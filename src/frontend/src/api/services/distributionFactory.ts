/**
 * Distribution Factory Service
 *
 * Service for querying distribution_factory canister directly (Factory Storage Standard)
 * This bypasses the backend for read operations, providing faster queries and better scalability.
 *
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 */

import { Principal } from '@dfinity/principal';
import { distributionFactoryActor } from '@/stores/auth';
import type {
  DistributionInfo as DistributionInfoCandid,
  PaginatedResponse as PaginatedResponseCandid
} from '@declarations/distribution_factory/distribution_factory.did';

// ============= TYPES =============

// Re-export types from generated declarations
export type DistributionInfo = DistributionInfoCandid;
export type PaginatedResponse = PaginatedResponseCandid;

// ============= SERVICE CLASS =============

export class DistributionFactoryService {
  /**
   * Get actor instance (authenticated or anonymous)
   * @param anon Use anonymous actor (for public queries)
   */
  private getActor(anon: boolean = false) {
    return distributionFactoryActor({ anon, requiresSigning: false });
  }

  // ============= STANDARD QUERY FUNCTIONS (Factory Storage Standard) =============

  /**
   * Get distributions created by user
   * Uses factory's creatorIndex (populated on deployment)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyCreatedDistributions(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false); // Authenticated query
      const result = await actor.getMyCreatedDistributions(user, limit, offset);
      return {
        distributions: result.distributions,
        total: result.total,
      };
    } catch (error) {
      console.error('Error fetching created distributions:', error);
      throw error;
    }
  }

  /**
   * Get distributions where user is recipient
   * Uses factory's recipientIndex (populated via contract callbacks)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyRecipientDistributions(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false);
      const result = await actor.getMyRecipientDistributions(user, limit, offset);
      return {
        distributions: result.distributions,
        total: result.total,
      };
    } catch (error) {
      console.error('Error fetching recipient distributions:', error);
      throw error;
    }
  }

  /**
   * Get distributions where user participates (alias for recipient)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyParticipatingDistributions(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    // For distributions, "participating" means "recipient"
    return this.getMyRecipientDistributions(user, limit, offset);
  }

  /**
   * Get all distributions for user (created + recipient, deduplicated)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyAllDistributions(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false);
      const result = await actor.getMyAllDistributions(user, limit, offset);
      return {
        distributions: result.distributions,
        total: result.total,
      };
    } catch (error) {
      console.error('Error fetching all distributions:', error);
      throw error;
    }
  }

  /**
   * Get public distributions (anyone can discover)
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getPublicDistributions(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query for public data
      const result = await actor.getPublicDistributions(limit, offset);
      return {
        distributions: result.distributions,
        total: result.total,
      };
    } catch (error) {
      console.error('Error fetching public distributions:', error);
      throw error;
    }
  }
  /**
   * Get distributions by Token ID
   * @param tokenId Token Principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getDistributionsByToken(
    tokenId: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query allowed
      const result = await actor.getDistributionsByToken(tokenId, limit, offset);
      return {
        distributions: result.distributions,
        total: result.total,
      };
    } catch (error) {
      console.error('Error fetching distributions by token:', error);
      throw error;
    }
  }

  /**
   * Get single distribution by contract ID
   * @param contractId Distribution contract principal
   */
  async getDistributionInfo(contractId: Principal): Promise<DistributionInfo | null> {
    try {
      const actor = this.getActor(true); // Can use anonymous for single query
      const result = await actor.getDistributionInfo(contractId);
      // Motoko optional returns [] for None, [value] for Some
      return result.length > 0 ? result[0] : null;
    } catch (error) {
      console.error('Error fetching distribution info:', error);
      throw error;
    }
  }

  /**
   * Convert DistributionInfo to display format
   */
  static formatDistributionInfo(info: DistributionInfo): {
    id: string;
    title: string;
    description: string;
    creator: string;
    recipientCount: number;
    totalAmount: string;
    tokenSymbol: string;
    isPublic: boolean;
    createdAt: Date;
    isActive: boolean;
  } {
    return {
      id: info.contractId.toString(),
      title: info.title,
      description: info.description,
      creator: info.creator.toString(),
      recipientCount: info.recipientCount,
      totalAmount: info.totalAmount.toString(),
      tokenSymbol: info.tokenSymbol,
      isPublic: info.isPublic,
      createdAt: new Date(Number(info.createdAt) / 1_000_000), // Convert nanoseconds to milliseconds
      isActive: info.isActive,
    };
  }

  /**
   * Batch format multiple distributions
   */
  static formatDistributions(distributions: DistributionInfo[]) {
    return distributions.map(dist => this.formatDistributionInfo(dist));
  }
}

// ============= SINGLETON INSTANCE =============

export const distributionFactoryService = new DistributionFactoryService();