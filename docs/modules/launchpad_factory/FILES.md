# Launchpad Factory - File Reference

**Last Updated:** 2025-01-11
**Module Version:** 1.0.0

---

## 📁 Backend (Motoko)

### Factory Canister
```
src/motoko/launchpad_factory/
├── main.mo                    # Main factory implementation
├── Types.mo                  # Type definitions for launchpad
├── LaunchpadContract.mo       # Launchpad contract template
├── VestingContract.mo         # Vesting contract template
└── MultisigContract.mo        # Multisig wallet template
```

### Key Backend Files

| File | Purpose | Key Functions |
|------|---------|---------------|
| `main.mo` | Factory orchestrator | `createLaunchpad`, `deployContracts`, `manageAssets` |
| `Types.mo` | Data structures | `LaunchpadConfig`, `GovernanceModel`, `Allocation` |
| `LaunchpadContract.mo` | Token sale logic | `contribute`, `finalizeSale`, `distributeFunds` |
| `VestingContract.mo` | Token vesting | `addRecipient`, `releaseTokens`, `getSchedule` |
| `MultisigContract.mo` | Multi-signature wallet | `addSigner`, `proposeTransaction`, `execute` |

---

## 📁 Frontend (Vue.js)

### Views
```
src/frontend/src/views/Launchpad/
├── LaunchpadCreate.vue        # Multi-step creation wizard
├── LaunchpadDetail.vue        # Launchpad management interface
└── LaunchpadList.vue          # Browse launchpads
```

### Components
```
src/frontend/src/components/launchpad/
├── LaunchpadProgress.vue      # Step progress indicator
├── TokenConfiguration.vue     # Token setup (Step 1)
├── RaisedFundsAllocation.vue   # Fund allocation (Step 3)
├── VestingScheduleConfig.vue  # Vesting configuration
├── RecipientManagement.vue    # Reusable recipient management
├── MultiDEXConfiguration.vue  # DEX platform setup (Step 4)
├── PostLaunchOptions.vue      # Governance model selection (Step 5)
├── MultisigConfiguration.vue   # Multisig wallet setup
└── LaunchpadCard.vue         # Launchpad list item
```

### API Services
```
src/frontend/src/api/services/
├── launchpadFactory.ts       # Factory canister API
├── launchpad.ts              # Launchpad contract API
├── multisigFactory.ts        # Multisig wallet API
└── daoFactory.ts             # DAO governance API
```

### Types
```
src/frontend/src/types/
├── launchpad.ts              # Launchpad type definitions
├── vesting.ts                # Vesting schedule types
├── multisig.ts               # Multisig wallet types
└── dao.ts                   # DAO governance types
```

---

## 📁 Documentation

### Module Documentation
```
documents/modules/launchpad_factory/
├── README.md                 # Module overview (this file)
├── CHANGELOG.md              # Development history
├── FILES.md                  # File reference (this file)
├── IMPLEMENTATION_GUIDE.md    # Implementation guide
├── BACKEND.md                # Backend implementation details
├── FRONTEND.md               # Frontend implementation guide
├── API.md                    # API documentation
└── SECURITY.md              # Security considerations
```

---

## 🔧 Component Dependencies

### Backend Dependencies
- **Multisig Factory** - For multisig wallet operations
- **DAO Factory** - For DAO governance operations
- **Token Factory** - For ICRC token standards
- **Distribution Factory** - For vesting contracts

### Frontend Dependencies
- **@lucide-vue-next** - Icon library
- **vue-sonner** - Toast notifications
- **@headlessui/vue** - UI components
- **tailwindcss** - Styling framework
- **@dfinity/agent** - IC blockchain interaction

---

## 📝 File Naming Conventions

### Backend Files
- **Motoko files:** PascalCase (e.g., `LaunchpadContract.mo`)
- **Type definitions:** PascalCase (e.g., `Types.mo`)
- **Module names:** snake_case (e.g., `launchpad_factory`)

### Frontend Files
- **Vue components:** PascalCase.vue (e.g., `LaunchpadCreate.vue`)
- **Services:** camelCase.ts (e.g., `launchpadFactory.ts`)
- **Types:** camelCase.ts (e.g., `launchpad.ts`)
- **Views:** PascalCase.vue (e.g., `LaunchpadList.vue`)

---

## 🚀 Quick File Access

### Core Implementation
- **Main Factory:** `src/motoko/launchpad_factory/main.mo`
- **Launchpad Contract:** `src/motoko/launchpad_factory/LaunchpadContract.mo`
- **Frontend Wizard:** `src/frontend/src/views/Launchpad/LaunchpadCreate.vue`
- **Allocation Component:** `src/frontend/src/components/launchpad/RaisedFundsAllocation.vue`

### API Services
- **Factory Service:** `src/frontend/src/api/services/launchpadFactory.ts`
- **Launchpad Service:** `src/frontend/src/api/services/launchpad.ts`

### Documentation
- **Implementation Guide:** `documents/modules/launchpad_factory/IMPLEMENTATION_GUIDE.md`
- **Backend Details:** `documents/modules/launchpad_factory/BACKEND.md`
- **Frontend Details:** `documents/modules/launchpad_factory/FRONTEND.md`

---

**File Structure Summary:**
- **Total Backend Files:** 5 core files
- **Total Frontend Files:** 15+ components and services
- **Documentation Files:** 7 comprehensive docs
- **Integration Points:** 4 other factory modules