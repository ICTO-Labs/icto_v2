# ICTO V2: Developer Workflow & Best Practices

**Version:** 1.0
**Last Updated:** 2025-11-17
**Status:** Official

---

## 1. Introduction

This document outlines the standard workflow and best practices for developers and AI agents contributing to the ICTO V2 ecosystem. Adhering to these guidelines is essential for maintaining code quality, ensuring project consistency, and enabling efficient collaboration.

The workflow is built upon three pillars:
1.  **Automated Setup**: A consistent and repeatable local development environment.
2.  **Mandatory Change Tracking**: A strict process for documenting every change.
3.  **Context-Optimized Development**: A modular approach to working on the codebase.

---

## 2. Local Development Setup

A comprehensive setup script, `setup-icto-v2.sh`, is provided to automate the entire local environment configuration.

### Quick Start

The recommended way to start is using the script's interactive mode.

```bash
# Make the script executable
chmod +x setup-icto-v2.sh

# Run the interactive setup
./setup-icto-v2.sh
```

Follow the on-screen menu. For a fresh, first-time setup, choose option `[99] Run Complete Setup`.

### Key Setup Steps

The script handles all necessary steps, including:
-   Deploying all canisters (`backend`, factories, storage services).
-   Funding the factories with cycles.
-   Configuring the whitelists (e.g., adding the backend's Principal to each factory's whitelist).
-   Loading the required token WASM into the `TokenFactory`.
-   Configuring the backend's internal microservices.
-   Generating the `.env` file for the frontend application.

> **Note:** For a detailed explanation of each step, refer to the **[SETUP_GUIDE.md](./SETUP_GUIDE.md)**.

---

## 3. The Mandatory `CHANGELOG.md` Workflow

**This is the most critical process for all contributors.** Every task, whether it's a new feature, a bug fix, or a refactor, **must** be documented in the `CHANGELOG.md` of the relevant module *before* and *after* the work is done.

This process creates a transparent, auditable, and easily understandable history of the project's evolution.

### The Workflow Steps

1.  **Identify the Module**: Determine which primary module your task relates to (e.g., `multisig_factory`, `launchpad_factory`, `frontend-dashboard`).

2.  **Before Coding - Create an Entry**:
    -   Navigate to the module's directory (e.g., `documents/modules/multisig_factory/`).
    -   Open `CHANGELOG.md`.
    -   Create a new entry at the top of the file using the standard template.

    **Template:**
    ```markdown
    ### YYYY-MM-DD - [Your Task Title]

    **Status:** 🚧 In Progress
    **Agent/Developer:** [Your Name/ID]
    **Type:** [Enhancement / Bug Fix / Refactor / Documentation]

    **Task Checklist:**
    - [ ] [Sub-task 1: e.g., Create the Vue component]
    - [ ] [Sub-task 2: e.g., Add the backend logic]
    - [ ] [Sub-task 3: e.g., Write unit tests]

    **Summary:**
    *(Leave blank for now)*

    **Files Modified:**
    *(Leave blank for now)*

    **Breaking Changes:**
    *(Leave blank for now)*
    ```

3.  **Perform the Work**: Write your code, implement your feature, or fix your bug.

4.  **After Coding - Update the Entry**:
    -   Return to your `CHANGELOG.md` entry.
    -   Update the status to `✅ Completed` or `❌ Failed`.
    -   Mark all checkboxes in your task list as complete (`[x]`).
    -   Write a concise **Summary** (2-3 sentences) describing the change from a user or developer perspective. What was the problem, and what is the solution?
    -   List all **Files Modified**, created, or deleted. This is crucial for code reviewers.
    -   Explicitly state any **Breaking Changes**. If there are none, write "None".

### Why is this so important?

-   **Audit Trail**: It provides a perfect history of who changed what, when, and why.
-   **Code Review**: It gives reviewers immediate context, saving them significant time.
-   **Knowledge Sharing**: It helps other developers (and AI agents) understand recent changes without having to read through all the code.
-   **Accountability**: It encourages thoughtful planning and clear documentation of work.

---

## 4. Context-Optimized Development

The ICTO V2 codebase is large, but the documentation is structured to be **context-efficient**. You are not expected to load the entire project into your mental model (or an AI agent's context window).

### The Recommended Approach

When starting a task for a specific module:

1.  **Start with the Module Documentation**: Navigate to `documents/modules/[your_module]/`.
2.  **Read the `README.md`**: Get a high-level overview of the module's purpose and components.
3.  **Read the `CHANGELOG.md`**: Understand the most recent changes to see if they impact your work.
4.  **Consult the `FILES.md`**: This document maps out the key source code files for the module, preventing you from having to search for them.
5.  **Follow the `IMPLEMENTATION_GUIDE.md`**: This guide provides specific, actionable steps and code snippets for common tasks within that module.

By following this "documentation-first" approach, you can efficiently complete your task with minimal context, reducing the chance of errors and misunderstandings.

---

## 5. Testing Philosophy & Scripts

The project is supported by a comprehensive suite of test scripts located in the `scripts/` and `zsh/` directories.

-   **Run Tests Locally**: Before submitting any change, run the relevant tests to ensure your changes have not caused any regressions.
-   **Focus on Integration**: Many scripts test the end-to-end integration between components (e.g., `test_backend_payment_integration.sh`). These are invaluable for verifying real-world behavior.
-   **Add New Tests**: If you are adding a new feature, you are encouraged to add a corresponding test script that validates its functionality.
