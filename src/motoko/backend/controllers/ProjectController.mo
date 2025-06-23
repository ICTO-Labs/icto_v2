// ProjectController.mo - Project Management Business Logic
// Extracted from main.mo to improve code organization

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Option "mo:base/Option";

// Import shared types
import ProjectTypes "../../shared/types/ProjectTypes";
import AuditLogger "../modules/AuditLogger";
import UserRegistry "../modules/UserRegistry";
import ControllerTypes "../types/ControllerTypes";

module ProjectController {
    
    // Use centralized types
    public type ProjectDetail = ControllerTypes.ProjectDetail;
    public type CreateProjectRequest = ControllerTypes.CreateProjectRequest;
    public type ProjectControllerState = ControllerTypes.ProjectControllerState;
    
    // Initialize controller with required state
    public func init(
        projectsTrie: Trie.Trie<Text, ProjectDetail>,
        userProjectsTrie: Trie.Trie<Principal, [Text]>,
        auditStorage: AuditLogger.AuditStorage,
        userRegistryStorage: UserRegistry.UserRegistryStorage
    ) : ProjectControllerState {
        {
            projectsTrie = projectsTrie;
            userProjectsTrie = userProjectsTrie;
            auditStorage = auditStorage;
            userRegistryStorage = userRegistryStorage;
        }
    };
    
    // Helper functions
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    // ================ PROJECT CRUD OPERATIONS ================
    
    public func createProject(
        state: ProjectControllerState,
        caller: Principal,
        request: CreateProjectRequest
    ) : Result.Result<Text, Text> {
        // Generate unique project ID
        let projectId = "project_" # Int.toText(Time.now()) # "_" # Principal.toText(caller);
        
        // Create project record
        let (updatedTrie, projectDetail) = createProjectRecord(state, projectId, request, caller);
        
        // Update user projects
        let updatedUserTrie = addUserProject(state, caller, projectId);
        
        // Log audit entry
        let auditEntry = AuditLogger.logAction(
            state.auditStorage,
            caller,
            #CreateProject,
            #RawData("Project created: " # projectDetail.projectInfo.name),
            ?projectId,
            ?#Backend
        );
        ignore AuditLogger.updateAuditStatus(state.auditStorage, auditEntry.id, #Completed, null, ?100);
        
        #ok(projectId)
    };
    
    public func getProject(
        state: ProjectControllerState,
        projectId: Text
    ) : ?ProjectDetail {
        Trie.get(state.projectsTrie, _textKey(projectId), Text.equal)
    };
    
    public func getAllProjects(
        state: ProjectControllerState
    ) : [(Text, ProjectDetail)] {
        Trie.toArray<Text, ProjectDetail, (Text, ProjectDetail)>(
            state.projectsTrie, func (k, v) = (k, v)
        )
    };
    
    public func createProjectRecord(
        state: ProjectControllerState,
        projectId: Text,
        request: CreateProjectRequest,
        creator: Principal
    ) : (Trie.Trie<Text, ProjectDetail>, ProjectDetail) {
        let now = Time.now();
        let projectDetail : ProjectDetail = {
            projectInfo = request.projectInfo;
            timeline = {
                createdTime = now;
                startTime = request.timeline.startTime;
                endTime = request.timeline.endTime;
                claimTime = request.timeline.claimTime;
                listingTime = request.timeline.listingTime;
            };
            currentPhase = #Created;
            launchParams = request.launchParams;
            tokenDistribution = request.tokenDistribution;
            financialSettings = request.financialSettings;
            compliance = request.compliance;
            security = request.security;
            creator = creator;
            createdAt = now;
            updatedAt = now;
            deployedCanisters = {
                tokenCanister = null;
                lockCanister = null;
                distributionCanister = null;
                launchpadCanister = null;
                daoCanister = null;
            };
            status = {
                totalRaised = 0;
                totalParticipants = 0;
                tokensDistributed = 0;
                liquidityAdded = false;
                vestingStarted = false;
                isCompleted = false;
                isCancelled = false;
                failureReason = null;
            };
        };
        
        let updatedTrie = Trie.put(state.projectsTrie, _textKey(projectId), Text.equal, projectDetail).0;
        (updatedTrie, projectDetail)
    };
    
    public func updateProject(
        state: ProjectControllerState,
        projectId: Text,
        updatedProject: ProjectDetail
    ) : Trie.Trie<Text, ProjectDetail> {
        let projectWithUpdatedTime = {
            updatedProject with
            updatedAt = Time.now();
        };
        Trie.put(state.projectsTrie, _textKey(projectId), Text.equal, projectWithUpdatedTime).0
    };
    
    public func deleteProject(
        state: ProjectControllerState,
        projectId: Text
    ) : Trie.Trie<Text, ProjectDetail> {
        Trie.remove(state.projectsTrie, _textKey(projectId), Text.equal).0
    };
    
    // ================ USER PROJECT MANAGEMENT ================
    
    public func getUserProjects(
        state: ProjectControllerState,
        user: Principal
    ) : [Text] {
        Option.get(Trie.get(state.userProjectsTrie, _principalKey(user), Principal.equal), [])
    };
    
    public func addUserProject(
        state: ProjectControllerState,
        user: Principal,
        projectId: Text
    ) : Trie.Trie<Principal, [Text]> {
        let existingProjects = Option.get(Trie.get(state.userProjectsTrie, _principalKey(user), Principal.equal), []);
        let updatedUserProjects = Array.append(existingProjects, [projectId]);
        Trie.put(state.userProjectsTrie, _principalKey(user), Principal.equal, updatedUserProjects).0
    };
    
    public func removeUserProject(
        state: ProjectControllerState,
        user: Principal,
        projectId: Text
    ) : Trie.Trie<Principal, [Text]> {
        let existingProjects = Option.get(Trie.get(state.userProjectsTrie, _principalKey(user), Principal.equal), []);
        let filteredProjects = Array.filter<Text>(existingProjects, func(id) { id != projectId });
        Trie.put(state.userProjectsTrie, _principalKey(user), Principal.equal, filteredProjects).0
    };
    
    // ================ PROJECT ANALYTICS ================
    
    public func getProjectAnalytics(
        state: ProjectControllerState,
        projectId: Text
    ) : ?{
        project: ProjectDetail;
        deployedCanisters: {
            token: ?Text;
            launchpad: ?Text; 
            distribution: ?Text;
            dao: ?Text;
        };
        createdAt: Time.Time;
        lastUpdated: Time.Time;
    } {
        switch (Trie.get(state.projectsTrie, _textKey(projectId), Text.equal)) {
            case (?project) {
                ?{
                    project = project;
                    deployedCanisters = {
                        token = project.deployedCanisters.tokenCanister;
                        launchpad = project.deployedCanisters.launchpadCanister;
                        distribution = project.deployedCanisters.distributionCanister;
                        dao = project.deployedCanisters.daoCanister;
                    };
                    createdAt = project.createdAt;
                    lastUpdated = project.updatedAt;
                }
            };
            case null null;
        }
    };
    
    public func getMarketOverview(
        state: ProjectControllerState
    ) : {
        totalProjects: Nat;
        recentProjects: [(Text, ProjectDetail)];
    } {
        let allProjects = Trie.toArray<Text, ProjectDetail, (Text, ProjectDetail)>(
            state.projectsTrie, func (k, v) = (k, v)
        );
        
        // Get most recent 5 projects
        let sortedProjects = Array.sort<(Text, ProjectDetail)>(
            allProjects,
            func(a, b) { Int.compare(b.1.createdAt, a.1.createdAt) }
        );
        let recentProjects = if (sortedProjects.size() > 5) {
            Array.subArray<(Text, ProjectDetail)>(sortedProjects, 0, 5)
        } else {
            sortedProjects
        };
        
        {
            totalProjects = Trie.size(state.projectsTrie);
            recentProjects = recentProjects;
        }
    };
    
    // ================ PROJECT VALIDATION ================
    
    public func validateProjectOwnership(
        state: ProjectControllerState,
        caller: Principal,
        projectId: ?Text
    ) : Result.Result<(), Text> {
        switch (projectId) {
            case (?id) {
                switch (Trie.get(state.projectsTrie, _textKey(id), Text.equal)) {
                    case (?project) {
                        if (project.creator == caller) {
                            #ok()
                        } else {
                            #err("Unauthorized: You do not own this project")
                        }
                    };
                    case null {
                        #err("Project not found: " # id)
                    };
                }
            };
            case null {
                #ok() // No project specified, validation passes
            };
        }
    };
    
    public func validateProjectExists(
        state: ProjectControllerState,
        projectId: Text
    ) : Result.Result<ProjectDetail, Text> {
        switch (Trie.get(state.projectsTrie, _textKey(projectId), Text.equal)) {
            case (?project) #ok(project);
            case null #err("Project not found: " # projectId);
        }
    };
    
    // ================ PROJECT DEPLOYMENT TRACKING ================
    
    public func updateProjectCanister(
        state: ProjectControllerState,
        projectId: Text,
        canisterType: Text,
        canisterId: Text
    ) : Result.Result<Trie.Trie<Text, ProjectDetail>, Text> {
        switch (Trie.get(state.projectsTrie, _textKey(projectId), Text.equal)) {
            case (?project) {
                let updatedCanisters = switch (canisterType) {
                    case ("token") {
                        {
                            project.deployedCanisters with
                            tokenCanister = ?canisterId;
                        }
                    };
                    case ("launchpad") {
                        {
                            project.deployedCanisters with
                            launchpadCanister = ?canisterId;
                        }
                    };
                    case ("distribution") {
                        {
                            project.deployedCanisters with
                            distributionCanister = ?canisterId;
                        }
                    };
                    case ("dao") {
                        {
                            project.deployedCanisters with
                            daoCanister = ?canisterId;
                        }
                    };
                    case ("lock") {
                        {
                            project.deployedCanisters with
                            lockCanister = ?canisterId;
                        }
                    };
                    case (_) project.deployedCanisters;
                };
                
                let updatedProject = {
                    project with
                    deployedCanisters = updatedCanisters;
                    updatedAt = Time.now();
                };
                
                let updatedTrie = Trie.put(state.projectsTrie, _textKey(projectId), Text.equal, updatedProject).0;
                #ok(updatedTrie)
            };
            case null {
                #err("Project not found: " # projectId)
            };
        }
    };
    
    public func updateProjectStatus(
        state: ProjectControllerState,
        projectId: Text,
        statusUpdate: {
            totalRaised: ?Nat;
            totalParticipants: ?Nat;
            tokensDistributed: ?Nat;
            liquidityAdded: ?Bool;
            vestingStarted: ?Bool;
            isCompleted: ?Bool;
            isCancelled: ?Bool;
            failureReason: ?(?Text);
        }
    ) : Result.Result<Trie.Trie<Text, ProjectDetail>, Text> {
        switch (Trie.get(state.projectsTrie, _textKey(projectId), Text.equal)) {
            case (?project) {
                let updatedStatus = {
                    totalRaised = Option.get(statusUpdate.totalRaised, project.status.totalRaised);
                    totalParticipants = Option.get(statusUpdate.totalParticipants, project.status.totalParticipants);
                    tokensDistributed = Option.get(statusUpdate.tokensDistributed, project.status.tokensDistributed);
                    liquidityAdded = Option.get(statusUpdate.liquidityAdded, project.status.liquidityAdded);
                    vestingStarted = Option.get(statusUpdate.vestingStarted, project.status.vestingStarted);
                    isCompleted = Option.get(statusUpdate.isCompleted, project.status.isCompleted);
                    isCancelled = Option.get(statusUpdate.isCancelled, project.status.isCancelled);
                    failureReason = Option.get(statusUpdate.failureReason, project.status.failureReason);
                };
                
                let updatedProject = {
                    project with
                    status = updatedStatus;
                    updatedAt = Time.now();
                };
                
                let updatedTrie = Trie.put(state.projectsTrie, _textKey(projectId), Text.equal, updatedProject).0;
                #ok(updatedTrie)
            };
            case null {
                #err("Project not found: " # projectId)
            };
        }
    };
} 