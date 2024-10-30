Public Class MockHttpResponseGenerator implements HttpCalloutMock {
        Private Integer statusCode;
        Private String mockType;
        
        Public MockHttpResponseGenerator(Integer statusCode, String mockType) {
            this.statusCode = statusCode;
            this.mockType = mockType;
        }
        /*
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (statusCode == 200) {
                Map<String, Object> responseBody = new Map<String, Object>();
                List<Map<String, Object>> records = new List<Map<String, Object>>();
                
                if (mockType == 'ProfileName') {
                    records.add(new Map<String, Object>{
                        'attributes' => new Map<String, Object>{'type' => 'Profile'},
                        'Id' => '00e36000000lw1MAAQ',
                        'Name' => 'Standard User',
                        'FullName' => 'Standard User'
                    });
                    responseBody.put('totalSize', records.size());
                    responseBody.put('done', true);
                    responseBody.put('records', records);
                    
                    res.setBody(JSON.serialize(responseBody));
                } 
                else if (mockType == 'CheckDependency') {
                     String jsonResponse = '{"records": [{"Id": "001xx000003DGbTAAW", "Permission": "Account<read>", "RequiredPermission": "Contact<read>"}]}';
					  res.setBody(jsonResponse);                    
                }
                else if (mockType == 'EmptyResponse') {
                    // Leave records empty
                }
            } 
            else if (statusCode == 400) {
                res.setBody(JSON.serialize(new Map<String, String>{
                    'error' => 'Bad Request'
                }));
            } 
            else {
                throw new CalloutException('Forced error for testing');
            }
            
            res.setStatusCode(statusCode);
            return res;
        }*/
    
    	Public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
    
        if (statusCode == 200) {
            res.setBody(getResponseBody());
        } else if (statusCode == 400) {
            res.setBody(JSON.serialize(new Map<String, String>{'error' => 'Bad Request'}));
        } else {
            throw new CalloutException('Forced error for testing');
        }
        
        return res;
    }
    
    Private String getResponseBody() {
        switch on mockType {
            when 'ProfileName' {
                return JSON.serialize(new Map<String, Object>{
                    'totalSize' => 1,
                    'done' => true,
                    'records' => new List<Map<String, Object>>{
                        new Map<String, Object>{
                            'attributes' => new Map<String, Object>{'type' => 'Profile'},
                            'Id' => '00e36000000lw1MAAQ',
                            'Name' => 'Standard User',
                            'FullName' => 'Standard User'
                        }
                    }
                });
            }
            when 'CheckDependency' {
                return '{"records": [{"Id": "001xx000003DGbTAAW", "Permission": "Account<read>", "RequiredPermission": "Contact<read>"}]}';
            }
            when 'EmptyResponse' {
                return JSON.serialize(new Map<String, Object>{
                    'totalSize' => 0,
                    'done' => true,
                    'records' => new List<Object>()
                });
            }
            when else {
                return '';
            }
        }
    }
    }