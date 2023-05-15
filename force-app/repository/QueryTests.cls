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
  static void it_works_with_datetimes() {
    Datetime sevenDaysAgo = System.now().addDays(-7);
    Query greaterThan = Query.greaterThan(Opportunity.CreatedDate, sevenDaysAgo);
    Query basicQuery = Query.greaterThanOrEqual(Opportunity.CreatedDate, sevenDaysAgo);

    System.assertEquals('CreatedDate > :bindVar0', greaterThan.toString());
    System.assertEquals('CreatedDate >= :bindVar1', basicQuery.toString());
    System.assertEquals(sevenDaysAgo, greaterThan.getBindVars().get('bindVar0'));
    System.assertEquals(sevenDaysAgo, basicQuery.getBindVars().get('bindVar1'));
  }

  @IsTest
  static void it_should_properly_format_comparison_queries() {
    Query lessThan = Query.lessThan(Opportunity.Amount, 0);
    Query lessThanOrEqual = Query.lessThanOrEqual(Opportunity.Amount, 0);

    System.assertEquals('Amount < :bindVar0', lessThan.toString());
    System.assertEquals(0, lessThan.getBindVars().get('bindVar0'));
    System.assertEquals('Amount <= :bindVar1', lessThanOrEqual.toString());
    System.assertEquals(0, lessThanOrEqual.getBindVars().get('bindVar1'));

    Query notEquals = Query.notEquals(Opportunity.Amount, 0);
    System.assertEquals('Amount != :bindVar2', notEquals.toString());
    System.assertEquals(0, notEquals.getBindVars().get('bindVar2'));
    Query notEqualsIterable = Query.notEquals(Opportunity.Amount, new List<Integer>{ 0, 1, 2 });
    System.assertEquals('Amount != :bindVar3', notEqualsIterable.toString());
    System.assertEquals(new List<Integer>{ 0, 1, 2 }, notEqualsIterable.getBindVars().get('bindVar3'));
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

    System.assertEquals('Amount = :bindVar0', doubleQuery.toString(), 'double');
    System.assertEquals(number1, doubleQuery.getBindVars().get('bindVar0'));
    System.assertEquals('Amount = :bindVar1', intQuery.toString(), 'int');
    System.assertEquals(number2, intQuery.getBindVars().get('bindVar1'));
    System.assertEquals('Amount = :bindVar2', decimalQuery.toString(), 'decimal');
    System.assertEquals(number3, decimalQuery.getBindVars().get('bindVar2'));
    System.assertEquals('Amount = :bindVar3', longQuery.toString(), 'long');
    System.assertEquals(number4, longQuery.getBindVars().get('bindVar3'));
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
  static void it_should_allow_nested_and_statements() {
    String expected = '(LastName = :bindVar0 OR LastName = :bindVar1 OR (FirstName = :bindVar2 AND (LastName != :bindVar3 OR LastName != :bindVar4)))';

    System.assertEquals(
      expected,
      Query.orQuery(
          new List<Query>{
            Query.equals(Contact.LastName, 'asd'),
            Query.equals(Contact.LastName, 'asb'),
            Query.andQuery(
              Query.equals(Contact.FirstName, 'John'),
              Query.orQuery(Query.notEquals(Contact.LastName, 'a'), Query.notEquals(Contact.LastName, 'b'))
            )
          }
        )
        .toString()
    );
  }

  @IsTest
  static void it_should_allow_like_statements() {
    String expectedName = '%someName%';

    Query likeQuery = Query.likeQuery(Account.Name, expectedName);

    System.assertEquals('Name like :bindVar0', likeQuery.toString());
    System.assertEquals(expectedName, likeQuery.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void it_should_allow_not_like_statements() {
    String expectedName = '%someName%';

    Query notLike = Query.notLike(Account.Name, expectedName);

    System.assertEquals('not Name like :bindVar0', notLike.toString());
    System.assertEquals(expectedName, notLike.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void it_should_allow_not_like_with_lists() {
    String firstVal = '%one';
    String secondVal = 'two%';
    List<String> values = new List<String>{ firstVal, secondVal };

    Query notLike = Query.notLike(Account.Name, values);

    System.assertEquals('not Name like :bindVar0', notLike.toString());
    System.assertEquals(values, notLike.getBindVars().get('bindVar0'));
  }

  @IsTest
  static void it_should_allow_parent_fields_for_filtering() {
    Query parentQuery = Query.equals(Group.DeveloperName, 'SOME_CONSTANT.DeveloperName')
      .usingParent(GroupMember.GroupId);
    System.assertEquals('Group.DeveloperName = :bindVar0', parentQuery.toString());
    System.assertEquals('SOME_CONSTANT.DeveloperName', parentQuery.getBindVars().get('bindVar0'));
    Query oliParentQuery = Query.equals(Profile.Name, 'System Administrator')
      .usingParent(
        new List<Schema.SObjectField>{
          OpportunityLineItem.OpportunityId,
          Opportunity.AccountId,
          Account.OwnerId,
          User.ProfileId
        }
      );
    System.assertEquals('Opportunity.Account.Owner.Profile.Name = :bindVar1', oliParentQuery.toString());
    System.assertEquals('System Administrator', oliParentQuery.getBindVars().get('bindVar1'));
  }

  @IsTest
  static void it_allows_empty_collections_for_not_equals() {
    Query notEquals = Query.notEquals(Opportunity.AccountId, new Set<Id>());

    System.assertEquals('AccountId != :bindVar0', notEquals.toString());
    System.assertEquals(new Set<Id>(), notEquals.getBindVars().get('bindVar0'));
  }
}
