@IsTest
public class PermissionSetGroupManagerTest {
    
    @TestSetup
    Static Void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales' LIMIT 1];
        
        User testUser1 = new User(FirstName = 'Newone',LastName = 'User1',Email = 'testuserOne@example.com',Username = 'testuserOne@example.com',Alias = 'TU1',
            						TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            							LanguageLocaleKey = 'en_US',IsActive = true);
        insert testUser1;
        
        User testUser2 = new User(FirstName = 'Newtwo',LastName = 'User2',Email = 'testuser2@example.com',Username = 'testuser2@example.com',Alias = 'TU1',
            						TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            							LanguageLocaleKey = 'en_US',IsActive = true);
        insert testUser2;  
        
        PermissionSet permSet = new PermissionSet(Name = 'New_Test_Permission_Set_One',Label = 'New Test Permission Set One',Description = 'Permission Set for Testing');
        insert permSet;
        
        PermissionSet permSettwo = new PermissionSet(Name = 'New_Test_Permission_Set_Two',Label = 'New Test Permission Set Two',Description = 'Permission Set for Testing');
        insert permSettwo;
        
        PermissionSetAssignment permSetAssignment = new PermissionSetAssignment(AssigneeId = testUser1.Id,PermissionSetId = permSet.Id);
        insert permSetAssignment;
        
        ObjectPermissions objPerm1= new ObjectPermissions(SObjectType = 'Contact',ParentId = permSet.Id,PermissionsRead = true,PermissionsCreate = false,
            				PermissionsEdit = true,PermissionsDelete = false,PermissionsViewAllRecords = false,PermissionsModifyAllRecords = false);
        insert objPerm1;
        
        ObjectPermissions obj2Perm1= new ObjectPermissions(SObjectType = 'Contact',ParentId = permSettwo.Id,PermissionsRead = true,PermissionsCreate = false,
            				PermissionsEdit = true,PermissionsDelete = false,PermissionsViewAllRecords = false,PermissionsModifyAllRecords = false);
        insert obj2Perm1;
        
        FieldPermissions field2Perm2 = new FieldPermissions(SObjectType = 'Account',ParentId = permSettwo.Id,Field = 'Account.Description',PermissionsRead = true,
            							PermissionsEdit = true);
        insert field2Perm2;
        
        FieldPermissions fieldPerm1 = new FieldPermissions(SObjectType = 'Contact',ParentId = permSet.Id,Field = 'Contact.Email',PermissionsRead = true,
            						PermissionsEdit = false);
        insert fieldPerm1;
        
        ObjectPermissions objPerm2 = new ObjectPermissions(SObjectType = 'Account',ParentId = permSet.Id,PermissionsRead = true,PermissionsCreate = true,PermissionsEdit = false,
            						PermissionsDelete = false,PermissionsViewAllRecords = false,PermissionsModifyAllRecords = false);
        insert objPerm2;
        
        FieldPermissions fieldPerm2 = new FieldPermissions(SObjectType = 'Account',ParentId = permSet.Id,Field = 'Account.Description',PermissionsRead = true,
            							PermissionsEdit = true);
        insert fieldPerm2;
        
        PermissionSetGroup permSetGroup = new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_One',MasterLabel = 'New Test Permission Set Group One',Description = 'This is a test permission set group.');
        insert permSetGroup;
        
        PermissionSetGroup permSetGrouptwo = new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_Two',MasterLabel = 'New Test Permission Set Group Two',Description = 'This is a test permission set group.');
        insert permSetGrouptwo;
        
        PermissionSetGroupComponent psgComponent = new PermissionSetGroupComponent(PermissionSetGroupId = permSetGroup.Id,PermissionSetId = permSettwo.Id);
        
        PermissionSetAssignment permSetGrpAssignment = new PermissionSetAssignment(AssigneeId = testUser1.Id,PermissionSetGroupId  = permSetGroup.Id);
        insert permSetGrpAssignment;
        
        MutingPermissionSet mutingPermissionSet = new MutingPermissionSet(
            MasterLabel = 'Muted Permission Set',
            DeveloperName = 'Muted_Permission_Set'
        );
        insert mutingPermissionSet;
        
        ObjectPermissions objectPermissionsmute = new ObjectPermissions(
            SobjectType = 'Opportunity',
            PermissionsCreate = true,
            PermissionsEdit = true,
            PermissionsDelete = true,
            PermissionsViewAllRecords = true,
            PermissionsModifyAllRecords = true,
            PermissionsRead = true,
            ParentId = mutingPermissionSet.Id
        );
        insert objectPermissionsmute;
        
        // Create Field Permissions for the Account object
        FieldPermissions accountFieldPermissions = new FieldPermissions(
            SObjectType = 'Opportunity',
            Field = 'Opportunity.Amount',
            PermissionsRead = true,
            PermissionsEdit = false,
            ParentId = mutingPermissionSet.Id
        );
        insert accountFieldPermissions;

        // Associate the Muting Permission Set with the Permission Set Group
        PermissionSetGroupComponent mutingComponent = new PermissionSetGroupComponent(
            PermissionSetId = mutingPermissionSet.Id,
            PermissionSetGroupId = permSetGrouptwo.Id
        );
        insert mutingComponent;
    }
    
    @IsTest
    Static Void testGetPermissionSetGrp() {
     	Test.startTest();
        List<PermissionSetGroupManager.permissionSetGroupWrapper> result = PermissionSetGroupManager.getPermissionSetGrp();
        Test.stopTest();   
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
     @IsTest
    static void testCreatePermissionSetGroupSuccess() {
        PermissionSet perSet = [Select id from PermissionSet where Name='New_Test_Permission_Set_Two' Limit 1];
        
        List<String> permissionSetIds = new List<String>{ perSet.id};

        Test.startTest();
        // Call the method being tested
        PermissionSetGroupManager.createPermissionSetGroup('New Test Permission Set Group Three', 'New_Test_Permission_Set_Group_Three', 'Test Description', permissionSetIds, true);
        Test.stopTest();

        // Step 2: Verify that the PermissionSetGroup was created
        PermissionSetGroup createdGroup = [SELECT Id, MasterLabel, DeveloperName, Description, HasActivationRequired FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_Three'];
        System.assertNotEquals(null, createdGroup, 'The PermissionSetGroup should be created');
        System.assertEquals('New Test Permission Set Group Three', createdGroup.MasterLabel, 'Group label mismatch');
        System.assertEquals('New_Test_Permission_Set_Group_Three', createdGroup.DeveloperName, 'Group API name mismatch');
        System.assertEquals('Test Description', createdGroup.Description, 'Group description mismatch');
        System.assertEquals(true, createdGroup.HasActivationRequired, 'Activation requirement mismatch');
    }
    
     @IsTest
    Static Void testCreatePermissionSetGroup_DmlException() {
        Test.startTest();
        try {
            PermissionSetGroupManager.createPermissionSetGroup('New Test Permission Set Group Two', 'New_Test_Permission_Set_Group_Two', 'Test Description', null, true);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
     @IsTest
    static void testEditPermissionSetGroupSuccessGroup() {
        
        PermissionSetGroup perSetGrp = [Select id from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' limit 1];

        Test.startTest();
        // Call the method being tested
        PermissionSetGroup updatedGroup = PermissionSetGroupManager.editPermissionSetGrp(perSetGrp.Id, 'New Test Permission Set Group Four', 'New_Test_Permission_Set_Group_Four', 'Updated Description', 'group');
        Test.stopTest();

        // Step 2: Verify that the PermissionSetGroup was updated
        PermissionSetGroup fetchedGroup = [SELECT MasterLabel, DeveloperName, Description FROM PermissionSetGroup WHERE Id = :perSetGrp.Id];
        System.assertEquals('New Test Permission Set Group Four', fetchedGroup.MasterLabel, 'The MasterLabel was not updated correctly');
        System.assertEquals('New_Test_Permission_Set_Group_Four', fetchedGroup.DeveloperName, 'The DeveloperName was not updated correctly');
        System.assertEquals('Updated Description', fetchedGroup.Description, 'The Description was not updated correctly');
    }
    
    @IsTest
    static void testEditPermissionSetGroupSuccessSet() {
        
        PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Group_One' limit 1];

        Test.startTest();
        // Call the method being tested
        PermissionSetGroup updatedGroup = PermissionSetGroupManager.editPermissionSetGrp(perSet.Id, 'New Test Permission Set Group Four', 'New_Test_Permission_Set_Group_Four', 'Updated Description', 'permission set');
        Test.stopTest();

        // Step 2: Verify that the PermissionSetGroup was updated
        PermissionSetGroup fetchedGroup = [SELECT MasterLabel, DeveloperName, Description FROM PermissionSetGroup WHERE Id = :perSet.PermissionSetGroupId];
        System.assertEquals('New Test Permission Set Group Four', fetchedGroup.MasterLabel, 'The MasterLabel was not updated correctly');
        System.assertEquals('New_Test_Permission_Set_Group_Four', fetchedGroup.DeveloperName, 'The DeveloperName was not updated correctly');
        System.assertEquals('Updated Description', fetchedGroup.Description, 'The Description was not updated correctly');
    }
    
    @IsTest
    static void testEditPermissionSetGroupErrorSet() {
        
      PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Two' limit 1];

      Test.startTest();
        try {
            PermissionSetGroup updatedGroup = PermissionSetGroupManager.editPermissionSetGrp(perSet.Id, 'New Test Permission Set Group Four', 'New_Test_Permission_Set_Group_Four', 'Updated Description', 'permission set');
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEditPermissionSetGroupNoFormat() {
        
      PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Two' limit 1];

      Test.startTest();
        try {
            PermissionSetGroup updatedGroup = PermissionSetGroupManager.editPermissionSetGrp(perSet.Id, 'New Test Permission Set Group One', 'New_Test_Permission_Set_Group_One', 'Updated Description', '');
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testClonePermissionSetGroup() {
        PermissionSetGroup perSetGrp = [Select id,DeveloperName,MasterLabel from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];
        
        PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Two' limit 1];
        
        PermissionSetGroupComponent psgComponent = new PermissionSetGroupComponent(PermissionSetGroupId = perSetGrp.Id,PermissionSetId = perSet.Id);
        insert psgComponent;
        
        Test.startTest();
        try{
        	PermissionSetGroupManager.clonePermissionSetGroup(perSetGrp.MasterLabel,'NewPermissionSetGroup','NewPermissionSetGroup','New Permission Set Group Description'); 
            System.assert(false, 'Expected AuraHandledException not thrown.');
        }catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();

        PermissionSetGroup newPsg = [SELECT Id, MasterLabel, DeveloperName, Description FROM PermissionSetGroup WHERE MasterLabel = 'NewPermissionSetGroup' LIMIT 1];
        System.assertNotEquals(null, newPsg, 'New Permission Set Group should be created');
        System.assertEquals('NewPermissionSetGroup', newPsg.DeveloperName, 'DeveloperName should match the provided API name');
        System.assertEquals('New Permission Set Group Description', newPsg.Description, 'Description should match the provided description');

        // Verify the Permission Set Group Components were cloned
        List<PermissionSetGroupComponent> newComponents = [SELECT PermissionSetId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :newPsg.Id];
        System.assertEquals(1, newComponents.size(), 'There should be one Permission Set Group Components in the new Permission Set Group');

    }
    
    @IsTest
    static void testClonePermissionSetGroupDMLException() {
        PermissionSetGroup perSetGrp = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        Test.startTest();
        try {
            PermissionSetGroupManager.clonePermissionSetGroup(perSetGrp.DeveloperName,'NewPermissionSetGroup','NewPermissionSetGroup','New Permission Set Group Description'); 
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testDeletePermissionSetGroupWithUnassignments() {
        // Retrieve the Permission Set Group created in the test setup
        PermissionSetGroup perSetGrp = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];
        
        PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Two' limit 1];
        
        PermissionSetGroupComponent psgComponent = new PermissionSetGroupComponent(PermissionSetGroupId = perSetGrp.Id,PermissionSetId = perSet.Id);
        insert psgComponent;

        Test.startTest();
        
        // Call the method to delete the Permission Set Group
        PermissionSetGroupManager.deletePermissionSetGroupWithUnassignments(perSetGrp.Id);
        
        Test.stopTest();

        // Verify the Permission Set Assignments were deleted
        List<PermissionSetAssignment> remainingAssignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId = :perSetGrp.Id];
        System.assertEquals(0, remainingAssignments.size(), 'All Permission Set Assignments should be deleted.');

        // Verify the Permission Set Group Components were deleted
        List<PermissionSetGroupComponent> remainingComponents = [SELECT Id FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :perSetGrp.Id];
        System.assertEquals(0, remainingComponents.size(), 'All Permission Set Group Components should be deleted.');

        // Verify the Permission Set Group was deleted
        List<PermissionSetGroup> remainingGroups = [SELECT Id FROM PermissionSetGroup WHERE Id = :perSetGrp.Id];
        System.assertEquals(0, remainingGroups.size(), 'The Permission Set Group should be deleted.');
    }
    
    @IsTest
    static void testGetUserPermissionSetGroup_Filters() {
        // Get Permission Set Group
        PermissionSetGroup perSetGrp = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        Test.startTest();
        List<User> userList = PermissionSetGroupManager.getUserPermissionSetGroup('HCH Sales', null, perSetGrp.Id);
        
        Test.stopTest();

        // Verify the user list returned matches expectations
        System.assertEquals(2, userList.size(), 'There should be 2 user returned with the profile filter.');
        System.assertEquals('testuser2@example.com', userList[1].Username, 'The returned user should be Test User2.');
    }
    
     @IsTest
    static void testGetUserPermissionSetGroup_AllFilters() {
        // Get Permission Set Group
        PermissionSetGroup perSetGrp = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        Test.startTest();
        List<User> userList = PermissionSetGroupManager.getUserPermissionSetGroup('HCH Sales', 'All', perSetGrp.Id);
        
        Test.stopTest();

        // Verify the user list returned matches expectations
        System.assertEquals(2, userList.size(), 'There should be 2 user returned with the profile filter.');
        System.assertEquals('testuser2@example.com', userList[1].Username, 'The returned user should be Test User2.');
    }
    
    @isTest
    static void testGetPermissionGroup_Success() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User where Email = 'testuser2@example.com' LIMIT 1];
        PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        // Collect User Ids
        List<String> userIds = new List<String>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }

        // Test the method with valid data
        Test.startTest();
        PermissionSetGroupManager.getPermissionGroup(userIds, testPermissionSetGroup.Id);
        Test.stopTest();

        // Verify that the Permission Set Assignments were created
        List<PermissionSetAssignment> assignments = [SELECT Id, AssigneeId, PermissionSetGroupId FROM PermissionSetAssignment WHERE PermissionSetGroupId = :testPermissionSetGroup.Id];
        System.assertEquals(2, assignments.size(), 'Three users should have been assigned to the Permission Set Group');
    }
    
     @isTest
    static void testGetPermissionGroup_DmlException() {
        // Get test data
        List<User> testUsers = [SELECT Id FROM User where Email = 'testuser2@example.com' LIMIT 1];
        PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        // Collect User Ids
        List<String> userIds = new List<String>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }

        // Create a Permission Set Assignment to force a DmlException (Duplicate Assignment)
        PermissionSetAssignment existingAssignment = new PermissionSetAssignment(AssigneeId = testUsers[0].Id,PermissionSetGroupId = testPermissionSetGroup.Id);
        insert existingAssignment;

        // Test the method, which should throw an exception due to the duplicate
        Test.startTest();
        try {
            PermissionSetGroupManager.getPermissionGroup(userIds, testPermissionSetGroup.Id);
            System.assert(false, 'A DmlException should have been thrown');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
     @isTest
    static void testGetPermissionSetGroup() {
        // Get the Permission Set Group ID
        PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        // Test the method
        Test.startTest();
        List<User> assignedUsers = PermissionSetGroupManager.getPermissionSetGroup(testPermissionSetGroup.Id);
        Test.stopTest();

        // Verify that the correct number of users are returned
        System.assertEquals(1, assignedUsers.size(), 'There should be one users assigned to the Permission Set Group');
        
        // Verify that each user has expected fields populated
        for (User user : assignedUsers) {
            System.assertNotEquals(null, user.Id, 'User Id should not be null');
            System.assertNotEquals(null, user.Name, 'User Name should not be null');
            System.assertNotEquals(null, user.Username, 'User Username should not be null');
            System.assertNotEquals(null, user.Profile.Name, 'Profile Name should not be null');
            System.assertNotEquals(null, user.Profile.UserLicense.Name, 'User License Name should not be null');
        }
    }
    
    @isTest
    static void testDeletePermissionGroup_Success() {
        // Get test data
       	List<User> testUsers = [SELECT Id FROM User where Email = 'testuserOne@example.com' LIMIT 1];
        PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];

        // Collect User Ids
        List<String> userIds = new List<String>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }

        // Test the delete method
        Test.startTest();
        PermissionSetGroupManager.deletePermissionGroup(userIds, testPermissionSetGroup.Id);
        Test.stopTest();

        // Verify that the Permission Set Assignments have been deleted
        List<PermissionSetAssignment> remainingAssignments = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId = :testPermissionSetGroup.Id];
        System.assertEquals(0, remainingAssignments.size(), 'All user assignments should have been deleted');
    }
    
    @isTest
    static void testGetProfiles() {
        Test.startTest();
        List<Profile> profiles = PermissionSetGroupManager.getProfiles();
        Test.stopTest();

        // Verify the result
        System.assertNotEquals(0, profiles.size(), 'The profile list should not be empty');
    }
    
    @isTest
    static void testGetPermissionSet_WithoutSearchTerm() {
        // Get the test Permission Set Group ID
       PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];
        
       PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Two' limit 1];
        
       PermissionSetGroupComponent psgComponent = new PermissionSetGroupComponent(PermissionSetGroupId = testPermissionSetGroup.Id,PermissionSetId = perSet.Id);
       insert psgComponent;

        // Test the getPermissionSet method without search term
        Test.startTest();
        List<PermissionSet> permissionSets = PermissionSetGroupManager.getPermissionSet(testPermissionSetGroup.Id, '');
        Test.stopTest();

        // Verify the results
        System.assertNotEquals(0, permissionSets.size(), 'Permission sets should be returned');

        for (PermissionSet ps : permissionSets) {
            System.assertNotEquals(null, ps.Id, 'Permission Set Id should not be null');
        }
    }
    
    @isTest
    static void testInsertPermissionSet() {
        // Get the test Permission Set Group and Permission Sets
        PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];
        List<PermissionSet> testPermissionSets = [SELECT Id FROM PermissionSet where Name = 'New_Test_Permission_Set_Two' LIMIT 1];

        // Prepare the list of permission set IDs to be added to the group
        List<String> permissionSetIds = new List<String>();
        for (PermissionSet ps : testPermissionSets) {
            permissionSetIds.add(ps.Id);
        }

        // Test the insertPermissionSet method
        Test.startTest();
        PermissionSetGroupManager.insertPermissionSet(permissionSetIds, testPermissionSetGroup.Id);
        Test.stopTest();

        // Verify the results: check if the PermissionSetGroupComponents have been inserted
        List<PermissionSetGroupComponent> insertedComponents = [SELECT Id, PermissionSetId, PermissionSetGroupId FROM PermissionSetGroupComponent WHERE PermissionSetGroupId = :testPermissionSetGroup.Id];
        System.assertEquals(1, insertedComponents.size(), 'One Permission Set Group Components should be inserted');
        
        Set<Id> insertedPermissionSetIds = new Set<Id>();
        for (PermissionSetGroupComponent component : insertedComponents) {
            insertedPermissionSetIds.add(component.PermissionSetId);
        }

        // Verify that the inserted PermissionSetGroupComponents have the correct PermissionSet IDs
        for (String permissionSetId : permissionSetIds) {
            System.assert(insertedPermissionSetIds.contains(permissionSetId), 'Permission Set ID should be part of the inserted components');
        }
    }
    
     @isTest
    static void testDeletePermissionSet() {
        // Retrieve the test Permission Set Group and Permission Sets
        PermissionSetGroup testPermissionSetGroup = [Select id,DeveloperName from PermissionSetGroup where DeveloperName = 'New_Test_Permission_Set_Group_One' Limit 1];
        List<PermissionSet> testPermissionSets = [SELECT Id FROM PermissionSet where Name = 'New_Test_Permission_Set_Two' LIMIT 1];

        // Prepare the list of permission set IDs to be deleted
        List<String> permissionSetIds = new List<String>();
        for (PermissionSet ps : testPermissionSets) {
            permissionSetIds.add(ps.Id);
        }

        // Call the deletePermissionSet method
        Test.startTest();
        PermissionSetGroupManager.deletePermissionSet(permissionSetIds, testPermissionSetGroup.Id);
        Test.stopTest();

        // Verify that the PermissionSetGroupComponents were deleted
        List<PermissionSetGroupComponent> remainingComponents = [SELECT Id, PermissionSetId 
                                                                  FROM PermissionSetGroupComponent
                                                                  WHERE PermissionSetGroupId = :testPermissionSetGroup.Id];
        System.assertEquals(0, remainingComponents.size(), 'No Permission Set Group Component should remain after deletion');
    }
    
    @isTest
    static void testGetSetPermission() {
        // Call the method to test
        Test.startTest();
        List<Map<String, String>> permissionSetData = PermissionSetGroupManager.getSetPermission();
        Test.stopTest();

        // Assert the result
        System.assertNotEquals(0, permissionSetData.size(), 'The result list should not be empty.');

        for (Map<String, String> permissionSetMap : permissionSetData) {
            System.assertNotEquals(null, permissionSetMap.get('Id'), 'Permission Set Id should not be null.');
            System.assertNotEquals(null, permissionSetMap.get('Name'), 'Permission Set Name should not be null.');
            System.assertNotEquals(null, permissionSetMap.get('Label'), 'Permission Set Label should not be null.');
        }
    }
    
    @isTest
    static void testGetProfileDetails() {
        // Call the method to test
        Test.startTest();
        List<PermissionSet> permissionSets = PermissionSetGroupManager.getProfileDetails();
        Test.stopTest();

        // Assert that the result is not empty
        System.assertNotEquals(0, permissionSets.size(), 'The result list should not be empty.');

        // Assert that each permission set is owned by a profile and contains required fields
        for (PermissionSet ps : permissionSets) {
            System.assertNotEquals(null, ps.ProfileId, 'ProfileId should not be null.');
            System.assertNotEquals(null, ps.Profile.Name, 'Profile Name should not be null.');
        }
    }
    
	 @isTest
    static void testGetUnAssignedUserForPermissionSet() {
        PermissionSet perSet = [Select id from PermissionSet where Name='New_Test_Permission_Set_One' Limit 1];
        
        Test.startTest();
        List<User> unassignedUsers = PermissionSetGroupManager.getUnAssignedUserForPermissionSet(
            perSet.id, 'HCH Sales', 'Salesforce', 'Salesforce'
        );
        Test.stopTest();

        // Assert that the result contains the correct user
        System.assertEquals(2, unassignedUsers.size(), 'There should be two unassigned user.');
    }
    
     @isTest
    static void testCheckDuplicatePermissionSetGroup_LabelExists() {
        Test.startTest();
        Boolean isDuplicate = PermissionSetGroupManager.checkDuplicatePermissionSetGroup('New Test Permission Set Three', 'New_Test_Permission_Set_Threre');
        Test.stopTest();

        // Assert that a duplicate is found
        System.assertEquals(false, isDuplicate, 'The method should return false for an existing label.');
    }
    
    @isTest
    static void testGetAssignedPermissionSet() {
        // Retrieve the Permission Set Group Id created in the setup
        PermissionSetGroup testPermissionSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_One' LIMIT 1];
        
        PermissionSet perSet = [Select id,PermissionSetGroupId from PermissionSet where Name = 'New_Test_Permission_Set_Two' limit 1];
        
       PermissionSetGroupComponent psgComponent = new PermissionSetGroupComponent(PermissionSetGroupId = testPermissionSetGroup.Id,PermissionSetId = perSet.Id);
       insert psgComponent;

        // Test the getAssignedPermissionSet method
        Test.startTest();
        List<PermissionSet> assignedPermissionSets = PermissionSetGroupManager.getAssignedPermissionSet(testPermissionSetGroup.Id);
        Test.stopTest();

        // Assert that the returned Permission Set is as expected
        System.assertEquals(1, assignedPermissionSets.size(), 'There should be one assigned permission set.');
        System.assertEquals('New_Test_Permission_Set_Two', assignedPermissionSets[0].Name, 'The assigned permission set name should match.');
    }
    
    @isTest
    static void testGetMutedObjandFieldPermissions_ExistingGroup() {
        // Retrieve Permission Set Group created in the testSetup method
        PermissionSetGroup permSetGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_Two' LIMIT 1];

        List<String> objNames = new List<String>{'Account', 'Contact'};
        String objName = 'Opportunity';
        
        // Call the method and check the response
        Test.startTest();
        PermissionSetGroupManager.MutePermissionWrapper result = PermissionSetGroupManager.getMutedObjandFieldPermissions(permSetGroup.Id, objNames, objName);
        Test.stopTest();

        // Validate that the permission set group ID is returned correctly
        System.assertNotEquals(null, result.mutePermSetId);
        System.assertNotEquals(null, result.wrapper);
        System.assert(result.wrapper.objectPermissions.isEmpty(), 'Object permissions should be empty.');
        //System.assert(result.wrapper.fieldPermissions.isEmpty(), 'Field permissions should be empty.');
    }
	
    
    @isTest
    static void testGetSobjectPermissionsForPermissionSetGroup() {
        
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
           UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        // Retrieve the test PermissionSetGroup created in testSetup
        PermissionSetGroup psg = [SELECT Id,DeveloperName,MasterLabel FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_Two' LIMIT 1];
        String permSetId = psg.Id;
        
         PermissionSetGroup psgone = new PermissionSetGroup();
        psgone.DeveloperName = 'New_Test_Permission_Set_Group_Three';
        psgone.MasterLabel = 'New Test Permission Set Group Three';
        insert psgone;


        // Call the method being tested
        Test.startTest();
		PermissionSetGroupManager.PermissionSetGroupObjectPermissionsWrapper result = PermissionSetGroupManager.getSobjectPermissionsForPermissionSetGroup(
                permSetId, 'Account', psg.MasterLabel, psg.DeveloperName
            );
        Test.stopTest();
        
        
        List<Object> result1 = PermissionSetManager.checkDependency('Account');

    }

    
    @IsTest
    static void testGetSobjectWithValidPermId() {
        // Query test PermissionSetGroup
        PermissionSetGroup testGroup = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_One' LIMIT 1];
        
        // Call the method with a valid Permission Set Group Id
        PermissionSetGroupManager.PermissionSetGroupObjectDetails result = PermissionSetGroupManager.getSobject(testGroup.Id);
    }
    
    @isTest
    static void testUpdateFieldPermissions() {
        // Fetch the permission set created during the test setup
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_Group_One' LIMIT 1];

        // Create mock input data for the FieldPermissionUpdateWrapper
        List<PermissionSetGroupManager.FieldPermissionUpdateWrapper> fieldPermWrapperList = new List<PermissionSetGroupManager.FieldPermissionUpdateWrapper>();

        PermissionSetGroupManager.FieldPermissionUpdateWrapper wrapper1 = new PermissionSetGroupManager.FieldPermissionUpdateWrapper();
        wrapper1.Field = 'Opportunity.Account';
        wrapper1.PermissionsRead = true;
        wrapper1.PermissionsEdit = true;
        wrapper1.mutedPermissionsRead = false;
        wrapper1.mutedPermissionsEdit = false;
        fieldPermWrapperList.add(wrapper1);

        // Call the method to test
        Test.startTest();
        	try {
            List<PermissionSetGroupManager.FieldPermissionUpdateWrapper> updatedPermissions = PermissionSetGroupManager.updateFieldPermissions(
            fieldPermWrapperList,
            permSet.Id,
            'Account',
            'PermissionsRead' // or 'MutePermissions'
        );
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
        
    }

	@isTest
    static void testGetCombinedPermissions() {
      PermissionSetGroup psg = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_One' LIMIT 1];
        
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
           UserAccessManager manager = new UserAccessManager();
        // Set up the mock callout
       Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));
        
        Test.startTest();
        PermissionSetGroupManager.userObjAndFieldPermissionSetGroupWrapper result = 
            PermissionSetGroupManager.getCombinedPermissions(psg.Id, 'Account', 'Test_PSG');
        Test.stopTest();
    }
    
    @isTest
    static void testMutePermissionsWithValidPermissions() {
        // Setup
        Map<String, Map<String, Object>> systemPermissionsMap = new Map<String, Map<String, Object>>{
            '' => new Map<String, Object>{
                'ViewAllData' => true,
                'ModifyAllData' => false
            }
        };
        String systemPermissionsMapJson = JSON.serialize(systemPermissionsMap);
         PermissionSetGroup psg = [SELECT Id,DeveloperName,MasterLabel FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_Permission_Set_Group_Two' LIMIT 1];

        // Test
        Test.startTest();
        try {
        List<MutingPermissionSet> result = PermissionSetGroupManager.mutePermissions(systemPermissionsMapJson, psg.MasterLabel, psg.DeveloperName, psg.id);
            System.assert(false, 'Expected AuraHandledException not thrown.');
        }catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    


}