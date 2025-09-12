// Import shared DAO types to avoid duplication
import DAOTypes "../shared/types/DAOTypes";

module Types {
    // Re-export all types from the shared module for backward compatibility
    public type Result<T, E> = DAOTypes.Result<T, E>;
    public type Account = DAOTypes.Account;
    public type Tokens = DAOTypes.Tokens;
    public type StakeRecord = DAOTypes.StakeRecord;
    public type StakeAction = DAOTypes.StakeAction;
    public type VotingPowerCalculation = DAOTypes.VotingPowerCalculation;
    public type Proposal = DAOTypes.Proposal;
    public type ProposalPayload = DAOTypes.ProposalPayload;
    public type MotionPayload = DAOTypes.MotionPayload;
    public type CallExternalPayload = DAOTypes.CallExternalPayload;
    public type TokenManagePayload = DAOTypes.TokenManagePayload;
    public type SystemUpdatePayload = DAOTypes.SystemUpdatePayload;
    public type ProposalState = DAOTypes.ProposalState;
    public type Vote = DAOTypes.Vote;
    public type VoteArgs = DAOTypes.VoteArgs;
    public type VoteRecord = DAOTypes.VoteRecord;
    public type TokenConfig = DAOTypes.TokenConfig;
    public type TokenConfigUpdate = DAOTypes.TokenConfigUpdate;
    public type TransferArgs = DAOTypes.TransferArgs;
    public type UpdateSystemParamsPayload = DAOTypes.UpdateSystemParamsPayload;
    public type EmergencyAction = DAOTypes.EmergencyAction;
    public type SystemParams = DAOTypes.SystemParams;
    public type BasicDaoStableStorage = DAOTypes.BasicDaoStableStorage;
    public type EmergencyState = DAOTypes.EmergencyState;
    public type DAOStats = DAOTypes.DAOStats;
    public type MemberInfo = DAOTypes.MemberInfo;
    public type ProposalInfo = DAOTypes.ProposalInfo;
    public type DAOConfig = DAOTypes.DAOConfig;
    public type ExternalDeployerArgs = DAOTypes.ExternalDeployerArgs;
    public type DeploymentResult = DAOTypes.DeploymentResult;
    public type DAODeploymentSummary = DAOTypes.DAODeploymentSummary;
    public type CustomSecurityParams = DAOTypes.CustomSecurityParams;
    public type GovernanceLevel = DAOTypes.GovernanceLevel;
    public type ProposalTimer = DAOTypes.ProposalTimer;
    public type ProposalTimerType = DAOTypes.ProposalTimerType;
    public type DelegationTimer = DAOTypes.DelegationTimer;
    public type SecurityEventType = DAOTypes.SecurityEventType;
    public type SecuritySeverity = DAOTypes.SecuritySeverity;
    public type RateLimitRecord = DAOTypes.RateLimitRecord;
    public type SecurityEvent = DAOTypes.SecurityEvent;
    public type ProposalExecutionContext = DAOTypes.ProposalExecutionContext;
    public type ProposalComment = DAOTypes.ProposalComment;
    public type CommentAction = DAOTypes.CommentAction;
    public type DelegationRecord = DAOTypes.DelegationRecord;
    public type UserStakeProfile = DAOTypes.UserStakeProfile;
    public type StakeEntry = DAOTypes.StakeEntry;
    public type TimelineEntry = DAOTypes.TimelineEntry;
    public type TimelineAction = DAOTypes.TimelineAction;
    public type StakingSummary = DAOTypes.StakingSummary;
    
    // NEW: Distribution voting power types - BACKWARD COMPATIBLE
    public type DistributionSnapshotEntry = DAOTypes.DistributionSnapshotEntry;
    public type DistributionContractRegistry = DAOTypes.DistributionContractRegistry;
    public type VPSource = DAOTypes.VPSource;
    public type VotingPowerBreakdown = DAOTypes.VotingPowerBreakdown;
    public type VotingPowerSnapshot = DAOTypes.VotingPowerSnapshot;
    // Re-export utility functions
    public let proposal_key = DAOTypes.proposal_key;
    public let account_key = DAOTypes.account_key;
    public let stake_key = DAOTypes.stake_key;
    public let accounts_fromArray = DAOTypes.accounts_fromArray;
    public let proposals_fromArray = DAOTypes.proposals_fromArray;
    public let stakes_fromArray = DAOTypes.stakes_fromArray;
    public let delegations_fromArray = DAOTypes.delegations_fromArray;
    public let comments_fromArray = DAOTypes.comments_fromArray;
    public let toFactoryInitArgs = DAOTypes.toFactoryInitArgs;
    public let comment_key = DAOTypes.comment_key;

    // Re-export constants
    public let E8S = DAOTypes.E8S;
    public let oneToken = DAOTypes.oneToken;
    public let zeroToken = DAOTypes.zeroToken;
    public let BASE_MULTIPLIER = DAOTypes.BASE_MULTIPLIER;
    public let MAX_LOCK_MULTIPLIER = DAOTypes.MAX_LOCK_MULTIPLIER;
    public let SECONDS_PER_YEAR = DAOTypes.SECONDS_PER_YEAR;
    public let DEFAULT_QUORUM_PERCENTAGE = DAOTypes.DEFAULT_QUORUM_PERCENTAGE;
    public let DEFAULT_APPROVAL_THRESHOLD = DAOTypes.DEFAULT_APPROVAL_THRESHOLD;
    public let DEFAULT_TIMELOCK_DURATION = DAOTypes.DEFAULT_TIMELOCK_DURATION;
    public let DEFAULT_VOTING_PERIOD = DAOTypes.DEFAULT_VOTING_PERIOD;
    public let DEFAULT_MIN_VOTING_PERIOD = DAOTypes.DEFAULT_MIN_VOTING_PERIOD;
    public let BASIS_POINTS = DAOTypes.BASIS_POINTS;
}