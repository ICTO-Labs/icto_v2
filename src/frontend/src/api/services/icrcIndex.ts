import { useAuthStore, icrcIndexActor } from "@/stores/auth";
import { Principal } from "@dfinity/principal";
import type {
  Account,
  GetAccountTransactionsArgs,
  GetTransactionsResult,
  TransactionWithId,
  Transaction,
} from "@declarations/icrc_index/icrc_index.did";

export interface AccountTransactionsResponse {
  balance: bigint;
  transactions: TransactionWithId[];
  oldestTxId?: bigint;
}

export class IcrcIndexService {
  /**
   * Get all transactions for a specific account using the Index canister
   * @param indexCanisterId - The index canister ID
   * @param account - The account to query (owner principal + optional subaccount)
   * @param maxResults - Maximum number of transactions to fetch
   * @param start - Optional transaction ID to start from (exclusive)
   */
  public static async getAccountTransactions(
    indexCanisterId: string,
    account: Account,
    maxResults: bigint = BigInt(100),
    start?: bigint
  ): Promise<AccountTransactionsResponse | null> {
    try {
      const actor = icrcIndexActor({
        canisterId: indexCanisterId.toString(),
        anon: true,
      });

      const args: GetAccountTransactionsArgs = {
        account,
        max_results: maxResults,
        start: start ? [start] : [],
      };

      const result = (await actor.get_account_transactions(args)) as GetTransactionsResult;

      if ("Ok" in result) {
        return {
          balance: result.Ok.balance,
          transactions: result.Ok.transactions,
          oldestTxId: result.Ok.oldest_tx_id[0],
        };
      } else {
        console.error("Error fetching account transactions:", result.Err.message);
        return null;
      }
    } catch (error) {
      console.error("Error getting account transactions from index:", error);
      return null;
    }
  }

  /**
   * Get all transactions for an account by fetching in batches
   * @param indexCanisterId - The index canister ID
   * @param principal - The principal to query
   * @param subaccount - Optional subaccount
   * @param batchSize - Number of transactions per fetch
   */
  public static async getAllAccountTransactions(
    indexCanisterId: string,
    principal: string | Principal,
    subaccount?: Uint8Array | number[],
    batchSize: bigint = BigInt(100)
  ): Promise<TransactionWithId[]> {
    try {
      const principalObj = typeof principal === "string" ? Principal.fromText(principal) : principal;

      const account: Account = {
        owner: principalObj,
        subaccount: subaccount ? [subaccount] : [],
      };

      const allTransactions: TransactionWithId[] = [];
      let start: bigint | undefined;
      let hasMore = true;

      while (hasMore) {
        const result = await this.getAccountTransactions(
          indexCanisterId,
          account,
          batchSize,
          start
        );

        if (!result) {
          break;
        }

        allTransactions.push(...result.transactions);

        // If we got fewer transactions than requested or oldest_tx_id is not set, we've reached the end
        if (result.transactions.length < Number(batchSize) || !result.oldestTxId) {
          hasMore = false;
        } else {
          // Set start to the last transaction's ID for next batch (exclusive)
          start = result.oldestTxId;
        }
      }

      return allTransactions;
    } catch (error) {
      console.error("Error getting all account transactions:", error);
      return [];
    }
  }

  /**
   * Get account balance from the index
   * @param indexCanisterId - The index canister ID
   * @param principal - The principal to query
   * @param subaccount - Optional subaccount
   */
  public static async getAccountBalance(
    indexCanisterId: string,
    principal: string | Principal,
    subaccount?: Uint8Array | number[]
  ): Promise<bigint | null> {
    try {
      const actor = icrcIndexActor({
        canisterId: indexCanisterId.toString(),
        anon: true,
      });

      const principalObj = typeof principal === "string" ? Principal.fromText(principal) : principal;

      const account: Account = {
        owner: principalObj,
        subaccount: subaccount ? [subaccount] : [],
      };

      const balance = (await actor.icrc1_balance_of(account)) as bigint;
      return balance;
    } catch (error) {
      console.error("Error getting account balance from index:", error);
      return null;
    }
  }

  /**
   * List all subaccounts for a principal
   * @param indexCanisterId - The index canister ID
   * @param principal - The principal to query
   * @param start - Optional subaccount to start from
   */
  public static async listSubaccounts(
    indexCanisterId: string,
    principal: string | Principal,
    start?: Uint8Array | number[]
  ): Promise<(Uint8Array | number[])[]> {
    try {
      const actor = icrcIndexActor({
        canisterId: indexCanisterId.toString(),
        anon: true,
      });

      const principalObj = typeof principal === "string" ? Principal.fromText(principal) : principal;

      const subaccounts = (await actor.list_subaccounts({
        owner: principalObj,
        start: start ? [start] : [],
      })) as (Uint8Array | number[])[];

      return subaccounts;
    } catch (error) {
      console.error("Error listing subaccounts:", error);
      return [];
    }
  }

  /**
   * Get the status of the index canister
   * @param indexCanisterId - The index canister ID
   */
  public static async getStatus(indexCanisterId: string) {
    try {
      const actor = icrcIndexActor({
        canisterId: indexCanisterId.toString(),
        anon: true,
      });

      const status = await actor.status();
      return status;
    } catch (error) {
      console.error("Error getting index status:", error);
      return null;
    }
  }

  /**
   * Get ledger ID from the index
   * @param indexCanisterId - The index canister ID
   */
  public static async getLedgerId(indexCanisterId: string): Promise<Principal | null> {
    try {
      const actor = icrcIndexActor({
        canisterId: indexCanisterId.toString(),
        anon: true,
      });

      const ledgerId = (await actor.ledger_id()) as Principal;
      return ledgerId;
    } catch (error) {
      console.error("Error getting ledger ID:", error);
      return null;
    }
  }
}
