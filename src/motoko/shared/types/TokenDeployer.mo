// Token Deployer Types - Centralized type definitions

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";

import ICRC "./ICRC";

module {
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
    
    public type TokenStatus = {
        #Active;
        #Paused;
        #Deprecated;
        #Upgrading;
    };
    
    // ================ DEPLOYMENT TYPES ================
    
    public type TokenConfig = {
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
    
    public type DeploymentConfig = {
        cyclesForInstall : ?Nat;
        cyclesForArchive : ?Nat64;
        minCyclesInDeployer : ?Nat;
        archiveOptions : ?ArchiveOptions;
        enableCycleOps : ?Bool;
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
    
    public type DeploymentStatus = {
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
        deploymentTime : Nat; // milliseconds
        cyclesUsed : Nat;
        success : Bool;
        error : ?Text;
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
    
    public type DeploymentResult = {
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
} 