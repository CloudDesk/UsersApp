//This Method is user to Fetch RecordType Permissions or Profile/Permissionset
//Used in LWC Component ==> PermissionAnalyzerRecordType

Public without Sharing Class PermissionAnalyzerRecordTypeServer {  
  Public permissionPartnerSoapSforceCom.Soap partnerConnection;
  Public MetadataService.MetadataPort service;
    
  Public Class getRecTypeVisibilityResutlWrapper {
      @AuraEnabled public List<RecordType> recordTypeList { get; set; }
      @AuraEnabled public Map<String, Object> recordTypeVisibility { get; set; }
      Public getRecTypeVisibilityResutlWrapper(List<RecordType> recordTypeList,Map<string, Object> recordTypeVisibility){
          this.recordTypeList = recordTypeList;
          this.recordTypeVisibility = recordTypeVisibility != null? recordTypeVisibility: new Map<String, Object>();
      }
  }
  //This Method used to Dynamically called the RecordType Visibility for profil and PermissionSet    
  @AuraEnabled(cacheable = true)
  public static getRecTypeVisibilityResutlWrapper getRecTypeVisibilityForProfileAndPermSet(
      String objName,
      String permissionSetId,
      String profileOrPermissionSetType,
      List < String > profileOrPermSetName
  ) {
      Map < String, Object > recordTypeVisibility = new Map < String, Object > ();

      if (String.isNotBlank(permissionSetId)) {
          try {
              recordTypeVisibility = profileOrPermissionSetType == 'Profile' ?
                  getRecordTypeVisibilityForProfile(profileOrPermSetName, objName) :
                  getRecordTypeVisibilityForPermSet(profileOrPermSetName, objName);
          } catch (Exception e) {
            handleException('An error occurred while fetching recordType visibility: ', e);
          }
      }

      List < RecordType > recordTypes = [
          SELECT Id, Name, DeveloperName, NamespacePrefix
          FROM RecordType
          WHERE SobjectType =: objName limit 50000
      ];

      return new getRecTypeVisibilityResutlWrapper(recordTypes, recordTypeVisibility);
  }
  //This Method is used to Fetch RecordType Visibility for Profile
  @AuraEnabled
  public static Map <String,Object> getRecordTypeVisibilityForProfile(List < String > profileNames, String sObjName) {
      UserAccessManager instance = new UserAccessManager();
      Map <String,Object> profileRecTypeMap = new Map < String, Object > ();
      try {
          List < MetadataService.Profile > profiles = (List < MetadataService.Profile > ) instance.service.readMetadata('Profile', profileNames).getRecords();
          if (profiles != null) {
              for (MetadataService.Profile prof: profiles) {
                  if (prof.recordTypeVisibilities != null) {
                      for (MetadataService.ProfileRecordTypeVisibility visibility: prof.recordTypeVisibilities) {
                          String recordType = visibility.recordType;
                          if (recordType.startsWith(sObjName + '.') || recordType.startsWith('PersonAccount.')) {
                              profileRecTypeMap.put(recordType, new Map < String, Object > {
                                  'RecordType' => recordType,
                                  'Visible' => visibility.visible,
                                  'Default_x' => visibility.default_x
                              });
                          }
                      }
                  }
              }
          }
      } catch (Exception e) {
          handleException('An error occurred while fetching RecordType Permissions through Profile: ', e);
      }
      System.debug('profileRecTypeMap: ' + profileRecTypeMap);
      return profileRecTypeMap;
  }
  //This Method is used to Fetch RecordType Visibility for PermissionSet
  @AuraEnabled
  public static Map < String, Object > getRecordTypeVisibilityForPermSet(List < String > permissionsSetNames, String sObjName) {
      UserAccessManager instance = new UserAccessManager();
      Map < String, Object > permissionSetRecTypeMap = new Map < String, Object > ();
      try {
          List < MetadataService.PermissionSet > permissionSets = (List < MetadataService.PermissionSet > ) instance.service.readMetadata('PermissionSet', permissionsSetNames).getRecords();

          if (permissionSets != null) {
              for (MetadataService.PermissionSet permissionSet: permissionSets) {
                  if (permissionSet.recordTypeVisibilities != null) {
                      for (MetadataService.PermissionSetRecordTypeVisibility visibility: permissionSet.recordTypeVisibilities) {
                          String recordType = visibility.recordType;
                          if (recordType.startsWith(sObjName + '.') || recordType.startsWith('PersonAccount.')) {
                              permissionSetRecTypeMap.put(recordType, new Map < String, Object > {
                                  'RecordType' => recordType,
                                  'Visible' => visibility.visible
                              });
                          }
                      }
                  }
              }
          }
      } catch (Exception e) {
          handleException('An error occurred while fetching RecordType Permissions through permission Sets: ', e);
      }

      return permissionSetRecTypeMap;
  }
  
  public class RecordTypeUpdateWrapper {
      @AuraEnabled public String RecordType { get; set; }
      @AuraEnabled public Boolean Visible { get; set; }
      @AuraEnabled public String label { get; set; }
      @AuraEnabled public String developerName { get; set; }
      @AuraEnabled public Boolean Default_x { get; set; }

      public RecordTypeUpdateWrapper() {}

      public RecordTypeUpdateWrapper(String recordType, Boolean visible, String label, String developerName, Boolean default_x) {
          this.RecordType = recordType;
          this.Visible = visible;
          this.label = label;
          this.developerName = developerName;
          this.Default_x = default_x;
      }
  }
    
  //This Method used to initiate Update Process for Profile Or PermissionSet
  @AuraEnabled
  public static List<RecordTypeUpdateWrapper> updateRecordTypeVisibility(
      List<RecordTypeUpdateWrapper> recordTypeVisibility,
      List<String> profileOrPermSetNames,
      String profileOrPermissionSetType
  ) {     
      if (profileOrPermSetNames == null || profileOrPermSetNames.isEmpty()) {
          return recordTypeVisibility;
      }

      try {
          UserAccessManager instance = new UserAccessManager();  
          String metadataType = (profileOrPermissionSetType == 'Profile') ? 'Profile' : 'PermissionSet';
          
          List<MetadataService.Metadata> metadata = instance.service.readMetadata(metadataType, profileOrPermSetNames).getRecords();
          
          if (profileOrPermissionSetType == 'Profile') {
              updateRecordTypeVisibilityForProfile((List<MetadataService.Profile>)metadata, recordTypeVisibility);
          } else {
              updateRecordTypeVisibilityForPermSet(profileOrPermSetNames, recordTypeVisibility);
          }
      } catch (Exception e) {
          handleException('An error occurred while updating RecordType Permissions: ', e);
      }
      
      return recordTypeVisibility;
  }
  //This Method is used to Update Record Type Visibility for Profile
  Private Static Boolean updateRecordTypeVisibilityForProfile(List < MetadataService.Profile > profiles, List < RecordTypeUpdateWrapper > recordTypeVisibility) {
    UserAccessManager instance = new UserAccessManager();
    List < MetadataService.Profile > profilesToUpdate = new List < MetadataService.Profile > ();

    Map < String, RecordTypeUpdateWrapper > wrapperMap = new Map < String, RecordTypeUpdateWrapper > ();
    for (RecordTypeUpdateWrapper wrapper: recordTypeVisibility) {
        wrapperMap.put(wrapper.RecordType, wrapper);
    }

    for (MetadataService.Profile profile: profiles) {
        MetadataService.Profile updatedProfile = new MetadataService.Profile();
        updatedProfile.fullName = profile.fullName;
        updatedProfile.recordTypeVisibilities = new List < MetadataService.ProfileRecordTypeVisibility > ();

        Map < String, MetadataService.ProfileRecordTypeVisibility > existingVisibilities = new Map < String, MetadataService.ProfileRecordTypeVisibility > ();
        if (profile.recordTypeVisibilities != null) {
            for (MetadataService.ProfileRecordTypeVisibility visibility: profile.recordTypeVisibilities) {
                existingVisibilities.put(visibility.recordType, visibility);
            }
        }

        for (String recordType : wrapperMap.keySet()) {
   		 RecordTypeUpdateWrapper wrapper = wrapperMap.get(recordType);
    
    // Initialize visibility object
    MetadataService.ProfileRecordTypeVisibility visibility;
    if (existingVisibilities.containsKey(recordType)) {
        visibility = existingVisibilities.get(recordType);
    } else {
        visibility = new MetadataService.ProfileRecordTypeVisibility();
        visibility.recordType = recordType;  // Set recordType separately
    }

    // Set fields
    visibility.visible = wrapper.Visible != null ? wrapper.Visible : false;
    visibility.default_x = wrapper.Default_x != null ? wrapper.Default_x : false;
    
    // Add visibility to updatedProfile
    updatedProfile.recordTypeVisibilities.add(visibility);
}


        profilesToUpdate.add(updatedProfile);
    }

    List < MetadataService.UpsertResult > results = instance.service.upsertMetadata(profilesToUpdate);
    return handleUpsertResults(results);
  }
  //This Method is used to handle Profile Upsert Result  
  private static Boolean handleUpsertResults(List < MetadataService.UpsertResult > results) {
      List < String > errorMessages = new List < String > ();
      List < String > successMessages = new List < String > ();

      for (MetadataService.UpsertResult upsertResult: results) {
          if (!upsertResult.success) {
              String errorMessage = 'Error updating profile or permission set: ' + upsertResult.fullName + ' - ';
              for (MetadataService.Error error: upsertResult.errors) {
                  errorMessage += error.message + ' (Status Code: ' + error.statusCode + ')';
                  if (error.fields != null && !error.fields.isEmpty()) {
                      errorMessage += ' Fields: ' + String.join(error.fields, ', ');
                  }
              }
              errorMessages.add(errorMessage);
          } else {
              successMessages.add('Record type visibilities updated successfully for: ' + upsertResult.fullName);
          }
      }

      // Log all success messages
      for (String successMsg: successMessages) {
          System.debug(successMsg);
      }

      // If there are any errors, throw an exception with all error messages
      if (!errorMessages.isEmpty()) {
          throw new AuraHandledException(String.join(errorMessages, '\n'));
      }

      return true;
  }
  //This Method is used to Update Record Type Visibility for PermissionSet
  @AuraEnabled
  public static List < RecordTypeUpdateWrapper > updateRecordTypeVisibilityForPermSet(List < String > permissionSetNames, List < RecordTypeUpdateWrapper > recordTypeUpdates) {
      System.debug('Received recordTypeUpdates: ' + recordTypeUpdates);
      try {
          UserAccessManager instance = new UserAccessManager();

          // Create a map for quick lookup of RecordTypeUpdateWrapper by RecordType
          Map < String, RecordTypeUpdateWrapper > updateMap = new Map < String, RecordTypeUpdateWrapper > ();
          for (RecordTypeUpdateWrapper rtUpdate: recordTypeUpdates) {
              updateMap.put(rtUpdate.RecordType, rtUpdate);
          }

          // Retrieve metadata
          MetadataService.Metadata[] metadataArray = instance.service.readMetadata('PermissionSet', permissionSetNames).getRecords();
          List < MetadataService.PermissionSet > permissionSetsToUpdate = new List < MetadataService.PermissionSet > ();

          for (MetadataService.Metadata metadata: metadataArray) {
              MetadataService.PermissionSet permissionSet = (MetadataService.PermissionSet) metadata;
              if (permissionSet != null) {
                  if (permissionSet.recordTypeVisibilities == null) {
                      permissionSet.recordTypeVisibilities = new List < MetadataService.PermissionSetRecordTypeVisibility > ();
                  }

                  Map < String, MetadataService.PermissionSetRecordTypeVisibility > existingVisibilities = new Map < String, MetadataService.PermissionSetRecordTypeVisibility > ();
                  for (MetadataService.PermissionSetRecordTypeVisibility visibility: permissionSet.recordTypeVisibilities) {
                      existingVisibilities.put(visibility.recordType, visibility);
                  }

                  for (String recordType: updateMap.keySet()) {
                      RecordTypeUpdateWrapper rtUpdate = updateMap.get(recordType);
                      MetadataService.PermissionSetRecordTypeVisibility visibility;

                      if (existingVisibilities.containsKey(recordType)) {
                          visibility = existingVisibilities.get(recordType);
                          visibility.visible = rtUpdate.Visible;
                      } else {
                          visibility = new MetadataService.PermissionSetRecordTypeVisibility();
                          visibility.recordType = recordType;
                          visibility.visible = rtUpdate.Visible;
                          permissionSet.recordTypeVisibilities.add(visibility);
                      }
                  }

                  permissionSetsToUpdate.add(permissionSet);
              } else {
                  System.debug('Permission set not found in metadata retrieval.');
              }
          }

          // Update metadata
          if (!permissionSetsToUpdate.isEmpty()) {
              MetadataService.SaveResult[] saveResults = instance.service.updateMetadata(permissionSetsToUpdate);
              handleSaveResults(saveResults);
          }
      } catch (Exception e) {
          handleException('Error updating permission sets:', e);
      }
      return recordTypeUpdates;
  }

  private static void handleException(String message, Exception e) {
    System.debug(message + ': ' + e.getMessage());
    throw new AuraHandledException(message + ': ' + e.getMessage());
}

  private static void handleSaveResults(MetadataService.SaveResult[] saveResults) {
      List < String > errors = new List < String > ();
      for (MetadataService.SaveResult saveResult: saveResults) {
          if (!saveResult.success) {
              errors.add('Error updating permission set ' + saveResult.fullName + ': ' + saveResult.errors[0].message);
          } else {
              System.debug('Permission set updated successfully: ' + saveResult.fullName);
          }
      }
      if (!errors.isEmpty()) {
          throw new AuraHandledException(String.join(errors, '\n'));
      }
  }
}