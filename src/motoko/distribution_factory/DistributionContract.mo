// ICTO Distribution Contract - Individual Distribution Canister
import Principal "mo:base/Principal";
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

// Import shared types (trust source)
import DistributionTypes "../shared/types/DistributionTypes";
import Timer "mo:base/Timer";
import ICRC "../shared/types/ICRC";
import BlockID "../shared/utils/BlockID";

persistent actor class DistributionContract(init_config: DistributionTypes.DistributionConfig, init_creator: Principal) = self {

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

    // ================ STABLE VARIABLES ================
    
    private var config: DistributionConfig = init_config;
    private var creator: Principal = init_creator;
    private var status: DistributionStatus = #Created;
    private var createdAt: Time.Time = Time.now();
    private var initialized: Bool = false;
    
    // Participant management
    private var participantsStable: [(Principal, Participant)] = [];
    private var claimRecordsStable: [ClaimRecord] = [];
    private var whitelistStable: [(Principal, Bool)] = [];
    
    // Stats
    private var totalDistributed: Nat = 0;
    private var totalClaimed: Nat = 0;
    private var participantCount: Nat = 0;
    
    // Runtime variables
    private transient var participants: Trie.Trie<Principal, Participant> = Trie.empty();
    private transient var claimRecords: Buffer.Buffer<ClaimRecord> = Buffer.Buffer(0);
    private transient var whitelist: Trie.Trie<Principal, Bool> = Trie.empty();
    
    // Timer and token management
    private var timerId: Nat = 0;
    private var tokenCanister: ?ICRC.ICRCLedger = null;
    
    // BlockID integration
    private let BLOCK_ID_CANISTER_ID = "3c7yh-4aaaa-aaaap-qhria-cai";
    private let BLOCK_ID_APPLICATION = "block-id";
    private let blockID: BlockID.Self = actor(BLOCK_ID_CANISTER_ID);

    //Token info
    private var transferFee: Nat = 0;
    
    // Constants
    private let E8S: Nat = 100_000_000;
    private let NANO_TIME: Nat = 1_000_000_000;

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
        
        // Initialize whitelist from config if first run
        if (Trie.size(whitelist) == 0) {
            _initializeWhitelist();
        };
        
        // Clear stable variables
        participantsStable := [];
        claimRecordsStable := [];
        whitelistStable := [];
        
        Debug.print("DistributionContract: Postupgrade completed");
    };

    // ================ HELPER FUNCTIONS ================
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _isOwner(caller: Principal) : Bool {
        Principal.equal(caller, creator) or Principal.equal(caller, config.owner) or
        (Option.isSome(config.governance) and Principal.equal(caller, Option.get(config.governance, caller)))
    };
    
    private func _isActive() : Bool {
        status == #Active and Time.now() >= config.distributionStart and
        (Option.isNull(config.distributionEnd) or Time.now() <= Option.get(config.distributionEnd, Time.now()))
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
            let contractBalance = await _getContractTokenBalance();
            if (contractBalance >= config.totalAmount) {
                ignore activate();
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
        
        // Calculate eligible amount (for now using equal distribution)
        let eligibleAmount = if (config.totalAmount > 0 and participantCount < config.totalAmount) {
            config.totalAmount / (participantCount + 1) // Simplified calculation
        } else { 0 };
        
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
        
        #ok()
    };
    
    public shared({ caller }) func claim() : async Result.Result<Nat, Text> {
        // Check if distribution is active
        if (not _isActive()) {
            return #err("Distribution is not currently active");
        };
        
        // Get participant
        let participant = switch (Trie.get(participants, _principalKey(caller), Principal.equal)) {
            case (?p) { p };
            case null {
                return #err("Not registered for this distribution");
            };
        };
        
        // Calculate unlocked amount
        let unlockedAmount = _calculateUnlockedAmount(participant);
        let claimableAmount = if (unlockedAmount > participant.claimedAmount) {
            Nat.sub(unlockedAmount, participant.claimedAmount)
        } else { 0 };
        
        if (claimableAmount == 0) {
            return #err("No tokens available to claim at this time");
        };
        
        // Check BlockID score if required
        let isEligible = await _checkEligibility(caller);
        if (not isEligible) {
            return #err("Not eligible for this distribution");
        };
        
        // Transfer tokens to participant
        let transferResult = await* _transfer(caller, claimableAmount);
        let txIndex = switch (transferResult) {
            case (#ok(index)) { ?index };
            case (#err(err)) {
                return #err("Token transfer failed: " # debug_show(err));
            };
        };
        
        // Update participant record
        let updatedParticipant: Participant = {
            principal = participant.principal;
            registeredAt = participant.registeredAt;
            eligibleAmount = participant.eligibleAmount;
            claimedAmount = participant.claimedAmount + claimableAmount;
            lastClaimTime = ?Time.now();
            status = if (participant.claimedAmount + claimableAmount >= participant.eligibleAmount) {
                #Claimed
            } else {
                #PartialClaim
            };
            vestingStart = participant.vestingStart;
            note = participant.note; // Preserve existing note
        };
        
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, updatedParticipant).0;
        
        // Add claim record
        let claimRecord: ClaimRecord = {
            participant = caller;
            amount = claimableAmount;
            timestamp = Time.now();
            blockHeight = null; // TODO: Get from blockchain
            transactionId = switch (txIndex) {
                case (?index) { ?Nat.toText(index) };
                case null { null };
            }; // Transaction ID from ICRC transfer
        };
        
        claimRecords.add(claimRecord);
        totalClaimed += claimableAmount;
        
        #ok(claimableAmount)
    };
    
    // Query functions
    public query func getParticipant(principal: Principal) : async ?Participant {
        Trie.get(participants, _principalKey(principal), Principal.equal)
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

    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        Cycles.balance() > 1_000_000_000 // 1B cycles minimum
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
}