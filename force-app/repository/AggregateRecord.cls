public class AggregateRecord {
  private final Map<String, Object> keyToAggregateResult = new Map<String, Object>();

  public AggregateRecord putAll(Map<String, Object> values) {
    this.keyToAggregateResult.putAll(values);
    return this;
  }

  public Object get(String key) {
    return this.keyToAggregateResult.get(key);
  }
}
