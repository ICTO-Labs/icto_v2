<template>
  <div class="space-y-4">
    <div
      v-for="(activity, index) in activities"
      :key="activity.id"
      class="flex gap-4 group"
    >
      <!-- Timeline line -->
      <div class="flex flex-col items-center">
        <div
          class="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ring-4 ring-white dark:ring-gray-800"
          :class="activity.iconBg"
        >
          <component :is="activity.icon" class="w-5 h-5" :class="activity.iconColor" />
        </div>
        <div
          v-if="index < activities.length - 1"
          class="w-0.5 h-full min-h-[40px] bg-gray-200 dark:bg-gray-700 mt-2"
        />
      </div>

      <!-- Content -->
      <div class="flex-1 pb-8">
        <div class="bg-white dark:bg-black/20 rounded-xl border border-gray-200 dark:border-white/5 p-4 group-hover:bg-gray-50 dark:group-hover:bg-black/30 transition-colors shadow-sm dark:shadow-none">
          <div class="flex items-start justify-between mb-2">
            <div class="flex-1">
              <h4 class="font-bold text-gray-900 dark:text-white text-sm">{{ activity.title }}</h4>
              <p class="text-xs text-gray-600 dark:text-gray-400 mt-1">{{ activity.description }}</p>
            </div>
            <span
              class="px-2 py-1 rounded-full text-xs font-bold ml-2 border border-gray-200 dark:border-white/5"
              :class="getStatusClass(activity.status)"
            >
              {{ activity.status }}
            </span>
          </div>
          <div class="flex items-center justify-between mt-3">
            <span class="text-xs text-gray-500">{{ activity.time }}</span>
            <button
              v-if="activity.actionUrl"
              class="text-xs text-[#b27c10] hover:text-[#d8a735] font-bold uppercase tracking-wide"
            >
              View Details →
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="activities.length === 0" class="text-center py-12">
      <ActivityIcon class="w-12 h-12 text-gray-400 mx-auto mb-3" />
      <p class="text-gray-500 dark:text-gray-400">No recent activities</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ActivityIcon } from 'lucide-vue-next'

interface Activity {
  id: string
  title: string
  description: string
  time: string
  status: 'completed' | 'pending' | 'active' | 'failed'
  icon: any
  iconBg: string
  iconColor: string
  actionUrl?: string
}

interface Props {
  activities: Activity[]
}

defineProps<Props>()

const getStatusClass = (status: string) => {
  const classes = {
    completed: 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400',
    pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400',
    active: 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400',
    failed: 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400'
  }
  return classes[status as keyof typeof classes] || classes.pending
}
</script>
