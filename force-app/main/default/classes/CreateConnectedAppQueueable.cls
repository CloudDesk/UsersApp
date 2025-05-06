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
        DateTime currentDateTime = System.now();
        String formattedDate = currentDateTime.format('yyyy_MM_dd_HH_mm_ss', 'GMT');
        
        MetadataService.ConnectedApp connectedApp = createConnectedApp(formattedDate);
        List<MetadataService.Metadata> metadataList = new List<MetadataService.Metadata>{ connectedApp };
            
            try {
                MetadataService.MetadataPort metaDataPort = getMetadataPort();
                MetadataService.SaveResult[] saveResults = metaDataPort.createMetadata(metadataList);
                
                if (!saveResults.isEmpty()) {
                    handleSaveResult(saveResults[0], formattedDate);
                }
            } catch (Exception e) {
                System.debug('Error creating ConnectedApp: ' + e.getMessage());
                createAndPublishPlatformEvent('Error', 'Error creating Connected App: ' + e.getMessage(), null);
            }
    }
    
    private MetadataService.MetadataPort getMetadataPort() {
        MetadataService.MetadataPort port = new MetadataService.MetadataPort('60.0');
        port.SessionHeader = new MetadataService.SessionHeader_element();
        port.SessionHeader.sessionId = sessionId;
        return port;
    }
    
    private MetadataService.ConnectedApp createConnectedApp(String formattedDate) {
        MetadataService.ConnectedApp connectedApp = new MetadataService.ConnectedApp();
        connectedApp.fullName = 'PermisphereConnectedApp';
        connectedApp.label = 'PermisphereConnectedApp';
        connectedApp.contactEmail = currentUserEmail;
        
        MetadataService.ConnectedAppOauthConfig oAuthConfig = new MetadataService.ConnectedAppOauthConfig();
        oAuthConfig.callbackUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/';
        oAuthConfig.scopes = new List<String>{ 'Api' };
            oAuthConfig.isClientCredentialEnabled = true;
        oAuthConfig.isAdminApproved = true;
        oAuthConfig.oauthClientCredentialUser = currentUserUsername;
        oAuthConfig.consumerKey = 'Permisphere_DefaultConsumerKey_' + formattedDate;
        oAuthConfig.consumerSecret = 'Permisphere_DefaultConsumerSecret_' + formattedDate;
        
        connectedApp.oauthConfig = oAuthConfig;
        return connectedApp;
    }
    
    private void handleSaveResult(MetadataService.SaveResult saveResult, String formattedDate) {
        if (saveResult.errors == null) {
            updateCustomSetting(formattedDate);
            List<ConnectedApplication> connectedApps = [
                SELECT Id, Name FROM ConnectedApplication WHERE Name = 'PermisphereConnectedApp' LIMIT 1
            ];
            createAndPublishPlatformEvent('Success', 'Connected App and custom setting created successfully.', connectedApps[0].Id);
        } else {
            String errorMsg = 'Metadata creation failed: ' + saveResult.errors[0].message;
            createAndPublishPlatformEvent('Error', errorMsg, null);
            EventBus.publish(new ConnectedAppEvent__e(Status__c = 'Error', Message__c = errorMsg));
        }
    }
    
    private void updateCustomSetting(String formattedDate) {
        String prefixName = UserAccessManager.getUserAccessCredentialNamespace();
        String customSettingName = prefixName + 'User_Access_Credentials__c';
        SObjectType settingType = Schema.getGlobalDescribe().get(customSettingName);
        
        if (settingType != null) {
            List<SObject> records = Database.query(
                'SELECT Id, Name, ' + prefixName + 'Client_Id__c, ' + prefixName + 'Client_Secret__c ' +
                'FROM ' + customSettingName + ' WHERE Name = \'Standard\''
            );
            
            SObject record = records.isEmpty() ? settingType.newSObject() : records[0];
            record.put('Name', 'Standard');
            record.put(prefixName + 'Client_Id__c', 'Permisphere_DefaultConsumerKey_' + formattedDate);
            record.put(prefixName + 'Client_Secret__c', 'Permisphere_DefaultConsumerSecret_' + formattedDate);
            
            if (record.get('Id') == null) {
                insert record;
            } else {
                update record;
            }
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
        return prefixName;
    }
    //Method to Create Platform Event
    public static SObject createAndPublishPlatformEvent(String status, String message, Id connectedAppId) {
        String eventApiName = 'ConnectedAppEvent__e';
        String prefixName = getPlatformEventNamespace();
        if (String.isNotBlank(prefixName)) {
            eventApiName = prefixName + 'ConnectedAppEvent__e';
        }
        SObject event = Schema.getGlobalDescribe().get(eventApiName).newSObject();
        String statusField = String.isNotBlank(prefixName) ? prefixName + 'Status__c' : 'Status__c';
        String messageField = String.isNotBlank(prefixName) ? prefixName + 'Message__c' : 'Message__c';
        String connectedAppField = String.isNotBlank(prefixName) ? prefixName + 'ConnectedApp_Id__c' : 'ConnectedApp_Id__c';
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