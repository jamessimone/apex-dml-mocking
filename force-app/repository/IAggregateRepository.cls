public interface IAggregateRepository extends IRepository {
  IAggregateRepository groupBy(Schema.SObjectField fieldToken);
  IAggregateRepository groupBy(List<Schema.SObjectField> parentFieldChain);
  IAggregateRepository addHaving(Aggregation aggregation, Query.Operator operator, Object value);

  // always a fun one
  Integer count();
  Integer count(Query query);
  Integer count(List<Query> queries);
  // with support for sum, count, count distinct, average, max, min
  List<AggregateRecord> aggregate(Aggregation aggregation);
  List<AggregateRecord> aggregate(Aggregation aggregation, Query query);
  List<AggregateRecord> aggregate(Aggregation aggregation, List<Query> queries);
  List<AggregateRecord> aggregate(List<Aggregation> aggregations);
  List<AggregateRecord> aggregate(List<Aggregation> aggregations, Query query);
  List<AggregateRecord> aggregate(List<Aggregation> aggregations, List<Query> queries);
}
