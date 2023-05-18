public virtual class Factory {
  public final RepoFactory repoFactory = new RepoFactory();

  @TestVisible
  private static Factory factory;

  protected Factory() {
    // enforce getFactory() as the sole entry point for usage
  }

  public static Factory getFactory() {
    // production code can only initialize the factory through this method
    // but tests can provide an alternative factory implementation
    if (factory == null) {
      factory = new Factory();
    }

    return factory;
  }

  // create methods to initialize your objects here
  // (an example is included in the example-app folder)

  @TestVisible
  private Factory withMocks {
    // you can call "withMocks" after "getFactory" in tests to swap out
    // how repositories are created and DML is performed
    get {
      this.repoFactory.setFacade(new RepoFactoryMock.FacadeMock());
      return this;
    }
  }
}
