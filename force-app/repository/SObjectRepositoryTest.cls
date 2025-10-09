@IsTest
private class SObjectRepositoryTest {
  @IsTest
  static void queriesWithGenericRepo() {
    Account acc = new Account(Name = SObjectRepositoryTest.class.getName() + System.now().getTime());
    insert acc;

    List<SObject> results = new SObjectRepository(
        Schema.Account.SObjectType,
        new List<Schema.SObjectField>(),
        new RepoFactory()
      )
      .getAll();

    Assert.areEqual(1, results.size());
    Assert.areEqual(acc.Id, results[0].Id);
  }
}
