# ICTO V2 - Internet Computer Token Operations Platform

<div align="center">

[![Internet Computer](https://img.shields.io/badge/Internet%20Computer-Blockchain-29ABE2)](https://internetcomputer.org/)
[![Motoko](https://img.shields.io/badge/Motoko-Backend-6B46C5)](https://internetcomputer.org/docs/current/motoko/main/motoko)
[![Vue 3](https://img.shields.io/badge/Vue.js-3.x-4FC08D)](https://vuejs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6)](https://www.typescriptlang.org/)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success)](https://github.com/ICTO-Labs/icto_v2)

A decentralized platform for token operations, multi-signature wallets, DAOs, token distribution, and launchpad services on the Internet Computer.

[Documentation](#documentation) • [Features](#features) • [Quick Start](#quick-start) • [Architecture](#architecture) • [Contributing](#contributing)

</div>

---

## 📢 Notice

> **This is the official ICTO V2 repository.**
>
> The previous version has been archived at [`icto.app-v1`](https://github.com/ICTO-Labs/icto.app-v1) for reference purposes only.
>
> ICTO V2 features a complete architectural redesign with a **factory-first, distributed architecture** that delivers:
> - 🚀 **95% reduction** in backend storage
> - ⚡ **60% faster** dashboard load times
> - 📊 **O(1) query performance** for all user lookups
> - 🏗️ **Scalable, distributed** system with no single point of failure

---

## ✨ Features

### 🏭 Factory Services

| Factory | Description | Status |
|---------|-------------|--------|
| **Token Factory** | Deploy ICRC-1/2 compliant tokens with SNS-compatible WASM | ✅ Production |
| **Multisig Factory** | Create multi-signature wallets with customizable policies | ✅ Production |
| **Distribution Factory** | Token distribution with vesting, airdrops, and locks | ✅ Production |
| **DAO Factory** | Deploy decentralized governance structures | 🚧 In Progress |
| **Launchpad Factory** | Token presale and launch platform | 🚧 In Progress |

### 🗄️ Storage Services

| Service | Description | Purpose |
|---------|-------------|---------|
| **Audit Storage** | Append-only audit trail logging | Immutable system event logs for compliance |
| **Invoice Storage** | Payment record management | Secure storage of ICP/ICRC-2 payment history |

**Key Features:**
- 🔒 **Independent Canisters** - Isolated from backend for security
- 📝 **Append-Only** - Immutable logs prevent tampering
- 🔐 **Whitelisted Access** - Only backend can write
- 📊 **Queryable** - Full history available for audit/compliance
- 💾 **Scalable** - Storage services scale independently

**Why Separate Storage?**
> Audit logs and payment records are stored in dedicated canisters (not in the backend) to ensure:
> - **Data Integrity**: Immutable logs prevent unauthorized modifications
> - **Security**: Isolated storage reduces attack surface
> - **Compliance**: Complete audit trail for regulatory requirements
> - **Scalability**: Storage grows independently of backend
> - **Backend Efficiency**: Keeps backend lean (~50MB) for fast operations

### 🎯 Core Capabilities

- **O(1) User Queries** - Instant retrieval of user-specific data via Trie-based indexes
- **Distributed Storage** - Each factory manages its own data independently
- **Version Management** - Automatic contract upgrades with rollback support
- **Payment Gateway** - ICRC-2 payment validation with ICP/cycles support
- **Callback System** - Real-time synchronization between factories and contracts
- **Audit Trail** - Complete logging via dedicated Audit Storage canister
- **Payment Records** - Secure financial data in isolated Invoice Storage canister

---

## 🏗️ Architecture

### Factory-First Design

ICTO V2 implements a revolutionary **factory-first architecture** where each factory is an autonomous service that:

- **Manages its own storage** with O(1) indexed lookups
- **Deploys and controls contracts** via dual-controller pattern
- **Maintains user indexes** (creator, participant, observer)
- **Handles upgrades** with automatic version management
- **Synchronizes state** through contract callbacks

```
┌────────────────────────────────────────────────────────────────┐
│                       Backend (Lean ~50MB)                      │
│  • Payment validation & coordination                            │
│  • Authentication & authorization                               │
│  • Factory registry management                                  │
└──────┬────────────────────────┬────────────────────────────────┘
       │                        │
       │ Coordinates            │ Delegates storage
       │                        │
       ▼                        ▼
┌─────────────┐         ┌──────────────────┐
│   Audit     │         │     Invoice      │
│  Storage    │         │     Storage      │
├─────────────┤         ├──────────────────┤
│• Audit logs │         │• Payment records │
│• Event trail│         │• ICRC-2 history  │
│• Immutable  │         │• Refund tracking │
└─────────────┘         └──────────────────┘

    ┌────────┴─────────┬─────────────┬─────────────┬─────────────┐
    │                  │             │             │             │
    ▼                  ▼             ▼             ▼             ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│Distribution  │  │  Multisig    │  │    Token     │  │     DAO      │
│  Factory     │  │   Factory    │  │   Factory    │  │   Factory    │
├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤
│• O(1) indexes│  │• O(1) indexes│  │• O(1) indexes│  │• O(1) indexes│
│• User data   │  │• User data   │  │• User data   │  │• User data   │
│• Direct query│  │• Direct query│  │• Direct query│  │• Direct query│
│• Callbacks   │  │• Callbacks   │  │• Callbacks   │  │• Callbacks   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │
   Deploys           Deploys           Deploys           Deploys
   Manages           Manages           Manages           Manages
       │                 │                 │                 │
       ▼                 ▼                 ▼                 ▼
   Contracts         Contracts         Contracts         Contracts
```

### Key Benefits

- ✅ **95% Backend Storage Reduction** - From 1.05GB to ~50MB
- ✅ **70% Cycle Cost Reduction** - Optimized queries and operations
- ✅ **O(1) Performance** - Trie-based indexes for instant lookups
- ✅ **Distributed & Scalable** - No single point of failure
- ✅ **Independent Upgrades** - Each factory upgrades independently

📚 **Full Architecture Documentation**: [documents/ARCHITECTURE.md](./documents/ARCHITECTURE.md)

---

## 🚀 Quick Start

### Prerequisites

- [DFX SDK](https://internetcomputer.org/docs/current/developer-docs/setup/install) >= 0.16.0
- [Node.js](https://nodejs.org/) >= 18.x
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ICTO-Labs/icto_v2.git
   cd icto_v2
   ```

2. **Install dependencies**
   ```bash
   # Install all dependencies (uses npm workspaces)
   npm install
   ```

3. **Start local IC replica**
   ```bash
   dfx start --clean --background
   ```

4. **Deploy all canisters**
   ```bash
   # Use the automated setup script
   chmod +x setup-icto-v2.sh
   ./setup-icto-v2.sh
   ```

   The setup script will:
   - ✅ Deploy all factory canisters
   - ✅ Deploy backend and storage services
   - ✅ Configure microservices
   - ✅ Set up whitelists
   - ✅ Add cycles to factories
   - ✅ Load WASM templates
   - ✅ Configure service fees
   - ✅ Generate frontend .env files (via setupEnv.js)
   - ✅ Run health checks

5. **Start the frontend**
   ```bash
   # Start frontend dev server (from root directory)
   npm run dev
   ```

6. **Access the application**
   - Frontend: `http://localhost:5173`
   - Backend (local): `http://localhost:4943?canisterId={backend-canister-id}`

---

## 📚 Documentation

### For Developers

| Document | Description |
|----------|-------------|
| [Architecture Guide](./documents/ARCHITECTURE.md) | System architecture and design principles |
| [Workflow Guide](./documents/WORKFLOW.md) | User flows and system interactions |
| [Module Documentation](./documents/modules/) | Detailed docs for each factory module |
| [Standards](./documents/standards/) | Development standards and patterns |
| [Deployment Guide](./documents/guides/DEPLOYMENT.md) | Production deployment instructions |

### For Contributors

| Document | Description |
|----------|-------------|
| [Contributing Guidelines](#contributing) | How to contribute to ICTO V2 |
| [Module Template](./documents/MODULE_TEMPLATE.md) | Template for new modules |
| [Testing Guide](./documents/guides/TESTING.md) | Testing standards |
| [Security Guidelines](./documents/guides/SECURITY.md) | Security best practices |

### Quick Links

- 📖 [Full Documentation Index](./documents/README.md)
- 🏭 [Factory Documentation](./documents/modules/)
- 🔧 [Setup Script](./setup-icto-v2.sh)
- 📊 [Version Management](./FACTORY_VERSION_UPDATE_SYSTEM.md)

---

## 🛠️ Tech Stack

### Backend

- **Language**: [Motoko](https://internetcomputer.org/docs/current/motoko/main/motoko)
- **Platform**: [Internet Computer (IC)](https://internetcomputer.org/)
- **Storage**: Stable variables + Trie-based indexes
- **Standards**: ICRC-1, ICRC-2, SNS-compatible

### Frontend

- **Framework**: [Vue 3](https://vuejs.org/) (Composition API)
- **Language**: [TypeScript](https://www.typescriptlang.org/) (Strict mode)
- **Styling**: [TailwindCSS](https://tailwindcss.com/) + [Headless UI](https://headlessui.com/)
- **Icons**: [@lucide-vue-next](https://lucide.dev/)
- **State Management**: [Pinia](https://pinia.vuejs.org/)
- **Notifications**: [vue-sonner](https://github.com/wobsoriano/vue-sonner)
- **Dialogs**: [SweetAlert2](https://sweetalert2.github.io/)

### Integration

- **Agent**: [@dfinity/agent](https://github.com/dfinity/agent-js)
- **Identity**: Internet Identity / Plug Wallet / [Oisy Wallet](https://oisy.com)
- **API Layer**: Service pattern (factory + contract services)

---

## 📂 Project Structure

### Workspace Configuration

This project uses **npm workspaces** for efficient dependency management:

- **Root workspace**: Contains shared dependencies and scripts
- **Frontend workspace**: Located at `src/frontend`
- **Unified commands**: Run `npm install` or `npm run dev` from root

### Directory Structure

```
icto_v2/
├── package.json                     # Root workspace config
├── setupEnv.js                      # Auto-generates .env files
├── setup-icto-v2.sh                 # Complete setup script
├── src/
│   ├── motoko/                      # Backend canisters (Motoko)
│   │   ├── backend/                 # Main backend gateway
│   │   ├── token_factory/           # Token deployment factory
│   │   ├── distribution_factory/    # Distribution management
│   │   ├── multisig_factory/        # Multisig wallet factory
│   │   ├── dao_factory/             # DAO governance factory
│   │   ├── launchpad_factory/       # Token launch platform
│   │   ├── audit_storage/           # 🗄️ Audit trail storage (independent)
│   │   ├── invoice_storage/         # 💳 Payment records storage (independent)
│   │   └── shared/                  # Shared types and utils
│   │
│   └── frontend/                    # Frontend application (Vue 3)
│       ├── src/
│       │   ├── views/               # Page components
│       │   ├── components/          # Reusable components
│       │   ├── api/services/        # API service layer
│       │   ├── types/               # TypeScript definitions
│       │   ├── composables/         # Vue composables
│       │   ├── stores/              # Pinia stores
│       │   └── utils/               # Utility functions
│       │
├── documents/                       # 📚 Official documentation
│   ├── ARCHITECTURE.md              # System architecture
│   ├── WORKFLOW.md                  # User & data flows
│   ├── modules/                     # Module-specific docs
│   │   ├── multisig_factory/
│   │   ├── distribution_factory/
│   │   ├── token_factory/
│   │   ├── dao_factory/
│   │   └── launchpad_factory/
│   ├── standards/                   # Development standards
│   └── guides/                      # Practical guides
│
├── setup-icto-v2.sh                # Automated setup script
├── dfx.json                        # DFX configuration
└── README.md                       # This file
```

---

## 🧪 Development

### Quick Reference - NPM Workspaces

All commands can be run from the **root directory**:

```bash
# Install all dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Run tests
npm run test

# Type checking
npm run type-check

# Run command in specific workspace
npm run [command] --workspace=frontend
```

### Running Tests

```bash
# Backend tests (Motoko)
dfx canister call [canister] test_[function]

# Frontend tests (from root)
npm run test --workspace=frontend

# E2E tests
npm run test:e2e
```

### Code Generation

```bash
# Generate Candid declarations
npm run generate

# Generate TypeScript types from Candid
dfx generate
```

### Linting & Formatting

```bash
# Frontend linting (from root using workspaces)
npm run lint --workspace=frontend

# Type checking (from root)
npm run type-check
```

---

## 💰 Service Fees

ICTO V2 uses ICP for service fees, validated through ICRC-2 approval mechanism:

| Service | Fee (ICP) | Purpose |
|---------|-----------|---------|
| Token Factory | 1.0 | ICRC token deployment |
| Distribution Factory | 1.0 | Distribution contract deployment |
| Multisig Factory | 0.5 | Multisig wallet creation |
| DAO Factory | 5.0 | DAO deployment with governance |
| Launchpad Factory | 10.0 | Token launch platform |

**Payment Flow:**
1. User approves ICP via ICRC-2 `approve()`
2. Backend validates payment via `icrc2_allowance()`
3. Backend transfers ICP and deploys contract
4. Factory creates contract and updates indexes

---

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### For Developers

1. **Fork the repository**
   ```bash
   git clone https://github.com/ICTO-Labs/icto_v2.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Read the documentation**
   - Start with [ARCHITECTURE.md](./documents/ARCHITECTURE.md)
   - Review the module you'll work on in [documents/modules/](./documents/modules/)
   - Follow the [IMPLEMENTATION_GUIDE.md](./documents/modules/multisig_factory/IMPLEMENTATION_GUIDE.md) pattern

4. **Make your changes**
   - Follow existing code patterns
   - Add tests for new features
   - Update documentation in module CHANGELOG.md

5. **Test your changes**
   ```bash
   # Run the setup script
   ./setup-icto-v2.sh

   # Test your feature
   npm run test
   ```

6. **Submit a Pull Request**
   - Write a clear description
   - Reference any related issues
   - Ensure CI/CD passes

### Coding Standards

- **Backend (Motoko)**:
  - Use Result types for error handling
  - Document functions with /// comments
  - Follow naming conventions (see [ARCHITECTURE.md](./documents/ARCHITECTURE.md))
  - Implement O(1) indexes for user lookups

- **Frontend (Vue 3 + TypeScript)**:
  - Use Composition API
  - Strict TypeScript mode
  - TailwindCSS for styling
  - Follow component structure in existing files

### Module Development

Each module must include:
- ✅ Backend factory canister
- ✅ Contract template
- ✅ Frontend components (List, Detail, Create)
- ✅ API service layer
- ✅ TypeScript types
- ✅ Complete documentation

📚 See [MODULE_TEMPLATE.md](./documents/MODULE_TEMPLATE.md) for details.

---

## 📊 Performance Metrics

### Improvements vs V1

| Metric | V1 | V2 | Improvement |
|--------|----|----|-------------|
| Backend Storage | 1.05 GB | 50 MB | **95% reduction** |
| Dashboard Load | 3-4s | 1-2s | **60% faster** |
| Query Cycles | High | -70% | **70% reduction** |
| User Lookups | O(n) | O(1) | **Instant** |
| Contracts/User | ~400K | 2M+ | **5x increase** |

### Scalability

- ✅ **Distributed Architecture** - No single point of failure
- ✅ **Parallel Queries** - Multiple factories serve simultaneously
- ✅ **Independent Scaling** - Each factory scales independently
- ✅ **O(1) Performance** - Constant time regardless of data size

---

## 🔒 Security

- **Factory Authentication** - Only whitelisted backend can deploy
- **Dual Controller Pattern** - Factory + Owner control contracts
- **Callback Verification** - Factories verify contract callbacks
- **Payment Validation** - ICRC-2 approval required for deployments
- **Isolated Storage** - Audit logs and payments in separate canisters
- **Append-Only Logs** - Immutable audit trail prevents tampering
- **Whitelisted Access** - Only backend can write to storage services

🔐 Full security guidelines: [documents/guides/SECURITY.md](./documents/guides/SECURITY.md)

---

## 🌐 Deployment

### Local Development

```bash
# Start local replica
dfx start --clean --background

# Deploy all canisters (includes setupEnv.js)
./setup-icto-v2.sh

# Start frontend (from root - uses npm workspaces)
npm run dev
```

### Testnet Deployment

```bash
# Deploy to IC testnet
dfx deploy --network ic --with-cycles 1000000000000

# Configure production settings
dfx canister call backend setConfig --network ic
```

### Production Deployment

See [documents/guides/DEPLOYMENT.md](./documents/guides/DEPLOYMENT.md) for complete production deployment instructions.

---

## 📞 Support & Community

- **Documentation**: [documents/](./documents/)
- **Issues**: [GitHub Issues](https://github.com/ICTO-Labs/icto_v2/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ICTO-Labs/icto_v2/discussions)
- **Website**: [icto.app](https://icto.app)
- **Telegram**: [icto_app](https://t.me/icto_app)
- **X Official**: [icto_app](https://x.com/icto_app)

---

## 📜 License

Copyright © 2025 ICTO Labs. All rights reserved.

---

## 🙏 Acknowledgments

- [DFINITY Foundation](https://dfinity.org/) - Internet Computer infrastructure
- [Developer Forum ](https://forum.dfinity.org) - Internet Computer Developer Forum
- [Vue.js Team](https://vuejs.org/) - Frontend framework
- [Community Contributors](https://github.com/ICTO-Labs/icto_v2/graphs/contributors) - All contributors

---

<div align="center">

**Built with ❤️ on the Internet Computer**

[![Internet Computer](https://img.shields.io/badge/Powered%20by-Internet%20Computer-29ABE2?style=for-the-badge)](https://internetcomputer.org/)

[Documentation](./documents/README.md) • [Architecture](./documents/ARCHITECTURE.md) • [Contributing](#contributing) • [License](#license)

</div>
