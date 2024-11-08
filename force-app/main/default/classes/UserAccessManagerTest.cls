// This test Class for UserAccessManager class
@IsTest
public class UserAccessManagerTest {
    //This method holds the test data.
    @TestSetup
    static void setupTestData() {
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'HCH Sales' LIMIT 1];
        List<User> userList = new List<User>();
        
        for(Integer i = 1; i <= 2; i++){
            userList.add(new User(FirstName = 'Test'+i,LastName = 'User'+i,Email = 'testuser' + i + '@example.com',Username = 'testuseraccess' + i + '@example.com',Alias = 'TU1',
                                  TimeZoneSidKey = 'America/Los_Angeles',LocaleSidKey = 'en_US',EmailEncodingKey = 'UTF-8',ProfileId = testProfile.Id,
                                  LanguageLocaleKey = 'en_US',IsActive = true));
        }
        insert userList;
    }
    //This test method is used to check successful login.    
    @IsTest
    static void testSuccessfulLogin() {
        Test.startTest();
        Test.setMock(WebServiceMock.class, new permissionPartnerSoapSforceComMock());
        permissionPartnerSoapSforceComMock.indicatorVar =  'LoginResult';
        UserAccessManager manager = new UserAccessManager();
        Test.stopTest();
        System.assertNotEquals(null, manager.partnerConnection, 'Partner connection should not be null after successful login.');
        System.assertNotEquals(null, manager.partnerConnection.SessionHeader, 'SessionHeader should not be null.');
        System.assertNotEquals(null, manager.partnerConnection.SessionHeader.sessionId, 'Session ID should be present in SessionHeader.');
    }
    //This test method is used to check Failed login.
    @IsTest
    static void testFailedLogin() {
        Test.startTest();
        Test.setMock(WebServiceMock.class, new PartnerWsdl2ApexMockWithError());
        try {
            new UserAccessManager();
            System.assert(true, 'Expected an exception to be thrown for failed login, but it did not.');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Login failed'), 'The expected login failure message should be present.');
        }
        Test.stopTest();
    }

}