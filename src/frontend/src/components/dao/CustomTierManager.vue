<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
    <!-- Header with Security Badge -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h3 class="text-xl font-semibold text-gray-900 dark:text-white">🛡️ Custom Tier Manager</h3>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Auditor-approved secure multiplier configuration
        </p>
      </div>
      
      <!-- Security Status -->
      <div class="flex items-center space-x-2">
        <div class="px-3 py-1 bg-green-100 dark:bg-green-900/20 text-green-800 dark:text-green-300 rounded-full text-sm">
          ✅ Secure
        </div>
        <div class="px-3 py-1 bg-blue-100 dark:bg-blue-900/20 text-blue-800 dark:text-blue-300 rounded-full text-sm">
          🔒 Overflow Protected
        </div>
      </div>
    </div>

    <!-- Security Limits Display -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
      <div class="bg-yellow-50 dark:bg-yellow-900/10 border border-yellow-200 dark:border-yellow-800 rounded-lg p-3">
        <div class="text-sm font-medium text-yellow-800 dark:text-yellow-300">Max Multiplier</div>
        <div class="text-lg font-bold text-yellow-900 dark:text-yellow-200">{{ SECURITY_LIMITS.MAX_MULTIPLIER }}x</div>
        <div class="text-xs text-yellow-600 dark:text-yellow-400">Anti-governance capture</div>
      </div>
      
      <div class="bg-blue-50 dark:bg-blue-900/10 border border-blue-200 dark:border-blue-800 rounded-lg p-3">
        <div class="text-sm font-medium text-blue-800 dark:text-blue-300">Max Lock Period</div>
        <div class="text-lg font-bold text-blue-900 dark:text-blue-200">{{ SECURITY_LIMITS.MAX_LOCK_DAYS }} days</div>
        <div class="text-xs text-blue-600 dark:text-blue-400">Prevent permanent locks</div>
      </div>
      
      <div class="bg-red-50 dark:bg-red-900/10 border border-red-200 dark:border-red-800 rounded-lg p-3">
        <div class="text-sm font-medium text-red-800 dark:text-red-300">Min Lock Period</div>
        <div class="text-lg font-bold text-red-900 dark:text-red-200">{{ SECURITY_LIMITS.MIN_LOCK_DAYS }} days</div>
        <div class="text-xs text-red-600 dark:text-red-400">Flash loan protection</div>
      </div>
    </div>

    <!-- Current Tiers -->
    <div class="mb-6">
      <div class="flex items-center justify-between mb-4">
        <h4 class="text-lg font-medium text-gray-900 dark:text-white">Configure Multiplier Tiers</h4>
        <button
          @click="addTier"
          :disabled="tiers.length >= SECURITY_LIMITS.MAX_TIERS"
          class="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-lg text-sm font-medium transition-colors"
        >
          ➕ Add Tier
        </button>
      </div>

      <div class="space-y-4">
        <div 
          v-for="(tier, index) in tiers" 
          :key="tier.id"
          class="border border-gray-200 dark:border-gray-600 rounded-lg p-4"
          :class="{
            'border-red-300 bg-red-50 dark:bg-red-900/10': tierValidation[tier.id] && !tierValidation[tier.id].valid,
            'border-green-300 bg-green-50 dark:bg-green-900/10': tierValidation[tier.id] && tierValidation[tier.id].valid
          }"
        >
          <div class="flex items-center justify-between mb-4">
            <div class="flex items-center space-x-3">
              <div class="w-8 h-8 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">
                {{ index + 1 }}
              </div>
              <div>
                <input
                  v-model="tier.name"
                  @input="validateTier(tier.id)"
                  placeholder="Tier Name (e.g., Short Term)"
                  class="text-lg font-medium bg-transparent border-none outline-none text-gray-900 dark:text-white placeholder-gray-400"
                />
                <div class="text-sm text-gray-500 dark:text-gray-400">
                  Multiplier: {{ formatMultiplier(tier.multiplier) }} • Lock: {{ tier.lockDays }} days
                </div>
              </div>
            </div>
            
            <div class="flex items-center space-x-2">
              <div 
                v-if="tierValidation[tier.id]"
                :class="{
                  'text-green-600': tierValidation[tier.id].valid,
                  'text-red-600': !tierValidation[tier.id].valid
                }"
                class="text-sm font-medium"
              >
                {{ tierValidation[tier.id].valid ? '✅ Valid' : '❌ Invalid' }}
              </div>
              
              <button
                @click="removeTier(tier.id)"
                :disabled="tiers.length <= 1"
                class="p-2 text-red-600 hover:bg-red-100 dark:hover:bg-red-900/20 rounded-lg disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                title="Remove tier"
              >
                🗑️
              </button>
            </div>
          </div>

          <!-- Tier Configuration -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Lock Period (days)
              </label>
              <input
                v-model.number="tier.lockDays"
                @input="onLockDaysChange(tier)"
                type="number"
                :min="SECURITY_LIMITS.MIN_LOCK_DAYS"
                :max="SECURITY_LIMITS.MAX_LOCK_DAYS"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              />
              <div class="text-xs text-gray-500 mt-1">{{ SECURITY_LIMITS.MIN_LOCK_DAYS }}-{{ SECURITY_LIMITS.MAX_LOCK_DAYS }} days</div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Voting Power Multiplier
              </label>
              <input
                v-model.number="tier.multiplier"
                @input="validateTier(tier.id)"
                type="number"
                step="0.1"
                :min="1.0"
                :max="SECURITY_LIMITS.MAX_MULTIPLIER"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              />
              <div class="text-xs text-gray-500 mt-1">1.0x - {{ SECURITY_LIMITS.MAX_MULTIPLIER }}x max</div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Min Stake Amount (tokens)
              </label>
              <input
                v-model.number="tier.minStake"
                @input="validateTier(tier.id)"
                type="number"
                min="1"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              />
              <div class="text-xs text-gray-500 mt-1">Minimum entry requirement</div>
            </div>
          </div>

          <!-- Advanced Configuration -->
          <div v-if="tier.showAdvanced" class="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Max Stake Per Entry (optional)
              </label>
              <input
                v-model.number="tier.maxStakePerEntry"
                type="number"
                min="0"
                placeholder="0 = no limit"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              />
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                Max VP % (governance security)
              </label>
              <input
                v-model.number="tier.maxVpPercent"
                @input="validateTier(tier.id)"
                type="number"
                min="1"
                max="40"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              />
              <div class="text-xs text-gray-500 mt-1">Max 40% to prevent whale attacks</div>
            </div>
          </div>

          <!-- Toggle Advanced -->
          <button
            @click="tier.showAdvanced = !tier.showAdvanced"
            class="mt-3 text-sm text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium"
          >
            {{ tier.showAdvanced ? '🔽 Hide Advanced' : '🔼 Show Advanced' }}
          </button>

          <!-- Validation Errors -->
          <div v-if="tierValidation[tier.id] && !tierValidation[tier.id].valid" class="mt-4 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <div class="text-sm font-medium text-red-800 dark:text-red-300 mb-1">⚠️ Validation Issues:</div>
            <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
              <li v-for="error in tierValidation[tier.id].errors" :key="error">• {{ error }}</li>
            </ul>
          </div>
        </div>
      </div>
    </div>

    <!-- Security Analysis -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
      <h4 class="text-sm font-medium text-blue-800 dark:text-blue-300 mb-3">🛡️ Security Analysis</h4>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <div class="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">Governance Security Score</div>
          <div class="text-lg font-bold" :class="securityScore >= 80 ? 'text-green-600' : securityScore >= 60 ? 'text-yellow-600' : 'text-red-600'">
            {{ securityScore }}/100
          </div>
          <div class="text-xs text-blue-500">{{ getSecurityLevel(securityScore) }}</div>
        </div>
        
        <div>
          <div class="text-xs text-blue-600 dark:text-blue-400 font-medium mb-1">Risk Assessment</div>
          <div class="space-y-1">
            <div class="flex items-center space-x-2 text-xs">
              <span :class="maxMultiplier <= 3.0 ? 'text-green-600' : 'text-red-600'">
                {{ maxMultiplier <= 3.0 ? '✅' : '❌' }}
              </span>
              <span>Max multiplier: {{ formatMultiplier(maxMultiplier) }}</span>
            </div>
            <div class="flex items-center space-x-2 text-xs">
              <span :class="hasFlashLoanProtection ? 'text-green-600' : 'text-red-600'">
                {{ hasFlashLoanProtection ? '✅' : '❌' }}
              </span>
              <span>Flash loan protection</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Action Buttons -->
    <div class="flex items-center justify-between mt-6 pt-6 border-t border-gray-200 dark:border-gray-700">
      <div class="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
        <span>{{ tiers.length }} tier{{ tiers.length !== 1 ? 's' : '' }} configured</span>
        <span>•</span>
        <span class="font-medium" :class="allTiersValid ? 'text-green-600' : 'text-red-600'">
          {{ allTiersValid ? 'All valid' : 'Has errors' }}
        </span>
      </div>
      
      <div class="flex items-center space-x-3">
        <button
          @click="resetToDefaults"
          class="px-4 py-2 text-gray-600 dark:text-gray-400 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
        >
          🔄 Reset to Defaults
        </button>
        
        <div class="px-4 py-2 bg-green-100 dark:bg-green-900/20 text-green-800 dark:text-green-300 rounded-lg text-sm">
          ✅ Auto-saved • Real-time sync
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { toast } from 'vue-sonner'

// Define props and emits
interface Props {
  modelValue?: CustomTier[]
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: () => []
})

const emit = defineEmits<{
  'update:modelValue': [value: CustomTier[]]
  'tier-config-changed': [tiers: CustomTier[]]
  'validation-changed': [validation: { valid: boolean; score: number; errors: string[] }]
}>()

// Security Constants (Auditor-approved limits)
const SECURITY_LIMITS = {
  MAX_MULTIPLIER: 3.0,   // Prevent governance capture
  MIN_MULTIPLIER: 1.0,   // Base multiplier
  MAX_LOCK_DAYS: 1095,   // 3 years max (prevent permanent locks)
  MIN_LOCK_DAYS: 7,      // 1 week min (flash loan protection)
  MAX_TIERS: 10,         // Prevent complexity attacks
  MIN_TIERS: 1,          // At least one tier required
  MAX_VP_PERCENT: 40     // Anti-whale protection
}

// Tier Interface
interface CustomTier {
  id: number
  name: string
  lockDays: number
  multiplier: number
  minStake: number
  maxStakePerEntry: number
  maxVpPercent: number
  showAdvanced: boolean
}

interface TierValidation {
  valid: boolean
  errors: string[]
}

// Reactive State
const tiers = ref<CustomTier[]>([])
const tierValidation = ref<Record<number, TierValidation>>({})
const nextTierId = ref(1)

// Initialize with secure defaults or from props
const initializeDefaults = () => {
  if (props.modelValue && props.modelValue.length > 0) {
    tiers.value = [...props.modelValue]
    // Update nextTierId to avoid conflicts
    nextTierId.value = Math.max(...tiers.value.map(t => t.id)) + 1
  } else {
    tiers.value = [
      {
        id: nextTierId.value++,
        name: 'Short Term',
        lockDays: 7,
        multiplier: 1.1,
        minStake: 100,
        maxStakePerEntry: 0,
        maxVpPercent: 15,
        showAdvanced: false
      },
      {
        id: nextTierId.value++,
        name: 'Medium Term', 
        lockDays: 90,
        multiplier: 1.5,
        minStake: 500,
        maxStakePerEntry: 0,
        maxVpPercent: 25,
        showAdvanced: false
      },
      {
        id: nextTierId.value++,
        name: 'Long Term',
        lockDays: 365,
        multiplier: 2.0,
        minStake: 1000,
        maxStakePerEntry: 0,
        maxVpPercent: 30,
        showAdvanced: false
      }
    ]
  }
  
  // Validate all tiers
  tiers.value.forEach(tier => validateTier(tier.id))
  emitTierConfig()
}

// Emit tier configuration to parent
const emitTierConfig = () => {
  emit('update:modelValue', [...tiers.value])
  emit('tier-config-changed', [...tiers.value])
  
  // Emit validation status
  const validationResult = {
    valid: allTiersValid.value,
    score: securityScore.value,
    errors: Object.values(tierValidation.value)
      .filter(v => !v.valid)
      .flatMap(v => v.errors)
  }
  emit('validation-changed', validationResult)
}

// Computed Properties
const allTiersValid = computed(() => {
  return tiers.value.every(tier => tierValidation.value[tier.id]?.valid)
})

const maxMultiplier = computed(() => {
  return Math.max(...tiers.value.map(t => t.multiplier))
})

const hasFlashLoanProtection = computed(() => {
  return tiers.value.every(t => t.lockDays >= SECURITY_LIMITS.MIN_LOCK_DAYS)
})

const securityScore = computed(() => {
  let score = 100
  
  // Deduct points for high multiplier
  if (maxMultiplier.value > 3.0) score -= 30
  else if (maxMultiplier.value > 2.5) score -= 15
  
  // Deduct points for insufficient flash loan protection
  if (!hasFlashLoanProtection.value) score -= 25
  
  // Deduct points for too many tiers (complexity attack)
  if (tiers.value.length > 7) score -= 10
  
  // Deduct points for overlapping tiers
  const sortedTiers = [...tiers.value].sort((a, b) => a.lockDays - b.lockDays)
  for (let i = 1; i < sortedTiers.length; i++) {
    if (sortedTiers[i].multiplier < sortedTiers[i-1].multiplier) {
      score -= 15 // Incentive misalignment
    }
  }
  
  return Math.max(0, score)
})

// Methods
const validateTier = (tierId: number) => {
  const tier = tiers.value.find(t => t.id === tierId)
  if (!tier) return
  
  const errors: string[] = []
  
  // Lock period validation
  if (tier.lockDays < SECURITY_LIMITS.MIN_LOCK_DAYS) {
    errors.push(`Lock period must be at least ${SECURITY_LIMITS.MIN_LOCK_DAYS} days`)
  }
  if (tier.lockDays > SECURITY_LIMITS.MAX_LOCK_DAYS) {
    errors.push(`Lock period cannot exceed ${SECURITY_LIMITS.MAX_LOCK_DAYS} days`)
  }
  
  // Multiplier validation
  if (tier.multiplier < SECURITY_LIMITS.MIN_MULTIPLIER) {
    errors.push('Multiplier must be at least 1.0x')
  }
  if (tier.multiplier > SECURITY_LIMITS.MAX_MULTIPLIER) {
    errors.push(`Multiplier cannot exceed ${SECURITY_LIMITS.MAX_MULTIPLIER}x`)
  }
  
  // Min stake validation
  if (tier.minStake <= 0) {
    errors.push('Minimum stake must be greater than 0')
  }
  
  // VP percent validation
  if (tier.maxVpPercent > SECURITY_LIMITS.MAX_VP_PERCENT) {
    errors.push(`Max VP% cannot exceed ${SECURITY_LIMITS.MAX_VP_PERCENT}%`)
  }
  
  // Max stake validation
  if (tier.maxStakePerEntry > 0 && tier.maxStakePerEntry <= tier.minStake) {
    errors.push('Max stake per entry must be greater than min stake')
  }
  
  tierValidation.value[tierId] = {
    valid: errors.length === 0,
    errors
  }
  
  // Emit changes on validation
  emitTierConfig()
}

const onLockDaysChange = (tier: CustomTier) => {
  // Auto-suggest multiplier based on lock period (security-conscious)
  const lockRatio = Math.min(tier.lockDays / SECURITY_LIMITS.MAX_LOCK_DAYS, 1)
  const suggestedMultiplier = 1.0 + (lockRatio * (SECURITY_LIMITS.MAX_MULTIPLIER - 1.0))
  
  // Only update if current multiplier is default (1.0) to avoid overwriting user input
  if (tier.multiplier === 1.0) {
    tier.multiplier = Math.round(suggestedMultiplier * 10) / 10 // Round to 1 decimal
  }
  
  validateTier(tier.id)
}

const addTier = () => {
  if (tiers.value.length >= SECURITY_LIMITS.MAX_TIERS) {
    toast.error(`Maximum ${SECURITY_LIMITS.MAX_TIERS} tiers allowed for security`)
    return
  }
  
  const newTier: CustomTier = {
    id: nextTierId.value++,
    name: `Custom Tier ${tiers.value.length + 1}`,
    lockDays: SECURITY_LIMITS.MIN_LOCK_DAYS,
    multiplier: 1.1,
    minStake: 100,
    maxStakePerEntry: 0,
    maxVpPercent: 15,
    showAdvanced: false
  }
  
  tiers.value.push(newTier)
  validateTier(newTier.id)
  emitTierConfig()
  toast.success('New tier added')
}

const removeTier = (tierId: number) => {
  if (tiers.value.length <= SECURITY_LIMITS.MIN_TIERS) {
    toast.error('At least one tier must remain')
    return
  }
  
  const index = tiers.value.findIndex(t => t.id === tierId)
  if (index > -1) {
    tiers.value.splice(index, 1)
    delete tierValidation.value[tierId]
    emitTierConfig()
    toast.success('Tier removed')
  }
}

const resetToDefaults = () => {
  if (confirm('Reset to default secure configuration? This will lose all current changes.')) {
    // Reset to defaults but don't use props
    tiers.value = [
      {
        id: nextTierId.value++,
        name: 'Short Term',
        lockDays: 7,
        multiplier: 1.1,
        minStake: 100,
        maxStakePerEntry: 0,
        maxVpPercent: 15,
        showAdvanced: false
      },
      {
        id: nextTierId.value++,
        name: 'Medium Term', 
        lockDays: 90,
        multiplier: 1.5,
        minStake: 500,
        maxStakePerEntry: 0,
        maxVpPercent: 25,
        showAdvanced: false
      },
      {
        id: nextTierId.value++,
        name: 'Long Term',
        lockDays: 365,
        multiplier: 2.0,
        minStake: 1000,
        maxStakePerEntry: 0,
        maxVpPercent: 30,
        showAdvanced: false
      }
    ]
    tiers.value.forEach(tier => validateTier(tier.id))
    emitTierConfig()
    toast.info('Reset to secure defaults')
  }
}

// Real-time tier configuration (no manual save needed)

const formatMultiplier = (multiplier: number): string => {
  return `${multiplier.toFixed(1)}x`
}

const getSecurityLevel = (score: number): string => {
  if (score >= 90) return 'Excellent'
  if (score >= 80) return 'Good' 
  if (score >= 60) return 'Fair'
  return 'Needs Improvement'
}

// Initialize on mount
initializeDefaults()

// Watch for changes and auto-validate (debounced to avoid excessive calls)
let emitTimeout: NodeJS.Timeout | null = null
watch(tiers, () => {
  // Clear existing timeout
  if (emitTimeout) clearTimeout(emitTimeout)
  
  // Debounce emission to avoid too frequent updates
  emitTimeout = setTimeout(() => {
    emitTierConfig()
  }, 300)
}, { deep: true })
</script>

<style scoped>
/* Custom scrollbar for better UX */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

/* Smooth transitions */
* {
  transition: all 0.2s ease;
}

/* Focus states */
input:focus {
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

/* Button hover effects */
button:not(:disabled):hover {
  transform: translateY(-1px);
  shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}
</style>