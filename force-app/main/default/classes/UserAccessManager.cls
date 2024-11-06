public with sharing class UserAccessManager {      
    public permissionPartnerSoapSforceCom.Soap partnerConnection;
    public MetadataService.MetadataPort service;
    User_Access_Credential__mdt userAccessCredMetadata = [Select User_Name__c, Password__c  from User_Access_Credential__mdt Where DeveloperName='Standard' Limit 1];
    // Constructor to initialize Metadata Service
    public UserAccessManager() {
        String username = userAccessCredMetadata.User_Name__c;
        String password = userAccessCredMetadata.Password__c;
        try {
            initializeConnections(username, password);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Login failed: ' + e.getMessage());
        }
    }
    // Private method to initialize connections
    private void initializeConnections(String username, String password) {
        partnerConnection = new permissionPartnerSoapSforceCom.Soap();
        permissionPartnerSoapSforceCom.LoginResult sessionInfo = partnerConnection.login(username, password);
        setupPartnerConnection(sessionInfo);
        setupMetadataService(sessionInfo);
    }
    // Setup partner connection
    private void setupPartnerConnection(permissionPartnerSoapSforceCom.LoginResult sessionInfo) {
        partnerConnection.SessionHeader = new permissionPartnerSoapSforceCom.SessionHeader_element();
        partnerConnection.SessionHeader.sessionId = sessionInfo.sessionId;
        partnerConnection.endpoint_x = sessionInfo.serverUrl;
    }
    // Setup metadata service
    private void setupMetadataService(permissionPartnerSoapSforceCom.LoginResult sessionInfo) {		
        service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = sessionInfo.sessionId;
        service.CallOptions = new MetadataService.CallOptions_element();
        service.timeout_x = 120000;
    }
}