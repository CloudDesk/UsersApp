//This Test Class Used for ProfileManager Class
@IsTest
public class ProfileManagerTest {
    private static final String Error_Null_Result_Message = 'The result should not be null';
	//This Method holds test data for the test class
    @TestSetup
    static void setupTestData() {
		PermissionAnalyzerObjectServerTest.testsetupMethod();
    }
	//This test Method Used to Check the getProfileName Method
    @IsTest
    static void testGetProfileName() {
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
        
        Test.startTest();
        List<String> profileNames = ProfileManager.getProfileName(profileId);
        Test.stopTest();
        
        System.assertEquals('Standard User', profileNames[0], 'The profile name should match the expected value.');
    }
    //This test Method Used to Check the getProfileusers Method
    @isTest
    static void testGetProfileUsers() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));

        Test.startTest();
        ProfileManager.UserAndProfileDetails result = ProfileManager.getProfileusers(testProfile.Id);
        Test.stopTest();

        System.assertEquals(2, result.userList.size(), 'Expected two users in the result');
    }
    //This test Method Used to Check the getProfileDetails Method
    @isTest
    static void testGetProfileDetails() {
        Test.startTest();
        List<PermissionSet> result = ProfileManager.getProfileDetails();
        Test.stopTest();
        
        System.assertNotEquals(null,result,Error_Null_Result_Message);

    }
    //This test Method Used to Check the updateProfile Method
    @IsTest
    static void testEditProfileProperties_Success() {
        Profile testProfile = [SELECT Id,Name FROM Profile WHERE Name = 'HCH Sales User' LIMIT 1];
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
 
        Test.startTest();
        Map<String, String> result = ProfileManager.updateProfile(testProfile.Name, 'Updated_Profile', 'Updated Description'); 
        Test.stopTest();
        
        System.assertEquals('Updated Description', result.get('description'), 'Expected updated profile description');
    }
    //This test Method Used to Check the deleteProfile Method
    @IsTest
    static void testDeleteProfile() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
 
        Test.startTest();
        ProfileManager.deleteProfile('HCH Sales User');
        Test.stopTest();
        
        System.assert(true, 'Expected to complete successfully without exceptions');
    }
    //This test Method Used to Check the updateSystemPermissionsProf Method
    @IsTest
    static void updateSystemPermissionsProf_Test() {
        
        Map<String, Boolean> systemPermissions = new Map<String, Boolean>{'MockPermission1' => true,'MockPermission2' => true};
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
        Test.startTest();     
        Map<String, Boolean> updatedResult = ProfileManager.updateSystemPermissionsProf('Test_Profile', systemPermissions);
        Test.stopTest();
        
        System.assertNotEquals(null, updatedResult, Error_Null_Result_Message);
    }
    //This test Method Used to Check the getSobjectPermissionsForProfile Method
    @IsTest
    static void testGetSobjectPermissionsForProfile() {
        PermissionSet perSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_2' LIMIT 1];
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());

        Test.startTest();
        ProfileManager.ProfileObjectPermissionsWrapper result = ProfileManager.getSobjectPermissionsForProfile(perSet.Id,'Account');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null ProfileObjectPermissionsWrapper result');   
        System.assertEquals(true, result.hasObjAccess, 'Expected hasObjAccess to be true');
    }
    //This test Method Used to Check the getCombinedPermissionsforProfile Method
    @IsTest
    static void testGetCombinedPermissionsforProfile() {
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());
        
        Test.startTest();
        ProfileManager.PermissionFieldWrap result = ProfileManager.getCombinedPermissionsforProfile(testPermSet.Id);
        Test.stopTest();

        System.assertNotEquals(null, result.userPermissions);
        System.assert(result.userPermissions.size() > 0, 'Expected user permissions to be populated');
        System.assertNotEquals(null, result.systemDependencies);
    }
    //This test Method Used to Check the getProfileTabSetting Method
    @IsTest
    static void testGetProfileTabSetting() {
        
        List<String> testProfiles = new List<String>{'Admin'};
		System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
        Test.startTest();
        List<Map<String, Object>> result = ProfileManager.getProfileTabSetting(testProfiles);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected result to be non-null');
        System.assert(result.size() > 0, 'Expected result to contain tab settings');
        Map<String, Object> tabSetting1 = result.get(0);
        System.assert(tabSetting1.containsKey('Visibility'), 'Expected Visibility key in tab settings');
    }
    //This test Method Used to Check the getTabPermissions Method
    @IsTest
    static void getTabPermissions_test()
    {
        List<String> profileNames = new List<String>{'TestProfile1', 'TestProfile2'};
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map<String, String> result = ProfileManager.getTabPermissions(profileNames);
        Test.stopTest();
        System.debug(result);
        
        System.assertNotEquals(null, result, Error_Null_Result_Message);
        System.assert(result.containsKey('standard-Account'), 'Expected key standard-Account to be present in the result');
    }
    //This test Method Used to Check the getTabPermissions Method is Failed
    @IsTest
    static void getTabPermissions_testFail()
    {
        List<String> profileNames = new List<String>{'InvalidProfile'};
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map<String, String> result = ProfileManager.getTabPermissions(profileNames);
        Test.stopTest();
        
        System.assertNotEquals(null, result, Error_Null_Result_Message);  
        System.assertEquals('DefaultOn', result.get('standard-Account'), 'Expected value for standard-Account to be DefaultOn');
    }
    //This test Method Used to Check the getProfileObjectDetails Method
    @IsTest
    static void getProfileObjectDetails_Test()
    {
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.startTest();
        ProfileManager.ProfileObjectDetails result = ProfileManager.getProfileObjectDetails(testPermSet.id);
        Test.stopTest();
        System.debug(result);
        
        System.assertNotEquals(null, result, Error_Null_Result_Message);  
    }
}