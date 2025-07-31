# Frontend Structure

## Introduction

The frontend of ICTO v2 is a modern, responsive, and user-friendly web application designed to interact seamlessly with the backend canisters on the Internet Computer. It provides a comprehensive interface for users to manage their projects, deploy tokens, and participate in launchpad events.

## Framework and Technologies

The frontend is built using a stack of modern web technologies:

- **Vue 3**: A progressive JavaScript framework for building user interfaces. The application is built using the Composition API, which allows for more flexible and reusable code.
- **TypeScript**: A statically typed superscript of JavaScript that adds type safety to the codebase, reducing bugs and improving developer experience.
- **Tailwind CSS**: A utility-first CSS framework that allows for rapid development of custom user interfaces. It is used for all styling within the application.
- **Vite**: A modern frontend build tool that provides a faster and leaner development experience compared to older tools like Webpack.

## Folder Structure and Naming Convention

The frontend source code is located in the `src/frontend/src/` directory. The structure is organized by feature and functionality:

```
src/frontend/src/
├── assets/         # Static assets like CSS and images
├── components/     # Reusable Vue components, organized by feature
│   ├── common/     # Basic, general-purpose components
│   ├── layout/     # Components related to the overall page structure
│   └── ...         # Feature-specific components (e.g., token, launchpad)
├── composables/    # Reusable composition functions (Vue 3 hooks)
├── router/         # Vue Router configuration
├── stores/         # Pinia state management stores
├── views/          # Top-level components for each page/route
├── App.vue         # The root Vue component
└── main.ts         # The main entry point of the application
```

- **`components/`**: This is one of the most important directories. It contains all the reusable UI elements of the application. They are further organized into subdirectories based on their domain (e.g., `components/token`, `components/launchpad`).
- **`composables/`**: These are Vue 3's equivalent of React hooks. They contain reusable stateful logic that can be shared across multiple components (e.g., `useAuth.ts`, `useDeploy.ts`).
- **`router/`**: Defines all the application routes, mapping URLs to the corresponding `view` components.
- **`stores/`**: Contains the Pinia stores. Each store is responsible for managing a specific piece of the application's global state (e.g., `auth.ts`, `project.ts`).
- **`views/`**: These are the main components for each page. A view is typically composed of multiple smaller components from the `components/` directory.

## Routing and Layout System

Routing is handled by **Vue Router**. The routes are defined in `src/router/index.ts`. The application uses a nested routing system to create complex layouts.

The main layout is defined in the `App.vue` component, which includes the primary `RouterView`. The overall page structure, including the sidebar and header, is managed by layout components found in `src/components/layout/`.

## API Communication with Backend

Communication with the Internet Computer backend is managed through the **`@dfinity/agent-js`** library. This library provides the tools to create an "actor" that can call the public functions of a canister.

- **Actor Creation**: An actor is created for each backend canister that the frontend needs to interact with. This is typically done in a dedicated service file (e.g., `src/api/services/backend.ts`).
- **CBOR Handling**: The `@dfinity/agent-js` library automatically handles the serialization and deserialization of data between the frontend (JavaScript objects) and the backend (Candid). This process is transparent to the frontend developer.
- **Asynchronous Calls**: All calls to the backend are asynchronous and return a `Promise`. The frontend uses `async/await` to handle these calls gracefully.

## Authentication

Authentication is handled using **Internet Identity**, the standard authentication provider for the Internet Computer. The `@dfinity/auth-client` library is used to integrate with Internet Identity.

The authentication flow is managed by the `auth` store in Pinia (`src/stores/auth.ts`).

1.  The user clicks a "Login" button.
2.  The `authClient.login()` method is called, which opens the Internet Identity login page in a new tab.
3.  After the user successfully authenticates, they are redirected back to the application.
4.  The `authClient` is now authenticated, and it holds the user's `Identity`.
5.  This identity is automatically used by the agent to sign all subsequent calls to the backend, proving the user's identity.

## State Management

Global state management is handled by **Pinia**, the official state management library for Vue 3. Pinia provides a simple and intuitive way to create shared stores.

- **Stores**: Each store is a separate file in the `src/stores/` directory (e.g., `auth.ts`, `ui.ts`).
- **State**: The `state` is the central part of the store, containing the data.
- **Getters**: `getters` are like computed properties for stores. They are used to derive state.
- **Actions**: `actions` are methods that can be called to modify the state.

Pinia is used to manage global state such as the authenticated user, UI state (e.g., whether a modal is open), and cached data from the backend.

## Environment Configuration and Build System

- **Environment Variables**: The application uses `.env` files to manage environment-specific variables (e.g., canister IDs). The main configuration is in `.env.development`.
- **Build System**: **Vite** is used to build the application for production. The `vite build` command compiles the Vue components and TypeScript code into static HTML, CSS, and JavaScript files that can be deployed to the `frontend` asset canister.
