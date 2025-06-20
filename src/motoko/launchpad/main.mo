// ⬇️ Enhanced from V1: icto_app/canisters/launchpad/main.mo
// ICTO V2 Launchpad Deployer with comprehensive project management
// Enforces immutable constraints after LIVE phase for transparency

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";

import ProjectTypes "../shared/types/ProjectTypes";
import LaunchpadTemplate "./templates/LaunchpadTemplate";

actor LaunchpadDeployer {
    
    // ================ STABLE VARIABLES ================
    private stable var projectsStable : [(Text, ProjectTypes.ProjectDetail)] = [];
    private stable var userProjectsStable : [(Principal, [Text])] = [];
    private stable var CYCLES_FOR_INSTALL : Nat = 300_000_000_000;
    private stable var MIN_CYCLES_IN_DEPLOYER : Nat = 2_000_000_000_000;
    
    // Runtime variables
    private var projects : Trie.Trie<Text, ProjectTypes.ProjectDetail> = Trie.empty();
    private var userProjects : Trie.Trie<Principal, [Text]> = Trie.empty();
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("LaunchpadDeployer: Starting preupgrade");
        projectsStable := Trie.toArray<Text, ProjectTypes.ProjectDetail, (Text, ProjectTypes.ProjectDetail)>(
            projects, func (k, v) = (k, v)
        );
        userProjectsStable := Trie.toArray<Principal, [Text], (Principal, [Text])>(
            userProjects, func (k, v) = (k, v)
        );
        Debug.print("LaunchpadDeployer: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("LaunchpadDeployer: Starting postupgrade");
        
        // Restore projects
        for ((projectId, project) in projectsStable.vals()) {
            projects := Trie.put(projects, _textKey(projectId), Text.equal, project).0;
        };
        
        // Restore user projects
        for ((userId, projectIds) in userProjectsStable.vals()) {
            userProjects := Trie.put(userProjects, _principalKey(userId), Principal.equal, projectIds).0;
        };
        
        // Clear stable variables
        projectsStable := [];
        userProjectsStable := [];
        
        Debug.print("LaunchpadDeployer: Postupgrade completed");
    };
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _generateProjectId() : Text {
        "project_" # Int.toText(Time.now())
    };
    
    private func _isProjectOwner(projectId: Text, caller: Principal) : Bool {
        switch (Trie.get(projects, _textKey(projectId), Text.equal)) {
            case (?project) { Principal.equal(project.creator, caller) };
            case null { false };
        };
    };
    
    private func _getCurrentPhase(timeline: ProjectTypes.Timeline) : ProjectTypes.LaunchpadPhase {
        let now = Time.now();
        if (now < timeline.startTime) {
            #Upcoming
        } else if (now < timeline.endTime) {
            #Live
        } else if (now < timeline.claimTime) {
            #Ended
        } else if (now < timeline.listingTime) {
            #Claim
        } else {
            #Listed
        };
    };
    
    private func _canUpdateProject(project: ProjectTypes.ProjectDetail) : Bool {
        let currentPhase = _getCurrentPhase(project.timeline);
        switch (currentPhase) {
            case (#Created or #Upcoming) { true };
            case _ { false }; // IMMUTABLE after LIVE phase
        };
    };
    
    private func _validateProjectRequest(request: ProjectTypes.CreateProjectRequest) : Result.Result<(), Text> {
        // Validate timeline
        let now = Time.now();
        if (request.timeline.startTime <= now) {
            return #err("Start time must be in the future");
        };
        if (request.timeline.endTime <= request.timeline.startTime) {
            return #err("End time must be after start time");
        };
        if (request.timeline.claimTime <= request.timeline.endTime) {
            return #err("Claim time must be after end time");
        };
        if (request.timeline.listingTime <= request.timeline.claimTime) {
            return #err("Listing time must be after claim time");
        };
        
        // Validate launch parameters
        if (request.launchParams.sellAmount == 0) {
            return #err("Sell amount must be greater than 0");
        };
        if (request.launchParams.softCap >= request.launchParams.hardCap) {
            return #err("Soft cap must be less than hard cap");
        };
        if (request.launchParams.minimumPurchase > request.launchParams.maximumPurchase) {
            return #err("Minimum purchase must be less than or equal to maximum purchase");
        };
        
        // Validate token distribution percentages add up to 100%
        let distribution = request.tokenDistribution;
        var totalPercentage = 
            distribution.publicSale.percentage +
            distribution.team.percentage +
            distribution.liquidityPool.percentage +
            distribution.marketing.percentage +
            distribution.development.percentage +
            distribution.advisors.percentage +
            distribution.treasury.percentage;
        
        for (other in distribution.others.vals()) {
            totalPercentage += other.percentage;
        };
        
        if (totalPercentage != 10000) { // 100% in basis points
            return #err("Token distribution percentages must add up to 100%");
        };
        
        // Validate raised funds distribution
        let fundsDistribution = request.financialSettings.raisedFundsDistribution;
        var totalFundsPercentage = 
            fundsDistribution.liquidityPercentage +
            fundsDistribution.teamPercentage +
            fundsDistribution.developmentPercentage +
            fundsDistribution.marketingPercentage +
            fundsDistribution.platformFeePercentage;
        
        for (custom in fundsDistribution.customDistributions.vals()) {
            totalFundsPercentage += custom.percentage;
        };
        
        if (totalFundsPercentage != 10000) { // 100% in basis points
            return #err("Raised funds distribution percentages must add up to 100%");
        };
        
        #ok()
    };
    
    // ================ PROJECT MANAGEMENT ================
    public shared({ caller }) func createProject(
        request: ProjectTypes.CreateProjectRequest
    ) : async Result.Result<Text, Text> {
        if (Principal.isAnonymous(caller)) {
            return #err("Anonymous users cannot create projects");
        };
        
        // Validate request
        switch (_validateProjectRequest(request)) {
            case (#err(error)) { return #err(error) };
            case (#ok()) {};
        };
        
        let projectId = _generateProjectId();
        let now = Time.now();
        
        // Create project detail
        let projectDetail : ProjectTypes.ProjectDetail = {
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
            creator = caller;
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
        
        // Store project
        projects := Trie.put(projects, _textKey(projectId), Text.equal, projectDetail).0;
        
        // Update user projects
        let existingUserProjects = Option.get(
            Trie.get(userProjects, _principalKey(caller), Principal.equal), 
            []
        );
        let updatedUserProjects = Array.append(existingUserProjects, [projectId]);
        userProjects := Trie.put(userProjects, _principalKey(caller), Principal.equal, updatedUserProjects).0;
        
        #ok(projectId)
    };
    
    public shared({ caller }) func updateProject(
        projectId: Text,
        request: ProjectTypes.UpdateProjectRequest
    ) : async Result.Result<(), Text> {
        if (not _isProjectOwner(projectId, caller)) {
            return #err("Unauthorized: Not project owner");
        };
        
        switch (Trie.get(projects, _textKey(projectId), Text.equal)) {
            case (null) { return #err("Project not found") };
            case (?project) {
                if (not _canUpdateProject(project)) {
                    return #err("Project is immutable after LIVE phase");
                };
                
                let now = Time.now();
                let updatedProject : ProjectTypes.ProjectDetail = {
                    projectInfo = Option.get(request.projectInfo, project.projectInfo);
                    timeline = Option.get(request.timeline, project.timeline);
                    currentPhase = _getCurrentPhase(Option.get(request.timeline, project.timeline));
                    launchParams = project.launchParams; // IMMUTABLE
                    tokenDistribution = project.tokenDistribution; // IMMUTABLE
                    financialSettings = project.financialSettings; // IMMUTABLE
                    compliance = Option.get(request.compliance, project.compliance);
                    security = Option.get(request.security, project.security);
                    creator = project.creator;
                    createdAt = project.createdAt;
                    updatedAt = now;
                    deployedCanisters = project.deployedCanisters;
                    status = project.status;
                };
                
                projects := Trie.put(projects, _textKey(projectId), Text.equal, updatedProject).0;
                #ok()
            };
        };
    };
    
    public shared({ caller }) func deployLaunchpad(projectId: Text) : async Result.Result<Text, Text> {
        if (not _isProjectOwner(projectId, caller)) {
            return #err("Unauthorized: Not project owner");
        };
        
        switch (Trie.get(projects, _textKey(projectId), Text.equal)) {
            case (null) { return #err("Project not found") };
            case (?project) {
                // Check if launchpad already deployed
                switch (project.deployedCanisters.launchpadCanister) {
                    case (?canisterId) { return #ok(canisterId) };
                    case null {};
                };
                
                // Check cycles
                let cycleBalance = Cycles.balance();
                if (cycleBalance < CYCLES_FOR_INSTALL + MIN_CYCLES_IN_DEPLOYER) {
                    return #err("Not enough cycles in deployer, balance: " # debug_show(cycleBalance) # "T");
                };
                
                // Deploy launchpad canister
                Cycles.add<system>(CYCLES_FOR_INSTALL);
                let launchpadActor = await LaunchpadTemplate.LaunchpadCanister();
                let launchpadId = Principal.fromActor(launchpadActor);
                let launchpadIdText = Principal.toText(launchpadId);
                
                // Initialize launchpad
                let installResult = await launchpadActor.initialize(project);
                switch (installResult) {
                    case (#err(error)) { return #err(error) };
                    case (#ok()) {
                        // Update project with deployed canister
                        let updatedProject : ProjectTypes.ProjectDetail = {
                            project with
                            deployedCanisters = {
                                project.deployedCanisters with
                                launchpadCanister = ?launchpadIdText;
                            };
                            updatedAt = Time.now();
                        };
                        
                        projects := Trie.put(projects, _textKey(projectId), Text.equal, updatedProject).0;
                        #ok(launchpadIdText)
                    };
                };
            };
        };
    };
    
    // ================ QUERY FUNCTIONS ================
    public query func getProject(projectId: Text) : async Result.Result<ProjectTypes.ProjectDetail, Text> {
        switch (Trie.get(projects, _textKey(projectId), Text.equal)) {
            case (null) { #err("Project not found") };
            case (?project) { 
                // Update current phase based on current time
                let currentPhase = _getCurrentPhase(project.timeline);
                let updatedProject = { project with currentPhase = currentPhase };
                #ok(updatedProject) 
            };
        };
    };
    
    public query func getUserProjects(user: Principal) : async [Text] {
        Option.get(Trie.get(userProjects, _principalKey(user), Principal.equal), [])
    };
    
    public query func getProjectsByPhase(phase: ProjectTypes.LaunchpadPhase) : async [(Text, ProjectTypes.ProjectDetail)] {
        let buffer = Buffer.Buffer<(Text, ProjectTypes.ProjectDetail)>(0);
        
        for ((projectId, project) in Trie.iter(projects)) {
            let currentPhase = _getCurrentPhase(project.timeline);
            if (currentPhase == phase) {
                let updatedProject = { project with currentPhase = currentPhase };
                buffer.add((projectId, updatedProject));
            };
        };
        
        Buffer.toArray(buffer)
    };
    
    public query func getAllProjects() : async [(Text, ProjectTypes.ProjectDetail)] {
        let buffer = Buffer.Buffer<(Text, ProjectTypes.ProjectDetail)>(0);
        
        for ((projectId, project) in Trie.iter(projects)) {
            let currentPhase = _getCurrentPhase(project.timeline);
            let updatedProject = { project with currentPhase = currentPhase };
            buffer.add((projectId, updatedProject));
        };
        
        Buffer.toArray(buffer)
    };
    
    // ================ ADMIN FUNCTIONS ================
    public shared({ caller }) func updateCyclesConfig(
        cyclesForInstall: ?Nat,
        minCyclesInDeployer: ?Nat
    ) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can update cycles config");
        };
        
        switch (cyclesForInstall) {
            case (?cycles) { CYCLES_FOR_INSTALL := cycles };
            case null {};
        };
        
        switch (minCyclesInDeployer) {
            case (?cycles) { MIN_CYCLES_IN_DEPLOYER := cycles };
            case null {};
        };
        
        #ok()
    };
    
    public query func getCyclesConfig() : async { cyclesForInstall: Nat; minCyclesInDeployer: Nat } {
        {
            cyclesForInstall = CYCLES_FOR_INSTALL;
            minCyclesInDeployer = MIN_CYCLES_IN_DEPLOYER;
        }
    };
    
    public query func getStats() : async {
        totalProjects: Nat;
        projectsByPhase: [(ProjectTypes.LaunchpadPhase, Nat)];
    } {
        var totalProjects = 0;
        var createdCount = 0;
        var upcomingCount = 0;
        var liveCount = 0;
        var endedCount = 0;
        var claimCount = 0;
        var listedCount = 0;
        var cancelledCount = 0;
        
        for ((_, project) in Trie.iter(projects)) {
            totalProjects += 1;
            let currentPhase = _getCurrentPhase(project.timeline);
            switch (currentPhase) {
                case (#Created) { createdCount += 1 };
                case (#Upcoming) { upcomingCount += 1 };
                case (#Live) { liveCount += 1 };
                case (#Ended) { endedCount += 1 };
                case (#Claim) { claimCount += 1 };
                case (#Listed) { listedCount += 1 };
                case (#Cancelled) { cancelledCount += 1 };
            };
        };
        
        {
            totalProjects = totalProjects;
            projectsByPhase = [
                (#Created, createdCount),
                (#Upcoming, upcomingCount),
                (#Live, liveCount),
                (#Ended, endedCount),
                (#Claim, claimCount),
                (#Listed, listedCount),
                (#Cancelled, cancelledCount)
            ];
        }
    };

    // ================ HEALTH CHECK ================
    public query func healthCheck() : async Bool {
        true
    };
}
