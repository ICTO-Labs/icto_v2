<template>
  <div class="space-y-6">
    <!-- Main Header -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-700 p-6">
      <div class="flex items-center justify-between mb-4">
        <h2 class="text-xl font-bold text-gray-900 dark:text-white">💰 Raised Funds Allocation</h2>
        <div class="text-sm text-gray-600 dark:text-gray-400">
          Industry Standard: PinkSale Style
        </div>
      </div>

      <!-- Simulation Slider -->
      <div class="mb-6">
        <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
          📊 Raised Funds Simulation:
          <span class="text-lg font-bold text-blue-600">{{ formatAmount(currentRaisedAmount) }} ICP</span>
          <HelpTooltip>Adjust slider to simulate different funding scenarios and see how allocations change.</HelpTooltip>
        </label>
        <input
          v-model.number="currentRaisedAmount"
          type="range"
          :min="softCapNumber"
          :max="hardCapNumber"
          :step="stepSize"
          class="w-full h-3 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
        />
        <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-2">
          <span>Soft Cap: {{ formatAmount(softCapNumber) }} ICP</span>
          <span>Hard Cap: {{ formatAmount(hardCapNumber) }} ICP</span>
        </div>
      </div>

      <!-- Available Funds Summary -->
      <div class="bg-white dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-600">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div>
            <span class="text-gray-600 dark:text-gray-400">Total Raised:</span>
            <span class="font-bold text-gray-900 dark:text-white">{{ formatAmount(currentRaisedAmount) }} ICP</span>
          </div>
          <div>
            <span class="text-gray-600 dark:text-gray-400">Platform Fee ({{ platformFeeRate }}%):</span>
            <span class="font-bold text-red-600">-{{ formatAmount(platformFee) }} ICP</span>
          </div>
          <div>
            <span class="text-gray-600 dark:text-gray-400">Available for Allocation:</span>
            <span class="font-bold text-green-600">{{ formatAmount(availableForAllocation) }} ICP</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Allocation Sections Container -->
    <div class="space-y-4">
      <!-- Team Allocation Section -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="p-4 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/30 dark:to-emerald-900/30">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-green-500 rounded-full flex items-center justify-center">
                <span class="text-white text-sm font-bold">👥</span>
              </div>
              <div>
                <h3 class="font-semibold text-green-900 dark:text-green-100">Team Allocation</h3>
                <p class="text-xs text-green-700 dark:text-green-300">Team compensation and operations</p>
              </div>
            </div>
            <div class="text-right">
              <div class="text-lg font-bold text-green-600">{{ teamPercentage.toFixed(1) }}%</div>
              <div class="text-sm text-green-600">{{ formatAmount(teamAmount) }} ICP</div>
            </div>
          </div>
        </div>

        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Allocation Percentage *
              </label>
              <div class="relative">
                <input
                  type="number"
                  v-model.number="teamPercentage"
                  min="0"
                  :max="maxTeamPercentage"
                  step="1"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 pr-16"
                />
                <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Calculated Amount
              </label>
              <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md">
                {{ formatAmount(teamAmount) }} ICP
              </div>
            </div>
          </div>

          <!-- Team Recipients -->
          <RecipientManagement
            v-if="teamPercentage > 0"
            title="Team Recipients"
            :recipients="teamRecipients"
            help-text="Configure principals who will receive team allocation. Each recipient will have the same vesting schedule configured above."
            empty-message="⚠️ At least one team recipient is required for non-zero team allocation"
            @add-recipient="addTeamRecipient"
            @remove-recipient="removeTeamRecipient"
          />
        </div>
      </div>

      <!-- DEX Liquidity Allocation Section -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="p-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/30 dark:to-indigo-900/30">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                <span class="text-white text-sm font-bold">🚀</span>
              </div>
              <div>
                <h3 class="font-semibold text-blue-900 dark:text-blue-100">DEX Liquidity Allocation</h3>
                <p class="text-xs text-blue-700 dark:text-blue-300">Automatic DEX listing liquidity</p>
              </div>
            </div>
            <div class="text-right">
              <div class="text-lg font-bold text-blue-600">{{ lpRaisedPercentage.toFixed(1) }}%</div>
              <div class="text-sm text-blue-600">{{ formatAmount(calculatedIcpAmount) }} ICP</div>
            </div>
          </div>
        </div>

        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Liquidity Percentage *
                <HelpTooltip>Percentage of raised funds for DEX liquidity (industry standard: 10-15%)</HelpTooltip>
              </label>
              <div class="relative">
                <input
                  type="number"
                  v-model.number="lpRaisedPercentage"
                  min="5"
                  max="30"
                  step="1"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 pr-16"
                />
                <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
              </div>
              <p class="text-xs text-gray-500 mt-1">{{ formatTokenAmount(calculatedTokenFromRaised) }} tokens for liquidity</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Calculated Amount
              </label>
              <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md">
                {{ formatAmount(calculatedIcpAmount) }} ICP
              </div>
              <p class="text-xs text-gray-500 mt-1">{{ calculatedTokenFromRaised.toLocaleString() }} tokens</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Marketing Allocation Section -->
      <div v-for="allocation in validCustomAllocations" :key="allocation.id"
           class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="p-4 bg-gradient-to-r from-purple-50 to-pink-50 dark:from-purple-900/30 dark:to-pink-900/30">
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-purple-500 rounded-full flex items-center justify-center">
                <span class="text-white text-sm font-bold">📢</span>
              </div>
              <div>
                <h3 class="font-semibold text-purple-900 dark:text-purple-100">{{ allocation.name }} Allocation</h3>
                <p class="text-xs text-purple-700 dark:text-purple-300">Custom allocation category</p>
              </div>
            </div>
            <div class="text-right">
              <div class="text-lg font-bold text-purple-600">{{ allocation.percentage.toFixed(1) }}%</div>
              <div class="text-sm text-purple-600">{{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP</div>
            </div>
          </div>
        </div>

        <div class="p-4 border-t border-gray-200 dark:border-gray-700">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Allocation Percentage *
              </label>
              <div class="relative">
                <input
                  type="number"
                  v-model.number="allocation.percentage"
                  min="0"
                  max="100"
                  step="1"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 pr-16"
                />
                <span class="absolute right-3 top-2.5 text-sm text-gray-500">%</span>
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Calculated Amount
              </label>
              <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md">
                {{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP
              </div>
            </div>
          </div>

          <!-- Custom Allocation Recipients -->
          <div v-if="allocation.percentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
            <RecipientManagement
              :title="`${allocation.name} Recipients`"
              :recipients="allocation.recipients"
              :help-text="`Configure principals who will receive ${allocation.name} allocation.`"
              :empty-message="`⚠️ At least one ${allocation.name.toLowerCase()} recipient is required for non-zero allocation`"
              @add-recipient="() => addCustomAllocationRecipient(allocation.id)"
              @remove-recipient="(index) => removeCustomAllocationRecipient(allocation.id, index)"
            />
          </div>
        </div>
      </div>

      <!-- Add Custom Allocation Button -->
      <div class="flex justify-center">
        <button
          @click="addCustomAllocation"
          type="button"
          :disabled="remainingAvailablePercentage <= 0"
          class="px-4 py-2 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg text-sm font-medium text-gray-700 dark:text-gray-300 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          + Add Custom Allocation
        </button>
      </div>

      <!-- Allocation Error Alert -->
      <div v-if="isOverAllocated" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
        <div class="flex items-start">
          <AlertTriangleIcon class="h-5 w-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
          <div>
            <h4 class="text-sm font-medium text-red-800 dark:text-red-200">⚠️ Allocation Error</h4>
            <p class="text-sm text-red-700 dark:text-red-300 mt-1">{{ allocationError }}</p>
            <div class="mt-2 text-xs text-red-600 dark:text-red-400">
              <div>Team: {{ teamPercentage.toFixed(1) }}%</div>
              <div>DEX Liquidity: {{ lpRaisedPercentage.toFixed(1) }}%</div>
              <div v-for="allocation in validCustomAllocations" :key="allocation.id">
                {{ allocation.name }}: {{ allocation.percentage.toFixed(1) }}%
              </div>
              <div class="font-semibold mt-1 pt-1 border-t border-red-300 dark:border-red-700">
                Total: {{ totalUsedPercentage.toFixed(1) }}% (must be ≤ 100%)
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Remaining Available Info -->
      <div v-else class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <span class="text-sm font-medium text-green-800 dark:text-green-200">✓ Available for allocation:</span>
            <span class="ml-2 text-sm font-bold text-green-600">{{ remainingAvailablePercentage.toFixed(1) }}%</span>
          </div>
          <div class="text-xs text-green-600 dark:text-green-400">
            ({{ formatAmount(remainingAvailablePercentage * currentRaisedAmount / 100) }} ICP)
          </div>
        </div>
      </div>

      <!-- DEX Configuration (Simplified - only shown when DEX > 0%) -->
      <div v-if="lpRaisedPercentage > 0" class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div class="p-4 bg-gradient-to-r from-orange-50 to-amber-50 dark:from-orange-900/30 dark:to-amber-900/30">
          <h3 class="font-semibold text-orange-900 dark:text-orange-100">🔧 DEX Configuration</h3>
          <p class="text-xs text-orange-700 dark:text-orange-300 mt-1">Liquidity lock and platform settings</p>
        </div>

        <div class="p-4 border-t border-gray-200 dark:border-gray-700 space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Liquidity Lock Duration *
              <HelpTooltip>How long to lock liquidity tokens after listing (industry standard: 180-365 days)</HelpTooltip>
            </label>
            <Select
              v-model="dexConfig.liquidityLockDays"
              :options="[
                { value: 30, label: '30 days' },
                { value: 90, label: '90 days' },
                { value: 180, label: '180 days (recommended)' },
                { value: 365, label: '365 days' },
                { value: 730, label: '730 days (2 years)' }
              ]"
              placeholder="Select lock duration"
            />
          </div>

          <!-- Platform Selection -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Add DEX Platform *
              <HelpTooltip>Add multiple DEX platforms for automatic listing and liquidity provision</HelpTooltip>
            </label>
            <div class="flex space-x-2">
              <Select
                v-model="selectedDexToAdd"
                :options="availableDexOptions"
                placeholder="Select DEX platform"
                :disabled="availableDexOptions.length === 0"
              />
              <button
                @click="addDexPlatform(selectedDexToAdd)"
                :disabled="!selectedDexToAdd"
                class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Add
              </button>
            </div>
          </div>

          <!-- DEX Platforms List -->
          <div v-if="availableDexs.length > 0" class="space-y-3 mt-4">
            <div class="text-sm font-medium text-gray-700 dark:text-gray-300">Configured DEX Platforms</div>

            <div v-for="(dex, index) in availableDexs" :key="dex.id" class="border border-gray-200 dark:border-gray-600 rounded-lg p-4">
              <div class="flex items-center justify-between mb-3">
                <div class="flex items-center space-x-3">
                  <div class="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center">
                    <span class="text-blue-600 dark:text-blue-400 text-sm">{{ dex.name.charAt(0) }}</span>
                  </div>
                  <div>
                    <h4 class="font-medium text-gray-900 dark:text-white">{{ dex.name }}</h4>
                    <p class="text-xs text-gray-500 dark:text-gray-400">{{ dex.description }}</p>
                  </div>
                </div>
                <button
                  @click="removeDexPlatform(index)"
                  class="text-red-500 hover:text-red-700 dark:text-red-400 dark:hover:text-red-300"
                >
                  Remove
                </button>
              </div>

              <!-- DEX Configuration -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Liquidity Percentage
                  </label>
                  <input
                    type="number"
                    v-model.number="dex.liquidityPercentage"
                    min="0"
                    max="100"
                    step="1"
                    class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800"
                  />
                </div>

                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Allocation Type
                  </label>
                  <div class="space-y-2">
                    <label class="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        v-model="dex.enableTokenLiquidity"
                        class="rounded text-blue-600"
                      />
                      <span class="text-sm">Token Liquidity</span>
                    </label>
                    <label class="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        v-model="dex.enablePurchaseLiquidity"
                        class="rounded text-blue-600"
                      />
                      <span class="text-sm">Purchase Liquidity</span>
                    </label>
                  </div>
                </div>
              </div>

              <div class="mt-3 text-xs text-gray-500 dark:text-gray-400">
                Calculated:
                {{ dex.enableTokenLiquidity ? formatTokenAmount(dex.calculatedTokenLiquidity) + ' tokens' : 'No token liquidity' }},
                {{ dex.enablePurchaseLiquidity ? formatAmount(dex.calculatedPurchaseLiquidity) + ' ICP' : 'No purchase liquidity' }}
              </div>
            </div>

            <!-- DEX Actions -->
            <div class="flex space-x-2 pt-2">
              <button
                @click="redistributeDexAllocations"
                class="px-3 py-1 bg-gray-600 text-white text-sm rounded hover:bg-gray-700"
              >
                Redistribute Equally
              </button>
            </div>
          </div>

          <!-- LP Lock Settings -->
          <div>
            <label class="flex items-center">
              <input
                type="checkbox"
                v-model="lpLockEnabled"
                class="mr-2"
              />
              <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                Enable LP Token Lock *
                <HelpTooltip>Lock LP tokens to prevent early withdrawal and build trust</HelpTooltip>
              </span>
            </label>
          </div>

          <!-- LP Token Recipient -->
          <div v-if="lpLockEnabled">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              LP Token Recipient *
              <HelpTooltip>Principal ID that will receive the LP tokens (usually the project treasury)</HelpTooltip>
            </label>
            <div class="flex gap-2">
              <input
                type="text"
                v-model="dexConfig.lpTokenRecipient"
                placeholder="Principal ID (e.g., aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa)"
                class="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800"
              />
              <button
                @click="copylpTokenRecipient"
                type="button"
                class="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
              >
                Copy
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary Section -->
    <div class="bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-900 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">📊 Allocation Summary</h3>

      <div class="space-y-3 mb-4">
        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Team Allocation:</span>
          <span class="font-medium text-green-600">{{ teamPercentage.toFixed(1) }}% ({{ formatAmount(teamAmount) }} ICP)</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">DEX Liquidity:</span>
          <span class="font-medium text-blue-600">{{ lpRaisedPercentage.toFixed(1) }}% ({{ formatAmount(calculatedIcpAmount) }} ICP)</span>
        </div>
        <div v-for="allocation in validCustomAllocations" :key="allocation.id" class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">{{ allocation.name }}:</span>
          <span class="font-medium text-purple-600">{{ allocation.percentage.toFixed(1) }}% ({{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP)</span>
        </div>
      </div>

      <div class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-2">
          <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Total Allocated:</span>
          <span class="font-bold text-lg">{{ totalAllocationPercentageWithDex.toFixed(1) }}%</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-3">
          <div
            class="bg-gradient-to-r from-green-500 to-blue-500 h-3 rounded-full transition-all duration-300"
            :style="{ width: `${Math.min(totalAllocationPercentageWithDex, 100)}%` }"
          ></div>
        </div>
        <div class="flex justify-between text-sm mt-2">
          <span class="text-gray-600 dark:text-gray-400">Remaining to Treasury:</span>
          <span class="font-medium text-green-600">{{ remainingPercentageWithDex.toFixed(1) }}% ({{ formatAmount(remainingAmountWithDex) }} ICP)</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, onMounted } from 'vue'
import { AlertTriangleIcon, ChevronDown } from 'lucide-vue-next'
import NumberInput from '@/components/common/NumberInput.vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import VestingScheduleConfig from './VestingScheduleConfig.vue'
import RecipientManagement from './RecipientManagement.vue'
import Select from '@/components/common/Select.vue'
import { InputMask } from '@/utils/inputMask'
import { useUniqueId } from '@/composables/useUniqueId'
import { useAuthStore } from '@/stores/auth'
import { toast } from 'vue-sonner'

const props = defineProps({
  softCap: {
    type: String,
    required: true
  },
  hardCap: {
    type: String,
    required: true
  },
  platformFeeRate: {
    type: Number,
    default: 2.0
  },
  dexLiquidityRequired: {
    type: Number,
    default: 0
  },
  saleTokenAllocation: {
    type: [String, Number],
    default: 0
  },
  tokenSymbol: {
    type: String,
    default: 'TOK'
  },
  purchaseSymbol: {
    type: String,
    default: 'ICP'
  },
  modelValue: {
    type: Object,
    required: true
  },
  totalSupply: {
    type: String,
    required: true
  },
  totalSaleAmount: {
    type: String,
    required: true
  },
  simulatedRaisedAmount: {
    type: String,
    default: '0'
  }
})

const emit = defineEmits(['update:modelValue', 'update:dexConfig'])

// Auth store for principal access
const authStore = useAuthStore()

// Unique ID for form elements
const autoListMainId = useUniqueId('auto-list-main')
const lpLockId = useUniqueId('lp-lock')

// LP Lock state
const lpLockEnabled = ref(true)

// DEX selection state
const selectedDexToAdd = ref('')

// Accordion state for raised funds allocation sections
const openRaisedFundsAccordions = ref({
  team: true  // Team section open by default
})

// All available DEX platforms (including disabled ones)
const allDexPlatforms = [
  { id: 'icpswap', name: 'ICPSwap', description: 'Leading DEX on Internet Computer', logo: 'https://app.icpswap.com/static/media/logo-dark.7b8c12091e650c40c5e9f561c57473ba.svg' },
  { id: 'sonic', name: 'Sonic DEX', description: 'High-speed AMM on Internet Computer', logo: 'SonicLogo' },
  { id: 'kongswap', name: 'Kong Swap', description: 'Community-driven DEX', logo: '🦍' },
  { id: 'icdex', name: 'ICDex', description: 'Order book DEX', logo: '📊' }
]

// Available DEXs array (originally from props in MultiDEXConfiguration)
const availableDexs = ref([])

// LP Allocation Method State
const lpAllocationMethod = ref('raised-funds') // Simplified to industry standard
const lpTokenPercentage = ref(30)
const lpRaisedPercentage = ref(10) // Industry standard: 10% for liquidity

// Team allocation state
const teamPercentage = ref(70) // Industry standard: 70% for team
const teamRecipients = ref([])
const teamVestingSchedule = ref(null)
const teamVestingEnabled = ref(true) // Team should have vesting by default

// Custom allocations state
const customAllocations = ref([])

// DEX configuration state
const dexConfig = ref({
  autoList: true,
  liquidityPercentage: 10,
  liquidityLockDays: 180,
  platform: 'icpswap',
  lpTokenRecipient: ''
})

// State management
const isUpdatingFromProps = ref(false)
const emitTimeout = ref(null)

// Token symbols from props
const saleTokenSymbol = computed(() => props.tokenSymbol)
const purchaseTokenSymbol = computed(() => props.purchaseSymbol)

// Sale token allocation as number
const saleTokenAllocationNumber = computed(() => {
  const value = parseFloat(props.saleTokenAllocation)
  return isNaN(value) || value <= 0 ? 1000000 : value
})

// Dynamic listing price calculation: Raised Amount ÷ Sale Token Allocation
const dynamicListingPrice = computed(() => {
  if (saleTokenAllocationNumber.value <= 0) return 0
  return currentRaisedAmount.value / saleTokenAllocationNumber.value
})


// Convert caps to numbers for calculations
const softCapNumber = computed(() => {
  const value = parseFloat(props.softCap)
  return isNaN(value) || value <= 0 ? 1000 : value
})


const hardCapNumber = computed(() => {
  const value = parseFloat(props.hardCap)
  return isNaN(value) || value <= 0 ? 100000 : value
})

const stepSize = computed(() => {
  const diff = hardCapNumber.value - softCapNumber.value
  return diff > 0 ? diff / 100 : 1000
})

// Raised funds simulation - initialize with a default value first
const currentRaisedAmount = ref(1000)

// LP Allocation Calculated Values
const calculatedTokenAmount = computed(() => {
  const totalSupplyValue = parseFloat(props.totalSupply) || 0
  const result = (totalSupplyValue * lpTokenPercentage.value) / 100
  console.log('calculatedTokenAmount:', {
    totalSupply: props.totalSupply,
    totalSupplyValue,
    lpTokenPercentage: lpTokenPercentage.value,
    result
  })
  return result
})

const calculatedIcpAmount = computed(() => {
  const simulatedValue = parseFloat(props.simulatedRaisedAmount) || 0
  const result = (simulatedValue * lpRaisedPercentage.value) / 100
  console.log('calculatedIcpAmount:', {
    simulatedRaisedAmount: props.simulatedRaisedAmount,
    simulatedValue,
    lpRaisedPercentage: lpRaisedPercentage.value,
    result
  })
  return result
})

const calculatedTokenFromRaised = computed(() => {
  const icpAmount = calculatedIcpAmount.value
  const tokenPrice = dynamicListingPrice.value
  return tokenPrice > 0 ? icpAmount / tokenPrice : 0
})
  const estimatedIcpNeeded = computed(() => {
  const tokenAmount = calculatedTokenAmount.value
  const tokenPrice = dynamicListingPrice.value
  return tokenAmount * tokenPrice
})

// Platform fee calculation
const platformFee = computed(() => currentRaisedAmount.value * (props.platformFeeRate / 100))

// DEX Liquidity calculation based on percentage and auto listing setting
const calculatedDexLiquidity = computed(() => {
  if (!dexConfig.value.autoList) return 0
  const percentage = Number(dexConfig.value.liquidityPercentage) || 0
  return currentRaisedAmount.value * (percentage / 100)
})

const dexLiquidityFee = computed(() => calculatedDexLiquidity.value)
const availableForAllocation = computed(() => currentRaisedAmount.value - platformFee.value)

const teamAmount = computed(() => currentRaisedAmount.value * (teamPercentage.value / 100))

// Calculate allocation amount for any percentage
const calculateAllocationAmount = (percentage) => {
  return currentRaisedAmount.value * (percentage / 100)
}

// Custom allocations
const validCustomAllocations = computed(() => {
  return customAllocations.value.filter(allocation =>
    allocation &&
    allocation.id &&
    allocation.percentage > 0
  )
})

const totalCustomPercentage = computed(() => {
  return customAllocations.value.reduce((sum, allocation) => sum + (allocation?.percentage || 0), 0)
})

const totalCustomAmount = computed(() => {
  return customAllocations.value.reduce((sum, allocation) => sum + calculateAllocationAmount(allocation?.percentage || 0), 0)
})

// DEX liquidity percentage calculation
const dexLiquidityPercentage = computed(() => {
  if (!dexConfig.value.autoList) return 0
  return Number(dexConfig.value.liquidityPercentage) || 0
})

// Calculate maximum available percentage for DEX liquidity allocation
const maxDexLiquidityPercentage = computed(() => {
  const usedByTeam = teamPercentage.value
  const usedByCustom = totalCustomPercentage.value
  const platformFeePercentage = props.platformFeeRate || 0
  return Math.max(0, 100 - platformFeePercentage - usedByTeam - usedByCustom)
})

// Calculate maximum available percentage for team allocation
const maxTeamPercentage = computed(() => {
  const usedByDex = dexLiquidityPercentage.value
  const usedByCustom = totalCustomPercentage.value
  const platformFeePercentage = props.platformFeeRate || 0
  return Math.max(0, 100 - platformFeePercentage - usedByDex - usedByCustom)
})

// Allocation totals
const totalAllocationPercentage = computed(() => teamPercentage.value + totalCustomPercentage.value)
const totalAllocationAmount = computed(() => teamAmount.value + totalCustomAmount.value)
const remainingPercentage = computed(() => {
  const platformFeePercentage = props.platformFeeRate || 0
  const usedByDex = dexLiquidityPercentage.value
  return Math.max(0, 100 - platformFeePercentage - usedByDex - totalAllocationPercentage.value)
})
const remainingAmount = computed(() => availableForAllocation.value - calculatedDexLiquidity.value - totalAllocationAmount.value)

// Overall totals INCLUDING DEX for display purposes
const totalAllocationPercentageWithDex = computed(() => {
  return dexLiquidityPercentage.value + totalAllocationPercentage.value
})
const totalAllocationAmountWithDex = computed(() => {
  return calculatedDexLiquidity.value + totalAllocationAmount.value
})
const remainingPercentageWithDex = computed(() => {
  const platformFeePercentage = props.platformFeeRate || 0
  return Math.max(0, 100 - platformFeePercentage - totalAllocationPercentageWithDex.value)
})
const remainingAmountWithDex = computed(() => {
  return (currentRaisedAmount.value - platformFee.value) - totalAllocationAmountWithDex.value
})

// Format amount for display
const formatAmount = (amount) => {
  const num = Number(amount)
  if (isNaN(num)) return '0'
  return num.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 4
  })
}

// Validation helpers
const isValidPrincipal = (principal) => {
  if (!principal || typeof principal !== 'string') return false

  // Basic principal format validation
  // Principals should be in format: "aaaaa-bbbbb-ccccc-ddddd-eeeeee"
  const principalRegex = /^[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{5}-[a-z0-9]{6}$/i
  return principalRegex.test(principal.trim())
}

// Format token amount for display
const formatTokenAmount = (amount) => {
  const num = Number(amount)
  if (isNaN(num)) return '0'
  return num.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2
  })
}

// Helper functions
const generateAllocationId = () => {
  return Date.now().toString(36) + Math.random().toString(36).substr(2)
}

const updateLpTokenPercentage = () => {
  // For raised funds method, token percentage is calculated automatically
  if (lpAllocationMethod.value === 'raised-funds') {
    const raisedAmount = parseFloat(props.simulatedRaisedAmount) || 0
    const tokenAmount = calculatedTokenFromRaised.value
    if (raisedAmount > 0 && tokenAmount > 0) {
      // Calculate what percentage of total tokens this represents
      const totalTokens = parseFloat(props.totalSupply) || 1
      lpTokenPercentage.value = (tokenAmount / totalTokens) * 100
    }
  }
}

const updateLpRaisedPercentage = () => {
  // For token supply method, raised percentage is calculated automatically
  if (lpAllocationMethod.value === 'token-supply') {
    const tokenAmount = calculatedTokenAmount.value
    const raisedAmount = estimatedIcpNeeded.value
    if (tokenAmount > 0 && raisedAmount > 0) {
      const totalRaised = parseFloat(props.simulatedRaisedAmount) || 1
      lpRaisedPercentage.value = (raisedAmount / totalRaised) * 100
    }
  }
}

// Emit DEX configuration changes to parent
const emitDexConfig = () => {
  // Skip if we're updating from props to prevent recursive loop
  if (isUpdatingFromProps) return

  emit('update:dexConfig', {
    lpAllocationMethod: lpAllocationMethod.value,
    lpTokenPercentage: lpTokenPercentage.value,
    lpRaisedPercentage: lpRaisedPercentage.value,
    availableDexs: availableDexs.value,
    ...dexConfig.value
  })
}

// Watch for changes and emit to parent (with debouncing)
watch([teamPercentage, currentRaisedAmount, teamRecipients, teamVestingSchedule, customAllocations, dexConfig, availableDexs], () => {
  // Skip if we're updating from props to prevent recursive loop
  if (isUpdatingFromProps) return

  // Debounce the emit to avoid too many updates
  clearTimeout(emitTimeout.value)
  emitTimeout.value = setTimeout(() => {
    const allocationData = {
      teamPercentage: teamPercentage.value,
      teamRecipients: teamRecipients.value,
      teamVestingSchedule: teamVestingSchedule.value,
      teamVestingEnabled: teamVestingEnabled.value,
      customAllocations: customAllocations.value,
      raisedAmount: currentRaisedAmount.value
    }
    emit('update:modelValue', allocationData)
  }, 100) // 100ms debounce
}, { deep: true })

// Watch DEX config changes
watch(dexConfig, () => {
  emitDexConfig()
}, { deep: true })

// DEX Management Functions
const addDexPlatform = (value) => {
  const platform = allDexPlatforms.find(p => p.id === value)
  if (platform) {
    availableDexs.value.push({
      ...platform,
      enabled: true,
      allocationPercentage: 0,
      liquidityPercentage: 0,
      enableTokenLiquidity: true,
      enablePurchaseLiquidity: true,
      calculatedPurchaseLiquidity: 0,
      calculatedTokenLiquidity: 0,
      fees: {
        listing: 0,
        liquidity: 0
      }
    })
    selectedDexToAdd.value = ''

    // Auto-redistribute when adding new DEX
    redistributeDexAllocations()
  }
}

const removeDexPlatform = (index) => {
  availableDexs.value.splice(index, 1)

  // Auto-redistribute when removing DEX
  if (availableDexs.value.length > 0) {
    redistributeDexAllocations()
  }
}

const updateDexPlatform = (index, field, value) => {
  if (availableDexs.value[index]) {
    availableDexs.value[index][field] = value

    // Auto-calculate percentages based on liquidity settings
    const dex = availableDexs.value[index]
    if (dex.enableTokenLiquidity && dex.enablePurchaseLiquidity) {
      // Both enabled - split equally
      dex.allocationPercentage = parseFloat(dex.liquidityPercentage) || 0
    } else if (dex.enableTokenLiquidity || dex.enablePurchaseLiquidity) {
      // Only one enabled - use full percentage
      dex.allocationPercentage = parseFloat(dex.liquidityPercentage) || 0
    } else {
      // Neither enabled - set to 0
      dex.allocationPercentage = 0
    }

    recalculateDexLiquidity()
  }
}

const recalculateDexLiquidity = () => {
  const totalLiquidity = calculatedIcpAmount.value
  const enabledDexs = availableDexs.value.filter(dex => dex.enabled)

  if (enabledDexs.length === 0) return

  // Calculate liquidity distribution
  const totalPercentage = enabledDexs.reduce((sum, dex) => sum + (dex.allocationPercentage || 0), 0)

  enabledDexs.forEach(dex => {
    const percentage = totalPercentage > 0 ? (dex.allocationPercentage || 0) / totalPercentage : 0
    const liquidityAmount = totalLiquidity * percentage

    if (dex.enableTokenLiquidity && dex.enablePurchaseLiquidity) {
      // Split equally between token and purchase liquidity
      dex.calculatedTokenLiquidity = liquidityAmount / 2
      dex.calculatedPurchaseLiquidity = liquidityAmount / 2
    } else if (dex.enableTokenLiquidity) {
      // All to token liquidity
      dex.calculatedTokenLiquidity = liquidityAmount
      dex.calculatedPurchaseLiquidity = 0
    } else if (dex.enablePurchaseLiquidity) {
      // All to purchase liquidity
      dex.calculatedTokenLiquidity = 0
      dex.calculatedPurchaseLiquidity = liquidityAmount
    } else {
      // Neither enabled
      dex.calculatedTokenLiquidity = 0
      dex.calculatedPurchaseLiquidity = 0
    }
  })
}

const redistributeDexAllocations = () => {
  const totalPercentage = 100
  const enabledDexs = availableDexs.value.filter(dex => dex.enabled)

  if (enabledDexs.length === 0) return

  // Distribute equally
  const equalPercentage = totalPercentage / enabledDexs.length
  enabledDexs.forEach(dex => {
    dex.allocationPercentage = equalPercentage
    dex.liquidityPercentage = equalPercentage
  })

  recalculateDexLiquidity()
}

const toggleAutoListing = () => {
  if (!dexConfig.value.autoList) {
    // Reset DEX allocations when auto-listing is disabled
    availableDexs.value = []
  } else {
    // Initialize with ICPSwap when auto-listing is enabled
    addDexPlatform('icpswap')
  }
}

const copylpTokenRecipient = async () => {
  try {
    await navigator.clipboard.writeText(dexConfig.value.lpTokenRecipient)
    toast.success('LP Token Recipient copied to clipboard')
  } catch (err) {
    console.error('Failed to copy text: ', err)
    toast.error('Failed to copy to clipboard')
  }
}

// Team management functions
const createDefaultRecipient = () => ({
  principal: '',
  percentage: 0,
  name: ''
})

const addTeamRecipient = () => {
  teamRecipients.value.push(createDefaultRecipient())
}

const removeTeamRecipient = (index) => {
  teamRecipients.value.splice(index, 1)
}

// Custom allocation management functions
const addCustomAllocation = () => {
  const newAllocation = {
    id: generateAllocationId(),
    name: '',
    percentage: 0,
    vestingEnabled: false,
    vestingSchedule: null,
    recipients: []
  }
  customAllocations.value.push(newAllocation)
}

const removeCustomAllocation = (allocationId) => {
  const index = customAllocations.value.findIndex(a => a.id === allocationId)
  if (index !== -1) {
    customAllocations.value.splice(index, 1)
  }
}

const addCustomAllocationRecipient = (allocationId) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.push(createDefaultRecipient())
  }
}

const removeCustomAllocationRecipient = (allocationId, recipientIndex) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.splice(recipientIndex, 1)
  }
}

const getRecipientAmount = (percentage, totalAmount) => {
  return (totalAmount * percentage) / 100
}

const getMaxCustomAllocationPercentage = (allocationId) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (!allocation) return 100

  const usedByOthers = totalCustomPercentage.value - allocation.percentage
  const available = maxTeamPercentage.value - usedByOthers
  return Math.max(0, available)
}

const getCustomAllocationRecipientsTotalPercentage = (allocationId) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (!allocation || !allocation.recipients) return 0

  return allocation.recipients.reduce((sum, recipient) => sum + (recipient.percentage || 0), 0)
}

// Calculate team recipients total percentage
const teamRecipientsTotalPercentage = computed(() => {
  return teamRecipients.value.reduce((sum, recipient) => sum + (recipient.percentage || 0), 0)
})

// Toggle accordion for allocation sections
const toggleRaisedFundsAccordion = (allocationId) => {
  openRaisedFundsAccordions.value[allocationId] = !openRaisedFundsAccordions.value[allocationId]
}

// Validation computed properties
const totalUsedPercentage = computed(() => {
  return teamPercentage.value + lpRaisedPercentage.value + totalCustomPercentage.value
})

const isOverAllocated = computed(() => {
  return totalUsedPercentage.value > 100
})

const allocationError = computed(() => {
  if (isOverAllocated.value) {
    return `Total allocation (${totalUsedPercentage.value.toFixed(1)}%) exceeds 100%. Please reduce some allocations.`
  }
  return ''
})

const remainingAvailablePercentage = computed(() => {
  return Math.max(0, 100 - teamPercentage.value - lpRaisedPercentage.value - totalCustomPercentage.value)
})

// Update max values based on remaining percentage
watch([teamPercentage, lpRaisedPercentage, totalCustomPercentage], () => {
  // Ensure no allocation exceeds remaining available percentage
  if (isOverAllocated.value) {
    // Auto-adjust team percentage first (most flexible)
    const excess = totalUsedPercentage.value - 100
    if (teamPercentage.value > excess) {
      teamPercentage.value -= excess
    }
  }
}, { deep: true })

// DEX computed properties
const enabledDexs = computed(() =>
  availableDexs.value.filter(dex => dex.enabled)
)

const availableDexOptions = computed(() => {
  const enabledIds = enabledDexs.value.map(dex => dex.id)
  return allDexPlatforms.filter(platform => !enabledIds.includes(platform.id)).map(platform => ({
    value: platform.id,
    label: platform.label || platform.name
  }))
})

const enabledDEXCount = computed(() => enabledDexs.value.length)

const totalPurchaseLiquidityRequired = computed(() => {
  return availableDexs.value
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + dex.calculatedPurchaseLiquidity, 0)
})

const estimatedTotalTVL = computed(() => {
  if (dynamicListingPrice.value <= 0) return 0
  return availableDexs.value
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + (dex.calculatedTokenLiquidity * dynamicListingPrice.value * 2), 0)
})

const allocationPercentageTotal = computed(() => {
  return availableDexs.value
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + dex.allocationPercentage, 0)
})

const dexFeesTotal = computed(() => {
  return availableDexs.value
    .filter(dex => dex.enabled && dex.fees)
    .reduce((sum, dex) => sum + (dex.calculatedPurchaseLiquidity * (dex.fees?.listing || 0) / 100), 0)
})

const totalFeesEstimate = computed(() => {
  return (hardCapNumber.value * (props.platformFeeRate / 100)) + dexFeesTotal.value
})

// Validation objects
const liquidityValidation = computed(() => {
  const issues = []
  const warnings = []

  // LP Receiver Principal ID validation when LP Lock is enabled
  if (lpLockEnabled.value && !dexConfig.value.lpTokenRecipient?.trim()) {
    issues.push('LP Token Recipient Principal ID is required when LP Lock is enabled')
  }

  // Platform fee validation
  if (props.platformFeeRate > 10) {
    warnings.push('Platform fee is unusually high')
  }

  return { issues, warnings }
})

const liquidityWarnings = computed(() => {
  const warnings = []

  // LP Receiver Principal ID format validation
  if (lpLockEnabled.value && dexConfig.value.lpTokenRecipient?.trim()) {
    const principalId = dexConfig.value.lpTokenRecipient.trim()
    if (!isValidPrincipal(principalId)) {
      warnings.push('LP Token Recipient Principal ID format may be invalid')
    }
  }

  return warnings
})

const raisedFundsAfterFees = computed(() => ({
  availableForLiquidity: currentRaisedAmount.value - platformFee.value - calculatedDexLiquidity.value
}))

// Allocation validation (using existing computed properties from above)

// Helper function to add quick allocation
const addQuickAllocation = (name, percentage) => {
  const newAllocation = {
    id: generateAllocationId(),
    name,
    percentage,
    vestingEnabled: false, // Default to false for custom allocations
    vestingSchedule: null,
    recipients: [] // Initialize with empty recipients array
  }
  customAllocations.value.push(newAllocation)
}

const initializeDefaultAllocations = () => {
  // Add marketing allocation if no custom allocations exist
  if (customAllocations.value.length === 0) {
    addQuickAllocation('Marketing', 20) // 20% for marketing (70% team + 20% marketing + 10% DEX = 100%)
  }

  // Initialize openRaisedFundsAccordions with allocation IDs
  customAllocations.value.forEach(allocation => {
    openRaisedFundsAccordions.value[allocation.id] = false
  })
}

// Initialize defaults on component mount
initializeDefaultAllocations()

// Initialize ICPSwap as default DEX
const initializeDefaultDex = () => {
  if (availableDexs.value.length === 0) {
    addDexPlatform('icpswap')
  }
}

// Initialize DEX on mount
onMounted(() => {
  initializeDefaultDex()
})
</script>
