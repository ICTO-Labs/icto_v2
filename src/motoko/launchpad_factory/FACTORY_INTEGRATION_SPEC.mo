import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";

// ================ FACTORY INTEGRATION SPECIFICATIONS ================
// Technical specifications for cross-factory communication in ICTO V2

module FactoryIntegrationSpec {

    // ================ SHARED TYPES FOR ALL FACTORIES ================

    public type ProjectId = Text;
    public type FactoryPrincipal = Principal;
    
    // Common project metadata
    public type ProjectMetadata = {
        id: ProjectId;
        name: Text;
        creator: Principal;
        createdAt: Time.Time;
        status: ProjectStatus;
    };

    public type ProjectStatus = {
        #Setup;           // Initial configuration
        #TokenCreated;    // Token deployed
        #LaunchReady;     // Ready for sale
        #LaunchActive;    // Sale in progress  
        #LaunchSuccess;   // Sale completed successfully
        #Distributing;    // Token distribution in progress
        #DAOActive;       // Community governance active
        #Completed;       // All phases completed
        #Failed;          // Project failed
        #Cancelled;       // Cancelled by creator
    };

    // ================ TOKEN FACTORY INTEGRATION ================

    public type TokenFactoryInterface = {
        // Create token for launchpad project
        createProjectToken: shared (TokenCreationArgs) -> async Result.Result<TokenCreationResult, Text>;
        
        // Setup initial token distribution
        setupTokenDistribution: shared (TokenDistributionArgs) -> async Result.Result<(), Text>;
        
        // Transfer token control to distribution factory
        transferTokenControl: shared (ProjectId, Principal) -> async Result.Result<(), Text>;
    };

    public type TokenCreationArgs = {
        projectId: ProjectId;
        tokenConfig: {
            name: Text;
            symbol: Text; 
            decimals: Nat8;
            totalSupply: Nat;
        };
        allocation: TokenAllocation;
        creator: Principal;
    };

    public type TokenAllocation = {
        sale: Nat;              // Tokens for launchpad sale
        team: Nat;              // Team allocation
        treasury: Nat;          // DAO treasury
        liquidity: Nat;         // DEX liquidity
        advisors: Nat;          // Advisor allocation  
        ecosystem: Nat;         // Ecosystem growth
        reserves: Nat;          // Future use
    };

    public type TokenCreationResult = {
        tokenCanisterId: Principal;
        deploymentCost: Nat;
        allocationBreakdown: TokenAllocation;
    };

    // ================ LAUNCHPAD FACTORY INTEGRATION ================

    public type LaunchpadFactoryInterface = {
        // Create launchpad for project (current functionality)
        createLaunchpad: shared (LaunchpadCreationArgs) -> async Result.Result<LaunchpadCreationResult, Text>;
        
        // Trigger post-launch distribution
        triggerDistribution: shared (ProjectId) -> async Result.Result<(), Text>;
        
        // Setup DAO governance after launch
        setupProjectGovernance: shared (ProjectId, DAOSetupArgs) -> async Result.Result<(), Text>;
    };

    public type LaunchpadCreationArgs = {
        projectId: ProjectId;
        tokenCanisterId: Principal;
        launchConfig: LaunchpadConfig;
        creator: Principal;
    };

    public type LaunchpadConfig = {
        // Sale parameters
        softCap: Nat;
        hardCap: Nat;
        tokenPrice: Nat;
        saleStart: Time.Time;
        saleEnd: Time.Time;
        
        // Distribution parameters
        saleTokenAmount: Nat;
        distributionPlan: DistributionPlan;
        
        // Governance setup
        daoConfig: ?DAOConfiguration;
    };

    public type LaunchpadCreationResult = {
        launchpadCanisterId: Principal;
        estimatedCosts: {
            deployment: Nat;
            operations: Nat;
            governance: Nat;
        };
    };

    // ================ DISTRIBUTION FACTORY INTEGRATION ================

    public type DistributionFactoryInterface = {
        // Setup vesting contracts for all categories
        createDistributionPipeline: shared (DistributionPipelineArgs) -> async Result.Result<DistributionPipelineResult, Text>;
        
        // Create milestone-based distribution
        createMilestoneDistribution: shared (MilestoneDistributionArgs) -> async Result.Result<Principal, Text>;
        
        // Setup liquidity provision
        createLiquidityDistribution: shared (LiquidityDistributionArgs) -> async Result.Result<Principal, Text>;
        
        // Transfer control to DAO
        transferDistributionControl: shared (ProjectId, Principal) -> async Result.Result<(), Text>;
    };

    public type DistributionPipelineArgs = {
        projectId: ProjectId;
        tokenCanisterId: Principal;
        raisedFunds: {
            token: Principal;  // ICP, USDC, etc.
            amount: Nat;
        };
        distributionPlan: DistributionPlan;
    };

    public type DistributionPlan = {
        // Sale participant distribution
        saleDistribution: VestingSchedule;
        
        // Team distribution  
        teamDistribution: VestingSchedule;
        
        // Treasury distribution (DAO controlled)
        treasuryDistribution: VestingSchedule;
        
        // Liquidity provision
        liquidityDistribution: {
            percentage: Nat8;  // % of raised funds for LP
            lockPeriod: Time.Time;
            dexPlatform: Text;  // Which DEX to use
        };
        
        // Raised funds distribution
        fundsDistribution: {
            teamFunding: FundsDistribution;
            operations: FundsDistribution; 
            liquidity: FundsDistribution;
        };
    };

    public type VestingSchedule = {
        cliff: Time.Time;              // Lock period
        duration: Time.Time;           // Total vesting period
        initialUnlock: Nat8;           // Immediate unlock %
        frequency: VestingFrequency;   // Release frequency
        conditions: ?[MilestoneCondition]; // Optional milestone requirements
    };

    public type VestingFrequency = {
        #Daily;
        #Weekly; 
        #Monthly;
        #Quarterly;
        #Custom: Time.Time;  // Custom interval
    };

    public type FundsDistribution = {
        amount: Nat;
        schedule: VestingSchedule;
        conditions: ?[MilestoneCondition];
    };

    public type MilestoneCondition = {
        id: Text;
        description: Text;
        deadline: Time.Time;
        verification: MilestoneVerificationType;
        penaltyOnMiss: DistributionPenalty;
    };

    public type MilestoneVerificationType = {
        #CommunityVote: { requiredApproval: Nat8 }; // % approval needed
        #TechnicalAudit: { auditorRequired: Bool };
        #KPITarget: { metric: Text; target: Nat };
        #CodeCommit: { repositoryUrl: Text; requiredCommits: Nat };
    };

    public type DistributionPenalty = {
        #DelayRelease: Time.Time;      // Delay next release
        #ReduceAmount: Nat8;           // Reduce by percentage
        #TransferToDAO;                // Transfer control to DAO
        #CompleteHalt;                 // Stop all distributions
    };

    public type DistributionPipelineResult = {
        contracts: {
            saleVesting: Principal;
            teamVesting: Principal;
            treasuryVesting: Principal;
            liquidityContract: Principal;
        };
        schedules: {
            nextReleaseTime: Time.Time;
            totalLockValue: Nat;
            estimatedCompletionTime: Time.Time;
        };
    };

    // ================ DAO FACTORY INTEGRATION ================

    public type DAOFactoryInterface = {
        // Create DAO for project governance
        createProjectDAO: shared (DAOCreationArgs) -> async Result.Result<DAOCreationResult, Text>;
        
        // Setup milestone voting
        setupMilestoneGovernance: shared (MilestoneGovernanceArgs) -> async Result.Result<(), Text>;
        
        // Transfer asset control to DAO
        transferAssetControl: shared (AssetControlTransferArgs) -> async Result.Result<(), Text>;
    };

    public type DAOCreationArgs = {
        projectId: ProjectId;
        tokenCanisterId: Principal;
        daoConfig: DAOConfiguration;
        initialMembers: [Principal];
    };

    public type DAOConfiguration = {
        // Voting parameters
        votingPeriod: Time.Time;           // How long votes are open
        quorumThreshold: Nat8;             // Minimum participation %
        approvalThreshold: Nat8;           // Approval % needed
        
        // Proposal parameters
        proposalDeposit: Nat;              // Cost to create proposal
        proposalThreshold: Nat;            // Min tokens to propose
        
        // Milestone governance
        milestoneVotingEnabled: Bool;
        emergencyVotingEnabled: Bool;
        
        // Treasury control
        treasuryManagement: TreasuryManagement;
    };

    public type TreasuryManagement = {
        multiSigRequired: Bool;
        requiredSigners: Nat8;
        spendingLimits: [SpendingLimit];
        auditRequirements: AuditRequirements;
    };

    public type SpendingLimit = {
        amount: Nat;
        period: Time.Time;
        requiresVote: Bool;
    };

    public type AuditRequirements = {
        monthlyReportRequired: Bool;
        externalAuditRequired: Bool;
        communityAuditEnabled: Bool;
    };

    public type DAOCreationResult = {
        daoCanisterId: Principal;
        votingTokenId: Principal;
        treasuryCanisterId: Principal;
        governanceSetup: GovernanceSetup;
    };

    public type GovernanceSetup = {
        initialProposals: [Text];  // Initial governance proposals
        scheduledTransitions: [(Time.Time, Text)]; // Scheduled governance transitions
        milestoneSchedule: [MilestoneGovernance];
    };

    public type MilestoneGovernance = {
        milestone: MilestoneCondition;
        votingStart: Time.Time;
        affectedDistributions: [Principal]; // Which distribution contracts are affected
    };

    // ================ CROSS-FACTORY COMMUNICATION ================

    public type CrossFactoryMessage = {
        fromFactory: FactoryType;
        toFactory: FactoryType;
        projectId: ProjectId;
        messageType: MessageType;
        payload: MessagePayload;
        timestamp: Time.Time;
    };

    public type FactoryType = {
        #TokenFactory;
        #LaunchpadFactory;
        #DistributionFactory;
        #DAOFactory;
    };

    public type MessageType = {
        #ProjectStatusUpdate;
        #AssetTransfer;
        #GovernanceTransition;
        #MilestoneCheck;
        #EmergencyAction;
    };

    public type MessagePayload = {
        #StatusUpdate: ProjectStatus;
        #AssetTransfer: {
            assetType: AssetType;
            from: Principal;
            to: Principal;
            amount: ?Nat;
        };
        #GovernanceTransition: {
            newController: Principal;
            transitionType: GovernanceTransitionType;
        };
        #MilestoneCheck: {
            milestoneId: Text;
            result: MilestoneResult;
        };
        #EmergencyAction: {
            actionType: EmergencyActionType;
            reason: Text;
        };
    };

    public type AssetType = {
        #Token: Principal;
        #Funds: Principal;
        #ContractOwnership: Principal;
    };

    public type GovernanceTransitionType = {
        #InitialDAOSetup;
        #CommunityTakeover;
        #EmergencyTransfer;
    };

    public type MilestoneResult = {
        #Achieved: { verifiedBy: MilestoneVerificationType };
        #Failed: { reason: Text };
        #Delayed: { newDeadline: Time.Time };
    };

    public type EmergencyActionType = {
        #PauseDistribution;
        #TransferToDAO;
        #RefundInvestors;
        #LockAssets;
    };

    // ================ INTEGRATION WORKFLOW FUNCTIONS ================

    // Complete project launch workflow
    public type ProjectLaunchWorkflow = {
        // Step 1: Token Creation
        createToken: (TokenCreationArgs) -> async Result.Result<Principal, Text>;
        
        // Step 2: Launchpad Setup  
        setupLaunchpad: (LaunchpadCreationArgs) -> async Result.Result<Principal, Text>;
        
        // Step 3: Conduct Sale
        conductSale: (ProjectId) -> async Result.Result<SaleResult, Text>;
        
        // Step 4: Setup Distribution
        setupDistribution: (DistributionPipelineArgs) -> async Result.Result<[Principal], Text>;
        
        // Step 5: Create DAO
        createDAO: (DAOCreationArgs) -> async Result.Result<Principal, Text>;
        
        // Step 6: Transfer Control
        transferControl: (ProjectId, Principal) -> async Result.Result<(), Text>;
    };

    public type SaleResult = {
        totalRaised: Nat;
        participantCount: Nat;
        success: Bool;
        distributionRequired: Bool;
    };

    // ================ ERROR HANDLING & RECOVERY ================

    public type IntegrationError = {
        #FactoryCommunicationFailed: Text;
        #AssetTransferFailed: Text;  
        #GovernanceSetupFailed: Text;
        #MilestoneVerificationFailed: Text;
        #EmergencyActionRequired: Text;
    };

    public type RecoveryAction = {
        errorType: IntegrationError;
        recoverySteps: [RecoveryStep];
        rollbackRequired: Bool;
    };

    public type RecoveryStep = {
        #RetryOperation: Text;
        #ManualIntervention: Text;
        #EmergencyPause: Text;
        #CommunityVote: Text;
    };

    // ================ MONITORING & ANALYTICS ================

    public type IntegrationMetrics = {
        projectId: ProjectId;
        factoryStatuses: [(FactoryType, FactoryStatus)];
        overallProgress: Nat8; // Percentage completion
        estimatedCompletion: Time.Time;
        blockers: [IntegrationBlocker];
    };

    public type FactoryStatus = {
        #NotStarted;
        #InProgress: Nat8; // Progress percentage
        #Completed;
        #Failed: Text;
        #Blocked: Text;
    };

    public type IntegrationBlocker = {
        factory: FactoryType;
        issue: Text;
        severity: BlockerSeverity;
        estimatedResolution: ?Time.Time;
    };

    public type BlockerSeverity = {
        #Low;      // Minor issue, doesn't block progress
        #Medium;   // Delays progress but project can continue
        #High;     // Blocks current phase
        #Critical; // Threatens project success
    };
}