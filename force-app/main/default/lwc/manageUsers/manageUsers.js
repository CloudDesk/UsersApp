//This component is used for editing users,activating&deactivating users,editing user assignment.
import {LightningElement,track,wire,api} from 'lwc';
import getAllUsers from '@salesforce/apex/ManageCloneUser.getAllUsers';
import userActivation from '@salesforce/apex/ManageCloneUser.userActivation';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
export default class ManageUsers extends NavigationMixin(LightningElement) {

    isUser = false;
    @track sortBy;
    @track sortDirection;
    @track userList = [];
    @api spinnerValue;
    isCreateModal = false;
    userId;
    isActive;
    isActivateConfirmMessage = false;
    isDeActivateConfirmMessage = false;
    userName;
    @track updatedOtherRecords = [];
    @track searchUserName = '';
    @track wiredResult = [];
    @track isUserRecord = false;

    userColumndropdown = [{
            label: 'Name',
            fieldName: 'Name',
            sortable: true
        },
        {
            label: 'Email',
            fieldName: 'Email',
            sortable: true
        },
        {
            label: 'License',
            fieldName: 'licenseName',
            sortable: true
        },
        {
            label: 'Is Active',
            fieldName: 'IsActive',
            sortable: true
        },
        {
            label: 'Edit',
            type: 'button-icon',
            typeAttributes: {
                iconName: 'utility:edit',
                name: 'edit',
                variant: 'border-filled',
                alternativeText: 'Edit',
                title: 'Edit'
            }
        },
        {
            label: 'Status',
            type: 'button',
            fieldName: 'buttonLabel',
            typeAttributes: {
                label: {
                    fieldName: 'buttonLabel'
                },
                name: 'active_Condition',
                variant: {
                    fieldName: 'buttonVariant'
                }
            }
        },
        {
            label: 'Assignments',
            type: 'button',
            typeAttributes: {
                label: 'Edit Assignment',
                name: 'editAssignment',
                variant: 'neutral',
                disabled: {
                    fieldName: 'editAssign'
                }
            }
        }
    ]

    // This method retrieves all users, formats the user list with additional properties like licenseName, buttonLabel, and buttonVariant, and filters the users while handling errors and managing spinner visibility.
    @wire(getAllUsers)
    wiredUsers({
        error,
        data
    }) {
        this.wiredResult = data;
        if (data) {
            console.log('Custom Event Spinner');
            console.log('OUTPUT : User List', JSON.stringify(data));
            this.userList = data.map(user => ({
                ...user,
                licenseName: user.Profile?.UserLicense?.Name || '',
                buttonLabel: user.IsActive ? 'Deactivate' : 'Activate',
                buttonVariant: user.IsActive ? 'destructive' : 'brand',
                editAssign: user.IsActive ? false : true
            }));
            this.filterUsers();
        } else if (error) {
            console.error(error);
            this.dispatchSpinnerEvent(false);
        }
    }
    //This method dispatches a custom event named spinnerchange with a specified value to toggle spinner visibility.
    dispatchSpinnerEvent(value) {
        const spinnerEvent = new CustomEvent('spinnerchange', {
            detail: value
        });
        this.dispatchEvent(spinnerEvent);
    }
    //This method updates the searchUserName property with the lowercase value of the input and triggers the filterUsers method to apply the search filter.
    handleSearchChange(event) {
        console.log('OUTPUT : event', event);
        this.searchUserName = event.target.value.toLowerCase();
        this.filterUsers();
    }
    //This method filters the userList based on the searchUserName input and updates the list with relevant user details, then triggers the spinner event.
    filterUsers() {
        this.userList = this.wiredResult.map(user => ({
            ...user,
            licenseName: user.Profile?.UserLicense?.Name || '',
            buttonLabel: user.IsActive ? 'Deactivate' : 'Activate',
            buttonVariant: user.IsActive ? 'destructive' : 'brand',
            editAssign: user.IsActive ? false : true
        }));
        this.userList = this.userList.filter(user =>
            user.Name.toLowerCase().includes(this.searchUserName)
        );
        this.isUser = this.userList.length > 0;
        this.dispatchSpinnerEvent(false);
    }

    //This function will used to sort data by direction.
    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    //Helper method for sorting data
    sortData(fieldName, sortDirection) {
        let data1 = JSON.parse(JSON.stringify(this.userList));
        let keyValue = (a) => a[fieldName];
        let isReverse = sortDirection === 'asc' ? 1 : -1;

        data1.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        this.userList = data1;
    }
    //This method handles different row actions such as editing a user, editing assignments, and toggling user activation status with appropriate modal and confirmation message triggers.
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        this.userId = event.detail.row.Id;
        this.userName = event.detail.row.Name;
        this.isActive = event.detail.row.IsActive;
        console.log('actionName', JSON.stringify(actionName));
        if (actionName === 'edit') {
            this.spinnerValue = true;
            this.isUserRecord = true;
            setTimeout(() => {
                this.spinnerValue = false;
            }, 2000);
        }
        if (actionName === 'editAssignment') {
            this.isCreateModal = true;
        }
        if (actionName === 'active_Condition') {
            if (event.detail.row.IsActive == true) {
                console.log('Deactive');
                this.isActive = false;
                console.log('OUTPUT : Deactive', JSON.stringify(this.isActive));
                this.isDeActivateConfirmMessage = true;
            }
            if (event.detail.row.IsActive == false) {
                console.log('Active');
                this.isActive = true;
                console.log('OUTPUT : Active', JSON.stringify(this.isActive));
                this.isActivateConfirmMessage = true;
            }
        }
    }
    //This method updates the user's activation status, modifies the user list accordingly, and displays a success or error toast, while managing confirmation message visibility.
    handleConfirmActivate() {
        this.spinnerValue = true;

        userActivation({
                userId: this.userId,
                isActive: this.isActive
            })
            .then((result) => {
                console.log(result);
                const updatedUserList = this.userList.map(user => {
                    if (user.Id === result.Id) {
                        console.log('before userToUpdate', JSON.stringify(user));
                        return {
                            ...user,
                            IsActive: result.IsActive,
                            buttonLabel: result.IsActive ? 'Deactivate' : 'Activate',
                            buttonVariant: result.IsActive ? 'destructive' : 'brand',
                            editAssign: result.IsActive ? false : true
                        };
                    }
                    return user;
                });
                this.userList = updatedUserList;

                const updatedWireList = this.wiredResult.map(user => {
                    if (user.Id === result.Id) {
                        console.log('before userToUpdate', JSON.stringify(user));
                        return {
                            ...user,
                            IsActive: result.IsActive,
                            buttonLabel: result.IsActive ? 'Deactivate' : 'Activate',
                            buttonVariant: result.IsActive ? 'destructive' : 'brand',
                            editAssign: result.IsActive ? false : true
                        };
                    }
                    return user;
                });
                this.wiredResult = updatedWireList;

                console.log('after userToUpdate', JSON.stringify(result));
                this.spinnerValue = false;
                this.handleShowToast('User Activated Successfully', 'Success', 'success');
            })
            .catch((error) => {
                console.error('Error in Updating Active Status', error);
                this.spinnerValue = false;
                let errorMessage = error.body.message;
                let extractedMessage = errorMessage.includes('first error:') ? errorMessage.split('first error:')[1].trim() : errorMessage;
                this.handleShowToast(extractedMessage, 'Error', 'error');
            });
        if (this.isActivateConfirmMessage == true) {
            this.isActivateConfirmMessage = false;
        }

        if (this.isDeActivateConfirmMessage == true) {
            this.isDeActivateConfirmMessage = false;
        }
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
    //This method hides confirmation or edit modals based on the ariaLabel of the canceled event.
    handleCancel(event) {
        if (event.target.name == 'activateCancel') {
            this.isActivateConfirmMessage = false;
        }
        if (event.target.name == 'deActivateCancel') {
            this.isDeActivateConfirmMessage = false;
        }
        if (event.target.name == 'editCancel') {
            this.isUserRecord = false;
        }
    }

    //This function is used to close create modal.
    closeAssignment() {
        this.isCreateModal = false;
    }
    //This method updates the updatedOtherRecords array with the sliced records from the event detail if they are defined and not empty.
    updateHandler(event) {
        if (event.detail.slicedRecords != undefined && event.detail.slicedRecords.length > 0) {
            this.updatedOtherRecords = [...event.detail.slicedRecords];
        }
    }
    //This method updates the user's name and email in both userList and wiredResult, hides the user record modal, and shows a success toast message after saving the changes.
    handleSuccess(event) {
        this.spinnerValue = true;
        const savedFields = event.detail.fields;
        const savedEmail = savedFields.Email.value;
        const fullName = `${savedFields.FirstName.value} ${savedFields.LastName.value}`;
        const updatedUserList = this.userList.map(user => {
            if (user.Id === event.detail.id) {
                return {
                    ...user,
                    Name: fullName,
                    Email: savedEmail
                };
            }
            return user;
        });
        this.userList = updatedUserList;

        const updatedWireList = this.wiredResult.map(user => {
            if (user.Id === event.detail.id) {
                return {
                    ...user,
                    Name: fullName,
                    Email: savedEmail
                };
            }
            return user;
        });
        this.wiredResult = updatedWireList;
        this.isUserRecord = false;
        this.handleShowToast('User Edited Successfully', 'Success', 'success');
        this.spinnerValue = false;
    }

}