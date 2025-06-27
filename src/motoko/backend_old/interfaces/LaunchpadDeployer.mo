// ⬇️ Launchpad Deployer Service Interface - Simple interface for project deployment
// Interface for ICTO V2 Launchpad Deployer Service

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import ProjectTypes "../../shared/types/ProjectTypes";

module {
    
    // ================ LAUNCHPAD DEPLOYER INTERFACE ================
    public type Self = actor {
        // Main project creation function
        createProject: shared (ProjectTypes.CreateProjectRequest) -> async Result.Result<Text, Text>;
        
        // Project management functions
        updateProject: shared (Text, ProjectTypes.UpdateProjectRequest) -> async Result.Result<(), Text>;
        getProject: query (Text) -> async ?ProjectTypes.ProjectDetail;
        getUserProjects: query (Principal) -> async [Text];
        
        // Service health functions
        healthCheck: () -> async Bool;
        getServiceHealth: query () -> async {
            totalProjects: Nat;
            cyclesBalance: Nat;
            isHealthy: Bool;
        };
        
        // Admin functions
        addAdmin: shared (Principal) -> async Result.Result<(), Text>;
        addToWhitelist: shared (Principal) -> async Result.Result<(), Text>;
        getWhitelist: shared query () -> async [Principal];
        
        // Service info
        getServiceInfo: query () -> async {
            name: Text;
            version: Text;
            description: Text;
            endpoints: [Text];
            maintainer: Text;
        };
    };
    
    // ================ TYPES ================
    
    public type UpdateProjectRequest = {
        projectInfo: ?ProjectTypes.ProjectInfo;
        timeline: ?ProjectTypes.Timeline;
        launchParams: ?ProjectTypes.LaunchParams;
        tokenDistribution: ?ProjectTypes.TokenDistribution;
    };
} 