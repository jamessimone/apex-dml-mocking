@IsTest
private class RepoFactoryMockTest {
  @IsTest
  static void addsChildrenInMemory() {
    Account acc = new Account();
    String expectedOppName = 'Hello';
    List<SObject> opps = new List<Opportunity>{ new Opportunity(Name = expectedOppName) };
    // can't simply do acc.Opportunities = opps - this leads to "Field is not writeable: Account.Opportunities" on deploy
    Assert.areEqual(0, acc.Opportunities.size(), 'Test has started under the wrong conditions');

    acc = (Account) RepoFactoryMock.addChildrenToRecord(acc, Opportunity.AccountId, opps);

    Assert.areEqual(1, acc.Opportunities.size());
    Assert.areEqual(expectedOppName, acc.Opportunities.get(0).Name);
  }

  @IsTest
  static void addsMockCursor() {
    Account acc = new Account(Id = TestingUtils.generateId(Schema.Account.SObjectType));
    Account secondAccount = new Account(Id = TestingUtils.generateId(Schema.Account.SObjectType));
    RepoFactoryMock.CursorResults.put(
      Account.SObjectType,
      new List<Cursor>{ new RepoFactoryMock.CursorMock(new List<Account>{ acc, secondAccount }) }
    );

    RepoFactoryMock.FacadeMock facade = new RepoFactoryMock.FacadeMock();
    IHistoryRepository repo = facade.getRepo(
      Account.SObjectType,
      new List<Schema.SObjectField>(),
      new RepoFactoryMock()
    );
    Cursor cursor = repo.getCursor(new List<Query>());

    Assert.areEqual(2, cursor.getNumRecords());
    Assert.areEqual(acc.Id, cursor.fetch(0, 1)[0].Id);
    // verify we don't overindex past the actual cursor end
    Assert.areEqual(secondAccount.Id, cursor.fetch(1, 3)[0].Id);
  }
}
