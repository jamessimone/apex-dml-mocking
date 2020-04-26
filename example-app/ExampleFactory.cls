public class ExampleFactory extends Factory {

    //normally you would not be "overriding" the static method
    //on the base factory; in your own code, you would be putting your
    //dependencies IN the actual factory class itself.
    //however, since this is an example app, to avoid over-writing the
    //existing Factory instance, this little evil is necessary to show off
    //the AccountHandler tests
    public static ExampleFactory getFactory() {
        return new ExampleFactory();
    }

    public virtual TriggerHandler getAccountHandler() {
      return new AccountHandler(this);
    }

    @testVisible
    private ExampleFactory withMocks {
        get {
            this.RepoFactory = new RepoFactoryMock();
            return this;
        }
    }
}