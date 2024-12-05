//This queueable class is used for creating custom setting and connected app.
public with sharing class CreateConnectedAppQueueable implements Queueable, Database.AllowsCallouts {
    @TestVisible private String sessionId;
    @TestVisible private String currentUserUsername;
    @TestVisible private String currentUserEmail;
    
    public CreateConnectedAppQueueable(String sessionId, String currentUserUsername, String currentUserEmail) {
        this.sessionId = sessionId;
        this.currentUserUsername = currentUserUsername;
        this.currentUserEmail = currentUserEmail;
    }
    
    public void execute(QueueableContext context) {
        Date todayDate = Date.today();
        String formattedDate = Datetime.newInstance(todayDate.year(), todayDate.month(), todayDate.day()).format('yyyy_MM_dd', 'GMT');
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort('60.0');
        metaDataPort.SessionHeader = new MetadataService.SessionHeader_element();
        metaDataPort.SessionHeader.sessionId = sessionId;
        
        MetadataService.ConnectedApp connectedApp = new MetadataService.ConnectedApp();
        connectedApp.fullName = 'UserAccessConnectedApp';
        connectedApp.label = 'User Access Connected App';
        connectedApp.contactEmail = currentUserEmail;
        
        // Define OAuth Config
        MetadataService.ConnectedAppOauthConfig oAuthConfig = new MetadataService.ConnectedAppOauthConfig();
        oAuthConfig.callbackUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/';
        oAuthConfig.scopes = new List<String>{'Api'};
        oAuthConfig.isClientCredentialEnabled = true;
        oAuthConfig.isAdminApproved = true;
        oAuthConfig.oauthClientCredentialUser = currentUserUsername;
        oAuthConfig.consumerKey = 'UserApp_DefaultConsumerKey_' + formattedDate;
        oAuthConfig.consumerSecret = 'UserApp_DefaultConsumerSecret_' + formattedDate;
        
        connectedApp.oauthConfig = oAuthConfig;
        
        // Prepare the metadata list
        List<MetadataService.Metadata> metadataList = new List<MetadataService.Metadata>{ connectedApp };
            
            // Send the request to Salesforce Metadata API
            try {
                MetadataService.SaveResult[] saveResults = metaDataPort.createMetadata(metadataList);
                if(saveResults.size() > 0){
                    MetadataService.SaveResult save_result = saveResults[0];
                    System.debug(save_result.errors);
                    System.debug('Save Results >>>'+save_result);
                    if(save_result.errors == null){
                        String prefixName = UserAccessManager.getUserAccessCredentialNamespace();
                        String customSettingName = prefixName + 'User_Access_Credentials__c';
                        SObject customSettingRecord = Schema.getGlobalDescribe().get(customSettingName).newSObject();
                        customSettingRecord.put('Name', 'Standard');
                        customSettingRecord.put(prefixName + 'Client_Id__c', 'UserApp_DefaultConsumerKey_' + formattedDate);
                        customSettingRecord.put(prefixName + 'Client_Secret__c', 'UserApp_DefaultConsumerSecret_' + formattedDate);
                        insert customSettingRecord;
                        system.debug('Full Name'+save_result.fullName);
                        List<ConnectedApplication> connectedApps = [SELECT Id, Name FROM ConnectedApplication WHERE Name = : connectedApp.label LIMIT 1];
                        SObject publishedEvent = createAndPublishPlatformEvent('Success','Connected App and custom setting created successfully.',connectedApps[0].Id);
                    }else {
                        SObject publishedEvent = createAndPublishPlatformEvent('Error','Metadata creation failed: ' + save_Result.errors[0].message,null);
                        ConnectedAppEvent__e event = new ConnectedAppEvent__e();
                        event.Status__c = 'Error';
                        event.Message__c = 'Metadata creation failed: ' + save_Result.errors[0].message;
                        EventBus.publish(event);
                    }
                    
                }
            } catch (Exception e) {
                System.debug('Error creating ConnectedApp: ' + e.getMessage());
                SObject publishedEvent = createAndPublishPlatformEvent('Error','Error creating Connected App: ' + e.getMessage(),null);
            }
    }
    // Getting Platform Event package name if applicable
    public static String getPlatformEventNamespace(){
        String prefixName = '';
        for (String key : Schema.getGlobalDescribe().keySet()) {
            if (key.endsWith('connectedappevent__e')) {
                prefixName = key;
                prefixName = prefixName.replace('connectedappevent__e', '');
                break;
            }
        }
        System.debug('prefixName'+prefixName);
        return prefixName;
    }
    //Method to Create Platform Event
    public static SObject createAndPublishPlatformEvent(String status, String message, Id connectedAppId) {
        String eventApiName = 'ConnectedAppEvent__e';
        String prefixName = getPlatformEventNamespace();
        
        if (String.isNotBlank(prefixName)) {
            eventApiName = prefixName + 'ConnectedAppEvent__e';
        }
        System.debug('eventApiName'+eventApiName);
        SObject event = Schema.getGlobalDescribe().get(eventApiName).newSObject();
        
        String statusField = String.isNotBlank(prefixName) ? prefixName + 'Status__c' : 'Status__c';
        String messageField = String.isNotBlank(prefixName) ? prefixName + 'Message__c' : 'Message__c';
        String connectedAppField = String.isNotBlank(prefixName) ? prefixName + 'ConnectedApp_Id__c' : 'ConnectedApp_Id__c';
        
        System.debug('statusField'+statusField);
        System.debug('messageField'+messageField);
        System.debug('connectedAppField'+connectedAppField);
        
        // Dynamically set fields
        event.put(statusField, status);
        event.put(messageField, message);
        event.put(connectedAppField, connectedAppId);
        
        Database.SaveResult result = EventBus.publish(event);
        
        if (!result.isSuccess()) {
            for (Database.Error err : result.getErrors()) {
                System.debug('Error publishing event: ' + err.getStatusCode() + ' - ' + err.getMessage());
            }
        }
        
        return event;
    }
}