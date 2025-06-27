import Result "mo:base/Result";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import ProjectTypes "./ProjectTypes";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

module ProjectService {
    // ==================================================================================================
    // ⬇️ Service to manage Projects
    // ==================================================================================================

    // --- STATE MANAGEMENT ---
    public func initState(owner: Principal) : ProjectTypes.State {
        ProjectTypes.emptyState()
    };

    public func fromStableState(stableState: ProjectTypes.StableState) : ProjectTypes.State {
        let state = ProjectTypes.emptyState();
        for (entry in stableState.projects.vals()) {
            let (k, v) = entry;
            state.projects := Trie.put(state.projects, {key=k; hash=Text.hash(k)}, Text.equal, v).0;
        };
        return state;
    };

    public func toStableState(state: ProjectTypes.State) : ProjectTypes.StableState {
        {
            projects = Iter.toArray(Trie.iter(state.projects));
        }
    };

    // --- QUERIES ---

    public func getProject(
        state: ProjectTypes.State, 
        projectId: ProjectTypes.ProjectId
    ) : ?ProjectTypes.Project {
        return Trie.get(state.projects, {key = projectId; hash = Text.hash(projectId)}, Text.equal);
    };

    // --- MUTATIONS ---
    public func createProject(
        state: ProjectTypes.State,
        id: ProjectTypes.ProjectId,
        name: Text,
        description: Text,
        logo: Text,
        owner: Principal,
        tokenSymbol: Text
    ) : Result.Result<ProjectTypes.Project, Text> {
        if (Trie.get(state.projects, {key=id; hash=Text.hash(id)}, Text.equal) != null) {
            return #err("Project with this ID already exists");
        };

        let newProject : ProjectTypes.Project = {
            id = id;
            name = name;
            description = description;
            logo = logo;
            owner = owner;
            tokenSymbol = tokenSymbol;
            tokenCanister = null;
            launchpadCanister = null;
            lockCanisters = [];
            distributionCanisters = [];
            createdAt = Time.now();
            updatedAt = Time.now();
        };

        state.projects := Trie.put(state.projects, {key=id; hash=Text.hash(id)}, Text.equal, newProject).0;
        return #ok(newProject);
    };

    public func updateProject(
        state: ProjectTypes.State,
        project: ProjectTypes.Project
    ) : Result.Result<ProjectTypes.Project, Text> {
        let key = {key = project.id; hash = Text.hash(project.id)};
        if(Trie.get(state.projects, key, Text.equal) == null) {
            return #err("Project not found");
        };
        let updatedProject = { project with updatedAt = Time.now() };
        state.projects := Trie.put(state.projects, key, Text.equal, updatedProject).0;
        return #ok(updatedProject);
    };

    public func deleteProject(
        state: ProjectTypes.State,
        projectId: ProjectTypes.ProjectId
    ) : Result.Result<(), Text> {
        let key = {key = projectId; hash = Text.hash(projectId)};
        if(Trie.get(state.projects, key, Text.equal) == null) {
            return #err("Project not found");
        };
        state.projects := Trie.remove(state.projects, key, Text.equal).0;
        return #ok(());
    };
}; 