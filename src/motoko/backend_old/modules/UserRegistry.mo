// ⬇️ User Registry for ICTO V2
// Comprehensive user activity and deployment tracking

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

import Common "../../shared/types/Common";
import Storage "../../shared/types/Storage";
import Audit "../../shared/types/Audit";

module {
    // ===== USER REGISTRY STATE =====
    
    public type UserRegistryStorage = {
        var userProfiles: Trie.Trie<Text, Storage.UserProfile>; // userId -> profile
        var deploymentRecords: Trie.Trie<Text, Storage.DeploymentRecord>; // deploymentId -> record
        var userDeployments: Trie.Trie<Text, [Text]>; // userId -> deploymentIds
        var projectDeployments: Trie.Trie<Common.ProjectId, [Text]>; // projectId -> deploymentIds
        var canisterOwnership: Trie.Trie<Text, Common.UserId>; // canisterId -> userId
    };
    public type UserProfile = Storage.UserProfile;
    public type DeploymentRecord = Storage.DeploymentRecord;
    
    // ===== INITIALIZATION =====
    
    public func initUserRegistry() : UserRegistryStorage {
        {
            var userProfiles = Trie.empty<Text, Storage.UserProfile>();
            var deploymentRecords = Trie.empty<Text, Storage.DeploymentRecord>();
            var userDeployments = Trie.empty<Text, [Text]>();
            var projectDeployments = Trie.empty<Common.ProjectId, [Text]>();
            var canisterOwnership = Trie.empty<Text, Common.UserId>();
        }
    };
    
    // ===== UTILITY FUNCTIONS =====
    
    private func keyT(x : Text) : Trie.Key<Text> = { hash = Text.hash(x); key = x };
    
    // ===== USER PROFILE MANAGEMENT =====
    
    public func registerUser(
        storage: UserRegistryStorage,
        userId: Common.UserId
    ) : Storage.UserProfile {
        let userKey = Principal.toText(userId);
        
        // Check if user already exists
        switch (Trie.get(storage.userProfiles, keyT(userKey), Text.equal)) {
            case (?existingProfile) {
                // Update last active time
                let updatedProfile = {
                    existingProfile with
                    lastActiveAt = Time.now();
                };
                storage.userProfiles := Trie.put(storage.userProfiles, keyT(userKey), Text.equal, updatedProfile).0;
                updatedProfile
            };
            case null {
                // Create new user profile
                let newProfile = Storage.createDefaultUserProfile(userId);
                storage.userProfiles := Trie.put(storage.userProfiles, keyT(userKey), Text.equal, newProfile).0;
                newProfile
            };
        }
    };
    
    public func updateUserProfile(
        storage: UserRegistryStorage,
        userId: Common.UserId,
        metadata: Storage.UserMetadata
    ) : ?Storage.UserProfile {
        let userKey = Principal.toText(userId);
        switch (Trie.get(storage.userProfiles, keyT(userKey), Text.equal)) {
            case (?profile) {
                let updatedProfile = {
                    profile with
                    metadata = metadata;
                    lastActiveAt = Time.now();
                };
                storage.userProfiles := Trie.put(storage.userProfiles, keyT(userKey), Text.equal, updatedProfile).0;
                ?updatedProfile
            };
            case null { null };
        }
    };
    
    public func getUserProfile(
        storage: UserRegistryStorage,
        userId: Common.UserId
    ) : ?Storage.UserProfile {
        let userKey = Principal.toText(userId);
        Trie.get(storage.userProfiles, keyT(userKey), Text.equal)
    };
    
    public func updateUserActivity(
        storage: UserRegistryStorage,
        userId: Common.UserId,
        feesPaid: Nat
    ) : ?Storage.UserProfile {
        let userKey = Principal.toText(userId);
        switch (Trie.get(storage.userProfiles, keyT(userKey), Text.equal)) {
            case (?profile) {
                let updatedProfile = {
                    profile with
                    lastActiveAt = Time.now();
                    totalFeesPaid = profile.totalFeesPaid + feesPaid;
                };
                storage.userProfiles := Trie.put(storage.userProfiles, keyT(userKey), Text.equal, updatedProfile).0;
                ?updatedProfile
            };
            case null { null };
        }
    };
    
    // ===== DEPLOYMENT TRACKING =====
    
    public func recordDeployment(
        storage: UserRegistryStorage,
        userId: Common.UserId,
        projectId: ?Common.ProjectId,
        canisterId: Common.CanisterId,
        serviceType: Audit.ServiceType,
        deploymentType: Storage.DeploymentType,
        costs: Storage.DeploymentCosts,
        metadata: Storage.DeploymentMetadata
    ) : Storage.DeploymentRecord {
        
        let deploymentId = Storage.generateDeploymentId(userId, serviceType, Time.now());
        let canisterIdText = Principal.toText(canisterId);
        
        let deploymentRecord : Storage.DeploymentRecord = {
            id = deploymentId;
            userId = userId;
            projectId = projectId;
            deploymentType = deploymentType;
            canisterId = canisterId;
            serviceType = serviceType;
            deployedAt = Time.now();
            status = #Active;
            configuration = {
                rawConfig = "{}"; // Will be filled by caller
                templateVersion = "1.0.0";
                features = [];
                upgradePolicy = "owner_only";
            };
            costs = costs;
            metadata = metadata;
        };
        
        // Store deployment record
        storage.deploymentRecords := Trie.put(storage.deploymentRecords, keyT(deploymentId), Text.equal, deploymentRecord).0;
        
        // Update user deployments index
        let userKey = Principal.toText(userId);
        let existingUserDeployments = Option.get(Trie.get(storage.userDeployments, keyT(userKey), Text.equal), []);
        storage.userDeployments := Trie.put(
            storage.userDeployments, 
            keyT(userKey), 
            Text.equal, 
            Array.append(existingUserDeployments, [deploymentId])
        ).0;
        
        // Update project deployments index if projectId exists
        switch (projectId) {
            case (?pid) {
                let existingProjectDeployments = Option.get(Trie.get(storage.projectDeployments, keyT(pid), Text.equal), []);
                storage.projectDeployments := Trie.put(
                    storage.projectDeployments, 
                    keyT(pid), 
                    Text.equal, 
                    Array.append(existingProjectDeployments, [deploymentId])
                ).0;
            };
            case null {};
        };
        
        // Record canister ownership
        storage.canisterOwnership := Trie.put(storage.canisterOwnership, keyT(canisterIdText), Text.equal, userId).0;
        
        // Update user profile deployment count
        switch (Trie.get(storage.userProfiles, keyT(userKey), Text.equal)) {
            case (?profile) {
                let updatedProfile = {
                    profile with
                    deploymentCount = profile.deploymentCount + 1;
                    totalFeesPaid = profile.totalFeesPaid + costs.totalCost;
                    lastActiveAt = Time.now();
                };
                storage.userProfiles := Trie.put(storage.userProfiles, keyT(userKey), Text.equal, updatedProfile).0;
            };
            case null {};
        };
        
        deploymentRecord
    };
    
    public func updateDeploymentStatus(
        storage: UserRegistryStorage,
        deploymentId: Text,
        status: Storage.DeploymentStatus
    ) : ?Storage.DeploymentRecord {
        switch (Trie.get(storage.deploymentRecords, keyT(deploymentId), Text.equal)) {
            case (?record) {
                let updatedRecord = {
                    record with
                    status = status;
                };
                storage.deploymentRecords := Trie.put(storage.deploymentRecords, keyT(deploymentId), Text.equal, updatedRecord).0;
                ?updatedRecord
            };
            case null { null };
        }
    };
    
    // ===== QUERY FUNCTIONS =====
    
    public func getUserDeployments(
        storage: UserRegistryStorage,
        userId: Common.UserId,
        limit: Nat,
        offset: Nat
    ) : [Storage.DeploymentRecord] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(storage.userDeployments, keyT(userKey), Text.equal)) {
            case (?deploymentIds) {
                let startIndex = offset;
                let endIndex = Nat.min(offset + limit, deploymentIds.size());
                
                if (startIndex >= deploymentIds.size()) {
                    []
                } else {
                    let slicedIds = Array.tabulate<Text>(
                        endIndex - startIndex,
                        func(i) { deploymentIds[startIndex + i] }
                    );
                    
                    Array.mapFilter<Text, Storage.DeploymentRecord>(slicedIds, func(id) {
                        Trie.get(storage.deploymentRecords, keyT(id), Text.equal)
                    })
                }
            };
            case null { [] };
        }
    };
    
    public func getProjectDeployments(
        storage: UserRegistryStorage,
        projectId: Common.ProjectId,
        limit: Nat,
        offset: Nat
    ) : [Storage.DeploymentRecord] {
        switch (Trie.get(storage.projectDeployments, keyT(projectId), Text.equal)) {
            case (?deploymentIds) {
                let startIndex = offset;
                let endIndex = Nat.min(offset + limit, deploymentIds.size());
                
                if (startIndex >= deploymentIds.size()) {
                    []
                } else {
                    let slicedIds = Array.tabulate<Text>(
                        endIndex - startIndex,
                        func(i) { deploymentIds[startIndex + i] }
                    );
                    
                    Array.mapFilter<Text, Storage.DeploymentRecord>(slicedIds, func(id) {
                        Trie.get(storage.deploymentRecords, keyT(id), Text.equal)
                    })
                }
            };
            case null { [] };
        }
    };
    
    public func getCanisterOwner(
        storage: UserRegistryStorage,
        canisterId: Common.CanisterId
    ) : ?Common.UserId {
        let canisterKey = Principal.toText(canisterId);
        Trie.get(storage.canisterOwnership, keyT(canisterKey), Text.equal)
    };
    
    public func getDeploymentRecord(
        storage: UserRegistryStorage,
        deploymentId: Text
    ) : ?Storage.DeploymentRecord {
        Trie.get(storage.deploymentRecords, keyT(deploymentId), Text.equal)
    };
    
    // ===== USER ACTIVITY SUMMARY =====
    
    public func getUserActivitySummary(
        storage: UserRegistryStorage,
        userId: Common.UserId,
        timeRange: ?Audit.TimeRange
    ) : Storage.UserActivitySummary {
        let userKey = Principal.toText(userId);
        let deployments = getUserDeployments(storage, userId, 1000, 0); // Get all deployments
        
        // Filter by time range if provided
        let deploymentsInRange = switch (timeRange) {
            case (?range) {
                Array.filter<Storage.DeploymentRecord>(deployments, func(deployment) {
                    deployment.deployedAt >= range.start and deployment.deployedAt <= range.end
                })
            };
            case null { deployments };
        };
        
        let totalDeployments = deploymentsInRange.size();
        let activeDeployments = Array.filter<Storage.DeploymentRecord>(deploymentsInRange, func(d) {
            d.status == #Active
        }).size();
        let failedDeployments = Array.filter<Storage.DeploymentRecord>(deploymentsInRange, func(d) {
            switch (d.status) {
                case (#Failed(_)) true;
                case (_) false;
            }
        }).size();
        
        let totalFeesPaid = Array.foldLeft<Storage.DeploymentRecord, Nat>(deploymentsInRange, 0, func(acc, d) {
            acc + d.costs.totalCost
        });
        
        let averageDeploymentCost = if (totalDeployments > 0) {
            totalFeesPaid / totalDeployments
        } else { 0 };
        
        let defaultTimeRange = switch (timeRange) {
            case (?range) range;
            case null {
                {
                    start = 0;
                    end = Time.now();
                }
            };
        };
        
        {
            userId = userId;
            timeRange = defaultTimeRange;
            totalDeployments = totalDeployments;
            activeDeployments = activeDeployments;
            failedDeployments = failedDeployments;
            deploymentsByType = []; // TODO: Implement grouping by service type
            totalFeesPaid = totalFeesPaid;
            averageDeploymentCost = averageDeploymentCost;
            paymentTokensUsed = []; // TODO: Collect unique payment tokens
            totalActions = 0; // Would come from audit logs
            successfulActions = 0; // Would come from audit logs
            failedActions = 0; // Would come from audit logs
            lastActiveDate = Time.now();
            projectsCreated = 0; // Would come from project registry
            activeProjects = 0; // Would come from project registry
            completedProjects = 0; // Would come from project registry
        }
    };
    
    // ===== ADMIN FUNCTIONS =====
    
    public func getAllUsers(
        storage: UserRegistryStorage,
        limit: Nat,
        offset: Nat
    ) : [Storage.UserProfile] {
        let allProfiles = Trie.toArray<Text, Storage.UserProfile, Storage.UserProfile>(
            storage.userProfiles,
            func(_, profile) { profile }
        );
        
        let startIndex = offset;
        let endIndex = Nat.min(offset + limit, allProfiles.size());
        
        if (startIndex >= allProfiles.size()) {
            []
        } else {
            Array.tabulate<Storage.UserProfile>(
                endIndex - startIndex,
                func(i) { allProfiles[startIndex + i] }
            )
        }
    };
    
    public func getTotalUsers(storage: UserRegistryStorage) : Nat {
        Trie.size(storage.userProfiles)
    };
    
    public func getTotalDeployments(storage: UserRegistryStorage) : Nat {
        Trie.size(storage.deploymentRecords)
    };
    
    // ===== DATA EXPORT/IMPORT FOR UPGRADES =====
    
    public func exportUserProfiles(storage: UserRegistryStorage) : [(Principal, Storage.UserProfile)] {
        var profiles : [(Principal, Storage.UserProfile)] = [];
        for ((userIdText, profile) in Trie.iter(storage.userProfiles)) {
            let userId = Principal.fromText(userIdText);
            profiles := Array.append(profiles, [(userId, profile)]);
        };
        profiles
    };
    
    public func exportDeploymentRecords(storage: UserRegistryStorage) : [Storage.DeploymentRecord] {
        var records : [Storage.DeploymentRecord] = [];
        for ((deploymentId, record) in Trie.iter(storage.deploymentRecords)) {
            records := Array.append(records, [record]);
        };
        records
    };
    
    public func importUserData(
        profiles: [(Principal, Storage.UserProfile)], 
        deployments: [Storage.DeploymentRecord]
    ) : UserRegistryStorage {
        let storage = initUserRegistry();
        
        // Import user profiles
        for ((userId, profile) in profiles.vals()) {
            storage.userProfiles := Trie.put(storage.userProfiles, keyT(Principal.toText(userId)), Text.equal, profile).0;
        };
        
        // Import deployment records
        for (deployment in deployments.vals()) {
            storage.deploymentRecords := Trie.put(storage.deploymentRecords, keyT(deployment.id), Text.equal, deployment).0;
            
            // Rebuild user deployment index
            let userIdText = Principal.toText(deployment.userId);
            let userDeployments = Option.get(Trie.get(storage.userDeployments, keyT(userIdText), Text.equal), []);
            storage.userDeployments := Trie.put(storage.userDeployments, keyT(userIdText), Text.equal, Array.append(userDeployments, [deployment.id])).0;
            
            // Rebuild project deployment index if project exists
            switch (deployment.metadata.parentProject) {
                case (?projectId) {
                    let projectDeployments = Option.get(Trie.get(storage.projectDeployments, keyT(projectId), Text.equal), []);
                    storage.projectDeployments := Trie.put(storage.projectDeployments, keyT(projectId), Text.equal, Array.append(projectDeployments, [deployment.id])).0;
                };
                case null {};
            };
        };
        
        storage
    };
    
    // Archive old deployment records - returns count of archived deployments
    public func archiveOldDeployments(storage: UserRegistryStorage, cutoffTime: Common.Timestamp) : Nat {
        var archivedCount = 0;
        var deploymentsToRemove : [Text] = [];
        
        // First, collect deployments to remove
        for ((deploymentId, deployment) in Trie.iter(storage.deploymentRecords)) {
            if (deployment.deployedAt < cutoffTime) {
                deploymentsToRemove := Array.append(deploymentsToRemove, [deploymentId]);
            };
        };
        
        // Then remove them
        for (deploymentId in deploymentsToRemove.vals()) {
            switch (Trie.get(storage.deploymentRecords, keyT(deploymentId), Text.equal)) {
                case (?deployment) {
                    // Remove from main storage
                    storage.deploymentRecords := Trie.remove(storage.deploymentRecords, keyT(deploymentId), Text.equal).0;
                    
                    // Remove from user deployment index
                    let userIdText = Principal.toText(deployment.userId);
                    let userDeployments = Option.get(Trie.get(storage.userDeployments, keyT(userIdText), Text.equal), []);
                    let filteredUserDeployments = Array.filter(userDeployments, func(id : Text) : Bool { id != deploymentId });
                    storage.userDeployments := Trie.put(storage.userDeployments, keyT(userIdText), Text.equal, filteredUserDeployments).0;
                    
                    // Remove from project deployment index if exists
                    switch (deployment.metadata.parentProject) {
                        case (?projectId) {
                            let projectDeployments = Option.get(Trie.get(storage.projectDeployments, keyT(projectId), Text.equal), []);
                            let filteredProjectDeployments = Array.filter(projectDeployments, func(id : Text) : Bool { id != deploymentId });
                            storage.projectDeployments := Trie.put(storage.projectDeployments, keyT(projectId), Text.equal, filteredProjectDeployments).0;
                        };
                        case null {};
                    };
                    
                    archivedCount += 1;
                };
                case null {};
            };
        };
        
        archivedCount
    };
} 