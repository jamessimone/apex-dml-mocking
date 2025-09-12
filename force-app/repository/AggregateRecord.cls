public class AggregateRecord {
  private final Map<String, Object> keyToAggregateResult = new Map<String, Object>();
  private static final String COUNT_KEY = 'countKey';

  public AggregateRecord putAll(Map<String, Object> values) {
    this.keyToAggregateResult.putAll(values);
    return this;
  }

  public Object get(String key) {
    return this.keyToAggregateResult.get(key);
  }

  public Integer getCount() {
    return (Integer) this.keyToAggregateResult.get(COUNT_KEY);
  }

  public AggregateRecord setCount(Integer countAmount) {
    this.keyToAggregateResult.put(COUNT_KEY, countAmount);
    return this;
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

  public Integer hashCode() {
    return this.keyToAggregateResult.hashCode();
  }
}
