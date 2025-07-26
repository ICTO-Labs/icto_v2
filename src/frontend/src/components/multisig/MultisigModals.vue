<template>
    <!-- Multisig Modals Container -->
    <div>
        <!-- Sign Proposal Modal -->
        <SignProposalModal />
        
        <!-- Create Proposal Modal -->
        <CreateProposalModal />
        
        <!-- Create Multisig Modal -->
        <CreateMultisigModal />
        
        <!-- Manage Signers Modal -->
        <ManageSignersModal />
        
        <!-- Receive Asset Modal -->
        <ReceiveAssetModal />
    </div>
</template>

<script setup lang="ts">
import SignProposalModal from '@/modals/multisig/SignProposalModal.vue'
import CreateProposalModal from '@/modals/multisig/CreateProposalModal.vue'
import CreateMultisigModal from '@/modals/multisig/CreateMultisigModal.vue'
import ManageSignersModal from '@/modals/multisig/ManageSignersModal.vue'
import ReceiveAssetModal from '@/modals/multisig/ReceiveAssetModal.vue'
</script>
