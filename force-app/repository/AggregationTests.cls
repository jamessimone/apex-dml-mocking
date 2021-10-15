@IsTest
private class AggregationTests {
  @IsTest
  static void shouldCorrectlyFormatSum() {
    String expectedAlias = 'myAlias';
    Aggregation agg = Aggregation.sum(Opportunity.Amount, expectedAlias);
    System.assertEquals('SUM(Amount) myAlias', agg.toString());
    System.assertEquals(expectedAlias, agg.getAlias());
  }

  @IsTest
  static void shouldCorrectlyFormatCountDistinct() {
    String expectedAlias = 'myAlias';
    Aggregation agg = Aggregation.countDistinct(Opportunity.StageName, expectedAlias);
    System.assertEquals('COUNT_DISTINCT(StageName) myAlias', agg.toString());
    System.assertEquals(expectedAlias, agg.getAlias());
  }
}