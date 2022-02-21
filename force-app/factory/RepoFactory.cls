public virtual class RepoFactory {
  public virtual IAggregateRepository getOppRepo() {
    List<SObjectField> queryFields = new List<SObjectField>{
      Opportunity.IsWon,
      Opportunity.StageName
      // etc ...
    };
    IAggregateRepository oppRepo = new AggregateRepository(Opportunity.SObjectType, queryFields, this);
    oppRepo.addParentFields(new List<SObjectType>{ Account.SObjectType }, new List<SObjectField>{ Opportunity.Account.Id });
    return oppRepo;
  }

  public virtual IAggregateRepository getAccountRepo() {
    IAggregateRepository accountRepo = new AggregateRepository(Account.SObjectType, new List<SObjectField>{ Account.Name }, this);
    accountRepo.addChildFields(Contact.SObjectType, new List<SObjectField>{ Contact.LastName });
    return accountRepo;
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
