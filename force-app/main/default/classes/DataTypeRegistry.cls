public class DataTypeRegistry {
    public static List<String> types = new List<String>{
        'Integer',
        'String',
        'Boolean',
        'List<Object>',
        'Set<Object>',
        'Map<Object, Object>',
        'List<SObject>'
    };
    public static Boolean isTypeInList(Object variable) {
        for (String typeName : DataTypeRegistry.types) {
            
            if (typeName == 'Integer' && variable instanceof Integer) {
                return true;
            } else if (typeName == 'String' && variable instanceof String) {
                return true;
            } else if (typeName == 'Boolean' && variable instanceof Boolean) {
                return true;
            } else if (typeName == 'List<Object>' && variable instanceof List<Object>) {
                return true;
            } else if (typeName == 'Set<Object>' && variable instanceof Set<Object>) {
                return true;
            } /*else if (typeName == 'Map<Object, Object>' && variable instanceof Map<Object, Object>) {
                system.debug('Instance check :::: Map<Object, Object>');
                return true;
            }*/
        }
        return false;
    }
}