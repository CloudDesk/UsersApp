@IsTest
public class ManageCloneUserTest {
    
    static User testUser1;
    static User testUser2;
    static PermissionSet testPermissionSet;
    static PermissionSetGroup testPermissionSetGroup;
    static Group testPublicGroup;
    static Group testQueue;

    @TestSetup
    static void setupTestData() {
        // Create a User License
        UserLicense license = [SELECT Id FROM UserLicense LIMIT 1];
        
        // Create a Profile
        Profile profilewithMatchingLicense = [SELECT Id FROM Profile WHERE UserLicenseId = :license.Id LIMIT 1];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create Test User
        testUser1 = new User(
            FirstName = 'Sample',
            LastName = 'User123',
            Email = 'Sampleuser123@example.com',
            Username = 'Sampleuser123@example.com',
            Alias = 'testus',
            CommunityNickname = 'testuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profilewithMatchingLicense.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;
        
        testUser2 = new User(
            FirstName = 'Sample',
            LastName = 'User345',
            Email = 'SampleUser345@example.com',
            Username = 'SampleUser345@example.com',
            Alias = 'testus',
            CommunityNickname = 'sampleuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = profile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = True
        );
        insert testUser2;

        // Create Permission Set
        testPermissionSet = new PermissionSet(Name = 'TestPermissionSet1122', Label = 'Test Permission Set1122');
        insert testPermissionSet;
		// Assign Permission Set to User
        PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = testUser2.Id, PermissionSetId = testPermissionSet.Id);
        insert psa;
        // Create Permission Set Group
        testPermissionSetGroup = new PermissionSetGroup(MasterLabel = 'Test Permission Set Group1122', DeveloperName = 'TestPermissionSetGroup1122');
        insert testPermissionSetGroup;
        // Assign Permission Set Group to User
        PermissionSetAssignment psaGroup = new PermissionSetAssignment(AssigneeId = testUser2.Id, PermissionSetGroupId = testPermissionSetGroup.Id);
        insert psaGroup;
        // Create Public Group
        testPublicGroup = new Group(Name = 'Test Public Group', DeveloperName = 'TestPublicGroup', Type = 'Regular');
        insert testPublicGroup;
        // Create Queue
        testQueue = new Group(Name = 'Test Queue', DeveloperName = 'TestQueue', Type = 'Queue');
        insert testQueue;
        // Add User to Queue
        GroupMember queueMember = new GroupMember(GroupId = testQueue.Id, UserOrGroupId = testUser2.Id);
        insert queueMember;
    }

    @IsTest
    static void testGetUsers() {
        Test.startTest();
        List<User> users = ManageCloneUser.getUsers();
        System.assertNotEquals(1, users.size(),'users have same size');
        Test.stopTest();
    }

    @IsTest
    static void testGetUserAssignedGroups() {
        User testUser2 = [select id from user where Username = 'SampleUser345@example.com'];
        Test.startTest();
        Map<String, List<SObject>> result = ManageCloneUser.getUserAssignedGroups(testUser2.Id);
        System.assertNotEquals(1, result.size(),'users have same size');
        Test.stopTest();
    }

    @IsTest
    static void testAssignPermissionsAndGroups() {
        User testUser2 = [select id from user where Username = 'SampleUser345@example.com'];
        Group testPublicGroup = [select id from Group where Name ='Test Public Group'];
        Group testQueue = [select id from Group where Name ='Test Queue'];   
        
        //Insert test permission set
        permissionSet testExamplePermissionSet = new PermissionSet(Name = 'testExamplePermissionSet', Label = 'Test Example Permission');
        insert testExamplePermissionSet;
        
        Test.startTest();
        List<PermissionSetAssignment> existingAssignments = [
            SELECT Id, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :testUser2.Id 
            AND PermissionSetId = :testExamplePermissionSet.Id
        ];
        System.assertEquals(existingAssignments.size(), 0, 'No Assignment Created');
        ManageCloneUser.assignPermissionsAndGroups(
            testUser2.Id,
            new List<Id>{testExamplePermissionSet.Id},
            new List<Id>{testPublicGroup.Id},
            new List<Id>{testQueue.Id}
        );
        List<PermissionSetAssignment> newAssignments = [
            SELECT Id, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :testUser2.Id 
            AND PermissionSetId = :testExamplePermissionSet.Id
        ];
        System.assert(existingAssignments.size() < newAssignments.size(), true);
        System.assertEquals(newAssignments.size(), 1, 'New Assignment Created');
        Test.stopTest();
    }

     @IsTest
    static void testUserActivationActivate() {
        User testUser2 = [select id from user where Username = 'SampleUser345@example.com'];
        Test.startTest();
        User updatedUser = ManageCloneUser.userActivation(testUser2.Id, true);
        Test.stopTest();

        // Assert the user is active
        System.assertEquals(true, updatedUser.IsActive, 'User should be activated');
    }

    @IsTest
    static void testGetPermissionSetsByUserLicense() {
        User testUser2 = [select id from user where Username = 'SampleUser345@example.com'];
        Test.startTest();
        ManageCloneUser.PermissionSetWrapper wrapper = ManageCloneUser.getPermissionSetsByUserLicense(testUser2.Id);
        System.assertNotEquals(0, wrapper.permissionSets.size(), 'Should return zero unassigned regular permission set');
        System.assertNotEquals(0, wrapper.permissionSetGroups.size(), 'Should return zero unassigned permission set group');
        System.assertNotEquals(0, wrapper.publicGroupQueue.size(), 'Should return zero unassigned group or queue');
        Test.stopTest();
    }

    @IsTest
    static void testGetAssignedAssignment() {
        User testUser2 = [select id from user where Username = 'SampleUser345@example.com'];
        Test.startTest();
        ManageCloneUser.PermissionSetWrapper wrapper = ManageCloneUser.getAssignedAssignment(testUser2.Id);
        Test.stopTest();
        System.assertEquals(0, wrapper.permissionSets.size(), 'Should return zero assigned regular permission set');
        System.assertEquals(1, wrapper.permissionSetGroups.size(), 'Should return one unassigned permission set group');
        System.assertEquals(1, wrapper.publicGroupQueue.size(), 'Should return one unassigned group or queue');
    }
    @IsTest
    static void testGetAllUsers() {
        Test.startTest();
        List<User> result = ManageCloneUser.getAllUsers();
        Test.stopTest();
        System.assert(result.size() > 2, 'Result should contain at least two users');
    }

    
}