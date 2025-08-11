import Principal "mo:base/Principal";

import FactoryRegistryTypes "FactoryRegistryTypes";

module FactoryRegistryInterface {

    // Import types for convenience
    type DeploymentType = FactoryRegistryTypes.DeploymentType;
    type UserDeploymentMap = FactoryRegistryTypes.UserDeploymentMap;
    type DeploymentInfo = FactoryRegistryTypes.DeploymentInfo;
    type DeploymentMetadata = FactoryRegistryTypes.DeploymentMetadata;
    type FactoryRegistryResult<T> = FactoryRegistryTypes.FactoryRegistryResult<T>;
    type UserDeploymentQuery = FactoryRegistryTypes.UserDeploymentQuery;
    type DeploymentQuery = FactoryRegistryTypes.DeploymentQuery;

    // ==================================================================================================
    // FACTORY REGISTRY INTERFACE
    // Public interface for interacting with factory registry system
    // ==================================================================================================

    public type FactoryRegistryInterface = {
        
        // --- FACTORY MANAGEMENT ---
        
        // Register a factory for a specific deployment type
        registerFactory: (
            deploymentType: DeploymentType,
            factoryPrincipal: Principal
        ) -> async FactoryRegistryResult<()>;
        
        // Get factory principal for a deployment type
        getFactory: (
            deploymentType: DeploymentType
        ) -> async FactoryRegistryResult<Principal>;
        
        // Get all registered factories
        getAllFactories: () -> async [(DeploymentType, Principal)];
        
        // --- USER DEPLOYMENT INDEX ---
        
        // Add deployment to user's index
        addUserDeployment: (
            user: Principal,
            deploymentType: DeploymentType,
            deploymentId: Principal
        ) -> async FactoryRegistryResult<()>;
        
        // Get all deployments for a user
        getUserDeployments: (
            queryObj: UserDeploymentQuery
        ) -> async FactoryRegistryResult<UserDeploymentMap>;
        
        // Batch add recipients to deployment index
        batchAddRecipients: (
            deploymentType: DeploymentType,
            deploymentId: Principal,
            recipients: [Principal]
        ) -> async FactoryRegistryResult<()>;
        
        // --- DEPLOYMENT METADATA ---
        
        // Main integration function - called after deployment
        postDeploymentCallback: (
            creator: Principal,
            deploymentType: DeploymentType,
            deploymentId: Principal,
            recipients: ?[Principal],
            metadata: DeploymentMetadata
        ) -> async FactoryRegistryResult<Text>;
        
        // --- QUERY FUNCTIONS ---
        
        // Query deployments with filters
        queryDeployments: (
            queryObj: DeploymentQuery
        ) -> async FactoryRegistryResult<[DeploymentInfo]>;
        
        // Get deployment info by ID
        getDeploymentInfo: (
            deploymentId: Text
        ) -> async FactoryRegistryResult<DeploymentInfo>;
        
        // --- UTILITY FUNCTIONS ---
        
        // Check if deployment type is supported
        isDeploymentTypeSupported: (
            deploymentType: DeploymentType
        ) -> async Bool;
        
        // Get all supported deployment types
        getSupportedTypes: () -> async [DeploymentType];
        
        // --- ADMIN FUNCTIONS ---
        
        // Add new deployment type to supported list
        addSupportedDeploymentType: (
            deploymentType: DeploymentType
        ) -> async FactoryRegistryResult<()>;
        
        // Add new admin principal
        addAdmin: (
            newAdmin: Principal
        ) -> async FactoryRegistryResult<()>;
    };
}