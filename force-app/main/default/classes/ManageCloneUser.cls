//This class is used to create,clone,activating,deactivating,assigning permission sets,permission set groups,public groups,queues for user.
public with sharing class ManageCloneUser {
    //This method is used to get users based on available licenses left.
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        Map<String, Integer> availableLicenseLimits = new Map<String, Integer>();
        for (UserLicense ul : [SELECT Name, MasterLabel, TotalLicenses, UsedLicenses FROM UserLicense]) {
            Integer remainingLicenses = ul.TotalLicenses - ul.UsedLicenses;
            availableLicenseLimits.put(ul.MasterLabel, remainingLicenses);
        }
        System.debug('Available license limits >> ' + availableLicenseLimits);
        
        List<String> validLicenseNames = new List<String>();
        for (String licenseName : availableLicenseLimits.keySet()) {
            if (availableLicenseLimits.get(licenseName) > 0) {
                validLicenseNames.add(licenseName);
            }
        }
        
        // Step 4: If no valid licenses are available, return an empty list
        if (validLicenseNames.isEmpty()) {
            return new List<User>();
        }
        
        List<User> activeUsersWithLicense = [
            SELECT Id, Name, Profile.Name, Profile.UserLicense.Name, UserRole.Name
            FROM User
            WHERE IsActive = true 
            AND Profile.UserLicense.Name IN :validLicenseNames
            ORDER BY Name
        ];
        return activeUsersWithLicense;
    }
    
    //This method is used to retrieve users assigned with permissionset,ps group,public group & queues.
    @AuraEnabled(cacheable=true)
    public static Map<String, List<SObject>> getUserAssignedGroups(String userId) {
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();
        
        if (userId == null) {
            return result;
        }
        
        // Get unique permission sets assigned to the user
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : [SELECT PermissionSetId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :userId]) {
            permissionSetIds.add(psa.PermissionSetId);
        }
        result.put('permissionSets', [SELECT Id, Name FROM PermissionSet WHERE Type ='Regular' AND Id IN :permissionSetIds]);
        
        // Get permission set groups
        List<PermissionSetGroup> permissionSetGroups = [SELECT Id, MasterLabel FROM PermissionSetGroup WHERE Id IN (
            SELECT PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
                                                       ];
        result.put('permissionSetGroups', permissionSetGroups);
        
        // Get public groups
        List<Group> publicGroups = [SELECT Id, Name FROM Group WHERE Type = 'Regular' AND Id IN (
            SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId)
                                   ];
        result.put('publicGroups', publicGroups);
        // Get queues
        List<Group> queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Id IN (
            SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId)
                             ];
        result.put('queues', queues);
        
        System.debug('Final Result >>>'+result);
        return result;
    }
    //This method is for assigning permission sets,permissionset group,public group,queue for user.
    @AuraEnabled
    public static void assignPermissionsAndGroups(Id userId,List<Id> permissionSetIds,List<Id> publicGroupIds,List<Id> queueIds) 
    {
        try {
        	assignPermissionSets(userId,permissionSetIds);            
        	assignPublicGroups(userId,publicGroupIds);
            assignQueues(userId,queueIds);
            
            System.debug('Successfully processed Permission Sets, Public Groups, and Queues for UserId: ' + userId);
        } catch (Exception ex) {
            System.debug('Error in assignExistingPermissionsAndGroups: ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while assigning permissions and groups: ' + ex.getMessage());
        }
    }
    
    //This method is for assigning permission sets
    @AuraEnabled
    public static void assignPermissionSets(Id userId,List<Id> permissionSetIds) 
    {
        if (!permissionSetIds.isEmpty()) {
            List<PermissionSetAssignment> existingAssignments = [
                SELECT Id, PermissionSetId 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId 
                AND PermissionSetId IN :permissionSetIds
            ];
            
            List<PermissionSetAssignment> assignmentsToRemove = new List<PermissionSetAssignment>();
            List<PermissionSetAssignment> assignmentsToAdd = new List<PermissionSetAssignment>();
            
            Set<Id> existingPermissionSetIds = new Set<Id>();
            for (PermissionSetAssignment psa : existingAssignments) {
                existingPermissionSetIds.add(psa.PermissionSetId);
                assignmentsToRemove.add(psa);
            }
            
            for (Id psId : permissionSetIds) {
                if (!existingPermissionSetIds.contains(psId)) {
                    assignmentsToAdd.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = psId));
                }
            }
            
            if (!assignmentsToRemove.isEmpty()) {
                delete assignmentsToRemove;
            }
            
            if (!assignmentsToAdd.isEmpty()) {
                insert assignmentsToAdd;
            }
        }
    }
    //This method is for assigning public groups
    @AuraEnabled
    public static void assignPublicGroups(Id userId,List<Id> publicGroupIds)
    {
        if (!publicGroupIds.isEmpty()) {
            List<GroupMember> existingPublicGroups = [
                SELECT Id, GroupId 
                FROM GroupMember 
                WHERE UserOrGroupId = :userId 
                AND GroupId IN :publicGroupIds
            ];
            
            List<GroupMember> groupsToRemove = new List<GroupMember>();
            List<GroupMember> groupsToAdd = new List<GroupMember>();
            
            Set<Id> existingPublicGroupIds = new Set<Id>();
            for (GroupMember gm : existingPublicGroups) {
                existingPublicGroupIds.add(gm.GroupId);
                groupsToRemove.add(gm);
            }
            
            for (Id groupId : publicGroupIds) {
                if (!existingPublicGroupIds.contains(groupId)) {
                    groupsToAdd.add(new GroupMember(UserOrGroupId = userId, GroupId = groupId));
                }
            }
            
            if (!groupsToRemove.isEmpty()) {
                delete groupsToRemove;
            }
            
            if (!groupsToAdd.isEmpty()) {
                insert groupsToAdd;
            }
        }
    }
    //This method is for assigning queues
    @AuraEnabled
    public static void assignQueues(Id userId,List<Id> queueIds)
    {
        if (!queueIds.isEmpty()) {
            List<GroupMember> existingQueues = [
                SELECT Id, GroupId 
                FROM GroupMember 
                WHERE UserOrGroupId = :userId 
                AND GroupId IN :queueIds
            ];
            
            List<GroupMember> queuesToRemove = new List<GroupMember>();
            List<GroupMember> queuesToAdd = new List<GroupMember>();
            
            Set<Id> existingQueueIds = new Set<Id>();
            for (GroupMember gm : existingQueues) {
                existingQueueIds.add(gm.GroupId);
                queuesToRemove.add(gm);
            }
            
            for (Id queueId : queueIds) {
                if (!existingQueueIds.contains(queueId)) {
                    queuesToAdd.add(new GroupMember(UserOrGroupId = userId, GroupId = queueId));
                }
            }
            
            if (!queuesToRemove.isEmpty()) {
                delete queuesToRemove;
            }
            
            if (!queuesToAdd.isEmpty()) {
                insert queuesToAdd;
            }
        }
    }
    //This method is used to fetch list of users.
    @AuraEnabled(cacheable=true)
    public static List<User> getAllUsers() {
        return [SELECT Id, Name, ProfileId, Email,profile.UserLicense.Name,IsActive FROM User order By Name asc];
    }
    //This method is used for user activation.
   @AuraEnabled
    public static User userActivation(Id userId, Boolean isActive) {
        try {
            User userRecord = [SELECT Id, Name, ProfileId, Email, profile.UserLicense.Name, IsActive 
                               FROM User 
                               WHERE Id = :userId 
                               LIMIT 1];
            userRecord.IsActive = isActive;
            update userRecord;
            return userRecord;
        } catch (Exception ex) {
            System.debug('Error user activation update ' + ex.getMessage());
            throw new AuraHandledException('An error occurred while updating the user activation: ' + ex.getMessage());
        }
    }
    
    public class PermissionSetWrapper {
        @AuraEnabled public List<PermissionSet> permissionSets { get; set; }
        @AuraEnabled public List<PermissionSet> permissionSetGroups { get; set; }
        @AuraEnabled public List<Group> publicGroupQueue { get; set; }
        
        public PermissionSetWrapper() {
            permissionSets = new List<PermissionSet>();
            permissionSetGroups = new List<PermissionSet>();
            publicGroupQueue = new List<Group>();
        }
    }
    //This method is used to retrieve userlicense based permission sets,permission set groups,public groups,queues.
    @AuraEnabled(cacheable=true)
    public static PermissionSetWrapper getPermissionSetsByUserLicense(Id userId) {
        User user = [SELECT Profile.UserLicenseId FROM User WHERE Id = :userId LIMIT 1];
        Id userLicenseId = user.Profile.UserLicenseId;
        if (userLicenseId == null) {
            throw new AuraHandledException('User does not have a valid license.');
        }
        
        PermissionSetWrapper wrapper = new PermissionSetWrapper();
        
        // Get assigned Permission Set Ids for the user
        Set<Id> assignedPermissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId
        ]) {
            assignedPermissionSetIds.add(psa.PermissionSetId);
        }
        
        // Fetch Permission Sets that match the user's license but are not assigned
        wrapper.permissionSets = [
            SELECT Id, Name,Label, LicenseId, License.Name 
            FROM PermissionSet 
            WHERE LicenseId = :userLicenseId 
            AND Type = 'Regular'
            AND Id NOT IN :assignedPermissionSetIds
        ];
        
        // Fetch Permission Set Groups that are not assigned to the user
        wrapper.permissionSetGroups = [
            SELECT Id, Name, LicenseId, License.Name 
            FROM PermissionSet 
            WHERE  Type = 'Group'
            AND Id NOT IN :assignedPermissionSetIds
        ];
        
        // Get assigned Group Ids for the user
        Set<Id> assignedGroupIds = new Set<Id>();
        for (GroupMember gm : [
            SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId
        ]) {
            assignedGroupIds.add(gm.GroupId);
        }
        
        // Query Public Groups and Queues that are not assigned to the user
        wrapper.publicGroupQueue = [
            SELECT Id, Name, DeveloperName, Type 
            FROM Group 
            WHERE Type IN ('Regular', 'Queue')
            AND Id NOT IN :assignedGroupIds
        ];
        
        System.debug('Result >>>' + wrapper);
        return wrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static PermissionSetWrapper getAssignedAssignment(Id userId) {
        User user = [SELECT Profile.UserLicenseId FROM User WHERE Id = :userId LIMIT 1];
        Id userLicenseId = user.Profile.UserLicenseId;
        if (userLicenseId == null) {
            throw new AuraHandledException('User does not have a valid license.');
        }
        
        PermissionSetWrapper wrapper = new PermissionSetWrapper();
        
        // Get assigned Permission Sets for the user
        wrapper.permissionSets = [
            SELECT Id, Name, LicenseId, License.Name 
            FROM PermissionSet 
            WHERE LicenseId = :userLicenseId 
            AND Type = 'Regular'
            AND Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ];
        
        // Get assigned Permission Set Groups for the user
        wrapper.permissionSetGroups = [
            SELECT Id, Name, LicenseId, License.Name 
            FROM PermissionSet 
            WHERE Type = 'Group'
            AND Id IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ];
        
        // Get assigned Groups (Public Groups and Queues) for the user
        wrapper.publicGroupQueue = [
            SELECT Id, Name, DeveloperName, Type 
            FROM Group 
            WHERE Type IN ('Regular', 'Queue')
            AND Id IN (SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId)
        ];
        
        System.debug('Assigned Result >>>' + wrapper);
        return wrapper;
    }
    
}