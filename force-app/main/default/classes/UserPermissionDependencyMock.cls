public class UserPermissionDependencyMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);        
        String responseBody = '{'
            + '"size": 153,'
            + '"totalSize": 153,'
            + '"done": true,'
            + '"queryLocator": null,'
            + '"entityTypeName": "PermissionDependency",'
            + '"records": ['
            + '{'
                + '"attributes": {'
                    + '"type": "PermissionDependency",'
                    + '"url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/2Pd000000000000CAA"'
                + '},'
                + '"Id": "2Pd000000000000CAA",'
                + '"Permission": "EmailSingle",'
                + '"RequiredPermission": "EditTask"'
            + '},'
            + '{'
                + '"attributes": {'
                    + '"type": "PermissionDependency",'
                    + '"url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/2Pd000000000001CAA"'
                + '},'
                + '"Id": "2Pd000000000001CAA",'
                + '"Permission": "EmailMass",'
                + '"RequiredPermission": "EmailSingle"'
            + '},'
            + '{'
                + '"attributes": {'
                    + '"type": "PermissionDependency",'
                    + '"url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/2Pd000000000002CAA"'
                + '},'
                + '"Id": "2Pd000000000002CAA",'
                + '"Permission": "ExportReport",'
                + '"RequiredPermission": "RunReports"'
            + '},'
            + '{'
                + '"attributes": {'
                    + '"type": "PermissionDependency",'
                    + '"url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/2Pd000000000007CAA"'
                + '},'
                + '"Id": "2Pd000000000007CAA",'
                + '"Permission": "ManageUsers",'
                + '"RequiredPermission": "ResetPasswords"'
            + '},'
            + '{'
                + '"attributes": {'
                    + '"type": "PermissionDependency",'
                    + '"url": "/services/data/v58.0/tooling/sobjects/PermissionDependency/2Pd000000000008CAA"'
                + '},'
                + '"Id": "2Pd000000000008CAA",'
                + '"Permission": "ManageUsers",'
                + '"RequiredPermission": "ViewAllUsers"'
            + '}'
            + ']'
        + '}';        
        res.setBody(responseBody);
        return res;
    }
}