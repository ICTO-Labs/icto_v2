<template>
    <div 
        v-if="launchpadInfo"
        class="inline-flex items-center gap-2 px-3 py-0.5 bg-gradient-to-r from-purple-500/10 to-pink-500/10 border border-purple-500/30 rounded-md cursor-pointer hover:border-purple-500/50 transition-all"
        @click="goToLaunchpad"
    >
        <RocketIcon class="w-4 h-4 text-purple-500" />
        <span class="text-xs font-medium text-purple-600 dark:text-purple-400">
            Launchpad Token
        </span>
        <ChevronRightIcon class="w-3 h-3 text-purple-500/70" />
    </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { RocketIcon, ChevronRightIcon } from 'lucide-vue-next'
import type { LaunchpadInfo } from '@/api/services/launchpadFactory'

const props = defineProps<{
    launchpadInfo: LaunchpadInfo | null
}>()

const router = useRouter()

const goToLaunchpad = () => {
    if (props.launchpadInfo) {
        router.push(`/launchpad/${props.launchpadInfo.canisterId.toString()}`)
    }
}
</script>
