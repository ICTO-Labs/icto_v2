import { useAuthStore, backendActor, launchpadContractActor } from "@/stores/auth";
import { Principal } from "@dfinity/principal";
import type {
  LaunchpadConfig,
  LaunchpadDetail,
  LaunchpadStats,
  LaunchpadStatus,
  LaunchpadInitArgs,
  ProjectInfo,
  SaleParams,
  Timeline,
  TokenInfo,
  Transaction,
  Participant,
  ProcessingState,
  DeployedContracts,
  SecurityEvent,
  AdminAction,
  AffiliateStats,
  Result,
  Result_1,
  Result_2,
  Result_3,
  Result_4
} from '@/declarations/launchpad_contract/launchpad_contract.did'
import { formatTokenAmount } from "@/utils/token";

export interface LaunchpadFilters {
  search?: string
  status?: string[]
  saleType?: string[]
  sortBy?: 'recent' | 'endingSoon' | 'popular' | 'raised' | 'alphabetical'
  sortOrder?: 'asc' | 'desc'
  categories?: string[]
  minRaise?: number
  maxRaise?: number
}

export interface CreateLaunchpadRequest {
  config: LaunchpadConfig
}

export interface CreateLaunchpadResponse {
  success: boolean
  launchpadCanisterId?: string
  error?: string
}

export interface ParticipationRequest {
  amount: bigint
  affiliateCode?: string
}

export class LaunchpadService {
  private static instance: LaunchpadService

  constructor() {
    // No need to store actor as instance variable
  }

  static getInstance(): LaunchpadService {
    if (!LaunchpadService.instance) {
      LaunchpadService.instance = new LaunchpadService()
    }
    return LaunchpadService.instance
  }

  private getBackendActor(requiresSigning: boolean = true) {
    return backendActor({ requiresSigning, anon: false })
  }

  private getBackendActorAnonymous() {
    return backendActor({ requiresSigning: false, anon: true })
  }

  private getLaunchpadActor(canisterId: string, requiresSigning: boolean = true) {
    return launchpadContractActor({ canisterId, requiresSigning, anon: false })
  }

  private getLaunchpadActorAnonymous(canisterId: string) {
    return launchpadContractActor({ canisterId, requiresSigning: false, anon: true })
  }

  // ==================================================================================================
  // LAUNCHPAD MANAGEMENT
  // ==================================================================================================

  async createLaunchpad(config: LaunchpadConfig): Promise<CreateLaunchpadResponse> {
    try {
      const actor = this.getBackendActor()
      
      const launchpadInitArgs: LaunchpadInitArgs = {
        id: this.generateLaunchpadId(),
        creator: Principal.fromText(useAuthStore().principal || ''),
        createdAt: BigInt(Date.now() * 1000000), // Convert to nanoseconds
        config
      }

      const result = await actor.deployLaunchpad(launchpadInitArgs)
      
      if ('ok' in result) {
        return {
          success: true,
          launchpadCanisterId: result.ok.canisterId.toText()
        }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error creating launchpad:', error)
      return {
        success: false,
        error: 'Failed to create launchpad'
      }
    }
  }

  async getLaunchpads(filters?: LaunchpadFilters): Promise<LaunchpadDetail[]> {
    try {
      const actor = this.getBackendActorAnonymous()
      
      // Get all launchpad canisters from the registry
      const launchpadCanisters = await actor.getCanistersByType({ Launchpad: null })
      
      // Fetch details for each launchpad
      const launchpadPromises = launchpadCanisters.map(async (canisterId: Principal) => {
        try {
          const launchpadActor = this.getLaunchpadActorAnonymous(canisterId.toText())
          const backendActor = this.getBackendActorAnonymous()
          
          const [detail, canisterInfo] = await Promise.all([
            launchpadActor.getLaunchpadDetail(),
            backendActor.getDeployedCanisterInfo(canisterId)
          ])
          
          return {
            ...detail,
            canisterId: canisterId,
            deploymentInfo: canisterInfo
          }
        } catch (error) {
          console.error(`Error fetching launchpad ${canisterId.toText()}:`, error)
          return null
        }
      })
      
      const launchpads = (await Promise.all(launchpadPromises))
        .filter((launchpad): launchpad is LaunchpadDetail => launchpad !== null)
      
      return this.applyFilters(launchpads, filters)
    } catch (error) {
      console.error('Error fetching launchpads:', error)
      throw new Error('Failed to fetch launchpads')
    }
  }

  async getLaunchpad(canisterId: string): Promise<LaunchpadDetail | null> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const detail = await launchpadActor.getLaunchpadDetail()
      return detail
    } catch (error) {
      console.error('Error fetching launchpad:', error)
      return null
    }
  }

  async getLaunchpadConfig(canisterId: string): Promise<LaunchpadConfig | null> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const config = await launchpadActor.getConfig()
      return config
    } catch (error) {
      console.error('Error fetching launchpad config:', error)
      return null
    }
  }

  async getLaunchpadStats(canisterId: string): Promise<LaunchpadStats | null> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const stats = await launchpadActor.getStats()
      return stats
    } catch (error) {
      console.error('Error fetching launchpad stats:', error)
      return null
    }
  }

  async getLaunchpadStatus(canisterId: string): Promise<LaunchpadStatus | null> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const status = await launchpadActor.getStatus()
      return status
    } catch (error) {
      console.error('Error fetching launchpad status:', error)
      return null
    }
  }

  // ==================================================================================================
  // PARTICIPATION MANAGEMENT
  // ==================================================================================================

  async participate(canisterId: string, amount: bigint, affiliateCode?: string): Promise<{ success: boolean; transaction?: Transaction; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.participate(amount, affiliateCode ? [affiliateCode] : [])
      
      if ('ok' in result) {
        return {
          success: true,
          transaction: result.ok
        }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error participating in launchpad:', error)
      return {
        success: false,
        error: 'Failed to participate in launchpad'
      }
    }
  }

  async claimTokens(canisterId: string): Promise<{ success: boolean; claimedAmount?: bigint; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.claimTokens()
      
      if ('ok' in result) {
        return {
          success: true,
          claimedAmount: result.ok
        }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error claiming tokens:', error)
      return {
        success: false,
        error: 'Failed to claim tokens'
      }
    }
  }

  async getParticipant(canisterId: string, principal?: string): Promise<Participant | null> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const authStore = useAuthStore()
      const targetPrincipal = principal || authStore.principal
      
      if (!targetPrincipal) {
        return null
      }
      
      const result = await launchpadActor.getParticipant(Principal.fromText(targetPrincipal))
      return result[0] || null
    } catch (error) {
      console.error('Error fetching participant:', error)
      return null
    }
  }

  async getParticipants(canisterId: string, offset: bigint = BigInt(0), limit: bigint = BigInt(50)): Promise<Participant[]> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const participants = await launchpadActor.getParticipants(offset, limit)
      return participants
    } catch (error) {
      console.error('Error fetching participants:', error)
      return []
    }
  }

  async isWhitelisted(canisterId: string, principal?: string): Promise<boolean> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const authStore = useAuthStore()
      const targetPrincipal = principal || authStore.principal
      
      if (!targetPrincipal) {
        return false
      }
      
      return await launchpadActor.isWhitelisted(Principal.fromText(targetPrincipal))
    } catch (error) {
      console.error('Error checking whitelist status:', error)
      return false
    }
  }

  // ==================================================================================================
  // TRANSACTION MANAGEMENT
  // ==================================================================================================

  async getTransactions(canisterId: string, offset: bigint = BigInt(0), limit: bigint = BigInt(50)): Promise<Transaction[]> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const transactions = await launchpadActor.getTransactions(offset, limit)
      return transactions
    } catch (error) {
      console.error('Error fetching transactions:', error)
      return []
    }
  }

  // ==================================================================================================
  // ADMIN MANAGEMENT
  // ==================================================================================================

  async pauseLaunchpad(canisterId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.pauseLaunchpad()
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error pausing launchpad:', error)
      return {
        success: false,
        error: 'Failed to pause launchpad'
      }
    }
  }

  async unpauseLaunchpad(canisterId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.unpauseLaunchpad()
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error unpausing launchpad:', error)
      return {
        success: false,
        error: 'Failed to unpause launchpad'
      }
    }
  }

  async emergencyPause(canisterId: string, reason: string): Promise<{ success: boolean; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.emergencyPause(reason)
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error emergency pausing launchpad:', error)
      return {
        success: false,
        error: 'Failed to emergency pause launchpad'
      }
    }
  }

  async emergencyUnpause(canisterId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.emergencyUnpause()
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error emergency unpausing launchpad:', error)
      return {
        success: false,
        error: 'Failed to emergency unpause launchpad'
      }
    }
  }

  async cancelLaunchpad(canisterId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const launchpadActor = this.getLaunchpadActor(canisterId, true)
      const result = await launchpadActor.cancelLaunchpad()
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error canceling launchpad:', error)
      return {
        success: false,
        error: 'Failed to cancel launchpad'
      }
    }
  }

  // ==================================================================================================
  // SECURITY & MONITORING
  // ==================================================================================================

  async getSecurityEvents(canisterId: string): Promise<SecurityEvent[]> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const result = await launchpadActor.getSecurityEvents()
      
      if ('ok' in result) {
        return result.ok
      } else {
        console.error('Error fetching security events:', result.err)
        return []
      }
    } catch (error) {
      console.error('Error fetching security events:', error)
      return []
    }
  }

  async getAdminActions(canisterId: string): Promise<AdminAction[]> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const result = await launchpadActor.getAdminActions()
      
      if ('ok' in result) {
        return result.ok
      } else {
        console.error('Error fetching admin actions:', result.err)
        return []
      }
    } catch (error) {
      console.error('Error fetching admin actions:', error)
      return []
    }
  }

  async getAffiliateStats(canisterId: string, affiliate: string): Promise<AffiliateStats | null> {
    try {
      const launchpadActor = this.getLaunchpadActorAnonymous(canisterId)
      const result = await launchpadActor.getAffiliateStats(Principal.fromText(affiliate))
      return result[0] || null
    } catch (error) {
      console.error('Error fetching affiliate stats:', error)
      return null
    }
  }

  // ==================================================================================================
  // UTILITY METHODS
  // ==================================================================================================

  private generateLaunchpadId(): string {
    return `launchpad_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  private applyFilters(launchpads: LaunchpadDetail[], filters?: LaunchpadFilters): LaunchpadDetail[] {
    if (!filters) return launchpads

    let filtered = [...launchpads]
    
    // Apply search filter
    if (filters.search) {
      const query = filters.search.toLowerCase()
      filtered = filtered.filter(launchpad => 
        launchpad.config.projectInfo.name.toLowerCase().includes(query) ||
        launchpad.config.projectInfo.description.toLowerCase().includes(query) ||
        launchpad.config.saleToken.symbol.toLowerCase().includes(query) ||
        launchpad.config.projectInfo.tags.some(tag => tag.toLowerCase().includes(query))
      )
    }
    
    // Apply status filter
    if (filters.status && filters.status.length > 0) {
      filtered = filtered.filter(launchpad => {
        const statusKey = this.getStatusKey(launchpad.status)
        return filters.status!.includes(statusKey)
      })
    }
    
    // Apply sale type filter
    if (filters.saleType && filters.saleType.length > 0) {
      filtered = filtered.filter(launchpad => {
        const saleTypeKey = this.getSaleTypeKey(launchpad.config.saleParams.saleType)
        return filters.saleType!.includes(saleTypeKey)
      })
    }
    
    // Apply category filter
    if (filters.categories && filters.categories.length > 0) {
      filtered = filtered.filter(launchpad => {
        const categoryKey = this.getCategoryKey(launchpad.config.projectInfo.category)
        return filters.categories!.includes(categoryKey)
      })
    }
    
    // Apply raise amount filters
    if (filters.minRaise !== undefined || filters.maxRaise !== undefined) {
      filtered = filtered.filter(launchpad => {
        const hardCapICP = Number(launchpad.config.saleParams.hardCap) / Math.pow(10, 8) // Assuming 8 decimals
        if (filters.minRaise !== undefined && hardCapICP < filters.minRaise) return false
        if (filters.maxRaise !== undefined && hardCapICP > filters.maxRaise) return false
        return true
      })
    }
    
    // Apply sorting
    filtered.sort((a, b) => {
      const order = filters.sortOrder === 'asc' ? 1 : -1
      
      switch (filters.sortBy) {
        case 'recent':
          const aTime = Number(a.createdAt)
          const bTime = Number(b.createdAt)
          return (bTime - aTime) * order
        case 'endingSoon':
          const aEnd = Number(a.config.timeline.saleEnd)
          const bEnd = Number(b.config.timeline.saleEnd)
          return (aEnd - bEnd) * order
        case 'popular':
          const aParticipants = Number(a.stats.participantCount)
          const bParticipants = Number(b.stats.participantCount)
          return (bParticipants - aParticipants) * order
        case 'raised':
          const aRaised = Number(a.stats.totalRaised)
          const bRaised = Number(b.stats.totalRaised)
          return (bRaised - aRaised) * order
        case 'alphabetical':
          return a.config.projectInfo.name.localeCompare(b.config.projectInfo.name) * order
        default:
          return 0
      }
    })
    
    return filtered
  }

  private getStatusKey(status: LaunchpadStatus): string {
    if ('Setup' in status) return 'setup'
    if ('Upcoming' in status) return 'upcoming'
    if ('WhitelistOpen' in status) return 'whitelist'
    if ('SaleActive' in status) return 'active'
    if ('SaleEnded' in status) return 'ended'
    if ('Distributing' in status) return 'distributing'
    if ('Claiming' in status) return 'claiming'
    if ('Completed' in status) return 'completed'
    if ('Successful' in status) return 'successful'
    if ('Failed' in status) return 'failed'
    if ('Cancelled' in status) return 'cancelled'
    if ('Emergency' in status) return 'emergency'
    return 'unknown'
  }

  private getSaleTypeKey(saleType: any): string {
    if ('IDO' in saleType) return 'ido'
    if ('PrivateSale' in saleType) return 'private'
    if ('FairLaunch' in saleType) return 'fair'
    if ('Auction' in saleType) return 'auction'
    if ('Lottery' in saleType) return 'lottery'
    return 'unknown'
  }

  private getCategoryKey(category: any): string {
    if ('DeFi' in category) return 'defi'
    if ('Gaming' in category) return 'gaming'
    if ('NFT' in category) return 'nft'
    if ('AI' in category) return 'ai'
    if ('Infrastructure' in category) return 'infrastructure'
    if ('DAO' in category) return 'dao'
    if ('SocialFi' in category) return 'socialfi'
    if ('Metaverse' in category) return 'metaverse'
    if ('Other' in category) return 'other'
    return 'unknown'
  }

  // Status helper methods
  getStatusDisplay(status: LaunchpadStatus): string {
    const key = this.getStatusKey(status)
    const statusMap = {
      setup: 'Setup',
      upcoming: 'Upcoming',
      whitelist: 'Whitelist Open',
      active: 'Sale Active',
      ended: 'Sale Ended',
      distributing: 'Distributing',
      claiming: 'Claiming',
      completed: 'Completed',
      successful: 'Successful',
      failed: 'Failed',
      cancelled: 'Cancelled',
      emergency: 'Emergency',
      unknown: 'Unknown'
    }
    return statusMap[key as keyof typeof statusMap] || 'Unknown'
  }

  getStatusColor(status: LaunchpadStatus): string {
    const key = this.getStatusKey(status)
    const colorMap = {
      setup: 'gray',
      upcoming: 'blue',
      whitelist: 'purple',
      active: 'green',
      ended: 'yellow',
      distributing: 'orange',
      claiming: 'indigo',
      completed: 'green',
      successful: 'green',
      failed: 'red',
      cancelled: 'red',
      emergency: 'red',
      unknown: 'gray'
    }
    return colorMap[key as keyof typeof colorMap] || 'gray'
  }

  // Calculate progress percentage
  getProgressPercentage(stats: LaunchpadStats, hardCap: bigint): number {
    const raised = Number(stats.totalRaised)
    const target = Number(hardCap)
    return target > 0 ? Math.min((raised / target) * 100, 100) : 0
  }

  // Time helper methods
  getTimeRemaining(endTime: bigint): string {
    const now = BigInt(Date.now() * 1000000) // Convert to nanoseconds
    const remaining = Number(endTime - now) / 1000000000 // Convert to seconds
    
    if (remaining <= 0) return 'Ended'
    
    const days = Math.floor(remaining / 86400)
    const hours = Math.floor((remaining % 86400) / 3600)
    const minutes = Math.floor((remaining % 3600) / 60)
    
    if (days > 0) return `${days}d ${hours}h`
    if (hours > 0) return `${hours}h ${minutes}m`
    return `${minutes}m`
  }

  formatDate(timestamp: bigint): string {
    const date = new Date(Number(timestamp) / 1000000) // Convert from nanoseconds
    return date.toLocaleDateString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric' 
    })
  }

  formatDateTime(timestamp: bigint): string {
    const date = new Date(Number(timestamp) / 1000000) // Convert from nanoseconds
    return date.toLocaleString('en-US', { 
      year: 'numeric', 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }
}