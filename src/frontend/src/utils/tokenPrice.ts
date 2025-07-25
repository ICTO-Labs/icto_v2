// Token Price Utilities for ICTO V2
// Author: AI Assistant
// This file contains functions to fetch token prices from various sources (simulated/placeholder),
// and helpers to calculate USD value for tokens.
// Easily extendable for real API integration.

import type { Token } from '@/types/token';

// Simulate fetching ICP price from CoinGecko
export async function fetchIcpPriceFromCoingecko(): Promise<number> {
    // Placeholder: ICP = 4.435$
    return 4.435;
}

// Simulate fetching price for a generic token from a DEX or other API
export async function fetchTokenPriceFromDex(symbol: string): Promise<number> {
    // Placeholder: return different prices for demo
    if (symbol === 'ICP') return 4.435;
    if (symbol === 'ckBTC') return 65000;
    if (symbol === 'OGY') return 0.02;
    // ... add more as needed
    return 0; // Unknown token
}

// Main function to fetch price for a token (can extend with more sources/fallbacks)
export async function fetchTokenPrice(token: Token): Promise<number> {
    if (token.symbol === 'ICP') {
        return await fetchIcpPriceFromCoingecko();
    }
    // Add more logic for other tokens/sources
    return await fetchTokenPriceFromDex(token.symbol);
}

// Get USD balance for a token
export async function getTokenUSDBalance(token: Token): Promise<number> {
    const price = await fetchTokenPrice(token);
    const balance = Number(token.balance ?? 0) / Math.pow(10, token.decimals ?? 8);
    return price * balance;
} 