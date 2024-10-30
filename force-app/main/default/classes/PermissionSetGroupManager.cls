//This class is used for create,edit,delete,clone functionality for Permission Set Group.
Public without Sharing Class PermissionSetGroupManager {
	
  @AuraEnabled(cacheable=true)
   //This method is used to fetch permission set group details.
   Public Static List < permissionSetGroupWrapper > getPermissionSetGrp() {
      Map < Id, Set < String >> permSetGrpLicenses = new Map < Id, Set < String >> ();
      List < permissionSetGroupWrapper > permissionSetGroupWithLicense = new List < permissionSetGroupWrapper > ();

      // Query PermissionSetGroupComponents and build license map
      for (PermissionSetGroupComponent permSetComp: [
              SELECT Id, PermissionSetId, PermissionSet.License.Name, PermissionSetGroupId
              FROM PermissionSetGroupComponent
              WHERE PermissionSet.License.Name != null
          ]) {
          if (!permSetGrpLicenses.containsKey(permSetComp.PermissionSetGroupId)) {
              permSetGrpLicenses.put(permSetComp.PermissionSetGroupId, new Set < String > ());
          }
          permSetGrpLicenses.get(permSetComp.PermissionSetGroupId).add(permSetComp.PermissionSet.License.Name);
      }

      // Query PermissionSetGroups and create wrappers
      for (PermissionSetGroup permSetGrp: [
              SELECT Id, DeveloperName, MasterLabel, Description, Status, NamespacePrefix,
              CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate
              FROM PermissionSetGroup
              ORDER BY MasterLabel ASC
          ]) {
          Set < String > licenseList = permSetGrpLicenses.get(permSetGrp.Id);
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
          permSetGrpWrapper.sameLicense = licenseList == null || licenseList.size() <= 1;

          permissionSetGroupWithLicense.add(permSetGrpWrapper);
      }
      System.debug('permissionSetGroupWithLicense: ' + permissionSetGroupWithLicense);
      System.debug('permissionSetGroupWithLicense size: ' + permissionSetGroupWithLicense.size());
      return permissionSetGroupWithLicense;
    }
    
    //wrapper class to fetch permission set group details.
    public class PermissionSetGroupWrapper {
        @AuraEnabled public String perSetGrpId { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String masterLabel { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String namespacePrefix { get; set; }
        @AuraEnabled public Id createdById { get; set; }
        @AuraEnabled public String createdByName { get; set; }
        @AuraEnabled public Datetime createdDate { get; set; }
        @AuraEnabled public Id lastModifiedById { get; set; }
        @AuraEnabled public String lastModifiedByName { get; set; }
        @AuraEnabled public Datetime lastModifiedDate { get; set; }
        @AuraEnabled public Boolean sameLicense { get; set; }

        public PermissionSetGroupWrapper() {
            // Default constructor
        }

        public PermissionSetGroupWrapper(PermissionSetGroup psg, Boolean sameLicense) {
            this.perSetGrpId = psg.Id;
            this.developerName = psg.DeveloperName;
            this.masterLabel = psg.MasterLabel;
            this.description = psg.Description;
            this.status = psg.Status;
            this.namespacePrefix = psg.NamespacePrefix;
            this.createdById = psg.CreatedById;
            this.createdByName = psg.CreatedBy?.Name;
            this.createdDate = psg.CreatedDate;
            this.lastModifiedById = psg.LastModifiedById;
            this.lastModifiedByName = psg.LastModifiedBy?.Name;
            this.lastModifiedDate = psg.LastModifiedDate;
            this.sameLicense = sameLicense;
        }
    }
    
    @AuraEnabled(cacheable=false)
    //This method is used for creation of permission set group.
    public static void createPermissionSetGroup(String label, String apiName, String description, List<String> permissionSetIds, Boolean isRequired) {
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
    public static PermissionSetGroup editPermissionSetGrp(String perSetId, String label, String apiName, String description, String format) {
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
    
  // This method is used for cloning permission set group along with permission sets.
  @AuraEnabled
  public static void clonePermissionSetGroup(String sourcePermissionSetGroupName, String newLabel, String newApiName, String newDescription) {
      try {
        // Fetch the source Permission Set Group
          PermissionSetGroup sourcePSG = [SELECT Id FROM PermissionSetGroup WHERE MasterLabel = :sourcePermissionSetGroupName LIMIT 1];

        // Create a new Permission Set Group
          PermissionSetGroup newPSG = new PermissionSetGroup(
              MasterLabel = newLabel,
              DeveloperName = newApiName.replaceAll(' ', '_'),
              Description = newDescription
          );
          insert newPSG;

          // Clone Permission Set Group Components
          List<PermissionSetGroupComponent> sourceComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :sourcePSG.Id];
          List<PermissionSetGroupComponent> newComponents = new List<PermissionSetGroupComponent>();
          for (PermissionSetGroupComponent component : sourceComponents) {
              newComponents.add(new PermissionSetGroupComponent(
                  PermissionSetGroupId = newPSG.Id,
                  PermissionSetId = component.PermissionSetId
              ));
        }
          insert newComponents;

          // Get Users and Assign
          List<PermissionSetAssignment> newAssignments = new List<PermissionSetAssignment>();
          for (PermissionSetAssignment psa : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetGroupId = :sourcePSG.Id AND Assignee.IsActive = TRUE]) {
              newAssignments.add(new PermissionSetAssignment(
                  AssigneeId = psa.AssigneeId,
                  PermissionSetGroupId = newPSG.Id
              ));
      }

          if (!newAssignments.isEmpty()) {
              insert newAssignments;
    }

      } catch (Exception e) {
          handleException('Error cloning Permission Set Group: ', e);
      }
  }
    
  // This method is used to delete permission set group.
  @AuraEnabled
  public static void deletePermissionSetGroupWithUnassignments(String permissionSetGroupId) {
    try {
        // Step 1: Retrieve all related records in a single query
      List<PermissionSetAssignment> assignmentsToDelete = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId = :permissionSetGroupId limit 1];
      List<PermissionSetGroupComponent> componentsToDelete = [SELECT Id FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :permissionSetGroupId limit 1];
      PermissionSetGroup permissionSetGroupToDelete = [SELECT Id FROM PermissionSetGroup WHERE Id = :permissionSetGroupId limit 1];

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
    
    @AuraEnabled
    public static List<User> getUserPermissionSetGroup(String profileName, String userLicense, String perSetGrpId) {
        // Query assigned users in one go
        Set<Id> assignedUserIds = new Set<Id>(new Map<Id, PermissionSetAssignment>([
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetGroupId = :perSetGrpId
        ]).keySet());
        
        // Start building the query string
        String query = 'SELECT Id, Name, Username, Profile.Name, IsActive, Profile.UserLicense.Name ' +
            'FROM User ' +
            'WHERE IsActive = true AND Id NOT IN :assignedUserIds';
        
        // Add conditions to the query string based on parameters
        if (String.isNotBlank(profileName) && profileName != 'All') {
            query += ' AND Profile.Name = \'' + String.escapeSingleQuotes(profileName) + '\'';
        }
        
        if (String.isNotBlank(userLicense) && userLicense != 'All') {
            query += ' AND Profile.UserLicense.Name = \'' + String.escapeSingleQuotes(userLicense) + '\'';
        }
        
        query += ' ORDER BY Name ASC limit 50000';
        
        // Execute the query
        List<User> userList = Database.query(query);
        System.debug('userList >>> ' + userList);
        return userList;
    }

  
  //This method is used to assign users to Permission Set Groups, retrieve users assigned to groups, and list users who are eligible to be assigned to a group.
  @AuraEnabled
  public static void getPermissionGroup(List < String > userIds, String permSetGrpId) {
    if (userIds == null || userIds.isEmpty() || String.isBlank(permSetGrpId)) {
      handleException('Invalid input parameters', null);
    }
    List < PermissionSetAssignment > perSetAssignments = new List < PermissionSetAssignment > ();
    for (String userId: userIds) {
        perSetAssignments.add(new PermissionSetAssignment(
            AssigneeId = userId,
            PermissionSetGroupId = permSetGrpId
        ));
    }

    try {
        insert perSetAssignments;
        System.debug('Permission Set Group assigned successfully to ' + userIds.size() + ' users');
    } catch (DmlException e) {
        handleException('Error assigning Permission Set Group: ', e);
    }
  }
    
  //This method is used to retrieve list of users who are already assigned to a specified Permission Set Group.
  @AuraEnabled
  public static List<User> getPermissionSetGroup(String perSetGrpId) {
    return [
        SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name 
        FROM User 
        WHERE Id IN (
            SELECT AssigneeId 
            FROM PermissionSetAssignment 
            WHERE PermissionSetGroupId = :perSetGrpId
        )
        ORDER BY Name ASC
    ];
  }
    
  @AuraEnabled
  public static void deletePermissionGroup(List < String > userIds, String perSetGrpId) {
      try {
          delete[SELECT Id FROM PermissionSetAssignment WHERE AssigneeId IN: userIds AND PermissionSetGroupId =: perSetGrpId limit 50000];
          System.debug('Permission Set Group assignments deleted successfully for the users');
      } catch (DmlException e) {
          handleException('Error deleting Permission Set Group assignments', e);
      }
  }

  @AuraEnabled
  public static List < Profile > getProfiles() {
      return [SELECT Id, Name, UserLicense.Name
          FROM Profile
          ORDER BY Name ASC limit 50000
      ];
  }
    
    @AuraEnabled
    public static List<PermissionSet> getPermissionSet(String permissionSetGroupId, String searchperset) {
        // Retrieve the PermissionSetIds related to the given PermissionSetGroupId
        Set<Id> permissionSetIds = new Set<Id>(new Map<Id, PermissionSetGroupComponent>([
            SELECT PermissionSetId
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId = :permissionSetGroupId
        ]).keySet());
        
        // Start building the query string
        String query = 'SELECT Id, Name, Label, Description, LicenseId, License.Name, IsCustom, ' +
            'CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, ' +
            'LastModifiedDate, NamespacePrefix ' +
            'FROM PermissionSet ' +
            'WHERE Id NOT IN :permissionSetIds AND IsOwnedByProfile = false AND Type != \'Group\' ';
        
        // Append search criteria if searchperset is provided
        if (String.isNotBlank(searchperset)) {
            query += ' AND Label LIKE \'%' + String.escapeSingleQuotes(searchperset) + '%\'';
        }
        
        query += ' ORDER BY Label ASC limit 50000';
        
        // Execute the query and return the result
        return Database.query(query);
    }

    
  @AuraEnabled
  public static void insertPermissionSet(List<String> permissionSetIds, String permissionSetGroupId) {
    if (permissionSetIds == null || permissionSetIds.isEmpty() || String.isBlank(permissionSetGroupId)) {
      handleException('Invalid input parameters', null);
    }
    List<PermissionSetGroupComponent> componentsToInsert = new List<PermissionSetGroupComponent>();
    for (String permissionSetId : permissionSetIds) {
        componentsToInsert.add(new PermissionSetGroupComponent(
            PermissionSetId = permissionSetId,
            PermissionSetGroupId = permissionSetGroupId
        ));
    }

    try {
        insert componentsToInsert;
        System.debug('Permission Set Group assigned successfully to ' + componentsToInsert.size() + ' Permission Sets');
    } catch (DmlException e) {
        handleException('Error assigning Permission Set Group: ', e);
    }
  }
    
  @AuraEnabled
  public static void deletePermissionSet(List < String > permissionSetIds, String perSetGrpId) {
    try {
        delete[SELECT Id FROM PermissionSetGroupComponent WHERE PermissionSetId IN: permissionSetIds AND PermissionSetGroupId =: perSetGrpId limit 50000];
        System.debug('Permission Set Group components deleted successfully');
    } catch (DmlException e) {
        handleException('Error deleting Permission Set Group components', e);
    }
  }

  @AuraEnabled
  public static List < PermissionSet > getAssignedPermissionSet(String permissionSetGroupId) {
      return [SELECT Id, Name, Label, Description, License.Name, IsCustom,
          CreatedById, CreatedBy.Name, CreatedDate,
          LastModifiedById, LastModifiedBy.Name, LastModifiedDate
          FROM PermissionSet
          WHERE Id IN(SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId =: permissionSetGroupId)
          AND IsOwnedByProfile = FALSE
          ORDER BY Label ASC limit 50000
      ];
  }
    
  @AuraEnabled(cacheable = true)
  public static List < Map<String, String> > getSetPermission() {
    List<Map<String, String>> result = new List<Map<String, String>>();   

    for (PermissionSet ps: [SELECT Id, Name, Label, Description, IsCustom, NamespacePrefix, CreatedDate, LastModifiedDate,
            License.Name, CreatedBy.Name, LastModifiedBy.Name
            FROM PermissionSet
            WHERE IsOwnedByProfile = false AND Type != 'Group' limit 50000
        ]) {
            Map<String, String> recordMap = new Map<String, String>();
            recordMap.put('Id', ps.Id);
            recordMap.put('Name', ps.Name);
            recordMap.put('Label', ps.Label);
            recordMap.put('Description', ps.Description);
            recordMap.put('IsCustom', String.valueOf(ps.IsCustom));
            recordMap.put('NamespacePrefix', ps.NamespacePrefix);
            recordMap.put('CreatedDate', String.valueOf(ps.CreatedDate));
            recordMap.put('LastModifiedDate', String.valueOf(ps.LastModifiedDate));

            if (ps.License != null) {
                recordMap.put('LicenseId', ps.License.Id);
                recordMap.put('LicenseName', ps.License.Name);
                System.debug('Permission Set Id >> ' + ps.Id);
                System.debug('License Name >> ' + ps.License.Name);
            } else {
                System.debug('License Name not found for Permission set ID: ' + ps.Id);
            }
            
            // Created By information
            if (ps.CreatedBy != null) {
                recordMap.put('CreatedById', ps.CreatedBy.Id);
                recordMap.put('CreatedByName', ps.CreatedBy.Name);
                System.debug('Permission Set Id >> ' + ps.Id);
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
    
  @AuraEnabled(cacheable = true)
  public static List < PermissionSet > getProfileDetails() {
      return [
          SELECT
          Id, ProfileId, Profile.Name, Profile.UserLicense.Name,
          Profile.Description, Profile.UserType, IsOwnedByProfile, IsCustom
          FROM PermissionSet
          WHERE IsOwnedByProfile = TRUE
          ORDER BY Profile.Name ASC limit 50000
      ];
  }
    
    @AuraEnabled
    public static List<User> getUnAssignedUserForPermissionSet(String permissionSetId, String profileName, String userLicense, String licenseName) {
        System.debug('License Name: ' + licenseName);
        System.debug('Permission Set: ' + permissionSetId);
        System.debug('Profile Name: ' + profileName);
        System.debug('User License: ' + userLicense);
        
        // Query assigned users in one go
        Set<Id> assignedUserIds = new Set<Id>(new Map<Id, PermissionSetAssignment>([
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Id = :permissionSetId
        ]).keySet());
        
        // Start building the query string
        String query = 'SELECT Id, Name, Username, Profile.Name, IsActive, Profile.UserLicense.Name ' +
            'FROM User ' +
            'WHERE IsActive = true AND Id NOT IN :assignedUserIds';
        
        // Append filters if provided
        if (String.isNotBlank(profileName) && profileName != 'All') {
            query += ' AND Profile.Name = \'' + String.escapeSingleQuotes(profileName) + '\'';
        }
        
        if (String.isNotBlank(licenseName)) {
            query += ' AND Profile.UserLicense.Name = \'' + String.escapeSingleQuotes(licenseName) + '\'';
        }
        
        query += ' ORDER BY Name ASC limit 50000';
        
        // Execute the query and return the result
        List<User> userList = Database.query(query);
        System.debug('userList: ' + userList);
        return userList;
    }

    
    @AuraEnabled(cacheable=true)
    public static Boolean checkDuplicatePermissionSetGroup(String label, String apiName) {
      return [SELECT COUNT() FROM PermissionSetGroup WHERE MasterLabel = :label OR DeveloperName = :apiName LIMIT 1] > 0;
    }
    
    public class userObjAndFieldPermissionSetGroupWrapper {
      @AuraEnabled public List < CombinedPermissionsWrapper > combinedPermissions { get; set; }
      @AuraEnabled public Map < String, ObjectPermissions > objectPermissions {get; set; }
      @AuraEnabled public Map < String, ObjectPermissions > mutingobjectPermissions { get; set; }
      @AuraEnabled public Map < String, List < FieldPermissions >> fieldPermissions { get; set; }
      @AuraEnabled public Map < String, List < FieldPermissions >> mutingfieldPermissions { get; set; }
      @AuraEnabled public List < TabDefinition > tabsetting { get; set; }
  
      public userObjAndFieldPermissionSetGroupWrapper(
          List < CombinedPermissionsWrapper > combinedPermissions,
          Map < String, ObjectPermissions > objectPermissions,
          Map < String, ObjectPermissions > mutingobjectPermissions,
          Map < String, List < FieldPermissions >> fieldPermissions,
          Map < String, List < FieldPermissions >> mutingfieldPermissions,
          List < TabDefinition > tabsetting
      ) {
          this.combinedPermissions = combinedPermissions;
          this.objectPermissions = objectPermissions;
          this.mutingobjectPermissions = mutingobjectPermissions;
          this.fieldPermissions = fieldPermissions;
          this.mutingfieldPermissions = mutingfieldPermissions;
          this.tabsetting = tabsetting;
      }
    }
    
    public class CombinedPermissionsWrapper {
      @AuraEnabled public String fieldName { get; set; }
      @AuraEnabled public String fieldLabel { get; set; }
      @AuraEnabled public Object fieldValue { get; set; }
      @AuraEnabled public Object mutedValue { get; set; }
      @AuraEnabled public String mutedId { get; set; }
      @AuraEnabled public Boolean hasDependencies { get; set; }
      @AuraEnabled public List < String > requiredPermissions { get; set; }
      @AuraEnabled public List < TabPermissionWrapper > tabPermissions { get; set; }
      public CombinedPermissionsWrapper(
          String fieldName,
          String fieldLabel,
          Object fieldValue,
          Object mutedValue,
          String mutedId
      ) {
          this.fieldName = fieldName;
          this.fieldLabel = fieldLabel;
          this.fieldValue = fieldValue;
          this.mutedValue = mutedValue;
          this.mutedId = mutedId;
          this.hasDependencies = false;
          this.requiredPermissions = new List < String > ();
          this.tabPermissions = new List < TabPermissionWrapper > ();
      }
    }
    
    public class TabPermissionWrapper {
      @AuraEnabled public String tabName { get; set; }
      @AuraEnabled public String visibility { get; set; }
  
      public TabPermissionWrapper(String tabName, String visibility) {
          this.tabName = tabName;
          this.visibility = visibility;
      }
    }
    
    private static Map < String, List < String >> checkForDependencies(
        Set < String > fieldNames,
        Boolean isUpdateSystemPermissions
    ) {
        Map < String, List < String >> fieldPermissionsMap = new Map < String, List < String >> ();
        if (fieldNames.isEmpty()) {
            return fieldPermissionsMap;
        }

        String query = buildQuery(fieldNames, isUpdateSystemPermissions);
        HttpResponse res = makeHttpRequest(query);
        if (res.getStatusCode() == 200) {
            Map < String, Object > result = (Map < String, Object > ) JSON.deserializeUntyped(res.getBody());
            List < Object > records = (List < Object > ) result.get('records');
            for (Object record: records) {
                Map < String, Object > recordMap = (Map < String, Object > ) record;
                String key = (String) recordMap.get(isUpdateSystemPermissions ? 'Permission' : 'RequiredPermission');
                String value = (String) recordMap.get(isUpdateSystemPermissions ? 'RequiredPermission' : 'Permission');
                if (!fieldPermissionsMap.containsKey(key)) {
                    fieldPermissionsMap.put(key, new List < String > ());
                }
                fieldPermissionsMap.get(key).add(value);
            }
        } else {
            System.debug('Error: ' + res.getBody());
        }
        return fieldPermissionsMap;
    }

    private static String buildQuery(Set < String > fieldNames, Boolean isUpdateSystemPermissions) {
        String joinedFieldNames = '\'' + String.join(new List < String > (fieldNames), '\',\'') + '\'';
        String fieldToCheck = isUpdateSystemPermissions ? 'Permission' : 'RequiredPermission';
        String additionalCondition = isUpdateSystemPermissions ? 'AND RequiredPermissionType = \'User Permission\'' : '';

        return 'SELECT RequiredPermission, Permission FROM PermissionDependency WHERE ' +
            fieldToCheck + ' IN (' + joinedFieldNames + ') ' + additionalCondition;
    }

    private static HttpResponse makeHttpRequest(String query) {
        UserAccessManager instance = new UserAccessManager();
        String endpoint = URL.getSalesforceBaseUrl().toExternalForm() +
            '/services/data/v58.0/tooling/query?q=' +
            EncodingUtil.urlEncode(query, 'UTF-8');

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + instance.partnerConnection.SessionHeader.sessionId);
        req.setHeader('Content-Type', 'application/json');

        return new Http().send(req);
    }

    @AuraEnabled(cacheable=false)
    Public Static userObjAndFieldPermissionSetGroupWrapper getCombinedPermissions(String permissionSetGroupId,string persetapi,string persetname) {
      List<CombinedPermissionsWrapper> combinedPermissions = new List<CombinedPermissionsWrapper>();
      String baseQueryString = 'SELECT Id, Name';
      Map<String, Schema.SObjectField> baseFields = Schema.SObjectType.PermissionSet.fields.getMap();

      // Build the query string and collect permission fields

      for (Schema.SObjectField field : baseFields.values()) {
        String fieldName = field.getDescribe().getName();
        if (fieldName.startsWith('Permissions') && fieldName != 'Permissionsetgroupid') {
          baseQueryString += ', ' + field;
          String fieldLabel = field.getDescribe().getLabel();
          combinedPermissions.add(new CombinedPermissionsWrapper(fieldName,fieldLabel,null,null,null)); // Initialize with null
        }
      }

      // Retrieve permission sets related to the permission set group
      List<PermissionSetGroupComponent> groupComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :permissionSetGroupId];
      Set<Id> permissionSetIds = new Set<Id>();
      for (PermissionSetGroupComponent component : groupComponents) {
        permissionSetIds.add(component.PermissionSetId);
      }
      baseQueryString += ' FROM PermissionSet WHERE Id IN :permissionSetIds';
      List<PermissionSet> basePermissionSets = (List<PermissionSet>) Database.query(baseQueryString);

      // Logging values of each permission field
      for (PermissionSet basePermissionSet : basePermissionSets) {
        for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
          String fieldName = wrapper.fieldName;
          Object fieldValue = basePermissionSet.get(fieldName);
            wrapper.fieldValue = fieldValue;      
        }
      }

      string nullValue = '%_%';
      list<PermissionSetGroupComponent> per = [SELECT id,PermissionSetId,PermissionSet.Name,PermissionSetGroupId,PermissionSetGroup.DeveloperName FROM PermissionSetGroupComponent
        WHERE
          PermissionSetGroupId = :permissionSetGroupId
          AND (NOT PermissionSet.Name LIKE :nullValue)
      ];
      string ids;
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
          //system.debug('Wrapper Fields'+wrapper.fieldName);
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
      // Perform batch callouts
      Map<String, List<String>> fieldPermissionsMap = checkForDependencies(requiredPermissionFields,false);
      for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
        String initialRequiredPermission = wrapper.fieldName.remove('Permissions');
        if (fieldPermissionsMap.containskey(initialRequiredPermission)) {
          wrapper.hasDependencies = true;
          wrapper.requiredPermissions.addAll(fieldPermissionsMap.get(initialRequiredPermission));
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
      Map<string, ObjectPermissions> objectPermissions = getObjectPermissionsforPSG(permissionSetGroupId);
      Map<string, ObjectPermissions> mutingobjectPermissions = getmutingObjectPermissionsforPSG(permissionSetGroupId,persetapi,persetname);
      Map<String, List<fieldPermissions>> fieldPermissions = getFieldPermissionspsg(permissionSetGroupId);
      Map<String, List<fieldPermissions>> mutingfieldPermissions = getmutingFieldPermissionspsg(permissionSetGroupId);
      List<TabDefinition> tabsetting = [SELECT id, Name, SobjectName FROM TabDefinition];
      
      return new userObjAndFieldPermissionSetGroupWrapper(truePermissions,objectPermissions,mutingobjectPermissions,fieldPermissions,mutingfieldPermissions,tabsetting);
    }
    
    @AuraEnabled
    public static Map<String, List<FieldPermissions>> getmutingFieldPermissionspsg(String persetgrpid) {
        // Query for MutingPermissionSet components in PermissionSetGroupComponent table
        List<PermissionSetGroupComponent> components = [
            SELECT PermissionSetId, PermissionSet.Name
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId = :persetgrpid
            AND PermissionSet.Type = 'Muting'
            LIMIT 1
        ];
        
        // If no relevant muting permission set is found, return an empty map
        if (components.isEmpty()) {
            return new Map<String, List<FieldPermissions>>();
        }
        
        String mutingPermissionSetId = components[0].PermissionSetId;
        
        // Query for FieldPermissions associated with the found MutingPermissionSet
        List<FieldPermissions> fieldPermissions = [
            SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :mutingPermissionSetId
        ];
        
        // Group FieldPermissions by SObjectType
        Map<String, List<FieldPermissions>> fieldMap = new Map<String, List<FieldPermissions>>();
        for (FieldPermissions fp : fieldPermissions) {
            if (!fieldMap.containsKey(fp.SObjectType)) {
                fieldMap.put(fp.SObjectType, new List<FieldPermissions>());
            }
            fieldMap.get(fp.SObjectType).add(fp);
        }
        
        return fieldMap;
    }


    @AuraEnabled
    public static Map < String, List < FieldPermissions >> getFieldPermissionspsg(String persetgrpid) {
        Map < String, List < FieldPermissions >> fieldmap = new Map < String, List < FieldPermissions >> ();

        for (FieldPermissions fie: [SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
                FROM FieldPermissions
                WHERE Parent.PermissionSetGroupId =: persetgrpid
            ]) {
            if (!fieldmap.containsKey(fie.SObjectType)) {
                fieldmap.put(fie.SObjectType, new List < FieldPermissions > ());
            }
            fieldmap.get(fie.SObjectType).add(fie);
        }

        return fieldmap;
    }
    
    @AuraEnabled
    public static Map<String, ObjectPermissions> getmutingObjectPermissionsforPSG(
        String persetgrpid,
        String psgapiname,
        String psgname
    ) {
        Map<String, ObjectPermissions> objMap = new Map<String, ObjectPermissions>();
        
        // Query for PermissionSetGroupComponent
        List<PermissionSetGroupComponent> psgComponentList = [
            SELECT Id, PermissionSetId, PermissionSet.Name
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId = :persetgrpid
            LIMIT 1
        ];
        
        String mutingPermSetId;
        if (psgComponentList.size() > 0) {
            mutingPermSetId = psgComponentList[0].PermissionSetId;
        } else {
            // Create a new MutingPermissionSet if not exists
            MutingPermissionSet mutingPermissionSet = new MutingPermissionSet(
                MasterLabel = psgname + ' Muted',
                DeveloperName = psgapiname + '_Muted'
            );
            insert mutingPermissionSet;
            mutingPermSetId = mutingPermissionSet.Id;
            
            // Create PermissionSetGroupComponent linking the new muting permission set
            insert new PermissionSetGroupComponent(
                PermissionSetGroupId = persetgrpid,
                PermissionSetId = mutingPermSetId
            );
        }
        
        // Query ObjectPermissions in bulk based on the muting permission set
        List<ObjectPermissions> objectPermissionsList = [
            SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
            PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
            FROM ObjectPermissions
            WHERE ParentId = :mutingPermSetId
        ];
        
        for (ObjectPermissions obj : objectPermissionsList) {
            if (!objMap.containsKey(obj.SObjectType)) {
                objMap.put(obj.SObjectType, obj);
            }
        }
        return objMap;
    }


    
    @AuraEnabled
    public static Map < String, ObjectPermissions > getObjectPermissionsforPSG(String persetgrpid) {
        Map < String, ObjectPermissions > objMap = new Map < String, ObjectPermissions > ();
   
        for (ObjectPermissions obj: [
                SELECT SobjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
                PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                FROM ObjectPermissions
                WHERE Parent.PermissionSetGroupId =: persetgrpid
            ]) {
            if (!objMap.containsKey(obj.SobjectType)) {
              objMap.put(obj.SobjectType, obj);
            }
        }
        System.debug(objMap);
        return objMap;
    }
    
    // Mute System Permissions for Permission Set Group
    @AuraEnabled
    public static List<MutingPermissionSet> mutePermissions(
        String systemPermissionsMapJson,
        String psgname,
        String psgapiname,
        String psgid
    ) {
        System.debug('Map Values: ' + systemPermissionsMapJson);
        Map<String, Object> tempMap = (Map<String, Object>) JSON.deserializeUntyped(
      systemPermissionsMapJson
    );
        Map<String, Map<String, Object>> systemPermissionsMap = (Map<String, Map<String, Object>>) JSON.deserializeUntyped(systemPermissionsMapJson);
        String mutingId;
        Map<String, Object> permissionsMap = new Map<String, Object>();
        
        // Create a new MutingPermissionSet if the map contains an empty key
        if (systemPermissionsMap.containsKey('')) {
            MutingPermissionSet mutingPermissionSet = new MutingPermissionSet(
                MasterLabel = psgname + ' Muted',
                DeveloperName = psgapiname + '_Muted'
            );
            insert mutingPermissionSet;
            mutingId = mutingPermissionSet.Id;
            
            insert new PermissionSetGroupComponent(
                PermissionSetGroupId = psgid,
                PermissionSetId = mutingId
            );
            
            for (String systemId : systemPermissionsMap.keySet()) {
                Map<String, Object> fieldMap = systemPermissionsMap.get(systemId);
                for (String fieldApi : fieldMap.keySet()) {
                    Object isChecked = fieldMap.get(fieldApi);
                    permissionsMap.put(fieldApi, isChecked);
                }
            }
        } else {
            mutingId = new List<String>(systemPermissionsMap.keySet())[0];
            for (String systemId : systemPermissionsMap.keySet()) {
                Map<String, Object> fieldMap = systemPermissionsMap.get(systemId);
                for (String fieldApi : fieldMap.keySet()) {
                    Object isChecked = fieldMap.get(fieldApi);
                    permissionsMap.put(fieldApi, isChecked);
                }
            }
        }
        
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.MutingPermissionSet.fields.getMap();
        List<String> validPermissions = new List<String>();
        
        for (String permission : permissionsMap.keySet()) {
            if (fieldsMap.containsKey(permission)) {
                validPermissions.add(permission);
            }
        }
        
        if (validPermissions.isEmpty()) {
            return new List<MutingPermissionSet>();
        }
        
        String query = 'SELECT ' + String.join(validPermissions, ', ') + ' FROM MutingPermissionSet WHERE Id = :mutingId';
        MutingPermissionSet mutingPermissionSet = (MutingPermissionSet) Database.query(query)[0];
        
        for (String permission : validPermissions) {
            mutingPermissionSet.put(permission, permissionsMap.get(permission));
        }
        
        try {
            update mutingPermissionSet;
            return new List<MutingPermissionSet> {
                mutingPermissionSet
                    };
                        } catch (DmlException e) {
                            handleException('Error updating MutingPermissionSet: ', e);
                            return new List<MutingPermissionSet>(); // Return an empty list on error
                        }
    }

    
    @AuraEnabled
    public static List < Map < String, Object >> getTabSettingpsg(String persetname) {
        UserAccessManager instance = new UserAccessManager();
        MetadataService.PermissionSetGroup permSetGroup = ((List < MetadataService.PermissionSetGroup > ) instance.service.readMetadata('PermissionSetGroup', new String[] {
            persetname
        }).getRecords())[0];
        // Map to store unique tab settings (key: tab name, value: visibility)
        Map < String, String > uniqueTabSettings = new Map < String, String > ();

        if (permSetGroup.permissionSets != null) {
            List < String > permissionSetNames = permSetGroup.permissionSets;
            List < MetadataService.PermissionSet > permSetList = (List < MetadataService.PermissionSet > ) instance.service.readMetadata('PermissionSet', permissionSetNames).getRecords();
            for (MetadataService.PermissionSet permSet: permSetList) {
                if (permSet.tabSettings != null) {
                    for (MetadataService.PermissionSetTabSetting tabSetting: permSet.tabSettings) {
                        if (!uniqueTabSettings.containsKey(tabSetting.tab)) {
                            uniqueTabSettings.put(tabSetting.tab, tabSetting.visibility);
                        }
                    }
                }
            }
        }
        List < Map < String, Object >> tabSettingMapList = new List < Map < String, Object >> ();

        for (TabDefinition tabDef: [SELECT Name, Label FROM TabDefinition ORDER BY Label ASC]) {
            tabSettingMapList.add(new Map < String, Object > {
                'Label' => tabDef.Label,
                'Name' => tabDef.Name,
                'Visibility' => uniqueTabSettings.get(tabDef.Name)
            });
        }
        return tabSettingMapList;
    }
    
    public class MutePermissionUpdateWrapper {
      @AuraEnabled public Map<String, Object> objectPermissions { get; set; }
      @AuraEnabled public List<FieldPermissionUpdateWrapper> fieldPermissions { get; set; }

      public MutePermissionUpdateWrapper(Map<String, Object> objectPermissions, List<FieldPermissionUpdateWrapper> fieldPermissions) {
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
    public static MutePermissionUpdateWrapper updateMutePermissions(
      String mutePermId,
      String permSetId,
      String objName,
      Map<String, Map<String, Boolean>> objPermission,
      List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList
    ) {
      Map<String, Object> objResult = objPermission != null ? updateObjPermissions(objPermission, mutePermId) : new Map<String, Object>();
      List<FieldPermissionUpdateWrapper> fieldResult = fieldPermissionWrapperList != null ? updateFieldPermissions(fieldPermissionWrapperList, mutePermId, objName, 'MutePermissions') : new List<FieldPermissionUpdateWrapper>();

      return new MutePermissionUpdateWrapper(objResult, fieldResult);
  }
    
  @AuraEnabled
  public static List < FieldPermissionUpdateWrapper > updateFieldPermissions(
      List < FieldPermissionUpdateWrapper > fieldPermissionWrapperList,
      String permissionSetId,
      String objName,
      String fieldPermType
  ) {
      if (permissionSetId == null || fieldPermissionWrapperList == null || fieldPermissionWrapperList.isEmpty()) {
          return null;
      }

      try {
          Map < String, FieldPermissions > existingPermissionsMap = new Map < String, FieldPermissions > ();
          Set < String > fieldNames = new Set < String > ();

          for (FieldPermissionUpdateWrapper wrapper: fieldPermissionWrapperList) {
              fieldNames.add(wrapper.Field);
          }

          for (FieldPermissions fieldPerm: [SELECT Id, SObjectType, Field, PermissionsRead, PermissionsEdit
                  FROM FieldPermissions
                  WHERE ParentId =: permissionSetId AND Field IN: fieldNames
              ]) {
              existingPermissionsMap.put(fieldPerm.Field, fieldPerm);
          }

          List < FieldPermissions > permissionsToUpsert = new List < FieldPermissions > ();

          for (FieldPermissionUpdateWrapper wrapper: fieldPermissionWrapperList) {
              FieldPermissions permission = existingPermissionsMap.containsKey(wrapper.Field) ?
                  existingPermissionsMap.get(wrapper.Field) :
                  new FieldPermissions(SObjectType = objName, Field = wrapper.Field, ParentId = permissionSetId);

              if (fieldPermType == 'MutePermissions') {
                  permission.PermissionsRead = wrapper.mutedPermissionsRead;
                  permission.PermissionsEdit = wrapper.mutedPermissionsEdit;
              } else {
                  permission.PermissionsRead = wrapper.PermissionsRead;
                  permission.PermissionsEdit = wrapper.PermissionsEdit;
              }

              permissionsToUpsert.add(permission);
          }

          if (!permissionsToUpsert.isEmpty()) {
              upsert permissionsToUpsert;
              return fieldPermissionWrapperList;
          }
      } catch (Exception e) {
          handleException('An error occurred while upserting Field Permissions: ', e);
      }
      return null;
  }

  public class PermissionSetGroupObjectDetails {
    @AuraEnabled public List<EntityDefinition> entityDefList { get; set; }
    @AuraEnabled public Map<String, Object> objectPermissions { get; set; }
    public PermissionSetGroupObjectDetails(List<EntityDefinition> entityDefList, Map<String, Object> objectPermissions) {
      this.entityDefList = entityDefList;
      this.objectPermissions = objectPermissions;
    }
  }  
  @AuraEnabled(cacheable=true)
  public static PermissionSetGroupObjectDetails getSobject(String permId) {
    Map<String, Object> objectPermissionsMap = new Map<String, Object>();
    if (String.isNotBlank(permId)) {
        for (ObjectPermissions objPerm : [
            SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, 
                   PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
            FROM ObjectPermissions 
            WHERE Parent.PermissionSetGroup.Id = :permId limit 50000
        ]) {
            objectPermissionsMap.put(objPerm.SObjectType, new Map<String, Object>{
                'PermissionsCreate' => objPerm.PermissionsCreate,
                'PermissionsRead' => objPerm.PermissionsRead,
                'PermissionsEdit' => objPerm.PermissionsEdit,
                'PermissionsDelete' => objPerm.PermissionsDelete,
                'PermissionsViewAllRecords' => objPerm.PermissionsViewAllRecords,
                'PermissionsModifyAllRecords' => objPerm.PermissionsModifyAllRecords
            });
        }
    }

    return new PermissionSetGroupObjectDetails(
        [SELECT Id, Label, QualifiedApiName, NameSpacePrefix 
         FROM EntityDefinition 
         WHERE DefaultCompactLayoutId != NULL],
        objectPermissionsMap
    );
  }
    
  public class PermissionSetGroupObjectPermissionsWrapper {
    @AuraEnabled public List<Map<String, Object>> fieldPermissions { get; private set; }
    @AuraEnabled public Boolean hasObjAccess { get; private set; }
    @AuraEnabled public List<Object> objDependent { get; private set; }
    @AuraEnabled public List<RecordType> recordTypeDetails { get; private set; }
    @AuraEnabled public String mutedId { get; private set; }

    public PermissionSetGroupObjectPermissionsWrapper(
      List<Map<String, Object>> fieldPermissions,
      Boolean hasObjAccess,
      List<Object> objDependent,
      List<RecordType> recordTypeDetails,
        String mutedId
    ) {
      this.fieldPermissions = fieldPermissions;
      this.hasObjAccess = hasObjAccess;
      this.objDependent = objDependent;
      this.recordTypeDetails = recordTypeDetails;
        this.mutedId = mutedId;
    }
  }

  @AuraEnabled
  public static PermissionSetGroupObjectPermissionsWrapper getSobjectPermissionsForPermissionSetGroup(
      String permSetId,
      String objName,
      String psgname,
      String psgapiname
  ) {
      System.debug('Perset Id: ' + permSetId + ', Object Name: ' + objName + ', PSG Name: ' + psgname + ', PSG API Name: ' + psgapiname);
      List < Object > dependObjects = PermissionSetManager.checkDependency(objName);
      Map < String, Boolean > fieldAccess = checkFieldType(objName);
      System.debug('fieldAccess: ' + fieldAccess);

      String muteId = getMutingPermissionSetId(permSetId, psgname, psgapiname);

      List < Map < String, Object >> fieldPermissionsMapList = getFieldPermissions(permSetId, objName, fieldAccess);
      List < RecordType > recordTypeDetails = [
          SELECT Id, Name, DeveloperName, NamespacePrefix
          FROM RecordType
          WHERE SobjectType =: objName
          ORDER BY Name ASC
      ];

      System.debug('check field permission map: ' + fieldPermissionsMapList);
      System.debug('check mute Id: ' + muteId);

      return new PermissionSetGroupObjectPermissionsWrapper(
          fieldPermissionsMapList,
          checkSObjType(objName),
          dependObjects,
          recordTypeDetails,
          muteId
      );
  }

  private static String getMutingPermissionSetId(String permSetId, String psgname, String psgapiname) {
      String nullValue = '%_%';
      PermissionSetGroupComponent psgc = [
          SELECT PermissionSetId, PermissionSet.Name
          FROM PermissionSetGroupComponent
          WHERE PermissionSetGroupId =: permSetId
          AND(NOT PermissionSet.Name LIKE: nullValue)
          LIMIT 1
      ];

      if (psgc != null) {
          return psgc.PermissionSetId;
      }

      MutingPermissionSet mutingPermissionSet = new MutingPermissionSet(
          MasterLabel = psgname + ' Muted',
          DeveloperName = psgapiname + '_Muted'
      );
      insert mutingPermissionSet;

      PermissionSetGroupComponent component = new PermissionSetGroupComponent(
          PermissionSetGroupId = permSetId,
          PermissionSetId = mutingPermissionSet.Id
      );
      insert component;

      return mutingPermissionSet.Id;
  }

  private static List < Map < String, Object >> getFieldPermissions(String permSetId, String objName, Map < String, Boolean > fieldAccess) {
      Map < String, Map < String, Object >> fieldDefMapByName = getFieldDefinitionProfile(objName);

      Map < String, FieldPermissions > fieldPermissionsMap = new Map < String, FieldPermissions > ();
      for (FieldPermissions fieldPerm: [
              SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
              FROM FieldPermissions
              WHERE Parent.PermissionSetGroup.Id =: permSetId AND SObjectType =: objName
          ]) {
          fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
      }

      List < Map < String, Object >> fieldPermissionsMapList = new List < Map < String, Object >> ();
      for (String fieldKey: fieldDefMapByName.keySet()) {
          if (fieldKey != null && (Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') && fieldAccess.get(fieldKey) == true) {
              Map < String, Object > fieldPermissionMap = new Map < String, Object > {
                  'Field' => fieldKey,
                  'label' => fieldDefMapByName.get(fieldKey).get('Label'),
                  'hasEditAccess' => fieldDefMapByName.get(fieldKey).get('isCalculated')
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

      return fieldPermissionsMapList;
    }
    
    @AuraEnabled
    public static Map < String, Map < String, Object >> getFieldDefinitionProfile(String objectName) {
        Map < String, Map < String, Object >> fieldDefMapByName = new Map < String, Map < String, Object >> ();
        Map < String, Schema.SObjectField > fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        for (String fieldName: fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.isPermissionable()) {
                fieldDefMapByName.put(objectName + '.' + fieldName, new Map < String, Object > {
                    'Label' => fieldDescribe.getLabel(),
                    'Name' => fieldName,
                    'isPermissionable' => true,
                    'isCalculated' => fieldDescribe.isCalculated()
                });
            }
        }
        return fieldDefMapByName;
    }

    public class MutePermissionWrapper {
        @AuraEnabled public String mutePermSetId { get; set; }
        @AuraEnabled public SObjectPermissionWrapper wrapper { get; set; }

        public MutePermissionWrapper(String mutePermSetId, SObjectPermissionWrapper wrapper) {
            this.mutePermSetId = mutePermSetId;
            this.wrapper = wrapper;
        }
    }

    public class SObjectPermissionWrapper {
        @AuraEnabled public Map < String, Object > objectPermissions { get; set; }
        @AuraEnabled public Map < String, Object > fieldPermissions { get; set; }

        public SObjectPermissionWrapper(Map < String, Object > objectPermissions, Map < String, Object > fieldPermissions) {
            this.objectPermissions = objectPermissions != null ? objectPermissions : new Map < String, Object > ();
            this.fieldPermissions = fieldPermissions != null ? fieldPermissions : new Map < String, Object > ();
        }
        public SObjectPermissionWrapper() {
            this.objectPermissions = new Map < String, Object > ();
            this.fieldPermissions = new Map < String, Object > ();
        }
    }
    @AuraEnabled
    public static Boolean checkSObjType(String sObjName) {
      Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
      return globalDescribe.containsKey(sObjName);
    }
    
    @AuraEnabled
    public static SObjectPermissionWrapper objAndFieldPermHelper(
        String permSetId,
        List < String > objNames,
        String objName
    ) {
        Map < String, Object > permissionSetMap = new Map < String, Object > ();
        Map < String, Object > fieldPermissionsMap = new Map < String, Object > ();

        if (String.isNotBlank(permSetId)) {
            // Query ObjectPermissions
            for (ObjectPermissions objPerm: [
                    SELECT SObjectType, PermissionsCreate, PermissionsEdit, PermissionsRead,
                    PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords
                    FROM ObjectPermissions
                    WHERE ParentId =: permSetId AND SObjectType IN: objNames limit 50000
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

            // Query FieldPermissions
            for (FieldPermissions fieldPerm: [
                    SELECT Field, PermissionsRead, PermissionsEdit
                    FROM FieldPermissions
                    WHERE ParentId =: permSetId AND SObjectType =: objName
                ]) {
                fieldPermissionsMap.put(fieldPerm.Field, new Map < String, Object > {
                    'PermissionsRead' => fieldPerm.PermissionsRead,
                    'PermissionsEdit' => fieldPerm.PermissionsEdit,
                    'Field' => fieldPerm.Field
                });
            }
        }
        return new SObjectPermissionWrapper(permissionSetMap, fieldPermissionsMap);
    }
    
  @AuraEnabled
  public static MutePermissionWrapper getMutedObjandFieldPermissions(
    String groupId,
    List<String> objNames,
    String objName
  ) {
    if (String.isBlank(groupId)) {
        return null;
    }

    String permSetId = getMutingPermissionSetId(groupId);
    SObjectPermissionWrapper objAndFieldPermWrapper = objAndFieldPermHelper(permSetId, objNames, objName);
    return new MutePermissionWrapper(permSetId, objAndFieldPermWrapper);
  }

    private static String getMutingPermissionSetId(String groupId) {
        // Query for PermissionSetGroupComponent
        List<PermissionSetGroupComponent> psgg = [
            SELECT PermissionSetId
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId = :groupId
            LIMIT 1
        ];
        
        // Return PermissionSetId if found
        if (!psgg.isEmpty()) {
            return psgg[0].PermissionSetId;
        }
        
        // Query for PermissionSetGroup
        List<PermissionSetGroup> permSetGrps = [
            SELECT MasterLabel, DeveloperName
            FROM PermissionSetGroup
            WHERE Id = :groupId
            LIMIT 1
        ];
        
        // Check if the PermissionSetGroup exists
        if (permSetGrps.isEmpty()) {
            handleException('PermissionSetGroup not found for Id: ' + groupId, null);
        }
        
        // Create a new MutingPermissionSet
        MutingPermissionSet mutePerm = new MutingPermissionSet(
            MasterLabel = permSetGrps[0].MasterLabel + ' Muted',
            DeveloperName = permSetGrps[0].DeveloperName + '_Muted'
        );
        insert mutePerm;
        
        // Create and insert PermissionSetGroupComponent
        PermissionSetGroupComponent component = new PermissionSetGroupComponent(
            PermissionSetGroupId = groupId,
            PermissionSetId = mutePerm.Id
        );
        insert component;
        
        return mutePerm.Id;
    }

    @AuraEnabled
    public static Map<String, Boolean> checkFieldType(String sObjName) {
        Map<String, Boolean> fieldMap = new Map<String, Boolean>();
        
        // Get the Describe result for FieldPermissions
        Schema.DescribeSObjectResult fieldPermissionsDescribe = Schema.SObjectType.FieldPermissions;
        Schema.DescribeFieldResult fieldDescribe = fieldPermissionsDescribe.fields.getMap().get('Field').getDescribe();
        
        // Iterate through the picklist values of the Field field
        for (Schema.PicklistEntry p : fieldDescribe.getPicklistValues()) {
            String[] parts = p.getValue().split('\\.');
            if (parts.size() > 1 && parts[0] == sObjName) {
                fieldMap.put(p.getValue(), true);
            }
        }
        
        return fieldMap;
    }


  @AuraEnabled
  public static Map < String, Object > updateObjPermissions(Map < String, Map < String, Object >> objPerms, String permSetId) {
      if (String.isBlank(permSetId) || objPerms == null || objPerms.isEmpty()) {
          return new Map < String, Object > ();
      }
      Map < String, Object > resultMap = new Map < String, Object > ();
      List < ObjectPermissions > objPermissionsToUpsert = new List < ObjectPermissions > ();

      try {
          Set < String > objNames = objPerms.keySet();

          Map < String, ObjectPermissions > existingPermMap = new Map < String, ObjectPermissions > ();
          for (ObjectPermissions perm: [SELECT Id, ParentId, SobjectType, PermissionsCreate, PermissionsRead, PermissionsEdit,
                  PermissionsDelete, PermissionsModifyAllRecords, PermissionsViewAllRecords
                  FROM ObjectPermissions
                  WHERE ParentId =: permSetId AND SobjectType IN: objNames
              ]) {
              existingPermMap.put(perm.SobjectType, perm);
          }

          for (String objName: objPerms.keySet()) {
              Map < String, Object > permissionsMap = objPerms.get(objName);
              ObjectPermissions objToUpsert = existingPermMap.containsKey(objName) ?
                  existingPermMap.get(objName) :
                  new ObjectPermissions(ParentId = permSetId, SobjectType = objName);

              objToUpsert.PermissionsCreate = (Boolean) permissionsMap.get('PermissionsCreate');
              objToUpsert.PermissionsRead = (Boolean) permissionsMap.get('PermissionsRead');
              objToUpsert.PermissionsEdit = (Boolean) permissionsMap.get('PermissionsEdit');
              objToUpsert.PermissionsDelete = (Boolean) permissionsMap.get('PermissionsDelete');
              objToUpsert.PermissionsModifyAllRecords = (Boolean) permissionsMap.get('PermissionsModifyAllRecords');
              objToUpsert.PermissionsViewAllRecords = (Boolean) permissionsMap.get('PermissionsViewAllRecords');
              objPermissionsToUpsert.add(objToUpsert);
              resultMap.put(objName, objToUpsert);
          }

          upsert objPermissionsToUpsert;
      } catch (Exception e) {
          handleException('Error updating object permissions: ', e);
      }
      return resultMap;
  } 

  private static void handleException(String message, Exception e) {
    String fullMessage = e == null ? message : message + ': ' + e.getMessage();
    System.debug(LoggingLevel.ERROR, fullMessage);
    throw new AuraHandledException(fullMessage);
  }
}