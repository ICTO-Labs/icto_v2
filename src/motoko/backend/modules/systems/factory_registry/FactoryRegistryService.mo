import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Int "mo:base/Int";

import Common "../../../shared/types/Common";
import FactoryRegistryTypes "FactoryRegistryTypes";

module FactoryRegistryService {

    // Import types for convenience
    type State = FactoryRegistryTypes.State;
    type StableState = FactoryRegistryTypes.StableState;
    type DeploymentType = FactoryRegistryTypes.DeploymentType;
    type UserDeploymentMap = FactoryRegistryTypes.UserDeploymentMap;
    type DeploymentInfo = FactoryRegistryTypes.DeploymentInfo;
    type DeploymentMetadata = FactoryRegistryTypes.DeploymentMetadata;
    type FactoryRegistryResult<T> = FactoryRegistryTypes.FactoryRegistryResult<T>;
    type FactoryRegistryError = FactoryRegistryTypes.FactoryRegistryError;
    type UserDeploymentQuery = FactoryRegistryTypes.UserDeploymentQuery;
    type DeploymentQuery = FactoryRegistryTypes.DeploymentQuery;

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
        for ((deploymentTypeText, factoryPrincipal) in stableState.factoryRegistry.vals()) {
            state.factoryRegistry := Trie.put(
                state.factoryRegistry, 
                {key = deploymentTypeText; hash = Text.hash(deploymentTypeText)}, 
                Text.equal, 
                factoryPrincipal
            ).0;
        };

        // Restore user deployment index
        for ((userText, userMap) in stableState.userDeploymentIndex.vals()) {
            state.userDeploymentIndex := Trie.put(
                state.userDeploymentIndex,
                {key = userText; hash = Text.hash(userText)},
                Text.equal,
                userMap
            ).0;
        };

        // Restore deployment metadata
        for ((deploymentId, deploymentInfo) in stableState.deploymentMetadata.vals()) {
            state.deploymentMetadata := Trie.put(
                state.deploymentMetadata,
                {key = deploymentId; hash = Text.hash(deploymentId)},
                Text.equal,
                deploymentInfo
            ).0;
        };

        // Restore other fields
        state.supportedTypes := stableState.supportedTypes;
        state.adminPrincipals := stableState.adminPrincipals;

        state
    };

    public func toStableState(state: State) : StableState {
        {
            factoryRegistry = Iter.toArray(Trie.iter(state.factoryRegistry));
            supportedTypes = state.supportedTypes;
            userDeploymentIndex = Iter.toArray(Trie.iter(state.userDeploymentIndex));
            deploymentMetadata = Iter.toArray(Trie.iter(state.deploymentMetadata));
            adminPrincipals = state.adminPrincipals;
        }
    };

    // ==================================================================================================
    // FACTORY REGISTRY FUNCTIONS
    // ==================================================================================================

    // Register a factory for a specific deployment type
    public func registerFactory(
        state: State,
        caller: Principal,
        deploymentType: DeploymentType,
        factoryPrincipal: Principal
    ) : FactoryRegistryResult<()> {
        
        // Check authorization
        if (not isAuthorized(state, caller)) {
            return #Err(#Unauthorized("Only authorized admins can register factories"));
        };

        // Check if deployment type is supported
        if (not FactoryRegistryTypes.isDeploymentTypeSupported(state.supportedTypes, deploymentType)) {
            return #Err(#DeploymentTypNotSupported("Deployment type not supported"));
        };

        let deploymentTypeText = FactoryRegistryTypes.deploymentTypeToText(deploymentType);
        
        // Check if factory already exists for this type
        switch (Trie.get(state.factoryRegistry, {key = deploymentTypeText; hash = Text.hash(deploymentTypeText)}, Text.equal)) {
            case (?existingFactory) {
                if (existingFactory == factoryPrincipal) {
                    return #Err(#AlreadyExists("Factory already registered for this deployment type"));
                } else {
                    // Update existing registration
                    state.factoryRegistry := Trie.put(
                        state.factoryRegistry,
                        {key = deploymentTypeText; hash = Text.hash(deploymentTypeText)},
                        Text.equal,
                        factoryPrincipal
                    ).0;
                    return #Ok(());
                };
            };
            case null {
                // Register new factory
                state.factoryRegistry := Trie.put(
                    state.factoryRegistry,
                    {key = deploymentTypeText; hash = Text.hash(deploymentTypeText)},
                    Text.equal,
                    factoryPrincipal
                ).0;
                return #Ok(());
            };
        };
    };

    // Get factory principal for a deployment type
    public func getFactory(
        state: State,
        deploymentType: DeploymentType
    ) : FactoryRegistryResult<Principal> {
        
        let deploymentTypeText = FactoryRegistryTypes.deploymentTypeToText(deploymentType);
        
        switch (Trie.get(state.factoryRegistry, {key = deploymentTypeText; hash = Text.hash(deploymentTypeText)}, Text.equal)) {
            case (?factoryPrincipal) {
                #Ok(factoryPrincipal)
            };
            case null {
                #Err(#NotFound("No factory registered for deployment type: " # deploymentTypeText))
            };
        };
    };

    // ==================================================================================================
    // USER DEPLOYMENT INDEX FUNCTIONS
    // ==================================================================================================

    // Add deployment to user's index
    public func addUserDeployment(
        state: State,
        user: Principal,
        deploymentType: DeploymentType,
        deploymentId: Principal
    ) : FactoryRegistryResult<()> {
        
        let userText = Principal.toText(user);
        
        // Get existing user deployment map or create new one
        let existingMap = switch (Trie.get(state.userDeploymentIndex, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?map) { map };
            case null { FactoryRegistryTypes.emptyUserDeploymentMap() };
        };
        
        // Add new deployment to map
        let updatedMap = FactoryRegistryTypes.addDeploymentToUserMap(existingMap, deploymentType, deploymentId);
        
        // Update state
        state.userDeploymentIndex := Trie.put(
            state.userDeploymentIndex,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedMap
        ).0;
        
        #Ok(())
    };

    // Get all deployments for a user
    public func getUserDeployments(
        state: State,
        queryObj: UserDeploymentQuery
    ) : FactoryRegistryResult<UserDeploymentMap> {
        
        let userText = Principal.toText(queryObj.user);
        
        switch (Trie.get(state.userDeploymentIndex, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?userMap) {
                // Filter by deployment type if specified
                switch (queryObj.deploymentType) {
                    case (?deploymentType) {
                        let filteredMap = filterUserMapByType(userMap, deploymentType);
                        #Ok(filteredMap)
                    };
                    case null {
                        #Ok(userMap)
                    };
                };
            };
            case null {
                #Ok(FactoryRegistryTypes.emptyUserDeploymentMap())
            };
        };
    };

    // Batch add recipients to deployment index
    public func batchAddRecipients(
        state: State,
        deploymentType: DeploymentType,
        deploymentId: Principal,
        recipients: [Principal]
    ) : FactoryRegistryResult<()> {
        
        for (recipient in recipients.vals()) {
            switch (addUserDeployment(state, recipient, deploymentType, deploymentId)) {
                case (#Err(error)) {
                    return #Err(error);
                };
                case (#Ok(_)) {
                    // Continue to next recipient
                };
            };
        };
        
        #Ok(())
    };

    // ==================================================================================================
    // DEPLOYMENT METADATA FUNCTIONS
    // ==================================================================================================

    // Main integration function - called after deployment
    public func postDeploymentCallback(
        state: State,
        creator: Principal,
        deploymentType: DeploymentType,
        deploymentId: Principal,
        recipients: ?[Principal],
        metadata: DeploymentMetadata
    ) : FactoryRegistryResult<Text> {
        
        // Get factory principal
        let factoryResult = getFactory(state, deploymentType);
        let factoryPrincipal = switch (factoryResult) {
            case (#Ok(principal)) { principal };
            case (#Err(error)) { return #Err(error); };
        };

        // Generate unique deployment info ID
        let deploymentInfoId = FactoryRegistryTypes.generateDeploymentId(
            deploymentType,
            creator,
            Time.now()
        );

        // Create deployment info
        let deploymentInfo : DeploymentInfo = {
            id = deploymentInfoId;
            deploymentType = deploymentType;
            factoryPrincipal = factoryPrincipal;
            canisterId = deploymentId;
            creator = creator;
            recipients = recipients;
            createdAt = Time.now();
            metadata = metadata;
        };

        // Store deployment metadata
        state.deploymentMetadata := Trie.put(
            state.deploymentMetadata,
            {key = deploymentInfoId; hash = Text.hash(deploymentInfoId)},
            Text.equal,
            deploymentInfo
        ).0;

        // Add deployment to creator's index
        switch (addUserDeployment(state, creator, deploymentType, deploymentId)) {
            case (#Err(error)) {
                return #Err(error);
            };
            case (#Ok(_)) {
                // Continue
            };
        };

        // Add deployment to recipients' index if provided
        switch (recipients) {
            case (?recipientList) {
                switch (batchAddRecipients(state, deploymentType, deploymentId, recipientList)) {
                    case (#Err(error)) {
                        return #Err(error);
                    };
                    case (#Ok(_)) {
                        // Continue
                    };
                };
            };
            case null {
                // No recipients to add
            };
        };

        #Ok(deploymentInfoId)
    };

    // ==================================================================================================
    // QUERY FUNCTIONS
    // ==================================================================================================

    // Query deployments with filters
    public func queryDeployments(
        state: State,
        queryObj: DeploymentQuery
    ) : FactoryRegistryResult<[DeploymentInfo]> {
        
        let buffer = Buffer.Buffer<DeploymentInfo>(0);
        let limit = Option.get(queryObj.limit, 100); // Default limit
        let offset = Option.get(queryObj.offset, 0);
        var count = 0;
        var skipped = 0;

        label deploymentLoop for ((_, deploymentInfo) in Trie.iter(state.deploymentMetadata)) {
            if (count >= limit) break deploymentLoop;
            
            // Apply filters
            var matches = true;
            
            // Filter by deployment type
            switch (queryObj.deploymentType) {
                case (?filterType) {
                    if (deploymentInfo.deploymentType != filterType) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            // Filter by creator
            switch (queryObj.creator) {
                case (?filterCreator) {
                    if (deploymentInfo.creator != filterCreator) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            // Filter by factory principal
            switch (queryObj.factoryPrincipal) {
                case (?filterFactory) {
                    if (deploymentInfo.factoryPrincipal != filterFactory) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            // Filter by status
            switch (queryObj.status) {
                case (?filterStatus) {
                    if (deploymentInfo.metadata.status != filterStatus) {
                        matches := false;
                    };
                };
                case null { };
            };
            
            if (matches) {
                if (skipped < offset) {
                    skipped += 1;
                } else {
                    buffer.add(deploymentInfo);
                    count += 1;
                };
            };
        };
        
        #Ok(Buffer.toArray(buffer))
    };

    // Get deployment info by ID
    public func getDeploymentInfo(
        state: State,
        deploymentId: Text
    ) : FactoryRegistryResult<DeploymentInfo> {
        
        switch (Trie.get(state.deploymentMetadata, {key = deploymentId; hash = Text.hash(deploymentId)}, Text.equal)) {
            case (?deploymentInfo) {
                #Ok(deploymentInfo)
            };
            case null {
                #Err(#NotFound("Deployment info not found for ID: " # deploymentId))
            };
        };
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

    // Filter user deployment map by deployment type
    private func filterUserMapByType(userMap: UserDeploymentMap, deploymentType: DeploymentType) : UserDeploymentMap {
        switch (deploymentType) {
            case (#DistributionFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions, [], [], [], [], [], []
                )
            };
            case (#TokenFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    [], userMap.tokens, [], [], [], [], []
                )
            };
            case (#TemplateFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    [], [], userMap.templates, [], [], [], []
                )
            };
            case (#LaunchpadFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    [], [], [], userMap.launchpads, [], [], []
                )
            };
            case (#NFTFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    [], [], [], [], userMap.nfts, [], []
                )
            };
            case (#StakingFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    [], [], [], [], [], userMap.staking, []
                )
            };
            case (#DAOFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    [], [], [], [], [], [], userMap.daos
                )
            };
        };
    };

    // Check if deployment type is supported
    public func isDeploymentTypeSupported(
        state: State,
        deploymentType: DeploymentType
    ) : Bool {
        FactoryRegistryTypes.isDeploymentTypeSupported(state.supportedTypes, deploymentType)
    };

    // Add new deployment type to supported list
    public func addSupportedDeploymentType(
        state: State,
        caller: Principal,
        deploymentType: DeploymentType
    ) : FactoryRegistryResult<()> {
        
        if (not isAuthorized(state, caller)) {
            return #Err(#Unauthorized("Only authorized admins can modify supported types"));
        };

        if (FactoryRegistryTypes.isDeploymentTypeSupported(state.supportedTypes, deploymentType)) {
            return #Err(#AlreadyExists("Deployment type already supported"));
        };

        state.supportedTypes := Array.append(state.supportedTypes, [deploymentType]);
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

    // Get all supported deployment types
    public func getSupportedTypes(state: State) : [DeploymentType] {
        state.supportedTypes
    };

    // Remove user deployment from registry
    public func removeUserDeployment(
        state: State,
        user: Principal,
        deploymentType: DeploymentType,
        canisterId: Principal
    ) : FactoryRegistryResult<()> {
        let userText = Principal.toText(user);
        
        // Get existing user deployment map
        let existingMap = switch (Trie.get(state.userDeploymentIndex, {key = userText; hash = Text.hash(userText)}, Text.equal)) {
            case (?map) { map };
            case null { return #Err(#NotFound("User has no deployments to remove")) };
        };
        
        // Remove deployment from appropriate array
        let updatedMap = removeDeploymentFromUserMap(existingMap, deploymentType, canisterId);
        
        // Update state
        state.userDeploymentIndex := Trie.put(
            state.userDeploymentIndex,
            {key = userText; hash = Text.hash(userText)},
            Text.equal,
            updatedMap
        ).0;
        
        #Ok(())
    };

    // Update deployment metadata
    public func updateDeploymentMetadata(
        state: State,
        deploymentId: Text,
        newMetadata: DeploymentMetadata
    ) : FactoryRegistryResult<()> {
        // Get existing deployment info
        switch (Trie.get(state.deploymentMetadata, {key = deploymentId; hash = Text.hash(deploymentId)}, Text.equal)) {
            case (?existingInfo) {
                let updatedInfo : DeploymentInfo = {
                    id = existingInfo.id;
                    deploymentType = existingInfo.deploymentType;
                    factoryPrincipal = existingInfo.factoryPrincipal;
                    canisterId = existingInfo.canisterId;
                    creator = existingInfo.creator;
                    recipients = existingInfo.recipients;
                    createdAt = existingInfo.createdAt;
                    metadata = newMetadata;
                };
                
                // Update state
                state.deploymentMetadata := Trie.put(
                    state.deploymentMetadata,
                    {key = deploymentId; hash = Text.hash(deploymentId)},
                    Text.equal,
                    updatedInfo
                ).0;
                
                #Ok(())
            };
            case null {
                #Err(#NotFound("Deployment not found for ID: " # deploymentId))
            };
        };
    };

    // Get all registered factories
    public func getAllFactories(state: State) : [(DeploymentType, Principal)] {
        let buffer = Buffer.Buffer<(DeploymentType, Principal)>(0);
        
        for ((deploymentTypeText, factoryPrincipal) in Trie.iter(state.factoryRegistry)) {
            switch (FactoryRegistryTypes.textToDeploymentType(deploymentTypeText)) {
                case (?deploymentType) {
                    buffer.add((deploymentType, factoryPrincipal));
                };
                case null {
                    // Skip invalid deployment types
                };
            };
        };
        
        Buffer.toArray(buffer)
    };

    // ==================================================================================================
    // HELPER FUNCTIONS
    // ==================================================================================================

    // Remove deployment from user map
    private func removeDeploymentFromUserMap(
        userMap: UserDeploymentMap,
        deploymentType: DeploymentType,
        canisterId: Principal
    ) : UserDeploymentMap {
        switch (deploymentType) {
            case (#DistributionFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    Array.filter(userMap.distributions, func(id: Principal) : Bool { id != canisterId }),
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#TokenFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions,
                    Array.filter(userMap.tokens, func(id: Principal) : Bool { id != canisterId }),
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#TemplateFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    Array.filter(userMap.templates, func(id: Principal) : Bool { id != canisterId }),
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#LaunchpadFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    Array.filter(userMap.launchpads, func(id: Principal) : Bool { id != canisterId }),
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#NFTFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    Array.filter(userMap.nfts, func(id: Principal) : Bool { id != canisterId }),
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#StakingFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    Array.filter(userMap.staking, func(id: Principal) : Bool { id != canisterId }),
                    userMap.daos
                )
            };
            case (#DAOFactory) {
                FactoryRegistryTypes.createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    Array.filter(userMap.daos, func(id: Principal) : Bool { id != canisterId })
                )
            };
        }
    };
}