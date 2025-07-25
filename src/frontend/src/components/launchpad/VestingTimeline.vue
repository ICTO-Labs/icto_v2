<template>
  <div class="space-y-6">
    <!-- Timeline -->
    <div class="relative">
      <div class="absolute left-4 top-0 bottom-0 w-0.5 bg-gray-300 dark:bg-gray-600"></div>
      
      <div
        v-for="(milestone, index) in vestingMilestones"
        :key="index"
        class="relative flex items-start mb-8 last:mb-0"
      >
        <!-- Timeline dot -->
        <div
          :class="[
            'absolute left-4 w-8 h-8 rounded-full border-4 border-white dark:border-gray-800 z-10 -translate-x-1/2',
            milestone.completed 
              ? 'bg-green-500' 
              : milestone.active 
                ? 'bg-blue-500 animate-pulse' 
                : 'bg-gray-400'
          ]"
        >
          <svg
            v-if="milestone.completed"
            class="w-4 h-4 text-white absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
            fill="currentColor"
            viewBox="0 0 20 20"
          >
            <path
              fill-rule="evenodd"
              d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
              clip-rule="evenodd"
            />
          </svg>
        </div>

        <!-- Content -->
        <div class="ml-12 flex-1">
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4 shadow-sm border border-gray-200 dark:border-gray-700">
            <div class="flex items-center justify-between mb-2">
              <h4 class="text-sm font-semibold text-gray-900 dark:text-white">
                {{ milestone.title }}
              </h4>
              <span
                :class="[
                  'text-xs px-2 py-1 rounded-full',
                  milestone.completed
                    ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                    : milestone.active
                      ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
                      : 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300'
                ]"
              >
                {{ milestone.percentage }}%
              </span>
            </div>
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-1">
              {{ milestone.description }}
            </p>
            <p class="text-xs text-gray-500 dark:text-gray-500">
              {{ milestone.date }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Summary -->
    <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
      <div class="flex items-start space-x-3">
        <svg class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
        </svg>
        <div class="flex-1">
          <h5 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-1">
            Vesting Information
          </h5>
          <p class="text-sm text-blue-700 dark:text-blue-300">
            {{ vestingSummary }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  vesting: {
    type: Object,
    required: true,
    default: () => ({
      publicSale: {
        tge: 25,
        cliff: 0,
        linear: 6,
        description: 'Public sale tokens: 25% at TGE, 75% linear over 6 months'
      },
      team: {
        tge: 0,
        cliff: 3,
        linear: 18,
        description: 'Team tokens: 3-month cliff, then linear vesting over 18 months'
      }
    })
  }
})

// Generate milestones from vesting data
const vestingMilestones = computed(() => {
  const milestones = []
  const now = new Date()

  // Add TGE milestone if applicable
  if (props.vesting.publicSale?.tge > 0) {
    milestones.push({
      title: 'Token Generation Event (TGE)',
      description: `${props.vesting.publicSale.tge}% of public sale tokens released`,
      percentage: props.vesting.publicSale.tge,
      date: 'Launch Date',
      completed: true,
      active: false
    })
  }

  // Add cliff milestone for team tokens
  if (props.vesting.team?.cliff > 0) {
    const cliffDate = new Date(now)
    cliffDate.setMonth(cliffDate.getMonth() + props.vesting.team.cliff)
    
    milestones.push({
      title: 'Team Token Cliff End',
      description: `Team tokens begin vesting after ${props.vesting.team.cliff}-month cliff`,
      percentage: 0,
      date: cliffDate.toLocaleDateString(),
      completed: false,
      active: true
    })
  }

  // Add linear vesting milestones
  if (props.vesting.publicSale?.linear > 0) {
    const linearMonths = props.vesting.publicSale.linear
    const monthlyRelease = (100 - props.vesting.publicSale.tge) / linearMonths
    
    for (let i = 1; i <= linearMonths; i++) {
      const vestingDate = new Date(now)
      vestingDate.setMonth(vestingDate.getMonth() + i)
      
      milestones.push({
        title: `Month ${i} Vesting`,
        description: `${monthlyRelease.toFixed(1)}% of public sale tokens released`,
        percentage: monthlyRelease.toFixed(1),
        date: vestingDate.toLocaleDateString(),
        completed: i <= 2, // Mock: first 2 months completed
        active: i === 3
      })
    }
  }

  return milestones.slice(0, 5) // Show max 5 milestones
})

// Generate vesting summary
const vestingSummary = computed(() => {
  const parts = []
  
  if (props.vesting.publicSale) {
    parts.push(props.vesting.publicSale.description)
  }
  
  if (props.vesting.team) {
    parts.push(props.vesting.team.description)
  }
  
  return parts.join('. ') || 'No vesting schedule defined.'
})
</script>
