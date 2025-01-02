public with sharing class UserAccessManager {      
    public permissionPartnerSoapSforceCom.Soap partnerConnection;
    public MetadataService.MetadataPort service;
    
    // Constructor to initialize Metadata Service
    public UserAccessManager() {
        try{
            CredentialsWrapper wrapper = getUserAccessCredential();
            if(wrapper != null){
                String client_id = wrapper.clientId;
                String client_secret = wrapper.clientSecret;
                initializeConnections(client_id, client_secret);
            }
            else{
                System.debug(LoggingLevel.ERROR, 'Invalid Client Id and Client Secret. Please contact system admin');
            }            
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
    //Querying Client Id and Client Secret
    public static CredentialsWrapper getUserAccessCredential(){        
        String prefixName = getUserAccessCredentialNamespace();
        String query = 'SELECT ' + prefixName + 'Client_Id__c, ' + prefixName + 'Client_Secret__c FROM ' + prefixName + 'User_Access_Credentials__c';
        List<SObject> userAccessCredential = Database.query(query);
        if(userAccessCredential.size() > 0){
            String clientId = (String)userAccessCredential[0].get(prefixName+'Client_Id__c');
            String clientSecret = (String)userAccessCredential[0].get(prefixName+'Client_Secret__c');
            return new CredentialsWrapper(clientId, clientSecret);
        }     
        return null;
    }
    // Getting custom setting's package name if applicable
    @AuraEnabled
    public static String getUserAccessCredentialNamespace(){
        String prefixName = '';
        for (String key : Schema.getGlobalDescribe().keySet()) {
            if (key.endsWith('user_access_credentials__c')) {
                prefixName = key;
                prefixName = prefixName.replace('user_access_credentials__c', '');
                break;
            }
        }
        return prefixName;
    }
    public class CredentialsWrapper{
        public String clientId {get;set;}
        public String clientSecret {get;set;}
        public CredentialsWrapper(String client_id, String client_secret){
            this.clientId = client_id;
            this.clientSecret = client_secret;
        }
    }
    // Getting access token with Client Id & Client Secret
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
            loginResult.serverUrl = instanceUrl + '/services/Soap/u/62.0';
        }
        return loginResult;
    }
}