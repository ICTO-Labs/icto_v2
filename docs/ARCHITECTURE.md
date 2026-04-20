# ICTO V2 - System Architecture

**Version:** 2.1
**Last Updated:** 2025-11-17
**Status:** Official

---

## 1. Executive Summary

ICTO V2 implements a **factory-first, decentralized architecture** where a lean backend gateway coordinates with autonomous factory canisters. This transformation from a monolithic V1 delivers a ~95% reduction in backend storage, ~60% faster load times, and highly performant O(1) data queries.

### Key Achievements

- ✅ **Distributed Architecture**: Each factory manages its own data and contracts.
- ✅ **Lean Gateway**: The backend acts as a coordinator and payment processor, not a data monolith.
- ✅ **O(1) Lookups**: Frontend queries data directly from factories for instant user data retrieval.
- ✅ **Scalable Design**: Eliminates the single point of failure and performance bottlenecks of V1.
- ✅ **Specialized Storage**: Dedicated canisters for immutable audit trails and financial records enhance security and compliance.

---

## 2. Architecture Overview

### Before: Centralized Monolith (V1)

In the previous version, a single backend canister was responsible for everything: storing all user and contract data, processing all queries, and managing all business logic.

```
┌─────────────────────────────────────────────────────────────────┐
│                     Backend (Centralized)                        │
│  - Stores ALL user relationships (1.05 GB+)                      │
│  - Processes ALL queries via slow O(n) iteration                 │
│  - Single point of failure and performance bottleneck            │
└────────────┬────────────────────────────────────────────────────┘
             │ Manages everything
             │
    ┌────────┴─────────┬─────────────┬─────────────┐
    │                  │             │             │
    ▼                  ▼             ▼             ▼
Distributions      Multisig         Tokens        DAOs
```

This led to significant scalability issues, slow dashboard load times (3-4 seconds), and high operational costs.

### After: Factory-First & Decentralized (V2)

The V2 architecture fundamentally redesigns this relationship. The backend is now a lightweight gateway, and the core logic and data storage are delegated to specialized, autonomous canisters.

```
                               +-----------------------------+
                               |    Frontend Application     |
                               +--------------+--------------+
                                              |
      (Direct, Read-only O(1) Queries)        | (Write Operations via Payment Gateway)
                                              |
  +-------------------------------------------+------------------------------------------+
  |                                           |                                          |
  |             +-----------------------------v-----------------------------+            |
  |             |           Backend Gateway (Lean Coordinator)              |            |
  |             | - Payment Validation                                      |            |
  |             | - Deployment Coordination                                 |            |
  |             | - Internal Microservices (User, Config, Audit)            |            |
  |             | - FactoryRegistryService (Aggregates relationship data)   |            |
  |             +-----------------------------+-----------------------------+            |
  |                                           |              |                           |
  | (Callbacks to update indexes)             |              | (Delegated Storage)       |
  |                                           |              |                           |
  |               +---------------------------v--------------v-------------------------+ |
  |               | Autonomous Factories & Specialized Storage                       | |
  +------------>  | +------------------+  +------------------+   +------------------+  | |
                  | | TokenFactory     |  | MultisigFactory  |   | AuditStorage     |  | |
                  | +------------------+  +------------------+   +------------------+  | |
                  | | DistributionFact |  | DAOFactory       |   | InvoiceStorage   |  | |
                  | +------------------+  +------------------+   +------------------+  | |
                  +--------------------------------------------------------------------+

```
---

## 3. System Components

### 3.1. The Backend Gateway Canister

The backend is a **lean coordinator**, not a data store. Its primary responsibilities are refined into a set of internal microservices.

#### Internal Microservice Architecture

-   **`PaymentService`**: Acts as the single entry point for all paid operations. It validates ICRC-2 payments before any action is taken, ensuring a secure "payment gate".
-   **`UserService`**: Manages user profiles and, crucially, tracks canister **ownership** (i.e., which user created which contract).
-   **`ConfigService`**: Manages system-wide configurations like service fees and feature flags, providing a central point of control.
-   **`AuditService`**: Provides an internal API for other services to log events. It then forwards these logs to the `AuditStorage` canister, decoupling the logging action from the storage implementation.
-   **`FactoryRegistryService`**: This is a key component for user experience. It acts as a **centralized index for user-to-canister *relationships***. While factories manage their own data, they report relationship information (e.g., a user becoming a DAO member, a signer on a multisig wallet, or a recipient of a distribution) back to this service. This allows the frontend to fetch all of a user's cross-ecosystem relationships in a single, efficient query.

### 3.2. Specialized Storage Services

To maintain the backend's lean nature and enhance security, high-volume, critical data is delegated to independent canisters.

-   **`AuditStorage`**: An **immutable, append-only canister** that stores all audit trail events. Its separation ensures the audit log is tamper-proof and can be scaled independently.
-   **`InvoiceStorage`**: A dedicated canister for all financial records. This isolates sensitive payment data, improving security and simplifying compliance.

### 3.3. Autonomous Factory Canisters

Each factory is a self-contained, domain-specific service responsible for creating and managing its own contracts.

-   **Core Functions**:
    -   Deploy new smart contract instances from WASM templates.
    -   Maintain `O(1)` query indexes (using Tries) for data related to their contracts.
    -   Handle callbacks from their child contracts to keep indexes synchronized in real-time.
    -   Manage the versioning and upgrade path for their contracts.

-   **Factory-Specific Indexes**:
    -   **`DistributionFactory`**: Indexes recipients.
    -   **`MultisigFactory`**: Indexes signers and observers.
    -   **`DAOFactory`**: Indexes members.
    -   **`LaunchpadFactory`**: Indexes participants.

### 3.4. Contract Canisters

These are the individual instances (e.g., a specific DAO, a multisig wallet) deployed by the factories. They operate autonomously but maintain a crucial link to their parent factory via callbacks for state synchronization.

---

## 4. Data & Communication Flows

### Write Path: Deploying a New Contract

Write operations are sequential and secured by the backend's payment gate.

1.  **Frontend**: The user initiates a deployment request and approves the ICRC-2 payment.
2.  **Backend (`PaymentService`)**: Receives the request and validates the payment approval with the ICRC ledger.
3.  **Backend (`InvoiceStorage`)**: If payment is valid, the backend deducts the fee and records the transaction in the `InvoiceStorage` canister.
4.  **Backend (`AuditStorage`)**: The payment success event is logged to the `AuditStorage` canister.
5.  **Backend -> Factory**: The backend, now certain of payment, calls the `createContract` method on the appropriate whitelisted factory.
6.  **Factory**: The factory deploys the new contract, sets the owner, and updates its internal indexes (e.g., adds the owner to its `creatorIndex`).
7.  **Factory -> Backend**: The factory returns the Principal of the new contract to the backend.
8.  **Backend -> Frontend**: The backend confirms the successful deployment to the frontend.

### Read Path: Fetching User Data

Read operations are designed for maximum performance by bypassing the backend.

1.  **Frontend**: To build a user's dashboard, the frontend initiates multiple, parallel data requests.
2.  **Request 1 -> Factory**: It calls `getMyContracts` directly on a factory (e.g., `TokenFactory`) to get contracts the user owns. The factory performs an `O(1)` Trie lookup and returns the data instantly.
3.  **Request 2 -> Backend (`FactoryRegistryService`)**: It calls `getRelatedCanisters` on the backend to get all contracts the user has a *relationship* with across all factories (e.g., DAOs they are a member of, multisigs they can sign).
4.  **Frontend**: The frontend receives data from these parallel queries and assembles the complete user dashboard. This entire process is significantly faster (1-2 seconds) than the V1 model.

### State Sync Path: Callbacks

This flow ensures data remains synchronized between contracts and their parent factories.

1.  **Contract**: A state change occurs (e.g., a new member is added to a DAO).
2.  **Contract -> Factory**: The DAO contract executes a **callback** to its parent `DAOFactory`, calling the `notifyMemberAdded` function.
3.  **Factory**: The `DAOFactory` first authenticates the call, ensuring it came from one of its deployed child contracts. It then updates its `memberIndex` to include the new relationship. This ensures that the next time the new member's data is queried, the `DAOFactory` will correctly return their membership.

---

## 5. Security & Design Principles

-   **Payment Before Action**: No expensive operations are performed until payment is secured.
-   **Whitelist Security**: The backend and factories only communicate with whitelisted principals, preventing unauthorized calls.
-   **Callback Authentication**: Factories verify that callbacks are coming from legitimate child contracts they have deployed.
-   **Data Segregation**: The separation of logic (Backend), data (Factories), and logs (Storage Canisters) minimizes the attack surface area of any single component.
-   **Performance through Asymmetry**: The data flow is intentionally asymmetric—writes go through the backend for security, while reads go directly to factories for performance.

---

## 6. Related Documentation

-   **[ECOSYSTEM_OVERVIEW.md](./ECOSYSTEM_OVERVIEW.md)** - For a higher-level, less technical summary.
-   **[BACKEND_FACTORY_INTEGRATION.md](./BACKEND_FACTORY_INTEGRATION.md)** - For detailed API and integration patterns.
