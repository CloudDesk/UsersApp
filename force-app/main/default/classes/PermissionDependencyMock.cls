public class PermissionDependencyMock implements HttpCalloutMock {
    private Map<String, String> queryToResponseMap;    
    private static final String PermDependency_Query = 'SELECT Id, Permission, RequiredPermission FROM PermissionDependency ';
    private static final String permDependency_Where_Query = 'AND PermissionType = \'Object Permission\' AND RequiredPermissionType = \'Object Permission\'';
    private static final String Null_Response = '{"size": 0, "totalSize": 0, "done": true, "queryLocator": null, ' +
                '"entityTypeName": "PermissionDependency", "records": []}';
    public PermissionDependencyMock() {
        queryToResponseMap = new Map<String, String>();
        setupDefaultMockResponses();
    }
    
    // Method to add custom responses for specific test scenarios
    public void addCustomResponse(String query, String response) {
        queryToResponseMap.put(normalizeQuery(query), response);
    }
    
    private void setupDefaultMockResponses() {
        // Account initial query response
        String accountQuery = PermDependency_Query +
            'WHERE (Permission LIKE \'%Account%\' OR RequiredPermission LIKE \'%Account%\') ' +
            permDependency_Where_Query;
            
        String accountResponse = '{"size": 3, "totalSize": 3, "done": true, "queryLocator": null, ' +
            '"entityTypeName": "PermissionDependency", "records": [' +
            '{"attributes": {"type": "PermissionDependency", "url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/001"}, ' +
            '"Id": "001", "Permission": "Account<read>", "RequiredPermission": "Contact<read>"},' +
            '{"attributes": {"type": "PermissionDependency", "url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/002"}, ' +
            '"Id": "002", "Permission": "Account<edit>", "RequiredPermission": "Contact<edit>"},' +
            '{"attributes": {"type": "PermissionDependency", "url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/002"}, ' +
            '"Id": "003", "Permission": "Plan_History__C<read>", "RequiredPermission": "Account<read>"}' +
            ']}';
        
        // Contact parent query response (empty)
        String contactParentQuery = PermDependency_Query +
            'WHERE Permission IN (\'Contact<read>\') ' +
            permDependency_Where_Query;
            
        String contactResponse = Null_Response;
		String planHistoryQuery = PermDependency_Query+
            'WHERE RequiredPermission IN (\'Plan_History__c<read>\') ' +
            permDependency_Where_Query;
            
        String planHistoryResponse = Null_Response;

		    
        queryToResponseMap.put(normalizeQuery(accountQuery), accountResponse);
        queryToResponseMap.put(normalizeQuery(contactParentQuery), contactResponse);
        queryToResponseMap.put(normalizeQuery(planHistoryQuery), planHistoryResponse);
    }
    
    private String normalizeQuery(String query) {
        return query.replaceAll('\\s+', ' ').toLowerCase().trim();
    }
    
    private String extractQueryParam(String endpoint) {
        Integer queryIndex = endpoint.indexOf('?q=');
        if (queryIndex != -1) {
            String encodedQuery = endpoint.substring(queryIndex + 3);
            return EncodingUtil.urlDecode(encodedQuery, 'UTF-8');
        }
        return '';
    }
    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        
        String query = normalizeQuery(extractQueryParam(req.getEndpoint()));
        String responseBody = queryToResponseMap.get(query);
        
        if (responseBody == null) {
            responseBody = Null_Response;
        }
        
        res.setBody(responseBody);
        return res;
    }
}