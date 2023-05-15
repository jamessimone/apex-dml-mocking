public virtual class DML implements IDML {
  /**
   * To use this class properly, see the Factory class:
   * DML should be injected as a dependency by the factory
   * then in your tests, the Factory.withMocks method
   * becomes your one-stop-shop signal for switching to the DMLMock in tests
   */
  @TestVisible
  private static Integer MAX_DML_CHUNKING = 10;

  private System.AccessLevel accessLevel = System.AccessLevel.SYSTEM_MODE;

  private Database.DMLOptions options {
    get {
      if (this.options == null) {
        this.options = new Database.DMLOptions();
        this.options.OptAllOrNone = true;
      }
      return this.options;
    }
    set;
  }

  public virtual SObject doInsert(SObject record) {
    return this.doInsert(new List<SObject>{ record })[0];
  }
  public virtual List<SObject> doInsert(List<SObject> records) {
    this.sortToPreventChunkingErrors(records);
    Database.insert(records, this.options, this.accessLevel);
    return records;
  }

  public virtual SObject doUpdate(SObject record) {
    return this.doUpdate(new List<SObject>{ record })[0];
  }
  public virtual List<SObject> doUpdate(List<SObject> records) {
    this.sortToPreventChunkingErrors(records);
    Database.update(records, this.options, this.accessLevel);
    return records;
  }

  public virtual SObject doUpsert(SObject record) {
    return this.doUpsert(new List<SObject>{ record })[0];
  }

  public virtual List<SObject> doUpsert(List<SObject> records) {
    this.sortToPreventChunkingErrors(records);
    Database.upsert(records, this.options.OptAllOrNone, this.accessLevel);
    return records;
  }

  public virtual List<SObject> doUpsert(List<SObject> records, Schema.SObjectField externalIdField) {
    Database.upsert(records, externalIdField, this.options.OptAllOrNone, this.accessLevel);
    return records;
  }

  public virtual SObject doUndelete(SObject record) {
    return this.doUnDelete(new List<SObject>{ record })[0];
  }
  public virtual List<SObject> doUndelete(List<SObject> records) {
    Database.undelete(records, this.options.OptAllOrNone, this.accessLevel);
    return records;
  }

  public virtual void doDelete(SObject record) {
    this.doDelete(new List<SObject>{ record });
  }
  public virtual void doDelete(List<SObject> records) {
    Database.delete(records, this.options.OptAllOrNone, this.accessLevel);
  }

  public virtual void doHardDelete(SObject record) {
    this.doHardDelete(new List<SObject>{ record });
  }
  public virtual void doHardDelete(List<SObject> records) {
    this.doDelete(records);
    Database.emptyRecycleBin(records);
  }

  public DML setOptions(Database.DMLOptions options, System.AccessLevel accessLevel) {
    if (options != null) {
      this.options = options;
    }
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
}
