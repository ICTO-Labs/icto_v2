// stores/token.ts
import { defineStore } from 'pinia';
import { ref } from 'vue';
import type { Token } from '@/types/token';
import { Principal } from '@dfinity/principal';

export const useTokenStore = defineStore('token', () => {
    // This will eventually be populated by backend calls.
    const myTokens = ref<Token[]>([
        {
          id: 'token1',
          name: 'Example Token',
          symbol: 'EXT',
          canisterId: Principal.fromText('rrkah-fqaaa-aaaaa-aaaaq-cai'),
          totalSupply: 1000000n,
          decimals: 8,
          owner: Principal.fromText('aaaaa-aa'),
          createdAt: Date.now() - 86400000, // 1 day ago
          fee: 1000000000000000000n,
        },
        {
          id: 'token2',
          name: 'Another Token',
          symbol: 'ANT',
          canisterId: Principal.fromText('ryjl3-tyaaa-aaaaa-aaaba-cai'),
          totalSupply: 500000000n,
          decimals: 18,
          owner: Principal.fromText('aaaaa-aa'),
          createdAt: Date.now() - 86400000 * 5, // 5 days ago
          fee: 1000000000000000000n,
        },
    ]);

    // TODO: Add actions to fetch tokens from the backend.

    return {
        myTokens,
    };
});
