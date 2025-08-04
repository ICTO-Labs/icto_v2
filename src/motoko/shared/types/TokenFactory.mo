// ================ UNIFIED TOKEN DEPLOYER TYPES ================
// Merged from:
// 1. shared/types/TokenDeployer.mo
// 2. backend/types/TokenDeployer.mo
// 3. backend/types/APITypes.mo (token-related)

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import ICRC "./ICRC";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";

module TokenFactory {

    // ================ CORE TOKEN TYPES ================
    
    public type TokenInfo = {
        // Core token data
        name : Text;
        symbol : Text;
        canisterId : Principal;
        decimals : Nat8;
        transferFee : Nat;
        totalSupply : Nat;
        
        // Metadata
        description : ?Text;
        logo : ?Text;
        website : ?Text;
        
        // Deployment info
        owner : Principal;
        deployer : Principal;
        deployedAt : Time.Time;
        moduleHash : Text;
        wasmVersion : Text;
        
        // V2 enhancements
        standard : Text; // "ICRC-1", "ICRC-2", etc.
        features : [Text]; // ["governance", "staking", etc.]
        status : TokenStatus;
        
        // Integration data
        projectId : ?Text;
        launchpadId : ?Principal;
        lockContracts : [(Text, Principal)];
        
        // Cycle management
        enableCycleOps : Bool;
        lastCycleCheck : Time.Time;
    };

    // Backup from backend/types/TokenDeployer
    public type TokenInfo_bk = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        description: ?Text;
        transferFee: Nat;
        logo: ?Text;
        website: ?Text;
        socialLinks: ?[(Text, Text)];
    };
    
    public type TokenStatus = {
        #Active;
        #Archived;
        #Faulty;
    };

    public type TokenRecord = {
        tokenId: Text;
        canisterId: Principal;
        projectId: Text;
        owner: Principal;
        tokenInfo: TokenInfo_bk;
        initialSupply: Nat;
        currentSupply: ?Nat;
        deployedAt: Int;
        status: Text;
        transactionCount: Nat;
        holderCount: Nat;
        metadata: {
            version: Text;
            deployer: Text;
            cyclesUsed: Nat;
        };
    };
    
    // ================ DEPLOYMENT TYPES ================
    
    public type TokenConfig_bk = {
        name : Text;
        symbol : Text;
        decimals : Nat8;
        transferFee : Nat;
        totalSupply : Nat;
        description : ?Text;
        logo : ?Text;
        website : ?Text;
        features : [Text];
        initialBalances : [(ICRC.Account, Nat)];
        minter : ?ICRC.Account;
        feeCollector : ?ICRC.Account;
        projectId : ?Text;
    };

    // Backup from backend/types/TokenDeployer
    public type TokenConfig = {
        name: Text;
        symbol: Text;
        decimals: Nat8;
        logo: ?Text;
        minter: ?{ owner : Principal; subaccount : ?Blob };
        feeCollector: ?{ owner : Principal; subaccount : ?Blob };
        transferFee: Nat;
        initialBalances: [({ owner : Principal; subaccount : ?Blob }, Nat)];
        totalSupply: Nat;
        description: ?Text;
        website: ?Text;
        projectId: ?Text;
    };
    
    public type DeploymentConfig = {
        tokenOwner: ?Principal;
        enableCycleOps: ?Bool;
        cyclesForInstall: ?Nat;
        cyclesForArchive: ?Nat;
        minCyclesInDeployer: ?Nat;
        archiveOptions: ?ArchiveOptions;
    };

    // Backup from backend/types/TokenDeployer
    public type DeploymentConfig_bk = {
        cyclesForInstall: ?Nat64;
        cyclesForArchive: ?Nat64;
        minCyclesInDeployer: ?Nat64;
        archiveOptions: ?ArchiveOptions_bk;
        enableCycleOps: ?Bool;
        tokenOwner: Principal;
    };
    
    public type TokenDeploymentRequest = {
        projectId: ?Text;
        tokenInfo: TokenInfo_bk;
        initialSupply: Nat;
        options: ?TokenDeploymentOptions;
    };

    public type TokenDeploymentOptions = {
        allowSymbolConflict: Bool;
        enableAdvancedFeatures: Bool;
        customMinter: ?Principal;
        customFeeCollector: ?Principal;
        enableCyclesOps: ?Bool;
        initialBalances: ?[(ICRC.Account, Nat)];
    };

    public type TokenDeploymentResult = {
        canisterId: Principal;
        projectId: ?Text;
        deployedAt: Int;
        cyclesUsed: Nat;
        tokenSymbol: Text;
        initialSupply: Nat;
    };
    
    public type PendingDeployment = {
        requestId : Text;
        requester : Principal;
        tokenConfig : TokenConfig;
        deploymentConfig : ?DeploymentConfig;
        createdAt : Time.Time;
        status : DeploymentStatus;
        error : ?Text;
    };
    
    public type DeploymentStatus_bk = {
        #Pending;
        #Installing;
        #Configuring;
        #Completed;
        #Failed;
    };
    
    public type DeploymentRecord = {
        id : Text;
        tokenCanisterId : Principal;
        deployer : Principal;
        owner : Principal;
        deployedAt : Time.Time;
        config : TokenConfig;
        deploymentConfig : ?DeploymentConfig;
        deploymentTime : Nat;
        cyclesUsed : Nat;
        success : Bool;
        error : ?Text;
    };
    
    // ================ ARCHIVE OPTIONS ================
    
    public type ArchiveOptions = {
        num_blocks_to_archive : Nat64;
        max_transactions_per_response : ?Nat64;
        trigger_threshold : Nat64;
        max_message_size_bytes : ?Nat64;
        cycles_for_archive_creation : ?Nat64;
        node_max_memory_size_bytes : ?Nat64;
        controller_id : Principal;
        more_controller_ids : ?[Principal];
    };

    // Backup from backend/types/TokenDeployer
    public type ArchiveOptions_bk = {
        maxArchiveSize: Nat;
        maxArchiveDuration: Nat;
        maxArchiveCount: Nat;
    };
    
        // ================ DEPLOYMENT RESULT TYPES ================
    
    public type DeploymentResult = {
        deploymentId: Text;
        deploymentType: Text;
        canisterId: ?Text;
        projectId: ?Text;
        status: DeploymentStatus;
        createdAt: Time.Time;
        startedAt: ?Time.Time;
        completedAt: ?Time.Time;
        metadata: DeploymentMetadata;
        steps: [DeploymentStepResult]; // For pipeline deployments
    };
    
    public type DeploymentStatus = {
        #Pending;
        #Queued;
        #InProgress;
        #Completed;
        #Failed: Text;
        #Cancelled;
        #Timeout;
        #PartialSuccess;
        #RollingBack;
    };
    
    public type DeploymentMetadata = {
        deployedBy: Principal;
        estimatedCost: Nat;
        actualCost: ?Nat;
        cyclesUsed: ?Nat;
        transactionId: ?Text;
        paymentRecordId: ?Text;
        serviceEndpoint: Text;
        version: Text;
        environment: Text; // "development", "staging", "production"
    };
    
    public type DeploymentStepResult = {
        stepId: Text;
        stepType: Text;
        status: DeploymentStatus;
        canisterId: ?Text;
        startedAt: Time.Time;
        completedAt: ?Time.Time;
        cyclesUsed: ?Nat;
        errorMessage: ?Text;
        retryCount: Nat;
    };

    // ================ V1 COMPATIBILITY TYPES ================
    
    public type InitArgsRequested = {
        token_symbol : Text;
        transfer_fee : Nat;
        token_name : Text;
        minting_account : ICRC.Account;
        initial_balances : [(ICRC.Account, Nat)];
        fee_collector_account : ?ICRC.Account;
        logo : Text;
    };
    
    public type TokenData = {
        launchpadId : ?Principal;
        description : ?Text;
        links : ?[Text];
        lockContracts : ?[(Text, Principal)];
        tokenProvider : ?Text;
        enableCycleOps : Bool;
    };
    
    // ================ LEDGER TYPES ================
    
    public type LedgerArg = {
        #Init: {
            token_symbol : Text;
            token_name : Text;
            decimals : ?Nat8;
            transfer_fee : Nat;
            minting_account : ICRC.Account;
            initial_balances : [(ICRC.Account, Nat)];
            fee_collector_account : ?ICRC.Account;
            archive_options : ArchiveOptions;
            max_memo_length : ?Nat16;
            feature_flags : ?{ icrc2 : Bool };
            maximum_number_of_accounts : ?Nat64;
            accounts_overflow_trim_quantity : ?Nat64;
            metadata : [(Text, MetadataValue)];
        };
        #Upgrade: {
            token_symbol : ?Text;
            transfer_fee : ?Nat;
            token_name : ?Text;
            metadata : ?[(Text, MetadataValue)];
            maximum_number_of_accounts : ?Nat64;
            accounts_overflow_trim_quantity : ?Nat64;
            max_memo_length : ?Nat16;
            feature_flags : ?{ icrc2 : Bool };
            change_fee_collector : ?ChangeFeeCollector;
            change_archive_options : ?ArchiveOptions;
        };
    };
    
    public type MetadataValue = {
        #Nat : Nat;
        #Int : Int;
        #Text : Text;
        #Blob : Blob;
    };
    
    public type ChangeFeeCollector = {
        #SetTo : ICRC.Account;
        #Unset;
    };
    
    // ================ SERVICE TYPES ================
    
    public type ServiceInfo = {
        name : Text;
        version : Text;
        status : Text;
        totalDeployments : Nat;
        successfulDeployments : Nat;
        failedDeployments : Nat;
        uptime : Int;
        wasmVersion : Text;
        hasWasmData : Bool;
    };
    
    // ================ API RESPONSE TYPES ================
    
    public type DeploymentResultToken = {
        id : Text;
        success : Bool;
        error : ?Text;
        canisterId : ?Principal;
        deployer : Principal;
        owner : Principal;
        deployedAt : Time.Time;
        deploymentTime : Int;
        cyclesUsed : Nat;
        wasmVersion : Text;
    };
    
    public type AdminResult = Result.Result<(), Text>;
    public type VersionResult = Result.Result<Text, Text>;

    // Structured error type for deployment failures
    public type DeploymentError = {
        #Unauthorized;
        #Validation: Text;
        #InsufficientCycles: { balance: Nat; required: Nat };
        #NoWasm;
        #CreateFailed: { msg: Text; pendingId: Text };
        #InstallFailed: { canisterId: Principal; msg: Text; pendingId: Text };
        #OwnershipFailed: { canisterId: Principal; msg: Text; pendingId: Text };
        #InternalError: Text;
        #PendingDeploymentNotFound: Text;
    };
    
    // Result type for the main deploy function
    public type DeployResult = Result.Result<Principal, DeploymentError>;
} 