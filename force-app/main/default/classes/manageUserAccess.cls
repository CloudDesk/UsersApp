public class manageUserAccess {
  public permissionPartnerSoapSforceCom.Soap partnerConnection;
  public MetadataService.MetadataPort service;

  public manageUserAccess() {
    string username = System.Label.Board_Book_Integration_Username;
    string password = System.Label.Board_Book_Integration_Password;
    try {
      partnerConnection = new permissionPartnerSoapSforceCom.Soap();
      permissionPartnerSoapSforceCom.LoginResult sessionInfoObj = partnerConnection.login(
        username,
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
      System.debug('Login failed: ' + e.getMessage());
    }
  }

  public class PackageDetail {
    @AuraEnabled
    public String packageName;
    @AuraEnabled
    public String namespacePrefix;
  }

  @AuraEnabled
  public static List<PackageDetail> getInstalledPackages() {
    string username = System.Label.Board_Book_Integration_Username;
    string password = System.Label.Board_Book_Integration_Password;
	
      ManageUserAccessPartner instance = new ManageUserAccessPartner();
      /*
    partnerWsdl2Apex.soap soapObj = new partnerWsdl2Apex.soap();
    partnerWsdl2Apex.LoginResult sessionInfoObj = soapObj.login(
      username,
      password
    );
*/
    //system.debug('sessionInfoObj >> ' + sessionInfoObj);
    //system.debug('sessionInfoObj.sessionId >> ' + sessionInfoObj.sessionId);

    List<PackageDetail> installedPackages = new List<PackageDetail>();
    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
    string toolingQuery = '/services/data/v58.0/tooling/query/?q=select+id,+SubscriberPackageId,+SubscriberPackage.NamespacePrefix,+SubscriberPackage.Name+from+InstalledSubscriberPackage';
    string endPoint = baseUrl + toolingQuery;
    Http newReq = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endPoint);
    req.setMethod('GET');
   // req.setHeader('Authorization', 'Bearer ' + sessionInfoObj.sessionId);
   req.setHeader('Authorization','Bearer ' + instance.partnerConnection.SessionHeader.sessionId);
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
          PackageDetail detail = new PackageDetail();
          detail.packageName = (String) ((map<String, Object>) recordMap.get(
              'SubscriberPackage'
            ))
            .get('Name');
          detail.namespacePrefix = (String) ((map<String, Object>) recordMap.get(
              'SubscriberPackage'
            ))
            .get('NamespacePrefix');
          installedPackages.add(detail);
        }
      } else {
        System.debug('Error: ' + res.getStatus());
        System.debug('Response: ' + res.getBody());
      }
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
    }

    system.debug('Check Installed Package' + installedPackages);
    return installedPackages;
  }

  /*@AuraEnabled
  public static list<EntityDefinition> getObjectDefinition() {
      //USED
    return [
      SELECT Id, Label, QualifiedApiName
      FROM EntityDefinition
      ORDER BY label ASC
    ];
  }*/

 /* @AuraEnabled
    //USED
  public static Map<String, String> getSystemAndUserDefinition() {
    Map<String, String> systemAndUserResult = new Map<String, String>();

    // Describe the PermissionSet object
    Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe()
      .get('PermissionSet')
      .getDescribe();

    // Construct a dynamic SOQL query for Boolean fields
    String queryFields = '';
    for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
      Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

      // Check if the field is of Boolean type
      if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
        if (queryFields != '') {
          queryFields += ', ';
        }
        queryFields += fieldDescribe.getName();
      }
    }

    // If there are Boolean fields, query them
    if (queryFields != '') {
      String soqlQuery =
        'SELECT ' +
        queryFields +
        ' FROM PermissionSet LIMIT 1';
      List<SObject> permissionSets = Database.query(soqlQuery);

      // If a PermissionSet record exists, map the Boolean fields
      if (!permissionSets.isEmpty()) {
        SObject ps = permissionSets[0];
        for (String fieldName : ps.getPopulatedFieldsAsMap().keySet()) {
          systemAndUserResult.put(
            fieldName,
            ps.getSObjectType()
              .getDescribe()
              .fields.getMap()
              .get(fieldName)
              .getDescribe()
              .getLabel()
          );
        }
      }
    }
    system.debug('systemAndUserResult : ' + systemAndUserResult);

    return systemAndUserResult;
  }
*/
  public class profilePermissiosetandUserWrapper {
    @AuraEnabled
    public list<PermissionSet> permissionSetList { get; set; }
    @AuraEnabled
    public list<User> userList { get; set; }

    public profilePermissiosetandUserWrapper(
      list<permissionset> permissionSetList,
      list<user> userList
    ) {
      this.permissionSetList = permissionSetList;
      this.userList = userList;
    }
  }
  @AuraEnabled
    //Used
  Public Static profilePermissiosetandUserWrapper getPermandUserofUserPerm(
    String userPermission,
    String objName,
    String objPermission,
    String objFieldName,
    String fieldName,
    String fieldPerm,
    String perSetId
  ) {
    list<permissionSet> permissionSetList = new List<permissionSet>();
    Set<Id> idToFetchPermList = new Set<id>();
    set<Id> permissionSetIdSet = new Set<Id>();
    set<id> assigneeIdSet = new Set<Id>();
    map<id, user> userMap = new Map<id, User>();
    if (userPermission != null && userPermission != '') {
      string permissionQuery =
        'select id, name, Profile.name, Type, Label from PermissionSet where ' +
        userPermission +
        ' =true';
      if (perSetId == 'All') {
        for (permissionSet permSet : Database.query(permissionQuery)) {
          permissionSetList.add(permSet);
          permissionSetIdSet.add(permSet.Id);
        }
      }
      if (perSetId != 'All') {
        permissionSetIdSet.add(perSetId);
      }
    }
    if (
      objName != null &&
      objName != '' &&
      objPermission != null &&
      objPermission != ''
    ) {
      string objectPermissionQuery =
        'select id, SobjectType, ParentId,parent.Name,parent.Label, Parent.Profile.Name, parent.Type from ObjectPermissions where SobjectType =: objName and  ' +
        objPermission +
        ' =true';  
        for (
          ObjectPermissions objperm : Database.query(objectPermissionQuery)
        ) {
            idToFetchPermList.add(objperm.ParentId);
            if(perSetId == 'All'){
          		permissionSetIdSet.add(objperm.ParentId);
            }
        }
        permissionSetList = [
          SELECT id, name, Profile.name, Type, Label
          FROM PermissionSet
          WHERE id IN :idToFetchPermList
        ];
      if (perSetId != 'All') {
        permissionSetIdSet.add(perSetId);
      }
      //permissionSetList = [select id, name, Profile.name, Type, Label from PermissionSet where id IN : permissionSetIdSet];
    }
 
    if (
      objFieldName != null &&
      objFieldName != '' &&
      fieldName != null &&
      fieldName != '' &&
      fieldPerm != null &&
      fieldPerm != ''
    ) {
      string objAndFieldConcat = objFieldName + '.' + fieldName;
      string fieldPermissionQuery =
        'select Id, SobjectType, ParentId, Field, parent.Label,Parent.Name, Parent.Profile.Name, parent.Type from FieldPermissions where field =: objAndFieldConcat and ' +
        fieldPerm +
        ' =true';
        for (
          fieldPermissions fieldPermission : Database.query(
            fieldPermissionQuery
          )
        ) {
         idToFetchPermList.add(fieldPermission.ParentId);
         if(perSetId == 'All'){
            permissionSetIdSet.add(fieldPermission.ParentId);
         }
        }
        permissionSetList = [
          SELECT id, name, Profile.name, label, Type
          FROM PermissionSet
          WHERE id IN :idToFetchPermList
        ];
      if (perSetId != 'All') {
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
    return new profilePermissiosetandUserWrapper(
      permissionsetList,
      usermap.values()
    );
  }

  //PROFILE
  @AuraEnabled(cacheable=true)
  public static List<String> getProfileName(String ProfileId) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
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
    
  //PERMISSION SET
  @AuraEnabled
    //used
  public static List<User> getAssignedUserForPermissionSet(
    string permissionSetId
  ) {
      /*
    List<Map<String, String>> result = new List<Map<String, String>>();
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    permissionPartnerSoapSforceCom.QueryResult persetquery = instance.partnerConnection.query(
      'SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.Id = \'' +
        permissionSetId +
        '\''
    );
    Set<Id> assigneeIds = new Set<Id>();
    if (persetquery != null && persetquery.records != null) {
      for (
        permissionSobjectPartnerSoapSforceCom.sObject_x record : persetquery.records
      ) {
        if (record != null && record.AssigneeId != null) {
          assigneeIds.add((String) record.AssigneeId);
        }
      }
    }
    List<User> users = [
      SELECT id, Name, Username, Profile.Name, Profile.UserLicense.Name
      FROM User
      WHERE Id IN :assigneeIds
      ORDER BY Name ASC
    ];
    return users;
*/
      Set<Id> assigneeIds = new Set<Id>();
    List<PermissionSetAssignment> permissionSetAssignments = [
        SELECT AssigneeId
        FROM PermissionSetAssignment
        WHERE PermissionSet.Id = :permissionSetId
    ];
    for (PermissionSetAssignment psa : permissionSetAssignments) {
        if (psa.AssigneeId != null) {
            assigneeIds.add(psa.AssigneeId);
        }
    }
    List<User> users = [
        SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name
        FROM User
        WHERE Id IN :assigneeIds
        ORDER BY Name ASC
    ];
    
    return users;
  }

  @AuraEnabled
    //used
  public static List<user> getUnAssignedUserForPermissionSet(
    string permissionSetId,
    string profileName,
    string userLicense,
    string licenseName
  ) {
      /*
    system.debug('License Name>>>>' + licenseName);
    system.debug('Permission Set>>>>' + permissionSetId);
    system.debug('Profile Name>>>>' + profileName);
    system.debug('User License>>>>' + userLicense);
    List<Map<String, String>> result = new List<Map<String, String>>();
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    permissionPartnerSoapSforceCom.QueryResult persetquery = instance.partnerConnection.query(
      'SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.Id = \'' +
        permissionSetId +
        '\''
    );
    Set<Id> assigneeIds = new Set<Id>();
    if (persetquery != null && persetquery.records != null) {
      for (
        permissionSobjectPartnerSoapSforceCom.sObject_x record : persetquery.records
      ) {
        if (record != null && record.AssigneeId != null) {
          assigneeIds.add((String) record.AssigneeId);
        }
      }
    }
    List<String> assigneeIdsList = new List<String>();
    for (Id id : assigneeIds) {
      assigneeIdsList.add(id);
    }

    string query = 'select id,Name, Username, Profile.Name, IsActive, Profile.UserLicense.Name from user WHERE IsActive = true AND Id NOT IN :assigneeIdsList';
    if (profileName != null && profileName != '' && profileName != 'All') {
      query += ' AND Profile.Name = :profileName';
    }
    if (licenseName != null && licenseName != '') {
      query += ' AND Profile.UserLicense.Name = :licenseName';
      system.debug('NOT NULL >>>');
    }
    query += ' ORDER BY Name ASC';
    List<user> userList = Database.Query(query);
    system.debug('userList >>>' + userList);
    return userList;
*/
      System.debug('License Name>>>>' + licenseName);
    System.debug('Permission Set>>>>' + permissionSetId);
    System.debug('Profile Name>>>>' + profileName);
    System.debug('User License>>>>' + userLicense);

    // Query PermissionSetAssignment using standard SOQL
    List<PermissionSetAssignment> permissionSetAssignments = [
        SELECT AssigneeId
        FROM PermissionSetAssignment
        WHERE PermissionSet.Id = :permissionSetId
    ];

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
    query += ' ORDER BY Name ASC';

    List<User> userList = Database.query(query);
    System.debug('userList >>>' + userList);
    return userList;
  }

  @AuraEnabled(cacheable=false)
    //used
  public static String createPermissionSet(
    Map<String,Object> permSetToCreate,
    List<Id> userids
  ) {    
    ManageUserAccess instance = new ManageUserAccess();
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
        MetadataService.UpsertResult[] results = (MetadataService.UpsertResult[]) instance.service.upsertMetadata(
          persetToInsert
        );

        for (MetadataService.UpsertResult upsertResult : results) {
          persetapi = upsertResult.fullName;
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
              'Error inserting Permission Set: ' +
              upsertResult.errors[0].message
            );
          } else {
            System.debug(
              'Permission Set Inserted successfully for: ' +
              upsertResult.fullName
            );
          }
        }
      } catch (Exception e) {
        System.debug('Error Inserting Permission Set: ' + e.getMessage());
        throw new AuraHandledException(
          'Error inserting Permission Set: ' + e.getMessage()
        );
      }
    }

    System.debug('Permission Set API Name: ' + persetapi);

    // Query the inserted Permission Set
    PermissionSet persetId = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name = :persetapi
      LIMIT 1
    ];

    List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
    for (Id userId : userids) {
      // Create a new PermissionSetAssignment record for each user
      PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
      permSetAssignment.AssigneeId = userId;
      permSetAssignment.PermissionSetId = persetId.Id;
      permSetAssignments.add(permSetAssignment);
    }

    try {
      insert permSetAssignments;
      System.debug('Permission set assignments successfully created.');
    } catch (DmlException e) {
      System.debug(
        'Error occurred while assigning permission set: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Error occurred while assigning permission set: ' + e.getMessage()
      );
    }
      return persetId.Id;
  }

  @AuraEnabled(cacheable=true)
    //used
  public static List<Map<String, String>> getSetPermission() {
      /*
    List<Map<String, String>> result = new List<Map<String, String>>();
    string username = System.Label.Board_Book_Integration_Username;
    string password = System.Label.Board_Book_Integration_Password;
    permissionPartnerSoapSforceCom.soap soapObj = new permissionPartnerSoapSforceCom.soap();
    permissionPartnerSoapSforceCom.LoginResult sessionInfoObj = soapObj.login(
      username,
      password
    );
    soapObj.SessionHeader = new permissionPartnerSoapSforceCom.SessionHeader_element();
    soapObj.SessionHeader.sessionId = sessionInfoObj.sessionId;
    soapObj.endpoint_x = sessionInfoObj.serverUrl;
    string Grptype = 'Group';
    permissionPartnerSoapSforceCom.QueryResult persetQueryResult = soapObj.query(
      'select Id,Name,Label,Description,IsCustom,NamespacePrefix,CreatedDate,LastModifiedDate,LicenseId,CreatedById,LastModifiedById from PermissionSet WHERE IsOwnedByProfile = false AND Type != \'' +
        Grptype +
        '\''
    );
    Map<String, permissionSobjectPartnerSoapSforceCom.sObject_x> licenseMap = new Map<String, permissionSobjectPartnerSoapSforceCom.sObject_x>();
    Map<String, permissionSobjectPartnerSoapSforceCom.sObject_x> createdbyMap = new Map<String, permissionSobjectPartnerSoapSforceCom.sObject_x>();
    Map<String, permissionSobjectPartnerSoapSforceCom.sObject_x> lastmodifiedMap = new Map<String, permissionSobjectPartnerSoapSforceCom.sObject_x>();
    Set<String> licenseIds = new Set<String>();
    Set<String> createdbyIds = new Set<String>();
    Set<String> modifiedIds = new Set<String>();
    for (
      permissionSobjectPartnerSoapSforceCom.sObject_x record : persetQueryResult.records
    ) {
      String licenseId = (String) record.LicenseId;
      String createdbyId = (String) record.CreatedById;
      String lastmodifiedId = (String) record.LastModifiedById;
      if (licenseId != null) {
        licenseIds.add(licenseId);
      }
      if (createdbyId != null) {
        createdbyIds.add(createdbyId);
      }
      if (lastmodifiedId != null) {
        modifiedIds.add(lastmodifiedId);
      }
    }
    if (!licenseIds.isEmpty()) {
      List<String> licenseIdsList = new List<String>();
      for (Id id : licenseIds) {
        licenseIdsList.add(id);
      }
      String licId = '\'' + String.join(licenseIdsList, '\',\'') + '\'';
      String licenseQuery =
        'select id,Name from UserLicense WHERE Id IN (' +
        licId +
        ')';
      permissionPartnerSoapSforceCom.QueryResult licenseQueryResult = soapObj.query(
        licenseQuery
      );

      for (
        permissionSobjectPartnerSoapSforceCom.sObject_x licenseRecord : licenseQueryResult.records
      ) {
        licenseMap.put((String) licenseRecord.Id, licenseRecord);
      }
    }
    if (!createdbyIds.isEmpty()) {
      List<String> createdIdsList = new List<String>();
      for (Id id : createdbyIds) {
        createdIdsList.add(id);
      }
      String creId = '\'' + String.join(createdIdsList, '\',\'') + '\'';
      String createdbyQuery =
        'select id,name from user WHERE Id IN (' +
        creId +
        ')';
      permissionPartnerSoapSforceCom.QueryResult createdbyQueryResult = soapObj.query(
        createdbyQuery
      );

      for (
        permissionSobjectPartnerSoapSforceCom.sObject_x createdbyRecord : createdbyQueryResult.records
      ) {
        createdbyMap.put((String) createdbyRecord.Id, createdbyRecord);
      }
    }
    if (!modifiedIds.isEmpty()) {
      List<String> modifiedIdsList = new List<String>();
      for (Id id : modifiedIds) {
        modifiedIdsList.add(id);
      }
      String modId = '\'' + String.join(modifiedIdsList, '\',\'') + '\'';
      String lastmodbyQuery =
        'select id,name from user WHERE Id IN (' +
        modId +
        ')';
      permissionPartnerSoapSforceCom.QueryResult lastmodbyQueryResult = soapObj.query(
        lastmodbyQuery
      );

      for (
        permissionSobjectPartnerSoapSforceCom.sObject_x lastmodbyRecord : lastmodbyQueryResult.records
      ) {
        lastmodifiedMap.put((String) lastmodbyRecord.Id, lastmodbyRecord);
      }
    }

    for (
      permissionSobjectPartnerSoapSforceCom.sObject_x record : persetQueryResult.records
    ) {
      Map<String, String> recordMap = new Map<String, String>();
      recordMap.put('Id', (String) record.Id);
      recordMap.put('Name', (String) record.Name);
      recordMap.put('Label', (String) record.Label);
      recordMap.put('Description', (String) record.Description);
      recordMap.put('IsCustom', (String) record.IsCustom);
      recordMap.put('NamespacePrefix', (String) record.NamespacePrefix);
      recordMap.put('CreatedDate', (String) record.CreatedDate);
      recordMap.put('LastModifiedDate', (String) record.LastModifiedDate);
      recordMap.put('LicenseId', (String) record.LicenseId);
      String permissionId = (String) record.Id;
      String licenseId = (String) record.LicenseId;
      String createdbyId = (String) record.CreatedById;
      String lastmodbyId = (String) record.LastModifiedById;
      if (licenseId != null && licenseMap.containsKey(licenseId)) {
        permissionSobjectPartnerSoapSforceCom.sObject_x license = licenseMap.get(
          licenseId
        );
        String licenseName = (String) license.Name;
        recordMap.put('LicenseName', licenseName);
        system.debug('Permission Set Id >> ' + permissionId);
        system.debug('License Name >> ' + licenseName);
      } else {
        System.debug(
          'License Name not found for Permission set ID: ' + permissionId
        );
      }
      if (createdbyId != null && createdbyMap.containsKey(createdbyId)) {
        permissionSobjectPartnerSoapSforceCom.sObject_x createdby = createdbyMap.get(
          createdbyId
        );
        String createdbyName = (String) createdby.Name;
        recordMap.put('CreatedByName', createdbyName);
        system.debug('Permission Set Id >> ' + permissionId);
        system.debug('Createdby Name >> ' + createdbyName);
      } else {
        System.debug(
          'createdbyName Name not found for Permission set ID: ' + permissionId
        );
      }
      if (lastmodbyId != null && lastmodifiedMap.containsKey(lastmodbyId)) {
        permissionSobjectPartnerSoapSforceCom.sObject_x lastmoddby = lastmodifiedMap.get(
          lastmodbyId
        );
        String lastmodbyName = (String) lastmoddby.Name;
        recordMap.put('LastModifiedByName', lastmodbyName);
        system.debug('Permission Set Id >> ' + permissionId);
        system.debug('LastModby Name >> ' + lastmodbyName);
      } else {
        System.debug(
          'LastModbyName Name not found for Permission set ID: ' + permissionId
        );
      }
      result.add(recordMap);
    }
    return result;
      */
          List<Map<String, String>> result = new List<Map<String, String>>();
    
    // Query PermissionSets
    List<PermissionSet> permissionSets = [
        SELECT Id, Name, Label, Description, IsCustom, NamespacePrefix, CreatedDate, LastModifiedDate, 
               License.Name, CreatedBy.Name, LastModifiedBy.Name
        FROM PermissionSet
        WHERE IsOwnedByProfile = false AND Type != 'Group'
    ];

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

  @AuraEnabled
    //used
  public static void insertUsertoPermissionSet(
    List<string> userId,
    string PerSetId
  ) {
    List<PermissionSetAssignment> persetasi = new List<PermissionSetAssignment>();
    for (string assignId : userId) {
      PermissionSetAssignment perasi = new PermissionSetAssignment();
      perasi.AssigneeId = assignId;
      perasi.PermissionSetId = PerSetId;
      persetasi.add(perasi);
    }

    try {
      insert persetasi;
      System.debug('Permission Set assigned successfully to all users');
    } catch (DmlException e) {
      System.debug('Error assigning Permission Set: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
    //used
  public static void deleteUserfromPermissionSet(
    List<string> userId,
    string perSetId
  ) {
    //PermissionSetGroup persetgrp = [SELECT Id,DeveloperName FROM PermissionSetGroup WHERE DeveloperName = : PerSetGroupName LIMIT 1];

    List<PermissionSetAssignment> persetAssignForDlt = [
      SELECT id
      FROM PermissionSetAssignment
      WHERE AssigneeId IN :userId AND PermissionSetId = :perSetId
    ];
    try {
      delete persetAssignForDlt;
      System.debug('Permission Set Deleted successfully for the users');
    } catch (DmlException e) {
      System.debug('Error Deleting Permission Set: ' + e.getMessage());
    }
  }

  @AuraEnabled(cacheable=true)
    //used
  public static List<User> getUserforPermissionSet(string licenseName) {
    List<User> userList = new List<User>();
    if (String.isNotEmpty(licenseName)) {
      system.debug('INSIDE IF');
      system.debug('license name: ' + licenseName);
	  List<UserLicense> userLic = [Select Id, Name from userLicense where Name =: licenseName LIMIT 1];
        system.debug('userLic'+ userLic);
        if(!userLic.isEmpty()){
            userList = [
            SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name
            FROM User
            WHERE IsActive = TRUE AND Profile.UserLicenseId = :userLic[0].Id
          ];
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
                    SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name
                    FROM User
                    WHERE IsActive = TRUE AND Id IN :assigneeId
                  ];
            }
        }
      
    } else {
      system.debug('INSIDE ELSE');
      system.debug('license name:>>> ' + licenseName);
      userList = [
        SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name
        FROM User
        WHERE IsActive = TRUE
      ];
      system.debug('userList'+ userList);
    }
    return userList;
  }

     @AuraEnabled(cacheable=true)
    //used
    public static Map<String,List<Map<String,String>>> getPermissionSetLicense(String userId){
		Map<String,List<Map<String,String>>> userPermLicenseMap = new Map<String,List<Map<String,String>>>();
        User userList = [select id, profile.UserLicenseId from user where id =:userId limit 1];
        If(userList != null){	
            UserLicense userLic = [select Id, Name, MasterLabel from UserLicense where id = :userList.profile.UserLicenseId];
            if(userLic != null){
                Map<String, String> recordMap = new Map<String, String>();
				recordMap.put('Id',userLic.Id);
                recordMap.put('Name',userLic.Name);
                recordMap.put('MasterLabel',userLic.MasterLabel);
				if (!userPermLicenseMap.containsKey('UserLicense')) {
                    userPermLicenseMap.put('UserLicense', new List<Map<String, String>>());
                }
                
                userPermLicenseMap.get('UserLicense').add(recordMap);
             }
		
        }
        system.debug('userPermLicenseMap'+ userPermLicenseMap);
        return userPermLicenseMap;
            
    }
    
    @AuraEnabled(cacheable=true)
    //used
	public static Map<String, List<Map<String, String>>> getPermissionSetLicenseCreate() {
    	Map<String, List<Map<String, String>>> userPermLicenseMap = new Map<String, List<Map<String, String>>>();
    
    	try {
        	// Query all User Licenses
        	List<UserLicense> userLicenses = [SELECT Id, Name, MasterLabel FROM UserLicense];
        
        	// Iterate through the result and add each record to the map
        	for (UserLicense userLic : userLicenses) {
            	Map<String, String> recordMap = new Map<String, String>();
            	recordMap.put('Id', userLic.Id);
            	recordMap.put('Name', userLic.Name);
            	recordMap.put('MasterLabel', userLic.MasterLabel);
            
            	// Add to the UserLicense list in the map
           	 if (!userPermLicenseMap.containsKey('UserLicense')) {
                	userPermLicenseMap.put('UserLicense', new List<Map<String, String>>());
           	 }
           	 userPermLicenseMap.get('UserLicense').add(recordMap);
        	}
   	 	} catch (DmlException e) {
       	 throw new AuraHandledException(e.getMessage());
    	}
    
    	system.debug('userPermLicenseMap' + userPermLicenseMap);
    	return userPermLicenseMap;
}


  @AuraEnabled
    //used
  public static PermissionSet editPermissionSet(
    string perSet,
    string label,
    string apiName,
    string description
  ) {
    PermissionSet perSetVal = [
      SELECT id, Name, Label, Description
      FROM PermissionSet
      WHERE id = :perSet
    ];
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

  @AuraEnabled
    //used
  public static String deletePerSet(String permissionSetId) {
    PermissionSet permSet = [
      SELECT Id
      FROM PermissionSet
      WHERE Id = :permissionSetId
      LIMIT 1
    ];

    if (permSet != null) {
      List<PermissionSetAssignment> permSetAssignments = [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :permSet.Id
      ];
      try {
        if (!permSetAssignments.isEmpty()) {
          // Delete all Permission Set Assignments
          delete permSetAssignments;
          System.debug('Permission set assignments deleted successfully.');
        }
        delete permSet;
        System.debug('Permission set deleted successfully.');
        return 'Permission set deleted successfully.';
      } catch (DmlException e) {
        System.debug(
          'Error occurred while deleting permission set or its assignments: ' +
          e.getMessage()
        );
        throw new AuraHandledException(e.getMessage());
      }
    } else {
      System.debug('Permission set not found.');
      return 'Permission set not found.';
    }
  }

  @AuraEnabled
    //used
  public static void clonePermissionSetwithUsers(
    String sourcePermissionSetId,
    String newLabel,
    String newApiName,
    String newDescription,
    string newLicense
  ) {
    try {
      System.debug('Permission Set Id' + sourcePermissionSetId);
      System.debug('Permission Set Label' + newLabel);
      System.debug('Permission Set API Name' + newApiName);
      System.debug('Permission Set Description' + newDescription);
      System.debug('Permission Set License Id' + newLicense);
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
      List<PermissionSetAssignment> persetass = [
        SELECT Id, AssigneeId, PermissionSetId
        FROM PermissionSetAssignment
        WHERE PermissionSetId = :sourcePermissionSetId
      ];
      Set<Id> assigneeIds = new Set<Id>();
      for (PermissionSetAssignment psa : persetass) {
        assigneeIds.add(psa.AssigneeId);
      }
      List<User> userList = [
        SELECT
          id,
          Name,
          Username,
          Profile.Name,
          IsActive,
          Profile.UserLicense.Name
        FROM user
        WHERE IsActive = TRUE AND Id IN :assigneeIds
      ];
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

  @AuraEnabled
    //used
  public static void clonePermissionSet(
    String newLabel,
    String newApiName,
    String newDescription,
    string newLicense
  ) {
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

  //SYSTEM PERMISSION FOR PERMISSION SET
  public class PermissionFieldWrapper {
    //@AuraEnabled public map<string,string> systemPermissions{get;set;}
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public String fieldLabel;
    @AuraEnabled
    public Object fieldValue;
    @AuraEnabled
    public Boolean hasDependencies;
    @AuraEnabled
    public List<String> requiredPermissions;

    public PermissionFieldWrapper(
      String fieldName,
      String fieldLabel,
      Object fieldValue
    ) {
      //systemPermissions = new map<string,string>();
      this.fieldName = fieldName;
      this.fieldLabel = fieldLabel;
      this.fieldValue = fieldValue;
      this.hasDependencies = false;
      this.requiredPermissions = new List<String>();
    }
  }
    

  //update Record Type
  public class RecordTypeUpdateWrapper {
    @AuraEnabled
    public String RecordType { get; set; }
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String developerName { get; set; }
    @AuraEnabled
    public Boolean Visible { get; set; }
  }

  @AuraEnabled
    //used
  public static List<ManageUserAccessPartner.RecordTypeUpdateWrapper> updatePermissionSetRecordTypeVisibility(
    List<String> permissionSetNames,
    List<ManageUserAccessPartner.RecordTypeUpdateWrapper> recordTypeUpdates
  ) {
    System.debug('Received recordTypeUpdates: ' + recordTypeUpdates);
    try {
      // Create MetadataService instance
      manageUserAccess instance = new manageUserAccess();

      // Map to hold permission sets to be updated
      Map<String, MetadataService.PermissionSet> permissionSetsMap = new Map<String, MetadataService.PermissionSet>();

      // Retrieve all permission sets in a single call
      MetadataService.Metadata[] metadataArray = instance.service.readMetadata(
          'PermissionSet',
          permissionSetNames
        )
        .getRecords();

      // Initialize the map with the retrieved permission sets
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

      // Update the record type visibilities for each permission set
      for (String permissionSetName : permissionSetsMap.keySet()) {
        MetadataService.PermissionSet permissionSet = permissionSetsMap.get(
          permissionSetName
        );

        for (
          ManageUserAccessPartner.RecordTypeUpdateWrapper updates : recordTypeUpdates
        ) {
          Boolean recordTypeExists = false;

          for (
            MetadataService.PermissionSetRecordTypeVisibility recordTypeVisibility : permissionSet.recordTypeVisibilities
          ) {
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

      // Save all updated permission sets
      MetadataService.Metadata[] updatedPermissionSets = new List<MetadataService.Metadata>{};
      for (
        MetadataService.PermissionSet permissionSet : permissionSetsMap.values()
      ) {
        updatedPermissionSets.add(permissionSet);
      }

      MetadataService.SaveResult[] saveResults = instance.service.updateMetadata(
        updatedPermissionSets
      );

      for (MetadataService.SaveResult saveResult : saveResults) {
        if (!saveResult.success) {
          System.debug(
            'Error updating permission set: ' + saveResult.errors[0].message
          );
        } else {
          System.debug(
            'Permission set updated successfully: ' + saveResult.fullName
          );
        }
      }
    } catch (Exception e) {
      System.debug(
        'Error in updatePermissionSetRecordTypeVisibility: ' + e.getMessage()
      );
    }
    return recordTypeUpdates;
  }

  @AuraEnabled
    //used
  public static Map<String, String> getTabPermissions(
    List<String> profileName
  ) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata(
        'Profile',
        profileName
      )
      .getRecords();
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

  // Update System Permissions for Permission Set usi
  @AuraEnabled
    //used
  public static list<PermissionSet> updateSystemPermissions(
    String systemPermissionsMap,
    String psid
  ) {
    System.debug('Map Values: ' + systemPermissionsMap);

    // Deserialize JSON to a map
    Map<String, Object> tempMap = (Map<String, Object>) JSON.deserializeUntyped(
      systemPermissionsMap
    );

    List<PermissionSet> psListToInsert = new List<PermissionSet>();

    Map<String, Object> permissionsMap = new Map<String, Object>();

    system.debug('Permission Set Id' + psid);

    PermissionSet permissionSet;

    for (String fieldApi : tempMap.keySet()) {
      Object isChecked = tempMap.get(fieldApi);
      permissionsMap.put(fieldApi, isChecked);
    }

    List<String> uniquePermissionsSet = new List<String>(
      permissionsMap.keySet()
    );
    String li = 'Id, ' + String.join(uniquePermissionsSet, ', ');
    String query = 'SELECT ' + li + ' FROM PermissionSet WHERE Id = :psid';
    system.debug(query);
    List<PermissionSet> psList = Database.query(query);
    system.debug(psList);
    permissionSet = psList[0];

    for (String permission : uniquePermissionsSet) {
      permissionSet.put(permission, permissionsMap.get(permission));
    }
    psListToInsert.add(permissionSet);

    try {
      update psListToInsert;
      return psListToInsert;
    } catch (DmlException e) {
      System.debug(
        'An error occurred while updating PermissionSets: ' + e.getMessage()
      );
      throw new AuraHandledException(e.getMessage());
    }
  }

  //PERMISSION SET GROUP
  @AuraEnabled(cacheable=true)
    //used
public static List<permissionSetGroupWrapper> getPermissionSetGrp() {
    Map<String, List<PermissionSetGroupComponent>> permSetCompMap = new Map<String, List<PermissionSetGroupComponent>>();
    List<permissionSetGroupWrapper> permissionSetGroupWithLicense = new List<permissionSetGroupWrapper>();

    // Query all PermissionSetGroupComponents
    for (PermissionSetGroupComponent permSetComp : [SELECT Id, PermissionSetId, PermissionSet.License.Name, PermissionSetGroupId FROM PermissionSetGroupComponent]) {
        // Check if the PermissionSetGroupId already exists in the map
        if (!permSetCompMap.containsKey(permSetComp.PermissionSetGroupId)) {
            // Initialize a new list for this PermissionSetGroupId
            List<PermissionSetGroupComponent> permSetGrpList = new List<PermissionSetGroupComponent>();
            permSetGrpList.add(permSetComp);
            permSetCompMap.put(permSetComp.PermissionSetGroupId, permSetGrpList);
        } else {
            // Retrieve the existing list
            List<PermissionSetGroupComponent> permSetGrpList = permSetCompMap.get(permSetComp.PermissionSetGroupId);
            // Add the current component to the list
            permSetGrpList.add(permSetComp);
        }
    }

    // Query all PermissionSetGroups
    for (PermissionSetGroup permSetGrp : [SELECT Id, DeveloperName, MasterLabel, Description, Status, NamespacePrefix, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedById, LastModifiedBy.Name, LastModifiedDate FROM PermissionSetGroup ORDER BY MasterLabel ASC]) {
        Set<String> licenseList = new Set<String>();
       
        if (permSetCompMap.containsKey(permSetGrp.Id)) {
            for (PermissionSetGroupComponent permSetGrpComp : permSetCompMap.get(permSetGrp.Id)) {
                if(permSetGrpComp.PermissionSet.License.Name != null){
                 licenseList.add(permSetGrpComp.PermissionSet.License.Name);
                }
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
            permSetGrpWrapper.sameLicense = licenseList.size() <= 1? true : false;
            /*if(licenseList.size() == 1){
                permSetGrpWrapper.sameLicense = true;
            }else{
                permSetGrpWrapper.sameLicense = false;
            }*/
        		permissionSetGroupWithLicense.add(permSetGrpWrapper);
        
    }
    System.debug('permissionSetGroupWithLicense' + permissionSetGroupWithLicense);
    System.debug('permissionSetGroupWithLicense size: ' + permissionSetGroupWithLicense.size());
    return permissionSetGroupWithLicense;
}
    
    public class permissionSetGroupWrapper{
        @AuraEnabled
        public String perSetGrpId { get; set;}
        @AuraEnabled
        public String DeveloperName { get; set;}
        @AuraEnabled
        public String MasterLabel { get; set;}
        @AuraEnabled
        public String Description { get; set;}
        @AuraEnabled
        public String Status { get; set;}
        @AuraEnabled
        public String NamespacePrefix { get; set;}
        @AuraEnabled
        public String CreatedById { get; set;}
        @AuraEnabled
        public String CreatedByName { get; set;}
        @AuraEnabled
        public Datetime CreatedDate { get; set;}
        @AuraEnabled
        public String LastModifiedById { get; set;}
        @AuraEnabled
        public String LastModifiedByName { get; set;}
        @AuraEnabled
        public Datetime LastModifiedDate { get; set;}
        @AuraEnabled
        public Boolean sameLicense { get; set;}
    }


  @AuraEnabled(cacheable=false)
    //used
  public static void createPermissionSetGroup(
    String label,
    String apiName,
    String description,
    List<String> permissionSetIds,
    Boolean isRequired
  ) {
    try {
      // Create Permission Set Group
      PermissionSetGroup newGroup = new PermissionSetGroup();
      newGroup.MasterLabel = label;
      newGroup.DeveloperName = apiName.replaceAll(' ', '_');
      newGroup.Description = description;
      newGroup.HasActivationRequired = isRequired;
      insert newGroup;

      // Assign Permission Sets to the Permission Set Group
      List<PermissionSetGroupComponent> groupComponents = new List<PermissionSetGroupComponent>();
      for (String permissionSetId : permissionSetIds) {
        system.debug('permission set Id --' + permissionSetId);
        system.debug('permission set Grp Id --' + newGroup.Id);
        PermissionSetGroupComponent groupComponent = new PermissionSetGroupComponent();
        groupComponent.PermissionSetGroupId = newGroup.Id;
        groupComponent.PermissionSetId = permissionSetId;
        system.debug('PermissionSetId >>' + PermissionSetId);
        groupComponents.add(groupComponent);
      }
      insert groupComponents;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
    //used
public static PermissionSetGroup EditPermissionSetGrp(
    string perSetId,
    string label,
    string apiName,
    string description,
    string format
) {
    system.debug('perSetId: ' + perSetId);
    system.debug('label: ' + label);
    system.debug('apiName: ' + apiName);
    system.debug('description: ' + description);
    system.debug('type: ' + format);
    
    PermissionSetGroup perSet;

    try {
        // If type is 'group', retrieve PermissionSetGroup directly by perSetId
        if (format == 'group') {
            perSet = [
                SELECT
                    id,
                    DeveloperName,
                    MasterLabel,
                    Description,
                    Status,
                    NamespacePrefix,
                    CreatedById,
                    CreatedBy.Name,
                    CreatedDate,
                    LastModifiedById,
                    LastModifiedBy.Name,
                    LastModifiedDate
                FROM PermissionSetGroup
                WHERE id = :perSetId
                LIMIT 1
            ];
        }
        // If type is 'permission set', retrieve PermissionSetGroup using PermissionSet
        else if (format == 'permission set') {
            PermissionSet permissionSet = [
                SELECT
                    PermissionSetGroupId
                FROM PermissionSet
                WHERE id = :perSetId
                LIMIT 1
            ];
            
            // Check if PermissionSetGroupId is not null
            if (permissionSet.PermissionSetGroupId != null) {
                perSet = [
                    SELECT
                        id,
                        DeveloperName,
                        MasterLabel,
                        Description,
                        Status,
                        NamespacePrefix,
                        CreatedById,
                        CreatedBy.Name,
                        CreatedDate,
                        LastModifiedById,
                        LastModifiedBy.Name,
                        LastModifiedDate
                    FROM PermissionSetGroup
                    WHERE id = :permissionSet.PermissionSetGroupId
                    LIMIT 1
                ];
            } else {
                throw new AuraHandledException('No PermissionSetGroup found for the provided PermissionSet ID.');
            }
        } else {
            throw new AuraHandledException('Invalid type provided. Must be "group" or "permission set".');
        }
    } catch (Exception e) {
        throw new AuraHandledException('Error retrieving PermissionSetGroup: ' + e.getMessage());
    }

    // Update the PermissionSetGroup if found
    if (perSet != null) {
        perSet.MasterLabel = label;
        perSet.DeveloperName = apiName;
        perSet.Description = description;

        try {
            update perSet;
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating PermissionSetGroup: ' + e.getMessage());
        }
    }

    return perSet;
}


  @AuraEnabled
    //used
  public static void clonePermissionSetGroup(
    String sourcePermissionSetGroupName,
    String newLabel,
    String newApiName,
    String newDescription
  ) {
    try {
      // Fetch the source Permission Set Group
      PermissionSetGroup sourcePSG = [
        SELECT Id, MasterLabel, DeveloperName, Description
        FROM PermissionSetGroup
        WHERE MasterLabel = :sourcePermissionSetGroupName
        LIMIT 1
      ];

      // Create a new Permission Set Group
      PermissionSetGroup newPSG = new PermissionSetGroup();
      newPSG.MasterLabel = newLabel;
      newPSG.DeveloperName = newApiName.replaceAll(' ', '_');
      newPSG.Description = newDescription;
      insert newPSG;

      // Fetch the newly created Permission Set Group ID
      Id newPSGId = newPSG.Id;

      // Clone Permission Set Group Components
      List<PermissionSetGroupComponent> sourceComponents = [
        SELECT PermissionSetId
        FROM PermissionSetGroupComponent
        WHERE PermissionSetGroupId = :sourcePSG.Id
      ];
      Set<Id> permissionSetIds = new Set<Id>();
      for (PermissionSetGroupComponent component : sourceComponents) {
        permissionSetIds.add(component.PermissionSetId);
        system.debug('Permission Set Ids' + component);
      }
      system.debug('First Permission Set Ids' + permissionSetIds);
      Set<Id> newpermissionSetIds = new Set<Id>();
      List<PermissionSet> perset = [
        SELECT Id
        FROM PermissionSet
        WHERE Id IN :permissionSetIds
      ];
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
      List<PermissionSetAssignment> assignedUsers = [
        SELECT AssigneeId
        FROM PermissionSetAssignment
        WHERE PermissionSetGroupId = :sourcePSG.Id
      ];
      Set<Id> assignedUserIds = new Set<Id>();
      for (PermissionSetAssignment psa : assignedUsers) {
        assignedUserIds.add(psa.AssigneeId);
      }
      List<User> userList = [
        SELECT
          id,
          Name,
          Username,
          Profile.Name,
          IsActive,
          Profile.UserLicense.Name
        FROM user
        WHERE IsActive = TRUE AND Id IN :assignedUserIds
      ];
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
        System.debug(
          'Permission Set Group assigned successfully to all users' + persetasi
        );
      } catch (DmlException e) {
        System.debug('Error assigning Permission Set Group: ' + e.getMessage());
      }
    } catch (Exception e) {
      System.debug('Error assigning Permission Set Group: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
    //used
  public static void deletePermissionSetGroupWithUnassignments(
    string permissionSetGroupId
  ) {
    try {
      // Step 1: Retrieve and delete PermissionSetAssignments related to the PermissionSetGroup
      List<PermissionSetAssignment> assignmentsToDelete = [
        SELECT Id
        FROM PermissionSetAssignment
        WHERE PermissionSetGroupId = :permissionSetGroupId
      ];

      if (!assignmentsToDelete.isEmpty()) {
        delete assignmentsToDelete;
        System.debug('Permission Set Group assignments deleted successfully.');
      } else {
        System.debug('No user assignments found for the Permission Set Group.');
      }

      // Step 2: Retrieve and delete PermissionSetGroupComponents related to the PermissionSetGroup
      List<PermissionSetGroupComponent> componentsToDelete = [
        SELECT Id
        FROM PermissionSetGroupComponent
        WHERE PermissionSetGroupId = :permissionSetGroupId
      ];

      if (!componentsToDelete.isEmpty()) {
        delete componentsToDelete;
        System.debug('Permission Set Group components deleted successfully.');
      } else {
        System.debug('No components found for the Permission Set Group.');
      }

      // Step 3: Retrieve and delete the PermissionSetGroup
      PermissionSetGroup permissionSetGroupToDelete = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE Id = :permissionSetGroupId
        LIMIT 1
      ];

      delete permissionSetGroupToDelete;
      System.debug('Permission Set Group deleted successfully.');
    } catch (Exception e) {
      System.debug(
        'Error while deleting Permission Set Group: ' + e.getMessage()
      );
      throw new AuraHandledException(e.getMessage());
    }
  }
  

  @AuraEnabled
    //used
  public static list<user> getUserPermissionSetGroup(
    String profileName,
    String userLicense,
    string perSetGrpId
  ) {
    List<PermissionSetAssignment> assignedUsers = [
      SELECT AssigneeId
      FROM PermissionSetAssignment
      WHERE PermissionSetGroupId = :perSetGrpId
    ];
    Set<Id> assignedUserIds = new Set<Id>();
    for (PermissionSetAssignment psa : assignedUsers) {
      assignedUserIds.add(psa.AssigneeId);
    }
    string query = 'select id,Name, Username, Profile.Name, IsActive, Profile.UserLicense.Name from user WHERE IsActive = true AND Id NOT IN :assignedUserIds';
    if (profileName != null && profileName != '' && profileName != 'All') {
      query += ' AND Profile.Name = :profileName';
    }
    if (userLicense != null && userLicense != '' && userLicense != 'All') {
      query += ' AND Profile.UserLicense.Name = :userLicense';
    }
    query += ' ORDER BY Name ASC';
    List<user> userList = Database.Query(query);
    system.debug('userList >>>' + userList);
    return userList;
  }

  @AuraEnabled
    //used
  public static list<Profile> getProfiles() {
    return [SELECT id, Name, UserLicense.Name FROM Profile ORDER BY name ASC];
  }

  @AuraEnabled
    //used
  public static void getPermissionGroup(
    List<string> userId,
    string PerSetGrpId
  ) {
    List<PermissionSetAssignment> persetasi = new List<PermissionSetAssignment>();
    for (string assignId : userId) {
      PermissionSetAssignment perasi = new PermissionSetAssignment();
      perasi.AssigneeId = assignId;
      perasi.PermissionSetGroupId = PerSetGrpId;
      persetasi.add(perasi);
    }

    try {
      insert persetasi;
      System.debug('Permission Set Group assigned successfully to all users');
    } catch (DmlException e) {
      System.debug('Error assigning Permission Set Group: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
    //used
  public static list<User> getPermissionSetGroup(string perSetGrpId) {
    List<PermissionSetAssignment> persetaList = [
      SELECT PermissionSetGroupId, AssigneeId
      FROM PermissionSetAssignment
      WHERE PermissionSetGroupId = :perSetGrpId
    ];
    Set<Id> userIds = new Set<Id>();
    for (PermissionSetAssignment perseta : persetaList) {
      userIds.add(perseta.AssigneeId);
    }
    List<User> users = [
      SELECT id, Name, Username, Profile.Name, Profile.UserLicense.Name
      FROM User
      WHERE Id IN :userIds
      ORDER BY Name ASC
    ];
    return users;
  }

  @AuraEnabled
    //used
  public static void deletePermissionGroup(
    List<string> userId,
    string perSetGrpId
  ) {
    //PermissionSetGroup persetgrp = [SELECT Id,DeveloperName FROM PermissionSetGroup WHERE DeveloperName = : PerSetGroupName LIMIT 1];

    List<PermissionSetAssignment> persetAssignForDlt = [
      SELECT id
      FROM PermissionSetAssignment
      WHERE AssigneeId IN :userId AND PermissionSetGroupId = :perSetGrpId
    ];
    try {
      delete persetAssignForDlt;
      System.debug('Permission Set Group Deleted successfully for the users');
    } catch (DmlException e) {
      System.debug('Error Deleting Permission Set Group: ' + e.getMessage());
    }
  }

  @AuraEnabled
    //used
  public static List<PermissionSet> getPermissionSet(
    string permissionSetGroupId,
    string searchperset
  ) {
    String typeValue = 'Group';
    List<PermissionSetGroupComponent> groupComponents = [
      SELECT PermissionSetId
      FROM PermissionSetGroupComponent
      WHERE PermissionSetGroupId = :permissionSetGroupId
    ];
    Set<Id> permissionSetIds = new Set<Id>();
    for (PermissionSetGroupComponent component : groupComponents) {
      permissionSetIds.add(component.PermissionSetId);
    }
    string query = 'SELECT Id, Name,Label,Description,LicenseId,License.Name,IsCustom,CreatedById,CreatedBy.Name,CreatedDate,LastModifiedById,LastModifiedBy.Name,LastModifiedDate,NamespacePrefix FROM PermissionSet WHERE Id NOT IN :permissionSetIds AND IsOwnedByProfile = false AND Type != :typeValue';
    if (searchperset != '' && searchperset != null) {
      string searchName = '%' + searchperset + '%';
      query += ' AND Label Like : searchName';
    }
    query += ' ORDER BY Label ASC';
    List<PermissionSet> perset = Database.Query(query);
    return perset;
  }

  @AuraEnabled
    //used
  public static List<PermissionSet> getAssignedPermissionSet(
    string permissionSetGroupId
  ) {
    List<PermissionSetGroupComponent> groupComponents = [
      SELECT PermissionSetId
      FROM PermissionSetGroupComponent
      WHERE PermissionSetGroupId = :permissionSetGroupId
    ];
    Set<Id> permissionSetIds = new Set<Id>();
    for (PermissionSetGroupComponent component : groupComponents) {
      permissionSetIds.add(component.PermissionSetId);
    }
    List<PermissionSet> perset = [
      SELECT
        Id,
        Name,
        Label,
        Description,
        License.Name,
        IsCustom,
        CreatedById,
        CreatedBy.Name,
        CreatedDate,
        LastModifiedById,
        LastModifiedBy.Name,
        LastModifiedDate
      FROM PermissionSet
      WHERE Id IN :permissionSetIds AND IsOwnedByProfile = FALSE
      ORDER BY Label ASC
    ];
    return perset;
  }

  @AuraEnabled
    //used
  public static void insertPermissionSet(
    list<string> permissionSetId,
    string permissionSetGroupId
  ) {
    List<PermissionSetGroupComponent> persetasi = new List<PermissionSetGroupComponent>();
    for (string permissionId : permissionSetId) {
      PermissionSetGroupComponent perasi = new PermissionSetGroupComponent();
      perasi.PermissionSetId = permissionId;
      perasi.PermissionSetGroupId = permissionSetGroupId;
      persetasi.add(perasi);
    }
    try {
      insert persetasi;
      System.debug(
        'Permission Set Group assigned successfully to Permission Set'
      );
    } catch (DmlException e) {
      System.debug('Error assigning Permission Set Group: ' + e.getMessage());
      throw new AuraHandledException(e.getMessage());
    }
  }

  @AuraEnabled
    //used
  public static void deletePermissionSet(
    List<string> permissionSetId,
    string perSetGrpId
  ) {
    List<PermissionSetGroupComponent> persetAssignForDlt = [
      SELECT id
      FROM PermissionSetGroupComponent
      WHERE
        PermissionSetId IN :permissionSetId
        AND PermissionSetGroupId = :perSetGrpId
    ];
    try {
      delete persetAssignForDlt;
      System.debug(
        'Permission Set Group Deleted successfully for the PermissionSet'
      );
    } catch (DmlException e) {
      System.debug('Error Deleting Permission Set Group: ' + e.getMessage());
    }
  }

  //PROFILE
  public class UserAndProfileDetails {
    @Auraenabled
    public List<User> userList { get; set; }
    @Auraenabled
    public String profileName { get; set; }
    public UserAndProfileDetails(List<User> userList, String profileName) {
      this.userList = userList;
      this.profileName = profileName;
    }
  }
  @AuraEnabled(cacheable=true)
    //used
  public static UserAndProfileDetails getProfileusers(String profId) {
    return new UserAndProfileDetails(
      [
        SELECT id, Name, Username, Profile.UserLicense.Name, IsActive
        FROM user
        WHERE ProfileId = :profId AND IsActive = TRUE
        ORDER BY Name ASC
      ],
      ManageUserAccess.getProfileName(profId)[0]
    );
  }

  @AuraEnabled(cacheable=true)
    //used
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
        isCustom
      FROM Permissionset
      WHERE IsOwnedByProfile = TRUE
      ORDER BY Profile.Name ASC
    ];
  }

  //WRAPPER FOR SYSEM PERMISSION,OBJECT PERMISSION AND FIELD PERMISSION FOR PERMISSION SET Group
  public class userObjAndFieldPermissionSetGroupWrapper {
    @AuraEnabled
    public List<CombinedPermissionsWrapper> combinedPermissions { get; set; }
    @AuraEnabled
    public Map<string, ObjectPermissions> objectPermissions { get; set; }
    @AuraEnabled
    public Map<string, ObjectPermissions> mutingobjectPermissions { get; set; }
    @AuraEnabled
    public Map<String, List<fieldPermissions>> fieldPermissions { get; set; }
    @AuraEnabled
    public Map<String, List<fieldPermissions>> mutingfieldPermissions {
      get;
      set;
    }
    @AuraEnabled
    public List<TabDefinition> tabsetting { get; set; }

    public userObjAndFieldPermissionSetGroupWrapper(
      List<CombinedPermissionsWrapper> combinedPermissions,
      Map<string, ObjectPermissions> objectPermissions,
      Map<string, ObjectPermissions> mutingobjectPermissions,
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

  @AuraEnabled
    //used
  public static Map<String, ObjectPermissions> getObjectPermissionsforPSG(
    String persetgrpid
  ) {
    Map<String, ObjectPermissions> objMap = new Map<String, ObjectPermissions>();

    List<ObjectPermissions> objPermissions = [
      SELECT
        SobjectType,
        PermissionsRead,
        PermissionsCreate,
        PermissionsEdit,
        PermissionsDelete,
        PermissionsViewAllRecords,
        PermissionsModifyAllRecords
      FROM ObjectPermissions
      WHERE Parent.PermissionSetGroupId = :persetgrpid
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
    //used
  public static Map<String, ObjectPermissions> getmutingObjectPermissionsforPSG(
    String persetgrpid,
    string psgapiname,
    string psgname
  ) {
    Map<String, ObjectPermissions> objMap = new Map<String, ObjectPermissions>();

    string nullValue = '%_%';
    list<PermissionSetGroupComponent> per = [
      SELECT
        id,
        PermissionSetId,
        PermissionSet.Name,
        PermissionSetGroupId,
        PermissionSetGroup.DeveloperName
      FROM PermissionSetGroupComponent
      WHERE
        PermissionSetGroupId = :persetgrpid
        AND (NOT PermissionSet.Name LIKE :nullValue)
    ];
    string ids;
    for (PermissionSetGroupComponent pe : per) {
      system.debug(pe);
      ids = pe.PermissionSetId;
    }

    List<MutingPermissionSet> mpsList = [
      SELECT id
      FROM MutingPermissionSet
      WHERE id = :ids
    ];

    MutingPermissionSet mutingPermissionSet;

    if (!mpsList.isEmpty()) {
      mutingPermissionSet = mpsList[0];
      ids = mutingPermissionSet.Id;
      system.debug('Id' + ids);
    } else {
      mutingPermissionSet = new MutingPermissionSet();
      mutingPermissionSet.MasterLabel = psgname + ' Muted';
      mutingPermissionSet.DeveloperName = psgapiname + '_Muted';
      insert mutingPermissionSet;

      system.debug('Id' + mutingPermissionSet.Id);

      ids = mutingPermissionSet.Id;

      PermissionSetGroup psGroup = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE Id = :persetgrpid
        LIMIT 1
      ];

      PermissionSetGroupComponent component = new PermissionSetGroupComponent(
        PermissionSetGroupId = psGroup.Id,
        PermissionSetId = mutingPermissionSet.Id
      );
      insert component;
    }

    List<ObjectPermissions> objPermissions = [
      SELECT
        SobjectType,
        PermissionsRead,
        PermissionsCreate,
        PermissionsEdit,
        PermissionsDelete,
        PermissionsViewAllRecords,
        PermissionsModifyAllRecords
      FROM ObjectPermissions
      WHERE ParentId = :ids
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
    //used
  public static Map<String, List<FieldPermissions>> getFieldPermissionspsg(
    String persetgrpid
  ) {
    //List<Map<String, List<FieldPermissions>>> fieldList = new List<Map<String, List<FieldPermissions>>>();

    List<FieldPermissions> fieldPermissions = [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE Parent.PermissionSetGroupId = :persetgrpid
    ];

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
    //used
  public static Map<String, List<fieldPermissions>> getmutingFieldPermissionspsg(
    String persetgrpid
  ) {
    //List<Map<String, List<FieldPermissions>>> fieldList = new List<Map<String, List<FieldPermissions>>>();

    string nullValue = '%_%';
    list<PermissionSetGroupComponent> per = [
      SELECT
        id,
        PermissionSetId,
        PermissionSet.Name,
        PermissionSetGroupId,
        PermissionSetGroup.DeveloperName
      FROM PermissionSetGroupComponent
      WHERE
        PermissionSetGroupId = :persetgrpid
        AND (NOT PermissionSet.Name LIKE :nullValue)
    ];
    string ids;
    for (PermissionSetGroupComponent pe : per) {
      system.debug(pe);
      ids = pe.PermissionSetId;
    }

    List<MutingPermissionSet> mpsList = [
      SELECT id
      FROM MutingPermissionSet
      WHERE id = :ids
    ];

    ids = mpsList[0].Id;

    List<FieldPermissions> fieldPermissions = [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE ParentId = :ids
    ];

    Map<String, List<FieldPermissions>> fieldmap = new Map<String, List<FieldPermissions>>();

    for (FieldPermissions fie : fieldPermissions) {
      if (!fieldmap.containsKey(fie.SObjectType)) {
        fieldmap.put(fie.SObjectType, new List<FieldPermissions>());
      }
      fieldmap.get(fie.SObjectType).add(fie);
    }

    return fieldmap;
  }

  public class CombinedPermissionsWrapper {
    //@AuraEnabled public map<string,string> systemPermissions{get;set;}
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public String fieldLabel;
    @AuraEnabled
    public Object fieldValue;
    @AuraEnabled
    public Object mutedValue;
    @AuraEnabled
    public String mutedId;
    @AuraEnabled
    public Boolean hasDependencies;
    @AuraEnabled
    public List<String> requiredPermissions;
    @AuraEnabled
    public List<TabPermissionWrapper> tabPermissions;
    

    public CombinedPermissionsWrapper(
      String fieldName,
      String fieldLabel,
      Object fieldValue,
      Object mutedValue,
      String mutedId
    ) {
      //systemPermissions = new map<string,string>();
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

 

  public class TabPermissionWrapper {
    @AuraEnabled
    public String tabName { get; set; }
    @AuraEnabled
    public String visibility { get; set; }

    public TabPermissionWrapper(String tabName, String visibility) {
      this.tabName = tabName;
      this.visibility = visibility;
    }
  }

  @AuraEnabled(cacheable=false)
    //used
  public static userObjAndFieldPermissionSetGroupWrapper getCombinedPermissions(
    String permissionSetGroupId,
    string persetapi,
    string persetname
  ) {
    system.debug('Id--->' + permissionSetGroupId);
    List<CombinedPermissionsWrapper> combinedPermissions = new List<CombinedPermissionsWrapper>();

    String baseQueryString = 'SELECT Id, Name';
    Map<String, Schema.SObjectField> baseFields = Schema.SObjectType.PermissionSet.fields.getMap();

    // Build the query string and collect permission fields

    for (Schema.SObjectField field : baseFields.values()) {
      String fieldName = field.getDescribe().getName();
      if (
        fieldName.startsWith('Permissions') &&
        fieldName != 'Permissionsetgroupid'
      ) {
        baseQueryString += ', ' + field;
        String fieldLabel = field.getDescribe().getLabel();
        combinedPermissions.add(
          new CombinedPermissionsWrapper(
            fieldName,
            fieldLabel,
            null,
            null,
            null
          )
        ); // Initialize with null
      }
    }

    // Retrieve permission sets related to the permission set group
    List<PermissionSetGroupComponent> groupComponents = [
      SELECT PermissionSetId
      FROM PermissionSetGroupComponent
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

    string nullValue = '%_%';
    list<PermissionSetGroupComponent> per = [
      SELECT
        id,
        PermissionSetId,
        PermissionSet.Name,
        PermissionSetGroupId,
        PermissionSetGroup.DeveloperName
      FROM PermissionSetGroupComponent
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
      
        String initialRequiredPermission = wrapper.fieldName.remove(
          'Permissions'
        );
        requiredPermissionFields.add(initialRequiredPermission);
      
    }
    system.debug('Length--->' + requiredPermissionFields.size());
    system.debug('Set-->' + requiredPermissionFields);

    // Perform batch callouts
    Map<String, List<String>> fieldPermissionsMap = checkForDependencies(
      requiredPermissionFields,
      false
    );
    system.debug('Field Permission map in main method' + fieldPermissionsMap);
    for (CombinedPermissionsWrapper wrapper : combinedPermissions) {
      String initialRequiredPermission = wrapper.fieldName.remove(
        'Permissions'
      );
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
    List<PermissionSetTabSetting> tabSettings = [
      SELECT Name, Visibility
      FROM PermissionSetTabSetting
      WHERE ParentId IN :permissionSetIds
    ];
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

    Map<string, ObjectPermissions> objectPermissions = manageUserAccess.getObjectPermissionsforPSG(
      permissionSetGroupId
    );
    Map<string, ObjectPermissions> mutingobjectPermissions = manageUserAccess.getmutingObjectPermissionsforPSG(
      permissionSetGroupId,
      persetapi,
      persetname
    );
    Map<String, List<fieldPermissions>> fieldPermissions = manageUserAccess.getFieldPermissionspsg(
      permissionSetGroupId
    );
    Map<String, List<fieldPermissions>> mutingfieldPermissions = manageUserAccess.getmutingFieldPermissionspsg(
      permissionSetGroupId
    );
    List<TabDefinition> tabsetting = [
      SELECT id, Name, SobjectName
      FROM TabDefinition
    ];

    system.debug('Object Permission' + objectPermissions);
    system.debug('Mute Object Permission' + mutingobjectPermissions);
    system.debug('Field Permission' + fieldPermissions);
    system.debug('Mute Field Permission' + mutingfieldPermissions);
    system.debug('Tab Setting' + tabsetting);

    return new userObjAndFieldPermissionSetGroupWrapper(
      truePermissions,
      objectPermissions,
      mutingobjectPermissions,
      fieldPermissions,
      mutingfieldPermissions,
      tabsetting
    );
  }
    
  // Mute System Permissions for Permission Set Group
  @AuraEnabled
    //used
  public static List<MutingPermissionSet> mutePermissions(
    String systemPermissionsMapJson,
    String psgname,
    String psgapiname,
    String psgid
  ) {
    System.debug('Map Values: ' + systemPermissionsMapJson);

    // Deserialize JSON to a map
    Map<String, Object> tempMap = (Map<String, Object>) JSON.deserializeUntyped(
      systemPermissionsMapJson
    );
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

      PermissionSetGroup psGroup = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE Id = :psgid
        LIMIT 1
      ];
      PermissionSetGroupComponent component = new PermissionSetGroupComponent(
        PermissionSetGroupId = psGroup.Id,
        PermissionSetId = mutingPermissionSet.Id
      );
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
        System.debug(
          'Field ' + permission + ' is not available on MutingPermissionSet.'
        );
      }
    }

    if (validPermissions.isEmpty()) {
      System.debug('No valid permissions to update.');
      return mpsListToInsert;
    }

    // Build dynamic query
    String fieldsList = 'Id, ' + String.join(validPermissions, ',');
    String query =
      'SELECT ' +
      fieldsList +
      ' FROM MutingPermissionSet WHERE Id = :mutingId';
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
        System.debug(
          'An error occurred while updating MutingPermissionSets: ' +
          e.getMessage()
        );
        throw new AuraHandledException(e.getMessage());
      }
    } else {
      System.debug('No MutingPermissionSet found with Id: ' + mutingId);
      throw new AuraHandledException('Contact System Admin');
    }
  }


  @AuraEnabled(cacheable=true)
    //used
  public static PermissionFieldWrap getCombinedPermissionsforProfile(
    string permissionSetIds
  ) {
    System.debug('pid==>' + permissionSetIds);
    PermissionFieldWrap permissionWrap = new PermissionFieldWrap();

    String baseQueryString = 'SELECT Id, Name';
    Map<String, Schema.SObjectField> baseFields = Schema.SObjectType.PermissionSet.fields.getMap();

    for (Schema.SObjectField field : baseFields.values()) {
      String fieldName = field.getDescribe().getName();
      if (
        fieldName.startsWith('Permissions') &&
        fieldName != 'Permissionsetgroupid'
      ) {
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
        if (
          fieldName.startsWith('Permissions') &&
          fieldName != 'Permissionsetgroupid'
        ) {
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

    List<Object> dependSystemPermissions = ManageUserAccess.checkDependencyforSystemPermissions();
    permissionWrap.systemDependencies = dependSystemPermissions;

    System.debug(
      'List of System Permissions: ' + permissionWrap.systemDependencies
    );

    Set<String> dependentObjects = new Set<String>();
    for (Object record : dependSystemPermissions) {
      Map<String, Object> recordMap = (Map<String, Object>) record;

      if (
        (String) recordMap.get('RequiredPermissionType') == 'Object Permission'
      ) {
        String requiredPermission = (String) recordMap.get(
          'RequiredPermission'
        );
        String requiredPermissionObject = requiredPermission.split('<')[0];
        dependentObjects.add(requiredPermissionObject);
      }
    }

    Map<String, Map<String, Object>> objectPermissionsMap = new Map<String, Map<String, Object>>();
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
      WHERE ParentId = :permissionSetIds AND SObjectType IN :dependentObjects
    ]) {
      if (objPerm != null) {
        Map<String, Object> objectPermMap = new Map<String, Object>();
        objectPermMap.put('PermissionsCreate', objPerm.PermissionsCreate);
        objectPermMap.put('PermissionsRead', objPerm.PermissionsRead);
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
        objectPermissionsMap.put(objPerm.SObjectType, objectPermMap);
      }
    }

    System.debug('Object Permission Map: ' + objectPermissionsMap);
    permissionWrap.objectPermissions = objectPermissionsMap;

    return permissionWrap;
  }

    //used
  private static Map<String, List<String>> checkForDependencies(
    Set<String> fieldNames,
    Boolean isUpdateSystemPermissions
  ) {
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
    String pertype = 'User Permission';
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

    String username = System.Label.Board_Book_Integration_Username;
    String password = System.Label.Board_Book_Integration_Password;

      /*
    partnerWsdl2Apex.soap soapObj = new partnerWsdl2Apex.soap();
    partnerWsdl2Apex.LoginResult sessionInfoObj = soapObj.login(
      username,
      password
    );
*/
      ManageUserAccessPartner instance = new ManageUserAccessPartner();

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

  @AuraEnabled
    //used
  public static List<Map<String, Object>> getTabSettingpsg(String persetname) {
      ManageUserAccess instance = new ManageUserAccess();
    List<MetadataService.PermissionSetGroup> permSetGroupList = 
        (List<MetadataService.PermissionSetGroup>) instance.service.readMetadata('PermissionSetGroup', new String[] {persetname}).getRecords();
    MetadataService.PermissionSetGroup permSetGroup = permSetGroupList[0];

    // Map to store unique tab settings (key: tab name, value: visibility)
    Map<String, String> uniqueTabSettings = new Map<String, String>();

    if (permSetGroup.permissionSets != null) {
        for (String permissionSetName : permSetGroup.permissionSets) {
            List<MetadataService.PermissionSet> permSetList = 
                (List<MetadataService.PermissionSet>) instance.service.readMetadata('PermissionSet', new String[] {permissionSetName}).getRecords();
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

  //Update Tab Setting
  public class TabSettingsWrapper {
    @AuraEnabled
    public String tab { get; set; }
    @AuraEnabled
    public String visibility { get; set; }
  }

  @AuraEnabled
    //used
public static List<TabSettingsWrapper> updatetab(String tabSettingsJson, String persetname) {
    System.debug('tabSettingsJson: ' + tabSettingsJson);

    // Deserialize the JSON into a List of Maps
    List<Map<String, String>> rawList = (List<Map<String, String>>) JSON.deserialize(tabSettingsJson, List<Map<String, String>>.class);
    List<TabSettingsWrapper> tabSettings = new List<TabSettingsWrapper>();

    // Convert the raw list into TabSettingsWrapper list
    for (Map<String, String> item : rawList) {
        for (String tabName : item.keySet()) {
            String visibility = item.get(tabName);

            // Create the wrapper object
            TabSettingsWrapper wrapper = new TabSettingsWrapper();
            wrapper.tab = tabName;
            wrapper.visibility = visibility;

            tabSettings.add(wrapper);
        }
    }

    System.debug('tabSettings: ' + tabSettings);
    return updatetabsetting(tabSettings, persetname);
}

  @AuraEnabled
    //used
public static List<TabSettingsWrapper> updatetabsetting(
    List<TabSettingsWrapper> tabSettings,
    String persetname
) {
    ManageUserAccess instance = new ManageUserAccess();

    // Retrieve the PermissionSet metadata
    List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
        'PermissionSet',
        new List<String>{ persetname }
    ).getRecords();

    MetadataService.PermissionSet permissionSet;
    if (permissionSets.size() > 0) {
        permissionSet = permissionSets[0];

        if (permissionSet.tabSettings == null) {
            permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();
        }

        // Collect tabs to remove
        Set<String> tabsToRemove = new Set<String>();

        // Update existing tab settings and collect tabs to remove
        for (TabSettingsWrapper tabSettingWrapper : tabSettings) {
            String tabName = tabSettingWrapper.tab;
            String visibility = tabSettingWrapper.visibility;

            if (visibility == null) {
                // If visibility is null, mark the tab for removal
                tabsToRemove.add(tabName);
            } else {
                Boolean tabFound = false;
                for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
                    if (existingTabSetting.tab == tabName) {
                        existingTabSetting.visibility = visibility;
                        tabFound = true;
                        break;
                    }
                }

                // Add new tab setting if not found
                if (!tabFound) {
                    MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                    newTabSetting.tab = tabName;
                    newTabSetting.visibility = visibility;
                    permissionSet.tabSettings.add(newTabSetting);
                }
            }
        }

        // Remove tabs with null visibility using manual iteration
        List<MetadataService.PermissionSetTabSetting> updatedTabSettings = new List<MetadataService.PermissionSetTabSetting>();
        for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
            if (!tabsToRemove.contains(existingTabSetting.tab)) {
                updatedTabSettings.add(existingTabSetting);
            }
        }
        permissionSet.tabSettings = updatedTabSettings;
        system.debug('Tabs to Remove'+tabsToRemove);
    } else {
        // PermissionSet not found, create a new one
        permissionSet = new MetadataService.PermissionSet();
        permissionSet.fullName = persetname;
        permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();

        for (TabSettingsWrapper tabSettingWrapper : tabSettings) {
            if (tabSettingWrapper.visibility != null) {
                MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                newTabSetting.tab = tabSettingWrapper.tab;
                newTabSetting.visibility = tabSettingWrapper.visibility;
                permissionSet.tabSettings.add(newTabSetting);
            }
        }
    }

    // Update the PermissionSet metadata
    MetadataService.SaveResult[] results = instance.service.updateMetadata(
        new List<MetadataService.Metadata>{ permissionSet }
    );

    for (MetadataService.SaveResult result : results) {
        System.debug('AsyncResult id: ' + result.fullName);
        System.debug('Status: ' + result.success);
        // Check for errors
        if (!result.success) {
            for (MetadataService.Error error : result.errors) {
                System.debug('Error: ' + error.message);
            }
        }
    }
    return tabSettings;
}

  @AuraEnabled
    //used
  public static Map<String, String> updateProfile(
    String profileName,
    String newProfileName,
    String newDescription
  ) {
      system.debug('profileName'+profileName);
      system.debug('newProfileName'+newProfileName);
      system.debug('newDescription'+newDescription);
    ManageUserAccess instance = new ManageUserAccess();
    Map<String, String> returnMap = new Map<String, String>();
    List<MetadataService.Profile> profilesToUpdate = new List<MetadataService.Profile>();
    List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata(
        'Profile',
        new List<String>{ profileName }
      )
      .getRecords();
    if (profiles[0].fullName != null) {
      for (MetadataService.Profile profile : profiles) {
        MetadataService.Profile updatedProfile = new MetadataService.Profile();
        updatedProfile.fullName = newProfileName;
        updatedProfile.description = newDescription;

        profilesToUpdate.add(updatedProfile);
      }
      MetadataService.UpsertResult[] results = instance.service.upsertMetadata(
        profilesToUpdate
      );
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
            'Profile updated successfully for: ' + upsertResult.fullName
          );
          returnMap.put('label', upsertResult.fullName);
          returnMap.put('description', newDescription);
        }
      }
    }
    system.debug('check return map' + returnMap);
    return returnMap;
  }

  @AuraEnabled
    //used
  public static void deleteProfile(String profileName) {
    system.debug('Profle Name' + profileName);
    ManageUserAccess instance = new ManageUserAccess();

    MetadataService.DeleteResult[] deleteResults = instance.service.deleteMetadata(
      'Profile',
      new List<String>{ profileName }
    );

    for (MetadataService.DeleteResult deleteResult : deleteResults) {
      System.debug('Deleted Metadata: ' + deleteResult.fullName);
      System.debug('Status: ' + deleteResult.success);
      if (!deleteResult.success) {
        for (MetadataService.Error error : deleteResult.errors) {
          System.debug('Error: ' + error.message);
          throw new AuraHandledException(
            'An error occurred while deleting Profile: ' + error.message
          );
        }
      }
    }
  }

  //Update System Permission
  @AuraEnabled
    //used
  public static Map<String, Boolean> updateSystemPermissionsProf(
    String profileName,
    Map<String, Boolean> systemPermissions
  ) {
    // Create an instance of ManageUserAccess
    ManageUserAccess instance = new ManageUserAccess();
    Map<String, Boolean> updatedResult = new Map<String, Boolean>();

    // Fetch the profiles
    List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata(
        'Profile',
        new List<String>{ profileName }
      )
      .getRecords();
    List<MetadataService.Profile> profilesToUpdate = new List<MetadataService.Profile>();

    // Iterate through the profiles
    for (MetadataService.Profile profile : profiles) {
      MetadataService.Profile updatedProfile = new MetadataService.Profile();
      updatedProfile.fullName = profile.fullName;
      updatedProfile.userPermissions = new List<MetadataService.ProfileUserPermission>();

      // Iterate through the system permissions to update
      for (String permissionName : systemPermissions.keySet()) {
        MetadataService.ProfileUserPermission newPermission = new MetadataService.ProfileUserPermission();
        newPermission.name = permissionName;
        newPermission.enabled = systemPermissions.get(permissionName);
        updatedProfile.userPermissions.add(newPermission);
      }

      profilesToUpdate.add(updatedProfile);
    }

    // Upsert the updated profiles
    MetadataService.UpsertResult[] results = instance.service.upsertMetadata(
      profilesToUpdate
    );

    // Process the upsert results
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
          'Error updating profile: ' + upsertResult.errors[0].message
        );
      } else {
        System.debug(
          'Profile updated successfully for: ' + upsertResult.fullName
        );
        for (MetadataService.Profile updateProf : profilesToUpdate) {
          System.debug('updateProf: ' + updateProf);
          if (updateProf.userPermissions != null) {
            for (
              MetadataService.ProfileUserPermission updateProfUser : updateProf.userPermissions
            ) {
              updatedResult.put(updateProfUser.name, updateProfUser.enabled);
            }
          }
        }
      }
    }
    System.debug('updatedResult: ' + updatedResult);
    return updatedResult;
  }

  public class ProfileObjectDetails {
    @AuraEnabled
    public List<EntityDefinition> entityDefList { get; set; }
    @AuraEnabled
    public Map<string, Object> objectPermissions { get; set; }

    public ProfileObjectDetails(
      List<EntityDefinition> entityDefList,
      Map<string, Object> objectPermissions
    ) {
      this.entityDefList = entityDefList;
      this.objectPermissions = objectPermissions;
    }
  }

  @AuraEnabled
    //used
  public static ProfileObjectDetails getProfileObjectDetails(String permId) {
    Map<String, Object> objectPermissionsMap = new Map<String, Object>();
    if (permId != null && permId != '') {
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
        WHERE ParentId = :permId
      ]) {
        if (objPerm != null) {
          Map<String, Object> objectPermMap = new Map<String, Object>();
          objectPermMap.put('PermissionsCreate', objPerm.PermissionsCreate);
          objectPermMap.put('PermissionsRead', objPerm.PermissionsRead);
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
          objectPermissionsMap.put(objPerm.SObjectType, objectPermMap);
        }
      }
    }
    return new ProfileObjectDetails(
      [
        SELECT Id, Label, QualifiedApiName, NameSpacePrefix
        FROM EntityDefinition
        WHERE DefaultCompactLayoutId != NULL
      ],
      objectPermissionsMap
    );
  }

  public class ProfileObjectPermissionsWrapper {
    @AuraEnabled
    public List<Map<String, Object>> fieldPermissions { get; set; }
    @AuraEnabled
    public Boolean hasObjAccess { get; set; }
    @AuraEnabled
    public List<Object> dependentObj { get; set; }

    public ProfileObjectPermissionsWrapper(
      List<Map<String, Object>> fieldPermissions,
      Boolean hasObjAccess,
      List<Object> dependentObj
    ) {
      this.fieldPermissions = fieldPermissions;
      this.hasObjAccess = hasObjAccess;
      this.dependentObj = dependentObj;
    }
  }
  @AuraEnabled
    //used
  public static Map<String, Map<String, Object>> getFieldDefinitionProfile(
    String objectName
  ) {
    Map<String, Map<String, Object>> fieldDefMapByName = new Map<String, Map<String, Object>>();
    Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe()
      .get(objectName)
      .getDescribe();

    for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
      Map<String, Object> fieldDefMap = new Map<String, Object>();
      fieldDefMap.put('Label', field.getDescribe().getLabel());
      fieldDefMap.put('Name', field.getDescribe().getName());
      fieldDefMap.put(
        'isPermissionable',
        field.getDescribe().isPermissionable()
      );
      fieldDefMap.put('isCalculated', field.getDescribe().isCalculated());

      String fieldNameKey = objectName + '.' + field.getDescribe().getName();
      fieldDefMapByName.put(fieldNameKey, fieldDefMap);
    }
    return fieldDefMapByName;
  }
  @AuraEnabled
    //used
  public static ProfileObjectPermissionsWrapper getSobjectPermissionsForProfile(
    String permSetId,
    String objName
  ) {
    List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
    List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
    //List<Map<String, Object>> recordTypeMapList = new List<Map<String, Object>>();
    Map<String, Boolean> fieldAccess = ManageUserAccessPartner.checkFieldType(
      objName
    );
    system.debug('fieldAccess' + fieldAccess);
    Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
      objName
    );
    system.debug('Before Object Permission');
    Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
    for (FieldPermissions fieldPerm : [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE ParentId = :permSetId AND SObjectType = :objName
    ]) {
      if (fieldPerm != null) {
        fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
      }
    }
    // Debug: Check the contents of fieldPermissionsMap
    System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);

    // Process each field definition
    for (String fieldKey : fieldDefMapByName.keySet()) {
      if (fieldKey != null) {
        //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
        system.debug(fieldKey + ' fieldKey ' + fieldAccess.get(fieldKey));
        if (
          (Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') &&
          fieldAccess.get(fieldKey) == true
        ) {
          Map<String, Object> fieldPermissionMap = new Map<String, Object>();
          fieldPermissionMap.put('Field', fieldKey);
          fieldPermissionMap.put(
            'label',
            fieldDefMapByName.get(fieldKey).get('Label')
          );

          // Debug: Check if fieldKey is present in fieldPermissionsMap
          System.debug('Processing fieldKey: ' + fieldKey);
          if (fieldPermissionsMap.containsKey(fieldKey)) {
            system.debug('inside containskey');
            FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
            fieldPermissionMap.put(
              'PermissionsRead',
              fieldPerm.PermissionsRead
            );
            fieldPermissionMap.put(
              'PermissionsEdit',
              fieldPerm.PermissionsEdit
            );
          } else {
            fieldPermissionMap.put('PermissionsRead', false);
            fieldPermissionMap.put('PermissionsEdit', false);
          }

          fieldPermissionMap.put(
            'hasEditAccess',
            fieldDefMapByName.get(fieldKey).get('isCalculated')
          );
          fieldPermissionsMapList.add(fieldPermissionMap);
        }
      }
    }
    System.debug('check field permission map' + fieldPermissionsMapList);
    //System.debug('check recordtype permission map' + recordTypeMapList);
    return new ProfileObjectPermissionsWrapper(
      fieldPermissionsMapList,
      ManageUserAccessPartner.checkSObjType(objName),
      dependObjects
    );
  }

  @AuraEnabled
    //used
  public static ProfileObjectPermissionsWrapper getSobjectPermissionsForPermissionSet(
    String permSetId,
    String objName,
    List<String> profileNames
  ) {
    List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
    List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
    //List<Map<String, Object>> recordTypeMapList = new List<Map<String, Object>>();
   	Map<String, Boolean> fieldAccess = ManageUserAccessPartner.checkFieldType(objName);
    system.debug('fieldAccess' + fieldAccess);
    Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
      objName
    );
    system.debug('Before Object Permission');
    Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
    for (FieldPermissions fieldPerm : [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE ParentId = :permSetId AND SObjectType = :objName
    ]) {
      if (fieldPerm != null) {
        fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
      }
    }
    // Debug: Check the contents of fieldPermissionsMap
    System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);

    // Process each field definition
    for (String fieldKey : fieldDefMapByName.keySet()) {
      if (fieldKey != null) {
        //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
        system.debug(fieldKey + ' fieldKey ' + fieldAccess.get(fieldKey));
        if (
          (Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') &&
          fieldAccess.get(fieldKey) == true
        ) {
         Map<String, Object> fieldPermissionMap = new Map<String, Object>();
          fieldPermissionMap.put('Field', fieldKey);
          fieldPermissionMap.put(
            'label',
            fieldDefMapByName.get(fieldKey).get('Label')
          );

          // Debug: Check if fieldKey is present in fieldPermissionsMap
          System.debug('Processing fieldKey: ' + fieldKey);
          if (fieldPermissionsMap.containsKey(fieldKey)) {
            system.debug('inside containskey');
            FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
            fieldPermissionMap.put(
              'PermissionsRead',
              fieldPerm.PermissionsRead
            );
            fieldPermissionMap.put(
              'PermissionsEdit',
              fieldPerm.PermissionsEdit
            );
          } else {
            fieldPermissionMap.put('PermissionsRead', false);
            fieldPermissionMap.put('PermissionsEdit', false);
          }

          fieldPermissionMap.put(
            'hasEditAccess',
            fieldDefMapByName.get(fieldKey).get('isCalculated')
          );
          fieldPermissionsMapList.add(fieldPermissionMap);

          // Debug: Check the contents of fieldPermissionMap
          //System.debug('fieldPermissionMap: ' + fieldPermissionMap);
        }
      }
    }
    System.debug('check field permission map' + fieldPermissionsMapList);
    //System.debug('check recordtype permission map' + recordTypeMapList);
    return new ProfileObjectPermissionsWrapper(
      fieldPermissionsMapList,
      ManageUserAccessPartner.checkSObjType(objName),
      dependObjects
    );
  }

  @AuraEnabled
    //used
  public static List<Map<String, Object>> getProfileTabSetting(
    List<String> profileName
  ) {
    List<Map<String, Object>> tabSettingMapList = new List<Map<String, Object>>();
    Map<String, String> tabVisibilities = getTabPermissions(profileName);
    List<TabDefinition> tabDefList = [
      SELECT id, Name, Label
      FROM TabDefinition
      ORDER BY Label ASC
    ];
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
    //used
  public static Void updateTabSettings(
    List<String> profileNames,
    List<Map<String, Object>> tabToUpdate
  ) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<MetadataService.Profile> profilesToUpdate = new List<MetadataService.Profile>();
    List<MetadataService.Profile> profiles = (List<MetadataService.Profile>) instance.service.readMetadata(
        'Profile',
        profileNames
      )
      .getRecords();
    if (Profiles != null) {
      for (MetadataService.Profile prof : Profiles) {
        MetadataService.Profile updatedProfile = new MetadataService.Profile();
        updatedProfile.fullName = prof.fullName;
        system.debug('check full Name' + updatedProfile.fullName);
        updatedProfile.tabVisibilities = new List<MetadataService.ProfileTabVisibility>();
        Map<String, MetadataService.ProfileTabVisibility> existingVisibilities = new Map<String, MetadataService.ProfileTabVisibility>();
        if (prof.tabVisibilities != null) {
          for (
            MetadataService.ProfileTabVisibility visibility : prof.tabVisibilities
          ) {
            //existingVisibilities.put(visibility.recordType, visibility);
            existingVisibilities.put(visibility.tab, visibility);
          }
        }
        system.debug('check existingVisibilities' + existingVisibilities);
        for (Map<String, Object> tab : tabToUpdate) {
            system.debug('Tab.Name'+ tab.get('Name'));
            system.debug('tab'+ tab);
          MetadataService.ProfileTabVisibility visibility = existingVisibilities.get(
            (String) tab.get('Name')
          );
          if (Visibility != null) {
            visibility = new MetadataService.ProfileTabVisibility();
            visibility.tab = (String) tab.get('Name');
          }
          visibility.visibility = (String) tab.get('Visibility');
          system.debug('check visibility' + visibility);
          updatedProfile.tabVisibilities.add(visibility);
        }
        system.debug(
          'updatedProfile.tabVisibilities' + updatedProfile.tabVisibilities
        );
        profilesToUpdate.add(updatedProfile);
      }
      if (!profilesToUpdate.isEmpty()) {
        try {
          List<MetadataService.UpsertResult> results = instance.service.upsertMetadata(
            profilesToUpdate
          );

          for (MetadataService.UpsertResult upsertResult : results) {
            if (!upsertResult.success) {
              for (MetadataService.Error error : upsertResult.errors) {
                System.debug(
                  'Error: ' +
                    error.message +
                    ' Status Code: ' +
                    error.statusCode
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
                'Tab Setting visibilities updated successfully for: ' +
                upsertResult.fullName
              );
            }
          }
          //return tabToUpdate;
        } catch (Exception e) {
          System.debug('Error updating profiles: ' + e.getMessage());
          //return null;
        }
      }
    }
  }

  //2nd approach
  @AuraEnabled
  public static List<Object> checkDependency(String objName) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<Object> allDependencies = new List<Object>();

    // Fetch dependencies for the given object
    fetchDependencies(
      objName,
      allDependencies,
      instance.partnerConnection.SessionHeader.sessionId,
      URL.getSalesforceBaseUrl().toExternalForm()
    );

    // Extract object names from Permission and RequiredPermission fields
    Set<String> objNamesSet = new Set<String>();
    for (Object record : allDependencies) {
      Map<String, Object> recordMap = (Map<String, Object>) record;
      String permission = (String) recordMap.get('Permission');
      String requiredPermission = (String) recordMap.get('RequiredPermission');

      if (permission != null) {
        String objNameFromPermission = permission.split('<')[0];
        objNamesSet.add(objNameFromPermission);
      }

      if (requiredPermission != null) {
        String objNameFromReqPermission = requiredPermission.split('<')[0];
        objNamesSet.add(objNameFromReqPermission);
      }
    }

    // Query FieldDefinition based on objNamesSet
    List<FieldDefinition> fieldDefinitions = [
      SELECT
        Id,
        IsPolymorphicForeignKey,
        EntityDefinition.QualifiedApiName,
        DeveloperName
      FROM FieldDefinition
      WHERE
        IsPolymorphicForeignKey = TRUE
        AND EntityDefinition.QualifiedApiName IN :objNamesSet
    ];

    // Filter allDependencies based on the query result
    Set<String> matchingObjNamesSet = new Set<String>();
    for (FieldDefinition fieldDef : fieldDefinitions) {
      matchingObjNamesSet.add(fieldDef.EntityDefinition.QualifiedApiName);
    }

    // Remove matching records from allDependencies
    List<Object> filteredDependencies = new List<Object>();
    for (Object record : allDependencies) {
      Map<String, Object> recordMap = (Map<String, Object>) record;
      String permission = (String) recordMap.get('Permission');
      String requiredPermission = (String) recordMap.get('RequiredPermission');

      String objNameFromPermission = permission != null
        ? permission.split('<')[0]
        : null;
      String objNameFromReqPermission = requiredPermission != null
        ? requiredPermission.split('<')[0]
        : null;

      if (
        !matchingObjNamesSet.contains(objNameFromPermission) &&
        !matchingObjNamesSet.contains(objNameFromReqPermission)
      ) {
        filteredDependencies.add(record);
      }
    }

    System.debug('Filtered Dependencies: ' + filteredDependencies);
    System.debug('Filtered Dependencies: ' + filteredDependencies.size());
    return filteredDependencies;
  }

  private static void fetchDependencies(
    String objName,
    List<Object> allDependencies,
    String sessionId,
    String serverUrl
  ) {
    if (objName == null || objName == '') {
      return;
    }

    // Mark the object as processed
    // processedObjects.add(objName);

    // Convert object name to formatted permissions
    List<String> permissions = new List<String>{
      'read',
      'edit',
      'delete',
      'create',
      'ViewAllRecords',
      'ModifyAllRecords'
    };
    String objNames = '';
    for (String perm : permissions) {
      objNames += '\'' + objName + '<' + perm + '>\',';
    }
    if (objNames.endsWith(',')) {
      objNames = objNames.removeEnd(',');
    }

    if (objNames != null && objNames != '') {
      String query =
        'SELECT Id, Permission, RequiredPermission ' +
        'FROM PermissionDependency ' +
        'WHERE (Permission LIKE \'%' +
        objName +
        '%\' ' +
        'OR RequiredPermission LIKE \'%' +
        objName +
        '%\')' +
        'AND PermissionType = \'Object Permission\' ' +
        'AND RequiredPermissionType = \'Object Permission\'';

      // Send the query request and process the result
      List<Object> queryResults = sendQueryRequest(query, sessionId, serverUrl);

      // Process the records
      Set<String> parentObjects = new Set<String>();
      Set<String> childObjects = new Set<String>();
      if (!queryResults.isEmpty()) {
        for (Object record : queryResults) {
          Map<String, Object> recordMap = (Map<String, Object>) record;
          allDependencies.add(record);
          String permission = (String) recordMap.get('Permission');
          String requiredPermission = (String) recordMap.get(
            'RequiredPermission'
          );

          if (permission != null && permission.contains(objName)) {
            parentObjects.add('\'' + requiredPermission + '\'');
          }
          if (
            requiredPermission != null && requiredPermission.contains(objName)
          ) {
            childObjects.add('\'' + permission + '\'');
          }
        }
      }
      System.debug('Parent Objects: ' + parentObjects);
      System.debug('Child Objects: ' + childObjects);

      // Recursively process parent and child objects
      if (!parentObjects.isEmpty()) {
        processParentObjects(
          new List<String>(parentObjects),
          allDependencies,
          sessionId,
          serverUrl
        );
      }
      if (!childObjects.isEmpty()) {
        processChildObjects(
          new List<String>(childObjects),
          allDependencies,
          sessionId,
          serverUrl
        );
      }
    }
  }

  private static Void processParentObjects(
    List<String> parentObjects,
    List<Object> allDependencies,
    String sessionId,
    String serverUrl
  ) {
    String parentObjNames = String.join(parentObjects, ',');
    system.debug('parentObjNames' + parentObjNames);
    String query =
      'SELECT Id, Permission, RequiredPermission ' +
      'FROM PermissionDependency ' +
      'WHERE Permission IN (' +
      parentObjNames +
      ') ' +
      'AND PermissionType = \'Object Permission\' ' +
      'AND RequiredPermissionType = \'Object Permission\'';
    system.debug('check query : ' + query);
    List<Object> queryResults = sendQueryRequest(query, sessionId, serverUrl);
    Set<String> newParentObjects = new Set<String>();
    if (!queryResults.isEmpty()) {
      for (Object record : queryResults) {
        system.debug(record);
        Map<String, Object> recordMap = (Map<String, Object>) record;
        allDependencies.add(record);
        String requiredPermission = (String) recordMap.get(
          'RequiredPermission'
        );
        if (requiredPermission != null) {
          newParentObjects.add('\'' + requiredPermission + '\'');
        }
      }
    }
    system.debug('newParentObjects' + newParentObjects);
    if (!newParentObjects.isEmpty()) {
      processParentObjects(
        new List<String>(newParentObjects),
        allDependencies,
        sessionId,
        serverUrl
      );
    }
  }
  private static Void processChildObjects(
    List<String> childObjects,
    List<Object> allDependencies,
    String sessionId,
    String serverUrl
  ) {
    String childObjNames = String.join(childObjects, ',');
    System.debug('ChildObjName : ' + childObjNames);
    String query =
      'SELECT Id, Permission, RequiredPermission ' +
      'FROM PermissionDependency ' +
      'WHERE RequiredPermission IN (' +
      childObjNames +
      ')' +
      'AND PermissionType = \'Object Permission\' ' +
      'AND RequiredPermissionType = \'Object Permission\'';

    List<Object> queryResults = sendQueryRequest(query, sessionId, serverUrl);
    Set<String> newChildObjects = new Set<String>();
    if (!queryResults.isEmpty()) {
      for (Object record : queryResults) {
        Map<String, Object> recordMap = (Map<String, Object>) record;
        allDependencies.add(record);
        String permission = (String) recordMap.get('Permission');
        if (permission != null) {
          newChildObjects.add('\'' + permission + '\'');
        }
      }
    }
    if (!newChildObjects.isEmpty()) {
      processChildObjects(
        new List<String>(newChildObjects),
        allDependencies,
        sessionId,
        serverUrl
      );
    }
  }
  public static List<Object> sendQueryRequest(
    String query,
    String sessionId,
    String serverUrl
  ) {
    String endpoint =
      serverUrl +
      '/services/data/v58.0/tooling/query?q=' +
      EncodingUtil.urlEncode(query, 'UTF-8');
    HttpRequest req = new HttpRequest();
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + sessionId);
    req.setHeader('Content-Type', 'application/json');
    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
      // Parse the JSON response
      Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      List<Object> records = (List<Object>) responseMap.get('records');
      return records != null ? records : new List<Object>();
    } else {
      System.debug('Error: ' + res.getStatus());
      return new List<Object>();
    }
  }

  //Tab Setting For Permission Set
  @AuraEnabled
    //used
  public static List<Map<String, Object>> getPermissionSetTabSetting(
    String permissionSetName
  ) {
    List<Map<String, Object>> tabSettingMapList = new List<Map<String, Object>>();
    Map<String, String> tabVisibilities = getTabForPermissionSet(
      permissionSetName
    );
    List<TabDefinition> tabDefList = [
      SELECT id, Name, Label
      FROM TabDefinition
      ORDER BY Label ASC
    ];
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
  public static Map<String, String> getTabForPermissionSet(
    String permissionSetName
  ) {
    ManageUserAccessPartner instance = new ManageUserAccessPartner();
    List<MetadataService.PermissionSet> perset = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
        'PermissionSet',
        new List<String>{ permissionSetName }
      )
      .getRecords();
    Map<String, String> tabSettingObj = new Map<String, String>();
    if (perset != null) {
      try {
        for (MetadataService.PermissionSet prof : perset) {
          if (prof.tabSettings != null) {
            for (
              MetadataService.PermissionSetTabSetting tabVisibility : prof.tabSettings
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

  //SYSTEM PERMISSION FOR PERMISSION SET
  public class PermissionFieldWrap {
    @AuraEnabled
    public List<Map<String, Object>> userPermissions;
    @AuraEnabled
    public List<Object> systemDependencies;
    @AuraEnabled
    public Map<String, Object> objectPermissions;

    public PermissionFieldWrap() {
      this.userPermissions = new List<Map<String, Object>>();
      this.systemDependencies = new List<Object>();
      this.objectPermissions = new Map<String, Object>();
    }
  }

  @AuraEnabled
  public static List<Object> checkDependencyforSystemPermissions() {
    List<Object> records;
    String query =
      'SELECT Id, Permission, RequiredPermission, PermissionType , RequiredPermissionType  ' +
      'FROM PermissionDependency ' +
      'WHERE PermissionType = \'User Permission\'';

    String username = System.Label.Board_Book_Integration_Username;
    String password = System.Label.Board_Book_Integration_Password;

    /*partnerWsdl2Apex.soap soapObj = new partnerWsdl2Apex.soap();
    /partnerWsdl2Apex.LoginResult sessionInfoObj = soapObj.login(
      username,
      password
    );*/
      ManageUserAccessPartner instance = new ManageUserAccessPartner();

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
      // Parse the JSON response
      Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );
      records = (List<Object>) responseMap.get('records');
    } else {
      System.debug('Error: ' + res.getStatus());
    }

    return records;
  }
    
    public class PermissionSetGroupObjectDetails {
    @AuraEnabled
    public List<EntityDefinition> entityDefList { get; set; }
    @AuraEnabled
    public Map<string, Object> objectPermissions { get; set; }
    public PermissionSetGroupObjectDetails(List<EntityDefinition> entityDefList,Map<string, Object> objectPermissions) {
      this.entityDefList = entityDefList;
      this.objectPermissions = objectPermissions;
    }
  }  

  @AuraEnabled(cacheable=true)
    //used
  public static PermissionSetGroupObjectDetails getSobject(String permId) {
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

    /*
  public class PermissionObjectPermissionsWrapper {
    @AuraEnabled
    public Map<string, Object> objectPermissions { get; set; }
    @AuraEnabled
    public List<Map<String, Object>> fieldPermissions { get; set; }
    @AuraEnabled
    public Boolean hasObjAccess { get; set; }
    @AuraEnabled
    public List<Object> objDependent { get; set; }
    @AuraEnabled
    public List<Map<String, Object>> recordTypeDetails { get; set; }

    public PermissionObjectPermissionsWrapper(
      Map<string, Object> objectPermissions,
      List<Map<String, Object>> fieldPermissions,
      Boolean hasObjAccess,
      List<Object> objDependent,
      List<Map<String, Object>> recordTypeDetails
    ) {
      this.objectPermissions = objectPermissions;
      this.fieldPermissions = fieldPermissions;
      this.hasObjAccess = hasObjAccess;
      this.objDependent = objDependent;
      this.recordTypeDetails = recordTypeDetails;
    }
  }

  @AuraEnabled
  public static PermissionObjectPermissionsWrapper getSobjectPermissionsForPermissions(
    String permSetId,
    String objName,
    String permissionsSetNames
  ) {
    manageUserAccess instance = new manageUserAccess();
    List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
    Set<String> dependentObjects = new Set<String>();

    for (Object record : dependObjects) {
      Map<String, Object> recordMap = (Map<String, Object>) record;
      String permission = (String) recordMap.get('Permission');
      String requiredPermission = (String) recordMap.get('RequiredPermission');

      // Filter for exact matches with word boundaries
      Boolean matchesPermission = Pattern.matches(
        '.*\\b' + Pattern.quote(objName) + '\\b.*',
        permission
      );
      Boolean matchesRequiredPermission = Pattern.matches(
        '.*\\b' + Pattern.quote(objName) + '\\b.*',
        requiredPermission
      );

      if (matchesPermission || matchesRequiredPermission) {
        String permissionObject = permission.split('<')[0];
        String requiredPermissionObject = requiredPermission.split('<')[0];
        dependentObjects.add(permissionObject);
        dependentObjects.add(requiredPermissionObject);
        /*System.debug('Id: ' + recordMap.get('Id') + 
                             ', Permission: ' + permission + 
                             ', RequiredPermission: ' + requiredPermission);
      }
    }

    Map<String, Object> objectPermissionsMap = new Map<String, Object>();
    List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
    Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
      objName
    );
    system.debug('Before Object Permission');
    // Object Permissions
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
      WHERE ParentId = :permSetId AND SObjectType IN :dependentObjects
    ]) {
      system.debug('Inside Object Permission');

      if (objPerm != null) {
        system.debug('Inside IF');
        Map<String, Object> objectPermMap = new Map<String, Object>();
        objectPermMap.put('PermissionsCreate', objPerm.PermissionsCreate);
        objectPermMap.put('PermissionsRead', objPerm.PermissionsRead);
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
        objectPermissionsMap.put(objPerm.SObjectType, objectPermMap);
      }
      system.debug('Obj Perm' + objPerm);
    }
    system.debug('After Object Permission');

    Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
    for (FieldPermissions fieldPerm : [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE ParentId = :permSetId AND SObjectType = :objName
    ]) {
      if (fieldPerm != null) {
        fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
      }
    }
    // Debug: Check the contents of fieldPermissionsMap
    System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);

    // Process each field definition
    for (String fieldKey : fieldDefMapByName.keySet()) {
      if (fieldKey != null) {
        //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
        if ((Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable')) {
          Map<String, Object> fieldPermissionMap = new Map<String, Object>();
          fieldPermissionMap.put('Field', fieldKey);
          fieldPermissionMap.put(
            'label',
            fieldDefMapByName.get(fieldKey).get('Label')
          );

          // Debug: Check if fieldKey is present in fieldPermissionsMap
          System.debug('Processing fieldKey: ' + fieldKey);
          if (fieldPermissionsMap.containsKey(fieldKey)) {
            FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
            fieldPermissionMap.put(
              'PermissionsRead',
              fieldPerm.PermissionsRead
            );
            fieldPermissionMap.put(
              'PermissionsEdit',
              fieldPerm.PermissionsEdit
            );
          } else {
            fieldPermissionMap.put('PermissionsRead', false);
            fieldPermissionMap.put('PermissionsEdit', false);
          }

          fieldPermissionMap.put(
            'hasEditAccess',
            fieldDefMapByName.get(fieldKey).get('isCalculated')
          );
          fieldPermissionsMapList.add(fieldPermissionMap);

          // Debug: Check the contents of fieldPermissionMap
          //System.debug('fieldPermissionMap: ' + fieldPermissionMap);
        }
      }
    }

    List<Map<String, Object>> recordTypeDetails = new List<Map<String, Object>>();

    List<RecordType> recordTypeList = [
      SELECT Id, Name, DeveloperName, SObjectType, NamespacePrefix
      FROM RecordType
      WHERE SObjectType = :objName
    ];

    Map<String, Map<String, Object>> recordTypes = new Map<String, Map<String, Object>>();

    // Create a map for record types with detailed information
    for (RecordType recType : recordTypeList) {
      if (recType != null) {
        String recTypeKey;
        if (recType.NamespacePrefix == null) {
          recTypeKey = recType.SObjectType + '.' + recType.DeveloperName;
        } else {
          recTypeKey =
            recType.SObjectType +
            '.' +
            recType.NamespacePrefix +
            '__' +
            recType.DeveloperName;
        }
        if (recType.Name == 'Person Account') {
          recTypeKey = 'PersonAccount.' + recType.DeveloperName;
        }

        Map<String, Object> recTypeMap = new Map<String, Object>();
        recTypeMap.put('Label', recType.Name);
        recTypeMap.put('developerName', recType.DeveloperName);
        recTypeMap.put('RecordType', recTypeKey);

        recordTypes.put(recTypeKey, recTypeMap);
      }
    }

    // Read metadata for the specified permission set
    List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
        'PermissionSet',
        new List<String>{ permissionsSetNames }
      )
      .getRecords();

    // Initialize the result map
    Map<String, Object> permissionSetMap = new Map<String, Object>();

    if (permissionSets != null && !permissionSets.isEmpty()) {
      try {
        // Get the first (and only) permission set from the list
        MetadataService.PermissionSet permissionSet = permissionSets[0];

        // Create a map for record type visibilities
        Map<String, Boolean> recordTypeVisibilityMap = new Map<String, Boolean>();

        // Check if the permission set has record type visibilities
        if (permissionSet.recordTypeVisibilities != null) {
          for (
            MetadataService.PermissionSetRecordTypeVisibility recordTypeVisibility : permissionSet.recordTypeVisibilities
          ) {
            // Check if the record type is for the specified object or 'PersonAccount.'
            if (
              recordTypeVisibility.recordType.startsWith(objName + '.') ||
              recordTypeVisibility.recordType.startsWith('PersonAccount.')
            ) {
              String recordTypeName = recordTypeVisibility.recordType.split(
                '\\.'
              )[1];
              // Add the visibility status to the map
              recordTypeVisibilityMap.put(
                recordTypeName,
                recordTypeVisibility.visible
              );
            }
          }
        }

        // Compare record types with the visibility settings
        for (String recordTypeKey : recordTypes.keySet()) {
          Map<String, Object> recordTypeInfo = recordTypes.get(recordTypeKey);
          Map<String, Object> recordTypeMap = new Map<String, Object>();
          recordTypeMap.put('Object', recordTypeInfo.get('Object'));
          recordTypeMap.put('RecordType', recordTypeInfo.get('RecordType'));
          recordTypeMap.put('label', recordTypeInfo.get('Label'));
          recordTypeMap.put(
            'developerName',
            recordTypeInfo.get('developerName')
          );

          // Set visibility status
          String recordTypeKeyStr = (String) recordTypeInfo.get('RecordType');
          String recordTypeName = recordTypeKeyStr != null
            ? recordTypeKeyStr.split('\\.')[1]
            : '';
          if (recordTypeVisibilityMap.containsKey(recordTypeName)) {
            recordTypeMap.put(
              'Visible',
              recordTypeVisibilityMap.get(recordTypeName)
            );
          } else {
            recordTypeMap.put('Visible', false);
          }

          // Add the map to the result list
          recordTypeDetails.add(recordTypeMap);
        }
      } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
      }
    }

    System.debug('check obj permission map' + objectPermissionsMap);
    //system.debug('Dependent Object---->'+dependObjects);
    system.debug('Dependent Object---->' + dependentObjects);
    System.debug('check field permission map' + fieldPermissionsMapList);
    return new PermissionObjectPermissionsWrapper(
      objectPermissionsMap,
      fieldPermissionsMapList,
      ManageUserAccessPartner.checkSObjType(objName),
      dependObjects,
      recordTypeDetails
    );
  }
*/

  public class PermissionSetGroupObjectPermissionsWrapper {
    //@AuraEnabled
    //public Map<string, Object> objectPermissions { get; set; }
    @AuraEnabled
    public List<Map<String, Object>> fieldPermissions { get; set; }
    @AuraEnabled
    public Boolean hasObjAccess { get; set; }
    @AuraEnabled
    public List<Object> objDependent { get; set; }
    @AuraEnabled
    public List<RecordType> recordTypeDetails { get; set; } // Updated to List<RecordType>
    @AuraEnabled
    public string MutedId { get; set; }

    public PermissionSetGroupObjectPermissionsWrapper(
      /*Map<string, Object> objectPermissions,*/
      List<Map<String, Object>> fieldPermissions,
      Boolean hasObjAccess,
      List<Object> objDependent,
      List<RecordType> recordTypeDetails,
      string muteId
    ) {
      //this.objectPermissions = objectPermissions;
      this.fieldPermissions = fieldPermissions;
      this.hasObjAccess = hasObjAccess;
      this.objDependent = objDependent;
      this.recordTypeDetails = recordTypeDetails;
      this.MutedId = muteId;
    }
  }

  @AuraEnabled
    //used
  public static PermissionSetGroupObjectPermissionsWrapper getSobjectPermissionsForPermissionSetGroup(
    String permSetId,
    String objName,
    String psgname,
    String psgapiname
  ) {
    System.debug('Perset Id' + permSetId);
    System.debug('Object Name' + objName);
    System.debug('PSG Name' + psgname);
    System.debug('PSG API Name' + psgapiname);
    manageUserAccess instance = new manageUserAccess();
    List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
    Map<String, Boolean> fieldAccess = ManageUserAccessPartner.checkFieldType(objName);
	system.debug('fieldAccess' + fieldAccess);

    string nullValue = '%_%';
    list<PermissionSetGroupComponent> per = [
      SELECT
        id,
        PermissionSetId,
        PermissionSet.Name,
        PermissionSetGroupId,
        PermissionSetGroup.DeveloperName
      FROM PermissionSetGroupComponent
      WHERE
        PermissionSetGroupId = :permSetId
        AND (NOT PermissionSet.Name LIKE :nullValue)
    ];
    string muteId;
    for (PermissionSetGroupComponent pe : per) {
      system.debug(pe);
      muteId = pe.PermissionSetId;
    }

    List<MutingPermissionSet> mpsList = [
      SELECT id
      FROM MutingPermissionSet
      WHERE id = :muteId
    ];

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

        /*
      PermissionSetGroup psGroup = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE Id = :muteId
        LIMIT 1
      ];*/
        PermissionSetGroup psGroup = [
        SELECT Id
        FROM PermissionSetGroup
        WHERE Id = : permSetId
        LIMIT 1
      ];
       

      PermissionSetGroupComponent component = new PermissionSetGroupComponent(
        PermissionSetGroupId = psGroup.Id,
        PermissionSetId = mutingPermissionSet.Id
      );
      insert component;
    }

    //Map<String, Object> objectPermissionsMap = new Map<String, Object>();

    List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();

    Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
      objName
    );
    system.debug('Before Object Permission');
    // Object Permissions
    
    Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
    for (FieldPermissions fieldPerm : [
      SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
      FROM FieldPermissions
      WHERE Parent.PermissionSetGroup.Id = :permSetId AND SObjectType = :objName
    ]) {
      if (fieldPerm != null) {
        fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
      }
    }
    // Debug: Check the contents of fieldPermissionsMap
    System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);

    // Process each field definition
    for (String fieldKey : fieldDefMapByName.keySet()) {
      if (fieldKey != null) {
        //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
        if ((Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') &&
          fieldAccess.get(fieldKey) == true) {
          Map<String, Object> fieldPermissionMap = new Map<String, Object>();
          fieldPermissionMap.put('Field', fieldKey);
          fieldPermissionMap.put(
            'label',
            fieldDefMapByName.get(fieldKey).get('Label')
          );

          // Debug: Check if fieldKey is present in fieldPermissionsMap
          System.debug('Processing fieldKey: ' + fieldKey);
          if (fieldPermissionsMap.containsKey(fieldKey)) {
            FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
            fieldPermissionMap.put(
              'PermissionsRead',
              fieldPerm.PermissionsRead
            );
            fieldPermissionMap.put(
              'PermissionsEdit',
              fieldPerm.PermissionsEdit
            );
          } else {
            fieldPermissionMap.put('PermissionsRead', false);
            fieldPermissionMap.put('PermissionsEdit', false);
          }

          fieldPermissionMap.put(
            'hasEditAccess',
            fieldDefMapByName.get(fieldKey).get('isCalculated')
          );
          fieldPermissionsMapList.add(fieldPermissionMap);

          // Debug: Check the contents of fieldPermissionMap
          //System.debug('fieldPermissionMap: ' + fieldPermissionMap);
        }
      }
    }

    List<RecordType> recordTypeDetails = [
      SELECT Id, Name, DeveloperName, NamespacePrefix
      FROM RecordType
      WHERE SobjectType = :objName
      ORDER BY Name ASC
    ];
      
    System.debug('check field permission map' + fieldPermissionsMapList);
    System.debug('check mute Id' + muteId);

    return new PermissionSetGroupObjectPermissionsWrapper(
      /*objectPermissionsMap,*/
      fieldPermissionsMapList,
      ManageUserAccessPartner.checkSObjType(objName),
      ManageUserAccess.checkDependency(objName),
      recordTypeDetails,
      muteId
    );
  }

  @AuraEnabled(cacheable=true)
    //used
  public static Boolean checkDuplicatePermissionSet(
    String label,
    String apiName
  ) {
    List<PermissionSet> existingSets = [
      SELECT Id
      FROM PermissionSet
      WHERE Label = :label OR Name = :apiName
    ];
    return existingSets.size() > 0;
  }

  @AuraEnabled(cacheable=true)
    //used
  public static Boolean checkDuplicatePermissionSetGroup(
    String label,
    String apiName
  ) {
    List<PermissionSetGroup> existingSets = [
      SELECT Id
      FROM PermissionSetGroup
      WHERE MasterLabel = :label OR DeveloperName = :apiName
    ];
    return existingSets.size() > 0;
  }
    
    @AuraEnabled
    //used
	public static List<PermissionSetAssignment> getUserProfilePerSet(String profpersetId) {
        return [SELECT Id, AssigneeId, Assignee.Name, Assignee.IsActive, Assignee.Profile.UserLicense.Name,Assignee.Username FROM PermissionSetAssignment WHERE PermissionSetId = :profpersetId 
                       AND Assignee.IsActive = true order by Assignee.Name asc]; 
    }

    
    
    
    
    //SYSTEM PERMISSION FOR PERMISSION SET
  public class CombinedPermissionWrapper {
    //@AuraEnabled public map<string,string> systemPermissions{get;set;}
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public String fieldLabel;
    @AuraEnabled
    public Object fieldValue;
    public CombinedPermissionWrapper(){}
    public CombinedPermissionWrapper(
      String fieldName,
      String fieldLabel,
      Object fieldValue
    ) {
      this.fieldName = fieldName;
      this.fieldLabel = fieldLabel;
      this.fieldValue = fieldValue;
    }
  }
    
Public Class UserPermissionsWrapper{
        @AuraEnabled Public List<CombinedPermissionWrapper> combinedWrapper {get;set;}
        @AuraEnabled Public List<Object> permDependency {get;set;}
        Public UserPermissionsWrapper(List<CombinedPermissionWrapper> combinedWrapper,List<Object> permDependency ){
            this.combinedWrapper = combinedWrapper;
            this.permDependency = permDependency;
        }
    }
@AuraEnabled(cacheable=true)
public static UserPermissionsWrapper getCombinedPermissionsForUser(List<String> permissionSetIds) {
    system.debug('Permission Set Ids ==> ' + permissionSetIds);
    List<CombinedPermissionWrapper> permissionFields = new List<CombinedPermissionWrapper>();
    
    // Constructing the base query to get permissions from PermissionSet
    String baseQueryString = 'SELECT Id, Name';
    Map<String, Schema.SObjectField> baseFields = Schema.SObjectType.PermissionSet.fields.getMap();

    for (Schema.SObjectField field : baseFields.values()) {
        String fieldName = field.getDescribe().getName();
        if (fieldName.startsWith('Permissions') && fieldName != 'Permissionsetgroupid') {
            baseQueryString += ', ' + fieldName;
            String fieldLabel = field.getDescribe().getLabel();
            permissionFields.add(new CombinedPermissionWrapper(fieldName, fieldLabel, null));
        }
    }

    // Query to get permission set data
    baseQueryString += ' FROM PermissionSet WHERE Id IN :permissionSetIds';
    List<PermissionSet> basePermissionSets = Database.query(baseQueryString);

    // To store the last value found for each permission (either true or false)
    Map<String, Boolean> finalPermissionValues = new Map<String, Boolean>();
    
    for (PermissionSet basePermissionSet : basePermissionSets) {
        for (CombinedPermissionWrapper wrapper : permissionFields) {
            String fieldName = wrapper.fieldName;
            Boolean fieldValue = (Boolean) basePermissionSet.get(fieldName); // Get permission value

            // Debugging field label and value
            system.debug('Field Label: ' + wrapper.fieldLabel + ', Field Value: ' + fieldValue);

            // If true is found, it should override false, but false should also be recorded
            if (!finalPermissionValues.containsKey(fieldName) || fieldValue == true) {
                finalPermissionValues.put(fieldName, fieldValue);
            }
        }
    }

    // Now create the final permission list based on finalPermissionValues map
    List<CombinedPermissionWrapper> combinedPermissions = new List<CombinedPermissionWrapper>();
    
    for (CombinedPermissionWrapper wrapper : permissionFields) {
        Boolean finalValue = finalPermissionValues.get(wrapper.fieldName);
        
        if (finalValue != null) {
            wrapper.fieldValue = finalValue;
            combinedPermissions.add(wrapper);
            
            // Debug final result
            system.debug(wrapper.fieldLabel + ' : ' + wrapper.fieldValue);
        }
    }

    system.debug('Combined Permissions: ' + combinedPermissions);
    return new UserPermissionsWrapper(combinedPermissions,getUserDependency());
}
@AuraEnabled
    //used
Public Static List<Object> getUserDependency(){
   ManageUserAccessPartner instance = new ManageUserAccessPartner();
   List<Object> records = new List<Object>();
    String baseUrl = URL.getOrgDomainUrl().toExternalForm();
    String toolingQuery = '/services/data/v58.0/tooling/query/?q=select+id,+RequiredPermission,+Permission+from+PermissionDependency+where+RequiredPermissionType=\'User%20Permission\'+and+PermissionType=\'User%20Permission\'';
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
     try{
         res = newReq.send(req);
         if (res.getStatusCode() == 200){
             Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(
                 res.getBody()
             );
             system.debug('results:::' + results);
             records = (List<Object>) results.get('records');
         }
         else {
            System.debug('Error: ' + res.getStatus());
            System.debug('Response: ' + res.getBody());
       }
         
     }
     catch (exception e) {
      System.debug('Exception: ' + e.getMessage());
    }
     return records;
 }
Public Class MuterUserPermWrapper{
     @AuraEnabled public String muteId {get;set;}
     @AuraEnabled Public List<Map<String,Object>> mutePermissions {get;set;}
    Public MuterUserPermWrapper(String muteId, List<Map<String,Object>> mutePermissions){
            this.muteId = muteId;
            this.mutePermissions = mutePermissions;
    }
 } 

@AuraEnabled
    //used
public static MuterUserPermWrapper getMuteUserPermission(String groupId, String fieldNames, List<Map<String,Object>> userPermissions) {
    String permSetId;
    List<Map<String,Object>> muterPermissions = new List<Map<String,Object>>();
    if (groupId != null) {
        system.debug('Inside Not Null');

        // Fetch PermissionSetGroupComponents
        List<PermissionSetGroupComponent> psgg = [
            SELECT Id, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel, PermissionSetId
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId = :groupId
            AND (NOT PermissionSet.Name LIKE '%_%')
        ];
        
        system.debug('Per Set Grp Com' + psgg);
        
        if (!psgg.isEmpty()) {
            system.debug('inside not null');
            permSetId = psgg[0].PermissionSetId;
        } else {
            system.debug('inside null');
            
            // Fetch the permission set group
            PermissionSetGroup permSetGrp = [
                SELECT Id, MasterLabel, DeveloperName
                FROM PermissionSetGroup
                WHERE Id = :groupId
                LIMIT 1
            ];

            if (permSetGrp != null) {
                // Create and insert a new MutingPermissionSet
                MutingPermissionSet mutePerm = new MutingPermissionSet();
                mutePerm.MasterLabel = permSetGrp.MasterLabel + ' Muted';
                mutePerm.DeveloperName = permSetGrp.DeveloperName + '_Muted';
                
                try {
                    insert mutePerm;
                    permSetId = mutePerm.Id;
                    
                    // Create and insert the PermissionSetGroupComponent
                    PermissionSetGroupComponent component = new PermissionSetGroupComponent(
                        PermissionSetGroupId = permSetGrp.Id,
                        PermissionSetId = permSetId
                    );
                    insert component;
                } catch (DmlException e) {
                    system.debug('Error inserting MutingPermissionSet or PermissionSetGroupComponent: ' + e.getMessage());
                   // return null; // Or handle it as needed
                }
            } else {
                system.debug('PermissionSetGroup not found for Id: ' + groupId);
            }
        }
        system.debug('check permSetId: ' + permSetId);
        if (permSetId != null && permSetId != '') {
            String query = 'SELECT Id, ' + fieldNames + ' FROM MutingPermissionSet WHERE Id = :permSetId LIMIT 1'; 
            system.debug('query'+query);
            MutingPermissionSet mutePerm = Database.query(query);
            if(mutePerm != null){
                system.debug('mutePerm'+ mutePerm);
                for(Map<String,Object> obj : userPermissions){
                    system.debug('obj'+obj);
					Object fieldValueMute = mutePerm.get((String) obj.get('fieldName'));
					obj.put('fieldValueMute', fieldValueMute);
                    muterPermissions.add(obj);                    
                }
            }
			
        }

    }
	
	return new MuterUserPermWrapper(permSetId,muterPermissions);
}
    
    @AuraEnabled(cacheable=false)
    //used
public static String createPermissionSetWithTabsAndUsers(
    Map<String, Object> permSetToCreate,
    String tabSettingsJson,
    List<Id> userids
) {
    system.debug('Method createPermissionSetWithTabsAndUsers Caaled');
    ManageUserAccess instance = new ManageUserAccess();
    String persetapi;
    List<MetadataService.PermissionSet> persetToInsert = new List<MetadataService.PermissionSet>();
    MetadataService.PermissionSet insertPerset = new MetadataService.PermissionSet();
    
    // Step 1: Create Permission Set
    insertPerset.fullName = ((String) permSetToCreate.get('Name')).replaceAll(' ', '_');
    insertPerset.label = (String) permSetToCreate.get('Label');
    insertPerset.description = (String) permSetToCreate.get('Description');
    insertPerset.license = (String) permSetToCreate.get('License');
    insertPerset.hasActivationRequired = (Boolean) permSetToCreate.get('hasActivationRequired');
    persetToInsert.add(insertPerset);

    if (!persetToInsert.isEmpty()) {
        try {
            MetadataService.UpsertResult[] results = (MetadataService.UpsertResult[]) instance.service.upsertMetadata(
                persetToInsert
            );

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
    }

    // Step 2: Add Tab Settings Logic Directly

    System.debug('tabSettingsJson: ' + tabSettingsJson);

    // Deserialize the JSON into a List of Maps
    List<Map<String, String>> rawList = (List<Map<String, String>>) JSON.deserialize(tabSettingsJson, List<Map<String, String>>.class);
    List<TabSettingsWrapper> tabSettings = new List<TabSettingsWrapper>();

    // Convert the raw list into TabSettingsWrapper list
    for (Map<String, String> item : rawList) {
        for (String tabName : item.keySet()) {
            String visibility = item.get(tabName);

            // Create the wrapper object
            TabSettingsWrapper wrapper = new TabSettingsWrapper();
            wrapper.tab = tabName;
            wrapper.visibility = visibility;

            tabSettings.add(wrapper);
        }
    }

    System.debug('tabSettings: ' + tabSettings);

    // Retrieve the PermissionSet metadata
    List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
        'PermissionSet',
        new List<String>{ persetapi }
    ).getRecords();

    MetadataService.PermissionSet permissionSet;
    if (permissionSets.size() > 0) {
        permissionSet = permissionSets[0];

        if (permissionSet.tabSettings == null) {
            permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();
        }

        // Collect tabs to remove
        Set<String> tabsToRemove = new Set<String>();

        // Update existing tab settings and collect tabs to remove
        for (TabSettingsWrapper tabSettingWrapper : tabSettings) {
            String tabName = tabSettingWrapper.tab;
            String visibility = tabSettingWrapper.visibility;

            if (visibility == null) {
                tabsToRemove.add(tabName);
            } else {
                Boolean tabFound = false;
                for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
                    if (existingTabSetting.tab == tabName) {
                        existingTabSetting.visibility = visibility;
                        tabFound = true;
                        break;
                    }
                }

                // Add new tab setting if not found
                if (!tabFound) {
                    MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                    newTabSetting.tab = tabName;
                    newTabSetting.visibility = visibility;
                    permissionSet.tabSettings.add(newTabSetting);
                }
            }
        }

        // Remove tabs with null visibility
        List<MetadataService.PermissionSetTabSetting> updatedTabSettings = new List<MetadataService.PermissionSetTabSetting>();
        for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
            if (!tabsToRemove.contains(existingTabSetting.tab)) {
                updatedTabSettings.add(existingTabSetting);
            }
        }
        permissionSet.tabSettings = updatedTabSettings;
    } else {
        permissionSet = new MetadataService.PermissionSet();
        permissionSet.fullName = persetapi;
        permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();

        for (TabSettingsWrapper tabSettingWrapper : tabSettings) {
            if (tabSettingWrapper.visibility != null) {
                MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                newTabSetting.tab = tabSettingWrapper.tab;
                newTabSetting.visibility = tabSettingWrapper.visibility;
                permissionSet.tabSettings.add(newTabSetting);
            }
        }
    }

    // Update the PermissionSet metadata with tab settings
    MetadataService.SaveResult[] updateResults = instance.service.updateMetadata(
        new List<MetadataService.Metadata>{ permissionSet }
    );

    for (MetadataService.SaveResult result : updateResults) {
        System.debug('Update Result id: ' + result.fullName);
        System.debug('Status: ' + result.success);
        if (!result.success) {
            for (MetadataService.Error error : result.errors) {
                System.debug('Error: ' + error.message);
            }
        }
    }

    // Step 3: Query the inserted Permission Set
    PermissionSet persetId = [
        SELECT Id, Name
        FROM PermissionSet
        WHERE Name = :persetapi
        LIMIT 1
    ];
	system.debug('persetId'+persetId);
    // Step 4: Assign Users to the Permission Set
    List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
    for (Id userId : userids) {
        PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
        permSetAssignment.AssigneeId = userId;
        permSetAssignment.PermissionSetId = persetId.Id;
        permSetAssignments.add(permSetAssignment);
    }

    try {
        insert permSetAssignments;
        System.debug('Permission set assignments successfully created.');
    } catch (DmlException e) {
        System.debug('Error occurred while assigning permission set: ' + e.getMessage());
        throw new AuraHandledException('Error occurred while assigning permission set: ' + e.getMessage());
    }

    return persetId.Id;
}
   
}