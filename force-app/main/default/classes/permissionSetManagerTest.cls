@IsTest
public class PermissionSetManagerTest {
    private static final String OPPORTUNITY_Amount_FIELD = 'Opportunity.Amount';
    @TestSetup
    static void setupTestData() {
       Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> userList = new List<User>();
        List<PermissionSet> permSets = new List<PermissionSet>();
        List<MutingPermissionSet> mutingPermSets = new List<MutingPermissionSet>();
        List<PermissionSetGroup> permSetGroups = new List<PermissionSetGroup>();
        
        for(Integer i = 1; i <= 3; i++){
            if(i <= 2){
                userList.add(new User(FirstName = 'Test'+i,LastName = 'User'+i,Email = 'testuser' + i + '@example.com',Username = 'testuseraccess' + i + '@example.com',Alias = 'TU1',
            						TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            							LanguageLocaleKey = 'en_US',IsActive = true));
                mutingPermSets.add(new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set '+i, DeveloperName = 'New_Test_MutePermSet_'+i));
            	permSetGroups.add(new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group '+i, DeveloperName = 'New_Test_PermSetGrp_'+i));
            }            
           	permSets.add(new permissionSet(Label = 'New Test Permission Set '+i, Name = 'New_Test_Permission_Set_'+i,PermissionsApiEnabled = true));
            
        }
        insert userList;     
        insert permSets;
        insert mutingPermSets;
        insert permSetGroups;
        
        List<PermissionSetGroupComponent> permSetGroupComponents = new List<PermissionSetGroupComponent>();
        for(Integer i = 1; i <= 4; i++)
        {
           String permSetGroupId;
           if (Math.mod(i, 2) == 1) { 
               permSetGroupId = permSetGroups[0].Id;
           }else{
               permSetGroupId = permSetGroups[1].Id;
           }
           String permSetId;
            if(i == 1){
                permSetId = permSets[1].Id;
            }else if(i == 2){
                 permSetId = permSets[2].Id;
            }else if(i == 3){
                 permSetId = mutingPermSets[0].Id;
            }else{
                permSetId = mutingPermSets[1].Id;
            }
           permSetGroupComponents.add(new PermissionSetGroupComponent(PermissionSetId = permSetId, PermissionSetGroupId = permSetGroupId));
        }
        insert permSetGroupComponents;
       List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        for(Integer i = 1; i <= 2; i++){
            String permSetId;
            if(i == 1){
                permSetId = permSets[1].Id;
            }else{
                permSetId = permSets[2].Id;
            }
            permSetAssignments.add(new PermissionSetAssignment(PermissionSetId = permSetId, AssigneeId = userList[0].Id));
        }
        insert permSetAssignments;
              
        List<ObjectPermissions> objPermissions = new List<ObjectPermissions>();
        for(Integer i = 1; i <= 4; i++)
        {
             String permSetId;
            Boolean permissionRead;
            if(i == 1){
                permSetId = permSets[1].Id;
                permissionRead = true;
            }else if(i == 2){
                 permSetId = permSets[2].Id;
                 permissionRead = true;
            }else if(i == 3){
                 permSetId = mutingPermSets[0].Id;
                 permissionRead = false;
            }else{
                permSetId = mutingPermSets[1].Id;
                permissionRead = false;
            }
            objPermissions.add(new ObjectPermissions(SObjectType = 'Opportunity', ParentId = permSetId,
                                PermissionsRead = permissionRead, PermissionsCreate = true, PermissionsEdit = false,
                                PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false));
        }
        insert objPermissions;
       
        List<FieldPermissions> fieldPermissions = new List<FieldPermissions>();
        for(Integer i = 1; i <= 4; i++)
        {
             String permSetId;
            if(i == 1){
                permSetId = permSets[1].Id;
            }else if(i == 2){
                 permSetId = permSets[2].Id;
            }else if(i == 3){
                 permSetId = mutingPermSets[0].Id;
            }else{
                permSetId = mutingPermSets[1].Id;
            }
            fieldPermissions.add(new FieldPermissions(SObjectType = 'Opportunity', Field = OPPORTUNITY_Amount_FIELD, ParentId = permSetId,
                                PermissionsRead = true, PermissionsEdit = false));
        }
        insert fieldPermissions;        
    }
 
	
    @isTest
    static void testCreatePermissionSet() {
        // Create test data
        PermissionSet testPermissionSet = new PermissionSet(Name = 'Test_Sample_PermSet',Label = 'Test Sample PermSet');
        insert testPermissionSet;
        User u = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com' LIMIT 1];
    
        // Mock external service
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
    
        // Prepare input data
        Map < String, Object > permSetToCreate = new Map < String, Object > {
            'Name' => 'Test_Test_Permission_Set',
            'Label' => 'Test Test Permission Set Label',
            'Description' => 'Test Permission Set Description',
            'License' => null,
            'hasActivationRequired' => false
        };
        List < Id > userIds = new List < Id > {u.Id};
    
        // Test the method
        Test.startTest();
        String permissionSetId = PermissionSetManager.createPermissionSet(permSetToCreate, userIds);
        Test.stopTest();
    
        // Verify results
        PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
    }
    
     @IsTest
    public static void testGetPermissionSet() {
        // Test the method
        Test.startTest();
        List < Map < String, String >> result = PermissionSetManager.getPermissionSet();
        Test.stopTest();
    
        // Verify results
        System.assertNotEquals(0, result.size(), 'The result should contain permission sets.');
    
        if (!result.isEmpty()) {
            Map < String, String > permissionSet1 = result[0];
            System.assertNotEquals(null, permissionSet1.get('Name'), 'Permission set name should not be null.');
            System.assertNotEquals(null, permissionSet1.get('Label'), 'Permission set label should not be null.');
        }
    }
    
    @IsTest
    static void testInsertUsertoPermissionSet() {
        // Create test data
        User testUser = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com' LIMIT 1];
        // Query an existing Permission Set
        PermissionSet testPermissionSet = new PermissionSet(name = 'Test_for_Insert_user_to_Perm_Set', label = 'Test for Insert user to Perm Set');
        insert testPermissionSet;
        List < String > userIds = new List < String > {testUser.Id};
        Test.startTest();
        PermissionSetManager.insertUsertoPermissionSet(userIds, testPermissionSet.Id);
        Test.stopTest();
    
        // Verify that PermissionSetAssignment was created successfully
        List < PermissionSetAssignment > assignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId =: testUser.Id AND PermissionSetId =: testPermissionSet.Id];
        System.assertEquals(1, assignments.size(), 'PermissionSetAssignment should be inserted successfully.');
    }
    
    @IsTest
    static void testDeleteUserFromPermissionSet() {
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];

        List<User> testUsers = [SELECT id FROM User WHERE userName = 'testuseraccess1@example.com' limit 1];

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
       PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
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
         PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
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
        PermissionSet sourcePermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
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
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];

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
    }
    
    @IsTest
    static void testGetUnAssignedUserForPermissionSet() {
        // Query the test permission set
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
        Test.startTest();
        PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'All', '', '');
        PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'Standard User', '', '');
        PermissionSetManager.getUnAssignedUserForPermissionSet(testPermissionSet.Id, 'All', 'Salesforce', 'Salesforce');
        Test.stopTest();
    }
    
    @IsTest
    static void testGetUserForPermissionSetWithUserLicense() {
        Test.startTest();
        PermissionSetManager.getUserForPermissionSet('Salesforce');
        PermissionSetManager.getUserForPermissionSet('Test_License');
        PermissionSetManager.getUserForPermissionSet('');
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
        PermissionSetManager.getProfiles();
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
    	PermissionSet permissionSet = [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1]; 
         System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        // Step 2: Mock the getTabForPermissionSet to return visibility settings for the tabs
        Test.startTest();
        
        PermissionSetManager.getPermissionSetTabSetting(permissionSet.Name);
        Test.stopTest();
    }
    
    @IsTest
    Static Void testGetCombinedPermissionsforProfile(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        Test.startTest();
        PermissionSetManager.PermissionFieldWrap result = PermissionSetManager.getCombinedPermissionsforProfile([SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1].Id);
        PermissionAnalyzerObjectServer.checkObjectPermissionDependencies('Account');
        Test.stopTest();
       
    }
    
    @isTest
    Static Void testUpdateSystemPermissions(){
        Test.startTest();
        PermissionSetManager.updateSystemPermissions('{"PermissionsApiEnabled":true}',[SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1].Id);
        Test.stopTest();
    }
    @isTest
    Static Void testGetSobjectPermissionsForPermissionSet(){
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
      PermissionSet perm =  [SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
       Test.StartTest();
        PermissionSetManager.getSobjectPermissionsForPermissionSet(perm.Id,'Account',new List<String>{perm.Name});
       Test.StopTest();
    }
    @IsTest
    Static Void testupdateSobjectMeta(){
        Map<String, Boolean> caseObjPermissions = new Map<String, Boolean>{
            'PermissionsCreate' => true,
            'PermissionsRead' => true,
            'PermissionsEdit' => true,
            'PermissionsDelete' => true,
            'PermissionsModifyAllRecords' => true,
            'PermissionsViewAllRecords' => true
        };
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
        PermissionSetManager.updateSobjectMeta(new Map<String, Map<String, Boolean>>{'Case'=>caseObjPermissions},fieldPermissionUpdateList,[SELECT Id,Name FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1].Id,'Opportunity');
   		Test.stopTest();
     }
    
   
}