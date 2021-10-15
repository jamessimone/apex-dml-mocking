public virtual class RepoFactory {
  // if you don't have need of aggregate queries, for a specific object
  // you can either return IRepository, or assign IRepository as the type
  // for a variable further downstream
  public virtual IRepository getOppRepo() {
    List<SObjectField> queryFields = new List<SObjectField>{
      Opportunity.IsWon,
      Opportunity.StageName
      // etc ...
    };
    return new AggregateRepository(Opportunity.SObjectType, queryFields, this);
  }

  public virtual IAggregateRepository getOppLineItemRepo() {
    List<SObjectField> queryFields = new List<SObjectField>{
      OpportunityLineItem.Description,
      OpportunityLineItem.OpportunityId
      // etc
    };
    return new AggregateRepository(OpportunityLineItem.SObjectType, queryFields, this);
  }

  public virtual IDML getDML() {
    return new DML();
  }
}
