
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


// Consolidated canister types
export type CanisterType = {
    BACKEND: _BACKEND;
    ICP_LEDGER: _ICP_SERVICE;
    ICRC2_LEDGER: _ICRC2_SERVICE;
    DISTRIBUTION_CONTRACT: _DISTRIBUTION_CONTRACT_SERVICE;
    DAO_CONTRACT: _DAO_CONTRACT_SERVICE;
    LAUNCHPAD_CONTRACT: _LAUNCHPAD_CONTRACT_SERVICE;
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
};