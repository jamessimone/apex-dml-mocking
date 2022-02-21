public interface IRepository extends IDML {
    List<SObject> get(Query query);
    List<SObject> get(List<Query> queries);
    List<SObject> getAll();

    void addParentFields(List<SObjectType> parentTypes, List<SObjectField> parentFields);
    void addChildFields(SObjectType childType, List<SObjectField> childFields);
  }