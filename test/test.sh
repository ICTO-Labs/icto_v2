#!/usr/local/bin/ic-repl --replica local
load "prelude.sh";
identity laking "~/.config/dfx/identity/laking/identity.pem";
import daoFactory = "tkt7n-77777-77774-qaasq-cai" as "../.dfx/local/canisters/dao_factory/dao_factory.did";
import daoContract = "s4yhg-kp777-77774-qaaxq-cai" as "../.dfx/local/canisters/dao_contract/dao_contract.did";
let DAO_ID = "s4yhg-kp777-77774-qaaxq-cai";
let wasm = file("../.dfx/local/canisters/dao_contract/dao_contract.wasm");

let init = encode daoContract.__init_args(
    record {
        rateLimits = vec {};
        delegationTimers = vec {};
        delegations = vec {};
        totalVotingPower = 0;
        tokenConfig = record {
            canisterId = principal "ryjl3-tyaaa-aaaaa-aaaba-cai";
            symbol = "ICP";
            name = "Internet Computer";
            decimals = 8;
            fee = 10000;
            managedByDAO = false;
        };
        system_params = record {
            transfer_fee = 10000;
            proposal_vote_threshold = 1000;
            proposal_submission_deposit = 100;
            timelock_duration = 172800;
            quorum_percentage = 2000;
            approval_threshold = 5000;
            max_voting_period = 604800;
            min_voting_period = 86400;
            stake_lock_periods = vec { 0; 2592000; 7776000; 31536000 };
            emergency_pause = true;
            emergency_contacts = vec { principal "neit2-bwqkk-6hylu-xkr5c-ug66s-4r3wg-kpxha-fgeaa-vhrmv-jjuy2-cqe" };
        };
        governanceLevel = variant { SemiManaged };
        customSecurity = opt record {
            maxProposalsPerHour = opt 0;
            maxStakeAmount = opt 0;
            maxProposalsPerDay = opt 0;
            maxProposalDeposit = opt 0;
            minProposalDeposit = opt 0;
            minStakeAmount = opt 0;
        };
        stakeRecords = vec {};
        emergencyState = record {
            paused = false;
            pausedBy = opt principal "neit2-bwqkk-6hylu-xkr5c-ug66s-4r3wg-kpxha-fgeaa-vhrmv-jjuy2-cqe";
            pausedAt = opt 0;
            reason = opt "test";
        };
        accounts = vec {};
        lastSecurityCheck = 0;
        executionContexts = vec {};
        comments = vec {};
        proposals = vec {};
        proposalTimers = vec {};
        totalStaked = 0;
        securityEvents = vec {};
        voteRecords = vec {};
    }
);

let cid = upgrade(daoContract, wasm, init);
