public interface IHistoryRepository extends IAggregateRepository {
  // essentially duplicating the method signatures from IRepository
  // but with FieldLevelHistory return types
  List<FieldLevelHistory> getHistory(Query query);
  List<FieldLevelHistory> getHistory(List<Query> queries);
  List<FieldLevelHistory> getAllHistory();
}