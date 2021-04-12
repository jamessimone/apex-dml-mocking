@isTest
private class RepositoryTests {
    @isTest
    static void it_should_take_in_a_query() {
        Query basicQuery = new Query(Opportunity.IsWon, Query.Operator.EQUALS, true);
        IRepository repo = Factory.getFactory().RepoFactory.getOppRepo();

        repo.get(basicQuery);
        System.assertEquals(1, Limits.getQueries());
    }

    @isTest
    static void it_should_handle_lists_and_sets_of_ids_or_strings() {
        Id accountId = TestingUtils.generateId(Account.SObjectType);
        Id secondAccountId = TestingUtils.generateId(Account.SObjectType);
        List<Id> ids = new List<Id>{ accountId, secondAccountId };
        Set<Id> setIds = new Set<Id>(ids);
        Set<String> oppNames = new Set<String>{ 'Open', 'Closed' };

        Query listQuery = new Query(Opportunity.Id, Query.Operator.EQUALS, ids);
        Query setQuery = new Query(Opportunity.Id, Query.Operator.EQUALS, setIds);
        Query setStringQuery = new Query(Opportunity.Name, Query.Operator.EQUALS, oppNames);

        IRepository repo = Factory.getFactory().RepoFactory.getOppRepo();

        repo.get(listQuery);
        repo.get(setQuery);
        repo.get(setStringQuery);
        System.assertEquals(3, Limits.getQueries());
        //we need to write a special assert for sets with multiple values
        System.assertEquals('Name in (\'Open\',\'Closed\')', setStringQuery.toString());
    }

    @isTest
    static void it_should_properly_short_circuit_when_empty_collections_passed_in() {
        Query listQuery = new Query(Opportunity.Id, Query.Operator.EQUALS, new List<Id>());

        IRepository repo = Factory.getFactory().RepoFactory.getOppRepo();

        List<SObject> opps = repo.get(listQuery);
        System.assertEquals(0, opps.size());
        System.assertEquals(0, Limits.getQueries());
    }

    @isTest
    static void it_should_decorate_dml_methods() {
        IRepository repo = Factory.getFactory().withMocks.RepoFactory.getOppRepo();
        Account acc = new Account();
        List<Account> accs = new List<Account>{ acc };

        repo.doInsert(acc);
        repo.doInsert(accs);
        System.assertEquals(acc, DMLMock.Inserted.Accounts.firstOrDefault);

        repo.doUpdate(acc);
        repo.doUpdate(accs);
        System.assertEquals(acc, DMLMock.Updated.Accounts.firstOrDefault);

        repo.doUpsert(acc);
        repo.doUpsert(accs);
        System.assertEquals(acc, DMLMock.Upserted.Accounts.firstOrDefault);

        repo.doDelete(acc);
        repo.doDelete(accs);
        System.assertEquals(acc, DMLMock.Deleted.Accounts.firstOrDefault);

        repo.doUndelete(acc);
        repo.doUndelete(accs);
        System.assertEquals(acc, DMLMock.Undeleted.Accounts.firstOrDefault);

        repo.doHardDelete(acc);
        repo.doHardDelete(accs);
        System.assertEquals(acc, DMLMock.Deleted.Accounts.firstOrDefault);
    }
}