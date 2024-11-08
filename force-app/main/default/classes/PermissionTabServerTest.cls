//This class is used to check the functionality of PermissionTabServer class
@IsTest
private class PermissionTabServerTest {
    private static final String OPPORTUNITY_Amount_FIELD = 'Opportunity.Amount';
    private static final String Result_Not_Null_Message = 'Result should not be null';
    //This method holds the test data
    @TestSetup
    static void setupTestData() {
        PermissionAnalyzerObjectServerTest.testsetupMethod();
    }
	//This test method is used to check the functionality of getUserDefinitions method
    @IsTest
    static void testGetUserDefinitions() {
        Map < String, String > result = PermissionTabServer.getUserDefinitions();
        System.assertNotEquals(null, result, 'User definitions should not be null');
        System.assert(!result.isEmpty(), 'User definitions should not be empty');
    }
    //This test method is used to check the functionality of getObjectDefinition method
    @IsTest
    static void testGetObjectDefinition() {
        List < EntityDefinition > result = PermissionTabServer.getObjectDefinition();
        System.assertNotEquals(null, result, 'Object definitions should not be null');
        System.assert(!result.isEmpty(), 'Object definitions should not be empty');
    }
    //This test method is used to check the functionality of getFieldDefinition method
    @IsTest
    static void testGetFieldDefinition() {
        List < Map < String, Object >> result = PermissionTabServer.getFieldDefinition('Opportunity');
        System.assertNotEquals(null, result, 'Field definitions should not be null');
        System.assert(!result.isEmpty(), 'Field definitions should not be empty');
    }
    //This test method is used to check the functionality of getPermsandUsersOfSelectedPerms method
    @IsTest
    static void testGetPermsandUsersOfSelectedPerms() {
        String permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1'].Id;
        
        PermissionTabServer.profilePermissionsetandUserWrapper[] results = new PermissionTabServer.profilePermissionsetandUserWrapper[] {
            PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {
                'PermissionsApiEnabled'
                    }, '', '', '', '', '', 'All'),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {'PermissionsApiEnabled'}, '', '', '', '', '', permSetId),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, 'Opportunity', 'PermissionsRead', '', '', '', 'All'),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, 'Opportunity', 'PermissionsRead', '', '', '', permSetId),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, '', '', 'Opportunity', 'Eligible__c', 'PermissionsRead', 'All'),
                PermissionTabServer.getPermsandUsersOfSelectedPerms(new List < String > {}, '', '', 'Opportunity', 'Eligible__c', 'PermissionsRead', permSetId)
                };
                    
                    for (PermissionTabServer.profilePermissionsetandUserWrapper result: results) {
                        System.assertNotEquals(null, result, 'Result should not be null for valid permission set');
                        if (result.permissionSetList != null) {
                            System.assert(result.permissionSetList.size() > 0, 'Permissions list should not be empty');
                        }
                    }
    }
    //This test method is used to check the functionality of getObjOrFieldPerm method
    @IsTest
    static void testGetObjOrFieldPerm() {
        Id userId = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com'].Id;
        
        List < Map < String, List < String >>> results = new List < Map < String, List < String >>> {
            PermissionTabServer.getObjOrFieldPerm('Opportunity', 'PermissionsRead', null, userId),
                PermissionTabServer.getObjOrFieldPerm('Opportunity', 'PermissionsRead', OPPORTUNITY_Amount_FIELD, userId),
                PermissionTabServer.getObjOrFieldPerm('Opportunity', 'PermissionsRead', OPPORTUNITY_Amount_FIELD, 'DummyID')
                };
                    
                    for (Map < String, List < String >> result: results) {
                        System.assertNotEquals(null, result, Result_Not_Null_Message);
                    }
    }
    //This test method is used to check the functionality of getUserPerm method
    @IsTest
    static void testGetUserPerm() {
        Id userId = [SELECT Id FROM User WHERE UserName = 'testuseraccess1@example.com'].Id;
        
        List < Map < String, List < String >>> results = new List < Map < String, List < String >>> {
            PermissionTabServer.getUserPerm(userId, new List < String > {
                'PermissionsApiEnabled'
                    }),
                
                PermissionTabServer.getUserPerm('DummyID', new List < String > {
                    'PermissionsAPIEnabled'
                        })
                };
                    
                    for (Map < String, List < String >> result: results) {
                        System.assertNotEquals(null, result, Result_Not_Null_Message);
                    }
    }
    //This test method is used to check the functionality of getObjOrFieldPermissionsOrigin method
    @IsTest
    static void testGetObjOrFieldPermissionsOrigin() {
        List < String > permSetIdList = new List < String > ();
        for (PermissionSet perm: [SELECT Id FROM PermissionSet]) {
            permSetIdList.add(perm.Id);
        }
        
        List < Map < String, List < String >>> results = new List < Map < String, List < String >>> {
            PermissionTabServer.getObjOrFieldPermissionsOrigin('PermissionsRead', permSetIdList, 'Opportunity', null),
                PermissionTabServer.getObjOrFieldPermissionsOrigin('PermissionsRead', permSetIdList, 'Opportunity', OPPORTUNITY_Amount_FIELD)
                };
                    
                    for (Map < String, List < String >> result: results) {
                        System.assertNotEquals(null, result, Result_Not_Null_Message);
                        System.assert(!result.isEmpty(), 'Result should not be empty');
                    }
    }
}