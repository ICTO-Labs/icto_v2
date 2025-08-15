import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import Array "mo:base/Array";

import Common "../../../shared/types/Common";
import AuditTypes "../audit/AuditTypes";

module FactoryRegistryTypes {

    // ==================================================================================================
    // Factory Registry Types - User-Centric Architecture
    // Purpose: Track user relationships with various canisters using a single user-centric map
    // Simplified from complex relationshipId system to avoid Principal conversion errors
    // ==================================================================================================

    // --- CANISTER RELATIONSHIP INFO ---
    
    public type CanisterRelationship = {
        canisterId: Principal;
        relationshipType: RelationshipType;
        factoryPrincipal: Principal;
        createdAt: Common.Timestamp;
        metadata: RelationshipMetadata;
        isActive: Bool;
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
        additionalData: ?Text; // JSON string for extra data
    };

    // --- USER-CENTRIC STORAGE ---
    
    // Single map: User Principal -> List of their canister relationships
    public type UserCanisterRelationships = [CanisterRelationship];

    // --- DEPLOYED CANISTER TRACKING ---
    
    public type DeployedCanister = {
        canisterId: Principal;
        deploymentType: DeploymentType;
        deployedBy: Principal; // Backend that deployed this
        creator: Principal; // User who requested deployment
        deployedAt: Common.Timestamp;
        metadata: ?{
            name: ?Text;
            description: ?Text;
            version: ?Text;
        };
        isActive: Bool;
    };

    public type DeploymentType = {
        #Token;
        #Distribution;
        #Launchpad;
        #Lock;
        #Template;
        #DAO;
        #Multisig;
    };

    // --- FACTORY REGISTRY STATE ---
    
    public type State = {
        var userRelationships: Trie.Trie<Text, UserCanisterRelationships>; // user principal text -> relationships
        var deployedCanisters: Trie.Trie<Principal, DeployedCanister>; // canister id -> deployed canister info
        var canistersByType: Trie.Trie<Text, [Principal]>; // deployment type text -> list of canister ids
    };

    public type StableState = {
        userRelationships: [(Text, UserCanisterRelationships)];
        deployedCanisters: [(Principal, DeployedCanister)];
        canistersByType: [(Text, [Principal])];
    };

    public func emptyState() : State {
        {
            var userRelationships = Trie.empty();
            var deployedCanisters = Trie.empty();
            var canistersByType = Trie.empty();
        }
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

    // Create new canister relationship
    public func createCanisterRelationship(
        canisterId: Principal,
        relationshipType: RelationshipType,
        factoryPrincipal: Principal,
        metadata: RelationshipMetadata
    ) : CanisterRelationship {
        {
            canisterId = canisterId;
            relationshipType = relationshipType;
            factoryPrincipal = factoryPrincipal;
            createdAt = Time.now();
            metadata = metadata;
            isActive = true;
        }
    };

    // Add relationship to user's list
    public func addRelationshipToUser(
        userRelationships: UserCanisterRelationships,
        newRelationship: CanisterRelationship
    ) : UserCanisterRelationships {
        // Check if relationship already exists
        for (existing in userRelationships.vals()) {
            if (existing.canisterId == newRelationship.canisterId and 
                existing.relationshipType == newRelationship.relationshipType) {
                // Relationship already exists, return unchanged
                return userRelationships;
            };
        };
        
        // Add new relationship
        Array.append(userRelationships, [newRelationship])
    };

    // Remove relationship from user's list
    public func removeRelationshipFromUser(
        userRelationships: UserCanisterRelationships,
        canisterId: Principal,
        relationshipType: RelationshipType
    ) : UserCanisterRelationships {
        Array.filter(userRelationships, func(rel: CanisterRelationship) : Bool {
            not (rel.canisterId == canisterId and rel.relationshipType == relationshipType)
        })
    };

    // Filter relationships by type
    public func filterRelationshipsByType(
        userRelationships: UserCanisterRelationships,
        relationshipType: RelationshipType
    ) : UserCanisterRelationships {
        Array.filter(userRelationships, func(rel: CanisterRelationship) : Bool {
            rel.relationshipType == relationshipType
        })
    };

    // Filter relationships by active status
    public func filterRelationshipsByActive(
        userRelationships: UserCanisterRelationships,
        includeInactive: Bool
    ) : UserCanisterRelationships {
        if (includeInactive) {
            userRelationships
        } else {
            Array.filter(userRelationships, func(rel: CanisterRelationship) : Bool {
                rel.isActive
            })
        }
    };

    // Extract canister IDs by relationship type (for backward compatibility)
    public func extractCanisterIdsByType(
        userRelationships: UserCanisterRelationships,
        relationshipType: RelationshipType
    ) : [Principal] {
        let filtered = filterRelationshipsByType(userRelationships, relationshipType);
        Array.map(filtered, func(rel: CanisterRelationship) : Principal {
            rel.canisterId
        })
    };

    // Create backward-compatible UserRelationshipMap
    public type UserRelationshipMap = {
        distributions: [Principal];
        launchpads: [Principal];
        daos: [Principal];
        multisigs: [Principal];
    };

    public func toBackwardCompatibleMap(userRelationships: UserCanisterRelationships) : UserRelationshipMap {
        {
            distributions = extractCanisterIdsByType(userRelationships, #DistributionRecipient);
            launchpads = extractCanisterIdsByType(userRelationships, #LaunchpadParticipant);
            daos = extractCanisterIdsByType(userRelationships, #DAOMember);
            multisigs = extractCanisterIdsByType(userRelationships, #MultisigSigner);
        }
    };

    public func emptyUserRelationshipMap() : UserRelationshipMap {
        {
            distributions = [];
            launchpads = [];
            daos = [];
            multisigs = [];
        }
    };

    // --- DEPLOYMENT TYPE UTILITIES ---

    public func deploymentTypeToText(dt: DeploymentType) : Text {
        switch (dt) {
            case (#Token) { "Token" };
            case (#Distribution) { "Distribution" };
            case (#Launchpad) { "Launchpad" };
            case (#Lock) { "Lock" };
            case (#Template) { "Template" };
            case (#DAO) { "DAO" };
            case (#Multisig) { "Multisig" };
        }
    };

    public func textToDeploymentType(text: Text) : ?DeploymentType {
        switch (text) {
            case ("Token") { ?#Token };
            case ("Distribution") { ?#Distribution };
            case ("Launchpad") { ?#Launchpad };
            case ("Lock") { ?#Lock };
            case ("Template") { ?#Template };
            case ("DAO") { ?#DAO };
            case ("Multisig") { ?#Multisig };
            case (_) { null };
        }
    };

    // Create new deployed canister record
    public func createDeployedCanister(
        canisterId: Principal,
        deploymentType: DeploymentType,
        deployedBy: Principal,
        creator: Principal,
        metadata: ?{
            name: ?Text;
            description: ?Text;
            version: ?Text;
        }
    ) : DeployedCanister {
        {
            canisterId = canisterId;
            deploymentType = deploymentType;
            deployedBy = deployedBy;
            creator = creator;
            deployedAt = Time.now();
            metadata = metadata;
            isActive = true;
        }
    };
}