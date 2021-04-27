public class Query {
  private enum Operator {
    EQUALS,
    NOT_EQUALS,
    LESS_THAN,
    LESS_THAN_OR_EQUAL,
    GREATER_THAN,
    GREATER_THAN_OR_EQUAL
  }

  private final SObjectField field;
  private final Operator operator;
  private final List<Object> predicates;

  private static Boolean isIterable = false;
  private static final String EMPTY = '\'\'';

  public static Query equals(SObjectField field, Object predicate) {
    return equals(field, new List<Object>{ predicate });
  }

  public static Query equals(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.EQUALS, predicates);
  }

  public static Query notEquals(SObjectField field, Object predicate) {
    return notEquals(field, new List<Object>{ predicate });
  }

  public static Query notEquals(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.NOT_EQUALS, predicates);
  }

  public static Query lessThan(SObjectField field, Object predicate) {
    return lessThan(field, new List<Object>{ predicate });
  }

  public static Query lessThan(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.LESS_THAN, predicates);
  }

  public static Query lessThanOrEqual(SObjectField field, Object predicate) {
    return lessThanOrEqual(field, new List<Object>{ predicate });
  }

  public static Query lessThanOrEqual(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.LESS_THAN_OR_EQUAL, predicates);
  }

  public static Query greaterThan(SObjectField field, Object predicate) {
    return greaterThan(field, new List<Object>{ predicate });
  }

  public static Query greaterThan(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.GREATER_THAN, predicates);
  }

  public static Query greaterThanOrEqual(SObjectField field, Object predicate) {
    return greaterThanOrEqual(field, new List<Object>{ predicate });
  }

  public static Query greaterThanOrEqual(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.GREATER_THAN_OR_EQUAL, predicates);
  }

  private Query(SObjectField field, Operator operator, List<Object> predicates) {
    this.field = field;
    this.operator = operator;
    this.predicates = predicates;
  }

  public override String toString() {
    String fieldName = this.field.getDescribe().getName();
    String predName = this.getPredicate(this.predicates);
    return fieldName + ' ' + this.getOperator() + ' ' + predName;
  }

  public Boolean isEmpty() {
    return this.getPredicate(this.predicates) == EMPTY;
  }

  public Boolean equals(Object thatObject) {
    if (thatObject instanceof Query) {
      Query that = (Query) thatObject;
      return this.toString() == that.toString();
    }

    return false;
  }

  private String getOperator() {
    isIterable = isIterable || this.predicates.size() > 1;
    String returnVal = '';
    switch on this.operator {
      when EQUALS {
        returnVal = isIterable ? 'in' : '=';
      }
      when NOT_EQUALS {
        returnVal = isIterable ? 'not in' : '!=';
      }
      when LESS_THAN {
        returnVal = '<';
      }
      when LESS_THAN_OR_EQUAL {
        returnVal = '<=';
      }
      when GREATER_THAN {
        returnVal = '>';
      }
      when GREATER_THAN_OR_EQUAL {
        returnVal = '>=';
      }
    }
    return returnVal;
  }

  private String getPredicate(Object predicate) {
    if (predicate == null) {
      return 'null';
    } else if (predicate instanceof Datetime) {
      //the most annoying one
      Datetime dt = (Datetime) predicate;
      return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    } else if (predicate instanceof List<Object>) {
      List<Object> predicates = (List<Object>) predicate;
      if (predicates.isEmpty()) {
        return EMPTY;
      }
      List<String> innerStrings = new List<String>();
      for (Object innerPred : predicates) {
        //recurse for string value
        String innerString = this.getPredicate(innerPred);
        innerStrings.add(innerString);
      }
      String start = innerStrings.size() > 1 ? '(' : '';
      String ending = innerStrings.size() > 1 ? ')' : '';
      return start + String.join(innerStrings, ',') + ending;
    } else if (predicate instanceof String) {
      String input = (String) predicate;
      return '\'' + String.escapeSingleQuotes(input) + '\'';
    }

    // it could still be a Set, which is notoriously hard to detect for due to instanceof Iterable<String> not working for Sets, despite
    // them implementing the interface ...
    try {
      Iterable<Object> objectSet = (Iterable<Object>) predicate;
      List<String> innerList = new List<String>();
      Iterator<Object> objectSetIterator = objectSet.iterator();
      while (objectSetIterator.hasNext()) {
        innerList.add(String.valueOf(objectSetIterator.next()));
      }
      isIterable = innerList.size() > 1;

      return this.getPredicate(innerList);
    } catch (Exception ex) {
      // do nothing, it didn't work
    }
    return String.valueOf(predicate);
  }
}
