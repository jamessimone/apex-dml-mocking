public without sharing class ExampleRepoFactory extends RepoFactory {
  // your app can expand on the repositories provided by the base instance here, like so

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

  public IHistoryRepository getOppFieldHistoryRepo() {
    return this.facade.getRepo(OpportunityFieldHistory.SObjectType, new List<Schema.SObjectField>(), this)
      .setParentField(OpportunityFieldHistory.OpportunityId);
  }
}
