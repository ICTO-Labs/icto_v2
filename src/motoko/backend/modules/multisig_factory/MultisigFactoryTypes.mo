// ICTO V2 Multisig Factory Types
// Type definitions for multisig factory backend module

import Principal "mo:base/Principal";
import MultisigTypes "../../../shared/types/MultisigTypes";

module {
    // ============== DEPLOYMENT TYPES ==============

    public type CreateMultisigRequest = {
        config: MultisigTypes.WalletConfig;
        initialDeposit: ?Nat; // Optional initial ICP deposit
    };

    public type DeploymentConfig = {
        factoryCanisterId: Principal;
        wasmModule: ?Blob; // Optional custom WASM
        cyclesForDeployment: Nat;
    };

    public type MultisigCall = {
        canisterId: Principal;
        args: CreateMultisigRequest;
        deploymentConfig: DeploymentConfig;
    };

    public type DeploymentResult = {
        walletId: MultisigTypes.WalletId;
        canisterId: Principal;
    };

    // ============== SERVICE STATE ==============

    public type ServiceState = {
        var totalDeployed: Nat;
        var totalFailed: Nat;
        var lastDeployment: ?Int;
    };

    public type StableState = {
        totalDeployed: Nat;
        totalFailed: Nat;
        lastDeployment: ?Int;
    };

    // ============== ERROR TYPES ==============

    public type DeploymentError = {
        #InsufficientCycles;
        #InvalidConfiguration: Text;
        #DeploymentFailed: Text;
        #Unauthorized;
        #RateLimited;
        #SystemError: Text;
    };

    // ============== WALLET REGISTRY TYPES ==============

    public type WalletRegistry = {
        id: MultisigTypes.WalletId;
        canisterId: Principal;
        creator: Principal;
        config: MultisigTypes.WalletConfig;
        createdAt: Int;
        status: WalletStatus;
        version: Nat;
    };

    public type WalletStatus = {
        #Active;
        #Paused;
        #Deprecated;
        #Failed;
    };

    public type FactoryStats = {
        totalWallets: Nat;
        activeWallets: Nat;
        totalVolume: Float;
        averageSigners: Float;
        deploymentSuccessRate: Float;
    };

    // ============== STATISTICS ==============

    public type ServiceStats = {
        totalDeployed: Nat;
        totalFailed: Nat;
        lastDeployment: ?Int;
        successRate: Float;
    };

    // ============== HELPER FUNCTIONS ==============

    public func walletStatusToText(status: WalletStatus): Text {
        switch (status) {
            case (#Active) "Active";
            case (#Paused) "Paused";
            case (#Deprecated) "Deprecated";
            case (#Failed) "Failed";
        }
    };
}