//This class is for 
@IsTest
public class UserPermissionAnalyzerServerTest {
    @testsetup
    static void testsetupMethod() {
        List < User > userList = new List < User > ();
        for (Integer i = 1; i <= 2; i++) {
            userList.add(new User(
                FirstName = 'Test' + i,
                LastName = 'User' + i,
                Email = 'testuser' + i + '@exampleUserApp.com',
                Username = 'testuser' + i + '@exampleUserApp.com',
                Alias = 'tu' + i,
                ProfileId = [Select Id from Profile where Name = 'Standard User'].Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert userList;
        List < PermissionSet > permSets = new List < PermissionSet > {
            new PermissionSet(Label = 'New Test Permission Set', Name = 'New_Test_Permission_Set', PermissionsApiEnabled = true),
            new PermissionSet(Label = 'New Test Permission Set 1', Name = 'New_Test_PermSet1', PermissionsApiEnabled = true, PermissionsEmailSingle = true, PermissionsEditTask = true, PermissionsListEmailSend = true, PermissionsEmailMass = true),
            new PermissionSet(Label = 'New Test Permission Set 2', Name = 'New_Test_PermSet2', PermissionsApiEnabled = true, PermissionsEmailSingle = true, PermissionsEditTask = true, PermissionsListEmailSend = true, PermissionsEmailMass = true)
        };
        insert permSets;
        List < MutingPermissionSet > mutingPermSets = new List < MutingPermissionSet > {
            new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set 1', DeveloperName = 'New_Test_MutePermSet1', PermissionsEmailSingle = false, PermissionsEditTask = false, PermissionsListEmailSend = false, PermissionsEmailMass = false),
            new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set 2', DeveloperName = 'New_Test_MutePermSet2', PermissionsEmailSingle = false, PermissionsEditTask = false, PermissionsListEmailSend = false, PermissionsEmailMass = false)
        };
        insert mutingPermSets;
        List < PermissionSetGroup > permSetGroups = new List < PermissionSetGroup > {
            new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 1', DeveloperName = 'New_Test_PermSetGrp1'),
            new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 2', DeveloperName = 'New_Test_PermSetGrp2'),
            new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_One', MasterLabel = 'New Test Permission Set Group One', Description = 'This is a test permission set group.')
        };
        insert permSetGroups;

        List < PermissionSetGroupComponent > permSetGroupComponents = new List < PermissionSetGroupComponent > {
            new PermissionSetGroupComponent(PermissionSetId = permSets[2].Id, PermissionSetGroupId = permSetGroups[1].Id),
            new PermissionSetGroupComponent(PermissionSetId = permSets[1].Id, PermissionSetGroupId = permSetGroups[0].Id),
            new PermissionSetGroupComponent(PermissionSetId = mutingPermSets[1].Id, PermissionSetGroupId = permSetGroups[1].Id),
            new PermissionSetGroupComponent(PermissionSetId = mutingPermSets[0].Id, PermissionSetGroupId = permSetGroups[0].Id)
        };
        insert permSetGroupComponents;

        List < PermissionSetAssignment > permSetAssignments = new List < PermissionSetAssignment > {
            new PermissionSetAssignment(PermissionSetId = permSets[1].Id, AssigneeId = userList[0].Id),
            new PermissionSetAssignment(PermissionSetId = permSets[2].Id, AssigneeId = userList[0].Id),
            new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetGroupId = permSetGroups[2].Id)
        };
        insert permSetAssignments;
    }
    @IsTest
    static void getCombinedUserPermissionsForUser_Test() {
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new UserPermissionDependencyMock());
    
        User u = [SELECT Id FROM User WHERE Username = 'testuser1@exampleUserApp.com'
            LIMIT 1
        ];
		List<Id> permSetIds = new List<Id>(new Map<Id, PermissionSet>([SELECT Id FROM PermissionSet]).keySet());
    
        System.runAs(u) {
            Test.startTest();
            UserPermissionAnalyzerServer.UserPermissionsWrapper result1 = UserPermissionAnalyzerServer.getCombinedUserPermissionsForUser(permSetIds);
            List < Object > result = UserPermissionAnalyzerServer.getUserPermissionUserDependency();
            Test.stopTest();
    
            System.assertNotEquals(null, result, 'Results should not be null');
            System.assertNotEquals(null, result1, 'Results should not be null');
        }
    }
    
    @IsTest
    static void getMutedUserPermissionOfPermSetGrp_Test() {
        List < Map < String, Object >> userPermMapList = new List < Map < String, Object >> {
            new Map < String,
            Object > {
                'fieldLabel' => 'Send Email',
                'fieldName' => 'PermissionsEmailSingle',
                'fieldValue' => true
            },
            new Map < String,
            Object > {
                'fieldLabel' => 'Email Mass',
                'fieldName' => 'PermissionsEmailMass',
                'fieldValue' => true
            },
            new Map < String,
            Object > {
                'fieldLabel' => 'Edit Task',
                'fieldName' => 'PermissionsEditTask',
                'fieldValue' => true
            }
        };
    
        Test.startTest();
        PermissionSetGroup testGroup = new PermissionSetGroup(MasterLabel = 'New TestGroup', DeveloperName = 'New_TestGroup');
        insert testGroup;
    
        String permSetGrpId = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_PermSetGrp1'
            LIMIT 1
        ].Id;
        String permissionNames = 'PermissionsEmailMass,PermissionsEmailSingle,PermissionsEditTask';
         UserPermissionAnalyzerServer.getMutedUserPermissionOfPermSetGrp(permSetGrpId, permissionNames, userPermMapList);
		 UserPermissionAnalyzerServer.getMutedUserPermissionOfPermSetGrp(testGroup.Id, permissionNames, userPermMapList);
         UserPermissionAnalyzerServer.getMutedUserPermissionOfPermSetGrp(null, permissionNames, userPermMapList);
        try {
            UserPermissionAnalyzerServer.getMutedUserPermissionOfPermSetGrp('DummyId', 'PermissionsEmailMass,PermissionsEmailSingle,EditTask', userPermMapList);
            System.assert(false, 'Exception should have been thrown');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void getSelectedUserPermissionOrigins_Test() {
        List<Id> permSetIds = new List<Id>(new Map<Id, PermissionSet>([SELECT Id FROM PermissionSet]).keySet());
        Test.startTest();
        Map < String, List < String >> result = UserPermissionAnalyzerServer.getSelectedUserPermissionOrigins('PermissionsEditTask', permSetIds);
        Test.stopTest();
    
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    @IsTest
    static void updateUserPermissionsforProfOrPermSetOrMuteGroups_Test() {
        // Set up test data
        Map < String, Boolean > userPermMap = new Map < String, Boolean > {
            'EmailMass' => false,
            'ListEmailSend' => false
        };
        Map < String, Boolean > userPermMapMute = new Map < String, Boolean > {
            'EmailMass' => true,
            'ListEmailSend' => true
        };
    
        // Fetch necessary IDs
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'HCH Sales User'].Id;
        Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1'].Id;
        Id mutePermSetId = [SELECT Id FROM MutingPermissionSet WHERE DeveloperName = 'New_Test_MutePermSet1'].Id;
        Test.startTest();
    
        // Test profile update
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Map < String, Boolean > resultProf = UserPermissionAnalyzerServer.updateUserPermissionsforProfOrPermSetOrMuteGroups(
            [SELECT Id FROM PermissionSet WHERE ProfileId =: profileId].Id,
            'HCH Sales User',
            userPermMap
        );
    
        // Test permission set update
        Map < String, Boolean > resultPermSet = UserPermissionAnalyzerServer.updateUserPermissionsforProfOrPermSetOrMuteGroups(
            permSetId,
            'TestProfile',
            userPermMap
        );
    
        // Test muting permission set update
        Map < String, Boolean > resultGroup = UserPermissionAnalyzerServer.updateUserPermissionsforProfOrPermSetOrMuteGroups(
            mutePermSetId,
            'TestProfile',
            userPermMapMute
        );
    
        // Test error scenarios
        testErrorScenarios();
    
        Test.stopTest();
    
        // Add assertions here to verify the results
        System.assertNotEquals(null, resultProf, 'Profile update result should not be null');
        System.assertNotEquals(null, resultPermSet, 'Permission Set update result should not be null');
        System.assertNotEquals(null, resultGroup, 'Muting Permission Set update result should not be null');
    }
    
    private static void testErrorScenarios() {
        Map < String, Boolean > userPermMapErr = new Map < String, Boolean > {
            'EmailMass' => false
        };
        Map < String, Boolean > userPermMapMuteErr = new Map < String, Boolean > {
            'EmailMass' => true
        };
    
        // Test exception for PermissionSet
        try {
            UserPermissionAnalyzerServer.updateUserPermissionsforProfOrPermSetOrMuteGroups(
                null,
                'TestProfile',
                userPermMapErr
            );
            System.assert(false, 'Exception should be thrown for invalid PermissionSet scenario');
        } catch (Exception e) {
            System.assert(true, 'Exception thrown as expected for invalid PermissionSet scenario');
        }
    
        // Test exception for MutingPermissionSet
        try {
            UserPermissionAnalyzerServer.updateUserPermissionsforProfOrPermSetOrMuteGroups(
                null,
                'TestProfile',
                userPermMapMuteErr
            );
            System.assert(false, 'Exception should be thrown for invalid MutingPermissionSet scenario');
        } catch (Exception e) {
            System.assert(true, 'Exception thrown as expected for invalid MutingPermissionSet scenario');
        }
    }
    
}