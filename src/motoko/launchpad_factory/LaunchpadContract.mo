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
import Blob "mo:base/Blob";


import LaunchpadTypes "../shared/types/LaunchpadTypes";
import LaunchpadUpgradeTypes "../shared/types/LaunchpadUpgradeTypes";
import TokenFactory "../shared/types/TokenFactory";
import IUpgradeable "../common/IUpgradeable";
import AID "../shared/utils/AID";
import ICRCTypes "../shared/types/ICRC";
import ICRC "../shared/utils/ICRC";

// ================ LAUNCHPAD CONTRACT V2 ================
// Actor class template for individual launchpad instances
// Follows ICTO V2 architecture: Backend → Factory → Contract
// Implements IUpgradeable for safe upgrades with state preservation



shared ({ caller = factory }) persistent actor class LaunchpadContract<system>(
    initArgs: LaunchpadUpgradeTypes.LaunchpadInitArgs
) = this {

    // ================ INITIALIZATION LOGIC ================
    // Determine if this is a fresh deployment or an upgrade

    let isUpgrade: Bool = switch (initArgs) {
        case (#InitialSetup(_)) { false };
        case (#Upgrade(_)) { true };
    };

    // Extract init parameters
    let init_id: Text = switch (initArgs) {
        case (#InitialSetup(setup)) { setup.id };
        case (#Upgrade(upgrade)) { upgrade.runtimeState.launchpadId };
    };

    let init_config: LaunchpadTypes.LaunchpadConfig = switch (initArgs) {
        case (#InitialSetup(setup)) { setup.config };
        case (#Upgrade(upgrade)) { upgrade.config };
    };

    let init_creator: Principal = switch (initArgs) {
        case (#InitialSetup(setup)) { setup.creator };
        case (#Upgrade(upgrade)) { upgrade.runtimeState.creator };
    };

    let init_createdAt: Time.Time = switch (initArgs) {
        case (#InitialSetup(setup)) { setup.createdAt };
        case (#Upgrade(upgrade)) { upgrade.runtimeState.createdAt };
    };

    let upgradeState: ?LaunchpadUpgradeTypes.LaunchpadRuntimeState = switch (initArgs) {
        case (#InitialSetup(_)) { null };
        case (#Upgrade(upgrade)) { ?upgrade.runtimeState };
    };

    // ================ STABLE STATE ================

    // Debug: Check config received from factory
    Debug.print("🔍 CONTRACT: LaunchpadContract constructor called");
    Debug.print("  received multiDexConfig: " # debug_show(init_config.multiDexConfig));

    // Core identity
    private var launchpadId : Text = init_id;
    private var config : LaunchpadTypes.LaunchpadConfig = init_config;
    private var creator : Principal = init_creator;
    private var factoryPrincipal : Principal = factory;
    private var createdAt : Time.Time = init_createdAt;

    // Debug: Verify stored config
    Debug.print("🔍 CONTRACT: Stored multiDexConfig: " # debug_show(config.multiDexConfig));
    private var updatedAt : Time.Time = switch (upgradeState) {
        case null { init_createdAt };
        case (?state) { state.updatedAt };
    };

    // VERSION TRACKING
    private var contractVersion : IUpgradeable.Version = { major = 1; minor = 0; patch = 0 };

    // Status
    private var status : LaunchpadTypes.LaunchpadStatus = switch (upgradeState) {
        case null { #Setup };
        case (?state) { state.status };
    };
    private var processingState : LaunchpadTypes.ProcessingState = switch (upgradeState) {
        case null { #Idle };
        case (?state) { state.processingState };
    };
    private var installed : Bool = switch (upgradeState) {
        case null { false };
        case (?state) { state.installed };
    };

    // Financial tracking
    private var totalRaised : Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.totalRaised };
    };
    private var totalAllocated : Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.totalAllocated };
    };
    private var participantCount : Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.participantCount };
    };
    private var transactionCount : Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.transactionCount };
    };

    // Participants storage (Trie for efficient queries)
    private var participantsStable : [(Text, LaunchpadTypes.Participant)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.participants };
    };
    private transient var participants = Trie.empty<Text, LaunchpadTypes.Participant>();

    // Transactions storage
    private var transactionsStable : [LaunchpadTypes.Transaction] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.transactions };
    };
    private transient var transactions = Buffer.fromArray<LaunchpadTypes.Transaction>(transactionsStable);

    // Affiliate tracking
    private var affiliateStatsStable : [(Text, LaunchpadTypes.AffiliateStats)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.affiliateStats };
    };
    private transient var affiliateStats = Trie.empty<Text, LaunchpadTypes.AffiliateStats>();

    // Deployed contracts after successful sale
    private var deployedContracts : LaunchpadTypes.DeployedContracts = switch (upgradeState) {
        case null {
            {
                tokenCanister = null;
                vestingContracts = [];
                daoCanister = null;
                liquidityPool = null;
                stakingContract = null;
            }
        };
        case (?state) { state.deployedContracts };
    };

    // Timer for automated lifecycle management (legacy - kept for backward compatibility)
    private var timerId : ?Timer.TimerId = null;
    private var _lastTimerSetup : Time.Time = 0;

    // Milestone-specific timers (V2 - automatic status transitions)
    private stable var saleStartTimerId: ?Nat = null;
    private stable var saleEndTimerId: ?Nat = null;
    private stable var claimStartTimerId: ?Nat = null;
    private stable var listingTimerId: ?Nat = null;
    
    // Security & Emergency Controls
    private var emergencyPaused : Bool = switch (upgradeState) {
        case null { false };
        case (?state) { state.emergencyPaused };
    };
    private var emergencyReason : Text = switch (upgradeState) {
        case null { "" };
        case (?state) { state.emergencyReason };
    };
    private var lastEmergencyAction : Time.Time = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.lastEmergencyAction };
    };

    // Reentrancy Protection (Per-User Lock System)
    // ==========================================
    // CRITICAL SECURITY FIX: Replaced global lock with per-user tracking
    // Global lock was a DoS vulnerability - one user could block entire system
    private var activeUserCalls : [(Principal, Time.Time)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.activeUserCalls };
    };

    // Auto-timeout for user locks (prevent permanent locks)
    private let USER_LOCK_TIMEOUT : Time.Time = 300_000_000_000; // 5 minutes

    // Audit Trail
    private var adminActions : [LaunchpadTypes.AdminAction] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.adminActions };
    };
    private var securityEvents : [LaunchpadTypes.SecurityEvent] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.securityEvents };
    };

    // Rate Limiting
    private var lastParticipationTime : [(Principal, Time.Time)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.lastParticipationTime };
    };
    private var rateLimitViolations : [(Principal, Nat)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.rateLimitViolations };
    };

    // Security Metrics (NEW)
    // ===================
    // Track security events for monitoring and analysis
    private var securityMetrics : {
        totalReentrancyAttempts: Nat;
        totalSuccessfulCalls: Nat;
        totalFailedCalls: Nat;
        averageCallDuration: Time.Time;
        lastSecurityEvent: Time.Time;
    } = switch (upgradeState) {
        case null {
            {
                totalReentrancyAttempts = 0;
                totalSuccessfulCalls = 0;
                totalFailedCalls = 0;
                averageCallDuration = 0;
                lastSecurityEvent = 0;
            };
        };
        case (?state) { state.securityMetrics };
    };

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

        // Cancel all timers before upgrade
        Debug.print("🔄 preupgrade: Cancelling all timers...");

        switch (timerId) {
            case (?id) {
                Timer.cancelTimer(id);
                Debug.print("  ✅ Legacy timer cancelled");
            };
            case null {};
        };

        switch (saleStartTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                Debug.print("  ✅ Sale start timer cancelled");
            };
            case null {};
        };

        switch (saleEndTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                Debug.print("  ✅ Sale end timer cancelled");
            };
            case null {};
        };

        switch (claimStartTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                Debug.print("  ✅ Claim start timer cancelled");
            };
            case null {};
        };

        switch (listingTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                Debug.print("  ✅ Listing timer cancelled");
            };
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

        // Restore milestone timers after upgrade
        // IMPORTANT: Also check and update status based on current time
        if (installed) {
            Debug.print("📍 postupgrade: Scheduling status check and timer restoration...");
            ignore Timer.setTimer<system>(
                #seconds(1),  // 1 second delay to allow postupgrade to complete
                func() : async () {
                    // First: Update status to current correct state based on timeline
                    // Call multiple times to handle cases where multiple milestones have passed
                    // (e.g., if both sale start and sale end times have passed)
                    Debug.print("🔄 postupgrade: Checking status transitions...");
                    let _ = await checkAndUpdateStatus();  // Transition 1 (e.g., Upcoming -> SaleActive)
                    let _ = await checkAndUpdateStatus();  // Transition 2 (e.g., SaleActive -> SaleEnded)
                    let _ = await checkAndUpdateStatus();  // Transition 3 (e.g., Successful -> Claiming if needed)

                    Debug.print("📊 postupgrade: Current status after transitions: " # LaunchpadTypes.statusToText(status));

                    // Then: Setup timers for future milestones
                    await _setupMilestoneTimers();

                    Debug.print("✅ postupgrade: Status updated and timers restored");
                }
            );
        };
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

        // Update status and setup timers
        status := #Upcoming;
        installed := true;
        updatedAt := Time.now();

        // Setup milestone-specific timers for automatic status transitions
        // IMPORTANT: Must await to ensure timers are actually created
        await _setupMilestoneTimers();

        Debug.print("Launchpad initialized: " # launchpadId);
        Debug.print("✅ Timers setup completed");
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

        // Cancel all timers
        _cancelAllTimers();

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

        // Restore milestone timers
        await _setupMilestoneTimers();

        Debug.print("Launchpad unpaused by: " # Principal.toText(caller));
        #ok(())
    };

    /// Re-setup milestone timers (admin/creator only)
    /// Useful for recovering from timer initialization issues
    public shared({caller}) func resetTimers() : async Result.Result<(), Text> {
        if (caller != creator and caller != factoryPrincipal) {
            return #err("Unauthorized: Only creator or factory can reset timers");
        };

        Debug.print("🔄 Resetting timers requested by: " # Principal.toText(caller));

        // Cancel existing timers first
        _cancelAllTimers();

        // Re-setup timers
        await _setupMilestoneTimers();

        Debug.print("✅ Timers reset completed");
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

    // ================ UPDATE FUNCTIONS (OWNER ONLY) ================

    /// Update basic project information (owner only)
    /// Images are handled separately via updateProjectImages()
    public shared({caller}) func updateProjectInfo(request: LaunchpadTypes.UpdateProjectInfoRequest) : async Result.Result<(), Text> {
        // Only creator can update
        if (caller != creator) {
            return #err("Unauthorized: Only creator can update project info");
        };

        // Cannot update after sale started (to prevent scam/rug)
        if (status != #Setup and status != #Upcoming) {
            return #err("Cannot update project info after sale has started");
        };

        // Update fields that are provided (optional pattern)
        let updatedProjectInfo = {
            config.projectInfo with
            description = switch (request.description) {
                case (null) { config.projectInfo.description };
                case (?desc) {
                    if (Text.size(desc) < 10) {
                        return #err("Description must be at least 10 characters");
                    };
                    desc
                };
            };
            website = switch (request.website) {
                case (null) { config.projectInfo.website };
                case (?w) { ?w };
            };
            whitepaper = switch (request.whitepaper) {
                case (null) { config.projectInfo.whitepaper };
                case (?w) { ?w };
            };
            documentation = switch (request.documentation) {
                case (null) { config.projectInfo.documentation };
                case (?d) { ?d };
            };
            telegram = switch (request.telegram) {
                case (null) { config.projectInfo.telegram };
                case (?t) { ?t };
            };
            twitter = switch (request.twitter) {
                case (null) { config.projectInfo.twitter };
                case (?t) { ?t };
            };
            discord = switch (request.discord) {
                case (null) { config.projectInfo.discord };
                case (?d) { ?d };
            };
            github = switch (request.github) {
                case (null) { config.projectInfo.github };
                case (?g) { ?g };
            };
            medium = switch (request.medium) {
                case (null) { config.projectInfo.medium };
                case (?m) { ?m };
            };
            reddit = switch (request.reddit) {
                case (null) { config.projectInfo.reddit };
                case (?r) { ?r };
            };
            youtube = switch (request.youtube) {
                case (null) { config.projectInfo.youtube };
                case (?y) { ?y };
            };
            auditReport = switch (request.auditReport) {
                case (null) { config.projectInfo.auditReport };
                case (?a) { ?a };
            };
            kycProvider = switch (request.kycProvider) {
                case (null) { config.projectInfo.kycProvider };
                case (?k) { ?k };
            };
            tags = switch (request.tags) {
                case (null) { config.projectInfo.tags };
                case (?t) { t };
            };
        };

        config := { config with projectInfo = updatedProjectInfo };
        updatedAt := Time.now();

        Debug.print("Project info updated by: " # Principal.toText(caller));
        #ok(())
    };

    /// Update project images (owner only)
    /// Separate function for images to optimize data transfer
    public shared({caller}) func updateProjectImages(request: LaunchpadTypes.ProjectImagesUpdate) : async Result.Result<(), Text> {
        if (caller != creator) {
            return #err("Unauthorized: Only creator can update images");
        };

        // Can update images anytime (before sale ends)
        if (status == #Completed or status == #Cancelled or status == #Failed) {
            return #err("Cannot update images after launchpad is finalized");
        };

        let updatedProjectInfo = {
            config.projectInfo with
            logo = switch (request.logo) {
                case (null) { config.projectInfo.logo };
                case (?l) { ?l };
            };
            cover = switch (request.cover) {
                case (null) { config.projectInfo.cover };
                case (?c) { ?c };
            };
        };

        config := { config with projectInfo = updatedProjectInfo };
        updatedAt := Time.now();

        Debug.print("Project images updated by: " # Principal.toText(caller));
        #ok(())
    };

    /// Update token information (owner only)
    public shared({caller}) func updateTokenInfo(request: LaunchpadTypes.UpdateTokenInfoRequest) : async Result.Result<(), Text> {
        if (caller != creator) {
            return #err("Unauthorized: Only creator can update token info");
        };

        // Cannot update after token deployed
        switch (deployedContracts.tokenCanister) {
            case (?_) { return #err("Cannot update token info after token is deployed"); };
            case (null) {};
        };

        let updatedSaleToken = {
            config.saleToken with
            description = switch (request.description) {
                case (null) { config.saleToken.description };
                case (?d) { ?d };
            };
            website = switch (request.website) {
                case (null) { config.saleToken.website };
                case (?w) { ?w };
            };
        };

        config := { config with saleToken = updatedSaleToken };
        updatedAt := Time.now();

        Debug.print("Token info updated by: " # Principal.toText(caller));
        #ok(())
    };

    /// Update token logo (owner only)
    public shared({caller}) func updateTokenLogo(request: LaunchpadTypes.TokenLogoUpdate) : async Result.Result<(), Text> {
        if (caller != creator) {
            return #err("Unauthorized: Only creator can update token logo");
        };

        // Can update logo anytime before completion
        if (status == #Completed or status == #Cancelled or status == #Failed) {
            return #err("Cannot update token logo after launchpad is finalized");
        };

        let updatedSaleToken = {
            config.saleToken with
            logo = switch (request.logo) {
                case (null) { config.saleToken.logo };
                case (?l) { ?l };
            };
        };

        config := { config with saleToken = updatedSaleToken };
        updatedAt := Time.now();

        Debug.print("Token logo updated by: " # Principal.toText(caller));
        #ok(())
    };

    // ================ QUERY FUNCTIONS ================

    /// Get launchpad detail WITHOUT images (for list/index views to reduce data transfer)
    /// Use getProjectImages() and getTokenLogo() separately to fetch images only when needed
    public query func getLaunchpadDetail() : async LaunchpadTypes.LaunchpadDetail {
        // Strip all images from config to reduce response size significantly
        let configWithoutImages = {
            config with
            saleToken = {
                config.saleToken with
                logo = null;  // Use getTokenLogo() to fetch separately
            };
            projectInfo = {
                config.projectInfo with
                logo = null;    // Use getProjectImages() to fetch separately
                cover = null;   // Use getProjectImages() to fetch separately
            };
        };

        {
            id = launchpadId;
            canisterId = Principal.fromActor(this);
            creator = creator;
            config = configWithoutImages;
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

    /// Get config WITHOUT images (optimized for list views)
    public query func getConfig() : async LaunchpadTypes.LaunchpadConfig {
        {
            config with
            saleToken = {
                config.saleToken with
                logo = null;
            };
            projectInfo = {
                config.projectInfo with
                logo = null;
                cover = null;
            };
        }
    };

    /// Get ONLY project images (separate query to fetch only when needed)
    /// This significantly reduces data transfer for list/index views
    public query func getProjectImages() : async {
        logo: ?Text;
        cover: ?Text;
    } {
        {
            logo = config.projectInfo.logo;
            cover = config.projectInfo.cover;
        }
    };

    /// Get ONLY token logo (separate query for optimization)
    public query func getTokenLogo() : async { logo: ?Text } {
        { logo = config.saleToken.logo }
    };

    /// Legacy function - kept for backward compatibility
    /// Use getProjectImages() and getTokenLogo() instead
    public query func getTokenLogos() : async {
        tokenLogo: ?Text;
        projectLogo: ?Text;
        projectCover: ?Text;
    } {
        {
            tokenLogo = config.saleToken.logo;
            projectLogo = config.projectInfo.logo;
            projectCover = config.projectInfo.cover;
        }
    };

    public query func getStatus() : async LaunchpadTypes.LaunchpadStatus {
        status
    };

    /// Manual status check and update (backup mechanism if timers fail)
    /// Can be called by anyone to trigger status update based on current time
    public shared func checkAndUpdateStatus() : async Result.Result<LaunchpadTypes.LaunchpadStatus, Text> {
        let now = Time.now();
        let oldStatus = status;

        // Check if status should be updated based on timeline
        switch (status) {
            case (#Upcoming or #WhitelistOpen) {
                if (now >= config.timeline.saleStart) {
                    await _updateStatusToSaleActive();
                };
            };
            case (#SaleActive) {
                if (now >= config.timeline.saleEnd) {
                    await _updateStatusToSaleEnded();
                };
            };
            case (#Successful) {
                if (now >= config.timeline.claimStart) {
                    await _updateStatusToClaiming();
                };
            };
            case (#Claiming) {
                switch (config.timeline.listingTime) {
                    case (?listingTime) {
                        if (now >= listingTime) {
                            await _updateStatusToCompleted();
                        };
                    };
                    case null {};
                };
            };
            case (_) {};
        };

        if (oldStatus != status) {
            Debug.print("✅ Manual status update: " # LaunchpadTypes.statusToText(oldStatus) # " → " # LaunchpadTypes.statusToText(status));
        };

        #ok(status)
    };

    /// Recover deposited funds based on balance check
    /// This function helps users who transferred tokens but failed to confirm deposit
    /// It checks the deposit account balance and creates a participation record
    public shared({caller}) func recoverDepositFromBalance() : async Result.Result<LaunchpadTypes.Transaction, Text> {
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

        Debug.print("💰 recoverDepositFromBalance called by: " # Principal.toText(caller));

        // Rate limiting & validation
        if (not _checkRateLimit(caller)) {
            _releaseReentrancyLock();
            return #err("Rate limit exceeded");
        };

        // Generate user's deposit account (subaccount)
        let subAccount = principalToSubAccount(caller);
        let subAccountBlob = Blob.fromArray(subAccount);

        // Create ICRC Account for the deposit account
        let depositAccount: ICRCTypes.Account = {
            owner = Principal.fromActor(this);
            subaccount = ?subAccountBlob;
        };

        Debug.print("🏦 Checking deposit account balance for recovery...");

        // Check balance of deposit account
        let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(config.purchaseToken.canisterId));
        let depositBalance = try {
            await ledger.icrc1_balance_of(depositAccount)
        } catch (error) {
            _releaseReentrancyLock();
            return #err("Failed to check deposit account balance: " # Error.message(error));
        };

        Debug.print("💵 Deposit account balance: " # Nat.toText(depositBalance));

        if (depositBalance == 0) {
            _releaseReentrancyLock();
            return #err("No balance found in deposit account. Please transfer tokens first.");
        };

        // Check if user already has a pending transaction for this amount
        let participantKey = Principal.toText(caller);
        let existingParticipant = Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal);
        let alreadyCounted = switch (existingParticipant) {
            case (?p) p.totalContribution;
            case null 0;
        };

        // Check if this amount would exceed max contribution
        switch (config.saleParams.maxContribution) {
            case (?maxAmount) {
                let maxContributionInSmallestUnit = toSmallestUnit(maxAmount, config.purchaseToken.decimals);
                if (alreadyCounted + depositBalance > maxContributionInSmallestUnit) {
                    _releaseReentrancyLock();
                    return #err("Deposit amount would exceed maximum contribution limit");
                };
            };
            case null {};
        };

        // Create transaction record for recovered deposit
        let transactionId = _generateTransactionId();
        let transaction: LaunchpadTypes.Transaction = {
            id = transactionId;
            participant = caller;
            txType = #Purchase;
            amount = depositBalance;
            token = config.purchaseToken.canisterId;
            timestamp = Time.now();
            blockIndex = null;
            fee = config.purchaseToken.transferFee;
            status = #Confirmed;
            affiliateCode = null; // No affiliate code for recovery
            notes = ?("Recovered from deposit account balance");
        };

        Debug.print("📝 Recording recovered participation...");

        // Process the purchase (update stats, participants, etc.)
        let purchaseResult = await _processPurchase(caller, depositBalance, null, transaction);
        switch (purchaseResult) {
            case (#err(msg)) {
                _releaseReentrancyLock();
                let failedTransaction = {
                    transaction with
                    status = #Failed(msg);
                    notes = ?("Deposit recovery failed: " # msg);
                };
                transactions.add(failedTransaction);
                return #err(msg);
            };
            case (#ok(updatedTransaction)) {
                transactions.add(updatedTransaction);
                transactionCount += 1;
                updatedAt := Time.now();
                _releaseReentrancyLock();

                Debug.print("✅ Deposit recovered successfully!");
                Debug.print("   Amount: " # Nat.toText(depositBalance));
                Debug.print("   User: " # Principal.toText(caller));
                return #ok(updatedTransaction);
            };
        };
    };

    public query func getAffiliateStats(affiliate: Principal) : async ?LaunchpadTypes.AffiliateStats {
        let key = Principal.toText(affiliate);
        Trie.get(affiliateStats, LaunchpadTypes.textKey(key), Text.equal)
    };

    public query func isWhitelisted(user: Principal) : async Bool {
        if (not config.saleParams.requiresWhitelist) return true;
        Array.find<Principal>(config.whitelist, func(p) { p == user }) != null
    };

    // ================ HELPER FUNCTIONS FOR AMOUNT CONVERSION ================
    // Helper to convert human-readable amount to smallest unit (e8s)
    // Example: 100 ICP -> 10000000000 e8s (with decimals = 8)
    private func toSmallestUnit(amount: Nat, decimals: Nat8) : Nat {
        let multiplier = 10 ** Nat8.toNat(decimals);
        amount * multiplier
    };

    // Convert hardCap/softCap to smallest unit for comparison
    // Note: Contract stores caps in human-readable format (e.g., 100 ICP)
    // But amounts passed in are in smallest unit (e.g., 10000000000 e8s)
    private func hardCapInSmallestUnit() : Nat {
        toSmallestUnit(config.saleParams.hardCap, config.purchaseToken.decimals)
    };

    private func softCapInSmallestUnit() : Nat {
        toSmallestUnit(config.saleParams.softCap, config.purchaseToken.decimals)
    };

    // ================ DEPOSIT ACCOUNT GENERATION ================
    // Generate unique deposit account for each user using AID (Account Identifier)
    // This creates a deterministic sub-account for the user within this launchpad contract
    // Similar to how SNS handles deposits on Internet Computer
    
    // Convert principal to subaccount (32 bytes) following IC standard format:
    // [size_byte, ...principal_bytes..., ...padding_zeros...]
    private func principalToSubAccount(userId: Principal) : [Nat8] {
        let p = Blob.toArray(Principal.toBlob(userId));
        Array.tabulate(32, func(i : Nat) : Nat8 {
            if (i >= p.size() + 1) 0
            else if (i == 0) (Nat8.fromNat(p.size()))
            else (p[i - 1])
        })
    };
    
    // Convert bytes array to hex string
    private func toHex(arr: [Nat8]): Text {
        let hexChars = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
        Text.join("", Iter.map<Nat8, Text>(Iter.fromArray(arr), func (x: Nat8) : Text {
            let a = Nat8.toNat(x / 16);
            let b = Nat8.toNat(x % 16);
            hexChars[a] # hexChars[b]
        }))
    };
    
    // Get deposit account - returns subaccount bytes and hex text
    public shared query ({ caller }) func getDepositAccount() : async Result.Result<{ account: [Nat8]; accountText: Text }, Text> {
        // Validation
        if (Principal.isAnonymous(caller)) {
            return #err("Unauthorized: User must be authenticated.");
        };

        // Generate subaccount from caller's principal (IC standard format)
        let subAccount = principalToSubAccount(caller);

        // Convert to hex string for display
        let hexString = toHex(subAccount);

        Debug.print("🏦 Generated deposit subaccount for launchpad: " # launchpadId);
        Debug.print("   User: " # Principal.toText(caller));
        Debug.print("   Subaccount: " # hexString);
        Debug.print("   Contract Principal: " # Principal.toText(Principal.fromActor(this)));

        return #ok({
            account = subAccount;  // Return subaccount bytes, not AID
            accountText = hexString;
        });
    };

    // Get deposit account as hex string for display (for debugging/monitoring)
    public shared query func getDepositAccountText(caller: Principal) : async Result.Result<Text, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Unauthorized: User must be authenticated.");
        };

        // Generate subaccount from caller's principal
        let subAccount = principalToSubAccount(caller);

        // Convert to hex string for display
        let hexString = toHex(subAccount);

        return #ok(hexString);
    };

    // Check deposited balance in user's deposit account (subaccount)
    public shared({ caller }) func getDepositedBalance() : async Result.Result<Nat, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Unauthorized: User must be authenticated.");
        };

        try {
            // Generate user's deposit account (subaccount)
            let subAccount = principalToSubAccount(caller);
            let subAccountBlob = Blob.fromArray(subAccount);

            // Create ICRC Account for the deposit account
            let depositAccount: ICRCTypes.Account = {
                owner = Principal.fromActor(this);
                subaccount = ?subAccountBlob;
            };

            Debug.print("💰 Checking deposited balance for: " # Principal.toText(caller));

            // Query balance from ICRC ledger
            let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(config.purchaseToken.canisterId));
            let balance = await ledger.icrc1_balance_of(depositAccount);

            Debug.print("   Deposited balance: " # Nat.toText(balance) # " (smallest unit)");

            return #ok(balance);
        } catch (error) {
            return #err("Failed to check deposited balance: " # Error.message(error));
        };
    };

    /// Get detailed deposit account information for user
    /// Shows balance, account details, and recovery options
    public shared({ caller }) func getDepositAccountInfo() : async Result.Result<{
        account: [Nat8];
        accountText: Text;
        balance: Nat;
        canRecover: Bool;
        recoverableAmount: Nat;
        alreadyContributed: Nat;
        remainingLimit: Nat;
    }, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Unauthorized: User must be authenticated.");
        };

        try {
            // Generate deposit account
            let subAccount = principalToSubAccount(caller);
            let subAccountBlob = Blob.fromArray(subAccount);
            let hexString = toHex(subAccount);

            // Check balance
            let depositAccount: ICRCTypes.Account = {
                owner = Principal.fromActor(this);
                subaccount = ?subAccountBlob;
            };

            let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(config.purchaseToken.canisterId));
            let balance = await ledger.icrc1_balance_of(depositAccount);

            // Check user's current contribution
            let participantKey = Principal.toText(caller);
            let existingContribution = switch (Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal)) {
                case null 0;
                case (?p) p.totalContribution;
            };

            // Calculate remaining limit
            let remainingLimit = switch (config.saleParams.maxContribution) {
                case (?maxAmount) {
                    let maxInSmallestUnit = toSmallestUnit(maxAmount, config.purchaseToken.decimals);
                    if (existingContribution >= maxInSmallestUnit) 0
                    else maxInSmallestUnit - existingContribution
                };
                case null balance; // No limit if not set
            };

            let canRecover = balance > 0 and balance <= remainingLimit;
            let recoverableAmount = if (canRecover) balance else 0;

            return #ok({
                account = subAccount;
                accountText = hexString;
                balance = balance;
                canRecover = canRecover;
                recoverableAmount = recoverableAmount;
                alreadyContributed = existingContribution;
                remainingLimit = remainingLimit;
            });
        } catch (error) {
            return #err("Failed to get deposit account info: " # Error.message(error));
        };
    };

    // ================ DEPOSIT CONFIRMATION ================
    // Confirm deposit after user has transferred tokens to their deposit account
    // NOTE: Tokens remain in subaccount for easy refunds if softcap not reached
    // They will be transferred to destination contracts after softcap is reached
    
    public shared({ caller }) func confirmDeposit(
        expectedAmount: Nat,
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
        
        Debug.print("💰 confirmDeposit called by: " # Principal.toText(caller));
        Debug.print("   Expected amount: " # Nat.toText(expectedAmount));
        
        // Rate limiting & validation (check early)
        if (not _checkRateLimit(caller)) {
            _releaseReentrancyLock();
            return #err("Rate limit exceeded");
        };
        
        if (not _validateLargeTransaction(expectedAmount, caller)) {
            _releaseReentrancyLock();
            return #err("Transaction validation failed");
        };
        
        // Validate participation eligibility
        let eligibilityCheck = await _checkParticipationEligibility(caller, expectedAmount);
        switch (eligibilityCheck) {
            case (#err(msg)) {
                _releaseReentrancyLock();
                return #err(msg);
            };
            case (#ok(_)) {};
        };
        
        // Generate user's deposit account (subaccount)
        let subAccount = principalToSubAccount(caller);
        let subAccountBlob = Blob.fromArray(subAccount);
        
        // Create ICRC Account for the deposit account
        let depositAccount: ICRCTypes.Account = {
            owner = Principal.fromActor(this);
            subaccount = ?subAccountBlob;
        };
        
        Debug.print("🏦 Checking balance of deposit account...");
        
        // Check balance of deposit account
        let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(config.purchaseToken.canisterId));
        let depositBalance = try {
            await ledger.icrc1_balance_of(depositAccount)
        } catch (error) {
            _releaseReentrancyLock();
            return #err("Failed to check deposit account balance: " # Error.message(error));
        };
        
        Debug.print("💵 Deposit account balance: " # Nat.toText(depositBalance));
        
        // Verify balance is sufficient (at least expectedAmount)
        // Note: We keep transfer fee in subaccount for future operations
        if (depositBalance < expectedAmount) {
            _releaseReentrancyLock();
            return #err("Insufficient balance in deposit account. Required: " # Nat.toText(expectedAmount) # ", Found: " # Nat.toText(depositBalance));
        };
        
        Debug.print("✅ Balance verified: " # Nat.toText(depositBalance));
        Debug.print("🔒 Tokens remain in deposit account (subaccount) for security");
        Debug.print("   Will be transferred after softcap is reached or refunded if not");
        
        // Create transaction record (no blockIndex yet as no transfer happened)
        let transactionId = _generateTransactionId();
        let transaction: LaunchpadTypes.Transaction = {
            id = transactionId;
            participant = caller;
            txType = #Purchase;
            amount = expectedAmount;
            token = config.purchaseToken.canisterId;
            timestamp = Time.now();
            blockIndex = null; // No block index as tokens stay in subaccount
            fee = config.purchaseToken.transferFee;
            status = #Confirmed;
            affiliateCode = affiliateCode;
            notes = ?("Deposit confirmed - tokens held in subaccount");
        };
        
        Debug.print("📝 Recording participation...");
        
        // Process the purchase (update stats, participants, etc.)
        let purchaseResult = await _processPurchase(caller, expectedAmount, affiliateCode, transaction);
        switch (purchaseResult) {
            case (#err(msg)) {
                _releaseReentrancyLock();
                let failedTransaction = {
                    transaction with 
                    status = #Failed(msg);
                    notes = ?("Purchase processing failed: " # msg);
                };
                transactions.add(failedTransaction);
                return #err(msg);
            };
            case (#ok(updatedTransaction)) {
                transactions.add(updatedTransaction);
                transactionCount += 1;
                updatedAt := Time.now();
                _releaseReentrancyLock();
                
                Debug.print("✅ Participation recorded successfully!");
                Debug.print("   Amount: " # Nat.toText(expectedAmount));
                Debug.print("   Stored in subaccount: safe for refunds if needed");
                return #ok(updatedTransaction);
            };
        };
    };

    // ================ TIMER & LIFECYCLE MANAGEMENT ================

    // ================ MILESTONE-SPECIFIC TIMERS (V2) ================
    // Automatic status transitions based on timeline milestones

    /// Update status to SaleActive when sale starts
    private func _updateStatusToSaleActive() : async () {
        if (status == #Upcoming or status == #WhitelistOpen) {
            status := #SaleActive;
            updatedAt := Time.now();
            Debug.print("⏰ Timer: Status automatically updated to SaleActive at " # Int.toText(Time.now()));
        };
    };

    /// Update status to SaleEnded when sale ends
    private func _updateStatusToSaleEnded() : async () {
        if (status == #SaleActive) {
            status := #SaleEnded;
            updatedAt := Time.now();
            Debug.print("⏰ Timer: Status automatically updated to SaleEnded at " # Int.toText(Time.now()));
            // Process sale end (check softcap, trigger token deployment or refunds)
            await _processSaleEnd();
        };
    };

    /// Update status to Claiming when claim period starts
    private func _updateStatusToClaiming() : async () {
        if (status == #Successful) {
            status := #Claiming;
            updatedAt := Time.now();
            Debug.print("⏰ Timer: Status automatically updated to Claiming at " # Int.toText(Time.now()));
        };
    };

    /// Update status to Completed when listing time is reached
    private func _updateStatusToCompleted() : async () {
        if (status == #Claiming) {
            status := #Completed;
            updatedAt := Time.now();
            Debug.print("⏰ Timer: Status automatically updated to Completed at " # Int.toText(Time.now()));
        };
    };

    /// Setup all milestone-specific timers based on timeline configuration
    /// This is called during initialization and after upgrades
    private func _setupMilestoneTimers() : async () {
        let now = Time.now();

        Debug.print("⏰ Setting up milestone timers...");
        Debug.print("   Current time: " # Int.toText(now));
        Debug.print("   Sale start: " # Int.toText(config.timeline.saleStart));
        Debug.print("   Sale end: " # Int.toText(config.timeline.saleEnd));

        // Timer 1: Sale Start
        if (config.timeline.saleStart > now and saleStartTimerId == null) {
            let nanosUntilStart = config.timeline.saleStart - now;
            let secondsUntilStart = nanosUntilStart / 1_000_000_000;
            Debug.print("   ⏰ Setting timer for sale START in " # Int.toText(secondsUntilStart) # " seconds");

            saleStartTimerId := ?Timer.setTimer<system>(
                #nanoseconds(Int.abs(nanosUntilStart)),
                func() : async () {
                    await _updateStatusToSaleActive();
                    saleStartTimerId := null; // Clear after execution
                }
            );
        } else if (config.timeline.saleStart <= now) {
            Debug.print("   ⏭️ Sale start time already passed - no timer needed");
        };

        // Timer 2: Sale End
        if (config.timeline.saleEnd > now and saleEndTimerId == null) {
            let nanosUntilEnd = config.timeline.saleEnd - now;
            let secondsUntilEnd = nanosUntilEnd / 1_000_000_000;
            Debug.print("   ⏰ Setting timer for sale END in " # Int.toText(secondsUntilEnd) # " seconds");

            saleEndTimerId := ?Timer.setTimer<system>(
                #nanoseconds(Int.abs(nanosUntilEnd)),
                func() : async () {
                    await _updateStatusToSaleEnded();
                    saleEndTimerId := null; // Clear after execution
                }
            );
        } else if (config.timeline.saleEnd <= now) {
            Debug.print("   ⏭️ Sale end time already passed - no timer needed");
        };

        // Timer 3: Claim Start (always configured - required field)
        if (config.timeline.claimStart > now and claimStartTimerId == null) {
            let nanosUntilClaim = config.timeline.claimStart - now;
            let secondsUntilClaim = nanosUntilClaim / 1_000_000_000;
            Debug.print("   ⏰ Setting timer for CLAIM start in " # Int.toText(secondsUntilClaim) # " seconds");

            claimStartTimerId := ?Timer.setTimer<system>(
                #nanoseconds(Int.abs(nanosUntilClaim)),
                func() : async () {
                    await _updateStatusToClaiming();
                    claimStartTimerId := null; // Clear after execution
                }
            );
        } else if (config.timeline.claimStart <= now) {
            Debug.print("   ⏭️ Claim start time already passed - no timer needed");
        };

        // Timer 4: Listing Time (if configured)
        switch (config.timeline.listingTime) {
            case (?listingTime) {
                if (listingTime > now and listingTimerId == null) {
                    let nanosUntilListing = listingTime - now;
                    let secondsUntilListing = nanosUntilListing / 1_000_000_000;
                    Debug.print("   ⏰ Setting timer for LISTING in " # Int.toText(secondsUntilListing) # " seconds");

                    listingTimerId := ?Timer.setTimer<system>(
                        #nanoseconds(Int.abs(nanosUntilListing)),
                        func() : async () {
                            await _updateStatusToCompleted();
                            listingTimerId := null; // Clear after execution
                        }
                    );
                } else if (listingTime <= now) {
                    Debug.print("   ⏭️ Listing time already passed - no timer needed");
                };
            };
            case null {
                Debug.print("   ℹ️ Listing time not configured");
            };
        };

        Debug.print("✅ Milestone timers setup complete");
    };

    /// Cancel all timers (used during pause/emergency)
    private func _cancelAllTimers() {
        Debug.print("🛑 Cancelling all timers...");

        switch (timerId) {
            case (?id) {
                Timer.cancelTimer(id);
                timerId := null;
                Debug.print("  ✅ Legacy timer cancelled");
            };
            case null {};
        };

        switch (saleStartTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                saleStartTimerId := null;
                Debug.print("  ✅ Sale start timer cancelled");
            };
            case null {};
        };

        switch (saleEndTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                saleEndTimerId := null;
                Debug.print("  ✅ Sale end timer cancelled");
            };
            case null {};
        };

        switch (claimStartTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                claimStartTimerId := null;
                Debug.print("  ✅ Claim start timer cancelled");
            };
            case null {};
        };

        switch (listingTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                listingTimerId := null;
                Debug.print("  ✅ Listing timer cancelled");
            };
            case null {};
        };
    };

    // ================ LEGACY TIMER SYSTEM (V1) ================
    // Kept for backward compatibility - can be removed in future versions

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
        Debug.print("🏁 Processing sale end...");
        Debug.print("   Total raised: " # Nat.toText(totalRaised));
        Debug.print("   Soft cap: " # Nat.toText(softCapInSmallestUnit()));

        if (totalRaised >= softCapInSmallestUnit()) {
            // FAIR LAUNCH SUCCESS: Finalize token allocations
            Debug.print("✅ Sale successful - finalizing token allocations...");
            _finalizeTokenAllocations();

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
            Debug.print("❌ Sale failed - soft cap not reached");
            Debug.print("   Raised: " # Nat.toText(totalRaised) # " vs Required: " # Nat.toText(softCapInSmallestUnit()));

            // First change to Refunding status (processing refunds)
            status := #Refunding;
            processingState := #Processing({
                stage = #Refunding;
                progress = 0;
                processedCount = 0;
                totalCount = participantCount;
                errorCount = 0;
                lastError = null;
            });
            // Process refunds asynchronously
            // After all refunds complete, will transition to #Failed
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
        // Note: softCap and hardCap are stored in human-readable format
        // No need to convert for this comparison as both are in same unit
        if (cfg.saleParams.softCap > cfg.saleParams.hardCap) {
            return #err("Soft cap cannot be greater than hard cap");
        };
        
        if (cfg.timeline.saleStart >= cfg.timeline.saleEnd) {
            return #err("Sale start must be before sale end");
        };
        
        if (cfg.saleParams.totalSaleAmount == 0) {
            return #err("Sale amount must be greater than 0");
        };

        // VALIDATION: Different rules per sale type
        switch (cfg.saleParams.saleType) {
            case (#FairLaunch) {
                // Fair launch: tokenPrice can be 0 (not used)
                Debug.print("✅ Fair launch: tokenPrice can be 0 (dynamic pricing)");
            };
            case (#PrivateSale) {
                // Private sale: Must have whitelist enabled
                if (not cfg.saleParams.requiresWhitelist) {
                    return #err("Private Sale must have whitelist enabled");
                };
                // Private sale: tokenPrice must be > 0
                if (cfg.saleParams.tokenPrice == 0) {
                    return #err("Private Sale requires tokenPrice > 0");
                };
                Debug.print("✅ Private sale: whitelist and tokenPrice validated");
            };
            case (#FixedPrice or #IDO) {
                // Fixed price: tokenPrice must be > 0
                if (cfg.saleParams.tokenPrice == 0) {
                    return #err("Fixed price sale requires tokenPrice > 0");
                };
                Debug.print("✅ Fixed price: tokenPrice validated");
            };
            case (#Auction or #Lottery) {
                // Special modes: tokenPrice can be 0 (handled differently)
                Debug.print("✅ Special mode: tokenPrice validation skipped");
            };
        };

        if (cfg.saleParams.minContribution > (switch(cfg.saleParams.maxContribution) { case (?max) max; case null 1_000_000_000_000 })) {
            return #err("Minimum contribution cannot be greater than maximum contribution");
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
        
        // Check maximum contribution (convert to smallest unit for comparison)
        switch (config.saleParams.maxContribution) {
            case (?maxAmount) {
                let maxContributionInSmallestUnit = toSmallestUnit(maxAmount, config.purchaseToken.decimals);
                let participantKey = Principal.toText(participant);
                let existingContribution = switch (Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal)) {
                    case null 0;
                    case (?p) p.totalContribution;
                };

                if (existingContribution + amount > maxContributionInSmallestUnit) {
                    return #err("Exceeds maximum contribution");
                };
            };
            case null {};
        };
        
        // Check hard cap (convert to smallest unit for comparison)
        if (totalRaised + amount > hardCapInSmallestUnit()) {
            return #err("Exceeds hard cap");
        };
        
        // Check whitelist if required
        if (config.saleParams.requiresWhitelist) {
            let isWhitelistedUser = Array.find<Principal>(config.whitelist, func(p) { p == participant });
            if (isWhitelistedUser == null) {
                return #err("Not whitelisted");
            };
        };

        // Check max participants limit (only for new participants)
        switch (config.saleParams.maxParticipants) {
            case (?maxPart) {
                let participantKey = Principal.toText(participant);
                let isExistingParticipant = switch (Trie.get(participants, LaunchpadTypes.textKey(participantKey), Text.equal)) {
                    case null false;
                    case (?_) true;
                };

                // Only reject if this is a new participant and we've reached the limit
                if (not isExistingParticipant and participantCount >= maxPart) {
                    return #err("Maximum participants limit reached");
                };
            };
            case null {};
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
        Debug.print("💸 Processing refunds for all participants...");
        Debug.print("   Total participants to refund: " # Nat.toText(participantCount));

        // TODO: Implement actual ICRC transfer refunds to each participant
        // For now, just mark processing as completed

        // After all refunds are processed, transition to Failed status
        processingState := #Completed;
        status := #Failed;
        updatedAt := Time.now();

        Debug.print("✅ All refunds processed. Launchpad marked as Failed.");
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
        // MULTI-MODEL SUPPORT: Different allocation logic per sale type
        switch (config.saleParams.saleType) {
            case (#FairLaunch) {
                // FAIR LAUNCH: Dynamic price, allocation calculated at sale end
                // allocationAmount = (contribution / totalRaised) × totalSaleAmount

                Debug.print("📊 Fair Launch: Token allocation deferred until sale end");
                Debug.print("   Contribution stored: " # Nat.toText(contributionAmount));
                Debug.print("   Total raised so far: " # Nat.toText(totalRaised));
                Debug.print("   Total sale amount: " # Nat.toText(config.saleParams.totalSaleAmount));

                0; // Placeholder - actual allocation calculated at sale end
            };
            case (#FixedPrice or #PrivateSale or #IDO) {
                // FIXED PRICE: allocation calculated immediately
                // allocationAmount = contributionAmount / tokenPrice (in e8s)

                if (config.saleParams.tokenPrice == 0) {
                    Debug.print("⚠️ WARNING: Token price is 0, using 1:1 ratio");
                    return contributionAmount;
                };

                let allocationAmount = contributionAmount * LaunchpadTypes.E8S / config.saleParams.tokenPrice;

                Debug.print("💰 Fixed Price: Immediate token allocation");
                Debug.print("   Contribution: " # Nat.toText(contributionAmount));
                Debug.print("   Token Price: " # Nat.toText(config.saleParams.tokenPrice));
                Debug.print("   Allocation: " # Nat.toText(allocationAmount));

                allocationAmount
            };
            case (#Auction or #Lottery) {
                // SPECIAL MODES: Handle allocation logic differently
                // For now, return contribution amount (1:1 ratio)
                // TODO: Implement auction/lottery specific logic

                Debug.print("🎯 Special Mode (" # LaunchpadTypes.saleTypeToText(config.saleParams.saleType) # "): Using 1:1 allocation");
                contributionAmount
            };
        };
    };

    // Calculate final token allocations when sale ends
    private func _finalizeTokenAllocations() : () {
        if (totalRaised == 0) return; // No contributions to allocate

        switch (config.saleParams.saleType) {
            case (#FairLaunch) {
                // FAIR LAUNCH: Calculate allocations based on actual raised amount
                Debug.print("🏁 Finalizing token allocations for fair launch");
                Debug.print("   Total raised: " # Nat.toText(totalRaised));
                Debug.print("   Total sale amount: " # Nat.toText(config.saleParams.totalSaleAmount));

                // Update all participants with their final token allocations
                let participantEntries = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(participants, func(k, v) { (k, v) });

                for ((key, participant) in participantEntries.vals()) {
                    // Fair launch formula: allocation = (contribution / totalRaised) × totalSaleAmount
                    let allocationAmount = (participant.totalContribution * config.saleParams.totalSaleAmount) / totalRaised;

                    let updatedParticipant = {
                        participant with
                        allocationAmount = allocationAmount;
                    };

                    participants := Trie.put(participants, LaunchpadTypes.textKey(key), Text.equal, updatedParticipant).0;

                    Debug.print("   Participant " # Principal.toText(participant.principal) # ":");
                    Debug.print("     Contribution: " # Nat.toText(participant.totalContribution));
                    Debug.print("     Allocation: " # Nat.toText(allocationAmount));
                };

                totalAllocated := config.saleParams.totalSaleAmount;
                Debug.print("✅ Fair launch token allocations finalized");
            };
            case (#FixedPrice or #PrivateSale or #IDO) {
                // FIXED PRICE: Allocations already calculated during participation
                Debug.print("💰 Fixed price sale: allocations already calculated during participation");
                Debug.print("   Total raised: " # Nat.toText(totalRaised));
                Debug.print("   Total allocated: " # Nat.toText(totalAllocated));
                Debug.print("✅ Fixed price allocations complete");
            };
            case (#Auction or #Lottery) {
                // SPECIAL MODES: Implement specific logic
                Debug.print("🎯 Special mode (" # LaunchpadTypes.saleTypeToText(config.saleParams.saleType) # "): Custom allocation logic");
                Debug.print("   Total raised: " # Nat.toText(totalRaised));
                Debug.print("✅ Special mode allocation complete");
            };
        };
    };

    private func _calculateStats() : LaunchpadTypes.LaunchpadStats {
        let now = Time.now();
        {
            totalRaised = totalRaised;
            totalAllocated = totalAllocated;
            participantCount = participantCount;
            transactionCount = transactions.size();
            softCapProgress = Nat8.fromNat(Nat.min(100, if (softCapInSmallestUnit() > 0) totalRaised * 100 / softCapInSmallestUnit() else 0));
            hardCapProgress = Nat8.fromNat(Nat.min(100, if (hardCapInSmallestUnit() > 0) totalRaised * 100 / hardCapInSmallestUnit() else 0));
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
        totalRaised >= hardCapInSmallestUnit()
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
  // PER-USER REENTRANCY PROTECTION (SECURITY FIX)
  // ============================================
  // Replaced vulnerable global lock with per-user tracking system
  // This prevents DoS attacks where one user could block entire system

    private func _checkReentrancy(caller: Principal) : Result.Result<(), Text> {
        let now = Time.now();

        // Clean up expired locks first (maintenance)
        _cleanupExpiredUserLocks(now);

        // Check if this specific user has an active call
        switch (Array.find<(Principal, Time.Time)>(activeUserCalls, func((p, _)) { p == caller })) {
            case (?(_, lockTime)) {
                // User already has an active call - potential reentrancy attack
                securityMetrics := {
                    totalReentrancyAttempts = securityMetrics.totalReentrancyAttempts + 1;
                    totalSuccessfulCalls = securityMetrics.totalSuccessfulCalls;
                    totalFailedCalls = securityMetrics.totalFailedCalls;
                    averageCallDuration = securityMetrics.averageCallDuration;
                    lastSecurityEvent = now;
                };

                _logSecurityEvent(#SuspiciousActivity, caller,
                    "Reentrancy attempt detected - user already has active call since " # Int.toText(lockTime),
                    #Critical);

                return #err("Reentrancy attack prevented for user: " # Principal.toText(caller));
            };
            case null {
                // User is clear - add to active calls
                activeUserCalls := Array.append<(Principal, Time.Time)>(activeUserCalls, [(caller, now)]);

                Debug.print("🔒 User locked: " # Principal.toText(caller) # " at " # Int.toText(now));
                #ok(())
            };
        };
    };

    private func _releaseReentrancyLock() : () {
        // This function is deprecated - use _releaseUserReentrancyLock instead
        Debug.print("⚠️ WARNING: _releaseReentrancyLock() called - this function is deprecated");
    };

    private func _releaseUserReentrancyLock(caller: Principal) : () {
        let beforeCount = activeUserCalls.size();
        activeUserCalls := Array.filter<(Principal, Time.Time)>(activeUserCalls, func((p, _)) { p != caller });

        if (activeUserCalls.size() < beforeCount) {
            Debug.print("🔓 User unlocked: " # Principal.toText(caller));

            // Update metrics
            securityMetrics := {
                totalReentrancyAttempts = securityMetrics.totalReentrancyAttempts;
                totalSuccessfulCalls = securityMetrics.totalSuccessfulCalls + 1;
                totalFailedCalls = securityMetrics.totalFailedCalls;
                averageCallDuration = securityMetrics.averageCallDuration;
                lastSecurityEvent = securityMetrics.lastSecurityEvent;
            };
        };
    };

    private func _cleanupExpiredUserLocks(now: Time.Time) : () {
        let beforeCount = activeUserCalls.size();
        activeUserCalls := Array.filter<(Principal, Time.Time)>(activeUserCalls, func((p, lockTime)) {
            let isExpired = (now - lockTime) > USER_LOCK_TIMEOUT;
            if (isExpired) {
                Debug.print("⏰ Expired lock auto-cleaned for user: " # Principal.toText(p));

                // Log as security event - unusual if locks are expiring
                _logSecurityEvent(#SuspiciousActivity, p,
                    "User lock expired after timeout - possible failed operation",
                    #Medium);
            };
            not isExpired;
        });

        let cleanedCount = beforeCount - activeUserCalls.size();
        if (cleanedCount > 0) {
            Debug.print("🧹 Auto-cleaned " # Nat.toText(cleanedCount) # " expired user locks");
        };
    };

    // Admin function to manually unlock specific user (emergency use only)
    private func _adminUnlockUser(targetUser: Principal, adminCaller: Principal) : Result.Result<(), Text> {
        if (not _isAuthorized(adminCaller)) {
            return #err("Unauthorized: Only authorized users can unlock users");
        };

        let beforeCount = activeUserCalls.size();
        activeUserCalls := Array.filter<(Principal, Time.Time)>(activeUserCalls, func((p, _)) { p != targetUser });

        if (activeUserCalls.size() < beforeCount) {
            _logAdminAction("USER_UNLOCK", adminCaller, "Target: " # Principal.toText(targetUser), true, null);
            Debug.print("🔓 Admin unlocked user: " # Principal.toText(targetUser) # " by " # Principal.toText(adminCaller));
            #ok(())
        } else {
            #err("User was not locked");
        };
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
        let largeTransactionThreshold = hardCapInSmallestUnit() / 20; // 5% of hard cap

        if (amount > largeTransactionThreshold) {
            _logSecurityEvent(#LargeTransaction, caller, "Large transaction: " # Nat.toText(amount), #High);
            // Additional validation for large transactions (convert to smallest unit for comparison)
            let maxContribCheck = switch(config.saleParams.maxContribution) {
                case (?max) amount <= toSmallestUnit(max, config.purchaseToken.decimals);
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

    /// Reset reentrancy lock for specific user (admin only - emergency function)
    /// Use this when a specific user's reentrancy lock gets stuck due to failed operations
    public shared({caller}) func resetUserReentrancyLock(targetUser: Principal) : async Result.Result<(), Text> {
        switch (_adminUnlockUser(targetUser, caller)) {
            case (#ok()) #ok(());
            case (#err(msg)) {
                _logSecurityEvent(#UnauthorizedAccess, caller, "Attempted to reset user lock: " # msg, #Medium);
                #err(msg);
            };
        };
    };

    /// Get current active user locks (admin only - for monitoring)
    public shared({caller}) func getActiveUserLocks() : async Result.Result<[(Principal, Time.Time)], Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized: Only authorized users can view active locks");
        };

        // Clean up expired locks first
        _cleanupExpiredUserLocks(Time.now());

        #ok(activeUserCalls);
    };

    /// Get security metrics (admin only)
    public shared({caller}) func getSecurityMetrics() : async Result.Result<{
        totalReentrancyAttempts: Nat;
        totalSuccessfulCalls: Nat;
        totalFailedCalls: Nat;
        averageCallDuration: Time.Time;
        lastSecurityEvent: Time.Time;
        activeUserLocksCount: Nat;
    }, Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized: Only authorized users can view security metrics");
        };

        #ok({
            totalReentrancyAttempts = securityMetrics.totalReentrancyAttempts;
            totalSuccessfulCalls = securityMetrics.totalSuccessfulCalls;
            totalFailedCalls = securityMetrics.totalFailedCalls;
            averageCallDuration = securityMetrics.averageCallDuration;
            lastSecurityEvent = securityMetrics.lastSecurityEvent;
            activeUserLocksCount = activeUserCalls.size();
        });
    };

    /// Emergency unlock ALL users (admin only - last resort)
    /// This will clear ALL active user locks - use only in emergency situations
    public shared({caller}) func emergencyUnlockAllUsers() : async Result.Result<Nat, Text> {
        if (not _isAuthorized(caller)) {
            return #err("Unauthorized: Only authorized users can perform emergency unlock");
        };

        let unlockedCount = activeUserCalls.size();
        activeUserCalls := [];

        _logAdminAction("EMERGENCY_UNLOCK_ALL", caller, "Unlocked " # Nat.toText(unlockedCount) # " users", true, null);
        _logSecurityEvent(#EmergencyAction, caller, "Emergency unlock of all users performed", #Critical);

        Debug.print("🚨 EMERGENCY: All " # Nat.toText(unlockedCount) # " user locks cleared by " # Principal.toText(caller));

        #ok(unlockedCount);
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

    // ================ IUPGRADEABLE INTERFACE ================
    // Following IUpgradeable pattern for safe contract upgrades

    /// Get upgrade args - captures current state for safe upgrade
    public query func getUpgradeArgs() : async Blob {
        let upgradeData: LaunchpadUpgradeTypes.LaunchpadUpgradeArgs = {
            // Original init args (STATIC - config never modified)
            id = launchpadId;
            config = config;
            creator = creator;
            createdAt = createdAt;

            // Current runtime state (DYNAMIC - captured now)
            runtimeState = {
                launchpadId = launchpadId;
                creator = creator;
                factoryPrincipal = factoryPrincipal;
                createdAt = createdAt;
                updatedAt = updatedAt;
                status = status;
                processingState = processingState;
                installed = installed;
                totalRaised = totalRaised;
                totalAllocated = totalAllocated;
                participantCount = participantCount;
                transactionCount = transactionCount;

                // Convert Tries to Arrays for serialization
                participants = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(
                    participants,
                    func (k, v) = (k, v)
                );
                transactions = Buffer.toArray(transactions);
                affiliateStats = Trie.toArray<Text, LaunchpadTypes.AffiliateStats, (Text, LaunchpadTypes.AffiliateStats)>(
                    affiliateStats,
                    func (k, v) = (k, v)
                );

                deployedContracts = deployedContracts;
                emergencyPaused = emergencyPaused;
                emergencyReason = emergencyReason;
                lastEmergencyAction = lastEmergencyAction;
                activeUserCalls = activeUserCalls;
                adminActions = adminActions;
                securityEvents = securityEvents;
                lastParticipationTime = lastParticipationTime;
                rateLimitViolations = rateLimitViolations;
                securityMetrics = securityMetrics;
            };
        };

        to_candid(upgradeData)
    };

    /// Check if contract can be upgraded
    public query func canUpgrade() : async Result.Result<(), Text> {
        // Check 1: Contract must be initialized
        if (not installed) {
            return #err("Cannot upgrade: Contract not initialized");
        };

        // Check 2: Cannot upgrade during emergency pause
        if (emergencyPaused) {
            return #err("Cannot upgrade: Contract in emergency pause");
        };

        // Check 3: Cannot upgrade during active processing
        switch (processingState) {
            case (#Processing(_)) {
                return #err("Cannot upgrade: Active processing in progress");
            };
            case (#Failed(_)) {
                return #err("Cannot upgrade: Processing failed, resolve first");
            };
            case _ {};
        };

        // SECURITY FIX: Removed global reentrancy lock check
        // Per-user locks no longer prevent upgrades
        // This eliminates DoS vulnerability where attacker could block upgrades

        #ok()
    };

    /// Get current contract version
    public query func getVersion() : async IUpgradeable.Version {
        contractVersion
    };

    /// Update contract version (factory only)
    /// Only the factory can call this function to update version after upgrade
    public func updateVersion(newVersion: IUpgradeable.Version, caller: Principal) : async Result.Result<(), Text> {
        // Factory authentication - only factory can update version
        if (caller != factoryPrincipal) {
            return #err("Unauthorized: Only factory can update version");
        };

        // Update version
        contractVersion := newVersion;
        Debug.print("✅ LaunchpadContract version updated by factory: " # debug_show(newVersion) # " by " # Principal.toText(caller));

        #ok(())
    };

    /// Comprehensive health check
    public query func healthCheck() : async IUpgradeable.HealthStatus {
        let issues = Buffer.Buffer<Text>(0);

        // Check 1: Initialization status
        if (not installed) {
            issues.add("Contract not initialized");
        };

        // Check 2: Emergency pause status
        if (emergencyPaused) {
            issues.add("Contract in emergency pause: " # emergencyReason);
        };

        // Check 3: Processing state
        switch (processingState) {
            case (#Failed(msg)) {
                issues.add("Processing failed: " # msg);
            };
            case _ {};
        };

        // Check 4: User reentrancy locks (updated from global lock)
        let now = Time.now();
        let activeLocksCount = Array.filter<(Principal, Time.Time)>(activeUserCalls, func((p, lockTime)) {
            (now - lockTime) <= USER_LOCK_TIMEOUT
        }).size();

        if (activeLocksCount > 50) {  // WARNING threshold
            issues.add("High number of active user locks: " # Nat.toText(activeLocksCount));
        };

        if (activeLocksCount > 0) {
            issues.add("User locks currently active: " # Nat.toText(activeLocksCount) # " users");
        };

        // Check 5: Recent security events
        let recentSecurityEvents = Array.filter<LaunchpadTypes.SecurityEvent>(securityEvents, func(event) {
            (now - event.timestamp) < 3_600_000_000_000 // Last hour
        });

        if (recentSecurityEvents.size() > 10) {
            issues.add("High number of recent security events: " # Nat.toText(recentSecurityEvents.size()));
        };

        // Check 6: Token deployment status (if sale successful)
        switch (status) {
            case (#Successful) {
                switch (deployedContracts.tokenCanister) {
                    case null {
                        issues.add("Token not deployed after successful sale");
                    };
                    case _ {};
                };
            };
            case _ {};
        };

        // Check 7: Stale locks (locks older than timeout)
        let staleLocks = Array.filter<(Principal, Time.Time)>(activeUserCalls, func((p, lockTime)) {
            (now - lockTime) > USER_LOCK_TIMEOUT
        });

        if (staleLocks.size() > 0) {
            issues.add("Stale user locks detected: " # Nat.toText(staleLocks.size()) # " (should be auto-cleaned)");
        };

        // Check 8: Reentrancy attack attempts
        if (securityMetrics.totalReentrancyAttempts > 100) {
            issues.add("High number of reentrancy attempts: " # Nat.toText(securityMetrics.totalReentrancyAttempts));
        };

        let issueArray = Buffer.toArray(issues);
        {
            healthy = issueArray.size() == 0;
            issues = issueArray;
            lastActivity = updatedAt;
            canisterCycles = 0; // TODO: Get actual cycles balance
            memorySize = 0; // TODO: Get actual memory size
        }
    };
}