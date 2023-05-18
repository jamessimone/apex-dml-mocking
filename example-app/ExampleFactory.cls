public virtual class ExampleFactory extends Factory {
  public final ExampleRepoFactory repoFactory = new ExampleRepoFactory();

  @TestVisible
  private static ExampleFactory factory;

  protected ExampleFactory() {
    // enforce getFactory() as the sole way to interact with this class
  }

  public static ExampleFactory getFactory() {
    if (factory == null) {
      factory = new ExampleFactory();
    }
    return factory;
  }

  public virtual TriggerHandler getAccountHandler() {
    return new AccountHandler(this);
  }

  @TestVisible
  private ExampleFactory withMocks {
    get {
      this.repoFactory.setFacade(new RepoFactoryMock.FacadeMock());
      return this;
    }
  }
}
