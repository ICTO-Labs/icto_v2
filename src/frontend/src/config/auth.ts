import { createPNP, type PNP, type GlobalPnpConfig } from "@windoge98/plug-n-play";

// Canister Imports
import {
    canisterId as backendCanisterId,
    idlFactory as backendIDL,
} from "../../../declarations/backend";
import type { _SERVICE as _BACKEND } from "../../../declarations/backend/backend.did.d.ts";
import { canisterId as icpCanisterId } from "../../../declarations/icp_ledger";
import { idlFactory as icrc2IDL } from "../../../declarations/icp_ledger/icp_ledger.did.js";
import type { _SERVICE as _ICRC2_SERVICE } from "../../../declarations/icp_ledger/icp_ledger.did.d.ts";
import { idlFactory as icpIDL } from "../../../declarations/icp_ledger/icp_ledger.did.js";
import type { _SERVICE as _ICP_SERVICE } from "../../../declarations/icp_ledger/icp_ledger.did.d.ts";
import { IDL } from "@dfinity/candid";


// Consolidated canister types
export type CanisterType = {
    BACKEND: _BACKEND;
    ICP_LEDGER: _ICP_SERVICE;
    ICRC2_LEDGER: _ICRC2_SERVICE;
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
};

// --- PNP Initialization ---
let globalPnp: PNP | null = null;
const isDev = import.meta.env.DFX_NETWORK === "local";
console.log('IS_DEV', isDev)

const frontendCanisterId = "3ldz4-aiaaa-aaaar-qaina-cai";

const delegationTargets = [
    backendCanisterId,
].filter(Boolean);


export function initializePNP(): PNP {
    if (globalPnp) {
        return globalPnp;
    }
    try {
        // Create a stable configuration object
        const config = {
            dfxNetwork: 'local',
            replicaPort: 4943, // Replica port for local development
            frontendCanisterId,
            timeout: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000), // 30 days
            delegationTimeout: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000), // 30 days
            delegationTargets,
            derivationOrigin: "https://icto.app",
            adapters: {
                ii: {
                    enabled: true,
                    localIdentityCanisterId: "rdmx6-jaaaa-aaaaa-aaadq-cai",
                },
                plug: {
                    enabled: true,
                },
                nfid: {
                    enabled: true,
                    rpcUrl: "https://nfid.one/rpc",
                },
                oisy: {
                    enabled: true,
                    signerUrl: "https://oisy.com/sign",
                }
            },
            localStorageKey: "ICTO_PNP_STATE",
        };

        // Initialize PNP with the stable config
        globalPnp = createPNP(config);

        return globalPnp;
    } catch (error) {
        console.error("Error initializing PNP:", error);
        throw error;
    }
}

export function getPnpInstance(): PNP {
    // Ensures initialization happens if called before explicit initialization
    if (!globalPnp) {
        return initializePNP();
    }
    return globalPnp;
}

// --- Exported PNP Instance ---
export const pnp = getPnpInstance();
