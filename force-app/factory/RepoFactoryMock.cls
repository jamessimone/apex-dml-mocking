@IsTest
public class RepoFactoryMock {
  @TestVisible
  private static final Map<Schema.SObjectType, List<AggregateRecord>> AggregateResults = new Map<Schema.SObjectType, List<AggregateRecord>>();
  @TestVisible
  private static final List<Aggregation> AggregatesMade = new List<Aggregation>();
  @TestVisible
  private static final List<SObject> QueryResults = new List<SObject>();
  @TestVisible
  private static final List<Query> QueriesMade = new List<Query>();
  @TestVisible
  private static final Map<Schema.SObjectType, List<FieldLevelHistory>> HistoryResults = new Map<Schema.SObjectType, List<FieldLevelHistory>>();
  @TestVisible
  private static final Map<SObjectType, List<AggregateRepository.GroupBy>> GroupByFields = new Map<SObjectType, List<AggregateRepository.GroupBy>>();
  @TestVisible
  private static final Map<SObjectType, Map<String, RepositorySortOrder>> FieldToSortOrders = new Map<SObjectType, Map<String, RepositorySortOrder>>();

  private static final Map<Schema.SObjectType, List<Schema.ChildRelationship>> CACHED_CHILD_RELATIONSHIPS = new Map<Schema.SObjectType, List<Schema.ChildRelationship>>();

  private class ChildrenSObjects {
    public final List<SObject> records;
    public final Boolean done = true;
    public final Integer totalSize;

    public ChildrenSObjects(List<SObject> records) {
      this.records = records;
      this.totalSize = records.size();
    }
  }

  public static SObject addChildrenToRecord(SObject record, Schema.SObjectField childField, List<SObject> children) {
    List<Schema.ChildRelationship> childRelationships = CACHED_CHILD_RELATIONSHIPS.get(record.getSObjectType());
    if (childRelationships == null) {
      childRelationships = record.getSObjectType()
        .getDescribe(Schema.SObjectDescribeOptions.FULL)
        .getChildRelationships();
      CACHED_CHILD_RELATIONSHIPS.put(record.getSObjectType(), childRelationships);
    }
    String relationshipName;
    for (Schema.ChildRelationship childRelationship : childRelationships) {
      if (childRelationship.getField() == childField) {
        relationshipName = childRelationship.getRelationshipName();
        break;
      }
    }
    if (relationshipName != null) {
      String serializedMeta = JSON.serialize(record).removeEnd('}');
      String childrenJson = '"' + relationshipName + '" : ' + JSON.serialize(new ChildrenSObjects(children));
      serializedMeta += ',' + childrenJson + '}';
      return (SObject) JSON.deserialize(serializedMeta, SObject.class);
    }
    return record;
  }

  public class FacadeMock extends RepoFactory.Facade {
    public override IDML getDML() {
      return new DMLMock();
    }

    public override IHistoryRepository getRepo(
      Schema.SObjectType repoType,
      List<Schema.SObjectField> queryFields,
      RepoFactory repoFactory
    ) {
      return getRepoFromSObjectType(repoType, super.getRepo(repoType, queryFields, repoFactory), repoFactory);
    }
  }

  private static IHistoryRepository getRepoFromSObjectType(
    SObjectType sObjectType,
    IAggregateRepository fallback,
    RepoFactory repoFactory
  ) {
    IHistoryRepository repo;
    List<SObject> queriedResults = getResults(sObjectType);
    List<AggregateRecord> aggRecords = AggregateResults.get(sObjectType);
    List<FieldLevelHistory> historyRecords = HistoryResults.get(SObjectType);

    if (queriedResults.size() > 0 || aggRecords?.size() > 0 || historyRecords?.size() > 0) {
      RepoMock mock = new RepoMock(sObjectType, repoFactory);
      mock.results.addAll(queriedResults);
      if (aggRecords != null) {
        mock.aggRecords.addAll(aggRecords);
      }
      if (historyRecords != null) {
        mock.historyRecords.addAll(historyRecords);
      }
      repo = mock;
    } else {
      repo = (IHistoryRepository) fallback;
    }
    return repo;
  }

  private static List<SObject> getResults(SObjectType sobjType) {
    List<SObject> resultList = new List<SObject>();
    for (SObject potentialResult : QueryResults) {
      if (potentialResult.getSObjectType() == sobjType) {
        resultList.add(potentialResult);
      }
    }
    return resultList;
  }

  private class RepoMock extends FieldLevelHistoryRepo {
    private final List<SObject> results = new List<SObject>();
    private final List<AggregateRecord> aggRecords = new List<AggregateRecord>();
    private final List<FieldLevelHistory> historyRecords = new List<FieldLevelHistory>();

    private RepoMock(Schema.SObjectType sObjectType, RepoFactory repoFactory) {
      super(sObjectType, new List<Schema.SObjectField>(), repoFactory);
    }

    public override List<FieldLevelHistory> getHistory(List<Query> queries) {
      QueriesMade.addAll(queries);
      return this.historyRecords;
    }

    public override List<SObject> getAll() {
      return this.get(new List<Query>());
    }

    public override List<SObject> get(Query query) {
      return this.get(new List<Query>{ query });
    }

    public override List<SObject> get(List<Query> queries) {
      QueriesMade.addAll(queries);
      return this.results;
    }

    public override List<AggregateRecord> aggregate(List<Aggregation> aggregations, List<Query> queries) {
      AggregatesMade.addAll(aggregations);
      QueriesMade.addAll(queries);

      List<AggregateRepository.GroupBy> fields = GroupByFields.get(this.repoType);
      if (fields == null) {
        fields = new List<AggregateRepository.GroupBy>();
        GroupByFields.put(this.repoType, fields);
      }
      fields.addAll(this.groupedByFieldNames);

      Map<String, RepositorySortOrder> localFieldToSortOrders = FieldToSortOrders.get(this.repoType);
      if (localFieldToSortOrders == null) {
        localFieldToSortOrders = new Map<String, RepositorySortOrder>();
        FieldToSortOrders.put(this.repoType, localFieldToSortOrders);
      }
      localFieldToSortOrders.putAll(this.fieldToSortOrder);

      return this.aggRecords;
    }
  }
}
