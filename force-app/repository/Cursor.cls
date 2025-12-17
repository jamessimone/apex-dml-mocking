public virtual without sharing class Cursor {
  @TestVisible
  private static Integer maxFetchSize = 2000;
  private static final Integer MAX_FETCHES_PER_TRANSACTION = Limits.getLimitFetchCallsOnApexCursor();
  @TestVisible
  private static Integer localFetchesMade;

  private Integer cursorNumRecords;
  private Integer fetchesPerTransaction = 1;
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

  public Cursor setFetchesPerTransaction(Integer possibleFetchesPerTransaction) {
    // Handle accidental round downs from Integer division
    if (possibleFetchesPerTransaction == 0) {
      return this;
    }
    if (possibleFetchesPerTransaction > MAX_FETCHES_PER_TRANSACTION) {
      System.debug(
        System.LoggingLevel.DEBUG,
        'Fetches per transaction: ' +
          possibleFetchesPerTransaction +
          ' exceeded platform max fetches per transaction: ' +
          MAX_FETCHES_PER_TRANSACTION +
          ', defaulting to platform max'
      );
      possibleFetchesPerTransaction = MAX_FETCHES_PER_TRANSACTION;
    }
    this.fetchesPerTransaction = possibleFetchesPerTransaction;
    return this;
  }

  protected Cursor() {
  }

  public virtual List<SObject> fetch(Integer start, Integer advanceBy) {
    if (this.getNumRecords() == 0) {
      System.debug(System.LoggingLevel.DEBUG, 'Bypassing fetch call, no records to fetch');
      return new List<SObject>();
    }
    localFetchesMade = localFetchesMade ?? 0;
    Integer localStart = start;
    List<SObject> results = new List<SObject>();
    while (
      localFetchesMade < this.fetchesPerTransaction &&
      results.size() < this.getNumRecords() &&
      localStart < start + advanceBy
    ) {
      Integer actualAdvanceBy = this.getAdvanceBy(localStart, advanceBy);
      results.addAll(this.cursor?.fetch(localStart, actualAdvanceBy) ?? new List<SObject>());
      localStart += actualAdvanceBy;
      localFetchesMade++;
    }
    return results;
  }

  public virtual Integer getNumRecords() {
    // cache the value for now, as changes made to Apex Cursors currently have calling getNumRecords()
    // consume a SOQL query each time
    this.cursorNumRecords = this.cursorNumRecords ?? this.cursor?.getNumRecords() ?? 0;
    return this.cursorNumRecords;
  }

  protected Integer getAdvanceBy(Integer start, Integer advanceBy) {
    Integer possibleFetchSize = Math.min(advanceBy, this.getNumRecords() - start);
    if (possibleFetchSize > maxFetchSize) {
      System.debug(
        System.LoggingLevel.DEBUG,
        'Fetch size: ' +
          possibleFetchSize +
          ' exceeded platform max fetch size of ' +
          maxFetchSize +
          ', defaulting to max fetch size'
      );
      possibleFetchSize = maxFetchSize;
    } else if (possibleFetchSize < 0) {
      possibleFetchSize = 0;
    }
    return possibleFetchSize;
  }
}
