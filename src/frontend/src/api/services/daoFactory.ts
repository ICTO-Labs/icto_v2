/**
 * DAO Factory Service
 *
 * Service for querying dao_factory canister directly (Factory Storage Standard)
 * This bypasses the backend for read operations, providing faster queries and better scalability.
 *
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 */

import { Principal } from '@dfinity/principal';
import { daoFactoryActor } from '@/stores/auth';
import type {
  DAOContract
} from '../../../../declarations/dao_factory/dao_factory.did';

// ============= TYPES =============

// Re-export types from generated declarations
export type DAOInfo = DAOContract;

// TODO: Update these types when pagination is added to dao_factory backend
export interface PaginatedResponse {
  daos: DAOInfo[];
  total: bigint;
}

// ============= SERVICE CLASS =============

export class DAOFactoryService {
  /**
   * Get actor instance (authenticated or anonymous)
   * @param anon Use anonymous actor (for public queries)
   */
  private getActor(anon: boolean = false) {
    return daoFactoryActor({ anon, requiresSigning: false });
  }

  // ============= STANDARD QUERY FUNCTIONS (Factory Storage Standard) =============

  /**
   * Get DAOs created by user
   * Uses factory's getUserDAOs
   * @param user User principal
   * @param limit Number of items per page (default: 20) - Not yet implemented in backend
   * @param offset Page offset (default: 0) - Not yet implemented in backend
   */
  async getMyCreatedDAOs(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false); // Authenticated query
      const daos = await actor.getUserDAOs(user);

      // TODO: Apply pagination client-side until backend supports it
      const paginatedDAOs = daos.slice(offset, offset + limit);

      return {
        daos: paginatedDAOs,
        total: BigInt(daos.length),
      };
    } catch (error) {
      console.error('Error fetching created DAOs:', error);
      throw error;
    }
  }

  /**
   * Get DAOs where user is member
   * Note: Backend doesn't have memberIndex yet, filtering client-side
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyMemberDAOs(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false);
      const allDAOs = await actor.listDAOs(0, 1000); // Get all DAOs

      // Filter DAOs where user is a member
      // TODO: This requires checking membership on each DAO contract
      // For now, just return empty array - should be implemented with proper indexing
      const memberDAOs: DAOInfo[] = [];

      // Apply pagination
      const paginatedDAOs = memberDAOs.slice(offset, offset + limit);

      return {
        daos: paginatedDAOs,
        total: BigInt(memberDAOs.length),
      };
    } catch (error) {
      console.error('Error fetching member DAOs:', error);
      throw error;
    }
  }

  /**
   * Get DAOs where user participates (alias for member)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyParticipatingDAOs(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    // For DAOs, "participating" means "member"
    return this.getMyMemberDAOs(user, limit, offset);
  }

  /**
   * Get all DAOs for user (created + member, deduplicated)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyAllDAOs(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      // For now, just return created DAOs
      // TODO: Merge with member DAOs when membership tracking is available
      return this.getMyCreatedDAOs(user, limit, offset);
    } catch (error) {
      console.error('Error fetching all DAOs:', error);
      throw error;
    }
  }

  /**
   * Get public DAOs (anyone can discover)
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getPublicDAOs(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query for public data

      // Use listDAOs with pagination
      const daos = await actor.listDAOs(offset, limit);

      // Get total count from factory stats
      const stats = await actor.getFactoryStats();

      return {
        daos,
        total: BigInt(stats.totalDAOs),
      };
    } catch (error) {
      console.error('Error fetching public DAOs:', error);
      throw error;
    }
  }

  /**
   * Get single DAO by contract ID
   * @param contractId DAO contract ID as text
   */
  async getDAOInfo(contractId: string): Promise<DAOInfo | null> {
    try {
      const actor = this.getActor(true); // Can use anonymous for single query
      const result = await actor.getDAOInfo(contractId);
      // Motoko optional returns [] for None, [value] for Some
      return result.length > 0 ? result[0] : null;
    } catch (error) {
      console.error('Error fetching DAO info:', error);
      throw error;
    }
  }

  /**
   * Get single DAO by Principal
   * @param contractId DAO contract principal
   */
  async getDAOInfoByPrincipal(contractId: Principal): Promise<DAOInfo | null> {
    return this.getDAOInfo(contractId.toString());
  }

  /**
   * Convert DAOInfo to display format
   */
  static formatDAOInfo(info: DAOInfo): {
    id: string;
    name: string;
    description: string;
    creator: string;
    tokenSymbol: string;
    createdAt: Date;
    status: string;
  } {
    return {
      id: info.canisterId.toString(),
      name: info.name,
      description: info.description.length > 0 ? info.description[0] : '',
      creator: info.creator.toString(),
      tokenSymbol: info.tokenSymbol,
      createdAt: new Date(Number(info.createdAt) / 1_000_000), // Convert nanoseconds to milliseconds
      status: 'Active' in info.status ? 'Active' :
              'Paused' in info.status ? 'Paused' : 'Archived',
    };
  }

  /**
   * Batch format multiple DAOs
   */
  static formatDAOs(daos: DAOInfo[]) {
    return daos.map(dao => this.formatDAOInfo(dao));
  }

  /**
   * Get factory statistics
   */
  async getFactoryStats() {
    try {
      const actor = this.getActor(true);
      const stats = await actor.getFactoryStats();
      return stats;
    } catch (error) {
      console.error('Error fetching factory stats:', error);
      throw error;
    }
  }
}

// ============= SINGLETON INSTANCE =============

export const daoFactoryService = new DAOFactoryService();
