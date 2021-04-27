public abstract class TestingUtils {
  private static Integer startingNumber = 1;

  public static String generateId(Schema.SObjectType sObjectType) {
    String result = String.valueOf(startingNumber++);
    return sObjectType.getDescribe().getKeyPrefix() + '0'.repeat(12 - result.length()) + result;
  }

  public static SObject generateId(SObject objectInstance) {
    if (objectInstance.Id == null) {
      objectInstance.Id = generateId(objectInstance.getSObjectType());
    }
    return objectInstance;
  }

  public static void generateIds(List<SObject> records) {
    for (SObject record : records) {
      if (record.Id == null) {
        generateId(record);
      }
    }
  }
}
