import { useAuthStore, icrcActor } from "@/stores/auth";
import type { Token } from "@/types/token";
import { Principal } from "@dfinity/principal";
import { hexStringToUint8Array } from "@dfinity/utils";

export class IcrcService {
    private static MAX_CONCURRENT_REQUESTS = 25;

    private static async withConcurrencyLimit<T>(
        operations: (() => Promise<T>)[],
        limit: number = this.MAX_CONCURRENT_REQUESTS,
    ): Promise<T[]> {
        const results: T[] = [];
        const executing: Promise<void>[] = [];
        const queue = [...operations];

        async function executeNext(): Promise<void> {
            if (queue.length === 0) return;
            const operation = queue.shift()!;
            try {
                const result = await operation();
                results.push(result);
            } catch (error) {
                results.push(null as T);
                console.error("Operation failed:", error);
            }
            await executeNext();
        }

        // Start initial batch of operations
        for (let i = 0; i < Math.min(limit, operations.length); i++) {
            executing.push(executeNext());
        }

        await Promise.all(executing);
        return results;
    }
    public static async getIcrc1Balance(
        token: Token,
        principal: Principal,
        subaccount?: number[] | undefined,
        separateBalances: boolean = false,
    ): Promise<{ default: bigint; subaccount: bigint } | bigint> {
        try {
            const actor = icrcActor({
                canisterId: token.canisterId.toString(),
                anon: true,
            });

            // Get default balance with retry logic
            const defaultBalance = await actor.icrc1_balance_of({
                owner: principal,
                subaccount: [],
            });

            // If we don't need separate balances or there's no subaccount, return total
            if (!separateBalances || !subaccount) {
                return defaultBalance;
            }

            // Get subaccount balance with retry logic
            const subaccountBalance = await actor.icrc1_balance_of({
                owner: principal,
                subaccount: [subaccount],
            });

            return { default: defaultBalance, subaccount: subaccountBalance };
        } catch (error) {
            console.error(`Error getting ICRC1 balance for ${token.symbol}:`, error);
            return BigInt(0);
        }
    }

    public static async batchGetBalances(
        tokens: Token[],
        principal: string,
    ): Promise<Map<string, bigint>> {
        // Add request deduplication with a shorter window and token-specific keys
        const requestKeys = tokens.map(
            (token) =>
                `${token.canisterId.toString()}-${principal}-${Date.now() - (Date.now() % 5000)}`,
        );

        // Check if any of these exact tokens are already being fetched
        const pendingPromises = requestKeys
            .map((key) => this.pendingRequests.get(key))
            .filter(Boolean);

        if (pendingPromises.length === tokens.length) {
            // All tokens are already being fetched, wait for them
                const results = await Promise.all(pendingPromises);
                return new Map([
                    ...results
                    .filter((m): m is NonNullable<typeof m> => m != null)
                    .flatMap((m) => [...m.entries()])
                ]);
        }

        // Some or none of the tokens are being fetched, do a fresh fetch
        const promise = this._batchGetBalances(tokens, principal);

        // Store the promise for each token
        requestKeys.forEach((key) => {
            this.pendingRequests.set(key, promise);
            // Clean up after 5 seconds
            setTimeout(() => this.pendingRequests.delete(key), 250);
        });

        try {
            const result = await promise;
            return result;
        } catch (error) {
            console.error("Error in batchGetBalances:", error);
            requestKeys.forEach((key) => this.pendingRequests.delete(key));
            return new Map();
        }
    }

    // Add this as a static class property
    private static pendingRequests = new Map<
        string,
        Promise<Map<string, bigint>>
    >();

    private static async _batchGetBalances(
        tokens: Token[],
        principal: string,
    ): Promise<Map<string, bigint>> {
        const results = new Map<string, bigint>();
        const auth = useAuthStore();
        const subaccount = auth.pnp?.account?.subaccount
            ? Array.from(hexStringToUint8Array(auth.pnp.account.subaccount))
            : undefined;

        // Group tokens by subnet to minimize subnet key fetches
        const tokensBySubnet = tokens.reduce((acc, token) => {
            const subnet = token.canisterId.toString();
            if (!acc.has(subnet)) acc.set(subnet, []);
            acc.get(subnet)?.push(token);
            return acc;
        }, new Map<string, Token[]>());

        // Process subnets in parallel with a higher concurrency limit
        const subnetEntries = Array.from(tokensBySubnet.entries());
        const subnetOperations = subnetEntries.map(
            ([subnet, subnetTokens]) =>
                async () => {
                    const operations = subnetTokens.map((token) => async () => {
                        try {
                            const balance = await this.getIcrc1Balance(
                                token,
                                Principal.fromText(principal),
                                subaccount,
                                false,
                            );
                            return { token, balance };
                        } catch (error) {
                            console.error(
                                `Failed to get balance for ${token.symbol}:`,
                                error,
                            );
                            return { token, balance: BigInt(0) };
                        }
                    });

                    // Increase concurrency limit for token balance fetching
                    const balances = await this.withConcurrencyLimit(operations, 30);

                    balances.forEach((result) => {
                        if (result) {
                            const { token, balance } = result;
                            results.set(
                                token.canisterId.toString(),
                                BigInt(balance.toString()),
                            );
                        }
                    });
                },
        );

        // Process all subnets with higher concurrency
        await this.withConcurrencyLimit(subnetOperations, 25);
        return results;
    }
}