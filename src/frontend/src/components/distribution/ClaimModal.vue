<template>
    <div class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
         @click="$emit('close')"
    >
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl max-w-md w-full p-6"
             @click.stop
        >
            <!-- Header -->
            <div class="flex items-center justify-between mb-6">
                <h3 class="text-xl font-bold text-gray-900 dark:text-white">
                    Claim Tokens
                </h3>
                <button @click="$emit('close')"
                        class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                >
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>

            <!-- Token Info -->
            <div class="bg-gradient-to-br from-[#d8a735]/10 to-[#eacf6f]/10 rounded-lg p-4 mb-6">
                <div class="flex items-center justify-between mb-2">
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Total Allocation
                    </span>
                    <span class="text-lg font-bold text-gray-900 dark:text-white">
                        {{ formatTokenAmount(claimInfo.totalAllocated) }}
                    </span>
                </div>
                <div class="flex items-center justify-between mb-2">
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Available to Claim
                    </span>
                    <span class="text-lg font-bold text-[#d8a735]">
                        {{ formatTokenAmount(claimInfo.maxClaimable) }}
                    </span>
                </div>
                <div class="flex items-center justify-between mb-2">
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Already Claimed
                    </span>
                    <span class="text-sm font-semibold text-gray-600 dark:text-gray-400">
                        {{ formatTokenAmount(claimInfo.claimed) }}
                    </span>
                </div>
                <div class="flex items-center justify-between">
                    <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Remaining Total
                    </span>
                    <span class="text-sm font-semibold text-blue-600 dark:text-blue-400">
                        {{ formatTokenAmount(claimInfo.remaining) }}
                    </span>
                </div>
            </div>

            <!-- Slider Control -->
            <div class="mb-6">
                <div class="flex items-center justify-between mb-2">
                    <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
                        Claim Amount
                    </label>
                    <span class="text-sm font-bold text-gray-900 dark:text-white">
                        {{ formatTokenAmount(selectedAmount) }}
                    </span>
                </div>

                <!-- Percentage Slider -->
                <div class="relative mb-4">
                    <input
                        v-model="selectedPercentage"
                        type="range"
                        min="0"
                        max="100"
                        step="25"
                        class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg appearance-none cursor-pointer slider"
                        :style="sliderStyle"
                    />
                    <!-- Slider Track Background -->
                    <div class="absolute top-1/2 -translate-y-1/2 w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-lg pointer-events-none" />
                    <div class="absolute top-1/2 -translate-y-1/2 h-2 bg-gradient-to-r from-[#d8a735] to-[#e1b74c] rounded-lg pointer-events-none"
                         :style="{ width: selectedPercentage + '%' }"
                    />
                </div>

                <!-- Quick Selection Buttons -->
                <div class="flex justify-between gap-2 mb-4">
                    <button
                        v-for="percentage in [10, 30, 50, 80, 100]"
                        :key="percentage"
                        @click="selectedPercentage = percentage"
                        :class="[
                            'flex-1 py-2 px-3 rounded-lg font-medium text-sm transition-all',
                            selectedPercentage === percentage
                                ? 'bg-gradient-to-r from-[#d8a735] to-[#e1b74c] text-white shadow-md'
                                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                        ]"
                    >
                        {{ percentage }}%
                    </button>
                </div>

                <!-- Input Field -->
                <div class="relative">
                    <input
                        v-model.number="selectedAmount"
                        type="number"
                        :max="parseTokenAmount(claimInfo.maxClaimable, tokenDecimals).toNumber()"
                        :min="0"
                        step="any"
                        class="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white text-right pr-16"
                        placeholder="Enter amount"
                    />
                    <span class="absolute right-3 top-1/2 -translate-y-1/2 text-sm text-gray-500 dark:text-gray-400">
                        {{ tokenSymbol }}
                    </span>
                </div>

                <!-- Validation Message -->
                <div v-if="validationMessage" class="mt-2 text-sm" :class="validationClass">
                    {{ validationMessage }}
                </div>
            </div>

            <!-- Status Indicators -->
            <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 mb-6">
                <div class="text-sm">
                    <div class="mb-3">
                        <span class="text-gray-600 dark:text-gray-400">Overall Progress</span>
                        <div class="flex items-center mt-1">
                            <div class="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-3 mr-3">
                                <div class="bg-gradient-to-r from-[#d8a735] to-[#e1b74c] h-3 rounded-full transition-all"
                                     :style="{ width: progressPercentage + '%' }"
                                />
                            </div>
                            <span class="text-sm font-medium text-gray-900 dark:text-white min-w-[40px] text-right">
                                {{ progressPercentage.toFixed(1) }}%
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Action Buttons -->
            <div class="flex gap-3">
                <button
                    @click="$emit('close')"
                    class="flex-1 px-4 py-3 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                >
                    Cancel
                </button>
                <button
                    @click="handleClaim"
                    :disabled="isClaiming || selectedAmount === 0 || !isValid"
                    class="flex-1 px-4 py-3 bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white font-semibold rounded-lg hover:shadow-lg transform hover:-translate-y-0.5 transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                >
                    <span v-if="isClaiming" class="flex items-center">
                        <svg class="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8 0 018 8 0 018-8 0 018-8 0 018-8 0 018-8 0 018z"></path>
                        </svg>
                        Claiming...
                    </span>
                    <span v-else>
                        Claim {{ formatTokenAmount(selectedAmount) }}
                    </span>
                </button>
            </div>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { ClaimInfo } from '@/types/distribution'
import { formatTokenDisplay, parseTokenAmount } from '@/utils/token'

interface Props {
    distributionId: string
    claimInfo: ClaimInfo
    tokenSymbol: string
    tokenDecimals: number
}

interface Emits {
    close: []
    claimed: [amount: number]
    refresh: []
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// State
const selectedPercentage = ref(100)
const selectedAmount = ref(0)
const isClaiming = ref(false)

// Computed
const isValid = computed(() => {
    const maxClaimableHuman = parseTokenAmount(props.claimInfo.maxClaimable, props.tokenDecimals).toNumber()
    return selectedAmount.value > 0 && selectedAmount.value <= maxClaimableHuman
})

const progressPercentage = computed(() => {
    if (props.claimInfo.totalAllocated === 0) return 0
    return (props.claimInfo.claimed / props.claimInfo.totalAllocated) * 100
})

const sliderStyle = computed(() => ({
    'background': `linear-gradient(to right, #d8a735 0%, #e1b74c ${selectedPercentage.value}%, #e3e3e3 ${selectedPercentage.value}%)`
}))

const validationMessage = computed(() => {
    if (selectedAmount.value === 0) {
        return 'Please enter an amount to claim'
    }
    const maxClaimableHuman = parseTokenAmount(props.claimInfo.maxClaimable, props.tokenDecimals).toNumber()
    if (selectedAmount.value > maxClaimableHuman) {
        return 'Amount exceeds available tokens'
    }
    return ''
})

const validationClass = computed(() => {
    if (selectedAmount.value === 0) {
        return 'text-gray-500'
    }
    const maxClaimableHuman = parseTokenAmount(props.claimInfo.maxClaimable, props.tokenDecimals).toNumber()
    if (selectedAmount.value > maxClaimableHuman) {
        return 'text-red-600 dark:text-red-400'
    }
    return 'text-green-600 dark:text-green-400'
})

// Initialize amount when modal opens (default to 100%) and refresh data
watch(() => props.claimInfo, (newClaimInfo) => {
    if (newClaimInfo && newClaimInfo.maxClaimable > 0) {
        const maxClaimableHuman = parseTokenAmount(newClaimInfo.maxClaimable, props.tokenDecimals).toNumber()
        selectedAmount.value = maxClaimableHuman
        selectedPercentage.value = 100
    }
}, { immediate: true })

// Remove this watch to prevent infinite loops
// Data refresh will be handled by parent component when modal opens

// Watch percentage changes (update amount)
watch(selectedPercentage, (newPercentage) => {
    if (props.claimInfo.maxClaimable > 0) {
        const maxClaimableHuman = parseTokenAmount(props.claimInfo.maxClaimable, props.tokenDecimals).toNumber()
        const amount = Math.floor((maxClaimableHuman * newPercentage) / 100)
        selectedAmount.value = amount
    }
})

// Watch amount changes (update percentage) - with debounce to prevent loop
watch(selectedAmount, (newAmount) => {
    if (props.claimInfo.maxClaimable > 0) {
        const maxClaimableHuman = parseTokenAmount(props.claimInfo.maxClaimable, props.tokenDecimals).toNumber()
        const percentage = Math.min(100, Math.floor((newAmount / maxClaimableHuman) * 100))
        // Find closest percentage from [10, 30, 50, 80, 100]
        const percentages = [10, 30, 50, 80, 100]
        const closest = percentages.reduce((prev, curr) =>
            Math.abs(curr - percentage) < Math.abs(prev - percentage) ? curr : prev
        )
        // Only update if different to prevent loop
        if (selectedPercentage.value !== closest) {
            selectedPercentage.value = closest
        }
    }
})

// Methods
const formatTokenAmount = (amount: number): string => {
    // Convert raw amount to human-readable for display
    const humanReadable = parseTokenAmount(amount, props.tokenDecimals).toNumber()
    return `${humanReadable.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 3 })} ${props.tokenSymbol}`
}

const handleClaim = async () => {
    if (!isValid.value || isClaiming.value) return

    isClaiming.value = true

    try {
        // TODO: Call the claim function with selectedAmount
        // const result = await distributionService.claim(props.distributionId, selectedAmount.value)

        // For now, simulate the claim
        await new Promise(resolve => setTimeout(resolve, 2000))

        emit('claimed', selectedAmount.value)
        emit('close')

        // Reset form
        selectedPercentage.value = 100
        selectedAmount.value = 0
    } catch (error) {
        console.error('Claim failed:', error)
        // TODO: Show error message
    } finally {
        isClaiming.value = false
    }
}
</script>

<style scoped>
.slider {
    -webkit-appearance: none;
    appearance: none;
    background: transparent;
    cursor: pointer;
}

.slider::-webkit-slider-track {
    background: transparent;
}

.slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    background: white;
    border: 2px solid #d8a735;
    border-radius: 50%;
    cursor: pointer;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.slider::-moz-range-thumb {
    width: 20px;
    height: 20px;
    background: white;
    border: 2px solid #d8a735;
    border-radius: 50%;
    cursor: pointer;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.slider::-webkit-slider-thumb:hover {
    transform: scale(1.1);
}

.slider::-moz-range-thumb:hover {
    transform: scale(1.1);
}

/* Custom slider styling for better UX */
input[type="range"] {
    -webkit-appearance: none;
    width: 100%;
    height: 8px;
    border-radius: 5px;
    background: transparent;
    outline: none;
    opacity: 0.7;
    transition: opacity 0.2s;
}

input[type="range"]:hover {
    opacity: 1;
}

input[type="range"]::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: linear-gradient(135deg, #d8a735 0%, #e1b74c 100%);
    cursor: pointer;
    border: 2px solid white;
    box-shadow: 0 2px 8px rgba(216, 167, 53, 0.3);
}

input[type="range"]::-moz-range-thumb {
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: linear-gradient(135deg, #d8a735 0%, #e1b74c 100%);
    cursor: pointer;
    border: 2px solid white;
    box-shadow: 0 2px 8px rgba(216, 167, 53, 0.3);
}

input[type="range"]::-webkit-slider-thumb:hover {
    transform: scale(1.1);
}

input[type="range"]::-moz-range-thumb:hover {
    transform: scale(1.1);
}
</style>