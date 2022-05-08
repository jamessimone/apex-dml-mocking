public virtual class RepoFactory {
  public virtual IAggregateRepository getOppRepo() {
    List<Schema.SObjectField> queryFields = new List<Schema.SObjectField>{
      Opportunity.IsWon,
      Opportunity.StageName
      // etc ...
    };
    IAggregateRepository oppRepo = new FieldLevelHistoryRepo(Opportunity.SObjectType, queryFields, this);
    oppRepo.addParentFields(
      new List<Schema.SObjectField>{ Opportunity.AccountId },
      new List<Schema.SObjectField>{ Opportunity.Account.Id }
    );
    return oppRepo;
  }

  public virtual IAggregateRepository getAccountRepo() {
    IAggregateRepository accountRepo = new FieldLevelHistoryRepo(
      Account.SObjectType,
      new List<Schema.SObjectField>{ Account.Name },
      this
    );
    accountRepo.addChildFields(Contact.AccountId, new List<Schema.SObjectField>{ Contact.LastName });
    return accountRepo;
  }

  public virtual IHistoryRepository getOppLineItemRepo() {
    List<Schema.SObjectField> queryFields = new List<Schema.SObjectField>{
      OpportunityLineItem.Description,
      OpportunityLineItem.OpportunityId
      // etc
    };
    return new FieldLevelHistoryRepo(OpportunityLineItem.SObjectType, queryFields, this);
  }

  public virtual IHistoryRepository getProfileRepo() {
    List<Schema.SObjectField> queryFields = new List<Schema.SObjectField>{ Profile.Name };
    return new FieldLevelHistoryRepo(Profile.SObjectType, queryFields, this);
  }

  public virtual IDML getDML() {
    return new DML();
  }
}
