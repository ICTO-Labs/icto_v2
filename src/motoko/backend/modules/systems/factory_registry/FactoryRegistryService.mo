import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";

import FactoryRegistryTypes "FactoryRegistryTypes";
import AuditTypes "../audit/AuditTypes";
import MicroserviceTypes "../microservices/MicroserviceTypes";

module FactoryRegistryService {

    // Import types for convenience
    type State = FactoryRegistryTypes.State;
    type StableState = FactoryRegistryTypes.StableState;
    type UserCanisterRelationships = FactoryRegistryTypes.UserCanisterRelationships;
    type CanisterRelationship = FactoryRegistryTypes.CanisterRelationship;
    type RelationshipType = FactoryRegistryTypes.RelationshipType;
    type RelationshipMetadata = FactoryRegistryTypes.RelationshipMetadata;
    type FactoryRegistryResult<T> = FactoryRegistryTypes.FactoryRegistryResult<T>;
    type FactoryRegistryError = FactoryRegistryTypes.FactoryRegistryError;
    type UserRelationshipQuery = FactoryRegistryTypes.UserRelationshipQuery;
    type RelationshipQuery = FactoryRegistryTypes.RelationshipQuery;
    type UserRelationshipMap = FactoryRegistryTypes.UserRelationshipMap;

    // ==================================================================================================
    // INTEGRATION FUNCTION FOR DEPLOYMENT FLOW
    // ==================================================================================================

    // Simple batch add relationships - called from main.mo deployment flow
    public func batchAddUserRelationshipsFromFlow(
        state: State,
        microserviceState: MicroserviceTypes.State,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        name: Text,
        description: ?Text
    ) : FactoryRegistryResult<()> {
        let metadata : RelationshipMetadata = {
            name = name;
            description = description;
            additionalData = null;
        };
        
        batchAddUserRelationships(state, microserviceState, relationshipType, canisterId, users, metadata)
    };

    // ==================================================================================================
    // STATE MANAGEMENT
    // ==================================================================================================

    public func initState() : State {
        FactoryRegistryTypes.emptyState()
    };

    public func fromStableState(stableState: StableState) : State {
        let state = FactoryRegistryTypes.emptyState();
        
        // Restore user relationships
        for ((userText, userRelationships) in stableState.userRelationships.vals()) {
            state.userRelationships := Trie.put(
                state.userRelationships,
                {key = userText; hash = Text.hash(userText)},
                Text.equal,
                userRelationships
            ).0;
        };

        // Restore deployed canisters
        for ((canisterId, deployedCanister) in stableState.deployedCanisters.vals()) {
            state.deployedCanisters := Trie.put(
                state.deployedCanisters,
                {key = canisterId; hash = Principal.hash(canisterId)},
                Principal.equal,
                deployedCanister
            ).0;
        };

        // Restore canisters by type
        for ((typeText, canisters) in stableState.canistersByType.vals()) {
            state.canistersByType := Trie.put(
                state.canistersByType,
                {key = typeText; hash = Text.hash(typeText)},
                Text.equal,
                canisters
            ).0;
        };

        state
    };

    public func toStableState(state: State) : StableState {
        {
            userRelationships = Iter.toArray(Trie.iter(state.userRelationships));
            deployedCanisters = Iter.toArray(Trie.iter(state.deployedCanisters));
            canistersByType = Iter.toArray(Trie.iter(state.canistersByType));
        }
    };

    // ==================================================================================================
    // USER RELATIONSHIP FUNCTIONS  
    // ==================================================================================================

    // Internal add user relationship (no authorization check - for backend calls)
    private func addUserRelationshipInternal(
        state: State,
        microserviceState: MicroserviceTypes.State,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        let userText = Principal.toText(user);
        Debug.print("Adding user relationship: " # userText # " to " # Principal.toText(canisterId));
        
        // Get existing user relationships or create empty array
        let existingRelationships = switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?relationships) { relationships };
            case null { [] };
        };
        
        // Get factory principal for this relationship using enhanced auth (no caller = internal call)
        let factoryPrincipal = switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, null, relationshipType)) {
            case (#Ok(principal)) { principal };
            case (#Err(error)) { 
                // For internal calls, we should handle missing factory gracefully
                Debug.print("⚠️  Factory not found for relationship type: " # FactoryRegistryTypes.relationshipTypeToText(relationshipType) # " - Error: " # debug_show(error));
                // Return error instead of using invalid hardcoded principal
                return #Err(#FactoryTypeNotSupported("No factory registered for relationship type: " # FactoryRegistryTypes.relationshipTypeToText(relationshipType)));
            };
        };
        Debug.print("✅ Factory principal: " # Principal.toText(factoryPrincipal));

        // Create new relationship
        let newRelationship = FactoryRegistryTypes.createCanisterRelationship(
            canisterId,
            relationshipType,
            factoryPrincipal,
            metadata
        );
        
        // Add relationship to user's list
        let updatedRelationships = FactoryRegistryTypes.addRelationshipToUser(existingRelationships, newRelationship);
        
        // Update state
        state.userRelationships := Trie.put(
            state.userRelationships,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedRelationships
        ).0;
        
        #Ok(())
    };

    // Public add user relationship (with potential authorization for external calls)
    public func addUserRelationship(
        state: State,
        microserviceState: MicroserviceTypes.State,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        // For now, just delegate to internal - can add authorization later if needed
        addUserRelationshipInternal(state, microserviceState, user, relationshipType, canisterId, metadata)
    };

    // Internal batch add (from backend deployment flow - no authorization needed)
    public func batchAddUserRelationships(
        state: State,
        microserviceState: MicroserviceTypes.State,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        for (user in users.vals()) {
            switch (addUserRelationshipInternal(state, microserviceState, user, relationshipType, canisterId, metadata)) {
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

    // External batch add (with authorization check)
    public func batchAddUserRelationshipsExternal(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized factory for this relationship type using enhanced auth
        switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, ?caller, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                // Authorization already checked in getFactoryForRelationshipTypeWithAuth
                Debug.print("✅ Authorized caller " # Principal.toText(caller) # " for factory " # Principal.toText(factoryPrincipal));
            };
            case (#Err(error)) {
                return #Err(error);
            };
        };

        // Use internal version for actual work
        batchAddUserRelationships(state, microserviceState, relationshipType, canisterId, users, metadata)
    };

    // ==================================================================================================
    // PUBLIC CALLBACK API FOR EXTERNAL CONTRACTS
    // ==================================================================================================

    // Public API for external contracts to update user relationships
    public func updateUserRelationships(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal,
        users: [Principal],
        metadata: RelationshipMetadata
    ) : FactoryRegistryResult<()> {
        
        // First, validate that the canister is in our deployed canister registry
        switch (validateCanisterForExternalRelationship(state, canisterId, relationshipType)) {
            case (#Err(error)) {
                return #Err(error);
            };
            case (#Ok(_)) {
                Debug.print("✅ Canister " # Principal.toText(canisterId) # " is registered for relationship type " # FactoryRegistryTypes.relationshipTypeToText(relationshipType));
            };
        };
        
        // Verify caller is authorized factory for this relationship type using enhanced auth
        switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, ?caller, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                Debug.print("✅ Authorized external call from " # Principal.toText(caller) # " for factory " # Principal.toText(factoryPrincipal));
            };
            case (#Err(error)) {
                return #Err(error);
            };
        };

        // Add relationships for all users
        batchAddUserRelationships(state, microserviceState, relationshipType, canisterId, users, metadata)
    };

    // Remove user relationship
    public func removeUserRelationship(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: Principal,
        user: Principal,
        relationshipType: RelationshipType,
        canisterId: Principal
    ) : FactoryRegistryResult<()> {
        
        // Verify caller is authorized using enhanced auth
        switch (getFactoryForRelationshipTypeWithAuth(state, microserviceState, ?caller, relationshipType)) {
            case (#Ok(factoryPrincipal)) {
                Debug.print("✅ Authorized removal by " # Principal.toText(caller) # " for factory " # Principal.toText(factoryPrincipal));
            };
            case (#Err(error)) {
                return #Err(error);
            };
        };

        let userText = Principal.toText(user);
        
        // Get existing user relationships
        let existingRelationships = switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?relationships) { relationships };
            case null { return #Err(#NotFound("User has no relationships to remove")) };
        };
        
        // Remove relationship from list
        let updatedRelationships = FactoryRegistryTypes.removeRelationshipFromUser(existingRelationships, canisterId, relationshipType);
        
        // Update state
        state.userRelationships := Trie.put(
            state.userRelationships,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedRelationships
        ).0;
        
        #Ok(())
    };

    // ==================================================================================================
    // QUERY FUNCTIONS
    // ==================================================================================================

    // Get all relationships for a user (new detailed format)
    public func getUserCanisterRelationships(
        state: State,
        queryObj: UserRelationshipQuery
    ) : FactoryRegistryResult<UserCanisterRelationships> {
        
        let userText = Principal.toText(queryObj.user);
        
        switch (Trie.get(state.userRelationships, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?userRelationships) {
                var filteredRelationships = userRelationships;
                
                // Filter by relationship type if specified
                switch (queryObj.relationshipType) {
                    case (?relationshipType) {
                        filteredRelationships := FactoryRegistryTypes.filterRelationshipsByType(filteredRelationships, relationshipType);
                    };
                    case null { };
                };
                
                // Filter by active status
                filteredRelationships := FactoryRegistryTypes.filterRelationshipsByActive(filteredRelationships, queryObj.includeInactive);
                
                #Ok(filteredRelationships)
            };
            case null {
                #Ok([])
            };
        };
    };

    // Get user relationships in backward-compatible format
    public func getUserRelationships(
        state: State,
        queryObj: UserRelationshipQuery
    ) : FactoryRegistryResult<UserRelationshipMap> {
        
        switch (getUserCanisterRelationships(state, queryObj)) {
            case (#Ok(relationships)) {
                let compatibleMap = FactoryRegistryTypes.toBackwardCompatibleMap(relationships);
                #Ok(compatibleMap)
            };
            case (#Err(error)) {
                #Err(error)
            };
        }
    };

    // Query relationships with filters
    public func queryRelationships(
        state: State,
        queryObj: RelationshipQuery
    ) : FactoryRegistryResult<[CanisterRelationship]> {
        
        let buffer = Buffer.Buffer<CanisterRelationship>(0);
        let limit = Option.get(queryObj.limit, 100); // Default limit
        let offset = Option.get(queryObj.offset, 0);
        var count = 0;
        var skipped = 0;

        label relationshipLoop for ((_, userRelationships) in Trie.iter(state.userRelationships)) {
            if (count >= limit) break relationshipLoop;
            
            for (relationship in userRelationships.vals()) {
                if (count >= limit) break relationshipLoop;
                
                // Apply filters
                var matches = true;
                
                // Filter by relationship type
                switch (queryObj.relationshipType) {
                    case (?filterType) {
                        if (relationship.relationshipType != filterType) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                // Filter by canister ID
                switch (queryObj.canisterId) {
                    case (?filterCanister) {
                        if (relationship.canisterId != filterCanister) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                // Filter by factory principal
                switch (queryObj.factoryPrincipal) {
                    case (?filterFactory) {
                        if (relationship.factoryPrincipal != filterFactory) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                // Filter by active status
                switch (queryObj.isActive) {
                    case (?filterActive) {
                        if (relationship.isActive != filterActive) {
                            matches := false;
                        };
                    };
                    case null { };
                };
                
                if (matches) {
                    if (skipped < offset) {
                        skipped += 1;
                    } else {
                        buffer.add(relationship);
                        count += 1;
                    };
                };
            };
        };
        
        #Ok(Buffer.toArray(buffer))
    };

    // ==================================================================================================
    // UTILITY FUNCTIONS
    // ==================================================================================================

    // Enhanced version that checks microservice state and caller authorization
    private func getFactoryForRelationshipTypeWithAuth(
        state: State,
        microserviceState: MicroserviceTypes.State,
        caller: ?Principal,
        relationshipType: RelationshipType
    ) : FactoryRegistryResult<Principal> {
        
        // First try to get factory from microservice state based on relationship type
        switch (microserviceState.canisterIds) {
            case (?canisterIds) {
                let factoryPrincipal = switch (relationshipType) {
                    case (#DistributionRecipient) { canisterIds.distributionFactory };
                    case (#LaunchpadParticipant) { canisterIds.launchpadFactory };
                    case (#DAOMember) { canisterIds.templateFactory }; // DAOs use template factory
                    case (#MultisigSigner) { canisterIds.templateFactory }; // Multisigs use template factory
                };
                
                switch (factoryPrincipal) {
                    case (?factory) {
                        // If caller is provided, verify authorization
                        switch (caller) {
                            case (?callerPrincipal) {
                                // Check if caller is the factory itself (authorized)
                                if (callerPrincipal == factory) {
                                    return #Ok(factory);
                                };
                                
                                // Check if caller is another microservice (authorized)
                                if (isCallerInMicroservices(canisterIds, callerPrincipal)) {
                                    return #Ok(factory);
                                };
                                
// Unauthorized caller
                                return #Err(#Unauthorized("Caller not authorized to update relationships"));
                            };
                            case null {
                                // Internal call (no caller check needed)
                                return #Ok(factory);
                            };
                        };
                    };
                    case null {
                        // Factory not found in microservice state
                        return #Err(#NotFound("Factory not configured for relationship type: " # FactoryRegistryTypes.relationshipTypeToText(relationshipType)));
                    };
                };
            };
            case null {
                // Microservice not configured yet
                return #Err(#NotFound("Microservice configuration not found"));
            };
        };
    };

    // Helper function to check if caller is in microservice canister IDs
    private func isCallerInMicroservices(canisterIds: MicroserviceTypes.CanisterIds, caller: Principal) : Bool {
        // Check against all microservice canister IDs
        switch (canisterIds.distributionFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.tokenFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.templateFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.lockFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        switch (canisterIds.launchpadFactory) {
            case (?id) { if (caller == id) return true; };
            case null { };
        };
        false
    };

    // ==================================================================================================
    // DEPLOYED CANISTER REGISTRY FUNCTIONS
    // ==================================================================================================

    // Register a new deployed canister
    public func registerDeployedCanister(
        state: State,
        canisterId: Principal,
        deploymentType: FactoryRegistryTypes.DeploymentType,
        deployedBy: Principal,
        creator: Principal,
        metadata: ?{
            name: ?Text;
            description: ?Text;
            version: ?Text;
        }
    ) : FactoryRegistryResult<()> {
        
        // Check if canister already exists
        switch (Trie.get(state.deployedCanisters, {key = canisterId; hash = Principal.hash(canisterId)}, Principal.equal)) {
            case (?_) {
                return #Err(#AlreadyExists("Canister " # Principal.toText(canisterId) # " is already registered"));
            };
            case null {};
        };

        let typeText = FactoryRegistryTypes.deploymentTypeToText(deploymentType);
        
        // Create deployed canister record
        let deployedCanister = FactoryRegistryTypes.createDeployedCanister(
            canisterId,
            deploymentType,
            deployedBy,
            creator,
            metadata
        );

        // Add to main registry
        state.deployedCanisters := Trie.put(
            state.deployedCanisters,
            {key = canisterId; hash = Principal.hash(canisterId)},
            Principal.equal,
            deployedCanister
        ).0;

        // Add to type-specific list
        let currentList = switch (Trie.get(state.canistersByType, {key = typeText; hash = Text.hash(typeText)}, Text.equal)) {
            case (?list) { list };
            case null { [] };
        };
        let newList = Array.append(currentList, [canisterId]);
        state.canistersByType := Trie.put(
            state.canistersByType,
            {key = typeText; hash = Text.hash(typeText)},
            Text.equal,
            newList
        ).0;

        Debug.print("📝 Registered canister: " # Principal.toText(canisterId) # " (type: " # typeText # ")");
        #Ok(())
    };

    // Check if a canister is registered and get its info
    public func getDeployedCanister(state: State, canisterId: Principal) : ?FactoryRegistryTypes.DeployedCanister {
        Trie.get(state.deployedCanisters, {key = canisterId; hash = Principal.hash(canisterId)}, Principal.equal)
    };

    // Check if a canister was deployed by this backend
    public func isCanisterDeployedByBackend(state: State, canisterId: Principal, backendId: Principal) : Bool {
        switch (getDeployedCanister(state, canisterId)) {
            case (?canister) {
                Principal.equal(canister.deployedBy, backendId)
            };
            case null { false };
        }
    };

    // Check if a canister is of a specific type
    public func isCanisterOfType(state: State, canisterId: Principal, deploymentType: FactoryRegistryTypes.DeploymentType) : Bool {
        switch (getDeployedCanister(state, canisterId)) {
            case (?canister) {
                canister.deploymentType == deploymentType
            };
            case null { false };
        }
    };

    // Get all canisters of a specific type
    public func getCanistersByType(state: State, deploymentType: FactoryRegistryTypes.DeploymentType) : [Principal] {
        let typeText = FactoryRegistryTypes.deploymentTypeToText(deploymentType);
        switch (Trie.get(state.canistersByType, {key = typeText; hash = Text.hash(typeText)}, Text.equal)) {
            case (?list) { list };
            case null { [] };
        }
    };

    // Validate that a canister is in the registry before allowing external relationships
    public func validateCanisterForExternalRelationship(
        state: State,
        canisterId: Principal,
        relationshipType: RelationshipType
    ) : FactoryRegistryResult<()> {
        
        switch (getDeployedCanister(state, canisterId)) {
            case (?deployedCanister) {
                // Check if the relationship type matches the deployment type
                let expectedDeploymentType = switch (relationshipType) {
                    case (#DistributionRecipient) { ?#Distribution };
                    case (#LaunchpadParticipant) { ?#Launchpad };
                    case (#DAOMember) { ?#DAO };
                    case (#MultisigSigner) { ?#Multisig };
                };
                
                switch (expectedDeploymentType) {
                    case (?expectedType) {
                        if (deployedCanister.deploymentType != expectedType) {
                            return #Err(#InvalidInput("Relationship type " # FactoryRegistryTypes.relationshipTypeToText(relationshipType) # " does not match deployment type " # FactoryRegistryTypes.deploymentTypeToText(deployedCanister.deploymentType)));
                        };
                    };
                    case null {
                        // No specific type requirement
                    };
                };
                
                if (not deployedCanister.isActive) {
                    return #Err(#InvalidInput("Canister " # Principal.toText(canisterId) # " is not active"));
                };
                
                #Ok(())
            };
            case null {
                #Err(#NotFound("Canister " # Principal.toText(canisterId) # " is not registered in the deployed canister registry"));
            };
        }
    };

}