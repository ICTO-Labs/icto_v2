/**
 * Dashboard Utilities
 * Helper functions for dashboard data processing and formatting
 */

/**
 * Format ICP amount from e8s to human-readable format
 */
export function formatICP(e8s: bigint | number): string {
  const amount = typeof e8s === 'bigint' ? Number(e8s) : e8s
  const icp = amount / 100_000_000

  if (icp >= 1000000) {
    return `${(icp / 1000000).toFixed(2)}M ICP`
  } else if (icp >= 1000) {
    return `${(icp / 1000).toFixed(2)}K ICP`
  } else if (icp >= 1) {
    return `${icp.toFixed(2)} ICP`
  } else {
    return `${icp.toFixed(4)} ICP`
  }
}

/**
 * Format large numbers with K/M/B suffixes
 */
export function formatNumber(num: number): string {
  if (num >= 1_000_000_000) {
    return `${(num / 1_000_000_000).toFixed(1)}B`
  } else if (num >= 1_000_000) {
    return `${(num / 1_000_000).toFixed(1)}M`
  } else if (num >= 1_000) {
    return `${(num / 1_000).toFixed(1)}K`
  }
  return num.toString()
}

/**
 * Calculate percentage change
 */
export function calculateChange(current: number, previous: number): number {
  if (previous === 0) return 100
  return Number((((current - previous) / previous) * 100).toFixed(1))
}

/**
 * Generate mock time series data for charts (last 7 days)
 */
export function generateMockTimeSeries(baseValue: number, variance: number = 0.2) {
  const data = []
  const labels = []
  const now = new Date()

  for (let i = 6; i >= 0; i--) {
    const date = new Date(now)
    date.setDate(date.getDate() - i)
    labels.push(date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }))

    // Generate random value with variance
    const randomFactor = 1 + (Math.random() - 0.5) * variance
    data.push(Math.floor(baseValue * randomFactor))
  }

  return { data, labels }
}

/**
 * Get factory status based on README information
 */
export function getFactoryStatus(factoryName: string): 'Production' | 'Beta' | 'Coming Soon' {
  const statuses: Record<string, 'Production' | 'Beta' | 'Coming Soon'> = {
    'token_factory': 'Production',
    'multisig_factory': 'Production',
    'distribution_factory': 'Production',
    'dao_factory': 'Beta',
    'launchpad_factory': 'Beta'
  }
  return statuses[factoryName] || 'Coming Soon'
}

/**
 * Get factory deployment fee from README (in ICP)
 */
export function getFactoryFeeInfo(factoryName: string): string {
  const fees: Record<string, string> = {
    'token_factory': '1.0',
    'multisig_factory': '0.5',
    'distribution_factory': '1.0',
    'dao_factory': '5.0',
    'launchpad_factory': '10.0'
  }
  return fees[factoryName] || 'N/A'
}

/**
 * Get factory key features
 */
export function getFactoryFeatures(factoryName: string): string[] {
  const features: Record<string, string[]> = {
    'token_factory': ['ICRC-1/2 Compliant', 'SNS-W WASM', 'O(1) Queries', 'Version Management'],
    'multisig_factory': ['Multi-Signature', 'Customizable Policies', 'Observer Roles', 'Real-time Sync'],
    'distribution_factory': ['Vesting', 'Airdrops', 'Token Locks', 'Batch Distribution'],
    'dao_factory': ['Governance', 'Proposal System', 'Voting', 'Treasury Management'],
    'launchpad_factory': ['Token Presale', 'Whitelist', 'Vesting', 'Refund Support']
  }
  return features[factoryName] || []
}

/**
 * Get factory gradient classes for UI
 */
export function getFactoryGradient(factoryName: string): {
  card: string
  button: string
} {
  const gradients: Record<string, { card: string, button: string }> = {
    'token_factory': {
      card: 'from-blue-500 to-blue-700',
      button: 'from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700'
    },
    'multisig_factory': {
      card: 'from-purple-500 to-purple-700',
      button: 'from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700'
    },
    'distribution_factory': {
      card: 'from-green-500 to-green-700',
      button: 'from-green-500 to-green-600 hover:from-green-600 hover:to-green-700'
    },
    'dao_factory': {
      card: 'from-orange-500 to-orange-700',
      button: 'from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700'
    },
    'launchpad_factory': {
      card: 'from-pink-500 to-pink-700',
      button: 'from-pink-500 to-pink-600 hover:from-pink-600 hover:to-pink-700'
    }
  }
  return gradients[factoryName] || gradients.token_factory
}
