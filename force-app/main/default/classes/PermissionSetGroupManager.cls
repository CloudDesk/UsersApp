//This class is used for create,edit,delete,clone functionality for Permission Set Group.
Public with sharing Class PermissionSetGroupManager {
	
  @AuraEnabled(cacheable=true)
  //This method is used to fetch permission set group details.
  Public Static List<permissionSetGroupWrapper> getPermissionSetGrp() {
      Map<String, List<PermissionSetGroupComponent>> permSetCompMap = new Map<String, List<PermissionSetGroupComponent>>();
      List<permissionSetGroupWrapper> permissionSetGroupWithLicense = new List<permissionSetGroupWrapper>();
      
      // Query all PermissionSetGroupComponents
      for (PermissionSetGroupComponent permSetComp : [SELECT Id, PermissionSetId, PermissionSet.License.Name, PermissionSetGroupId FROM PermissionSetGroupComponent where PermissionSet.License.Name != NULL limit 5000]) {
        if (!permSetCompMap.containsKey(permSetComp.PermissionSetGroupId)) {
          permSetCompMap.put(permSetComp.PermissionSetGroupId, new List<PermissionSetGroupComponent>());
        }
        permSetCompMap.get(permSetComp.PermissionSetGroupId).add(permSetComp);
      }
      
      // Query all PermissionSetGroups
      for (PermissionSetGroup permSetGrp : [SELECT Id, DeveloperName, MasterLabel, Description, Status, NamespacePrefix, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate FROM PermissionSetGroup ORDER BY MasterLabel ASC limit 5000]) {
          Set<String> licenseList = new Set<String>();
          
          if (permSetCompMap.containsKey(permSetGrp.Id)) {
              for (PermissionSetGroupComponent permSetGrpComp : permSetCompMap.get(permSetGrp.Id)) {
                licenseList.add(permSetGrpComp.PermissionSet.License.Name);
              }
              
          }
          permissionSetGroupWrapper permSetGrpWrapper = new permissionSetGroupWrapper();
          permSetGrpWrapper.perSetGrpId = permSetGrp.Id;
          permSetGrpWrapper.DeveloperName = permSetGrp.DeveloperName;
          permSetGrpWrapper.MasterLabel = permSetGrp.MasterLabel;
          permSetGrpWrapper.Description = permSetGrp.Description;
          permSetGrpWrapper.Status = permSetGrp.Status;
          permSetGrpWrapper.NamespacePrefix = permSetGrp.NamespacePrefix;
          permSetGrpWrapper.CreatedById = permSetGrp.CreatedById;
          permSetGrpWrapper.CreatedByName = permSetGrp.CreatedBy.Name;
          permSetGrpWrapper.CreatedDate = permSetGrp.CreatedDate;
          permSetGrpWrapper.LastModifiedById = permSetGrp.LastModifiedById;
          permSetGrpWrapper.LastModifiedByName = permSetGrp.LastModifiedBy.Name;
          permSetGrpWrapper.LastModifiedDate = permSetGrp.LastModifiedDate;
          permSetGrpWrapper.sameLicense = licenseList.size() <= 1;
          permissionSetGroupWithLicense.add(permSetGrpWrapper);
          
      }
      System.debug('permissionSetGroupWithLicense' + permissionSetGroupWithLicense);
      System.debug('permissionSetGroupWithLicense size: ' + permissionSetGroupWithLicense.size());
      return permissionSetGroupWithLicense;
  }
  
  //wrapper class to fetch permission set group details.
  Public class PermissionSetGroupWrapper{
      @AuraEnabled Public String perSetGrpId { get; set;}
      @AuraEnabled Public String DeveloperName { get; set;}
      @AuraEnabled Public String MasterLabel { get; set;}
      @AuraEnabled Public String Description { get; set;}
      @AuraEnabled Public String Status { get; set;}
      @AuraEnabled Public String NamespacePrefix { get; set;}
      @AuraEnabled Public String CreatedById { get; set;}
      @AuraEnabled Public String CreatedByName { get; set;}
      @AuraEnabled Public Datetime CreatedDate { get; set;}
      @AuraEnabled Public String LastModifiedById { get; set;}
      @AuraEnabled Public String LastModifiedByName { get; set;}
      @AuraEnabled Public Datetime LastModifiedDate { get; set;}
      @AuraEnabled Public Boolean sameLicense { get; set;}
  }
  
  @AuraEnabled(cacheable=false)
  //This method is used for creation of permission set group.
  Public Static Void createPermissionSetGroup(String label, String apiName, String description, List<String> permissionSetIds, Boolean isRequired) {
      try {
        // Create Permission Set Group
          PermissionSetGroup newGroup = new PermissionSetGroup(
              MasterLabel = label,
              DeveloperName = apiName.replaceAll(' ', '_'),
              Description = description,
              HasActivationRequired = isRequired
          );
        insert newGroup;

        // Assign Permission Sets to the Permission Set Group
        List<PermissionSetGroupComponent> groupComponents = new List<PermissionSetGroupComponent>();
        for (String permissionSetId : permissionSetIds) {
              groupComponents.add(new PermissionSetGroupComponent(
                  PermissionSetGroupId = newGroup.Id,
                  PermissionSetId = permissionSetId
              ));
        }
        insert groupComponents;
      } catch (Exception e) {
          handleException('Error creating Permission Set Group: ', e);
      }
    }
  
  @AuraEnabled
  //This method is used for editing permission set group.
  Public Static PermissionSetGroup editPermissionSetGrp(String perSetId, String label, String apiName, String description, String format) {
      system.debug('Input params: perSetId=' + perSetId + ', label=' + label + ', apiName=' + apiName + ', description=' + description + ', format=' + format);
      PermissionSetGroup perSet;
      String query = 'SELECT id, DeveloperName, MasterLabel, Description, Status, NamespacePrefix, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate FROM PermissionSetGroup WHERE ';
      try {
          if (format == 'group') {
              query += 'id = :perSetId LIMIT 1';
              perSet = Database.query(query);
          } else if (format == 'permission set') {
              String permissionSetGroupId = [SELECT PermissionSetGroupId FROM PermissionSet WHERE id =: perSetId LIMIT 1].PermissionSetGroupId;
              if (permissionSetGroupId == null) {
                  handleException('No PermissionSetGroup found for the provided PermissionSet ID.', null);
              }
              query += 'id = :permissionSetGroupId LIMIT 1';
              perSet = Database.query(query);
          } else {
              handleException('Invalid format provided. Must be "group" or "permission set".', null);
          }
          if (perSet != null) {
              perSet.MasterLabel = label;
              perSet.DeveloperName = apiName;
              perSet.Description = description;
              update perSet;
          }
      } catch (Exception e) {
          handleException('Error processing PermissionSetGroup: ', e);
      }
      
      return perSet;
  }
  
  @AuraEnabled
  // This method is used for cloning permission set group along with permission sets.
  Public Static Void clonePermissionSetGroup(String sourcePermissionSetGroupName,String newLabel,String newApiName,String newDescription) {
      try {
          // Fetch the source Permission Set Group
          PermissionSetGroup sourcePSG = [SELECT Id, MasterLabel, DeveloperName, Description FROM PermissionSetGroup WHERE MasterLabel = :sourcePermissionSetGroupName LIMIT 1];
          
          // Create a new Permission Set Group
          PermissionSetGroup newPSG = new PermissionSetGroup();
          newPSG.MasterLabel = newLabel;
          newPSG.DeveloperName = newApiName.replaceAll(' ', '_');
          newPSG.Description = newDescription;
          insert newPSG;
          
          // Fetch the newly created Permission Set Group ID
          Id newPSGId = newPSG.Id;
          
          // Clone Permission Set Group Components
          List<PermissionSetGroupComponent> sourceComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :sourcePSG.Id];
          Set<Id> permissionSetIds = new Set<Id>();
          for (PermissionSetGroupComponent component : sourceComponents) {
              permissionSetIds.add(component.PermissionSetId);
              system.debug('Permission Set Ids' + component);
          }
          system.debug('First Permission Set Ids' + permissionSetIds);
          Set<Id> newpermissionSetIds = new Set<Id>();
          List<PermissionSet> perset = [SELECT Id FROM PermissionSet WHERE Id IN :permissionSetIds];
          for (PermissionSet component : perset) {
              newpermissionSetIds.add(component.Id);
              system.debug('Second Permission Set Ids' + component);
          }
          system.debug('Third Permission Set Ids' + newpermissionSetIds);
          List<PermissionSetGroupComponent> newComponents = new List<PermissionSetGroupComponent>();
          for (Id component : newpermissionSetIds) {
              PermissionSetGroupComponent newComponent = new PermissionSetGroupComponent();
              newComponent.PermissionSetGroupId = newPSGId;
              newComponent.PermissionSetId = component;
              newComponents.add(newComponent);
          }
          insert newComponents;
          
          //Get User
          List<PermissionSetAssignment> assignedUsers = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId = :sourcePSG.Id];
          Set<Id> assignedUserIds = new Set<Id>();
          for (PermissionSetAssignment psa : assignedUsers) {
              assignedUserIds.add(psa.AssigneeId);
          }
          List<User> userList = [SELECT id,Name,Username,Profile.Name,IsActive,Profile.UserLicense.Name FROM user WHERE IsActive = TRUE AND Id IN :assignedUserIds];
          Set<Id> userids = new Set<Id>();
          for (User psa : userList) {
              userids.add(psa.id);
          }
          System.debug('User IDs to be assigned: ' + userids);
          //Users Assign
          List<PermissionSetAssignment> persetasi = new List<PermissionSetAssignment>();
          for (Id assignId : userids) {
              PermissionSetAssignment perasi = new PermissionSetAssignment();
              perasi.AssigneeId = assignId;
              perasi.PermissionSetGroupId = newPSGId;
              persetasi.add(perasi);
          }
          System.debug('Permission Set Assignments to insert: ' + persetasi);
          
          try {
              insert persetasi;
          } catch (DmlException e) {
              handleException('Error cloning Permission Set Group: ', e);
          }
      } catch (Exception e) {
          handleException('Error cloning Permission Set Group: ', e);
      }
  }

  
  // This method is used to delete permission set group.
  @AuraEnabled
  Public Static Void deletePermissionSetGroupWithUnassignments(String permissionSetGroupId) {
      try {
          // Step 1: Retrieve all related records in a single query
          List<PermissionSetAssignment> assignmentsToDelete = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId = :permissionSetGroupId];
          List<PermissionSetGroupComponent> componentsToDelete = [SELECT Id FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :permissionSetGroupId];
          PermissionSetGroup permissionSetGroupToDelete = [SELECT Id FROM PermissionSetGroup WHERE Id = :permissionSetGroupId];
          
          // Step 2: Perform bulk DML operations
          List<SObject> recordsToDelete = new List<SObject>();
          recordsToDelete.addAll(assignmentsToDelete);
          recordsToDelete.addAll(componentsToDelete);
          recordsToDelete.add(permissionSetGroupToDelete);
          
          if (!recordsToDelete.isEmpty()) {
              delete recordsToDelete;
              System.debug('Permission Set Group and related records deleted successfully.');
          } else {
              System.debug('No records found for the Permission Set Group.');
          }
      } catch (Exception e) {
          handleException('Error deleting Permission Set Group: ', e);
      }
  }
  
  //This method is used to show list of users for Permission Set group to assign.
  @AuraEnabled
  Public Static List<User> getUserPermissionSetGroup(String profileName, String userLicense, String perSetGrpId_tofetch) {
      // Fetch assigned users
      List<PermissionSetAssignment> assignedUsers = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId = :perSetGrpId_tofetch];
      Set<Id> assignedUserIds = new Set<Id>();
      for (PermissionSetAssignment psa : assignedUsers) {
          assignedUserIds.add(psa.AssigneeId);
      }
      
      // Start constructing the query
      String query = 'SELECT Id, Name, Username, Profile.Name, IsActive, Profile.UserLicense.Name ' +
          'FROM User ' +
          'WHERE IsActive = true AND Id NOT IN :assignedUserIds';
      
      // Sanitize inputs to prevent SOQL injection
      if (String.isNotBlank(profileName) && profileName != 'All') {
          query += ' AND Profile.Name = \'' + String.escapeSingleQuotes(profileName) + '\'';
      }
      
      if (String.isNotBlank(userLicense) && userLicense != 'All') {
          query += ' AND Profile.UserLicense.Name = \'' + String.escapeSingleQuotes(userLicense) + '\'';
      }
      
      query += ' ORDER BY Name ASC limit 5000';
      
      // Execute the query
      List<User> userList = Database.query(query);
      System.debug('userList >>> ' + userList);
      return userList;
  }


  
  @AuraEnabled
  //This method is used to assign users to Permission Set Groups, retrieve users assigned to groups, and list users who are eligible to be assigned to a group.
  Public Static Void getPermissionGroup(List<String> userId,String perGrp_Id) {
      List<PermissionSetAssignment> persetasi = new List<PermissionSetAssignment>();
      for (String assignId : userId) {
          PermissionSetAssignment perasi = new PermissionSetAssignment();
          perasi.AssigneeId = assignId;
          perasi.PermissionSetGroupId = perGrp_Id;
          persetasi.add(perasi);
      }
      
      try {
          insert persetasi;
          System.debug('Permission Set Group assigned successfully to all users');
      } catch (DmlException e) {
          handleException('Error in fetching Permission Set Group: ', e);
      }
  }
  
  @AuraEnabled
  //This method is used to retrieve list of users who are already assigned to a specified Permission Set Group.
  Public Static List<User> getPermissionSetGroup(String perSetGrp_Id) {
      List<PermissionSetAssignment> persetaList = [SELECT PermissionSetGroupId, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId = :perSetGrp_Id];
      Set<Id> userIds = new Set<Id>();
      for (PermissionSetAssignment perseta : persetaList) {
          userIds.add(perseta.AssigneeId);
      }
      List<User> users = [SELECT id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE Id IN :userIds ORDER BY Name ASC limit 5000];
      return users;
  }
  
  @AuraEnabled
  // This method deletes the assignments of users from a specified Permission Set Group.
  Public Static Void deletePermissionGroup(List<String> userId,String delPerGrpId) {
      List<PermissionSetAssignment> persetAssignForDlt = [SELECT id FROM PermissionSetAssignment WHERE AssigneeId IN :userId AND PermissionSetGroupId = :delPerGrpId];
      try {
          delete persetAssignForDlt;
          System.debug('Permission Set Group Deleted successfully for the users');
      } catch (DmlException e) {
          handleException('Error in deleting Permission Set Group: ', e);
      }
  }
  
  @AuraEnabled
  //This method is used to retrieve profiles.
  Public Static List<Profile> getProfiles() {
      return [SELECT id, Name, UserLicense.Name FROM Profile ORDER BY name ASC limit 5000];
  }
  
  @AuraEnabled
  //This method is used to retrieve Permission set list.
  Public Static List<PermissionSet> getPermissionSet(String permissionSetGroupId, String searchperset) {
      String typeValue = 'Group';
      List<PermissionSetGroupComponent> groupComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :permissionSetGroupId];    
      Set<Id> permissionSetIds = new Set<Id>();
      for (PermissionSetGroupComponent component : groupComponents) {
          permissionSetIds.add(component.PermissionSetId);
      }
      
      String query = 'SELECT Id, Name, Label, Description, LicenseId, License.Name, IsCustom, CreatedById, ' +
          'CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate, NamespacePrefix ' +
          'FROM PermissionSet ' +
          'WHERE Id NOT IN :permissionSetIds AND IsOwnedByProfile = false AND Type != \'' + typeValue + '\'';
      
      // Sanitize and add the search filter if present
      if (String.isNotBlank(searchperset)) {
          String searchName = '%' + String.escapeSingleQuotes(searchperset) + '%';
          query += ' AND Label LIKE \'' + searchName + '\'';
      }      
      query += ' ORDER BY Label ASC limit 5000';
      List<PermissionSet> perset = Database.query(query);
      return perset;
  }

  
  @AuraEnabled
  //This method is used to assign permission set to permission set group.
  Public Static Void insertPermissionSet(List<String> permissionSetId,String permissionSetGroupId) {
      List<PermissionSetGroupComponent> persetasi = new List<PermissionSetGroupComponent>();
      for (String permissionId : permissionSetId) {
          PermissionSetGroupComponent perasi = new PermissionSetGroupComponent();
          perasi.PermissionSetId = permissionId;
          perasi.PermissionSetGroupId = permissionSetGroupId;
          persetasi.add(perasi);
      }
      try {
          insert persetasi;
          System.debug('Permission Set Group assigned successfully to Permission Set');
      } catch (DmlException e) {
          handleException('Error in creating Permission Set Group: ', e);
      }
  }
  
  @AuraEnabled
  //This method is used to unassign permission set from permission set group.
  Public Static Void deletePermissionSet(List<String> permissionSetId,String delPerSetId) {
      List<PermissionSetGroupComponent> persetAssignForDlt = [SELECT id FROM PermissionSetGroupComponent WHERE PermissionSetId IN :permissionSetId AND PermissionSetGroupId = :delPerSetId];
      try {
          delete persetAssignForDlt;
          System.debug(
              'Permission Set Group Deleted successfully for the PermissionSet'
          );
      } catch (DmlException e) {
          handleException('Error deleting Permission Set Group components', e);
      }
  }
  
  @AuraEnabled
  //This method is used to fetch assigned permission set list related to permission set group.
  Public Static List<PermissionSet> getAssignedPermissionSet(String permissionSetGroupId) {
      List<PermissionSetGroupComponent> groupComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :permissionSetGroupId];
      Set<Id> permissionSetIds = new Set<Id>();
      for (PermissionSetGroupComponent component : groupComponents) {
          permissionSetIds.add(component.PermissionSetId);
      }
      List<PermissionSet> perset = [SELECT Id,Name,Label,Description,License.Name,IsCustom,CreatedById,CreatedBy.Name,CreatedDate,LastModifiedById,LastModifiedBy.Name,LastModifiedDate FROM PermissionSet WHERE Id IN :permissionSetIds AND IsOwnedByProfile = FALSE ORDER BY Label ASC limit 5000];
      return perset;
  }
  
  @AuraEnabled(cacheable=true)
  //This method is used to fetch permission sets.
  Public Static List<Map<String, String>> getSetPermission() {
      
      List<Map<String, String>> result = new List<Map<String, String>>();    
      // Query PermissionSets
      List<PermissionSet> permissionSets = [SELECT Id, Name, Label, Description, IsCustom, NamespacePrefix, CreatedDate, LastModifiedDate,License.Name, CreatedBy.Name, LastModifiedBy.Name FROM PermissionSet WHERE IsOwnedByProfile = false AND Type != 'Group'];
      for (PermissionSet ps : permissionSets) {
          Map<String, String> recordMap = new Map<String, String>();
          recordMap.put('Id', ps.Id);
          recordMap.put('Name', ps.Name);
          recordMap.put('Label', ps.Label);
          recordMap.put('Description', ps.Description);
          recordMap.put('IsCustom', String.valueOf(ps.IsCustom));
          recordMap.put('NamespacePrefix', ps.NamespacePrefix);
          recordMap.put('CreatedDate', String.valueOf(ps.CreatedDate));
          recordMap.put('LastModifiedDate', String.valueOf(ps.LastModifiedDate));
          
          // License information
          if (ps.License != null) {
              recordMap.put('LicenseId', ps.License.Id);
              recordMap.put('LicenseName', ps.License.Name);
              System.debug('License Name >> ' + ps.License.Name);
          } else {
              System.debug('License Name not found for Permission set ID: ' + ps.Id);
          }
          
          // Created By information
          if (ps.CreatedBy != null) {
              recordMap.put('CreatedById', ps.CreatedBy.Id);
              recordMap.put('CreatedByName', ps.CreatedBy.Name);
              System.debug('Createdby Name >> ' + ps.CreatedBy.Name);
          } else {
              System.debug('CreatedBy Name not found for Permission set ID: ' + ps.Id);
          }
          
          // Last Modified By information
          if (ps.LastModifiedBy != null) {
              recordMap.put('LastModifiedById', ps.LastModifiedBy.Id);
              recordMap.put('LastModifiedByName', ps.LastModifiedBy.Name);
              System.debug('Permission Set Id >> ' + ps.Id);
              System.debug('LastModby Name >> ' + ps.LastModifiedBy.Name);
          } else {
              System.debug('LastModifiedBy Name not found for Permission set ID: ' + ps.Id);
          }      
          result.add(recordMap);
      }  
      return result;
  }
  
  @AuraEnabled(cacheable=true)
  //This method is used to fetch permission set lists.
  Public Static List<PermissionSet> getProfileDetails() {
      return [SELECT Id,ProfileId,Profile.Name,Profile.UserLicense.Name,Profile.Description,Profile.UserType,IsOwnedByProfile,isCustom FROM Permissionset WHERE IsOwnedByProfile = TRUE ORDER BY Profile.Name ASC limit 5000];
  }
  
  @AuraEnabled
  //This method is used to display assigned users in permission set group.
  Public Static List<user> getUnAssignedUserForPermissionSet(String permissionSetId,String profileName,String userLicense,String licenseName) {
      System.debug('License Name>>>>' + licenseName);
      System.debug('Permission Set>>>>' + permissionSetId);
      System.debug('Profile Name>>>>' + profileName);
      System.debug('User License>>>>' + userLicense);
      
      // Query PermissionSetAssignment using standard SOQL
      List<PermissionSetAssignment> permissionSetAssignments = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Id = :permissionSetId];
      Set<Id> assigneeIds = new Set<Id>();
      for (PermissionSetAssignment psa : permissionSetAssignments) {
          if (psa.AssigneeId != null) {
              assigneeIds.add(psa.AssigneeId);
          }
      }
      // Convert Set<Id> to List<String> for backwards compatibility
      List<String> assigneeIdsList = new List<String>();
      for (Id id : assigneeIds) {
          assigneeIdsList.add(id);
      }
      // Constructing the dynamic query
      String query = 'SELECT Id, Name, Username, Profile.Name, IsActive, Profile.UserLicense.Name ' +
          'FROM User ' +
          'WHERE IsActive = true AND Id NOT IN :assigneeIdsList';
      
      if (String.isNotBlank(profileName) && profileName != 'All') {
          query += ' AND Profile.Name = :profileName';
      }
      if (String.isNotBlank(licenseName)) {
          query += ' AND Profile.UserLicense.Name = :licenseName';
          System.debug('NOT NULL >>>');
      }
      query += ' ORDER BY Name ASC limit 5000';
      List<User> userList = Database.query(query);
      System.debug('userList >>>' + userList);
      return userList;
  }
  
  @AuraEnabled(cacheable=true)
  //This method is used to check duplicate label & api name while creating new permission set group.
  Public Static Boolean checkDuplicatePermissionSetGroup(String label,String apiName) {
      List<PermissionSetGroup> existingSets = [SELECT Id FROM PermissionSetGroup WHERE MasterLabel = :label OR DeveloperName = :apiName];
      return existingSets.size() > 0;
  }
  
  //Wrapper class for system,object,muted Object,field,muted field permissions.
  Public Class UserObjAndFieldPermissionSetGroupWrapper {
  @AuraEnabled Public List<CombinedPermissionsWrapper> combinedPermissions { get; set; }
  @AuraEnabled Public Map<String, ObjectPermissions> objectPermissions { get; set; }
  @AuraEnabled Public Map<String, ObjectPermissions> mutingobjectPermissions { get; set; }
  @AuraEnabled Public Map<String, List<fieldPermissions>> fieldPermissions { get; set; }
  @AuraEnabled Public Map<String, List<fieldPermissions>> mutingfieldPermissions { get;set; }
  @AuraEnabled Public List<TabDefinition> tabsetting { get; set; }

  Public UserObjAndFieldPermissionSetGroupWrapper(
    List<CombinedPermissionsWrapper> combinedPermissions,
    Map<String, ObjectPermissions> objectPermissions,
    Map<String, ObjectPermissions> mutingobjectPermissions,
    Map<String, List<fieldPermissions>> fieldPermissions,
    Map<String, List<fieldPermissions>> mutingfieldPermissions,
    List<TabDefinition> tabsetting
  ) {
    this.combinedPermissions = combinedPermissions;
    this.objectPermissions = objectPermissions;
    this.mutingobjectPermissions = mutingobjectPermissions;
    this.fieldPermissions = fieldPermissions;
    this.mutingfieldPermissions = mutingfieldPermissions;
    this.tabsetting = tabsetting;
  }
}
  
  Public Class CombinedPermissionsWrapper {
  @AuraEnabled Public String fieldName;
  @AuraEnabled Public String fieldLabel;
  @AuraEnabled Public Object fieldValue;
  @AuraEnabled Public Object mutedValue;
  @AuraEnabled Public String mutedId;
  @AuraEnabled Public Boolean hasDependencies;
  @AuraEnabled Public List<String> requiredPermissions;
  @AuraEnabled Public List<TabPermissionWrapper> tabPermissions;
  

  Public CombinedPermissionsWrapper(String fieldName,String fieldLabel,Object fieldValue,Object mutedValue,String mutedId) {
    this.fieldName = fieldName;
    this.fieldLabel = fieldLabel;
    this.fieldValue = fieldValue;
    this.mutedValue = mutedValue;
    this.mutedId = mutedId;
    this.hasDependencies = false;
    this.requiredPermissions = new List<String>();
    tabPermissions = new List<TabPermissionWrapper>();
    
  }
}
  
 Public Class TabPermissionWrapper {
  @AuraEnabled Public String tabName { get; set; }
  @AuraEnabled Public String visibility { get; set; }

  Public TabPermissionWrapper(String tabName, String visibility) {
    this.tabName = tabName;
    this.visibility = visibility;
  }
}
  
  //Helper method for checking dependencies.
  Private Static Map<String, List<String>> checkForDependencies(Set<String> fieldNames,Boolean isUpdateSystemPermissions) {
  system.debug(fieldNames);
  system.debug(isUpdateSystemPermissions);
  Map<String, List<String>> fieldPermissionsMap = new Map<String, List<String>>();
  if (fieldNames.isEmpty()) {
    return fieldPermissionsMap;
  }

  List<String> quotedFieldNames = new List<String>();
  for (String fieldName : fieldNames) {
    quotedFieldNames.add('\'' + fieldName + '\'');
  }
  system.debug(quotedFieldNames);
  String query;
  if (isUpdateSystemPermissions) {
    string usertype = 'User Permission';
    query =
      'SELECT RequiredPermission, Permission FROM PermissionDependency WHERE Permission IN (' +
      String.join(quotedFieldNames, ',') +
      ') AND RequiredPermissionType = \'' +
      usertype +
      '\'';
  } else {
    query =
      'SELECT RequiredPermission, Permission FROM PermissionDependency WHERE RequiredPermission IN (' +
      String.join(quotedFieldNames, ',') +
      ')';
  }
  system.debug('QUery' + query);

  UserAccessManager instance = new UserAccessManager();

  String endpoint =
    URL.getSalesforceBaseUrl().toExternalForm() + 
    '/services/data/v58.0/tooling/query?q=' +
    EncodingUtil.urlEncode(query, 'UTF-8');
  HttpRequest req = new HttpRequest();
  req.setEndpoint(endpoint);
  req.setMethod('GET');
  //req.setHeader('Authorization', 'Bearer ' + sessionInfoObj.sessionId);
  req.setHeader('Authorization','Bearer ' + instance.partnerConnection.SessionHeader.sessionId);
  req.setHeader('Content-Type', 'application/json');
  Http http = new Http();
  HttpResponse res = http.send(req);

  if (res.getStatusCode() == 200) {
    Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );
    List<Object> records = (List<Object>) result.get('records');
    system.debug('Records--->' + records);
    for (Object record : records) {
      Map<String, Object> recordMap = (Map<String, Object>) record;
      if (isUpdateSystemPermissions) {
        String requiredPermission = ((String) recordMap.get('Permission'));
        String permission = (String) recordMap.get('RequiredPermission');
        if (!fieldPermissionsMap.containsKey(requiredPermission)) {
          fieldPermissionsMap.put(requiredPermission, new List<String>());
        }
        fieldPermissionsMap.get(requiredPermission).add(permission);
      } else {
        String requiredPermission = ((String) recordMap.get(
          'RequiredPermission'
        ));
        String permission = (String) recordMap.get('Permission');
        if (!fieldPermissionsMap.containsKey(requiredPermission)) {
          fieldPermissionsMap.put(requiredPermission, new List<String>());
        }
        fieldPermissionsMap.get(requiredPermission).add(permission);
      }
    }
  } else {
    System.debug('Error: ' + res.getBody());
  }
  system.debug('fieldPermissionsMap' + fieldPermissionsMap);
  return fieldPermissionsMap;
}

  
  @AuraEnabled(cacheable=false)
  //This method is used to get user permissions/system permissions for permission set. 
  Public Static UserObjAndFieldPermissionSetGroupWrapper getCombinedPermissions(String permissionSetGroupId,string persetapi,string persetname) {
      
      List<CombinedPermissionsWrapper> combinedPermissions = new List<CombinedPermissionsWrapper>();
      String baseQueryString = 'SELECT Id, Name';
      Map<String, Schema.SObjectField> baseFields = Schema.SObjectType.PermissionSet.fields.getMap();
      
      // Build the query string and collect permission fields
      
      for (Schema.SObjectField field : baseFields.values()) {
          String fieldName = field.getDescribe().getName();
          if (fieldName.startsWith('Permissions') && fieldName != 'Permissionsetgroupid') {
              baseQueryString += ', ' + field;
              String fieldLabel = field.getDescribe().getLabel();
              combinedPermissions.add(
                  new CombinedPermissionsWrapper(fieldName,fieldLabel,null,null,null)
              ); // Initialize with null
          }
      }
      
      // Retrieve permission sets related to the permission set group
      List<PermissionSetGroupComponent> groupComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent
                                                           WHERE PermissionSetGroupId = :permissionSetGroupId
                                                          ];
      Set<Id> permissionSetIds = new Set<Id>();
      for (PermissionSetGroupComponent component : groupComponents) {
          permissionSetIds.add(component.PermissionSetId);
      }
      
      baseQueryString += ' FROM PermissionSet WHERE Id IN :permissionSetIds';
      List<PermissionSet> basePermissionSets = (List<PermissionSet>) Database.query(
          baseQueryString
      );
      
      // Logging values of each permission field
      for (PermissionSet basePermissionSet : basePermissionSets) {
          for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
              String fieldName = wrapper.fieldName;
              Object fieldValue = basePermissionSet.get(fieldName);
              wrapper.fieldValue = fieldValue;
              
          }
      }
      
      String nullValue = '%_%';
      list<PermissionSetGroupComponent> per = [SELECT id,PermissionSetId,PermissionSet.Name,PermissionSetGroupId,PermissionSetGroup.DeveloperName FROM PermissionSetGroupComponent
                                               WHERE
                                               PermissionSetGroupId = :permissionSetGroupId
                                               AND (NOT PermissionSet.Name LIKE :nullValue)
                                              ];
      String ids;
      for (PermissionSetGroupComponent pe : per) {
          system.debug(pe);
          ids = pe.PermissionSetId;
      }
      Map<String, Schema.SObjectField> baseMuteFields = Schema.SObjectType.MutingPermissionSet.fields.getMap();
      system.debug('Mute Fields--->' + baseMuteFields);
      String baseMuteString = 'SELECT Id, DeveloperName';
      
      for (String fieldName : baseMuteFields.keySet()) {
          if (fieldName.startsWith('permissions')) {
              baseMuteString += ', ' + fieldName;
          }
      }
      baseMuteString += ' FROM MutingPermissionSet WHERE Id =: ids';
      List<MutingPermissionSet> mute = Database.query(baseMuteString);
      
      // Map muted values to the corresponding permission fields
      for (MutingPermissionSet mutePermissionSet : mute) {
          for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
              String fieldName = wrapper.fieldName;
              Object mutedValue = mutePermissionSet.get(wrapper.fieldName);
              wrapper.mutedValue = mutedValue;
              wrapper.mutedId = mutePermissionSet.Id;
          }
      }
      
      // Collect field names for batch processing
      Set<String> requiredPermissionFields = new Set<String>();
      for (CombinedPermissionsWrapper wrapper : combinedPermissions) {    
          String initialRequiredPermission = wrapper.fieldName.remove('Permissions');
          requiredPermissionFields.add(initialRequiredPermission);     
      }
      system.debug('Length--->' + requiredPermissionFields.size());
      system.debug('Set-->' + requiredPermissionFields);
      
      // Perform batch callouts
      Map<String, List<String>> fieldPermissionsMap = checkForDependencies(requiredPermissionFields,false);
      system.debug('Field Permission map in main method' + fieldPermissionsMap);
      for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
          String initialRequiredPermission = wrapper.fieldName.remove('Permissions');
          if (fieldPermissionsMap.containskey(initialRequiredPermission)) {
              system.debug('Inside If');
              wrapper.hasDependencies = true;
              wrapper.requiredPermissions.addAll(
                  fieldPermissionsMap.get(initialRequiredPermission)
              );
          }
      }
      
      Set<String> seenPermissions = new Set<String>(); // To track seen permission names
      List<CombinedPermissionsWrapper> truePermissions = new List<CombinedPermissionsWrapper>();
      for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
          
          // Check if we have already added this permission (by fieldName) to truePermissions
          if (!seenPermissions.contains(wrapper.fieldName)) {
              truePermissions.add(wrapper);
              seenPermissions.add(wrapper.fieldName); // Mark this permission as seen
              
          }
      }
      
      // Retrieve tab permissions
      List<PermissionSetTabSetting> tabSettings = [SELECT Name, Visibility FROM PermissionSetTabSetting WHERE ParentId IN :permissionSetIds];
      Set<String> seenTabs = new Set<String>(); // Track seen tab names to remove duplicates
      for (PermissionSetTabSetting tabSetting : tabSettings) {
          String visibility = tabSetting.Visibility;
          String tabName = tabSetting.Name;
          if (!seenTabs.contains(tabName)) {
              seenTabs.add(tabName);
              for (CombinedPermissionsWrapper wrapper : truePermissions) {
                  wrapper.tabPermissions.add(
                      new TabPermissionWrapper(tabName, visibility)
                  );
              }
          }
      }
      System.debug('Retrieved Tab Permissions: ' + truePermissions);
      system.debug('combined permissions ' + combinedPermissions);
      system.debug('permissionFields' + truePermissions);
      
      Map<string, ObjectPermissions> objectPermissions = PermissionSetGroupManager.getObjectPermissionsforPSG(permissionSetGroupId);
      Map<string, ObjectPermissions> mutingobjectPermissions = PermissionSetGroupManager.getmutingObjectPermissionsforPSG(permissionSetGroupId,persetapi,persetname);
      Map<String, List<fieldPermissions>> fieldPermissions = PermissionSetGroupManager.getFieldPermissionspsg(permissionSetGroupId);
      Map<String, List<fieldPermissions>> mutingfieldPermissions = PermissionSetGroupManager.getmutingFieldPermissionspsg(permissionSetGroupId);
      List<TabDefinition> tabsetting = [SELECT id, Name, SobjectName FROM TabDefinition];
      
      system.debug('Object Permission' + objectPermissions);
      system.debug('Mute Object Permission' + mutingobjectPermissions);
      system.debug('Field Permission' + fieldPermissions);
      system.debug('Mute Field Permission' + mutingfieldPermissions);
      system.debug('Tab Setting' + tabsetting);
      
      return new userObjAndFieldPermissionSetGroupWrapper(truePermissions,objectPermissions,mutingobjectPermissions,fieldPermissions,mutingfieldPermissions,tabsetting);
  }
  
  @AuraEnabled
  //Helper method to retrieve object permissions of group.
  Public Static Map<String, ObjectPermissions> getObjectPermissionsforPSG(String parent_persetgrpid)
  {
  Map<String, ObjectPermissions> objMap = new Map<String, ObjectPermissions>();
  List<ObjectPermissions> objPermissions = [SELECT SobjectType,PermissionsRead,PermissionsCreate,PermissionsEdit,PermissionsDelete,PermissionsViewAllRecords,PermissionsModifyAllRecords
    FROM ObjectPermissions
    WHERE Parent.PermissionSetGroupId = :parent_persetgrpid
  ];

  for (ObjectPermissions obj : objPermissions) {
    if (!objMap.containsKey(obj.SobjectType)) {
      objMap.put(obj.SobjectType, obj);
    }
  }
  system.debug(objMap);
  return objMap;
}
  
  @AuraEnabled
  //Helper method to get muted object permissions.
  Public Static Map<String, ObjectPermissions> getmutingObjectPermissionsforPSG(String muting_persetgrpid,String psgapiname,String psgname)
  {
  Map<String, ObjectPermissions> objMap = new Map<String, ObjectPermissions>();

  String nullValue = '%_%';
  list<PermissionSetGroupComponent> per = [SELECT id,PermissionSetId,PermissionSet.Name,PermissionSetGroupId,PermissionSetGroup.DeveloperName
    FROM PermissionSetGroupComponent
    WHERE PermissionSetGroupId = :muting_persetgrpid AND (NOT PermissionSet.Name LIKE :nullValue)];
  String perSet_ids;
  for (PermissionSetGroupComponent pe : per) {
    system.debug(pe);
    perSet_ids = pe.PermissionSetId;
  }

  List<MutingPermissionSet> mpsList = [SELECT id FROM MutingPermissionSet WHERE id = :perSet_ids];
  MutingPermissionSet mutingPermissionSet;

  if (!mpsList.isEmpty()) {
    mutingPermissionSet = mpsList[0];
    perSet_ids = mutingPermissionSet.Id;
    system.debug('Id' + perSet_ids);
  } else {
    mutingPermissionSet = new MutingPermissionSet();
    mutingPermissionSet.MasterLabel = psgname + ' Muted';
    mutingPermissionSet.DeveloperName = psgapiname + '_Muted';
    insert mutingPermissionSet;

    system.debug('Id' + mutingPermissionSet.Id);
    perSet_ids = mutingPermissionSet.Id;

    PermissionSetGroup psGroup = [SELECT Id FROM PermissionSetGroup WHERE Id = :muting_persetgrpid LIMIT 1];
    PermissionSetGroupComponent component = new PermissionSetGroupComponent(
      PermissionSetGroupId = psGroup.Id,
      PermissionSetId = mutingPermissionSet.Id
    );
    insert component;
  }

  List<ObjectPermissions> objPermissions = [SELECT SobjectType,PermissionsRead,PermissionsCreate,PermissionsEdit,PermissionsDelete,PermissionsViewAllRecords,PermissionsModifyAllRecords
    FROM ObjectPermissions
    WHERE ParentId = :perSet_ids
  ];

  for (ObjectPermissions obj : objPermissions) {
    if (!objMap.containsKey(obj.SobjectType)) {
      objMap.put(obj.SobjectType, obj);
    }
  }
  system.debug(objMap);
  return objMap;
}
  
// Mute System Permissions for Permission Set Group.
@AuraEnabled
public static List<MutingPermissionSet> mutePermissions(String systemPermissionsMapJson,String psgname,String psgapiname,String psgid) {

  // Deserialize JSON to a map
  Map<String, Object> tempMap = (Map<String, Object>) JSON.deserializeUntyped(systemPermissionsMapJson);
  Map<String, Map<String, Object>> systemPermissionsMap = new Map<String, Map<String, Object>>();

  // Convert each entry to the expected map structure
  for (String key : tempMap.keySet()) {
    systemPermissionsMap.put(key, (Map<String, Object>) tempMap.get(key));
  }

  List<MutingPermissionSet> mpsListToInsert = new List<MutingPermissionSet>();
  String mutingId;
  MutingPermissionSet mutingPermissionSet;
  Map<String, Object> permissionsMap = new Map<String, Object>();

  // Check if the map contains any specific key and process accordingly
  if (systemPermissionsMap.containsKey('')) {
    System.debug('Empty');
    mutingPermissionSet = new MutingPermissionSet();
    mutingPermissionSet.MasterLabel = psgname + ' Muted';
    mutingPermissionSet.DeveloperName = psgapiname + '_Muted';
    insert mutingPermissionSet;

    System.debug('Id: ' + mutingPermissionSet.Id);
    mutingId = mutingPermissionSet.Id;

    PermissionSetGroup psGroup = [SELECT Id FROM PermissionSetGroup WHERE Id = :psgid LIMIT 1];
    PermissionSetGroupComponent component = new PermissionSetGroupComponent(PermissionSetGroupId = psGroup.Id,PermissionSetId = mutingPermissionSet.Id);
    insert component;

    for (String systemId : systemPermissionsMap.keySet()) {
      Map<String, Object> fieldMap = systemPermissionsMap.get(systemId);
      for (String fieldApi : fieldMap.keySet()) {
        Object isChecked = fieldMap.get(fieldApi);
        permissionsMap.put(fieldApi, isChecked);
      }
    }
  } else {
    System.debug('Not Empty');
    for (String systemId : systemPermissionsMap.keySet()) {
      mutingId = systemId;
      Map<String, Object> fieldMap = systemPermissionsMap.get(systemId);
      for (String fieldApi : fieldMap.keySet()) {
        Object isChecked = fieldMap.get(fieldApi);
        permissionsMap.put(fieldApi, isChecked);
      }
    }
  }

  System.debug('Muting Id: ' + mutingId);

  List<String> validPermissions = new List<String>();
  // Retrieve the valid fields of MutingPermissionSet dynamically
  Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.MutingPermissionSet.fields.getMap();

  for (String permission : permissionsMap.keySet()) {
    if (fieldsMap.containsKey(permission)) {
      validPermissions.add(permission);
    } else {
      System.debug('Field ' + permission + ' is not available on MutingPermissionSet.');
    }
  }

  if (validPermissions.isEmpty()) {
    System.debug('No valid permissions to update.');
    return mpsListToInsert;
  }

  // Build dynamic query
  String fieldsList = 'Id, ' + String.join(validPermissions, ',');
  String query = 'SELECT ' + fieldsList + ' FROM MutingPermissionSet WHERE Id = :mutingId';
  List<MutingPermissionSet> mpsList = Database.query(query);

  if (!mpsList.isEmpty()) {
    mutingPermissionSet = mpsList[0];
    for (String permission : validPermissions) {
      mutingPermissionSet.put(permission, permissionsMap.get(permission));
    }
    mpsListToInsert.add(mutingPermissionSet);

    try {
      update mpsListToInsert;
      System.debug('MutingPermissionSets successfully updated.');
      return mpsListToInsert; // Return only on successful update
    } catch (DmlException e) {
      handleException('Error updating MutingPermissionSet: ', e);
    }
  } else {
    System.debug('No MutingPermissionSet found with Id: ' + mutingId);
  }
    return mpsListToInsert;
}
  
  @AuraEnabled
  //Helper method to get field permissions of group.
  Public Static Map<String, List<FieldPermissions>> getFieldPermissionspsg(String persetgrpid) {

  List<FieldPermissions> fieldPermissions = [SELECT SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Parent.PermissionSetGroupId = :persetgrpid];
  Map<String, List<FieldPermissions>> fieldmap = new Map<String, List<FieldPermissions>>();
  for (FieldPermissions fie : fieldPermissions) {
    if (!fieldmap.containsKey(fie.SObjectType)) {
      fieldmap.put(fie.SObjectType, new List<FieldPermissions>());
    }
    fieldmap.get(fie.SObjectType).add(fie);
  }

  return fieldmap;
}
  
  @AuraEnabled
  //Helper method to get muted field permissions of group.
  Public Static Map<String, List<fieldPermissions>> getmutingFieldPermissionspsg(String persetgrpid_toMute) {
  String nullValue = '%_%';
  list<PermissionSetGroupComponent> per = [SELECT id,PermissionSetId,PermissionSet.Name,PermissionSetGroupId,PermissionSetGroup.DeveloperName
    FROM PermissionSetGroupComponent
    WHERE
      PermissionSetGroupId = :persetgrpid_toMute
      AND (NOT PermissionSet.Name LIKE :nullValue)];
  String perSetGrpCmpIds;
  for (PermissionSetGroupComponent pe : per) {
    system.debug(pe);
    perSetGrpCmpIds = pe.PermissionSetId;
  }

  List<MutingPermissionSet> mpsList = [SELECT id FROM MutingPermissionSet WHERE id = :perSetGrpCmpIds];
  perSetGrpCmpIds = mpsList[0].Id;

  List<FieldPermissions> fieldPermissions = [SELECT SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE ParentId = :perSetGrpCmpIds];
  Map<String, List<FieldPermissions>> fieldmap = new Map<String, List<FieldPermissions>>();

  for (FieldPermissions fie : fieldPermissions) {
    if (!fieldmap.containsKey(fie.SObjectType)) {
      fieldmap.put(fie.SObjectType, new List<FieldPermissions>());
    }
    fieldmap.get(fie.SObjectType).add(fie);
  }

  return fieldmap;
}
  
  @AuraEnabled
  //Helper method to get tab settings of group.
  public static List<Map<String, Object>> getTabSettingpsg(String persetname) {
      UserAccessManager ua_instance = new UserAccessManager();
      List<MetadataService.PermissionSetGroup> permSetGroupList = 
          (List<MetadataService.PermissionSetGroup>) ua_instance.service.readMetadata('PermissionSetGroup', new String[] {persetname}).getRecords();
      MetadataService.PermissionSetGroup permSetGroup = permSetGroupList[0];
      
      // Map to store unique tab settings (key: tab name, value: visibility)
      Map<String, String> uniqueTabSettings = new Map<String, String>();
      
      if (permSetGroup.permissionSets != null) {
          for (String permissionSetName : permSetGroup.permissionSets) {
              List<MetadataService.PermissionSet> permSetList = 
                  (List<MetadataService.PermissionSet>) ua_instance.service.readMetadata('PermissionSet', new String[] {permissionSetName}).getRecords();
              if (permSetList.size() > 0) {
                  MetadataService.PermissionSet permSet = permSetList[0];
                  if (permSet.tabSettings != null) {
                      for (MetadataService.PermissionSetTabSetting tabSetting : permSet.tabSettings) {
                          // Check if the tab is already in the map
                          if (!uniqueTabSettings.containsKey(tabSetting.tab)) {
                              uniqueTabSettings.put(tabSetting.tab, tabSetting.visibility);
                          }
                      }
                  } else {
                      System.debug('No tab settings found in the Permission Set: ' + permissionSetName);
                  }   
              } else {
                  System.debug('No Permission Sets found in the Permission Set Group.');
              }
          }
      }
      List<Map<String, Object>> tabSettingMapList = new List<Map<String, Object>>();
      
      List<TabDefinition> tabDefList = [SELECT id, Name, Label FROM TabDefinition ORDER BY Label ASC];
      system.debug('tabDefList' + tabDefList);
      if (!tabDefList.isEmpty()) {
          for (TabDefinition tabDef : tabDefList) {
              Map<String, Object> tabSettingMap = new Map<String, Object>();
              tabSettingMap.put('Label', tabDef.Label);
              tabSettingMap.put('Name', tabDef.Name);
              tabSettingMap.put('Visibility', uniqueTabSettings.get(tabDef.Name));
              tabSettingMapList.add(tabSettingMap);
          }
      }
      System.debug('tabSettingMap' + tabSettingMapList);
      return tabSettingMapList;
  }
  
  public class MutePermissionUpdateWrapper {
      @AuraEnabled public Map<string, Object> objectPermissions { get; set; }
      @AuraEnabled public List<FieldPermissionUpdateWrapper> fieldPermissions { get; set; }
      
      public MutePermissionUpdateWrapper(Map<string, Object> objectPermissions, List<FieldPermissionUpdateWrapper> fieldPermissions) {
          this.objectPermissions = objectPermissions;
          this.fieldPermissions = fieldPermissions;
      }
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
  
@AuraEnabled
//This method is used for updating muting permissions for group.
public static MutePermissionUpdateWrapper updateMutePermissions(string mutePermId,string permSetId,string objName,Map<String, Map<String, Boolean>> objPermission,
  List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList
) {
  Map<string, Object> objResult = new Map<String, Object>();
  List<FieldPermissionUpdateWrapper> fieldResult = new List<FieldPermissionUpdateWrapper>();
  if (objPermission != null) {
    objResult = PermissionSetGroupManager.updateObjPermissions(objPermission,mutePermId);
  }
  if (fieldPermissionWrapperList != null) {
    fieldResult = updateFieldPermissions(fieldPermissionWrapperList,mutePermId,objName,'MutePermissions');
  }
  MutePermissionUpdateWrapper objAndFieldPermResultWrapper = new MutePermissionUpdateWrapper(objResult,fieldResult);
  return objAndFieldPermResultWrapper;
}
  
  @AuraEnabled
  //Helper method to update object permissions.
  Public Static Map<String, Object> updateObjPermissions(Map<String, Map<String, Object>> objPerms,String permSetId)
  {
      Map<String, Object> resultMap = new Map<String, Object>();
      List<ObjectPermissions> objPermissionsToUpsert = new List<ObjectPermissions>();
      
      if (permSetId != null && objPerms != null && !objPerms.isEmpty()) {
          try {
              // Collect all object names from the input map
              Set<String> objNames = objPerms.keySet();
              
              // Query existing ObjectPermissions records for all objects at once
              List<ObjectPermissions> existingObjPerms = [SELECT Id,ParentId,SobjectType,PermissionsCreate,PermissionsRead,PermissionsEdit,PermissionsDelete,PermissionsModifyAllRecords,PermissionsViewAllRecords
                                                          FROM ObjectPermissions
                                                          WHERE ParentId = :permSetId AND SobjectType IN :objNames
                                                         ];
              
              // Create a map to easily find existing permissions by SobjectType
              Map<String, ObjectPermissions> existingPermMap = new Map<String, ObjectPermissions>();
              for (ObjectPermissions perm : existingObjPerms) {
                  existingPermMap.put(perm.SobjectType, perm);
              }
              
              // Iterate over the input map and prepare ObjectPermissions records for upsert
              for (String objName : objPerms.keySet()) {
                  // Get the permissions map for the current object
                  Map<String, Object> permissionsMap = objPerms.get(objName);
                  
                  ObjectPermissions objToUpsert;
                  if (existingPermMap.containsKey(objName)) {
                      // If the record exists, update it
                      objToUpsert = existingPermMap.get(objName);
                  } else {
                      // Otherwise, create a new ObjectPermissions record
                      objToUpsert = new ObjectPermissions();
                      objToUpsert.ParentId = permSetId;
                      objToUpsert.SobjectType = objName;
                  }
                  
                  // Set the permissions from the permissionsMap
                  objToUpsert.PermissionsCreate = (Boolean) permissionsMap.get('PermissionsCreate');
                  objToUpsert.PermissionsRead = (Boolean) permissionsMap.get('PermissionsRead');
                  objToUpsert.PermissionsEdit = (Boolean) permissionsMap.get('PermissionsEdit');
                  objToUpsert.PermissionsDelete = (Boolean) permissionsMap.get('PermissionsDelete');
                  objToUpsert.PermissionsModifyAllRecords = (Boolean) permissionsMap.get('PermissionsModifyAllRecords');
                  objToUpsert.PermissionsViewAllRecords = (Boolean) permissionsMap.get('PermissionsViewAllRecords');
                  
                  // Add to the list of records to upsert
                  objPermissionsToUpsert.add(objToUpsert);
                  
                  // Add the result to the resultMap
                  resultMap.put(objName, objToUpsert);
              }
              
              // Perform a bulk upsert of all ObjectPermissions records
              system.debug('objPermissionsToUpsert' + objPermissionsToUpsert);
              upsert objPermissionsToUpsert;
          } catch (Exception e) {
              handleException('Error updating Object Permissions: ', e);
          }
      }
      return resultMap;
  }
  
  @AuraEnabled
  //Helper method to update field permissions.
  Public Static List<FieldPermissionUpdateWrapper> updateFieldPermissions(List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList,String permissionSetId,String objName,String fieldPermType) {
      List<FieldPermissions> permissionsToUpsert = new List<FieldPermissions>();
      List<FieldPermissionUpdateWrapper> updatedFieldPermissions = new List<FieldPermissionUpdateWrapper>();
      Set<String> fieldNames = new Set<String>();
      if (permissionSetId != null && FieldPermissionWrapperList != null) {
          try {
              for (
                  FieldPermissionUpdateWrapper fieldPermWrapper : FieldPermissionWrapperList
              ) {
                  fieldNames.add(fieldPermWrapper.Field);
              }
              system.debug('field Names' + fieldNames);
              Map<String, FieldPermissions> existingPermissionsMap = new Map<String, FieldPermissions>();
              for (FieldPermissions fieldPerm : [SELECT Id, SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions
                                                 WHERE parentId = :permissionSetId AND Field IN :fieldNames
                                                ]) {
                                                    existingPermissionsMap.put(fieldPerm.Field, fieldPerm);
                                                }
              for (FieldPermissionUpdateWrapper fieldPermWrap : FieldPermissionWrapperList) {
                  FieldPermissions permission;
                  if (existingPermissionsMap.containsKey(fieldPermWrap.Field)) {
                      permission = existingPermissionsMap.get(fieldPermWrap.Field);
                  } else {
                      permission = new FieldPermissions();
                      permission.SObjectType = objName;
                      permission.Field = fieldPermWrap.Field;
                      permission.ParentId = permissionSetId;
                  }
                  if (fieldPermType != 'MutePermission') {
                      permission.PermissionsRead = fieldPermWrap.PermissionsRead;
                      permission.PermissionsEdit = fieldPermWrap.PermissionsEdit;
                  }
                  if (fieldPermType == 'MutePermissions') {
                      permission.PermissionsRead = fieldPermWrap.mutedPermissionsRead;
                      permission.PermissionsEdit = fieldPermWrap.mutedPermissionsEdit;
                  }
                  permissionsToUpsert.add(permission);
                  updatedFieldPermissions.add(fieldPermWrap);
              }
              system.debug(' check permissions to upsert' + permissionsToUpsert);
              system.debug(
                  'check updatedFieldPermissions: ' + updatedFieldPermissions
              );
              if (!permissionsToUpsert.isEmpty()) {
                  upsert permissionsToUpsert;
                  return updatedFieldPermissions;
              }
          } catch (exception e) {
              handleException('An error occurred while upserting Field Permissions: ', e);
          }
      }
      
      return null;
  }
  
  Public Class PermissionSetGroupObjectDetails {
  @AuraEnabled Public List<EntityDefinition> entityDefList { get; set; }
  @AuraEnabled Public Map<String, Object> objectPermissions { get; set; }
      
  Public PermissionSetGroupObjectDetails(List<EntityDefinition> entityDefList,Map<string, Object> objectPermissions) {
    this.entityDefList = entityDefList;
    this.objectPermissions = objectPermissions;
  }
}  

@AuraEnabled(cacheable=true)
//This method is used to get object permissions details.
Public Static PermissionSetGroupObjectDetails getSobject(String permId) {
  Map<String, Object> objectPermissionsMap = new Map<String, Object>();
  if (permId != null && permId != '') {
    for (ObjectPermissions objPerm : [SELECT Id,SObjectType,PermissionsRead,PermissionsCreate,PermissionsEdit,PermissionsDelete,PermissionsViewAllRecords,PermissionsModifyAllRecords
                    FROM ObjectPermissions WHERE Parent.PermissionSetGroup.Id = :permId]) 
  {
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
}
return new PermissionSetGroupObjectDetails([SELECT Id, Label, QualifiedApiName, NameSpacePrefix FROM EntityDefinition WHERE DefaultCompactLayoutId != NULL],objectPermissionsMap); 
}
  
  public class PermissionSetGroupObjectPermissionsWrapper {
  @AuraEnabled public List<Map<String, Object>> fieldPermissions { get; set; }
  @AuraEnabled public Boolean hasObjAccess { get; set; }
  @AuraEnabled public List<Object> objDependent { get; set; }
  @AuraEnabled public List<RecordType> recordTypeDetails { get; set; }
  @AuraEnabled public string MutedId { get; set; }

  public PermissionSetGroupObjectPermissionsWrapper(List<Map<String, Object>> fieldPermissions,Boolean hasObjAccess,List<Object> objDependent,
    List<RecordType> recordTypeDetails,
    string muteId
  ) {
    this.fieldPermissions = fieldPermissions;
    this.hasObjAccess = hasObjAccess;
    this.objDependent = objDependent;
    this.recordTypeDetails = recordTypeDetails;
    this.MutedId = muteId;
  }
}

@AuraEnabled
//This Method Used to retrieve fieldDefinition, valid Sobjects for Obj Permissions, Valid field for field Permissions and also fetch Object Permissons Dependencies
Public Static PermissionSetGroupObjectPermissionsWrapper getSobjectPermissionsForPermissionSetGroup(String permSetId,String objName,String psgname,String psgapiname) {
  System.debug('Perset Id' + permSetId);
  System.debug('Object Name' + objName);
  System.debug('PSG Name' + psgname);
  System.debug('PSG API Name' + psgapiname);
  Map<String, Boolean> fieldAccess = PermissionSetManager.checkFieldType(objName);
  system.debug('fieldAccess' + fieldAccess);

  string nullValue = '%_%';
  list<PermissionSetGroupComponent> per = [SELECT id,PermissionSetId,PermissionSet.Name,PermissionSetGroupId,PermissionSetGroup.DeveloperName FROM PermissionSetGroupComponent
    WHERE
      PermissionSetGroupId = :permSetId
      AND (NOT PermissionSet.Name LIKE :nullValue)
  ];
  string muteId;
  for (PermissionSetGroupComponent pe : per) {
    system.debug(pe);
    muteId = pe.PermissionSetId;
  }

  List<MutingPermissionSet> mpsList = [SELECT id FROM MutingPermissionSet WHERE id = :muteId];
  MutingPermissionSet mutingPermissionSet;

  if (!mpsList.isEmpty()) {
    mutingPermissionSet = mpsList[0];
    muteId = mutingPermissionSet.Id;
    system.debug('Mute Id' + muteId);
  } else {
    mutingPermissionSet = new MutingPermissionSet();
    mutingPermissionSet.MasterLabel = psgname + ' Muted';
    mutingPermissionSet.DeveloperName = psgapiname + '_Muted';
    insert mutingPermissionSet;
    system.debug('Id' + mutingPermissionSet.Id);

    muteId = mutingPermissionSet.Id;
    PermissionSetGroup psGroup = [SELECT Id FROM PermissionSetGroup WHERE Id = : permSetId LIMIT 1];
    PermissionSetGroupComponent component = new PermissionSetGroupComponent(
      PermissionSetGroupId = psGroup.Id,
      PermissionSetId = mutingPermissionSet.Id
    );
    insert component;
  }

  List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
  Map<String, Map<String, Object>> fieldDefMapByName = PermissionSetGroupManager.getFieldDefinitionProfile(objName);
  system.debug('Before Object Permission');  
  Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
  for (FieldPermissions fieldPerm : [SELECT SObjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE Parent.PermissionSetGroup.Id = :permSetId AND SObjectType = :objName]) {
    if (fieldPerm != null) {
      fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
    }
  }
  // Debug: Check the contents of fieldPermissionsMap
  System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);

  // Process each field definition
  for (String fieldKey : fieldDefMapByName.keySet()) {
    if (fieldKey != null) {
      if ((Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') && fieldAccess.get(fieldKey) == true) {
        Map<String, Object> fieldPermissionMap = new Map<String, Object>();
        fieldPermissionMap.put('Field', fieldKey);
        fieldPermissionMap.put('label',fieldDefMapByName.get(fieldKey).get('Label'));

        // Debug: Check if fieldKey is present in fieldPermissionsMap
        System.debug('Processing fieldKey: ' + fieldKey);
        if (fieldPermissionsMap.containsKey(fieldKey)) {
          FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
          fieldPermissionMap.put('PermissionsRead',fieldPerm.PermissionsRead);
          fieldPermissionMap.put('PermissionsEdit',fieldPerm.PermissionsEdit);
        } else {
          fieldPermissionMap.put('PermissionsRead', false);
          fieldPermissionMap.put('PermissionsEdit', false);
        }

        fieldPermissionMap.put('hasEditAccess',fieldDefMapByName.get(fieldKey).get('isCalculated'));
        fieldPermissionsMapList.add(fieldPermissionMap);
      }
    }
  }

  List<RecordType> recordTypeDetails = [SELECT Id, Name, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType = :objName ORDER BY Name ASC];    
  System.debug('check field permission map' + fieldPermissionsMapList);
  System.debug('check mute Id' + muteId);

  return new PermissionSetGroupObjectPermissionsWrapper(fieldPermissionsMapList,PermissionSetManager.checkSObjType(objName),PermissionAnalyzerObjectServer.checkObjectPermissionDependencies(objName),
    recordTypeDetails,
    muteId
  );
}
  
  @AuraEnabled
  //Helper method to fetch field names.
  Public Static Map<String, Map<String, Object>> getFieldDefinitionProfile(String objectName) 
  {
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

  Public Class MutePermissionWrapper {
  @AuraEnabled Public String mutePermSetId { get; set; }
  @AuraEnabled Public SObjectPermissionWrapper wrapper { get; set; }

  Public MutePermissionWrapper(String mutePermSetId,SObjectPermissionWrapper wrapper) {
    this.mutePermSetId = mutePermSetId;
    this.wrapper = wrapper;
  }
}
  
  Public Class SObjectPermissionWrapper {
  @AuraEnabled Public Map<String, Object> objectPermissions;
  @AuraEnabled Public Map<String, Object> fieldPermissions;
      
  Public SObjectPermissionWrapper(Map<String, Object> objectPermissions,Map<String, Object> fieldPermissions) {
    this.objectPermissions = objectPermissions != null ? objectPermissions : new Map<String, Object>();
    this.fieldPermissions = fieldPermissions != null ? fieldPermissions : new Map<String, Object>();
  }
  public SObjectPermissionWrapper() {
    this.objectPermissions = new Map<string, Object>();
    this.fieldPermissions = new Map<string, Object>();
  }
}
  
  @AuraEnabled
  //This method is used to retrieve object & field permissions.
  Public Static SObjectPermissionWrapper objAndFieldPermHelper(String permSetId,List<String> objNames,String objName) {
      system.debug('er set Id' + permSetId);
      Map<String, Object> permissionSetMap = new Map<String, Object>();
      Map<String, Object> fieldPermissionsMap = new Map<String, Object>();
      if (permSetId != null) {
          system.debug('inside perm set NOT null');
          for (objectPermissions objPerm : [SELECT Id,SObjectType,PermissionsCreate,PermissionsEdit,PermissionsRead,PermissionsDelete,PermissionsModifyAllRecords,
                                            PermissionsViewAllRecords
                                            FROM ObjectPermissions
                                            WHERE parentId = :permSetId AND SObjectType IN :objNames
                                           ]) {
                                               system.debug('check obj perm' + objPerm);
                                               if (objPerm != null) {
                                                   Map<String, Object> objectPermMap = new Map<String, Object>();
                                                   objectPermMap.put('SObjectType', objPerm.SObjectType);
                                                   objectPermMap.put('PermissionsRead', objPerm.PermissionsRead);
                                                   objectPermMap.put('PermissionsCreate', objPerm.PermissionsCreate);
                                                   objectPermMap.put('PermissionsEdit', objPerm.PermissionsEdit);
                                                   objectPermMap.put('PermissionsDelete', objPerm.PermissionsDelete);
                                                   objectPermMap.put('PermissionsViewAllRecords',objPerm.PermissionsViewAllRecords);
                                                   objectPermMap.put('PermissionsModifyAllRecords',objPerm.PermissionsModifyAllRecords);
                                                   permissionSetMap.put(objPerm.SObjectType, objectPermMap);
                                               }
                                           }
          for (FieldPermissions fieldPerm : [SELECT Id, Field, PermissionsRead, PermissionsEdit, SObjectType FROM FieldPermissions
                                             WHERE ParentId = :permSetId AND SObjectType = :objName
                                            ]) {
                                                system.debug('fieldPerm' + fieldPerm);
                                                if (fieldPerm != null) {
                                                    Map<String, Object> fieldPermission = new Map<String, Object>();
                                                    fieldPermission.put('PermissionsRead', fieldPerm.PermissionsRead);
                                                    fieldPermission.put('PermissionsEdit', fieldPerm.PermissionsEdit);
                                                    fieldPermission.put('Field', fieldPerm.Field);
                                                    fieldPermissionsMap.put(fieldPerm.Field, fieldPermission);
                                                }
                                            }
      }
      return new SObjectPermissionWrapper(permissionSetMap, fieldPermissionsMap);
  }
  
@AuraEnabled
//This method is used to retrieve muted object and field permissions.
Public Static MutePermissionWrapper getMutedObjandFieldPermissions(String groupId,List<String> objNames,String objName) {
  system.debug('check group id' + groupId);
  system.debug('objName' + objNames);
  String permSetId;
  if (groupId != null) {
    system.debug('Inside Not Null');
    List<PermissionSetGroupComponent> psgg = [SELECT Id,PermissionSetGroup.DeveloperName,PermissionSetGroup.MasterLabel,PermissionSetId FROM PermissionSetGroupComponent
      WHERE
        PermissionSetGroupId = :groupId
        AND (NOT PermissionSet.Name LIKE '%_%')
    ];
    system.debug('Per Set Grp Com' + psgg);
    if (!psgg.isEmpty()) {
      system.debug('inside not null');
      permSetId = psgg[0].PermissionSetId;
    }
    if (psgg.isEmpty()) {
      system.debug('inside null');

      // Fetch the permission set group
      PermissionSetGroup permSetGrp = [SELECT Id, MasterLabel, DeveloperName FROM PermissionSetGroup WHERE Id = :groupId LIMIT 1];

      if (permSetGrp != null) {
        // Create a new MutingPermissionSet
        MutingPermissionSet mutePerm = new MutingPermissionSet();
        mutePerm.MasterLabel = permSetGrp.MasterLabel + ' Muted';
        mutePerm.DeveloperName = permSetGrp.DeveloperName + '_Muted';
        insert mutePerm;

        // Get the Id of the newly inserted MutingPermissionSet
        permSetId = mutePerm.Id;

        // Create and insert the PermissionSetGroupComponent
        PermissionSetGroupComponent component = new PermissionSetGroupComponent(PermissionSetGroupId = permSetGrp.Id,PermissionSetId = permSetId);
        insert component;
      } else {
        system.debug('PermissionSetGroup not found for Id: ' + groupId);
      }
    }
    system.debug('check permSetId' + permSetId);
  }
  SObjectPermissionWrapper objAndFieldPermWrapper = objAndFieldPermHelper(permSetId,objNames,objName);
  return new MutePermissionWrapper(permSetId, objAndFieldPermWrapper);
}
  
  //Helper method to capture Exception logs.
  private static void handleException(String message, Exception e) {
  String fullMessage = e == null ? message : message + ': ' + e.getMessage();
  System.debug(LoggingLevel.ERROR, fullMessage);
  throw new AuraHandledException(fullMessage);
}
  
}