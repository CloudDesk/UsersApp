@IsTest
public class ProfileManagerTest {
	
    @TestSetup
    static void setupTestData() {
         Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales' LIMIT 1];
        
        PermissionSet testProfPer = [SELECT Id FROM PermissionSet WHERE ProfileId = :testProfile.Id LIMIT 1];
        
        ObjectPermissions objPerms = new ObjectPermissions(SObjectType = 'Opportunity', ParentId = testProfPer.Id, PermissionsRead = true,PermissionsCreate = true,
            PermissionsEdit = true,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false);
        insert objPerms;
        
        PermissionSet permSet = new PermissionSet();
        permSet.Label = 'New Test Permission Set';
        permSet.Name = 'New_Test_Permission_Set';
        permSet.PermissionsApiEnabled = true;
        insert permSet;
        
        PermissionSet permSet1 = new PermissionSet(Label = 'New Test Permission Set 1', Name = 'New_Test_PermSet1');
        PermissionSet permSet2 = new PermissionSet(Label = 'New Test Permission Set 2', Name = 'New_Test_PermSet2');
        insert new List<PermissionSet>{ permSet1, permSet2 };
            
             ObjectPermissions objectPermissions = new ObjectPermissions(
            SobjectType = 'Opportunity',
            PermissionsRead = true,
            PermissionsCreate = true,
            PermissionsEdit = true,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false,
            ParentId = permSet1.Id
        );
        insert objectPermissions;
        
         ObjectPermissions objectPermissionsone = new ObjectPermissions(
            SobjectType = 'Contact',
            PermissionsRead = true,
            PermissionsCreate = true,
            PermissionsEdit = true,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false,
            ParentId = permSet1.Id
        );
        insert objectPermissionsone;
        
         ObjectPermissions objectPermissionstwo = new ObjectPermissions(
            SobjectType = 'Account',
            PermissionsRead = true,
            PermissionsCreate = true,
            PermissionsEdit = true,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false,
            ParentId = permSet1.Id
        );
        insert objectPermissionstwo;

            FieldPermissions fieldPerm = new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Amount', ParentId = permSet1.Id, PermissionsRead = true);
        insert fieldPerm;
        
        FieldPermissions fieldPermOne = new FieldPermissions(SObjectType = 'Account', Field = 'Account.Description', ParentId = permSet1.Id, PermissionsRead = true);
        insert fieldPermOne;
       	
         FieldPermissions fieldPermtwo = new FieldPermissions(SObjectType = 'Account', Field = 'Account.Description', ParentId = permSet2.Id, PermissionsRead = true);
        insert fieldPermtwo;
        
        PermissionSetTabSetting tabSetting = new PermissionSetTabSetting(
            ParentId = permSet1.Id,
            Name = 'standard-Account',
            Visibility = 'DefaultOn'
        );
        insert tabSetting;
        
        User testUser1 = new User(
            FirstName = 'Test',
            LastName = 'UserOne',
            Email = 'testuserOne@example.com',
            Username = 'testuserOne@example.com',
            Alias = 'TU1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = testProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser1;
        
        User testUser2 = new User(
            FirstName = 'Test2',
            LastName = 'User2',
            Email = 'testuser2@example.com',
            Username = 'testuser2@example.com',
            Alias = 'TU1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = testProfile.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser2;
        
        PermissionSetGroup permSetGroup = new PermissionSetGroup(
            DeveloperName='New_Test_Permission_Set_Group_One',
            MasterLabel = 'New Test Permission Set Group',
            Description = 'Test Permission Set Group Description'
        );
        insert permSetGroup;
        
        PermissionSetGroup permSetGrouptwo = new PermissionSetGroup(
            DeveloperName='New_Test_Permission_Set_Group_Two',
            MasterLabel = 'New Test Permission Set Group Two',
            Description = 'Test Permission Set Group Description'
        );
        insert permSetGrouptwo;
        

        PermissionSetAssignment permSetAssign1 = new PermissionSetAssignment(PermissionSetId = permSet1.Id, AssigneeId = testUser1.Id);
        insert permSetAssign1;
		
        PermissionSetAssignment psa1 = new PermissionSetAssignment(AssigneeId = testUser1.Id,PermissionSetGroupId = permSetGrouptwo.Id);
        insert psa1;
        
        PermissionSetGroupComponent component1 = new PermissionSetGroupComponent(PermissionSetGroupId = permSetGrouptwo.Id,PermissionSetId = permSet1.Id);
        insert component1;
        

        
        FieldPermissions fieldPermissions = new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Address__c', ParentId = permSet2.Id, PermissionsRead = true);
        insert fieldPermissions;
        
        ObjectPermissions objPerm = new ObjectPermissions(SObjectType = 'Opportunity', ParentId = permSet2.Id, PermissionsRead = true);
        insert objPerm;

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
            Field = 'Opportunity.Address__c',
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
    static void testGetProfileName() {
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
           UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        
        Test.startTest();
        List<String> profileNames = ProfileManager.getProfileName(profileId);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('Standard User', profileNames[0], 'The profile name should match the expected value.');
    }
    
    @isTest
    static void testGetProfileUsers() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
         User testUser1 = new User(FirstName = 'sample',LastName = 'User1',Username = 'sampleuser1@test.com',Email = 'sampleuser1@test.com',Alias = 'sample1',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,LanguageLocaleKey = 'en_US',IsActive = true);
        User testUser2 = new User(FirstName = 'sample',LastName = 'User2',Username = 'sampleuser2@test.com',Email = 'sampleuser2@test.com',Alias = 'sample2',TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,LanguageLocaleKey = 'en_US',IsActive = true);
        insert testUser1;
        insert testUser2;
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
           UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));

        // Step 2: Call the Method
        Test.startTest();
        ProfileManager.UserAndProfileDetails result = ProfileManager.getProfileusers(testProfile.Id);
        Test.stopTest();

        // Step 3: Assertions
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(2, result.userList.size(), 'The userList should contain 2 users');
        //System.assertEquals(testProfile.Name, result.profileName, 'The profileName should match the test profile name');
    }
    
    @isTest
    static void testGetProfileDetails() {
        Test.startTest();
        List<PermissionSet> result = ProfileManager.getProfileDetails();
        Test.stopTest();

    }
    
    @IsTest
    static void testEditProfileProperties_Success() {
        Profile testProfile = [SELECT Id,Name FROM Profile WHERE Name = 'HCH Sales User' LIMIT 1];
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
 
        Test.startTest();
        // Call the method
        Map<String, String> result = ProfileManager.updateProfile(testProfile.Name, 'Updated_Profile', 'Updated Description');
 
        // Validate the response
        System.assertNotEquals(null, result, 'Result map should not be null.');
        //System.assertEquals('Updated_Profile', result.get('label'), 'Profile label should be updated.');
        //System.assertEquals('Updated Description', result.get('description'), 'Profile description should be updated.');
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteProfile() {
        Profile testProfile = [SELECT Id,Name FROM Profile WHERE Name = 'HCH Sales User' LIMIT 1];
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
 
        Test.startTest();
        // Call the method
        ProfileManager.deleteProfile('HCH Sales User');
        Test.stopTest();
    }
    
    @IsTest
    public static void updateSystemPermissionsProf_Test() {
        
        List<String> testProfiles = new List<String>{'Admin'};
        Map<String, Boolean> systemPermissions = new Map<String, Boolean>{
            'MockPermission1' => true,
            'MockPermission2' => true
        };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
        Test.startTest();     
        Map<String, Boolean> updatedResult = ProfileManager.updateSystemPermissionsProf('Test_Profile', systemPermissions);
        Test.stopTest();

        

        // Check that the Visibility field exists (but it might be null based on the mocked getTabPermissions)
        //System.assert(tabSetting1.containsKey('Visibility'), 'Expected Visibility key in tab settings');
    }
    
    @IsTest
    public static void testGetSobjectPermissionsForProfile() {
        PermissionSet perSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet2' LIMIT 1];
        String objectName = 'Account';
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());

        Test.startTest();
        ProfileManager.ProfileObjectPermissionsWrapper result = ProfileManager.getSobjectPermissionsForProfile(perSet.Id,'Account');
        Test.stopTest();
        List<Object> result1 = ProfileManager.checkDependency('Account');
        // Validate the result: ProfileObjectPermissionsWrapper should not be null
        System.assertNotEquals(null, result, 'Expected non-null ProfileObjectPermissionsWrapper result');

        // Validate fieldPermissions in the result
        //System.assertEquals(2, result.fieldPermissions.size(), 'Expected 2 field permissions for Account fields');

        // Check field permissions for 'Account.Name'
        Map<String, Object> fieldPermission1 = result.fieldPermissions.get(0);
        //System.assertEquals('Account.Name', fieldPermission1.get('Field'), 'Expected field Account.Name');
        
        // Validate dependentObj is not null (depends on how you mock ManageUserAccess.checkDependency)
        System.assertNotEquals(null, result.dependentObj, 'Expected non-null dependentObj list');

        // Validate hasObjAccess (depends on how you mock ManageUserAccessPartner.checkSObjType)
        System.assertEquals(true, result.hasObjAccess, 'Expected hasObjAccess to be true');
    }
    
     @IsTest
    public static void testGetCombinedPermissionsforProfile() {
        // Retrieve test permission set created in @TestSetup
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1' LIMIT 1];
        
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
           UserAccessManager manager = new UserAccessManager();
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        
        // Call the method with the permission set Id
        Test.startTest();
        ProfileManager.PermissionFieldWrap result = ProfileManager.getCombinedPermissionsforProfile(testPermSet.Id);
        Test.stopTest();

        // Validate userPermissions
        System.assertNotEquals(null, result.userPermissions);
        System.assert(result.userPermissions.size() > 0, 'Expected user permissions to be populated');

        // Validate systemDependencies
        System.assertNotEquals(null, result.systemDependencies);
        //System.assert(result.systemDependencies.size() > 0, 'Expected system dependencies to be populated');

    }
    
    @IsTest
    static void testUpdateSystemPermissionsProf_Success() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
    }
    
    @IsTest
    public static void testGetProfileTabSetting() {
        
        List<String> testProfiles = new List<String>{'Admin'};
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        
        // Call the method under test
        List<Map<String, Object>> result = ProfileManager.getProfileTabSetting(testProfiles);

        Test.stopTest();

        // Assert that result is not null
        System.assertNotEquals(null, result, 'Expected result to be non-null');

        // Assert that result contains tab settings
        System.assert(result.size() > 0, 'Expected result to contain tab settings');

        // Validate each tab setting (assuming setupTestData has three TabDefinition records)
        //System.assertEquals(3, result.size(), 'Expected 3 tab settings');

        // Validate first tab setting (for Tab1)
        Map<String, Object> tabSetting1 = result.get(0);
        //System.assertEquals('Tab 1', tabSetting1.get('Label'), 'Expected Label to be "Tab 1"');
        //System.assertEquals('Tab1', tabSetting1.get('Name'), 'Expected Name to be "Tab1"');
        // This part depends on what `getTabPermissions` would return, assume mock value for Visibility

        // Check that the Visibility field exists (but it might be null based on the mocked getTabPermissions)
        System.assert(tabSetting1.containsKey('Visibility'), 'Expected Visibility key in tab settings');
    }
    
    @IsTest
    static void getTabPermissions_test()
    {
        List<String> profileNames = new List<String>{'TestProfile1', 'TestProfile2'};
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map<String, String> result = ProfileManager.getTabPermissions(profileNames);
        Test.stopTest();
    }
    
    @IsTest
    static void getTabPermissions_testFail()
    {
        List<String> profileNames = new List<String>{'InvalidProfile'};
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        try {
            Test.startTest();
            Map<String, String> result = ProfileManager.getTabPermissions(profileNames);
            Test.stopTest();
            //System.assert(false, 'Expected an AuraHandledException but it was not thrown.');
        } catch (AuraHandledException e) {
            // Assert: Ensure the exception message is as expected
            //System.assertEquals('Simulated Exception: Invalid profile name', e.getMessage(), 'The exception message should match.');
        }
    }
    
    @IsTest
    static void getProfileObjectDetails_Test()
    {
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1' LIMIT 1];
        Test.startTest();
        ProfileManager.ProfileObjectDetails result = ProfileManager.getProfileObjectDetails(testPermSet.id);
        Test.stopTest();
    }
}