//This class is used to check the functionality of ManagePermissionSetCreateServer class
@IsTest
public class ManagePermissionSetCreateServerTest {
    private static final String OPPORTUNITY_Amount_FIELD = 'Opportunity.Amount';
    private static final String PermissionSet_Label = 'Test Sample PermSet';
    private static final String PermissionSet_Description = 'This is Test Sample';
    private static final String Error_Thrown_Message = 'Expected AuraHandledException but it was not thrown.';
    private static final String Script_Thrown_Message = 'Script-thrown exception';
    private static final String Assertion_CreateNewPermSet_Message = 'The created PermissionSet should be found in the query.';
    //This method holds the test data
    @TestSetup
    static void setupTestData() { 
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        List<User> userList = new List<User>();
        User testUser1 = new User(
            FirstName = 'TestNewOne',
            LastName = 'UserNewOne',
            Email = 'testuserone@example.com',
            Username = 'testuserNewone@example.com',
            Alias = 'tuone',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US');
        userList.add(testUser1);
        insert userList; 
        PermissionSet permSet1 = new PermissionSet(Label = 'New Test Permission Set 1', Name = 'New_Test_PermSet1', PermissionsApiEnabled =true);
        insert new List<PermissionSet>{ permSet1};
        PermissionSetAssignment permSetAssign1 = new PermissionSetAssignment(PermissionSetId = permSet1.Id, AssigneeId = testUser1.Id);  
        insert new List<PermissionSetAssignment>{permSetAssign1};
        PermissionSetGroup permSetGroupForUserAssign = new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_One',MasterLabel = 'New Test Permission Set Group One',Description = 'This is a test permission set group.');
        insert permSetGroupForUserAssign;
        PermissionSetAssignment permSetGrpAssignment = new PermissionSetAssignment(AssigneeId = testUser1.Id,PermissionSetGroupId  = permSetGroupForUserAssign.Id);
        insert permSetGrpAssignment;
        ObjectPermissions objPerm1 = new ObjectPermissions(
        	SObjectType = 'Opportunity',
            ParentId = permSet1.Id,
            PermissionsRead = true,
            PermissionsCreate = true,
            PermissionsEdit = false,
            PermissionsDelete = false,
            PermissionsViewAllRecords = false,
            PermissionsModifyAllRecords = false);
        insert new List<ObjectPermissions>{ objPerm1};
        FieldPermissions fieldPerm1 = new FieldPermissions(
             SObjectType = 'Opportunity',
             Field = OPPORTUNITY_Amount_FIELD,
             ParentId = permSet1.Id,
             PermissionsRead = true,
             PermissionsEdit = false);
        insert new List<FieldPermissions>{ fieldPerm1};
        PermissionSet testPermissionSet = new PermissionSet(Name = 'Test_Sample_PermSet',Label = PermissionSet_Label);
        insert testPermissionSet;
    }
    //This test method is used to check the functionality of duplicatePermissionSetCheck method in ManagePermissionSetCreateServer class
    @IsTest
    static void duplicatePermissionSetCheck_Test(){
        Boolean result = ManagePermissionSetCreateServer.duplicatePermissionSetCheck('test perm','test_perm');
        System.assertNotEquals(true, result, 'it should not be false');
    }
    //This test method is used to check the functionality of getUserLicenseForUser method in ManagePermissionSetCreateServer class
    @IsTest
    static void getUserLicenseForUser_Test(){
        Test.StartTest();
        Map<String,List<Map<String,String>>> result = ManagePermissionSetCreateServer.getUserLicenseForUser([Select Id FROM User Where UserName= 'testuserNewone@example.com'].Id);      
        Test.StopTest();
        System.assertNotEquals(null, result, 'it should Not be null');
    }
    //This test method is used to check the functionality of getUsersBasedOnLicenseName method in ManagePermissionSetCreateServer class
    @IsTest
    static void getUsersBasedOnLicenseName_Test(){
        Test.StartTest();
        List<User> result = ManagePermissionSetCreateServer.getUsersBasedOnLicenseName('Salesforce'); 
        ManagePermissionSetCreateServer.getUsersBasedOnLicenseName('ActionPlansPsl');
        ManagePermissionSetCreateServer.getUsersBasedOnLicenseName('');
        Test.StopTest();
        System.assertNotEquals(null, result, 'it should Not be null');
    }
    //This test method is used to check the functionality of createPermissionSetTest method with Object in ManagePermissionSetCreateServer class
    @IsTest
    static void createNewPermissionSet_TestWithObj(){
        Map<String,Boolean> objPerm = new Map<String,Boolean>{'PermissionsRead'=>true, 'PermissionsEdit'=>true,
            'PermissionsDelete'=>true, 'PermissionsViewAllRecords'=>true,'PermissionsCreate'=>true,'PermissionsModifyAllRecords'=>true};
                Map<String, Map<String, Boolean>> objectPermMap = new Map<String, Map<String, Boolean>>{'Opportunity'=>objPerm};
                    PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper eligibleFieldWrapper = new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper();
        eligibleFieldWrapper.field = OPPORTUNITY_Amount_FIELD;
        eligibleFieldWrapper.PermissionsRead = true;
        eligibleFieldWrapper.PermissionsEdit = true;
        eligibleFieldWrapper.Label = 'Amount';
        eligibleFieldWrapper.hasEditAccess = true;
        eligibleFieldWrapper.mutedPermissionsRead = false;
        eligibleFieldWrapper.mutedPermissionsEdit = false;
        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        Test.StartTest();
        createPermissionSetTest(objectPermMap, new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{eligibleFieldWrapper},'Obj','',new Map<String, Boolean>(),new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>());
        Test.StopTest();
    }
    //This test method is used to check the functionality of createPermissionSetTest method with User in ManagePermissionSetCreateServer class
    @IsTest
    static void createNewPermissionSet_TestWithUser(){
        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        Test.StartTest();
        createPermissionSetTest(new Map<String, Map<String, Boolean>>(), new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{},'User','',new Map<String, Boolean>{'ApiEnabled'=>true,'EditTask'=>true},new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>());
        Test.StopTest();
    }
    //This test method is used to check the functionality of createPermissionSetTest method with Tab in ManagePermissionSetCreateServer class
    @IsTest
    static void createNewPermissionSet_TestWithTab(){
        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService(); 
        
        Test.StartTest();
        createPermissionSetTest(new Map<String, Map<String, Boolean>>(), new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{},'Tab','[{"standard-Account":"visible"}]',new Map<String, Boolean>(),new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>());
        Test.StopTest();
    }
    //This test method is used to check the functionality of createPermissionSetTest method with Record Type in ManagePermissionSetCreateServer class
    @IsTest
    static void createNewPermissionSet_TestWithRecType(){
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper wrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        wrapper.RecordType = 'Account.Healthplan';
        wrapper.Visible = false;
        wrapper.developerName = 'Healthplan';
        wrapper.Default_x = false;
        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        
        Test.StartTest();
        createPermissionSetTest(new Map<String, Map<String, Boolean>>(), new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{},'RecordType','',new Map<String, Boolean>(),new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>{wrapper});
        Test.StopTest();
    }
    //Method to Check functionality of Create Permission Set in ManagePermissionSetCreateServer class
    static void createPermissionSetTest(Map<String, Map<String, Boolean>> objectPermissionsMap, List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper> fieldPerms, String updateType, String tabToUpdate, Map<String, Boolean> userToUpdate,List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> recTypeToUpdate){
        try{
            ManagePermissionSetCreateServer.createNewPermissionSet(new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> PermissionSet_Label, 
                'Description'=>PermissionSet_Description, 'License'=>null,'hasActivationRequired'=>true},
                                                                   new List<String>{[SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1].Id},objectPermissionsMap, 
                                                                   fieldPerms,'Opportunity',updateType,tabToUpdate,
                                                                   userToUpdate, recTypeToUpdate);
            PermissionSetManager.createPermissionSet(new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> PermissionSet_Label, 
                'Description'=>PermissionSet_Description, 'License'=>null,'hasActivationRequired'=>true}
                                                     , new List<String>{[SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1].Id});
            System.assert(false, Error_Thrown_Message);
            
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals([Select Id from PermissionSet Where Name = 'Test_Sample_PermSet'].Id, retrievedPermSet.Id, Assertion_CreateNewPermSet_Message);
    }
    //This test method is used to check the functionality of assignUsersToPermissionSet method with Record Type in ManagePermissionSetCreateServer class
    @IsTest
    static void testAssignUsersToPermissionSet() {
        PermissionSet testPermSet = [Select Id from PermissionSet Where Name = 'Test_Sample_PermSet'];
        List<User> testUsers = new List<User>();
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        testUsers.add(testUser);
        List<Id> userIds = new List<Id>();
        for (User user : testUsers) {
            userIds.add(user.Id);
        }
        Test.startTest();
        ManagePermissionSetCreateServer.assignUsersToPermissionSet(testPermSet.Id, userIds);
        Test.stopTest();
        List<PermissionSetAssignment> assignments = [SELECT Id, AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE PermissionSetId = :testPermSet.Id 
                                                     AND AssigneeId IN :userIds];
        System.assertEquals(userIds.size(), assignments.size(), 'All users should be assigned to the permission set.');
        for (PermissionSetAssignment assignment : assignments) {
            System.assert(userIds.contains(assignment.AssigneeId), 'Assigned user ID should be in the original list of user IDs.');
            System.assertEquals(testPermSet.Id, assignment.PermissionSetId, 'Assigned permission set ID should match the test permission set ID.');
        }
    }
    
     //This test method is used to check the functionality of createPermissionSetWithTabsAndUsers(Success) method with Record Type in ManagePermissionSetCreateServer class
     @IsTest
    static void testCreatePermissionSetWithoutTabSettings() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        String tabSettingsJson = '[]';
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        List<Id> userIds = new List<Id>{ testUser.Id };
        Test.startTest();
        
        // Call the method to create the permission set without tab settings
        String createdPermSetId = ManagePermissionSetCreateServer.createPermissionSetWithTabsAndUsers(new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> PermissionSet_Label, 
                'Description'=>PermissionSet_Description, 'License'=>null,'hasActivationRequired'=>true}, tabSettingsJson, userIds);

        Test.stopTest();

        // Verify the permission set creation
        PermissionSet createdPermSet = [SELECT Id, Name, Label, Description, IsCustom FROM PermissionSet WHERE Id = :createdPermSetId];
        System.assertNotEquals(null, createdPermSet, 'Permission Set should be created successfully.');
        

        // Verify that the permission set was assigned to the user
        List<PermissionSetAssignment> assignments = [
            SELECT Id, AssigneeId, PermissionSetId
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :createdPermSetId
            AND AssigneeId = :testUser.Id
        ];
        System.assertEquals(1, assignments.size(), 'Permission Set should be assigned to the test user.');
    }
    
    //This test method is used to check the functionality of createPermissionSetWithTabsAndUsers(Failure) method with Record Type in ManagePermissionSetCreateServer class
     @IsTest
    static void testCreatePermissionSetWithoutTabSettings_DmlException() {
        String tabSettingsJson = '[]';
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        List<Id> userIds = new List<Id>{ testUser.Id };
        Test.startTest();      
        try{
            String createdPermSetId = ManagePermissionSetCreateServer.createPermissionSetWithTabsAndUsers(new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> PermissionSet_Label, 
                'Description'=>PermissionSet_Description, 'License'=>null,'hasActivationRequired'=>true}, tabSettingsJson, userIds);
            System.assert(false, Error_Thrown_Message);
            
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }

        Test.stopTest();
    }
    //
    @IsTest
    static void testGetPermSetTabSettings() {
        TabPermissionAnalyzerServer.TabSettingsWrapper wrapper = new TabPermissionAnalyzerServer.TabSettingsWrapper('Account', 'Default On');
        Test.startTest();
        List<MetadataService.PermissionSetTabSetting> tabSettingList = ManagePermissionSetCreateServer.getPermSetTabSettings(new List<TabPermissionAnalyzerServer.TabSettingsWrapper> {wrapper});
        System.assertEquals(tabSettingList.size(), 1, 'List size as expected');
        try{
            ManagePermissionSetCreateServer.handleException('Exception Occured', null);
        }
        catch(Exception e){
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception Occured as expected');
        }
        Test.stopTest();
        
    }
    
}