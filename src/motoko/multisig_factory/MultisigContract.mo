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
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";

import MultisigTypes "../shared/types/MultisigTypes";
import ICRC "../shared/types/ICRC";

persistent actor class MultisigContract(initArgs: {
        id: MultisigTypes.WalletId;
        config: MultisigTypes.WalletConfig;
        creator: Principal;
        factory: Principal;
    }) = self {

        // ============== TYPES ==============

        private type ProposalEntry = (MultisigTypes.ProposalId, MultisigTypes.Proposal);
        private type EventEntry = (Text, MultisigTypes.WalletEvent);
        private type SignerEntry = (Principal, MultisigTypes.SignerInfo);

        // ============== STATE ==============

        private var walletId = Principal.toText(Principal.fromActor(self));//initArgs.id;
        private var walletConfig = initArgs.config;
        private var creator = initArgs.creator;
        private var factory = initArgs.factory;
        private var createdAt = Time.now();

        // Core wallet state - STABLE for upgrades (implicitly stable in persistent actor)
        private var status: MultisigTypes.WalletStatus = #Setup;
        private var version: Nat = 1;
        private var lastActivity = Time.now();

        // Signers and permissions - STABLE for upgrades
        private var signersEntries: [SignerEntry] = [];
        private var observersArray: [Principal] = [];

        // Proposals and execution - STABLE for upgrades
        private var nextProposalId: Nat = 1;
        private var proposalsEntries: [ProposalEntry] = [];
        private var totalProposals: Nat = 0;
        private var executedProposals: Nat = 0;
        private var failedProposals: Nat = 0;

        // Asset tracking - STABLE for upgrades
        private var icpBalance: Nat = 0;
        private var tokensArray: [MultisigTypes.TokenBalance] = [];
        private var nftsArray: [MultisigTypes.NFTBalance] = [];

        // Security and monitoring - STABLE for upgrades
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

        // Events and audit trail - STABLE for upgrades
        private var eventsEntries: [EventEntry] = [];
        private var nextEventId: Nat = 1;

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

        // Reentrancy protection
        private transient var isExecuting = false;

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
            for (signerConfig in walletConfig.signers.vals()) {
                let signerInfo: MultisigTypes.SignerInfo = {
                    principal = signerConfig.principal;
                    name = signerConfig.name;
                    role = if (signerConfig.principal == creator) #Owner else signerConfig.role;
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
                signers.put(signerConfig.principal, signerInfo);
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
            // Check if caller is in observers buffer (deprecated)
            for (observer in observers.vals()) {
                if (observer == caller) return true;
            };
            // Check if caller is a signer with Observer role
            switch (signers.get(caller)) {
                case (?signer) signer.isActive and signer.role == #Observer;
                case null false;
            };
        };

        private func canViewWallet(caller: Principal): Bool {
            // Public wallet: anyone can view
            if (walletConfig.isPublic) {
                return true;
            };
            // Private wallet: creator, signers and observers can view
            caller == creator or isSigner(caller) or isObserver(caller)
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

        public shared({caller}) func createProposal(
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

        public shared({caller}) func signProposal(
            proposalId: MultisigTypes.ProposalId,
            signature: Blob,
            note: ?Text
        ): async MultisigTypes.SignatureResult {

            if (not isSigner(caller)) {
                return #err(#Unauthorized);
            };

            // Rate limiting for signing
            switch (lastProposalTimes.get(caller)) {
                case (?lastTime) {
                    let timeSinceLastAction = Time.now() - lastTime;
                    if (timeSinceLastAction < MIN_PROPOSAL_INTERVAL) {
                        return #err(#SecurityCheckFailed);
                    };
                };
                case null {};
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

                    let readyForExecution = currentApprovals >= walletConfig.threshold and
                                          (switch (proposal.earliestExecution) {
                                              case (?earliest) Time.now() >= earliest;
                                              case null true;
                                          });

                    let updatedProposal = {
                        proposal with
                        approvals = newApprovals;
                        currentApprovals = currentApprovals;
                        status = if (readyForExecution) #Approved else #Pending;
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
                    lastProposalTimes.put(caller, Time.now());

                    Debug.print("MultisigContract: Proposal " # proposalId # " signed by " # Principal.toText(caller) # " (" # debug_show(currentApprovals) # "/" # debug_show(walletConfig.threshold) # ")");

                    // Auto-execute if ready and not blocked by reentrancy protection
                    if (readyForExecution and not isExecuting) {
                        Debug.print("MultisigContract: Auto-executing proposal " # proposalId);

                        // Execute the proposal automatically
                        isExecuting := true;
                        try {
                            let executionResult = await executeProposalActions(updatedProposal, caller);

                            // Update proposal status after execution
                            let executedProposal = {
                                updatedProposal with
                                status = if (executionResult.success) #Executed else #Failed;
                                executedAt = ?Time.now();
                                executedBy = ?caller;
                            };

                            proposals.put(proposalId, executedProposal);

                            // Create execution event
                            let executionEvent = createEvent(
                                #ProposalExecuted,
                                caller,
                                ?("Proposal " # proposalId # " auto-executed")
                            );
                            events.put(executionEvent.id, executionEvent);

                            updateLastActivity();
                            isExecuting := false;

                            Debug.print("MultisigContract: Auto-execution completed for proposal " # proposalId # " - Success: " # debug_show(executionResult.success));

                            #ok({
                                proposalId = proposalId;
                                signatureId = generateSignatureId();
                                currentApprovals = currentApprovals;
                                requiredApprovals = walletConfig.threshold;
                                readyForExecution = false; // Already executed
                            })
                        } catch (error) {
                            isExecuting := false;
                            Debug.print("MultisigContract: Auto-execution failed for proposal " # proposalId # " - Error: " # Error.message(error));

                            // Mark as failed
                            let failedProposal = {
                                updatedProposal with
                                status = #Failed;
                                executedAt = ?Time.now();
                                executedBy = ?caller;
                            };
                            proposals.put(proposalId, failedProposal);

                            #ok({
                                proposalId = proposalId;
                                signatureId = generateSignatureId();
                                currentApprovals = currentApprovals;
                                requiredApprovals = walletConfig.threshold;
                                readyForExecution = false;
                            })
                        };
                    } else {
                        #ok({
                            proposalId = proposalId;
                            signatureId = generateSignatureId();
                            currentApprovals = currentApprovals;
                            requiredApprovals = walletConfig.threshold;
                            readyForExecution = readyForExecution;
                        })
                    }
                };
                case null #err(#ProposalNotFound);
            }
        };

        public shared({caller}) func executeProposal(
            proposalId: MultisigTypes.ProposalId
        ): async Result.Result<MultisigTypes.ExecutionResult, MultisigTypes.ProposalError> {

            // Reentrancy protection
            if (isExecuting) {
                return #err(#SecurityViolation("Execution already in progress"));
            };

            if (not isSigner(caller)) {
                return #err(#Unauthorized);
            };

            // Rate limiting for execution
            switch (lastProposalTimes.get(caller)) {
                case (?lastTime) {
                    let timeSinceLastAction = Time.now() - lastTime;
                    if (timeSinceLastAction < MIN_PROPOSAL_INTERVAL) {
                        return #err(#SecurityViolation("Rate limit exceeded"));
                    };
                };
                case null {};
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
                    isExecuting := true;
                    try {
                        let executionResult = await executeProposalActions(proposal, caller);

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
                        lastProposalTimes.put(caller, Time.now());

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
                    } finally {
                        isExecuting := false;
                    }
                };
                case null #err(#InvalidProposal("Proposal not found"));
            }
        };

        // ============== EXECUTION ENGINE ==============

        private func executeProposalActions(proposal: MultisigTypes.Proposal, caller: Principal): async MultisigTypes.ExecutionResult {
            let actionResults = Buffer.Buffer<MultisigTypes.ActionResult>(proposal.actions.size());
            let balanceChanges = Buffer.Buffer<MultisigTypes.BalanceChange>(0);
            let transactionIds = Buffer.Buffer<MultisigTypes.TransactionId>(0);
            var totalGasUsed: Nat = 0;
            var overallSuccess = true;

            for (actionIndex in proposal.actions.keys()) {
                let action = proposal.actions[actionIndex];
                try {
                    let result = await executeAction(action, actionIndex, proposal.proposer);
                    actionResults.add(result);

                    if (not result.success) {
                        overallSuccess := false;
                    };

                    switch (result.gasUsed) {
                        case (?gas) totalGasUsed += gas;
                        case null {};
                    };

                } catch (e) {
                    let errorMsg = Error.message(e);
                    Debug.print("MultisigContract: Action " # Nat.toText(actionIndex) # " failed with error: " # errorMsg);
                    
                    let errorResult: MultisigTypes.ActionResult = {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?errorMsg;
                        gasUsed = null;
                        result = null;
                    };
                    actionResults.add(errorResult);
                    overallSuccess := false;
                };
            };

            // Log final execution result
            Debug.print("MultisigContract: Execution completed - Success: " # debug_show(overallSuccess) # 
                       ", Actions: " # Nat.toText(actionResults.size()) # 
                       ", Gas used: " # Nat.toText(totalGasUsed));
            
            // Log individual action results for debugging
            for (i in actionResults.vals()) {
                if (not i.success) {
                    let error = switch (i.error) { case (?err) err; case null "Unknown error" };
                    Debug.print("MultisigContract: Action " # Nat.toText(i.actionIndex) # " failed: " # error);
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

        private func executeAction(action: MultisigTypes.ProposalAction, actionIndex: Nat, proposer: Principal): async MultisigTypes.ActionResult {
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
                    await executeWalletModification(modData, actionIndex, proposer)
                };
                case (#ContractCall(callData)) {
                    await executeContractCall(callData, actionIndex)
                };
                case (#EmergencyAction(emergencyData)) {
                    await executeEmergencyAction(emergencyData, actionIndex, proposer)
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
            
            Debug.print("MultisigContract: Executing transfer - Recipient: " # Principal.toText(transferData.recipient) # 
                       ", Amount: " # Nat.toText(transferData.amount) # 
                       ", Asset: " # debug_show(transferData.asset));

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
                    Debug.print("MultisigContract: Processing ICP transfer...");
                    
                    // Update balance first to get real balance
                    let currentBalance = await* getICPBalance();
                    icpBalance := currentBalance;
                    Debug.print("MultisigContract: Current ICP balance: " # Nat.toText(icpBalance));
                    
                    if (transferData.amount > icpBalance) {
                        Debug.print("MultisigContract: Insufficient ICP balance");
                        return {
                            actionIndex = actionIndex;
                            success = false;
                            error = ?("Insufficient ICP balance: " # Nat.toText(icpBalance) # " available, " # Nat.toText(transferData.amount) # " requested");
                            gasUsed = null;
                            result = null;
                        };
                    };

                    Debug.print("MultisigContract: Executing ICP transfer...");
                    // Execute actual ICP transfer
                    switch (await* executeICPTransfer(transferData.recipient, transferData.amount, transferData.memo)) {
                        case (#ok(txIndex)) {
                            Debug.print("MultisigContract: ICP transfer successful, txIndex: " # Nat.toText(txIndex));
                            {
                                actionIndex = actionIndex;
                                success = true;
                                error = null;
                                gasUsed = ?100_000; // Estimated gas
                                result = ?("ICP transfer completed. Transaction index: " # Nat.toText(txIndex));
                            }
                        };
                        case (#err(error)) {
                            Debug.print("MultisigContract: ICP transfer failed: " # error);
                            {
                                actionIndex = actionIndex;
                                success = false;
                                error = ?error;
                                gasUsed = null;
                                result = null;
                            }
                        };
                    };
                };
                case (#Token(tokenCanister)) {
                    // Execute ICRC1 token transfer
                    switch (await* executeICRCTransfer(tokenCanister, transferData.recipient, transferData.amount, transferData.memo)) {
                        case (#ok(txIndex)) {
                            {
                                actionIndex = actionIndex;
                                success = true;
                                error = null;
                                gasUsed = ?150_000; // Estimated gas for token transfer
                                result = ?("Token transfer completed. Transaction index: " # Nat.toText(txIndex));
                            }
                        };
                        case (#err(error)) {
                            {
                                actionIndex = actionIndex;
                                success = false;
                                error = ?error;
                                gasUsed = null;
                                result = null;
                            }
                        };
                    };
                };
                case (#NFT(_)) {
                    // TODO: Implement NFT transfer - this is more complex as NFT standards vary
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
            actionIndex: Nat,
            proposer: Principal
        ): async MultisigTypes.ActionResult {

            switch (modData.modificationType) {
                case (#AddSigner(signerData)) {
                    let newSigner: MultisigTypes.SignerInfo = {
                        principal = signerData.signer;
                        name = signerData.name;
                        role = signerData.role;
                        addedAt = Time.now();
                        addedBy = proposer;
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
                case (#UpdateSignerRole(roleData)) {
                    // Update signer role
                    switch (signers.get(roleData.signer)) {
                        case (?signer) {
                            let updatedSigner = { signer with role = roleData.newRole };
                            signers.put(roleData.signer, updatedSigner);

                            {
                                actionIndex = actionIndex;
                                success = true;
                                error = null;
                                gasUsed = ?40_000;
                                result = ?"Signer role updated successfully";
                            }
                        };
                        case null {
                            {
                                actionIndex = actionIndex;
                                success = false;
                                error = ?"Signer not found";
                                gasUsed = null;
                                result = null;
                            }
                        };
                    };
                };
                case (#AddObserver(observerData)) {
                    // Add observer as a signer with Observer role
                    let newObserver: MultisigTypes.SignerInfo = {
                        principal = observerData.observer;
                        name = observerData.name; // Use provided name
                        role = #Observer;
                        addedAt = Time.now();
                        addedBy = proposer;
                        lastSeen = null;
                        isActive = true;
                        requiresTwoFactor = false;
                        ipWhitelist = null;
                        sessionTimeout = null;
                        delegatedVoting = false;
                        delegatedTo = null;
                        delegationExpiry = null;
                    };

                    signers.put(observerData.observer, newObserver);

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?50_000;
                        result = ?"Observer added successfully";
                    }
                };
                case (#RemoveObserver(observerData)) {
                    // Remove observer by deleting from signers
                    signers.delete(observerData.observer);

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?30_000;
                        result = ?"Observer removed successfully";
                    }
                };
                case (#ChangeVisibility(visibilityData)) {
                    // Change wallet visibility (public/private)
                    walletConfig := {
                        walletConfig with isPublic = visibilityData.isPublic
                    };

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?20_000;
                        result = if (visibilityData.isPublic) ?"Wallet is now public" else ?"Wallet is now private";
                    }
                };
                case (#UpdateWalletConfig(configData)) {
                    // Update entire wallet config
                    walletConfig := configData.config;

                    {
                        actionIndex = actionIndex;
                        success = true;
                        error = null;
                        gasUsed = ?100_000;
                        result = ?"Wallet configuration updated successfully";
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
            actionIndex: Nat,
            proposer: Principal
        ): async MultisigTypes.ActionResult {

            // Security check: Only owners can execute emergency actions
            if (not isOwner(proposer)) {
                return {
                    actionIndex = actionIndex;
                    success = false;
                    error = ?"Only owners can execute emergency actions";
                    gasUsed = null;
                    result = null;
                };
            };

            switch (emergencyData.actionType) {
                case (#FreezeWallet) {
                    status := #Frozen;
                    let event = createEvent(#EmergencyAction, proposer, ?"Wallet frozen by owner");
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
                    let event = createEvent(#EmergencyAction, proposer, ?"Wallet unfrozen by owner");
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
                    // Additional validation for transfer amount
                    if (transferData.amount > 1_000_000_000_000_000) { // Max 1M ICP
                        return #err("Transfer amount exceeds maximum limit");
                    };
                };
                case (#WalletModification(modData)) {
                    switch (modData.modificationType) {
                        case (#AddSigner(addData)) {
                            if (Principal.isAnonymous(addData.signer)) {
                                return #err("Invalid signer address");
                            };
                        };
                        case (#RemoveSigner(removeData)) {
                            if (Principal.isAnonymous(removeData.signer)) {
                                return #err("Invalid signer address");
                            };
                        };
                        case (#ChangeThreshold(thresholdData)) {
                            if (thresholdData.newThreshold == 0) {
                                return #err("Threshold must be greater than 0");
                            };
                        };
                        case (_) {};
                    };
                };
                case (#ContractCall(callData)) {
                    if (Principal.isAnonymous(callData.canister)) {
                        return #err("Invalid contract address");
                    };
                    if (callData.method.size() == 0) {
                        return #err("Method name cannot be empty");
                    };
                };
                case (_) {};
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
                case (#Low) walletConfig.threshold; // Always use wallet threshold, do not reduce for low risk
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

        // Public function to update balances (callable by signers)
        public shared({caller}) func updateWalletBalances(): async Result.Result<(), Text> {
            if (not isSigner(caller) and caller != factory) {
                return #err("Only signers can update balances");
            };

            try {
                await* updateBalances();
                #ok()
            } catch (error) {
                #err("Failed to update balances: " # Error.message(error))
            }
        };

        public shared({caller}) func getWalletInfo(): async MultisigTypes.MultisigWallet {
            // Check if caller has permission to view this wallet
            if (not canViewWallet(caller)) {
                Debug.trap("Access denied: You don't have permission to view this wallet");
            };

            // Update balances for accurate information (only for authorized callers)
            if (isSigner(caller) or caller == factory) {
                try {
                    ignore await* updateBalances();
                } catch (error) {
                    Debug.print("Failed to update balances in getWalletInfo: " # Error.message(error));
                };
            };

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

        // Use ICRC standard ledger interface
        private type ICRCLedger = ICRC.ICRCLedger;

        // Constants for ICP ledger
        private var ICP_LEDGER_CANISTER_ID = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");

        // Execute ICP transfer using ICRC standard (following DistributionContract pattern)
        private func executeICPTransfer(
            to: Principal,
            amount: Nat,
            memo: ?Blob
        ): async* Result.Result<Nat, Text> {
            let icpLedger : ICRCLedger = actor(Principal.toText(ICP_LEDGER_CANISTER_ID));
            
            // Get transfer fee
            let transferFee = await icpLedger.icrc1_fee();
            Debug.print("MultisigContract: Transfer fee from ledger: " # Nat.toText(transferFee));
            Debug.print("MultisigContract: Transfer amount requested: " # Nat.toText(amount));
            
            // Check amount is sufficient (following DistributionContract pattern)
            let transferAmount = if (amount > transferFee) {
                Nat.sub(amount, transferFee)
            } else { 0 };
            
            Debug.print("MultisigContract: Calculated transfer amount after fee: " # Nat.toText(transferAmount));
            
            if (transferAmount == 0) {
                Debug.print("MultisigContract: Transfer amount is 0 after fee deduction");
                let minAmount = transferFee + 1; // Minimum + 1 for actual transfer
                return #err("Amount too small to cover transfer fee. Minimum required: " # Nat.toText(minAmount) # " e8s (fee: " # Nat.toText(transferFee) # " e8s), provided: " # Nat.toText(amount) # " e8s");
            };
            
            // Prepare transfer arguments (following DistributionContract pattern)
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
            
            // Execute transfer
            let transferResult = await icpLedger.icrc1_transfer(transferArgs);
            
            switch (transferResult) {
                case (#Ok(txIndex)) {
                    // Update local balance
                    icpBalance := Nat.sub(icpBalance, amount);
                    #ok(txIndex)
                };
                case (#Err(err)) {
                    let errorMsg = switch (err) {
                        case (#InsufficientFunds { balance }) "Insufficient funds: balance " # Nat.toText(balance);
                        case (#BadFee { expected_fee }) "Bad fee: expected " # Nat.toText(expected_fee);
                        case (#TooOld) "Transaction too old";
                        case (#CreatedInFuture { ledger_time = _ }) "Transaction created in future";
                        case (#Duplicate { duplicate_of }) "Duplicate transaction: " # Nat.toText(duplicate_of);
                        case (#TemporarilyUnavailable) "Service temporarily unavailable";
                        case (#GenericError { error_code; message }) "Error " # Nat.toText(error_code) # ": " # message;
                        case (#BadBurn { min_burn_amount }) "Bad burn: minimum " # Nat.toText(min_burn_amount);
                    };
                    #err(errorMsg)
                };
            }
        };

        // Execute ICRC1 transfer for token assets
        private func executeICRCTransfer(
            tokenCanisterId: Principal,
            to: Principal,
            amount: Nat,
            memo: ?Blob
        ): async* Result.Result<Nat, Text> {
            try {
                let tokenCanister : ICRCLedger = actor(Principal.toText(tokenCanisterId));

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


        // Create a transfer proposal
        public shared({caller}) func createTransferProposal(
            recipient: Principal,
            amount: Nat,
            asset: MultisigTypes.AssetType,
            memo: ?Blob,
            title: Text,
            description: Text
        ): async MultisigTypes.ProposalResult {

            // Check if caller is authorized signer
            if (not isSigner(caller)) {
                return #err(#Unauthorized);
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
            // Enhanced risk assessment to ensure proper threshold enforcement
            switch (asset) {
                case (#ICP) {
                    // For ICP transfers, use more conservative risk assessment
                    if (amount > 1_000_000_000) #High // > 10 ICP
                    else if (amount > 100_000_000) #Medium // > 1 ICP
                    else #Medium; // Always require at least Medium risk for any transfer
                };
                case (#Token(_)) {
                    // For tokens, default to Medium risk to ensure threshold compliance
                    #Medium;
                };
                case (#NFT(_)) #High; // NFTs are always high risk
            }
        };

        // Create wallet modification proposal (add/remove signer, change threshold)
        public shared({caller}) func createWalletModificationProposal(
            modificationType: MultisigTypes.WalletModificationType,
            title: Text,
            description: Text
        ): async MultisigTypes.ProposalResult {

            // Check if caller is authorized signer
            if (not isSigner(caller)) {
                return #err(#Unauthorized);
            };

            // Validate modification type
            switch (modificationType) {
                case (#AddSigner(signerData)) {
                    if (Principal.isAnonymous(signerData.signer)) {
                        return #err(#InvalidProposal("Invalid signer address"));
                    };
                    // Check if signer already exists
                    switch (signers.get(signerData.signer)) {
                        case (?_) return #err(#InvalidProposal("Signer already exists"));
                        case null {};
                    };
                };
                case (#RemoveSigner(signerData)) {
                    if (Principal.isAnonymous(signerData.signer)) {
                        return #err(#InvalidProposal("Invalid signer address"));
                    };
                    // Check if signer exists
                    switch (signers.get(signerData.signer)) {
                        case null return #err(#InvalidProposal("Signer does not exist"));
                        case (?_) {};
                    };
                    // Check if removing would leave too few signers
                    if (signers.size() <= 1) {
                        return #err(#InvalidProposal("Cannot remove last signer"));
                    };
                };
                case (#ChangeThreshold(thresholdData)) {
                    if (thresholdData.newThreshold == 0) {
                        return #err(#InvalidProposal("Threshold must be greater than 0"));
                    };
                    if (thresholdData.newThreshold > signers.size()) {
                        return #err(#InvalidProposal("Threshold cannot exceed number of signers"));
                    };
                };
                case (_) {
                    return #err(#InvalidProposal("Modification type not supported"));
                };
            };

            // Create wallet modification proposal
            let proposalId = generateProposalId();
            let proposalType = #WalletModification({
                modificationType = modificationType;
            });

            let riskLevel = #Medium; // Wallet modifications are always medium risk
            let requiredApprovals = calculateRequiredApprovals(riskLevel);

            let proposal: MultisigTypes.Proposal = {
                id = proposalId;
                walletId = walletId;
                proposalType = proposalType;
                title = title;
                description = description;
                actions = [{
                    actionType = #WalletModification({
                        modificationType = modificationType;
                    });
                    estimatedCost = ?50000; // Estimate cycles cost
                    riskAssessment = {
                        level = riskLevel;
                        factors = [#StructuralChange];
                        score = 0.4;
                        autoApproved = false;
                    };
                }];
                proposer = caller;
                proposedAt = Time.now();
                earliestExecution = null;
                expiresAt = Time.now() + walletConfig.maxProposalLifetime;
                requiredApprovals = requiredApprovals;
                currentApprovals = 0;
                approvals = [];
                rejections = [];
                status = #Pending;
                executedAt = null;
                executedBy = null;
                executionResult = null;
                risk = riskLevel;
                requiresConsensus = true; // Wallet modifications require consensus
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
                ?("Wallet modification proposal created: " # title)
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

        public shared({caller}) func resetICPLedger(): async Result.Result<(), Text> {
            if (not isSigner(caller) and caller != factory) {
                return #err("Only signers can reset ICP ledger");
            };
            
            ICP_LEDGER_CANISTER_ID := Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
            #ok()
        };

        // Note: executeProposal is already implemented above
        // ICRC transfer logic will be integrated into existing executeAction function

        // ============== HELPER FUNCTIONS ==============

        // No longer needed - ICRC1 uses Principal directly instead of account identifiers

        // Get real ICP balance from ledger using ICRC standard
        private func getICPBalance(): async* Nat {
            try {
                let icpLedger : ICRCLedger = actor(Principal.toText(ICP_LEDGER_CANISTER_ID));
                
                let account: ICRC.Account = {
                    owner = Principal.fromText(walletId);
                    subaccount = null;
                };
                
                let balance = await icpLedger.icrc1_balance_of(account);
                balance
            } catch (error) {
                Debug.print("Failed to get ICP balance: " # Error.message(error));
                0
            }
        };

        // Get ICRC1 token balance for this wallet
        private func getICRCBalance(tokenCanisterId: Principal): async* Nat {
            try {
                let tokenCanister : ICRCLedger = actor(Principal.toText(tokenCanisterId));

                let account: ICRC.Account = {
                    owner = Principal.fromText(walletId);
                    subaccount = null;
                };

                let balance = await tokenCanister.icrc1_balance_of(account);
                balance
            } catch (error) {
                Debug.print("Failed to get ICRC balance: " # Error.message(error));
                0
            }
        };

        // Update balances from real sources
        private func updateBalances(): async* () {
            // Update ICP balance
            icpBalance := await* getICPBalance();
            
            // Update token balances (simplified - in real implementation would iterate through all tokens)
            // This is a placeholder for token balance updates
        };

        private func generateProposalId(): MultisigTypes.ProposalId {
            let id = nextProposalId;
            nextProposalId += 1;
            Nat.toText(id)
        };

        private func generateSignatureId(): MultisigTypes.SignatureId {
            walletId # "-signature-" # Nat.toText(Int.abs(Time.now()) % 1000000)
        };

        private func createEvent(
            eventType: MultisigTypes.EventType,
            actorEvent: Principal,
            _description: ?Text
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

        system func preupgrade(){
            signersEntries := Iter.toArray(signers.entries());
            proposalsEntries := Iter.toArray(proposals.entries());
            eventsEntries := Iter.toArray(events.entries());
            observersArray := Buffer.toArray(observers);

            Debug.print("MultisigContract: Pre-upgrade completed for wallet " # walletId);
        };

        system func postupgrade(){
            // Do NOT clear stable variables - they are already restored automatically
            // signersEntries, proposalsEntries, eventsEntries are now stable and preserved
            
            // Reconstruct transient HashMaps from stable arrays
            signers := HashMap.fromIter<Principal, MultisigTypes.SignerInfo>(
                signersEntries.vals(),
                signersEntries.size(),
                Principal.equal,
                Principal.hash
            );

            proposals := HashMap.fromIter<MultisigTypes.ProposalId, MultisigTypes.Proposal>(
                proposalsEntries.vals(),
                proposalsEntries.size(),
                Text.equal,
                Text.hash
            );

            events := HashMap.fromIter<Text, MultisigTypes.WalletEvent>(
                eventsEntries.vals(),
                eventsEntries.size(),
                Text.equal,
                Text.hash
            );

            observers := Buffer.fromArray<Principal>(observersArray);

            // Initialize wallet if this is first deployment (no signers)
            if (signers.size() == 0) {
                initializeWallet();
            };

            Debug.print("MultisigContract: Post-upgrade completed for wallet " # walletId # " with " # 
                       debug_show(signers.size()) # " signers, " # 
                       debug_show(proposals.size()) # " proposals, " # 
                       debug_show(events.size()) # " events");
        };

        // Initialize wallet on contract deployment
        if (signers.size() == 0) {
            initializeWallet();
        };
    }