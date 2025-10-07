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
import Error "mo:base/Error";
// Import shared types (trust source)
import DistributionTypes "../shared/types/DistributionTypes";
import DistributionUpgradeTypes "../shared/types/DistributionUpgradeTypes";
import IUpgradeable "../common/IUpgradeable";
import Timer "mo:base/Timer";
import ICRC "../shared/types/ICRC";
import BlockID "../shared/utils/BlockID";
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

    // Contract version for upgrade tracking
    private var contractVersion: IUpgradeable.Version = { major = 1; minor = 0; patch = 0 };
    private var lastActivityTime: Time.Time = Time.now();

    // Participant management
    private var participantsStable: [(Principal, Participant)] = switch (upgradeState) {
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
    private transient var participants: Trie.Trie<Principal, Participant> = Trie.empty();
    private transient var claimRecords: Buffer.Buffer<ClaimRecord> = Buffer.Buffer(0);
    private transient var whitelist: Trie.Trie<Principal, Bool> = Trie.empty();
    private transient var blacklist: Trie.Trie<Principal, Bool> = Trie.empty();

    // Timer and token management
    private var timerId: Nat = 0;
    private var tokenCanister: ?ICRC.ICRCLedger = null;

    // BlockID integration
    private let BLOCK_ID_CANISTER_ID = "3c7yh-4aaaa-aaaap-qhria-cai";
    private let BLOCK_ID_APPLICATION = "block-id";
    private let blockID: BlockID.Self = actor(BLOCK_ID_CANISTER_ID);

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

    // Initialize whitelist and participants from config on contract creation
    public shared({ caller }) func init() : async Result.Result<(), Text> {
        if (not _isOwner(caller)) {
            return #err("Unauthorized: Only owner can initialize distribution");
        };

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

        // Start the timer
        await startTimer();

        initialized := true;
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
        participantsStable := Trie.toArray<Principal, Participant, (Principal, Participant)>(participants, func (k, v) = (k, v));
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
    
    private func _initializeWhitelist() {
        switch (config.eligibilityType) {
            case (#Whitelist) {
                // Initialize whitelist from recipients field
                for (recipient in config.recipients.vals()) {
                    whitelist := Trie.put(whitelist, _principalKey(recipient.address), Principal.equal, true).0;

                    // For whitelist distributions, also initialize participants directly
                    let participant: Participant = {
                        principal = recipient.address;
                        registeredAt = Time.now();
                        eligibleAmount = recipient.amount;
                        claimedAmount = 0;
                        lastClaimTime = null;
                        status = #Eligible;
                        vestingStart = null;
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
            case (#BlockIDScore(minScore)) {
                await _checkBlockIDScore(participant, minScore)
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
    
    private func _checkBlockIDScore(participant: Principal, minScore: Nat) : async Bool {
        try {
            if (minScore == 0) return true;
            let score = await blockID.getWalletScore(participant, BLOCK_ID_APPLICATION);
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
    
    private func _calculateUnlockedAmount(participant: Participant) : Nat {
        let vestingStart = switch (participant.vestingStart) {
            case (?start) { start };
            case null { config.distributionStart };
        };
        
        let elapsed = Int.abs(Time.now() - vestingStart);
        let totalAmount = participant.eligibleAmount;
        let initialUnlock = (totalAmount * config.initialUnlockPercentage) / 100;
        
        switch (config.vestingSchedule) {
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
    
    private func _checkStartTime() : async () {
        if (Time.now() >= config.distributionStart and status == #Created and initialized) {
            ignore {
                let contractBalance = await _getContractTokenBalance();
                if (contractBalance >= config.totalAmount) {
                    ignore activate();
                };
            };
        };
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

                // Convert Tries to Arrays for serialization
                participants = Trie.toArray<Principal, Participant, (Principal, Participant)>(
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
    public query func canUpgrade() : async Result.Result<(), Text> {
        // Check 1: Contract not in emergency or critical processing state
        if (status == #Created and not initialized) {
            return #err("Cannot upgrade: Contract not initialized");
        };

        // Check 2: No pending claims in progress (if status is Active)
        // For distribution contracts, we allow upgrade during most states
        // as claims are independent operations

        // Check 3: Recent activity check (optional - commented out for flexibility)
        // let timeSinceLastActivity = Time.now() - lastActivityTime;
        // if (timeSinceLastActivity < 60_000_000_000) { // 60 seconds
        //     return #err("Cannot upgrade: Recent activity detected (wait 60s)");
        // };

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
        switch (factoryCanisterId) {
            case (?factoryPrincipal) {
                if (caller != factoryPrincipal) {
                    return #err("Unauthorized: Only factory can update version");
                };
            };
            case null {
                return #err("Unauthorized: No factory configured");
            };
        };

        // Update version
        contractVersion := newVersion;
        Debug.print("✅ DistributionContract version updated by factory: " # debug_show(newVersion) # " by " # Principal.toText(caller));

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
        
        // Create participant record
        let participant: Participant = {
            principal = caller;
            registeredAt = Time.now();
            eligibleAmount = eligibleAmount;
            claimedAmount = 0;
            lastClaimTime = null;
            status = #Registered;
            vestingStart = null;
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
    private func _autoRegisterParticipant(caller: Principal) : async Result.Result<Participant, Text> {
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
        
        // Create participant record
        let participant: Participant = {
            principal = caller;
            registeredAt = Time.now();
            eligibleAmount = eligibleAmount;
            claimedAmount = 0;
            lastClaimTime = null;
            status = #Registered;
            vestingStart = null;
            note = null; // No specific note for auto-registered participants
        };
        
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, participant).0;
        participantCount += 1;

        // Notify factory about new recipient (Factory Storage Standard)
        await _notifyFactoryRecipientAdded(caller);

        #ok(participant)
    };
    
    public shared({ caller }) func claim() : async Result.Result<Nat, Text> {
        // CHECKS: All validation first, no state changes
        if (not _isActive()) {
            return #err("Distribution is not currently active");
        };

        // Check if caller is blacklisted
        if (_isBlacklisted(caller)) {
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

        let claimableAmount = if (unlockedAmount > participant.claimedAmount) {
            Nat.sub(unlockedAmount, participant.claimedAmount)
        } else { 0 };

        if (claimableAmount == 0) {
            return #err("No tokens available to claim at this time");
        };

        // Additional safety check for maximum claim amount per transaction
        let maxClaimPerTx = 10000000000; // 100 tokens with 8 decimals
        if (claimableAmount > maxClaimPerTx) {
            return #err("Claim amount exceeds maximum per transaction");
        };

        // Check BlockID score if required
        let isEligible = await _checkEligibility(caller);
        if (not isEligible) {
            return #err("Not eligible for this distribution");
        };

        // EFFECTS: Update state before external calls
        let updatedParticipant = {
            participant with
            claimedAmount = participant.claimedAmount + claimableAmount;
            lastClaimTime = ?Time.now();
        };

        // Update participant state
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, updatedParticipant).0;
        totalClaimed += claimableAmount;

        // Create claim record for tracking
        let claimRecord: ClaimRecord = {
            participant = caller;
            amount = claimableAmount;
            timestamp = Time.now();
            blockHeight = null; // TODO: Get from blockchain
            transactionId = null; // Will be updated after transfer
        };
        claimRecords.add(claimRecord);

        // INTERACTIONS: External calls last
        let transferResult = await* _transfer(caller, claimableAmount);
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
                let revertedParticipant = {
                    participant with
                    claimedAmount = participant.claimedAmount; // Original amount
                    lastClaimTime = participant.lastClaimTime; // Original time
                };
                participants := Trie.put(participants, _principalKey(caller), Principal.equal, revertedParticipant).0;
                totalClaimed -= claimableAmount;
                let _ = claimRecords.removeLast(); // Remove failed claim record

                return #err("Token transfer failed: " # debug_show(err));
            };
        };
        
        #ok(claimableAmount)
    };

    // Add blacklist checking function
    private func _isBlacklisted(principal: Principal) : Bool {
        switch (Trie.get(blacklist, _principalKey(principal), Principal.equal)) {
            case (?true) { true };
            case _ { false };
        };
    };

    // Safe calculation with overflow protection
    private func _safeCalculateUnlockedAmount(participant: Participant) : Result.Result<Nat, Text> {
        let vestingStart = switch (participant.vestingStart) {
            case (?start) { start };
            case null { config.distributionStart };
        };

        let currentTime = Time.now();
        if (currentTime < vestingStart) {
            return #ok(0); // Vesting hasn't started
        };

        let elapsed = Int.abs(currentTime - vestingStart);
        let totalAmount = participant.eligibleAmount;

        // Check for reasonable bounds
        if (totalAmount == 0) {
            return #ok(0);
        };

        // Safe calculation of initial unlock
        let initialUnlockResult = _safePercentageOf(totalAmount, config.initialUnlockPercentage);
        let initialUnlock = switch (initialUnlockResult) {
            case (#ok(amount)) { amount };
            case (#err(error)) { return #err(error) };
        };

        switch (config.vestingSchedule) {
            case (#Instant) {
                #ok(totalAmount)
            };
            case (#Linear(linear)) {
                if (elapsed >= linear.duration) {
                    #ok(totalAmount)
                } else {
                    let vestingAmount = _safeSubtract(totalAmount, initialUnlock);
                    let vestedResult = _safeMultiplyDivide(vestingAmount, elapsed, linear.duration);
                    switch (vestedResult) {
                        case (#ok(vested)) { #ok(initialUnlock + vested) };
                        case (#err(error)) { #err(error) };
                    };
                }
            };
            case (#Cliff(cliff)) {
                if (elapsed < cliff.cliffDuration) {
                    #ok(initialUnlock)
                } else if (elapsed >= cliff.cliffDuration + cliff.vestingDuration) {
                    #ok(totalAmount)
                } else {
                    let cliffAmountResult = _safePercentageOf(totalAmount, cliff.cliffPercentage);
                    let cliffAmount = switch (cliffAmountResult) {
                        case (#ok(amount)) { amount };
                        case (#err(error)) { return #err(error) };
                    };

                    let remainingAmount = _safeSubtract(_safeSubtract(totalAmount, initialUnlock), cliffAmount);
                    let postCliffElapsed = _safeSubtract(elapsed, cliff.cliffDuration);
                    let vestedResult = _safeMultiplyDivide(remainingAmount, postCliffElapsed, cliff.vestingDuration);

                    switch (vestedResult) {
                        case (#ok(vested)) { #ok(initialUnlock + cliffAmount + vested) };
                        case (#err(error)) { #err(error) };
                    };
                }
            };
            case (#Single(single)) {
                if (elapsed >= single.duration) {
                    #ok(totalAmount)
                } else {
                    #ok(initialUnlock)
                }
            };
            case (#SteppedCliff(steps)) {
                var unlockedAmount = initialUnlock;
                for (step in steps.vals()) {
                    if (elapsed >= step.timeOffset) {
                        let stepAmountResult = _safePercentageOf(totalAmount, step.percentage);
                        let stepAmount = switch (stepAmountResult) {
                            case (#ok(amount)) { amount };
                            case (#err(error)) { return #err(error) };
                        };
                        unlockedAmount += stepAmount;
                    };
                };
                #ok(Nat.min(unlockedAmount, totalAmount))
            };
            case (#Custom(unlockEvents)) {
                var unlockedAmount = initialUnlock;
                for (event in unlockEvents.vals()) {
                    if (currentTime >= event.timestamp) {
                        unlockedAmount += event.amount;
                    };
                };
                #ok(Nat.min(unlockedAmount, totalAmount))
            };
        };
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
        
        // Calculate elapsed time
        let vestingStart = switch (participant.vestingStart) {
            case (?start) { start };
            case null { config.distributionStart };
        };
        let elapsed = Int.abs(Time.now() - vestingStart);
        
        // Check if early unlock is allowed
        if (not _canEarlyUnlock(elapsed, config.penaltyUnlock)) {
            return #err("Early unlock is not allowed at this time. Check minimum lock time requirements.");
        };
        
        // Calculate full vested amount (what would be unlocked without penalty)
        let totalAmount = participant.eligibleAmount;
        let remainingAmount = if (totalAmount > participant.claimedAmount) {
            Nat.sub(totalAmount, participant.claimedAmount)
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
        let updatedParticipant: Participant = {
            principal = participant.principal;
            registeredAt = participant.registeredAt;
            eligibleAmount = participant.eligibleAmount;
            claimedAmount = participant.eligibleAmount; // Mark as fully claimed
            lastClaimTime = ?Time.now();
            status = #Claimed;
            vestingStart = participant.vestingStart;
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
    
    // Query functions
    public query func getParticipant(principal: Principal) : async ?Participant {
        Trie.get(participants, _principalKey(principal), Principal.equal)
    };
    
    // Get comprehensive user context information
    public shared({ caller }) func whoami() : async {
        principal: Principal;
        isOwner: Bool;
        isRegistered: Bool;
        isEligible: Bool;
        participant: ?Participant;
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
                if (unlockedAmount > p.claimedAmount) {
                    Nat.sub(unlockedAmount, p.claimedAmount)
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
                if (unlockedAmount > participant.claimedAmount) {
                    Nat.sub(unlockedAmount, participant.claimedAmount)
                } else { 0 }
            };
            case null { 0 };
        }
    };
    
    public query func getAllParticipants() : async [Participant] {
        let buffer = Buffer.Buffer<Participant>(0);
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
        Timer.cancelTimer(timerId); // Cancel auto-start timer if running
        #ok()
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
        Timer.cancelTimer(timerId); // Cancel timer
        
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
                    // Update existing participant
                    let updated: Participant = {
                        principal = existing.principal;
                        registeredAt = existing.registeredAt;
                        eligibleAmount = amount;
                        claimedAmount = existing.claimedAmount;
                        lastClaimTime = existing.lastClaimTime;
                        status = existing.status;
                        vestingStart = existing.vestingStart;
                        note = existing.note; // Preserve existing note
                    };
                    participants := Trie.put(participants, _principalKey(principal), Principal.equal, updated).0;
                };
                case null {
                    // Add new participant
                    let participant: Participant = {
                        principal = principal;
                        registeredAt = Time.now();
                        eligibleAmount = amount;
                        claimedAmount = 0;
                        lastClaimTime = null;
                        status = #Eligible;
                        vestingStart = ?Time.now();
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
    
    public func startTimer() : async () {
        timerId := Timer.recurringTimer<system>(#seconds(30), _checkStartTime);
    };
    
    public func cancelTimer() : async () {
        Timer.cancelTimer(timerId);
    };
    
    public query func getTimerStatus() : async { timerId: Nat; isRunning: Bool } {
        { timerId = timerId; isRunning = timerId > 0 }
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
                    // Update existing participant
                    let updated: Participant = {
                        existing with
                        eligibleAmount = amount;
                    };
                    participants := Trie.put(participants, _principalKey(principal), Principal.equal, updated).0;
                };
                case null {
                    // Add new participant
                    let participant: Participant = {
                        principal = principal;
                        registeredAt = Time.now();
                        eligibleAmount = amount;
                        claimedAmount = 0;
                        lastClaimTime = null;
                        status = #Eligible;
                        vestingStart = ?Time.now();
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
                let vestingStart = switch (participant.vestingStart) {
                    case (?start) { start };
                    case null { config.distributionStart };
                };
                
                // Calculate remaining locked amount
                let unlockedAmount = _calculateUnlockedAmount(participant);
                let remainingAmount = if (participant.eligibleAmount > unlockedAmount) {
                    Nat.sub(participant.eligibleAmount, unlockedAmount)
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
}