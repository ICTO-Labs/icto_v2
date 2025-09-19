import type {
    DistributionConfig,
    EligibilityLogic,
    DistributionDetails,
    NFTHolderConfig,
    TokenHolderConfig,
} from '@/types/distribution';
import type {
    MotokoDistributionConfig,
    EligibilityTypeMotoko,
    EligibilityLogicMotoko,
    RecipientModeMotoko,
    VestingScheduleMotoko,
    UnlockFrequencyMotoko,
    FeeStructureMotoko,
    RegistrationPeriodMotoko
} from '@/types/motoko-backend';
import { Principal } from '@dfinity/principal';
import { keyToText } from './common';
import { formatTokenAmount } from './token';

export class DistributionUtils {
    /**
     * Convert frontend DistributionConfig to backend MotokoDistributionConfig
     */
    public static convertToBackendRequest(config: DistributionConfig): MotokoDistributionConfig {
        console.log('config', config);
        // Build the base config object
        const result: any = {
            title: config.title,
            description: config.description,
            isPublic: config.isPublic,
            campaignType: this.convertCampaignType((config as any).campaignType),
            tokenInfo: {
                canisterId: Principal.fromText(config.tokenInfo.canisterId.toString()),
                symbol: config.tokenInfo.symbol,
                name: config.tokenInfo.name,
                decimals: config.tokenInfo.decimals
            },
            totalAmount: formatTokenAmount(config.totalAmount, config.tokenInfo.decimals).toNumber(),
            eligibilityType: this.convertEligibilityType(config.eligibilityType, config),
            recipientMode: this.convertRecipientMode(config.recipientMode),
            vestingSchedule: this.convertVestingSchedule(config.vestingSchedule),
            initialUnlockPercentage: BigInt(config.initialUnlockPercentage),
            penaltyUnlock: config.penaltyUnlock ? [this.convertPenaltyUnlock(config.penaltyUnlock)] : [], // Candid optional
            distributionStart: BigInt(Math.floor(config.distributionStart.getTime()) * 1_000_000), // Convert to nanoseconds
            feeStructure: this.convertFeeStructure(config.feeStructure),
            allowCancel: config.allowCancel,
            allowModification: config.allowModification,
            owner: Principal.fromText(config.owner.toString()),
            recipients: this.buildRecipientsArray(config),
            // registrationPeriod will be handled as Candid optional below
        };

        // Handle optional fields as Candid optionals: null → [], ?value → [value]
        result.eligibilityLogic = config.eligibilityLogic ? [this.convertEligibilityLogic(config.eligibilityLogic)] : [];
        result.maxRecipients = config.maxRecipients ? [BigInt(config.maxRecipients)] : [];

        // Handle registrationPeriod as Candid optional: null → [], ?value → [value]
        if (config.registrationPeriod && config.registrationPeriod.startTime && config.registrationPeriod.endTime) {
            result.registrationPeriod = [this.convertRegistrationPeriod(config.registrationPeriod)];
        } else {
            result.registrationPeriod = [];
        }

        // Handle other optional fields as Candid optionals
        result.distributionEnd = config.distributionEnd ? [BigInt(Math.floor(config.distributionEnd.getTime()) * 1_000_000)] : [];
        result.governance = (config.governance && config.governance.trim()) ? [Principal.fromText(config.governance)] : [];
        result.externalCheckers = (config.externalCheckers && config.externalCheckers.length > 0) ?
            [config.externalCheckers.map(checker => [checker.name, Principal.fromText(checker.canisterId)] as [string, Principal])] :
            [];

        // Handle MultiSig Governance as Candid optional (disabled)
        result.multiSigGovernance = [];

        // Handle LaunchpadContext as Candid optional (null for standalone distributions)
        result.launchpadContext = [];

        return result as MotokoDistributionConfig;
    }

    /**
     * Convert frontend EligibilityType to backend EligibilityTypeMotoko
     */
    private static convertEligibilityType(eligibilityType: string, config: DistributionConfig): EligibilityTypeMotoko {
        switch (eligibilityType) {
            case 'Open':
                return { Open: null };
            
            case 'Whitelist':
                // For whitelist, we get the addresses from recipients array
                const recipients = this.buildRecipientsArray(config);
                const whitelistAddresses = recipients.map(r => r.address);
                return { Whitelist: whitelistAddresses };
            
            case 'TokenHolder':
                const tokenConfig = (config as any).tokenHolderConfig;
                return { 
                    TokenHolder: {
                        canisterId: Principal.fromText(tokenConfig?.canisterId || ''),
                        minAmount: BigInt(tokenConfig?.minAmount || 0),
                        snapshotTime: tokenConfig?.snapshotTime ?
                            BigInt(tokenConfig.snapshotTime.getTime() * 1_000_000) : undefined
                    }
                };
            
            case 'NFTHolder':
                const nftConfig = (config as any).nftHolderConfig;
                return { 
                    NFTHolder: {
                        canisterId: Principal.fromText(nftConfig?.canisterId || ''),
                        minCount: BigInt(nftConfig?.minCount || 1),
                        collections: nftConfig?.collections?.length ? [nftConfig.collections] : []
                    }
                };
            
            case 'BlockIDScore':
                const blockIdScore = (config as any).blockIdScore;
                return { BlockIDScore: BigInt(blockIdScore || 0) };
            
            case 'Hybrid':
                // For now, return simple structure - can be enhanced later
                return { 
                    Hybrid: {
                        conditions: [{ Open: null }], // Default to open condition
                        logic: { AND: null }
                    }
                };
            
            default:
                return { Open: null };
        }
    }

    /**
     * Convert frontend EligibilityLogic to backend EligibilityLogicMotoko
     */
    private static convertEligibilityLogic(logic: EligibilityLogic): EligibilityLogicMotoko {
        switch (keyToText(logic)) {
            case 'AND':
                return { AND: null };
            case 'OR':
                return { OR: null };
            default:
                return { AND: null };
        }
    }

    /**
     * Convert frontend CampaignType to backend CampaignTypeMotoko
     */
    private static convertCampaignType(campaignType: string): any {
        switch (campaignType) {
            case 'Airdrop':
                return { Airdrop: null };
            case 'Vesting':
                return { Vesting: null };
            case 'Lock':
                return { Lock: null };
            default:
                return { Airdrop: null }; // Default to Airdrop
        }
    }

    /**
     * Build unified recipients array from whitelist data
     */
    private static buildRecipientsArray(config: any): any[] {
        // Only build recipients for Whitelist distributions
        if (keyToText(config.eligibilityType) != 'Whitelist') {
            return []; // For Open distributions, recipients are added dynamically or register themselves
        }

        const addresses = (config as any).whitelistAddresses || [];
        if (!Array.isArray(addresses) || addresses.length === 0) {
            console.log('No whitelistAddresses found or empty array');
            return [];
        }

        console.log('Building recipients from addresses:', addresses);
        console.log('Config whitelistAmountType:', (config as any).whitelistAmountType);
        console.log('Config whitelistSameAmount:', (config as any).whitelistSameAmount);

        // Handle both simple string arrays and complex objects with principal/amount
        const recipients = addresses.map((addr: any) => {
            if (typeof addr === 'string') {
                // Simple string format - use default amount
                const amount = formatTokenAmount((config as any).whitelistSameAmount || 0, (config as any).tokenInfo.decimals || 8);
                return {
                    address: Principal.fromText(addr.trim()),
                    amount: amount.toNumber(), // Convert BigNumber to number for Candid nat
                    note: []  // Candid optional: no note
                };
            } else if (addr && typeof addr === 'object' && addr.principal) {
                // Complex object format with principal/amount/note (from Lock campaigns)
                const amount = formatTokenAmount(addr.amount, (config as any).tokenInfo.decimals || 8);
                return {
                    address: Principal.fromText(addr.principal.trim()),
                    amount: amount.toNumber(), // Convert BigNumber to number for Candid nat
                    note: addr.note ? [addr.note] : []  // Candid optional
                };
            }
            console.warn('Invalid address format:', addr);
            return null;
        }).filter((r: any) => r !== null);

        console.log('Built recipients:', recipients);
        return recipients;
    }

    /**
     * Convert frontend RecipientMode to backend RecipientModeMotoko
     */
    private static convertRecipientMode(mode: any): RecipientModeMotoko {
        switch (mode) {
            case 'Fixed':
                return { Fixed: null };
            case 'Dynamic':
                return { Dynamic: null };
            case 'SelfService':
                return { SelfService: null };
            default:
                return { Fixed: null };
        }
    }

    /**
     * Convert frontend RegistrationPeriod to backend RegistrationPeriodMotoko
     */
    private static convertRegistrationPeriod(period: any): RegistrationPeriodMotoko {
        return {
            startTime: BigInt(Math.floor(period.startTime.getTime()) * 1_000_000), // Convert to nanoseconds
            endTime: BigInt(Math.floor(period.endTime.getTime()) * 1_000_000),
            // Handle maxParticipants as Candid optional: null → [], ?value → [value]
            maxParticipants: period.maxParticipants ? [BigInt(period.maxParticipants)] : []
        };
    }

    /**
     * Convert frontend VestingSchedule to backend VestingScheduleMotoko
     */
    private static convertVestingSchedule(schedule: any): VestingScheduleMotoko {
        switch (schedule.type) {
            case 'Instant':
                return { Instant: null };
            
            case 'Linear':
                return {
                    Linear: {
                        duration: BigInt(schedule.config.duration),
                        frequency: this.convertUnlockFrequency(schedule.config.frequency)
                    }
                };
            
            case 'Cliff':
                return {
                    Cliff: {
                        cliffDuration: BigInt(schedule.config.cliffDuration),
                        cliffPercentage: BigInt(schedule.config.cliffPercentage),
                        vestingDuration: BigInt(schedule.config.vestingDuration),
                        frequency: this.convertUnlockFrequency(schedule.config.frequency)
                    }
                };
            
            case 'Single':
                return {
                    Single: {
                        duration: BigInt(schedule.config.duration)
                    }
                };
            
            case 'SteppedCliff':
                return {
                    SteppedCliff: schedule.config.map((step: any) => ({
                        timeOffset: BigInt(step.timeOffset),
                        percentage: BigInt(step.percentage)
                    }))
                };
            
            case 'Custom':
                return {
                    Custom: schedule.config.map((event: any) => ({
                        timestamp: BigInt(Math.floor(event.timestamp.getTime()) * 1_000_000), // Convert to nanoseconds
                        amount: BigInt(event.amount)
                    }))
                };
            
            default:
                return { Instant: null };
        }
    }

    /**
     * Convert frontend PenaltyUnlock to backend PenaltyUnlock
     */
    private static convertPenaltyUnlock(penaltyUnlock: any): any {
        return {
            enableEarlyUnlock: penaltyUnlock.enableEarlyUnlock,
            penaltyPercentage: BigInt(penaltyUnlock.penaltyPercentage || 0),
            penaltyRecipient: penaltyUnlock.penaltyRecipient ? [penaltyUnlock.penaltyRecipient] : [], // Candid optional
            minLockTime: penaltyUnlock.minLockTime ? [BigInt(penaltyUnlock.minLockTime)] : [] // Candid optional
        };
    }

    /**
     * Convert frontend UnlockFrequency to backend UnlockFrequencyMotoko
     */
    private static convertUnlockFrequency(frequency: string): UnlockFrequencyMotoko {
        switch (frequency) {
            case 'Continuous':
                return { Continuous: null };
            case 'Daily':
                return { Daily: null };
            case 'Weekly':
                return { Weekly: null };
            case 'Monthly':
                return { Monthly: null };
            case 'Quarterly':
                return { Quarterly: null };
            case 'Yearly':
                return { Yearly: null };
            default:
                if (typeof frequency === 'number') {
                    return { Custom: BigInt(frequency) };
                }
                return { Monthly: null }; // Default fallback
        }
    }

    /**
     * Convert frontend FeeStructure to backend FeeStructureMotoko
     */
    private static convertFeeStructure(feeStructure: any): FeeStructureMotoko {
        switch (feeStructure.type) {
            case 'Free':
                return { Free: null };
            
            case 'Fixed':
                return { Fixed: BigInt(feeStructure.amount) };
            
            case 'Percentage':
                return { Percentage: BigInt(feeStructure.rate) };
            
            case 'Progressive':
                return {
                    Progressive: feeStructure.tiers.map((tier: any) => ({
                        threshold: BigInt(tier.threshold),
                        feeRate: BigInt(tier.feeRate)
                    }))
                };
            
            case 'RecipientPays':
                return { RecipientPays: null };
            
            case 'CreatorPays':
                return { CreatorPays: null };
            
            default:
                return { Free: null };
        }
    }


    /**
     * Get distribution deployment price from backend
     */
    public static async getDistributionDeployPrice(): Promise<bigint> {
        // Import here to avoid circular dependency
        const { backendService } = await import('@/api/services/backend');
        return backendService.getDeploymentFee('distribution_factory');
    }
}

// ================ DISTRIBUTION STATUS UTILITIES ================

export type DistributionStatus = 'Created' | 'Deployed' | 'Active' | 'Paused' | 'Completed' | 'Cancelled'

/**
 * Get status color classes for distribution status badge
 */
export function getDistributionStatusColor(status: string): string {
  switch (status) {
    case 'Active':
      return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
    case 'Paused':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400'
    case 'Completed':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
    case 'Cancelled':
      return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400'
    case 'Created':
    case 'Deployed':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
    default:
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
  }
}

/**
 * Get status dot color for distribution status indicator
 */
export function getDistributionStatusDotColor(status: string): string {
  switch (status) {
    case 'Active':
      return 'bg-green-400'
    case 'Paused':
      return 'bg-orange-400'
    case 'Completed':
      return 'bg-blue-400'
    case 'Cancelled':
      return 'bg-red-400'
    case 'Created':
    case 'Deployed':
      return 'bg-gray-400'
    default:
      return 'bg-yellow-400'
  }
}

/**
 * Get human-readable status text for distribution status
 */
export function getDistributionStatusText(status: string): string {
  switch (status) {
    case 'Created': return 'Created'
    case 'Deployed': return 'Deployed'
    case 'Active': return 'Active'
    case 'Paused': return 'Paused'
    case 'Completed': return 'Completed'
    case 'Cancelled': return 'Cancelled'
    default: return status
  }
}

/**
 * Check if distribution can be activated
 */
export function canActivateDistribution(status: string, hasEnoughBalance: boolean): boolean {
  return (status === 'Created' || status === 'Deployed') && hasEnoughBalance
}

/**
 * Check if distribution can be paused
 */
export function canPauseDistribution(status: string): boolean {
  return status === 'Active'
}

/**
 * Check if distribution can be resumed
 */
export function canResumeDistribution(status: string): boolean {
  return status === 'Paused'
}

/**
 * Check if distribution can be cancelled
 */
export function canCancelDistribution(status: string, allowCancel: boolean): boolean {
  return allowCancel && status !== 'Completed' && status !== 'Cancelled'
}

/**
 * Check if distribution can be initialized
 */
export function canInitializeDistribution(status: string): boolean {
  return status === 'Created'
}

/**
 * Check if distribution should show insufficient balance alert
 */
export function shouldShowInsufficientBalanceAlert(status: string, hasInsufficientBalance: boolean): boolean {
  if (!hasInsufficientBalance) return false
  return status !== 'Active' && status !== 'Completed' && status !== 'Cancelled'
}

/**
 * Check if distribution is in a final state (completed or cancelled)
 */
export function isDistributionFinalState(status: string): boolean {
  return status === 'Completed' || status === 'Cancelled'
}

/**
 * Check if distribution is active or running
 */
export function isDistributionActive(status: string): boolean {
  return status === 'Active'
}

/**
 * Get distribution state category for grouping
 */
export function getDistributionStateCategory(status: string): 'inactive' | 'active' | 'paused' | 'final' {
  switch (status) {
    case 'Created':
    case 'Deployed':
      return 'inactive'
    case 'Active':
      return 'active'
    case 'Paused':
      return 'paused'
    case 'Completed':
    case 'Cancelled':
      return 'final'
    default:
      return 'inactive'
  }
}