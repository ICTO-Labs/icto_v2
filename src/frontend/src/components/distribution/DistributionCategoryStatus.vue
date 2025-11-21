<template>
  <div class="category-status-sidebar space-y-4">
    <!-- Overview Card -->
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-5 border border-gray-200 dark:border-gray-700">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
        <ListIcon class="w-5 h-5 mr-2 text-blue-600 dark:text-blue-400" />
        Your Status
      </h3>

      <!-- Summary Stats -->
      <div class="grid grid-cols-2 gap-3 mb-4">
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3">
          <div class="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">Registered</div>
          <div class="text-xl font-bold text-blue-700 dark:text-blue-300">
            {{ registeredCount }}/{{ totalCategories }}
          </div>
        </div>

        <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-3">
          <div class="text-xs text-green-600 dark:text-green-400 font-medium mb-1">Claimable</div>
          <div class="text-xl font-bold text-green-700 dark:text-green-300">
            {{ claimableCount }}
          </div>
        </div>
      </div>

      <!-- Batch Actions -->
      <div class="space-y-2 mb-4">
        <button v-if="hasEligibleCategories" :disabled="!hasEligibleCategories || processing"
          @click="$emit('register-all')"
          class="w-full flex items-center justify-center px-4 py-2.5 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg hover:from-blue-700 hover:to-blue-800 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed font-medium shadow-sm">
          <UserPlusIcon class="w-4 h-4 mr-2" />
          Register All Eligible <span v-if="eligibleCount"
            class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-1 text-xs px-2 text-blue-600 dark:text-blue-400 text-center ml-2">{{
              eligibleCount }}</span>
        </button>

        <button v-if="hasClaimableCategories" :disabled="!hasClaimableCategories || processing"
          @click="$emit('claim-all')"
          class="w-full flex items-center justify-center px-4 py-2.5 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg hover:from-green-700 hover:to-green-800 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed font-medium shadow-sm">
          <CoinsIcon class="w-4 h-4 mr-2" />
          Claim All Ready <span v-if="claimableCount"
            class="bg-green-50 dark:bg-green-900/20 rounded-lg p-1 text-xs px-2 text-green-600 dark:text-green-400 font-medium text-center ml-2">{{
              claimableCount }}</span>
        </button>
      </div>

      <!-- Category List with Status -->
      <div class="space-y-2 max-h-[400px] overflow-y-auto scrollbar-thin">
        <div v-for="category in categoryStatuses" :key="category.id"
          class="category-status-item flex items-center justify-between p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200 cursor-pointer group"
          :class="{ 'bg-blue-50 dark:bg-blue-900/20': category.isActive }" @click="scrollToCategory(category.id)">
          <div class="flex items-center space-x-2 flex-1 min-w-0">
            <component :is="getStatusIconComponent(category.status)" class="w-4 h-4 flex-shrink-0"
              :class="getStatusIconColorClass(category.status)" />
            <div class="min-w-0 flex-1">
              <p class="text-sm font-medium text-gray-900 dark:text-white truncate">
                {{ category.name }}
              </p>
              <p class="text-xs text-gray-500 dark:text-gray-400">
                {{ category.statusLabel }}
              </p>
            </div>
          </div>

          <span class="inline-flex items-center rounded-full font-medium px-2 py-0.5 text-xs flex-shrink-0"
            :class="getStatusBadgeClass(category.status)">
            <span class="mr-1">{{ getStatusEmoji(category.status) }}</span>
            {{ category.statusLabel }}
          </span>

          <ChevronRightIcon
            class="w-4 h-4 text-gray-400 group-hover:text-gray-600 dark:group-hover:text-gray-300 transition-colors ml-2 flex-shrink-0" />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  ListIcon,
  UserPlusIcon,
  CoinsIcon,
  ChevronRightIcon,
  InfoIcon,
  CheckCircle2Icon,
  CircleIcon,
  AlertCircleIcon,
  LockIcon,
  GiftIcon,
  ClockIcon
} from 'lucide-vue-next'

// Types
type CategoryUserStatus = 'NOT_ELIGIBLE' | 'ELIGIBLE' | 'REGISTERED' | 'CLAIMABLE' | 'CLAIMED' | 'LOCKED'

interface CategoryStatus {
  id: string
  name: string
  status: CategoryUserStatus
  statusLabel: string
  isActive: boolean
  canRegister: boolean
  canClaim: boolean
  claimableAmount?: bigint
}

// Props
interface Props {
  categories: any[]
  userContext?: any
  isAuthenticated: boolean
  processing?: boolean
  activeCategory?: string
}

const props = withDefaults(defineProps<Props>(), {
  processing: false,
  activeCategory: undefined
})

// Emits
const emit = defineEmits<{
  'register-all': []
  'claim-all': []
  'scroll-to-category': [categoryId: string]
}>()

// Computed: Category statuses
const categoryStatuses = computed<CategoryStatus[]>(() => {
  if (!props.categories || props.categories.length === 0) {
    return []
  }

  return props.categories.map(category => {
    const categoryId = category.categoryId?.toString() || category.category?.id?.toString()

    // Determine user status for this category
    const status = getCategoryUserStatus(category)

    return {
      id: categoryId,
      name: category.name || `Category ${categoryId}`,
      status,
      statusLabel: getStatusLabel(status),
      isActive: props.activeCategory === categoryId,
      canRegister: status === 'ELIGIBLE',
      canClaim: status === 'CLAIMABLE',
      claimableAmount: category.claimableAmount
    }
  })
})

// Computed: Summary counts
const totalCategories = computed(() => props.categories.length)

const registeredCount = computed(() =>
  categoryStatuses.value.filter(cat =>
    cat.status === 'REGISTERED' ||
    cat.status === 'CLAIMABLE' ||
    cat.status === 'CLAIMED' ||
    cat.status === 'LOCKED'
  ).length
)

const eligibleCount = computed(() =>
  categoryStatuses.value.filter(cat => cat.status === 'ELIGIBLE').length
)

const claimableCount = computed(() =>
  categoryStatuses.value.filter(cat => cat.status === 'CLAIMABLE').length
)

const hasEligibleCategories = computed(() => eligibleCount.value > 0)
const hasClaimableCategories = computed(() => claimableCount.value > 0)

// Methods: Get user status for category
function getCategoryUserStatus(category: any): CategoryUserStatus {
  if (!props.isAuthenticated) {
    return 'NOT_ELIGIBLE'
  }

  // Check if user has allocation in this category (from category.participants)
  const currentUserPrincipal = props.userContext?.principal
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
      const userScore = Number(props.userContext?.passportScore || 0)

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
  // Use injected values from parent if available (vesting-aware), otherwise fall back to participant data
  const eligibleAmount = category.eligibleAmount !== undefined
    ? BigInt(category.eligibleAmount)
    : BigInt(userCategoryData.allocation || 0)

  const claimedAmount = category.claimedAmount !== undefined
    ? BigInt(category.claimedAmount)
    : BigInt(userCategoryData.claimed || 0)

  // Calculate claimable amount
  // Priority: 1. Injected value (vesting-aware), 2. Local calculation (naive)
  const claimableAmount = category.claimableAmount !== undefined
    ? BigInt(category.claimableAmount)
    : (eligibleAmount > claimedAmount ? eligibleAmount - claimedAmount : BigInt(0))

  // Check if fully claimed
  if (eligibleAmount > 0 && claimedAmount >= eligibleAmount) {
    return 'CLAIMED'
  }

  // Check if can claim now
  if (claimableAmount > 0) {
    return 'CLAIMABLE'
  }

  // Check if vesting has started
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

// Methods: Get status label
function getStatusLabel(status: CategoryUserStatus): string {
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

// Methods: Scroll to category
function scrollToCategory(categoryId: string) {
  emit('scroll-to-category', categoryId)
  const element = document.getElementById(`category-${categoryId}`)
  if (element) {
    element.scrollIntoView({ behavior: 'smooth', block: 'start' })
    // Add highlight animation
    element.classList.add('highlight-pulse')
    setTimeout(() => {
      element.classList.remove('highlight-pulse')
    }, 2000)
  }
}

// Helper Methods: Get status icon component
function getStatusIconComponent(status: CategoryUserStatus) {
  switch (status) {
    case 'NOT_ELIGIBLE':
      return LockIcon
    case 'ELIGIBLE':
      return CircleIcon
    case 'REGISTERED':
      return CheckCircle2Icon
    case 'CLAIMABLE':
      return GiftIcon
    case 'CLAIMED':
      return CheckCircle2Icon
    case 'LOCKED':
      return ClockIcon
    default:
      return AlertCircleIcon
  }
}

// Helper Methods: Get status icon color class
function getStatusIconColorClass(status: CategoryUserStatus): string {
  switch (status) {
    case 'NOT_ELIGIBLE':
      return 'text-gray-400'
    case 'ELIGIBLE':
      return 'text-blue-500'
    case 'REGISTERED':
      return 'text-blue-500'
    case 'CLAIMABLE':
      return 'text-green-500'
    case 'CLAIMED':
      return 'text-green-500'
    case 'LOCKED':
      return 'text-amber-500'
    default:
      return 'text-gray-400'
  }
}

// Helper Methods: Get status badge class
function getStatusBadgeClass(status: CategoryUserStatus): string {
  switch (status) {
    case 'NOT_ELIGIBLE':
      return 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300'
    case 'ELIGIBLE':
      return 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
    case 'REGISTERED':
      return 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
    case 'CLAIMABLE':
      return 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
    case 'CLAIMED':
      return 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300'
    case 'LOCKED':
      return 'bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-300'
    default:
      return 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300'
  }
}

// Helper Methods: Get status emoji
function getStatusEmoji(status: CategoryUserStatus): string {
  switch (status) {
    case 'NOT_ELIGIBLE':
      return '🔒'
    case 'ELIGIBLE':
      return '✨'
    case 'REGISTERED':
      return '✅'
    case 'CLAIMABLE':
      return '🎁'
    case 'CLAIMED':
      return '✅'
    case 'LOCKED':
      return '⏳'
    default:
      return '❓'
  }
}
</script>

<style scoped>
/* Custom scrollbar for category list */
.scrollbar-thin::-webkit-scrollbar {
  width: 6px;
}

.scrollbar-thin::-webkit-scrollbar-track {
  background: transparent;
}

.scrollbar-thin::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb {
  background: #475569;
}

.scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.dark .scrollbar-thin::-webkit-scrollbar-thumb:hover {
  background: #64748b;
}

/* Category item hover effect */
.category-status-item {
  position: relative;
  transition: all 0.2s ease;
}

.category-status-item::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 0;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  border-radius: 0 2px 2px 0;
  transition: height 0.2s ease;
}

.category-status-item:hover::before {
  height: 60%;
}


/* Mobile responsive */
@media (max-width: 1024px) {
  .category-status-sidebar {
    position: relative;
    top: 0;
  }
}

/* Highlight pulse animation for scrolled category */
:global(.highlight-pulse) {
  animation: highlight-pulse 2s ease-out;
}

@keyframes highlight-pulse {

  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0);
  }

  50% {
    box-shadow: 0 0 0 10px rgba(59, 130, 246, 0.3);
  }
}
</style>
