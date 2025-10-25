import { ref, computed } from 'vue'

/**
 * Composable for LaunchpadCreateV2 form state management
 * Uses centralized state pattern to avoid props/emit circular dependencies
 *
 * Modern Vue 3 pattern:
 * - Single source of truth for form data
 * - Direct state mutation without emit chains
 * - No v-model, no props drilling
 *
 * Usage:
 * ```typescript
 * // In parent component
 * const launchpadForm = useLaunchpadForm()
 *
 * // In child component
 * const launchpadForm = useLaunchpadForm()
 * launchpadForm.formData.value.projectInfo.name = 'New Name'
 * ```
 */

// Platform fee configuration
const PLATFORM_FEE_PERCENTAGE = 2.0

// Default vesting schedule
const DEFAULT_VESTING_SCHEDULE = {
  cliffDays: 180,
  durationDays: 730,
  releaseFrequency: 'monthly' as const,
  immediatePercentage: 10
}

// Singleton state - shared across all components
let formDataInstance: any = null
let currentStepInstance: any = null
let simulatedAmountInstance: any = null
let estimatedTokenPriceInstance: any = null

export function useLaunchpadForm() {
  // Initialize singleton state only once
  if (!formDataInstance) {
    console.log('[useLaunchpadForm] 🔧 Initializing NEW singleton instance')
    formDataInstance = ref({
      // Project information
      projectInfo: {
        name: '',
        description: '',
        // Visual Assets (URLs only)
        logo: '',
        cover: '',
        // Links & Documentation
        website: '',
        whitepaper: '',
        documentation: '',
        // Social Media & Community
        twitter: '',
        telegram: '',
        discord: '',
        github: '',
        medium: '',
        reddit: '',
        youtube: '',
        // Verification & Compliance
        isKYCed: false,
        kycProvider: '',
        isAudited: false,
        auditReport: '',
        // Classification
        category: '' as string,
        tags: [] as string[],
        metadata: [],
        minICTOPassportScore: 0
      },

      // Enhanced token configuration
      saleToken: {
        name: '',
        symbol: '',
        decimals: 8,
        totalSupply: '100000000',
        transferFee: '10000',
        standard: 'ICRC1',
        logo: '',
        description: '',
        website: ''
      },

      // Enhanced purchase token configuration
      purchaseToken: {
        canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // Default to ICP
        name: 'Internet Computer',
        symbol: 'ICP',
        decimals: 8,
        totalSupply: '0',
        transferFee: '10000',
        standard: 'ICRC1',
        logo: 'https://cryptologos.cc/logos/internet-computer-icp-logo.png',
        description: 'Internet Computer Protocol',
        website: 'https://internetcomputer.org'
      },

      // Enhanced sale parameters
      saleParams: {
        saleType: 'FairLaunch' as string,
        allocationMethod: 'FirstComeFirstServe' as string,

        // ✅ NEW: Sale Visibility (Public by default)
        visibility: 'Public' as 'Public' | 'WhitelistOnly' | 'Private',

        totalSaleAmount: '',
        price: '',
        tokenPrice: '',
        softCap: '',
        hardCap: '',
        minContribution: '',
        maxContribution: '',
        maxParticipants: '',

        // Whitelist Config
        requiresWhitelist: false,  // Auto-set based on visibility
        whitelistMode: 'OpenRegistration' as 'Closed' | 'OpenRegistration',

        // KYC Config
        requiresKYC: false,
        kycProvider: '',

        // ✅ NEW: ICTO Passport Third-party Service (disabled by default)
        ictoPassportConfig: {
          enabled: false,
          minScore: 50,  // Default: basic verification required
          providerCanisterId: undefined,
          verificationMethods: [],
          bypassForWhitelisted: true  // Allow whitelisted users to skip ICTO Passport
        },

        // ✅ NEW: Whitelist Scoring (disabled by default)
        whitelistScoring: {
          enabled: false,
          minTotalScore: 50
        },

        restrictedRegions: [],

        // Updated whitelist entries structure
        whitelistEntries: [] as Array<{
          principal: string
          allocation?: string
          tier?: number
          ictoPassportScore?: number
          whitelistScore?: number
          scoreBreakdown?: {
            accountAge?: number
            stakeAmount?: number
            nftHolder?: boolean
            activityScore?: number
          }
          registeredAt?: string
          approvedAt?: string
          approvedBy?: string
        }>
      },

      // Enhanced timeline
      timeline: {
        saleStart: '',
        saleEnd: '',
        whitelistStart: '',
        whitelistEnd: '',
        claimStart: '',
        listingTime: '',
        vestingStart: '',
        daoActivation: '',
        createdAt: BigInt(0)
      },

      // Enhanced distribution with vesting support
      distribution: {
        sale: {
          name: 'Sale',
          percentage: 60,
          totalAmount: '',
          description: 'Public/Private sale allocation for investors'
        },
        team: {
          name: 'Team',
          percentage: 15,
          totalAmount: '',
          vestingSchedule: {
            cliffDays: 365,
            durationDays: 1460,
            releaseFrequency: 'monthly' as const,
            immediateRelease: 0  // ✅ RENAMED from immediatePercentage
          },
          recipients: [] as Array<{
            principal: string
            percentage: number
            name?: string
            description?: string
            vestingEnabled: boolean
            vestingSchedule?: {
              cliffDays: number
              durationDays: number
              releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
              immediateRelease: number  // ✅ RENAMED from immediatePercentage
            }
          }>,
          description: 'Team and founder allocation'
        },
        liquidityPool: {
          name: 'Liquidity Pool',
          percentage: 0,
          totalAmount: '',
          autoCalculated: true,
          description: 'DEX liquidity provision'
        },
        others: [] as Array<{
          id: string
          name: string
          percentage: number
          totalAmount: string
          vestingEnabled: boolean
          vestingSchedule?: {
            cliffDays: number
            durationDays: number
            releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
            immediateRelease: number  // ✅ RENAMED from immediatePercentage
          }
          recipients: Array<{
            principal: string
            percentage: number
            name?: string
            description?: string
            vestingEnabled: boolean
            vestingSchedule?: {
              cliffDays: number
              durationDays: number
              releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
              immediateRelease: number  // ✅ RENAMED from immediatePercentage
            }
          }>
          description?: string
        }>
      },

      // ✅ V2 ALIGNED WITH BACKEND: Dynamic allocation array structure
      // Simplified DEX config - backend handles detailed configuration
      raisedFundsAllocation: {
        // Dynamic allocations array matching backend structure
        allocations: [
          // Team Allocation (default 70%)
          {
            id: 'team',
            name: 'Team Allocation',
            amount: '0',
            percentage: 70,
            recipients: [] as Array<{
              principal: string
              percentage: number
              name?: string
              vestingEnabled: boolean
              vestingSchedule?: {
                cliffDays: number
                durationDays: number
                releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
                immediateRelease: number  // ✅ RENAMED from immediatePercentage
              }
              description?: string
            }>
          },
          // Marketing Allocation (default 20%)
          {
            id: 'marketing',
            name: 'Marketing Allocation',
            amount: '0',
            percentage: 20,
            recipients: [] as Array<{
              principal: string
              percentage: number
              name?: string
              vestingEnabled: boolean
              vestingSchedule?: {
                cliffDays: number
                durationDays: number
                releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
                immediateRelease: number
              }
              description?: string
            }>
          },
          // DEX Liquidity Allocation (default 10%)
          {
            id: 'dex_liquidity',
            name: 'DEX Liquidity',
            amount: '0',
            percentage: 10,
            recipients: [] // No recipients - auto-distributed to DEX
          }
        ] as Array<{
          id: string
          name: string
          amount: string
          percentage: number
          recipients: Array<{
            principal: string
            percentage: number
            name?: string
            vestingEnabled: boolean
            vestingSchedule?: {
              cliffDays: number
              durationDays: number
              releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
              immediateRelease: number
            }
            description?: string
          }>
        }>,

        // ✅ SIMPLIFIED: DEX Config - only IDs, backend handles details
        dexConfig: {
          platforms: [] as Array<{
            id: string           // DEX identifier: 'icpswap', 'kongswap', 'sonic', etc.
            enabled: boolean
            allocationPercentage: number  // Percentage of DEX liquidity allocated to this DEX
            calculatedTokenLiquidity: number
            calculatedPurchaseLiquidity: number
          }>
        }
      },

      // Enhanced DEX configuration
      dexConfig: {
        platform: '',
        totalLiquidityToken: '',
        liquidityLockDays: 180,
        autoList: false,
        lpTokenRecipient: ''
      },

      // Enhanced governance configuration
      governanceConfig: {
        enabled: false,
        daoCanisterId: '',
        votingToken: '',
        proposalThreshold: '',
        quorumPercentage: 50,
        votingPeriod: '7',
        timelockDuration: '2',
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      // Unallocated assets management (required - must select one)
      unallocatedManagement: {
        model: 'dao_treasury' as 'dao_treasury' | 'multisig_wallet',
        daoConfig: null as {
          name: string
          description: string
          governanceType: 'liquid' | 'locked' | 'hybrid'
          proposalThreshold: number
          quorumPercentage: number
          approvalThreshold: number
          votingPeriod: number
          minimumStake: number
          timelockDuration: number
        } | null,
        multisigConfig: null as {
          name: string
          description: string
          signers: string[]
          threshold: number
        } | null
      }
    })

    currentStepInstance = ref(0)
    simulatedAmountInstance = ref(0)
    estimatedTokenPriceInstance = ref(0)
  }

  // Computed properties for validation
  const step0ValidationErrors = computed(() => {
    const errors: string[] = []

    if (!formDataInstance.value?.projectInfo) {
      return errors
    }

    if (!formDataInstance.value.projectInfo.name?.trim()) {
      errors.push('Project name is required')
    }
    if (!formDataInstance.value.projectInfo.description?.trim()) {
      errors.push('Project description is required')
    }
    if (!formDataInstance.value.projectInfo.category?.trim()) {
      errors.push('Project category is required')
    }

    return errors
  })

  const step1ValidationErrors = computed(() => {
    const errors: string[] = []

    if (!formDataInstance.value?.saleParams || !formDataInstance.value?.saleToken) {
      return errors
    }

    // Token validation
    if (!formDataInstance.value.saleToken.name?.trim()) {
      errors.push('Token name is required')
    }
    if (!formDataInstance.value.saleToken.symbol?.trim()) {
      errors.push('Token symbol is required')
    }
    if (!formDataInstance.value.saleToken.decimals || formDataInstance.value.saleToken.decimals < 1 || formDataInstance.value.saleToken.decimals > 18) {
      errors.push('Token decimals must be between 1 and 18')
    }
    if (!formDataInstance.value.saleToken.totalSupply || Number(formDataInstance.value.saleToken.totalSupply) <= 0) {
      errors.push('Token total supply must be greater than 0')
    }

    // Sale configuration validation
    if (!formDataInstance.value.saleParams.softCap || Number(formDataInstance.value.saleParams.softCap) <= 0) {
      errors.push('Soft cap is required and must be greater than 0')
    }
    if (!formDataInstance.value.saleParams.hardCap || Number(formDataInstance.value.saleParams.hardCap) <= 0) {
      errors.push('Hard cap is required and must be greater than 0')
    }
    if (Number(formDataInstance.value.saleParams.softCap) >= Number(formDataInstance.value.saleParams.hardCap)) {
      errors.push('Hard cap must be greater than soft cap')
    }
    if (!formDataInstance.value.saleParams.totalSaleAmount || Number(formDataInstance.value.saleParams.totalSaleAmount) <= 0) {
      errors.push('Total sale amount is required and must be greater than 0')
    }

    // Timeline validation
    if (!formDataInstance.value.timeline.saleStart) {
      errors.push('Sale start time is required')
    }
    if (!formDataInstance.value.timeline.saleEnd) {
      errors.push('Sale end time is required')
    }
    if (!formDataInstance.value.timeline.claimStart) {
      errors.push('Claim start time is required')
    }

    return errors
  })

  const step2ValidationErrors = computed(() => {
    const errors: string[] = []

    if (!formDataInstance.value?.distribution) {
      return errors
    }

    if (Object.keys(formDataInstance.value.distribution).length === 0) {
      errors.push('At least one token distribution category is required')
    }

    // Check team allocation validation
    const teamPercentage = Number(formDataInstance.value.distribution.team?.percentage) || 0
    if (teamPercentage > 0) {
      if (!formDataInstance.value.distribution.team?.recipients || formDataInstance.value.distribution.team.recipients.length === 0) {
        errors.push('Team allocation requires at least one recipient')
      } else {
        const totalTeamPercentage = formDataInstance.value.distribution.team.recipients.reduce((sum, r) => sum + (Number(r.percentage) || 0), 0)
        // Only error if exceeds 100%, allow < 100% for flexible allocation
        if (totalTeamPercentage > 100) {
          errors.push(`Team recipient percentages exceed 100% (currently ${totalTeamPercentage.toFixed(2)}%)`)
        }
      }
    }

    // Check raised funds allocation validation
    const raisedFundsTeamPercentage = Number(formDataInstance.value.raisedFundsAllocation?.teamAllocationPercentage) || 0
    if (raisedFundsTeamPercentage > 0) {
      if (!formDataInstance.value.raisedFundsAllocation?.teamRecipients || formDataInstance.value.raisedFundsAllocation.teamRecipients.length === 0) {
        errors.push('Raised funds team allocation requires at least one recipient')
      } else {
        const totalTeamPercentage = formDataInstance.value.raisedFundsAllocation.teamRecipients.reduce((sum, r) => sum + (Number(r.percentage) || 0), 0)
        // Only error if exceeds 100%, allow < 100% for flexible allocation
        if (totalTeamPercentage > 100) {
          errors.push(`Raised funds team recipient percentages exceed 100% (currently ${totalTeamPercentage.toFixed(2)}%)`)
        }
      }
    }

    return errors
  })

  const timelineValidation = computed(() => {
    const issues: string[] = []

    if (!formDataInstance.value?.timeline) {
      return issues
    }

    const now = new Date()

    try {
      if (formDataInstance.value.timeline.saleStart) {
        const saleStart = new Date(formDataInstance.value.timeline.saleStart)
        if (saleStart <= now) {
          issues.push('Sale start must be in the future')
        }
      }

      if (formDataInstance.value.timeline.saleStart && formDataInstance.value.timeline.saleEnd) {
        const saleStart = new Date(formDataInstance.value.timeline.saleStart)
        const saleEnd = new Date(formDataInstance.value.timeline.saleEnd)
        if (saleEnd <= saleStart) {
          issues.push('Sale end must be after sale start')
        }
      }

      if (formDataInstance.value.timeline.saleEnd && formDataInstance.value.timeline.claimStart) {
        const saleEnd = new Date(formDataInstance.value.timeline.saleEnd)
        const claimStart = new Date(formDataInstance.value.timeline.claimStart)
        if (claimStart <= saleEnd) {
          issues.push('Claim start should be after sale end')
        }
      }
    } catch (error) {
      issues.push('Invalid timeline format')
    }

    return issues
  })

  const liquidityValidation = computed(() => {
    const issues: string[] = []
    const warnings: string[] = []

    if (!formDataInstance.value?.saleParams) {
      return { issues, warnings }
    }

    try {
      const softCapAmount = Number(formDataInstance.value.saleParams.softCap) || 0
      const platformFeeAtSoftCap = softCapAmount * (PLATFORM_FEE_PERCENTAGE / 100)

      if (softCapAmount > 0 && platformFeeAtSoftCap > softCapAmount) {
        issues.push(`Platform fees exceed soft cap. Project is not viable at minimum funding level!`)
      }

      const remainingAfterFeesAtSoftCap = softCapAmount - platformFeeAtSoftCap
      if (softCapAmount > 0 && remainingAfterFeesAtSoftCap < 0) {
        issues.push(`No funds available for project operations after paying fees.`)
      }
    } catch (error) {
      issues.push('Invalid sale parameters format')
    }

    return { issues, warnings }
  })

  const step3ValidationErrors = computed(() => {
    const errors: string[] = []
    // Step 3 is verification step - no specific validation needed
    // All validations are done in previous steps
    return errors
  })

  // Helper methods
  const updateSimulatedAmount = (amount: number) => {
    simulatedAmountInstance.value = amount
  }

  const updateEstimatedTokenPrice = (price: number) => {
    estimatedTokenPriceInstance.value = price
  }

  const applySimulation = (data: { tokenPrice: number; simulatedAmount: number }) => {
    estimatedTokenPriceInstance.value = data.tokenPrice
    simulatedAmountInstance.value = data.simulatedAmount

    // Auto-fill hardCap if not set (use simulated amount)
    if (!formDataInstance.value.saleParams.hardCap || Number(formDataInstance.value.saleParams.hardCap) === 0) {
      formDataInstance.value.saleParams.hardCap = data.simulatedAmount.toString()
    }

    // Auto-fill softCap if not set (50% of hardCap by default)
    if (!formDataInstance.value.saleParams.softCap || Number(formDataInstance.value.saleParams.softCap) === 0) {
      const currentHardCap = Number(formDataInstance.value.saleParams.hardCap) || data.simulatedAmount
      formDataInstance.value.saleParams.softCap = (currentHardCap * 0.5).toString()
    }

    // Update DEX liquidity allocation
    const dexLiquidityPercentage = formDataInstance.value.raisedFundsAllocation?.dexLiquidityPercentage || 0
    if (dexLiquidityPercentage > 0) {
      const dexLiquidityValue = data.simulatedAmount * (dexLiquidityPercentage / 100)
      const dexLiquidityTokenAmount = dexLiquidityValue / data.tokenPrice

      // Update liquidity pool allocation
      if (formDataInstance.value.distribution?.liquidityPool) {
        formDataInstance.value.distribution.liquidityPool.totalAmount = dexLiquidityTokenAmount.toString()
        formDataInstance.value.distribution.liquidityPool.percentage =
          (dexLiquidityTokenAmount / Number(formDataInstance.value.saleToken.totalSupply)) * 100
      }
    }
  }

  const resetForm = () => {
    // Reset to initial state if needed
    currentStepInstance.value = 0
    simulatedAmountInstance.value = 0
    estimatedTokenPriceInstance.value = 0
  }

  return {
    // State
    formData: formDataInstance,
    currentStep: currentStepInstance,
    simulatedAmount: simulatedAmountInstance,
    estimatedTokenPrice: estimatedTokenPriceInstance,

    // Computed validations
    step0ValidationErrors,
    step1ValidationErrors,
    step2ValidationErrors,
    step3ValidationErrors,
    timelineValidation,
    liquidityValidation,

    // Constants
    platformFeePercentage: PLATFORM_FEE_PERCENTAGE,

    // Methods
    updateSimulatedAmount,
    updateEstimatedTokenPrice,
    applySimulation,
    resetForm
  }
}
