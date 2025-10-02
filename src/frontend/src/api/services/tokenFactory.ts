/**
 * Token Factory Service
 *
 * Service for querying token_factory canister directly (Factory Storage Standard)
 * This bypasses the backend for read operations, providing faster queries and better scalability.
 *
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 */

import { Principal } from '@dfinity/principal';
import { tokenFactoryActor } from '@/stores/auth';
import type {
  TokenInfo as TokenInfoCandid
} from '../../../../declarations/token_factory/token_factory.did';

// ============= TYPES =============

// Re-export types from generated declarations
export type TokenInfo = TokenInfoCandid;

export interface PaginatedResponse {
  tokens: TokenInfo[];
  total: bigint;
}

// ============= SERVICE CLASS =============

export class TokenFactoryService {
  /**
   * Get actor instance (authenticated or anonymous)
   * @param anon Use anonymous actor (for public queries)
   */
  private getActor(anon: boolean = false) {
    return tokenFactoryActor({ anon, requiresSigning: false });
  }

  // ============= STANDARD QUERY FUNCTIONS (Factory Storage Standard) =============

  /**
   * Get tokens created by user
   * Uses factory's creatorIndex (populated on deployment)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyCreatedTokens(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false); // Authenticated query

      // Backend expects page number (1-indexed) and pageSize
      const page = Math.floor(offset / limit) + 1;
      const tokens = await actor.getMyCreatedTokens(user, BigInt(page), BigInt(limit));

      // Get total count
      const total = await actor.getTotalTokens();

      return {
        tokens,
        total: BigInt(total),
      };
    } catch (error) {
      console.error('Error fetching created tokens:', error);
      throw error;
    }
  }

  /**
   * Get tokens held by user
   * Note: Backend doesn't have holderIndex yet, this is a placeholder
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyHeldTokens(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      // TODO: Implement when backend supports holder tracking
      // For now, return empty array
      return {
        tokens: [],
        total: BigInt(0),
      };
    } catch (error) {
      console.error('Error fetching held tokens:', error);
      throw error;
    }
  }

  /**
   * Get tokens where user participates (alias for held)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyParticipatingTokens(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    // For tokens, "participating" means "held"
    return this.getMyHeldTokens(user, limit, offset);
  }

  /**
   * Get all tokens for user (created + held, deduplicated)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyAllTokens(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      // For now, just return created tokens
      // TODO: Merge with held tokens when available
      return this.getMyCreatedTokens(user, limit, offset);
    } catch (error) {
      console.error('Error fetching all tokens:', error);
      throw error;
    }
  }

  /**
   * Get public tokens (anyone can discover)
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getPublicTokens(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query for public data

      // Backend expects page number (1-indexed) and pageSize
      const page = Math.floor(offset / limit) + 1;
      const tokens = await actor.getPublicTokens(BigInt(page), BigInt(limit));

      // Get total count of public tokens
      const total = await actor.getTotalTokens(); // TODO: Should be public tokens count

      return {
        tokens,
        total: BigInt(total),
      };
    } catch (error) {
      console.error('Error fetching public tokens:', error);
      throw error;
    }
  }

  /**
   * Get verified tokens
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getVerifiedTokens(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query for public data

      // Backend expects page number (1-indexed) and pageSize
      const page = Math.floor(offset / limit) + 1;
      const tokens = await actor.getVerifiedTokens(BigInt(page), BigInt(limit));

      // Get total count
      const total = await actor.getTotalTokens(); // TODO: Should be verified tokens count

      return {
        tokens,
        total: BigInt(total),
      };
    } catch (error) {
      console.error('Error fetching verified tokens:', error);
      throw error;
    }
  }

  /**
   * Search tokens by name or symbol
   * @param query Search query
   * @param limit Number of results (default: 20)
   */
  async searchTokens(query: string, limit: number = 20): Promise<TokenInfo[]> {
    try {
      const actor = this.getActor(true); // Anonymous query

      // Get all tokens and filter client-side
      // TODO: Implement backend search when available
      const allTokens = await actor.getAllTokens(BigInt(1), BigInt(100));

      const searchQuery = query.toLowerCase();
      const filtered = allTokens.filter(token => {
        const name = token.name.toLowerCase();
        const symbol = token.symbol.toLowerCase();
        return name.includes(searchQuery) || symbol.includes(searchQuery);
      });

      return filtered.slice(0, limit);
    } catch (error) {
      console.error('Error searching tokens:', error);
      throw error;
    }
  }

  /**
   * Get single token by contract ID
   * @param contractId Token contract principal
   */
  async getTokenInfo(contractId: Principal): Promise<TokenInfo | null> {
    try {
      const actor = this.getActor(true); // Can use anonymous for single query
      const result = await actor.getToken(contractId);
      // Motoko optional returns [] for None, [value] for Some
      return result.length > 0 ? result[0] : null;
    } catch (error) {
      console.error('Error fetching token info:', error);
      throw error;
    }
  }

  /**
   * Get token by text ID (legacy support)
   * @param canisterId Token contract ID as text
   */
  async getTokenInfoByText(canisterId: string): Promise<TokenInfo | null> {
    try {
      const actor = this.getActor(true);
      const result = await actor.getTokenInfo(canisterId);
      return result.length > 0 ? result[0] : null;
    } catch (error) {
      console.error('Error fetching token info by text:', error);
      throw error;
    }
  }

  /**
   * Convert TokenInfo to display format
   */
  static formatTokenInfo(info: TokenInfo): {
    id: string;
    name: string;
    symbol: string;
    decimals: number;
    totalSupply: string;
    creator: string;
    isPublic: boolean;
    isVerified: boolean;
    createdAt: Date;
  } {
    return {
      id: info.canisterId.toString(),
      name: info.name,
      symbol: info.symbol,
      decimals: Number(info.decimals),
      totalSupply: info.totalSupply.toString(),
      creator: info.owner.toString(),
      isPublic: info.isPublic,
      isVerified: info.isVerified,
      createdAt: new Date(Number(info.createdAt) / 1_000_000), // Convert nanoseconds to milliseconds
    };
  }

  /**
   * Batch format multiple tokens
   */
  static formatTokens(tokens: TokenInfo[]) {
    return tokens.map(token => this.formatTokenInfo(token));
  }

  /**
   * Get total tokens count
   */
  async getTotalTokens(): Promise<number> {
    try {
      const actor = this.getActor(true);
      const total = await actor.getTotalTokens();
      return total;
    } catch (error) {
      console.error('Error fetching total tokens:', error);
      throw error;
    }
  }
}

// ============= SINGLETON INSTANCE =============

export const tokenFactoryService = new TokenFactoryService();
