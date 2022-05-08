@IsTest
private class ExampleSObjectTest {
  @TestSetup
  static void setup() {
    Account acc = new Account(Name = ExampleSObjectTest.class.getName());
    insert acc;
    insert new ExampleSObject__c(Account__c = acc.Id, SecondAccountLookup__c = acc.Id, Name = 'Child');
  }

  @IsTest
  static void correctlyReturnsCustomObjectParents() {
    Repository repo = new Repository(
      ExampleSObject__c.SObjectType,
      new List<Schema.SObjectField>{ ExampleSObject__c.Id, ExampleSObject__c.Name },
      new RepoFactory()
    );
    repo.addParentFields(
      new List<Schema.SObjectField>{ ExampleSObject__c.Account__c },
      new List<Schema.SObjectField>{ Account.Name }
    );
    repo.addParentFields(
      new List<Schema.SObjectField>{ ExampleSObject__c.SecondAccountLookup__c },
      new List<Schema.SObjectField>{ Account.Name }
    );

    List<ExampleSObject__c> children = repo.getAll();

    ExampleSObject__c expected = [SELECT Id, Account__r.Name, SecondAccountLookup__r.Name FROM ExampleSObject__c];
    System.assertEquals(1, children.size());
    System.assertEquals(expected.Account__r.Name, children.get(0).Account__r.Name);
    System.assertEquals(expected.SecondAccountLookup__r.Name, children.get(0).SecondAccountLookup__r.Name);
  }

  @IsTest
  static void correctlyReturnsCustomObjectChildren() {
    Repository repo = new Repository(
      Account.SObjectType,
      new List<Schema.SObjectField>{ Account.Name },
      new RepoFactory()
    );
    repo.addChildFields(ExampleSObject__c.Account__c, new List<Schema.SObjectField>{ ExampleSObject__c.Name });
    repo.addChildFields(
      ExampleSObject__c.SecondAccountLookup__c,
      new List<Schema.SObjectField>{ ExampleSObject__c.Name }
    );

    Account expected = [
      SELECT (SELECT Name FROM Example_SObjects__r), (SELECT Name FROM Example_SObjects1__r)
      FROM Account
    ];
    Account actual = (Account) repo.getAll().get(0);
    System.assertEquals(1, actual.Example_SObjects__r.size());
    System.assertEquals(expected.Example_SObjects__r, actual.Example_SObjects__r);
    System.assertEquals(1, actual.Example_SObjects1__r.size());
    System.assertEquals(expected.Example_SObjects1__r, actual.Example_SObjects1__r);
  }
}
