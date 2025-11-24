# TypeScript Declarations Auto-Generation Guide

## Overview

ICTO V2 uses DFX's native declarations generation feature to automatically create TypeScript type definitions for all canisters. This eliminates manual sync steps and ensures declarations are always up-to-date with canister interfaces.

## How It Works

### Configuration in dfx.json

Every canister in `dfx.json` has a `declarations` configuration:

```json
{
  "canisters": {
    "token_factory": {
      "main": "src/motoko/token_factory/main.mo",
      "type": "motoko",
      "declarations": {
        "output": "src/declarations/token_factory"
      }
    }
  }
}
```

### Generation Process

When you run `dfx build` or `dfx deploy`:

1. **DFX compiles** the Motoko canister to WASM
2. **DFX extracts** the Candid interface from the canister
3. **DFX generates** TypeScript declarations to `src/declarations/{canister}/`
4. **Frontend imports** declarations with type safety

### Generated Files

For each canister, three files are generated:

```
src/declarations/token_factory/
├── index.ts                    # Exported factory functions
├── token_factory.did           # Candid interface definition
├── token_factory.did.d.ts      # TypeScript type definitions
└── token_factory.did.js        # JavaScript factory import
```

## Importing Declarations

### Using the @declarations Alias

All imports use the `@declarations` alias defined in `vite.config.ts`:

```typescript
// Clean and consistent imports
import { tokenFactoryActor } from '@declarations/token_factory';
import type { TokenInfo } from '@declarations/token_factory/token_factory.did';
```

**Without alias (not recommended):**
```typescript
// Messy relative paths - harder to maintain
import { tokenFactoryActor } from '../../../../declarations/token_factory';
```

### Available Canisters

The following canisters have auto-generated declarations:

| Canister | Path | Type |
|----------|------|------|
| backend | `@declarations/backend` | Motoko |
| token_factory | `@declarations/token_factory` | Motoko |
| audit_storage | `@declarations/audit_storage` | Motoko |
| invoice_storage | `@declarations/invoice_storage` | Motoko |
| distribution_factory | `@declarations/distribution_factory` | Motoko |
| distribution_contract | `@declarations/distribution_contract` | Motoko |
| multisig_factory | `@declarations/multisig_factory` | Motoko |
| multisig_contract | `@declarations/multisig_contract` | Motoko |
| dao_factory | `@declarations/dao_factory` | Motoko |
| dao_contract | `@declarations/dao_contract` | Motoko |
| launchpad_factory | `@declarations/launchpad_factory` | Motoko |
| launchpad_contract | `@declarations/launchpad_contract` | Motoko |
| lock_factory | `@declarations/lock_factory` | Motoko |
| template_factory | `@declarations/template_factory` | Motoko |
| icp_ledger | `@declarations/icp_ledger` | Custom (ICP Ledger) |
| icrc_index | `@declarations/icrc_index` | Custom (ICRC-3 Index) |
| internet_identity | `@declarations/internet_identity` | Custom (Internet Identity) |

## Development Workflow

### Normal Development

1. **Make changes** to Motoko code
2. **Run `dfx build`** - declarations auto-generate
3. **Frontend automatically** picks up new types
4. **No manual steps needed** ✅

### After Changing Function Signatures

1. Update function signature in Motoko:
   ```motoko
   // OLD
   public func deployToken(config: TokenConfig) : async Result;

   // NEW
   public func deployToken(config: TokenConfig, enableIndex: Bool) : async Result;
   ```

2. Run `dfx build`:
   ```bash
   dfx build token_factory
   ```

3. TypeScript types are **automatically updated**:
   ```typescript
   // Old type signature is replaced with new one
   deployToken(config: TokenConfig, enableIndex: boolean): Promise<Result>;
   ```

4. **No rebuild required** - just use the new types ✅

## Troubleshooting

### Declarations Not Updating

**Problem:** Changes to Motoko don't appear in TypeScript types

**Solution:**
```bash
# Clean rebuild of specific canister
dfx build token_factory --no-cache

# Or clean all declarations
rm -rf src/declarations/*
dfx build
```

### Import Errors

**Problem:** `Cannot find module '@declarations/token_factory'`

**Solution:** Ensure `vite.config.ts` has the alias configured:
```typescript
resolve: {
  alias: {
    '@': fileURLToPath(new URL('./src', import.meta.url)),
    '@declarations': fileURLToPath(new URL('../declarations', import.meta.url))
  }
}
```

### Type Mismatches

**Problem:** TypeScript says function signature is different from documentation

**Solution:** Rebuild the canister to regenerate types:
```bash
dfx build --network local
```

Types are generated from the actual compiled WASM, not the source code.

## Best Practices

### ✅ Do

- Use `@declarations/` alias for all canister imports
- Rebuild after changing Motoko signatures
- Commit `src/declarations/` to git (it's auto-generated but good for CI)
- Check generated `.did` files to understand actual interfaces

### ❌ Don't

- Manually edit generated files in `src/declarations/`
- Use relative import paths (use alias instead)
- Rely on stale declarations without rebuilding
- Import from `.dfx/local/canisters/` directly (use declarations instead)

## Understanding Generated Types

### Example: TokenInfo Type

**Generated TypeScript (token_factory.did.d.ts):**
```typescript
export interface TokenInfo {
  'canisterId': Principal;
  'name': string;
  'symbol': string;
  'decimals': number;
  'totalSupply': bigint;
  'enableIndex': boolean;
  'indexCanisterId': [] | [Principal];
  // ... other fields
}
```

**Motoko Source (token_factory.mo):**
```motoko
type TokenInfo = {
  canisterId: Principal;
  name: Text;
  symbol: Text;
  decimals: Nat8;
  totalSupply: Nat;
  enableIndex: Bool;
  indexCanisterId: ?Principal;
  // ... other fields
};
```

**Type Mapping:**
- `Text` → `string`
- `Bool` → `boolean`
- `Nat` → `bigint`
- `Principal` → `Principal`
- `?Type` → `[] | [Type]` (optional)
- `[Type]` → `Type[]` (array)
- Record → Interface

## Performance Impact

**No negative impact** - declarations are:
- ✅ Generated at build time (not runtime)
- ✅ Cached in `.dfx/local/canisters/`
- ✅ Copied to `src/declarations/` by DFX
- ✅ Highly optimized by DFX

## CI/CD Integration

### GitHub Actions Example

```yaml
- name: Build canisters
  run: dfx build

- name: Verify declarations generated
  run: |
    test -f src/declarations/token_factory/index.ts || exit 1
    test -f src/declarations/backend/index.ts || exit 1
```

### Gradle Integration

```gradle
task dfxBuild {
  doLast {
    exec {
      commandLine 'dfx', 'build'
    }
  }
}

build.dependsOn dfxBuild
```

## Migration from Manual Sync

If you previously used manual sync scripts:

### Old Approach
```bash
# Manual sync after build
npm run build
bash scripts/sync-declarations.sh  # Unnecessary now
```

### New Approach
```bash
# Declarations auto-generate during build
dfx build
npm run build
# Done! ✅
```

## References

- [DFX Documentation - Declarations](https://internetcomputer.org/docs/current/developer-docs/build/candid/candid-intro)
- [Candid Language Guide](https://internetcomputer.org/docs/current/developer-docs/build/candid/candid-ref)
- [TypeScript Generation](https://github.com/dfinity/agent-js/tree/main/packages/candid)

## FAQ

### Q: Do I need to commit `src/declarations/` to git?
**A:** Not strictly necessary, but recommended for CI/CD pipelines to avoid rebuilding. They're generated files, so `.gitignore` them if you prefer.

### Q: What if a canister doesn't have declarations generated?
**A:** Check that `dfx.json` has the `declarations` section configured for that canister. If missing, add it and rebuild.

### Q: Can I customize declaration generation?
**A:** DFX has limited customization. For advanced needs, see [DFX Configuration](https://internetcomputer.org/docs/current/developer-docs/build/project-structure/dfx-json).

### Q: How do I know declarations are up-to-date?
**A:** Check the timestamp of files in `src/declarations/`. If older than your last `dfx build`, run rebuild.

### Q: What about mainnet canisters?
**A:** Declarations are generated the same way. The difference is network (local vs. ic), not declaration generation.
