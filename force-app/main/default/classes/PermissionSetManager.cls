//This class is used for create,edit,delete,update,assign user,unassign user in Permission Set..
Public without sharing Class PermissionSetManager {
  //Method to Create Permission Set
  @AuraEnabled(cacheable=false)
  Public Static String createPermissionSet(Map<String,Object> permSetToCreate,List<Id> userIds) 
  {    
    UserAccessManager instance = new UserAccessManager();
    String persetapi;
    List<MetadataService.PermissionSet> persetToInsert = new List<MetadataService.PermissionSet>();
    MetadataService.PermissionSet insertPerset = new MetadataService.PermissionSet();
    insertPerset.fullName = ((String) permSetToCreate.get('Name')).replaceAll(' ', '_');
    insertPerset.label = (String) permSetToCreate.get('Label');
    insertPerset.description = (String) permSetToCreate.get('Description');
    insertPerset.license = (String) permSetToCreate.get('License');
    insertPerset.hasActivationRequired = (Boolean) permSetToCreate.get('hasActivationRequired');
    persetToInsert.add(insertPerset);

    if (!persetToInsert.isEmpty()) {
      try {
        MetadataService.UpsertResult[] results = (MetadataService.UpsertResult[]) instance.service.upsertMetadata(persetToInsert);
        for (MetadataService.UpsertResult upsertResult : results) {
          persetapi = upsertResult.fullName;
          if (!upsertResult.success) {
            for (MetadataService.Error error : upsertResult.errors) {
              System.debug('Error: ' + error.message + ' Status Code: ' + error.statusCode);
              if (error.fields != null) {
                for (String field : error.fields) {
                  System.debug('Error Field: ' + field);
                }
              }
            }
            throw new AuraHandledException('Error inserting Permission Set: ' + upsertResult.errors[0].message);
          } else {
            System.debug('Permission Set Inserted successfully for: ' + upsertResult.fullName);
          }
        }
      } catch (Exception e) {
        System.debug('Error Inserting Permission Set: ' + e.getMessage());
        throw new AuraHandledException('Error inserting Permission Set: ' + e.getMessage());
      }
    }
    System.debug('Permission Set API Name:>>> ' + persetapi);
     
    List<PermissionSet> persetId = [SELECT Id, Name FROM PermissionSet WHERE Name = :persetapi LIMIT 1];
      System.debug('persetId>>>'+persetId);
    createPermSetAssignmentForCreatedPermSet(userIds,persetId[0].Id);
      return persetId[0].Id;
  }
   @AuraEnabled
   Public Static Void createPermSetAssignmentForCreatedPermSet(List<Id> userids, String perSetId){
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        for (Id userId : userIds) {
          // Create a new PermissionSetAssignment record for each user
          PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
          permSetAssignment.AssigneeId = userId;
          permSetAssignment.PermissionSetId = perSetId;
          permSetAssignments.add(permSetAssignment);
        }
    
        try {
          insert permSetAssignments;
          System.debug('Permission set assignments successfully created.');
        } catch (DmlException e) {
          System.debug('Error occurred while assigning permission set: ' + e.getMessage());
          throw new AuraHandledException('Error occurred while assigning permission set: ' + e.getMessage());
        }
   }
  //Method to get Permission Set
  @AuraEnabled(cacheable=true)
  Public Static List<Map<String, String>> getPermissionSet() 
  {  
    List < Map < String, String >> result = new List < Map < String, String >> ();

    // Query PermissionSets
    List < PermissionSet > permissionSets = [SELECT Id, Name, Label, Description, IsCustom, NamespacePrefix, CreatedDate, LastModifiedDate,
        License.Name, License.Id,CreatedBy.Name, CreatedBy.Id,LastModifiedBy.Name, LastModifiedBy.Id FROM PermissionSet
        WHERE IsOwnedByProfile = false AND Type != 'Group' Limit 50000
    ];

    for (PermissionSet ps: permissionSets) {
        Map < String, String > recordMap = new Map < String, String > {
            'Id' => ps.Id,
            'Name' => ps.Name,
            'Label' => ps.Label,
            'Description' => ps.Description,
            'IsCustom' => String.valueOf(ps.IsCustom),
            'NamespacePrefix' => ps.NamespacePrefix,
            'CreatedDate' => String.valueOf(ps.CreatedDate),
            'LastModifiedDate' => String.valueOf(ps.LastModifiedDate),
            'LicenseId' => ps.License?.Id,
            'LicenseName' => ps.License?.Name,
            'CreatedById' => ps.CreatedBy?.Id,
            'CreatedByName' => ps.CreatedBy?.Name,
            'LastModifiedById' => ps.LastModifiedBy?.Id,
            'LastModifiedByName' => ps.LastModifiedBy?.Name
        };
        result.add(recordMap);
    }
    return result;
  }
   
  //Method to Insert Users to Permission Set
  @AuraEnabled
  Public Static Void insertUsertoPermissionSet(List<String> userId,String perSetId) 
  {
    List<PermissionSetAssignment> perSetAsi = new List<PermissionSetAssignment>();
    for (String assignId : userId) {
      PermissionSetAssignment perAsi = new PermissionSetAssignment();
      perAsi.AssigneeId = assignId;
      perAsi.PermissionSetId = perSetId;
      perSetAsi.add(perAsi);
    }
    try {
      insert perSetAsi;
      System.debug('Permission Set assigned successfully to all users');
    } catch (DmlException e) {
      System.debug('Error assigning Permission Set: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }
    
  //Method to Delete Users from Permission Set  
  @AuraEnabled
  Public Static Void deleteUserfromPermissionSet(List<String> userId,String perSetId) 
  {
    List<PermissionSetAssignment> persetAssignForDlt = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId IN :userId AND PermissionSetId = :perSetId Limit 50000];
    try {
      delete persetAssignForDlt;
      System.debug('Permission Set Deleted successfully for the users');
    } catch (DmlException e) {
      System.debug('Error Deleting Permission Set: ' + e.getMessage());
    }
  }
  
  //Method to Edit Permission Set  
  @AuraEnabled
  Public Static PermissionSet editPermissionSet(String perSet,String label,String apiName,String description) 
  {
    system.debug('Per Set'+perSet);
    system.debug('Label'+label);
    system.debug('Api Name'+apiName);
    system.debug('Description'+description);
    PermissionSet perSetVal = [SELECT id, Name, Label, Description FROM PermissionSet WHERE id = :perSet];
    if (perSet != null) {
      perSetVal.Label = label;
      perSetVal.Name = apiName.replaceAll(' ', '_');
      perSetVal.Description = description;
      try {
        update perSetVal;
      } catch (DmlException e) {
        throw new AuraHandledException(e.getMessage());
      }
    }
    return perSetVal;
  }
    
  //Method to Delete Permission Set    
  @AuraEnabled
  Public Static String deletePerSet(String permissionSetId) 
  {
    try {
          // Delete Permission Set Assignments first
          delete[SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId =: permissionSetId];
          // Delete the Permission Set
          delete new PermissionSet(Id = permissionSetId);
          return 'Permission set and its assignments deleted successfully.';
      } catch (QueryException qe) {
          System.debug('Permission set not found: ' + qe.getMessage());
          return 'Permission set not found.';
      } catch (DmlException de) {
          handleException('Error occurred while deleting permission set or its assignments: ', de);
          return null;
      }
  }
    
  //Method to Clone Permission Set with Users  
  @AuraEnabled
  Public Static Void clonePermissionSetwithUsers(String sourcePermissionSetId, String newLabel, String newApiName, String newDescription, String newLicense) 
  {
    try {
      PermissionSet newPerSet = new PermissionSet();
      newPerSet.Label = newLabel;
      newPerSet.Name = newApiName.replaceAll(' ', '_');
      newPerSet.Description = newDescription;
      if (newLicense != null || newLicense != '') {
        newPerSet.LicenseId = newLicense;
      }
      insert newPerSet;
      Id newPermissionSetId = newPerSet.Id;

      //Get Users From Old Permission Set
      List<PermissionSetAssignment> persetass = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId = :sourcePermissionSetId Limit 50000];
      Set<Id> assigneeIds = new Set<Id>();
      for (PermissionSetAssignment psa : persetass) {
        assigneeIds.add(psa.AssigneeId);
      }
      List<User> userList = [SELECT id,Name,Username,Profile.Name,IsActive,Profile.UserLicense.Name FROM user WHERE IsActive = TRUE AND Id IN :assigneeIds Limit 50000];
      Set<Id> userids = new Set<Id>();
      for (User psa : userList) {
        userids.add(psa.id);
      }
      //Assign Users to new permission Set
      List<PermissionSetAssignment> persetasi = new List<PermissionSetAssignment>();
      for (string assignId : userids) {
        PermissionSetAssignment perasi = new PermissionSetAssignment();
        perasi.AssigneeId = assignId;
        perasi.PermissionSetId = newPermissionSetId;
        persetasi.add(perasi);
      }
      try {
        insert persetasi;
        System.debug('Permission Set assigned successfully to all users');
      } catch (DmlException e) {
        System.debug('Error assigning Permission Set: ' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
      }
    } catch (DmlException e) {
      System.debug('Error Cloning Permission Set Group: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }
    
  //Method to Clone Permission Set without Users  
  @AuraEnabled
  Public Static Void clonePermissionSetWithoutUser(String newLabel,String newApiName,String newDescription,string newLicense) 
  {
    try {
      PermissionSet newPerSet = new PermissionSet();
      newPerSet.Label = newLabel;
      newPerSet.Name = newApiName.replaceAll(' ', '_');
      newPerSet.Description = newDescription;
      if (newLicense != null || newLicense != '') {
        newPerSet.LicenseId = newLicense;
      }
      insert newPerSet;
    } catch (DmlException e) {
      System.debug('Error Cloning Permission Set Group: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }
    
    //Method to retrieve Assigned Users From Permission Set
  @AuraEnabled
  Public Static List<User> getAssignedUserForPermissionSet(String permissionSetId) 
  {
    return [SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User 
        WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Id = :permissionSetId AND AssigneeId != null)
        ORDER BY Name ASC Limit 50000];
  }
    
  //Method to retrieve UnAssigned Users From Permission Set  
  @AuraEnabled
  Public Static List<user> getUnAssignedUserForPermissionSet(String permissionSetId,String profileName,String userLicense,String licenseName) 
  {	   
    // Query PermissionSetAssignment using standard SOQL
    Set<Id> assigneeIds = new Set<Id>();
    for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Id = :permissionSetId AND AssigneeId != null]) {
            assigneeIds.add(psa.AssigneeId);
        }
    // Constructing the dynamic query
    String query = 'SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name ' +
                  'FROM User ' +
                  'WHERE IsActive = true AND Id NOT IN :assigneeIds';

    if (String.isNotBlank(profileName) && profileName != 'All') {
        query += ' AND Profile.Name = :profileName';
    }
    if (String.isNotBlank(licenseName)) {
        query += ' AND Profile.UserLicense.Name = :licenseName';
    }

    query += ' ORDER BY Name ASC';
    return Database.query(query);
  }
  
  //Method to filter user based on license
  @AuraEnabled(cacheable=true)
  Public Static List<User> getUserForPermissionSet(String licenseName) {
    List<User> userList = new List<User>();
    if (String.isNotEmpty(licenseName)) {
      system.debug('INSIDE IF');
      system.debug('license name: ' + licenseName);
	  List<UserLicense> userLic = [Select Id, Name from userLicense where Name =: licenseName LIMIT 1];
        system.debug('userLic'+ userLic);
        if(!userLic.isEmpty()){
            userList = [SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE IsActive = TRUE AND Profile.UserLicenseId = :userLic[0].Id];
        }else{
			Set<Id> assigneeId = new Set<Id>();
            for(PermissionSetLicenseAssign permSetLic : [Select Id,AssigneeId,PermissionSetLicense.DeveloperName from PermissionSetLicenseAssign where PermissionSetLicense.DeveloperName =: licenseName])
            {
                if(permSetLic != null){
                   assigneeId.add(permSetLic.AssigneeId); 
                }
            }
            if(assigneeId.size()>0){
                userList = [
                    SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE IsActive = TRUE AND Id IN :assigneeId];
            }
        }
      
    } else {
      system.debug('INSIDE ELSE');
      system.debug('license name:>>> ' + licenseName);
      userList = [SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE IsActive = TRUE];
      system.debug('userList'+ userList);
    }
    return userList;
  }
    
  	@AuraEnabled(cacheable=true)
  public static List<Map<String, String>> getSetPermission() {
      List < Map < String, String >> result = new List < Map < String, String >> ();

      // Query PermissionSets with all necessary related objects in a single query
      List < PermissionSet > permissionSets = [
          SELECT
          Id, Name, Label, Description, IsCustom, NamespacePrefix,
          CreatedDate, LastModifiedDate,
          License.Name, License.Id,
          CreatedBy.Name, CreatedBy.Id,
          LastModifiedBy.Name, LastModifiedBy.Id
          FROM PermissionSet
          WHERE IsOwnedByProfile = false AND Type != 'Group'
      ];

      for (PermissionSet ps: permissionSets) {
          Map < String, String > recordMap = new Map < String, String > {
              'Id' => ps.Id,
              'Name' => ps.Name,
              'Label' => ps.Label,
              'Description' => ps.Description,
              'IsCustom' => String.valueOf(ps.IsCustom),
              'NamespacePrefix' => ps.NamespacePrefix,
              'CreatedDate' => String.valueOf(ps.CreatedDate),
              'LastModifiedDate' => String.valueOf(ps.LastModifiedDate),
              'LicenseId' => ps.License?.Id,
              'LicenseName' => ps.License?.Name,
              'CreatedById' => ps.CreatedBy?.Id,
              'CreatedByName' => ps.CreatedBy?.Name,
              'LastModifiedById' => ps.LastModifiedBy?.Id,
              'LastModifiedByName' => ps.LastModifiedBy?.Name
          };
          result.add(recordMap);
      }
      return result;
  }
    
    @AuraEnabled(cacheable=true)
    //This is a method to get user License for permission set.
	Public Static Map<String, List<Map<String, String>>> getPermissionSetLicenseCreate() {
    	Map < String, List < Map < String, String >>> userPermLicenseMap = new Map < String, List < Map < String, String >>> {
        'UserLicense' => new List < Map < String,
        String >> ()
    };
    try {
        for (UserLicense userLic: [SELECT Id, Name, MasterLabel FROM UserLicense]) {
            userPermLicenseMap.get('UserLicense').add(new Map < String, String > {
                'Id' => userLic.Id,
                'Name' => userLic.Name,
                'MasterLabel' => userLic.MasterLabel
            });
        }
    } catch (Exception e) {
        handleException('Error retrieving UserLicenses: ', e);
    }

    System.debug('userPermLicenseMap: ' + userPermLicenseMap);
    return userPermLicenseMap;
}
    
    @AuraEnabled
    //This is a method to retrieve profiles list.
    Public Static List<Profile> getProfiles() {
         return [SELECT Id, Name, UserLicense.Name FROM Profile ORDER BY Name ASC Limit 50000];
    }
    
    @AuraEnabled(cacheable=true)
    //This is a method to check duplicate label & api name before creating permission set.
    Public Static Boolean checkDuplicatePermissionSet(String label,String apiName) {
        return [SELECT COUNT() FROM PermissionSet WHERE Label = :label OR Name = :apiName] > 0;
    }
    
    @AuraEnabled
    //This method is used to get tab settings for permission set.
    Public Static List<Map<String, Object>> getPermissionSetTabSetting(String permissionSetName) {
        List<Map<String, Object>> tabSettingMapList = new List<Map<String, Object>>();
        Map<String, String> tabVisibilities = getTabForPermissionSet(permissionSetName);
        List<TabDefinition> tabDefList = [SELECT id, Name, Label FROM TabDefinition ORDER BY Label ASC Limit 50000];
        system.debug('tabDefList' + tabDefList);
        if (!tabDefList.isEmpty()) {
            for (TabDefinition tabDef : tabDefList) {
                Map<String, Object> tabSettingMap = new Map<String, Object>();
                tabSettingMap.put('Label', tabDef.Label);
                tabSettingMap.put('Name', tabDef.Name);
                tabSettingMap.put('Visibility', tabVisibilities.get(tabDef.Name));
                tabSettingMapList.add(tabSettingMap);
            }
        }
        System.debug('tabSettingMap' + tabSettingMapList);
        return tabSettingMapList;
    }

  @AuraEnabled
  //Helper method to get tab permissions for permission set.
  Public Static Map<String, String> getTabForPermissionSet(String permissionSetName) {
    UserAccessManager instance = new UserAccessManager();
        Map < String, String > tabSettingObj = new Map < String, String > ();
        try {
            List < MetadataService.PermissionSet > persets = (List < MetadataService.PermissionSet > ) instance.service.readMetadata('PermissionSet', new List < String > {
                permissionSetName
            }).getRecords();

            if (persets != null && !persets.isEmpty()) {
                MetadataService.PermissionSet perset = persets[0];
                if (perset.tabSettings != null) {
                    for (MetadataService.PermissionSetTabSetting tabVisibility: perset.tabSettings) {
                        tabSettingObj.put(tabVisibility.tab, tabVisibility.visibility);
                    }
                }
            }
        } catch (Exception e) {
            handleException('Error retrieving tab settings: ', e);
        }
        System.debug('Tab settings: ' + tabSettingObj);
        return tabSettingObj;
  }
    
    @AuraEnabled(cacheable=true)
    //This method is used to get user permissions/system permissions for permission set.
    Public Static PermissionFieldWrap getCombinedPermissionsforProfile(String permissionSetIds) {
        System.debug('pid==>' + permissionSetIds);
        PermissionFieldWrap permissionWrap = new PermissionFieldWrap();
        
        String baseQueryString = 'SELECT Id, Name';
        Map<String, Schema.SObjectField> baseFields = Schema.SObjectType.PermissionSet.fields.getMap();
        
        for (Schema.SObjectField field : baseFields.values()) {
            String fieldName = field.getDescribe().getName();
            if (fieldName.startsWith('Permissions') &&fieldName != 'Permissionsetgroupid') {
                baseQueryString += ', ' + fieldName;
            }
        }
        baseQueryString += ' FROM PermissionSet WHERE Id = :permissionSetIds';
        List<PermissionSet> basePermissionSets = (List<PermissionSet>) Database.query(
            baseQueryString
        );
        
        // Create a List of Maps
        List<Map<String, Object>> userPermissionsList = new List<Map<String, Object>>();
        
        for (PermissionSet basePermissionSet : basePermissionSets) {
            for (Schema.SObjectField field : baseFields.values()) {
                String fieldName = field.getDescribe().getName();
                if (fieldName.startsWith('Permissions') && fieldName != 'Permissionsetgroupid') {
                    Object fieldValue = basePermissionSet.get(fieldName);
                    String fieldLabel = field.getDescribe().getLabel();
                    
                    // Create a map with the field details
                    Map<String, Object> fieldMap = new Map<String, Object>();
                    fieldMap.put('fieldName', fieldName);
                    fieldMap.put('fieldLabel', fieldLabel);
                    fieldMap.put('fieldValue', fieldValue);
                    
                    // Add the fieldMap to the list
                    userPermissionsList.add(fieldMap);
                }
            }
        }
        
        System.debug('User Permissions List: ' + userPermissionsList);
        permissionWrap.userPermissions = userPermissionsList;
        List<Object> dependSystemPermissions = PermissionSetManager.checkDependencyforSystemPermissions();
        permissionWrap.systemDependencies = dependSystemPermissions;
        System.debug(
            'List of System Permissions: ' + permissionWrap.systemDependencies
        );
        
        Set<String> dependentObjects = new Set<String>();
        for (Object record : dependSystemPermissions) {
            Map<String, Object> recordMap = (Map<String, Object>) record;
            if ((String) recordMap.get('RequiredPermissionType') == 'Object Permission') {
                String requiredPermission = (String) recordMap.get('RequiredPermission');
                String requiredPermissionObject = requiredPermission.split('<')[0];
                dependentObjects.add(requiredPermissionObject);
            }
        }
        
        Map<String, Map<String, Object>> objectPermissionsMap = new Map<String, Map<String, Object>>();
        for (ObjectPermissions objPerm : [SELECT Id,SObjectType,PermissionsRead,PermissionsCreate,PermissionsEdit,PermissionsDelete,PermissionsViewAllRecords,
                                          PermissionsModifyAllRecords
                                          FROM ObjectPermissions
                                          WHERE ParentId = :permissionSetIds AND SObjectType IN :dependentObjects
                                         ]) {
                                             if (objPerm != null) {
                                                 Map<String, Object> objectPermMap = new Map<String, Object>();
                                                 objectPermMap.put('PermissionsCreate', objPerm.PermissionsCreate);
                                                 objectPermMap.put('PermissionsRead', objPerm.PermissionsRead);
                                                 objectPermMap.put('PermissionsEdit', objPerm.PermissionsEdit);
                                                 objectPermMap.put('PermissionsDelete', objPerm.PermissionsDelete);
                                                 objectPermMap.put('PermissionsViewAllRecords',objPerm.PermissionsViewAllRecords);
                                                 objectPermMap.put('PermissionsModifyAllRecords',objPerm.PermissionsModifyAllRecords);
                                                 objectPermissionsMap.put(objPerm.SObjectType, objectPermMap);
                                             }
                                         }
        
        System.debug('Object Permission Map: ' + objectPermissionsMap);
        permissionWrap.objectPermissions = objectPermissionsMap;
        return permissionWrap;
    }
	
    //Wrapper class to get user/system permissions and its dependencies.
    public class PermissionFieldWrap {
        @AuraEnabled public List<Map<String, Object>> userPermissions { get; private set; }
        @AuraEnabled public List<Object> systemDependencies { get; private set; }
        @AuraEnabled public Map<String, Object> objectPermissions { get; private set; }
        public PermissionFieldWrap() {
                this.userPermissions = new List<Map<String, Object>>();
                this.systemDependencies = new List<Object>();
                this.objectPermissions = new Map<String, Object>();
            }
    }
    
    @AuraEnabled
    //Helper method to get user/system dependencies
    Public Static List<Object> checkDependencyforSystemPermissions() {
        UserAccessManager instance = new UserAccessManager();
        String sessionId = instance.partnerConnection.SessionHeader.sessionId;
        String serverUrl = URL.getSalesforceBaseUrl().toExternalForm();

        String query = 'SELECT Id, Permission, RequiredPermission, PermissionType, RequiredPermissionType ' +
            'FROM PermissionDependency ' +
            'WHERE PermissionType = \'User Permission\'';

        return sendQueryRequest(query, sessionId, serverUrl);
    }
    
    private static List < Object > sendQueryRequest(String query, String sessionId, String serverUrl) {
        String endpoint = serverUrl + '/services/data/v58.0/tooling/query?q=' +
            EncodingUtil.urlEncode(query, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map < String, Object > responseMap = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
            return (List < Object > ) responseMap.get('records');
        } else {
            System.debug('Error: ' + res.getStatus());
            return new List < Object > ();
        }
    }
    
    @AuraEnabled
    //This method is used for updating user/system permissions.
    public static List<PermissionSet> updateSystemPermissions(String systemPermissionsMap, String psid) {
    try {
        // Deserialize JSON to a map
        Map<String, Object> permissionsMap = (Map<String, Object>) JSON.deserializeUntyped(systemPermissionsMap);

        // Query for the PermissionSet
        String query = 'SELECT ' + String.join(new List<String>(permissionsMap.keySet()), ', ') +
            ' FROM PermissionSet WHERE Id = :psid';
        List<PermissionSet> permissionSetList = Database.query(query);
        PermissionSet permissionSet;

        // Update the PermissionSet fields
        if (!permissionSetList.isEmpty()) {
            permissionSet = permissionSetList[0];
            for (String permission : permissionsMap.keySet()) {
                permissionSet.put(permission, permissionsMap.get(permission));
            }
        } else {
            // Return an empty list if no permission set was found
            return new List<PermissionSet>();
        }

        // Update the PermissionSet
        update permissionSet;
        return new List<PermissionSet>{ permissionSet }; // Return the updated permission set

    } catch (Exception e) {
        handleException('Error updating PermissionSet: ', e);
        return new List<PermissionSet>(); // Return an empty list if an exception occurs
    }
}
    
    //Wrapper class to get field permissions & its dependencies.
    public class ProfileObjectPermissionsWrapper {
        @AuraEnabled public final List<Map<String, Object>> fieldPermissions;
        @AuraEnabled public final Boolean hasObjAccess;
        @AuraEnabled public final List<Object> dependentObj;
        public ProfileObjectPermissionsWrapper(List<Map<String, Object>> fieldPermissions, Boolean hasObjAccess, List<Object> dependentObj) {
            this.fieldPermissions = fieldPermissions;
            this.hasObjAccess = hasObjAccess;
            this.dependentObj = dependentObj;
        }
    }
    
    @AuraEnabled
    //This Method Used to retrieve fieldDefinition, valid Sobjects for Obj Permissions, Valid field for field Permissions and also fetch Object Permissons Dependencies
    Public Static ProfileObjectPermissionsWrapper getSobjectPermissionsForPermissionSet(String permSetId,String objName,List<String> profileNames)
    {
        List < Object > dependObjects = PermissionAnalyzerObjectServer.checkObjectPermissionDependencies(objName);
        List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
        Map<String, Boolean> fieldAccess = PermissionSetManager.checkFieldType(objName);
        system.debug('fieldAccess' + fieldAccess);
        Map<String, Map<String, Object>> fieldDefMapByName = PermissionSetManager.getFieldDefinitionProfile(objName);
        system.debug('fieldAccess' + fieldDefMapByName);
        system.debug('Before Object Permission');
        Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
        for (FieldPermissions fieldPerm : [SELECT SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId = :permSetId AND SObjectType = :objName]) {
            if (fieldPerm != null) {
                fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
            }
        }
        // Debug: Check the contents of fieldPermissionsMap
        System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);
        
        // Process each field definition
        for (String fieldKey : fieldDefMapByName.keySet()) {
            system.debug('fieldKey'+fieldKey);
            if (fieldKey != null) {
                system.debug(fieldKey + ' fieldKey ' + fieldAccess.get(fieldKey));
                if ((Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') && fieldAccess.get(fieldKey) == true) {
                    Map<String, Object> fieldPermissionMap = new Map<String, Object>();
                    fieldPermissionMap.put('Field', fieldKey);
                    fieldPermissionMap.put('label',fieldDefMapByName.get(fieldKey).get('Label'));
                    
                    // Debug: Check if fieldKey is present in fieldPermissionsMap
                    System.debug('Processing fieldKey: ' + fieldKey);
                    if (fieldPermissionsMap.containsKey(fieldKey)) {
                        system.debug('inside containskey');
                        FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
                        fieldPermissionMap.put('PermissionsRead',fieldPerm.PermissionsRead);
                        fieldPermissionMap.put('PermissionsEdit',fieldPerm.PermissionsEdit);
                    } else {
                        system.debug('inside Else');
                        fieldPermissionMap.put('PermissionsRead', false);
                        fieldPermissionMap.put('PermissionsEdit', false);
                    }
                    
                    fieldPermissionMap.put('hasEditAccess',fieldDefMapByName.get(fieldKey).get('isCalculated'));
                    fieldPermissionsMapList.add(fieldPermissionMap);
                }
            }
        }
        System.debug('check field permission map' + fieldPermissionsMapList);
        return new ProfileObjectPermissionsWrapper(fieldPermissionsMapList,PermissionSetManager.checkSObjType(objName),dependObjects);
    }
    @AuraEnabled
    //Helper to get the valid fields for updating ObjectPermissions.
    Public Static Map<String, Boolean> checkFieldType(String sObjName) {
         Map<String, Boolean> fieldMap = new Map<String, Boolean>();
        for (Schema.PicklistEntry p : fieldPermissions.Field.getDescribe().getPicklistValues()) {
            if (sObjName == p.getValue().split('\\.')[0]) {
                system.debug('p.getValue()'+p.getValue());
                system.debug('p.getValue().split'+p.getValue().split('\\.')[0]);
                fieldMap.put(p.getValue(), true);
            }
        }
        system.debug('fieldMap'+fieldMap);
        return fieldMap;
    }
                      
    @AuraEnabled
    //Helper method to get field names.
    Public Static Map<String, Map<String, Object>> getFieldDefinitionProfile(String objectName) {
       Map<String, Map<String, Object>> fieldDefMapByName = new Map<String, Map<String, Object>>();
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(objectName).getDescribe();
        
        for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
            Map<String, Object> fieldDefMap = new Map<String, Object>();
            fieldDefMap.put('Label', field.getDescribe().getLabel());
            fieldDefMap.put('Name', field.getDescribe().getName());
            fieldDefMap.put('isPermissionable',field.getDescribe().isPermissionable());
            fieldDefMap.put('isCalculated', field.getDescribe().isCalculated());
            String fieldNameKey = objectName + '.' + field.getDescribe().getName();
            fieldDefMapByName.put(fieldNameKey, fieldDefMap);
        }
        return fieldDefMapByName;
    }
    @AuraEnabled
    //Helper to get the valid Sobject for updating ObjectPermissions.
    Public Static Boolean checkSObjType(string sObjName) {
        Set < String > validSObjectTypes = new Set < String > ();
        for (Schema.PicklistEntry p: ObjectPermissions.SObjectType.getDescribe().getPicklistValues()) {
            validSObjectTypes.add(p.getValue());
        }
        return validSObjectTypes.contains(sObjName);
    }
    
    public class updatedObjPermResult {
        @AuraEnabled public Map<String, Object> objectPerms { get; private set; }
        @AuraEnabled public List<FieldPermissionUpdateWrapper> fieldPerms { get; private set; }

        public updatedObjPermResult(Map<String, Object> objectPerms, List<FieldPermissionUpdateWrapper> fieldPerms) {
        this.objectPerms = objectPerms;
        this.fieldPerms = fieldPerms;
        }
    }
    
    @AuraEnabled
    //This method is used for updating object permissions.
    public static updatedObjPermResult updateSobjectMeta(Map<String, Map<String, Boolean>> objectPermissionsMap, List<FieldPermissionUpdateWrapper> fieldPerms, String permSetId, String objName) {
    Map<String, Object> objResult = new Map<String, Object>();
    List<FieldPermissionUpdateWrapper> fieldResult = new List<FieldPermissionUpdateWrapper>();

    try {
        // Update object permissions if present
        if (!objectPermissionsMap.isEmpty()) {
            objResult = updateObjPermissions(objectPermissionsMap, permSetId);
        }

        // Update field permissions if present
        if (!fieldPerms.isEmpty()) {
            fieldResult = updateFieldPermissions(fieldPerms, permSetId, objName, '');
        }

        // Return the results
        return new updatedObjPermResult(objResult, fieldResult);
    } catch (Exception e) {
        handleException('Error updating SObject metadata: ', e);
        // Return an empty updatedObjPermResult in case of an exception
        return new updatedObjPermResult(new Map<String, Object>(), new List<FieldPermissionUpdateWrapper>());
    }
}
    
    @AuraEnabled
    //Helper method for updating object permissions.
    public static Map<String, ObjectPermissions> updateObjPermissions(Map<String, Map<String, Object>> objPerms, String permSetId) {
    if (permSetId == null || objPerms == null || objPerms.isEmpty()) {
        return new Map<String, ObjectPermissions>();
    }

    Map<String, ObjectPermissions> resultMap = new Map<String, ObjectPermissions>();
    try {
        // Query existing ObjectPermissions records for all objects at once
        Map<String, ObjectPermissions> existingPermMap = new Map<String, ObjectPermissions>();
        for (ObjectPermissions perm : [SELECT Id, ParentId, SobjectType, PermissionsCreate, PermissionsRead,
                                        PermissionsEdit, PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords
                                        FROM ObjectPermissions
                                        WHERE ParentId = :permSetId AND SobjectType IN :objPerms.keySet()]) {
            existingPermMap.put(perm.SobjectType, perm);
        }

        List<ObjectPermissions> objPermissionsToUpsert = new List<ObjectPermissions>();
        for (String objName : objPerms.keySet()) {
            Map<String, Object> permissionsMap = objPerms.get(objName);

            ObjectPermissions objToUpsert = existingPermMap.containsKey(objName) ? 
                                            existingPermMap.get(objName) : 
                                            new ObjectPermissions(ParentId = permSetId, SobjectType = objName);

            // Cast each individual permission to Boolean
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
    } catch (Exception e) {
        handleException('Error updating object permissions: ', e);
    }
    return resultMap;
}
    
    //Wrapper class to get field permissions.
    public class FieldPermissionUpdateWrapper {
        @AuraEnabled public String Field { get; set; }
        @AuraEnabled public Boolean PermissionsRead { get; set; }
        @AuraEnabled public Boolean PermissionsEdit { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Boolean hasEditAccess { get; set; }
        @AuraEnabled public Boolean mutedPermissionsRead { get; set; }
        @AuraEnabled public Boolean mutedPermissionsEdit { get; set; }

        public FieldPermissionUpdateWrapper() {}

        public FieldPermissionUpdateWrapper(String Field, Boolean PermissionsRead, Boolean PermissionsEdit, String label, Boolean hasEditAccess) {
            this.Field = Field;
            this.PermissionsRead = PermissionsRead;
            this.PermissionsEdit = PermissionsEdit;
            this.label = label;
            this.hasEditAccess = hasEditAccess;
        }
    }
    
    @AuraEnabled
    //Helper method for updating field permissions. 
    Public Static List<FieldPermissionUpdateWrapper> updateFieldPermissions(List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList,String permissionSetId,String objName,String fieldPermType) {
        if (permissionSetId == null || fieldPermissionWrapperList == null || fieldPermissionWrapperList.isEmpty()) {
            return null;
        }
    
        List < FieldPermissions > permissionsToUpsert = new List < FieldPermissions > ();
        Map < String, FieldPermissionUpdateWrapper > fieldWrapperMap = new Map < String, FieldPermissionUpdateWrapper > ();
        List< FieldPermissionUpdateWrapper > updatedFieldPermissions = new List< FieldPermissionUpdateWrapper >();
    
        for (FieldPermissionUpdateWrapper wrapper: fieldPermissionWrapperList) {
            fieldWrapperMap.put(wrapper.Field, wrapper);
        }
    
        Map < String, FieldPermissions > existingPermissionsMap = new Map < String, FieldPermissions > ();
        for (FieldPermissions fieldPerm: [SELECT Id, SObjectType, Field, PermissionsRead, PermissionsEdit
                FROM FieldPermissions
                WHERE ParentId =: permissionSetId AND Field IN: fieldWrapperMap.keySet()
            ]) {
            existingPermissionsMap.put(fieldPerm.Field, fieldPerm);
        }
    
        for (String fieldName: fieldWrapperMap.keySet()) {
            FieldPermissionUpdateWrapper wrapper = fieldWrapperMap.get(fieldName);
            FieldPermissions permission = existingPermissionsMap.containsKey(fieldName) ?
                existingPermissionsMap.get(fieldName) :
                new FieldPermissions(SObjectType = objName, Field = fieldName, ParentId = permissionSetId);
    
            if (fieldPermType != 'MutePermission') {
                permission.PermissionsRead = wrapper.PermissionsRead;
                permission.PermissionsEdit = wrapper.PermissionsEdit;
            } else{
                permission.PermissionsRead = wrapper.mutedPermissionsRead;
                permission.PermissionsEdit = wrapper.mutedPermissionsEdit;
            }
    
            permissionsToUpsert.add(permission);
            updatedFieldPermissions.add(wrapper);
        }
        
       
        Map<String,Boolean> checkAccessLevelForFieldPermissions = PermissionAnalyzerServer.getObjDefinition('FieldPermissions');
    if (!permissionsToUpsert.isEmpty() && checkAccessLevelForFieldPermissions.get('Create') 
        && checkAccessLevelForFieldPermissions.get('Update')) {
            try {
                upsert permissionsToUpsert;
                return updatedFieldPermissions;
            } catch (Exception e) {
                handleException('An error occurred while upserting Field Permissions: ', e);
            }
        }    
        return null;
    }

	Private Static Void handleException(String message, Exception e) {
        system.debug('e.getMessage'+ e.getMessage());
        String fullMessage = e == null ? message : message + ': ' + e.getMessage();
        System.debug(LoggingLevel.ERROR, fullMessage);
        throw new AuraHandledException(fullMessage);
    }    
}