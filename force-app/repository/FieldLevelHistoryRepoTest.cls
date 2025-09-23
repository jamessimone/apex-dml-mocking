@IsTest
private class FieldLevelHistoryRepoTest {
  @IsTest
  static void itShouldContinueToActAsBaseRepo() {
    IHistoryRepository historyRepo = new FieldLevelHistoryRepoTest.ExampleRepoFactory().getOppFieldHistoryRepo();

    List<OpportunityFieldHistory> histories = historyRepo.get(
      Query.equals(OpportunityFieldHistory.OpportunityId, null)
    );

    Assert.areNotEqual(null, histories);
  }

  @IsTest
  static void itShouldContinueToActAsAggregateRepo() {
    Aggregation count = Aggregation.count(OpportunityFieldHistory.Id, 'countId');
    IAggregateRepository repo = new FieldLevelHistoryRepoTest.ExampleRepoFactory().getOppFieldHistoryRepo();
    repo.groupBy(OpportunityFieldHistory.OpportunityId);

    List<AggregateRecord> records = repo.aggregate(count);

    // It's not much of an assert, but at least we know the query went through successfully
    Assert.areEqual(true, records.isEmpty());
  }

  @IsTest
  static void itShouldQueryHistoryRecords() {
    IHistoryRepository historyRepo = new FieldLevelHistoryRepoTest.ExampleRepoFactory().getOppFieldHistoryRepo();

    List<FieldLevelHistory> histories = historyRepo.getAllHistory();
    // History records can't be created during Apex unit testing, but we can at least validate the query
    // and prove that the FieldLevelHistory decorator list is returned properly
    Assert.areEqual(true, histories.isEmpty());
  }

  @IsTest
  static void itShouldAllowMockingOfHistoryRecords() {
    FieldLevelHistory mockRecord = new FieldLevelHistory();
    mockRecord.setValues(
      new Map<String, Object>{
        'CreatedDate' => System.now(),
        'Id' => TestingUtils.generateId(OpportunityFieldHistory.SObjectType),
        'Field' => 'Amount',
        'OldValue' => 0,
        'NewValue' => 1,
        'OpportunityId' => TestingUtils.generateId(Opportunity.SObjectType)
      }
    );
    RepoFactoryMock.HistoryResults.put(OpportunityFieldHistory.SObjectType, new List<FieldLevelHistory>{ mockRecord });

    IHistoryRepository historyRepo = new FieldLevelHistoryRepoTest.ExampleRepoFactory().getOppFieldHistoryRepo();

    List<FieldLevelHistory> histories = historyRepo.getAllHistory();
    Assert.areNotEqual(true, histories.isEmpty());
    Assert.areEqual(mockRecord, histories[0]);
  }

  private without sharing class ExampleRepoFactory extends RepoFactory {
    private ExampleRepoFactory() {
      this.facade = new RepoFactoryMock.FacadeMock();
    }

    public IAggregateRepository getOppRepo() {
      List<Schema.SObjectField> queryFields = new List<Schema.SObjectField>{
        Opportunity.IsWon,
        Opportunity.StageName
        // etc ...
      };
      IAggregateRepository oppRepo = this.facade.getRepo(Opportunity.SObjectType, queryFields, this);
      oppRepo.addParentFields(
        new List<Schema.SObjectField>{ Opportunity.AccountId },
        new List<Schema.SObjectField>{ Account.Id }
      );
      return oppRepo;
    }

    public IHistoryRepository getOppFieldHistoryRepo() {
      return this.facade.getRepo(OpportunityFieldHistory.SObjectType, new List<Schema.SObjectField>(), this)
        .setParentField(OpportunityFieldHistory.OpportunityId);
    }
  }
}
