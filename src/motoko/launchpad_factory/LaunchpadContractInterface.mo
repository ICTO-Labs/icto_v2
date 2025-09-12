import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";

import LaunchpadTypes "../shared/types/LaunchpadTypes";

module LaunchpadContractInterface {

    // ================ FRONTEND API INTERFACES ================

    // Complete launchpad contract interface for frontend integration
    public type LaunchpadContractActor = actor {
        
        // ================ CORE PARTICIPATION ================
        
        // Join the launchpad sale
        participate: shared (amount: Nat, affiliateCode: ?Text) -> async Result.Result<LaunchpadTypes.Transaction, Text>;
        
        // Claim allocated tokens after sale completion
        claimTokens: shared () -> async Result.Result<Nat, Text>;
        
        // ================ QUERY FUNCTIONS (READ-ONLY) ================
        
        // Get complete launchpad information
        getLaunchpadDetail: query () -> async LaunchpadTypes.LaunchpadDetail;
        
        // Get current launchpad status
        getStatus: query () -> async LaunchpadTypes.LaunchpadStatus;
        
        // Get launchpad configuration
        getConfig: query () -> async LaunchpadTypes.LaunchpadConfig;
        
        // Get aggregated statistics
        getStats: query () -> async LaunchpadTypes.LaunchpadStats;
        
        // Get specific participant info
        getParticipant: query (participant: Principal) -> async ?LaunchpadTypes.Participant;
        
        // Get paginated participants list
        getParticipants: query (offset: Nat, limit: Nat) -> async [LaunchpadTypes.Participant];
        
        // Get transaction history
        getTransactions: query (offset: Nat, limit: Nat) -> async [LaunchpadTypes.Transaction];
        
        // Check if user is whitelisted
        isWhitelisted: query (user: Principal) -> async Bool;
        
        // Get affiliate statistics
        getAffiliateStats: query (affiliate: Principal) -> async ?LaunchpadTypes.AffiliateStats;
        
        // ================ ADMIN FUNCTIONS ================
        
        // Initialize launchpad (factory only)
        initialize: shared () -> async Result.Result<(), Text>;
        
        // Pause launchpad operations
        pauseLaunchpad: shared () -> async Result.Result<(), Text>;
        
        // Resume launchpad operations  
        unpauseLaunchpad: shared () -> async Result.Result<(), Text>;
        
        // Cancel launchpad permanently
        cancelLaunchpad: shared () -> async Result.Result<(), Text>;
        
        // Emergency pause with reason
        emergencyPause: shared (reason: Text) -> async Result.Result<(), Text>;
        
        // Remove emergency pause
        emergencyUnpause: shared () -> async Result.Result<(), Text>;
        
        // ================ AUDIT & SECURITY ================
        
        // Get security events log (admin only)
        getSecurityEvents: query () -> async Result.Result<[LaunchpadTypes.SecurityEvent], Text>;
        
        // Get admin actions log (admin only)
        getAdminActions: query () -> async Result.Result<[LaunchpadTypes.AdminAction], Text>;
    };

    // ================ FRONTEND RESPONSE TYPES ================

    // Comprehensive response for frontend dashboard
    public type LaunchpadDashboardData = {
        // Basic info
        launchpadId: Text;
        projectName: Text;
        status: LaunchpadTypes.LaunchpadStatus;
        
        // Token information
        saleToken: LaunchpadTypes.TokenInfo;
        purchaseToken: LaunchpadTypes.TokenInfo;
        
        // Sale progress
        totalRaised: Nat;
        totalAllocated: Nat;
        softCap: Nat;
        hardCap: Nat;
        softCapProgress: Nat8; // Percentage
        hardCapProgress: Nat8; // Percentage
        
        // Timeline
        saleStart: Time.Time;
        saleEnd: Time.Time;
        claimStart: Time.Time;
        whitelistStart: ?Time.Time;
        whitelistEnd: ?Time.Time;
        
        // Participation
        participantCount: Nat;
        minContribution: Nat;
        maxContribution: ?Nat;
        
        // User-specific data (if authenticated)
        userParticipation: ?{
            totalContribution: Nat;
            allocationAmount: Nat;
            claimedAmount: Nat;
            canParticipate: Bool;
            isWhitelisted: Bool;
        };
        
        // Real-time countdown
        timeRemaining: ?Time.Time;
        nextPhaseTime: ?Time.Time;
        
        // Security status
        isPaused: Bool;
        pauseReason: ?Text;
    };

    // User participation response
    public type ParticipationResponse = {
        success: Bool;
        transactionId: ?Text;
        newTotalContribution: Nat;
        allocationAmount: Nat;
        message: Text;
        timestamp: Time.Time;
    };

    // Claiming response
    public type ClaimResponse = {
        success: Bool;
        claimedAmount: Nat;
        remainingAmount: Nat;
        nextClaimableTime: ?Time.Time;
        message: Text;
        timestamp: Time.Time;
    };

    // ================ FRONTEND UTILITY FUNCTIONS ================

    // Calculate user's maximum possible contribution
    public func calculateMaxContribution(
        config: LaunchpadTypes.LaunchpadConfig,
        currentContribution: Nat,
        hardCap: Nat,
        totalRaised: Nat
    ) : Nat {
        let remainingHardCap = if (hardCap > totalRaised) { hardCap - totalRaised } else { 0 };
        
        switch (config.saleParams.maxContribution) {
            case (?maxContrib) {
                let userRemainingLimit = if (maxContrib > currentContribution) {
                    maxContrib - currentContribution
                } else { 0 };
                
                if (userRemainingLimit < remainingHardCap) {
                    userRemainingLimit
                } else {
                    remainingHardCap
                }
            };
            case null remainingHardCap;
        }
    };

    // Calculate token allocation based on contribution
    public func calculateTokenAllocation(
        contribution: Nat,
        tokenPrice: Nat,
        decimals: Nat8
    ) : Nat {
        let priceMultiplier = 10 ** Nat8.toNat(decimals);
        (contribution * priceMultiplier) / tokenPrice
    };

    // Get phase display name
    public func getPhaseDisplayName(status: LaunchpadTypes.LaunchpadStatus) : Text {
        switch (status) {
            case (#Setup) "Preparing";
            case (#Upcoming) "Coming Soon";
            case (#WhitelistOpen) "Whitelist Phase";
            case (#SaleActive) "Public Sale";
            case (#SaleEnded) "Sale Completed";
            case (#Claiming) "Claim Available";
            case (#Completed) "Completed";
            case (#Cancelled) "Cancelled";
            case (#Distributing) "Token Distribution";
            case (#Emergency) "Emergency Mode";
            case (#Failed) "Launch Failed";
            case (#Successful) "Launch Successful";
        }
    };

    // Calculate progress percentage
    public func calculateProgress(raised: Nat, target: Nat) : Nat8 {
        if (target == 0) return 0;
        let progress = (raised * 100) / target;
        if (progress > 100) { 100 } else { Nat8.fromNat(progress % 256) }
    };
}