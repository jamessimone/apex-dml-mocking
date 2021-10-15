public interface IRepository extends IDML {
    List<SObject> get(Query query);
    List<SObject> get(List<Query> queries);
    List<SObject> getAll();
}