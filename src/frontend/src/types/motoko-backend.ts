// Motoko Backend Interface Types - Matching exact backend expectations
import { Principal } from '@dfinity/principal';

// Distribution Configuration for Backend Deployment
export interface MotokoDistributionConfig {
    // Basic Information
    title: string;
    description: string;
    isPublic: boolean;
    
    // Token Configuration
    tokenInfo: {
        canisterId: Principal;
        symbol: string;
        name: string;
        decimals: number;
    };
    totalAmount: bigint;
    
    // Eligibility & Recipients
    eligibilityType: EligibilityTypeMotoko;
    eligibilityLogic?: EligibilityLogicMotoko;
    recipientMode: RecipientModeMotoko;
    maxRecipients?: bigint;
    
    // Vesting Configuration
    vestingSchedule: VestingScheduleMotoko;
    initialUnlockPercentage: bigint;
    
    // Timing
    registrationPeriod?: RegistrationPeriodMotoko;
    distributionStart: bigint;  // nanoseconds timestamp
    distributionEnd?: bigint;   // nanoseconds timestamp
    
    // Fees & Permissions
    feeStructure: FeeStructureMotoko;
    allowCancel: boolean;
    allowModification: boolean;
    
    // Owner & Governance
    owner: Principal;
    governance?: Principal;
    
    // External Integrations
    externalCheckers?: Array<[string, Principal]>;  // (name, principal) tuples
}

// Eligibility Types matching Motoko backend exactly
export type EligibilityTypeMotoko = 
    | { Open: null }
    | { Whitelist: Principal[] }
    | { TokenHolder: TokenHolderConfigMotoko }
    | { NFTHolder: NFTHolderConfigMotoko }
    | { BlockIDScore: bigint }
    | { Hybrid: { conditions: EligibilityTypeMotoko[], logic: EligibilityLogicMotoko } };

export type EligibilityLogicMotoko = 
    | { AND: null }
    | { OR: null };

export interface TokenHolderConfigMotoko {
    canisterId: Principal;
    minAmount: bigint;
    snapshotTime?: bigint;  // nanoseconds timestamp
}

export interface NFTHolderConfigMotoko {
    canisterId: Principal;
    minCount: bigint;
    collections?: string[];
}

export type RecipientModeMotoko = 
    | { Fixed: null }
    | { Dynamic: null }
    | { SelfService: null };

export interface RegistrationPeriodMotoko {
    startTime: bigint;
    endTime: bigint;
    maxParticipants?: bigint;
}

// Vesting Schedule matching Motoko backend exactly
export type VestingScheduleMotoko = 
    | { Instant: null }
    | { Linear: { duration: bigint, frequency: UnlockFrequencyMotoko } }
    | { Cliff: { cliffDuration: bigint, cliffPercentage: bigint, vestingDuration: bigint, frequency: UnlockFrequencyMotoko } }
    | { SteppedCliff: Array<{ timeOffset: bigint, percentage: bigint }> }
    | { Custom: Array<{ timestamp: bigint, amount: bigint }> };

export type UnlockFrequencyMotoko = 
    | { Continuous: null }
    | { Daily: null }
    | { Weekly: null }
    | { Monthly: null }
    | { Quarterly: null }
    | { Yearly: null }
    | { Custom: bigint };

// Fee Structure matching Motoko backend exactly
export type FeeStructureMotoko = 
    | { Free: null }
    | { Fixed: bigint }
    | { Percentage: bigint }
    | { Progressive: Array<{ threshold: bigint, feeRate: bigint }> }
    | { RecipientPays: null }
    | { CreatorPays: null };

// Deployment Result
export interface DeploymentResultMotoko {
    distributionCanisterId: Principal;
}