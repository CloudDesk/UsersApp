//This batch class is used to retrieve current user's detail.
global with sharing class UserAccessBatch implements Database.Batchable<SObject> {
    
    private List<String> failedRecords = new List<String>();
    //This start method retrieves current users data.
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select Id from User Limit 1 ';
        return Database.getQueryLocator(query);
    }
    //This execute method calls queueable apex.
    global void execute(Database.BatchableContext bc, List<User> scope) {
        try {
            System.enqueueJob(new CreateConnectedAppQueueable(UserInfo.getSessionId(), UserInfo.getUserName(), UserInfo.getUserEmail()));
        } catch (Exception e) {
            
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        System.debug('Batch Completed');        
    }

}