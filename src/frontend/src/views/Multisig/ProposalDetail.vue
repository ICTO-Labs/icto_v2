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
                            
                            <!-- Transfer Proposals (ICP & Token) -->
                            <div v-if="getProposalTypeKey(proposal) === 'transfer'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Amount</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ getFormattedTransferAmount(proposal) }}
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Fee</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ getTransferFee(proposal) }}
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Recipient</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-xs text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-2 rounded break-all">
                                            {{ getFormattedRecipient(proposal) }}
                                        </span>
                                        <CopyIcon :data="getFormattedRecipient(proposal) || ''" class="w-4 h-4 flex-shrink-0" />
                                    </div>
                                </div>
                                <div v-if="getTransferMemo(proposal)">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Memo</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400 bg-gray-50 dark:bg-gray-700 p-3 rounded">
                                        {{ getTransferMemo(proposal) }}
                                    </p>
                                </div>
                            </div>

                            <!-- Add Signer Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'add_signer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">New Signer</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-xs text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-2 rounded break-all">
                                            {{ getFormattedTarget(proposal) }}
                                        </span>
                                        <CopyIcon :data="getFormattedTarget(proposal) || ''" class="w-4 h-4 flex-shrink-0" />
                                    </div>
                                </div>
                                <div v-if="getSignerNameUtil(proposal)">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Signer Name</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ getSignerNameUtil(proposal) }}
                                    </p>
                                </div>
                                <div v-if="getSignerRole(proposal)">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Role</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ getSignerRole(proposal) }}
                                    </p>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        Will increase wallet signers to {{ (wallet.signers?.length || 0) + 1 }} total
                                    </p>
                                </div>
                            </div>

                            <!-- Remove Signer Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'remove_signer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Signer to Remove</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-xs text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-2 rounded break-all">
                                            {{ getFormattedTarget(proposal) }}
                                        </span>
                                        <CopyIcon :data="getFormattedTarget(proposal) || ''" class="w-4 h-4 flex-shrink-0" />
                                    </div>
                                </div>
                                <div v-if="getSignerNameUtil(proposal)">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Signer Name</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ getSignerNameUtil(proposal) }}
                                    </p>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        Will reduce wallet signers to {{ Math.max((wallet.signers?.length || 0) - 1, 0) }} total
                                    </p>
                                </div>
                            </div>

                            <!-- Add Observer Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'add_observer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">New Observer</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-xs text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-2 rounded break-all">
                                            {{ getFormattedTarget(proposal) }}
                                        </span>
                                        <CopyIcon :data="getFormattedTarget(proposal) || ''" class="w-4 h-4 flex-shrink-0" />
                                    </div>
                                </div>
                                <div v-if="getSignerNameUtil(proposal)">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Observer Name</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ getSignerNameUtil(proposal) }}
                                    </p>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        Observer can view wallet activity but cannot sign proposals
                                    </p>
                                </div>
                            </div>

                            <!-- Remove Observer Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'remove_observer'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400 mb-2">Observer to Remove</label>
                                    <div class="flex items-center space-x-2">
                                        <span class="font-mono text-xs text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-3 py-2 rounded break-all">
                                            {{ getFormattedTarget(proposal) }}
                                        </span>
                                        <CopyIcon :data="getFormattedTarget(proposal) || ''" class="w-4 h-4 flex-shrink-0" />
                                    </div>
                                </div>
                                <div v-if="getSignerNameUtil(proposal)">
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Observer Name</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ getSignerNameUtil(proposal) }}
                                    </p>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        Observer will lose view access to wallet activity
                                    </p>
                                </div>
                            </div>

                            <!-- Change Visibility Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'change_visibility'" class="space-y-4">
                                <div class="grid grid-cols-2 gap-4">
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Current Visibility</label>
                                        <p class="text-sm text-gray-600 dark:text-gray-400">
                                            {{ wallet.config?.isPublic ? 'Public' : 'Private' }}
                                        </p>
                                    </div>
                                    <div>
                                        <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">New Visibility</label>
                                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                            {{ getVisibilityChange(proposal) ? 'Public' : 'Private' }}
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ getVisibilityChange(proposal) ? 'Wallet will be visible to all users' : 'Wallet will be private and only accessible to signers' }}
                                    </p>
                                </div>
                            </div>

                            <!-- Change Threshold Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'threshold_changed'" class="space-y-4">
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
                                            {{ getThresholdChange(proposal).newThreshold || 0 }}/{{ wallet.signers?.length || 0 }}
                                        </p>
                                    </div>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        {{ (getThresholdChange(proposal).newThreshold || 0) > (wallet.config?.threshold || 0) ? 'More signatures required for proposal execution' : 'Fewer signatures required for proposal execution' }}
                                    </p>
                                </div>
                            </div>

                            <!-- Governance Vote Proposal -->
                            <div v-else-if="getProposalTypeKey(proposal) === 'governance_vote'" class="space-y-4">
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Governance Action</label>
                                    <p class="text-lg font-semibold text-gray-900 dark:text-white">
                                        Governance Vote
                                    </p>
                                </div>
                                <div>
                                    <label class="block text-sm font-medium text-gray-500 dark:text-gray-400">Impact</label>
                                    <p class="text-sm text-gray-600 dark:text-gray-400">
                                        This proposal will participate in governance voting
                                    </p>
                                </div>
                            </div>

                            <div v-else class="text-center py-4">
                                <p class="text-sm text-gray-500 dark:text-gray-400">
                                    Transaction details not available for this proposal type.
                                </p>
                            </div>
                        </div>

                        <!-- Timeline -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">Timeline</h3>

                            <div class="flow-root">
                                <ul class="space-y-6">
                                    <!-- Proposal Created -->
                                    <li>
                                        <div class="relative">
                                            <div v-if="(proposal.signatures || []).length > 0 || (proposal.status || '') === 'executed' || (proposal.status || '') === 'failed'" class="absolute top-10 left-6 -ml-px h-full w-0.5 bg-gradient-to-b from-blue-200 to-transparent dark:from-blue-800"></div>
                                            <div class="relative flex items-start space-x-4">
                                                <div class="flex-shrink-0">
                                                    <div class="h-12 w-12 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center ring-4 ring-white dark:ring-gray-800 shadow-lg">
                                                        <PlusIcon class="h-5 w-5 text-white" />
                                                    </div>
                                                </div>
                                                <div class="flex-1 min-w-0 bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
                                                    <div class="flex items-center justify-between mb-2">
                                                        <div class="text-sm font-medium text-gray-900 dark:text-white">
                                                            Proposal Created
                                                        </div>
                                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">
                                                            {{ formatProposalType(proposal.type || '') }}
                                                        </span>
                                                    </div>
                                                    <div class="text-sm text-gray-600 dark:text-gray-300 mb-2">
                                                        <span class="font-medium">{{ proposal.proposerName ? proposal.proposerName[0] : proposal.proposer || 'Unknown Proposer' }}</span>
                                                        created this proposal
                                                    </div>
                                                    <div class="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
                                                        <span>{{ proposal.proposedAt ? formatDateTime(proposal.proposedAt) : 'Unknown date' }}</span>
                                                        <span>{{ proposal.proposedAt ? formatTimeAgo(proposal.proposedAt.getTime()) : '' }}</span>
                                                    </div>
                                                    <!-- Proposal details summary -->
                                                    <div class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-600">
                                                        <div class="text-xs text-gray-600 dark:text-gray-400">
                                                            <div v-if="getProposalTypeKey(proposal) === 'transfer'" class="flex items-center space-x-2">
                                                                <CoinsIcon class="h-4 w-4" />
                                                                <span>{{ getFormattedTransferAmount(proposal) }} → <span class="font-mono text-xs">{{ getFormattedRecipient(proposal) }}</span></span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'add_signer'" class="flex items-center space-x-2">
                                                                <UserPlusIcon class="h-4 w-4" />
                                                                <span>Add <span class="font-medium text-gray-900 dark:text-white">{{ getSignerNameUtil(proposal) || '' }}</span> <span class="font-mono text-xs">{{ getFormattedTarget(proposal) }}</span></span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'remove_signer'" class="flex items-center space-x-2">
                                                                <UserMinusIcon class="h-4 w-4" />
                                                                <span>Remove <span class="font-mono text-xs">{{ getFormattedTarget(proposal) }}</span></span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'add_observer'" class="flex items-center space-x-2">
                                                                <UserPlusIcon class="h-4 w-4" />
                                                                <span>Add Observer <span class="font-medium text-gray-900 dark:text-white">{{ getSignerNameUtil(proposal) || '' }}</span> <span class="font-mono text-xs">{{ getFormattedTarget(proposal) }}</span></span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'remove_observer'" class="flex items-center space-x-2">
                                                                <UserMinusIcon class="h-4 w-4" />
                                                                <span>Remove Observer <span class="font-mono text-xs">{{ getFormattedTarget(proposal) }}</span></span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'change_visibility'" class="flex items-center space-x-2">
                                                                <SettingsIcon class="h-4 w-4" />
                                                                <span>Change visibility to {{ getVisibilityChange(proposal) ? 'Public' : 'Private' }}</span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'threshold_changed'" class="flex items-center space-x-2">
                                                                <LockIcon class="h-4 w-4" />
                                                                <span>Change threshold to {{ getThresholdChange(proposal).newThreshold || 0 }}</span>
                                                            </div>
                                                            <div v-else-if="getProposalTypeKey(proposal) === 'governance_vote'" class="flex items-center space-x-2">
                                                                <VoteIcon class="h-4 w-4" />
                                                                <span>Governance Vote</span>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Signatures -->
                                    <li v-for="(signature, index) in (proposal.signatures || [])" :key="signature.signer">
                                        <div class="relative">
                                            <div v-if="index < (proposal.signatures || []).length - 1 || (proposal.status || '') === 'executed' || (proposal.status || '') === 'failed'" class="absolute top-10 left-6 -ml-px h-full w-0.5 bg-gradient-to-b from-green-200 to-transparent dark:from-green-800"></div>
                                            <div class="relative flex items-start space-x-4">
                                                <div class="flex-shrink-0">
                                                    <div class="h-12 w-12 rounded-full bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center ring-4 ring-white dark:ring-gray-800 shadow-lg">
                                                        <CheckIcon class="h-5 w-5 text-white" />
                                                    </div>
                                                </div>
                                                <div class="flex-1 min-w-0 bg-green-30 dark:bg-green-900/50 rounded-lg p-4 border border-green-200 dark:border-green-800">
                                                    <div class="flex items-center justify-between mb-2">
                                                        <div class="text-sm  text-green-900 dark:text-green-100">
                                                            <span class="font-medium">{{ signature.signerName ? signature.signerName[0] : signature.signer || 'Unknown Signer' }}</span>
                                                            signed this proposal (Signature #{{index + 1}})
                                                        </div>
                                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
                                                            Approved
                                                        </span>
                                                    </div>
                                                    <div class="flex items-center justify-between text-xs text-green-600 dark:text-green-400 mb-2">
                                                        <span>{{ formatDateTime(signature.signedAt) }}</span>
                                                        <span>{{ formatTimeAgo(signature.signedAt.getTime()) }}</span>
                                                    </div>
                                                    <div v-if="signature.note" class="mt-2 pt-2 border-t border-green-200 dark:border-green-700">
                                                        <div class="text-xs text-green-600 dark:text-green-400 font-medium mb-1">Note:</div>
                                                        <div class="text-sm text-green-700 dark:text-green-200 ">
                                                            "{{ signature.note }}"
                                                        </div>
                                                    </div>
                                                    <div class="text-xs mt-2 text-green-600 dark:text-green-400 font-mono bg-green-100 dark:bg-green-900/30 p-2 rounded border">
                                                        Signer: {{ signature.signerName ? signature.signer: signature.signer || 'Unknown Signer' }}
                                                    </div>

                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Execution -->
                                    <li v-if="normalizeStatus(proposal.status) === 'executed'">
                                        <div class="relative">
                                            <div class="relative flex items-start space-x-4">
                                                <div class="flex-shrink-0">
                                                    <div class="h-12 w-12 rounded-full bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center ring-4 ring-white dark:ring-gray-800 shadow-lg">
                                                        <CheckIcon class="h-5 w-5 text-white" />
                                                    </div>
                                                </div>
                                                <div class="flex-1 min-w-0 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg p-4 border border-emerald-200 dark:border-emerald-800">
                                                    <div class="flex items-center justify-between mb-2">
                                                        <div class="text-sm font-medium text-emerald-900 dark:text-emerald-100">
                                                            🎉 Proposal Executed Successfully
                                                        </div>
                                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-300">
                                                            Completed
                                                        </span>
                                                    </div>
                                                    <div class="text-sm text-emerald-700 dark:text-emerald-200 mb-2">
                                                        The proposal has been successfully executed
                                                    </div>
                                                    <div class="flex items-center justify-between text-xs text-emerald-600 dark:text-emerald-400 mb-2">
                                                        <span>{{ proposal.executedAt ? formatDateTime(proposal.executedAt) : 'Recently' }}</span>
                                                        <span>{{ proposal.executedAt ? formatTimeAgo(proposal.executedAt.getTime()) : '' }}</span>
                                                    </div>
                                                    <div v-if="proposal.executedBy" class="text-xs text-emerald-600 dark:text-emerald-400 font-mono bg-emerald-100 dark:bg-emerald-900/30 p-2 rounded border mb-3">
                                                        Executed by: {{ (proposal.executedBy.toString()) }}
                                                    </div>
                                                    <!-- Show transaction result details -->
                                                    <div v-if="proposal.type === 'icp_transfer' && proposal.transactionData" class="mt-3 pt-3 border-t border-emerald-200 dark:border-emerald-700">
                                                        <div class="text-xs text-emerald-600 dark:text-emerald-400 font-medium mb-2">🔗 Transaction Details:</div>
                                                        <div class="space-y-1 text-xs text-emerald-700 dark:text-emerald-200">
                                                            <div>✅ {{ formatCurrency((typeof proposal.transactionData.amount === 'bigint' ? Number(proposal.transactionData.amount) : Number(proposal.transactionData.amount || 0)) / 100000000) }} ICP transferred</div>
                                                            <div>📨 To: <span class="font-mono text-xs">{{ proposal.transactionData.to }}</span></div>
                                                            <div v-if="proposal.transactionData.memo">📝 Memo: {{ proposal.transactionData.memo }}</div>
                                                        </div>
                                                    </div>
                                                    <div v-else-if="proposal.type === 'add_signer' && proposal.transactionData" class="mt-3 pt-3 border-t border-emerald-200 dark:border-emerald-700">
                                                        <div class="text-xs text-emerald-600 dark:text-emerald-400 font-medium mb-2 flex items-center space-x-2"><UserPlusIcon class="h-4 w-4 mr-2" /> Signer Management:</div>
                                                        <div class="space-y-1 text-xs text-emerald-700 dark:text-emerald-200">
                                                            <div class="flex items-center space-x-2"><CheckIcon class="h-4 w-4 mr-2" /> New signer added successfully</div>
                                                            <div class="flex items-center space-x-2"><UserPlusIcon class="h-4 w-4 mr-2" /> Signer: <span class="font-mono text-xs">{{ proposal.transactionData.targetSigner || 'Unknown Signer' }}</span></div>
                                                            <div class="flex items-center space-x-2"><LockIcon class="h-4 w-4 mr-2" /> Wallet threshold updated</div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </li>

                                    <!-- Failed Execution -->
                                    <li v-else-if="normalizeStatus(proposal.status) === 'failed'">
                                        <div class="relative">
                                            <div class="relative flex items-start space-x-4">
                                                <div class="flex-shrink-0">
                                                    <div class="h-12 w-12 rounded-full bg-gradient-to-br from-red-500 to-red-600 flex items-center justify-center ring-4 ring-white dark:ring-gray-800 shadow-lg">
                                                        <AlertTriangle class="h-5 w-5 text-white" />
                                                    </div>
                                                </div>
                                                <div class="flex-1 min-w-0 bg-red-50 dark:bg-red-900/20 rounded-lg p-4 border border-red-200 dark:border-red-800">
                                                    <div class="flex items-center justify-between mb-2">
                                                        <div class="text-sm font-medium text-red-900 dark:text-red-100">
                                                            ❌ Execution Failed
                                                        </div>
                                                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">
                                                            ⚠️ Failed
                                                        </span>
                                                    </div>
                                                    <div class="text-sm text-red-700 dark:text-red-200 mb-2">
                                                        The proposal execution encountered an error
                                                    </div>
                                                    <div class="flex items-center justify-between text-xs text-red-600 dark:text-red-400 mb-2">
                                                        <span>{{ proposal.executedAt ? formatDateTime(proposal.executedAt) : 'Recently' }}</span>
                                                        <span>{{ proposal.executedAt ? formatTimeAgo(proposal.executedAt.getTime()) : '' }}</span>
                                                    </div>
                                                    <div v-if="proposal.executedBy" class="text-xs text-red-600 dark:text-red-400 font-mono bg-red-100 dark:bg-red-900/30 p-2 rounded border mb-3">
                                                        Attempted by: {{ (proposal.executedBy.toString()) }}
                                                    </div>

                                                    <!-- Error Details -->
                                                    <div v-if="proposal.executionResult?.error" class="mt-3 pt-3 border-t border-red-200 dark:border-red-700">
                                                        <div class="text-xs text-red-600 dark:text-red-400 font-medium mb-2">🚫 Error Details:</div>
                                                        <div class="text-xs text-red-700 dark:text-red-200 bg-red-100 dark:bg-red-900/30 p-3 rounded border font-mono">
                                                            {{ proposal.executionResult.error }}
                                                        </div>
                                                    </div>

                                                    <!-- Action Results -->
                                                    <div v-if="proposal.executionResult?.actionResults && proposal.executionResult.actionResults.length > 0" class="mt-3 pt-3 border-t border-red-200 dark:border-red-700">
                                                        <div class="text-xs text-red-600 dark:text-red-400 font-medium mb-2">📋 Action Results:</div>
                                                        <div class="space-y-2">
                                                            <div v-for="(actionResult, idx) in proposal.executionResult.actionResults" :key="idx"
                                                                class="text-xs p-2 rounded border"
                                                                :class="actionResult.success ? 'bg-green-100 border-green-200 text-green-700 dark:bg-green-900/20 dark:border-green-800 dark:text-green-300' : 'bg-red-100 border-red-200 text-red-700 dark:bg-red-900/20 dark:border-red-800 dark:text-red-300'"
                                                            >
                                                                <div class="font-medium mb-1">
                                                                    {{ actionResult.success ? '✅' : '❌' }} Action {{ idx + 1 }}: {{ actionResult.success ? 'Success' : 'Failed' }}
                                                                </div>
                                                                <div v-if="!actionResult.success && actionResult.error" class="font-mono text-xs">
                                                                    {{ actionResult.error }}
                                                                </div>
                                                            </div>
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
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-6">Status</h3>

                            <div class="space-y-6">
                                <!-- Status Badge -->
                                <div class="text-center">
                                    <div v-if="normalizeStatus(proposal.status) === 'executed'" class="inline-flex items-center justify-center space-x-2 bg-green-50 dark:bg-green-900/20 text-green-700 dark:text-green-300 px-4 py-2 rounded-full border border-green-200 dark:border-green-800">
                                        <CheckIcon class="h-4 w-4" />
                                        <span class="text-sm font-medium">Executed Successfully</span>
                                    </div>
                                    <div v-else-if="normalizeStatus(proposal.status) === 'failed'" class="inline-flex items-center justify-center space-x-2 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-300 px-4 py-2 rounded-full border border-red-200 dark:border-red-800">
                                        <AlertTriangle class="h-4 w-4" />
                                        <span class="text-sm font-medium">Execution Failed</span>
                                    </div>
                                    <div v-else-if="normalizeStatus(proposal.status) === 'approved'" class="inline-flex items-center justify-center space-x-2 bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 px-4 py-2 rounded-full border border-blue-200 dark:border-blue-800">
                                        <PlayIcon class="h-4 w-4" />
                                        <span class="text-sm font-medium">Ready to Execute</span>
                                    </div>
                                    <div v-else-if="normalizeStatus(proposal.status) === 'expired'" class="inline-flex items-center justify-center space-x-2 bg-gray-50 dark:bg-gray-900/20 text-gray-700 dark:text-gray-300 px-4 py-2 rounded-full border border-gray-200 dark:border-gray-800">
                                        <AlertTriangle class="h-4 w-4" />
                                        <span class="text-sm font-medium">Expired</span>
                                    </div>
                                    <div v-else class="inline-flex items-center justify-center space-x-2 bg-yellow-50 dark:bg-yellow-900/20 text-yellow-700 dark:text-yellow-300 px-4 py-2 rounded-full border border-yellow-200 dark:border-yellow-800">
                                        <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20">
                                            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd" />
                                        </svg>
                                        <span class="text-sm font-medium">Awaiting Signatures</span>
                                    </div>
                                </div>

                                <!-- Signatures Progress -->
                                <div class="space-y-3">
                                    <div class="flex justify-between items-center">
                                        <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Signatures Collected</span>
                                        <span class="text-sm font-bold text-gray-900 dark:text-white">
                                            {{ proposal.currentSignatures || 0 }}/{{ proposal.requiredSignatures || 0 }}
                                        </span>
                                    </div>

                                    <!-- Enhanced Progress Bar -->
                                    <div class="relative">
                                        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3 overflow-hidden">
                                            <div
                                                class="h-3 rounded-full transition-all duration-500 ease-out relative overflow-hidden"
                                                :class="{
                                                    'bg-gradient-to-r from-green-500 to-green-600': normalizeStatus(proposal.status) === 'executed',
                                                    'bg-gradient-to-r from-red-500 to-red-600': normalizeStatus(proposal.status) === 'failed',
                                                    'bg-gradient-to-r from-blue-500 to-blue-600': normalizeStatus(proposal.status) === 'approved' || (Number(proposal.currentSignatures) >= Number(proposal.requiredSignatures)),
                                                    'bg-gradient-to-r from-yellow-500 to-yellow-600': normalizeStatus(proposal.status) === 'pending'
                                                }"
                                                :style="{ width: `${Math.min(((Number(proposal.currentSignatures) || 0) / Math.max(Number(proposal.requiredSignatures) || 1, 1)) * 100, 100)}%` }"
                                            >
                                                <div class="absolute inset-0 bg-white/20 animate-pulse"></div>
                                            </div>
                                        </div>

                                        <!-- Progress markers -->
                                        <div class="absolute top-0 left-0 w-full h-3 flex justify-between items-center px-1">
                                            <div v-for="i in Number(proposal.requiredSignatures)" :key="i"
                                                class="w-1 h-1 rounded-full"
                                                :class="i <= Number(proposal.currentSignatures) ? 'bg-white/80' : 'bg-gray-400/50'"
                                            ></div>
                                        </div>
                                    </div>

                                    <!-- Remaining info -->
                                    <div v-if="normalizeStatus(proposal.status) === 'pending'" class="text-center">
                                        <p class="text-xs text-gray-500 dark:text-gray-400">
                                            {{ (Number(proposal.requiredSignatures) || 0) - (Number(proposal.currentSignatures) || 0) }} more signature{{ ((Number(proposal.requiredSignatures) || 0) - (Number(proposal.currentSignatures) || 0)) !== 1 ? 's' : '' }} needed
                                        </p>
                                    </div>
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
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Expiration</h3>

                            <div class="text-center space-y-3">
                                <div class="p-3 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
                                    <p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Expires on</p>
                                    <p class="font-medium text-gray-900 dark:text-white text-sm">
                                        {{ proposal.expiresAt ? formatDate(proposal.expiresAt) : 'Unknown date' }}
                                    </p>
                                    <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                                        {{ proposal.expiresAt ? getTimeStatus(proposal.expiresAt) : 'Unknown' }}
                                    </p>
                                </div>

                                <!-- Time remaining indicator -->
                                <div v-if="proposal.expiresAt" class="flex items-center justify-center space-x-2">
                                    <div class="w-2 h-2 rounded-full"
                                        :class="{
                                            'bg-red-500 animate-pulse': isExpiringSoon(proposal.expiresAt),
                                            'bg-yellow-500': isExpiringToday(proposal.expiresAt) && !isExpiringSoon(proposal.expiresAt),
                                            'bg-green-500': !isExpiringToday(proposal.expiresAt)
                                        }"
                                    ></div>
                                    <span class="text-xs font-medium"
                                        :class="{
                                            'text-red-600 dark:text-red-400': isExpiringSoon(proposal.expiresAt),
                                            'text-yellow-600 dark:text-yellow-400': isExpiringToday(proposal.expiresAt) && !isExpiringSoon(proposal.expiresAt),
                                            'text-green-600 dark:text-green-400': !isExpiringToday(proposal.expiresAt)
                                        }"
                                    >
                                        {{ getExpirationStatus(proposal.expiresAt) }}
                                    </span>
                                </div>
                            </div>
                        </div>

                        <!-- Proposal Metadata -->
                        <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                            <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">Metadata</h3>

                            <div class="space-y-3 text-sm">
                                <div class="flex justify-between">
                                    <span class="text-gray-500 dark:text-gray-400">Created</span>
                                    <span class="font-medium text-gray-900 dark:text-white">
                                        {{ proposal.proposedAt ? formatDateTime(proposal.proposedAt) : 'Unknown' }}
                                    </span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-gray-500 dark:text-gray-400">Duration</span>
                                    <span class="font-medium text-gray-900 dark:text-white">
                                        {{ proposal.proposedAt && proposal.expiresAt ? calculateDuration(proposal.proposedAt, proposal.expiresAt) : 'Unknown' }}
                                    </span>
                                </div>
                                <div v-if="proposal.executedAt" class="flex justify-between">
                                    <span class="text-gray-500 dark:text-gray-400">{{ normalizeStatus(proposal.status) === 'executed' ? 'Executed' : 'Attempted' }}</span>
                                    <span class="font-medium text-gray-900 dark:text-white">
                                        {{ formatDateTime(proposal.executedAt) }}
                                    </span>
                                </div>
                                <div class="flex justify-between">
                                    <span class="text-gray-500 dark:text-gray-400">Proposal ID</span>
                                    <div class="flex items-center space-x-1">
                                        <span class="font-mono text-xs font-medium text-gray-900 dark:text-white bg-gray-100 dark:bg-gray-700 px-2 py-1 rounded">
                                            {{ proposal.id || 'N/A' }}
                                        </span>
                                        <CopyIcon :data="proposal.id || ''" class="w-3 h-3" />
                                    </div>
                                </div>
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
import { useModalStore } from '@/stores/modal'
import { useAuthStore } from '@/stores/auth'
import { multisigService } from '@/api/services/multisig'
import { toast } from 'vue-sonner'
import { formatCurrency, formatNumber } from '@/utils/numberFormat'
import { formatDate, formatTimeAgo } from '@/utils/dateFormat'
import { 
    getProposalTypeKey, 
    getTransferAmount, 
    getTransferRecipient, 
    getModificationTarget,
    getSignerName as getSignerNameUtil,
    getSignerRole,
    getVisibilityChange,
    getThresholdChange,
    getTransferMemo,
    formatPrincipal as formatPrincipalUtil,
    parseTokenAmount,
    formatTokenAmount
} from '@/utils/multisig'
import { parseTokenAmount as parseTokenAmountUtil, formatTokenAmountLabel } from '@/utils/token'
import {
    ArrowLeftIcon,
    PenIcon,
    PlayIcon,
    RefreshCcwIcon,
    PlusIcon,
    CheckIcon,
    WalletIcon,
    AlertTriangle,
    UserPlusIcon,
    UserMinusIcon,
    LockIcon,
    CoinsIcon,
    SettingsIcon,
    VoteIcon,
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import LoadingSkeleton from '@/components/multisig/LoadingSkeleton.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import CopyIcon from '@/icons/CopyIcon.vue'

// Stores and router
const route = useRoute()
const router = useRouter()
// const multisigStore = useMultisigStore() // Unused for now
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
            const proposedAtValue = typeof proposal.proposedAt === 'bigint' ? Number(proposal.proposedAt) : proposal.proposedAt
            proposal.proposedAt = new Date(proposedAtValue / 1000000) // Convert nanoseconds to milliseconds
        }
        if (proposal.expiresAt) {
            const expiresAtValue = typeof proposal.expiresAt === 'bigint' ? Number(proposal.expiresAt) : proposal.expiresAt
            proposal.expiresAt = new Date(expiresAtValue / 1000000)
        }
        if (proposal.executedAt) {
            const executedAtValue = typeof proposal.executedAt === 'bigint' ? Number(proposal.executedAt) : proposal.executedAt
            proposal.executedAt = new Date(executedAtValue / 1000000)
        }

        // Parse signature data from approvals array
        if (proposal.approvals && proposal.approvals.length > 0) {
            proposal.signatures = proposal.approvals.map((approval: any) => ({
                signer: approval.signer.toString(),
                signerName: getSignerName(approval.signer.toString(), walletInfo.signers),
                signedAt: approval.approvedAt ? new Date((typeof approval.approvedAt === 'bigint' ? Number(approval.approvedAt) : approval.approvedAt) / 1000000) : new Date(),
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

// Enhanced datetime formatting
const formatDateTime = (date: Date): string => {
    return new Intl.DateTimeFormat('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        timeZoneName: 'short'
    }).format(date)
}

// Helper function to format principal
const formatPrincipal = (principal: string): string => {
    if (!principal) return 'Unknown'
    if (principal.length <= 16) return principal
    return `${principal.slice(0, 8)}...${principal.slice(-8)}`
}

// Calculate duration between two dates
const calculateDuration = (start: Date, end: Date): string => {
    const diffMs = end.getTime() - start.getTime()
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
    const diffHours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))

    if (diffDays > 0) {
        return `${diffDays} day${diffDays > 1 ? 's' : ''} ${diffHours}h`
    } else if (diffHours > 0) {
        return `${diffHours} hour${diffHours > 1 ? 's' : ''}`
    } else {
        const diffMinutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
        return `${diffMinutes} minute${diffMinutes > 1 ? 's' : ''}`
    }
}

// Check if proposal is expiring soon (within 24 hours)
const isExpiringSoon = (expiresAt: Date): boolean => {
    const now = new Date()
    const timeUntilExpiry = expiresAt.getTime() - now.getTime()
    return timeUntilExpiry > 0 && timeUntilExpiry <= 24 * 60 * 60 * 1000 // 24 hours
}

// Check if proposal is expiring today
const isExpiringToday = (expiresAt: Date): boolean => {
    const now = new Date()
    const timeUntilExpiry = expiresAt.getTime() - now.getTime()
    return timeUntilExpiry > 0 && timeUntilExpiry <= 24 * 60 * 60 * 1000 // Today
}

// Get expiration status
const getExpirationStatus = (expiresAt: Date): string => {
    const now = new Date()
    const timeUntilExpiry = expiresAt.getTime() - now.getTime()

    if (timeUntilExpiry <= 0) {
        return 'Expired'
    } else if (timeUntilExpiry <= 60 * 60 * 1000) { // 1 hour
        return 'Expires Soon'
    } else if (timeUntilExpiry <= 24 * 60 * 60 * 1000) { // 24 hours
        return 'Expires Today'
    } else {
        const days = Math.ceil(timeUntilExpiry / (24 * 60 * 60 * 1000))
        return `${days} day${days > 1 ? 's' : ''} left`
    }
}

// Get time status relative to now
const getTimeStatus = (date: Date): string => {
    const now = new Date()
    const diffMs = date.getTime() - now.getTime()

    if (diffMs <= 0) {
        return formatTimeAgo(date.getTime()) + ' ago'
    } else {
        const futureMs = Math.abs(diffMs)
        const futureDays = Math.floor(futureMs / (1000 * 60 * 60 * 24))
        const futureHours = Math.floor((futureMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))

        if (futureDays > 0) {
            return `in ${futureDays} day${futureDays > 1 ? 's' : ''}`
        } else if (futureHours > 0) {
            return `in ${futureHours} hour${futureHours > 1 ? 's' : ''}`
        } else {
            const futureMinutes = Math.floor((futureMs % (1000 * 60 * 60)) / (1000 * 60))
            return `in ${futureMinutes} minute${futureMinutes > 1 ? 's' : ''}`
        }
    }
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

// Helper methods for formatting proposal data
const getFormattedTransferAmount = (proposal: any): string => {
    const { amount, asset } = getTransferAmount(proposal)
    
    if (!amount) return 'Unknown amount'
    
    try {
        const numAmount = typeof amount === 'bigint' ? Number(amount) : Number(amount)
        
        if (!asset || asset === 'ICP' || (typeof asset === 'object' && 'ICP' in asset)) {
            const icpAmount = parseTokenAmountUtil(numAmount, 8)
            return `${icpAmount.toFixed(6).replace(/\.?0+$/, '')} ICP`
        } else if (typeof asset === 'object' && 'Token' in asset) {
            const tokenAmount = parseTokenAmountUtil(numAmount, 8)
            return formatTokenAmountLabel(tokenAmount.toString(), 'Token')
        } else {
            const tokenAmount = parseTokenAmountUtil(numAmount, 8)
            return formatTokenAmountLabel(tokenAmount.toString(), asset || 'Token')
        }
    } catch (error) {
        return `${amount}`
    }
}

const getTransferFee = (proposal: any): string => {
    // Default ICP fee
    return '0.0001 ICP'
}

const getFormattedRecipient = (proposal: any): string => {
    const recipient = getTransferRecipient(proposal)
    
    if (!recipient) return 'Unknown recipient'
    
    if (typeof recipient === 'object' && recipient.toString) {
        return recipient.toString()
    }
    if (typeof recipient === 'string') {
        return recipient
    }
    return String(recipient)
}

const getFormattedTarget = (proposal: any): string => {
    const target = getModificationTarget(proposal)
    
    if (!target) return 'Unknown target'
    
    if (typeof target === 'object' && target.toString) {
        return target.toString()
    }
    if (typeof target === 'string') {
        return target
    }
    return String(target)
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
