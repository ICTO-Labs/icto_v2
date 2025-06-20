// ⬇️ ICTO V2 Backend Router Types - Comprehensive Routing System Types
// Complete type definitions for the ICTO V2 routing and deployment system
// This module centralizes all routing-related types for maintainability

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import ProjectTypes "../../shared/types/ProjectTypes";

// Import backend types for proper typing
import BackendTypes "../types/BackendTypes";

// Import interface types that are used in BackendContext
// We'll use the actual module types here

module RouterTypes {

    // ================ ROUTE TYPES ================
    
    public type RouteType = {
        #Token;
        #Launchpad;
        #Lock;
        #Distribution;
        #Pipeline;
        #Airdrop;
        #DAO;
        #Analytics;
    };
    
    public type RoutePriority = {
        #Standard;
        #High;
        #Critical;
        #Background;
    };
    
    public type RouteOptions = {
        priority: RoutePriority;
        enableNotifications: Bool;
        customMetadata: ?Text;
        dependsOn: [Text]; // Other route IDs this depends on
        timeout: ?Nat; // Timeout in seconds
    };

    // ================ DEPLOYMENT REQUEST TYPES ================
    
    public type DeploymentType = {
        #Token: TokenDeploymentRequest;
        #Launchpad: LaunchpadDeploymentRequest;
        #Lock: LockDeploymentRequest;
        #Distribution: DistributionDeploymentRequest;
        #Pipeline: PipelineDeploymentRequest;
        #Airdrop: AirdropDeploymentRequest;
        #DAO: DAODeploymentRequest;
    };

    // ================ TOKEN DEPLOYMENT TYPES ================
    
    public type TokenDeploymentRequest = {
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        initialSupply: Nat;
        options: ?TokenDeploymentOptions;
    };
    
    public type TokenDeploymentOptions = {
        allowSymbolConflict: Bool;
        enableAdvancedFeatures: Bool;
        customMinter: ?Principal;
        customFeeCollector: ?Principal;
        vestingEnabled: Bool;
        burnEnabled: Bool;
        mintingEnabled: Bool;
        maxSupply: ?Nat;
        transferRestrictions: [TransferRestriction];
    };
    
    public type TransferRestriction = {
        restrictionType: TransferRestrictionType;
        parameters: Text; // JSON configuration
        exemptPrincipals: [Principal];
    };
    
    public type TransferRestrictionType = {
        #TimeLock;
        #VestingLock;
        #WhitelistOnly;
        #MaxTransferAmount;
        #CooldownPeriod;
    };

    // ================ LAUNCHPAD DEPLOYMENT TYPES ================
    
    public type LaunchpadDeploymentRequest = {
        projectRequest: ProjectTypes.CreateProjectRequest;
        launchpadConfig: LaunchpadConfiguration;
        fundraisingStrategy: FundraisingStrategy;
    };
    
    public type LaunchpadConfiguration = {
        fundraisingGoal: Nat;
        hardCap: Nat;
        softCap: ?Nat;
        startTime: Time.Time;
        endTime: Time.Time;
        minContribution: Nat;
        maxContribution: Nat;
        enableWhitelist: Bool;
        enableKYC: Bool;
        vestingSchedule: ?VestingSchedule;
        liquidityLockPeriod: ?Nat; // seconds
    };
    
    public type FundraisingStrategy = {
        #PublicSale;
        #PrivateSale;
        #PresaleAndPublic: {
            presaleAllocation: Nat; // percentage
            presaleDiscount: Nat; // percentage
            presaleDuration: Nat; // seconds
        };
        #DutchAuction: {
            startPrice: Nat;
            endPrice: Nat;
            priceDecreaseInterval: Nat; // seconds
        };
        #FixedPrice;
    };

    // ================ LOCK DEPLOYMENT TYPES ================
    
    public type LockDeploymentRequest = {
        projectId: Text;
        lockConfiguration: LockConfiguration;
        beneficiaries: [LockBeneficiary];
    };
    
    public type LockConfiguration = {
        lockDuration: Nat; // seconds
        vestingSchedule: ?VestingSchedule;
        cliffPeriod: ?Nat; // seconds
        isRevocable: Bool;
        lockType: LockType;
    };
    
    public type LockType = {
        #TokenLock;
        #LPLock;
        #TeamLock;
        #InvestorLock;
        #FounderLock;
        #AdvisorLock;
    };
    
    public type VestingSchedule = {
        totalDuration: Nat; // seconds
        releaseIntervals: Nat; // seconds between releases
        initialRelease: Nat; // percentage released immediately
        cliffDuration: Nat; // seconds before first release
    };
    
    public type LockBeneficiary = {
        principal: Principal;
        amount: Nat;
        lockDuration: ?Nat; // Override default if needed
        vestingOverride: ?VestingSchedule;
        metadata: ?BeneficiaryMetadata;
    };
    
    public type BeneficiaryMetadata = {
        role: Text; // "founder", "advisor", "investor", "team"
        contributionDescription: Text;
        complianceStatus: ComplianceStatus;
    };
    
    public type ComplianceStatus = {
        kycCompleted: Bool;
        amlCleared: Bool;
        jurisdiction: Text;
    };

    // ================ DISTRIBUTION DEPLOYMENT TYPES ================
    
    public type DistributionDeploymentRequest = {
        projectId: Text;
        distributionConfig: DistributionConfiguration;
        recipients: [DistributionRecipient];
    };
    
    public type DistributionConfiguration = {
        distributionType: DistributionType;
        totalAmount: Nat;
        startTime: ?Time.Time;
        endTime: ?Time.Time;
        claimDeadline: ?Time.Time;
        requiresWhitelist: Bool;
        enablePartialClaims: Bool;
        batchSize: Nat;
        verificationRequired: Bool;
    };
    
    public type DistributionType = {
        #Airdrop;
        #PrivateSale;
        #PublicSale;
        #TeamAllocation;
        #CommunityRewards;
        #LiquidityIncentives;
        #StakingRewards;
        #GovernanceRewards;
    };
    
    public type DistributionRecipient = {
        principal: Principal;
        amount: Nat;
        vestingSchedule: ?VestingSchedule;
        metadata: ?RecipientMetadata;
    };
    
    public type RecipientMetadata = {
        category: Text;
        contributionScore: ?Nat;
        referrer: ?Principal;
        specialConditions: [Text];
    };

    // ================ AIRDROP DEPLOYMENT TYPES ================
    
    public type AirdropDeploymentRequest = {
        projectId: Text;
        airdropConfig: AirdropConfiguration;
        eligibilityCriteria: [EligibilityCriterion];
    };
    
    public type AirdropConfiguration = {
        totalTokens: Nat;
        maxRecipientsPerBatch: Nat;
        claimPeriod: Nat; // seconds
        requiresVerification: Bool;
        enableSnapshot: Bool;
        snapshotTime: ?Time.Time;
        antiSybilMeasures: [AntiSybilMeasure];
    };
    
    public type EligibilityCriterion = {
        criterionType: EligibilityType;
        parameters: Text; // JSON configuration
        weight: Nat; // For scoring systems
        minimumRequirement: Bool;
    };
    
    public type EligibilityType = {
        #TokenHolding: {
            tokenContract: Principal;
            minimumAmount: Nat;
            holdingPeriod: ?Nat; // seconds
        };
        #ActivityLevel: {
            platform: Text;
            activityType: Text;
            minimumActivity: Nat;
        };
        #StakingAmount: {
            stakingContract: Principal;
            minimumStaked: Nat;
        };
        #CommunityParticipation: {
            platformType: Text;
            participationType: Text;
            minimumScore: Nat;
        };
        #WhitelistMembership: {
            whitelistId: Text;
            tier: ?Text;
        };
    };
    
    public type AntiSybilMeasure = {
        measureType: AntiSybilType;
        parameters: Text;
        isRequired: Bool;
    };
    
    public type AntiSybilType = {
        #UniqueWalletVerification;
        #KYCVerification;
        #SocialVerification;
        #TransactionHistoryAnalysis;
    };

    // ================ DAO DEPLOYMENT TYPES ================
    
    public type DAODeploymentRequest = {
        projectId: Text;
        daoConfig: DAOConfiguration;
        governanceRules: GovernanceRules;
    };
    
    public type DAOConfiguration = {
        daoName: Text;
        description: Text;
        governanceToken: Principal;
        treasuryManagement: TreasuryConfig;
        votingMechanism: VotingMechanism;
    };
    
    public type TreasuryConfig = {
        initialFunds: Nat;
        managementRules: Text; // JSON configuration
        spendingLimits: [(Principal, Nat)]; // Principal -> spending limit
        multiSigConfig: ?MultiSigConfig;
    };
    
    public type MultiSigConfig = {
        requiredSignatures: Nat;
        totalSigners: Nat;
        signers: [Principal];
        timelock: ?Nat; // seconds
    };
    
    public type VotingMechanism = {
        #SimpleVoting;
        #QuadraticVoting;
        #DelegatedVoting: {
            allowRedelegation: Bool;
            delegationLimits: ?Nat;
        };
        #WeightedVoting: {
            weightFactors: [(Text, Nat)];
        };
    };
    
    public type GovernanceRules = {
        proposalThreshold: Nat; // Minimum tokens to create proposal
        quorumRequirement: Nat; // Minimum participation for valid vote
        votingPeriod: Nat; // seconds
        executionDelay: Nat; // seconds after vote passes
        vetoRights: [Principal]; // Who can veto proposals
    };

    // ================ PIPELINE DEPLOYMENT TYPES ================
    
    public type PipelineDeploymentRequest = {
        projectId: Text;
        pipelineConfig: PipelineConfiguration;
        steps: [PipelineStep];
    };
    
    public type PipelineConfiguration = {
        pipelineName: Text;
        description: Text;
        executeInOrder: Bool;
        continueOnError: Bool;
        maxRetries: Nat;
        timeoutPerStep: Nat; // seconds
        parallelExecution: Bool;
    };
    
    public type PipelineStep = {
        stepId: Text;
        stepType: PipelineStepType;
        dependencies: [Text]; // Other step IDs
        configuration: PipelineStepConfig;
        retryPolicy: RetryPolicy;
    };
    
    public type PipelineStepType = {
        #CreateToken;
        #CreateLock;
        #CreateDistribution;
        #CreateLaunchpad;
        #CreateDAO;
        #AddLiquidity;
        #StartVesting;
        #ExecuteAirdrop;
        #SetupGovernance;
        #Custom: Text; // Custom step type
    };
    
    public type PipelineStepConfig = {
        #TokenConfig: TokenDeploymentRequest;
        #LockConfig: LockDeploymentRequest;
        #DistributionConfig: DistributionDeploymentRequest;
        #LaunchpadConfig: LaunchpadDeploymentRequest;
        #DAOConfig: DAODeploymentRequest;
        #CustomConfig: Text; // JSON string for custom configurations
    };
    
    public type RetryPolicy = {
        maxRetries: Nat;
        backoffStrategy: BackoffStrategy;
        retryableErrors: [Text]; // Error patterns that should trigger retry
    };
    
    public type BackoffStrategy = {
        #Fixed: Nat; // Fixed delay in seconds
        #Linear: Nat; // Linear increase per retry
        #Exponential: Nat; // Exponential backoff base
        #Custom: {
            delayFunction: Text;
            parameters: [Nat];
        };
    };

    // ================ DEPLOYMENT RESULT TYPES ================
    
    public type DeploymentResult = {
        deploymentId: Text;
        deploymentType: Text;
        canisterId: ?Text;
        projectId: ?Text;
        status: DeploymentStatus;
        createdAt: Time.Time;
        startedAt: ?Time.Time;
        completedAt: ?Time.Time;
        metadata: DeploymentMetadata;
        steps: [DeploymentStepResult]; // For pipeline deployments
    };
    
    public type DeploymentStatus = {
        #Pending;
        #Queued;
        #InProgress;
        #Completed;
        #Failed: Text;
        #Cancelled;
        #Timeout;
        #PartialSuccess;
        #RollingBack;
    };
    
    public type DeploymentMetadata = {
        deployedBy: Principal;
        estimatedCost: Nat;
        actualCost: ?Nat;
        cyclesUsed: ?Nat;
        transactionId: ?Text;
        paymentRecordId: ?Text;
        serviceEndpoint: Text;
        version: Text;
        environment: Text; // "development", "staging", "production"
    };
    
    public type DeploymentStepResult = {
        stepId: Text;
        stepType: Text;
        status: DeploymentStatus;
        canisterId: ?Text;
        startedAt: Time.Time;
        completedAt: ?Time.Time;
        cyclesUsed: ?Nat;
        errorMessage: ?Text;
        retryCount: Nat;
    };

    // ================ ROUTING CONFIGURATION TYPES ================
    
    public type RouteConfiguration = {
        routeType: RouteType;
        isEnabled: Bool;
        serviceEndpoint: ?Principal;
        healthCheckInterval: Nat; // seconds
        timeout: Nat; // seconds
        retryPolicy: RetryPolicy;
        loadBalancing: LoadBalancingConfig;
    };
    
    public type LoadBalancingConfig = {
        strategy: LoadBalancingStrategy;
        maxConcurrentRequests: Nat;
        queueSize: Nat;
        healthCheckRequired: Bool;
    };
    
    public type LoadBalancingStrategy = {
        #RoundRobin;
        #LeastConnections;
        #WeightedRoundRobin: [(Principal, Nat)]; // Service -> Weight
        #HealthBased;
        #ResponseTimeBased;
    };

    // ================ ANALYTICS AND MONITORING TYPES ================
    
    public type RouteMetrics = {
        routeType: RouteType;
        totalRequests: Nat;
        successfulRequests: Nat;
        failedRequests: Nat;
        averageResponseTime: Nat; // milliseconds
        lastRequestTime: ?Time.Time;
        healthStatus: HealthStatus;
        throughputMetrics: ThroughputMetrics;
    };
    
    public type ThroughputMetrics = {
        requestsPerSecond: Nat;
        peakRequestsPerSecond: Nat;
        averageRequestSize: Nat;
        averageResponseSize: Nat;
    };
    
    public type HealthStatus = {
        #Healthy;
        #Degraded;
        #Unhealthy;
        #Unknown;
        #Maintenance;
    };
    
    public type RouterAnalytics = {
        totalDeployments: Nat;
        deploymentsByType: [(RouteType, Nat)];
        averageDeploymentTime: Nat; // seconds
        successRate: Float;
        popularRoutes: [RouteType];
        peakUsageHours: [Nat]; // Hours of day (0-23)
    };

    // ================ ERROR HANDLING TYPES ================
    
    public type RouterError = {
        #RouteNotFound: Text;
        #ServiceUnavailable: Text;
        #InvalidRequest: Text;
        #AuthenticationFailed;
        #RateLimitExceeded;
        #InternalError: Text;
        #TimeoutError;
        #DependencyFailed: Text;
        #ConfigurationError: Text;
        #ResourceExhausted: Text;
    };
    
    public type RoutingResult<T> = {
        #Ok: T;
        #Err: RouterError;
    };

    // ================ SERVICE HEALTH TYPES ================
    
    public type ServiceHealthCheck = {
        serviceType: RouteType;
        canisterId: Principal;
        lastCheckTime: Time.Time;
        status: HealthStatus;
        responseTime: ?Nat; // milliseconds
        errorMessage: ?Text;
        version: ?Text;
        uptime: ?Nat; // seconds
    };

    // ================ BACKEND CONTEXT TYPES ================
    // These are placeholder types that will be properly resolved at runtime
    // Each backend module defines its own storage types
    
    public type BackendContext = {
        // Core data structures
        projectsTrie: Trie.Trie<Text, ProjectTypes.ProjectDetail>;
        tokenSymbolRegistry: Trie.Trie<Text, Principal>;
        
        // Backend module storage types - use Any as placeholder
        auditStorage: Any;
        userRegistryStorage: Any;
        systemStorage: Any;
        paymentValidator: Any;
        
        // External service references
        externalInvoiceStorage: ?Any;
        tokenDeployerCanisterId: ?Principal;
        launchpadDeployerCanisterId: ?Principal;
        lockDeployerCanisterId: ?Principal;
        distributionDeployerCanisterId: ?Principal;
        
        // System configuration
        systemConfiguration: Any;
    };

    // ================ PERMISSION AND ACCESS TYPES ================
    
    public type DeploymentPermissions = {
        allowedDeploymentTypes: [RouteType];
        userPermissions: [(Principal, [RouteType])];
        rateLimits: [(Principal, RateLimitConfig)];
    };
    
    public type RateLimitConfig = {
        requestsPerSecond: Nat;
        burstCapacity: Nat;
        windowSize: Nat; // seconds
    };
    
    public type AccessControl = {
        resourceType: Text;
        permissions: [Permission];
        conditions: [AccessCondition];
    };
    
    public type Permission = {
        action: Text; // "read", "write", "deploy", "admin"
        scope: Text; // "global", "project", "self"
        limitations: [Text];
    };
    
    public type AccessCondition = {
        conditionType: Text;
        parameters: Text;
        enforcement: Text; // "strict", "advisory", "optional"
    };

    // ================ FEATURE FLAGS ================
    
    public type FeatureFlags = {
        enablePipelineDeployments: Bool;
        enableDAODeployments: Bool;
        enableAirdropOptimizations: Bool;
        enableAdvancedAnalytics: Bool;
        experimentalFeatures: [ExperimentalFeature];
    };
    
    public type ExperimentalFeature = {
        featureName: Text;
        isEnabled: Bool;
        rolloutPercentage: ?Nat;
        conditions: [Text];
        expirationTime: ?Time.Time;
    };
} 