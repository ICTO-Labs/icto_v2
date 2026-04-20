# ICTO V2: Frontend Architecture

**Version:** 1.0
**Last Updated:** 2025-11-17
**Status:** Official

---

## 1. Overview & Guiding Principles

The ICTO V2 frontend is a modern, modular, and performant **Single-Page Application (SPA)** built with **Vue.js** and **TypeScript**. It serves as the primary user interface for the entire ICTO ecosystem.

The architecture is guided by three core principles:

1.  **Performance First**: Employing an intelligent, asymmetric data-fetching strategy to ensure a fast and responsive user experience.
2.  **Modularity & Scalability**: Structuring the codebase to mirror the backend's "factory-first" domain separation, making it easy to add or modify features.
3.  **Developer Experience**: Utilizing a strong type system (TypeScript) and modern tooling to ensure code quality, maintainability, and ease of development.

---

## 2. Technology Stack

| Category      | Technology                                    | Purpose                                       |
|---------------|-----------------------------------------------|-----------------------------------------------|
| **Framework** | [Vue 3](https://vuejs.org/) (with Composition API) | Core application framework.                   |
| **Language**  | [TypeScript](https://www.typescriptlang.org/)     | Strict typing for code quality and safety.    |
| **Styling**   | [TailwindCSS](https://tailwindcss.com/)           | Utility-first CSS framework for rapid UI dev. |
| **UI Kit**    | [Headless UI](https://headlessui.com/)          | Unstyled, accessible UI components.           |
| **State Mgt** | [Pinia](https://pinia.vuejs.org/)               | Official state management library for Vue 3.  |
| **IC Agent**  | `@dfinity/agent`                              | Interacting with the Internet Computer.       |
| **Identity**  | Internet Identity / Plug Wallet               | User authentication.                          |
| **Build Tool**| [Vite](https://vitejs.dev/)                     | Fast and modern frontend build tooling.       |

---

## 3. Core Architectural Concept: Asymmetric Data Flow

The single most important architectural decision in the frontend is the **asymmetric data flow**. This strategy is designed to maximize both security and performance by treating write and read operations differently.

### Write Operations (Via Backend Gateway)

Any action that modifies state or incurs a cost (e.g., deploying a contract, adding a DAO member, creating a proposal) is channeled **through the Backend Gateway**.

```
Frontend -> Backend.createToken() -> TokenFactory.createContract()
```

-   **Why?** This leverages the backend's crucial role as a **secure payment gate**. It ensures every state-changing operation is properly authenticated, authorized, and paid for before execution. The frontend is never trusted to perform write operations directly on the factories.

### Read Operations (Directly to Factories)

Any action that only fetches data (e.g., listing a user's tokens, viewing DAO proposals, checking a multisig balance) is sent **directly from the frontend to the relevant Autonomous Factory**.

```
Frontend -> TokenFactory.getMyContracts()
Frontend -> DAOFactory.getProposals()
```

-   **Why?** This strategy bypasses the backend, which would otherwise become a bottleneck. It allows the frontend to leverage the factories' high-performance `O(1)` indexes for near-instant data retrieval. It also enables fetching data from multiple factories in parallel, dramatically speeding up the loading of complex dashboards.

This asymmetric pattern is the key to achieving a fast, scalable, and secure application.

---

## 4. Directory & Code Structure

The frontend's directory structure is organized by feature domains, mirroring the backend architecture.

```
src/
├── api/
│   ├── canisters/      # Raw canister actor interfaces
│   └── services/       # Business logic layer for canister interaction
├── assets/             # Static assets (images, fonts)
├── components/
│   ├── common/         # Shared, reusable components (buttons, modals)
│   └── [feature]/      # Components specific to a feature (e.g., /token, /dao)
├── composables/        # Reusable Vue Composition API functions (e.g., useWallet)
├── router/             # Vue Router configuration
├── stores/             # Pinia state management stores (e.g., token.ts, dao.ts)
├── types/              # TypeScript type definitions
├── utils/              # Utility functions
└── views/              # Top-level page components, organized by feature
```

### Key Directories Explained

-   **`api/services/`**: This is the abstraction layer for all Internet Computer interactions. Instead of components calling `actor.call()` directly, they use a service (e.g., `tokenService.getMyTokens()`). This centralizes canister interaction logic, makes it reusable, and simplifies component code.

-   **`stores/`**: Contains all Pinia stores. Each business domain (e.g., `token`, `dao`, `multisig`, `user`) has its own store. This encapsulates state and actions related to that domain, preventing a single monolithic store and promoting modularity.

-   **`views/` & `components/`**: These are organized by feature. For example, all token-related pages are in `views/token/`, and all reusable token-related components are in `components/token/`. This makes it very easy to locate and work on code for a specific part of the application.

---

## 5. State Management with Pinia

State management is handled by Pinia, following a modular, domain-driven approach.

-   **One Store Per Domain**: Each major feature (`auth`, `user`, `token`, `dao`, etc.) has its own dedicated store.
-   **Responsibilities of a Store**:
    -   **State**: Holds the reactive data for that domain (e.g., `userTokens`, `selectedDAO`).
    -   **Getters**: Computed properties derived from the state (e.g., `activeTokens`, `completedProposals`).
    -   **Actions**: Functions that perform asynchronous operations (e.g., calling an API service) and mutate the state.

**Example Pinia Store (`token.ts`):**

```typescript
import { defineStore } from 'pinia';
import { tokenService } from '@/api/services/token';
import type { TokenInfo } from '@/types';

export const useTokenStore = defineStore('token', {
  state: () => ({
    userTokens: [] as TokenInfo[],
    isLoading: false,
  }),
  getters: {
    // Example getter
    fungibleTokens: (state) => state.userTokens.filter(t => t.standard === 'ICRC1'),
  },
  actions: {
    async fetchUserTokens() {
      this.isLoading = true;
      try {
        // Calls the abstracted service layer
        const tokens = await tokenService.getMyTokens();
        this.userTokens = tokens;
      } catch (error) {
        console.error("Failed to fetch user tokens:", error);
      } finally {
        this.isLoading = false;
      }
    },

    async deployToken(args: DeployArgs) {
      // Note: Write operations go through the backend service
      return await backendService.deployToken(args);
    }
  },
});
```
This structure ensures that all logic related to fetching, caching, and managing token data is centralized and reusable across the application.

---

## 6. Related Documentation

-   **[ECOSYSTEM_OVERVIEW.md](./ECOSYSTEM_OVERVIEW.md)**: For understanding how the frontend fits into the larger ICTO V2 architecture.
-   **[ARCHITECTURE.md](./ARCHITECTURE.md)**: For details on the backend and factory canisters that the frontend interacts with.
