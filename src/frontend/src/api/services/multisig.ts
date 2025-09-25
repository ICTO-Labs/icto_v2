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
import { toast } from 'vue-sonner';

class MultisigService {
  constructor() {
    // No need to store actors as instance variables
  }

  private async getBackendActor() {
    return await backendActor({ anon: false, requiresSigning: true });
  }

  private async getContractActor(canisterId: string) {
    return await multisigContractActor({ canisterId, anon: false });
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
  async createWallet(formData: MultisigFormData): Promise<ApiResponse<{ walletId: string; canisterId: Principal }>> {
    try {
      const actor = await this.getBackendActor();
      const config = this.convertFormDataToConfig(formData);
      
      // Use backend service for deployment (similar to other services)
      const result = await actor.deployMultisig(config, []);

      if ('Ok' in result) {
        console.log('Backend deployment result:', result.Ok);

        // Backend should return canister ID as Principal
        const canisterId = result.Ok as Principal;

        return {
          success: true,
          data: {
            canisterId: canisterId,
            walletId: canisterId.toString()
          }
        };
      } else {
        this.handleError(result);
      }
    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to create wallet'
      };
    }
  }

  async getWallets(): Promise<ApiResponse<any[]>> {
    try {
      const actor = await this.getBackendActor();
      const authStore = useAuthStore();
      
      if (!authStore.principal) {
        throw new Error('Not authenticated');
      }

      // Use backend to get user's deployments (similar to dao.ts)
      const deployments = await actor.getCurrentUserDeployments();
      const multisigDeployments = deployments.filter((d: any) => 'Multisig' in d.deploymentType);
      
      return {
        success: true,
        data: multisigDeployments
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
      const actor = await this.getContractActor(canisterId);
      const backendActorInstance = await backendActor({ anon: true });
      
      // Get wallet info from contract and metadata from backend
      const [walletInfo, canisterInfo] = await Promise.all([
        actor.getWalletInfo(),
        backendActorInstance.getDeployedCanisterInfo(Principal.fromText(canisterId))
      ]);
      
      return {
        success: true,
        data: walletInfo
      };
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
      const actor = await this.getContractActor(canisterId);
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
      const actor = await this.getContractActor(canisterId);

      console.log('Calling getProposals with canisterId:', canisterId);

      const proposals = await actor.getProposals(
        filter ? [filter] : [], // ProposalFilter should be wrapped as optional
        limit ? [BigInt(limit)] : [], 
        offset ? [BigInt(offset)] : []
      );

      console.log('getProposals successful, raw data:', proposals);

      // Process proposals to add computed fields
      const processedProposals = proposals.map((proposal: any) => {
        // Calculate current signatures count
        const currentSignatures = proposal.approvals ?
          Object.keys(proposal.approvals).length :
          (proposal.signatures ? proposal.signatures.length : 0);

        // Get wallet info to determine required signatures (threshold)
        const walletInfoPromise = this.getWalletInfo(canisterId);

        return {
          ...proposal,
          currentSignatures,
          // Will be updated with actual threshold from wallet info
          requiredSignatures: 2, // Default fallback
          // Add computed status
          status: proposal.status || 'pending'
        };
      });

      // Get wallet info to set correct required signatures
      try {
        const walletInfoResponse = await this.getWalletInfo(canisterId);
        if (walletInfoResponse.success && walletInfoResponse.data) {
          const threshold = walletInfoResponse.data.config?.threshold || 2;
          processedProposals.forEach(proposal => {
            proposal.requiredSignatures = threshold;
          });
        }
      } catch (walletInfoError) {
        console.warn('Could not fetch wallet info for threshold:', walletInfoError);
      }

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
      const actor = await this.getContractActor(canisterId);
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