// ⬇️ Shared CORE types for the Backend service
// Central, minimal type definitions for consistency

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Int "mo:base/Int";

module {
    // ===== CORE SYSTEM TYPES =====
    
    public type CanisterId = Principal;
    public type Timestamp = Int;
    public type UserId = Principal;
    public type ProjectId = Text;
    public type PipelineId = Text;
    public type StepId = Text;
    
    // ===== COMMON UTILITY TYPES =====
    
    public type Page<T> = {
        data: [T];
        totalCount: Nat;
        page: Nat;
        pageSize: Nat;
        hasNext: Bool;
    };
    
    public type PaginationParams = {
        page: Nat;
        pageSize: Nat;
    };
} 