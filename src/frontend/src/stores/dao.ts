import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { DAOService } from '@/api/services/dao'
import type { DAO, DAOFilters, MemberInfo, Proposal } from '@/types/dao'
import { bigintToNumber, bigintToString } from '@/types/dao'

export const useDAOStore = defineStore('dao', () => {
  const daoService = DAOService.getInstance()

  // State
  const daos = ref<DAO[]>([])
  const currentDAO = ref<DAO | null>(null)
  const currentMemberInfo = ref<MemberInfo | null>(null)
  const proposals = ref<Proposal[]>([])
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // Getters
  const getDAOById = computed(() => {
    return (id: string) => daos.value.find(dao => dao.id === id || dao.canisterId === id)
  })

  const totalStats = computed(() => {
    return {
      totalDAOs: daos.value.length,
      totalMembers: daos.value.reduce((sum, dao) => sum + bigintToNumber(dao.stats.totalMembers), 0),
      activeProposals: daos.value.reduce((sum, dao) => sum + bigintToNumber(dao.stats.activeProposals), 0),
      totalTVL: daos.value.reduce((sum, dao) => sum + parseFloat(bigintToString(dao.stats.totalStaked)), 0)
    }
  })

  const myDAOs = computed(() => {
    // TODO: Filter by current user's DAOs
    return daos.value.filter(dao => dao.isPublic)
  })

  // Actions
  const fetchDAOs = async (filters?: DAOFilters) => {
    isLoading.value = true
    error.value = null

    try {
      const result = await daoService.getDAOs(filters)
      daos.value = result
      return result
    } catch (err) {
      console.error('Error fetching DAOs:', err)
      error.value = 'Failed to fetch DAOs'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchDAO = async (id: string) => {
    isLoading.value = true
    error.value = null

    try {
      const result = await daoService.getDAO(id)
      if (result) {
        currentDAO.value = result
        
        // Update in the list if it exists
        const index = daos.value.findIndex(dao => dao.id === id || dao.canisterId === id)
        if (index !== -1) {
          daos.value[index] = result
        } else {
          daos.value.push(result)
        }
      }
      return result
    } catch (err) {
      console.error('Error fetching DAO:', err)
      error.value = 'Failed to fetch DAO'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const fetchMemberInfo = async (daoId: string, memberPrincipal?: string) => {
    try {
      const result = await daoService.getMemberInfo(daoId, memberPrincipal)
      if (!memberPrincipal) {
        currentMemberInfo.value = result
      }
      return result
    } catch (err) {
      console.error('Error fetching member info:', err)
      currentMemberInfo.value = null
      return null
    }
  }

  const fetchProposals = async (daoId: string, status?: string) => {
    try {
      const result = await daoService.getProposals(daoId, status)
      proposals.value = result
      return result
    } catch (err) {
      console.error('Error fetching proposals:', err)
      proposals.value = []
      throw err
    }
  }

  const createDAO = async (config: any) => {
    isLoading.value = true
    error.value = null

    try {
      const result = await daoService.createDAO(config)
      if (result.success && result.daoCanisterId) {
        // Fetch the newly created DAO
        await fetchDAO(result.daoCanisterId)
      }
      return result
    } catch (err) {
      console.error('Error creating DAO:', err)
      error.value = 'Failed to create DAO'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  const stake = async (daoId: string, amount: string, lockDuration?: number) => {
    try {
      const result = await daoService.stake(daoId, { amount, lockDuration })
      if (result.success) {
        // Refresh member info and DAO stats
        await Promise.all([
          fetchMemberInfo(daoId),
          fetchDAO(daoId)
        ])
      }
      return result
    } catch (err) {
      console.error('Error staking:', err)
      throw err
    }
  }

  const unstake = async (daoId: string, amount: string) => {
    try {
      const result = await daoService.unstake(daoId, { amount })
      if (result.success) {
        // Refresh member info and DAO stats
        await Promise.all([
          fetchMemberInfo(daoId),
          fetchDAO(daoId)
        ])
      }
      return result
    } catch (err) {
      console.error('Error unstaking:', err)
      throw err
    }
  }

  const vote = async (daoId: string, proposalId: number, vote: 'yes' | 'no' | 'abstain', reason?: string) => {
    try {
      const result = await daoService.vote(daoId, { proposalId, vote, reason })
      if (result.success) {
        // Refresh proposals
        await fetchProposals(daoId)
      }
      return result
    } catch (err) {
      console.error('Error voting:', err)
      throw err
    }
  }

  const createProposal = async (daoId: string, payload: any) => {
    try {
      const result = await daoService.createProposal(daoId, payload)
      if (result.success) {
        // Refresh proposals and DAO stats
        await Promise.all([
          fetchProposals(daoId),
          fetchDAO(daoId)
        ])
      }
      return result
    } catch (err) {
      console.error('Error creating proposal:', err)
      throw err
    }
  }

  const delegate = async (daoId: string, to: string) => {
    try {
      const result = await daoService.delegate(daoId, { to })
      if (result.success) {
        // Refresh member info
        await fetchMemberInfo(daoId)
      }
      return result
    } catch (err) {
      console.error('Error delegating:', err)
      throw err
    }
  }

  const undelegate = async (daoId: string) => {
    try {
      const result = await daoService.undelegate(daoId)
      if (result.success) {
        // Refresh member info
        await fetchMemberInfo(daoId)
      }
      return result
    } catch (err) {
      console.error('Error undelegating:', err)
      throw err
    }
  }

  // Utility methods
  const clearError = () => {
    error.value = null
  }

  const clearCurrentDAO = () => {
    currentDAO.value = null
    currentMemberInfo.value = null
    proposals.value = []
  }

  const refreshDAOStats = async (daoId: string) => {
    try {
      const stats = await daoService.getDAOStats(daoId)
      
      // Update DAO in the list
      const dao = daos.value.find(d => d.id === daoId || d.canisterId === daoId)
      if (dao) {
        dao.stats = stats
      }
      
      // Update current DAO if it matches
      if (currentDAO.value && (currentDAO.value.id === daoId || currentDAO.value.canisterId === daoId)) {
        currentDAO.value.stats = stats
      }
      
      return stats
    } catch (err) {
      console.error('Error refreshing DAO stats:', err)
      throw err
    }
  }

  return {
    // State
    daos,
    currentDAO,
    currentMemberInfo,
    proposals,
    isLoading,
    error,
    
    // Getters
    getDAOById,
    totalStats,
    myDAOs,
    
    // Actions
    fetchDAOs,
    fetchDAO,
    fetchMemberInfo,
    fetchProposals,
    createDAO,
    stake,
    unstake,
    vote,
    createProposal,
    delegate,
    undelegate,
    clearError,
    clearCurrentDAO,
    refreshDAOStats
  }
})