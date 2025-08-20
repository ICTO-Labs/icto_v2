<template>
	<div class="space-y-6">
		<!-- Timing Mode Selection -->
		<div>
			<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-4">
				{{ startTimeLabel }} *
			</label>
			<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
				<!-- Start Upon Creation -->
				<label class="flex items-center gap-4 p-4 rounded-lg border transition cursor-pointer shadow-sm"
					:class="localConfig.mode === 'immediate'
						? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
						: 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400'">
					<input v-model="localConfig.mode" value="immediate" type="radio" class="sr-only" @change="emitChange" />
					<div class="flex items-center justify-center h-10 w-10 rounded-full" :class="localConfig.mode === 'immediate'
						? 'bg-blue-600'
						: 'bg-blue-50 dark:bg-blue-900/20'">
						<RocketIcon class="h-6 w-6" :class="localConfig.mode === 'immediate'
							? 'text-white'
							: 'text-blue-600'" />
					</div>
					<div class="flex-1 min-w-0">
						<div class="text-base font-medium text-gray-900 dark:text-white">{{ immediateLabel }}</div>
						<div class="text-sm text-gray-500">{{ immediateDescription }}</div>
					</div>
					<div v-if="localConfig.mode === 'immediate'" class="ml-2">
						<CheckIcon class="h-5 w-5 text-blue-600" />
					</div>
				</label>

				<!-- Scheduled Start -->
				<label class="flex items-center gap-4 p-4 rounded-lg border transition cursor-pointer shadow-sm"
					:class="localConfig.mode === 'scheduled'
						? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
						: 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400'">
					<input v-model="localConfig.mode" value="scheduled" type="radio" class="sr-only" @change="emitChange" />
					<div class="flex items-center justify-center h-10 w-10 rounded-full" :class="localConfig.mode === 'scheduled'
						? 'bg-blue-600'
						: 'bg-blue-50 dark:bg-blue-900/20'">
						<CalendarIcon class="h-6 w-6" :class="localConfig.mode === 'scheduled'
							? 'text-white'
							: 'text-blue-600'" />
					</div>
					<div class="flex-1 min-w-0">
						<div class="text-base font-medium text-gray-900 dark:text-white">{{ scheduledLabel }}</div>
						<div class="text-sm text-gray-500">{{ scheduledDescription }}</div>
					</div>
					<div v-if="localConfig.mode === 'scheduled'" class="ml-2">
						<CheckIcon class="h-5 w-5 text-blue-600" />
					</div>
				</label>
			</div>
		</div>

		<!-- Scheduled Configuration -->
		<div v-if="localConfig.mode === 'scheduled'" class="space-y-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
			<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
				<!-- Start Time -->
				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						{{ startTimeInputLabel }} *
					</label>
					<input 
						v-model="localConfig.startTime"
						type="datetime-local" 
						required
						class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
						@change="emitChange"
					/>
					<p class="mt-1 text-xs text-gray-500">When the {{ contextType.toLowerCase() }} should begin</p>
				</div>

				<!-- End Time (Optional) -->
				<div v-if="showEndTime">
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						{{ endTimeInputLabel }}
						<span v-if="!requireEndTime" class="text-gray-400">(Optional)</span>
					</label>
					<input 
						v-model="localConfig.endTime"
						type="datetime-local"
						:required="requireEndTime"
						class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
						@change="emitChange"
					/>
					<p class="mt-1 text-xs text-gray-500">
						<span v-if="contextType === 'Registration'">When registration closes</span>
						<span v-else>When the {{ contextType.toLowerCase() }} should end (leave empty for indefinite)</span>
					</p>
				</div>
			</div>

			<!-- Registration Period Specific Options -->
			<div v-if="contextType === 'Registration'" class="space-y-4">
				<!-- Max Participants -->
				<div>
					<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
						Maximum Participants
						<span class="text-gray-400">(Optional)</span>
					</label>
					<input 
						v-model.number="localConfig.maxParticipants"
						type="number"
						min="1"
						placeholder="No limit"
						class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
						@change="emitChange"
					/>
					<p class="mt-1 text-xs text-gray-500">Maximum number of participants allowed to register</p>
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
						<h5 class="text-sm font-medium text-blue-800 dark:text-blue-200">{{ contextType }} Schedule</h5>
						<div class="mt-1 text-sm text-blue-700 dark:text-blue-300 space-y-1">
							<p v-if="localConfig.startTime">
								<strong>{{ startTimeInputLabel }}:</strong> {{ formatDateTime(localConfig.startTime) }}
							</p>
							<p v-if="localConfig.endTime">
								<strong>{{ endTimeInputLabel }}:</strong> {{ formatDateTime(localConfig.endTime) }}
							</p>
							<p v-if="localConfig.maxParticipants && contextType === 'Registration'">
								<strong>Max Participants:</strong> {{ localConfig.maxParticipants.toLocaleString() }}
							</p>
						</div>
					</div>
				</div>
			</div>
		</div>
	</div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { RocketIcon, CalendarIcon, CheckIcon } from 'lucide-vue-next'

interface TimingConfig {
	mode: 'immediate' | 'scheduled'
	startTime?: string
	endTime?: string
	maxParticipants?: number
}

interface Props {
	modelValue: TimingConfig
	contextType: 'Registration' | 'Distribution' | 'Lock'
	showEndTime?: boolean
	requireEndTime?: boolean
}

interface Emits {
	(e: 'update:modelValue', value: TimingConfig): void
}

const props = withDefaults(defineProps<Props>(), {
	showEndTime: true,
	requireEndTime: false
})

const emit = defineEmits<Emits>()

// Local reactive copy
const localConfig = ref<TimingConfig>({ 
	mode: 'immediate', 
	...props.modelValue 
})

// Dynamic labels based on context type
const startTimeLabel = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Registration Start Time'
		case 'Distribution': return 'Distribution Start Time'  
		case 'Lock': return 'Lock Start Time'
		default: return 'Start Time'
	}
})

const immediateLabel = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Open Registration'
		case 'Distribution': return 'Start Upon Creation'
		case 'Lock': return 'Lock Upon Creation'
		default: return 'Start Immediately'
	}
})

const immediateDescription = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Registration opens immediately after deployment'
		case 'Distribution': return 'Distribution begins immediately after deployment'
		case 'Lock': return 'Lock begins immediately after deployment'
		default: return 'Begins immediately after deployment'
	}
})

const scheduledLabel = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Scheduled Registration'
		case 'Distribution': return 'Scheduled Start'
		case 'Lock': return 'Scheduled Lock'
		default: return 'Scheduled Start'
	}
})

const scheduledDescription = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Set specific registration period'
		case 'Distribution': return 'Set specific start and end times'
		case 'Lock': return 'Set specific lock start time'
		default: return 'Set specific timing'
	}
})

const startTimeInputLabel = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Registration Opens'
		case 'Distribution': return 'Distribution Starts'
		case 'Lock': return 'Lock Starts'
		default: return 'Start Time'
	}
})

const endTimeInputLabel = computed(() => {
	switch (props.contextType) {
		case 'Registration': return 'Registration Closes'
		case 'Distribution': return 'Distribution Ends'
		case 'Lock': return 'Lock Ends'
		default: return 'End Time'
	}
})

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
	Object.assign(localConfig.value, newValue)
}, { deep: true })

// Emit changes to parent
const emitChange = () => {
	emit('update:modelValue', { ...localConfig.value })
}

// Helper function to format date time
const formatDateTime = (dateTimeString: string): string => {
	if (!dateTimeString) return ''
	try {
		const date = new Date(dateTimeString)
		return date.toLocaleString('en-US', {
			year: 'numeric',
			month: 'short', 
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit',
			hour12: true
		})
	} catch {
		return dateTimeString
	}
}
</script>