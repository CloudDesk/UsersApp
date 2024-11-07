//This test class is used to check functionality of TabPermissionAnalyzerServer class.
@IsTest
private class TabPermissionAnalyzerServerTest {
    private static final String Tab_Visibilty_Not_Null_Message = 'Tab visibility map should not be null.';
    private static final String Tab_Visibilty_Not_Empty_Message = 'Tab visibility list should not be empty.';
    //This test method is used to check the logics for getProfileOrPermSetTabVisibility method for Permission Set in TabPermissionAnalyzerServer class.
    @IsTest
    static void testGetProfileOrPermSetTabVisibilityForProfile() {
        Test.startTest();
        List<String> profileNames = new List<String> { 'ProfileA' };
        String typeProfile = 'Profile';
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        List < Map < String, Object >> tabVisibility  = TabPermissionAnalyzerServer.getProfileOrPermSetTabVisibility(profileNames, typeProfile);
        Test.stopTest();
        System.assertNotEquals(null, tabVisibility, Tab_Visibilty_Not_Null_Message);
        System.assert(!tabVisibility.isEmpty(), Tab_Visibilty_Not_Empty_Message);
    }
    //This test method is used to check the logics for getProfileOrPermSetTabVisibility method for Permission Set in TabPermissionAnalyzerServer class.
    @IsTest
    static void testGetProfileOrPermSetTabVisibilityForPermissionSet() {
        Test.startTest();
        List<String> profileNames = new List<String> { 'PermissionSetA' };
        String typeProfile = 'PermissionSet';
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        List < Map < String, Object >> tabVisibility  = TabPermissionAnalyzerServer.getProfileOrPermSetTabVisibility(profileNames, typeProfile);
        Test.stopTest();
        System.assertNotEquals(null, tabVisibility, Tab_Visibilty_Not_Null_Message);
        System.assert(!tabVisibility.isEmpty(), Tab_Visibilty_Not_Empty_Message);
    }
    
    //This test method is used to check the logics for tabVisibilityRetrieverForProfile method in TabPermissionAnalyzerServer class.
    @IsTest
    static void tabVisibilityRetrieverForProfile_Test()
    {
        List<String> profileNames = new List<String> { 'HCH Sales User' };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map < String, String > tabVisibility = TabPermissionAnalyzerServer.tabVisibilityRetrieverForProfile(profileNames);
        Test.stopTest();
        System.assertNotEquals(null, tabVisibility, Tab_Visibilty_Not_Null_Message);
        System.assert(!tabVisibility.isEmpty(), Tab_Visibilty_Not_Empty_Message);
    }
    
    //This test method is used to check the logics for tabVisibilityRetrieverForPermissionSet method in TabPermissionAnalyzerServer class.
    @IsTest
    static void tabVisibilityRetrieverForPermissionSet_Test()
    {
        List<String> perSetNames = new List<String> { 'New Test Permission Set 1' };
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map < String, String > tabVisibility = TabPermissionAnalyzerServer.tabVisibilityRetrieverForPermissionSet(perSetNames);
        Test.stopTest();
        System.assertNotEquals(null, tabVisibility, Tab_Visibilty_Not_Null_Message);
        System.assert(!tabVisibility.isEmpty(), Tab_Visibilty_Not_Empty_Message);
    }
    
    //This test method is used to check the logics for updateProfileTabVisibilities method in TabPermissionAnalyzerServer class.
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
    
    //This test method is used to check the logics for updatePermissionSetTabVisibilities method in TabPermissionAnalyzerServer class.
    @IsTest
    static void updatePermissionSetTabVisibilities_Test() {
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> result = TabPermissionAnalyzerServer.updatePermissionSetTabVisibilities( '[{"standard-Account":"visible"}]', 'New Test Permission Set 1');
        handlingErrorsAndExceptionsTest();
        Test.stopTest();
        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(1, result.size(), 'The result should contain exactly 1 TabSettingsWrapper entry.');
    }
    static void handlingErrorsAndExceptionsTest(){
        List<MetadataService.Error> errorList = new List<MetadataService.Error>();
        MetadataService.Error error = new MetadataService.Error();
        error.message = 'Error Occured';
        error.statusCode = '400';
        error.fields = new List<String>();
        error.fields.add('Name');
        errorList.add(error);
        try{
            TabPermissionAnalyzerServer.handleErrorMessages(errorList);
        }
        catch (Exception e) {
            System.assertEquals(e.getMessage(), 'Script-thrown exception', 'Exception Occured as expected');
        }
    }
}