/**
 * Launchpad Factory Service
 *
 * Service for querying launchpad_factory canister directly (Factory Storage Standard)
 * This bypasses the backend for read operations, providing faster queries and better scalability.
 *
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 */

import { Principal } from '@dfinity/principal';
import { launchpadFactoryActor } from '@/stores/auth';
import type {
  LaunchpadContract,
  LaunchpadFilter
} from '@declarations/launchpad_factory/launchpad_factory.did';

// ============= TYPES =============

// Re-export types from generated declarations
export type LaunchpadInfo = LaunchpadContract;

// TODO: Update these types when pagination is added to launchpad_factory backend
export interface PaginatedResponse {
  sales: LaunchpadInfo[];
  total: bigint;
}

// ============= SERVICE CLASS =============

export class LaunchpadFactoryService {
  /**
   * Get actor instance (authenticated or anonymous)
   * @param anon Use anonymous actor (for public queries)
   */
  private getActor(anon: boolean = false) {
    return launchpadFactoryActor({ anon, requiresSigning: false });
  }

  // ============= STANDARD QUERY FUNCTIONS (Factory Storage Standard) =============

  /**
   * Get launchpads created by user
   * Uses factory's getUserLaunchpads
   * @param user User principal
   * @param limit Number of items per page (default: 20) - Not yet implemented in backend
   * @param offset Page offset (default: 0) - Not yet implemented in backend
   */
  async getMyCreatedSales(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false); // Authenticated query
      const sales = await actor.getUserLaunchpads(user);

      // TODO: Apply pagination client-side until backend supports it
      const paginatedSales = sales.slice(offset, offset + limit);

      return {
        sales: paginatedSales,
        total: BigInt(sales.length),
      };
    } catch (error) {
      console.error('Error fetching created sales:', error);
      throw error;
    }
  }

  /**
   * Get launchpads where user is participant
   * Note: Backend doesn't have participantIndex yet
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyParticipantSales(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      // TODO: Implement when backend supports participant tracking
      // For now, return empty array
      return {
        sales: [],
        total: BigInt(0),
      };
    } catch (error) {
      console.error('Error fetching participant sales:', error);
      throw error;
    }
  }

  /**
   * Get launchpads where user participates (alias for participant)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyParticipatingSales(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    return this.getMyParticipantSales(user, limit, offset);
  }

  /**
   * Get all launchpads for user (created + participant, deduplicated)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyAllSales(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      // For now, just return created sales
      // TODO: Merge with participant sales when available
      return this.getMyCreatedSales(user, limit, offset);
    } catch (error) {
      console.error('Error fetching all sales:', error);
      throw error;
    }
  }

  /**
   * Get public launchpads (anyone can discover)
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getPublicSales(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query for public data

      // Use getAllLaunchpads with filter for active sales
      const filter: LaunchpadFilter = {
        status: [{ Active: null }], // Only active sales
        creator: [],
        tokenCanister: [],
      };

      const sales = await actor.getAllLaunchpads([filter]);

      // Apply pagination client-side
      const paginatedSales = sales.slice(offset, offset + limit);

      return {
        sales: paginatedSales,
        total: BigInt(sales.length),
      };
    } catch (error) {
      console.error('Error fetching public sales:', error);
      throw error;
    }
  }

  /**
   * Get active launchpads
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getActiveSales(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    return this.getPublicSales(limit, offset);
  }

  /**
   * Get all launchpads with optional filter
   * @param filter Optional filter criteria
   */
  async getAllSales(filter?: LaunchpadFilter): Promise<LaunchpadInfo[]> {
    try {
      const actor = this.getActor(true);
      const sales = await actor.getAllLaunchpads(filter ? [filter] : []);
      return sales;
    } catch (error) {
      console.error('Error fetching all sales:', error);
      throw error;
    }
  }

  /**
   * Get single launchpad by contract ID
   * @param contractId Launchpad contract ID as text
   */
  async getLaunchpadInfo(contractId: string): Promise<LaunchpadInfo | null> {
    try {
      const actor = this.getActor(true); // Can use anonymous for single query
      const result = await actor.getLaunchpad(contractId);
      // Motoko optional returns [] for None, [value] for Some
      return result.length > 0 ? result[0] : null;
    } catch (error) {
      console.error('Error fetching launchpad info:', error);
      throw error;
    }
  }

  /**
   * Get single launchpad by Principal
   * @param contractId Launchpad contract principal
   */
  async getLaunchpadInfoByPrincipal(contractId: Principal): Promise<LaunchpadInfo | null> {
    return this.getLaunchpadInfo(contractId.toString());
  }

  /**
   * Convert LaunchpadInfo to display format
   */
  static formatLaunchpadInfo(info: LaunchpadInfo): {
    id: string;
    title: string;
    description: string;
    creator: string;
    tokenSymbol: string;
    softCap: string;
    hardCap: string;
    startTime: Date;
    endTime: Date;
    status: string;
    createdAt: Date;
  } {
    return {
      id: info.canisterId.toString(),
      title: info.title,
      description: info.description,
      creator: info.creator.toString(),
      tokenSymbol: info.tokenSymbol,
      softCap: info.softCap.toString(),
      hardCap: info.hardCap.toString(),
      startTime: new Date(Number(info.startTime) / 1_000_000),
      endTime: new Date(Number(info.endTime) / 1_000_000),
      status: 'Active' in info.status ? 'Active' :
              'Paused' in info.status ? 'Paused' :
              'Completed' in info.status ? 'Completed' :
              'Cancelled' in info.status ? 'Cancelled' : 'Unknown',
      createdAt: new Date(Number(info.createdAt) / 1_000_000),
    };
  }

  /**
   * Batch format multiple launchpads
   */
  static formatLaunchpads(sales: LaunchpadInfo[]) {
    return sales.map(sale => this.formatLaunchpadInfo(sale));
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

export const launchpadFactoryService = new LaunchpadFactoryService();
