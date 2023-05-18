public class Aggregation {
  private enum Operation {
    COUNT,
    COUNT_DISTINCT,
    SUM,
    AVERAGE,
    MAX,
    MIN
  }

  private final Operation op;
  private final String fieldName;
  private final String alias;

  private Aggregation(Operation op, Schema.SObjectField fieldToken, String alias) {
    this.op = op;
    this.fieldName = fieldToken.getDescribe().getName();
    this.alias = alias;
  }

  public static Aggregation sum(Schema.SObjectField fieldToken, String alias) {
    return new Aggregation(Operation.SUM, fieldToken, alias);
  }

  public static Aggregation count(Schema.SObjectField fieldToken, String alias) {
    return new Aggregation(Operation.COUNT, fieldToken, alias);
  }

  public static Aggregation countDistinct(Schema.SObjectfield fieldToken, String alias) {
    return new Aggregation(Operation.COUNT_DISTINCT, fieldToken, alias);
  }

  public static Aggregation average(Schema.SObjectfield fieldToken, String alias) {
    return new Aggregation(Operation.AVERAGE, fieldToken, alias);
  }

  public static Aggregation max(Schema.SObjectfield fieldToken, String alias) {
    return new Aggregation(Operation.MAX, fieldToken, alias);
  }

  public static Aggregation min(Schema.SObjectfield fieldToken, String alias) {
    return new Aggregation(Operation.MIN, fieldToken, alias);
  }

  public String getAlias() {
    return this.alias;
  }

  public String getFieldName() {
    return this.fieldName;
  }

  public String getBaseAggregation() {
    return this.op.name() + '(' + fieldName + ')';
  }

  public override String toString() {
    return this.getBaseAggregation() + ' ' + this.alias;
  }

  public Boolean equals(Object that) {
    return this.toString() == that.toString();
  }
}
