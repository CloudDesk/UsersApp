@isTest
public class permissionPartnerSoapSforceComMock implements WebServiceMock  {
    public static string indicatorVar;
    public void doInvoke(
        object stud,
        object request,
        map<string, object> response,
        string endpoint,
        string soapAction,
        string requestName,
        string responseNS,
        string responseName,
        string responseType
    ){
      if(indicatorVar == 'DescribeTab')
        {
            permissionPartnerSoapSforceCom.describeAllTabsResponse_element response_x  = new permissionPartnerSoapSforceCom.describeAllTabsResponse_element();
            List<permissionPartnerSoapSforceCom.DescribeTab> testDescribeTab = new list<permissionPartnerSoapSforceCom.DescribeTab>();
            response_x.result = testDescribeTab;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'GroupStructureRes')
        {
            permissionPartnerSoapSforceCom.describeDataCategoryGroupStructuresResponse_element response_x = new permissionPartnerSoapSforceCom.describeDataCategoryGroupStructuresResponse_element();
            List<permissionPartnerSoapSforceCom.DescribeDataCategoryGroupStructureResult> testGroupStructureRes = new List<permissionPartnerSoapSforceCom.DescribeDataCategoryGroupStructureResult>();
            response_x.result= testGroupStructureRes;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'GroupResponse')
        {
            permissionPartnerSoapSforceCom.describeDataCategoryGroupsResponse_element response_x = new permissionPartnerSoapSforceCom.describeDataCategoryGroupsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeDataCategoryGroupResult> testCategoryGroupResult = new list<permissionPartnerSoapSforceCom.DescribeDataCategoryGroupResult>();
            response_x.result = testCategoryGroupResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'FindDuplicates')
        {
            permissionPartnerSoapSforceCom.findDuplicatesResponse_element response_x = new permissionPartnerSoapSforceCom.findDuplicatesResponse_element();
            list<permissionPartnerSoapSforceCom.FindDuplicatesResult> testFindDuplicates = new list<permissionPartnerSoapSforceCom.FindDuplicatesResult>();
            response_x.result = testFindDuplicates;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'Process')
        {
            permissionPartnerSoapSforceCom.processResponse_element response_x = new permissionPartnerSoapSforceCom.processResponse_element();
            list<permissionPartnerSoapSforceCom.ProcessResult> testProcessResult = new list<permissionPartnerSoapSforceCom.ProcessResult>();
            response_x.result = testProcessResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'DescribeGlobal')
        {
            permissionPartnerSoapSforceCom.describeGlobalResponse_element response_x = new permissionPartnerSoapSforceCom.describeGlobalResponse_element();
            permissionPartnerSoapSforceCom.DescribeGlobalResult  testDescribeGlobal = new permissionPartnerSoapSforceCom.DescribeGlobalResult();
            response_x.result = testDescribeGlobal;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'UserInfo')
        {
            permissionPartnerSoapSforceCom.getUserInfoResponse_element response_x = new permissionPartnerSoapSforceCom.getUserInfoResponse_element();
            permissionPartnerSoapSforceCom.GetUserInfoResult  testUserInfo = new permissionPartnerSoapSforceCom.GetUserInfoResult();
            response_x.result = testUserInfo;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'GlobalTheme')
        {
            permissionPartnerSoapSforceCom.describeGlobalThemeResponse_element response_x = new permissionPartnerSoapSforceCom.describeGlobalThemeResponse_element();
            permissionPartnerSoapSforceCom.DescribeGlobalTheme  testGlobalTheme = new permissionPartnerSoapSforceCom.DescribeGlobalTheme();
            response_x.result = testGlobalTheme;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'ApprovalLayout')
        {
            permissionPartnerSoapSforceCom.describeApprovalLayoutResponse_element response_x = new permissionPartnerSoapSforceCom.describeApprovalLayoutResponse_element();
            permissionPartnerSoapSforceCom.DescribeApprovalLayoutResult  testApprovalLayout = new permissionPartnerSoapSforceCom.DescribeApprovalLayoutResult();
            response_x.result = testApprovalLayout;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'CompactLayout')
        {
            permissionPartnerSoapSforceCom.describePrimaryCompactLayoutsResponse_element response_x = new permissionPartnerSoapSforceCom.describePrimaryCompactLayoutsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeCompactLayout> testCompactLayout = new list<permissionPartnerSoapSforceCom.DescribeCompactLayout>();
            response_x.result = testCompactLayout;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'QueryResult')
        {
            permissionPartnerSoapSforceCom.queryMoreResponse_element response_x = new permissionPartnerSoapSforceCom.queryMoreResponse_element();
            permissionPartnerSoapSforceCom.QueryResult  testQueryResult = new permissionPartnerSoapSforceCom.QueryResult();
            response_x.result = testQueryResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'EntityResult')
        {
            permissionPartnerSoapSforceCom.describeSearchableEntitiesResponse_element response_x = new permissionPartnerSoapSforceCom.describeSearchableEntitiesResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeSearchableEntityResult> testEntityResult = new list<permissionPartnerSoapSforceCom.DescribeSearchableEntityResult>();
            response_x.result = testEntityResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'LayoutResult')
        {
            permissionPartnerSoapSforceCom.describeLayoutResponse_element response_x = new permissionPartnerSoapSforceCom.describeLayoutResponse_element();
            permissionPartnerSoapSforceCom.DescribeLayoutResult  testLayoutResult = new permissionPartnerSoapSforceCom.DescribeLayoutResult();
            response_x.result = testLayoutResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'AppMenu')
        {
            permissionPartnerSoapSforceCom.describeAppMenuResponse_element response_x = new permissionPartnerSoapSforceCom.describeAppMenuResponse_element();
            permissionPartnerSoapSforceCom.DescribeAppMenuResult  testAppMenu = new permissionPartnerSoapSforceCom.DescribeAppMenuResult();
            response_x.result = testAppMenu;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'LeadConvert')
        {
            permissionPartnerSoapSforceCom.convertLeadResponse_element response_x = new permissionPartnerSoapSforceCom.convertLeadResponse_element();
            list<permissionPartnerSoapSforceCom.LeadConvertResult>  testLeadConvert = new list<permissionPartnerSoapSforceCom.LeadConvertResult>();
            response_x.result = testLeadConvert;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'SobjectListView')
        {
            permissionPartnerSoapSforceCom.describeSObjectListViewsResponse_element response_x = new permissionPartnerSoapSforceCom.describeSObjectListViewsResponse_element();
            permissionPartnerSoapSforceCom.DescribeSoqlListViewResult  testSobjectListView = new permissionPartnerSoapSforceCom.DescribeSoqlListViewResult();
            response_x.result = testSobjectListView;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'DeleteResult')
        {
            permissionPartnerSoapSforceCom.deleteResponse_element response_x = new permissionPartnerSoapSforceCom.deleteResponse_element();
            list<permissionPartnerSoapSforceCom.DeleteResult>  testDeleteResult = new list<permissionPartnerSoapSforceCom.DeleteResult>();
            response_x.result = testDeleteResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'LoginResult')
        {
			if (request instanceof permissionPartnerSoapSforceCom.login_element) {
            // Create a successful login response
            permissionPartnerSoapSforceCom.loginResponse_element loginResponse = 
                new permissionPartnerSoapSforceCom.loginResponse_element();
            
            // Create the login result
            permissionPartnerSoapSforceCom.LoginResult loginResult = 
                new permissionPartnerSoapSforceCom.LoginResult();
            
            // Set the required fields
            loginResult.sessionId = 'dummy-session-id-' + System.currentTimeMillis();
            loginResult.serverUrl = 'https://test.salesforce.com/services/Soap/u/54.0';
            loginResult.metadataServerUrl = 'https://test.salesforce.com/services/Soap/m/54.0';
            loginResult.passwordExpired = false;
            loginResult.userId = UserInfo.getUserId();
            
            // Set the result in the response
            loginResponse.result = loginResult;
            
            // Put the response in the output map
            response.put('response_x', loginResponse);
        }
            
        }
        if(indicatorVar == 'QueryAllResult')
        {
            permissionPartnerSoapSforceCom.queryAllResponse_element response_x = new permissionPartnerSoapSforceCom.queryAllResponse_element();
            permissionPartnerSoapSforceCom.QueryResult  testQueryResult = new permissionPartnerSoapSforceCom.QueryResult();
            response_x.result = testQueryResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'SaveResult')
        {
            permissionPartnerSoapSforceCom.updateResponse_element response_x = new permissionPartnerSoapSforceCom.updateResponse_element();
            list<permissionPartnerSoapSforceCom.SaveResult>  testSaveResult = new list<permissionPartnerSoapSforceCom.SaveResult>();
            response_x.result = testSaveResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'EmptyRecycleBinResult')
        {
            permissionPartnerSoapSforceCom.emptyRecycleBinResponse_element response_x = new permissionPartnerSoapSforceCom.emptyRecycleBinResponse_element();
            list<permissionPartnerSoapSforceCom.EmptyRecycleBinResult>  testRecycleResult = new list<permissionPartnerSoapSforceCom.EmptyRecycleBinResult>();
            response_x.result = testRecycleResult;
            response.put('response_x', response_x);
        }        
        if(indicatorVar == 'DescribeCompactLayoutsResult')
        {
            permissionPartnerSoapSforceCom.describeCompactLayoutsResponse_element response_x = new permissionPartnerSoapSforceCom.describeCompactLayoutsResponse_element();
            permissionPartnerSoapSforceCom.DescribeCompactLayoutsResult  testDescribeCompactLayoutsResult = new permissionPartnerSoapSforceCom.DescribeCompactLayoutsResult();
            response_x.result = testDescribeCompactLayoutsResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'ChangeOwnPasswordResult')
        {
            permissionPartnerSoapSforceCom.changeOwnPasswordResponse_element response_x = new permissionPartnerSoapSforceCom.changeOwnPasswordResponse_element();
            permissionPartnerSoapSforceCom.ChangeOwnPasswordResult  testRecycleResult = new permissionPartnerSoapSforceCom.ChangeOwnPasswordResult();
            response_x.result = testRecycleResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'SoqlListViews')
        {
            permissionPartnerSoapSforceCom.describeSoqlListViewsResponse_element response_x = new permissionPartnerSoapSforceCom.describeSoqlListViewsResponse_element();
            permissionPartnerSoapSforceCom.DescribeSoqlListViewResult  testSoqlListViews = new permissionPartnerSoapSforceCom.DescribeSoqlListViewResult();
            response_x.result = testSoqlListViews;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'PathAssitantResult')
        {
            permissionPartnerSoapSforceCom.describePathAssistantsResponse_element response_x = new permissionPartnerSoapSforceCom.describePathAssistantsResponse_element();
            permissionPartnerSoapSforceCom.DescribePathAssistantsResult  testPathAssitantResult = new permissionPartnerSoapSforceCom.DescribePathAssistantsResult();
            response_x.result = testPathAssitantResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'AvailabeQuickAction')
        {
            permissionPartnerSoapSforceCom.describeAvailableQuickActionsResponse_element response_x = new permissionPartnerSoapSforceCom.describeAvailableQuickActionsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeAvailableQuickActionResult>  testAvailabeQuickAction = new list<permissionPartnerSoapSforceCom.DescribeAvailableQuickActionResult>();
            response_x.result = testAvailabeQuickAction;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'GetDeletedResult')
        {
            permissionPartnerSoapSforceCom.getDeletedResponse_element response_x = new permissionPartnerSoapSforceCom.getDeletedResponse_element();
            permissionPartnerSoapSforceCom.GetDeletedResult  testGetDeletedResult = new permissionPartnerSoapSforceCom.GetDeletedResult();
            response_x.result = testGetDeletedResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'DescribeTabSetResult')
        {
            permissionPartnerSoapSforceCom.describeTabsResponse_element response_x = new permissionPartnerSoapSforceCom.describeTabsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeTabSetResult>  testDescribeTabSetResult = new list<permissionPartnerSoapSforceCom.DescribeTabSetResult>();
            response_x.result = testDescribeTabSetResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'QuickActionTemplateResult')
        {
            permissionPartnerSoapSforceCom.retrieveMassQuickActionTemplatesResponse_element response_x = new permissionPartnerSoapSforceCom.retrieveMassQuickActionTemplatesResponse_element();
            list<permissionPartnerSoapSforceCom.QuickActionTemplateResult>  testQuickActionTemplateResult = new list<permissionPartnerSoapSforceCom.QuickActionTemplateResult>();
            response_x.result = testQuickActionTemplateResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'SearchResult')
        {
            permissionPartnerSoapSforceCom.searchResponse_element response_x = new permissionPartnerSoapSforceCom.searchResponse_element();
            permissionPartnerSoapSforceCom.SearchResult  testSearchResult = new permissionPartnerSoapSforceCom.SearchResult();
            response_x.result = testSearchResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'SendEmail')
        {
            permissionPartnerSoapSforceCom.sendEmailResponse_element response_x = new permissionPartnerSoapSforceCom.sendEmailResponse_element();
            list<permissionPartnerSoapSforceCom.SendEmailResult>  testSendEmail = new list<permissionPartnerSoapSforceCom.SendEmailResult>();
            response_x.result = testSendEmail;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'GetUpdatedResult')
        {
            permissionPartnerSoapSforceCom.getUpdatedResponse_element response_x = new permissionPartnerSoapSforceCom.getUpdatedResponse_element();
            permissionPartnerSoapSforceCom.GetUpdatedResult  testUpdatedResult = new permissionPartnerSoapSforceCom.GetUpdatedResult();
            response_x.result = testUpdatedResult;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'SendEmailMessage')
        {
            permissionPartnerSoapSforceCom.sendEmailMessageResponse_element response_x = new permissionPartnerSoapSforceCom.sendEmailMessageResponse_element();
            list<permissionPartnerSoapSforceCom.SendEmailResult>  testSendEmailMessage = new list<permissionPartnerSoapSforceCom.SendEmailResult>();
            response_x.result = testSendEmailMessage;
            response.put('response_x', response_x);
        }
        if(indicatorVar == 'QuickActionsForRecordType')
        {
            permissionPartnerSoapSforceCom.describeQuickActionsForRecordTypeResponse_element response_x = new permissionPartnerSoapSforceCom.describeQuickActionsForRecordTypeResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeQuickActionResult> testQuickActionResult = new list<permissionPartnerSoapSforceCom.DescribeQuickActionResult>();
            response_x.result = testQuickActionResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'RenderEmailTemplate')
        {
            permissionPartnerSoapSforceCom.renderEmailTemplateResponse_element response_x = new permissionPartnerSoapSforceCom.renderEmailTemplateResponse_element();
            list<permissionPartnerSoapSforceCom.RenderEmailTemplateResult> testRenderEmailTemplate = new list<permissionPartnerSoapSforceCom.RenderEmailTemplateResult>();
            response_x.result = testRenderEmailTemplate;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'UpsertResult')
        {
            permissionPartnerSoapSforceCom.upsertResponse_element response_x = new permissionPartnerSoapSforceCom.upsertResponse_element();
            list<permissionPartnerSoapSforceCom.UpsertResult> testUpsertResult = new list<permissionPartnerSoapSforceCom.UpsertResult>();
            response_x.result = testUpsertResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'QueryResultInt')
        {
            permissionPartnerSoapSforceCom.queryResponse_element response_x = new permissionPartnerSoapSforceCom.queryResponse_element();
            permissionPartnerSoapSforceCom.QueryResult testQueryResultInt = new permissionPartnerSoapSforceCom.QueryResult();
            response_x.result = testQueryResultInt;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeQuickActionResult')
        {
            permissionPartnerSoapSforceCom.describeQuickActionsResponse_element response_x = new permissionPartnerSoapSforceCom.describeQuickActionsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeQuickActionResult> testQuickActionResult = new list<permissionPartnerSoapSforceCom.DescribeQuickActionResult>();
            response_x.result = testQuickActionResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'PerformQuickActions')
        {
            permissionPartnerSoapSforceCom.performQuickActionsResponse_element response_x = new permissionPartnerSoapSforceCom.performQuickActionsResponse_element();
            list<permissionPartnerSoapSforceCom.PerformQuickActionResult> testPerformQuickAction = new list<permissionPartnerSoapSforceCom.PerformQuickActionResult>();
            response_x.result = testPerformQuickAction;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeSobjectResult')
        {
            permissionPartnerSoapSforceCom.describeSObjectsResponse_element response_x = new permissionPartnerSoapSforceCom.describeSObjectsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeSObjectResult> testDescribeSObjectResult = new list<permissionPartnerSoapSforceCom.DescribeSObjectResult>();
            response_x.result = testDescribeSObjectResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'KnowledgeSettings')
        {
            permissionPartnerSoapSforceCom.describeKnowledgeSettingsResponse_element response_x = new permissionPartnerSoapSforceCom.describeKnowledgeSettingsResponse_element();
            permissionPartnerSoapSforceCom.KnowledgeSettings testKnowledgeSettings = new permissionPartnerSoapSforceCom.KnowledgeSettings();
            response_x.result = testKnowledgeSettings;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'UndeleteResult')
        {
            permissionPartnerSoapSforceCom.undeleteResponse_element response_x = new permissionPartnerSoapSforceCom.undeleteResponse_element();
            list<permissionPartnerSoapSforceCom.UndeleteResult> testUndeleteResult = new list<permissionPartnerSoapSforceCom.UndeleteResult>();
            response_x.result = testUndeleteResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeTheme')
        {
            permissionPartnerSoapSforceCom.describeThemeResponse_element response_x = new permissionPartnerSoapSforceCom.describeThemeResponse_element();
            permissionPartnerSoapSforceCom.DescribeThemeResult testDescribeTheme = new permissionPartnerSoapSforceCom.DescribeThemeResult();
            response_x.result = testDescribeTheme;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DeleteByExample')
        {
            permissionPartnerSoapSforceCom.deleteByExampleResponse_element response_x = new permissionPartnerSoapSforceCom.deleteByExampleResponse_element();
            list<permissionPartnerSoapSforceCom.DeleteByExampleResult> testDeleteByExample = new list<permissionPartnerSoapSforceCom.DeleteByExampleResult>();
            response_x.result = testDeleteByExample;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeNounResult')
        {
            permissionPartnerSoapSforceCom.describeNounsResponse_element response_x = new permissionPartnerSoapSforceCom.describeNounsResponse_element();
            list<permissionPartnerSoapSforceCom.DescribeNounResult> testDescribeNounResult = new list<permissionPartnerSoapSforceCom.DescribeNounResult>();
            response_x.result = testDescribeNounResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'FindDuplicatesResult')
        {
            permissionPartnerSoapSforceCom.findDuplicatesByIdsResponse_element response_x = new permissionPartnerSoapSforceCom.findDuplicatesByIdsResponse_element();
            list<permissionPartnerSoapSforceCom.FindDuplicatesResult> testDuplicatesResult = new list<permissionPartnerSoapSforceCom.FindDuplicatesResult>();
            response_x.result = testDuplicatesResult;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'ExecuteListView')
        {
            permissionPartnerSoapSforceCom.executeListViewResponse_element response_x = new permissionPartnerSoapSforceCom.executeListViewResponse_element();
            permissionPartnerSoapSforceCom.ExecuteListViewResult testExecuteListView = new permissionPartnerSoapSforceCom.ExecuteListViewResult();
            response_x.result = testExecuteListView;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'RenderStoredEmailTemplate')
        {
            permissionPartnerSoapSforceCom.renderStoredEmailTemplateResponse_element response_x = new permissionPartnerSoapSforceCom.renderStoredEmailTemplateResponse_element();
            permissionPartnerSoapSforceCom.RenderStoredEmailTemplateResult testRenderStoredEmailTemplate = new permissionPartnerSoapSforceCom.RenderStoredEmailTemplateResult();
            response_x.result = testRenderStoredEmailTemplate;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeVisualForce')
        {
            permissionPartnerSoapSforceCom.describeVisualForceResponse_element response_x = new permissionPartnerSoapSforceCom.describeVisualForceResponse_element();
            permissionPartnerSoapSforceCom.DescribeVisualForceResult testDescribeVisualForce = new permissionPartnerSoapSforceCom.DescribeVisualForceResult();
            response_x.result = testDescribeVisualForce;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeSObject')
        {
            permissionPartnerSoapSforceCom.describeSObjectResponse_element response_x = new permissionPartnerSoapSforceCom.describeSObjectResponse_element();
            permissionPartnerSoapSforceCom.DescribeSObjectResult testDescribeSObject = new permissionPartnerSoapSforceCom.DescribeSObjectResult();
            response_x.result = testDescribeSObject;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'GetServerTimestamp')
        {
            permissionPartnerSoapSforceCom.getServerTimestampResponse_element response_x = new permissionPartnerSoapSforceCom.getServerTimestampResponse_element();
            permissionPartnerSoapSforceCom.GetServerTimestampResult testGetServerTimestamp = new permissionPartnerSoapSforceCom.GetServerTimestampResult();
            response_x.result = testGetServerTimestamp;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'RetrieveQuickActionTemplates')
        {
            permissionPartnerSoapSforceCom.retrieveQuickActionTemplatesResponse_element response_x = new permissionPartnerSoapSforceCom.retrieveQuickActionTemplatesResponse_element();
            list<permissionPartnerSoapSforceCom.QuickActionTemplateResult> testRetrieveQuickActionTemplates = new list<permissionPartnerSoapSforceCom.QuickActionTemplateResult>();
            response_x.result = testRetrieveQuickActionTemplates;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'SetPassword')
        {
            permissionPartnerSoapSforceCom.setPasswordResponse_element response_x = new permissionPartnerSoapSforceCom.setPasswordResponse_element();
            permissionPartnerSoapSforceCom.SetPasswordResult testSetPassword = new permissionPartnerSoapSforceCom.SetPasswordResult();
            response_x.result = testSetPassword;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'resetPassword')
        {
            permissionPartnerSoapSforceCom.resetPasswordResponse_element response_x = new permissionPartnerSoapSforceCom.resetPasswordResponse_element();
            permissionPartnerSoapSforceCom.ResetPasswordResult testResetPassword = new permissionPartnerSoapSforceCom.ResetPasswordResult();
            response_x.result = testResetPassword;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeSoftphoneLayout')
        {
            permissionPartnerSoapSforceCom.describeSoftphoneLayoutResponse_element response_x = new permissionPartnerSoapSforceCom.describeSoftphoneLayoutResponse_element();
            permissionPartnerSoapSforceCom.DescribeSoftphoneLayoutResult testDescribeSoftphoneLayout = new permissionPartnerSoapSforceCom.DescribeSoftphoneLayoutResult();
            response_x.result = testDescribeSoftphoneLayout;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'Create')
        {
            permissionPartnerSoapSforceCom.createResponse_element response_x = new permissionPartnerSoapSforceCom.createResponse_element();
            list<permissionPartnerSoapSforceCom.SaveResult> testCreate = new list<permissionPartnerSoapSforceCom.SaveResult>();
            response_x.result = testCreate;
            response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeSearchLayouts')
        {
           permissionPartnerSoapSforceCom.describeSearchLayoutsResponse_element response_x = new permissionPartnerSoapSforceCom.describeSearchLayoutsResponse_element();
           list<permissionPartnerSoapSforceCom.DescribeSearchLayoutResult> testCreate = new list<permissionPartnerSoapSforceCom.DescribeSearchLayoutResult>();
           response_x.result = testCreate;
           response.put('response_x',response_x);
        }
        if(indicatorVar == 'Merge')
        {
           permissionPartnerSoapSforceCom.mergeResponse_element response_x = new permissionPartnerSoapSforceCom.mergeResponse_element();
           list<permissionPartnerSoapSforceCom.MergeResult> testMerge = new list<permissionPartnerSoapSforceCom.MergeResult>();
           response_x.result = testMerge;
           response.put('response_x',response_x);
        }
        if(indicatorVar == 'InvalidateSessions')
        {
           permissionPartnerSoapSforceCom.invalidateSessionsResponse_element response_x = new permissionPartnerSoapSforceCom.invalidateSessionsResponse_element();
           list<permissionPartnerSoapSforceCom.InvalidateSessionsResult> testInvalidateSessions = new list<permissionPartnerSoapSforceCom.InvalidateSessionsResult>();
           response_x.result = testInvalidateSessions;
           response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeDataCategoryMappings')
        {
           permissionPartnerSoapSforceCom.describeDataCategoryMappingsResponse_element response_x = new permissionPartnerSoapSforceCom.describeDataCategoryMappingsResponse_element();
           list<permissionPartnerSoapSforceCom.DescribeDataCategoryMappingResult> testDescribeDataCategoryMappings = new list<permissionPartnerSoapSforceCom.DescribeDataCategoryMappingResult>();
           response_x.result = testDescribeDataCategoryMappings;
           response.put('response_x',response_x);
        }
        if(indicatorVar == 'Logout')
        {
           permissionPartnerSoapSforceCom.logoutResponse_element response_x = new permissionPartnerSoapSforceCom.logoutResponse_element();
           response.put('response_x',response_x);
        }
        if(indicatorVar == 'DescribeSearchScopeOrder')
        {
           permissionPartnerSoapSforceCom.describeSearchScopeOrderResponse_element response_x = new permissionPartnerSoapSforceCom.describeSearchScopeOrderResponse_element();
           list<permissionPartnerSoapSforceCom.DescribeSearchScopeOrderResult> testDescribeSearchScopeOrder = new list<permissionPartnerSoapSforceCom.DescribeSearchScopeOrderResult>();
           response_x.result = testDescribeSearchScopeOrder;
           response.put('response_x',response_x);
        }
        if(indicatorVar == 'Retrieve')
        {
            permissionPartnerSoapSforceCom.retrieveResponse_element response_x = new permissionPartnerSoapSforceCom.retrieveResponse_element();
            list<permissionSobjectPartnerSoapSforceCom.sObject_x> testRetrieve = new list<permissionSobjectPartnerSoapSforceCom.sObject_x>();
            response_x.result = testRetrieve;
            response.put('response_x',response_x);
        }
       
    }

}