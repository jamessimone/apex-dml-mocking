@IsTest
private class CursorTest {
  @IsTest
  static void itCapsAdvanceByArgument() {
    String accountName = 'helloWorld!';
    insert new Account(Name = accountName);
    String query = 'SELECT Name FROM Account WHERE Name = :bindVar0';
    Map<String, Object> bindVars = new Map<String, Object>{ 'bindVar0' => accountName };

    Cursor instance = new Cursor(query, bindVars, System.AccessLevel.SYSTEM_MODE);

    Assert.areEqual(1, instance.getNumRecords());
    Assert.areEqual(accountName, instance.fetch(0, 1000).get(0).get('Name'));
    Assert.areEqual(1, System.Limits.getApexCursorRows());
  }

  @IsTest
  static void itCapsMaxFetchSize() {
    Cursor.maxFetchSize = 20;
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < Cursor.maxFetchSize + 1; i++) {
      accounts.add(new Account(Name = 'Fetch ' + i));
    }
    insert accounts;

    Integer oneMoreThanMaxFetch = Cursor.maxFetchSize + 1;
    Exception ex;
    List<SObject> results;
    Cursor instance = new Cursor('SELECT Id FROM Account', new Map<String, Object>(), System.AccessLevel.SYSTEM_MODE);
    try {
      results = instance.fetch(0, oneMoreThanMaxFetch);
    } catch (System.InvalidParameterValueException e) {
      ex = e;
    }

    Assert.areEqual(null, ex?.getMessage());
    Assert.areEqual(Cursor.maxFetchSize, results.size());
    Assert.areEqual(1, Cursor.localFetchesMade);
  }

  @IsTest
  static void itFetchesMultipleTimesPerTransactionWhenMoreThanMaxFetch() {
    Cursor.maxFetchSize = 20;
    List<Account> accounts = new List<Account>();
    Set<String> expectedFetchNames = new Set<String>();
    for (Integer i = 0; i < Cursor.maxFetchSize + 1; i++) {
      String accountName = 'Fetch' + i;
      expectedFetchNames.add(accountName);
      accounts.add(new Account(Name = accountName));
    }
    insert accounts;

    Integer oneMoreThanMaxFetch = Cursor.maxFetchSize + 1;
    Cursor instance = new Cursor('SELECT Name FROM Account', new Map<String, Object>(), System.AccessLevel.SYSTEM_MODE);
    List<SObject> results = instance.setFetchesPerTransaction(2).fetch(0, oneMoreThanMaxFetch);

    Assert.areEqual(Cursor.maxFetchSize + 1, results.size());
    Assert.areEqual(2, Cursor.localFetchesMade);
    Set<String> actuallyFetchedNames = new Set<String>();
    for (Account account : (List<Account>) results) {
      actuallyFetchedNames.add(account.Name);
    }
    Assert.areEqual(expectedFetchNames, actuallyFetchedNames);
  }

  @IsTest
  static void itFetchesMultipleTimesPerTransaction() {
    Cursor.maxFetchSize = 1;
    insert new List<Account>{ new Account(Name = 'One'), new Account(Name = 'Two') };

    Cursor instance = new Cursor('SELECT Id FROM Account', new Map<String, Object>(), System.AccessLevel.SYSTEM_MODE)
      .setFetchesPerTransaction(2);
    List<SObject> results = instance.fetch(0, 2);

    Assert.areEqual(2, instance.getNumRecords());
    Assert.areEqual(2, results.size());
    results = instance.fetch(2, 1);
    Assert.areEqual(0, results.size());
  }

  @IsTest
  static void fetchesCorrectAmountOfRecords() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 10; i++) {
      accounts.add(new Account(Name = 'Fetch ' + i));
    }
    insert accounts;

    Cursor instance = new Cursor('SELECT Id FROM Account', new Map<String, Object>(), System.AccessLevel.SYSTEM_MODE)
      .setFetchesPerTransaction(10);
    List<SObject> results = instance.fetch(0, 2);

    Assert.areEqual(2, results.size(), '' + results);
    Assert.areEqual(1, Cursor.localFetchesMade);
  }
}
