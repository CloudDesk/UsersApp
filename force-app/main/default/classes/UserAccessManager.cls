Public without sharing Class UserAccessManager {
    @AuraEnabled(cacheable=true)
  public static Map<String, String> getSessionInfo() {
      String sessionId = UserInfo.getSessionId();
      String sessionUrl = System.Url.getOrgDomainUrl().toExternalForm();
      
      Map<String, String> sessionInfo = new Map<String, String>();
      sessionInfo.put('sessionId', sessionId);
      sessionInfo.put('sessionUrl', sessionUrl);
      
      return sessionInfo;
  }
    Public permissionPartnerSoapSforceCom.Soap partnerConnection;
    Public MetadataService.MetadataPort service;
    User_Access_Credential__mdt userAccessCredMetadata = new User_Access_Credential__mdt();
    
    // Constructor to initialize Metadata Service
    Public UserAccessManager() {
        if (Schema.sObjectType.User_Access_Credential__mdt.isAccessible()) {
          userAccessCredMetadata = [Select User_Name__c, Password__c  from User_Access_Credential__mdt Where DeveloperName='Standard' Limit 1];
        }
        String username = userAccessCredMetadata.User_Name__c;
        String password = userAccessCredMetadata.Password__c;

        try {
            initializeConnections(username, password);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Login failed: ' + e.getMessage());
        }
    }

    // Private method to initialize connections
    Private Void initializeConnections(String username, String password) {
        partnerConnection = new permissionPartnerSoapSforceCom.Soap();
        permissionPartnerSoapSforceCom.LoginResult sessionInfo = partnerConnection.login(username, password);

        setupPartnerConnection(sessionInfo);
        setupMetadataService(sessionInfo);
    }

    // Setup partner connection
    Private Void setupPartnerConnection(permissionPartnerSoapSforceCom.LoginResult sessionInfo) {
        system.debug('sessionInfo.serverUrl'+sessionInfo.serverUrl);
        partnerConnection.SessionHeader = new permissionPartnerSoapSforceCom.SessionHeader_element();
        partnerConnection.SessionHeader.sessionId = UserInfo.getSessionId();//sessionInfo.sessionId;
        partnerConnection.endpoint_x = sessionInfo.serverUrl;
    }

    // Setup metadata service
    Private Void setupMetadataService(permissionPartnerSoapSforceCom.LoginResult sessionInfo) {
      
        service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();//sessionInfo.sessionId;
        service.CallOptions = new MetadataService.CallOptions_element();
        service.timeout_x = 120000;
    }
}