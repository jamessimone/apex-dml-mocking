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
}
