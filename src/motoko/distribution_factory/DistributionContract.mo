// ICTO Distribution Contract - Individual Distribution Canister
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Float "mo:base/Float";
import Types "Types";

persistent actor class DistributionContract(init_config: Types.DistributionConfig, init_creator: Principal) = self {

    // ================ TYPES ================
    
    public type TokenInfo = {
        canisterId: Principal;
        symbol: Text;
        name: Text;
        decimals: Nat8;
    };

    public type EligibilityType = {
        #Open;
        #Whitelist: [Principal];
        #TokenHolder: TokenHolderConfig;
        #NFTHolder: NFTHolderConfig;
        #BlockIDScore: Nat;
        #Hybrid: {
            conditions: [EligibilityType];
            logic: EligibilityLogic;
        };
    };

    public type TokenHolderConfig = {
        canisterId: Principal;
        minAmount: Nat;
        snapshotTime: ?Time.Time;
    };

    public type NFTHolderConfig = {
        canisterId: Principal;
        minCount: Nat;
        collections: ?[Text];
    };

    public type EligibilityLogic = {
        #AND;
        #OR;
    };

    public type RecipientMode = {
        #Fixed;
        #Dynamic;
        #SelfService;
    };

    public type RegistrationPeriod = {
        startTime: Time.Time;
        endTime: Time.Time;
        maxParticipants: ?Nat;
    };

    public type VestingSchedule = {
        #Instant;
        #Linear: LinearVesting;
        #Cliff: CliffVesting;
        #SteppedCliff: [CliffStep];
        #Custom: [UnlockEvent];
    };

    public type LinearVesting = {
        duration: Nat;
        frequency: UnlockFrequency;
    };

    public type CliffVesting = {
        cliffDuration: Nat;
        cliffPercentage: Nat;
        vestingDuration: Nat;
        frequency: UnlockFrequency;
    };

    public type CliffStep = {
        timeOffset: Nat;
        percentage: Nat;
    };

    public type UnlockEvent = {
        timestamp: Time.Time;
        amount: Nat;
    };

    public type UnlockFrequency = {
        #Continuous;
        #Daily;
        #Weekly;
        #Monthly;
        #Quarterly;
        #Yearly;
        #Custom: Nat;
    };

    public type FeeStructure = {
        #Free;
        #Fixed: Nat;
        #Percentage: Nat;
        #Progressive: [FeeTier];
        #RecipientPays;
        #CreatorPays;
    };

    public type FeeTier = {
        threshold: Nat;
        feeRate: Nat;
    };

    public type DistributionConfig = {
        // Basic Information
        title: Text;
        description: Text;
        
        // Token Configuration
        tokenInfo: TokenInfo;
        totalAmount: Nat;
        
        // Eligibility & Recipients
        eligibilityType: EligibilityType;
        eligibilityLogic: ?EligibilityLogic;
        recipientMode: RecipientMode;
        maxRecipients: ?Nat;
        
        // Vesting Configuration
        vestingSchedule: VestingSchedule;
        initialUnlockPercentage: Nat;
        
        // Timing
        registrationPeriod: ?RegistrationPeriod;
        distributionStart: Time.Time;
        distributionEnd: ?Time.Time;
        
        // Fees & Permissions
        feeStructure: FeeStructure;
        allowCancel: Bool;
        allowModification: Bool;
        
        // Owner & Governance
        owner: Principal;
        governance: ?Principal;
        
        // External Integrations
        externalCheckers: ?[(Text, Principal)];
    };

    public type DistributionStatus = {
        #Created;
        #Active;
        #Paused;
        #Completed;
        #Cancelled;
    };

    public type ParticipantStatus = {
        #Registered;
        #Eligible;
        #Ineligible;
        #Claimed;
        #PartialClaim;
    };

    public type Participant = {
        principal: Principal;
        registeredAt: Time.Time;
        eligibleAmount: Nat;
        claimedAmount: Nat;
        lastClaimTime: ?Time.Time;
        status: ParticipantStatus;
        vestingStart: ?Time.Time;
    };

    public type ClaimRecord = {
        participant: Principal;
        amount: Nat;
        timestamp: Time.Time;
        blockHeight: ?Nat;
        transactionId: ?Text;
    };

    public type DistributionStats = {
        totalParticipants: Nat;
        totalDistributed: Nat;
        totalClaimed: Nat;
        remainingAmount: Nat;
        completionPercentage: Float;
        isActive: Bool;
    };

    // ================ STABLE VARIABLES ================
    
    private stable var config: DistributionConfig = init_config;
    private stable var creator: Principal = init_creator;
    private stable var status: DistributionStatus = #Created;
    private stable var createdAt: Time.Time = Time.now();
    
    // Participant management
    private stable var participantsStable: [(Principal, Participant)] = [];
    private stable var claimRecordsStable: [ClaimRecord] = [];
    private stable var whitelistStable: [(Principal, Bool)] = [];
    
    // Stats
    private stable var totalDistributed: Nat = 0;
    private stable var totalClaimed: Nat = 0;
    private stable var participantCount: Nat = 0;
    
    // Runtime variables
    private transient var participants: Trie.Trie<Principal, Participant> = Trie.empty();
    private transient var claimRecords: Buffer.Buffer<ClaimRecord> = Buffer.Buffer(0);
    private transient var whitelist: Trie.Trie<Principal, Bool> = Trie.empty();

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
            case (#Whitelist(addresses)) {
                for (address in addresses.vals()) {
                    whitelist := Trie.put(whitelist, _principalKey(address), Principal.equal, true).0;
                };
            };
            case (_) {};
        };
    };

    // ================ ELIGIBILITY CHECKING ================
    
    private func _checkEligibility(participant: Principal) : async Bool {
        switch (config.eligibilityType) {
            case (#Open) { true };
            case (#Whitelist(_)) {
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
        // TODO: Implement Block ID score checking
        // For now, return true as placeholder
        true
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
                    let vestedAmount = (totalAmount - initialUnlock) * elapsed / linear.duration;
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
                    let remainingAmount = totalAmount - initialUnlock - cliffAmount;
                    let postCliffElapsed = elapsed - cliff.cliffDuration;
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
            config.totalAmount - totalDistributed
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
            unlockedAmount - participant.claimedAmount
        } else { 0 };
        
        if (claimableAmount == 0) {
            return #err("No tokens available to claim at this time");
        };
        
        // TODO: Transfer tokens to participant
        // For now, just update records
        
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
        };
        
        participants := Trie.put(participants, _principalKey(caller), Principal.equal, updatedParticipant).0;
        
        // Add claim record
        let claimRecord: ClaimRecord = {
            participant = caller;
            amount = claimableAmount;
            timestamp = Time.now();
            blockHeight = null; // TODO: Get from token transfer
            transactionId = null; // TODO: Get from token transfer
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
                    unlockedAmount - participant.claimedAmount
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
        
        status := #Active;
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
}