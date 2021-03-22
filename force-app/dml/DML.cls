public virtual class DML implements IDML {
    /**
     * To use this class properly, see the Factory class:
     * DML should be injected as a dependency by the factory
     * then in your tests, the Factory.withMocks method
     * becomes your one-stop-shop signal for switching to the DMLMock in tests
    */
    @testVisible private static Integer MAX_DML_CHUNKING = 10;

    public virtual SObject doInsert(SObject record) { return this.doInsert(new List<SObject>{ record })[0];}
    public virtual List<SObject> doInsert(List<SObject> records) {
        this.sortToPreventChunkingErrors(records);
        Database.insert(records);
        return records;
    }

    public virtual SObject doUpdate(SObject record) { return this.doUpdate(new List<SObject>{ record })[0]; }
    public virtual List<SObject> doUpdate(List<SObject> records) {
        this.sortToPreventChunkingErrors(records);
        Database.update(records);
        return records;
    }

    public virtual SObject doUpsert(SObject record) {
        return this.doUpsert(new List<SObject>{ record })[0];
    }

    public virtual List<SObject> doUpsert(List<SObject> records) {
        this.sortToPreventChunkingErrors(records);
        Database.upsert(records);
        return records;
    }

    public virtual List<SObject> doUpsert(List<SObject> records, Schema.SObjectField externalIdField) {
        Database.upsert(records, externalIdField);
        return records;
    }

    public virtual SObject doUndelete(SObject record) { return this.doUnDelete(new List<SObject>{ record })[0]; }
    public virtual List<SObject> doUndelete(List<SObject> records) {
        Database.undelete(records);
        return records;
    }

    public virtual void doDelete(SObject record) { this.doDelete(new List<SObject>{ record }); }
    public virtual void doDelete(List<SObject> records) {
        Database.delete(records);
    }

    public virtual void doHardDelete(SObject record) { this.doHardDelete(new List<SObject>{ record }); }
    public virtual void doHardDelete(List<SObject> records) {
        this.doDelete(records);
        Database.emptyRecycleBin(records);
    }

    private void sortToPreventChunkingErrors(List<SObject> records) {
        //prevents a chunking error that can occur if SObject types are in the list out of order.
        //no need to sort if the list size is below the limit
        if (records.size() >= MAX_DML_CHUNKING) {
            records.sort();
        }
    }
}
