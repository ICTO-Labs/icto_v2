# Launchpad Pipeline Integration Guide

This document provides a comprehensive guide to the Launchpad Pipeline architecture, execution flow, and integration details for the ICTO v2 platform. It serves as a reference for developers and community members understanding the launchpad's lifecycle.

## 1. Overview

The Launchpad Pipeline is a robust, step-by-step mechanism that handles the transition of a project from a successful sale to a fully deployed and functional ecosystem. It ensures atomicity, idempotency, and auditability of all critical operations.

### Key Features
*   **Modular Architecture**: Each step is an independent executor.
*   **Idempotency**: Steps can be safely retried without side effects.
*   **Financial Tracking**: All financial movements (fees, liquidity, refunds) are recorded.
*   **Fail-Safe**: The system defaults to a safe state on errors.

## 2. Pipeline Architecture

The pipeline is managed by `PipelineManager.mo` and consists of the following sequential stages:

1.  **Token Deployment**: Deploys the project's sale token (if not already existing).
2.  **Distribution Setup**: Deploys the Distribution canister and sets up vesting schedules.
3.  **DAO Deployment**: Deploys the DAO governance canister (if enabled).
4.  **Liquidity Setup**: Creates liquidity pools on DEXs (ICPSwap, KongSwap).
5.  **Fee Processing**: Calculates and transfers platform fees.
6.  **Final Cleanup**: Updates status and enables claiming.

## 3. Execution Flow & Parameters

### Step 1: Token Deployment
*   **Goal**: Ensure the project token exists and is ready for distribution.
*   **Input**: `LaunchpadConfig.saleToken`
*   **Action**: Deploys an ICRC-1/ICRC-2 compatible token canister.
*   **Output**: `canisterId` of the deployed token.

### Step 2: Distribution Setup
*   **Goal**: Set up the mechanism for users to claim their tokens.
*   **Input**: `LaunchpadConfig.tokenDistribution` (V2) or `distribution` (V1).
*   **Action**:
    *   Deploys `DistributionContract`.
    *   Transfers total allocated tokens to the Distribution canister.
    *   Configures vesting schedules.
*   **Output**: `canisterId` of the Distribution contract.

### Step 3: DAO Deployment (Optional)
*   **Goal**: Establish decentralized governance.
*   **Input**: `LaunchpadConfig.governanceConfig`.
*   **Action**: Deploys `DAOContract` with initial parameters.
*   **Output**: `canisterId` of the DAO.

### Step 4: Liquidity Setup (DEX Integration)
*   **Goal**: Create trading markets for the token.
*   **Input**: `LaunchpadConfig.dexConfig` and `LaunchpadConfig.multiDexConfig`.
*   **Supported Platforms**:
    *   **ICPSwap**: Concentrated Liquidity.
    *   **KongSwap**: Constant Product Formula.
*   **Process**:
    1.  Calculates token and ICP amounts based on `liquidityFund` allocation.
    2.  Approves DEX contracts to spend tokens.
    3.  Calls DEX APIs to create pools/positions.
    4.  Verifies liquidity creation.
*   **Verification**:
    *   **ICPSwap**: Checks `metadata().sqrtPriceX96 > 0`.
    *   **KongSwap**: Optimistic verification via `add_pool` success response.

### Step 5: Fee Processing
*   **Goal**: Collect platform fees.
*   **Input**: `totalRaised` and `LaunchpadConfig.platformFeeRate`.
*   **Action**:
    *   Calculates fee: `totalRaised * feeRate / 100`.
    *   Transfers fee to `backendPrincipal` (Factory).
    *   Records transaction as `#FeePayment`.

## 4. Configuration Parameters

### LaunchpadConfig
The core configuration object defining the launchpad behavior.

```motoko
public type LaunchpadConfig = {
    // ... project info ...
    
    // Fee Structure
    platformFeeRate: Nat8;        // Platform fee percentage (0-100)
    successFeeRate: Nat8;         // Additional fee on successful launch
    
    // DEX Integration
    dexConfig: DEXConfig;         // Primary DEX config
    multiDexConfig: ?MultiDEXConfig; // Multi-DEX support
    
    // ... other configs ...
};
```

### DEXConfig
```motoko
public type DEXConfig = {
    enabled: Bool;
    platform: Text;               // "ICPSwap", "KongSwap"
    listingPrice: Nat;            // Initial price in e8s
    totalLiquidityToken: Nat;     // Tokens allocated for liquidity
    initialLiquidityPurchase: Nat;// ICP allocated for liquidity
    // ...
};
```

## 5. Developer Reference

### Interfaces

#### ICPSwap Pool
```motoko
public type ICPSwapPool = actor {
    deposit: (args: ICPSwapDepositArgs) -> async ICPSwapResult;
    depositFrom: (args: ICPSwapDepositArgs) -> async ICPSwapResult;
    metadata: () -> async ICPSwapMetadataResult;
    mint: (args: ICPSwapMintArgs) -> async ICPSwapResult;
};
```

#### KongSwap Backend
```motoko
public type KongSwapBackend = actor {
    add_pool: (args: KongSwapAddPoolArgs) -> async KongSwapAddPoolReply;
};
```

### Financial Records
All pipeline steps return financial records for auditing:

```motoko
public type FinancialRecord = {
    txType: FinancialTxType; // #FeePayment, #LiquidityProvision, etc.
    amount: Nat;
    from: Principal;
    to: Principal;
    blockIndex: ?Nat;
    timestamp: Time.Time;
    status: FinancialTxStatus;
    executionId: ExecutionId;
};
```

## 6. Future Improvements
*   **Dynamic DEX Loading**: Support adding new DEX adapters without code changes.
*   **Advanced Vesting**: More complex vesting curves (e.g., exponential).
*   **Cross-Chain Liquidity**: Integration with Bitcoin/Ethereum bridges.
