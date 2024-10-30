@IsTest
Public Class PermissionAnalyzerObjectServer_Test {    
    @testsetup
    static void testsetupMethod() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> userList = new List<User>{
            new User(FirstName = 'TestOne', LastName = 'UserOne', Email = 'testuserone@example.com',
                    Username = 'testuserone@example.com', Alias = 'tuone', ProfileId = testProfile.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', 
                    EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US'),
            new User(FirstName = 'TestOne', LastName = 'UserTwo', Email = 'testusertwo@example.com',
                    Username = 'testusertwo@example.com', Alias = 'tutwo', ProfileId = testProfile.Id,
                    TimeZoneSidKey = 'America/Los_Angeles', LocaleSidKey = 'en_US', 
                    EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US')
        };
            insert userList;
            
        List<PermissionSet> permSets = new List<PermissionSet>{
            new PermissionSet(Label = 'New Test Permission Set', Name = 'New_Test_Permission_Set', PermissionsApiEnabled = true),
            new PermissionSet(Label = 'New Test Permission Set 1', Name = 'New_Test_PermSet1', PermissionsApiEnabled = true),
            new PermissionSet(Label = 'New Test Permission Set 2', Name = 'New_Test_PermSet2', PermissionsApiEnabled = true)
        };
        insert permSets;
            
        List<MutingPermissionSet> mutingPermSets = new List<MutingPermissionSet>{
            new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set 1', DeveloperName = 'New_Test_MutePermSet1'),
            new MutingPermissionSet(MasterLabel = 'New Test Mute Permission Set 2', DeveloperName = 'New_Test_MutePermSet2')
        };
        insert mutingPermSets;

        List<PermissionSetGroup> permSetGroups = new List<PermissionSetGroup>{
            new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 1', DeveloperName = 'New_Test_PermSetGrp1'),
            new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 2', DeveloperName = 'New_Test_PermSetGrp2')
        };
        insert permSetGroups;

        List<PermissionSetGroupComponent> permSetGroupComponents = new List<PermissionSetGroupComponent>{
            new PermissionSetGroupComponent(PermissionSetId = permSets[2].Id, PermissionSetGroupId = permSetGroups[1].Id),
            new PermissionSetGroupComponent(PermissionSetId = permSets[1].Id, PermissionSetGroupId = permSetGroups[0].Id),
            new PermissionSetGroupComponent(PermissionSetId = mutingPermSets[1].Id, PermissionSetGroupId = permSetGroups[1].Id),
            new PermissionSetGroupComponent(PermissionSetId = mutingPermSets[0].Id, PermissionSetGroupId = permSetGroups[0].Id)
        };
        insert permSetGroupComponents;

        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>{
            new PermissionSetAssignment(PermissionSetId = permSets[1].Id, AssigneeId = userList[0].Id),
            new PermissionSetAssignment(PermissionSetId = permSets[2].Id, AssigneeId = userList[0].Id)
        };
        insert permSetAssignments;
        List<ObjectPermissions> objPermissions = new List<ObjectPermissions>{
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = permSets[1].Id,
                                PermissionsRead = true, PermissionsCreate = true, PermissionsEdit = false,
                                PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = false),
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = permSets[2].Id,
                                PermissionsRead = true, PermissionsCreate = false, PermissionsEdit = true,
                                PermissionsDelete = true, PermissionsViewAllRecords = true, PermissionsModifyAllRecords = false),
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = mutingPermSets[0].Id,
                                PermissionsRead = false, PermissionsCreate = false, PermissionsEdit = false,
                                PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = true),
            new ObjectPermissions(SObjectType = 'Opportunity', ParentId = mutingPermSets[1].Id,
                                PermissionsRead = false, PermissionsCreate = false, PermissionsEdit = false,
                                PermissionsDelete = false, PermissionsViewAllRecords = false, PermissionsModifyAllRecords = true)
        };
        insert objPermissions;

        List<FieldPermissions> fieldPermissions = new List<FieldPermissions>{
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Amount', ParentId = permSets[1].Id,
                                PermissionsRead = true, PermissionsEdit = false),
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Amount', ParentId = permSets[2].Id,
                                PermissionsRead = true, PermissionsEdit = true),
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Amount', ParentId = mutingPermSets[0].Id,
                                PermissionsRead = false, PermissionsEdit = false),
            new FieldPermissions(SObjectType = 'Opportunity', Field = 'Opportunity.Amount', ParentId = mutingPermSets[1].Id,
                                PermissionsRead = false, PermissionsEdit = false)
        };
        insert fieldPermissions;
    }
    
    @IsTest
    static void checkSobjectFoundInPicklist_Test() {
        Test.startTest();
        System.assert(PermissionAnalyzerObjectServer.checkSobjectFoundInPicklist('Account'), 'Account should be a valid SObject type');
        System.assert(!PermissionAnalyzerObjectServer.checkSobjectFoundInPicklist('TestObj'), 'TestObj should not be a valid SObject type');
        Test.stopTest();
    }    
    @IsTest
    static void checkFieldFoundInPicklist_Test() {
        Test.startTest();
        Map<String, Boolean> result = PermissionAnalyzerObjectServer.checkFieldFoundInPicklist('Account');
        Test.stopTest();
        System.assertNotEquals(null, result, 'The fieldMap should not be null');
        System.assert(!result.isEmpty(), 'The fieldMap should have at least one value');
    }    

    @IsTest
    static void getObjAndFieldPermissionsForMutingPermSet_Test() {
        PermissionSetGroup newGroup = new PermissionSetGroup(MasterLabel = 'New Test Group', DeveloperName = 'New_Test_Group');
        insert newGroup;
        Id groupId = [SELECT Id FROM PermissionSetGroup WHERE DeveloperName = 'New_Test_PermSetGrp1' LIMIT 1].Id;
        
        Test.startTest();
        PermissionAnalyzerObjectServer.MutePermissionWrapper result = PermissionAnalyzerObjectServer.getObjAndFieldPermissionsForMutingPermSet(groupId, new List<String>{'Opportunity'}, 'Opportunity');
        PermissionAnalyzerObjectServer.MutePermissionWrapper result1 = PermissionAnalyzerObjectServer.getObjAndFieldPermissionsForMutingPermSet(newGroup.Id, new List<String>{'Account','Contact'}, 'Account');
        PermissionAnalyzerObjectServer.MutePermissionWrapper result2 = PermissionAnalyzerObjectServer.getObjAndFieldPermissionsForMutingPermSet(null, new List<String>{'Opportunity'}, 'Opportunity');
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }
    @IsTest
    static void getSelectePermissionsetObjAndFieldResult_Test() {
        List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper> fieldPermissionWrapperList = new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{
            new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper(
                'Opportunity.Amount', true, true, 'Amount', true, false, false
            )
        };
        Id permSetID = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1'].Id;

        Test.startTest();
        PermissionAnalyzerObjectServer.UpdatedObjAndFieldResult result = PermissionAnalyzerObjectServer.getSelectePermissionsetObjAndFieldResult(
            permSetID, new List<String>{'Opportunity'}, fieldPermissionWrapperList, new List<String>{'Opportunity.Amount'}
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void updateObjAndFieldInitiation_Test() {
        Map<String, Map<String, Boolean>> objPermissionMap = new Map<String, Map<String, Boolean>>{
            'Opportunity' => new Map<String, Boolean>{
                'PermissionsCreate' => true, 'PermissionsRead' => true, 'PermissionsEdit' => true,
                'PermissionsDelete' => true, 'PermissionsModifyAllRecords' => true, 'PermissionsViewAllRecords' => true
            }
        };
        List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper> fieldPermissionWrapperList = new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{
            new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper(
                'Opportunity.Amount', true, true, 'Amount', true, true, true
            )
        };

        Id permSetID = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1'].Id;
        Id mutingPermSetId = [SELECT Id FROM MutingPermissionSet WHERE DeveloperName = 'New_Test_MutePermSet1'].Id;

        Test.startTest();
        PermissionAnalyzerObjectServer.UpdatedObjAndFieldResult result = PermissionAnalyzerObjectServer.updateObjAndFieldInitiation(
            objPermissionMap, fieldPermissionWrapperList, permSetID, 'Opportunity', ''
        );
        PermissionAnalyzerObjectServer.UpdatedObjAndFieldResult result1 = PermissionAnalyzerObjectServer.updateObjAndFieldInitiation(
            objPermissionMap, fieldPermissionWrapperList, mutingPermSetId, 'Opportunity', 'MutePermissions'
        );
        Boolean isExceptionThrown = false;
        try {
            PermissionAnalyzerObjectServer.updateObjAndFieldInitiation(objPermissionMap, fieldPermissionWrapperList, 'invalidId', 'Opportunity', '');
        } catch (Exception e) {
            isExceptionThrown = true;
        }
        Test.stopTest();

        System.assert(isExceptionThrown, 'An exception should be thrown for invalid ID');
    }
    
    @IsTest
    static void updateObjPermissions_Test() {
        Map<String, Map<String, Boolean>> objPermissionMap = new Map<String, Map<String, Boolean>>{
            'Case' => new Map<String, Boolean>{
                'PermissionsCreate' => true,
                'PermissionsRead' => true,
                'PermissionsEdit' => true,
                'PermissionsDelete' => true,
                'PermissionsModifyAllRecords' => true,
                'PermissionsViewAllRecords' => true
            }
        };
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1' LIMIT 1].Id;
        Test.startTest();
        Map<String, Object> result = PermissionAnalyzerObjectServer.updateObjPermissions(objPermissionMap, permissionSetId);
        Test.stopTest();
        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @IsTest
    static void updateFieldPermissions_Test() {
        List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper> fieldPermissionUpdateList = new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{
            new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper('Opportunity.Amount', true, true, 'Amount', true, true, true),
            new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper('Opportunity.LeadSource', true, true, 'LeadSource', true, false, false)
        };
        
        Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_PermSet1' LIMIT 1].Id;
        Id mutingPermSetId = [SELECT Id FROM MutingPermissionSet WHERE DeveloperName = 'New_Test_MutePermSet1' LIMIT 1].Id;
        
        Test.startTest();
        PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper[] result1 = PermissionAnalyzerObjectServer.updateFieldPermissions(fieldPermissionUpdateList, permSetId, 'Opportunity', '');
        PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper[] result2 = PermissionAnalyzerObjectServer.updateFieldPermissions(fieldPermissionUpdateList, mutingPermSetId, 'Opportunity', 'MutePermissions');
        PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper[] resultErr = PermissionAnalyzerObjectServer.updateFieldPermissions(fieldPermissionUpdateList, null, 'Opportunity', '');
        
        Boolean isExceptionThrown = false;
        try {
            PermissionAnalyzerObjectServer.updateFieldPermissions(
                new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{
                    new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper('Dummy Fields', true, true, 'LeadSource', true, false, false)
                }, 
                permSetId, 'dummy obj', ''
            );
        } catch (Exception e) {
            isExceptionThrown = true;
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Expected invalid object error message, got: ' + e.getMessage());
        }
        Test.stopTest();
        
        System.assertEquals(fieldPermissionUpdateList.size(), result1.size(), 'Expected same size of updated wrappers');
        System.assertEquals(fieldPermissionUpdateList.size(), result2.size(), 'Expected same size of updated wrappers for muting permission set');
        System.assert(isExceptionThrown, 'Exception should be thrown for invalid object');
    }

    @IsTest
    static void checkObjectPermissionDependencies_Test() {
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        
        Test.startTest();
        List<Object> results = PermissionAnalyzerObjectServer.checkObjectPermissionDependencies('Account');
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(3, results.size(), 'Should have 3 permission dependencies');
        
        Map<String, Object> firstResult = (Map<String, Object>)results[0];
        System.assertEquals('Account<read>', firstResult.get('Permission'), 'First permission should be Account read');
        System.assertEquals('Contact<read>', firstResult.get('RequiredPermission'), 'First required permission should be Contact read');
    }

    @IsTest
    static void getFieldsAndObjectRelatedDetails_Test() {
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar = 'LoginResult';
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        
        User u = [SELECT Id FROM User WHERE Username = 'testuserone@example.com' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            PermissionAnalyzerObjectServer.getFieldWrapper fieldRes = PermissionAnalyzerObjectServer.getFieldsAndObjectRelatedDetails('Account', 'Name to Fetch');
            List<Object> result = PermissionAnalyzerObjectServer.checkObjectPermissionDependencies('Account');
            Test.stopTest();
            
            System.assertNotEquals(null, fieldRes, 'Field result should not be null');
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assert(result.size() > 0, 'Should return dependencies');
        }
    }   
}