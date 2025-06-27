// UserController.mo - User Management Business Logic
// Extracted from main.mo to improve code organization

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Option "mo:base/Option";

// Import shared modules
import UserRegistry "../modules/UserRegistry";
import AuditLogger "../modules/AuditLogger";
import Audit "../../shared/types/Audit";
import Common "../../shared/types/Common";
import Storage "../../shared/types/Storage";
import ControllerTypes "../types/ControllerTypes";

module UserController {
    
    // Use centralized types
    public type UserProfile = ControllerTypes.UserProfile;
    public type DeploymentRecord = ControllerTypes.DeploymentRecord;
    public type AuditEntry = ControllerTypes.AuditEntry;
    public type UserControllerState = ControllerTypes.UserControllerState;
    
    // Initialize controller with required state
    public func init(
        userRegistryStorage: UserRegistry.UserRegistryStorage,
        auditStorage: AuditLogger.AuditStorage,
        userProjectsTrie: Trie.Trie<Principal, [Text]>
    ) : UserControllerState {
        {
            userRegistryStorage = userRegistryStorage;
            auditStorage = auditStorage;
            userProjectsTrie = userProjectsTrie;
        }
    };
    
    // Helper function for Principal key
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    // ================ USER PROFILE MANAGEMENT ================
    
    public func getUserProfile(
        state: UserControllerState,
        caller: Principal
    ) : ?UserProfile {
        UserRegistry.getUserProfile(state.userRegistryStorage, caller)
    };
    
    public func registerUser(
        state: UserControllerState,
        caller: Principal
    ) : UserProfile {
        UserRegistry.registerUser(state.userRegistryStorage, caller)
    };
    
    public func updateUserActivity(
        state: UserControllerState,
        caller: Principal,
        feesPaid: Nat
    ) : ?UserProfile {
        UserRegistry.updateUserActivity(state.userRegistryStorage, caller, feesPaid)
    };
    
    // ================ USER DEPLOYMENTS ================
    
    public func getUserDeployments(
        state: UserControllerState,
        caller: Principal,
        limit: Nat,
        offset: Nat
    ) : [DeploymentRecord] {
        UserRegistry.getUserDeployments(state.userRegistryStorage, caller, limit, offset)
    };
    
    public func getTokensByUser(
        state: UserControllerState,
        caller: Principal
    ) : [DeploymentRecord] {
        let allDeployments = UserRegistry.getUserDeployments(state.userRegistryStorage, caller, 100, 0);
        Array.filter<DeploymentRecord>(
            allDeployments,
            func(deployment) { deployment.serviceType == #TokenDeployer }
        )
    };
    
    // TODO: Fix complex type signatures based on main_old.mo reference
    /*
    public func recordDeployment(
        state: UserControllerState,
        caller: Principal,
        projectId: ?Text,
        canisterId: Principal,
        serviceType: Audit.ServiceType,
        deploymentMetadata: Storage.DeploymentMetadata,
        deploymentCost: Storage.DeploymentCosts,
        resourceMetadata: Storage.ResourceMetadata
    ) : UserRegistry.DeploymentRecord {
        UserRegistry.recordDeployment(
            state.userRegistryStorage,
            caller,
            projectId,
            canisterId,
            serviceType,
            deploymentMetadata,
            deploymentCost,
            resourceMetadata
        )
    };
    */
    
    // ================ USER PROJECTS ================
    
    public func getUserProjects(
        state: UserControllerState,
        caller: Principal
    ) : [Text] {
        Option.get(Trie.get(state.userProjectsTrie, _principalKey(caller), Principal.equal), [])
    };
    
    public func addUserProject(
        state: UserControllerState,
        caller: Principal,
        projectId: Text
    ) : Trie.Trie<Principal, [Text]> {
        let existingProjects = Option.get(Trie.get(state.userProjectsTrie, _principalKey(caller), Principal.equal), []);
        let updatedUserProjects = Array.append(existingProjects, [projectId]);
        Trie.put(state.userProjectsTrie, _principalKey(caller), Principal.equal, updatedUserProjects).0
    };
    
    // ================ USER AUDIT HISTORY ================
    
    public func getUserAuditHistory(
        state: UserControllerState,
        caller: Principal,
        limit: Nat,
        offset: Nat
    ) : [AuditEntry] {
        AuditLogger.getUserAuditHistory(state.auditStorage, caller, limit, offset)
    };
    
    // ================ USER DASHBOARD ANALYTICS ================
    
    public func getUserDashboardSummary(
        state: UserControllerState,
        caller: Principal
    ) : {
        profile: ?UserProfile;
        projectCount: Nat;
        tokenDeployments: Nat;
        totalFeesPaid: Nat;
        recentActivity: [DeploymentRecord];
        projectList: [Text];
    } {
        let profile = UserRegistry.getUserProfile(state.userRegistryStorage, caller);
        let userProjectIds = Option.get(Trie.get(state.userProjectsTrie, _principalKey(caller), Principal.equal), []);
        let recentDeployments = UserRegistry.getUserDeployments(state.userRegistryStorage, caller, 5, 0);
        
        // Count token deployments
        let tokenCount = Array.foldLeft<DeploymentRecord, Nat>(
            recentDeployments, 0,
            func(acc, deployment) { 
                if (deployment.serviceType == #TokenDeployer) acc + 1 else acc 
            }
        );
        
        {
            profile = profile;
            projectCount = userProjectIds.size();
            tokenDeployments = tokenCount;
            totalFeesPaid = switch (profile) {
                case (?p) p.totalFeesPaid;
                case null 0;
            };
            recentActivity = recentDeployments;
            projectList = userProjectIds;
        }
    };
    
    public func getProjectParticipation(
        state: UserControllerState,
        caller: Principal
    ) : {
        ownedProjects: [Text];
        totalProjects: Nat;
        tokensDeployed: Nat;
        launchpadsCreated: Nat;
    } {
        let userProjectIds = Option.get(Trie.get(state.userProjectsTrie, _principalKey(caller), Principal.equal), []);
        let allDeployments = UserRegistry.getUserDeployments(state.userRegistryStorage, caller, 100, 0);
        
        var tokenCount = 0;
        var launchpadCount = 0;
        
        for (deployment in allDeployments.vals()) {
            switch (deployment.serviceType) {
                case (#TokenDeployer) tokenCount += 1;
                case (#LaunchpadDeployer) launchpadCount += 1;
                case (_) {};
            };
        };
        
        {
            ownedProjects = userProjectIds;
            totalProjects = userProjectIds.size();
            tokensDeployed = tokenCount;
            launchpadsCreated = launchpadCount;
        }
    };
    
    // ================ USER STATISTICS ================
    
    public func getTotalUsers(state: UserControllerState) : Nat {
        UserRegistry.getTotalUsers(state.userRegistryStorage)
    };
    
    public func getTotalDeployments(state: UserControllerState) : Nat {
        UserRegistry.getTotalDeployments(state.userRegistryStorage)
    };
    
    public func getAllUsers(
        state: UserControllerState,
        limit: Nat,
        offset: Nat
    ) : [UserProfile] {
        UserRegistry.getAllUsers(state.userRegistryStorage, limit, offset)
    };
    
    // ================ COMPREHENSIVE DASHBOARD ================
    
    // TODO: Add proper types for external storage interfaces
    /*
    public func getUserCompleteDashboard(
        state: UserControllerState,
        caller: Principal,
        limit: ?Nat,
        offset: ?Nat,
        externalInvoiceStorage: ?InvoiceStorage.InvoiceStorage,
        refundManager: RefundManager.RefundManagerState
    ) : async {
        profile: ?UserProfile;
        projects: [Text];
        recentDeployments: [DeploymentRecord];
        recentAudits: [AuditEntry];
        paymentRecords: [InvoiceStorage.PaymentRecord];
        refundRecords: [RefundManager.RefundRequest];
        statistics: {
            totalProjects: Nat;
            totalDeployments: Nat;
            totalFeesPaid: Nat;
            successfulDeployments: Nat;
            failedDeployments: Nat;
        };
    } {
        let defaultLimit = Option.get(limit, 10);
        let defaultOffset = Option.get(offset, 0);
        
        // Get user profile
        let profile = UserRegistry.getUserProfile(state.userRegistryStorage, caller);
        
        // Get user projects
        let userProjectIds = Option.get(Trie.get(state.userProjectsTrie, _principalKey(caller), Principal.equal), []);
        
        // Get recent deployments
        let recentDeployments = UserRegistry.getUserDeployments(state.userRegistryStorage, caller, defaultLimit, defaultOffset);
        
        // Get recent audit history
        let recentAudits = AuditLogger.getUserAuditHistory(state.auditStorage, caller, defaultLimit, defaultOffset);
        
        // Get payment records (async call)
        let paymentRecords = switch (externalInvoiceStorage) {
            case (?invoiceStorage) {
                try {
                    let result = await invoiceStorage.getUserPaymentRecords(caller, ?defaultLimit, ?defaultOffset);
                    switch (result) {
                        case (#ok(records)) records;
                        case (#err(_)) [];
                    }
                } catch (e) { [] }
            };
            case null { [] };
        };
        
        // Get refund records
        let refundRecords = RefundManager.getRefundsByUser(refundManager, caller);
        let paginatedRefunds = if (refundRecords.size() > defaultOffset) {
            let endIndex = Nat.min(defaultOffset + defaultLimit, refundRecords.size());
            Array.subArray(refundRecords, defaultOffset, endIndex - defaultOffset)
        } else { [] };
        
        // Calculate statistics
        var successfulDeployments = 0;
        var failedDeployments = 0;
        
        for (deployment in recentDeployments.vals()) {
            // Count successful vs failed deployments based on deployment records
            successfulDeployments += 1; // All recorded deployments are considered successful
        };
        
        {
            profile = profile;
            projects = userProjectIds;
            recentDeployments = recentDeployments;
            recentAudits = recentAudits;
            paymentRecords = paymentRecords;
            refundRecords = paginatedRefunds;
            statistics = {
                totalProjects = userProjectIds.size();
                totalDeployments = recentDeployments.size();
                totalFeesPaid = switch (profile) {
                    case (?p) p.totalFeesPaid;
                    case null 0;
                };
                successfulDeployments = successfulDeployments;
                failedDeployments = failedDeployments;
            };
        }
    };
    */
} 