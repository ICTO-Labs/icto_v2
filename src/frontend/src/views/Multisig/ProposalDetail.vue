<template>
    <admin-layout>
        <!-- Breadcrumb -->
        <Breadcrumb :items="breadcrumbItems" />

        <div class="gap-4 md:gap-6">
            <!-- Loading state -->
            <div v-if="loading">
                <LoadingSkeleton type="wallet-detail" />
            </div>

            <!-- Error state -->
            <div v-else-if="error" class="bg-red-50 border-l-4 border-red-400 p-4 mb-4">
                <div class="flex">
                    <div class="flex-shrink-0">
                        <svg class="h-5 w-5 text-red-400" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
                        </svg>
                    </div>
                    <div class="ml-3">
                        <p class="text-sm text-red-700">{{ error }}</p>
                    </div>
                </div>
            </div>

            <!-- Proposal content -->
            <div v-else-if="proposal && wallet">
                <!-- Header -->
                <div class="mb-8">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-4">
                            <button
                                @click="goBack"
                                class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                            >
                                <ArrowLeftIcon class="h-5 w-5" />
                            </button>
                            <div>
                                <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
                                    {{ proposal.title || 'Untitled Proposal' }}
                                </h1>
                                <div class="flex items-center space-x-4 mt-2">
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                                        :class="{
                                            'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300': normalizeStatus(proposal.status) === 'pending',
                                            'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300': normalizeStatus(proposal.status) === 'approved',
                                            'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300': normalizeStatus(proposal.status) === 'executed',
                                            'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300': normalizeStatus(proposal.status) === 'rejected' || normalizeStatus(proposal.status) === 'failed',
                                            'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300': normalizeStatus(proposal.status) === 'expired'
                                        }"
                                    >
                                        {{ getStatusDisplay(proposal.status, proposal.currentSignatures, proposal.requiredSignatures) }}
                                    </span>
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ formatProposalType(proposal.type || '') }}
                                    </span>
                                    <span class="text-sm text-gray-500 dark:text-gray-400">
                                        ID: {{ proposal.id || 'N/A' }}
                                    </span>
                                </div>
                            </div>
                        </div>
                        
                        <div class="flex items-center space-x-3">
                            <button
                                v-if="(proposal.status === 'pending' || proposal.status === 'approved') && canSign"
                                @click="openSignModal"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                            >
                                <PenIcon class="h-4 w-4 mr-2" />
                                Sign Proposal
                            </button>
                            <button
                                v-if="canExecute"
                                @click="executeProposal"
                                :disabled="executing"
                                class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
                            >
                                <PlayIcon class="h-4 w-4 mr-2" />
                                {{ executing ? 'Executing...' : 'Execute' }}
                            </button>
                            <button
                                @click="refreshData"
                                :disabled="loading"
                                class="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
                            >
                                <RefreshCcwIcon class="h-5 w-5" :class="{ 'animate-spin': loading }" />
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Proposal Overview -->
                <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 mb-8">
                    <!-- Main Content -->
                    <div class="lg:col-span-2 space-y-6">
                        <!-- Description -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Description</h3>
                            <p class="text-gray-600 dark:text-gray-400 whitespace-pre-wrap">
                                {{ proposal.description || 'No description provided.' }}
                            </p>
                        </div>

                        <!-- Transaction Details -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Transaction Details</h3>
                            
                            <div v-if="(proposal.type || '') === 'icp_transfer'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Amount</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ formatCurrency(Number(proposal.transactionData?.amount || 0) / 100000000) }} ICP
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Fee</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ formatCurrency(Number(proposal.transactionData?.fee || 10000) / 100000000) }} ICP
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Recipient</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.to }}
                                        </span>
                                        <CopyIcon :data="proposal.transactionData?.to || ''" class="w-4 h-4" />
                                    </div>
                                </div>
                                <div v-if="proposal.transactionData?.memo">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Memo</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700 p-3 rounded">
                                        {{ proposal.transactionData.memo ? proposal.transactionData.memo[0] : '-' }}
                                    </p>
                                </div>
                            </div>

                            <div v-else-if="(proposal.type || '') === 'token_transfer'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Amount</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ formatNumber(proposal.transactionData?.amount || 0) }} {{ proposal.transactionData?.symbol }}
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Token</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ proposal.transactionData?.tokenCanister }}
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Recipient</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.to }}
                                        </span>
                                        <CopyIcon :data="proposal.transactionData?.to || ''" />
                                    </div>
                                </div>
                            </div>

                            <div v-else-if="(proposal.type || '') === 'add_signer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">New Signer</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.targetSigner }}
                                        </span>
                                        <CopyIcon :data="proposal.transactionData?.targetSigner || ''" />
                                    </div>
                                </div>
                                <div v-if="proposal.transactionData?.newThreshold">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Threshold</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ proposal.transactionData?.newThreshold || 0 }}/{{ (wallet.signers?.length || 0) + 1 }} signatures required
                                    </p>
                                </div>
                            </div>

                            <div v-else-if="(proposal.type || '') === 'remove_signer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Signer to Remove</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-sm text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-1 rounded">
                                            {{ proposal.transactionData?.targetSigner }}
                                        </span>
                                        <CopyIcon :data="proposal.transactionData?.targetSigner || ''" />
                                    </div>
                                </div>
                                <div v-if="proposal.transactionData?.newThreshold">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Threshold</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ proposal.transactionData?.newThreshold || 0 }}/{{ Math.max((wallet.signers?.length || 0) - 1, 0) }} signatures required
                                    </p>
                                </div>
                            </div>

                            <div v-else-if="(proposal.type || '') === 'threshold_changed'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Current Threshold</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ wallet.config?.threshold || 0 }}/{{ wallet.signers?.length || 0 }}
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Threshold</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ proposal.transactionData?.newThreshold || 0 }}/{{ wallet.signers?.length || 0 }}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div v-else class="text-center py-4">
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    Transaction details not available for this proposal type.
                                </p>
                            </div>
                        </div>

                        <!-- Timeline -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Timeline</h3>
                            
                            <div class="flow-root">
                                <ul class="-mb-8">
                                    <!-- Proposal Created -->
                                    <li>
                                        <div class="relative pb-8">
                                            <div v-if="(proposal.signatures || []).length > 0 || (proposal.status || '') === 'executed' || (proposal.status || '') === 'failed'" class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 dark:bg-gray-600"></div>
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-blue-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <PlusIcon class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="font-medium text-gray-900 dark:text-white">{{ proposal.proposerName ? proposal.proposerName[0] : 'Unknown Proposer' }}</span>
                                                            <span class="text-gray-500 dark:text-gray-400"> created this proposal</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ proposal.proposedAt ? formatDate(proposal.proposedAt) : 'Unknown date' }}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Signatures -->
                                    <li v-for="(signature, index) in (proposal.signatures || [])" :key="signature.signer">
                                        <div class="relative pb-8">
                                            <div v-if="index < (proposal.signatures || []).length - 1 || (proposal.status || '') === 'executed' || (proposal.status || '') === 'failed'" class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200 dark:bg-gray-600"></div>
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-green-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <CheckIcon class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="font-medium text-gray-900 dark:text-white">{{ signature.signerName ? signature.signerName[0] : 'Unknown Signer' }}</span>
                                                            <span class="text-gray-500 dark:text-gray-400"> signed this proposal</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ formatDate(signature.signedAt) }}
                                                        </p>
                                                        <p v-if="signature.note" class="mt-2 text-sm text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700 p-2 rounded">
                                                            {{ signature.note }}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Execution -->
                                    <li v-if="normalizeStatus(proposal.status) === 'executed'">
                                        <div class="relative">
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-green-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <CheckIcon class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="font-medium text-gray-900 dark:text-white">Proposal executed successfully</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ proposal.executedAt ? formatDate(proposal.executedAt) : 'Recently' }}
                                                        </p>
                                                        <p v-if="proposal.executedBy" class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                                            Executed by {{ getSignerName(proposal.executedBy.toString(), wallet?.signers) ? getSignerName(proposal.executedBy.toString(), wallet?.signers)[0] : 'Unknown Signer' }}
                                                        </p>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Failed Execution -->
                                    <li v-else-if="normalizeStatus(proposal.status) === 'failed'">
                                        <div class="relative">
                                            <div class="relative flex space-x-3">
                                                <div>
                                                    <span class="h-8 w-8 rounded-full bg-red-500 flex items-center justify-center ring-8 ring-white dark:ring-gray-800">
                                                        <AlertTriangle class="h-4 w-4 text-white" />
                                                    </span>
                                                </div>
                                                <div class="flex-1 min-w-0">
                                                    <div>
                                                        <div class="text-sm">
                                                            <span class="font-medium text-red-900 dark:text-red-300">Proposal execution failed</span>
                                                        </div>
                                                        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                                                            {{ proposal.executedAt ? formatDate(proposal.executedAt) : 'Recently' }}
                                                        </p>
                                                        <p v-if="proposal.executedBy" class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                                            Attempted by {{ getSignerName(proposal.executedBy.toString(), wallet?.signers) ? getSignerName(proposal.executedBy.toString(), wallet?.signers)[0] : 'Unknown Signer' }}
                                                        </p>
                                                        <div v-if="proposal.executionResult?.error" class="mt-2 p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded">
                                                            <p class="text-xs font-medium text-red-800 dark:text-red-300">Error Details:</p>
                                                            <p class="text-xs text-red-700 dark:text-red-300 mt-1">{{ proposal.executionResult.error }}</p>
                                                        </div>
                                                        <div v-if="proposal.executionResult?.actionResults && proposal.executionResult.actionResults.length > 0" class="mt-2">
                                                            <p class="text-xs font-medium text-gray-700 dark:text-gray-300">Action Results:</p>
                                                            <ul class="mt-1 space-y-1">
                                                                <li v-for="(actionResult, idx) in proposal.executionResult.actionResults" :key="idx" class="text-xs">
                                                                    <span :class="actionResult.success ? 'text-green-600 dark:text-green-400' : 'text-red-600 dark:text-red-400'">
                                                                        Action {{ idx + 1 }}: {{ actionResult.success ? 'Success' : 'Failed' }}
                                                                    </span>
                                                                    <span v-if="!actionResult.success && actionResult.error" class="text-red-600 dark:text-red-400"> - {{ actionResult.error }}</span>
                                                                </li>
                                                            </ul>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>

                    <!-- Sidebar -->
                    <div class="space-y-6">
                        <!-- Progress -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Progress</h3>
                            
                            <div class="space-y-4">
                                <div>
                                    <div class="flex justify-between text-sm mb-2">
                                        <span class="text-gray-500 dark:text-gray-400">Signatures</span>
                                        <span class="font-medium text-gray-900 dark:text-white">
                                            {{ proposal.currentSignatures || 0 }}/{{ proposal.requiredSignatures || 0 }}
                                        </span>
                                    </div>
                                    <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                        <div 
                                            class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                                            :style="{ width: `${((Number(proposal.currentSignatures) || 0) / Math.max(Number(proposal.requiredSignatures) || 1, 1)) * 100}%` }"
                                        ></div>
                                    </div>
                                </div>
                                
                                <div class="text-center">
                                    <div v-if="normalizeStatus(proposal.status) === 'executed'" class="flex items-center justify-center space-x-2">
                                        <CheckIcon class="h-4 w-4 text-green-600 dark:text-green-400" />
                                        <p class="text-sm font-medium text-green-600 dark:text-green-400">
                                            Executed Successfully
                                        </p>
                                    </div>
                                    <div v-else-if="normalizeStatus(proposal.status) === 'failed'" class="flex items-center justify-center space-x-2">
                                        <AlertTriangle class="h-4 w-4 text-red-600 dark:text-red-400" />
                                        <p class="text-sm font-medium text-red-600 dark:text-red-400">
                                            Execution Failed
                                        </p>
                                    </div>
                                    <div v-else-if="normalizeStatus(proposal.status) === 'approved'" class="flex items-center justify-center space-x-2">
                                        <PlayIcon class="h-4 w-4 text-blue-600 dark:text-blue-400" />
                                        <p class="text-sm font-medium text-blue-600 dark:text-blue-400">
                                            Ready to Execute
                                        </p>
                                    </div>
                                    <p v-else class="text-sm text-gray-500 dark:text-gray-400">
                                        {{ (Number(proposal.requiredSignatures) || 0) - (Number(proposal.currentSignatures) || 0) }} more signature{{ ((Number(proposal.requiredSignatures) || 0) - (Number(proposal.currentSignatures) || 0)) !== 1 ? 's' : '' }} needed
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Wallet Info -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Wallet</h3>
                            
                            <div class="space-y-3">
                                <div class="flex items-center space-x-3">
                                    <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                                        <WalletIcon class="h-5 w-5 text-white" />
                                    </div>
                                    <div>
                                        <p class="font-medium text-gray-900 dark:text-white">{{ wallet.config?.name || 'Unnamed Wallet' }}</p>
                                        <p class="text-sm text-gray-500 dark:text-gray-400">
                                            {{ Number(wallet.config?.threshold || 0) }}-of-{{ Number(wallet.signers?.length || 0) }} Multisig
                                        </p>
                                    </div>
                                </div>
                                
                                <div class="pt-3 border-t border-gray-200 dark:border-gray-600">
                                    <div class="flex items-center justify-between text-sm">
                                        <span class="text-gray-500 dark:text-gray-400">Canister ID</span>
                                        <div class="flex items-center space-x-1">
                                            <span class="font-mono text-xs text-gray-900 dark:text-white">
                                                {{ (route.params.id as string) }}
                                            </span>
                                            <CopyIcon :data="route.params.id as string" class="w-4 h-4" />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Expiration -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Expiration</h3>
                            
                            <div class="text-center">
                                <p class="text-sm text-gray-500 dark:text-gray-400 mb-2">Expires on</p>
                                <p class="font-medium text-gray-900 dark:text-white">
                                    {{ proposal.expiresAt ? formatDate(proposal.expiresAt) : 'Unknown date' }}
                                </p>
                                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                    {{ proposal.expiresAt ? formatTimeAgo(proposal.expiresAt.getTime()) : 'Unknown' }}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </admin-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMultisigStore } from '@/stores/multisig'
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import { multisigService } from '@/api/services/multisig'
import { toast } from 'vue-sonner'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import {
    ArrowLeftIcon,
    PenIcon,
    PlayIcon,
    RefreshCcwIcon,
    PlusIcon,
    CheckIcon,
    WalletIcon,
    AlertTriangle
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import LoadingSkeleton from '@/components/multisig/LoadingSkeleton.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

// Stores and router
const route = useRoute()
const router = useRouter()
const multisigStore = useMultisigStore()
const modalStore = useModalStore()
const authStore = useAuthStore()

// Reactive state
const loading = ref(false)
const executing = ref(false)
const error = ref<string | null>(null)
const proposalData = ref<any>(null)
const walletData = ref<any>(null)

// Computed properties
const proposal = computed(() => {
    return proposalData.value
})

const wallet = computed(() => {
    return walletData.value
})

const canSign = computed(() => {
    if (!proposal.value || !authStore.principal || !wallet.value) {
        return false
    }
    
    const currentUserPrincipal = authStore.principal.toString()
    
    // Check if current user is a signer (Owner or Signer role)
    const hasSignerAccess = wallet.value?.signers?.some((s: any) => {
        const signerPrincipal = s.principal?.toString() || s.toString()
        const isOwner = s.role && typeof s.role === 'object' && 'Owner' in s.role
        const isSigner = s.role && typeof s.role === 'object' && 'Signer' in s.role
        const canSignRole = isOwner || isSigner
        
        return signerPrincipal === currentUserPrincipal && canSignRole
    })
    
    // Check if already signed
    const alreadySigned = proposal.value.signatures?.some((s: any) => {
        const signerPrincipal = s.signer?.toString() || s.toString()
        return signerPrincipal === currentUserPrincipal
    })
    
    return hasSignerAccess && !alreadySigned && (proposal.value.status === 'pending' || proposal.value.status === 'approved')
})

const canExecute = computed(() => {
    if (!proposal.value || !wallet.value) return false
    const currentSigs = Number(proposal.value.currentSignatures || proposal.value.signatures?.length || 0)
    const requiredSigs = Number(wallet.value.config?.threshold || 0)
    // Allow execution when we have enough signatures and status is approved or pending (with enough sigs)
    const hasEnoughSignatures = currentSigs >= requiredSigs
    const canExecuteStatus = proposal.value.status === 'approved' ||
                           (proposal.value.status === 'pending' && hasEnoughSignatures)
    return hasEnoughSignatures && canExecuteStatus
})

// Breadcrumb
const breadcrumbItems = computed(() => [
    { label: 'Multisig Wallets', to: '/multisig' },
    { label: wallet.value?.config?.name || 'Wallet', to: `/multisig/${route.params.id}` },
    { label: 'Proposals', to: `/multisig/${route.params.id}/proposals` },
    { label: proposal.value?.title || `Proposal ${route.params.proposalId}` }
])

// Methods
const loadProposalData = async () => {
    loading.value = true
    error.value = null

    try {
        const proposalId = route.params.proposalId as string
        const canisterId = route.params.id as string // This is canisterId, not walletId

        if (!proposalId || !canisterId) {
            error.value = 'Invalid proposal or canister ID'
            return
        }

        // Load wallet data first
        const walletResult = await multisigService.getWalletInfo(canisterId)
        if (!walletResult.success) {
            error.value = walletResult.error || 'Wallet not found'
            return
        }

        // Parse numbers and ensure proper data format
        const walletInfo = walletResult.data
        if (walletInfo.config?.threshold) {
            walletInfo.config.threshold = Number(walletInfo.config.threshold)
        }

        walletData.value = walletInfo

        // Load specific proposal
        const proposalResult = await multisigService.getProposal(canisterId, proposalId)
        if (!proposalResult.success) {
            error.value = proposalResult.error || 'Proposal not found'
            return
        }

        // Parse and format proposal data
        const proposal = proposalResult.data[0] || proposalResult.data

        // Handle different proposal types based on Motoko contract structure
        if (proposal.proposalType) {
            // Extract transaction data from proposalType based on Motoko structure
            switch (true) {
                case 'Transfer' in proposal.proposalType:
                    const transferData = proposal.proposalType.Transfer
                    if (transferData.asset && 'ICP' in transferData.asset) {
                        proposal.type = 'icp_transfer'
                        proposal.transactionData = {
                            to: transferData.recipient.toString(),
                            amount: Number(transferData.amount) * 100000000, // Convert to e8s (ICP base unit)
                            fee: 10000, // Default ICP fee in e8s
                            memo: transferData.memo
                        }
                    } else if (transferData.asset && 'Token' in transferData.asset) {
                        proposal.type = 'token_transfer'
                        proposal.transactionData = {
                            to: transferData.recipient.toString(),
                            amount: Number(transferData.amount),
                            tokenCanister: transferData.asset.Token.toString(),
                            symbol: 'Token', // Default symbol
                            memo: transferData.memo
                        }
                    }
                    break
                case 'WalletModification' in proposal.proposalType:
                    const modData = proposal.proposalType.WalletModification
                    if ('AddSigner' in modData.modificationType) {
                        proposal.type = 'add_signer'
                        proposal.transactionData = {
                            targetSigner: modData.modificationType.AddSigner.signer.toString(),
                            newThreshold: walletInfo.config?.threshold
                        }
                    } else if ('RemoveSigner' in modData.modificationType) {
                        proposal.type = 'remove_signer'
                        proposal.transactionData = {
                            targetSigner: modData.modificationType.RemoveSigner.signer.toString(),
                            newThreshold: Math.max((walletInfo.signers?.length || 0) - 1, 1)
                        }
                    } else if ('ChangeThreshold' in modData.modificationType) {
                        proposal.type = 'threshold_changed'
                        proposal.transactionData = {
                            newThreshold: Number(modData.modificationType.ChangeThreshold.newThreshold)
                        }
                    }
                    break
                default:
                    proposal.type = 'unknown'
                    proposal.transactionData = {}
            }
        }

        // Parse timestamps
        if (proposal.proposedAt) {
            proposal.proposedAt = new Date(Number(proposal.proposedAt) / 1000000) // Convert nanoseconds to milliseconds
        }
        if (proposal.expiresAt) {
            proposal.expiresAt = new Date(Number(proposal.expiresAt) / 1000000)
        }
        if (proposal.executedAt) {
            proposal.executedAt = new Date(Number(proposal.executedAt) / 1000000)
        }

        // Parse signature data from approvals array
        if (proposal.approvals && proposal.approvals.length > 0) {
            proposal.signatures = proposal.approvals.map((approval: any) => ({
                signer: approval.signer.toString(),
                signerName: getSignerName(approval.signer.toString(), walletInfo.signers),
                signedAt: approval.approvedAt ? new Date(Number(approval.approvedAt) / 1000000) : new Date(),
                note: Array.isArray(approval.note) && approval.note.length > 0 ? approval.note[0] : (approval.note || null)
            }))
        } else {
            proposal.signatures = []
        }

        // Convert proposer to string and get name
        if (proposal.proposer) {
            proposal.proposerName = getSignerName(proposal.proposer.toString(), walletInfo.signers)
            proposal.proposer = proposal.proposer.toString()
        }

        // Parse status from Motoko variant first (handle both object and string formats)
        if (proposal.status) {
            if (typeof proposal.status === 'object') {
                if ('Pending' in proposal.status) {
                    proposal.status = 'pending'
                } else if ('Approved' in proposal.status) {
                    proposal.status = 'approved'
                } else if ('Executed' in proposal.status) {
                    proposal.status = 'executed'
                } else if ('Rejected' in proposal.status) {
                    proposal.status = 'rejected'
                } else if ('Expired' in proposal.status) {
                    proposal.status = 'expired'
                } else if ('Failed' in proposal.status) {
                    proposal.status = 'failed'
                }
            } else if (typeof proposal.status === 'string') {
                // Already in string format, convert to lowercase
                proposal.status = proposal.status.toLowerCase()
            }
        }

        // Calculate signatures count from approvals
        proposal.currentSignatures = Number(proposal.currentApprovals || proposal.approvals?.length || 0)
        // Always use wallet threshold as required signatures, not what backend calculated
        proposal.requiredSignatures = Number(walletInfo.config?.threshold || 0)

        // Fix status logic - only mark as approved if we have enough signatures based on wallet threshold
        if (proposal.status === 'approved' && Number(proposal.currentSignatures) < Number(proposal.requiredSignatures)) {
            proposal.status = 'pending'
        }

        proposalData.value = proposal

    } catch (err) {
        console.error('Error loading proposal data:', err)
        error.value = 'Failed to load proposal data'
    } finally {
        loading.value = false
    }
}

// Helper function to get signer name from signers list
const getSignerName = (signerPrincipal: string, signers: any[]): string => {
    const signer = signers?.find(s => {
        const sPrincipal = s.principal?.toString() || s.toString()
        return sPrincipal === signerPrincipal
    })

    if (signer?.name) {
        return signer.name
    }

    // Check if it's an owner
    const isOwner = signer?.role && typeof signer.role === 'object' && 'Owner' in signer.role
    const rolePrefix = isOwner ? 'Owner' : 'Signer'

    return `${rolePrefix} ${signerPrincipal.slice(0, 8)}...`
}

const refreshData = () => {
    loadProposalData()
}

const goBack = () => {
    const canisterId = route.params.id as string
    router.push(`/multisig/${canisterId}`)
}

const openSignModal = () => {
    if (proposal.value && wallet.value) {
        modalStore.open('signProposal', {
            proposal: proposal.value,
            wallet: wallet.value,
            canisterId: route.params.id as string
        })
    }
}

const executeProposal = async () => {
    if (!proposal.value || !canExecute.value) return

    executing.value = true
    try {
        const toastId = toast.loading('Executing proposal...', {
            description: 'Please wait while the proposal is being executed'
        })

        const canisterId = route.params.id as string
        const result = await multisigService.executeProposal(canisterId, proposal.value.id)

        if (result.success) {
            toast.success('Proposal executed successfully!', {
                id: toastId,
                description: 'The proposal has been executed'
            })
            refreshData()
        } else {
            toast.error('Failed to execute proposal', {
                id: toastId,
                description: result.error || 'An unexpected error occurred'
            })
        }
    } catch (error) {
        console.error('Error executing proposal:', error)
        toast.error('Failed to execute proposal', {
            description: error instanceof Error ? error.message : 'An unexpected error occurred'
        })
    } finally {
        executing.value = false
    }
}

const formatProposalType = (type: string) => {
    const typeMap: Record<string, string> = {
        'icp_transfer': 'ICP Transfer',
        'token_transfer': 'Token Transfer',
        'add_signer': 'Add Signer',
        'remove_signer': 'Remove Signer',
        'threshold_changed': 'Change Threshold',
        'governance_vote': 'Governance Vote'
    }
    return typeMap[type] || type.replace('_', ' ').toUpperCase()
}

// Helper function to normalize status
const normalizeStatus = (status: any): string => {
    if (!status) return 'unknown'

    if (typeof status === 'string') {
        return status.toLowerCase()
    }

    if (typeof status === 'object') {
        // Handle Motoko variant objects
        if ('Pending' in status) return 'pending'
        if ('Approved' in status) return 'approved'
        if ('Executed' in status) return 'executed'
        if ('Failed' in status) return 'failed'
        if ('Rejected' in status) return 'rejected'
        if ('Expired' in status) return 'expired'
    }

    return String(status).toLowerCase()
}

const getStatusDisplay = (status: any, currentSigs: number, requiredSigs: number) => {
    const statusStr = normalizeStatus(status)

    if (statusStr === 'pending') {
        return `Pending (${currentSigs}/${requiredSigs})`
    }
    if (statusStr === 'approved') {
        if (currentSigs >= requiredSigs) {
            return 'Ready to Execute'
        } else {
            return `Pending (${currentSigs}/${requiredSigs})`
        }
    }
    if (statusStr === 'executed') {
        return 'Executed'
    }
    if (statusStr === 'failed') {
        return 'Execution Failed'
    }
    if (statusStr === 'rejected') {
        return 'Rejected'
    }
    if (statusStr === 'expired') {
        return 'Expired'
    }
    return statusStr ? statusStr.charAt(0).toUpperCase() + statusStr.slice(1) : 'Unknown'
}

// Watch for route changes
watch(() => route.params.proposalId, loadProposalData, { immediate: true })

onMounted(() => {
    loadProposalData()
    
    // Listen for proposal signed event to refresh data
    const handleProposalSigned = (event: CustomEvent) => {
        const { proposalId, canisterId } = event.detail
        const currentProposalId = route.params.proposalId as string
        const currentCanisterId = route.params.id as string

        if (proposalId === currentProposalId && canisterId === currentCanisterId) {
            loadProposalData()
        }
    }
    
    window.addEventListener('proposal-signed', handleProposalSigned as EventListener)
    
    onUnmounted(() => {
        window.removeEventListener('proposal-signed', handleProposalSigned as EventListener)
    })
})
</script>
