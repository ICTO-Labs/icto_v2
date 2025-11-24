# [Module Name] Factory - Module Overview

**Status:** 📋 Planned / 🚧 In Progress / ✅ Completed
**Version:** X.X.X
**Last Updated:** YYYY-MM-DD

---

## 📋 Quick Links

- [Backend Documentation](./BACKEND.md) - Motoko implementation
- [Frontend Documentation](./FRONTEND.md) - Vue.js implementation
- [API Documentation](./API.md) - Service layer and integration
- [Token Indexing Guide](./TOKEN_INDEXING.md) - ICRC-3 Index Canister integration
- [Files Reference](./FILES.md) - Complete file listing
- [Implementation Guide](./IMPLEMENTATION_GUIDE.md) - For AI agents
- [Changelog](./CHANGELOG.md) - Development history

---

## Overview

[Brief description of what this module does]

### Key Features

- ✅ Feature 1
- ✅ Feature 2
- ✅ Feature 3
- 🚧 Feature 4 (in progress)
- 📋 Feature 5 (planned)

---

## System Components

### 1. Backend (Motoko)

**Factory Canister:**
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**[Contract Type] Contract:**
- [Responsibility 1]
- [Responsibility 2]
- [Responsibility 3]

**Location:** `src/motoko/[module_name]_factory/`

### 2. Frontend (Vue.js)

**Views:**
- [View 1 description]
- [View 2 description]
- [View 3 description]

**Components:**
- [Component 1 description]
- [Component 2 description]
- [Component 3 description]

**Location:** `src/frontend/src/views/[ModuleName]/`, `src/frontend/src/components/[moduleName]/`

### 3. API Layer

**Services:**
- `[moduleName]Factory.ts` - Factory interactions
- `[moduleName].ts` - Contract interactions

**Location:** `src/frontend/src/api/services/`

---

## User Roles

### Role 1
- Permission 1
- Permission 2
- Permission 3

### Role 2
- Permission 1
- Permission 2
- Permission 3

---

## Data Flow

### 1. [Primary Action]

```
User (Frontend)
    │
    │ 1. [Step 1]
    ▼
Backend
    │
    │ 2. [Step 2]
    ▼
[Module] Factory
    │
    │ 3. [Step 3]
    │ 4. [Step 4]
    ▼
[Action Result] ✅
```

---

## Storage Indexes

### Factory Indexes (O(1) Lookups)

```motoko
// [Index 1]: description
[indexName]: Trie.Trie<Principal, [Principal]>

// [Index 2]: description
[indexName]: Trie.Trie<Principal, [Principal]>

// Public contracts
publicContracts: [Principal]
```

### Query Functions

```motoko
// [Query 1 description]
[queryName](user, limit, offset) : {items, total}

// [Query 2 description]
[queryName](user, limit, offset) : {items, total}
```

---

## Callback Events

Contracts notify factory on these events:

| Event | Callback Function | Index Updated |
|-------|------------------|---------------|
| [Event 1] | `notify[Event1]([param])` | [indexName] |
| [Event 2] | `notify[Event2]([param])` | [indexName] |

---

## Version Management

### Current Version: X.X.X

**Features:**
- Feature 1
- Feature 2
- Feature 3

### Upgrade Path

[Standard upgrade path documentation]

---

## Security Model

### 1. Factory Authentication
[Security measure 1]

### 2. Callback Verification
[Security measure 2]

### 3. Role-Based Access
[Security measure 3]

---

## Performance Metrics

### Query Performance

| Operation | Complexity | Time | Cycles |
|-----------|-----------|------|--------|
| [Operation 1] | O(1) | <500ms | 10M |
| [Operation 2] | O(1) | <200ms | 5M |

---

## Testing Requirements

### Unit Tests
[List of unit tests]

### Integration Tests
[List of integration tests]

---

## Current Status

### ✅ Completed
[Completed features]

### 🚧 In Progress
[In-progress features]

### 📋 Planned
[Planned features]

---

## Quick Start

### For Developers
[Quick start instructions]

### For AI Agents
[Context loading instructions]

---

## Related Modules

- **[Module 1]** - [Relationship]
- **[Module 2]** - [Relationship]

---

## Support

- **Implementation Questions:** See [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
- **Backend Details:** See [BACKEND.md](./BACKEND.md)
- **Frontend Details:** See [FRONTEND.md](./FRONTEND.md)
- **File Locations:** See [FILES.md](./FILES.md)

---

**Last Updated:** YYYY-MM-DD
**Module Version:** X.X.X
**Status:** [Status Icon] [Status Text]
