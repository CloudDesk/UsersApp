@IsTest
public class ManagePermissionSetCreateServer_Test {
    @TestSetup
    static void setupTestData() {
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
    
         List<User> userList = new List<User>();
		User testUser1 = new User(
            FirstName = 'TestNewOne',
            LastName = 'UserNewOne',
            Email = 'testuserone@example.com',
            Username = 'testuserNewone@example.com',
            Alias = 'tuone',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        User testUser2 = new User(
            FirstName = 'TestOne',
            LastName = 'UserTwo',
            Email = 'testusertwo@example.com',
            Username = 'testusertwo@example.com',
            Alias = 'tutwo',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
		
        userList.add(testUser1);
         userList.add(testUser2);
        insert userList;
        
        PermissionSet permSet = new PermissionSet();
        permSet.Label = 'New Test Permission Set';
        permSet.Name = 'New_Test_Permission_Set';
        permSet.PermissionsApiEnabled = true;
        insert permSet;
        
        PermissionSet permSet1 = new PermissionSet(Label = 'New Test Permission Set 1', Name = 'New_Test_PermSet1', PermissionsApiEnabled =true);
        PermissionSet permSet2 = new PermissionSet(Label = 'New Test Permission Set 2', Name = 'New_Test_PermSet2',PermissionsApiEnabled=true);
        insert new List<PermissionSet>{ permSet1, permSet2 };
        MutingPermissionSet  permsetMute1 = new MutingPermissionSet (MasterLabel = 'New Test Mute Permission Set 1', DeveloperName = 'New_Test_MutePermSet1');
        MutingPermissionSet  permsetMute2 = new MutingPermissionSet (MasterLabel = 'New Test Mute Permission Set 2', DeveloperName = 'New_Test_MutePermSet2');
    	insert new List<MutingPermissionSet>{ permsetMute1, permsetMute2 };
		PermissionSetGroup permSetGrp1 = new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 1', DeveloperName = 'New_Test_PermSetGrp1');
        PermissionSetGroup permSetGrp2 = new PermissionSetGroup(MasterLabel = 'New Test Permission Set Group 2', DeveloperName = 'New_Test_PermSetGrp2');
        insert new List<PermissionSetGroup>{ permSetGrp1, permSetGrp2 };
		PermissionSetGroupComponent permSetgGroupCompo1 = new PermissionSetGroupComponent(PermissionSetId=permSet2.Id, PermissionSetGroupId=permSetGrp2.Id);
        PermissionSetGroupComponent permSetgGroupCompo2 = new PermissionSetGroupComponent(PermissionSetId=permSet1.Id, PermissionSetGroupId=permSetGrp1.Id);
        PermissionSetGroupComponent permSetgGroupCompoMute1 = new PermissionSetGroupComponent(PermissionSetId=permsetMute2.Id, PermissionSetGroupId=permSetGrp2.Id);
        PermissionSetGroupComponent permSetgGroupCompoMute2 = new PermissionSetGroupComponent(PermissionSetId=permsetMute1.Id, PermissionSetGroupId=permSetGrp1.Id);
        insert new List<PermissionSetGroupComponent>{permSetgGroupCompo1,permSetgGroupCompo2,permSetgGroupCompoMute1,permSetgGroupCompoMute2};
		PermissionSetAssignment permSetAssign1 = new PermissionSetAssignment(PermissionSetId = permSet1.Id, AssigneeId = testUser1.Id);        
        PermissionSetAssignment permSetAssign2 = new PermissionSetAssignment(PermissionSetId = permSet2.Id, AssigneeId = testUser1.Id);        
        insert new List<PermissionSetAssignment>{permSetAssign1,permSetAssign2};
        PermissionSetGroup permSetGroupForUserAssign = new PermissionSetGroup(DeveloperName = 'New_Test_Permission_Set_Group_One',MasterLabel = 'New Test Permission Set Group One',Description = 'This is a test permission set group.');
        insert permSetGroupForUserAssign;
        PermissionSetAssignment permSetGrpAssignment = new PermissionSetAssignment(AssigneeId = testUser1.Id,PermissionSetGroupId  = permSetGroupForUserAssign.Id);
        insert permSetGrpAssignment;

        ObjectPermissions objPerm1 = new ObjectPermissions(
        SObjectType = 'Opportunity',
        ParentId = permSet1.Id,
        PermissionsRead = true,
        PermissionsCreate = true,
        PermissionsEdit = false,
        PermissionsDelete = false,
        PermissionsViewAllRecords = false,
        PermissionsModifyAllRecords = false
   		 );
        ObjectPermissions objPerm2 = new ObjectPermissions(
        SObjectType = 'Opportunity',
        ParentId = permSet2.Id,
        PermissionsRead = true,
        PermissionsCreate = false,
        PermissionsEdit = true,
        PermissionsDelete = true,
        PermissionsViewAllRecords = true,
        PermissionsModifyAllRecords = false
    );
        ObjectPermissions objPermMute1 = new ObjectPermissions(
        SObjectType = 'Opportunity',
        ParentId = permsetMute1.Id,
        PermissionsRead = false,
        PermissionsCreate = false,
        PermissionsEdit = false,
        PermissionsDelete = false,
        PermissionsViewAllRecords = false,
        PermissionsModifyAllRecords = true
   		 );
        ObjectPermissions objPermMute2 = new ObjectPermissions(
        SObjectType = 'Opportunity',
        ParentId = permsetMute2.Id,
        PermissionsRead = false,
        PermissionsCreate = false,
        PermissionsEdit = false,
        PermissionsDelete = false,
        PermissionsViewAllRecords = false,
        PermissionsModifyAllRecords = true
    );
    insert new List<ObjectPermissions>{ objPerm1, objPerm2,objPermMute1,objPermMute2};

        FieldPermissions fieldPerm1 = new FieldPermissions(
        SObjectType = 'Opportunity',
        Field = 'Opportunity.Eligible__c',
        ParentId = permSet1.Id,
        PermissionsRead = true,
        PermissionsEdit = false
    );
       FieldPermissions fieldPerm2 = new FieldPermissions(
        SObjectType = 'Opportunity',
        Field = 'Opportunity.Eligible__c',
        ParentId = permSet2.Id,
        PermissionsRead = true,
        PermissionsEdit = true
    );
        FieldPermissions fieldPermMute1 = new FieldPermissions(
        SObjectType = 'Opportunity',
        Field = 'Opportunity.Eligible__c',
        ParentId = permsetMute1.Id,
        PermissionsRead = false,
        PermissionsEdit = false
    );
        FieldPermissions fieldPermMute2 = new FieldPermissions(
        SObjectType = 'Opportunity',
        Field = 'Opportunity.Eligible__c',
        ParentId = permsetMute2.Id,
        PermissionsRead = false,
        PermissionsEdit = false
    );
	insert new List<FieldPermissions>{ fieldPerm1, fieldPerm2,fieldPermMute1,fieldPermMute2};
    }
    @IsTest
    Static Void duplicatePermissionSetCheck_Test(){
        Boolean result = ManagePermissionSetCreateServer.duplicatePermissionSetCheck('test perm','test_perm');
          System.assertNotEquals(true, result, 'it should not be false');
    }
    @IsTest
    Static Void getUserLicenseForUser_Test(){
        Test.StartTest();
        Map<String,List<Map<String,String>>> result = ManagePermissionSetCreateServer.getUserLicenseForUser([Select Id FROM User Where UserName= 'testuserNewone@example.com'].Id);      
        Test.StopTest();
        System.assertNotEquals(null, result, 'it should Not be null');
    }
    @IsTest
    Static Void getUsersBasedOnLicenseName_Test(){
        Test.StartTest();
         List<User> result = ManagePermissionSetCreateServer.getUsersBasedOnLicenseName('Salesforce'); 
         List<User> resultPermLicense = ManagePermissionSetCreateServer.getUsersBasedOnLicenseName('ActionPlansPsl');
         List<User> resultNull = ManagePermissionSetCreateServer.getUsersBasedOnLicenseName('');
        Test.StopTest();
          System.assertNotEquals(null, result, 'it should Not be null');
    }
    @IsTest
    Static Void createNewPermissionSet_TestWithObj(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        Map<String,Object> newPermSet = new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> 'Test Sample PermSet', 
            						'Description'=>'This is Test Sample', 'License'=>null,'hasActivationRequired'=>true};
        Map<String,Boolean> objPerm = new Map<String,Boolean>{'PermissionsRead'=>true, 'PermissionsEdit'=>true,
            'PermissionsDelete'=>true, 'PermissionsViewAllRecords'=>true,'PermissionsCreate'=>true,'PermissionsModifyAllRecords'=>true};
        Map<String, Map<String, Boolean>> objectPermMap = new Map<String, Map<String, Boolean>>{'Opportunity'=>objPerm};
        List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper> fieldPermissionWrapperList = new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{
            new PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper(
                'Opportunity.Amount', true, true, 'Amount', true, false, false
            )
        };
        PermissionSet testPermissionSet = new PermissionSet();
        testPermissionSet.Name = 'Test_Sample_PermSet';
        testPermissionSet.Label = 'Test Sample PermSet';
        insert testPermissionSet; // Insert into test database

        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        Test.StartTest();
        try{
        PermissionSet result = ManagePermissionSetCreateServer.createNewPermissionSet(newPermSet,new List<String>{testUser.Id},objectPermMap, 
                                                                                      fieldPermissionWrapperList,'Opportunity','Obj','',
                                                                                     new Map<String, Boolean>(),new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>());
          String permissionSetId = PermissionSetManager.createPermissionSet(newPermSet, new List<String>{testUser.Id});
            System.assert(false, 'Expected AuraHandledException but it was not thrown.');
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.StopTest();
         PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
    }
	    @IsTest
    Static Void createNewPermissionSet_TestWithUser(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        Map<String,Object> newPermSet = new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> 'Test Sample PermSet', 
            						'Description'=>'This is Test Sample', 'License'=>null,'hasActivationRequired'=>true};
       
        PermissionSet testPermissionSet = new PermissionSet();
        testPermissionSet.Name = 'Test_Sample_PermSet';
        testPermissionSet.Label = 'Test Sample PermSet';
        insert testPermissionSet; // Insert into test database

        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        Test.StartTest();
        try{
        PermissionSet result = ManagePermissionSetCreateServer.createNewPermissionSet(newPermSet,new List<String>{testUser.Id},new Map<String, Map<String, Boolean>>(), 
                                                                                      new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{},'Opportunity','User','',
                                                                                      new Map<String, Boolean>{'ApiEnabled'=>true,'EditTask'=>true},new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>());
          String permissionSetId = PermissionSetManager.createPermissionSet(newPermSet, new List<String>{testUser.Id});
            System.assert(false, 'Expected AuraHandledException but it was not thrown.');
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.StopTest();
         PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
    }
        @IsTest
    Static Void createNewPermissionSet_TestWithTab(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        Map<String,Object> newPermSet = new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> 'Test Sample PermSet', 
            						'Description'=>'This is Test Sample', 'License'=>null,'hasActivationRequired'=>true};
       
        PermissionSet testPermissionSet = new PermissionSet();
        testPermissionSet.Name = 'Test_Sample_PermSet';
        testPermissionSet.Label = 'Test Sample PermSet';
        insert testPermissionSet; // Insert into test database

        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        Test.StartTest();
        try{
        PermissionSet result = ManagePermissionSetCreateServer.createNewPermissionSet(newPermSet,new List<String>{testUser.Id},new Map<String, Map<String, Boolean>>(), 
                                                                                      new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{},'Opportunity','Tab','[{"standard-Account":"visible"}]',
                                                                                      new Map<String, Boolean>(),new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>());
          String permissionSetId = PermissionSetManager.createPermissionSet(newPermSet, new List<String>{testUser.Id});
            System.assert(false, 'Expected AuraHandledException but it was not thrown.');
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.StopTest();
         PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
    }
    @IsTest
    Static Void createNewPermissionSet_TestWithRecType(){
        User testUser = [SELECT Id FROM User WHERE Username = 'testuserNewone@example.com' LIMIT 1];
        Map<String,Object> newPermSet = new Map<String,Object>{'Name' => 'Test_Sample_PermSet11', 'Label'=> 'Test Sample PermSet', 
            						'Description'=>'This is Test Sample', 'License'=>null,'hasActivationRequired'=>true};
       
        PermissionSet testPermissionSet = new PermissionSet();
        testPermissionSet.Name = 'Test_Sample_PermSet';
        testPermissionSet.Label = 'Test Sample PermSet';
        insert testPermissionSet; // Insert into test database
        PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper wrapper = new PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper();
        wrapper.RecordType = 'Account.Healthplan';
        wrapper.Visible = false;
        wrapper.developerName = 'Healthplan';
        wrapper.Default_x = false;
        

        System.Test.setMock(WebServiceMock.class, new KanithaWebServiceMock());
        MetadataService metaDataService = new MetadataService();  
        Test.StartTest();
        try{
        PermissionSet result = ManagePermissionSetCreateServer.createNewPermissionSet(newPermSet,new List<String>{testUser.Id},new Map<String, Map<String, Boolean>>(), 
                                                                                      new List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper>{},'Opportunity','RecordType','',
                                                                                      new Map<String, Boolean>(),new List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper>{wrapper});
          String permissionSetId = PermissionSetManager.createPermissionSet(newPermSet, new List<String>{testUser.Id});
            System.assert(false, 'Expected AuraHandledException but it was not thrown.');
        } catch(AuraHandledException e) {
            System.assert(e.getMessage().contains('Script-thrown exception'), 'Script-thrown exception');
        }
        Test.StopTest();
         PermissionSet retrievedPermSet = [SELECT Id, Name FROM PermissionSet WHERE Name = 'Test_Sample_PermSet' LIMIT 1];
        System.assertEquals(testPermissionSet.Id, retrievedPermSet.Id, 'The created PermissionSet should be found in the query.');
    }
      
    

    
}