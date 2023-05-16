public class AggregateRecord {
  private final Map<String, Object> keyToAggregateResult = new Map<String, Object>();

  public AggregateRecord putAll(Map<String, Object> values) {
    this.keyToAggregateResult.putAll(values);
    return this;
  }

  public Object get(String key) {
    return this.keyToAggregateResult.get(key);
  }

  public Boolean equals(Object that) {
    if (that instanceof AggregateResult) {
      Map<String, Object> thatKeyToAggregateResult = ((AggregateResult) that).getPopulatedFieldsAsMap();
      return this.keyToAggregateResult.equals(thatKeyToAggregateResult);
    } else if (that instanceof AggregateRecord) {
      return this.keyToAggregateResult.equals(((AggregateRecord) that).keyToAggregateResult);
    }
    return false;
  }
}
