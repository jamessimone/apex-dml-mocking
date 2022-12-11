@IsTest
private class QueryTests {
  @IsTest
  static void it_should_encapsulate_sobject_fields_and_values() {
    Query basicQuery = Query.equals(Opportunity.IsWon, true);

    System.assertEquals('IsWon = true', basicQuery.toString());
  }

  @IsTest
  static void it_should_equal_another_query_with_the_same_values() {
    Query basicQuery = Query.equals(Opportunity.IsWon, true);
    Query sameQuery = Query.equals(Opportunity.IsWon, true);
    System.assertEquals(basicQuery, sameQuery);
  }

  @IsTest
  static void it_should_properly_render_datetimes_as_strings() {
    Datetime sevenDaysAgo = System.now().addDays(-7);
    Query greaterThan = Query.greaterThan(Opportunity.CreatedDate, sevenDaysAgo);
    Query basicQuery = Query.greaterThanOrEqual(Opportunity.CreatedDate, sevenDaysAgo);

    String expectedTimeString = sevenDaysAgo.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    System.assertEquals('CreatedDate > ' + expectedTimeString, greaterThan.toString());
    System.assertEquals('CreatedDate >= ' + expectedTimeString, basicQuery.toString());
  }

  @IsTest
  static void it_should_properly_format_comparison_queries() {
    String expectedLessThan = 'Amount < 0';
    String expectedLessThanOrEqual = 'Amount <= 0';

    Query lessThan = Query.lessThan(Opportunity.Amount, 0);
    Query lessThanOrEqual = Query.lessThanOrEqual(Opportunity.Amount, 0);

    System.assertEquals(expectedLessThan, lessThan.toString());
    System.assertEquals(expectedLessThanOrEqual, lessThanOrEqual.toString());

    String expectedNotEquals = 'Amount != 0';
    System.assertEquals(expectedNotEquals, Query.notEquals(Opportunity.Amount, 0).toString());
    String notEqualsIterable = 'Amount not in (0,1,2)';
    System.assertEquals(
      notEqualsIterable,
      Query.notEquals(Opportunity.Amount, new List<Integer>{ 0, 1, 2 }).toString()
    );
  }

  @IsTest
  static void it_should_properly_handle_numbers() {
    Double number1 = 1261992;
    Integer number2 = 1;
    Decimal number3 = 1.00;
    Long number4 = 1234567890;

    Query doubleQuery = Query.equals(Opportunity.Amount, number1);
    Query intQuery = Query.equals(Opportunity.Amount, number2);
    Query decimalQuery = Query.equals(Opportunity.Amount, number3);
    Query longQuery = Query.equals(Opportunity.Amount, number4);

    System.assertEquals('Amount = 1261992.0', doubleQuery.toString(), 'double');
    System.assertEquals('Amount = 1', intQuery.toString(), 'int');
    System.assertEquals('Amount = 1.00', decimalQuery.toString(), 'decimal');
    System.assertEquals('Amount = 1234567890', longQuery.toString(), 'long');
  }

  @IsTest
  static void it_should_properly_handle_nulls() {
    Id nullId = null;

    Query idQuery = Query.equals(Opportunity.Id, nullId);

    System.assertEquals('Id = null', idQuery.toString());
  }

  @IsTest
  static void it_should_allow_or_statements() {
    Id nullId = null;
    String expectedQuery = '(Id = null OR Id != null)';

    Query orQuery = Query.orQuery(Query.equals(Account.Id, nullId), Query.notEquals(Account.Id, nullId));

    System.assertEquals(expectedQuery, orQuery.toString());
  }

  @IsTest
  static void it_should_allow_like_statements() {
    String expectedName = '%someName%';

    Query likeQuery = Query.likeQuery(Account.Name, expectedName);

    System.assertEquals('Name like \'' + expectedName + '\'', likeQuery.toString());
  }

  @IsTest
  static void it_should_allow_not_like_statements() {
    String expectedName = '%someName%';

    Query notLike = Query.notLike(Account.Name, expectedName);

    System.assertEquals('not Name like \'' + expectedName + '\'', notLike.toString());
  }

  @IsTest
  static void it_should_allow_not_like_with_lists() {
    String firstVal = '%one';
    String secondVal = 'two%';
    List<String> expectedBindVars = new List<String>{ firstVal, secondVal };

    Query notLike = Query.notLike(Account.Name, expectedBindVars);

    System.assertEquals('not Name like :bindVar', notLike.toString());
    System.assertEquals(expectedBindVars, notLike.getBindVars());
  }

  @IsTest
  static void it_should_allow_parent_fields_for_filtering() {
    Query parentQuery = Query.equals(Group.DeveloperName, 'SOME_CONSTANT.DeveloperName')
      .usingParent(GroupMember.GroupId);
    System.assertEquals('Group.DeveloperName = \'SOME_CONSTANT.DeveloperName\'', parentQuery.toString());
    Query oliParentQuery = Query.equals(Profile.Name, 'System Administrator')
      .usingParent(
        new List<Schema.SObjectField>{
          OpportunityLineItem.OpportunityId,
          Opportunity.AccountId,
          Account.OwnerId,
          User.ProfileId
        }
      );
    System.assertEquals('Opportunity.Account.Owner.Profile.Name = \'System Administrator\'', oliParentQuery.toString());
  }

  @IsTest
  static void it_allows_empty_collections_for_not_equals() {
    Query notEquals = Query.notEquals(Opportunity.AccountId, new Set<Id>());

    System.assertEquals('AccountId != \'\'', notEquals.toString());
  }
}
