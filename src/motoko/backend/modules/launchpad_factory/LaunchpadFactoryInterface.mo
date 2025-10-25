import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import LaunchpadTypes "../../../shared/types/LaunchpadTypes";

module LaunchpadFactoryInterface {

    // ================ FACTORY INTERFACE TYPES ================

    // Arguments for creating a new launchpad
    public type CreateLaunchpadArgs = {
        config: LaunchpadTypes.LaunchpadConfig;
        creator: Principal;  // User who is creating the launchpad
        initialDeposit: ?Nat;
    };

    // Result of launchpad creation
    // IMPORTANT: Must match factory's exact return type
    public type CreateLaunchpadResult = {
        #Ok: {
            launchpadId: Text;
            canisterId: Principal;
            estimatedCosts: LaunchpadTypes.LaunchpadCosts;
        };
        #Err: Text;
    };

    // Arguments for launchpad operations
    public type LaunchpadOperationArgs = {
        launchpadId: Text;
        operation: LaunchpadOperation;
        reason: ?Text;
    };

    // Supported operations
    public type LaunchpadOperation = {
        #Pause;
        #Unpause;
        #Cancel;
        #UpdateConfig: LaunchpadTypes.LaunchpadConfig;
    };

    // Query arguments
    public type QueryLaunchpadArgs = {
        launchpadId: ?Text;
        creator: ?Principal;
        status: ?LaunchpadTypes.LaunchpadStatus;
        offset: Nat;
        limit: Nat;
    };

    // ================ FACTORY ACTOR INTERFACE ================

    // Interface that the LaunchpadFactory canister must implement
    public type LaunchpadFactoryActor = actor {
        
        // ================ DEPLOYMENT FUNCTIONS ================
        
        // Create a new launchpad contract
        createLaunchpad: shared (CreateLaunchpadArgs) -> async CreateLaunchpadResult;
        
        // ================ MANAGEMENT FUNCTIONS ================
        
        // Pause a launchpad
        pauseLaunchpad: shared (Text) -> async Result.Result<(), Text>;
        
        // Unpause a launchpad
        unpauseLaunchpad: shared (Text) -> async Result.Result<(), Text>;
        
        // Cancel a launchpad
        cancelLaunchpad: shared (Text) -> async Result.Result<(), Text>;
        
        // Upgrade a launchpad contract
        upgradeLaunchpad: shared (Text, Blob) -> async Result.Result<(), Text>;
        
        // ================ QUERY FUNCTIONS ================
        
        // Get launchpad details
        getLaunchpad: query (Text) -> async ?LaunchpadTypes.LaunchpadDetail;
        
        // Get all launchpads with optional filtering
        getAllLaunchpads: query (QueryLaunchpadArgs) -> async {
            launchpads: [LaunchpadTypes.LaunchpadDetail];
            totalCount: Nat;
        };
        
        // Get launchpads created by a specific user
        getUserLaunchpads: query (Principal) -> async [LaunchpadTypes.LaunchpadDetail];
        
        // Get factory statistics
        getFactoryStats: query () -> async FactoryStats;
        
        // ================ ADMIN FUNCTIONS ================
        
        // Add backend canister to whitelist
        addBackendCanister: shared (Principal) -> async Result.Result<(), Text>;
        
        // Remove backend canister from whitelist
        removeBackendCanister: shared (Principal) -> async Result.Result<(), Text>;
        
        // Update factory configuration
        updateFactoryConfig: shared (FactoryConfig) -> async Result.Result<(), Text>;
        
        // Emergency pause all launchpads
        emergencyPauseAll: shared () -> async Result.Result<Nat, Text>;
        
        // ================ UTILITY FUNCTIONS ================
        
        // Health check
        healthCheck: query () -> async Bool;
        
        // Get version info
        getVersion: query () -> async Text;
    };

    // ================ SUPPORTING TYPES ================

    // Factory statistics
    public type FactoryStats = {
        totalLaunchpads: Nat;
        activeLaunchpads: Nat;
        completedLaunchpads: Nat;
        failedLaunchpads: Nat;
        totalRaised: Nat;
        totalParticipants: Nat;
        averageRaise: Nat;
        successRate: Nat8; // Percentage
    };

    // Factory configuration
    public type FactoryConfig = {
        maxLaunchpadsPerUser: Nat;
        minDeploymentFee: Nat;
        maxDeploymentFee: Nat;
        platformFeeRate: Nat8;
        emergencyPauseEnabled: Bool;
        upgradesEnabled: Bool;
    };

    // ================ CALLBACK TYPES ================

    // Callback interface for Backend notifications
    public type BackendCallbackActor = actor {
        onLaunchpadCreated: shared ({
            launchpadId: Text;
            canisterId: Principal;
            creator: Principal;
            success: Bool;
        }) -> async ();
        
        onLaunchpadStatusChanged: shared ({
            launchpadId: Text;
            canisterId: Principal;
            oldStatus: LaunchpadTypes.LaunchpadStatus;
            newStatus: LaunchpadTypes.LaunchpadStatus;
        }) -> async ();
        
        onLaunchpadCompleted: shared ({
            launchpadId: Text;
            canisterId: Principal;
            totalRaised: Nat;
            participantCount: Nat;
            success: Bool;
        }) -> async ();
    };

    // ================ ERROR TYPES ================

    public type FactoryError = {
        #Unauthorized;
        #LaunchpadNotFound;
        #InvalidConfiguration;
        #DeploymentFailed: Text;
        #InsufficientCycles;
        #SystemError: Text;
    };

    // Convert error to text
    public func errorToText(error: FactoryError) : Text {
        switch (error) {
            case (#Unauthorized) "Unauthorized access";
            case (#LaunchpadNotFound) "Launchpad not found";
            case (#InvalidConfiguration) "Invalid configuration";
            case (#DeploymentFailed(msg)) "Deployment failed: " # msg;
            case (#InsufficientCycles) "Insufficient cycles for operation";
            case (#SystemError(msg)) "System error: " # msg;
        }
    };
}