public class AccountHandler extends TriggerHandler {
  private final IRepository oppRepo;

  public AccountHandler(Factory factory) {
    this.oppRepo = factory.RepoFactory.getOppRepo();
  }

  public override void beforeInsert(List<SObject> insertedRecords) {
    List<Account> insertedAccounts = (List<Account>) insertedRecords;
    this.createOppAutomatically(insertedAccounts);
  }

  private void createOppAutomatically(List<Account> insertedAccounts) {
    List<Opportunity> oppsToInsert = new List<Opportunity>();
    for (Account insertedAccount : insertedAccounts) {
      oppsToInsert.add(
        new Opportunity(Name = 'Prospecting Opp for: ' + insertedAccount.Name, AccountId = insertedAccount.Id)
      );
    }
    this.oppRepo.doInsert(oppsToInsert);
  }
}
