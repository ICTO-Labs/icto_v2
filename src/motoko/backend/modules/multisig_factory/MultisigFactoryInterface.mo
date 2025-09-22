// ICTO V2 Multisig Factory Interface
// Interface definitions for multisig factory actor communication

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import MultisigTypes "../../../shared/types/MultisigTypes";
import MultisigFactoryTypes "./MultisigFactoryTypes";

module {
    // ============== DEPLOYMENT ARGUMENTS ==============

    public type CreateMultisigArgs = {
        config: MultisigTypes.WalletConfig;
        creator: ?Principal;
        initialCycles: ?Nat;
    };

    // ============== FACTORY ACTOR INTERFACE ==============

    public type MultisigFactoryActor = actor {
        // Core deployment function
        createMultisigWallet : (
            MultisigTypes.WalletConfig,
            ?Principal, // creator
            ?Nat // initial cycles
        ) -> async Result.Result<{
            walletId: MultisigTypes.WalletId;
            canisterId: Principal;
        }, Text>;

        // Query functions
        getWallet : (MultisigTypes.WalletId) -> async ?MultisigFactoryTypes.WalletRegistry;
        getWalletsByCreator : (Principal) -> async [MultisigFactoryTypes.WalletRegistry];
        getAllWallets : () -> async [MultisigFactoryTypes.WalletRegistry];
        getFactoryStats : () -> async MultisigFactoryTypes.FactoryStats;
        isWalletActive : (MultisigTypes.WalletId) -> async Bool;

        // Admin functions
        addAdmin : (Principal) -> async Result.Result<(), Text>;
        addToWhitelist : (Principal) -> async Result.Result<(), Text>;
        pauseWallet : (MultisigTypes.WalletId) -> async Result.Result<(), Text>;
        resumeWallet : (MultisigTypes.WalletId) -> async Result.Result<(), Text>;
        emergencyPause : () -> async Result.Result<(), Text>;

        // Health check
        healthCheck : () -> async Bool;
        getCyclesBalance : () -> async Nat;
    };

}