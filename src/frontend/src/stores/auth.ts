import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { storeToRefs } from 'pinia';
import { getPnpInstance } from "../config/auth";
import { canisters, type CanisterType } from "../config/canisters";
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
            
            console.log(`[Auth] Connecting to wallet: ${walletId} (auto: ${isAutoConnect}, retry: ${isRetry})`);
            
            const result = await pnp.connect(walletId);
            
            if (!result?.owner) {
                if (!isRetry && !isAutoConnect) {
                    console.warn(`[Auth] Connection attempt failed for ${walletId}, retrying once...`);
                    await pnp.disconnect();
                    await new Promise(resolve => setTimeout(resolve, 500));
                    return await connectWallet(walletId, true, isAutoConnect);
                }
                
                console.error(`[Auth] Connection failed after retry for ${walletId}`);
                await disconnectWallet();
                
                // For auto-connect, fail silently to avoid disrupting user experience
                if (isAutoConnect) {
                    console.warn(`[Auth] Auto-connect failed for ${walletId}, clearing session data`);
                    return { success: false, error: 'Auto-connect failed' };
                }
                
                throw new Error("Invalid connection result after retry. Please try again. If the issue persists, reload the page.");
            }
            
            // Update state
            principal.value = result.owner.toString();
            isConnected.value = true;
            selectedWalletId.value = walletId;
            
            // Get account ID
            try {
                address.value = await pnp.provider.getAccountId();
            } catch (accIdError) {
                console.warn(`[Auth] Failed to get accountId for ${walletId}:`, accIdError);
                address.value = null;
            }
            
            // Store session data in localStorage
            storage.set('LAST_WALLET', walletId);
            storage.set('WAS_CONNECTED', 'true');

            // Load user data in background
            setTimeout(async () => {
                console.log(`[Auth] Loading user data for ${result.owner?.toString()}`);
                try {
                    await userTokensStore.setPrincipal(result.owner);
                    await userTokensStore.refreshTokenData();
                    await userTokensStore.refreshAllBalances();
                } catch (error) {
                    console.error("[Auth] Error loading user data:", error);
                }
            }, 0);

            console.log(`[Auth] Successfully connected to ${walletId}`);
            return { success: true, walletId };
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : 'Unknown error';
            console.error(`[Auth] Connection error for ${walletId}:`, errorMessage);
            
            connectionError.value = errorMessage;
            isConnected.value = false;
            
            // For auto-connect failures, clear session data to prevent repeated attempts
            if (isAutoConnect) {
                storage.clear();
            }
            
            return { success: false, error: errorMessage };
        } finally {
            isAuthenticating.value = false;
        }
    }

    async function disconnectWallet() {
        console.log('[Auth] Disconnecting wallet...');
        await pnp.disconnect();
        isConnected.value = false;
        selectedWalletId.value = null;
        principal.value = null;
        address.value = null;
        // Clear session data from localStorage
        storage.clear();
        // Clear user tokens store
        await userTokensStore.setPrincipal(null);
    }

    function isSessionValid(): boolean {
        try {
            return pnp.isAuthenticated();
        } catch (error) {
            console.warn('[Auth] Error checking session validity:', error);
            return false;
        }
    }

    async function initialize() {
        try {
            // First check if PNP already has an active session
            if (pnp.isAuthenticated()) {
                console.log('[Auth] PNP session already active, attempting to restore state...');
                
                // Try to get current session info
                try {
                    // Check if we have stored wallet info
                    const lastWallet = storage.get('LAST_WALLET');
                    
                    if (lastWallet) {
                        // Try to get account info from provider
                        let accountId = null;
                        try {
                            accountId = await pnp.provider.getAccountId();
                        } catch (error) {
                            console.warn('[Auth] Could not get account ID during session restore:', error);
                        }
                        
                        // If we can get account info, the session is likely valid
                        if (accountId) {
                            isConnected.value = true;
                            selectedWalletId.value = lastWallet;
                            address.value = accountId;
                            
                            // Try to get principal from provider
                            try {
                                const principalId = await pnp.provider.getPrincipal();
                                if (principalId) {
                                    principal.value = principalId.toString();
                                    
                                    // Load user data in background
                                    setTimeout(async () => {
                                        try {
                                            await userTokensStore.setPrincipal(principalId);
                                            await userTokensStore.refreshTokenData();
                                            await userTokensStore.refreshAllBalances();
                                        } catch (error) {
                                            console.error('[Auth] Error loading user data during session restore:', error);
                                        }
                                    }, 0);
                                    
                                    console.log('[Auth] Session restored successfully for wallet:', lastWallet);
                                    return;
                                }
                            } catch (error) {
                                console.warn('[Auth] Could not get principal during session restore:', error);
                            }
                        }
                    }
                } catch (error) {
                    console.warn('[Auth] Error during session restore:', error);
                }
                
                // If session restore failed, clear the authentication state
                console.log('[Auth] Session restore failed, clearing PNP session...');
                await pnp.disconnect();
            }
            
            // If no active PNP session, check localStorage for auto-reconnect
            const lastWallet = storage.get('LAST_WALLET');
            const wasConnected = storage.get('WAS_CONNECTED');
            
            if (lastWallet && wasConnected === 'true') {
                console.log('[Auth] Attempting auto-reconnect to wallet:', lastWallet);
                await connectWallet(lastWallet, false, true);
            }
        } catch (error) {
            console.error('[Auth] Error during initialization:', error);
            // Clear potentially corrupted session data
            storage.clear();
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
        isSessionValid,
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

export const distributionContractActor = ({ canisterId, anon = false, requiresSigning = true }: { canisterId: string, anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["DISTRIBUTION_CONTRACT"]>({ canisterId, idl: canisters.distribution_contract.idl, anon, requiresSigning });
}

export const daoContractActor = ({ canisterId, anon = false, requiresSigning = true }: { canisterId: string, anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["DAO_CONTRACT"]>({ canisterId, idl: canisters.dao_contract.idl, anon, requiresSigning });
}

export const launchpadContractActor = ({ canisterId, anon = false, requiresSigning = true }: { canisterId: string, anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["LAUNCHPAD_CONTRACT"]>({ canisterId, idl: canisters.launchpad_contract.idl, anon, requiresSigning });
}

export const multisigContractActor = ({ canisterId, anon = false, requiresSigning = true }: { canisterId: string, anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["MULTISIG_CONTRACT"]>({ canisterId, idl: canisters.multisig_contract.idl, anon, requiresSigning });
}

export const tokenFactoryActor = ({ anon = false, requiresSigning = true }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["TOKEN_FACTORY"]>({ canisterId: canisters.token_factory.canisterId!, idl: canisters.token_factory.idl, anon, requiresSigning });
}

export const distributionFactoryActor = ({ anon = false, requiresSigning = false }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["DISTRIBUTION_FACTORY"]>({ canisterId: canisters.distribution_factory.canisterId!, idl: canisters.distribution_factory.idl, anon, requiresSigning });
}

export const multisigFactoryActor = ({ anon = false, requiresSigning = false }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["MULTISIG_FACTORY"]>({ canisterId: canisters.multisig_factory.canisterId!, idl: canisters.multisig_factory.idl, anon, requiresSigning });
}

export const daoFactoryActor = ({ anon = false, requiresSigning = false }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["DAO_FACTORY"]>({ canisterId: canisters.dao_factory.canisterId!, idl: canisters.dao_factory.idl, anon, requiresSigning });
}

export const launchpadFactoryActor = ({ anon = false, requiresSigning = false }: { anon?: boolean, requiresSigning?: boolean }) => {
    return pnp.getActor<CanisterType["LAUNCHPAD_FACTORY"]>({ canisterId: canisters.launchpad_factory.canisterId!, idl: canisters.launchpad_factory.idl, anon, requiresSigning });
}