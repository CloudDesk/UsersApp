@isTest
Public class PartnerWsdl2ApexMock implements WebServiceMock  {
    Public Static string indicatorVar;
     Public Void doInvoke(
        Object stud,
        Object request,
        Map < String, Object > response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType
    ){
        Switch on indicatorVar {
            when 'DescribeTab' {
                partnerWsdl2Apex.describeAllTabsResponse_element response_x = new partnerWsdl2Apex.describeAllTabsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeTab > ();
                response.put('response_x', response_x);
            }
            when 'GroupStructureRes' {
                partnerWsdl2Apex.describeDataCategoryGroupStructuresResponse_element response_x = new partnerWsdl2Apex.describeDataCategoryGroupStructuresResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeDataCategoryGroupStructureResult > ();
                response.put('response_x', response_x);
            }
            when 'GroupResponse' {
                partnerWsdl2Apex.describeDataCategoryGroupsResponse_element response_x = new partnerWsdl2Apex.describeDataCategoryGroupsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeDataCategoryGroupResult > ();
                response.put('response_x', response_x);
            }
            when 'FindDuplicates' {
                partnerWsdl2Apex.findDuplicatesResponse_element response_x = new partnerWsdl2Apex.findDuplicatesResponse_element();
                response_x.result = new List < partnerWsdl2Apex.FindDuplicatesResult > ();
                response.put('response_x', response_x);
            }
            when 'Process' {
                partnerWsdl2Apex.processResponse_element response_x = new partnerWsdl2Apex.processResponse_element();
                response_x.result = new List < partnerWsdl2Apex.ProcessResult > ();
                response.put('response_x', response_x);
            }
            when 'DescribeGlobal' {
                partnerWsdl2Apex.describeGlobalResponse_element response_x = new partnerWsdl2Apex.describeGlobalResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeGlobalResult();
                response.put('response_x', response_x);
            }
            when 'UserInfo' {
                partnerWsdl2Apex.getUserInfoResponse_element response_x = new partnerWsdl2Apex.getUserInfoResponse_element();
                response_x.result = new partnerWsdl2Apex.GetUserInfoResult();
                response.put('response_x', response_x);
            }
            when 'GlobalTheme' {
                partnerWsdl2Apex.describeGlobalThemeResponse_element response_x = new partnerWsdl2Apex.describeGlobalThemeResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeGlobalTheme();
                response.put('response_x', response_x);
            }
            when 'ApprovalLayout' {
                partnerWsdl2Apex.describeApprovalLayoutResponse_element response_x = new partnerWsdl2Apex.describeApprovalLayoutResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeApprovalLayoutResult();
                response.put('response_x', response_x);
            }
            when 'CompactLayout' {
                partnerWsdl2Apex.describePrimaryCompactLayoutsResponse_element response_x = new partnerWsdl2Apex.describePrimaryCompactLayoutsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeCompactLayout > ();
                response.put('response_x', response_x);
            }
            when 'QueryResult' {
                partnerWsdl2Apex.queryMoreResponse_element response_x = new partnerWsdl2Apex.queryMoreResponse_element();
                response_x.result = new partnerWsdl2Apex.QueryResult();
                response.put('response_x', response_x);
            }
            when 'EntityResult' {
                partnerWsdl2Apex.describeSearchableEntitiesResponse_element response_x = new partnerWsdl2Apex.describeSearchableEntitiesResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeSearchableEntityResult > ();
                response.put('response_x', response_x);
            }
            when 'LayoutResult' {
                partnerWsdl2Apex.describeLayoutResponse_element response_x = new partnerWsdl2Apex.describeLayoutResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeLayoutResult();
                response.put('response_x', response_x);
            }
            when 'AppMenu' {
                partnerWsdl2Apex.describeAppMenuResponse_element response_x = new partnerWsdl2Apex.describeAppMenuResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeAppMenuResult();
                response.put('response_x', response_x);
            }
            when 'LeadConvert' {
                partnerWsdl2Apex.convertLeadResponse_element response_x = new partnerWsdl2Apex.convertLeadResponse_element();
                response_x.result = new List < partnerWsdl2Apex.LeadConvertResult > ();
                response.put('response_x', response_x);
            }
            when 'SobjectListView' {
                partnerWsdl2Apex.describeSObjectListViewsResponse_element response_x = new partnerWsdl2Apex.describeSObjectListViewsResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeSoqlListViewResult();
                response.put('response_x', response_x);
            }
            when 'DeleteResult' {
                partnerWsdl2Apex.deleteResponse_element response_x = new partnerWsdl2Apex.deleteResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DeleteResult > ();
                response.put('response_x', response_x);
            }
            when 'LoginResult' {
                partnerWsdl2Apex.loginResponse_element response_x = new partnerWsdl2Apex.loginResponse_element();
                response_x.result = new partnerWsdl2Apex.LoginResult();
                response.put('response_x', response_x);
            }
            when 'QueryAllResult' {
                partnerWsdl2Apex.queryAllResponse_element response_x = new partnerWsdl2Apex.queryAllResponse_element();
                response_x.result = new partnerWsdl2Apex.QueryResult();
                response.put('response_x', response_x);
            }
            when 'SaveResult' {
                partnerWsdl2Apex.updateResponse_element response_x = new partnerWsdl2Apex.updateResponse_element();
                response_x.result = new List < partnerWsdl2Apex.SaveResult > ();
                response.put('response_x', response_x);
            }
            when 'EmptyRecycleBinResult' {
                partnerWsdl2Apex.emptyRecycleBinResponse_element response_x = new partnerWsdl2Apex.emptyRecycleBinResponse_element();
                response_x.result = new List < partnerWsdl2Apex.EmptyRecycleBinResult > ();
                response.put('response_x', response_x);
            }
            when 'DescribeCompactLayoutsResult' {
                partnerWsdl2Apex.describeCompactLayoutsResponse_element response_x = new partnerWsdl2Apex.describeCompactLayoutsResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeCompactLayoutsResult();
                response.put('response_x', response_x);
            }
            when 'ChangeOwnPasswordResult' {
                partnerWsdl2Apex.changeOwnPasswordResponse_element response_x = new partnerWsdl2Apex.changeOwnPasswordResponse_element();
                response_x.result = new partnerWsdl2Apex.ChangeOwnPasswordResult();
                response.put('response_x', response_x);
            }
            when 'SoqlListViews' {
                partnerWsdl2Apex.describeSoqlListViewsResponse_element response_x = new partnerWsdl2Apex.describeSoqlListViewsResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeSoqlListViewResult();
                response.put('response_x', response_x);
            }
            when 'PathAssistantResult' {
                partnerWsdl2Apex.describePathAssistantsResponse_element response_x = new partnerWsdl2Apex.describePathAssistantsResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribePathAssistantsResult();
                response.put('response_x', response_x);
            }
            when 'AvailabeQuickAction' {
                partnerWsdl2Apex.describeAvailableQuickActionsResponse_element response_x = new partnerWsdl2Apex.describeAvailableQuickActionsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeAvailableQuickActionResult > ();
                response.put('response_x', response_x);
            }
            when 'GetDeletedResult' {
                partnerWsdl2Apex.getDeletedResponse_element response_x = new partnerWsdl2Apex.getDeletedResponse_element();
                response_x.result = new partnerWsdl2Apex.GetDeletedResult();
                response.put('response_x', response_x);
            }
            when 'DescribeTabSetResult' {
                partnerWsdl2Apex.describeTabsResponse_element response_x = new partnerWsdl2Apex.describeTabsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeTabSetResult > ();
                response.put('response_x', response_x);
            }
            when 'QuickActionTemplateResult' {
                partnerWsdl2Apex.retrieveMassQuickActionTemplatesResponse_element response_x = new partnerWsdl2Apex.retrieveMassQuickActionTemplatesResponse_element();
                response_x.result = new list < partnerWsdl2Apex.QuickActionTemplateResult > ();
                response.put('response_x', response_x);
            }
            when 'SearchResult' {
                partnerWsdl2Apex.searchResponse_element response_x = new partnerWsdl2Apex.searchResponse_element();
                response_x.result = new partnerWsdl2Apex.SearchResult();
                response.put('response_x', response_x);
            }
            when 'SendEmail' {
                partnerWsdl2Apex.sendEmailResponse_element response_x = new partnerWsdl2Apex.sendEmailResponse_element();
                response_x.result = new list < partnerWsdl2Apex.SendEmailResult > ();
                response.put('response_x', response_x);
            }
            when 'GetUpdatedResult' {
                partnerWsdl2Apex.getUpdatedResponse_element response_x = new partnerWsdl2Apex.getUpdatedResponse_element();
                response_x.result = new partnerWsdl2Apex.GetUpdatedResult();
                response.put('response_x', response_x);
            }
            when 'SendEmailMessage' {
                partnerWsdl2Apex.sendEmailMessageResponse_element response_x = new partnerWsdl2Apex.sendEmailMessageResponse_element();
                response_x.result = new list < partnerWsdl2Apex.SendEmailResult > ();
                response.put('response_x', response_x);
            }
            when 'QuickActionsForRecordType' {
                partnerWsdl2Apex.describeQuickActionsForRecordTypeResponse_element response_x = new partnerWsdl2Apex.describeQuickActionsForRecordTypeResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeQuickActionResult > ();
                response.put('response_x', response_x);
            }
            when 'RenderEmailTemplate' {
                partnerWsdl2Apex.renderEmailTemplateResponse_element response_x = new partnerWsdl2Apex.renderEmailTemplateResponse_element();
                response_x.result = new List < partnerWsdl2Apex.RenderEmailTemplateResult > ();
                response.put('response_x', response_x);
            }
            when 'UpsertResult' {
                partnerWsdl2Apex.upsertResponse_element response_x = new partnerWsdl2Apex.upsertResponse_element();
                response_x.result = new List < partnerWsdl2Apex.UpsertResult > ();
                response.put('response_x', response_x);
            }
            when 'QueryResultInt' {
                partnerWsdl2Apex.queryResponse_element response_x = new partnerWsdl2Apex.queryResponse_element();
                response_x.result = new partnerWsdl2Apex.QueryResult();
                response.put('response_x', response_x);
            }
            when 'DescribeQuickActionResult' {
                partnerWsdl2Apex.describeQuickActionsResponse_element response_x = new partnerWsdl2Apex.describeQuickActionsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeQuickActionResult > ();
                response.put('response_x', response_x);
            }
            when 'PerformQuickActions' {
                partnerWsdl2Apex.performQuickActionsResponse_element response_x = new partnerWsdl2Apex.performQuickActionsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.PerformQuickActionResult > ();
                response.put('response_x', response_x);
            }
            when 'DescribeSobjectResult' {
                partnerWsdl2Apex.describeSObjectsResponse_element response_x = new partnerWsdl2Apex.describeSObjectsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeSObjectResult > ();
                response.put('response_x', response_x);
            }
            when 'KnowledgeSettings' {
                partnerWsdl2Apex.describeKnowledgeSettingsResponse_element response_x = new partnerWsdl2Apex.describeKnowledgeSettingsResponse_element();
                response_x.result = new partnerWsdl2Apex.KnowledgeSettings();
                response.put('response_x', response_x);
            }
            when 'UndeleteResult' {
                partnerWsdl2Apex.undeleteResponse_element response_x = new partnerWsdl2Apex.undeleteResponse_element();
                response_x.result = new List < partnerWsdl2Apex.UndeleteResult > ();
                response.put('response_x', response_x);
            }
            when 'Retrieve' {
                partnerWsdl2Apex.retrieveResponse_element response_x = new partnerWsdl2Apex.retrieveResponse_element();
                response_x.result = new List < partnerSObjectWsdl2Apex.sObject_x > ();
                response.put('response_x', response_x);
            }
            when 'DescribeTheme' {
                partnerWsdl2Apex.describeThemeResponse_element response_x = new partnerWsdl2Apex.describeThemeResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeThemeResult();
                response.put('response_x', response_x);
            }
            when 'DeleteByExample' {
                partnerWsdl2Apex.deleteByExampleResponse_element response_x = new partnerWsdl2Apex.deleteByExampleResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DeleteByExampleResult > ();
                response.put('response_x', response_x);
            }
            when 'DescribeNounResult' {
                partnerWsdl2Apex.describeNounsResponse_element response_x = new partnerWsdl2Apex.describeNounsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeNounResult > ();
                response.put('response_x', response_x);
            }
            when 'FindDuplicatesResult' {
                partnerWsdl2Apex.findDuplicatesByIdsResponse_element response_x = new partnerWsdl2Apex.findDuplicatesByIdsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.FindDuplicatesResult > ();
                response.put('response_x', response_x);
            }
            when 'ExecuteListView' {
                partnerWsdl2Apex.executeListViewResponse_element response_x = new partnerWsdl2Apex.executeListViewResponse_element();
                response_x.result = new partnerWsdl2Apex.ExecuteListViewResult();
                response.put('response_x', response_x);
            }
            when 'RenderStoredEmailTemplate' {
                partnerWsdl2Apex.renderStoredEmailTemplateResponse_element response_x = new partnerWsdl2Apex.renderStoredEmailTemplateResponse_element();
                response_x.result = new partnerWsdl2Apex.RenderStoredEmailTemplateResult();
                response.put('response_x', response_x);
            }
            when 'DescribeVisualForce' {
                partnerWsdl2Apex.describeVisualForceResponse_element response_x = new partnerWsdl2Apex.describeVisualForceResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeVisualForceResult();
                response.put('response_x', response_x);
            }
            when 'DescribeSObject' {
                partnerWsdl2Apex.describeSObjectResponse_element response_x = new partnerWsdl2Apex.describeSObjectResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeSObjectResult();
                response.put('response_x', response_x);
            }
            when 'GetServerTimestamp' {
                partnerWsdl2Apex.getServerTimestampResponse_element response_x = new partnerWsdl2Apex.getServerTimestampResponse_element();
                response_x.result = new partnerWsdl2Apex.GetServerTimestampResult();
                response.put('response_x', response_x);
            }
            when 'RetrieveQuickActionTemplates' {
                partnerWsdl2Apex.retrieveQuickActionTemplatesResponse_element response_x = new partnerWsdl2Apex.retrieveQuickActionTemplatesResponse_element();
                response_x.result = new List < partnerWsdl2Apex.QuickActionTemplateResult > ();
                response.put('response_x', response_x);
            }
            when 'SetPassword' {
                partnerWsdl2Apex.setPasswordResponse_element response_x = new partnerWsdl2Apex.setPasswordResponse_element();
                response_x.result = new partnerWsdl2Apex.SetPasswordResult();
                response.put('response_x', response_x);
            }
            when 'resetPassword' {
                partnerWsdl2Apex.resetPasswordResponse_element response_x = new partnerWsdl2Apex.resetPasswordResponse_element();
                response_x.result = new partnerWsdl2Apex.ResetPasswordResult();
                response.put('response_x', response_x);
            }
            when 'DescribeSoftphoneLayout' {
                partnerWsdl2Apex.describeSoftphoneLayoutResponse_element response_x = new partnerWsdl2Apex.describeSoftphoneLayoutResponse_element();
                response_x.result = new partnerWsdl2Apex.DescribeSoftphoneLayoutResult();
                response.put('response_x', response_x);
            }
            when 'Create' {
                partnerWsdl2Apex.createResponse_element response_x = new partnerWsdl2Apex.createResponse_element();
                response_x.result = new List < partnerWsdl2Apex.SaveResult > ();
                response.put('response_x', response_x);
            }
            when 'DescribeSearchLayouts' {
                partnerWsdl2Apex.describeSearchLayoutsResponse_element response_x = new partnerWsdl2Apex.describeSearchLayoutsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeSearchLayoutResult > ();
                response.put('response_x', response_x);
            }
            when 'Merge' {
                partnerWsdl2Apex.mergeResponse_element response_x = new partnerWsdl2Apex.mergeResponse_element();
                response_x.result = new List < partnerWsdl2Apex.MergeResult > ();
                response.put('response_x', response_x);
            }
            when 'InvalidateSessions' {
                partnerWsdl2Apex.invalidateSessionsResponse_element response_x = new partnerWsdl2Apex.invalidateSessionsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.InvalidateSessionsResult > ();
                response.put('response_x', response_x);
            }
            when 'DescribeDataCategoryMappings' {
                partnerWsdl2Apex.describeDataCategoryMappingsResponse_element response_x = new partnerWsdl2Apex.describeDataCategoryMappingsResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeDataCategoryMappingResult > ();
                response.put('response_x', response_x);
            }
            when 'Logout' {
                partnerWsdl2Apex.logoutResponse_element response_x = new partnerWsdl2Apex.logoutResponse_element();
                response.put('response_x', response_x);
            }
            when 'DescribeSearchScopeOrder' {
                partnerWsdl2Apex.describeSearchScopeOrderResponse_element response_x = new partnerWsdl2Apex.describeSearchScopeOrderResponse_element();
                response_x.result = new List < partnerWsdl2Apex.DescribeSearchScopeOrderResult > ();
                response.put('response_x', response_x);
            }
        }
    }
    
}