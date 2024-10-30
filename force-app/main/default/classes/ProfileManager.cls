//This class is used for edit,delete,update Profiles.
Public Class ProfileManager {
  
  //This method is used to fetch profile name.
  @AuraEnabled(cacheable=true)
   //This method is used to fetch profile name.
  Public Static List<String> getProfileName(String ProfileId) {
    UserAccessManager instance = new UserAccessManager();
    List<String> profileName = new List<String>();
    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
    String toolingQuery =
      '/services/data/v58.0/tooling/query/?q=select+id,+Name,+FullName+from+Profile+where+Id=\'' +
      ProfileId +
      '\'';
    String endPoint = baseUrl + toolingQuery;
    Http newReq = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endPoint);
    req.setMethod('GET');
    req.setHeader(
      'Authorization',
      'Bearer ' + instance.partnerConnection.SessionHeader.sessionId
    );
    req.setHeader('Content-Type', 'application/json');
    HttpResponse res = new HttpResponse();
    try {
      res = newReq.send(req);
      if (res.getStatusCode() == 200) {
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
          res.getBody()
        );
        List<Object> records = (List<Object>) results.get('records');
        for (Object record : records) {
          Map<String, Object> recordMap = (Map<String, Object>) record;
          profileName.add((String) recordMap.get('FullName'));
        }
      } else {
        System.debug('Error: ' + res.getStatus());
        System.debug('Response: ' + res.getBody());
      }
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
    }
    System.debug('profileName: ' + profileName);
    return profileName;
  }
  
  //This method is used to update profile property.
  @AuraEnabled
  public static Map < String, String > updateProfile(String profileName, String newProfileName, String newDescription) {
      System.debug('profileName: ' + profileName);
      System.debug('newProfileName: ' + newProfileName);
      System.debug('newDescription: ' + newDescription);
  
      UserAccessManager instance = new UserAccessManager();
      Map < String, String > returnMap = new Map < String, String > ();
      List < MetadataService.Profile > profiles = (List < MetadataService.Profile > ) instance.service.readMetadata('Profile', new List < String > {
          profileName
      }).getRecords();
      if (!profiles.isEmpty() && profiles[0].fullName != null) {
          MetadataService.Profile updatedProfile = new MetadataService.Profile();
          updatedProfile.fullName = newProfileName;
          updatedProfile.description = newDescription;
          MetadataService.UpsertResult[] results = instance.service.upsertMetadata(new List < MetadataService.Profile > {
              updatedProfile
          });
          if (!results.isEmpty()) {
              MetadataService.UpsertResult upsertResult = results[0];
              if (upsertResult.success) {
                  System.debug('Profile updated successfully for: ' + upsertResult.fullName);
                  returnMap.put('label', upsertResult.fullName);
                  returnMap.put('description', newDescription);
              } else {
                  String errorMessage = 'Error updating profile: ' + (upsertResult.errors != null && !upsertResult.errors.isEmpty() ? upsertResult.errors[0].message : 'Unknown error');
                  handleException(errorMessage, null);
              }
          }
      }
      System.debug('Return map: ' + returnMap);
      return returnMap;
  }
    
  //This method is used for delete functionality in profile.
  @AuraEnabled
  public static void deleteProfile(String profileName) {
      if (String.isBlank(profileName)) {
          handleException('Profile name cannot be blank.', null);
      }
      try {
          UserAccessManager instance = new UserAccessManager();
          MetadataService.DeleteResult[] deleteResults = instance.service.deleteMetadata('Profile', new List < String > {
              profileName
          });

          if (deleteResults == null || deleteResults.isEmpty()) {
              handleException('No response received from delete operation.', null);
          }
          MetadataService.DeleteResult deleteResult = deleteResults[0];
          if (!deleteResult.success) {
              String errorMessage = deleteResult.errors != null && !deleteResult.errors.isEmpty() ?
                  deleteResult.errors[0].message :
                  'Unknown error occurred during profile deletion.';
                handleException('Failed to delete profile: ', null);
          }

          System.debug('Successfully deleted profile: ' + deleteResult.fullName);
      } catch (Exception e) {
          System.debug(LoggingLevel.ERROR, 'Error in deleteProfile: ' + e.getMessage());
          handleException('An error occurred while deleting the profile: ', e);
      }
  }
    
  //Wrapper class to fetch users list & profile name
  public class UserAndProfileDetails {
      @AuraEnabled public List<User> userList { get; private set; }
      @AuraEnabled public String profileName { get; private set; }
      public UserAndProfileDetails(List<User> userList, String profileName) {
        this.userList = userList;
        this.profileName = profileName;
      }
    }
    
    // This method is used to fetch profile-related users.
    @AuraEnabled(cacheable=true)
    public static UserAndProfileDetails getProfileUsers(String profId) {
        List<User> users = [
            SELECT Id, Name, Username, Profile.UserLicense.Name, IsActive 
            FROM User 
            WHERE ProfileId = :profId AND IsActive = TRUE 
            ORDER BY Name ASC
        ];
        
        // Get the profile name as a single string
        String profileName = ProfileManager.getProfileName(profId).isEmpty() 
            ? '' 
            : ProfileManager.getProfileName(profId)[0];
        
        return new UserAndProfileDetails(users, profileName);
    }
    
    //This method retrieves permission sets associated with profiles.
    @AuraEnabled(cacheable=true)    
    public static List<PermissionSet> getProfileDetails() {
        return [
            SELECT 
                Id, 
                ProfileId, 
                Profile.Name, 
                Profile.UserLicense.Name, 
                Profile.Description, 
                Profile.UserType, 
                IsOwnedByProfile, 
                IsCustom 
            FROM PermissionSet 
            WHERE IsOwnedByProfile = TRUE 
            ORDER BY Profile.Name ASC
        ];
    }
    
    //This method retrieves tab visibility settings for each profile.
    @AuraEnabled
    Public Static List<Map<String, Object>> getProfileTabSetting(List<String> profileName) {
        List<Map<String, Object>> tabSettingMapList = new List<Map<String, Object>>();
        Map<String, String> tabVisibilities = getTabPermissions(profileName);
        List<TabDefinition> tabDefList = [SELECT id, Name, Label FROM TabDefinition ORDER BY Label ASC];
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
    //Helper to get tab permissions for each profile.
    Public Static Map<String, String> getTabPermissions(List<String> profileName) {
        UserAccessManager instance = new UserAccessManager();
        List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata('Profile',profileName).getRecords();
        Map<String, String> tabSettingObj = new Map<String, String>();
        if (profiles != null) {
            try {
                for (MetadataService.Profile prof : profiles) {
                    if (prof.tabVisibilities != null) {
                        for (
                            MetadataService.ProfileTabVisibility tabVisibility : prof.tabVisibilities
                        ) {
                            tabSettingObj.put(tabVisibility.tab, tabVisibility.visibility);
                        }
                    }
                }
            } catch (exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        system.debug('check tab setting' + tabSettingObj);
        return tabSettingObj;
        
    }
    
      @AuraEnabled
      public static ProfileObjectPermissionsWrapper getSobjectPermissionsForProfile(String permSetId, String objName) {
          // Fetch dependencies and field access in parallel
          List < Object > dependObjects = ProfileManager.checkDependency(objName);
          Map < String, Boolean > fieldAccess = ProfileManager.checkFieldType(objName);
      
          // Get field definitions
          Map < String, Map < String, Object >> fieldDefMapByName = ProfileManager.getFieldDefinitionProfile(objName);
      
          // Query field permissions in bulk
          Map < String, FieldPermissions > fieldPermissionsMap = new Map < String, FieldPermissions > ();
          for (FieldPermissions fieldPerm: [SELECT Field, PermissionsRead, PermissionsEdit
                  FROM FieldPermissions
                  WHERE ParentId =: permSetId AND SObjectType =: objName
              ]) {
              fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
          }
      
          List < Map < String, Object >> fieldPermissionsMapList = new List < Map < String, Object >> ();
          for (String fieldKey: fieldDefMapByName.keySet()) {
              Map < String, Object > fieldDefMap = fieldDefMapByName.get(fieldKey);
              if ((Boolean) fieldDefMap.get('isPermissionable') && fieldAccess.get(fieldKey) == true) {
                  Map < String, Object > fieldPermissionMap = new Map < String, Object > {
                      'Field' => fieldKey,
                      'label' => fieldDefMap.get('Label'),
                      'hasEditAccess' => fieldDefMap.get('isCalculated')
                  };
                  FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
                  if (fieldPerm != null) {
                      fieldPermissionMap.put('PermissionsRead', fieldPerm.PermissionsRead);
                      fieldPermissionMap.put('PermissionsEdit', fieldPerm.PermissionsEdit);
                  } else {
                      fieldPermissionMap.put('PermissionsRead', false);
                      fieldPermissionMap.put('PermissionsEdit', false);
                  }
                  fieldPermissionsMapList.add(fieldPermissionMap);
              }
          }
      
          return new ProfileObjectPermissionsWrapper(
              fieldPermissionsMapList,
              ProfileManager.checkSObjType(objName),
              dependObjects
          );
      }
    
    //Helper method to fetch dependencies for object.
    @AuraEnabled
    public static List < Object > checkDependency(String objName) {
        UserAccessManager instance = new UserAccessManager();
        List < Object > allDependencies = new List < Object > ();

        // Fetch dependencies for the given object
        fetchDependencies(objName, allDependencies, instance.partnerConnection.SessionHeader.sessionId, URL.getSalesforceBaseUrl().toExternalForm());

        // Extract object names from Permission and RequiredPermission fields
        Set < String > objNamesSet = new Set < String > ();
        for (Object record: allDependencies) {
            Map < String, Object > recordMap = (Map < String, Object > ) record;
            objNamesSet.add(((String) recordMap.get('Permission')).substringBefore('<'));
            objNamesSet.add(((String) recordMap.get('RequiredPermission')).substringBefore('<'));
        }
        // Query FieldDefinition based on objNamesSet
        Set < String > matchingObjNamesSet = new Set < String > ();
        for (FieldDefinition fieldDef: [SELECT EntityDefinition.QualifiedApiName
                FROM FieldDefinition
                WHERE IsPolymorphicForeignKey = TRUE
                AND EntityDefinition.QualifiedApiName IN: objNamesSet
            ]) {
            matchingObjNamesSet.add(fieldDef.EntityDefinition.QualifiedApiName);
        }

        // Filter allDependencies based on the query result
        List < Object > filteredDependencies = new List < Object > ();
        for (Object record: allDependencies) {
            Map < String, Object > recordMap = (Map < String, Object > ) record;
            String permission = (String) recordMap.get('Permission');
            String requiredPermission = (String) recordMap.get('RequiredPermission');
            String objNameFromPermission = permission != null ? permission.split('<')[0] : null;
            String objNameFromReqPermission = requiredPermission != null ? requiredPermission.split('<')[0] : null;
            if (!matchingObjNamesSet.contains(objNameFromPermission) && !matchingObjNamesSet.contains(objNameFromReqPermission)) {
              filteredDependencies.add(record);
            }
        }

        System.debug('Filtered Dependencies: ' + filteredDependencies);
        System.debug('Filtered Dependencies: ' + filteredDependencies.size());
        return filteredDependencies;
    }
	
    //Wrapper class to fetch object & field permissions.
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

    Private Static Void fetchDependencies(String objName, List < Object > allDependencies, String sessionId, String serverUrl) {
      if (String.isBlank(objName)) {
          return;
      }
  
      Set < String > permissions = new Set < String > {
          'read',
          'edit',
          'delete',
          'create',
          'ViewAllRecords',
          'ModifyAllRecords'
      };
      Set < String > formattedPermissions = new Set < String > ();
      for (String perm: permissions) {
          formattedPermissions.add('\'' + objName + '<' + perm + '>\'');
      }
  
      String query = 'SELECT Id, Permission, RequiredPermission ' +
          'FROM PermissionDependency ' +
          'WHERE (Permission IN :formattedPermissions ' +
          'OR RequiredPermission IN :formattedPermissions) ' +
          'AND PermissionType = \'Object Permission\' ' +
          'AND RequiredPermissionType = \'Object Permission\'';
      List < Object > queryResults = sendQueryRequest(query, sessionId, serverUrl);
  
      Set < String > parentObjects = new Set < String > ();
      Set < String > childObjects = new Set < String > ();
      for (Object record: queryResults) {
          Map < String, Object > recordMap = (Map < String, Object > ) record;
          allDependencies.add(record);
          String permission = (String) recordMap.get('Permission');
          String requiredPermission = (String) recordMap.get('RequiredPermission');
          if (permission != null && permission.startsWith(objName)) {
              parentObjects.add('\'' + requiredPermission + '\'');
          }
          if (requiredPermission != null && requiredPermission.startsWith(objName)) {
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

    //Helper to get the valid fields for updating ObjectPermissions.
    @AuraEnabled
    public static Map < String, Boolean > checkFieldType(String sObjName) {
        Map < String, Boolean > fieldMap = new Map < String, Boolean > ();
        String prefix = sObjName + '.';

        for (Schema.PicklistEntry p: fieldPermissions.Field.getDescribe().getPicklistValues()) {
            String value = p.getValue();
            if (value.startsWith(prefix)) {
                fieldMap.put(value, true);
            }
        }
        return fieldMap;
    }
    
    //Helper to get valid field name.
    @AuraEnabled
    //Helper to get valid field name.
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
    
    //Helper to get parent object dependencies
    private static void processParentObjects(List < String > parentObjects, List < Object > allDependencies, String sessionId, String serverUrl) {
      if (parentObjects.isEmpty()) {
          return;
      }
      String parentObjNames = String.join(parentObjects, ',');
      String query = 'SELECT Id, Permission, RequiredPermission ' +
          'FROM PermissionDependency ' +
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
    
    //Helper to get parent object dependencies
    private static void processChildObjects(List < String > childObjects, List < Object > allDependencies, String sessionId, String serverUrl) {
      if (childObjects.isEmpty()) {
          return;
      }
      String childObjNames = String.join(childObjects, ',');
      System.debug('ChildObjName : ' + childObjNames);
  
      String query = 'SELECT Id, Permission, RequiredPermission ' +
          'FROM PermissionDependency ' +
          'WHERE RequiredPermission IN (' + childObjNames + ') ' +
          'AND PermissionType = \'Object Permission\' ' +
          'AND RequiredPermissionType = \'Object Permission\'';
  
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
    
    public static List<Object> sendQueryRequest(String query, String sessionId, String serverUrl) {
        String endpoint = serverUrl + '/services/data/v58.0/tooling/query?q=' + EncodingUtil.urlEncode(query, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + sessionId);
        req.setHeader('Content-Type', 'application/json');
        
        try {
            HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
          Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                return (List<Object>) responseMap.get('records') ?? new List<Object>();
        } else {
                System.debug('Error: ' + res.getStatus() + ' - ' + res.getBody());
        }
        } catch (Exception e) {
            System.debug('Exception occurred: ' + e.getMessage());
      }
        
        return new List<Object>();
    }
    
    //Helper to get valid sobject.
    @AuraEnabled
    public static Boolean checkSObjType(String sObjName) {
        return new Set < String > (new List < String > (Schema.getGlobalDescribe().keySet())).contains(sObjName);
    }
    //Wrapper class for user permissions & its dependencies.
    public class PermissionFieldWrap {
        @AuraEnabled public List < Map < String, Object >> userPermissions { get; set; }
        @AuraEnabled public List < Object > systemDependencies { get; set; }
        @AuraEnabled public Map < String, Object > objectPermissions { get; set; }

        public PermissionFieldWrap() {
            this.userPermissions = new List < Map < String, Object >> ();
            this.systemDependencies = new List < Object > ();
            this.objectPermissions = new Map < String, Object > ();
        }
    }
    
    //This method is used to retrieve system permissions & its dependencies of profile.
    @AuraEnabled(cacheable = true)
    public static PermissionFieldWrap getCombinedPermissionsforProfile(String permissionSetIds) {
        PermissionFieldWrap permissionWrap = new PermissionFieldWrap();

        // Fetch user permissions
        List < Map < String, Object >> userPermissionsList = getUserPermissions(permissionSetIds);
        permissionWrap.userPermissions = userPermissionsList;

        // Fetch system dependencies
        List < Object > dependSystemPermissions = ProfileManager.checkDependencyforSystemPermissions();
        permissionWrap.systemDependencies = dependSystemPermissions;

        // Extract dependent objects
        Set < String > dependentObjects = extractDependentObjects(dependSystemPermissions);

        // Fetch object permissions
        Map < String, Map < String, Object >> objectPermissionsMap = getObjectPermissions(permissionSetIds, dependentObjects);
        permissionWrap.objectPermissions = objectPermissionsMap;

        return permissionWrap;
    }

    private static List < Map < String, Object >> getUserPermissions(String permissionSetIds) {
      List < Map < String, Object >> userPermissionsList = new List < Map < String, Object >> ();
  
      String query = 'SELECT Id, Name, ' + String.join(getPermissionFields(), ', ') +
          ' FROM PermissionSet WHERE Id = :permissionSetIds';
  
      for (PermissionSet ps: Database.query(query)) {
          for (String fieldName: getPermissionFields()) {
              userPermissionsList.add(new Map < String, Object > {
                  'fieldName' => fieldName,
                  'fieldLabel' => Schema.SObjectType.PermissionSet.fields.getMap().get(fieldName).getDescribe().getLabel(),
                  'fieldValue' => ps.get(fieldName)
              });
          }
      }
  
      return userPermissionsList;
  }
  
  private static List < String > getPermissionFields() {
      List < String > permissionFields = new List < String > ();
      for (Schema.SObjectField field: Schema.SObjectType.PermissionSet.fields.getMap().values()) {
          String fieldName = field.getDescribe().getName();
          if (fieldName.startsWith('Permissions') && fieldName != 'Permissionsetgroupid') {
              permissionFields.add(fieldName);
          }
      }
      return permissionFields;
  }
  
  private static Set < String > extractDependentObjects(List < Object > dependSystemPermissions) {
      Set < String > dependentObjects = new Set < String > ();
      for (Object record: dependSystemPermissions) {
          Map < String, Object > recordMap = (Map < String, Object > ) record;
          if ((String) recordMap.get('RequiredPermissionType') == 'Object Permission') {
              String requiredPermission = (String) recordMap.get('RequiredPermission');
              dependentObjects.add(requiredPermission.split('<')[0]);
          }
      }
      return dependentObjects;
  }
  
  private static Map < String, Map < String, Object >> getObjectPermissions(String permissionSetIds, Set < String > dependentObjects) {
      Map < String, Map < String, Object >> objectPermissionsMap = new Map < String, Map < String, Object >> ();
  
      for (ObjectPermissions objPerm: [SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
              PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
              FROM ObjectPermissions
              WHERE ParentId =: permissionSetIds AND SObjectType IN: dependentObjects
          ]) {
          objectPermissionsMap.put(objPerm.SObjectType, new Map < String, Object > {
              'PermissionsCreate' => objPerm.PermissionsCreate,
              'PermissionsRead' => objPerm.PermissionsRead,
              'PermissionsEdit' => objPerm.PermissionsEdit,
              'PermissionsDelete' => objPerm.PermissionsDelete,
              'PermissionsViewAllRecords' => objPerm.PermissionsViewAllRecords,
              'PermissionsModifyAllRecords' => objPerm.PermissionsModifyAllRecords
          });
      }
  
      return objectPermissionsMap;
  }
    
  //Helper method to get dependent user permissions.
  @AuraEnabled(cacheable = true)
  public static List < Object > checkDependencyforSystemPermissions() {
      String query = 'SELECT Id, Permission, RequiredPermission, PermissionType, RequiredPermissionType ' +
          'FROM PermissionDependency ' +
          'WHERE PermissionType = \'User Permission\'';

      UserAccessManager instance = new UserAccessManager();
      String sessionId = instance.partnerConnection.SessionHeader.sessionId;
      String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

      return sendQueryRequest(query, sessionId, baseUrl);
  }

    @AuraEnabled
    public static Map<String, Boolean> updateSystemPermissionsProf(String profileName, Map<String, Boolean> systemPermissions) {
        UserAccessManager instance = new UserAccessManager();
        Map<String, Boolean> updatedResult = new Map<String, Boolean>();
        
        try {
            // Fetch the profile
            List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata('Profile', new List<String> { profileName }).getRecords();
            
            if (profiles.isEmpty()) {
                handleException('Profile not found: ', null);
            }
            
            MetadataService.Profile updatedProfile = new MetadataService.Profile();
            updatedProfile.fullName = profiles[0].fullName;
            updatedProfile.userPermissions = new List<MetadataService.ProfileUserPermission>();
            
            // Create user permissions
            for (String permissionName : systemPermissions.keySet()) {
                MetadataService.ProfileUserPermission userPermission = new MetadataService.ProfileUserPermission();
                userPermission.name = permissionName;
                userPermission.enabled = systemPermissions.get(permissionName);
                updatedProfile.userPermissions.add(userPermission);
            }
            
            // Upsert the updated profile
            MetadataService.UpsertResult[] results = instance.service.upsertMetadata(new List<MetadataService.Profile> { updatedProfile });
            
            if (results[0].success) {
                System.debug('Profile updated successfully for: ' + results[0].fullName);
                updatedResult.putAll(systemPermissions);
            } else {
                handleUpsertError(results[0]);
            }
        } catch (Exception e) {
            handleException('An error occurred while updating the profile: ', e);
        }
        
        System.debug('updatedResult: ' + updatedResult);
        return updatedResult;
    }


  private static void handleUpsertError(MetadataService.UpsertResult result) {
      String errorMessage = 'Error updating profile: ';
      for (MetadataService.Error error: result.errors) {
          errorMessage += error.message + ' (Status Code: ' + error.statusCode + ') ';
          if (error.fields != null) {
              errorMessage += 'Fields: ' + String.join(error.fields, ', ');
          }
      }
      handleException(errorMessage, null);
  }
    
  //Wrapper class for object level permissions.
  public class ProfileObjectDetails {
    @AuraEnabled public final List<EntityDefinition> entityDefList;
    @AuraEnabled public final Map<String, Object> objectPermissions;
    public ProfileObjectDetails(List<EntityDefinition> entityDefList, Map<String, Object> objectPermissions) {
      this.entityDefList = entityDefList;
      this.objectPermissions = objectPermissions;
    }
  }
 
  //This method is used to retrieve object-level permissions for a specific profile.
  @AuraEnabled
  public static ProfileObjectDetails getProfileObjectDetails(String permId) {
    Map < String, Map < String, Boolean >> objectPermissionsMap = new Map < String, Map < String, Boolean >> ();

    if (String.isNotBlank(permId)) {
        for (ObjectPermissions objPerm: [
                SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
                PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                FROM ObjectPermissions
                WHERE ParentId =: permId
            ]) {
            objectPermissionsMap.put(objPerm.SObjectType, new Map < String, Boolean > {
                'PermissionsCreate' => objPerm.PermissionsCreate,
                'PermissionsRead' => objPerm.PermissionsRead,
                'PermissionsEdit' => objPerm.PermissionsEdit,
                'PermissionsDelete' => objPerm.PermissionsDelete,
                'PermissionsViewAllRecords' => objPerm.PermissionsViewAllRecords,
                'PermissionsModifyAllRecords' => objPerm.PermissionsModifyAllRecords
            });
        }
    }

    return new ProfileObjectDetails([
        SELECT Id, Label, QualifiedApiName, NameSpacePrefix
        FROM EntityDefinition
        WHERE DefaultCompactLayoutId != NULL
    ], objectPermissionsMap);
  }
  
  private static void handleException(String message, Exception e) {
      String fullMessage = e == null ? message : message + ': ' + e.getMessage();
      System.debug(LoggingLevel.ERROR, fullMessage);
      throw new AuraHandledException(fullMessage);
  }
    
}