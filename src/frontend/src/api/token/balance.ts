import { IcrcService } from "@/api/services/icrc";
import { Principal } from "@dfinity/principal";
import type { Token, TokenBalance, TokenBalanceBase } from '@/types/token';
import { icrcActor } from '@/stores/auth';
import { formatBalance, formatToNonZeroDecimal } from '@/utils/numberFormat';

// Constants
const BATCH_SIZE = 40;
const BATCH_DELAY_MS = 100;
const DEFAULT_PRICE = 0;

// Helper functions
function convertPrincipalId(principalId: string | Principal): Principal {
    return typeof principalId === "string" ? Principal.fromText(principalId) : principalId;
}

function calculateUsdValue(balance: string, price: number | string = DEFAULT_PRICE): number {
    const tokenAmount = parseFloat(balance.replace(/,/g, ''));
    return tokenAmount * Number(price);
}

function formatTokenBalance(balance: bigint | { default: bigint }, decimals: number, price: number | string, token: Token): TokenBalanceBase {
    const finalBalance = typeof balance === "object" ? balance.default : balance;
    const actualBalance = formatBalance(finalBalance, decimals)?.replace(/,/g, '');
    const usdValue = calculateUsdValue(actualBalance, price);
    return {
        inTokens: finalBalance,
        inUsd: usdValue.toString(),
    };
}

// Main functions
export async function fetchBalance(
    token: Token,
    principalId?: string,
    forceRefresh = false,
): Promise<TokenBalanceBase> {
    console.log('>>> fetchBalance', token, principalId, forceRefresh)
    try {
        if (!token?.canisterId || !principalId) {
            return {
                inTokens: BigInt(0),
                inUsd: formatToNonZeroDecimal(0),
            };
        }

        const principal = convertPrincipalId(principalId);
        const balance = await IcrcService.getIcrc1Balance(token, principal);
        return formatTokenBalance(balance, token.decimals, token?.metrics?.price ?? DEFAULT_PRICE, token);
    } catch (error) {
        console.error(`Error fetching balance for token ${token.canisterId.toString()}:`, error);
        return {
            inTokens: BigInt(0),
            inUsd: formatToNonZeroDecimal(0),
        };
    }
}

async function processBatch(
    batch: Token[],
    principal: string,
): Promise<Map<string, bigint>> {
    try {
        const batchBalances = await IcrcService.batchGetBalances(batch, principal);
        return new Map(
            Array.from(batchBalances.entries())
                .filter(([_, balance]) => balance !== undefined && balance !== null)
                .map(([canisterId, balance]) => [canisterId, balance as bigint])
        );
        } catch (error) {
        console.error(`Error processing batch:`, error);
        return new Map();
    }
}

export async function fetchBalances(
    tokens?: Token[],
    principalId?: string,
    forceRefresh = false,
): Promise<Record<string, TokenBalanceBase>> {
    if (!principalId || !tokens?.length) {
        return {};
    }

    try {
        const principal = principalId;
        const results = new Map<string, bigint>();
        // Process tokens in batches
        for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
            const batch = tokens
                .slice(i, i + BATCH_SIZE)
                .map(t => ({ ...t, timestamp: Date.now() }));

            const batchResults = await processBatch(batch, principal);
            for (const [canisterId, balance] of batchResults) {
                results.set(canisterId, balance);
            }

            // Add delay between batches if not the last batch
            if (i + BATCH_SIZE < tokens.length) {
                await new Promise(resolve => setTimeout(resolve, BATCH_DELAY_MS));
            }
        }

        // Process results into final format
        return tokens.reduce((acc, token) => {
            const balance = results.get(token.canisterId.toString());
            if (balance !== undefined) {
                const tokenBalance = formatTokenBalance(
                    balance,
                    token.decimals,
                    token?.metrics?.price ?? DEFAULT_PRICE,
                    token
                );
                acc[token.canisterId.toString()] = tokenBalance;
            }
            return acc;
        }, {} as Record<string, TokenBalanceBase>);

    } catch (error) {
        console.error('Error in fetchBalances:', error);
        return {};
    }
}

/**
 * Fetch balance for a single token
 */
export async function fetchTokenBalance(
    canisterId: string,
    principal: string,
    skipCache = false
): Promise<bigint | null> {
    try {
        const actor = icrcActor({ canisterId });
        const balance = await actor.icrc1_balance_of({
            owner: Principal.fromText(principal),
            subaccount: []
        });
        return balance;
    } catch (error) {
        console.error(`Error fetching balance for ${canisterId}:`, error);
        return null;
    }
}
