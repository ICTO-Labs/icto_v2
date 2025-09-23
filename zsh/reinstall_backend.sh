#! /bin/bash

# Reinstall the backend

# dfx deploy backend --mode=reinstall

# Add canister ids to the backend

# Get canister ids from the .env file

echo "Getting canister ids from the dfx canister"
BACKEND_ID=$(dfx canister id backend)
TOKEN_ID=$(dfx canister id token_factory)
AUDIT_ID=$(dfx canister id audit_storage)
INVOICE_ID=$(dfx canister id invoice_storage)
TEMPLATE_ID=$(dfx canister id template_factory)
DISTRIBUTION_ID=$(dfx canister id distribution_factory)
DAO_ID=$(dfx canister id dao_factory)
MULTISIG_ID=$(dfx canister id multisig_factory)
LAUNCHPAD_ID=$(dfx canister id launchpad_factory)

echo "Backend: $BACKEND_ID"
echo "Token Factory: $TOKEN_ID"
echo "Audit Storage: $AUDIT_ID"
echo "Invoice Storage: $INVOICE_ID"
echo "Template Factory: $TEMPLATE_ID"
echo "Distribution Factory: $DISTRIBUTION_ID"
echo "DAO Factory: $DAO_ID"
echo "Multisig Factory: $MULTISIG_ID"
echo "Launchpad Factory: $LAUNCHPAD_ID"
dfx canister call backend setCanisterIds "(record {
    tokenFactory = opt principal \"$TOKEN_ID\";
    auditStorage = opt principal \"$AUDIT_ID\";
    invoiceStorage = opt principal \"$INVOICE_ID\";
    templateFactory = opt principal \"$TEMPLATE_ID\";
    distributionFactory = opt principal \"$DISTRIBUTION_ID\";
    daoFactory = opt principal \"$DAO_ID\";
    multisigFactory = opt principal \"$MULTISIG_ID\";
    launchpadFactory = opt principal \"$LAUNCHPAD_ID\";
})"

echo "Canister ids added to the backend successfully"
echo "================================================"
echo "Adding backend to the whitelist of the microservices"

## Add backend to the whitelist of the token factory
echo "Adding backend to the whitelist of the token factory: $TOKEN_ID"
dfx canister call token_factory addToWhitelist "(principal \"$BACKEND_ID\")"

## Add backend to the whitelist of the audit storage
echo "Adding backend to the whitelist of the audit storage: $AUDIT_ID"
dfx canister call audit_storage addToWhitelist "(principal \"$BACKEND_ID\")"
## Add backend to the whitelist of the invoice storage
echo "Adding backend to the whitelist of the invoice storage: $INVOICE_ID"
dfx canister call invoice_storage addToWhitelist "(principal \"$BACKEND_ID\")"
## Add backend to the whitelist of the template factory

echo "Adding backend to the whitelist of the template factory: $TEMPLATE_ID"
dfx canister call template_factory addToWhitelist "(principal \"$BACKEND_ID\")"
## Add backend to the whitelist of the distribution factory
echo "Adding backend to the whitelist of the distribution factory: $DISTRIBUTION_ID"
dfx canister call distribution_factory addToWhitelist "(principal \"$BACKEND_ID\")"
## Add backend to the whitelist of the multisig factory
echo "Adding backend to the whitelist of the multisig factory: $MULTISIG_ID"
dfx canister call multisig_factory addToWhitelist "(principal \"$BACKEND_ID\")"
## Add backend to the whitelist of the dao factory
echo "Adding backend to the whitelist of the dao factory: $DAO_ID"
dfx canister call dao_factory addToWhitelist "(principal \"$BACKEND_ID\")"
## Add backend to the whitelist of the launchpad factory
echo "Adding backend to the whitelist of the launchpad factory: $LAUNCHPAD_ID"
dfx canister call launchpad_factory addToWhitelist "(principal \"$BACKEND_ID\")"
echo "================================================"
echo "Canister ids added to the backend"
echo "================================================"