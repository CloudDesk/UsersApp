@IsTest
Public Class UserAccessManagerTest {
    
    @TestSetup
    Static Void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales' LIMIT 1];
        
        User testUser1 = new User(FirstName = 'Test',LastName = 'User1',Email = 'testuserOne@example.com',Username = 'testuserOne@example.com',Alias = 'TU1',
            						TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            							LanguageLocaleKey = 'en_US',IsActive = true);
        insert testUser1;
        
        User testUser2 = new User(FirstName = 'Test2',LastName = 'User2',Email = 'testuserTwo@example.com',Username = 'testuserTwo@example.com',Alias = 'TU1',
            						TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
            							LanguageLocaleKey = 'en_US',IsActive = true);
        insert testUser2;   
    }
    
    @IsTest
    Static Void testSuccessfulLogin() {
        User u = [Select Id,UserName From User where UserName = 'testuserOne@example.com'];
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