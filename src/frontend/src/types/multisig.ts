// Types for Multisig Wallets - V2 Architecture
// SOURCE OF TRUTH: All types imported from IDL
import type { Principal } from '@dfinity/principal';

// Import ALL generated types from IDL as the single source of truth
import type {
  MultisigWallet,
  WalletConfig,
  Proposal,
  ProposalType,
  ProposalStatus,
  SignerInfo,
  SignerRole,
  AssetType,
  TransferRequest,
  ProposalFilter,
  WalletModificationType,
  SecurityFlags,
  AssetBalances,
  WalletEvent,
  MultisigContract,
  ProposalResult,
  ProposalError,
  SignatureResult,
  SignatureError,
  ExecutionResult,
  ActionResult,
  BalanceChange,
  EventFilter,
  ProposalApproval,
  ProposalRejection,
  WalletStatus,
  EventSeverity,
  EventType,
  TransactionId,
  SignatureId,
  ProposalId,
  WalletId,
  RiskLevel,
  RiskFactor,
  RiskAssessment,
  ProposalAction,
  EmergencyActionType,
  SystemUpdateType,
  Permission,
  PermissionType,
  AutomationRule,
  TriggerCondition,
  AutomatedAction,
  AssetLimit,
  SecurityEventType,
  ThresholdDirection,
  TokenBalance,
  TokenMetadata,
  TokenStandard,
  NFTBalance,
  NFTStandard
} from '@declarations/multisig_contract/multisig_contract.did';

// Re-export all types
export type {
  MultisigWallet,
  WalletConfig,
  Proposal,
  ProposalType,
  ProposalStatus,
  SignerInfo,
  SignerRole,
  AssetType,
  TransferRequest,
  ProposalFilter,
  WalletModificationType,
  SecurityFlags,
  AssetBalances,
  WalletEvent,
  MultisigContract,
  ProposalResult,
  ProposalError,
  SignatureResult,
  SignatureError,
  ExecutionResult,
  ActionResult,
  BalanceChange,
  EventFilter,
  ProposalApproval,
  ProposalRejection,
  WalletStatus,
  EventSeverity,
  EventType,
  TransactionId,
  SignatureId,
  ProposalId,
  WalletId,
  RiskLevel,
  RiskFactor,
  RiskAssessment,
  ProposalAction,
  EmergencyActionType,
  SystemUpdateType,
  Permission,
  PermissionType,
  AutomationRule,
  TriggerCondition,
  AutomatedAction,
  AssetLimit,
  SecurityEventType,
  ThresholdDirection,
  TokenBalance,
  TokenMetadata,
  TokenStandard,
  NFTBalance,
  NFTStandard
};

// Additional frontend-only types not in IDL

// Extended MultisigWallet with additional frontend fields
export interface ExtendedMultisigWallet extends MultisigWallet {
  metadata?: any; // Additional metadata from backend
}

// Frontend-specific types (not in IDL)
export interface MultisigFormData {
  name: string;
  description: string;
  signers: Array<{
    principal: string;
    name?: string;
    role: SignerRole;
  }>;
  threshold: number;
  requiresTimelock: boolean;
  timelockDuration?: number; // in hours
  dailyLimit?: number;
  allowRecovery: boolean;
  recoveryThreshold?: number;
  allowObservers: boolean;
  requiresConsensusForChanges: boolean;
  maxProposalLifetime: number; // in hours
  emergencyContactDelay?: number; // in hours
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
