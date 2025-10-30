@IsTest
private class LazyFactoryTest {
  @IsTest
  static void properlyCachesLazyLoadedInstances() {
    ExtendedLazyFactory extendedExampleFactory = new ExtendedLazyFactory();

    Example firstExample = (Example) extendedExampleFactory.example;
    Example secondExample = (Example) extendedExampleFactory.example;

    Assert.areEqual(1, loadCounter);
    // prove that even without overriding "equals" and a setter for the
    // ExtendedLazyFactory that the instances returned are the same
    Assert.areEqual(firstExample, secondExample);
  }

  private class ExtendedLazyFactory extends LazyFactory {
    public Instance example {
      get {
        return this.load(Example.class);
      }
    }
  }

  private static Integer loadCounter = 0;
  private class Example implements LazyFactory.Instance {
    public Example() {
      loadCounter++;
    }
  }
}
