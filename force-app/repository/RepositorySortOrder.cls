public class RepositorySortOrder {
  private final SortOrder sortOrder;
  private NullSortOrder nullSortOrder;

  public enum SortOrder {
    ASCENDING,
    DESCENDING
  }

  public enum NullSortOrder {
    FIRST,
    LAST
  }

  public static final RepositorySortOrder ASCENDING {
    get {
      if (ASCENDING == null) {
        ASCENDING = new RepositorySortOrder(SortOrder.ASCENDING);
      }
      return ASCENDING;
    }
    set;
  }

  public static final RepositorySortOrder DESCENDING {
    get {
      if (DESCENDING == null) {
        DESCENDING = new RepositorySortOrder(SortOrder.DESCENDING);
      }
      return DESCENDING;
    }
    set;
  }

  public RepositorySortOrder(SortOrder sortOrder) {
    this(sortOrder, null);
  }

  public RepositorySortOrder(SortOrder sortOrder, NullSortOrder nullSortOrder) {
    this.sortOrder = sortOrder;
    this.nullSortOrder = nullSortOrder;
  }

  public override String toString() {
    String base = this.sortOrder == RepositorySortOrder.SortOrder.ASCENDING ? 'ASC' : 'DESC';
    if (this.nullSortOrder != null) {
      base += ' ' + 'NULLS ' + this.nullSortOrder.name();
    }
    return base;
  }

  public Boolean equals(Object thatObj) {
    if (thatObj instanceof RepositorySortOrder) {
      RepositorySortOrder that = (RepositorySortOrder) thatObj;
      return this.nullSortOrder == that.nullSortOrder && this.sortOrder == that.sortOrder;
    }
    return false;
  }
}
