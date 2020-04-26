public class Query {
    public enum Operator {
        EQUALS,
        NOT_EQUALS,
        LESS_THAN,
        LESS_THAN_OR_EQUAL,
        GREATER_THAN,
        GREATER_THAN_OR_EQUAL
    }

    private final SObjectField field;
    private final Operator operator;
    private final List<Object> predicates;

    private static Boolean isSet = false;
    private static final String EMPTY = '\'\'';

    public Query(SObjectField field, Operator operator, Object predicate) {
        this(field, operator, new List<Object>{ predicate });
    }

    public Query(SObjectField field, Operator operator, List<Object> predicates) {
        this.field = field;
        this.operator = operator;
        this.predicates = predicates;
    }

    public override String toString() {
        String fieldName = this.field.getDescribe().getName();
        String predName = this.getPredicate(this.predicates);
        return fieldName + ' ' + this.getOperator() + ' ' + predName;
    }

    public Boolean isEmpty() {
        return this.getPredicate(this.predicates) == EMPTY;
    }

    public Boolean equals(Object thatObject) {
        if(thatObject instanceof Query) {
            Query that = (Query) thatObject;
            return this.toString() == that.toString();
        }

        return false;
    }

    private String getOperator() {
        Boolean isList = this.predicates.size() > 1;
        switch on this.operator {
            when EQUALS {
                return isList || isSet ? 'in' : '=';
            }
            when NOT_EQUALS {
                return isList || isSet ? 'not in' : '!=';
            }
            when LESS_THAN {
                return '<';
            }
            when LESS_THAN_OR_EQUAL {
                return '<=';
            }
            when GREATER_THAN {
                return '>';
            }
            when GREATER_THAN_OR_EQUAL {
                return '>=';
            }
            when else {
                return null;
            }
        }
    }

    private String getPredicate(Object predicate) {
        if(predicate == null) {
            return 'null';
        } else if(predicate instanceof Datetime) {
            //the most annoying one
            Datetime dt = (Datetime) predicate;
            return dt.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
        } else if(predicate instanceof List<Object>) {
            List<Object> predicates = (List<Object>) predicate;
            if(predicates.isEmpty()) {
                return EMPTY;
            }
            List<String> innerStrings = new List<String>();
            for(Object innerPred : predicates) {
                //recurse for string value
                String innerString = this.getPredicate(innerPred);
                innerStrings.add(innerString);
            }
            String start = innerStrings.size() > 1 ? '(' : '';
            String ending = innerStrings.size() > 1 ? ')' : '';
            return start + String.join(innerStrings, ',') + ending;
        } else if(predicate instanceof String) {
            String input = (String) predicate;
            return '\'' + String.escapeSingleQuotes(input) + '\'';
        }

        String predValue = String.valueOf(predicate);
        //fun fact - you can detect a list
        //but you can't detect a set!
        if(predValue.startsWith('{') && predValue.endsWith('}')) {
            List<String> setInner = predValue.substring(1, predValue.length() -1).split(',');
            isSet = setInner.size() > 1;
            return this.getPredicate(setInner);
        }
        return predValue;
    }
}