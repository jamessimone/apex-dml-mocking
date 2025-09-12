@IsTest
private class AccountHandlerTests {
  @IsTest
  static void itShouldInsertNewOppsWhenAccountsAreInserted() {
    Account acc = new Account(Name = 'Test Corp.', Id = TestingUtils.generateId(Account.SObjectType));

    // this is a unit test; an integration test would have a trigger on Account,
    // and you would insert/update the Account in order to test end-to-end that your trigger
    // correctly called your handler, which correctly did the things you cared about.
    // a unit test for a handler does not rely on DML; it does not actually update entities in the database;
    // it purely tests inputs and outputs for the expected results
    ExampleFactory.getFactory()
      .withMocks.getAccountHandler()
      .afterInsert(new List<SObject>{ acc }, new Map<Id, SObject>(new List<SObject>{ acc }));

    Opportunity insertedOpp = (Opportunity) DMLMock.Inserted.Opportunities.singleOrDefault;
    Assert.areNotEqual(null, insertedOpp, 'Opp should have been inserted!');
    Assert.areEqual('Prospecting Opp for: Test Corp.', insertedOpp.Name);
    Assert.areEqual(acc.Id, insertedOpp.AccountId);
  }
}
