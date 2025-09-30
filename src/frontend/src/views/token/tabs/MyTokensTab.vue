<template>
    <div>
        <div class="flex justify-between items-center mb-6">
            <h2 class="text-lg font-medium text-gray-900 dark:text-white">My Tokens</h2>
            <button 
                @click="refreshDeployments" 
                class="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh
            </button>
        </div>

        <!-- Loading state -->
        <div v-if="loading" class="flex justify-center items-center py-12">
            <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-indigo-500"></div>
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

        <!-- Empty state -->
        <div v-else-if="deployments.length === 0" class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-lg p-8 text-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-gray-900 dark:text-white">No tokens deployed</h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">Get started by deploying your first token.</p>
            <div class="mt-6">
                <router-link to="/token/deploy" class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                    <svg class="-ml-1 mr-2 h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
                        <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd" />
                    </svg>
                    Deploy New Token
                </router-link>
            </div>
        </div>

        <!-- Deployments list -->
        <div v-else class="bg-white dark:bg-gray-800 shadow overflow-hidden sm:rounded-lg">
            <ul role="list" class="divide-y divide-gray-200 dark:divide-gray-700">
                <li v-for="deployment in deployments" :key="deployment.id" class="px-4 py-4 sm:px-6">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center">
                            <TokenLogo 
                                :canister-id="deployment.canisterId" 
                                :symbol="deployment.tokenInfo?.symbol || 'T'"
                                :size="40"
                                class="flex-shrink-0"
                            />
                            <div class="ml-4">
                                <div class="flex items-center">
                                    <router-link 
                                        :to="`/tokens/${deployment.canisterId}`"
                                        class="text-sm font-medium text-gray-900 dark:text-white hover:text-indigo-600 dark:hover:text-indigo-400"
                                    >
                                        {{ deployment.tokenInfo?.name || deployment.name }}
                                    </router-link>
                                    <span v-if="deployment.tokenInfo?.symbol" class="ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                                        {{ deployment.tokenInfo.symbol }}
                                    </span>
                                    <span class="ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200">
                                        {{ deployment.deploymentType }}
                                    </span>
                                </div>
                                <div class="mt-1 flex items-center text-sm text-gray-500 dark:text-gray-400">
                                    <span class="truncate">{{ deployment.canisterId }}</span>
                                    <CopyIcon :data="deployment.canisterId" class="w-4 h-4 ml-1"></CopyIcon>
                                </div>
                            </div>
                        </div>
                        <div class="flex flex-col items-end">
                            <div class="text-sm text-gray-500 dark:text-gray-400">
                                {{ deployment.deployedAt }}
                            </div>
                            <div class="mt-1 flex space-x-2">
                                <a href="'https://dashboard.internetcomputer.org/canister/' + deployment.canisterId" target="_blank" class="inline-flex items-center px-2.5 py-1.5 border border-gray-300 dark:border-gray-600 shadow-sm text-xs font-medium rounded text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                                    View on IC Dashboard
                                </a>
                                <router-link 
                                    v-if="deployment.tokenInfo" 
                                    :to="`/tokens/${deployment.canisterId}`"
                                    class="inline-flex items-center px-2.5 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                                >
                                    Details
                                </router-link>
                            </div>
                        </div>
                    </div>
                    <div v-if="deployment.tokenInfo" class="mt-2">
                        <div class="grid grid-cols-2 gap-4 sm:grid-cols-3 text-sm">
                            <div>
                                <span class="text-gray-500 dark:text-gray-400">Standard:</span>
                                <span class="ml-1 text-gray-900 dark:text-white">{{ deployment.tokenInfo.standard }}</span>
                            </div>
                            <div>
                                <span class="text-gray-500 dark:text-gray-400">Decimals:</span>
                                <span class="ml-1 text-gray-900 dark:text-white">{{ deployment.tokenInfo.decimals }}</span>
                            </div>
                            <div>
                                <span class="text-gray-500 dark:text-gray-400">Total Supply:</span>
                                <span class="ml-1 text-gray-900 dark:text-white">{{ formatBalance(deployment.tokenInfo.totalSupply, deployment.tokenInfo.decimals) }}</span>
                            </div>
                        </div>
                    </div>
                </li>
            </ul>
        </div>
    </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from '@/stores/auth';
import tokenService, { type TokenInfo } from '@/api/services/token';
import { toast } from 'vue-sonner';
import { formatBalance } from '@/utils/numberFormat';
import { CopyIcon } from '@/icons';
import TokenLogo from '@/components/token/TokenLogo.vue';
import { Principal } from '@dfinity/principal';

const router = useRouter();
const authStore = useAuthStore();

const emit = defineEmits<{
    (e: 'refresh'): void
}>();

const myTokens = ref<TokenInfo[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);

// Computed: Convert TokenInfo to display format
const deployments = computed(() => {
    return myTokens.value.map(token => ({
        id: token.canisterId.toText(),
        canisterId: token.canisterId.toText(),
        name: token.name,
        deploymentType: token.standard,
        deployedAt: new Date(Number(token.deployedAt) / 1_000_000).toLocaleDateString(),
        tokenInfo: {
            name: token.name,
            symbol: token.symbol,
            standard: token.standard,
            decimals: token.decimals,
            totalSupply: token.totalSupply,
            logo: token.logo && token.logo.length > 0 ? token.logo[0] : undefined
        }
    }));
});

onMounted(async () => {
    await fetchDeployments();
});

async function fetchDeployments() {
    loading.value = true;
    error.value = null;
    
    try {
        // Check if user is authenticated
        if (!authStore.principal) {
            error.value = 'Please connect your wallet to view your tokens';
            myTokens.value = [];
            return;
        }
        
        const userPrincipal = Principal.fromText(authStore.principal);
        const result = await tokenService.getMyCreatedTokens(userPrincipal, 100, 0);
        myTokens.value = result.tokens;
    } catch (err) {
        console.error('Error fetching my tokens:', err);
        error.value = 'Failed to load your tokens. Please try again.';
    } finally {
        loading.value = false;
    }
}

async function refreshDeployments() {
    await fetchDeployments();
    if (!error.value) {
        toast.success('Tokens refreshed successfully');
        emit('refresh');
    } else {
        toast.error('Failed to refresh tokens');
    }
}

function shortenCanisterId(canisterId: string): string {
    if (!canisterId) return '';
    return `${canisterId.substring(0, 5)}...${canisterId.substring(canisterId.length - 5)}`;
}

function copyToClipboard(text: string) {
    navigator.clipboard.writeText(text).then(() => {
        toast.success('Canister ID copied to clipboard');
    }).catch(err => {
        console.error('Failed to copy:', err);
        toast.error('Failed to copy to clipboard');
    });
}



</script>