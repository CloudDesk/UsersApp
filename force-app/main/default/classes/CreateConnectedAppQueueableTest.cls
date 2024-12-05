//This class is used to check the functionality of CreateConnectedAppQueueable class.
@IsTest
public class CreateConnectedAppQueueableTest {
    //This test method is used to check the success functionality of CreateConnectedAppQueueable
    @isTest
    static void testCreateConnectedAppQueueableSuccess() {
        Test.startTest();
        CreateConnectedAppQueueable queueable = new CreateConnectedAppQueueable('mockSessionId', 'testuser@domain.com', 'testuser@domain.com');
        System.enqueueJob(queueable);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200,'Login'));
        Test.setMock(WebServiceMock.class, new MetadataWebServiceMock());
        
        List<ConnectedApplication> connectedApps = [SELECT Id, Name FROM ConnectedApplication WHERE Name = 'User Access Connected App'];
        System.assertEquals(1, connectedApps.size(), 'Connected App should be created successfully.');
        System.assertEquals('testuser@domain.com', queueable.currentUserUsername, 'Same Value Should be retrun');
        
        Test.stopTest();
    }
    //This test method is used to check the exception functionality of CreateConnectedAppQueueable
    @isTest
    public static void testCreateConnectedAppQueueableError() {
        Test.startTest();
        CreateConnectedAppQueueable queueable = new CreateConnectedAppQueueable('', '', '');
        System.enqueueJob(queueable);
        System.assertEquals('', queueable.currentUserUsername, 'Should Return Null');
        System.assertNotEquals('User Name', queueable.currentUserUsername, 'Should Return Null');
        Test.stopTest();
    }
}