# Whitelist Management System

## Overview

Complete whitelist management system for Launchpad Factory with CSV import, manual entry, and tier-based allocation support.

## Architecture

### Backend Contract Support (NEW!)

The launchpad factory contract now natively supports:
- `visibility: SaleVisibility` - Native visibility control
  - `{ Public: null }`
  - `{ WhitelistOnly: { mode: OpenRegistration | Closed } }`
  - `{ Private: null }`
- `requiresWhitelist: boolean` (inferred from visibility)
- `whitelist: Array<Principal>` (whitelisted addresses)
- `saleType: IDO | FairLaunch | PrivateSale | Auction | Lottery` (legacy fallback)

### Frontend Integration

Frontend directly uses backend visibility field:
- `visibility: 'Public' | 'WhitelistOnly' | 'Private'` (backend field)
- `whitelistMode: 'OpenRegistration' | 'Closed'` (used with WhitelistOnly)
- `whitelistEntries[]` (enhanced structure with metadata)

## Clean Architecture - No Mapping Required!

### Backend SaleVisibility Structure

| Frontend Visibility | Backend SaleVisibility | Whitelist Required | Description |
|-------------------|----------------------|-------------------|-------------|
| 🌍 Public | `{ Public: null }` | false (optional) | Open to everyone, optional whitelist for early access |
| 📋 Whitelist Only | `{ WhitelistOnly: { mode: OpenRegistration | Closed } }` | true | Public discovery, whitelist required to participate |
| 🔒 Private | `{ Private: null }` | true | Invite-only, no public discovery |

### Whitelist Mode Logic

| Whitelist Mode | Registration | Approval | Use Case |
|---------------|-------------|-----------|----------|
| OpenRegistration | Open | Auto-approved based on criteria | Public sales with optional whitelist |
| Closed | Admin-only | Manual approval required | Private sales, VCs, strategic partners |

## Components

### 1. SaleVisibilityConfig.vue

Main component for configuring sale visibility and access control.

**Features:**
- 3 visibility modes with automatic backend mapping
- Real-time configuration updates
- Visual indicators for each mode
- Integration with WhitelistImport component

**Key Functions:**
```typescript
selectVisibility(value: 'Public' | 'WhitelistOnly' | 'Private') {
  // Maps frontend visibility → backend saleType + whitelist config
  if (value === 'Public') {
    formData.value.saleParams.saleType = 'FairLaunch'
    formData.value.saleParams.requiresWhitelist = false
    formData.value.saleParams.whitelistMode = 'OpenRegistration'
  }
  // ... other mappings
}
```

### 2. WhitelistImport.vue

Comprehensive whitelist management component.

**Features:**
- **CSV Import**: Upload CSV files with bulk addresses
- **Manual Entry**: Add individual addresses with form
- **Management**: View, edit, delete existing entries
- **Export**: Download whitelist as CSV
- **Validation**: Real-time principal and data validation

**CSV Format:**
```csv
principal,allocation,tier
aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa,1000,1
bbbbb-bbbbb-bbbbb-bbbbb-bbbbb-bbbbb-bbbbb,500,2
```

**Fields:**
- `principal` (required): Wallet address
- `allocation` (optional): Maximum tokens they can buy
- `tier` (optional): Priority tier 1-10 (defaults to 1)

## Data Structure

### WhitelistEntry Interface

```typescript
interface WhitelistEntry {
  principal: string           // Wallet address
  allocation?: string         // Max tokens they can purchase
  tier?: number              // Priority tier (1-10)
  ictoPassportScore?: number      // ICTO Passport verification score
  whitelistScore?: number    // Internal scoring
  scoreBreakdown?: {         // Detailed score breakdown
    accountAge?: number
    stakeAmount?: number
    nftHolder?: boolean
    activityScore?: number
  }
  registeredAt?: string      // Registration timestamp
  approvedAt?: string        // Approval timestamp
  approvedBy?: string        // Admin who approved
}
```

## Usage Examples

### Public Sale with Optional Whitelist

```typescript
// User selects "Public" visibility
formData.saleParams = {
  visibility: 'Public',
  saleType: 'FairLaunch',      // Auto-mapped
  requiresWhitelist: false,    // Default
  whitelistMode: 'OpenRegistration',
  // User can optionally enable whitelist for early access
}
```

### IDO with Required Whitelist

```typescript
// User selects "Whitelist Only" visibility
formData.saleParams = {
  visibility: 'WhitelistOnly',
  saleType: 'IDO',            // Auto-mapped
  requiresWhitelist: true,     // Forced
  whitelistMode: 'OpenRegistration' | 'Closed', // User choice
}
```

### Private Sale with Closed Whitelist

```typescript
// User selects "Private" visibility
formData.saleParams = {
  visibility: 'Private',
  saleType: 'PrivateSale',    // Auto-mapped
  requiresWhitelist: true,     // Forced
  whitelistMode: 'Closed',    // Forced
}
```

## Integration Flow

1. **User selects visibility mode** in SaleVisibilityConfig
2. **Component auto-maps** to backend saleType and configures whitelist
3. **If whitelist required**, WhitelistImport component appears
4. **User imports/enters** whitelist addresses via CSV or manual entry
5. **Data is stored** in `formData.whitelistEntries[]`
6. **On deployment**, backend processes whitelist array and saleType

## Backend Processing

The backend contract will:

1. **Read `saleType`** to determine sale behavior
2. **Check `requiresWhitelist`** to enforce participation rules
3. **Process `whitelist` array** for allowed addresses
4. **Apply sale logic** based on SaleType (IDO vs FairLaunch vs PrivateSale)

## Important Notes

- **`visibility` is frontend-only** - not sent to backend
- **`whitelistMode` is frontend logic** - for admin approval flow
- **Backend only cares about** `saleType` and `requiresWhitelist`
- **Private sales are not discoverable** in public listings
- **Whitelist data persists** in form state until deployment

## Future Enhancements

- [ ] Integration with ICTO Passport for automatic scoring
- [ ] Whitelist scoring system with multiple criteria
- [ ] Bulk operations (approve all, reject all)
- [ ] Whitelist templates for common use cases
- [ ] Integration with external identity providers
- [ ] Real-time collaboration for team whitelist management