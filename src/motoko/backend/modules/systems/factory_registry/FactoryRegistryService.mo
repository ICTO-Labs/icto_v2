import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Nat "mo:base/Nat";

import Common "../../../shared/types/Common";
import FactoryRegistryTypes "FactoryRegistryTypes";
import AuditTypes "../audit/AuditTypes";
// Removed Deployments import - logic moved to main.mo flow

module FactoryRegistryService {

    // Import types for convenience
    type State = FactoryRegistryTypes.State;
    type StableState = FactoryRegistryTypes.StableState;
    type UserRelationshipMap = FactoryRegistryTypes.UserRelationshipMap;
    type RelationshipInfo = FactoryRegistryTypes.RelationshipInfo;
    type RelationshipType = FactoryRegistryTypes.RelationshipType;
    type RelationshipMetadata = FactoryRegistryTypes.RelationshipMetadata;
    type FactoryRegistryResult<T> = FactoryRegistryTypes.FactoryRegistryResult<T>;
    type FactoryRegistryError = FactoryRegistryTypes.FactoryRegistryError;
    type UserRelationshipQuery = FactoryRegistryTypes.UserRelationshipQuery;
    type RelationshipQuery = FactoryRegistryTypes.RelationshipQuery;

    // ==================================================================================================
    // INTEGRATION FUNCTION FOR DEPLOYMENT FLOW
    // ==================================================================================================

    // Simple batch add relationships - called from main.mo deployment flow
    public func batchAddUserRelationshipsFromFlow(
        state: State,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        name: Text,
        description: ?Text
    ) : FactoryRegistryResult<()> {
        let metadata : RelationshipMetadata = {
            name = name;
            description = description;
            isActive = true;
            additionalData = null;
        };
        
        batchAddUserRelationships(state, relationshipType, canisterId, users, metadata)
    };

    // ==================================================================================================
    // STATE MANAGEMENT
    // ==================================================================================================

    public func initState(adminPrincipal: Principal) : State {
        let state = FactoryRegistryTypes.emptyState();
        state.adminPrincipals := [adminPrincipal];
        state
    };

    public func fromStableState(stableState: StableState) : State {
        let state = FactoryRegistryTypes.emptyState();
        
        // Restore factory registry
        for ((actionTypeText, factoryPrincipal) in stableState.factoryRegistry.vals()) {
            state.factoryRegistry := Trie.put(
                state.factoryRegistry, 
                {key = actionTypeText; hash = Text.hash(actionTypeText)}, 
                Text.equal, 
                factoryPrincipal
            ).0;
        };

        // Restore user relationships
        for ((userText, userMap) in stableState.userRelationships.vals()) {
            state.userRelationships := Trie.put(
                state.userRelationships,
                {key = userText; hash = Text.hash(userText)},
                Text.equal,
                userMap
            ).0;
        };

        // Restore relationship metadata
        for ((relationshipId, relationshipInfo) in stableState.relationshipMetadata.vals()) {
            state.relationshipMetadata := Trie.put(
                state.relationshipMetadata,
                {key = relationshipId; hash = Text.hash(relationshipId)},
                Text.equal,
                relationshipInfo
            ).0;
        };

        // Restore other fields
        state.supportedFactoryTypes := stableState.supportedFactoryTypes;
        state.adminPrincipals := stableState.adminPrincipals;

        state
    };

    public func toStableState(state: State) : StableState {
        {
            factoryRegistry = Iter.toArray(Trie.iter(state.factoryRegistry));
            supportedFactoryTypes = state.supportedFactoryTypes;
            userRelationships = Iter.toArray(Trie.iter(state.userRelationships));
            relationshipMetadata = Iter.toArray(Trie.iter(state.relationshipMetadata));
            adminPrincipals = state.adminPrincipals;
        }
    };

    // Get factory principal for an action type
    public func getFactory(
        state: State,
        actionType: AuditTypes.ActionType
    ) : FactoryRegistryResult<Principal> {
        
        let actionTypeText = FactoryRegistryTypes.actionTypeToText(actionType);
        
        switch (Trie.get(state.factoryRegistry, {key = actionTypeText; hash = Text.hash(actionTypeText)}, Text.equal)) {
            case (?factoryPrincipal) {
                #Ok(factoryPrincipal)
            };
            case null {
                #Err(#NotFound("No factory registered for action type: " # actionTypeText))
            };
        };
    };

    // ==================================================================================================
    // USER RELATIONSHIP FUNCTIONS  
    // ==================================================================================================

    // Add user relationship (single user)
    public func addUserRelationship(
        state: State,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<Text> {
        
        let userText = Principal.toText(user);
        
        // Get existing user relationship map or create new one
        let existingMap = switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?map) { map };
            case null { FactoryRegistryTypes.emptyUserRelationshipMap() };
        };
        
        // Add new relationship to map
        let updatedMap = FactoryRegistryTypes.addRelationshipToUserMap(existingMap, relationshipType, canisterId);
        
        // Update state
        state.userRelationships := Trie.put(
            state.userRelationships,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedMap
        ).0;

        // Create relationship info
        let relationshipId = FactoryRegistryTypes.generateRelationshipId(
            relationshipType,
            user,
            canisterId,
            Time.now()
        );

        // Get factory principal for this relationship
        let factoryPrincipal = switch (getFactoryForRelationshipType(state, relationshipType)) {
            case (#Ok(principal)) { principal };
            case (#Err(_)) { 
                // Use a default/unknown principal if factory not found
                Principal.fromText("rdmx6-jaaaa-aaaah-qcaiq-cai") // Default/fallback principal
            };
        };

        let relationshipInfo : RelationshipInfo = {
            id = relationshipId;
            relationshipType = relationshipType;
            canisterId = canisterId;
            userId = user;
            factoryPrincipal = factoryPrincipal;
            createdAt = Time.now();
            metadata = metadata;
        };

        // Store relationship metadata
        state.relationshipMetadata := Trie.put(
            state.relationshipMetadata,
            {key = relationshipId; hash = Text.hash(relationshipId)},
            Text.equal,
            relationshipInfo
        ).0;
        
        #Ok(relationshipId)
    };

    // Batch add user relationships
    public func batchAddUserRelationships(
        state: State,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        for (user in users.vals()) {
            switch (addUserRelationship(state, user, relationshipType, canisterId, metadata)) {
                case (#Err(error)) {
                    return #Err(error);
                };
                case (#Ok(_)) {
                    // Continue to next user
                };
            };
        };
        
        #Ok(())
    };

    // ==================================================================================================
    // PUBLIC CALLBACK API FOR EXTERNAL CONTRACTS
    // ==================================================================================================

    // Public API for external contracts to update user relationships
    public func updateUserRelationships(
        state: State,
        caller: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized factory for this relationship type
        switch (getFactoryForRelationshipType(state, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                if (caller != factoryPrincipal) {
                    return #Err(#Unauthorized("Only the registered factory can update relationships for this type"));
                };
            };
            case (#Err(_)) {
                return #Err(#FactoryTypeNotSupported("No factory registered for this relationship type"));
            };
        };

        // Add relationships for all users
        batchAddUserRelationships(state, relationshipType, canisterId, users, metadata)
    };

    // Remove user relationship
    public func removeUserRelationship(
        state: State,
        caller: Principal,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized
        switch (getFactoryForRelationshipType(state, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                if (caller != factoryPrincipal and not isAuthorized(state, caller)) {
                    return #Err(#Unauthorized("Only the factory or admin can remove relationships"));
                };
            };
            case (#Err(_)) {
                if (not isAuthorized(state, caller)) {
                    return #Err(#Unauthorized("Admin access required"));
                };
            };
        };

        let userText = Principal.toText(user);
        
        // Get existing user relationship map
        let existingMap = switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?map) { map };
            case null { return #Err(#NotFound("User has no relationships to remove")) };
        };
        
        // Remove relationship from appropriate array
        let updatedMap = removeRelationshipFromUserMap(existingMap, relationshipType, canisterId);
        
        // Update state
        state.userRelationships := Trie.put(
            state.userRelationships,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedMap
        ).0;
        
        #Ok(())
    };

    // ==================================================================================================
    // QUERY FUNCTIONS
    // ==================================================================================================

    // Get all relationships for a user
    public func getUserRelationships(
        state: State,
        queryObj: UserRelationshipQuery
    ) : FactoryRegistryResult<UserRelationshipMap> {
        
        let userText = Principal.toText(queryObj.user);
        
        switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?userMap) {
                // Filter by relationship type if specified
                switch (queryObj.relationshipType) {
                    case (?relationshipType) {
                        let filteredMap = filterUserMapByType(userMap, relationshipType);
                        #Ok(filteredMap)
                    };
                    case null {
                        #Ok(userMap)
                    };
                };
            };
            case null {
                #Ok(FactoryRegistryTypes.emptyUserRelationshipMap())
            };
        };
    };

    // Query relationships with filters
    public func queryRelationships(
        state: State,
        queryObj: RelationshipQuery
    ) : FactoryRegistryResult<[RelationshipInfo]> {
        
        let buffer = Buffer.Buffer<RelationshipInfo>(0);
        let limit = Option.get(queryObj.limit, 100); // Default limit
        let offset = Option.get(queryObj.offset, 0);
        var count = 0;
        var skipped = 0;

        label relationshipLoop for ((_, relationshipInfo) in Trie.iter(state.relationshipMetadata)) {
            if (count >= limit) break relationshipLoop;
            
            // Apply filters
            var matches = true;
            
            // Filter by relationship type
            switch (queryObj.relationshipType) {
                case (?filterType) {
                    if (relationshipInfo.relationshipType != filterType) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            // Filter by canister ID
            switch (queryObj.canisterId) {
                case (?filterCanister) {
                    if (relationshipInfo.canisterId != filterCanister) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            // Filter by factory principal
            switch (queryObj.factoryPrincipal) {
                case (?filterFactory) {
                    if (relationshipInfo.factoryPrincipal != filterFactory) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            // Filter by active status
            switch (queryObj.isActive) {
                case (?filterActive) {
                    if (relationshipInfo.metadata.isActive != filterActive) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            if (matches) {
                if (skipped < offset) {
                    skipped += 1;
                } else {
                    buffer.add(relationshipInfo);
                    count += 1;
                };
            };
        };
        
        #Ok(Buffer.toArray(buffer))
    };

    // Get relationship info by ID
    public func getRelationshipInfo(
        state: State,
        relationshipId: Text
    ) : FactoryRegistryResult<RelationshipInfo> {
        
        switch (Trie.get(state.relationshipMetadata, {key = relationshipId; hash = Text.hash(relationshipId)}, Text.equal)) {
            case (?relationshipInfo) {
                #Ok(relationshipInfo)
            };
            case null {
                #Err(#NotFound("Relationship info not found for ID: " # relationshipId))
            };
        };
    };

    // Get all registered factories
    public func getAllFactories(state: State) : [(AuditTypes.ActionType, Principal)] {
        let buffer = Buffer.Buffer<(AuditTypes.ActionType, Principal)>(0);
        
        for ((actionTypeText, factoryPrincipal) in Trie.iter(state.factoryRegistry)) {
            // Convert text back to ActionType (simplified approach)
            switch (actionTypeText) {
                case ("CreateDistribution") { buffer.add((#CreateDistribution, factoryPrincipal)) };
                case ("CreateToken") { buffer.add((#CreateToken, factoryPrincipal)) };
                case ("CreateTemplate") { buffer.add((#CreateTemplate, factoryPrincipal)) };
                // Add more mappings as needed
                case _ { }; // Skip unknown action types
            };
        };
        
        Buffer.toArray(buffer)
    };

    // ==================================================================================================
    // UTILITY FUNCTIONS
    // ==================================================================================================

    // Check if caller is authorized for admin operations
    private func isAuthorized(state: State, caller: Principal) : Bool {
        for (admin in state.adminPrincipals.vals()) {
            if (admin == caller) {
                return true;
            };
        };
        false
    };

    // Filter user relationship map by relationship type
    private func filterUserMapByType(userMap: UserRelationshipMap, relationshipType: RelationshipType) : UserRelationshipMap {
        switch (relationshipType) {
            case (#DistributionRecipient) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    userMap.distributions, [], [], []
                )
            };
            case (#LaunchpadParticipant) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    [], userMap.launchpads, [], []
                )
            };
            case (#DAOMember) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    [], [], userMap.daos, []
                )
            };
            case (#MultisigSigner) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    [], [], [], userMap.multisigs
                )
            };
        };
    };

    // Remove relationship from user map
    private func removeRelationshipFromUserMap(
        userMap: UserRelationshipMap,
        relationshipType: RelationshipType,
        canisterId: Principal
    ) : UserRelationshipMap {
        switch (relationshipType) {
            case (#DistributionRecipient) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    Array.filter(userMap.distributions, func(id: Principal) : Bool { id != canisterId }),
                    userMap.launchpads,
                    userMap.daos,
                    userMap.multisigs
                )
            };
            case (#LaunchpadParticipant) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    userMap.distributions,
                    Array.filter(userMap.launchpads, func(id: Principal) : Bool { id != canisterId }),
                    userMap.daos,
                    userMap.multisigs
                )
            };
            case (#DAOMember) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    userMap.distributions,
                    userMap.launchpads,
                    Array.filter(userMap.daos, func(id: Principal) : Bool { id != canisterId }),
                    userMap.multisigs
                )
            };
            case (#MultisigSigner) {
                FactoryRegistryTypes.createUserRelationshipMap(
                    userMap.distributions,
                    userMap.launchpads,
                    userMap.daos,
                    Array.filter(userMap.multisigs, func(id: Principal) : Bool { id != canisterId })
                )
            };
        }
    };

    // Get factory principal for relationship type
    private func getFactoryForRelationshipType(
        state: State,
        relationshipType: RelationshipType
    ) : FactoryRegistryResult<Principal> {
        let actionType = switch (relationshipType) {
            case (#DistributionRecipient) { #CreateDistribution };
            case (#LaunchpadParticipant) { #CreateTemplate }; // Assuming launchpads use template factory
            case (#DAOMember) { #CreateTemplate }; // Assuming DAOs use template factory  
            case (#MultisigSigner) { #CreateTemplate }; // Assuming multisigs use template factory
        };
        
        getFactory(state, actionType)
    };

    // Check if factory type is supported
    public func isFactoryTypeSupported(
        state: State,
        actionType: AuditTypes.ActionType
    ) : Bool {
        FactoryRegistryTypes.isFactoryTypeSupported(state.supportedFactoryTypes, actionType)
    };

    // Add new factory type to supported list
    public func addSupportedFactoryType(
        state: State,
        caller: Principal,
        actionType: AuditTypes.ActionType
    ) : FactoryRegistryResult<()> {
        
        if (not isAuthorized(state, caller)) {
            return #Err(#Unauthorized("Only authorized admins can modify supported types"));
        };

        if (FactoryRegistryTypes.isFactoryTypeSupported(state.supportedFactoryTypes, actionType)) {
            return #Err(#AlreadyExists("Action type already supported"));
        };

        state.supportedFactoryTypes := Array.append(state.supportedFactoryTypes, [actionType]);
        #Ok(())
    };

    // Add new admin principal
    public func addAdmin(
        state: State,
        caller: Principal,
        newAdmin: Principal
    ) : FactoryRegistryResult<()> {
        
        if (not isAuthorized(state, caller)) {
            return #Err(#Unauthorized("Only authorized admins can add new admins"));
        };

        if (isAuthorized(state, newAdmin)) {
            return #Err(#AlreadyExists("Principal is already an admin"));
        };

        state.adminPrincipals := Array.append(state.adminPrincipals, [newAdmin]);
        #Ok(())
    };

    // Get all supported factory types
    public func getSupportedFactoryTypes(state: State) : [AuditTypes.ActionType] {
        state.supportedFactoryTypes
    };
}