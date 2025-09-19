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
        #LaunchpadDistribution; // New: For launchpad-linked distributions
    };

    // Launchpad Integration Types
    public type LaunchpadContext = {
        launchpadId: Principal;           // Reference to launchpad project
        category: DistributionCategory;   // Type of distribution within launchpad
        projectMetadata: ProjectMetadata; // Project info for display
        batchId: ?Text;                   // For grouping multiple distributions from same launchpad
    };

    // Dynamic distribution category - can be any text for flexibility
    public type DistributionCategory = {
        id: Text;           // Unique identifier (e.g. "team", "advisors", "fairlaunch")
        name: Text;         // Display name (e.g. "Team Allocation", "Advisor Vesting")
        description: ?Text; // Optional description
        order: ?Nat;        // Optional ordering for display
    };

    public type ProjectMetadata = {
        name: Text;
        symbol: Text;
        logo: ?Text;
        website: ?Text;
        description: Text;
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
        campaignType: CampaignType;

        // Launchpad Integration (Optional - backward compatible)
        launchpadContext: ?LaunchpadContext; // New: Optional launchpad linking

        // Token Configuration
        tokenInfo: TokenInfo;
        totalAmount: Nat;

        // Eligibility & Recipients
        eligibilityType: EligibilityType;
        eligibilityLogic: ?EligibilityLogic;
        recipientMode: RecipientMode;
        maxRecipients: ?Nat;

        // Unified Recipients List (replaces separate whitelist, etc.)
        recipients: [Recipient];

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
        governance: ?Principal; // Legacy single governance

        // Enhanced Governance (Optional - can be used by ANY distribution)
        multiSigGovernance: ?MultiSigGovernance; // New: Optional multisig for any distribution

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

    // Batch Operations for Launchpad
    public type BatchDistributionRequest = {
        launchpadId: Principal;
        projectMetadata: ProjectMetadata;
        batchId: Text;
        distributions: [DistributionConfig];
    };

    public type BatchDistributionResult = {
        batchId: Text;
        launchpadId: Principal;
        distributions: [DistributionDeploymentResult];
        successCount: Nat;
        failureCount: Nat;
    };

    public type DistributionDeploymentResult = {
        category: DistributionCategory;
        result: {
            #Ok: Principal;  // Deployed canister ID
            #Err: Text;      // Error message
        };
    };

    // Multi-signature Governance (can be used by ANY distribution)
    public type MultiSigGovernance = {
        threshold: Nat;              // Required signatures (must be <= signers.size())
        signers: [Principal];        // Authorized signers
        timelock: ?Nat;             // Timelock period in nanoseconds (optional)
        proposalExpiry: ?Nat;       // Proposal expiry time in nanoseconds (optional)

        // Governance scope - what actions require multisig approval
        governanceScope: GovernanceScope;

        // Emergency settings
        emergencyActions: ?EmergencySettings;
    };

    public type GovernanceScope = {
        requireApprovalFor: [GovernanceAction]; // Which actions need multisig
        exemptActions: [GovernanceAction];      // Which actions owner can do alone
    };

    public type GovernanceAction = {
        #PauseDistribution;
        #ResumeDistribution;
        #CancelDistribution;
        #UpdateConfig;
        #EmergencyWithdraw;
        #AddParticipants;
        #RemoveParticipants;
        #UpdateVesting;
        #ChangeOwnership;
        #UpdateGovernance;
        #FundDistribution;
        #All; // Require approval for ALL actions
    };

    public type EmergencySettings = {
        emergencySigners: [Principal];    // Special signers for emergencies
        emergencyThreshold: Nat;          // Lower threshold for emergencies
        emergencyTimelock: ?Nat;          // Shorter timelock for emergencies
        allowEmergencyBypass: Bool;       // Allow bypassing normal governance in emergency
    };

    public type GovernanceProposal = {
        id: Text;
        proposer: Principal;
        proposalType: ProposalType;
        description: Text;
        signatures: [Principal];
        createdAt: Time.Time;
        executedAt: ?Time.Time;
        expiresAt: ?Time.Time;
        status: ProposalStatus;
    };

    public type ProposalType = {
        #UpdateConfig: DistributionConfig;
        #PauseDistribution;
        #ResumeDistribution;
        #CancelDistribution;
        #EmergencyWithdraw: { recipient: Principal; amount: ?Nat };
        #UpdateGovernance: MultiSigGovernance;
    };

    public type ProposalStatus = {
        #Pending;
        #Approved;
        #Executed;
        #Rejected;
        #Expired;
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
            case (#LaunchpadDistribution) { "LaunchpadDistribution" };
        }
    };

    // Convert text to campaign type
    public func textToCampaignType(text: Text) : ?CampaignType {
        switch (text) {
            case ("Airdrop") { ?#Airdrop };
            case ("Vesting") { ?#Vesting };
            case ("Lock") { ?#Lock };
            case ("LaunchpadDistribution") { ?#LaunchpadDistribution };
            case (_) { null };
        }
    };

    // Distribution Category helpers
    public func createDistributionCategory(id: Text, name: Text, description: ?Text, order: ?Nat) : DistributionCategory {
        {
            id = id;
            name = name;
            description = description;
            order = order;
        }
    };

    // Predefined common categories for convenience
    public func getCommonCategories() : [DistributionCategory] {
        [
            { id = "fairlaunch"; name = "Fair Launch"; description = ?"Public sale allocation - TGE unlock"; order = ?1 },
            { id = "team"; name = "Team"; description = ?"Team allocation - 12M cliff + 24M linear"; order = ?2 },
            { id = "advisors"; name = "Advisors"; description = ?"Advisor allocation - 6M cliff + 24M linear"; order = ?3 },
            { id = "marketing"; name = "Marketing"; description = ?"Marketing allocation - 3M cliff + 12M linear"; order = ?4 },
            { id = "liquidity"; name = "Liquidity"; description = ?"Liquidity pool allocation - instant unlock"; order = ?5 },
            { id = "treasury"; name = "Treasury"; description = ?"Treasury allocation - 24M single lock"; order = ?6 },
            { id = "private"; name = "Private Sale"; description = ?"Private sale - 6M cliff + 18M linear"; order = ?7 },
            { id = "seed"; name = "Seed"; description = ?"Seed round - 12M cliff + 18M linear"; order = ?8 },
            { id = "strategic"; name = "Strategic"; description = ?"Strategic partners - 9M cliff + 15M linear"; order = ?9 }
        ]
    };

    // Preset vesting schedules for common categories
    public func getPresetVestingSchedule(categoryId: Text) : VestingSchedule {
        switch (categoryId) {
            case ("fairlaunch") {
                #Instant // TGE unlock
            };
            case ("team") {
                #Cliff({
                    cliffDuration = 365 * 24 * 60 * 60 * 1_000_000_000; // 12 months
                    cliffPercentage = 0; // No unlock at cliff
                    vestingDuration = 730 * 24 * 60 * 60 * 1_000_000_000; // 24 months
                    frequency = #Monthly;
                })
            };
            case ("advisors") {
                #Cliff({
                    cliffDuration = 180 * 24 * 60 * 60 * 1_000_000_000; // 6 months
                    cliffPercentage = 0;
                    vestingDuration = 730 * 24 * 60 * 60 * 1_000_000_000; // 24 months
                    frequency = #Monthly;
                })
            };
            case ("marketing") {
                #Cliff({
                    cliffDuration = 90 * 24 * 60 * 60 * 1_000_000_000; // 3 months
                    cliffPercentage = 10; // 10% unlock at cliff
                    vestingDuration = 365 * 24 * 60 * 60 * 1_000_000_000; // 12 months
                    frequency = #Monthly;
                })
            };
            case ("liquidity") {
                #Instant // Immediate unlock for DEX
            };
            case ("treasury") {
                #Single({
                    duration = 730 * 24 * 60 * 60 * 1_000_000_000; // 24 months lock
                })
            };
            case ("private") {
                #Cliff({
                    cliffDuration = 180 * 24 * 60 * 60 * 1_000_000_000; // 6 months
                    cliffPercentage = 5; // 5% unlock at cliff
                    vestingDuration = 545 * 24 * 60 * 60 * 1_000_000_000; // 18 months
                    frequency = #Monthly;
                })
            };
            case ("seed") {
                #Cliff({
                    cliffDuration = 365 * 24 * 60 * 60 * 1_000_000_000; // 12 months
                    cliffPercentage = 0;
                    vestingDuration = 545 * 24 * 60 * 60 * 1_000_000_000; // 18 months
                    frequency = #Monthly;
                })
            };
            case ("strategic") {
                #Cliff({
                    cliffDuration = 270 * 24 * 60 * 60 * 1_000_000_000; // 9 months
                    cliffPercentage = 10; // 10% unlock at cliff
                    vestingDuration = 455 * 24 * 60 * 60 * 1_000_000_000; // 15 months
                    frequency = #Monthly;
                })
            };
            case (_) {
                // Default: 6 month cliff + 18 month linear
                #Cliff({
                    cliffDuration = 180 * 24 * 60 * 60 * 1_000_000_000;
                    cliffPercentage = 0;
                    vestingDuration = 545 * 24 * 60 * 60 * 1_000_000_000;
                    frequency = #Monthly;
                })
            };
        }
    };

    // Create distribution config with preset vesting for category
    public func createDistributionConfigForCategory(
        baseConfig: DistributionConfig,
        category: DistributionCategory,
        overrideVesting: ?VestingSchedule // Optional override
    ) : DistributionConfig {
        let vestingSchedule = switch (overrideVesting) {
            case (?customVesting) { customVesting };
            case null { getPresetVestingSchedule(category.id) };
        };

        {
            baseConfig with
            vestingSchedule = vestingSchedule;
            title = category.name # " - " # baseConfig.title;
            description = switch (category.description) {
                case (?desc) { desc # " | " # baseConfig.description };
                case null { baseConfig.description };
            };
        }
    };

    // MULTISIG GOVERNANCE HELPERS

    // Create standard multisig for team allocations
    public func createTeamMultiSig(signers: [Principal]) : MultiSigGovernance {
        {
            threshold = 2; // Require 2 signatures
            signers = signers;
            timelock = ?(24 * 60 * 60 * 1_000_000_000); // 24 hours
            proposalExpiry = ?(7 * 24 * 60 * 60 * 1_000_000_000); // 7 days
            governanceScope = {
                requireApprovalFor = [
                    #PauseDistribution,
                    #CancelDistribution,
                    #UpdateConfig,
                    #EmergencyWithdraw,
                    #UpdateVesting,
                    #ChangeOwnership
                ];
                exemptActions = [#AddParticipants, #RemoveParticipants]; // Owner can manage participants
            };
            emergencyActions = ?{
                emergencySigners = signers;
                emergencyThreshold = 1; // In emergency, only 1 signature needed
                emergencyTimelock = ?(1 * 60 * 60 * 1_000_000_000); // 1 hour in emergency
                allowEmergencyBypass = true;
            };
        }
    };

    // Create strict multisig for high-value allocations
    public func createStrictMultiSig(signers: [Principal], threshold: Nat) : MultiSigGovernance {
        {
            threshold = threshold;
            signers = signers;
            timelock = ?(48 * 60 * 60 * 1_000_000_000); // 48 hours
            proposalExpiry = ?(14 * 24 * 60 * 60 * 1_000_000_000); // 14 days
            governanceScope = {
                requireApprovalFor = [#All]; // ALL actions need approval
                exemptActions = []; // No exemptions
            };
            emergencyActions = ?{
                emergencySigners = signers;
                emergencyThreshold = threshold; // Same threshold even in emergency
                emergencyTimelock = ?(12 * 60 * 60 * 1_000_000_000); // 12 hours in emergency
                allowEmergencyBypass = false; // No bypass allowed
            };
        }
    };

    // Create flexible multisig for marketing/operations
    public func createOperationalMultiSig(signers: [Principal]) : MultiSigGovernance {
        {
            threshold = 1; // Only 1 signature needed (but tracked)
            signers = signers;
            timelock = ?(2 * 60 * 60 * 1_000_000_000); // 2 hours
            proposalExpiry = ?(3 * 24 * 60 * 60 * 1_000_000_000); // 3 days
            governanceScope = {
                requireApprovalFor = [
                    #CancelDistribution,
                    #EmergencyWithdraw,
                    #ChangeOwnership
                ]; // Only major actions
                exemptActions = [
                    #PauseDistribution,
                    #ResumeDistribution,
                    #AddParticipants,
                    #RemoveParticipants,
                    #UpdateConfig
                ]; // Owner can do operational tasks
            };
            emergencyActions = null; // No special emergency procedures
        }
    };

    // Create custom multisig
    public func createCustomMultiSig(
        signers: [Principal],
        threshold: Nat,
        timelockHours: ?Nat,
        requiredActions: [GovernanceAction],
        exemptActions: [GovernanceAction]
    ) : MultiSigGovernance {
        let timelock = switch (timelockHours) {
            case (?hours) { ?(hours * 60 * 60 * 1_000_000_000) };
            case null { null };
        };

        {
            threshold = threshold;
            signers = signers;
            timelock = timelock;
            proposalExpiry = ?(7 * 24 * 60 * 60 * 1_000_000_000); // Default 7 days
            governanceScope = {
                requireApprovalFor = requiredActions;
                exemptActions = exemptActions;
            };
            emergencyActions = null; // Custom setups handle emergencies separately
        }
    };

    // Check if action requires multisig approval
    public func requiresMultiSigApproval(
        governance: ?MultiSigGovernance,
        action: GovernanceAction
    ) : Bool {
        switch (governance) {
            case (?multiSig) {
                // Check if action is in exemptions first
                let isExempt = Array.find<GovernanceAction>(
                    multiSig.governanceScope.exemptActions,
                    func(exemptAction) = exemptAction == action
                ) != null;

                if (isExempt) return false;

                // Check if action requires approval or if ALL actions require approval
                let requiresApproval = Array.find<GovernanceAction>(
                    multiSig.governanceScope.requireApprovalFor,
                    func(requiredAction) = requiredAction == action or requiredAction == #All
                ) != null;

                requiresApproval
            };
            case null { false }; // No multisig = no approval needed
        }
    };

    // Check if distribution is linked to launchpad
    public func isLaunchpadDistribution(config: DistributionConfig) : Bool {
        switch (config.launchpadContext) {
            case (?_) { true };
            case null { false };
        }
    };

    // Get distribution category from config
    public func getDistributionCategory(config: DistributionConfig) : ?DistributionCategory {
        switch (config.launchpadContext) {
            case (?context) { ?context.category };
            case null { null };
        }
    };

    // Get category by ID from common categories
    public func findCategoryById(id: Text) : ?DistributionCategory {
        let categories = getCommonCategories();
        Array.find<DistributionCategory>(categories, func(c) = c.id == id)
    };

    // Create launchpad-linked distribution config
    public func createLaunchpadDistributionConfig(
        baseConfig: DistributionConfig,
        launchpadId: Principal,
        category: DistributionCategory,
        projectMetadata: ProjectMetadata,
        batchId: ?Text
    ) : DistributionConfig {
        {
            baseConfig with
            campaignType = #LaunchpadDistribution;
            launchpadContext = ?{
                launchpadId = launchpadId;
                category = category;
                projectMetadata = projectMetadata;
                batchId = batchId;
            };
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