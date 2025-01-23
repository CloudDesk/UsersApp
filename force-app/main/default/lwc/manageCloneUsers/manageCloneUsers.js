//This component is used to create & clone users and adding assignment to users.
import {LightningElement,track,wire,api} from 'lwc';
import getUsers from '@salesforce/apex/ManageCloneUser.getUsers';
import getUserAssignedGroups from '@salesforce/apex/ManageCloneUser.getUserAssignedGroups';
import assignPermissionsAndGroups from '@salesforce/apex/ManageCloneUser.assignPermissionsAndGroups';
import { getRecord } from 'lightning/uiRecordApi';
import PROFILE_FIELD from '@salesforce/schema/User.ProfileId';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class ManageCloneUsers extends NavigationMixin(LightningElement) {
    isCloneUsersTable = false;
    showSpinner = false;
    @track userValue = [];
    @track searchUserName = '';
    @track error;
    @track selectedRows = [];
    disabledNext = true;
    @track selectedUserId = '';
    @track selectedUserName = '';
    @track createUserId;
    isCloneUserModal = false;
    isCreateOrCloneModal = false;
    isCreateUserModal = false;
    isUserAssignmentModal = false;
    @track permissionSets = [];
    @track permissionSetGroups = [];
    @track publicGroups = [];
    @track queues = [];
    @api selectedUserId;
    defaultProfileId;
    @track hasAvailUser = true;

    @wire(getRecord, { recordId: '$selectedUserId', fields: [PROFILE_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.defaultProfileId = data.fields.ProfileId.value;
        } else if (error) {
            console.error(error);
        }
    }

    //This function is used to open create/clone modal.
    handleOnBoardUserClick() {
        this.isCreateOrCloneModal = true;
    }
    //This function is used to open users table. 
    handleClone() {
        this.isCreateOrCloneModal = false;
        this.isCloneUsersTable = true;
        this.showSpinner = true;
        setTimeout(() => {
            this.showSpinner = false;
            }, 1500);
    }
    //This function is used to open create modal.
    handleCreate() {
        this.isCreateOrCloneModal = false;
        this.showSpinner = true;
        this.isCreateUserModal = true;
        setTimeout(() => {
            this.showSpinner = false;
            }, 1500);
    }
    //This function is used to close create/clone modal.
    handleClose() {
        this.isCreateOrCloneModal = false;
    }
    //This function is used for creating successful user.
    handleSuccessCreate(event) {
        console.log('User record saved successfully. Record ID: ' + event.detail.id);
        this.createUserId = event.detail.id;
        this.isCreateUserModal = false;
        this.isCreateOrCloneModal = false;
        this.isUserAssignmentModal = true;
    }
    //This method creates a new user, assigns specified permissions, public groups, and queues.
    handleSuccessClone(event) {
        console.log('User record saved successfully. Record ID: ' + event.detail.id);
        const userId = event.detail.id;
        //this.createUserId = event.detail.id;
        console.log('userId : ', userId);
        assignPermissionsAndGroups({
                userId: userId,
                permissionSetIds: this.permissionSets,
                publicGroupIds: this.publicGroups,
                queueIds : this.queues
            })
            .then(() => {
                this.handleShowToast('User created successfully', 'Success', 'success');
                this.isCloneUserModal=false;
                this.isCreateOrCloneModal = false;
                this.isUserAssignmentModal = true;
            })
            .catch(error => {
                console.log('OUTPUT : ', error);
                this.handleShowToast(error, 'Error', 'error');
                this.isCloneUserModal=false;
                this.isCreateOrCloneModal = false;
            });

    }
    //This method displays an error toast notification when an error occurs during the user creation process.
    handleError(event) {
        const errorDetail = event.detail.message;
        console.log('errorDetail',JSON.stringify(errorDetail));
        this.handleShowToast(errorDetail, 'Error', 'error');
    }
    //This method handles the cancel action, toggling modal and table visibility based on the ariaLabel of the triggered event.
    handleCancel(event) {
        if (event.target.name === 'CancelNext') {
            console.log('Inside CancelNext >>> ');
            console.log('this.isCloneUsersTable : ',this.isCloneUsersTable);
            this.isCloneUsersTable = false;
            this.disabledNext = true;
            this.isCloneUserModal = false;
            this.isCreateOrCloneModal = true;
            this.searchUserName ='';
            this.filterUsers();
        }
        if(event.target.name === 'createCancel'){
            this.isCreateUserModal = false;
            this.isCreateOrCloneModal = true;
        }
        if(event.target.name === 'cloneCancel'){
            this.disabledNext = true;
            this.isCloneUserModal = false;
            this.isCloneUsersTable = true;
        }
    }
    //This method displays the user modal and hides the users table when triggered.
    handleNext(event) {
        this.showSpinner = true;
        this.isCloneUserModal = true;
        this.isCloneUsersTable = false;
        setTimeout(() => {
            this.showSpinner = false;
            }, 1500);
    }
    //This method retrieves and processes user data, mapping additional fields like license name, role, and profile, and handles errors or loading states.
    @wire(getUsers)
    wiredUsers({
        error,
        data
    }) {
        if (data) {
            this.userValue = data.map(user => ({
                ...user,
                UserLicenseName: user.Profile?.UserLicense?.Name || '',
                Role: user.UserRole?.Name || '',
                Profile: user.Profile?.Name || ''
            }));
            this.filteredUsers = [...this.userValue];
            this.error = undefined;
            this.selectedRows = this.userValue.map(user => user.Id);
            this.showSpinner = false;
            console.log('Result : ', JSON.stringify(this.userValue));
        } else if (error) {
            this.error = error;
            this.users = [];
            this.showSpinner = false;
            console.error('Error retrieving active users:', error);
        }
    }
    //This method fetches and processes user-assigned groups, including permission sets, permission set groups, public groups, and queues, based on the selected user.
    async handleUserSelection(event) {
        this.selectedUserId = event.target.value;
        this.createUserId = this.selectedUserId;
        this.selectedUserName = event.target.dataset.name;
        console.log('Event : ',event);
        console.log('selectedUserId : ',event.target.value);
        console.log('OUTPUT : Profile',event.target.dataset.profile);
        this.disabledNext = false;
        if (this.selectedUserId) {
            try {
                const result = await getUserAssignedGroups({
                    userId: this.selectedUserId
                });
                this.permissionSets = result.permissionSets.map(ps => ps.Id);
                this.permissionSetGroups = result.permissionSetGroups.map(psg => psg.Id);
                this.publicGroups = result.publicGroups.map(pg => pg.Id);
                this.queues = result.queues.map(que => que.Id);
                console.log('OUTPUT : ', JSON.stringify(result));
                console.log('permissionSets : ', JSON.stringify(this.permissionSets.length));
                console.log('permissionSets : ', JSON.stringify(this.permissionSets));
                console.log('permissionSetGroups : ', JSON.stringify(this.permissionSetGroups.length));
                console.log('publicGroups : ', JSON.stringify(this.publicGroups.length));
                console.log('Queues : ', JSON.stringify(this.queues));
            } catch (error) {
                console.error('Error fetching user groups:', error);
            }
        }
    }
    //This method closes the user assignment modal.
    closeAssignment() {
        this.isUserAssignmentModal = false;
    }
    //This method triggers a toast notification with the specified message, title, variant, and dismissible mode.
    handleShowToast(message, title, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: "dismissible"
            })
        );
    }
    handleSearchChange(event) {
        console.log('OUTPUT : event', event);
        this.searchUserName = event.target.value;
        this.filterUsers();
    }
    filterUsers() {
    if (this.searchUserName) {
        const filtered = this.userValue.filter(user => 
            user.Name.toLowerCase().includes(this.searchUserName.toLowerCase())
        );
        this.filteredUsers = filtered; 
        this.hasAvailUser = filtered.length > 0;
    } else {
        this.filteredUsers = [...this.userValue];
        this.hasAvailUser = this.filteredUsers.length > 0;
    }
}


}