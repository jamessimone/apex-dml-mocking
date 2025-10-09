@IsTest
private class CursorTest {
  @IsTest
  static void itCapsAdvanceByArgument() {
    String query = 'SELECT Id FROM User WHERE Id = :bindVar0';
    Map<String, Object> bindVars = new Map<String, Object>{ 'bindVar0' => UserInfo.getUserId() };

    Cursor cursor = new Cursor(query, bindVars, System.AccessLevel.SYSTEM_MODE);

    Assert.areEqual(1, cursor.getNumRecords());
    Assert.areEqual(UserInfo.getUserId(), cursor.fetch(0, 1000).get(0).Id);
    Assert.areEqual(1, System.Limits.getApexCursorRows());
  }

  @IsTest
  static void itCapsMaxFetchSize() {
    List<Account> accounts = new List<Account>();
    for (Integer i = 0; i < 2001; i++) {
      accounts.add(new Account(Name = 'Fetch ' + i));
    }
    insert accounts;

    Integer oneMoreThanMaxFetch = 2001;
    Exception ex;
    try {
      new Cursor('SELECT Id FROM Account', new Map<String, Object>(), System.AccessLevel.SYSTEM_MODE)
        .fetch(0, oneMoreThanMaxFetch);
    } catch (System.InvalidParameterValueException e) {
      ex = e;
    }

    Assert.areEqual(null, ex?.getMessage());
  }

  @IsTest
  static void itFetchesMultipleTimesPerTransaction() {
    insert new List<Account>{ new Account(Name = 'One'), new Account(Name = 'Two') };

    Cursor cursor = new Cursor('SELECT Id FROM Account', new Map<String, Object>(), System.AccessLevel.SYSTEM_MODE)
      .setFetchesPerTransaction(2);
    List<SObject> results = cursor.fetch(0, 1);

    Assert.areEqual(2, results.size());
    results = cursor.fetch(2, 1);
    Assert.areEqual(0, results.size());
    Assert.areEqual(2, cursor.getNumRecords());
  }
}
