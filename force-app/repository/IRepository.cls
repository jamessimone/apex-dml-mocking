public interface IRepository extends IDML {
  Database.QueryLocator getQueryLocator(List<Query> queries);
  Database.QueryLocator getQueryLocator(List<Query> queries, Boolean shouldAddChildFields);
  List<SObject> get(Query query);
  List<SObject> get(List<Query> queries);
  List<SObject> getAll();

  List<List<SObject>> getSosl(String searchTerm, Query query);
  List<List<SObject>> getSosl(String searchTerm, List<Query> queries);
  IRepository setSearchGroup(SearchGroup searchGroup);

  IRepository setAccessLevel(System.AccessLevel accessLevel);
  IRepository setLimit(Integer limitAmount);
  IRepository addSortOrder(Schema.SObjectField fieldToken, RepositorySortOrder sortOrder);
  IRepository addParentFields(List<Schema.SObjectField> relationshipFields, List<Schema.SObjectField> parentFields);
  IRepository addChildFields(Schema.SObjectField childFieldToken, List<SObjectField> childFields);
  IRepository addChildFields(
    Schema.SObjectField childFieldToken,
    List<Schema.SObjectField> childFields,
    List<Query> optionalWhereFilters,
    Map<String, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  );
}
