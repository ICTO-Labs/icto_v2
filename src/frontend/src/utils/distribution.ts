import type { DistributionConfig, EligibilityType, EligibilityLogic } from '@/types/distribution';
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

export class DistributionUtils {
    /**
     * Convert frontend DistributionConfig to backend MotokoDistributionConfig
     */
    public static convertToBackendRequest(config: DistributionConfig): MotokoDistributionConfig {
        // Build the base config object
        const result: any = {
            title: config.title,
            description: config.description,
            isPublic: config.isPublic,
            campaignType: this.convertCampaignType((config as any).campaignType),
            tokenInfo: {
                canisterId: Principal.fromText(config.tokenInfo.canisterId),
                symbol: config.tokenInfo.symbol,
                name: config.tokenInfo.name,
                decimals: config.tokenInfo.decimals
            },
            totalAmount: BigInt(config.totalAmount),
            eligibilityType: this.convertEligibilityType(config.eligibilityType, config),
            recipientMode: this.convertRecipientMode(config.recipientMode),
            vestingSchedule: this.convertVestingSchedule(config.vestingSchedule),
            initialUnlockPercentage: BigInt(config.initialUnlockPercentage),
            distributionStart: BigInt(config.distributionStart.getTime() * 1_000_000), // Convert to nanoseconds
            feeStructure: this.convertFeeStructure(config.feeStructure),
            allowCancel: config.allowCancel,
            allowModification: config.allowModification,
            owner: Principal.fromText(config.owner),
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
        result.distributionEnd = config.distributionEnd ? [BigInt(config.distributionEnd.getTime() * 1_000_000)] : [];
        result.governance = (config.governance && config.governance.trim()) ? [Principal.fromText(config.governance)] : [];
        result.externalCheckers = (config.externalCheckers && config.externalCheckers.length > 0) ? 
            [config.externalCheckers.map(checker => [checker.name, Principal.fromText(checker.canisterId)] as [string, Principal])] : 
            [];

        return result as MotokoDistributionConfig;
    }

    /**
     * Convert frontend EligibilityType to backend EligibilityTypeMotoko
     */
    private static convertEligibilityType(eligibilityType: EligibilityType, config: DistributionConfig): EligibilityTypeMotoko {
        switch (eligibilityType) {
            case 'Open':
                return { Open: null };
            
            case 'Whitelist':
                // For whitelist, just return the marker - recipients are handled separately
                return { Whitelist: null };
            
            case 'TokenHolder':
                const tokenConfig = (config as any).tokenHolderConfig;
                return { 
                    TokenHolder: {
                        canisterId: Principal.fromText(tokenConfig?.canisterId || ''),
                        minAmount: BigInt(tokenConfig?.minAmount || 0),
                        snapshotTime: tokenConfig?.snapshotTime ? 
                            [BigInt(tokenConfig.snapshotTime.getTime() * 1_000_000)] : []
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
        switch (logic) {
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
    private static buildRecipientsArray(config: DistributionConfig): any[] {
        // Only build recipients for Whitelist distributions
        if (config.eligibilityType !== 'Whitelist') {
            return []; // For Open distributions, recipients are added dynamically
        }

        const addresses = (config as any).whitelistAddresses || [];
        if (!Array.isArray(addresses) || addresses.length === 0) {
            return [];
        }

        // Handle both simple string arrays and complex objects with principal/amount
        const recipients = addresses.map((addr: any) => {
            if (typeof addr === 'string') {
                // Simple string format - use default amount
                return {
                    address: Principal.fromText(addr.trim()),
                    amount: BigInt((config as any).whitelistSameAmount || 0),
                    note: []  // Candid optional: no note
                };
            } else if (addr && typeof addr === 'object' && addr.principal) {
                // Complex object format with principal/amount/note
                return {
                    address: Principal.fromText(addr.principal.trim()),
                    amount: BigInt(addr.amount || 0),
                    note: addr.note ? [addr.note] : []  // Candid optional
                };
            }
            return null;
        }).filter((r: any) => r !== null);

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
            startTime: BigInt(period.startTime.getTime() * 1_000_000), // Convert to nanoseconds
            endTime: BigInt(period.endTime.getTime() * 1_000_000),
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
                        timestamp: BigInt(event.timestamp.getTime() * 1_000_000), // Convert to nanoseconds
                        amount: BigInt(event.amount)
                    }))
                };
            
            default:
                return { Instant: null };
        }
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