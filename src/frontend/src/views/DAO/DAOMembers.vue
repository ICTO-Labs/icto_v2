<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-center space-x-4 mb-4">
          <button 
            @click="$router.go(-1)"
            class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors"
          >
            <ArrowLeftIcon class="h-5 w-5" />
          </button>
          <div>
            <h1 class="text-3xl font-bold text-gray-900 dark:text-white">DAO Members</h1>
            <p class="text-gray-600 dark:text-gray-300 mt-1">
              {{ dao?.name || 'Loading...' }} - Member Directory
            </p>
          </div>
        </div>

        <!-- DAO Header Info -->
        <div v-if="dao" class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 mb-6">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-4">
              <div class="p-3 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-xl">
                <UsersIcon class="h-8 w-8 text-white" />
              </div>
              <div>
                <h2 class="text-xl font-semibold text-gray-900 dark:text-white">{{ dao.name }}</h2>
                <p class="text-gray-600 dark:text-gray-300">{{ bigintToNumber(dao.stats.totalMembers) }} Members</p>
              </div>
            </div>
            <div class="text-right">
              <div class="text-2xl font-bold text-yellow-600 dark:text-yellow-400">
                {{ formatTokenAmount(bigintToString(dao.stats.totalStaked), dao.tokenConfig.symbol) }}
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">Total Staked</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Filters and Search -->
      <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 mb-6">
        <div class="flex flex-col sm:flex-row gap-4">
          <!-- Search -->
          <div class="flex-1">
            <div class="relative">
              <SearchIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                v-model="searchQuery"
                type="text"
                placeholder="Search members by address..."
                class="w-full pl-10 pr-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500"
              />
            </div>
          </div>

          <!-- Sort Options -->
          <div class="sm:w-48">
            <select
              v-model="sortBy"
              class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500"
            >
              <option value="votingPower">Voting Power</option>
              <option value="staked">Staked Amount</option>
              <option value="proposals">Proposals Created</option>
              <option value="joined">Join Date</option>
            </select>
          </div>

          <!-- Filter Options -->
          <div class="sm:w-48">
            <select
              v-model="filterBy"
              class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500"
            >
              <option value="all">All Members</option>
              <option value="staked">Staked Members</option>
              <option value="delegated">Has Delegation</option>
              <option value="active">Active Voters</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="flex justify-center py-12">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-yellow-500"></div>
      </div>

      <!-- Members List -->
      <div v-else-if="filteredMembers.length > 0" class="space-y-4">
        <MemberCard
          v-for="member in paginatedMembers"
          :key="member.address"
          :member="member"
          :dao="dao"
          @click="viewMemberDetail(member)"
        />

        <!-- Pagination -->
        <div v-if="totalPages > 1" class="flex justify-center mt-8">
          <nav class="flex items-center space-x-2">
            <button
              @click="currentPage = Math.max(1, currentPage - 1)"
              :disabled="currentPage === 1"
              class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-800 dark:border-gray-600 dark:text-gray-400 dark:hover:bg-gray-700"
            >
              Previous
            </button>
            
            <span class="px-4 py-2 text-sm text-gray-700 dark:text-gray-300">
              Page {{ currentPage }} of {{ totalPages }}
            </span>
            
            <button
              @click="currentPage = Math.min(totalPages, currentPage + 1)"
              :disabled="currentPage === totalPages"
              class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-800 dark:border-gray-600 dark:text-gray-400 dark:hover:bg-gray-700"
            >
              Next
            </button>
          </nav>
        </div>
      </div>

      <!-- Empty State -->
      <div v-else-if="!isLoading" class="text-center py-12">
        <UsersIcon class="h-16 w-16 text-gray-400 mx-auto mb-4" />
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">No members found</h3>
        <p class="text-gray-500 dark:text-gray-400">
          {{ searchQuery ? 'No members match your search criteria.' : 'This DAO has no members yet.' }}
        </p>
      </div>
    </div>

    <!-- Member Detail Modal -->
    <MemberDetailModal
      v-if="selectedMember"
      :member="selectedMember"
      :dao="dao"
      @close="selectedMember = null"
    />
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import {
  ArrowLeftIcon,
  UsersIcon,
  SearchIcon
} from 'lucide-vue-next'
import { useDAOStore } from '@/stores/dao'
import type { DAO, MemberInfo } from '@/types/dao'
import { bigintToNumber, bigintToString } from '@/types/dao'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import MemberCard from '@/components/dao/MemberCard.vue'
import MemberDetailModal from '@/components/dao/MemberDetailModal.vue'

interface ExtendedMemberInfo extends MemberInfo {
  address: string
}

const route = useRoute()
const daoStore = useDAOStore()

// State
const dao = ref<DAO | null>(null)
const members = ref<ExtendedMemberInfo[]>([])
const isLoading = ref(true)
const selectedMember = ref<ExtendedMemberInfo | null>(null)

// Filters
const searchQuery = ref('')
const sortBy = ref('votingPower')
const filterBy = ref('all')
const currentPage = ref(1)
const pageSize = 20

// Computed
const filteredMembers = computed(() => {
  let filtered = [...members.value]

  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(member => 
      member.address.toLowerCase().includes(query)
    )
  }

  // Apply category filter
  if (filterBy.value !== 'all') {
    filtered = filtered.filter(member => {
      switch (filterBy.value) {
        case 'staked':
          return bigintToNumber(member.stakedAmount) > 0
        case 'delegated':
          return member.delegatedTo && member.delegatedTo.length > 0
        case 'active':
          return bigintToNumber(member.proposalsVoted) > 0
        default:
          return true
      }
    })
  }

  // Apply sorting
  filtered.sort((a, b) => {
    switch (sortBy.value) {
      case 'votingPower':
        return bigintToNumber(b.votingPower) - bigintToNumber(a.votingPower)
      case 'staked':
        return bigintToNumber(b.stakedAmount) - bigintToNumber(a.stakedAmount)
      case 'proposals':
        return bigintToNumber(b.proposalsCreated) - bigintToNumber(a.proposalsCreated)
      case 'joined':
        return bigintToNumber(b.joinedAt) - bigintToNumber(a.joinedAt)
      default:
        return 0
    }
  })

  return filtered
})

const totalPages = computed(() => Math.ceil(filteredMembers.value.length / pageSize))

const paginatedMembers = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  const end = start + pageSize
  return filteredMembers.value.slice(start, end)
})

const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: dao.value?.name || 'DAO', to: `/dao/${route.params.id}` },
  { label: 'Members' }
])

// Methods
const fetchDAO = async () => {
  const daoId = route.params.id as string
  try {
    const result = await daoStore.fetchDAO(daoId)
    dao.value = result
  } catch (error) {
    console.error('Error fetching DAO:', error)
  }
}

const fetchMembers = async () => {
  // Note: This is a placeholder implementation
  // In a real app, you would call a service to get all members
  // For now, we'll simulate with mock data
  try {
    isLoading.value = true
    
    // Mock member data - in reality this would come from the backend
    const mockMembers: ExtendedMemberInfo[] = [
      {
        address: 'rdmx6-jaaaa-aaaah-qcaaa-cai',
        stakedAmount: BigInt(1000000000),
        votingPower: BigInt(1200000000),
        delegatedTo: [],
        delegatedFrom: BigInt(200000000),
        proposalsCreated: BigInt(5),
        proposalsVoted: BigInt(12),
        joinedAt: BigInt(Date.now() * 1000000 - 86400000 * 30 * 1000000)
      },
      {
        address: 'rrkah-fqaaa-aaaah-qcaaa-cai', 
        stakedAmount: BigInt(500000000),
        votingPower: BigInt(500000000),
        delegatedTo: [],
        delegatedFrom: BigInt(0),
        proposalsCreated: BigInt(2),
        proposalsVoted: BigInt(8),
        joinedAt: BigInt(Date.now() * 1000000 - 86400000 * 15 * 1000000)
      }
    ]
    
    members.value = mockMembers
  } catch (error) {
    console.error('Error fetching members:', error)
  } finally {
    isLoading.value = false
  }
}

const viewMemberDetail = (member: ExtendedMemberInfo) => {
  selectedMember.value = member
}

const formatTokenAmount = (amount: string, symbol: string): string => {
  const num = parseFloat(amount)
  if (isNaN(num)) return '0 ' + symbol
  
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1) + 'M ' + symbol
  } else if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'K ' + symbol
  }
  return Math.floor(num).toString() + ' ' + symbol
}

// Watchers
watch([searchQuery, sortBy, filterBy], () => {
  currentPage.value = 1
})

// Lifecycle
onMounted(async () => {
  await Promise.all([
    fetchDAO(),
    fetchMembers()
  ])
})
</script>

<style scoped>
/* Add any additional styling if needed */
</style>