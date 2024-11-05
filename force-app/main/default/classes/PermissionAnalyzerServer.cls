//This Class is used to fetch User and its Related Profile/PermissionSet/PermissionSetgroup details and used in permissionAnalyzer LWC Component
Public Without Sharing Class PermissionAnalyzerServer {
    //Retrive Users Based on SearchName.
    @AuraEnabled
    Public Static List<User> getUser(String searchUserName) 
    {
        if (String.isNotBlank(searchUserName)) {
            List<User> userList = [SELECT Id, Name, ProfileId, Email FROM User WHERE Name LIKE :'%' + String.escapeSingleQuotes(searchUserName) + '%' LIMIT 1000];
            return userList;
        } else {
            return new List<User>();
        }
    }
    // Retrive PermissionSets based on Users
    @AuraEnabled
    public static List<PermissionSet> getUserRelatedPermissionSets(string userId) 
    {
        if (String.isBlank(userId)) {
            return new List < PermissionSet > ();
        }
        Set < Id > permissionSetIds = new Set < Id > ();
        for (PermissionSetAssignment psa: [SELECT PermissionSetId,Assignee.UserName FROM PermissionSetAssignment WHERE AssigneeId =: userId]) {
            permissionSetIds.add(psa.PermissionSetId);
        }    		
        return [
            SELECT Id, Name, NamespacePrefix, IsCustom, Description, PermissionSetGroupId,
            PermissionSetGroup.Description, ProfileId, Type, Profile.Name, Profile.UserType,
            Profile.Description, Profile.UserLicense.Name, License.Name, Label
            FROM PermissionSet
            WHERE Id IN: permissionSetIds LIMIT 50000
        ];
    }
    // Used to fetch EntityDefinition Objects.
    @AuraEnabled
    Public Static List<EntityDefinition> getEntityDefinition(string objType) 
    {
        String query = 'Select Id, Label,QualifiedApiName,NamespacePrefix FROM EntityDefinition WHERE DefaultCompactLayoutId != null ';
        if (objType == 'Native') {
            query += ' and (not NameSpacePrefix LIKE \'%_%\')';
        }    
        if (objType == 'ManagedPackage') {
            query += 'and NameSpacePrefix LIKE  \'%_%\'';
        } 
        query += ' ORDER BY Label LIMIT 50000';
        System.debug('query'+query);
        return Database.Query(query);
    }
    //Wrapper Class for User's Object And Field Permissions
    Public Class ObjANdFieldPermissionsWrapper 
    {
        @AuraEnabled public Map < String, Object > objectPermissions { get; set; }
        @AuraEnabled public Map < String, Object > fieldPermissions { get; set; }
        
        public ObjAndFieldPermissionsWrapper(Map < String, Object > objectPermissions, Map < String, Object > fieldPermissions) {
            this.objectPermissions = objectPermissions ?? new Map < String, Object > ();
            this.fieldPermissions = fieldPermissions ?? new Map < String, Object > ();
        }
        public ObjAndFieldPermissionsWrapper() {
            this(null, null);
        }
    }
    //User To Fetch user's Object and Field Permissions based on User's Profile && PermissionSet && PermissionSetGroup.
    @AuraEnabled
    Public Static Map<String, ObjANdFieldPermissionsWrapper> getCombinedObjAndFieldPermsForUser(List<String> permissionSetIds) 
    {
        Map<String, ObjANdFieldPermissionsWrapper> objANdFieldPermissionsWrapperMap = new Map<String, ObjANdFieldPermissionsWrapper>();
        for (ObjectPermissions objPerm : [
            SELECT Id, SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords,
            PermissionsModifyAllRecords FROM ObjectPermissions WHERE ParentId IN :permissionSetIds ORDER BY SObjectType ASC LIMIT 50000])
        {
            ObjAndFieldPermissionsWrapper wrapper = objAndFieldPermissionsWrapperMap.get(objPerm.SObjectType);
            if (wrapper == null) {
                Map < String, Object > permissionSetMap = new Map < String, Object > {
                    'SObjectType' => objPerm.SObjectType,
                        'PermissionsRead' => objPerm.PermissionsRead,
                        'PermissionsCreate' => objPerm.PermissionsCreate,
                        'PermissionsEdit' => objPerm.PermissionsEdit,
                        'PermissionsDelete' => objPerm.PermissionsDelete,
                        'PermissionsViewAllRecords' => objPerm.PermissionsViewAllRecords,
                        'PermissionsModifyAllRecords' => objPerm.PermissionsModifyAllRecords
                        };
                            
                            wrapper = new ObjAndFieldPermissionsWrapper(permissionSetMap, new Map < String, Object > ());
                objAndFieldPermissionsWrapperMap.put(objPerm.SObjectType, wrapper);
            } else {
                wrapper.objectPermissions = consolidateObjectPermissions(wrapper.objectPermissions, objPerm);
            }
        }
        // Process Field Permissions
        for (FieldPermissions fieldPerm : [SELECT SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions
                                           WHERE ParentId IN :permissionSetIds ORDER BY SObjectType ASC LIMIT 50000])
        {
            System.debug('inside field permissions for loop');
            ObjAndFieldPermissionsWrapper wrapper = objAndFieldPermissionsWrapperMap.get(fieldPerm.SObjectType);
            if (wrapper == null) {
                Map < String, Object > fieldPermissionsMap = new Map < String, Object > {
                    fieldPerm.Field => new Map < String,
                        Object > {
                            'PermissionsRead' => fieldPerm.PermissionsRead,
                                'PermissionsEdit' => fieldPerm.PermissionsEdit,
                                'Field' => fieldPerm.Field
                                }
                };
                    wrapper = new ObjAndFieldPermissionsWrapper(new Map < String, Object > (), fieldPermissionsMap);
                objAndFieldPermissionsWrapperMap.put(fieldPerm.SObjectType, wrapper);
            } else {
                wrapper.fieldPermissions = wrapper.fieldPermissions ?? new Map < String, Object > ();
                wrapper.fieldPermissions = consolidateFieldPermissions(wrapper.fieldPermissions, fieldPerm);
            }
        } 
        return objANdFieldPermissionsWrapperMap;
    }
    // Gives the consolidated Object Permissions for an User
    public static Map < String, Object > consolidateObjectPermissions(Map < String, Object > existingPermissions, ObjectPermissions newPerm) {
        Map < String, Object > result = existingPermissions == null ? new Map < String, Object > () : existingPermissions.clone();
        
        result.put('PermissionsRead', (Boolean) result.get('PermissionsRead') || newPerm.PermissionsRead);
        result.put('PermissionsCreate', (Boolean) result.get('PermissionsCreate') ||newPerm.PermissionsCreate);
        result.put('PermissionsEdit', (Boolean) result.get('PermissionsEdit') || newPerm.PermissionsEdit);
        result.put('PermissionsDelete', (Boolean) result.get('PermissionsDelete') || newPerm.PermissionsDelete);
        result.put('PermissionsViewAllRecords', (Boolean) result.get('PermissionsViewAllRecords') || newPerm.PermissionsViewAllRecords);
        result.put('PermissionsModifyAllRecords', (Boolean) result.get('PermissionsModifyAllRecords') || newPerm.PermissionsModifyAllRecords);
        
        return result;
    }
    // Gives the consolidated Field Permissions for an User
    public static Map<String, Object> consolidateFieldPermissions(Map<String, Object> existingPermissions, FieldPermissions newPerm) {
        existingPermissions = existingPermissions ?? new Map<String, Object>();
        
        Map<String, Object> fieldPermission = (Map<String, Object>)existingPermissions.get(newPerm.Field);
        fieldPermission = fieldPermission ?? new Map<String, Object>();
        
        fieldPermission.put('PermissionsRead', fieldPermission.containsKey('PermissionsRead') ? (Boolean) fieldPermission.get('PermissionsRead') || newPerm.PermissionsRead : newPerm.PermissionsRead);
        fieldPermission.put('PermissionsEdit', fieldPermission.containsKey('PermissionsEdit') ? (Boolean) fieldPermission.get('PermissionsEdit') || newPerm.PermissionsEdit : newPerm.PermissionsEdit);
        
        existingPermissions.put(newPerm.Field, fieldPermission);
        
        return existingPermissions;
    }
    //Uses to fetch Profile API Name Using Tooling API
    @AuraEnabled
    Public Static List<String> getProfileName(String profileId) 
    {
        UserAccessManager instance = new UserAccessManager();
        List<String> profileName = new List<String>(); 
        String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query/?q=select+id,+Name,+FullName+from+Profile+where+Id=\'' +profileId +'\'';
        Http newReq = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('GET');
        req.setHeader('Authorization','Bearer ' + instance.partnerConnection.SessionHeader.sessionId);
        req.setHeader('Content-Type', 'application/json');
        HttpResponse res = new HttpResponse();
        try {
            res = newReq.send(req);
            system.debug('check result' + res);
            if (res.getStatusCode() == 200) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> records = (List<Object>) results.get('records');
                for (Object record : records) {
                    Map<String, Object> recordMap = (Map<String, Object>) record;
                    profileName.add((String) recordMap.get('FullName'));
                }
            } else {
                System.debug('Error: ' + res.getStatus());
                System.debug('Response: ' + res.getBody());
            }
        } catch (exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
        system.debug('check profile Name' + profileName);
        return profileName;
    }
    
    //Uses To fetch the Assigned List of users for Profile/PermissionSet and PermissionSetGroup
    @AuraEnabled
    Public Static List<PermissionSetAssignment> getAssignedUsersForProfilePerSetPerSetGrp(String profpersetId) {
        return [SELECT Id, AssigneeId, Assignee.Name, Assignee.IsActive, Assignee.Profile.UserLicense.Name,Assignee.Username FROM PermissionSetAssignment WHERE PermissionSetId = :profpersetId 
                AND Assignee.IsActive = true order by Assignee.Name asc LIMIT 50000
               ]; 
    }
    
    //This method is used to edit the properties of PermissionSetGroup
    @AuraEnabled
    Public Static PermissionSetGroup editPermSetGrpProperties( String perSetId, String label, String apiName, String description, String format) {
        if (String.isBlank(perSetId)) {
            throw new AuraHandledException('Invalid Permission Set Id');
        }
        List<PermissionSet> permissioSetList = [SELECT PermissionSetGroupId FROM PermissionSet WHERE Id = :perSetId LIMIT 1];
        System.debug('permissioSetList'+permissioSetList);
        PermissionSetGroup permsetGroup = new PermissionSetGroup();
        Map<String,Boolean> checkAccessLevelForPermSetGrpUpdate = getObjDefinition('PermissionSetGroup');
        if(permissioSetList[0].PermissionSetGroupId != null && checkAccessLevelForPermSetGrpUpdate.get('Update')){
            permsetGroup.Id = permissioSetList[0].PermissionSetGroupId;
            permsetGroup.MasterLabel = label;
            permsetGroup.DeveloperName = apiName;
            permsetGroup.Description = description;
            update permsetGroup;
        }else {
            throw new AuraHandledException('No PermissionSetGroup found for the provided PermissionSet ID.');
        }
        return permsetGroup;
    }
    //This method is used to edit the properties of PermissionSet
    @AuraEnabled
    Public Static PermissionSet editPermSetProperties(String perSetId, String label, String apiName, String description) {       
        System.debug('perSetId '+ perSetId + ' label'+ label + ' apiName' + apiName + ' Description'+ description);
        PermissionSet perSetVal = new PermissionSet(Id = perSetId, Label = label,  Name = apiName?.replaceAll(' ', '_'), Description = description);
        Map<String,Boolean> checkAccessLevelForPermSetUpdate = getObjDefinition('PermissionSet');
        if(checkAccessLevelForPermSetUpdate.get('Update')){
            try {
                update perSetVal;
            } catch (DmlException e) {
                handleException('Error updating Permission Set: ', e);
            }
        }        
        return [SELECT Id, Name, Label, Description FROM PermissionSet WHERE Id =: perSetId];
    }
    //This method is used to edit the properties of Profile
    @AuraEnabled
    Public Static Map<String, String> editProfileProperties(String profileName,String newProfileName,String newDescription) {
        Map<String, String> returnMap = new Map<String, String>();
        try {
            UserAccessManager instance = new UserAccessManager();
            List < MetadataService.Profile > profiles = (List < MetadataService.Profile > ) instance.service.readMetadata('Profile', new List < String > {
                profileName
                    }).getRecords();
            if (profiles.isEmpty() || profiles[0].fullName == null) {
                throw new AuraHandledException('Profile not found');
            }
            MetadataService.Profile updatedProfile = new MetadataService.Profile();
            updatedProfile.fullName = newProfileName;
            updatedProfile.description = newDescription;
            MetadataService.UpsertResult[] results = instance.service.upsertMetadata(new List < MetadataService.Profile > {
                updatedProfile
                    });
            if (!results[0].success) {
                throw new AuraHandledException('Error updating profile: ' + ': ' + results[0].errors[0].message);
            }
            
            returnMap.put('label', newProfileName);
            returnMap.put('description', newDescription);
            
        } catch (Exception e) {
            handleException('Error processing profile update: ', e);
        }
        return returnMap;
    }    
    private static void handleException(String message, Exception e) {
        String fullMessage = e == null ? message : message + ': ' + e.getMessage();
        System.debug(LoggingLevel.ERROR, fullMessage);
        throw new AuraHandledException(fullMessage);
    }
    @AuraEnabled
    public static Map<String, Boolean> getObjDefinition(String objectName) {        
        if (String.isBlank(objectName)) {
            throw new IllegalArgumentException('Object name cannot be blank.');
        }
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
        
        if (sObjectType == null) {
            throw new IllegalArgumentException('Invalid object name: ' + objectName);
        }        
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Map<String, Boolean> permissionsMap = new Map<String, Boolean>();
        permissionsMap.put('Create', describeResult.isCreateable());
        permissionsMap.put('Delete', describeResult.isDeletable());
        permissionsMap.put('Update', describeResult.isUpdateable());
        permissionsMap.put('Accessible', describeResult.isAccessible()); // Checks if the object is readable
        System.debug('permissionsMap'+permissionsMap);
        return permissionsMap;        
    }
    
}