/**
 * Multisig Factory Service
 *
 * Service for querying multisig_factory canister directly (Factory Storage Standard)
 * This bypasses the backend for read operations, providing faster queries and better scalability.
 *
 * Based on: FACTORY_STORAGE_STANDARD.md and FRONTEND_QUERY_STANDARD.md
 */

import { Principal } from '@dfinity/principal';
import { multisigFactoryActor } from '@/stores/auth';
import type {
  WalletRegistry
} from '../../../../declarations/multisig_factory/multisig_factory.did';

// ============= TYPES =============

// Re-export types from generated declarations
export type WalletInfo = WalletRegistry;

// TODO: Update these types when pagination is added to multisig_factory backend
export interface PaginatedResponse {
  wallets: WalletInfo[];
  total: bigint;
}

// ============= SERVICE CLASS =============

export class MultisigFactoryService {
  /**
   * Get actor instance (authenticated or anonymous)
   * @param anon Use anonymous actor (for public queries)
   */
  private getActor(anon: boolean = false) {
    return multisigFactoryActor({ anon, requiresSigning: false });
  }

  // ============= STANDARD QUERY FUNCTIONS (Factory Storage Standard) =============

  /**
   * Get wallets created by user
   * Currently uses getWalletsByCreator (to be replaced with paginated version)
   * @param user User principal
   * @param limit Number of items per page (default: 20) - Not yet implemented in backend
   * @param offset Page offset (default: 0) - Not yet implemented in backend
   */
  async getMyCreatedWallets(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false); // Authenticated query
      const wallets = await actor.getWalletsByCreator(user);

      // TODO: Apply pagination client-side until backend supports it
      const paginatedWallets = wallets.slice(offset, offset + limit);

      return {
        wallets: paginatedWallets,
        total: BigInt(wallets.length),
      };
    } catch (error) {
      console.error('Error fetching created wallets:', error);
      throw error;
    }
  }

  /**
   * Get wallets where user is signer
   * Note: Backend doesn't have signerIndex yet, filtering client-side
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMySignerWallets(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false);
      const allWallets = await actor.getAllWallets();

      // Filter wallets where user is a signer
      const signerWallets = allWallets.filter(wallet =>
        wallet.config.signers.some(signer =>
          signer.principal.toString() === user.toString()
        )
      );

      // Apply pagination
      const paginatedWallets = signerWallets.slice(offset, offset + limit);

      return {
        wallets: paginatedWallets,
        total: BigInt(signerWallets.length),
      };
    } catch (error) {
      console.error('Error fetching signer wallets:', error);
      throw error;
    }
  }

  /**
   * Get wallets where user is observer
   * Note: Observer index not yet implemented, filtering client-side
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyObserverWallets(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false);
      const allWallets = await actor.getAllWallets();

      // Filter wallets where user is an observer
      const observerWallets = allWallets.filter(wallet =>
        wallet.config.signers.some(signer =>
          signer.principal.toString() === user.toString() &&
          'Observer' in signer.role
        )
      );

      // Apply pagination
      const paginatedWallets = observerWallets.slice(offset, offset + limit);

      return {
        wallets: paginatedWallets,
        total: BigInt(observerWallets.length),
      };
    } catch (error) {
      console.error('Error fetching observer wallets:', error);
      throw error;
    }
  }

  /**
   * Get all wallets for user (created + signer + observer, deduplicated)
   * @param user User principal
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getMyAllWallets(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(false);
      const allWallets = await actor.getAllWallets();

      // Filter wallets where user has any role
      const userWallets = allWallets.filter(wallet => {
        const isCreator = wallet.creator.toString() === user.toString();
        const isSigner = wallet.config.signers.some(signer =>
          signer.principal.toString() === user.toString()
        );
        return isCreator || isSigner;
      });

      // Deduplicate by canisterId
      const uniqueWallets = Array.from(
        new Map(userWallets.map(w => [w.canisterId.toString(), w])).values()
      );

      // Apply pagination
      const paginatedWallets = uniqueWallets.slice(offset, offset + limit);

      return {
        wallets: paginatedWallets,
        total: BigInt(uniqueWallets.length),
      };
    } catch (error) {
      console.error('Error fetching all wallets:', error);
      throw error;
    }
  }

  /**
   * Get public wallets (anyone can discover)
   * @param limit Number of items per page (default: 20)
   * @param offset Page offset (default: 0)
   */
  async getPublicWallets(
    limit: number = 20,
    offset: number = 0
  ): Promise<PaginatedResponse> {
    try {
      const actor = this.getActor(true); // Anonymous query for public data
      const allWallets = await actor.getAllWallets();

      // Filter public wallets
      const publicWallets = allWallets.filter(wallet => wallet.config.isPublic);

      // Apply pagination
      const paginatedWallets = publicWallets.slice(offset, offset + limit);

      return {
        wallets: paginatedWallets,
        total: BigInt(publicWallets.length),
      };
    } catch (error) {
      console.error('Error fetching public wallets:', error);
      throw error;
    }
  }

  /**
   * Get single wallet by canisterId (Principal) or WalletId (fallback)
   * @param identifier Canister ID (Principal) or Wallet ID (text) from factory
   */
  async getWallet(identifier: string): Promise<WalletInfo | null> {
    try {
      const actor = this.getActor(true); // Can use anonymous for single query

      // First try to get wallet by canisterId (preferred method)
      try {
        const { Principal } = await import('@dfinity/principal');
        const principalId = Principal.fromText(identifier);
        const resultByCanister = await (actor as any).getWalletByCanisterId(principalId);

        // Motoko optional: [] = None, [value] = Some
        if (Array.isArray(resultByCanister) && resultByCanister.length > 0) {
          return resultByCanister[0];
        }
      } catch (canisterError) {
        // Continue to fallback
      }

      // Fallback: try WalletId lookup (for backward compatibility)
      const result = await actor.getWallet(identifier);

      // Motoko optional: [] = None, [value] = Some
      if (Array.isArray(result) && result.length > 0) {
        return result[0];
      }

      return null;
    } catch (error) {
      console.error('Error fetching wallet:', error);
      throw error;
    }
  }

  
  /**
   * Get user's role in a wallet
   * @param user User principal
   * @param canisterId Wallet contract principal (as string)
   */
  async getUserRole(
    user: Principal,
    canisterId: string
  ): Promise<'Creator' | 'Signer' | 'Observer' | null> {
    try {
      const wallet = await this.getWallet(canisterId);
      if (!wallet) return null;

      // Check if creator
      if (wallet.creator.toString() === user.toString()) {
        return 'Creator';
      }

      // Check if signer or observer
      const signerInfo = wallet.config.signers.find(s =>
        s.principal.toString() === user.toString()
      );

      if (!signerInfo) return null;

      if ('Observer' in signerInfo.role) return 'Observer';
      return 'Signer';
    } catch (error) {
      console.error('Error getting user role:', error);
      throw error;
    }
  }

  /**
   * Convert WalletInfo to display format
   */
  static formatWalletInfo(info: WalletInfo): {
    id: string;
    name: string;
    description: string;
    creator: string;
    threshold: number;
    signerCount: number;
    isPublic: boolean;
    createdAt: Date;
    status: string;
  } {
    return {
      id: info.canisterId.toString(),
      name: info.config.name,
      description: info.config.description.length > 0 ? info.config.description[0] : '',
      creator: info.creator.toString(),
      threshold: info.config.threshold,
      signerCount: info.config.signers.length,
      isPublic: info.config.isPublic,
      createdAt: new Date((typeof info.createdAt === 'bigint' ? Number(info.createdAt) : info.createdAt) / 1_000_000), // Convert nanoseconds to milliseconds
      status: 'Active' in info.status ? 'Active' :
              'Paused' in info.status ? 'Paused' : 'Archived',
    };
  }

  /**
   * Batch format multiple wallets
   */
  static formatWallets(wallets: WalletInfo[]) {
    return wallets.map(wallet => this.formatWalletInfo(wallet));
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

export const multisigFactoryService = new MultisigFactoryService();
