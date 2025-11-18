# ICTO V2 - Technical Documentation

**Version:** 2.1
**Last Updated:** 2025-11-17
**Status:** Official

---

## 📚 Documentation Index

Welcome to the official technical documentation for the ICTO V2 ecosystem. This documentation is designed for developers, contributors, and AI agents. It is structured in a modular way to optimize for context-efficient learning and development.

### 🎯 Recommended Reading Path

For the best understanding of the project, we recommend reading the core documents in the following order:

1.  **[ECOSYSTEM_OVERVIEW.md](./ECOSYSTEM_OVERVIEW.md)**: Start here for a high-level understanding of the project's vision and its four main pillars.
2.  **[ARCHITECTURE.md](./ARCHITECTURE.md)**: A deep dive into the "factory-first" architecture, internal backend microservices, and data flows.
3.  **[FRONTEND_ARCHITECTURE.md](./FRONTEND_ARCHITECTURE.md)**: An essential guide to understanding the structure and core concepts of the Vue.js frontend application.
4.  **[DEVELOPER_WORKFLOW.md](./DEVELOPER_WORKFLOW.md)**: The mandatory guide for all contributors, outlining the setup, `CHANGELOG` process, and best practices.

---

## 📖 Core Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| **[ECOSYSTEM_OVERVIEW.md](./ECOSYSTEM_OVERVIEW.md)** | A high-level introduction to the ICTO V2 ecosystem and its core components. | **Everyone** |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Detailed breakdown of the backend, factories, and data flows. | Developers, Architects |
| **[FRONTEND_ARCHITECTURE.md](./FRONTEND_ARCHITECTURE.md)** | Explains the Vue.js SPA, including its structure, state management, and data flow patterns. | Frontend Developers |
| **[DEVELOPER_WORKFLOW.md](./DEVELOPER_WORKFLOW.md)** | Outlines the mandatory contribution process, including setup and the `CHANGELOG` workflow. | **All Contributors** |
| [BACKEND_FACTORY_INTEGRATION.md](./BACKEND_FACTORY_INTEGRATION.md) | Technical details on the API and security patterns between the backend and factories. | Backend Developers, AI Agents |

---

## 📘 Guides & Standards

Practical guides for common tasks and standards that apply across all modules.

| Guide / Standard | Description |
|---|---|
| **[SETUP_GUIDE.md](./SETUP_GUIDE.md)** | A step-by-step guide to using the `setup-icto-v2.sh` script for local development. |
| **[VERSION_MANAGEMENT.md](./VERSION_MANAGEMENT.md)** | Details the robust system for versioning and upgrading smart contracts. |
| [More guides to come...] | |

---

## 🧩 Modules

Each module represents a core business domain within ICTO V2 and has its own self-contained documentation.

### Factory Modules

| Module | Status | Description |
|--------|--------|-------------|
| [Distribution Factory](./modules/distribution_factory/) | ✅ Completed | Token distribution management system |
| [Multisig Factory](./modules/multisig_factory/) | 🚧 In Progress | Multi-signature wallet system |
| [Token Factory](./modules/token_factory/) | ✅ Completed | ICRC token creation and management |
| [DAO Factory](./modules/dao_factory/) | 🚧 In Progress | Decentralized governance system |
| [Launchpad Factory](./modules/launchpad_factory/) | ✅ Completed | Token launch and presale platform |

### Module Documentation Structure

Each module's documentation typically includes:
- **`README.md`**: An overview of the module's features and purpose.
- **`CHANGELOG.md`**: **(Mandatory)** A complete history of all changes made to the module.
- **`FILES.md`**: A quick reference mapping business logic to specific source code files.
- **`IMPLEMENTATION_GUIDE.md`**: A technical guide with code snippets for common development tasks.

---

## 🤖 For AI Agents: The Workflow

AI agents are expected to follow the **[DEVELOPER_WORKFLOW.md](./DEVELOPER_WORKFLOW.md)** strictly. The key steps are:

1.  **Identify Module**: Determine the primary module for the task.
2.  **Consult Module Docs**: Read the module's `README.md`, `CHANGELOG.md`, `FILES.md`, and `IMPLEMENTATION_GUIDE.md` to load the necessary context.
3.  **Create `CHANGELOG` Entry**: **Before starting work**, create an "In Progress" entry in the module's `CHANGELOG.md`.
4.  **Implement Changes**: Perform the coding task.
5.  **Update `CHANGELOG` Entry**: **After completing work**, update the entry with the final status, a summary, and a list of modified files.

This workflow is not optional; it is essential for maintaining the project's integrity and auditability.
