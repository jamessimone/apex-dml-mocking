public class AccountHandler extends TriggerHandler {
  private final IRepository oppRepo;

  public AccountHandler(Factory factory) {
    this.oppRepo = factory.RepoFactory.getOppRepo();
  }

  public override void afterInsert(List<SObject> insertedRecords, Map<Id, SObject> unused) {
    List<Account> insertedAccounts = (List<Account>) insertedRecords;
    this.createOppAutomatically(insertedAccounts);
  }

  private void createOppAutomatically(List<Account> insertedAccounts) {
    List<Opportunity> oppsToInsert = new List<Opportunity>();
    for (Account insertedAccount : insertedAccounts) {
      oppsToInsert.add(
        new Opportunity(
          Name = 'Prospecting Opp for: ' + insertedAccount.Name,
          AccountId = insertedAccount.Id,
          StageName = 'Open',
          CloseDate = Date.today()
        )
      );
    }
    this.oppRepo.doInsert(oppsToInsert);
  }
}
