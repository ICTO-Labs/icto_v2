// ⬇️ Token Deployer Service Interface - V2 Enhanced with whitelist management
// Interface for ICTO V2 Token Deployer Service

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import ProjectTypes "../../shared/types/ProjectTypes";
import TokenDeployerTypes "../../shared/types/TokenDeployer";

module {
    
    // ================ TOKEN DEPLOYER INTERFACE ================
    public type Self = actor {
        // V2 Primary deployment function with backend configuration (Central Gateway Pattern)
        deployTokenWithConfig: shared (TokenDeployerTypes.TokenConfig, TokenDeployerTypes.DeploymentConfig, ?Principal) -> async Result.Result<Principal, Text>;
        
        // Query functions
        getTokenInfo: query (Text) -> async ?TokenDeployerTypes.TokenInfo;
        getTokensByOwner: query (Principal, Nat, Nat) -> async [TokenDeployerTypes.TokenInfo];
        getAllTokens: query (Nat, Nat) -> async [TokenDeployerTypes.TokenInfo];
        getDeploymentHistory: query (Text) -> async ?TokenDeployerTypes.DeploymentResult;
        getTotalTokens: query () -> async Nat;
        
        // Service info
        getServiceInfo: query () -> async TokenDeployerTypes.ServiceInfo;
        getCurrentWasmInfo: query () -> async {
            version: Text;
            size: Nat;
            isManual: Bool;
        };
        getConfiguration: query () -> async {
            deploymentFee: Nat;
            minCyclesInDeployer: Nat;
            cyclesForInstall: Nat;
            cyclesForArchive: Nat64;
            allowManualWasm: Bool;
        };
        
        // Admin functions - whitelist management (standardized)
        addToWhitelist: shared (Principal) -> async Result.Result<(), Text>;
        removeFromWhitelist: shared (Principal) -> async Result.Result<(), Text>;
        getWhitelistedBackends: query () -> async [Principal];
        isWhitelisted: query (Principal) -> async Bool;
        
        // Legacy functions for backward compatibility
        addBackendToWhitelist: shared (Principal) -> async Result.Result<(), Text>;
        removeBackendFromWhitelist: shared (Principal) -> async Result.Result<(), Text>;
        
        // Admin functions - general
        addAdmin: shared (Text) -> async Result.Result<(), Text>;
        removeAdmin: shared (Text) -> async Result.Result<(), Text>;
        getAdmins: query () -> async [Text];
        
        // Configuration management
        updateConfiguration: shared (?Nat, ?Nat, ?Nat, ?Nat64, ?Bool) -> async Result.Result<(), Text>;
        
        // WASM management - manual upload (for testing)
        uploadChunk: shared ([Nat8]) -> async Result.Result<Nat, Text>;
        clearChunks: shared () -> async Result.Result<(), Text>;
        addWasm: shared ([Nat8]) -> async Result.Result<Text, Text>;
        getLatestWasmVersion: shared () -> async Result.Result<Text, Text>;
        
        // Health check
        healthCheck: query () -> async Bool;
        cycleBalance: query () -> async Nat;
        
        // Enhanced health check for setupMicroservices integration
        getServiceHealth: query () -> async {
            isHealthy: Bool;
            cyclesBalance: Nat;
            hasWasmData: Bool;
            totalDeployments: Nat;
            uptime: Int;
        };
        
        // Auto-healing health check that fetches WASM if missing
        getServiceHealthWithAutoHeal: shared () -> async {
            isHealthy: Bool;
            cyclesBalance: Nat;
            hasWasmData: Bool;
            totalDeployments: Nat;
            uptime: Int;
            autoHealAttempted: Bool;
            autoHealSuccess: Bool;
        };
        
        // Bootstrap function for initial backend setup
        bootstrapBackendSetup: shared (Principal) -> async Result.Result<(), Text>;
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