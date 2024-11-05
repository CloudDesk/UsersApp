//This class is used to Handling tab setting permissions For Profile And PermissionSet.
//This Class referred In LWC --> tabPermissionAnalyzer
Public with sharing Class TabPermissionAnalyzerServer {
//This Method is used to retrieve TabSettings Permissions for Profile Or Permission, Try to Combine with TabDefinition for Name and label
	@AuraEnabled
    Public Static List < Map < String, Object >> getProfileOrPermSetTabVisibility(List < String > profileOrPermissionSetName, String typeProfileOrPermissionSet) {
     List<Map<String, Object>> profileTabSettingVisibilityResult = new List<Map<String, Object>>();
        Map<String, String> tabVisibilitiesofProfileOrPermissionSet = new Map<String,String>();
        if(typeProfileOrPermissionSet == 'Profile'){
            tabVisibilitiesofProfileOrPermissionSet = tabVisibilityRetrieverForProfile(profileOrPermissionSetName);
         }else{
            tabVisibilitiesofProfileOrPermissionSet = tabVisibilityRetrieverForPermissionSet(profileOrPermissionSetName);
        }
        List<TabDefinition> tabDefList = [SELECT id, Name, Label FROM TabDefinition ORDER BY Label ASC Limit 50000];
        system.debug('tabDefList' + tabDefList);
        if (!tabDefList.isEmpty()) {
          for (TabDefinition tabDef : tabDefList) {
            Map<String, Object> tabSettingMap = new Map<String, Object>();
            tabSettingMap.put('Label', tabDef.Label);
            tabSettingMap.put('Name', tabDef.Name);
            tabSettingMap.put('Visibility', tabVisibilitiesofProfileOrPermissionSet.get(tabDef.Name));
            profileTabSettingVisibilityResult.add(tabSettingMap);
          }
        }
        System.debug('tabSettingMap' + profileTabSettingVisibilityResult);
        return profileTabSettingVisibilityResult;
  }
//This is helper method to fetch the permissions of TabSetting for Profile Using MetaAPI
  @AuraEnabled
  Public Static Map < String, String > tabVisibilityRetrieverForProfile(List < String > profileNames) {
      UserAccessManager instance = new UserAccessManager();
      Map < String, String > tabVisibilityMap = new Map < String, String > ();
      try {
          List < MetadataService.Profile > profiles = (List < MetadataService.Profile > ) instance.service.readMetadata('Profile', profileNames).getRecords();

          if (profiles != null && !profiles.isEmpty()) {
              for (MetadataService.Profile prof: profiles) {
                  if (prof.tabVisibilities != null) {
                      for (MetadataService.ProfileTabVisibility tabVisibility: prof.tabVisibilities) {
                          tabVisibilityMap.put(tabVisibility.tab, tabVisibility.visibility);
                      }
                  }
              }
          }
      } catch (Exception e) {
          handleException('Error retrieving tab visibility: ', e);
      }
      System.debug('Tab visibility settings: ' + tabVisibilityMap);
      return tabVisibilityMap;
  }
    
  Private Static void handleException(String message, Exception e) {
    String fullMessage = e == null ? message : message + ': ' + e.getMessage();
    System.debug(LoggingLevel.ERROR, fullMessage);
    throw new AuraHandledException(fullMessage);
  }
//This is helper method to fetch the permissions of TabSetting for PermissionSet Using MetaAPI	
  @AuraEnabled
  Public Static Map < String, String > tabVisibilityRetrieverForPermissionSet(List < String > permissionSetNames) {
      UserAccessManager instance = new UserAccessManager();
      Map < String, String > tabVisibilityMap = new Map < String, String > ();
      try {
          List < MetadataService.PermissionSet > permissionSets = (List < MetadataService.PermissionSet > ) instance.service.readMetadata('PermissionSet', permissionSetNames).getRecords();

          if (permissionSets != null && !permissionSets.isEmpty()) {
              for (MetadataService.PermissionSet permSet: permissionSets) {
                  if (permSet.tabSettings != null) {
                      for (MetadataService.PermissionSetTabSetting tabSetting: permSet.tabSettings) {
                          tabVisibilityMap.put(tabSetting.tab, tabSetting.visibility);
                      }
                  }
              }
          }
      } catch (Exception e) {
          handleException('Error retrieving tab visibility: ', e);
      }
      System.debug('Tab visibility settings: ' + tabVisibilityMap);
      return tabVisibilityMap;
  }
//This is Methos Used to updated TabVIsibility for Profile Using MetadataAPI
    Public class TabSettingsWrapper {
        Public String tab;
    	Public String visibility;
	
    Public TabSettingsWrapper(String tab, String visibility) {
        this.tab = tab;
        this.visibility = visibility;
    }
	 public TabSettingsWrapper() {
        // Initialize fields if necessary
        this.tab = '';
        this.visibility = '';
    }
}
//This is the Method Used to Update TabVisibiltity For PermissionSet Deserialize and call an update method
  @AuraEnabled
  Public Static List < TabSettingsWrapper > updatePermissionSetTabVisibilities(String tabSettingsJson, String persetname) {
      List < Map < String, String >> tabSettingRawList = (List < Map < String, String >> ) JSON.deserialize(tabSettingsJson, List < Map < String, String >> .class);
      List < TabSettingsWrapper > tabVisibilityWrapper = new List < TabSettingsWrapper > ();
      for (Map < String, String > item: tabSettingRawList) {
          for (String tabName: item.keySet()) {
              tabVisibilityWrapper.add(new TabSettingsWrapper(tabName, item.get(tabName)));
          }
      }
      System.debug('tabSettings: ' + tabVisibilityWrapper);
      return helperUpdateClassForPermissionset(tabVisibilityWrapper, persetname);
  }
    @AuraEnabled
  Public Static List < TabSettingsWrapper > helperUpdateClassForPermissionset(List < TabSettingsWrapper > tabSettingsResult, String persetname) {
      UserAccessManager instance = new UserAccessManager();
      List < MetadataService.PermissionSet > permissionSets = (List < MetadataService.PermissionSet > ) instance.service.readMetadata('PermissionSet', new List < String > {
          persetname
      }).getRecords();

      MetadataService.PermissionSet permissionSet = permissionSets.isEmpty() ? new MetadataService.PermissionSet() : permissionSets[0];
	  if (permissionSets.isEmpty()) {
    	permissionSet.fullName = persetname;
	  }

      Map < String, MetadataService.PermissionSetTabSetting > tabSettingsMap = new Map < String, MetadataService.PermissionSetTabSetting > ();
      if (permissionSet.tabSettings != null) {
          for (MetadataService.PermissionSetTabSetting setting: permissionSet.tabSettings) {
              tabSettingsMap.put(setting.tab, setting);
          }
      }
      List < MetadataService.PermissionSetTabSetting > updatedTabSettings = new List < MetadataService.PermissionSetTabSetting > ();

      for (TabSettingsWrapper wrapper : tabSettingsResult) {
    	if (wrapper.visibility != null) {
        	MetadataService.PermissionSetTabSetting tabSetting;
        	if (tabSettingsMap.containsKey(wrapper.tab)) {
            	tabSetting = tabSettingsMap.get(wrapper.tab);
        	} else {
            	tabSetting = new MetadataService.PermissionSetTabSetting();
            	tabSetting.tab = wrapper.tab;
        	}
        		tabSetting.visibility = wrapper.visibility;
        		updatedTabSettings.add(tabSetting);
    	}
	}

      permissionSet.tabSettings = updatedTabSettings;
      MetadataService.SaveResult[] results = instance.service.updateMetadata(new List < MetadataService.Metadata > {
          permissionSet
      });

      for (MetadataService.SaveResult result: results) {
          if (!result.success) {
              for (MetadataService.Error error: result.errors) {
                  System.debug('Error: ' + error.message);
              }
              handleException('Failed to update PermissionSet: ' + result.errors[0].message, null);
          }
      }

      return tabSettingsResult;
  }
   //This is Methos Used to updated TabVIsibility for Profile Using MetadataAPI
  @AuraEnabled
  public static void updateProfileTabVisibilities(List < String > profileNames, List < Map < String, Object >> tabToUpdate) {
      UserAccessManager instance = new UserAccessManager();
      List < MetadataService.Profile > profilesToUpdate = new List < MetadataService.Profile > ();
      try {
          List < MetadataService.Profile > profiles = (List < MetadataService.Profile > ) instance.service.readMetadata('Profile', profileNames).getRecords();

          if (profiles != null && !profiles.isEmpty()) {
              for (MetadataService.Profile prof: profiles) {
                  MetadataService.Profile updatedProfile = new MetadataService.Profile();
                  updatedProfile.fullName = prof.fullName;
                  updatedProfile.tabVisibilities = new List < MetadataService.ProfileTabVisibility > ();

                  Map < String, MetadataService.ProfileTabVisibility > existingVisibilities = new Map < String, MetadataService.ProfileTabVisibility > ();
                  if (prof.tabVisibilities != null) {
                      for (MetadataService.ProfileTabVisibility visibility: prof.tabVisibilities) {
                          existingVisibilities.put(visibility.tab, visibility);
                      }
                  }

                  for (Map<String, Object> tab : tabToUpdate) {
                    String tabName = (String) tab.get('Name');
                    String visibility = (String) tab.get('Visibility');
                
                    MetadataService.ProfileTabVisibility tabVisibility;
                    	if (existingVisibilities.containsKey(tabName)) {
                        	tabVisibility = existingVisibilities.get(tabName);
                    	} else {
                        	tabVisibility = new MetadataService.ProfileTabVisibility();
                        	tabVisibility.tab = tabName;
                    	}
                			tabVisibility.visibility = visibility;
                    		updatedProfile.tabVisibilities.add(tabVisibility);
				}
					profilesToUpdate.add(updatedProfile);
              }

              if (!profilesToUpdate.isEmpty()) {
                  List < MetadataService.UpsertResult > results = instance.service.upsertMetadata(profilesToUpdate);
                  handleUpsertResults(results);
              }
          }
      } catch (Exception e) {
          System.debug('Error updating profiles: ' + e.getMessage());
          handleException('Error updating profiles: ', e);
      }
  }
    
    private static void handleUpsertResults(List < MetadataService.UpsertResult > results) {
      for (MetadataService.UpsertResult upsertResult: results) {
          if (!upsertResult.success) {
              String errorMessage = 'Error updating profile: ' + upsertResult.errors[0].message;
              for (MetadataService.Error error: upsertResult.errors) {
                  System.debug('Error: ' + error.message + ' Status Code: ' + error.statusCode);
                  if (error.fields != null) {
                      System.debug('Error Fields: ' + String.join(error.fields, ', '));
                  }
              }
              handleException(errorMessage, null);              
          } else {
              System.debug('Tab Setting visibilities updated successfully for: ' + upsertResult.fullName);
          }
      }
  }
}