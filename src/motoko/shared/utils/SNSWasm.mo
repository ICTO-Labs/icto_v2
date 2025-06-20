// SNS-W interface for fetching ICRC ledger WASM files

import Principal "mo:base/Principal";

module {
    public type Self = actor {
        get_latest_sns_version_pretty : (?GetLatestSnsVersionPrettyRequest) -> async [(Text, Text)];
        get_wasm : GetWasmRequest -> async GetWasmResponse;
    };
    
    public type GetLatestSnsVersionPrettyRequest = {
        update_type : ?UpdateType;
    };
    
    public type UpdateType = {
        #All;
        #UpdateOnly;
    };
    
    public type GetWasmRequest = {
        hash : Blob;
    };
    
    public type GetWasmResponse = {
        wasm : ?SnsWasm;
    };
    
    public type SnsWasm = {
        wasm : Blob;
        canister_type : SnsCanisterType;
        proposal_id : ?Nat64;
    };
    
    public type SnsCanisterType = {
        #Root;
        #Governance;
        #Ledger;
        #Swap;
        #Archive;
        #Index;
    };
} 