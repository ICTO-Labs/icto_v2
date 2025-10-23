import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Hash "mo:base/Hash";
import Trie "mo:base/Trie";

module LaunchpadTypes {
    public type Result<T, E> = Result.Result<T, E>;

    // ================ CORE UTILITY TYPES ================

    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };

    public type TokenInfo = {
        canisterId: Principal;
        symbol: Text;
        name: Text;
        decimals: Nat8;
        totalSupply: Nat;
        transferFee: Nat;
        logo: ?Text;
        description: ?Text;
        website: ?Text;
        standard: Text; // "ICRC-1", "ICRC-2", etc.
    };

    // ================ LAUNCHPAD-SPECIFIC TOKEN TYPE ================
    // Separate type for launchpad sale token (deployed AFTER soft cap)
    public type LaunchpadSaleToken = {
        canisterId: ?Principal;      // Optional - null until deployed after soft cap
        symbol: Text;
        name: Text;
        decimals: Nat8;
        totalSupply: Nat;
        transferFee: Nat;
        logo: ?Text;
        description: ?Text;
        website: ?Text;
        standard: Text; // "ICRC-1", "ICRC-2", etc.
    };

    // ================ PROJECT & LAUNCHPAD CONFIGURATION ================

    public type ProjectInfo = {
        name: Text;
        description: Text;
        logo: ?Text;
        banner: ?Text;
        website: ?Text;
        whitepaper: ?Text;
        documentation: ?Text;
        telegram: ?Text;
        twitter: ?Text;
        discord: ?Text;
        github: ?Text;
        isAudited: Bool;
        auditReport: ?Text;
        isKYCed: Bool;
        kycProvider: ?Text;
        tags: [Text]; // ["DeFi", "Gaming", "NFT", etc.]
        category: ProjectCategory;
        metadata: ?[(Text, Text)]; // Additional key-value metadata
    };

    public type ProjectCategory = {
        #DeFi;
        #Gaming; 
        #NFT;
        #Infrastructure;
        #DAO;
        #Metaverse;
        #AI;
        #SocialFi;
        #Other: Text;
    };

    // ================ TIMELINE & PHASES ================

    public type Timeline = {
        createdAt: Time.Time;
        whitelistStart: ?Time.Time;
        whitelistEnd: ?Time.Time; 
        saleStart: Time.Time;
        saleEnd: Time.Time;
        claimStart: Time.Time;
        vestingStart: ?Time.Time;
        listingTime: ?Time.Time;
        daoActivation: ?Time.Time;
    };

    // ================ SALE CONFIGURATION ================

    public type SaleType = {
        #FairLaunch;      // Public sale open to all
        #PrivateSale;     // Whitelist required
        #IDO;             // Initial DEX Offering with special mechanics
        #Auction;         // Dutch auction mechanism
        #Lottery;         // Lottery-based allocation
    };

    public type AllocationMethod = {
        #FirstComeFirstServe;
        #ProRata;         // Proportional allocation if oversubscribed
        #Lottery;         // Random selection
        #Weighted;        // Based on user scores/tiers
    };

    public type WhitelistMode = {
        #Closed;          // Only pre-approved addresses
        #OpenRegistration; // Users can register for whitelist approval
    };

    public type WhitelistEntry = {
        principal: Principal;
        allocation: ?Nat;  // Optional specific allocation for this address
        tier: ?Nat8;       // Optional tier level
        registeredAt: ?Time.Time; // When they registered (for open registration mode)
        approvedAt: ?Time.Time;   // When they were approved
    };

    public type SaleParams = {
        saleType: SaleType;
        allocationMethod: AllocationMethod;
        totalSaleAmount: Nat;         // Total tokens for sale
        softCap: Nat;                 // Minimum raise goal (in purchase token)
        hardCap: Nat;                 // Maximum raise goal (in purchase token)
        tokenPrice: Nat;              // Price per token in e8s of purchase token
        minContribution: Nat;         // Minimum individual contribution
        maxContribution: ?Nat;        // Maximum individual contribution (None = no limit)
        maxParticipants: ?Nat;        // Maximum number of participants
        requiresWhitelist: Bool;      // Whether whitelist is required
        requiresKYC: Bool;           // Whether KYC is required
        minICTOPassportScore: Nat;         // Minimum ICTO Passport score (0 = no requirement)
        restrictedRegions: [Text];    // ISO country codes
        whitelistMode: WhitelistMode; // Whitelist registration mode
        whitelistEntries: [WhitelistEntry]; // Whitelist entries
    };

    // ================ DEX INTEGRATION & LIQUIDITY ================

    public type DEXConfig = {
        enabled: Bool;
        platform: Text;                   // "ICSwap", "Sonic", "ICPSwap", etc.
        listingPrice: Nat;               // Price in e8s of purchase token
        totalLiquidityToken: Nat;        // Total tokens for liquidity
        initialLiquidityToken: Nat;      // Initial tokens for liquidity
        initialLiquidityPurchase: Nat;   // Initial purchase tokens for liquidity
        liquidityLockDays: Nat;          // Days to lock LP tokens
        autoList: Bool;                  // Automatically list after successful sale
        slippageTolerance: Nat8;         // Slippage tolerance (0-100)
        lpTokenRecipient: ?Principal;    // LP token recipient (matches frontend)
        fees: {
            listingFee: Nat;             // Platform listing fee
            transactionFee: Nat8;        // Transaction fee percentage
        };
    };

    public type MultiDEXConfig = {
        platforms: [DEXPlatform];
        totalLiquidityAllocation: Nat;   // Total allocation for all DEXs
        distributionStrategy: DEXDistributionStrategy;
    };

    public type DEXPlatform = {
        id: Text;                        // "icswap", "sonic", etc.
        name: Text;
        description: ?Text;              // Platform description (matches frontend)
        logo: ?Text;                     // Platform logo URL (matches frontend)
        enabled: Bool;
        allocationPercentage: Nat8;      // Percentage of total liquidity (0-100)
        calculatedTokenLiquidity: Nat;   // Calculated token amount
        calculatedPurchaseLiquidity: Nat; // Calculated purchase token amount
        fees: {
            listing: Nat;
            transaction: Nat8;
        };
    };

    public type DEXDistributionStrategy = {
        #Equal;                          // Equal distribution across enabled DEXs
        #Weighted;                       // Weighted by allocation percentage
        #Priority;                       // Priority-based allocation
    };

    // ================ RAISED FUNDS ALLOCATION ================

    // Updated to support dynamic allocation structure from frontend
    public type RaisedFundsAllocation = {
        allocations: [FundAllocation];   // Dynamic allocation system
    };

    public type FundAllocation = {
        id: Text;                        // Unique identifier ("team", "development", etc.)
        name: Text;                      // Display name ("Team Allocation", "Development Fund", etc.)
        amount: Nat;                     // Calculated amount in e8s
        percentage: Nat8;                // Percentage of total raised funds (0-100)
        recipients: [FundRecipient];     // List of recipients for this allocation
    };

    public type FundRecipient = {
        principal: Principal;
        percentage: Nat8;                // Percentage of the allocation (0-100)
        name: ?Text;                     // Optional name/description for recipient
        vestingEnabled: Bool;            // Whether vesting is enabled
        vestingSchedule: ?VestingSchedule; // Optional vesting for fund recipients
        description: ?Text;              // Description of recipient role
    };

    // Legacy compatibility - keeping old structure for backward compatibility
    public type LegacyRaisedFundsAllocation = {
        teamAllocation: Nat8;            // Percentage for team (0-100)
        developmentFund: Nat8;           // Percentage for development (0-100)
        marketingFund: Nat8;             // Percentage for marketing (0-100)
        liquidityFund: Nat8;             // Percentage for DEX liquidity (0-100)
        reserveFund: Nat8;               // Percentage for reserve/treasury (0-100)
        teamRecipients: [FundRecipient];
        developmentRecipients: [FundRecipient];
        marketingRecipients: [FundRecipient];
        customAllocations: [CustomFundAllocation];
    };

    public type CustomFundAllocation = {
        name: Text;                      // "Legal", "Audit", "Compliance", etc.
        percentage: Nat8;                // Percentage of total raised funds (0-100)
        recipients: [FundRecipient];
        vestingSchedule: ?VestingSchedule;
        description: ?Text;
    };

    // ================ TOKEN DISTRIBUTION & VESTING ================

    public type VestingSchedule = {
        cliffDays: Nat;               // Cliff period in days (matches frontend)
        durationDays: Nat;            // Total vesting duration in days (matches frontend)
        releaseFrequency: VestingFrequency;  // How often tokens are released
        immediateRelease: Nat8;       // Percentage unlocked immediately (0-100)
    };

    public type VestingFrequency = {
        #Daily;           // Daily unlocks
        #Weekly;          // Weekly unlocks
        #Monthly;         // Monthly unlocks
        #Quarterly;       // Quarterly unlocks
        #Yearly;          // Yearly unlocks
        #Immediate;       // All at once after cliff
        #Linear;          // Continuous linear vesting
        #Custom: Nat;     // Custom period in seconds
    };

    // ================ FIXED 4-CATEGORY DISTRIBUTION (V2) ================
    // New structure that matches frontend fixed allocation design
    
    public type TokenDistribution = {
        sale: SaleAllocation;
        team: TeamAllocation;
        liquidityPool: LiquidityPoolAllocation;
        others: [OtherAllocation];
    };

    public type SaleAllocation = {
        name: Text;                   // "Sale"
        percentage: Float;            // Percentage of total supply
        totalAmount: Text;            // String representation for large numbers
        vestingSchedule: ?VestingSchedule;
        description: ?Text;
    };

    public type TeamAllocation = {
        name: Text;                   // "Team" 
        percentage: Float;            // Percentage of total supply
        totalAmount: Text;            // String representation for large numbers
        vestingSchedule: ?VestingSchedule;
        recipients: [TeamRecipient];
        description: ?Text;
    };

    public type LiquidityPoolAllocation = {
        name: Text;                   // "Liquidity Pool"
        percentage: Float;            // Percentage of total supply (auto-calculated)
        totalAmount: Text;            // String representation for large numbers
        autoCalculated: Bool;         // Always true - calculated from DEX config
        description: ?Text;
        // NO vestingSchedule - LP tokens need to be available immediately
    };

    public type OtherAllocation = {
        id: Text;                     // Unique identifier
        name: Text;                   // Category name (Marketing, Advisors, etc.)
        percentage: Float;            // Percentage of total supply
        totalAmount: Text;            // String representation for large numbers
        description: ?Text;
        recipients: [OtherRecipient];
        vestingSchedule: ?VestingSchedule;
    };

    public type TeamRecipient = {
        principal: Text;              // Principal ID as text
        percentage: Float;            // Percentage within team allocation
        amount: ?Text;               // Optional amount override
        name: ?Text;                 // Optional name/description
        description: ?Text;
        vestingOverride: ?VestingSchedule; // Override team-level vesting
    };

    public type OtherRecipient = {
        principal: Text;              // Principal ID as text  
        percentage: Float;            // Percentage within category allocation
        amount: ?Text;               // Optional amount override
        name: ?Text;                 // Optional name/description
        description: ?Text;
        vestingOverride: ?VestingSchedule; // Override category-level vesting
    };

    // ================ LEGACY DISTRIBUTION (V1) ================
    // Kept for backward compatibility
    
    public type DistributionCategory = {
        name: Text;                   // "Public Sale", "Private Sale", "Team", "Liquidity", etc.
        percentage: Nat8;             // Percentage of total supply (0-100)
        totalAmount: Nat;             // Calculated from percentage * totalSupply
        vestingSchedule: ?VestingSchedule; // None = immediate unlock
        recipients: RecipientConfig;  // How recipients are determined
        description: ?Text;           // Description of this allocation
    };

    public type UnallocatedManagement = {
        #Multisig: ?Principal;      // Unallocated managed by multisig (optional canister ID)
        #DAO: ?Principal;           // Unallocated managed by DAO (optional canister ID)
    };

    public type RecipientConfig = {
        #SaleParticipants;           // Distributed to sale participants
        #FixedList: [Recipient];     // Fixed list of recipients
        #TeamAllocation;             // Team wallet allocation
        #TreasuryReserve;           // DAO/Project treasury
        #LiquidityPool;             // DEX liquidity provision
        #Airdrop;                   // Airdrop distribution
        #Staking;                   // Staking rewards
        #Marketing;                 // Marketing and partnerships
        #Advisors;                  // Advisor allocations
        #Unallocated: UnallocatedManagement; // Unallocated tokens (DAO or Multisig)
    };

    public type Recipient = {
        address: Principal;
        amount: Nat;
        description: ?Text;
        vestingOverride: ?VestingSchedule; // Override default vesting for this recipient
    };

    // ================ AFFILIATE & REFERRAL SYSTEM ================

    public type AffiliateConfig = {
        enabled: Bool;
        commissionRate: Nat8;         // Percentage (0-100)
        maxTiers: Nat8;              // Maximum referral tiers (1-5)
        tierRates: [Nat8];           // Commission rates per tier
        minPurchaseForCommission: Nat; // Minimum purchase to earn commission
        paymentToken: Principal;      // Token used for commission payments
        vestingSchedule: ?VestingSchedule; // Commission vesting (None = immediate)
    };

    public type AffiliateStats = {
        referrer: Principal;
        totalVolume: Nat;
        totalCommission: Nat;
        referralCount: Nat;
        tierLevel: Nat8;
        isActive: Bool;
    };

    // ================ GOVERNANCE INTEGRATION ================

    public type GovernanceConfig = {
        enabled: Bool;
        daoCanisterId: ?Principal;    // Set after DAO deployment
        votingToken: Principal;       // Token used for governance
        proposalThreshold: Nat;       // Minimum tokens to create proposal
        quorumPercentage: Nat8;      // Required quorum (0-100)
        votingPeriod: Time.Time;     // Voting period in seconds
        timelockDuration: Time.Time;  // Execution delay after approval
        emergencyContacts: [Principal]; // Emergency pause/unpause contacts
        initialGovernors: [Principal]; // Initial governance participants
        autoActivateDAO: Bool;        // Automatically activate DAO after successful sale
    };

    // ================ PARTICIPANT & TRANSACTION TRACKING ================

    public type Participant = {
        principal: Principal;
        totalContribution: Nat;       // Total amount contributed (in purchase token e8s)
        allocationAmount: Nat;        // Allocated tokens (if different from contribution)
        commitCount: Nat;            // Number of separate contributions
        firstContribution: Time.Time;
        lastContribution: Time.Time;
        whitelistTier: ?Nat8;        // Whitelist tier (if applicable)
        kycStatus: KYCStatus;
        affiliateCode: ?Text;        // Referral code used
        claimedAmount: Nat;          // Amount already claimed
        refundedAmount: Nat;         // Amount refunded (if any)
        vestingContract: ?Principal;  // Vesting contract if applicable
        isBlacklisted: Bool;         // Emergency blacklist
    };

    public type KYCStatus = {
        #NotRequired;
        #Pending;
        #Approved;
        #Rejected;
        #Expired;
    };

    public type Transaction = {
        id: Text;
        participant: Principal;
        txType: TransactionType;
        amount: Nat;
        token: Principal;
        timestamp: Time.Time;
        blockIndex: ?Nat;            // ICRC transaction block index
        fee: Nat;                    // Transaction fee paid
        status: TransactionStatus;
        affiliateCode: ?Text;        // Associated referral code
        notes: ?Text;                // Additional notes or error messages
    };

    public type TransactionType = {
        #Purchase;
        #Refund;
        #Claim;
        #AffiliateReward;
        #Fee;
    };

    public type TransactionStatus = {
        #Pending;
        #Confirmed;
        #Failed: Text;               // Error message
        #Reversed;                   // Transaction was reversed
    };

    // ================ LAUNCHPAD STATUS & LIFECYCLE ================

    public type LaunchpadStatus = {
        #Setup;          // Initial configuration phase
        #Upcoming;       // Configured but not started
        #WhitelistOpen;  // Whitelist registration open
        #SaleActive;     // Sale is active
        #SaleEnded;      // Sale ended, processing results
        #Successful;     // Soft cap reached, processing distribution
        #Failed;         // Soft cap not reached, processing refunds
        #Distributing;   // Distributing tokens/setting up vesting
        #Claiming;       // Claims are active
        #Completed;      // All processes completed
        #Cancelled;      // Cancelled by admin/creator
        #Emergency;      // Emergency pause state
    };

    public type ProcessingState = {
        #Idle;
        #Processing: {
            stage: ProcessingStage;
            progress: Nat8;          // 0-100
            processedCount: Nat;
            totalCount: Nat;
            errorCount: Nat;
            lastError: ?Text;
        };
        #Completed;
        #Failed: Text;
    };

    public type ProcessingStage = {
        #TokenDeployment;
        #VestingSetup;
        #Distribution;
        #DAODeployment;
        #Refunding;
        #FinalCleanup;
    };

    // ================ MAIN LAUNCHPAD CONFIGURATION ================

    public type LaunchpadConfig = {
        // Project Information
        projectInfo: ProjectInfo;
        
        // Token Configuration
        saleToken: LaunchpadSaleToken; // Token being sold (deployed AFTER soft cap)
        purchaseToken: TokenInfo;      // Token used for purchase (ICP, ckBTC, etc.) - must exist
        
        // Sale Configuration  
        saleParams: SaleParams;
        
        // Timeline
        timeline: Timeline;
        
        // Token Distribution (V2 - Fixed 4-Category Structure)
        tokenDistribution: ?TokenDistribution;  // New fixed structure
        
        // Legacy Distribution (V1 - Dynamic Array) - Backward compatibility
        distribution: [DistributionCategory];
        
        // DEX Integration
        dexConfig: DEXConfig;         // DEX listing configuration
        multiDexConfig: ?MultiDEXConfig; // Optional multi-DEX support
        
        // Raised Funds Management
        raisedFundsAllocation: RaisedFundsAllocation;
        
        // Advanced Features
        affiliateConfig: AffiliateConfig;
        governanceConfig: GovernanceConfig;
        
        // Security & Compliance
        whitelist: [Principal];       // Pre-approved participants
        blacklist: [Principal];       // Blocked participants
        adminList: [Principal];       // Launchpad administrators
        
        // Fee Structure
        platformFeeRate: Nat8;        // Platform fee percentage (0-100)
        successFeeRate: Nat8;         // Additional fee on successful launch (0-100)
        
        // Emergency Controls
        emergencyContacts: [Principal]; // Emergency pause/cancel contacts
        pausable: Bool;               // Whether launchpad can be paused
        cancellable: Bool;            // Whether launchpad can be cancelled
    };

    // ================ LAUNCHPAD CONTRACT STATE ================

    public type LaunchpadDetail = {
        id: Text;                     // Unique launchpad identifier
        canisterId: Principal;        // Launchpad contract principal
        creator: Principal;           // Launchpad creator
        
        // Configuration
        config: LaunchpadConfig;
        
        // Current State
        status: LaunchpadStatus;
        processingState: ProcessingState;
        
        // Statistics
        stats: LaunchpadStats;
        
        // Deployment Results
        deployedContracts: DeployedContracts;
        
        // Timestamps
        createdAt: Time.Time;
        updatedAt: Time.Time;
        finalizedAt: ?Time.Time;
    };

    public type LaunchpadStats = {
        // Financial Statistics
        totalRaised: Nat;             // Total raised in purchase token e8s
        totalAllocated: Nat;          // Total tokens allocated
        participantCount: Nat;        // Number of unique participants
        transactionCount: Nat;        // Total number of transactions
        
        // Progress Metrics
        softCapProgress: Nat8;        // Progress towards soft cap (0-100)
        hardCapProgress: Nat8;        // Progress towards hard cap (0-100)
        allocationProgress: Nat8;     // Percentage of tokens allocated (0-100)
        
        // Affiliate Statistics
        affiliateVolume: Nat;         // Volume from affiliate referrals
        affiliateCount: Nat;          // Number of active affiliates
        totalCommissions: Nat;        // Total affiliate commissions
        
        // Average Metrics
        averageContribution: Nat;     // Average contribution per participant
        medianContribution: Nat;      // Median contribution
        
        // Time Metrics
        timeRemaining: ?Time.Time;    // Time remaining in current phase
        estimatedCompletion: ?Time.Time; // Estimated completion time
    };

    public type DeployedContracts = {
        tokenCanister: ?Principal;    // Deployed token canister
        vestingContracts: [(Text, Principal)]; // Name -> Principal mapping
        daoCanister: ?Principal;      // DAO governance canister
        liquidityPool: ?Principal;    // DEX liquidity pool
        stakingContract: ?Principal;  // Staking rewards contract
    };

    // ================ FACTORY & DEPLOYMENT TYPES ================

    public type CreateLaunchpadRequest = {
        config: LaunchpadConfig;
        initialDeposit: ?Nat;        // Optional initial deposit to cover fees
    };

    public type CreateLaunchpadResult = {
        launchpadId: Text;
        canisterId: Principal;
        estimatedCosts: LaunchpadCosts;
    };

    public type LaunchpadCosts = {
        deploymentFee: Nat;          // One-time deployment fee
        cycleCost: Nat;              // Estimated cycle cost
        platformFee: Nat;            // Platform fee (if applicable)
        totalCost: Nat;              // Total upfront cost
    };

    // ================ QUERY & FILTER TYPES ================

    public type LaunchpadFilter = {
        status: ?LaunchpadStatus;
        category: ?ProjectCategory;
        saleType: ?SaleType;
        creator: ?Principal;
        minRaised: ?Nat;
        maxRaised: ?Nat;
        tags: ?[Text];
        featured: ?Bool;
        isActive: ?Bool;
    };

    public type LaunchpadSort = {
        #CreatedAt: SortDirection;
        #SaleStart: SortDirection;
        #TotalRaised: SortDirection;
        #ParticipantCount: SortDirection;
        #HardCapProgress: SortDirection;
    };

    public type SortDirection = {
        #Asc;
        #Desc;
    };

    public type PaginationParams = {
        offset: Nat;
        limit: Nat;                  // Max 100
        sort: ?LaunchpadSort;
    };

    // ================ ERROR TYPES ================

    public type LaunchpadError = {
        #NotFound;
        #Unauthorized;
        #InvalidConfig: Text;
        #InsufficientFunds;
        #SaleNotActive;
        #SaleClosed;
        #HardCapReached;
        #ContributionTooSmall;
        #ContributionTooLarge;
        #NotWhitelisted;
        #KYCRequired;
        #RegionRestricted;
        #ProcessingInProgress;
        #AlreadyProcessed;
        #VestingNotActive;
        #InsufficientAllocation;
        #TransactionFailed: Text;
        #SystemError: Text;
    };

    // ================ UTILITY FUNCTIONS ================

    public func textKey(t: Text) : Trie.Key<Text> {
        { key = t; hash = Text.hash(t) }
    };

    public func principalKey(p: Principal) : Trie.Key<Principal> {
        { key = p; hash = Principal.hash(p) }
    };

    public func statusToText(status: LaunchpadStatus) : Text {
        switch (status) {
            case (#Setup) "setup";
            case (#Upcoming) "upcoming";
            case (#WhitelistOpen) "whitelist_open";
            case (#SaleActive) "sale_active";
            case (#SaleEnded) "sale_ended";
            case (#Successful) "successful";
            case (#Failed) "failed";
            case (#Distributing) "distributing";
            case (#Claiming) "claiming";
            case (#Completed) "completed";
            case (#Cancelled) "cancelled";
            case (#Emergency) "emergency";
        };
    };

    public func saleTypeToText(saleType: SaleType) : Text {
        switch (saleType) {
            case (#FairLaunch) "fairlaunch";
            case (#PrivateSale) "private";
            case (#IDO) "ido";
            case (#Auction) "auction";
            case (#Lottery) "lottery";
        };
    };

    // ================ SECURITY & AUDIT TYPES ================

    // Admin action tracking for audit trail
    public type AdminAction = {
        action: Text;
        caller: Principal;
        timestamp: Time.Time;
        parameters: Text;
        success: Bool;
        reason: ?Text;
    };

    // Security event logging
    public type SecurityEvent = {
        eventType: SecurityEventType;
        principal: Principal;
        timestamp: Time.Time;
        details: Text;
        severity: SecuritySeverity;
    };

    public type SecurityEventType = {
        #UnauthorizedAccess;
        #RateLimitViolation;
        #SuspiciousActivity;
        #EmergencyAction;
        #ConfigurationChange;
        #LargeTransaction;
    };

    public type SecuritySeverity = {
        #Low;
        #Medium;
        #High;
        #Critical;
    };

    public type LaunchpadInitArgs = {
        id: Text;
        config: LaunchpadConfig;
        creator: Principal;
        createdAt: Time.Time;
    };
    // ================ CONSTANTS ================

    public let MAX_PARTICIPANTS_PER_LAUNCHPAD : Nat = 50000;
    public let MAX_DISTRIBUTION_CATEGORIES : Nat = 20;
    public let MAX_WHITELIST_SIZE : Nat = 100000;
    public let MAX_AFFILIATE_TIERS : Nat8 = 5;
    public let DEFAULT_PLATFORM_FEE_RATE : Nat8 = 2; // 2%
    public let DEFAULT_SUCCESS_FEE_RATE : Nat8 = 1; // 1%
    public let MIN_SALE_DURATION : Time.Time = 3600; // 1 hour
    public let MAX_SALE_DURATION : Time.Time = 7776000; // 90 days
    public let MIN_SOFT_CAP_PERCENTAGE : Nat8 = 30; // 30% of hard cap
    public let E8S : Nat = 100_000_000;
}