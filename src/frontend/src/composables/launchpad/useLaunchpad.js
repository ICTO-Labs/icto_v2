import { ref, computed } from 'vue'
import { toast } from 'vue-sonner'

// Mock data for launchpads
const mockLaunchpads = [
  {
    id: '1',
    name: 'OpenChat DAO',
    symbol: 'OCT',
    logo: '/logos/openchat.svg',
    status: 'launching',
    startDate: '2025-08-01',
    endDate: '2025-08-15',
    raiseTarget: '25000 ICP',
    raised: '15430 ICP',
    progress: 61.72,
    participantCount: 342,
    participated: true,
    raiseType: 'Public Sale',
    minContribution: 10,
    maxContribution: 1000,
    acceptedTokens: ['ICP', 'ICTO'],
    description: 'OpenChat is a decentralized messaging platform built on the Internet Computer, offering secure and private communication.',
    participationInstructions: 'Connect your wallet and contribute ICP or ICTO tokens to participate in the sale.',
    refundConditions: 'If the soft cap of 10,000 ICP is not reached, all contributions will be refunded.',
    contractAddress: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
    tokenomics: {
      totalSupply: '100,000,000 OCT',
      distribution: {
        team: 20,
        publicSale: 25,
        advisors: 5,
        ecosystem: 30,
        treasury: 20
      },
      vestingSchedule: {
        publicSale: {
          tge: 25,
          cliff: 0,
          linear: 6,
          description: 'Public sale tokens: 25% at TGE, 75% linear over 6 months'
        },
        team: {
          tge: 0,
          cliff: 3,
          linear: 18,
          description: 'Team tokens: 3-month cliff, then linear vesting over 18 months'
        }
      }
    },
    links: [
      { label: 'Website', url: 'https://openchat.com' },
      { label: 'Docs', url: 'https://docs.openchat.com' },
      { label: 'GitHub', url: 'https://github.com/openchat' },
      { label: 'Whitepaper', url: 'https://openchat.com/whitepaper.pdf' }
    ],
    team: [
      { name: 'John Doe', role: 'CEO & Founder' },
      { name: 'Jane Smith', role: 'CTO' },
      { name: 'Mike Johnson', role: 'Head of Product' }
    ],
    transactions: [
      { id: '1', wallet: '0x1234...5678', time: '2 hours ago', amount: '500 ICP' },
      { id: '2', wallet: '0xabcd...efgh', time: '3 hours ago', amount: '250 ICP' },
      { id: '3', wallet: '0x9876...5432', time: '5 hours ago', amount: '1000 ICP' }
    ]
  },
  {
    id: '2',
    name: 'DeFinity DEX',
    symbol: 'DFX',
    logo: '/logos/definity.svg',
    status: 'upcoming',
    startDate: '2025-09-01',
    endDate: '2025-09-15',
    raiseTarget: '50000 ICP',
    raised: '0 ICP',
    progress: 0,
    participantCount: 0,
    participated: false,
    raiseType: 'Private Sale',
    minContribution: 100,
    maxContribution: 5000,
    acceptedTokens: ['ICP'],
    description: 'DeFinity DEX is a decentralized exchange built on Internet Computer.',
    tokenomics: {
      totalSupply: '500,000,000 DFX',
      distribution: {
        team: 15,
        publicSale: 30,
        advisors: 5,
        ecosystem: 35,
        treasury: 15
      }
    }
  },
  {
    id: '3',
    name: 'IC Storage',
    symbol: 'ICS',
    logo: '/logos/icstorage.svg',
    status: 'finished',
    startDate: '2025-06-01',
    endDate: '2025-06-15',
    raiseTarget: '15000 ICP',
    raised: '15000 ICP',
    progress: 100,
    participantCount: 523,
    participated: true,
    raiseType: 'Community Sale',
    minContribution: 5,
    maxContribution: 500,
    acceptedTokens: ['ICP', 'ICTO'],
    description: 'Decentralized storage solution on the Internet Computer.',
    tokenomics: {
      totalSupply: '1,000,000,000 ICS',
      distribution: {
        team: 18,
        publicSale: 35,
        advisors: 4,
        ecosystem: 28,
        treasury: 15
      }
    }
  }
]

export function useLaunchpad() {
  const launchpads = ref([])
  const isLoading = ref(false)
  const error = ref(null)

  // Fetch all launchpads
  const fetchLaunchpads = async () => {
    isLoading.value = true
    error.value = null
    
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      launchpads.value = mockLaunchpads
    } catch (err) {
      error.value = err.message
      toast.error('Failed to fetch launchpads')
    } finally {
      isLoading.value = false
    }
  }

  // Fetch single launchpad detail
  const fetchLaunchpadDetail = async (id) => {
    isLoading.value = true
    error.value = null
    
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500))
      return mockLaunchpads.find(l => l.id === id)
    } catch (err) {
      error.value = err.message
      toast.error('Failed to fetch launchpad details')
      return null
    } finally {
      isLoading.value = false
    }
  }

  // Participate in launchpad
  const participate = async (launchpadId, amount, token) => {
    try {
      // Simulate blockchain transaction
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      toast.success(`Successfully participated with ${amount} ${token}!`)
      
      // Update local state
      const launchpad = launchpads.value.find(l => l.id === launchpadId)
      if (launchpad) {
        launchpad.participated = true
        launchpad.participantCount++
      }
      
      return { success: true, txHash: '0x' + Math.random().toString(36).substr(2, 9) }
    } catch (err) {
      toast.error('Failed to participate', {
        description: err.message
      })
      throw err
    }
  }

  // Connect wallet (mock)
  const connectWallet = async () => {
    try {
      await new Promise(resolve => setTimeout(resolve, 1000))
      toast.success('Wallet connected successfully!')
      return true
    } catch (err) {
      toast.error('Failed to connect wallet')
      return false
    }
  }

  return {
    launchpads: computed(() => launchpads.value),
    isLoading: computed(() => isLoading.value),
    error: computed(() => error.value),
    fetchLaunchpads,
    fetchLaunchpadDetail,
    participate,
    connectWallet
  }
}
