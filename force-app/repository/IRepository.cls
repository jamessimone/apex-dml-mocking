public interface IRepository extends IDML {
  List<SObject> get(Query query);
  List<SObject> get(List<Query> queries);
  List<SObject> getAll();

  IRepository setAccessLevel(System.AccessLevel accessLevel);
  IRepository setLimit(Integer limitAmount);
  IRepository addSortOrder(Schema.SObjectField fieldToken, RepositorySortOrder sortOrder);
  IRepository addParentFields(List<Schema.SObjectField> relationshipFields, List<Schema.SObjectField> parentFields);
  IRepository addChildFields(Schema.SObjectField childFieldToken, List<SObjectField> childFields);
  IRepository addChildFields(
    Schema.SObjectField childFieldToken,
    List<Schema.SObjectField> childFields,
    List<Query> optionalWhereFilters,
    Map<Schema.SObjectField, RepositorySortOrder> fieldToSortOrder,
    Integer limitBy
  );
}
