@IsTest
private class FieldLevelHistoryRepoTests {
  @IsTest
  static void it_should_continue_to_act_as_base_repo() {
    IHistoryRepository historyRepo = new ExampleRepoFactory().getOppFieldHistoryRepo();

    List<OpportunityFieldHistory> histories = historyRepo.get(
      Query.equals(OpportunityFieldHistory.OpportunityId, null)
    );

    System.assertNotEquals(null, histories);
  }

  @IsTest
  static void it_should_continue_to_act_as_aggregate_repo() {
    Aggregation count = Aggregation.count(OpportunityFieldHistory.Id, 'countId');
    IAggregateRepository repo = new ExampleRepoFactory().getOppFieldHistoryRepo();
    repo.groupBy(OpportunityFieldHistory.OpportunityId);

    List<AggregateRecord> records = repo.aggregate(count);

    // It's not much of an assert, but at least we know the query went through successfully
    System.assertEquals(true, records.isEmpty());
  }

  @IsTest
  static void it_should_query_history_records() {
    IHistoryRepository historyRepo = new ExampleRepoFactory().getOppFieldHistoryRepo();

    List<FieldLevelHistory> histories = historyRepo.getAllHistory();
    // History records can't be created during Apex unit testing, but we can at least validate the query
    // and prove that the FieldLevelHistory decorator list is returned properly
    System.assertEquals(true, histories.isEmpty());
  }

  @IsTest
  static void it_should_allow_mocking_of_history_records() {
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

    IHistoryRepository historyRepo = new ExampleRepoFactory().getOppFieldHistoryRepo();

    List<FieldLevelHistory> histories = historyRepo.getAllHistory();
    System.assertNotEquals(true, histories.isEmpty());
    System.assertEquals(mockRecord, histories[0]);
  }

  private without sharing class ExampleRepoFactory extends RepoFactory {
    private ExampleRepoFactory() {
      this.facade = new RepoFactoryMock.FacadeMock();
    }
    public IHistoryRepository getOppFieldHistoryRepo() {
      return this.facade.getRepo(OpportunityFieldHistory.SObjectType, new List<Schema.SObjectField>(), this)
        .setParentField(OpportunityFieldHistory.OpportunityId);
    }
  }
}
