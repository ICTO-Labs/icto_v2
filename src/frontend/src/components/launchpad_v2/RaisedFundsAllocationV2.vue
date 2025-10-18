<template>
  <div class="space-y-6">
    <!-- Funding Simulation Slider -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 mb-6">
      <div class="flex justify-between items-center mb-4">
        <h5 class="font-medium text-gray-900 dark:text-white">📊 Funding Simulation</h5>
        <div class="text-sm font-bold text-blue-600">{{ formatNumber(simulatedAmount) }} {{ purchaseTokenSymbol }}</div>
      </div>

      <input
        v-model.number="simulatedAmount"
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

    <!-- Team Allocation (Collapsible) -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
      <!-- Header - Clickable to toggle -->
      <div
        @click="teamExpanded = !teamExpanded"
        class="p-4 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/30 dark:to-emerald-900/30 cursor-pointer hover:from-green-100 hover:to-emerald-100 dark:hover:from-green-900/40 dark:hover:to-emerald-900/40 transition-colors"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <ChevronDownIcon
              :class="['h-5 w-5 text-green-600 transition-transform', teamExpanded ? 'rotate-180' : '']"
            />
            <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
              <span class="text-white text-sm font-bold">👥</span>
            </div>
            <div>
              <h3 class="font-semibold text-green-900 dark:text-green-100">Team Allocation</h3>
              <p class="text-xs text-green-700 dark:text-green-300">{{ teamPercentage }}% of raised funds with vesting</p>
            </div>
          </div>
          <div class="text-right">
            <div class="text-lg font-bold text-green-600">{{ teamPercentage.toFixed(1) }}%</div>
            <div class="text-sm text-green-600">{{ formatAmount(teamAmount) }} {{ purchaseTokenSymbol }}</div>
          </div>
        </div>
      </div>

      <!-- Allocation Configuration - Collapsible Content -->
      <div v-show="teamExpanded" class="border-t border-gray-200 dark:border-gray-700">
        <div class="p-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Allocation Percentage *
            </label>
            <div class="relative">
              <input
                v-model.number="teamPercentage"
                type="number"
                min="0"
                :max="maxTeamPercentage"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 pr-16"
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Calculated Amount
            </label>
            <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md">
              {{ formatAmount(teamAmount) }} {{ purchaseTokenSymbol }}
            </div>
          </div>
        </div>

        <!-- Enhanced: Global Vesting Configuration -->
        <div class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
          <div class="flex items-center mb-3">
            <label class="relative inline-flex items-center cursor-pointer mr-3">
              <input
                v-model="teamVestingEnabled"
                type="checkbox"
                class="sr-only peer"
              />
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
            </label>
            <label
              @click="teamVestingEnabled = !teamVestingEnabled"
              class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
            >
              ⭐ Enable Global Vesting Schedule
            </label>
            <HelpTooltip class="text-xs">
              Apply vesting to all team recipients unless individually overridden
            </HelpTooltip>
          </div>

          <VestingScheduleConfig
            v-if="teamVestingEnabled"
            v-model="globalVestingSchedule"
            allocation-name="Team Funds"
            type="funds"
          />
        </div>

        <!-- Enhanced Recipients Management -->
        <div class="mt-4">
          <RecipientManagementV2
            v-if="teamPercentage > 0"
            v-model="teamRecipients"
            title="Team Fund Recipients"
            help-text="Configure principals who will receive team fund allocation. Vesting is managed at allocation level above."
            empty-message="⚠️ At least one team recipient is required for non-zero team allocation"
            allocation-type="funds"
            :total-amount="teamAmount"
            :purchase-token-symbol="purchaseTokenSymbol"
            @add-recipient="addTeamRecipient"
            @remove-recipient="removeTeamRecipient"
          />
        </div>
        </div>
      </div>
    </div>

    <!-- DEX Liquidity Allocation (Collapsible) -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
      <!-- Header - Clickable to toggle -->
      <div
        @click="dexExpanded = !dexExpanded"
        class="p-4 bg-gradient-to-r from-orange-50 to-amber-50 dark:from-orange-900/30 dark:to-amber-900/30 cursor-pointer hover:from-orange-100 hover:to-amber-100 dark:hover:from-orange-900/40 dark:hover:to-amber-900/40 transition-colors"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <ChevronDownIcon
              :class="['h-5 w-5 text-orange-600 transition-transform', dexExpanded ? 'rotate-180' : '']"
            />
            <div class="w-8 h-8 bg-orange-500 rounded-full flex items-center justify-center">
              <span class="text-white text-sm font-bold">🔄</span>
            </div>
            <div>
              <h3 class="font-semibold text-orange-900 dark:text-orange-100">DEX Liquidity Allocation</h3>
              <p class="text-xs text-orange-700 dark:text-orange-300">{{ dexLiquidityPercentage }}% of raised funds for trading</p>
            </div>
          </div>
          <div class="text-right">
            <div class="text-lg font-bold text-orange-600">{{ dexLiquidityPercentage.toFixed(1) }}%</div>
            <div class="text-sm text-orange-600">{{ formatAmount(dexLiquidityAmount) }} {{ purchaseTokenSymbol }}</div>
          </div>
        </div>
      </div>

      <!-- DEX allocation configuration - Collapsible Content -->
      <div v-show="dexExpanded" class="border-t border-gray-200 dark:border-gray-700">
        <div class="p-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <div class="flex items-center justify-between mb-2">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
                Liquidity Percentage *
              </label>
              <div class="flex gap-1">
                <button
                  @click="dexLiquidityPercentage = 25"
                  type="button"
                  class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 border border-gray-300 dark:border-gray-600 rounded"
                  title="Conservative (25%)"
                >
                  25%
                </button>
                <button
                  @click="dexLiquidityPercentage = 30"
                  type="button"
                  class="px-2 py-1 text-xs bg-blue-100 dark:bg-blue-900/40 hover:bg-blue-200 dark:hover:bg-blue-800/60 border border-blue-300 dark:border-blue-700 rounded"
                  title="Balanced (30%)"
                >
                  30%
                </button>
                <button
                  @click="dexLiquidityPercentage = 35"
                  type="button"
                  class="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 border border-gray-300 dark:border-gray-600 rounded"
                  title="Aggressive (35%)"
                >
                  35%
                </button>
              </div>
            </div>
            <div class="relative">
              <input
                v-model.number="dexLiquidityPercentage"
                type="number"
                min="0"
                :max="maxDexLiquidityPercentage"
                step="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 pr-16"
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Calculated Amount
            </label>
            <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md">
              {{ formatAmount(dexLiquidityAmount) }} {{ purchaseTokenSymbol }}
            </div>
          </div>
        </div>

        <!-- Allocation Summary & Validation -->
        <div class="mt-3 space-y-3">
          <!-- Platform Fee Info -->
          <div class="p-3 bg-gray-50 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg">
            <div class="flex items-center justify-between text-sm">
              <span class="text-gray-700 dark:text-gray-300">
                <strong>⚙️ Platform Fee:</strong>
              </span>
              <span class="font-bold text-gray-900 dark:text-gray-100">
                {{ platformFeePercentage }}% ({{ formatAmount(simulatedAmount * platformFeePercentage / 100) }} {{ purchaseTokenSymbol }})
              </span>
            </div>
          </div>

          <!-- Total Allocation Summary -->
          <div class="p-3 rounded-lg" :class="[
            totalRaisedFundsPercentage > 100
              ? 'bg-red-50 dark:bg-red-900/20 border-2 border-red-300 dark:border-red-800'
              : totalRaisedFundsPercentage === 100
                ? 'bg-green-50 dark:bg-green-900/20 border border-green-300 dark:border-green-800'
                : 'bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-300 dark:border-yellow-800'
          ]">
            <div class="flex items-center justify-between mb-2">
              <span class="text-sm font-medium" :class="[
                totalRaisedFundsPercentage > 100 ? 'text-red-800 dark:text-red-200' :
                totalRaisedFundsPercentage === 100 ? 'text-green-800 dark:text-green-200' :
                'text-yellow-800 dark:text-yellow-200'
              ]">
                Total Allocated:
              </span>
              <span class="text-lg font-bold" :class="[
                totalRaisedFundsPercentage > 100 ? 'text-red-900 dark:text-red-100' :
                totalRaisedFundsPercentage === 100 ? 'text-green-900 dark:text-green-100' :
                'text-yellow-900 dark:text-yellow-100'
              ]">
                {{ totalRaisedFundsPercentage.toFixed(1) }}%
              </span>
            </div>

            <div class="text-xs space-y-1" :class="[
              totalRaisedFundsPercentage > 100 ? 'text-red-700 dark:text-red-300' :
              totalRaisedFundsPercentage === 100 ? 'text-green-700 dark:text-green-300' :
              'text-yellow-700 dark:text-yellow-300'
            ]">
              <div class="flex justify-between">
                <span>Team:</span>
                <span>{{ teamPercentage.toFixed(1) }}%</span>
              </div>
              <div class="flex justify-between">
                <span>DEX Liquidity:</span>
                <span>{{ dexLiquidityPercentage.toFixed(1) }}%</span>
              </div>
              <div v-if="totalCustomPercentage > 0" class="flex justify-between">
                <span>Custom Allocations:</span>
                <span>{{ totalCustomPercentage.toFixed(1) }}%</span>
              </div>
              <div class="flex justify-between pt-1 border-t" :class="[
                totalRaisedFundsPercentage > 100 ? 'border-red-300 dark:border-red-700' :
                totalRaisedFundsPercentage === 100 ? 'border-green-300 dark:border-green-700' :
                'border-yellow-300 dark:border-yellow-700'
              ]">
                <span class="font-medium">Remaining:</span>
                <span class="font-bold">{{ (100 - totalRaisedFundsPercentage).toFixed(1) }}%</span>
              </div>
            </div>

            <!-- Validation Messages -->
            <div v-if="totalRaisedFundsPercentage > 100" class="mt-2 pt-2 border-t border-red-300 dark:border-red-700">
              <p class="text-xs font-medium text-red-800 dark:text-red-200">
                ⚠️ <strong>Error:</strong> Total allocation exceeds 100%! Please reduce allocations by {{ (totalRaisedFundsPercentage - 100).toFixed(1) }}%
              </p>
            </div>
            <div v-else-if="totalRaisedFundsPercentage === 100" class="mt-2 pt-2 border-t border-green-300 dark:border-green-700">
              <p class="text-xs font-medium text-green-800 dark:text-green-200">
                ✅ <strong>Perfect!</strong> All raised funds are allocated.
              </p>
            </div>
            <div v-else-if="totalRaisedFundsPercentage < 100" class="mt-2 pt-2 border-t border-yellow-300 dark:border-yellow-700">
              <p class="text-xs font-medium text-yellow-800 dark:text-yellow-200">
                💡 <strong>Note:</strong> {{ (100 - totalRaisedFundsPercentage).toFixed(1) }}% of raised funds is unallocated and will go to DAO Treasury.
              </p>
            </div>
          </div>

          <!-- Recommended Range Info -->
          <div class="p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
            <p class="text-xs font-medium text-blue-800 dark:text-blue-200 mb-1">
              💡 Recommended DEX Liquidity Range: 20-40%
            </p>
            <div class="text-xs text-blue-700 dark:text-blue-300 space-y-1">
              <p>• <strong>20-25%:</strong> Conservative - Good for stable tokens with established community</p>
              <p>• <strong>30-35%:</strong> Balanced - Standard for most launchpads, ensures healthy liquidity</p>
              <p>• <strong>35-40%:</strong> Aggressive - Better price stability but less for team/development</p>
            </div>
            <p class="text-xs text-blue-600 dark:text-blue-400 mt-2">
              <strong>Current:</strong> {{ dexLiquidityPercentage }}%
              <span v-if="dexLiquidityPercentage < 20">(⚠️ Low - May cause high volatility)</span>
              <span v-else-if="dexLiquidityPercentage >= 20 && dexLiquidityPercentage <= 40">(✅ Within recommended range)</span>
              <span v-else>(⚠️ High - Consider team/development needs)</span>
            </p>
          </div>
        </div>
        <p class="text-xs text-gray-500 mt-2">Note: DEX liquidity typically doesn't require vesting as it's used for immediate market making</p>
        </div>
      </div>
    </div>

    <!-- Custom Allocations -->
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Custom Allocations</h3>
        <button
          @click="addCustomAllocation"
          type="button"
          class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-lg text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
        >
          <PlusIcon class="h-4 w-4 mr-2" />
          Add Custom Allocation
        </button>
      </div>

      <div
        v-for="(allocation, index) in customAllocations"
        :key="allocation.id"
        class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4"
      >
        <div class="flex items-center justify-between mb-4">
          <h4 class="font-medium text-gray-900 dark:text-white">{{ allocation.name }}</h4>
          <button
            @click="removeCustomAllocation(index)"
            type="button"
            class="text-red-500 hover:text-red-700 transition-colors"
          >
            <XIcon class="h-4 w-4" />
          </button>
        </div>

        <CustomAllocationForm
          v-model="customAllocations[index]"
          :available-percentage="availableCustomPercentage"
          :purchase-token-symbol="purchaseTokenSymbol"
          :simulated-amount="simulatedAmount"
          @update:total="updateAllocationTotals"
        />
      </div>
    </div>

    <!-- Remaining Funds Display -->
    <div v-if="remainingPercentage > 0" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100">🏛️ DAO Treasury (Remaining)</h3>
          <p class="text-sm text-blue-700 dark:text-blue-300">
            Unallocated funds will go to DAO treasury for community governance
          </p>
        </div>
        <div class="text-right">
          <div class="text-lg font-bold text-blue-600">{{ remainingPercentage.toFixed(1) }}%</div>
          <div class="text-sm text-blue-600">{{ formatAmount(remainingAmount) }} {{ purchaseTokenSymbol }}</div>
        </div>
      </div>
    </div>

    <!-- Validation Summary -->
    <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
        <div>
          <span class="text-gray-500 dark:text-gray-400">Total Allocated:</span>
          <span class="ml-2 font-medium">{{ totalAllocatedPercentage.toFixed(1) }}%</span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Remaining:</span>
          <span class="ml-2 font-medium">{{ remainingPercentage.toFixed(1) }}%</span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Team Recipients:</span>
          <span class="ml-2 font-medium">{{ teamRecipients.length }}</span>
        </div>
        <div>
          <span class="text-gray-500 dark:text-gray-400">Custom Allocations:</span>
          <span class="ml-2 font-medium">{{ customAllocations.length }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { PlusIcon, XIcon, ChevronDownIcon } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

// Component imports
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import VestingScheduleConfig from '@/components/launchpad/VestingScheduleConfig.vue'
import RecipientManagementV2 from './RecipientManagementV2.vue'
import CustomAllocationForm from './CustomAllocationForm.vue'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Collapse states
const teamExpanded = ref(true)
const dexExpanded = ref(true)

// Props - only keep flags and display settings
interface Props {
  enableVesting?: boolean
  enableRecipients?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  enableVesting: true,
  enableRecipients: true
})

// Use composable for data - single source of truth
const launchpadForm = useLaunchpadForm()
const { formData, simulatedAmount: sharedSimulatedAmount, platformFeePercentage } = launchpadForm

// ✅ V2 MIGRATION: Access allocations array
const allocations = computed(() => formData.value?.raisedFundsAllocation?.allocations || [])

// Helper functions to get specific allocations by ID
const getTeamAllocation = computed(() => allocations.value.find(a => a.id === 'team'))
const getDexAllocation = computed(() => allocations.value.find(a => a.id === 'dex_liquidity'))
const getMarketingAllocation = computed(() => allocations.value.find(a => a.id === 'marketing'))
const getCustomAllocations = computed(() => allocations.value.filter(a => !['team', 'marketing', 'dex_liquidity'].includes(a.id)))

// Constants
const DEFAULT_VESTING_SCHEDULE = {
  cliffDays: 180,
  durationDays: 730,
  releaseFrequency: 'monthly' as const,
  immediateRelease: 10  // ✅ RENAMED from immediatePercentage
}

// Get data from composable
const purchaseTokenSymbol = computed(() => {
  const symbol = formData.value?.purchaseToken?.symbol
  return (symbol && typeof symbol === 'string') ? symbol : 'ICP'
})
const softCapAmount = computed(() => Number(formData.value?.saleParams?.softCap) || 0)
const hardCapAmount = computed(() => Number(formData.value?.saleParams?.hardCap) || 0)
const stepSize = computed(() => {
  const diff = hardCapAmount.value - softCapAmount.value
  return diff > 0 ? Math.max(1, Math.floor(diff / 100)) : 1000
})

// Use shared simulatedAmount from composable
const simulatedAmount = sharedSimulatedAmount

const availableAfterFees = computed(() => {
  return simulatedAmount.value * (1 - platformFeePercentage / 100)
})

// ✅ V2: Get allocation data from allocations array
const teamPercentage = computed({
  get: () => getTeamAllocation.value?.percentage || 70,
  set: (val) => {
    const allocation = getTeamAllocation.value
    if (allocation) allocation.percentage = val
  }
})

const dexLiquidityPercentage = computed({
  get: () => getDexAllocation.value?.percentage || 10,
  set: (val) => {
    const allocation = getDexAllocation.value
    if (allocation) allocation.percentage = val
  }
})

const teamRecipients = computed({
  get: () => getTeamAllocation.value?.recipients || [],
  set: (val) => {
    const allocation = getTeamAllocation.value
    if (allocation) allocation.recipients = val
  }
})

// ✅ V2: Custom allocations are now separate items in allocations array
const customAllocations = computed({
  get: () => getCustomAllocations.value,
  set: (val) => {
    // Update logic will be handled in add/remove methods
  }
})

// ✅ V2: Vesting is managed per allocation, not globally
// Team allocation vesting
const teamVestingEnabled = computed({
  get: () => {
    const teamAlloc = getTeamAllocation.value
    if (!teamAlloc) return false
    // Check if any recipient has vesting enabled
    return teamAlloc.recipients.some(r => r.vestingEnabled)
  },
  set: (val) => {
    const teamAlloc = getTeamAllocation.value
    if (!teamAlloc) return
    // Apply vesting to all recipients
    teamAlloc.recipients.forEach(r => {
      r.vestingEnabled = val
      if (val && !r.vestingSchedule) {
        r.vestingSchedule = { ...DEFAULT_VESTING_SCHEDULE }
      }
    })
  }
})

const globalVestingSchedule = computed({
  get: () => {
    // Get vesting schedule from first recipient that has it
    const teamAlloc = getTeamAllocation.value
    if (!teamAlloc || !teamAlloc.recipients.length) return { ...DEFAULT_VESTING_SCHEDULE }
    const firstWithVesting = teamAlloc.recipients.find(r => r.vestingSchedule)
    return firstWithVesting?.vestingSchedule || { ...DEFAULT_VESTING_SCHEDULE }
  },
  set: (val) => {
    // Apply vesting schedule to all recipients that have vesting enabled
    const teamAlloc = getTeamAllocation.value
    if (!teamAlloc) return
    teamAlloc.recipients.forEach(r => {
      if (r.vestingEnabled) {
        r.vestingSchedule = { ...val }
      }
    })
  }
})

const teamAmount = computed(() => (availableAfterFees.value * teamPercentage.value) / 100)
const dexLiquidityAmount = computed(() => (availableAfterFees.value * dexLiquidityPercentage.value) / 100)

const totalCustomPercentage = computed(() => {
  return getCustomAllocations.value.reduce((sum, alloc) => sum + (alloc.percentage || 0), 0)
})

const totalAllocatedPercentage = computed(() => {
  return teamPercentage.value + dexLiquidityPercentage.value + totalCustomPercentage.value
})

const remainingPercentage = computed(() => {
  return Math.max(0, 100 - totalAllocatedPercentage.value)
})

const remainingAmount = computed(() => (availableAfterFees.value * remainingPercentage.value) / 100)

const maxTeamPercentage = computed(() => 100 - dexLiquidityPercentage.value - totalCustomPercentage.value)
const maxDexLiquidityPercentage = computed(() => 100 - teamPercentage.value - totalCustomPercentage.value)

const availableCustomPercentage = computed(() => Math.max(0, 100 - teamPercentage.value - dexLiquidityPercentage.value))

// Total raised funds allocation percentage
const totalRaisedFundsPercentage = computed(() => {
  return teamPercentage.value + dexLiquidityPercentage.value + totalCustomPercentage.value
})

// Initialize simulation amount from composable
watch([softCapAmount, hardCapAmount], ([softCap, hardCap]) => {
  if (simulatedAmount.value === 0 || simulatedAmount.value < softCap || simulatedAmount.value > hardCap) {
    simulatedAmount.value = hardCap
  }
}, { immediate: true })

// ✅ V2: Update allocation amounts when they change
watch([teamAmount, dexLiquidityAmount, remainingAmount], () => {
  const teamAlloc = getTeamAllocation.value
  const dexAlloc = getDexAllocation.value

  if (teamAlloc) {
    teamAlloc.amount = teamAmount.value.toString()
  }
  if (dexAlloc) {
    dexAlloc.amount = dexLiquidityAmount.value.toString()
  }
})

// Methods - no emit needed, composable is reactive!

const addTeamRecipient = () => {
  const currentRecipients = teamRecipients.value
  currentRecipients.push({
    principal: '',
    percentage: 0,
    name: ''
  })
  teamRecipients.value = currentRecipients
}

const removeTeamRecipient = (index: number) => {
  const currentRecipients = teamRecipients.value
  currentRecipients.splice(index, 1)
  teamRecipients.value = currentRecipients
}

// ✅ V2: Add custom allocation to main allocations array
const addCustomAllocation = () => {
  const allAllocations = formData.value.raisedFundsAllocation?.allocations
  if (!allAllocations) return

  allAllocations.push({
    id: `custom_${Date.now()}`,
    name: 'Custom Allocation',
    percentage: 0,
    amount: '0',
    recipients: []
  })
}

// ✅ V2: Remove custom allocation by finding it in main array
const removeCustomAllocation = (index: number) => {
  const allAllocations = formData.value.raisedFundsAllocation?.allocations
  if (!allAllocations) return

  const customAllocs = getCustomAllocations.value
  const toRemove = customAllocs[index]
  if (!toRemove) return

  const mainIndex = allAllocations.findIndex(a => a.id === toRemove.id)
  if (mainIndex !== -1) {
    allAllocations.splice(mainIndex, 1)
  }
}

const updateAllocationTotals = () => {
  // Composable is reactive, no need to do anything
}

// Enforce max percentage constraints
watch(dexLiquidityPercentage, (newVal, oldVal) => {
  if (newVal > maxDexLiquidityPercentage.value) {
    dexLiquidityPercentage.value = maxDexLiquidityPercentage.value
    toast.warning('DEX Liquidity percentage adjusted', {
      description: `Maximum allowed is ${maxDexLiquidityPercentage.value.toFixed(1)}% based on other allocations`
    })
  }
  if (newVal < 0) {
    dexLiquidityPercentage.value = 0
    toast.error('Invalid percentage', {
      description: 'Percentage cannot be negative'
    })
  }
})

watch(teamPercentage, (newVal, oldVal) => {
  if (newVal > maxTeamPercentage.value) {
    teamPercentage.value = maxTeamPercentage.value
    toast.warning('Team percentage adjusted', {
      description: `Maximum allowed is ${maxTeamPercentage.value.toFixed(1)}% based on other allocations`
    })
  }
  if (newVal < 0) {
    teamPercentage.value = 0
    toast.error('Invalid percentage', {
      description: 'Percentage cannot be negative'
    })
  }
})

// Vesting is now managed at allocation level, not per-recipient
// Recipients automatically inherit vesting from their parent allocation (Team/Custom)

const formatNumber = (num: number | string) => {
  return Number(num).toLocaleString()
}

const formatAmount = (amount: number) => {
  return formatNumber(amount.toFixed(2))
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

.dark .slider::-webkit-slider-track {
  background: linear-gradient(to right, #451A03 0%, #F59E0B 100%);
}

.dark .slider::-moz-range-track {
  background: linear-gradient(to right, #451A03 0%, #F59E0B 100%);
}
</style>