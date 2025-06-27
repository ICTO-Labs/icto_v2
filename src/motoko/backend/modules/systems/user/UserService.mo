import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";

import Common "../../../shared/types/Common";
import UserTypes "UserTypes";
import Audit "../audit/AuditTypes";

module UserService {

    // ==================================================================================================
    // ⬇️ Ported from V1: icto_app/backend/modules/UserRegistry.mo
    // Refactored for modular pipeline compatibility (V2)
    // All functions are stateless and operate on the provided `state` object.
    // ==================================================================================================

    // --- STATE MANAGEMENT ---

    public func initState(owner: Principal) : UserTypes.State {
        UserTypes.emptyState()
    };

    public func fromStableState(stableState: UserTypes.StableState) : UserTypes.State {
        let state = UserTypes.emptyState();
        for (entry in stableState.userProfiles.vals()) {
            let (k, v) = entry;
            state.userProfiles := Trie.put(state.userProfiles, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        for (entry in stableState.deploymentRecords.vals()) {
            let (k, v) = entry;
            state.deploymentRecords := Trie.put(state.deploymentRecords, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        for (entry in stableState.userDeployments.vals()) {
            let (k, v) = entry;
            state.userDeployments := Trie.put(state.userDeployments, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        for (entry in stableState.projectDeployments.vals()) {
            let (k, v) = entry;
            state.projectDeployments := Trie.put(state.projectDeployments, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        for (entry in stableState.canisterOwnership.vals()) {
            let (k, v) = entry;
            state.canisterOwnership := Trie.put(state.canisterOwnership, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        return state;
    };

    public func toStableState(state: UserTypes.State) : UserTypes.StableState {
        {
            userProfiles = Iter.toArray(Trie.iter(state.userProfiles));
            deploymentRecords = Iter.toArray(Trie.iter(state.deploymentRecords));
            userDeployments = Iter.toArray(Trie.iter(state.userDeployments));
            projectDeployments = Iter.toArray(Trie.iter(state.projectDeployments));
            canisterOwnership = Iter.toArray(Trie.iter(state.canisterOwnership));
        }
    };

    // --- UTILS ---

    private func textKey(x : Text) : Trie.Key<Text> = { hash = Text.hash(x); key = x };
    private func principalKey(p: Principal) : Trie.Key<Text> = textKey(Principal.toText(p));

    // --- USER PROFILE MANAGEMENT ---

    public func getUserProfile(
        state: UserTypes.State,
        userId: Common.UserId
    ) : ?UserTypes.UserProfile {
        let userKey = Principal.toText(userId);
        Trie.get(state.userProfiles, textKey(userKey), Text.equal)
    };

    public func registerUser(
        state: UserTypes.State,
        userId: Common.UserId
    ) : UserTypes.UserProfile {
        let userKey = Principal.toText(userId);
        
        switch (Trie.get(state.userProfiles, textKey(userKey), Text.equal)) {
            case (?existingProfile) {
                let updatedProfile = {
                    existingProfile with
                    lastActiveAt = Time.now();
                };
                state.userProfiles := Trie.put(state.userProfiles, textKey(userKey), Text.equal, updatedProfile).0;
                updatedProfile
            };
            case null {
                let newProfile = UserTypes.createDefaultUserProfile(userId);
                state.userProfiles := Trie.put(state.userProfiles, textKey(userKey), Text.equal, newProfile).0;
                newProfile
            };
        }
    };
    
    public func updateUserProfile(
        state: UserTypes.State,
        userId: Common.UserId,
        metadata: UserTypes.UserMetadata
    ) : ?UserTypes.UserProfile {
        let userKey = Principal.toText(userId);
        switch (Trie.get(state.userProfiles, textKey(userKey), Text.equal)) {
            case (?profile) {
                let updatedProfile = {
                    profile with
                    metadata = metadata;
                    lastActiveAt = Time.now();
                };
                state.userProfiles := Trie.put(state.userProfiles, textKey(userKey), Text.equal, updatedProfile).0;
                ?updatedProfile
            };
            case null { null };
        }
    };
    
    public func updateUserActivity(
        state: UserTypes.State,
        userId: Common.UserId,
        feesPaid: Nat
    ) : ?UserTypes.UserProfile {
        let userKey = Principal.toText(userId);
        switch (Trie.get(state.userProfiles, textKey(userKey), Text.equal)) {
            case (?profile) {
                let updatedProfile = {
                    profile with
                    lastActiveAt = Time.now();
                    totalFeesPaid = profile.totalFeesPaid + feesPaid;
                };
                state.userProfiles := Trie.put(state.userProfiles, textKey(userKey), Text.equal, updatedProfile).0;
                ?updatedProfile
            };
            case null { null };
        }
    };

    // --- DEPLOYMENT TRACKING ---
    
    public func recordDeployment(
        state: UserTypes.State,
        userId: Common.UserId,
        projectId: ?Common.ProjectId,
        canisterId: Common.CanisterId,
        serviceType: Audit.ServiceType,
        deploymentType: UserTypes.DeploymentType,
        costs: UserTypes.DeploymentCosts,
        metadata: UserTypes.DeploymentMetadata
    ) : UserTypes.DeploymentRecord {
        
        let deploymentId = UserTypes.generateDeploymentId(userId, serviceType, Time.now());
        let canisterIdText = Principal.toText(canisterId);
        
        let deploymentRecord : UserTypes.DeploymentRecord = {
            id = deploymentId;
            userId = userId;
            projectId = projectId;
            deploymentType = deploymentType;
            canisterId = canisterId;
            serviceType = serviceType;
            deployedAt = Time.now();
            status = #Active;
            configuration = {
                rawConfig = "{}"; // TODO: Will be filled by caller
                templateVersion = "1.0.0";
                features = [];
                upgradePolicy = "owner_only";
            };
            costs = costs;
            metadata = metadata;
        };
        
        state.deploymentRecords := Trie.put(state.deploymentRecords, textKey(deploymentId), Text.equal, deploymentRecord).0;
        
        let userKeyText = Principal.toText(userId);
        let existingUserDeployments = Option.get(Trie.get(state.userDeployments, textKey(userKeyText), Text.equal), []);
        state.userDeployments := Trie.put(
            state.userDeployments, 
            textKey(userKeyText), 
            Text.equal, 
            Array.append(existingUserDeployments, [deploymentId])
        ).0;
        
        switch (projectId) {
            case (?pid) {
                let existingProjectDeployments = Option.get(Trie.get(state.projectDeployments, textKey(pid), Text.equal), []);
                state.projectDeployments := Trie.put(
                    state.projectDeployments, 
                    textKey(pid), 
                    Text.equal, 
                    Array.append(existingProjectDeployments, [deploymentId])
                ).0;
            };
            case null {};
        };
        
        state.canisterOwnership := Trie.put(state.canisterOwnership, textKey(canisterIdText), Text.equal, userId).0;
        
        switch (Trie.get(state.userProfiles, textKey(userKeyText), Text.equal)) {
            case (?profile) {
                let updatedProfile = {
                    profile with
                    deploymentCount = profile.deploymentCount + 1;
                    totalFeesPaid = profile.totalFeesPaid + costs.totalCost;
                    lastActiveAt = Time.now();
                };
                state.userProfiles := Trie.put(state.userProfiles, textKey(userKeyText), Text.equal, updatedProfile).0;
            };
            case null {};
        };
        
        deploymentRecord
    };
    
    public func updateDeploymentStatus(
        state: UserTypes.State,
        deploymentId: Text,
        status: UserTypes.DeploymentStatus
    ) : ?UserTypes.DeploymentRecord {
        switch (Trie.get(state.deploymentRecords, textKey(deploymentId), Text.equal)) {
            case (?record) {
                let updatedRecord = { record with status = status; };
                state.deploymentRecords := Trie.put(state.deploymentRecords, textKey(deploymentId), Text.equal, updatedRecord).0;
                ?updatedRecord
            };
            case null { null };
        }
    };
    
    // --- QUERY FUNCTIONS ---
    
    public func getUserDeployments(
        state: UserTypes.State,
        userId: Common.UserId,
        limit: Nat,
        offset: Nat
    ) : [UserTypes.DeploymentRecord] {
        let userKey = Principal.toText(userId);
        switch (Trie.get(state.userDeployments, textKey(userKey), Text.equal)) {
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
                    
                    Array.mapFilter<Text, UserTypes.DeploymentRecord>(slicedIds, func(id) {
                        Trie.get(state.deploymentRecords, textKey(id), Text.equal)
                    })
                }
            };
            case null { [] };
        }
    };

    public func getDeploymentRecord(
        state: UserTypes.State,
        deploymentId: Text
    ) : ?UserTypes.DeploymentRecord {
        Trie.get(state.deploymentRecords, textKey(deploymentId), Text.equal)
    };

    public func getCanisterOwner(
        state: UserTypes.State,
        canisterId: Common.CanisterId
    ) : ?Common.UserId {
        let canisterIdText = Principal.toText(canisterId);
        Trie.get(state.canisterOwnership, textKey(canisterIdText), Text.equal)
    };

    public func getAllUserProfiles(state: UserTypes.State) : [UserTypes.UserProfile] {
        let profilesIter = Iter.map<(Text, UserTypes.UserProfile), UserTypes.UserProfile>(
            Trie.iter(state.userProfiles),
            func((_, v)) { v }
        );
        let profiles = Iter.toArray(profilesIter);
        profiles
    };
};
