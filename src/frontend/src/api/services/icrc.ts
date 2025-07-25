import { useAuthStore, icrcActor, icpActor } from "@/stores/auth";
import type { Token } from "@/types/token";
import type { IcrcAccount, IcrcTransferArg, ApproveParams } from "@dfinity/ledger-icrc";
import { Principal } from "@dfinity/principal";
import { hexStringToUint8Array } from "@dfinity/utils";
import { hex2Bytes } from "@/utils/common";
import type { AllowanceArgs, ApproveArgs, TransferArgs } from "@dfinity/ledger-icp/dist/candid/ledger";

import type { IcrcTokenMetadataResponse } from "@dfinity/ledger-icrc";

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

    public static async getIcrc1Metadata(canisterId: string): Promise<Token | null> {
        try {
            const actor = icrcActor({
                canisterId: canisterId.toString(),
                anon: true,
            });

            const metadata = await actor.icrc1_metadata();
            const fee = await actor.icrc1_fee();
            const standards = await actor.icrc1_supported_standards();

            const token: Partial<Token> = {
                canisterId: canisterId.toString(),
                fee: Number(fee),
                standards: standards.map((standard) => standard.name),
            };

            metadata.forEach(([key, value]) => {
                if ('Text' in value) {
                    if (key === 'icrc1:name') token.name = value.Text;
                    if (key === 'icrc1:symbol') token.symbol = value.Text;
                    if (key === 'icrc1:logo') token.logoUrl = value.Text;
                } else if ('Nat' in value) {
                    if (key === 'icrc1:decimals') token.decimals = Number(value.Nat);
                }
            });

            // Basic validation
            if (!token.name || !token.symbol || typeof token.decimals === 'undefined') {
                console.error(`Incomplete metadata for canister ${canisterId}`);
                return null;
            }

            return token as Token;
        } catch (error) {
            console.error(`Error getting ICRC1 metadata for ${canisterId}:`, error);
            return null;
        }
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
                owner: Principal.fromText(principal.toString()),
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

    public static async getTokenFee(token: Token): Promise<bigint> {
        try {
            const actor = icrcActor({
                canisterId: token.canisterId.toString(),
                anon: true
            });
            return await actor.icrc1_fee();
        } catch (error) {
            console.error(`Error getting token fee for ${token.symbol}:`, error);
            return BigInt(10000); // Fallback to default fee
        }
    }

    public static async icrc2Approve(
        token: Token,
        spender: Principal,
        amount: bigint,
        opts: {
            memo?: Uint8Array;
            fee?: bigint;
            fromSubaccount?: number[];
            createdAtTime?: bigint;
            expiresAt?: bigint;
            expectedAllowance?: bigint;
        } = {},
    ): Promise<any> {
        try {
            const actor = icrcActor({
                canisterId: token.canisterId.toString(),
                anon: false,
                requiresSigning: true,
            });

            const approveFee = opts.fee ?? BigInt(await this.getTokenFee(token));
            console.log('approveFee', approveFee);
            
            const approveArgs: ApproveArgs = {
                spender: {
                    owner: spender,
                    subaccount: [],
                },
                amount,
                fee: approveFee ? [approveFee] : [],
                memo: opts.memo ? [opts.memo] : [],
                from_subaccount: opts.fromSubaccount ? [opts.fromSubaccount] : [],
                created_at_time: opts.createdAtTime ? [opts.createdAtTime] : [],
                expires_at: opts.expiresAt ? [opts.expiresAt] : [],
                expected_allowance: opts.expectedAllowance ? [opts.expectedAllowance] : [],
            };

            console.log('ICRC2 Approve Args:', approveArgs);

            const result = await actor.icrc2_approve(approveArgs);
            return result;
        } catch (error) {
            console.error("ICRC2 Approve error:", error);
            const stringifiedError = JSON.stringify(error, (_, value) =>
                typeof value === "bigint" ? value.toString() : value,
            );
            return { Err: JSON.parse(stringifiedError) };
        }
    }

    public static async getIcrc2Allowance(
        token: Token,
        owner: Principal,
        spender: Principal,
        fromSubaccount?: Uint8Array | number[]
    ): Promise<bigint> {
        try {
            const actor = icrcActor({
                canisterId: token.canisterId.toString(),
                anon: true,
            });

            const allowanceArgs: AllowanceArgs = {
                account: {
                    owner: owner,
                    subaccount: fromSubaccount ? [fromSubaccount] as [Uint8Array | number[]] : [],
                },
                spender: {
                    owner: spender,
                    subaccount: [],
                },
            };
            const result = await actor.icrc2_allowance(allowanceArgs);
            return result.allowance;
        } catch (error) {
            console.error(`Error getting ICRC2 allowance for ${token.symbol}:`, error);
            return BigInt(0);
        }
    }

    public static async transfer(
        token: Token,
        to: string | Principal | IcrcAccount,
        amount: bigint,
        opts: {
            memo?: Uint8Array | number[];
            fee?: bigint;
            fromSubaccount?: Uint8Array | number[];
            createdAtTime?: bigint;
        } = {},
    ): Promise<any> {
        try {
            const auth = useAuthStore();
            // If it's an ICP transfer to a legacy Account ID string
            if (
                token.symbol === "ICP" &&
                typeof to === "string" &&
                to.length === 64 &&
                !to.includes("-")
            ) {
                const wallet = auth.pnp.adapter.id;
                if (wallet === "oisy") {
                    return { Err: "Oisy subaccount transfer is temporarily disabled." };
                }
                const ledgerActor = icpActor({ requiresSigning: true });

                const transfer_args: TransferArgs = {
                    to: hex2Bytes(to),
                    amount: { e8s: amount },
                    fee: { e8s: opts.fee ?? BigInt(token.fee ?? 10000) },
                    memo: 0n,
                    from_subaccount: opts.fromSubaccount
                        ? [Array.from(opts.fromSubaccount)]
                        : [],
                    created_at_time: opts.createdAtTime
                        ? [{ timestamp_nanos: opts.createdAtTime }]
                        : [],
                };

                const result = await ledgerActor.transfer(transfer_args);
                if ("Err" in result) {
                    const stringifiedError = JSON.stringify(result.Err, (_, value) =>
                        typeof value === "bigint" ? value.toString() : value,
                    );
                    return { Err: JSON.parse(stringifiedError) };
                }
                return { Ok: BigInt(result.Ok) };
            }

            // For all ICRC standard transfers (Principal or ICRC1 Account)
            const actor = icrcActor({
                canisterId: token.canisterId.toString(),
                anon: false,
                requiresSigning: true,
            });

            let recipientAccount: {
                owner: Principal;
                subaccount: [] | [Uint8Array | number[]];
            };

            if (typeof to === "string") {
                recipientAccount = {
                    owner: Principal.fromText(to),
                    subaccount: [],
                };
            } else if (to instanceof Principal) {
                recipientAccount = { owner: Principal.fromText(to.toString()), subaccount: [] };
            } else {
                recipientAccount = {
                    owner: Principal.fromText(to.owner.toString()),
                    subaccount: to.subaccount ? [to.subaccount] : [],
                };
            }

            const transferFee = opts.fee ?? (await this.getTokenFee(token));

            const _transferArgs: IcrcTransferArg = {
                to: recipientAccount,
                amount: amount,
                fee: [transferFee],
                memo: [],
                from_subaccount: [],
                created_at_time: [],
            }

            console.log('Transfer Args:', _transferArgs)

            const result = await actor.icrc1_transfer(_transferArgs);
            return result;
        } catch (error) {
            console.error("Transfer error:", error);
            const stringifiedError = JSON.stringify(error, (_, value) =>
                typeof value === "bigint" ? value.toString() : value,
            );
            return { Err: JSON.parse(stringifiedError) };
        }
    }

    //Check if principal is a mint account
    public static async isMintAccount(canisterId: Principal, principal: Principal): Promise<boolean> {
        try {
            // Validate input
            if (!canisterId) {
                throw new Error('Invalid token: canisterId is required');
            }
            
            if (!principal) {
                throw new Error('Invalid principal: principal is required');
            }    
            const actor = icrcActor({
                canisterId: canisterId.toString(),
                anon: true,
            });
            const result = await actor.icrc1_minting_account();
            if (!result || !Array.isArray(result)) {
                console.warn('No minting accounts found or invalid response:', result);
                return false;
            }
            const isMintAccount = result.some((account) => {
                if (!account?.owner) {
                    return false;
                }
                return account.owner.toString() === principal.toString();
            });
            return isMintAccount;
        } catch (error) {
            console.error('Error checking if principal is a mint account:', error);
            return false;
        }
    }
}