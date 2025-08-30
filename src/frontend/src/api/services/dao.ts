import { useAuthStore, backendActor, daoContractActor } from "@/stores/auth";
import { Principal } from "@dfinity/principal";
import type { 
  DAO,
  DAOConfig,
  CreateDAORequest,
  CreateDAOResponse,
  DAOFilters,
  DAODeploymentSummary,
  CustomSecurityParams,
  ApprovalArgs,
  GovernanceLevel
} from '@/types/dao'
import { 
  getProposalStateKey,
  getVoteKey,
  bigintToNumber,
  bigintToString,
  stringToBigint
} from '@/types/dao'
import type {
  StakeArgs,
  UnstakeArgs,
  DelegateArgs,
  VoteType,
  ProposalStateKey,
  MemberInfo,
  VoteArgs,
  Proposal,
  ProposalInfo,
  ProposalPayload,
  ProposalComment,
  CreateCommentArgs,
  UpdateCommentArgs,
  DAOStats
} from '@/declarations/dao_contract/dao_contract.did'
import { IcrcService } from './icrc'
import { formatTokenAmount } from "@/utils/token";
import { convertGovernanceLevelFromBackend, convertGovernanceLevelToBackend } from "@/utils/dao";

export class DAOService {
  private static instance: DAOService

  constructor() {
    // No need to store actor as instance variable
  }

  static getInstance(): DAOService {
    if (!DAOService.instance) {
      DAOService.instance = new DAOService()
    }
    return DAOService.instance
  }

  private getBackendActor(requiresSigning: boolean = true) {
    return backendActor({ requiresSigning, anon: false })
  }

  private getDAOActor(canisterId: string, requiresSigning: boolean = true) {
    return daoContractActor({ canisterId, requiresSigning, anon: false })
  }


  // ==================================================================================================
  // DAO MANAGEMENT
  // ==================================================================================================

  async createDAO(config: DAOConfig): Promise<CreateDAOResponse> {
    try {
      const actor = this.getBackendActor()
      
      // Convert frontend config to backend format matching DAOTypes.DAOConfig
      const backendConfig = {
        name: config.name,
        description: config.description,
        tokenCanisterId: Principal.fromText(config.tokenCanisterId),
        governanceLevel: convertGovernanceLevelToBackend(config.governanceLevel),
        governanceType: config.governanceType,
        stakingEnabled: config.stakingEnabled,
        minimumStake: BigInt(config.minimumStake),
        proposalThreshold: BigInt(config.proposalThreshold),
        proposalSubmissionDeposit: BigInt(config.proposalSubmissionDeposit),
        quorumPercentage: BigInt(config.quorumPercentage * 100), // Convert to basis points
        approvalThreshold: BigInt(config.approvalThreshold * 100), // Convert to basis points
        timelockDuration: BigInt(config.timelockDuration),
        maxVotingPeriod: BigInt(config.maxVotingPeriod),
        minVotingPeriod: BigInt(config.minVotingPeriod),
        stakeLockPeriods: config.stakeLockPeriods.map(period => BigInt(period)),
        emergencyPauseEnabled: config.emergencyPauseEnabled,
        emergencyContacts: config.emergencyPauseEnabled == true ? config.emergencyContacts.map(contact => Principal.fromText(contact)) : [],
        managedByDAO: config.managedByDAO,
        transferFee: formatTokenAmount(Number(config.transferFee), 8).toNumber(),
        initialSupply: config.initialSupply ? [formatTokenAmount(Number(config.initialSupply), 8).toNumber()] : [],
        enableDelegation: config.enableDelegation,
        votingPowerModel: config.votingPowerModel,
        tags: config.tags,
        isPublic: config.isPublic
      }

      // Convert custom security parameters to backend format
      const customSecurity = config.customSecurity ? [{
        minStakeAmount: config.customSecurity.minStakeAmount ? [BigInt(config.customSecurity.minStakeAmount)] : [],
        maxStakeAmount: config.customSecurity.maxStakeAmount ? [BigInt(config.customSecurity.maxStakeAmount)] : [],
        minProposalDeposit: config.customSecurity.minProposalDeposit ? [BigInt(config.customSecurity.minProposalDeposit)] : [],
        maxProposalDeposit: config.customSecurity.maxProposalDeposit ? [BigInt(config.customSecurity.maxProposalDeposit)] : [],
        maxProposalsPerHour: config.customSecurity.maxProposalsPerHour ? [BigInt(config.customSecurity.maxProposalsPerHour)] : [],
        maxProposalsPerDay: config.customSecurity.maxProposalsPerDay ? [BigInt(config.customSecurity.maxProposalsPerDay)] : []
      }] : []

      console.log('🔍 backendConfig:', backendConfig)
      console.log('🔍 customSecurity:', customSecurity)

      const result = await actor.deployDAO(backendConfig, customSecurity)
      
      if ('ok' in result) {
        return {
          success: true,
          daoCanisterId: result.ok.daoCanisterId.toText()
        }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error creating DAO:', error)
      return {
        success: false,
        error: 'Failed to create DAO'
      }
    }
  }

  async getDAOLevel(canisterId: string): Promise<GovernanceLevel> {
    const daoActor = await this.getDAOActor(canisterId, false)
    const result = await daoActor.getGovernanceLevel()
    return convertGovernanceLevelFromBackend(result)  as GovernanceLevel
  }

  async getDAOs(filters?: DAOFilters): Promise<DAO[]> {
    try {
      const actor = this.getBackendActor(false) // Allow anonymous access for public DAOs
      
      // Get all DAO canisters from the registry using the correct DeploymentType variant
      const daoCanisters = await actor.getCanistersByType({ DAO: null })
      
      // Fetch details for each DAO
      const daoPromises = daoCanisters.map(async (canisterId: Principal) => {
        try {
          const daoActor = await this.getDAOActor(canisterId.toText(), false)
          
          // Use the new single query method to get all DAO info at once
          const [daoInfo, canisterInfo, stats] = await Promise.all([
            daoActor.getDAOsInfo(),
            actor.getDeployedCanisterInfo(canisterId),
            daoActor.getDAOStats()
          ])
          
          const dao: DAO = {
            id: canisterId.toText(),
            canisterId: canisterId.toText(),
            name: canisterInfo?.metadata?.name || daoInfo.tokenConfig.name + ' DAO',
            description: canisterInfo?.metadata?.description || `DAO for ${daoInfo.tokenConfig.symbol} governance`,
            tokenConfig: daoInfo.tokenConfig,
            systemParams: daoInfo.systemParams,
            stats: {
              ...stats,
              totalMembers: Number(daoInfo.totalMembers),
              totalStaked: Number(daoInfo.totalStaked),
              totalVotingPower: Number(daoInfo.totalVotingPower)
            },
            createdAt: canisterInfo?.deployedAt || BigInt(Date.now() * 1000000),
            createdBy: canisterInfo?.deployer?.toText() || '',
            isPublic: canisterInfo?.metadata?.isPublic || true,
            tags: canisterInfo?.metadata?.tags || [],
            governanceType: this.inferGovernanceType(daoInfo.systemParams),
            governanceLevel: daoInfo.governanceLevel,
            stakingEnabled: daoInfo.stakingEnabled,
            votingPowerModel: 'proportional', // Default assumption
            emergencyState: {
              paused: false,//daoInfo.systemParams.emergency_pause,
              pausedBy: [],
              pausedAt: [],
              reason: []
            }
          }
          
          return dao
        } catch (error) {
          console.error(`Error fetching DAO ${canisterId.toText()}:`, error)
          return null
        }
      })
      
      const daos = (await Promise.all(daoPromises)).filter((dao): dao is DAO => dao !== null)
      
      // Apply filters
      return this.applyFilters(daos, filters)
    } catch (error) {
      console.error('Error fetching DAOs:', error)
      throw new Error('Failed to fetch DAOs')
    }
  }

  async getDAO(canisterId: string): Promise<DAO | null> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      const backendActor = this.getBackendActor(false)
      
      // Use the new single query method to get all DAO info at once
      const [daoInfo, canisterInfo, stats] = await Promise.all([
        daoActor.getDAOsInfo(),
        backendActor.getDeployedCanisterInfo(Principal.fromText(canisterId)),
        daoActor.getDAOStats()
      ])
      
      const dao: DAO = {
        id: canisterId,
        canisterId: canisterId,
        name: (canisterInfo && canisterInfo[0]?.metadata?.name) || daoInfo.tokenConfig.name + ' DAO',
        description: (canisterInfo && canisterInfo[0]?.metadata?.description) || `DAO for ${daoInfo.tokenConfig.symbol} governance`,
        tokenConfig: daoInfo.tokenConfig,
        systemParams: daoInfo.systemParams,
        stats: {
          ...stats,
          totalMembers: Number(daoInfo.totalMembers),
          totalStaked: Number(daoInfo.totalStaked),
          totalVotingPower: Number(daoInfo.totalVotingPower)
        },
        createdAt: (canisterInfo && canisterInfo[0]?.deployedAt) || BigInt(Date.now() * 1000000),
        createdBy: (canisterInfo && canisterInfo[0]?.deployer?.toText()) || '',
        isPublic: (canisterInfo && canisterInfo[0]?.metadata?.isPublic) || true,
        tags: (canisterInfo && canisterInfo[0]?.metadata?.tags) || [],
        governanceType: this.inferGovernanceType(daoInfo.systemParams),
        governanceLevel: this.convertGovernanceLevel(daoInfo.governanceLevel),
        stakingEnabled: daoInfo.stakingEnabled,
        votingPowerModel: 'proportional',
        emergencyState: {
          paused: false,//daoInfo.systemParams.emergency_pause,
          pausedBy: [],
          pausedAt: [],
          reason: []
        }
      }
      
      return dao
    } catch (error) {
      console.error('Error fetching DAO:', error)
      return null
    }
  }

  async getDAOStats(canisterId: string): Promise<DAOStats> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      return await daoActor.getDAOStats()
    } catch (error) {
      console.error('Error fetching DAO stats:', error)
      throw new Error('Failed to fetch DAO statistics')
    }
  }

  // ==================================================================================================
  // PROPOSAL MANAGEMENT
  // ==================================================================================================

  async getProposals(canisterId: string, status?: string): Promise<Proposal[]> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      const proposals = await daoActor.listProposals(BigInt(0), BigInt(100)) // Get first 100 proposals
      
      if (status) {
        return proposals.filter(proposal => {
          const stateKey = getProposalStateKey(proposal.state)
          return stateKey === status
        })
      }
      
      return proposals
    } catch (error) {
      console.error('Error fetching proposals:', error)
      throw new Error('Failed to fetch proposals')
    }
  }

  async getProposal(canisterId: string, proposalId: number): Promise<ProposalInfo | null> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      const result = await daoActor.getProposalInfo(BigInt(proposalId))
      
      if (result && result[0]) {
        return result[0]
      }
      return null
    } catch (error) {
      console.error('Error fetching proposal:', error)
      throw new Error('Failed to fetch proposal details')
    }
  }

  async createProposal(canisterId: string, payload: ProposalPayload): Promise<{ success: boolean; proposalId?: number; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      const result = await daoActor.submitProposal(payload)
      
      if ('ok' in result) {
        return {
          success: true,
          proposalId: Number(result.ok)
        }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error creating proposal:', error)
      return {
        success: false,
        error: 'Failed to create proposal'
      }
    }
  }

  async vote(canisterId: string, voteArgs: { proposalId: number; vote: VoteType; reason?: string }): Promise<{ success: boolean; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      
      const candidVoteArgs = {
        proposal_id: BigInt(voteArgs.proposalId),
        vote: { [voteArgs.vote.toLowerCase()]: null },
        reason: voteArgs.reason ? [voteArgs.reason] : []
      }
      const result = await daoActor.vote(candidVoteArgs)
      console.log('result', result)
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error voting:', error)
      return {
        success: false,
        error: 'Failed to cast vote'
      }
    }
  }

  async getUserVote(daoCanisterId: string, proposalId: number, userId: string): Promise<{ success: boolean; data?: any; error?: string }> {
    try {
      const actor = await this.getDAOActor(daoCanisterId, false)
      const userPrincipal = Principal.fromText(userId)
      const result = await actor.getUserVote(BigInt(proposalId), userPrincipal)

      if (result && result.length > 0) {
        const vote = result[0]
        return {
          success: true,
          data: {
            voter: vote.voter.toText(),
            vote: 'yes' in vote.vote ? 'yes' : 'no' in vote.vote ? 'no' : 'abstain',
            votingPower: bigintToString(vote.votingPower),
            timestamp: bigintToString(vote.timestamp),
            reason: vote.reason && vote.reason.length > 0 ? vote.reason[0] : null
          }
        }
      }

      return { success: true, data: null }
    } catch (error) {
      console.error('Error fetching user vote:', error)
      return { success: false, error: 'Failed to fetch user vote' }
    }
  }

  async getProposalVotes(daoCanisterId: string, proposalId: number): Promise<{ success: boolean; data?: any[]; error?: string }> {
    try {
      const actor = await this.getDAOActor(daoCanisterId, false)
      // Use getProposalInfo to get vote information instead of getProposalVotes 
      const result = await actor.getProposalInfo(BigInt(proposalId))

      if (result && result.length > 0) {
        const proposalInfo = result[0]
        // For now, return empty votes array since we need to implement the proper vote fetching
        // This would need to be updated when the backend provides a getProposalVotes method
        return { success: true, data: [] }
      }

      return { success: true, data: [] }
    } catch (error) {
      console.error('Error fetching proposal votes:', error)
      return { success: false, error: 'Failed to fetch proposal votes' }
    }
  }

  // ==================================================================================================
  // COMMENT SYSTEM
  // ==================================================================================================

  async getProposalComments(canisterId: string, proposalId: number): Promise<ProposalComment[]> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      const result = await daoActor.getProposalComments(BigInt(proposalId))
      
      if (result) {
        return result.map((comment: any) => ({
          id: comment.id,
          proposalId: proposalId.toString(),
          author: comment.author.toText(),
          content: comment.content,
          createdAt: comment.createdAt,
          updatedAt: comment.updatedAt?.[0],
          isEdited: comment.isEdited,
          votingPower: comment.votingPower?.[0],
          isStaker: comment.isStaker
        }))
      }
      
      return []
    } catch (error) {
      console.error('Error fetching proposal comments:', error)
      return []
    }
  }

  async createComment(canisterId: string, args: CreateCommentArgs): Promise<{ success: boolean; commentId?: string; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      
      const result = await daoActor.createComment(
        BigInt(args.proposalId),
        args.content
      )
      
      if (result && 'ok' in result) {
        return {
          success: true,
          commentId: result.ok
        }
      } else {
        return {
          success: false,
          error: result?.err || 'Failed to create comment'
        }
      }
    } catch (error) {
      console.error('Error creating comment:', error)
      return {
        success: false,
        error: 'Failed to create comment'
      }
    }
  }

  async updateComment(canisterId: string, args: UpdateCommentArgs): Promise<{ success: boolean; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      
      const result = await daoActor.updateComment(
        args.commentId,
        args.content
      )
      
      if (result && 'ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result?.err || 'Failed to update comment'
        }
      }
    } catch (error) {
      console.error('Error updating comment:', error)
      return {
        success: false,
        error: 'Failed to update comment'
      }
    }
  }

  // ==================================================================================================
  // STAKING & DELEGATION
  // ==================================================================================================

  async stake(canisterId: string, stakeArgs: { amount: string; lockDuration?: number; requiresApproval?: boolean }): Promise<{ success: boolean; error?: string; requiresApproval?: boolean }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      
      // Check if this requires ICRC2 approval first
      if (stakeArgs.requiresApproval) {
        // Get DAO token config to know which token we're approving
        const tokenConfig = await daoActor.getTokenConfig()
        const stakeAmount = Number(stakeArgs.amount)
        
        // Approve DAO to spend tokens on behalf of user
        const approvalResult = await this.approveTokenSpending({
          tokenCanisterId: tokenConfig.canisterId.toText(),
          spenderPrincipal: canisterId, // The DAO canister
          amount: stakeArgs.amount,
          memo: 'DAO Stake Approval'
        })
        
        if (!approvalResult.success) {
          return {
            success: false,
            error: approvalResult.error || 'Failed to approve token spending'
          }
        }
      }
      
      // Proceed with staking
      const result = await daoActor.stake(
        BigInt(stakeArgs.amount), 
        stakeArgs.lockDuration ? [BigInt(stakeArgs.lockDuration)] : []
      )
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error staking:', error)
      return {
        success: false,
        error: 'Failed to stake tokens'
      }
    }
  }

  async unstake(canisterId: string, unstakeArgs: { amount: string }): Promise<{ success: boolean; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      const result = await daoActor.unstake(BigInt(unstakeArgs.amount))
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error unstaking:', error)
      return {
        success: false,
        error: 'Failed to unstake tokens'
      }
    }
  }

  async delegate(canisterId: string, delegateArgs: { to: string }): Promise<{ success: boolean; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      const result = await daoActor.delegate(Principal.fromText(delegateArgs.to))
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error delegating:', error)
      return {
        success: false,
        error: 'Failed to delegate voting power'
      }
    }
  }

  async undelegate(canisterId: string): Promise<{ success: boolean; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, true)
      const result = await daoActor.undelegate()
      
      if ('ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: result.err
        }
      }
    } catch (error) {
      console.error('Error undelegating:', error)
      return {
        success: false,
        error: 'Failed to undelegate voting power'
      }
    }
  }

  async getDelegationInfo(canisterId: string, principal?: string): Promise<{ success: boolean; data?: any; error?: string }> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      const authStore = useAuthStore()
      const targetPrincipal = principal || authStore.principal
      
      if (!targetPrincipal) {
        return { success: false, error: 'No principal available' }
      }
      
      const result = await daoActor.getDelegationInfo(Principal.fromText(targetPrincipal))
      
      if (result && result.length > 0) {
        const delegation = result[0]
        return {
          success: true,
          data: {
            delegate: delegation.delegate.toText(),
            delegator: delegation.delegator.toText(),
            delegatedAt: bigintToString(delegation.delegatedAt),
            effectiveAt: bigintToString(delegation.effectiveAt),
            revokable: delegation.revokable,
            votingPower: bigintToString(delegation.votingPower)
          }
        }
      }
      
      return { success: true, data: null }
    } catch (error) {
      console.error('Error getting delegation info:', error)
      return { success: false, error: 'Failed to get delegation info' }
    }
  }

  // ==================================================================================================
  // MEMBER INFO
  // ==================================================================================================

  async getMemberInfo(canisterId: string, memberPrincipal?: string): Promise<any | null> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      if (!memberPrincipal) {
        // TODO: Get current user principal from auth store
        return null
      }
      
      const result = await daoActor.getMemberInfo(Principal.fromText(memberPrincipal))
      if (result && result[0]) {
        return result[0]
      }
      return null
    } catch (error) {
      console.error('Error fetching member info:', error)
      return null
    }
  }

  // Get my member info
  async getMyMemberInfo(canisterId: string): Promise<any | null> {
    try {
      const daoActor = await this.getDAOActor(canisterId, false)
      const authStore = useAuthStore()
      if(!authStore?.principal) {
        return null
      }
      const result = await daoActor.getMemberInfo(Principal.fromText(authStore?.principal))
      return result ? result[0] : null
    } catch (error) {
      console.error('Error fetching my member info:', error)
      return null
    }
  }

  // ==================================================================================================
  // TOKEN APPROVAL METHODS
  // ==================================================================================================

  async approveTokenSpending(approvalArgs: ApprovalArgs): Promise<{ success: boolean; error?: string }> {
    try {
      const { tokenCanisterId, spenderPrincipal, amount, memo } = approvalArgs
      
      // Get token metadata to determine the token type
      const tokenMetadata = await IcrcService.getIcrc1Metadata(tokenCanisterId)
      if (!tokenMetadata) {
        return {
          success: false,
          error: 'Invalid token canister ID'
        }
      }
      
      // Perform ICRC2 approve
      const result = await IcrcService.icrc2Approve(
        tokenMetadata,
        Principal.fromText(spenderPrincipal),
        BigInt(formatTokenAmount(Number(amount), tokenMetadata.decimals).toNumber()),
        {
          memo: memo ? new TextEncoder().encode(memo) : undefined
        }
      )
      
      if ('Ok' in result) {
        return { success: true }
      } else {
        return {
          success: false,
          error: `Approval failed: ${JSON.stringify(result.Err)}`
        }
      }
    } catch (error) {
      console.error('Error approving token spending:', error)
      return {
        success: false,
        error: 'Failed to approve token spending'
      }
    }
  }

  async checkTokenAllowance(tokenCanisterId: string, owner: string, spender: string): Promise<bigint> {
    try {
      const tokenMetadata = await IcrcService.getIcrc1Metadata(tokenCanisterId)
      if (!tokenMetadata) {
        return BigInt(0)
      }
      
      return await IcrcService.getIcrc2Allowance(
        tokenMetadata,
        Principal.fromText(owner),
        Principal.fromText(spender)
      )
    } catch (error) {
      console.error('Error checking token allowance:', error)
      return BigInt(0)
    }
  }

  // ==================================================================================================
  // UTILITY METHODS
  // ==================================================================================================

  private inferGovernanceType(systemParams: any): 'liquid' | 'locked' | 'hybrid' {
    if (systemParams.stake_lock_periods.length === 0) return 'liquid'
    if (systemParams.stake_lock_periods.length === 1) return 'locked'
    return 'hybrid'
  }

  private convertGovernanceLevel(level: any): 'motion-only' | 'semi-managed' | 'fully-managed' {
    if ('MotionOnly' in level) return 'motion-only'
    if ('SemiManaged' in level) return 'semi-managed'
    if ('FullyManaged' in level) return 'fully-managed'
    return 'motion-only' // default
  }

  private applyFilters(daos: DAO[], filters?: DAOFilters): DAO[] {
    if (!filters) return daos

    let filtered = [...daos]
    
    // Apply search filter
    if (filters.search) {
      const query = filters.search.toLowerCase()
      filtered = filtered.filter(dao => 
        dao.name.toLowerCase().includes(query) ||
        dao.description.toLowerCase().includes(query) ||
        dao.tokenConfig.symbol.toLowerCase().includes(query) ||
        dao.tags.some(tag => tag.toLowerCase().includes(query))
      )
    }
    
    // Apply category filter
    if (filters.filter !== 'all') {
      filtered = filtered.filter(dao => {
        switch (filters.filter) {
          case 'public':
            return dao.isPublic
          case 'mine':
            // TODO: Filter by current user's DAOs
            return true
          case 'staking':
            return dao.stakingEnabled
          case 'governance':
            return Number(dao.stats.totalProposals) > 0
          default:
            return true
        }
      })
    }
    
    // Apply governance type filter
    if (filters.governanceType && filters.governanceType.length > 0) {
      filtered = filtered.filter(dao => filters.governanceType!.includes(dao.governanceType))
    }
    
    // Apply staking filter
    if (filters.stakingEnabled !== undefined) {
      filtered = filtered.filter(dao => dao.stakingEnabled === filters.stakingEnabled)
    }
    
    // Apply tag filter
    if (filters.tags && filters.tags.length > 0) {
      filtered = filtered.filter(dao => 
        filters.tags!.some(tag => dao.tags.includes(tag))
      )
    }
    
    // Apply sorting
    filtered.sort((a, b) => {
      switch (filters.sortBy) {
        case 'created':
          const aTime = Number(a.createdAt)
          const bTime = Number(b.createdAt)
          return filters.sortOrder === 'asc' ? aTime - bTime : bTime - aTime
        case 'name':
          return filters.sortOrder === 'asc' 
            ? a.name.localeCompare(b.name)
            : b.name.localeCompare(a.name)
        case 'members':
          const aMembers = Number(a.stats.totalMembers)
          const bMembers = Number(b.stats.totalMembers)
          return filters.sortOrder === 'asc' ? aMembers - bMembers : bMembers - aMembers
        case 'proposals':
          const aProposals = Number(a.stats.totalProposals)
          const bProposals = Number(b.stats.totalProposals)
          return filters.sortOrder === 'asc' ? aProposals - bProposals : bProposals - aProposals
        case 'tvl':
          const aTVL = Number(a.stats.totalStaked)
          const bTVL = Number(b.stats.totalStaked)
          return filters.sortOrder === 'asc' ? aTVL - bTVL : bTVL - aTVL
        default:
          return 0
      }
    })
    
    return filtered
  }
}