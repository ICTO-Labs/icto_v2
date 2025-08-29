
import { backendActor } from "@/stores/auth";
import { Principal } from "@dfinity/principal";
import type { 
  AuditEntry,
  ActionType,
  ActionStatus,
  PaymentRecord,
  UserProfile,
  ServiceHealth,
  RefundRequest,
  DeploymentRecord
} from '@/types/backend'
import type { 
  SystemMetrics,
  PaymentConfig,
  SystemConfig,
  AdminDashboardData,
  AdminFilters,
  DeploymentInfo
} from '@/types/admin'

export class AdminService {
  private static instance: AdminService

  constructor() {
    // No need to store actor as instance variable
  }

  static getInstance(): AdminService {
    if (!AdminService.instance) {
      AdminService.instance = new AdminService()
    }
    return AdminService.instance
  }

  private getActor(requiresSigning: boolean = true) {
    return backendActor({ requiresSigning, anon: false })
  }

  // ==================================================================================================
  // SYSTEM OVERVIEW & HEALTH
  // ==================================================================================================

  async getSystemMetrics(): Promise<SystemMetrics> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetSystemMetrics()
      return {
        totalUsers: Number(result.totalUsers),
        totalDeployments: Number(result.totalDeployments),
        totalPayments: Number(result.totalPayments),
        totalRefunds: Number(result.totalRefunds)
      }
    } catch (error) {
      console.error('Error fetching system metrics:', error)
      throw new Error('Failed to fetch system metrics')
    }
  }

  async getServicesHealth(): Promise<ServiceHealth[]> {
    try {
      const actor = this.getActor()
      const result = await actor.getMicroserviceHealth()
      return result.map((service: any) => ({
        name: service.name,
        canisterId: service.canisterId.toText(),
        status: service.status.Ok !== undefined ? 'Ok' : 'Error',
        cycles: service.cycles ? Number(service.cycles[0]) : undefined,
        isHealthy: service.isHealthy ? service.isHealthy[0] : undefined,
        error: service.status.Error || undefined
      }))
    } catch (error) {
      console.error('Error fetching services health:', error)
      throw new Error('Failed to fetch services health')
    }
  }

  async getSystemStatus(): Promise<SystemConfig> {
    try {
      const actor = this.getActor()
      const result = await actor.getSystemStatus()
      return {
        maintenanceMode: result.isMaintenanceMode,
        lastUpgrade: Number(result.lastUpgrade),
        setupCompleted: await actor.getMicroserviceSetupStatus()
      }
    } catch (error) {
      console.error('Error fetching system status:', error)
      throw new Error('Failed to fetch system status')
    }
  }

  async getDashboardData(): Promise<AdminDashboardData> {
    try {
      const [systemMetrics, servicesHealth, systemConfig, paymentConfig, recentAuditLogs, pendingRefunds] = await Promise.all([
        this.getSystemMetrics(),
        this.getServicesHealth(),
        this.getSystemStatus(),
        this.getPaymentConfig(),
        this.getAuditLogs({ limit: 10 }),
        this.getRefundRequests({ status: 'Pending', limit: 5 })
      ])

      return {
        systemMetrics,
        servicesHealth,
        systemConfig,
        paymentConfig,
        recentAuditLogs,
        pendingRefunds
      }
    } catch (error) {
      console.error('Error fetching dashboard data:', error)
      throw new Error('Failed to fetch dashboard data')
    }
  }

  // ==================================================================================================
  // CONFIGURATION MANAGEMENT
  // ==================================================================================================

  async getPaymentConfig(): Promise<PaymentConfig> {
    try {
      const actor = this.getActor()
      const result = await actor.getPaymentConfig()
      return {
        acceptedTokens: result.acceptedTokens.map((token: any) => token.toText()),
        feeRecipient: result.feeRecipient.toText(),
        serviceFees: result.serviceFees.map(([name, fee]: [string, any]) => ({
          name,
          fee: Number(fee)
        })),
        paymentTimeout: Number(result.paymentTimeout),
        requireConfirmation: result.requireConfirmation,
        defaultToken: result.defaultToken.toText()
      }
    } catch (error) {
      console.error('Error fetching payment config:', error)
      throw new Error('Failed to fetch payment configuration')
    }
  }

  async setConfigValue(key: string, value: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminSetConfigValue(key, value)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error setting config value:', error)
      throw error
    }
  }

  async deleteConfigValue(key: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminDeleteConfigValue(key)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error deleting config value:', error)
      throw error
    }
  }

  // ==================================================================================================
  // USER MANAGEMENT
  // ==================================================================================================

  async getUsers(offset: number = 0, limit: number = 50): Promise<UserProfile[]> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetUsers(BigInt(offset), BigInt(limit))
      return result.map((profile: any) => ({
        principal: profile.principal.toText(),
        registrationDate: Number(profile.registrationDate),
        deploymentCount: Number(profile.deploymentCount || 0),
        totalSpent: Number(profile.totalSpent || 0),
        isActive: profile.isActive,
        lastActivity: profile.lastActivity ? Number(profile.lastActivity[0]) : undefined,
        metadata: profile.metadata || {}
      } as unknown as UserProfile))
    } catch (error) {
      console.error('Error fetching users:', error)
      throw new Error('Failed to fetch users')
    }
  }

  async getUserProfile(userId: string): Promise<UserProfile | null> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetUserProfile(Principal.fromText(userId))
      if (!result || !result[0]) return null

      const profile = result[0] as any
      return {
        principal: profile.principal.toText(),
        registrationDate: Number(profile.registrationDate),
        deploymentCount: Number(profile.deploymentCount || 0),
        totalSpent: Number(profile.totalSpent || 0),
        isActive: profile.isActive,
        lastActivity: profile.lastActivity ? Number(profile.lastActivity[0]) : undefined,
        metadata: profile.metadata || {}
      } as unknown as UserProfile
    } catch (error) {
      console.error('Error fetching user profile:', error)
      throw new Error('Failed to fetch user profile')
    }
  }

  async getUserDeployments(userId: string): Promise<DeploymentRecord[]> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetUserDeployments(Principal.fromText(userId))
      return result.map((deployment: any) => ({
        id: deployment.id,
        canisterId: deployment.canisterId.toText(),
        deploymentType: deployment.deploymentType,
        owner: deployment.owner.toText(),
        createdAt: Number(deployment.createdAt),
        status: deployment.status,
        cost: Number(deployment.cost || 0),
        metadata: deployment.metadata || {}
      }))
    } catch (error) {
      console.error('Error fetching user deployments:', error)
      throw new Error('Failed to fetch user deployments')
    }
  }

  // ==================================================================================================
  // AUDIT & MONITORING
  // ==================================================================================================

  async getAuditLogs(filters: AdminFilters = {}): Promise<AuditEntry[]> {
    try {
      const actor = this.getActor()
      
      // Convert actionType string to proper variant format for backend
      let actionTypeVariant: any[] = []
      if (filters.actionType) {
        switch (filters.actionType) {
          case 'CreateToken':
            actionTypeVariant = [{ CreateToken: null }]
            break
          case 'CreateDistribution':
            actionTypeVariant = [{ CreateDistribution: null }]
            break
          case 'CreateTemplate':
            actionTypeVariant = [{ CreateTemplate: null }]
            break
          case 'PaymentProcessed':
            actionTypeVariant = [{ PaymentProcessed: null }]
            break
          case 'PaymentFailed':
            actionTypeVariant = [{ PaymentFailed: null }]
            break
          case 'AccessDenied':
            actionTypeVariant = [{ AccessDenied: null }]
            break
          case 'UpdateSystemConfig':
            actionTypeVariant = [{ UpdateSystemConfig: null }]
            break
          case 'UserManagement':
            actionTypeVariant = [{ UserManagement: null }]
            break
          case 'AdminAction':
            actionTypeVariant = [{ AdminAction: 'System' }]
            break
          default:
            actionTypeVariant = []
        }
      }
      
      const result = await actor.adminGetAuditLogs(
        filters.userPrincipal ? [Principal.fromText(filters.userPrincipal)] : [],
        actionTypeVariant,
        filters.dateFrom ? [BigInt(new Date(filters.dateFrom).getTime() * 1000000)] : [],
        filters.dateTo ? [BigInt(new Date(filters.dateTo).getTime() * 1000000)] : [],
        filters.limit ? [BigInt(filters.limit)] : []
      )
      
      // Map backend audit entries to the proper AuditEntry structure
      return result.map((entry: any) => {
        // The backend returns complete AuditEntry objects, we just need to ensure correct typing
        return entry as AuditEntry
      })
      
    } catch (error) {
      console.error('Error fetching audit logs:', error)
      throw new Error('Failed to fetch audit logs')
    }
  }

  // ==================================================================================================
  // PAYMENT & REFUNDS MANAGEMENT
  // ==================================================================================================

  async getRefundRequests(filters: AdminFilters = {}): Promise<RefundRequest[]> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetRefundRequests(
        filters.userPrincipal ? [Principal.fromText(filters.userPrincipal)] : []
      )
      
      return result.map((refund: any) => ({
        id: refund.id,
        paymentRecordId: refund.paymentRecordId,
        userId: refund.userId.toText(),
        amount: Number(refund.amount),
        reason: refund.reason,
        status: refund.status,
        requestedAt: Number(refund.requestedAt),
        processedAt: refund.processedAt ? Number(refund.processedAt[0]) : undefined,
        processedBy: refund.processedBy ? refund.processedBy[0].toText() : undefined,
        notes: refund.notes || undefined
      })).filter((refund: RefundRequest) => {
        // Apply client-side filters
        if (filters.status && refund.status !== filters.status) return false
        if (filters.limit && result.length > filters.limit) return false
        return true
      }).slice(0, filters.limit || undefined)
    } catch (error) {
      console.error('Error fetching refund requests:', error)
      throw new Error('Failed to fetch refund requests')
    }
  }

  async approveRefund(refundId: string, notes?: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminApproveRefund(refundId, notes ? [notes] : [])
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error approving refund:', error)
      throw error
    }
  }

  async rejectRefund(refundId: string, reason: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminRejectRefund(refundId, reason)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error rejecting refund:', error)
      throw error
    }
  }

  async processRefund(refundId: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminProcessRefund(refundId)
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error processing refund:', error)
      throw error
    }
  }

  // ==================================================================================================
  // SYSTEM ACTIONS
  // ==================================================================================================

  async forceResetMicroserviceSetup(): Promise<void> {
    try {
      const actor = this.getActor()
      await actor.forceResetMicroserviceSetup()
    } catch (error) {
      console.error('Error resetting microservice setup:', error)
      throw new Error('Failed to reset microservice setup')
    }
  }


  async healthCheck(): Promise<ServiceHealth[]> {
    return this.getServicesHealth()
  }

  // ==================================================================================================
  // ADMIN MANAGEMENT
  // ==================================================================================================

  async addAdmin(adminPrincipal: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminAddAdmin(Principal.fromText(adminPrincipal))
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error adding admin:', error)
      throw error
    }
  }

  async removeAdmin(adminPrincipal: string): Promise<void> {
    try {
      const actor = this.getActor()
      const result = await actor.adminRemoveAdmin(Principal.fromText(adminPrincipal))
      if ('err' in result) {
        throw new Error(result.err)
      }
    } catch (error) {
      console.error('Error removing admin:', error)
      throw error
    }
  }

  async getAdmins(): Promise<string[]> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetAdmins()
      return result.map((p: any) => p.toText())
    } catch (error) {
      console.error('Error fetching admins:', error)
      throw new Error('Failed to fetch admins')
    }
  }

  async getSuperAdmins(): Promise<string[]> {
    try {
      const actor = this.getActor()
      const result = await actor.adminGetSuperAdmins()
      return result.map((p: any) => p.toText())
    } catch (error) {
      console.error('Error fetching super admins:', error)
      throw new Error('Failed to fetch super admins')
    }
  }

  // ==================================================================================================
  // DEPLOYMENT MANAGEMENT
  // ==================================================================================================

  async getDeploymentsByType(deploymentType: string): Promise<string[]> {
    try {
      const actor = this.getActor()
      // Create proper deployment type object based on the type string
      let deploymentTypeObj: any
      switch (deploymentType) {
        case 'Token':
          deploymentTypeObj = { Token: null }
          break
        case 'Distribution':
          deploymentTypeObj = { Distribution: null }
          break
        case 'Lock':
          deploymentTypeObj = { Lock: null }
          break
        case 'Launchpad':
          deploymentTypeObj = { Launchpad: null }
          break
        case 'DAO':
          deploymentTypeObj = { DAO: null }
          break
        default:
          deploymentTypeObj = { Token: null }
      }
      const result = await actor.getCanistersByType(deploymentTypeObj)
      return result.map((canisterId: any) => canisterId.toText())
    } catch (error) {
      console.error('Error fetching deployments by type:', error)
      throw new Error('Failed to fetch deployments by type')
    }
  }

  async getDeployedCanisterInfo(canisterId: string): Promise<any> {
    try {
      const actor = this.getActor()
      const result = await actor.getDeployedCanisterInfo(Principal.fromText(canisterId))
      return result[0] || null
    } catch (error) {
      console.error('Error fetching canister info:', error)
      throw new Error('Failed to fetch canister information')
    }
  }

  // ==================================================================================================
  // PAYMENT MANAGEMENT
  // ==================================================================================================

  async getPaymentHistory(filters: Partial<AdminFilters>): Promise<PaymentRecord[]> {
    try {
      const actor = this.getActor()
      // Mock data for now - in production this would call a real backend method
      const mockPayments: PaymentRecord[] = [
        {
          id: 'pay_001',
          userId: 'rdmx6-jaaaa-aaaaa-aaadq-cai',
          amount: 100000000, // 1 ICP in e8s
          feeAmount: 10000000, // 0.1 ICP in e8s
          serviceType: 'TokenFactory',
          status: 'Completed',
          timestamp: Date.now() - 86400000,
          transactionId: 'tx_001'
        },
        {
          id: 'pay_002',
          userId: 'rdmx6-jaaaa-aaaaa-aaadq-cai',
          amount: 50000000, // 0.5 ICP in e8s
          serviceType: 'DistributionFactory',
          status: 'Pending',
          timestamp: Date.now() - 3600000,
        },
        {
          id: 'pay_003',
          userId: 'be2us-64aaa-aaaaa-qaabq-cai',
          amount: 200000000, // 2 ICP in e8s
          feeAmount: 20000000, // 0.2 ICP in e8s
          serviceType: 'LaunchpadFactory',
          status: 'Failed',
          timestamp: Date.now() - 7200000,
        }
      ]
      
      // Apply filters if provided
      let filtered = mockPayments
      if (filters.status) {
        filtered = filtered.filter(p => p.status === filters.status)
      }
      if (filters.userPrincipal) {
        filtered = filtered.filter(p => p.userId.includes(filters.userPrincipal!))
      }
      
      return filtered
    } catch (error) {
      console.error('Error fetching payment history:', error)
      throw new Error('Failed to fetch payment history')
    }
  }

  // ==================================================================================================
  // DEPLOYMENT INFORMATION
  // ==================================================================================================

  async getDeploymentInfo(filters: Partial<AdminFilters>): Promise<DeploymentInfo[]> {
    try {
      const actor = this.getActor()
      // Get service health data which contains deployment info
      const healthData = await this.healthCheck()
      
      // Transform health data to deployment info format
      const deployments: DeploymentInfo[] = healthData.map((service, index) => ({
        id: `deploy_${index}`,
        name: service.name,
        serviceType: service.name,
        canisterId: service.canisterId,
        status: service.status === 'Ok' ? 'Active' : 'Failed',
        healthStatus: service.isHealthy ? 'Healthy' : 'Critical',
        deployedAt: Date.now() - Math.random() * 86400000 * 30, // Random deployment time in last 30 days
        lastUpdate: Date.now() - Math.random() * 3600000, // Random update time in last hour
        uptime: Math.random() * 86400000 * 30, // Random uptime
        cycles: service.cycles || Math.floor(Math.random() * 1000000000000), // Random cycles if not provided
        version: '1.0.0'
      }))
      
      // Apply filters if provided
      let filtered = deployments
      if (filters.status) {
        filtered = filtered.filter(d => d.status === filters.status)
      }
      if (filters.deploymentType) {
        filtered = filtered.filter(d => d.serviceType === filters.deploymentType)
      }
      
      return filtered
    } catch (error) {
      console.error('Error fetching deployment info:', error)
      throw new Error('Failed to fetch deployment information')
    }
  }
}