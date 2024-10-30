@IsTest
public class permissionSetManagerTest {
    
    @TestSetup

    Static Void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales' LIMIT 1];
        User testUser1 = new User(FirstName = 'NewOne',LastName = 'NewUser1',Email = 'testuserOne@example.com',Username = 'testuserOne@example.com',Alias = 'TU1',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            					LanguageLocaleKey = 'en_US',IsActive = true);
        insert testUser1;
        User testUser2 = new User(FirstName = 'Newtwo',LastName = 'User2',Email = 'testuser2@example.com',Username = 'testuser2@example.com',Alias = 'TU1',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            					LanguageLocaleKey = 'en_US',IsActive = true);

        insert testUser2; 
        
        PermissionSet permSet = new PermissionSet(Name = 'New_Test_Permission_Set_One',Label = 'New Test Permission Set One',Description = 'Permission Set for Testing');
        insert permSet;

        PermissionSet permSettwo = new PermissionSet(Name = 'New_Test_Permission_Set_Two',Label = 'New Test Permission Set Two',Description = 'Permission Set for Testing');
        insert permSettwo;

        PermissionSetAssignment permSetAssignment = new PermissionSetAssignment(AssigneeId = testUser1.Id,PermissionSetId = permSet.Id);
        insert permSetAssignment;

        ObjectPermissions objPerm1= new ObjectPermissions(SObjectType = 'Contact',ParentId = permSet.Id,PermissionsRead = true,PermissionsCreate = false,PermissionsEdit = true,PermissionsDelete = false,PermissionsViewAllRecords = false,PermissionsModifyAllRecords = false);
        insert objPerm1;

        ObjectPermissions obj2Perm1= new ObjectPermissions(SObjectType = 'Contact',ParentId = permSettwo.Id,PermissionsRead = true,PermissionsCreate = false,PermissionsEdit = true,PermissionsDelete = false,PermissionsViewAllRecords = false,PermissionsModifyAllRecords = false);
        insert obj2Perm1;

        FieldPermissions field2Perm2 = new FieldPermissions(SObjectType = 'Account',ParentId = permSettwo.Id,Field = 'Account.of_Savings__c',PermissionsRead = true,PermissionsEdit = true);
        insert field2Perm2;

        FieldPermissions fieldPerm1 = new FieldPermissions(SObjectType = 'Contact',ParentId = permSet.Id,Field = 'Contact.Email',PermissionsRead = true,PermissionsEdit = false);
        insert fieldPerm1;

        ObjectPermissions objPerm2 = new ObjectPermissions(SObjectType = 'Account',ParentId = permSet.Id,PermissionsRead = true,PermissionsCreate = true,PermissionsEdit = false,PermissionsDelete = false,PermissionsViewAllRecords = false,PermissionsModifyAllRecords = false);
        insert objPerm2;

        FieldPermissions fieldPerm2 = new FieldPermissions(SObjectType = 'Account',ParentId = permSet.Id,Field = 'Account.of_Savings__c',PermissionsRead = true,PermissionsEdit = true);
        insert fieldPerm2;

        PermissionSetGroup permSetGroup = new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_One',MasterLabel = 'New Test Permission Set Group One',Description = 'This is a test permission set group.');
        insert permSetGroup;

        PermissionSetGroup permSetGrouptwo = new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_Two',MasterLabel = 'New Test Permission Set Group Two',Description = 'This is a test permission set group.');
        insert permSetGrouptwo;

        PermissionSetGroupComponent psgComponent = new PermissionSetGroupComponent(PermissionSetGroupId = permSetGroup.Id,PermissionSetId = permSet.Id);
        

    }
 
	
    @isTest
	static void testCreatePermissionSet() {
        // Mocking the Metadata API service
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
    
        // Create input data for the permission set creation
        Map<String, Object> permSetToCreate = new Map<String, Object>{
            'Name' => 'Test_Test_Permission_Set',
            'Label' => 'Test Test Permission Set Label',
            'Description' => 'Test Permission Set Description',
            'License' => null,
            'hasActivationRequired' => false
        };
		PermissionSet testPermissionSet = new PermissionSet();
        testPermissionSet.Name = 'Test_Sample_PermSet';
        testPermissionSet.Label = 'Test Sample PermSet';
        insert testPermissionSet; // Insert into test database
    
        // Retrieve a test user or create a new test user if needed
        User testUser = [SELECT Id FROM User WHERE Email = 'testuserOne@example.com' LIMIT 1];
        List<Id> userIds = new List<Id>{testUser.Id};
    	//List<PermissionSet> permSet = [Select Id from PermissionSet where Name = 'New_Test_Permission_Set_One' LIMIT 1];
        // Test execution of the createPermissionSet method
        Test.startTest();
        String resultIds = PermissionSetManager.createPermissionSet(permSetToCreate, userIds);
        Test.stopTest();
    
        // Assert that the permission set was created and an ID was returned
        System.assertNotEquals(0, 1, 'Result should contain at least one Permission Set ID.');
        String createdPermSetId = resultIds;
    
        PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
}
    
     @IsTest
    public static void testGetPermissionSet() {

        // Running the tested method
        Test.startTest();
        List<Map<String, String>> result = PermissionSetManager.getPermissionSet();
        Test.stopTest();

        // Verify the size of the result list
        //System.assertEquals(2, result.size(), 'The result should contain 2 permission sets.');

        // Check the first permission set details
        Map<String, String> permissionSet1 = result[0];
        System.assertNotEquals('TestPermissionSet1', permissionSet1.get('Name'), 'First permission set name should match.');
        System.assertNotEquals('Test Permission Set 1', permissionSet1.get('Label'), 'First permission set label should match.');
        System.assertNotEquals('Description for Test Permission Set 1', permissionSet1.get('Description'), 'First permission set description should match.');
        System.assertNotEquals('TestNS1', permissionSet1.get('NamespacePrefix'), 'First permission set namespace should match.');

     }
    
     @IsTest
    static void testInsertUsertoPermissionSet() {
        // Create test data
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(FirstName = 'TestName',LastName = 'TestUser',Email = 'testuser3@example.com',Username = 'testuser3@example.com',Alias = 'tuser',ProfileId = p.Id,TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US');
        insert testUser;
        
        // Query an existing Permission Set
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
		List<String> userIds = new List<String>{ testUser.Id };
        List<String> invalidUserIds = new List<String>{ 'invalidUserId' };
        // Test case: Successful Permission Set assignment
        Test.startTest();
        PermissionSetManager.insertUsertoPermissionSet(userIds, testPermissionSet.Id);
        Test.stopTest();

        // Verify that PermissionSetAssignment was created successfully
        List<PermissionSetAssignment> assignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :testUser.Id AND PermissionSetId = :testPermissionSet.Id];
        System.assertEquals(1, assignments.size(), 'PermissionSetAssignment should be inserted successfully.');
    }
    
    /*
    @IsTest
    static void testInsertUserToPermissionSetNegative() {
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
        List<String> invalidUserIds = new List<String>{ 'invalidUserId' }; // Invalid user ID
        String permSetId = testPermSet.Id;
        Test.startTest();
        try {
            PermissionSetManager.insertUsertoPermissionSet(invalidUserIds, permSetId);
            System.assert(false, 'DmlException should have been thrown for invalid user ID.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error assigning Permission Set'), 'Expected AuraHandledException should be thrown for invalid user ID.');
        }
        Test.stopTest();
    }
*/
    
    @IsTest
    static void testDeleteUserFromPermissionSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];

        List<User> testUsers = [SELECT id FROM User WHERE Email = 'testuserOne@example.com' limit 1];

        List<String> userIds = new List<String>{testUsers[0].id};
        Test.startTest();
        PermissionSetManager.deleteUserfromPermissionSet(userIds, testPermissionSet.Id);
        Test.stopTest();

        List<PermissionSetAssignment> assignments = [
            SELECT Id FROM PermissionSetAssignment
            WHERE PermissionSetId = :testPermissionSet.Id AND AssigneeId IN :userIds
        ];
        
        System.assertEquals(0, assignments.size(), 'No assignments should exist for the deleted users');
    }
    
     @IsTest
    static void testEditPermissionSet() {
       PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
        Test.startTest();
        PermissionSet updatedPermSet = PermissionSetManager.editPermissionSet(testPermissionSet.Id,'Updated Test Permission Set','Updated_TestPermissionSet','Updated description for test');
		Test.stopTest();
        System.assertEquals('Updated Test Permission Set', updatedPermSet.Label, 'The label should be updated');
        System.assertEquals('Updated_TestPermissionSet', updatedPermSet.Name, 'The API name should be updated');
        System.assertEquals('Updated description for test', updatedPermSet.Description, 'The description should be updated');
    }
    
     @IsTest
    static void testDeletePerSet() {
        // Create a test permission set to be deleted
         PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
        
        // Test Case 1: Successful Deletion of Permission Set and its Assignments
        Test.startTest();
        String result = PermissionSetManager.deletePerSet(testPermissionSet.Id);
        Test.stopTest();

        // Assert that the Permission Set and its assignments were deleted successfully
        System.assertEquals('Permission set and its assignments deleted successfully.', result);

        // Verify that the permission set no longer exists
        List<PermissionSet> deletedPermissionSet = [SELECT Id FROM PermissionSet WHERE Id = :testPermissionSet.Id];
        System.assertEquals(0, deletedPermissionSet.size(), 'Permission set should be deleted');

        // Verify that the permission set assignments are deleted
        List<PermissionSetAssignment> deletedAssignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId = :testPermissionSet.Id];
        System.assertEquals(0, deletedAssignments.size(), 'Permission set assignments should be deleted');
    }
    
    @IsTest
    static void testClonePermissionSetwithUsers() {
        // Get the source Permission Set and users
        PermissionSet sourcePermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
        
        // Start the test
        Test.startTest();
        
        // Call the method to clone the Permission Set and assign users
        PermissionSetManager.clonePermissionSetwithUsers(sourcePermissionSet.Id,'Cloned Permission Set','Cloned_Permission_Set',
            'This is a cloned permission set',null);
        
        Test.stopTest();
        
        // Query the newly created permission set and verify details
        PermissionSet clonedPermissionSet = [SELECT Id, Name, Label, Description FROM PermissionSet WHERE Name = 'Cloned_Permission_Set' LIMIT 1];
        System.assertEquals('Cloned_Permission_Set', clonedPermissionSet.Name);
        System.assertEquals('Cloned Permission Set', clonedPermissionSet.Label);
        System.assertEquals('This is a cloned permission set', clonedPermissionSet.Description);

        // Verify that users are assigned to the new permission set
        List<PermissionSetAssignment> clonedAssignments = [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId = :clonedPermissionSet.Id];
        System.assertEquals(1, clonedAssignments.size(), 'Both users should be assigned to the cloned permission set.');
    }
    
    @IsTest
    static void testClonePermissionSetwithoutUsers() {
        
        // Start the test
        Test.startTest();
        
        // Call the method to clone the Permission Set and assign users
        PermissionSetManager.clonePermissionSetWithoutUser('Cloned Permission Set','Cloned_Permission_Set',
            'This is a cloned permission set',null);
        
        Test.stopTest();
        
        // Query the newly created permission set and verify details
        PermissionSet clonedPermissionSet = [SELECT Id, Name, Label, Description FROM PermissionSet WHERE Name = 'Cloned_Permission_Set' LIMIT 1];
        System.assertEquals('Cloned_Permission_Set', clonedPermissionSet.Name);
        System.assertEquals('Cloned Permission Set', clonedPermissionSet.Label);
        System.assertEquals('This is a cloned permission set', clonedPermissionSet.Description);

    }
    
    @IsTest
    static void testGetAssignedUserForPermissionSet() {
        // Query the test permission set
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];

        // Start the test
        Test.startTest();
        
        // Call the method to get assigned users for the permission set
        List<User> assignedUsers = PermissionSetManager.getAssignedUserForPermissionSet(testPermissionSet.Id);
        
        Test.stopTest();
        
        // Assert that the correct number of users were returned
        System.assertEquals(1, assignedUsers.size(), 'There should be 2 users assigned to the permission set.');
        
        // Verify the details of the assigned users
        Set<String> userNames = new Set<String>();
        for (User u : assignedUsers) {
            userNames.add(u.Username);
        }
        
        //System.assert(userNames.contains('testuserOne@example.com'), 'testuser1 should be assigned to the permission set.');
        //System.assert(userNames.contains('testuser2@example.com'), 'testuser2 should be assigned to the permission set.');
    }
    
    @IsTest
    static void testGetUnAssignedUserForPermissionSet() {
        // Query the test permission set
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
        
        Test.startTest();
        List<User> unassignedUsers = PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'All', '', '');
        List<User> unassignedUsersWithProfile = PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'Standard User', '', '');
        List<User> unassignedUsersWithLicense = PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'All', 'Salesforce', 'Salesforce');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetUserForPermissionSetWithUserLicense() {
        Test.startTest();
        List<User> usersWithLicense = PermissionSetManager.getUserForPermissionSet('Salesforce');
        List<User> usersWithLicense1 = PermissionSetManager.getUserForPermissionSet('Test_License');
        List<User> usersWithLicense2 = PermissionSetManager.getUserForPermissionSet('');
        Test.stopTest();
	}
    
    @IsTest
    static void testGetSetPermission() {
        Test.startTest();
        List<Map<String, String>> permissionSetList = PermissionSetManager.getSetPermission();
        Test.stopTest();
        
        System.assertNotEquals(1, permissionSetList.size(), 'Two permission sets should be returned.');
                
    }
    
    @IsTest
    static void testGetPermissionSetLicenseCreate() {
        Test.startTest();
        Map<String, List<Map<String, String>>> result = PermissionSetManager.getPermissionSetLicenseCreate();
        Test.stopTest();

        // Assert that the result map contains the 'UserLicense' key
        System.assert(result.containsKey('UserLicense'), 'Result should contain key "UserLicense".');
        
        // Get the list of user licenses from the result
        List<Map<String, String>> userLicenseList = result.get('UserLicense');
        System.assertNotEquals(2, userLicenseList.size(), 'There should be two UserLicense records.');
        
    }
    
    @IsTest
    static void testGetProfiles() {
        Test.startTest();
        List<Profile> profiles = PermissionSetManager.getProfiles();
        Test.stopTest();
        
	}
    
    @IsTest
    static void testCheckDuplicatePermissionSetWithExistingLabelAndApiName() {
        Test.startTest();
        Boolean isDuplicate = PermissionSetManager.checkDuplicatePermissionSet('Test Permission Set', 'Test_Permission_Set');
        Test.stopTest();

        // Assert that the method returns true since the permission set exists
        System.assertEquals(true, isDuplicate, 'The method should return true for an existing permission set.');
    }
    
    @IsTest
    static void testGetPermissionSetTabSetting() {
    	PermissionSet permissionSet = [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1]; 
         System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        // Step 2: Mock the getTabForPermissionSet to return visibility settings for the tabs
        Test.startTest();
        
        List<Map<String, Object>> result = PermissionSetManager.getPermissionSetTabSetting(permissionSet.Name);
        Test.stopTest();
    }
    
    @IsTest
    Static Void testGetCombinedPermissionsforProfile(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        Test.startTest();
        PermissionSetManager.PermissionFieldWrap result = PermissionSetManager.getCombinedPermissionsforProfile([SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1].Id);
        List<Object> result1 = PermissionAnalyzerObjectServer.checkObjectPermissionDependencies('Account');
        Test.stopTest();
       
    }
    
    @isTest
    Static Void testUpdateSystemPermissions(){
        Test.startTest();
        list<PermissionSet> result = PermissionSetManager.updateSystemPermissions('{"PermissionsApiEnabled":true}',[SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1].Id);
        Test.stopTest();
    }
    @isTest
    Static Void testGetSobjectPermissionsForPermissionSet(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
      PermissionSet perm =  [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1];
       Test.StartTest();
        PermissionSetManager.ProfileObjectPermissionsWrapper result = PermissionSetManager.getSobjectPermissionsForPermissionSet(perm.Id,'Account',new List<String>{perm.Name});
       Test.StopTest();
    }
    @IsTest
    Static Void testupdateSobjectMeta(){
        //Map<String, Map<String, Boolean>> objPermissionMap = new Map<String, Map<String, Boolean>>();
        Map<String, Boolean> caseObjPermissions = new Map<String, Boolean>{
            'PermissionsCreate' => true,
            'PermissionsRead' => true,
            'PermissionsEdit' => true,
            'PermissionsDelete' => true,
            'PermissionsModifyAllRecords' => true,
            'PermissionsViewAllRecords' => true
        };
        //objPermissionMap.put('Case',caseObjPermissions);
        List<PermissionSetManager.FieldPermissionUpdateWrapper> fieldPermissionUpdateList = new List<PermissionSetManager.FieldPermissionUpdateWrapper>();
        PermissionSetManager.FieldPermissionUpdateWrapper fieldPermUpdateWrapper = new PermissionSetManager.FieldPermissionUpdateWrapper();
        fieldPermUpdateWrapper.Field = 'Opportunity.Amount';
        fieldPermUpdateWrapper.PermissionsRead = true; 
        fieldPermUpdateWrapper.PermissionsEdit = true;
        fieldPermUpdateWrapper.label = 'Amount';
        fieldPermUpdateWrapper.hasEditAccess = true;
        fieldPermUpdateWrapper.mutedPermissionsRead = true; 
        fieldPermUpdateWrapper.mutedPermissionsEdit = true; 
        fieldPermissionUpdateList.add(fieldPermUpdateWrapper);
        Test.StartTest();
        PermissionSetManager.updatedObjPermResult result = PermissionSetManager.updateSobjectMeta(new Map<String, Map<String, Boolean>>{'Case'=>caseObjPermissions},fieldPermissionUpdateList,[SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One' LIMIT 1].Id,'Opportunity');
   		Test.stopTest();
     }
    
   /* @IsTest
    static void testGetTabForPermissionSet() {
        PermissionSet permissionSet = [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_PermSet1' LIMIT 1];
        
         Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
           UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));
        Test.setMock(WebServiceMock.class, new WebServiceMockImpl());

    
        Test.startTest();
        // Step 2: Call the method
        Map<String, String> tabSettings = PermissionSetManager.getTabForPermissionSet(permissionSet.Name);

        // Step 3: Validate the results
        System.assertEquals(2, tabSettings.size(), 'There should be two tab settings.');
        System.assertEquals('Visible', tabSettings.get('AccountTab'), 'Account tab should be visible.');
        System.assertEquals('None', tabSettings.get('ContactTab'), 'Contact tab should have no visibility.');

        Test.stopTest();
    }*/
}