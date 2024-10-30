public class ServiceDispatcher {
    @AuraEnabled
    public static Object invokeAction(String actionName, String actionMethodName, Object actionVariable ){
        if(isValidVariable(actionVariable)){
            Type classType = Type.forName(actionName);
            if (isValueNotNull(classType)) {
                Object instance = classType.newInstance();
                if (instance instanceof ServiceInterface) {
                    ServiceInterface serviceInstance = (ServiceInterface) instance;                    
                    return serviceInstance.execute(actionMethodName, actionVariable);
                }
                else{
                    system.debug('The given class name does not exist: ');
                }
            }
            else{
                system.debug('Class not found: ');
            }
        }
        else{
            system.debug('Invalid variable(s) passed');
        }
        return null;
    }
    public static Boolean isValidVariable(Object actionVariable){
        Boolean isvalid = false;
        if(isValueNotNull(actionVariable)){
            isvalid = DataTypeRegistry.isTypeInList(actionVariable);
        }
        else{
            // throw exception
            system.debug('Invalid variable(s) passed');
        }
        return isvalid;        
    }
    
    public static Boolean isValueNotNull(Object value){
        if(value == null){
            return false;
        }
        else{
            // throw exception
            return true;
        }
    }
}