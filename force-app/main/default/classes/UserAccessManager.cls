Public Class UserAccessManager {
      Public permissionPartnerSoapSforceCom.Soap partnerConnection;
      Public MetadataService.MetadataPort service;
	  User_Access_Credential__mdt userAccessCredMetadata = [Select User_Name__c, Password__c  from User_Access_Credential__mdt Where DeveloperName='Standard' Limit 1];
      // Constructor to initialize Metadata Service
      Public UserAccessManager() {
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
          partnerConnection.SessionHeader.sessionId = sessionInfo.sessionId;
          partnerConnection.endpoint_x = sessionInfo.serverUrl;
      }

      // Setup metadata service
      Private Void setupMetadataService(permissionPartnerSoapSforceCom.LoginResult sessionInfo) {
          service = new MetadataService.MetadataPort();
          service.SessionHeader = new MetadataService.SessionHeader_element();
          service.SessionHeader.sessionId = sessionInfo.sessionId;
          service.CallOptions = new MetadataService.CallOptions_element();
          service.timeout_x = 120000;
      }
  }