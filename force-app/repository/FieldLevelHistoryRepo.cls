public virtual without sharing class FieldLevelHistoryRepo extends AggregateRepository implements IHistoryRepository {
  private final Type fieldLevelHistoryType;
  private final String parentFieldName;

  public FieldLevelHistoryRepo(
    Schema.SObjectField parentField,
    Schema.SObjectType repoType,
    Type fieldLevelHistoryType,
    RepoFactory repoFactory
  ) {
    super(repoType, new List<Schema.SObjectField>(), repoFactory);
    this.fieldLevelHistoryType = fieldLevelHistoryType;
    this.parentFieldName = parentField.getDescribe().getName();
  }

  public FieldLevelHistoryRepo(Schema.SObjectField parentField, Schema.SObjectType repoType, RepoFactory repoFactory) {
    this(parentField, repoType, FieldLevelHistory.class, repoFactory);
  }

  public FieldLevelHistoryRepo(
    Schema.SObjectType repoType,
    List<Schema.SObjectField> queryFields,
    RepoFactory repoFactory
  ) {
    super(repoType, queryFields, repoFactory);
  }

  protected FieldLevelHistoryRepo(RepoFactory repoFactory) {
    super(repoFactory);
  }

  protected virtual override Set<String> addSelectFields() {
    Set<String> baseFields = super.addSelectFields();
    return (baseFields.isEmpty() || baseFields.size() == 1 && baseFields.contains('Id')) &&
      this.repoType.getDescribe().getName().contains('History')
      ? new Set<String>{ 'CreatedById', 'CreatedDate', 'Field', 'Id', 'NewValue', 'OldValue', this.parentFieldName }
      : baseFields;
  }

  public List<FieldLevelHistory> getHistory(Query query) {
    return this.getHistory(new List<Query>{ query });
  }

  public virtual List<FieldLevelHistory> getHistory(List<Query> queries) {
    List<Object> unwrappedHistoryRecords = this.get(queries);
    if (unwrappedHistoryRecords instanceof List<FieldLevelHistory>) {
      return (List<FieldLevelHistory>) unwrappedHistoryRecords;
    }

    List<FieldLevelHistory> historyRecords = new List<FieldLevelHistory>();
    for (Object obj : unwrappedHistoryRecords) {
      FieldLevelHistory historyRecord = (FieldLevelHistory) this.fieldLevelHistoryType.newInstance();
      historyRecord.setValues((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj)));
      historyRecords.add(historyRecord);
    }
    return historyRecords;
  }

  public virtual List<FieldLevelHistory> getAllHistory() {
    return this.getHistory(new List<Query>());
  }
}
