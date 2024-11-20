//This test class is used to check functionality of TabPermissionAnalyzerServer class.
@IsTest
private class TabPermissionAnalyzerServerTest {
    private static final List<String> profileNames = new List<String> { 'HCH Sales User' };
    private static final String Tab_Visibilty_Not_Null_Message = 'Tab visibility map should not be null.';
    private static final String Tab_Visibilty_Not_Empty_Message = 'Tab visibility list should not be empty.';
    private static final String Script_Thrown_Message = 'Script-thrown exception';
    private static final String Error_Thrown_Message = 'Expected AuraHandledException but it was not thrown.';
    //This test method is used to check the logics for getProfileOrPermSetTabVisibility method for Permission Set in TabPermissionAnalyzerServer class.
    @IsTest
    static void testGetProfileOrPermSetTabVisibilityForProfile() {
        Test.startTest();
        List<String> profileNames = new List<String> { 'ProfileA' };
        String typeProfile = 'Profile';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
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
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map < String, String > tabVisibility = TabPermissionAnalyzerServer.tabVisibilityRetrieverForProfile(profileNames);
        Test.stopTest();
        System.assertNotEquals(null, tabVisibility, Tab_Visibilty_Not_Null_Message);
        System.assert(!tabVisibility.isEmpty(), Tab_Visibilty_Not_Empty_Message);
    }
    
    //This test method is used to check the logics for tabVisibilityRetrieverForPermissionSet(Success) method in TabPermissionAnalyzerServer class.
    @IsTest
    static void tabVisibilityRetrieverForPermissionSet_Test()
    {
        List<String> perSetNames = new List<String> { 'New Test Permission Set 1' };
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        Map < String, String > tabVisibility = TabPermissionAnalyzerServer.tabVisibilityRetrieverForPermissionSet(perSetNames);
        Test.stopTest();
        System.assertNotEquals(null, tabVisibility, Tab_Visibilty_Not_Null_Message);
        System.assert(!tabVisibility.isEmpty(), Tab_Visibilty_Not_Empty_Message);
    }
    //This test method is used to check the logics for tabVisibilityRetrieverForPermissionSet(Failure) method in TabPermissionAnalyzerServer class.
    @IsTest
    static void tabVisibilityRetrieverForPermissionSet_Test_exceptionHandling()
    {
        List<String> perSetNames = new List<String> { 'New Test Permission Set 2' };
        Test.startTest();
        try{
        TabPermissionAnalyzerServer.tabVisibilityRetrieverForPermissionSet(perSetNames);
        System.assert(true, Error_Thrown_Message);
        } catch(Exception e){
          System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);  
        }
        Test.stopTest();
    }
    
    //This test method is used to check the logics for updateProfileTabVisibilities(success) method in TabPermissionAnalyzerServer class.
     @IsTest
    static void updateProfileTabVisibilities_Test()
    {
        List<Map<String, Object>> tabToUpdate = new List<Map<String, Object>>();
        Map<String, Object> tab1 = new Map<String, Object>{'Label' => 'Account','Name' => 'standard-Account','Visibility' => 'DefaultOn'};
        tabToUpdate.add(tab1);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        TabPermissionAnalyzerServer.updateProfileTabVisibilities(profileNames, tabToUpdate);
        Test.stopTest();
    }
    //This test method is used to check the logics for updateProfileTabVisibilities(Failure) method in TabPermissionAnalyzerServer class.
     @IsTest
    static void updateProfileTabVisibilities_Test_exceptionHandling()
    {
        List<Map<String, Object>> tabToUpdate = new List<Map<String, Object>>();
        Map<String, Object> tab1 = new Map<String, Object>{'Label' => 'Account','Name' => 'standard-Account','Visibility' => 'DefaultOn'};
        tabToUpdate.add(tab1);
        Test.startTest();
        try{
        TabPermissionAnalyzerServer.updateProfileTabVisibilities(profileNames, tabToUpdate);
        System.assert(true, Error_Thrown_Message);
        } catch(Exception e){
        System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message); 
        }
        Test.stopTest();
    }
    
    //This test method is used to check the logics for updatePermissionSetTabVisibilities(Success) method in TabPermissionAnalyzerServer class.
    @IsTest
    static void updatePermissionSetTabVisibilities_Test() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> result = TabPermissionAnalyzerServer.updatePermissionSetTabVisibilities( '[{"standard-Account":"visible"}]', 'New Test Permission Set 3');
        handlingErrorsAndExceptionsTest();
        Test.stopTest();
        System.assertNotEquals(null, result, 'The result should not be null.');
        System.assertEquals(1, result.size(), 'The result should contain exactly 1 TabSettingsWrapper entry.');
    }
    //This test method is used to check the logics for updatePermissionSetTabVisibilities(Failure) method in TabPermissionAnalyzerServer class.
    @IsTest
    static void updatePermissionSetTabVisibilities_Test_elseCondition() {
        String invalidPermissionSetName = 'InvalidPermissionSet';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        System.Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        MetadataService metaDataService = new MetadataService();
        Test.startTest();
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> result = TabPermissionAnalyzerServer.updatePermissionSetTabVisibilities( '[{"standard-Account":"visible"}]', invalidPermissionSetName);
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