//This class is used to check the functionality of UserAccessBatch class.
@isTest
public class UserAccessBatchTest {
    //This setup holds the test data.
    @testSetup
    static void setupTestData() {
        PermissionAnalyzerObjectServerTest.testsetupMethod();
    }
    //This test method is used to check the functionality method in UserAccessBatch class.
    @isTest
    static void testUserAccessBatch() {
        Test.startTest();
        UserAccessBatch batch = new UserAccessBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();
        System.assertNotEquals(1, [SELECT Count() FROM AsyncApexJob WHERE Status = 'Queued']);
    }
    
}