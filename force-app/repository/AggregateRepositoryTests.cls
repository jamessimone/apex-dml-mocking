@IsTest
private class AggregateRepositoryTests {
  @IsTest
  static void shouldAggregateSum() {
    Account parent = new Account(Name = AggregateRepositoryTests.class.getName(), NumberOfEmployees = 1);
    Account secondParent = new Account(Name = 'Second parent', NumberOfEmployees = 1);
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
    System.assertEquals(
      1,
      repo.groupBy(new List<Schema.SObjectField>{ Opportunity.AccountId, Account.NumberOfEmployees })
        .aggregate(sum)
        .size()
    );
  }

  @IsTest
  static void shouldReturnCountOnFieldNameCorrectly() {
    insert new List<Opportunity>{
      new Opportunity(Name = 'opp', StageName = 'sum', CloseDate = System.today()),
      new Opportunity(Name = 'opp2', Amount = 1, StageName = 'sum', CloseDate = System.today())
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
    System.assertEquals(
      1,
      repo.addHaving(countOfAmount, Query.Operator.GREATER_THAN, 0)
          .groupBy(Opportunity.CloseDate)
          .aggregate(countOfAmount)[0]
        .get(countOfAmount.getAlias())
    );
    // prove equality works
    System.assert(results.get(0).equals([SELECT COUNT(Amount) wowza FROM Opportunity].get(0)));
    System.assertEquals(results.get(0), results.get(0));
  }

  @IsTest
  static void shouldReturnCountAsInteger() {
    insert new List<Opportunity>{
      new Opportunity(Name = 'opp', StageName = 'sum', CloseDate = System.today()),
      new Opportunity(Name = 'opp2', Amount = 1, StageName = 'sum', CloseDate = System.today())
    };
    IAggregateRepository repo = new AggregateRepository(
      Opportunity.SObjectType,
      new List<SObjectField>{ Opportunity.AccountId, Opportunity.Id, Opportunity.Amount },
      new RepoFactory()
    );

    System.assertEquals(2, repo.count());
  }

  @IsTest
  static void mocksAggregateResultsSuccessfully() {
    Aggregation countOfAmount = Aggregation.count(Opportunity.Amount, 'wowza');
    Aggregation sum = Aggregation.sum(Opportunity.Amount, 'oppSum');
    String accountKey = 'AccountId';
    Map<String, Object> mockAggregateResult = new Map<String, Object>{
      countOfAmount.getAlias() => 5,
      sum.getAlias() => 10,
      accountKey => TestingUtils.generateId(Account.SObjectType)
    };
    AggregateRecord res = new AggregateRecord().putAll(mockAggregateResult);
    RepoFactoryMock.AggregateResults.put(Opportunity.SObjectType, new List<AggregateRecord>{ res });

    List<AggregateRecord> results = new RepoFactory()
      .setFacade(new RepoFactoryMock.FacadeMock())
      .getOppRepo()
      .groupBy(Opportunity.AccountId)
      .aggregate(new List<Aggregation>{ countOfAmount, sum });

    System.assertEquals(1, results.size());
    AggregateRecord returnedResult = results.get(0);
    System.assertEquals(mockAggregateResult.get(accountKey), returnedResult.get(accountKey));
    System.assertEquals(
      mockAggregateResult.get(countOfAmount.getAlias()),
      returnedResult.get(countOfAmount.getAlias())
    );
    System.assertEquals(mockAggregateResult.get(sum.getAlias()), returnedResult.get(sum.getAlias()));
  }
}
