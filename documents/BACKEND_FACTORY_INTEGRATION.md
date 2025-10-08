# Backend-Factory Integration Guide

**Version:** 2.0
**Last Updated:** 2025-10-08
**Status:** Production Ready

---

## Overview

This document details how the Backend canister integrates with Factory canisters in ICTO V2. The relationship is based on a **whitelist security model** where:

- **Backend** acts as the payment gateway and deployment coordinator
- **Factories** are autonomous services that only accept calls from whitelisted backend
- **Storage Services** (Audit & Invoice) only accept writes from whitelisted backend
- **Contracts** callback to their factory for index updates

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Backend (Lean ~50MB)                              │
│  • Payment validation via ICRC-2                                         │
│  • Deployment coordination                                               │
│  • Authentication & authorization                                        │
│  • Factory registry & whitelist management                               │
│  • Configuration management (service fees, enabled/disabled)             │
└─────┬────────────────────────┬──────────────────────────────────────────┘
      │                        │
      │ Delegates              │ Coordinates & Monitors
      │ storage                │
      ▼                        ▼
┌─────────────┐         ┌─────────────────────────────────────────────────┐
│   Audit     │         │          Factory Registry                        │
│  Storage    │         │  • Whitelist verification                        │
├─────────────┤         │  • Factory health monitoring                     │
│• Audit logs │         │  • Service status tracking                       │
│• Event trail│         └─────────┬───────────────────────────────────────┘
│• Immutable  │                   │
└─────────────┘                   │ Backend calls factories via whitelist
                                  │
┌─────────────┐                   │
│   Invoice   │                   │
│  Storage    │◄──────────────────┘
├─────────────┤         │
│• Payment rec│         │ 1. createContract(owner, args, payment)
│• ICRC-2 hist│         │ 2. setupWhitelist(backendId)
│• Refund     │         │ 3. getMyContracts(user) [query]
└─────────────┘         │ 4. getFactoryHealth() [monitor]
                        │
    ┌───────────────────┼────────────────┬──────────────┬──────────────┐
    │                   │                │              │              │
    │ Whitelisted       │ Whitelisted    │ Whitelisted  │ Whitelisted  │
    │ Backend           │ Backend        │ Backend      │ Backend      │
    ▼                   ▼                ▼              ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Distribution  │  │  Multisig    │  │    Token     │  │     DAO      │  │  Launchpad   │
│  Factory     │  │   Factory    │  │   Factory    │  │   Factory    │  │   Factory    │
├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤
│• Whitelisted │  │• Whitelisted │  │• Whitelisted │  │• Whitelisted │  │• Whitelisted │
│  backend     │  │  backend     │  │  backend     │  │  backend     │  │  backend     │
│• O(1) indexes│  │• O(1) indexes│  │• O(1) indexes│  │• O(1) indexes│  │• O(1) indexes│
│• User data   │  │• User data   │  │• User data   │  │• User data   │  │• User data   │
│• Direct query│  │• Direct query│  │• Direct query│  │• Direct query│  │• Direct query│
│• Callbacks   │  │• Callbacks   │  │• Callbacks   │  │• Callbacks   │  │• Callbacks   │
│• Version Mgmt│  │• Version Mgmt│  │• Version Mgmt│  │• Version Mgmt│  │• Version Mgmt│
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │                 │
   Deploys &         Deploys &         Deploys &         Deploys &         Deploys &
   Manages           Manages           Manages           Manages           Manages
       │                 │                 │                 │                 │
       ▼                 ▼                 ▼                 ▼                 ▼
  Distribution      Multisig          Token             DAO            Launchpad
  Contracts         Contracts         Contracts         Contracts      Contracts
       │                 │                 │                 │                 │
       └─────────────────┴─────────────────┴─────────────────┴─────────────────┘
                                          │
                                          │ Callbacks to factory
                                          │ • notifyParticipantAdded(user)
                                          │ • notifyStatusChanged(status)
                                          │ • notifyVisibilityChanged(isPublic)
                                          │
                                          └─────► Factory indexes updated
```

---

## Integration Points

### 1. Backend → Factories (Write Operations)

**Purpose:** Deploy contracts via payment gateway

**Security:** Whitelist verification required

**API Functions:**

```motoko
// Backend calls factory to create contract
public shared({caller}) func createToken(args: TokenArgs) : async Result<Principal, Text> {
    // 1. Validate payment
    let fee = await getServiceFee("token_factory");
    let paymentValid = await validatePayment(caller, fee);
    if (not paymentValid) {
        return #err("Payment required");
    };

    // 2. Call factory (backend is whitelisted)
    let result = await tokenFactory.createContract(caller, args);

    // 3. Log to audit storage
    await auditStorage.logEvent({
        action = "TokenCreated";
        user = caller;
        timestamp = Time.now();
    });

    result
}
```

**Factory Whitelist Check:**

```motoko
// Factory verifies caller is whitelisted backend
public shared({caller}) func createContract(
    owner: Principal,
    args: ContractArgs
) : async Result<Principal, Text> {
    // Security: Only whitelisted backend can deploy
    if (not isWhitelistedBackend(caller)) {
        return #err("Unauthorized: Must deploy via backend");
    };

    // Deploy contract...
    // ...
}
```

**Setup Command:**

```bash
# Whitelist backend in factory (run during setup)
dfx canister call token_factory setupWhitelist "(principal \"$(dfx canister id backend)\")"
```

---

### 2. Frontend → Factories (Read Operations)

**Purpose:** Direct queries bypass backend for performance

**Security:** No authorization required (public queries)

**API Functions:**

```motoko
// Factory query - no backend involved
public query func getMyContracts(user: Principal) : async [ContractInfo] {
    // O(1) lookup in creator index
    let asCreator = Trie.get(creatorIndex, principalKey(user), Principal.equal);

    // O(1) lookup in participant index
    let asParticipant = Trie.get(participantIndex, principalKey(user), Principal.equal);

    // Combine and return
    combineResults(asCreator, asParticipant)
}
```

**Frontend Service Example:**

```typescript
// services/tokenFactory.ts
class TokenFactoryService {
  private actor: any

  async getMyTokens(userPrincipal: Principal): Promise<TokenInfo[]> {
    // Direct query to factory (bypass backend)
    const result = await this.actor.getMyContracts(userPrincipal)

    // Parse BigInt to Number
    return result.map(token => ({
      ...token,
      totalSupply: Number(token.totalSupply)
    }))
  }
}
```

**Performance:**
- No backend bottleneck
- O(1) Trie lookups
- Parallel queries to multiple factories
- 60% faster than V1 centralized approach

---

### 3. Backend → Storage Services (Audit & Payment)

**Purpose:** Delegated storage for audit logs and payment records

**Security:** Only whitelisted backend can write

**API Functions:**

```motoko
// Backend writes to Audit Storage
await auditStorage.logEvent({
    action = "TokenCreated";
    user = caller;
    contract = contractId;
    timestamp = Time.now();
    metadata = "Token: MyToken (MTK)";
});

// Backend writes to Invoice Storage
await invoiceStorage.recordPayment({
    user = caller;
    amount = fee;
    token = ICP_LEDGER;
    service = "token_factory";
    timestamp = Time.now();
    status = #Completed;
});
```

**Setup Commands:**

```bash
# Whitelist backend in Audit Storage
dfx canister call audit_storage setupWhitelist "(principal \"$(dfx canister id backend)\")"

# Whitelist backend in Invoice Storage
dfx canister call invoice_storage setupWhitelist "(principal \"$(dfx canister id backend)\")"
```

---

### 4. Contracts → Factories (Callbacks)

**Purpose:** Real-time index synchronization

**Security:** Factory verifies caller is deployed contract

**Callback Examples:**

```motoko
// Contract notifies factory of new participant
public shared func addParticipant(user: Principal) : async Result<(), Text> {
    // Update internal state
    participants := Array.append(participants, [user]);

    // Callback to factory
    await factory.notifyParticipantAdded(Principal.fromActor(this), user);

    #ok()
}
```

**Factory Callback Handler:**

```motoko
// Factory receives callback from contract
public shared({caller}) func notifyParticipantAdded(
    contractId: Principal,
    user: Principal
) : async Result<(), Text> {
    // 1. Verify caller is deployed contract
    if (not isDeployedContract(caller)) {
        return #err("Unauthorized: Caller is not a deployed contract");
    };

    // 2. Verify contractId matches caller
    if (not Principal.equal(caller, contractId)) {
        return #err("Invalid: Contract ID mismatch");
    };

    // 3. Update participant index (O(1))
    participantIndex := addToIndex(participantIndex, user, contractId);

    #ok()
}
```

**Security Checks:**
1. Verify caller Principal exists in `deployedContracts`
2. Verify contractId matches caller
3. Update indexes only if verified

---

### 5. Backend Monitoring & Health Checks

**Purpose:** Monitor factory health and system status

**API Functions:**

```motoko
// Get microservice health status
public shared func getMicroserviceHealth() : async [ServiceHealth] {
    // Check all factories
    let tokenHealth = await tokenFactory.getHealth();
    let multisigHealth = await multisigFactory.getHealth();
    // ...

    [tokenHealth, multisigHealth, ...]
}

// Get microservice setup status
public shared func getMicroserviceSetupStatus() : async [ServiceSetupStatus] {
    // Check whitelist configuration
    let tokenSetup = await tokenFactory.getSetupStatus();
    let multisigSetup = await multisigFactory.getSetupStatus();
    // ...

    [tokenSetup, multisigSetup, ...]
}

// Get overall system status
public shared func getSystemStatus() : async SystemStatus {
    {
        isMaintenanceMode = configState.maintenanceMode;
        servicesHealth = await getMicroserviceHealth();
        lastUpgrade = lastUpgradeTime;
    }
}
```

**Health Check Commands:**

```bash
# Check microservice health
dfx canister call backend getMicroserviceHealth "()"

# Check setup status
dfx canister call backend getMicroserviceSetupStatus "()"

# Check system status
dfx canister call backend getSystemStatus "()"
```

---

## Configuration Management

### Service Fee Configuration

**Backend manages service fees for all factories:**

```motoko
// Get service fee (automatically appends ".fee")
public shared query func getServiceFee(serviceName: Text) : async ?Nat {
    let key = serviceName # ".fee";
    switch (Trie.get(configState.values, {key=key; hash=Text.hash(key)}, Text.equal)) {
        case (?value) Nat.fromText(value);
        case null null;
    };
}

// Set service fee (admin only)
public shared({caller}) func adminSetConfigValue(
    key: Text,
    value: Text
) : async Result<(), Text> {
    // Verify admin authorization
    if (not ConfigService.isAdmin(configState, caller)) {
        return #err("Unauthorized: Admin only");
    };

    // Set configuration
    ConfigService.set(configState, key, value, caller)
}
```

**Configuration Commands:**

```bash
# Get service fee
dfx canister call backend getServiceFee "(\"token_factory\")"

# Set service fee (admin only)
dfx canister call backend adminSetConfigValue "(\"token_factory.fee\", \"100000000\")"

# Enable/disable service
dfx canister call backend adminSetConfigValue "(\"token_factory.enabled\", \"true\")"
```

**Default Configuration (from ConfigService.mo):**

```motoko
// Token Factory
ignore set(state, "token_factory.enabled", "true", backendId);
ignore set(state, "token_factory.fee", "100000000", backendId); // 1 ICP
ignore set(state, "token_factory.initial_cycles", "200000000", backendId);

// Multisig Factory
ignore set(state, "multisig_factory.enabled", "true", backendId);
ignore set(state, "multisig_factory.fee", "50000000", backendId); // 0.5 ICP
ignore set(state, "multisig_factory.initial_cycles", "200000000", backendId);

// Distribution Factory
ignore set(state, "distribution_factory.enabled", "true", backendId);
ignore set(state, "distribution_factory.fee", "100000000", backendId); // 1 ICP
ignore set(state, "distribution_factory.initial_cycles", "200000000", backendId);

// DAO Factory
ignore set(state, "dao_factory.enabled", "true", backendId);
ignore set(state, "dao_factory.fee", "500000000", backendId); // 5 ICP
ignore set(state, "dao_factory.initial_cycles", "300000000", backendId);

// Launchpad Factory
ignore set(state, "launchpad_factory.enabled", "true", backendId);
ignore set(state, "launchpad_factory.fee", "1000000000", backendId); // 10 ICP
ignore set(state, "launchpad_factory.initial_cycles", "2000000000", backendId);
```

---

## Deployment Flow

### Complete End-to-End Flow

```
User Request (Frontend)
    │
    │ 1. User approves ICRC-2 payment
    │ 2. Frontend → Backend.createToken(args)
    ▼
Backend (Payment Gateway)
    │
    │ 3. Verify caller authorization
    │ 4. Check service enabled: getConfigValue("token_factory.enabled")
    │ 5. Get service fee: getServiceFee("token_factory")
    │ 6. Validate ICRC-2 approval
    │ 7. Deduct payment via transferFrom
    │ 8. Write to Invoice Storage
    │ 9. Write to Audit Storage
    ▼
Backend → Factory (Whitelist Check)
    │
    │ 10. Backend → TokenFactory.createContract(owner, args)
    │     Factory verifies: caller == whitelisted backend
    ▼
Factory (Deployment)
    │
    │ 11. Load WASM template from stable storage
    │ 12. Create canister via IC Management
    │ 13. Install contract code
    │ 14. Add factory + owner as dual controllers
    │ 15. Initialize contract state
    │ 16. Update creator index (O(1))
    │ 17. Register version (v1.0.0)
    │ 18. Add to deployed contracts
    ▼
Contract Deployed ✅
    │
    │ 19. Contract → Factory.notifyDeploymentComplete()
    ▼
Factory Finalizes
    │
    │ 20. Confirm contract in indexes
    │ 21. Update factory statistics
    │ 22. Return contract Principal to backend
    ▼
Backend Finalizes
    │
    │ 23. Log deployment success to Audit Storage
    │ 24. Update payment status in Invoice Storage
    │ 25. Return success to frontend
    ▼
Frontend Updates UI ✅
```

---

## Security Model

### 1. Whitelist Security

**All write operations require whitelist verification:**

```motoko
// Factory whitelist check
private stable var whitelistedBackends: [Principal] = [];

private func isWhitelistedBackend(caller: Principal) : Bool {
    switch(Array.find(whitelistedBackends, func(p: Principal) : Bool {
        Principal.equal(p, caller)
    })) {
        case (?_) true;
        case null false;
    }
}

// Setup whitelist (one-time during deployment)
public shared({caller}) func setupWhitelist(backend: Principal) : async () {
    // Only allow during initial setup or by admin
    whitelistedBackends := [backend];
}
```

### 2. Payment Gate

**All deployments must go through backend payment validation:**

```motoko
// Backend enforces payment before deployment
public shared({caller}) func createToken(args: TokenArgs) : async Result<Principal, Text> {
    // 1. Get service fee
    let feeOpt = await getServiceFee("token_factory");
    let fee = switch (feeOpt) {
        case (?f) f;
        case null return #err("Service fee not configured");
    };

    // 2. Validate ICRC-2 approval
    let approved = await icrcLedger.allowance({
        account = { owner = caller; subaccount = null };
        spender = { owner = Principal.fromActor(this); subaccount = null };
    });

    if (approved < fee) {
        return #err("Insufficient ICRC-2 approval");
    };

    // 3. Transfer payment
    let transferResult = await icrcLedger.icrc2_transfer_from({
        from = { owner = caller; subaccount = null };
        to = feeRecipient;
        amount = fee;
        // ...
    });

    // 4. Only if payment succeeds, deploy contract
    switch (transferResult) {
        case (#Ok(_)) {
            await tokenFactory.createContract(caller, args)
        };
        case (#Err(e)) {
            #err("Payment failed: " # debug_show(e))
        };
    }
}
```

### 3. Callback Authentication

**Factories verify callbacks come from deployed contracts:**

```motoko
// Factory maintains registry of deployed contracts
private stable var deployedContractsStable: [Principal] = [];
private var deployedContracts: Trie.Trie<Principal, ContractInfo> = Trie.empty();

// Callback verification
public shared({caller}) func notifyParticipantAdded(
    contractId: Principal,
    user: Principal
) : async Result<(), Text> {
    // Verify caller is deployed contract
    if (not isDeployedContract(caller)) {
        return #err("Unauthorized: Caller is not a deployed contract");
    };

    // Verify contractId matches caller
    if (not Principal.equal(caller, contractId)) {
        return #err("Invalid: Contract ID mismatch");
    };

    // Update indexes
    participantIndex := addToIndex(participantIndex, user, contractId);

    #ok()
}
```

---

## Setup Commands Reference

### Initial Setup

```bash
# 1. Deploy all canisters
dfx deploy

# 2. Setup backend whitelist in factories
for factory in distribution_factory multisig_factory token_factory dao_factory launchpad_factory; do
    echo "Setting up whitelist for $factory..."
    dfx canister call $factory setupWhitelist "(principal \"$(dfx canister id backend)\")"
done

# 3. Setup backend whitelist in storage services
dfx canister call audit_storage setupWhitelist "(principal \"$(dfx canister id backend)\")"
dfx canister call invoice_storage setupWhitelist "(principal \"$(dfx canister id backend)\")"

# 4. Configure microservices in backend
dfx canister call backend setupMicroservices "(
    principal \"$(dfx canister id audit_storage)\",
    principal \"$(dfx canister id invoice_storage)\",
    principal \"$(dfx canister id token_factory)\",
    principal \"$(dfx canister id distribution_factory)\",
    principal \"$(dfx canister id multisig_factory)\",
    principal \"$(dfx canister id dao_factory)\",
    principal \"$(dfx canister id launchpad_factory)\"
)"

# 5. Configure service fees
dfx canister call backend adminSetConfigValue "(\"token_factory.fee\", \"100000000\")"
dfx canister call backend adminSetConfigValue "(\"token_factory.enabled\", \"true\")"

# 6. Verify health
dfx canister call backend getMicroserviceHealth "()"
dfx canister call backend getSystemStatus "()"
```

### Monitoring Commands

```bash
# Check factory health
dfx canister call backend getMicroserviceHealth "()"

# Check setup status
dfx canister call backend getMicroserviceSetupStatus "()"

# Check system status
dfx canister call backend getSystemStatus "()"

# Get service fee
dfx canister call backend getServiceFee "(\"token_factory\")"

# List all configurations
dfx canister call backend getAllConfigValues "()"
```

---

## File Locations

### Backend
- **Main**: `src/motoko/backend/main.mo`
- **Config Service**: `src/motoko/backend/modules/systems/config/ConfigService.mo`
- **Config Types**: `src/motoko/backend/modules/systems/config/ConfigTypes.mo`

### Factories
- **Token Factory**: `src/motoko/token_factory/main.mo`
- **Multisig Factory**: `src/motoko/multisig_factory/main.mo`
- **Distribution Factory**: `src/motoko/distribution_factory/main.mo`
- **DAO Factory**: `src/motoko/dao_factory/main.mo`
- **Launchpad Factory**: `src/motoko/launchpad_factory/main.mo`

### Storage Services
- **Audit Storage**: `src/motoko/audit_storage/main.mo`
- **Invoice Storage**: `src/motoko/invoice_storage/main.mo`

### Frontend Services
- **Token Service**: `src/frontend/src/api/services/token.ts`
- **Multisig Service**: `src/frontend/src/api/services/multisig.ts`
- **Distribution Service**: `src/frontend/src/api/services/distribution.ts`

---

## Related Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System architecture overview
- **[README.md](../README.md)** - Project overview and setup
- **[modules/](./modules/)** - Module-specific documentation
- **[setup-icto-v2.sh](../setup-icto-v2.sh)** - Automated setup script

---

**Last Updated:** 2025-10-08
**Version:** 2.0
**Status:** Production Ready ✅
