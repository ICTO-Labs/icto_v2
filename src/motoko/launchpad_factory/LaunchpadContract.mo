import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Char "mo:base/Char";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Timer "mo:base/Timer";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Error "mo:base/Error";

import LaunchpadTypes "../shared/types/LaunchpadTypes";
import TokenFactory "../shared/types/TokenFactory";

// ================ LAUNCHPAD CONTRACT V2 ================
// Actor class template for individual launchpad instances
// Follows ICTO V2 architecture: Backend → Factory → Contract



shared ({ caller = factory }) persistent actor class LaunchpadContract<system>(
    initArgs: LaunchpadTypes.LaunchpadInitArgs
) = this {

    // ================ STABLE STATE ================

    // launchpadId is the canister ID (set by factory)
    private var launchpadId : Text = initArgs.id;
    private var config : LaunchpadTypes.LaunchpadConfig = initArgs.config;
    private var creator : Principal = initArgs.creator;
    private var factoryPrincipal : Principal = factory;
    private var createdAt : Time.Time = initArgs.createdAt;
    private var updatedAt : Time.Time = initArgs.createdAt;

    private var status : LaunchpadTypes.LaunchpadStatus = #Setup;
    private var processingState : LaunchpadTypes.ProcessingState = #Idle;
    private var installed : Bool = false;
    
    // Financial tracking
    private var totalRaised : Nat = 0;
    private var totalAllocated : Nat = 0;
    private var participantCount : Nat = 0;
    private var transactionCount : Nat = 0;

    // Participants storage (Trie for efficient queries)
    private var participantsStable : [(Text, LaunchpadTypes.Participant)] = [];
    private transient var participants = Trie.empty<Text, LaunchpadTypes.Participant>();

    // Transactions storage
    private var transactionsStable : [LaunchpadTypes.Transaction] = [];
    private transient var transactions = Buffer.fromArray<LaunchpadTypes.Transaction>(transactionsStable);

    // Affiliate tracking
    private var affiliateStatsStable : [(Text, LaunchpadTypes.AffiliateStats)] = [];
    private transient var affiliateStats = Trie.empty<Text, LaunchpadTypes.AffiliateStats>();

    // Deployed contracts after successful sale
    private var deployedContracts : LaunchpadTypes.DeployedContracts = {
        tokenCanister = null;
        vestingContracts = [];
        daoCanister = null;
        liquidityPool = null;
        stakingContract = null;
    };

    // Timer for automated lifecycle management
    private var timerId : ?Timer.TimerId = null;
    private var _lastTimerSetup : Time.Time = 0;
    
    // Security & Emergency Controls
    private var emergencyPaused : Bool = false;
    private var emergencyReason : Text = "";
    private var lastEmergencyAction : Time.Time = 0;
    
    // Reentrancy Protection
    private var reentrancyLock : Bool = false;
    
    // Audit Trail
    private var adminActions : [LaunchpadTypes.AdminAction] = [];
    private var securityEvents : [LaunchpadTypes.SecurityEvent] = [];
    
    // Rate Limiting
    private var lastParticipationTime : [(Principal, Time.Time)] = [];
    private var rateLimitViolations : [(Principal, Nat)] = [];

    // Factory Actor Interfaces
    // TODO: Get factory IDs from config instead of hardcoding
    // This should be passed via init args or loaded dynamically
    // TEMPORARY FIX: Using local token_factory ID
    private let tokenFactoryActor = actor("ulvla-h7777-77774-qaacq-cai") : actor {
        deployTokenWithConfig : (
            config: TokenFactory.TokenConfig,
            deploymentConfig: TokenFactory.DeploymentConfig,
            paymentResult: ?Text
        ) -> async Result.Result<TokenFactory.DeploymentResult, Text>;
    };

    // ================ SYSTEM FUNCTIONS ================

    system func preupgrade() {
        participantsStable := Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(participants, func(k, v) { (k, v) });
        transactionsStable := Buffer.toArray(transactions);
        affiliateStatsStable := Trie.toArray<Text, LaunchpadTypes.AffiliateStats, (Text, LaunchpadTypes.AffiliateStats)>(affiliateStats, func(k, v) { (k, v) });
        
        // Cancel timer
        switch (timerId) {
            case (?id) { Timer.cancelTimer(id); };
            case null {};
        };
    };

    system func postupgrade() {
        participants := Trie.empty<Text, LaunchpadTypes.Participant>();
        for ((key, participant) in participantsStable.vals()) {
            participants := Trie.put(participants, LaunchpadTypes.textKey(key), Text.equal, participant).0;
        };
        
        transactions := Buffer.fromArray(transactionsStable);
        
        affiliateStats := Trie.empty<Text, LaunchpadTypes.AffiliateStats>();
        for ((key, stats) in affiliateStatsStable.vals()) {
            affiliateStats := Trie.put(affiliateStats, LaunchpadTypes.textKey(key), Text.equal, stats).0;
        };
        
        // Clear stable arrays to save memory
        participantsStable := [];
        transactionsStable := [];
        affiliateStatsStable := [];
        
        // Note: Timer will be restarted on first function call
    };

    // ================ INITIALIZATION ================

    /// Set the launchpad ID (called by factory after creation with canister ID)
    public shared({caller}) func setId(newId: Text) : async Result.Result<(), Text> {
        if (caller != factoryPrincipal) {
            return #err("Unauthorized: Only factory can set ID");
        };

        if (installed) {
            return #err("Cannot change ID after initialization");
        };

        launchpadId := newId;
        Debug.print("Launchpad ID set to: " # newId);
        #ok(())
    };

    public shared({caller}) func initialize() : async Result.Result<(), Text> {
        if (caller != factoryPrincipal) {
            return #err("Unauthorized: Only factory can initialize");
        };

        if (installed) {
            return #err("Launchpad already initialized");
        };

        // Validate configuration
        let validationResult = _validateConfig(config);
        switch (validationResult) {
            case (#err(msg)) return #err("Configuration invalid: " # msg);
            case (#ok(_)) {};
        };

        // Update status and setup timer
        status := #Upcoming;
        installed := true;
        updatedAt := Time.now();
        ignore _setupTimer();

        Debug.print("Launchpad initialized: " # launchpadId);
        #ok(())
    };

    // ================ PARTICIPATION FUNCTIONS ================

    public shared({caller}) func participate(
        amount: Nat,
        affiliateCode: ?Text
    ) : async Result.Result<LaunchpadTypes.Transaction, Text> {
        
        // Reentrancy protection
        switch (_checkReentrancy(caller)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        if (emergencyPaused) {
            _releaseReentrancyLock();
            return #err("Contract paused: " # emergencyReason);
        };
        
        if (not installed) {
            _releaseReentrancyLock();
            return #err("Launchpad not initialized");
        };
        
        // Rate limiting & large transaction validation
        if (not _checkRateLimit(caller)) {
            _releaseReentrancyLock();
            return #err("Rate limit exceeded");
        };
        
        if (not _validateLargeTransaction(amount, caller)) {
            _releaseReentrancyLock();
            return #err("Transaction validation failed");
        };
        
        // Validate participation eligibility
        let eligibilityCheck = await _checkParticipationEligibility(caller, amount);
        switch (eligibilityCheck) {
            case (#err(msg)) return #err(msg);
            case (#ok(_)) {};
        };

        // Create transaction record
        let transactionId = _generateTransactionId();
        let transaction : LaunchpadTypes.Transaction = {
            id = transactionId;
            participant = caller;
            txType = #Purchase;
            amount = amount;
            token = config.purchaseToken.canisterId;
            timestamp = Time.now();
            blockIndex = null; // Will be set after ICRC transfer
            fee = config.purchaseToken.transferFee;
            status = #Pending;
            affiliateCode = affiliateCode;
            notes = null;
        };

        // Process the purchase
        let purchaseResult = await _processPurchase(caller, amount, affiliateCode, transaction);
        switch (purchaseResult) {
            case (#err(msg)) {
                // Update transaction as failed
                let failedTransaction = {
                    transaction with 
                    status = #Failed(msg);
                    notes = ?("Purchase failed: " # msg);
                };
                transactions.add(failedTransaction);
                return #err(msg);
            };
            case (#ok(updatedTransaction)) {
                transactions.add(updatedTransaction);
                transactionCount += 1;
                updatedAt := Time.now();
                return #ok(updatedTransaction);
            };
        };
    };

    // ================ CLAIM FUNCTIONS ================

    public shared({caller}) func claimTokens() : async Result.Result<Nat, Text> {
        // Reentrancy protection
        switch (_checkReentrancy(caller)) {
            case (#err(msg)) return #err(msg);
            case (#ok()) {};
        };
        
        if (emergencyPaused) {
            _releaseReentrancyLock();
            return #err("Contract paused: " # emergencyReason);
        };

        if (status != #Claiming and status != #Completed) {
            _releaseReentrancyLock();
            return #err("Claiming not active");
        };

        // Rate limiting
        if (not _checkRateLimit(caller)) {
            _releaseReentrancyLock();
            return #err("Rate limit exceeded");
        };

        let participantKey = Principal.toText(caller);
        let participant = switch (Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal)) {
            case null {
                _releaseReentrancyLock();
                return #err("Not a participant");
            };
            case (?p) p;
        };

        if (participant.allocationAmount == 0) {
            _releaseReentrancyLock();
            return #err("No allocation available");
        };

        let unclaimedAmount = if (participant.allocationAmount >= participant.claimedAmount) {
            Nat.sub(participant.allocationAmount, participant.claimedAmount)
        } else {
            0
        };
        if (unclaimedAmount == 0) {
            _releaseReentrancyLock();
            return #err("Already fully claimed");
        };

        // CEI Pattern: Check-Effects-Interactions
        // 1. EFFECT: Update state BEFORE external calls
        let updatedParticipant: LaunchpadTypes.Participant = {
            participant with 
            claimedAmount = participant.claimedAmount + unclaimedAmount;
        };
        participants := Trie.put(participants, LaunchpadTypes.textKey(participantKey), Text.equal, updatedParticipant).0;
        
        // Log the claim attempt
        _logAdminAction("TOKEN_CLAIM", caller, "Amount: " # Nat.toText(unclaimedAmount), true, null);
        
        // 2. INTERACTION: External calls AFTER state update  
        let claimResult = await _processClaim(caller, participant, unclaimedAmount);
        
        // 3. Release reentrancy lock
        _releaseReentrancyLock();
        
        switch (claimResult) {
            case (#err(msg)) {
                // Rollback state change if external call failed
                participants := Trie.put(participants, LaunchpadTypes.textKey(participantKey), Text.equal, participant).0;
                _logAdminAction("TOKEN_CLAIM_FAILED", caller, msg, false, ?msg);
                return #err(msg);
            };
            case (#ok(claimedAmount)) {
                updatedAt := Time.now();
                return #ok(claimedAmount);
            };
        };
    };

    // ================ ADMIN FUNCTIONS ================

    public shared({caller}) func pauseLaunchpad() : async Result.Result<(), Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized");
        };

        if (not config.pausable) {
            return #err("Launchpad is not pausable");
        };

        status := #Emergency;
        updatedAt := Time.now();
        
        // Cancel timer
        switch (timerId) {
            case (?id) {
                Timer.cancelTimer(id);
                timerId := null;
            };
            case null {};
        };

        Debug.print("Launchpad paused by: " # Principal.toText(caller));
        #ok(())
    };

    public shared({caller}) func unpauseLaunchpad() : async Result.Result<(), Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized");
        };

        if (status != #Emergency) {
            return #err("Launchpad is not paused");
        };

        // Determine appropriate status based on timeline
        let now = Time.now();
        let newStatus = if (now < config.timeline.saleStart) {
            #Upcoming
        } else if (now <= config.timeline.saleEnd) {
            #SaleActive
        } else {
            #SaleEnded
        };

        status := newStatus;
        updatedAt := Time.now();
        ignore _setupTimer();

        Debug.print("Launchpad unpaused by: " # Principal.toText(caller));
        #ok(())
    };

    public shared({caller}) func cancelLaunchpad() : async Result.Result<(), Text> {
        if (caller != creator and caller != factoryPrincipal) {
            return #err("Unauthorized: Only creator or factory can cancel");
        };

        if (not config.cancellable) {
            return #err("Launchpad is not cancellable");
        };

        if (status == #Completed or status == #Cancelled) {
            return #err("Launchpad already finalized");
        };

        status := #Cancelled;
        processingState := #Processing({
            stage = #Refunding;
            progress = 0;
            processedCount = 0;
            totalCount = participantCount;
            errorCount = 0;
            lastError = null;
        });
        updatedAt := Time.now();

        // Start refund process
        ignore _processRefunds();

        Debug.print("Launchpad cancelled by: " # Principal.toText(caller));
        #ok(())
    };

    // ================ QUERY FUNCTIONS ================

    public query func getLaunchpadDetail() : async LaunchpadTypes.LaunchpadDetail {
        {
            id = launchpadId;
            canisterId = Principal.fromActor(this);
            creator = creator;
            config = config;
            status = status;
            processingState = processingState;
            stats = _calculateStats();
            deployedContracts = deployedContracts;
            createdAt = createdAt;
            updatedAt = updatedAt;
            finalizedAt = _getFinalizedTime();
        }
    };

    public query func getParticipant(participant: Principal) : async ?LaunchpadTypes.Participant {
        let key = Principal.toText(participant);
        Trie.get(participants, LaunchpadTypes.textKey(key), Text.equal)
    };

    public query func getParticipants(offset: Nat, limit: Nat) : async [LaunchpadTypes.Participant] {
        let participantArray = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(participants, func(k, v) { (k, v) });
        let maxLimit = Nat.min(limit, 100); // Max 100 per query
        let startIndex = Nat.min(offset, participantArray.size());
        let endIndex = Nat.min(startIndex + maxLimit, participantArray.size());
        
        if (startIndex >= participantArray.size()) {
            return [];
        };
        
        Array.tabulate<LaunchpadTypes.Participant>(endIndex - startIndex, func(i) {
            participantArray[startIndex + i].1
        })
    };

    public query func getTransactions(offset: Nat, limit: Nat) : async [LaunchpadTypes.Transaction] {
        let transactionArray = Buffer.toArray(transactions);
        let maxLimit = Nat.min(limit, 100);
        let startIndex = Nat.min(offset, transactionArray.size());
        let endIndex = Nat.min(startIndex + maxLimit, transactionArray.size());
        
        if (startIndex >= transactionArray.size()) {
            return [];
        };
        
        Array.tabulate<LaunchpadTypes.Transaction>(endIndex - startIndex, func(i) {
            transactionArray[startIndex + i]
        })
    };

    public query func getStats() : async LaunchpadTypes.LaunchpadStats {
        _calculateStats()
    };

    public query func getConfig() : async LaunchpadTypes.LaunchpadConfig {
        config
    };

    public query func getStatus() : async LaunchpadTypes.LaunchpadStatus {
        status
    };

    public query func getAffiliateStats(affiliate: Principal) : async ?LaunchpadTypes.AffiliateStats {
        let key = Principal.toText(affiliate);
        Trie.get(affiliateStats, LaunchpadTypes.textKey(key), Text.equal)
    };

    public query func isWhitelisted(user: Principal) : async Bool {
        if (not config.saleParams.requiresWhitelist) return true;
        Array.find<Principal>(config.whitelist, func(p) { p == user }) != null
    };

    // ================ TIMER & LIFECYCLE MANAGEMENT ================

    private func _setupTimer() : async () {
        let now = Time.now();
        let nextCheck = _getNextTimerInterval(now);
        
        if (nextCheck > now) {
            timerId := ?Timer.setTimer<system>(#nanoseconds(Int.abs(nextCheck - now)), _timerCallback);
        };
    };

    private func _timerCallback() : async () {
        await _processLifecycleTransition();
        
        // Setup next timer if still active
        if (isActive()) {
            await _setupTimer();
        };
    };

    private func _processLifecycleTransition() : async () {
        let now = Time.now();
        let oldStatus = status;
        
        switch (status) {
            case (#Upcoming) {
                if (config.timeline.whitelistStart != null and now >= Option.get(config.timeline.whitelistStart, 0)) {
                    status := #WhitelistOpen;
                } else if (now >= config.timeline.saleStart) {
                    status := #SaleActive;
                };
            };
            case (#WhitelistOpen) {
                if (now >= config.timeline.saleStart) {
                    status := #SaleActive;
                };
            };
            case (#SaleActive) {
                if (now >= config.timeline.saleEnd or _isHardCapReached()) {
                    status := #SaleEnded;
                    await _processSaleEnd();
                };
            };
            case (_) {}; // No automatic transitions for other states
        };
        
        if (oldStatus != status) {
            updatedAt := now;
            Debug.print("Status updated from " # LaunchpadTypes.statusToText(oldStatus) # " to " # LaunchpadTypes.statusToText(status));
        };
    };

    private func _processSaleEnd() : async () {
        if (totalRaised >= config.saleParams.softCap) {
            status := #Successful;
            processingState := #Processing({
                stage = #TokenDeployment;
                progress = 0;
                processedCount = 0;
                totalCount = 4; // Token, Vesting, DAO, Distribution
                errorCount = 0;
                lastError = null;
            });
            ignore _processSuccessfulSale();
        } else {
            status := #Failed;
            processingState := #Processing({
                stage = #Refunding;
                progress = 0;
                processedCount = 0;
                totalCount = participantCount;
                errorCount = 0;
                lastError = null;
            });
            ignore _processRefunds();
        };
    };

    // ================ PRIVATE IMPLEMENTATION ================

    // ================ FACTORY CALLBACKS ================

    private func _notifyFactoryParticipantAdded(participant: Principal) : async () {
        let factory = actor(Principal.toText(factoryPrincipal)) : actor {
            notifyParticipantAdded : (Principal) -> async Result.Result<(), Text>;
        };

        try {
            let result = await factory.notifyParticipantAdded(participant);
            switch (result) {
                case (#ok()) {
                    Debug.print("✅ Notified factory: participant " # Principal.toText(participant) # " added");
                };
                case (#err(msg)) {
                    Debug.print("⚠️ Factory notification failed: " # msg);
                };
            };
        } catch (e) {
            Debug.print("⚠️ Failed to notify factory: " # Error.message(e));
            // Continue anyway - not critical
        };
    };

    private func _notifyFactoryParticipantRemoved(participant: Principal) : async () {
        let factory = actor(Principal.toText(factoryPrincipal)) : actor {
            notifyParticipantRemoved : (Principal) -> async Result.Result<(), Text>;
        };

        try {
            let result = await factory.notifyParticipantRemoved(participant);
            switch (result) {
                case (#ok()) {
                    Debug.print("✅ Notified factory: participant " # Principal.toText(participant) # " removed");
                };
                case (#err(msg)) {
                    Debug.print("⚠️ Factory notification failed: " # msg);
                };
            };
        } catch (e) {
            Debug.print("⚠️ Failed to notify factory: " # Error.message(e));
            // Continue anyway - not critical
        };
    };

    // ================ VALIDATION ================

    private func _validateConfig(cfg: LaunchpadTypes.LaunchpadConfig) : Result.Result<(), Text> {
        if (cfg.saleParams.softCap > cfg.saleParams.hardCap) {
            return #err("Soft cap cannot be greater than hard cap");
        };
        
        if (cfg.timeline.saleStart >= cfg.timeline.saleEnd) {
            return #err("Sale start must be before sale end");
        };
        
        if (cfg.saleParams.totalSaleAmount == 0) {
            return #err("Sale amount must be greater than 0");
        };
        
        #ok(())
    };

    private func _checkParticipationEligibility(participant: Principal, amount: Nat) : async Result.Result<(), Text> {
        // Check sale is active
        if (status != #SaleActive and status != #WhitelistOpen) {
            return #err("Sale not active");
        };
        
        // Check minimum contribution
        if (amount < config.saleParams.minContribution) {
            return #err("Contribution below minimum");
        };
        
        // Check maximum contribution
        switch (config.saleParams.maxContribution) {
            case (?maxAmount) {
                let participantKey = Principal.toText(participant);
                let existingContribution = switch (Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal)) {
                    case null 0;
                    case (?p) p.totalContribution;
                };
                
                if (existingContribution + amount > maxAmount) {
                    return #err("Exceeds maximum contribution");
                };
            };
            case null {};
        };
        
        // Check hard cap
        if (totalRaised + amount > config.saleParams.hardCap) {
            return #err("Exceeds hard cap");
        };
        
        // Check whitelist if required
        if (config.saleParams.requiresWhitelist) {
            let isWhitelistedUser = Array.find<Principal>(config.whitelist, func(p) { p == participant });
            if (isWhitelistedUser == null) {
                return #err("Not whitelisted");
            };
        };
        
        #ok(())
    };

    private func _processPurchase(
        participant: Principal, 
        amount: Nat, 
        affiliateCode: ?Text,
        transaction: LaunchpadTypes.Transaction
    ) : async Result.Result<LaunchpadTypes.Transaction, Text> {
        
        // Simulate ICRC transfer (in real implementation, call ICRC ledger)
        // For now, assume successful transfer
        let confirmedTransaction = {
            transaction with 
            status = #Confirmed;
            blockIndex = ?transactionCount; // Mock block index
        };
        
        // Update participant record
        let participantKey = Principal.toText(participant);
        let existingParticipant = Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal);
        
        let isNewParticipant = Option.isNull(existingParticipant);

        let updatedParticipant = switch (existingParticipant) {
            case null {
                // New participant
                participantCount += 1;
                {
                    principal = participant;
                    totalContribution = amount;
                    allocationAmount = _calculateTokenAllocation(amount);
                    commitCount = 1;
                    firstContribution = Time.now();
                    lastContribution = Time.now();
                    whitelistTier = null;
                    kycStatus = #NotRequired;
                    affiliateCode = affiliateCode;
                    claimedAmount = 0;
                    refundedAmount = 0;
                    vestingContract = null;
                    isBlacklisted = false;
                } : LaunchpadTypes.Participant
            };
            case (?existing) {
                // Existing participant
                {
                    existing with
                    totalContribution = existing.totalContribution + amount;
                    allocationAmount = existing.allocationAmount + _calculateTokenAllocation(amount);
                    commitCount = existing.commitCount + 1;
                    lastContribution = Time.now();
                }
            };
        };

        participants := Trie.put(participants, LaunchpadTypes.textKey(participantKey), Text.equal, updatedParticipant).0;

        // Notify factory if this is a new participant
        if (isNewParticipant) {
            await _notifyFactoryParticipantAdded(participant);
        };
        
        // Update totals
        totalRaised += amount;
        totalAllocated += _calculateTokenAllocation(amount);
        
        // Process affiliate commission if applicable
        switch (affiliateCode) {
            case (?code) {
                _processAffiliateCommission(code, amount);
            };
            case null {};
        };
        
        #ok(confirmedTransaction)
    };

    private func _processClaim(
        _claimer: Principal, 
        participant: LaunchpadTypes.Participant,
        amount: Nat
    ) : async Result.Result<Nat, Text> {
        // Simulate token transfer to participant
        // In real implementation, transfer from deployed token canister
        #ok(amount)
    };

    private func _processSuccessfulSale() : async () {
        // Update processing state
        processingState := #Processing({
            stage = #TokenDeployment;
            progress = 0;
            processedCount = 0;
            totalCount = 5; // Token, DAO, Distributions, Fees, Finalize
            errorCount = 0;
            lastError = null;
        });
        
        try {
            // Step 1: Create Token
            await _createProjectToken();
            _updateProcessingProgress(1, #VestingSetup);
            
            // Step 2: Create DAO Contract  
            await _createProjectDAO();
            _updateProcessingProgress(2, #Distribution);
            
            // Step 3: Create Distribution Contracts
            await _setupDistributionContracts();
            _updateProcessingProgress(3, #FinalCleanup);
            
            // Step 4: Process Platform Fees & Final Allocation
            await _processPlatformFeesAndAllocation();
            _updateProcessingProgress(4, #FinalCleanup);
            
            // Step 5: Transfer Controllers to DAO
            await _transferControllersToDAO();
            _updateProcessingProgress(5, #FinalCleanup);
            
            // Complete the process
            processingState := #Completed;
            status := #Claiming;
            updatedAt := Time.now();
            
            Debug.print("Successful sale processing completed for launchpad: " # launchpadId);
            
        } catch (_error) {
            processingState := #Failed("Pipeline execution failed");
            Debug.print("Failed to process successful sale");
        };
    };

    // Helper function to update processing progress
    private func _updateProcessingProgress(completed: Nat, nextStage: LaunchpadTypes.ProcessingStage) : () {
        switch (processingState) {
            case (#Processing(state)) {
                processingState := #Processing({
                    state with
                    stage = nextStage;
                    progress = Nat8.fromNat(Nat.min(100, completed * 100 / 5));
                    processedCount = completed;
                });
            };
            case (_) {};
        };
    };

    // Step 1: Create Project Token
    private func _createProjectToken() : async () {
        Debug.print("Creating project token for launchpad: " # launchpadId);
        
        try {
            // Prepare token configuration
            let tokenConfig : TokenFactory.TokenConfig = {
                name = config.saleToken.name;
                symbol = config.saleToken.symbol;
                decimals = config.saleToken.decimals;
                logo = config.saleToken.logo;
                minter = ?{ owner = creator; subaccount = null };
                feeCollector = ?{ owner = creator; subaccount = null };
                transferFee = config.saleToken.transferFee;
                initialBalances = [];
                totalSupply = config.saleToken.totalSupply;
                description = config.saleToken.description;
                website = config.projectInfo.website;
                projectId = ?launchpadId;
            };
            
            // Prepare deployment configuration
            let deploymentConfig : TokenFactory.DeploymentConfig = {
                tokenOwner = ?creator;
                enableCycleOps = ?true;
                cyclesForInstall = ?200_000_000_000; // 200B cycles
                cyclesForArchive = ?100_000_000_000; // 100B cycles
                minCyclesInDeployer = ?50_000_000_000; // 50B cycles
                archiveOptions = ?{
                    num_blocks_to_archive = 1000;
                    max_transactions_per_response = ?2000;
                    trigger_threshold = 2000;
                    max_message_size_bytes = ?2048;
                    cycles_for_archive_creation = ?100_000_000_000;
                    node_max_memory_size_bytes = ?3_221_225_472;
                    controller_id = creator;
                    more_controller_ids = ?[Principal.fromActor(this)];
                };
            };
            
            // Call TokenFactory to create ICRC token
            let tokenResult = await tokenFactoryActor.deployTokenWithConfig(
                tokenConfig,
                deploymentConfig,
                null // No payment result needed for launchpad integration
            );
            
            switch (tokenResult) {
                case (#ok(result)) {
                    // Extract canister ID from deployment result
                    let canisterId = switch (result.canisterId) {
                        case (?id) Principal.fromText(id);
                        case (null) throw Error.reject("Token deployment succeeded but no canister ID returned");
                    };
                    
                    // Update deployedContracts with token canister ID
                    deployedContracts := {
                        deployedContracts with
                        tokenCanister = ?canisterId;
                    };
                    
                    Debug.print("Token created successfully. Canister ID: " # Principal.toText(canisterId));
                };
                case (#err(error)) {
                    Debug.print("Token creation failed: " # error);
                    throw Error.reject("Token creation failed: " # error);
                };
            };
            
        } catch (error) {
            Debug.print("Error in _createProjectToken");
            throw error;
        };
    };

    // Step 2: Create Project DAO
    private func _createProjectDAO() : async () {
        Debug.print("Creating project DAO...");
        
        // TODO: Actual DAOFactory integration
        // let daoResult = await DAOFactory.createDAO({
        //     votingToken = deployedContracts.tokenCanister;
        //     proposalThreshold = config.governanceConfig.proposalThreshold;
        //     quorumPercentage = config.governanceConfig.quorumPercentage;
        //     votingPeriod = config.governanceConfig.votingPeriod;
        //     timelockDuration = config.governanceConfig.timelockDuration;
        // });
        
        // Update deployedContracts with DAO canister ID
        // deployedContracts := {
        //     deployedContracts with
        //     daoCanister = ?daoResult.canisterId;
        // };
    };

    // Step 3: Setup Distribution Contracts
    private func _setupDistributionContracts() : async () {
        Debug.print("Setting up distribution contracts...");
        
        // Create investor vesting contracts
        await _createInvestorDistribution();
        
        // Create team allocation contracts (both token and raised funds)
        await _createTeamAllocations();
        
        // Create other distribution contracts
        await _createOtherDistributions();
    };

    // Step 4: Process Platform Fees and Final Allocation
    private func _processPlatformFeesAndAllocation() : async () {
        Debug.print("Processing platform fees and final allocation...");
        
        // Calculate platform fees
        let _platformFee = totalRaised * Nat8.toNat(config.platformFeeRate) / 100;
        
        // Calculate DEX listing fees
        let _dexFees = _calculateDEXFees();
        
        // Calculate treasury allocation (remaining tokens)
        let _treasuryTokens = _calculateTreasuryAllocation();
        let _treasuryFunds = _calculateTreasuryFunds();
        
        // Transfer platform fees
        // await _transferPlatformFees(platformFee);
        
        // Transfer remaining allocation to DAO treasury
        // await _transferToDAOTreasury(treasuryTokens, treasuryFunds);
    };

    // Step 5: Transfer Controllers to DAO
    private func _transferControllersToDAO() : async () {
        Debug.print("Transferring controllers to DAO...");
        
        // Transfer token contract controller to DAO
        // Transfer distribution contracts controller to DAO
        // Transfer any other relevant controllers to DAO
        
        // This ensures DAO has full control over project contracts
    };

    // Helper functions for distribution creation
    private func _createInvestorDistribution() : async () {
        // Create vesting contract for all sale participants
        // Based on sale participant data and vesting schedules
    };

    private func _createTeamAllocations() : async () {
        // Create team token allocation (sale tokens with vesting)
        // Create team raised fund allocation (raised tokens with vesting)
    };

    private func _createOtherDistributions() : async () {
        // Create marketing, development, and other allocation contracts
        // Based on raisedFundsAllocation configuration
    };

    // Fee calculation helpers
    private func _calculateDEXFees() : Nat {
        // Calculate total DEX listing fees across all enabled DEXs
        var totalFees: Nat = 0;
        // Implementation would sum up fees from all enabled DEX platforms
        totalFees
    };

    private func _calculateTreasuryAllocation() : Nat {
        // Calculate remaining tokens for DAO treasury using new fixed structure
        var allocatedTokens: Nat = 0;
        
        switch (config.tokenDistribution) {
            case (?fixedDistrib) {
                // Use new V2 fixed structure  
                allocatedTokens += _parseTokenAmount(fixedDistrib.sale.totalAmount);
                allocatedTokens += _parseTokenAmount(fixedDistrib.team.totalAmount);
                allocatedTokens += _parseTokenAmount(fixedDistrib.liquidityPool.totalAmount);
                
                for (other in fixedDistrib.others.vals()) {
                    allocatedTokens += _parseTokenAmount(other.totalAmount);
                };
            };
            case (null) {
                // Fallback to legacy V1 structure
                for (category in config.distribution.vals()) {
                    allocatedTokens += category.totalAmount;
                };
            };
        };
        
        if (config.saleToken.totalSupply >= allocatedTokens) {
            config.saleToken.totalSupply - allocatedTokens
        } else {
            0
        }
    };

    // Helper function to parse string amounts
    private func _parseTokenAmount(amountStr: Text) : Nat {
        // Simple parser for string to Nat conversion
        // In production, use a proper parsing library
        var result: Nat = 0;
        var multiplier: Nat = 1;
        let charArray = Iter.toArray(Text.toIter(amountStr));
        let size = charArray.size();
        
        var i = 0;
        label parseLoop while (i < size) {
            let char = charArray[size - 1 - i];
            switch (char) {
                case ('0') { result += 0 * multiplier; };
                case ('1') { result += 1 * multiplier; };
                case ('2') { result += 2 * multiplier; };
                case ('3') { result += 3 * multiplier; };
                case ('4') { result += 4 * multiplier; };
                case ('5') { result += 5 * multiplier; };
                case ('6') { result += 6 * multiplier; };
                case ('7') { result += 7 * multiplier; };
                case ('8') { result += 8 * multiplier; };
                case ('9') { result += 9 * multiplier; };
                case (',') { /* ignore commas */ };
                case (_) { 
                    // Invalid character, return 0
                    return 0;
                };
            };
            multiplier *= 10;
            i += 1;
        };
        result
    };

    private func _calculateTreasuryFunds() : Nat {
        // Calculate remaining raised funds for DAO treasury  
        // Total raised - platform fees - DEX fees - team allocations = treasury funds
        var allocatedFunds: Nat = 0;
        
        // Add platform fees
        allocatedFunds += totalRaised * Nat8.toNat(config.platformFeeRate) / 100;
        
        // Add DEX fees
        allocatedFunds += _calculateDEXFees();
        
        // Add team/development/marketing allocations
        allocatedFunds += _calculateRaisedFundsAllocations();
        
        if (totalRaised >= allocatedFunds) {
            totalRaised - allocatedFunds
        } else {
            0
        }
    };

    private func _calculateRaisedFundsAllocations() : Nat {
        var totalAllocated : Nat = 0;

        for (allocation in config.raisedFundsAllocation.allocations.vals()) {
            totalAllocated += allocation.amount;
        };

        totalAllocated
    };

    private func _processRefunds() : async () {
        // Process refunds for all participants
        processingState := #Completed;
        status := #Completed;
        updatedAt := Time.now();
    };

    private func _processAffiliateCommission(code: Text, amount: Nat) : () {
        let commission = amount * Nat8.toNat(config.affiliateConfig.commissionRate) / 100;
        let existingStats = Trie.get(affiliateStats, LaunchpadTypes.textKey(code), Text.equal);
        
        let updatedStats = switch (existingStats) {
            case null {
                {
                    referrer = Principal.fromText(code); // This would need proper conversion
                    totalVolume = amount;
                    totalCommission = commission;
                    referralCount = 1;
                    tierLevel = 1;
                    isActive = true;
                } : LaunchpadTypes.AffiliateStats
            };
            case (?existing) {
                {
                    existing with
                    totalVolume = existing.totalVolume + amount;
                    totalCommission = existing.totalCommission + commission;
                    referralCount = existing.referralCount + 1;
                }
            };
        };
        
        affiliateStats := Trie.put(affiliateStats, LaunchpadTypes.textKey(code), Text.equal, updatedStats).0;
    };

    private func _calculateTokenAllocation(contributionAmount: Nat) : Nat {
        contributionAmount * LaunchpadTypes.E8S / config.saleParams.tokenPrice
    };

    private func _calculateStats() : LaunchpadTypes.LaunchpadStats {
        let now = Time.now();
        {
            totalRaised = totalRaised;
            totalAllocated = totalAllocated;
            participantCount = participantCount;
            transactionCount = transactions.size();
            softCapProgress = Nat8.fromNat(Nat.min(100, if (config.saleParams.softCap > 0) totalRaised * 100 / config.saleParams.softCap else 0));
            hardCapProgress = Nat8.fromNat(Nat.min(100, if (config.saleParams.hardCap > 0) totalRaised * 100 / config.saleParams.hardCap else 0));
            allocationProgress = 100; // Calculate based on actual distribution
            affiliateVolume = 0; // Calculate from affiliate stats
            affiliateCount = Trie.size(affiliateStats);
            totalCommissions = 0; // Calculate from affiliate stats
            averageContribution = if (participantCount > 0) totalRaised / participantCount else 0;
            medianContribution = 0; // Would need sorting to calculate
            timeRemaining = if (status == #SaleActive and now < config.timeline.saleEnd) 
                            ?(config.timeline.saleEnd - now) else null;
            estimatedCompletion = null; // Calculate based on current progress
        }
    };

    private func _getFinalizedTime() : ?Time.Time {
        switch (status) {
            case (#Completed or #Cancelled) ?updatedAt;
            case (_) null;
        }
    };

    private func _generateTransactionId() : Text {
        launchpadId # "_" # Nat.toText(transactions.size() + 1)
    };

    private func _getNextTimerInterval(now: Time.Time) : Time.Time {
        switch (status) {
            case (#Upcoming) {
                switch (config.timeline.whitelistStart) {
                    case (?whitelistStart) {
                        if (now < whitelistStart) {
                            whitelistStart
                        } else {
                            config.timeline.saleStart
                        }
                    };
                    case (null) config.timeline.saleStart;
                }
            };
            case (#WhitelistOpen) config.timeline.saleStart;
            case (#SaleActive) config.timeline.saleEnd;
            case (_) now + 3600_000_000_000; // 1 hour default
        }
    };

    private func _isHardCapReached() : Bool {
        totalRaised >= config.saleParams.hardCap
    };

    private func _isAuthorized(caller: Principal) : Bool {
        caller == creator or 
        caller == factoryPrincipal or
        Array.find<Principal>(config.adminList, func(p) { p == caller }) != null or
        Array.find<Principal>(config.emergencyContacts, func(p) { p == caller }) != null
    };

    private func isActive() : Bool {
        switch (status) {
            case (#Setup or #Upcoming or #WhitelistOpen or #SaleActive) true;
            case (_) false;
        }
    };

    // ================ SECURITY & REENTRANCY PROTECTION ================

    private func _checkReentrancy(caller: Principal) : Result.Result<(), Text> {
        if (reentrancyLock) {
            _logSecurityEvent(#SuspiciousActivity, caller, "Reentrancy attempt detected", #Critical);
            return #err("Reentrancy attack prevented");
        };
        reentrancyLock := true;
        #ok(())
    };

    private func _releaseReentrancyLock() : () {
        reentrancyLock := false;
    };

    // ================ SECURITY & AUDIT FUNCTIONS ================

    private func _logAdminAction(action: Text, caller: Principal, parameters: Text, success: Bool, reason: ?Text) : () {
        let adminAction: LaunchpadTypes.AdminAction = {
            action = action;
            caller = caller;
            timestamp = Time.now();
            parameters = parameters;
            success = success;
            reason = reason;
        };
        adminActions := Array.append<LaunchpadTypes.AdminAction>(adminActions, [adminAction]);
    };

    private func _logSecurityEvent(eventType: LaunchpadTypes.SecurityEventType, principal: Principal, details: Text, severity: LaunchpadTypes.SecuritySeverity) : () {
        let securityEvent: LaunchpadTypes.SecurityEvent = {
            eventType = eventType;
            principal = principal;
            timestamp = Time.now();
            details = details;
            severity = severity;
        };
        securityEvents := Array.append<LaunchpadTypes.SecurityEvent>(securityEvents, [securityEvent]);
    };

    private func _checkRateLimit(caller: Principal) : Bool {
        let now = Time.now();
        let minInterval: Time.Time = 1_000_000_000; // 1 second
        
        switch (Array.find<(Principal, Time.Time)>(lastParticipationTime, func((p, _)) { p == caller })) {
            case (?(_, lastTime)) {
                if (now - lastTime < minInterval) {
                    // Record rate limit violation
                    rateLimitViolations := Array.append<(Principal, Nat)>(rateLimitViolations, [(caller, 1)]);
                    _logSecurityEvent(#RateLimitViolation, caller, "Too many requests", #Medium);
                    return false;
                };
            };
            case null {};
        };
        
        // Update last participation time
        lastParticipationTime := Array.append<(Principal, Time.Time)>(lastParticipationTime, [(caller, now)]);
        true
    };

    private func _validateLargeTransaction(amount: Nat, caller: Principal) : Bool {
        let largeTransactionThreshold = config.saleParams.hardCap / 20; // 5% of hard cap
        
        if (amount > largeTransactionThreshold) {
            _logSecurityEvent(#LargeTransaction, caller, "Large transaction: " # Nat.toText(amount), #High);
            // Additional validation for large transactions
            let maxContribCheck = switch(config.saleParams.maxContribution) {
                case (?max) amount <= max;
                case null true;
            };
            return _isAuthorized(caller) or maxContribCheck;
        };
        true
    };

    // Emergency pause function
    public shared({caller}) func emergencyPause(reason: Text) : async Result.Result<(), Text> {
        if (not _isAuthorized(caller)) {
            _logSecurityEvent(#UnauthorizedAccess, caller, "Attempted emergency pause", #Critical);
            return #err("Unauthorized: Only authorized users can emergency pause");
        };

        emergencyPaused := true;
        emergencyReason := reason;
        lastEmergencyAction := Time.now();
        
        _logAdminAction("EMERGENCY_PAUSE", caller, reason, true, null);
        _logSecurityEvent(#EmergencyAction, caller, "Emergency pause activated: " # reason, #Critical);
        
        #ok(())
    };

    public shared({caller}) func emergencyUnpause() : async Result.Result<(), Text> {
        if (not _isAuthorized(caller)) {
            _logSecurityEvent(#UnauthorizedAccess, caller, "Attempted emergency unpause", #Critical);
            return #err("Unauthorized: Only authorized users can emergency unpause");
        };

        emergencyPaused := false;
        emergencyReason := "";
        lastEmergencyAction := Time.now();
        
        _logAdminAction("EMERGENCY_UNPAUSE", caller, "", true, null);
        _logSecurityEvent(#EmergencyAction, caller, "Emergency pause deactivated", #High);
        
        #ok(())
    };

    // Query security events (admin only)
    public query({caller}) func getSecurityEvents() : async Result.Result<[LaunchpadTypes.SecurityEvent], Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized: Only authorized users can view security events");
        };
        #ok(securityEvents)
    };

    // Query admin actions (admin only)
    public query({caller}) func getAdminActions() : async Result.Result<[LaunchpadTypes.AdminAction], Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized: Only authorized users can view admin actions");
        };
        #ok(adminActions)
    };
}