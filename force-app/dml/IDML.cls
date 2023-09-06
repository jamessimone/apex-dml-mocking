public interface IDML {
  Database.SaveResult doInsert(SObject record);
  List<Database.SaveResult> doInsert(List<SObject> recordList);
  Database.SaveResult doUpdate(SObject record);
  List<Database.SaveResult> doUpdate(List<SObject> recordList);
  Database.UpsertResult doUpsert(SObject record);
  List<Database.UpsertResult> doUpsert(List<SObject> recordList);
  List<Database.UpsertResult> doUpsert(List<SObject> recordList, Schema.SObjectField externalIDField);
  Database.UndeleteResult doUndelete(SObject record);
  List<Database.UndeleteResult> doUndelete(List<SObject> recordList);

  Database.DeleteResult doDelete(SObject record);
  List<Database.DeleteResult> doDelete(List<SObject> recordList);
  Database.DeleteResult doHardDelete(SObject record);
  List<Database.DeleteResult> doHardDelete(List<SObject> recordList);

  Database.SaveResult publish(SObject platformEvent);
  List<Database.SaveResult> publish(List<SObject> platformEvent);

  IDML setOptions(Database.DMLOptions options, System.AccessLevel accessLevel);
}
