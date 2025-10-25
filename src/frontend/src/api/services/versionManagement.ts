/**
 * Generic Version Management Service
 * Works with all factory types (Launchpad, DAO, Token, Distribution, Multisig)
 */

import {
  launchpadFactoryActor,
  launchpadContractActor,
  daoFactoryActor,
  daoContractActor,
  tokenFactoryActor,
  icrcActor, // Token contracts use ICRC standard
  distributionFactoryActor,
  distributionContractActor,
  multisigFactoryActor,
  multisigContractActor
} from "@/stores/auth"

export type FactoryType = 'launchpad' | 'dao' | 'token' | 'distribution' | 'multisig'

export interface Version {
  major: bigint
  minor: bigint
  patch: bigint
}

export interface VersionInfo {
  current: string
  latest: string
  hasUpdate: boolean
  releaseNotes?: string
  uploadedAt?: number
}

export interface VersionMetadata {
  version: Version
  releaseNotes: string
  uploadedAt: bigint
  uploadedBy: string
  isStable: boolean
  totalSize: bigint
}

class VersionManagementService {
  /**
   * Get the appropriate factory actor based on factory type
   */
  private getFactoryActor(factoryType: FactoryType, options = { requiresSigning: false, anon: true }) {
    switch (factoryType) {
      case 'launchpad':
        return launchpadFactoryActor(options)
      case 'dao':
        return daoFactoryActor(options)
      case 'token':
        return tokenFactoryActor(options)
      case 'distribution':
        return distributionFactoryActor(options)
      case 'multisig':
        return multisigFactoryActor(options)
      default:
        throw new Error(`Unknown factory type: ${factoryType}`)
    }
  }

  /**
   * Get the appropriate contract actor based on factory type
   */
  private getContractActor(
    factoryType: FactoryType,
    canisterId: string,
    requiresSigning: boolean = false
  ) {
    const options = {
      canisterId,
      requiresSigning,
      anon: !requiresSigning
    }

    switch (factoryType) {
      case 'launchpad':
        return launchpadContractActor(options)
      case 'dao':
        return daoContractActor(options)
      case 'token':
        // Token contracts use ICRC standard
        return icrcActor(options)
      case 'distribution':
        return distributionContractActor(options)
      case 'multisig':
        return multisigContractActor(options)
      default:
        throw new Error(`Unknown factory type: ${factoryType}`)
    }
  }

  /**
   * Check version information for a deployed contract
   */
  async checkVersionInfo(
    factoryType: FactoryType,
    canisterId: string
  ): Promise<{
    currentVersion: Version
    factoryPrincipal: string
    creator: string
  }> {
    try {
      const actor = this.getContractActor(factoryType, canisterId, false)
      const info = await actor.checkVersionInfo()

      return {
        currentVersion: info.currentVersion,
        factoryPrincipal: info.factoryPrincipal.toString(),
        creator: info.creator.toString()
      }
    } catch (error) {
      console.error(`❌ Error checking version info for ${factoryType}:`, error)
      throw error
    }
  }

  /**
   * Get the latest stable version from factory
   */
  async getLatestStableVersion(
    factoryType: FactoryType
  ): Promise<Version | null> {
    try {
      const actor = this.getFactoryActor(factoryType, {
        requiresSigning: false,
        anon: true
      })

      const result = await actor.getLatestStableVersion()

      if (result.length > 0 && result[0]) {
        return result[0]
      }

      return null
    } catch (error) {
      console.error(`❌ Error getting latest stable version for ${factoryType}:`, error)
      return null
    }
  }

  /**
   * Get latest stable version with metadata (including release notes)
   */
  async getLatestStableVersionWithMetadata(
    factoryType: FactoryType
  ): Promise<VersionMetadata | null> {
    try {
      const actor = this.getFactoryActor(factoryType, {
        requiresSigning: false,
        anon: true
      })

      const result = await actor.getLatestStableVersionWithMetadata()

      if (result.length > 0 && result[0]) {
        const metadata = result[0]
        return {
          version: metadata.version,
          releaseNotes: metadata.releaseNotes,
          uploadedAt: metadata.uploadedAt,
          uploadedBy: metadata.uploadedBy.toString(),
          isStable: metadata.isStable,
          totalSize: metadata.totalSize
        }
      }

      return null
    } catch (error) {
      console.error(`❌ Error getting latest stable version metadata for ${factoryType}:`, error)
      return null
    }
  }

  /**
   * Get metadata for a specific version
   */
  async getVersionMetadata(
    factoryType: FactoryType,
    version: Version
  ): Promise<VersionMetadata | null> {
    try {
      const actor = this.getFactoryActor(factoryType, {
        requiresSigning: false,
        anon: true
      })

      const result = await actor.getVersionMetadata(version)

      if (result.length > 0 && result[0]) {
        const metadata = result[0]
        return {
          version: metadata.version,
          releaseNotes: metadata.releaseNotes,
          uploadedAt: metadata.uploadedAt,
          uploadedBy: metadata.uploadedBy.toString(),
          isStable: metadata.isStable,
          totalSize: metadata.totalSize
        }
      }

      return null
    } catch (error) {
      console.error(`❌ Error getting version metadata for ${factoryType}:`, error)
      return null
    }
  }

  /**
   * Request self-upgrade for a contract (queue-based)
   */
  async requestSelfUpgrade(
    factoryType: FactoryType,
    canisterId: string
  ): Promise<{ success: boolean; error?: string; requestId?: string }> {
    try {
      const actor = this.getContractActor(factoryType, canisterId, true)
      const result = await actor.requestSelfUpgrade()

      if ('ok' in result) {
        console.log(`✅ ${factoryType} contract upgrade request successful`)
        return {
          success: true,
          requestId: typeof result.ok === 'string' ? result.ok : undefined
        }
      } else {
        const errorMsg = 'err' in result ? result.err : 'Unknown error'
        console.error(`❌ ${factoryType} contract upgrade request failed:`, errorMsg)
        return { success: false, error: errorMsg }
      }
    } catch (error: any) {
      console.error(`❌ Error requesting self-upgrade for ${factoryType}:`, error)
      return {
        success: false,
        error: error.message || 'Failed to request upgrade'
      }
    }
  }

  /**
   * Get upgrade status from factory queue
   */
  async getUpgradeStatus(
    factoryType: FactoryType,
    canisterId: string,
    requestId: string
  ): Promise<{ success: boolean; status?: string; errorMessage?: string; error?: string }> {
    try {
      const actor = this.getFactoryActor(factoryType, {
        requiresSigning: false,
        anon: true
      })

      const result = await actor.getUpgradeRequestStatus(canisterId, requestId)

      if ('ok' in result) {
        const statusResult = result.ok
        if (statusResult) {
          return {
            success: true,
            status: this.mapStatusFromMotoko(statusResult.status),
            errorMessage: statusResult.errorMessage.length > 0 ? statusResult.errorMessage : undefined
          }
        } else {
          return { success: false, error: 'Upgrade request not found' }
        }
      } else {
        const errorMsg = 'err' in result ? result.err : 'Unknown error'
        return { success: false, error: errorMsg }
      }
    } catch (error: any) {
      console.error(`❌ Error getting upgrade status for ${factoryType}:`, error)
      return {
        success: false,
        error: error.message || 'Failed to get upgrade status'
      }
    }
  }

  /**
   * Cancel upgrade request
   */
  async cancelUpgradeRequest(
    factoryType: FactoryType,
    canisterId: string,
    requestId: string
  ): Promise<{ success: boolean; error?: string }> {
    try {
      const actor = this.getFactoryActor(factoryType, {
        requiresSigning: true,
        anon: false
      })

      const result = await actor.cancelUpgradeRequest(canisterId, requestId)

      if ('ok' in result) {
        console.log(`✅ ${factoryType} upgrade request cancelled successfully`)
        return { success: true }
      } else {
        const errorMsg = 'err' in result ? result.err : 'Unknown error'
        console.error(`❌ ${factoryType} upgrade request cancellation failed:`, errorMsg)
        return { success: false, error: errorMsg }
      }
    } catch (error: any) {
      console.error(`❌ Error cancelling upgrade request for ${factoryType}:`, error)
      return {
        success: false,
        error: error.message || 'Failed to cancel upgrade request'
      }
    }
  }

  /**
   * Map Motoko status to TypeScript string
   */
  private mapStatusFromMotoko(status: any): string {
    // Handle Motoko variant types
    if (status && typeof status === 'object') {
      if ('Pending' in status) return 'Pending'
      if ('Pausing' in status) return 'Pausing'
      if ('InProgress' in status) return 'InProgress'
      if ('Completed' in status) return 'Completed'
      if ('Failed' in status) return 'Failed'
    }
    return 'Unknown'
  }

  /**
   * Format version object to string
   */
  formatVersion(version: Version): string {
    return `${version.major}.${version.minor}.${version.patch}`
  }

  /**
   * Compare two versions
   * Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equal
   */
  compareVersions(v1: Version, v2: Version): number {
    // Compare major
    if (v1.major > v2.major) return 1
    if (v1.major < v2.major) return -1

    // Compare minor
    if (v1.minor > v2.minor) return 1
    if (v1.minor < v2.minor) return -1

    // Compare patch
    if (v1.patch > v2.patch) return 1
    if (v1.patch < v2.patch) return -1

    return 0
  }

  /**
   * Get full version information (current + latest + comparison + release notes)
   */
  async getVersionInfo(
    factoryType: FactoryType,
    canisterId: string
  ): Promise<VersionInfo> {
    try {
      const [contractInfo, latestMetadata] = await Promise.all([
        this.checkVersionInfo(factoryType, canisterId),
        this.getLatestStableVersionWithMetadata(factoryType)
      ])

      if (!latestMetadata) {
        return {
          current: this.formatVersion(contractInfo.currentVersion),
          latest: 'N/A',
          hasUpdate: false
        }
      }

      const comparison = this.compareVersions(latestMetadata.version, contractInfo.currentVersion)

      return {
        current: this.formatVersion(contractInfo.currentVersion),
        latest: this.formatVersion(latestMetadata.version),
        hasUpdate: comparison > 0,
        releaseNotes: latestMetadata.releaseNotes,
        uploadedAt: Number(latestMetadata.uploadedAt) / 1_000_000 // Convert nanoseconds to milliseconds
      }
    } catch (error) {
      console.error(`❌ Error getting version info for ${factoryType}:`, error)
      throw error
    }
  }
}

export const versionManagementService = new VersionManagementService()
