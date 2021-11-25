trigger AccountTrigger on Account (before insert, after insert) {
    ExampleFactory.getFactory().getAccountHandler().execute();
}