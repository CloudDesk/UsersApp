public class ManageUserAccessPartner {
  public permissionPartnerSoapSforceCom.Soap partnerConnection;
  public MetadataService.MetadataPort service;
  public ManageUserAccessPartner() {
        this(null, null, false);
  }

  //ConnectCallBack to connect partner wsdl and fetch login url and sessionId
  public ManageUserAccessPartner(String testUsername, String testPassword, Boolean isTest) {
 		String userName;
        String password;
    if (isTest) {
            userName = testUsername;
            password = testPassword;
        } else {
            userName = System.Label.Board_Book_Integration_Username;
            password = System.Label.Board_Book_Integration_Password;
        }
    try {
      partnerConnection = new permissionPartnerSoapSforceCom.Soap();
      permissionPartnerSoapSforceCom.LoginResult sessionInfoObj = partnerConnection.login(
        userName,
        password
      );
      partnerConnection.SessionHeader = new permissionPartnerSoapSforceCom.SessionHeader_element();
      partnerConnection.SessionHeader.sessionId = sessionInfoObj.sessionId;
      partnerConnection.endpoint_x = sessionInfoObj.serverUrl;
      service = new MetadataService.MetadataPort();
      service.SessionHeader = new MetadataService.SessionHeader_element();
      service.SessionHeader.sessionId = sessionInfoObj.sessionId;
      service.CallOptions = new MetadataService.CallOptions_element();
      service.timeout_x = 120000;
    } catch (exception e) {
      System.debug('Login failed:?? ' + e.getMessage());
    }
  }
  //Get list of Users on search used in Permission Analyzer component to fetch all the users based on search term.
  @AuraEnabled
  //USED
  public static List<User> getUser(String searchUserName) {
    //String searchName = '%' + searchUserName + '%' ;
    if (searchUserName != null) {
      List<User> userList = [
        SELECT Id, Name, ProfileId, Email
        FROM User
        WHERE Name LIKE :'%' + searchUserName + '%'
        LIMIT 1000
      ];
      return userList;
    } else {
      return new List<user>();
    }
  }
  @AuraEnabled
  //USED  
  public static List<PermissionSet> getUserPermsWrapper(string userId) {
    Set<Id> permId = new Set<Id>();
    Set<Id> permSetGrpId = new Set<Id>();
    List<PermissionSet> permSetList = new List<PermissionSet>();
    //List<PermissionSetGroupComponent> assignedPermSetForGroup = new List<PermissionSetGroupComponent>();
    if (userId != null) {
      for (permissionSetAssignment permsetAssign : [
        SELECT id, permissionsetId
        FROM permissionSetAssignment
        WHERE assigneeId = :userId
      ]) {
        permId.add(permsetAssign.permissionsetId);
      }
    }
    if (permId != null) {
      permSetList = [
        SELECT Id,Name, NamespacePrefix, IsCustom, Description, PermissionSetGroupId,PermissionSetGroup.Description, ProfileId, Type,
        Profile.Name,Profile.UserType, Profile.Description, Profile.UserLicense.Name, 
        License.Name, Label FROM PermissionSet WHERE Id IN :permId];
    }
    return permSetList;
  }

  //Need to alter for Profile Name
  @AuraEnabled
    //USED
  public static List<string> getProfileName(String ProfileId) {
      system.debug('ProfileId'+ ProfileId);
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    // system.debug('check sessionId'+ instance.partnerConnection.SessionHeader.sessionId );
    list<string> profileName = new List<string>();

    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
    String toolingQuery =
      '/services/data/v58.0/tooling/query/?q=select+id,+Name,+FullName+from+Profile+where+Id=\'' +
      ProfileId +
      '\'';
    String endPoint = baseUrl + toolingQuery;
    system.debug('check end Point' + endPoint);
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
      system.debug('check result' + res);
      if (res.getStatusCode() == 200) {
        system.debug('res.getBody()' + res.getBody());
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
          res.getBody()
        );
        system.debug('results:::' + results);
        List<Object> records = (List<Object>) results.get('records');
        system.debug('check recordsss' + records);
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

  @AuraEnabled
    //USED
  public static Map<String, SObjectPermissionWrapper> getObject(
    List<String> permissionSetIds
  ) {
    Map<String, SObjectPermissionWrapper> sObjectPermissionsMap = new Map<String, SObjectPermissionWrapper>();

    // Fetch and consolidate object permissions
    for (ObjectPermissions objPerm : [
      SELECT
        Id,
        SObjectType,
        PermissionsRead,
        PermissionsCreate,
        PermissionsEdit,
        PermissionsDelete,
        PermissionsViewAllRecords,
        PermissionsModifyAllRecords
      FROM ObjectPermissions
      WHERE ParentId IN :permissionSetIds
      ORDER BY SObjectType ASC
    ]) {
      SObjectPermissionWrapper wrapper;
      if (sObjectPermissionsMap.containsKey(objPerm.SObjectType)) {
        wrapper = sObjectPermissionsMap.get(objPerm.SObjectType);
        wrapper.objectPermissions = consolidateObjectPermissions(
          wrapper.objectPermissions,
          objPerm
        );
      } else {
        Map<String, Object> permissionSetMap = new Map<String, Object>();
        permissionSetMap.put('SObjectType', objPerm.SObjectType);
        permissionSetMap.put('PermissionsRead', objPerm.PermissionsRead);
        permissionSetMap.put('PermissionsCreate', objPerm.PermissionsCreate);
        permissionSetMap.put('PermissionsEdit', objPerm.PermissionsEdit);
        permissionSetMap.put('PermissionsDelete', objPerm.PermissionsDelete);
        permissionSetMap.put(
          'PermissionsViewAllRecords',
          objPerm.PermissionsViewAllRecords
        );
        permissionSetMap.put(
          'PermissionsModifyAllRecords',
          objPerm.PermissionsModifyAllRecords
        );

        wrapper = new SObjectPermissionWrapper(
          permissionSetMap,
          new Map<String, Object>()
        );
        sObjectPermissionsMap.put(objPerm.SObjectType, wrapper);
      }
    }

    // Fetch and consolidate field permissions
    for (FieldPermissions fieldPerm : [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE ParentId IN :permissionSetIds
      ORDER BY SObjectType ASC
      LIMIT 50000
    ]) {
      System.debug('inside field permissions for loop');
      SObjectPermissionWrapper wrapper;
      if (sObjectPermissionsMap.containsKey(fieldPerm.SObjectType)) {
        wrapper = sObjectPermissionsMap.get(fieldPerm.SObjectType);
        if (wrapper.fieldPermissions == null) {
          wrapper.fieldPermissions = new Map<String, Object>();
        }
        wrapper.fieldPermissions = consolidateFieldPermissions(
          wrapper.fieldPermissions,
          fieldPerm
        );
      } else {
        Map<String, Object> fieldPermissionsMap = new Map<String, Object>();
        Map<String, Object> fieldPermission = new Map<String, Object>();
        fieldPermission.put('PermissionsRead', fieldPerm.PermissionsRead);
        fieldPermission.put('PermissionsEdit', fieldPerm.PermissionsEdit);
        fieldPermission.put('Field', fieldPerm.Field);
        fieldPermissionsMap.put(fieldPerm.Field, fieldPermission);

        wrapper = new SObjectPermissionWrapper(
          new Map<String, Object>(),
          fieldPermissionsMap
        );
        sObjectPermissionsMap.put(fieldPerm.SObjectType, wrapper);
      }
    }

    system.debug('check sobject permisison map' + sObjectPermissionsMap);
    return sObjectPermissionsMap;
  }

  public static Map<String, Object> consolidateObjectPermissions(
    Map<String, Object> existingPermissions,
    ObjectPermissions newPerm
  ) {
    if (existingPermissions == null) {
      existingPermissions = new Map<String, Object>();
    }

    // Logic to consolidate object permissions
    existingPermissions.put(
      'PermissionsRead',
      (Boolean) existingPermissions.get('PermissionsRead') ||
      newPerm.PermissionsRead
    );
    existingPermissions.put(
      'PermissionsCreate',
      (Boolean) existingPermissions.get('PermissionsCreate') ||
      newPerm.PermissionsCreate
    );
    existingPermissions.put(
      'PermissionsEdit',
      (Boolean) existingPermissions.get('PermissionsEdit') ||
      newPerm.PermissionsEdit
    );
    existingPermissions.put(
      'PermissionsDelete',
      (Boolean) existingPermissions.get('PermissionsDelete') ||
      newPerm.PermissionsDelete
    );
    existingPermissions.put(
      'PermissionsViewAllRecords',
      (Boolean) existingPermissions.get('PermissionsViewAllRecords') ||
      newPerm.PermissionsViewAllRecords
    );
    existingPermissions.put(
      'PermissionsModifyAllRecords',
      (Boolean) existingPermissions.get('PermissionsModifyAllRecords') ||
      newPerm.PermissionsModifyAllRecords
    );

    return existingPermissions;
  }

  public static Map<String, Object> consolidateFieldPermissions(
    Map<String, Object> existingPermissions,
    FieldPermissions newPerm
  ) {
    // Logic to consolidate field permissions
    if (existingPermissions == null) {
      existingPermissions = new Map<String, Object>();
    }

    Map<String, Object> fieldPermission;
    if (existingPermissions.containsKey(newPerm.Field)) {
      fieldPermission = (Map<String, Object>) existingPermissions.get(
        newPerm.Field
      );
    } else {
      fieldPermission = new Map<String, Object>();
    }

    fieldPermission.put(
      'PermissionsRead',
      fieldPermission.containsKey('PermissionsRead')
        ? (Boolean) fieldPermission.get('PermissionsRead') ||
          newPerm.PermissionsRead
        : newPerm.PermissionsRead
    );
    fieldPermission.put(
      'PermissionsEdit',
      fieldPermission.containsKey('PermissionsEdit')
        ? (Boolean) fieldPermission.get('PermissionsEdit') ||
          newPerm.PermissionsEdit
        : newPerm.PermissionsEdit
    );

    existingPermissions.put(newPerm.Field, fieldPermission);

    return existingPermissions;
  }

 
     @AuraEnabled
  public static list<EntityDefinition> getEntityDefinition(string objType) {
    string query = 'select id, Label,QualifiedApiName,NamespacePrefix from EntityDefinition where DefaultCompactLayoutId != null ';
    string nullValue = '%_%';
    if (objType == 'Native') {
      query += 'and (not NameSpacePrefix LIKE : nullValue) order by Label';
    }

    if (objType == 'ManagedPackage') {
      query += 'and NameSpacePrefix like : nullValue order by Label';
    }

    list<EntityDefinition> endef = Database.Query(query);
    system.debug('check entity def' + endef);
    return endef;
  }

  /*
  @AuraEnabled
  public static map<string, string> getSystemAndUserDefinition() {
    map<string, string> systemAndUserResult = new Map<string, string>();
    Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe()
      .get('Profile')
      .getDescribe();
    for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
      Schema.DisplayType fielddataType = field.getDescribe().getType();
      if (fielddataType.name().toUpperCase() == 'BOOLEAN') {
        systemAndUserResult.put(
          field.getDescribe().getName(),
          field.getDescribe().getlabel()
        );
      }
    }

    return systemAndUserResult;
  }
*/

  /*
  @AuraEnabled
  public static list<map<string, string>> getObjectDefinition() {
    list<map<string, string>> objDefinition = new List<map<string, string>>();
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    permissionPartnerSoapSforceCom.DescribeGlobalResult describeGlobalResult = instance.partnerConnection.describeGlobal();
    permissionPartnerSoapSforceCom.DescribeGlobalSObjectResult[] sObjects = describeGlobalResult.sobjects;
    for (
      permissionPartnerSoapSforceCom.DescribeGlobalSObjectResult sObj : sObjects
    ) {
      String objectName = sObj.name;
      string objectLable = sObj.label;
      map<string, string> objMap = new Map<string, string>();
      objMap.put('Label', sObj.label);
      objMap.put('Name', sObj.name);
      objDefinition.add(objMap);
    }
    system.debug(objDefinition + 'objMap');
    system.debug('size objMap' + objDefinition.size());
    return objDefinition;
  }
*/

  @AuraEnabled
    //USED
  public static list<map<string, Object>> getFieldDefinition(
    string objectName
  ) {
    list<Map<string, Object>> fieldDefList = new List<map<string, Object>>();
    Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe()
      .get(objectName)
      .getDescribe();
    for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
      if (field.getDescribe().isPermissionable()) {
        Map<string, Object> fieldDefMap = new Map<string, Object>();
        fieldDefMap.put('Label', field.getDescribe().getlabel());
        fieldDefMap.put('Name', field.getDescribe().getName());
        fieldDefMap.put(
          'isPermissionable',
          field.getDescribe().isPermissionable()
        );
        fieldDefMap.put('isCalculated', field.getDescribe().isCalculated());
        system.debug(fieldDefMap);
        fieldDefList.add(fieldDefMap);
      }
    }
    return fieldDefList;
  }
  public class getFieldWrapper {
    @AuraEnabled
    public List<Map<String, Object>> fieldLabelMap { get; set; }
    @AuraEnabled
    public Boolean hasObjAccess { get; set; }      
    @AuraEnabled
    public Map<String, Boolean> hasFieldAccess { get; set; }
    @AuraEnabled
    public List<Object> dependentObj { get; set; }
    public getFieldWrapper(
      List<Map<String, Object>> fieldLabelMap,
      Boolean hasObjAccess,      
      Map<String, Boolean> hasFieldAccess,List<Object> dependentObj
    ) {
      this.fieldLabelMap = fieldLabelMap;
      this.hasObjAccess = hasObjAccess;      
      this.hasFieldAccess = hasFieldAccess;
      this.dependentObj = dependentObj;
    }
  }

  @AuraEnabled
    //USED
  public static getFieldWrapper getFields(
    String sObjectNameList,
    String permissionSetIdToFetchName
  ) {
    list<map<string, Object>> fieldLabelMap = ManageUserAccessPartner.getFieldDefinition(
      sObjectNameList
    );
    return new getFieldWrapper(
      fieldLabelMap,
      ManageUserAccessPartner.checkSObjType(sObjectNameList),
      checkFieldType(sObjectNameList),
      ManageUserAccess.checkDependency(sObjectNameList)
      
    );
  }
     @AuraEnabled
    //USED
  public static Boolean checkSObjType(string sObjName) {
    for (
      Schema.PicklistEntry p : objectPermissions.SObjectType.getDescribe()
        .getPicklistValues()
    ) {
      if (sObjName == p.getValue()) {
        return true;
      }
    }
    return false;
  }

  @AuraEnabled
    //USED
  public static Map<String, Boolean> checkFieldType(String sObjName) {
    Map<String, Boolean> fieldMap = new Map<String, Boolean>();
    for (
      Schema.PicklistEntry p : fieldPermissions.Field.getDescribe()
        .getPicklistValues()
    ) {
      if (sObjName == p.getValue().split('\\.')[0]) {
        fieldMap.put(p.getValue(), true);
      }
    }
    return fieldMap;
  }
  
  Public Class getRecTypeWrapper {
    @AuraEnabled
    public List<RecordType> recordTypeList { get; set; }
    @AuraEnabled
    public Map<String, Object> recordTypeVisibility { get; set; }
    @AuraEnabled
    public List<String> permName { get; set; }
    Public getRecTypeWrapper(
      List<RecordType> recordTypeList,
      Map<string, Object> recordTypeVisibility,
      List<String> permName
    ){
      this.recordTypeList = recordTypeList;
      this.recordTypeVisibility = recordTypeVisibility != null
        ? recordTypeVisibility
        : new Map<String, Object>();
      this.permName = permName;
    }
        
  }
  @AuraEnabled(cacheable=true)
    //USED
  Public Static getRecTypeWrapper  getRecTypes(
    String objName,
    String permissionSetId){
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<String> permSetNames = new List<String>();
    Map<String, Object> recordTypeVisibility = new Map<string, Object>();
    if(permissionSetId != null && permissionSetId != 'PermAll')
    {		
      try {
        for (PermissionSet perm : [
          SELECT
            Id,
            Name,
            NamespacePrefix,
            IsCustom,
            PermissionSetGroupId,
            ProfileId,
            Type,
            Profile.Name,
            Label
          FROM PermissionSet
          WHERE Id = :permissionSetId
        ]) {
          if (perm.Type == 'Profile') {
            system.debug('Inside Profile');
            permSetNames = getProfileName( perm.ProfileId);
            recordTypeVisibility = getProfileRecordIdRetriever(permSetNames,objName);
          } else if (perm.Type != 'Profile' && perm.Type != 'Group') {
            String permSetName;
            if (perm.NamespacePrefix != null) {
              permSetName = Perm.NamespacePrefix + '__' + perm.Name;
              permSetNames.add(permSetName);
            } else {
              PermSetName = perm.Name;
              permSetNames.add(permSetName);
            }
            recordTypeVisibility = getPermissionSetRecordTypeRetriever(
              permSetNames,
              objName
            );
          }
        }
      } catch (exception e) {
        throw new AuraHandledException(
          'An error occurred while fetching recordType visibility' +
          e.getMessage()
        );
      }
      } 
        return new getRecTypeWrapper([SELECT Id, Name, DeveloperName, NamespacePrefix FROM RecordType WHERE SobjectType = :objName], recordTypeVisibility, permSetNames);
    }
  
    public class SObjectPermissionWrapper {
    @AuraEnabled
    public Map<string, Object> objectPermissions;
    @AuraEnabled
    public Map<string, Object> fieldPermissions;
    public SObjectPermissionWrapper(
      Map<string, Object> objectPermissions,
      Map<string, Object> fieldPermissions
    ) {
      this.objectPermissions = objectPermissions != null
        ? objectPermissions
        : new Map<String, Object>();
      this.fieldPermissions = fieldPermissions != null
        ? fieldPermissions
        : new Map<String, Object>();
    }
    public SObjectPermissionWrapper() {
      this.objectPermissions = new Map<string, Object>();
      this.fieldPermissions = new Map<string, Object>();
    }
  }

  @AuraEnabled
    //USED
  public static Map<String, Object> getPermissionSetRecordTypeRetriever(
    List<String> permissionsSetNames,
    String sObjName
  ) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
        'PermissionSet',
        permissionsSetNames
      )
      .getRecords();
      system.debug('permissionSets'+ permissionSets);
    Map<String, Object> permissionSetMap = new Map<String, Object>();
    if (permissionSets != null) {
      try {
        for (MetadataService.PermissionSet permissionSet : permissionSets) {
          if (PermissionSet.recordTypeVisibilities != null) {
            for (
              MetadataService.PermissionSetRecordTypeVisibility recordTypeVisibility : PermissionSet.recordTypeVisibilities
            ) {
              if (
                recordTypeVisibility.recordType.startsWith(sObjName + '.') ||
                recordTypeVisibility.recordType.startsWith('PersonAccount.')
              ) {
                system.debug(
                  'recordTypeVisibility.recordType' +
                  recordTypeVisibility.recordType
                );
                system.debug(
                  'recordTypeVisibility.recordType' +
                  recordTypeVisibility.visible
                );
                Map<String, Object> recordTypeObj = new Map<String, Object>();
                recordTypeObj.put(
                  'RecordType',
                  recordTypeVisibility.recordType
                );
                recordTypeObj.put('Visible', recordTypeVisibility.visible);
                // Add the recordTypeObj to the profileMap
                permissionSetMap.put(
                  recordTypeVisibility.recordType,
                  recordTypeObj
                );
              }
            }
          }
        }
      } catch (exception e) {
        throw new AuraHandledException(
          'An error occurred while field RecordType Permissions through permission Sets: ' +
          e.getMessage()
        );
      }
    }
    return permissionSetMap;
  }

  @AuraEnabled
    //USED
  public static Map<String, Object> getProfileRecordIdRetriever(
    List<String> ProfileName,
    String sObjName
  ) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata(
        'Profile',
        ProfileName
      )
      .getRecords();
    Map<String, Object> profileRecTypeMap = new Map<String, Object>();
    if (profiles != null) {
      try {
        for (MetadataService.Profile prof : profiles) {
          system.debug('Check prof' + prof.fullName);
          if (prof.recordTypeVisibilities != null) {
            for (
              MetadataService.ProfileRecordTypeVisibility recordTypeVisibility : prof.recordTypeVisibilities
            ) {
              if (
                recordTypeVisibility.recordType.startsWith(sObjName + '.') ||
                recordTypeVisibility.recordType.startsWith('PersonAccount.')
              ) {
                system.debug(
                  'recordTypeVisibility.recordType' +
                  recordTypeVisibility.recordType
                );
                system.debug(
                  'recordTypeVisibility.recordType' +
                  recordTypeVisibility.visible
                );
                Map<String, Object> recordTypeObj = new Map<String, Object>();
                recordTypeObj.put(
                  'RecordType',
                  recordTypeVisibility.recordType
                );
                recordTypeObj.put('Visible', recordTypeVisibility.visible);
                recordTypeObj.put('Default_x', recordTypeVisibility.default_x);
                profileRecTypeMap.put(
                  recordTypeVisibility.recordType,
                  recordTypeObj
                );
              }
            }
          }
        }
      } catch (exception e) {
        throw new AuraHandledException(
          'An error occurred while field RecordType Permissions through Profile: ' +
          e.getMessage()
        );
      }
    }
    system.debug('profileRecTypeMap' + profileRecTypeMap);
    return profileRecTypeMap;
  }
 

  /* public static list<map<string,string>> getObjPerm(string query)
    {
        list<map<string,string>>  objectPermList = new list<map<string,string>>();
        ManageUserAccessPartner instance = new ManageUserAccessPartner();
        permissionPartnerSoapSforceCom.QueryResult objPermList = instance.partnerConnection.query(query);
        for(permissionSobjectPartnerSoapSforceCom.sObject_x record : objPermList.records)
        {
            Map<string,string> objPermMap = new map<String,string>();
            objPermMap.put('Id', (String) record.Id);
            objPermMap.put('SobjectType', (String) record.SobjectType);
            objPermMap.put('parentId', (String) record.parentId);
            objPermMap.put('PermissionsRead', (String) record.PermissionsRead);
            objPermMap.put('PermissionsCreate', (String) record.PermissionsCreate);
            //objPermMap.put('PermissionsEdit', record.PermissionsEdit);
            objPermMap.put('PermissionsDelete', (String) record.PermissionsDelete);
            objPermMap.put('PermissionsModifyAllRecords', (String) record.PermissionsModifyAllRecords);
            objPermMap.put('PermissionsViewAllRecords', (String) record.PermissionsViewAllRecords);
            objectPermList.add(objPermMap);
        }
        system.debug('object Perm List' +objectPermList );
        return objectPermList;
    }
    
    public static list<map<string,string>> getFieldPerm(string query)
    {
        list<map<string,string>>  fieldPermList = new list<map<string,string>>();
        ManageUserAccessPartner instance = new ManageUserAccessPartner();
        permissionPartnerSoapSforceCom.QueryResult fieldPermListQuery = instance.partnerConnection.query(query);
        for(permissionSobjectPartnerSoapSforceCom.sObject_x record : fieldPermListQuery.records)
        {
            Map<string,string> fieldPermMap = new map<String,string>();
            fieldPermMap.put('Id', (String) record.Id);
            fieldPermMap.put('SobjectType', (String) record.SobjectType);
            //fieldPermMap.put('PermissionsEdit', record.PermissionsEdit);
            fieldPermMap.put('PermissionsRead', (String) record.PermissionsRead);
            fieldPermMap.put('Field', (String) record.Field);
            fieldPermMap.put('ParentId', (String) record.ParentId);
            
            fieldPermList.add(fieldPermMap);
        }
        system.debug('object Perm List' +fieldPermList );
        return fieldPermList;
    }*/
  
    /*
  @AuraEnabled
  public static Map<string, ObjectPermissions> updateObjectPermissions(
    map<String, Boolean> objPermission,
    String permissionSetIdToUpdate,
    String objName
  ) {
    system.debug('from javascript' + objPermission);
    Map<string, ObjectPermissions> objPermWithObjNameMap = new Map<string, ObjectPermissions>();
    if (permissionSetIdToUpdate != null && objPermission != null) {
      ObjectPermissions objToUpsert = new ObjectPermissions();

      try {
        List<ObjectPermissions> objPerms = [
          SELECT
            Id,
            ParentId,
            SobjectType,
            PermissionsCreate,
            PermissionsRead,
            PermissionsEdit,
            PermissionsDelete,
            PermissionsModifyAllRecords,
            PermissionsViewAllRecords
          FROM ObjectPermissions
          WHERE ParentId = :permissionSetIdToUpdate AND SobjectType = :objName
        ];
        system.debug('objPerms' + objPerms);

        if (!objPerms.isEmpty()) {
          objToUpsert.Id = objPerms[0].Id;
        } else {
          objToUpsert.ParentId = permissionSetIdToUpdate;
          objToUpsert.SobjectType = objName;
        }

        objToUpsert.PermissionsCreate = objPermission.get('PermissionsCreate');
        objToUpsert.PermissionsRead = objPermission.get('PermissionsRead');
        objToUpsert.PermissionsEdit = objPermission.get('PermissionsEdit');
        objToUpsert.PermissionsDelete = objPermission.get('PermissionsDelete');
        objToUpsert.PermissionsModifyAllRecords = objPermission.get(
          'PermissionsModifyAllRecords'
        );
        objToUpsert.PermissionsViewAllRecords = objPermission.get(
          'PermissionsViewAllRecords'
        );
        system.debug('check obj permissions to upsert>>>>>>>>' + objToUpsert);
        objPermWithObjNameMap.put(objName, objToUpsert);
        upsert objToUpsert;
        return objPermWithObjNameMap;
      } catch (exception e) {
        throw new AuraHandledException(
          'An error occurred while upserting Object Permissions: ' +
          e.getMessage()
        );
      }
    }
    return null;
  }
*/
  public class FieldPermissionUpdateWrapper {
    @AuraEnabled
    public String Field { get; set; }
    @AuraEnabled
    public Boolean PermissionsRead { get; set; }
    @AuraEnabled
    public Boolean PermissionsEdit { get; set; }
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public Boolean hasEditAccess { get; set; }
    @AuraEnabled
    public Boolean mutedPermissionsRead { get; set; }
    @AuraEnabled
    public Boolean mutedPermissionsEdit { get; set; }
  }
  @AuraEnabled
    //USED
  public static list<FieldPermissionUpdateWrapper> updateFieldPermissions(
    List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList,
    String permissionSetId,
    String objName,
    String fieldPermType
  ) {
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
        for (FieldPermissions fieldPerm : [
          SELECT Id, SObjectType, Field, PermissionsRead, PermissionsEdit
          FROM FieldPermissions
          WHERE parentId = :permissionSetId AND Field IN :fieldNames
        ]) {
          existingPermissionsMap.put(fieldPerm.Field, fieldPerm);
        }
        for (
          FieldPermissionUpdateWrapper fieldPermWrap : FieldPermissionWrapperList
        ) {
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
        system.debug('check field error' + e.getMessage());
        throw new AuraHandledException(
          'An error occurred while upserting Field Permissions: ' +
          e.getMessage()
        );
      }
    }

    return null;
  }
  public class RecordTypeUpdateWrapper {
    @AuraEnabled
    public String RecordType { get; set; }
    @AuraEnabled
    public Boolean Visible { get; set; }
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String developerName { get; set; }
    @AuraEnabled
    public Boolean Default_x { get; set; }
  }
  @AuraEnabled
    //USED
  public static List<RecordTypeUpdateWrapper> updateRecordTypeVisibility(
    List<RecordTypeUpdateWrapper> recordTypeVisibility,
    List<String> profileOrPermSetNames
  ) {
    system.debug('profileOrPermSetNames' + profileOrPermSetNames);
    List<RecordTypeUpdateWrapper> result = new List<RecordTypeUpdateWrapper>();
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    if (profileOrPermSetNames != null && !profileOrPermSetNames.isEmpty()) {
      system.debug('inside if');
      try {
        // Read profiles
        List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata(
            'Profile',
            profileOrPermSetNames
          )
          .getRecords();
        system.debug('check profiles+' + profiles);
        if (profiles[0].fullName != null) {
          system.debug('inside profile');
          if (!processProfiles(profiles, recordTypeVisibility)) {
            return null;
          }
        } else {
          // Read permission sets
          List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
              'PermissionSet',
              profileOrPermSetNames
            )
            .getRecords();
          if (permissionSets != null && !permissionSets.isEmpty()) {
            system.debug('inside permset');
            result = manageUserAccess.updatePermissionSetRecordTypeVisibility(
              profileOrPermSetNames,
              recordTypeVisibility
            );

            if (result.isEmpty()) {
              return null;
            }
          } else {
            return null;
          }
        }
      } catch (Exception e) {
        System.debug('Exception: ' + e.getMessage());
        throw new AuraHandledException(
          'An error occurred while updating RecordType Permissions: ' +
          e.getMessage()
        );
      }
    }
    return recordTypeVisibility;
  }

    //USED
  private static Boolean processProfiles(
    List<MetadataService.Profile> profiles,
    List<RecordTypeUpdateWrapper> recordTypeVisibility
  ) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<MetadataService.Profile> profilesToUpdate = new List<MetadataService.Profile>();

    for (MetadataService.Profile profile : profiles) {
      MetadataService.Profile updatedProfile = new MetadataService.Profile();
      updatedProfile.fullName = profile.fullName;
      updatedProfile.recordTypeVisibilities = new List<MetadataService.ProfileRecordTypeVisibility>();

      Map<String, MetadataService.ProfileRecordTypeVisibility> existingVisibilities = new Map<String, MetadataService.ProfileRecordTypeVisibility>();
      if (profile.recordTypeVisibilities != null) {
        for (
          MetadataService.ProfileRecordTypeVisibility visibility : profile.recordTypeVisibilities
        ) {
          existingVisibilities.put(visibility.recordType, visibility);
        }
      }
      for (RecordTypeUpdateWrapper wrapper : recordTypeVisibility) {
        MetadataService.ProfileRecordTypeVisibility visibility = existingVisibilities.get(
          wrapper.RecordType
        );
        if (visibility == null) {
          visibility = new MetadataService.ProfileRecordTypeVisibility();
          visibility.recordType = wrapper.RecordType;
        }
        system.debug('wrapper label' + wrapper.label);
        // visibility.label = wrapper.label;
        visibility.visible = wrapper.Visible != null ? wrapper.Visible : false; // Ensure boolean value is set
        visibility.default_x = wrapper.Default_x != null
          ? wrapper.Default_x
          : false;
        updatedProfile.recordTypeVisibilities.add(visibility);
      }
      profilesToUpdate.add(updatedProfile);
    }

    List<MetadataService.UpsertResult> results = instance.service.upsertMetadata(
      profilesToUpdate
    );
    return handleUpsertResults(results);
  }

    //USED
  private static Boolean handleUpsertResults(
    List<MetadataService.UpsertResult> results
  ) {
    for (MetadataService.UpsertResult upsertResult : results) {
      if (!upsertResult.success) {
        for (MetadataService.Error error : upsertResult.errors) {
          System.debug(
            'Error: ' + error.message + ' Status Code: ' + error.statusCode
          );
          if (error.fields != null) {
            for (String field : error.fields) {
              System.debug('Error Field: ' + field);
            }
          }
        }
        throw new AuraHandledException(
          'Error updating profile or permission set: ' +
          upsertResult.errors[0].message
        );
      } else {
        System.debug(
          'Record type visibilities updated successfully for: ' +
          upsertResult.fullName
        );
      }
    }
    return true;
  }

  @AuraEnabled
    //USED
  public static Map<String, List<String>> retrieveObjPermissionsName(
    String permissionType,
    List<String> permSetIds,
    String objName,
    String fieldName
  ) {
    Map<String, List<String>> permMap = new Map<String, List<String>>();
      system.debug('objName : '+objName+'permSetIds : '+ permSetIds + 'fieldName : ' + fieldName  + 'permissionType : '+ permissionType);
    if (fieldName == null) {
        system.debug('inside object');
      for (ObjectPermissions objPerm : [
        SELECT
          Id,
          PermissionsRead,
          Parent.Type,
          Parent.Name,
          Parent.Profile.Name,
          PermissionsEdit,
          PermissionsCreate,
          PermissionsDelete,
          PermissionsViewAllRecords,
          PermissionsModifyAllRecords
        FROM ObjectPermissions
        WHERE SObjectType = :objName AND ParentId IN :permSetIds
      ]) {
        if (Boolean.valueOf(objPerm.get(permissionType))) {
          if (objPerm.Parent.Type == 'Profile') {
            if (!permMap.containsKey('Profile')) {
              permMap.put('Profile', new List<String>());
            }
            permMap.get('Profile').add(objPerm.Parent.Profile.Name);
          }
          if (
            objPerm.Parent.Type != 'Profile' &&
            objPerm.Parent.Type != 'Group'
          ) {
            if (!permMap.containsKey('PermissionSet')) {
              permMap.put('PermissionSet', new List<String>());
            }
            permMap.get('PermissionSet').add(objPerm.Parent.Name);
          }
          if (objPerm.Parent.Type == 'Group') {
            if (!permMap.containsKey('Group')) {
              permMap.put('Group', new List<String>());
            }
            permMap.get('Group').add(objPerm.Parent.Name);
          }
        }
      }
    }
    if (fieldName != null && fieldName != '') {
        system.debug('inside field');
      for (FieldPermissions field : [
        SELECT
          Id,
          PermissionsEdit,
          PermissionsRead,
          Parent.Type,
          Parent.Name,
          Parent.Profile.Name
        FROM FieldPermissions
        WHERE
          SObjectType = :objName
          AND ParentId IN :permSetIds
          AND Field = :fieldName
      ]) {
        if (Boolean.valueOf(field.get(permissionType))) {
          if (field.Parent.Type == 'Profile') {
            if (!permMap.containsKey('Profile')) {
              permMap.put('Profile', new List<String>());
            }
            permMap.get('Profile').add(field.Parent.Profile.Name);
          }
          if (field.Parent.Type != 'Profile' && field.Parent.Type != 'Group') {
            if (!permMap.containsKey('Permission Set')) {
              permMap.put('PermissionSet', new List<String>());
            }
            permMap.get('PermissionSet').add(field.Parent.Name);
          }
          if (field.Parent.Type == 'Group') {
            if (!permMap.containsKey('Group')) {
              permMap.put('Group', new List<String>());
            }
            permMap.get('Group').add(field.Parent.Name);
          }
        }
      }
    }
    system.debug('check permMap::' + permMap);
    return permMap;
  }
  public class MutePermissionWrapper {
    @AuraEnabled
    public String mutePermSetId { get; set; }
    @AuraEnabled
    public SObjectPermissionWrapper wrapper { get; set; }
    //@AuraEnabled public Map<string,Object> recordTypeVisibilities;

    public MutePermissionWrapper(
      String mutePermSetId,
      SObjectPermissionWrapper wrapper
    ) {
      this.mutePermSetId = mutePermSetId;
      this.wrapper = wrapper;
    }
  }
  @AuraEnabled
    //USED
  public static MutePermissionWrapper getMutedObjandFieldPermissions(
    String groupId,
    List<String> objNames,
    String objName
  ) {
    system.debug('check group id' + groupId);
    system.debug('objName' + objNames);
    string permSetId;
    if (groupId != null) {
      system.debug('Inside Not Null');
      List<PermissionSetGroupComponent> psgg = [
        SELECT
          Id,
          PermissionSetGroup.DeveloperName,
          PermissionSetGroup.MasterLabel,
          PermissionSetId
        FROM PermissionSetGroupComponent
        WHERE
          PermissionSetGroupId = :groupId
          AND (NOT PermissionSet.Name LIKE '%_%')
      ];
      system.debug('Per Set Grp Com' + psgg);
      //for(PermissionSetGroupComponent permSetGrpComp : psgg){
      //system.debug('Per Set Grp Com'+permSetGrpComp);
      if (!psgg.isEmpty()) {
        system.debug('inside not null');
        permSetId = psgg[0].PermissionSetId;
      }
      if (psgg.isEmpty()) {
        system.debug('inside null');

        // Fetch the permission set group
        PermissionSetGroup permSetGrp = [
          SELECT Id, MasterLabel, DeveloperName
          FROM PermissionSetGroup
          WHERE Id = :groupId
          LIMIT 1
        ];

        if (permSetGrp != null) {
          // Create a new MutingPermissionSet
          MutingPermissionSet mutePerm = new MutingPermissionSet();
          mutePerm.MasterLabel = permSetGrp.MasterLabel + ' Muted';
          mutePerm.DeveloperName = permSetGrp.DeveloperName + '_Muted';
          insert mutePerm;

          // Get the Id of the newly inserted MutingPermissionSet
          permSetId = mutePerm.Id;

          // Create and insert the PermissionSetGroupComponent
          PermissionSetGroupComponent component = new PermissionSetGroupComponent(
            PermissionSetGroupId = permSetGrp.Id,
            PermissionSetId = permSetId
          );
          insert component;
        } else {
          system.debug('PermissionSetGroup not found for Id: ' + groupId);
        }
      }
      //}
      system.debug('check permSetId' + permSetId);
    }
    SObjectPermissionWrapper objAndFieldPermWrapper = ManageUserAccessPartner.objAndFieldPermHelper(
      permSetId,
      objNames,
      objName
    );
    return new MutePermissionWrapper(permSetId, objAndFieldPermWrapper);
  }
  @AuraEnabled
    //USED
  public static SObjectPermissionWrapper objAndFieldPermHelper(
    String permSetId,
    List<String> objNames,
    String objName
  ) {
    system.debug('er set Id' + permSetId);
    Map<String, Object> permissionSetMap = new Map<String, Object>();
    Map<String, Object> fieldPermissionsMap = new Map<String, Object>();
    if (permSetId != null) {
      system.debug('inside perm set NOT null');
      for (objectPermissions objPerm : [
        SELECT
          Id,
          SObjectType,
          PermissionsCreate,
          PermissionsEdit,
          PermissionsRead,
          PermissionsDelete,
          PermissionsModifyAllRecords,
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
          objectPermMap.put(
            'PermissionsViewAllRecords',
            objPerm.PermissionsViewAllRecords
          );
          objectPermMap.put(
            'PermissionsModifyAllRecords',
            objPerm.PermissionsModifyAllRecords
          );
          permissionSetMap.put(objPerm.SObjectType, objectPermMap);
        }
      }
      for (FieldPermissions fieldPerm : [
        SELECT Id, Field, PermissionsRead, PermissionsEdit, SObjectType
        FROM FieldPermissions
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

  public class MutePermissionUpdateWrapper {
    @AuraEnabled
    public Map<string, Object> objectPermissions { get; set; }
    @AuraEnabled
    public List<FieldPermissionUpdateWrapper> fieldPermissions { get; set; }
    public MutePermissionUpdateWrapper(
      Map<string, Object> objectPermissions,
      List<FieldPermissionUpdateWrapper> fieldPermissions
    ) {
      this.objectPermissions = objectPermissions;
      this.fieldPermissions = fieldPermissions;
    }
  }

  @AuraEnabled
    //USED
  public static MutePermissionUpdateWrapper updateMutePermissions(
    string mutePermId,
    string permSetId,
    string objName,
    Map<String, Map<String, Boolean>> objPermission,
    List<FieldPermissionUpdateWrapper> fieldPermissionWrapperList
  ) {
    Map<string, Object> objResult = new Map<String, Object>();
    List<FieldPermissionUpdateWrapper> fieldResult = new List<FieldPermissionUpdateWrapper>();
    if (objPermission != null) {
      objResult = ManageUserAccessPartner.updateObjPermissions(
        objPermission,
        mutePermId
      );
    }
    if (fieldPermissionWrapperList != null) {
      fieldResult = ManageUserAccessPartner.updateFieldPermissions(
        fieldPermissionWrapperList,
        mutePermId,
        objName,
        'MutePermissions'
      );
    }
    MutePermissionUpdateWrapper objAndFieldPermResultWrapper = new MutePermissionUpdateWrapper(
      objResult,
      fieldResult
    );
    return objAndFieldPermResultWrapper;
  }
  public class updatedObjPermResult {
    @AuraEnabled
    public Map<String, Object> objectPerms { get; set; }
    @AuraEnabled
    public List<FieldPermissionUpdateWrapper> fieldPerms { get; set; }
    public updatedObjPermResult(
      Map<String, Object> objectPerms,
      List<FieldPermissionUpdateWrapper> fieldPerms
    ) {
      this.objectPerms = objectPerms;
      this.fieldPerms = fieldPerms;
    }
  }
  @AuraEnabled
    //USED
  public static Map<String, Object> updateObjPermissions(
    Map<String, Map<String, Object>> objPerms,
    String permSetId
  ) {
    Map<String, Object> resultMap = new Map<String, Object>();
    List<ObjectPermissions> objPermissionsToUpsert = new List<ObjectPermissions>();

    if (permSetId != null && objPerms != null && !objPerms.isEmpty()) {
      try {
        // Collect all object names from the input map
        Set<String> objNames = objPerms.keySet();

        // Query existing ObjectPermissions records for all objects at once
        List<ObjectPermissions> existingObjPerms = [
          SELECT
            Id,
            ParentId,
            SobjectType,
            PermissionsCreate,
            PermissionsRead,
            PermissionsEdit,
            PermissionsDelete,
            PermissionsModifyAllRecords,
            PermissionsViewAllRecords
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
          objToUpsert.PermissionsCreate = (Boolean) permissionsMap.get(
            'PermissionsCreate'
          );
          objToUpsert.PermissionsRead = (Boolean) permissionsMap.get(
            'PermissionsRead'
          );
          objToUpsert.PermissionsEdit = (Boolean) permissionsMap.get(
            'PermissionsEdit'
          );
          objToUpsert.PermissionsDelete = (Boolean) permissionsMap.get(
            'PermissionsDelete'
          );
          objToUpsert.PermissionsModifyAllRecords = (Boolean) permissionsMap.get(
            'PermissionsModifyAllRecords'
          );
          objToUpsert.PermissionsViewAllRecords = (Boolean) permissionsMap.get(
            'PermissionsViewAllRecords'
          );

          // Add to the list of records to upsert
          objPermissionsToUpsert.add(objToUpsert);

          // Add the result to the resultMap
          resultMap.put(objName, objToUpsert);
        }

        // Perform a bulk upsert of all ObjectPermissions records
        system.debug('objPermissionsToUpsert' + objPermissionsToUpsert);
        upsert objPermissionsToUpsert;
      } catch (Exception e) {
        system.debug('e.getMessage()' + e.getMessage());
        throw new AuraHandledException(e.getMessage());
      }
    }
    return resultMap;
  }

  @AuraEnabled
    //USED
  public static updatedObjPermResult updateSobjectMeta(
    Map<String, Map<String, Boolean>> objectPermissionsMap,
    List<FieldPermissionUpdateWrapper> fieldPerms,
    String permSetId,
    String objName
  ) {
    Map<String, Object> objResult = new Map<String, Object>();
    List<FieldPermissionUpdateWrapper> fieldResult = new List<FieldPermissionUpdateWrapper>();

    try {
      if (objectPermissionsMap != null && !objectPermissionsMap.isEmpty()) {
        system.debug('check objectPermissionsMap' + objectPermissionsMap);
        objResult = updateObjPermissions(objectPermissionsMap, permSetId);
          system.debug('objResult'+objResult);
      }

      if (fieldPerms != null && !fieldPerms.isEmpty()) {
        fieldResult = updateFieldPermissions(
          fieldPerms,
          permSetId,
          objName,
          ''
        );
          system.debug('fieldResult'+fieldResult);
      }
      // Return the results as an updatedObjPermResult instance
      return new updatedObjPermResult(objResult, fieldResult);
    } catch (Exception e) {
      // Throw an error if any of the updates fail
      throw new AuraHandledException(
        'An error occurred while updating SObject metadata: ' + e.getMessage()
      );
    }
  }
    
  @AuraEnabled
    //USED
  Public static updatedObjPermResult retreiveExistingPermissionSet(String permSetId, List<String> objNames, List<FieldPermissionUpdateWrapper> fieldMap, List<String> fieldsList){
      Map<String,Object> existingObjPermsMap = new Map<String,Object>();
      List<FieldPermissionUpdateWrapper> existingFieldPermMap = new List<FieldPermissionUpdateWrapper>();
     if(permSetId != null && permSetId != ''){
         for(ObjectPermissions objPerm : [Select Id, SObjectType, PermissionsRead, PermissionsDelete, PermissionsEdit, PermissionsCreate,PermissionsViewAllRecords, PermissionsModifyAllRecords FROM Objectpermissions WHERE Parent.Id = :permSetId AND SobjectType IN :objNames]){
             if(objPerm != null){
                 Map<String,Boolean> objMap = new Map<String,Boolean>(); 
                 objMap.put('PermissionsRead',objPerm.PermissionsRead);
                 objMap.put('PermissionsDelete',objPerm.PermissionsDelete);
                 objMap.put('PermissionsEdit',objPerm.PermissionsEdit);
                 objMap.put('PermissionsCreate',objPerm.PermissionsCreate);
                 objMap.put('PermissionsViewAllRecords',objPerm.PermissionsViewAllRecords);
                 objMap.put('PermissionsModifyAllRecords',objPerm.PermissionsModifyAllRecords);
                 existingObjPermsMap.put(objPerm.SobjectType, objMap);
             }
         }
       if(!fieldMap.isEmpty()){
         for(FieldPermissions fieldPerm : [Select Id, PermissionsRead, PermissionsEdit, Field, sObjectType from FieldPermissions where parent.Id = :permSetId and Field IN :fieldsList ]){
             If(fieldPerm != null){
                 for(FieldPermissionUpdateWrapper  fieldPermWrapper: fieldMap){
                     if(fieldPermWrapper.Field == fieldPerm.Field){
                         fieldPermWrapper.PermissionsRead = fieldPerm.PermissionsRead;
                         fieldPermWrapper.PermissionsEdit = fieldPerm.PermissionsEdit;
                         existingFieldPermMap.add(fieldPermWrapper);
                     }
                 }
             }
         }
       }
     }
      return new updatedObjPermResult(existingObjPermsMap,existingFieldPermMap);
  }
  
  @AuraEnabled
    //USED
    Public Static PermissionSet createNewPermissionSet(Map<String,Object> newPermSet, List<Id> userIds,
        Map<String, Map<String, Boolean>> objectPermissionsMap,
        List<FieldPermissionUpdateWrapper> fieldPerms,String objName, String updateType, String tabToUpdate, Map<String, Boolean> userToUpdate,List<RecordTypeUpdateWrapper> recTypeToUpdate){
           String permSetId;  
            if(updateType == 'Obj' || updateType == 'User'){
                system.debug('Obj type' + updateType);
                permSetId = ManageUserAccess.createPermissionSet(newPermSet,userIds);                
             }
            if(updateType == 'Obj'){
                if(permSetId != null && permSetId != ''){
                        updateSobjectMeta(objectPermissionsMap,fieldPerms,permSetId,objName);
                  } 
            }
            if(updateType == 'User'){
                if(permSetId != null && permSetId != ''){
                        updateUserPermissions(permSetId,'',userToUpdate);
                  } 
            }
            if(updateType == 'Tab'){
                permSetId = ManageUserAccess.createPermissionSetWithTabsAndUsers(newPermSet,tabToUpdate,userIds);
                //ManageUserAccess.updatetab(tabToUpdate,permSetApiName);
            }
            if(updateType == 'RecordType'){
                permSetId = createPermissionSetWithRecordTypeAndUsers(newPermSet,recTypeToUpdate,userIds);
            }
	   return [SELECT Id,Name, NamespacePrefix, IsCustom, Description, PermissionSetGroupId, ProfileId, Type,
               Profile.Name,Profile.UserType, Profile.Description, Profile.UserLicense.Name, 
               License.Name, Label FROM PermissionSet WHERE Id =: permSetId];  
    }
    
    @AuraEnabled
    //USED
public static String createPermissionSetWithRecordTypeAndUsers(
    Map<String, Object> newPermSet,
    List<RecordTypeUpdateWrapper> recTypeToUpdate,
    List<String> userIds
) {
    System.debug('Method createPermissionSetWithRecordTypeAndUsers Called');
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    String persetapi;
    List<MetadataService.PermissionSet> persetToInsert = new List<MetadataService.PermissionSet>();
    MetadataService.PermissionSet insertPerset = new MetadataService.PermissionSet();

    // Step 1: Create Permission Set
    insertPerset.fullName = ((String) newPermSet.get('Name')).replaceAll(' ', '_');
    insertPerset.label = (String) newPermSet.get('Label');
    insertPerset.description = (String) newPermSet.get('Description');
    insertPerset.license = (String) newPermSet.get('License');
    insertPerset.hasActivationRequired = (Boolean) newPermSet.get('hasActivationRequired');
    persetToInsert.add(insertPerset);

    if (!persetToInsert.isEmpty()) {
        try {
            MetadataService.UpsertResult[] results = (MetadataService.UpsertResult[]) instance.service.upsertMetadata(persetToInsert);

            for (MetadataService.UpsertResult upsertResult : results) {
                persetapi = upsertResult.fullName;
                if (!upsertResult.success) {
                    for (MetadataService.Error error : upsertResult.errors) {
                        System.debug('Error: ' + error.message + ' Status Code: ' + error.statusCode);
                        throw new AuraHandledException('Error inserting Permission Set: ' + error.message);
                    }
                } else {
                    System.debug('Permission Set Inserted successfully for: ' + upsertResult.fullName);
                }
            }
        } catch (Exception e) {
            System.debug('Error Inserting Permission Set: ' + e.getMessage());
            throw new AuraHandledException('Error inserting Permission Set: ' + e.getMessage());
        }

        System.debug('persetapi: ' + persetapi);
        Map<String, MetadataService.PermissionSet> permissionSetsMap = new Map<String, MetadataService.PermissionSet>();

        try {
            MetadataService.Metadata[] metadataArray = instance.service.readMetadata('PermissionSet', new List<String>{persetapi}).getRecords();

            for (MetadataService.Metadata metadata : metadataArray) {
                MetadataService.PermissionSet permissionSet = (MetadataService.PermissionSet) metadata;
                if (permissionSet != null) {
                    if (permissionSet.recordTypeVisibilities == null) {
                        permissionSet.recordTypeVisibilities = new List<MetadataService.PermissionSetRecordTypeVisibility>();
                    }
                    permissionSetsMap.put(permissionSet.fullName, permissionSet);
                } else {
                    System.debug('Permission set not found in metadata retrieval.');
                }
            }

            // Step 2: Update Record Type Visibilities
            for (String permissionSetName : permissionSetsMap.keySet()) {
                MetadataService.PermissionSet permissionSet = permissionSetsMap.get(permissionSetName);

                for (ManageUserAccessPartner.RecordTypeUpdateWrapper updates : recTypeToUpdate) {
                    Boolean recordTypeExists = false;

                    for (MetadataService.PermissionSetRecordTypeVisibility recordTypeVisibility : permissionSet.recordTypeVisibilities) {
                        if (recordTypeVisibility.recordType == updates.RecordType) {
                            // Update the visibility
                            recordTypeVisibility.visible = updates.Visible;
                            recordTypeExists = true;
                            break;
                        }
                    }

                    // If the record type does not exist, add it
                    if (!recordTypeExists) {
                        MetadataService.PermissionSetRecordTypeVisibility newRecordTypeVisibility = new MetadataService.PermissionSetRecordTypeVisibility();
                        newRecordTypeVisibility.recordType = updates.RecordType;
                        newRecordTypeVisibility.visible = updates.Visible;
                        permissionSet.recordTypeVisibilities.add(newRecordTypeVisibility);
                    }
                }
            }

            // Step 3: Save updated permission sets
            MetadataService.Metadata[] updatedPermissionSets = new List<MetadataService.Metadata>();
            for (MetadataService.PermissionSet permissionSet : permissionSetsMap.values()) {
                updatedPermissionSets.add(permissionSet);
            }

            MetadataService.SaveResult[] saveResults = instance.service.updateMetadata(updatedPermissionSets);

            for (MetadataService.SaveResult saveResult : saveResults) {
                if (!saveResult.success) {
                    System.debug('Error updating permission set: ' + saveResult.errors[0].message);
                } else {
                    System.debug('Permission set updated successfully: ' + saveResult.fullName);
                }
            }

        } catch (Exception e) {
            System.debug('Error in updatePermissionSetRecordTypeVisibility: ' + e.getMessage());
            throw new AuraHandledException('Error updating Permission Set record type visibility: ' + e.getMessage());
        }
    }
		 PermissionSet persetId = [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name = :persetapi
                LIMIT 1
            ];
        // Step 4: Assign Users to the Permission Set
        try {          

            System.debug('persetId: ' + persetId);

            List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
            for (String userId : userIds) {
                PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
                permSetAssignment.AssigneeId = userId;
                permSetAssignment.PermissionSetId = persetId.Id;
                permSetAssignments.add(permSetAssignment);
            }

            insert permSetAssignments;
            System.debug('Permission set assignments successfully created.');

        } catch (DmlException e) {
            System.debug('Error occurred while assigning permission set: ' + e.getMessage());
            throw new AuraHandledException('Error occurred while assigning permission set: ' + e.getMessage());
        }

        return persetId.Id; // Return the created PermissionSet ID
}


    
	@AuraEnabled
    //USED
    Public Static Map<String,List<String>> retrieveUserPermissionsName(String permissionType, List<String> permSetIds){
        Map<String,List<String>> userPermEnabledPermSets = new Map<String,List<String>>();
        if(!permSetIds.isEmpty()){
            String query = 'SELECT Id, Type, Name, Profile.Name, ' + permissionType + ' FROM PermissionSet WHERE Id IN :permSetIds And '+permissionType+ ' = true';
            for(PermissionSet perms : Database.query(query))
            {
                system.debug('perms'+perms);
                if(perms.Type == 'Profile'){
                    if (!userPermEnabledPermSets.containsKey('Profile')) {
                      userPermEnabledPermSets.put('Profile', new List<String>());
                    }
                    userPermEnabledPermSets.get('Profile').add(perms.Profile.Name);
                }
                if (
                    perms.Type != 'Profile' &&
                    perms.Type != 'Group'
                  ){
                    if (!userPermEnabledPermSets.containsKey('PermissionSet')) {
                      userPermEnabledPermSets.put('PermissionSet', new List<String>());
                    }
                    userPermEnabledPermSets.get('PermissionSet').add(perms.Name);
                }
                if(perms.Type == 'Group'){
                    if (!userPermEnabledPermSets.containsKey('Group')) {
                      userPermEnabledPermSets.put('Group', new List<String>());
                    }
					userPermEnabledPermSets.get('Group').add(perms.Name);
                }
                
            }
        }
        System.debug('userPermEnabledPermSets'+ userPermEnabledPermSets);
        return userPermEnabledPermSets;
    }
   

/*@AuraEnabled
Public Static Map<String, Boolean> updateUserPermissions(String permSetId, String profileName,
    Map<String, Boolean> systemPermissions){
	Map<String, Boolean> result = new Map<String, Boolean>();
    PermissionSet perms = [Select Id, Type from PermissionSet where Id =: permSetId LIMIT 1];
	if(perms != null){
        if(perms.Type == 'Profile'){
           result = manageUserAccess.updateSystemPermissionsProf(profileName,systemPermissions);
        }
        else {
            PermissionSet newPerm = new PermissionSet();
            newPerm.Id = permSetId;        
            for (String key : systemPermissions.keySet()) {
                // Construct the permission field name dynamically
                String permissionKey = 'Permissions' + key;                
                // Dynamically set the field value using SObject.put()
                newPerm.put(permissionKey, systemPermissions.get(key));
        	}
            if(newPerm != null){
              try{
                 update newPerm; 
                 result = systemPermissions;
              }catch(exception e){
                  system.debug('check error message'+ e.getMessage());
                  throw new AuraHandledException('Error updating system permissions: ' + e.getMessage());  
              }
            }
      }
   }
	MutingPermissionSet mutePerms = [Select Id from MutingPermissionSet where Id =: permSetId LIMIT 1];
    if(mutePerms != null){
        MutingPermissionSet newPerm = new MutingPermissionSet();
        newPerm.Id = permSetId;        
        for (String key : systemPermissions.keySet()) {
            // Construct the permission field name dynamically
            String permissionKey = 'Permissions' + key;                
            // Dynamically set the field value using SObject.put()
            newPerm.put(permissionKey, systemPermissions.get(key));
        }
        if(newPerm != null){
            try{
                update newPerm; 
                result = systemPermissions;
            }catch(exception e){
                system.debug('check error message'+ e.getMessage());
                throw new AuraHandledException('Error updating system permissions: ' + e.getMessage());  
            }
        }
    }
    return result;
 }
  */
@AuraEnabled
//USED
public static Map<String, Boolean> updateUserPermissions(String permSetId, String profileName, Map<String, Boolean> systemPermissions) {
    Map<String, Boolean> result = new Map<String, Boolean>();

    // Query the PermissionSet
    List<PermissionSet> perms = [SELECT Id, Type FROM PermissionSet WHERE Id =: permSetId LIMIT 1];
    if (!perms.isEmpty()) {
        if (perms[0].Type == 'Profile') {
            // If it's a profile, delegate the update to manageUserAccess
            result = manageUserAccess.updateSystemPermissionsProf(profileName, systemPermissions);
        } else {
            // Update PermissionSet if found
            try {
                updatePermissions(perms[0], systemPermissions);
                result = systemPermissions;
            } catch (Exception e) {
                system.debug('Error updating PermissionSet: ' + e.getMessage());
                throw new AuraHandledException('Error updating system permissions: ' + e.getMessage());
            }
        }
    }

    // Query the MutingPermissionSet
    List<MutingPermissionSet> mutePerms = [SELECT Id FROM MutingPermissionSet WHERE Id =: permSetId LIMIT 1];
    if (!mutePerms.isEmpty()) {
        try {
            updatePermissions(mutePerms[0], systemPermissions);
            result = systemPermissions;
        } catch (Exception e) {
            system.debug('Error updating MutingPermissionSet: ' + e.getMessage());
            throw new AuraHandledException('Error updating system permissions: ' + e.getMessage());
        }
    }

    return result;
}

    //USED
private static void updatePermissions(SObject permSet, Map<String, Boolean> systemPermissions) {
    // Dynamically set permissions in the provided permSet (PermissionSet or MutingPermissionSet)
    for (String key : systemPermissions.keySet()) {
        String permissionKey = 'Permissions' + key;
        permSet.put(permissionKey, systemPermissions.get(key));
    }

    update permSet;
}
   
    
    @AuraEnabled
    //USED
    Public Static ManageUserAccess.profilePermissiosetandUserWrapper  getUserPermandUsers(List<String> userPermissions,  String perSetId){        
        set<id> assigneeIdSet = new Set<Id>();
		list<permissionSet> permissionSetList = new List<permissionSet>();
    	set<Id> permissionSetIdSet = new Set<Id>();
        map<id, user> userMap = new Map<id, User>();
		List<String> conditions = new List<String>();
        if(!userPermissions.isEmpty()){
            string permissionQuery ='select id, name, Profile.name, Type, Label from PermissionSet where ';
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
        }
		for (PermissionSetAssignment perSetAssign : [
          SELECT id, AssigneeId
          FROM PermissionSetAssignment
          WHERE PermissionSetId IN :permissionSetIdSet
        ]) {
          assigneeIdSet.add(perSetAssign.AssigneeId);
        }
		for (user u : [
          SELECT id,Name, Username, Alias,Profile.Name, IsActive, LastLoginDate, Title, Department,
            Profile.UserLicense.Name FROM user WHERE id IN :assigneeIdSet AND IsActive = true ORDER BY IsActive DESC Limit 50000]) {
          userMap.put(u.id, u);
        }        
        system.debug('permissionSetList'+permissionSetList);
        system.debug('userMap.values()'+userMap.values());
        system.debug('userMap.values()'+userMap.values().size());
		return new ManageUserAccess.profilePermissiosetandUserWrapper(permissionSetList, userMap.values());
    }

    
    
	@AuraEnabled
    //USED
public static Map<String, List<String>> getUserPerm(String userId, List<String> perms) {
    List<String> conditions = new List<String>();
    Map<String, List<String>> permNamesWithType = new Map<String, List<String>>();
    String permSetAssignQuery = 'SELECT Id, PermissionSet.Profile.Name, PermissionSet.Type, PermissionSet.Name, PermissionSet.Label ' +
                                'FROM PermissionSetAssignment WHERE AssigneeId = :userId';

    // Adding permission conditions if provided
    if (!perms.isEmpty()) {
        for (String perm : perms) {
            conditions.add('PermissionSet.' + perm + ' = true'); // Use the PermissionSet prefix for permissions
        }
        permSetAssignQuery += ' AND ' + String.join(conditions, ' AND ');
    }

    System.debug('permSetAssignQuery: ' + permSetAssignQuery);

    // Execute the query
    List<PermissionSetAssignment> permSetAssignments = Database.query(permSetAssignQuery);

    // Process the query results
    for (PermissionSetAssignment permSetAssign : permSetAssignments) {
		        //permNamesWithType.get(permType).add(permLabel);
        if ( permSetAssign.PermissionSet.Type == 'Profile') {
            if (!permNamesWithType.containsKey('Profile')) {
            	permNamesWithType.put('Profile', new List<String>());
       		 }
            permNamesWithType.get('Profile').add(permSetAssign.PermissionSet.Profile.Name);
        } else if ( permSetAssign.PermissionSet.Type == 'Group') {
            if (!permNamesWithType.containsKey('Group')) {
            	permNamesWithType.put('Group', new List<String>());
       		 }
           permNamesWithType.get('Group').add(permSetAssign.PermissionSet.Label);
        } else {
            if (!permNamesWithType.containsKey('PermissionSet')) {
            	permNamesWithType.put('PermissionSet', new List<String>());
       		 }
            permNamesWithType.get('PermissionSet').add(permSetAssign.PermissionSet.Label);
        }

        // Add the permission name to the map
          // Add the permission label to the correct list
    }
	system.debug('permNamesWithType'+permNamesWithType);
    return permNamesWithType;
}
    @AuraEnabled
    Public Static Map<String,List<String>> getObjOrFieldPerm(String objName, String permType, String fieldName, String userId)
    {
        system.debug('permType : '+ permType+ 'fieldName : '+ fieldName );
		Set<String> permSetIds = new Set<String>();
        string objAndFieldConcat;
		for(PermissionSetAssignment perSetAssign : [Select Id, PermissionSetId from PermissionSetAssignment where AssigneeId = :userId])
        {
            permSetIds.add(perSetAssign.PermissionSetId);
        }
        if(fieldName != ''){
            objAndFieldConcat = objName + '.' + fieldName;
        }
        return retrieveObjPermissionsName(permType,new List<String>(permSetIds),objName,objAndFieldConcat);
    }

	
}