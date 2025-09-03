import Time "mo:base/Time";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Array "mo:base/Array";

module {
    // 🛡️ AUDITOR-APPROVED SECURE MULTIPLIER TIER SYSTEM
    // This replaces the vulnerable soft-multiplier system with configurable tiers
    
    /// Security Constants - NEVER change these without security review
    public let SECURITY_LIMITS = {
        MAX_MULTIPLIER = 3.0;           // Anti-governance capture
        MIN_MULTIPLIER = 1.0;           // Base requirement
        MAX_LOCK_DAYS = 1095;           // 3 years max (prevent permanent locks)
        MIN_LOCK_DAYS = 7;              // 1 week min (flash loan protection)
        MAX_TIERS_PER_DAO = 10;         // Prevent complexity attacks
        MIN_TIERS_PER_DAO = 1;          // At least one tier required
        MAX_VP_PERCENT = 40;            // Anti-whale protection (basis points = 4000)
        SECONDS_PER_DAY = 86400;        // Time conversion constant
        OVERFLOW_PROTECTION_LIMIT = 1_000_000_000_000; // Max safe calculation limit
    };

    /// Custom Multiplier Tier (replaces soft-multiplier)
    public type MultiplierTier = {
        id: Nat;
        name: Text;
        minStake: Nat;                  // Minimum tokens required (in e8s)
        maxStakePerEntry: ?Nat;         // Maximum tokens per entry (None = unlimited)
        lockPeriod: Nat;                // Lock period in seconds
        multiplier: Float;              // Voting power multiplier (1.0 - 3.0)
        maxVpPercentage: Nat;           // Max VP% this tier can hold (1-40)
        
        // Security features
        emergencyUnlockEnabled: Bool;   // Allow emergency unlock
        flashLoanProtection: Bool;      // Enforce minimum lock period
        governanceCapProtection: Bool;  // Enforce max VP limits
    };

    /// Secure Stake Entry with overflow protection
    public type SecureStakeEntry = {
        id: Nat;
        staker: Principal;
        amount: Nat;                    // Protected against overflow
        tierId: Nat;                    // Reference to multiplier tier
        lockPeriod: Nat;                // Actual lock period (from tier)
        unlockTime: Time.Time;          // Calculated unlock time
        votingPower: Nat;               // Pre-calculated VP (overflow protected)
        stakedAt: Time.Time;
        isActive: Bool;                 // Can be set to false instead of deletion
        blockIndex: ?Nat;               // ICRC transfer block for audit
        
        // Security metadata
        securityChecksum: Nat;          // Integrity check
        lastValidated: Time.Time;       // Last security validation
    };

    /// DAO Configuration with Tier System
    public type SecureDAOConfig = {
        // Basic settings
        name: Text;
        description: Text;
        tokenCanisterId: Principal;
        
        // Governance
        governanceType: Text;           // "liquid", "locked", "hybrid"
        quorumPercentage: Nat;          // 1-100
        approvalThreshold: Nat;         // 1-100
        proposalThreshold: Nat;         // Min tokens to propose
        timelockDuration: Nat;          // Seconds before execution
        
        // Secure Tier System
        multiplierTiers: [MultiplierTier];    // Custom tiers
        defaultTierId: Nat;                   // Fallback tier
        tierUpgradeEnabled: Bool;             // Allow tier upgrades
        tierDowngradeEnabled: Bool;           // Allow tier downgrades
        
        // Security settings
        maxTotalSupply: Nat;                  // Overflow protection
        emergencyPauseEnabled: Bool;
        multiSigRequired: Bool;               // Require multi-sig for critical ops
        auditTrailEnabled: Bool;              // Enhanced logging
        
        // Treasury protection
        treasuryLockEnabled: Bool;
        treasuryMultiSigThreshold: Nat;       // Min sigs for treasury ops
        maxTreasuryWithdrawal: Nat;           // Max single withdrawal
    };

    /// Secure Voting Power Calculation Result
    public type VotingPowerResult = {
        votingPower: Nat;
        multiplierUsed: Float;
        tierId: Nat;
        calculationValid: Bool;
        securityWarnings: [Text];
    };

    /// Treasury Operation (enhanced security)
    public type TreasuryOperation = {
        id: Nat;
        operationType: TreasuryOperationType;
        amount: Nat;
        recipient: ?Principal;
        requester: Principal;
        approvers: [Principal];           // Multi-sig approvals
        requiredSignatures: Nat;
        status: TreasuryOperationStatus;
        createdAt: Time.Time;
        executedAt: ?Time.Time;
        blockIndex: ?Nat;                 // Audit trail
        
        // Security
        riskLevel: RiskLevel;
        securityChecks: [SecurityCheck];
        emergencyOverride: Bool;
    };

    public type TreasuryOperationType = {
        #Transfer: { to: Principal };
        #BulkTransfer: { recipients: [(Principal, Nat)] };
        #StakingReward: { amount: Nat };
        #ProposalRefund: { proposalId: Nat };
        #Emergency: { reason: Text };
    };

    public type TreasuryOperationStatus = {
        #Pending;
        #Approved: { signatures: Nat };
        #Executed: { blockIndex: Nat };
        #Rejected: { reason: Text };
        #Expired;
    };

    public type RiskLevel = {
        #Low;     // < 1% of treasury
        #Medium;  // 1-5% of treasury  
        #High;    // 5-25% of treasury
        #Critical; // > 25% of treasury
    };

    public type SecurityCheck = {
        checkType: Text;
        passed: Bool;
        message: Text;
        timestamp: Time.Time;
    };

    /// Enhanced Error Types with Security Context
    public type SecureDAOError = {
        #Unauthorized: { required: Text; provided: Text };
        #InsufficientStake: { required: Nat; available: Nat };
        #InvalidTier: { tierId: Nat; reason: Text };
        #SecurityViolation: { violation: Text; severity: Text };
        #OverflowDetected: { operation: Text; values: [Nat] };
        #TreasurySecurityBlock: { reason: Text; riskLevel: RiskLevel };
        #FlashLoanAttackDetected: { suspiciousActivity: Text };
        #GovernanceCaptureAttempt: { details: Text };
        #InvalidMultiSig: { required: Nat; provided: Nat };
        #AuditTrailBroken: { lastValidBlock: ?Nat };
        #EmergencyMode: { reason: Text };
        #RateLimitExceeded: { operation: Text; limit: Nat };
    };

    /// Security Event for Audit Trail
    public type SecurityEvent = {
        id: Nat;
        eventType: SecurityEventType;
        severity: SecuritySeverity;
        principal: Principal;
        details: Text;
        timestamp: Time.Time;
        blockIndex: ?Nat;
        resolved: Bool;
    };

    public type SecurityEventType = {
        #StakeOverflow;
        #VotingPowerAnomaly;  
        #TierManipulation;
        #FlashLoanAttempt;
        #GovernanceCapture;
        #TreasuryAnomaly;
        #UnauthorizedAccess;
        #SystemIntegrityCheck;
    };

    public type SecuritySeverity = {
        #Info;
        #Warning;
        #Critical;
        #Emergency;
    };

    // Security Validation Functions
    public func validateTier(tier: MultiplierTier) : {valid: Bool; errors: [Text]} {
        var errors: [Text] = [];
        
        // Multiplier bounds check
        if (tier.multiplier < SECURITY_LIMITS.MIN_MULTIPLIER) {
            errors := Array.append(errors, ["Multiplier below minimum: " # Float.toText(tier.multiplier)]);
        };
        if (tier.multiplier > SECURITY_LIMITS.MAX_MULTIPLIER) {
            errors := Array.append(errors, ["Multiplier exceeds maximum: " # Float.toText(tier.multiplier)]);
        };
        
        // Lock period validation
        let lockDays = tier.lockPeriod / SECURITY_LIMITS.SECONDS_PER_DAY;
        if (lockDays < SECURITY_LIMITS.MIN_LOCK_DAYS) {
            errors := Array.append(errors, ["Lock period too short: " # Nat.toText(lockDays) # " days"]);
        };
        if (lockDays > SECURITY_LIMITS.MAX_LOCK_DAYS) {
            errors := Array.append(errors, ["Lock period too long: " # Nat.toText(lockDays) # " days"]);
        };
        
        // VP percentage check
        if (tier.maxVpPercentage > SECURITY_LIMITS.MAX_VP_PERCENT) {
            errors := Array.append(errors, ["VP percentage exceeds limit: " # Nat.toText(tier.maxVpPercentage) # "%"]);
        };
        
        // Min stake validation
        if (tier.minStake == 0) {
            errors := Array.append(errors, ["Minimum stake cannot be zero"]);
        };
        
        // Max stake consistency check
        switch (tier.maxStakePerEntry) {
            case (?maxStake) {
                if (maxStake <= tier.minStake) {
                    errors := Array.append(errors, ["Max stake must be greater than min stake"]);
                };
            };
            case null { /* No limit is valid */ };
        };
        
        {
            valid = errors.size() == 0;
            errors = errors;
        }
    };

    // Calculate secure voting power with overflow protection
    public func calculateSecureVotingPower(
        amount: Nat,
        tier: MultiplierTier
    ) : VotingPowerResult {
        var warnings: [Text] = [];
        
        // Overflow protection
        if (amount > SECURITY_LIMITS.OVERFLOW_PROTECTION_LIMIT) {
            return {
                votingPower = 0;
                multiplierUsed = 1.0;
                tierId = tier.id;
                calculationValid = false;
                securityWarnings = ["Amount exceeds overflow protection limit"];
            };
        };
        
        // Multiplier bounds check
        let safeMult = if (tier.multiplier > SECURITY_LIMITS.MAX_MULTIPLIER) {
            warnings := Array.append(warnings, ["Multiplier capped to security limit"]);
            SECURITY_LIMITS.MAX_MULTIPLIER;
        } else if (tier.multiplier < SECURITY_LIMITS.MIN_MULTIPLIER) {
            warnings := Array.append(warnings, ["Multiplier raised to minimum"]);
            SECURITY_LIMITS.MIN_MULTIPLIER;
        } else {
            tier.multiplier;
        };
        
        // Safe multiplication with overflow check
        let baseVP = Float.toInt(Float.fromInt(amount) * safeMult);
        let safeVP = if (baseVP < 0 or baseVP > SECURITY_LIMITS.OVERFLOW_PROTECTION_LIMIT) {
            warnings := Array.append(warnings, ["Voting power overflow detected, using safe limit"]);
            Int.abs(SECURITY_LIMITS.OVERFLOW_PROTECTION_LIMIT);
        } else {
            Int.abs(baseVP);
        };
        
        {
            votingPower = safeVP;
            multiplierUsed = safeMult;
            tierId = tier.id;
            calculationValid = warnings.size() == 0;
            securityWarnings = warnings;
        }
    };

    // Generate security checksum for stake entry
    public func generateSecurityChecksum(entry: SecureStakeEntry) : Nat {
        // Simple but effective checksum using entry data
        let combined = entry.amount + entry.tierId * 1000 + Int.abs(entry.unlockTime) / 1000000000;
        combined % 999999991 // Large prime for better distribution
    };
}