//This class is used to Handling tab setting permissions For Profile And PermissionSet.
//This Class referred In LWC --> tabPermissionAnalyzer
public with sharing class TabPermissionAnalyzerServer {
    //This Method is used to retrieve TabSettings Permissions for Profile Or Permission, Try to Combine with TabDefinition for Name and label
    @AuraEnabled
    public static List < Map < String, Object >> getProfileOrPermSetTabVisibility(List < String > profileOrPermissionSetName, String typeProfileOrPermissionSet) {
        List<Map<String, Object>> profileTabSettingVisibilityResult = new List<Map<String, Object>>();
        Map<String, String> tabVisibilitiesofProfileOrPermissionSet = new Map<String,String>();
        if(typeProfileOrPermissionSet == 'Profile'){
            tabVisibilitiesofProfileOrPermissionSet = tabVisibilityRetrieverForProfile(profileOrPermissionSetName);
        }else{
            tabVisibilitiesofProfileOrPermissionSet = tabVisibilityRetrieverForPermissionSet(profileOrPermissionSetName);
        }
        List<TabDefinition> tabDefList = [SELECT id, Name, Label FROM TabDefinition ORDER BY Label ASC Limit 50000];
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
    public static Map < String, String > tabVisibilityRetrieverForProfile(List < String > profileNames) {
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
    @TestVisible
    private static void handleException(String message, Exception e) {
        String fullMessage = e == null ? message : message + ': ' + e.getMessage();
        System.debug(LoggingLevel.ERROR, fullMessage);
        throw new AuraHandledException(fullMessage);
    }
    //This is helper method to fetch the permissions of TabSetting for PermissionSet Using MetaAPI	
    @AuraEnabled
    public static Map < String, String > tabVisibilityRetrieverForPermissionSet(List < String > permissionSetNames) {
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
    public class TabSettingsWrapper {
        public String tab;
        public String visibility;
        public TabSettingsWrapper(String tab, String visibility) {
            this.tab = tab;
            this.visibility = visibility;
        }
    }
    @AuraEnabled
    Public Static List<TabSettingsWrapper> updatePermissionSetTabVisibilities(String tabSettingsJson, String persetname) {
        List<Map<String, String>> tabSettingRawList = (List<Map<String, String>>) JSON.deserialize(tabSettingsJson, List<Map<String, String>>.class);
        List<TabSettingsWrapper> tabVisibilityWrapper = new List<TabSettingsWrapper>();    
        // Convert the raw list into TabSettingsWrapper list
        for (Map<String, String> item : tabSettingRawList) {
            for (String tabName : item.keySet()) {   
                // Create the wrapper object
                tabVisibilityWrapper.add(new TabSettingsWrapper(tabName, item.get(tabName)));
            }
        }    
        System.debug('tabSettings: ' + tabVisibilityWrapper);
        return helperUpdateClassForPermissionset(tabVisibilityWrapper, persetname);
    }
    @AuraEnabled
	Public Static List<TabSettingsWrapper> helperUpdateClassForPermissionset(List<TabSettingsWrapper> tabSettingsResult,String persetname) {
   		 UserAccessManager instance = new UserAccessManager();
        List<MetadataService.PermissionSet> permissionSets = (List<MetadataService.PermissionSet>) instance.service.readMetadata('PermissionSet',new List<String>{ persetname }).getRecords();    
        MetadataService.PermissionSet permissionSet;
        if (permissionSets.size() > 0) {
            permissionSet = permissionSets[0]; 
            if (permissionSet.tabSettings == null) {
                permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();
            } 
            permissionSet.tabSettings = updateExistingHelper(permissionSet,tabSettingsResult);
        } else {
            permissionSet = new MetadataService.PermissionSet();
            permissionSet.fullName = persetname;
            permissionSet.tabSettings = new List<MetadataService.PermissionSetTabSetting>();    
            for (TabSettingsWrapper tabSettingWrapper : tabSettingsResult) {
                if (tabSettingWrapper.visibility != null) {
                    MetadataService.PermissionSetTabSetting newTabSetting = new MetadataService.PermissionSetTabSetting();
                    newTabSetting.tab = tabSettingWrapper.tab;
                    newTabSetting.visibility = tabSettingWrapper.visibility;
                    permissionSet.tabSettings.add(newTabSetting);
                }
            }
        }    
        // Update the PermissionSet metadata
        MetadataService.SaveResult[] results = instance.service.updateMetadata(new List<MetadataService.Metadata>{ permissionSet });
        handleSaveResult(results);
        return tabSettingsResult;
    }    
    //Helper Method for updating Exisiting tab Permissions
    private static List<MetadataService.PermissionSetTabSetting> updateExistingHelper(MetadataService.PermissionSet permissionSet, List<TabSettingsWrapper> tabSettingsResult){
           
        Set<String> tabsToRemove = new Set<String>();
        for (TabSettingsWrapper tabSettingWrapper : tabSettingsResult) {
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
        
        return updateExistingHelper1(permissionSet,tabsToRemove);
    }
    //Helper Method for updating Exisiting 1 tab Permissions
    private static List<MetadataService.PermissionSetTabSetting> updateExistingHelper1(MetadataService.PermissionSet permissionSet, Set<String> tabsToRemove){
        List<MetadataService.PermissionSetTabSetting> updatedTabSettings = new List<MetadataService.PermissionSetTabSetting>();
        for (MetadataService.PermissionSetTabSetting existingTabSetting : permissionSet.tabSettings) {
            if (!tabsToRemove.contains(existingTabSetting.tab)) {
                updatedTabSettings.add(existingTabSetting);
            }
        }
        return updatedTabSettings;
    }
    
    // Handling Save Results
    private static void handleSaveResult(List<MetadataService.SaveResult> saveResultList){
        for (MetadataService.SaveResult result: saveResultList) {
            if (!result.success) {
                handleErrorMessages(result.errors);
            }
        }
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
                    updatedProfile.tabVisibilities = consolidatingTabVisibilitiesToUpdate(tabToUpdate, existingVisibilities);
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
    // Collecting tab visibilities from input Tabs
    private static List<MetadataService.ProfileTabVisibility> consolidatingTabVisibilitiesToUpdate(List< Map<String, Object> > tabsToUpdate, Map < String, MetadataService.ProfileTabVisibility > existingVisibilities){
        List< MetadataService.ProfileTabVisibility > tabVisibilitiesToUpdate = new List< MetadataService.ProfileTabVisibility >();    
        for (Map<String, Object> tab : tabsToUpdate) {
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
            tabVisibilitiesToUpdate.add(tabVisibility);
        }
        return tabVisibilitiesToUpdate;
    }
    private static void handleUpsertResults(List < MetadataService.UpsertResult > results) {
        for (MetadataService.UpsertResult upsertResult: results) {
            if (!upsertResult.success) {
                handleErrorMessages(upsertResult.errors);         
            } else {
                System.debug('Tab Setting visibilities updated successfully for: ' + upsertResult.fullName);
            }
        }
    }
    // Handling result error messages
    @TestVisible
    private static void handleErrorMessages(List<MetadataService.Error> errors){
        for (MetadataService.Error error: errors) {
            System.debug('Error: ' + error.message + ' Status Code: ' + error.statusCode);
            if (error.fields != null) {
                System.debug('Error Fields: ' + String.join(error.fields, ', '));
            }
        }
        handleException('Exception: ' + errors[0].message, null);
    }
}