// ⬇️ Shared Helper functions across all ICTO V2 services

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Common "../types/Common";

module {
    // ================ KEY CREATION UTILITIES ================
    
    public func textKey(t: Text) : {key: Text; hash: Nat32} {
        {key = t; hash = Text.hash(t)}
    };
    
    public func principalKey(p: Principal) : {key: Principal; hash: Nat32} {
        {key = p; hash = Principal.hash(p)}
    };

    // ================ ID CREATION UTILITIES ================

    public func createProjectId(owner: Common.UserId, timestamp: Common.Timestamp) : Common.ProjectId {
        Principal.toText(owner) # "_" # Int.toText(timestamp)
    };
    
    public func createPipelineId(projectId: Common.ProjectId, timestamp: Common.Timestamp) : Common.PipelineId {
        projectId # "_pipeline_" # Int.toText(timestamp)
    };
} 