#! /bin/bash

# Reinstall the backend

dfx deploy backend --mode=reinstall

# Add canister ids to the backend

# Get canister ids from the .env file

TOKEN_ID=$(dfx canister id token_deployer)
AUDIT_ID=$(dfx canister id audit_storage)
INVOICE_ID=$(dfx canister id invoice_storage)
TEMPLATE_ID=$(dfx canister id template_deployer)

dfx canister call backend setCanisterIds "(record {
    tokenDeployer = opt principal \"$TOKEN_ID\";
    auditStorage = opt principal \"$AUDIT_ID\";
    invoiceStorage = opt principal \"$INVOICE_ID\";
    templateDeployer = opt principal \"$TEMPLATE_ID\";
})"

echo "Canister ids added to the backend"