import { DEFAULT_TOKENS } from "@/config/constants";
import { useAuthStore, backendActor } from "@/stores/auth";
import type { Token, TokensByCanisterRequest } from "@/types/token";
import { BackendUtils } from "@/utils/backend";

export class backendService {
    private static tokenFetchCache = new Map<string, { promise: Promise<Token[]>, timestamp: number }>();
    private static CACHE_TTL = 30000; // 30 seconds cache

    public static async getDefaultTokens(canisterIds: string[]) {
        // Validate input
        const validCanisterIds = canisterIds.filter(id => typeof id === 'string' && id.trim().length > 0);
        
        if (validCanisterIds.length === 0) {
        return [];
        }
        
        // Create a cache key from sorted canister IDs
        const cacheKey = validCanisterIds.slice().sort().join(',');
        const now = Date.now();
        
        // Check cache
        const cached = this.tokenFetchCache.get(cacheKey);
        if (cached && (now - cached.timestamp) < this.CACHE_TTL) {
            return cached.promise;
        }
        const allTokens = await backendActor({ anon: true }).getDefaultTokens();
        const serializedTokens = allTokens.map(token => BackendUtils.serializeTokenMetadata(token));

        // Filter out any null/undefined tokens from serialization before further processing
        const validSerializedTokens = serializedTokens.filter((token): token is Token => !!token);

        // Filter the results to only include the requested canister IDs
        const filteredTokens = validSerializedTokens.filter(token => 
            validCanisterIds.includes(token.canisterId.toString())
        );

        return filteredTokens;
    }
}
