public virtual class Query {
  private enum Operator {
    EQUALS,
    NOT_EQUALS,
    LESS_THAN,
    LESS_THAN_OR_EQUAL,
    GREATER_THAN,
    GREATER_THAN_OR_EQUAL,
    ALIKE, // like is a reserved word
    NOT_LIKE
  }

  private final String field;
  private final Schema.SObjectField fieldToken;
  private final Operator operator;
  private final List<Object> predicates;

  private Boolean isIterable = false;

  private static final String EMPTY = '\'\'';

  public Query usingParent(Schema.SObjectField parentField) {
    return this.usingParent(new List<Schema.SObjectField>{ parentField });
  }

  public Query usingParent(List<SObjectField> parentFields) {
    parentFields.add(this.fieldToken);
    return new ParentQuery(parentFields, this.operator, this.predicates);
  }

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

  // like is a reserved keyword
  public static Query likeQuery(SObjectField field, Object predicate) {
    return likeQuery(field, new List<Object>{ predicate });
  }

  public static Query likeQuery(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.ALIKE, predicates);
  }

  public static Query notLike(SObjectField field, Object predicate) {
    return notLike(field, new List<Object>{ predicate });
  }

  public static Query notLike(SObjectField field, List<Object> predicates) {
    return new Query(field, Operator.NOT_LIKE, predicates);
  }

  // or is a reserved keyword
  public static Query orQuery(Query innerQuery, Query secondInnerQuery) {
    return orQuery(new List<Query>{ innerQuery, secondInnerQuery });
  }

  public static Query orQuery(List<Query> innerQueries) {
    return new OrQuery(innerQueries);
  }

  private class OrQuery extends Query {
    private final List<Query> queries;
    private final String orDelimiter = ' OR ';

    public OrQuery(List<Query> queries) {
      super();
      this.queries = queries;
    }

    public override String toString() {
      String baseString = '(';
      for (Query innerQuery : this.queries) {
        baseString += innerQuery.toString() + this.orDelimiter;
      }
      return baseString.removeEnd(this.orDelimiter) + ')';
    }
  }

  private class ParentQuery extends Query {
    private ParentQuery(List<SObjectField> parentFields, Operator operator, List<Object> predicates) {
      super(getBuiltUpParentFieldName(parentFields), operator, predicates);
    }
  }

  protected Query() {
  }

  private Query(String fieldName, Operator operator, List<Object> predicates) {
    this.field = fieldName;
    this.operator = operator;
    this.predicates = predicates;
  }

  private Query(SObjectField fieldToken, Operator operator, List<Object> predicates) {
    this(fieldToken.getDescribe().getName(), operator, predicates);
    this.fieldToken = fieldToken;
  }

  public List<Object> getBindVars() {
    return this.predicates;
  }

  public virtual override String toString() {
    String predicateValue = this.getPredicate(this.predicates);
    this.isIterable = this.isIterable || this.predicates.size() > 1;
    if (this.operator == Query.Operator.NOT_LIKE) {
      String endingString = ' ' + (this.isIterable ? ':bindVar' : predicateValue);
      // who knows why this is the format they wanted
      return String.format(this.getOperator(), new List<String>{ this.field }) + endingString;
    }
    return this.field + ' ' + this.getOperator() + ' ' + predicateValue;
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
      when ALIKE {
        returnVal = 'like';
      }
      when NOT_LIKE {
        returnVal = 'not {0} like';
      }
    }
    return returnVal;
  }

  private String getPredicate(Object predicate) {
    if (predicate == null) {
      return 'null';
    } else if (predicate instanceof Datetime) {
      // the most annoying one
      Datetime dt = (Datetime) predicate;
      return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    } else if (predicate instanceof List<Object>) {
      List<Object> localPredicates = (List<Object>) predicate;
      if (localPredicates.isEmpty()) {
        return EMPTY;
      }
      List<String> innerStrings = new List<String>();
      for (Object innerPred : localPredicates) {
        // recurse for string value
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

    // it could still be a Set, which is notoriously hard to detect for
    // due to instanceof Iterable<String> returning false for Sets, despite
    // Set.class implementing the interface ...
    try {
      Iterable<Object> objectSet = (Iterable<Object>) predicate;
      List<String> innerList = new List<String>();
      Iterator<Object> objectSetIterator = objectSet.iterator();
      while (objectSetIterator.hasNext()) {
        innerList.add(String.valueOf(objectSetIterator.next()));
      }
      this.isIterable = innerList.size() > 1;

      return this.getPredicate(innerList);
    } catch (Exception ex) {
      // do nothing, it didn't work
    }
    return String.valueOf(predicate);
  }

  private static String getBuiltUpParentFieldName(List<SObjectField> parentFields) {
    String builtUpFieldName = '';
    for (Integer index = 0; index < parentFields.size(); index++) {
      Schema.DescribeFieldResult parentFieldDescribe = parentFields[index].getDescribe();
      builtUpFieldName += index == parentFields.size() - 1
        ? parentFieldDescribe.getName()
        : parentFieldDescribe.getRelationshipName() + '.';
    }
    return builtUpFieldName;
  }
}
