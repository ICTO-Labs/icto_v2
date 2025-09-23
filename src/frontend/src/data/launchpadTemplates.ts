import type { LaunchpadFormData } from '@/types/launchpad'

export interface LaunchpadTemplate {
  id: string
  name: string
  description: string
  complexity: 'basic' | 'intermediate' | 'advanced' | 'enterprise'
  icon: string
  badge?: string
  recommendedFor: string[]
  features: string[]
  data: Partial<LaunchpadFormData>
}

export const launchpadTemplates: LaunchpadTemplate[] = [
  {
    id: 'basic-token-sale',
    name: 'Basic Token Sale',
    description: 'Simple token sale for beginners with essential features only. Perfect for first-time projects.',
    complexity: 'basic',
    icon: '🚀',
    badge: 'Most Popular',
    recommendedFor: [
      'New projects',
      'Simple utility tokens',
      'Community-driven projects',
      'First-time launchers'
    ],
    features: [
      'Fixed price sale',
      'Basic vesting (6 months)',
      'Single DEX listing (ICPSwap)',
      'Simple team allocation',
      'KYC optional'
    ],
    data: {
      // Project Information
      projectInfo: {
        name: '',
        description: '',
        logo: '',
        website: '',
        telegram: '',
        twitter: '',
        discord: '',
        github: '',
        isAudited: false,
        auditReport: '',
        isKYCed: false,
        kycProvider: '',
        tags: [],
        category: 'DeFi',
        blockIdRequired: 0
      },

      // Sale Token Configuration
      saleToken: {
        symbol: '',
        name: '',
        decimals: 8,
        totalSupply: '1000000',
        transferFee: '0.0001',
        logo: '',
        description: '',
        website: '',
        standard: 'ICRC-2'
      },

      // Purchase Token Configuration
      purchaseToken: {
        canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // ICP Ledger
        symbol: 'ICP',
        name: 'Internet Computer',
        decimals: 8,
        totalSupply: '0',
        transferFee: '0.0001',
        standard: 'ICRC-2'
      },

      // Sale Parameters
      saleParams: {
        saleType: 'FairLaunch',
        allocationMethod: 'FirstComeFirstServe',
        totalSaleAmount: '100000',
        softCap: '1000',
        hardCap: '10000',
        tokenPrice: '0.1',
        minContribution: '10',
        maxContribution: '1000',
        requiresWhitelist: false,
        requiresKYC: false,
        blockIdRequired: 0,
        restrictedRegions: [],
        whitelistMode: 'Closed',
        whitelistEntries: []
      },

      // Timeline
      timeline: {
        createdAt: new Date().toISOString(),
        saleStart: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        saleEnd: new Date(Date.now() + 37 * 24 * 60 * 60 * 1000).toISOString(),
        claimStart: new Date(Date.now() + 38 * 24 * 60 * 60 * 1000).toISOString()
      },

      // Token Distribution - Fixed Allocation Structure
      distribution: {
        sale: {
          name: 'Public Sale',
          percentage: 40,
          totalAmount: '400000',
          vestingSchedule: {
            initialUnlock: 30,
            cliff: BigInt(30 * 24 * 60 * 60 * 1_000_000_000), // 30 days
            duration: BigInt(180 * 24 * 60 * 60 * 1_000_000_000), // 180 days
            frequency: { Monthly: null }
          },
          description: 'Public sale allocation for investors'
        },
        team: {
          name: 'Team',
          percentage: 20,
          totalAmount: '200000',
          vestingSchedule: {
            initialUnlock: 0,
            cliff: BigInt(180 * 24 * 60 * 60 * 1_000_000_000), // 180 days
            duration: BigInt(720 * 24 * 60 * 60 * 1_000_000_000), // 720 days
            frequency: { Monthly: null }
          },
          recipients: [],
          description: 'Team and founder allocation'
        },
        liquidityPool: {
          name: 'Liquidity',
          percentage: 15,
          totalAmount: '150000',
          autoCalculated: true,
          description: 'DEX liquidity provision'
        },
        others: [
          {
            id: 'development',
            name: 'Development',
            percentage: 15,
            totalAmount: '150000',
            vestingEnabled: true,
            vestingSchedule: {
              cliffDays: 90,
              durationDays: 360,
              releaseFrequency: 'monthly',
              immediateRelease: 25
            },
            recipients: [],
            description: 'Development fund allocation'
          },
          {
            id: 'marketing',
            name: 'Marketing',
            percentage: 10,
            totalAmount: '100000',
            vestingEnabled: true,
            vestingSchedule: {
              cliffDays: 30,
              durationDays: 180,
              releaseFrequency: 'monthly',
              immediateRelease: 50
            },
            recipients: [],
            description: 'Marketing and growth allocation'
          }
        ]
      },

      // DEX Configuration
      dexConfig: {
        enabled: true,
        platform: 'ICPSwap',
        listingPrice: '0.12',
        totalLiquidityToken: '50000',
        initialLiquidityToken: '50000',
        initialLiquidityPurchase: '6000',
        liquidityLockDays: 180,
        autoList: true,
        slippageTolerance: 5,
        fees: {
          listingFee: '0',
          transactionFee: 0.3
        }
      },

      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: 30,
        developmentFund: 25,
        marketingFund: 15,
        liquidityFund: 30,
        reserveFund: 0,
        teamRecipients: [],
        developmentRecipients: [],
        marketingRecipients: [],
        customAllocations: []
      },

      // Affiliate Program
      affiliateConfig: {
        enabled: false,
        commissionRate: 0,
        maxTiers: 1,
        tierRates: [0],
        minPurchaseForCommission: '0',
        paymentToken: 'ryjl3-tyaaa-aaaaa-aaaba-cai'
      },

      // Governance Configuration
      governanceConfig: {
        enabled: false,
        votingToken: '',
        proposalThreshold: '0',
        quorumPercentage: 10,
        votingPeriod: '7',
        timelockDuration: '2',
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      // Security & Admin
      whitelist: [],
      blacklist: [],
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      platformFeeRate: 2.5,
      successFeeRate: 1
    }
  },

  {
    id: 'defi-project',
    name: 'DeFi Project',
    description: 'Advanced DeFi project with multi-DEX listing, governance, and staking features.',
    complexity: 'advanced',
    icon: '🏦',
    recommendedFor: [
      'DeFi protocols',
      'DEX platforms',
      'Yield farming projects',
      'Advanced tokenomics'
    ],
    features: [
      'Multi-DEX listing',
      'Advanced vesting schedules',
      'DAO governance',
      'Affiliate program',
      'KYC required',
      'Whitelist tiers'
    ],
    data: {
      projectInfo: {
        name: '',
        description: '',
        logo: '',
        website: '',
        whitepaper: '',
        telegram: '',
        twitter: '',
        discord: '',
        github: '',
        isAudited: true,
        auditReport: '',
        isKYCed: true,
        kycProvider: '',
        tags: ['DeFi', 'DEX', 'Governance'],
        category: 'DeFi',
        blockIdRequired: 0
      },

      saleToken: {
        symbol: '',
        name: '',
        decimals: 8,
        totalSupply: '100000000',
        transferFee: '0.0001',
        standard: 'ICRC-2'
      },

      purchaseToken: {
        canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
        symbol: 'ICP',
        name: 'Internet Computer',
        decimals: 8,
        totalSupply: '0',
        transferFee: '0.0001',
        standard: 'ICRC-2'
      },

      saleParams: {
        saleType: 'IDO',
        allocationMethod: 'ProRata',
        totalSaleAmount: '1000000',
        softCap: '10000',
        hardCap: '50000',
        tokenPrice: '0.05',
        minContribution: '50',
        maxContribution: '5000',
        requiresWhitelist: true,
        requiresKYC: true,
        blockIdRequired: 0,
        restrictedRegions: [],
        whitelistMode: 'OpenRegistration',
        whitelistEntries: []
      },

      timeline: {
        createdAt: new Date().toISOString(),
        whitelistStart: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
        saleStart: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
        saleEnd: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000).toISOString(),
        claimStart: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000).toISOString()
      },

      // Token Distribution - Fixed Allocation Structure
      distribution: {
        sale: {
          name: 'IDO Sale',
          percentage: 45, // Combined public + private
          totalAmount: '45000000',
          vestingSchedule: {
            initialUnlock: 15,
            cliff: BigInt(60 * 24 * 60 * 60 * 1_000_000_000), // 60 days
            duration: BigInt(365 * 24 * 60 * 60 * 1_000_000_000), // 365 days
            frequency: { Monthly: null }
          },
          description: 'IDO sale allocation for investors'
        },
        team: {
          name: 'Team',
          percentage: 20,
          totalAmount: '20000000',
          vestingSchedule: {
            initialUnlock: 0,
            cliff: BigInt(365 * 24 * 60 * 60 * 1_000_000_000), // 365 days
            duration: BigInt(1095 * 24 * 60 * 60 * 1_000_000_000), // 3 years
            frequency: { Monthly: null }
          },
          recipients: [],
          description: 'Team and founder allocation'
        },
        liquidityPool: {
          name: 'Liquidity',
          percentage: 10,
          totalAmount: '10000000',
          autoCalculated: true,
          description: 'Multi-DEX liquidity provision'
        },
        others: [
          {
            id: 'development',
            name: 'Development',
            percentage: 15,
            totalAmount: '15000000',
            vestingEnabled: true,
            vestingSchedule: {
              cliffDays: 180,
              durationDays: 730,
              releaseFrequency: 'monthly',
              immediateRelease: 15
            },
            recipients: [],
            description: 'Development and ecosystem fund'
          },
          {
            id: 'treasury',
            name: 'Treasury',
            percentage: 10,
            totalAmount: '10000000',
            vestingEnabled: false,
            recipients: [],
            description: 'DAO treasury reserve'
          }
        ]
      },

      dexConfig: {
        enabled: true,
        platform: 'ICPSwap',
        listingPrice: '0.06',
        totalLiquidityToken: '200000',
        initialLiquidityToken: '200000',
        initialLiquidityPurchase: '12000',
        liquidityLockDays: 365,
        autoList: true,
        slippageTolerance: 3,
        fees: {
          listingFee: '0',
          transactionFee: 0.3
        }
      },

      multiDexConfig: {
        platforms: [
          {
            id: 'icpswap',
            name: 'ICPSwap',
            enabled: true,
            allocationPercentage: 40,
            calculatedTokenLiquidity: '80000',
            calculatedPurchaseLiquidity: '4800',
            fees: { listing: '0', transaction: 0.3 }
          },
          {
            id: 'sonic',
            name: 'Sonic',
            enabled: true,
            allocationPercentage: 35,
            calculatedTokenLiquidity: '70000',
            calculatedPurchaseLiquidity: '4200',
            fees: { listing: '0', transaction: 0.25 }
          },
          {
            id: 'kongswap',
            name: 'KongSwap',
            enabled: true,
            allocationPercentage: 25,
            calculatedTokenLiquidity: '50000',
            calculatedPurchaseLiquidity: '3000',
            fees: { listing: '0', transaction: 0.3 }
          }
        ],
        totalLiquidityAllocation: '200000',
        distributionStrategy: 'Weighted'
      },

      raisedFundsAllocation: {
        teamAllocation: 25,
        developmentFund: 40,
        marketingFund: 20,
        liquidityFund: 15,
        reserveFund: 0,
        teamRecipients: [],
        developmentRecipients: [],
        marketingRecipients: [],
        customAllocations: []
      },

      affiliateConfig: {
        enabled: true,
        commissionRate: 5,
        maxTiers: 3,
        tierRates: [3, 5, 7],
        minPurchaseForCommission: '100',
        paymentToken: 'ryjl3-tyaaa-aaaaa-aaaba-cai'
      },

      governanceConfig: {
        enabled: true,
        votingToken: '',
        proposalThreshold: '100000',
        quorumPercentage: 10,
        votingPeriod: '7',
        timelockDuration: '2',
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      whitelist: [],
      blacklist: [],
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      platformFeeRate: 2.5,
      successFeeRate: 1
    }
  },

  {
    id: 'community-token',
    name: 'Community Token',
    description: 'Community-focused token with governance, fair distribution, and long-term sustainability.',
    complexity: 'intermediate',
    icon: '👥',
    recommendedFor: [
      'Community projects',
      'Social platforms',
      'Gaming communities',
      'Creator tokens'
    ],
    features: [
      'Fair launch mechanism',
      'Community governance',
      'Long-term vesting',
      'Anti-whale protection',
      'BlockID verification'
    ],
    data: {
      projectInfo: {
        name: '',
        description: '',
        logo: '',
        website: '',
        telegram: '',
        twitter: '',
        discord: '',
        github: '',
        isAudited: false,
        auditReport: '',
        isKYCed: false,
        kycProvider: '',
        tags: ['Community', 'Governance', 'Fair Launch'],
        category: 'SocialFi',
        blockIdRequired: 50
      },

      saleToken: {
        symbol: '',
        name: '',
        decimals: 8,
        totalSupply: '10000000',
        transferFee: '0.0001',
        standard: 'ICRC-2'
      },

      purchaseToken: {
        canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
        symbol: 'ICP',
        name: 'Internet Computer',
        decimals: 8,
        totalSupply: '0',
        transferFee: '0.0001',
        standard: 'ICRC-2'
      },

      saleParams: {
        saleType: 'FairLaunch',
        allocationMethod: 'Lottery',
        totalSaleAmount: '500000',
        softCap: '5000',
        hardCap: '25000',
        tokenPrice: '0.02',
        minContribution: '5',
        maxContribution: '500',
        requiresWhitelist: true,
        requiresKYC: false,
        blockIdRequired: 50,
        restrictedRegions: [],
        whitelistMode: 'OpenRegistration',
        whitelistEntries: []
      },

      timeline: {
        createdAt: new Date().toISOString(),
        whitelistStart: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(),
        saleStart: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString(),
        saleEnd: new Date(Date.now() + 17 * 24 * 60 * 60 * 1000).toISOString(),
        claimStart: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000).toISOString()
      },

      // Token Distribution - Fixed Allocation Structure
      distribution: {
        sale: {
          name: 'Community Sale',
          percentage: 50,
          totalAmount: '5000000',
          vestingSchedule: {
            initialUnlock: 25,
            cliff: BigInt(30 * 24 * 60 * 60 * 1_000_000_000), // 30 days
            duration: BigInt(270 * 24 * 60 * 60 * 1_000_000_000), // 270 days
            frequency: { Monthly: null }
          },
          description: 'Fair launch community sale'
        },
        team: {
          name: 'Team',
          percentage: 15,
          totalAmount: '1500000',
          vestingSchedule: {
            initialUnlock: 0,
            cliff: BigInt(180 * 24 * 60 * 60 * 1_000_000_000), // 180 days
            duration: BigInt(540 * 24 * 60 * 60 * 1_000_000_000), // 540 days
            frequency: { Monthly: null }
          },
          recipients: [],
          description: 'Team allocation with long vesting'
        },
        liquidityPool: {
          name: 'Liquidity',
          percentage: 10,
          totalAmount: '1000000',
          autoCalculated: true,
          description: 'Community-owned liquidity'
        },
        others: [
          {
            id: 'treasury',
            name: 'Community Treasury',
            percentage: 25,
            totalAmount: '2500000',
            vestingEnabled: false,
            recipients: [],
            description: 'Community-governed treasury'
          }
        ]
      },

      dexConfig: {
        enabled: true,
        platform: 'Sonic',
        listingPrice: '0.025',
        totalLiquidityToken: '100000',
        initialLiquidityToken: '100000',
        initialLiquidityPurchase: '2500',
        liquidityLockDays: 180,
        autoList: true,
        slippageTolerance: 5,
        fees: {
          listingFee: '0',
          transactionFee: 0.25
        }
      },

      raisedFundsAllocation: {
        teamAllocation: 20,
        developmentFund: 50,
        marketingFund: 30,
        liquidityFund: 0,
        reserveFund: 0,
        teamRecipients: [],
        developmentRecipients: [],
        marketingRecipients: [],
        customAllocations: []
      },

      affiliateConfig: {
        enabled: true,
        commissionRate: 3,
        maxTiers: 1,
        tierRates: [3],
        minPurchaseForCommission: '10',
        paymentToken: 'ryjl3-tyaaa-aaaaa-aaaba-cai'
      },

      governanceConfig: {
        enabled: true,
        votingToken: '',
        proposalThreshold: '50000',
        quorumPercentage: 5,
        votingPeriod: '5',
        timelockDuration: '1',
        emergencyContacts: [],
        initialGovernors: [],
        autoActivateDAO: false
      },

      whitelist: [],
      blacklist: [],
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      platformFeeRate: 2.5,
      successFeeRate: 1
    }
  }
]

export const getTemplateById = (id: string): LaunchpadTemplate | undefined => {
  return launchpadTemplates.find(template => template.id === id)
}

export const getTemplatesByComplexity = (complexity: LaunchpadTemplate['complexity']): LaunchpadTemplate[] => {
  return launchpadTemplates.filter(template => template.complexity === complexity)
}