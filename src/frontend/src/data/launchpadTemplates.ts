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
      projectName: '',
      description: '',
      website: '',
      twitter: '',
      telegram: '',
      
      // Sale Token Configuration
      saleTokenName: '',
      saleTokenSymbol: '',
      saleTokenDecimals: 8,
      saleTokenTotalSupply: '1000000',
      saleTokenTransferFee: '0.0001',
      
      // Purchase Token Configuration
      purchaseToken: 'ICP',
      
      // Sale Parameters
      saleType: 'PublicSale',
      allocationMethod: 'FirstComeFirstServe',
      tokenPrice: '0.1',
      softCap: '1000',
      hardCap: '10000',
      minContribution: '10',
      maxContribution: '1000',
      totalSaleAmount: '100000',
      requiresWhitelist: false,
      requiresKYC: false,
      
      // Timeline (30 days from now)
      saleStart: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days from now
      saleEnd: new Date(Date.now() + 37 * 24 * 60 * 60 * 1000), // 37 days from now
      claimStart: new Date(Date.now() + 38 * 24 * 60 * 60 * 1000), // 38 days from now
      
      // Vesting Schedule
      vestingEnabled: true,
      tgePercentage: 30,
      cliffDuration: 30, // 30 days
      vestingDuration: 180, // 6 months
      vestingInterval: 30, // monthly
      
      // Token Distribution
      distribution: [
        {
          category: 'Public Sale',
          percentage: 40,
          totalAmount: '400000',
          recipients: []
        },
        {
          category: 'Team',
          percentage: 20,
          totalAmount: '200000',
          recipients: []
        },
        {
          category: 'Development',
          percentage: 15,
          totalAmount: '150000',
          recipients: []
        },
        {
          category: 'Marketing',
          percentage: 10,
          totalAmount: '100000',
          recipients: []
        },
        {
          category: 'Liquidity',
          percentage: 15,
          totalAmount: '150000',
          recipients: []
        }
      ],
      
      // DEX Configuration
      dexConfig: {
        platform: 'ICPSwap',
        enabled: true,
        listingPrice: '0.12',
        totalLiquidityToken: '50000',
        liquidityLockDays: 180,
        autoList: true,
        slippageTolerance: 5
      },
      
      // Multi-DEX Support
      multiDexEnabled: false,
      multiDexConfig: {},
      
      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: 30,
        developmentFund: 25,
        marketingFund: 15,
        teamRecipients: []
      },
      
      // Affiliate Program
      affiliateEnabled: false,
      affiliateCommissionRate: 0,
      
      // Governance Configuration
      governanceEnabled: false,
      
      // Security & Admin
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      enableAuditLog: true,
      platformFeeRate: 2.5,
      
      // Whitelist Management
      whitelist: [],
      whitelistTiers: []
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
      // Project Information
      projectName: '',
      description: '',
      website: '',
      twitter: '',
      telegram: '',
      discord: '',
      whitepaper: '',
      
      // Sale Token Configuration
      saleTokenName: '',
      saleTokenSymbol: '',
      saleTokenDecimals: 8,
      saleTokenTotalSupply: '100000000',
      saleTokenTransferFee: '0.0001',
      
      // Purchase Token Configuration
      purchaseToken: 'ICP',
      
      // Sale Parameters
      saleType: 'PublicSale',
      allocationMethod: 'Proportional',
      tokenPrice: '0.05',
      softCap: '10000',
      hardCap: '50000',
      minContribution: '50',
      maxContribution: '5000',
      totalSaleAmount: '1000000',
      requiresWhitelist: true,
      requiresKYC: true,
      
      // Timeline
      whitelistStart: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // 3 days
      saleStart: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      saleEnd: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000), // 21 days
      claimStart: new Date(Date.now() + 22 * 24 * 60 * 60 * 1000), // 22 days
      
      // Vesting Schedule
      vestingEnabled: true,
      tgePercentage: 20,
      cliffDuration: 60, // 2 months
      vestingDuration: 365, // 12 months
      vestingInterval: 30, // monthly
      
      // Token Distribution
      distribution: [
        {
          category: 'Public Sale',
          percentage: 30,
          totalAmount: '30000000',
          recipients: []
        },
        {
          category: 'Private Sale',
          percentage: 15,
          totalAmount: '15000000',
          recipients: []
        },
        {
          category: 'Team',
          percentage: 20,
          totalAmount: '20000000',
          recipients: []
        },
        {
          category: 'Development',
          percentage: 15,
          totalAmount: '15000000',
          recipients: []
        },
        {
          category: 'Liquidity',
          percentage: 10,
          totalAmount: '10000000',
          recipients: []
        },
        {
          category: 'Treasury',
          percentage: 10,
          totalAmount: '10000000',
          recipients: []
        }
      ],
      
      // DEX Configuration
      dexConfig: {
        platform: 'ICPSwap',
        enabled: true,
        listingPrice: '0.06',
        totalLiquidityToken: '200000',
        liquidityLockDays: 365,
        autoList: true,
        slippageTolerance: 3
      },
      
      // Multi-DEX Support
      multiDexEnabled: true,
      multiDexConfig: {
        ICPSwap: {
          enabled: true,
          listingPrice: '0.06',
          liquidityAllocation: '40',
          lockDays: 365,
          autoList: true
        },
        Sonic: {
          enabled: true,
          listingPrice: '0.06',
          liquidityAllocation: '35',
          lockDays: 365,
          autoList: true
        },
        KongSwap: {
          enabled: true,
          listingPrice: '0.06',
          liquidityAllocation: '25',
          lockDays: 365,
          autoList: false
        }
      },
      
      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: 25,
        developmentFund: 40,
        marketingFund: 20,
        teamRecipients: []
      },
      
      // Affiliate Program
      affiliateEnabled: true,
      affiliateCommissionRate: 5,
      affiliateConfig: {
        maxCommission: 10,
        tierStructure: [
          { tier: 1, minReferrals: 1, commissionRate: 3 },
          { tier: 2, minReferrals: 10, commissionRate: 5 },
          { tier: 3, minReferrals: 50, commissionRate: 7 }
        ]
      },
      
      // Governance Configuration
      governanceEnabled: true,
      governanceConfig: {
        proposalThreshold: '100000',
        quorumPercentage: 10,
        votingPeriod: 7,
        timelockDuration: 2,
        enableDelegation: true
      },
      
      // Security & Admin
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      enableAuditLog: true,
      platformFeeRate: 2.5,
      
      // Whitelist Management
      whitelist: [],
      whitelistTiers: [
        {
          tier: 1,
          name: 'Gold Tier',
          allocation: '2000',
          maxContribution: '2000',
          participants: []
        },
        {
          tier: 2,
          name: 'Silver Tier',
          allocation: '1000',
          maxContribution: '1000',
          participants: []
        }
      ]
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
      // Project Information
      projectName: '',
      description: '',
      website: '',
      twitter: '',
      telegram: '',
      discord: '',
      
      // Sale Token Configuration
      saleTokenName: '',
      saleTokenSymbol: '',
      saleTokenDecimals: 8,
      saleTokenTotalSupply: '10000000',
      saleTokenTransferFee: '0.0001',
      
      // Purchase Token Configuration
      purchaseToken: 'ICP',
      
      // Sale Parameters
      saleType: 'FairLaunch',
      allocationMethod: 'Lottery',
      tokenPrice: '0.02',
      softCap: '5000',
      hardCap: '25000',
      minContribution: '5',
      maxContribution: '500', // Anti-whale protection
      totalSaleAmount: '500000',
      requiresWhitelist: true,
      requiresKYC: false, // BlockID instead
      
      // Timeline
      whitelistStart: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      saleStart: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
      saleEnd: new Date(Date.now() + 17 * 24 * 60 * 60 * 1000),
      claimStart: new Date(Date.now() + 18 * 24 * 60 * 60 * 1000),
      
      // Vesting Schedule
      vestingEnabled: true,
      tgePercentage: 25,
      cliffDuration: 30,
      vestingDuration: 270, // 9 months
      vestingInterval: 30,
      
      // Token Distribution
      distribution: [
        {
          category: 'Community Sale',
          percentage: 50,
          totalAmount: '5000000',
          recipients: []
        },
        {
          category: 'Community Treasury',
          percentage: 25,
          totalAmount: '2500000',
          recipients: []
        },
        {
          category: 'Team',
          percentage: 15,
          totalAmount: '1500000',
          recipients: []
        },
        {
          category: 'Development',
          percentage: 10,
          totalAmount: '1000000',
          recipients: []
        }
      ],
      
      // DEX Configuration
      dexConfig: {
        platform: 'Sonic',
        enabled: true,
        listingPrice: '0.025',
        totalLiquidityToken: '100000',
        liquidityLockDays: 180,
        autoList: true,
        slippageTolerance: 5
      },
      
      // Multi-DEX Support
      multiDexEnabled: false,
      multiDexConfig: {},
      
      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: 20,
        developmentFund: 50,
        marketingFund: 30,
        teamRecipients: []
      },
      
      // Affiliate Program
      affiliateEnabled: true,
      affiliateCommissionRate: 3,
      
      // Governance Configuration
      governanceEnabled: true,
      governanceConfig: {
        proposalThreshold: '50000',
        quorumPercentage: 5,
        votingPeriod: 5,
        timelockDuration: 1,
        enableDelegation: true
      },
      
      // Security & Admin
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      enableAuditLog: true,
      platformFeeRate: 2.5,
      
      // Whitelist Management
      whitelist: [],
      whitelistTiers: []
    }
  },

  {
    id: 'enterprise-token',
    name: 'Enterprise Solution',
    description: 'Enterprise-grade token launch with maximum security, compliance, and advanced features.',
    complexity: 'enterprise',
    icon: '🏢',
    badge: 'Premium',
    recommendedFor: [
      'Enterprise companies',
      'Regulated industries',
      'Large-scale projects',
      'Institutional investors'
    ],
    features: [
      'Full compliance suite',
      'Institutional-grade security',
      'Multi-signature controls',
      'Advanced analytics',
      'Priority support',
      'Custom integrations'
    ],
    data: {
      // Project Information
      projectName: '',
      description: '',
      website: '',
      twitter: '',
      telegram: '',
      discord: '',
      whitepaper: '',
      
      // Sale Token Configuration
      saleTokenName: '',
      saleTokenSymbol: '',
      saleTokenDecimals: 8,
      saleTokenTotalSupply: '1000000000',
      saleTokenTransferFee: '0.0001',
      
      // Purchase Token Configuration
      purchaseToken: 'ICP',
      
      // Sale Parameters
      saleType: 'PrivateSale',
      allocationMethod: 'Proportional',
      tokenPrice: '0.10',
      softCap: '100000',
      hardCap: '500000',
      minContribution: '1000',
      maxContribution: '50000',
      totalSaleAmount: '5000000',
      requiresWhitelist: true,
      requiresKYC: true,
      
      // Timeline
      whitelistStart: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      saleStart: new Date(Date.now() + 21 * 24 * 60 * 60 * 1000),
      saleEnd: new Date(Date.now() + 35 * 24 * 60 * 60 * 1000),
      claimStart: new Date(Date.now() + 42 * 24 * 60 * 60 * 1000),
      
      // Vesting Schedule
      vestingEnabled: true,
      tgePercentage: 10,
      cliffDuration: 90, // 3 months
      vestingDuration: 730, // 24 months
      vestingInterval: 30,
      
      // Token Distribution
      distribution: [
        {
          category: 'Private Sale',
          percentage: 15,
          totalAmount: '150000000',
          recipients: []
        },
        {
          category: 'Public Sale',
          percentage: 10,
          totalAmount: '100000000',
          recipients: []
        },
        {
          category: 'Team',
          percentage: 20,
          totalAmount: '200000000',
          recipients: []
        },
        {
          category: 'Advisors',
          percentage: 5,
          totalAmount: '50000000',
          recipients: []
        },
        {
          category: 'Development',
          percentage: 25,
          totalAmount: '250000000',
          recipients: []
        },
        {
          category: 'Marketing',
          percentage: 10,
          totalAmount: '100000000',
          recipients: []
        },
        {
          category: 'Liquidity',
          percentage: 10,
          totalAmount: '100000000',
          recipients: []
        },
        {
          category: 'Reserve',
          percentage: 5,
          totalAmount: '50000000',
          recipients: []
        }
      ],
      
      // DEX Configuration
      dexConfig: {
        platform: 'ICPSwap',
        enabled: true,
        listingPrice: '0.15',
        totalLiquidityToken: '1000000',
        liquidityLockDays: 730,
        autoList: true,
        slippageTolerance: 2
      },
      
      // Multi-DEX Support
      multiDexEnabled: true,
      multiDexConfig: {
        ICPSwap: {
          enabled: true,
          listingPrice: '0.15',
          liquidityAllocation: '50',
          lockDays: 730,
          autoList: true
        },
        Sonic: {
          enabled: true,
          listingPrice: '0.15',
          liquidityAllocation: '30',
          lockDays: 730,
          autoList: true
        },
        KongSwap: {
          enabled: true,
          listingPrice: '0.15',
          liquidityAllocation: '20',
          lockDays: 730,
          autoList: true
        }
      },
      
      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: 15,
        developmentFund: 50,
        marketingFund: 25,
        teamRecipients: []
      },
      
      // Affiliate Program
      affiliateEnabled: true,
      affiliateCommissionRate: 2,
      affiliateConfig: {
        maxCommission: 5,
        tierStructure: [
          { tier: 1, minReferrals: 5, commissionRate: 1 },
          { tier: 2, minReferrals: 25, commissionRate: 2 },
          { tier: 3, minReferrals: 100, commissionRate: 3 }
        ]
      },
      
      // Governance Configuration
      governanceEnabled: true,
      governanceConfig: {
        proposalThreshold: '1000000',
        quorumPercentage: 15,
        votingPeriod: 14,
        timelockDuration: 7,
        enableDelegation: true
      },
      
      // Security & Admin
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      enableAuditLog: true,
      platformFeeRate: 2.5,
      
      // Whitelist Management
      whitelist: [],
      whitelistTiers: [
        {
          tier: 1,
          name: 'Institutional',
          allocation: '25000',
          maxContribution: '50000',
          participants: []
        },
        {
          tier: 2,
          name: 'Premium',
          allocation: '10000',
          maxContribution: '25000',
          participants: []
        },
        {
          tier: 3,
          name: 'Standard',
          allocation: '5000',
          maxContribution: '10000',
          participants: []
        }
      ]
    }
  },

  {
    id: 'gaming-token',
    name: 'Gaming Token',
    description: 'Gaming-focused token with play-to-earn mechanics and community rewards.',
    complexity: 'intermediate',
    icon: '🎮',
    recommendedFor: [
      'Gaming projects',
      'NFT games',
      'Metaverse platforms',
      'Play-to-earn projects'
    ],
    features: [
      'Gaming-optimized tokenomics',
      'Reward pools',
      'Community governance',
      'Anti-bot protection',
      'Seasonal campaigns'
    ],
    data: {
      // Project Information
      projectName: '',
      description: '',
      website: '',
      twitter: '',
      telegram: '',
      discord: '',
      
      // Sale Token Configuration
      saleTokenName: '',
      saleTokenSymbol: '',
      saleTokenDecimals: 8,
      saleTokenTotalSupply: '50000000',
      saleTokenTransferFee: '0.0001',
      
      // Purchase Token Configuration
      purchaseToken: 'ICP',
      
      // Sale Parameters
      saleType: 'PublicSale',
      allocationMethod: 'FirstComeFirstServe',
      tokenPrice: '0.08',
      softCap: '8000',
      hardCap: '40000',
      minContribution: '20',
      maxContribution: '2000',
      totalSaleAmount: '500000',
      requiresWhitelist: true,
      requiresKYC: false,
      
      // Timeline
      whitelistStart: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      saleStart: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
      saleEnd: new Date(Date.now() + 28 * 24 * 60 * 60 * 1000),
      claimStart: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
      
      // Vesting Schedule
      vestingEnabled: true,
      tgePercentage: 40,
      cliffDuration: 14, // 2 weeks
      vestingDuration: 120, // 4 months
      vestingInterval: 14, // bi-weekly
      
      // Token Distribution
      distribution: [
        {
          category: 'Public Sale',
          percentage: 25,
          totalAmount: '12500000',
          recipients: []
        },
        {
          category: 'Game Rewards',
          percentage: 30,
          totalAmount: '15000000',
          recipients: []
        },
        {
          category: 'Team',
          percentage: 15,
          totalAmount: '7500000',
          recipients: []
        },
        {
          category: 'Development',
          percentage: 15,
          totalAmount: '7500000',
          recipients: []
        },
        {
          category: 'Marketing',
          percentage: 10,
          totalAmount: '5000000',
          recipients: []
        },
        {
          category: 'Liquidity',
          percentage: 5,
          totalAmount: '2500000',
          recipients: []
        }
      ],
      
      // DEX Configuration
      dexConfig: {
        platform: 'KongSwap',
        enabled: true,
        listingPrice: '0.10',
        totalLiquidityToken: '75000',
        liquidityLockDays: 90,
        autoList: true,
        slippageTolerance: 8
      },
      
      // Multi-DEX Support
      multiDexEnabled: false,
      multiDexConfig: {},
      
      // Raised Funds Allocation
      raisedFundsAllocation: {
        teamAllocation: 25,
        developmentFund: 45,
        marketingFund: 30,
        teamRecipients: []
      },
      
      // Affiliate Program
      affiliateEnabled: true,
      affiliateCommissionRate: 8,
      affiliateConfig: {
        maxCommission: 15,
        tierStructure: [
          { tier: 1, minReferrals: 3, commissionRate: 5 },
          { tier: 2, minReferrals: 15, commissionRate: 8 },
          { tier: 3, minReferrals: 50, commissionRate: 12 }
        ]
      },
      
      // Governance Configuration
      governanceEnabled: true,
      governanceConfig: {
        proposalThreshold: '25000',
        quorumPercentage: 8,
        votingPeriod: 3,
        timelockDuration: 1,
        enableDelegation: true
      },
      
      // Security & Admin
      adminList: [],
      emergencyContacts: [],
      pausable: true,
      cancellable: true,
      enableAuditLog: true,
      platformFeeRate: 2.5,
      
      // Whitelist Management
      whitelist: [],
      whitelistTiers: [
        {
          tier: 1,
          name: 'Early Gamers',
          allocation: '1500',
          maxContribution: '1500',
          participants: []
        },
        {
          tier: 2,
          name: 'Community',
          allocation: '750',
          maxContribution: '750',
          participants: []
        }
      ]
    }
  }
]

export const getTemplateById = (id: string): LaunchpadTemplate | undefined => {
  return launchpadTemplates.find(template => template.id === id)
}

export const getTemplatesByComplexity = (complexity: LaunchpadTemplate['complexity']): LaunchpadTemplate[] => {
  return launchpadTemplates.filter(template => template.complexity === complexity)
}