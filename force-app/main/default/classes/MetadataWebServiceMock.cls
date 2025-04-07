public class MetadataWebServiceMock implements WebServiceMock {
    public void doInvoke(
        Object stub, Object request, Map<String, Object> response,
        String endpoint, String soapAction, String requestName,
        String responseNS, String responseName, String responseType) 
    {
        if (request instanceof MetadataService.IReadResult) {
            handleReadResult(request, response);
        } else if (request instanceof MetadataService.readMetadata_element) {
            handleReadMetadata(request, response);
        } else if (request instanceof MetadataService.updateMetadata_element) {
            response.put('response_x', updateMetadataResponseHelper());
        } else if (request instanceof MetadataService.deleteMetadata_element) {
            handleDeleteMetadata(response);
        } else if (request instanceof MetadataService.upsertMetadata_element) {
            handleUpsertMetadata(response);
        } else if (request instanceof permissionPartnerSoapSforceCom.login_element) {
            handleLogin(request, response);
        } else if (request instanceof MetadataService.createMetadata_element) {
            handleCreateMetadata(request, response);
        }
    }

    private void handleReadResult(Object request, Map<String, Object> response) {
        response.put('response_x', new MetadataService.readProfileResponse_element());
    }

    private void handleReadMetadata(Object request, Map<String, Object> response) {
        MetadataService.readMetadata_element readMeta = (MetadataService.readMetadata_element) request;
        if (readMeta.type_x == 'Profile') {
            response.put('response_x', createProfileResponse());
        } else if (readMeta.type_x == 'ConnectedApp') {
            response.put('response_x', createConnectedAppResponse());
        } else if (readMeta.type_x == 'PermissionSet') {
            response.put('response_x', createPermissionSetResponse());
        }
    }

    private MetadataService.readProfileResponse_element createProfileResponse() {
        MetadataService.readProfileResponse_element profileResp = new MetadataService.readProfileResponse_element();
        profileResp.result = new MetadataService.ReadProfileResult();
        
        MetadataService.Profile prof = createProfile();
        profileResp.result.records = new List<MetadataService.Profile>{ prof };
        
        return profileResp;
    }

    private MetadataService.Profile createProfile() {
        MetadataService.Profile prof = new MetadataService.Profile();
        prof.fullName = 'HCH Sales User';

        prof.recordTypeVisibilities = new List<MetadataService.ProfileRecordTypeVisibility>{
            createRecordTypeVisibility()
        };
        prof.tabVisibilities = new List<MetadataService.ProfileTabVisibility>{
            createTabVisibility()
        };
        prof.objectPermissions = new List<MetadataService.ProfileObjectPermissions>{
            createObjectPermission()
        };
        prof.fieldPermissions = new List<MetadataService.ProfileFieldLevelSecurity>{
            createFieldPermission()
        };
        prof.applicationVisibilities = new List<MetadataService.ProfileApplicationVisibility>{
            createApplicationVisibility()
        };
        prof.classAccesses = new List<MetadataService.ProfileApexClassAccess>{
            createClassAccess()
        };
        prof.pageAccesses = new List<MetadataService.ProfileApexPageAccess>{
            createPageAccess()
        };
        prof.userPermissions = new List<MetadataService.ProfileUserPermission>{
            createUserPermission()
        };

        return prof;
    }

    private MetadataService.ProfileRecordTypeVisibility createRecordTypeVisibility() {
        MetadataService.ProfileRecordTypeVisibility recordTypeVisibility = new MetadataService.ProfileRecordTypeVisibility();
        recordTypeVisibility.recordType = 'Account.Healthplan';
        recordTypeVisibility.visible = true;
        recordTypeVisibility.default_x = false;
        return recordTypeVisibility;
    }

    private MetadataService.ProfileTabVisibility createTabVisibility() {
        MetadataService.ProfileTabVisibility tabSettingVisibility = new MetadataService.ProfileTabVisibility();
        tabSettingVisibility.tab = 'standard-Account';
        tabSettingVisibility.visibility = 'DefaultOn';
        return tabSettingVisibility;
    }

    private MetadataService.ProfileObjectPermissions createObjectPermission() {
        MetadataService.ProfileObjectPermissions objectPermission = new MetadataService.ProfileObjectPermissions();
        objectPermission.object_x = 'Opportunity';
        objectPermission.allowCreate = true;
        objectPermission.allowRead = true;
        objectPermission.allowEdit = true;
        objectPermission.allowDelete = false;
        objectPermission.viewAllRecords = false;
        objectPermission.modifyAllRecords = false;
        return objectPermission;
    }

    private MetadataService.ProfileFieldLevelSecurity createFieldPermission() {
        MetadataService.ProfileFieldLevelSecurity fieldPermission = new MetadataService.ProfileFieldLevelSecurity();
        fieldPermission.field = 'Opportunity.Amount';
        fieldPermission.readable = true;
        fieldPermission.editable = true;
        return fieldPermission;
    }

    private MetadataService.ProfileApplicationVisibility createApplicationVisibility() {
        MetadataService.ProfileApplicationVisibility appVisibility = new MetadataService.ProfileApplicationVisibility();
        appVisibility.application = 'standard__ServiceConsole';
        appVisibility.visible = true;
        return appVisibility;
    }

    private MetadataService.ProfileApexClassAccess createClassAccess() {
        MetadataService.ProfileApexClassAccess classAccess = new MetadataService.ProfileApexClassAccess();
        classAccess.apexClass = 'CustomController';
        classAccess.enabled = true;
        return classAccess;
    }

    private MetadataService.ProfileApexPageAccess createPageAccess() {
        MetadataService.ProfileApexPageAccess pageAccess = new MetadataService.ProfileApexPageAccess();
        pageAccess.apexPage = 'CustomPage';
        pageAccess.enabled = true;
        return pageAccess;
    }

    private MetadataService.ProfileUserPermission createUserPermission() {
        MetadataService.ProfileUserPermission userPermission = new MetadataService.ProfileUserPermission();
        userPermission.name = 'ViewSetup';
        userPermission.enabled = true;
        return userPermission;
    }

    private MetadataService.readConnectedAppResponse_element createConnectedAppResponse() {
        MetadataService.readConnectedAppResponse_element connectedAppResp = new MetadataService.readConnectedAppResponse_element();
        connectedAppResp.result = new MetadataService.ReadConnectedAppResult();
        
        MetadataService.ConnectedApp connectedApp = createConnectedApp();
        connectedAppResp.result.records = new List<MetadataService.ConnectedApp>{ connectedApp };
        
        return connectedAppResp;
    }

    private MetadataService.ConnectedApp createConnectedApp() {
        MetadataService.ConnectedApp connectedApp = new MetadataService.ConnectedApp();
        connectedApp.fullName = 'Test_Connected_App';
        connectedApp.label = 'Test Connected App';
        connectedApp.contactEmail = 'test@app.com';
        connectedApp.oauthConfig = createOauthConfig();
        return connectedApp;
    }

    private MetadataService.ConnectedAppOauthConfig createOauthConfig() {
        MetadataService.ConnectedAppOauthConfig oauthConfig = new MetadataService.ConnectedAppOauthConfig();
        oauthConfig.callbackUrl = 'https://test.callback.com';
        oauthConfig.scopes = new List<String>{ 'Api', 'Web', 'Full' };
        oauthConfig.consumerKey = '1234567890abcdef';
        oauthConfig.consumerSecret = 'abcdef1234567890';
        return oauthConfig;
    }

    private MetadataService.readPermissionSetResponse_element createPermissionSetResponse() {
        MetadataService.readPermissionSetResponse_element permSetResp = new MetadataService.readPermissionSetResponse_element();
        permSetResp.result = new MetadataService.ReadPermissionSetResult();
        
        MetadataService.PermissionSet permissionSet = createPermissionSet();
        permSetResp.result.records = new List<MetadataService.PermissionSet>{ permissionSet };
        
        return permSetResp;
    }

    private MetadataService.PermissionSet createPermissionSet() {
        MetadataService.PermissionSet permissionSet = new MetadataService.PermissionSet();
        permissionSet.fullName = 'Test_Sample_PermSet';
        
        permissionSet.recordTypeVisibilities = new List<MetadataService.PermissionSetRecordTypeVisibility>{
            createPermissionSetRecordTypeVisibility()
        };
        permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>{
            createPermissionSetTabSetting()
        };

        return permissionSet;
    }

    private MetadataService.PermissionSetRecordTypeVisibility createPermissionSetRecordTypeVisibility() {
        MetadataService.PermissionSetRecordTypeVisibility recordTypeVisibility = new MetadataService.PermissionSetRecordTypeVisibility();
        recordTypeVisibility.recordType = 'Account.Healthplan';
        recordTypeVisibility.visible = true;
        return recordTypeVisibility;
    }

    private MetadataService.PermissionSetTabSetting createPermissionSetTabSetting() {
        MetadataService.PermissionSetTabSetting tabSettingVisibility = new MetadataService.PermissionSetTabSetting();
        tabSettingVisibility.tab = 'standard-Account';
        tabSettingVisibility.visibility = 'visible';
        return tabSettingVisibility;
    }

    private void handleDeleteMetadata(Map<String, Object> response) {
        MetadataService.deleteMetadataResponse_element deleteResponse = new MetadataService.deleteMetadataResponse_element();
        MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
        deleteResult.success = true;
        deleteResult.fullName = 'HCH Sales User';
        deleteResponse.result = new List<MetadataService.DeleteResult>{ deleteResult };
        response.put('response_x', deleteResponse);
    }

    private void handleUpsertMetadata(Map<String, Object> response) {
        MetadataService.upsertMetadataResponse_element upsertResult = new MetadataService.upsertMetadataResponse_element();
        MetadataService.UpsertResult upsResult = new MetadataService.UpsertResult();
        upsResult.created = true;
        upsResult.success = true;
        upsResult.fullName = 'Test_Sample_PermSet';
        upsertResult.result = new List<MetadataService.UpsertResult>{ upsResult };
        response.put('response_x', upsertResult);
        System.debug('upsertResult >>>' + upsertResult);
    }

    private void handleLogin(Object request, Map<String, Object> response) {
        permissionPartnerSoapSforceCom.loginResponse_element loginResp = new permissionPartnerSoapSforceCom.loginResponse_element();
        loginResp.result = new permissionPartnerSoapSforceCom.LoginResult();
        loginResp.result.sessionId = 'TESTSESSION';
        loginResp.result.serverUrl = 'https://healthcarehighways--genesys1.sandbox.lightning.force.com/';
        response.put('response_x', loginResp);
    }

    private void handleCreateMetadata(Object request, Map<String, Object> response) {
        MetadataService.createMetadata_element createRequest = (MetadataService.createMetadata_element) request;
        if (createRequest.metadata[0] instanceof MetadataService.ConnectedApp) {
            MetadataService.createMetadataResponse_element createResponse = new MetadataService.createMetadataResponse_element();
            MetadataService.SaveResult createResult = new MetadataService.SaveResult();
            createResult.success = true;
            createResult.fullName = 'Test_Connected_App';
            createResponse.result = new List<MetadataService.SaveResult>{ createResult };
            response.put('response_x', createResponse);
            System.debug('Connected App created successfully: ' + createResult.fullName);
        }
    }

    public static MetadataService.updateMetadataResponse_element updateMetadataResponseHelper() {
        MetadataService.updateMetadataResponse_element updateResponse = new MetadataService.updateMetadataResponse_element();
        MetadataService.SaveResult updateResult = new MetadataService.SaveResult();
        Boolean isUpdateSuccessful = true;

        if (isUpdateSuccessful) {
            updateResult.success = true;
            updateResult.fullName = 'Test_Sample';
            updateResult.errors = new List<MetadataService.Error>();
        } else {
            updateResult.success = false;
            updateResult.fullName = null;
            MetadataService.Error error = new MetadataService.Error();
            error.message = 'An error occurred while updating the metadata.';
            error.statusCode = 'INVALID_FIELD';
            updateResult.errors = new List<MetadataService.Error>{ error };
        }

        updateResponse.result = new List<MetadataService.SaveResult>{ updateResult };
        return updateResponse;
    }
}