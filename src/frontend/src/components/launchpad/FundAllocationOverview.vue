<template>
  <div>
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Summary Chart -->
      <div>
        <PieChart
          title="Complete Fund Allocation"
          :chart-data="chartData"
          :show-values="true"
          value-unit="ICP"
          center-label="Total Raised"
          :total-value="simulatedAmount"
        />
      </div>

      <!-- Breakdown Table -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
        <h6 class="font-medium text-gray-900 dark:text-white mb-3">💎 Usage Breakdown</h6>
        <div class="space-y-3 text-sm">

          <!-- Platform Fee -->
          <div class="flex justify-between items-center p-2 bg-red-50 dark:bg-red-900/20 rounded">
            <div class="flex items-center">
              <div class="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
              <span class="text-red-700 dark:text-red-300">Platform Fee ({{ platformFeePercentage.toFixed(1) }}%)</span>
            </div>
            <span class="font-medium text-red-700 dark:text-red-300">{{ formatNumber(platformFeeAmount) }}</span>
          </div>

          <!-- DEX Liquidity (Parent Category) -->
          <div v-if="dexAllocations.length > 0" class="space-y-2">
            <div class="flex justify-between items-center p-2 bg-orange-50 dark:bg-orange-900/20 rounded border-l-4 border-orange-500">
              <div class="flex items-center">
                <div class="w-3 h-3 rounded-full bg-orange-500 mr-2"></div>
                <span class="font-medium text-orange-700 dark:text-orange-300">DEX Liquidity ({{ totalDexPercentage.toFixed(1) }}%)</span>
              </div>
              <span class="font-bold text-orange-700 dark:text-orange-300">{{ formatNumber(totalDexAmount) }}</span>
            </div>

            <!-- Individual DEX Platforms (Sub-categories) -->
            <div v-for="dex in dexAllocations" :key="dex.id" class="flex justify-between items-center p-2 bg-orange-25 dark:bg-orange-900/10 rounded ml-6 border-l-2 border-orange-300">
              <div class="flex items-center">
                <div class="w-2 h-2 rounded-full bg-orange-400 mr-2"></div>
                <span class="text-orange-600 dark:text-orange-400 text-xs">{{ dex.name }} ({{ dex.percentage.toFixed(1) }}%)</span>
              </div>
              <span class="text-orange-600 dark:text-orange-400 text-xs">{{ formatNumber(dex.amount) }}</span>
            </div>
          </div>

          <!-- Team Allocation (Parent Category) -->
          <div v-if="teamAllocations.length > 0" class="space-y-2">
            <div class="flex justify-between items-center p-2 bg-blue-50 dark:bg-blue-900/20 rounded border-l-4 border-blue-500">
              <div class="flex items-center">
                <div class="w-3 h-3 rounded-full bg-blue-500 mr-2"></div>
                <span class="font-medium text-blue-700 dark:text-blue-300">Team Allocation ({{ totalTeamPercentage.toFixed(1) }}%)</span>
              </div>
              <span class="font-bold text-blue-700 dark:text-blue-300">{{ formatNumber(totalTeamAmount) }}</span>
            </div>

            <!-- Individual Team Recipients (Sub-categories) -->
            <div v-for="(recipient, index) in teamAllocations" :key="index" class="flex justify-between items-center p-2 bg-blue-25 dark:bg-blue-900/10 rounded ml-6 border-l-2 border-blue-300">
              <div class="flex items-center">
                <div class="w-2 h-2 rounded-full bg-blue-400 mr-2"></div>
                <span class="text-blue-600 dark:text-blue-400 text-xs">{{ recipient.name || `Team Member ${index + 1}` }} ({{ recipient.percentage.toFixed(1) }}%)</span>
              </div>
              <span class="text-blue-600 dark:text-blue-400 text-xs">{{ formatNumber(recipient.amount) }}</span>
            </div>
          </div>

          <!-- Custom Allocations -->
          <div v-for="(allocation, index) in customAllocations"
               :key="allocation.id"
               class="flex justify-between items-center p-2 bg-gray-50 dark:bg-gray-700 rounded ml-4">
            <div class="flex items-center">
              <div
                class="w-2 h-2 rounded-full mr-2"
                :class="[
                  index === 0 ? 'bg-green-400' :
                  index === 1 ? 'bg-purple-400' :
                  index === 2 ? 'bg-yellow-400' :
                  'bg-pink-400'
                ]"
              ></div>
              <span class="text-gray-600 dark:text-gray-300 text-xs">{{ allocation.name }} ({{ allocation.percentage.toFixed(1) }}%)</span>
            </div>
            <span class="text-gray-700 dark:text-gray-300 text-xs">{{ formatNumber(allocation.amount) }}</span>
          </div>

          <!-- DAO Treasury (Root Category) -->
          <div v-if="treasuryAmount > 0" class="flex justify-between items-center p-2 bg-gray-50 dark:bg-gray-700 rounded">
            <div class="flex items-center">
              <div class="w-3 h-3 rounded-full bg-gray-400 mr-2"></div>
              <span class="text-gray-600 dark:text-gray-300">DAO Treasury ({{ treasuryPercentage.toFixed(1) }}%)</span>
            </div>
            <span class="text-gray-700 dark:text-gray-300">{{ formatNumber(treasuryAmount) }}</span>
          </div>
        </div>
      </div>
    </div>
     <!-- DEX Configuration -->
     <div v-if="dexConfig && Object.keys(dexConfig).length > 0" class="bg-white dark:bg-gray-800 rounded-lg p-4">
            <h4 class="font-semibold text-gray-900 dark:text-white mb-3">DEX Configuration <span class="text-xs text-blue-600 border border-blue-600 rounded-full px-2 py-1">{{ dexConfig.autoList ? 'Auto-listing' : 'Manual listing' }}</span></h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Primary Platform:</span>
                <span class="font-medium">{{ dexConfig.platform || 'Not specified' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Liquidity Allocation:</span>
                <span class="font-medium">{{ dexConfig.liquidityPercentage || 0 }}% of raised funds</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Liquidity Lock Days:</span>
                <span class="font-medium">{{ dexConfig.liquidityLockDays || 0 }} days</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">LP Token Recipient:</span>
                <span class="text-sm text-blue-600">{{ dexConfig.lpTokenRecipient || 'Not specified' }}</span>
              </div>
            </div>
          </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import PieChart from '@/components/common/PieChart.vue'

const props = defineProps({
  allocation: {
    type: Object,
    required: true
  },
  simulatedAmount: {
    type: Number,
    required: true
  },
  platformFeeRate: {
    type: Number,
    default: 2
  },
  dexConfig: {
    type: Object,
    default: () => ({})
  }
})

// Access dexConfig for template with fallback
const dexConfig = computed(() => {
  // Prioritize dexConfig from allocation data, fallback to props
  return props.allocation?.dexConfig || props.dexConfig || {}
})

// Chart colors
const CHART_COLORS = [
  '#ef4444', // Platform Fee - Red
  '#f97316', // DEX Liquidity - Orange
  '#3b82f6', // Team Allocation - Blue
  '#10b981', // Custom 1 - Green
  '#8b5cf6', // Custom 2 - Purple
  '#f59e0b', // Custom 3 - Yellow
  '#ec4899', // Custom 4 - Pink
  '#6b7280'  // DAO Treasury - Gray
]

// Platform Fee Calculations
const platformFeeAmount = computed(() => props.simulatedAmount * (props.platformFeeRate / 100))
const platformFeePercentage = computed(() => props.platformFeeRate)

// DEX Calculations (Fixed percentages, dynamic amounts)
const dexAllocations = computed(() => {
  if (!props.allocation?.dexConfig?.autoList || !props.allocation?.availableDexs) return []

  const enabledDexs = props.allocation.availableDexs.filter(dex => dex.enabled)
  const dexLiquidityPercentage = Number(props.allocation.dexConfig.liquidityPercentage) || 0

  return enabledDexs.map(dex => {
    const dexShare = (dex.allocationPercentage || 0) / 100
    const dexPercentage = dexLiquidityPercentage * dexShare
    const dexAmount = props.simulatedAmount * (dexPercentage / 100)

    return {
      id: dex.id,
      name: dex.name,
      percentage: dexPercentage,
      amount: dexAmount
    }
  })
})

const totalDexPercentage = computed(() =>
  dexAllocations.value.reduce((sum, dex) => sum + dex.percentage, 0)
)

const totalDexAmount = computed(() =>
  dexAllocations.value.reduce((sum, dex) => sum + dex.amount, 0)
)

// Team Calculations (Fixed percentages, dynamic amounts)
const teamAllocations = computed(() => {
  if (!props.allocation?.teamRecipients || props.allocation.teamRecipients.length === 0) return []

  const teamPercentage = Number(props.allocation.teamAllocationPercentage) || 0

  return props.allocation.teamRecipients
    .filter(recipient => recipient.percentage > 0)
    .map(recipient => {
      const recipientShare = (recipient.percentage || 0) / 100
      const recipientPercentage = teamPercentage * recipientShare
      const recipientAmount = props.simulatedAmount * (recipientPercentage / 100)

      return {
        name: recipient.name,
        percentage: recipientPercentage,
        amount: recipientAmount
      }
    })
})

const totalTeamPercentage = computed(() =>
  teamAllocations.value.reduce((sum, recipient) => sum + recipient.percentage, 0)
)

const totalTeamAmount = computed(() =>
  teamAllocations.value.reduce((sum, recipient) => sum + recipient.amount, 0)
)

// Custom Allocations (Fixed percentages, dynamic amounts)
const customAllocations = computed(() => {
  if (!props.allocation?.customAllocations) return []

  return props.allocation.customAllocations
    .filter(allocation => allocation && allocation.percentage > 0)
    .map(allocation => ({
      id: allocation.id,
      name: allocation.name,
      percentage: allocation.percentage,
      amount: props.simulatedAmount * (allocation.percentage / 100)
    }))
})

// DAO Treasury (Remaining amount)
const treasuryAmount = computed(() => {
  const allocated = platformFeeAmount.value + totalDexAmount.value + totalTeamAmount.value +
    customAllocations.value.reduce((sum, alloc) => sum + alloc.amount, 0)
  return Math.max(0, props.simulatedAmount - allocated)
})

const treasuryPercentage = computed(() =>
  props.simulatedAmount > 0 ? (treasuryAmount.value / props.simulatedAmount) * 100 : 0
)

// Chart Data
const chartData = computed(() => {
  const labels = []
  const data = []
  const values = []
  const colors = []

  // Platform Fee
  if (platformFeeAmount.value > 0) {
    labels.push('Platform Fee')
    data.push(platformFeePercentage.value)
    values.push(platformFeeAmount.value)
    colors.push(CHART_COLORS[0])
  }

  // DEX Liquidity (as single category)
  if (totalDexAmount.value > 0) {
    labels.push('DEX Liquidity')
    data.push(totalDexPercentage.value)
    values.push(totalDexAmount.value)
    colors.push(CHART_COLORS[1])
  }

  // Team Allocation (as single category)
  if (totalTeamAmount.value > 0) {
    labels.push('Team Allocation')
    data.push(totalTeamPercentage.value)
    values.push(totalTeamAmount.value)
    colors.push(CHART_COLORS[2])
  }

  // Custom Allocations
  customAllocations.value.forEach((allocation, index) => {
    labels.push(allocation.name)
    data.push(allocation.percentage)
    values.push(allocation.amount)
    colors.push(CHART_COLORS[3 + index] || CHART_COLORS[CHART_COLORS.length - 1])
  })

  // DAO Treasury
  if (treasuryAmount.value > 0) {
    labels.push('DAO Treasury')
    data.push(treasuryPercentage.value)
    values.push(treasuryAmount.value)
    colors.push(CHART_COLORS[CHART_COLORS.length - 1])
  }

  return {
    labels,
    data,
    values,
    colors,
    percentages: data.map(d => Number(d.toFixed(1)))
  }
})

// Format number helper
const formatNumber = (amount) => {
  const numAmount = Number(amount)
  if (isNaN(numAmount)) return '0.00'
  return numAmount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}
</script>