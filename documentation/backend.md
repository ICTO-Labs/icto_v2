# Backend Structure

## Introduction

The backend of ICTO v2 is a sophisticated multi-canister system written in **Motoko**. It follows a modular, microservices-like architecture where each major piece of functionality is encapsulated in its own canister. This design enhances scalability, maintainability, and the ability to upgrade components independently.

The core of the backend is the main `backend` canister, which acts as an orchestrator or a pipeline executor. It receives requests from the frontend, processes payments, logs actions, and then dispatches the core task to the appropriate specialized canister.

## Folder Structure and Naming Conventions

The Motoko source code is organized within the `src/motoko/` directory. The structure is as follows:

```
src/motoko/
├── backend/
│   ├── main.mo                 # Main backend actor, entrypoint, and orchestrator
│   ├── modules/
│   │   ├── systems/            # Core system modules (config, audit, user, etc.)
│   │   └── ...                 # Business logic modules (token_deployer, etc.)
│   └── shared/                 # Shared types and utilities
├── token_deployer/
│   ├── main.mo                 # Actor for the token deployer canister
│   └── templates/              # Motoko templates for different token types
├── launchpad_deployer/
│   └── main.mo
├── distribution_deployer/
│   └── main.mo
├── invoice_storage/
│   └── main.mo
├── audit_storage/
│   └── main.mo
└── shared/
    ├── types/
    └── utils/
```

- **`backend/`**: Contains the central orchestrator canister.
- **`backend/modules/`**: Houses the various services that the main backend canister uses. These are not separate canisters but logical modules within the main backend.
  - **`systems/`**: Manages core functionalities like configuration (`ConfigService`), auditing (`AuditService`), user management (`UserService`), and payments (`PaymentService`).
  - Other directories in `modules/` contain the logic for interacting with the deployer canisters.
- **`*_deployer/`**: Each of these directories corresponds to a separate canister responsible for a specific deployment type (e.g., `token_deployer`, `launchpad_deployer`).
- **`*_storage/`**: Canisters dedicated to storing data, such as `invoice_storage` and `audit_storage`.
- **`shared/`**: Contains common `types` and `utils` that are used across multiple canisters.

## Backend Architecture: Multi-Canister Structure

The backend is not a single canister but a collection of canisters that work together.

- **Entrypoint (`backend/main.mo`)**: All user-facing requests are initially handled by the main `backend` canister. This canister is responsible for authentication, authorization, and initial validation.
- **Dispatchers**: After initial processing, the `backend` canister dispatches the request to the appropriate service canister. For example, a request to deploy a new token is forwarded to the `token_deployer` canister.
- **Service Canisters**: These are specialized canisters that perform a single, well-defined task. Examples include:
  - `token_deployer`: Creates and deploys new ICRC tokens.
  - `launchpad_deployer`: Deploys and configures launchpad canisters for projects.
  - `distribution_deployer`: Manages the logic for token distribution events.
  - `invoice_storage`: A simple storage canister for financial records.
  - `audit_storage`: A dedicated canister for storing immutable audit logs.

### Communication Flow

Inter-canister communication is fundamental to the ICTO v2 backend. The `backend` canister communicates with the service canisters using asynchronous `await` calls.

**Example:** When `deployToken` is called on the `backend` canister, it doesn't create the token itself. Instead, it makes an inter-canister call to the `deployTokenWithConfig` function on the `token_deployer` canister.

```motoko
// Inside backend/main.mo's _handleStandardDeploymentFlow

let deployerActor = actor (Principal.toText(call.canisterId)) : actor {
    deployTokenWithConfig : (
        TokenDeployerTypes.TokenConfig,
        TokenDeployerTypes.DeploymentConfig,
        ?Principal,
    ) -> async Result.Result<Principal, TokenDeployerTypes.DeploymentError>;
};
let result = await deployerActor.deployTokenWithConfig(call.args.config, call.args.deploymentConfig, null);
```

### Serialization Format

All data passed between canisters is serialized using **Candid**, the native serialization format of the Internet Computer. Candid ensures that data is strongly typed and can be correctly interpreted by different canisters, even if they are written in different languages.

## The Pipeline Executor System

A key architectural pattern in ICTO v2 is the standardized pipeline for handling deployment actions. This is encapsulated in the `_handleStandardDeploymentFlow` private function within the `backend` canister. This function ensures that every deployment, regardless of its type, follows the same sequence of steps, providing consistency and robustness.

The pipeline is designed with idempotency and resumability in mind.

### Pipeline Steps:

1.  **Authorization & Pre-flight Checks**: Verifies that the user is authenticated and authorized to perform the action.
2.  **Payment Processing**:
    - It calls the `PaymentService` to validate that the user has approved the necessary fee payment (using ICRC-2 `icrc2_approve`).
    - It then transfers the fee from the user's account to the project's fee recipient address using `icrc2_transfer_from`.
3.  **Audit Logging (Initiated)**: An audit log is created to record the start of the action. This is crucial for tracking and debugging. The log is stored in the `audit_storage` canister for immutability.
4.  **Dispatch to Deployer**: The request is dispatched to the appropriate specialized deployer canister (e.g., `token_deployer`).
5.  **Process Result**:
    - **On Success**: The audit log is updated to `Completed`, and the canister ID of the newly created canister is returned to the user.
    - **On Failure**: The audit log is updated to `Failed`. A refund process is initiated via the `PaymentService` to return the fee to the user.

This pipeline ensures that even if a step fails, the system remains in a consistent state. For example, if the token deployment fails after the fee has been paid, the fee is automatically refunded.

## Fee Validator Logic

The `PaymentService` module is responsible for handling all payment-related logic.

- **Fee Configuration**: Service fees are configurable via the `ConfigService`. An admin can set the fee for each type of deployment (e.g., `token_deployer.fee`).
- **Payment Validation**: Before executing a paid action, the frontend calls `checkPaymentApprovalForAction`. The backend checks if the user has an active ICRC-2 approval for the required fee amount.
- **Payment Execution**: The `_handleStandardDeploymentFlow` function executes the payment by calling `icrc2_transfer_from` on the appropriate ICRC token canister (e.g., ICP).
- **Refunds**: If an operation fails after payment, the `PaymentService` creates a `RefundRequest`. An admin can then approve this request to process the refund.

Initially, all fees are paid in **ICP**. The architecture is designed to support other ICRC-compliant tokens in the future, potentially including an ICTO token.
