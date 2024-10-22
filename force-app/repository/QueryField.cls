public without sharing virtual class QueryField {
  private final String fieldValue;

  public QueryField(List<Schema.SObjectField> fieldTokens) {
    this(getFieldNames(fieldTokens));
  }

  public QueryField(List<String> fieldNames) {
    this.fieldValue = String.join(fieldNames, ',');
  }

  public QueryField(Schema.SObjectField token) {
    this.fieldValue = token.toString();
  }

  public QueryField(List<Schema.SObjectField> parentFieldChain, List<Schema.SObjectField> parentFields) {
    String base = '';
    while (parentFieldChain.isEmpty() == false) {
      base += parentFieldChain.remove(0).getDescribe().getRelationshipName() + '.';
    }
    List<String> fields = new List<String>();
    for (Schema.SObjectField field : parentFields) {
      fields.add(base + field.toString());
    }
    this.fieldValue = String.join(fields, ',');
  }

  public override String toString() {
    return this.fieldValue;
  }

  private static List<String> getFieldNames(List<Schema.SObjectField> fieldTokens) {
    List<String> fieldNames = new List<String>();
    for (Schema.SObjectField token : fieldTokens) {
      fieldNames.add(token.toString());
    }
    return fieldNames;
  }
}
