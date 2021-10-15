@IsTest
private class AggregateRepositoryTests {
  @IsTest
  static void shouldAggregateSum() {
    Account parent = new Account(Name = AggregateRepositoryTests.class.getName());
    Account secondParent = new Account(Name = 'Second parent');
    insert new List<Account>{ parent, secondParent };

    Opportunity opp = new Opportunity(
      Name = 'opp',
      Amount = 1,
      AccountId = parent.Id,
      StageName = 'sum',
      CloseDate = System.today()
    );
    Opportunity secondOpp = new Opportunity(
      Name = 'opp2',
      Amount = 1,
      AccountId = secondParent.Id,
      StageName = 'sum',
      CloseDate = System.today()
    );
    Opportunity anotherSecondParentMatch = new Opportunity(
      Name = 'opp3',
      Amount = 1,
      AccountId = secondParent.Id,
      StageName = 'sum',
      CloseDate = System.today()
    );
    insert new List<Opportunity>{ opp, secondOpp, anotherSecondParentMatch };

    Aggregation sum = Aggregation.sum(Opportunity.Amount, 'oppSum');
    IAggregateRepository repo = new AggregateRepository(
      Opportunity.SObjectType,
      new List<SObjectField>{ Opportunity.AccountId, Opportunity.Id, Opportunity.Amount },
      new RepoFactory()
    );
    repo.groupBy(Opportunity.AccountId);
    List<AggregateRecord> results = repo.aggregate(sum);

    System.assertEquals(2, results?.size());
    for (AggregateRecord res : results) {
      if (res.get('AccountId') == secondParent.Id) {
        System.assertEquals(2, res.get(sum.getAlias()));
      } else {
        System.assertEquals(1, res.get(sum.getAlias()));
      }
    }
  }

  @IsTest
  static void shouldReturnCountOnFieldNameCorrectly() {
    insert new List<Opportunity> {
      new Opportunity(
        Name = 'opp',
        StageName = 'sum',
        CloseDate = System.today()
      ),
      new Opportunity(
        Name = 'opp2',
        Amount = 1,
        StageName = 'sum',
        CloseDate = System.today()
      )
    };

    IAggregateRepository repo = new AggregateRepository(
      Opportunity.SObjectType,
      new List<SObjectField>{ Opportunity.AccountId, Opportunity.Id, Opportunity.Amount },
      new RepoFactory()
    );
    Aggregation countOfAmount = Aggregation.count(Opportunity.Amount, 'wowza');
    List<AggregateRecord> results = repo.aggregate(countOfAmount);

    System.assertEquals(1, results.size());
    System.assertEquals(1, results[0].get(countOfAmount.getAlias()));
  }

  @IsTest
  static void shouldReturnCountAsInteger() {
    insert new List<Opportunity> {
      new Opportunity(
        Name = 'opp',
        StageName = 'sum',
        CloseDate = System.today()
      ),
      new Opportunity(
        Name = 'opp2',
        Amount = 1,
        StageName = 'sum',
        CloseDate = System.today()
      )
    };
    IAggregateRepository repo = new AggregateRepository(
      Opportunity.SObjectType,
      new List<SObjectField>{ Opportunity.AccountId, Opportunity.Id, Opportunity.Amount },
      new RepoFactory()
    );

    System.assertEquals(2, repo.count());
  }
}