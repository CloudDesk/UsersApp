@IsTest
Public Class UserAccessManagerTest {
    
    @TestSetup
    Static Void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales' LIMIT 1];
        List<User> userList = new List<User>();
        
        for(Integer i = 1; i <= 2; i++){
            userList.add(new User(FirstName = 'Test'+i,LastName = 'User'+i,Email = 'testuser' + i + '@example.com',Username = 'testuser' + i + '@example.com',Alias = 'TU1',
            						TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            							LanguageLocaleKey = 'en_US',IsActive = true));
        }
        insert userList;
    }
    
    @IsTest
    Static Void testSuccessfulLogin() {
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
		permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult';
       	UserAccessManager manager = new UserAccessManager();   
        
        Test.stopTest();
    }
 	@IsTest
    Static Void testFailedLogin() {
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new PartnerWsdl2ApexMockWithError());
        UserAccessManager manager = new UserAccessManager();
        
        Test.stopTest();
    }

}