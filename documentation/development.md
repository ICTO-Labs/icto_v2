# Development Guide

This guide provides instructions for setting up a local development environment for ICTO v2, running the application, and deploying it to the Internet Computer.

## Prerequisites

Before you begin, ensure you have the following tools installed on your system:

- **DFINITY Canister SDK (dfx)**: The primary tool for building and managing applications on the Internet Computer.
- **Node.js**: A JavaScript runtime environment (version 16.x or higher).
- **Motoko**: The Motoko compiler is included with the DFINITY Canister SDK.
- **Git**: For version control.

## Setting Up the Local Environment

1.  **Clone the Repository**:

    ```bash
    git clone https://github.com/ICTO-Labs/icto_v2.git
    cd icto_v2
    ```

2.  **Install Frontend Dependencies**:

    The frontend project is managed as an npm workspace. Install the dependencies from the root of the project:

    ```bash
    npm install
    ```

## Starting the Application Locally

To run the application on your local machine, you will need to start the local replica (a simulated Internet Computer environment) and deploy the canisters.

1.  **Start the Local Replica**:

    Open a new terminal window and run the following command to start the replica in the background:

    ```bash
    dfx start --background
    ```

2.  **Deploy and Configure Canisters**:

    The project includes a comprehensive setup script that deploys all the necessary canisters and configures them to work together. Run this script from the root of the project:

    ```bash
    ./setup-icto-v2.sh
    ```

    This script will:
    - Deploy all Motoko canisters (`backend`, `token_deployer`, etc.).
    - Get the principal IDs of the deployed canisters.
    - Add the necessary cycles to the `token_deployer` canister.
    - Whitelist the `backend` canister in all other service canisters to allow communication.
    - Configure the `backend` canister with the IDs of the other microservices.

3.  **Start the Frontend Development Server**:

    Once the canisters are deployed, you can start the frontend development server. This will also set up the necessary environment variables for the frontend to communicate with the local canisters.

    ```bash
    npm run dev
    ```

    This command will start a Vite development server, typically at `http://localhost:8080`. You can now access the application in your web browser.

## Deployment to the Internet Computer

To deploy the application to the live Internet Computer network, you will need to have cycles in your wallet.

1.  **Deploy to the `ic` Network**:

    Use the `dfx deploy` command with the `--network ic` flag:

    ```bash
    dfx deploy --network ic
    ```

    This will deploy all the canisters defined in `dfx.json` to the mainnet.

2.  **Run the Setup Script on `ic`**:

    After deploying, you will need to run the setup script on the `ic` network to configure the canisters. You may need to modify the `setup-icto-v2.sh` script to work with the `ic` network or run the commands manually.

## Running Tests

The project includes a number of test scripts in the `scripts/` directory. These are shell scripts that test various aspects of the backend functionality.

**Example:** To test the token deployment flow, you can run:

```bash
./scripts/test_backend_token_deployer_integration.sh
```

Before running these tests, make sure you have deployed the canisters locally.

## Troubleshooting Common Issues

- **Canister Not Found**: If you get an error that a canister is not found, make sure you have run `dfx deploy` and that the local replica is running.
- **Frontend Not Connecting to Backend**: Check the browser's developer console for any errors. Ensure that the canister IDs in your `.env` file are correct. The `npm run dev` script should handle this automatically.
- **Cycles-Related Errors**: If you are deploying to the `ic` network, make sure your wallet has enough cycles to create the canisters. You can check your balance with `dfx wallet balance`.
