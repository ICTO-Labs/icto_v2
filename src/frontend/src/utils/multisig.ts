// Multisig Utility Functions
import { Principal } from '@dfinity/principal';
import type {
  MultisigWallet,
  Proposal,
  ProposalType,
  AssetType,
  RiskLevel,
  WalletStatus,
  ProposalStatus,
  SignerRole,
  TokenBalance,
  SecurityFlags,
  MultisigFormData,
  WalletConfig
} from '@/types/multisig';

/**
 * Principal validation and formatting
 */
export function isValidPrincipal(principalText: string): boolean {
  try {
    Principal.fromText(principalText);
    return true;
  } catch {
    return false;
  }
}

export function formatPrincipal(principal: Principal | string, length = 8): string {
  try{
    if(!isValidPrincipal(principal as string)) return principal as string;
    else{
      const principalStr = principal.toString();
      if (principalStr.length <= length * 2) return principalStr;
      return `${principalStr.slice(0, length)}...${principalStr.slice(-length)}`;
    }
  } catch {
    return principal as string;
  }
}


export function principalToAccountIdentifier(principal: Principal): string {
  // This would implement the actual account identifier conversion
  // For now, return a placeholder
  return principal.toString();
}

/**
 * Asset type utilities
 */
export function createICPAsset(): AssetType {
  return { ICP: null };
}

export function createTokenAsset(canisterId: string): AssetType {
  return { Token: Principal.fromText(canisterId) };
}

export function createNFTAsset(canisterId: string, tokenId: number): AssetType {
  return { NFT: { canister: Principal.fromText(canisterId), tokenId } };
}

export function formatAssetName(asset: AssetType): string {
  if ('ICP' in asset) return 'ICP';
  if ('Token' in asset) return 'Token';
  if ('NFT' in asset) return 'NFT';
  return 'Unknown';
}

export function getAssetSymbol(asset: AssetType, tokenBalances?: TokenBalance[]): string {
  if ('ICP' in asset) return 'ICP';

  if ('Token' in asset && tokenBalances) {
    const token = tokenBalances.find(t => t.canisterId.toString() === asset.Token.toString());
    return token?.symbol || 'Unknown';
  }

  if ('NFT' in asset) return 'NFT';

  return 'Unknown';
}

/**
 * Amount formatting and parsing
 */
export function formatTokenAmount(
  amount: bigint,
  decimals: number = 8,
  symbol?: string,
  showFullPrecision = false
): string {
  const divisor = BigInt(10 ** decimals);
  const integerPart = amount / divisor;
  const fractionalPart = amount % divisor;

  if (fractionalPart === 0n) {
    return `${integerPart}${symbol ? ' ' + symbol : ''}`;
  }

  let fractionalStr = fractionalPart.toString().padStart(decimals, '0');

  if (!showFullPrecision) {
    fractionalStr = fractionalStr.replace(/0+$/, '');
  }

  return `${integerPart}.${fractionalStr}${symbol ? ' ' + symbol : ''}`;
}

export function parseTokenAmount(amountStr: string, decimals: number = 8): bigint {
  // Remove any non-numeric characters except decimal point
  const cleanStr = amountStr.replace(/[^\d.]/g, '');
  const [integerPart, fractionalPart = ''] = cleanStr.split('.');

  if (!integerPart && !fractionalPart) return 0n;

  const paddedFractional = fractionalPart.padEnd(decimals, '0').slice(0, decimals);
  const integer = integerPart || '0';

  return BigInt(integer) * BigInt(10 ** decimals) + BigInt(paddedFractional);
}

export function formatICPAmount(amount: bigint, showFullPrecision = false): string {
  return formatTokenAmount(amount, 8, 'ICP', showFullPrecision);
}

export function parseICPAmount(amountStr: string): bigint {
  return parseTokenAmount(amountStr, 8);
}

/**
 * Time and duration utilities
 */
export function formatDuration(nanoseconds: bigint): string {
  const ms = Number(nanoseconds / 1000000n);
  const seconds = Math.floor(ms / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (days > 0) return `${days}d ${hours % 24}h`;
  if (hours > 0) return `${hours}h ${minutes % 60}m`;
  if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
  return `${seconds}s`;
}

export function formatTimestamp(nanoseconds: bigint): string {
  const ms = Number(nanoseconds / 1000000n);
  return new Date(ms).toLocaleString();
}

export function hoursToNanoseconds(hours: number): bigint {
  return BigInt(hours * 3600 * 1000000000);
}

export function nanosecondsToHours(nanoseconds: bigint): number {
  return Number(nanoseconds / 3600000000000n);
}

/**
 * Status and role utilities
 */
export function getStatusColor(status: WalletStatus | ProposalStatus): string {
  switch (status) {
    case 'Active':
    case 'Executed':
    case 'Approved':
      return 'success';
    case 'Pending':
    case 'Setup':
      return 'warning';
    case 'Frozen':
    case 'Failed':
    case 'Rejected':
      return 'danger';
    case 'Paused':
    case 'Draft':
    case 'Timelocked':
      return 'info';
    case 'Recovery':
    case 'Deprecated':
    case 'Expired':
    case 'Cancelled':
      return 'secondary';
    default:
      return 'secondary';
  }
}

export function getRiskColor(risk: RiskLevel): string {
  switch (risk) {
    case 'Low': return 'success';
    case 'Medium': return 'warning';
    case 'High': return 'danger';
    case 'Critical': return 'danger';
    default: return 'secondary';
  }
}

export function getRoleIcon(role: SignerRole): string {
  switch (role) {
    case 'Owner': return 'crown';
    case 'Signer': return 'edit';
    case 'Observer': return 'eye';
    case 'Guardian': return 'shield';
    case 'Delegate': return 'users';
    default: return 'user';
  }
}

export function canSignerCreateProposal(role: SignerRole): boolean {
  return ['Owner', 'Signer'].includes(role);
}

export function canSignerSign(role: SignerRole): boolean {
  return ['Owner', 'Signer', 'Guardian'].includes(role);
}

export function canSignerExecute(role: SignerRole): boolean {
  return ['Owner', 'Signer'].includes(role);
}

export function canSignerManage(role: SignerRole): boolean {
  return role === 'Owner';
}

/**
 * Proposal utilities
 */
export function getProposalTypeDisplay(proposalType: ProposalType): string {
  if ('Transfer' in proposalType) return 'Transfer';
  if ('TokenApproval' in proposalType) return 'Token Approval';
  if ('BatchTransfer' in proposalType) return 'Batch Transfer';
  if ('WalletModification' in proposalType) return 'Wallet Modification';
  if ('ContractCall' in proposalType) return 'Contract Call';
  if ('EmergencyAction' in proposalType) return 'Emergency Action';
  if ('SystemUpdate' in proposalType) return 'System Update';
  return 'Unknown';
}

export function getProposalTypeIcon(proposalType: ProposalType): string {
  if ('Transfer' in proposalType) return 'money';
  if ('TokenApproval' in proposalType) return 'key';
  if ('BatchTransfer' in proposalType) return 'list';
  if ('WalletModification' in proposalType) return 'settings';
  if ('ContractCall' in proposalType) return 'code';
  if ('EmergencyAction' in proposalType) return 'warning';
  if ('SystemUpdate' in proposalType) return 'upgrade';
  return 'document';
}

export function isProposalExecutable(proposal: Proposal): boolean {
  return proposal.status === 'Approved' &&
         proposal.currentApprovals >= proposal.requiredApprovals &&
         BigInt(Date.now() * 1000000) < proposal.expiresAt;
}

export function isProposalExpired(proposal: Proposal): boolean {
  return BigInt(Date.now() * 1000000) > proposal.expiresAt;
}

export function canUserSignProposal(proposal: Proposal, userPrincipal: Principal): boolean {
  if (proposal.status !== 'Pending') return false;
  if (isProposalExpired(proposal)) return false;

  // Check if user already signed
  const alreadySigned = proposal.approvals.some(
    approval => approval.signer.toString() === userPrincipal.toString()
  );

  return !alreadySigned;
}

/**
 * Security utilities
 */
export function calculateSecurityScore(flags: SecurityFlags): number {
  let score = 1.0;

  if (flags.suspiciousActivity) score -= 0.3;
  if (flags.rateLimit) score -= 0.1;
  if (flags.geoRestricted) score -= 0.1;
  if (flags.complianceAlert) score -= 0.2;
  if (flags.failedAttempts > 5) score -= 0.2;

  if (flags.autoFreezeEnabled) score += 0.1;
  if (flags.anomalyDetection) score += 0.1;
  if (flags.whitelistOnly) score += 0.1;

  return Math.max(0, Math.min(1, score));
}

export function getSecurityScoreColor(score: number): string {
  if (score >= 0.8) return 'success';
  if (score >= 0.6) return 'warning';
  return 'danger';
}

export function getSecurityScoreText(score: number): string {
  if (score >= 0.9) return 'Excellent';
  if (score >= 0.8) return 'Good';
  if (score >= 0.6) return 'Fair';
  if (score >= 0.4) return 'Poor';
  return 'Critical';
}

/**
 * Validation utilities
 */
export function validateWalletConfig(config: Partial<MultisigFormData>): string[] {
  const errors: string[] = [];

  if (!config.name?.trim()) {
    errors.push('Wallet name is required');
  }

  if (!config.signers?.length) {
    errors.push('At least one signer is required');
  }

  if (config.threshold && config.signers) {
    if (config.threshold < 1) {
      errors.push('Threshold must be at least 1');
    }
    if (config.threshold > config.signers.length) {
      errors.push('Threshold cannot exceed number of signers');
    }
  }

  if (config.signers) {
    const duplicates = config.signers.filter((signer, index, arr) =>
      arr.findIndex(s => s.principal === signer.principal) !== index
    );
    if (duplicates.length > 0) {
      errors.push('Duplicate signers are not allowed');
    }

    const invalidPrincipals = config.signers.filter(signer =>
      !isValidPrincipal(signer.principal)
    );
    if (invalidPrincipals.length > 0) {
      errors.push('Some signer principals are invalid');
    }
  }

  if (config.timelockDuration && config.timelockDuration < 0) {
    errors.push('Timelock duration cannot be negative');
  }

  if (config.dailyLimit && config.dailyLimit < 0) {
    errors.push('Daily limit cannot be negative');
  }

  if (config.maxProposalLifetime && config.maxProposalLifetime < 1) {
    errors.push('Maximum proposal lifetime must be at least 1 hour');
  }

  return errors;
}

export function validateTransferAmount(amount: string, balance: bigint, decimals: number = 8): string[] {
  const errors: string[] = [];

  if (!amount.trim()) {
    errors.push('Amount is required');
    return errors;
  }

  try {
    const parsedAmount = parseTokenAmount(amount, decimals);

    if (parsedAmount <= 0n) {
      errors.push('Amount must be greater than 0');
    }

    if (parsedAmount > balance) {
      errors.push('Amount exceeds available balance');
    }
  } catch (error) {
    errors.push('Invalid amount format');
  }

  return errors;
}

/**
 * URL and navigation utilities
 */
export function getWalletDetailUrl(walletId: string): string {
  return `/multisig/${walletId}`;
}

export function getProposalDetailUrl(walletId: string, proposalId: string): string {
  return `/multisig/${walletId}/proposal/${proposalId}`;
}

/**
 * Export utilities
 */
export function exportWalletData(wallet: MultisigWallet): string {
  return JSON.stringify({
    id: wallet.id,
    name: wallet.config.name,
    description: wallet.config.description,
    threshold: wallet.config.threshold,
    signers: wallet.signers.map(s => ({
      principal: s.principal.toString(),
      name: s.name,
      role: s.role
    })),
    status: wallet.status,
    createdAt: formatTimestamp(wallet.createdAt),
    totalProposals: wallet.totalProposals,
    executedProposals: wallet.executedProposals,
    securityScore: wallet.securityFlags.securityScore
  }, null, 2);
}

export function exportProposalData(proposal: Proposal): string {
  return JSON.stringify({
    id: proposal.id,
    title: proposal.title,
    description: proposal.description,
    type: getProposalTypeDisplay(proposal.proposalType),
    status: proposal.status,
    proposer: proposal.proposer.toString(),
    proposedAt: formatTimestamp(proposal.proposedAt),
    expiresAt: formatTimestamp(proposal.expiresAt),
    requiredApprovals: proposal.requiredApprovals,
    currentApprovals: proposal.currentApprovals,
    risk: proposal.risk,
    approvals: proposal.approvals.map(a => ({
      signer: a.signer.toString(),
      approvedAt: formatTimestamp(a.approvedAt),
      note: a.note
    }))
  }, null, 2);
}

/**
 * Mock data generators (for development)
 */
export function generateMockSignature(): Uint8Array {
  return new Uint8Array(64).map(() => Math.floor(Math.random() * 256));
}

export function generateMockPrincipal(): Principal {
  const randomBytes = new Uint8Array(29).map(() => Math.floor(Math.random() * 256));
  return Principal.fromUint8Array(randomBytes);
}