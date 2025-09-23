@SuppressWarnings('PMD.EmptyCatchBlock,PMD.EmptyStatementBlock')
public virtual without sharing class Cursor {
  private final Database.Cursor cursor;

  public Cursor(String finalQuery, Map<String, Object> bindVars, System.AccessLevel accessLevel) {
    try {
      this.cursor = Database.getCursorWithBinds(finalQuery, bindVars, accessLevel);
    } catch (FatalCursorException e) {
      System.debug(
        System.LoggingLevel.WARN,
        'Error creating cursor. This can happen if there are no records returned by the query: ' + e.getMessage()
      );
    }
  }

  protected Cursor() {
  }

  public virtual List<SObject> fetch(Integer start, Integer advanceBy) {
    if (this.getNumRecords() == 0) {
      System.debug(System.LoggingLevel.WARN, 'Bypassing fetch call, no records to fetch');
      return new List<SObject>();
    }
    return this.cursor?.fetch(start, this.getAdvanceBy(start, advanceBy)) ?? new List<SObject>();
  }

  public virtual Integer getNumRecords() {
    return this.cursor?.getNumRecords() ?? 0;
  }

  protected Integer getAdvanceBy(Integer start, Integer advanceBy) {
    return Math.min(advanceBy, this.getNumRecords() - start);
  }
}
