// ⬇️ ICTO V2 Backend - Centralized Controller Types
// Eliminates type duplication across all controllers and APIs
// Single source of truth for all controller-related types

import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Time "mo:base/Time";
import Result "mo:base/Result";

// Import shared types
import ProjectTypes "../../shared/types/ProjectTypes";
import AuditLogger "../modules/AuditLogger";
import UserRegistry "../modules/UserRegistry";
import SystemManager "../modules/SystemManager";
import PaymentValidator "../modules/PaymentValidator";
import RefundManager "../modules/RefundManager";
import PipelineEngine "../modules/PipelineEngine";
import InvoiceStorage "../interfaces/InvoiceStorage";

module {
    
    // ================ SHARED CONTROLLER TYPES ================
    
    // Common types used across controllers
    public type UserProfile = UserRegistry.UserProfile;
    public type DeploymentRecord = UserRegistry.DeploymentRecord;
    public type AuditEntry = AuditLogger.AuditEntry;
    public type ProjectDetail = ProjectTypes.ProjectDetail;
    public type CreateProjectRequest = ProjectTypes.CreateProjectRequest;
    public type SystemConfiguration = SystemManager.ConfigStorage;
    public type PaymentValidationResult = PaymentValidator.PaymentValidationResult;
    public type RefundRequest = RefundManager.RefundRequest;
    public type PaymentRecord = InvoiceStorage.PaymentRecord;
    
    // ================ USER CONTROLLER TYPES ================
    
    public type UserControllerState = {
        userRegistryStorage: UserRegistry.UserRegistryStorage;
        auditStorage: AuditLogger.AuditStorage;
        userProjectsTrie: Trie.Trie<Principal, [Text]>;
    };
    
    // ================ PROJECT CONTROLLER TYPES ================
    
    public type ProjectControllerState = {
        projectsTrie: Trie.Trie<Text, ProjectDetail>;
        userProjectsTrie: Trie.Trie<Principal, [Text]>;
        auditStorage: AuditLogger.AuditStorage;
        userRegistryStorage: UserRegistry.UserRegistryStorage;
    };
    
    // ================ PAYMENT CONTROLLER TYPES ================
    
    public type PaymentControllerState = {
        paymentValidator: PaymentValidator.PaymentValidatorStorage;
        refundManager: RefundManager.RefundStorage;
        systemStorage: SystemManager.ConfigStorage;
        auditStorage: AuditLogger.AuditStorage;
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage;
    };
    
    // ================ ADMIN CONTROLLER TYPES ================
    
    public type AdminControllerState = {
        systemStorage: SystemManager.ConfigStorage;
        auditStorage: AuditLogger.AuditStorage;
        userRegistryStorage: UserRegistry.UserRegistryStorage;
    };
    
    // ================ TOKEN CONTROLLER TYPES ================
    
    public type TokenInfo = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        description: ?Text;
        logo: ?Text;
        website: ?Text;
        socialLinks: ?[(Text, Text)];
    };
    
    public type TokenRecord = {
        tokenId: Text;
        canisterId: Principal;
        projectId: Text;
        owner: Principal;
        tokenInfo: TokenInfo;
        initialSupply: Nat;
        currentSupply: ?Nat;
        deployedAt: Int;
        status: Text; // "active" | "paused" | "deprecated"
        transactionCount: Nat;
        holderCount: Nat;
        metadata: {
            version: Text;
            deployer: Text;
            cyclesUsed: Nat;
        };
    };
    
    public type TokenDeploymentRequest = {
        projectId: Text;
        tokenInfo: TokenInfo;
        initialSupply: Nat;
        options: ?{
            allowSymbolConflict: Bool;
            enableAdvancedFeatures: Bool;
            customMinter: ?Principal;
            customFeeCollector: ?Principal;
        };
    };
    
    public type TokenDeploymentResult = {
        canisterId: Principal;
        projectId: Text;
        deployedAt: Int;
        cyclesUsed: Nat;
        tokenSymbol: Text;
        initialSupply: Nat;
    };
    
    public type TokenControllerState = {
        userRegistryStorage: UserRegistry.UserRegistryStorage;
        auditStorage: AuditLogger.AuditStorage;
        tokenRecords: [(Text, TokenRecord)]; // tokenId -> TokenRecord
    };
    
    // ================ COMMON RESULT TYPES ================
    
    public type ControllerResult<T> = Result.Result<T, Text>;
    
    // ================ DASHBOARD SUMMARY TYPES ================
    
    public type UserDashboardSummary = {
        profile: ?UserProfile;
        projectCount: Nat;
        tokenDeployments: Nat;
        totalFeesPaid: Nat;
        recentActivity: [DeploymentRecord];
        projectList: [Text];
    };
    
    public type ProjectParticipation = {
        ownedProjects: [Text];
        totalProjects: Nat;
        tokensDeployed: Nat;
        launchpadsCreated: Nat;
    };
    
    public type PlatformStatistics = {
        totalUsers: Nat;
        totalProjects: Nat;
        totalTokens: Nat;
        totalDeployments: Nat;
        deploymentsByType: {
            tokens: Nat;
            launchpads: Nat;
            distributions: Nat;
            locks: Nat;
        };
        isAuthorized: Bool;
    };
} 