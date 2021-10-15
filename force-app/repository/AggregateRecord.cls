public class AggregateRecord {
  private final Map<String, Object> keyToAggregateResult = new Map<String, Object>();

  public void putAll(Map<String, Object> values) {
    this.keyToAggregateResult.putAll(values);
  }

  public Object get(String key) {
    return this.keyToAggregateResult.get(key);
  }
}
