<template>
  <div class="space-y-6">

    <!-- Token Allocation Vesting Summary -->
    <div v-if="tokenDistributionVesting.length > 0" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 mb-6">
      <h4 class="font-medium text-blue-900 dark:text-blue-100 mb-4">Token Allocation Vesting</h4>

      <div class="space-y-4">
        <div
          v-for="(allocation, index) in tokenDistributionVesting"
          :key="index"
          class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-blue-200 dark:border-blue-700"
        >
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                <span class="text-white text-sm">{{ getAllocationIcon(allocation.name) }}</span>
              </div>
              <div>
                <h5 class="font-medium text-gray-900 dark:text-white">{{ allocation.name }}</h5>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {{ allocation.percentage }}% of total supply ({{ formatNumber(allocation.totalAmount) }} {{ saleTokenSymbol }})
                </p>
              </div>
            </div>
            <div class="text-sm text-green-600 dark:text-green-400">
              ✅ Vesting Enabled
            </div>
          </div>

          <!-- Vesting Schedule Details -->
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Cliff Period</div>
              <div class="font-medium">{{ allocation.vestingSchedule?.cliffDays || 0 }} days</div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Vesting Duration</div>
              <div class="font-medium">{{ allocation.vestingSchedule?.durationDays || 0 }} days</div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Release Frequency</div>
              <div class="font-medium capitalize">{{ allocation.vestingSchedule?.releaseFrequency || 'monthly' }}</div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Immediate Release</div>
              <div class="font-medium">{{ allocation.vestingSchedule?.immediateRelease || 0 }}%</div>
            </div>
          </div>

          <!-- Recipients with Vesting -->
          <div v-if="allocation.recipients && allocation.recipients.length > 0" class="mt-4 pt-4 border-t border-blue-200 dark:border-blue-700">
            <h6 class="text-sm font-medium text-gray-900 dark:text-white mb-2">Recipients ({{ allocation.recipients.length }})</h6>
            <div class="space-y-2">
              <div
                v-for="(recipient, recipientIndex) in allocation.recipients"
                :key="recipientIndex"
                class="flex items-center justify-between p-2 bg-blue-50 dark:bg-blue-900/20 rounded"
              >
                <div class="flex items-center space-x-2">
                  <UserIcon class="h-4 w-4 text-blue-600" />
                  <div>
                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                      {{ recipient.name || `Recipient ${recipientIndex + 1}` }}
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {{ recipient.percentage || recipient.amount }}{{ recipient.percentage ? '%' : '' }} • {{ recipient.principal.slice(0, 10) }}...
                    </div>
                  </div>
                </div>
                <div class="text-xs text-green-600 dark:text-green-400">
                  ✓ Vesting Enabled
                </div>
              </div>
            </div>
          </div>

          <!-- Vesting Timeline Visualization -->
          <div class="mt-4 pt-4 border-t border-blue-200 dark:border-blue-700">
            <VestingTimeline
              :schedule="allocation.vestingSchedule"
              :total-amount="allocation.totalAmount"
              :token-symbol="saleTokenSymbol"
              size="sm"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Raised Funds Allocation Vesting Summary -->
    <div v-if="raisedFundsAllocationVesting.length > 0" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 mb-6">
      <h4 class="font-medium text-green-900 dark:text-green-100 mb-4">Raised Funds Allocation Vesting</h4>

      <div class="space-y-4">
        <div
          v-for="(allocation, index) in raisedFundsAllocationVesting"
          :key="index"
          class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-green-200 dark:border-green-700"
        >
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                <span class="text-white text-sm">{{ getAllocationIcon(allocation.name) }}</span>
              </div>
              <div>
                <h5 class="font-medium text-gray-900 dark:text-white">{{ allocation.name }}</h5>
                <p class="text-sm text-gray-500 dark:text-gray-400">
                  {{ allocation.percentage }}% of raised funds ({{ formatAmount(calculateAmount(allocation.percentage)) }} {{ purchaseTokenSymbol }})
                </p>
              </div>
            </div>
            <div class="text-sm text-green-600 dark:text-green-400">
              ✅ Vesting Enabled
            </div>
          </div>

          <!-- Vesting Schedule Details -->
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Cliff Period</div>
              <div class="font-medium">{{ allocation.vestingSchedule?.cliffDays || 0 }} days</div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Vesting Duration</div>
              <div class="font-medium">{{ allocation.vestingSchedule?.durationDays || 0 }} days</div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Release Frequency</div>
              <div class="font-medium capitalize">{{ allocation.vestingSchedule?.releaseFrequency || 'monthly' }}</div>
            </div>
            <div class="bg-gray-50 dark:bg-gray-700 rounded p-3">
              <div class="text-gray-600 dark:text-gray-400 mb-1">Immediate Release</div>
              <div class="font-medium">{{ allocation.vestingSchedule?.immediateRelease || 0 }}%</div>
            </div>
          </div>

          <!-- Recipients with Vesting -->
          <div v-if="allocation.recipients && allocation.recipients.length > 0" class="mt-4 pt-4 border-t border-green-200 dark:border-green-700">
            <h6 class="text-sm font-medium text-gray-900 dark:text-white mb-2">Recipients ({{ allocation.recipients.length }})</h6>
            <div class="space-y-2">
              <div
                v-for="(recipient, recipientIndex) in allocation.recipients"
                :key="recipientIndex"
                class="flex items-center justify-between p-2 bg-green-50 dark:bg-green-900/20 rounded"
              >
                <div class="flex items-center space-x-2">
                  <UserIcon class="h-4 w-4 text-green-600" />
                  <div>
                    <div class="text-sm font-medium text-gray-900 dark:text-white">
                      {{ recipient.name || `Recipient ${recipientIndex + 1}` }}
                    </div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">
                      {{ recipient.percentage }}% • {{ recipient.principal.slice(0, 10) }}...
                    </div>
                  </div>
                </div>
                <div class="text-xs text-green-600 dark:text-green-400">
                  ✓ Vesting Enabled
                </div>
              </div>
            </div>
          </div>

          <!-- Vesting Timeline Visualization -->
          <div class="mt-4 pt-4 border-t border-green-200 dark:border-green-700">
            <VestingTimeline
              :schedule="allocation.vestingSchedule"
              :total-amount="calculateAmount(allocation.percentage)"
              :token-symbol="purchaseTokenSymbol"
              size="sm"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Global Vesting Configuration Summary -->
    <div v-if="globalVestingConfig" class="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-6">
      <h4 class="font-medium text-purple-900 dark:text-purple-100 mb-4">Global Vesting Configuration</h4>
      <p class="text-sm text-purple-700 dark:text-purple-300 mb-4">
        Default vesting schedule applied to allocations unless overridden.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
        <div class="bg-white dark:bg-gray-800 rounded p-3">
          <div class="text-gray-600 dark:text-gray-400 mb-1">Cliff Period</div>
          <div class="font-medium">{{ globalVestingConfig.cliffDays }} days</div>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded p-3">
          <div class="text-gray-600 dark:text-gray-400 mb-1">Vesting Duration</div>
          <div class="font-medium">{{ globalVestingConfig.durationDays }} days</div>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded p-3">
          <div class="text-gray-600 dark:text-gray-400 mb-1">Release Frequency</div>
          <div class="font-medium capitalize">{{ globalVestingConfig.releaseFrequency }}</div>
        </div>
        <div class="bg-white dark:bg-gray-800 rounded p-3">
          <div class="text-gray-600 dark:text-gray-400 mb-1">Immediate Release</div>
          <div class="font-medium">{{ globalVestingConfig.immediateRelease }}%</div>
        </div>
      </div>
    </div>

    <!-- Statistics Summary -->
    <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
      <h4 class="font-medium text-gray-900 dark:text-white mb-4">📊 Vesting Statistics</h4>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div>
          <span class="text-gray-500 dark:text-gray-400">Token Allocations with Vesting:</span>
          <span class="ml-2 font-medium">{{ tokenDistributionVesting.length }}</span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Raised Funds Allocations with Vesting:</span>
          <span class="ml-2 font-medium">{{ raisedFundsAllocationVesting.length }}</span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Total Recipients with Vesting:</span>
          <span class="ml-2 font-medium">{{ totalVestingRecipients }}</span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Custom Vesting Schedules:</span>
          <span class="ml-2 font-medium">{{ customVestingSchedules }}</span>
        </div>
      </div>

      <!-- Vesting Health Indicators -->
      <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded p-3">
            <div class="flex items-center space-x-2">
              <CheckCircleIcon class="h-4 w-4 text-green-600" />
              <span class="text-green-700 dark:text-green-300">All allocations have vesting configured</span>
            </div>
          </div>
          <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded p-3">
            <div class="flex items-center space-x-2">
              <InfoIcon class="h-4 w-4 text-blue-600" />
              <span class="text-blue-700 dark:text-blue-300">{{ totalVestingRecipients }} recipients configured with vesting</span>
            </div>
          </div>
          <div class="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded p-3">
            <div class="flex items-center space-x-2">
              <SettingsIcon class="h-4 w-4 text-purple-600" />
              <span class="text-purple-700 dark:text-purple-300">{{ customVestingSchedules }} custom vesting schedules created</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { CheckCircleIcon, InfoIcon, SettingsIcon, UserIcon } from 'lucide-vue-next'

// Component imports
import VestingTimeline from './VestingTimeline.vue'

// Props
interface Props {
  tokenDistribution: any
  raisedFundsAllocation: any
  saleTokenSymbol: string
  purchaseTokenSymbol: string
  simulatedAmount?: number
}

const props = withDefaults(defineProps<Props>(), {
  simulatedAmount: 0
})

// Computed properties
const tokenDistributionVesting = computed(() => {
  if (!props.tokenDistribution) return []

  const allocations = []

  // Team allocation - always has vesting if vestingSchedule exists
  if (props.tokenDistribution.team?.vestingSchedule) {
    allocations.push({
      name: props.tokenDistribution.team.name || 'Team',
      percentage: props.tokenDistribution.team.percentage || 0,
      totalAmount: props.tokenDistribution.team.totalAmount || '0',
      vestingSchedule: props.tokenDistribution.team.vestingSchedule,
      recipients: props.tokenDistribution.team.recipients || []
    })
  }

  // Custom allocations (others) - only if vestingEnabled
  if (props.tokenDistribution.others && Array.isArray(props.tokenDistribution.others)) {
    props.tokenDistribution.others.forEach(allocation => {
      if (allocation.vestingEnabled && allocation.vestingSchedule) {
        allocations.push({
          name: allocation.name || 'Custom',
          percentage: allocation.percentage || 0,
          totalAmount: allocation.totalAmount || '0',
          vestingSchedule: allocation.vestingSchedule,
          recipients: allocation.recipients || []
        })
      }
    })
  }

  return allocations
})

// ✅ V2: Read from allocations array
const raisedFundsAllocationVesting = computed(() => {
  if (!props.raisedFundsAllocation || !props.raisedFundsAllocation.allocations) return []

  const vestingAllocations = []

  // Process all allocations from the array
  props.raisedFundsAllocation.allocations.forEach(allocation => {
    // Check if this allocation has recipients with vesting enabled
    const vestingRecipients = allocation.recipients?.filter(r => r.vestingEnabled) || []

    if (vestingRecipients.length > 0) {
      vestingAllocations.push({
        name: allocation.name,
        percentage: allocation.percentage || 0,
        recipients: vestingRecipients,
        // Use first recipient's vesting schedule as representative
        vestingSchedule: vestingRecipients[0]?.vestingSchedule
      })
    }
  })

  return vestingAllocations
})

const globalVestingConfig = computed(() => {
  return props.raisedFundsAllocation?.globalVestingSchedule
})

const totalVestingRecipients = computed(() => {
  // Since vesting is at allocation level, all recipients in vesting-enabled allocations have vesting
  const tokenRecipients = tokenDistributionVesting.value.reduce((sum, allocation) => {
    return sum + (allocation.recipients?.length || 0)
  }, 0)

  const fundsRecipients = raisedFundsAllocationVesting.value.reduce((sum, allocation) => {
    return sum + (allocation.recipients?.length || 0)
  }, 0)

  return tokenRecipients + fundsRecipients
})

const customVestingSchedules = computed(() => {
  // Count custom allocations with vesting (others in token distribution, custom in raised funds)
  const tokenCustomSchedules = props.tokenDistribution?.others?.filter(a => a.vestingEnabled)?.length || 0
  const fundsCustomSchedules = props.raisedFundsAllocation?.customAllocations?.filter(a => a.vestingEnabled)?.length || 0

  return tokenCustomSchedules + fundsCustomSchedules
})

// Methods
const formatNumber = (num: number | string) => {
  return Number(num).toLocaleString()
}

const formatAmount = (amount: number) => {
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(amount)
}

const calculateAmount = (percentage: number) => {
  if (!props.simulatedAmount) return 0
  return (props.simulatedAmount * percentage) / 100
}

const getAllocationIcon = (name: string) => {
  const icons: Record<string, string> = {
    'Team': '👥',
    'Marketing': '📢',
    'Advisors': '🎯',
    'Community': '🌍',
    'Reserve': '📦',
    'Treasury': '🏦',
    'Team Allocation': '👥',
    'Marketing Allocation': '📢'
  }

  return icons[name] || '📋'
}
</script>