import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Int "mo:base/Int";

import Common "../../../shared/types/Common";
import AuditTypes "../audit/AuditTypes";

module FactoryRegistryTypes {

    // ==================================================================================================
    // Factory Registry Types
    // Purpose: Track user relationships with various canisters (not deployments they own)
    // Example: User participates in launchpad, is recipient in distribution, etc.
    // Note: User-owned deployments are tracked in UserService
    // ==================================================================================================

    // --- USER RELATIONSHIP MAPPING ---
    
    // Track what canisters a user has relationships with (not ownership)
    public type UserRelationshipMap = {
        distributions: [Principal]; // distributions where user is recipient
        launchpads: [Principal]; // launchpads user participated in
        daos: [Principal]; // DAOs user is member of
        multisigs: [Principal]; // multisig wallets user is signer of
        // Can add more relationship types as needed
    };

    public func emptyUserRelationshipMap() : UserRelationshipMap {
        {
            distributions = [];
            launchpads = [];
            daos = [];
            multisigs = [];
        }
    };

    // --- FACTORY REGISTRY STATE ---

    public type State = {
        var factoryRegistry: Trie.Trie<Text, Principal>; // actionType text -> factory principal
        var supportedFactoryTypes: [AuditTypes.ActionType]; // supported factory types
        var userRelationships: Trie.Trie<Text, UserRelationshipMap>; // user principal text -> relationships
        var relationshipMetadata: Trie.Trie<Text, RelationshipInfo>; // relationship ID -> metadata
        var adminPrincipals: [Principal]; // authorized admins
    };

    public type StableState = {
        factoryRegistry: [(Text, Principal)];
        supportedFactoryTypes: [AuditTypes.ActionType];
        userRelationships: [(Text, UserRelationshipMap)];
        relationshipMetadata: [(Text, RelationshipInfo)];
        adminPrincipals: [Principal];
    };

    public func emptyState() : State {
        {
            var factoryRegistry = Trie.empty();
            var supportedFactoryTypes = [
                #CreateDistribution,
                #CreateToken, 
                #CreateTemplate
                // Add more as factories are developed
            ];
            var userRelationships = Trie.empty();
            var relationshipMetadata = Trie.empty();
            var adminPrincipals = [];
        }
    };

    // --- RELATIONSHIP METADATA ---

    public type RelationshipInfo = {
        id: Text; // unique relationship ID
        relationshipType: RelationshipType;
        canisterId: Principal; // target canister
        userId: Principal; // user in relationship
        factoryPrincipal: Principal; // factory that created the canister
        createdAt: Common.Timestamp;
        metadata: RelationshipMetadata;
    };

    public type RelationshipType = {
        #DistributionRecipient; // User is recipient in distribution
        #LaunchpadParticipant; // User participated in launchpad
        #DAOMember; // User is DAO member
        #MultisigSigner; // User is multisig signer
        // Add more relationship types as needed
    };

    public type RelationshipMetadata = {
        name: Text; // Human readable name
        description: ?Text;
        isActive: Bool; // Whether relationship is still active
        additionalData: ?Text; // JSON string for extra data
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
        #FactoryTypeNotSupported: Text;
    };

    // --- QUERY TYPES ---

    public type UserRelationshipQuery = {
        user: Principal;
        relationshipType: ?RelationshipType; // filter by type, null for all
        includeInactive: Bool; // include inactive relationships
    };

    public type RelationshipQuery = {
        relationshipType: ?RelationshipType;
        canisterId: ?Principal;
        factoryPrincipal: ?Principal;
        isActive: ?Bool;
        limit: ?Nat;
        offset: ?Nat;
    };

    // --- UTILITY FUNCTIONS ---

    public func actionTypeToText(actionType: AuditTypes.ActionType) : Text {
        switch (actionType) {
            case (#CreateDistribution) { "CreateDistribution" };
            case (#CreateToken) { "CreateToken" };
            case (#CreateTemplate) { "CreateTemplate" };
            case (#ServiceFee(serviceName)) { "ServiceFee:" # serviceName };
            case (#CreateProject) { "CreateProject" };
            case (#UpdateProject) { "UpdateProject" };
            case (#DeleteProject) { "DeleteProject" };
            case (#StartPipeline) { "StartPipeline" };
            case (#StepCompleted) { "StepCompleted" };
            case (#StepFailed) { "StepFailed" };
            case (#PipelineCompleted) { "PipelineCompleted" };
            case (#PipelineFailed) { "PipelineFailed" };
            case (#FeeValidation) { "FeeValidation" };
            case (#PaymentProcessed) { "PaymentProcessed" };
            case (#PaymentFailed) { "PaymentFailed" };
            case (#RefundProcessed) { "RefundProcessed" };
            case (#RefundRequest) { "RefundRequest" };
            case (#RefundFailed) { "RefundFailed" };
            case (#AdminLogin) { "AdminLogin" };
            case (#UpdateSystemConfig) { "UpdateSystemConfig" };
            case (#ServiceMaintenance) { "ServiceMaintenance" };
            case (#UserManagement) { "UserManagement" };
            case (#SystemUpgrade) { "SystemUpgrade" };
            case (#StatusUpdate) { "StatusUpdate" };
            case (#AccessDenied) { "AccessDenied" };
            case (#AccessGranted) { "AccessGranted" };
            case (#GrantAccess) { "GrantAccess" };
            case (#RevokeAccess) { "RevokeAccess" };
            case (#AccessRevoked) { "AccessRevoked" };
            case (#Custom(text)) { "Custom:" # text };
            case (#AdminAction(text)) { "AdminAction:" # text };
        }
    };

    public func isFactoryTypeSupported(supportedTypes: [AuditTypes.ActionType], actionType: AuditTypes.ActionType) : Bool {
        for (supportedType in supportedTypes.vals()) {
            if (supportedType == actionType) {
                return true;
            };
        };
        false
    };

    public func generateRelationshipId(
        relationshipType: RelationshipType,
        user: Principal,
        canisterId: Principal,
        timestamp: Common.Timestamp
    ) : Text {
        let typeText = relationshipTypeToText(relationshipType);
        let userText = Principal.toText(user);
        let canisterText = Principal.toText(canisterId);
        let timeText = Int.toText(timestamp / 1_000_000); // Convert ns to ms
        typeText # ":" # userText # ":" # canisterText # ":" # timeText
    };

    public func relationshipTypeToText(relationshipType: RelationshipType) : Text {
        switch (relationshipType) {
            case (#DistributionRecipient) { "DistributionRecipient" };
            case (#LaunchpadParticipant) { "LaunchpadParticipant" };
            case (#DAOMember) { "DAOMember" };
            case (#MultisigSigner) { "MultisigSigner" };
        }
    };

    public func textToRelationshipType(text: Text) : ?RelationshipType {
        switch (text) {
            case ("DistributionRecipient") { ?#DistributionRecipient };
            case ("LaunchpadParticipant") { ?#LaunchpadParticipant };
            case ("DAOMember") { ?#DAOMember };
            case ("MultisigSigner") { ?#MultisigSigner };
            case (_) { null };
        }
    };

    // Create user relationship map from arrays
    public func createUserRelationshipMap(
        distributions: [Principal],
        launchpads: [Principal],
        daos: [Principal],
        multisigs: [Principal]
    ) : UserRelationshipMap {
        {
            distributions = distributions;
            launchpads = launchpads;
            daos = daos;
            multisigs = multisigs;
        }
    };

    // Add relationship to user map
    public func addRelationshipToUserMap(
        userMap: UserRelationshipMap,
        relationshipType: RelationshipType,
        canisterId: Principal
    ) : UserRelationshipMap {
        switch (relationshipType) {
            case (#DistributionRecipient) {
                createUserRelationshipMap(
                    Array.append(userMap.distributions, [canisterId]),
                    userMap.launchpads,
                    userMap.daos,
                    userMap.multisigs
                )
            };
            case (#LaunchpadParticipant) {
                createUserRelationshipMap(
                    userMap.distributions,
                    Array.append(userMap.launchpads, [canisterId]),
                    userMap.daos,
                    userMap.multisigs
                )
            };
            case (#DAOMember) {
                createUserRelationshipMap(
                    userMap.distributions,
                    userMap.launchpads,
                    Array.append(userMap.daos, [canisterId]),
                    userMap.multisigs
                )
            };
            case (#MultisigSigner) {
                createUserRelationshipMap(
                    userMap.distributions,
                    userMap.launchpads,
                    userMap.daos,
                    Array.append(userMap.multisigs, [canisterId])
                )
            };
        }
    };
}