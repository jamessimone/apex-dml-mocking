@IsTest
private class QueryFieldTest {
  @IsTest
  static void parentFieldChainsConcatenatedProperly() {
    QueryField queryField = new QueryField(
      new List<Schema.SObjectField>{ Contact.AccountId, Account.OwnerId },
      new List<Schema.SObjectField>{ User.Email }
    );

    Assert.areEqual('Account.Owner.Email', queryField.toString());
  }

  @IsTest
  static void concatenatesFieldsProperly() {
    QueryField queryField = new QueryField(new List<Schema.SObjectField>{ Contact.AccountId, Contact.LastName });

    Assert.areEqual('AccountId,LastName', queryField.toString());
  }
}
