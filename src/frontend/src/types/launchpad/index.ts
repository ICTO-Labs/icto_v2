export interface Launchpad {
  id: string
  name: string
  symbol: string
  logo: string
  status: 'upcoming' | 'launching' | 'finished'
  startDate: string
  endDate: string
  raiseTarget: string
  raised: string
  progress: number
  participantCount: number
  participated: boolean
  raiseType: 'Public Sale' | 'Private Sale' | 'Community Sale'
  minContribution: number
  maxContribution: number
  acceptedTokens: string[]
  description: string
  participationInstructions?: string
  refundConditions?: string
  contractAddress?: string
  tokenomics: Tokenomics
  links?: Link[]
  team?: TeamMember[]
  transactions?: Transaction[]
}

export interface Tokenomics {
  totalSupply: string
  distribution: TokenDistribution
  vestingSchedule?: VestingSchedule
}

export interface TokenDistribution {
  team: number
  publicSale: number
  advisors: number
  ecosystem: number
  treasury: number
  [key: string]: number
}

export interface VestingSchedule {
  publicSale?: VestingPlan
  team?: VestingPlan
  [key: string]: VestingPlan | undefined
}

export interface VestingPlan {
  tge: number // Token Generation Event percentage
  cliff: number // Cliff period in months
  linear: number // Linear vesting period in months
  description: string
}

export interface Link {
  label: string
  url: string
}

export interface TeamMember {
  name: string
  role: string
  bio?: string
  avatar?: string
}

export interface Transaction {
  id: string
  wallet: string
  time: string
  amount: string
  txHash?: string
}

export interface ParticipateParams {
  launchpadId: string
  amount: number
  token: 'ICP' | 'ICTO'
}

export interface ParticipateResult {
  success: boolean
  txHash: string
  error?: string
}
