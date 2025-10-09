public without sharing class SObjectRepository extends FieldLevelHistoryRepo {
  public SObjectRepository(
    Schema.SObjectType repoType,
    List<Schema.SObjectField> queryFields,
    RepoFactory repoFactory
  ) {
    super(repoType, queryFields, repoFactory);
  }
}
