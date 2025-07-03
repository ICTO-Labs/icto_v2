import type { Principal } from "@dfinity/principal";
export interface TokenBalanceBase {
  inTokens: bigint;
  inUsd: string;
}
export interface TokensByCanisterRequest {
  canisterIds: string[];
}
export interface TokenMetrics {
  price: number;
  volume: number;
  marketCap: number;
  totalSupply: number;
}
export interface Token {
  name: string;
  symbol: string;
  decimals: number;
  fee: number;
  logoUrl: string | null;
  standards: string[];
  metrics: TokenMetrics;
  canisterId: string;
}
export interface TokenData {
  address: string;
  symbol: string;
  name: string;
  decimals: number;
  fee: bigint;
  metadata: Array<[string, { Int: bigint } | { Text: string }]>;
  totalSupply: bigint;
  balance?: bigint;
}

export interface TokenBalance {
  token: Token;
  balance: bigint;
  formattedBalance?: string;
}

export interface TokenBalanceMap {
  [key: string]: TokenBalance;
}

export interface BalanceResponse {
  balances: { [key: string]: bigint };
  errors: { [key: string]: string };
}

export interface TokenMetadata {
  name: string;
  symbol: string;
  decimals: number;
  fee: bigint;
  totalSupply: bigint;
  [key: string]: any;
} 