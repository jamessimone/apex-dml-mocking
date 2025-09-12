public without sharing virtual class AggregateRepository extends Repository implements IAggregateRepository {
  protected final Set<GroupBy> groupedByFieldNames = new Set<GroupBy>();
  private final Set<String> havingFields = new Set<String>();
  private List<Aggregation> aggregations;
  private Boolean isNumberCountQuery = false;

  @TestVisible
  private class GroupBy {
    private final String selectName;
    private final String groupByName;

    public GroupBy(String groupByName, String alias) {
      this.selectName = groupByName + ' ' + alias;
      this.groupByName = groupByName;
    }

    public GroupBy(String fieldName) {
      this.selectName = fieldName;
      this.groupByName = fieldName;
    }

    public String getSelectName() {
      return this.selectName;
    }

    public String getGroupByName() {
      return this.groupByName;
    }

    public Boolean equals(Object other) {
      if (other instanceof GroupBy) {
        GroupBy that = (GroupBy) other;
        return this.groupByName == that.groupByName && this.selectName == that.selectName;
      }
      return false;
    }

    public Integer hashCode() {
      return this.selectName.hashCode() + this.groupByName.hashCode();
    }
  }

  public AggregateRepository(
    Schema.SObjectType repoType,
    List<Schema.SObjectField> queryFields,
    RepoFactory repoFactory
  ) {
    super(repoType, queryFields, repoFactory);
  }

  public IAggregateRepository groupBy(DateFunction dateFunction, Schema.SObjectField fieldToken, String alias) {
    String groupByName = this.getFormattedDateFunction(dateFunction, fieldToken);
    this.groupedByFieldNames.add(new GroupBy(groupByName, alias));
    return this;
  }

  public IAggregateRepository groupBy(Schema.SObjectField fieldToken) {
    this.groupedByFieldNames.add(new GroupBy(fieldToken.getDescribe().getName()));
    return this;
  }

  public IAggregateRepository groupBy(List<Schema.SObjectField> parentFieldChain) {
    String parentFieldGroupBy = '';
    while (parentFieldChain.size() > 1) {
      parentFieldGroupBy += parentFieldChain.remove(0).getDescribe().getRelationshipName() + '.';
    }
    this.groupedByFieldNames.add(new GroupBy(parentFieldGroupBy + parentFieldChain.remove(0).getDescribe().getName()));
    return this;
  }

  public IAggregateRepository addSortOrder(Aggregation aggregate, RepositorySortOrder sortOrder) {
    this.fieldToSortOrder.put(aggregate.getBaseAggregation(), sortOrder);
    return this;
  }

  public IAggregateRepository addSortOrder(
    DateFunction dateFunction,
    Schema.SObjectField fieldToken,
    RepositorySortOrder sortOrder
  ) {
    this.fieldToSortOrder.put(this.getFormattedDateFunction(dateFunction, fieldToken), sortOrder);
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
  public virtual Integer count(List<Query> queries) {
    this.isNumberCountQuery = true;
    Integer recordCount = Database.countQueryWithBinds(this.getFinalQuery(queries), this.bindVars, this.accessLevel);
    this.clearState();
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

    this.clearState();
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

    for (GroupBy groupBy : this.groupedByFieldNames) {
      baseFields.add(groupBy.getSelectName());
    }
    return baseFields.isEmpty() ? super.addSelectFields() : baseFields;
  }

  protected override String getFinalQuery(List<Query> queries) {
    String baseString = super.getFinalQuery(queries);
    if (this.groupedByFieldNames.isEmpty() == false) {
      String potentialOrderBy = null;
      String orderByKey = '\nORDER BY';
      if (baseString.contains(orderByKey)) {
        potentialOrderBy = baseString.substringAfter(orderByKey);
        baseString = baseString.replace(orderByKey + potentialOrderBy, '');
      }
      baseString += '\nGROUP BY ';
      for (GroupBy groupBy : this.groupedByFieldNames) {
        baseString += groupBy.getGroupByName() + ',';
      }
      baseString = baseString.removeEnd(',');
      // having is only valid with a grouping
      if (this.havingFields.isEmpty() == false) {
        baseString += '\nHAVING ' + String.join(this.havingFields, ',');
      }
      if (potentialOrderBy != null) {
        baseString += orderByKey + potentialOrderBy;
      }
    }
    return baseString;
  }

  protected override void clearState() {
    super.clearState();
    this.havingFields.clear();
    this.groupedByFieldNames.clear();
    this.aggregations = null;
  }

  private String getFormattedDateFunction(DateFunction dateFunction, Schema.SObjectField fieldToken) {
    return dateFunction.name() + '(' + fieldToken + ')';
  }

  private class AggregateQuery extends Query {
    public AggregateQuery(Query.Operator op, Object value) {
      super('', op, value);
    }
  }
}
