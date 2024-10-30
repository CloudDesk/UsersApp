@IsTest
public class PermissionAnalyzerRecordTypeServerTest {
    @testsetup
    static void testsetupMethod() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'
            LIMIT 1
        ];

        List < User > userList = new List < User > ();
        for (Integer i = 0; i < 2; i++) {
            userList.add(new User(
                FirstName = 'Test' + (i == 0 ? 'One' : 'Two'),
                LastName = 'User' + (i == 0 ? 'One' : 'Two'),
                Email = 'testuser' + (i == 0 ? 'one' : 'two') + '@example.com',
                Username = 'testuser' + (i == 0 ? 'one' : 'two') + '@example.com',
                Alias = 'tu' + (i == 0 ? 'one' : 'two'),
                ProfileId = testProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert userList;

        List < PermissionSet > permSets = new List < PermissionSet > {
            new PermissionSet(Label = 'New Test Permission Set', Name = 'New_Test_Permission_Set', PermissionsApiEnabled = true),
            new PermissionSet(Label = 'New Test Permission Set 1', Name = 'New_Test_PermSet1', PermissionsApiEnabled = true),
            new PermissionSet(Label = 'New Test Permission Set 2', Name = 'New_Test_PermSet2', PermissionsApiEnabled = true)
        };
        insert permSets;

        List < MutingPermissionSet > mutingPermSets = new List < MutingPermissionSet > {
            new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set 1', DeveloperName = 'New_Test_MutePermSet1'),
            new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set 2', DeveloperName = 'New_Test_MutePermSet2')
        };
        insert mutingPermSets;

        List < PermissionSetGroup > permSetGroups = new List < PermissionSetGroup > {
            new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 1', DeveloperName = 'New_Test_PermSetGrp1'),
            new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 2', DeveloperName = 'New_Test_PermSetGrp2')
        };
        insert permSetGroups;

        List < PermissionSetGroupComponent > permSetGroupComps = new List < PermissionSetGroupComponent > {
            new PermissionSetGroupComponent(PermissionSetId = permSets[2].Id, PermissionSetGroupId = permSetGroups[1].Id),
            new PermissionSetGroupComponent(PermissionSetId = permSets[1].Id, PermissionSetGroupId = permSetGroups[0].Id),
            new PermissionSetGroupComponent(PermissionSetId = mutingPermSets[1].Id, PermissionSetGroupId = permSetGroups[1].Id),
            new PermissionSetGroupComponent(PermissionSetId = mutingPermSets[0].Id, PermissionSetGroupId = permSetGroups[0].Id)
        };
        insert permSetGroupComps;

        List < PermissionSetAssignment > permSetAssigns = new List < PermissionSetAssignment > {
            new PermissionSetAssignment(PermissionSetId = permSets[1].Id, AssigneeId = userList[0].Id),
            new PermissionSetAssignment(PermissionSetId = permSets[2].Id, AssigneeId = userList[0].Id)
        };
        insert permSetAssigns;
        List < ObjectPermissions > objPerms = new List < ObjectPermissions > ();
        List < FieldPermissions > fieldPerms = new List < FieldPermissions > ();

        for (Integer i = 0; i < 4; i++) {
            Boolean isRegular = i < 2;
            Id parentId = isRegular ? permSets[i + 1].Id : mutingPermSets[i - 2].Id;

            objPerms.add(new ObjectPermissions(
                SObjectType = 'Opportunity',
                ParentId = parentId,
                PermissionsRead = isRegular,
                PermissionsCreate = i == 0,
                PermissionsEdit = i == 1,
                PermissionsDelete = i == 1,
                PermissionsViewAllRecords = i == 1,
                PermissionsModifyAllRecords = !isRegular
            ));
            fieldPerms.add(new FieldPermissions(
                SObjectType = 'Opportunity',
                Field = 'Opportunity.Amount',
                ParentId = parentId,
                PermissionsRead = isRegular,
                PermissionsEdit = i == 1
            ));
        }

        insert objPerms;
        insert fieldPerms;
    }

    @IsTest
    static void testUpdateRecordTypeVisibilityForPermissionSet() {
        PermissionSet permSet = [SELECT Id, Label, Name FROM PermissionSet LIMIT 1];
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper wrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        wrapper.developerName = permSet.Name;
        wrapper.label = permSet.Label;
        wrapper.Visible = true;
        wrapper.RecordType = 'test';
        
        Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        
        Test.startTest();
        PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibilityForPermSet(
            new List<String> {permSet.Name}, 
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {wrapper}
        );
        Test.stopTest();
    }

    @IsTest
    static void testGetAndUpdateRecordTypeVisibilityForProfile() {
        String profileName = 'HCH Sales User';
        String objectName = 'Account';
        String recordTypeName = 'Account.Healthplan';
        
        Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        Test.startTest();
        
        // Test getRecordTypeVisibilityForProfile
        Map<String, Object> getResult = PermissionAnalyzerRecordTypeServer.getRecordTypeVisibilityForProfile(
            new List<String> {profileName}, 
            objectName
        );
        
        // Test updateRecordTypeVisibilityForProfile
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper updateWrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        updateWrapper.Default_x = true;
        updateWrapper.developerName = 'Standard User';
        updateWrapper.label = 'Standard User';
        updateWrapper.Visible = true;
        updateWrapper.RecordType = recordTypeName;
        
        List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> updateResult = PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibility(
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {updateWrapper}, 
            new List<String> {profileName}, 
            'Profile'
        );
        Test.stopTest();
        // Assertions
        System.assertNotEquals(null, getResult, 'getResult should not be null');
        System.assertEquals(1, getResult.size(), 'There should be one record type in the getResult');
        System.assertEquals(true, ((Map<String, Object>)getResult.get(recordTypeName)).get('Visible'), 'Record Type should be visible for Profile');
        
        System.assertEquals(1, updateResult.size(), 'Expected 1 record type to be returned in updateResult');
        System.assertEquals(recordTypeName, updateResult[0].recordType, 'RecordType should match');
        System.assertEquals(true, updateResult[0].Visible, 'RecordType visibility should be true');
    }
    
    @IsTest
    static void testGetRecTypeVisibilityForProfileAndPermSet() {
        String profileName = 'HCH Sales User';
        String objectName = 'Account';
        
        Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        
        Test.startTest();
        PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityResutlWrapper result = 
            PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityForProfileAndPermSet(
                objectName, 
                null, 
                'Profile', 
                new List<String>{profileName}
            );
        Test.stopTest();
        
        System.assertNotEquals(1, result.recordTypeList.size(), 'Expected more than one record types to be returned');
    }
    
    @IsTest
    static void testGetRecordTypeVisibilityForPermSet() {
        PermissionSet permSet = [SELECT Id, Label, Name FROM PermissionSet LIMIT 1];
        String objectName = 'Account';
        
        Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        
        Test.startTest();
        Map<String, Object> result = PermissionAnalyzerRecordTypeServer.getRecordTypeVisibilityForPermSet(
            new List<String> {permSet.Name}, 
            objectName
        );
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}