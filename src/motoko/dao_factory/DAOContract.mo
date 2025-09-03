import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Error "mo:base/Error";
import ICRaw "mo:base/ExperimentalInternetComputer";
import List "mo:base/List";
import Time "mo:base/Time";
import Timer "mo:base/Timer";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Cycles "mo:base/ExperimentalCycles";
import Types "./Types";
import DAOTypes "../shared/types/DAOTypes";
import ICRC "../shared/types/ICRC";
import SafeMath "../shared/utils/SafeMath";
import DAOUtils "../shared/utils/DAO";
// ICTO V2 - Mini DAO Contract
// FIXED: Proper ICRC2 approve/transferFrom pattern + comprehensive transaction logging
persistent actor class DAO(init : Types.BasicDaoStableStorage) = Self {

    // ================ TYPE DEFINITIONS ================
    
    type ActionType = {
        #SubmitProposal;
        #Vote;
        #Stake;
        #Unstake;
        #Delegate;
        #Execute;
    };

    public type TransactionType = {
        #Stake;
        #Unstake;
        #ProposalDeposit;
        #ProposalRefund;
        #Transfer;
    };

    public type Transaction = {
        id: Nat;
        transactionType: TransactionType;
        from: Principal;
        to: ?Principal;
        amount: Nat;
        blockIndex: ?Nat; // ICRC transfer block index for audit trail
        timestamp: Time.Time;
        description: Text;
        status: { #Pending; #Completed; #Failed: Text };
    };

    // ================ STABLE VARIABLES ================
    
    // Core storage - UPGRADE SAFE: Use empty defaults, init only on first creation
    var accounts_stable : [(Principal, Types.Account)] = [];
    var proposals_stable : [(Nat, Types.Proposal)] = [];
    var stakes_stable : [(Principal, Types.StakeRecord)] = []; // LEGACY: Keep for migration
    var delegations_stable : [(Principal, Types.DelegationRecord)] = [];
    var next_proposal_id : Nat = 1;
    
    // Reconstruct Tries from stable data (upgrade-safe) - Start with empty, will be populated in postupgrade
    var accounts = Trie.empty<Principal, Types.Account>();
    var proposals = Trie.empty<Nat, Types.Proposal>();
    var stakes = Trie.empty<Principal, Types.StakeRecord>();
    var delegations = Trie.empty<Principal, Types.DelegationRecord>();
    
    // Initialize default secure tiers
    private func _initializeDefaultTiers() {
        // Create 3 secure default tiers
        let shortTermTier : CustomMultiplierTier = {
            id = 0;
            name = "Short Term (1 Week)";
            minStake = 100 * Types.E8S;      // 100 tokens min
            maxStakePerEntry = ?(10000 * Types.E8S); // 10K max per entry
            lockPeriod = 7 * SECONDS_PER_DAY;      // 7 days
            multiplier = 1.1;                      // 1.1x multiplier
            maxVpPercentage = 15;                  // Max 15% VP
            isActive = true;
            emergencyUnlockEnabled = true;
            flashLoanProtection = true;
            createdAt = Time.now();
            lastModified = Time.now();
        };
        
        let mediumTermTier : CustomMultiplierTier = {
            id = 1;
            name = "Medium Term (3 Months)";
            minStake = 500 * Types.E8S;
            maxStakePerEntry = ?(25000 * Types.E8S);
            lockPeriod = 90 * SECONDS_PER_DAY;     // 90 days
            multiplier = 1.5;
            maxVpPercentage = 25;
            isActive = true;
            emergencyUnlockEnabled = true;
            flashLoanProtection = true;
            createdAt = Time.now();
            lastModified = Time.now();
        };
        
        let longTermTier : CustomMultiplierTier = {
            id = 2;
            name = "Long Term (1 Year)";
            minStake = 1000 * Types.E8S;
            maxStakePerEntry = ?(50000 * Types.E8S);
            lockPeriod = 365 * SECONDS_PER_DAY;    // 365 days
            multiplier = 2.0;
            maxVpPercentage = 30;
            isActive = true;
            emergencyUnlockEnabled = false;         // No emergency unlock for long term
            flashLoanProtection = true;
            createdAt = Time.now();
            lastModified = Time.now();
        };
        
        // Insert default tiers
        multiplierTiers := Trie.put(multiplierTiers, DAOUtils._natKey(0), Nat.equal, shortTermTier).0;
        multiplierTiers := Trie.put(multiplierTiers, DAOUtils._natKey(1), Nat.equal, mediumTermTier).0;
        multiplierTiers := Trie.put(multiplierTiers, DAOUtils._natKey(2), Nat.equal, longTermTier).0;
        
        nextTierId := 3;
        defaultTierId := 0; // Short term as default
    };
    
    private func _initializeCustomTiers(customTiers: [DAOTypes.MultiplierTier]) {
        // Clear any existing tiers
        multiplierTiers := Trie.empty();
        var currentId = 0;
        
        // Convert and insert custom tiers from frontend
        for (tier in customTiers.vals()) {
            let customTier : CustomMultiplierTier = {
                id = currentId;
                name = tier.name;
                minStake = tier.minStake;
                maxStakePerEntry = tier.maxStakePerEntry;
                lockPeriod = tier.lockPeriod;
                multiplier = tier.multiplier;
                maxVpPercentage = tier.maxVpPercentage;
                isActive = true;
                emergencyUnlockEnabled = tier.emergencyUnlockEnabled;
                flashLoanProtection = tier.flashLoanProtection;
                createdAt = Time.now();
                lastModified = Time.now();
            };
            
            multiplierTiers := Trie.put(multiplierTiers, DAOUtils._natKey(currentId), Nat.equal, customTier).0;
            currentId += 1;
        };
        
        nextTierId := currentId;
        // Set default tier ID to first tier (index 0) if available
        defaultTierId := if (currentId > 0) { 0 } else { 0 };
    };
    
    // Initialize data from factory on first creation
    private func _initializeFromFactory() {
        // Always use default values - no init data usage during upgrade
        accounts_stable := [];
        accounts := Trie.empty<Principal, Types.Account>();
        
        // Initialize proposals from empty state  
        proposals_stable := [];
        proposals := Trie.empty<Nat, Types.Proposal>();
        
        // Initialize stakes from empty state
        stakes_stable := [];
        stakes := Trie.empty<Principal, Types.StakeRecord>();
        
        // Initialize delegations from empty state
        delegations_stable := [];
        delegations := Trie.empty<Principal, Types.DelegationRecord>();
        
        // Initialize comments from empty state
        comments_stable := [];
        comments := Trie.empty<Text, Types.ProposalComment>();
        
        // Initialize custom tiers from config or use defaults
        switch (init.customMultiplierTiers) {
            case (?customTiers) {
                _initializeCustomTiers(customTiers);
            };
            case null {
                // No custom tiers provided, use secure defaults
                _initializeDefaultTiers();
            };
        };
    };
    
    // NEW: Enhanced stake system
    var stakeEntries = Trie.empty<Principal, [Types.StakeEntry]>(); // User -> StakeEntry[]
    var userTimelines = Trie.empty<Principal, [Types.TimelineEntry]>(); // User -> Timeline[]
    var nextStakeEntryId : Nat = 1;
    
    // 🛡️ MULTIPLIER TIER MANAGEMENT FUNCTIONS
    
    /// Validate a custom multiplier tier (security checks)
    private func _validateTier(tier: CustomMultiplierTier) : Types.Result<(), Text> {
        // Multiplier bounds check
        if (tier.multiplier < MIN_MULTIPLIER) {
            return #err("Multiplier below minimum: " # Float.toText(tier.multiplier));
        };
        if (tier.multiplier > MAX_MULTIPLIER) {
            return #err("Multiplier exceeds maximum: " # Float.toText(tier.multiplier));
        };
        
        // Lock period validation  
        let lockDays = tier.lockPeriod / SECONDS_PER_DAY;
        if (lockDays < MIN_LOCK_DAYS) {
            return #err("Lock period too short: " # Nat.toText(lockDays) # " days (min: " # Nat.toText(MIN_LOCK_DAYS) # ")");
        };
        if (lockDays > MAX_LOCK_DAYS) {
            return #err("Lock period too long: " # Nat.toText(lockDays) # " days (max: " # Nat.toText(MAX_LOCK_DAYS) # ")");
        };
        
        // VP percentage check
        if (tier.maxVpPercentage > MAX_VP_PERCENT_PER_TIER) {
            return #err("VP percentage exceeds limit: " # Nat.toText(tier.maxVpPercentage) # "% (max: " # Nat.toText(MAX_VP_PERCENT_PER_TIER) # "%)");
        };
        
        // Min stake validation
        if (tier.minStake == 0) {
            return #err("Minimum stake cannot be zero");
        };
        
        // Max stake consistency check
        switch (tier.maxStakePerEntry) {
            case (?maxStake) {
                if (maxStake <= tier.minStake) {
                    return #err("Max stake must be greater than min stake");
                };
            };
            case null { /* No limit is valid */ };
        };
        
        #ok()
    };
    
    /// Find appropriate tier for given stake amount and desired lock period
    private func _findApplicableTier(amount: Nat, desiredLockPeriod: Nat) : ?CustomMultiplierTier {
        // Get all active tiers that match the criteria
        var bestTier : ?CustomMultiplierTier = null;
        
        for ((id, tier) in Trie.iter(multiplierTiers)) {
            if (tier.isActive and 
                amount >= tier.minStake and
                desiredLockPeriod >= tier.lockPeriod) {
                
                // Check max stake per entry limit
                let meetsMaxLimit = switch (tier.maxStakePerEntry) {
                    case (?maxStake) { amount <= maxStake };
                    case null { true };
                };
                
                if (meetsMaxLimit) {
                    // Choose tier with highest multiplier that user qualifies for
                    switch (bestTier) {
                        case null { bestTier := ?tier; };
                        case (?currentBest) {
                            if (tier.multiplier > currentBest.multiplier) {
                                bestTier := ?tier;
                            };
                        };
                    };
                };
            };
        };
        
        bestTier
    };
    
    /// Calculate secure voting power with tier-based multiplier
    private func _calculateTierVotingPower(amount: Nat, tier: CustomMultiplierTier) : Types.Result<Nat, Text> {
        // Overflow protection
        if (amount > 1_000_000_000_000) { // 1T limit
            return #err("Amount exceeds overflow protection limit");
        };
        
        // Safe multiplication with overflow check
        let baseVP = Float.toInt(Float.fromInt(amount) * tier.multiplier);
        if (baseVP < 0) {
            return #err("Voting power calculation overflow");
        };
        
        #ok(Int.abs(baseVP))
    };
    
    /// Get tier by ID with validation
    private func _getTier(tierId: Nat) : ?CustomMultiplierTier {
        Trie.get(multiplierTiers, DAOUtils._natKey(tierId), Nat.equal)
    };
    
    /// Find tier by lock period (closest match)
    private func _findTierByLockPeriod(lockPeriod: Nat) : ?CustomMultiplierTier {
        // Convert lockPeriod from seconds to days for comparison
        let lockDays = lockPeriod / (24 * 60 * 60);
        var bestTier: ?CustomMultiplierTier = null;
        var bestMatch: Nat = 999999;
        
        // Iterate through all tiers to find best match
        for ((tierId, tier) in Trie.iter(multiplierTiers)) {
            if (tier.isActive) {
                let tierLockDays = tier.lockPeriod / (24 * 60 * 60);
                
                // Find exact match first
                if (tierLockDays == lockDays) {
                    return ?tier;
                };
                
                // If no exact match, find closest tier with lock period <= requested
                if (tierLockDays <= lockDays) {
                    let diff = lockDays - tierLockDays;
                    if (diff < bestMatch) {
                        bestMatch := diff;
                        bestTier := ?tier;
                    };
                };
            };
        };
        
        bestTier
    };
    
    /// Create new custom tier (admin only)
    // public shared({caller}) func createCustomTier(
    //     name: Text,
    //     minStake: Nat,
    //     maxStakePerEntry: ?Nat,
    //     lockPeriod: Nat,
    //     multiplier: Float,
    //     maxVpPercentage: Nat
    // ) : async Types.Result<Nat, Text> {
    //     // Check authorization (only DAO members with sufficient voting power)
    //     let memberInfo = switch (Trie.get(accounts, DAOUtils._principalKey(caller), Principal.equal)) {
    //         case null { return #err("Not a DAO member"); };
    //         case (?account) { account };
    //     };
        
    //     if (memberInfo.votingPower < 10000 * Types.E8S) { // Require 10K VP to create tiers
    //         return #err("Insufficient voting power to create custom tiers");
    //     };
        
    //     // Check tier limit
    //     let currentTierCount = Trie.size(multiplierTiers);
    //     if (currentTierCount >= MAX_TIERS_PER_DAO) {
    //         return #err("Maximum tier limit reached: " # Nat.toText(MAX_TIERS_PER_DAO));
    //     };
        
    //     // Create new tier
    //     let newTier : CustomMultiplierTier = {
    //         id = nextTierId;
    //         name = name;
    //         minStake = minStake;
    //         maxStakePerEntry = maxStakePerEntry;
    //         lockPeriod = lockPeriod;
    //         multiplier = multiplier;
    //         maxVpPercentage = maxVpPercentage;
    //         isActive = true;
    //         emergencyUnlockEnabled = lockPeriod <= 30 * SECONDS_PER_DAY; // Only short-term tiers allow emergency unlock
    //         flashLoanProtection = true;
    //         createdAt = Time.now();
    //         lastModified = Time.now();
    //     };
        
    //     // Validate tier
    //     switch (_validateTier(newTier)) {
    //         case (#err(msg)) { return #err(msg); };
    //         case (#ok()) {};
    //     };
        
    //     // Insert tier
    //     multiplierTiers := Trie.put(multiplierTiers, DAOUtils._natKey(nextTierId), Nat.equal, newTier).0;
    //     let tierId = nextTierId;
    //     nextTierId += 1;
        
    //     // Log security event
    //     await _logSecurityEvent(caller, "Custom tier created: " # name # " (ID: " # Nat.toText(tierId) # ")", #Medium);
        
    //     #ok(tierId)
    // };
    var nextTimelineEntryId : Nat = 1;
    
    // Configuration - UPGRADE SAFE: Set to init values, will be restored in postupgrade
    var system_params : Types.SystemParams = init.system_params;
    var token_config : Types.TokenConfig = init.tokenConfig;
    var governance_level : Types.GovernanceLevel = init.governanceLevel;
    var security_config : Types.CustomSecurityParams = switch (init.customSecurity) {
        case (?custom) { custom };
        case null {
            {
                minStakeAmount = ?100_000_000;
                maxStakeAmount = ?(100_000_000 * 100_000_000);
                minProposalDeposit = ?(1 * 100_000_000);
                maxProposalDeposit = ?(10_000 * 100_000_000);
                maxProposalsPerHour = ?3;
                maxProposalsPerDay = ?1000;
            };
        };
    };
    
    // Stable copies for upgrade safety
    var system_params_stable : ?Types.SystemParams = null;
    var token_config_stable : ?Types.TokenConfig = null;
    var governance_level_stable : ?Types.GovernanceLevel = null;
    var security_config_stable : ?Types.CustomSecurityParams = null;
    
    // ================ SECURITY CONSTANTS ================
    // Time-based security (fixed constants)
    let DELEGATION_TIMELOCK : Int = 24 * 60 * 60 * 1_000_000_000; // 24 hours in nanoseconds
    let MIN_VOTING_PERIOD : Int = 24 * 60 * 60 * 1_000_000_000; // 24 hours
    let MAX_VOTING_PERIOD : Int = 30 * 24 * 60 * 60 * 1_000_000_000; // 30 days
    let MIN_TIMELOCK_DURATION : Int = 2 * 24 * 60 * 60 * 1_000_000_000; // 2 days
    let MAX_TIMELOCK_DURATION : Int = 7 * 24 * 60 * 60 * 1_000_000_000; // 7 days
    
    // Rate limiting (customizable by DAO creator)
    let MAX_PROPOSALS_PER_HOUR : Nat = switch (init.customSecurity) {
        case (?custom) {
            switch (custom.maxProposalsPerHour) {
                case (?value) { value };
                case null { 3 }; // Default value
            };
        };
        case null { 3 }; // Default value
    };
    let MAX_PROPOSALS_PER_DAY : Nat = switch (init.customSecurity) {
        case (?custom) {
            switch (custom.maxProposalsPerDay) {
                case (?value) { value };
                case null { 10 }; // Default value
            };
        };
        case null { 10 }; // Default value
    };
    let MAX_VOTES_PER_HOUR : Nat = 50; // Fixed constant
    let PROPOSAL_RATE_LIMIT_WINDOW : Int = 60 * 60 * 1_000_000_000; // 1 hour
    let DAILY_RATE_LIMIT_WINDOW : Int = 24 * 60 * 60 * 1_000_000_000; // 24 hours
    
    // Financial limits (customizable by DAO creator)
    let MAX_TOKEN_AMOUNT : Nat = 1_000_000_000 * 100_000_000; // 1B tokens with 8 decimals
    let MIN_STAKE_AMOUNT : Nat = switch (init.customSecurity) {
        case (?custom) {
            switch (custom.minStakeAmount) {
                case (?value) { value };
                case null { 100_000_000 }; // Default: 1 token with 8 decimals
            };
        };
        case null { 100_000_000 }; // Default: 1 token with 8 decimals
    };
    let MAX_STAKE_AMOUNT : Nat = switch (init.customSecurity) {
        case (?custom) {
            switch (custom.maxStakeAmount) {
                case (?value) { value };
                case null { 100_000_000 * 100_000_000 }; // Default: 100M tokens with 8 decimals
            };
        };
        case null { 100_000_000 * 100_000_000 }; // Default: 100M tokens with 8 decimals
    };
    let MIN_PROPOSAL_DEPOSIT : Nat = switch (init.customSecurity) {
        case (?custom) {
            switch (custom.minProposalDeposit) {
                case (?value) { value };
                case null { 1 * 100_000_000 }; // Default: 1 token
            };
        };
        case null { 1 * 100_000_000 }; // Default: 1 token
    };
    let MAX_PROPOSAL_DEPOSIT : Nat = switch (init.customSecurity) {
        case (?custom) {
            switch (custom.maxProposalDeposit) {
                case (?value) { value };
                case null { 10_000 * 100_000_000 }; // Default: 10K tokens
            };
        };
        case null { 10_000 * 100_000_000 }; // Default: 10K tokens
    };
    
    // Governance limits (fixed constants)
    let MIN_QUORUM_PERCENTAGE : Nat = 100; // 1% in basis points
    let MAX_QUORUM_PERCENTAGE : Nat = 5000; // 50% in basis points
    let MIN_APPROVAL_THRESHOLD : Nat = 5000; // 50% in basis points  
    let MAX_APPROVAL_THRESHOLD : Nat = 10000; // 100% in basis points
    let MAX_VOTING_POWER_MULTIPLIER : Nat = 40000; // 4x in basis points
    let MAX_EMERGENCY_CONTACTS : Nat = 10;
    let MAX_STAKE_LOCK_PERIODS : Nat = 10;
    
    // System limits (fixed constants)
    let MAX_PROPOSALS_PER_DAO : Nat = 10000;
    let MAX_MEMBERS_PER_DAO : Nat = 100000;
    let MAX_DELEGATION_CHAIN_LENGTH : Nat = 5; // Prevent infinite delegation chains
    let MIN_CYCLES_FOR_OPERATION : Nat = 1_000_000_000; // 1B cycles minimum
    let HEARTBEAT_INTERVAL_NS : Int = 60 * 1_000_000_000; // 1 minute
    let MAX_HEARTBEAT_OPERATIONS : Nat = 10; // Max operations per heartbeat


    // 🛡️ AUDITOR-APPROVED MULTIPLIER TIER SYSTEM
    // Replaces vulnerable soft-multiplier with configurable secure tiers
    
    // Security constants
    private let MAX_LOCK_DAYS : Nat = 1095; // 3 years max
    private let MIN_LOCK_DAYS : Nat = 7;    // Flash loan protection
    private let MAX_MULTIPLIER : Float = 3.0; // Anti-governance capture  
    private let MIN_MULTIPLIER : Float = 1.0; // Base multiplier
    private let SECONDS_PER_DAY : Nat = 86400;
    private let MAX_TIERS_PER_DAO : Nat = 10; // Prevent complexity attacks
    private let MAX_VP_PERCENT_PER_TIER : Nat = 40; // Anti-whale protection
    
    // Custom Multiplier Tier Definition
    public type CustomMultiplierTier = {
        id: Nat;
        name: Text;
        minStake: Nat;              // Minimum tokens required (e8s)
        maxStakePerEntry: ?Nat;     // Max tokens per entry (None = unlimited)
        lockPeriod: Nat;            // Lock period in seconds
        multiplier: Float;          // Voting power multiplier (1.0 - 3.0)
        maxVpPercentage: Nat;       // Max VP% this tier can hold (1-40)
        isActive: Bool;             // Can be disabled without deletion
        emergencyUnlockEnabled: Bool;
        flashLoanProtection: Bool;  // Enforce minimum lock
        createdAt: Time.Time;
        lastModified: Time.Time;
    };
    
    // DAO Tier Configuration
    private stable var multiplierTiers_stable : [(Nat, CustomMultiplierTier)] = [];
    private var multiplierTiers = Trie.empty<Nat, CustomMultiplierTier>();
    private stable var nextTierId : Nat = 1;
    private stable var defaultTierId : Nat = 0; // Fallback tier
    
    // Treasury Management Configuration - Community DAO Governance Only
    public type TreasuryConfig = {
        // Community governance settings (no admin controls)
        treasuryProposalThreshold: Nat;     // Higher threshold for treasury proposals  
        treasuryQuorumPercentage: Nat;      // Higher quorum for treasury operations
        maxSingleWithdrawal: Nat;           // Max tokens per proposal
        maxDailyWithdrawal: Nat;            // Max tokens per day across all proposals
        
        // Security features
        emergencyPauseEnabled: Bool;
        auditTrailEnabled: Bool;
        
        // DAO-only treasury control (no admin access)
        requireProposalForWithdrawal: Bool; // Always true for community DAOs
        minExecutionDelay: Nat;             // Additional delay for treasury proposals
    };
    
    private stable var treasuryConfig : TreasuryConfig = {
        // Higher thresholds for treasury governance (community protection)
        treasuryProposalThreshold = 7500; // 75% approval needed for treasury
        treasuryQuorumPercentage = 4000;  // 40% quorum for treasury operations
        maxSingleWithdrawal = 50_000 * Types.E8S;  // 50K tokens max per proposal
        maxDailyWithdrawal = 100_000 * Types.E8S;  // 100K tokens max per day
        
        // Security features
        emergencyPauseEnabled = false;
        auditTrailEnabled = true;
        
        // DAO-only governance (no admin access to treasury)
        requireProposalForWithdrawal = true;  // Always require community proposal
        minExecutionDelay = 259200;           // 3 days additional delay for treasury
    };
    
    // ================ VALIDATION FUNCTIONS ================
    
    /// Check if a timestamp is within a reasonable range
    func isValidTimestamp(timestamp: Int) : Bool {
        let now = Time.now();
        let fiveYearsAgo = now - (5 * 365 * 24 * 60 * 60 * 1_000_000_000);
        let oneYearFuture = now + (365 * 24 * 60 * 60 * 1_000_000_000);
        
        timestamp >= fiveYearsAgo and timestamp <= oneYearFuture
    };
    
    /// Check if voting period is within acceptable bounds
    func isValidVotingPeriod(period: Int) : Bool {
        period >= MIN_VOTING_PERIOD and period <= MAX_VOTING_PERIOD
    };
    
    /// Check if timelock duration is within acceptable bounds  
    func isValidTimelockDuration(duration: Int) : Bool {
        duration >= MIN_TIMELOCK_DURATION and duration <= MAX_TIMELOCK_DURATION
    };
    
    /// Check if percentage is valid (in basis points)
    func isValidBasisPoints(basisPoints: Nat) : Bool {
        basisPoints <= 10000 // 100% maximum
    };
    
    /// Check if quorum percentage is within acceptable bounds
    func isValidQuorumPercentage(percentage: Nat) : Bool {
        percentage >= MIN_QUORUM_PERCENTAGE and percentage <= MAX_QUORUM_PERCENTAGE
    };
    
    /// Check if approval threshold is within acceptable bounds
    func isValidApprovalThreshold(threshold: Nat) : Bool {
        threshold >= MIN_APPROVAL_THRESHOLD and threshold <= MAX_APPROVAL_THRESHOLD
    };
    
    // Transaction logging - CRITICAL FOR AUDIT TRAIL AND COMPLIANCE
    var transactions_stable : [Transaction] = [];
    var next_transaction_id : Nat = 1;
    
    // Governance state - Set to init values, will be restored in postupgrade
    var total_staked : Nat = init.totalStaked;
    var total_voting_power : Nat = init.totalVotingPower;
    var emergency_state : Types.EmergencyState = init.emergencyState;
    
    // Stable copies for upgrade safety
    stable var total_staked_stable : ?Nat = null;
    stable var total_voting_power_stable : ?Nat = null;
    stable var emergency_state_stable : ?Types.EmergencyState = null;
    
    // Timer management - stable storage for persistence
    var proposal_timers_stable : [(Nat, Types.ProposalTimer)] = [];
    var delegation_timers_stable : [(Principal, Types.DelegationTimer)] = [];
    
    // Security state
    var rate_limits_stable : [(Principal, Types.RateLimitRecord)] = [];
    var execution_contexts_stable : [(Nat, Types.ProposalExecutionContext)] = [];
    var security_events_stable : [Types.SecurityEvent] = [];
    // Security state - Set to init values, will be restored in postupgrade
    var last_security_check : Time.Time = init.lastSecurityCheck;
    
    // Comment system storage - Set to init values, will be restored in postupgrade
    var comments : Trie.Trie<Text, Types.ProposalComment> = Types.comments_fromArray(init.comments);
    stable var next_comment_id : Nat = 0;
    
    // Stable copies for upgrade safety
    stable var last_security_check_stable : ?Time.Time = null;
    stable var comments_stable : [(Text, Types.ProposalComment)] = [];
    
    // Vote tracking
    var vote_records_stable : [Types.VoteRecord] = [];
    
    // Transient variables (reconstructed from stable data)
    private transient var vote_records_trie : Trie.Trie<Text, Types.VoteRecord> = Trie.empty();
    private transient var rate_limits_trie : Trie.Trie<Principal, Types.RateLimitRecord> = Trie.empty();
    private transient var execution_contexts_trie : Trie.Trie<Nat, Types.ProposalExecutionContext> = Trie.empty();
    private transient var proposal_timers_trie : Trie.Trie<Nat, Types.ProposalTimer> = Trie.empty();
    private transient var delegation_timers_trie : Trie.Trie<Principal, Types.DelegationTimer> = Trie.empty();
    private transient var transactions_trie : Trie.Trie<Nat, Transaction> = Trie.empty();
    
    // Active timer IDs for cancellation
    private transient var active_timer_ids : Trie.Trie<Nat, Timer.TimerId> = Trie.empty();
    private transient var delegation_timer_ids : Trie.Trie<Principal, Timer.TimerId> = Trie.empty();
    
    // ICRC token interface
    var token_ledger : ?ICRC.ICRCLedger = ?actor(Principal.toText(token_config.canisterId));
    
    // Constants
    private let E8S : Nat = Types.E8S;
    private let BASIS_POINTS : Nat = Types.BASIS_POINTS;

    // ================ INITIALIZATION ================
    
    // Initialize factory data only on first creation
    _initializeFromFactory();
    
    // CRITICAL: Save all state to stable variables before upgrade
    system func preupgrade() {
        // Save Tries to stable arrays using Iter.toArray
        accounts_stable := Iter.toArray(Trie.iter(accounts));
        proposals_stable := Iter.toArray(Trie.iter(proposals));
        stakes_stable := Iter.toArray(Trie.iter(stakes));
        delegations_stable := Iter.toArray(Trie.iter(delegations));
        comments_stable := Iter.toArray(Trie.iter(comments));
        
        // Save configuration to stable variables
        system_params_stable := ?system_params;
        token_config_stable := ?token_config;
        governance_level_stable := ?governance_level;
        security_config_stable := ?security_config;
        
        // Save governance state
        total_staked_stable := ?total_staked;
        total_voting_power_stable := ?total_voting_power;
        emergency_state_stable := ?emergency_state;
        last_security_check_stable := ?last_security_check;
        
        // Store transaction data to stable storage - CRITICAL for compliance
        transactions_stable := Iter.toArray(Iter.map(Trie.iter(transactions_trie), func((k, v): (Nat, Transaction)) : Transaction = v));
        
        // Store timer data to stable storage for persistence across upgrades
        let proposalTimerBuffer = Buffer.Buffer<(Nat, Types.ProposalTimer)>(0);
        for ((proposalId, timer) in Trie.iter(proposal_timers_trie)) {
            proposalTimerBuffer.add((proposalId, timer));
        };
        proposal_timers_stable := Buffer.toArray(proposalTimerBuffer);
        
        let delegationTimerBuffer = Buffer.Buffer<(Principal, Types.DelegationTimer)>(0);
        for ((principal, timer) in Trie.iter(delegation_timers_trie)) {
            delegationTimerBuffer.add((principal, timer));
        };
        delegation_timers_stable := Buffer.toArray(delegationTimerBuffer);
        
        // Store security data
        let rateLimitBuffer = Buffer.Buffer<(Principal, Types.RateLimitRecord)>(0);
        for ((principal, record) in Trie.iter(rate_limits_trie)) {
            rateLimitBuffer.add((principal, record));
        };
        rate_limits_stable := Buffer.toArray(rateLimitBuffer);
        
        let contextBuffer = Buffer.Buffer<(Nat, Types.ProposalExecutionContext)>(0);
        for ((id, context) in Trie.iter(execution_contexts_trie)) {
            contextBuffer.add((id, context));
        };
        execution_contexts_stable := Buffer.toArray(contextBuffer);
    };
    
    system func postupgrade() {
        // Restore configuration from stable variables
        system_params := switch (system_params_stable) {
            case (?params) { params };
            case null { system_params }; // Keep init values if no stable data
        };
        
        token_config := switch (token_config_stable) {
            case (?config) { config };
            case null { token_config }; // Keep init values if no stable data
        };
        
        governance_level := switch (governance_level_stable) {
            case (?level) { level };
            case null { governance_level }; // Keep init values if no stable data
        };
        
        // Restore governance state
        total_staked := switch (total_staked_stable) {
            case (?staked) { staked };
            case null { total_staked }; // Keep init values if no stable data
        };
        
        total_voting_power := switch (total_voting_power_stable) {
            case (?power) { power };
            case null { total_voting_power }; // Keep init values if no stable data
        };
        
        emergency_state := switch (emergency_state_stable) {
            case (?state) { state };
            case null { emergency_state }; // Keep init values if no stable data
        };
        
        last_security_check := switch (last_security_check_stable) {
            case (?check) { check };
            case null { last_security_check }; // Keep init values if no stable data
        };
        
        // Restore Tries from stable data
        accounts := Trie.empty<Principal, Types.Account>();
        for ((principal, account) in accounts_stable.vals()) {
            accounts := Trie.put(accounts, Types.stake_key(principal), Principal.equal, account).0;
        };
        
        proposals := Trie.empty<Nat, Types.Proposal>();
        for ((proposalId, proposal) in proposals_stable.vals()) {
            let key = { key = proposalId; hash = Int.hash(proposalId) };
            proposals := Trie.put(proposals, key, Nat.equal, proposal).0;
        };
        
        stakes := Trie.empty<Principal, Types.StakeRecord>();
        for ((principal, stake) in stakes_stable.vals()) {
            stakes := Trie.put(stakes, Types.stake_key(principal), Principal.equal, stake).0;
        };
        
        delegations := Trie.empty<Principal, Types.DelegationRecord>();
        for ((principal, delegation) in delegations_stable.vals()) {
            delegations := Trie.put(delegations, Types.stake_key(principal), Principal.equal, delegation).0;
        };
        
        comments := Trie.empty<Text, Types.ProposalComment>();
        for ((commentId, comment) in comments_stable.vals()) {
            let key = { key = commentId; hash = Text.hash(commentId) };
            comments := Trie.put(comments, key, Text.equal, comment).0;
        };
        
        // Initialize token ledger after upgrade
        token_ledger := ?actor(Principal.toText(token_config.canisterId));
        
        // Reconstruct vote records trie from stable storage  
        // Note: Skip vote records restoration since we changed the key structure (Nat -> Text)
        // In production, a migration function would be needed
        vote_records_trie := Trie.empty();
        
        // Reconstruct transaction trie from stable storage
        transactions_trie := Trie.empty();
        for (i in transactions_stable.keys()) {
            let key = { key = transactions_stable[i].id; hash = Int.hash(transactions_stable[i].id) };
            transactions_trie := Trie.put(transactions_trie, key, Nat.equal, transactions_stable[i]).0;
        };
        
        // Reconstruct security tries from stable storage
        rate_limits_trie := Trie.empty();
        for ((principal, record) in rate_limits_stable.vals()) {
            rate_limits_trie := Trie.put(rate_limits_trie, Types.stake_key(principal), Principal.equal, record).0;
        };
        
        execution_contexts_trie := Trie.empty();
        for ((proposalId, context) in execution_contexts_stable.vals()) {
            let key = { key = proposalId; hash = Int.hash(proposalId) };
            execution_contexts_trie := Trie.put(execution_contexts_trie, key, Nat.equal, context).0;
        };
        
        // Reconstruct timer tries from stable storage
        proposal_timers_trie := Trie.empty();
        for ((proposalId, timer) in proposal_timers_stable.vals()) {
            let key = { key = proposalId; hash = Int.hash(proposalId) };
            proposal_timers_trie := Trie.put(proposal_timers_trie, key, Nat.equal, timer).0;
        };
        
        delegation_timers_trie := Trie.empty();
        for ((principal, timer) in delegation_timers_stable.vals()) {
            let key = Types.stake_key(principal);
            delegation_timers_trie := Trie.put(delegation_timers_trie, key, Principal.equal, timer).0;
        };
        
        // Timers will need to be restored manually after upgrade
        
        // Perform security validation after upgrade
        _performSecurityValidation();
    };
    
    // ================ STABLE VARIABLE SYNC HELPERS ================
    // These functions ensure stable variables are updated when runtime variables change
    
    private func _syncAccountsToStable() {
        accounts_stable := Iter.toArray(Trie.iter(accounts));
    };
    
    private func _syncProposalsToStable() {
        proposals_stable := Iter.toArray(Trie.iter(proposals));
    };
    
    private func _syncStakesToStable() {
        stakes_stable := Iter.toArray(Trie.iter(stakes));
    };
    
    private func _syncDelegationsToStable() {
        delegations_stable := Iter.toArray(Trie.iter(delegations));
    };
    
    private func _syncCommentsToStable() {
        comments_stable := Iter.toArray(Trie.iter(comments));
    };
    
    private func _syncSystemParamsToStable() {
        system_params_stable := ?system_params;
    };
    
    private func _syncTokenConfigToStable() {
        token_config_stable := ?token_config;
    };
    
    private func _syncGovernanceStateToStable() {
        total_staked_stable := ?total_staked;
        total_voting_power_stable := ?total_voting_power;
        emergency_state_stable := ?emergency_state;
        governance_level_stable := ?governance_level;
    };
    
    private func _syncSecurityStateToStable() {
        last_security_check_stable := ?last_security_check;
        security_config_stable := ?security_config;
    };

    // ================ TRANSACTION LOGGING SYSTEM ================
    
    /// Create transaction log entry - ESSENTIAL for compliance and audit
    private func _logTransaction(transactionType: TransactionType, from: Principal, to: ?Principal, amount: Nat, description: Text) : Nat {
        let transactionId = next_transaction_id;
        next_transaction_id += 1;
        
        let transaction : Transaction = {
            id = transactionId;
            transactionType = transactionType;
            from = from;
            to = to;
            amount = amount;
            blockIndex = null; // Will be updated when ICRC transfer completes
            timestamp = Time.now();
            description = description;
            status = #Pending;
        };
        
        let key = { key = transactionId; hash = Int.hash(transactionId) };
        transactions_trie := Trie.put(transactions_trie, key, Nat.equal, transaction).0;
        
        transactionId
    };
    
    /// Update transaction with block index and status - CRITICAL for audit trail
    private func _updateTransaction(transactionId: Nat, blockIndex: ?Nat, status: { #Pending; #Completed; #Failed: Text }) {
        let key = { key = transactionId; hash = Int.hash(transactionId) };
        switch (Trie.get(transactions_trie, key, Nat.equal)) {
            case null { /* Transaction not found */ };
            case (?transaction) {
                let updatedTransaction = {
                    transaction with 
                    blockIndex = blockIndex;
                    status = status;
                };
                transactions_trie := Trie.put(transactions_trie, key, Nat.equal, updatedTransaction).0;
            };
        };
    };

    // ================ TIMER MANAGEMENT SYSTEM ================
    
    /// Restore all timers after upgrade
    private func _restoreTimersAfterUpgrade() : async () {
        let now = Time.now();
        
        // Restore proposal timers
        for ((proposalId, proposalTimer) in Trie.iter(proposal_timers_trie)) {
            if (proposalTimer.scheduledTime > now) {
                // Timer hasn't expired, reschedule it
                let duration = Int.abs(proposalTimer.scheduledTime - now);
                let timerId = Timer.setTimer<system>(#nanoseconds(duration), func() : async () {
                    await _handleProposalTimer(proposalId, proposalTimer.timerType);
                });
                
                let key = { key = proposalId; hash = Int.hash(proposalId) };
                active_timer_ids := Trie.put(active_timer_ids, key, Nat.equal, timerId).0;
            } else {
                // Timer has expired, execute immediately
                ignore Timer.setTimer<system>(#nanoseconds(1000000), func() : async () {
                    await _handleProposalTimer(proposalId, proposalTimer.timerType);
                });
            };
        };
        
        // Restore delegation timers
        for ((principal, delegationTimer) in Trie.iter(delegation_timers_trie)) {
            if (delegationTimer.scheduledTime > now) {
                let duration = Int.abs(delegationTimer.scheduledTime - now);
                let timerId = Timer.setTimer<system>(#nanoseconds(duration), func() : async () {
                    await _handleDelegationTimer(principal);
                });
                
                let key = Types.stake_key(principal);
                delegation_timer_ids := Trie.put(delegation_timer_ids, key, Principal.equal, timerId).0;
            } else {
                // Timer has expired, process immediately
                ignore Timer.setTimer<system>(#nanoseconds(1000000), func() : async () {
                    await _handleDelegationTimer(principal);
                });
            };
        };
    };
    
    /// Schedule timer for proposal lifecycle events
    private func _scheduleProposalTimer(proposalId: Nat, timerType: Types.ProposalTimerType, scheduledTime: Time.Time) : async () {
        let now = Time.now();
        let duration = if (scheduledTime > now) { 
            Int.abs(scheduledTime - now) 
        } else { 
            1000000 // 1ms for immediate execution
        };
        
        let timerId = Timer.setTimer<system>(#nanoseconds(duration), func() : async () {
            await _handleProposalTimer(proposalId, timerType);
        });
        
        // Store timer info
        let proposalTimer : Types.ProposalTimer = {
            proposalId = proposalId;
            timerType = timerType;
            scheduledTime = scheduledTime;
            createdAt = now;
            remainingTime = scheduledTime - now;
        };
        
        let key = { key = proposalId; hash = Int.hash(proposalId) };
        proposal_timers_trie := Trie.put(proposal_timers_trie, key, Nat.equal, proposalTimer).0;
        active_timer_ids := Trie.put(active_timer_ids, key, Nat.equal, timerId).0;
    };
    
    /// Handle proposal timer events
    private func _handleProposalTimer(proposalId: Nat, timerType: Types.ProposalTimerType) : async () {
        switch (Trie.get(proposals, Types.proposal_key(proposalId), Nat.equal)) {
            case null { return }; // Proposal not found
            case (?proposal) {
                switch (timerType) {
                    case (#VotingEnd) {
                        await _processVotingEndTimer(proposalId, proposal);
                    };
                    case (#TimelockEnd) {
                        await _processTimelockEndTimer(proposalId, proposal);
                    };
                    case (#Cleanup) {
                        await _processCleanupTimer(proposalId, proposal);
                    };
                };
            };
        };
        
        // Cleanup timer after execution
        let key = { key = proposalId; hash = Int.hash(proposalId) };
        proposal_timers_trie := Trie.remove(proposal_timers_trie, key, Nat.equal).0;
        active_timer_ids := Trie.remove(active_timer_ids, key, Nat.equal).0;
    };
    
    /// Process voting end timer
    private func _processVotingEndTimer(proposalId: Nat, proposal: Types.Proposal) : async () {
        if (proposal.state != #Open) { return };
        
        let now = Time.now();
        let votingEndTime = proposal.timestamp + Int.abs(system_params.max_voting_period * 1_000_000_000);
        if (now >= votingEndTime) {
            let totalVotes = proposal.votes_yes + proposal.votes_no;
            let quorum = _calculateQuorum(total_voting_power);
            let quorumMet = totalVotes >= quorum;
            let approvalPercentage = if (totalVotes > 0) { 
                (proposal.votes_yes * BASIS_POINTS) / totalVotes 
            } else { 0 };
            let thresholdMet = approvalPercentage >= system_params.approval_threshold;
            
            let newState = if (quorumMet and thresholdMet) {
                // Schedule timelock timer if accepted
                let timelockEnd = now + system_params.timelock_duration;
                await _scheduleProposalTimer(proposalId, #TimelockEnd, timelockEnd);
                #Accepted
            } else {
                #Rejected
            };
            
            let updated_proposal = {
                proposal with 
                state = newState;
                voting_ends_at = now;
            };
            
            proposals := Trie.put(proposals, Types.proposal_key(proposalId), Nat.equal, updated_proposal).0;
            
            _logSecurityEvent(Principal.fromActor(Self), #SuspiciousActivity, 
                "Proposal " # Nat.toText(proposalId) # " moved to " # debug_show(newState), #Medium);
        };
    };
    
    /// Process timelock expiry timer
    private func _processTimelockEndTimer(proposalId: Nat, proposal: Types.Proposal) : async () {
        if (proposal.state != #Accepted) { return };
        
        let updated_proposal = {
            proposal with 
            state = #ExecutionReady;
        };
        
        proposals := Trie.put(proposals, Types.proposal_key(proposalId), Nat.equal, updated_proposal).0;
        
        // Schedule execution deadline timer (e.g., 30 days to execute)
        let executionDeadline = Time.now() + (30 * 24 * 60 * 60 * 1_000_000_000); // 30 days
        await _scheduleProposalTimer(proposalId, #Cleanup, executionDeadline);
        
        _logSecurityEvent(Principal.fromActor(Self), #SuspiciousActivity,
            "Proposal " # Nat.toText(proposalId) # " ready for execution", #Medium);
    };
    
    /// Process execution deadline timer
    private func _processCleanupTimer(proposalId: Nat, proposal: Types.Proposal) : async () {
        if (proposal.state != #ExecutionReady) { return };
        
        let updated_proposal = {
            proposal with 
            state = #Expired;
        };
        
        proposals := Trie.put(proposals, Types.proposal_key(proposalId), Nat.equal, updated_proposal).0;
        
        _logSecurityEvent(Principal.fromActor(Self), #SuspiciousActivity,
            "Proposal " # Nat.toText(proposalId) # " expired due to execution deadline", #High);
    };
    
    /// Cancel timer for proposal
    private func _cancelProposalTimer(proposalId: Nat) {
        let key = { key = proposalId; hash = Int.hash(proposalId) };
        switch (Trie.get(active_timer_ids, key, Nat.equal)) {
            case null { /* No timer to cancel */ };
            case (?timerId) {
                Timer.cancelTimer(timerId);
                active_timer_ids := Trie.remove(active_timer_ids, key, Nat.equal).0;
                proposal_timers_trie := Trie.remove(proposal_timers_trie, key, Nat.equal).0;
            };
        };
    };

    // ================ ENHANCED STAKE UTILITY FUNCTIONS ================
    
    // Get user's stake entries
    private func _getUserStakeEntries(user: Principal) : [Types.StakeEntry] {
        switch (Trie.get(stakeEntries, Types.stake_key(user), Principal.equal)) {
            case (?entries) { entries };
            case null { [] };
        }
    };
    
    // Update user's stake entries
    private func _updateUserStakeEntries(user: Principal, entries: [Types.StakeEntry]) {
        stakeEntries := Trie.put(stakeEntries, Types.stake_key(user), Principal.equal, entries).0;
    };
    
    // Add timeline entry
    private func _addTimelineEntry(user: Principal, action: Types.TimelineAction, details: Text, blockIndex: ?Nat) {
        let entry: Types.TimelineEntry = {
            id = nextTimelineEntryId;
            timestamp = Time.now();
            action = action;
            details = details;
            blockIndex = blockIndex;
        };
        
        let currentTimeline = switch (Trie.get(userTimelines, Types.stake_key(user), Principal.equal)) {
            case (?timeline) { timeline };
            case null { [] };
        };
        
        let updatedTimeline = Array.append([entry], currentTimeline);
        userTimelines := Trie.put(userTimelines, Types.stake_key(user), Principal.equal, updatedTimeline).0;
        nextTimelineEntryId += 1;
    };
    
    // Create new stake entry with tier validation
    private func _createStakeEntry(
        staker: Principal, 
        amount: Nat, 
        lockPeriod: Nat,
        blockIndex: ?Nat
    ) : Types.Result<Types.StakeEntry, Text> {
        
        // Find applicable multiplier tier based on lock period and amount
        let applicableTier = switch (_findTierByLockPeriod(lockPeriod)) {
            case (?tier) {
                // Convert to DAOTypes.MultiplierTier for validation
                let tierForValidation: DAOTypes.MultiplierTier = {
                    id = tier.id;
                    name = tier.name;
                    minStake = tier.minStake;
                    maxStakePerEntry = tier.maxStakePerEntry;
                    lockPeriod = tier.lockPeriod;
                    multiplier = tier.multiplier;
                    maxVpPercentage = tier.maxVpPercentage;
                    emergencyUnlockEnabled = tier.emergencyUnlockEnabled;
                    flashLoanProtection = tier.flashLoanProtection;
                    governanceCapProtection = tier.maxVpPercentage <= 40; // Set based on VP limit
                };
                
                // Validate amount meets tier requirements
                switch (DAOUtils.validateTierRequirements(amount, tierForValidation)) {
                    case (#ok()) { tier };
                    case (#err(msg)) {
                        // If amount doesn't meet tier requirements, use base tier (1.0x multiplier)
                        let baseTier: CustomMultiplierTier = {
                            id = 0;
                            name = "Base Tier";
                            minStake = 1;
                            maxStakePerEntry = null;
                            lockPeriod = lockPeriod;
                            multiplier = 1.0;
                            maxVpPercentage = 10;
                            isActive = true;
                            emergencyUnlockEnabled = false;
                            flashLoanProtection = true;
                            createdAt = Time.now();
                            lastModified = Time.now();
                        };
                        baseTier;
                    };
                };
            };
            case null {
                // No tier found for this lock period, use base multiplier
                let baseTier: CustomMultiplierTier = {
                    id = 0;
                    name = "Base Tier";
                    minStake = 1;
                    maxStakePerEntry = null;
                    lockPeriod = lockPeriod;
                    multiplier = 1.0;
                    maxVpPercentage = 10;
                    isActive = true;
                    emergencyUnlockEnabled = false;
                    flashLoanProtection = true;
                    createdAt = Time.now();
                    lastModified = Time.now();
                };
                baseTier;
            };
        };
        
        // Calculate tier-based voting power
        let tierMultiplier = applicableTier.multiplier;
        // Convert tier for calculation compatibility
        let tierForCalculation: DAOTypes.MultiplierTier = {
            id = applicableTier.id;
            name = applicableTier.name;
            minStake = applicableTier.minStake;
            maxStakePerEntry = applicableTier.maxStakePerEntry;
            lockPeriod = applicableTier.lockPeriod;
            multiplier = applicableTier.multiplier;
            maxVpPercentage = applicableTier.maxVpPercentage;
            emergencyUnlockEnabled = applicableTier.emergencyUnlockEnabled;
            flashLoanProtection = applicableTier.flashLoanProtection;
            governanceCapProtection = applicableTier.maxVpPercentage <= 40;
        };
        let votingPower = DAOUtils.calculateTierVotingPower(amount, tierForCalculation);
        
        let now = Time.now();
        let unlockTime = now + (Int.abs(lockPeriod) * 1_000_000_000);
        
        let entry: Types.StakeEntry = {
            id = nextStakeEntryId;
            staker = staker;
            amount = amount;
            stakedAt = now;
            lockPeriod = lockPeriod;
            unlockTime = unlockTime;
            multiplier = tierMultiplier;
            votingPower = votingPower;
            isActive = true;
            blockIndex = blockIndex;
        };
        
        nextStakeEntryId += 1;
        #ok(entry)
    };
    
    // Check if stake entry can be unstaked
    private func _canUnstakeEntry(entry: Types.StakeEntry) : Types.Result<(), Text> {
        let now = Time.now();
        
        if (not entry.isActive) {
            return #err("Stake entry is already inactive");
        };
        
        if (now < entry.unlockTime) {
            let remainingSeconds = Int.abs(entry.unlockTime - now) / 1_000_000_000;
            return #err("Stake is locked for " # Nat.toText(remainingSeconds) # " more seconds (Entry ID: " # Nat.toText(entry.id) # ")");
        };
        
        #ok(())
    };
    
    // Migrate legacy stake to new system (called on first interaction)
    private func _migrateLegacyStakeIfNeeded(user: Principal) : async () {
        // Check if user has legacy stake but no stake entries
        let hasLegacyStake = switch (Trie.get(stakes, Types.stake_key(user), Principal.equal)) {
            case (?_) { true };
            case null { false };
        };
        
        let hasStakeEntries = switch (Trie.get(stakeEntries, Types.stake_key(user), Principal.equal)) {
            case (?entries) { Array.size(entries) > 0 };
            case null { false };
        };
        
        if (hasLegacyStake and not hasStakeEntries) {
            switch (Trie.get(stakes, Types.stake_key(user), Principal.equal)) {
                case (?legacyStake) {
                    // Convert to new system as Liquid Staking (use default tier)
                    let liquidTier = switch (Trie.get(multiplierTiers, DAOUtils._natKey(defaultTierId), Nat.equal)) {
                        case (?tier) { tier };
                        case null { return }; // Should never happen - default tier should exist
                    };
                    
                    let migratedEntry: Types.StakeEntry = {
                        id = nextStakeEntryId;
                        staker = user;
                        amount = legacyStake.amount;
                        stakedAt = legacyStake.stakedAt;
                        lockPeriod = 0; // Liquid
                        unlockTime = Time.now(); // Already unlocked
                        multiplier = liquidTier.multiplier;
                        votingPower = legacyStake.votingPower;
                        isActive = true;
                        blockIndex = null; // Legacy stakes don't have block index
                    };
                    
                    nextStakeEntryId += 1;
                    _updateUserStakeEntries(user, [migratedEntry]);
                    
                    // Add timeline entry for migration
                    _addTimelineEntry(
                        user, 
                        #Stake({
                            entryId = migratedEntry.id; 
                            amount = migratedEntry.amount; 
                            lockPeriod = 0;
                        }),
                        "Legacy stake migrated to new system",
                        null
                    );
                };
                case null {};
            };
        };
    };

    // ================ STAKING FUNCTIONS WITH SECURITY ================

    /// 🔥 NEW: Enhanced stake function with tier system and anti-gaming
    public shared({caller}) func stake(amount: Nat, lockDuration: ?Nat) : async Types.Result<(), Text> {
        // ================ MIGRATION CHECK ================
        await _migrateLegacyStakeIfNeeded(caller);
        
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #Stake)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Input validation with SafeMath
        switch (SafeMath.validateAmount(amount, MIN_STAKE_AMOUNT, MAX_STAKE_AMOUNT)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Validate lock duration - allow any duration from 0 to MAX_LOCK_DAYS
        let validLockDuration = switch (lockDuration) {
            case null { 0 }; // Default to liquid staking (0 lock period)
            case (?duration) {
                let maxLockSeconds = MAX_LOCK_DAYS * SECONDS_PER_DAY;
                if (duration > maxLockSeconds) {
                    return #err("Lock duration cannot exceed " # Nat.toText(MAX_LOCK_DAYS) # " days (" # Nat.toText(maxLockSeconds) # " seconds)");
                };
                duration;
            };
        };

        let ledger = switch (token_ledger) {
            case null { return #err("Token ledger not initialized") };
            case (?ledger) { ledger };
        };

        // Create transaction log entry FIRST - ESSENTIAL for audit trail
        let transactionId = _logTransaction(
            #Stake, 
            caller, 
            ?Principal.fromActor(Self), 
            amount, 
            "Stake " # Nat.toText(amount) # " tokens with " # Nat.toText(validLockDuration) # "s lock"
        );

        // Check existing stake
        let existingStake = switch (Trie.get(stakes, Types.stake_key(caller), Principal.equal)) {
            case null { null };
            case (?stake) { ?stake };
        };

        // Find appropriate tier for this stake
        let tier = switch (_findApplicableTier(amount, validLockDuration)) {
            case (?t) { t };
            case null {
                // Fallback to default tier if no tier matches
                switch (_getTier(defaultTierId)) {
                    case (?defaultTier) { defaultTier };
                    case null { return #err("No valid tier found and default tier missing"); };
                };
            };
        };
        
        // Validate tier is still active
        if (not tier.isActive) {
            return #err("Selected tier is no longer active");
        };
        
        // Check minimum stake requirement
        if (amount < tier.minStake) {
            return #err("Amount below tier minimum: " # Nat.toText(amount / Types.E8S) # " < " # Nat.toText(tier.minStake / Types.E8S));
        };
        
        // Check maximum stake per entry if applicable
        switch (tier.maxStakePerEntry) {
            case (?maxStake) {
                if (amount > maxStake) {
                    return #err("Amount exceeds tier maximum: " # Nat.toText(amount / Types.E8S) # " > " # Nat.toText(maxStake / Types.E8S));
                };
            };
            case null { /* No limit */ };
        };
        
        // Calculate voting power with tier multiplier
        let votingPowerResult = _calculateTierVotingPower(amount, tier);
        let votingPower = switch (votingPowerResult) {
            case (#err(msg)) { 
                _updateTransaction(transactionId, null, #Failed("Voting power calculation failed: " # msg));
                return #err("Voting power calculation failed: " # msg);
            };
            case (#ok(vp)) { vp };
        };

        // ================ INTERACTIONS FIRST (FIXED) ================
        try {
            // 🔥 CRITICAL FIX: Use icrc2_transfer_from instead of icrc1_transfer
            // Frontend MUST call icrc2_approve first with this contract as spender
            let transferArgs : ICRC.TransferFromArgs = {
                spender_subaccount = null;
                from = { owner = caller; subaccount = null };
                to = { owner = Principal.fromActor(Self); subaccount = null };
                amount = amount;
                fee = ?system_params.transfer_fee;
                memo = null;
                created_at_time = null;
            };

            let transferResult = await ledger.icrc2_transfer_from(transferArgs);

            switch (transferResult) {
                case (#Err(e)) {
                    _updateTransaction(transactionId, null, #Failed("ICRC2 transfer failed: " # debug_show(e)));
                    return #err("Token transfer failed: " # debug_show(e) # ". Make sure you have approved this amount + fee for the DAO contract first.");
                };
                case (#Ok(blockIndex)) {
                    // Transfer successful, now update state
                    _updateTransaction(transactionId, ?blockIndex, #Completed);
                    
                    // ================ NEW: CREATE STAKE ENTRY ================
                    switch (_createStakeEntry(caller, amount, validLockDuration, ?blockIndex)) {
                        case (#err(msg)) {
                            _updateTransaction(transactionId, ?blockIndex, #Failed("Stake entry creation failed: " # msg));
                            return #err("Stake entry creation failed: " # msg);
                        };
                        case (#ok(stakeEntry)) {
                            // Add to user's stake entries
                            let currentEntries = _getUserStakeEntries(caller);
                            let updatedEntries = Array.append(currentEntries, [stakeEntry]);
                            _updateUserStakeEntries(caller, updatedEntries);
                            
                            // Update totals with SafeMath
                            switch (SafeMath.addNat(total_staked, amount)) {
                                case (#err(msg)) { return #err("Total staked calculation failed: " # msg) };
                                case (#ok(newTotal)) { total_staked := newTotal };
                            };

                            switch (SafeMath.addNat(total_voting_power, stakeEntry.votingPower)) {
                                case (#err(msg)) { return #err("Total voting power calculation failed: " # msg) };
                                case (#ok(newTotal)) { total_voting_power := newTotal };
                            };

                            // Add timeline entry
                            _addTimelineEntry(
                                caller,
                                #Stake({
                                    entryId = stakeEntry.id;
                                    amount = amount;
                                    lockPeriod = validLockDuration;
                                }),
                                "Staked " # Nat.toText(amount / Types.E8S) # " tokens (Lock: " # Nat.toText(validLockDuration / SECONDS_PER_DAY) # " days)",
                                ?blockIndex
                            );

                            // Log security event with block index
                            _logSecurityEvent(caller, #StakeChange, 
                                "Staked " # Nat.toText(amount / Types.E8S) # " tokens (Entry: " # Nat.toText(stakeEntry.id) # ", Lock: " # Nat.toText(validLockDuration / SECONDS_PER_DAY) # " days, Block: " # Nat.toText(blockIndex) # ")", #Low);
                            
                            return #ok();
                        };
                    };
                };
            };

        } catch (error) {
            _updateTransaction(transactionId, null, #Failed("Transfer error: " # Error.message(error)));
            return #err("Staking failed: " # Error.message(error));
        };
    };

    /// 🔥 LEGACY: Backward compatible unstake function (migrates first, then calls new system)
    public shared({caller}) func unstake(amount: Nat) : async Types.Result<(), Text> {
        // Migrate legacy stakes first
        await _migrateLegacyStakeIfNeeded(caller);
        
        // Check if user has stake entries
        let userEntries = _getUserStakeEntries(caller);
        if (Array.size(userEntries) == 0) {
            return #err("No stakes found");
        };
        
        // Find first available (unlocked) entry with sufficient amount
        var remainingAmount = amount;
        var updatedEntries: [Types.StakeEntry] = [];
        var totalVotingPowerReduction: Nat = 0;
        
        for (entry in userEntries.vals()) {
            if (remainingAmount == 0) {
                updatedEntries := Array.append(updatedEntries, [entry]);
            } else if (entry.isActive) {
                switch (_canUnstakeEntry(entry)) {
                    case (#ok()) {
                        let unstakeFromEntry = Nat.min(remainingAmount, entry.amount);
                        let votingPowerReduction = (entry.votingPower * unstakeFromEntry) / entry.amount;
                        
                        if (unstakeFromEntry == entry.amount) {
                            // Complete entry unstake
                            let deactivatedEntry = {
                                id = entry.id;
                                staker = entry.staker;
                                amount = entry.amount;
                                stakedAt = entry.stakedAt;
                                lockPeriod = entry.lockPeriod;
                                unlockTime = entry.unlockTime;
                                multiplier = entry.multiplier;
                                votingPower = entry.votingPower;
                                isActive = false;
                                blockIndex = entry.blockIndex;
                            };
                            updatedEntries := Array.append(updatedEntries, [deactivatedEntry]);
                        } else {
                            // Partial entry unstake
                            let updatedEntry = {
                                id = entry.id;
                                staker = entry.staker;
                                amount = Nat.sub(entry.amount, unstakeFromEntry);
                                stakedAt = entry.stakedAt;
                                lockPeriod = entry.lockPeriod;
                                unlockTime = entry.unlockTime;
                                multiplier = entry.multiplier;
                                votingPower = Nat.sub(entry.votingPower, votingPowerReduction);
                                isActive = true;
                                blockIndex = entry.blockIndex;
                            };
                            updatedEntries := Array.append(updatedEntries, [updatedEntry]);
                        };
                        
                        remainingAmount -= unstakeFromEntry;
                        totalVotingPowerReduction += votingPowerReduction;
                    };
                    case (#err(_)) {
                        updatedEntries := Array.append(updatedEntries, [entry]);
                    };
                }
            } else {
                updatedEntries := Array.append(updatedEntries, [entry]);
            }
        };
        
        if (remainingAmount > 0) {
            return #err("Insufficient unlocked tokens. Requested: " # Nat.toText(amount / Types.E8S) # ", available: " # Nat.toText(Nat.sub(amount, remainingAmount) / Types.E8S));
        };
        
        // Execute the unstake transaction
        switch (await _executeUnstakeTransfer(caller, amount, totalVotingPowerReduction)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(blockIndex)) {
                // Update state
                _updateUserStakeEntries(caller, updatedEntries);
                
                // Add timeline entry
                _addTimelineEntry(
                    caller,
                    #Unstake({ entryId = 0; amount = amount }), // 0 = legacy/batch unstake
                    "Unstaked " # Nat.toText(amount / Types.E8S) # " tokens (batch)",
                    ?blockIndex
                );
                
                return #ok();
            };
        }
    };

    /// 🔥 NEW: Enhanced unstake specific entry with granular control
    public shared({caller}) func unstakeEntry(entryId: Nat, amount: ?Nat) : async Types.Result<(), Text> {
        // Migrate legacy stakes first
        await _migrateLegacyStakeIfNeeded(caller);
        
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #Unstake)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        let userEntries = _getUserStakeEntries(caller);
        
        // Find the specific entry
        let entryOpt = Array.find<Types.StakeEntry>(userEntries, func(e) = e.id == entryId and e.staker == caller);
        let entry = switch (entryOpt) {
            case (?e) { e };
            case null { return #err("Stake entry not found or not owned by caller") };
        };

        // Check if entry can be unstaked
        switch (_canUnstakeEntry(entry)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Determine unstake amount
        let unstakeAmount = switch (amount) {
            case (?amt) {
                if (amt > entry.amount) {
                    return #err("Cannot unstake more than staked amount. Requested: " # Nat.toText(amt / Types.E8S) # ", available: " # Nat.toText(entry.amount / Types.E8S));
                };
                amt
            };
            case null { entry.amount }; // Unstake full entry
        };

        // Calculate voting power reduction
        let votingPowerReduction = Nat.div(Nat.mul(entry.votingPower, unstakeAmount), entry.amount);

        // Execute the unstake transaction
        switch (await _executeUnstakeTransfer(caller, unstakeAmount, votingPowerReduction)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(blockIndex)) {
                // Update entry state
                let updatedEntries = Array.map<Types.StakeEntry, Types.StakeEntry>(userEntries, func(e) {
                    if (e.id == entryId) {
                        if (unstakeAmount == e.amount) {
                            // Complete entry unstake - deactivate
                            {
                                id = e.id;
                                staker = e.staker;
                                amount = e.amount;
                                stakedAt = e.stakedAt;
                                lockPeriod = e.lockPeriod;
                                unlockTime = e.unlockTime;
                                multiplier = e.multiplier;
                                votingPower = e.votingPower;
                                isActive = false; // Deactivated
                                blockIndex = e.blockIndex;
                            }
                        } else {
                            // Partial entry unstake
                            {
                                id = e.id;
                                staker = e.staker;
                                amount = Nat.sub(e.amount, unstakeAmount);
                                stakedAt = e.stakedAt;
                                lockPeriod = e.lockPeriod;
                                unlockTime = e.unlockTime;
                                multiplier = e.multiplier;
                                votingPower = Nat.sub(e.votingPower, votingPowerReduction);
                                isActive = true; // Still active
                                blockIndex = e.blockIndex;
                            }
                        }
                    } else {
                        e
                    }
                });
                
                _updateUserStakeEntries(caller, updatedEntries);
                
                // Add timeline entry
                _addTimelineEntry(
                    caller,
                    #Unstake({ entryId = entryId; amount = unstakeAmount }),
                    "Unstaked " # Nat.toText(unstakeAmount / Types.E8S) # " tokens (Entry #" # Nat.toText(entryId) # ", Lock: " # Nat.toText(entry.lockPeriod / SECONDS_PER_DAY) # " days)",
                    ?blockIndex
                );
                
                return #ok();
            };
        }
    };

    /// Private helper for executing unstake transfer
    private func _executeUnstakeTransfer(caller: Principal, amount: Nat, votingPowerReduction: Nat) : async Types.Result<Nat, Text> {
        let ledger = switch (token_ledger) {
            case null { return #err("Token ledger not initialized") };
            case (?ledger) { ledger };
        };

        // Create transaction log entry
        let transactionId = _logTransaction(
            #Unstake, 
            Principal.fromActor(Self), 
            ?caller, 
            amount, 
            "Unstake " # Nat.toText(amount / Types.E8S) # " tokens"
        );

        // Update totals first (optimistic)
        total_staked := Nat.sub(total_staked, amount);
        total_voting_power := Nat.sub(total_voting_power, votingPowerReduction);

        // Execute transfer
        try {
            let transferResult = await ledger.icrc1_transfer({
                from_subaccount = null;
                to = { owner = caller; subaccount = null };
                amount = amount;
                fee = ?system_params.transfer_fee;
                memo = null;
                created_at_time = null;
            });

            switch (transferResult) {
                case (#Err(e)) {
                    // Revert state changes on transfer failure
                    total_staked := Nat.add(total_staked, amount);
                    total_voting_power := Nat.add(total_voting_power, votingPowerReduction);
                    
                    _updateTransaction(transactionId, null, #Failed("ICRC1 transfer failed: " # debug_show(e)));
                    _logSecurityEvent(caller, #SuspiciousActivity,
                        "Token transfer failed during unstaking: " # debug_show(e), #High);
                    return #err("Token transfer failed: " # debug_show(e));
                };
                case (#Ok(blockIndex)) {
                    _updateTransaction(transactionId, ?blockIndex, #Completed);
                    _logSecurityEvent(caller, #StakeChange,
                        "Unstaked " # Nat.toText(amount / Types.E8S) # " tokens (Block: " # Nat.toText(blockIndex) # ")", #Low);
                    return #ok(blockIndex);
                };
            };

        } catch (error) {
            // Revert state changes on error
            total_staked := Nat.add(total_staked, amount);
            total_voting_power := Nat.add(total_voting_power, votingPowerReduction);
            
            _updateTransaction(transactionId, null, #Failed("Error: " # Error.message(error)));
            _logSecurityEvent(caller, #SuspiciousActivity,
                "Unstaking failed with error: " # Error.message(error), #High);
            return #err("Unstaking failed: " # Error.message(error));
        };
    };

    // ================ PROPOSAL FUNCTIONS WITH TRANSACTION LOGGING ================

    /// Execute a proposal that's ready for execution
    public shared({caller}) func executeProposal(proposalId: Nat) : async Types.Result<(), Text> {
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #Execute)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Get proposal
        let proposal = switch (Trie.get(proposals, Types.proposal_key(proposalId), Nat.equal)) {
            case null { return #err("Proposal not found") };
            case (?proposal) { proposal };
        };

        // Validate proposal state
        if (proposal.state != #ExecutionReady) {
            return #err("Proposal is not ready for execution. Current state: " # debug_show(proposal.state));
        };

        // Create execution context to prevent re-execution
        let executionContext : Types.ProposalExecutionContext = {
            proposalId = proposalId;
            executor = caller;
            executionStarted = Time.now();
            expectedCompletionTime = ?(Time.now() + (30 * 60 * 1_000_000_000)); // 30 minutes
            criticalOperation = true; // All proposal executions are considered critical
        };

        let contextKey = { key = proposalId; hash = Int.hash(proposalId) };
        execution_contexts_trie := Trie.put(execution_contexts_trie, contextKey, Nat.equal, executionContext).0;

        // Update proposal state to executing
        let executingProposal = {
            proposal with 
            state = #Executing;
        };
        proposals := Trie.put(proposals, Types.proposal_key(proposalId), Nat.equal, executingProposal).0;

        // Cancel execution deadline timer since we're executing now
        _cancelProposalTimer(proposalId);

        // ================ EXECUTE BASED ON PROPOSAL TYPE ================
        let executionResult = switch (proposal.payload) {
            case (#Motion(motion)) {
                // Motion proposals are informational - mark as succeeded
                _logSecurityEvent(caller, #SuspiciousActivity,
                    "Motion proposal " # Nat.toText(proposalId) # " executed: " # motion.title, #Low);
                #ok("Motion proposal executed successfully");
            };
            
            case (#TokenManage(tokenAction)) {
                await _executeTokenManagement(proposalId, tokenAction, caller);
            };
            
            case (#CallExternal(externalCall)) {
                await _executeExternalCall(proposalId, externalCall, caller);
            };
            
            case (#SystemUpdate(systemUpdate)) {
                await _executeSystemUpdate(proposalId, systemUpdate, caller);
            };
        };

        // ================ UPDATE EXECUTION CONTEXT AND PROPOSAL STATE ================
        let now = Time.now();
        let finalState = switch (executionResult) {
            case (#ok(_)) { #Succeeded };
            case (#err(_)) { #Failed(switch (executionResult) { case (#err(msg)) msg; case _ "Unknown error" }) };
        };

        // Update execution context
        let completedContext = {
            executionContext with
            status = switch (finalState) {
                case (#Succeeded) { #Completed };
                case (#Failed(msg)) { #Failed(msg) };
                case (_) { #Failed("Unknown error") };
            };
        };
        execution_contexts_trie := Trie.put(execution_contexts_trie, contextKey, Nat.equal, completedContext).0;

        // Update proposal state
        let finalProposal = {
            proposal with 
            state = finalState;
            executed_at = ?now;
        };
        proposals := Trie.put(proposals, Types.proposal_key(proposalId), Nat.equal, finalProposal).0;

        // Log final result
        _logSecurityEvent(caller, #ProposalExecution,
            "Proposal " # Nat.toText(proposalId) # " execution " # debug_show(finalState), #High);

        switch (executionResult) {
            case (#ok(_)) { #ok() };
            case (#err(msg)) { #err(msg) };
        }
    };

    /// Execute token management actions
    private func _executeTokenManagement(proposalId: Nat, tokenAction: Types.TokenManagePayload, executor: Principal) : async Types.Result<Text, Text> {
        let ledger = switch (token_ledger) {
            case null { return #err("Token ledger not initialized") };
            case (?ledger) { ledger };
        };

        switch (tokenAction) {
            case (#Transfer(args)) {
                // 🛡️ TREASURY GOVERNANCE VALIDATION
                // Ensure this treasury transfer meets community DAO requirements
                
                // Check if this is a treasury withdrawal (requires stricter validation)
                if (treasuryConfig.requireProposalForWithdrawal) {
                    // Validate withdrawal amount against limits
                    if (args.amount > treasuryConfig.maxSingleWithdrawal) {
                        return #err("Transfer amount exceeds maximum single withdrawal limit: " # 
                                  Nat.toText(treasuryConfig.maxSingleWithdrawal / Types.E8S) # " tokens");
                    };
                    
                    // Get proposal for additional validation
                    let proposal = switch (Trie.get(proposals, Types.proposal_key(proposalId), Nat.equal)) {
                        case null { return #err("Proposal not found for treasury validation") };
                        case (?p) { p };
                    };
                    
                    // Ensure higher approval threshold was met for treasury transfers
                    let yesVotes = proposal.votes_yes;
                    let totalVotes = proposal.votes_yes + proposal.votes_no;
                    let approvalPercentage = if (totalVotes > 0) {
                        (yesVotes * 10000) / totalVotes
                    } else { 0 };
                    
                    if (approvalPercentage < treasuryConfig.treasuryProposalThreshold) {
                        return #err("Treasury transfer requires " # 
                                  Nat.toText(treasuryConfig.treasuryProposalThreshold / 100) # 
                                  "% approval. Current: " # Nat.toText(approvalPercentage / 100) # "%");
                    };
                    
                    // Log treasury operation for audit trail
                    _logSecurityEvent(executor, #LargeTokenTransfer,
                        "Treasury transfer: " # Nat.toText(args.amount / Types.E8S) # 
                        " tokens to " # Principal.toText(args.to) # 
                        " via proposal " # Nat.toText(proposalId), #High);
                };
                // END TREASURY VALIDATION
                
                // Create transaction log
                let memo = switch (args.memo) {
                    case (?m) m;
                    case null "No memo";
                };
                let transactionId = _logTransaction(
                    #Transfer, 
                    Principal.fromActor(Self), 
                    ?args.to, 
                    args.amount, 
                    "Proposal " # Nat.toText(proposalId) # " token transfer: " # memo
                );

                try {
                    let transferResult = await ledger.icrc1_transfer({
                        from_subaccount = null;
                        to = { owner = args.to; subaccount = null };
                        amount = args.amount;
                        fee = ?system_params.transfer_fee;
                        memo = null;
                        created_at_time = null;
                    });

                    switch (transferResult) {
                        case (#Err(e)) {
                            _updateTransaction(transactionId, null, #Failed("Transfer failed: " # debug_show(e)));
                            #err("Token transfer failed: " # debug_show(e));
                        };
                        case (#Ok(blockIndex)) {
                            _updateTransaction(transactionId, ?blockIndex, #Completed);
                            #ok("Transfer completed. Block: " # Nat.toText(blockIndex));
                        };
                    };
                } catch (error) {
                    _updateTransaction(transactionId, null, #Failed("Error: " # Error.message(error)));
                    #err("Transfer failed: " # Error.message(error));
                };
            };

            case (#Burn(args)) {
                if (not token_config.managedByDAO) {
                    return #err("DAO does not have token management permissions");
                };
                
                // Create transaction log
                let memo = switch (args.memo) {
                    case (?m) m;
                    case null "No memo";
                };
                let transactionId = _logTransaction(
                    #Transfer, 
                    Principal.fromActor(Self), 
                    null, 
                    args.amount, 
                    "Proposal " # Nat.toText(proposalId) # " token burn: " # memo
                );

                // TODO: Implement burn when ICRC standard supports it
                _updateTransaction(transactionId, null, #Failed("Burn functionality not yet implemented"));
                #err("Token burn functionality not yet implemented");
            };

            case (#Mint(args)) {
                if (not token_config.managedByDAO) {
                    return #err("DAO does not have token management permissions");
                };
                
                // Create transaction log  
                let memo = switch (args.memo) {
                    case (?m) m;
                    case null "No memo";
                };
                let transactionId = _logTransaction(
                    #Transfer, 
                    Principal.fromActor(Self), 
                    ?args.to, 
                    args.amount, 
                    "Proposal " # Nat.toText(proposalId) # " token mint: " # memo
                );

                // TODO: Implement mint when DAO has minting permissions
                _updateTransaction(transactionId, null, #Failed("Mint functionality not yet implemented"));
                #err("Token mint functionality not yet implemented");
            };

            case (#UpdateMetadata(args)) {
                if (not token_config.managedByDAO) {
                    return #err("DAO does not have token management permissions");
                };
                
                // TODO: Implement metadata update when ICRC supports it
                #err("Token metadata update not yet implemented");
            };
        }
    };

    /// Execute external canister calls
    private func _executeExternalCall(proposalId: Nat, externalCall: Types.CallExternalPayload, executor: Principal) : async Types.Result<Text, Text> {
        try {
            // Validate the call target
            if (externalCall.target == Principal.fromActor(Self)) {
                return #err("Cannot make external call to self");
            };

            // Security check: ensure target is not a sensitive canister
            let targetText = Principal.toText(externalCall.target);
            if (targetText == "rdmx6-jaaaa-aaaah-qdrva-cai" or // IC Management Canister
                targetText == "rrkah-fqaaa-aaaah-qcuwa-cai" or // NNS Registry
                targetText == "rno2w-sqaaa-aaaah-qcuwa-cai") {  // NNS Root
                return #err("Cannot call sensitive system canisters");
            };

            // Make the external call with controlled permissions
            let callResult = await ICRaw.call(externalCall.target, externalCall.method, externalCall.args);
            
            _logSecurityEvent(executor, #ProposalExecution,
                "External call successful: " # externalCall.method # " to " # Principal.toText(externalCall.target), #Medium);
                
            #ok("External call completed successfully");
            
        } catch (error) {
            _logSecurityEvent(executor, #SuspiciousActivity,
                "External call failed: " # Error.message(error), #High);
            #err("External call failed: " # Error.message(error));
        };
    };

    /// Execute system parameter updates
    private func _executeSystemUpdate(proposalId: Nat, systemUpdate: Types.SystemUpdatePayload, executor: Principal) : async Types.Result<Text, Text> {
        switch (systemUpdate) {
            case (#UpdateSystemParams(params)) {
                await _executeSystemParamsUpdate(proposalId, params, executor);
            };
            
            case (#UpdateTokenConfig(tokenUpdate)) {
                await _executeTokenConfigUpdate(proposalId, tokenUpdate, executor);
            };

            case (#UpdateGovernanceLevel(newLevel)) {
                _executeGovernanceLevelUpdate(proposalId, newLevel, executor);
            };
            
            case (#Emergency(emergencyAction)) {
                await _executeEmergencyAction(proposalId, emergencyAction, executor);
            };
        }
    };

    /// Execute system parameters update
    private func _executeSystemParamsUpdate(proposalId: Nat, params: Types.UpdateSystemParamsPayload, executor: Principal) : async Types.Result<Text, Text> {
        var updateCount = 0;
        let changes = Buffer.Buffer<Text>(0);

        // Update each parameter if provided
        switch (params.transfer_fee) {
            case null { };
            case (?fee) {
                switch (SafeMath.validateAmount(fee, 0, MAX_TOKEN_AMOUNT)) {
                    case (#err(msg)) { return #err("Invalid transfer fee: " # msg) };
                    case (#ok()) {
                        system_params := { system_params with transfer_fee = fee };
                        changes.add("transfer_fee=" # Nat.toText(fee));
                        updateCount += 1;
                    };
                };
            };
        };

        switch (params.proposal_vote_threshold) {
            case null { };
            case (?threshold) {
                switch (SafeMath.validateAmount(threshold, MIN_STAKE_AMOUNT, MAX_STAKE_AMOUNT)) {
                    case (#err(msg)) { return #err("Invalid vote threshold: " # msg) };
                    case (#ok()) {
                        system_params := { system_params with proposal_vote_threshold = threshold };
                        changes.add("proposal_vote_threshold=" # Nat.toText(threshold));
                        updateCount += 1;
                    };
                };
            };
        };

        switch (params.proposal_submission_deposit) {
            case null { };
            case (?deposit) {
                switch (SafeMath.validateAmount(deposit, MIN_PROPOSAL_DEPOSIT, MAX_PROPOSAL_DEPOSIT)) {
                    case (#err(msg)) { return #err("Invalid proposal deposit: " # msg) };
                    case (#ok()) {
                        system_params := { system_params with proposal_submission_deposit = deposit };
                        changes.add("proposal_submission_deposit=" # Nat.toText(deposit));
                        updateCount += 1;
                    };
                };
            };
        };

        switch (params.quorum_percentage) {
            case null { };
            case (?quorum) {
                if (quorum < MIN_QUORUM_PERCENTAGE or quorum > MAX_QUORUM_PERCENTAGE) {
                    return #err("Invalid quorum percentage: " # Nat.toText(quorum));
                };
                system_params := { system_params with quorum_percentage = quorum };
                changes.add("quorum_percentage=" # Nat.toText(quorum));
                updateCount += 1;
            };
        };

        switch (params.approval_threshold) {
            case null { };
            case (?threshold) {
                if (threshold < MIN_APPROVAL_THRESHOLD or threshold > MAX_APPROVAL_THRESHOLD) {
                    return #err("Invalid approval threshold: " # Nat.toText(threshold));
                };
                system_params := { system_params with approval_threshold = threshold };
                changes.add("approval_threshold=" # Nat.toText(threshold));
                updateCount += 1;
            };
        };

        switch (params.timelock_duration) {
            case null { };
            case (?duration) {
                if (duration < MIN_TIMELOCK_DURATION or duration > MAX_TIMELOCK_DURATION) {
                    return #err("Invalid timelock duration: " # Nat.toText(duration));
                };
                system_params := { system_params with timelock_duration = duration };
                changes.add("timelock_duration=" # Nat.toText(duration));
                updateCount += 1;
            };
        };

        if (updateCount == 0) {
            return #err("No parameters to update");
        };

        let changesSummary = Text.join(", ", changes.vals());
        _logSecurityEvent(executor, #ProposalExecution,
            "System parameters updated: " # changesSummary, #High);

        #ok("Updated " # Nat.toText(updateCount) # " parameters: " # changesSummary);
    };

    /// Execute token config update
    private func _executeTokenConfigUpdate(proposalId: Nat, tokenUpdate: Types.TokenConfigUpdate, executor: Principal) : async Types.Result<Text, Text> {
        var updateCount = 0;
        let changes = Buffer.Buffer<Text>(0);

        switch (tokenUpdate.fee) {
            case null { };
            case (?fee) {
                token_config := { token_config with fee = fee };
                changes.add("fee=" # Nat.toText(fee));
                updateCount += 1;
            };
        };

        switch (tokenUpdate.name) {
            case null { };
            case (?name) {
                token_config := { token_config with name = name };
                changes.add("name=" # name);
                updateCount += 1;
            };
        };

        switch (tokenUpdate.symbol) {
            case null { };
            case (?symbol) {
                token_config := { token_config with symbol = symbol };
                changes.add("symbol=" # symbol);
                updateCount += 1;
            };
        };

        switch (tokenUpdate.managedByDAO) {
            case null { };
            case (?managed) {
                token_config := { token_config with managedByDAO = managed };
                changes.add("managedByDAO=" # debug_show(managed));
                updateCount += 1;
            };
        };

        if (updateCount == 0) {
            return #err("No token config to update");
        };

        let changesSummary = Text.join(", ", changes.vals());
        _logSecurityEvent(executor, #ProposalExecution,
            "Token config updated: " # changesSummary, #High);

        #ok("Updated " # Nat.toText(updateCount) # " token settings: " # changesSummary);
    };

    /// Execute emergency actions
    private func _executeEmergencyAction(proposalId: Nat, emergencyAction: Types.EmergencyAction, executor: Principal) : async Types.Result<Text, Text> {
        // Verify executor is emergency contact
        if (Array.find<Principal>(system_params.emergency_contacts, func(contact) = contact == executor) == null) {
            return #err("Only emergency contacts can execute emergency actions");
        };

        switch (emergencyAction) {
            case (#Pause) {
                emergency_state := { emergency_state with 
                    paused = true; 
                    pausedBy = ?executor; 
                    pausedAt = ?Time.now();
                    reason = ?("Emergency pause via proposal " # Nat.toText(proposalId));
                };
                _logSecurityEvent(executor, #EmergencyPause,
                    "DAO paused via proposal " # Nat.toText(proposalId), #Critical);
                #ok("DAO paused successfully");
            };

            case (#Unpause) {
                emergency_state := { emergency_state with 
                    paused = false; 
                    pausedBy = null; 
                    pausedAt = null;
                    reason = null;
                };
                _logSecurityEvent(executor, #EmergencyUnpause,
                    "DAO unpaused via proposal " # Nat.toText(proposalId), #Critical);
                #ok("DAO unpaused successfully");
            };

            case (#EmergencyWithdraw(args)) {
                let ledger = actor(Principal.toText(args.token)) : actor {
                    icrc1_transfer : (ICRC.TransferArgs) -> async ICRC.TransferResult;
                };

                let transactionId = _logTransaction(
                    #Transfer, 
                    Principal.fromActor(Self), 
                    ?args.to, 
                    args.amount, 
                    "Emergency withdrawal via proposal " # Nat.toText(proposalId)
                );

                try {
                    let transferResult = await ledger.icrc1_transfer({
                        from_subaccount = null;
                        to = { owner = args.to; subaccount = null };
                        amount = args.amount;
                        fee = ?system_params.transfer_fee;
                        memo = null;
                        created_at_time = null;
                    });

                    switch (transferResult) {
                        case (#Err(e)) {
                            _updateTransaction(transactionId, null, #Failed("Emergency withdrawal failed: " # debug_show(e)));
                            #err("Emergency withdrawal failed: " # debug_show(e));
                        };
                        case (#Ok(blockIndex)) {
                            _updateTransaction(transactionId, ?blockIndex, #Completed);
                            _logSecurityEvent(executor, #EmergencyPause,
                                "Emergency withdrawal completed: " # Nat.toText(args.amount) # " tokens", #Critical);
                            #ok("Emergency withdrawal completed. Block: " # Nat.toText(blockIndex));
                        };
                    };
                } catch (error) {
                    _updateTransaction(transactionId, null, #Failed("Error: " # Error.message(error)));
                    #err("Emergency withdrawal failed: " # Error.message(error));
                };
            };

            case (#UpdateEmergencyContacts(args)) {
                if (args.contacts.size() > MAX_EMERGENCY_CONTACTS) {
                    return #err("Too many emergency contacts. Max: " # Nat.toText(MAX_EMERGENCY_CONTACTS));
                };

                system_params := { system_params with emergency_contacts = args.contacts };
                _logSecurityEvent(executor, #EmergencyPause,
                    "Emergency contacts updated. New count: " # Nat.toText(args.contacts.size()), #Critical);
                #ok("Emergency contacts updated successfully");
            };
        };
    };

    /// Execute governance level update
    private func _executeGovernanceLevelUpdate(proposalId: Nat, newLevel: Types.GovernanceLevel, executor: Principal) : Types.Result<Text, Text> {
        // Validate upgrade path - can only upgrade, not downgrade (except motionOnly can be changed)
        let currentLevel = governance_level;
        let upgradeValid = switch (currentLevel, newLevel) {
            case (#MotionOnly, #SemiManaged) { true };
            case (#MotionOnly, #FullyManaged) { true };
            case (#SemiManaged, #FullyManaged) { true };
            case (#MotionOnly, #MotionOnly) { false }; // No change
            case (#SemiManaged, #SemiManaged) { false }; // No change
            case (#FullyManaged, #FullyManaged) { false }; // No change
            case _ { false }; // Invalid downgrade
        };

        if (not upgradeValid) {
            let currentText = switch (currentLevel) {
                case (#MotionOnly) { "Motion-Only" };
                case (#SemiManaged) { "Semi-Managed" };
                case (#FullyManaged) { "Fully-Managed" };
            };
            let newText = switch (newLevel) {
                case (#MotionOnly) { "Motion-Only" };
                case (#SemiManaged) { "Semi-Managed" };
                case (#FullyManaged) { "Fully-Managed" };
            };
            return #err("Invalid governance upgrade path from " # currentText # " to " # newText);
        };

        // Update governance level
        governance_level := newLevel;

        // Update managedByDAO flag based on new governance level
        let newManagedByDAO = switch (newLevel) {
            case (#MotionOnly) { false };
            case (#SemiManaged) { true };
            case (#FullyManaged) { true };
        };
        token_config := { token_config with managedByDAO = newManagedByDAO };

        let levelText = switch (newLevel) {
            case (#MotionOnly) { "Motion-Only" };
            case (#SemiManaged) { "Semi-Managed" };
            case (#FullyManaged) { "Fully-Managed" };
        };

        _logSecurityEvent(executor, #ProposalExecution,
            "Governance level upgraded to " # levelText # " via proposal " # Nat.toText(proposalId), #High);

        #ok("Governance level successfully upgraded to " # levelText);
    };

    /// 🔥 FIXED: Submit proposal with proper ICRC2 transferFrom for deposit
    public shared({caller}) func submitProposal(payload: Types.ProposalPayload) : async Types.Result<Nat, Text> {
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #SubmitProposal)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Check voting power threshold
        let userVotingPower = _getVotingPower(caller);
        if (userVotingPower < system_params.proposal_vote_threshold) {
            return #err("Insufficient voting power to submit proposal");
        };

        // Validate governance level permissions
        switch (_validateGovernanceLevel(payload)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Validate proposal content
        switch (_validateProposalPayload(payload)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        let ledger = switch (token_ledger) {
            case null { return #err("Token ledger not initialized") };
            case (?ledger) { ledger };
        };

        let proposal_id = next_proposal_id;
        next_proposal_id += 1;

        // Create transaction log entry for proposal deposit - ESSENTIAL for audit
        let transactionId = _logTransaction(
            #ProposalDeposit, 
            caller, 
            ?Principal.fromActor(Self), 
            system_params.proposal_submission_deposit, 
            "Proposal " # Nat.toText(proposal_id) # " submission deposit"
        );

        // ================ INTERACTIONS FIRST ================
        try {
            // 🔥 CRITICAL FIX: Use icrc2_transfer_from for proposal deposit
            // Frontend must approve the deposit amount first
            let transferArgs : ICRC.TransferFromArgs = {
                spender_subaccount = null;
                from = { owner = caller; subaccount = null };
                to = { owner = Principal.fromActor(Self); subaccount = null };
                amount = system_params.proposal_submission_deposit;
                fee = ?system_params.transfer_fee;
                memo = null;
                created_at_time = null;
            };

            let transferResult = await ledger.icrc2_transfer_from(transferArgs);

            switch (transferResult) {
                case (#Err(e)) {
                    _updateTransaction(transactionId, null, #Failed("ICRC2 transfer failed: " # debug_show(e)));
                    return #err("Deposit transfer failed: " # debug_show(e) # ". Make sure you have approved the deposit amount + fee first.");
                };
                case (#Ok(blockIndex)) {
                    _updateTransaction(transactionId, ?blockIndex, #Completed);

                    // ================ EFFECTS ================
                    let now = Time.now();
                    
                    // 🛡️ TREASURY GOVERNANCE - Use higher thresholds for treasury proposals
                    let (treasuryQuorum, treasuryApproval) = switch (payload) {
                        case (#TokenManage(#Transfer(_))) {
                            // Treasury transfers require higher thresholds for community protection
                            (
                                _calculateTreasuryQuorum(total_voting_power),
                                treasuryConfig.treasuryProposalThreshold
                            );
                        };
                        case (_) {
                            // Standard proposals use normal thresholds
                            (
                                _calculateQuorum(total_voting_power),
                                system_params.approval_threshold
                            );
                        };
                    };
                    
                    let proposal : Types.Proposal = {
                        id = proposal_id;
                        proposer = caller;
                        payload = payload;
                        state = #Open;
                        votes_yes = 0;
                        votes_no = 0;
                        voters = List.nil();
                        timestamp = now;
                        executionTime = null;
                        quorumRequired = treasuryQuorum;
                        approvalThreshold = treasuryApproval;
                    };

                    proposals := Trie.put(proposals, Types.proposal_key(proposal_id), Nat.equal, proposal).0;

                    // Schedule voting end timer - REPLACES HEARTBEAT SYSTEM
                    let votingEndTime = proposal.timestamp + Int.abs(system_params.max_voting_period * 1_000_000_000);
                    await _scheduleProposalTimer(proposal_id, #VotingEnd, votingEndTime);

                    _logSecurityEvent(caller, #SuspiciousActivity,
                        "Submitted proposal " # Nat.toText(proposal_id) # " (Block: " # Nat.toText(blockIndex) # ")", #Medium);
                    
                    return #ok(proposal_id);
                };
            };

        } catch (error) {
            _updateTransaction(transactionId, null, #Failed("Error: " # Error.message(error)));
            return #err("Proposal submission failed: " # Error.message(error));
        };
    };

    /// Create composite key for vote records
    private func _makeVoteKey(proposalId: Nat, voter: Principal) : Trie.Key<Text> {
        let compositeKey = Nat.toText(proposalId) # ":" # Principal.toText(voter);
        { key = compositeKey; hash = Text.hash(compositeKey) }
    };

    /// Vote on a proposal
    public shared({caller}) func vote(args: Types.VoteArgs) : async Types.Result<(), Text> {
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #Vote)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Get proposal
        let proposal = switch (Trie.get(proposals, Types.proposal_key(args.proposal_id), Nat.equal)) {
            case null { return #err("Proposal not found") };
            case (?proposal) { proposal };
        };

        // Validate proposal state and timing
        if (proposal.state != #Open) {
            return #err("Proposal is not open for voting");
        };

        let now = Time.now();
        let votingEndTime = proposal.timestamp + Int.abs(system_params.max_voting_period * 1_000_000_000);
        if (now >= votingEndTime) {
            return #err("Voting period has ended");
        };

        // Get voter's voting power
        let votingPower = _getVotingPower(caller);
        if (votingPower == 0) {
            return #err("No voting power - you need to stake tokens first");
        };

        // Check if already voted  
        let voteKey = _makeVoteKey(args.proposal_id, caller);
        switch (Trie.get(vote_records_trie, voteKey, Text.equal)) {
            case (?existingRecord) {
                return #err("You have already voted on this proposal");
            };
            case null {};
        };

        // ================ EFFECTS ================
        
        // Create vote record
        let voteRecord : Types.VoteRecord = {
            voter = caller;
            vote = args.vote;
            votingPower = votingPower;
            timestamp = now;
            reason = args.reason;
        };

        // Store vote record
        vote_records_trie := Trie.put(vote_records_trie, voteKey, Text.equal, voteRecord).0;

        // Update proposal vote counts
        let updatedProposal = switch (args.vote) {
            case (#yes) {
                {
                    proposal with 
                    votes_yes = proposal.votes_yes + votingPower;
                    voters = List.push(caller, proposal.voters);
                }
            };
            case (#no) {
                {
                    proposal with 
                    votes_no = proposal.votes_no + votingPower;
                    voters = List.push(caller, proposal.voters);
                }
            };
            case (#abstain) {
                // Abstain votes are not counted but the voter is registered
                {
                    proposal with 
                    voters = List.push(caller, proposal.voters);
                }
            };
        };

        proposals := Trie.put(proposals, Types.proposal_key(args.proposal_id), Nat.equal, updatedProposal).0;

        // Log vote
        let _reason = switch (args.reason) { case (?r) r; case null "" };
        let voteDescription = "Voted " # debug_show(args.vote) # " on proposal " # Nat.toText(args.proposal_id) # 
            " with " # Nat.toText(votingPower) # " voting power" #
            " (Reason: " # _reason # ")";
            
        // Vote activity is not considered a security event - removing security log

        #ok()
    };

    /// Get proposal information
    public query func getProposal(proposalId: Nat) : async ?Types.Proposal {
        Trie.get(proposals, Types.proposal_key(proposalId), Nat.equal)
    };

    /// List proposals with pagination
    public query func listProposals(offset: Nat, limit: Nat) : async [Types.Proposal] {
        let allProposals = Iter.toArray(Iter.map(Trie.iter(proposals), func((k, v): (Nat, Types.Proposal)) : Types.Proposal = v));
        
        let sorted = Array.sort(allProposals, func(a: Types.Proposal, b: Types.Proposal) : {#less; #equal; #greater} {
            if (a.timestamp > b.timestamp) #less else if (a.timestamp < b.timestamp) #greater else #equal
        });
        
        let totalProposals = sorted.size();
        if (offset >= totalProposals) {
            return [];
        };
        
        let endIndex = Nat.min(offset + limit, totalProposals);
        Array.tabulate(Nat.sub(endIndex, offset), func (i : Nat) : Types.Proposal = sorted[offset + i])
    };

    /// Get user's vote on a proposal
    public query func getUserVote(proposalId: Nat, user: Principal) : async ?Types.VoteRecord {
        let voteKey = _makeVoteKey(proposalId, user);
        Trie.get(vote_records_trie, voteKey, Text.equal)
    };

    /// Get all vote records for a proposal
    public query func getProposalVotes(proposalId: Nat) : async [Types.VoteRecord] {
        let votesBuffer = Buffer.Buffer<Types.VoteRecord>(0);
        
        for ((key, voteRecord) in Trie.iter(vote_records_trie)) {
            // Parse composite key to extract proposalId
            let parts = Text.split(key, #char(':'));
            switch (parts.next()) {
                case (?proposalIdText) {
                    switch (Nat.fromText(proposalIdText)) {
                        case (?pid) {
                            if (pid == proposalId) {
                                votesBuffer.add(voteRecord);
                            };
                        };
                        case null { /* Skip invalid key */ };
                    };
                };
                case null { /* Skip invalid key */ };
            };
        };
        
        Buffer.toArray(votesBuffer)
    };

    /// Get DAO statistics
    public query func getDAOStats() : async Types.DAOStats {
        let totalProposals = Trie.size(proposals);
        let activeProposals = Array.foldLeft(
            Iter.toArray(Iter.map(Trie.iter(proposals), func((k, v): (Nat, Types.Proposal)) : Types.Proposal = v)),
            0,
            func(acc: Nat, proposal: Types.Proposal) : Nat {
                if (proposal.state == #Open) acc + 1 else acc
            }
        );

        {
            totalMembers = Trie.size(stakes);
            totalProposals = totalProposals;
            activeProposals = activeProposals;
            totalStaked = total_staked;
            totalVotingPower = total_voting_power;
            tokenInfo = token_config;
            treasuryBalance = 0; // TODO: Calculate actual treasury balance
        }
    };

    /// Get system parameters
    public query func getSystemParams() : async Types.SystemParams {
        system_params
    };

    /// Get token configuration
    public query func getTokenConfig() : async Types.TokenConfig {
        token_config
    };

    // Get governance level
    public query func getGovernanceLevel() : async Types.GovernanceLevel {
        governance_level
    };

    // Get all DAOs info
    public query func getDAOsInfo() : async {
        systemParams: Types.SystemParams;
        tokenConfig: Types.TokenConfig;
        governanceLevel: Types.GovernanceLevel;
        stakingEnabled: Bool;
        totalMembers: Nat;
        totalStaked: Nat;
        totalVotingPower: Nat;
    } {
        {
            systemParams = system_params;
            tokenConfig = token_config;
            governanceLevel = governance_level;
            stakingEnabled = Trie.size(multiplierTiers) > 0;
            totalMembers = Trie.size(stakes);
            totalStaked = total_staked;
            totalVotingPower = total_voting_power;
        }
    };

    /// Get detailed proposal information
    public query func getProposalInfo(proposalId: Nat) : async ?Types.ProposalInfo {
        switch (Trie.find(proposals, Types.proposal_key(proposalId), Nat.equal)) {
            case (?proposal) {
                // Count votes by type
                var yesVotes : Nat = 0;
                var noVotes : Nat = 0;
                var abstainVotes : Nat = 0;
                var totalVotes : Nat = 0;
                
                for ((key, voteRecord) in Trie.iter(vote_records_trie)) {
                    // Parse composite key to extract proposalId
                    let parts = Text.split(key, #char(':'));
                    switch (parts.next()) {
                        case (?proposalIdText) {
                            switch (Nat.fromText(proposalIdText)) {
                                case (?pid) {
                                    if (pid == proposalId) {
                                        let votingPower = voteRecord.votingPower;
                                        totalVotes += votingPower;
                                        switch (voteRecord.vote) {
                                            case (#yes) { yesVotes += votingPower };
                                            case (#no) { noVotes += votingPower };
                                            case (#abstain) { abstainVotes += votingPower };
                                        };
                                    };
                                };
                                case null { /* Skip invalid key */ };
                            };
                        };
                        case null { /* Skip invalid key */ };
                    };
                };
                
                // Calculate quorum and threshold
                let quorumRequired = (total_voting_power * system_params.quorum_percentage) / 10000;
                let quorumMet = totalVotes >= quorumRequired;
                let thresholdMet = totalVotes > 0 and (yesVotes * 10000) / totalVotes >= system_params.approval_threshold;
                
                // Calculate time remaining
                let now = Time.now();
                let votingEndTime = proposal.timestamp + Int.abs(system_params.max_voting_period * 1_000_000_000);
                let timeRemaining = if (now < votingEndTime) { ?(Int.abs(votingEndTime - now) / 1_000_000_000) } else { null };
                
                // Calculate time to execution (if in timelock)
                let timeToExecution = switch (proposal.state) {
                    case (#Timelock) {
                        switch (proposal.executionTime) {
                            case (?execTime) {
                                if (now < execTime) { ?(Int.abs(execTime - now) / 1_000_000_000) } else { ?0 };
                            };
                            case null { null };
                        };
                    };
                    case _ { null };
                };
                
                ?{
                    proposal = proposal;
                    votesDetails = {
                        totalVotes = totalVotes;
                        yesVotes = yesVotes;
                        noVotes = noVotes;
                        abstainVotes = abstainVotes;
                        quorumMet = quorumMet;
                        thresholdMet = thresholdMet;
                    };
                    timeRemaining = timeRemaining;
                    timeToExecution = timeToExecution;
                }
            };
            case null { null };
        }
    };

    /// Get member information
    public query func getMemberInfo(member: Principal) : async ?Types.MemberInfo {
        let stakeRecord = Trie.find(stakes, Types.stake_key(member), Principal.equal);
        
        switch (stakeRecord) {
            case (?stake) {
                // Count proposals created by member
                var proposalsCreated : Nat = 0;
                for ((id, proposal) in Trie.iter(proposals)) {
                    if (proposal.proposer == member) {
                        proposalsCreated += 1;
                    };
                };
                
                // Count proposals voted on by member
                var proposalsVoted : Nat = 0;
                for ((key, voteRecord) in Trie.iter(vote_records_trie)) {
                    if (voteRecord.voter == member) {
                        proposalsVoted += 1;
                    };
                };
                
                // Get delegated from amount
                var delegatedFrom : Nat = 0;
                for ((delegator, delegation) in Trie.iter(delegations)) {
                    if (delegation.delegate == member) {
                        delegatedFrom += delegation.votingPower;
                    };
                };
                
                ?{
                    stakedAmount = stake.amount;
                    votingPower = stake.votingPower;
                    delegatedTo = null; // TODO: Implement delegation tracking in StakeRecord
                    delegatedFrom = delegatedFrom;
                    proposalsCreated = proposalsCreated;
                    proposalsVoted = proposalsVoted;
                    joinedAt = stake.stakedAt; // Use stakedAt instead of timestamp
                }
            };
            case null { null };
        }
    };

    // ================ TRANSACTION QUERY FUNCTIONS - ESSENTIAL FOR AUDIT ================
    
    /// Get user transactions for audit trail and compliance
    public query func getUserTransactions(user: Principal, offset: Nat, limit: Nat) : async [Transaction] {
        let userTransactions = Buffer.Buffer<Transaction>(0);
        
        for ((_, transaction) in Trie.iter(transactions_trie)) {
            if (transaction.from == user or (switch (transaction.to) { case (?to) to == user; case null false })) {
                userTransactions.add(transaction);
            };
        };
        
        let sorted = Array.sort(Buffer.toArray(userTransactions), func(a: Transaction, b: Transaction) : {#less; #equal; #greater} {
            if (a.timestamp > b.timestamp) #less else if (a.timestamp < b.timestamp) #greater else #equal
        });
        
        let totalTransactions = sorted.size();
        if (offset >= totalTransactions) {
            return [];
        };
        
        let endIndex = Nat.min(offset + limit, totalTransactions);
        Array.tabulate(Nat.sub(endIndex, offset), func (i : Nat) : Transaction = sorted[offset + i])
    };
    
    /// Get all transactions (admin/auditor only)
    public query func getAllTransactions(offset: Nat, limit: Nat) : async [Transaction] {
        let allTransactions = Iter.toArray(Iter.map(Trie.iter(transactions_trie), func((k, v): (Nat, Transaction)) : Transaction = v));
        
        let sorted = Array.sort(allTransactions, func(a: Transaction, b: Transaction) : {#less; #equal; #greater} {
            if (a.timestamp > b.timestamp) #less else if (a.timestamp < b.timestamp) #greater else #equal
        });
        
        let totalTransactions = sorted.size();
        if (offset >= totalTransactions) {
            return [];
        };
        
        let endIndex = Nat.min(offset + limit, totalTransactions);
        Array.tabulate(Nat.sub(endIndex, offset), func (i : Nat) : Transaction = sorted[offset + i])
    };

    // ================ SECURITY AND UTILITY FUNCTIONS ================
    
    /// Calculate quorum based on total voting power
    func _calculateQuorum(totalVotingPower: Nat) : Nat {
        (totalVotingPower * system_params.quorum_percentage) / BASIS_POINTS
    };
    
    /// Calculate higher quorum requirement for treasury proposals (community protection)
    func _calculateTreasuryQuorum(totalVotingPower: Nat) : Nat {
        (totalVotingPower * treasuryConfig.treasuryQuorumPercentage) / BASIS_POINTS
    };
    
    /// Get voting power for a principal (including delegated power)
    func _getVotingPower(principal: Principal) : Nat {
        _getEffectiveVotingPower(principal)
    };

    /// Validate if proposal type is allowed by governance level
    func _validateGovernanceLevel(payload: Types.ProposalPayload) : Types.Result<(), Text> {
        switch (governance_level, payload) {
            case (#MotionOnly, #Motion(_)) { #ok() };
            case (#MotionOnly, #SystemUpdate(systemUpdate)) {
                // Motion-only DAOs can only do governance level upgrades and voting parameter updates
                switch (systemUpdate) {
                    case (#UpdateGovernanceLevel(_)) { #ok() };
                    case (#UpdateSystemParams(_)) { #ok() };
                    case (_) { #err("Motion-only DAOs can only update governance level and voting parameters") };
                };
            };
            case (#MotionOnly, _) { 
                #err("Motion-only DAO can only submit Motion and SystemUpdate proposals") 
            };
            
            case (#SemiManaged, #Motion(_)) { #ok() };
            case (#SemiManaged, #TokenManage(tokenAction)) {
                switch (tokenAction) {
                    case (#Transfer(_)) { #ok() }; // Can transfer from treasury
                    case (_) { #err("Semi-managed DAOs cannot mint or burn tokens") };
                };
            };
            case (#SemiManaged, #SystemUpdate(_)) { #ok() }; // Can upgrade to fully managed
            case (#SemiManaged, #CallExternal(_)) { #err("Semi-managed DAOs cannot call external contracts") };
            
            case (#FullyManaged, _) { #ok() }; // Can do everything
        };
    };
    
    /// Validate proposal payload for security - ENHANCED for all proposal types
    func _validateProposalPayload(payload: Types.ProposalPayload) : Types.Result<(), Text> {
        switch (payload) {
            case (#Motion(motion)) {
                // Validate motion content
                if (motion.title.size() == 0) {
                    return #err("Motion title cannot be empty");
                };
                if (motion.title.size() > 200) {
                    return #err("Motion title too long (max 200 characters)");
                };
                if (motion.description.size() == 0) {
                    return #err("Motion description cannot be empty");
                };
                if (motion.description.size() > 10000) {
                    return #err("Motion description too long (max 10000 characters)");
                };
                #ok()
            };
            
            case (#TokenManage(tokenAction)) {
                switch (tokenAction) {
                    case (#Transfer(args)) {
                        switch (SafeMath.validateAmount(args.amount, 1, MAX_TOKEN_AMOUNT)) {
                            case (#err(msg)) { #err("Invalid transfer amount: " # msg) };
                            case (#ok()) {
                                // Validate recipient is not zero principal
                                if (Principal.toText(args.to).size() == 0) {
                                    #err("Invalid recipient principal");
                                } else {
                                    #ok();
                                };
                            };
                        };
                    };
                    case (#Burn(args)) {
                        if (not token_config.managedByDAO) {
                            #err("DAO does not have token management permissions");
                        } else {
                            SafeMath.validateAmount(args.amount, 1, MAX_TOKEN_AMOUNT);
                        };
                    };
                    case (#Mint(args)) {
                        if (not token_config.managedByDAO) {
                            #err("DAO does not have token management permissions");
                        } else {
                            switch (SafeMath.validateAmount(args.amount, 1, MAX_TOKEN_AMOUNT)) {
                                case (#err(msg)) { #err("Invalid mint amount: " # msg) };
                                case (#ok()) {
                                    if (Principal.toText(args.to).size() == 0) {
                                        #err("Invalid mint recipient principal");
                                    } else {
                                        #ok();
                                    };
                                };
                            };
                        };
                    };
                    case (#UpdateMetadata(args)) {
                        if (not token_config.managedByDAO) {
                            #err("DAO does not have token management permissions");
                        } else if (args.key.size() == 0) {
                            #err("Metadata key cannot be empty");
                        } else if (args.key.size() > 100) {
                            #err("Metadata key too long (max 100 characters)");
                        } else if (args.value.size() > 1000) {
                            #err("Metadata value too long (max 1000 characters)");
                        } else {
                            #ok();
                        };
                    };
                }
            };
            
            case (#CallExternal(externalCall)) {
                // Validate external call parameters
                if (externalCall.target == Principal.fromActor(Self)) {
                    #err("Cannot call self via external call");
                } else if (externalCall.method.size() == 0) {
                    #err("Method name cannot be empty");
                } else if (externalCall.method.size() > 100) {
                    #err("Method name too long (max 100 characters)");
                } else if (externalCall.description.size() == 0) {
                    #err("External call description cannot be empty");
                } else if (externalCall.description.size() > 1000) {
                    #err("External call description too long (max 1000 characters)");
                } else if (externalCall.args.size() > 1_000_000) { // 1MB limit
                    #err("External call arguments too large (max 1MB)");
                } else {
                    // Security check for sensitive canisters
                    let targetText = Principal.toText(externalCall.target);
                    if (targetText == "rdmx6-jaaaa-aaaah-qdrva-cai" or // IC Management Canister
                        targetText == "rrkah-fqaaa-aaaah-qcuwa-cai" or // NNS Registry  
                        targetText == "rno2w-sqaaa-aaaah-qcuwa-cai") { // NNS Root
                        #err("Cannot call sensitive system canisters");
                    } else {
                        #ok();
                    };
                };
            };
            
            case (#SystemUpdate(systemUpdate)) {
                switch (systemUpdate) {
                    case (#UpdateSystemParams(params)) {
                        // Validate system parameter updates
                        _validateSystemParamsUpdate(params);
                    };
                    case (#UpdateTokenConfig(tokenUpdate)) {
                        // Validate token config updates
                        _validateTokenConfigUpdate(tokenUpdate);
                    };
                    case (#UpdateGovernanceLevel(newLevel)) {
                        // Validate governance level upgrade is allowed
                        let currentLevel = governance_level;
                        switch (currentLevel, newLevel) {
                            case (#MotionOnly, #SemiManaged) { #ok() };
                            case (#MotionOnly, #FullyManaged) { #ok() };
                            case (#SemiManaged, #FullyManaged) { #ok() };
                            case (#MotionOnly, #MotionOnly) { #err("No governance level change specified") };
                            case (#SemiManaged, #SemiManaged) { #err("No governance level change specified") };
                            case (#FullyManaged, #FullyManaged) { #err("No governance level change specified") };
                            case _ { #err("Invalid governance upgrade path") };
                        };
                    };
                    case (#Emergency(emergencyAction)) {
                        // Validate emergency actions
                        _validateEmergencyAction(emergencyAction);
                    };
                }
            };
        }
    };

    /// Validate system parameters update
    func _validateSystemParamsUpdate(params: Types.UpdateSystemParamsPayload) : Types.Result<(), Text> {
        switch (params.transfer_fee) {
            case null { };
            case (?fee) {
                switch (SafeMath.validateAmount(fee, 0, MAX_TOKEN_AMOUNT)) {
                    case (#err(msg)) { return #err("Invalid transfer fee: " # msg) };
                    case (#ok()) { };
                };
            };
        };

        switch (params.proposal_vote_threshold) {
            case null { };
            case (?threshold) {
                switch (SafeMath.validateAmount(threshold, MIN_STAKE_AMOUNT, MAX_STAKE_AMOUNT)) {
                    case (#err(msg)) { return #err("Invalid vote threshold: " # msg) };
                    case (#ok()) { };
                };
            };
        };

        switch (params.proposal_submission_deposit) {
            case null { };
            case (?deposit) {
                switch (SafeMath.validateAmount(deposit, MIN_PROPOSAL_DEPOSIT, MAX_PROPOSAL_DEPOSIT)) {
                    case (#err(msg)) { return #err("Invalid proposal deposit: " # msg) };
                    case (#ok()) { };
                };
            };
        };

        switch (params.quorum_percentage) {
            case null { };
            case (?quorum) {
                if (quorum < MIN_QUORUM_PERCENTAGE or quorum > MAX_QUORUM_PERCENTAGE) {
                    return #err("Invalid quorum percentage: " # Nat.toText(quorum));
                };
            };
        };

        switch (params.approval_threshold) {
            case null { };
            case (?threshold) {
                if (threshold < MIN_APPROVAL_THRESHOLD or threshold > MAX_APPROVAL_THRESHOLD) {
                    return #err("Invalid approval threshold: " # Nat.toText(threshold));
                };
            };
        };

        switch (params.timelock_duration) {
            case null { };
            case (?duration) {
                if (duration < MIN_TIMELOCK_DURATION or duration > MAX_TIMELOCK_DURATION) {
                    return #err("Invalid timelock duration: " # Nat.toText(duration));
                };
            };
        };

        #ok()
    };

    /// Validate token config update
    func _validateTokenConfigUpdate(tokenUpdate: Types.TokenConfigUpdate) : Types.Result<(), Text> {
        switch (tokenUpdate.name) {
            case null { };
            case (?name) {
                if (name.size() == 0) {
                    return #err("Token name cannot be empty");
                };
                if (name.size() > 100) {
                    return #err("Token name too long (max 100 characters)");
                };
            };
        };

        switch (tokenUpdate.symbol) {
            case null { };
            case (?symbol) {
                if (symbol.size() == 0) {
                    return #err("Token symbol cannot be empty");
                };
                if (symbol.size() > 10) {
                    return #err("Token symbol too long (max 10 characters)");
                };
            };
        };

        #ok()
    };

    /// Validate emergency action
    func _validateEmergencyAction(emergencyAction: Types.EmergencyAction) : Types.Result<(), Text> {
        switch (emergencyAction) {
            case (#EmergencyWithdraw(args)) {
                switch (SafeMath.validateAmount(args.amount, 1, MAX_TOKEN_AMOUNT)) {
                    case (#err(msg)) { #err("Invalid withdrawal amount: " # msg) };
                    case (#ok()) {
                        if (Principal.toText(args.to).size() == 0) {
                            #err("Invalid withdrawal recipient");
                        } else {
                            #ok();
                        };
                    };
                };
            };
            case (#UpdateEmergencyContacts(args)) {
                if (args.contacts.size() == 0) {
                    #err("Emergency contacts list cannot be empty");
                } else if (args.contacts.size() > MAX_EMERGENCY_CONTACTS) {
                    #err("Too many emergency contacts. Max: " # Nat.toText(MAX_EMERGENCY_CONTACTS));
                } else {
                    // Check for duplicates
                    let uniqueContacts = Array.foldLeft<Principal, [Principal]>(args.contacts, [], func(acc, contact) {
                        if (Array.find<Principal>(acc, func(c) = c == contact) == null) {
                            Array.append(acc, [contact])
                        } else {
                            acc
                        }
                    });
                    if (uniqueContacts.size() != args.contacts.size()) {
                        #err("Duplicate emergency contacts not allowed");
                    } else {
                        #ok();
                    };
                };
            };
            case (#Pause) { #ok() };
            case (#Unpause) { #ok() };
        }
    };

    /// Rate limiting to prevent spam attacks
    func _checkRateLimit(caller: Principal, action: ActionType) : Types.Result<(), Text> {
        let now = Time.now();
        let key = Types.stake_key(caller);
        
        let currentRecord = switch (Trie.get(rate_limits_trie, key, Principal.equal)) {
            case null {
                {
                    timestamps = [];
                    dailyCount = 0;
                    lastReset = now;
                };
            };
            case (?record) { record };
        };
        
        // Get limits based on action type
        let hourlyLimit = switch (action) {
            case (#SubmitProposal) { MAX_PROPOSALS_PER_HOUR };
            case (#Vote) { MAX_VOTES_PER_HOUR };
            case (_) { 100 }; // Default high limit for other actions
        };
        
        let dailyLimit = switch (action) {
            case (#SubmitProposal) { MAX_PROPOSALS_PER_DAY };
            case (_) { 1000 }; // Default high limit
        };
        
        // Reset daily count if day has passed
        let dayInNanoseconds = 24 * 60 * 60 * 1_000_000_000;
        let needsReset = now - currentRecord.lastReset > dayInNanoseconds;
        let updatedRecord = if (needsReset) {
            {
                timestamps = [now];
                dailyCount = 1;
                lastReset = now;
            }
        } else {
            // Filter recent timestamps (last hour)
            let hourInNanoseconds = 60 * 60 * 1_000_000_000;
            let recentTimestamps = Array.filter(currentRecord.timestamps, func(t: Time.Time) : Bool {
                now - t <= hourInNanoseconds
            });
            
            // Check hourly limit
            if (recentTimestamps.size() >= hourlyLimit) {
                _logSecurityEvent(caller, #SuspiciousActivity,
                    "Hourly rate limit exceeded for " # debug_show(action), #Medium);
                return #err("Hourly rate limit exceeded");
            };
            
            // Check daily limit
            if (currentRecord.dailyCount >= dailyLimit) {
                _logSecurityEvent(caller, #SuspiciousActivity,
                    "Daily rate limit exceeded for " # debug_show(action), #High);
                return #err("Daily rate limit exceeded");
            };
            
            // Update record with new timestamp
            {
                timestamps = Array.append(recentTimestamps, [now]);
                dailyCount = currentRecord.dailyCount + 1;
                lastReset = currentRecord.lastReset;
            }
        };
        
        rate_limits_trie := Trie.put(rate_limits_trie, key, Principal.equal, updatedRecord).0;
        
        #ok()
    };

    /// Log security events for monitoring
    func _logSecurityEvent(principal: Principal, eventType: Types.SecurityEventType, description: Text, severity: Types.SecuritySeverity) {
        let event : Types.SecurityEvent = {
            principal = principal;
            eventType = eventType;
            details = description;
            severity = severity;
            timestamp = Time.now();
        };
        
        security_events_stable := Array.append(security_events_stable, [event]);
        
        // Keep only recent events to prevent unbounded growth
        if (security_events_stable.size() > 10000) {
            let recent = Array.tabulate<Types.SecurityEvent>(5000, func(i) {
                security_events_stable[security_events_stable.size() - 5000 + i]
            });
            security_events_stable := recent;
        };
        
        // Log critical events immediately
        if (severity == #High) {
            Debug.print("SECURITY ALERT: " # debug_show(eventType) # " - " # description);
        };
    };

    /// Handle delegation timer expiry
    private func _handleDelegationTimer(delegator: Principal) : async () {
        switch (Trie.get(delegations, Types.stake_key(delegator), Principal.equal)) {
            case null { return };
            case (?delegation) {
                if (delegation.effectiveAt <= Time.now()) {
                    // Delegation is now effective, no timer action needed
                    return;
                };
            };
        };
        
        // Cleanup timer
        let key = Types.stake_key(delegator);
        delegation_timers_trie := Trie.remove(delegation_timers_trie, key, Principal.equal).0;
        delegation_timer_ids := Trie.remove(delegation_timer_ids, key, Principal.equal).0;
    };

    /// Security validation check
    func _performSecurityValidation() {
        last_security_check := Time.now();
        
        // Check for anomalies in voting power distribution
        if (total_voting_power > MAX_TOKEN_AMOUNT) {
            _logSecurityEvent(Principal.fromActor(Self), #SuspiciousActivity,
                "Total voting power exceeds maximum: " # Nat.toText(total_voting_power), #High);
        };
        
        // Additional security checks can be added here
    };

    // ================ PUBLIC QUERY FUNCTIONS ================
    
    /// Get stake information for security analysis
    public query func getUserStakeInfo(user: Principal) : async ?{
        amount: Nat;
        votingPower: Nat;
        lockDuration: Nat;
        unlockTime: Time.Time;
        isLocked: Bool;
    } {
        switch (Trie.get(stakes, Types.stake_key(user), Principal.equal)) {
            case null { null };
            case (?stake) {
                let now = Time.now();
                ?{
                    amount = stake.amount;
                    votingPower = stake.votingPower;
                    lockDuration = switch (stake.unlockTime) {
                        case null { 0 };
                        case (?unlock) { Int.abs(unlock - stake.stakedAt) / 1_000_000_000 }; // Convert to seconds
                    };
                    unlockTime = switch (stake.unlockTime) {
                        case null { now };
                        case (?unlock) { unlock };
                    };
                    isLocked = switch (stake.unlockTime) {
                        case null { false };
                        case (?unlock) { now < unlock };
                    };
                }
            };
        }
    };
    
    /// Get security statistics including transaction count
    public query func getSecurityStats() : async {
        totalStaked: Nat;
        totalVotingPower: Nat;
        activeProposals: Nat;
        securityEvents: Nat;
        transactions: Nat;
        lastSecurityCheck: Time.Time;
    } {
        let activeProposals = Trie.size(proposals);
        {
            totalStaked = total_staked;
            totalVotingPower = total_voting_power;
            activeProposals = activeProposals;
            securityEvents = security_events_stable.size();
            transactions = Trie.size(transactions_trie); // NEW: Transaction count
            lastSecurityCheck = last_security_check;
        }
    };

    /// Health check for monitoring
    public query func healthCheck() : async Bool {
        not emergency_state.paused and
        Cycles.balance() > MIN_CYCLES_FOR_OPERATION and
        Time.now() - last_security_check < (24 * 60 * 60 * 1_000_000_000) // 24 hours
    };

    // ================ COMMENT SYSTEM ================
    
    /// Get all comments for a proposal
    public query func getProposalComments(proposalId: Nat) : async [Types.ProposalComment] {
        let buffer = Buffer.Buffer<Types.ProposalComment>(0);
        
        for ((id, comment) in Trie.iter(comments)) {
            if (comment.proposalId == proposalId) {
                buffer.add(comment);
            };
        };
        
        // Sort by creation time (oldest first)
        let commentsArray = Buffer.toArray(buffer);
        Array.sort(commentsArray, func (a: Types.ProposalComment, b: Types.ProposalComment) : {#less; #equal; #greater} {
            if (a.createdAt < b.createdAt) { #less }
            else if (a.createdAt > b.createdAt) { #greater }
            else { #equal }
        })
    };
    
    /// Create a new comment on a proposal
    public shared({caller}) func createComment(proposalId: Nat, content: Text) : async Types.Result<Text, Text> {
        // Validate input
        if (content.size() == 0 or content.size() > 500) {
            return #err("Comment content must be between 1 and 500 characters");
        };
        
        // Check if proposal exists
        switch (Trie.get(proposals, Types.proposal_key(proposalId), Nat.equal)) {
            case null { return #err("Proposal not found") };
            case (?_) { /* Continue */ };
        };
        
        // Generate comment ID
        let commentId = "comment_" # Nat.toText(next_comment_id) # "_" # Int.toText(Time.now());
        next_comment_id += 1;
        
        // Get caller's voting power and staker status
        let memberStake = Trie.get(stakes, Types.stake_key(caller), Principal.equal);
        let (votingPower, isStaker) = switch (memberStake) {
            case null { (null, false) };
            case (?stake) { (?stake.votingPower, true) };
        };
        
        // Create comment record
        let comment: Types.ProposalComment = {
            id = commentId;
            proposalId = proposalId;
            author = caller;
            content = content;
            createdAt = Time.now();
            updatedAt = null;
            isEdited = false;
            votingPower = votingPower;
            isStaker = isStaker;
        };
        
        // Store comment
        comments := Trie.put(comments, Types.comment_key(commentId), Text.equal, comment).0;
        
        #ok(commentId)
    };
    
    /// Update an existing comment (only by author)
    public shared({caller}) func updateComment(commentId: Text, content: Text) : async Types.Result<(), Text> {
        // Validate input
        if (content.size() == 0 or content.size() > 500) {
            return #err("Comment content must be between 1 and 500 characters");
        };
        
        // Get existing comment
        switch (Trie.get(comments, Types.comment_key(commentId), Text.equal)) {
            case null { return #err("Comment not found") };
            case (?comment) {
                // Check if caller is the author
                if (comment.author != caller) {
                    return #err("Only the author can edit this comment");
                };
                
                // Update comment
                let updatedComment: Types.ProposalComment = {
                    id = comment.id;
                    proposalId = comment.proposalId;
                    author = comment.author;
                    content = content;
                    createdAt = comment.createdAt;
                    updatedAt = ?Time.now();
                    isEdited = true;
                    votingPower = comment.votingPower;
                    isStaker = comment.isStaker;
                };
                
                comments := Trie.put(comments, Types.comment_key(commentId), Text.equal, updatedComment).0;
                #ok()
            };
        }
    };
    
    /// Delete a comment (only by author)
    public shared({caller}) func deleteComment(commentId: Text) : async Types.Result<(), Text> {
        // Get existing comment
        switch (Trie.get(comments, Types.comment_key(commentId), Text.equal)) {
            case null { return #err("Comment not found") };
            case (?comment) {
                // Check if caller is the author
                if (comment.author != caller) {
                    return #err("Only the author can delete this comment");
                };
                
                // Delete comment
                comments := Trie.remove(comments, Types.comment_key(commentId), Text.equal).0;
                #ok()
            };
        }
    };

    // ================ DELEGATION SYSTEM ================
    
    /// Delegate voting power to another principal
    public shared({caller}) func delegate(delegate: Principal) : async Types.Result<(), Text> {
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #Delegate)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Can't delegate to self
        if (caller == delegate) {
            return #err("Cannot delegate to yourself");
        };

        // Check if caller has stake
        let stakeRecord = switch (Trie.get(stakes, Types.stake_key(caller), Principal.equal)) {
            case null { return #err("You must stake tokens before delegating") };
            case (?stake) { stake };
        };

        // Check if delegate exists (has stake)
        switch (Trie.get(stakes, Types.stake_key(delegate), Principal.equal)) {
            case null { return #err("Delegate must be a DAO member (have staked tokens)") };
            case (?_) { /* Valid delegate */ };
        };

        // Check for delegation chain length to prevent infinite loops
        let chainLength = _calculateDelegationChainLength(delegate, 0);
        if (chainLength >= MAX_DELEGATION_CHAIN_LENGTH) {
            return #err("Delegation chain too long. Maximum length: " # Nat.toText(MAX_DELEGATION_CHAIN_LENGTH));
        };

        let now = Time.now();
        let effectiveTime = now + DELEGATION_TIMELOCK; // 24 hour timelock

        // Create delegation record
        let delegationRecord: Types.DelegationRecord = {
            delegator = caller;
            delegate = delegate;
            votingPower = stakeRecord.votingPower;
            delegatedAt = now;
            effectiveAt = effectiveTime;
            revokable = true;
        };

        // Remove existing delegation if any
        delegations := Trie.remove(delegations, Types.stake_key(caller), Principal.equal).0;
        
        // Store new delegation
        delegations := Trie.put(delegations, Types.stake_key(caller), Principal.equal, delegationRecord).0;

        // Schedule timer for delegation to become effective
        let timerId = Timer.setTimer<system>(#nanoseconds(Int.abs(effectiveTime - now)), func() : async () {
            await _handleDelegationTimer(caller);
        });

        let delegationTimer: Types.DelegationTimer = {
            delegator = caller;
            scheduledTime = effectiveTime;
            createdAt = now;
            remainingTime = effectiveTime - now;
        };

        delegation_timers_trie := Trie.put(delegation_timers_trie, Types.stake_key(caller), Principal.equal, delegationTimer).0;
        delegation_timer_ids := Trie.put(delegation_timer_ids, Types.stake_key(caller), Principal.equal, timerId).0;

        _logSecurityEvent(caller, #SuspiciousActivity,
            "Delegated " # Nat.toText(stakeRecord.votingPower) # " voting power to " # Principal.toText(delegate), #Low);

        #ok()
    };

    /// Revoke delegation and return voting power to self
    public shared({caller}) func undelegate() : async Types.Result<(), Text> {
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Get existing delegation
        let delegationRecord = switch (Trie.get(delegations, Types.stake_key(caller), Principal.equal)) {
            case null { return #err("No delegation found") };
            case (?delegation) { delegation };
        };

        if (not delegationRecord.revokable) {
            return #err("Delegation cannot be revoked");
        };

        // Update delegation record to mark as not revokable
        let revokedDelegation = {
            delegationRecord with 
            revokable = false;
        };

        delegations := Trie.put(delegations, Types.stake_key(caller), Principal.equal, revokedDelegation).0;

        // Cancel delegation timer if it hasn't been executed yet
        let key = Types.stake_key(caller);
        switch (Trie.get(delegation_timer_ids, key, Principal.equal)) {
            case null { /* No timer to cancel */ };
            case (?timerId) {
                Timer.cancelTimer(timerId);
                delegation_timer_ids := Trie.remove(delegation_timer_ids, key, Principal.equal).0;
                delegation_timers_trie := Trie.remove(delegation_timers_trie, key, Principal.equal).0;
            };
        };

        _logSecurityEvent(caller, #SuspiciousActivity,
            "Revoked delegation of " # Nat.toText(delegationRecord.votingPower) # " voting power from " # Principal.toText(delegationRecord.delegate), #Low);

        #ok()
    };

    /// Get delegation information for a principal
    public query func getDelegationInfo(principal: Principal) : async ?Types.DelegationRecord {
        Trie.get(delegations, Types.stake_key(principal), Principal.equal)
    };

    /// Calculate delegation chain length to prevent infinite loops
    private func _calculateDelegationChainLength(principal: Principal, currentLength: Nat) : Nat {
        if (currentLength >= MAX_DELEGATION_CHAIN_LENGTH) {
            return currentLength;
        };

        switch (Trie.get(delegations, Types.stake_key(principal), Principal.equal)) {
            case null { currentLength };
            case (?delegation) {
                if (not delegation.revokable or delegation.effectiveAt > Time.now()) {
                    currentLength
                } else {
                    _calculateDelegationChainLength(delegation.delegate, currentLength + 1)
                }
            };
        }
    };

    /// Get effective voting power including delegated power
    private func _getEffectiveVotingPower(principal: Principal) : Nat {
        let directPower = switch (Trie.get(stakes, Types.stake_key(principal), Principal.equal)) {
            case null { 0 };
            case (?stake) { stake.votingPower };
        };

        // Add delegated power from others
        var delegatedFromOthers : Nat = 0;
        for ((delegator, delegation) in Trie.iter(delegations)) {
            if (delegation.delegate == principal and 
                delegation.revokable and 
                delegation.effectiveAt <= Time.now()) {
                delegatedFromOthers += delegation.votingPower;
            };
        };

        // If this principal has delegated their power, subtract it
        let delegatedToOthers = switch (Trie.get(delegations, Types.stake_key(principal), Principal.equal)) {
            case null { 0 };
            case (?delegation) {
                if (not delegation.revokable or delegation.effectiveAt > Time.now()) {
                    0
                } else {
                    delegation.votingPower
                }
            };
        };

        directPower + delegatedFromOthers - delegatedToOthers
    };

    /// Update the existing _getVotingPower function to use effective voting power
    private func _getVotingPowerUpdated(principal: Principal) : Nat {
        _getEffectiveVotingPower(principal)
    };

    // ================ HEARTBEAT SYSTEM (DISABLED) ================
    // Note: Heartbeat is disabled in favor of timer-based approach for better predictability
    
    /* 
    system func heartbeat() : async () {
        // Heartbeat disabled - using Timer-based approach instead
        // This is more predictable and doesn't depend on IC's heartbeat timing
    };
    */

    /// Manual trigger for time-sensitive operations (for testing/debugging)
    public shared({caller}) func triggerTimeBasedOperations() : async Types.Result<(), Text> {
        // Only allow emergency contacts to trigger manual operations
        if (Array.find<Principal>(system_params.emergency_contacts, func(contact) = contact == caller) == null) {
            return #err("Only emergency contacts can trigger manual operations");
        };

        let now = Time.now();
        var operationsCount : Nat = 0;

        // Check for expired proposals that need state updates
        label proposalLoop for ((proposalId, proposal) in Trie.iter(proposals)) {
            if (operationsCount >= MAX_HEARTBEAT_OPERATIONS) {
                break proposalLoop;
            };
            
            switch (proposal.state) {
                case (#Open) {
                    let votingEndTime = proposal.timestamp + Int.abs(system_params.max_voting_period * 1_000_000_000);
                    if (now >= votingEndTime) {
                        await _processVotingEndTimer(proposalId, proposal);
                        operationsCount += 1;
                    };
                };
                case (_) { /* Skip non-open proposals */ };
            };
        };

        _logSecurityEvent(caller, #SuspiciousActivity, "Manual trigger of time-based operations completed. Processed: " # Nat.toText(operationsCount), #Medium);

        #ok()
    };

    // ================ ENHANCED STAKE QUERY ENDPOINTS ================

    /// Get user's stake entries with detailed information
    public query func getStakeEntries(user: Principal) : async [Types.StakeEntry] {
        _getUserStakeEntries(user)
    };

    /// Get user's activity timeline
    public query func getUserTimeline(user: Principal, limit: ?Nat) : async [Types.TimelineEntry] {
        let timeline = switch (Trie.get(userTimelines, Types.stake_key(user), Principal.equal)) {
            case (?entries) { entries };
            case null { [] };
        };
        
        let maxLimit = switch (limit) {
            case (?l) { Nat.min(l, 100) }; // Max 100 entries
            case null { 50 }; // Default 50 entries
        };
        
        if (Array.size(timeline) <= maxLimit) {
            timeline
        } else {
            // Return most recent entries (timeline is sorted newest first)
            Array.subArray<Types.TimelineEntry>(timeline, 0, maxLimit)
        }
    };

    /// Get user's complete staking summary  
    public query func getStakingSummary(user: Principal) : async Types.StakingSummary {
        let userEntries = _getUserStakeEntries(user);
        let now = Time.now();
        
        // Calculate totals
        var totalStaked: Nat = 0;
        var totalVotingPower: Nat = 0;
        var activeEntries: Nat = 0;
        var availableToUnstake: Nat = 0;
        var nextUnlock: ?{time: Time.Time; amount: Nat; entryId: Nat} = null;

        for (entry in userEntries.vals()) {
            if (entry.isActive) {
                totalStaked += entry.amount;
                totalVotingPower += entry.votingPower;
                activeEntries += 1;

                // Check if available to unstake
                if (entry.unlockTime <= now) {
                    availableToUnstake += entry.amount;
                } else {
                    // Check for next unlock
                    switch (nextUnlock) {
                        case null {
                            nextUnlock := ?{time = entry.unlockTime; amount = entry.amount; entryId = entry.id};
                        };
                        case (?current) {
                            if (entry.unlockTime < current.time) {
                                nextUnlock := ?{time = entry.unlockTime; amount = entry.amount; entryId = entry.id};
                            };
                        };
                    };
                };
            };
        };

        // Convert tier map to array
        // let arr1 : [(Nat, Nat)] =
        // Trie.toArray<Nat, { staked : Nat; votingPower : Nat }, (Nat, Nat)>(
        //     tierMap,
        //     func (k, v) { (k, v.staked) }
        // );

        // let arr2 : [(Nat, Nat)] =
        // Trie.toArray<Nat, { staked : Nat; votingPower : Nat }, (Nat, Nat)>(
        //     tierMap,
        //     func (k, v) { (k, v.votingPower) }
        // );

        // let tierBreakdown = Array.mapFilter<(Nat, {staked: Nat; votingPower: Nat}), (Text, Nat, Nat)>(
        //     arr1,
        //     arr2.vals(),
        //     func((tierId, data)) : ?(Text, Nat, Nat) {
        //         switch (DAOUtils.findTierById(DEFAULT_MULTIPLIER_TIERS, tierId)) {
        //             case (?tier) { ?(tier.name, data.staked, data.votingPower) };
        //             case null { null };
        //         }
        //     }
        // );

        // Check for legacy stake
        let legacyStakeExists = switch (Trie.get(stakes, Types.stake_key(user), Principal.equal)) {
            case (?_) { Array.size(userEntries) == 0 }; // Only true if legacy exists but no entries
            case null { false };
        };

        {
            totalStaked = totalStaked;
            totalVotingPower = totalVotingPower;
            activeEntries = activeEntries;
            tierBreakdown = [];
            nextUnlock = nextUnlock;
            availableToUnstake = availableToUnstake;
            legacyStakeExists = legacyStakeExists;
        }
    };


    /// Get specific stake entry by ID
    public query func getStakeEntry(user: Principal, entryId: Nat) : async ?Types.StakeEntry {
        let userEntries = _getUserStakeEntries(user);
        Array.find<Types.StakeEntry>(userEntries, func(e) = e.id == entryId and e.staker == user)
    };
};