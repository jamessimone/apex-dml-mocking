@IsTest
private class HistoryRepoTests {
  @IsTest
  static void it_should_continue_to_act_as_base_repo() {
    List<Profile> profiles = new RepoFactory().getProfileRepo().get(Query.equals(Profile.Name, 'System Administrator'));
    System.assertNotEquals(null, profiles);

    IHistoryRepository historyRepo = new FieldLevelHistoryRepo(
      OpportunityFieldHistory.OpportunityId,
      OpportunityFieldHistory.SObjectType,
      OpportunityFieldHistoryExample.class,
      new RepoFactory()
    );
    // validate history repo can still return SObjects ...
    List<OpportunityFieldHistory> histories = historyRepo.get(Query.equals(OpportunityFieldHistory.OpportunityId, ''));
    System.assertNotEquals(null, histories);
  }

  @IsTest
  static void it_should_continue_to_act_as_aggregate_repo() {
    Aggregation count = Aggregation.count(OpportunityFieldHistory.Id, 'countId');
    IAggregateRepository repo = new FieldLevelHistoryRepo(
      OpportunityFieldHistory.OpportunityId,
      OpportunityFieldHistory.SObjectType,
      OpportunityFieldHistoryExample.class,
      new RepoFactory()
    );
    repo.groupBy(OpportunityFieldHistory.OpportunityId);

    List<AggregateRecord> records = repo.aggregate(count);

    // It's not much of an assert, but at least we know the query went through successfully
    System.assertEquals(true, records.isEmpty());
  }

  @IsTest
  static void it_should_query_history_records() {
    IHistoryRepository historyRepo = new FieldLevelHistoryRepo(
      OpportunityFieldHistory.OpportunityId,
      OpportunityFieldHistory.SObjectType,
      OpportunityFieldHistoryExample.class,
      new RepoFactory()
    );
    List<FieldLevelHistory> histories = historyRepo.getAllHistory();
    // History records can't be created during Apex unit testing, but we can at least validate the query
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
    /**
     * normally, you would be adding an IHistoryRepo implementation to the RepoFactory, and then overriding
     * within RepoFactoryMock the concrete implementation with the call to getRepoFromSObjectType. Since I don't
     * want to continue adding outer classes to force-app, however, we'll bypass that step here; you would be doing the equivalent
     * of the AccountHandlerTests, though - either calling the base Factory to initialize a class with an IHistoryRepository dependency,
     * or just new RepoFactoryMock().getMyAlreadyOverriddenRepo() to test the implementation directly.
     * All of that is to say: the whole point behind this pattern is to have dependencies be registered in the Factory, and Repository
     * implementations stubbed out in RepoFactoryMocks
     */
    IHistoryRepository historyRepo = new RepoFactoryMock()
      .getRepoFromSObjectType(OpportunityFieldHistory.SObjectType, null);

    List<FieldLevelHistory> histories = historyRepo.getAllHistory();
    System.assertNotEquals(true, histories.isEmpty());
    System.assertEquals(mockRecord, histories[0]);
  }

  private class OpportunityFieldHistoryExample extends FieldLevelHistory {
    protected override String getParentFieldName() {
      return OpportunityFieldHistory.OpportunityId.getDescribe().getName();
    }
  }
}
