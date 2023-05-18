public virtual class RepoFactory {
  private static final Map<Schema.SObjectType, IHistoryRepository> CACHED_REPOS = new Map<Schema.SObjectType, IHistoryRepository>();

  public Facade facade {
    get {
      if (this.facade == null) {
        this.facade = new Facade();
      }
      return this.facade;
    }
    protected set;
  }

  public IAggregateRepository getOppRepo() {
    List<Schema.SObjectField> queryFields = new List<Schema.SObjectField>{
      Opportunity.IsWon,
      Opportunity.StageName
      // etc ...
    };
    IAggregateRepository oppRepo = this.facade.getRepo(Opportunity.SObjectType, queryFields, this);
    oppRepo.addParentFields(
      new List<Schema.SObjectField>{ Opportunity.AccountId },
      new List<Schema.SObjectField>{ Account.Id }
    );
    return oppRepo;
  }

  public IAggregateRepository getAccountRepo() {
    IAggregateRepository accountRepo = this.facade.getRepo(
      Account.SObjectType,
      new List<Schema.SObjectField>{ Account.Name },
      this
    );
    accountRepo.addChildFields(Contact.AccountId, new List<Schema.SObjectField>{ Contact.LastName });
    return accountRepo;
  }

  public IHistoryRepository getOppLineItemRepo() {
    List<Schema.SObjectField> queryFields = new List<Schema.SObjectField>{
      OpportunityLineItem.Description,
      OpportunityLineItem.OpportunityId
      // etc
    };
    return this.facade.getRepo(OpportunityLineItem.SObjectType, queryFields, this);
  }

  public IHistoryRepository getProfileRepo() {
    return this.facade.getRepo(Profile.SObjectType, new List<Schema.SObjectField>{ Profile.Name }, this);
  }

  public IDML getDML() {
    return this.facade.getDML();
  }

  public RepoFactory setFacade(Facade mockFacade) {
    if (Test.isRunningTest() == false) {
      throw new IllegalArgumentException('Should not call this outside of tests');
    }
    this.facade = mockFacade;
    return this;
  }

  public virtual class Facade {
    public virtual IDML getDML() {
      return new DML();
    }

    public virtual IHistoryRepository getRepo(
      Schema.SObjectType repoType,
      List<Schema.SObjectField> queryFields,
      RepoFactory repoFactory
    ) {
      IHistoryRepository potentiallyCachedInstance = CACHED_REPOS.get(repoType);
      if (potentiallyCachedInstance == null) {
        potentiallyCachedInstance = new FieldLevelHistoryRepo(repoType, queryFields, repoFactory);
        CACHED_REPOS.put(repoType, potentiallyCachedInstance);
      }
      return potentiallyCachedInstance;
    }
  }
}
