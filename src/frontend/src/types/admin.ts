export interface SystemMetrics {
  totalUsers: number
  totalDeployments: number
  totalPayments: number
  totalRefunds: number
}

export interface ServiceHealth {
  name: string
  canisterId: string
  status: 'Ok' | 'Error'
  cycles?: number
  isHealthy?: boolean
  error?: string
}

export interface PaymentConfig {
  acceptedTokens: string[]
  feeRecipient: string
  serviceFees: Array<{ name: string; fee: number }>
  paymentTimeout: number
  requireConfirmation: boolean
  defaultToken: string
}

export interface ConfigValue {
  key: string
  value: string
  updatedBy?: string
  updatedAt?: number
}

export interface UserProfile {
  principal: string
  registrationDate: number
  deploymentCount: number
  totalSpent: number
  isActive: boolean
  lastActivity?: number
  metadata?: {
    [key: string]: string
  }
}

export interface DeploymentRecord {
  id: string
  canisterId: string
  deploymentType: 'Token' | 'Distribution' | 'Lock' | 'Launchpad' | 'Template'
  owner: string
  createdAt: number
  status: 'Active' | 'Failed' | 'Cancelled'
  cost: number
  metadata?: {
    name?: string
    description?: string
    version?: string
  }
}

export interface AuditEntry {
  id: string
  timestamp: number
  userId: string
  actionType: AuditActionType
  status: 'Pending' | 'Completed' | 'Failed'
  details: string
  metadata?: any
}

export type AuditActionType = 
  | 'CreateToken'
  | 'CreateDistribution'
  | 'CreateTemplate'
  | 'PaymentProcessed'
  | 'PaymentFailed'
  | 'AccessDenied'
  | 'UpdateSystemConfig'
  | 'UserManagement'
  | 'AdminAction'
  | 'CreateProject'
  | 'UpdateProject'
  | 'DeleteProject'
  | 'StartPipeline'
  | 'StepCompleted'
  | 'StepFailed'
  | 'PipelineCompleted'
  | 'PipelineFailed'
  | 'FeeValidation'
  | 'RefundProcessed'
  | 'RefundRequest'
  | 'RefundFailed'
  | 'AdminLogin'
  | 'ServiceMaintenance'
  | 'SystemUpgrade'
  | 'StatusUpdate'
  | 'AccessGranted'
  | 'GrantAccess'
  | 'RevokeAccess'
  | 'AccessRevoked'
  | 'Custom'

export interface RefundRequest {
  id: string
  paymentRecordId: string
  userId: string
  amount: number
  reason: string
  status: 'Pending' | 'Approved' | 'Rejected' | 'Processed'
  requestedAt: number
  processedAt?: number
  processedBy?: string
  notes?: string
}

export interface SystemConfig {
  maintenanceMode: boolean
  lastUpgrade: number
  setupCompleted: boolean
}

export interface AdminDashboardData {
  systemMetrics: SystemMetrics
  servicesHealth: ServiceHealth[]
  recentAuditLogs: AuditEntry[]
  pendingRefunds: RefundRequest[]
  systemConfig: SystemConfig
  paymentConfig: PaymentConfig
}

// Filters and Query Types
export interface AdminFilters {
  dateFrom?: string
  dateTo?: string
  dateRange?: string
  userPrincipal?: string
  actionType?: AuditActionType | ''
  status?: string
  deploymentType?: string
  limit?: number
  offset?: number
}

export interface AdminInfo {
  principal: string
  addedAt?: number
  addedBy?: string
  isActive: boolean
  isSuperAdmin: boolean
}

export interface AdminManagementData {
  admins: AdminInfo[]
  superAdmins: AdminInfo[]
  currentUserRole: 'SuperAdmin' | 'Admin' | 'User'
}

export interface PaymentRecord {
  id: string
  userId: string
  amount: number
  feeAmount?: number
  serviceType: string
  status: 'Pending' | 'Completed' | 'Failed' | 'Refunded'
  timestamp: number
  transactionId?: string
  refunded?: boolean
  notes?: string
}

export interface DeploymentInfo {
  id: string
  name: string
  serviceType: string
  canisterId: string
  status: 'Active' | 'Pending' | 'Failed' | 'Stopped'
  healthStatus: 'Healthy' | 'Warning' | 'Critical' | 'Unknown'
  deployedAt: number
  lastUpdate?: number
  uptime?: number
  cycles?: number
  version?: string
  metadata?: {
    [key: string]: any
  }
}

export interface TableSortConfig {
  field: string
  direction: 'asc' | 'desc'
}

// UI State Types
export interface AdminPageState {
  loading: boolean
  error: string | null
  refreshing: boolean
  filters: AdminFilters
  sortConfig: TableSortConfig
  selectedItems: string[]
  showFilters: boolean
}

// Action Types for Admin Operations
export interface AdminAction {
  id: string
  name: string
  description: string
  type: 'config' | 'user' | 'payment' | 'system' | 'deployment'
  requiresSuperAdmin?: boolean
  confirmationRequired?: boolean
  icon: string
}

// Quick Actions Configuration
export const ADMIN_QUICK_ACTIONS: AdminAction[] = [
  {
    id: 'system-health',
    name: 'System Health Check',
    description: 'Check all microservices health status',
    type: 'system',
    icon: 'Activity',
    confirmationRequired: false
  },
  {
    id: 'maintenance-mode',
    name: 'Toggle Maintenance Mode',
    description: 'Enable/disable system maintenance mode',
    type: 'system',
    icon: 'Settings',
    requiresSuperAdmin: true,
    confirmationRequired: true
  },
  {
    id: 'process-refunds',
    name: 'Process Pending Refunds',
    description: 'Process all approved refund requests',
    type: 'payment',
    icon: 'RefreshCw',
    confirmationRequired: true
  },
  {
    id: 'export-audit-logs',
    name: 'Export Audit Logs',
    description: 'Download audit logs for specified period',
    type: 'system',
    icon: 'Download',
    confirmationRequired: false
  }
]