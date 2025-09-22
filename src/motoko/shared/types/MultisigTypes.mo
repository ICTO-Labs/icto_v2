// ICTO V2 Multisig Types
// Comprehensive type definitions for secure multisig wallet system
import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {
    // ============== CORE WALLET TYPES ==============

    public type WalletId = Text;
    public type ProposalId = Text;
    public type SignatureId = Text;
    public type TransactionId = Text;

    // Wallet configuration for creation
    public type WalletConfig = {
        name: Text;
        description: ?Text;
        threshold: Nat; // M of N signatures required
        signers: [Principal]; // Initial signers list
        // Security settings
        requiresTimelock: Bool;
        timelockDuration: ?Int; // Nanoseconds
        dailyLimit: ?Nat; // Daily spending limit in base units
        emergencyContactDelay: ?Int; // Emergency contact activation delay
        // Advanced features
        allowRecovery: Bool;
        recoveryThreshold: ?Nat; // Different threshold for recovery operations
        maxProposalLifetime: Int; // Maximum proposal lifetime in nanoseconds
        // Governance
        requiresConsensusForChanges: Bool; // Requires all signers for structural changes
        allowObservers: Bool;
    };

    // Complete wallet state
    public type MultisigWallet = {
        id: WalletId;
        canisterId: Principal;
        config: WalletConfig;

        // Current state
        signers: [SignerInfo];
        observers: [Principal]; // Read-only access
        status: WalletStatus;

        // Balances and assets
        balances: AssetBalances;

        // Operational data
        totalProposals: Nat;
        executedProposals: Nat;
        failedProposals: Nat;

        // Security tracking
        lastActivity: Int;
        securityFlags: SecurityFlags;

        // Metadata
        createdAt: Int;
        createdBy: Principal;
        version: Nat;
    };

    public type SignerInfo = {
        principal: Principal;
        name: ?Text;
        role: SignerRole;
        addedAt: Int;
        addedBy: Principal;
        lastSeen: ?Int;
        isActive: Bool;

        // Security features
        requiresTwoFactor: Bool;
        ipWhitelist: ?[Text];
        sessionTimeout: ?Int;

        // Delegation capabilities
        delegatedVoting: Bool;
        delegatedTo: ?Principal;
        delegationExpiry: ?Int;
    };

    public type SignerRole = {
        #Owner; // Full administrative rights
        #Signer; // Can create and sign proposals
        #Observer; // Read-only access
        #Guardian; // Emergency operations only
        #Delegate; // Temporary signing rights
    };

    public type WalletStatus = {
        #Active;
        #Paused;
        #Frozen; // Emergency freeze
        #Recovery; // In recovery mode
        #Deprecated; // Being phased out
        #Setup; // Initial setup phase
    };

    // ============== ASSET AND BALANCE TYPES ==============

    public type AssetBalances = {
        icp: Nat;
        tokens: [TokenBalance];
        nfts: [NFTBalance];
        totalUsdValue: ?Float;
        lastUpdated: Int;
    };

    public type TokenBalance = {
        canisterId: Principal;
        standard: TokenStandard;
        symbol: Text;
        name: Text;
        decimals: Nat8;
        balance: Nat;
        lockedBalance: Nat; // Locked in pending proposals
        metadata: ?TokenMetadata;
    };

    public type NFTBalance = {
        canisterId: Principal;
        standard: NFTStandard;
        tokenIds: [Nat];
        lockedTokens: [Nat]; // Locked in pending proposals
    };

    public type TokenStandard = {
        #ICRC1;
        #ICRC2;
        #DIP20;
        #EXT;
        #Custom: Text;
    };

    public type NFTStandard = {
        #DIP721;
        #EXT;
        #ICRC7;
        #Custom: Text;
    };

    public type TokenMetadata = {
        logo: ?Text;
        website: ?Text;
        verified: Bool;
        tags: [Text];
    };

    // ============== PROPOSAL SYSTEM ==============

    public type Proposal = {
        id: ProposalId;
        walletId: WalletId;

        // Proposal content
        proposalType: ProposalType;
        title: Text;
        description: Text;

        // Execution data
        actions: [ProposalAction];

        // Proposer information
        proposer: Principal;
        proposedAt: Int;

        // Execution timeline
        earliestExecution: ?Int; // For timelock
        expiresAt: Int;

        // Approval tracking
        requiredApprovals: Nat;
        currentApprovals: Nat;
        approvals: [ProposalApproval];
        rejections: [ProposalRejection];

        // Status and results
        status: ProposalStatus;
        executedAt: ?Int;
        executedBy: ?Principal;
        executionResult: ?ExecutionResult;

        // Security features
        risk: RiskLevel;
        requiresConsensus: Bool;
        emergencyOverride: Bool;

        // Batch execution
        dependsOn: [ProposalId]; // Dependency chain
        executionOrder: ?Nat;
    };

    public type ProposalType = {
        // Asset transfers
        #Transfer: {
            recipient: Principal;
            amount: Nat;
            asset: AssetType;
            memo: ?Blob;
        };

        // Token operations
        #TokenApproval: {
            spender: Principal;
            amount: Nat;
            token: Principal;
        };

        // Batch operations
        #BatchTransfer: {
            transfers: [TransferRequest];
        };

        // Governance operations
        #WalletModification: {
            modificationType: WalletModificationType;
        };

        // External contract calls
        #ContractCall: {
            canister: Principal;
            method: Text;
            args: Blob;
            cycles: ?Nat;
        };

        // Emergency operations
        #EmergencyAction: {
            actionType: EmergencyActionType;
        };

        // System operations
        #SystemUpdate: {
            updateType: SystemUpdateType;
        };
    };

    public type AssetType = {
        #ICP;
        #Token: Principal;
        #NFT: { canister: Principal; tokenId: Nat };
    };

    public type TransferRequest = {
        recipient: Principal;
        amount: Nat;
        asset: AssetType;
        memo: ?Blob;
    };

    public type WalletModificationType = {
        #AddSigner: { signer: Principal; role: SignerRole };
        #RemoveSigner: { signer: Principal };
        #ChangeThreshold: { newThreshold: Nat };
        #UpdateSignerRole: { signer: Principal; newRole: SignerRole };
        #AddObserver: { observer: Principal };
        #RemoveObserver: { observer: Principal };
        #UpdateWalletConfig: { config: WalletConfig };
    };

    public type EmergencyActionType = {
        #FreezeWallet;
        #UnfreezeWallet;
        #EnableRecoveryMode;
        #DisableRecoveryMode;
        #EmergencyTransfer: { to: Principal; asset: AssetType; amount: Nat };
        #PauseAllOperations;
        #ResumeOperations;
    };

    public type SystemUpdateType = {
        #UpgradeWasm: { wasmModule: Blob };
        #UpdatePermissions: { permissions: [Permission] };
        #ConfigureAutomation: { rules: [AutomationRule] };
        #SetDailyLimits: { limits: [AssetLimit] };
    };

    public type ProposalAction = {
        actionType: ProposalType;
        estimatedCost: ?Nat; // In cycles
        riskAssessment: RiskAssessment;
    };

    public type ProposalApproval = {
        signer: Principal;
        approvedAt: Int;
        signature: Blob;
        note: ?Text;

        // Security verification
        ipAddress: ?Text;
        userAgent: ?Text;
        twoFactorVerified: Bool;
        delegated: Bool;
        delegatedBy: ?Principal;
    };

    public type ProposalRejection = {
        signer: Principal;
        rejectedAt: Int;
        reason: Text;

        // Security tracking
        ipAddress: ?Text;
        userAgent: ?Text;
    };

    public type ProposalStatus = {
        #Draft;
        #Pending;
        #Approved; // Has enough signatures but not executed
        #Timelocked; // Waiting for timelock to expire
        #Executed;
        #Rejected;
        #Expired;
        #Failed; // Execution failed
        #Cancelled;
    };

    public type RiskLevel = {
        #Low;
        #Medium;
        #High;
        #Critical;
    };

    public type RiskAssessment = {
        level: RiskLevel;
        factors: [RiskFactor];
        score: Float; // 0.0 to 1.0
        autoApproved: Bool;
    };

    public type RiskFactor = {
        #LargeAmount;
        #UnknownRecipient;
        #ExternalContract;
        #StructuralChange;
        #EmergencyAction;
        #CrossChainOperation;
        #HighFrequency;
        #OutsideBusinessHours;
    };

    // ============== EXECUTION AND RESULTS ==============

    public type ExecutionResult = {
        success: Bool;
        error: ?Text;
        gasUsed: ?Nat;
        transactionIds: [TransactionId];
        timestamp: Int;

        // Detailed results for each action
        actionResults: [ActionResult];

        // Side effects
        balanceChanges: [BalanceChange];
        eventsEmitted: [WalletEvent];
    };

    public type ActionResult = {
        actionIndex: Nat;
        success: Bool;
        error: ?Text;
        gasUsed: ?Nat;
        result: ?Blob; // Serialized result data
    };

    public type BalanceChange = {
        asset: AssetType;
        previousBalance: Nat;
        newBalance: Nat;
        delta: Int; // Can be negative
    };

    // ============== SECURITY AND MONITORING ==============

    public type SecurityFlags = {
        suspiciousActivity: Bool;
        rateLimit: Bool;
        geoRestricted: Bool;
        complianceAlert: Bool;

        // Automated security features
        autoFreezeEnabled: Bool;
        anomalyDetection: Bool;
        whitelistOnly: Bool;

        // Monitoring
        failedAttempts: Nat;
        lastSecurityEvent: ?Int;
        securityScore: Float; // 0.0 to 1.0
    };

    public type Permission = {
        principal: Principal;
        permissions: [PermissionType];
        grantedAt: Int;
        grantedBy: Principal;
        expiresAt: ?Int;
    };

    public type PermissionType = {
        #Read;
        #CreateProposal;
        #SignProposal;
        #ExecuteProposal;
        #ModifyWallet;
        #EmergencyAction;
        #AdminAccess;
    };

    // ============== AUTOMATION AND RULES ==============

    public type AutomationRule = {
        id: Text;
        name: Text;
        isActive: Bool;

        // Trigger conditions
        trigger: TriggerCondition;

        // Actions to take
        actions: [AutomatedAction];

        // Constraints
        cooldownPeriod: ?Int;
        maxExecutions: ?Nat;
        executionCount: Nat;

        // Metadata
        createdAt: Int;
        createdBy: Principal;
        lastExecuted: ?Int;
    };

    public type TriggerCondition = {
        #TimeSchedule: { cron: Text };
        #BalanceThreshold: { asset: AssetType; threshold: Nat; direction: ThresholdDirection };
        #ProposalCreated: { proposalType: ?ProposalType };
        #SecurityEvent: { eventType: SecurityEventType };
        #ExternalCall: { source: Principal; method: Text };
    };

    public type ThresholdDirection = {
        #Above;
        #Below;
    };

    public type AutomatedAction = {
        #CreateProposal: { proposalType: ProposalType; title: Text; description: Text };
        #SendNotification: { recipients: [Principal]; message: Text };
        #FreezeWallet;
        #ActivateEmergencyMode;
        #UpdateSecuritySettings: { settings: SecurityFlags };
    };

    public type AssetLimit = {
        asset: AssetType;
        dailyLimit: Nat;
        monthlyLimit: ?Nat;
        perTransactionLimit: ?Nat;

        // Current usage
        dailyUsed: Nat;
        monthlyUsed: Nat;
        lastReset: Int;
    };

    // ============== EVENTS AND LOGGING ==============

    public type WalletEvent = {
        id: Text;
        walletId: WalletId;
        eventType: EventType;
        timestamp: Int;
        actorEvent: Principal;

        // Event data
        data: ?Blob;

        // Context
        proposalId: ?ProposalId;
        transactionId: ?TransactionId;

        // Security
        ipAddress: ?Text;
        userAgent: ?Text;
        severity: EventSeverity;
    };

    public type EventType = {
        #WalletCreated;
        #WalletModified;
        #ProposalCreated;
        #ProposalSigned;
        #ProposalExecuted;
        #ProposalRejected;
        #ProposalExpired;
        #SignerAdded;
        #SignerRemoved;
        #SignerRoleChanged;
        #TransferExecuted;
        #SecurityAlert;
        #EmergencyAction;
        #AutomationTriggered;
        #ConfigurationChanged;
        #PermissionGranted;
        #PermissionRevoked;
    };

    public type EventSeverity = {
        #Info;
        #Warning;
        #Error;
        #Critical;
    };

    public type SecurityEventType = {
        #FailedAuthentication;
        #SuspiciousIP;
        #RapidProposalCreation;
        #LargeTransferAttempt;
        #UnauthorizedAccess;
        #GeographicAnomaly;
        #TimeAnomaly;
        #ComplianceViolation;
    };

    // ============== API RESULT TYPES ==============

    public type CreateWalletResult = Result.Result<{
        walletId: WalletId;
        canisterId: Principal;
        deploymentCost: Nat;
    }, CreateWalletError>;

    public type CreateWalletError = {
        #InsufficientFunds;
        #InvalidConfiguration: Text;
        #DeploymentFailed: Text;
        #Unauthorized;
        #RateLimited;
        #SystemError: Text;
    };

    public type ProposalResult = Result.Result<{
        proposalId: ProposalId;
        status: ProposalStatus;
        requiredApprovals: Nat;
        currentApprovals: Nat;
    }, ProposalError>;

    public type ProposalError = {
        #WalletNotFound;
        #Unauthorized;
        #InvalidProposal: Text;
        #InsufficientBalance;
        #ProposalExpired;
        #AlreadySigned;
        #ThresholdNotMet;
        #ExecutionFailed: Text;
        #SecurityViolation: Text;
        #RateLimited;
    };

    public type SignatureResult = Result.Result<{
        proposalId: ProposalId;
        signatureId: SignatureId;
        currentApprovals: Nat;
        requiredApprovals: Nat;
        readyForExecution: Bool;
    }, SignatureError>;

    public type SignatureError = {
        #ProposalNotFound;
        #AlreadySigned;
        #Unauthorized;
        #ProposalExpired;
        #InvalidSignature;
        #SecurityCheckFailed;
    };

    // ============== QUERY AND FILTER TYPES ==============

    public type WalletFilter = {
        status: ?[WalletStatus];
        signerPrincipal: ?Principal;
        minBalance: ?Nat;
        maxBalance: ?Nat;
        createdAfter: ?Int;
        createdBefore: ?Int;
        hasAsset: ?AssetType;
    };

    public type ProposalFilter = {
        status: ?[ProposalStatus];
        proposalType: ?[ProposalType];
        proposer: ?Principal;
        createdAfter: ?Int;
        createdBefore: ?Int;
        riskLevel: ?[RiskLevel];
        walletId: ?WalletId;
    };

    public type EventFilter = {
        eventType: ?[EventType];
        severity: ?[EventSeverity];
        actorEvent: ?Principal;
        startTime: ?Int;
        endTime: ?Int;
        walletId: ?WalletId;
    };

    // ============== STATISTICS AND ANALYTICS ==============

    public type WalletStatistics = {
        totalWallets: Nat;
        activeWallets: Nat;
        totalValue: Float; // In USD
        totalProposals: Nat;
        executedProposals: Nat;

        // Security metrics
        securityIncidents: Nat;
        failedTransactions: Nat;
        averageSecurityScore: Float;

        // Performance metrics
        averageExecutionTime: Float;
        successRate: Float;

        // Asset distribution
        assetBreakdown: [(AssetType, Float)];
    };

    public type ProposalStatistics = {
        totalProposals: Nat;
        pendingProposals: Nat;
        executedProposals: Nat;
        rejectedProposals: Nat;
        expiredProposals: Nat;

        // Performance metrics
        averageApprovalTime: Float;
        averageExecutionTime: Float;

        // Risk analysis
        riskDistribution: [(RiskLevel, Nat)];
        automatedApprovals: Nat;
    };

    // ============== UPGRADE AND MIGRATION ==============

    public type UpgradeData = {
        version: Nat;
        migrationRequired: Bool;
        backupRequired: Bool;
        estimatedDowntime: ?Int;

        // Data to preserve
        preserveState: Bool;
        preserveEvents: Bool;
        preserveAutomation: Bool;
    };

    public type MigrationStep = {
        stepId: Text;
        description: Text;
        estimatedTime: Int;
        riskLevel: RiskLevel;
        rollbackPossible: Bool;
    };
}