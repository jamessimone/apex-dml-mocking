@isTest
private class DMLTests {
    @TestSetup
    static void setup() {
        Contact con = new Contact(LastName='Test1');
        con.Email = 'something@something.com';
        insert new List<SObject>{ new Account(Name='TestAccount'), con };
    }

    @isTest
    static void shouldPerformInsert() {
        Contact contact = new Contact(LastName= 'Test2');
        new DML().doInsert(contact);

        System.assertNotEquals(null, contact.Id);
    }

    @isTest
    static void shouldPerformUpdate() {
        Contact contact = [SELECT Id FROM Contact];

        contact.FirstName = 'Harry';
        new DML().doUpdate(contact);

        System.assert(contact.FirstName == 'Harry');
    }

    @isTest
    static void shouldNotFailWhileUpdatingEmptyList() {
        List<Contact> contacts = new List<Contact>();
        new DML().doUpdate(contacts);

        System.assert(true, 'Should make it here');
    }

    @isTest
    static void shouldPerformUpsert() {
        Contact contact = [SELECT Id FROM Contact];
        contact.FirstName = 'Harry';
        new DML().doUpsert(contact);

        contact = [SELECT Id, FirstName FROM Contact WHERE Id = :contact.Id];

        System.assert(contact.FirstName == 'Harry');
    }

    @isTest
    static void shouldPerformDelete() {
        Contact contact = [SELECT Id FROM Contact];

        new DML().doDelete(contact);
        List<Contact> deletedContacts = [SELECT Id, IsDeleted FROM Contact ALL ROWS];

        System.assert(deletedContacts[0].IsDeleted);
    }

    @isTest
    static void shouldPerformHardDelete() {
        Contact contact = [SELECT Id FROM Contact];

        new DML().doHardDelete(contact);
        List<Contact> deletedContacts = [SELECT Id, IsDeleted FROM Contact ALL ROWS];

        System.assert(deletedContacts[0].IsDeleted);
    }

    @isTest
    static void shouldPerformUndelete() {
        Contact contact = [SELECT Id FROM Contact];

        IDML dml = new DML();
        dml.doDelete(contact);
        dml.doUndelete(contact);

        List<Contact> notDeletedContacts = [SELECT Id FROM Contact];
        System.assert(!notDeletedContacts.isEmpty());
    }

    @isTest
    static void shouldRollbackUpsertOnError() {
        Account one = new Account(Name = 'Test1');
        Account two = new Account();
        try { // this should fail because name is a required field on Account
            new DML().doUpsert(new List<Account>{ one, two });
        } catch (Exception e) {
            // do nothing, in this case
        }

        System.assertEquals(null, one.Id);
        System.assertEquals(null, two.Id);
    }

    @isTest
    static void shouldNotFailDueToChunkingError() {
        List<SObject> records = new List<SObject>();
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();

        for(Integer i = 0; i < dml.MAX_DML_CHUNKING; i ++) {
            Account a = new Account(Name=''+i);
            accounts.add(a);
            records.add(a);

            Contact c = new Contact(LastName=''+i);
            contacts.add(c);
            records.add(c);
        }

        insert accounts;
        insert contacts;

        try {
            new DML().doUpdate(records);
        } catch(Exception ex) {
            System.assert(false, ex);
        }
    }
}