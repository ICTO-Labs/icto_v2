import type { Principal } from "@dfinity/principal";

export type TransactionType = "Transfer" | "Approve" | "Mint" | "Burn" | "Unknown";
export type TransactionStatus = "Completed" | "Failed" | "Pending";

export interface IcrcAccount {
  owner: Principal;
  subaccount?: Uint8Array | number[];
}

// Raw transaction from ICRC canister
export interface TransactionRecord {
  index?: bigint;
  kind: string;
  timestamp: string | bigint;
  amount?: bigint;
  from?: IcrcAccount;
  to?: IcrcAccount;
  fee?: bigint;
  memo?: Uint8Array | number[];
  approved_amount?: bigint;
  spender?: IcrcAccount;
  allowance_expected?: bigint;
  expiresAt?: number;

  // New format fields
  mint?: Array<{
    to: IcrcAccount;
    memo?: number[];
    created_at_time?: string[];
    amount: string;
  }>;
  transfer?: Array<{
    from: IcrcAccount;
    to: IcrcAccount;
    amount: string;
    memo?: number[];
    created_at_time?: string[];
    fee?: string;
  }>;
  approve?: Array<{
    from: IcrcAccount;
    spender: IcrcAccount;
    amount: string;
    expires_at?: string[];
    memo?: number[];
  }>;
  burn?: Array<{
    from: IcrcAccount;
    amount: string;
    memo?: number[];
  }>;
}

export interface Transaction {
  index: bigint;
  type: TransactionType;
  amount: bigint;
  from: string;
  to: string;
  timestamp: bigint;
  fee?: bigint;
  memo?: string;
  status: TransactionStatus;
  hash?: string;
}

export interface TransactionDetail extends Transaction {
  rawData?: TransactionRecord;
  blockIndex?: bigint;
}

export interface TransactionListResponse {
  transactions: TransactionRecord[];
  total: bigint;
}

export interface TransactionListParams {
  start: bigint;
  length: bigint;
}
