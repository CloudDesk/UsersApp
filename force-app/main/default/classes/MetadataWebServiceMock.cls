public class MetadataWebServiceMock implements WebServiceMock{
    public void doInvoke(
        Object stub, Object request, Map<String, Object> response,
        String endpoint, String soapAction, String requestName,
        String responseNS, String responseName, String responseType) 
    {
        MetadataService metaDataService = new MetadataService();
        
        if(request instanceof MetadataService.IReadResult){            
            response.put('response_x', new MetadataService.readProfileResponse_element());
        }
        else if(request instanceof MetadataService.readMetadata_element){            
           readMetadataResponeHelper(request, response);
        }
        else if(request instanceof MetadataService.updateMetadata_element){            
            MetadataService.updateMetadataResponse_element updateResponse = updateMetadataResponseHelper(); 
            response.put('response_x', updateResponse);
        }
        else if(request instanceof  MetadataService.deleteMetadata_element){
            MetadataService.deleteMetadataResponse_element deleteResponse = new MetadataService.deleteMetadataResponse_element();
            
            MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
            deleteResult.success = true;  
            
            deleteResult.fullName = 'HCH Sales User'; 
            
            
            deleteResponse.result = new List<MetadataService.DeleteResult>{ deleteResult };
                
                // Populate the response map with the deleteResponse object
                response.put('response_x', deleteResponse);
        }
        else if(request instanceof  MetadataService.upsertMetadata_element){
            MetadataService.upsertMetadataResponse_element upsertResult = new MetadataService.upsertMetadataResponse_element();     
            
            MetadataService.UpsertResult upsResult = new MetadataService.UpsertResult();
            upsResult.created = true;
            upsResult.success = true;
            upsResult.fullName = 'Test_Sample_PermSet';
            upsertResult.result = new List<MetadataService.UpsertResult>{upsResult};
                response.put('response_x', upsertResult);
            system.debug('upsertResult >>>'+upsertResult);
        }
        else if(request instanceof permissionPartnerSoapSforceCom.login_element){
            permissionPartnerSoapSforceCom.loginResponse_element loginResp = new permissionPartnerSoapSforceCom.loginResponse_element();
            loginResp.result = new permissionPartnerSoapSforceCom.LoginResult();
            loginResp.result.sessionId = 'TESTSESSION';
            loginResp.result.serverUrl = 'https://healthcarehighways--genesys1.sandbox.lightning.force.com/';
            response.put('response_x', loginResp);
        }
        else if (request instanceof MetadataService.createMetadata_element) {
            MetadataService.createMetadataResponse_element createResponse = createMetadataResponseHelper(request);
            response.put('response_x', createResponse);
            
        }
        return;
    } 
    
    public static MetadataService.updateMetadataResponse_element updateMetadataResponseHelper(){
        MetadataService.updateMetadataResponse_element updateResponse = new MetadataService.updateMetadataResponse_element();           
        MetadataService.SaveResult updateResult = new MetadataService.SaveResult();
            Boolean isUpdateSuccessful = true; 
            if (isUpdateSuccessful) {
                updateResult.success = true;
                updateResult.fullName = 'Test_Sample';
                updateResult.errors = new List<MetadataService.Error>();
                
                updateResponse.result = new List<MetadataService.SaveResult>{ updateResult };
                    } 
            else {
                updateResult.success = false;
                updateResult.fullName = null;
                
                MetadataService.Error error = new MetadataService.Error();
                error.message = 'An error occurred while updating the metadata.';
                error.statusCode = 'INVALID_FIELD';
                updateResult.errors = new List<MetadataService.Error>{ error };
                    
                    updateResponse.result = new List<MetadataService.SaveResult>{ updateResult };
              }
        return updateResponse;
        
    }
    
    public static MetadataService.createMetadataResponse_element createMetadataResponseHelper(Object request){
        MetadataService.createMetadataResponse_element createResponse = new MetadataService.createMetadataResponse_element();
        MetadataService.createMetadata_element createRequest = (MetadataService.createMetadata_element) request;
            if (createRequest.metadata[0] instanceof MetadataService.ConnectedApp) {                
                MetadataService.SaveResult createResult = new MetadataService.SaveResult();
                createResult.success = true;
                createResult.fullName = 'Test_Connected_App';
                createResponse.result = new List<MetadataService.SaveResult>{ createResult };
                System.debug('Connected App created successfully: ' + createResult.fullName);
            }
        return createResponse;
    }
    
    public static void readMetadataResponeHelper(Object request, Map<String,Object> response){
         MetadataService.readMetadata_element readMeta = (MetadataService.readMetadata_element) request;
            if (readMeta.type_x == 'Profile') {
                MetadataService.readProfileResponse_element profileResp = new MetadataService.readProfileResponse_element();
                profileResp.result = new MetadataService.ReadProfileResult();
                
                MetadataService.Profile prof = new MetadataService.Profile();
                prof.fullName = 'HCH Sales User';
                
                // Record Type Visibilities
                MetadataService.ProfileRecordTypeVisibility recordTypeVisibility = new MetadataService.ProfileRecordTypeVisibility();
                recordTypeVisibility.recordType = 'Account.Healthplan';
                recordTypeVisibility.visible = true;
                recordTypeVisibility.default_x = false;
                prof.recordTypeVisibilities = new List<MetadataService.ProfileRecordTypeVisibility>();
                prof.recordTypeVisibilities.add(recordTypeVisibility);
                
                // Tab Visibilities
                MetadataService.ProfileTabVisibility tabSettingVisibility = new MetadataService.ProfileTabVisibility();
                tabSettingVisibility.tab = 'standard-Account';
                tabSettingVisibility.visibility = 'DefaultOn';
                if (prof.tabVisibilities == null) {
                    prof.tabVisibilities = new List<MetadataService.ProfileTabVisibility>();
                }
                prof.tabVisibilities.add(tabSettingVisibility);
                
                // Object Permissions
                MetadataService.ProfileObjectPermissions objectPermission = new MetadataService.ProfileObjectPermissions();
                objectPermission.object_x = 'Opportunity';
                objectPermission.allowCreate = true;
                objectPermission.allowRead = true;
                objectPermission.allowEdit = true;
                objectPermission.allowDelete = false;
                objectPermission.viewAllRecords = false;
                objectPermission.modifyAllRecords = false;
                prof.objectPermissions = new List<MetadataService.ProfileObjectPermissions>();
                prof.objectPermissions.add(objectPermission);
                
                // Field Permissions
                MetadataService.ProfileFieldLevelSecurity fieldPermission = new MetadataService.ProfileFieldLevelSecurity();
                fieldPermission.field = 'Opportunity.Amount';
                fieldPermission.readable = true;
                fieldPermission.editable = true;
                prof.fieldPermissions = new List<MetadataService.ProfileFieldLevelSecurity>();
                prof.fieldPermissions.add(fieldPermission);
                
                // Application Visibilities
                MetadataService.ProfileApplicationVisibility appVisibility = new MetadataService.ProfileApplicationVisibility();
                appVisibility.application = 'standard__ServiceConsole';
                appVisibility.visible = true;
                prof.applicationVisibilities = new List<MetadataService.ProfileApplicationVisibility>();
                prof.applicationVisibilities.add(appVisibility);
                
                // Class Accesses
                MetadataService.ProfileApexClassAccess classAccess = new MetadataService.ProfileApexClassAccess();
                classAccess.apexClass = 'CustomController';
                classAccess.enabled = true;
                prof.classAccesses = new List<MetadataService.ProfileApexClassAccess>();
                prof.classAccesses.add(classAccess);
                
                // Page Accesses
                MetadataService.ProfileApexPageAccess pageAccess = new MetadataService.ProfileApexPageAccess();
                pageAccess.apexPage = 'CustomPage';
                pageAccess.enabled = true;
                prof.pageAccesses = new List<MetadataService.ProfileApexPageAccess>();
                prof.pageAccesses.add(pageAccess);
                
                // User Permissions
                MetadataService.ProfileUserPermission userPermission = new MetadataService.ProfileUserPermission();
                userPermission.name = 'ViewSetup';
                userPermission.enabled = true;
                prof.userPermissions = new List<MetadataService.ProfileUserPermission>();
                prof.userPermissions.add(userPermission);
                
                // Add profile to response
                profileResp.result.records = new List<MetadataService.Profile>();
                profileResp.result.records.add(prof);
                
                response.put('response_x', profileResp);
            }
			else if (readMeta.type_x == 'ConnectedApp') {
                MetadataService.readConnectedAppResponse_element connectedAppResp = new MetadataService.readConnectedAppResponse_element();
                connectedAppResp.result = new MetadataService.ReadConnectedAppResult();
                
                MetadataService.ConnectedApp connectedApp = new MetadataService.ConnectedApp();
                connectedApp.fullName = 'Test_Connected_App';
                connectedApp.label = 'Test Connected App';
                connectedApp.contactEmail = 'test@app.com';
                connectedApp.oauthConfig = new MetadataService.ConnectedAppOauthConfig();
                connectedApp.oauthConfig.callbackUrl = 'https://test.callback.com';
                connectedApp.oauthConfig.scopes = new List<String>{ 'Api', 'Web', 'Full' };
                connectedApp.oauthConfig.consumerKey = '1234567890abcdef';
                connectedApp.oauthConfig.consumerSecret = 'abcdef1234567890';
                
                connectedAppResp.result.records = new List<MetadataService.ConnectedApp>();
                connectedAppResp.result.records.add(connectedApp);
                
                response.put('response_x', connectedAppResp);
            }
            else if(readMeta.type_x == 'PermissionSet'){
                MetadataService.readPermissionSetResponse_element permSetResp = new MetadataService.readPermissionSetResponse_element();
                permSetResp.result = new MetadataService.ReadPermissionSetResult();
                
                MetadataService.PermissionSet permissionSetMetaRecord = new MetadataService.PermissionSet();
                permissionSetMetaRecord.fullName = 'Test_Sample_PermSet';
                
                MetadataService.PermissionSetRecordTypeVisibility recordTypeVisibility = new MetadataService.PermissionSetRecordTypeVisibility();
                recordTypeVisibility.recordType = 'Account.Healthplan';
                recordTypeVisibility.visible = true;
                permissionSetMetaRecord.recordTypeVisibilities = new List<MetadataService.PermissionSetRecordTypeVisibility>();
                permissionSetMetaRecord.recordTypeVisibilities.add(recordTypeVisibility);
                
                
                MetadataService.PermissionSetTabSetting tabSettingVisibility = new MetadataService.PermissionSetTabSetting();
                tabSettingVisibility.tab= 'standard-Account';
                tabSettingVisibility.visibility= 'visible';
                if (permissionSetMetaRecord.tabSettings == null) {
                    permissionSetMetaRecord.tabSettings = new List<MetadataService.PermissionSetTabSetting>();
                }
                
                permissionSetMetaRecord.tabSettings.add(tabSettingVisibility);
                
                
                
                permSetResp.result.records = new List<MetadataService.PermissionSet>();
                permSetResp.result.records.add(permissionSetMetaRecord);
                
                response.put('response_x', permSetResp);  
            }            
    }
}