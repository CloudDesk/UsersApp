@IsTest
public class TabPermissionAnalyzerServerTest {
    @IsTest
    static void testGetProfileOrPermSetTabVisibilityForProfile() {
        Test.startTest();
        List<String> profileNames = new List<String> { 'ProfileA' };
        String typeProfile = 'Profile';
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        TabPermissionAnalyzerServer.getProfileOrPermSetTabVisibility(profileNames, typeProfile);
        Test.stopTest();
    }
    
    @IsTest
    static void tabVisibilityRetrieverForProfile_Test()
    {
        List<String> profileNames = new List<String> { 'HCH Sales User' };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        TabPermissionAnalyzerServer.tabVisibilityRetrieverForProfile(profileNames);
        Test.stopTest();
    }
    
    @IsTest
    static void tabVisibilityRetrieverForPermissionSet_Test()
    {
        List<String> perSetNames = new List<String> { 'New Test Permission Set 1' };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        TabPermissionAnalyzerServer.tabVisibilityRetrieverForPermissionSet(perSetNames);
        Test.stopTest();
    }
    
     @IsTest
    static void updateProfileTabVisibilities_Test()
    {
        List<String> profileNames = new List<String> { 'HCH Sales User' };
        List<Map<String, Object>> tabToUpdate = new List<Map<String, Object>>();
        Map<String, Object> tab1 = new Map<String, Object>{'Label' => 'Account','Name' => 'standard-Account','Visibility' => 'DefaultOn'};
        tabToUpdate.add(tab1);
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        TabPermissionAnalyzerServer.updateProfileTabVisibilities(profileNames, tabToUpdate);
        Test.stopTest();
    }
    
    @IsTest
    static void updatePermissionSetTabVisibilities_Test() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        TabPermissionAnalyzerServer.updatePermissionSetTabVisibilities( '[{"standard-Account":"visible"}]', 'New Test Permission Set 1');
        Test.stopTest();
        
    }
}