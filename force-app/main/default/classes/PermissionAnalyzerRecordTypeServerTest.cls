//This class is used to check the functionality of PermissionAnalyzerRecordTypeServer class
@IsTest
public class PermissionAnalyzerRecordTypeServerTest {
    private static final String Script_Thrown_Message = 'Script-thrown exception';
    private static final String Error_Thrown_Message = 'Expected AuraHandledException but it was not thrown.';
    private static final String PROFILE_NAME = 'HCH Sales User';
    //This method holds the test data
    @testsetup
    static void testsetupMethod() {
        PermissionAnalyzerObjectServerTest.testsetupMethod();
    }
    //This test method is used to check the functionality of updateRecordTypeVisibilityForPermSet(Success) method in PermissionAnalyzerRecordTypeServer class
    @IsTest
    static void testUpdateRecordTypeVisibilityForPermissionSet() {
        PermissionSet permSet = [SELECT Id, Label, Name FROM PermissionSet LIMIT 1];
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper wrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        wrapper.developerName = permSet.Name;
        wrapper.label = permSet.Label;
        wrapper.Visible = true;
        wrapper.RecordType = 'test';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Test.startTest();
        List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> result=PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibilityForPermSet(
            new List<String> {permSet.Name}, 
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {wrapper}
        );
        Test.stopTest();
        System.assertEquals(1, result.size(), 'Expected one record type updates in the result');
    }
    
    //This test method is used to check the functionality of updateRecordTypeVisibilityForPermSet(Failure) method in PermissionAnalyzerRecordTypeServer class
    @IsTest
    static void testUpdateRecordTypeVisibilityForPermSet_ExceptionHandling() {
        List<String> permissionSetNames = new List<String>{'InvalidPermissionSet'};
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper wrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        wrapper.developerName = 'MockPermSetName';
        wrapper.label = 'MockLabel';
        wrapper.Visible = true;
        wrapper.RecordType = 'test';
        Test.startTest();
        try {
            PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibilityForPermSet(
            permissionSetNames, 
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {wrapper});
            System.assert(true, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    
	//This test method is used to check the functionality of getRecordTypeVisibilityForProfile method in PermissionAnalyzerRecordTypeServer class
    @IsTest
    static void testGetAndUpdateRecordTypeVisibilityForProfile() {
        String profileName = PROFILE_NAME;
        String objectName = 'Account';
        String recordTypeName = 'Account.Healthplan';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Test.startTest();
        Map<String, Object> getResult = PermissionAnalyzerRecordTypeServer.getRecordTypeVisibilityForProfile(new List<String> {profileName},objectName);
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper updateWrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        updateWrapper.Default_x = true;
        updateWrapper.developerName = 'Standard User';
        updateWrapper.label = 'Standard User';
        updateWrapper.Visible = true;
        updateWrapper.RecordType = recordTypeName;
        List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> updateResult = PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibility(
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {updateWrapper},new List<String> {profileName},'Profile');
        PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibility(
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {updateWrapper},null,'Profile');
        PermissionAnalyzerRecordTypeServer.updateRecordTypeVisibility(
            new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> {updateWrapper},new List<String> {'Test Permission set'},'Permission Set');
        Test.stopTest();
        System.assertNotEquals(null, getResult, 'getResult should not be null');
        System.assertEquals(1, getResult.size(), 'There should be one record type in the getResult');
        System.assertEquals(true, ((Map<String, Object>)getResult.get(recordTypeName)).get('Visible'), 'Record Type should be visible for Profile');        
        System.assertEquals(1, updateResult.size(), 'Expected 1 record type to be returned in updateResult');
        System.assertEquals(recordTypeName, updateResult[0].recordType, 'RecordType should match');
        System.assertEquals(true, updateResult[0].Visible, 'RecordType visibility should be true');
    }
    //This test method is used to check the functionality of getRecTypeVisibilityForProfileAndPermSet method in PermissionAnalyzerRecordTypeServer class
    @IsTest
    static void testGetRecTypeVisibilityForProfileAndPermSet() {
        String profileName = PROFILE_NAME;
        String objectName = 'Account';  
        PermissionSet testPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'New_Test_Permission_Set_1' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Test.startTest();
        PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityResutlWrapper result =PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityForProfileAndPermSet(
            objectName,null,'Profile',new List<String>{profileName});
        PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityForProfileAndPermSet(
            objectName,testPermissionSet.Id,'Profile',new List<String>{profileName});
        PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityForProfileAndPermSet(
            objectName,testPermissionSet.Id,'Permission Set',new List<String>{profileName});
        Test.stopTest();  
        System.assertNotEquals(1, result.recordTypeList.size(), 'Expected more than one record types to be returned');
    }
    
    //This test method is used to check the functionality of getRecTypeVisibilityForProfileAndPermSet method in PermissionAnalyzerRecordTypeServer class
    @IsTest
    static void testGetRecTypeVisibilityForProfileAndPermSet_ExceptionHandling() {
        String invalidObjectName  = 'Invalid_Object';
        String profileName = PROFILE_NAME;
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Test.startTest();
        try {
            PermissionAnalyzerRecordTypeServer.getRecTypeVisibilityForProfileAndPermSet(
            invalidObjectName,null,'Profile',new List<String>{profileName});
            System.assert(true, Error_Thrown_Message);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains(Script_Thrown_Message), Script_Thrown_Message);
        }
        Test.stopTest();
    }
    
    //This test method is used to check the functionality of getRecordTypeVisibilityForPermSet method in PermissionAnalyzerRecordTypeServer class
    @IsTest
    static void testGetRecordTypeVisibilityForPermSet() {
        PermissionSet permSet = [SELECT Id, Label, Name FROM PermissionSet LIMIT 1];
        String objectName = 'Account';
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        Test.startTest();
        Map<String, Object> result = PermissionAnalyzerRecordTypeServer.getRecordTypeVisibilityForPermSet(new List<String> {permSet.Name},objectName);
        Test.stopTest(); 
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}