public without sharing class ExampleRepoFactory extends RepoFactory {
  // your app can expand on the repositories provided by the base instance here, like so

  public IHistoryRepository getOppFieldHistoryRepo() {
    return this.facade.getRepo(OpportunityFieldHistory.SObjectType, new List<Schema.SObjectField>(), this)
      .setParentField(OpportunityFieldHistory.OpportunityId);
  }
}
