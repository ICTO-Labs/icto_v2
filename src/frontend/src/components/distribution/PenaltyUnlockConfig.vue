<template>
	<div class="space-y-4">
		<div>
			<BaseSwitch
				:model-value="!!localConfig.enableEarlyUnlock"
				@update:model-value="(value: boolean) => { localConfig.enableEarlyUnlock = value; emitChange() }"
				label="Early Unlock (Optional)"
				label-position="right"
				description="Allow participants to unlock tokens early with a penalty"
			/>
		</div>

		<!-- Early Unlock Configuration (when enabled) -->
		<div v-if="localConfig.enableEarlyUnlock" class="space-y-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
				<!-- Penalty Percentage -->
				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						Early Unlock Penalty (%) *
					</label>
					<div class="relative">
						<input 
							v-model.number="localConfig.penaltyPercentage" 
							type="number" 
							required 
							min="0" 
							max="100"
							step="1"
							placeholder="10"
							class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-2 pr-8 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
							@input="emitChange"
						/>
						<span class="absolute right-3 top-3 text-sm text-gray-500">%</span>
					</div>
					<p class="mt-1 text-xs text-gray-500">Percentage of tokens taken as penalty when unlocking early</p>
				</div>

				<!-- Penalty Recipient -->
				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						Penalty Recipient
					</label>
					<input 
						v-model="localConfig.penaltyRecipient" 
						type="text" 
						placeholder="Principal ID (leave empty to burn tokens)"
						class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
						@input="emitChange"
					/>
					<p class="mt-1 text-xs text-gray-500">Where penalty tokens go. Leave empty to burn tokens.</p>
				</div>
			</div>

			<!-- Minimum Lock Time Configuration -->
			<div class="bg-white dark:bg-gray-900 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
				<div class="mb-4">
					<BaseSwitch
						:model-value="hasMinLockTime"
						@update:model-value="(value: boolean) => { hasMinLockTime = value; if (!value) localConfig.minLockTime = undefined; else calculateMinLockTime(); emitChange() }"
						label="Minimum Lock Time"
						label-position="right"
						description="Require a minimum lock duration before early unlock is allowed"
					/>
				</div>

				<div v-if="hasMinLockTime" class="grid grid-cols-1 md:grid-cols-2 gap-4">
					<!-- Lock Time Method Selection -->
					<div>
						<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
							Lock Time Method
						</label>
						<div class="flex gap-2">
							<label class="flex items-center gap-2 cursor-pointer px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 flex-1 text-center">
								<input 
									v-model="minLockTimeMode" 
									value="percentage" 
									type="radio"
									class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" 
									@change="calculateMinLockTime"
								/>
								<span class="text-sm text-gray-700 dark:text-gray-300">Percentage</span>
							</label>
							<label class="flex items-center gap-2 cursor-pointer px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 flex-1 text-center">
								<input 
									v-model="minLockTimeMode" 
									value="absolute" 
									type="radio"
									class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500"
									@change="calculateMinLockTime"
								/>
								<span class="text-sm text-gray-700 dark:text-gray-300">Absolute</span>
							</label>
						</div>
					</div>

					<!-- Lock Time Input -->
					<div>
						<!-- Percentage Input -->
						<div v-if="minLockTimeMode === 'percentage'">
							<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
								Percentage of Lock Duration *
							</label>
							<div class="relative">
								<input 
									v-model.number="minLockPercentage" 
									type="number" 
									required
									min="0" 
									max="100"
									step="1"
									placeholder="50"
									class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 pr-8 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
									@input="calculateMinLockTime"
								/>
								<span class="absolute right-2 top-2 text-sm text-gray-500">%</span>
							</div>
							<p class="mt-1 text-xs text-gray-500">
								Example: {{ minLockPercentage || 0 }}% = {{ Math.round(((minLockPercentage || 0) * 365) / 100) }} days for 1-year lock
							</p>
						</div>

						<!-- Absolute Time Input -->
						<div v-if="minLockTimeMode === 'absolute'">
							<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
								Absolute Time *
							</label>
							<div class="grid grid-cols-3 gap-2">
								<div>
									<input 
										v-model.number="minLockDays" 
										type="number" 
										required
										min="0"
										step="1"
										placeholder="30"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
										@input="calculateMinLockTime"
									/>
									<div class="text-xs text-gray-500 mt-1 text-center">Days</div>
								</div>
								<div>
									<input 
										v-model.number="minLockHours" 
										type="number" 
										min="0"
										max="23"
										step="1"
										placeholder="0"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
										@input="calculateMinLockTime"
									/>
									<div class="text-xs text-gray-500 mt-1 text-center">Hours</div>
								</div>
								<div>
									<input 
										v-model.number="minLockMinutes" 
										type="number" 
										min="0"
										max="59"
										step="1"
										placeholder="0"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
										@input="calculateMinLockTime"
									/>
									<div class="text-xs text-gray-500 mt-1 text-center">Minutes</div>
								</div>
							</div>
							<p class="mt-1 text-xs text-gray-500">
								Total: {{ getTotalTimeDescription() }}
							</p>
						</div>
					</div>
				</div>
			</div>

			<!-- Preview -->
			<div class="bg-blue-50 dark:bg-blue-900/30 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
				<div class="flex items-start">
					<div class="flex-shrink-0">
						<svg class="w-5 h-5 text-blue-500 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
						</svg>
					</div>
					<div class="ml-3">
						<h5 class="text-sm font-medium text-blue-800 dark:text-blue-200">Early Unlock Settings</h5>
						<div class="mt-1 space-y-1 text-sm text-blue-700 dark:text-blue-300">
							<p>
								Participants can unlock their tokens early with a <strong>{{ localConfig.penaltyPercentage || 0 }}% penalty</strong>.
							</p>
							<p v-if="hasMinLockTime">
								<strong>Minimum lock requirement:</strong> {{ getMinLockTimeDescription() }}
							</p>
							<p>
								{{ localConfig.penaltyRecipient ? 
									`Penalty tokens will be sent to: ${localConfig.penaltyRecipient}` : 
									'Penalty tokens will be burned permanently.' }}
							</p>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import type { PenaltyUnlock } from '@/types/distribution'
import BaseSwitch from '@/components/common/BaseSwitch.vue'

interface Props {
	modelValue: Partial<PenaltyUnlock>
	lockDuration?: number // Total lock duration in nanoseconds (for percentage calculation)
}

interface Emits {
	(e: 'update:modelValue', value: Partial<PenaltyUnlock>): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// Local reactive copy of the config
const localConfig = ref<Partial<PenaltyUnlock>>({
	enableEarlyUnlock: false,
	penaltyPercentage: 10,
	penaltyRecipient: '',
	minLockTime: undefined,
	...props.modelValue
})

// UI state for minimum lock time
const hasMinLockTime = ref(!!localConfig.value.minLockTime)
const minLockTimeMode = ref<'percentage' | 'absolute'>('percentage')

// UI inputs for different modes
const minLockPercentage = ref(50) // Default 50%
const minLockDays = ref(0)
const minLockHours = ref(0)
const minLockMinutes = ref(0)

// Initialize from existing minLockTime if available
if (localConfig.value.minLockTime && props.lockDuration) {
	const minTimeNanos = localConfig.value.minLockTime
	const percentage = Math.round((minTimeNanos / props.lockDuration) * 100)
	
	if (percentage <= 100) {
		// Use percentage mode
		minLockTimeMode.value = 'percentage'
		minLockPercentage.value = percentage
	} else {
		// Use absolute mode
		minLockTimeMode.value = 'absolute'
		const totalMinutes = Math.floor(minTimeNanos / (1_000_000_000 * 60))
		minLockDays.value = Math.floor(totalMinutes / (24 * 60))
		minLockHours.value = Math.floor((totalMinutes % (24 * 60)) / 60)
		minLockMinutes.value = totalMinutes % 60
	}
}

// Watch for changes from parent - SIMPLIFIED
watch(() => props.modelValue, (newValue) => {
	Object.assign(localConfig.value, newValue)
	// Don't auto-disable based on value changes
}, { deep: true })

// Simple calculation function
const calculateMinLockTime = () => {
	if (!hasMinLockTime.value) return
	
	let minTimeNanos: number

	if (minLockTimeMode.value === 'percentage') {
		if (props.lockDuration && minLockPercentage.value > 0) {
			minTimeNanos = Math.floor((props.lockDuration * minLockPercentage.value) / 100)
		} else {
			const oneYearNanos = 365 * 24 * 60 * 60 * 1_000_000_000
			minTimeNanos = Math.floor((oneYearNanos * (minLockPercentage.value || 0)) / 100)
		}
	} else {
		const totalMinutes = (minLockDays.value || 0) * 24 * 60 + (minLockHours.value || 0) * 60 + (minLockMinutes.value || 0)
		minTimeNanos = totalMinutes * 60 * 1_000_000_000
	}

	localConfig.value.minLockTime = minTimeNanos
	emitChange()
}

// Helper for absolute time description
const getTotalTimeDescription = (): string => {
	const days = minLockDays.value || 0
	const hours = minLockHours.value || 0
	const minutes = minLockMinutes.value || 0
	
	const parts = []
	if (days > 0) parts.push(`${days}d`)
	if (hours > 0) parts.push(`${hours}h`)
	if (minutes > 0) parts.push(`${minutes}m`)
	
	return parts.length > 0 ? parts.join(' ') : '0m'
}

// Get description of minimum lock time for preview
const getMinLockTimeDescription = (): string => {
	if (!localConfig.value.minLockTime) return 'None'

	const minTimeNanos = localConfig.value.minLockTime
	const totalMinutes = Math.floor(minTimeNanos / (1_000_000_000 * 60))
	
	if (totalMinutes === 0) return 'None'

	const days = Math.floor(totalMinutes / (24 * 60))
	const hours = Math.floor((totalMinutes % (24 * 60)) / 60)
	const minutes = totalMinutes % 60

	const parts = []
	if (days > 0) parts.push(`${days} day${days === 1 ? '' : 's'}`)
	if (hours > 0) parts.push(`${hours} hour${hours === 1 ? '' : 's'}`)
	if (minutes > 0) parts.push(`${minutes} minute${minutes === 1 ? '' : 's'}`)

	let description = parts.join(', ')

	// Add percentage if lock duration is available
	if (props.lockDuration && props.lockDuration > 0) {
		const percentage = Math.round((minTimeNanos / props.lockDuration) * 100)
		description += ` (${percentage}% of lock duration)`
	}

	return description
}

// Emit changes to parent
const emitChange = () => {
	emit('update:modelValue', { ...localConfig.value })
}
</script>