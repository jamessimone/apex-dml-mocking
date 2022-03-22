public without sharing virtual class AggregateRepository extends Repository implements IAggregateRepository {
  private final Set<String> groupedByFieldNames;
  private List<Aggregation> aggregations;
  private Boolean isNumberCountQuery = false;
  public AggregateRepository(
    Schema.SObjectType repoType,
    List<Schema.SObjectField> queryFields,
    RepoFactory repoFactory
  ) {
    super(repoType, queryFields, repoFactory);
    this.groupedByFieldNames = new Set<String>();
  }

  protected AggregateRepository(RepoFactory repoFactory) {
    super(repoFactory);
  }

  public void groupBy(Schema.SObjectField fieldToken) {
    this.groupBy(fieldToken.getDescribe().getName());
  }
  public void groupBy(String fieldName) {
    this.groupedByFieldNames.add(fieldName);
  }

  public Integer count() {
    return this.count(new List<Query>());
  }
  public Integer count(Query query) {
    return this.count(new List<Query>{ query });
  }
  public Integer count(List<Query> queries) {
    this.isNumberCountQuery = true;
    Integer recordCount = Database.countQuery(this.getFinalQuery(queries));
    this.isNumberCountQuery = false;
    return recordCount;
  }

  public List<AggregateRecord> aggregate(Aggregation aggregation) {
    return this.aggregate(new List<Aggregation>{ aggregation }, new List<Query>());
  }
  public List<AggregateRecord> aggregate(Aggregation aggregation, Query query) {
    return this.aggregate(new List<Aggregation>{ aggregation }, new List<Query>{ query });
  }
  public List<AggregateRecord> aggregate(Aggregation aggregation, List<Query> queries) {
    return this.aggregate(new List<Aggregation>{ aggregation }, queries);
  }
  public List<AggregateRecord> aggregate(List<Aggregation> aggregations) {
    return this.aggregate(aggregations, new List<Query>());
  }
  public List<AggregateRecord> aggregate(List<Aggregation> aggregations, Query query) {
    return this.aggregate(aggregations, new List<Query>{ query });
  }
  public virtual List<AggregateRecord> aggregate(List<Aggregation> aggregations, List<Query> queries) {
    this.aggregations = aggregations;
    List<AggregateResult> results = (List<AggregateResult>) this.get(queries);
    List<AggregateRecord> aggregateRecords = new List<AggregateRecord>();
    for (AggregateResult result : results) {
      AggregateRecord aggRecord = new AggregateRecord();
      aggRecord.putAll(result.getPopulatedFieldsAsMap());
      aggregateRecords.add(aggRecord);
    }
    return aggregateRecords;
  }

  protected virtual override Set<String> addSelectFields() {
    Set<String> baseFields = new Set<String>();
    if (this.isNumberCountQuery) {
      baseFields.add('COUNT()');
      return baseFields;
    }

    if (this.aggregations != null) {
      for (Aggregation agg : aggregations) {
        baseFields.add(agg.toString());
      }
    }

    baseFields.addAll(this.groupedByFieldNames);
    return baseFields.isEmpty() ? super.addSelectFields() : baseFields;
  }

  protected override String getFinalQuery(List<Query> queries) {
    String baseString = super.getFinalQuery(queries);
    return this.groupedByFieldNames.isEmpty()
      ? baseString
      : baseString + '\nGROUP BY ' + String.join(new List<String>(this.groupedByFieldNames), ',');
  }
}
