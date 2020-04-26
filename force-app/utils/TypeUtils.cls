public abstract class TypeUtils {
    public static List<SObject> createSObjectList(SObject record) {
        String listType = 'List<' + record.getSObjectType() + '>';
        List<SObject> records = (List<SObject>) create(listType);
        records.add(record);
        return records;
    }

    public static Object create(String objectName) {
        return Type.forName(objectName).newInstance();
    }
}