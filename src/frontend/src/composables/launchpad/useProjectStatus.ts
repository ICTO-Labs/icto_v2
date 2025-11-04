import { computed, type ComputedRef } from 'vue'
import type { LaunchpadStatus } from '@/declarations/launchpad_contract/launchpad_contract.did'

/**
 * Project Status (User-Facing)
 * Simplified status that users actually care about
 */
export type ProjectStatus = 
  | 'Upcoming'      // Not started yet
  | 'Whitelist'     // Whitelist registration open
  | 'Live'          // Sale is active
  | 'Ended'         // Sale ended, processing results
  | 'Successful'    // ✅ Success - tokens deployed/claiming
  | 'Failed'        // ❌ Failed - refunded
  | 'Cancelled'     // 🚫 Cancelled by admin

/**
 * Timeline Step
 */
export interface TimelineStep {
  id: string
  label: string
  description: string
  date?: bigint | string
  value?: string
  progress?: number
  status: 'completed' | 'active' | 'pending' | 'failed'
  icon: string
  color: string
}

/**
 * Project Status Info
 */
export interface ProjectStatusInfo {
  status: ProjectStatus
  label: string
  description: string
  color: string
  icon: string
  bgClass: string
  textClass: string
  isProcessing: boolean
  processingLabel?: string
  canParticipate: boolean
  canClaim: boolean
  canViewRefund: boolean
  showPipeline: boolean
}

/**
 * Composable for managing project status display
 * Provides simplified, user-friendly status from complex backend states
 */
export function useProjectStatus(launchpad: ComputedRef<any>) {
  /**
   * Map backend LaunchpadStatus to user-friendly ProjectStatus
   */
  const projectStatus = computed<ProjectStatus>(() => {
    if (!launchpad.value?.status) return 'Upcoming'
    
    const status = launchpad.value.status
    
    // Initial phases
    if ('Setup' in status || 'Upcoming' in status) return 'Upcoming'
    if ('WhitelistOpen' in status) return 'Whitelist'
    if ('SaleActive' in status) return 'Live'
    if ('SaleEnded' in status) return 'Ended'
    
    // SUCCESS PATH - Map all success states to "Successful"
    if ('Successful' in status) return 'Successful'
    if ('Distributing' in status) return 'Successful'
    if ('Claiming' in status) return 'Successful'
    
    // Handle Completed - check if it was successful or failed
    if ('Completed' in status) {
      const stats = launchpad.value.stats
      const config = launchpad.value.config
      
      if (stats && config) {
        const totalRaised = Number(stats.totalRaised || 0)
        const softCap = Number(config.saleParams?.softCap || 0)
        return totalRaised >= softCap ? 'Successful' : 'Failed'
      }
      
      return 'Successful' // Default to successful if can't determine
    }
    
    // FAILED PATH - Map all failed states to "Failed"
    if ('Failed' in status) return 'Failed'
    if ('Refunding' in status) return 'Failed'
    if ('Refunded' in status) return 'Failed'
    if ('Finalized' in status) return 'Failed'
    
    // Special states
    if ('Cancelled' in status) return 'Cancelled'
    if ('Emergency' in status) return 'Ended'
    
    return 'Upcoming'
  })

  /**
   * Detailed status information
   */
  const statusInfo = computed<ProjectStatusInfo>(() => {
    const status = projectStatus.value
    const backendStatus = launchpad.value?.status
    const processingState = launchpad.value?.processingState
    
    const statusMap: Record<ProjectStatus, Omit<ProjectStatusInfo, 'status'>> = {
      Upcoming: {
        label: 'Upcoming',
        description: 'Sale has not started yet',
        color: 'gray',
        icon: '⏰',
        bgClass: 'bg-gray-100 dark:bg-gray-700',
        textClass: 'text-gray-700 dark:text-gray-300',
        isProcessing: false,
        canParticipate: false,
        canClaim: false,
        canViewRefund: false,
        showPipeline: false
      },
      Whitelist: {
        label: 'Whitelist Open',
        description: 'Whitelist registration is active',
        color: 'purple',
        icon: '👥',
        bgClass: 'bg-purple-100 dark:bg-purple-900',
        textClass: 'text-purple-700 dark:text-purple-300',
        isProcessing: false,
        canParticipate: true,
        canClaim: false,
        canViewRefund: false,
        showPipeline: false
      },
      Live: {
        label: 'Live',
        description: 'Sale is currently active',
        color: 'blue',
        icon: '🚀',
        bgClass: 'bg-blue-100 dark:bg-blue-900',
        textClass: 'text-blue-700 dark:text-blue-300',
        isProcessing: false,
        canParticipate: true,
        canClaim: false,
        canViewRefund: false,
        showPipeline: false
      },
      Ended: {
        label: 'Ended',
        description: 'Sale ended, processing results',
        color: 'yellow',
        icon: '⏸️',
        bgClass: 'bg-yellow-100 dark:bg-yellow-900',
        textClass: 'text-yellow-700 dark:text-yellow-300',
        isProcessing: true,
        processingLabel: 'Determining outcome...',
        canParticipate: false,
        canClaim: false,
        canViewRefund: false,
        showPipeline: false
      },
      Successful: {
        label: 'Successful',
        description: 'Soft cap reached',
        color: 'green',
        icon: '✅',
        bgClass: 'bg-green-100 dark:bg-green-900',
        textClass: 'text-green-700 dark:text-green-300',
        isProcessing: backendStatus && ('Distributing' in backendStatus || 'Successful' in backendStatus),
        processingLabel: backendStatus && 'Distributing' in backendStatus 
          ? 'Deploying tokens...' 
          : backendStatus && 'Claiming' in backendStatus
            ? 'Claiming available'
            : 'Completed',
        canParticipate: false,
        canClaim: backendStatus && ('Claiming' in backendStatus || 'Completed' in backendStatus),
        canViewRefund: false,
        showPipeline: backendStatus && ('Distributing' in backendStatus || 'Successful' in backendStatus)
      },
      Failed: {
        label: 'Failed',
        description: 'Soft cap not reached',
        color: 'red',
        icon: '❌',
        bgClass: 'bg-red-100 dark:bg-red-900',
        textClass: 'text-red-700 dark:text-red-300',
        isProcessing: backendStatus && ('Failed' in backendStatus || 'Refunding' in backendStatus),
        processingLabel: backendStatus && ('Failed' in backendStatus || 'Refunding' in backendStatus)
          ? 'Processing refunds...'
          : 'Refunded',
        canParticipate: false,
        canClaim: false,
        canViewRefund: backendStatus && ('Refunded' in backendStatus || 'Finalized' in backendStatus),
        showPipeline: backendStatus && ('Failed' in backendStatus || 'Refunding' in backendStatus)
      },
      Cancelled: {
        label: 'Cancelled',
        description: 'Cancelled by admin or creator',
        color: 'yellow',
        icon: '🚫',
        bgClass: 'bg-yellow-100 dark:bg-yellow-900',
        textClass: 'text-yellow-700 dark:text-yellow-300',
        isProcessing: false,
        canParticipate: false,
        canClaim: false,
        canViewRefund: true,
        showPipeline: false
      }
    }
    
    return {
      status,
      ...statusMap[status]
    }
  })

  /**
   * Timeline steps (7 universal steps)
   */
  const timeline = computed<TimelineStep[]>(() => {
    if (!launchpad.value) {
      console.log('🔍 [useProjectStatus] No launchpad data')
      return []
    }
    
    const config = launchpad.value.config
    const timeline = config?.timeline
    const stats = launchpad.value.stats
    const processingState = launchpad.value.processingState
    const backendStatus = launchpad.value.status
    const createdAt = launchpad.value.createdAt
    
    console.log('🔍 [useProjectStatus] Building timeline:', {
      projectStatus: projectStatus.value,
      backendStatus,
      processingState
    })
    
    const currentTime = BigInt(Date.now() * 1_000_000) // Convert to nanoseconds
    
    const steps: TimelineStep[] = []
    
    // ============================================
    // STEP 1: Created (ALWAYS SHOW)
    // ============================================
    steps.push({
      id: 'created',
      label: 'Created',
      description: 'Launchpad deployed',
      date: createdAt,
      status: 'completed',
      icon: '📝',
      color: 'gray'
    })
    
    // ============================================
    // STEP 2: Whitelist (OPTIONAL - only if configured)
    // ============================================
    if (timeline?.whitelistStart && timeline.whitelistStart > BigInt(0)) {
      const whitelistEnd = timeline.whitelistEnd || timeline.saleStart // Fallback to saleStart
      const isCompleted = currentTime > whitelistEnd
      const isActive = currentTime >= timeline.whitelistStart && currentTime <= whitelistEnd
      
      steps.push({
        id: 'whitelist',
        label: 'Whitelist',
        description: 'Registration period',
        date: timeline.whitelistStart,
        status: isCompleted ? 'completed' : isActive ? 'active' : 'pending',
        icon: '👥',
        color: 'purple'
      })
    }
    
    // ============================================
    // STEP 3: Sale Start (ALWAYS SHOW)
    // ============================================
    steps.push({
      id: 'sale-start',
      label: 'Sale Start',
      description: 'Public sale begins',
      date: timeline?.saleStart || BigInt(0),
      status: timeline?.saleStart && currentTime > timeline.saleStart 
        ? 'completed' 
        : backendStatus && 'SaleActive' in backendStatus 
          ? 'active' 
          : 'pending',
      icon: '🚀',
      color: 'blue' // Changed from green to blue (per user's color scheme)
    })
    
    // ============================================
    // STEP 4: Sale End (ALWAYS SHOW)
    // ============================================
    steps.push({
      id: 'sale-end',
      label: 'Sale End',
      description: 'Sale concluded',
      date: timeline?.saleEnd || BigInt(0),
      status: timeline?.saleEnd && currentTime > timeline.saleEnd 
        ? 'completed' 
        : backendStatus && 'SaleEnded' in backendStatus
          ? 'active'
          : 'pending',
      icon: '⏸️',
      color: 'yellow'
    })
    
    // ============================================
    // STEP 5: Result - Success/Failed (ALWAYS SHOW after sale end)
    // ============================================
    const isSuccess = projectStatus.value === 'Successful'
    const isFailed = projectStatus.value === 'Failed'
    const isCancelled = projectStatus.value === 'Cancelled'
    const saleEnded = backendStatus && ('SaleEnded' in backendStatus || 'Successful' in backendStatus || 'Failed' in backendStatus || 'Claiming' in backendStatus || 'Completed' in backendStatus || 'Finalized' in backendStatus || 'Refunded' in backendStatus || 'Cancelled' in backendStatus)
    
    const softCap = Number(config?.saleParams?.softCap || 0) / 100_000_000
    const totalRaised = Number(stats?.totalRaised || 0) / 100_000_000
    
    steps.push({
      id: 'result',
      label: 'Result',
      description: isCancelled 
        ? 'Cancelled by admin' 
        : isSuccess 
          ? 'Soft cap reached ✓' 
          : isFailed 
            ? 'Soft cap not reached'
            : 'Pending sale conclusion',
      value: saleEnded && !isCancelled ? `${totalRaised.toFixed(2)} / ${softCap.toFixed(2)} ICP` : undefined,
      status: isSuccess 
        ? 'completed' 
        : isFailed || isCancelled 
          ? 'failed' 
          : saleEnded 
            ? 'active'
            : 'pending',
      icon: isSuccess ? '✅' : isCancelled ? '🚫' : isFailed ? '❌' : '⏳',
      color: isSuccess ? 'green' : isCancelled ? 'yellow' : isFailed ? 'red' : 'gray'
    })
    
    // ============================================
    // STEP 6: Pipeline - Deploying/Refunding (ALWAYS SHOW)
    // ============================================
    const isDeploying = isSuccess
    const isRefunding = isFailed || isCancelled
    const isPipelineActive = statusInfo.value.showPipeline || 
      (backendStatus && ('Processing' in processingState || 'Successful' in backendStatus || 'Failed' in backendStatus || 'Refunding' in backendStatus))
    
    const progress = processingState && 'Processing' in processingState 
      ? processingState.Processing.progress 
      : isSuccess && backendStatus && ('Claiming' in backendStatus || 'Completed' in backendStatus || 'Finalized' in backendStatus)
        ? 100  // Pipeline completed for success
        : isRefunding && backendStatus && ('Refunded' in backendStatus || 'Finalized' in backendStatus)
          ? 100  // Pipeline completed for refund
          : 0
    
    steps.push({
      id: 'pipeline',
      label: isDeploying ? 'Deploying' : isRefunding ? 'Refunding' : 'Pipeline',
      description: isDeploying 
        ? 'Token deployment & distribution' 
        : isRefunding 
          ? 'Processing refunds to participants'
          : 'Awaiting sale result',
      progress: Number(progress),
      status: progress === 100 
        ? 'completed' 
        : isPipelineActive 
          ? 'active' 
          : saleEnded
            ? 'pending'
            : 'pending',
      icon: isDeploying ? '📦' : isRefunding ? '💸' : '⚙️',
      color: isDeploying ? 'indigo' : isRefunding ? 'blue' : 'gray'
    })
    
    // ============================================
    // STEP 7: Finalized (ALWAYS SHOW)
    // ============================================
    const isFinalized = backendStatus && ('Completed' in backendStatus || 'Finalized' in backendStatus)
    
    steps.push({
      id: 'finalized',
      label: 'Finalized',
      description: isSuccess 
        ? 'Token distribution completed' 
        : isFailed || isCancelled
          ? 'All refunds processed'
          : 'All processes completed',
      status: isFinalized ? 'completed' : 'pending',
      icon: '🏁',
      color: 'gray'
    })
    
    return steps
  })

  /**
   * Get filter-friendly status
   */
  const filterStatus = computed(() => projectStatus.value)

  return {
    // Main status
    projectStatus,
    statusInfo,
    
    // Timeline
    timeline,
    
    // Convenience flags
    isUpcoming: computed(() => projectStatus.value === 'Upcoming'),
    isWhitelist: computed(() => projectStatus.value === 'Whitelist'),
    isLive: computed(() => projectStatus.value === 'Live'),
    isEnded: computed(() => projectStatus.value === 'Ended'),
    isSuccessful: computed(() => projectStatus.value === 'Successful'),
    isFailed: computed(() => projectStatus.value === 'Failed'),
    isCancelled: computed(() => projectStatus.value === 'Cancelled'),
    
    // Actions
    canParticipate: computed(() => statusInfo.value.canParticipate),
    canClaim: computed(() => statusInfo.value.canClaim),
    canViewRefund: computed(() => statusInfo.value.canViewRefund),
    showPipeline: computed(() => statusInfo.value.showPipeline),
    
    // Filter
    filterStatus
  }
}

