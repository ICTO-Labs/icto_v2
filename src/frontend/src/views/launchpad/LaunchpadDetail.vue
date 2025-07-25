<template>
  <AdminLayout>
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <!-- Back Button -->
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <router-link 
          to="/launchpad" 
          class="inline-flex items-center text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
        >
          <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
          </svg>
          Back to Launchpads
        </router-link>
      </div>

      <div v-if="launchpad" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-12">
        <!-- Header Section -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl overflow-hidden mb-8">
          <div class="bg-gradient-to-r from-blue-600 to-purple-600 p-8">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-6">
                <img 
                  :src="launchpad.logo || '/placeholder-logo.png'" 
                  alt="Logo" 
                  class="h-20 w-20 rounded-full bg-white shadow-lg object-cover"
                  @error="handleImageError"
                >
                <div>
                  <h1 class="text-3xl font-bold text-white mb-2">{{ launchpad.name }}</h1>
                  <div class="flex items-center space-x-4">
                    <span class="text-lg text-blue-100">${{ launchpad.symbol }}</span>
                    <StatusBadge :status="launchpad.status" />
                  </div>
                </div>
              </div>
              <div class="text-right">
                <p class="text-sm text-blue-100 mb-1">Total Raise</p>
                <p class="text-2xl font-bold text-white">{{ launchpad.raiseTarget }}</p>
              </div>
            </div>
          </div>

          <!-- Progress Bar -->
          <div class="px-8 py-6 bg-gray-50 dark:bg-gray-900">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Progress</span>
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ launchpad.progress }}%</span>
            </div>
            <div class="w-full bg-gray-200 rounded-full h-3 dark:bg-gray-700 overflow-hidden">
              <div 
                :style="{ width: launchpad.progress + '%' }" 
                class="bg-gradient-to-r from-blue-600 to-purple-600 h-3 rounded-full transition-all duration-700 ease-out"
              />
            </div>
            <div class="flex items-center justify-between mt-2">
              <span class="text-xs text-gray-600 dark:text-gray-400">Raised: {{ launchpad.raised }}</span>
              <span class="text-xs text-gray-600 dark:text-gray-400">Goal: {{ launchpad.raiseTarget }}</span>
            </div>
          </div>
        </div>

        <!-- Tab Navigation -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl overflow-hidden">
          <div class="border-b border-gray-200 dark:border-gray-700">
            <nav class="-mb-px flex" aria-label="Tabs">
              <button
                v-for="(tab, index) in tabs"
                :key="index"
                @click="currentTab = index"
                :class="[
                  'flex-1 py-4 px-6 text-center font-medium text-sm transition-all duration-200',
                  currentTab === index
                    ? 'border-b-2 border-blue-600 text-blue-600 dark:text-blue-400 bg-blue-50 dark:bg-blue-900/20'
                    : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700/50'
                ]"
              >
                <div class="flex items-center justify-center space-x-2">
                  <component :is="tabIcons[index]" class="w-4 h-4" />
                  <span>{{ tab }}</span>
                </div>
              </button>
            </nav>
          </div>

          <!-- Tab Content -->
          <div class="p-8">
            <!-- Overview Tab -->
            <div v-show="currentTab === 0" class="space-y-8">
              <!-- Key Metrics Grid -->
              <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Campaign Duration</h4>
                  <p class="text-lg font-semibold text-gray-900 dark:text-white">
                    {{ formatDate(launchpad.startDate) }} - {{ formatDate(launchpad.endDate) }}
                  </p>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ getDaysLeft() }} days left</p>
                </div>
                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Raise Type</h4>
                  <p class="text-lg font-semibold text-gray-900 dark:text-white">{{ launchpad.raiseType }}</p>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ launchpad.participantCount }} participants</p>
                </div>
                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="text-sm font-medium text-gray-600 dark:text-gray-400 mb-2">Token Price</h4>
                  <p class="text-lg font-semibold text-gray-900 dark:text-white">1 {{ launchpad.symbol }} = 0.1 ICP</p>
                  <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">Listing price: 0.15 ICP</p>
                </div>
              </div>

              <!-- Description -->
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-4">About the Project</h3>
                <p class="text-gray-600 dark:text-gray-400 leading-relaxed">{{ launchpad.description }}</p>
              </div>

              <!-- Action Buttons -->
              <div class="flex flex-col sm:flex-row gap-4">
                <button 
                  @click="openParticipateModal" 
                  :disabled="launchpad.status !== 'launching'"
                  class="flex-1 px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transform hover:-translate-y-0.5 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  <span v-if="launchpad.status === 'launching'">Participate Now</span>
                  <span v-else-if="launchpad.status === 'upcoming'">Coming Soon</span>
                  <span v-else>Sale Ended</span>
                </button>
                <button 
                  v-if="!walletConnected" 
                  @click="connectWallet" 
                  class="px-6 py-3 bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white font-semibold rounded-xl hover:bg-gray-300 dark:hover:bg-gray-600 transition-all duration-200"
                >
                  Connect Wallet
                </button>
              </div>
            </div>

            <!-- Tokenomics Tab -->
            <div v-show="currentTab === 1" class="space-y-8">
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Token Economics</h3>
                <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                  <div>
                    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Total Supply</h4>
                    <p class="text-3xl font-bold text-blue-600 dark:text-blue-400 mb-6">{{ launchpad.tokenomics.totalSupply }}</p>
                    <TokenomicsChart :distribution="launchpad.tokenomics.distribution" />
                  </div>
                  <div>
                    <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Vesting Schedule</h4>
                    <VestingTimeline :vesting="launchpad.tokenomics.vestingSchedule" />
                  </div>
                </div>
              </div>
            </div>

            <!-- Project Info Tab -->
            <div v-show="currentTab === 2" class="space-y-8">
              <div>
                <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Project Information</h3>
                
                <!-- Links -->
                <div class="mb-8">
                  <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Official Links</h4>
                  <div class="flex flex-wrap gap-3">
                    <a 
                      v-for="link in launchpad.links" 
                      :key="link.label"
                      :href="link.url" 
                      target="_blank" 
                      class="inline-flex items-center px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
                    >
                      <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                      </svg>
                      {{ link.label }}
                    </a>
                  </div>
                </div>

                <!-- Team -->
                <div v-if="launchpad.team && launchpad.team.length > 0">
                  <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Team Members</h4>
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div 
                      v-for="member in launchpad.team" 
                      :key="member.name"
                      class="bg-gray-50 dark:bg-gray-900 rounded-xl p-4"
                    >
                      <h5 class="font-semibold text-gray-900 dark:text-white">{{ member.name }}</h5>
                      <p class="text-sm text-gray-600 dark:text-gray-400">{{ member.role }}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <!-- Participation Tab -->
            <div v-show="currentTab === 3" class="space-y-8">
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">How to Participate</h3>
              
              <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-6 mb-6">
                <p class="text-gray-700 dark:text-gray-300">{{ launchpad.participationInstructions }}</p>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Accepted Tokens</h4>
                  <div class="flex flex-wrap gap-2">
                    <span 
                      v-for="token in launchpad.acceptedTokens" 
                      :key="token"
                      class="px-3 py-1 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 rounded-full text-sm font-medium"
                    >
                      {{ token }}
                    </span>
                  </div>
                </div>

                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Contribution Limits</h4>
                  <div class="space-y-2">
                    <p class="text-sm text-gray-600 dark:text-gray-400">
                      <span class="font-medium">Minimum:</span> {{ launchpad.minContribution }} ICP
                    </p>
                    <p class="text-sm text-gray-600 dark:text-gray-400">
                      <span class="font-medium">Maximum:</span> {{ launchpad.maxContribution }} ICP
                    </p>
                  </div>
                </div>

                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Refund Policy</h4>
                  <p class="text-sm text-gray-600 dark:text-gray-400">{{ launchpad.refundConditions }}</p>
                </div>

                <div class="bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                  <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Smart Contract</h4>
                  <div class="flex items-center space-x-2">
                    <code class="text-xs text-gray-600 dark:text-gray-400 break-all">{{ launchpad.contractAddress }}</code>
                    <button 
                      @click="copyToClipboard(launchpad.contractAddress)"
                      class="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                    >
                      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 002 2h2a2 2 0 002-2M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <!-- Activity Tab -->
            <div v-show="currentTab === 4" class="space-y-6">
              <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-6">Recent Activity</h3>
              
              <div class="bg-gray-50 dark:bg-gray-900 rounded-xl overflow-hidden">
                <div class="overflow-x-auto">
                  <table class="w-full">
                    <thead class="bg-gray-100 dark:bg-gray-800">
                      <tr>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Wallet</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Amount</th>
                        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">Time</th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
                      <tr 
                        v-for="tx in launchpad.transactions" 
                        :key="tx.id"
                        class="hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                      >
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white font-mono">{{ tx.wallet }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-blue-600 dark:text-blue-400">{{ tx.amount }}</td>
                        <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-400">{{ tx.time }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <div class="px-6 py-4 border-t border-gray-200 dark:border-gray-700">
                  <button 
                    @click="loadMore" 
                    class="w-full px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                  >
                    Load More
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-else-if="isLoading" class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="animate-pulse">
          <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8 mb-8">
            <div class="h-20 bg-gray-300 dark:bg-gray-700 rounded-full w-20 mb-4"></div>
            <div class="h-8 bg-gray-300 dark:bg-gray-700 rounded w-1/3 mb-2"></div>
            <div class="h-4 bg-gray-300 dark:bg-gray-700 rounded w-1/4"></div>
          </div>
          <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-xl p-8">
            <div class="h-64 bg-gray-300 dark:bg-gray-700 rounded"></div>
          </div>
        </div>
      </div>

      <!-- Not Found State -->
      <div v-else class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div class="text-center py-16">
          <svg class="mx-auto h-24 w-24 text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <h3 class="text-xl font-medium text-gray-900 dark:text-white mb-2">Launchpad not found</h3>
          <p class="text-gray-600 dark:text-gray-400 mb-6">The launchpad you're looking for doesn't exist or has been removed.</p>
          <router-link 
            to="/launchpad" 
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Back to Launchpads
          </router-link>
        </div>
      </div>
    </div>

    <!-- Participate Modal -->
    <ParticipateModal 
      :is-open="showParticipateModal" 
      :launchpad="launchpad"
      @close="showParticipateModal = false"
      @confirm="handleParticipation"
    />
  </AdminLayout>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { 
  HomeIcon, 
  ChartPieIcon, 
  CreditCardIcon, 
  InfoIcon,
  ClockIcon 
} from 'lucide-vue-next'
import StatusBadge from '@/components/Launchpad/StatusBadge.vue'
import TokenomicsChart from '@/components/Launchpad/TokenomicsChart.vue'
import VestingTimeline from '@/components/Launchpad/VestingTimeline.vue'
import ParticipateModal from '@/components/Launchpad/ParticipateModal.vue'
import { useLaunchpad } from '@/composables/launchpad/useLaunchpad'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { toast } from 'vue-sonner'

const route = useRoute()
const { fetchLaunchpadDetail, connectWallet, participate } = useLaunchpad()

// State
const launchpad = ref(null)
const walletConnected = ref(false)
const isLoading = ref(false)
const showParticipateModal = ref(false)
const currentTab = ref(0)

// Tab configuration
const tabs = ['Overview', 'Tokenomics', 'Project Info', 'Participation', 'Activity']
const tabIcons = [
  HomeIcon,
  ChartPieIcon,
  InfoIcon,
  CreditCardIcon,
  ClockIcon
]

// Methods
const loadLaunchpadDetail = async () => {
  isLoading.value = true
  try {
    const launchpadId = route.params.id
    launchpad.value = await fetchLaunchpadDetail(launchpadId)
  } catch (error) {
    console.error('Failed to load launchpad:', error)
  } finally {
    isLoading.value = false
  }
}

const openParticipateModal = () => {
  if (!walletConnected.value) {
    toast.error('Please connect your wallet first')
    return
  }
  showParticipateModal.value = true
}

const handleParticipation = async (data) => {
  try {
    await participate(launchpad.value.id, data.amount, data.token)
    showParticipateModal.value = false
    // Refresh launchpad data
    await loadLaunchpadDetail()
  } catch (error) {
    console.error('Participation failed:', error)
  }
}

const loadMore = () => {
  toast.info('Loading more transactions...')
  // TODO: Implement pagination for transactions
}

const handleImageError = (event) => {
  event.target.src = '/placeholder-logo.png'
}

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    toast.success('Copied to clipboard!')
  } catch (error) {
    toast.error('Failed to copy')
  }
}

// Utility functions
const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', { 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric' 
  })
}

const getDaysLeft = () => {
  if (!launchpad.value) return 0
  const end = new Date(launchpad.value.endDate)
  const now = new Date()
  const diff = end - now
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)))
}

// Lifecycle
onMounted(() => {
  loadLaunchpadDetail()
})
</script>

