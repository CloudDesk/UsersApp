@IsTest
public class PermissionAnalyzerServerTest {
	
    @TestSetup
    static void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales'
            LIMIT 1
        ];

        List < User > usersToInsert = new List < User > {
            new User(FirstName = 'NewOne', LastName = 'UserOne', Email = 'testuserOne@example.com', Username = 'testuserOne@example.com', Alias = 'TU1',
                TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', ProfileId = testProfile.Id,
                LanguageLocaleKey = 'en_US', IsActive = true),
            new User(FirstName = 'Newtwo', LastName = 'User2', Email = 'testuser2@example.com', Username = 'testuser2@example.com', Alias = 'TU2',
                TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', ProfileId = testProfile.Id,
                LanguageLocaleKey = 'en_US', IsActive = true)
        };
        insert usersToInsert;

        List < PermissionSet > permSetsToInsert = new List < PermissionSet > {
            new PermissionSet(Name = 'New_Test_Permission_Set_One', Label = 'New Test Permission Set One', Description = 'Permission Set for Testing'),
            new PermissionSet(Name = 'New_Test_Permission_Set_Two', Label = 'New Test Permission Set Two', Description = 'Permission Set for Testing')
        };
        insert permSetsToInsert;

        insert new PermissionSetAssignment(AssigneeId = usersToInsert[0].Id, PermissionSetId = permSetsToInsert[0].Id);

        List < ObjectPermissions > objPermsToInsert = new List < ObjectPermissions > {
            new ObjectPermissions(SObjectType = 'Contact', ParentId = permSetsToInsert[0].Id, PermissionsRead = true, PermissionsCreate = false,
                PermissionsEdit = true, PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false),
            new ObjectPermissions(SObjectType = 'Contact', ParentId = permSetsToInsert[1].Id, PermissionsRead = true, PermissionsCreate = true,
                PermissionsEdit = true, PermissionsDelete = true, PermissionsViewAllRecords = true, PermissionsModifyAllRecords = false),
            new ObjectPermissions(SObjectType = 'Account', ParentId = permSetsToInsert[0].Id, PermissionsRead = true, PermissionsCreate = true, PermissionsEdit = false,
                PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false)
        };
        insert objPermsToInsert;

        List < FieldPermissions > fieldPermsToInsert = new List < FieldPermissions > {
            new FieldPermissions(SObjectType = 'Account', ParentId = permSetsToInsert[1].Id, Field = 'Account.Description', PermissionsRead = true, PermissionsEdit = false),
            new FieldPermissions(SObjectType = 'Contact', ParentId = permSetsToInsert[0].Id, Field = 'Contact.Email', PermissionsRead = true, PermissionsEdit = false),
            new FieldPermissions(SObjectType = 'Account', ParentId = permSetsToInsert[0].Id, Field = 'Account.Description', PermissionsRead = true, PermissionsEdit = true)
        };
        insert fieldPermsToInsert;

        List < PermissionSetGroup > permSetGroupsToInsert = new List < PermissionSetGroup > {
            new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_One', MasterLabel = 'New Test Permission Set Group One', Description = 'This is a test permission set group.'),
            new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_Two', MasterLabel = 'New Test Permission Set Group Two', Description = 'This is a test permission set group.')
        };
        insert permSetGroupsToInsert;

        insert new PermissionSetGroupComponent(PermissionSetGroupId = permSetGroupsToInsert[0].Id, PermissionSetId = permSetsToInsert[0].Id);
    }

    @IsTest
    static void testGetUser() {
        Test.startTest();
        List < User > resultsWithSearch = PermissionAnalyzerServer.getUser('New');
        List < User > resultsNoSearch = PermissionAnalyzerServer.getUser(null);
        Test.stopTest();

        System.assertEquals(2, resultsWithSearch.size(), 'There should be 2 users found with the name "New"');
        System.assertEquals(0, resultsNoSearch.size(), 'There should be no users returned when search term is null');
    }

    @IsTest
    static void testGetUserRelatedPermissionSets() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserOne@example.com'
            LIMIT 1
        ];

        Test.startTest();
        List < PermissionSet > permissionSetsValid = PermissionAnalyzerServer.getUserRelatedPermissionSets(testUser.Id);
        List < PermissionSet > permissionSetsInvalid = PermissionAnalyzerServer.getUserRelatedPermissionSets('');
        Test.stopTest();

        System.assertNotEquals(0, permissionSetsValid.size(), 'The user should have at least one permission set assigned.');
        System.assertEquals(0, permissionSetsInvalid.size(), 'No permission sets should be returned for invalid user ID.');
    }

    @IsTest
    static void testGetEntityDefinition() {
        Test.startTest();
        List < EntityDefinition > nativeResults = PermissionAnalyzerServer.getEntityDefinition('Native');
        List < EntityDefinition > managedResults = PermissionAnalyzerServer.getEntityDefinition('ManagedPackage');
        Test.stopTest();

        System.assertNotEquals(0, nativeResults.size(), 'Native entity definitions should be returned.');
        System.assertNotEquals(null, nativeResults[0].QualifiedApiName, 'EntityDefinition should have a QualifiedApiName.');

        System.assertNotEquals(0, managedResults.size(), 'ManagedPackage entity definitions should be returned.');
        for (EntityDefinition ed: managedResults) {
            System.assertNotEquals(null, ed.NamespacePrefix, 'Managed package objects should have a NamespacePrefix.');
        }
    }

    @IsTest
    static void testGetCombinedObjAndFieldPermsForUser() {
        // Get the Permission Set IDs created in test setup
        Map < String, Id > permSetMap = new Map < String, Id > ();
        for (PermissionSet perm: [SELECT Id, Name FROM PermissionSet WHERE Name IN('New_Test_Permission_Set_Two', 'New_Test_Permission_Set_One')]) {
            permSetMap.put(perm.Name, perm.Id);
        }

        // Insert field permission for Opportunity
        FieldPermissions fieldPerm = new FieldPermissions(
            SObjectType = 'Opportunity',
            ParentId = permSetMap.get('New_Test_Permission_Set_Two'),
            Field = 'Opportunity.Amount',
            PermissionsRead = true,
            PermissionsEdit = true
        );
        insert fieldPerm;

        Test.startTest();
        // Insert dummy PermissionSet
        PermissionSet permSetDummy = new PermissionSet(Name = 'Dummy_PermissionSet', Label = 'Dummy PermissionSet');
        insert permSetDummy;

        // Test with valid permission sets
        Map < String, PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper > result =
            PermissionAnalyzerServer.getCombinedObjAndFieldPermsForUser(new List < Id > (permSetMap.values()));

        // Test with dummy permission set (should return null)
        Map < String, PermissionAnalyzerServer.ObjANdFieldPermissionsWrapper > resultNull =
            PermissionAnalyzerServer.getCombinedObjAndFieldPermsForUser(new List < String > {
                permSetDummy.Id
            });
        Test.stopTest();

        // Verifications
        System.assertEquals(3, result.size(), 'There should be permissions for 3 objects (Account, Opportunity and Contact).');

        // Verify Object Permissions for Account
        Map < String, Object > accountPerms = result.get('Account').objectPermissions;
        System.assert(Boolean.valueOf(accountPerms.get('PermissionsRead')), 'Account: PermissionsRead should be true.');
        System.assert(Boolean.valueOf(accountPerms.get('PermissionsCreate')), 'Account: PermissionsCreate should be true.');
        System.assert(!Boolean.valueOf(accountPerms.get('PermissionsEdit')), 'Account: PermissionsEdit should be false.');
        System.assert(!Boolean.valueOf(accountPerms.get('PermissionsDelete')), 'Account: PermissionsDelete should be false.');

        // Verify Object Permissions for Contact
        Map < String, Object > contactPerms = result.get('Contact').objectPermissions;
        System.assert(Boolean.valueOf(contactPerms.get('PermissionsRead')), 'Contact: PermissionsRead should be true.');
        System.assert(Boolean.valueOf(contactPerms.get('PermissionsCreate')), 'Contact: PermissionsCreate should be true.');
        System.assert(Boolean.valueOf(contactPerms.get('PermissionsEdit')), 'Contact: PermissionsEdit should be true.');

        // Verify resultNull is empty
        System.assertEquals(0, resultNull.size(), 'Result for dummy permission set should be empty.');
    }

    @IsTest
    static void testConsolidateFieldPermissions() {
        Map < String, Object > existingPermissions = new Map < String, Object > {
            'Account.Name' => new Map < String,
            Object > {
                'PermissionsRead' => true,
                'PermissionsEdit' => true
            }
        };

        FieldPermissions newPerm = new FieldPermissions(
            Field = 'Account.Name',
            PermissionsRead = false,
            PermissionsEdit = false
        );
        Test.startTest();
        Map < String, Object > result = PermissionAnalyzerServer.consolidateFieldPermissions(existingPermissions, newPerm);
        Test.stopTest();

        System.assert(result.containsKey('Account.Name'), 'Account.Name should exist.');
        Map < String, Object > fieldPermissions = (Map < String, Object > ) result.get('Account.Name');
        System.assert(Boolean.valueOf(fieldPermissions.get('PermissionsRead')), 'PermissionsRead should remain true.');
        System.assert(Boolean.valueOf(fieldPermissions.get('PermissionsEdit')), 'PermissionsEdit should remain true.');
    }

    @IsTest
    static void testGetProfileName() {
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'
            LIMIT 1
        ];

        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'ProfileName'));

        Test.startTest();
        List < String > profileNames = PermissionAnalyzerServer.getProfileName(standardUserProfile.Id);
        Test.stopTest();

        System.assertEquals(1, profileNames.size(), 'There should be 1 profile name returned.');
        System.assertEquals('Standard User', profileNames[0], 'The profile name should be Standard User');
    }

    @IsTest
    static void testGetProfileNameEmptyResponse() {
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'
            LIMIT 1
        ];

        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(null, 'EmptyResponse'));

        Test.startTest();
        List < String > profileNames = PermissionAnalyzerServer.getProfileName(standardUserProfile.Id);
        Test.stopTest();

        System.assertEquals(0, profileNames.size(), 'There should be no profile name returned.');
    }
    
    @IsTest
    static void testGetAssignedUsersForProfilePerSetPerSetGrp() {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One'
            LIMIT 1
        ];
    
        Test.startTest();
        List < PermissionSetAssignment > assignedUsers = PermissionAnalyzerServer.getAssignedUsersForProfilePerSetPerSetGrp(permSet.Id);
        Test.stopTest();
    
        System.assertEquals(1, assignedUsers.size(), 'There should be exactly 1 user assigned.');
        PermissionSetAssignment assignment = assignedUsers[0];
        System.assert(assignment.Assignee.IsActive, 'Assignee should be active.');
        System.assertNotEquals(null, assignment.Assignee.Name, 'Assignee Name should not be null.');
        System.assertNotEquals(null, assignment.Assignee.Username, 'Assignee Username should not be null.');
    }
    @IsTest
    static void testEditPermSetGroupProperties() {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE PermissionSetGroup.DeveloperName = 'New_Test_Permission_Set_Group_One'
            LIMIT 1
        ];
    
        Test.startTest();
        PermissionSetGroup updatedGroup = PermissionAnalyzerServer.editPermSetGrpProperties(permSet.Id, 'Updated Permission Set Group Analyzer1234', 'Updated_PermSetGroup_Analyzer1234', 'This is an updated description', 'permission set');
        Test.stopTest();
    
        System.assertNotEquals(null, updatedGroup, 'Updated Permission Set Group should not be null.');
        PermissionSetGroup dbGroup = [SELECT MasterLabel, DeveloperName, Description FROM PermissionSetGroup WHERE Id =: updatedGroup.Id];
        System.assertEquals('Updated Permission Set Group Analyzer1234', dbGroup.MasterLabel, 'MasterLabel should be updated.');
        System.assertEquals('Updated_PermSetGroup_Analyzer1234', dbGroup.DeveloperName, 'DeveloperName should be updated.');
        System.assertEquals('This is an updated description', dbGroup.Description, 'Description should be updated.');
    }
    
    @IsTest
    static void testEditPermSetGroupPropertiesWithoutPerSetGrpId() {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_Two'
            LIMIT 1
        ];
    
        Test.startTest();
        try {
            PermissionAnalyzerServer.editPermSetGrpProperties(permSet.Id, 'Updated Permission Set Group', 'Updated_PermSetGroup', 'This is an updated description', 'permission set');
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEditPermSetProperties() {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One'
            LIMIT 1
        ];
    
        Test.startTest();
        PermissionSet updatedPermSet = PermissionAnalyzerServer.editPermSetProperties(permSet.Id, 'Updated Permission Set', 'Updated Permission Set', 'This is an updated description');
        Test.stopTest();
        PermissionSet dbPermSet = [SELECT Label, Name, Description FROM PermissionSet WHERE Id =: updatedPermSet.Id];
        System.assertEquals('Updated Permission Set', dbPermSet.Label, 'Label should be updated.');
        System.assertEquals('Updated_Permission_Set', dbPermSet.Name, 'Name should be updated with underscores.');
        System.assertEquals('This is an updated description', dbPermSet.Description, 'Description should be updated.');
    }
    
    @IsTest
    static void testEditPermSetProperties_DmlException() {
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_One'
            LIMIT 1
        ];
    
        Test.startTest();
        try {
            PermissionAnalyzerServer.editPermSetProperties(permSet.Id, 'New Test Permission Set Two', 'New Test Permission Set Two', 'This is an updated description');
            System.assert(false, 'Expected AuraHandledException not thrown.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEditProfileProperties_Success() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Test.startTest();
        Map < String, String > result = PermissionAnalyzerServer.editProfileProperties('System Administrator', 'Updated_Profile', 'Updated Description');
        Test.stopTest();
    
        System.assertNotEquals(null, result, 'Result map should not be null.');
    }
    
}