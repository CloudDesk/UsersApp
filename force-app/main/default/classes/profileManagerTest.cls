@IsTest
public class ProfileManagerTest {
	
    @TestSetup
    static void setupTestData() {
		PermissionAnalyzerObjectServerTest.testsetupMethod();
    }

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
    
    @isTest
    static void testGetProfileUsers() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'ProfileName'));

        Test.startTest();
        ProfileManager.UserAndProfileDetails result = ProfileManager.getProfileusers(testProfile.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'The result should not be null');
    }
    
    @isTest
    static void testGetProfileDetails() {
        Test.startTest();
        List<PermissionSet> result = ProfileManager.getProfileDetails();
        Test.stopTest();
        
        System.assertNotEquals(null,result,'Result Should not be Null');

    }
    
    @IsTest
    static void testEditProfileProperties_Success() {
        Profile testProfile = [SELECT Id,Name FROM Profile WHERE Name = 'HCH Sales User' LIMIT 1];
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
 
        Test.startTest();
        Map<String, String> result = ProfileManager.updateProfile(testProfile.Name, 'Updated_Profile', 'Updated Description'); 
        System.assertNotEquals(null, result, 'Result map should not be null.');
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteProfile() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
 
        Test.startTest();
        ProfileManager.deleteProfile('HCH Sales User');
        Test.stopTest();
    }
    
    @IsTest
    public static void updateSystemPermissionsProf_Test() {
        
        Map<String, Boolean> systemPermissions = new Map<String, Boolean>{
            'MockPermission1' => true,
            'MockPermission2' => true
        };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
        Test.startTest();     
        Map<String, Boolean> updatedResult = ProfileManager.updateSystemPermissionsProf('Test_Profile', systemPermissions);
        Test.stopTest();
    }
    
    @IsTest
    public static void testGetSobjectPermissionsForProfile() {
        PermissionSet perSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_2' LIMIT 1];
        String objectName = 'Account';
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult'; 
        Test.setMock(HttpCalloutMock.class, new PermissionDependencyMock());

        Test.startTest();
        ProfileManager.ProfileObjectPermissionsWrapper result = ProfileManager.getSobjectPermissionsForProfile(perSet.Id,'Account');
        Test.stopTest();
        System.assertNotEquals(null, result, 'Expected non-null ProfileObjectPermissionsWrapper result');

        Map<String, Object> fieldPermission1 = result.fieldPermissions.get(0);
        
        System.assertNotEquals(null, result.dependentObj, 'Expected non-null dependentObj list');
        System.assertEquals(true, result.hasObjAccess, 'Expected hasObjAccess to be true');
    }
    
     @IsTest
    public static void testGetCombinedPermissionsforProfile() {
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
        List<Map<String, Object>> result = ProfileManager.getProfileTabSetting(testProfiles);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Expected result to be non-null');
        System.assert(result.size() > 0, 'Expected result to contain tab settings');
        Map<String, Object> tabSetting1 = result.get(0);
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
        Test.startTest();
        Map<String, String> result = ProfileManager.getTabPermissions(profileNames);
        Test.stopTest();
    }
    
    @IsTest
    static void getProfileObjectDetails_Test()
    {
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.startTest();
        ProfileManager.ProfileObjectDetails result = ProfileManager.getProfileObjectDetails(testPermSet.id);
        Test.stopTest();
    }
}