public without sharing virtual class AggregateRepository extends Repository implements IAggregateRepository {
  private final Set<String> havingFields = new Set<String>();
  private final Set<String> groupedByFieldNames = new Set<String>();
  private List<Aggregation> aggregations;
  private Boolean isNumberCountQuery = false;
  public AggregateRepository(
    Schema.SObjectType repoType,
    List<Schema.SObjectField> queryFields,
    RepoFactory repoFactory
  ) {
    super(repoType, queryFields, repoFactory);
  }

  public IAggregateRepository groupBy(Schema.SObjectField fieldToken) {
    this.groupedByFieldNames.add(fieldToken.getDescribe().getName());
    return this;
  }
  public IAggregateRepository groupBy(List<Schema.SObjectField> parentFieldChain) {
    String parentFieldGroupBy = '';
    while (parentFieldChain.size() > 1) {
      parentFieldGroupBy += parentFieldChain.remove(0).getDescribe().getRelationshipName() + '.';
    }
    this.groupedByFieldNames.add(parentFieldGroupBy + parentFieldChain.remove(0).getDescribe().getName());
    return this;
  }

  public IAggregateRepository addHaving(Aggregation aggregation, Query.Operator operator, Object value) {
    Query aggQuery = new AggregateQuery(operator, value);
    this.havingFields.add(aggregation.getBaseAggregation() + ' ' + aggQuery);
    this.bindVars.putAll(aggQuery.getBindVars());
    return this;
  }

  public Integer count() {
    return this.count(new List<Query>());
  }
  public Integer count(Query query) {
    return this.count(new List<Query>{ query });
  }
  public Integer count(List<Query> queries) {
    this.isNumberCountQuery = true;
    Integer recordCount = Database.countQueryWithBinds(this.getFinalQuery(queries), this.bindVars, this.accessLevel);
    this.bindVars.clear();
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

    this.havingFields.clear();
    this.groupedByFieldNames.clear();
    this.aggregations = null;
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
    if (this.groupedByFieldNames.isEmpty() == false) {
      baseString += '\nGROUP BY ' + String.join(new List<String>(this.groupedByFieldNames), ',');
      // having is only valid with a grouping
      if (this.havingFields.isEmpty() == false) {
        baseString += '\nHAVING ' + String.join(new List<String>(this.havingFields), ',');
      }
    }
    return baseString;
  }

  private class AggregateQuery extends Query {
    public AggregateQuery(Query.Operator op, Object value) {
      super('', op, value);
    }
  }
}
