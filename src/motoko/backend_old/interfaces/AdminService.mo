// ⬇️ ICTO V2 - Admin Service Interface  
// Comprehensive admin management for system configuration, user management, and monitoring

import Common "../../shared/types/Common";
import Audit "../../shared/types/Audit";
import Storage "../../shared/types/Storage";

module {
    // ===== ADMIN MANAGEMENT TYPES =====
    
    public type AdminRole = {
        #SuperAdmin;
        #Admin;
        #Moderator;
        #Support;
        #ReadOnly;
    };
    
    public type AdminPermission = {
        #ManageUsers;
        #ManageProjects;
        #ManagePayments;
        #ManageRefunds;
        #ViewAuditLogs;
        #ModifySystemConfig;
        #DeployServices;
        #ManageAdmins;
        #EmergencyStop;
        #DataExport;
        #SystemMaintenance;
    };
    
    public type AdminAccount = {
        userId: Common.UserId;
        role: AdminRole;
        permissions: [AdminPermission];
        displayName: Text;
        email: ?Text;
        isActive: Bool;
        lastLoginAt: ?Common.Timestamp;
        createdAt: Common.Timestamp;
        createdBy: Common.UserId;
    };
    
    // ===== SYSTEM CONFIGURATION =====
    
    public type SystemSettings = {
        maintenanceMode: Bool;
        emergencyStop: Bool;
        newUserRegistration: Bool;
        publicProjectCreation: Bool;
        rateLimitEnabled: Bool;
        maxRequestsPerHour: Nat;
        maxProjectsPerUser: Nat;
        dataRetentionDays: Nat;
    };
    
    // ===== USER MANAGEMENT =====
    
    public type UserManagementAction = {
        #Suspend;
        #Unsuspend;
        #Ban;
        #Unban;
        #UpdateRole;
        #AddNote;
        #DataExport;
    };
    
    // ===== MONITORING & ANALYTICS =====
    
    public type SystemMetrics = {
        uptime: Nat;
        totalRequests: Nat;
        errorRate: Float;
        memoryUsage: Float;
        totalUsers: Nat;
        activeUsers: Nat;
        totalProjects: Nat;
        totalDeployments: Nat;
        lastHealthCheck: Common.Timestamp;
    };
    
    public type SystemAlert = {
        id: Text;
        severity: Audit.LogSeverity;
        alertType: Text;
        message: Text;
        createdAt: Common.Timestamp;
        acknowledgedBy: ?Common.UserId;
        serviceAffected: ?Text;
    };
    
    // ===== ADMIN SERVICE INTERFACE =====
    
    public type AdminService = actor {
        // Authentication
        adminLogin : (credentials: Text) -> async Common.SystemResult<AdminSession>;
        adminLogout : (sessionId: Text) -> async Common.SystemResult<()>;
        verifyAdminSession : (sessionId: Text) -> async Bool;
        
        // Admin account management
        createAdminAccount : (account: AdminAccount, password: Text) -> async Common.SystemResult<()>;
        listAdminAccounts : (limit: Nat, offset: Nat) -> async [AdminAccount];
        getAdminAccount : (userId: Common.UserId) -> async ?AdminAccount;
        
        // System configuration
        getSystemSettings : () -> async SystemSettings;
        updateSystemSettings : (settings: SystemSettings, reason: Text) -> async Common.SystemResult<()>;
        toggleMaintenanceMode : (enabled: Bool, message: ?Text) -> async Common.SystemResult<()>;
        emergencyStop : (reason: Text) -> async Common.SystemResult<()>;
        
        // User management
        searchUsers : (search: Text, limit: Nat, offset: Nat) -> async [Storage.UserProfile];
        executeUserAction : (userId: Common.UserId, action: UserManagementAction, reason: Text) -> async Common.SystemResult<()>;
        getUserAuditTrail : (userId: Common.UserId, limit: Nat, offset: Nat) -> async [Audit.AuditEntry];
        
        // Project management
        getAllProjects : (limit: Nat, offset: Nat) -> async [Common.Project];
        forceDeleteProject : (projectId: Common.ProjectId, reason: Text) -> async Common.SystemResult<()>;
        getAllDeployments : (limit: Nat, offset: Nat) -> async [Storage.DeploymentRecord];
        
        // Monitoring
        getSystemMetrics : () -> async SystemMetrics;
        getAuditSummary : () -> async Audit.AuditSummary;
        searchAuditLogs : (queryObj: Audit.AuditQuery) -> async Audit.AuditPage;
        exportAuditLogs : (startDate: Common.Timestamp, endDate: Common.Timestamp) -> async [Audit.AuditEntry];
        
        // Data management
        archiveOldData : (cutoffDate: Common.Timestamp) -> async Common.SystemResult<Nat>;
        exportUserData : (userId: Common.UserId) -> async Common.SystemResult<Text>;
        
        // Service management
        getServiceHealth : (canisterId: Common.CanisterId) -> async Bool;
        restartService : (canisterId: Common.CanisterId, reason: Text) -> async Common.SystemResult<()>;
        
        // Alerts
        acknowledgeAlert : (alertId: Text, notes: ?Text) -> async Common.SystemResult<()>;
        createAlert : (alert: SystemAlert) -> async Common.SystemResult<Text>;
    };
    
    // ===== SUPPORTING TYPES =====
    
    public type AdminSession = {
        sessionId: Text;
        userId: Common.UserId;
        role: AdminRole;
        expiresAt: Common.Timestamp;
        createdAt: Common.Timestamp;
    };
} 