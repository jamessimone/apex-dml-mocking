trigger AccountTrigger on Account (after insert) {
    ExampleFactory.getFactory().getAccountHandler().execute();
}