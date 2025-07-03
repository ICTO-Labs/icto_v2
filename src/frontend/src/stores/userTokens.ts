import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { backendService } from '@/api/services/backend';
import { DEFAULT_TOKENS } from '@/config/constants';
import { BackendUtils } from '@/utils/backend';
import type { Token } from '@/types/token';

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
            localStorage.setItem(getStorageKey(STORAGE_KEYS[key]), JSON.stringify(value));
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
            tokenData.value = new Map(JSON.parse(storedTokens));
        }

        if (storedEnabledTokens) {
            enabledTokens.value = new Set(JSON.parse(storedEnabledTokens));
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
        if (tokenDetailsCache.has(canisterId)) {
            return tokenDetailsCache.get(canisterId.toString()) || null;
        }

        if (tokenData.value.has(canisterId)) {
            const token = tokenData.value.get(canisterId) as Token;
            if (token) {
                tokenDetailsCache.set(canisterId.toString(), token);
                return token;
            }
        }

        try {
            const [token] = await backendService.getDefaultTokens([canisterId]) as Token[];
            if (token) {
                tokenDetailsCache.set(canisterId.toString(), token);
                tokenData.value.set(canisterId.toString(), token);
                await debouncedUpdateStorage();
                return token;
            }
        } catch (error) {
            console.error(`[UserTokens] Error fetching token details for ${canisterId}:`, error);
        }

        return null;
    }

    async function enableToken(token: Token) {
        if (!token?.canisterId) return;

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
