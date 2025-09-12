import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";

import LaunchpadTypes "../../../shared/types/LaunchpadTypes";

module LaunchpadFactoryTypes {

    // ================ BACKEND-SPECIFIC LAUNCHPAD TYPES ================

    // Backend configuration for launchpad creation (simplified from full LaunchpadTypes)
    public type LaunchpadConfig = {
        // Project Information
        projectInfo: LaunchpadTypes.ProjectInfo;
        
        // Token Configuration
        saleToken: LaunchpadTypes.TokenInfo;
        purchaseToken: LaunchpadTypes.TokenInfo;
        
        // Sale Configuration  
        saleParams: LaunchpadTypes.SaleParams;
        
        // Timeline
        timeline: LaunchpadTypes.Timeline;
        
        // Token Distribution
        distribution: [LaunchpadTypes.DistributionCategory];
        
        // Advanced Features
        affiliateConfig: LaunchpadTypes.AffiliateConfig;
        governanceConfig: LaunchpadTypes.GovernanceConfig;
        
        // Security & Compliance
        whitelist: [Principal];
        blacklist: [Principal];
        
        // Emergency Controls
        emergencyContacts: [Principal];
    };

    // Request structure for creating launchpads via Backend
    public type CreateLaunchpadRequest = {
        config: LaunchpadConfig;
        projectId: ?Text; // Optional project ID for tracking
        initialDeposit: ?Nat; // Optional initial cycles deposit
    };

    // Response structure after successful launchpad creation
    public type CreateLaunchpadResponse = {
        launchpadId: Text;
        canisterId: Principal;
        estimatedCosts: LaunchpadFees;
        createdAt: Time.Time;
    };

    // Fee structure for launchpad operations
    public type LaunchpadFees = {
        deploymentFee: Nat;    // One-time deployment fee in e8s
        cycleCost: Nat;        // Estimated cycle cost
        platformFee: Nat;      // Platform fee based on hard cap
        totalCost: Nat;        // Total upfront cost
    };

    // Summary for audit logging
    public type LaunchpadDeploymentSummary = {
        projectName: Text;
        saleTokenSymbol: Text;
        purchaseTokenSymbol: Text;
        saleType: Text;
        totalSaleAmount: Nat;
        softCap: Nat;
        hardCap: Nat;
        requiresWhitelist: Bool;
        affiliateEnabled: Bool;
        totalParticipants: Nat;
        createdAt: Time.Time;
    };

    // Launchpad management operations
    public type LaunchpadOperation = {
        #Pause;
        #Unpause;
        #Cancel: Text; // Reason for cancellation
        #UpdateTimeline: LaunchpadTypes.Timeline;
        #UpdateWhitelist: [Principal];
        #EmergencyWithdraw: Principal; // Emergency withdrawal to specified principal
    };

    // Operation result
    public type OperationResult = {
        success: Bool;
        message: Text;
        timestamp: Time.Time;
        operationType: Text;
    };

    // Launchpad status for Backend queries
    public type LaunchpadStatusSummary = {
        id: Text;
        canisterId: Principal;
        status: LaunchpadTypes.LaunchpadStatus;
        totalRaised: Nat;
        participantCount: Nat;
        softCapProgress: Nat8;
        hardCapProgress: Nat8;
        timeRemaining: ?Time.Time;
        lastUpdated: Time.Time;
    };

    // Filter for querying launchpads
    public type LaunchpadQueryFilter = {
        status: ?LaunchpadTypes.LaunchpadStatus;
        creator: ?Principal;
        saleType: ?LaunchpadTypes.SaleType;
        minRaised: ?Nat;
        maxRaised: ?Nat;
        dateFrom: ?Time.Time;
        dateTo: ?Time.Time;
    };

    // Pagination parameters
    public type PaginationParams = {
        offset: Nat;
        limit: Nat; // Max 100
    };

    // Paginated response
    public type PaginatedLaunchpadResponse = {
        launchpads: [LaunchpadStatusSummary];
        totalCount: Nat;
        hasMore: Bool;
        nextOffset: ?Nat;
    };

    // ================ ERROR TYPES ================

    public type LaunchpadFactoryError = {
        #ValidationError: Text;
        #DeploymentError: Text;
        #InsufficientFunds: Text;
        #UnauthorizedAccess: Text;
        #LaunchpadNotFound: Text;
        #InvalidOperation: Text;
        #SystemError: Text;
    };

    // ================ UTILITY TYPES ================

    public type Result<T, E> = Result.Result<T, E>;

    // Convert LaunchpadFactoryError to Text for error handling
    public func errorToText(error: LaunchpadFactoryError) : Text {
        switch (error) {
            case (#ValidationError(msg)) "Validation Error: " # msg;
            case (#DeploymentError(msg)) "Deployment Error: " # msg;
            case (#InsufficientFunds(msg)) "Insufficient Funds: " # msg;
            case (#UnauthorizedAccess(msg)) "Unauthorized Access: " # msg;
            case (#LaunchpadNotFound(msg)) "Launchpad Not Found: " # msg;
            case (#InvalidOperation(msg)) "Invalid Operation: " # msg;
            case (#SystemError(msg)) "System Error: " # msg;
        }
    };

    // ================ CONSTANTS ================

    public let MIN_DEPLOYMENT_FEE : Nat = 1_000_000_000; // 0.01 ICP
    public let MAX_DEPLOYMENT_FEE : Nat = 1_000_000_000_000; // 10 ICP
    public let DEFAULT_CYCLE_COST : Nat = 100_000_000; // 1T cycles
    public let PLATFORM_FEE_RATE : Nat8 = 2; // 2%
    public let MAX_LAUNCHPADS_PER_USER : Nat = 10;
    public let MAX_QUERY_LIMIT : Nat = 100;
}