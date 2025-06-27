// AdminController.mo - Admin Management Business Logic
// Extracted from main.mo to improve code organization

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Utils "../Utils";
import Trie "mo:base/Trie";
// Import shared modules
import SystemManager "../modules/SystemManager";
import AuditLogger "../modules/AuditLogger";
import UserRegistry "../modules/UserRegistry";
import Audit "../../shared/types/Audit";

module AdminController {
    
    // Public types for controller interface
    public type SystemConfiguration = SystemManager.ConfigStorage;
    public type CycleConfiguration = SystemManager.ConfigStorage;
    public type UserProfile = UserRegistry.UserProfile;
    public type AuditEntry = AuditLogger.AuditEntry;
    public type AuditQuery = Audit.AuditQuery;
    public type AuditPage = Audit.AuditPage;
    
    // Controller state type
    public type AdminControllerState = {
        systemStorage: SystemManager.ConfigStorage;
        auditStorage: AuditLogger.AuditStorage;
        userRegistryStorage: UserRegistry.UserRegistryStorage;
    };
    
    // Initialize controller with required state
    public func init(
        systemStorage: SystemManager.ConfigStorage,
        auditStorage: AuditLogger.AuditStorage,
        userRegistryStorage: UserRegistry.UserRegistryStorage
    ) : AdminControllerState {
        {
            systemStorage = systemStorage;
            auditStorage = auditStorage;
            userRegistryStorage = userRegistryStorage;
        }
    };
    
    // Helper function to check if user is admin
    public func isAdmin(
        state: AdminControllerState,
        caller: Principal
    ) : Bool {
        SystemManager._isAdmin(state.systemStorage, caller)
    };
    
    // Helper function to check if user is super admin
    public func isSuperAdmin(
        state: AdminControllerState,
        caller: Principal
    ) : Bool {
        SystemManager._isSuperAdmin(state.systemStorage, caller)
    };
    
    // ================ SYSTEM CONFIGURATION MANAGEMENT ================

        //Get all configs
    public func getAllConfigs(state: AdminControllerState) : Result.Result<[(Text, Text)], Text> {
        #ok(SystemManager.getAllValues(state.systemStorage))
    };


    public func createOrUpdateConfig(
        state: AdminControllerState,
        key: Text,
        value: Text,
        caller: Principal
    ) : Result.Result<(), Text> {
        //log action
        let auditEntry = AuditLogger.logAction(
            state.auditStorage,
            caller,
            #UpdateSystemConfig,
            #RawData("Config " # key # " updated/created to " # value),
            null,
            ?#Backend
        );

        let result = SystemManager.set(state.systemStorage, key, value, caller);
        switch (result) {
            case (#ok()) {
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };

    //Delete config
    public func deleteConfig(
        state: AdminControllerState,
        key: Text,
        caller: Principal
    ) : Result.Result<(), Text> {
        //log action
        let auditEntry = AuditLogger.logAction(
            state.auditStorage,
            caller,
            #AdminAction("DeleteSystemConfig"),
            #RawData("Config " # key # " deleted"),
            null,
            ?#Backend
        );
        let result = SystemManager.delete(state.systemStorage, key, caller);
        switch (result) {
            case (#ok()) {
                ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
                #ok()
            };
            case (#err(msg)) #err(msg);
        }
    };

    
    
    // ================ ADMIN MANAGEMENT ================
    
    public func addAdmin(
        state: AdminControllerState,
        newAdmin: Principal,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.addAdmin(
            state.systemStorage,
            newAdmin,
            caller
        )
    };
    
    public func removeAdmin(
        state: AdminControllerState,
        adminToRemove: Principal,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.removeAdmin(
            state.systemStorage,
            adminToRemove,
            caller
        )
    };
    
    // ================ SYSTEM CONTROL ================
    
    public func enableMaintenanceMode(
        state: AdminControllerState,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.enableMaintenanceMode(state.systemStorage, caller)
    };
    
    public func disableMaintenanceMode(
        state: AdminControllerState,
        caller: Principal
    ) : Result.Result<(), Text> {
        SystemManager.disableMaintenanceMode(state.systemStorage, caller)
    };
    
    public func emergencyStop(
        state: AdminControllerState,
        caller: Principal
    ) : Result.Result<(), Text> {
        if (not isSuperAdmin(state, caller)) {
            return #err("Only super admins can emergency stop");
        };
        SystemManager.emergencyStop(state.systemStorage, caller)
    };
    
    
    // ================ USER MANAGEMENT ================
    
    public func getAllUsers(
        state: AdminControllerState,
        caller: Principal,
        limit: Nat,
        offset: Nat
    ) : [UserProfile] {
        if (not isAdmin(state, caller)) {
            return [];
        };
        UserRegistry.getAllUsers(state.userRegistryStorage, limit, offset)
    };
    
    public func getPlatformStatistics(
        state: AdminControllerState,
        caller: Principal
    ) : {
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
    } {
        let isAuthorized = isAdmin(state, caller);
        
        if (isAuthorized) {
            let allUsers = UserRegistry.getAllUsers(state.userRegistryStorage, 1000, 0);
            var tokenCount = 0;
            var launchpadCount = 0;
            var distributionCount = 0;
            var lockCount = 0;
            
            for (user in allUsers.vals()) {
                let deployments = UserRegistry.getUserDeployments(state.userRegistryStorage, user.userId, 100, 0);
                for (deployment in deployments.vals()) {
                    switch (deployment.serviceType) {
                        case (#TokenDeployer) tokenCount += 1;
                        case (#LaunchpadDeployer) launchpadCount += 1;
                        case (#DistributionDeployer) distributionCount += 1;
                        case (#LockDeployer) lockCount += 1;
                        case (_) {};
                    };
                };
            };
            
            {
                totalUsers = UserRegistry.getTotalUsers(state.userRegistryStorage);
                totalProjects = 0; // Will need to be passed from ProjectController
                totalTokens = 0; // Will need to be passed from TokenController
                totalDeployments = UserRegistry.getTotalDeployments(state.userRegistryStorage);
                deploymentsByType = {
                    tokens = tokenCount;
                    launchpads = launchpadCount;
                    distributions = distributionCount;
                    locks = lockCount;
                };
                isAuthorized = true;
            }
        } else {
            {
                totalUsers = 0;
                totalProjects = 0;
                totalTokens = 0;
                totalDeployments = 0;
                deploymentsByType = {
                    tokens = 0;
                    launchpads = 0;
                    distributions = 0;
                    locks = 0;
                };
                isAuthorized = false;
            }
        }
    };
    
    // ================ AUDIT MANAGEMENT ================
    
    public func queryAudit(
        state: AdminControllerState,
        caller: Principal,
        queryObj: AuditQuery
    ) : AuditPage {
        if (not isAdmin(state, caller)) {
            return { entries = []; hasNext = false; totalCount = 0; page = 0; pageSize = 0; summary = null };
        };
        AuditLogger.queryAuditEntries(state.auditStorage, queryObj)
    };
    
    // ================ SERVICE ENDPOINT MANAGEMENT ================
    
    // Enable a service endpoint by domain as serviceType and key is_enabled
    public func enableServiceEndpoint(
        state: AdminControllerState,
        serviceType: Text,
        canisterId: Principal,
        version: ?Text,
        caller: Principal
    ) : Result.Result<(), Text> {
        ignore SystemManager.set(state.systemStorage, serviceType # ".is_enabled", "true", caller);
        ignore SystemManager.set(state.systemStorage, serviceType # ".canister_id", Principal.toText(canisterId), caller);
        switch (version) {
            case (?version) {
                ignore SystemManager.set(state.systemStorage, serviceType # ".version", version, caller);
            };
            case null {};
        };
        #ok()
    };

    // Disable a service endpoint by domain as serviceType and key is_enabled
    public func disableServiceEndpoint(
        state: AdminControllerState,
        serviceType: Text,
        caller: Principal
    ) : Result.Result<(), Text> {
        ignore SystemManager.set(state.systemStorage, serviceType # ".is_enabled", "false", caller);
        #ok()
    };
    
} 