// This Class is Handle to Display Users having UserPermissions, objectPermissions and fieldPermissions 
// through Profile,PermissionSet and PermissionSetGroup.
//This CLass Used IN PermissionAnalyzer  && ManagePermissionComponentClone LWC Component
Public Without sharing Class PermissionTabServer {
 //Used to fetch User Permissions
 @AuraEnabled
  Public Static Map<String, String> getUserDefinitions() {   
      
      Map < String, String > systemAndUserResult = new Map < String, String > ();
      Map < String, Schema.SObjectField > fieldMap = Schema.SObjectType.PermissionSet.fields.getMap();

      List < String > booleanFields = new List < String > ();
      for (Schema.SObjectField field: fieldMap.values()) {
          Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
          if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
              booleanFields.add(fieldDescribe.getName());
          }
      }

      if (!booleanFields.isEmpty()) {
          String soqlQuery = 'SELECT ' + String.join(booleanFields, ', ') + ' FROM PermissionSet LIMIT 1';
          List < PermissionSet > permissionSets = Database.query(soqlQuery);

          if (!permissionSets.isEmpty()) {
              PermissionSet ps = permissionSets[0];
              for (String fieldName: ps.getPopulatedFieldsAsMap().keySet()) {
                  systemAndUserResult.put(fieldName, fieldMap.get(fieldName).getDescribe().getLabel());
              }
          }
      }
      System.debug('systemAndUserResult : ' + systemAndUserResult);
      return systemAndUserResult;
  }
   
    //Uses to fetch EntityDefinition to get ObjNames
  @AuraEnabled
  Public Static List<EntityDefinition> getObjectDefinition() {   
       return [SELECT Id, Label, QualifiedApiName FROM EntityDefinition ORDER BY label ASC];
  }

    //Uses to Fetch FieldDefinition to get FieldNames
    @AuraEnabled
  Public Static List<Map<String, Object>> getFieldDefinition(string objectName) {
    List<Map<String, Object>> fieldDefList = new List<Map<String, Object>>();
     Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
      for (Schema.SObjectField field: fieldMap.values()) {
          Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
          if (fieldDescribe.isPermissionable()) {
              fieldDefList.add(new Map < String, Object > {
                  'Label' => fieldDescribe.getLabel(),
                  'Name' => fieldDescribe.getName(),
                  'isPermissionable' => true,
                  'isCalculated' => fieldDescribe.isCalculated()
              });
          }
      }
      return fieldDefList;
  }
  Public Class ProfilePermissionSetAndUserWrapper {
    @AuraEnabled Public List<PermissionSet> permissionSetList { get; set; }
    @AuraEnabled Public List<User> userList { get; set; }

    Public ProfilePermissionSetAndUserWrapper(List<permissionset> permissionSetList, List<user> userList) {
      this.permissionSetList = permissionSetList;
      this.userList = userList;
    }
  }
    
    //Uses to fetch Users based on selected permissions
    @AuraEnabled
	 Public Static profilePermissionsetandUserWrapper getPermsandUsersOfSelectedPerms(List<String> userPermissions,String objName,
                  String objPermission,String objFieldName,String fieldName,String fieldPerm,String perSetId) {
        system.debug('userPermissions'+ userPermissions);                 
        List<permissionSet> permissionSetList = new List<permissionSet>();
        Set<Id> idToFetchPermList = new Set<Id>();
        Set<Id> permissionSetIdSet = new Set<Id>();
        Set<Id> assigneeIdSet = new Set<Id>();
        Map<Id, user> userMap = new Map<Id, User>();
        List<String> conditions = new List<String>();
        try{
        if(!userPermissions.isEmpty()){
                String permissionQuery ='Select Id, Name, Profile.Name, Type, Label From PermissionSet Where ';
                for(String userPerm : userPermissions){
                    conditions.add(userPerm + ' =true');
                }
                permissionQuery += String.join(conditions, ' And ');
                System.debug('permissionQuery'+ permissionQuery);
                for (permissionSet permSet : Database.query(permissionQuery)) {
                    permissionSetList.add(permSet);
                    if(perSetId == 'All'){
                    permissionSetIdSet.add(permSet.Id);
                    }
                }  
                if(perSetId != 'All'){
                    permissionSetIdSet.add(perSetId);
                }
            System.debug('permissionSetIdSet' + permissionSetIdSet);
            }
        if (objName != null &&objName != '' &&objPermission != null &&objPermission != '') {
          string objectPermissionQuery ='select id, SobjectType, ParentId,parent.Name,parent.Label, Parent.Profile.Name, parent.Type from ObjectPermissions where SobjectType =: objName and  ' +objPermission +' =true';  
            for (
              ObjectPermissions objperm : Database.query(objectPermissionQuery)
            ) {
                idToFetchPermList.add(objperm.ParentId);
                if(perSetId == 'All'){
                    permissionSetIdSet.add(objperm.ParentId);
                }
            }
            permissionSetList = [SELECT id, name, Profile.name, Type, Label FROM PermissionSet WHERE id IN :idToFetchPermList];
          if (perSetId != 'All') {
            permissionSetIdSet.add(perSetId);
          }
    	} 
        if (objFieldName != null && objFieldName != '' && fieldName != null && fieldName != '' && fieldPerm != null && fieldPerm != '') {
          string objAndFieldConcat = objFieldName + '.' + fieldName;
          string fieldPermissionQuery =
            'select Id, SobjectType, ParentId, Field, parent.Label,Parent.Name, Parent.Profile.Name, parent.Type from FieldPermissions where field =: objAndFieldConcat and ' +
            fieldPerm +
            ' =true';
            for(fieldPermissions fieldPermission : Database.query(fieldPermissionQuery))          
            {
             idToFetchPermList.add(fieldPermission.ParentId);
             if(perSetId == 'All'){
                permissionSetIdSet.add(fieldPermission.ParentId);
             }
            }
            permissionSetList = [SELECT id, name, Profile.name, label, Type FROM PermissionSet WHERE id IN :idToFetchPermList];
            if (perSetId != 'All') {
               permissionSetIdSet.add(perSetId);
            }
        }
     
        for (PermissionSetAssignment perSetAssign : [ SELECT id, AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN :permissionSetIdSet]) {
          assigneeIdSet.add(perSetAssign.AssigneeId);
        }
        for (User u : [SELECT id,Name, Username, Alias,Profile.Name, IsActive, LastLoginDate, Title, Department, Profile.UserLicense.Name FROM user WHERE id IN :assigneeIdSet AND IsActive = true ORDER BY IsActive DESC Limit 50000]) { 
            userMap.put(u.id, u);
         }
        }catch(exception e){
            new AuraHandledException('Error on getPermsandUsersOfSelectedPerms'+ e.getMessage());
        }
        return new profilePermissionsetandUserWrapper(permissionsetList, usermap.values());
  }
     // Uses to Fetch the Origin of Object/Field Permissions for Users
  @AuraEnabled
    Public Static Map<String,List<String>> getObjOrFieldPerm(String objName, String permType, String fieldName, String userId)
    {System.debug('permType: ' + permType + ', fieldName: ' + fieldName);
  
      // Fetch PermissionSetIds in a single query
      Set < Id > permSetIds = new Set < Id > ();
      for (PermissionSetAssignment psa: [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =: userId]) {
          permSetIds.add(psa.PermissionSetId);
      }
  
      // Construct objAndFieldConcat only if fieldName is not empty
      String objAndFieldConcat = String.isNotBlank(fieldName) ? objName + '.' + fieldName : null;
  
      // Call getObjOrFieldPermissionsOrigin with optimized parameters
      return getObjOrFieldPermissionsOrigin(permType, new List < Id > (permSetIds), objName, objAndFieldConcat);
    }
    //This Method is Used to Retrieve the Origin of ObjectOrFieldPermissions.
  @AuraEnabled
  Public Static Map<String, List<String>> getObjOrFieldPermissionsOrigin(String permissionType, List<String> permSetIds, String objName, String fieldName) {
   	 Map < String, List < String >> permMap = new Map < String, List < String >> ();
  
      String query;
      if (String.isBlank(fieldName)) {
          query = 'SELECT Parent.Type, Parent.Name, Parent.Profile.Name, ' + permissionType +
              ' FROM ObjectPermissions WHERE SObjectType = :objName AND ParentId IN :permSetIds';
      } else {
          query = 'SELECT Parent.Type, Parent.Name, Parent.Profile.Name, ' + permissionType +
              ' FROM FieldPermissions WHERE SObjectType = :objName AND Field = :fieldName AND ParentId IN :permSetIds';
      }
  
      for (SObject perm: Database.query(query)) {
          if (Boolean.valueOf(perm.get(permissionType))) {
              String parentType = (String) perm.getSObject('Parent').get('Type');
              String parentName = (String) perm.getSObject('Parent').get('Name');
  
              String key;
              if (parentType == 'Profile') {
                  key = 'Profile';
                  parentName = (String) perm.getSObject('Parent').getSObject('Profile').get('Name');
              } else if (parentType == 'Group') {
                  key = 'Group';
              } else {
                  key = 'PermissionSet';
              }
  
              if (!permMap.containsKey(key)) {
                  permMap.put(key, new List < String > ());
              }
              permMap.get(key).add(parentName);
          }
      }
      return permMap;
  
  }
    
    // Uses to Fetch the Origin of User Permissions for Users
    @AuraEnabled
	Public Static Map<String, List<String>> getUserPerm(String userId, List<String> perms) {
        Map < String, List < String >> permNamesWithType = new Map < String, List < String >> {
          'Profile' => new List < String > (),
          'Group' => new List < String > (),
          'PermissionSet' => new List < String > ()
      };
      try {
          String permSetAssignQuery = 'SELECT PermissionSet.Profile.Name, PermissionSet.Type, PermissionSet.Label ' +
              'FROM PermissionSetAssignment WHERE AssigneeId = :userId';
  
          if (!perms.isEmpty()) {
              permSetAssignQuery += ' AND PermissionSet.' + String.join(perms, ' = true AND PermissionSet.') + ' = true';
          }
          for (PermissionSetAssignment permSetAssign: Database.query(permSetAssignQuery)) {
              String type = permSetAssign.PermissionSet.Type;
              String name = (type == 'Profile') ? permSetAssign.PermissionSet.Profile.Name : permSetAssign.PermissionSet.Label;
  
              if (type != 'Profile' && type != 'Group') {
                  type = 'PermissionSet';
              }
  
              permNamesWithType.get(type).add(name);
          }
  
      } catch (Exception e) {
        handleException('Error on fetching user origins: ', e);
      }
      return permNamesWithType;
    }
	private static void handleException(String message, Exception e) {
        String fullMessage = e == null ? message : message + ': ' + e.getMessage();
        System.debug(LoggingLevel.ERROR, fullMessage);
        throw new AuraHandledException(fullMessage);
    }
}