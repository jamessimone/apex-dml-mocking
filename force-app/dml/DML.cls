public virtual without sharing class DML implements IDML {
  /**
   * To use this class properly, see the Factory class:
   * DML should be injected as a dependency by the factory
   * then in your tests, the Factory.withMocks method
   * becomes your one-stop-shop signal for switching to the DMLMock in tests
   */
  @TestVisible
  private static final Integer MAX_DML_CHUNKING = 10;

  private System.AccessLevel accessLevel = System.AccessLevel.SYSTEM_MODE;

  private Database.DMLOptions options {
    get {
      if (this.options == null) {
        this.options = new Database.DMLOptions();
      }
      this.options.OptAllOrNone = this.options.OptAllOrNone ?? true;
      return this.options;
    }
    set;
  }

  private enum OperationLoggingValue {
    INSERTING,
    UPDATING,
    UPSERTING,
    DELETING,
    UNDELETING,
    PUBLISHING
  }

  public virtual Database.SaveResult doInsert(SObject record) {
    return this.doInsert(new List<SObject>{ record })[0];
  }
  public virtual List<Database.SaveResult> doInsert(List<SObject> records) {
    this.sortToPreventChunkingErrors(records);
    log(OperationLoggingValue.INSERTING, records);
    return Database.insert(records, this.options, this.accessLevel);
  }

  public virtual Database.SaveResult doUpdate(SObject record) {
    return this.doUpdate(new List<SObject>{ record })[0];
  }
  public virtual List<Database.SaveResult> doUpdate(List<SObject> records) {
    this.sortToPreventChunkingErrors(records);
    log(OperationLoggingValue.UPDATING, records);
    return Database.update(records, this.options, this.accessLevel);
  }

  public virtual Database.UpsertResult doUpsert(SObject record) {
    return this.doUpsert(new List<SObject>{ record })[0];
  }

  public virtual List<Database.UpsertResult> doUpsert(List<SObject> records) {
    this.sortToPreventChunkingErrors(records);
    log(OperationLoggingValue.UPSERTING, records);
    return Database.upsert(records, this.options.OptAllOrNone, this.accessLevel);
  }

  public virtual List<Database.UpsertResult> doUpsert(List<SObject> records, Schema.SObjectField externalIdField) {
    this.sortToPreventChunkingErrors(records);
    log(OperationLoggingValue.UPSERTING, records);
    return Database.upsert(records, externalIdField, this.options.OptAllOrNone, this.accessLevel);
  }

  public virtual Database.UndeleteResult doUndelete(SObject record) {
    return this.doUndelete(new List<SObject>{ record })[0];
  }
  public virtual List<Database.UndeleteResult> doUndelete(List<SObject> records) {
    log(OperationLoggingValue.UNDELETING, records);
    return Database.undelete(records, this.options.OptAllOrNone, this.accessLevel);
  }

  public virtual Database.DeleteResult doDelete(SObject record) {
    return this.doDelete(new List<SObject>{ record })[0];
  }
  public virtual List<Database.DeleteResult> doDelete(List<SObject> records) {
    log(OperationLoggingValue.DELETING, records);
    return Database.delete(records, this.options.OptAllOrNone, this.accessLevel);
  }

  public virtual Database.DeleteResult doHardDelete(SObject record) {
    return this.doHardDelete(new List<SObject>{ record })[0];
  }
  public virtual List<Database.DeleteResult> doHardDelete(List<SObject> records) {
    List<Database.DeleteResult> results = this.doDelete(records);
    System.debug(System.LoggingLevel.DEBUG, 'emptying recycling bin...');
    Database.emptyRecycleBin(records);
    return results;
  }

  public virtual Database.SaveResult publish(SObject event) {
    log(OperationLoggingValue.PUBLISHING, event);
    return EventBus.publish(event);
  }
  public virtual List<Database.SaveResult> publish(List<SObject> events) {
    log(OperationLoggingValue.PUBLISHING, events);
    return EventBus.publish(events);
  }

  public DML setOptions(Database.DMLOptions options) {
    return this.setOptions(options, this.accessLevel);
  }

  public DML setOptions(Database.DMLOptions options, System.AccessLevel accessLevel) {
    this.options = options ?? this.options;
    this.accessLevel = accessLevel;
    return this;
  }

  private void sortToPreventChunkingErrors(List<SObject> records) {
    // prevents a chunking error that can occur if SObject types are in the list out of order.
    // no need to sort if the list size is below the limit
    if (records.size() >= MAX_DML_CHUNKING) {
      records.sort();
    }
  }

  private static void log(OperationLoggingValue loggingValue, Object recordOrRecords) {
    Integer size = (recordOrRecords instanceof List<SObject>) ? ((List<SObject>) recordOrRecords).size() : 1;
    System.debug(
      System.LoggingLevel.DEBUG,
      loggingValue.name().toLowerCase() + ' ' + size + ' record' + (size > 1 ? 's' : '') + '...'
    );
  }
}
