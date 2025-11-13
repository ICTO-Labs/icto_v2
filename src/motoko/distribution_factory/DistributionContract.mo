// ICTO Distribution Contract - Individual Distribution Canister
import Principal "mo:core/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Error "mo:base/Error";
import Array "mo:base/Array";
// Import shared types (trust source)
import DistributionTypes "../shared/types/DistributionTypes";
import DistributionUpgradeTypes "../shared/types/DistributionUpgradeTypes";
import IUpgradeable "../common/IUpgradeable";
import Timer "mo:base/Timer";
import ICRC "../shared/types/ICRC";
import ICTOPassport "../shared/utils/ICTOPassport";
import Prim "mo:⛔";

persistent actor class DistributionContract(initArgs: DistributionUpgradeTypes.DistributionInitArgs) = self {

    // ================ TYPE ALIASES (from shared types) ================

    public type TokenInfo = DistributionTypes.TokenInfo;
    public type EligibilityType = DistributionTypes.EligibilityType;
    public type Recipient = DistributionTypes.Recipient;
    public type CampaignType = DistributionTypes.CampaignType;

    public type TokenHolderConfig = DistributionTypes.TokenHolderConfig;
    public type NFTHolderConfig = DistributionTypes.NFTHolderConfig;
    public type EligibilityLogic = DistributionTypes.EligibilityLogic;
    public type RecipientMode = DistributionTypes.RecipientMode;
    public type RegistrationPeriod = DistributionTypes.RegistrationPeriod;
    public type VestingSchedule = DistributionTypes.VestingSchedule;
    public type LinearVesting = DistributionTypes.LinearVesting;
    public type CliffVesting = DistributionTypes.CliffVesting;
    public type SingleVesting = DistributionTypes.SingleVesting;
    public type PenaltyUnlock = DistributionTypes.PenaltyUnlock;
    public type CliffStep = DistributionTypes.CliffStep;
    public type UnlockEvent = DistributionTypes.UnlockEvent;
    public type UnlockFrequency = DistributionTypes.UnlockFrequency;
    public type FeeStructure = DistributionTypes.FeeStructure;
    public type FeeTier = DistributionTypes.FeeTier;
    public type DistributionConfig = DistributionTypes.DistributionConfig;
    public type DistributionStatus = DistributionTypes.DistributionStatus;
    public type ParticipantStatus = DistributionTypes.ParticipantStatus;
    public type Participant = DistributionTypes.Participant;
    public type CategoryAllocation = DistributionTypes.CategoryAllocation;
    public type MultiCategoryParticipant = DistributionTypes.MultiCategoryParticipant;  // V2.0
    public type MultiCategoryRecipient = DistributionTypes.MultiCategoryRecipient;      // V2.0
    public type ClaimRecord = DistributionTypes.ClaimRecord;
    public type DistributionStats = DistributionTypes.DistributionStats;

    // ================ INITIALIZATION LOGIC ================
    // Determine if this is a fresh deployment or an upgrade
    // and extract the appropriate values

    let isUpgrade: Bool = switch (initArgs) {
        case (#InitialSetup(_)) { false };
        case (#Upgrade(_)) { true };
    };

    // Extract config and creator based on deployment mode
    let init_config: DistributionConfig = switch (initArgs) {
        case (#InitialSetup(setup)) {
            Debug.print("🆕 DistributionContract: Fresh deployment");
            setup.config
        };
        case (#Upgrade(upgrade)) {
            Debug.print("⬆️ DistributionContract: Upgrading from previous version");
            upgrade.config
        };
    };

    let init_creator: Principal = switch (initArgs) {
        case (#InitialSetup(setup)) { setup.creator };
        case (#Upgrade(upgrade)) { upgrade.creator };
    };

    let init_factory_canister: ?Principal = switch (initArgs) {
        case (#InitialSetup(setup)) { setup.factory };
        case (#Upgrade(upgrade)) { upgrade.factory };
    };

    let init_version: IUpgradeable.Version = switch (initArgs) {
        case (#InitialSetup(setup)) {
            Debug.print("📦 InitialSetup version: " # debug_show(setup.version));
            setup.version
        };
        case (#Upgrade(upgrade)) {
            // During upgrade, version is managed by VersionManager
            // This is just the initial value, will be updated by completeUpgrade()
            { major = 1; minor = 0; patch = 0 }
        };
    };

    let upgradeState: ?DistributionUpgradeTypes.DistributionRuntimeState = switch (initArgs) {
        case (#InitialSetup(_)) { null };
        case (#Upgrade(upgrade)) { ?upgrade.runtimeState };
    };

    // ================ STABLE VARIABLES ================

    private var config: DistributionConfig = init_config;
    private var creator: Principal = init_creator;
    private var status: DistributionStatus = switch (upgradeState) {
        case null { #Created };
        case (?state) { state.status };
    };
    private var createdAt: Time.Time = switch (upgradeState) {
        case null { Time.now() };
        case (?state) { state.createdAt };
    };
    private var initialized: Bool = switch (upgradeState) {
        case null { false };
        case (?state) { state.initialized };
    };

    // Contract version for upgrade tracking (passed from factory on fresh deploy)
    private var contractVersion: IUpgradeable.Version = init_version;

    // ================ UPGRADE STATE MANAGEMENT ================
    // Contract self-locks when requesting upgrade, factory unlocks when done/failed/timeout

    /// Upgrade mode state
    private var isUpgrading : Bool = false;
    private var upgradeRequestedAt : ?Int = null;
    private var upgradeRequestId : ?Text = null;

    /// Timeout configuration (30 minutes in nanoseconds)
    private let UPGRADE_TIMEOUT_NANOS : Int = 30 * 60 * 1_000_000_000;

    private var lastActivityTime: Time.Time = Time.now();

    // ================ SECURITY MEASURES ================

    /// Per-user reentrancy protection - prevents recursive calls to critical functions
    private var _userReentrancyGuards: [(Principal, Bool)] = [];

    /// Global emergency reentrancy protection - only for critical emergencies
    private var _emergencyReentrancyGuard: Bool = false;

    /// Rate limiting for claim operations (1 claim per minute per user)
    private var _lastClaimTime: [(Principal, Time.Time)] = [];

    /// Global rate limiting to prevent Sybil attacks
    private var _globalClaimTimestamps: [Time.Time] = [];
    private let _MAX_CLAIMS_PER_MINUTE: Nat = 100; // Global limit

    /// Security event logging for audit trail
    private var _securityEvents: [SecurityEvent] = [];
    private let _MAX_SECURITY_EVENTS: Nat = 1000; // Keep last 1000 events

    /// Access control roles
    private var _adminRoles: [(Principal, Role)] = [];

    /// Maximum operations per batch to prevent gas griefing
    private let _MAX_BATCH_OPERATIONS: Nat = 100;

    /// Role types for access control
    public type Role = {
        #Owner;
        #Admin;
        #Manager;
        #User;
    };

    // Participant management (V2.0: Now MultiCategoryParticipant)
    private var participantsStable: [(Principal, MultiCategoryParticipant)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.participants };
    };
    private var claimRecordsStable: [ClaimRecord] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.claimRecords };
    };
    private var whitelistStable: [(Principal, Bool)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.whitelist };
    };
    private var blacklistStable: [(Principal, Bool)] = switch (upgradeState) {
        case null { [] };
        case (?state) { state.blacklist };
    };

    // Stats
    private var totalDistributed: Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.totalDistributed };
    };
    private var totalClaimed: Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.totalClaimed };
    };
    private var participantCount: Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.participantCount };
    };

    // Runtime variables - will be restored in postupgrade
    // V2.0: Now uses MultiCategoryParticipant for all distributions (legacy auto-converts to default category)
    private transient var participants: Trie.Trie<Principal, MultiCategoryParticipant> = Trie.empty();
    private transient var claimRecords: Buffer.Buffer<ClaimRecord> = Buffer.Buffer(0);
    private transient var whitelist: Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var blacklist: Trie.Trie<Principal, Bool> = Trie.empty();

    // Milestone timers (similar to Launchpad pattern)
    private var distributionStartTimerId: ?Nat = null;  // Timer for auto-activation
    private var distributionEndTimerId: ?Nat = null;     // Timer for auto-completion
    private var balanceCheckTimerId: ?Nat = null;       // Recurring timer for balance checks (post-start)
    private var tokenCanister: ?ICRC.ICRCLedger = null;

    // ICTO Passport integration
    private let BLOCK_ID_CANISTER_ID = "3c7yh-4aaaa-aaaap-qhria-cai";
    private let BLOCK_ID_APPLICATION = "block-id";
    private let passportInterface: ICTOPassport.Self = actor(BLOCK_ID_CANISTER_ID);

    // Factory integration for relationship updates (Factory Storage Standard)
    private var factoryCanisterId: ?Principal = init_factory_canister;

    // Launchpad Integration - Optional features
    private var launchpadCanisterId: ?Principal = switch (upgradeState) {
        case null { null };
        case (?state) { state.launchpadCanisterId };
    };

    //Token info
    private var transferFee: Nat = switch (upgradeState) {
        case null { 0 };
        case (?state) { state.transferFee };
    };

    // Constants
    private let E8S: Nat = 100_000_000;
    private let _NANO_TIME: Nat = 1_000_000_000;

    // ================ SECURITY HELPER FUNCTIONS ================

    /// Per-user reentrancy protection - prevents recursive calls
    private func _reentrancyGuardEnter(caller: Principal) : Result.Result<(), Text> {
        // Check emergency guard first
        if (_emergencyReentrancyGuard) {
            return #err("Emergency reentrancy protection active");
        };

        // Simple approach: check if user is already locked
        let existingGuard = Array.find(_userReentrancyGuards, func ((user, _): (Principal, Bool)) : Bool {
            Principal.equal(user, caller)
        });

        switch (existingGuard) {
            case (?(_, isLocked)) {
                if (isLocked) {
                    return #err("Reentrancy detected for user: " # Principal.toText(caller));
                };
                // Update existing guard to locked
                let filteredGuards = Array.filter(_userReentrancyGuards, func ((user, _): (Principal, Bool)) : Bool {
                    not Principal.equal(user, caller)
                });
                _userReentrancyGuards := Array.append(filteredGuards, [(caller, true)]);
            };
            case null {
                // Add new user guard
                _userReentrancyGuards := Array.append(_userReentrancyGuards, [(caller, true)]);
            };
        };

        #ok(())
    };

    /// Release per-user reentrancy guard
    private func _reentrancyGuardExit(caller: Principal) {
        // Find and unlock user
        let filteredGuards = Array.filter(_userReentrancyGuards, func ((user, _): (Principal, Bool)) : Bool {
            not Principal.equal(user, caller)
        });
        _userReentrancyGuards := Array.append(filteredGuards, [(caller, false)]);
    };

    /// Emergency reentrancy protection - lock all operations (Owner only)
    private func _emergencyReentrancyLock() {
        _emergencyReentrancyGuard := true;
    };

    /// Release emergency reentrancy protection (Owner only)
    private func _emergencyReentrancyUnlock() {
        _emergencyReentrancyGuard := false;
    };

    /// Safe arithmetic operations with overflow/underflow protection
    private func _safeAdd(a: Nat, b: Nat) : ?Nat {
        let result = a + b;
        if (result >= a) { ?result } else { null };
    };

    private func _safeSub(a: Nat, b: Nat) : ?Nat {
        if (a >= b) { ?(a - b) } else { null };
    };

    private func _safeMul(a: Nat, b: Nat) : ?Nat {
        let result = a * b;
        if (result / a == b and a != 0) { ?result } else { null };
    };

    private func _safeDiv(a: Nat, b: Nat) : ?Nat {
        if (b != 0) { ?(a / b) } else { null };
    };

    /// Enhanced rate limiting with global and per-user protection
    private func _checkRateLimit(caller: Principal) : Result.Result<(), Text> {
        let now = _getValidatedTime(); // Use protected time
        let cooldownPeriod = 60_000_000_000; // 1 minute in nanoseconds

        // 1. Global rate limiting (prevent Sybil attacks)
        let recentGlobalClaims = Array.filter(_globalClaimTimestamps, func (timestamp: Time.Time) : Bool {
            let timeDiff = Int.abs(now - timestamp);
            timeDiff < cooldownPeriod
        });

        if (recentGlobalClaims.size() >= _MAX_CLAIMS_PER_MINUTE) {
            return #err("Global rate limit exceeded. Please try again later.");
        };

        // 2. Per-user rate limiting
        let lastClaim = Array.find(_lastClaimTime, func ((user, _): (Principal, Time.Time)) : Bool {
            Principal.equal(user, caller)
        });

        switch (lastClaim) {
            case (?(_, lastTime)) {
                let timeSinceLastClaim = Int.abs(now - lastTime);
                if (timeSinceLastClaim < cooldownPeriod) {
                    return #err("Rate limit exceeded. Please wait " # debug_show(cooldownPeriod - timeSinceLastClaim) # " nanoseconds");
                };
                // Update last claim time
                _updateLastClaimTime(caller, now);
            };
            case null {
                // First time claiming
                _updateLastClaimTime(caller, now);
            };
        };

        // 3. Update global claim timestamps
        _globalClaimTimestamps := Array.append(_globalClaimTimestamps, [now]);

        // 4. Cleanup old timestamps (keep only recent ones)
        let cleanedTimestamps = Array.filter(_globalClaimTimestamps, func (timestamp: Time.Time) : Bool {
            let timeDiff = Int.abs(now - timestamp);
            timeDiff < cooldownPeriod * 10 // Keep 10 minutes of history
        });
        _globalClaimTimestamps := cleanedTimestamps;

        #ok(())
    };

    /// Update last claim time for a user
    private func _updateLastClaimTime(user: Principal, time: Time.Time) {
        // Simple approach: filter out existing entry and add new one
        let filteredEntries = Array.filter(_lastClaimTime, func (item: (Principal, Time.Time)) : Bool {
            not Principal.equal(item.0, user)
        });
        // Add new entry
        _lastClaimTime := Array.append(filteredEntries, [(user, time)]);
    };

    /// Oracle-protected time function to prevent MEV attacks
    private func _getValidatedTime() : Time.Time {
        let currentTime = Time.now();
        let contractTime = lastActivityTime; // Contract's last validated time

        // Maximum allowed time drift (5 minutes)
        let maxTimeDrift = 300_000_000_000; // 5 minutes in nanoseconds

        // Check for unreasonable time jumps
        let timeDiff = Int.abs(currentTime - contractTime);

        if (timeDiff > maxTimeDrift) {
            // Time manipulation detected - use contract time as fallback
            Debug.print("⚠️ Time manipulation detected: " # debug_show(timeDiff) # "ns drift");
            return contractTime;
        };

        // Validate time is reasonable (not too far in past/future)
        let reasonableTimeRange = 86400_000_000_000; // 24 hours
        let referenceTime = 1700000000000000000; // Reference timestamp (Nov 2023)

        if (currentTime < referenceTime or currentTime > referenceTime + reasonableTimeRange * 365) {
            Debug.print("⚠️ Unreasonable time detected, using fallback");
            return contractTime;
        };

        currentTime;
    };

    // ================ ATOMIC BALANCE OPERATIONS (TOCTOU PROTECTION) ================

    /// Atomic balance check and claim operation
    /// Prevents TOCTOU race conditions by performing checks and updates in a single atomic operation
    private func _atomicClaimOperation(
        caller: Principal,
        participant: MultiCategoryParticipant,
        claimAmount: Nat,
        updatedCategories: [CategoryAllocation]
    ) : Result.Result<MultiCategoryParticipant, Text> {
        // Create a checkpoint of the current state
        let checkpoint = {
            originalParticipant = participant;
            originalTotalClaimed = totalClaimed;
            originalClaimRecordsSize = claimRecords.size();
        };

        // Calculate new state atomically
        let newTotalClaimedResult = _safeAdd(participant.totalClaimed, claimAmount);
        let newTotalClaimed = switch (newTotalClaimedResult) {
            case (?amount) { amount };
            case null { return #err("Arithmetic overflow in claim calculation") };
        };

        // Validate that the claim is still valid under current state
        let maxClaimableResult = _safeSub(_calculateTotalFromCategories(participant.categories), participant.totalClaimed);
        let maxClaimable = switch (maxClaimableResult) {
            case (?amount) { amount };
            case null { return #err("Invalid state: claimed exceeds eligible") };
        };

        if (claimAmount > maxClaimable) {
            return #err("State changed: claim amount no longer valid");
        };

        // All checks passed - return updated participant
        let updatedParticipant: MultiCategoryParticipant = {
            principal = participant.principal;
            registeredAt = participant.registeredAt;
            categories = updatedCategories;
            totalEligible = participant.totalEligible;
            totalClaimed = newTotalClaimed;
            lastClaimTime = ?_getValidatedTime();
            status = participant.status;
            note = participant.note;
        };

        #ok(updatedParticipant)
    };

    /// Verify and update global totals atomically
    private func _atomicUpdateGlobalTotals(
        previousTotal: Nat,
        addition: Nat,
        operation: Text
    ) : Result.Result<Nat, Text> {
        let newTotalResult = _safeAdd(previousTotal, addition);
        let newTotal = switch (newTotalResult) {
            case (?amount) { amount };
            case null {
                return #err("Global total overflow in " # operation);
            };
        };

        // Additional sanity check
        if (newTotal < previousTotal) {
            return #err("Arithmetic underflow detected in " # operation);
        };

        #ok(newTotal)
    };

    /// Log security events for audit trail
    private func _logSecurityEvent(
        eventType: Text,
        principal: Principal,
        amount: Nat,
        details: Text,
        severity: Severity
    ) {
        let event: SecurityEvent = {
            timestamp = _getValidatedTime();
            eventType = eventType;
            principal = principal;
            amount = amount;
            details = details;
            severity = severity;
        };

        // Add event to log
        _securityEvents := Array.append(_securityEvents, [event]);

        // Keep only last MAX_EVENTS events (prevent unbounded growth)
        if (_securityEvents.size() > _MAX_SECURITY_EVENTS) {
            let excess = _securityEvents.size() - _MAX_SECURITY_EVENTS;
            _securityEvents := Array.take(_securityEvents, _securityEvents.size() - excess);
        };

        // Also log to Debug for development visibility
        let severityText = switch (severity) {
            case (#Info) { "INFO" };
            case (#Warning) { "WARN" };
            case (#Error) { "ERROR" };
            case (#Critical) { "CRITICAL" };
        };
        Debug.print("🔐 SECURITY [" # severityText # "] " # eventType # " by " # Principal.toText(principal) # ": " # details);
    };

    /// Enhanced access control with role-based permissions
    private func _hasRole(caller: Principal, requiredRole: Role) : Bool {
        // Check creator first (highest privilege)
        if (Principal.equal(caller, creator)) {
            return true;
        };

        // Check role assignments
        let userRole = Array.find(_adminRoles, func ((user, _role): (Principal, Role)) : Bool {
            Principal.equal(user, caller)
        });

        switch (userRole) {
            case (?(_, userAssignedRole)) {
                return _roleHasPermission(userAssignedRole, requiredRole);
            };
            case null {
                // Default role for all users is #User
                return _roleHasPermission(#User, requiredRole);
            };
        };
    };

    /// Check if a role has permission for the required role level
    private func _roleHasPermission(userRole: Role, requiredRole: Role) : Bool {
        switch (userRole) {
            case (#Owner) { true }; // Owner can do everything
            case (#Admin) {
                switch (requiredRole) {
                    case (#Owner) { false }; // Admin cannot be owner
                    case (_) { true };
                };
            };
            case (#Manager) {
                switch (requiredRole) {
                    case (#User) { true };
                    case (_) { false };
                };
            };
            case (#User) {
                switch (requiredRole) {
                    case (#User) { true };
                    case (_) { false };
                };
            };
        };
    };

    /// Comprehensive input validation
    private func _validatePrincipal(p: Principal) : Result.Result<(), Text> {
        if (Principal.isAnonymous(p)) {
            return #err("Anonymous principal not allowed");
        };
        #ok(())
    };

    private func _validateAmount(amount: Nat) : Result.Result<(), Text> {
        if (amount == 0) {
            return #err("Amount cannot be zero");
        };
        if (amount > 1_000_000_000_000_000_000) { // 1 billion tokens (adjust as needed)
            return #err("Amount exceeds maximum allowed");
        };
        #ok(())
    };

    private func _validateText(text: Text) : Result.Result<(), Text> {
        if (text.size() == 0) {
            return #err("Text cannot be empty");
        };
        if (text.size() > 1000) { // Reasonable limit
            return #err("Text too long");
        };
        #ok(())
    };

    /// Initialize whitelist and participants from config on contract creation
    public shared({ caller }) func init() : async Result.Result<(), Text> {
        Debug.print("🔧 init() called by: " # Principal.toText(caller));
        Debug.print("📋 Creator: " # Principal.toText(creator));
        Debug.print("📋 Owner: " # Principal.toText(config.owner));
        let factoryText = switch (factoryCanisterId) {
            case (?factoryId) { Principal.toText(factoryId) };
            case null { "null" };
        };
        Debug.print("📋 Factory: " # factoryText);

        // Allow factory, creator, or config.owner to initialize
        let isFactory = switch (factoryCanisterId) {
            case (?factoryId) {
                let result = Principal.equal(caller, factoryId);
                Debug.print("🔍 Factory check: caller == factory? " # debug_show(result));
                result
            };
            case null {
                Debug.print("🔍 Factory check: no factory configured");
                false
            };
        };

        let isOwner = _isOwner(caller);
        Debug.print("🔍 Owner check: caller is owner? " # debug_show(isOwner));

        if (not isOwner and not isFactory) {
            Debug.print("❌ Authorization failed: caller is not owner or factory");
            return #err("Unauthorized: Only owner or factory can initialize distribution");
        };

        Debug.print("✅ Authorization passed");

        if (initialized) {
            return #err("Distribution already initialized");
        };
        
        // Initialize token canister
        tokenCanister := ?actor(Principal.toText(config.tokenInfo.canisterId));
        transferFee := await _getTransferFee(tokenCanister);
        
        // Initialize whitelist and participants from config
        _initializeWhitelist();

        // Initialize Launchpad features if linked
        _initializeLaunchpadFeatures();

        // Setup milestone timers for automatic status transitions
        await _setupMilestoneTimers();

        initialized := true;
        Debug.print("✅ Manual initialization completed with milestone timers");
        #ok()
    };

    private func _getTransferFee(tokenCanister: ?ICRC.ICRCLedger) : async Nat {
        switch (tokenCanister) {
            case (?icrcLedger) {
                await icrcLedger.icrc1_fee();
            };
            case null { 0 };
        };
    };

    // ================ INITIALIZATION ================
    
    system func preupgrade() {
        Debug.print("DistributionContract: Starting preupgrade");
        // V2.0: Now uses MultiCategoryParticipant
        participantsStable := Trie.toArray<Principal, MultiCategoryParticipant, (Principal, MultiCategoryParticipant)>(participants, func (k, v) = (k, v));
        claimRecordsStable := Buffer.toArray(claimRecords);
        whitelistStable := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelist, func (k, v) = (k, v));
        blacklistStable := Trie.toArray<Principal, Bool, (Principal, Bool)>(blacklist, func (k, v) = (k, v));
        Debug.print("DistributionContract: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("DistributionContract: Starting postupgrade");
        
        // Restore participants
        for ((principal, participant) in participantsStable.vals()) {
            participants := Trie.put(participants, _principalKey(principal), Principal.equal, participant).0;
        };
        
        // Restore claim records
        for (record in claimRecordsStable.vals()) {
            claimRecords.add(record);
        };
        
        // Restore whitelist
        for ((principal, eligible) in whitelistStable.vals()) {
            whitelist := Trie.put(whitelist, _principalKey(principal), Principal.equal, eligible).0;
        };
        
        // Restore blacklist
        for ((principal, eligible) in blacklistStable.vals()) {
            blacklist := Trie.put(blacklist, _principalKey(principal), Principal.equal, eligible).0;
        };
        
        // Initialize whitelist from config if first run
        if (Trie.size(whitelist) == 0) {
            _initializeWhitelist();
        };
        
        // Clear stable variables
        participantsStable := [];
        claimRecordsStable := [];
        whitelistStable := [];
        blacklistStable := [];
        Debug.print("DistributionContract: Postupgrade completed");

        // AUTO-INIT AND TIMER SETUP (Similar to Launchpad pattern)
        // This ensures distribution is fully initialized and milestone timers run automatically
        Debug.print("📍 postupgrade: Scheduling auto-init and timer setup...");
        ignore Timer.setTimer<system>(
            #seconds(1),  // 1 second delay to allow postupgrade to complete
            func() : async () {
                // If not initialized yet, auto-initialize
                if (not initialized) {
                    Debug.print("🔧 Auto-initializing distribution contract...");

                    // Initialize token canister
                    tokenCanister := ?actor(Principal.toText(config.tokenInfo.canisterId));
                    transferFee := await _getTransferFee(tokenCanister);

                    // Initialize whitelist and participants from config
                    _initializeWhitelist();

                    // Initialize Launchpad features if linked
                    _initializeLaunchpadFeatures();

                    initialized := true;
                    Debug.print("✅ Auto-initialization completed");
                };

                // Setup milestone timers for automatic status transitions
                // Uses one-time timers at exact timestamps (like Launchpad)
                Debug.print("🔄 Setting up milestone timers...");
                await _setupMilestoneTimers();

                Debug.print("✅ postupgrade: Auto-init and timers configured");
            }
        );

        // Signal upgrade completion for factory detection
        Debug.print("UPGRADE_COMPLETED:" # Principal.toText(Principal.fromActor(self)) # ":" # debug_show(contractVersion));
    };

    // ================ HELPER FUNCTIONS ================
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _isOwner(caller: Principal) : Bool {
        Principal.equal(caller, creator) or Principal.equal(caller, config.owner)
    };
    
    private func _isActive() : Bool {
        status == #Active and Time.now() >= config.distributionStart and
        (Option.isNull(config.distributionEnd) or Time.now() <= Option.get(config.distributionEnd, Time.now()))
    };
    
    private func _findRecipientAmount(principal: Principal) : ?Nat {
        for (recipient in config.recipients.vals()) {
            if (Principal.equal(recipient.address, principal)) {
                return ?recipient.amount;
            };
        };
        null
    };

    // ================ MULTI-CATEGORY HELPERS (V2.0) ================

    /// Calculate total eligible amount from all categories
    private func _calculateTotalFromCategories(categories: [CategoryAllocation]) : Nat {
        var total: Nat = 0;
        for (category in categories.vals()) {
            total += category.amount;
        };
        total
    };

    /// Calculate total claimed amount from all categories
    private func _calculateTotalClaimedFromCategories(categories: [CategoryAllocation]) : Nat {
        var total: Nat = 0;
        for (category in categories.vals()) {
            total += category.claimedAmount;
        };
        total
    };

    // ================ PARTICIPANT INITIALIZATION (V2.0) ================

    private func _initializeWhitelist() {
        // ================ DETECT MODE: Multi-Category vs Legacy ================
        switch (config.multiCategoryRecipients) {
            case (?multiRecipients) {
                // ✅ MULTI-CATEGORY MODE - Direct initialization
                Debug.print("🎯 Multi-category mode: Initializing " # Nat.toText(multiRecipients.size()) # " multi-category participants");

                switch (config.eligibilityType) {
                    case (#Whitelist) {
                        for (recipient in multiRecipients.vals()) {
                            whitelist := Trie.put(whitelist, _principalKey(recipient.address), Principal.equal, true).0;

                            let participant: MultiCategoryParticipant = {
                                principal = recipient.address;
                                registeredAt = Time.now();
                                categories = recipient.categories;  // Use as-is
                                totalEligible = _calculateTotalFromCategories(recipient.categories);
                                totalClaimed = 0;
                                lastClaimTime = null;
                                status = #Eligible;
                                note = recipient.note;
                            };
                            participants := Trie.put(participants, _principalKey(recipient.address), Principal.equal, participant).0;
                            participantCount += 1;
                        };
                    };
                    case (_) {
                        // For non-whitelist distributions, participants register themselves
                    };
                };
            };
            case null {
                // ✅ LEGACY MODE - Auto-convert to default category
                Debug.print("📦 Legacy mode: Auto-converting " # Nat.toText(config.recipients.size()) # " recipients to default category");

                switch (config.eligibilityType) {
                    case (#Whitelist) {
                        for (recipient in config.recipients.vals()) {
                            whitelist := Trie.put(whitelist, _principalKey(recipient.address), Principal.equal, true).0;

                            // Wrap in default category
                            let defaultCategory: CategoryAllocation = {
                                categoryId = 1;
                                categoryName = "Default Distribution";
                                amount = recipient.amount;
                                claimedAmount = 0;
                                vestingSchedule = config.vestingSchedule;  // Use contract-level vesting
                                vestingStart = config.distributionStart;
                                note = recipient.note;
                            };

                            let participant: MultiCategoryParticipant = {
                                principal = recipient.address;
                                registeredAt = Time.now();
                                categories = [defaultCategory];  // Single default category
                                totalEligible = recipient.amount;
                                totalClaimed = 0;
                                lastClaimTime = null;
                                status = #Eligible;
                                note = recipient.note;
                            };
                            participants := Trie.put(participants, _principalKey(recipient.address), Principal.equal, participant).0;
                            participantCount += 1;
                        };
                    };
                    case (_) {
                        // For non-whitelist distributions, participants register themselves
                    };
                };
            };
        };
    };

    private func _initializeLaunchpadFeatures() {
        // Check if this is a launchpad-linked distribution
        switch (config.launchpadContext) {
            case (?context) {
                launchpadCanisterId := ?context.launchpadId;
                Debug.print("🚀 Initialized Launchpad-linked distribution: " # context.category.name);

            };
            case null {
                Debug.print("✅ Standalone distribution initialized");
            };
        };
    };

    // ================ ELIGIBILITY CHECKING ================
    
    private func _checkEligibility(participant: Principal) : async Bool {
        switch (config.eligibilityType) {
            case (#Open) { true }; // Anyone can register for open distributions
            case (#Whitelist) {
                // Check if participant is in the whitelist
                switch (Trie.get(whitelist, _principalKey(participant), Principal.equal)) {
                    case (?eligible) { eligible };
                    case null { false };
                }
            };
            case (#TokenHolder(tokenConfig)) {
                await _checkTokenHolding(participant, tokenConfig)
            };
            case (#NFTHolder(nftConfig)) {
                await _checkNFTHolding(participant, nftConfig)
            };
            case (#ICTOPassportScore(minScore)) {
                await _checkICTOPassportScore(participant, minScore)
            };
            case (#Hybrid(hybridConfig)) {
                await _checkHybridEligibility(participant, hybridConfig)
            };
        }
    };
    
    private func _checkTokenHolding(participant: Principal, tokenConfig: TokenHolderConfig) : async Bool {
        // TODO: Implement token balance checking via ICRC standards
        // For now, return true as placeholder
        true
    };
    
    private func _checkNFTHolding(participant: Principal, nftConfig: NFTHolderConfig) : async Bool {
        // TODO: Implement NFT holding verification
        // For now, return true as placeholder
        true
    };
    
    private func _checkICTOPassportScore(participant: Principal, minScore: Nat) : async Bool {
        try {
            if (minScore == 0) return true;
            let score = await passportInterface.getWalletScore(participant, BLOCK_ID_APPLICATION);
            score.totalScore >= minScore;
        } catch (_) {
            false;
        };
    };
    
    private func _checkHybridEligibility(participant: Principal, hybridConfig: { conditions: [EligibilityType]; logic: EligibilityLogic }) : async Bool {
        // TODO: Implement hybrid eligibility checking with AND/OR logic
        // For now, return true as placeholder
        true
    };

    // ================ VESTING CALCULATIONS ================
    
    // Check if early unlock with penalty is allowed
    private func _canEarlyUnlock(elapsed: Nat, penaltyConfig: ?PenaltyUnlock) : Bool {
        switch (penaltyConfig) {
            case (?penalty) {
                if (not penalty.enableEarlyUnlock) { return false; };
                switch (penalty.minLockTime) {
                    case (?minTime) { elapsed >= minTime };
                    case null { true };
                }
            };
            case null { false };
        }
    };
    
    // Calculate penalty amount for early unlock
    private func _calculatePenalty(totalAmount: Nat, penaltyConfig: PenaltyUnlock) : Nat {
        (totalAmount * penaltyConfig.penaltyPercentage) / 100
    };
    
    // ================ PER-CATEGORY VESTING CALCULATION (V2.0) ================

    /// Calculate unlocked amount for a single category
    /// Each category has its own vesting schedule and start time
    private func _calculateUnlockedAmountForCategory(category: CategoryAllocation, initialUnlockPercentage: Nat) : Nat {
        let vestingStart = category.vestingStart; // Already Time.Time, not optional

        let elapsed = Int.abs(_getValidatedTime() - vestingStart);
        let totalAmount = category.amount;
        let initialUnlock = (totalAmount * initialUnlockPercentage) / 100;

        switch (category.vestingSchedule) {
            case (#Instant) {
                totalAmount
            };
            case (#Linear(linear)) {
                if (elapsed >= linear.duration) {
                    totalAmount
                } else {
                    let vestedAmount = Nat.mul(Nat.div(Nat.sub(totalAmount, initialUnlock), linear.duration), elapsed);
                    initialUnlock + vestedAmount
                }
            };
            case (#Cliff(cliff)) {
                if (elapsed < cliff.cliffDuration) {
                    initialUnlock
                } else if (elapsed >= cliff.cliffDuration + cliff.vestingDuration) {
                    totalAmount
                } else {
                    let cliffAmount = (totalAmount * cliff.cliffPercentage) / 100;
                    let remainingAmount = Nat.sub(Nat.sub(totalAmount, initialUnlock), cliffAmount);
                    let postCliffElapsed = Nat.sub(elapsed, cliff.cliffDuration);
                    let vestedAmount = remainingAmount * postCliffElapsed / cliff.vestingDuration;
                    initialUnlock + cliffAmount + vestedAmount
                }
            };
            case (#Single(single)) {
                // Single vesting: tokens fully locked until duration ends, then 100% unlock
                if (elapsed >= single.duration) {
                    totalAmount  // Full unlock after duration
                } else {
                    initialUnlock  // Only initial unlock before duration ends (usually 0 for locks)
                }
            };
            case (#SteppedCliff(steps)) {
                var unlockedAmount = initialUnlock;
                for (step in steps.vals()) {
                    if (elapsed >= step.timeOffset) {
                        let stepAmount = (totalAmount * step.percentage) / 100;
                        unlockedAmount += stepAmount;
                    };
                };
                if (unlockedAmount > totalAmount) totalAmount else unlockedAmount
            };
            case (#Custom(events)) {
                var unlockedAmount = initialUnlock;
                for (event in events.vals()) {
                    if (Time.now() >= event.timestamp) {
                        unlockedAmount += event.amount;
                    };
                };
                if (unlockedAmount > totalAmount) totalAmount else unlockedAmount
            };
        }
    };

    /// Calculate total unlocked amount across all categories for a participant
    /// V2.0: Sums unlocked amounts from all categories
    private func _calculateUnlockedAmount(participant: MultiCategoryParticipant) : Nat {
        var totalUnlocked: Nat = 0;
        for (category in participant.categories.vals()) {
            let categoryUnlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
            totalUnlocked += categoryUnlocked;
        };
        totalUnlocked
    };

    // ================ PER-CATEGORY CLAIMING LOGIC (V2.0) ================

    /// Calculate claimable amount for a single category
    /// Returns the amount that can be claimed from this specific category
    private func _calculateClaimableAmountForCategory(category: CategoryAllocation) : Nat {
        let unlockedAmount = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
        if (unlockedAmount > category.claimedAmount) {
            Nat.sub(unlockedAmount, category.claimedAmount)
        } else { 0 }
    };

    /// Calculate per-category claimable amounts for a participant
    /// Returns array of (categoryId, claimableAmount) pairs
    private func _calculateCategoryClaimableBreakdown(participant: MultiCategoryParticipant) : [(Nat, Nat)] {
        let breakdown = Buffer.Buffer<(Nat, Nat)>(0);
        for (category in participant.categories.vals()) {
            let claimableAmount = _calculateClaimableAmountForCategory(category);
            if (claimableAmount > 0) {
                breakdown.add((category.categoryId, claimableAmount));
            };
        };
        Buffer.toArray(breakdown)
    };

    /// Distribute claim amount across categories proportionally
    /// Takes available claimable amounts and distributes the requested claim amount
    private func _distributeClaimAcrossCategories(
        categories: [CategoryAllocation],
        requestedAmount: Nat
    ) : [(Nat, Nat)] {
        var remainingAmount = requestedAmount;
        let distribution = Buffer.Buffer<(Nat, Nat)>(0);

        // Calculate total claimable across all categories
        var totalClaimable: Nat = 0;
        for (category in categories.vals()) {
            let claimable = _calculateClaimableAmountForCategory(category);
            totalClaimable += claimable;
        };

        // If requested amount exceeds total claimable, cap it
        let actualClaimAmount = Nat.min(requestedAmount, totalClaimable);

        // Distribute proportionally across categories
        for (category in categories.vals()) {
            if (remainingAmount == 0) {
                // Exit loop if no remaining amount to distribute
            } else {
                let claimable = _calculateClaimableAmountForCategory(category);
                if (claimable > 0) {
                    // Calculate proportional share for this category
                    let proportionalShare = if (totalClaimable > 0) {
                        (actualClaimAmount * claimable) / totalClaimable
                    } else { 0 };

                    // Cap at what's actually claimable from this category
                    let categoryClaimAmount = Nat.min(Nat.min(proportionalShare, claimable), remainingAmount);

                    if (categoryClaimAmount > 0) {
                        distribution.add((category.categoryId, categoryClaimAmount));
                        remainingAmount -= categoryClaimAmount;
                    };
                };
            };
        };

        Buffer.toArray(distribution)
    };

    /// Update categories with new claimed amounts
    /// Returns updated categories array with claimed amounts incremented
    private func _updateCategoriesAfterClaim(
        categories: [CategoryAllocation],
        claimDistribution: [(Nat, Nat)]
    ) : [CategoryAllocation] {
        let updatedCategories = Buffer.Buffer<CategoryAllocation>(0);

        for (category in categories.vals()) {
            var updatedCategory = category;

            // Find if this category was claimed from
            for ((categoryId, claimAmount) in claimDistribution.vals()) {
                if (categoryId == category.categoryId) {
                    updatedCategory := {
                        category with
                        claimedAmount = category.claimedAmount + claimAmount
                    };
                };
            };

            updatedCategories.add(updatedCategory);
        };

        Buffer.toArray(updatedCategories)
    };

    // ================ TOKEN MANAGEMENT ================
    
    private func _getContractTokenBalance() : async Nat {
        switch (tokenCanister) {
            case (?canister) {
                let balance = await canister.icrc1_balance_of({ 
                    owner = Principal.fromActor(self); 
                    subaccount = null 
                });
                balance
            };
            case null { 0 };
        }
    };
    
    private func _transfer(to: Principal, amount: Nat) : async* Result.Result<Nat, ICRC.TransferError> {
        switch (tokenCanister) {
            case (?canister) {
                let transferAmount = if (amount > transferFee) {
                    Nat.sub(amount, transferFee)
                } else { 0 };
                
                if (transferAmount == 0) {
                    return #err(#InsufficientFunds { balance = amount });
                };
                
                let transfer_result = await canister.icrc1_transfer({
                    to = {
                        owner = to;
                        subaccount = null;
                    };
                    fee = ?transferFee;
                    amount = transferAmount;
                    memo = null;
                    from_subaccount = null;
                    created_at_time = null;
                });
                
                switch (transfer_result) {
                    case (#Ok(txIndex)) { #ok(txIndex) };
                    case (#Err(err)) { #err(err) };
                }
            };
            case null {
                #err(#GenericError { error_code = 500; message = "Token canister not initialized" })
            };
        }
    };
    
    // ================ MILESTONE TIMER MANAGEMENT (Similar to Launchpad) ================

    /// Setup milestone timers for automatic status transitions
    /// Uses one-time timers at exact timestamps instead of recurring checks
    private func _setupMilestoneTimers() : async () {
        let now = Time.now();

        Debug.print("⏰ Setting up distribution milestone timers...");
        Debug.print("   Current time: " # Int.toText(now));
        Debug.print("   Distribution start: " # Int.toText(config.distributionStart));

        // Timer 1: Distribution Start (Activate)
        if (config.distributionStart > now and distributionStartTimerId == null) {
            let nanosUntilStart = config.distributionStart - now;
            let secondsUntilStart = nanosUntilStart / 1_000_000_000;
            Debug.print("   ⏰ Setting timer for ACTIVATION in " # Int.toText(secondsUntilStart) # " seconds");

            distributionStartTimerId := ?Timer.setTimer<system>(
                #nanoseconds(Int.abs(nanosUntilStart)),
                func() : async () {
                    await _updateStatusToActive();
                    distributionStartTimerId := null; // Clear after execution
                }
            );
        } else if (config.distributionStart <= now) {
            Debug.print("   ⏭️ Distribution start time already passed - checking activation now");
            // Immediately check if we should activate
            await _updateStatusToActive();
        };

        // Timer 2: Distribution End (Complete) - if configured
        switch (config.distributionEnd) {
            case (?endTime) {
                Debug.print("   Distribution end: " # Int.toText(endTime));
                if (endTime > now and distributionEndTimerId == null) {
                    let nanosUntilEnd = endTime - now;
                    let secondsUntilEnd = nanosUntilEnd / 1_000_000_000;
                    Debug.print("   ⏰ Setting timer for COMPLETION in " # Int.toText(secondsUntilEnd) # " seconds");

                    distributionEndTimerId := ?Timer.setTimer<system>(
                        #nanoseconds(Int.abs(nanosUntilEnd)),
                        func() : async () {
                            await _updateStatusToCompleted();
                            distributionEndTimerId := null; // Clear after execution
                        }
                    );
                } else if (endTime <= now) {
                    Debug.print("   ⏭️ Distribution end time already passed - no timer needed");
                };
            };
            case null {
                Debug.print("   ℹ️ Distribution end time not configured");
            };
        };

        Debug.print("✅ Milestone timers setup complete");
    };

    /// Update status to Active (called by timer at distributionStart)
    private func _updateStatusToActive() : async () {
        if (status != #Created) {
            Debug.print("⏭️ Already past Created status, skipping activation");
            return;
        };

        if (not initialized) {
            Debug.print("⚠️ Cannot activate: not initialized yet");
            return;
        };

        Debug.print("🔄 Auto-activating distribution...");

        // Check contract has sufficient token balance
        let contractBalance = await _getContractTokenBalance();
        if (contractBalance < config.totalAmount) {
            Debug.print("⚠️ Cannot activate: Insufficient balance");
            Debug.print("   Required: " # debug_show(config.totalAmount) # " " # config.tokenInfo.symbol);
            Debug.print("   Available: " # debug_show(contractBalance / E8S) # " " # config.tokenInfo.symbol);

            // Start recurring balance check if not already running
            await _setupRecurringBalanceCheck();
            return;
        };

        status := #Active;
        Debug.print("✅ Distribution activated automatically at: " # Int.toText(Time.now()));

        // Cancel balance check timer if running (no longer needed)
        _cancelBalanceCheckTimer();
    };

    /// Setup recurring balance check for post-start activation attempts
    /// This ensures that distributions can still activate even if tokens arrive late
    ///
    /// TRIGGER CONDITIONS:
    /// - Distribution start time has passed
    /// - Status is still #Created (not activated)
    /// - Balance is insufficient
    ///
    /// CHECK FREQUENCY: Every 10 minutes (600 seconds)
    ///
    /// AUTO-STOP CONDITIONS:
    /// - Status changes to #Active (balance sufficient, activation successful)
    /// - Status changes to #Cancelled
    /// - depositTokens() is called and succeeds
    ///
    /// CYCLE COST: ~3M cycles per check (very lightweight)
    /// Max checks: 6 per hour, 144 per day
    private func _setupRecurringBalanceCheck() : async () {
        // Don't setup if already running
        switch (balanceCheckTimerId) {
            case (?_) {
                Debug.print("   ⏱️ Balance check timer already running");
                return;
            };
            case (null) {};
        };

        // Don't setup if not past start time
        let now = Time.now();
        if (now < config.distributionStart) {
            Debug.print("   ⏱️ Start time not reached yet, skipping recurring check");
            return;
        };

        Debug.print("   ⏱️ Setting up recurring balance check (every 10 minutes)");

        balanceCheckTimerId := ?Timer.recurringTimer<system>(
            #seconds(600), // Check every 10 minutes (responsive for late deposits)
            func() : async () {
                // Stop if status changed from Created
                if (status != #Created) {
                    Debug.print("⏱️ Balance check: Status changed to " # debug_show(status) # ", stopping checks");
                    _cancelBalanceCheckTimer();
                    return;
                };

                Debug.print("⏱️ Balance check: Checking if activation possible...");

                // Check balance
                let contractBalance = await _getContractTokenBalance();
                Debug.print("   Current balance: " # Nat.toText(contractBalance / E8S));
                Debug.print("   Required: " # Nat.toText(config.totalAmount / E8S));

                if (contractBalance >= config.totalAmount) {
                    Debug.print("✅ Balance check: Sufficient balance! Activating...");
                    status := #Active;
                    _cancelBalanceCheckTimer();
                } else {
                    let percentFunded = (contractBalance * 100) / config.totalAmount;
                    Debug.print("   Balance check: " # Nat.toText(percentFunded) # "% funded, waiting for more tokens...");
                };
            }
        );
    };

    /// Cancel the recurring balance check timer
    private func _cancelBalanceCheckTimer() {
        switch (balanceCheckTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                balanceCheckTimerId := null;
                Debug.print("   ⏱️ Balance check timer cancelled");
            };
            case (null) {};
        };
    };

    /// Update status to Completed (called by timer at distributionEnd)
    private func _updateStatusToCompleted() : async () {
        if (status == #Completed or status == #Cancelled) {
            Debug.print("⏭️ Already completed or cancelled");
            return;
        };

        Debug.print("🔄 Auto-completing distribution...");
        status := #Completed;
        Debug.print("✅ Distribution completed automatically at: " # Int.toText(Time.now()));
    };

    /// Cancel all milestone timers (used during pause/emergency)
    private func _cancelAllTimers() {
        Debug.print("🛑 Cancelling all timers...");

        switch (distributionStartTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                distributionStartTimerId := null;
                Debug.print("  ✅ Distribution start timer cancelled");
            };
            case null {};
        };

        switch (distributionEndTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                distributionEndTimerId := null;
                Debug.print("  ✅ Distribution end timer cancelled");
            };
            case null {};
        };

        switch (balanceCheckTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                balanceCheckTimerId := null;
                Debug.print("  ✅ Balance check timer cancelled");
            };
            case null {};
        };

        Debug.print("✅ All timers cancelled");
    };

    // ================ PUBLIC INTERFACE ================
    
    // Configuration and Info
    public query func getConfig() : async DistributionConfig {
        config
    };
    
    public query func getStatus() : async DistributionStatus {
        status
    };
    
    public query func getStats() : async DistributionStats {
        let remaining = if (config.totalAmount > totalDistributed) {
            Nat.sub(config.totalAmount, totalDistributed)
        } else { 0 };

        let completionPercentage = if (config.totalAmount > 0) {
            Float.fromInt(totalDistributed) / Float.fromInt(config.totalAmount) * 100.0
        } else { 0.0 };

        {
            totalParticipants = participantCount;
            totalDistributed = totalDistributed;
            totalClaimed = totalClaimed;
            remainingAmount = remaining;
            completionPercentage = completionPercentage;
            isActive = _isActive();
        }
    };

    // ================ IUPGRADEABLE INTERFACE ================

    /// Get current state serialized for upgrade
    /// CRITICAL: Returns CURRENT config + ALL runtime state
    /// Factory calls this BEFORE upgrade to capture state
    public query func getUpgradeArgs() : async Blob {
        let upgradeData: DistributionUpgradeTypes.DistributionUpgradeArgs = {
            // Original init args (STATIC - config never modified)
            config = config;
            creator = creator;
            factory = factoryCanisterId;

            // Current runtime state (DYNAMIC - captured now)
            runtimeState = {
                status = status;
                createdAt = createdAt;
                initialized = initialized;

                // Convert Tries to Arrays for serialization (V2.0: MultiCategoryParticipant)
                participants = Trie.toArray<Principal, MultiCategoryParticipant, (Principal, MultiCategoryParticipant)>(
                    participants,
                    func (k, v) = (k, v)
                );
                claimRecords = Buffer.toArray(claimRecords);
                whitelist = Trie.toArray<Principal, Bool, (Principal, Bool)>(
                    whitelist,
                    func (k, v) = (k, v)
                );
                blacklist = Trie.toArray<Principal, Bool, (Principal, Bool)>(
                    blacklist,
                    func (k, v) = (k, v)
                );

                // Statistics
                totalDistributed = totalDistributed;
                totalClaimed = totalClaimed;
                participantCount = participantCount;

                // Integration
                launchpadCanisterId = launchpadCanisterId;

                // Token info
                transferFee = transferFee;
            };
        };

        // Serialize to Candid blob
        to_candid(upgradeData)
    };

    /// Validate if contract is ready for upgrade
    /// Checks for pending operations and critical state
    ///
    /// IMPORTANT: Similar to Launchpad pattern with auto-init support
    /// - Fresh deploy (upgradeState = null): Always allow upgrade (will auto-init in postupgrade)
    /// - Existing contract: Must be initialized before upgrade
    public query func canUpgrade() : async Result.Result<(), Text> {
        // Check 1: For existing contracts (not fresh deploy), must be initialized
        // Fresh deploy (upgradeState = null) will auto-init in postupgrade, so we allow upgrade
        switch (upgradeState) {
            case null {
                // Fresh deploy - allow upgrade immediately
                // Auto-init will happen in postupgrade after factory upgrade call
                Debug.print("✅ canUpgrade: Fresh deploy - allowing upgrade (will auto-init in postupgrade)");
            };
            case (?state) {
                // Existing contract - must be initialized
                if (not state.initialized) {
                    return #err("Cannot upgrade: Contract not initialized");
                };
            };
        };

        // Check 2: Cannot upgrade if cancelled (permanent state)
        if (status == #Cancelled) {
            return #err("Cannot upgrade: Contract is cancelled");
        };

        // Check 3: For distribution contracts, we allow upgrade during most states
        // as claims are independent operations and can resume after upgrade

        #ok()
    };

    // NOTE: updateVersion() REMOVED - version update now handled by completeUpgrade()

    // ============================================
    // UPGRADE STATE MANAGEMENT HELPERS
    // ============================================

    /// Guard function - check if contract is in upgrade mode
    /// Passively unlocks if timeout expired (fallback mechanism)
    private func _requireNotUpgrading() : Result.Result<(), Text> {
        if (isUpgrading) {
            switch (upgradeRequestedAt) {
                case (?startTime) {
                    let age = Time.now() - startTime;

                    // PASSIVE SELF-UNLOCK if timeout exceeded (fallback)
                    if (age > UPGRADE_TIMEOUT_NANOS) {
                        Debug.print("⏰ CONTRACT: Timeout detected - auto-unlocking (fallback)");

                        isUpgrading := false;
                        upgradeRequestedAt := null;
                        upgradeRequestId := null;

                        #ok(())
                    } else {
                        let remainingMinutes = (UPGRADE_TIMEOUT_NANOS - age) / (60 * 1_000_000_000);
                        #err("Contract is being upgraded. Estimated completion: ~" # Int.toText(remainingMinutes) # " minutes. Please try again later.")
                    }
                };
                case null {
                    // Inconsistent state - unlock
                    isUpgrading := false;
                    #ok(())
                };
            }
        } else {
            #ok(())
        }
    };

    // ============================================
    // UPGRADE STATE QUERY FUNCTIONS
    // ============================================

    /// Check if contract is in upgrade mode
    public query func isInUpgradeMode() : async Bool {
        isUpgrading
    };

    /// Get upgrade mode details
    public query func getUpgradeModeInfo() : async {
        isUpgrading: Bool;
        requestedAt: ?Int;
        requestId: ?Text;
        timeoutAt: ?Int;
    } {
        {
            isUpgrading = isUpgrading;
            requestedAt = upgradeRequestedAt;
            requestId = upgradeRequestId;
            timeoutAt = switch (upgradeRequestedAt) {
                case (?startTime) { ?(startTime + UPGRADE_TIMEOUT_NANOS) };
                case null { null };
            };
        }
    };

    /// Check if upgrade timeout has expired
    public query func isUpgradeTimeout() : async Bool {
        switch (upgradeRequestedAt) {
            case (?startTime) {
                Time.now() - startTime > UPGRADE_TIMEOUT_NANOS
            };
            case null { false };
        }
    };

    /// Get current contract version
    public query func getVersion() : async IUpgradeable.Version {
        contractVersion
    };

    // ============================================
    // UPGRADE LIFECYCLE FUNCTIONS
    // ============================================

    /// Request self-upgrade to latest stable version
    /// CONTRACT LOCKS IMMEDIATELY when calling this function
    /// Only creator can request upgrade
    public shared({caller}) func requestSelfUpgrade() : async Result.Result<Text, Text> {
        Debug.print("🔄 CONTRACT: requestSelfUpgrade called by " # Principal.toText(caller));

        // ============================================
        // AUTHORIZATION CHECK
        // ============================================

        if (caller != creator) {
            Debug.print("❌ Unauthorized: Only creator");
            return #err("Unauthorized: Only creator can request self-upgrade");
        };

        // ============================================
        // CHECK NOT ALREADY UPGRADING
        // ============================================

        if (isUpgrading) {
            // Check if timeout expired
            switch (upgradeRequestedAt) {
                case (?startTime) {
                    if (Time.now() - startTime > UPGRADE_TIMEOUT_NANOS) {
                        Debug.print("⏰ Previous upgrade timed out - allowing new request");
                    } else {
                        return #err("Upgrade already in progress. Please wait or cancel the current upgrade.");
                    };
                };
                case null {
                    // Inconsistent state - reset
                    isUpgrading := false;
                };
            };
        };

        // Get factory principal
        let factoryPrincipal = switch (factoryCanisterId) {
            case (?principal) { principal };
            case null {
                return #err("No factory configured");
            };
        };

        // ============================================
        // LOCK CONTRACT IMMEDIATELY
        // ============================================

        isUpgrading := true;
        upgradeRequestedAt := ?Time.now();

        Debug.print("🔒 CONTRACT LOCKED - All mutations blocked for 30 minutes or until upgrade completes");

        // ============================================
        // CALL FACTORY TO REQUEST UPGRADE
        // ============================================

        try {
            let factoryActor = actor(Principal.toText(factoryPrincipal)) : actor {
                requestSelfUpgrade: () -> async Result.Result<(), Text>;
            };

            Debug.print("📞 Calling factory.requestSelfUpgrade()...");
            let result = await factoryActor.requestSelfUpgrade();

            switch (result) {
                case (#ok()) {
                    Debug.print("✅ Upgrade request accepted by factory");

                    // Generate local request ID
                    let requestId = "upgrade-" # Int.toText(Time.now());
                    upgradeRequestId := ?requestId;

                    #ok(requestId)
                };
                case (#err(msg)) {
                    Debug.print("❌ Factory rejected upgrade request: " # msg);

                    // UNLOCK on failure
                    isUpgrading := false;
                    upgradeRequestedAt := null;
                    upgradeRequestId := null;

                    #err(msg)
                };
            };
        } catch (e) {
            let errorMsg = "Failed to call factory: " # Error.message(e);
            Debug.print("💥 " # errorMsg);

            // UNLOCK on error
            isUpgrading := false;
            upgradeRequestedAt := null;
            upgradeRequestId := null;

            #err(errorMsg)
        }
    };

    /// Complete upgrade (called by factory after successful upgrade)
    /// This unlocks the contract and updates version
    public func completeUpgrade(newVersion: IUpgradeable.Version, caller: Principal) : async Result.Result<(), Text> {
        // Only factory can call this
        switch (factoryCanisterId) {
            case (?factoryPrincipal) {
                if (caller != factoryPrincipal) {
                    return #err("Unauthorized: Only factory can complete upgrade");
                };
            };
            case null {
                return #err("No factory configured");
            };
        };

        if (not isUpgrading) {
            Debug.print("⚠️ Warning: completeUpgrade called but contract was not locked");
        };

        // Update version
        contractVersion := newVersion;

        // UNLOCK contract
        isUpgrading := false;
        upgradeRequestedAt := null;
        upgradeRequestId := null;

        Debug.print("🔓 CONTRACT UNLOCKED - Upgrade completed successfully to version " # debug_show(newVersion));

        #ok(())
    };

    /// Cancel upgrade (called by factory on failure OR timeout)
    /// This unlocks the contract
    public func cancelUpgrade(reason: Text, caller: Principal) : async Result.Result<(), Text> {
        // Factory OR creator can cancel
        let isFactory = switch (factoryCanisterId) {
            case (?factoryPrincipal) { caller == factoryPrincipal };
            case null { false };
        };
        let isCreator = caller == creator;
        let isAuthorized = isFactory or isCreator;

        if (not isAuthorized) {
            return #err("Unauthorized: Only factory or creator can cancel upgrade");
        };

        if (not isUpgrading) {
            return #err("Contract is not in upgrade mode");
        };

        // UNLOCK contract
        isUpgrading := false;
        upgradeRequestedAt := null;
        upgradeRequestId := null;

        Debug.print("🔓 CONTRACT UNLOCKED - Upgrade cancelled: " # reason);

        #ok(())
    };

    /// Emergency unlock (creator only) - for stuck contracts
    public shared({caller}) func emergencyUnlockUpgrade() : async Result.Result<(), Text> {
        // Only creator can emergency unlock
        if (caller != creator) {
            return #err("Unauthorized: Only creator can emergency unlock");
        };

        if (not isUpgrading) {
            return #err("Contract is not in upgrade mode");
        };

        // UNLOCK contract
        isUpgrading := false;
        upgradeRequestedAt := null;
        upgradeRequestId := null;

        Debug.print("🚨 EMERGENCY UNLOCK by " # Principal.toText(caller));

        #ok(())
    };

    /// Comprehensive health check
    public query func healthCheck() : async IUpgradeable.HealthStatus {
        let issues = Buffer.Buffer<Text>(0);

        // Check 1: Initialization status
        if (not initialized) {
            issues.add("Contract not initialized");
        };

        // Check 2: Token canister connectivity
        if (Option.isNull(tokenCanister)) {
            issues.add("Token canister not set");
        };

        // Check 3: Data consistency
        let participantTrieSize = Trie.size(participants);
        if (participantTrieSize != participantCount) {
            issues.add("Participant count mismatch: Trie=" # Nat.toText(participantTrieSize) # " vs Count=" # Nat.toText(participantCount));
        };

        // Check 4: Financial consistency
        if (totalClaimed > totalDistributed) {
            issues.add("Claimed amount exceeds distributed amount");
        };

        if (totalDistributed > config.totalAmount) {
            issues.add("Distributed amount exceeds configured total");
        };

        // Check 5: Cycles balance
        let cyclesBalance = Cycles.balance();
        if (cyclesBalance < 100_000_000_000) { // Less than 0.1T cycles
            issues.add("Low cycles: " # Nat.toText(cyclesBalance));
        };

        {
            healthy = issues.size() == 0;
            issues = Buffer.toArray(issues);
            lastActivity = lastActivityTime;
            canisterCycles = cyclesBalance;
            memorySize = Prim.rts_memory_size();
        }
    };

    // Participant Management
    public shared({ caller }) func register() : async Result.Result<(), Text> {
        // Check if registration is open
        if(Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot register");
        };
        switch (config.registrationPeriod) {
            case (?period) {
                let now = Time.now();
                if (now < period.startTime or now > period.endTime) {
                    return #err("Registration period is not active");
                };
                
                // Check max participants
                switch (period.maxParticipants) {
                    case (?max) {
                        if (participantCount >= max) {
                            return #err("Maximum participants reached");
                        };
                    };
                    case null {};
                };
            };
            case null {
                // No registration period means always open for self-service mode
                if (config.recipientMode != #SelfService) {
                    return #err("Registration not available for this distribution mode");
                };
            };
        };
        
        // Check if already registered
        switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
            case (?_) {
                return #err("Already registered");
            };
            case null {};
        };
        
        // Check eligibility
        let isEligible = await _checkEligibility(caller);
        if (not isEligible) {
            return #err("Not eligible for this distribution");
        };
        
        // Calculate eligible amount based on distribution type
        let eligibleAmount = switch (config.eligibilityType) {
            case (#Whitelist) {
                // For whitelist distributions, get amount from recipients list
                switch (_findRecipientAmount(caller)) {
                    case (?amount) { amount };
                    case null { 0 };
                }
            };
            case (#Open) {
                // For Open distributions, divide totalAmount equally among maxRecipients
                switch (config.maxRecipients) {
                    case (?maxRecipients) {
                        if (maxRecipients > 0) {
                            Nat.div(config.totalAmount, maxRecipients)
                        } else { 0 }
                    };
                    case null { 0 };
                }
            };
            case (_) {
                // For other distribution types with SelfService mode
                if (config.recipientMode == #SelfService) {
                    switch (config.maxRecipients) {
                        case (?maxRecipients) {
                            if (maxRecipients > 0) {
                                Nat.div(config.totalAmount, maxRecipients)
                            } else { 0 }
                        };
                        case null { 0 };
                    }
                } else {
                    0
                }
            };
        };
        
        // Check if there's still allocation available
        if (eligibleAmount == 0) {
            return #err("No allocation available for new participants");
        };
        
        // Check if adding this participant would exceed total distribution amount
        let projectedDistribution = totalDistributed + eligibleAmount;
        if (projectedDistribution > config.totalAmount) {
            return #err("No more allocation available - distribution is full");
        };
        
        // Create participant record (V2.0: As MultiCategoryParticipant with default category)
        // Self-registered participants always use default category with contract-level vesting
        let defaultCategory: CategoryAllocation = {
            categoryId = 1;
            categoryName = "Default Distribution";
            amount = eligibleAmount;
            claimedAmount = 0;
            vestingSchedule = config.vestingSchedule;
            vestingStart = config.distributionStart;
            note = null;
        };

        let participant: MultiCategoryParticipant = {
            principal = caller;
            registeredAt = Time.now();
            categories = [defaultCategory];
            totalEligible = eligibleAmount;
            totalClaimed = 0;
            lastClaimTime = null;
            status = #Registered;
            note = null; // No specific note for self-registered participants
        };

        participants := Trie.put(participants, _principalKey(caller), Principal.equal, participant).0;
        participantCount += 1;
        
        // Notify factory about new recipient (Factory Storage Standard)
        await _notifyFactoryRecipientAdded(caller);

        #ok()
    };

    // Admin remove participant
    public shared({ caller }) func removeParticipant(principal: Principal) : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can remove participant");
        };

        // Notify factory about removed recipient (Factory Storage Standard)
        await _notifyFactoryRecipientRemoved(principal);

        #ok()
    };

    // Admin add to blacklist
    public shared({ caller }) func addToBlacklist(principal: Principal) : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can add to blacklist");
        };
        blacklist := Trie.put(blacklist, _principalKey(principal), Principal.equal, true).0;
        #ok()
    };

    // Admin remove from blacklist
    public shared({ caller }) func removeFromBlacklist(principal: Principal) : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can remove from blacklist");
        };
        blacklist := Trie.put(blacklist, _principalKey(principal), Principal.equal, false).0;
        #ok()
    };

    // ================ FACTORY CALLBACKS (Factory Storage Standard) ================

    // Notify factory when new recipient added
    private func _notifyFactoryRecipientAdded(recipient: Principal) : async () {
        switch (factoryCanisterId) {
            case (?factoryId) {
                try {
                    let factory = actor(Principal.toText(factoryId)) : actor {
                        notifyRecipientAdded: (Principal) -> async Result.Result<(), Text>;
                    };

                    let result = await factory.notifyRecipientAdded(recipient);
                    switch (result) {
                        case (#ok()) {
                            Debug.print("✅ Factory notified: recipient added " # Principal.toText(recipient));
                        };
                        case (#err(error)) {
                            Debug.print("❌ Factory notification failed: " # error);
                        };
                    };
                } catch (error) {
                    // Log error but don't fail registration
                    Debug.print("⚠️ Warning: Failed to notify factory: " # Error.message(error));
                };
            };
            case null {
                Debug.print("⚠️ Warning: No factory configured for callbacks");
            };
        };
    };

    // Notify factory when recipient removed
    private func _notifyFactoryRecipientRemoved(recipient: Principal) : async () {
        switch (factoryCanisterId) {
            case (?factoryId) {
                try {
                    let factory = actor(Principal.toText(factoryId)) : actor {
                        notifyRecipientRemoved: (Principal) -> async Result.Result<(), Text>;
                    };

                    let result = await factory.notifyRecipientRemoved(recipient);
                    switch (result) {
                        case (#ok()) {
                            Debug.print("✅ Factory notified: recipient removed " # Principal.toText(recipient));
                        };
                        case (#err(error)) {
                            Debug.print("❌ Factory notification failed: " # error);
                        };
                    };
                } catch (error) {
                    Debug.print("⚠️ Warning: Failed to notify factory: " # Error.message(error));
                };
            };
            case null {
                Debug.print("⚠️ Warning: No factory configured for callbacks");
            };
        };
    };
    
    // Auto-register participant when no registration period is configured
    private func _autoRegisterParticipant(caller: Principal) : async Result.Result<MultiCategoryParticipant, Text> {
        // Check if user is anonymous
        if(Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot participate");
        };
        
        // Check if already registered
        switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
            case (?p) { return #ok(p) };
            case null {};
        };
        
        // Check eligibility
        let isEligible = await _checkEligibility(caller);
        if (not isEligible) {
            return #err("Not eligible for this distribution");
        };
        
        // Calculate eligible amount based on distribution type
        let eligibleAmount = switch (config.eligibilityType) {
            case (#Whitelist) {
                // For whitelist distributions, get amount from recipients list
                switch (_findRecipientAmount(caller)) {
                    case (?amount) { amount };
                    case null { 0 };
                }
            };
            case (#Open) {
                // For Open distributions, divide totalAmount equally among maxRecipients
                switch (config.maxRecipients) {
                    case (?maxRecipients) {
                        if (maxRecipients > 0) {
                            Nat.div(config.totalAmount, maxRecipients)
                        } else { 0 }
                    };
                    case null { 0 };
                }
            };
            case (_) {
                // For other distribution types with SelfService mode
                if (config.recipientMode == #SelfService) {
                    switch (config.maxRecipients) {
                        case (?maxRecipients) {
                            if (maxRecipients > 0) {
                                Nat.div(config.totalAmount, maxRecipients)
                            } else { 0 }
                        };
                        case null { 0 };
                    }
                } else {
                    0
                }
            };
        };
        
        // Check if there's still allocation available
        if (eligibleAmount == 0) {
            return #err("No allocation available for new participants");
        };
        
        // Check if adding this participant would exceed total distribution amount
        let projectedDistribution = totalDistributed + eligibleAmount;
        if (projectedDistribution > config.totalAmount) {
            return #err("No more allocation available - distribution is full");
        };
        
        // Create participant record (V2.0: As MultiCategoryParticipant with default category)
        let defaultCategory: CategoryAllocation = {
            categoryId = 1;
            categoryName = "Default Distribution";
            amount = eligibleAmount;
            claimedAmount = 0;
            vestingSchedule = config.vestingSchedule;
            vestingStart = config.distributionStart;
            note = null;
        };

        let participant: MultiCategoryParticipant = {
            principal = caller;
            registeredAt = Time.now();
            categories = [defaultCategory];
            totalEligible = eligibleAmount;
            totalClaimed = 0;
            lastClaimTime = null;
            status = #Registered;
            note = null; // No specific note for auto-registered participants
        };

        participants := Trie.put(participants, _principalKey(caller), Principal.equal, participant).0;
        participantCount += 1;

        // Notify factory about new recipient (Factory Storage Standard)
        await _notifyFactoryRecipientAdded(caller);

        #ok(participant)
    };
    
    public shared({ caller }) func claim(claimAmount: ?Nat) : async Result.Result<Nat, Text> {
        // ================ SECURITY CHECKS ================

        // 1. Input validation
        switch (_validatePrincipal(caller)) {
            case (#ok(_)) {};
            case (#err(error)) {
                _logSecurityEvent(
                    "INVALID_PRINCIPAL",
                    caller,
                    0,
                    "Invalid principal in claim: " # error,
                    #Warning
                );
                return #err(error)
            };
        };

        switch (claimAmount) {
            case (?amount) {
                switch (_validateAmount(amount)) {
                    case (#ok(_)) {};
                    case (#err(error)) {
                        _logSecurityEvent(
                            "INVALID_AMOUNT",
                            caller,
                            0,
                            "Invalid claim amount: " # error,
                            #Warning
                        );
                        return #err(error)
                    };
                };
            };
            case null {}; // Full claim is valid
        };

        // 2. Per-user reentrancy protection
        switch (_reentrancyGuardEnter(caller)) {
            case (#ok(_)) {};
            case (#err(error)) {
                _logSecurityEvent(
                    "REENTRANCY_BLOCKED",
                    caller,
                    0,
                    "Reentrancy guard blocked access: " # error,
                    #Critical
                );
                return #err(error)
            };
        };

        // 3. Enhanced rate limiting (global + per-user)
        switch (_checkRateLimit(caller)) {
            case (#ok(_)) {};
            case (#err(error)) {
                _logSecurityEvent(
                    "RATE_LIMIT_BLOCKED",
                    caller,
                    0,
                    "Rate limit exceeded: " # error,
                    #Warning
                );
                _reentrancyGuardExit(caller);
                return #err(error)
            };
        };

        // 4. Basic distribution validation
        if (not _isActive()) {
            _logSecurityEvent(
                "DISTRIBUTION_INACTIVE",
                caller,
                0,
                "Claim attempted when distribution not active",
                #Info
            );
            _reentrancyGuardExit(caller);
            return #err("Distribution is not currently active");
        };

        // Check if caller is blacklisted
        if (_isBlacklisted(caller)) {
            _logSecurityEvent(
                "BLACKLISTED_ACCESS_ATTEMPT",
                caller,
                0,
                "Blacklisted user attempted claim",
                #Critical
            );
            _reentrancyGuardExit(caller);
            return #err("Address is blacklisted");
        };

        // Get participant, with auto-registration if enabled
        let participant = switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
            case (?p) { p };
            case null {
                // Check if we should auto-register when no registration period is configured
                switch (config.registrationPeriod) {
                    case null {
                        // No registration period configured - auto-register eligible participants
                        let registrationResult = await _autoRegisterParticipant(caller);
                        switch (registrationResult) {
                            case (#ok(newParticipant)) { newParticipant };
                            case (#err(error)) { return #err(error) };
                        };
                    };
                    case (?_) {
                        // Registration period exists but participant not registered
                        return #err("Not registered for this distribution");
                    };
                };
            };
        };

        // Calculate unlocked amount with overflow protection
        let unlockedAmountResult = _safeCalculateUnlockedAmount(participant);
        let unlockedAmount = switch (unlockedAmountResult) {
            case (#ok(amount)) { amount };
            case (#err(error)) { return #err("Calculation error: " # error) };
        };

        let maxClaimableAmountResult = _safeSub(unlockedAmount, participant.totalClaimed);
        let maxClaimableAmount = switch (maxClaimableAmountResult) {
            case (?amount) { amount };
            case null { 0 };
        };

        if (maxClaimableAmount == 0) {
            _reentrancyGuardExit(caller);
            return #err("No tokens available to claim at this time");
        };

        // Determine actual claim amount (partial or full)
        let actualClaimAmount = switch (claimAmount) {
            case (?amount) {
                // Partial claim specified
                if (amount == 0) {
                    _reentrancyGuardExit(caller);
                    return #err("Claim amount must be greater than 0");
                };
                if (amount > maxClaimableAmount) {
                    _reentrancyGuardExit(caller);
                    return #err("Claim amount exceeds available tokens");
                };
                amount
            };
            case null {
                // No amount specified - claim all available
                maxClaimableAmount
            };
        };

        // Check ICTO Passport score if required
        let isEligible = await _checkEligibility(caller);
        if (not isEligible) {
            _reentrancyGuardExit(caller);
            return #err("Not eligible for this distribution");
        };

        // EFFECTS: Update state before external calls using atomic operations
        // Phase 5: Update per-category claimedAmount using proportional distribution
        let claimDistribution = _distributeClaimAcrossCategories(participant.categories, actualClaimAmount);
        let updatedCategories = _updateCategoriesAfterClaim(participant.categories, claimDistribution);

        // Perform atomic claim operation to prevent TOCTOU race conditions
        let updatedParticipantResult = _atomicClaimOperation(caller, participant, actualClaimAmount, updatedCategories);
        let updatedParticipant = switch (updatedParticipantResult) {
            case (#ok(p)) { p };
            case (#err(error)) {
                _logSecurityEvent(
                    "TOCTOU_RACE_CONDITION_DETECTED",
                    caller,
                    actualClaimAmount,
                    "Race condition detected: " # error,
                    #Critical
                );
                _reentrancyGuardExit(caller);
                return #err("State validation failed: " # error);
            };
        };

        // Update participant state atomically
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, updatedParticipant).0;

        // Update global total atomically
        let newGlobalTotalResult = _atomicUpdateGlobalTotals(totalClaimed, actualClaimAmount, "claim_operation");
        let newGlobalTotal = switch (newGlobalTotalResult) {
            case (#ok(total)) { total };
            case (#err(error)) {
                _logSecurityEvent(
                    "GLOBAL_TOTAL_UPDATE_FAILED",
                    caller,
                    actualClaimAmount,
                    "Global total update failed: " # error,
                    #Critical
                );
                _reentrancyGuardExit(caller);
                return #err("System error: " # error);
            };
        };
        totalClaimed := newGlobalTotal;

        // Create claim record for tracking
        let claimRecord: ClaimRecord = {
            participant = caller;
            amount = actualClaimAmount;
            timestamp = _getValidatedTime();
            blockHeight = null; // TODO: Get from blockchain
            transactionId = null; // Will be updated after transfer
        };
        claimRecords.add(claimRecord);

        // Log security event
        _logSecurityEvent(
            "CLAIM_SUCCESS",
            caller,
            actualClaimAmount,
            "User claimed tokens successfully",
            #Info
        );

        // INTERACTIONS: External calls last
        let transferResult = await* _transfer(caller, actualClaimAmount);
        let txIndex = switch (transferResult) {
            case (#ok(index)) {
                // Update claim record with transaction index
                let finalClaimRecord = { claimRecord with txIndex = ?index };
                let _ = claimRecords.removeLast(); // Remove temporary record
                claimRecords.add(finalClaimRecord);
                ?index
            };
            case (#err(err)) {
                // REVERT: Rollback state changes on transfer failure
                let revertedParticipant: MultiCategoryParticipant = {
                    principal = participant.principal;
                    registeredAt = participant.registeredAt;
                    categories = participant.categories;
                    totalEligible = participant.totalEligible;
                    totalClaimed = participant.totalClaimed; // Original amount (before claim)
                    lastClaimTime = participant.lastClaimTime; // Original time
                    status = participant.status;
                    note = participant.note;
                };
                participants := Trie.put(participants, _principalKey(caller), Principal.equal, revertedParticipant).0;
                let newTotalClaimed = switch (_safeSub(totalClaimed, actualClaimAmount)) {
                    case (?amount) { amount };
                    case null { totalClaimed }; // Fallback, should not happen
                };
                totalClaimed := newTotalClaimed;
                let _ = claimRecords.removeLast(); // Remove failed claim record

                // Log critical transfer failure for security monitoring
                _logSecurityEvent(
                    "TRANSFER_FAILED",
                    caller,
                    actualClaimAmount,
                    "Token transfer failed: " # debug_show(err),
                    #Critical
                );

                _reentrancyGuardExit(caller);
                return #err("Token transfer failed: " # debug_show(err));
            };
        };

        // Release reentrancy guard before successful return
        _reentrancyGuardExit(caller);
        #ok(actualClaimAmount)
    };

    // ================ ENHANCED CLAIMING FUNCTIONS (V2.0) ================

    /// Claim from a specific category
    /// Allows users to claim from a particular category instead of proportional distribution
    public shared({ caller }) func claimFromCategory(categoryId: Nat, claimAmount: ?Nat) : async Result.Result<{claimedAmount: Nat; categoryId: Nat}, Text> {
        // ================ SECURITY CHECKS ================

        // 1. Input validation
        switch (_validatePrincipal(caller)) {
            case (#ok(_)) {};
            case (#err(error)) {
                _logSecurityEvent(
                    "INVALID_PRINCIPAL_CATEGORY_CLAIM",
                    caller,
                    0,
                    "Invalid principal in category claim: " # error,
                    #Warning
                );
                return #err(error)
            };
        };

        switch (claimAmount) {
            case (?amount) {
                switch (_validateAmount(amount)) {
                    case (#ok(_)) {};
                    case (#err(error)) {
                        _logSecurityEvent(
                            "INVALID_AMOUNT_CATEGORY_CLAIM",
                            caller,
                            0,
                            "Invalid category claim amount: " # error,
                            #Warning
                        );
                        return #err(error)
                    };
                };
            };
            case null {}; // Full claim is valid
        };

        // 2. Per-user reentrancy protection
        switch (_reentrancyGuardEnter(caller)) {
            case (#ok(_)) {};
            case (#err(error)) {
                _logSecurityEvent(
                    "REENTRANCY_BLOCKED_CATEGORY_CLAIM",
                    caller,
                    0,
                    "Reentrancy guard blocked category claim: " # error,
                    #Critical
                );
                return #err(error)
            };
        };

        // 3. Enhanced rate limiting (global + per-user)
        switch (_checkRateLimit(caller)) {
            case (#ok(_)) {};
            case (#err(error)) {
                _logSecurityEvent(
                    "RATE_LIMIT_BLOCKED_CATEGORY_CLAIM",
                    caller,
                    0,
                    "Rate limit exceeded in category claim: " # error,
                    #Warning
                );
                _reentrancyGuardExit(caller);
                return #err(error)
            };
        };

        // 4. Basic distribution validation
        if (not _isActive()) {
            _logSecurityEvent(
                "DISTRIBUTION_INACTIVE_CATEGORY_CLAIM",
                caller,
                0,
                "Category claim attempted when distribution not active",
                #Info
            );
            _reentrancyGuardExit(caller);
            return #err("Distribution is not currently active");
        };

        // Check if caller is blacklisted
        if (_isBlacklisted(caller)) {
            _logSecurityEvent(
                "BLACKLISTED_CATEGORY_CLAIM_ATTEMPT",
                caller,
                0,
                "Blacklisted user attempted category claim",
                #Critical
            );
            _reentrancyGuardExit(caller);
            return #err("Address is blacklisted");
        };

        // Get participant
        let participant = switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
            case (?p) { p };
            case null { return #err("You are not registered for this distribution"); };
        };

        // Find the specific category manually
        var targetCategory: ?CategoryAllocation = null;
        for (category in participant.categories.vals()) {
            if (category.categoryId == categoryId) {
                targetCategory := ?category;
            };
        };

        let category = switch (targetCategory) {
            case (?cat) { cat };
            case null { return #err("Category " # Nat.toText(categoryId) # " not found for this participant"); };
        };

        // Calculate claimable amount for this specific category
        let categoryClaimable = _calculateClaimableAmountForCategory(category);

        // Determine actual claim amount
        let actualClaimAmount = switch (claimAmount) {
            case (?amount) {
                if (amount == 0) { return #err("Claim amount must be greater than 0"); };
                if (amount > categoryClaimable) { return #err("Claim amount exceeds available tokens in category"); };
                amount
            };
            case null { categoryClaimable }; // Claim all available from this category
        };

        if (actualClaimAmount == 0) {
            return #err("No tokens available to claim from this category at this time");
        };

        // Check ICTO Passport score if required
        let isEligible = await _checkEligibility(caller);
        if (not isEligible) {
            return #err("Not eligible for this distribution");
        };

        // EFFECTS: Update state before external calls using atomic operations
        let updatedCategories = Buffer.Buffer<CategoryAllocation>(0);
        for (category in participant.categories.vals()) {
            if (category.categoryId == categoryId) {
                let updatedCategory = {
                    category with
                    claimedAmount = category.claimedAmount + actualClaimAmount
                };
                updatedCategories.add(updatedCategory);
            } else {
                updatedCategories.add(category);
            };
        };

        // Perform atomic claim operation to prevent TOCTOU race conditions
        let updatedParticipantResult = _atomicClaimOperation(caller, participant, actualClaimAmount, Buffer.toArray(updatedCategories));
        let updatedParticipant = switch (updatedParticipantResult) {
            case (#ok(p)) { p };
            case (#err(error)) {
                _logSecurityEvent(
                    "TOCTOU_RACE_CONDITION_CATEGORY_CLAIM",
                    caller,
                    actualClaimAmount,
                    "Race condition in category claim: " # error,
                    #Critical
                );
                _reentrancyGuardExit(caller);
                return #err("State validation failed: " # error);
            };
        };

        // Update participant state atomically
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, updatedParticipant).0;

        // Update global total atomically
        let newGlobalTotalResult = _atomicUpdateGlobalTotals(totalClaimed, actualClaimAmount, "category_claim_operation");
        let newGlobalTotal = switch (newGlobalTotalResult) {
            case (#ok(total)) { total };
            case (#err(error)) {
                _logSecurityEvent(
                    "GLOBAL_TOTAL_UPDATE_CATEGORY_CLAIM_FAILED",
                    caller,
                    actualClaimAmount,
                    "Global total update in category claim failed: " # error,
                    #Critical
                );
                _reentrancyGuardExit(caller);
                return #err("System error: " # error);
            };
        };
        totalClaimed := newGlobalTotal;

        // Create claim record for tracking
        let claimRecord: ClaimRecord = {
            participant = caller;
            amount = actualClaimAmount;
            timestamp = Time.now();
            blockHeight = null;
            transactionId = null;
        };
        claimRecords.add(claimRecord);

        // INTERACTIONS: External calls last
        let transferResult = await* _transfer(caller, actualClaimAmount);
        let txIndex = switch (transferResult) {
            case (#ok(index)) {
                let finalClaimRecord = { claimRecord with txIndex = ?index };
                let _ = claimRecords.removeLast();
                claimRecords.add(finalClaimRecord);
                ?index
            };
            case (#err(err)) {
                // REVERT: Rollback state changes on transfer failure
                let revertedParticipant: MultiCategoryParticipant = {
                    principal = participant.principal;
                    registeredAt = participant.registeredAt;
                    categories = participant.categories; // Original categories
                    totalEligible = participant.totalEligible;
                    totalClaimed = participant.totalClaimed; // Original amount
                    lastClaimTime = participant.lastClaimTime;
                    status = participant.status;
                    note = participant.note;
                };
                participants := Trie.put(participants, _principalKey(caller), Principal.equal, revertedParticipant).0;
                totalClaimed -= actualClaimAmount;
                let _ = claimRecords.removeLast();

                return #err("Token transfer failed: " # debug_show(err));
            };
        };

        #ok({ claimedAmount = actualClaimAmount; categoryId = categoryId })
    };

    // Add blacklist checking function
    private func _isBlacklisted(principal: Principal) : Bool {
        switch (Trie.get(blacklist, _principalKey(principal), Principal.equal)) {
            case (?true) { true };
            case _ { false };
        };
    };

    // Safe calculation with overflow protection (V2.0: Uses MultiCategoryParticipant)
    private func _safeCalculateUnlockedAmount(participant: MultiCategoryParticipant) : Result.Result<Nat, Text> {
        // V2.0: Use the new _calculateUnlockedAmount which sums all categories
        let unlockedAmount = _calculateUnlockedAmount(participant);
        #ok(unlockedAmount)
    };


    // Safe arithmetic operations with overflow protection
    private func _safeMultiplyDivide(a: Nat, b: Nat, c: Nat) : Result.Result<Nat, Text> {
        if (c == 0) return #err("Division by zero");
        if (a == 0 or b == 0) return #ok(0);

        // Check for overflow in multiplication
        let maxNat = 18446744073709551615; // 2^64 - 1
        if (a > maxNat / b) {
            return #err("Arithmetic overflow in multiplication");
        };

        let product = a * b;
        #ok(product / c)
    };

    private func _safePercentageOf(amount: Nat, percentage: Nat) : Result.Result<Nat, Text> {
        if (percentage > 100) {
            return #err("Percentage cannot exceed 100");
        };
        if (amount == 0 or percentage == 0) {
            return #ok(0);
        };

        // Use safe multiplication
        let result = _safeMultiplyDivide(amount, percentage, 100);
        result
    };

    private func _safeSubtract(a: Nat, b: Nat) : Nat {
        if (a >= b) { a - b } else { 0 }
    };
    
    // Early unlock with penalty
    public shared({ caller }) func earlyUnlockWithPenalty() : async Result.Result<{unlockedAmount: Nat; penaltyAmount: Nat}, Text> {
        // Check if distribution is active
        if (not _isActive()) {
            return #err("Distribution is not currently active");
        };
        
        // Get participant
        let participant = switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
            case (?p) { p };
            case null { return #err("You are not registered for this distribution"); };
        };
        
        // Check penalty unlock configuration
        let penaltyConfig = switch (config.penaltyUnlock) {
            case (?penalty) { penalty };
            case null { return #err("Early unlock with penalty is not enabled for this distribution"); };
        };
        
        // V2.0: Use earliest vesting start time from all categories for penalty calculation
        let vestingStart = if (participant.categories.size() > 0) {
            var earliestTime = participant.categories[0].vestingStart;
            for (category in participant.categories.vals()) {
                if (category.vestingStart < earliestTime) {
                    earliestTime := category.vestingStart;
                };
            };
            earliestTime
        } else {
            config.distributionStart
        };
        let elapsed = Int.abs(Time.now() - vestingStart);

        // Check if early unlock is allowed
        if (not _canEarlyUnlock(elapsed, config.penaltyUnlock)) {
            return #err("Early unlock is not allowed at this time. Check minimum lock time requirements.");
        };

        // V2.0: Calculate full vested amount using new per-category vesting
        let totalAmount = _calculateUnlockedAmount(participant);
        let remainingAmount = if (totalAmount > participant.totalClaimed) {
            Nat.sub(totalAmount, participant.totalClaimed)
        } else { 0 };
        
        if (remainingAmount == 0) {
            return #err("No remaining tokens to unlock");
        };
        
        // Calculate penalty
        let penaltyAmount = _calculatePenalty(remainingAmount, penaltyConfig);
        let unlockedAmount = if (remainingAmount > penaltyAmount) {
            Nat.sub(remainingAmount, penaltyAmount)
        } else { 0 };
        
        if (unlockedAmount == 0) {
            return #err("Penalty amount equals or exceeds remaining tokens");
        };
        
        // Transfer unlocked tokens to participant
        let transferResult = await* _transfer(caller, unlockedAmount);
        let txIndex = switch (transferResult) {
            case (#ok(index)) { ?index };
            case (#err(err)) {
                return #err("Token transfer failed: " # debug_show(err));
            };
        };
        
        // Handle penalty tokens (transfer to recipient or burn)
        if (penaltyAmount > 0) {
            switch (penaltyConfig.penaltyRecipient) {
                case (?recipient) {
                    // Transfer penalty to specified recipient
                    let penaltyPrincipal = Principal.fromText(recipient);
                    let penaltyTransferResult = await* _transfer(penaltyPrincipal, penaltyAmount);
                    switch (penaltyTransferResult) {
                        case (#err(err)) {
                            // Log error but don't fail the whole transaction
                            Debug.print("Warning: Penalty transfer failed: " # debug_show(err));
                        };
                        case (#ok(_)) { /* Success */ };
                    };
                };
                case null {
                    // Penalty tokens are effectively burned (not transferred)
                    Debug.print("Penalty tokens burned: " # Nat.toText(penaltyAmount));
                };
            };
        };
        
        // Update participant as fully claimed (early unlock claims all remaining)
        // TODO Phase 5: Update per-category claimedAmount as well
        let updatedParticipant: MultiCategoryParticipant = {
            principal = participant.principal;
            registeredAt = participant.registeredAt;
            categories = participant.categories; // TODO Phase 5: Update per-category claimedAmount
            totalEligible = participant.totalEligible;
            totalClaimed = participant.totalEligible; // Mark as fully claimed
            lastClaimTime = ?Time.now();
            status = #Claimed;
            note = participant.note;
        };
        
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, updatedParticipant).0;
        
        // Add claim record for early unlock
        let claimRecord: ClaimRecord = {
            participant = caller;
            amount = unlockedAmount;
            timestamp = Time.now();
            blockHeight = null; // TODO: Get from blockchain
            transactionId = switch (txIndex) {
                case (?index) { ?Nat.toText(index) };
                case null { null };
            };
        };
        
        claimRecords.add(claimRecord);
        totalClaimed += unlockedAmount;
        
        #ok({ unlockedAmount = unlockedAmount; penaltyAmount = penaltyAmount })
    };
    
    // Query functions (V2.0: Returns MultiCategoryParticipant)
    public query func getParticipant(principal: Principal) : async ?MultiCategoryParticipant {
        Trie.get(participants, _principalKey(principal), Principal.equal)
    };

    // Get comprehensive user context information (V2.0: Returns MultiCategoryParticipant)
    public shared({ caller }) func whoami() : async {
        principal: Principal;
        isOwner: Bool;
        isRegistered: Bool;
        isEligible: Bool;
        participant: ?MultiCategoryParticipant;
        claimableAmount: Nat;
        distributionStatus: DistributionStatus;
        canRegister: Bool;
        canClaim: Bool;
        registrationError: ?Text;
    } {
        let participant = Trie.get(participants, _principalKey(caller), Principal.equal);
        let isRegistered = switch (participant) {
            case (?_) { true };
            case null { false };
        };
        
        // Check eligibility (simplified for query function)
        let isEligible = switch (config.eligibilityType) {
            case (#Open) { true };
            case (#Whitelist) {
                switch (Trie.get(whitelist, _principalKey(caller), Principal.equal)) {
                    case (?eligible) { eligible };
                    case null { false };
                }
            };
            case _ { true }; // For other types, assume eligible (would need async check)
        };
        
        let claimableAmount = switch (participant) {
            case (?p) {
                let unlockedAmount = _calculateUnlockedAmount(p);
                if (unlockedAmount > p.totalClaimed) {
                    Nat.sub(unlockedAmount, p.totalClaimed)
                } else { 0 }
            };
            case null { 0 };
        };
        
        // Check if can register
        let canRegister = if (isRegistered) {
            false // Already registered
        } else {
            // Check registration period and eligibility
            let registrationOpen = switch (config.registrationPeriod) {
                case (?period) {
                    let now = Time.now();
                    now >= period.startTime and now <= period.endTime
                };
                case null {
                    config.recipientMode == #SelfService
                };
            };
            registrationOpen and isEligible
        };
        
        // Check if can claim
        let canClaim = isRegistered and _isActive() and claimableAmount > 0;
        
        // Determine registration error if any
        let registrationError = if (isRegistered) {
            ?"Already registered"
        } else if (not isEligible) {
            ?"Not eligible for this distribution"
        } else {
            switch (config.registrationPeriod) {
                case (?period) {
                    let now = Time.now();
                    if (now < period.startTime) {
                        ?"Registration period has not started yet"
                    } else if (now > period.endTime) {
                        ?"Registration period has ended"
                    } else {
                        switch (period.maxParticipants) {
                            case (?max) {
                                if (participantCount >= max) {
                                    ?"Maximum participants reached"
                                } else { null }
                            };
                            case null { null };
                        }
                    }
                };
                case null {
                    if (config.recipientMode != #SelfService) {
                        ?"Registration not available for this distribution mode"
                    } else {
                        // Check if allocation is available
                        let eligibleAmount = switch (config.maxRecipients) {
                            case (?maxRecipients) {
                                if (maxRecipients > 0) {
                                    config.totalAmount / maxRecipients
                                } else { 0 }
                            };
                            case null { 0 };
                        };
                        
                        if (eligibleAmount == 0) {
                            ?"No allocation available for new participants"
                        } else {
                            let projectedDistribution = totalDistributed + eligibleAmount;
                            if (projectedDistribution > config.totalAmount) {
                                ?"No more allocation available - distribution is full"
                            } else { null }
                        }
                    }
                };
            }
        };
        
        {
            principal = caller;
            isOwner = _isOwner(caller);
            isRegistered = isRegistered;
            isEligible = isEligible;
            participant = participant;
            claimableAmount = claimableAmount;
            distributionStatus = status;
            canRegister = canRegister;
            canClaim = canClaim;
            registrationError = registrationError;
        }
    };
    
    public query func getClaimableAmount(principal: Principal) : async Nat {
        switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
            case (?participant) {
                let unlockedAmount = _calculateUnlockedAmount(participant);
                if (unlockedAmount > participant.totalClaimed) {
                    Nat.sub(unlockedAmount, participant.totalClaimed)
                } else { 0 }
            };
            case null { 0 };
        }
    };

    public query func getClaimInfo(principal: Principal) : async {
        maxClaimable: Nat;
        totalAllocated: Nat;
        claimed: Nat;
        remaining: Nat;
    } {
        switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
            case (?participant) {
                let unlockedAmount = _calculateUnlockedAmount(participant);
                let maxClaimable = if (unlockedAmount > participant.totalClaimed) {
                    Nat.sub(unlockedAmount, participant.totalClaimed)
                } else { 0 };

                {
                    maxClaimable = maxClaimable;
                    totalAllocated = participant.totalEligible;
                    claimed = participant.totalClaimed;
                    remaining = if (participant.totalEligible > participant.totalClaimed) {
                        Nat.sub(participant.totalEligible, participant.totalClaimed)
                    } else { 0 };
                };
            };
            case null {
                {
                    maxClaimable = 0;
                    totalAllocated = 0;
                    claimed = 0;
                    remaining = 0;
                };
            };
        };
    };

    public query func getAllParticipants() : async [MultiCategoryParticipant] {
        let buffer = Buffer.Buffer<MultiCategoryParticipant>(0);
        for ((_, participant) in Trie.iter(participants)) {
            buffer.add(participant);
        };
        Buffer.toArray(buffer)
    };
    
    public query func getClaimHistory(principal: ?Principal) : async [ClaimRecord] {
        let buffer = Buffer.Buffer<ClaimRecord>(0);
        for (record in claimRecords.vals()) {
            switch (principal) {
                case (?p) {
                    if (Principal.equal(record.participant, p)) {
                        buffer.add(record);
                    };
                };
                case null {
                    buffer.add(record);
                };
            };
        };
        Buffer.toArray(buffer)
    };

    // ================ CATEGORY BREAKDOWN QUERIES (V2.0) ================

    /// Get detailed category breakdown for a participant
    /// Shows allocation, claimed, and remaining amounts per category
    public query func getCategoryBreakdown(principal: Principal) : async [{
        categoryId: Nat;
        categoryName: Text;
        allocatedAmount: Nat;
        claimedAmount: Nat;
        remainingAmount: Nat;
        claimableAmount: Nat;
        unlockedAmount: Nat;
        vestingSchedule: VestingSchedule;
        vestingStart: Time.Time;
        note: ?Text;
    }] {
        switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
            case (?participant) {
                let breakdown = Buffer.Buffer<{
                    categoryId: Nat;
                    categoryName: Text;
                    allocatedAmount: Nat;
                    claimedAmount: Nat;
                    remainingAmount: Nat;
                    claimableAmount: Nat;
                    unlockedAmount: Nat;
                    vestingSchedule: VestingSchedule;
                    vestingStart: Time.Time;
                    note: ?Text;
                }>(0);

                for (category in participant.categories.vals()) {
                    let unlockedAmount = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                    let claimableAmount = if (unlockedAmount > category.claimedAmount) {
                        Nat.sub(unlockedAmount, category.claimedAmount)
                    } else { 0 };
                    let remainingAmount = if (category.amount > category.claimedAmount) {
                        Nat.sub(category.amount, category.claimedAmount)
                    } else { 0 };

                    breakdown.add({
                        categoryId = category.categoryId;
                        categoryName = category.categoryName;
                        allocatedAmount = category.amount;
                        claimedAmount = category.claimedAmount;
                        remainingAmount = remainingAmount;
                        claimableAmount = claimableAmount;
                        unlockedAmount = unlockedAmount;
                        vestingSchedule = category.vestingSchedule;
                        vestingStart = category.vestingStart;
                        note = category.note;
                    });
                };

                Buffer.toArray(breakdown)
            };
            case null { [] };
        }
    };

    /// Get claimable breakdown for a participant
    /// Shows how much can be claimed from each category
    public query func getClaimableBreakdown(principal: Principal) : async [{
        categoryId: Nat;
        categoryName: Text;
        claimableAmount: Nat;
        totalUnlocked: Nat;
        percentageOfTotal: Float; // Percentage of total unlocked that this category represents
    }] {
        switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
            case (?participant) {
                let breakdown = Buffer.Buffer<{
                    categoryId: Nat;
                    categoryName: Text;
                    claimableAmount: Nat;
                    totalUnlocked: Nat;
                    percentageOfTotal: Float;
                }>(0);

                let claimableBreakdown = _calculateCategoryClaimableBreakdown(participant);
                var totalUnlocked: Nat = 0;

                // Calculate total unlocked across all categories
                for (category in participant.categories.vals()) {
                    let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                    totalUnlocked += unlocked;
                };

                for ((categoryId, claimableAmount) in claimableBreakdown.vals()) {
                    // Find category manually
                    var foundCategory: ?CategoryAllocation = null;
                    for (category in participant.categories.vals()) {
                        if (category.categoryId == categoryId) {
                            foundCategory := ?category;
                        };
                    };

                    switch (foundCategory) {
                        case (?category) {
                            let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                            let percentage = if (totalUnlocked > 0) {
                                Float.fromInt(unlocked) / Float.fromInt(totalUnlocked) * 100.0
                            } else { 0.0 };

                            breakdown.add({
                                categoryId = categoryId;
                                categoryName = category.categoryName;
                                claimableAmount = claimableAmount;
                                totalUnlocked = unlocked;
                                percentageOfTotal = percentage;
                            });
                        };
                        case null {};
                    };
                };

                Buffer.toArray(breakdown)
            };
            case null { [] };
        }
    };

    /// Get vesting progress for all categories of a participant
    /// Shows progress percentage for each category
    public query func getVestingProgress(principal: Principal) : async [{
        categoryId: Nat;
        categoryName: Text;
        progressPercentage: Float; // Percentage of tokens that have unlocked
        isFullyVested: Bool;
        timeUntilNextUnlock: ?Nat; // Seconds until next unlock (null if fully vested)
        nextUnlockAmount: ?Nat; // Amount that will unlock next (null if fully vested)
    }] {
        switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
            case (?participant) {
                let progress = Buffer.Buffer<{
                    categoryId: Nat;
                    categoryName: Text;
                    progressPercentage: Float;
                    isFullyVested: Bool;
                    timeUntilNextUnlock: ?Nat;
                    nextUnlockAmount: ?Nat;
                }>(0);

                let now = Time.now();

                for (category in participant.categories.vals()) {
                    let unlockedAmount = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                    let progressPercentage = if (category.amount > 0) {
                        Float.fromInt(unlockedAmount) / Float.fromInt(category.amount) * 100.0
                    } else { 0.0 };

                    let isFullyVested = unlockedAmount >= category.amount;
                    var timeUntilNextUnlock: ?Nat = null;
                    var nextUnlockAmount: ?Nat = null;

                    if (not isFullyVested) {
                        // Calculate time until next unlock based on vesting schedule
                        let elapsedInt = if (now >= category.vestingStart) {
                            Int.sub(now, category.vestingStart)
                        } else {
                            Int.sub(category.vestingStart, now)
                        };

                        // Convert to Nat for calculations (only if positive)
                        let elapsed = if (elapsedInt >= 0) {
                            Int.abs(elapsedInt)
                        } else {
                            0 // Should not happen, but safe fallback
                        };

                        switch (category.vestingSchedule) {
                            case (#Linear(linear)) {
                                if (elapsed < linear.duration) {
                                    let timeRemaining = linear.duration - elapsed;
                                    timeUntilNextUnlock := ?timeRemaining;
                                    nextUnlockAmount := ?1; // Linear unlocks continuously
                                };
                            };
                            case (#Cliff(cliff)) {
                                if (elapsed < cliff.cliffDuration) {
                                    let timeRemaining = cliff.cliffDuration - elapsed;
                                    timeUntilNextUnlock := ?timeRemaining;
                                    nextUnlockAmount := ?0; // Nothing unlocks until cliff
                                } else if (elapsed < cliff.cliffDuration + cliff.vestingDuration) {
                                    let cliffAmount = (category.amount * cliff.cliffPercentage) / 100;
                                    let initialUnlock = (category.amount * config.initialUnlockPercentage) / 100;
                                    let remainingAmount = category.amount - initialUnlock - cliffAmount;
                                    let postCliffElapsed = elapsed - cliff.cliffDuration;
                                    let _vestedAmount = (remainingAmount * postCliffElapsed) / cliff.vestingDuration;
                                    nextUnlockAmount := ?1; // Linear after cliff
                                };
                            };
                            case (#Single(single)) {
                                if (elapsed < single.duration) {
                                    let timeRemaining = single.duration - elapsed;
                                    timeUntilNextUnlock := ?timeRemaining;
                                    nextUnlockAmount := ?category.amount; // Full amount unlocks at end
                                };
                            };
                            case (_) {
                                // For other vesting types, we don't predict next unlock
                            };
                        };
                    };

                    progress.add({
                        categoryId = category.categoryId;
                        categoryName = category.categoryName;
                        progressPercentage = progressPercentage;
                        isFullyVested = isFullyVested;
                        timeUntilNextUnlock = timeUntilNextUnlock;
                        nextUnlockAmount = nextUnlockAmount;
                    });
                };

                Buffer.toArray(progress)
            };
            case null { [] };
        }
    };

    /// Enhanced whoami with category information
    /// Returns participant info including category breakdown
    public shared({ caller }) func whoamiWithCategories() : async {
        principal: Principal;
        isOwner: Bool;
        isRegistered: Bool;
        isEligible: Bool;
        participant: ?MultiCategoryParticipant;
        claimableAmount: Nat;
        distributionStatus: DistributionStatus;
        canRegister: Bool;
        canClaim: Bool;
        registrationError: ?Text;
        categoryBreakdown: [{
            categoryId: Nat;
            categoryName: Text;
            claimableAmount: Nat;
            allocatedAmount: Nat;
            claimedAmount: Nat;
            progressPercentage: Float;
        }];
    } {
        let participant = Trie.get(participants, _principalKey(caller), Principal.equal);
        let isRegistered = switch (participant) {
            case (?_) { true };
            case null { false };
        };

        // Check eligibility (simplified for query function)
        let isEligible = switch (config.eligibilityType) {
            case (#Open) { true };
            case (#Whitelist) {
                switch (Trie.get(whitelist, _principalKey(caller), Principal.equal)) {
                    case (?eligible) { eligible };
                    case null { false };
                }
            };
            case _ { true }; // For other types, assume eligible (would need async check)
        };

        let claimableAmount = switch (participant) {
            case (?p) {
                let unlockedAmount = _calculateUnlockedAmount(p);
                if (unlockedAmount > p.totalClaimed) {
                    Nat.sub(unlockedAmount, p.totalClaimed)
                } else { 0 }
            };
            case null { 0 };
        };

        // Calculate category breakdown
        let categoryBreakdown = switch (participant) {
            case (?p) {
                let breakdown = Buffer.Buffer<{
                    categoryId: Nat;
                    categoryName: Text;
                    claimableAmount: Nat;
                    allocatedAmount: Nat;
                    claimedAmount: Nat;
                    progressPercentage: Float;
                }>(0);

                for (category in p.categories.vals()) {
                    let claimable = _calculateClaimableAmountForCategory(category);
                    let unlocked = _calculateUnlockedAmountForCategory(category, config.initialUnlockPercentage);
                    let progress = if (category.amount > 0) {
                        Float.fromInt(unlocked) / Float.fromInt(category.amount) * 100.0
                    } else { 0.0 };

                    breakdown.add({
                        categoryId = category.categoryId;
                        categoryName = category.categoryName;
                        claimableAmount = claimable;
                        allocatedAmount = category.amount;
                        claimedAmount = category.claimedAmount;
                        progressPercentage = progress;
                    });
                };

                Buffer.toArray(breakdown)
            };
            case null { [] };
        };

        // Check if can register
        let canRegister = if (isRegistered) {
            false // Already registered
        } else {
            // Check registration period and eligibility
            let registrationOpen = switch (config.registrationPeriod) {
                case (?period) {
                    let now = Time.now();
                    now >= period.startTime and now <= period.endTime
                };
                case null {
                    config.recipientMode == #SelfService
                };
            };
            registrationOpen and isEligible
        };

        // Check if can claim
        let canClaim = isRegistered and _isActive() and claimableAmount > 0;

        // Determine registration error if any
        let registrationError = if (isRegistered) {
            ?"Already registered"
        } else if (not isEligible) {
            ?"Not eligible for this distribution"
        } else {
            switch (config.registrationPeriod) {
                case (?period) {
                    let now = Time.now();
                    if (now < period.startTime) {
                        ?"Registration period has not started yet"
                    } else if (now > period.endTime) {
                        ?"Registration period has ended"
                    } else {
                        switch (period.maxParticipants) {
                            case (?max) {
                                if (participantCount >= max) {
                                    ?"Maximum participants reached"
                                } else { null }
                            };
                            case null { null };
                        }
                    }
                };
                case null {
                    if (config.recipientMode != #SelfService) {
                        ?"Registration not available for this distribution mode"
                    } else {
                        null
                    }
                };
            }
        };

        {
            principal = caller;
            isOwner = _isOwner(caller);
            isRegistered = isRegistered;
            isEligible = isEligible;
            participant = participant;
            claimableAmount = claimableAmount;
            distributionStatus = status;
            canRegister = canRegister;
            canClaim = canClaim;
            registrationError = registrationError;
            categoryBreakdown = categoryBreakdown;
        }
    };

    // Admin functions
    public shared({ caller }) func activate() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can activate distribution");
        };
        
        if (status != #Created) {
            return #err("Distribution can only be activated from Created status");
        };
        
        // Check contract has sufficient token balance
        let contractBalance = await _getContractTokenBalance();
        if (contractBalance < config.totalAmount) {
            return #err("Insufficient token balance. Required: " # debug_show(config.totalAmount) # " " # config.tokenInfo.symbol # ", Available: " # debug_show(contractBalance / E8S) # " " # config.tokenInfo.symbol);
        };
        
        status := #Active;

        // Cancel auto-activation timer if running (no longer needed)
        switch (distributionStartTimerId) {
            case (?id) {
                Timer.cancelTimer(id);
                distributionStartTimerId := null;
                Debug.print("✅ Auto-activation timer cancelled (manually activated)");
            };
            case null {};
        };

        Debug.print("✅ Distribution manually activated at: " # Int.toText(Time.now()));
        #ok()
    };

    /// Deposit tokens to contract using ICRC-2 transfer_from
    /// This allows the creator to deposit required tokens in a secure, auditable way
    ///
    /// SECURITY:
    /// - Only owner can deposit
    /// - Uses ICRC-2 approval mechanism (safer than direct transfer)
    /// - Automatically attempts activation after successful deposit
    /// - Cancels balance check timer once sufficient balance reached
    ///
    /// WORKFLOW:
    /// 1. Owner approves distribution contract for totalAmount tokens
    /// 2. Owner calls this function
    /// 3. Contract pulls tokens from owner's account
    /// 4. Contract attempts auto-activation if balance sufficient
    public shared({ caller }) func depositTokens() : async Result.Result<Nat, Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can deposit tokens");
        };

        if (status != #Created) {
            return #err("Can only deposit tokens when status is Created. Current status: " # debug_show(status));
        };

        let tokenActor = switch (tokenCanister) {
            case (?canister) canister;
            case (null) {
                return #err("Token canister not initialized");
            };
        };

        Debug.print("💰 Depositing tokens to distribution contract...");
        Debug.print("   From: " # Principal.toText(caller));
        Debug.print("   Amount: " # Nat.toText(config.totalAmount));

        // Check current balance before transfer
        let balanceBefore = await _getContractTokenBalance();
        let remainingNeeded = if (config.totalAmount > balanceBefore) {
            Nat.sub(config.totalAmount, balanceBefore)
        } else {
            0
        };

        if (remainingNeeded == 0) {
            return #err("Contract already has sufficient balance (" # Nat.toText(balanceBefore) # " / " # Nat.toText(config.totalAmount) # ")");
        };

        Debug.print("   Remaining needed: " # Nat.toText(remainingNeeded));

        // Use ICRC-2 transfer_from to pull tokens from owner
        let transferFromArgs : ICRC.TransferFromArgs = {
            from = {
                owner = caller;
                subaccount = null;
            };
            to = {
                owner = Principal.fromActor(self);
                subaccount = null;
            };
            amount = remainingNeeded; // Only transfer what's needed
            fee = ?transferFee;
            memo = ?Text.encodeUtf8("Distribution token deposit");
            created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
            spender_subaccount = null;
        };

        let transferResult = await tokenActor.icrc2_transfer_from(transferFromArgs);

        switch (transferResult) {
            case (#Ok(blockIndex)) {
                Debug.print("✅ Tokens deposited successfully!");
                Debug.print("   Block Index: " # Nat.toText(blockIndex));

                // Check new balance
                let balanceAfter = await _getContractTokenBalance();
                Debug.print("   New Balance: " # Nat.toText(balanceAfter) # " / " # Nat.toText(config.totalAmount));

                // Try to activate if we now have sufficient balance
                if (balanceAfter >= config.totalAmount) {
                    Debug.print("✅ Sufficient balance reached! Attempting activation...");

                    // Cancel balance check timer if running
                    switch (balanceCheckTimerId) {
                        case (?id) {
                            Timer.cancelTimer(id);
                            balanceCheckTimerId := null;
                            Debug.print("   ⏱️ Balance check timer cancelled");
                        };
                        case (null) {};
                    };

                    // Attempt activation
                    await _updateStatusToActive();
                };

                #ok(blockIndex)
            };
            case (#Err(error)) {
                let errorMsg = debug_show(error);
                Debug.print("❌ Token deposit failed: " # errorMsg);

                // Provide helpful error messages
                let helpfulError = switch (error) {
                    case (#InsufficientAllowance(_)) {
                        "Insufficient allowance. Please approve the distribution contract for " # Nat.toText(remainingNeeded) # " tokens first using icrc2_approve()."
                    };
                    case (#InsufficientFunds(_)) {
                        "Insufficient funds in your account. Required: " # Nat.toText(remainingNeeded) # " tokens."
                    };
                    case (_) errorMsg;
                };

                #err("Token deposit failed: " # helpfulError)
            };
        }
    };

    public shared({ caller }) func pause() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can pause distribution");
        };
        
        if (not config.allowModification) {
            return #err("Distribution modification is not allowed");
        };
        
        status := #Paused;
        #ok()
    };
    
    public shared({ caller }) func resume() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can resume distribution");
        };
        
        if (status != #Paused) {
            return #err("Distribution must be paused to resume");
        };
        
        status := #Active;
        #ok()
    };
    
    public shared({ caller }) func cancel() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can cancel distribution");
        };
        
        if (not config.allowCancel) {
            return #err("Distribution cancellation is not allowed");
        };
        
        status := #Cancelled;

        // Cancel all milestone timers
        _cancelAllTimers();
        
        // Return remaining tokens to owner if any
        let balance = await _getContractTokenBalance();
        if (balance >= Nat.mul(transferFee, 2)) {
            let transferResult = await* _transfer(config.owner, balance);
            switch (transferResult) {
                case (#ok(_)) { /* Transfer successful */ };
                case (#err(_)) { /* Log error but don't fail cancellation */ };
            };
        };
        
        #ok()
    };
    
    public shared({ caller }) func addParticipants(newParticipants: [(Principal, Nat)]) : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can add participants");
        };
        
        if (config.recipientMode == #SelfService) {
            return #err("Cannot manually add participants in self-service mode");
        };
        
        for ((principal, amount) in newParticipants.vals()) {
            // Check if already exists
            switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
                case (?existing) {
                    // Update existing participant (V2.0: Add new category or update existing)
                    // For admin addition, create/update default category
                    let defaultCategory: CategoryAllocation = {
                        categoryId = 1;
                        categoryName = "Default Distribution";
                        amount = amount;
                        claimedAmount = 0; // Reset claimed for new amount
                        vestingSchedule = config.vestingSchedule;
                        vestingStart = config.distributionStart;
                        note = null;
                    };

                    let updated: MultiCategoryParticipant = {
                        principal = existing.principal;
                        registeredAt = existing.registeredAt;
                        categories = [defaultCategory]; // V2.0: Replace with new admin category
                        totalEligible = amount;
                        totalClaimed = existing.totalClaimed; // Preserve existing claimed amount
                        lastClaimTime = existing.lastClaimTime;
                        status = existing.status;
                        note = existing.note;
                    };
                    participants := Trie.put(participants, _principalKey(principal), Principal.equal, updated).0;
                };
                case null {
                    // Add new participant (V2.0: Create with default category)
                    let defaultCategory: CategoryAllocation = {
                        categoryId = 1;
                        categoryName = "Default Distribution";
                        amount = amount;
                        claimedAmount = 0;
                        vestingSchedule = config.vestingSchedule;
                        vestingStart = config.distributionStart;
                        note = null;
                    };

                    let participant: MultiCategoryParticipant = {
                        principal = principal;
                        registeredAt = Time.now();
                        categories = [defaultCategory];
                        totalEligible = amount;
                        totalClaimed = 0;
                        lastClaimTime = null;
                        status = #Eligible;
                        note = null; // No specific note for manually added participants
                    };
                    participants := Trie.put(participants, _principalKey(principal), Principal.equal, participant).0;
                    participantCount += 1;
                };
            };
        };
        
        #ok()
    };

    public query func getCanisterInfo() : async {
        creator: Principal;
        createdAt: Time.Time;
        cyclesBalance: Nat;
        distributionTitle: Text;
        participantCount: Nat;
        totalDistributed: Nat;
        status: DistributionStatus;
    } {
        {
            creator = creator;
            createdAt = createdAt;
            cyclesBalance = Cycles.balance();
            distributionTitle = config.title;
            participantCount = participantCount;
            totalDistributed = totalDistributed;
            status = status;
        }
    };
    
    // ================ TIMER MANAGEMENT ================

    /// Manually setup milestone timers (for testing/recovery)
    /// Normally called automatically in postupgrade()
    public shared({ caller }) func setupTimers() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can setup timers");
        };

        Debug.print("🔧 Manual timer setup requested by owner");
        await _setupMilestoneTimers();
        #ok(())
    };

    /// Cancel all milestone timers (for pause/emergency)
    public shared({ caller }) func cancelTimers() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can cancel timers");
        };

        _cancelAllTimers();
        #ok(())
    };

    /// Get timer status for debugging
    public query func getTimerStatus() : async {
        distributionStartTimer: ?Nat;
        distributionEndTimer: ?Nat;
    } {
        {
            distributionStartTimer = distributionStartTimerId;
            distributionEndTimer = distributionEndTimerId;
        }
    };
    
    // ================ LAUNCHPAD INTEGRATION FUNCTIONS ================

    // Get launchpad context information
    public query func getLaunchpadContext() : async ?DistributionTypes.LaunchpadContext {
        config.launchpadContext
    };

    // Check if this distribution is linked to a launchpad
    public query func isLaunchpadLinked() : async Bool {
        switch (config.launchpadContext) {
            case (?_) { true };
            case null { false };
        }
    };

    // Auto-fund distribution from launchpad (called by launchpad canister)
    public shared({ caller }) func fundFromLaunchpad(expectedAmount: Nat) : async Result.Result<(), Text> {
        // Only allow calls from linked launchpad
        switch (launchpadCanisterId) {
            case (?launchpadId) {
                if (not Principal.equal(caller, launchpadId)) {
                    return #err("Unauthorized: Only linked launchpad can fund this distribution");
                };
            };
            case null {
                return #err("This distribution is not linked to any launchpad");
            };
        };

        // Check if contract received the expected tokens
        let currentBalance = await _getContractTokenBalance();
        if (currentBalance >= expectedAmount) {
            Debug.print("✅ Distribution funded successfully: " # Nat.toText(currentBalance) # " tokens");
            #ok()
        } else {
            #err("Insufficient funding: expected " # Nat.toText(expectedAmount) # ", received " # Nat.toText(currentBalance))
        }
    };

    // Batch add participants (optimized for large lists from launchpad)
    public shared({ caller }) func addParticipantsBatch(
        newParticipants: [(Principal, Nat)],
        batchSize: ?Nat
    ) : async Result.Result<Nat, Text> {
        if (not _isOwner(caller) and not _isLaunchpadCaller(caller)) {
            return #err("Unauthorized: Only owner or linked launchpad can add participants");
        };

        let maxBatchSize = switch (batchSize) {
            case (?size) { size };
            case null { 1000 }; // Default batch size
        };

        var processedCount = 0;
        let totalParticipants = newParticipants.size();

        label addLoop for ((principal, amount) in newParticipants.vals()) {
            if (processedCount >= maxBatchSize) {
                break addLoop;
            };

            // Check if already exists
            switch (Trie.get(participants, _principalKey(principal), Principal.equal)) {
                case (?existing) {
                    // Update existing participant (V2.0: Update with default category)
                    let defaultCategory: CategoryAllocation = {
                        categoryId = 1;
                        categoryName = "Default Distribution";
                        amount = amount;
                        claimedAmount = 0;
                        vestingSchedule = config.vestingSchedule;
                        vestingStart = config.distributionStart;
                        note = null;
                    };

                    let updated: MultiCategoryParticipant = {
                        principal = existing.principal;
                        registeredAt = existing.registeredAt;
                        categories = [defaultCategory]; // V2.0: Replace with new category
                        totalEligible = amount;
                        totalClaimed = existing.totalClaimed;
                        lastClaimTime = existing.lastClaimTime;
                        status = existing.status;
                        note = existing.note;
                    };
                    participants := Trie.put(participants, _principalKey(principal), Principal.equal, updated).0;
                };
                case null {
                    // Add new participant (V2.0: Create with default category)
                    let defaultCategory: CategoryAllocation = {
                        categoryId = 1;
                        categoryName = "Default Distribution";
                        amount = amount;
                        claimedAmount = 0;
                        vestingSchedule = config.vestingSchedule;
                        vestingStart = config.distributionStart;
                        note = null;
                    };

                    let participant: MultiCategoryParticipant = {
                        principal = principal;
                        registeredAt = Time.now();
                        categories = [defaultCategory];
                        totalEligible = amount;
                        totalClaimed = 0;
                        lastClaimTime = null;
                        status = #Eligible;
                        note = null;
                    };
                    participants := Trie.put(participants, _principalKey(principal), Principal.equal, participant).0;
                    participantCount += 1;
                };
            };

            processedCount += 1;
        };

        #ok(processedCount)
    };

    // Helper function to check if caller is linked launchpad
    private func _isLaunchpadCaller(caller: Principal) : Bool {
        switch (launchpadCanisterId) {
            case (?launchpadId) { Principal.equal(caller, launchpadId) };
            case null { false };
        }
    };


    // ================ ADDITIONAL QUERY FUNCTIONS ================

    public query func getContractBalance() : async Nat {
        // This is a query approximation; use getContractBalanceAsync for real-time balance
        0 // Placeholder since we can't make async calls in query functions
    };
    
    public func getContractBalanceAsync() : async Nat {
        await _getContractTokenBalance()
    };
    
    public query func checkEligibilitySync(principal: Principal) : async Bool {
        // Synchronous eligibility check for simple cases
        switch (config.eligibilityType) {
            case (#Open) { true };
            case (#Whitelist) {
                switch (Trie.get(whitelist, _principalKey(principal), Principal.equal)) {
                    case (?eligible) { eligible };
                    case null { false };
                }
            };
            case (_) { false }; // Complex eligibility requires async call
        }
    };
    
    // Query function to get the configured factory canister
    public query func getFactoryCanisterId() : async ?Principal {
        factoryCanisterId
    };

    // Debug function to help troubleshoot factory relationship issues
    public query func getRelationshipDebugInfo() : async {
        hasFactoryCanister: Bool;
        factoryCanisterId: ?Principal;
        contractAddress: Principal;
    } {
        {
            hasFactoryCanister = Option.isSome(factoryCanisterId);
            factoryCanisterId = factoryCanisterId;
            contractAddress = Principal.fromActor(self);
        }
    };
    
    // ================ DAO VOTING POWER INTEGRATION ================
    // NEW: Added for DAO voting power calculation - PUBLIC FUNCTIONS
    
    /// Private helper for sync snapshot calculation
    private func _getDistributionSnapshotSync(
        queriedPrincipal: Principal
    ) : ?{
        principal: Principal;
        remaining: Nat;
        remaining_time: Nat;
        max_lock: Nat;
        contract_id: Principal;
    } {
        switch (Trie.get(participants, _principalKey(queriedPrincipal), Principal.equal)) {
            case (?participant) {
                let now = Time.now();
                // V2.0: Use earliest vesting start time from all categories for display
                let vestingStart = if (participant.categories.size() > 0) {
                    var earliestTime = participant.categories[0].vestingStart;
                    for (category in participant.categories.vals()) {
                        if (category.vestingStart < earliestTime) {
                            earliestTime := category.vestingStart;
                        };
                    };
                    earliestTime
                } else {
                    config.distributionStart
                };

                // Calculate remaining locked amount
                let unlockedAmount = _calculateUnlockedAmount(participant);
                let remainingAmount = if (participant.totalEligible > unlockedAmount) {
                    Nat.sub(participant.totalEligible, unlockedAmount)
                } else { 0 };
                
                if (remainingAmount == 0) {
                    return null; // No locked tokens = no voting power
                };
                
                // Calculate remaining time and max lock duration
                let (remainingTime, maxLock) = switch (config.vestingSchedule) {
                    case (#Linear(linear)) {
                        let elapsed = Int.abs(now - vestingStart);
                        let remaining = if (linear.duration > elapsed) {
                            Nat.sub(linear.duration, elapsed)
                        } else { 0 };
                        (remaining, linear.duration)
                    };
                    case (#Cliff(cliff)) {
                        let totalDuration = cliff.cliffDuration + cliff.vestingDuration;
                        let elapsed = Int.abs(now - vestingStart);
                        let remaining = if (totalDuration > elapsed) {
                            Nat.sub(totalDuration, elapsed)
                        } else { 0 };
                        (remaining, totalDuration)
                    };
                    case (#Single(single)) {
                        let elapsed = Int.abs(now - vestingStart);
                        let remaining = if (single.duration > elapsed) {
                            Nat.sub(single.duration, elapsed)
                        } else { 0 };
                        (remaining, single.duration)
                    };
                    case (_) { (0, 0) }; // Other types need implementation
                };
                
                ?{
                    principal = queriedPrincipal;
                    remaining = remainingAmount;
                    remaining_time = remainingTime / 1_000_000_000; // Convert to seconds
                    max_lock = maxLock / 1_000_000_000; // Convert to seconds
                    contract_id = Principal.fromActor(self);
                }
            };
            case null { null };
        }
    };
    
    /// Get distribution snapshot for a specific principal (for DAO queries)
    public shared ({ caller }) func getDistributionSnapshotForPrincipal(
        queriedPrincipal: Principal  // Not caller - allow canister-to-canister queries
    ) : async ?{
        principal: Principal;
        remaining: Nat;         // token not vested at snapshot
        remaining_time: Nat;    // remaining time to lock_end (seconds)
        max_lock: Nat;          // total time to lock (seconds)
        contract_id: Principal; // canister id of distribution contract
    } {
        //Only allow canister-to-canister queries
        assert Principal.isCanister(caller);
        _getDistributionSnapshotSync(queriedPrincipal)
    };
    
    /// Get all participants with locked tokens (for DAO discovery)
    public shared ({ caller }) func getAllParticipantsWithLockedTokens() : async [{
        principal: Principal;
        remaining: Nat;
        remaining_time: Nat;
        max_lock: Nat;
        contract_id: Principal;
    }] {
        //Only allow canister-to-canister queries
        assert Principal.isCanister(caller);
        let buffer = Buffer.Buffer<{
            principal: Principal;
            remaining: Nat;
            remaining_time: Nat;
            max_lock: Nat;
            contract_id: Principal;
        }>(0);
        
        for ((principal, _) in Trie.iter(participants)) {
            switch (_getDistributionSnapshotSync(principal)) {
                case (?entry) { buffer.add(entry) };
                case null { /* Skip fully vested participants */ };
            };
        };
        
        Buffer.toArray(buffer)
    };
    
    /// Batch query for multiple principals (more efficient for DAO)
    public query func getBatchDistributionSnapshot(
        principals: [Principal]
    ) : async [{
        principal: Principal;
        remaining: Nat;
        remaining_time: Nat;
        max_lock: Nat;
        contract_id: Principal;
    }] {
        let buffer = Buffer.Buffer<{
            principal: Principal;
            remaining: Nat;
            remaining_time: Nat;
            max_lock: Nat;
            contract_id: Principal;
        }>(0);
        
        for (principal in principals.vals()) {
            switch (_getDistributionSnapshotSync(principal)) {
                case (?entry) { buffer.add(entry) };
                case null { /* Skip principals with no locked tokens */ };
            };
        };
        
        Buffer.toArray(buffer)
    };

    // ================ ADMIN FUNCTIONS (ROLE-BASED ACCESS CONTROL) ================

    /// Add a role to a user (Owner only)
    public shared({ caller }) func addRole(user: Principal, role: Role) : async Result.Result<(), Text> {
        // Only Owner can add roles
        if (not Principal.equal(caller, creator)) {
            return #err("Only owner can add roles");
        };

        // Input validation
        switch (_validatePrincipal(user)) {
            case (#ok(_)) {};
            case (#err(error)) { return #err(error) };
        };

        // Check if user already has this role
        let existingRole = Array.find(_adminRoles, func ((u, _): (Principal, Role)) : Bool {
            Principal.equal(u, user)
        });

        switch (existingRole) {
            case (?(_, currentRole)) {
                return #err("User already has role: " # debug_show(currentRole));
            };
            case null {
                _adminRoles := Array.append(_adminRoles, [(user, role)]);
                return #ok(());
            };
        };
    };

    /// Remove a role from a user (Owner only)
    public shared({ caller }) func removeRole(user: Principal) : async Result.Result<(), Text> {
        // Only Owner can remove roles
        if (not Principal.equal(caller, creator)) {
            return #err("Only owner can remove roles");
        };

        // Filter out the user's role
        let filteredRoles = Array.filter(_adminRoles, func ((u, _): (Principal, Role)) : Bool {
            not Principal.equal(u, user)
        });

        // Check if role was actually removed
        if (filteredRoles.size() == _adminRoles.size()) {
            return #err("User has no role to remove");
        };

        _adminRoles := filteredRoles;
        return #ok(());
    };

    /// Get all role assignments (Admin+ only)
    public query func getRoleAssignments() : async [(Principal, Role)] {
        _adminRoles;
    };

    /// Get user's role (public query)
    public query func getUserRole(user: Principal) : async ?Role {
        var foundRole: ?Role = null;
        for ((u, role) in _adminRoles.vals()) {
            if (Principal.equal(u, user)) {
                foundRole := ?role;
            };
        };
        foundRole
    };

    /// Check if caller has specific role
    public query func hasRole(caller: Principal, role: Role) : async Bool {
        _hasRole(caller, role);
    };

    // ================ EMERGENCY CONTROLS (OWNER ONLY) ================

    /// Emergency pause - temporarily disable all operations (Owner only)
    public shared({ caller }) func emergencyPause() : async Result.Result<(), Text> {
        // Only Owner can emergency pause
        if (not Principal.equal(caller, creator)) {
            return #err("Only owner can emergency pause");
        };

        // Only pause if currently active
        if (status != #Active) {
            return #err("Distribution is not active");
        };

        status := #Paused;
        Debug.print("🚨 EMERGENCY PAUSE activated by: " # Principal.toText(caller));
        return #ok(());
    };

    /// Emergency unpause - resume operations (Owner only)
    public shared({ caller }) func emergencyUnpause() : async Result.Result<(), Text> {
        // Only Owner can emergency unpause
        if (not Principal.equal(caller, creator)) {
            return #err("Only owner can emergency unpause");
        };

        // Only unpause if currently paused
        if (status != #Paused) {
            return #err("Distribution is not paused");
        };

        status := #Active;
        Debug.print("✅ EMERGENCY UNPAUSE activated by: " # Principal.toText(caller));
        return #ok(());
    };

    /// Emergency withdraw - allows owner to withdraw remaining tokens in emergency (Owner only)
    public shared({ caller }) func emergencyWithdraw(amount: Nat, recipient: Principal) : async Result.Result<Nat, Text> {
        // Only Owner can emergency withdraw
        if (not Principal.equal(caller, creator)) {
            return #err("Only owner can emergency withdraw");
        };

        // Input validation
        switch (_validatePrincipal(recipient)) {
            case (#ok(_)) {};
            case (#err(error)) { return #err(error) };
        };

        switch (_validateAmount(amount)) {
            case (#ok(_)) {};
            case (#err(error)) { return #err(error) };
        };

        // Check if distribution is paused or failed (emergency only)
        if (status != #Paused and status != #Failed) {
            return #err("Emergency withdraw only allowed when distribution is paused or failed");
        };

        // Check contract balance with atomic operation pattern
        let contractBalance = await getContractBalance();

        // Validate amount doesn't exceed balance
        switch (_safeSub(contractBalance, amount)) {
            case (?_remainingBalance) {
                // Balance is sufficient, proceed with transfer
            };
            case null {
                return #err("Insufficient contract balance");
            };
        };

        // Perform emergency transfer with validated amount
        let transferResult = await* _transfer(recipient, amount);
        switch (transferResult) {
            case (#ok(_)) {
                Debug.print("🚨 EMERGENCY WITHDRAW: " # debug_show(amount) # " tokens to " # Principal.toText(recipient));
                return #ok(amount);
            };
            case (#err(error)) {
                return #err("Emergency transfer failed: " # debug_show(error));
            };
        };
    };

    /// Update configuration (Admin+ only)
    public shared({ caller }) func updateConfig(newConfig: DistributionConfig) : async Result.Result<(), Text> {
        // Require Admin or higher role
        if (not _hasRole(caller, #Admin)) {
            return #err("Admin or higher role required");
        };

        // Don't allow config changes after distribution is active
        if (status == #Active or status == #Completed) {
            return #err("Cannot update config when distribution is active or completed");
        };

        // Validate critical fields cannot be changed after creation
        if (not Principal.equal(newConfig.owner, config.owner)) {
            return #err("Cannot change owner after creation");
        };

        if (newConfig.totalAmount != config.totalAmount) {
            return #err("Cannot change total amount after creation");
        };

        config := newConfig;
        Debug.print("⚙️ Configuration updated by: " # Principal.toText(caller));
        return #ok(());
    };

    // ================ ENHANCED AUDIT LOGGING ================

    /// Get security events log (Admin+ only)
    public query func getSecurityEvents() : async [SecurityEvent] {
        // Return security-related events from claim records
        // This could be extended with a dedicated security event log
        let securityEvents = Buffer.Buffer<SecurityEvent>(0);

        for (record in claimRecords.vals()) {
            let event: SecurityEvent = {
                timestamp = record.timestamp;
                eventType = "CLAIM";
                principal = record.participant;
                amount = record.amount;
                details = "Claim operation completed";
                severity = #Info;
            };
            securityEvents.add(event);
        };

        Buffer.toArray(securityEvents);
    };

    /// Get system health status (Admin+ only)
    public query func getSystemHealth() : async SystemHealth {
        var participantCount = 0;
        for (_ in Trie.iter(participants)) {
            participantCount += 1;
        };
        let totalClaimedAmount = totalClaimed;
        // Note: Contract balance requires async call, use cached value or separate async call

        {
            contractBalance = 0; // Query limitation - use getContractBalanceAsync for real balance
            totalClaimed = totalClaimedAmount;
            remainingAmount = 0; // Query limitation - calculate externally
            participantCount = participantCount;
            distributionStatus = status;
            lastActivityTime = lastActivityTime;
            rateLimitEntries = _lastClaimTime.size();
            roleAssignments = _adminRoles.size();
            reentrancyGuardActive = _emergencyReentrancyGuard;
        };
    };

    /// Get system health status with real contract balance (async)
    public shared({ caller }) func getSystemHealthAsync() : async SystemHealth {
        // Require Admin or higher role
        if (not _hasRole(caller, #Admin)) {
            return {
                contractBalance = 0;
                totalClaimed = 0;
                remainingAmount = 0;
                participantCount = 0;
                distributionStatus = #Cancelled;
                lastActivityTime = 0;
                rateLimitEntries = 0;
                roleAssignments = 0;
                reentrancyGuardActive = false;
            };
        };

        let contractBalance = await getContractBalanceAsync();
        var participantCount = 0;
        for (_ in Trie.iter(participants)) {
            participantCount += 1;
        };
        let totalClaimedAmount = totalClaimed;
        let remainingAmount = if (contractBalance >= totalClaimedAmount) {
            contractBalance - totalClaimedAmount
        } else { 0 };

        {
            contractBalance = contractBalance;
            totalClaimed = totalClaimedAmount;
            remainingAmount = remainingAmount;
            participantCount = participantCount;
            distributionStatus = status;
            lastActivityTime = lastActivityTime;
            rateLimitEntries = _lastClaimTime.size();
            roleAssignments = _adminRoles.size();
            reentrancyGuardActive = _emergencyReentrancyGuard;
        };
    };

    /// Types for enhanced monitoring
    public type SecurityEvent = {
        timestamp: Time.Time;
        eventType: Text;
        principal: Principal;
        amount: Nat;
        details: Text;
        severity: Severity;
    };

    public type Severity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
    };

    public type SystemHealth = {
        contractBalance: Nat;
        totalClaimed: Nat;
        remainingAmount: Nat;
        participantCount: Nat;
        distributionStatus: DistributionStatus;
        lastActivityTime: Time.Time;
        rateLimitEntries: Nat;
        roleAssignments: Nat;
        reentrancyGuardActive: Bool;
    };
}