# ICTO V2 - Technical Documentation

**Version:** 2.0
**Last Updated:** 2025-10-06
**Status:** Production Ready

---

## 📚 Documentation Index

This documentation is designed for developers, contributors, and AI agents working on the ICTO V2 platform. Each section is self-contained to minimize context loading.

### 🎯 Quick Start

- **New to the project?** Start with [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Understanding workflows?** Read [WORKFLOW.md](./WORKFLOW.md)
- **Working on a specific module?** Jump to [Modules](#modules)
- **Need to follow standards?** Check [Standards](#standards)

---

## 📖 Core Documentation

### Architecture & Design

| Document | Description | Audience |
|----------|-------------|----------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System architecture overview, factory-first design | All developers |
| [BACKEND_FACTORY_INTEGRATION.md](./BACKEND_FACTORY_INTEGRATION.md) | Backend-Factory integration, whitelist security, API calls | Backend devs, AI agents |
| [WORKFLOW.md](./WORKFLOW.md) | User flows, data flows, system interactions | Frontend & Backend devs |

---

## 🧩 Modules

Each module is self-contained with complete documentation of backend, frontend, API, and related files.

### Factory Modules

| Module | Status | Description |
|--------|--------|-------------|
| [Distribution Factory](./modules/distribution_factory/) | ✅ Completed | Token distribution management system |
| [Multisig Factory](./modules/multisig_factory/) | 🚧 In Progress | Multi-signature wallet system |
| [Token Factory](./modules/token_factory/) | 📋 Planned | ICRC token creation and management |
| [DAO Factory](./modules/dao_factory/) | 📋 Planned | Decentralized governance system |
| [Launchpad Factory](./modules/launchpad_factory/) | 📋 Planned | Token launch and presale platform |

### Module Documentation Structure

Each module contains:
- **README.md** - Overview and quick links
- **BACKEND.md** - Backend (Motoko) implementation
- **FRONTEND.md** - Frontend (Vue) implementation
- **API.md** - API services and integration
- **FILES.md** - Complete list of related files
- **CHANGELOG.md** - Development history and changes
- **IMPLEMENTATION_GUIDE.md** - Guide for AI agents

---

## 📏 Standards

Core standards that apply across all modules.

| Standard | Description | Priority |
|----------|-------------|----------|
| [Factory Template](./standards/FACTORY_TEMPLATE.md) | Standard factory pattern | ⭐ Required |
| [Version Management](./standards/VERSION_MANAGEMENT.md) | Upgrade and rollback system | ⭐ Required |
| [Admin System](./standards/ADMIN_SYSTEM.md) | Backend-managed permissions | ⭐ Required |
| [Storage Pattern](./standards/STORAGE_PATTERN.md) | Factory storage and indexing | ⭐ Required |

---

## 📘 Guides

Practical guides for common tasks.

| Guide | Description |
|-------|-------------|
| [Migration Guide](./guides/MIGRATION.md) | Migrating from old architecture |
| [Deployment Guide](./guides/DEPLOYMENT.md) | Deploying to IC network |
| [Testing Guide](./guides/TESTING.md) | Testing standards and practices |
| [Security Guide](./guides/SECURITY.md) | Security best practices |

---

## 🤖 For AI Agents

### Context Optimization Strategy

When working on a specific feature, AI agents should:

1. **Identify the module** - Which factory/feature are you modifying?
2. **Load module docs** - Read only the relevant module's documentation
3. **Check CHANGELOG** - Understand recent changes
4. **Follow IMPLEMENTATION_GUIDE** - Use the specific guide for that module
5. **Update CHANGELOG** - Document your changes

### Example: Adding a feature to Multisig

```bash
# Context to load (in order):
1. documents/modules/multisig_factory/README.md          # Overview
2. documents/modules/multisig_factory/CHANGELOG.md       # Recent changes
3. documents/modules/multisig_factory/IMPLEMENTATION_GUIDE.md  # How to implement
4. documents/modules/multisig_factory/FILES.md           # Which files to edit
5. Specific docs: BACKEND.md or FRONTEND.md              # Detailed implementation
```

**Total context:** ~5 files instead of entire project!

---

## 🔄 Change Management Protocol

All changes must be tracked in the module's CHANGELOG.md:

### For AI Agents: MANDATORY WORKFLOW

```markdown
## Before Making Changes

1. Check module's CHANGELOG.md
2. Create new entry with checkbox:
   - [ ] Task name
   - [ ] Files affected
   - [ ] Implementation status

## After Completing Changes

1. Update the checkbox: [x]
2. Add summary in English (2-3 sentences)
3. List files modified
4. Note any breaking changes
```

### Example CHANGELOG Entry

```markdown
### 2025-10-06 - Add Transaction Confirmation Dialog

**Status:** ✅ Completed
**Agent:** Claude
**Type:** Enhancement

**Task Checklist:**
- [x] Add confirmation dialog component
- [x] Integrate with payment flow
- [x] Add loading states
- [x] Update tests

**Summary:**
Added a confirmation dialog before executing multisig transactions. Users now see transaction details (amount, recipient, gas) and must explicitly confirm before proceeding. Includes loading states and error handling.

**Files Modified:**
- `src/frontend/src/components/multisig/TransactionConfirmDialog.vue` (new)
- `src/frontend/src/views/Multisig/MultisigDetail.vue`
- `src/frontend/src/api/services/multisig.ts`

**Breaking Changes:** None
```

---

## 🏗️ Project Structure

```
icto_v2/
├── src/
│   ├── motoko/                 # Backend canisters
│   │   ├── multisig_factory/
│   │   ├── distribution_factory/
│   │   ├── token_factory/
│   │   ├── dao_factory/
│   │   └── launchpad_factory/
│   │
│   └── frontend/               # Vue.js frontend
│       ├── src/
│       │   ├── views/          # Page components
│       │   ├── components/     # Reusable components
│       │   ├── api/services/   # API service layer
│       │   ├── types/          # TypeScript types
│       │   ├── composables/    # Vue composables
│       │   └── utils/          # Utility functions
│       │
├── documents/                  # 📚 Official documentation (you are here)
│   ├── README.md
│   ├── ARCHITECTURE.md
│   ├── WORKFLOW.md
│   ├── modules/
│   ├── standards/
│   └── guides/
│
└── docs/                      # 📝 Legacy docs (reference only)
    └── refactor/
```

---

## 🎯 Key Principles

### 1. Modular Documentation
- Each module is self-contained
- Minimize cross-references
- Load only what you need

### 2. Change Tracking
- Every change documented in CHANGELOG
- Clear before/after states
- Agent attribution

### 3. AI-Friendly
- Structured formats
- Clear file paths
- Actionable guides

### 4. Version Controlled
- Documentation versioned with code
- Changelogs track evolution
- Easy to rollback

---

## 📊 System Metrics

### Performance Improvements (vs V1)

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Backend Storage | 1.05 GB | ~50 MB | 95% reduction |
| Dashboard Load | 3-4s | 1-2s | 60% faster |
| Query Cycles | High | -70% | Cost reduction |
| Query Complexity | O(n) | O(1) | Instant lookups |

### Architecture Benefits

- ✅ Distributed, scalable architecture
- ✅ Factory-first design pattern
- ✅ O(1) user lookups
- ✅ Version-controlled upgrades
- ✅ Rollback support

---

## 🤝 Contributing

### For Community Contributors

1. Read [ARCHITECTURE.md](./ARCHITECTURE.md) first
2. Choose a module to work on
3. Follow the module's IMPLEMENTATION_GUIDE
4. Update CHANGELOG with your changes
5. Submit PR with tests

### For AI Agents

1. Always update CHANGELOG before and after changes
2. Follow the context optimization strategy
3. Use structured format for documentation
4. Keep summaries concise but complete

---

## 📞 Support & Resources

- **Documentation Issues:** File issue in `/documents`
- **Code Issues:** File issue in GitHub repo
- **Architecture Questions:** See [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Legacy Docs:** See `/docs/refactor` (reference only)

---

## 📜 License

Copyright © 2025 ICTO. All rights reserved.

---

**Last Updated:** 2025-10-06
**Documentation Version:** 2.0
**System Status:** Production Ready ✅
