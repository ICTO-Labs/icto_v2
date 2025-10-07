# BigInt Conversion Memory - ICTO V2

## Critical Rule: Always Convert BigInt from IC Backend

### Problem
IC backend (Motoko) returns BigInt values for numbers, but frontend JavaScript expects regular numbers. Mixing BigInt with regular numbers in arithmetic operations causes:
```
TypeError: Invalid mix of BigInt and other type in division
```

### Solution Pattern
Always convert BigInt to Number before arithmetic operations:

```typescript
// ❌ WRONG - Direct arithmetic with BigInt
const result = bigintValue / 1000

// ✅ CORRECT - Convert first
const result = Number(bigintValue) / 1000

// ✅ SAFER - Handle both types
const numValue = typeof value === 'bigint' ? Number(value) : value
const result = numValue / 1000
```

### Common IC Backend BigInt Fields
- `timestamp` (nanoseconds)
- `amount` (token amounts)
- `balance` (account balances)
- `proposalId` (when numeric)
- `blockIndex` (transaction references)

### Conversion Functions
```typescript
// Timestamp conversion (nanoseconds to milliseconds)
const formatTimestamp = (timestamp: number | bigint) => {
  const timestampNumber = typeof timestamp === 'bigint' ? Number(timestamp) : timestamp
  const timestampMs = Math.floor(timestampNumber / 1_000_000)
  return new Date(timestampMs).toLocaleString()
}

// Amount conversion (e8s to display)
const formatAmount = (amount: number | bigint) => {
  const amountNumber = typeof amount === 'bigint' ? Number(amount) : amount
  return (amountNumber / 100_000_000).toFixed(8)
}
```

### Files Already Fixed
- `/src/frontend/src/components/multisig/FullAuditLog.vue` - formatTimestamp function
- `/src/frontend/src/api/services/multisig.ts` - Multiple BigInt conversions needed

### Files That Need Checking
- All multisig components handling amounts/timestamps
- Balance display components
- Transaction history components
- Any component receiving IC backend data

### Best Practice
1. Always assume IC backend returns BigInt for numeric values
2. Convert immediately after receiving data
3. Use type guards: `typeof value === 'bigint'`
4. Test arithmetic operations with BigInt data
