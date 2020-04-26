@isTest
private class TriggerHandler_Tests {
    @isTest
    static void it_should_perform_before_insert() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.beforeInsert(null);

        System.assertEquals(TriggerOperation.BEFORE_INSERT, testHandler.Method);
    }

    @isTest
    static void it_should_perform_before_update() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.beforeUpdate(null, null, null, null);

        System.assertEquals(TriggerOperation.BEFORE_UPDATE, testHandler.Method);
    }

    @isTest
    static void it_should_perform_before_delete() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.beforeDelete(null, null);

        System.assertEquals(TriggerOperation.BEFORE_DELETE, testHandler.Method);
    }

    @isTest
    static void it_should_perform_after_insert() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.afterInsert(null, null);

        System.assertEquals(TriggerOperation.AFTER_INSERT, testHandler.Method);
    }

    @isTest
    static void it_should_perform_after_update() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.afterUpdate(null, null, null, null);

        System.assertEquals(TriggerOperation.AFTER_UPDATE, testHandler.Method);
    }

    @isTest
    static void it_should_perform_after_delete() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.afterDelete(null, null);

        System.assertEquals(TriggerOperation.AFTER_DELETE, testHandler.Method);
    }

    @isTest
    static void it_should_perform_after_undelete() {
        TestTriggerHandler testHandler = new TestTriggerHandler();

        testHandler.afterUndelete(null, null);

        System.assertEquals(TriggerOperation.AFTER_UNDELETE, testHandler.Method);
    }

    private class TestTriggerHandler extends TriggerHandler {
        public TriggerOperation Method { get; private set;}

        @testVisible protected override void beforeInsert(List<SObject> newRecords) { this.Method = TriggerOperation.BEFORE_INSERT; }
        @testVisible protected override void beforeUpdate(List<SObject> updatedRecords, Map<Id, SObject> updatedRecordsMap, List<SObject> oldRecords, Map<Id, SObject> oldRecordsMap) {
            this.Method = TriggerOperation.BEFORE_UPDATE;
        }
        @testVisible protected override void beforeDelete(List<SObject> deletedRecords, Map<Id, SObject> deletedRecordsMap) {
            this.Method = TriggerOperation.BEFORE_DELETE;
        }
        @testVisible protected override void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordsMap) {
            this.Method = TriggerOperation.AFTER_INSERT;
        }
        @testVisible protected override void afterUpdate(List<SObject> updatedRecords, Map<Id, SObject> updatedRecordsMap, List<SObject> oldRecords, Map<Id, SObject> oldRecordsMap) {
            this.Method = TriggerOperation.AFTER_UPDATE;
        }
        @testVisible protected override void afterDelete(List<SObject> deletedRecords, Map<Id, SObject> deletedRecordsMap) {
            this.Method = TriggerOperation.AFTER_DELETE;
        }
        @testVisible protected override void afterUndelete(List<SObject> undeletedRecords, Map<Id, SObject> undeletedRecordsMap) {
            this.Method = TriggerOperation.AFTER_UNDELETE;
        }
    }
}