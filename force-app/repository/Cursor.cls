@SuppressWarnings('PMD.EmptyCatchBlock,PMD.EmptyStatementBlock')
public virtual without sharing class Cursor {
  private final Database.Cursor cursor;

  public Cursor(String finalQuery, Map<String, Object> bindVars, System.AccessLevel accessLevel) {
    try {
      this.cursor = Database.getCursorWithBinds(finalQuery, bindVars, accessLevel);
    } catch (FatalCursorException e) {
      // I recommend logging a warning for this using Nebula Logger in your own code
    }
  }

  protected Cursor() {
  }

  public virtual List<SObject> fetch(Integer start, Integer advanceBy) {
    return this.cursor?.fetch(start, advanceBy) ?? new List<SObject>();
  }

  public virtual Integer getNumRecords() {
    return this.cursor?.getNumRecords() ?? 0;
  }
}
