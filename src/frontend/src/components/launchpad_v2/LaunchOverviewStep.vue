<template>
  <div class="space-y-6">
    <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Launch Overview & Terms</h2>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
      Review your complete launch configuration and accept the terms before deployment.
    </p>

    <!-- Complete Project Summary -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-xl p-6 border border-blue-200 dark:border-blue-700 mb-8">
      <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">🚀 Complete Project Summary</h3>

      <!-- Project Information -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div class="bg-white dark:bg-gray-800 rounded-lg p-4">
          <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Project Information</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Project Name:</span>
              <span class="font-medium">{{ formData.value?.projectInfo?.name || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Category:</span>
              <span class="font-medium">{{ formData.value?.projectInfo?.category || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Token Name:</span>
              <span class="font-medium">{{ formData.value?.saleToken?.name || 'Not specified' }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Token Symbol:</span>
              <span class="font-medium">{{ formData.value?.saleToken?.symbol || 'Not specified' }}</span>
            </div>
          </div>
        </div>

        <div class="bg-white dark:bg-gray-800 rounded-lg p-4">
          <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Sale Configuration</h4>
          <div class="space-y-2 text-sm">
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Sale Type:</span>
              <span class="font-medium">{{ formData.value?.saleParams?.saleType }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Soft Cap:</span>
              <span class="font-medium">{{ formatNumber(formData.value?.saleParams?.softCap) }} {{ purchaseTokenSymbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Hard Cap:</span>
              <span class="font-medium">{{ formatNumber(formData.value?.saleParams?.hardCap) }} {{ purchaseTokenSymbol }}</span>
            </div>
            <div class="flex justify-between">
              <span class="text-gray-600 dark:text-gray-400">Token Price Range:</span>
              <span class="font-medium">{{ tokenPriceRange }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Token Distribution Overview -->
      <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-6">
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Chart Section -->
          <div>
            <PieChart
              title="Token Distribution"
              :chart-data="overviewTokenChartData"
              :show-values="true"
              :value-unit="saleTokenSymbol"
              center-label="Total Supply"
              :total-value="Number(formData.value?.saleToken?.totalSupply) || 0"
            />
          </div>

          <!-- Summary Section -->
          <div class="space-y-4">
            <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Token Allocation Summary</h4>
            <div class="space-y-3">
              <div v-for="(allocation, index) in tokenAllocations" :key="index" class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                <div class="flex items-center space-x-3">
                  <div class="w-4 h-4 rounded-full" :style="{ backgroundColor: getAllocationColor(index) }"></div>
                  <div>
                    <div class="font-medium text-gray-900 dark:text-white">{{ allocation.name }}</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">{{ allocation.percentage }}% of total supply</div>
                    <div v-if="allocation.vestingEnabled && allocation.vestingInfo" class="text-xs text-purple-600 dark:text-purple-400 mt-1 space-y-0.5">
                      <div>⏰ Cliff: {{ allocation.vestingInfo.cliff }}d | Init: {{ allocation.vestingInfo.immediate }}%</div>
                      <div>Duration: {{ allocation.vestingInfo.duration }}d | Freq: {{ allocation.vestingInfo.frequency }}</div>
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="font-bold text-gray-900 dark:text-white">{{ formatNumber(Number(allocation.totalAmount)) }}</div>
                  <div class="text-xs text-gray-500 dark:text-gray-400">{{ saleTokenSymbol }}</div>
                </div>
              </div>

              <!-- Remaining/Treasury (includes LP estimate) -->
              <div v-if="remainingAllocation > 0" class="flex items-center justify-between p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                <div class="flex items-center space-x-3">
                  <div class="w-4 h-4 rounded-full bg-blue-500"></div>
                  <div class="flex-1">
                    <div class="font-medium text-blue-900 dark:text-blue-100">Remaining (Auto Treasury)</div>
                    <div class="text-xs text-blue-600 dark:text-blue-400">{{ remainingPercentage.toFixed(2) }}% remaining</div>
                    <div v-if="lpTokenEstimate.max > 0" class="text-xs text-orange-600 dark:text-orange-400 mt-1">
                      Includes LP: {{ formatNumber(lpTokenEstimate.min) }} - {{ formatNumber(lpTokenEstimate.max) }} {{ saleTokenSymbol }}
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <div class="font-bold text-blue-900 dark:text-blue-100">{{ formatNumber(remainingAllocation) }}</div>
                  <div class="text-xs text-blue-600 dark:text-blue-400">{{ saleTokenSymbol }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Raised Funds Usage Overview -->
    <div class="bg-gradient-to-br from-yellow-50 to-amber-50 dark:from-yellow-900/20 dark:to-amber-900/20 rounded-lg border border-yellow-200 dark:border-yellow-700 p-6 mb-8">
      <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">💰 Raised Funds Usage Overview</h4>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
        Simulate different funding scenarios to understand how raised funds will be allocated.
      </p>

      <!-- Funding Simulation -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 mb-6">
        <div class="flex justify-between items-center mb-4">
          <h5 class="font-medium text-gray-900 dark:text-white">📊 Funding Simulation</h5>
          <div class="text-sm font-bold text-blue-600">{{ formatNumber(localSimulatedAmount) }} {{ purchaseTokenSymbol }}</div>
        </div>

        <input
          v-model.number="localSimulatedAmount"
          type="range"
          :min="softCapAmount"
          :max="hardCapAmount"
          :step="stepSize"
          class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
        />
        <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
          <span>Soft Cap: {{ formatNumber(softCapAmount) }} {{ purchaseTokenSymbol }}</span>
          <span>Hard Cap: {{ formatNumber(hardCapAmount) }} {{ purchaseTokenSymbol }}</span>
        </div>
      </div>

      <!-- Fund Allocation Overview -->
      <FundAllocationOverview
        :allocation="formData.raisedFundsAllocation"
        :simulated-amount="localSimulatedAmount"
        :platform-fee-rate="platformFeePercentage"
        :dex-config="formData.raisedFundsAllocation?.dexConfig"
      />
    </div>

    <!-- Timeline Summary -->
    <div class="bg-white dark:bg-gray-800 rounded-lg p-6 mb-8">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">📅 Timeline Summary</h3>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
        <div>
          <div class="text-gray-600 dark:text-gray-400">Sale Start</div>
          <div class="font-medium">{{ formatDate(formData.value?.timeline?.saleStart) }}</div>
        </div>
        <div>
          <div class="text-gray-600 dark:text-gray-400">Sale End</div>
          <div class="font-medium">{{ formatDate(formData.value?.timeline?.saleEnd) }}</div>
        </div>
        <div>
          <div class="text-gray-600 dark:text-gray-400">Claim Start</div>
          <div class="font-medium">{{ formatDate(formData.value?.timeline?.claimStart) }}</div>
        </div>
      </div>
    </div>


    <!-- Unallocated Assets Management -->
    <div v-if="hasUnallocatedAssets" class="bg-amber-50 dark:bg-amber-900/10 rounded-lg border-2 border-amber-300 dark:border-amber-700 p-6 mb-8">
      <UnallocatedAssetsManagement
        :sale-token-symbol="saleTokenSymbol"
        :purchase-token-symbol="purchaseTokenSymbol"
      />
    </div>

    <!-- Community Governance (Optional - Only show if DAO not selected for unallocated) -->
    <div v-if="!isDaoSelectedForUnallocated" class="bg-white dark:bg-gray-800 rounded-lg p-6 mb-8">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">🏛️ Community Governance (Optional)</h3>
          <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">
            Enable DAO for community operations and future governance decisions
          </p>
        </div>
        <label class="relative inline-flex items-center cursor-pointer">
          <input
            type="checkbox"
            v-model="communityGovernanceEnabled"
            class="sr-only peer"
          />
          <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-purple-300 dark:peer-focus:ring-purple-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-purple-600"></div>
        </label>
      </div>

      <div v-if="communityGovernanceEnabled" class="mt-4 p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800">
        <p class="text-sm text-purple-800 dark:text-purple-200">
          ✓ Community governance will be enabled for proposal voting and community operations
        </p>
      </div>
    </div>

    <!-- Validation Summary -->
    <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 mb-8">
      <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-4">✅ Validation Summary</h3>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
        <div class="flex items-center space-x-2">
          <CheckIcon class="h-4 w-4 text-green-600" />
          <span class="text-gray-700 dark:text-gray-300">Project Information</span>
        </div>
        <div class="flex items-center space-x-2">
          <CheckIcon class="h-4 w-4 text-green-600" />
          <span class="text-gray-700 dark:text-gray-300">Token Configuration</span>
        </div>
        <div class="flex items-center space-x-2">
          <CheckIcon class="h-4 w-4 text-green-600" />
          <span class="text-gray-700 dark:text-gray-300">Distribution Setup</span>
        </div>
        <div class="flex items-center space-x-2">
          <CheckIcon class="h-4 w-4 text-green-600" />
          <span class="text-gray-700 dark:text-gray-300">Governance Model</span>
        </div>
      </div>
    </div>

    <!-- Deployment Cost Breakdown -->
    <CostBreakdownPreview
      :needs-token-deployment="formData.value?.deployNewToken || false"
      :enable-d-a-o="communityGovernanceEnabled"
      class="mb-8"
    />

    <!-- Terms & Conditions -->
    <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
      <div class="prose dark:prose-invert max-w-none">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Platform Terms & Conditions</h3>
        <div class="space-y-4 text-sm text-gray-700 dark:text-gray-300">
          <p>By proceeding with this token launch, you acknowledge and agree to the following:</p>
          <ul class="list-disc list-inside space-y-2 ml-4">
            <li>All information provided is accurate and truthful</li>
            <li>You have the necessary rights and permissions to conduct this token sale</li>
            <li>You comply with all applicable laws and regulations in your jurisdiction</li>
            <li>Platform fees ({{ platformFeePercentage }}%) will be deducted from raised funds</li>
            <li>DEX listing fees and liquidity requirements are your responsibility</li>
            <li>The platform is not responsible for the success or failure of your project</li>
            <li>You understand the risks associated with token launches and DeFi protocols</li>
          </ul>
        </div>
      </div>

      <div class="border-t border-gray-200 dark:border-gray-600 pt-6 mt-6">
        <div class="flex items-start space-x-3">
          <input
            :id="uniqueIds.acceptTerms"
            v-model="localAcceptTerms"
            type="checkbox"
            class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600 mt-0.5"
            required
          />
          <label :for="uniqueIds.acceptTerms" class="text-sm text-gray-700 dark:text-gray-300">
            I understand and accept the terms and conditions for launching a token sale on this platform.
            I confirm that all information provided is accurate and that I have the necessary rights to conduct this token sale.
          </label>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { CheckIcon } from 'lucide-vue-next'

// Component imports
import PieChart from '@/components/common/PieChart.vue'
import FundAllocationOverview from '@/components/launchpad/FundAllocationOverview.vue'
import UnallocatedAssetsManagement from './UnallocatedAssetsManagement.vue'
import CostBreakdownPreview from './CostBreakdownPreview.vue'

// Composables
import { useUniqueId } from '@/composables/useUniqueId'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Props
interface Props {
  acceptTerms?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  acceptTerms: false
})

// Emits
const emit = defineEmits<{
  'update:acceptTerms': [value: boolean]
}>()

// Composable - centralized state management
const launchpadForm = useLaunchpadForm()
const {
  formData,
  platformFeePercentage,
  simulatedAmount
} = launchpadForm

// Local state
const uniqueIds = {
  acceptTerms: useUniqueId('accept-terms')
}

// Computed properties
const isDaoSelectedForUnallocated = computed(() => {
  return formData.value?.unallocatedManagement?.model === 'dao_treasury'
})

const communityGovernanceEnabled = computed({
  get: () => formData.value?.governanceConfig?.enabled || false,
  set: (value) => {
    if (formData.value?.governanceConfig) {
      formData.value.governanceConfig.enabled = value
    }
  }
})

// Chart computed properties
const totalAllocationPercentage = computed(() => {
  const distribution = formData.value?.distribution
  if (!distribution) return 0

  // Bỏ liquidityPool vì đã được tính trong Remaining
  const allocations = [
    distribution.sale?.percentage || 0,
    distribution.team?.percentage || 0,
    // distribution.liquidityPool?.percentage || 0, // Removed - included in Remaining
  ]

  // Add others
  if (distribution.others && Array.isArray(distribution.others)) {
    distribution.others.forEach(alloc => {
      if (alloc && alloc.percentage) {
        allocations.push(alloc.percentage)
      }
    })
  }

  return allocations.reduce((sum, value) => sum + Number(value), 0)
})

// ✅ V2: Calculate total from allocations array
const totalRaisedFundsPercentage = computed(() => {
  const allocation = formData.value?.raisedFundsAllocation
  if (!allocation || !allocation.allocations) return 0

  // Sum all percentages from allocations array
  return allocation.allocations.reduce((total, alloc) => {
    return total + Number(alloc.percentage || 0)
  }, 0)
})

const localSimulatedAmount = computed({
  get: () => simulatedAmount.value,
  set: (value) => { simulatedAmount.value = value }
})

const localAcceptTerms = computed({
  get: () => props.acceptTerms,
  set: (value) => { emit('update:acceptTerms', value) }
})

const purchaseTokenSymbol = computed(() => {
  return formData.value?.purchaseToken?.symbol || 'ICP'
})

const saleTokenSymbol = computed(() => {
  return formData.value?.saleToken?.symbol || 'TOKEN'
})

const softCapAmount = computed(() => Number(formData.value?.saleParams?.softCap) || 0)
const hardCapAmount = computed(() => Number(formData.value?.saleParams?.hardCap) || 0)

const stepSize = computed(() => {
  const diff = hardCapAmount.value - softCapAmount.value
  return diff > 0 ? Math.max(1, Math.floor(diff / 100)) : 1000
})

const tokenPriceRange = computed(() => {
  const softCap = Number(formData.value?.saleParams?.softCap) || 0
  const hardCap = Number(formData.value?.saleParams?.hardCap) || 0
  const saleAmount = Number(formData.value?.saleParams?.totalSaleAmount) || 0

  if (saleAmount > 0) {
    const minPrice = softCap / saleAmount
    const maxPrice = hardCap / saleAmount
    return `${minPrice.toFixed(6)} - ${maxPrice.toFixed(6)} ${purchaseTokenSymbol.value}`
  }
  return 'Not calculated'
})

const tokenAllocations = computed(() => {
  if (!formData.value?.distribution) return []

  // Bỏ liquidityPool vì đã được tính trong Remaining
  const allocations = [
    formData.value.distribution.sale,
    formData.value.distribution.team,
    // formData.value.distribution.liquidityPool, // Removed - included in Remaining
    ...(formData.value.distribution.others || [])
  ].filter(Boolean) // Remove any null/undefined

  const result = allocations.map(allocation => {
    const vestingSchedule = allocation.vestingSchedule
    const hasVesting = !!(vestingSchedule && Object.keys(vestingSchedule).length > 0)

    console.log(`[LaunchOverviewStep] 📊 Allocation "${allocation.name}":`, {
      hasVestingSchedule: !!vestingSchedule,
      vestingSchedule,
      hasVesting
    })

    return {
      name: allocation.name || 'Unknown',
      percentage: allocation.percentage || 0,
      totalAmount: allocation.totalAmount || '0',
      vestingEnabled: hasVesting,
      vestingInfo: hasVesting ? {
        cliff: vestingSchedule.cliffDays || 0,
        immediate: vestingSchedule.immediatePercentage || 0,
        duration: vestingSchedule.durationDays || 0,
        frequency: vestingSchedule.releaseFrequency || 'monthly'
      } : null
    }
  })

  console.log('[LaunchOverviewStep] 📋 Final tokenAllocations:', result)
  return result
})

// LP Token Estimate (based on raised funds and DEX liquidity %)
const lpTokenEstimate = computed(() => {
  // ✅ V2: Get DEX liquidity percentage from allocations array
  const allocation = formData.value?.raisedFundsAllocation
  const dexAllocation = allocation?.allocations?.find(a => a.id === 'dex_liquidity')
  const dexLiqPercentage = Number(dexAllocation?.percentage) || 0

  if (dexLiqPercentage === 0) return { min: 0, max: 0 }

  const softCap = Number(formData.value?.saleParams?.softCap) || 0
  const hardCap = Number(formData.value?.saleParams?.hardCap) || 0
  const totalSaleAmount = Number(formData.value?.saleParams?.totalSaleAmount) || 0

  if (totalSaleAmount === 0) return { min: 0, max: 0 }

  // Platform fee
  const platformFee = platformFeePercentage / 100

  // Calculate token price at soft and hard cap
  const minPrice = softCap / totalSaleAmount
  const maxPrice = hardCap / totalSaleAmount

  // Calculate LP funds allocation
  const minLpFunds = (softCap - softCap * platformFee) * (dexLiqPercentage / 100)
  const maxLpFunds = (hardCap - hardCap * platformFee) * (dexLiqPercentage / 100)

  // Convert to token amount
  const minTokens = minLpFunds / minPrice
  const maxTokens = maxLpFunds / maxPrice

  return { min: minTokens, max: maxTokens }
})

const remainingAllocation = computed(() => {
  const totalSupply = Number(formData.value?.saleToken?.totalSupply) || 0
  const allocated = tokenAllocations.value.reduce((sum, allocation) => sum + Number(allocation.totalAmount), 0)
  return totalSupply - allocated
})

const remainingPercentage = computed(() => {
  const totalSupply = Number(formData.value?.saleToken?.totalSupply) || 0
  if (totalSupply === 0) return 0
  return (remainingAllocation.value / totalSupply) * 100
})

// Check if there are unallocated assets
const hasUnallocatedAssets = computed(() => {
  const unallocatedTokens = 100 - totalAllocationPercentage.value
  const unallocatedFunds = 100 - totalRaisedFundsPercentage.value
  return unallocatedTokens > 0.01 || unallocatedFunds > 0.01 // 0.01% threshold
})

const overviewTokenChartData = computed(() => {
  if (!formData.value?.distribution) {
    return {
      labels: [],
      data: [],
      values: [],
      colors: [],
      percentages: []
    }
  }

  const colors = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6']
  // Bỏ liquidityPool vì đã được tính trong Auto Treasury
  const allAllocations = [
    formData.value.distribution.sale,
    formData.value.distribution.team,
    // formData.value.distribution.liquidityPool, // Removed - included in Auto Treasury
    ...(formData.value.distribution.others || [])
  ].filter(Boolean)

  const labels = allAllocations.map(a => a.name || 'Unnamed')
  const data = allAllocations.map(a => Number(a.percentage || 0))
  const values = allAllocations.map(a => Number(a.totalAmount || 0))

  // Add remaining portion if exists
  const totalAllocated = data.reduce((sum, value) => sum + value, 0)
  const unallocatedPercentage = Math.max(0, 100 - totalAllocated)
  const totalSupply = Number(formData.value.saleToken.totalSupply) || 0

  if (unallocatedPercentage > 0) {
    labels.push('Auto Treasury')
    data.push(unallocatedPercentage)
    values.push(totalSupply * (unallocatedPercentage / 100))
  }

  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages: data.map(value => Number(value.toFixed(1)))
  }
})

// Methods
const formatNumber = (num: number | string) => {
  return Number(num).toLocaleString()
}

const formatDate = (dateString: string) => {
  if (!dateString) return 'Not set'
  try {
    return new Date(dateString).toLocaleString()
  } catch {
    return 'Invalid date'
  }
}

const getAllocationColor = (index: number) => {
  const colors = ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#06B6D4', '#84CC16', '#F97316', '#EC4899', '#6366F1']
  return colors[index % colors.length]
}
</script>

<style scoped>
/* Custom slider styling */
.slider::-webkit-slider-thumb {
  appearance: none;
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3B82F6, #1D4ED8);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(59, 130, 246, 0.4);
  border: 2px solid white;
  transition: all 0.2s ease;
}

.slider::-webkit-slider-thumb:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.6);
}

.slider::-moz-range-thumb {
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3B82F6, #1D4ED8);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(59, 130, 246, 0.4);
  border: 2px solid white;
  transition: all 0.2s ease;
}

.slider::-webkit-slider-track {
  height: 6px;
  border-radius: 3px;
  background: linear-gradient(to right, #FEF3C7 0%, #F59E0B 100%);
}

.slider::-moz-range-track {
  height: 6px;
  border-radius: 3px;
  background: linear-gradient(to right, #FEF3C7 0%, #F59E0B 100%);
}

.slider:focus {
  outline: none;
}

.dark .slider::-webkit-slider-track {
  background: linear-gradient(to right, #451A03 0%, #F59E0B 100%);
}

.dark .slider::-moz-range-track {
  background: linear-gradient(to right, #451A03 0%, #F59E0B 100%);
}
</style>