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
        categoryId: ?Nat;                 // Reference to primary category (from categories array)
        projectMetadata: ProjectMetadata; // Project info for display
        batchId: ?Text;                   // For grouping multiple distributions from same launchpad
    };

    // ========== UNIFIED CATEGORY SYSTEM ==========
    // Category Definition (Source of Truth)
    // Used by BOTH Launchpad and Frontend Distribution
    public type DistributionCategory = {
        // Identity
        id: Nat;                              // PRIMARY: Dynamic ID (1, 2, 3...)
        name: Text;                           // Display name (e.g. "Seed Sale", "Team")
        description: ?Text;                   // Detailed description
        order: ?Nat;                          // Display order for UI

        // Category Behavior
        mode: CategoryMode;                   // Predefined (has recipients) or Open (self-register)

        // Default Allocation Settings (templates for CategoryAllocation)
        defaultVestingSchedule: VestingSchedule;
        defaultVestingStart: Time.Time;
        defaultPassportScore: Nat;            // 0 = disabled, 1-100 = required score
        defaultPassportProvider: Text;        // "ICTO", "Gitcoin", "Civic", etc.

        // Limits
        maxParticipants: ?Nat;                // Maximum users allowed in this category
        allocationPerUser: ?Nat;              // Fixed allocation per user (for Open mode)
    };

    // Category Mode
    public type CategoryMode = {
        #Predefined;  // Has predefined recipients via multiCategoryRecipients
        #Open;        // Users self-register into this category
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

    // Multi-category recipient for unified distributions
    public type MultiCategoryRecipient = {
        address: Principal;
        categories: [CategoryAllocation];   // Multiple categories with different vesting
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

        // ========== MULTI-CATEGORY SUPPORT (V2.0) ==========
        // Category Definitions (Source of Truth) - NEW!
        // Defines available categories with their rules and defaults
        // REQUIRED for both Predefined and Open modes
        categories: ?[DistributionCategory];

        // Optional multi-category recipients (Instances)
        // Predefined mode: Contains recipients with CategoryAllocations
        // Open mode: Empty, users register later
        // If null: Use legacy mode (auto-convert to default category)
        multiCategoryRecipients: ?[MultiCategoryRecipient];

        // ========== SPRINT 2: RATE LIMITING ==========
        rateLimitConfig: ?RateLimitConfig;

        // ========== SPRINT 3: MERKLE TREE ==========
        // Legacy mode (default): usingMerkleSystem = false or null
        // Merkle mode: usingMerkleSystem = true + merkleConfig
        usingMerkleSystem: ?Bool;  // ?null = default false (legacy), ?true = enable Merkle
        merkleConfig: ?MerkleConfig;
    };

    // Sprint 2: Rate Limiting Configuration
    public type RateLimitConfig = {
        enabled: Bool;
        maxClaimsPerWindow: Nat;     // e.g., 1 claim
        windowDurationNs: Nat;        // e.g., 86400000000000 (24 hours)
        enforcementLevel: RateLimitEnforcement;
    };

    public type RateLimitEnforcement = {
        #Warning;  // Log only, don't block
        #Soft;     // Delay next claim
        #Hard;     // Block claim entirely
    };

    // Sprint 2: Claim Event for rate limit tracking
    public type ClaimEvent = {
        timestamp: Time.Time;
        categoryId: Nat;
        amount: Nat;
    };

    // Sprint 2: Pagination types for large queries
    public type PaginationConfig = {
        page: Nat;       // 0-indexed
        pageSize: Nat;   // Max 100
    };

    public type PaginatedResponse<T> = {
        data: [T];
        page: Nat;
        pageSize: Nat;
        totalPages: Nat;
        totalItems: Nat;
    };

    // Sprint 3: Merkle Tree types for scalable recipient storage
    public type MerkleProof = {
        leaf: Blob;        // Hash of (address, amount, categoryId)
        siblings: [Blob];  // Sibling hashes for verification path
        root: Blob;        // Merkle root
    };

    public type MerkleConfig = {
        enabled: Bool;
        roots: [(Nat, Blob)]; // categoryId -> merkle root
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
        #ICTOPassportScore: Nat;
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

    // ================ UNIFIED DISTRIBUTION TYPES ================
    // Single unified contract with multiple categories organized by ID

    // Individual category distribution within unified contract
    public type CategoryDistribution = {
        categoryId: Nat;                    // Numeric ID (1=participants, 2=team, 3=advisors, etc.)
        categoryInfo: DistributionCategory; // Category metadata
        recipients: [Recipient];            // Recipients for this category (legacy - will be merged)
        totalAmount: Nat;                   // Total tokens for this category
        vestingSchedule: VestingSchedule;   // Vesting schedule for this category
    };

    // Multi-category distribution configuration for unified contract
    public type MultiCategoryDistributionConfig = {
        // Basic Information
        title: Text;
        description: Text;
        isPublic: Bool;
        campaignType: CampaignType;

        // Launchpad Integration
        launchpadContext: ?LaunchpadContext;

        // Token Configuration
        tokenInfo: TokenInfo;
        totalAmount: Nat;

        // ========== MULTI-CATEGORY SUPPORT (V2.0) ==========
        // Category Definitions (Source of Truth)
        categories: ?[DistributionCategory];

        // Multi-category recipients with different vesting schedules
        multiCategoryRecipients: [MultiCategoryRecipient];

        // Eligibility & Permissions
        eligibilityType: EligibilityType;
        recipientMode: RecipientMode;
        maxRecipients: ?Nat;

        // Timing
        distributionStart: Time.Time;
        distributionEnd: ?Time.Time;

        // Fees & Permissions
        feeStructure: FeeStructure;
        allowCancel: Bool;
        allowModification: Bool;

        // Owner & Governance
        owner: Principal;
        governance: ?Principal;
        multiSigGovernance: ?MultiSigGovernance;
        externalCheckers: ?[(Text, Principal)];
    };

    // Unified distribution request for single contract deployment
    public type UnifiedDistributionRequest = {
        launchpadId: Principal;
        projectMetadata: ProjectMetadata;
        batchId: Text;
        tokenInfo: TokenInfo;
        categories: [CategoryDistribution]; // Array of categories with ID-based organization
        totalAmount: Nat;                   // Total tokens across all categories
        distributionStart: Time.Time;       // When distribution starts
    };

    public type UnifiedDistributionResult = {
        batchId: Text;
        launchpadId: Principal;
        unifiedCanisterId: Principal;       // Single canister ID for all categories
        categories: [CategoryDeploymentResult];
        totalAmount: Nat;
        successCount: Nat;
        failureCount: Nat;
    };

    public type CategoryDeploymentResult = {
        categoryId: Nat;
        categoryInfo: DistributionCategory;
        result: {
            #Ok: Text;      // Category successfully deployed in unified contract
            #Err: Text;      // Error message for this category
        };
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
        #Failed;
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

    // ================ MULTI-CATEGORY PARTICIPANT TYPES ================
    // Support for participants with multiple allocations and vesting schedules

    public type CategoryAllocation = {
        categoryId: Nat;                    // Category identifier (1=sale, 2=team, etc.)
        categoryName: Text;                 // Category display name
        amount: Nat;                        // Total allocation for this category
        claimedAmount: Nat;                 // Amount already claimed from this category
        vestingSchedule: VestingSchedule;   // Category-specific vesting schedule
        vestingStart: Time.Time;            // Category-specific vesting start time

        // ✨ NEW: Per-Category Passport Verification (Sprint 1)
        passportScore: Nat;                 // 0 = disabled, 1-100 = minimum score required
        passportProvider: Text;             // "ICTO", "Gitcoin", "Civic", etc.

        note: ?Text;                        // Category-specific note
    };

    // Legacy single-category participant for backward compatibility
    public type LegacyParticipant = {
        principal: Principal;
        registeredAt: Time.Time;
        eligibleAmount: Nat;
        claimedAmount: Nat;
        lastClaimTime: ?Time.Time;
        status: ParticipantStatus;
        vestingStart: ?Time.Time;
        note: ?Text; // From Recipient.note
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

    // Multi-category participant for future implementation
    public type MultiCategoryParticipant = {
        principal: Principal;
        registeredAt: Time.Time;
        categories: [CategoryAllocation];   // Multi-category allocations
        totalEligible: Nat;                 // Sum of all category amounts
        totalClaimed: Nat;                  // Sum of all claimed amounts
        lastClaimTime: ?Time.Time;
        status: ParticipantStatus;
        note: ?Text;                        // General participant note
    };

    public type ClaimRecord = {
        participant: Principal;
        amount: Nat;
        timestamp: Time.Time;
        blockHeight: ?Nat;
        transactionId: ?Text;
    };

    public type DistributionStats = {
        // Statistics
        totalParticipants: Nat;
        totalDistributed: Nat;
        totalClaimed: Nat;
        remainingAmount: Nat;
        completionPercentage: Float;
        isActive: Bool;
        
        // Config info for frontend optimization (avoid multiple API calls)
        title: Text;
        description: Text;
        tokenInfo: TokenInfo;
        campaignType: CampaignType;
        totalAmount: Nat;
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

    // Distribution Category helpers - DEPRECATED
    // Categories are now defined per-distribution in DistributionConfig.categories
    // This is kept for backward compatibility only
    public func getCommonCategories() : [DistributionCategory] {
        // Return empty array - categories should be defined in config
        []
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
            case null { category.defaultVestingSchedule }; // Use category's default vesting
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

    // Get primary distribution category from config
    public func getPrimaryCategory(config: DistributionConfig) : ?DistributionCategory {
        switch (config.categories) {
            case (?cats) {
                // Return first category or category matching launchpadContext.categoryId
                switch (config.launchpadContext) {
                    case (?context) {
                        switch (context.categoryId) {
                            case (?catId) {
                                // Find category by ID
                                Array.find<DistributionCategory>(cats, func(c) { c.id == catId })
                            };
                            case null {
                                // Return first category if no specific ID
                                if (cats.size() > 0) { ?cats[0] } else { null }
                            };
                        }
                    };
                    case null {
                        // Return first category if no launchpad context
                        if (cats.size() > 0) { ?cats[0] } else { null }
                    };
                }
            };
            case null { null };
        }
    };

    // Get category by ID from categories array
    public func findCategoryById(categories: [DistributionCategory], id: Nat) : ?DistributionCategory {
        Array.find<DistributionCategory>(categories, func(c) { c.id == id })
    };

    // Create launchpad-linked distribution config
    public func createLaunchpadDistributionConfig(
        baseConfig: DistributionConfig,
        launchpadId: Principal,
        categoryId: ?Nat,
        projectMetadata: ProjectMetadata,
        batchId: ?Text
    ) : DistributionConfig {
        {
            baseConfig with
            campaignType = #LaunchpadDistribution;
            launchpadContext = ?{
                launchpadId = launchpadId;
                categoryId = categoryId;
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

    // ========== BATCH RESULT TYPES FOR FLEXIBLE REGISTER/CLAIM ==========

    /// Batch result for comprehensive category processing
    public type BatchResult = {
        success: Bool;
        message: Text;
        categories: [CategoryResult];
    };

    /// Individual category result for batch operations
    public type CategoryResult = {
        categoryId: Nat;
        categoryName: Text;
        success: Bool;
        isValid: Bool;
        allocation: Nat;
        claimedAmount: ?Nat;
        isRegistered: Bool;
        errorMessage: ?Text;
    };

    /// Batch registration result
    public type BatchRegisterResult = BatchResult;

    /// Batch claim result with total amount claimed
    public type BatchClaimResult = {
        success: Bool;
        message: Text;
        categories: [CategoryResult];
        totalAmount: Nat;
    };

}