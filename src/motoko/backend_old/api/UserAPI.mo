// UserAPI.mo - User Management Public API
// Public interface layer for user-related functions

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import UserController "../controllers/UserController";

module UserAPI {
    
    // Public types
    public type UserProfile = UserController.UserProfile;
    public type DeploymentRecord = UserController.DeploymentRecord;
    public type AuditEntry = UserController.AuditEntry;
    
    // ================ USER PROFILE API ================
    
    public func getMyProfile(
        caller: Principal,
        userController: UserController.UserControllerState
    ) : ?UserProfile {
        UserController.getUserProfile(userController, caller)
    };
    
    public func getUserDashboardSummary(
        caller: Principal,
        userController: UserController.UserControllerState
    ) : {
        profile: ?UserProfile;
        projectCount: Nat;
        tokenDeployments: Nat;
        totalFeesPaid: Nat;
        recentActivity: [DeploymentRecord];
        projectList: [Text];
    } {
        UserController.getUserDashboardSummary(userController, caller)
    };
    
    public func getProjectParticipation(
        caller: Principal,
        userController: UserController.UserControllerState
    ) : {
        ownedProjects: [Text];
        totalProjects: Nat;
        tokensDeployed: Nat;
        launchpadsCreated: Nat;
    } {
        UserController.getProjectParticipation(userController, caller)
    };
    
    // ================ USER DEPLOYMENTS API ================
    
    public func getMyDeployments(
        caller: Principal,
        userController: UserController.UserControllerState,
        limit: Nat,
        offset: Nat
    ) : [DeploymentRecord] {
        UserController.getUserDeployments(userController, caller, limit, offset)
    };
    
    public func getTokensByUser(
        caller: Principal,
        userController: UserController.UserControllerState
    ) : [DeploymentRecord] {
        UserController.getTokensByUser(userController, caller)
    };
    
    // ================ USER PROJECTS API ================
    
    public func getUserProjects(
        caller: Principal,
        userController: UserController.UserControllerState
    ) : [Text] {
        UserController.getUserProjects(userController, caller)
    };
    
    // ================ USER AUDIT API ================
    
    public func getMyAuditHistory(
        caller: Principal,
        userController: UserController.UserControllerState,
        limit: Nat,
        offset: Nat
    ) : [AuditEntry] {
        UserController.getUserAuditHistory(userController, caller, limit, offset)
    };
} 