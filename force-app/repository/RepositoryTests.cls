@IsTest
private class RepositoryTests {
  @IsTest
  static void it_should_take_in_a_query() {
    Query basicQuery = Query.equals(ContactPointAddress.PreferenceRank, 1);
    IRepository repo = new ContactPointAddressRepo();

    repo.get(basicQuery);
    System.assertEquals(1, Limits.getQueries());
  }

  @IsTest
  static void it_should_handle_lists_and_sets_of_ids_or_strings() {
    Id accountId = TestingUtils.generateId(Account.SObjectType);
    Id secondAccountId = TestingUtils.generateId(Account.SObjectType);
    List<Id> ids = new List<Id>{ accountId, secondAccountId };
    Set<Id> setIds = new Set<Id>(ids);
    Set<String> cpaNames = new Set<String>{ 'Open', 'Closed' };

    Query listQuery = Query.equals(ContactPointAddress.ParentId, ids);
    Query setQuery = Query.equals(ContactPointAddress.ParentId, setIds);
    Query setStringQuery = Query.equals(ContactPointAddress.Name, cpaNames);

    IRepository repo = new ContactPointAddressRepo();

    repo.get(listQuery);
    repo.get(setQuery);
    repo.get(setStringQuery);
    System.assertEquals(3, Limits.getQueries());
    System.assertEquals('Name = :bindVar3', setStringQuery.toString());
    System.assertEquals(cpaNames, setStringQuery.getBindVars().get('bindVar3'));
  }

  @IsTest
  static void it_should_query_with_empty_collections() {
    Query listQuery = Query.equals(ContactPointAddress.Id, new List<Id>());

    IRepository repo = new ContactPointAddressRepo();

    List<SObject> results = repo.get(listQuery);
    System.assertEquals(0, results.size());
    System.assertEquals(1, Limits.getQueries());
  }

  @IsTest
  static void it_should_respect_or_statements_in_queries() {
    ContactPointAddress cpa = new ContactPointAddress(Name = 'Test Or', PreferenceRank = 1);
    ContactPointAddress secondCpa = new ContactPointAddress(Name = 'Test Or Two', PreferenceRank = 2);
    insert new List<ContactPointAddress>{ cpa, secondCpa };

    IRepository repo = new ContactPointAddressRepo();

    Id nullId = null;
    Query andQuery = Query.equals(ContactPointAddress.ParentId, nullId);
    Query secondAnd = Query.notEquals(ContactPointAddress.Id, nullId);
    Query orQuery = Query.orQuery(
      Query.equals(ContactPointAddress.PreferenceRank, cpa.PreferenceRank),
      Query.equals(ContactPointAddress.PreferenceRank, secondCpa.PreferenceRank)
    );

    List<ContactPointAddress> cpas = repo.get(new List<Query>{ andQuery, secondAnd, orQuery });
    System.assertEquals(2, cpas.size());
  }

  @IsTest
  static void it_should_respect_not_like_syntax_for_multiple_values() {
    ContactPointAddress cpa = new ContactPointAddress(Name = 'Test Or', PreferenceRank = 1);
    ContactPointAddress secondCpa = new ContactPointAddress(Name = 'Something different', PreferenceRank = 2);
    insert new List<ContactPointAddress>{ cpa, secondCpa };

    IRepository repo = new ContactPointAddressRepo();

    Query notLike = Query.notLike(ContactPointAddress.Name, new List<String>{ cpa.Name, 'someOtherString' });

    List<ContactPointAddress> cpas = repo.get(notLike);

    System.assertEquals(1, cpas.size());
    System.assertEquals(secondCpa.Id, cpas[0].Id);
  }

  @IsTest
  static void it_should_add_parent_fields() {
    GroupMemberRepo repo = new GroupMemberRepo();
    repo.addParentFields(
      new List<Schema.SObjectField>{ GroupMember.GroupId },
      new List<Schema.SObjectField>{ Group.Id }
    );

    Group grp = new Group(Name = RepositoryTests.class.getName());
    insert grp;
    GroupMember member = new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId());
    insert member;
    List<GroupMember> members = repo.get(Query.equals(GroupMember.Id, member.Id));

    System.assertEquals(1, members.size());
    System.assertEquals(grp.Id, members[0].Group.Id);
  }

  @IsTest
  static void it_should_add_child_fields() {
    IRepository repo = new AccountRepo()
      .addChildFields(
        Contact.AccountId,
        new List<QueryField>{
          new QueryField(Contact.AccountId),
          new QueryField(Contact.LastName),
          new QueryField(
            new List<Schema.SObjectField>{ Contact.AccountId },
            new List<Schema.SObjectField>{ Account.Name }
          )
        },
        new List<Query>(),
        new Map<String, RepositorySortOrder>(),
        1
      );

    Account acc = new Account(Name = 'Parent');
    insert acc;
    Contact con = new Contact(AccountId = acc.Id, LastName = 'Child');
    insert con;

    List<Account> accounts = repo.getAll();

    System.assertEquals(1, accounts.size());
    System.assertEquals(1, accounts.get(0).Contacts.size());
    Contact returnedCon = accounts.get(0).Contacts.get(0);
    System.assertEquals(con.LastName, returnedCon.LastName);
    System.assertEquals(acc.Name, returnedCon.Account.Name);
  }

  @IsTest
  static void it_adds_child_fields_with_filters() {
    String nameFilter = 'Child';
    IRepository repo = new AccountRepo()
      .addChildFields(
        Contact.AccountId,
        new List<Schema.SObjectField>{ Contact.AccountId, Contact.LastName },
        new List<Query>{ Query.equals(Contact.LastName, nameFilter) },
        new Map<String, RepositorySortOrder>(),
        1
      );

    Account acc = new Account(Name = 'Parent');
    insert acc;
    Contact con = new Contact(AccountId = acc.Id, LastName = nameFilter);
    Contact secondRecord = new Contact(AccountId = acc.Id, LastName = nameFilter);
    Contact excluded = new Contact(AccountId = acc.Id, LastName = 'Excluded');
    insert new List<Contact>{ con, secondRecord, excluded };

    List<Account> accounts = repo.getAll();
    System.assertEquals(1, accounts.size());
    System.assertEquals(1, accounts.get(0).Contacts.size());
  }

  @IsTest
  static void it_should_sort_and_limit_correctly() {
    insert new List<Account>{
      new Account(Name = 'Two', AnnualRevenue = 1),
      new Account(Name = 'One'),
      new Account(Name = 'Three')
    };

    List<Account> accounts = new AccountRepo()
      .addSortOrder(Account.Name, RepositorySortOrder.ASCENDING)
      .addSortOrder(
        Account.AnnualRevenue,
        new RepositorySortOrder(RepositorySortOrder.SortOrder.DESCENDING, RepositorySortOrder.NullSortOrder.LAST)
      )
      .setLimit(1)
      .getAll();

    System.assertEquals(1, accounts.size());
    System.assertEquals('One', accounts.get(0).get(Account.Name));
  }

  @IsTest
  static void it_sorts_by_parent_fields() {
    List<Account> accounts = new List<Account>{
      new Account(Name = 'Should Not Be Returned'),
      new Account(Name = 'Parent B'),
      new Account(Name = 'Should Be Returned'),
      new Account(Name = 'Parent A')
    };
    insert accounts;

    accounts[0].ParentId = accounts[1].Id;
    accounts[2].ParentId = accounts[3].Id;
    update accounts;

    List<Account> returnedAccounts = new AccountRepo()
      .addParentFields(
        new List<Schema.SObjectField>{ Account.ParentId },
        new List<Schema.SObjectField>{ Account.Id, Account.Name }
      )
      .addSortOrder(
        new List<Schema.SObjectField>{ Account.ParentId, Account.Name },
        new RepositorySortOrder(RepositorySortOrder.SortOrder.ASCENDING, RepositorySortOrder.NullSortOrder.LAST)
      )
      .setLimit(1)
      .getAll();

    Assert.areEqual(accounts[2].Name, returnedAccounts[0].Name);
    Assert.areEqual(accounts[2].Id, returnedAccounts[0].Id);
    Assert.areEqual(accounts[3].Id, returnedAccounts[0].Parent.Id);
    Assert.areEqual(accounts[3].Name, returnedAccounts[0].Parent.Name);
  }

  @IsTest
  static void it_should_decorate_dml_methods() {
    IRepository repo = new RepoFactory().setFacade(new RepoFactoryMock.FacadeMock()).getProfileRepo();
    Account acc = new Account();
    List<Account> accs = new List<Account>{ acc };

    repo.setAccessLevel(System.AccessLevel.USER_MODE)
      .setOptions(new Database.DMLOptions(), System.AccessLevel.USER_MODE);

    repo.doInsert(acc);
    repo.doInsert(accs);
    System.assertEquals(acc, DMLMock.Inserted.Accounts.firstOrDefault);

    repo.doUpdate(acc);
    repo.doUpdate(accs);
    System.assertEquals(acc, DMLMock.Updated.Accounts.firstOrDefault);

    repo.doUpsert(acc);
    repo.doUpsert(accs);
    System.assertEquals(acc, DMLMock.Upserted.Accounts.firstOrDefault);

    repo.doDelete(acc);
    repo.doDelete(accs);
    System.assertEquals(acc, DMLMock.Deleted.Accounts.firstOrDefault);

    repo.doUndelete(acc);
    repo.doUndelete(accs);
    System.assertEquals(acc, DMLMock.Undeleted.Accounts.firstOrDefault);

    repo.doHardDelete(acc);
    repo.doHardDelete(accs);
    System.assertEquals(acc, DMLMock.Deleted.Accounts.firstOrDefault);

    BatchApexErrorEvent event = new BatchApexErrorEvent();
    repo.publish(event);
    repo.publish(new List<SObject>{ event });
    System.assertEquals(event, DMLMock.Published.firstOrDefault);
  }

  @IsTest
  static void it_performs_sosl_queries() {
    ContactPointAddress cpa = new ContactPointAddress(Name = 'hello world', PreferenceRank = 1);
    insert cpa;
    Test.setFixedSearchResults(new List<Id>{ cpa.Id });

    List<List<SObject>> results = new ContactPointAddressRepo()
      .setSearchGroup(SearchGroup.NAME_FIELDS)
      .getSosl('hel', Query.equals(ContactPointAddress.PreferenceRank, 1));

    System.assertEquals(cpa.Id, results.get(0).get(0).Id);
  }

  @IsTest
  static void it_searches_for_additional_objects() {
    ContactPointPhone record = new ContactPointPhone(TelephoneNumber = 'hello universe');
    insert record;

    Test.setFixedSearchResults(new List<Id>{ record.Id });

    List<List<SObject>> results = new ContactPointAddressRepo()
      .setSearchGroup(SearchGroup.NAME_FIELDS)
      .getSosl(
        'hel',
        new List<Query>{ Query.equals(ContactPointAddress.PreferenceRank, 1) },
        new List<AdditionalSoslObject>{
          new AdditionalSoslObject(
            ContactPointPhone.SObjectType,
            new List<Schema.SObjectField>(),
            new List<Query>{ Query.equals(ContactPointPhone.TelephoneNumber, 'hello universe') },
            1
          )
        }
      );

    System.assertEquals(record.Id, results.get(1).get(0).Id);
  }

  @IsTest
  static void it_handles_empty_sosl_searches() {
    ContactPointPhone record = new ContactPointPhone(TelephoneNumber = 'hello universe');
    insert record;

    Test.setFixedSearchResults(new List<Id>{ record.Id });

    List<List<SObject>> results = new ContactPointAddressRepo()
      .setSearchGroup(SearchGroup.NAME_FIELDS)
      .getSosl(
        'hel',
        new List<Query>(),
        new List<AdditionalSoslObject>{
          new AdditionalSoslObject(
            ContactPointPhone.SObjectType,
            new List<Schema.SObjectField>(),
            new List<Query>{
              Query.notEquals(ContactPointPhone.Id, new List<Id>()),
              Query.equals(ContactPointPhone.TelephoneNumber, 'hello universe')
            },
            1
          )
        }
      );

    System.assertEquals(record.Id, results.get(1).get(0).Id);
  }

  @IsTest
  static void it_adds_function_field_without_alias(){
    // Arrange
    Account acc = new Account(
      Name = 'hello world',
      Industry = Account.Industry.getDescribe().getPicklistValues().get(0).getValue()
    );
    insert acc;

    IRepository repo = new AccountRepo();
    repo.addFunctionBaseField(SelectFunction.TOLABEL, Account.Industry);

    // Act
    Test.startTest();
    List<Account> results = repo.setLimit(1).getAll();
    Test.stopTest();

    // Assert
    Assert.areEqual(
      Account.Industry.getDescribe().getPicklistValues().get(0).getLabel(),
      results.get(0).Industry,
      'Account.Industry should equal label'
    );
  }

  @IsTest
  static void it_adds_base_field_and_function_field_with_automatic_alias(){
    // Arrange
    Date activeFromDate = Date.newInstance(2001, 1, 1);
    ContactPointAddress cpa = new ContactPointAddress(Name = 'hello world', PreferenceRank = 1, ActiveFromDate = activeFromDate);
    insert cpa;

    IRepository repo = new ContactPointAddressRepo();
    repo.addBaseFields(new List<Schema.SObjectField>{ContactPointAddress.ActiveFromDate});
    repo.addFunctionBaseField(SelectFunction.FORMAT, ContactPointAddress.ActiveFromDate);

    User testUserGerman = TestingUtils.generate_german_user();
    String activeFromDateGerman;
    List<ContactPointAddress> results = new List<ContactPointAddress>();

    // Act
    Test.startTest();
    System.runAs(testUserGerman){
      results = repo.setLimit(1).getAll();
      activeFromDateGerman = activeFromDate.format();
    }
    Test.stopTest();

    // Assert
    Assert.isNotNull(results.get(0).ActiveFromDate, 'ActiveFromDate should not be null');
    Assert.areEqual(
      activeFromDateGerman,
      results.get(0).get('ActiveFromDate_FORMAT'),
      'ActiveFromDate_FORMAT should equal ' + activeFromDateGerman
    );
  }

  @IsTest
  static void it_adds_base_field_and_function_field_with_manual_alias(){
    // Arrange
    Date activeFromDate = Date.newInstance(2001, 1, 1);
    ContactPointAddress cpa = new ContactPointAddress(Name = 'hello world', PreferenceRank = 1, ActiveFromDate = activeFromDate);
    insert cpa;

    IRepository repo = new ContactPointAddressRepo();
    repo.addBaseFields(new List<Schema.SObjectField>{ContactPointAddress.ActiveFromDate});
    repo.addFunctionBaseFields(SelectFunction.FORMAT, new Map<Schema.SObjectField, String>{ContactPointAddress.ActiveFromDate => 'AktivSeit'});

    User testUserGerman = TestingUtils.generate_german_user();
    String activeFromDateGerman;
    List<ContactPointAddress> results = new List<ContactPointAddress>();

    // Act
    Test.startTest();
    System.runAs(testUserGerman){
      results = repo.setLimit(1).getAll();
      activeFromDateGerman = activeFromDate.format();
    }
    Test.stopTest();

    // Assert
    Assert.isNotNull(results.get(0).ActiveFromDate, 'ActiveFromDate should not be null');
    Assert.areEqual(
      activeFromDateGerman,
      results.get(0).get('AktivSeit'),
      'AktivSeit should equal '+ activeFromDateGerman
    );
  }

  private class GroupMemberRepo extends Repository {
    public GroupMemberRepo() {
      super(GroupMember.SObjectType, new List<Schema.SObjectField>{ GroupMember.GroupId }, new RepoFactory());
    }
  }

  private class ContactPointAddressRepo extends Repository {
    public ContactPointAddressRepo() {
      super(
        ContactPointAddress.SObjectType,
        new List<Schema.SObjectField>{
          ContactPointAddress.Id,
          ContactPointAddress.PreferenceRank,
          ContactPointAddress.ParentId,
          ContactPointAddress.Name
        },
        new RepoFactory()
      );
    }
  }

  private class AccountRepo extends Repository {
    public AccountRepo() {
      super(Account.SObjectType, new List<Schema.SObjectField>{ Account.Name }, new RepoFactory());
    }
  }
}
