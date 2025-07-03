import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { storeToRefs } from 'pinia';
import {
    type CanisterType,
    canisters,
    getPnpInstance
} from "../config/auth";

// Re-export CanisterType for other modules
export type { CanisterType };
// import { browser } from "$app/environment";
import { fetchBalances } from "@/api/token/balance";
// import { currentUserBalancesStore } from "$lib/stores/balancesStore";
// import { currentUserPoolsStore } from "$lib/stores/currentUserPoolsStore";
// import { trackEvent, AnalyticsEvent } from "$lib/utils/analytics";
import { useUserTokensStore } from './userTokens';

// const userTokens = useUserTokensStore();

// Constants
const AUTH_NAMESPACE = 'AUTH';
const STORAGE_KEYS = {
    LAST_WALLET: "SELECTED_WALLET",
    AUTO_CONNECT_ATTEMPTED: "AUTO_CONNECT_ATTEMPTED",
    WAS_CONNECTED: "WAS_CONNECTED",
    CONNECTION_RETRY_COUNT: "CONNECTION_RETRY_COUNT",
} as const;

// Helper to create namespaced localStorage keys
const getStorageKey = (key: string) => `${AUTH_NAMESPACE}:${key}`;

// Initialize PNP
const pnp = getPnpInstance();

export const useAuthStore = defineStore('auth', () => {
    const userTokensStore = useUserTokensStore();
    const { tokens } = storeToRefs(userTokensStore);
    const isConnected = ref(false);
    const selectedWalletId = ref<string | null>(null);
    const connectionError = ref<string | null>(null);
    const isAuthenticating = ref(false);
    const principal = ref<string | null>(null);
    const address = ref<string | null>(null);

    // Storage operations
    const storage = {
        get(key: keyof typeof STORAGE_KEYS): string | null {
            try {
                return localStorage.getItem(getStorageKey(STORAGE_KEYS[key]));
            } catch (error) {
                console.error(`Error getting ${key} from storage:`, error);
                return null;
            }
        },
        
        set(key: keyof typeof STORAGE_KEYS, value: string): void {
            try {
                localStorage.setItem(getStorageKey(STORAGE_KEYS[key]), value);
            } catch (error) {
                console.error(`Error setting ${key} in storage:`, error);
            }
        },
        
        clear(): void {
            try {
                for (const key of Object.values(STORAGE_KEYS)) {
                    localStorage.removeItem(getStorageKey(key));
                }
            } catch (error) {
                console.error('Error clearing storage:', error);
            }
        },
    };

    async function connectWallet(walletId: string, isRetry = false, isAutoConnect = false) {
        try {
            connectionError.value = null;
            isAuthenticating.value = true;
            const result = await pnp.connect(walletId);
            principal.value = result?.owner;
            address.value = 'result?.address';
            if (!result?.owner) {
                if (!isRetry && !isAutoConnect) {
                    console.warn(`Connection attempt failed for ${walletId}, retrying once...`);
                    await pnp.disconnect();
                    await new Promise(resolve => setTimeout(resolve, 500));
                    return await connectWallet(walletId, true, isAutoConnect);
                }
                console.error("Connection failed after retry.");
                await disconnectWallet();
                throw new Error("Invalid connection result after retry. Please try again. If the issue persists, reload the page.");
            }
            isConnected.value = true;
            selectedWalletId.value = walletId;
            // Store session data in localStorage
            storage.set('LAST_WALLET', walletId);
            storage.set('WAS_CONNECTED', 'true');

            // Load balances in background
            setTimeout(async () => {
                try {
                    await userTokensStore.setPrincipal(result.owner);
                    await userTokensStore.refreshTokenData();
                    await fetchBalances(tokens.value, result.owner?.toString(), true);
                } catch (error) {
                    console.error("Error loading balances:", error);
                }
            }, 0);

            return { success: true, walletId };
        } catch (error) {
            connectionError.value = error instanceof Error ? error.message : 'Unknown error';
            isConnected.value = false;
            return { success: false, error: connectionError.value };
        } finally {
            isAuthenticating.value = false;
        }
    }

    async function disconnectWallet() {
        await pnp.disconnect();
        isConnected.value = false;
        selectedWalletId.value = null;
        // Clear session data from localStorage
        storage.clear();
    }

    function initialize() {
        const lastWallet = storage.get('LAST_WALLET');
        const wasConnected = storage.get('WAS_CONNECTED');
        if (lastWallet && wasConnected === 'true') {
            connectWallet(lastWallet, false, true);
        }
    }


    const isWalletConnected = computed(() => isConnected.value);
    const pnp = getPnpInstance();

    async function handleConnection(result: any) {
        if (result?.owner) {
            try {
                await userTokensStore.setPrincipal(result.owner);
                await userTokensStore.refreshTokenData();
                await fetchBalances(tokens.value, result.owner?.toString(), true);
            } catch (error) {
                console.error('Error handling connection:', error);
            }
        }
    }

    return {
        principal,
        address,
        isConnected,
        selectedWalletId,
        connectionError,
        isAuthenticating,
        connectWallet,
        disconnectWallet,
        isWalletConnected,
        initialize,
        pnp,
        handleConnection
    };
});

// Helper functions
export function requireWalletConnection(): void {
    if (!pnp.isAuthenticated()) throw new Error("Wallet is not connected.");
}

export function icrcActor({ canisterId, anon = false, requiresSigning = true }: { canisterId: string, anon?: boolean, requiresSigning?: boolean }) {
    return pnp.getActor<CanisterType["ICRC2_LEDGER"]>({ canisterId, idl: canisters.icrc2.idl, anon, requiresSigning });
}

export const icpActor = ({ anon = false, requiresSigning = true }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["ICP_LEDGER"]>({ canisterId: canisters.icp.canisterId!, idl: canisters.icp.idl, anon, requiresSigning });
}

export const backendActor = ({ anon = false, requiresSigning = true }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["BACKEND"]>({ canisterId: canisters.backend.canisterId!, idl: canisters.backend.idl, anon, requiresSigning });
}
