import Principal "mo:base/Principal";

import FactoryRegistryTypes "FactoryRegistryTypes";
import AuditTypes "../audit/AuditTypes";

module FactoryRegistryInterface {

    // Import types for convenience
    type RelationshipType = FactoryRegistryTypes.RelationshipType;
    type UserRelationshipMap = FactoryRegistryTypes.UserRelationshipMap;
    type UserCanisterRelationships = FactoryRegistryTypes.UserCanisterRelationships;
    type CanisterRelationship = FactoryRegistryTypes.CanisterRelationship;
    type RelationshipMetadata = FactoryRegistryTypes.RelationshipMetadata;
    type FactoryRegistryResult<T> = FactoryRegistryTypes.FactoryRegistryResult<T>;
    type UserRelationshipQuery = FactoryRegistryTypes.UserRelationshipQuery;
    type RelationshipQuery = FactoryRegistryTypes.RelationshipQuery;

    // ==================================================================================================
    // FACTORY REGISTRY INTERFACE - User-Centric Relationship Tracking
    // Public interface for interacting with factory registry system
    // Simplified from complex relationshipId system to user-centric approach
    // ==================================================================================================

    public type FactoryRegistryInterface = {
        
        // --- FACTORY MANAGEMENT ---
        
        // Register a factory for a specific action type
        registerFactory: (
            actionType: AuditTypes.ActionType,
            factoryPrincipal: Principal
        ) -> async FactoryRegistryResult<()>;
        
        // Get factory principal for an action type
        getFactory: (
            actionType: AuditTypes.ActionType
        ) -> async FactoryRegistryResult<Principal>;
        
        // Get all registered factories
        getAllFactories: () -> async [(AuditTypes.ActionType, Principal)];
        
        // --- USER RELATIONSHIP TRACKING ---
        
        // Add relationship for a single user
        addUserRelationship: (
            user: Principal,
            relationshipType: RelationshipType,
            canisterId: Principal,
            metadata: RelationshipMetadata
        ) -> async FactoryRegistryResult<()>;
        
        // Batch add users to canister relationship
        batchAddUserRelationships: (
            relationshipType: RelationshipType,
            canisterId: Principal,
            users: [Principal],
            metadata: RelationshipMetadata
        ) -> async FactoryRegistryResult<()>;
        
        // Get user relationships in backward-compatible format
        getUserRelationships: (
            queryObj: UserRelationshipQuery
        ) -> async FactoryRegistryResult<UserRelationshipMap>;
        
        // Get user relationships in new detailed format
        getUserCanisterRelationships: (
            queryObj: UserRelationshipQuery
        ) -> async FactoryRegistryResult<UserCanisterRelationships>;
        
        // --- EXTERNAL CONTRACT CALLBACKS ---
        
        // Public API for external contracts to register user relationships
        updateUserRelationships: (
            relationshipType: RelationshipType,
            canisterId: Principal,
            users: [Principal],
            metadata: RelationshipMetadata
        ) -> async FactoryRegistryResult<()>;
        
        // Remove user relationship
        removeUserRelationship: (
            user: Principal,
            relationshipType: RelationshipType,
            canisterId: Principal
        ) -> async FactoryRegistryResult<()>;
        
        // --- QUERY FUNCTIONS ---
        
        // Query relationships with filters
        queryRelationships: (
            queryObj: RelationshipQuery
        ) -> async FactoryRegistryResult<[CanisterRelationship]>;
        
        // Get relationships by type (simplified)
        getRelatedCanisters: (
            user: ?Principal
        ) -> async FactoryRegistryResult<UserRelationshipMap>;
        
        // Get relationships by type and user
        getRelatedCanistersByType: (
            relationshipType: RelationshipType,
            user: ?Principal
        ) -> async FactoryRegistryResult<[Principal]>;
        
        // --- UTILITY FUNCTIONS ---
        
        // Check if factory type is supported
        isFactoryTypeSupported: (
            actionType: AuditTypes.ActionType
        ) -> async Bool;
        
        // Get all supported factory types
        getSupportedFactoryTypes: () -> async [AuditTypes.ActionType];
        
        // --- ADMIN FUNCTIONS ---
        
        // Add new factory type to supported list
        addSupportedFactoryType: (
            actionType: AuditTypes.ActionType
        ) -> async FactoryRegistryResult<()>;
        
        // Add new admin principal
        addAdmin: (
            newAdmin: Principal
        ) -> async FactoryRegistryResult<()>;
        
        // Manually add relationship (for admin correction)
        adminAddUserRelationship: (
            user: Principal,
            relationshipType: RelationshipType,
            canisterId: Principal,
            metadata: RelationshipMetadata
        ) -> async FactoryRegistryResult<()>;
        
        // Manually remove relationship (for admin correction)  
        adminRemoveUserRelationship: (
            user: Principal,
            relationshipType: RelationshipType,
            canisterId: Principal
        ) -> async FactoryRegistryResult<()>;
    };
}