/**
 * TypeConverter - Converts between Frontend Vue types and Backend Motoko types
 * Handles the complex type mapping for launchpad data
 */
import { Principal } from '@dfinity/principal'
import type { LaunchpadFormData } from '../services/LaunchpadService'

export class TypeConverter {
  /**
   * Safely convert value to BigInt using Distribution pattern
   */
  private static toBigInt(value: any): bigint {
    if (value === '' || value === null || value === undefined) {
      return BigInt(0)
    }

    let num: number
    if (typeof value === 'string') {
      num = parseFloat(value)
      if (isNaN(num)) return BigInt(0)
    } else if (typeof value === 'bigint') {
      return value // Already BigInt
    } else {
      num = Number(value)
      if (isNaN(num)) return BigInt(0)
    }

    // Use Math.floor to ensure integer like Distribution pattern
    return BigInt(Math.floor(num))
  }

  /**
   * Convert frontend formData to backend LaunchpadConfig
   */
  static formDataToLaunchpadConfig(formData: LaunchpadFormData): any {
    return {
      // Project Information
      projectInfo: {
        name: formData.projectInfo.name,
        description: formData.projectInfo.description,
        logo: formData.projectInfo.logo ? [formData.projectInfo.logo] : [],
        banner: [], // Optional field
        website: formData.projectInfo.website ? [formData.projectInfo.website] : [],
        whitepaper: formData.projectInfo.whitepaper ? [formData.projectInfo.whitepaper] : [],
        documentation: formData.projectInfo.documentation ? [formData.projectInfo.documentation] : [],
        telegram: formData.projectInfo.telegram ? [formData.projectInfo.telegram] : [],
        twitter: formData.projectInfo.twitter ? [formData.projectInfo.twitter] : [],
        discord: formData.projectInfo.discord ? [formData.projectInfo.discord] : [],
        github: formData.projectInfo.github ? [formData.projectInfo.github] : [],
        isAudited: formData.projectInfo.isAudited,
        auditReport: formData.projectInfo.auditReport ? [formData.projectInfo.auditReport] : [],
        isKYCed: formData.projectInfo.isKYCed,
        kycProvider: [], // Optional
        tags: formData.projectInfo.tags,
        category: TypeConverter.stringToProjectCategory(formData.projectInfo.category),
        metadata: [] // Optional metadata
      },

      // Sale Token Configuration
      saleToken: {
        canisterId: Principal.fromText('2vxsx-fae'), // Placeholder, will be created
        symbol: formData.saleToken.symbol,
        name: formData.saleToken.name,
        decimals: formData.saleToken.decimals,
        totalSupply: TypeConverter.toBigInt(formData.saleToken.totalSupply),
        transferFee: TypeConverter.toBigInt(formData.saleToken.transferFee),
        logo: formData.saleToken.logo ? [formData.saleToken.logo] : [],
        description: formData.saleToken.description ? [formData.saleToken.description] : [],
        website: formData.saleToken.website ? [formData.saleToken.website] : [],
        standard: formData.saleToken.standard
      },

      // Purchase Token Configuration
      purchaseToken: {
        canisterId: Principal.fromText(formData.purchaseToken.canisterId),
        symbol: formData.purchaseToken.symbol,
        name: formData.purchaseToken.name,
        decimals: formData.purchaseToken.decimals,
        totalSupply: formData.purchaseToken.totalSupply,
        transferFee: formData.purchaseToken.transferFee,
        logo: [],
        description: [],
        website: [],
        standard: formData.purchaseToken.standard
      },

      // Sale Parameters
      saleParams: {
        saleType: TypeConverter.stringToSaleType(formData.saleParams.saleType),
        allocationMethod: TypeConverter.stringToAllocationMethod(formData.saleParams.allocationMethod),
        totalSaleAmount: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.totalSaleAmount)),
        softCap: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.softCap)),
        hardCap: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.hardCap)),
        tokenPrice: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.tokenPrice)),
        minContribution: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.minContribution)),
        maxContribution: formData.saleParams.maxContribution
          ? [TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.maxContribution))]
          : [],
        maxParticipants: [], // Optional
        requiresWhitelist: formData.saleParams.requiresWhitelist,
        requiresKYC: formData.saleParams.requiresKYC,
        blockIdRequired: 0n, // Default
        restrictedRegions: [] // Default
      },

      // Timeline - Using Distribution pattern with BigInt literals
      timeline: {
        createdAt: BigInt(Date.now()) * 1_000_000n, // Convert to nanoseconds like Distribution
        whitelistStart: formData.timeline.whitelistStart
          ? [BigInt(new Date(formData.timeline.whitelistStart).getTime()) * 1_000_000n]
          : [],
        whitelistEnd: formData.timeline.whitelistEnd
          ? [BigInt(new Date(formData.timeline.whitelistEnd).getTime()) * 1_000_000n]
          : [],
        saleStart: BigInt(new Date(formData.timeline.saleStart).getTime()) * 1_000_000n,
        saleEnd: BigInt(new Date(formData.timeline.saleEnd).getTime()) * 1_000_000n,
        claimStart: BigInt(new Date(formData.timeline.claimStart).getTime()) * 1_000_000n,
        vestingStart: formData.timeline.vestingStart
          ? [BigInt(new Date(formData.timeline.vestingStart).getTime()) * 1_000_000n]
          : [],
        listingTime: formData.timeline.listingTime
          ? [BigInt(new Date(formData.timeline.listingTime).getTime()) * 1_000_000n]
          : [],
        daoActivation: formData.timeline.daoActivation
          ? [BigInt(new Date(formData.timeline.daoActivation).getTime()) * 1_000_000n]
          : []
      },

      // Token Distribution - Fixed Allocation Structure
      distribution: [
        // Sale allocation - no recipients (investors assigned after launch)
        {
          name: formData.distribution.sale.name,
          percentage: formData.distribution.sale.percentage,
          totalAmount: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.distribution.sale.totalAmount)),
          vestingSchedule: formData.distribution.sale.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(formData.distribution.sale.vestingSchedule)]
            : [],
          recipients: { SaleParticipants: null }, // Empty, assigned after launch
          description: [formData.distribution.sale.description || '']
        },

        // Team allocation - fixed category with recipients
        {
          name: formData.distribution.team.name,
          percentage: formData.distribution.team.percentage,
          totalAmount: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.distribution.team.totalAmount)),
          vestingSchedule: formData.distribution.team.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(formData.distribution.team.vestingSchedule)]
            : [],
          recipients: TypeConverter.convertRecipientConfig(formData.distribution.team.recipients),
          description: [formData.distribution.team.description || '']
        },

        // LP allocation - auto-calculated from DEX config
        {
          name: formData.distribution.liquidityPool.name,
          percentage: formData.distribution.liquidityPool.percentage,
          totalAmount: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.distribution.liquidityPool.totalAmount)),
          vestingSchedule: formData.distribution.liquidityPool.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(formData.distribution.liquidityPool.vestingSchedule)]
            : [],
          recipients: { LiquidityPool: null }, // Special recipient type for LP
          description: [formData.distribution.liquidityPool.description || '']
        },

        // Others - dynamic allocations
        ...formData.distribution.others.map((allocation: any) => ({
          name: allocation.name,
          percentage: allocation.percentage,
          totalAmount: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(allocation.totalAmount)),
          vestingSchedule: allocation.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(allocation.vestingSchedule)]
            : [],
          recipients: TypeConverter.convertRecipientConfig(allocation.recipients),
          description: [allocation.description || '']
        }))
      ],

      // DEX Configuration
      dexConfig: {
        enabled: true,
        platform: formData.dexConfig.platform,
        listingPrice: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.dexConfig.listingPrice)),
        totalLiquidityToken: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.dexConfig.totalLiquidityToken)),
        initialLiquidityToken: TypeConverter.toBigInt(TypeConverter.tokenAmountToE8s(formData.dexConfig.totalLiquidityToken)),
        initialLiquidityPurchase: 0n, // Will be calculated
        liquidityLockDays: TypeConverter.toBigInt(formData.dexConfig.liquidityLockDays),
        autoList: formData.dexConfig.autoList,
        slippageTolerance: 5, // Default 5%
        fees: {
          listingFee: 0n, // Platform specific
          transactionFee: 3 // Default 0.3%
        }
      },

      // Multi-DEX Config (optional)
      multiDexConfig: [], // Not implemented in frontend yet

      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: Math.floor(parseFloat(formData.raisedFundsAllocation.teamAllocation || '0')),
        developmentFund: Math.floor(parseFloat(formData.raisedFundsAllocation.developmentFund || '0')),
        marketingFund: Math.floor(parseFloat(formData.raisedFundsAllocation.marketingFund || '0')),
        liquidityFund: 50, // Default 50% for liquidity
        reserveFund: 0, // Default 0%
        teamRecipients: formData.raisedFundsAllocation.teamRecipients.map((recipient: any) =>
          TypeConverter.convertFundRecipient(recipient)
        ),
        developmentRecipients: formData.raisedFundsAllocation.developmentRecipients.map((recipient: any) =>
          TypeConverter.convertFundRecipient(recipient)
        ),
        marketingRecipients: formData.raisedFundsAllocation.marketingRecipients.map((recipient: any) =>
          TypeConverter.convertFundRecipient(recipient)
        ),
        customAllocations: []
      },

      // Affiliate Configuration (default)
      affiliateConfig: {
        enabled: false,
        commissionRate: 0,
        maxTiers: 1,
        tierRates: [0],
        minPurchaseForCommission: 0n,
        paymentToken: Principal.fromText('2vxsx-fae'), // Default
        vestingSchedule: []
      },

      // Governance Configuration (default)
      governanceConfig: {
        enabled: false,
        daoCanisterId: [],
        votingToken: Principal.fromText('2vxsx-fae'), // Will be sale token
        proposalThreshold: 1000n,
        quorumPercentage: 10,
        votingPeriod: 7n * 24n * 60n * 60n * 1_000_000_000n, // 7 days in nanoseconds
        timelockDuration: 2n * 24n * 60n * 60n * 1_000_000_000n, // 2 days
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      // Security & Compliance
      whitelist: formData.saleParams.whitelistAddresses.map((addr: any) =>
        Principal.fromText(addr.principal)
      ),
      blacklist: [],
      adminList: [],

      // Fee Structure
      platformFeeRate: 2, // 2% default
      successFeeRate: 1, // 1% default

      // Emergency Controls
      emergencyContacts: [],
      pausable: true,
      cancellable: true
    }
  }

  /**
   * Convert frontend vesting schedule to backend format
   */
  private static convertVestingSchedule(vesting: any): any {
    return {
      cliff: BigInt(Math.floor(vesting.cliff)) * 24n * 60n * 60n * 1_000_000_000n, // days to nanoseconds
      duration: BigInt(Math.floor(vesting.duration)) * 24n * 60n * 60n * 1_000_000_000n,
      frequency: TypeConverter.stringToVestingFrequency(vesting.releases),
      initialUnlock: vesting.immediateRelease || 0
    }
  }

  /**
   * Convert frontend fund recipient to backend format
   */
  private static convertFundRecipient(recipient: any): any {
    return {
      principal: Principal.fromText(recipient.principalId),
      percentage: recipient.percentage,
      vestingSchedule: recipient.vestingSchedule 
        ? [TypeConverter.convertVestingSchedule({
            cliff: recipient.vestingSchedule.cliffDays,
            duration: recipient.vestingSchedule.durationDays,
            releases: recipient.vestingSchedule.releaseFrequency,
            immediateRelease: recipient.vestingSchedule.immediateRelease
          })]
        : [],
      description: []
    }
  }

  /**
   * Convert recipient config to backend format
   */
  private static convertRecipientConfig(recipients: any[]): any {
    if (recipients.length === 0) {
      return { SaleParticipants: null }
    }

    return {
      FixedList: recipients.map(recipient => ({
        address: Principal.fromText(recipient.principal),
        amount: BigInt(recipient.percentage * 1_000_000), // Convert percentage to amount
        description: [],
        vestingOverride: []
      }))
    }
  }

  /**
   * Convert string to ProjectCategory variant
   */
  private static stringToProjectCategory(category: string): any {
    const categoryMap: Record<string, any> = {
      'DeFi': { DeFi: null },
      'Gaming': { Gaming: null },
      'NFT': { NFT: null },
      'AI': { AI: null },
      'Infrastructure': { Infrastructure: null },
      'DAO': { DAO: null },
      'SocialFi': { SocialFi: null },
      'Metaverse': { Metaverse: null }
    }
    return categoryMap[category] || { Other: category }
  }

  /**
   * Convert string to SaleType variant
   */
  private static stringToSaleType(saleType: string): any {
    const typeMap: Record<string, any> = {
      'FairLaunch': { FairLaunch: null },
      'PrivateSale': { PrivateSale: null },
      'IDO': { IDO: null },
      'Auction': { Auction: null },
      'Lottery': { Lottery: null }
    }
    return typeMap[saleType] || { FairLaunch: null }
  }

  // REMOVED: stringToVisibility method - using SaleType mapping instead

  /**
   * Convert string to AllocationMethod variant
   */
  private static stringToAllocationMethod(method: string): any {
    const methodMap: Record<string, any> = {
      'FirstComeFirstServe': { FirstComeFirstServe: null },
      'ProRata': { ProRata: null },
      'Lottery': { Lottery: null },
      'Weighted': { Weighted: null }
    }
    return methodMap[method] || { FirstComeFirstServe: null }
  }

  /**
   * Convert string to VestingFrequency variant
   */
  private static stringToVestingFrequency(frequency: string | number): any {
    if (typeof frequency === 'number') {
      return { Custom: BigInt(Math.floor(frequency)) }
    }

    const frequencyMap: Record<string, any> = {
      'immediate': { Immediate: null },
      'linear': { Linear: null },
      'monthly': { Monthly: null },
      'quarterly': { Quarterly: null },
      'yearly': { Yearly: null },
      'daily': { Custom: 24n * 60n * 60n }, // seconds in a day
      'weekly': { Custom: 7n * 24n * 60n * 60n } // seconds in a week
    }
    return frequencyMap[frequency.toLowerCase()] || { Linear: null }
  }

  /**
   * Convert token amount to e8s using Distribution pattern (1 token = 100_000_000 e8s)
   */
  static tokenAmountToE8s(amount: string | number | bigint): number {
    if (amount === '' || amount === null || amount === undefined) {
      return 0
    }

    let num: number
    if (typeof amount === 'string') {
      num = parseFloat(amount)
      if (isNaN(num)) return 0
    } else if (typeof amount === 'bigint') {
      num = Number(amount)
    } else {
      num = Number(amount)
      if (isNaN(num)) return 0
    }

    // Use Math.floor like Distribution: Math.floor(amount * 100_000_000)
    return Math.floor(num * 100_000_000)
  }

  /**
   * Convert e8s back to token amount
   */
  static e8sToTokenAmount(e8s: bigint | number | string): number {
    if (e8s === '' || e8s === null || e8s === undefined) {
      return 0
    }

    let num: number
    if (typeof e8s === 'string') {
      num = parseFloat(e8s)
      if (isNaN(num)) return 0
    } else if (typeof e8s === 'bigint') {
      num = Number(e8s)
    } else {
      num = Number(e8s)
      if (isNaN(num)) return 0
    }

    // Convert from e8s to token amount (divide by 100_000_000)
    return num / 100_000_000
  }

  /**
   * Convert backend status to frontend readable format
   */
  static statusToString(status: any): string {
    if ('Setup' in status) return 'setup'
    if ('Upcoming' in status) return 'upcoming'
    if ('WhitelistOpen' in status) return 'whitelist'
    if ('SaleActive' in status) return 'active'
    if ('SaleEnded' in status) return 'ended'
    if ('Successful' in status) return 'successful'
    if ('Failed' in status) return 'failed'
    if ('Distributing' in status) return 'distributing'
    if ('Claiming' in status) return 'claiming'
    if ('Completed' in status) return 'completed'
    if ('Cancelled' in status) return 'cancelled'
    if ('Emergency' in status) return 'emergency'
    return 'unknown'
  }

  /**
   * Convert nanoseconds to JavaScript Date using Distribution pattern
   */
  static nanosToDate(nanos: bigint): Date {
    return new Date(Number(nanos / 1_000_000n))
  }

  /**
   * Convert JavaScript Date to nanoseconds using Distribution pattern
   */
  static dateToNanos(date: Date): bigint {
    return BigInt(date.getTime()) * 1_000_000n
  }

  /**
   * Validate Principal string
   */
  static isValidPrincipal(principalString: string): boolean {
    try {
      Principal.fromText(principalString)
      return true
    } catch {
      return false
    }
  }
}