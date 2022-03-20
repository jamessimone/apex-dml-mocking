public virtual class FieldLevelHistory {
  public Datetime CreatedDate { get; set; }
  public Id CreatedById { get; set; }
  public Object NewValue { get; set; }
  public Object OldValue { get; set; }
  public String Field { get; set; }

  public Id ParentId { get; private set; }

  public override String toString() {
    return JSON.serialize(this);
  }

  public void setValues(Map<String, Object> values) {
    this.CreatedById = (Id) values.get('CreatedById');
    Object possibleCreatedDate = values.get('CreatedDate');
    this.CreatedDate = Datetime.valueOfGmt(String.valueOf(possibleCreatedDate).replace('T', ' ').remove('"'));
    this.Field = (String) values.get('Field');
    this.NewValue = values.get('NewValue');
    this.OldValue = values.get('OldValue');
    this.setParentId(values);
  }

  protected virtual String getParentFieldName() {
    return 'ParentId';
  }

  private void setParentId(Map<String, Object> values) {
    this.ParentId = (Id) values.get(this.getParentFieldName());
  }
}