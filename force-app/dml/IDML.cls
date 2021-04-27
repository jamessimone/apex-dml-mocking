public interface IDML {
  SObject doInsert(SObject record);
  List<SObject> doInsert(List<SObject> recordList);
  SObject doUpdate(SObject record);
  List<SObject> doUpdate(List<SObject> recordList);
  SObject doUpsert(SObject record);
  List<SObject> doUpsert(List<SObject> recordList);
  List<SObject> doUpsert(List<SObject> recordList, Schema.SObjectField externalIDField);
  SObject doUndelete(SObject record);
  List<SObject> doUndelete(List<SObject> recordList);

  void doDelete(SObject record);
  void doDelete(List<SObject> recordList);
  void doHardDelete(SObject record);
  void doHardDelete(List<SObject> recordList);
}
