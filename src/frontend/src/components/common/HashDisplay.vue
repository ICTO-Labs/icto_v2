<!-- components/common/HashDisplay.vue -->
<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  hash: string
  type: 'transaction' | 'canister' | 'principal'
}>()

const shortHash = computed(() => {
  if (!props.hash) return ''
  return `${props.hash.slice(0, 6)}...${props.hash.slice(-4)}`
});

function copyToClipboard() {
    navigator.clipboard.writeText(props.hash);
    // TODO: Add a toast notification for better UX
    console.log("Copied to clipboard:", props.hash);
}

const externalLink = computed(() => {
    if (props.type === 'canister') {
        return `https://dashboard.internetcomputer.org/canister/${props.hash}`;
    }
    // TODO: Add links for other types like principal on icscan.io
    return '#';
})

</script>

<template>
  <div class="flex items-center space-x-2">
    <span class="font-mono text-sm">{{ shortHash }}</span>
    <button @click="copyToClipboard" class="text-gray-500 hover:text-gray-700">
      [Copy]
    </button>
    <a 
      v-if="type === 'canister'"
      :href="externalLink"
      target="_blank"
      class="text-blue-500 hover:text-blue-700"
    >
      [Link]
    </a>
  </div>
</template> 