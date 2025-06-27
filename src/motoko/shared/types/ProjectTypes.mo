// ⬇️ Ported from V1: icto_app/canisters/launchpad/types/Common.mo
// Enhanced project types for ICTO V2 with comprehensive launchpad information
// Refactored for modular pipeline compatibility (V2)

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Common "Common";
import Float "mo:base/Float";

module {
    
    // ================ ACCOUNT TYPES ================
    public type Account = {
        owner: Principal;
        subaccount: ?Blob;
    };
    
    // ================ TOKEN INFORMATION ================
    public type TokenInfo = {
        name: Text;
        symbol: Text;
        decimals: Nat;
        transferFee: Nat;
        totalSupply: Nat;
        metadata: ?Blob;
        logo: Text;
        canisterId: ?Text; // Will be populated after deployment
    };
    
    // ================ PROJECT INFORMATION ================
    public type ProjectInfo = {
        name: Text;
        description: Text;
        isAudited: Bool;
        isVerified: Bool;
        auditReport: ?Text; // URL to audit report
        links: ?[ProjectLink]; // Social links, website, etc.
        logo: Text;
        banner: ?Text;
        metadata: ?[(Text, Text)];
        category: ProjectCategory;
        tags: [Text];
        teamInfo: TeamInfo;
    };
    
    public type ProjectLink = {
        linkType: LinkType;
        url: Text;
        title: ?Text;
    };
    
    public type LinkType = {
        #Website;
        #Twitter;
        #Telegram;
        #Discord;
        #Github;
        #Medium;
        #Documentation;
        #Whitepaper;
        #Other;
    };
    
    public type ProjectCategory = {
        #DeFi;
        #GameFi;
        #Infrastructure;
        #NFT;
        #SocialFi;
        #Web3;
        #AI;
        #Metaverse;
        #DAO;
        #Other;
    };
    
    public type TeamInfo = {
        teamSize: Nat;
        founder: ?Text;
        coFounders: [Text];
        advisors: [Text];
        description: ?Text;
        experience: ?Text;
    };
    
    // ================ TIMELINE & PHASES ================
    public type Timeline = {
        createdTime: Time.Time;
        startTime: Time.Time; // When launchpad goes LIVE
        endTime: Time.Time; // When sale ends
        claimTime: Time.Time; // When token claim starts
        listingTime: Time.Time; // When token gets listed on DEX
    };
    
    public type LaunchpadPhase = {
        #Created; // Project created, not started
        #Upcoming; // Before startTime
        #Live; // Between startTime and endTime - IMMUTABLE PHASE
        #Ended; // Between endTime and claimTime
        #Claim; // Between claimTime and listingTime
        #Listed; // After listingTime
        #Cancelled; // If project fails or gets cancelled
    };
    
    // ================ LAUNCH PARAMETERS ================
    public type LaunchParams = {
        sellAmount: Nat; // Amount of tokens to sell
        price: Nat; // Price per token in purchase token (e8s)
        softCap: Nat; // Minimum amount to raise (in purchase token e8s)
        hardCap: Nat; // Maximum amount to raise (in purchase token e8s)
        minimumPurchase: Nat; // Minimum purchase per user
        maximumPurchase: Nat; // Maximum purchase per user
        whitelistEnabled: Bool;
        kycRequired: Bool;
        vestingEnabled: Bool;
        affiliateProgram: AffiliateSettings;
    };
    
    public type AffiliateSettings = {
        enabled: Bool;
        percentage: Nat; // Percentage for affiliates (basis points, e.g., 500 = 5%)
        maxReward: ?Nat; // Maximum reward per affiliate
    };
    
    // ================ VESTING CONFIGURATION ================
    public type VestingInfo = {
        cliff: Nat; // Cliff period in seconds
        duration: Nat; // Total vesting duration in seconds
        unlockFrequency: Nat; // 0: immediate, 1: linear, others: periodic unlocks
        tgeUnlock: Nat; // Percentage unlocked at TGE (basis points)
    };
    
    // ================ TOKEN DISTRIBUTION ================
    public type TokenDistribution = {
        // Public sale allocation
        publicSale: DistributionItem;
        
        // Team allocation with vesting
        team: TeamAllocation;
        
        // Liquidity pool allocation
        liquidityPool: LiquidityPoolAllocation;
        
        // Marketing & partnerships
        marketing: DistributionItem;
        
        // Development fund
        development: DistributionItem;
        
        // Advisors allocation
        advisors: DistributionItem;
        
        // Treasury/Reserve
        treasury: DistributionItem;
        
        // Other allocations
        others: [CustomAllocation];
    };
    
    public type DistributionItem = {
        title: Text;
        percentage: Nat; // Percentage of total supply (basis points)
        amount: Nat; // Actual token amount
        vesting: ?VestingInfo;
        description: ?Text;
    };
    
    public type TeamAllocation = {
        title: Text;
        percentage: Nat;
        amount: Nat;
        vesting: VestingInfo; // Team tokens always vested
        recipients: [TeamRecipient];
        lockPeriod: Nat; // Additional lock period in seconds
    };
    
    public type TeamRecipient = {
        address: Text;
        percentage: Nat; // Percentage of team allocation
        role: Text;
        note: ?Text;
    };
    
    public type LiquidityPoolAllocation = {
        title: Text;
        percentage: Nat;
        amount: Nat;
        targetDEX: Text; // Which DEX to provide liquidity
        lockPeriod: Nat; // LP lock period in seconds
        initialPriceRatio: ?Nat; // Initial price ratio for LP
    };
    
    public type CustomAllocation = {
        title: Text;
        description: Text;
        percentage: Nat;
        amount: Nat;
        vesting: ?VestingInfo;
        recipients: [AllocationRecipient];
    };
    
    public type AllocationRecipient = {
        address: Text;
        amount: Nat;
        note: ?Text;
    };
    
    // ================ FINANCIAL SETTINGS ================
    public type FinancialSettings = {
        purchaseToken: TokenInfo; // Token used for purchase (usually ICP)
        saleToken: TokenInfo; // Token being sold
        raisedFundsDistribution: RaisedFundsDistribution;
        feeStructure: FeeStructure;
        refundPolicy: RefundPolicy;
    };
    
    public type RaisedFundsDistribution = {
        // How raised funds will be distributed
        liquidityPercentage: Nat; // Percentage for liquidity pool
        teamPercentage: Nat; // Percentage for team
        developmentPercentage: Nat; // Percentage for development
        marketingPercentage: Nat; // Percentage for marketing
        platformFeePercentage: Nat; // Platform fee
        customDistributions: [CustomFundDistribution];
    };
    
    public type CustomFundDistribution = {
        title: Text;
        percentage: Nat;
        recipient: Text;
        vesting: ?VestingInfo;
        description: ?Text;
    };
    
    public type FeeStructure = {
        platformFee: Nat; // Platform fee percentage (basis points)
        successFee: Nat; // Additional fee if successful
        listingFee: ?Nat; // Fee for DEX listing
        paymentTokenFee: Nat; // Fee for payment processing
    };
    
    public type RefundPolicy = {
        enabled: Bool;
        conditions: [RefundCondition];
        timeline: RefundTimeline;
    };
    
    public type RefundCondition = {
        conditionType: RefundConditionType;
        description: Text;
        autoTrigger: Bool;
    };
    
    public type RefundConditionType = {
        #SoftCapNotMet;
        #TechnicalFailure;
        #TeamDecision;
        #CommunityVote;
        #RegulatoryIssues;
    };
    
    public type RefundTimeline = {
        claimStartTime: Time.Time;
        claimEndTime: Time.Time;
        processingTime: Nat; // Time in seconds to process refunds
    };
    
    // ================ COMPLIANCE & SECURITY ================
    public type ComplianceSettings = {
        kycRequired: Bool;
        kycProvider: ?Text;
        restrictedCountries: [Text];
        minimumAge: ?Nat;
        termsOfService: Text;
        privacyPolicy: Text;
        riskDisclosure: Text;
        accreditedInvestorOnly: Bool;
    };
    
    public type SecuritySettings = {
        multiSigRequired: Bool;
        multiSigThreshold: ?Nat;
        auditRequired: Bool;
        auditProvider: ?Text;
        insuranceRequired: Bool;
        emergencyPause: Bool;
    };
    
    // ================ COMPLETE PROJECT STRUCTURE ================
    public type ProjectDetail = {
        // Basic information
        projectInfo: ProjectInfo;
        
        // Timeline and phases
        timeline: Timeline;
        currentPhase: LaunchpadPhase;
        
        // Launch parameters - IMMUTABLE after LIVE phase
        launchParams: LaunchParams;
        
        // Token distribution - IMMUTABLE after LIVE phase
        tokenDistribution: TokenDistribution;
        
        // Financial settings - IMMUTABLE after LIVE phase  
        financialSettings: FinancialSettings;
        
        // Compliance and security
        compliance: ComplianceSettings;
        security: SecuritySettings;
        
        // System fields
        creator: Principal;
        createdAt: Time.Time;
        updatedAt: Time.Time;
        
        // Deployment tracking
        deployedCanisters: DeployedCanisters;
        
        // Runtime status
        status: ProjectStatus;
    };
    
    public type DeployedCanisters = {
        tokenCanister: ?Text;
        lockCanister: ?Text;
        distributionCanister: ?Text;
        launchpadCanister: ?Text;
        daoCanister: ?Text;
    };
    
    public type ProjectStatus = {
        totalRaised: Nat;
        totalParticipants: Nat;
        tokensDistributed: Nat;
        liquidityAdded: Bool;
        vestingStarted: Bool;
        isCompleted: Bool;
        isCancelled: Bool;
        failureReason: ?Text;
    };
    
    // ================ PROJECT CREATION REQUEST ================
    public type CreateProjectRequest = {
        projectInfo: ProjectInfo;
        timeline: Timeline;
        launchParams: LaunchParams;
        tokenDistribution: TokenDistribution;
        financialSettings: FinancialSettings;
        compliance: ComplianceSettings;
        security: SecuritySettings;
    };
    
    // ================ PROJECT UPDATE REQUEST ================
    // Only certain fields can be updated before LIVE phase
    public type UpdateProjectRequest = {
        projectInfo: ?ProjectInfo; // Can update before LIVE
        timeline: ?Timeline; // Can update before LIVE
        compliance: ?ComplianceSettings; // Can update before LIVE
        security: ?SecuritySettings; // Can update before LIVE
        // launchParams, tokenDistribution, financialSettings are IMMUTABLE after creation
    };

    // ===== PROJECT MANAGEMENT =====
    public type ProjectId = Common.ProjectId;
    public type Project = {
        id: ProjectId;
        owner: Common.UserId;
        name: Text;
        description: Text;
        status: ProjectStatus;
        createdAt: Common.Timestamp;
        updatedAt: Common.Timestamp;
        metadata: ProjectMetadata;
    };
    public type ProjectMetadata = {
        tokenId: ?Common.CanisterId;
        launchpadId: ?Common.CanisterId;
        distributionContracts: [Common.CanisterId];
        lockContracts: [Common.CanisterId];
        daoId: ?Common.CanisterId;
    };

    // ===== PROJECT-LEVEL ACTIONS =====
    public type ActionType = {
        #ProjectCreate;
        #TokenDeploy;
        #LaunchpadDeploy;
        #LockDeploy;
        #DistributionDeploy;
    };
    
    public type ResourceType = {
        #Project;
        #Token;
        #Launchpad;
        #Lock;
        #Distribution;
    };
    
    // ===== SERVICE CONFIGURATION TYPES (for a project) =====
    
    public type TokenCreationConfig = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        totalSupply: Nat;
        logo: ?Text;
        description: ?Text;
        standard: TokenStandard;
    };
    
    public type TokenStandard = {
        #ICRC1;
        #ICRC2;
        #Custom : Text;
    };
    
    public type LaunchpadConfig = {
        enableDAO: Bool;
        votingThreshold: Nat;
        proposalDuration: Nat; // in seconds
        executionDelay: Nat; // in seconds
    };
    
    public type DistributionConfig = {
        distributionType: DistributionType;
        recipients: [Recipient];
        startTime: ?Common.Timestamp;
        cliffPeriod: ?Nat; // in seconds
    };
    
    public type DistributionType = {
        #Public;
        #Whitelist;
        #Airdrop;
    };
    
    public type Recipient = {
        address: Principal;
        amount: Nat;
        vestingPeriod: ?Nat; // in seconds
        note: ?Text;
    };
    
    public type LockConfig = {
        lockType: LockType;
        duration: Nat; // in seconds
        releaseSchedule: ReleaseSchedule;
        canCancel: Bool;
        canModify: Bool;
    };
    
    public type LockType = {
        #Team;
        #Advisor;
        #Treasury;
        #Custom : Text;
    };
    
    public type ReleaseSchedule = {
        #Linear;
        #Cliff : { cliff: Nat; linear: Nat };
        #Custom : [ReleasePoint];
    };
    
    public type ReleasePoint = {
        timestamp: Common.Timestamp;
        percentage: Nat; // 0-10000 (basis points)
    };
    
    // ===== PIPELINE SYSTEM =====
    
    public type PipelineId = Common.PipelineId;
    public type StepId = Common.StepId;
    public type PipelineStep = Common.PipelineStep;
    public type StepStatus = Common.StepStatus;
    public type PipelineExecution = Common.PipelineExecution;
    
    public type PipelineConfig = {
        projectId: ProjectId;
        steps: [Common.PipelineStep];
        parallelExecution: Bool;
        retryPolicy: RetryPolicy;
        timeout: Nat; // in seconds
    };
    
    public type RetryPolicy = {
        maxRetries: Nat;
        backoffMultiplier: Float;
        initialDelay: Nat; // in seconds
    };
} 