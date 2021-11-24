public virtual class DMLMock extends DML {
  public static List<SObject> InsertedRecords = new List<SObject>();
  public static List<SObject> UpsertedRecords = new List<SObject>();
  public static List<SObject> UpdatedRecords = new List<SObject>();
  public static List<SObject> DeletedRecords = new List<SObject>();
  public static List<SObject> UndeletedRecords = new List<SObject>();

  @TestVisible
  private DMLMock() {
    // @IsTest classes cannot be virtual, so enforce visibility
  }

  public override List<SObject> doInsert(List<SObject> recordList) {
    TestingUtils.generateIds(recordList);
    InsertedRecords.addAll(recordList);
    return recordList;
  }

  public override List<SObject> doUpdate(List<SObject> recordList) {
    UpdatedRecords.addAll(recordList);
    return recordList;
  }

  public override List<SObject> doUpsert(List<SObject> recordList) {
    TestingUtils.generateIds(recordList);
    UpsertedRecords.addAll(recordList);
    return recordList;
  }
  public override List<SObject> doUpsert(List<SObject> recordList, Schema.SObjectField field) {
    return this.doUpsert(recordList);
  }

  public override List<SObject> doUndelete(List<SObject> recordList) {
    UndeletedRecords.addAll(recordList);
    return recordList;
  }

  public override void doDelete(List<SObject> recordList) {
    if (recordList?.isEmpty() == false) {
      DeletedRecords.addAll(recordList);
    }
  }

  public override void doHardDelete(List<SObject> recordList) {
    this.doDelete(recordList);
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
    RecordsWrapper(List<SObject> recordList) {
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
      Boolean exists = false;
      for (SObject record : this.recordList) {
        if (record.Id == recordId) {
          exists = true;
        }
      }
      return exists;
    }

    public Boolean hasId(Id whatId, SObjectField idField) {
      Boolean exists = false;
      for (SObject record : this.recordList) {
        if (record.get(idField) == whatId) {
          exists = true;
        }
      }
      return exists;
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
}
