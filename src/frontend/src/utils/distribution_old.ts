import type { DistributionConfig, EligibilityType, EligibilityLogic } from '@/types/distribution';
import type { 
    DistributionDeploymentRequest, 
    VestingScheduleBackend, 
    UnlockFrequencyBackend, 
    FeeStructureBackend,
    DistributionTokenInfo,
    EligibilityTypeBackend,
    EligibilityLogicBackend,
    TokenHolderConfigBackend,
    NFTHolderConfigBackend,
    RegistrationPeriodBackend
} from '@/types/backend';
import { Principal } from '@dfinity/principal';

export class DistributionUtils {
    /**
     * Convert frontend DistributionConfig to backend DistributionDeploymentRequest
     */
    public static convertToBackendRequest(config: DistributionConfig): DistributionDeploymentRequest {
        return {
            title: config.title,
            description: config.description,
            isPublic: config.isPublic,
            tokenInfo: {
                canisterId: Principal.fromText(config.tokenInfo.canisterId),
                symbol: config.tokenInfo.symbol,
                name: config.tokenInfo.name,
                decimals: config.tokenInfo.decimals
            },
            totalAmount: BigInt(config.totalAmount),
            eligibilityType: this.convertEligibilityType(config.eligibilityType, config),
            eligibilityLogic: config.eligibilityLogic ? this.convertEligibilityLogic(config.eligibilityLogic) : undefined,
            recipientMode: this.convertRecipientMode(config.recipientMode),
            maxRecipients: config.maxRecipients ? BigInt(config.maxRecipients) : undefined,
            vestingSchedule: this.convertVestingSchedule(config.vestingSchedule),
            initialUnlockPercentage: BigInt(config.initialUnlockPercentage),
            registrationPeriod: config.registrationPeriod ? this.convertRegistrationPeriod(config.registrationPeriod) : undefined,
            distributionStart: BigInt(config.distributionStart.getTime() * 1_000_000), // Convert to nanoseconds
            distributionEnd: config.distributionEnd ? BigInt(config.distributionEnd.getTime() * 1_000_000) : undefined,
            feeStructure: this.convertFeeStructure(config.feeStructure),
            allowCancel: config.allowCancel,
            allowModification: config.allowModification,
            owner: config.owner,
            governance: config.governance || undefined,
            externalCheckers: config.externalCheckers ? 
                config.externalCheckers.map(checker => [checker.name, checker.canisterId] as [string, string]) : 
                undefined
        };
    }

    /**
     * Convert frontend EligibilityType to backend EligibilityTypeBackend
     */
    private static convertEligibilityType(eligibilityType: EligibilityType, config: DistributionConfig): EligibilityTypeBackend {
        switch (eligibilityType) {
            case 'Open':
                return { Open: null };
            
            case 'Whitelist':
                // Convert whitelist addresses to Principal strings
                const addresses = (config as any).whitelistAddresses || [];
                if (Array.isArray(addresses) && addresses.length > 0) {
                    // Handle both simple string arrays and complex objects with principal/amount
                    const principals = addresses.map(addr => {
                        if (typeof addr === 'string') {
                            return addr.trim();
                        } else if (addr && typeof addr === 'object' && addr.principal) {
                            return addr.principal.trim();
                        }
                        return '';
                    }).filter(p => p.length > 0);
                    return { Whitelist: principals };
                }
                return { Whitelist: [] };
            
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
                        collections: nftConfig?.collections?.length ? nftConfig.collections : undefined
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
     * Convert frontend EligibilityLogic to backend EligibilityLogicBackend
     */
    private static convertEligibilityLogic(logic: EligibilityLogic): EligibilityLogicBackend {
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
     * Convert frontend RecipientMode to backend RecipientModeBackend
     */
    private static convertRecipientMode(mode: any) {
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
     * Convert frontend RegistrationPeriod to backend RegistrationPeriodBackend
     */
    private static convertRegistrationPeriod(period: any): RegistrationPeriodBackend {
        return {
            startTime: BigInt(period.startTime.getTime() * 1_000_000), // Convert to nanoseconds
            endTime: BigInt(period.endTime.getTime() * 1_000_000),
            maxParticipants: period.maxParticipants ? BigInt(period.maxParticipants) : undefined
        };
    }

    /**
     * Convert frontend VestingSchedule to backend VestingScheduleBackend
     */
    private static convertVestingSchedule(schedule: any): VestingScheduleBackend {
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
     * Convert frontend UnlockFrequency to backend UnlockFrequencyBackend
     */
    private static convertUnlockFrequency(frequency: string): UnlockFrequencyBackend {
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
     * Convert frontend FeeStructure to backend FeeStructureBackend
     */
    private static convertFeeStructure(feeStructure: any): FeeStructureBackend {
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