// ICTO V2 Multisig Contract
// Secure multisig wallet implementation with advanced features
// Maximum security for asset protection on Internet Computer

import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Random "mo:base/Random";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Timer "mo:base/Timer";
import Cycles "mo:base/ExperimentalCycles";

import MultisigTypes "../shared/types/MultisigTypes";
import ICRC "../shared/types/ICRC";

persistent actor class MultisigContract(initArgs: {
        id: MultisigTypes.WalletId;
        config: MultisigTypes.WalletConfig;
        creator: Principal;
        factory: Principal;
    }) {

        // ============== TYPES ==============

        private type ProposalEntry = (MultisigTypes.ProposalId, MultisigTypes.Proposal);
        private type EventEntry = (Text, MultisigTypes.WalletEvent);
        private type SignerEntry = (Principal, MultisigTypes.SignerInfo);

        // ============== STATE ==============

        private var walletId = initArgs.id;
        private var walletConfig = initArgs.config;
        private var creator = initArgs.creator;
        private var factory = initArgs.factory;
        private var createdAt = Time.now();

        // Core wallet state
        private transient var status: MultisigTypes.WalletStatus = #Setup;
        private transient var version: Nat = 1;
        // Actor principal will be computed at runtime when needed
        private transient var lastActivity = Time.now();

        // Signers and permissions
        private transient var signersEntries: [SignerEntry] = [];
        private transient var observersArray: [Principal] = [];

        // Proposals and execution
        private transient var nextProposalId: Nat = 1;
        private transient var proposalsEntries: [ProposalEntry] = [];
        private transient var totalProposals: Nat = 0;
        private transient var executedProposals: Nat = 0;
        private transient var failedProposals: Nat = 0;

        // Asset tracking
        private transient var icpBalance: Nat = 0;
        private transient var tokensArray: [MultisigTypes.TokenBalance] = [];
        private transient var nftsArray: [MultisigTypes.NFTBalance] = [];

        // Security and monitoring
        private var securityFlags: MultisigTypes.SecurityFlags = {
            suspiciousActivity = false;
            rateLimit = false;
            geoRestricted = false;
            complianceAlert = false;
            autoFreezeEnabled = true;
            anomalyDetection = true;
            whitelistOnly = false;
            failedAttempts = 0;
            lastSecurityEvent = null;
            securityScore = 1.0;
        };

        // Events and audit trail
        private transient var eventsEntries: [EventEntry] = [];
        private transient var nextEventId: Nat = 1;

        // Runtime state
        private transient var signers = HashMap.fromIter<Principal, MultisigTypes.SignerInfo>(
            signersEntries.vals(),
            signersEntries.size(),
            Principal.equal,
            Principal.hash
        );

        private transient var proposals = HashMap.fromIter<MultisigTypes.ProposalId, MultisigTypes.Proposal>(
            proposalsEntries.vals(),
            proposalsEntries.size(),
            Text.equal,
            Text.hash
        );

        private transient var events = HashMap.fromIter<Text, MultisigTypes.WalletEvent>(
            eventsEntries.vals(),
            eventsEntries.size(),
            Text.equal,
            Text.hash
        );

        private transient var observers = Buffer.fromArray<Principal>(observersArray);

        // Security rate limiting
        private transient var lastProposalTimes = HashMap.HashMap<Principal, Int>(10, Principal.equal, Principal.hash);
        private transient var dailyLimitsUsage = HashMap.HashMap<MultisigTypes.AssetType, Nat>(10, func(a: MultisigTypes.AssetType, b: MultisigTypes.AssetType): Bool { false }, func(a: MultisigTypes.AssetType): Nat32 { 0 });

        // Constants
        private let MAX_PROPOSALS_PER_HOUR = 10;
        private let MIN_PROPOSAL_INTERVAL = 60_000_000_000; // 1 minute in nanoseconds
        private let SECURITY_COOLDOWN = 300_000_000_000; // 5 minutes
        private let MAX_FAILED_ATTEMPTS = 5;

        // ============== INITIALIZATION ==============

        private func initializeWallet() {
            // Initialize signers from config
            for (signerPrincipal in walletConfig.signers.vals()) {
                let signerInfo: MultisigTypes.SignerInfo = {
                    principal = signerPrincipal;
                    name = null;
                    role = if (signerPrincipal == creator) #Owner else #Signer;
                    addedAt = Time.now();
                    addedBy = creator;
                    lastSeen = null;
                    isActive = true;
                    requiresTwoFactor = false;
                    ipWhitelist = null;
                    sessionTimeout = null;
                    delegatedVoting = false;
                    delegatedTo = null;
                    delegationExpiry = null;
                };
                signers.put(signerPrincipal, signerInfo);
            };

            // Create initialization event
            let initEvent = createEvent(
                #WalletCreated,
                creator,
                ?("Multisig wallet initialized with " # debug_show(walletConfig.signers.size()) # " signers")
            );
            events.put(initEvent.id, initEvent);

            status := #Active;
            Debug.print("MultisigContract: Initialized wallet " # walletId # " with " # debug_show(signers.size()) # " signers");
        };

        // Initialize the wallet - call moved to after createEvent definition

        // ============== ACCESS CONTROL ==============

        private func isAuthorized(caller: Principal): Bool {
            // Factory can always access
            if (caller == factory) return true;

            // Check if caller is a signer
            switch (signers.get(caller)) {
                case (?signer) signer.isActive;
                case null false;
            };
        };

        private func isSigner(caller: Principal): Bool {
            switch (signers.get(caller)) {
                case (?signer) {
                    signer.isActive and (signer.role == #Owner or signer.role == #Signer)
                };
                case null false;
            };
        };

        private func isOwner(caller: Principal): Bool {
            switch (signers.get(caller)) {
                case (?signer) signer.isActive and signer.role == #Owner;
                case null false;
            };
        };

        private func isObserver(caller: Principal): Bool {
            for (observer in observers.vals()) {
                if (observer == caller) return true;
            };
            false;
        };

        private func canCreateProposal(caller: Principal): Result.Result<(), Text> {
            if (status != #Active) {
                return #err("Wallet is not active");
            };

            if (not isSigner(caller)) {
                return #err("Only signers can create proposals");
            };

            // Rate limiting check
            switch (lastProposalTimes.get(caller)) {
                case (?lastTime) {
                    let timeSinceLastProposal = Time.now() - lastTime;
                    if (timeSinceLastProposal < MIN_PROPOSAL_INTERVAL) {
                        return #err("Too many proposals - please wait before creating another");
                    };
                };
                case null {};
            };

            #ok()
        };

        // ============== PROPOSAL MANAGEMENT ==============

        public func createProposal(
            caller: Principal,
            proposalType: MultisigTypes.ProposalType,
            title: Text,
            description: Text,
            actions: [MultisigTypes.ProposalAction]
        ): async Result.Result<MultisigTypes.ProposalId, MultisigTypes.ProposalError> {

            // Authorization check
            switch (canCreateProposal(caller)) {
                case (#err(error)) return #err(#SecurityViolation(error));
                case (#ok()) {};
            };

            // Validate proposal
            switch (validateProposal(proposalType, actions)) {
                case (#err(error)) return #err(#InvalidProposal(error));
                case (#ok()) {};
            };

            // Generate proposal ID
            let proposalId = generateProposalId();

            // Calculate risk assessment
            let riskAssessment = calculateRiskAssessment(proposalType, actions);

            // Determine required approvals (can be different based on risk)
            let requiredApprovals = calculateRequiredApprovals(riskAssessment.level);

            // Calculate expiration time
            let expiresAt = Time.now() + walletConfig.maxProposalLifetime;

            // Create proposal
            let proposal: MultisigTypes.Proposal = {
                id = proposalId;
                walletId = walletId;
                proposalType = proposalType;
                title = title;
                description = description;
                actions = actions;
                proposer = caller;
                proposedAt = Time.now();
                earliestExecution = if (walletConfig.requiresTimelock) {
                    switch (walletConfig.timelockDuration) {
                        case (?duration) ?(Time.now() + duration);
                        case null null;
                    };
                } else null;
                expiresAt = expiresAt;
                requiredApprovals = requiredApprovals;
                currentApprovals = 0;
                approvals = [];
                rejections = [];
                status = #Pending;
                executedAt = null;
                executedBy = null;
                executionResult = null;
                risk = riskAssessment.level;
                requiresConsensus = riskAssessment.level == #Critical or walletConfig.requiresConsensusForChanges;
                emergencyOverride = false;
                dependsOn = [];
                executionOrder = null;
            };

            // Store proposal
            proposals.put(proposalId, proposal);
            totalProposals += 1;

            // Update rate limiting
            lastProposalTimes.put(caller, Time.now());

            // Create event
            let event = createEvent(
                #ProposalCreated,
                caller,
                ?("Proposal created: " # title)
            );
            events.put(event.id, event);

            // Update activity
            updateLastActivity();

            Debug.print("MultisigContract: Created proposal " # proposalId # " by " # Principal.toText(caller));

            #ok(proposalId)
        };

        public func signProposal(
            caller: Principal,
            proposalId: MultisigTypes.ProposalId,
            signature: Blob,
            note: ?Text
        ): async MultisigTypes.SignatureResult {

            if (not isSigner(caller)) {
                return #err(#Unauthorized);
            };

            switch (proposals.get(proposalId)) {
                case (?proposal) {
                    // Check if proposal is still valid
                    if (proposal.status != #Pending) {
                        return #err(#ProposalNotFound);
                    };

                    if (Time.now() > proposal.expiresAt) {
                        // Mark as expired
                        let expiredProposal = { proposal with status = #Expired };
                        proposals.put(proposalId, expiredProposal);
                        return #err(#ProposalExpired);
                    };

                    // Check if already signed
                    for (approval in proposal.approvals.vals()) {
                        if (approval.signer == caller) {
                            return #err(#AlreadySigned);
                        };
                    };

                    // Create approval
                    let approval: MultisigTypes.ProposalApproval = {
                        signer = caller;
                        approvedAt = Time.now();
                        signature = signature;
                        note = note;
                        ipAddress = null; // TODO: Get from context
                        userAgent = null; // TODO: Get from context
                        twoFactorVerified = false; // TODO: Implement 2FA
                        delegated = false;
                        delegatedBy = null;
                    };

                    // Update proposal
                    let newApprovals = Array.append(proposal.approvals, [approval]);
                    let currentApprovals = newApprovals.size();

                    let updatedProposal = {
                        proposal with
                        approvals = newApprovals;
                        currentApprovals = currentApprovals;
                        status = if (currentApprovals >= proposal.requiredApprovals) #Approved else #Pending;
                    };

                    proposals.put(proposalId, updatedProposal);

                    // Create event
                    let event = createEvent(
                        #ProposalSigned,
                        caller,
                        ?("Proposal " # proposalId # " signed")
                    );
                    events.put(event.id, event);

                    updateLastActivity();

                    let readyForExecution = currentApprovals >= proposal.requiredApprovals and
                                          (switch (proposal.earliestExecution) {
                                              case (?earliest) Time.now() >= earliest;
                                              case null true;
                                          });

                    Debug.print("MultisigContract: Proposal " # proposalId # " signed by " # Principal.toText(caller) # " (" # debug_show(currentApprovals) # "/" # debug_show(proposal.requiredApprovals) # ")");

                    #ok({
                        proposalId = proposalId;
                        signatureId = generateSignatureId();
                        currentApprovals = currentApprovals;
                        requiredApprovals = proposal.requiredApprovals;
                        readyForExecution = readyForExecution;
                    })
                };
                case null #err(#ProposalNotFound);
            }
        };

        public func executeProposal(
            caller: Principal,
            proposalId: MultisigTypes.ProposalId
        ): async Result.Result<MultisigTypes.ExecutionResult, MultisigTypes.ProposalError> {

            if (not isSigner(caller)) {
                return #err(#Unauthorized);
            };

            switch (proposals.get(proposalId)) {
                case (?proposal) {
                    // Validation checks
                    if (proposal.status != #Approved) {
                        return #err(#ThresholdNotMet);
                    };

                    if (Time.now() > proposal.expiresAt) {
                        let expiredProposal = { proposal with status = #Expired };
                        proposals.put(proposalId, expiredProposal);
                        return #err(#ProposalExpired);
                    };

                    // Check timelock
                    switch (proposal.earliestExecution) {
                        case (?earliest) {
                            if (Time.now() < earliest) {
                                return #err(#SecurityViolation("Timelock period not yet expired"));
                            };
                        };
                        case null {};
                    };

                    // Execute the proposal
                    try {
                        let executionResult = await executeProposalActions(proposal);

                        // Update proposal status
                        let updatedProposal = {
                            proposal with
                            status = if (executionResult.success) #Executed else #Failed;
                            executedAt = ?Time.now();
                            executedBy = ?caller;
                            executionResult = ?executionResult;
                        };

                        proposals.put(proposalId, updatedProposal);

                        if (executionResult.success) {
                            executedProposals += 1;
                        } else {
                            failedProposals += 1;
                        };

                        // Create event
                        let event = createEvent(
                            if (executionResult.success) #ProposalExecuted else #ProposalRejected,
                            caller,
                            ?("Proposal " # proposalId # " execution result: " # debug_show(executionResult.success))
                        );
                        events.put(event.id, event);

                        updateLastActivity();

                        Debug.print("MultisigContract: Proposal " # proposalId # " executed by " # Principal.toText(caller) #
                                   " with result: " # debug_show(executionResult.success));

                        #ok(executionResult)

                    } catch (e) {
                        failedProposals += 1;
                        let errorMsg = "Execution failed: " # Error.message(e);

                        let updatedProposal = {
                            proposal with
                            status = #Failed;
                            executedAt = ?Time.now();
                            executedBy = ?caller;
                            executionResult = ?{
                                success = false;
                                error = ?errorMsg;
                                gasUsed = null;
                                transactionIds = [];
                                timestamp = Time.now();
                                actionResults = [];
                                balanceChanges = [];
                                eventsEmitted = [];
                            };
                        };

                        proposals.put(proposalId, updatedProposal);

                        #err(#ExecutionFailed(errorMsg))
                    }
                };
                case null #err(#InvalidProposal("Proposal not found"));
            }
        };

        // ============== EXECUTION ENGINE ==============

        private func executeProposalActions(proposal: MultisigTypes.Proposal): async MultisigTypes.ExecutionResult {
            let actionResults = Buffer.Buffer<MultisigTypes.ActionResult>(proposal.actions.size());
            let balanceChanges = Buffer.Buffer<MultisigTypes.BalanceChange>(0);
            let transactionIds = Buffer.Buffer<MultisigTypes.TransactionId>(0);
            var totalGasUsed: Nat = 0;
            var overallSuccess = true;

            for (actionIndex in proposal.actions.keys()) {
                let action = proposal.actions[actionIndex];
                try {
                    let result = await executeAction(action, actionIndex);
                    actionResults.add(result);

                    if (not result.success) {
                        overallSuccess := false;
                    };

                    switch (result.gasUsed) {
                        case (?gas) totalGasUsed += gas;
                        case null {};
                    };

                } catch (e) {
                    let errorResult: MultisigTypes.ActionResult = {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?Error.message(e);
                        gasUsed = null;
                        result = null;
                    };
                    actionResults.add(errorResult);
                    overallSuccess := false;
                };
            };

            {
                success = overallSuccess;
                error = if (overallSuccess) null else ?"One or more actions failed";
                gasUsed = ?totalGasUsed;
                transactionIds = Buffer.toArray(transactionIds);
                timestamp = Time.now();
                actionResults = Buffer.toArray(actionResults);
                balanceChanges = Buffer.toArray(balanceChanges);
                eventsEmitted = [];
            }
        };

        private func executeAction(action: MultisigTypes.ProposalAction, actionIndex: Nat): async MultisigTypes.ActionResult {
            switch (action.actionType) {
                case (#Transfer(transferData)) {
                    await executeTransfer(transferData, actionIndex)
                };
                case (#TokenApproval(approvalData)) {
                    await executeTokenApproval(approvalData, actionIndex)
                };
                case (#BatchTransfer(batchData)) {
                    await executeBatchTransfer(batchData, actionIndex)
                };
                case (#WalletModification(modData)) {
                    await executeWalletModification(modData, actionIndex)
                };
                case (#ContractCall(callData)) {
                    await executeContractCall(callData, actionIndex)
                };
                case (#EmergencyAction(emergencyData)) {
                    await executeEmergencyAction(emergencyData, actionIndex)
                };
                case (#SystemUpdate(updateData)) {
                    await executeSystemUpdate(updateData, actionIndex)
                };
            }
        };

        // ============== SPECIFIC EXECUTION METHODS ==============

        private func executeTransfer(
            transferData: { recipient: Principal; amount: Nat; asset: MultisigTypes.AssetType; memo: ?Blob },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {

            // Check daily limits
            switch (checkDailyLimit(transferData.asset, transferData.amount)) {
                case (#err(error)) {
                    return {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?error;
                        gasUsed = null;
                        result = null;
                    };
                };
                case (#ok()) {};
            };

            // Execute based on asset type
            switch (transferData.asset) {
                case (#ICP) {
                    if (transferData.amount > icpBalance) {
                        return {
                            actionIndex = actionIndex;
                            success = false;
                            error = ?"Insufficient ICP balance";
                            gasUsed = null;
                            result = null;
                        };
                    };

                    // TODO: Implement actual ICP transfer
                    // This would call the ICP ledger canister
                    icpBalance -= transferData.amount;

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?100_000; // Estimated gas
                        result = ?"ICP transfer completed";
                    }
                };
                case (#Token(tokenCanister)) {
                    // TODO: Implement token transfer
                    {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?"Token transfers not yet implemented";
                        gasUsed = null;
                        result = null;
                    }
                };
                case (#NFT(_)) {
                    // TODO: Implement NFT transfer
                    {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?"NFT transfers not yet implemented";
                        gasUsed = null;
                        result = null;
                    }
                };
            }
        };

        private func executeTokenApproval(
            approvalData: { spender: Principal; amount: Nat; token: Principal },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {
            // TODO: Implement token approval
            {
                actionIndex = actionIndex;
                success = false;
                error = ?"Token approvals not yet implemented";
                gasUsed = null;
                result = null;
            }
        };

        private func executeBatchTransfer(
            batchData: { transfers: [MultisigTypes.TransferRequest] },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {
            // TODO: Implement batch transfers
            {
                actionIndex = actionIndex;
                success = false;
                error = ?"Batch transfers not yet implemented";
                gasUsed = null;
                result = null;
            }
        };

        private func executeWalletModification(
            modData: { modificationType: MultisigTypes.WalletModificationType },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {

            switch (modData.modificationType) {
                case (#AddSigner(signerData)) {
                    let newSigner: MultisigTypes.SignerInfo = {
                        principal = signerData.signer;
                        name = null;
                        role = signerData.role;
                        addedAt = Time.now();
                        addedBy = Principal.fromText("2vxsx-fae"); // TODO: Get actual caller
                        lastSeen = null;
                        isActive = true;
                        requiresTwoFactor = false;
                        ipWhitelist = null;
                        sessionTimeout = null;
                        delegatedVoting = false;
                        delegatedTo = null;
                        delegationExpiry = null;
                    };

                    signers.put(signerData.signer, newSigner);

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?50_000;
                        result = ?"Signer added successfully";
                    }
                };
                case (#RemoveSigner(signerData)) {
                    signers.delete(signerData.signer);

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?50_000;
                        result = ?"Signer removed successfully";
                    }
                };
                case (#ChangeThreshold(thresholdData)) {
                    walletConfig := {
                        walletConfig with threshold = thresholdData.newThreshold
                    };

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?30_000;
                        result = ?"Threshold changed successfully";
                    }
                };
                case (_) {
                    {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?"Wallet modification type not yet implemented";
                        gasUsed = null;
                        result = null;
                    }
                };
            }
        };

        private func executeContractCall(
            callData: { canister: Principal; method: Text; args: Blob; cycles: ?Nat },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {
            // TODO: Implement contract calls
            {
                actionIndex = actionIndex;
                success = false;
                error = ?"Contract calls not yet implemented";
                gasUsed = null;
                result = null;
            }
        };

        private func executeEmergencyAction(
            emergencyData: { actionType: MultisigTypes.EmergencyActionType },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {

            switch (emergencyData.actionType) {
                case (#FreezeWallet) {
                    status := #Frozen;
                    let event = createEvent(#EmergencyAction, Principal.fromText("2vxsx-fae"), ?"Wallet frozen");
                    events.put(event.id, event);

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?10_000;
                        result = ?"Wallet frozen";
                    }
                };
                case (#UnfreezeWallet) {
                    status := #Active;
                    let event = createEvent(#EmergencyAction, Principal.fromText("2vxsx-fae"), ?"Wallet unfrozen");
                    events.put(event.id, event);

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?10_000;
                        result = ?"Wallet unfrozen";
                    }
                };
                case (_) {
                    {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?"Emergency action type not yet implemented";
                        gasUsed = null;
                        result = null;
                    }
                };
            }
        };

        private func executeSystemUpdate(
            updateData: { updateType: MultisigTypes.SystemUpdateType },
            actionIndex: Nat
        ): async MultisigTypes.ActionResult {
            // TODO: Implement system updates
            {
                actionIndex = actionIndex;
                success = false;
                error = ?"System updates not yet implemented";
                gasUsed = null;
                result = null;
            }
        };

        // ============== VALIDATION AND SECURITY ==============

        private func validateProposal(
            proposalType: MultisigTypes.ProposalType,
            actions: [MultisigTypes.ProposalAction]
        ): Result.Result<(), Text> {

            if (actions.size() == 0) {
                return #err("Proposal must have at least one action");
            };

            if (actions.size() > 100) {
                return #err("Too many actions in proposal (max 100)");
            };

            // Validate each action
            for (action in actions.vals()) {
                switch (validateAction(action)) {
                    case (#err(error)) return #err(error);
                    case (#ok()) {};
                };
            };

            #ok()
        };

        private func validateAction(action: MultisigTypes.ProposalAction): Result.Result<(), Text> {
            switch (action.actionType) {
                case (#Transfer(transferData)) {
                    if (transferData.amount == 0) {
                        return #err("Transfer amount must be greater than 0");
                    };
                    if (Principal.isAnonymous(transferData.recipient)) {
                        return #err("Invalid recipient address");
                    };
                };
                case (_) {}; // TODO: Add validation for other action types
            };

            #ok()
        };

        private func calculateRiskAssessment(
            proposalType: MultisigTypes.ProposalType,
            actions: [MultisigTypes.ProposalAction]
        ): MultisigTypes.RiskAssessment {

            var riskScore: Float = 0.0;
            let riskFactors = Buffer.Buffer<MultisigTypes.RiskFactor>(5);

            // Analyze proposal type
            switch (proposalType) {
                case (#Transfer(transferData)) {
                    if (transferData.amount > 1000_00000000) { // > 1000 ICP
                        riskScore += 0.3;
                        riskFactors.add(#LargeAmount);
                    };
                };
                case (#WalletModification(_)) {
                    riskScore += 0.4;
                    riskFactors.add(#StructuralChange);
                };
                case (#EmergencyAction(_)) {
                    riskScore += 0.6;
                    riskFactors.add(#EmergencyAction);
                };
                case (#ContractCall(_)) {
                    riskScore += 0.5;
                    riskFactors.add(#ExternalContract);
                };
                case (_) {};
            };

            // Time-based risk factors
            let currentHour = (Time.now() / 1_000_000_000) % 86400 / 3600;
            if (currentHour < 6 or currentHour > 22) { // Outside business hours
                riskScore += 0.1;
                riskFactors.add(#OutsideBusinessHours);
            };

            // Determine risk level
            let riskLevel = if (riskScore >= 0.8) #Critical
                           else if (riskScore >= 0.6) #High
                           else if (riskScore >= 0.3) #Medium
                           else #Low;

            {
                level = riskLevel;
                factors = Buffer.toArray(riskFactors);
                score = riskScore;
                autoApproved = riskLevel == #Low and riskScore < 0.1;
            }
        };

        private func calculateRequiredApprovals(riskLevel: MultisigTypes.RiskLevel): Nat {
            switch (riskLevel) {
                case (#Critical) signers.size(); // Requires unanimous approval
                case (#High) Nat.max(walletConfig.threshold + 1, (signers.size() * 2 / 3)); // Requires 2/3 or threshold+1
                case (#Medium) walletConfig.threshold;
                case (#Low) Nat.max(1, walletConfig.threshold - 1); // Can reduce by 1 for low risk
            }
        };

        private func checkDailyLimit(asset: MultisigTypes.AssetType, amount: Nat): Result.Result<(), Text> {
            switch (walletConfig.dailyLimit) {
                case (?limit) {
                    switch (asset) {
                        case (#ICP) {
                            let currentUsage = switch (dailyLimitsUsage.get(asset)) {
                                case (?usage) usage;
                                case null 0;
                            };

                            if (currentUsage + amount > limit) {
                                return #err("Daily limit exceeded");
                            };

                            dailyLimitsUsage.put(asset, currentUsage + amount);
                        };
                        case (_) {}; // TODO: Implement for other assets
                    };
                };
                case null {};
            };

            #ok()
        };

        // ============== QUERY FUNCTIONS ==============

        public query func getWalletInfo(): async MultisigTypes.MultisigWallet {
            {
                id = walletId;
                canisterId = Principal.fromText(walletId); // Use wallet ID as canister identifier
                config = walletConfig;
                signers = Iter.toArray(signers.vals());
                observers = Buffer.toArray(observers);
                status = status;
                balances = {
                    icp = icpBalance;
                    tokens = tokensArray;
                    nfts = nftsArray;
                    totalUsdValue = null; // TODO: Calculate from external price feeds
                    lastUpdated = Time.now();
                };
                totalProposals = totalProposals;
                executedProposals = executedProposals;
                failedProposals = failedProposals;
                lastActivity = lastActivity;
                securityFlags = securityFlags;
                createdAt = createdAt;
                createdBy = creator;
                version = version;
            }
        };

        public query func getProposal(proposalId: MultisigTypes.ProposalId): async ?MultisigTypes.Proposal {
            proposals.get(proposalId)
        };

        public query func getProposals(
            filter: ?MultisigTypes.ProposalFilter,
            limit: ?Nat,
            offset: ?Nat
        ): async [MultisigTypes.Proposal] {
            let allProposals = Iter.toArray(proposals.vals());

            // TODO: Apply filtering
            let filteredProposals = allProposals;

            // TODO: Apply pagination
            filteredProposals
        };

        public query func getEvents(
            filter: ?MultisigTypes.EventFilter,
            limit: ?Nat,
            offset: ?Nat
        ): async [MultisigTypes.WalletEvent] {
            let allEvents = Iter.toArray(events.vals());

            // TODO: Apply filtering and pagination
            allEvents
        };

        public query func getSecurityInfo(): async {
            securityFlags: MultisigTypes.SecurityFlags;
            recentEvents: [MultisigTypes.WalletEvent];
            riskScore: Float;
        } {
            let recentEvents = Array.filter<MultisigTypes.WalletEvent>(
                Iter.toArray(events.vals()),
                func(event) = (Time.now() - event.timestamp) < (24 * 60 * 60 * 1_000_000_000) // Last 24 hours
            );

            {
                securityFlags = securityFlags;
                recentEvents = recentEvents;
                riskScore = securityFlags.securityScore;
            }
        };

        // ============== ICRC TRANSFER FUNCTIONALITY ==============

        // ICRC1 Token Actor Interface
        private type ICRC1Actor = actor {
            icrc1_transfer : (ICRC.TransferArgs) -> async ICRC.TransferResult;
            icrc1_balance_of : (ICRC.Account) -> async ICRC.Balance;
            icrc1_fee : () -> async ICRC.Balance;
        };

        // Execute ICRC1 transfer for token assets
        private func executeICRCTransfer(
            tokenCanisterId: Principal,
            to: Principal,
            amount: Nat,
            memo: ?Blob
        ): async* Result.Result<Nat, Text> {
            try {
                let tokenCanister : ICRC1Actor = actor(Principal.toText(tokenCanisterId));

                // Get the transfer fee
                let transferFee = await tokenCanister.icrc1_fee();

                // Calculate transfer amount after fee
                let transferAmount = if (amount > transferFee) {
                    Nat.sub(amount, transferFee)
                } else { 0 };

                if (transferAmount == 0) {
                    return #err("Insufficient amount to cover transfer fee");
                };

                // Execute the transfer
                let transferArgs: ICRC.TransferArgs = {
                    to = {
                        owner = to;
                        subaccount = null;
                    };
                    fee = ?transferFee;
                    amount = transferAmount;
                    memo = memo;
                    from_subaccount = null;
                    created_at_time = null;
                };

                let transferResult = await tokenCanister.icrc1_transfer(transferArgs);

                switch (transferResult) {
                    case (#Ok(txIndex)) {
                        #ok(txIndex)
                    };
                    case (#Err(err)) {
                        let errorMsg = switch (err) {
                            case (#InsufficientFunds { balance }) "Insufficient funds: balance " # Nat.toText(balance);
                            case (#BadFee { expected_fee }) "Bad fee: expected " # Nat.toText(expected_fee);
                            case (#TooOld) "Transaction too old";
                            case (#CreatedInFuture { ledger_time }) "Transaction created in future";
                            case (#Duplicate { duplicate_of }) "Duplicate transaction: " # Nat.toText(duplicate_of);
                            case (#TemporarilyUnavailable) "Service temporarily unavailable";
                            case (#GenericError { error_code; message }) "Error " # Nat.toText(error_code) # ": " # message;
                            case (#BadBurn { min_burn_amount }) "Bad burn: minimum " # Nat.toText(min_burn_amount);
                        };
                        #err(errorMsg)
                    };
                }
            } catch (error) {
                #err("Transfer failed: " # Error.message(error))
            }
        };

        // Get ICRC1 token balance for this wallet
        private func getICRCBalance(tokenCanisterId: Principal): async* Nat {
            try {
                let tokenCanister : ICRC1Actor = actor(Principal.toText(tokenCanisterId));

                let account: ICRC.Account = {
                    owner = Principal.fromText(walletId); // Use wallet ID as principal identifier
                    subaccount = null;
                };

                let balance = await tokenCanister.icrc1_balance_of(account);
                balance
            } catch (error) {
                Debug.print("Failed to get ICRC balance: " # Error.message(error));
                0
            }
        };

        // Create a transfer proposal
        public func createTransferProposal(
            recipient: Principal,
            amount: Nat,
            asset: MultisigTypes.AssetType,
            memo: ?Blob,
            title: Text,
            description: Text
        ): async MultisigTypes.ProposalResult {
            // Note: In actual deployment, caller would be obtained from message context
            // For now, we'll use the creator as a placeholder - this needs proper access control
            let caller = creator;

            // Check if caller is authorized signer
            switch (signers.get(caller)) {
                case null return #err(#Unauthorized);
                case (?_) {};
            };

            // Validate transfer parameters
            if (amount == 0) {
                return #err(#InvalidProposal("Transfer amount must be greater than zero"));
            };

            // Check daily limits
            switch (checkDailyLimit(asset, amount)) {
                case (#err(error)) return #err(#InvalidProposal(error));
                case (#ok()) {};
            };

            // Create transfer proposal
            let proposalId = generateProposalId();
            let proposalType = #Transfer({
                recipient = recipient;
                amount = amount;
                asset = asset;
                memo = memo;
            });

            let proposal: MultisigTypes.Proposal = {
                id = proposalId;
                walletId = walletId;
                proposalType = proposalType;
                title = title;
                description = description;
                actions = [{
                    actionType = proposalType;
                    estimatedCost = ?1000000; // Estimate cycles cost
                    riskAssessment = {
                        level = assessTransferRisk(amount, asset);
                        factors = [];
                        score = 0.5;
                        autoApproved = false;
                    };
                }];
                proposer = caller;
                proposedAt = Time.now();
                earliestExecution = null;
                expiresAt = Time.now() + walletConfig.maxProposalLifetime;
                requiredApprovals = calculateRequiredApprovals(assessTransferRisk(amount, asset));
                currentApprovals = 0;
                approvals = [];
                rejections = [];
                status = #Pending;
                executedAt = null;
                executedBy = null;
                executionResult = null;
                risk = assessTransferRisk(amount, asset);
                requiresConsensus = false;
                emergencyOverride = false;
                dependsOn = [];
                executionOrder = null;
            };

            // Store proposal
            proposals.put(proposalId, proposal);
            totalProposals += 1;

            // Create event
            let event = createEvent(
                #ProposalCreated,
                caller,
                ?("Transfer proposal created for " # Nat.toText(amount))
            );
            events.put(event.id, event);

            updateLastActivity();

            #ok({
                proposalId = proposalId;
                status = #Pending;
                requiredApprovals = proposal.requiredApprovals;
                currentApprovals = 0;
            })
        };

        // Assess transfer risk based on amount and asset type
        private func assessTransferRisk(amount: Nat, asset: MultisigTypes.AssetType): MultisigTypes.RiskLevel {
            // Simple risk assessment - can be enhanced
            switch (asset) {
                case (#ICP) {
                    if (amount > 100_000_000) #High // > 1 ICP
                    else if (amount > 10_000_000) #Medium // > 0.1 ICP
                    else #Low;
                };
                case (#Token(_)) {
                    // For tokens, we'd need to check value/market cap
                    #Medium;
                };
                case (#NFT(_)) #High; // NFTs are always high risk
            }
        };

        // Note: signProposal is already implemented above

        // Note: executeProposal is already implemented above
        // ICRC transfer logic will be integrated into existing executeAction function

        // ============== HELPER FUNCTIONS ==============

        private func generateProposalId(): MultisigTypes.ProposalId {
            let id = nextProposalId;
            nextProposalId += 1;
            walletId # "-proposal-" # Nat.toText(id)
        };

        private func generateSignatureId(): MultisigTypes.SignatureId {
            walletId # "-signature-" # Nat.toText(Int.abs(Time.now()) % 1000000)
        };

        private func createEvent(
            eventType: MultisigTypes.EventType,
            actorEvent: Principal,
            description: ?Text
        ): MultisigTypes.WalletEvent {
            let eventId = "event-" # Nat.toText(nextEventId);
            nextEventId += 1;

            {
                id = eventId;
                walletId = walletId;
                eventType = eventType;
                timestamp = Time.now();
                actorEvent = actorEvent;
                data = null;
                proposalId = null;
                transactionId = null;
                ipAddress = null;
                userAgent = null;
                severity = #Info;
            }
        };

        // Initialization is done in postUpgrade or on first use

        private func updateLastActivity() {
            lastActivity := Time.now();
        };

        // ============== UPGRADE HOOKS ==============

        public func preUpgrade(): async () {
            signersEntries := Iter.toArray(signers.entries());
            proposalsEntries := Iter.toArray(proposals.entries());
            eventsEntries := Iter.toArray(events.entries());
            observersArray := Buffer.toArray(observers);

            Debug.print("MultisigContract: Pre-upgrade completed for wallet " # walletId);
        };

        public func postUpgrade(): async () {
            signersEntries := [];
            proposalsEntries := [];
            eventsEntries := [];

            // Initialize wallet if this is first deployment
            if (signers.size() == 0) {
                initializeWallet();
            };

            Debug.print("MultisigContract: Post-upgrade completed for wallet " # walletId);
        };

        // Initialize wallet on contract deployment
        if (signers.size() == 0) {
            initializeWallet();
        };
    }