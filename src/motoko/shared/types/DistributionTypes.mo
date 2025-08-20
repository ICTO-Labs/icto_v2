import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Array "mo:base/Array";
import Float "mo:base/Float";

module DistributionTypes {

    // ================ CORE TYPES ================

    // Campaign Types
    public type CampaignType = {
        #Airdrop;
        #Vesting;
        #Lock;
    };

    // Unified Recipient type for all participant data
    public type Recipient = {
        address: Principal;
        amount: Nat;
        note: ?Text;
    };



    // Distribution Configuration
    public type DistributionConfig = {
        // Basic Information
        title: Text;
        description: Text;
        isPublic: Bool;
        campaignType: CampaignType; // New field
        
        // Token Configuration
        tokenInfo: TokenInfo;
        totalAmount: Nat;
        
        // Eligibility & Recipients
        eligibilityType: EligibilityType;
        eligibilityLogic: ?EligibilityLogic;
        recipientMode: RecipientMode;
        maxRecipients: ?Nat;
        
        // Unified Recipients List (replaces separate whitelist, etc.)
        recipients: [Recipient]; // New unified field
        
        // Vesting Configuration
        vestingSchedule: VestingSchedule;
        initialUnlockPercentage: Nat;
        penaltyUnlock: ?PenaltyUnlock; // Optional penalty unlock configuration for any vesting type
        
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

    public type TokenInfo = {
        canisterId: Principal;
        symbol: Text;
        name: Text;
        decimals: Nat8;
    };

    public type EligibilityType = {
        #Open;        // Anyone can register themselves
        #Whitelist;   // Only pre-defined recipients (from recipients field)
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
        #Single: SingleVesting;
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

    public type SingleVesting = {
        duration: Nat;
    };

    // Penalty unlock configuration - can be applied to any vesting type
    public type PenaltyUnlock = {
        enableEarlyUnlock: Bool;
        penaltyPercentage: Nat;       // Percentage (0-100) taken as penalty
        penaltyRecipient: ?Text;      // Optional recipient principal for penalty tokens (null = burn)
        minLockTime: ?Nat;           // Minimum time before early unlock is allowed (nanoseconds)
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

    // External Deployer Args
    public type ExternalDeployerArgs = {
        config: DistributionConfig;
        owner: Principal;
    };

    // Distribution Contract Record (stored in factory)
    public type DistributionContract = {
        id: Text;
        creator: Principal;
        config: DistributionConfig;
        deployedCanister: ?Principal;
        createdAt: Time.Time;
        status: DistributionStatus;
    };

    public type DistributionStatus = {
        #Created;
        #Deployed;
        #Active;
        #Paused;
        #Completed;
        #Cancelled;
    };

    // Deployment Result
    public type DeploymentResult = {
        distributionCanisterId: Principal;
    };

    // For backend service compatibility
    public type StableState = {
        var distributionFactoryCanisterId: ?Principal;
        var distributionContracts: [(Text, DistributionContract)];
    };

    public func emptyState() : StableState {
        {
            var distributionFactoryCanisterId = null;
            var distributionContracts = [];
        }
    };

    // ================ PARTICIPANT TYPES ================

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
        note: ?Text; // From Recipient.note
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

    // ================ RESULT TYPES ================

    public type DistributionResult<T> = {
        #Ok: T;
        #Err: DistributionError;
    };

    public type DistributionError = {
        #Unauthorized: Text;
        #NotFound: Text;
        #AlreadyExists: Text;
        #InvalidInput: Text;
        #InternalError: Text;
        #InsufficientFunds: Text;
        #DistributionNotActive: Text;
        #RegistrationClosed: Text;
        #MaxParticipantsReached: Text;
        #NotEligible: Text;
        #NothingToClaim: Text;
        #VestingNotStarted: Text;
        #InvalidPrincipal: Text;
    };

    // ================ HELPER FUNCTIONS ================

    // Convert campaign type to text
    public func campaignTypeToText(campaignType: CampaignType) : Text {
        switch (campaignType) {
            case (#Airdrop) { "Airdrop" };
            case (#Vesting) { "Vesting" };
            case (#Lock) { "Lock" };
        }
    };

    // Convert text to campaign type
    public func textToCampaignType(text: Text) : ?CampaignType {
        switch (text) {
            case ("Airdrop") { ?#Airdrop };
            case ("Vesting") { ?#Vesting };
            case ("Lock") { ?#Lock };
            case (_) { null };
        }
    };

    // Validate recipient address
    public func isValidRecipient(recipient: Recipient) : Bool {
        // Basic validation
        recipient.amount > 0 and Principal.toText(recipient.address) != ""
    };

    // Create recipient from address and amount
    public func createRecipient(address: Principal, amount: Nat, note: ?Text) : Recipient {
        {
            address = address;
            amount = amount;
            note = note;
        }
    };

    // Extract principals from recipients
    public func extractPrincipals(recipients: [Recipient]) : [Principal] {
        Array.map<Recipient, Principal>(recipients, func(r) = r.address)
    };

    // Calculate total amount from recipients
    public func calculateTotalAmount(recipients: [Recipient]) : Nat {
        Array.foldLeft<Recipient, Nat>(recipients, 0, func(acc, r) = acc + r.amount)
    };

    // Validate distribution config
    public func validateConfig(config: DistributionConfig) : DistributionResult<()> {
        // Basic validation
        if (config.title == "") {
            return #Err(#InvalidInput("Title cannot be empty"));
        };

        if (config.totalAmount == 0) {
            return #Err(#InvalidInput("Total amount must be greater than 0"));
        };

        // Validate recipients based on eligibility type
        switch (config.eligibilityType) {
            case (#Whitelist) {
                // For whitelist, recipients must be pre-defined
                if (config.recipients.size() == 0) {
                    return #Err(#InvalidInput("Whitelist recipients cannot be empty"));
                };
                
                // Validate each recipient
                for (recipient in config.recipients.vals()) {
                    if (not isValidRecipient(recipient)) {
                        return #Err(#InvalidInput("Invalid recipient: " # Principal.toText(recipient.address)));
                    };
                };
                
                // Check if total amount matches recipients
                let calculatedTotal = calculateTotalAmount(config.recipients);
                if (calculatedTotal != config.totalAmount) {
                    return #Err(#InvalidInput("Total amount does not match sum of recipient amounts"));
                };
            };
            case (#Open) {
                // For open distributions, recipients array can be empty initially
                // Recipients will register themselves and be added to the list
            };
            case (_) {
                // For other types (TokenHolder, NFT, etc.), specific validation logic needed
            };
        };

        #Ok(())
    };

}