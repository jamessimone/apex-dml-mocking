@IsTest
private class RepositoryTest {
  @IsTest
  static void itShouldTakeInAQuery() {
    Query basicQuery = Query.equals(ContactPointAddress.PreferenceRank, 1);
    IRepository repo = new ContactPointAddressRepo();

    repo.get(basicQuery);
    Assert.areEqual(1, Limits.getQueries());
  }

  @IsTest
  static void itShouldHandleListsAndSetsOfIdsOrStrings() {
    Id accountId = TestingUtils.generateId(Account.SObjectType);
    Id secondAccountId = TestingUtils.generateId(Account.SObjectType);
    List<Id> ids = new List<Id>{ accountId, secondAccountId };
    Set<Id> setIds = new Set<Id>(ids);
    Set<String> cpaNames = new Set<String>{ 'Open', 'Closed' };

    Query listQuery = Query.equals(ContactPointAddress.ParentId, ids);
    Query setQuery = Query.equals(ContactPointAddress.Id, setIds);
    Query setStringQuery = Query.equals(ContactPointAddress.Name, cpaNames);

    IRepository repo = new ContactPointAddressRepo();

    repo.get(listQuery);
    repo.get(setQuery);
    repo.get(setStringQuery);
    Assert.areEqual(3, Limits.getQueries());
    Assert.areEqual('ParentId = :bindVar0', listQuery.toString());
    Assert.areEqual(ids, listQuery.getBindVars().get('bindVar0'));
    Assert.areEqual('Id = :bindVar1', setQuery.toString());
    Assert.areEqual(setIds, setQuery.getBindVars().get('bindVar1'));
    Assert.areEqual('Name = :bindVar2', setStringQuery.toString());
    Assert.areEqual(cpaNames, setStringQuery.getBindVars().get('bindVar2'));
  }

  @IsTest
  static void itShouldQueryWithEmptyCollections() {
    Query listQuery = Query.equals(ContactPointAddress.Id, new List<Id>());

    IRepository repo = new ContactPointAddressRepo();

    List<SObject> results = repo.get(listQuery);
    Assert.areEqual(0, results.size());
    Assert.areEqual(1, Limits.getQueries());
  }

  @IsTest
  static void itShouldSearchWithEmptyCollections() {
    Query listQuery = Query.equals(ContactPointAddress.Id, new List<Id>());

    IRepository repo = new ContactPointAddressRepo();

    List<List<SObject>> results = repo.getSosl('aaa', listQuery);
    Assert.areEqual(1, results.size());
    Assert.areEqual(0, results.get(0).size());
    Assert.areEqual(1, Limits.getSoslQueries());
  }

  @IsTest
  static void itShouldRespectOrStatementsInQueries() {
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
    Assert.areEqual(2, cpas.size());
  }

  @IsTest
  static void itShouldRespectNotLikeSyntaxForMultipleValues() {
    ContactPointAddress cpa = new ContactPointAddress(Name = 'Test Or', PreferenceRank = 1);
    ContactPointAddress secondCpa = new ContactPointAddress(Name = 'Something different', PreferenceRank = 2);
    insert new List<ContactPointAddress>{ cpa, secondCpa };

    IRepository repo = new ContactPointAddressRepo();

    Query notLike = Query.notLike(ContactPointAddress.Name, new List<String>{ cpa.Name, 'someOtherString' });

    List<ContactPointAddress> cpas = repo.get(notLike);

    Assert.areEqual(1, cpas.size());
    Assert.areEqual(secondCpa.Id, cpas[0].Id);
  }

  @IsTest
  static void itShouldAddParentFields() {
    GroupMemberRepo repo = new GroupMemberRepo();
    repo.addParentFields(
      new List<Schema.SObjectField>{ GroupMember.GroupId },
      new List<Schema.SObjectField>{ Group.Id }
    );

    Group grp = new Group(Name = RepositoryTest.class.getName());
    insert grp;
    GroupMember member = new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId());
    insert member;
    List<GroupMember> members = repo.get(Query.equals(GroupMember.Id, member.Id));

    Assert.areEqual(1, members.size());
    Assert.areEqual(grp.Id, members[0].Group.Id);
  }

  @IsTest
  static void itShouldAddChildFields() {
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

    Assert.areEqual(1, accounts.size());
    Assert.areEqual(1, accounts.get(0).Contacts.size());
    Contact returnedCon = accounts.get(0).Contacts.get(0);
    Assert.areEqual(con.LastName, returnedCon.LastName);
    Assert.areEqual(acc.Name, returnedCon.Account.Name);
  }

  @IsTest
  static void itShouldAddChildFieldsFromRepo() {
    IRepository repo = new AccountRepo()
      .addChildFields(
        Opportunity.AccountId,
        new OpportunityRepo().addChildFields(OpportunityContactRole.OpportunityId, new OpportunityContactRoleRepo())
      );

    Account acc = new Account(Name = 'Parent');
    insert acc;
    Contact con = new Contact(AccountId = acc.Id, LastName = 'Child Contact');
    insert con;
    Opportunity opp = new Opportunity(
      AccountId = acc.Id,
      Name = 'Chlid',
      StageName = Opportunity.StageName.getDescribe().getPicklistValues().get(0).getValue(),
      CloseDate = Date.today()
    );
    insert opp;
    OpportunityContactRole ocr = new OpportunityContactRole(
      OpportunityId = opp.Id,
      ContactId = con.Id,
      Role = OpportunityContactRole.Role.getDescribe().getPicklistValues().get(0).getValue()
    );
    insert ocr;

    List<Account> accounts = repo.getAll();
    Assert.areEqual(1, accounts.size());
    Assert.areEqual(1, accounts.get(0).Opportunities.size());
    Opportunity returnedOpp = accounts.get(0).Opportunities.get(0);
    Assert.areEqual(opp.Name, returnedOpp.Name);
    Assert.areEqual(1, returnedOpp.OpportunityContactRoles.size());
    OpportunityContactRole returnedOcr = returnedOpp.OpportunityContactRoles.get(0);
    Assert.areEqual(ocr.Role, returnedOcr.Role);
  }

  @IsTest
  static void itAddsChildFieldsWithFilters() {
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
    Assert.areEqual(1, accounts.size());
    Assert.areEqual(1, accounts.get(0).Contacts.size());
  }

  @IsTest
  static void itAddsChildFieldsWithFiltersFromRepo() {
    String nameFilter = 'Child';
    IRepository repo = new AccountRepo()
      .addChildFields(
        Contact.AccountId,
        new ContactRepo(),
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
    Assert.areEqual(1, accounts.size());
    Assert.areEqual(1, accounts.get(0).Contacts.size());
    // verify that filters can be used multiple times
    accounts = repo.getAll();
    Assert.areEqual(1, accounts.size());
    Assert.areEqual(1, accounts.get(0).Contacts.size());
  }

  @IsTest
  static void itShouldSortAndLimitCorrectly() {
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

    Assert.areEqual(1, accounts.size());
    Assert.areEqual('One', accounts.get(0).get(Account.Name));
  }

  @IsTest
  static void itSortsByParentFields() {
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
  static void itShouldDecorateDmlMethods() {
    IRepository repo = new RepoFactory().setFacade(new RepoFactoryMock.FacadeMock()).getProfileRepo();
    Account acc = new Account();
    List<Account> accs = new List<Account>{ acc };

    repo.setAccessLevel(System.AccessLevel.USER_MODE)
      .setOptions(new Database.DMLOptions(), System.AccessLevel.USER_MODE);

    repo.doInsert(acc);
    repo.doInsert(accs);
    Assert.areEqual(acc, DMLMock.Inserted.Accounts.firstOrDefault);

    repo.doUpdate(acc);
    repo.doUpdate(accs);
    Assert.areEqual(acc, DMLMock.Updated.Accounts.firstOrDefault);

    repo.doUpsert(acc);
    repo.doUpsert(accs);
    Assert.areEqual(acc, DMLMock.Upserted.Accounts.firstOrDefault);

    repo.doDelete(acc);
    repo.doDelete(accs);
    Assert.areEqual(acc, DMLMock.Deleted.Accounts.firstOrDefault);

    repo.doUndelete(acc);
    repo.doUndelete(accs);
    Assert.areEqual(acc, DMLMock.Undeleted.Accounts.firstOrDefault);

    repo.doHardDelete(acc);
    repo.doHardDelete(accs);
    Assert.areEqual(acc, DMLMock.Deleted.Accounts.firstOrDefault);

    BatchApexErrorEvent event = new BatchApexErrorEvent();
    repo.publish(event);
    repo.publish(new List<SObject>{ event });
    Assert.areEqual(event, DMLMock.Published.firstOrDefault);
  }

  @IsTest
  static void itPerformsSoslQueries() {
    ContactPointAddress cpa = new ContactPointAddress(Name = 'hello world', PreferenceRank = 1);
    insert cpa;
    Test.setFixedSearchResults(new List<Id>{ cpa.Id });

    List<List<SObject>> results = new ContactPointAddressRepo()
      .setSearchGroup(SearchGroup.NAME_FIELDS)
      .getSosl('hel', Query.equals(ContactPointAddress.PreferenceRank, 1));

    Assert.areEqual(cpa.Id, results.get(0).get(0).Id);
  }

  @IsTest
  static void itSearchesForAdditionalObjects() {
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

    Assert.areEqual(record.Id, results.get(1).get(0).Id);
  }

  @IsTest
  static void itHandlesEmptySoslSearches() {
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

    Assert.areEqual(record.Id, results.get(1).get(0).Id);
  }

  @IsTest
  static void itAddsFunctionFieldWithoutAlias() {
    Account acc = new Account(
      Name = 'hello world',
      Industry = Account.Industry.getDescribe().getPicklistValues().get(0).getValue()
    );
    insert acc;

    IRepository repo = new AccountRepo();
    repo.addFunctionBaseField(SelectFunction.TOLABEL, Account.Industry);

    Test.startTest();
    List<Account> results = repo.setLimit(1).getAll();
    Test.stopTest();

    Assert.areEqual(
      Account.Industry.getDescribe().getPicklistValues().get(0).getLabel(),
      results.get(0).Industry,
      'Account.Industry should equal label'
    );
  }

  @IsTest
  static void itAddsBaseFieldAndFunctionFieldWithAutomaticAlias() {
    Date activeFromDate = Date.newInstance(2001, 1, 1);
    ContactPointAddress cpa = new ContactPointAddress(
      Name = 'hello world',
      PreferenceRank = 1,
      ActiveFromDate = activeFromDate
    );
    insert cpa;

    IRepository repo = new ContactPointAddressRepo();
    repo.addBaseFields(new List<Schema.SObjectField>{ ContactPointAddress.ActiveFromDate });
    repo.addFunctionBaseField(SelectFunction.FORMAT, ContactPointAddress.ActiveFromDate);

    String activeFromDateFormatted;
    List<ContactPointAddress> results = new List<ContactPointAddress>();

    Test.startTest();
    results = repo.setLimit(1).getAll();
    activeFromDateFormatted = activeFromDate.format();
    Test.stopTest();

    Assert.isNotNull(results.get(0).ActiveFromDate, 'ActiveFromDate should not be null');
    Assert.areEqual(
      activeFromDateFormatted,
      results.get(0).get('ActiveFromDate_FORMAT'),
      'ActiveFromDate_FORMAT should equal ' + activeFromDateFormatted
    );
  }

  @IsTest
  static void itAddsBaseFieldAndFunctionFieldWithManualAlias() {
    Date activeFromDate = Date.newInstance(2001, 1, 1);
    ContactPointAddress cpa = new ContactPointAddress(
      Name = 'hello world',
      PreferenceRank = 1,
      ActiveFromDate = activeFromDate
    );
    insert cpa;

    IRepository repo = new ContactPointAddressRepo();
    repo.addBaseFields(new List<Schema.SObjectField>{ ContactPointAddress.ActiveFromDate });
    repo.addFunctionBaseFields(
      SelectFunction.FORMAT,
      new Map<Schema.SObjectField, String>{ ContactPointAddress.ActiveFromDate => 'AktivSeit' }
    );

    String activeFromDateFormatted;
    List<ContactPointAddress> results = new List<ContactPointAddress>();

    Test.startTest();
    results = repo.setLimit(1).getAll();
    activeFromDateFormatted = activeFromDate.format();
    Test.stopTest();

    Assert.isNotNull(results.get(0).ActiveFromDate, 'ActiveFromDate should not be null');
    Assert.areEqual(
      activeFromDateFormatted,
      results.get(0).get('AktivSeit'),
      'AktivSeit should equal ' + activeFromDateFormatted
    );
  }

  @IsTest
  static void itShouldReturnACursor() {
    List<Account> accounts = new List<Account>{
      new Account(Name = 'One'),
      new Account(Name = 'Two'),
      new Account(Name = 'Three')
    };
    insert accounts;

    IRepository repo = new AccountRepo();
    Cursor cursor = repo.getCursor(
      new List<Query>{ Query.orQuery(Query.equals(Account.Name, 'One'), Query.equals(Account.Name, 'Two')) }
    );
    Assert.areEqual(2, cursor.getNumRecords());
    Assert.areEqual(accounts[0].Id, cursor.fetch(0, 1).get(0).Id);
    Assert.areEqual(accounts[1].Id, cursor.fetch(1, 1).get(0).Id);
  }

  @IsTest
  static void itShouldReturnAnEmptyCursor() {
    List<Account> accounts = new List<Account>{ new Account(Name = 'One'), new Account(Name = 'Two') };
    insert accounts;

    IRepository repo = new AccountRepo();
    Cursor cursor = repo.getCursor(new List<Query>{ Query.equals(Account.Name, 'Three') });
    Assert.areEqual(0, cursor.getNumRecords());
    Assert.areEqual(new List<SObject>(), cursor.fetch(-111, -11111));
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

  private class ContactRepo extends Repository {
    public ContactRepo() {
      super(Contact.SObjectType, new List<Schema.SObjectField>{ Contact.LastName }, new RepoFactory());
    }
  }

  private class OpportunityRepo extends Repository {
    public OpportunityRepo() {
      super(Opportunity.SObjectType, new List<Schema.SObjectField>{ Opportunity.Name }, new RepoFactory());
    }
  }

  private class OpportunityContactRoleRepo extends Repository {
    public OpportunityContactRoleRepo() {
      super(
        OpportunityContactRole.SObjectType,
        new List<Schema.SObjectField>{ OpportunityContactRole.Role },
        new RepoFactory()
      );
    }
  }
}
