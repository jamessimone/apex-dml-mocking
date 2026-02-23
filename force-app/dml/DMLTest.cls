@IsTest
private class DMLTest {
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

    Assert.isNotNull(contact.Id);
  }

  @IsTest
  static void shouldPerformUpdate() {
    Contact contact = [SELECT Id FROM Contact];

    contact.FirstName = 'Harry';
    new DML().doUpdate(contact);

    Assert.isTrue(contact.FirstName == 'Harry');
  }

  @IsTest
  static void shouldNotFailWhileUpdatingEmptyList() {
    List<Contact> contacts = new List<Contact>();
    new DML().doUpdate(contacts);

    Assert.isTrue(true, 'Should make it here');
  }

  @IsTest
  static void shouldPerformUpsert() {
    Contact contact = [SELECT Id FROM Contact];
    contact.FirstName = 'Harry';
    new DML().doUpsert(contact);

    contact = [SELECT Id, FirstName FROM Contact WHERE Id = :contact.Id];

    Assert.isTrue(contact.FirstName == 'Harry');
  }

  @IsTest
  static void shouldPerformDelete() {
    Contact contact = [SELECT Id FROM Contact];

    new DML().doDelete(contact);
    List<Contact> deletedContacts = [SELECT Id, IsDeleted FROM Contact ALL ROWS];

    Assert.isTrue(deletedContacts[0].IsDeleted);
  }

  @IsTest
  static void shouldPerformHardDelete() {
    Contact contact = [SELECT Id FROM Contact];

    new DML().doHardDelete(contact);
    List<Contact> deletedContacts = [SELECT Id, IsDeleted FROM Contact ALL ROWS];

    Assert.isTrue(deletedContacts[0].IsDeleted);
  }

  @IsTest
  static void hardDeleteDoesNotThrowWithEmptyList() {
    new DML().doHardDelete(new List<SObject>());

    Assert.isTrue(true, 'Made it here');
  }

  @IsTest
  static void shouldPerformUndelete() {
    Contact contact = [SELECT Id FROM Contact];

    IDML dml = new DML();
    dml.doDelete(contact);
    dml.doUndelete(contact);

    List<Contact> notDeletedContacts = [SELECT Id FROM Contact];
    Assert.isTrue(!notDeletedContacts.isEmpty());
  }

  @IsTest
  static void shouldRollbackUpsertOnError() {
    Account one = new Account(Name = 'Test1');
    Account two = new Account();
    try {
      // this should fail because name is a required field on Account
      new DML().doUpsert(new List<Account>{ one, two });
      Assert.fail('Should throw in above unit');
    } catch (Exception e) {
      Assert.isInstanceOfType(e, System.DmlException.class);
      // do nothing, in this case
    }

    Assert.areEqual(null, one.Id);
    Assert.areEqual(null, two.Id);
  }

  @IsTest
  static void shouldNotFailDueToChunkingError() {
    List<SObject> records = new List<SObject>();
    List<Account> accounts = new List<Account>();
    List<Contact> contacts = new List<Contact>();

    for (Integer i = 0; i < DML.MAX_DML_CHUNKING; i++) {
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
      Assert.isNull(ex, ex.getMessage());
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
    Assert.areEqual(accs, wrapper.Records);
    Assert.areEqual(1, wrapper.size());
    Assert.areEqual(accs[0], wrapper.singleOrDefault);
    Assert.areEqual(accs[0], wrapper.firstOrDefault);

    Assert.areEqual(true, wrapper.hasId(accs[0].Id));
    Assert.areEqual(true, wrapper.hasId(accs[0].Id, Account.Id));
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

  @IsTest
  static void shouldPassNonNullValueOnOperatonThatDoesNotUseDmlOptions() {
    Database.DMLOptions dmlOptions = new Database.DMLOptions();
    dmlOptions.AllowFieldTruncation = true;
    Contact contact = new Contact(LastName = 'Test2');

    new DML().setOptions(dmlOptions).doUpsert(contact);

    Assert.isNotNull(contact.Id);
  }

  @IsTest
  static void upsertWithDefaultSetOptionsWorks() {
    // on some code paths, like insert, OptAllOrNone not being initialized on Database.DMLOptions is fine
    // but on upsert (and possibly other operations), that specific value is always checked
    Contact con = new Contact(LastName = 'Upsert');

    new DML().setOptions(new Database.DMLOptions(), System.AccessLevel.SYSTEM_MODE).doUpsert(con);

    Assert.isNotNull(con.Id);
  }
}
