import Result "mo:base/Result";
import Trie "mo:base/Trie";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import List "mo:base/List";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Float "mo:base/Float";
import Nat8 "mo:base/Nat8";
import Hash "mo:base/Hash";
import SecureDAOTypes "./SecureDAOTypes";
import Array "mo:base/Array";
import Text "mo:base/Text";
module DAOTypes {
    public type Result<T, E> = Result.Result<T, E>;
    
    // ================ CORE ACCOUNT & TOKEN TYPES ================
    
    public type Account = { owner : Principal; tokens : Tokens };
    public type Tokens = { amount_e8s : Nat };
    
    // ================ STAKING TYPES ================
    
    // Multiplier Tier for custom staking system (imported from SecureDAOTypes)
    public type MultiplierTier = SecureDAOTypes.MultiplierTier;
    
    // LEGACY: Keep for backward compatibility during migration
    public type StakeRecord = {
        staker: Principal;
        amount: Nat;
        stakedAt: Time.Time;
        unlockTime: ?Time.Time; // None = liquid staking, Some = locked staking
        votingPower: Nat; // Calculated based on amount and lock duration
    };
    
    // Simplified stake entry system with soft-multiplier curve
    public type StakeEntry = {
        id: Nat;                    // Unique ID for this stake entry
        staker: Principal;
        amount: Nat;
        stakedAt: Time.Time;
        lockPeriod: Nat;            // Lock period in seconds (0 = liquid staking)
        unlockTime: Time.Time;      // Calculated unlock time
        multiplier: Float;          // Applied soft multiplier (1.0 - 1.5x)
        votingPower: Nat;           // Calculated voting power
        isActive: Bool;             // Can be set to false when unstaked
        blockIndex: ?Nat;           // ICRC transfer block index for audit
    };
    
    // User's complete staking profile - simplified without tiers
    public type UserStakeProfile = {
        principal: Principal;
        stakeEntries: [StakeEntry];
        totalStaked: Nat;
        totalVotingPower: Nat;
        activeEntries: Nat;
        lastStakeTime: ?Time.Time;
        // Legacy compatibility
        legacyStake: ?StakeRecord;  // For migration period
    };
    
    // Timeline tracking for user activities
    public type TimelineEntry = {
        id: Nat;
        timestamp: Time.Time;
        action: TimelineAction;
        details: Text;
        blockIndex: ?Nat;           // For audit trail
    };
    
    public type TimelineAction = {
        #Stake: { entryId: Nat; amount: Nat; lockPeriod: Nat };
        #Unstake: { entryId: Nat; amount: Nat };
        #Vote: { proposalId: Nat; vote: Text; votingPower: Nat };
        #CreateProposal: { proposalId: Nat; title: Text };
        #Delegate: { to: Principal; votingPower: Nat };
        #Undelegate: { votingPower: Nat };
    };
    
    public type StakeAction = {
        #Stake: { amount: Nat; lockDuration: ?Nat }; // lockDuration in seconds
        #Unstake: { amount: Nat };
        #UnstakeEntry: { entryId: Nat; amount: ?Nat }; // NEW: Unstake specific entry
        #Delegate: { to: Principal };
        #Undelegate;
    };
    
    public type VotingPowerCalculation = {
        baseAmount: Nat;
        lockMultiplier: Float; // 1.0 for liquid, up to 4.0 for max lock
        delegatedFrom: Nat;
        totalVotingPower: Nat;
    };
    
    // Enhanced stake summary for UI
    public type StakingSummary = {
        totalStaked: Nat;
        totalVotingPower: Nat;
        activeEntries: Nat;
        tierBreakdown: [(Text, Nat, Nat)]; // (tier name, staked amount, voting power)
        nextUnlock: ?{time: Time.Time; amount: Nat; entryId: Nat};
        availableToUnstake: Nat;
        legacyStakeExists: Bool;   // For migration UI
    };
    
    // ================ ENHANCED PROPOSAL TYPES ================
    
    public type Proposal = {
        id : Nat;
        votes_no : Nat; // Now using voting power instead of tokens
        votes_yes : Nat;
        voters : List.List<Principal>;
        state : ProposalState;
        timestamp : Time.Time;
        proposer : Principal;
        payload : ProposalPayload;
        executionTime: ?Time.Time; // When proposal will be executed (timelock)
        quorumRequired: Nat; // Minimum voting power needed
        approvalThreshold: Nat; // Percentage needed to pass (in basis points, e.g., 5000 = 50%)
    };
    
    public type ProposalPayload = {
        #Motion: MotionPayload;
        #CallExternal: CallExternalPayload;
        #TokenManage: TokenManagePayload;
        #SystemUpdate: SystemUpdatePayload;
    };
    
    public type MotionPayload = {
        title: Text;
        description: Text;
        discussionUrl: ?Text;
    };
    
    public type CallExternalPayload = {
        target: Principal;
        method: Text;
        args: Blob;
        description: Text;
    };
    
    public type TokenManagePayload = {
        #Transfer: { to: Principal; amount: Nat; memo: ?Text };
        #Burn: { amount: Nat; memo: ?Text };
        #Mint: { to: Principal; amount: Nat; memo: ?Text };
        #UpdateMetadata: { key: Text; value: Text };
    };
    
    public type SystemUpdatePayload = {
        #UpdateSystemParams: UpdateSystemParamsPayload;
        #UpdateTokenConfig: TokenConfigUpdate;
        #UpdateGovernanceLevel: GovernanceLevel;
        #Emergency: EmergencyAction;
    };
    
    public type ProposalState = {
        // A failure occurred while executing the proposal
        #Failed : Text;
        // The proposal is open for voting
        #Open;
        // The proposal is currently being executed
        #Executing;
        // Enough "no" votes have been cast to reject the proposal, and it will not be executed
        #Rejected;
        // The proposal has been successfully executed
        #Succeeded;
        // Enough "yes" votes have been cast to accept the proposal, and it will soon be executed
        #Accepted;
        // Proposal is in timelock period before execution
        #Timelock;
        // Proposal was cancelled by proposer or admin
        #Cancelled;
        // Proposal is ready for execution
        #ExecutionReady;
        // Proposal has expired due to execution deadline
        #Expired;
        // Accepted proposal is in timelock period before execution
    };
    // ================ VOTING TYPES ================
    
    public type Vote = { #no; #yes; #abstain };
    public type VoteArgs = { 
        vote : Vote; 
        proposal_id : Nat;
        reason: ?Text; // Optional reason for vote
    };
    
    public type VoteRecord = {
        voter: Principal;
        vote: Vote;
        votingPower: Nat;
        timestamp: Time.Time;
        reason: ?Text;
    };
    
    // ================ ICRC TOKEN MANAGEMENT ================
    
    public type TokenConfig = {
        canisterId: Principal;
        symbol: Text;
        name: Text;
        decimals: Nat8;
        fee: Nat;
        managedByDAO: Bool; // Whether DAO can mint/burn
    };
    
    public type TokenConfigUpdate = {
        fee: ?Nat;
        name: ?Text;
        symbol: ?Text;
        managedByDAO: ?Bool;
    };
    
    public type TransferArgs = { to : Principal; amount : Nat; memo: ?Text };
    
    // ================ SYSTEM PARAMETERS ================
    
    public type UpdateSystemParamsPayload = {
        transfer_fee : ?Nat;
        proposal_vote_threshold : ?Nat;
        proposal_submission_deposit : ?Nat;
        timelock_duration : ?Nat; // Seconds
        quorum_percentage : ?Nat; // Basis points (e.g., 2000 = 20%)
        approval_threshold : ?Nat; // Basis points (e.g., 5000 = 50%)
        max_voting_period : ?Nat; // Seconds
        min_voting_period : ?Nat; // Seconds
        stake_lock_periods : ?[Nat]; // Available lock periods in seconds
    };
    
    public type EmergencyAction = {
        #Pause;
        #Unpause;
        #EmergencyWithdraw: { token: Principal; to: Principal; amount: Nat };
        #UpdateEmergencyContacts: { contacts: [Principal] };
    };

    public type SystemParams = {
        transfer_fee: Nat;
        
        // Minimum voting power needed to submit a proposal
        proposal_vote_threshold: Nat;
        
        // Amount of tokens required as deposit when submitting a proposal
        proposal_submission_deposit: Nat;
        
        // Time delay before accepted proposals are executed (security)
        timelock_duration: Nat; // seconds
        
        // Minimum percentage of total voting power that must participate
        quorum_percentage: Nat; // basis points (e.g., 2000 = 20%)
        
        // Percentage of votes needed to approve a proposal
        approval_threshold: Nat; // basis points (e.g., 5000 = 50%)
        
        // Voting period duration
        max_voting_period: Nat; // seconds
        min_voting_period: Nat; // seconds
        
        // Available staking lock periods and their multipliers
        stake_lock_periods: [Nat]; // seconds: [0, 2592000, 7776000, 15552000, 31104000] // 0, 1M, 3M, 6M, 1Y
        
        // Emergency settings
        emergency_pause: Bool;
        emergency_contacts: [Principal];
    };
    // ================ STABLE STORAGE TYPES ================
    
    public type BasicDaoStableStorage = {
        accounts: [Account];
        proposals: [Proposal];
        system_params: SystemParams;
        stakeRecords: [(Principal, StakeRecord)];
        voteRecords: [VoteRecord];
        tokenConfig: TokenConfig;
        delegations: [(Principal, DelegationRecord)]; // delegator -> delegation record
        rateLimits: [(Principal, RateLimitRecord)]; // principal -> rate limit data
        executionContexts: [(Nat, ProposalExecutionContext)]; // proposal_id -> execution context
        securityEvents: [SecurityEvent]; // Security audit trail
        proposalTimers: [ProposalTimer]; // Active proposal timers for upgrade persistence
        delegationTimers: [DelegationTimer]; // Active delegation timers for upgrade persistence
        comments: [(Text, ProposalComment)]; // comment_id -> comment record
        totalStaked: Nat;
        totalVotingPower: Nat;
        emergencyState: EmergencyState;
        lastSecurityCheck: Time.Time; // Last time security validation was performed
        customSecurity: ?CustomSecurityParams; // Optional custom security parameters from DAO creator
        governanceLevel: GovernanceLevel; // Governance control level
        customMultiplierTiers: ?[MultiplierTier]; // Custom multiplier tiers from DAO config
    };
    
    public type EmergencyState = {
        paused: Bool;
        pausedBy: ?Principal;
        pausedAt: ?Time.Time;
        reason: ?Text;
    };
    
    // ================ SECURITY TYPES ================
    
    /// Custom security parameters that can be set during DAO creation
    public type CustomSecurityParams = {
        minStakeAmount: ?Nat; // Minimum tokens required to stake
        maxStakeAmount: ?Nat; // Maximum tokens allowed to stake
        minProposalDeposit: ?Nat; // Minimum deposit for creating proposals
        maxProposalDeposit: ?Nat; // Maximum deposit for creating proposals
        maxProposalsPerHour: ?Nat; // Rate limiting for proposals
        maxProposalsPerDay: ?Nat; // Daily rate limiting for proposals
    };
    
    /// Rate limiting tracking for proposals and votes
    public type RateLimitRecord = {
        timestamps: [Time.Time]; // Recent action timestamps
        dailyCount: Nat; // Actions in current 24h period
        lastReset: Time.Time; // Last time counters were reset
    };
    
    /// Delegation with timelock for security
    public type DelegationRecord = {
        delegate: Principal; // Who receives the voting power
        delegator: Principal; // Who delegates their power  
        delegatedAt: Time.Time; // When delegation was initiated
        effectiveAt: Time.Time; // When delegation becomes active (after timelock)
        revokable: Bool; // Whether delegation can be revoked
        votingPower: Nat; // Amount of voting power delegated
    };
    
    /// Proposal execution context for security validation
    public type ProposalExecutionContext = {
        proposalId: Nat;
        executor: Principal; // Who initiated execution
        executionStarted: Time.Time;
        expectedCompletionTime: ?Time.Time;
        criticalOperation: Bool; // Whether this is a critical operation
    };
    
    /// Enhanced audit trail for security events
    public type SecurityEvent = {
        eventType: SecurityEventType;
        principal: Principal;
        timestamp: Time.Time;
        details: Text;
        severity: SecuritySeverity;
    };
    
    public type SecurityEventType = {
        #EmergencyPause;
        #EmergencyUnpause;
        #SuspiciousActivity;
        #RateLimitExceeded; 
        #UnauthorizedAccess;
        #LargeTokenTransfer;
        #GovernanceAttack;
        #DelegationChainTooLong;
        #CustomSecurityViolation;
        #ProposalRateLimitExceeded;
        #DailyRateLimitExceeded;
        #ProposalSubmissionRateLimitExceeded;
        #ProposalSubmissionDepositExceeded;
        #StakeAmountExceeded;
        #DelegationAmountExceeded;
        #DelegationRateLimitExceeded;
        #DelegationDepositExceeded;
        #DelegationTimelockExceeded;
        #ProposalTimelockExceeded;
        #ProposalVotingPeriodExceeded;
        #StakeChange;
        #ProposalExecution;
    };
    
    public type SecuritySeverity = {
        #Low;
        #Medium; 
        #High;
        #Critical;
    };
    
    // ================ TIMER MANAGEMENT TYPES ================
    
    /// Timer information for persistence across upgrades
    public type ProposalTimer = {
        proposalId: Nat;
        timerType: ProposalTimerType;
        scheduledTime: Time.Time; // When the timer should fire
        createdAt: Time.Time; // When the timer was created
        remainingTime: Int; // Nanoseconds remaining (for upgrade persistence)
    };
    
    public type ProposalTimerType = {
        #VotingEnd; // Timer for when voting period ends
        #TimelockEnd; // Timer for when timelock period ends and proposal can execute
        #Cleanup; // Timer for cleanup of expired proposals
    };
    
    /// Delegation timer for timelock periods
    public type DelegationTimer = {
        delegator: Principal;
        scheduledTime: Time.Time;
        createdAt: Time.Time;
        remainingTime: Int;
    };
    
    // ================ QUERY TYPES ================
    
    public type DAOStats = {
        totalMembers: Nat;
        totalStaked: Nat;
        totalVotingPower: Nat;
        activeProposals: Nat;
        totalProposals: Nat;
        treasuryBalance: Nat;
        tokenInfo: TokenConfig;
    };
    
    public type MemberInfo = {
        stakedAmount: Nat;
        votingPower: Nat;
        delegatedTo: ?Principal;
        delegatedFrom: Nat; // Total voting power delegated to this member
        proposalsCreated: Nat;
        proposalsVoted: Nat;
        joinedAt: Time.Time;
    };
    
    public type ProposalInfo = {
        proposal: Proposal;
        votesDetails: {
            totalVotes: Nat;
            yesVotes: Nat;
            noVotes: Nat;
            abstainVotes: Nat;
            quorumMet: Bool;
            thresholdMet: Bool;
        };
        timeRemaining: ?Nat; // seconds until voting ends
        timeToExecution: ?Nat; // seconds until execution (if in timelock)
    };

    // ================ COMMENT SYSTEM TYPES ================
    
    public type ProposalComment = {
        id: Text; // Unique comment identifier
        proposalId: Nat; // Which proposal this comment belongs to
        author: Principal; // Who wrote the comment
        content: Text; // Comment text content
        createdAt: Time.Time; // When comment was created
        updatedAt: ?Time.Time; // When comment was last updated (if edited)
        isEdited: Bool; // Whether comment has been edited
        votingPower: ?Nat; // Author's voting power when commenting
        isStaker: Bool; // Whether author has staking power
    };

    public type CommentAction = {
        #Create: { content: Text };
        #Update: { commentId: Text; content: Text };
        #Delete: { commentId: Text };
    };

    // ================ BACKEND INTEGRATION TYPES ================
    
    // Governance Level types
    public type GovernanceLevel = {
        #MotionOnly;      // Only motion proposals and governance upgrades
        #SemiManaged;     // Basic treasury management + upgrades
        #FullyManaged;    // Complete token control (irreversible)
    };

    // Configuration for creating a DAO through the backend
    public type DAOConfig = {
        // Basic DAO information
        name: Text;
        description: Text;
        tokenCanisterId: Principal;
        
        // Governance parameters
        governanceType: Text; // "liquid", "locked", "hybrid"
        governanceLevel: GovernanceLevel; // NEW: Determines DAO's control level
        stakingEnabled: Bool;
        
        // Voting configuration
        minimumStake: Nat; // Minimum tokens required to participate
        proposalThreshold: Nat; // Voting power required to submit proposal
        proposalSubmissionDeposit: Nat; // Token deposit required when creating proposal
        quorumPercentage: Nat; // Percentage for quorum (in basis points)
        approvalThreshold: Nat; // Percentage for approval (in basis points)
        
        // Time parameters
        timelockDuration: Nat; // Seconds before proposal execution
        maxVotingPeriod: Nat; // Maximum voting period in seconds
        minVotingPeriod: Nat; // Minimum voting period in seconds
        
        // Staking configuration
        stakeLockPeriods: [Nat]; // Available lock periods for enhanced voting power (legacy)
        customMultiplierTiers: ?[MultiplierTier]; // Custom multiplier tier configuration
        
        // Security settings
        emergencyContacts: [Principal]; // Addresses that can pause DAO
        emergencyPauseEnabled: Bool;
        
        // Token management
        managedByDAO: Bool; // Whether DAO can manage the token (derived from governanceLevel)
        transferFee: Nat; // Fee for internal transfers
        
        // Initial configuration
        initialSupply: ?Nat; // For new tokens (if creating new token with DAO)
        
        // Advanced settings
        enableDelegation: Bool; // Allow vote delegation
        votingPowerModel: Text; // "equal", "proportional", "quadratic"
        
        // Metadata
        tags: [Text];
        isPublic: Bool;
    };

    // Arguments for creating DAO via factory
    public type ExternalDeployerArgs = {
        config: DAOConfig;
        owner: Principal;
    };

    // DAO Factory deployment result
    public type DeploymentResult = {
        daoCanisterId: Principal;
    };

    // DAO deployment summary for audit
    public type DAODeploymentSummary = {
        daoName: Text;
        tokenSymbol: Text;
        tokenCanisterId: Principal;
        governanceType: Text;
        stakingEnabled: Bool;
        votingPowerModel: Text;
        emergencyContacts: [Text];
        totalMembers: Nat;
        createdAt: Time.Time;
    };

    // ================ CONVERSION FUNCTIONS ================
    
    /// Convert DAOConfig to SystemParams for backend initialization
    public func configToSystemParams(config: DAOConfig) : SystemParams {
        {
            transfer_fee = config.transferFee;
            proposal_vote_threshold = config.proposalThreshold;
            proposal_submission_deposit = config.proposalSubmissionDeposit;
            timelock_duration = config.timelockDuration;
            quorum_percentage = config.quorumPercentage;
            approval_threshold = config.approvalThreshold;
            max_voting_period = config.maxVotingPeriod;
            min_voting_period = config.minVotingPeriod;
            stake_lock_periods = config.stakeLockPeriods;
            emergency_pause = config.emergencyPauseEnabled;
            emergency_contacts = config.emergencyContacts;
        }
    };
    
    /// Convert DAOConfig to TokenConfig for backend initialization
    public func configToTokenConfig(config: DAOConfig) : TokenConfig {
        {
            canisterId = config.tokenCanisterId;
            symbol = ""; // Will be fetched from token canister
            name = ""; // Will be fetched from token canister  
            decimals = 8; // Default, will be updated
            fee = config.transferFee;
            managedByDAO = config.managedByDAO;
        }
    };

    // ================ UTILITY FUNCTIONS ================
    
    public func proposal_key(t: Nat) : Trie.Key<Nat> = { key = t; hash = Int.hash(t) };
    public func account_key(t: Principal) : Trie.Key<Principal> = { key = t; hash = Principal.hash(t) };
    public func stake_key(t: Principal) : Trie.Key<Principal> = { key = t; hash = Principal.hash(t) };
    
    public func accounts_fromArray(arr: [Account]) : Trie.Trie<Principal, Tokens> {
        var s = Trie.empty<Principal, Tokens>();
        for (account in arr.vals()) {
            s := Trie.put(s, account_key(account.owner), Principal.equal, account.tokens).0;
        };
        s
    };
    
    public func proposals_fromArray(arr: [Proposal]) : Trie.Trie<Nat, Proposal> {
        var s = Trie.empty<Nat, Proposal>();
        for (proposal in arr.vals()) {
            s := Trie.put(s, proposal_key(proposal.id), Nat.equal, proposal).0;
        };
        s
    };
    
    public func stakes_fromArray(arr: [(Principal, StakeRecord)]) : Trie.Trie<Principal, StakeRecord> {
        var s = Trie.empty<Principal, StakeRecord>();
        for ((principal, stake) in arr.vals()) {
            s := Trie.put(s, stake_key(principal), Principal.equal, stake).0;
        };
        s
    };
    
    public func delegations_fromArray(arr: [(Principal, DelegationRecord)]) : Trie.Trie<Principal, DelegationRecord> {
        var s = Trie.empty<Principal, DelegationRecord>();
        for ((delegator, record) in arr.vals()) {
            s := Trie.put(s, stake_key(delegator), Principal.equal, record).0;
        };
        s
    };

    // Comments helper functions
    public func comment_key(id: Text) : Trie.Key<Text> = { key = id; hash = Text.hash(id) };
    
    public func comments_fromArray(arr: [(Text, ProposalComment)]) : Trie.Trie<Text, ProposalComment> {
        var s = Trie.empty<Text, ProposalComment>();
        for ((id, comment) in arr.vals()) {
            s := Trie.put(s, comment_key(id), Text.equal, comment).0;
        };
        s
    };

    // Convert backend DAOConfig to factory BasicDaoStableStorage
    public func toFactoryInitArgs(config: DAOConfig, owner: Principal, customSecurity: ?CustomSecurityParams) : BasicDaoStableStorage {
        let tokenConfig: TokenConfig = {
            canisterId = config.tokenCanisterId;
            symbol = ""; // Will be fetched from token canister
            name = config.name; // Use DAO name for token name
            decimals = 8; // Standard ICRC decimals
            fee = config.transferFee;
            managedByDAO = config.managedByDAO;
        };

        let systemParams: SystemParams = {
            transfer_fee = config.transferFee;
            proposal_vote_threshold = config.proposalThreshold;
            proposal_submission_deposit = config.minimumStake;
            timelock_duration = config.timelockDuration;
            quorum_percentage = config.quorumPercentage;
            approval_threshold = config.approvalThreshold;
            max_voting_period = config.maxVotingPeriod;
            min_voting_period = config.minVotingPeriod;
            stake_lock_periods = config.stakeLockPeriods;
            emergency_pause = config.emergencyPauseEnabled;
            emergency_contacts = config.emergencyContacts;
        };

        let emergencyState: EmergencyState = {
            paused = false;
            pausedBy = null;
            pausedAt = null;
            reason = null;
        };

        {
            accounts = []; // No initial accounts from backend
            proposals = []; // Start with no proposals
            system_params = systemParams;
            stakeRecords = []; // No initial stake records
            voteRecords = []; // No initial vote records
            tokenConfig = tokenConfig;
            delegations = []; // No initial delegations
            totalStaked = 0;
            totalVotingPower = 0;
            emergencyState = emergencyState;
            executionContexts = [];
            securityEvents = [];
            proposalTimers = [];
            delegationTimers = [];
            comments = []; // No initial comments
            lastSecurityCheck = Time.now();
            rateLimits = [];
            customSecurity = customSecurity;
            governanceLevel = config.governanceLevel;
            customMultiplierTiers = config.customMultiplierTiers;
        }
    };
    
    // ================ CONSTANTS ================
    
    public let E8S : Nat = 100_000_000;
    public let oneToken = { amount_e8s = E8S };
    public let zeroToken = { amount_e8s = 0 };
    
    // Voting power calculation constants
    public let BASE_MULTIPLIER : Float = 1.0;
    public let MAX_LOCK_MULTIPLIER : Float = 4.0;
    public let SECONDS_PER_YEAR : Nat = 31536000;
    
    // Default system parameters
    public let DEFAULT_QUORUM_PERCENTAGE : Nat = 2000; // 20%
    public let DEFAULT_APPROVAL_THRESHOLD : Nat = 5000; // 50%
    public let DEFAULT_TIMELOCK_DURATION : Nat = 172800; // 2 days
    public let DEFAULT_VOTING_PERIOD : Nat = 604800; // 7 days
    public let DEFAULT_MIN_VOTING_PERIOD : Nat = 86400; // 1 day
    
    // Basis points for percentage calculations
    public let BASIS_POINTS : Nat = 10000; // 100% = 10000 basis points
    
    // ================ DISTRIBUTION VOTING POWER TYPES ================
    // NEW: Added for distribution contract integration - BACKWARD COMPATIBLE
    
    public type DistributionSnapshotEntry = {
        principal: Principal;
        remaining: Nat;         // token chưa vest tại snapshot
        remaining_time: Nat;    // thời gian còn lại tới lock_end (seconds)
        max_lock: Nat;          // tổng thời gian khóa ban đầu (seconds)
        contract_id: Principal; // canister id của distribution contract
    };
    
    public type DistributionContractRegistry = {
        contractId: Principal;
        projectName: Text;
        addedAt: Time.Time;
        isActive: Bool;
        verifiedBy: Principal; // Who added this contract to whitelist
    };
    
    public type VPSource = {
        contractId: Principal;
        remaining: Nat;
        remainingTime: Nat;
        maxLock: Nat;
        vpCalculated: Nat;
        sourceType: Text;       // "DAO_Staking" or "Distribution_Contract"
    };
    
    public type VotingPowerBreakdown = {
        principal: Principal;
        stakingVP: Nat;         // From direct DAO staking  
        distributionVP: Nat;    // From distribution contracts
        totalVP: Nat;           // stakingVP + distributionVP
        sources: [VPSource];    // Detailed breakdown
    };
    
    public type VotingPowerSnapshot = {
        proposalId: Nat;
        snapshotTime: Time.Time;
        totalParticipants: Nat;
        totalVotingPower: Nat;
        distributionSources: [(Principal, Nat)]; // Contract -> total VP from that contract
        participantVP: [(Principal, VotingPowerBreakdown)];
    };

}
