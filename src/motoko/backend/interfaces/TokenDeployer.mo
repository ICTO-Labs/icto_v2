// ⬇️ Token Deployer Service Interface - Simplified to match actual implementation
// Interface for ICTO V2 Token Deployer Service

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import ProjectTypes "../../shared/types/ProjectTypes";

module {
    
    // ================ TOKEN DEPLOYER INTERFACE ================
    public type Self = actor {
        // Main deployment function (new standardized interface)
        deploy: shared ({
            projectId: ?Text;
            tokenInfo: ProjectTypes.TokenInfo;
            initialSupply: Nat;
            premintTo: ?Principal;
            metadata: ?[(Text, Text)];
        }) -> async Result.Result<DeployTokenResponse, Text>;
        
        // Backward compatibility function
        deployToken: shared ({
            projectId: ?Text;
            tokenInfo: ProjectTypes.TokenInfo;
            initialSupply: Nat;
            premintTo: ?Principal;
            metadata: ?[(Text, Text)];
        }) -> async Result.Result<DeployTokenResponse, Text>;
        
        // Query functions
        getDeploymentRecord: query (Text) -> async ?DeploymentRecord;
        getAllDeployments: query () -> async [DeploymentRecord];
        getDeploymentsByUser: query (Principal) -> async [DeploymentRecord];
        getServiceHealth: query () -> async {
            totalDeployments: Nat;
            cyclesBalance: Nat;
            isHealthy: Bool;
        };
        
        // Admin functions
        addAdmin: shared (Principal) -> async Result.Result<(), Text>;
        addToWhitelist: shared (Principal) -> async Result.Result<(), Text>;
        getWhitelist: shared query () -> async [Principal];
        getAdmins: shared query () -> async [Principal];
        
        // Health and service info
        healthCheck: () -> async Bool;
        getHealthInfo: query () -> async {
            isHealthy: Bool;
            version: Text;
            uptime: Nat;
            lastActivity: ?Time.Time;
            resourceUsage: {
                cycles: Nat;
                memory: Nat;
                totalDeployments: Nat;
            };
            capabilities: [Text];
            status: Text;
        };
        getServiceInfo: query () -> async {
            name: Text;
            version: Text;
            description: Text;
            endpoints: [Text];
            maintainer: Text;
        };
        
        // Cycle management
        cyclesBalance: query () -> async Nat;
    };
    
    // ================ TYPES ================
    
    public type DeploymentRecord = {
        canisterId: Principal;
        deployedBy: Principal;
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        deployedAt: Time.Time;
        cyclesUsed: Nat;
        deploymentType: DeploymentType;
    };
    
    public type DeploymentType = {
        #Fresh; // New canister created
        #Upgrade; // Existing canister upgraded
    };
    
    public type DeployTokenRequest = {
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        initialSupply: Nat;
        premintTo: ?Principal;
        metadata: ?[(Text, Text)];
    };
    
    public type DeployTokenResponse = {
        canisterId: Text;
        projectId: ?Text;
        tokenInfo: ProjectTypes.TokenInfo;
        deployedAt: Time.Time;
        deployedBy: Principal;
        cyclesUsed: Nat;
    };
} 