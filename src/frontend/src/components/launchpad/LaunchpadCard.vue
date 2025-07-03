<!-- components/launchpad/LaunchpadCard.vue -->
<script setup>
import { computed } from 'vue';
import StatusBadge from '../common/StatusBadge.vue';

const props = defineProps({
  project: {
    type: Object,
    required: true
  }
})

const progress = computed(() => {
  if (props.project.hardCap === 0n) return 0;
  return Number(props.project.raised * 100n / props.project.hardCap);
});

const formatBigInt = (n) => {
    return n.toString(); // Basic formatter
}

</script>

<template>
    <div class="bg-white dark:bg-neutral-800 rounded-xl shadow-sm border border-neutral-200 dark:border-neutral-700 hover:shadow-lg transition-all duration-200 cursor-pointer">
        <div class="p-6">
            <!-- Header -->
            <div class="flex items-center space-x-4 mb-4">
                <img :src="project.logo || '/default-project.svg'" :alt="project.name" class="w-12 h-12 rounded-full bg-gray-200"/>
                <div>
                    <h3 class="text-lg font-semibold text-neutral-900 dark:text-neutral-100">{{ project.name }}</h3>
                    <p class="text-sm text-neutral-500 dark:text-neutral-400">{{ project.tokenSymbol }}</p>
                </div>
                <div class="ml-auto">
                    <StatusBadge :status="project.status" />
                </div>
            </div>

            <!-- Description -->
            <p class="text-sm text-neutral-600 dark:text-neutral-300 h-10 overflow-hidden text-ellipsis">
                {{ project.description }}
            </p>

            <!-- Progress Bar -->
            <div class="mt-4">
                <div class="flex justify-between text-sm text-neutral-600 dark:text-neutral-300 mb-1">
                    <span>Progress</span>
                    <span class="font-medium">{{ progress }}%</span>
                </div>
                <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5">
                    <div class="bg-blue-600 h-2.5 rounded-full" :style="{ width: progress + '%' }"></div>
                </div>
                <div class="flex justify-between text-xs text-neutral-500 dark:text-neutral-400 mt-1">
                    <span>{{ formatBigInt(project.raised) }} ICP</span>
                    <span>{{ formatBigInt(project.hardCap) }} ICP</span>
                </div>
            </div>
        </div>
    </div>
</template> 