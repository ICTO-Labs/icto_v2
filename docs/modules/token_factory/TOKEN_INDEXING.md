# Token Indexing and ICRC-3 Index Canister Integration

## Overview

The Token Factory supports automatic integration with ICRC-3 Index Canisters to enable efficient transaction querying. This document explains how token indexing works and how to use it.

## What is Token Indexing?

Token indexing is a feature that allows tokens to automatically track and reference an associated ICRC-3 Index Canister. This enables:

- **Efficient Transaction Queries** - Query transactions directly from the index canister instead of the ledger
- **Account-Specific Transactions** - Retrieve transactions for specific accounts O(1)
- **Reduced Ledger Queries** - Index canisters handle account-specific queries, reducing load on the token ledger
- **Better UX** - Faster transaction history loading in frontends

## Fields

### TokenInfo (Token Factory Storage)

When a token is deployed, the following fields track indexing:

```motoko
type TokenInfo = {
  // ... other fields
  enableIndex: bool;              // Whether indexing is enabled for this token
  indexCanisterId: ?Principal;    // The associated ICRC-3 Index Canister ID
  launchpadId: ?Principal;        // Optional: Associated launchpad ID
};
```

### TokenConfig (Deployment Configuration)

When deploying a new token, you can configure:

```motoko
type TokenConfig = {
  // ... other fields
  enableIndex: ?bool;             // Set to [true] to enable indexing
  launchpadId: ?Principal;        // Optional: Launchpad that created this token
};
```

## Deployment

### Enabling Index Canister Support

When deploying a token via the frontend:

1. **Optional**: Check "Enable Index Canister" in the deployment form
2. This sets `enableIndex = true` in the token configuration
3. The token_factory stores this setting in TokenInfo

**Example Frontend Usage:**
```typescript
const deploymentRequest = {
  config: {
    name: "My Token",
    symbol: "MTK",
    // ... other config
    enableIndex: [true]  // Enable indexing
  },
  // ... other fields
};
```

### Updating Index Canister Reference

After a token is deployed, you can update its index canister reference using:

```bash
dfx canister call token_factory updateTokenIndexCanister "(
  principal \"<token-canister-id>\",
  principal \"<index-canister-id>\"
)"
```

This function:
- Updates the token's `indexCanisterId` field
- Can only be called by backend or token owner
- Persists the index canister reference for future queries

## Frontend Integration

### Automatic Detection

The frontend automatically detects and uses the index canister:

1. **TokenTransactions.vue** loads token info from token_factory
2. Checks if `indexCanisterId` is set
3. **If index exists**: Uses IcrcIndexService for queries (ICRC-3 Index Canister)
4. **If no index**: Falls back to IcrcService for queries (Token Ledger Canister)
5. Displays transaction source badge: "Source: Index" or "Source: Ledger"

### Transaction Source Badge

Transactions display a source indicator:
```
Source: Index    # Loaded from ICRC-3 Index Canister (fast)
Source: Ledger   # Loaded from token ledger (fallback)
```

### Example Component Usage

```typescript
// TokenTransactions.vue
const loadTransactions = async () => {
  // Load token info from token_factory
  const tokenInfo = await tokenFactoryService.getTokenInfo(
    Principal.fromText(canisterId.value)
  );

  // Check if index canister is available
  if (tokenInfo?.indexCanisterId?.[0]) {
    // Use Index Canister (efficient account-specific queries)
    const transactions = await IcrcIndexService.getAllAccountTransactions(
      indexCanisterId.value
    );
    transactionSource.value = 'Index';
  } else {
    // Fallback to Ledger Canister
    const result = await IcrcService.getTransactions(canisterId.value, ...);
    transactionSource.value = 'Ledger';
  }
};
```

## ICRC-3 Index Canister Format

The frontend expects the ICRC-3 Index Canister to implement methods like:

```candid
service : {
  get_account_transactions : (GetAccountTransactionsRequest) -> (GetTransactionsResponse) query;
  // ... other methods
}
```

The index canister returns transactions in ICRC-3 format, which the frontend converts to the internal TransactionRecord format.

## Benefits

### For Users
- ✅ Faster transaction history loading
- ✅ Better pagination support
- ✅ Account-specific transaction queries
- ✅ Reduced blockchain queries

### For Developers
- ✅ Automatic detection and routing
- ✅ Graceful fallback to ledger if index unavailable
- ✅ Clear transaction source indication
- ✅ Standard ICRC-3 Index format

### For Scalability
- ✅ Distributes query load
- ✅ Reduces ledger canister load
- ✅ Enables specialized indexing canisters
- ✅ Supports future index implementations

## Common Workflows

### Deploying a Token with Index Support

1. Deploy token with `enableIndex: [true]`
2. After deployment, note the token canister ID
3. Deploy an ICRC-3 Index Canister for the token
4. Call `updateTokenIndexCanister()` with both IDs
5. Index canister is now active and queries will use it

### Checking Token Index Status

```bash
# Get token info including index canister ID
dfx canister call token_factory getToken "(principal \"<token-id>\")"

# Output includes:
# enableIndex: true
# indexCanisterId: opt principal "<index-canister-id>"
```

### Disabling Index Usage

Currently, index canister references are persistent. To disable:
- Call `updateTokenIndexCanister()` with null principal (if implemented)
- Or queries will gracefully fall back to ledger if index canister becomes unavailable

## Technical Details

### Conversion Function

The frontend includes a converter to transform ICRC-3 Index format to internal TransactionRecord:

```typescript
const convertIndexTransactionToRecord = (txWithId: TransactionWithId): TransactionRecord => {
  const tx = txWithId.transaction;
  const record: TransactionRecord = {
    index: txWithId.id,
    kind: tx.kind,
    timestamp: Number(tx.timestamp / BigInt(1000000)), // ns to ms
  };

  // Extract transfer, mint, burn, approve details based on transaction type
  if (tx.transfer && tx.transfer.length > 0) {
    const transfer = tx.transfer[0];
    record.amount = transfer.amount;
    record.fee = transfer.fee?.[0];
    record.from = transfer.from;
    record.to = transfer.to;
    record.memo = transfer.memo?.[0];
  }
  // ... handle other transaction types

  return record;
};
```

### Service Classes

- **IcrcIndexService**: Queries ICRC-3 Index Canister
- **IcrcService**: Queries token ledger canister (fallback)
- Both provide `getTransactions()` with consistent interface

## Future Enhancements

- [ ] Batch index canister creation during token deployment
- [ ] Automatic index canister selection based on token type
- [ ] Custom index canister implementations
- [ ] Index canister health monitoring
- [ ] Multi-index support for redundancy

## References

- [ICRC-3 Standard](https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-3/)
- [Token Factory Documentation](./TOKEN_FACTORY.md)
- [Frontend Architecture](../../FRONTEND_ARCHITECTURE.md)
- [Transaction Handling](../../common_features/TRANSACTION_HANDLING.md)
