<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-4">
        <button @click="$router.go(-1)" class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
          <ArrowLeftIcon class="h-5 w-5 text-gray-500" />
        </button>
        <div>
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">DAO Proposals</h1>
          <p class="text-gray-600 dark:text-gray-400">{{ dao?.name || 'Loading...' }}</p>
        </div>
      </div>
      
      <button 
        @click="showCreateProposalModal = true"
        v-auth-required
        class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200"
      >
        <PlusIcon class="h-4 w-4 mr-2" />
        Create Proposal
      </button>
    </div>

    <!-- Filters -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-4">
      <div class="flex items-center space-x-4">
        <div class="flex space-x-1 bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
          <button 
            v-for="status in statusFilters" 
            :key="status.value"
            @click="activeFilter = status.value"
            :class="[
              'px-3 py-1.5 text-sm font-medium rounded-md transition-colors',
              activeFilter === status.value
                ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
            ]"
          >
            {{ status.label }}
          </button>
        </div>

        <div class="relative flex-1 max-w-xs">
          <SearchIcon class="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search proposals..."
            class="pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-sm focus:ring-2 focus:ring-yellow-500 focus:border-transparent w-full"
          />
        </div>
      </div>
    </div>

    <!-- Proposals List -->
    <div class="space-y-4">
      <div v-if="isLoading" class="text-center py-12">
        <div class="inline-flex items-center px-6 py-3 border border-transparent rounded-full shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600">
          <div class="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white mr-3"></div>
          Loading proposals...
        </div>
      </div>

      <div v-else-if="filteredProposals.length === 0" class="text-center py-12">
        <VoteIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          {{ searchQuery || activeFilter !== 'all' ? 'No proposals found' : 'No proposals yet' }}
        </h3>
        <p class="text-gray-500 dark:text-gray-400 mb-6">
          {{ searchQuery || activeFilter !== 'all' 
            ? 'Try adjusting your search or filter criteria.' 
            : 'Be the first to create a proposal for this DAO.' 
          }}
        </p>
        <button 
          v-if="!searchQuery && activeFilter === 'all'"
          @click="showCreateProposalModal = true"
          v-auth-required="{ message: 'Please connect your wallet to continue' }"
          class="inline-flex items-center px-6 py-3 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200"
        >
          <PlusIcon class="h-5 w-5 mr-2" />
          Create First Proposal
        </button>
      </div>

      <div v-else class="space-y-4">
        <ProposalCard
          v-for="proposal in filteredProposals"
          :key="proposal.id"
          :proposal="proposal"
          :dao="dao"
          @click="goToProposal(proposal.id)"
        />
      </div>
    </div>

    <!-- Create Proposal Modal -->
    <CreateProposalModal
      v-if="showCreateProposalModal && dao"
      :dao="dao"
      @close="showCreateProposalModal = false"
      @success="handleProposalSuccess"
    />
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { DAOService } from '@/api/services/dao'
import {
  ArrowLeftIcon,
  PlusIcon,
  SearchIcon,
  VoteIcon
} from 'lucide-vue-next'
import ProposalCard from '@/components/dao/ProposalCard.vue'
import CreateProposalModal from '@/components/dao/CreateProposalModal.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import type { DAO, Proposal } from '@/types/dao'
import AdminLayout from '@/components/layout/AdminLayout.vue'

const route = useRoute()
const router = useRouter()
const daoService = DAOService.getInstance()

// State
const dao = ref<DAO | null>(null)
const proposals = ref<Proposal[]>([])
const isLoading = ref(true)
const searchQuery = ref('')
const activeFilter = ref('all')
const showCreateProposalModal = ref(false)

const statusFilters = [
  { label: 'All', value: 'all' },
  { label: 'Open', value: 'open' },
  { label: 'Accepted', value: 'accepted' },
  { label: 'Rejected', value: 'rejected' },
  { label: 'Executed', value: 'succeeded' }
]

// Computed
const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: dao.value?.name || 'DAO', to: `/dao/${route.params.id}` },
  { label: 'Proposals' }
])

const filteredProposals = computed(() => {
  let filtered = [...proposals.value]
  
  // Apply search filter
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(proposal => 
      proposal.payload.title.toLowerCase().includes(query) ||
      proposal.payload.description.toLowerCase().includes(query)
    )
  }
  
  // Apply status filter
  if (activeFilter.value !== 'all') {
    filtered = filtered.filter(proposal => proposal.state === activeFilter.value)
  }
  
  return filtered.sort((a, b) => Number(b.timestamp) - Number(a.timestamp))
})

// Methods
const fetchData = async () => {
  isLoading.value = true

  try {
    const daoId = route.params.id as string
    
    // Fetch DAO details
    const daoData = await daoService.getDAO(daoId)
    if (!daoData) {
      router.push('/dao')
      return
    }
    dao.value = daoData

    // Fetch proposals
    const proposalData = await daoService.getProposals(daoId)
    proposals.value = proposalData

  } catch (err) {
    console.error('Error fetching proposals:', err)
  } finally {
    isLoading.value = false
  }
}

const goToProposal = (proposalId: number) => {
  router.push(`/dao/${route.params.id}/proposal/${proposalId}`)
}

const handleProposalSuccess = () => {
  showCreateProposalModal.value = false
  fetchData() // Refresh proposals
}

onMounted(() => {
  fetchData()
})
</script>