public interface IRepository extends IDML {
  Cursor getCursor(List<Query> queries);
  Database.QueryLocator getQueryLocator(List<Query> queries);
  Database.QueryLocator getQueryLocator(List<Query> queries, Boolean shouldAddChildFields);
  List<SObject> get(Query query);
  List<SObject> get(List<Query> queries);
  List<SObject> getAll();

  List<List<SObject>> getSosl(String searchTerm, Query query);
  List<List<SObject>> getSosl(String searchTerm, List<Query> queries);
  List<List<SObject>> getSosl(String searchTerm, List<Query> queries, List<AdditionalSoslObject> additionalSoslObjects);
  IRepository setSearchGroup(SearchGroup searchGroup);

  IRepository clearBindVars();
  IRepository setAccessLevel(System.AccessLevel accessLevel);
  IRepository setLimit(Integer limitAmount);
  IRepository addSortOrder(Schema.SObjectField fieldToken, RepositorySortOrder sortOrder);
  IRepository addSortOrder(List<Schema.SObjectField> fieldChain, RepositorySortOrder sortOrder);

  IRepository addBaseFields(List<Schema.SObjectField> fields);
  IRepository addFunctionBaseField(SelectFunction selectFunction, Schema.SObjectField field);
  IRepository addFunctionBaseFields(SelectFunction selectFunction, List<Schema.SObjectField> fields);
  IRepository addFunctionBaseFields(SelectFunction selectFunction, Map<Schema.SObjectField, String> fieldsToAliases);
  IRepository addParentFields(List<Schema.SObjectField> relationshipFields, List<Schema.SObjectField> parentFields);
  IRepository addChildFields(Schema.SObjectField childFieldToken, List<SObjectField> childFields);
  IRepository addChildFields(Schema.SObjectField childFieldToken, IRepository childRepo);
  IRepository addChildFields(
    Schema.SObjectField childFieldToken,
    List<Schema.SObjectField> childFields,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  );
  IRepository addChildFields(
    Schema.SObjectField childFieldToken,
    IRepository childRepo,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  );
  IRepository addChildFields(
    Schema.SObjectField childFieldToken,
    List<QueryField> childFields,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  );
}
