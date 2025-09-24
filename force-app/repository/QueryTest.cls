@IsTest
private class QueryTest {
  @IsTest
  static void itShouldEncapsulateSobjectFieldsAndValues() {
    Query basicQuery = Query.equals(Opportunity.IsWon, true);

    Assert.areEqual('IsWon = true', basicQuery.toString());
  }

  @IsTest
  static void itShouldEqualAnotherQueryWithTheSameValues() {
    Query basicQuery = Query.equals(Opportunity.IsWon, true);
    Query sameQuery = Query.equals(Opportunity.IsWon, true);
    Assert.areEqual(basicQuery, sameQuery);
  }

  @IsTest
  static void itShouldEqualAnotherQueryWithTheSameStringValues() {
    Query basicQuery = Query.equals(Opportunity.Name, 'some string value');
    Query sameQuery = Query.equals(Opportunity.Name, 'some string value');

    Assert.areEqual(basicQuery, sameQuery);
  }

  @IsTest
  static void itShouldNotEqualAnotherQueryWithDifferentStringValues() {
    Query basicQuery = Query.equals(Opportunity.Name, 'some string value');
    Query differentQuery = Query.equals(Opportunity.Name, 'another string value');

    System.assertNotEquals(basicQuery, differentQuery);
  }

  @IsTest
  static void itWorksWithDatetimes() {
    Datetime sevenDaysAgo = System.now().addDays(-7);
    Query greaterThan = Query.greaterThan(Opportunity.CreatedDate, sevenDaysAgo);
    Query basicQuery = Query.greaterThanOrEqual(Opportunity.CreatedDate, sevenDaysAgo);
    Query.shouldPerformStrictEquals = true;

    Assert.areEqual('CreatedDate > ' + sevenDaysAgo, greaterThan.toString());
    Assert.areEqual('CreatedDate >= ' + sevenDaysAgo, basicQuery.toString());
    Assert.areEqual(sevenDaysAgo, greaterThan.getBindVars().get('bindVar0'));
    Assert.areEqual(sevenDaysAgo, basicQuery.getBindVars().get('bindVar1'));
  }

  @IsTest
  static void itShouldProperlyFormatComparisonQueries() {
    Query lessThan = Query.lessThan(Opportunity.Amount, 0);
    Query lessThanOrEqual = Query.lessThanOrEqual(Opportunity.Amount, 0);

    Assert.areEqual('Amount < :bindVar0', lessThan.toString());
    Assert.areEqual(0, lessThan.getBindVars().get('bindVar0'));
    Assert.areEqual('Amount <= :bindVar1', lessThanOrEqual.toString());
    Assert.areEqual(0, lessThanOrEqual.getBindVars().get('bindVar1'));

    Query notEquals = Query.notEquals(Opportunity.Amount, 0);
    Assert.areEqual('Amount != :bindVar2', notEquals.toString());
    Assert.areEqual(0, notEquals.getBindVars().get('bindVar2'));
    Query notEqualsIterable = Query.notEquals(Opportunity.Amount, new List<Integer>{ 0, 1, 2 });
    Assert.areEqual('Amount != :bindVar3', notEqualsIterable.toString());
    Assert.areEqual(new List<Integer>{ 0, 1, 2 }, notEqualsIterable.getBindVars().get('bindVar3'));
  }

  @IsTest
  static void itShouldProperlyHandleNumbers() {
    Double number1 = 1261992;
    Integer number2 = 1;
    Decimal number3 = 1.00;
    Long number4 = 1234567890;

    Query doubleQuery = Query.equals(Opportunity.Amount, number1);
    Query intQuery = Query.equals(Opportunity.Amount, number2);
    Query decimalQuery = Query.equals(Opportunity.Amount, number3);
    Query longQuery = Query.equals(Opportunity.Amount, number4);
    Query.shouldPerformStrictEquals = true;

    Assert.areEqual('Amount = ' + number1, doubleQuery.toString(), 'double');
    Assert.areEqual(number1, doubleQuery.getBindVars().get('bindVar0'));
    Assert.areEqual('Amount = ' + number2, intQuery.toString(), 'int');
    Assert.areEqual(number2, intQuery.getBindVars().get('bindVar1'));
    Assert.areEqual('Amount = ' + number3, decimalQuery.toString(), 'decimal');
    Assert.areEqual(number3, decimalQuery.getBindVars().get('bindVar2'));
    Assert.areEqual('Amount = ' + number4, longQuery.toString(), 'long');
    Assert.areEqual(number4, longQuery.getBindVars().get('bindVar3'));
  }

  @IsTest
  static void itShouldProperlyHandleNulls() {
    Id nullId = null;

    Query idQuery = Query.equals(Opportunity.Id, nullId);

    Assert.areEqual('Id = null', idQuery.toString());
  }

  @IsTest
  static void itShouldAllowOrStatements() {
    Id nullId = null;
    String expectedQuery = '(Id = null OR Id != null)';

    Query orQuery = Query.orQuery(Query.equals(Account.Id, nullId), Query.notEquals(Account.Id, nullId));

    Assert.areEqual(expectedQuery, orQuery.toString());
  }

  @IsTest
  static void itShouldAllowNestedAndStatements() {
    String regexExpected = '\\(LastName = :bindVar\\d OR LastName = :bindVar\\d OR \\(FirstName = :bindVar\\d AND \\(LastName != :bindVar\\d OR LastName != :bindVar\\d\\)\\)\\)';
    // String expected = '(LastName = :bindVar0 OR LastName = :bindVar1 OR (FirstName = :bindVar2 AND (LastName != :bindVar3 OR LastName != :bindVar4)))';

    Query output = Query.orQuery(
      new List<Query>{
        Query.equals(Contact.LastName, 'asd'),
        Query.equals(Contact.LastName, 'asb'),
        Query.andQuery(
          Query.equals(Contact.FirstName, 'John'),
          Query.orQuery(Query.notEquals(Contact.LastName, 'a'), Query.notEquals(Contact.LastName, 'b'))
        )
      }
    );

    Assert.areEqual(true, Pattern.compile(regexExpected).matcher(output.toString()).matches());
    // Assert.areEqual(expected, output.toString());
  }

  @IsTest
  static void itShouldAllowLikeStatements() {
    String expectedName = '%someName%';

    Query likeQuery = Query.likeQuery(Account.Name, expectedName);

    Assert.areEqual('Name LIKE :bindVar0', likeQuery.toString());
    Assert.areEqual(expectedName, likeQuery.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void itShouldAllowNotLikeStatements() {
    String expectedName = '%someName%';

    Query notLike = Query.notLike(Account.Name, expectedName);
    Query.shouldPerformStrictEquals = true;

    Assert.areEqual('NOT Name LIKE ' + expectedName, notLike.toString());
    Assert.areEqual(expectedName, notLike.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void itShouldAllowNotLikeWithLists() {
    String firstVal = '%one';
    String secondVal = 'two%';
    List<String> values = new List<String>{ firstVal, secondVal };

    Query notLike = Query.notLike(Account.Name, values);
    Query.shouldPerformStrictEquals = true;

    Assert.areEqual('NOT Name LIKE ' + values, notLike.toString());
    Assert.areEqual(values, notLike.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void itShouldAllowParentFieldsForFiltering() {
    Query parentQuery = Query.equals(Group.DeveloperName, 'SOME_CONSTANT.DeveloperName')
      .usingParent(GroupMember.GroupId);
    Assert.areEqual('Group.DeveloperName = :bindVar0', parentQuery.toString());
    Assert.areEqual('SOME_CONSTANT.DeveloperName', parentQuery.getBindVars().get('bindVar0'));

    Query oliParentQuery = Query.equals(Profile.Name, 'System Administrator')
      .usingParent(
        new List<Schema.SObjectField>{
          OpportunityLineItem.OpportunityId,
          Opportunity.AccountId,
          Account.OwnerId,
          User.ProfileId
        }
      );

    Assert.areEqual('SOME_CONSTANT.DeveloperName', parentQuery.getBindVars().get('bindVar0'));
    Assert.areEqual('Opportunity.Account.Owner.Profile.Name = :bindVar1', oliParentQuery.toString());
    Assert.areEqual('System Administrator', oliParentQuery.getBindVars().get('bindVar1'));
  }

  @IsTest
  static void itAllowsEmptyCollectionsForNotEquals() {
    Query notEquals = Query.notEquals(Opportunity.AccountId, new Set<Id>());

    Assert.areEqual('AccountId != :bindVar0', notEquals.toString());
    Assert.areEqual(new Set<Id>(), notEquals.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void itAllowsSubqueries() {
    Query subquery = Query.subquery(
      Contact.AccountId,
      Account.Id,
      Query.andQuery(
        new List<Query>{
          Query.equals(Account.AnnualRevenue, 50),
          Query.equals(Account.Industry, 'Tech'),
          Query.orQuery(
            new List<Query>{ Query.equals(Account.NumberOfEmployees, 1), Query.equals(Account.Site, 'web3') }
          )
        }
      )
    );

    String regex = 'AccountId IN \\(SELECT Id FROM Account WHERE \\(AnnualRevenue = :bindVar\\d AND Industry = :bindVar\\d AND \\(NumberOfEmployees = :bindVar\\d OR Site = :bindVar\\d\\)\\)\\)';
    Assert.areEqual(true, Pattern.compile(regex).matcher(subquery.toString()).matches());
    // Assert.areEqual(
    //   'AccountId IN (SELECT Id FROM Account WHERE (AnnualRevenue = :bindVar0 AND Industry = :bindVar1 AND (NumberOfEmployees = :bindVar2 OR Site = :bindVar3)))',
    //   subquery.toString()
    // );
  }

  @IsTest
  static void itWorksWithCollectionsForSoslQueriesNotIn() {
    List<Id> fakeAccountIds = new List<Id>{
      TestingUtils.generateId(Account.SObjectType),
      TestingUtils.generateId(Account.SObjectType)
    };

    Query query = Query.notEquals(Account.Id, fakeAccountIds);

    Assert.areEqual('Id NOT IN (\'' + String.join(fakeAccountIds, '\',\'') + '\')', query.toSoslString());
  }

  @IsTest
  static void itWorksWithCollectionsForSoslQueriesIn() {
    List<Id> fakeAccountIds = new List<Id>{
      TestingUtils.generateId(Account.SObjectType),
      TestingUtils.generateId(Account.SObjectType)
    };

    Query query = Query.equals(Account.Id, fakeAccountIds);

    Assert.areEqual('Id IN (\'' + String.join(fakeAccountIds, '\',\'') + '\')', query.toSoslString());
  }

  @IsTest
  static void itWorksForSingularValueInCollections() {
    List<Id> fakeAccountIds = new List<Id>{ TestingUtils.generateId(Account.SObjectType) };

    Query query = Query.equals(Account.Id, fakeAccountIds);

    Assert.areEqual('Id IN (\'' + String.join(fakeAccountIds, '\',\'') + '\')', query.toSoslString());
  }

  @IsTest
  static void itDoesNotAddEmptyParenthesisToTheEnd() {
    Query query = Query.andQuery(
      new List<Query>{ Query.equals(Account.Id, new List<Id>()), Query.orQuery(new List<Query>()) }
    );

    Assert.areEqual('(Id = :bindVar0)', query.toString());
  }
}
