# Launchpad Factory - Type Migration Guide

**Date:** 2025-10-17
**Version:** V2 Migration
**Status:** 🔄 Ready for Implementation

---

## 📋 Overview

This guide provides **step-by-step instructions** for aligning frontend types with backend V2 architecture. All type mismatches have been identified and solutions provided with code examples.

---

## 🎯 Summary of Changes

### ✅ Completed
1. ✅ Updated `src/frontend/src/types/launchpad.ts` with aligned types
2. ✅ Renamed `immediatePercentage` → `immediateRelease` in VestingSchedule
3. ✅ Added `description` and `logo` fields to DEX platforms
4. ✅ Updated RaisedFundsAllocation to V2 dynamic array structure

### ⚠️ Pending Implementation
1. ❌ Update `useLaunchpadForm.ts` composable initialization
2. ❌ Update components using old vesting field names
3. ❌ Update RaisedFundsAllocationV2 component logic
4. ❌ Create data transformation utilities

---

## 🔧 Required Code Changes

### 1. **useLaunchpadForm.ts** - Composable State Structure

#### File: `/Users/fern/Coding/icto_v2/src/frontend/src/composables/useLaunchpadForm.ts`

#### Change 1.1: Update raisedFundsAllocation Structure (Lines 197-262)

**❌ OLD CODE (REMOVE):**
```typescript
raisedFundsAllocation: {
  teamAllocationPercentage: 70,
  teamAllocation: '',
  teamVestingEnabled: true,
  teamRecipients: [] as Array<{
    principal: string
    percentage: number
    name?: string
  }>,
  marketingAllocationPercentage: 20,
  marketingAllocation: '',
  marketingVestingEnabled: false,
  marketingRecipients: [] as Array<{
    principal: string
    percentage: number
    name?: string
  }>,
  dexLiquidityPercentage: 10,
  dexLiquidityAllocation: '',
  dexConfig: {
    platforms: [] as Array<{
      id: string
      name: string
      enabled: boolean
      allocationPercentage: number
      calculatedTokenLiquidity: number
      calculatedPurchaseLiquidity: number
      fees?: {
        listing: number
        transaction: number
      }
    }>
  },
  customAllocations: [] as Array<{
    id: string
    name: string
    percentage: number
    amount: string
    vestingEnabled: boolean
    vestingSchedule?: {
      cliffDays: number
      durationDays: number
      releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
      immediatePercentage: number  // ❌ OLD FIELD NAME
    }
    recipients: Array<{
      principal: string
      percentage: number
      name?: string
    }>
  }>,
  globalVestingSchedule: {
    cliffDays: 180,
    durationDays: 730,
    releaseFrequency: 'monthly' as const,
    immediatePercentage: 10  // ❌ OLD FIELD NAME
  },
  marketingVestingSchedule: {
    cliffDays: 180,
    durationDays: 730,
    releaseFrequency: 'monthly' as const,
    immediatePercentage: 10  // ❌ OLD FIELD NAME
  }
},
```

**✅ NEW CODE (REPLACE WITH):**
```typescript
// ✅ V2 ALIGNED WITH BACKEND: LaunchpadTypes.mo L180-L220
// Dynamic allocation array structure matching backend
raisedFundsAllocation: {
  allocations: [
    // Team Allocation (default 70%)
    {
      id: 'team',
      name: 'Team Allocation',
      amount: '0',  // Calculated by backend
      percentage: 70,
      recipients: [] as Array<{
        principal: string
        percentage: number
        name?: string
        vestingEnabled: boolean
        vestingSchedule?: {
          cliffDays: number
          durationDays: number
          releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
          immediateRelease: number  // ✅ RENAMED from immediatePercentage
        }
        description?: string
      }>
    },
    // Marketing Allocation (default 20%)
    {
      id: 'marketing',
      name: 'Marketing Allocation',
      amount: '0',
      percentage: 20,
      recipients: [] as Array<{
        principal: string
        percentage: number
        name?: string
        vestingEnabled: boolean
        vestingSchedule?: {
          cliffDays: number
          durationDays: number
          releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
          immediateRelease: number  // ✅ RENAMED
        }
        description?: string
      }>
    },
    // DEX Liquidity Allocation (default 10%)
    {
      id: 'dex_liquidity',
      name: 'DEX Liquidity',
      amount: '0',
      percentage: 10,
      recipients: [] // No recipients - auto-distributed to DEX
    }
  ] as Array<{
    id: string
    name: string
    amount: string
    percentage: number
    recipients: Array<{
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: {
        cliffDays: number
        durationDays: number
        releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
        immediateRelease: number
      }
      description?: string
    }>
  }>,

  // ✅ ALIGNED: Multi-DEX Config with enhanced fields
  dexConfig: {
    platforms: [] as Array<{
      id: string
      name: string
      description?: string  // ✅ NEW - Platform description
      logo?: string         // ✅ NEW - Platform logo URL
      enabled: boolean
      allocationPercentage: number
      calculatedTokenLiquidity: number
      calculatedPurchaseLiquidity: number
      fees?: {
        listing: number
        transaction: number
      }
    }>
  }
},
```

**Lines to replace:** 197-262

---

#### Change 1.2: Update Token Distribution Vesting Fields (Lines 130-160)

**Search for:**
```typescript
vestingSchedule: {
  cliffDays: 365,
  durationDays: 1460,
  releaseFrequency: 'monthly' as const,
  immediatePercentage: 0  // ❌ OLD FIELD NAME
},
```

**Replace with:**
```typescript
vestingSchedule: {
  cliffDays: 365,
  durationDays: 1460,
  releaseFrequency: 'monthly' as const,
  immediateRelease: 0  // ✅ RENAMED from immediatePercentage
},
```

**Apply to:**
- `distribution.team.vestingSchedule` (approx line 140)
- All `team.recipients[].vestingSchedule` (line 152)
- All `others[].vestingSchedule` (line 174)
- All `others[].recipients[].vestingSchedule` (line 189)

---

### 2. **Components** - Update Vesting Field References

#### Files to Update:

1. `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad/TokenAllocation.vue`
2. `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad_v2/VestingScheduleConfig.vue`
3. `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad_v2/VestingSummary.vue`
4. `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad_v2/RecipientManagementV2.vue`
5. `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad_v2/LaunchOverviewStep.vue`

#### Search & Replace All:

**Find:**
```typescript
immediatePercentage
```

**Replace with:**
```typescript
immediateRelease
```

**Note:** This is a **GLOBAL RENAME** across all component files.

---

### 3. **RaisedFundsAllocationV2.vue** - Update Component Logic

#### File: `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad_v2/RaisedFundsAllocationV2.vue`

**Current Structure** (needs verification):
- Component likely uses `teamAllocationPercentage`, `marketingAllocationPercentage`, etc.
- Needs to be refactored to use `allocations` array

**✅ NEW APPROACH:**

```vue
<script setup lang="ts">
import { computed } from 'vue'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

const launchpadForm = useLaunchpadForm()
const { formData } = launchpadForm

// Access allocations array
const allocations = computed(() => formData.value?.raisedFundsAllocation?.allocations || [])

// Get specific allocation by ID
const teamAllocation = computed(() =>
  allocations.value.find(a => a.id === 'team')
)
const marketingAllocation = computed(() =>
  allocations.value.find(a => a.id === 'marketing')
)
const dexLiquidityAllocation = computed(() =>
  allocations.value.find(a => a.id === 'dex_liquidity')
)

// Update allocation percentage
const updateAllocationPercentage = (id: string, newPercentage: number) => {
  const allocation = allocations.value.find(a => a.id === id)
  if (allocation) {
    allocation.percentage = newPercentage
  }
}

// Add custom allocation
const addCustomAllocation = () => {
  if (!formData.value?.raisedFundsAllocation?.allocations) return

  formData.value.raisedFundsAllocation.allocations.push({
    id: `custom_${Date.now()}`,
    name: 'Custom Allocation',
    amount: '0',
    percentage: 0,
    recipients: []
  })
}
</script>

<template>
  <div class="space-y-6">
    <!-- Team Allocation -->
    <div v-if="teamAllocation" class="allocation-section">
      <label>Team Allocation ({{ teamAllocation.percentage }}%)</label>
      <input
        type="number"
        v-model.number="teamAllocation.percentage"
        min="0"
        max="100"
      />
      <!-- Recipient management here -->
    </div>

    <!-- Marketing Allocation -->
    <div v-if="marketingAllocation" class="allocation-section">
      <label>Marketing Allocation ({{ marketingAllocation.percentage }}%)</label>
      <input
        type="number"
        v-model.number="marketingAllocation.percentage"
        min="0"
        max="100"
      />
    </div>

    <!-- DEX Liquidity -->
    <div v-if="dexLiquidityAllocation" class="allocation-section">
      <label>DEX Liquidity ({{ dexLiquidityAllocation.percentage }}%)</label>
      <input
        type="number"
        v-model.number="dexLiquidityAllocation.percentage"
        min="0"
        max="100"
      />
    </div>

    <!-- Custom Allocations -->
    <div v-for="allocation in allocations.filter(a => !['team', 'marketing', 'dex_liquidity'].includes(a.id))"
         :key="allocation.id"
         class="allocation-section">
      <label>{{ allocation.name }} ({{ allocation.percentage }}%)</label>
      <input
        type="number"
        v-model.number="allocation.percentage"
        min="0"
        max="100"
      />
    </div>

    <!-- Add Custom Allocation Button -->
    <button @click="addCustomAllocation" class="btn-primary">
      Add Custom Allocation
    </button>
  </div>
</template>
```

---

### 4. **MultiDEXConfiguration.vue** - Add Platform Enhancement Fields

#### File: `/Users/fern/Coding/icto_v2/src/frontend/src/components/launchpad_v2/MultiDEXConfiguration.vue`

**Enhancement:** Add `description` and `logo` fields to platform objects

```typescript
// Platform definitions with enhanced metadata
const availablePlatforms = [
  {
    id: 'icswap',
    name: 'ICPSwap',
    description: 'Leading DEX on Internet Computer', // ✅ NEW
    logo: 'https://icpswap.com/logo.svg',             // ✅ NEW
    enabled: false,
    allocationPercentage: 0,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0,
      transaction: 0.3
    }
  },
  {
    id: 'sonic',
    name: 'Sonic DEX',
    description: 'Fast and efficient IC DEX',        // ✅ NEW
    logo: 'https://sonic.ooo/logo.svg',              // ✅ NEW
    enabled: false,
    allocationPercentage: 0,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0,
      transaction: 0.25
    }
  },
  // ... other platforms
]
```

**UI Enhancement:**
```vue
<template>
  <div v-for="platform in platforms" :key="platform.id" class="platform-card">
    <!-- Platform Logo -->
    <img v-if="platform.logo" :src="platform.logo" :alt="platform.name" class="w-8 h-8" />

    <!-- Platform Name & Description -->
    <div>
      <h4>{{ platform.name }}</h4>
      <p v-if="platform.description" class="text-sm text-gray-500">
        {{ platform.description }}
      </p>
    </div>

    <!-- ... rest of UI -->
  </div>
</template>
```

---

## 🔄 Data Transformation Layer

### Create: `src/frontend/src/utils/launchpadTransformer.ts`

```typescript
import type { LaunchpadFormData } from '@/types/launchpad'

/**
 * Transform frontend formData to backend LaunchpadConfig format
 */
export function transformToBackendConfig(formData: LaunchpadFormData): any {
  return {
    projectInfo: {
      ...formData.projectInfo,
      // Transform arrays and ensure Principal format
      tags: formData.projectInfo.tags.map(t => t.trim()),
      category: mapCategoryToVariant(formData.projectInfo.category),
      metadata: formData.projectInfo.metadata ? [...formData.projectInfo.metadata] : null
    },

    saleToken: {
      canisterId: formData.saleToken.canisterId ?
        { _isPrincipal: true, _arr: toPrincipalBytes(formData.saleToken.canisterId) } :
        null,
      symbol: formData.saleToken.symbol,
      name: formData.saleToken.name,
      decimals: formData.saleToken.decimals,
      totalSupply: stringToBigInt(formData.saleToken.totalSupply, formData.saleToken.decimals),
      transferFee: stringToBigInt(formData.saleToken.transferFee, formData.saleToken.decimals),
      logo: formData.saleToken.logo || null,
      description: formData.saleToken.description || null,
      website: formData.saleToken.website || null,
      standard: formData.saleToken.standard
    },

    purchaseToken: {
      canisterId: { _isPrincipal: true, _arr: toPrincipalBytes(formData.purchaseToken.canisterId) },
      // ... similar to saleToken
    },

    saleParams: {
      saleType: mapSaleTypeToVariant(formData.saleParams.saleType),
      allocationMethod: mapAllocationMethodToVariant(formData.saleParams.allocationMethod),
      totalSaleAmount: stringToBigInt(formData.saleParams.totalSaleAmount, formData.saleToken.decimals),
      softCap: stringToBigInt(formData.saleParams.softCap, formData.purchaseToken.decimals),
      hardCap: stringToBigInt(formData.saleParams.hardCap, formData.purchaseToken.decimals),
      tokenPrice: stringToBigInt(formData.saleParams.tokenPrice, formData.purchaseToken.decimals),
      minContribution: stringToBigInt(formData.saleParams.minContribution, formData.purchaseToken.decimals),
      maxContribution: formData.saleParams.maxContribution ?
        stringToBigInt(formData.saleParams.maxContribution, formData.purchaseToken.decimals) : null,
      maxParticipants: formData.saleParams.maxParticipants || null,
      requiresWhitelist: formData.saleParams.requiresWhitelist,
      requiresKYC: formData.saleParams.requiresKYC,
      blockIdRequired: BigInt(formData.saleParams.blockIdRequired),
      restrictedRegions: formData.saleParams.restrictedRegions,
      whitelistMode: mapWhitelistModeToVariant(formData.saleParams.whitelistMode),
      whitelistEntries: formData.saleParams.whitelistEntries.map(entry => ({
        principal: { _isPrincipal: true, _arr: toPrincipalBytes(entry.principal) },
        allocation: entry.allocation ? stringToBigInt(entry.allocation, formData.saleToken.decimals) : null,
        tier: entry.tier || null,
        registeredAt: entry.registeredAt ? dateToNanoseconds(entry.registeredAt) : null,
        approvedAt: entry.approvedAt ? dateToNanoseconds(entry.approvedAt) : null
      }))
    },

    timeline: {
      createdAt: dateToNanoseconds(formData.timeline.createdAt),
      whitelistStart: formData.timeline.whitelistStart ? dateToNanoseconds(formData.timeline.whitelistStart) : null,
      whitelistEnd: formData.timeline.whitelistEnd ? dateToNanoseconds(formData.timeline.whitelistEnd) : null,
      saleStart: dateToNanoseconds(formData.timeline.saleStart),
      saleEnd: dateToNanoseconds(formData.timeline.saleEnd),
      claimStart: dateToNanoseconds(formData.timeline.claimStart),
      vestingStart: formData.timeline.vestingStart ? dateToNanoseconds(formData.timeline.vestingStart) : null,
      listingTime: formData.timeline.listingTime ? dateToNanoseconds(formData.timeline.listingTime) : null,
      daoActivation: formData.timeline.daoActivation ? dateToNanoseconds(formData.timeline.daoActivation) : null
    },

    // ✅ NEW V2 Structure
    tokenDistribution: {
      sale: {
        name: formData.distribution.sale.name,
        percentage: formData.distribution.sale.percentage,
        totalAmount: formData.distribution.sale.totalAmount,
        vestingSchedule: formData.distribution.sale.vestingSchedule ?
          transformVestingSchedule(formData.distribution.sale.vestingSchedule) : null,
        description: formData.distribution.sale.description || null
      },
      team: {
        name: formData.distribution.team.name,
        percentage: formData.distribution.team.percentage,
        totalAmount: formData.distribution.team.totalAmount,
        vestingSchedule: formData.distribution.team.vestingSchedule ?
          transformVestingSchedule(formData.distribution.team.vestingSchedule) : null,
        recipients: formData.distribution.team.recipients.map(r => ({
          principal: r.principal,
          percentage: r.percentage,
          amount: null,
          name: r.name || null,
          description: r.description || null,
          vestingOverride: r.vestingSchedule ? transformVestingSchedule(r.vestingSchedule) : null
        })),
        description: formData.distribution.team.description || null
      },
      liquidityPool: {
        name: formData.distribution.liquidityPool.name,
        percentage: formData.distribution.liquidityPool.percentage,
        totalAmount: formData.distribution.liquidityPool.totalAmount,
        autoCalculated: formData.distribution.liquidityPool.autoCalculated,
        description: formData.distribution.liquidityPool.description || null
      },
      others: formData.distribution.others.map(other => ({
        id: other.id,
        name: other.name,
        percentage: other.percentage,
        totalAmount: other.totalAmount,
        description: other.description || null,
        recipients: other.recipients.map(r => ({
          principal: r.principal,
          percentage: r.percentage,
          amount: null,
          name: r.name || null,
          description: r.description || null,
          vestingOverride: r.vestingSchedule ? transformVestingSchedule(r.vestingSchedule) : null
        })),
        vestingSchedule: other.vestingSchedule ? transformVestingSchedule(other.vestingSchedule) : null
      }))
    },

    // ✅ V2 Raised Funds Allocation
    raisedFundsAllocation: {
      allocations: formData.raisedFundsAllocation.allocations.map(allocation => ({
        id: allocation.id,
        name: allocation.name,
        amount: stringToBigInt(allocation.amount, formData.purchaseToken.decimals),
        percentage: allocation.percentage,
        recipients: allocation.recipients.map(r => ({
          principal: { _isPrincipal: true, _arr: toPrincipalBytes(r.principal) },
          percentage: r.percentage,
          name: r.name || null,
          vestingEnabled: r.vestingEnabled,
          vestingSchedule: r.vestingSchedule ? transformVestingSchedule(r.vestingSchedule) : null,
          description: r.description || null
        }))
      }))
    },

    // ... rest of transformations
  }
}

/**
 * Transform vesting schedule with correct field names
 */
function transformVestingSchedule(vesting: any) {
  return {
    cliffDays: BigInt(vesting.cliffDays),
    durationDays: BigInt(vesting.durationDays),
    releaseFrequency: mapReleaseFrequencyToVariant(vesting.releaseFrequency),
    immediateRelease: vesting.immediateRelease  // ✅ Aligned field name
  }
}

// Helper functions
function stringToBigInt(value: string, decimals: number): bigint {
  const num = parseFloat(value)
  if (isNaN(num)) return BigInt(0)
  return BigInt(Math.floor(num * Math.pow(10, decimals)))
}

function dateToNanoseconds(dateString: string): bigint {
  return BigInt(new Date(dateString).getTime() * 1_000_000)
}

function toPrincipalBytes(principalText: string): Uint8Array {
  // Use @dfinity/principal library
  // return Principal.fromText(principalText).toUint8Array()
  // Placeholder - implement with actual Principal library
  return new Uint8Array()
}

function mapCategoryToVariant(category: string): any {
  const variants: Record<string, any> = {
    'DeFi': { DeFi: null },
    'Gaming': { Gaming: null },
    'NFT': { NFT: null },
    'Infrastructure': { Infrastructure: null },
    'DAO': { DAO: null },
    'Metaverse': { Metaverse: null },
    'AI': { AI: null },
    'SocialFi': { SocialFi: null }
  }
  return variants[category] || { Other: category }
}

function mapSaleTypeToVariant(type: string): any {
  const variants: Record<string, any> = {
    'FairLaunch': { FairLaunch: null },
    'PrivateSale': { PrivateSale: null },
    'IDO': { IDO: null },
    'Auction': { Auction: null },
    'Lottery': { Lottery: null }
  }
  return variants[type]
}

function mapAllocationMethodToVariant(method: string): any {
  const variants: Record<string, any> = {
    'FirstComeFirstServe': { FirstComeFirstServe: null },
    'ProRata': { ProRata: null },
    'Lottery': { Lottery: null },
    'Weighted': { Weighted: null }
  }
  return variants[method]
}

function mapWhitelistModeToVariant(mode: string): any {
  return mode === 'Closed' ? { Closed: null } : { OpenRegistration: null }
}

function mapReleaseFrequencyToVariant(freq: string): any {
  const variants: Record<string, any> = {
    'daily': { Daily: null },
    'weekly': { Weekly: null },
    'monthly': { Monthly: null },
    'quarterly': { Quarterly: null },
    'yearly': { Yearly: null },
    'immediate': { Immediate: null },
    'linear': { Linear: null }
  }
  return variants[freq]
}
```

---

## ✅ Validation Checklist

Before deploying, verify:

- [ ] All `immediatePercentage` renamed to `immediateRelease`
- [ ] `useLaunchpadForm.ts` uses `allocations` array structure
- [ ] `RaisedFundsAllocationV2.vue` refactored for new structure
- [ ] DEX platforms include `description` and `logo` fields
- [ ] Data transformation layer created and tested
- [ ] TypeScript compilation passes with no errors
- [ ] All components render correctly with new structure
- [ ] Vesting schedules save and load correctly
- [ ] Allocations percentages sum to 100%
- [ ] Backend accepts transformed data format

---

## 🚀 Implementation Order

**Priority 1 (Blocking):**
1. Update `useLaunchpadForm.ts` - raisedFundsAllocation structure
2. Global rename `immediatePercentage` → `immediateRelease`
3. Test TypeScript compilation

**Priority 2 (High):**
4. Refactor `RaisedFundsAllocationV2.vue` for new structure
5. Create `launchpadTransformer.ts` utility
6. Test data serialization to backend

**Priority 3 (Medium):**
7. Add DEX platform enhancement fields
8. Update MultiDEXConfiguration UI
9. Integration testing

---

## 📝 Testing Strategy

### Unit Tests:
```typescript
describe('LaunchpadTransformer', () => {
  it('should transform vesting schedule with correct field names', () => {
    const input = {
      cliffDays: 180,
      durationDays: 730,
      releaseFrequency: 'monthly',
      immediateRelease: 10  // ✅ New field name
    }

    const result = transformVestingSchedule(input)

    expect(result.immediateRelease).toBe(10)
    expect(result).not.toHaveProperty('immediatePercentage')
  })

  it('should transform raised funds allocation to backend format', () => {
    const formData = createMockFormData()
    const backendConfig = transformToBackendConfig(formData)

    expect(backendConfig.raisedFundsAllocation.allocations).toHaveLength(3)
    expect(backendConfig.raisedFundsAllocation.allocations[0].id).toBe('team')
  })
})
```

### Integration Tests:
1. Create launchpad with new structure
2. Verify backend accepts data
3. Verify data roundtrip (create → fetch → display)
4. Verify vesting schedules persist correctly

---

## 🆘 Rollback Plan

If issues arise:

1. **Immediate Rollback:**
   ```bash
   git stash  # Stash current changes
   git checkout HEAD~1  # Revert to previous commit
   ```

2. **Partial Rollback:**
   - Keep type updates in `launchpad.ts`
   - Revert composable changes only
   - Add compatibility layer for old structure

3. **Forward Fix:**
   - Create compatibility wrapper
   - Support both old and new structures
   - Gradual migration with feature flag

---

**Status:** ✅ **READY FOR IMPLEMENTATION**
**Estimated Time:** 4-6 hours
**Risk Level:** Medium (Type changes, requires testing)
**Rollback Time:** < 15 minutes

---

**Last Updated:** 2025-10-17
**Created By:** Claude Code (AI)
