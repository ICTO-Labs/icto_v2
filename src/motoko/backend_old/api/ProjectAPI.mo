// ProjectAPI.mo - Project Management Public API
// Public interface layer for project-related functions

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import ProjectController "../controllers/ProjectController";

module ProjectAPI {
    
    // Public types
    public type ProjectDetail = ProjectController.ProjectDetail;
    public type CreateProjectRequest = ProjectController.CreateProjectRequest;
    // TODO: Implement ProjectAnalytics in ProjectController
    // public type ProjectAnalytics = ProjectController.ProjectAnalytics;
    
    // ================ PROJECT CRUD API ================
    
    public func createProject(
        caller: Principal,
        request: CreateProjectRequest,
        projectController: ProjectController.ProjectControllerState
    ) : Result.Result<Text, Text> {
        ProjectController.createProject(projectController, caller, request)
    };
    
    public func getProject(
        projectId: Text,
        projectController: ProjectController.ProjectControllerState
    ) : ?ProjectDetail {
        ProjectController.getProject(projectController, projectId)
    };
    
    public func getAllProjects(
        projectController: ProjectController.ProjectControllerState
    ) : [(Text, ProjectDetail)] {
        ProjectController.getAllProjects(projectController)
    };
    
    public func getUserProjects(
        caller: Principal,
        projectController: ProjectController.ProjectControllerState
    ) : [Text] {
        ProjectController.getUserProjects(projectController, caller)
    };
    
    // TODO: Fix this function - createProjectRecord has different signature
    /*
    public func createProject(
        caller: Principal,
        request: CreateProjectRequest,
        projectController: ProjectController.ProjectControllerState
    ) : Result.Result<Text, Text> {
        // Note: createProjectRecord returns (Trie, ProjectDetail) not Result
        // Need to implement proper wrapper
        #err("Not implemented - function signature mismatch")
    };
    */
    
    // TODO: The following functions need to be implemented in ProjectController
    // or their signatures need to be updated to match the actual implementations
    
    /*
    // ================ PROJECT ANALYTICS API ================
    
    public func getProjectsByCategory(
        category: Text,
        projectController: ProjectController.ProjectControllerState
    ) : [(Text, ProjectDetail)] {
        ProjectController.getProjectsByCategory(projectController, category)
    };
    
    public func getRecentProjects(
        projectController: ProjectController.ProjectControllerState
    ) : [(Text, ProjectDetail)] {
        ProjectController.getRecentProjects(projectController)
    };
    
    // ================ PROJECT VALIDATION API ================
    
    public func validateProjectOwnership(
        caller: Principal,
        projectId: Text,
        projectController: ProjectController.ProjectControllerState
    ) : Result.Result<(), Text> {
        ProjectController.validateProjectOwnership(projectController, caller, projectId)
    };
    
    public func isProjectOwner(
        caller: Principal,
        projectId: Text,
        projectController: ProjectController.ProjectControllerState
    ) : Bool {
        ProjectController.isProjectOwner(projectController, caller, projectId)
    };
    
    // ================ PROJECT UPDATE API ================
    
    public func updateProjectCanister(
        caller: Principal,
        projectId: Text,
        canisterType: Text,
        canisterId: Principal,
        projectController: ProjectController.ProjectControllerState
    ) : Result.Result<(), Text> {
        ProjectController.updateProjectCanister(projectController, caller, projectId, canisterType, canisterId)
    };
    
    public func recordProjectCanister(
        caller: Principal,
        projectId: Text,
        canisterType: Text,
        canisterId: Principal,
        projectController: ProjectController.ProjectControllerState
    ) : Result.Result<(), Text> {
        ProjectController.recordProjectCanister(projectController, caller, projectId, canisterType, canisterId)
    };
    
    // ================ PROJECT STATUS API ================
    
    public func updateProjectStatus(
        caller: Principal,
        projectId: Text,
        newStatus: Text,
        projectController: ProjectController.ProjectControllerState
    ) : Result.Result<(), Text> {
        ProjectController.updateProjectStatus(projectController, caller, projectId, newStatus)
    };
    
    public func getProjectsByStatus(
        status: Text,
        projectController: ProjectController.ProjectControllerState
    ) : [(Text, ProjectDetail)] {
        ProjectController.getProjectsByStatus(projectController, status)
    };
    */
    
    // ================ PROJECT ANALYTICS API ================
    
    // TODO: Add proper type imports
    /*
    public func getMarketOverview(
        projectController: ProjectController.ProjectControllerState,
        userController: UserController.UserControllerState,
        tokenSymbolRegistry: Trie.Trie<Text, Principal>
    ) : {
        totalProjects: Nat;
        totalTokens: Nat;
        totalUsers: Nat;
        totalDeployments: Nat;
        recentProjects: [(Text, ProjectDetail)];
    } {
        ProjectController.getMarketOverview(projectController, userController, tokenSymbolRegistry)
    };
    */
} 