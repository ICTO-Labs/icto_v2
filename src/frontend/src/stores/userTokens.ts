import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { backendService } from '@/api/services/backend';
import { IcrcService } from '@/api/services/icrc';
import { DEFAULT_TOKENS } from '@/config/constants';
import { BackendUtils } from '@/utils/backend';
import type { Token } from '@/types/token';
import { useAuthStore } from './auth';

interface SyncTokensResult {
    tokensToAdd: Token[];
    tokensToRemove: Token[];
    syncStatus: { added: number; removed: number } | null;
}

interface UserTokensState {
    enabledTokens: Set<string>;
    tokenData: Map<string, Token>;
    tokens: Token[];
    isAuthenticated: boolean;
    lastUpdated: number;
}

// Constants
const AUTH_NAMESPACE = 'userTokens';
const STORAGE_KEYS = {
    LAST_WALLET: "selectedWallet",
    CURRENT_PRINCIPAL: "currentPrincipal",
    ENABLED_TOKENS: "enabledTokens",
    TOKEN_DATA: "tokenData"
} as const;

// Cache for token details
const tokenDetailsCache = new Map<string, Token>();

// Helper to create namespaced storage keys
const getStorageKey = (key: string) => `${AUTH_NAMESPACE}:${key}`;

// Custom replacer and reviver for BigInt
const json = {
    stringify(value: any): string {
        const replacer = (key: string, value: any) =>
            typeof value === 'bigint' ? `BIGINT::${value.toString()}` : value;
        return JSON.stringify(value, replacer);
    },
    parse(text: string): any {
        const reviver = (key: string, value: any) => {
            if (typeof value === 'string' && value.startsWith('BIGINT::')) {
                return BigInt(value.substring(8));
            }
            return value;
        };
        return JSON.parse(text, reviver);
    }
};

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

    set(key: keyof typeof STORAGE_KEYS, value: any): void {
        try {
            localStorage.setItem(getStorageKey(STORAGE_KEYS[key]), json.stringify(value));
        } catch (error) {
            console.error(`Error setting ${key} in storage:`, error);
        }
    },

    clear(): void {
        try {
            Object.values(STORAGE_KEYS).forEach(key => {
                localStorage.removeItem(getStorageKey(key));
            });
        } catch (error) {
            console.error('Error clearing storage:', error);
        }
    }
};

import type { Principal } from '@dfinity/principal';

export const useUserTokensStore = defineStore('userTokens', () => {
    // State
    const enabledTokens = ref<Set<string>>(new Set());
    const tokenData = ref<Map<string, Token>>(new Map());
    const isAuthenticated = ref(false);
    const currentPrincipal = ref<string | null>(null);
    const lastUpdated = ref(Date.now());

    // Computed
    const tokens = computed(() => Array.from(tokenData.value.values()));
    const enabledTokensList = computed(() =>
        Array.from(enabledTokens.value).map(id => tokenData.value.get(id)).filter(Boolean) as Token[]
    );

    // Actions
    const debouncedUpdateStorage = BackendUtils.debounce(async () => {
        storage.set('ENABLED_TOKENS', Array.from(enabledTokens.value));
        storage.set('TOKEN_DATA', Array.from(tokenData.value.entries()));
        storage.set('CURRENT_PRINCIPAL', currentPrincipal.value);
    }, 300);

    async function loadDefaultTokens() {
        try {
            const defaultTokensList = await backendService.getDefaultTokens(Object.values(DEFAULT_TOKENS));
            defaultTokensList.forEach((token: Token | null) => {
                if (!token) return;
                enabledTokens.value.add(token.canisterId.toString());
                tokenData.value.set(token.canisterId.toString(), token);
                tokenDetailsCache.set(token.canisterId.toString(), token);
            });
            await debouncedUpdateStorage();
        } catch (error) {
            console.error('[UserTokens] Error loading default tokens:', error);
        }
    }

    async function initialize() {
        const storedPrincipal = storage.get('CURRENT_PRINCIPAL');
        if (storedPrincipal) {
            currentPrincipal.value = JSON.parse(storedPrincipal);
            isAuthenticated.value = true;
        }

        const storedTokens = storage.get('TOKEN_DATA');
        const storedEnabledTokens = storage.get('ENABLED_TOKENS');

        if (storedTokens) {
            tokenData.value = new Map(json.parse(storedTokens));
        }

        if (storedEnabledTokens) {
            enabledTokens.value = new Set(json.parse(storedEnabledTokens));
        }

        if (!enabledTokens.value.size) {
            await loadDefaultTokens();
        }
    }

    async function setPrincipal(principalId: string | null) {
        currentPrincipal.value = principalId;
        isAuthenticated.value = !!principalId;

        if (principalId) {
            storage.set('CURRENT_PRINCIPAL', principalId);
            await initialize();
        } else {
            storage.clear();
            enabledTokens.value.clear();
            tokenData.value.clear();
        }
    }

    async function getTokenDetails(canisterId: string): Promise<Token | null> {
        const normalizedId = canisterId.toString();

        // 1. Check local cache first
        if (tokenDetailsCache.has(normalizedId)) {
            return tokenDetailsCache.get(normalizedId) || null;
        }
        if (tokenData.value.has(normalizedId)) {
            const token = tokenData.value.get(normalizedId)!;
            tokenDetailsCache.set(normalizedId, token);
            return token;
        }

        // 2. Try fetching from the backend service (for known/popular tokens)
        try {
            const [tokenFromBackend] = await backendService.getDefaultTokens([normalizedId]);
            // Ensure the returned token matches the requested canister ID
            if (tokenFromBackend && tokenFromBackend.canisterId.toString() === normalizedId) {
                tokenDetailsCache.set(normalizedId, tokenFromBackend);
                return tokenFromBackend;
            }
        } catch (error) {
            console.warn(`[UserTokens] Could not fetch ${normalizedId} from backend, will try ICRC.`, error);
        }

        // 3. Fallback to direct ICRC canister query
        try {
            const tokenFromCanister = await IcrcService.getIcrc1Metadata(normalizedId);
            if (tokenFromCanister) {
                tokenDetailsCache.set(normalizedId, tokenFromCanister);
                return tokenFromCanister;
            }
        } catch (error) {
            console.error(`[UserTokens] ICRC metadata fetch failed for ${normalizedId}:`, error);
        }

        // 4. If all fails, return null
        return null;
    }

    async function enableToken(token: Token) {
        if (!token?.canisterId) return;

        if (enabledTokens.value.has(token.canisterId.toString())) {
            throw new Error('Token already exists.');
        }

        enabledTokens.value.add(token.canisterId.toString());
        tokenData.value.set(token.canisterId.toString(), token);
        tokenDetailsCache.set(token.canisterId.toString(), token);
        await debouncedUpdateStorage();
    }

    async function disableToken(canisterId: string) {
        enabledTokens.value.delete(canisterId);
        await debouncedUpdateStorage();
    }

    async function refreshTokenData() {
        const canisterIds = Array.from(enabledTokens.value);
        if (!canisterIds.length) return;

        try {
            const tokens = await backendService.getDefaultTokens(canisterIds);
            tokens.forEach((token: Token | null) => {
                if (!token) return;
                if (token?.canisterId) {
                    tokenData.value.set(token.canisterId.toString(), token);
                    tokenDetailsCache.set(token.canisterId.toString(), token);
                }
            });
            lastUpdated.value = Date.now();
            await debouncedUpdateStorage();
        } catch (error) {
            console.error('[UserTokens] Error refreshing token data:', error);
        }
    }

    function searchTokens(query: string): Token[] {
        if (!query) return tokens.value;

        const searchTerms = query.toLowerCase();
        return tokens.value.filter((token: Token) => {
            const terms = `${token.symbol} ${token.name} ${token.canisterId}`.toLowerCase();
            return terms.includes(searchTerms);
        });
    }

    function isDefaultToken(canisterId: string): boolean {
        return Object.values(DEFAULT_TOKENS).includes(canisterId);
    }

    async function reset() {
        enabledTokens.value.clear();
        tokenData.value.clear();
        isAuthenticated.value = false;
        currentPrincipal.value = null;
        lastUpdated.value = Date.now();
        storage.clear();
    }

    async function refreshAllBalances(): Promise<void> {
        const authStore = useAuthStore();
        const principal = authStore.principal;

        if (!principal) {
            console.warn("[UserTokens] Cannot refresh balances without a principal.");
            return;
        }

        const enabledTokens = enabledTokensList.value;
        if (enabledTokens.length === 0) {
            return; // Nothing to refresh
        }

        try {
            const balances = await IcrcService.batchGetBalances(enabledTokens, principal.toString());
            
            balances.forEach((balance, canisterId) => {
                const token = tokenData.value.get(canisterId);
                if (token) {
                    const updatedToken = {
                        ...token,
                        balance: balance, // Update the balance
                    };
                    tokenData.value.set(canisterId, updatedToken);
                }
            });

            await debouncedUpdateStorage();
            console.log("[UserTokens] Balances refreshed successfully.");
        } catch (error) {
            console.error("[UserTokens] Error refreshing balances:", error);
        }
    }

    return { 
        // State
        enabledTokens,
        tokenData,
        tokens,
        isAuthenticated,
        currentPrincipal,
        lastUpdated,
        enabledTokensList,

        // Actions
        initialize,
        setPrincipal,
        getTokenDetails,
        refreshAllBalances,
        enableToken,
        disableToken,
        refreshTokenData,
        searchTokens,
        isDefaultToken,
        reset,

        // Helper functions
        isTokenEnabled: (canisterId: string) => enabledTokens.value.has(canisterId)
    };
});
