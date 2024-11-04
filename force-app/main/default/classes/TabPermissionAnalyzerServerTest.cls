@IsTest
public class TabPermissionAnalyzerServerTest {
	
    
     @IsTest
    static void testGetProfileOrPermSetTabVisibilityForProfile() {
        // Mocking tab visibility retriever for Profile
        Test.startTest();
        
        // Mock the response from tabVisibilityRetrieverForProfile
        // Assume 'ProfileA' has visibility for 'standard-Account' and no visibility for 'standard-Contact'
        List<String> profileNames = new List<String> { 'ProfileA' };
        String typeProfile = 'Profile';

        // Use Test.setMock for mocking web service calls if needed
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());

        // Call the method to test for profiles
        List<Map<String, Object>> result = TabPermissionAnalyzerServer.getProfileOrPermSetTabVisibility(profileNames, typeProfile);

        // Verify the result
        //System.assertEquals(2, result.size(), 'Expected 2 tab settings returned');
        //System.assertEquals('Accounts', result[0].get('Label'), 'Expected first tab label is Accounts');
        //System.assertEquals('standard-Account', result[0].get('Name'), 'Expected first tab name is standard-Account');
        //System.assertNotNull(result[0].get('Visibility'), 'Expected visibility for standard-Account tab');
        //System.assertEquals('Contacts', result[1].get('Label'), 'Expected second tab label is Contacts');
        //System.assertEquals('standard-Contact', result[1].get('Name'), 'Expected second tab name is standard-Contact');
        //System.assertNull(result[1].get('Visibility'), 'Expected no visibility for standard-Contact tab');
        
        Test.stopTest();
    }
    
    @IsTest
    static void tabVisibilityRetrieverForProfile_Test()
    {
        List<String> profileNames = new List<String> { 'HCH Sales User' };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map<String, String> result = TabPermissionAnalyzerServer.tabVisibilityRetrieverForProfile(profileNames);
        Test.stopTest();
    }
    
    @IsTest
    static void tabVisibilityRetrieverForPermissionSet_Test()
    {
        List<String> perSetNames = new List<String> { 'New Test Permission Set 1' };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map<String, String> result = TabPermissionAnalyzerServer.tabVisibilityRetrieverForPermissionSet(perSetNames);
        Test.stopTest();
    }
    
     @IsTest
    static void updateProfileTabVisibilities_Test()
    {
        List<String> profileNames = new List<String> { 'HCH Sales User' };
        List<Map<String, Object>> tabToUpdate = new List<Map<String, Object>>();
         Map<String, Object> tab1 = new Map<String, Object>{
            'Label' => 'Account',
            'Name' => 'standard-Account',
            'Visibility' => 'DefaultOn'
        };
        tabToUpdate.add(tab1);
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        TabPermissionAnalyzerServer.updateProfileTabVisibilities(profileNames, tabToUpdate);
        Test.stopTest();
    }
    
    @IsTest
    static void UpdatePermissionSetTabVisibilities_Test() {
        // Sample JSON string to simulate the input
        String tabSettingsJson = '[{"standard-Account":"visible"}]';
        String permissionSetName = 'New Test Permission Set 1';
		
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        // Start test context
        Test.startTest();

        // Call the method to test
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> result = TabPermissionAnalyzerServer.updatePermissionSetTabVisibilities(tabSettingsJson, permissionSetName);

        // Stop test context
        Test.stopTest();

        // Assertions
        //System.assertEquals(3, result.size(), 'The result should contain 3 tab settings.');

        // Validate each TabSettingsWrapper
        
    }
    
    /*
    @IsTest
    static void helperUpdateClassForPermissionset_Test() {
        // Sample JSON string to simulate the input
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> tabSettingsResult = new List<TabPermissionAnalyzerServer.TabSettingsWrapper>();
        
        TabPermissionAnalyzerServer.TabSettingsWrapper tabSetting1 = new TabPermissionAnalyzerServer.TabSettingsWrapper();
        tabSetting1.tab = 'standard-Account';
        tabSetting1.visibility = 'Visible';
        tabSettingsResult.add(tabSetting1);

        TabPermissionAnalyzerServer.TabSettingsWrapper tabSetting2 = new TabPermissionAnalyzerServer.TabSettingsWrapper();
        tabSetting2.tab = 'standard-Case';
        tabSetting2.visibility = 'Available';
        tabSettingsResult.add(tabSetting2);
        
        String permissionSetName = 'TestPermissionSet';
		
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        
        // Start test context
        Test.startTest();

        // Call the method to test
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> result = TabPermissionAnalyzerServer.helperUpdateClassForPermissionset(tabSettingsResult, permissionSetName);

        // Stop test context
        Test.stopTest();

        // Assertions
        //System.assertEquals(3, result.size(), 'The result should contain 3 tab settings.');

        // Validate each TabSettingsWrapper
        
    }
		*/
}