import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Prim "mo:prim";

import Types "./types/Types";

actor AuditStorage {
    
    // ================ SERVICE CONFIGURATION ================
    private let SERVICE_VERSION : Text = "1.0.0";
    private stable var serviceStartTime : Time.Time = 0;
    
    // ================ STABLE VARIABLES ================
    private stable var whitelistedCanisters : [(Principal, Bool)] = [];
    private stable var auditEntriesStable : [(Text, Types.AuditEntry)] = [];
    private stable var systemEventsStable : [(Text, Types.SystemEvent)] = [];
    
    // Runtime variables
    private var whitelistTrie : Trie.Trie<Principal, Bool> = Trie.empty();
    private var auditEntries : Trie.Trie<Text, Types.AuditEntry> = Trie.empty();
    private var systemEvents : Trie.Trie<Text, Types.SystemEvent> = Trie.empty();
    
    // ================ UPGRADE FUNCTIONS ================
    system func preupgrade() {
        Debug.print("AuditStorage: Starting preupgrade");
        whitelistedCanisters := Trie.toArray<Principal, Bool, (Principal, Bool)>(whitelistTrie, func (k, v) = (k, v));
        auditEntriesStable := Trie.toArray<Text, Types.AuditEntry, (Text, Types.AuditEntry)>(auditEntries, func (k, v) = (k, v));
        systemEventsStable := Trie.toArray<Text, Types.SystemEvent, (Text, Types.SystemEvent)>(systemEvents, func (k, v) = (k, v));
        Debug.print("AuditStorage: Preupgrade completed");
    };

    system func postupgrade() {
        Debug.print("AuditStorage: Starting postupgrade");
        
        // Restore whitelist
        for ((principal, enabled) in whitelistedCanisters.vals()) {
            whitelistTrie := Trie.put(whitelistTrie, _principalKey(principal), Principal.equal, enabled).0;
        };
        
        // Restore audit logs
        for ((id, log) in auditEntriesStable.vals()) {
            auditEntries := Trie.put(auditEntries, _textKey(id), Text.equal, log).0;
        };
        
        // Restore system events
        for ((id, event) in systemEventsStable.vals()) {
            systemEvents := Trie.put(systemEvents, _textKey(id), Text.equal, event).0;
        };
        
        // Clear stable variables
        whitelistedCanisters := [];
        auditEntriesStable := [];
        systemEventsStable := [];
        
        // Initialize service start time if not set
        if (serviceStartTime == 0) {
            serviceStartTime := Time.now();
        };
        
        Debug.print("AuditStorage: Postupgrade completed");
    };
    
    // Initialize service start time
    serviceStartTime := Time.now();
    
    // ================ HELPER FUNCTIONS ================
    private func _textKey(text: Text) : Trie.Key<Text> {
        { key = text; hash = Text.hash(text) }
    };
    
    private func _principalKey(principal: Principal) : Trie.Key<Principal> {
        { key = principal; hash = Principal.hash(principal) }
    };
    
    private func _isWhitelisted(caller: Principal) : Bool {
        // Always allow controller
        if (Principal.isController(caller)) {
            return true;
        };
        
        switch (Trie.get(whitelistTrie, _principalKey(caller), Principal.equal)) {
            case (?enabled) { enabled };
            case null { false };
        };
    };
    
    private func _generateId(prefix: Text) : Text {
        prefix # "_" # Int.toText(Time.now())
    };
    
    // ================ WHITELIST MANAGEMENT ================
    public shared({ caller }) func addToWhitelist(canisterId: Principal) : async Result.Result<(), Text> {
        // Only admin/controller can manage whitelist
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can manage whitelist");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(canisterId), Principal.equal, true).0;
        #ok()
    };
    
    public shared({ caller }) func removeFromWhitelist(canisterId: Principal) : async Result.Result<(), Text> {
        if (not Principal.isController(caller)) {
            return #err("Unauthorized: Only controllers can manage whitelist");
        };
        
        whitelistTrie := Trie.put(whitelistTrie, _principalKey(canisterId), Principal.equal, false).0;
        #ok()
    };
    
    public query func getWhitelistedCanisters() : async [Principal] {
        let buffer = Buffer.Buffer<Principal>(0);
        for ((principal, enabled) in Trie.iter(whitelistTrie)) {
            if (enabled) {
                buffer.add(principal);
            };
        };
        Buffer.toArray(buffer)
    };
    
    // Standardized isWhitelisted function
    public query func isWhitelisted(caller: Principal) : async Bool {
        _isWhitelisted(caller)
    };
    
    // ================ AUDIT LOG FUNCTIONS ================
    public shared({ caller }) func logAuditEntry(
        entry: Types.AuditEntry
    ) : async Result.Result<Text, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        // The backend generates the ID, but we can overwrite it or validate it.
        // For now, we'll trust the incoming ID.
        let logId = entry.id;

        // We can also overwrite the timestamp to prevent spoofing
        let finalEntry = { entry with timestamp = Time.now(); canisterId = ?caller };

        auditEntries := Trie.put(auditEntries, _textKey(logId), Text.equal, finalEntry).0;
        #ok(logId)
    };
    
    public query({ caller }) func getAuditLogs(
        userId: ?Principal,
        limit: ?Nat
    ) : async Result.Result<[Types.AuditEntry], Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let buffer = Buffer.Buffer<Types.AuditEntry>(0);
        let maxLimit = Option.get(limit, 100);
        var count = 0;
        
        label logs for ((_, log) in Trie.iter(auditEntries)) {
            if (count >= maxLimit) break logs;
            
            var shouldInclude = true;
            
            // Filter by userId if provided
            switch (userId) {
                case (?uid) {
                    if (log.userId != uid) {
                        shouldInclude := false;
                    };
                };
                case null { };
            };
            
            if (shouldInclude) {
                buffer.add(log);
                count += 1;
            };
        };
        
        #ok(Buffer.toArray(buffer))
    };
    
    // ================ SYSTEM EVENT FUNCTIONS ================
    public shared({ caller }) func logSystemEvent(
        eventType: Types.SystemEventType,
        description: Text,
        severity: Types.Severity,
        metadata: ?[(Text, Text)]
    ) : async Result.Result<Text, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let eventId = _generateId("event");
        let systemEvent : Types.SystemEvent = {
            id = eventId;
            eventType = eventType;
            description = description;
            severity = severity;
            metadata = metadata;
            timestamp = Time.now();
            canisterId = Principal.toText(caller);
        };
        
        systemEvents := Trie.put(systemEvents, _textKey(eventId), Text.equal, systemEvent).0;
        #ok(eventId)
    };

    public query({ caller }) func getSystemEvents(
        eventType: ?Types.SystemEventType,
        limit: ?Nat
    ) : async Result.Result<[Types.SystemEvent], Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let buffer = Buffer.Buffer<Types.SystemEvent>(0);
        let maxLimit = Option.get(limit, 100);
        var count = 0;
        
        let filteredTrie = Trie.filter<Text, Types.SystemEvent>(
            systemEvents,
            func (k, v) = switch (eventType) {
                case (?et) { v.eventType == et };
                case null { true };
            }
        );

        label events for ((_, event) in Trie.iter(filteredTrie)) {
            if (count >= maxLimit) break events;
            buffer.add(event);
            count += 1;
        };
        
        #ok(Buffer.toArray(buffer))
    };

    public query func getSystemEvent(id: Text) : async Result.Result<Types.SystemEvent, Text> {
        // if (not _isWhitelisted(caller)) {
        //     return #err("Unauthorized: Caller not whitelisted");
        // };
        
        switch (Trie.get(systemEvents, _textKey(id), Text.equal)) {
            case (?event) { #ok(event) };
            case null { #err("Event not found") };
        };
    };

    public query func getEntry(id: Text) : async Result.Result<Types.AuditEntry, Text> {
        switch (Trie.get(auditEntries, _textKey(id), Text.equal)) {
            case (?entry) { #ok(entry) };
            case null { #err("Entry not found") };
        };
    };
    
    // ================ STORAGE STATS ================
    public query({ caller }) func getStorageStats() : async Result.Result<Types.StorageStats, Text> {
        if (not _isWhitelisted(caller)) {
            return #err("Unauthorized: Caller not whitelisted");
        };
        
        let stats : Types.StorageStats = {
            totalAuditLogs = Trie.size(auditEntries);
            totalSystemEvents = Trie.size(systemEvents);
            totalUserActivities = 0; // Simplified for now
            totalSystemConfigs = 0; // Simplified for now
            whitelistedCanisters = Trie.size(whitelistTrie);
        };
        
        #ok(stats)
    };
    
    // ================ STANDARDIZED HEALTH CHECK INTERFACE ================
    
    // Standard health check function - ALL microservices must implement this
    public func healthCheck() : async Bool {
        // Audit storage is healthy if it can respond and has basic functionality
        let canAcceptRequests = true;
        let hasWhitelist = Trie.size(whitelistTrie) > 0;
        
        canAcceptRequests
    };
    
    // Extended health information - optional but recommended  
    public query func getHealthInfo() : async {
        isHealthy: Bool;
        version: Text;
        uptime: Nat;
        lastActivity: ?Time.Time;
        resourceUsage: {
            totalAuditLogs: Nat;
            totalSystemEvents: Nat;
            whitelistedCanisters: Nat;
            memoryUsage: Nat;
        };
        capabilities: [Text];
        status: Text;
    } {
        let currentTime = Time.now();
        let uptime = Int.abs(currentTime - serviceStartTime);
        let isHealthy = true; // Audit storage is generally always healthy if responding
        
        {
            isHealthy = isHealthy;
            version = SERVICE_VERSION;
            uptime = Int.abs(uptime);
            lastActivity = null; // Could track last audit log
            resourceUsage = {
                totalAuditLogs = Trie.size(auditEntries);
                totalSystemEvents = Trie.size(systemEvents);
                whitelistedCanisters = Trie.size(whitelistTrie);
                memoryUsage = 0; // Placeholder
            };
            capabilities = ["logAuditEntry", "getAuditLogs", "healthCheck", "getStorageStats"];
            status = if (isHealthy) "healthy" else "degraded";
        }
    };
    
    // Service info for discovery
    public query func getServiceInfo() : async {
        name: Text;
        version: Text;
        description: Text;
        endpoints: [Text];
        maintainer: Text;
    } {
        {
            name = "AuditStorage";
            version = SERVICE_VERSION;
            description = "ICTO V2 Centralized audit logging and system event storage";
            endpoints = ["logAuditEntry", "getAuditLogs", "healthCheck", "getHealthInfo", "getServiceInfo"];
            maintainer = "ICTO Development Team";
        }
    };
} 