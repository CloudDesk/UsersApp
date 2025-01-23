import { LightningElement,api,track } from 'lwc';
import getObjectDefinition from '@salesforce/apex/manageUserAccess.getObjectDefinition';
import getFieldDefinition from '@salesforce/apex/manageUserAccess.getFieldDefinition';
import getSystemandUserDefinition from '@salesforce/apex/manageUserAccess.getSystemandUserDefinition';
import getPermandUserofUserPerm from '@salesforce/apex/manageUserAccess.getPermandUserofUserPerm';
export default class ManagePermissionComponent extends LightningElement {

isUser=true;
isObject = false;
isField = false;
isUserAll = false;
isObjectAll = false;
isFieldAll = false;
isUserProfile= false;
isObjectProfile= false;
isFieldProfile = false;
isUserpermSet = false;
isObjectPermSet = false;
isfieldPermSet = false;
isUserpermSetGrp = false;
isObjectPermSetGrp = false;
isfieldPermSetGrp = false;
permissionTypeValue = "User";
userPermissionValue;
userObjectValue;
@api userObjectOptions;
objectPermissionValue;
fieldPermissionValue;
objectValue;
isObjectSelected = true;
isFieldObjectSelected = true;
profileValue= 'All';
permissionSetValue = 'All';
permissionSetGroupValue='All';
@api userPermissionOptions = [];
fieldValue;
isFieldSelected=true;
isPermissionEnabledPermission = true;
showTable= false;
showSpinner = false;
@track enabledUserPermission = [];
@track sortBy = 'IsActive';
@track sortDirection = 'desc';
@api updatedOtherRecords;
@track fieldOptions = [];
@track profileOptions = [];
@track permissionSetOption = [];
@track permissionSetGroupOption = [];
noUserWithPermission = false;
selectedPermissionLabel=''
selectedPermissionTypeLabel=''
permissionTypeOptions = [
{label: "User", value: "User", type: "text"},
{label: "Object", value: "Object", type: "text"},
{label: "Field", value: "Field", type: "text"}
];
datacolumns=[
   {
   label: 'FUll Name',
   fieldName: 'Name',
   },
   {
      label:'User Name',
      fieldName: 'Username',
   },
   {
      label:'Alias',
      fieldName: 'Alias',
   },
   {
      label:'Profile',
      fieldName: 'profileName',
   },
   {
      label:'Active',
      fieldName: 'IsActive',
      type: 'boolean',
      sortable: true,
   },
   {
      label:'Last Login',
      fieldName: 'LastLoginDate',
      type: 'date',
      typeAttributes: {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
    },
   }
]




//  connectedCallback() {
//         // Find and update styles for .slds-dropdown_fluid and .slds-dropdown--fluid
//         const dropdownFluidElements = this.template.querySelectorAll('.slds-dropdown_fluid');
//         const dropdownElements = this.template.querySelectorAll('.slds-dropdown--fluid');
// console.log('OUTPUT FLUID ELEMENTS ! : '+dropdownFluidElements);
// console.log('OUTPUT FLUID ELEMENTS !!!!! : '+dropdownElements);
//         dropdownFluidElements.forEach(element => {
//             element.style.minWidth = 'none';
//             element.style.maxWidth = 'none';
//             element.style.width = 'none';
//         });

//         dropdownElements.forEach(element => {
//             element.style.minWidth = 'none';
//             element.style.maxWidth = 'none';
//             element.style.width = 'none';
//         });
//     }


objectPermissionOptions = [
{label: "Create", value: "PermissionsCreate", type: "text"},
{label: "Read", value: "PermissionsRead", type: "text"},
{label: "Edit", value: "PermissionsEdit", type: "text"},
{label: "Delete", value: "PermissionsDelete", type: "text"},
{label: "View All Records", value: "PermissionsViewAllRecords", type: "text"},
{label: "Modify All Records", value: "PermissionsModifyAllRecords", type: "text"}
];
fieldPermissionOptions = [
{label: "Read", value: "PermissionsRead", type: "text"},
{label: "Edit", value: "PermissionsEdit", type: "text"}
];

// handlePermissionListValues()
// {

// getSystemandUserDefinition()
//    .then(res=>{
//       let arr = []
//          for(let key in res)
//          {         
//             arr.push({label: res[key], value: key})
//          }
//       this.userPermissionOptions = arr.sort((a,b)=>{
//             if (a.label < b.label) {
//                return -1;
//          } else if (a.label > b.label) {
//                return 1;
//          }
//          return 0;
//       });
//       console.log('user permission options?>>>>', JSON.stringify(this.userPermissionOptions))
//    })

// getObjectDefinition()
// .then(res=>{
//    console.log('res Object ::::::::::::::::::::::::', res);
//    this.userObjectOptions = res?.map(elem => ({label:elem.Label,value:elem.QualifiedApiName}))
// })
// console.log('User Object Options ::::::::::::::::: ', this.userObjectOptions);

// }

handlePermissionTypeChange(event)
{
this.permissionTypeValue = event.detail.value;
console.log('Permission Type Value : >>>>>', this.permissionTypeValue); 
this.handleclear();
}
handleclear()
{
   if(this.permissionTypeValue == 'User')
   {
   this.isUser = true;
   this.isObject= false;
   this.isObjectAll = false;
   this.isField = false;
   this.isFieldAll = false;
   this.isObjectProfile= false;
   this.isFieldProfile = false;
   this.isObjectPermSet = false;
   this.isfieldPermSet = false;
   this.isObjectPermSetGrp = false;
   this.isfieldPermSetGrp = false;
   }
   if(this.permissionTypeValue == 'Object')
   { 
   this.isObject = true;
   this.isField = false;
   this.isFieldAll= false;
   this.isUser = false;
   this.isUserAll = false;
   this.isUserProfile = false;
   this.isFieldProfile = false;
   this.isUserPermSet = false;
   this.isfieldPermSet = false;
   this.isUserPermSetGrp = false;
   this.isfieldPermSetGrp = false;
   }
   if(this.permissionTypeValue == 'Field')
   {
   this.isField = true;
   this.isObjectProfile= false;
   this.isUserProfile = false;
   this.isObjectPermSet = false;
   this.isUserPermSet = false;
   this.isObjectPermSetGrp = false;
   this.isUserPermSetGrp = false;
   this.isObject= false;
   this.isObjectAll= false;
   this.isUser = false;
   this.isUserAll = false;
   }
  
   this.userPermissionValue='';
   this.userObjectValue='';
   this.objectPermissionValue='';
   this.objectValue='';
   this.fieldValue='';
   this.fieldPermissionValue='';
   this.isObjectSelected = true;
   this.isFieldObjectSelected=true;
   this.isFieldSelected=true;
   this.selectedPermissionLabel = '';
   this.selectedPermissionTypeLabel = '';
   this.selectedObject='';
   this.selectedField='';
   this.showTable = false;
   this.enabledUserPermission = [];
   this.isPermissionEnabledPermission = true;
   this.profileValue = 'All';
   this.permissionSetValue= 'All';
   this.permissionSetGroupValue ='All';
   this.profileOptions = [];
   this.permissionSetOption = [];
   this.permissionSetGroupOption = [];
}
sortData(fieldname, direction)
{
let parseData = JSON.parse(JSON.stringify(this.enabledUserPermission));
// Return the value stored in the field
let keyValue = (a) => {
      return a[fieldname];
};
let isReverse = direction === 'desc' ? -1 : 1;
// sorting data
parseData.sort((x, y) => {
   x = keyValue(x) ? keyValue(x) : ''; // handling null values
   y = keyValue(y) ? keyValue(y) : '';
   // sorting values based on direction
   return isReverse * ((x > y) - (y > x));
});
this.enabledUserPermission = parseData;
}

handleUserPermissionChange(event)
{
this.profileValue = 'All';
this.permissionSetValue = 'All';
this.permissionSetGroupValue = 'All';
this.profileOptions = [];
this.permissionSetOption = [];
this.permissionSetGroupOption = [];
this.isUserpermSet = false;
this.isUserPermSetGrp=false;
this.isUserProfile=false;
this.showSpinner = true;
this.userPermissionValue = event.detail.value;
console.log('Check user permission value : >>>>', this.userPermissionValue);
let selectedOption = this.userPermissionOptions.find(option=>option.value === this.userPermissionValue)
if(selectedOption)
{
   this.selectedPermissionLabel = selectedOption.label;
}

this.handlePermissionHandlerCall(this.userPermissionValue,'','','','','','All');
this.isPermissionEnabledPermission = false;
this.isUserAll = true;
}

handleObjectChange(event)
{
   this.userObjectValue = event.detail.value;
   this.isObjectSelected = false;
   this.objectPermissionValue = '';
   this.showTable=false;
   let selectedOption = this.userObjectOptions.find(option=>option.value === this.userObjectValue)
   if(selectedOption)
   {
      this.selectedObject = selectedOption.label;
   }  
}
handleObjectPermissionChange(event)
{
   this.profileValue = 'All';
   this.permissionSetValue = 'All';
   this.permissionSetGroupValue = 'All';
   this.profileOptions = [];
   this.permissionSetGroupOption=[];
   this.permissionSetOption=[]
   this.isObjectpermSet = false;
   this.isObjectPermSetGrp=false;
   this.isObjectProfile=false;
   this.showSpinner = true;
   this.objectPermissionValue = event.detail.value;
   let selectedOption = this.objectPermissionOptions.find(option=>option.value === this.objectPermissionValue)
   if(selectedOption)
   {
      this.selectedPermissionLabel = selectedOption.label;
   }
   this.handlePermissionHandlerCall('', this.userObjectValue,this.objectPermissionValue,'','','','All');
   this.isPermissionEnabledPermission = false;
   this.isObjectAll = true;
}

handleFieldObjectChange(event)
{
   this.objectValue = event.detail.value;
   console.log('check field value objecte', this.objectValue);
   let selectedOption = this.userObjectOptions.find(option=>option.value === this.objectValue)
   if(selectedOption)
   {
      this.selectedObject = selectedOption.label;
   }  
   this.fieldValue = '';
   this.fieldPermissionValue='';
   this.showTable=false;
   getFieldDefinition({objectName: this.objectValue})
   .then(res=>{
      console.log('check map result', res);
      let arr =[];
      for(let key in res)
      {         
         arr.push({label: res[key], value: key})
      }
         this.fieldOptions = arr.sort((a,b)=>{
            if (a.label < b.label) {
               return -1;
         } else if (a.label > b.label) {
               return 1;
         }
         return 0;
      });
   })
   this.isFieldObjectSelected = false;
}
handleFieldChange(event)
{
   this.fieldValue = event.detail.value;
   console.log('check field option', this.fieldValue)
   let selectedOption = this.fieldOptions.find(option=>option.value === this.fieldValue)
   if(selectedOption)
   {
      this.selectedField = selectedOption.label;
   }  
   console.log('check selected field',this.selectedField )
   this.fieldPermissionValue='';
   this.showTable=false;
   this.isFieldSelected=false;
}
handleFieldPermissionChange(event)
{
   this.profileValue = 'All';
   this.permissionSetValue = 'All';
   this.permissionSetGroupValue = 'All';
   this.profileOptions = [];
   this.permissionSetGroupOption=[];
   this.permissionSetOption=[]
   this.isFieldpermSet = false;
   this.isFieldPermSetGrp=false;
   this.isFieldProfile=false;
   this.showSpinner = true;
   this.fieldPermissionValue = event.detail.value;
   console.log('check field Permission Value', this.fieldPermissionValue);
   let selectedOption = this.fieldPermissionOptions.find(option=>option.value === this.fieldPermissionValue)
   if(selectedOption)
   {
      this.selectedPermissionLabel = selectedOption.label;
   } 
   this.handlePermissionHandlerCall('','','',this.objectValue,this.fieldValue,this.fieldPermissionValue,'All')
   this.isPermissionEnabledPermission =false;
   this.isFieldAll= true;
}

handlePermissionHandlerCall(userPermissionValue, objNameValue, objPermissionValue, fieldObj, fieldNameVal, fieldPermVal, permValue)
{
   console.log('check field obj: '+fieldObj+'check field: '+ fieldNameVal+ 'chcek field perm: ' + fieldPermVal);
getPermandUserofUserPerm({userPermission: userPermissionValue, objName:objNameValue, objPermission: objPermissionValue ,objFieldName:fieldObj,fieldName:fieldNameVal,fieldPerm:fieldPermVal, perSetId:permValue })
.then(res=>{
   console.log('check user permission result list>>', res);
   if(res.userList.length > 0)
   {
      this.showTable = true;
      this.noUserWithPermission = false;
      this.enabledUserPermission = res.userList.map(user=>{
         return{
            ...user,
            profileName:user.Profile?.Name
         };
      });     
      this.sortData(this.sortBy, this.sortDirection);
      console.log('chcek enabledUser permission', JSON.stringify(this.enabledUserPermission))
   }
   if(res.userList.length == 0)
   {
      this.noUserWithPermission = true;
      this.showTable= false
   }
   if(res.permissionSetList.length > 0)
   {
      let permissionSetArray = res.permissionSetList;
      console.log('permissionSetArray : ', permissionSetArray);
      let profileType = [ {label : 'All',value : 'All'}];
      let permissionSetType = [ {label: 'All', value: 'All'}];
      let groupType = [ {label: 'All', value: 'All'}];

      permissionSetArray.forEach(obj=>{
         if(obj.Type == 'Profile')
         {
             profileType.push({label: obj.Profile.Name, value: obj.Id})

         }
         else if(obj.Type =='Group')
         {                          
              groupType.push({label: obj.Label, value: obj.Id})
         }
         else
         {             
               permissionSetType.push({label: obj.Label, value: obj.Id})
                         
         }        
      })
       this.profileOptions = profileType;
       this.permissionSetOption = permissionSetType;
       this.permissionSetGroupOption = groupType;
      console.log('profileOption>>>+++', JSON.stringify(this.profileOptions.length));
      console.log('permissionSet+++', JSON.stringify(this.permissionSetOption.length));
      console.log('Group +++: ',JSON.stringify(this.permissionSetGroupOption.length));
   }
   this.showSpinner = false;
})
}

handleProfileChange(event)
{
   this.showSpinner = true;
   this.showTable = false;
   this.selectedPermissionTypeLabel = ''
   this.profileValue = event.target.value;
   this.permissionSetValue = 'All';
   this.permissionSetGroupValue ='All'
   console.log('profile value'+ this.profileValue);
   let selectedOption = this.profileOptions.find(option=>option.value === this.profileValue)
   if(selectedOption)
   {
      this.selectedPermissionTypeLabel = selectedOption.label;
   }
   console.log('selectedPermissionTypeLabel  : ',this.selectedPermissionTypeLabel);
   this.handlePermissionHandlerCall(this.userPermissionValue, this.userObjectValue, this.objectPermissionValue, this.objectValue, this.fieldValue, this.fieldPermissionValue, this.profileValue)
   if(this.isUser == true)
   {
    if( this.profileValue == 'All')
    {
      this.isUserAll = true; 
    }
    else{
      this.isUserProfile = true;
      this.isUserAll = false;
      this.isUserpermSet = false;
      this.isUserPermSetGrp = false;
    }
    
   }
   if(this.isObject == true)
   {
      if( this.profileValue == 'All')
      {
         this.isUserAll = true; 
      }
      else{
         this.isObjectProfile = true;
         this.isObjectAll = false;
         this.isObjectPermSet = false;
         this.isObjectPermSetGrp = false;
      }
   }
   if(this.isField == true)
   {
       if( this.profileValue == 'All')
       {
         this.isUserAll = true; 
      }
      else{
         this.isFieldProfile = true;
         this.isFieldAll= false;
         this.isfieldPermSet = false;
         this.isfieldPermSetGrp = false;
      }
   }
   
  
}
handlePermissionSetGroupChange(event){
   this.showSpinner = true;
   this.showTable = false;
   this.selectedPermissionTypeLabel = ''
   this.permissionSetGroupValue = event.target.value;
   this.profileValue = 'All';
   this.permissionSetValue = 'All';
   let selectedOption = this.permissionSetGroupOption.find(option=>option.value === this.permissionSetGroupValue)
   if(selectedOption)
   {
      this.selectedPermissionTypeLabel = selectedOption.label;
   }
   console.log('selectedPermissionTypeLabel  : ',this.selectedPermissionTypeLabel);
   
   this.handlePermissionHandlerCall(this.userPermissionValue, this.userObjectValue, this.objectPermissionValue, this.objectValue, this.fieldValue, this.fieldPermissionValue, this.permissionSetGroupValue)
   console.log('permission set group : ', this.permissionSetGroupValue);
   if(this.isUser == true)
   {
    if( this.permissionSetGroupValue == 'All')
    {
      this.isUserAll = true; 
    }
    else{
      this.isUserProfile = false;
      this.isUserAll = false;
      this.isUserpermSet = false;
      this.isUserPermSetGrp = true;
    }
    
   }
   if(this.isObject == true)
   {
      if( this.permissionSetGroupValue == 'All')
      {
         this.isObjectAll = true; 
      }
      else{
         this.isObjectProfile = false;
         this.isObjectAll = false;
         this.isObjectPermSet = false
         this.isObjectPermSetGrp = true;
      }
   }
   if(this.isField == true)
   {
       if( this.permissionSetGroupValue == 'All')
       {
         this.isFieldAll = true; 
      }
      else{
         this.isFieldProfile = false;
         this.isFieldAll= false;
         this.isfieldPermSet = false;
         this.isfieldPermSetGrp = true;
      }
   }
}
handlePermissionSetChange(event)
{
   this.showSpinner = true;
   this.showTable = false;
   this.selectedPermissionTypeLabel = false;
   this.permissionSetValue = event.target.value;
   this.profileValue = 'All';
   this.permissionSetGroupValue = 'All';
   let selectedOption = this.permissionSetOption.find(option=>option.value === this.permissionSetValue)
   if(selectedOption)
   {
      this.selectedPermissionTypeLabel = selectedOption.label;
   }
   console.log('selectedPermissionTypeLabel  : ',this.selectedPermissionTypeLabel);
   
   this.handlePermissionHandlerCall(this.userPermissionValue, this.userObjectValue, this.objectPermissionValue, this.objectValue, this.fieldValue, this.fieldPermissionValue, this.permissionSetValue)
   console.log('permission set value : ', this.permissionSetValue);
    if(this.isUser == true)
   {
    if( this.permissionSetValue == 'All')
    {
      this.isUserAll = true; 
    }
    else{
      this.isUserProfile = false;
      this.isUserAll = false;
      this.isUserpermSet = true;
      this.isUserPermSetGrp = false;
    }
    
   }
   if(this.isObject == true)
   {
      if( this.permissionSetValue == 'All')
      {
         this.isObjectAll = true; 
      }
      else{
         this.isObjectProfile = false;
         this.isObjectAll = false;
         this.isObjectPermSet = true
         this.isObjectPermSetGrp = false;
      }
   }
   if(this.isField == true)
   {
       if( this.permissionSetValue == 'All')
       {
         this.isFieldAll = true; 
      }
      else{
         this.isFieldProfile = false;
         this.isFieldAll= false;
         this.isfieldPermSet = true;
         this.isfieldPermSetGrp = false;
      }
   }
}

updateHandler(event) {
        if (event.detail.slicedRecords != undefined && event.detail.slicedRecords.length > 0) {
            this.updatedOtherRecords = [...event.detail.slicedRecords];
            this.showSpinner = false;
        }
    }
}