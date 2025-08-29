import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Array "mo:base/Array";

import ConfigTypes "../systems/config/ConfigTypes";
import MicroserviceTypes "../systems/microservices/MicroserviceTypes";
import MicroserviceService "../systems/microservices/MicroserviceService";
import DAOFactoryTypes "./DAOFactoryTypes";
import DAOFactoryInterface "./DAOFactoryInterface";
import DAOTypes "../../../shared/types/DAOTypes";
import ICRCUtility "../../../shared/utils/ICRC";

module DAOFactoryService {

    // ==================================================================================================
    // DAO FACTORY SERVICE
    // ==================================================================================================

    // Prepares deployment call to DAO factory canister
    public func prepareDeployment(
        state: (), // DAO factory doesn't need internal state
        owner: Principal,
        config: DAOFactoryTypes.DAOConfig,
        configState: ConfigTypes.State,
        microserviceState: MicroserviceTypes.State
    ) : async Result.Result<
        {
            canisterId: Principal;
            args: DAOFactoryInterface.CreateDAOArgs;
        }, 
        Text> {
        
        // 1. Get the deployer canister principal from microservice state
        let canisterIds = switch (MicroserviceService.getCanisterIds(microserviceState)) {
            case null { return #err("Microservice canister IDs not configured") };
            case (?ids) ids;
        };

        let deployerCanisterId = switch(canisterIds.daoFactory) {
            case null { return #err("DAO Factory canister ID is not configured in microservices.") };
            case (?id) { id };
        };

        // 2. Validate the configuration
        let validationResult = validateConfig(config);
        switch (validationResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(_)) {};
        };

        // 3. Prepare the arguments (convert to DAO factory format)
        let args = await _convertToDAOFactoryArgs(config, owner);

        // 4. Return the canisterId and args for the Backend actor to call
        return #ok({
            canisterId = deployerCanisterId;
            args = args;
        });
    };

    // --- VALIDATION FUNCTIONS ---

    private func validateConfig(config: DAOFactoryTypes.DAOConfig) : Result.Result<Bool, Text> {
        
        // Validate basic information
        if (config.name == "") {
            return #err("DAO name cannot be empty");
        };

        if (config.description == "") {
            return #err("DAO description cannot be empty");
        };

        // Validate token canister ID
        if (Principal.isAnonymous(config.tokenCanisterId)) {
            return #err("Invalid token canister ID");
        };

        // Validate governance parameters
        if (config.minimumStake == 0) {
            return #err("Minimum stake must be greater than 0");
        };

        if (config.proposalThreshold == 0) {
            return #err("Proposal threshold must be greater than 0");
        };

        // Validate percentages (basis points)
        if (config.quorumPercentage == 0 or config.quorumPercentage > 10000) {
            return #err("Quorum percentage must be between 1 and 10000 basis points");
        };

        if (config.approvalThreshold == 0 or config.approvalThreshold > 10000) {
            return #err("Approval threshold must be between 1 and 10000 basis points");
        };

        // Validate time parameters
        if (config.timelockDuration < 3600) { // Minimum 1 hour
            return #err("Timelock duration must be at least 1 hour (3600 seconds)");
        };

        if (config.maxVotingPeriod < config.minVotingPeriod) {
            return #err("Maximum voting period must be greater than minimum voting period");
        };

        if (config.minVotingPeriod < 3600) { // Minimum 1 hour
            return #err("Minimum voting period must be at least 1 hour (3600 seconds)");
        };

        // Validate stake lock periods
        if (config.stakeLockPeriods.size() == 0) {
            return #err("At least one stake lock period must be defined");
        };

        // Validate emergency contacts
        if (config.emergencyPauseEnabled and config.emergencyContacts.size() == 0) {
            return #err("Emergency contacts required when emergency pause is enabled");
        };

        // Validate governance type
        switch (config.governanceType) {
            case ("liquid" or "locked" or "hybrid") {};
            case (_) { return #err("Invalid governance type. Must be 'liquid', 'locked', or 'hybrid'") };
        };

        // Validate voting power model
        switch (config.votingPowerModel) {
            case ("equal" or "proportional" or "quadratic") {};
            case (_) { return #err("Invalid voting power model. Must be 'equal', 'proportional', or 'quadratic'") };
        };

        #ok(true);
    };

    // --- UTILITY FUNCTIONS ---

    // Extract basic info for audit logging
    public func extractDAOInfo(config: DAOFactoryTypes.DAOConfig) : {
        name: Text;
        tokenCanisterId: Principal;
        governanceType: Text;
        stakingEnabled: Bool;
        emergencyContacts: [Text];
    } {
        {
            name = config.name;
            tokenCanisterId = config.tokenCanisterId;
            governanceType = config.governanceType;
            stakingEnabled = config.stakingEnabled;
            emergencyContacts = principalArrayToTextArray(config.emergencyContacts);
        }
    };

    // Convert Principals to Text array for audit
    private func principalArrayToTextArray(principals: [Principal]) : [Text] {
        Array.map<Principal, Text>(principals, Principal.toText)
    };

    // Generate DAO deployment summary for logging
    public func generateDeploymentSummary(
        config: DAOFactoryTypes.DAOConfig,
        daoCanisterId: Principal
    ) : DAOFactoryTypes.DAODeploymentSummary {
        {
            daoName = config.name;
            tokenSymbol = ""; // Will be fetched from token canister
            tokenCanisterId = config.tokenCanisterId;
            governanceType = config.governanceType;
            stakingEnabled = config.stakingEnabled;
            votingPowerModel = config.votingPowerModel;
            emergencyContacts = principalArrayToTextArray(config.emergencyContacts);
            totalMembers = 0; // Will be populated after deployment
            createdAt = Time.now();
        }
    };

    // --- PRIVATE CONVERSION FUNCTIONS ---

    // Convert backend DAOConfig to DAO factory CreateDAOArgs
    private func _convertToDAOFactoryArgs(
        config: DAOFactoryTypes.DAOConfig,
        _owner: Principal
    ) : async DAOFactoryInterface.CreateDAOArgs {
        // Getting token metadata from token canister
        let tokenMetadata = await ICRCUtility.getLedgerMetadata(config.tokenCanisterId);
        // Placeholder for token config before getting metadata
        var tokenConfig: DAOTypes.TokenConfig = {
            canisterId = config.tokenCanisterId;
            symbol = "ICP";
            name = config.name;
            decimals = 8;
            fee = config.transferFee;
            managedByDAO = config.managedByDAO;
        };
        switch (tokenMetadata) {
            case (#ok(metadata)) {
                tokenConfig := {
                    canisterId = config.tokenCanisterId;
                    symbol = metadata.symbol;
                    name = metadata.name;
                    decimals = metadata.decimals;
                    fee = config.transferFee;
                    managedByDAO = config.managedByDAO;
                };
            };
            case (#err(msg)) { Debug.print("Error getting token metadata: " # msg) };
        };

        let systemParams: DAOTypes.SystemParams = {
            transfer_fee = config.transferFee;
            proposal_vote_threshold = config.proposalThreshold;
            proposal_submission_deposit = config.minimumStake;
            timelock_duration = config.timelockDuration;
            quorum_percentage = config.quorumPercentage;
            approval_threshold = config.approvalThreshold;
            max_voting_period = config.maxVotingPeriod;
            min_voting_period = config.minVotingPeriod;
            stake_lock_periods = config.stakeLockPeriods;
            emergency_pause = config.emergencyPauseEnabled;
            emergency_contacts = config.emergencyContacts;
        };

        {
            tokenConfig = tokenConfig;
            systemParams = ?systemParams;
            initialAccounts = null; // No initial accounts from backend
            emergencyContacts = config.emergencyContacts;
            customSecurity = null;
            governanceLevel = config.governanceLevel;
        }
    };
}
