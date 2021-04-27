public interface IRepository extends IDML {
  List<SObject> getAll();
  List<SObject> get(Query query);
  List<SObject> get(List<Query> queries);
}
