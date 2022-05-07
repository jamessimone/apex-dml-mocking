@IsTest
class ExampleSObjectTest {

    @IsTest
    static void runTest () {
        Repository repo = new Repository(
            ExampleSObject__c.SObjectType,
            new SObjectField[] { ExampleSObject__c.Id, ExampleSObject__c.Name },
            new RepoFactory()
        );

        repo.addParentFields(
            new SObjectType[] { Account.SObjectType },
            new SObjectField[] { Account.Name }
        );

        repo.getAll();
    }

}
