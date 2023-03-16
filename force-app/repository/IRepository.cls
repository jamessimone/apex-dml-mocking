public interface IRepository extends IDML {
  List<SObject> get(Query query);
  List<SObject> get(List<Query> queries);
  List<SObject> getAll();
  IRepository setAccessLevel(System.AccessLevel accessLevel);

  void addParentFields(List<Schema.SObjectField> relationshipFields, List<Schema.SObjectField> parentFields);
  void addChildFields(Schema.SObjectField childFieldToken, List<SObjectField> childFields);
}
