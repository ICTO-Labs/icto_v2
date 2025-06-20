// IC Management Canister interface for canister operations

import Principal "mo:base/Principal";

module {
    public type Self = actor {
        create_canister : CreateCanisterArgs -> async CreateCanisterResult;
        update_settings : UpdateSettingsArgs -> async ();
        install_code : InstallCodeArgs -> async ();
        uninstall_code : UninstallCodeArgs -> async ();
        start_canister : StartCanisterArgs -> async ();
        stop_canister : StopCanisterArgs -> async ();
        canister_status : CanisterStatusArgs -> async CanisterStatusResult;
        delete_canister : DeleteCanisterArgs -> async ();
    };
    
    public type CreateCanisterArgs = {
        settings : ?CanisterSettings;
        sender_canister_version : ?Nat64;
    };
    
    public type CreateCanisterResult = {
        canister_id : Principal;
    };
    
    public type UpdateSettingsArgs = {
        canister_id : Principal;
        settings : CanisterSettings;
        sender_canister_version : ?Nat64;
    };
    
    public type InstallCodeArgs = {
        mode : InstallMode;
        canister_id : Principal;
        wasm_module : Blob;
        arg : Blob;
        sender_canister_version : ?Nat64;
    };
    
    public type UninstallCodeArgs = {
        canister_id : Principal;
        sender_canister_version : ?Nat64;
    };
    
    public type StartCanisterArgs = {
        canister_id : Principal;
    };
    
    public type StopCanisterArgs = {
        canister_id : Principal;
    };
    
    public type CanisterStatusArgs = {
        canister_id : Principal;
    };
    
    public type DeleteCanisterArgs = {
        canister_id : Principal;
    };
    
    public type CanisterSettings = {
        controllers : ?[Principal];
        compute_allocation : ?Nat;
        memory_allocation : ?Nat;
        freezing_threshold : ?Nat;
        reserved_cycles_limit : ?Nat;
    };
    
    public type InstallMode = {
        #install;
        #reinstall;
        #upgrade : ?UpgradeArgs;
    };
    
    public type UpgradeArgs = {
        skip_pre_upgrade : ?Bool;
    };
    
    public type CanisterStatusResult = {
        status : CanisterStatus;
        settings : CanisterSettings;
        module_hash : ?Blob;
        memory_size : Nat;
        cycles : Nat;
        reserved_cycles : Nat;
        idle_cycles_burned_per_day : Nat;
    };
    
    public type CanisterStatus = {
        #running;
        #stopping;
        #stopped;
    };
} 