public class RepoFactoryMock extends RepoFactory {
    @testVisible
    private static List<SObject> QueryResults = new List<SObject>();
    @testVisible
    private static List<Query> QueriesMade = new List<Query>();

    //just as an example of what the override would look like
    public override IRepository getOppLineItemRepo() {
        List<SObject> queriedResults = this.getResults(OpportunityLineItem.SObjectType);
        return queriedResults.size() > 0 ?
            new RepoMock(queriedResults, this) :
            super.getOppLineItemRepo();
    }

    public override IDML getDML() {
        return new DMLMock();
    }

    private List<SObject> getResults(SObjectType sobjType) {
        List<SObject> resultList = new List<SObject>();
        for(SObject potentialResult : QueryResults) {
            if(potentialResult.getSObjectType() == sobjType) {
                resultList.add(potentialResult);
            }
        }
        return resultList;
    }

    private class RepoMock extends Repository {
        private final List<SObject> results;

        public RepoMock(List<SObject> results, RepoFactory factory) {
            super(factory);
            this.results = results;
        }

        public override List<SObject> getAll() {
          return this.results;
        }

        public override List<SObject> get(Query query) {
            return this.get(new List<Query>{ query });
        }

        public override List<SObject> get(List<Query> queries) {
            QueriesMade.addAll(queries);
            return this.results;
        }
    }
}