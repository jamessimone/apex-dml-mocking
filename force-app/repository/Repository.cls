public virtual without sharing class Repository implements IRepository {
  private final IDML dml;
  private final List<Schema.SObjectField> queryFields;
  private final Schema.SObjectType repoType;

  private Boolean shortCircuit = false;
  private Object bindVar;

  public Repository(Schema.SObjectType repoType, List<Schema.SObjectField> queryFields, RepoFactory repoFactory) {
    this.dml = repoFactory.getDml();
    this.queryFields = queryFields;
    this.repoType = repoType;
  }

  protected Repository(RepoFactory repoFactory) {
    this.dml = repoFactory.getDml();
  }

  // SOQL
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

  protected virtual Set<String> addSelectFields() {
    Set<String> fieldStrings = new Set<String>{ 'Id' };
    for (SObjectField field : this.queryFields) {
      fieldStrings.add(field.getDescribe().getName());
    }
    return fieldStrings;
  }

  protected virtual String getFinalQuery(List<Query> queries) {
    return this.getSelectAndFrom() + this.addWheres(queries);
  }

  private String getSelectAndFrom() {
    return 'SELECT ' + String.join(new List<String>(this.addSelectFields()), ', ') + '\nFROM ' + this.repoType;
  }

  private String addWheres(List<Query> queries) {
    List<String> wheres = new List<String>();
    for (Query query : queries) {
      if (query.isEmpty()) {
        this.shortCircuit = true;
      } else if (this.bindVar == null) {
        // at some point, it would be nice to support multiple bind variables
        // for collection-based arguments; for now, we only support them for NOT LIKE
        // arguments - and even then, only once per full query
        // multiple NOT LIKEs (for different fields) are supported
        // by chaining queries together, if necessary
        this.bindVar = query.getBindVars();
      }
      wheres.add(query.toString());
    }
    return wheres.isEmpty() ? '' : '\nWHERE ' + String.join(wheres, '\nAND');
  }

  private List<SObject> performQuery(String finalQuery) {
    System.debug('Query: \n' + finalQuery);
    if (this.bindVar != null) {
      System.debug('Bind var: ' + this.bindVar);
    }
    List<SObject> results = shortCircuit ? new List<SObject>() : Database.query(finalQuery);
    System.debug('Results: \n' + results);
    return results;
  }

  // DML
  public SObject doInsert(SObject record) {
    return this.dml.doInsert(record);
  }
  public List<SObject> doInsert(List<SObject> records) {
    return this.dml.doInsert(records);
  }

  public SObject doUpdate(SObject record) {
    return this.dml.doUpdate(record);
  }
  public List<SObject> doUpdate(List<SObject> records) {
    return this.dml.doUpdate(records);
  }

  public SObject doUpsert(SObject record) {
    return this.dml.doUpsert(record);
  }
  public List<SObject> doUpsert(List<SObject> records) {
    return this.dml.doUpsert(records);
  }
  public List<SObject> doUpsert(List<SObject> records, Schema.SObjectField field) {
    return this.dml.doUpsert(records, field);
  }

  public SObject doUndelete(SObject record) {
    return this.dml.doUnDelete(record);
  }
  public List<SObject> doUndelete(List<SObject> records) {
    return this.dml.doUndelete(records);
  }

  public void doDelete(SObject record) {
    this.dml.doDelete(record);
  }
  public void doDelete(List<SObject> records) {
    this.dml.doDelete(records);
  }

  public void doHardDelete(SObject record) {
    this.dml.doHardDelete(record);
  }
  public void doHardDelete(List<SObject> records) {
    this.dml.doHardDelete(records);
  }
}
