@isTest
private class QueryTests {
  @isTest
  static void it_should_encapsulate_sobject_fields_and_values() {
    Query basicQuery = Query.equals(Opportunity.IsWon, true);

    System.assertEquals('IsWon = true', basicQuery.toString());
  }

  @isTest
  static void it_should_equal_another_query_with_the_same_values() {
    Query basicQuery = Query.equals(Opportunity.IsWon, true);
    Query sameQuery = Query.equals(Opportunity.IsWon, true);
    System.assertEquals(basicQuery, sameQuery);
  }

  @isTest
  static void it_should_properly_render_datetimes_as_strings() {
    Datetime sevenDaysAgo = System.now().addDays(-7);
    Query greaterThan = Query.greaterThan(Opportunity.CreatedDate, sevenDaysAgo);
    Query basicQuery = Query.greaterThanOrEqual(Opportunity.CreatedDate, sevenDaysAgo);

    String expectedTimeString = sevenDaysAgo.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    System.assertEquals('CreatedDate > ' + expectedTimeString, greaterThan.toString());
    System.assertEquals('CreatedDate >= ' + expectedTimeString, basicQuery.toString());
  }

  @isTest
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

  @isTest
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

  @isTest
  static void it_should_properly_handle_nulls() {
    Id nullId = null;

    Query idQuery = Query.equals(Opportunity.Id, nullId);

    System.assertEquals('Id = null', idQuery.toString());
  }
}
