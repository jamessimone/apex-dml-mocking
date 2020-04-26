@isTest
private class QueryTests {
    @isTest
    static void it_should_encapsulate_sobject_fields_and_values() {
        Query basicQuery = new Query(Opportunity.IsWon, Query.Operator.EQUALS, true);

        System.assertEquals('IsWon = true', basicQuery.toString());
    }

    @isTest
    static void it_should_equal_another_query_with_the_same_values() {
        Query basicQuery = new Query(Opportunity.IsWon, Query.Operator.EQUALS, true);
        Query sameQuery = new Query(Opportunity.IsWon, Query.Operator.EQUALS, true);
        System.assertEquals(basicQuery, sameQuery);
    }

    @isTest
    static void it_should_properly_render_datetimes_as_strings() {
        Datetime sevenDaysAgo = System.now().addDays(-7);
        Query basicQuery = new Query(
            Opportunity.CreatedDate,
            Query.Operator.GREATER_THAN_OR_EQUAL,
            sevenDaysAgo
        );

        System.assertEquals(
            'CreatedDate >= ' + sevenDaysAgo.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time'),
             basicQuery.toString()
        );
    }

    @isTest
    static void it_should_properly_handle_numbers() {
        Double number1 = 1261992;
        Integer number2 = 1;
        Decimal number3 = 1.00;
        Long number4 = 1234567890;

        Query doubleQuery = new Query(Opportunity.Amount, Query.Operator.EQUALS, number1);
        Query intQuery = new Query(Opportunity.Amount, Query.Operator.EQUALS, number2);
        Query decimalQuery = new Query(Opportunity.Amount, Query.Operator.EQUALS, number3);
        Query longQuery = new Query(Opportunity.Amount, Query.Operator.EQUALS, number4);

        System.assertEquals('Amount = 1261992.0', doubleQuery.toString(), 'double');
        System.assertEquals('Amount = 1', intQuery.toString(), 'int');
        System.assertEquals('Amount = 1.00', decimalQuery.toString(), 'decimal');
        System.assertEquals('Amount = 1234567890', longQuery.toString(), 'long');
    }

    @isTest
    static void it_should_properly_handle_nulls() {
        Id nullId = null;

        Query idQuery = new Query(Opportunity.Id, Query.Operator.EQUALS, nullId);

        System.assertEquals('Id = null', idQuery.toString());
    }
}