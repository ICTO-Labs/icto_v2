// Multisig API Service - V2 Architecture
// Using IDL types as single source of truth
import { Principal } from '@dfinity/principal';
import type {
  MultisigFormData,
  ApiResponse
} from '@/types/multisig';
import type {
  MultisigWallet,
  WalletConfig,
  Proposal,
  ProposalResult,
  SignatureResult,
  ProposalFilter,
  EventFilter,
  WalletEvent,
  AssetType,
  ProposalId,
  MultisigContract
} from '@/declarations/multisig_contract/multisig_contract.did';
import { useAuthStore, multisigContractActor, backendActor } from '@/stores/auth';
import type { DeploymentResult__1 } from '@/declarations/backend/backend.did';
import { multisigFactoryService } from './multisigFactory';
import { toast } from 'vue-sonner';

class MultisigService {
  constructor() {
    // No need to store actors as instance variables
  }

  private async getBackendActor() {
    return await backendActor({ anon: false, requiresSigning: true });
  }

  private async getContractActor(canisterId: string) {
    return await multisigContractActor({ canisterId, anon: false, requiresSigning: true });
  }

  // For query-only operations (like visibility checks)
  private async getContractQueryActor(canisterId: string) {
    return await multisigContractActor({ canisterId, anon: false, requiresSigning: false });
  }

  private convertFormDataToConfig(formData: any): any {
    console.log('Converting form data to config:', formData);

    // Validate and safely handle optional text
    const description = formData.description && formData.description.trim()
      ? formData.description.trim()
      : '';

    const config = {
      name: formData.name || 'Unnamed Wallet',
      description: description ? [description] : [], // opt Text: present = [value], absent = []
      threshold: formData.threshold || 2,
      signers: (formData.signers || []).map((s: any) => ({
        principal: Principal.fromText(s.principal),
        name: s.name ? [s.name] : [], // opt text: present = [value], absent = []
        role: s.role === 'Observer' ? { Observer: null } :
              s.role === 'Owner' ? { Owner: null } :
              { Signer: null } // Default to Signer
      })),
      requiresTimelock: Boolean(formData.requiresTimelock),
      timelockDuration: formData.timelockDuration
        ? [BigInt(formData.timelockDuration * 3600 * 1000000000)]
        : [], // opt Int
      dailyLimit: [], // opt Nat - empty for now
      emergencyContactDelay: [], // opt Int - empty for now
      allowRecovery: Boolean(formData.allowRecovery),
      recoveryThreshold: [], // opt Nat - empty for now
      maxProposalLifetime: BigInt((formData.maxProposalLifetime || 24) * 3600 * 1000000000), // Int (not optional)
      requiresConsensusForChanges: Boolean(formData.requiresConsensusForChanges),
      allowObservers: Boolean(formData.allowObservers),
      isPublic: Boolean(formData.isPublic || false) // Default to private
    };

    console.log('Converted config:', config);
    return config;
  }

  private handleError(error: any): never {
    console.error('Multisig service error:', error);

    let message = 'An unexpected error occurred';
    if (typeof error === 'string') {
      message = error;
    } else if (error?.message) {
      message = error.message;
    } else if (error?.Err) {
      if (typeof error.Err === 'string') {
        message = error.Err;
      } else if (error.Err.InvalidConfiguration) {
        message = `Invalid configuration: ${error.Err.InvalidConfiguration}`;
      } else if (error.Err.DeploymentFailed) {
        message = `Deployment failed: ${error.Err.DeploymentFailed}`;
      } else if (error.Err.InsufficientFunds) {
        message = 'Insufficient funds for deployment';
      } else if (error.Err.Unauthorized) {
        message = 'Unauthorized operation';
      } else if (error.Err.RateLimited) {
        message = 'Rate limited. Please try again later';
      }
    }

    toast.error(message);
    throw new Error(message);
  }

  // Factory methods
  async createWallet(formData: MultisigFormData): Promise<ApiResponse<{ canisterId: Principal }>> {
    try {
      const actor = await this.getBackendActor();
      const config = this.convertFormDataToConfig(formData);

      // CORRECT FLOW: Frontend → Backend (payment validation) → Factory → Deploy
      console.log('Calling backend.deployMultisig with config:', config);
      const result = await actor.deployMultisig(config, []);

      console.log('Backend deployment result:', result);

      if ('Ok' in result) {
        // Backend returns DeploymentResult__1: { canisterId: principal; walletId: WalletId }
        const deploymentResult = result.Ok as DeploymentResult__1;

        console.log('Deployment successful, canisterId:', deploymentResult.canisterId.toString());
        // Ignore walletId - we only use canisterId as primary key

        return {
          success: true,
          data: {
            canisterId: deploymentResult.canisterId
          }
        };
      } else {
        console.error('Deployment failed with error:', result);
        this.handleError(result);
      }
    } catch (error) {
      console.error('createWallet error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create wallet'
      };
    }
  }

  async getWallets(): Promise<ApiResponse<any[]>> {
    try {
      const authStore = useAuthStore();

      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      // FACTORY-FIRST: Query multisig_factory directly for user's wallets
      const factoryResponse = await multisigFactoryService.getMyCreatedWallets(
        authStore.principal,
        20, // limit
        0  // offset
      );

      return {
        success: true,
        data: factoryResponse.wallets
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch wallets'
      };
    }
  }

  async getWalletStatistics(): Promise<ApiResponse<any>> {
    try {
      const actor = await this.getBackendActor();
      const authStore = useAuthStore();
      
      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      // Get basic stats from user deployments
      const deployments = await actor.getCurrentUserDeployments();
      const multisigDeployments = deployments.filter((d: any) => 'Multisig' in d.deploymentType);
      
      const stats = {
        totalWallets: multisigDeployments.length,
        activeWallets: multisigDeployments.filter((d: any) => d.status === 'Active').length,
        totalValue: 0,
        totalProposals: 0
      };
      
      return {
        success: true,
        data: stats
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch statistics'
      };
    }
  }

  // Contract methods
  async getWalletInfo(canisterId: string): Promise<ApiResponse<any>> {
    try {
      const authStore = useAuthStore();
      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      // FACTORY-FIRST: Get wallet from factory first
      const factoryWallets = await multisigFactoryService.getMyCreatedWallets(
        authStore.principal,
        100, // Get more to search
        0
      );

      // Find wallet by canisterId
      const wallet = factoryWallets.wallets.find(w => w.canisterId.toString() === canisterId);

      if (!wallet) {
        throw new Error('Wallet not found in factory index');
      }

      // Try to get detailed info from contract, but fallback to factory data
      try {
        const contractActor = await this.getContractQueryActor(canisterId);
        const contractInfo = await contractActor.getWalletInfo();

        return {
          success: true,
          data: {
            ...wallet,
            contractState: contractInfo
          }
        };
      } catch (contractError) {
        console.warn('Contract query failed, using factory data:', contractError);

        // Fallback to factory data only
        return {
          success: true,
          data: wallet
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch wallet info'
      };
    }
  }

  async createTransferProposal(
    canisterId: string,
    recipient: string,
    amount: number,
    asset: any,
    title: string,
    description: string,
    memo?: Uint8Array
  ): Promise<ApiResponse<any>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const _memo = memo ? [memo] : []
      
      // Convert amount to e8s (multiply by 100,000,000 for ICP)
      const amountE8s = Math.floor(amount * 100_000_000);
      const amountBigInt = BigInt(amountE8s);
      
      const result = await actor.createTransferProposal(
        Principal.fromText(recipient),
        amountBigInt,
        asset,
        _memo as [] | [Uint8Array],
        title,
        description
      );

      if ('ok' in result) {
        toast.success('Transfer proposal created successfully');
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create proposal'
      };
    }
  }

  async createWalletModificationProposal(
    canisterId: string,
    modificationType: any,
    title: string,
    description: string
  ): Promise<ApiResponse<any>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const result = await actor.createWalletModificationProposal(
        modificationType,
        title,
        description
      );

      if ('ok' in result) {
        toast.success('Wallet modification proposal created successfully');
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create wallet modification proposal'
      };
    }
  }

  async signProposal(
    canisterId: string,
    proposalId: string,
    signature: Uint8Array,
    note?: string
  ): Promise<ApiResponse<any>> {
    try {
      const authStore = useAuthStore();
      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      const actor = await this.getContractActor(canisterId);
      const _note = note ? [note] : []
      const result = await actor.signProposal(
        proposalId,
        signature,
        _note as [] | [string]
      );

      if ('ok' in result) {
        toast.success('Proposal signed successfully');
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to sign proposal'
      };
    }
  }

  async executeProposal(
    canisterId: string,
    proposalId: string
  ): Promise<ApiResponse<any>> {
    try {
      const authStore = useAuthStore();
      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      const actor = await this.getContractActor(canisterId);
      const result = await actor.executeProposal(
        proposalId
      );

      if ('ok' in result) {
        toast.success('Proposal executed successfully');
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to execute proposal'
      };
    }
  }

  async getProposal(
    canisterId: string,
    proposalId: string
  ): Promise<ApiResponse<any>> {
    try {
      const actor = await this.getContractQueryActor(canisterId);
      const proposal = await actor.getProposal(proposalId);

      if (!proposal) {
        throw new Error('Proposal not found');
      }

      return {
        success: true,
        data: proposal
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch proposal'
      };
    }
  }

  async getProposals(
    canisterId: string,
    filter?: any,
    limit?: number,
    offset?: number
  ): Promise<ApiResponse<any[]>> {
    try {
      const actor = await this.getContractQueryActor(canisterId);

      console.log('Calling getProposals with canisterId:', canisterId);

      // Fetch proposals and wallet info in parallel to get threshold
      const [proposals, walletInfoResponse] = await Promise.all([
        actor.getProposals(
          filter ? [filter] : [], // ProposalFilter should be wrapped as optional
          limit ? [BigInt(limit)] : [],
          offset ? [BigInt(offset)] : []
        ),
        this.getWalletInfo(canisterId)
      ]);

      console.log('getProposals successful, raw data:', proposals);

      // Get threshold from wallet info
      const threshold = walletInfoResponse.success && walletInfoResponse.data?.config?.threshold || 2;

      // Process proposals to add computed fields
      const processedProposals = proposals.map((proposal: any) => {
        // Calculate current signatures count
        const currentSignatures = proposal.approvals ?
          Object.keys(proposal.approvals).length :
          (proposal.signatures ? proposal.signatures.length : 0);

        return {
          ...proposal,
          currentSignatures,
          requiredSignatures: threshold,
          // Add computed status
          status: proposal.status || 'pending'
        };
      });

      console.log('getProposals processed data:', processedProposals);

      return {
        success: true,
        data: processedProposals
      };
    } catch (error) {
      console.error('getProposals error:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch proposals'
      };
    }
  }

  async getWalletEvents(
    canisterId: string,
    filter?: any,
    limit?: number,
    offset?: number
  ): Promise<ApiResponse<any[]>> {
    try {
      const actor = await this.getContractQueryActor(canisterId);
      const events = await actor.getEvents(
        filter ? [filter] : [], // EventFilter should be wrapped as optional
        limit ? [BigInt(limit)] : [], 
        offset ? [BigInt(offset)] : []
      );
      return {
        success: true,
        data: events
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch events'
      };
    }
  }

  async getSecurityInfo(canisterId: string): Promise<ApiResponse<{
    securityFlags: any;
    recentEvents: any[];
    riskScore: number;
  }>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const security = await actor.getSecurityInfo();
      return {
        success: true,
        data: security
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch security info'
      };
    }
  }

  async getWalletBalance(
    canisterId: string,
    assetType: any = { ICP: null }
  ): Promise<ApiResponse<bigint>> {
    try {
      const { IcrcService } = await import('./icrc');
      const walletPrincipal = Principal.fromText(canisterId);
      
      // For ICP balance
      if ('ICP' in assetType) {
        // ICP ledger canister ID
        const icpLedgerCanisterId = 'ryjl3-tyaaa-aaaaa-aaaba-cai';
        const icpToken = await IcrcService.getIcrc1Metadata(icpLedgerCanisterId);
        if (!icpToken) {
          throw new Error('Failed to get ICP token metadata');
        }
        
        const balance = await IcrcService.getIcrc1Balance(icpToken, walletPrincipal);
        return {
          success: true,
          data: typeof balance === 'bigint' ? balance : balance.default
        };
      }
      
      // For other tokens
      if ('Token' in assetType) {
        const tokenMetadata = await IcrcService.getIcrc1Metadata(assetType.Token.toString());
        if (!tokenMetadata) {
          throw new Error('Failed to get token metadata');
        }
        
        const balance = await IcrcService.getIcrc1Balance(tokenMetadata, walletPrincipal);
        return {
          success: true,
          data: typeof balance === 'bigint' ? balance : balance.default
        };
      }
      
      return {
        success: true,
        data: BigInt(0)
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch wallet balance'
      };
    }
  }

  async getWalletBalances(
    canisterId: string,
    assets: any[] = [{ ICP: null }]
  ): Promise<ApiResponse<Map<string, bigint>>> {
    try {
      const balances = new Map<string, bigint>();
      
      for (const asset of assets) {
        const result = await this.getWalletBalance(canisterId, asset);
        if (result.success) {
          const key = this.formatAssetType(asset);
          balances.set(key, result.data!);
        }
      }
      
      return {
        success: true,
        data: balances
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch wallet balances'
      };
    }
  }

  // Utility methods
  async getUserWallets(): Promise<ApiResponse<any[]>> {
    try {
      const authStore = useAuthStore();
      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      // Use getWallets method instead of duplicating logic
      return await this.getWallets();
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch user wallets'
      };
    }
  }

  // Additional proposal methods (createTransferProposal already exists above)

  private formatProposalError(error: any): string {
    if (typeof error === 'object' && error !== null) {
      if ('Unauthorized' in error) return 'You are not authorized to create proposals';
      if ('InvalidProposal' in error) return `Invalid proposal: ${error.InvalidProposal}`;
      if ('InsufficientBalance' in error) return 'Insufficient balance';
      if ('SecurityViolation' in error) return `Security violation: ${error.SecurityViolation}`;
      if ('RateLimited' in error) return 'Rate limited - please wait before creating another proposal';
    }
    return 'Failed to create proposal';
  }

  // Asset management methods
  async addWatchedAsset(
    canisterId: string,
    asset: any
  ): Promise<ApiResponse<void>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const result = await actor.addWatchedAsset(asset);

      if ('ok' in result) {
        return {
          success: true,
          data: undefined
        };
      } else {
        return {
          success: false,
          error: result.err || 'Failed to add watched asset'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to add watched asset'
      };
    }
  }

  async removeWatchedAsset(
    canisterId: string,
    asset: any
  ): Promise<ApiResponse<void>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const result = await actor.removeWatchedAsset(asset);

      if ('ok' in result) {
        return {
          success: true,
          data: undefined
        };
      } else {
        return {
          success: false,
          error: result.err || 'Failed to remove watched asset'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to remove watched asset'
      };
    }
  }

  async getWatchedAssets(canisterId: string): Promise<ApiResponse<any[]>> {
    try {
      console.log('MultisigService: Getting watched assets for canister:', canisterId);
      const actor = await this.getContractActor(canisterId);
      console.log('MultisigService: Got actor:', typeof actor);

      console.log('MultisigService: Calling getWatchedAssets on actor...');
      const assets = await actor.getWatchedAssets();
      console.log('MultisigService: Got watched assets result:', assets);

      return {
        success: true,
        data: assets
      };
    } catch (error) {
      console.error('MultisigService: Error getting watched assets:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch watched assets'
      };
    }
  }

  async getContractBalances(
    canisterId: string,
    assets: any[]
  ): Promise<ApiResponse<[string, bigint][]>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const result = await actor.getWalletBalances(assets);

      if ('ok' in result) {
        return {
          success: true,
          data: result.ok
        };
      } else {
        return {
          success: false,
          error: result.err || 'Failed to fetch contract balances'
        };
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch contract balances'
      };
    }
  }

  // ============== AUDIT MONITORING METHODS ==============

  // Quick wallet visibility check (for UI/UX optimization)
  // This method is optimized to check access rights BEFORE attempting to load wallet data
  async getWalletVisibility(canisterId: string): Promise<ApiResponse<{
    isOwner: boolean;
    isSigner: boolean;
    isObserver: boolean;
    isAuthorized: boolean;
    isPublic: boolean;
    canView: boolean;
  }>> {
    try {
      const authStore = useAuthStore();
      const actor = await this.getContractQueryActor(canisterId);

      // Step 1: Try to get wallet info to check isPublic
      // This call will succeed for public wallets or authorized users
      let isPublic = false;
      let walletInfo = null;
      
      try {
        walletInfo = await actor.getWalletInfo();
        isPublic = walletInfo?.config?.isPublic ?? false;
      } catch (walletError: any) {
        // If getWalletInfo fails with "Access denied", wallet is private and user not authorized
        if (walletError?.message?.includes('Access denied') || 
            walletError?.message?.includes("don't have permission")) {
          // Wallet exists but is private and user not authorized
          return {
            success: true,
            data: { 
              isOwner: false, 
              isSigner: false, 
              isObserver: false, 
              isAuthorized: false,
              isPublic: false,
              canView: false
            }
          };
        }
        // Other errors (wallet not found, network issues, etc.)
        throw walletError;
      }

      // Step 2: If we got wallet info, determine user's role
      if (!authStore.principal) {
        // Not authenticated, but wallet is public (since getWalletInfo succeeded)
        return {
          success: true,
          data: { 
            isOwner: false, 
            isSigner: false, 
            isObserver: false, 
            isAuthorized: false,
            isPublic,
            canView: isPublic
          }
        };
      }

      // Step 3: Check user roles (only if authenticated)
      const [isOwner, isSigner] = await Promise.all([
        actor.isOwner(Principal.fromText(authStore.principal)).catch(() => false),
        actor.isSigner(Principal.fromText(authStore.principal)).catch(() => false)
      ]);

      const isAuthorized = isOwner || isSigner;
      const canView = isPublic || isAuthorized;

      return {
        success: true,
        data: {
          isOwner,
          isSigner,
          isObserver: false,
          isAuthorized,
          isPublic,
          canView
        }
      };
    } catch (error: any) {
      console.error('getWalletVisibility error:', error);
      
      // Check if it's a "wallet not found" error
      if (error?.message?.includes('not found') || error?.message?.includes('does not exist')) {
        return {
          success: false,
          error: 'Wallet not found'
        };
      }
      
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to check wallet visibility'
      };
    }
  }

  // Get comprehensive audit log (only for authorized users)
  async getAuditLog(
    canisterId: string,
    startTime?: number,
    endTime?: number,
    eventTypes?: string[],
    limit?: number
  ): Promise<ApiResponse<{
    events: any[];
    summary: any;
    securityAlerts: any[];
  }>> {
    try {
      const actor = await this.getContractActor(canisterId);

      const result = await actor.getAuditLog(
        startTime ? [BigInt(startTime)] : [],
        endTime ? [BigInt(endTime)] : [],
        eventTypes ? [eventTypes] : [],
        limit ? [BigInt(limit)] : []
      );

      if ('ok' in result) {
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch audit log'
      };
    }
  }

  // Get real-time security status
  async getSecurityStatus(canisterId: string): Promise<ApiResponse<{
    isPaused: boolean;
    isExecuting: boolean;
    activeThreats: number;
    lastSecurityScan: number;
    riskLevel: string;
    recommendations: string[];
  }>> {
    try {
      const actor = await this.getContractActor(canisterId);

      const result = await actor.getSecurityStatus();

      if ('ok' in result) {
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch security status'
      };
    }
  }

  // Get activity report for specific time periods
  async getActivityReport(
    canisterId: string,
    startTime: number,
    endTime: number
  ): Promise<ApiResponse<{
    proposalActivity: any;
    transferActivity: any;
    securityActivity: any;
    userActivity: any[];
  }>> {
    try {
      const actor = await this.getContractActor(canisterId);

      const result = await actor.getActivityReport({
        startTime: BigInt(startTime),
        endTime: BigInt(endTime)
      });

      if ('ok' in result) {
        return {
          success: true,
          data: result.ok
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch activity report'
      };
    }
  }

  // Get security metrics
  async getSecurityMetrics(canisterId: string): Promise<ApiResponse<{
    failedAttempts: number;
    rateLimit: boolean;
    suspiciousActivity: boolean;
    lastSecurityEvent?: number;
    securityScore: number;
  }>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const metrics = await actor.getSecurityMetrics();

      return {
        success: true,
        data: metrics
      };
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to fetch security metrics'
      };
    }
  }

  // Emergency controls (only for owners)
  async emergencyPause(canisterId: string): Promise<ApiResponse<void>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const result = await actor.emergencyPause();

      if ('ok' in result) {
        toast.success('Emergency pause activated');
        return {
          success: true,
          data: undefined
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to activate emergency pause'
      };
    }
  }

  async emergencyUnpause(canisterId: string): Promise<ApiResponse<void>> {
    try {
      const actor = await this.getContractActor(canisterId);
      const result = await actor.emergencyUnpause();

      if ('ok' in result) {
        toast.success('Emergency pause deactivated');
        return {
          success: true,
          data: undefined
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to deactivate emergency pause'
      };
    }
  }

  // Format helpers
  formatAssetType(asset: any): string {
    if ('ICP' in asset) return 'ICP';
    if ('Token' in asset) return `Token (${asset.Token.toString()})`;
    if ('NFT' in asset) return `NFT (${asset.NFT.canister.toString()}#${asset.NFT.tokenId})`;
    return 'Unknown';
  }
}

// Singleton instance
export const multisigService = new MultisigService();

// Export default
export default multisigService;