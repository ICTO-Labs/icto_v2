<template>
    <UnifiedProposalTable
        :proposals="proposals"
        title="Recent Proposals"
        :show-create-button="false"
        @view-proposal="handleProposalDetails"
        @sign-proposal="handleProposalSign"
    />
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import type { Proposal } from '@/types/multisig'
import UnifiedProposalTable from '@/components/multisig/UnifiedProposalTable.vue'

// Props
interface Props {
    proposals: Proposal[]
}

const props = defineProps<Props>()
const router = useRouter()

// Emits
const emit = defineEmits<{
    refresh: []
    sign: [proposal: Proposal]
    view: [proposal: Proposal]
    execute: [proposal: Proposal]
    cancel: [proposal: Proposal]
}>()

// Event handlers for the unified table
const handleProposalDetails = (proposal: Proposal) => {
    const walletId = proposal.walletId || 'unknown'
    router.push(`/multisig/${walletId}/proposal/${proposal.id}`)
    emit('view', proposal)
}

const handleProposalSign = (proposal: Proposal) => {
    emit('sign', proposal)
}

</script>
