public class ServiceClass implements ServiceInterface{
    public ENUM ActionMethod {
        UPSERTCASE,
        GETDATA  
    }
    
    //public static List<String> validMethodNames = new List<String> {'UPSERTCASE', 'GETDATA'};
    
    //public static Map<String, String> validMethodNamesMap = new Map<String, String> { 'UPSERTCASE' => 'upsertCase', 'GETDATA' => 'getData'};
        
    public static Set<String> validMethodNamesSet = new Set<String> {'UPSERTCASE', 'GETDATA'};
    
	/*public Object execute(String actionMethodName, Object actionVariable) {
        Boolean isValidActionMethod = false;
        for(ActionMethod actionMethodValue : ActionMethod.values()){
            if(actionMethodValue.name().equals(actionMethodName.toUpperCase())){
                isValidActionMethod = true;
            }
        }
        if(isValidActionMethod){
            return invokeMethod(ActionMethod.valueOf(actionMethodName), actionVariable);
        }
        else{
            system.debug('Invalid Method Name');
        }
        return null;
    }
	public Object invokeMethod(ActionMethod actionMethodName, Object actionVariable) {
        system.debug('actionMethodName >> '+ actionMethodName);
        switch on actionMethodName {
            when UPSERTCASE {
                return upsertCase(actionVariable);
            }
            when GETDATA {
                return getData(actionVariable);
            }
            when else {
                system.debug('Method not found: ' + actionMethodName);
                return null;
            }
        }
    }*/
    

    public Object execute(String actionMethodName, Object actionVariable) {

        actionMethodName = actionMethodName.toUpperCase();

        /*if(!String.isEmpty(actionMethodName) && validMethodNames.contains(actionMethodName)){            
            return invokeMethod(actionMethodName, actionVariable);
        }*/
        
        /*if(!String.isEmpty(actionMethodName) && validMethodNamesMap.containsKey(actionMethodName)){
            return invokeMethod(actionMethodName, actionVariable);
        }*/
        if(!String.isEmpty(actionMethodName) && validMethodNamesSet.contains(actionMethodName)){            
            return invokeMethod(actionMethodName, actionVariable);
        }
        
        return null;
    }
    public Object invokeMethod(String actionMethodName, Object actionVariable) {
        system.debug('actionMethodName >> '+ actionMethodName);
        switch on actionMethodName {
            when 'UPSERTCASE' {
                return upsertCase(actionVariable);
            }
            when 'GETDATA' {
                return getData(actionVariable);
            }
            when else {
                system.debug('Method not found: ' + actionMethodName);
                return null;
            }
        }
    }
    
    private static Object upsertCase(Object actionVariable){        
        ServiceObject result = new ServiceObject();
        /*serviceClassWrapper wrpr = new serviceClassWrapper();
        List<Case> caseList = new List<Case>();
        
        if(actionVariable instanceof List<Object>){
            
            for (Object obj : (List<Object>) actionVariable) {
                if (obj instanceof Case) {
                    caseList.add((Case) obj);
                }
            }
            
            List<Id> successIdList = new List<Id>();
            List<Id> errorIdList = new List<Id>();
            
            //Database.UpsertResult[] results = Database.upsert(caseList);
            
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    System.debug('Successfully upserted record with ID: ' + results[i].getId());
                    successIdList.add(results[i].getId());
                } else {
                    Database.Error[] errors = results[i].getErrors();
                    for (Database.Error error : errors) {
                        System.debug('Failed to upsert record. Error: ' + error.getMessage());
                        errorIdList.add(results[i].getId());
                    }
                }
            }
            wrpr.successIdList = successIdList;
            wrpr.errorIdList = errorIdList;
            
            result.resultObject = wrpr;
        }*/
        return result;
    }
    private static Object getData(Object actionVariable){
        ServiceObject result = new ServiceObject();
        /*if(actionVariable instanceof String && (String)actionVariable != '' && (String)actionVariable != null){
            String searchQueryText = (String)actionVariable;
            List<Case> caseList = [Select Id from Case where caseNumber like: searchQueryText];            
            result.resultList = caseList;
        }*/
        return result;
    }
    public class serviceClassWrapper{
        List<Id> successIdList {get;set;}
        List<Id> errorIdList {get;set;}
        
        serviceClassWrapper(){
            successIdList = new List<Id>();
            errorIdList = new List<Id>();
        }
        
    }
}