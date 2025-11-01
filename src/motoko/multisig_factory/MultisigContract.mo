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
import Bool "mo:base/Bool";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";

import MultisigTypes "../shared/types/MultisigTypes";
import MultisigUpgradeTypes "../shared/types/MultisigUpgradeTypes";
import IUpgradeable "../common/IUpgradeable";
import ICRC "../shared/types/ICRC";
import SafeMath "../shared/utils/SafeMath";
import Prim "mo:⛔";
import Cycles "mo:base/ExperimentalCycles";

persistent actor class MultisigContract(initArgs: MultisigUpgradeTypes.MultisigInitArgs) = self {

        // ============== TYPES ==============

        Debug.print("🚀 MultisigContract constructor called with initArgs: " # debug_show(initArgs));

        private type ProposalEntry = (MultisigTypes.ProposalId, MultisigTypes.Proposal);
        private type EventEntry = (Text, MultisigTypes.WalletEvent);
        private type SignerEntry = (Principal, MultisigTypes.SignerInfo);

        // ============== INITIALIZATION ==============

        // Determine deployment mode
        let isUpgrade: Bool = switch (initArgs) {
            case (#InitialSetup(_)) { false };
            case (#Upgrade(_)) { true };
        };

        // Extract metadata based on mode
        let init_id: MultisigTypes.WalletId = switch (initArgs) {
            case (#InitialSetup(setup)) {
                Debug.print("🆕 MultisigContract: Fresh deployment");
                setup.id
            };
            case (#Upgrade(upgrade)) {
                Debug.print("⬆️ MultisigContract: Upgrading from previous version");
                upgrade.id
            };
        };

        let init_config: MultisigTypes.WalletConfig = switch (initArgs) {
            case (#InitialSetup(setup)) { setup.config };
            case (#Upgrade(upgrade)) { upgrade.currentConfig };  // CURRENT config (may have been modified!)
        };

        let init_creator: Principal = switch (initArgs) {
            case (#InitialSetup(setup)) { setup.creator };
            case (#Upgrade(upgrade)) { upgrade.creator };
        };

        let init_factory: Principal = switch (initArgs) {
            case (#InitialSetup(setup)) { setup.factory };
            case (#Upgrade(upgrade)) { upgrade.factory };
        };

        let init_createdAt: Time.Time = switch (initArgs) {
            case (#InitialSetup(_)) { Time.now() };
            case (#Upgrade(upgrade)) { upgrade.createdAt };
        };

        // Extract runtime state if upgrading
        let upgradeState: ?MultisigUpgradeTypes.MultisigRuntimeState = switch (initArgs) {
            case (#InitialSetup(_)) { null };
            case (#Upgrade(upgrade)) { ?upgrade.runtimeState };
        };

        // ============== STATE ==============

        // Metadata (static or from upgrade)
        // Use canister's own principal as walletId for consistency
        private var walletId = if (init_id == "") {
            Principal.toText(Principal.fromActor(self))
        } else {
            init_id
        };
        private var walletConfig = init_config;
        private var creator = init_creator;
        private var factory = init_factory;
        private var createdAt = init_createdAt;

        // Core wallet state - STABLE for upgrades (implicitly stable in persistent actor)
        private var status: MultisigTypes.WalletStatus = switch (upgradeState) {
            case null { #Setup };
            case (?state) { state.status };
        };
        private var version: Nat = switch (upgradeState) {
            case null { 1 };
            case (?state) { state.version };
        };
        private var lastActivity = switch (upgradeState) {
            case null { Time.now() };
            case (?state) { state.lastActivity };
        };

        // Store target version for postupgrade (stable variable)
        private stable var targetVersionForUpgrade: ?IUpgradeable.Version = switch (initArgs) {
            case (#InitialSetup(_)) { null };
            case (#Upgrade(upgrade)) { upgrade.targetVersion };
        };

        // Contract version for upgrade tracking
        private var contractVersion: IUpgradeable.Version = switch (initArgs) {
            case (#InitialSetup(_)) { { major = 1; minor = 0; patch = 0 } };  // Fresh deployment
            case (#Upgrade(upgrade)) {
                // For upgrades, start with current version and let postupgrade handle the update
                let currentPatch = upgrade.runtimeState.version;
                { major = 1; minor = 0; patch = currentPatch }
            };
        };

        // ================ UPGRADE STATE MANAGEMENT ================
        // Contract self-locks when requesting upgrade, factory unlocks when done/failed/timeout

        /// Upgrade mode state
        private var isUpgrading : Bool = false;
        private var upgradeRequestedAt : ?Int = null;
        private var upgradeRequestId : ?Text = null;

        /// Timeout configuration (30 minutes in nanoseconds)
        private let UPGRADE_TIMEOUT_NANOS : Int = 30 * 60 * 1_000_000_000;

        Debug.print("🚀 MultisigContract initialized with version: " # debug_show(contractVersion) #
                   " (upgrade mode: " # debug_show(switch (initArgs) { case (#InitialSetup(_)) { "fresh" }; case (#Upgrade(_)) { "upgrade" } }) # ")");

        // Signers and permissions - STABLE for upgrades
        private var signersEntries: [SignerEntry] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.signersEntries };
        };
        private var observersArray: [Principal] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.observersArray };
        };

        // Proposals and execution - STABLE for upgrades
        private var nextProposalId: Nat = switch (upgradeState) {
            case null { 1 };
            case (?state) { state.nextProposalId };
        };
        private var proposalsEntries: [ProposalEntry] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.proposalsEntries };
        };
        private var totalProposals: Nat = switch (upgradeState) {
            case null { 0 };
            case (?state) { state.totalProposals };
        };
        private var executedProposals: Nat = switch (upgradeState) {
            case null { 0 };
            case (?state) { state.executedProposals };
        };
        private var failedProposals: Nat = switch (upgradeState) {
            case null { 0 };
            case (?state) { state.failedProposals };
        };

        // Asset tracking - STABLE for upgrades
        private var icpBalance: Nat = switch (upgradeState) {
            case null { 0 };
            case (?state) { state.icpBalance };
        };
        private var tokensArray: [MultisigTypes.TokenBalance] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.tokensArray };
        };
        private var nftsArray: [MultisigTypes.NFTBalance] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.nftsArray };
        };

        // Watched assets - STABLE for upgrades
        private var watchedAssets: [MultisigTypes.AssetType] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.watchedAssets };
        };

        // Security and monitoring - STABLE for upgrades
        private var securityFlags: MultisigTypes.SecurityFlags = switch (upgradeState) {
            case null {
                {
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
                }
            };
            case (?state) { state.securityFlags };
        };

        // Reentrancy protection - STABLE for upgrades
        private var isExecuting: Bool = switch (upgradeState) {
            case null { false };
            case (?state) { state.isExecuting };
        };
        private var emergencyPaused: Bool = switch (upgradeState) {
            case null { false };
            case (?state) { state.emergencyPaused };
        };

        // Enhanced rate limiting - Runtime state (will be reconstructed)
        private transient var lastProposalTimes = HashMap.HashMap<Principal, Int>(10, Principal.equal, Principal.hash);
        private transient var dailyLimitsUsage = HashMap.HashMap<Text, Nat>(10, Text.equal, Text.hash);

        // Events and audit trail - STABLE for upgrades
        private var eventsEntries: [EventEntry] = switch (upgradeState) {
            case null { [] };
            case (?state) { state.eventsEntries };
        };
        private var nextEventId: Nat = switch (upgradeState) {
            case null { 1 };
            case (?state) { state.nextEventId };
        };

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


        // Security Constants
        private let MAX_PROPOSALS_PER_HOUR = 10;
        private let MIN_PROPOSAL_INTERVAL = 60_000_000_000; // 1 minute in nanoseconds
        private let SECURITY_COOLDOWN = 300_000_000_000; // 5 minutes
        private let MAX_FAILED_ATTEMPTS = 5;
        private let EMERGENCY_THRESHOLD_MULTIPLIER = 2; // Require 2x normal threshold for emergency actions
        private let MAX_TRANSFER_AMOUNT = 1_000_000_000_000; // 10,000 ICP in e8s
        private let DAILY_LIMIT_RESET_INTERVAL = 86_400_000_000_000; // 24 hours in nanoseconds

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
            // Debug.print("MultisigContract: Initialized wallet " # walletId # " with " # debug_show(signers.size()) # " signers");
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

        private func isSignerInternal(caller: Principal): Bool {
            switch (signers.get(caller)) {
                case (?signer) {
                    signer.isActive and (signer.role == #Owner or signer.role == #Signer)
                };
                case null false;
            };
        };

        private func isOwnerInternal(caller: Principal): Bool {
            switch (signers.get(caller)) {
                case (?signer) signer.isActive and signer.role == #Owner;
                case null false;
            };
        };

        // ============== SECURITY GUARDS ==============

        private func nonReentrant<T>(f: () -> T): T {
            if (isExecuting) {
                Debug.trap("Reentrancy detected");
            };
            isExecuting := true;
            let result = f();
            isExecuting := false;
            result
        };

        private func whenNotPaused<T>(f: () -> T): T {
            if (emergencyPaused) {
                Debug.trap("Contract is paused");
            };
            f()
        };

        private func validateAmountSafe(amount: Nat): Result.Result<(), Text> {
            switch (SafeMath.validateAmount(amount, 1, MAX_TRANSFER_AMOUNT)) {
                case (#err(msg)) { #err(msg) };
                case (#ok()) { #ok() };
            }
        };

        private func checkDailyLimitSafe(asset: MultisigTypes.AssetType, amount: Nat): Result.Result<(), Text> {
            let assetKey = switch (asset) {
                case (#ICP) { "ICP" };
                case (#Token(principal)) { Principal.toText(principal) };
                case (#NFT(nftData)) { Principal.toText(nftData.canister) # "-" # Nat.toText(nftData.tokenId) };
            };

            let currentUsage = switch (dailyLimitsUsage.get(assetKey)) {
                case (?usage) { usage };
                case null { 0 };
            };

            switch (SafeMath.addNat(currentUsage, amount)) {
                case (#err(msg)) { #err("Daily limit calculation error: " # msg) };
                case (#ok(newUsage)) {
                    let dailyLimit = switch (asset) {
                        case (#ICP) { MAX_TRANSFER_AMOUNT };
                        case (#Token(_)) { MAX_TRANSFER_AMOUNT };
                    };

                    if (newUsage > dailyLimit) {
                        #err("Daily limit exceeded")
                    } else {
                        dailyLimitsUsage.put(assetKey, newUsage);
                        #ok()
                    }
                };
            }
        };

        private func isEmergencyAction(proposalType: MultisigTypes.ProposalType): Bool {
            switch (proposalType) {
                case (#Emergency(_)) true;
                case _ false;
            }
        };

        private func calculateRequiredApprovalsSafe(proposalType: MultisigTypes.ProposalType): Nat {
            let baseThreshold = walletConfig.threshold;
            if (isEmergencyAction(proposalType)) {
                switch (SafeMath.mulNat(baseThreshold, EMERGENCY_THRESHOLD_MULTIPLIER)) {
                    case (#ok(result)) { Nat.min(result, signers.size()) };
                    case (#err(_)) { signers.size() }; // Fallback to max
                }
            } else {
                baseThreshold
            }
        };

        // ============== COMPREHENSIVE INPUT VALIDATION ==============

        private func validatePrincipalInput(principal: Principal): Result.Result<(), Text> {
            if (Principal.isAnonymous(principal)) {
                return #err("Anonymous principal not allowed");
            };
            let textForm = Principal.toText(principal);
            if (textForm.size() < 5) {
                return #err("Invalid principal format");
            };
            #ok()
        };

        private func validateProposalTitle(title: Text): Result.Result<(), Text> {
            if (title.size() == 0) {
                return #err("Title cannot be empty");
            };
            if (title.size() > 200) {
                return #err("Title too long (max 200 characters)");
            };
            #ok()
        };

        private func validateProposalDescription(description: Text): Result.Result<(), Text> {
            if (description.size() > 2000) {
                return #err("Description too long (max 2000 characters)");
            };
            #ok()
        };

        private func validateTransferParams(recipient: Principal, amount: Nat, asset: MultisigTypes.AssetType): Result.Result<(), Text> {
            // Validate recipient
            switch (validatePrincipalInput(recipient)) {
                case (#err(msg)) { return #err("Invalid recipient: " # msg) };
                case (#ok()) {};
            };

            // Validate amount
            switch (validateAmountSafe(amount)) {
                case (#err(msg)) { return #err("Invalid amount: " # msg) };
                case (#ok()) {};
            };

            // Additional asset-specific validation
            switch (asset) {
                case (#ICP) {
                    if (amount < 10000) { // 0.0001 ICP minimum
                        return #err("ICP amount too small (minimum 0.0001 ICP)");
                    };
                };
                case (#Token(_)) {
                    // Token-specific validation can be added here
                };
                case (#NFT(_)) {
                    // NFT transfers usually have amount = 1
                    if (amount != 1) {
                        return #err("NFT amount must be 1");
                    };
                };
            };

            #ok()
        };

        private func validateThresholdChange(newThreshold: Nat): Result.Result<(), Text> {
            if (newThreshold == 0) {
                return #err("Threshold must be greater than 0");
            };
            if (newThreshold > signers.size()) {
                return #err("Threshold cannot exceed number of signers");
            };
            if (newThreshold == walletConfig.threshold) {
                return #err("New threshold must be different from current");
            };
            #ok()
        };

        // Enhanced rate limiting with proper validation
        private func checkAdvancedRateLimit(caller: Principal, proposalType: MultisigTypes.ProposalType): Result.Result<(), Text> {
            let now = Time.now();

            // Check basic interval
            switch (lastProposalTimes.get(caller)) {
                case (?lastTime) {
                    if (now - lastTime < MIN_PROPOSAL_INTERVAL) {
                        let waitTime = Int.abs(MIN_PROPOSAL_INTERVAL - (now - lastTime)) / 1_000_000_000;
                        return #err("Rate limit exceeded: must wait " #
                                  Nat.toText(waitTime) #
                                  " more seconds");
                    };
                };
                case null {};
            };

            // Emergency proposals have stricter limits
            if (isEmergencyAction(proposalType)) {
                switch (lastProposalTimes.get(caller)) {
                    case (?lastTime) {
                        if (now - lastTime < SECURITY_COOLDOWN) {
                            let cooldownTime = Int.abs(SECURITY_COOLDOWN - (now - lastTime)) / 1_000_000_000;
                        return #err("Security cooldown: emergency proposals require " #
                                      Nat.toText(cooldownTime) #
                                      " more seconds");
                        };
                    };
                    case null {};
                };
            };

            #ok()
        };

        private func isObserverInternal(caller: Principal): Bool {
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
            caller == creator or isSignerInternal(caller) or isObserverInternal(caller)
        };

        private func canCreateProposal(caller: Principal): Result.Result<(), Text> {
            if (status != #Active) {
                return #err("Wallet is not active");
            };

            if (not isSignerInternal(caller)) {
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
            let event = createEventWithProposal(
                #ProposalCreated,
                caller,
                ?("Proposal created: " # title),
                ?proposalId
            );
            events.put(event.id, event);

            // Update activity
            updateLastActivity();

            // Debug.print("MultisigContract: Created proposal " # proposalId # " by " # Principal.toText(caller));

            #ok(proposalId)
        };

        public shared({caller}) func signProposal(
            proposalId: MultisigTypes.ProposalId,
            signature: Blob,
            note: ?Text
        ): async MultisigTypes.SignatureResult {

            if (not isSignerInternal(caller)) {
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
                    let event = createEventWithProposal(
                        #ProposalSigned,
                        caller,
                        ?("Proposal " # proposalId # " signed"),
                        ?proposalId
                    );
                    events.put(event.id, event);

                    updateLastActivity();
                    lastProposalTimes.put(caller, Time.now());

                    // Debug.print("MultisigContract: Proposal " # proposalId # " signed by " # Principal.toText(caller) # " (" # debug_show(currentApprovals) # "/" # debug_show(walletConfig.threshold) # ")");

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
                            let executionEvent = createEventWithProposal(
                                #ProposalExecuted,
                                caller,
                                ?("Proposal " # proposalId # " auto-executed"),
                                ?proposalId
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

            // Emergency pause check
            if (emergencyPaused) {
                return #err(#SecurityViolation("Contract is paused"));
            };

            // Reentrancy protection
            if (isExecuting) {
                return #err(#SecurityViolation("Execution already in progress"));
            };
            isExecuting := true;

            if (not isSignerInternal(caller)) {
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
                            switch (SafeMath.addNat(executedProposals, 1)) {
                                case (#ok(newCount)) { executedProposals := newCount };
                                case (#err(_)) { /* Log error but continue */ };
                            }
                        } else {
                            switch (SafeMath.addNat(failedProposals, 1)) {
                                case (#ok(newCount)) { failedProposals := newCount };
                                case (#err(_)) { /* Log error but continue */ };
                            }
                        };

                        // Create event
                        let event = createEventWithProposal(
                            if (executionResult.success) #ProposalExecuted else #ProposalRejected,
                            caller,
                            ?("Proposal " # proposalId # " execution result: " # debug_show(executionResult.success)),
                            ?proposalId
                        );
                        events.put(event.id, event);

                        updateLastActivity();
                        lastProposalTimes.put(caller, Time.now());

                        Debug.print("MultisigContract: Proposal " # proposalId # " executed by " # Principal.toText(caller) #
                                   " with result: " # debug_show(executionResult.success));

                        #ok(executionResult)

                    } catch (e) {
                        switch (SafeMath.addNat(failedProposals, 1)) {
                            case (#ok(newCount)) { failedProposals := newCount };
                            case (#err(_)) { /* Log error but continue */ };
                        };
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

            // Validate amount using SafeMath
            switch (validateAmountSafe(transferData.amount)) {
                case (#err(error)) {
                    return {
                        actionIndex = actionIndex;
                        success = false;
                        error = ?("Amount validation failed: " # error);
                        gasUsed = null;
                        result = null;
                    };
                };
                case (#ok()) {};
            };

            // Check daily limits with SafeMath
            switch (checkDailyLimitSafe(transferData.asset, transferData.amount)) {
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

                    // Create signer added event
                    let signerEvent = createEvent(
                        #SignerAdded,
                        proposer,
                        ?("Signer added: " # Principal.toText(signerData.signer))
                    );
                    events.put(signerEvent.id, signerEvent);

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

                    // Create signer removed event
                    let signerEvent = createEvent(
                        #SignerRemoved,
                        proposer,
                        ?("Signer removed: " # Principal.toText(signerData.signer))
                    );
                    events.put(signerEvent.id, signerEvent);

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

                    // Create threshold changed event
                    let thresholdEvent = createEvent(
                        #WalletModified,
                        proposer,
                        ?("Threshold changed to " # Nat.toText(thresholdData.newThreshold))
                    );
                    events.put(thresholdEvent.id, thresholdEvent);

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

                            // Create role updated event
                            let roleEvent = createEvent(
                                #WalletModified,
                                proposer,
                                ?("Signer role updated: " # Principal.toText(roleData.signer))
                            );
                            events.put(roleEvent.id, roleEvent);

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

                    // Create observer added event
                    let observerEvent = createEvent(
                        #WalletModified,
                        proposer,
                        ?("Observer added: " # Principal.toText(observerData.observer))
                    );
                    events.put(observerEvent.id, observerEvent);

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

                    // Create observer removed event
                    let observerEvent = createEvent(
                        #WalletModified,
                        proposer,
                        ?("Observer removed: " # Principal.toText(observerData.observer))
                    );
                    events.put(observerEvent.id, observerEvent);

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
            if (not isOwnerInternal(proposer)) {
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
                            let assetKey = "ICP";
                            let currentUsage = switch (dailyLimitsUsage.get(assetKey)) {
                                case (?usage) usage;
                                case null 0;
                            };

                            if (currentUsage + amount > limit) {
                                return #err("Daily limit exceeded");
                            };

                            dailyLimitsUsage.put(assetKey, currentUsage + amount);
                        };
                        case (_) {}; // TODO: Implement for other assets
                    };
                };
                case null {};
            };

            #ok()
        };

        // ============== QUERY FUNCTIONS ==============

        // Quick visibility query methods for UI optimization
        public shared query func isOwner(principal: Principal): async Bool {
            switch (signers.get(principal)) {
                case (?signer) signer.isActive and signer.role == #Owner;
                case null false;
            };
        };

        public shared query func isSigner(principal: Principal): async Bool {
            switch (signers.get(principal)) {
                case (?signer) {
                    signer.isActive and (signer.role == #Owner or signer.role == #Signer)
                };
                case null false;
            };
        };

        public shared query func isObserver(principal: Principal): async Bool {
            switch (observers.vals() |> Iter.toArray(_)) {
                case (observerArray) {
                    Array.find<Principal>(observerArray, func(p) = p == principal) != null
                };
            }
        };

        public shared query func getUserRole(principal: Principal): async ?{
            role: Text;
            isActive: Bool;
            permissions: [Text];
        } {
            switch (signers.get(principal)) {
                case (?signer) {
                    let permissions = switch (signer.role) {
                        case (#Owner) ["create_proposal", "sign_proposal", "manage_signers", "emergency_controls", "view_audit"];
                        case (#Signer) ["create_proposal", "sign_proposal", "view_audit"];
                        case (#Observer) ["view_only"];
                    };

                    ?{
                        role = debug_show(signer.role);
                        isActive = signer.isActive;
                        permissions = permissions;
                    }
                };
                case null {
                    // Check if observer
                    if (isObserverInternal(principal)) {
                        ?{
                            role = "Observer";
                            isActive = true;
                            permissions = ["view_only"];
                        }
                    } else {
                        null
                    }
                };
            };
        };

        // Public function to update balances (callable by signers)
        public shared({caller}) func updateWalletBalances(): async Result.Result<(), Text> {
            if (not isSignerInternal(caller) and caller != factory) {
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
            if (isSignerInternal(caller) or caller == factory) {
                try {
                    await* updateBalances();
                } catch (error) {
                    Debug.print("Failed to update balances in getWalletInfo: " # Error.message(error));
                };
            };

            // Format version as semantic version string
            let versionString = Nat.toText(contractVersion.major) # "." #
                               Nat.toText(contractVersion.minor) # "." #
                               Nat.toText(contractVersion.patch);

            {
                id = walletId;
                // Use the contract's own canister ID instead of trying to parse walletId as Principal
                canisterId = Principal.fromActor(self);
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
                version = version; // Numeric version (deprecated)
                versionString = versionString; // Semantic version
            }
        };

        /// Lightweight summary for card/list views (optimized for performance)
        /// Returns essential info WITHOUT querying ledgers - frontend lazy loads balances
        public query func getWalletSummary(): async {
            name: Text;
            isPublic: Bool;
            status: MultisigTypes.WalletStatus;
            threshold: Nat;
            totalSigners: Nat;
            pendingProposals: Nat;
            executedProposals: Nat;
            tokenCount: Nat; // Number of watched tokens (excluding ICP)
            watchedAssets: [MultisigTypes.AssetType]; // For frontend to lazy load balances
            lastActivity: Time.Time; // Falls back to createdAt if no activity
            createdAt: Time.Time;
            version: Text; // Semantic version string (e.g., "1.0.0")
        } {
            // Count pending proposals
            var pendingCount: Nat = 0;
            for ((_, proposal) in proposals.entries()) {
                if (proposal.status == #Pending) {
                    pendingCount += 1;
                };
            };

            // Determine last activity (fallback to createdAt)
            let actualLastActivity = if (lastActivity == 0) {
                createdAt
            } else {
                lastActivity
            };

            // Format version as semantic version string
            let versionString = Nat.toText(contractVersion.major) # "." #
                               Nat.toText(contractVersion.minor) # "." #
                               Nat.toText(contractVersion.patch);

            {
                name = walletConfig.name;
                isPublic = walletConfig.isPublic;
                status = status;
                threshold = walletConfig.threshold;
                totalSigners = signers.size();
                pendingProposals = pendingCount;
                executedProposals = executedProposals;
                tokenCount = tokensArray.size(); // Count of non-ICP tokens
                watchedAssets = watchedAssets; // Frontend will lazy load balances for these
                lastActivity = actualLastActivity;
                createdAt = createdAt;
                version = versionString; // Semantic version for quick check
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

        // ============== ASSET MANAGEMENT ==============

        public shared({caller}) func addWatchedAsset(asset: MultisigTypes.AssetType): async Result.Result<(), Text> {
            if (not isSignerInternal(caller)) {
                return #err("Only signers can add watched assets");
            };

            // Check if asset already exists
            for (existingAsset in watchedAssets.vals()) {
                if (assetsEqual(existingAsset, asset)) {
                    return #err("Asset already being watched");
                };
            };

            // Add asset to watched list
            watchedAssets := Array.append(watchedAssets, [asset]);

            // Create event
            let event = createEvent(
                #WalletCreated, // Reuse existing event type or add new one
                caller,
                ?("Added watched asset")
            );
            events.put(event.id, event);

            #ok()
        };

        public shared({caller}) func removeWatchedAsset(asset: MultisigTypes.AssetType): async Result.Result<(), Text> {
            if (not isSignerInternal(caller)) {
                return #err("Only signers can remove watched assets");
            };

            // Filter out the asset
            watchedAssets := Array.filter<MultisigTypes.AssetType>(
                watchedAssets,
                func(existingAsset) = not assetsEqual(existingAsset, asset)
            );

            // Create event
            let event = createEvent(
                #WalletCreated, // Reuse existing event type or add new one
                caller,
                ?("Removed watched asset")
            );
            events.put(event.id, event);

            #ok()
        };

        public query func getWatchedAssets(): async [MultisigTypes.AssetType] {
            watchedAssets
        };

        // ================ IUPGRADEABLE INTERFACE ================

        /// Get current state serialized for upgrade
        /// CRITICAL: Returns CURRENT config (may have been modified via #UpdateWalletConfig)
        public query func getUpgradeArgs() : async Blob {
            let upgradeData: MultisigUpgradeTypes.MultisigUpgradeArgs = {
                // Metadata (static)
                id = walletId;
                creator = creator;
                factory = factory;
                createdAt = createdAt;

                // CURRENT config (DYNAMIC - may have been modified!)
                currentConfig = walletConfig;

                // Current runtime state
                runtimeState = {
                    status = status;
                    version = contractVersion.patch;  // Use current patch version
                    lastActivity = lastActivity;

                    // Signers and permissions (from HashMaps → Arrays)
                    signersEntries = Iter.toArray(signers.entries());
                    observersArray = Buffer.toArray(observers);

                    // Proposals and execution
                    nextProposalId = nextProposalId;
                    proposalsEntries = Iter.toArray(proposals.entries());
                    totalProposals = totalProposals;
                    executedProposals = executedProposals;
                    failedProposals = failedProposals;

                    // Asset tracking
                    icpBalance = icpBalance;
                    tokensArray = tokensArray;
                    nftsArray = nftsArray;

                    // Watched assets
                    watchedAssets = watchedAssets;

                    // Security and monitoring
                    securityFlags = securityFlags;

                    // Reentrancy protection
                    isExecuting = isExecuting;
                    emergencyPaused = emergencyPaused;

                    // Events and audit trail
                    eventsEntries = Iter.toArray(events.entries());
                    nextEventId = nextEventId;
                };

                // Target version (will be overwritten by factory)
                targetVersion = ?contractVersion;
            };

            // Serialize to Candid blob
            to_candid(upgradeData)
        };

        /// Validate if contract is ready for upgrade
        public query func canUpgrade() : async Result.Result<(), Text> {
            // Check 1: Not in executing state
            if (isExecuting) {
                return #err("Cannot upgrade: Transaction in progress");
            };

            // Check 2: Not in emergency pause (unless intentional)
            if (emergencyPaused) {
                return #err("Cannot upgrade: Contract is paused");
            };

            // Check 3: No pending high-risk proposals
            var hasHighRiskPending = false;
            for ((_, proposal) in proposals.entries()) {
                if (proposal.status == #Pending and proposal.risk == #High) {
                    hasHighRiskPending := true;
                };
            };

            if (hasHighRiskPending) {
                return #err("Cannot upgrade: High-risk proposals pending");
            };

            #ok()
        };

        // ============================================
        // UPGRADE STATE MANAGEMENT HELPERS
        // ============================================

        /// Guard function - check if contract is in upgrade mode
        /// Passively unlocks if timeout expired (fallback mechanism)
        private func _requireNotUpgrading() : Result.Result<(), Text> {
            if (isUpgrading) {
                switch (upgradeRequestedAt) {
                    case (?startTime) {
                        let age = Time.now() - startTime;

                        // PASSIVE SELF-UNLOCK if timeout exceeded (fallback)
                        if (age > UPGRADE_TIMEOUT_NANOS) {
                            Debug.print("⏰ CONTRACT: Timeout detected - auto-unlocking (fallback)");

                            isUpgrading := false;
                            upgradeRequestedAt := null;
                            upgradeRequestId := null;

                            #ok(())
                        } else {
                            let remainingMinutes = (UPGRADE_TIMEOUT_NANOS - age) / (60 * 1_000_000_000);
                            #err("Contract is being upgraded. Estimated completion: ~" # Int.toText(remainingMinutes) # " minutes. Please try again later.")
                        }
                    };
                    case null {
                        // Inconsistent state - unlock
                        isUpgrading := false;
                        #ok(())
                    };
                }
            } else {
                #ok(())
            }
        };

        // ============================================
        // UPGRADE STATE QUERY FUNCTIONS
        // ============================================

        /// Check if contract is in upgrade mode
        public query func isInUpgradeMode() : async Bool {
            isUpgrading
        };

        /// Get upgrade mode details
        public query func getUpgradeModeInfo() : async {
            isUpgrading: Bool;
            requestedAt: ?Int;
            requestId: ?Text;
            timeoutAt: ?Int;
        } {
            {
                isUpgrading = isUpgrading;
                requestedAt = upgradeRequestedAt;
                requestId = upgradeRequestId;
                timeoutAt = switch (upgradeRequestedAt) {
                    case (?startTime) { ?(startTime + UPGRADE_TIMEOUT_NANOS) };
                    case null { null };
                };
            }
        };

        /// Check if upgrade timeout has expired
        public query func isUpgradeTimeout() : async Bool {
            switch (upgradeRequestedAt) {
                case (?startTime) {
                    Time.now() - startTime > UPGRADE_TIMEOUT_NANOS
                };
                case null { false };
            }
        };

        /// Get current contract version
        public query func getVersion() : async IUpgradeable.Version {
            contractVersion
        };

        // ============================================
        // UPGRADE LIFECYCLE FUNCTIONS
        // ============================================

        /// Request self-upgrade to latest stable version
        /// CONTRACT LOCKS IMMEDIATELY when calling this function
        /// Only creator or signers can request upgrade
        public shared({caller}) func requestSelfUpgrade() : async Result.Result<Text, Text> {
            Debug.print("🔄 CONTRACT: requestSelfUpgrade called by " # Principal.toText(caller));

            // ============================================
            // AUTHORIZATION CHECK
            // ============================================

            let isCreator = caller == creator;
            let isSigner = switch (signers.get(caller)) {
                case (?_) { true };
                case null { false };
            };

            if (not isCreator and not isSigner) {
                Debug.print("❌ Unauthorized: Not creator or signer");
                return #err("Unauthorized: Only creator or signers can request self-upgrade");
            };

            // ============================================
            // CHECK NOT ALREADY UPGRADING
            // ============================================

            if (isUpgrading) {
                // Check if timeout expired
                switch (upgradeRequestedAt) {
                    case (?startTime) {
                        if (Time.now() - startTime > UPGRADE_TIMEOUT_NANOS) {
                            Debug.print("⏰ Previous upgrade timed out - allowing new request");
                        } else {
                            return #err("Upgrade already in progress. Please wait or cancel the current upgrade.");
                        };
                    };
                    case null {
                        // Inconsistent state - reset
                        isUpgrading := false;
                    };
                };
            };

            // ============================================
            // LOCK CONTRACT IMMEDIATELY
            // ============================================

            isUpgrading := true;
            upgradeRequestedAt := ?Time.now();

            Debug.print("🔒 CONTRACT LOCKED - All mutations blocked for 30 minutes or until upgrade completes");

            // ============================================
            // CALL FACTORY TO REQUEST UPGRADE
            // ============================================

            try {
                let factoryActor = actor(Principal.toText(factory)) : actor {
                    requestSelfUpgrade: () -> async Result.Result<(), Text>;
                };

                Debug.print("📞 Calling factory.requestSelfUpgrade()...");
                let result = await factoryActor.requestSelfUpgrade();

                switch (result) {
                    case (#ok()) {
                        Debug.print("✅ Upgrade request accepted by factory");

                        // Generate local request ID
                        let requestId = "upgrade-" # Int.toText(Time.now());
                        upgradeRequestId := ?requestId;

                        #ok(requestId)
                    };
                    case (#err(msg)) {
                        Debug.print("❌ Factory rejected upgrade request: " # msg);

                        // UNLOCK on failure
                        isUpgrading := false;
                        upgradeRequestedAt := null;
                        upgradeRequestId := null;

                        #err(msg)
                    };
                };
            } catch (e) {
                let errorMsg = "Failed to call factory: " # Error.message(e);
                Debug.print("💥 " # errorMsg);

                // UNLOCK on error
                isUpgrading := false;
                upgradeRequestedAt := null;
                upgradeRequestId := null;

                #err(errorMsg)
            }
        };

        /// Complete upgrade (called by factory after successful upgrade)
        /// This unlocks the contract and updates version
        public func completeUpgrade(newVersion: IUpgradeable.Version, caller: Principal) : async Result.Result<(), Text> {
            // Only factory can call this
            if (caller != factory) {
                return #err("Unauthorized: Only factory can complete upgrade");
            };

            if (not isUpgrading) {
                Debug.print("⚠️ Warning: completeUpgrade called but contract was not locked");
            };

            // Update version
            contractVersion := newVersion;

            // UNLOCK contract
            isUpgrading := false;
            upgradeRequestedAt := null;
            upgradeRequestId := null;

            Debug.print("🔓 CONTRACT UNLOCKED - Upgrade completed successfully to version " # debug_show(newVersion));

            #ok(())
        };

        /// Cancel upgrade (called by factory on failure OR timeout)
        /// This unlocks the contract
        public func cancelUpgrade(reason: Text, caller: Principal) : async Result.Result<(), Text> {
            // Factory OR creator/signers can cancel
            let isFactory = caller == factory;
            let isCreator = caller == creator;
            let isSigner = switch (signers.get(caller)) {
                case (?_) { true };
                case null { false };
            };
            let isAuthorized = isFactory or isCreator or isSigner;

            if (not isAuthorized) {
                return #err("Unauthorized: Only factory, creator, or signers can cancel upgrade");
            };

            if (not isUpgrading) {
                return #err("Contract is not in upgrade mode");
            };

            // UNLOCK contract
            isUpgrading := false;
            upgradeRequestedAt := null;
            upgradeRequestId := null;

            Debug.print("🔓 CONTRACT UNLOCKED - Upgrade cancelled: " # reason);

            #ok(())
        };

        /// Emergency unlock (creator or signers only) - for stuck contracts
        public shared({caller}) func emergencyUnlockUpgrade() : async Result.Result<(), Text> {
            // Only creator or signers can emergency unlock
            let isCreator = caller == creator;
            let isSigner = switch (signers.get(caller)) {
                case (?_) { true };
                case null { false };
            };

            if (not isCreator and not isSigner) {
                return #err("Unauthorized: Only creator or signers can emergency unlock");
            };

            if (not isUpgrading) {
                return #err("Contract is not in upgrade mode");
            };

            // UNLOCK contract
            isUpgrading := false;
            upgradeRequestedAt := null;
            upgradeRequestId := null;

            Debug.print("🚨 EMERGENCY UNLOCK by " # Principal.toText(caller));

            #ok(())
        };

        /// Comprehensive health check
        public query func healthCheck() : async IUpgradeable.HealthStatus {
            let issues = Buffer.Buffer<Text>(0);

            // Check 1: Signers configuration
            let signerCount = signers.size();
            if (signerCount == 0) {
                issues.add("No signers configured");
            };
            if (signerCount < walletConfig.threshold) {
                issues.add("Signer count below threshold");
            };

            // Check 2: Wallet status
            if (status == #Setup) {
                issues.add("Wallet still in setup mode");
            };

            // Check 3: Security status
            if (securityFlags.suspiciousActivity) {
                issues.add("Suspicious activity detected");
            };
            if (securityFlags.failedAttempts > 3) {
                issues.add("Multiple failed attempts: " # Nat.toText(securityFlags.failedAttempts));
            };

            // Check 4: Emergency status
            if (emergencyPaused) {
                issues.add("Contract is paused");
            };

            // Check 5: Threshold validation
            if (walletConfig.threshold > signerCount) {
                issues.add("Invalid threshold configuration");
            };

            // Check 6: Cycles balance
            let cyclesBalance = Cycles.balance();
            if (cyclesBalance < 100_000_000_000) { // 0.1T
                issues.add("Low cycles: " # Nat.toText(cyclesBalance));
            };

            {
                healthy = issues.size() == 0;
                issues = Buffer.toArray(issues);
                lastActivity = lastActivity;
                canisterCycles = cyclesBalance;
                memorySize = Prim.rts_memory_size();
            }
        };

        public shared({caller}) func getWalletBalances(
            assets: [MultisigTypes.AssetType]
        ): async Result.Result<[(Text, Nat)], Text> {
            if (not canViewWallet(caller)) {
                return #err("Access denied");
            };

            let results = Buffer.Buffer<(Text, Nat)>(assets.size());

            for (asset in assets.vals()) {
                switch (asset) {
                    case (#ICP) {
                        let balance = await* getICPBalance();
                        results.add(("ICP", balance));
                    };
                    case (#Token(canisterId)) {
                        let balance = await* getICRCBalance(canisterId);
                        results.add((Principal.toText(canisterId), balance));
                    };
                    case (#NFT(nftInfo)) {
                        // For NFTs, we could check ownership - simplified to 0 for now
                        results.add((Principal.toText(nftInfo.canister) # "-" # Nat.toText(nftInfo.tokenId), 0));
                    };
                };
            };

            #ok(Buffer.toArray(results))
        };

        // Helper function to compare assets
        private func assetsEqual(a1: MultisigTypes.AssetType, a2: MultisigTypes.AssetType): Bool {
            switch (a1, a2) {
                case (#ICP, #ICP) true;
                case (#Token(c1), #Token(c2)) Principal.equal(c1, c2);
                case (#NFT(n1), #NFT(n2)) Principal.equal(n1.canister, n2.canister) and n1.tokenId == n2.tokenId;
                case (_, _) false;
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
            
            // Check amount is sufficient using SafeMath
            let transferAmount = switch (SafeMath.subNat(amount, transferFee)) {
                case (#ok(result)) { result };
                case (#err(_)) { 0 }; // Amount < transferFee
            };

            Debug.print("MultisigContract: Calculated transfer amount after fee: " # Nat.toText(transferAmount));

            if (transferAmount == 0) {
                Debug.print("MultisigContract: Transfer amount is 0 after fee deduction");
                switch (SafeMath.addNat(transferFee, 1)) { // Minimum + 1 for actual transfer
                    case (#ok(minAmount)) {
                        return #err("Amount too small to cover transfer fee. Minimum required: " # Nat.toText(minAmount) # " e8s (fee: " # Nat.toText(transferFee) # " e8s), provided: " # Nat.toText(amount) # " e8s");
                    };
                    case (#err(msg)) {
                        return #err("Fee calculation error: " # msg);
                    };
                }
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
            if (not isSignerInternal(caller)) {
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
            let event = createEventWithProposal(
                #ProposalCreated,
                caller,
                ?("Transfer proposal created for " # Nat.toText(amount)),
                ?proposalId
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
            if (not isSignerInternal(caller)) {
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
                case (#AddObserver(observerData)) {
                    if (Principal.isAnonymous(observerData.observer)) {
                        return #err(#InvalidProposal("Invalid observer address"));
                    };
                    // Check if observer already exists
                    switch (signers.get(observerData.observer)) {
                        case (?_) return #err(#InvalidProposal("Observer already exists"));
                        case null {};
                    };
                };
                case (#RemoveObserver(observerData)) {
                    if (Principal.isAnonymous(observerData.observer)) {
                        return #err(#InvalidProposal("Invalid observer address"));
                    };
                    // Check if observer exists
                    switch (signers.get(observerData.observer)) {
                        case null return #err(#InvalidProposal("Observer does not exist"));
                        case (?_) {};
                    };
                };
                case (#ChangeVisibility(visibilityData)) {
                    // Visibility change is always valid
                    // Just check that it's actually changing the visibility
                    if (visibilityData.isPublic == walletConfig.isPublic) {
                        return #err(#InvalidProposal("Visibility is already set to this value"));
                    };
                };
                case (#UpdateWalletConfig(configData)) {
                    // Basic validation for wallet config update
                    if (configData.config.threshold == 0) {
                        return #err(#InvalidProposal("Threshold must be greater than 0"));
                    };
                    if (configData.config.threshold > signers.size()) {
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
            let event = createEventWithProposal(
                #ProposalCreated,
                caller,
                ?("Wallet modification proposal created: " # title),
                ?proposalId
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
            if (not isSignerInternal(caller) and caller != factory) {
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
            switch (SafeMath.addNat(nextProposalId, 1)) {
                case (#ok(newId)) { nextProposalId := newId };
                case (#err(_)) {
                    Debug.print("Warning: Proposal ID overflow detected, resetting to 1");
                    nextProposalId := 1;
                };
            };
            Nat.toText(id)
        };

        // Helper function to create and store a proposal with common validation
        private func createAndStoreProposal(
            caller: Principal,
            proposalType: MultisigTypes.ProposalType,
            title: Text,
            description: Text,
            actions: [MultisigTypes.ProposalAction]
        ): MultisigTypes.ProposalResult {

            // Check if caller is authorized signer
            if (not isSignerInternal(caller)) {
                return #err(#Unauthorized);
            };

            // Rate limiting check
            let now = Time.now();
            switch (lastProposalTimes.get(caller)) {
                case (?lastTime) {
                    if (now - lastTime < MIN_PROPOSAL_INTERVAL) {
                        return #err(#SecurityViolation("Rate limit exceeded"));
                    };
                };
                case null {};
            };

            // Generate proposal ID
            let proposalId = generateProposalId();

            // Calculate required approvals
            let requiredApprovals = walletConfig.threshold;

            // Create proposal
            let proposal: MultisigTypes.Proposal = {
                id = proposalId;
                walletId = walletId;
                proposalType = proposalType;
                title = title;
                description = description;
                actions = actions;
                proposer = caller;
                proposedAt = now;
                earliestExecution = null;
                expiresAt = now + (24 * 60 * 60 * 1_000_000_000); // 24 hours in nanoseconds
                requiredApprovals = requiredApprovals;
                currentApprovals = 0;
                approvals = [];
                rejections = [];
                status = #Pending;
                executedAt = null;
                executedBy = null;
                executionResult = null;
                risk = #Medium;
                requiresConsensus = false;
                emergencyOverride = false;
                dependsOn = [];
                executionOrder = null;
            };

            // Store proposal
            proposals.put(proposalId, proposal);

            // Update last proposal time
            lastProposalTimes.put(caller, now);

            // Create event
            let event = createEventWithProposal(#ProposalCreated, caller, ?("Proposal created: " # title), ?proposalId);
            events.put(event.id, event);

            #ok({
                proposalId = proposalId;
                status = #Pending;
                requiredApprovals = proposal.requiredApprovals;
                currentApprovals = 0;
            })
        };

        private func generateSignatureId(): MultisigTypes.SignatureId {
            walletId # "-signature-" # Nat.toText(Int.abs(Time.now()) % 1000000)
        };

        private func createEvent(
            eventType: MultisigTypes.EventType,
            actorEvent: Principal,
            _description: ?Text
        ): MultisigTypes.WalletEvent {
            createEventWithProposal(eventType, actorEvent, _description, null)
        };

        private func createEventWithProposal(
            eventType: MultisigTypes.EventType,
            actorEvent: Principal,
            _description: ?Text,
            proposalId: ?MultisigTypes.ProposalId
        ): MultisigTypes.WalletEvent {
            let eventId = "event-" # Nat.toText(nextEventId);
            switch (SafeMath.addNat(nextEventId, 1)) {
                case (#ok(newId)) { nextEventId := newId };
                case (#err(_)) {
                    Debug.print("Warning: Event ID overflow detected, resetting to 1");
                    nextEventId := 1;
                };
            };

            {
                id = eventId;
                walletId = walletId;
                eventType = eventType;
                timestamp = Time.now();
                actorEvent = actorEvent;
                data = null;
                proposalId = proposalId;
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

        // ============== EMERGENCY CONTROLS ==============

        public shared({caller}) func emergencyPause(): async Result.Result<(), Text> {
            // Only owners can pause
            if (not isOwnerInternal(caller)) {
                return #err("Unauthorized: Only owners can pause");
            };

            emergencyPaused := true;

            // Create emergency event
            let event = createEvent(#EmergencyAction, caller, ?"Emergency pause activated");
            events.put(event.id, event);

            #ok()
        };

        public shared({caller}) func emergencyUnpause(): async Result.Result<(), Text> {
            // Only owners can unpause
            if (not isOwnerInternal(caller)) {
                return #err("Unauthorized: Only owners can unpause");
            };

            emergencyPaused := false;

            // Create emergency event
            let event = createEvent(#EmergencyAction, caller, ?"Emergency pause deactivated");
            events.put(event.id, event);

            #ok()
        };

        public query func getEmergencyStatus(): async {
            isPaused: Bool;
            isExecuting: Bool;
        } {
            {
                isPaused = emergencyPaused;
                isExecuting = isExecuting;
            }
        };

        public shared({caller}) func resetDailyLimits(): async Result.Result<(), Text> {
            // Only owners can reset daily limits
            if (not isOwnerInternal(caller)) {
                return #err("Unauthorized: Only owners can reset daily limits");
            };

            // Clear daily limits
            dailyLimitsUsage := HashMap.HashMap<Text, Nat>(10, Text.equal, Text.hash);

            // Create event
            let event = createEvent(#WalletModified, caller, ?"Daily limits reset");
            events.put(event.id, event);

            #ok()
        };

        // ============== COMPREHENSIVE AUDIT MONITORING ==============

        public query func getSecurityMetrics(): async {
            failedAttempts: Nat;
            rateLimit: Bool;
            suspiciousActivity: Bool;
            lastSecurityEvent: ?Int;
            securityScore: Float;
        } {
            {
                failedAttempts = securityFlags.failedAttempts;
                rateLimit = securityFlags.rateLimit;
                suspiciousActivity = securityFlags.suspiciousActivity;
                lastSecurityEvent = securityFlags.lastSecurityEvent;
                securityScore = securityFlags.securityScore;
            }
        };

        // Audit log for comprehensive monitoring (only accessible by signers/owners)
        public shared query({caller}) func getAuditLog(
            startTime: ?Int,
            endTime: ?Int,
            eventTypes: ?[MultisigTypes.EventType],
            limit: ?Nat
        ): async Result.Result<{
            events: [MultisigTypes.WalletEvent];
            summary: {
                totalEvents: Nat;
                proposalsCreated: Nat;
                proposalsExecuted: Nat;
                signersAdded: Nat;
                signersRemoved: Nat;
                emergencyActions: Nat;
                securityIncidents: Nat;
            };
            securityAlerts: [{
                severity: Text;
                message: Text;
                timestamp: Int;
                principal: Principal;
            }];
        }, Text> {

            // Security check: only signers/owners can view audit logs
            if (not (isSignerInternal(caller) or isOwnerInternal(caller))) {
                return #err("Unauthorized: Only signers and owners can access audit logs");
            };

            let maxLimit = 1000;
            let actualLimit = switch (limit) {
                case (?l) { Nat.min(l, maxLimit) };
                case null { 100 };
            };

            let now = Time.now();
            let defaultStartTime = now - (30 * 24 * 60 * 60 * 1_000_000_000); // 30 days ago
            let actualStartTime = switch (startTime) {
                case (?st) { st };
                case null { defaultStartTime };
            };
            let actualEndTime = switch (endTime) {
                case (?et) { et };
                case null { now };
            };

            // Filter events
            let filteredEvents = Buffer.Buffer<MultisigTypes.WalletEvent>(0);
            let securityAlerts = Buffer.Buffer<{severity: Text; message: Text; timestamp: Int; principal: Principal}>(0);

            var proposalsCreated = 0;
            var proposalsExecuted = 0;
            var signersAdded = 0;
            var signersRemoved = 0;
            var emergencyActions = 0;
            var securityIncidents = 0;

            for ((eventId, event) in events.entries()) {
                if (event.timestamp >= actualStartTime and event.timestamp <= actualEndTime) {
                    // Check event type filter
                    let includeEvent = switch (eventTypes) {
                        case (?types) {
                            Array.find<MultisigTypes.EventType>(types, func(t) = t == event.eventType) != null
                        };
                        case null { true };
                    };

                    if (includeEvent and filteredEvents.size() < actualLimit) {
                        filteredEvents.add(event);

                        // Count event types for summary
                        switch (event.eventType) {
                            case (#ProposalCreated) { proposalsCreated += 1 };
                            case (#ProposalExecuted) { proposalsExecuted += 1 };
                            case (#SignerAdded) { signersAdded += 1 };
                            case (#SignerRemoved) { signersRemoved += 1 };
                            case (#EmergencyAction) {
                                emergencyActions += 1;
                                securityAlerts.add({
                                    severity = "HIGH";
                                    message = "Emergency action triggered";
                                    timestamp = event.timestamp;
                                    principal = event.actorEvent;
                                });
                            };
                            case _ {};
                        };

                        // Detect security incidents
                        if (isSecurityEvent(event)) {
                            securityIncidents += 1;
                            let severity = getEventSeverity(event);
                            securityAlerts.add({
                                severity = severity;
                                message = "Security event detected: " # debug_show(event.eventType);
                                timestamp = event.timestamp;
                                principal = event.actorEvent;
                            });
                        };
                    };
                };
            };

            #ok({
                events = Buffer.toArray(filteredEvents);
                summary = {
                    totalEvents = filteredEvents.size();
                    proposalsCreated = proposalsCreated;
                    proposalsExecuted = proposalsExecuted;
                    signersAdded = signersAdded;
                    signersRemoved = signersRemoved;
                    emergencyActions = emergencyActions;
                    securityIncidents = securityIncidents;
                };
                securityAlerts = Buffer.toArray(securityAlerts);
            })
        };

        // Helper function to determine if an event is security-related
        private func isSecurityEvent(event: MultisigTypes.WalletEvent): Bool {
            switch (event.eventType) {
                case (#EmergencyAction) { true };
                case (#SignerRemoved) { true };
                case (#WalletModified) { true };
                case _ { false };
            }
        };

        // Helper function to get event severity
        private func getEventSeverity(event: MultisigTypes.WalletEvent): Text {
            switch (event.eventType) {
                case (#EmergencyAction) { "CRITICAL" };
                case (#SignerRemoved) { "HIGH" };
                case (#WalletModified) { "MEDIUM" };
                case _ { "LOW" };
            }
        };

        // Real-time security monitoring
        public shared query({caller}) func getSecurityStatus(): async Result.Result<{
            isPaused: Bool;
            isExecuting: Bool;
            activeThreats: Nat;
            lastSecurityScan: Int;
            riskLevel: Text;
            recommendations: [Text];
        }, Text> {

            if (not (isSignerInternal(caller) or isOwnerInternal(caller))) {
                return #err("Unauthorized: Only signers and owners can access security status");
            };

            let activeThreats = (if (securityFlags.suspiciousActivity) 1 else 0) +
                               (if (securityFlags.rateLimit) 1 else 0) +
                               (if (securityFlags.failedAttempts > 3) 1 else 0);

            let riskLevel = if (activeThreats >= 2) "HIGH"
                          else if (activeThreats == 1) "MEDIUM"
                          else "LOW";

            let recommendations = Buffer.Buffer<Text>(0);
            if (securityFlags.suspiciousActivity) {
                recommendations.add("Review recent suspicious activities");
            };
            if (securityFlags.failedAttempts > 3) {
                recommendations.add("Consider temporary access restrictions");
            };
            if (not securityFlags.autoFreezeEnabled) {
                recommendations.add("Enable auto-freeze for enhanced security");
            };

            #ok({
                isPaused = emergencyPaused;
                isExecuting = isExecuting;
                activeThreats = activeThreats;
                lastSecurityScan = Time.now();
                riskLevel = riskLevel;
                recommendations = Buffer.toArray(recommendations);
            })
        };

        // Activity monitoring for specific time periods
        public shared query({caller}) func getActivityReport(
            timeRange: {startTime: Int; endTime: Int}
        ): async Result.Result<{
            proposalActivity: {
                created: Nat;
                executed: Nat;
                failed: Nat;
                pending: Nat;
            };
            transferActivity: {
                icpTransfers: Nat;
                tokenTransfers: Nat;
                totalValue: Nat; // in e8s
            };
            securityActivity: {
                emergencyActions: Nat;
                signerChanges: Nat;
                configChanges: Nat;
            };
            userActivity: [{
                principal: Text;
                proposalsCreated: Nat;
                proposalsSigned: Nat;
                lastActivity: Int;
            }];
        }, Text> {

            if (not (isSignerInternal(caller) or isOwnerInternal(caller))) {
                return #err("Unauthorized: Only signers and owners can access activity reports");
            };

            var proposalsCreated = 0;
            var proposalsExecuted = 0;
            var proposalsFailed = 0;
            var proposalsPending = 0;
            var icpTransfers = 0;
            var tokenTransfers = 0;
            var totalValue = 0;
            var emergencyActions = 0;
            var signerChanges = 0;
            var configChanges = 0;

            let userActivityMap = HashMap.HashMap<Principal, {
                var proposalsCreated: Nat;
                var proposalsSigned: Nat;
                var lastActivity: Int;
            }>(10, Principal.equal, Principal.hash);

            // Analyze events in time range
            for ((eventId, event) in events.entries()) {
                if (event.timestamp >= timeRange.startTime and event.timestamp <= timeRange.endTime) {
                    switch (event.eventType) {
                        case (#ProposalCreated) {
                            proposalsCreated += 1;
                            switch (userActivityMap.get(event.actorEvent)) {
                                case (?userData) {
                                    userData.proposalsCreated += 1;
                                    userData.lastActivity := event.timestamp;
                                };
                                case null {
                                    userActivityMap.put(event.actorEvent, {
                                        var proposalsCreated = 1;
                                        var proposalsSigned = 0;
                                        var lastActivity = event.timestamp;
                                    });
                                };
                            };
                        };
                        case (#ProposalExecuted) { proposalsExecuted += 1 };
                        case (#ProposalRejected) { proposalsFailed += 1 };
                        case (#EmergencyAction) { emergencyActions += 1 };
                        case (#SignerAdded or #SignerRemoved) { signerChanges += 1 };
                        case (#WalletModified) { configChanges += 1 };
                        case _ {};
                    };
                };
            };

            // Count pending proposals
            for ((proposalId, proposal) in proposals.entries()) {
                if (proposal.status == #Pending) {
                    proposalsPending += 1;
                };
            };

            let userActivityArray = Buffer.Buffer<{principal: Text; proposalsCreated: Nat; proposalsSigned: Nat; lastActivity: Int}>(userActivityMap.size());
            for ((principal, userData) in userActivityMap.entries()) {
                userActivityArray.add({
                    principal = Principal.toText(principal);
                    proposalsCreated = userData.proposalsCreated;
                    proposalsSigned = userData.proposalsSigned;
                    lastActivity = userData.lastActivity;
                });
            };

            #ok({
                proposalActivity = {
                    created = proposalsCreated;
                    executed = proposalsExecuted;
                    failed = proposalsFailed;
                    pending = proposalsPending;
                };
                transferActivity = {
                    icpTransfers = icpTransfers;
                    tokenTransfers = tokenTransfers;
                    totalValue = totalValue;
                };
                securityActivity = {
                    emergencyActions = emergencyActions;
                    signerChanges = signerChanges;
                    configChanges = configChanges;
                };
                userActivity = Buffer.toArray(userActivityArray);
            })
        };

        public shared({caller}) func updateSecurityScore(newScore: Float): async Result.Result<(), Text> {
            // Only factory can update security score
            if (caller != factory) {
                return #err("Unauthorized: Only factory can update security score");
            };

            securityFlags := {
                securityFlags with securityScore = newScore
            };

            #ok()
        };

        // ============== UPGRADE HOOKS ==============

        system func preupgrade(){
            signersEntries := Iter.toArray(signers.entries());
            proposalsEntries := Iter.toArray(proposals.entries());
            eventsEntries := Iter.toArray(events.entries());
            observersArray := Buffer.toArray(observers);
            // watchedAssets is already stable

            Debug.print("MultisigContract: Pre-upgrade completed for wallet " # walletId);
        };

        system func postupgrade() {
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

            // Update contract version using stored target version
            switch (targetVersionForUpgrade) {
                case (?targetVersion) {
                    contractVersion := targetVersion;
                    Debug.print("✅ Updated contract version to: " # debug_show(targetVersion));
                };
                case null {
                    // Backward compatibility: auto-increment if no target version provided
                    let currentPatch = contractVersion.patch;
                    contractVersion := { major = 1; minor = 0; patch = currentPatch + 1 };
                    Debug.print("⚠️ Auto-incremented contract version to: " # debug_show(contractVersion));
                };
            };

            // Initialize wallet if this is first deployment (no signers)
            if (signers.size() == 0) {
                initializeWallet();
            };

            Debug.print("MultisigContract: Post-upgrade completed for wallet " # walletId # " with " #
                       debug_show(signers.size()) # " signers, " #
                       debug_show(proposals.size()) # " proposals, " #
                       debug_show(events.size()) # " events, version: " # debug_show(contractVersion));

            // Signal upgrade completion for factory detection
            Debug.print("UPGRADE_COMPLETED:" # walletId # ":" # Principal.toText(Principal.fromActor(self)) # ":" # debug_show(contractVersion));
        };

        // Initialize wallet on contract deployment
        if (signers.size() == 0) {
            initializeWallet();
        };
    }