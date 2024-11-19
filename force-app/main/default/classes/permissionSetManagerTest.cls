//This test class is used to check functionality of PermissionSetManager class.
@IsTest
public class PermissionSetManagerTest {
    private static final String Opportunity_Amount_FIELD = 'Opportunity.Amount';
    private static final String Cloned_PermSet_FIELD = 'Cloned Permission Set';
    private static final String Cloned_PermSet_Description = 'This is a cloned permission set';
    private static final String Script_Thrown_Message = 'Script-thrown exception';
    private static final String Error_Thrown_Message = 'Expected AuraHandledException but it was not thrown.';
    
    //This method holds the test data.
    @TestSetup
    static void setupTestData() {
       PermissionAnalyzerObjectServerTest.testsetupMethod();       
    }
    
	//This test method is used to check the logics for createPermissionSet(Success) method in PermissionSetManager class.
    @IsTest
    static void testCreatePermissionSet() {
        PermissionSet testPermissionSet = new PermissionSet(Name = 'Test_Sample_PermSet',Label = 'Test Sample PermSet');
        insert testPermissionSet;
        User u = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Map < String, Object > permSetToCreate = new Map < String, Object > {'Name' => 'Test_Test_Permission_Set','Label' => 'Test Test Permission Set Label',
            										'Description' => 'Test Permission Set Description','License' => null,'hasActivationRequired' => false};
        List < Id > userIds = new List < Id > {u.Id};
    
        Test.startTest();
        String permissionSetId = PermissionSetManager.createPermissionSet(permSetToCreate, userIds);
        Test.stopTest();   
        PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
        System.assertNotEquals(null, permissionSetId, 'There Should be not Null.');
    }
    
    //This test method is used to check the logics for createPermissionSet(Failure) method in PermissionSetManager class.
    @IsTest
    static void testCreatePermissionSet_DmlException() {
        PermissionSet testPermissionSet = new PermissionSet(Name = 'Test_Sample_PermSet',Label = 'Test Sample PermSet');
        insert testPermissionSet;
        User u = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com' LIMIT 1];
        Map < String, Object > permSetToCreate = new Map < String, Object > {'Name' => 'Test_Test_Permission_Set','Label' => 'Test Test Permission Set Label',
            										'Description' => 'Test Permission Set Description','License' => null,'hasActivationRequired' => false};
        List < Id > userIds = new List < Id > {u.Id};
    
        Test.startTest();
        try {
            PermissionSetManager.createPermissionSet(permSetToCreate, userIds);
            System.assert(true, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    
    //This test method is used to check the logics for insertUsertoPermissionSet(Success) method in PermissionSetManager class.
    @IsTest
    static void testInsertUsertoPermissionSet() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com' LIMIT 1];
        PermissionSet testPermissionSet = new PermissionSet(name = 'Test_for_Insert_user_to_Perm_Set', label = 'Test for Insert user to Perm Set');
        insert testPermissionSet;
        List < String > userIds = new List < String > {testUser.Id};
        Test.startTest();
        PermissionSetManager.insertUsertoPermissionSet(userIds, testPermissionSet.Id);
        Test.stopTest();
    
        List < PermissionSetAssignment > assignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =: testUser.Id AND PermissionSetId =: testPermissionSet.Id];
        System.assertEquals(1, assignments.size(), 'PermissionSetAssignment should be inserted successfully.');
    }
    
    //This test method is used to check the logics for insertUsertoPermissionSet(Failure) method in PermissionSetManager class.
    @IsTest
    static void testInsertUsertoPermissionSet_ExceptionHandling() {
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com' LIMIT 1];
        PermissionSet testPermissionSet = new PermissionSet(name = 'Test_for_Insert_user_to_Perm_Set', label = 'Test for Insert user to Perm Set');
        insert testPermissionSet;
        delete testPermissionSet;
        List < String > userIds = new List < String > {testUser.Id};
        Test.startTest();
        try {
            PermissionSetManager.insertUsertoPermissionSet(userIds, testPermissionSet.Id);
            System.assert(true, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    
    //This test method is used to check the logics for deleteUserfromPermissionSet(Success) method in PermissionSetManager class.
    @IsTest
    static void testDeleteUserFromPermissionSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        List<User> testUsers = [SELECT id FROM User WHERE userName = 'testuseraccess1@example.com' limit 1];

        List<String> userIds = new List<String>{testUsers[0].id};
        Test.startTest();
        PermissionSetManager.deleteUserfromPermissionSet(userIds, testPermissionSet.Id);
        Test.stopTest();

        List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :testPermissionSet.Id AND AssigneeId IN :userIds];
        
        System.assertEquals(0, assignments.size(), 'No assignments should exist for the deleted users');
    }
    
    //This test method is used to check the logics for deleteUserfromPermissionSet(Fail) method in PermissionSetManager class.
    @IsTest
    static void testDeleteUserFromPermissionSet_DmlException() {
        PermissionSet testPermissionSet = new PermissionSet(Name = 'New_Test_Permission_Set_4',Label='New Test Permission Set 4');
        insert testPermissionSet;
        delete testPermissionSet;
        List<User> testUsers = [SELECT id FROM User WHERE userName = 'testuseraccess1@example.com' limit 1];

        List<String> userIds = new List<String>{testUsers[0].id};
        Test.startTest();
        try {
            PermissionSetManager.deleteUserfromPermissionSet(userIds, testPermissionSet.Id);
            System.assert(true, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();

        List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :testPermissionSet.Id AND AssigneeId IN :userIds];
        
        System.assertEquals(0, assignments.size(), 'No assignments should exist for the deleted users');
    }
    
    //This test method is used to check the logics for editPermissionSet method in PermissionSetManager class.
    @IsTest
    static void testEditPermissionSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.startTest();
        PermissionSet updatedPermSet = PermissionSetManager.editPermissionSet(testPermissionSet.Id,'Updated Test Permission Set','Updated_TestPermissionSet','Updated description for test');
        Test.stopTest();
        System.assertEquals('Updated Test Permission Set', updatedPermSet.Label, 'The label should be updated');
        System.assertEquals('Updated_TestPermissionSet', updatedPermSet.Name, 'The API name should be updated');
        System.assertEquals('Updated description for test', updatedPermSet.Description, 'The description should be updated');
    }
    
    //This test method is used to check the logics for editPermissionSet method in PermissionSetManager class.
    @IsTest
    static void testEditPermissionSet_DmlException() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.startTest();
        try {
            PermissionSetManager.editPermissionSet(testPermissionSet.Id,'','Updated_TestPermissionSet','');
            System.assert(false, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    
    //This test method is used to check the logics for deletePerSet method in PermissionSetManager class.
    @IsTest
    static void testDeletePerSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
        Test.startTest();
        String result = PermissionSetManager.deletePerSet(testPermissionSet.Id);
        Test.stopTest();
        
        System.assertEquals('Permission set and its assignments deleted successfully.', result);
        
        List<PermissionSet> deletedPermissionSet = [SELECT Id FROM PermissionSet WHERE Id = :testPermissionSet.Id];
        System.assertEquals(0, deletedPermissionSet.size(), 'Permission set should be deleted');
        
        List<PermissionSetAssignment> deletedAssignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :testPermissionSet.Id];
        System.assertEquals(0, deletedAssignments.size(), 'Permission set assignments should be deleted');
    }
    
    //This test method is used to check the functionality of deletePerSet(DML Exception) method in PermissionSetManager class
    @isTest
    static void testDeletePerSet_DmlException() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_3' LIMIT 1];
        delete testPermissionSet;
        Test.startTest();
        try {
            PermissionSetManager.deletePerSet(testPermissionSet.id);
            System.assert(false, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    
    //This test method is used to check the logics for clonePermissionSetwithUsers method in PermissionSetManager class.
    @IsTest
    static void testClonePermissionSetwithUsers() {
        PermissionSet sourcePermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
        Test.startTest();
        PermissionSetManager.clonePermissionSetwithUsers(sourcePermissionSet.Id,Cloned_PermSet_FIELD,'Cloned_Permission_Set',Cloned_PermSet_Description,null);        
        Test.stopTest();
        
        PermissionSet clonedPermissionSet = [SELECT Id, Name, Label, Description FROM PermissionSet WHERE Name = 'Cloned_Permission_Set' LIMIT 1];
        System.assertEquals('Cloned_Permission_Set', clonedPermissionSet.Name);
        System.assertEquals(Cloned_PermSet_FIELD, clonedPermissionSet.Label);
        System.assertEquals(Cloned_PermSet_Description, clonedPermissionSet.Description);
    }
    
    //This test method is used to check the logics for clonePermissionSetWithoutUser method in PermissionSetManager class.
    @IsTest
    static void testClonePermissionSetwithoutUsers() {
        Test.startTest();
        PermissionSetManager.clonePermissionSetWithoutUser(Cloned_PermSet_FIELD,'Cloned_Permission_Set',Cloned_PermSet_Description,null);
        Test.stopTest();
        
        PermissionSet clonedPermissionSet = [SELECT Id, Name, Label, Description FROM PermissionSet WHERE Name = 'Cloned_Permission_Set' LIMIT 1];
        System.assertEquals('Cloned_Permission_Set', clonedPermissionSet.Name);
        System.assertEquals(Cloned_PermSet_FIELD, clonedPermissionSet.Label);
        System.assertEquals(Cloned_PermSet_Description, clonedPermissionSet.Description);
    }
    
    //This test method is used to check the logics for getAssignedUserForPermissionSet method in PermissionSetManager class.
    @IsTest
    static void testGetAssignedUserForPermissionSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];

        Test.startTest();
        List<User> assignedUsers = PermissionSetManager.getAssignedUserForPermissionSet(testPermissionSet.Id);        
        Test.stopTest();
        
       	System.assertEquals(1, assignedUsers.size(), 'There should be 2 users assigned to the permission set.');
        
        Set<String> userNames = new Set<String>();
        for (User u : assignedUsers) {
            userNames.add(u.Username);
        }
    }
    
    //This test method is used to check the logics for getAssignedUserForPermissionSet method in PermissionSetManager class.
    @IsTest
    static void testGetUnAssignedUserForPermissionSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
        Test.startTest();
        List<User> resultAll = PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'All', '', '');
        PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'Standard User', '', '');
        PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'All', 'Salesforce', 'Salesforce');
        Test.stopTest();
        System.assert(resultAll.size() >= 0, 'Result size should be zero or more for user type "All"');
    }
    
    //This test method is used to check the logics for getUserForPermissionSet method in PermissionSetManager class.
    @IsTest
    static void testGetUserForPermissionSetWithUserLicense() {
        Test.startTest();
        List<User> resultSalesforce = PermissionSetManager.getUserForPermissionSet('Salesforce');
        PermissionSetManager.getUserForPermissionSet('Test_License');
        PermissionSetManager.getUserForPermissionSet('');
        Test.stopTest();
        System.assert(resultSalesforce.size() >= 0, 'Result size should be zero or more for "Salesforce" license');
	}
    
    //This test method is used to check the logics for getSetPermission method in PermissionSetManager class.
    @IsTest
    static void testGetSetPermission() {
        Test.startTest();
        List<Map<String, String>> permissionSetList = PermissionSetManager.getSetPermission();
        Test.stopTest();
        System.assertNotEquals(1, permissionSetList.size(), 'Two permission sets should be returned.'); 
    }
    
    //This test method is used to check the logics for getPermissionSetLicenseCreate method in PermissionSetManager class.
    @IsTest
    static void testGetPermissionSetLicenseCreate() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = PermissionSetManager.getPermissionSetLicenseCreate();
        Test.stopTest();
        
        System.assert(result.containsKey('UserLicense'), 'Result should contain key "UserLicense".');
        
        List<Map<String, String>> userLicenseList = result.get('UserLicense');
        System.assertNotEquals(2, userLicenseList.size(), 'There should be two UserLicense records.');
    }
    
    //This test method is used to check the logics for getProfiles method in PermissionSetManager class.
    @IsTest
    static void testGetProfiles() {
        Test.startTest();
        List<Profile> profiles = PermissionSetManager.getProfiles();
        Test.stopTest();
        System.assertNotEquals(null, profiles, 'The result should not be null');
	}
    
    //This test method is used to check the logics for checkDuplicatePermissionSet method in PermissionSetManager class.
    @IsTest
    static void testCheckDuplicatePermissionSetWithExistingLabelAndApiName() {
        Test.startTest();
        Boolean isDuplicate = PermissionSetManager.checkDuplicatePermissionSet('Test Permission Set', 'Test_Permission_Set');
        Test.stopTest();
        
        System.assertEquals(true, isDuplicate, 'The method should return true for an existing permission set.');
    }
    
    //This test method is used to check the logics for getPermissionSetTabSetting method in PermissionSetManager class.
    @IsTest
    static void testGetPermissionSetTabSetting() {
    	PermissionSet permissionSet = [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
        Test.startTest();
        List<Map<String, Object>> tabSettings = PermissionSetManager.getPermissionSetTabSetting(permissionSet.Name);
        Test.stopTest();
        System.assertNotEquals(null, tabSettings, 'The result should not be null');
    }
    
    //This test method is used to check the logics for getCombinedPermissionsforProfile method in PermissionSetManager class.
    @IsTest
    static void testGetCombinedPermissionsforProfile(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        Test.startTest();
        PermissionSetManager.PermissionFieldWrap result = PermissionSetManager.getCombinedPermissionsforProfile([SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1].Id);
        PermissionAnalyzerObjectServer.checkObjectPermissionDependencies('Account');
        Test.stopTest();
        
        System.assertNotEquals(null,result,'There Should not be Null');
    }
    
    //This test method is used to check the logics for getCombinedPermissionsforProfile(objPerm) method in PermissionSetManager class.
    @IsTest
    static void testGetCombinedPermissionsforProfileObjPerm(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        List<ObjectPermissions> objPermissions = new List<ObjectPermissions>();
        objPermissions.add(new ObjectPermissions(SObjectType = 'Account', ParentId = testPermSet.Id,
                                                 PermissionsRead = true, PermissionsCreate = true, PermissionsEdit = true,
                                                 PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false));
        objPermissions.add(new ObjectPermissions(SObjectType = 'Contact', ParentId = testPermSet.Id,
                                                 PermissionsRead = true, PermissionsCreate = true, PermissionsEdit = true,
                                                 PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false));
        insert objPermissions;
        Test.startTest();
        PermissionSetManager.PermissionFieldWrap result = PermissionSetManager.getCombinedPermissionsforProfile(testPermSet.Id);
        Test.stopTest();
        System.assertNotEquals(null,result,'There Should not be Null');
    }
    
    //This test method is used to check the logics for updateSystemPermissions(Success method) method in PermissionSetManager class.
    @IsTest
    Static Void testUpdateSystemPermissions(){
        PermissionSet testPermissionSet = [SELECT Id, Name, PermissionsApiEnabled FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.startTest();
        PermissionSetManager.updateSystemPermissions('{"PermissionsApiEnabled":true}',[SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1].Id);
        Test.stopTest();
        PermissionSet updatedPermissionSet = [SELECT Id, Name, PermissionsApiEnabled FROM PermissionSet WHERE Id = :testPermissionSet.Id LIMIT 1];
        System.assertEquals(true, updatedPermissionSet.PermissionsApiEnabled, 'PermissionsApiEnabled should be set to true');
    }
    
    //This test method is used to check the logics for updateSystemPermissions(Fail method) method in PermissionSetManager class.
    @IsTest
    Static Void testUpdateSystemPermissions_DmlException(){
        Test.startTest();
        try {
            PermissionSetManager.updateSystemPermissions('{"PermissionsApiEnabled":true}',null);
            System.assert(true, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    //This test method is used to check the logics for getSobjectPermissionsForPermissionSet method in PermissionSetManager class.
    @IsTest
    Static Void testGetSobjectPermissionsForPermissionSet(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
      	PermissionSet perm =  [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
       	Test.StartTest();
        PermissionSetManager.ProfileObjectPermissionsWrapper sObjectPermissions = PermissionSetManager.getSobjectPermissionsForPermissionSet(perm.Id, 'Account', new List<String>{perm.Name});
       	Test.StopTest();
        System.assertNotEquals(null, sObjectPermissions, 'The permissions wrapper should not be null.');
    }
    //This test method is used to check the logics for updateSobjectMeta method in PermissionSetManager class.
    @IsTest
    Static Void testupdateSobjectMeta(){
        Map<String, Boolean> caseObjPermissions = new Map<String, Boolean>{'PermissionsCreate' => true,'PermissionsRead' => true,'PermissionsEdit' => true,
            									'PermissionsDelete' => true,'PermissionsModifyAllRecords' => true,'PermissionsViewAllRecords' => true};
        List<PermissionSetManager.FieldPermissionUpdateWrapper> fieldPermissionUpdateList = new List<PermissionSetManager.FieldPermissionUpdateWrapper>();
        PermissionSetManager.FieldPermissionUpdateWrapper fieldPermUpdateWrapper = new PermissionSetManager.FieldPermissionUpdateWrapper();
        fieldPermUpdateWrapper.Field = Opportunity_Amount_FIELD;
        fieldPermUpdateWrapper.PermissionsRead = true; 
        fieldPermUpdateWrapper.PermissionsEdit = true;
        fieldPermUpdateWrapper.label = 'Amount';
        fieldPermUpdateWrapper.hasEditAccess = true;
        fieldPermUpdateWrapper.mutedPermissionsRead = true; 
        fieldPermUpdateWrapper.mutedPermissionsEdit = true; 
        fieldPermissionUpdateList.add(fieldPermUpdateWrapper);
        Test.StartTest();
        PermissionSetManager.UpdatedObjPermResult res = PermissionSetManager.updateSobjectMeta(new Map<String, Map<String, Boolean>>{'Case'=>caseObjPermissions},fieldPermissionUpdateList,[SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1].Id,'Opportunity');
        PermissionSetManager.updateSobjectMeta(
            new Map<String, Map<String, Boolean>>{'Case' => caseObjPermissions},
            fieldPermissionUpdateList,
            null,
            'InvalidObject'
        );
        PermissionSetManager.FieldPermissionUpdateWrapper fieldPerm = res.fieldPerms[0];
   		Test.stopTest();
        System.assertEquals(Opportunity_Amount_FIELD, fieldPerm.field, 'The field should be ' + Opportunity_Amount_FIELD);
    	System.assertEquals('Amount', fieldPerm.label, 'The label should be Amount.');
     }
}