// Multisig Types and Interfaces

export interface MultisigWallet {
  id: string;
  name: string;
  description?: string;
  threshold: number; // M signatures required
  totalSigners: number; // N total signers
  signers: string[]; // Principal IDs
  signerDetails: SignerInfo[];
  balance: WalletBalance;
  createdAt: Date;
  lastActivity: Date;
  status: 'active' | 'frozen' | 'pending_setup';
  canisterId: string;
  cyclesBalance?: bigint;
}

export interface SignerInfo {
  principal: string;
  name: string;
  email?: string;
  role: 'owner' | 'signer' | 'observer';
  addedAt: Date;
  lastSeen?: Date;
  isOnline: boolean;
  avatar?: string;
}

export interface WalletBalance {
  icp: number;
  tokens: TokenBalance[];
  totalUsdValue?: number;
}

export interface TokenBalance {
  symbol: string;
  name: string;
  amount: number;
  decimals: number;
  canisterId: string;
  usdValue?: number;
  logo?: string;
}

export interface TransactionProposal {
  id: string;
  walletId: string;
  type: ProposalType;
  title: string;
  description: string;
  proposer: string;
  proposerName?: string;
  proposedAt: Date;
  expiresAt: Date;
  status: ProposalStatus;
  requiredSignatures: number;
  currentSignatures: number;
  signatures: ProposalSignature[];
  transactionData: TransactionData;
  estimatedFee?: number;
  executedAt?: Date;
  executionResult?: string;
  executionTxId?: string;
}

export type ProposalType = 
  | 'transfer' 
  | 'token_transfer' 
  | 'canister_call' 
  | 'batch' 
  | 'governance_vote'
  | 'add_signer'
  | 'remove_signer'
  | 'change_threshold';

export type ProposalStatus = 
  | 'draft' 
  | 'pending' 
  | 'approved' 
  | 'rejected' 
  | 'executed' 
  | 'expired'
  | 'failed';

export interface ProposalSignature {
  signer: string;
  signerName?: string;
  signedAt: Date;
  signature: string;
  note?: string;
}

export interface TransactionData {
  // For transfers
  recipient?: string;
  amount?: number;
  token?: string;
  memo?: string;
  
  // For canister calls
  canisterId?: string;
  method?: string;
  args?: any;
  
  // For batch operations
  operations?: TransactionData[];
  
  // For governance
  proposalId?: string;
  vote?: 'yes' | 'no' | 'abstain';
  
  // For signer management
  targetSigner?: string;
  newThreshold?: number;
}

// Activity Types
export interface MultisigActivity {
  id: string;
  walletId: string;
  walletName: string;
  type: ActivityType;
  title: string;
  description?: string;
  timestamp: Date;
  actor: string;
  actorName?: string;
  details?: any;
}

export type ActivityType = 
  | 'wallet_created'
  | 'proposal_created'
  | 'proposal_signed'
  | 'proposal_executed'
  | 'proposal_rejected'
  | 'signer_added'
  | 'signer_removed'
  | 'threshold_changed'
  | 'tokens_received'
  | 'tokens_sent'
  | 'funds_received'
  | 'funds_sent';

// Filter and Sort Types
export interface MultisigFilters {
  status?: MultisigWallet['status'][];
  searchQuery?: string;
  dateRange?: {
    start: Date;
    end: Date;
  };
}

export interface ProposalFilters {
  status?: ProposalStatus[];
  type?: ProposalType[];
  walletId?: string;
  searchQuery?: string;
  dateRange?: {
    start: Date;
    end: Date;
  };
}

// Statistics
export interface MultisigStats {
  totalWallets: number;
  activeWallets: number;
  totalValueLocked: number;
  pendingProposals: number;
  executedProposals: number;
  totalSigners: number;
}
