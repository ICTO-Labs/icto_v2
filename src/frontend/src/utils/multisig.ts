// Multisig Utility Functions
import { Principal } from '@dfinity/principal';
import { formatTimeAgo } from '@/utils/dateFormat';
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
 * Status normalization utility - Handle both string and object status formats
 */
export function normalizeStatus(status: any): string {
    if (!status) return 'unknown'

    if (typeof status === 'string') {
        return status.toLowerCase()
    }

    if (typeof status === 'object') {
        // Handle Motoko variant objects
        if ('Pending' in status) return 'pending'
        if ('Approved' in status) return 'approved'
        if ('Executed' in status) return 'executed'
        if ('Failed' in status) return 'failed'
        if ('Rejected' in status) return 'rejected'
        if ('Expired' in status) return 'expired'
    }

    return String(status).toLowerCase()
}

/**
 * Safe timestamp formatter for proposals that handles both BigInt and other formats
 */
export function safeFormatTimeAgo(timestamp: any): string {
    if (!timestamp) {
        console.log('safeFormatTimeAgo: No timestamp provided')
        return 'Unknown'
    }

    try {
        let timeValue: number

        console.log('safeFormatTimeAgo input:', timestamp, 'type:', typeof timestamp)

        if (timestamp instanceof Date) {
            timeValue = timestamp.getTime()
        } else if (typeof timestamp === 'bigint') {
            // Convert nanoseconds to milliseconds
            timeValue = Number(timestamp) / 1000000
        } else if (typeof timestamp === 'number') {
            // If timestamp looks like nanoseconds, convert to milliseconds
            timeValue = timestamp > 1e12 ? timestamp / 1000000 : timestamp
        } else if (typeof timestamp === 'string') {
            const parsed = new Date(timestamp)
            timeValue = parsed.getTime()
        } else if (typeof timestamp === 'object') {
            // Handle possible object format from Motoko
            console.log('Timestamp is object:', timestamp)
            // Try to extract time from object properties
            const timeField = timestamp.time || timestamp.timestamp || timestamp.value
            if (timeField) {
                return safeFormatTimeAgo(timeField)
            }
            return 'Unknown'
        } else {
            console.log('Unknown timestamp format:', typeof timestamp)
            return 'Unknown'
        }

        console.log('Converted timeValue:', timeValue)

        if (isNaN(timeValue) || timeValue <= 0) {
            console.log('Invalid timeValue:', timeValue)
            return 'Unknown'
        }

        const result = formatTimeAgo(timeValue)
        console.log('formatTimeAgo result:', result)
        return result
    } catch (error) {
        console.error('Error formatting time:', error, 'timestamp was:', timestamp)
        return 'Unknown'
    }
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

/**
 * Proposal data extraction utilities - Extract detailed information from proposal actions
 */

/**
 * Extract data from multiple possible paths in Motoko variant structures
 */
export function extractFromMultiplePaths(obj: any, paths: string[]): any {
    // First, try to extract from Motoko variant structure
    if (obj && typeof obj === 'object' && !Array.isArray(obj)) {
        const keys = Object.keys(obj)
        if (keys.length === 1) {
            const variantKey = keys[0]
            const variantValue = obj[variantKey]
            
            if (variantKey === 'Transfer' && typeof variantValue === 'object') {
                for (const path of paths) {
                    const field = path.split('.').pop()
                    if (variantValue[field]) {
                        return variantValue[field]
                    }
                }
                return variantValue
            }
            if (variantKey === 'WalletModification' && typeof variantValue === 'object') {
                for (const path of paths) {
                    const field = path.split('.').pop()
                    if (variantValue[field]) {
                        return variantValue[field]
                    }
                }
                return variantValue
            }
            return variantValue
        }
    }
    
    // Fallback to original path-based extraction
    for (const path of paths) {
        const keys = path.split('.')
        let current = obj
        let found = true
        
        for (const key of keys) {
            if (current && typeof current === 'object' && key in current) {
                current = current[key]
            } else {
                found = false
                break
            }
        }
        
        if (found && current !== undefined && current !== null) {
            return current
        }
    }
    
    return null
}

/**
 * Get proposal type key from actions array or fallback paths
 */
export function getProposalTypeKey(proposal: any): string {
    // First check if proposal has actions array (from debug image structure)
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                return 'transfer'
            } else if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modType = Object.keys(modData.modificationType)[0]
                    switch (modType) {
                        case 'AddSigner': return 'add_signer'
                        case 'RemoveSigner': return 'remove_signer'
                        case 'AddObserver': return 'add_observer'
                        case 'RemoveObserver': return 'remove_observer'
                        case 'ChangeVisibility': return 'change_visibility'
                        case 'ChangeThreshold': return 'threshold_changed'
                        case 'GovernanceVote': return 'governance_vote'
                    }
                }
            }
        }
    }
    
    // Fallback to original logic
    if (proposal.type) {
        return proposal.type.toLowerCase()
    }
    
    if (proposal.proposalType) {
        if ('Transfer' in proposal.proposalType) return 'transfer'
        if ('WalletModification' in proposal.proposalType) {
            const modData = proposal.proposalType.WalletModification
            if (modData.modificationType) {
                const modType = Object.keys(modData.modificationType)[0]
                switch (modType) {
                    case 'AddSigner': return 'add_signer'
                    case 'RemoveSigner': return 'remove_signer'
                    case 'AddObserver': return 'add_observer'
                    case 'RemoveObserver': return 'remove_observer'
                    case 'ChangeVisibility': return 'change_visibility'
                    case 'ChangeThreshold': return 'threshold_changed'
                    case 'GovernanceVote': return 'governance_vote'
                }
            }
        }
    }
    
    return 'unknown'
}

/**
 * Extract transfer amount and asset from proposal
 */
export function getTransferAmount(proposal: any): { amount: bigint | number | null, asset: any } {
    let amount = null
    let asset = null
    
    // Check if proposal has actions array (from debug image structure)
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                const transferData = firstAction.actionType.Transfer
                amount = transferData.amount
                asset = transferData.asset
            }
        }
    }
    
    // Fallback logic if not found in actions
    if (!amount) {
        amount = extractFromMultiplePaths(proposal, [
            'proposalType.Transfer.amount',
            'transactionData.amount',
            'amount'
        ])
    }
    
    if (!asset) {
        asset = extractFromMultiplePaths(proposal, [
            'proposalType.Transfer.asset',
            'transactionData.asset',
            'asset'
        ])
    }
    
    return { amount, asset }
}

/**
 * Extract transfer recipient from proposal
 */
export function getTransferRecipient(proposal: any): any {
    let recipient = null
    
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                const transferData = firstAction.actionType.Transfer
                recipient = transferData.recipient || transferData.to
            }
        }
    }
    
    // Fallback logic if not found in actions
    if (!recipient) {
        recipient = extractFromMultiplePaths(proposal, [
            'proposalType.Transfer.recipient',
            'proposalType.Transfer.to',
            'transactionData.to',
            'transactionData.recipient',
            'to',
            'recipient'
        ])
    }
    
    return recipient
}

/**
 * Extract target from wallet modification proposals
 */
export function getModificationTarget(proposal: any): any {
    let target = null
    
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    const modTypeData = modData.modificationType[modTypeKey]
                    
                    if (modTypeKey === 'AddSigner' || modTypeKey === 'RemoveSigner') {
                        target = modTypeData.signer
                    } else if (modTypeKey === 'AddObserver' || modTypeKey === 'RemoveObserver') {
                        target = modTypeData.observer
                    } else {
                        target = modTypeData.target || modTypeData.principal
                    }
                }
                if (!target) {
                    target = modData.target || modData.principal
                }
            }
        }
    }
    
    // Fallback logic if not found in actions
    if (!target) {
        target = extractFromMultiplePaths(proposal, [
            'proposalType.WalletModification.modificationType.AddSigner.signer',
            'proposalType.WalletModification.modificationType.RemoveSigner.signer',
            'proposalType.WalletModification.modificationType.AddObserver.observer',
            'proposalType.WalletModification.modificationType.RemoveObserver.observer',
            'proposalType.WalletModification.target',
            'proposalType.WalletModification.principal',
            'transactionData.targetSigner',
            'transactionData.target',
            'targetSigner',
            'target'
        ])
    }
    
    return target
}

/**
 * Extract signer name from AddSigner/RemoveSigner proposals
 */
export function getSignerName(proposal: any): string | null {
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    const modTypeData = modData.modificationType[modTypeKey]
                    if (['AddSigner', 'RemoveSigner', 'AddObserver', 'RemoveObserver'].includes(modTypeKey)) {
                        if (modTypeData.name && Array.isArray(modTypeData.name) && modTypeData.name.length > 0) {
                            return modTypeData.name[0]
                        }
                    }
                }
            }
        }
    }
    
    // Fallback
    return extractFromMultiplePaths(proposal, [
        'proposalType.WalletModification.modificationType.AddSigner.name[0]',
        'proposalType.WalletModification.modificationType.RemoveSigner.name[0]',
        'transactionData.targetSignerName[0]',
        'targetSignerName[0]'
    ])
}

/**
 * Extract signer role from AddSigner proposals
 */
export function getSignerRole(proposal: any): string | null {
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    if (modTypeKey === 'AddSigner') {
                        const signerData = modData.modificationType.AddSigner
                        if (signerData.role && typeof signerData.role === 'object') {
                            return Object.keys(signerData.role)[0]
                        }
                    }
                }
            }
        }
    }
    
    // Fallback
    const role = extractFromMultiplePaths(proposal, [
        'proposalType.WalletModification.modificationType.AddSigner.role',
        'transactionData.role'
    ])
    
    if (role && typeof role === 'object') {
        return Object.keys(role)[0]
    }
    
    return role
}

/**
 * Extract visibility change from ChangeVisibility proposals
 */
export function getVisibilityChange(proposal: any): boolean | null {
    let visibility = null
    
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    if (modTypeKey === 'ChangeVisibility') {
                        const visibilityData = modData.modificationType.ChangeVisibility
                        // From debug image: ChangeVisibility: {isPublic: true}
                        visibility = visibilityData.isPublic
                    }
                }
            }
        }
    }
    
    // Fallback
    if (visibility === null) {
        visibility = extractFromMultiplePaths(proposal, [
            'proposalType.WalletModification.modificationType.ChangeVisibility.isPublic',
            'proposalType.WalletModification.modificationType.ChangeVisibility.newVisibility',
            'proposalType.WalletModification.modificationType.ChangeVisibility.visibility',
            'transactionData.newVisibility',
            'transactionData.visibility',
            'newVisibility',
            'visibility'
        ])
    }
    
    return visibility
}

/**
 * Extract threshold change from ChangeThreshold proposals
 */
export function getThresholdChange(proposal: any): { newThreshold: number | null, oldThreshold: number | null } {
    let newThreshold = null
    let oldThreshold = null
    
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'WalletModification') {
                const modData = firstAction.actionType.WalletModification
                if (modData.modificationType) {
                    const modTypeKey = Object.keys(modData.modificationType)[0]
                    if (modTypeKey === 'ChangeThreshold') {
                        const thresholdData = modData.modificationType.ChangeThreshold
                        newThreshold = thresholdData.newThreshold
                        oldThreshold = thresholdData.oldThreshold
                    }
                }
            }
        }
    }
    
    // Fallback
    if (newThreshold === null) {
        newThreshold = extractFromMultiplePaths(proposal, [
            'proposalType.WalletModification.modificationType.ChangeThreshold.newThreshold',
            'transactionData.newThreshold',
            'newThreshold'
        ])
    }
    
    if (oldThreshold === null) {
        oldThreshold = extractFromMultiplePaths(proposal, [
            'proposalType.WalletModification.modificationType.ChangeThreshold.oldThreshold',
            'transactionData.oldThreshold',
            'oldThreshold'
        ])
    }
    
    return { newThreshold, oldThreshold }
}

/**
 * Format transfer memo from proposal
 */
export function getTransferMemo(proposal: any): string | null {
    let memo = null
    
    // Check if proposal has actions array
    if (proposal.actions && Array.isArray(proposal.actions) && proposal.actions.length > 0) {
        const firstAction = proposal.actions[0]
        if (firstAction.actionType && typeof firstAction.actionType === 'object') {
            const variantKey = Object.keys(firstAction.actionType)[0]
            if (variantKey === 'Transfer') {
                const transferData = firstAction.actionType.Transfer
                memo = transferData.memo
            }
        }
    }
    
    // Fallback
    if (!memo) {
        memo = extractFromMultiplePaths(proposal, [
            'proposalType.Transfer.memo',
            'transactionData.memo',
            'memo'
        ])
    }
    
    // Handle array format
    if (Array.isArray(memo) && memo.length > 0) {
        return memo[0]
    }
    
    return memo
}