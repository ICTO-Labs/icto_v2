#!/usr/local/bin/ic-repl --replica local
load "prelude.sh";
identity laking "~/.config/dfx/identity/laking/identity.pem";


import multisigContract = "x4hhs-wh777-77774-qaaka-cai" as "/Users/fern/Coding/icto_v2/.dfx/local/canisters/multisig_contract/multisig_contract.did";

let wasm = file("/Users/fern/Coding/icto_v2/.dfx/local/canisters/multisig_contract/multisig_contract.wasm");

let init = encode multisigContract.__init_args(
    record {
        id = "x4hhs-wh777-77774-qaaka-cai";
        "config" = record {
            name = "Upgraded Multisig Wallet";
            description = opt "Wallet upgraded via script";
            threshold = 2;
            signers = vec {
                record {
                    "principal" = principal "kdwnu-vuw4u-wrtin-wa45p-jqx25-zu7td-hcqif-ahocs-frz7g-7oo2c-zae";
                    name = opt "Wallet Owner";
                    role = variant { Owner };
                };
                record {
                    "principal" = principal "jcg5j-otzki-wldwv-o5dgs-vs4xu-v2on4-ldvbf-7uk5f-foggx-t5gyp-mae";
                    name = opt "Jena";
                    role = variant { Signer };
                };
                record {
                    "principal" = principal "lekqg-fvb6g-4kubt-oqgzu-rd5r7-muoce-kppfz-aaem3-abfaj-cxq7a-dqe";
                    name = opt "Fern";
                    role = variant { Signer };
                };
            };
            requiresTimelock = false;
            timelockDuration = opt 172800000000000;
            dailyLimit = opt 1000000000000;
            emergencyContactDelay = opt 86400000000000;
            allowRecovery = true;
            recoveryThreshold = opt 3;
            maxProposalLifetime = 604800000000000;
            requiresConsensusForChanges = true;
            allowObservers = true;
            isPublic = false;
        };
        "creator" = principal "kdwnu-vuw4u-wrtin-wa45p-jqx25-zu7td-hcqif-ahocs-frz7g-7oo2c-zae";
        factory = principal "xad5d-bh777-77774-qaaia-cai";
    }
);

let cid = upgrade(multisigContract, wasm, init);

"Upgrade completed for multisig contract"
