import Principal "mo:base/Principal";
import Result "mo:base/Result";
import DAOFactoryTypes "./DAOFactoryTypes";
import DAOTypes "../../../shared/types/DAOTypes";

module DAOFactoryInterface {

    // ==================================================================================================
    // DAO FACTORY ACTOR INTERFACE
    // ==================================================================================================

    // DAO Factory Types for interface - matches actual DAO factory
    public type CreateDAOArgs = {
        tokenConfig: DAOTypes.TokenConfig;
        systemParams: ?DAOTypes.SystemParams;
        initialAccounts: ?[DAOTypes.Account];
        emergencyContacts: [Principal];
        customSecurity: ?DAOTypes.CustomSecurityParams; // Optional custom security parameters
        governanceLevel: DAOTypes.GovernanceLevel;
    };

    public type CreateDAOResult = {
        #Ok: { daoId: Text; canisterId: Principal };
        #Err: Text;
    };

    // Interface for communicating with the DAO Factory canister
    public type DAOFactoryActor = actor {
        // Create a new DAO (actual DAO factory function)
        createDAO: (CreateDAOArgs) -> async CreateDAOResult;
        
        // Get DAO information
        getDaoInfo: (Text) -> async ?{
            id: Text;
            canisterId: Principal;
            creator: Principal;
            createdAt: Int;
            status: { #Active; #Paused; #Archived };
        };
        
        // Get user's DAOs
        getUserDaos: (Principal) -> async [{
            id: Text;
            canisterId: Principal;
            creator: Principal;
            createdAt: Int;
            status: { #Active; #Paused; #Archived };
        }];
        
        // Admin functions
        addToWhitelist: (Principal) -> async Result.Result<(), Text>;
        removeFromWhitelist: (Principal) -> async Result.Result<(), Text>;
        isWhitelisted: (Principal) -> async Bool;
        
        // Service info
        getServiceInfo: () -> async {
            name: Text;
            version: Text;
            description: Text;
            endpoints: [Text];
            maintainer: Text;
            minCycles: Nat;
            cyclesForInstall: Nat;
        };
        
        // Health check
        healthCheck: () -> async Bool;
    };
}
