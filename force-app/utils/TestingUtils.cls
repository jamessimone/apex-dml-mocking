@IsTest
public class TestingUtils {
  private static Integer startingNumber = 1;

  @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
  public static String generateId(Schema.SObjectType sObjectType) {
    String result = String.valueOf(startingNumber++);
    Schema.DescribeSObjectResult describe = sObjectType.getDescribe(Schema.SObjectDescribeOptions.DEFERRED);
    String keyPrefix = describe.getKeyPrefix();
    if (keyPrefix == null) {
      switch on describe.getAssociateEntityType() {
        when 'History' {
          keyPrefix = '017';
        }
        when 'Share' {
          keyPrefix = '02c';
        }
      }
    }
    return keyPrefix + '0'.repeat(12 - result.length()) + result;
  }

  public static SObject generateId(SObject objectInstance) {
    objectInstance.Id = objectInstance.Id ?? generateId(objectInstance.getSObjectType());
    return objectInstance;
  }

  public static void generateIds(List<SObject> records) {
    for (SObject record : records) {
      generateId(record);
    }
  }

  @IsTest
  static void generatesFakeHistoryIds() {
    Assert.isNotNull(generateId(LeadHistory.SObjectType));
  }

  @IsTest
  static void generatesFakeShareRecords() {
    Assert.isNotNull(generateId(LeadShare.SObjectType));
  }
}
