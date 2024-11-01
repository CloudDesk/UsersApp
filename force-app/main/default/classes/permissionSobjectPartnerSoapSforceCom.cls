public class permissionSobjectPartnerSoapSforceCom {
    public class sObject_x {
        public String type_x;
        public String[] fieldsToNull;
        public String Id;
        public String Name;
        public String SobjectType;
        public String PermissionsRead;
        public String PermissionsCreate;
        public String PermissionsEdit;
        public String PermissionsDelete;
        public String PermissionsViewAllRecords;
        public String PermissionsModifyAllRecords;
        public String Field;
        public String IsOwnedByProfile;
        public String DeveloperName;
        public String MasterLabel ;
        public String Label;
        public string ProfileId;
        public string Email;
        public string Description;
        public string IsCustom;
        public string NamespacePrefix;
        public string License;
        public string CreatedBy;
        public string CreatedDate;
        public string LastModifiedBy;
        public string LastModifiedDate;
        public string AssigneeId;
        public string PermissionSetId;
        public string Type;
        public string UserLicenseId;
        //public string profileName;
        Public string Profile;
        Public string ParentId;
        Public string Parent;
        public string QualifiedApiName;
        public string Username;
        public string Alias;
        public string IsActive;
        public string LastLoginDate;
        public string Title;
        public string Department;
        public String licenseName;
        public String LicenseId;
        public String CreatedById;
        public String LastModifiedById;
        public String EntityDefinitionId;
        public String EntityDefinition;
        public String Contact;
        public String AccountId;
        public string FullName;
        public string DurableId;
        public string RecordId;
        /*
        public Map<String, String> fieldValues = new Map<String, String>();
        public void put(String fieldName, String fieldValue) {
            fieldValues.put(fieldName, fieldValue);
        }

        
        public object getfield(SObject sObjectRecord, String fieldName){
           return sObjectRecord.get(fieldName); 
        }
        
        public string getSobject(String fieldName) {
            if(fieldName == 'Name'){
            string samp = (string) getSobject(fieldName);
                return samp;
                }
            else{
                return null;
            }
        }
        
        public String get(String fieldName) {
            if(fieldName == 'Name'){
        return (String) get(fieldName);
                }
            else{
                return null;
            }

        }*/

  		
        private string[] RecordId_type_info = new string[]{'RecordId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] EntityDefinition_type_info = new string[]{'EntityDefinition','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] EntityDefinitionId_type_info = new string[]{'EntityDefinitionId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] CreatedById_type_info = new String[]{'CreatedById','urn:sobject.partner.soap.sforce.com',null,'0','-1','true'};
        private String[] LastModifiedById_type_info = new String[]{'LastModifiedById','urn:sobject.partner.soap.sforce.com',null,'0','-1','true'};
        private String[] LicenseId_type_info = new String[]{'LicenseId','urn:sobject.partner.soap.sforce.com',null,'0','-1','true'};
        private String[] licenseName_type_info = new String[]{'License.Name','urn:sobject.partner.soap.sforce.com',null,'0','-1','true'};
        private String[] type_x_type_info = new String[]{'type','urn:sobject.partner.soap.sforce.com',null,'1','1','false'};
        private String[] fieldsToNull_type_info = new String[]{'fieldsToNull','urn:sobject.partner.soap.sforce.com',null,'0','-1','true'};
        private String[] Id_type_info = new String[]{'Id','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] apex_schema_type_info = new String[]{'urn:sobject.partner.soap.sforce.com','true','false'};
        private String[] field_order_type_info = new String[]{'type_x','fieldsToNull','Id'};
        private String[] Name_type_info = new String[]{'Name','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] SobjectType_type_info = new String[]{'SobjectType','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] PermissionsRead_type_info = new String[]{'PermissionsRead','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] PermissionsCreate_type_info = new String[]{'PermissionsCreate','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] PermissionsEdit_type_info = new String[]{'PermissionsEdit','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] PermissionsDelete_type_info = new String[]{'PermissionsDelete','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] PermissionsViewAllRecords_type_info = new String[]{'PermissionsViewAllRecords','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] PermissionsModifyAllRecords_type_info = new String[]{'PermissionsModifyAllRecords','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] Field_type_info = new String[]{'Field','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] Label_type_info = new String[]{'Label','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] IsOwnedByProfile_type_info = new String[]{'IsOwnedByProfile','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] DeveloperName_type_info = new String[]{'DeveloperName','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private String[] MasterLabel_type_info = new String[]{'MasterLabel','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};        
        private String[] ProfileId_type_info = new String[]{'ProfileId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        Private string[] Email_type_info = new String[]{'Email','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        Private string[] Description_type_info = new String[]{'Description','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        Private string[] IsCustom_type_info = new String[]{'IsCustom','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] NamespacePrefix_type_info = new String[]{'NamespacePrefix','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] License_type_info = new String[]{'License','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] CreatedBy_type_info = new String[]{'CreatedBy','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] CreatedDate_type_info = new String[]{'CreatedDate','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] LastModifiedBy_type_info = new String[]{'LastModifiedBy','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] LastModifiedDate_type_info = new String[]{'LastModifiedDate','urn:sobject.partner.soap.sforce.com',null,'1','1','true'}; 
        Private string[] AssigneeId_type_info = new String[]{'AssigneeId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};   
        Private string[] PermissionSetId_type_info = new String[]{'PermissionSetId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};    
        private string[] Type_type_info = new String[]{'Type','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
       // private string[] profileName_type_info = new String[]{'Profile.Name','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        Private string[] Profile_type_info = new String[]{'Profile','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        Private string[] ParentId_type_info = new String[]{'ParentId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        Private string[] Parent_type_info = new String[]{'Parent','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] QualifiedApiName_type_info = new String[]{'QualifiedApiName','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] Username_type_info = new string[]{'Username','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] Alias_type_info = new string[]{'Alias','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] IsActive_type_info = new string[]{'IsActive','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] LastLoginDate_type_info = new string[]{'LastLoginDate','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] Title_type_info = new string[]{'Title','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] Department_type_info = new string[]{'Department','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] UserLicenseId_type_info = new string[]{'UserLicenseId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] FullName_type_info = new string[]{'FullName','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] DurableId_type_info = new string[]{'DurableId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] AccountId_type_info = new string[]{'AccountId','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
        private string[] AccountName = new string[]{'Account.Name','urn:sobject.partner.soap.sforce.com',null,'1','1','true'};
    }
}