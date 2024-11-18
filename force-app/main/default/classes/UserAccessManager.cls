public with sharing class UserAccessManager {      
      public permissionPartnerSoapSforceCom.Soap partnerConnection;
      public MetadataService.MetadataPort service;
	  User_Access_Credential__mdt userAccessMetadata = [SELECT Client_Id__c, Client_Secret__c FROM User_Access_Credential__mdt WHERE DeveloperName = 'Standard' LIMIT 1 ];
      
      // Constructor to initialize Metadata Service
      public UserAccessManager() {
          String client_id = userAccessMetadata.Client_Id__c;
          String client_secret = userAccessMetadata.Client_Secret__c;
          try {
              initializeConnections(client_id, client_secret);
          } catch (Exception e) {
              System.debug(LoggingLevel.ERROR, 'Login failed: ' + e.getMessage());
          }
      }
      // Private method to initialize connections
      private void initializeConnections(String client_id, String client_secret) {
          partnerConnection = new permissionPartnerSoapSforceCom.Soap();
          permissionPartnerSoapSforceCom.LoginResult sessionInfo = getSessionId(client_id, client_secret);
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
    
    public static PermissionPartnerSoapSforceCom.LoginResult getSessionId(String client_id, String client_secret){
        
        PermissionPartnerSoapSforceCom.LoginResult loginResult = new PermissionPartnerSoapSforceCom.LoginResult();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(System.Url.getOrgDomainUrl().toExternalForm() + '/services/oauth2/token'); 
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        String body = 'grant_type=client_credentials' +
                      '&client_id='+ client_id +
                      '&client_secret=' + client_secret;
        req.setBody(body);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String accessToken = (String) responseMap.get('access_token');
            String instanceUrl = (String) responseMap.get('instance_url');
            
            loginResult.sessionId = accessToken;
            loginResult.serverUrl = instanceUrl + '/services/Soap/u/62.0'; // Adjust version as needed
        }
        return loginResult;
    }
}