public virtual class RepoFactory {
  private static final Map<Schema.SObjectType, IHistoryRepository> CACHED_REPOS = new Map<Schema.SObjectType, IHistoryRepository>();
  private Boolean shouldPrintBindVars = false;

  public Facade facade {
    get {
      if (this.facade == null) {
        this.facade = new Facade();
      }
      return this.facade;
    }
    protected set;
  }

  public RepoFactory setShouldPrintBindVars(Boolean shouldPrintBindVars) {
    this.shouldPrintBindVars = shouldPrintBindVars;
    return this;
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
        System.debug(System.LoggingLevel.FINER, 'Instantiating new repository of type: ' + repoType);
      } else {
        System.debug(System.LoggingLevel.FINER, 'Using cached repository of type: ' + repoType);
      }
      potentiallyCachedInstance.setShouldPrintBindVars(repoFactory.shouldPrintBindVars);
      return potentiallyCachedInstance;
    }
  }
}
