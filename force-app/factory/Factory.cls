public virtual class Factory {
    //this is only "protected set" to show-case how your own
    //Factory might function in the example app. Make this a private set
    //in your own code!
    public RepoFactory RepoFactory { get; protected set;}

    @testVisible
    private static Factory factory;

    protected Factory() {
        this.RepoFactory = new RepoFactory();
    }

    public static Factory getFactory() {
        //production code can only initialize the factory through this method
        if(factory == null) {
            factory = new Factory();
        }

        return factory;
    }

    //create methods to initialize your objects here
    //(an example is included in the example app)

    @testVisible
    private Factory withMocks {
        get {
            this.RepoFactory = new RepoFactoryMock();
            return this;
        }
    }
}