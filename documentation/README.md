# ICTO v2 Documentation

## 1. Overview

Welcome to the official documentation for ICTO v2, a decentralized, modular, and scalable launchpad framework built on the Internet Computer. This document provides a high-level overview of the project's purpose, architecture, and technology stack.

### Project Purpose

ICTO v2 is designed to empower creators and communities by providing a robust and flexible platform for launching new tokens and projects on the Internet Computer. It aims to simplify the tokenization process, offering a seamless experience for both project owners and investors. The platform is built with scalability and maintainability in mind, allowing for future integrations and extensions, such as with the Service Nervous System (SNS).

### Key Features and Modules

The project is composed of several key modules, each encapsulated within its own canister, promoting a modular and microservices-like architecture. The main components include:

- **Backend:** The core business logic, acting as a dispatcher to other modules.
- **Token Deployer:** Manages the creation and deployment of new tokens.
- **Launchpad Deployer:** Handles the setup and configuration of token launchpads.
- **Distribution Deployer:** Manages the distribution of tokens post-launch.
- **Invoice Storage:** Stores and manages payment invoices.
- **Audit Storage:** Provides a record of all significant events for auditing purposes.
- **Frontend:** A user-friendly interface for interacting with the ICTO v2 platform.

### Technologies Used

- **Backend:** The backend is written in **Motoko**, a programming language specifically designed for the Internet Computer. It leverages the actor model and asynchronous programming to build scalable and secure services.
- **Frontend:** The frontend is a modern web application built with **Vue 3**, **TypeScript**, and **Tailwind CSS**. This combination provides a reactive, type-safe, and beautifully styled user interface.
- **Platform:** The entire application is deployed on the **Internet Computer**, a decentralized cloud platform that allows for the creation of scalable and autonomous software.

### Internal Architecture Pattern

ICTO v2 employs a **modular, multi-canister backend architecture**. The main `backend` canister acts as an entrypoint and a pipeline executor, dispatching requests to the appropriate specialized canisters (e.g., `token_deployer`, `launchpad_deployer`). This design promotes separation of concerns, improves scalability, and allows for independent upgrades of each module.

Communication between canisters is handled through **inter-canister calls**, with data serialized using **Candid**. The system is designed to be resilient, with features like idempotent operations and checkpointing to ensure that long-running processes can be resumed in case of failures.
