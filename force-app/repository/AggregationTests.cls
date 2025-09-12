@IsTest
private class AggregationTests {
  @IsTest
  static void shouldCorrectlyFormatSum() {
    String expectedAlias = 'myAlias';
    Aggregation agg = Aggregation.sum(Opportunity.Amount, expectedAlias);
    Assert.areEqual('SUM(Amount) myAlias', agg.toString());
    Assert.areEqual(expectedAlias, agg.getAlias());
  }

  @IsTest
  static void shouldCorrectlyFormatCountDistinct() {
    String expectedAlias = 'myAlias';
    Aggregation agg = Aggregation.countDistinct(Opportunity.StageName, expectedAlias);
    Assert.areEqual('COUNT_DISTINCT(StageName) myAlias', agg.toString());
    Assert.areEqual(expectedAlias, agg.getAlias());
  }
}
