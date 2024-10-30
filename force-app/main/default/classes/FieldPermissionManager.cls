public class FieldPermissionManager {
    
    @AuraEnabled
    //used
    public static Map<String, List<FieldPermissions>> getFieldPermissionspsg(String persetgrpid) {
        //List<Map<String, List<FieldPermissions>>> fieldList = new List<Map<String, List<FieldPermissions>>>();
        
        List<FieldPermissions> fieldPermissions = [
            SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE Parent.PermissionSetGroupId = :persetgrpid
        ];
        
        Map<String, List<FieldPermissions>> fieldmap = new Map<String, List<FieldPermissions>>();
        
        for (FieldPermissions fie : fieldPermissions) {
            if (!fieldmap.containsKey(fie.SObjectType)) {
                fieldmap.put(fie.SObjectType, new List<FieldPermissions>());
            }
            fieldmap.get(fie.SObjectType).add(fie);
        }
        
        return fieldmap;
    }
    
    @AuraEnabled
    //used
    public static Map<String, List<fieldPermissions>> getmutingFieldPermissionspsg(String persetgrpid) {
        //List<Map<String, List<FieldPermissions>>> fieldList = new List<Map<String, List<FieldPermissions>>>();
        
        string nullValue = '%_%';
        list<PermissionSetGroupComponent> per = [
            SELECT
            id,
            PermissionSetId,
            PermissionSet.Name,
            PermissionSetGroupId,
            PermissionSetGroup.DeveloperName
            FROM PermissionSetGroupComponent
            WHERE
            PermissionSetGroupId = :persetgrpid
            AND (NOT PermissionSet.Name LIKE :nullValue)
        ];
        string ids;
        for (PermissionSetGroupComponent pe : per) {
            system.debug(pe);
            ids = pe.PermissionSetId;
        }
        
        List<MutingPermissionSet> mpsList = [
            SELECT id
            FROM MutingPermissionSet
            WHERE id = :ids
        ];
        
        ids = mpsList[0].Id;
        
        List<FieldPermissions> fieldPermissions = [
            SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :ids
        ];
        
        Map<String, List<FieldPermissions>> fieldmap = new Map<String, List<FieldPermissions>>();
        
        for (FieldPermissions fie : fieldPermissions) {
            if (!fieldmap.containsKey(fie.SObjectType)) {
                fieldmap.put(fie.SObjectType, new List<FieldPermissions>());
            }
            fieldmap.get(fie.SObjectType).add(fie);
        }
        
        return fieldmap;
    }
    
    @AuraEnabled
    //used
    public static Map<String, Map<String, Object>> getFieldDefinitionProfile(String objectName) {
        Map<String, Map<String, Object>> fieldDefMapByName = new Map<String, Map<String, Object>>();
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe();
        
        for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
            Map<String, Object> fieldDefMap = new Map<String, Object>();
            fieldDefMap.put('Label', field.getDescribe().getLabel());
            fieldDefMap.put('Name', field.getDescribe().getName());
            fieldDefMap.put(
                'isPermissionable',
                field.getDescribe().isPermissionable()
            );
            fieldDefMap.put('isCalculated', field.getDescribe().isCalculated());
            
            String fieldNameKey = objectName + '.' + field.getDescribe().getName();
            fieldDefMapByName.put(fieldNameKey, fieldDefMap);
        }
        return fieldDefMapByName;
    }
    
    @AuraEnabled
    //used
    public static ProfileObjectPermissionsWrapper getSobjectPermissionsForProfile(String permSetId,String objName) {
        List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
        List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
        //List<Map<String, Object>> recordTypeMapList = new List<Map<String, Object>>();
        Map<String, Boolean> fieldAccess = ManageUserAccessPartner.checkFieldType(
            objName
        );
        system.debug('fieldAccess' + fieldAccess);
        Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
            objName
        );
        system.debug('Before Object Permission');
        Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
        for (FieldPermissions fieldPerm : [
            SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :permSetId AND SObjectType = :objName
        ]) {
            if (fieldPerm != null) {
                fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
            }
        }
        // Debug: Check the contents of fieldPermissionsMap
        System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);
        
        // Process each field definition
        for (String fieldKey : fieldDefMapByName.keySet()) {
            if (fieldKey != null) {
                //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
                system.debug(fieldKey + ' fieldKey ' + fieldAccess.get(fieldKey));
                if (
                    (Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') &&
                    fieldAccess.get(fieldKey) == true
                ) {
                    Map<String, Object> fieldPermissionMap = new Map<String, Object>();
                    fieldPermissionMap.put('Field', fieldKey);
                    fieldPermissionMap.put(
                        'label',
                        fieldDefMapByName.get(fieldKey).get('Label')
                    );
                    
                    // Debug: Check if fieldKey is present in fieldPermissionsMap
                    System.debug('Processing fieldKey: ' + fieldKey);
                    if (fieldPermissionsMap.containsKey(fieldKey)) {
                        system.debug('inside containskey');
                        FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
                        fieldPermissionMap.put(
                            'PermissionsRead',
                            fieldPerm.PermissionsRead
                        );
                        fieldPermissionMap.put(
                            'PermissionsEdit',
                            fieldPerm.PermissionsEdit
                        );
                    } else {
                        fieldPermissionMap.put('PermissionsRead', false);
                        fieldPermissionMap.put('PermissionsEdit', false);
                    }
                    
                    fieldPermissionMap.put(
                        'hasEditAccess',
                        fieldDefMapByName.get(fieldKey).get('isCalculated')
                    );
                    fieldPermissionsMapList.add(fieldPermissionMap);
                }
            }
        }
        System.debug('check field permission map' + fieldPermissionsMapList);
        //System.debug('check recordtype permission map' + recordTypeMapList);
        return new ProfileObjectPermissionsWrapper(
            fieldPermissionsMapList,
            ManageUserAccessPartner.checkSObjType(objName),
            dependObjects
        );
    }
    
    @AuraEnabled
    //used
    public static ProfileObjectPermissionsWrapper getSobjectPermissionsForPermissionSet( String permSetId,String objName,List<String> profileNames) {
        List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
        List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
        //List<Map<String, Object>> recordTypeMapList = new List<Map<String, Object>>();
        Map<String, Boolean> fieldAccess = ManageUserAccessPartner.checkFieldType(objName);
        system.debug('fieldAccess' + fieldAccess);
        Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
            objName
        );
        system.debug('Before Object Permission');
        Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
        for (FieldPermissions fieldPerm : [
            SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE ParentId = :permSetId AND SObjectType = :objName
        ]) {
            if (fieldPerm != null) {
                fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
            }
        }
        // Debug: Check the contents of fieldPermissionsMap
        System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);
        
        // Process each field definition
        for (String fieldKey : fieldDefMapByName.keySet()) {
            if (fieldKey != null) {
                //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
                system.debug(fieldKey + ' fieldKey ' + fieldAccess.get(fieldKey));
                if (
                    (Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') &&
                    fieldAccess.get(fieldKey) == true
                ) {
                    Map<String, Object> fieldPermissionMap = new Map<String, Object>();
                    fieldPermissionMap.put('Field', fieldKey);
                    fieldPermissionMap.put(
                        'label',
                        fieldDefMapByName.get(fieldKey).get('Label')
                    );
                    
                    // Debug: Check if fieldKey is present in fieldPermissionsMap
                    System.debug('Processing fieldKey: ' + fieldKey);
                    if (fieldPermissionsMap.containsKey(fieldKey)) {
                        system.debug('inside containskey');
                        FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
                        fieldPermissionMap.put(
                            'PermissionsRead',
                            fieldPerm.PermissionsRead
                        );
                        fieldPermissionMap.put(
                            'PermissionsEdit',
                            fieldPerm.PermissionsEdit
                        );
                    } else {
                        fieldPermissionMap.put('PermissionsRead', false);
                        fieldPermissionMap.put('PermissionsEdit', false);
                    }
                    
                    fieldPermissionMap.put(
                        'hasEditAccess',
                        fieldDefMapByName.get(fieldKey).get('isCalculated')
                    );
                    fieldPermissionsMapList.add(fieldPermissionMap);
                    
                    // Debug: Check the contents of fieldPermissionMap
                    //System.debug('fieldPermissionMap: ' + fieldPermissionMap);
                }
            }
        }
        System.debug('check field permission map' + fieldPermissionsMapList);
        //System.debug('check recordtype permission map' + recordTypeMapList);
        return new ProfileObjectPermissionsWrapper(
            fieldPermissionsMapList,
            ManageUserAccessPartner.checkSObjType(objName),
            dependObjects
        );
    }
    
    public class ProfileObjectPermissionsWrapper {
        @AuraEnabled
        public List<Map<String, Object>> fieldPermissions { get; set; }
        @AuraEnabled
        public Boolean hasObjAccess { get; set; }
        @AuraEnabled
        public List<Object> dependentObj { get; set; }
        
        public ProfileObjectPermissionsWrapper(
            List<Map<String, Object>> fieldPermissions,
            Boolean hasObjAccess,
            List<Object> dependentObj
        ) {
            this.fieldPermissions = fieldPermissions;
            this.hasObjAccess = hasObjAccess;
            this.dependentObj = dependentObj;
        }
    }
    
    
    public class PermissionSetGroupObjectPermissionsWrapper {
        //@AuraEnabled
        //public Map<string, Object> objectPermissions { get; set; }
        @AuraEnabled
        public List<Map<String, Object>> fieldPermissions { get; set; }
        @AuraEnabled
        public Boolean hasObjAccess { get; set; }
        @AuraEnabled
        public List<Object> objDependent { get; set; }
        @AuraEnabled
        public List<RecordType> recordTypeDetails { get; set; } // Updated to List<RecordType>
        @AuraEnabled
        public string MutedId { get; set; }
        
        public PermissionSetGroupObjectPermissionsWrapper(
            /*Map<string, Object> objectPermissions,*/
            List<Map<String, Object>> fieldPermissions,
            Boolean hasObjAccess,
            List<Object> objDependent,
            List<RecordType> recordTypeDetails,
            string muteId
        ) {
            //this.objectPermissions = objectPermissions;
            this.fieldPermissions = fieldPermissions;
            this.hasObjAccess = hasObjAccess;
            this.objDependent = objDependent;
            this.recordTypeDetails = recordTypeDetails;
            this.MutedId = muteId;
        }
    }
    
    @AuraEnabled
    //used
    public static PermissionSetGroupObjectPermissionsWrapper getSobjectPermissionsForPermissionSetGroup(String permSetId,String objName,String psgname,String psgapiname) {
        System.debug('Perset Id' + permSetId);
        System.debug('Object Name' + objName);
        System.debug('PSG Name' + psgname);
        System.debug('PSG API Name' + psgapiname);
        manageUserAccess instance = new manageUserAccess();
        List<Object> dependObjects = ManageUserAccess.checkDependency(objName);
        Map<String, Boolean> fieldAccess = ManageUserAccessPartner.checkFieldType(objName);
        system.debug('fieldAccess' + fieldAccess);
        
        string nullValue = '%_%';
        list<PermissionSetGroupComponent> per = [
            SELECT
            id,
            PermissionSetId,
            PermissionSet.Name,
            PermissionSetGroupId,
            PermissionSetGroup.DeveloperName
            FROM PermissionSetGroupComponent
            WHERE
            PermissionSetGroupId = :permSetId
            AND (NOT PermissionSet.Name LIKE :nullValue)
        ];
        string muteId;
        for (PermissionSetGroupComponent pe : per) {
            system.debug(pe);
            muteId = pe.PermissionSetId;
        }
        
        List<MutingPermissionSet> mpsList = [
            SELECT id
            FROM MutingPermissionSet
            WHERE id = :muteId
        ];
        
        MutingPermissionSet mutingPermissionSet;
        
        if (!mpsList.isEmpty()) {
            mutingPermissionSet = mpsList[0];
            muteId = mutingPermissionSet.Id;
            system.debug('Mute Id' + muteId);
        } else {
            mutingPermissionSet = new MutingPermissionSet();
            mutingPermissionSet.MasterLabel = psgname + ' Muted';
            mutingPermissionSet.DeveloperName = psgapiname + '_Muted';
            insert mutingPermissionSet;
            
            system.debug('Id' + mutingPermissionSet.Id);
            
            muteId = mutingPermissionSet.Id;
            
            /*
PermissionSetGroup psGroup = [
SELECT Id
FROM PermissionSetGroup
WHERE Id = :muteId
LIMIT 1
];*/
            PermissionSetGroup psGroup = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE Id = : permSetId
                LIMIT 1
            ];
            
            
            PermissionSetGroupComponent component = new PermissionSetGroupComponent(
                PermissionSetGroupId = psGroup.Id,
                PermissionSetId = mutingPermissionSet.Id
            );
            insert component;
        }
        
        //Map<String, Object> objectPermissionsMap = new Map<String, Object>();
        
        List<Map<String, Object>> fieldPermissionsMapList = new List<Map<String, Object>>();
        
        Map<String, Map<String, Object>> fieldDefMapByName = manageUserAccess.getFieldDefinitionProfile(
            objName
        );
        system.debug('Before Object Permission');
        // Object Permissions
        
        Map<String, FieldPermissions> fieldPermissionsMap = new Map<String, FieldPermissions>();
        for (FieldPermissions fieldPerm : [
            SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
            FROM FieldPermissions
            WHERE Parent.PermissionSetGroup.Id = :permSetId AND SObjectType = :objName
        ]) {
            if (fieldPerm != null) {
                fieldPermissionsMap.put(fieldPerm.Field, fieldPerm);
            }
        }
        // Debug: Check the contents of fieldPermissionsMap
        System.debug('fieldPermissionsMap: ' + fieldPermissionsMap);
        
        // Process each field definition
        for (String fieldKey : fieldDefMapByName.keySet()) {
            if (fieldKey != null) {
                //Map<String, Object> fieldDefMap = fieldDefMapByName.get(fieldKey);
                if ((Boolean) fieldDefMapByName.get(fieldKey).get('isPermissionable') &&
                    fieldAccess.get(fieldKey) == true) {
                        Map<String, Object> fieldPermissionMap = new Map<String, Object>();
                        fieldPermissionMap.put('Field', fieldKey);
                        fieldPermissionMap.put(
                            'label',
                            fieldDefMapByName.get(fieldKey).get('Label')
                        );
                        
                        // Debug: Check if fieldKey is present in fieldPermissionsMap
                        System.debug('Processing fieldKey: ' + fieldKey);
                        if (fieldPermissionsMap.containsKey(fieldKey)) {
                            FieldPermissions fieldPerm = fieldPermissionsMap.get(fieldKey);
                            fieldPermissionMap.put(
                                'PermissionsRead',
                                fieldPerm.PermissionsRead
                            );
                            fieldPermissionMap.put(
                                'PermissionsEdit',
                                fieldPerm.PermissionsEdit
                            );
                        } else {
                            fieldPermissionMap.put('PermissionsRead', false);
                            fieldPermissionMap.put('PermissionsEdit', false);
                        }
                        
                        fieldPermissionMap.put(
                            'hasEditAccess',
                            fieldDefMapByName.get(fieldKey).get('isCalculated')
                        );
                        fieldPermissionsMapList.add(fieldPermissionMap);
                        
                        // Debug: Check the contents of fieldPermissionMap
                        //System.debug('fieldPermissionMap: ' + fieldPermissionMap);
                    }
            }
        }
        
        List<RecordType> recordTypeDetails = [
            SELECT Id, Name, DeveloperName, NamespacePrefix
            FROM RecordType
            WHERE SobjectType = :objName
            ORDER BY Name ASC
        ];
        
        System.debug('check field permission map' + fieldPermissionsMapList);
        System.debug('check mute Id' + muteId);
        
        return new PermissionSetGroupObjectPermissionsWrapper(
            /*objectPermissionsMap,*/
            fieldPermissionsMapList,
            ManageUserAccessPartner.checkSObjType(objName),
            ManageUserAccess.checkDependency(objName),
            recordTypeDetails,
            muteId
        );
    }
    
    
}