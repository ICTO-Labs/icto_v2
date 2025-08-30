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
import ICRC "../shared/types/ICRC";
import SafeMath "../shared/utils/SafeMath";

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
    
    // Core storage
    var accounts = Types.accounts_fromArray(init.accounts);
    var proposals = Types.proposals_fromArray(init.proposals);
    var stakes = Types.stakes_fromArray(init.stakeRecords);
    var delegations = Types.delegations_fromArray(init.delegations);
    var next_proposal_id : Nat = 0;
    var system_params : Types.SystemParams = init.system_params;
    var token_config : Types.TokenConfig = init.tokenConfig;
    var governance_level : Types.GovernanceLevel = init.governanceLevel;
    var security_config : Types.CustomSecurityParams = switch (init.customSecurity) {
        case (?custom) {
            custom;
        };
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
    
    // Governance state
    var total_staked : Nat = init.totalStaked;
    var total_voting_power : Nat = init.totalVotingPower;
    var emergency_state : Types.EmergencyState = init.emergencyState;
    
    // Timer management - stable storage for persistence
    var proposal_timers_stable : [(Nat, Types.ProposalTimer)] = [];
    var delegation_timers_stable : [(Principal, Types.DelegationTimer)] = [];
    
    // Security state
    var rate_limits_stable : [(Principal, Types.RateLimitRecord)] = [];
    var execution_contexts_stable : [(Nat, Types.ProposalExecutionContext)] = [];
    var security_events_stable : [Types.SecurityEvent] = [];
    var last_security_check : Time.Time = init.lastSecurityCheck;
    
    // Comment system storage
    var comments : Trie.Trie<Text, Types.ProposalComment> = Types.comments_fromArray(init.comments);
    var next_comment_id : Nat = 0;
    
    // Vote tracking
    var vote_records_stable : [Types.VoteRecord] = [];
    
    // Transient variables (reconstructed from stable data)
    private transient var vote_records_trie : Trie.Trie<Nat, Types.VoteRecord> = Trie.empty();
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


    
    system func postupgrade() {
        // Initialize token ledger after upgrade
        token_ledger := ?actor(Principal.toText(token_config.canisterId));
        
        // Reconstruct vote records trie from stable storage
        vote_records_trie := Trie.empty();
        for (i in vote_records_stable.keys()) {
            let key = { key = i; hash = Int.hash(i) };
            vote_records_trie := Trie.put(vote_records_trie, key, Nat.equal, vote_records_stable[i]).0;
        };
        
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

    // ================ STAKING FUNCTIONS WITH SECURITY ================

    /// 🔥 FIXED: Stake tokens using proper ICRC2 approve/transferFrom pattern
    public shared({caller}) func stake(amount: Nat, lockDuration: ?Nat) : async Types.Result<(), Text> {
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

        // Validate lock duration
        let validLockDuration = switch (lockDuration) {
            case null { 0 };
            case (?duration) {
                if (Array.find<Nat>(system_params.stake_lock_periods, func(x) = x == duration) == null) {
                    return #err("Invalid lock duration");
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

        // Calculate voting power with SafeMath
        let maxLockPeriod = Array.foldLeft<Nat, Nat>(system_params.stake_lock_periods, 0, Nat.max);
        let maxLock = if (maxLockPeriod == 0) { 1 } else { maxLockPeriod };
        let lockRatio = (validLockDuration * BASIS_POINTS) / maxLock;
        let multiplier = BASIS_POINTS + lockRatio; // Base voting power + lock bonus

        let votingPowerResult = SafeMath.calculateVotingPower(amount, multiplier, 8);
        let votingPower = switch (votingPowerResult) {
            case (#err(msg)) { 
                _updateTransaction(transactionId, null, #Failed("Voting power calculation failed: " # msg));
                return #err("Voting power calculation failed: " # msg);
            };
            case (#ok(power)) { power };
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
                    
                    // ================ EFFECTS ================
                    let now = Time.now();
                    let unlockTime = now + (validLockDuration * 1_000_000_000); // Convert seconds to nanoseconds

                    let newStake : Types.StakeRecord = switch (existingStake) {
                        case null {
                            // New stake
                            {
                                staker = caller;
                                amount = amount;
                                votingPower = votingPower;
                                stakedAt = now;
                                unlockTime = ?unlockTime;
                            };
                        };
                        case (?existing) {
                            // Update existing stake with SafeMath
                            let newAmountResult = SafeMath.addNat(existing.amount, amount);
                            let newAmount = switch (newAmountResult) {
                                case (#err(msg)) { return #err("Amount calculation failed: " # msg) };
                                case (#ok(amt)) { amt };
                            };

                            let newVotingPowerResult = SafeMath.addNat(existing.votingPower, votingPower);
                            let newVotingPower = switch (newVotingPowerResult) {
                                case (#err(msg)) { return #err("Voting power calculation failed: " # msg) };
                                case (#ok(power)) { power };
                            };

                            {
                                staker = existing.staker;
                                amount = newAmount;
                                stakedAt = existing.stakedAt;
                                votingPower = newVotingPower;
                                unlockTime = switch (existing.unlockTime) {
                                    case null { ?unlockTime };
                                    case (?existingUnlock) { 
                                        ?Int.max(existingUnlock, unlockTime);
                                    };
                                };
                            };
                        };
                    };

                    stakes := Trie.put(stakes, Types.stake_key(caller), Principal.equal, newStake).0;

                    // Update totals with SafeMath
                    switch (SafeMath.addNat(total_staked, amount)) {
                        case (#err(msg)) { return #err("Total staked calculation failed: " # msg) };
                        case (#ok(newTotal)) { total_staked := newTotal };
                    };

                    switch (SafeMath.addNat(total_voting_power, votingPower)) {
                        case (#err(msg)) { return #err("Total voting power calculation failed: " # msg) };
                        case (#ok(newTotal)) { total_voting_power := newTotal };
                    };

                    // Log security event with block index
                    _logSecurityEvent(caller, #StakeChange, 
                        "Staked " # Nat.toText(amount) # " tokens (Block: " # Nat.toText(blockIndex) # ")", #Low);
                    
                    return #ok();
                };
            };

        } catch (error) {
            _updateTransaction(transactionId, null, #Failed("Transfer error: " # Error.message(error)));
            return #err("Staking failed: " # Error.message(error));
        };
    };

    /// 🔥 FIXED: Withdraw staked tokens with comprehensive security and transaction logging
    public shared({caller}) func unstake(amount: Nat) : async Types.Result<(), Text> {
        // ================ CHECKS ================
        if (emergency_state.paused) {
            return #err("DAO is paused for emergency");
        };

        // Rate limiting check
        switch (_checkRateLimit(caller, #Unstake)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };

        // Get existing stake
        let existingStake = switch (Trie.get(stakes, Types.stake_key(caller), Principal.equal)) {
            case null { return #err("No stake found") };
            case (?stake) { stake };
        };

        // Validate amount
        if (amount > existingStake.amount) {
            return #err("Insufficient staked amount");
        };

        // Check lock period - CRITICAL SECURITY CHECK
        let now = Time.now();
        switch (existingStake.unlockTime) {
            case null { /* Not locked */ };
            case (?unlockTime) {
                if (now < unlockTime) {
                    let remainingLock = Int.abs(unlockTime - now) / 1_000_000_000; // Convert to seconds
                    return #err("Tokens are locked for " # Nat.toText(remainingLock) # " more seconds");
                };
            };
        };

        // Anti-spam check: prevent dust withdrawals that could clog the system
        if (amount < MIN_STAKE_AMOUNT and amount < existingStake.amount) {
            return #err("Withdrawal amount too small, must be at least " # Nat.toText(MIN_STAKE_AMOUNT));
        };

        let ledger = switch (token_ledger) {
            case null { return #err("Token ledger not initialized") };
            case (?ledger) { ledger };
        };

        // Create transaction log entry - ESSENTIAL for compliance
        let transactionId = _logTransaction(
            #Unstake, 
            Principal.fromActor(Self), 
            ?caller, 
            amount, 
            "Unstake " # Nat.toText(amount) # " tokens"
        );

        // Calculate voting power reduction proportionally with overflow protection
        let votingPowerReduction = (existingStake.votingPower * amount) / existingStake.amount;

        // ================ EFFECTS ================
        let updatedStake = if (amount == existingStake.amount) {
            null // Complete withdrawal
        } else {
            ?{
                staker = existingStake.staker;
                amount = existingStake.amount - amount;
                stakedAt = existingStake.stakedAt;
                votingPower = existingStake.votingPower - votingPowerReduction;
                unlockTime = existingStake.unlockTime;
            }
        };

        // Update or remove stake
        switch (updatedStake) {
            case null {
                stakes := Trie.remove(stakes, Types.stake_key(caller), Principal.equal).0;
            };
            case (?newStake) {
                stakes := Trie.put(stakes, Types.stake_key(caller), Principal.equal, newStake).0;
            };
        };

        // Update totals with overflow protection
        total_staked -= amount;
        total_voting_power -= votingPowerReduction;

        // ================ INTERACTIONS ================
        try {
            // Transfer tokens back to caller (Contract CAN transfer its own tokens)
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
                    // Revert state changes on transfer failure - CRITICAL FOR SECURITY
                    total_staked += amount;
                    total_voting_power += votingPowerReduction;
                    stakes := Trie.put(stakes, Types.stake_key(caller), Principal.equal, existingStake).0;
                    
                    _updateTransaction(transactionId, null, #Failed("ICRC1 transfer failed: " # debug_show(e)));
                    _logSecurityEvent(caller, #SuspiciousActivity,
                        "Token transfer failed during unstaking: " # debug_show(e), #High);
                    return #err("Token transfer failed: " # debug_show(e));
                };
                case (#Ok(blockIndex)) {
                    _updateTransaction(transactionId, ?blockIndex, #Completed);
                    _logSecurityEvent(caller, #StakeChange,
                        "Unstaked " # Nat.toText(amount) # " tokens (Block: " # Nat.toText(blockIndex) # ")", #Low);
                    return #ok();
                };
            };

        } catch (error) {
            // Revert state changes on error - CRITICAL FOR SECURITY
            total_staked += amount;
            total_voting_power += votingPowerReduction;
            stakes := Trie.put(stakes, Types.stake_key(caller), Principal.equal, existingStake).0;
            
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
                        quorumRequired = _calculateQuorum(total_voting_power);
                        approvalThreshold = system_params.approval_threshold;
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
        switch (Trie.get(vote_records_trie, { key = args.proposal_id; hash = Int.hash(args.proposal_id) }, Nat.equal)) {
            case (?existingRecord) {
                if (existingRecord.voter == caller) {
                    return #err("You have already voted on this proposal");
                };
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
        let voteKey = { key = args.proposal_id; hash = Int.hash(args.proposal_id) };
        vote_records_trie := Trie.put(vote_records_trie, voteKey, Nat.equal, voteRecord).0;

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
        switch (Trie.get(vote_records_trie, { key = proposalId; hash = Int.hash(proposalId) }, Nat.equal)) {
            case null { null };
            case (?record) {
                if (record.voter == user) { ?record } else { null }
            };
        }
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
                    if (key == proposalId) {
                        let votingPower = voteRecord.votingPower;
                        totalVotes += votingPower;
                        switch (voteRecord.vote) {
                            case (#yes) { yesVotes += votingPower };
                            case (#no) { noVotes += votingPower };
                            case (#abstain) { abstainVotes += votingPower };
                        };
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

    // ================ UPGRADE FUNCTIONS ================
    
    system func preupgrade() {
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

        _logSecurityEvent(caller, #SuspiciousActivity,
            "Manual trigger of time-based operations completed. Processed: " # Nat.toText(operationsCount), #Medium);

        #ok()
    };
};