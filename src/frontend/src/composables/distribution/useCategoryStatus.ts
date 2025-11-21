import { computed, type Ref } from 'vue'

export type CategoryUserStatus = 'NOT_ELIGIBLE' | 'ELIGIBLE' | 'REGISTERED' | 'CLAIMABLE' | 'CLAIMED' | 'LOCKED'

export interface CategoryWithStatus {
  categoryId: string
  name: string
  description: string
  mode: 'Predefined' | 'Open'
  totalAllocation: bigint
  passportScore: bigint
  userStatus: CategoryUserStatus
  canRegister: boolean
  canClaim: boolean
  claimableAmount: bigint
  eligibleAmount: bigint
  claimedAmount: bigint
  isRegistered: boolean
}

export function useCategoryStatus(
  categories: Ref<any[]>,
  userContext: Ref<any | null>,
  isAuthenticated: Ref<boolean>,
  categoryBreakdown: Ref<Map<string, any>>
) {
  /**
   * Get user status for a specific category
   */
  const getCategoryUserStatus = (category: any): CategoryUserStatus => {
    if (!isAuthenticated.value || !userContext.value) {
      return 'NOT_ELIGIBLE'
    }

    const categoryId = category.categoryId?.toString() || category.category?.id?.toString()

    // Check if user has allocation in this category (from category.participants)
    const currentUserPrincipal = userContext.value.principal
    const userCategoryData = category.participants?.find(
      (p: any) => p.principal?.toString() === currentUserPrincipal?.toString()
    )

    if (!userCategoryData) {
      // User not registered for this category
      // Check if eligible to register
      const mode = category.mode || category.category?.mode
      const isOpen = mode === 'Open' || (mode && typeof mode === 'object' && 'Open' in mode)

      if (isOpen) {
        // Check passport score for Open categories
        const requiredScore = Number(category.passportScore || category.category?.passportScore || 0)
        const userScore = Number(userContext.value.passportScore || 0)

        if (userScore >= requiredScore) {
          return 'ELIGIBLE'
        } else {
          return 'NOT_ELIGIBLE'
        }
      } else {
        // Predefined mode - not eligible if not in list
        return 'NOT_ELIGIBLE'
      }
    }

    // User is registered for this category
    const eligibleAmount = BigInt(userCategoryData.allocation || 0)
    const claimedAmount = BigInt(userCategoryData.claimed || 0)

    // Calculate claimable amount (simplified - actual vesting calculation done in backend)
    const claimableAmount = eligibleAmount > claimedAmount ? eligibleAmount - claimedAmount : BigInt(0)

    // Check if fully claimed
    if (eligibleAmount > 0 && claimedAmount >= eligibleAmount) {
      return 'CLAIMED'
    }

    // Check if can claim now (has unlocked tokens)
    if (claimableAmount > 0) {
      return 'CLAIMABLE'
    }

    // Check if vesting has started by checking distribution start time
    // If vesting hasn't started yet, show REGISTERED instead of LOCKED
    const vestingStart = category.vestingStart || category.category?.defaultVestingStart
    if (vestingStart) {
      const vestingStartMs = Number(vestingStart) / 1_000_000
      const now = Date.now()

      if (now < vestingStartMs) {
        // Vesting hasn't started yet
        return 'REGISTERED'
      }
    }

    // Vesting has started but no tokens unlocked yet
    if (eligibleAmount > claimedAmount && claimableAmount === BigInt(0)) {
      return 'LOCKED'
    }

    // Default: registered but nothing to claim yet
    return 'REGISTERED'
  }

  /**
   * Get enhanced category data with user status
   */
  const categoriesWithStatus = computed<CategoryWithStatus[]>(() => {
    if (!categories.value || categories.value.length === 0) {
      return []
    }

    return categories.value.map(category => {
      const categoryId = (category.categoryId || category.category?.id)?.toString()

      // Get vesting-aware breakdown data from backend
      const breakdownData = categoryBreakdown.value.get(categoryId)

      // Use breakdown data if available (accurate vesting calculation from backend)
      // Otherwise fall back to participant data
      let claimableAmount = BigInt(0)
      let eligibleAmount = BigInt(0)
      let claimedAmount = BigInt(0)
      let isRegistered = false
      let userStatus = getCategoryUserStatus(category) // Default status from local calculation

      if (breakdownData) {
        // Use accurate backend data
        claimableAmount = BigInt(breakdownData.claimableAmount || 0)
        eligibleAmount = BigInt(breakdownData.allocatedAmount || 0)
        claimedAmount = BigInt(breakdownData.claimedAmount || 0)
        isRegistered = true

        // RE-EVALUATE STATUS BASED ON BACKEND DATA
        // This overrides the optimistic local calculation
        if (eligibleAmount > 0 && claimedAmount >= eligibleAmount) {
          userStatus = 'CLAIMED'
        } else if (claimableAmount > 0) {
          userStatus = 'CLAIMABLE'
        } else if (eligibleAmount > 0) {
          // Has allocation but nothing claimable yet -> Locked
          userStatus = 'LOCKED'
        } else {
          // Fallback
          userStatus = 'REGISTERED'
        }
      } else {
        // Fall back to participant data from category
        const currentUserPrincipal = userContext.value?.principal
        const userCategoryData = category.participants?.find(
          (p: any) => p.principal?.toString() === currentUserPrincipal?.toString()
        )

        if (userCategoryData) {
          eligibleAmount = BigInt(userCategoryData.allocation || 0)
          claimedAmount = BigInt(userCategoryData.claimed || 0)
          // Simple calculation (not vesting-aware)
          claimableAmount = eligibleAmount > claimedAmount ? eligibleAmount - claimedAmount : BigInt(0)
          isRegistered = true
        }
      }

      return {
        categoryId,
        name: category.name || `Category ${categoryId}`,
        description: category.description || '',
        mode: (category.mode === 'Open' || (category.mode && typeof category.mode === 'object' && 'Open' in category.mode)) ? 'Open' : 'Predefined',
        totalAllocation: BigInt(category.totalAllocation || 0),
        passportScore: BigInt(category.passportScore || 0),
        userStatus,
        canRegister: userStatus === 'ELIGIBLE',
        canClaim: userStatus === 'CLAIMABLE',
        claimableAmount,
        eligibleAmount,
        claimedAmount,
        isRegistered
      }
    })
  })

  /**
   * Summary statistics
   */
  const totalCategories = computed(() => categories.value.length)

  const registeredCount = computed(() =>
    categoriesWithStatus.value.filter(cat =>
      cat.userStatus === 'REGISTERED' ||
      cat.userStatus === 'CLAIMABLE' ||
      cat.userStatus === 'CLAIMED' ||
      cat.userStatus === 'LOCKED'
    ).length
  )

  const eligibleCount = computed(() =>
    categoriesWithStatus.value.filter(cat => cat.userStatus === 'ELIGIBLE').length
  )

  const claimableCount = computed(() =>
    categoriesWithStatus.value.filter(cat => cat.userStatus === 'CLAIMABLE').length
  )

  const totalClaimableAmount = computed(() =>
    categoriesWithStatus.value.reduce(
      (sum, cat) => sum + cat.claimableAmount,
      BigInt(0)
    )
  )

  const hasEligibleCategories = computed(() => eligibleCount.value > 0)
  const hasClaimableCategories = computed(() => claimableCount.value > 0)

  /**
   * Get categories by status
   */
  const eligibleCategories = computed(() =>
    categoriesWithStatus.value.filter(cat => cat.canRegister)
  )

  const claimableCategories = computed(() =>
    categoriesWithStatus.value.filter(cat => cat.canClaim)
  )

  /**
   * Get status label
   */
  const getStatusLabel = (status: CategoryUserStatus): string => {
    switch (status) {
      case 'NOT_ELIGIBLE':
        return 'Not Eligible'
      case 'ELIGIBLE':
        return 'Can Register'
      case 'REGISTERED':
        return 'Registered'
      case 'CLAIMABLE':
        return 'Ready to Claim'
      case 'CLAIMED':
        return 'Fully Claimed'
      case 'LOCKED':
        return 'Vesting Locked'
      default:
        return 'Unknown'
    }
  }

  /**
   * Get status color
   */
  const getStatusColor = (status: CategoryUserStatus): string => {
    switch (status) {
      case 'NOT_ELIGIBLE':
        return 'gray'
      case 'ELIGIBLE':
        return 'blue'
      case 'REGISTERED':
        return 'blue'
      case 'CLAIMABLE':
        return 'green'
      case 'CLAIMED':
        return 'green'
      case 'LOCKED':
        return 'amber'
      default:
        return 'gray'
    }
  }

  return {
    categoriesWithStatus,
    totalCategories,
    registeredCount,
    eligibleCount,
    claimableCount,
    totalClaimableAmount,
    hasEligibleCategories,
    hasClaimableCategories,
    eligibleCategories,
    claimableCategories,
    getCategoryUserStatus,
    getStatusLabel,
    getStatusColor
  }
}
