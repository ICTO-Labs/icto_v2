/**
 * TypeConverter - Converts between Frontend Vue types and Backend Motoko types
 * Handles the complex type mapping for launchpad data
 */
import { Principal } from '@dfinity/principal'
import type { LaunchpadFormData } from '../types/launchpad'

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
   * Safely convert value to Nat8 (0-255)
   */
  private static toNat8(value: any): number {
    if (value === '' || value === null || value === undefined) {
      return 0
    }

    let num: number
    if (typeof value === 'string') {
      num = parseFloat(value)
      if (isNaN(num)) return 0
    } else if (typeof value === 'bigint') {
      num = Number(value)
    } else {
      num = Number(value)
      if (isNaN(num)) return 0
    }

    // Ensure within Nat8 range (0-255)
    const result = Math.floor(num)
    return Math.max(0, Math.min(255, result))
  }

  /**
   * Safely convert value to Float for Motoko
   */
  private static toFloat(value: any): number {
    if (value === '' || value === null || value === undefined) {
      return 0.0
    }

    let num: number
    if (typeof value === 'string') {
      num = parseFloat(value)
      if (isNaN(num)) return 0.0
    } else if (typeof value === 'bigint') {
      num = Number(value)
    } else {
      num = Number(value)
      if (isNaN(num)) return 0.0
    }

    return num
  }

  /**
   * Convert frontend formData to backend LaunchpadConfig
   * Using simple distribution factory pattern
   */
  static formDataToLaunchpadConfig(formData: LaunchpadFormData): any {
    console.log('🚀 Converting LaunchpadConfig:', formData)
    console.log('📊 Distribution data:', formData.distribution)

    // Build base config object using distribution pattern
    const config: any = {
      // Basic project info (ALL required fields from Motoko)
      projectInfo: {
        name: formData.projectInfo.name,
        description: formData.projectInfo.description,
        logo: formData.projectInfo.logo ? [formData.projectInfo.logo] : [],
        cover: formData.projectInfo.cover ? [formData.projectInfo.cover] : [],
        website: formData.projectInfo.website ? [formData.projectInfo.website] : [],
        whitepaper: formData.projectInfo.whitepaper ? [formData.projectInfo.whitepaper] : [],
        documentation: formData.projectInfo.documentation ? [formData.projectInfo.documentation] : [],
        telegram: formData.projectInfo.telegram ? [formData.projectInfo.telegram] : [],
        twitter: formData.projectInfo.twitter ? [formData.projectInfo.twitter] : [],
        discord: formData.projectInfo.discord ? [formData.projectInfo.discord] : [],
        github: formData.projectInfo.github ? [formData.projectInfo.github] : [],
        medium: formData.projectInfo.medium ? [formData.projectInfo.medium] : [],
        reddit: formData.projectInfo.reddit ? [formData.projectInfo.reddit] : [],
        youtube: formData.projectInfo.youtube ? [formData.projectInfo.youtube] : [],
        isAudited: formData.projectInfo.isAudited,
        auditReport: formData.projectInfo.auditReport ? [formData.projectInfo.auditReport] : [],
        isKYCed: formData.projectInfo.isKYCed || false,
        kycProvider: formData.projectInfo.kycProvider ? [formData.projectInfo.kycProvider] : [],
        tags: formData.projectInfo.tags || [],
        category: TypeConverter.stringToProjectCategory(formData.projectInfo.category),
        metadata: formData.projectInfo.metadata ? [formData.projectInfo.metadata] : []
      },

      // Sale token (LaunchpadSaleToken type - will be created AFTER soft cap reached)
      saleToken: {
        canisterId: [], // Optional - null until deployed after sale reaches soft cap
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

      // Purchase token (TokenInfo type - must exist, users buy with this token)
      purchaseToken: {
        canisterId: Principal.fromText(formData.purchaseToken.canisterId), // Required Principal (not optional)
        symbol: formData.purchaseToken.symbol,
        name: formData.purchaseToken.name,
        decimals: formData.purchaseToken.decimals,
        totalSupply: TypeConverter.toBigInt(formData.purchaseToken.totalSupply),
        transferFee: TypeConverter.toBigInt(formData.purchaseToken.transferFee),
        logo: formData.purchaseToken.logo ? [formData.purchaseToken.logo] : [],
        description: formData.purchaseToken.description ? [formData.purchaseToken.description] : [],
        website: formData.purchaseToken.website ? [formData.purchaseToken.website] : [],
        standard: formData.purchaseToken.standard
      },

      // Sale parameters
      saleParams: {
        saleType: TypeConverter.stringToSaleType(formData.saleParams.saleType),
        allocationMethod: TypeConverter.stringToAllocationMethod(formData.saleParams.allocationMethod),
        totalSaleAmount: TypeConverter.toBigInt(formData.saleParams.totalSaleAmount),
        softCap: TypeConverter.toBigInt(formData.saleParams.softCap),
        hardCap: TypeConverter.toBigInt(formData.saleParams.hardCap),
        tokenPrice: TypeConverter.toBigInt(formData.saleParams.tokenPrice),
        minContribution: TypeConverter.toBigInt(formData.saleParams.minContribution),
        maxContribution: formData.saleParams.maxContribution
          ? [TypeConverter.toBigInt(formData.saleParams.maxContribution)]
          : [],
        maxParticipants: formData.saleParams.maxParticipants
          ? [TypeConverter.toBigInt(formData.saleParams.maxParticipants)]
          : [],
        requiresWhitelist: formData.saleParams.requiresWhitelist,
        requiresKYC: formData.saleParams.requiresKYC || false,
        minICTOPassportScore: 0n, // Default
        restrictedRegions: [], // Default
        whitelistMode: { Closed: null }, // Default WhitelistMode
        whitelistEntries: formData.saleParams.whitelistEntries || []
      },

      // Timeline (ALL required + optional fields from Motoko)
      timeline: {
        createdAt: BigInt(Date.now()) * 1_000_000n,
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

      // ✅ V2 Token Distribution (NEW - Required by Backend)
      tokenDistribution: [{
        sale: {
          name: "Sale",
          percentage: TypeConverter.toFloat(formData.distribution.sale.percentage),
          totalAmount: formData.distribution.sale.totalAmount,
          vestingSchedule: formData.distribution.sale.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(formData.distribution.sale.vestingSchedule)]
            : [],
          description: formData.distribution.sale.description ? [formData.distribution.sale.description] : []
        },
        team: {
          name: "Team",
          percentage: TypeConverter.toFloat(formData.distribution.team.percentage),
          totalAmount: formData.distribution.team.totalAmount,
          vestingSchedule: formData.distribution.team.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(formData.distribution.team.vestingSchedule)]
            : [],
          recipients: (formData.distribution.team.recipients || []).map((r: any) => ({
            principal: r.principal,
            percentage: TypeConverter.toFloat(r.percentage),
            amount: r.amount ? [r.amount] : [],
            name: r.name ? [r.name] : [],
            description: r.description ? [r.description] : [],
            vestingOverride: r.vestingOverride ? [TypeConverter.convertVestingSchedule(r.vestingOverride)] : []
          })),
          description: formData.distribution.team.description ? [formData.distribution.team.description] : []
        },
        liquidityPool: {
          name: "Liquidity Pool",
          percentage: TypeConverter.toFloat(formData.distribution.liquidityPool.percentage),
          totalAmount: formData.distribution.liquidityPool.totalAmount,
          autoCalculated: formData.distribution.liquidityPool.autoCalculated || false,
          description: formData.distribution.liquidityPool.description ? [formData.distribution.liquidityPool.description] : []
        },
        others: (formData.distribution.others || []).map((other: any) => ({
          id: other.id,
          name: other.name,
          percentage: TypeConverter.toFloat(other.percentage),
          totalAmount: other.totalAmount,
          description: other.description ? [other.description] : [],
          recipients: (other.recipients || []).map((r: any) => ({
            principal: r.principal,
            percentage: TypeConverter.toFloat(r.percentage),
            amount: r.amount ? [r.amount] : [],
            name: r.name ? [r.name] : [],
            description: r.description ? [r.description] : [],
            vestingOverride: r.vestingOverride ? [TypeConverter.convertVestingSchedule(r.vestingOverride)] : []
          })),
          vestingSchedule: other.vestingSchedule
            ? [TypeConverter.convertVestingSchedule(other.vestingSchedule)]
            : []
        }))
      }],

      // Build complete distribution array from all categories (V1 Legacy - for backward compatibility)
      distribution: (() => {
        const categories: any[] = []

        // 1. Sale allocation
        if (formData.distribution.sale.percentage > 0) {
          categories.push({
            name: "Public Sale",
            percentage: Math.max(0, Math.min(255, Math.floor(Number(formData.distribution.sale.percentage)))),
            totalAmount: TypeConverter.toBigInt(formData.distribution.sale.totalAmount),
            vestingSchedule: formData.distribution.sale.vestingSchedule
              ? [TypeConverter.convertVestingSchedule(formData.distribution.sale.vestingSchedule)]
              : [],
            recipients: { SaleParticipants: null },
            description: formData.distribution.sale.description ? [formData.distribution.sale.description] : ["Public sale allocation"]
          })
        }

        // 2. Team allocation
        if (formData.distribution.team.percentage > 0) {
          categories.push({
            name: "Team",
            percentage: Math.max(0, Math.min(255, Math.floor(Number(formData.distribution.team.percentage)))),
            totalAmount: TypeConverter.toBigInt(formData.distribution.team.totalAmount),
            vestingSchedule: formData.distribution.team.vestingSchedule
              ? [TypeConverter.convertVestingSchedule(formData.distribution.team.vestingSchedule)]
              : [],
            recipients: { TeamAllocation: null },
            description: formData.distribution.team.description ? [formData.distribution.team.description] : ["Team allocation"]
          })
        }

        // ❌ REMOVED: LP Pool allocation - will be allocated from unallocated tokens after launch success
        // LP amount depends on final raised funds (softCap → hardCap), so it cannot be predetermined
        // LP tokens will be allocated from unallocated reserves based on multiDexConfig after sale ends

        // 3. Other allocations (marketing, advisors, etc.)
        if (formData.distribution.others && formData.distribution.others.length > 0) {
          formData.distribution.others.forEach((other: any) => {
            if (other.percentage > 0) {
              // Map category name to RecipientConfig variant
              let recipientType: any
              const lowerName = other.name.toLowerCase()
              if (lowerName.includes('marketing')) {
                recipientType = { Marketing: null }
              } else if (lowerName.includes('advisor')) {
                recipientType = { Advisors: null }
              } else if (lowerName.includes('staking')) {
                recipientType = { Staking: null }
              } else {
                recipientType = { FixedList: [] } // Default for custom categories
              }

              categories.push({
                name: other.name,
                percentage: Math.max(0, Math.min(255, Math.floor(Number(other.percentage)))),
                totalAmount: TypeConverter.toBigInt(other.totalAmount),
                vestingSchedule: other.vestingSchedule
                  ? [TypeConverter.convertVestingSchedule(other.vestingSchedule)]
                  : [],
                recipients: recipientType,
                description: other.description ? [other.description] : []
              })
            }
          })
        }

        // 5. Calculate unallocated and add to DAO or Multisig
        const totalPercentage = categories.reduce((sum, cat) => sum + cat.percentage, 0)
        const unallocatedPercentage = 100 - totalPercentage

        if (unallocatedPercentage > 0) {
          const unallocatedModel = formData.distribution.unallocatedManagement?.model || 'dao_treasury'

          categories.push({
            name: unallocatedModel === 'dao_treasury' ? "DAO Treasury Reserve" : "Multisig Reserve",
            percentage: Math.max(0, Math.min(255, unallocatedPercentage)),
            totalAmount: TypeConverter.toBigInt(
              (Number(formData.saleToken.totalSupply) * unallocatedPercentage / 100).toString()
            ),
            vestingSchedule: [],
            // Use new Unallocated variant with optional Principal (will be deployed in pipeline)
            recipients: {
              Unallocated: unallocatedModel === 'dao_treasury'
                ? { DAO: [] }      // null - DAO will be deployed after launchpad success
                : { Multisig: [] } // null - Multisig will be deployed after launchpad success
            },
            description: [unallocatedModel === 'dao_treasury'
              ? "Unallocated tokens to be managed by DAO (deployed after launch success)"
              : "Unallocated tokens to be managed by Multisig (deployed after launch success)"]
          })
        }

        console.log('✅ Built distribution categories:', categories)
        console.log('📈 Total percentage:', categories.reduce((sum, cat) => sum + cat.percentage, 0))
        return categories
      })(),

      // DEX config (ALL required fields from Motoko)
      dexConfig: {
        enabled: formData.dexConfig.enabled || false,
        platform: formData.dexConfig.platform || "",
        listingPrice: TypeConverter.toBigInt(formData.dexConfig.listingPrice || 0),
        totalLiquidityToken: TypeConverter.toBigInt(formData.dexConfig.totalLiquidityToken || 0),
        initialLiquidityToken: TypeConverter.toBigInt(formData.dexConfig.initialLiquidityToken || 0),
        initialLiquidityPurchase: TypeConverter.toBigInt(formData.dexConfig.initialLiquidityPurchase || 0),
        liquidityLockDays: TypeConverter.toBigInt(formData.dexConfig.liquidityLockDays || 0),
        autoList: formData.dexConfig.autoList || false,
        slippageTolerance: 5, // Nat8 default
        lpTokenRecipient: formData.dexConfig.lpTokenRecipient
          ? [Principal.fromText(formData.dexConfig.lpTokenRecipient)]
          : [],
        fees: {
          listingFee: 0n,
          transactionFee: 3 // Nat8
        }
      },

      // Multi-DEX config (optional) - ✅ FIX: Read from raisedFundsAllocation.dexConfig (source of truth)
      multiDexConfig: (() => {
        console.log('🔍 [TypeConverter] Checking multiDexConfig...')
        console.log('  raisedFundsAllocation:', formData.raisedFundsAllocation)
        console.log('  dexConfig:', formData.raisedFundsAllocation?.dexConfig)
        console.log('  platforms:', formData.raisedFundsAllocation?.dexConfig?.platforms)

        const platforms = formData.raisedFundsAllocation?.dexConfig?.platforms
        const platformsLength = platforms?.length ?? 0

        console.log(`  platforms.length: ${platformsLength}`)

        if (platformsLength > 0) {
          const result = [{
            platforms: formData.raisedFundsAllocation!.dexConfig!.platforms!.map((platform: any) => ({
              // ✅ CRITICAL: Field order must match LaunchpadTypes.mo DEXPlatform (lines 170-183)
              id: platform.id,                                                      // 1. id: Text
              name: TypeConverter.getPlatformName(platform.id),                    // 2. name: Text
              description: platform.description ? [platform.description] : [],     // 3. description: ?Text
              logo: platform.logo ? [platform.logo] : [],                          // 4. logo: ?Text
              enabled: platform.enabled || false,                                  // 5. enabled: Bool
              allocationPercentage: TypeConverter.toNat8(platform.allocationPercentage || 0), // 6. allocationPercentage: Nat8
              calculatedTokenLiquidity: TypeConverter.toBigInt(platform.calculatedTokenLiquidity || 0), // 7. calculatedTokenLiquidity: Nat
              calculatedPurchaseLiquidity: TypeConverter.toBigInt(platform.calculatedPurchaseLiquidity || 0), // 8. calculatedPurchaseLiquidity: Nat
              fees: {                                                              // 9. fees: { listing: Nat; transaction: Nat8 }
                listing: TypeConverter.toBigInt(platform.fees?.listing || 0),
                transaction: TypeConverter.toNat8(platform.fees?.transaction || 0)
              }
            })),
            distributionStrategy: TypeConverter.stringToDistributionStrategy(
              formData.raisedFundsAllocation!.dexConfig!.distributionStrategy || 'Equal'
            ),
            totalLiquidityAllocation: 0n // Will be calculated after sale ends based on actual raised funds
          }]
          console.log('✅ [TypeConverter] multiDexConfig generated (array):', result)
          return result
        } else {
          console.log('⚠️ [TypeConverter] No platforms configured, returning empty array')
          return []
        }
      })(),

      // Raised funds allocation - convert from formData
      raisedFundsAllocation: (() => {
        const allocations = (formData.raisedFundsAllocation?.allocations || []).map((alloc: any) => ({
          id: alloc.id,
          name: alloc.name,
          amount: TypeConverter.toBigInt(alloc.amount || 0),
          percentage: TypeConverter.toNat8(alloc.percentage),
          recipients: (alloc.recipients || []).map((recipient: any) => ({
            principal: Principal.fromText(recipient.principal),
            percentage: TypeConverter.toNat8(recipient.percentage),
            name: recipient.name ? [recipient.name] : [],
            vestingEnabled: recipient.vestingEnabled || false,
            vestingSchedule: recipient.vestingSchedule
              ? [TypeConverter.convertVestingSchedule(recipient.vestingSchedule)]
              : [],
            description: recipient.description ? [recipient.description] : []
          }))
        }))

        // Calculate unallocated percentage for raised funds
        const totalPercentage = allocations.reduce((sum, alloc) => sum + Number(alloc.percentage), 0)
        const unallocatedPercentage = 100 - totalPercentage

        // Add unallocated fund allocation if there's remaining percentage
        // This will be used for LP provision after sale based on multiDexConfig
        if (unallocatedPercentage > 0) {
          allocations.push({
            id: 'unallocated_lp_reserve',
            name: 'LP Provision Reserve',
            amount: 0n, // Will be calculated after sale ends based on actual raised amount
            percentage: TypeConverter.toNat8(Math.max(0, Math.min(255, unallocatedPercentage))),
            recipients: [] // Empty - will be distributed to DEX pools after sale success
          })
        }

        return { allocations }
      })(),

      // Affiliate config (disabled by default)
      affiliateConfig: {
        enabled: false,
        commissionRate: 0,
        maxTiers: 1,
        tierRates: [0],
        minPurchaseForCommission: 0n,
        paymentToken: Principal.fromText(import.meta.env.VITE_BACKEND_CANISTER_ID || 'rrkah-fqaaa-aaaaa-aaaaq-cai'), // Placeholder
        vestingSchedule: []
      },

      // Governance config (disabled by default - ALL required fields from Motoko)
      governanceConfig: {
        enabled: false,
        daoCanisterId: [],
        votingToken: Principal.fromText(import.meta.env.VITE_BACKEND_CANISTER_ID || 'rrkah-fqaaa-aaaaa-aaaaq-cai'), // Will be sale token after deployment
        proposalThreshold: 1000n, // Nat default
        quorumPercentage: 10, // Nat8 (0-100)
        votingPeriod: 7n * 24n * 60n * 60n * 1_000_000_000n, // 7 days in nanoseconds
        timelockDuration: 2n * 24n * 60n * 60n * 1_000_000_000n, // 2 days in nanoseconds
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      // Security
      whitelist: [],
      blacklist: [],
      adminList: [],

      // Fees
      platformFeeRate: 2,
      successFeeRate: 1,

      // Emergency controls
      emergencyContacts: [],
      pausable: true,
      cancellable: true
    }

    console.log('✅ Generated LaunchpadConfig:', config)
    return config
  }

  /**
   * Convert vesting schedule from frontend to backend format
   */
  private static convertVestingSchedule(vesting: any): any {
    if (!vesting) {
      return {
        cliffDays: 0n,
        durationDays: 0n,
        releaseFrequency: { Linear: null },
        immediateRelease: 0
      }
    }

    return {
      cliffDays: TypeConverter.toBigInt(vesting.cliffDays || vesting.cliff || 0),
      durationDays: TypeConverter.toBigInt(vesting.durationDays || vesting.duration || 0),
      releaseFrequency: TypeConverter.stringToVestingFrequency(vesting.releaseFrequency || vesting.releases),
      immediateRelease: TypeConverter.toNat8(vesting.immediateRelease || vesting.immediatePercentage || 0)
    }
  }

  // Removed complex helper methods to keep it simple like distribution factory

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
   * Convert vesting frequency string to backend variant
   */
  private static stringToVestingFrequency(frequency: any): any {
    if (!frequency || typeof frequency !== 'string') {
      return { Linear: null } // Default
    }

    const freqMap: Record<string, any> = {
      'daily': { Daily: null },
      'Daily': { Daily: null },
      'weekly': { Weekly: null },
      'Weekly': { Weekly: null },
      'monthly': { Monthly: null },
      'Monthly': { Monthly: null },
      'quarterly': { Quarterly: null },
      'Quarterly': { Quarterly: null },
      'yearly': { Yearly: null },
      'Yearly': { Yearly: null },
      'immediate': { Immediate: null },
      'Immediate': { Immediate: null },
      'linear': { Linear: null },
      'Linear': { Linear: null }
    }

    return freqMap[frequency] || { Linear: null }
  }

  /**
   * Convert string to DEXDistributionStrategy variant
   */
  private static stringToDistributionStrategy(strategy: string): any {
    const strategyMap: Record<string, any> = {
      'Equal': { Equal: null },
      'Priority': { Priority: null },
      'Weighted': { Weighted: null },
      'Custom': { Custom: null }
    }
    return strategyMap[strategy] || { Equal: null }
  }

  /**
   * Get platform display name from ID
   */
  private static getPlatformName(platformId: string): string {
    const platformNames: Record<string, string> = {
      'icpswap': 'ICPSwap',
      'kongswap': 'KongSwap',
      'sonic': 'Sonic',
      'icdex': 'ICDex',
      'iclight': 'ICLight'
    }
    return platformNames[platformId] || platformId.charAt(0).toUpperCase() + platformId.slice(1)
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