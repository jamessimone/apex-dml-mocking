@IsTest
public class RepoFactoryMock extends RepoFactory {
  @TestVisible
  private static Map<SObjectType, List<AggregateRecord>> AggregateResults = new Map<SObjectType, List<AggregateRecord>>();
  @TestVisible
  private static List<Aggregation> AggregatesMade = new List<Aggregation>();
  @TestVisible
  private static List<SObject> QueryResults = new List<SObject>();
  @TestVisible
  private static List<Query> QueriesMade = new List<Query>();

  public override IDML getDML() {
    return new DMLMock();
  }

  public override IAggregateRepository getOppLineItemRepo() {
    return this.getRepoFromSObjectType(OpportunityLineItem.SObjectType, super.getOppLineItemRepo());
  }

  private IAggregateRepository getRepoFromSObjectType(SObjectType sObjectType, IAggregateRepository fallback) {
    IAggregateRepository repo;
    List<SObject> queriedResults = this.getResults(sObjectType);
    List<AggregateRecord> aggRecords = this.getAggregateResults(sObjectType);

    if (queriedResults.size() > 0) {
      repo = new RepoMock(queriedResults, this);
    } else if (aggRecords?.size() > 0) {
      repo = new RepoMock(aggRecords, this);
    } else {
      repo = fallback;
    }
    return repo;
  }

  private List<SObject> getResults(SObjectType sobjType) {
    List<SObject> resultList = new List<SObject>();
    for (SObject potentialResult : QueryResults) {
      if (potentialResult.getSObjectType() == sobjType) {
        resultList.add(potentialResult);
      }
    }
    return resultList;
  }

  private List<AggregateRecord> getAggregateResults(SObjectType sObjType) {
    return AggregateResults.get(sObjType);
  }

  @TestVisible
  private class RepoMock extends AggregateRepository {
    private final List<SObject> results;
    private final List<AggregateRecord> aggRecords;

    @TestVisible
    private RepoMock() {
      this(new List<SObject>(), new RepoFactoryMock());
    }

    public RepoMock(List<SObject> results, RepoFactory factory) {
      super(factory);
      this.results = results;
    }

    public RepoMock(List<AggregateRecord> records, RepoFactory factory) {
      super(factory);
      this.aggRecords = records;
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
      return this.aggRecords;
    }
  }
}
