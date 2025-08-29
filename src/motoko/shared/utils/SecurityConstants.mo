// ICTO V2 - Security Constants
// Centralized security configuration and limits
import Time "mo:base/Time";

let _DELEGATION_TIMELOCK = 24 * 60 * 60 * 1_000_000_000; // 24 hours in nanoseconds
let _MIN_VOTING_PERIOD = 24 * 60 * 60 * 1_000_000_000; // 24 hours
let _MAX_VOTING_PERIOD = 30 * 24 * 60 * 60 * 1_000_000_000; // 30 days
let _MIN_TIMELOCK_DURATION = 2 * 24 * 60 * 60 * 1_000_000_000; // 2 days
let _MAX_TIMELOCK_DURATION = 7 * 24 * 60 * 60 * 1_000_000_000; // 7 days
let _PROPOSAL_RATE_LIMIT_WINDOW = 60 * 60 * 1_000_000_000; // 1 hour
let _DAILY_RATE_LIMIT_WINDOW = 24 * 60 * 60 * 1_000_000_000; // 24 hours
let _MAX_TOKEN_AMOUNT = 1_000_000_000 * 100_000_000; // 1B tokens with 8 decimals
let _MIN_STAKE_AMOUNT = 100_000_000; // 1 token with 8 decimals
let _MAX_STAKE_AMOUNT = 100_000_000 * 100_000_000; // 100M tokens with 8 decimals
let _MIN_PROPOSAL_DEPOSIT = 1 * 100_000_000; // 1 token
let _MAX_PROPOSAL_DEPOSIT = 10_000 * 100_000_000; // 10K tokens
let _HEARTBEAT_INTERVAL_NS = 60 * 1_000_000_000; // 1 minute

module SecurityConstants {
    // ================ TIME-BASED SECURITY ================
    public let DELEGATION_TIMELOCK : Int = _DELEGATION_TIMELOCK;
    public let MIN_VOTING_PERIOD : Int = _MIN_VOTING_PERIOD;
    public let MAX_VOTING_PERIOD : Int = _MAX_VOTING_PERIOD;
    public let MIN_TIMELOCK_DURATION : Int = _MIN_TIMELOCK_DURATION;
    public let MAX_TIMELOCK_DURATION : Int = _MAX_TIMELOCK_DURATION;
    
    // ================ RATE LIMITING ================  
    public let MAX_PROPOSALS_PER_HOUR : Nat = 3;
    public let MAX_PROPOSALS_PER_DAY : Nat = 10;
    public let MAX_VOTES_PER_HOUR : Nat = 50;
    public let PROPOSAL_RATE_LIMIT_WINDOW : Int = _PROPOSAL_RATE_LIMIT_WINDOW;
    public let DAILY_RATE_LIMIT_WINDOW : Int = _DAILY_RATE_LIMIT_WINDOW;
    
    // ================ FINANCIAL LIMITS ================
    public let MAX_TOKEN_AMOUNT : Nat = _MAX_TOKEN_AMOUNT;
    public let MIN_STAKE_AMOUNT : Nat = _MIN_STAKE_AMOUNT;
    public let MAX_STAKE_AMOUNT : Nat = _MAX_STAKE_AMOUNT;
    public let MIN_PROPOSAL_DEPOSIT : Nat = _MIN_PROPOSAL_DEPOSIT;
    public let MAX_PROPOSAL_DEPOSIT : Nat = _MAX_PROPOSAL_DEPOSIT;
    
    // ================ GOVERNANCE LIMITS ================
    public let MIN_QUORUM_PERCENTAGE : Nat = 100; // 1% in basis points
    public let MAX_QUORUM_PERCENTAGE : Nat = 5000; // 50% in basis points
    public let MIN_APPROVAL_THRESHOLD : Nat = 5000; // 50% in basis points  
    public let MAX_APPROVAL_THRESHOLD : Nat = 10000; // 100% in basis points
    public let MAX_VOTING_POWER_MULTIPLIER : Nat = 40000; // 4x in basis points
    public let MAX_EMERGENCY_CONTACTS : Nat = 10;
    public let MAX_STAKE_LOCK_PERIODS : Nat = 10;
    
    // ================ SYSTEM LIMITS ================
    public let MAX_PROPOSALS_PER_DAO : Nat = 10000;
    public let MAX_MEMBERS_PER_DAO : Nat = 100000;
    public let MAX_DELEGATION_CHAIN_LENGTH : Nat = 5; // Prevent infinite delegation chains
    public let MIN_CYCLES_FOR_OPERATION : Nat = 1_000_000_000; // 1B cycles minimum
    public let HEARTBEAT_INTERVAL_NS : Int = _HEARTBEAT_INTERVAL_NS; // 1 minute
    public let MAX_HEARTBEAT_OPERATIONS : Nat = 10; // Max operations per heartbeat
    
    // ================ VALIDATION FUNCTIONS ================
    
    /// Check if a timestamp is within a reasonable range
    public func isValidTimestamp(timestamp: Int) : Bool {
        let now = Time.now();
        let fiveYearsAgo = now - (5 * 365 * 24 * 60 * 60 * 1_000_000_000);
        let oneYearFuture = now + (365 * 24 * 60 * 60 * 1_000_000_000);
        
        timestamp >= fiveYearsAgo and timestamp <= oneYearFuture
    };
    
    /// Check if voting period is within acceptable bounds
    public func isValidVotingPeriod(period: Int) : Bool {
        period >= MIN_VOTING_PERIOD and period <= MAX_VOTING_PERIOD
    };
    
    /// Check if timelock duration is within acceptable bounds  
    public func isValidTimelockDuration(duration: Int) : Bool {
        duration >= MIN_TIMELOCK_DURATION and duration <= MAX_TIMELOCK_DURATION
    };
    
    /// Check if percentage is valid (in basis points)
    public func isValidBasisPoints(basisPoints: Nat) : Bool {
        basisPoints <= 10000 // 100% maximum
    };
    
    /// Check if quorum percentage is within acceptable bounds
    public func isValidQuorumPercentage(percentage: Nat) : Bool {
        percentage >= MIN_QUORUM_PERCENTAGE and percentage <= MAX_QUORUM_PERCENTAGE
    };
    
    /// Check if approval threshold is within acceptable bounds
    public func isValidApprovalThreshold(threshold: Nat) : Bool {
        threshold >= MIN_APPROVAL_THRESHOLD and threshold <= MAX_APPROVAL_THRESHOLD
    };
}