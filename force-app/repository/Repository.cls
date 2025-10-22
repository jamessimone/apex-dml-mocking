@SuppressWarnings('PMD.AvoidBooleanMethodParameters,PMD.ExcessiveParameterList,PMD.ExcessivePublicCount')
public virtual without sharing class Repository implements IRepository {
  private final Map<Schema.SObjectField, String> childToRelationshipNames;
  private final IDML dml;
  @TestVisible
  private final List<Schema.SObjectField> queryFields;
  private final Set<String> selectFields = new Set<String>();
  private final Set<String> childBindVarKeys = new Set<String>();

  protected final Schema.SObjectType repoType;
  protected final Map<String, Object> bindVars = new Map<String, Object>();

  protected System.AccessLevel accessLevel = System.AccessLevel.SYSTEM_MODE;
  protected final Map<String, RepositorySortOrder> fieldToSortOrder = new Map<String, RepositorySortOrder>();

  private Boolean shouldPrintBindVars = false;
  private Boolean baseSelectUsed = false;
  private Boolean isSosl = false;
  private Boolean shouldAddChildFields = true;
  private Integer limitAmount;
  private SearchGroup soslSearchGroup = SearchGroup.ALL_FIELDS;

  public Repository(Schema.SObjectType repoType, List<Schema.SObjectField> queryFields, RepoFactory repoFactory) {
    this.dml = repoFactory.getDml();
    this.queryFields = queryFields;
    this.repoType = repoType;
    this.childToRelationshipNames = this.getChildRelationshipNames(repoType);
  }

  // SOQL
  public virtual Cursor getCursor(List<Query> queries) {
    String finalQuery = this.getFinalQuery(queries);
    this.logQuery('cursor query:\n' + finalQuery);
    Cursor cursor = new Cursor(finalQuery, this.bindVars, this.accessLevel);
    this.clearState();
    System.debug(System.LoggingLevel.FINER, 'number of results: ' + cursor.getNumRecords());
    return cursor;
  }

  public Database.QueryLocator getQueryLocator(List<Query> queries) {
    return this.getQueryLocator(queries, this.shouldAddChildFields);
  }

  public Database.QueryLocator getQueryLocator(List<Query> queries, Boolean shouldAddChildFields) {
    Boolean originalValue = this.shouldAddChildFields;
    this.shouldAddChildFields = shouldAddChildFields;
    String finalQuery = this.getFinalQuery(queries);
    this.logQuery('query locator query:\n' + finalQuery);
    Database.QueryLocator locator = Database.getQueryLocatorWithBinds(
      this.getFinalQuery(queries),
      this.bindVars,
      this.accessLevel
    );
    this.clearState();
    this.shouldAddChildFields = originalValue;

    return locator;
  }

  public virtual List<SObject> get(Query query) {
    return this.get(new List<Query>{ query });
  }

  public virtual List<SObject> get(List<Query> queries) {
    String finalQuery = this.getFinalQuery(queries);
    return this.performQuery(finalQuery);
  }

  public virtual List<SObject> getAll() {
    return this.get(new List<Query>());
  }

  public Repository setLimit(Integer limitAmount) {
    this.limitAmount = limitAmount;
    return this;
  }

  public Repository addSortOrder(Schema.SObjectField fieldToken, RepositorySortOrder sortOrder) {
    this.fieldToSortOrder.put(fieldToken.getDescribe().getName(), sortOrder);
    return this;
  }

  public Repository addSortOrder(List<Schema.SObjectField> parentFieldChain, RepositorySortOrder sortOrder) {
    this.fieldToSortOrder.put(Query.getBuiltUpParentFieldName(parentFieldChain), sortOrder);
    return this;
  }

  public Repository addBaseFields(List<Schema.SObjectField> fields) {
    Set<Schema.SObjectField> uniqueFields = new Set<Schema.SObjectField>(this.queryFields);
    uniqueFields.addAll(fields);
    this.queryFields.clear();
    this.queryFields.addAll(uniqueFields);
    return this;
  }

  public Repository addFunctionBaseField(SelectFunction selectFunction, Schema.SObjectField field) {
    return this.addFunctionBaseFields(selectFunction, new List<Schema.SObjectField>{ field });
  }

  public Repository addFunctionBaseFields(SelectFunction selectFunction, List<Schema.SObjectField> fields) {
    Map<Schema.SObjectField, String> fieldsToAliases = new Map<Schema.SObjectfield, String>();
    for (Schema.SObjectField field : fields) {
      fieldsToAliases.put(
        field,
        this.queryFields.contains(field) ? field.getDescribe().getName() + '_' + selectFunction.name() : null
      );
    }
    return this.addFunctionBaseFields(selectFunction, fieldsToAliases);
  }

  public Repository addFunctionBaseFields(
    SelectFunction selectFunction,
    Map<Schema.SObjectField, String> fieldsToAliases
  ) {
    Map<String, String> fieldNamesToAliases = new Map<String, String>();
    for (Schema.SObjectField field : fieldsToAliases.keySet()) {
      fieldNamesToAliases.put(field.getDescribe().getName(), fieldsToAliases.get(field));
    }
    this.selectFields.addAll(this.getFunctionBaseFields(selectFunction, fieldNamesToAliases));
    return this;
  }

  public Repository addParentFields(Schema.SObjectField parentType, List<Schema.SObjectField> parentFields) {
    return this.addParentFields(new List<Schema.SObjectField>{ parentType }, parentFields);
  }

  public Repository addParentFields(List<Schema.SObjectField> parentTypes, List<Schema.SObjectField> parentFields) {
    this.selectFields.addAll(this.getParentFields(parentTypes, parentFields));
    return this;
  }

  public Repository addChildFields(Schema.SObjectField childFieldToken, List<Schema.SObjectField> childFields) {
    return this.addChildFields(
      childFieldToken,
      childFields,
      new List<Query>(),
      new Map<String, RepositorySortOrder>(),
      null
    );
  }

  public Repository addChildFields(Schema.SObjectField childFieldToken, IRepository childRepo) {
    return this.addChildFields(
      childFieldToken,
      childRepo,
      new List<Query>(),
      new Map<String, RepositorySortOrder>(),
      null
    );
  }

  public Repository addChildFields(
    Schema.SObjectField childFieldToken,
    List<Schema.SObjectField> childFields,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  ) {
    return this.addChildFields(
      childFieldToken,
      new List<QueryField>{ new QueryField(childFields) },
      optionalWhereFilters,
      fieldToSortOrder,
      limitBy
    );
  }

  public Repository addChildFields(
    Schema.SObjectField childFieldToken,
    IRepository childRepo,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  ) {
    Repository cr = (Repository) childRepo;
    cr.selectFields.addAll(cr.addSelectFields());
    Set<String> localSelectFields = cr.selectFields;
    localSelectFields.remove('Id');

    return this.addChildFields(
      childFieldToken,
      new List<QueryField>{ new QueryField(new List<String>(localSelectFields)) },
      optionalWhereFilters,
      fieldToSortOrder,
      limitBy
    );
  }

  public Repository addChildFields(
    Schema.SObjectField childFieldToken,
    List<QueryField> childFields,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  ) {
    if (this.childToRelationshipNames.containsKey(childFieldToken) == false || this.shouldAddChildFields == false) {
      return this;
    }

    String baseSubselect =
      '(SELECT {0} FROM {1}' +
      this.addWheres(optionalWhereFilters) +
      this.getOrderBys(fieldToSortOrder) +
      this.getLimitAmount(limitBy) +
      ')';

    Set<String> childFieldNames = new Set<String>{ 'Id' };
    for (QueryField childField : childFields) {
      childFieldNames.add(childField.toString());
    }

    for (Query query : optionalWhereFilters) {
      this.childBindVarKeys.addAll(query.getBindVars().keySet());
    }

    this.selectFields.add(
      String.format(
        baseSubselect,
        new List<String>{ String.join(childFieldNames, ','), this.childToRelationshipNames.get(childFieldToken) }
      )
    );
    return this;
  }

  public Repository setAccessLevel(System.AccessLevel accessLevel) {
    this.setOptions(null, accessLevel);
    return this;
  }

  public Repository clearBindVars() {
    for (String key : this.bindVars.keySet()) {
      if (this.childBindVarKeys.contains(key) == false) {
        this.bindVars.remove(key);
      }
    }
    return this;
  }

  public Repository setShouldPrintBindVars(Boolean shouldPrintBindVars) {
    this.shouldPrintBindVars = shouldPrintBindVars;
    return this;
  }

  protected virtual Set<String> addSelectFields() {
    this.baseSelectUsed = true;
    return this.addSelectFields(this.queryFields);
  }

  protected virtual String getFinalQuery(List<Query> queries) {
    return this.getSelectAndFrom() +
      this.addWheres(queries) +
      this.getOrderBys(this.fieldToSortOrder) +
      this.getLimitAmount(this.limitAmount);
  }

  protected virtual void clearState() {
    this.clearBindVars();
    this.fieldToSortOrder.clear();
    this.limitAmount = null;
  }

  private List<String> getFunctionBaseFields(SelectFunction selectFunction, Map<String, String> fieldsToAliases) {
    List<String> functionBaseFields = new List<String>();
    for (String field : fieldsToAliases.keySet()) {
      Object alias = fieldsToAliases.get(field);
      functionBaseFields.add(
        String.format(selectFunction.name() + '({0}){1}', new List<Object>{ field, alias == null ? '' : ' ' + alias })
      );
    }
    return functionBaseFields;
  }

  private List<String> getParentFields(
    List<Schema.SObjectField> parentTypes,
    List<Schema.SObjectField> parentFieldTokens
  ) {
    List<String> parentFields = new List<String>();
    String parentBase = '';
    for (Schema.SObjectField parentToken : parentTypes) {
      String parentName = parentToken.getDescribe().getRelationshipName() ??
        parentToken.toString().replace('__c', '__r');
      parentBase += parentName + '.';
    }
    for (Schema.SObjectField parentField : parentFieldTokens) {
      parentFields.add(parentBase + parentField.getDescribe().getName());
    }
    return parentFields;
  }

  private Map<Schema.SObjectField, String> getChildRelationshipNames(Schema.SObjectType repoType) {
    Map<Schema.SObjectField, String> localChildToRelationshipNames = new Map<Schema.SObjectField, String>();
    for (Schema.ChildRelationship childRelationship : repoType.getDescribe().getChildRelationships()) {
      localChildToRelationshipNames.put(childRelationship.getField(), childRelationship.getRelationshipName());
    }
    return localChildToRelationshipNames;
  }

  private String getSelectAndFrom() {
    Set<String> localSelectFields = this.addSelectFields();
    if (this.baseSelectUsed) {
      localSelectFields.addAll(this.selectFields);
      this.baseSelectUsed = false;
    }
    return 'SELECT ' + String.join(localSelectFields, ', ') + '\nFROM ' + this.repoType;
  }

  private Set<String> addSelectFields(List<Schema.SObjectField> fields) {
    Set<String> fieldStrings = new Set<String>{ 'Id' };
    for (SObjectField field : fields) {
      fieldStrings.add(field.getDescribe().getName());
    }
    return fieldStrings;
  }

  private String addWheres(List<Query> queries) {
    List<String> wheres = new List<String>();
    for (Query qry : queries) {
      String possibleWhere = this.isSosl ? qry.toSoslString() : qry.toString();
      if (qry.isSoslEmpty() == false && String.isNotBlank(possibleWhere)) {
        wheres.add(possibleWhere);
        this.bindVars.putAll(qry.getBindVars());
      }
    }

    String whereClause = String.join(wheres, '\nAND ');
    return wheres.isEmpty() || String.isBlank(whereClause) ? '' : '\nWHERE ' + whereClause;
  }

  private List<SObject> performQuery(String finalQuery) {
    this.logQuery('performQuery query:\n' + finalQuery);
    List<SObject> results = Database.queryWithBinds(finalQuery, this.bindVars, this.accessLevel);
    this.clearState();
    System.debug(System.LoggingLevel.FINER, 'number of results: ' + results.size() + '\nresults: \n' + results);
    return results;
  }

  private String getOrderBys(Map<String, RepositorySortOrder> sortOrders) {
    String orderByString = '';
    if (sortOrders.isEmpty() == false) {
      orderByString += ' \nORDER BY ';
      String separator = ', ';
      for (String field : sortOrders.keySet()) {
        orderByString += field + ' ' + sortOrders.get(field).toString() + separator;
      }
      orderByString = orderByString.removeEnd(separator);
    }
    return orderByString;
  }

  private String getLimitAmount(Integer limitAmount) {
    return (limitAmount != null ? '\nLIMIT ' + limitAmount : '');
  }

  // SOSL

  public List<List<SObject>> getSosl(String searchTerm, Query queryFilter) {
    return this.getSosl(searchTerm, new List<Query>{ queryFilter });
  }

  public virtual List<List<SObject>> getSosl(String searchTerm, List<Query> queryFilters) {
    return this.getSosl(searchTerm, queryFilters, new List<AdditionalSoslObject>());
  }

  public virtual List<List<SObject>> getSosl(
    String searchTerm,
    List<Query> queryFilters,
    List<AdditionalSoslObject> additionalSoslObjects
  ) {
    this.isSosl = true;
    List<AdditionalSoslObject> orderedSearchObjects = new List<AdditionalSoslObject>{
      new AdditionalSoslObject(this.repoType, this.queryFields, queryFilters, this.limitAmount)
    };
    orderedSearchObjects.addAll(additionalSoslObjects);
    String searchQuery =
      'FIND \'' +
      String.escapeSingleQuotes(searchTerm) +
      '\' IN ' +
      this.soslSearchGroup.name().replace('_', ' ') +
      ' RETURNING ' +
      this.formatAdditionalSoslObjects(orderedSearchObjects);

    this.logQuery('search query:\n' + searchQuery);
    List<List<SObject>> results = Search.query(searchQuery, this.accessLevel);
    System.debug(System.LoggingLevel.FINER, 'number of results: ' + results.size() + '\nresults: \n' + results);
    this.clearState();
    this.isSosl = false;
    return results;
  }

  public Repository setSearchGroup(SearchGroup searchGroup) {
    this.soslSearchGroup = searchGroup;
    return this;
  }

  private String formatAdditionalSoslObjects(List<AdditionalSoslObject> soslObjects) {
    List<String> objectsPreJoin = new List<String>();
    for (AdditionalSoslObject soslObject : soslObjects) {
      objectsPreJoin.add(
        soslObject.objectType +
          '(' +
          String.join(this.addSelectFields(soslObject.selectFields), ',') +
          this.addWheres(soslObject.queryFilters) +
          this.getLimitAmount(soslObject.queryLimit) +
          ')'
      );
    }
    return String.join(objectsPreJoin, ',');
  }

  protected void logQuery(String logString) {
    if (this.shouldPrintBindVars) {
      logString += '\n\nBind vars: ' + JSON.serializePretty(this.bindVars);
    }
    System.debug(System.LoggingLevel.DEBUG, logString);
  }

  // DML
  public Database.SaveResult doInsert(SObject record) {
    return this.dml.doInsert(record);
  }
  public List<Database.SaveResult> doInsert(List<SObject> records) {
    return this.dml.doInsert(records);
  }

  public Database.SaveResult doUpdate(SObject record) {
    return this.dml.doUpdate(record);
  }
  public List<Database.SaveResult> doUpdate(List<SObject> records) {
    return this.dml.doUpdate(records);
  }

  public Database.UpsertResult doUpsert(SObject record) {
    return this.dml.doUpsert(record);
  }
  public List<Database.UpsertResult> doUpsert(List<SObject> records) {
    return this.dml.doUpsert(records);
  }
  public List<Database.UpsertResult> doUpsert(List<SObject> records, Schema.SObjectField field) {
    return this.dml.doUpsert(records, field);
  }

  public Database.UndeleteResult doUndelete(SObject record) {
    return this.dml.doUnDelete(record);
  }
  public List<Database.UndeleteResult> doUndelete(List<SObject> records) {
    return this.dml.doUndelete(records);
  }

  public Database.DeleteResult doDelete(SObject record) {
    return this.dml.doDelete(record);
  }
  public List<Database.DeleteResult> doDelete(List<SObject> records) {
    return this.dml.doDelete(records);
  }

  public Database.DeleteResult doHardDelete(SObject record) {
    return this.dml.doHardDelete(record);
  }
  public List<Database.DeleteResult> doHardDelete(List<SObject> records) {
    return this.dml.doHardDelete(records);
  }

  public Database.SaveResult publish(SObject event) {
    return this.dml.publish(event);
  }
  public List<Database.SaveResult> publish(List<SObject> events) {
    return this.dml.publish(events);
  }

  public IDML setOptions(Database.DMLOptions options) {
    return this.setOptions(options, this.accessLevel);
  }

  public IDML setOptions(Database.DMLOptions options, System.AccessLevel accessLevel) {
    this.accessLevel = accessLevel;
    return this.dml.setOptions(options, accessLevel);
  }
}
