@IsTest
private class AccountHandlerTests {
  @IsTest
  static void it_should_insert_new_opps_when_accounts_are_inserted() {
    Account acc = new Account(Name = 'Test Corp.', Id = TestingUtils.generateId(Account.SObjectType));

    ExampleFactory.getFactory().withMocks.getAccountHandler().beforeInsert(new List<SObject>{ acc });

    Opportunity insertedOpp = (Opportunity) DMLMock.Inserted.Opportunities.singleOrDefault;
    System.assertNotEquals(null, insertedOpp, 'Opp should have been inserted!');
    System.assertEquals('Prospecting Opp for: Test Corp.', insertedOpp.Name);
    System.assertEquals(acc.Id, insertedOpp.AccountId);
  }
}
