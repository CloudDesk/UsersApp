//This class is used to check the functionality of ConnectedAppCreation class.
@isTest
public class ConnectedAppCreationTest {
    //This setup holds the test data.
    @testSetup
    static void setupTestData() {
        PermissionAnalyzerObjectServerTest.testsetupMethod();
    }
    //This test method is used to check the functionality of createApp method in ConnectedAppCreation class.
    @isTest
    static void testCreateApp_AppDoesNotExist() {
        Test.startTest();
        String result = ConnectedAppCreation.createApp('NonExistentId');
        Test.stopTest();
        
        System.assertEquals('Connected App creation is in progress. Please wait... ', result, 'Unexpected result for app creation');
    }
    //This test method is used to check the functionality of createApp method Exception in ConnectedAppCreation class.
    @isTest
    static void testCreateApp_AppExists() {
        ConnectedApplication existingApp = [SELECT Id FROM ConnectedApplication LIMIT 1];
        
        Test.startTest();
        String result = ConnectedAppCreation.createApp(existingApp.Id);
        Test.stopTest();
        
        System.assertEquals('Error: App Exist', result, 'Unexpected result for existing app');
    }
    //This test method is used to check the functionality of getUserAccessConnectedApp method in ConnectedAppCreation class.
    @isTest
    static void testGetUserAccessConnectedApp_True() {
        ConnectedApplication existingApp = [SELECT Id FROM ConnectedApplication LIMIT 1];
        
        Test.startTest();
        Boolean result = ConnectedAppCreation.getUserAccessConnectedApp(existingApp.Id);
        Test.stopTest();
        
        System.assert(result, 'Expected true for existing app');
    }
    //This test method is used to check the functionality of getUserAccessConnectedApp method Exception in ConnectedAppCreation class.
    @isTest
    static void testGetUserAccessConnectedApp_False() {
        Test.startTest();
        Boolean result = ConnectedAppCreation.getUserAccessConnectedApp('NonExistentId');
        Test.stopTest();
        
        System.assert(!result, 'Expected false for non-existent app');
    }
    //This test method is used to check the functionality of add assignAssignmentsConnectedApp method in ConnectedAppCreation class.
    @isTest
    static void testAssignAssignmentsConnectedApp() {
        ConnectedApplication existingApp = [SELECT Id FROM ConnectedApplication LIMIT 1];
        PermissionSet newPermissionSet = new PermissionSet();
		newPermissionSet.Name = 'New_Test_Permission_Set_6';
		newPermissionSet.Label = 'New Test Permission Set 6';
        insert newPermissionSet;
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_6' LIMIT 1];
        
        List<String> permissionSetIds = new List<String>();
        for (PermissionSet ps : permissionSets) {
            permissionSetIds.add(ps.Id);
        }
        
        Test.startTest();
        ConnectedAppCreation.assignAssignmentsConnectedApp(existingApp.Id, permissionSetIds);
        Test.stopTest();
        
        List<SetupEntityAccess> assignedRecords = [SELECT Id, ParentId, SetupEntityId FROM SetupEntityAccess WHERE SetupEntityId = :existingApp.Id];
        System.assertNotEquals(5, assignedRecords.size(), 'All permission sets should be assigned');
    }
    //This test method is used to check the functionality of removing assignAssignmentsConnectedApp method in ConnectedAppCreation class.
    @isTest
    static void testAssignAssignmentsConnectedApp_RemoveExistingAssignments() {
        ConnectedApplication existingApp = [SELECT Id FROM ConnectedApplication LIMIT 1];
        PermissionSet newPermissionSet = new PermissionSet();
		newPermissionSet.Name = 'New_Test_Permission_Set_6';
		newPermissionSet.Label = 'New Test Permission Set 6';
        insert newPermissionSet;
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_6' LIMIT 1];
        List<SetupEntityAccess> initialAssignments = new List<SetupEntityAccess>();
        for (PermissionSet ps : permissionSets) {
            SetupEntityAccess access = new SetupEntityAccess();
            access.ParentId = ps.Id;
            access.SetupEntityId = existingApp.Id;
            initialAssignments.add(access);
        }
        insert initialAssignments;
        List<String> newPermissionSetIds = new List<String> { permissionSets[0].Id };
            
        Test.startTest();
        ConnectedAppCreation.assignAssignmentsConnectedApp(existingApp.Id, newPermissionSetIds);
        Test.stopTest();
        
        List<SetupEntityAccess> finalAssignments = [SELECT Id, ParentId, SetupEntityId FROM SetupEntityAccess WHERE SetupEntityId = :existingApp.Id];
        System.assertNotEquals(3, finalAssignments.size(), 'Only one permission set should remain');
    }
    
    
}