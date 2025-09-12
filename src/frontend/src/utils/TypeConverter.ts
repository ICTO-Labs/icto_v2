/**
 * TypeConverter - Converts between Frontend Vue types and Backend Motoko types
 * Handles the complex type mapping for launchpad data
 */
import { Principal } from '@dfinity/principal'
import type { LaunchpadFormData } from '../services/LaunchpadService'

export class TypeConverter {
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
        totalSupply: BigInt(formData.saleToken.totalSupply),
        transferFee: BigInt(formData.saleToken.transferFee),
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
        totalSaleAmount: BigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.totalSaleAmount)),
        softCap: BigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.softCap)),
        hardCap: BigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.hardCap)),
        tokenPrice: BigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.tokenPrice)),
        minContribution: BigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.minContribution)),
        maxContribution: formData.saleParams.maxContribution 
          ? [BigInt(TypeConverter.tokenAmountToE8s(formData.saleParams.maxContribution))] 
          : [],
        maxParticipants: [], // Optional
        requiresWhitelist: formData.saleParams.requiresWhitelist,
        requiresKYC: formData.saleParams.requiresKYC,
        blockIdRequired: BigInt(0), // Default
        restrictedRegions: [] // Default
      },

      // Timeline
      timeline: {
        createdAt: BigInt(Date.now() * 1_000_000), // Convert to nanoseconds
        whitelistStart: formData.timeline.whitelistStart 
          ? [BigInt(new Date(formData.timeline.whitelistStart).getTime() * 1_000_000)]
          : [],
        whitelistEnd: formData.timeline.whitelistEnd
          ? [BigInt(new Date(formData.timeline.whitelistEnd).getTime() * 1_000_000)]
          : [],
        saleStart: BigInt(new Date(formData.timeline.saleStart).getTime() * 1_000_000),
        saleEnd: BigInt(new Date(formData.timeline.saleEnd).getTime() * 1_000_000),
        claimStart: BigInt(new Date(formData.timeline.claimStart).getTime() * 1_000_000),
        vestingStart: formData.timeline.vestingStart
          ? [BigInt(new Date(formData.timeline.vestingStart).getTime() * 1_000_000)]
          : [],
        listingTime: formData.timeline.listingTime
          ? [BigInt(new Date(formData.timeline.listingTime).getTime() * 1_000_000)]
          : [],
        daoActivation: formData.timeline.daoActivation
          ? [BigInt(new Date(formData.timeline.daoActivation).getTime() * 1_000_000)]
          : []
      },

      // Token Distribution
      distribution: formData.distribution.map(dist => ({
        name: dist.name,
        percentage: dist.percentage,
        totalAmount: BigInt(TypeConverter.tokenAmountToE8s(dist.totalAmount)),
        vestingSchedule: dist.vestingSchedule ? [TypeConverter.convertVestingSchedule(dist.vestingSchedule)] : [],
        recipients: TypeConverter.convertRecipientConfig(dist.recipients),
        description: [] // Optional
      })),

      // DEX Configuration
      dexConfig: {
        enabled: true,
        platform: formData.dexConfig.platform,
        listingPrice: BigInt(TypeConverter.tokenAmountToE8s(formData.dexConfig.listingPrice)),
        totalLiquidityToken: BigInt(TypeConverter.tokenAmountToE8s(formData.dexConfig.totalLiquidityToken)),
        initialLiquidityToken: BigInt(TypeConverter.tokenAmountToE8s(formData.dexConfig.totalLiquidityToken)),
        initialLiquidityPurchase: BigInt(0), // Will be calculated
        liquidityLockDays: BigInt(formData.dexConfig.liquidityLockDays),
        autoList: formData.dexConfig.autoList,
        slippageTolerance: 5, // Default 5%
        fees: {
          listingFee: BigInt(0), // Platform specific
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
        teamRecipients: formData.raisedFundsAllocation.teamRecipients.map(recipient => 
          TypeConverter.convertFundRecipient(recipient)
        ),
        developmentRecipients: formData.raisedFundsAllocation.developmentRecipients.map(recipient =>
          TypeConverter.convertFundRecipient(recipient)
        ),
        marketingRecipients: formData.raisedFundsAllocation.marketingRecipients.map(recipient =>
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
        minPurchaseForCommission: BigInt(0),
        paymentToken: Principal.fromText('2vxsx-fae'), // Default
        vestingSchedule: []
      },

      // Governance Configuration (default)
      governanceConfig: {
        enabled: false,
        daoCanisterId: [],
        votingToken: Principal.fromText('2vxsx-fae'), // Will be sale token
        proposalThreshold: BigInt(1000),
        quorumPercentage: 10,
        votingPeriod: BigInt(7 * 24 * 60 * 60 * 1_000_000_000), // 7 days in nanoseconds
        timelockDuration: BigInt(2 * 24 * 60 * 60 * 1_000_000_000), // 2 days
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      // Security & Compliance
      whitelist: formData.saleParams.whitelistAddresses.map(addr => 
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
      cliff: BigInt(vesting.cliff * 24 * 60 * 60 * 1_000_000_000), // days to nanoseconds
      duration: BigInt(vesting.duration * 24 * 60 * 60 * 1_000_000_000),
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
      return { Custom: BigInt(frequency) }
    }

    const frequencyMap: Record<string, any> = {
      'immediate': { Immediate: null },
      'linear': { Linear: null },
      'monthly': { Monthly: null },
      'quarterly': { Quarterly: null },
      'yearly': { Yearly: null },
      'daily': { Custom: BigInt(24 * 60 * 60) },
      'weekly': { Custom: BigInt(7 * 24 * 60 * 60) }
    }
    return frequencyMap[frequency.toLowerCase()] || { Linear: null }
  }

  /**
   * Convert token amount string to e8s (1 token = 100_000_000 e8s)
   */
  static tokenAmountToE8s(amount: string | number): string {
    const num = typeof amount === 'string' ? parseFloat(amount) : amount
    if (isNaN(num)) return '0'
    
    // Convert to e8s (multiply by 100_000_000)
    return Math.floor(num * 100_000_000).toString()
  }

  /**
   * Convert e8s back to token amount
   */
  static e8sToTokenAmount(e8s: bigint): number {
    return Number(e8s) / 100_000_000
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
   * Convert nanoseconds to JavaScript Date
   */
  static nanosToDate(nanos: bigint): Date {
    return new Date(Number(nanos / BigInt(1_000_000)))
  }

  /**
   * Convert JavaScript Date to nanoseconds
   */
  static dateToNanos(date: Date): bigint {
    return BigInt(date.getTime() * 1_000_000)
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