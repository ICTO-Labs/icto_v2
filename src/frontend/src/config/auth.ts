import { createPNP, type PNP, type GlobalPnpConfig } from "@windoge98/plug-n-play";
import { canisters } from "./canisters";

// --- PNP Initialization ---
let globalPnp: PNP | null = null;
const isDev = import.meta.env.VITE_DFX_NETWORK === "local";
console.log('IS_DEV', import.meta.env.VITE_DFX_NETWORK)

const frontendCanisterId = import.meta.env.VITE_FRONTEND_CANISTER_ID;

const delegationTargets = [
    canisters.backend.canisterId,
    canisters.icp.canisterId,
].filter(Boolean);


export function initializePNP(): PNP {
    if (globalPnp) {
        return globalPnp;
    }
    try {
        // Create a stable configuration object
        const config = {
            dfxNetwork: 'local',
            hostUrl: isDev ? "http://localhost:4943" : "https://icp0.io",
            replicaPort: 4943, // Replica port for local development
            frontendCanisterId,
            timeout: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000), // 30 days
            delegationTimeout: BigInt(30 * 24 * 60 * 60 * 1000 * 1000 * 1000), // 30 days
            delegationTargets,
            derivationOrigin: isDev ? "http://localhost:5173" : "https://" + frontendCanisterId + ".icp0.io",
            identityProvider: isDev ? "http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943" : "https://identity.ic0.app",

            adapters: {
                ii: {
                    enabled: true,
                    config: {
                        localIdentityCanisterId: import.meta.env.VITE_INTERNET_IDENTITY_CANISTER_ID,
                        identityProvider: isDev ? "http://rdmx6-jaaaa-aaaaa-aaadq-cai.localhost:4943" : "https://identity.ic0.app",
                    }
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
