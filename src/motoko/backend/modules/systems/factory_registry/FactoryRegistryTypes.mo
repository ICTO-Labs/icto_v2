import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Int "mo:base/Int";
// import Map "mo:map/Map"; // Not needed for now

import Common "../../../shared/types/Common";

module FactoryRegistryTypes {

    // ==================================================================================================
    // Factory Registry Types
    // Hệ thống mapping các factory canister IDs với deployment types
    // và tracking các deployments liên quan đến user
    // ==================================================================================================

    // --- DEPLOYMENT TYPES ---
    
    // Flexible enum cho future expansion
    public type DeploymentType = {
        #DistributionFactory;
        #TokenFactory; 
        #TemplateFactory;
        #LaunchpadFactory;
        #NFTFactory;        // Future
        #StakingFactory;    // Future  
        #DAOFactory;        // Future
        // Có thể add thêm không cần migration
    };

    // --- STATE MANAGEMENT ---

    public type State = {
        var factoryRegistry: Trie.Trie<Text, Principal>; // deploymentType text -> factory principal
        var supportedTypes: [DeploymentType]; // array of supported deployment types
        var userDeploymentIndex: Trie.Trie<Text, UserDeploymentMap>; // user principal text -> deployment map
        var deploymentMetadata: Trie.Trie<Text, DeploymentInfo>; // deployment ID -> metadata
        var adminPrincipals: [Principal]; // authorized admins for factory registration
    };

    public type StableState = {
        factoryRegistry: [(Text, Principal)];
        supportedTypes: [DeploymentType];
        userDeploymentIndex: [(Text, UserDeploymentMap)];
        deploymentMetadata: [(Text, DeploymentInfo)];
        adminPrincipals: [Principal];
    };

    public func emptyState() : State {
        {
            var factoryRegistry = Trie.empty();
            var supportedTypes = [
                #DistributionFactory, 
                #TokenFactory, 
                #TemplateFactory, 
                #LaunchpadFactory
            ];
            var userDeploymentIndex = Trie.empty();
            var deploymentMetadata = Trie.empty();
            var adminPrincipals = [];
        }
    };

    // --- USER DEPLOYMENT MAPPING ---

    public type UserDeploymentMap = {
        distributions: [Principal]; // distribution canister IDs user is recipient of
        tokens: [Principal]; // tokens user deployed or owns
        templates: [Principal]; // templates user deployed
        launchpads: [Principal]; // launchpads user created or participated in
        nfts: [Principal]; // future
        staking: [Principal]; // future
        daos: [Principal]; // future
    };

    public func emptyUserDeploymentMap() : UserDeploymentMap {
        {
            distributions = [];
            tokens = [];
            templates = [];
            launchpads = [];
            nfts = [];
            staking = [];
            daos = [];
        }
    };

    // --- DEPLOYMENT INFO ---

    public type DeploymentInfo = {
        id: Text; // unique deployment ID
        deploymentType: DeploymentType;
        factoryPrincipal: Principal; // factory that created this
        canisterId: Principal; // deployed canister ID
        creator: Principal; // user who initiated deployment
        recipients: ?[Principal]; // for distributions, launchpads etc
        createdAt: Common.Timestamp;
        metadata: DeploymentMetadata;
    };

    public type DeploymentMetadata = {
        name: Text;
        description: ?Text;
        tags: [Text];
        isPublic: Bool;
        version: Text;
        status: DeploymentInfoStatus;
    };

    public type DeploymentInfoStatus = {
        #Active;
        #Paused;
        #Deprecated;
        #Failed: Text;
    };

    // --- RESULT TYPES ---

    public type FactoryRegistryResult<T> = {
        #Ok: T;
        #Err: FactoryRegistryError;
    };

    public type FactoryRegistryError = {
        #Unauthorized: Text;
        #NotFound: Text;
        #AlreadyExists: Text;
        #InvalidInput: Text;
        #InternalError: Text;
        #DeploymentTypNotSupported: Text;
    };

    // --- QUERY TYPES ---

    public type UserDeploymentQuery = {
        user: Principal;
        deploymentType: ?DeploymentType; // filter by type, null for all
        includeMetadata: Bool;
    };

    public type DeploymentQuery = {
        deploymentType: ?DeploymentType;
        creator: ?Principal;
        factoryPrincipal: ?Principal;
        status: ?DeploymentInfoStatus;
        limit: ?Nat;
        offset: ?Nat;
    };

    // --- UTILITY FUNCTIONS ---

    // Helper function to append to array
    private func appendToArray(arr: [Principal], item: Principal) : [Principal] {
        Array.append(arr, [item])
    };

    public func deploymentTypeToText(deploymentType: DeploymentType) : Text {
        switch (deploymentType) {
            case (#DistributionFactory) { "DistributionFactory" };
            case (#TokenFactory) { "TokenFactory" };
            case (#TemplateFactory) { "TemplateFactory" };
            case (#LaunchpadFactory) { "LaunchpadFactory" };
            case (#NFTFactory) { "NFTFactory" };
            case (#StakingFactory) { "StakingFactory" };
            case (#DAOFactory) { "DAOFactory" };
        }
    };

    public func textToDeploymentType(text: Text) : ?DeploymentType {
        switch (text) {
            case ("DistributionFactory") { ?#DistributionFactory };
            case ("TokenFactory") { ?#TokenFactory };
            case ("TemplateFactory") { ?#TemplateFactory };
            case ("LaunchpadFactory") { ?#LaunchpadFactory };
            case ("NFTFactory") { ?#NFTFactory };
            case ("StakingFactory") { ?#StakingFactory };
            case ("DAOFactory") { ?#DAOFactory };
            case (_) { null };
        }
    };

    public func isDeploymentTypeSupported(supportedTypes: [DeploymentType], deploymentType: DeploymentType) : Bool {
        for (supportedType in supportedTypes.vals()) {
            if (supportedType == deploymentType) {
                return true;
            };
        };
        false
    };

    public func generateDeploymentId(
        deploymentType: DeploymentType,
        creator: Principal,
        timestamp: Common.Timestamp
    ) : Text {
        let typeText = deploymentTypeToText(deploymentType);
        let creatorText = Principal.toText(creator);
        let timeText = Int.toText(timestamp / 1_000_000); // Convert ns to ms
        typeText # ":" # creatorText # ":" # timeText
    };

    // Tạo user deployment map từ các arrays
    public func createUserDeploymentMap(
        distributions: [Principal],
        tokens: [Principal],
        templates: [Principal],
        launchpads: [Principal],
        nfts: [Principal],
        staking: [Principal],
        daos: [Principal]
    ) : UserDeploymentMap {
        {
            distributions = distributions;
            tokens = tokens;
            templates = templates;
            launchpads = launchpads;
            nfts = nfts;
            staking = staking;
            daos = daos;
        }
    };

    // Thêm deployment vào user map
    public func addDeploymentToUserMap(
        userMap: UserDeploymentMap,
        deploymentType: DeploymentType,
        canisterId: Principal
    ) : UserDeploymentMap {
        switch (deploymentType) {
            case (#DistributionFactory) {
                createUserDeploymentMap(
                    appendToArray(userMap.distributions, canisterId),
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#TokenFactory) {
                createUserDeploymentMap(
                    userMap.distributions,
                    appendToArray(userMap.tokens, canisterId),
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#TemplateFactory) {
                createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    appendToArray(userMap.templates, canisterId),
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#LaunchpadFactory) {
                createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    appendToArray(userMap.launchpads, canisterId),
                    userMap.nfts,
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#NFTFactory) {
                createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    appendToArray(userMap.nfts, canisterId),
                    userMap.staking,
                    userMap.daos
                )
            };
            case (#StakingFactory) {
                createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    appendToArray(userMap.staking, canisterId),
                    userMap.daos
                )
            };
            case (#DAOFactory) {
                createUserDeploymentMap(
                    userMap.distributions,
                    userMap.tokens,
                    userMap.templates,
                    userMap.launchpads,
                    userMap.nfts,
                    userMap.staking,
                    appendToArray(userMap.daos, canisterId)
                )
            };
        }
    };
}