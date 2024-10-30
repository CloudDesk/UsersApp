//This Method is Used to Create Permission Set and its related Object Permissions field Permissions, User Permissions and Tab setting;
//This Class referred In LWC - ManagePermissionSetCreate

Public without Sharing class ManagePermissionSetCreateServer {
	// This Method is used to check the dublicate Permission label and Api Name
    @AuraEnabled(cacheable=true)
  	Public Static Boolean duplicatePermissionSetCheck(String label,String apiName) 
    {
    	return [SELECT COUNT() FROM PermissionSet WHERE Label = :label OR Name = :apiName LIMIT 1] > 0;
  	}
    // This Method is used to get the user License based on userId
    @AuraEnabled(cacheable = true)
    Public Static Map<String, List<Map<String,String>>> getUserLicenseForUser(String userId) {
        Map<String,List<Map<String,String>>> userLicenseMap = new Map <String,List<Map<String,String>>>();

        List<User> userWithLicenseList = [SELECT Profile.UserLicense.Id, Profile.UserLicense.Name, Profile.UserLicense.MasterLabel FROM User WHERE Id =: userId LIMIT 1];

        if (!userWithLicenseList.isEmpty()) {
            User userWithLicense = userWithLicenseList[0];
            Map < String, String > recordMap = new Map < String, String > {'Id' => userWithLicense.Profile.UserLicense.Id,
                'Name' => userWithLicense.Profile.UserLicense.Name,'MasterLabel' => userWithLicense.Profile.UserLicense.MasterLabel};
			userLicenseMap.put('UserLicense', new List<Map<String,String>> {recordMap});
        }
        System.debug('userLicenseMap: ' + userLicenseMap);
        return userLicenseMap;
    }
//This Method is used to fetch the Users based on UserLicense/PermissioSetLicense
  @AuraEnabled(cacheable = true)
    Public Static List<User> getUsersBasedOnLicenseName(String licenseName) {
        List<User> userList = new List<User>();
        if (String.isBlank(licenseName)) {
            return [SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE IsActive = TRUE];
        }
        List<UserLicense> userLicList = [SELECT Id, Name FROM UserLicense WHERE Name =: licenseName LIMIT 1];

        if (!userLicList.isEmpty()) {
            return [SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE IsActive = TRUE AND Profile.UserLicenseId =: userLicList[0].Id];
        } else {
            Set<Id> assigneeIds = new Set<Id>();
            for (PermissionSetLicenseAssign permSetLic: [SELECT AssigneeId FROM PermissionSetLicenseAssign WHERE PermissionSetLicense.DeveloperName =: licenseName]) {
                assigneeIds.add(permSetLic.AssigneeId);
            }
            if (!assigneeIds.isEmpty()) {
                return [SELECT Id, Name, Username, Profile.Name, Profile.UserLicense.Name FROM User WHERE IsActive = TRUE AND Id IN: assigneeIds];
            }
        }
        return userList;
    }
  //This Method is used to intiate Create new permissionSet Based on Profile changes with Object or Field or RecordType or User or Tab Permissions
   @AuraEnabled
    Public Static PermissionSet createNewPermissionSet(Map<String,Object> newPermSet, List<Id> userIds,
        Map<String, Map<String, Boolean>> objectPermissionsMap,
        List<PermissionAnalyzerObjectServer.FieldPermissionUpdateWrapper> fieldPerms,String objName, String updateType, String tabToUpdate, Map<String, Boolean> userToUpdate,List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> recTypeToUpdate){
            System.debug('newPermSet'+newPermSet);
            System.debug('userIds'+userIds);
            System.debug('objectPermissionsMap'+objectPermissionsMap);
            System.debug('fieldPerms'+fieldPerms);
            System.debug('objName'+objName);
            System.debug('updateType'+updateType);
            System.debug('tabToUpdate'+tabToUpdate);
            System.debug('userToUpdate'+userToUpdate);
            System.debug('recTypeToUpdate'+recTypeToUpdate);
            String permSetId;  
            if(updateType == 'Obj' || updateType == 'User'){
                system.debug('Obj type' + updateType);
                permSetId = PermissionSetManager.createPermissionSet(newPermSet,userIds);                
             }
            if(updateType == 'Obj'){
                if(permSetId != null && permSetId != ''){
                        PermissionAnalyzerObjectServer.updateObjAndFieldInitiation(objectPermissionsMap,fieldPerms,permSetId,objName,'');
                  } 
            }
            if(updateType == 'User'){
                if(permSetId != null && permSetId != ''){
                        UserPermissionAnalyzerServer.updateUserPermissionsforProfOrPermSetOrMuteGroups(permSetId,'',userToUpdate);
                  } 
            }
            if(updateType == 'Tab'){
                permSetId = createPermissionSetWithTabsAndUsers(newPermSet,tabToUpdate,userIds);
            }
            if(updateType == 'RecordType'){
                permSetId = createPermissionSetWithRecordTypeAndUsers(newPermSet,recTypeToUpdate,userIds);
            }
	   return [SELECT Id,Name, NamespacePrefix, IsCustom, Description, PermissionSetGroupId, ProfileId, Type,
               Profile.Name,Profile.UserType, Profile.Description, Profile.UserLicense.Name, 
               License.Name, Label FROM PermissionSet WHERE Id =: permSetId];  
    }
    //This Method is the helper method to deal create PermissionSet With TabSettings
    @AuraEnabled(cacheable=false)
    Public Static String createPermissionSetWithTabsAndUsers(Map<String, Object> permSetToCreate,  String tabSettingsJson, List<Id> userids) {
        system.debug('Method createPermissionSetWithTabsAndUsers Caaled');
        UserAccessManager instance = new UserAccessManager();
        String persetapi;
        List<MetadataService.PermissionSet> persetToInsert = new List<MetadataService.PermissionSet>();
        MetadataService.PermissionSet insertPerset = new MetadataService.PermissionSet();
        insertPerset.fullName = ((String) permSetToCreate.get('Name')).replaceAll(' ', '_');
        insertPerset.label = (String) permSetToCreate.get('Label');
        insertPerset.description = (String) permSetToCreate.get('Description');
        insertPerset.license = (String) permSetToCreate.get('License');
        insertPerset.hasActivationRequired = (Boolean) permSetToCreate.get('hasActivationRequired');
        persetToInsert.add(insertPerset);

    	if (!persetToInsert.isEmpty()) {
        try {
            MetadataService.UpsertResult[] results = (MetadataService.UpsertResult[]) instance.service.upsertMetadata(persetToInsert);
            for (MetadataService.UpsertResult upsertResult : results) {
                persetapi = upsertResult.fullName;
                if (!upsertResult.success) {
                    for (MetadataService.Error error : upsertResult.errors) {
                        System.debug('Error: ' + error.message + ' Status Code: ' + error.statusCode);
                        throw new AuraHandledException('Error inserting Permission Set: ' + error.message);
                    }
                } else {
                    System.debug('Permission Set Inserted successfully for: ' + upsertResult.fullName);                    
                }
            }
        } catch (Exception e) {
            System.debug('Error Inserting Permission Set: ' + e.getMessage());
            throw new AuraHandledException('Error inserting Permission Set: ' + e.getMessage());
        }
    }
        System.debug('tabSettingsJson: ' + tabSettingsJson);
        List<Map<String, String>> rawList = (List<Map<String, String>>) JSON.deserialize(tabSettingsJson, List<Map<String, String>>.class);
        List<TabPermissionAnalyzerServer.TabSettingsWrapper> tabSettings = new List<TabPermissionAnalyzerServer.TabSettingsWrapper>();
        for (Map<String, String> item : rawList) {
            for (String tabName : item.keySet()) {
                String visibility = item.get(tabName); 
                TabPermissionAnalyzerServer.TabSettingsWrapper wrapper = new TabPermissionAnalyzerServer.TabSettingsWrapper();
                wrapper.tab = tabName;
                wrapper.visibility = visibility;
                tabSettings.add(wrapper);
            }
        }
        System.debug('tabSettings: ' + tabSettings);
        List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata(
            'PermissionSet', new List<String>{ persetapi }).getRecords();    
        MetadataService.PermissionSet permissionSet;
        if (permissionSets.size() > 0) {
            permissionSet = permissionSets[0];
            if (permissionSet.tabSettings == null) {
                permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();
            }
            // Collect tabs to remove
            Set<String> tabsToRemove = new Set<String>();
            for (TabPermissionAnalyzerServer.TabSettingsWrapper tabSettingWrapper : tabSettings) {
                String tabName = tabSettingWrapper.tab;
                String visibility = tabSettingWrapper.visibility;    
                if (visibility == null) {
                    tabsToRemove.add(tabName);
                } else {
                    Boolean tabFound = false;
                    for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
                        if (existingTabSetting.tab == tabName) {
                            existingTabSetting.visibility = visibility;
                            tabFound = true;
                            break;
                        }
                    }
                    // Add new tab setting if not found
                    if (!tabFound) {
                        MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                        newTabSetting.tab = tabName;
                        newTabSetting.visibility = visibility;
                        permissionSet.tabSettings.add(newTabSetting);
                    }
                }
            }
            // Remove tabs with null visibility
            List<MetadataService.PermissionSetTabSetting> updatedTabSettings = new List<MetadataService.PermissionSetTabSetting>();
            for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
                if (!tabsToRemove.contains(existingTabSetting.tab)) {
                    updatedTabSettings.add(existingTabSetting);
                }
            }
            permissionSet.tabSettings = updatedTabSettings;
        } else {
            permissionSet = new MetadataService.PermissionSet();
            permissionSet.fullName = persetapi;
            permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();
    
            for (TabPermissionAnalyzerServer.TabSettingsWrapper tabSettingWrapper : tabSettings) {
                if (tabSettingWrapper.visibility != null) {
                    MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                    newTabSetting.tab = tabSettingWrapper.tab;
                    newTabSetting.visibility = tabSettingWrapper.visibility;
                    permissionSet.tabSettings.add(newTabSetting);
                }
            }
        }
        // Update the PermissionSet metadata with tab settings
        System.debug('permissionSet' +permissionSet);
		System.debug('permissionSet.tabSettings'+permissionSet.tabSettings);
        MetadataService.SaveResult[] updateResults = instance.service.updateMetadata(new List<MetadataService.Metadata>{ permissionSet });
        for (MetadataService.SaveResult result : updateResults) {
            System.debug('Update Result id: ' + result.fullName);
            System.debug('Status: ' + result.success);
            if (!result.success) {
                for (MetadataService.Error error : result.errors) {
                    System.debug('Error: ' + error.message);
                }
            }
        } 
        // Step 3: Query the inserted Permission Set
        PermissionSet persetId = [SELECT Id, Name FROM PermissionSet WHERE Name = :persetapi LIMIT 1];
        system.debug('persetId'+persetId);
        // Step 4: Assign Users to the Permission Set
        List<PermissionSetAssignment> permSetAssignments = new List<PermissionSetAssignment>();
        for (Id userId : userids) {
            PermissionSetAssignment permSetAssignment = new PermissionSetAssignment();
            permSetAssignment.AssigneeId = userId;
            permSetAssignment.PermissionSetId = persetId.Id;
            permSetAssignments.add(permSetAssignment);
        }
        try {
            insert permSetAssignments;
            System.debug('Permission set assignments successfully created.');
        } catch (DmlException e) {
            System.debug('Error occurred while assigning permission set: ' + e.getMessage());
            throw new AuraHandledException('Error occurred while assigning permission set: ' + e.getMessage());
        }
        return persetId.Id;
    }
    
    Private Static Void handleUpsertResults(MetadataService.UpsertResult[] results) {
        for (MetadataService.UpsertResult result: results) {
            if (!result.success) {
                throw new AuraHandledException('Error inserting Permission Set: ' + result.errors[0].message);
            }
        }
    }
    
    Private Static Void handleException(String message, Exception e) {
        System.debug(message + ': ' + e.getMessage());
        throw new AuraHandledException(message + ': ' + e.getMessage());
    }
    //This Method is the helper method to deal create PermissionSet with RecordType
    Public Static String createPermissionSetWithRecordTypeAndUsers(Map<String, Object> newPermSet,
      List<PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper> recTypeToUpdate,List <String> userIds) {
        System.debug('Method createPermissionSetWithRecordTypeAndUsers Called');
        UserAccessManager instance = new UserAccessManager();
        String permSetApi = ((String) newPermSet.get('Name')).replaceAll(' ', '_');
        // Step 1: Create Permission Set
        MetadataService.PermissionSet insertPermSet = createPermissionSet(newPermSet);
        try {
            MetadataService.UpsertResult[] results = (MetadataService.UpsertResult[]) instance.service.upsertMetadata(new List<MetadataService.PermissionSet> {
                insertPermSet
            });
            handleUpsertResults(results);
        } catch (Exception e) {
            handleException('Error inserting Permission Set', e);
        }
        // Step 2: Update Record Type Visibilities
        MetadataService.PermissionSet permissionSet = getPermissionSet(instance, permSetApi);
        updateRecordTypeVisibilities(permissionSet, recTypeToUpdate);
        try {
            MetadataService.SaveResult[] saveResults = instance.service.updateMetadata(new List < MetadataService.Metadata > {permissionSet});
            handleSaveResults(saveResults);
        } catch (Exception e) {
            handleException('Error updating Permission Set record type visibility', e);
        }
        // Step 3: Assign Users to the Permission Set
        List<PermissionSet> permSetId = [SELECT Id FROM PermissionSet WHERE Name = :permSetApi LIMIT 1];
		if (!permSetId.isEmpty()) {
    		// Proceed only if a PermissionSet was found
    		assignUsersToPermissionSet(permSetId[0].Id, userIds);
    		return permSetId[0].Id; // Return the Id of the found PermissionSet
		} else {
    		System.debug('No Permission Set found with the name: ' + permSetApi);
    		throw new AuraHandledException('Permission Set not found: ' + permSetApi);
		}
    }
    
    Private Static MetadataService.PermissionSet createPermissionSet(Map < String, Object > permSetToCreate) {
        MetadataService.PermissionSet permSet = new MetadataService.PermissionSet();
        permSet.fullName = ((String) permSetToCreate.get('Name')).replaceAll(' ', '_');
        permSet.label = (String) permSetToCreate.get('Label');
        permSet.description = (String) permSetToCreate.get('Description');
        permSet.license = (String) permSetToCreate.get('License');
        permSet.hasActivationRequired = (Boolean) permSetToCreate.get('hasActivationRequired');
        return permSet;
    }
    
    Private Static Void assignUsersToPermissionSet(Id permSetId, List < Id > userIds) {
        List < PermissionSetAssignment > permSetAssignments = new List < PermissionSetAssignment > ();
        for (Id userId: userIds) {
            permSetAssignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permSetId));
        }

        try {
            insert permSetAssignments;
        } catch (DmlException e) {
            handleException('Error occurred while assigning permission set', e);
        }
    }

    Private Static MetadataService.PermissionSet getPermissionSet(UserAccessManager instance, String permSetApiName) {
       List<MetadataService.PermissionSet> permissionSets = (List <MetadataService.PermissionSet>) instance.service.readMetadata('PermissionSet', new List<String> {
            permSetApiName}).getRecords();
        MetadataService.PermissionSet permissionSet = (permissionSets.isEmpty()) ? new MetadataService.PermissionSet() : permissionSets[0];
		if (permissionSets.isEmpty()) {
    		permissionSet.fullName = permSetApiName; // Set fullName after instantiation
		}
		if (permissionSet.recordTypeVisibilities == null) {            
    		permissionSet.recordTypeVisibilities = new List<MetadataService.PermissionSetRecordTypeVisibility>();
		}
			return permissionSet;
    	}

    Private Static Void updateRecordTypeVisibilities(MetadataService.PermissionSet permissionSet, List < PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper > recTypeToUpdate) {
        Map <String,MetadataService.PermissionSetRecordTypeVisibility> existingVisibilities = new Map <String,MetadataService.PermissionSetRecordTypeVisibility>();
        for (MetadataService.PermissionSetRecordTypeVisibility visibility: permissionSet.recordTypeVisibilities) {
            existingVisibilities.put(visibility.recordType, visibility);
        }
        for (PermissionAnalyzerRecordTypeServer.RecordTypeUpdateWrapper recUpdate: recTypeToUpdate) {
            MetadataService.PermissionSetRecordTypeVisibility visibility = existingVisibilities.get(recUpdate.RecordType);
            if (visibility == null) {
                visibility = new MetadataService.PermissionSetRecordTypeVisibility();
                visibility.recordType = recUpdate.RecordType;
                permissionSet.recordTypeVisibilities.add(visibility);
            }
            visibility.visible = recUpdate.Visible;
        }
    }

    Private Static Void handleSaveResults(MetadataService.SaveResult[] results) {
        for (MetadataService.SaveResult result: results) {
            if (!result.success) {
                throw new AuraHandledException('Error updating Permission Set: ' + result.errors[0].message);
            }
        }
    }
    
}