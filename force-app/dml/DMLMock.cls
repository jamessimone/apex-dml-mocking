public virtual class DMLMock extends DML {
  public static List<SObject> InsertedRecords = new List<SObject>();
  public static List<SObject> UpsertedRecords = new List<SObject>();
  public static List<SObject> UpdatedRecords = new List<SObject>();
  public static List<SObject> DeletedRecords = new List<SObject>();
  public static List<SObject> UndeletedRecords = new List<SObject>();

  public override List<Database.SaveResult> doInsert(List<SObject> records) {
    TestingUtils.generateIds(records);
    InsertedRecords.addAll(records);
    return (List<Database.SaveResult>) createDatabaseResults(Database.SaveResult.class, records);
  }

  public override List<Database.SaveResult> doUpdate(List<SObject> records) {
    UpdatedRecords.addAll(records);
    return (List<Database.SaveResult>) createDatabaseResults(Database.SaveResult.class, records);
  }

  public override List<Database.UpsertResult> doUpsert(List<SObject> records) {
    TestingUtils.generateIds(records);
    UpsertedRecords.addAll(records);
    return (List<Database.UpsertResult>) createDatabaseResults(Database.UpsertResult.class, records);
  }
  public override List<Database.UpsertResult> doUpsert(List<SObject> records, Schema.SObjectField field) {
    return this.doUpsert(records);
  }

  public override List<Database.UndeleteResult> doUndelete(List<SObject> records) {
    UndeletedRecords.addAll(records);
    return (List<Database.UndeleteResult>) createDatabaseResults(Database.UndeleteResult.class, records);
  }

  public override List<Database.DeleteResult> doDelete(List<SObject> records) {
    if (records?.isEmpty() == false) {
      DeletedRecords.addAll(records);
    }
    return (List<Database.DeleteResult>) createDatabaseResults(Database.DeleteResult.class, records);
  }

  public override List<Database.DeleteResult> doHardDelete(List<SObject> records) {
    return this.doDelete(records);
  }

  public static RecordsWrapper Inserted {
    get {
      return new RecordsWrapper(InsertedRecords);
    }
  }

  public static RecordsWrapper Upserted {
    get {
      return new RecordsWrapper(UpsertedRecords);
    }
  }

  public static RecordsWrapper Updated {
    get {
      return new RecordsWrapper(UpdatedRecords);
    }
  }

  public static RecordsWrapper Deleted {
    get {
      return new RecordsWrapper(DeletedRecords);
    }
  }

  public static RecordsWrapper Undeleted {
    get {
      return new RecordsWrapper(UndeletedRecords);
    }
  }

  public class RecordsWrapper {
    List<SObject> recordList;
    private RecordsWrapper(List<SObject> recordList) {
      this.recordList = recordList;
    }

    public RecordsWrapper ofType(Schema.SObjectType sObjectType) {
      return new RecordsWrapper(this.getRecordsMatchingType(recordList, sObjectType));
    }

    public RecordsWrapper Accounts {
      get {
        return this.ofType(Schema.Account.SObjectType);
      }
    }

    public RecordsWrapper Leads {
      get {
        return this.ofType(Schema.Lead.SObjectType);
      }
    }

    public RecordsWrapper Contacts {
      get {
        return this.ofType(Schema.Contact.SObjectType);
      }
    }

    public RecordsWrapper Opportunities {
      get {
        return this.ofType(Schema.Opportunity.SObjectType);
      }
    }

    public RecordsWrapper Tasks {
      get {
        return this.ofType(Schema.Task.SObjectType);
      }
    }

    public List<SObject> Records {
      get {
        return recordList;
      }
    }

    public Boolean hasId(Id recordId) {
      return this.hasId(recordId, 'Id');
    }

    public Boolean hasId(Id relatedId, Schema.SObjectField idField) {
      return this.hasId(relatedId, idField.getDescribe().getName());
    }

    private Boolean hasId(Id relatedId, String idFieldName) {
      for (SObject record : this.recordList) {
        if (record.get(idFieldName) == relatedId) {
          return true;
        }
      }
      return false;
    }

    public Integer size() {
      return this.recordList.size();
    }

    public SObject singleOrDefault {
      get {
        if (recordList.size() > 1) {
          throw new IllegalArgumentException('More than one value in records list');
        }
        return recordList.size() == 0 ? null : recordList[0];
      }
    }

    public SObject firstOrDefault {
      get {
        if (recordList.size() > 0) {
          return recordList[0];
        }
        return null;
      }
    }

    private List<SObject> getRecordsMatchingType(List<SObject> records, Schema.SObjectType sObjectType) {
      List<SObject> matchingRecords = new List<SObject>();
      for (SObject record : records) {
        if (record.getSObjectType() == sObjectType) {
          matchingRecords.add(record);
        }
      }
      return matchingRecords;
    }
  }

  private static List<Object> createDatabaseResults(Type clazz, List<SObject> records) {
    List<Object> results = (List<Object>) Type.forName('List<' + clazz.getName() + '>').newInstance();
    for (SObject record : records) {
      results.add(createDatabaseResult(clazz, record));
    }
    return results;
  }

  private static Object createDatabaseResult(Type clazz, SObject record) {
    return JSON.deserialize('{"success": true, "id": "' + record.Id + '"}', clazz);
  }
}
