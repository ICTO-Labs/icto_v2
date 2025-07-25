<template>
  <div class="container mx-auto px-4 py-6">
    <!-- Loading State -->
    <div v-if="isLoading" class="flex justify-center items-center py-12">
      <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
    </div>

    <!-- Error State -->
    <div v-else-if="!campaign" class="bg-red-50 border-l-4 border-red-400 p-4">
      <p class="text-sm text-red-700">Could not find the distribution campaign.</p>
    </div>

    <!-- Campaign Content -->
    <div v-else-if="campaign">
      <!-- Header -->
      <div class="mb-8">
        <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-6">
          <div class="flex items-center space-x-4">
            <div class="w-16 h-16 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
              <img :src="campaign.token.icon || '/default-token-icon.svg'" :alt="campaign.token.symbol" class="w-10 h-10"/>
            </div>
            <div>
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{{ campaign.title }}</h1>
              <div class="flex items-center space-x-3 mt-1">
                <span :class="statusInfo.class" class="px-2.5 py-0.5 rounded-full text-xs font-medium">{{ statusInfo.text }}</span>
                <span class="text-sm text-gray-500 dark:text-gray-400">{{ campaign.type }}</span>
              </div>
            </div>
          </div>
          <div class="flex items-center space-x-3 mt-4 sm:mt-0">
            <button @click="router.back()" class="btn-secondary">
              <CircleArrowLeftIcon class="h-4 w-4 mr-2" />
              Back
            </button>
          </div>
        </div>

        <!-- Campaign Info Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <!-- Campaign Info -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Campaign Info</h3>
            <div class="space-y-4">
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Token</span>
                <div class="flex items-center mt-1">
                  <img :src="campaign.token.icon || '/default-token-icon.svg'" :alt="campaign.token.symbol" class="w-6 h-6 mr-2 rounded-full"/>
                  <span class="text-sm font-medium text-gray-900 dark:text-white">{{ campaign.token.symbol }} - {{ campaign.token.name }}</span>
                </div>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Distribution Method</span>
                <p class="text-sm font-medium text-gray-900 dark:text-white capitalize">{{ campaign?.method?.toLowerCase().replace('_', ' ') }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Whitelist Required</span>
                <span :class="campaign?.isWhitelisted ? 'bg-yellow-100 text-yellow-800' : 'bg-green-100 text-green-800'" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium">
                  {{ campaign?.isWhitelisted ? 'Yes' : 'No' }}
                </span>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Max per Wallet</span>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ campaign?.maxPerWallet ? campaign.maxPerWallet.toLocaleString() + ' tokens' : 'Unlimited' }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Creator</span>
                <p class="text-sm font-mono text-gray-900 dark:text-white font-medium">{{ campaign?.creator?.slice(0, 8) }}...{{ campaign?.creator?.slice(-6) }}</p>
              </div>
            </div>
          </div>

          <!-- Timeline -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Timeline</h3>
            <div class="space-y-4">
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Start Time</span>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ formatDate(campaign?.startTime) }}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400">{{ formatRelativeTime(campaign?.startTime) }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">End Time</span>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ formatDate(campaign?.endTime) }}</p>
                <p class="text-xs text-gray-500 dark:text-gray-400">{{ formatRelativeTime(campaign?.endTime) }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Duration</span>
                <p class="text-sm font-medium text-gray-900 dark:text-white">{{ formatDuration(campaign?.startTime, campaign?.endTime) }}</p>
              </div>
            </div>
          </div>

          <!-- Stats -->
          <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Statistics</h3>
            <div class="space-y-4">
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Total Amount</span>
                <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ formatNumber(campaign.totalAmount) }} {{ campaign.token.symbol }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Distributed</span>
                <p class="text-2xl font-bold text-gray-900 dark:text-white">{{ formatNumber(campaign.distributedAmount) }} {{ campaign.token.symbol }}</p>
              </div>
              <div>
                <span class="text-sm text-gray-500 dark:text-gray-400">Progress</span>
                <div class="mt-1">
                  <div class="flex justify-between text-sm">
                    <span>{{ Math.round((campaign.distributedAmount / campaign.totalAmount) * 100) }}%</span>
                    <span>{{ formatNumber(campaign.distributedAmount) }} / {{ formatNumber(campaign.totalAmount) }}</span>
                  </div>
                  <div class="w-full bg-gray-200 rounded-full h-2 mt-1">
                    <div class="bg-blue-600 h-2 rounded-full" :style="`width: ${(campaign.distributedAmount / campaign.totalAmount) * 100}%`"></div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div class="stat-card">
          <h3 class="stat-title">Total Amount</h3>
          <p class="stat-value">{{ formatNumber(campaign.totalAmount) }} {{ campaign.token.symbol }}</p>
        </div>
        <div class="stat-card">
          <h3 class="stat-title">Distributed</h3>
          <p class="stat-value">{{ formatNumber(campaign.distributedAmount) }} {{ campaign.token.symbol }}</p>
        </div>
        <div class="stat-card">
          <h3 class="stat-title">Start Time</h3>
          <p class="stat-value">{{ formatDate(campaign.startTime) }}</p>
        </div>
        <div class="stat-card">
          <h3 class="stat-title">End Time</h3>
          <p class="stat-value">{{ formatDate(campaign.endTime) }}</p>
        </div>
      </div>

      <!-- Tabs -->
      <div>
        <div class="border-b border-gray-200 dark:border-gray-700">
          <nav class="-mb-px flex space-x-8" aria-label="Tabs">
            <button v-for="tab in tabs" :key="tab.name" @click="activeTab = tab.name"
              :class="[
                'whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm',
                activeTab === tab.name
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300 dark:hover:border-gray-600'
              ]">
              {{ tab.name }}
            </button>
          </nav>
        </div>
        <div class="mt-6">
          <!-- Overview Tab -->
          <CampaignOverviewTab v-if="activeTab === 'Overview'" :campaign="campaign" :format-number="formatNumber" :format-duration="formatDuration" />
          
          <!-- Participants Tab -->
          <ParticipantsTab v-else-if="activeTab === 'Participants'" :participants="mockParticipants" :format-number="formatNumber" />
          
          <!-- History Tab -->
          <HistoryTab v-else-if="activeTab === 'History'" :history="mockHistory" :format-number="formatNumber" :format-date="formatDate" />
          
          <!-- My Activity Tab -->
          <MyActivityTab v-else-if="activeTab === 'My Activity'" :format-number="formatNumber" />
          
          <!-- Analytics Tab -->
          <AnalyticsTab v-else-if="activeTab === 'Analytics'" :regions="mockRegions" :format-number="formatNumber" />
      </div>
    </div>
  </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import CampaignOverviewTab from './tabs/CampaignOverviewTab.vue';
import ParticipantsTab from './tabs/ParticipantsTab.vue';
import HistoryTab from './tabs/HistoryTab.vue';
import MyActivityTab from './tabs/MyActivityTab.vue';
import AnalyticsTab from './tabs/AnalyticsTab.vue';
import { useDistributionStore } from '@/stores/distribution';
import { ArrowLeft } from 'lucide-vue-next';
import type { CampaignStatus } from '@/types/distribution';

// Tab components are now inline - no external imports needed

const route = useRoute();
const router = useRouter();
const store = useDistributionStore();

const campaignId = route.params.id as string;
// Mock data for display when backend has no data
const mockCampaign = {
  id: campaignId,
  title: 'Community Airdrop Campaign',
  type: 'Airdrop' as const,
  token: {
    symbol: 'ICTO',
    name: 'ICTO Token',
    icon: '🪙'
  },
  totalAmount: 1000000,
  distributedAmount: 750000,
  startTime: new Date('2024-01-15T10:00:00Z'),
  endTime: new Date('2024-02-15T10:00:00Z'),
  method: 'Immediate' as const,
  isWhitelisted: true,
  status: 'Ongoing' as const,
  creator: '0x742d35Cc6634C0532925a3b8D2A6C8d1e1b92c3A',
  description: 'A community airdrop campaign to reward early supporters and active community members through fair and transparent distribution mechanisms.',
  maxPerWallet: 5000
};

// Mock data for tabs
const mockParticipants = [
  { address: '0x1234...5678', claimedAmount: 2500, totalEligibleAmount: 5000 },
  { address: '0xabcd...efgh', claimedAmount: 4000, totalEligibleAmount: 4000 },
  { address: '0x9876...5432', claimedAmount: 1800, totalEligibleAmount: 3000 },
  { address: '0xzyxw...vuts', claimedAmount: 5000, totalEligibleAmount: 5000 },
  { address: '0x1111...2222', claimedAmount: 1200, totalEligibleAmount: 2500 },
  { address: '0x3333...4444', claimedAmount: 3200, totalEligibleAmount: 4000 },
  { address: '0x5555...6666', claimedAmount: 2800, totalEligibleAmount: 3500 },
  { address: '0x7777...8888', claimedAmount: 4500, totalEligibleAmount: 5000 }
];

const mockHistory = [
  { recipient: '0x1234...5678', amount: 2500, timestamp: new Date('2024-01-20T10:30:00Z'), status: 'Success' },
  { recipient: '0xabcd...efgh', amount: 4000, timestamp: new Date('2024-01-20T09:15:00Z'), status: 'Success' },
  { recipient: '0x9876...5432', amount: 1800, timestamp: new Date('2024-01-19T14:22:00Z'), status: 'Success' },
  { recipient: '0xzyxw...vuts', amount: 5000, timestamp: new Date('2024-01-19T11:45:00Z'), status: 'Success' },
  { recipient: '0x1111...2222', amount: 1200, timestamp: new Date('2024-01-18T16:20:00Z'), status: 'Success' },
  { recipient: '0x3333...4444', amount: 3200, timestamp: new Date('2024-01-18T13:10:00Z'), status: 'Success' },
  { recipient: '0x5555...6666', amount: 2800, timestamp: new Date('2024-01-17T15:30:00Z'), status: 'Success' },
  { recipient: '0x7777...8888', amount: 4500, timestamp: new Date('2024-01-17T12:00:00Z'), status: 'Success' }
];

const mockRegions = [
  { name: 'North America', percentage: 35, color: 'bg-blue-500' },
  { name: 'Europe', percentage: 28, color: 'bg-green-500' },
  { name: 'Asia', percentage: 22, color: 'bg-purple-500' },
  { name: 'South America', percentage: 8, color: 'bg-yellow-500' },
  { name: 'Africa', percentage: 4, color: 'bg-red-500' },
  { name: 'Oceania', percentage: 3, color: 'bg-indigo-500' }
];

const campaign = computed(() => {
  // Return mock data when no store data available
  // const storeCampaign = store.getCampaignById(campaignId);
  return mockCampaign;
});

const isLoading = computed(() => false); // Mock: no loading
const error = computed(() => null); // Mock: no error

onMounted(() => {
  if (store.campaigns.length === 0) {
    store.fetchCampaigns();
  }
});

const tabs = [
  { name: 'Overview' },
  { name: 'Participants' },
  { name: 'History' },
  { name: 'My Activity' },
  { name: 'Analytics' }
];

const activeTab = ref('Overview');

const statusInfo = computed(() => {
  if (!campaign.value) return { class: '', text: '' };
  const status = campaign.value.status as CampaignStatus;
  switch (status) {
    case 'Ongoing':
      return { class: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300', text: 'Active' };
    case 'Upcoming':
      return { class: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300', text: 'Upcoming' };
    case 'Ended':
      return { class: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300', text: 'Ended' };
    default:
      return { class: 'bg-gray-100 text-gray-800', text: status };
  }
});

// Helper functions
const formatNumber = (num: number) => {
  return new Intl.NumberFormat('en-US').format(num);
};

const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US', {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date);
};

const formatDuration = (start: Date, end: Date) => {
  const diff = end.getTime() - start.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  return `${days} days`;
};

const formatRelativeTime = (date: Date) => {
  const now = new Date();
  const diff = date.getTime() - now.getTime();
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  
  if (days > 0) {
    return `in ${days} day${days > 1 ? 's' : ''}`;
  } else if (days < 0) {
    return `${Math.abs(days)} day${Math.abs(days) > 1 ? 's' : ''} ago`;
  } else {
    return 'Today';
  }
};
</script>

<style scoped>
.btn-secondary {
  display: inline-flex;
  align-items: center;
  padding: 0.5rem 1rem;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  background-color: white;
  cursor: pointer;
}
.btn-secondary:hover {
  background-color: #f9fafb;
}
.btn-secondary:focus {
  outline: none;
  box-shadow: 0 0 0 2px #3b82f6, 0 0 0 4px rgba(59, 130, 246, 0.5);
}

.dark .btn-secondary {
  background-color: #1f2937;
  border-color: #4b5563;
  color: #d1d5db;
}

.dark .btn-secondary:hover {
  background-color: #374151;
}

.stat-card {
  background-color: white;
  border-radius: 0.75rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  padding: 1.5rem;
}

.dark .stat-card {
  background-color: #1f2937;
}

.stat-title {
  font-size: 0.875rem;
  font-weight: 500;
  color: #6b7280;
}

.dark .stat-title {
  color: #9ca3af;
}

.stat-value {
  margin-top: 0.25rem;
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
}

.dark .stat-value {
  color: white;
}
</style>