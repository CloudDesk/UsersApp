@isTest
private class PermissionTabServerTest {
    
    @TestSetup
    static void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User'
            LIMIT 1
        ];
    
        List < User > userList = new List < User > {
            new User(FirstName = 'TestOne', LastName = 'UserOne', Email = 'testuserone@example.com', Username = 'testuserone@example.com', Alias = 'tuone', ProfileId = testProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'TestOne', LastName = 'UserTwo', Email = 'testusertwo@example.com', Username = 'testusertwo@example.com', Alias = 'tutwo', ProfileId = testProfile.Id, TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US')
        };
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
    
        List < ObjectPermissions > objPermissions = new List < ObjectPermissions > {
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = permSets[1].Id, PermissionsRead = true, PermissionsCreate = true, PermissionsEdit = false, PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false),
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = permSets[2].Id, PermissionsRead = true, PermissionsCreate = false, PermissionsEdit = true, PermissionsDelete = true, PermissionsViewAllRecords = true, PermissionsModifyAllRecords = false),
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = mutingPermSets[0].Id, PermissionsRead = false, PermissionsCreate = false, PermissionsEdit = false, PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = true),
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = mutingPermSets[1].Id, PermissionsRead = false, PermissionsCreate = false, PermissionsEdit = false, PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = true)
        };
        insert objPermissions;
    
        List < FieldPermissions > fieldPermissions = new List < FieldPermissions > {
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Eligible__c', ParentId = permSets[1].Id, PermissionsRead = true, PermissionsEdit = false),
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Eligible__c', ParentId = permSets[2].Id, PermissionsRead = true, PermissionsEdit = true),
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Eligible__c', ParentId = mutingPermSets[0].Id, PermissionsRead = false, PermissionsEdit = false),
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Eligible__c', ParentId = mutingPermSets[1].Id, PermissionsRead = false, PermissionsEdit = false)
        };
        insert fieldPermissions;
    }

    @isTest
    static void testGetUserDefinitions() {
        Map < String, String > result = PermissionTabServer.getUserDefinitions();
        System.assertNotEquals(null, result, 'User definitions should not be null');
        System.assert(!result.isEmpty(), 'User definitions should not be empty');
    }
    
    @isTest
    static void testGetObjectDefinition() {
        List < EntityDefinition > result = PermissionTabServer.getObjectDefinition();
        System.assertNotEquals(null, result, 'Object definitions should not be null');
        System.assert(!result.isEmpty(), 'Object definitions should not be empty');
    }
    
    @isTest
    static void testGetFieldDefinition() {
        List < Map < String, Object >> result = PermissionTabServer.getFieldDefinition('Opportunity');
        System.assertNotEquals(null, result, 'Field definitions should not be null');
        System.assert(!result.isEmpty(), 'Field definitions should not be empty');
    }
    @isTest
    static void testGetPermsandUsersOfSelectedPerms() {
        String permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1'].Id;
    
        PermissionTabServer.profilePermissionsetandUserWrapper[] results = new PermissionTabServer.profilePermissionsetandUserWrapper[] {
            PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {
                    'PermissionsApiEnabled'
                }, '', '', '', '', '', 'All'),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {
                    'PermissionsApiEnabled'
                }, '', '', '', '', '', permSetId),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, 'Opportunity', 'PermissionsRead', '', '', '', 'All'),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, 'Opportunity', 'PermissionsRead', '', '', '', permSetId),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, '', '', 'Opportunity', 'Eligible__c', 'PermissionsRead', 'All'),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, '', '', 'Opportunity', 'Eligible__c', 'PermissionsRead', permSetId),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, '', '', 'Opportunity', 'Eligible__c', 'PermissionsRead', 'DUMMYID')
        };
    
        for (PermissionTabServer.profilePermissionsetandUserWrapper result: results) {
            System.assertNotEquals(null, result, 'Result should not be null for valid permission set');
            if (result.permissionSetList != null) {
                System.assert(result.permissionSetList.size() > 0, 'Permissions list should not be empty');
            }
        }
    }
    @isTest
    static void testGetObjOrFieldPerm() {
        Id userId = [SELECT Id FROM User WHERE UserName = 'testuserone@example.com'].Id;
    
        List < Map < String, List < String >>> results = new List < Map < String, List < String >>> {
            PermissionTabServer.getObjOrFieldPerm('Opportunity', 'PermissionsRead', null, userId),
            PermissionTabServer.getObjOrFieldPerm('Opportunity', 'PermissionsRead', 'Opportunity.Eligible__C', userId),
            PermissionTabServer.getObjOrFieldPerm('Opportunity', 'PermissionsRead', 'Opportunity.Eligible__C', 'DummyID')
        };
    
        for (Map < String, List < String >> result: results) {
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }
    
    @isTest
    static void testGetUserPerm() {
        Id userId = [SELECT Id FROM User WHERE UserName = 'testuserone@example.com'].Id;
    
        List < Map < String, List < String >>> results = new List < Map < String, List < String >>> {
            PermissionTabServer.getUserPerm(userId, new List < String > {
                'PermissionsApiEnabled'
            }),
            
            PermissionTabServer.getUserPerm('DummyID', new List < String > {
                'PermissionsAPIEnabled'
            })
        };
    
        for (Map < String, List < String >> result: results) {
            System.assertNotEquals(null, result, 'Result should not be null');
        }
    }
    
    @isTest
    static void testGetObjOrFieldPermissionsOrigin() {
        List < String > permSetIdList = new List < String > ();
        for (PermissionSet perm: [SELECT Id FROM PermissionSet]) {
            permSetIdList.add(perm.Id);
        }
    
        List < Map < String, List < String >>> results = new List < Map < String, List < String >>> {
            PermissionTabServer.getObjOrFieldPermissionsOrigin('PermissionsRead', permSetIdList, 'Opportunity', null),
            PermissionTabServer.getObjOrFieldPermissionsOrigin('PermissionsRead', permSetIdList, 'Opportunity', 'Opportunity.Eligible__c')
        };
    
        for (Map < String, List < String >> result: results) {
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(!result.isEmpty(), 'Result should not be empty');
        }
    }
}