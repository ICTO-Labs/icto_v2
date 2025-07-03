// constatns.ts

const defaultTokens = () => {
    if (import.meta.env.DFX_NETWORK === 'local') {
        return {
            icp: import.meta.env.CANISTER_ID_ICP_LEDGER,
            ckusdt: import.meta.env.CANISTER_ID_CKUSDT_LEDGER,
        };
    }
    return {
        ICP: "ryjl3-tyaaa-aaaaa-aaaba-cai",
        CKUSDT: "cngnf-vqaaa-aaaar-qag4q-cai",
        CKUSDC: "xevnm-gaaaa-aaaar-qafnq-cai",
        CKBTCM: "mxzaz-hqaaa-aaaar-qaada-cai",
        CKETH: "ss2fx-dyaaa-aaaar-qacoq-cai",
        DKP: "zfcdd-tqaaa-aaaaq-aaaga-cai",
        EXE: "rh2pm-ryaaa-aaaan-qeniq-cai",
        PARTY: "7xkvf-zyaaa-aaaal-ajvra-cai",
        MOTOKO: "k45jy-aiaaa-aaaaq-aadcq-cai",
        NICP: "buwm7-7yaaa-aaaar-qagva-cai",
        TCYCLES: "um5iw-rqaaa-aaaaq-qaaba-cai",
        GLDGov: "tyyy3-4aaaa-aaaaq-aab7a-cai",
        GLDT: "6c7su-kiaaa-aaaar-qaira-cai",
        ALEX: "ysy5f-2qaaa-aaaap-qkmmq-cai",
        BOB: "7pail-xaaaa-aaaas-aabmq-cai",
        NTN: "f54if-eqaaa-aaaaq-aacea-cai",
        CLOUD: "pcj6u-uaaaa-aaaak-aewnq-cai",
        PANDA: "druyg-tyaaa-aaaaq-aactq-cai",
        DCD: "xsi2v-cyaaa-aaaaq-aabfq-cai"
    };
    };
    
    export const DEFAULT_TOKENS = defaultTokens();
    
    export const ICTO_BACKEND_CANISTER_ID = import.meta.env.VITE_BACKEND_CANISTER_ID;
    
    // Token Canister IDs
    export const CKUSDC_CANISTER_ID = 'xevnm-gaaaa-aaaar-qafnq-cai';
    export const CKUSDT_CANISTER_ID = import.meta.env.VITE_CANISTER_ID_CKUSDT_LEDGER;
    export const ICP_CANISTER_ID = import.meta.env.VITE_CANISTER_ID_ICP_LEDGER;