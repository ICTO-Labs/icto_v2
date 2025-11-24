import { useAuthStore, icrcActor, icpActor } from "@/stores/auth";
import type { Token } from "@/types/token";
import type { IcrcAccount, IcrcTransferArg, ApproveParams } from "@dfinity/ledger-icrc";
import { Principal } from "@dfinity/principal";
import { hexStringToUint8Array } from "@dfinity/utils";
import { hex2Bytes } from "@/utils/common";
import type { AllowanceArgs, ApproveArgs, TransferArgs } from "@dfinity/ledger-icp/dist/candid/ledger";
import type { TransactionRecord, TransactionListParams, TransactionListResponse } from "@/types/transaction";

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

    public static async getIcrc1SubaccountBalance(
        token: Token,
        owner: Principal,
        subaccount?: number[] | undefined,
        separateBalances: boolean = false,
    ): Promise<{ default: bigint; subaccount: bigint } | bigint> {
        try {
            const actor = icrcActor({
                canisterId: token.canisterId.toString(),
                anon: true,
            });

            // If no subaccount specified, get default balance
            if (!subaccount) {
                const defaultBalance = await actor.icrc1_balance_of({
                    owner: Principal.fromText(owner.toString()),
                    subaccount: [],  // Empty array for no subaccount
                });
                return defaultBalance;
            }

            // If we need separate balances, return both
            if (separateBalances) {
                const defaultBalance = await actor.icrc1_balance_of({
                    owner: Principal.fromText(owner.toString()),
                    subaccount: [],  // Empty array for no subaccount
                });
                const subaccountBalance = await actor.icrc1_balance_of({
                    owner: owner,
                    subaccount: [subaccount],
                });
                return { default: defaultBalance, subaccount: subaccountBalance };
            }

            // Otherwise, return only the subaccount balance
            const subaccountBalance = await actor.icrc1_balance_of({
                owner: owner,
                subaccount: subaccount ? [subaccount] : [],  // Handle undefined subaccount
            });
            return subaccountBalance;

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
    public static async isMintAccount(canisterId: Principal, principal?: string | null): Promise<boolean> {
        try {
            // Validate canisterId
            if (!canisterId) {
                return false;
            }

            // Return false if principal is not available
            if (!principal) {
                return false;
            }

            const actor = icrcActor({
                canisterId: canisterId.toString(),
                anon: true,
            });
            const result = await actor.icrc1_minting_account();
            if (!result || !Array.isArray(result)) {
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
            return false;
        }
    }

    // Get transaction history for a token
    public static async getTransactions(
        canisterId: string,
        start: bigint = BigInt(0),
        length: bigint = BigInt(20)
    ): Promise<TransactionListResponse | null> {
        try {
            const actor = icrcActor({
                canisterId: canisterId.toString(),
                anon: true,
            }) as any;

            // Check if the canister supports get_transactions
            // Try different method names (some implementations use different naming)
            const getTransactionsMethod =
                actor.icrc1_get_transactions ||
                actor.get_transactions ||
                actor.icrc_get_transactions;

            if (!getTransactionsMethod) {
                console.warn(`Canister ${canisterId} does not support get_transactions`);
                return null;
            }

            const params: TransactionListParams = { start, length };
            const result = await getTransactionsMethod(params);

            if (!result) {
                console.warn(`No result from get_transactions for ${canisterId}`);
                return null;
            }

            console.log('Transaction result:', result);

            // Handle different response formats
            let transactions: TransactionRecord[] = [];
            let total: bigint = BigInt(0);

            // Try different response formats
            if (Array.isArray(result)) {
                // Result is array directly
                transactions = result;
                total = BigInt(result.length);
            } else if (result.transactions && Array.isArray(result.transactions)) {
                // Result has transactions property
                transactions = result.transactions;
                total = result.log_length || BigInt(result.transactions.length);
            } else if (result.logs && Array.isArray(result.logs)) {
                // Result has logs property
                transactions = result.logs;
                total = result.log_length || BigInt(result.logs.length);
            } else if (result.Ok && Array.isArray(result.Ok)) {
                // Result is wrapped in Ok variant
                transactions = result.Ok;
                total = BigInt(result.Ok.length);
            }

            const response: TransactionListResponse = {
                transactions: transactions || [],
                total: total
            };

            console.log('Processed transactions:', response);
            return response;
        } catch (error) {
            console.error(`Error getting transactions for ${canisterId}:`, error);
            return null;
        }
    }

    // Parse ICRC3 Value type to TransactionRecord
    private static parseICRC3Value(value: any, blockIndex: bigint): TransactionRecord | null {
        try {
            // value is a Map structure with keys like "tx", "ts", "fee", "phash"
            if (!value || !value.Map || !Array.isArray(value.Map)) {
                return null;
            }

            // Convert Map array to object
            const blockMap: Record<string, any> = {};
            for (const [key, val] of value.Map) {
                blockMap[key] = val;
            }

            // Extract transaction data
            const txValue = blockMap['tx'];
            if (!txValue || !txValue.Map) {
                return null;
            }

            // Convert tx Map to object
            const txMap: Record<string, any> = {};
            for (const [key, val] of txValue.Map) {
                txMap[key] = val;
            }

            // Helper to extract value from Value variant
            const extractValue = (val: any): any => {
                if (!val) return null;
                if (val.Nat !== undefined) return BigInt(val.Nat);
                if (val.Int !== undefined) return BigInt(val.Int);
                if (val.Blob !== undefined) return new Uint8Array(val.Blob);
                if (val.Text !== undefined) return val.Text;
                if (val.Array !== undefined) return val.Array;
                if (val.Map !== undefined) return val.Map;
                return val;
            };

            // Helper to convert blob to principal string
            const blobToPrincipal = (blob: Uint8Array): string => {
                if (!blob || blob.length === 0) return '';
                try {
                    // Use Principal.fromUint8Array if available from @dfinity/principal
                    return Principal.fromUint8Array(blob).toString();
                } catch (e) {
                    // Fallback to hex representation
                    return Array.from(blob).map(b => b.toString(16).padStart(2, '0')).join('');
                }
            };

            // Extract blob from Value array
            const extractBlob = (arr: any[]): Uint8Array | null => {
                if (!Array.isArray(arr) || arr.length === 0) {
                    return null;
                }
                const firstItem = arr[0];

                if (firstItem && firstItem.Blob) {
                    return new Uint8Array(firstItem.Blob);
                }

                // Maybe the array contains Blob directly?
                if (firstItem && firstItem instanceof Uint8Array) {
                    return firstItem;
                }

                return null;
            };

            // Build TransactionRecord
            // Note: timestamp is in nanoseconds, convert to milliseconds for Date
            const timestampValue = blockMap['ts'] ? extractValue(blockMap['ts']) : BigInt(0);
            const timestampNs = timestampValue instanceof BigInt ? timestampValue : BigInt(timestampValue);
            const timestampMs = Number(timestampNs / BigInt(1000000)); // Convert nanoseconds to milliseconds

            // txMap['from'] is a Value type, need to extract Array first
            const fromValue = txMap['from'] ? extractValue(txMap['from']) : null;
            const toValue = txMap['to'] ? extractValue(txMap['to']) : null;

            const fromBlob = extractBlob(fromValue);
            const toBlob = extractBlob(toValue);

            // Extract spender for approve transactions
            const spenderValue = txMap['spender'] ? extractValue(txMap['spender']) : null;
            const spenderBlob = extractBlob(spenderValue);

            // Extract memo - could be in block or tx
            let memoValue = blockMap['memo'] ? extractValue(blockMap['memo']) : undefined;
            if (!memoValue && txMap['memo']) {
                memoValue = extractValue(txMap['memo']);
            }

            // Extract fee - try multiple locations
            let feeValue: bigint | undefined = undefined;
            const blockFee = blockMap['fee'] ? extractValue(blockMap['fee']) : null;
            const txFee = txMap['fee'] ? extractValue(txMap['fee']) : null;

            if (blockFee) {
                feeValue = blockFee instanceof BigInt ? blockFee : BigInt(blockFee.toString());
            } else if (txFee) {
                feeValue = txFee instanceof BigInt ? txFee : BigInt(txFee.toString());
            }

            // Extract expiresAt for approve transactions
            let expiresAtValue: number | undefined = undefined;
            const expiresAtRaw = txMap['expires_at'] ? extractValue(txMap['expires_at']) : null;
            if (expiresAtRaw) {
                // expiresAt could be in nanoseconds (like timestamp), convert to milliseconds
                const expiresAtNs = expiresAtRaw instanceof BigInt ? expiresAtRaw : BigInt(expiresAtRaw.toString());
                expiresAtValue = Number(expiresAtNs / BigInt(1000000));
            }

            const transaction: TransactionRecord = {
                index: blockIndex, // Use blockIndex from parameter, not from block data
                timestamp: timestampMs,
                kind: txMap['op'] ? extractValue(txMap['op']) : 'unknown',
                amount: txMap['amt'] ? BigInt(extractValue(txMap['amt']).toString()) : undefined,
                fee: feeValue,
                from: fromBlob ? {
                    owner: { toString: () => blobToPrincipal(fromBlob) } as any,
                    subaccount: undefined
                } : undefined,
                to: toBlob ? {
                    owner: { toString: () => blobToPrincipal(toBlob) } as any,
                    subaccount: undefined
                } : undefined,
                spender: spenderBlob ? {
                    owner: { toString: () => blobToPrincipal(spenderBlob) } as any,
                    subaccount: undefined
                } : undefined,
                memo: memoValue,
                expiresAt: expiresAtValue
            };

            return transaction;
        } catch (error) {
            return null;
        }
    }

    // Get a specific block/transaction by index
    public static async getBlockByIndex(
        canisterId: string,
        blockIndex: bigint
    ): Promise<TransactionRecord | null> {
        try {

            const actor = icrcActor({
                canisterId: canisterId.toString(),
                anon: true,
            }) as any;

            // Check if the canister supports icrc3_get_blocks
            const getBlocksMethod =
                actor.icrc3_get_blocks ||
                actor.get_blocks;

            if (!getBlocksMethod) {
                return null;
            }

            // icrc3_get_blocks expects a vec of GetBlocksArgs records
            // Each record has { start: nat; length: nat }
            const params = [
                {
                    start: blockIndex,
                    length: BigInt(1)
                }
            ];

            const result = await getBlocksMethod(params);

            if (!result || !result.blocks || result.blocks.length === 0) {
                return null;
            }

            // Parse the block result - it comes as { id: nat; block: Value }
            const blockData = result.blocks[0];

            if (blockData && blockData.block) {
                // The block data is a Value type (Map variant), need to parse it
                const transaction = this.parseICRC3Value(blockData.block, blockIndex);
                if (transaction) {
                    return transaction;
                }
            }

            return null;
        } catch (error) {
            return null;
        }
    }

    // Parse transaction record into user-friendly format
    public static parseTransactionRecord(record: TransactionRecord): {
        type: string;
        from: string;
        to: string;
        amount: bigint;
    } | null {
        try {
            const kind = record.kind || 'Unknown';

            if (kind === 'Transfer') {
                return {
                    type: 'Transfer',
                    from: record.from?.owner.toString() || 'Unknown',
                    to: record.to?.owner.toString() || 'Unknown',
                    amount: record.amount || BigInt(0),
                };
            } else if (kind === 'Approve') {
                return {
                    type: 'Approve',
                    from: record.from?.owner.toString() || 'Unknown',
                    to: record.spender?.owner.toString() || 'Unknown',
                    amount: record.approved_amount || BigInt(0),
                };
            } else if (kind === 'Mint') {
                return {
                    type: 'Mint',
                    from: 'Minting Account',
                    to: record.to?.owner.toString() || 'Unknown',
                    amount: record.amount || BigInt(0),
                };
            } else if (kind === 'Burn') {
                return {
                    type: 'Burn',
                    from: record.from?.owner.toString() || 'Unknown',
                    to: 'Burn Account',
                    amount: record.amount || BigInt(0),
                };
            }

            return null;
        } catch (error) {
            console.error('Error parsing transaction record:', error);
            return null;
        }
    }
}