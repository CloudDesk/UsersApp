@isTest
public class PartnerSObjectWsdl2ApexTest {
    @isTest
    static void testSObjectXCreation() {
        Test.startTest();
        PartnerSObjectWsdl2Apex.SObject_x testSObjectX = new PartnerSObjectWsdl2Apex.SObject_x();
        System.assertNotEquals(null, testSObjectX, 'SObject_x instance should not be null');
        Test.stopTest();
    }
}