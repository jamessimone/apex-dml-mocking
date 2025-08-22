public class AdditionalSoslObject {
  public final Schema.SObjectType objectType;
  public final Integer queryLimit;
  public final List<Query> queryFilters;
  public final List<Schema.SObjectField> selectFields;

  public AdditionalSoslObject(
    Schema.SObjectType objectType,
    List<Schema.SObjectField> selectFields,
    List<Query> queryFilters,
    Integer queryLimit
  ) {
    this.objectType = objectType;
    this.queryFilters = queryFilters;
    this.queryLimit = queryLimit;
    this.selectFields = selectFields;
  }
}
