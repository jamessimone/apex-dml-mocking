private class OpportunityFieldHistoryExample extends FieldLevelHistory {
  protected override String getParentFieldName() {
      return OpportunityFieldHistory.OpportunityId.getDescribe().getName();
  }
}

if ([SELECT COUNT() FROM OpportunityFieldHistory] == 0) {
  List<Opportunity> opps = [SELECT Id, Name FROM Opportunity LIMIT 1];
  if (opps.isEmpty()) {
    Opportunity newOpp = new Opportunity(StageName = 'History', Name = 'History Field Tracking Integration Test', CloseDate = System.today(), Amount = 5);
    insert newOpp;
    opps.add(newOpp);
  }

  Opportunity opp = opps[0];
  opp.Name = 'Something New';
  update opp;
} else {
  System.debug('Histories already exist, continuing ...');
}

Exception ex;
List<FieldLevelHistory> histories;
try {
  histories = new FieldLevelHistoryRepo(
    OpportunityFieldHistory.OpportunityId,
    OpportunityFieldHistory.SObjectType,
    OpportunityFieldHistoryExample.class,
    new RepoFactory()
  ).getAllHistory();
  System.debug(histories);
} catch (Exception e) {
  ex = e;
}

if (histories.isEmpty()) {
  ex = new IllegalArgumentException('History record(s) were not retrieved correctly!');
}
if (ex == null) {
  System.debug('Finished successfully!');
} else {
  throw ex;
}

