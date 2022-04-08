public virtual class RepoFactory {
  public virtual IAggregateRepository getOppRepo() {
    List<SObjectField> queryFields = new List<SObjectField>{
      Opportunity.IsWon,
      Opportunity.StageName
      // etc ...
    };
    IAggregateRepository oppRepo = new FieldLevelHistoryRepo(Opportunity.SObjectType, queryFields, this);
    oppRepo.addParentFields(
      new List<SObjectType>{ Account.SObjectType },
      new List<SObjectField>{ Opportunity.Account.Id }
    );
    return oppRepo;
  }

  public virtual IAggregateRepository getAccountRepo() {
    IAggregateRepository accountRepo = new FieldLevelHistoryRepo(
      Account.SObjectType,
      new List<SObjectField>{ Account.Name },
      this
    );
    accountRepo.addChildFields(Contact.SObjectType, new List<SObjectField>{ Contact.LastName });
    return accountRepo;
  }

  public virtual IHistoryRepository getOppLineItemRepo() {
    List<SObjectField> queryFields = new List<SObjectField>{
      OpportunityLineItem.Description,
      OpportunityLineItem.OpportunityId
      // etc
    };
    return new FieldLevelHistoryRepo(OpportunityLineItem.SObjectType, queryFields, this);
  }

  public virtual IHistoryRepository getProfileRepo() {
    List<SObjectField> queryFields = new List<SObjectField>{ Profile.Name };
    return new FieldLevelHistoryRepo(Profile.SObjectType, queryFields, this);
  }

  public virtual IDML getDML() {
    return new DML();
  }
}
