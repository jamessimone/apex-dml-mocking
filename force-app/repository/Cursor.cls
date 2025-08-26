public virtual class Cursor {
  private final Database.Cursor cursor;

  public Cursor(Database.Cursor cursor) {
    this.cursor = cursor;
  }

  protected Cursor() {
  }

  public virtual List<SObject> fetch(Integer start, Integer advanceBy) {
    return this.cursor.fetch(start, advanceBy);
  }

  public virtual Integer getNumRecords() {
    return this.cursor.getNumRecords();
  }
}
