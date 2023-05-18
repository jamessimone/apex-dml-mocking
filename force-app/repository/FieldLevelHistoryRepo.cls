public virtual without sharing class FieldLevelHistoryRepo extends AggregateRepository implements IHistoryRepository {
  private Schema.SObjectField parentFieldToken;
  private final Set<String> fullHistoryFields;

  private Boolean isHistoryQuery = false;

  public FieldLevelHistoryRepo(
    Schema.SObjectType repoType,
    List<Schema.SObjectField> queryFields,
    RepoFactory repoFactory
  ) {
    super(repoType, queryFields, repoFactory);
    this.fullHistoryFields = this.repoType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet();
  }

  public virtual List<FieldLevelHistory> getAllHistory() {
    return this.getHistory(new List<Query>());
  }

  public List<FieldLevelHistory> getHistory(Query query) {
    return this.getHistory(new List<Query>{ query });
  }

  public virtual List<FieldLevelHistory> getHistory(List<Query> queries) {
    this.isHistoryQuery = true;
    List<Object> unwrappedHistoryRecords = this.get(queries);
    this.isHistoryQuery = false;
    if (unwrappedHistoryRecords instanceof List<FieldLevelHistory>) {
      return (List<FieldLevelHistory>) unwrappedHistoryRecords;
    }

    List<FieldLevelHistory> historyRecords = new List<FieldLevelHistory>();
    for (Object obj : unwrappedHistoryRecords) {
      FieldLevelHistory historyRecord = new FieldLevelHistory()
        .setParentLookup(this.parentFieldToken)
        .setValues((Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj)));
      historyRecords.add(historyRecord);
    }
    return historyRecords;
  }

  public FieldLevelHistoryRepo setParentField(Schema.SObjectField parentField) {
    this.parentFieldToken = parentField;
    return this;
  }

  protected virtual override Set<String> addSelectFields() {
    return this.isHistoryQuery ? this.fullHistoryFields : super.addSelectFields();
  }
}
