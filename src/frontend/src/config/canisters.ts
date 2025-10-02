
// Canister Imports
import {
    canisterId as backendCanisterId,
    idlFactory as backendIDL,
} from "../../../declarations/backend";
import type { _SERVICE as _BACKEND } from "../../../declarations/backend/backend.did.d.ts";
import { idlFactory as icrc2IDL } from "../../../declarations/icp_ledger/icp_ledger.did.js";
import type { _SERVICE as _ICRC2_SERVICE } from "../../../declarations/icp_ledger/icp_ledger.did.d.ts";
//Custom ICP ledger
import { canisterId as icpCanisterId } from "../api/actor/icp_ledger";
import { idlFactory as icpIDL } from "../api/actor/icp_ledger/icp_ledger.did.js";
import type { _SERVICE as _ICP_SERVICE } from "../api/actor/icp_ledger/icp_ledger.did.d.ts";
import { IDL } from "@dfinity/candid";
// DAO Contract
import {
    canisterId as daoContractCanisterId,
    idlFactory as daoContractIDL,
} from "../../../declarations/dao_contract";
import type { _SERVICE as _DAO_CONTRACT_SERVICE } from "../../../declarations/dao_contract/dao_contract.did.d.ts";
// Distribution Contract (Template)
import {
    canisterId as distributionContractCanisterId,
    idlFactory as distributionContractIDL,
} from "../../../declarations/distribution_contract";
import type { _SERVICE as _DISTRIBUTION_CONTRACT_SERVICE } from "../../../declarations/distribution_contract/distribution_contract.did.d.ts";
// Launchpad Contract
import {
    canisterId as launchpadContractCanisterId,
    idlFactory as launchpadContractIDL,
} from "../../../declarations/launchpad_contract";
import type { _SERVICE as _LAUNCHPAD_CONTRACT_SERVICE } from "../../../declarations/launchpad_contract/launchpad_contract.did.d.ts";
// Multisig Contract
import {
    canisterId as multisigContractCanisterId,
    idlFactory as multisigContractIDL,
} from "../../../declarations/multisig_contract";
import type { _SERVICE as _MULTISIG_CONTRACT_SERVICE } from "../../../declarations/multisig_contract/multisig_contract.did.d.ts";
// Token Factory
import {
    canisterId as tokenFactoryCanisterId,
    idlFactory as tokenFactoryIDL,
} from "../../../declarations/token_factory";
import type { _SERVICE as _TOKEN_FACTORY_SERVICE } from "../../../declarations/token_factory/token_factory.did.d.ts";
// Distribution Factory
import {
    canisterId as distributionFactoryCanisterId,
    idlFactory as distributionFactoryIDL,
} from "../../../declarations/distribution_factory";
import type { _SERVICE as _DISTRIBUTION_FACTORY_SERVICE } from "../../../declarations/distribution_factory/distribution_factory.did.d.ts";
// Multisig Factory
import {
    canisterId as multisigFactoryCanisterId,
    idlFactory as multisigFactoryIDL,
} from "../../../declarations/multisig_factory";
import type { _SERVICE as _MULTISIG_FACTORY_SERVICE } from "../../../declarations/multisig_factory/multisig_factory.did.d.ts";


// Consolidated canister types
export type CanisterType = {
    BACKEND: _BACKEND;
    ICP_LEDGER: _ICP_SERVICE;
    ICRC2_LEDGER: _ICRC2_SERVICE;
    DISTRIBUTION_CONTRACT: _DISTRIBUTION_CONTRACT_SERVICE;
    DISTRIBUTION_FACTORY: _DISTRIBUTION_FACTORY_SERVICE;
    DAO_CONTRACT: _DAO_CONTRACT_SERVICE;
    LAUNCHPAD_CONTRACT: _LAUNCHPAD_CONTRACT_SERVICE;
    MULTISIG_CONTRACT: _MULTISIG_CONTRACT_SERVICE;
    MULTISIG_FACTORY: _MULTISIG_FACTORY_SERVICE;
    TOKEN_FACTORY: _TOKEN_FACTORY_SERVICE;
};

export type CanisterConfigs = {
    [key: string]: {
        canisterId?: string;
        idl: IDL.InterfaceFactory;
        type?: any;
    };
};

export const canisters: CanisterConfigs = {
    backend: {
        canisterId: import.meta.env.VITE_BACKEND_CANISTER_ID,
        idl: backendIDL,
        type: {} as CanisterType["BACKEND"],
    },
    icp: {
        canisterId: import.meta.env.VITE_ICP_LEDGER_CANISTER_ID,
        idl: icpIDL,
        type: {} as CanisterType["ICP_LEDGER"],
    },
    icrc1: {
        idl: icrc2IDL,
        type: {} as CanisterType["ICRC2_LEDGER"],
    },
    icrc2: {
        idl: icrc2IDL,
        type: {} as CanisterType["ICRC2_LEDGER"],
    },
    distribution_contract: {
        canisterId: import.meta.env.VITE_DISTRIBUTION_CONTRACT_CANISTER_ID,
        idl: distributionContractIDL,
        type: {} as CanisterType["DISTRIBUTION_CONTRACT"],
    },
    dao_contract: {
        canisterId: import.meta.env.VITE_DAO_CONTRACT_CANISTER_ID,
        idl: daoContractIDL,
        type: {} as CanisterType["DAO_CONTRACT"],
    },
    launchpad_contract: {
        canisterId: import.meta.env.VITE_LAUNCHPAD_CONTRACT_CANISTER_ID,
        idl: launchpadContractIDL,
        type: {} as CanisterType["LAUNCHPAD_CONTRACT"],
    },
    multisig_contract: {
        canisterId: import.meta.env.VITE_MULTISIG_CONTRACT_CANISTER_ID,
        idl: multisigContractIDL,
        type: {} as CanisterType["MULTISIG_CONTRACT"],
    },
    token_factory: {
        canisterId: import.meta.env.VITE_TOKEN_FACTORY_CANISTER_ID,
        idl: tokenFactoryIDL,
        type: {} as CanisterType["TOKEN_FACTORY"],
    },
    distribution_factory: {
        canisterId: import.meta.env.VITE_DISTRIBUTION_FACTORY_CANISTER_ID,
        idl: distributionFactoryIDL,
        type: {} as CanisterType["DISTRIBUTION_FACTORY"],
    },
    multisig_factory: {
        canisterId: import.meta.env.VITE_MULTISIG_FACTORY_CANISTER_ID,
        idl: multisigFactoryIDL,
        type: {} as CanisterType["MULTISIG_FACTORY"],
    },
};

// Export canister IDs for easy access
export const canisterIds = {
    backend: canisters.backend.canisterId,
    icp: canisters.icp.canisterId,
    distribution_contract: canisters.distribution_contract.canisterId,
    distribution_factory: canisters.distribution_factory.canisterId,
    dao_contract: canisters.dao_contract.canisterId,
    launchpad_contract: canisters.launchpad_contract.canisterId,
    multisig_contract: canisters.multisig_contract.canisterId,
    multisig_factory: canisters.multisig_factory.canisterId,
    token_factory: canisters.token_factory.canisterId,
};