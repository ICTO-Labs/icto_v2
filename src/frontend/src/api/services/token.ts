// Token Factory Service - Factory-First V2
// Provides direct queries to Token Factory for user indexes

import type { Principal } from '@dfinity/principal'
import { tokenFactoryActor } from '@/stores/auth'
import { IcrcService } from './icrc'

// ================ TYPES ================

export interface TokenInfo {
  name: string
  symbol: string
  canisterId: Principal
  decimals: number
  transferFee: bigint
  totalSupply: bigint
  description: string[]
  logo: string[]
  website: string[]
  owner: Principal
  deployer: Principal
  deployedAt: bigint
  moduleHash: string
  wasmVersion: string
  standard: string
  features: string[]
  status: TokenStatus
  projectId: string[]
  launchpadId: Principal[]
  lockContracts: Array<[string, Principal]>
  enableCycleOps: boolean
  lastCycleCheck: bigint
  isPublic: boolean // Factory-First V2
  isVerified: boolean // Factory-First V2
}

export type TokenStatus = { Active: null } | { Archived: null } | { Faulty: null }

export interface TokenQueryResult {
  tokens: TokenInfo[]
  total: bigint
}

export interface FactoryStats {
  totalTokens: bigint
  totalCreators: bigint
  publicTokensCount: bigint
  verifiedTokensCount: bigint
}

// ================ TOKEN FACTORY SERVICE ================

class TokenFactoryService {
  /**
   * Get actor for token factory
   */
  private getActor() {
    return tokenFactoryActor({ anon: true })
  }

  // ============= FACTORY-FIRST V2: QUERY FUNCTIONS =============

  /**
   * Get tokens created by a specific user
   */
  async getMyCreatedTokens(
    user: Principal,
    limit: number = 20,
    offset: number = 0
  ): Promise<TokenQueryResult> {
    try {
      const actor = await this.getActor()
      const result = await actor.getMyCreatedTokens(user, BigInt(limit), BigInt(offset))
      return {
        tokens: result.tokens,
        total: result.total
      }
    } catch (error) {
      console.error('Failed to get created tokens:', error)
      throw error
    }
  }

  /**
   * Get public tokens (discoverable)
   */
  async getPublicTokens(
    limit: number = 20,
    offset: number = 0
  ): Promise<TokenQueryResult> {
    try {
      const actor = await this.getActor()
      const result = await actor.getPublicTokens(BigInt(limit), BigInt(offset))
      return {
        tokens: result.tokens,
        total: result.total
      }
    } catch (error) {
      console.error('Failed to get public tokens:', error)
      throw error
    }
  }

  /**
   * Get verified tokens (admin-approved)
   */
  async getVerifiedTokens(
    limit: number = 20,
    offset: number = 0
  ): Promise<TokenQueryResult> {
    try {
      const actor = await this.getActor()
      const result = await actor.getVerifiedTokens(BigInt(limit), BigInt(offset))
      return {
        tokens: result.tokens,
        total: result.total
      }
    } catch (error) {
      console.error('Failed to get verified tokens:', error)
      throw error
    }
  }

  /**
   * Get single token by canister ID
   */
  async getToken(canisterId: Principal): Promise<TokenInfo | null> {
    try {
      const actor = await this.getActor()
      const result = await actor.getToken(canisterId)
      return result.length > 0 ? result[0] : null
    } catch (error) {
      console.error('Failed to get token:', error)
      throw error
    }
  }

  /**
   * Search tokens by name or symbol
   */
  async searchTokens(query: string, limit: number = 20): Promise<TokenInfo[]> {
    try {
      const actor = await this.getActor()
      const result = await actor.searchTokens(query, BigInt(limit))
      return result
    } catch (error) {
      console.error('Failed to search tokens:', error)
      throw error
    }
  }

  /**
   * Get factory statistics
   */
  async getFactoryStats(): Promise<FactoryStats> {
    try {
      const actor = await this.getActor()
      const result = await actor.getFactoryStats()
      return result
    } catch (error) {
      console.error('Failed to get factory stats:', error)
      throw error
    }
  }

  // ============= ADMIN FUNCTIONS =============

  /**
   * Admin: Verify a token
   */
  async verifyToken(tokenId: Principal): Promise<void> {
    try {
      const actor = await this.getActor()
      const result = await actor.verifyToken(tokenId)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Failed to verify token:', error)
      throw error
    }
  }

  /**
   * Admin: Unverify a token
   */
  async unverifyToken(tokenId: Principal): Promise<void> {
    try {
      const actor = await this.getActor()
      const result = await actor.unverifyToken(tokenId)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Failed to unverify token:', error)
      throw error
    }
  }

  /**
   * Admin: Update token visibility
   */
  async updateTokenVisibility(tokenId: Principal, isPublic: boolean): Promise<void> {
    try {
      const actor = await this.getActor()
      const result = await actor.updateTokenVisibility(tokenId, isPublic)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Failed to update token visibility:', error)
      throw error
    }
  }

  /**
   * Admin: Batch verify tokens
   */
  async batchVerifyTokens(tokenIds: Principal[]): Promise<number> {
    try {
      const actor = await this.getActor()
      const result = await actor.batchVerifyTokens(tokenIds)
      if ('err' in result) {
        throw new Error(result.err)
      }
      return Number(result.ok)
    } catch (error) {
      console.error('Failed to batch verify tokens:', error)
      throw error
    }
  }

  // ============= LEGACY FUNCTIONS (Compatibility) =============

  /**
   * Get tokens by owner (legacy - uses new creatorIndex)
   */
  async getTokensByOwner(
    owner: Principal,
    page: number = 0,
    pageSize: number = 20
  ): Promise<TokenInfo[]> {
    const result = await this.getMyCreatedTokens(owner, pageSize, page * pageSize)
    return result.tokens
  }

  /**
   * Get all tokens (legacy - uses publicTokens)
   */
  async getAllTokens(page: number = 0, pageSize: number = 20): Promise<TokenInfo[]> {
    const result = await this.getPublicTokens(pageSize, page * pageSize)
    return result.tokens
  }

  /**
   * Get token info (legacy - uses new getToken)
   */
  async getTokenInfo(canisterId: string): Promise<TokenInfo | null> {
    const principal = Principal.fromText(canisterId)
    return await this.getToken(principal)
  }
}

// Export singleton instance
export const tokenService = new TokenFactoryService()

// Export for composables
export default tokenService
