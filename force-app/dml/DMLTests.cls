@IsTest
private class DMLTests {
  @TestSetup
  static void setup() {
    Contact con = new Contact(LastName = 'Test1');
    con.Email = 'something@something.com';
    insert new List<SObject>{ new Account(Name = 'TestAccount'), con };
  }

  @IsTest
  static void shouldPerformInsert() {
    Contact contact = new Contact(LastName = 'Test2');
    new DML().doInsert(contact);

    System.assertNotEquals(null, contact.Id);
  }

  @IsTest
  static void shouldPerformUpdate() {
    Contact contact = [SELECT Id FROM Contact];

    contact.FirstName = 'Harry';
    new DML().doUpdate(contact);

    System.assert(contact.FirstName == 'Harry');
  }

  @IsTest
  static void shouldNotFailWhileUpdatingEmptyList() {
    List<Contact> contacts = new List<Contact>();
    new DML().doUpdate(contacts);

    System.assert(true, 'Should make it here');
  }

  @IsTest
  static void shouldPerformUpsert() {
    Contact contact = [SELECT Id FROM Contact];
    contact.FirstName = 'Harry';
    new DML().doUpsert(contact);

    contact = [SELECT Id, FirstName FROM Contact WHERE Id = :contact.Id];

    System.assert(contact.FirstName == 'Harry');
  }

  @IsTest
  static void shouldPerformDelete() {
    Contact contact = [SELECT Id FROM Contact];

    new DML().doDelete(contact);
    List<Contact> deletedContacts = [SELECT Id, IsDeleted FROM Contact ALL ROWS];

    System.assert(deletedContacts[0].IsDeleted);
  }

  @IsTest
  static void shouldPerformHardDelete() {
    Contact contact = [SELECT Id FROM Contact];

    new DML().doHardDelete(contact);
    List<Contact> deletedContacts = [SELECT Id, IsDeleted FROM Contact ALL ROWS];

    System.assert(deletedContacts[0].IsDeleted);
  }

  @IsTest
  static void shouldPerformUndelete() {
    Contact contact = [SELECT Id FROM Contact];

    IDML dml = new DML();
    dml.doDelete(contact);
    dml.doUndelete(contact);

    List<Contact> notDeletedContacts = [SELECT Id FROM Contact];
    System.assert(!notDeletedContacts.isEmpty());
  }

  @IsTest
  static void shouldRollbackUpsertOnError() {
    Account one = new Account(Name = 'Test1');
    Account two = new Account();
    try {
      // this should fail because name is a required field on Account
      new DML().doUpsert(new List<Account>{ one, two });
    } catch (Exception e) {
      // do nothing, in this case
    }

    System.assertEquals(null, one.Id);
    System.assertEquals(null, two.Id);
  }

  @IsTest
  static void shouldNotFailDueToChunkingError() {
    List<SObject> records = new List<SObject>();
    List<Account> accounts = new List<Account>();
    List<Contact> contacts = new List<Contact>();

    for (Integer i = 0; i < dml.MAX_DML_CHUNKING; i++) {
      Account a = new Account(Name = '' + i);
      accounts.add(a);
      records.add(a);

      Contact c = new Contact(LastName = '' + i);
      contacts.add(c);
      records.add(c);
    }

    insert accounts;
    insert contacts;

    try {
      new DML().doUpdate(records);
    } catch (Exception ex) {
      System.assert(false, ex);
    }
  }

  @IsTest
  static void shouldFakeDMLOperations() {
    // some of these operations aren't awesome
    // but this ensures adequate code coverage prior to
    // being used elsewhere in the codebase for mocking
    IDML mock = new DMLMock();

    List<Account> accs = new List<Account>{ new Account() };

    mock.doInsert(accs);

    mock.doUpdate(accs);

    mock.doUpsert(accs);
    mock.doUpsert(accs, Account.Name);

    mock.doDelete(accs);

    mock.doUndelete(accs);

    DMLMock.RecordsWrapper wrapper = DMLMock.Inserted.ofType(Account.SObjectType);
    System.assertEquals(accs, wrapper.Records);
    System.assertEquals(1, wrapper.size());
    System.assertEquals(accs[0], wrapper.singleOrDefault);
    System.assertEquals(accs[0], wrapper.firstOrDefault);

    Id fakeAccountId = TestingUtils.generateId(Account.SObjectType);
    System.assertEquals(true, wrapper.hasId(accs[0].Id));
    System.assertEquals(true, wrapper.hasId(accs[0].Id, Account.Id));

    System.assert(true, 'Should make it here');
  }

  @IsTest
  static void publishesEvents() {
    BatchApexErrorEvent first = new BatchApexErrorEvent();
    BatchApexErrorEvent second = new BatchApexErrorEvent();

    IDML dml = new DML();
    Database.SaveResult firstResult = dml.publish(first);
    Database.SaveResult secondResult = dml.publish(new List<SObject>{ second }).get(0);

    Assert.areEqual(true, firstResult.isSuccess());
    Assert.areEqual(true, secondResult.isSuccess());
  }
}
