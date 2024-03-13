public virtual class Query {
  public enum Operator {
    EQUALS,
    NOT_EQUALS,
    LESS_THAN,
    LESS_THAN_OR_EQUAL,
    GREATER_THAN,
    GREATER_THAN_OR_EQUAL,
    ALIKE, // like is a reserved word
    NOT_LIKE
  }

  public final Operator operator;
  private final String field;
  private final Schema.SObjectField fieldToken;
  private final Object predicate;

  private final Map<String, Object> bindVars = new Map<String, Object>();

  private static final String BIND_VAR_MERGE = 'bindVar{0}';
  private static Integer BIND_VAR_NUMBER = 0;

  public Query usingParent(Schema.SObjectField parentField) {
    return this.usingParent(new List<Schema.SObjectField>{ parentField });
  }

  public Query usingParent(List<SObjectField> parentFields) {
    parentFields.add(this.fieldToken);
    return new ParentQuery(parentFields, this);
  }

  public static Query subquery(Schema.SObjectField field, Schema.SObjectField innerMatchingField, Query subcondition) {
    return subquery(field, innerMatchingField.getDescribe().getSObjectType(), innerMatchingField, subcondition);
  }

  public static Query subquery(
    Schema.SObjectField field,
    Schema.SObjectType objectType,
    Schema.SObjectField innerMatchingField,
    Query subcondition
  ) {
    return new SubQuery(field, objectType, innerMatchingField, subcondition);
  }

  public static Query equals(SObjectField field, Object predicate) {
    return new Query(field, Operator.EQUALS, predicate);
  }

  public static Query notEquals(SObjectField field, Object predicate) {
    return new Query(field, Operator.NOT_EQUALS, predicate);
  }

  public static Query lessThan(SObjectField field, Object predicate) {
    return new Query(field, Operator.LESS_THAN, predicate);
  }

  public static Query lessThanOrEqual(SObjectField field, Object predicate) {
    return new Query(field, Operator.LESS_THAN_OR_EQUAL, predicate);
  }

  public static Query greaterThan(SObjectField field, Object predicate) {
    return new Query(field, Operator.GREATER_THAN, predicate);
  }

  public static Query greaterThanOrEqual(SObjectField field, Object predicate) {
    return new Query(field, Operator.GREATER_THAN_OR_EQUAL, predicate);
  }

  // like is a reserved keyword
  public static Query likeQuery(SObjectField field, Object predicate) {
    return new Query(field, Operator.ALIKE, predicate);
  }

  public static Query notLike(SObjectField field, Object predicate) {
    return new Query(field, Operator.NOT_LIKE, predicate);
  }

  // or is a reserved keyword
  public static Query orQuery(Query innerQuery, Query secondInnerQuery) {
    return orQuery(new List<Query>{ innerQuery, secondInnerQuery });
  }

  public static Query orQuery(List<Query> innerQueries) {
    return new OrQuery(innerQueries);
  }

  // and is a reserved keyword
  public static Query andQuery(Query innerQuery, Query secondInnerQuery) {
    return andQuery(new List<Query>{ innerQuery, secondInnerQuery });
  }

  public static Query andQuery(List<Query> innerQueries) {
    return new AndQuery(innerQueries);
  }

  private class SubQuery extends Query {
    private final Schema.SObjectField field;
    private final Schema.SObjectType objectType;
    private final Schema.SObjectField innerMatchingField;
    private final Query subcondition;

    public SubQuery(
      Schema.SObjectField field,
      Schema.SObjectType objectType,
      Schema.SObjectField innerMatchingField,
      Query subcondition
    ) {
      this.field = field;
      this.objectType = objectType;
      this.innerMatchingField = innerMatchingField;
      this.subcondition = subcondition;
    }

    public override String toString() {
      String whereClause = ' WHERE ' + this.subcondition.toString();
      this.bindVars.putAll(this.subcondition.getBindVars());
      return this.field.getDescribe().getName() +
        ' IN (SELECT ' +
        this.innerMatchingField +
        ' FROM ' +
        this.objectType +
        whereClause +
        ')';
    }
  }

  private abstract class DelimitedQuery extends Query {
    private final List<Query> queries;

    public DelimitedQuery(List<Query> queries) {
      super();
      this.queries = queries;
    }

    public abstract String getDelimiter();

    public override String toString() {
      String baseString = '(';
      for (Query innerQuery : this.queries) {
        baseString += innerQuery.toString() + this.getDelimiter();
        this.bindVars.putAll(innerQuery.getBindVars());
      }
      return baseString.removeEnd(this.getDelimiter()) + ')';
    }
  }

  private class AndQuery extends DelimitedQuery {
    private final String delimiter = ' AND ';

    public AndQuery(List<Query> queries) {
      super(queries);
    }

    public override String getDelimiter() {
      return this.delimiter;
    }
  }

  private class OrQuery extends DelimitedQuery {
    private final String delimiter = ' OR ';

    public OrQuery(List<Query> queries) {
      super(queries);
    }

    public override String getDelimiter() {
      return this.delimiter;
    }
  }

  private class ParentQuery extends Query {
    private ParentQuery(List<SObjectField> parentFields, Query innerQuery) {
      super(innerQuery);
      this.field = getBuiltUpParentFieldName(parentFields);
    }
  }

  protected Query() {
  }

  protected Query(Query innerQuery) {
    this.operator = innerQuery.operator;
    this.predicate = innerQuery.predicate;
    this.bindVars.putAll(innerQuery.getBindVars());
  }

  protected Query(String fieldName, Operator operator, Object predicate) {
    this.field = fieldName;
    this.operator = operator;
    this.predicate = this.getPredicate(predicate);
  }

  private Query(SObjectField fieldToken, Operator operator, Object predicate) {
    this(fieldToken.getDescribe().getName(), operator, predicate);
    this.fieldToken = fieldToken;
  }

  public Map<String, Object> getBindVars() {
    return this.bindVars;
  }

  public virtual override String toString() {
    if (this.operator == Query.Operator.NOT_LIKE) {
      // who knows why this is the format they wanted
      return String.format(this.getOperator(), new List<String>{ this.field, this.predicate.toString() });
    }
    return this.field + ' ' + this.getOperator() + ' ' + this.predicate;
  }

  public Boolean equals(Object thatObject) {
    if (thatObject instanceof Query) {
      Query that = (Query) thatObject;
      return this.field == that.field &&
        this.operator == that.operator &&
        this.bindVars.values() == that.bindVars.values();
    }

    return false;
  }

  private String getOperator() {
    String returnVal = '';
    switch on this.operator {
      when EQUALS {
        returnVal = '=';
      }
      when NOT_EQUALS {
        returnVal = '!=';
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
        returnVal = '(not {0} like {1})';
      }
    }
    return returnVal;
  }

  private String getPredicate(Object predicate) {
    if (predicate == null || predicate instanceof Boolean) {
      return '' + predicate;
    }
    String predicateKey = String.format(BIND_VAR_MERGE, new List<String>{ BIND_VAR_NUMBER.format() });
    BIND_VAR_NUMBER++;
    this.bindVars.put(predicateKey, predicate);
    return ':' + predicateKey;
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
