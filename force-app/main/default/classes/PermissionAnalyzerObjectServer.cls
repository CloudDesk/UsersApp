//This Class is Used to Handle object and Field Permissions
// Used In PermissionAnalyzerObject _LWC
Public without Sharing Class PermissionAnalyzerObjectServer {    
    Public Class GetFieldWrapper {
        @AuraEnabled
        Public List<Map<String, Object>> fieldLabelMap { get; set; }
        @AuraEnabled
        Public Boolean hasObjAccess { get; set; }      
        @AuraEnabled
        Public Map<String, Boolean> hasFieldAccess { get; set; }
        @AuraEnabled
        Public List<Object> dependentObj { get; set; }
        
        Public GetFieldWrapper(
            List<Map<String, Object>> fieldLabelMap,Boolean hasObjAccess,Map<String, Boolean> hasFieldAccess,List<Object> dependentObj) {
                this.fieldLabelMap = fieldLabelMap;
                this.hasObjAccess = hasObjAccess;      
                this.hasFieldAccess = hasFieldAccess;
                this.dependentObj = dependentObj;
            }
    }
    //This Method Used to retrieve fieldDefinition, valid Sobjects for Obj Permissions, Valid field for field Permissions and also fetch Object Permissons Dependencies
    @AuraEnabled
    Public Static GetFieldWrapper getFieldsAndObjectRelatedDetails(String sObjectNameList,String permissionSetIdToFetchName) {
        List<Map<string, Object>> fieldLabelMap = PermissionTabServer.getFieldDefinition(sObjectNameList);
        return new GetFieldWrapper(fieldLabelMap,checkSobjectFoundInPicklist(sObjectNameList),
                                   checkFieldFoundInPicklist(sObjectNameList),checkObjectPermissionDependencies(sObjectNameList));
    }
    //Helper to get the valid Sobject for updating ObjectPermissions.
    @AuraEnabled
    Public Static Boolean checkSobjectFoundInPicklist(string sObjName) {
        for (Schema.PicklistEntry p : objectPermissions.SObjectType.getDescribe().getPicklistValues()) {
            if (sObjName == p.getValue()) {
                return true;
            }
        }
        return false;
    }
    //Helper to get the valid fields for updating ObjectPermissions.
    @AuraEnabled
    Public Static Map<String, Boolean> checkFieldFoundInPicklist(String sObjName) {
        Map<String, Boolean> fieldMap = new Map<String, Boolean>();
        for (Schema.PicklistEntry p : fieldPermissions.Field.getDescribe().getPicklistValues()) {
            if (sObjName == p.getValue().split('\\.')[0]) {
                fieldMap.put(p.getValue(), true);
            }
        }
        return fieldMap;
    }
    //Helper to get the ObjectPermission Dependencies 
    @AuraEnabled
    Public Static List<Object> checkObjectPermissionDependencies(String objName) {
        UserAccessManager instance = new UserAccessManager();
        List<Object> allDependencies = new List<Object>();
        // Fetch dependencies for the given object
        fetchDependencies(objName,allDependencies,instance.partnerConnection.SessionHeader.sessionId,System.Url.getOrgDomainUrl().toExternalForm());
        Set<String> sObjectNameSet = new Set<String>();
        for (Object record : allDependencies) {
            Map<String, Object> recordMap = (Map<String, Object>) record;
            addObjectNameToSet(sObjectNameSet, (String) recordMap.get('Permission'));
            addObjectNameToSet(sObjectNameSet, (String) recordMap.get('RequiredPermission'));
        }        
        // Filter allDependencies based on the query result
        Set<String> matchingObjNamesSet = new Set<String>();
        for (FieldDefinition fieldDef : [SELECT EntityDefinition.QualifiedApiName
                                         FROM FieldDefinition WHERE IsPolymorphicForeignKey = TRUE AND EntityDefinition.QualifiedApiName IN: sObjectNameSet
                                         Limit 50000]) {
                                             matchingObjNamesSet.add(fieldDef.EntityDefinition.QualifiedApiName);
                                         }
        // Remove matching records from allDependencies
        List<Object> filteredDependencies = new List<Object>();
        for (Object record : allDependencies) {
            Map<String, Object> recordMap = (Map<String, Object>) record;
            if (!isMatchingObject(matchingObjNamesSet, (String) recordMap.get('Permission')) &&
                !isMatchingObject(matchingObjNamesSet, (String) recordMap.get('RequiredPermission'))) {
                    filteredDependencies.add(record);
                }
        }
        System.debug('Filtered Dependencies: ' + filteredDependencies);
        System.debug('filteredDependencies'+ filteredDependencies.size());
        return filteredDependencies;        
    }
    private static void addObjectNameToSet(Set < String > sObjectNameSet, String permission) {
        if (permission != null) {
            sObjectNameSet.add(permission.split('<')[0]);
        }
    }
    private static boolean isMatchingObject(Set < String > matchingObjNamesSet, String permission) {
        return permission != null && matchingObjNamesSet.contains(permission.split('<')[0]);
    }
    @TestVisible
    private static void fetchDependencies(String objName, List < Object > allDependencies, String sessionId, String serverUrl) {
        System.debug('Inside fetchDependencies');
        
        if (String.isBlank(objName)) {
            return;
        }
        String query = 'SELECT Id, Permission, RequiredPermission FROM PermissionDependency ' +
            'WHERE (Permission LIKE \'%' + String.escapeSingleQuotes(objName) + '%\' ' +
            'OR RequiredPermission LIKE \'%' + String.escapeSingleQuotes(objName) + '%\') ' +
            'AND PermissionType = \'Object Permission\' ' +
            'AND RequiredPermissionType = \'Object Permission\'';
        
        System.debug('fetch query: ' + query);
        List < Object > queryResults = sendQueryRequest(query, sessionId, serverUrl);
        Set < String > parentObjects = new Set < String > ();
        Set < String > childObjects = new Set < String > ();
        for (Object record: queryResults) {
            Map < String, Object > recordMap = (Map < String, Object > ) record;
            allDependencies.add(record);
            String permission = (String) recordMap.get('Permission');
            String requiredPermission = (String) recordMap.get('RequiredPermission');
            
            if (permission != null && permission.contains(objName)) {
                parentObjects.add('\'' + requiredPermission + '\'');
            }
            if (requiredPermission != null && requiredPermission.contains(objName)) {
                childObjects.add('\'' + permission + '\'');
            }
        }
        if (!parentObjects.isEmpty()) {
            processParentObjects(new List < String > (parentObjects), allDependencies, sessionId, serverUrl);
        }
        if (!childObjects.isEmpty()) {
            processChildObjects(new List < String > (childObjects), allDependencies, sessionId, serverUrl);
        }
    }
    @TestVisible
    private static void processParentObjects(List < String > parentObjects, List < Object > allDependencies, String sessionId, String serverUrl) {
        if (parentObjects.isEmpty()) {
            return;
        }
        String parentObjNames = String.join(parentObjects, ',');
        String query = 'SELECT Id, Permission, RequiredPermission FROM PermissionDependency ' +
            'WHERE Permission IN (' + parentObjNames + ') ' +
            'AND PermissionType = \'Object Permission\' ' +
            'AND RequiredPermissionType = \'Object Permission\'';
        List < Object > queryResults = sendQueryRequest(query, sessionId, serverUrl);
        Set < String > newParentObjects = new Set < String > ();
        for (Object record: queryResults) {
            Map < String, Object > recordMap = (Map < String, Object > ) record;
            allDependencies.add(record);
            String requiredPermission = (String) recordMap.get('RequiredPermission');
            if (String.isNotBlank(requiredPermission)) {
                newParentObjects.add('\'' + requiredPermission + '\'');
            }
        }
        if (!newParentObjects.isEmpty()) {
            processParentObjects(new List < String > (newParentObjects), allDependencies, sessionId, serverUrl);
        }
    }
    @TestVisible
    private static void processChildObjects(List < String > childObjects, List < Object > allDependencies, String sessionId, String serverUrl) {
        if (childObjects.isEmpty()) {
            return;
        }  
        String childObjNames = String.join(childObjects, ',');
        System.debug('ChildObjName : ' + childObjNames);
        String query = 'SELECT Id, Permission, RequiredPermission FROM PermissionDependency ' +
            'WHERE RequiredPermission IN (' + childObjNames + ') ' +
            'AND PermissionType = \'Object Permission\' ' +
            'AND RequiredPermissionType = \'Object Permission\'';
        System.debug('child query: ' + query);
        
        List < Object > queryResults = sendQueryRequest(query, sessionId, serverUrl);
        Set < String > newChildObjects = new Set < String > ();
        for (Object record: queryResults) {
            Map < String, Object > recordMap = (Map < String, Object > ) record;
            allDependencies.add(record);
            String permission = (String) recordMap.get('Permission');
            if (String.isNotBlank(permission)) {
                newChildObjects.add('\'' + permission + '\'');
            }
        }
        if (!newChildObjects.isEmpty()) {
            processChildObjects(new List < String > (newChildObjects), allDependencies, sessionId, serverUrl);
        }
    }   
    @TestVisible
    private static List < Object > sendQueryRequest(String query, String sessionId, String serverUrl) {
        String endpoint = serverUrl + '/services/data/v58.0/tooling/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map < String, Object > responseMap = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
                return (List < Object > ) responseMap.get('records');
            } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
        }
        
        return new List < Object > ();
    }  
    
    Public Class MutePermissionWrapper {
        @AuraEnabled public final String mutePermSetId;
        @AuraEnabled public final PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper wrapper;
        public MutePermissionWrapper(String mutePermSetId, PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper wrapper) {
            this.mutePermSetId = mutePermSetId;
            this.wrapper = wrapper;
        }
    }
    //This method is used to fetch object and field permissions for PermissionSetGroup related MutingPermissionSet
    @AuraEnabled
    public static MutePermissionWrapper getObjAndFieldPermissionsForMutingPermSet(String groupId, List < String > objNames, String objName) {
        if (String.isBlank(groupId)) {
            return null;
        }
        
        String permSetId = getMutingPermissionSetId(groupId);
        if (String.isBlank(permSetId)) {
            return null;
        }
        PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper objAndFieldPermWrapper = objAndFieldCombinedWrapperResult(permSetId, objNames, objName);
        return new MutePermissionWrapper(permSetId, objAndFieldPermWrapper);
    }
    private static String getMutingPermissionSetId(String groupId) {
        List < PermissionSetGroupComponent > permSetGroupComponents = [ SELECT PermissionSetId FROM PermissionSetGroupComponent
                                                                       WHERE PermissionSetGroupId =: groupId AND (NOT PermissionSet.Name LIKE '%_%') LIMIT 1];
        
        if (!permSetGroupComponents.isEmpty()) {
            return permSetGroupComponents[0].PermissionSetId;
        }
        
        List<PermissionSetGroup> permSetGrp = [SELECT MasterLabel, DeveloperName FROM PermissionSetGroup WHERE Id =: groupId LIMIT 1];
        String mutePermissionId;
        if (permSetGrp.isEmpty()) {
            System.debug('PermissionSetGroup not found for Id: ' + groupId);
            return null;
        }else if(permSetGrp.size() == 1){
            Map<String,Boolean> checkAccessLevelForMutingPermissioSet = PermissionAnalyzerServer.getObjDefinition('MutingPermissionSet');
            system.debug('checkAccessLevelForMutingPermissioSet'+ checkAccessLevelForMutingPermissioSet);
            if(checkAccessLevelForMutingPermissioSet.get('Create')){
                MutingPermissionSet mutePerm = new MutingPermissionSet(
                    MasterLabel = permSetGrp[0].MasterLabel + ' Muted',
                    DeveloperName = permSetGrp[0].DeveloperName + '_Muted'
                );
                insert mutePerm;
                
                Map<String,Boolean> checkAccessLevelForPermissionSetGroupComponent = PermissionAnalyzerServer.getObjDefinition('PermissionSetGroupComponent');
                if(checkAccessLevelForPermissionSetGroupComponent.get('Create')){
                    mutePermissionId = mutePerm.Id;
                    PermissionSetGroupComponent grpComponent = new PermissionSetGroupComponent(PermissionSetGroupId = groupId,  
                                                                                               PermissionSetId = mutePerm.Id );
                    insert grpComponent;
                }
            }
        }
        return mutePermissionId;
    }
    
    @AuraEnabled
    public static PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper objAndFieldCombinedWrapperResult(String permSetId, List < String > objNames, String objName) {
        Map < String, Object > permissionSetMap = new Map < String, Object > ();
        Map < String, Object > fieldPermissionsMap = new Map < String, Object > ();
        
        if (String.isNotBlank(permSetId)) {
            // Query for ObjectPermissions
            for (ObjectPermissions objPerm: [SELECT SObjectType, PermissionsCreate, PermissionsEdit, PermissionsRead,
                                             PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords
                                             FROM ObjectPermissions WHERE ParentId =: permSetId AND SObjectType IN: objNames LIMIT 50000
                                            ]) {
                                                permissionSetMap.put(objPerm.SObjectType, new Map < String, Object > {
                                                    'SObjectType' => objPerm.SObjectType,
                                                        'PermissionsRead' => objPerm.PermissionsRead,
                                                        'PermissionsCreate' => objPerm.PermissionsCreate,
                                                        'PermissionsEdit' => objPerm.PermissionsEdit,
                                                        'PermissionsDelete' => objPerm.PermissionsDelete,
                                                        'PermissionsViewAllRecords' => objPerm.PermissionsViewAllRecords,
                                                        'PermissionsModifyAllRecords' => objPerm.PermissionsModifyAllRecords
                                                        });
                                            }
            
            // Query for FieldPermissions
            for (FieldPermissions fieldPerm: [SELECT Field, PermissionsRead, PermissionsEdit
                                              FROM FieldPermissions
                                              WHERE ParentId =: permSetId AND SObjectType =: objName LIMIT 50000
                                             ]) {
                                                 fieldPermissionsMap.put(fieldPerm.Field, new Map < String, Object > {
                                                     'PermissionsRead' => fieldPerm.PermissionsRead,
                                                         'PermissionsEdit' => fieldPerm.PermissionsEdit,
                                                         'Field' => fieldPerm.Field
                                                         });
                                             }
        }
        return new PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper(permissionSetMap, fieldPermissionsMap);
    }  
    
    public class FieldPermissionUpdateWrapper {
        @AuraEnabled public String Field { get; set; }
        @AuraEnabled public Boolean PermissionsRead { get; set; }
        @AuraEnabled public Boolean PermissionsEdit { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Boolean hasEditAccess { get; set; }
        @AuraEnabled public Boolean mutedPermissionsRead { get; set; }
        @AuraEnabled public Boolean mutedPermissionsEdit { get; set; }
    }
    Public Class UpdatedObjAndFieldResult {
        @AuraEnabled Public Map<String, Object> objectPerms { get; set; }
        @AuraEnabled Public List<FieldPermissionUpdateWrapper> fieldPerms { get; set; }
        Public UpdatedObjAndFieldResult(Map<String, Object> objectPerms,List<FieldPermissionUpdateWrapper> fieldPerms) {
            this.objectPerms = objectPerms;
            this.fieldPerms = fieldPerms;
        }
    }
    
    //This Method is Used to Fetch the PermissionSet's Object/Field permissions to update the profile Changes to PermissionSet 
    @AuraEnabled
    public static UpdatedObjAndFieldResult getSelectePermissionsetObjAndFieldResult(String permSetId, List < String > objNames, List < FieldPermissionUpdateWrapper > fieldMap, List < String > fieldsList) {
        Map < String, Object > existingObjPermsMap = new Map < String, Object > ();
        Map < String, FieldPermissionUpdateWrapper > fieldWrapperMap = new Map < String, FieldPermissionUpdateWrapper > ();
        
        if (String.isNotBlank(permSetId)) {
            // Query Object Permissions
            for (ObjectPermissions objPerm: [SELECT SObjectType, PermissionsRead, PermissionsDelete, PermissionsEdit, PermissionsCreate, PermissionsViewAllRecords, PermissionsModifyAllRecords
                                             FROM ObjectPermissions
                                             WHERE ParentId =: permSetId AND SobjectType IN: objNames LIMIT 50000
                                            ]) {
                                                existingObjPermsMap.put(objPerm.SobjectType, new Map < String, Boolean > {
                                                    'PermissionsRead' => objPerm.PermissionsRead,
                                                        'PermissionsDelete' => objPerm.PermissionsDelete,
                                                        'PermissionsEdit' => objPerm.PermissionsEdit,
                                                        'PermissionsCreate' => objPerm.PermissionsCreate,
                                                        'PermissionsViewAllRecords' => objPerm.PermissionsViewAllRecords,
                                                        'PermissionsModifyAllRecords' => objPerm.PermissionsModifyAllRecords
                                                        });
                                            }
            
            // Create a map for quick lookup of FieldPermissionUpdateWrapper objects
            for (FieldPermissionUpdateWrapper wrapper: fieldMap) {
                fieldWrapperMap.put(wrapper.Field, wrapper);
            }
            
            // Query Field Permissions
            if (!fieldMap.isEmpty()) {
                for (FieldPermissions fieldPerm: [SELECT PermissionsRead, PermissionsEdit, Field
                                                  FROM FieldPermissions
                                                  WHERE ParentId =: permSetId AND Field IN: fieldsList LIMIT 50000
                                                 ]) {
                                                     FieldPermissionUpdateWrapper wrapper = fieldWrapperMap.get(fieldPerm.Field);
                                                     if (wrapper != null) {
                                                         wrapper.PermissionsRead = fieldPerm.PermissionsRead;
                                                         wrapper.PermissionsEdit = fieldPerm.PermissionsEdit;
                                                     }
                                                 }
            }
        }
        return new UpdatedObjAndFieldResult(existingObjPermsMap, fieldMap);
    }
    //This Method is Used to Update Object ANd Field Permissions For Profile and PermissionSets And PermissionSetGroup
    @AuraEnabled
    Public Static UpdatedObjAndFieldResult updateObjAndFieldInitiation(Map<String, Map<String, Boolean>> objectPermissionsMap, List<FieldPermissionUpdateWrapper> fieldPerms, String permSetId, String objName, String muteOrFilePermissionsType) {
        system.debug('objectPermissionsMap'+objectPermissionsMap);
        system.debug('fieldPerms'+fieldPerms);
        system.debug('permSetId'+permSetId);
        system.debug('objName'+objName);
        system.debug('muteOrFilePermissionsType'+muteOrFilePermissionsType);
        Map<String, Object> objPermissionResult = new Map<String, Object>();
        List<FieldPermissionUpdateWrapper> fieldPermissionResult = new List<FieldPermissionUpdateWrapper>();
        try {
            if (objectPermissionsMap != null && !objectPermissionsMap.isEmpty()) {
                objPermissionResult = updateObjPermissions(objectPermissionsMap, permSetId);
            }
            
            if (fieldPerms != null && !fieldPerms.isEmpty()) {
                String fieldPermType = (muteOrFilePermissionsType == 'MutePermissions') ? 'MutePermissions' : '';
                fieldPermissionResult = updateFieldPermissions(fieldPerms, permSetId, objName, fieldPermType);
            }
            return new UpdatedObjAndFieldResult(objPermissionResult, fieldPermissionResult);
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while updating SObject metadata: ' + e.getMessage());
        }
    }
    // This Method is the Handler for Updating Object Permissions
    @AuraEnabled
    Public Static Map<String, Object> updateObjPermissions(Map<String, Map<String, Object>> objPerms, String permSetId) {
        Map < String, Object > resultMap = new Map < String, Object > ();
        if (String.isBlank(permSetId) || objPerms == null || objPerms.isEmpty()) {
            return resultMap;
        }
        
        try {
            Set < String > objNames = objPerms.keySet();
            Map < String, ObjectPermissions > existingPermMap = new Map < String, ObjectPermissions > ();
            for (ObjectPermissions perm: [SELECT Id, ParentId, SobjectType, PermissionsCreate, PermissionsRead,
                                          PermissionsEdit, PermissionsDelete, PermissionsModifyAllRecords,
                                          PermissionsViewAllRecords
                                          FROM ObjectPermissions
                                          WHERE ParentId =: permSetId AND SobjectType IN: objNames LIMIT 50000
                                         ]) {
                                             existingPermMap.put(perm.SobjectType, perm);
                                         }
            
            List < ObjectPermissions > objPermissionsToUpsert = new List < ObjectPermissions > ();
            
            for (String objName: objPerms.keySet()) {
                Map < String, Object > permissionsMap = objPerms.get(objName);
                //This Method is the Handler for Updating Field Permissions
                ObjectPermissions objToUpsert = existingPermMap.containsKey(objName) ?
                    existingPermMap.get(objName) : new ObjectPermissions(ParentId = permSetId, SobjectType = objName);
                
                objToUpsert.PermissionsCreate = (Boolean) permissionsMap.get('PermissionsCreate');
                objToUpsert.PermissionsRead = (Boolean) permissionsMap.get('PermissionsRead');
                objToUpsert.PermissionsEdit = (Boolean) permissionsMap.get('PermissionsEdit');
                objToUpsert.PermissionsDelete = (Boolean) permissionsMap.get('PermissionsDelete');
                objToUpsert.PermissionsModifyAllRecords = (Boolean) permissionsMap.get('PermissionsModifyAllRecords');
                objToUpsert.PermissionsViewAllRecords = (Boolean) permissionsMap.get('PermissionsViewAllRecords');
                
                objPermissionsToUpsert.add(objToUpsert);
                resultMap.put(objName, objToUpsert);
            }
            Map<String,Boolean> checkAccessLevelForObjectPermissions = PermissionAnalyzerServer.getObjDefinition('ObjectPermissions');
            if (!objPermissionsToUpsert.isEmpty() && checkAccessLevelForObjectPermissions.get('Create') 
                && checkAccessLevelForObjectPermissions.get('Update')) {
                    upsert objPermissionsToUpsert;
                }
            return resultMap;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating object permissions: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while updating object permissions: ' + e.getMessage());
        }
    }
    //This Method is the Handler for Updating Field Permissions
    Public Static List<FieldPermissionUpdateWrapper> updateFieldPermissions(List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList, String permissionSetId, String objName, String fieldPermType)
    {
        if (String.isBlank(permissionSetId) || fieldPermissionWrapperList == null || fieldPermissionWrapperList.isEmpty()) {
            return null;
        }
        
        List < FieldPermissions > permissionsToUpsert = new List < FieldPermissions > ();
        Map < String, FieldPermissionUpdateWrapper > fieldWrapperMap = new Map < String, FieldPermissionUpdateWrapper > ();
        
        for (FieldPermissionUpdateWrapper wrapper: fieldPermissionWrapperList) {
            fieldWrapperMap.put(wrapper.Field, wrapper);
        }
        
        Map < String, FieldPermissions > existingPermissionsMap = new Map < String, FieldPermissions > ();
        for (FieldPermissions fieldPerm: [SELECT Id, SObjectType, Field, PermissionsRead, PermissionsEdit
                                          FROM FieldPermissions
                                          WHERE ParentId =: permissionSetId AND Field IN: fieldWrapperMap.keySet() LIMIT 50000
                                         ]) {
                                             existingPermissionsMap.put(fieldPerm.Field, fieldPerm);
                                         }
        
        for (String fieldName: fieldWrapperMap.keySet()) {
            FieldPermissionUpdateWrapper fieldPermWrap = fieldWrapperMap.get(fieldName);
            FieldPermissions permission = existingPermissionsMap.containsKey(fieldName) ?
                existingPermissionsMap.get(fieldName) :
            new FieldPermissions(SObjectType = objName, Field = fieldName, ParentId = permissionSetId);
            
            if (fieldPermType != 'MutePermissions') {
                permission.PermissionsRead = fieldPermWrap.PermissionsRead;
                permission.PermissionsEdit = fieldPermWrap.PermissionsEdit;
            } else {
                permission.PermissionsRead = fieldPermWrap.mutedPermissionsRead;
                permission.PermissionsEdit = fieldPermWrap.mutedPermissionsEdit;
            }
            
            permissionsToUpsert.add(permission);
        }
        Map<String,Boolean> checkAccessLevelForFieldPermissions = PermissionAnalyzerServer.getObjDefinition('FieldPermissions');
        if (!permissionsToUpsert.isEmpty() && checkAccessLevelForFieldPermissions.get('Create') 
            && checkAccessLevelForFieldPermissions.get('Update')) {
                try {
                    upsert permissionsToUpsert;
                    return fieldPermissionWrapperList;
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error upserting Field Permissions: ' + e.getMessage());
                    throw new AuraHandledException('An error occurred while upserting Field Permissions: ' + e.getMessage());
                }
            }
        return null;
    }
    
    
}