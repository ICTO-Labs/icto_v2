// ================ FUND MANAGER MODULE ================
// Unified fund management for launchpad deposits, refunds, and collections
// SECURITY LEVEL: CRITICAL (handles user funds)
//
// RESPONSIBILITIES:
// 1. Generate deterministic subaccounts (IC standard format)
// 2. Check balances in subaccounts
// 3. Transfer funds FROM subaccounts (refund OR collect)
// 4. Batch processing for multiple participants
// 5. Complete audit trail
//
// RENAMED FROM: SubaccountManager
// LOCATION: src/motoko/launchpad_factory/modules/FundManager.mo

import Result "mo:base/Result";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Blob "mo:base/Blob";
import Trie "mo:base/Trie";
import Option "mo:base/Option";

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import ICRCTypes "../../shared/types/ICRC";

module {

    // ================ TYPES ================
    
    /// Execution ID for tracking operations
    public type ExecutionId = Text;
    
    /// Financial transaction types
    public type FinancialTxType = {
        #Refund;
        #TokenTransfer;
        #FeePayment;
        #LiquidityProvision;
    };
    
    public type FinancialTxStatus = {
        #Pending;
        #Confirmed;
        #Failed: Text;
        #Rolled_Back;
    };
    
    /// Financial transaction record
    public type FinancialRecord = {
        txType: FinancialTxType;
        amount: Nat;
        from: Principal;
        to: Principal;
        blockIndex: ?Nat;
        timestamp: Time.Time;
        status: FinancialTxStatus;
        executionId: ExecutionId;
    };

    /// Transfer direction - determines recipient of funds
    public type TransferDirection = {
        #ToParticipant;    // Refund: subaccount → participant (sale failed)
        #ToLaunchpad;      // Collection: subaccount → launchpad main (sale succeeded)
    };

    /// Batch transfer summary
    public type BatchTransferResult = {
        totalAmount: Nat;
        successCount: Nat;
        failedCount: Nat;
        skippedCount: Nat;
        transactions: [FinancialRecord];
        failedTransfers: [(Principal, Text)];
    };

    /// Individual transfer result
    public type TransferResult = {
        participant: Principal;
        amount: Nat;
        blockIndex: ?Nat;
        status: TransferStatus;
        error: ?Text;
    };

    public type TransferStatus = {
        #Success;
        #Failed;
        #Skipped;
        #AlreadyProcessed;
        #ZeroBalance;
        #InsufficientForFee;
    };

    /// Generic transfer request
    public type TransferRequest = {
        to: Principal;
        amount: Nat;
        referenceId: ExecutionId;
    };

    // ================ FUND MANAGER CLASS ================

    public class FundManager(
        purchaseTokenCanisterId: Principal,
        purchaseTokenFee: Nat,
        launchpadPrincipal: Principal
    ) {

        // ================ SUBACCOUNT UTILITIES ================

        /// Generate IC-standard deterministic subaccount from Principal
        /// Format: [size_byte, ...principal_bytes..., ...padding_zeros...]
        /// This ensures consistent subaccount generation across all operations
        private func principalToSubAccount(userId: Principal) : [Nat8] {
            let p = Blob.toArray(Principal.toBlob(userId));
            Array.tabulate(32, func(i : Nat) : Nat8 {
                if (i >= p.size() + 1) 0
                else if (i == 0) (Nat8.fromNat(p.size()))
                else (p[i - 1])
            })
        };

        /// Get deposit account for participant (subaccount within launchpad canister)
        private func getDepositAccount(participant: Principal) : ICRCTypes.Account {
            let subAccount = principalToSubAccount(participant);
            let subAccountBlob = Blob.fromArray(subAccount);
            
            {
                owner = launchpadPrincipal;
                subaccount = ?subAccountBlob;
            }
        };

        /// Get launchpad main account (for fund collection)
        private func getLaunchpadMainAccount() : ICRCTypes.Account {
            {
                owner = launchpadPrincipal;
                subaccount = null;
            }
        };

        /// Convert subaccount bytes to hex string (for logging/debugging)
        private func toHex(arr: [Nat8]): Text {
            let hexChars = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
            Text.join("", Iter.map<Nat8, Text>(Iter.fromArray(arr), func (x: Nat8) : Text {
                let a = Nat8.toNat(x / 16);
                let b = Nat8.toNat(x % 16);
                hexChars[a] # hexChars[b]
            }))
        };

        // ================ PUBLIC API ================

        /// Check balance in participant's deposit subaccount
        public func checkBalance(participant: Principal) : async Result.Result<Nat, Text> {
            try {
                let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(purchaseTokenCanisterId));
                let depositAccount = getDepositAccount(participant);
                
                let balance = await ledger.icrc1_balance_of(depositAccount);
                
                Debug.print("💰 Balance for " # Principal.toText(participant) # ": " # Nat.toText(balance));
                #ok(balance)
            } catch (error) {
                #err("Failed to check balance: " # Error.message(error))
            }
        };

        /// Transfer funds from participant's subaccount
        /// Direction: #ToParticipant for refund, #ToLaunchpad for collection
        public func transferFromSubaccount(
            participant: LaunchpadTypes.Participant,
            direction: TransferDirection,
            executionId: ExecutionId,
            memo: Text
        ) : async TransferResult {
            
            let participantPrincipal = participant.principal;
            
            // VALIDATION #1: Check if already processed (for refunds)
            switch (direction) {
                case (#ToParticipant) {
                    if (participant.refundedAmount > 0) {
                        Debug.print("⚠️ Already refunded: " # Principal.toText(participantPrincipal));
                        return {
                            participant = participantPrincipal;
                            amount = 0;
                            blockIndex = null;
                            status = #AlreadyProcessed;
                            error = ?"Already refunded";
                        };
                    };
                };
                case (#ToLaunchpad) {
                    // For collection, we don't check if already processed
                    // Collection happens once for all participants
                };
            };

            // VALIDATION #2: Check balance in subaccount
            let balanceResult = await checkBalance(participantPrincipal);
            let balance = switch (balanceResult) {
                case (#ok(bal)) bal;
                case (#err(msg)) {
                    return {
                        participant = participantPrincipal;
                        amount = 0;
                        blockIndex = null;
                        status = #Failed;
                        error = ?("Balance check failed: " # msg);
                    };
                };
            };

            // VALIDATION #3: Check if balance is sufficient
            if (balance == 0) {
                Debug.print("⏭️ Zero balance: " # Principal.toText(participantPrincipal));
                return {
                    participant = participantPrincipal;
                    amount = 0;
                    blockIndex = null;
                    status = #ZeroBalance;
                    error = ?"Zero balance in subaccount";
                };
            };

            if (balance < purchaseTokenFee) {
                Debug.print("⚠️ Insufficient for fee: " # Principal.toText(participantPrincipal));
                return {
                    participant = participantPrincipal;
                    amount = balance;
                    blockIndex = null;
                    status = #InsufficientForFee;
                    error = ?("Balance " # Nat.toText(balance) # " < fee " # Nat.toText(purchaseTokenFee));
                };
            };

            // EXECUTION: Perform transfer
            try {
                let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(purchaseTokenCanisterId));
                
                let fromAccount = getDepositAccount(participantPrincipal);
                
                // Determine recipient based on direction
                let toAccount: ICRCTypes.Account = switch (direction) {
                    case (#ToParticipant) {
                        // Refund to participant
                        { owner = participantPrincipal; subaccount = null }
                    };
                    case (#ToLaunchpad) {
                        // Collect to launchpad main account
                        getLaunchpadMainAccount()
                    };
                };

                // Calculate transfer amount (balance - fee)
                let transferAmount = balance - purchaseTokenFee;

                // Build transfer args
                let transferArgs: ICRCTypes.TransferArgs = {
                    from_subaccount = fromAccount.subaccount;
                    to = toAccount;
                    amount = transferAmount;
                    fee = ?purchaseTokenFee;
                    memo = ?Text.encodeUtf8(memo);
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };

                Debug.print("📤 Transferring from subaccount...");
                Debug.print("   From: " # Principal.toText(fromAccount.owner) # " (subaccount)");
                Debug.print("   To: " # Principal.toText(toAccount.owner));
                Debug.print("   Amount: " # Nat.toText(transferAmount));
                Debug.print("   Fee: " # Nat.toText(purchaseTokenFee));

                let result = await ledger.icrc1_transfer(transferArgs);

                switch (result) {
                    case (#Ok(blockIndex)) {
                        Debug.print("✅ Transfer successful: block " # Nat.toText(blockIndex));
                        
                        {
                            participant = participantPrincipal;
                            amount = transferAmount;
                            blockIndex = ?blockIndex;
                            status = #Success;
                            error = null;
                        }
                    };
                    case (#Err(error)) {
                        let errorMsg = debug_show(error);
                        Debug.print("❌ Transfer failed: " # errorMsg);
                        
                        {
                            participant = participantPrincipal;
                            amount = 0;
                            blockIndex = null;
                            status = #Failed;
                            error = ?errorMsg;
                        }
                    };
                };
            } catch (error) {
                let errorMsg = Error.message(error);
                Debug.print("❌ Transfer exception: " # errorMsg);
                
                {
                    participant = participantPrincipal;
                    amount = 0;
                    blockIndex = null;
                    status = #Failed;
                    error = ?errorMsg;
                }
            }
        };

        /// Process batch transfers for multiple participants
        /// Used for both mass refunds and fund collection
        public func processBatchTransfers(
            participants: Trie.Trie<Text, LaunchpadTypes.Participant>,
            direction: TransferDirection,
            executionId: ExecutionId,
            batchSize: Nat
        ) : async BatchTransferResult {
            
            let directionStr = switch (direction) {
                case (#ToParticipant) "REFUND";
                case (#ToLaunchpad) "COLLECTION";
            };
            
            Debug.print("🔄 Starting batch " # directionStr # "...");
            Debug.print("   Batch size: " # Nat.toText(batchSize));

            let transactions = Buffer.Buffer<FinancialRecord>(0);
            let failedTransfers = Buffer.Buffer<(Principal, Text)>(0);
            
            var totalAmount: Nat = 0;
            var successCount: Nat = 0;
            var failedCount: Nat = 0;
            var skippedCount: Nat = 0;

            // Convert Trie to array for iteration
            let participantArray = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(
                participants,
                func(k, v) { (k, v) }
            );

            Debug.print("   Total participants: " # Nat.toText(participantArray.size()));

            // Process each participant
            for ((key, participant) in participantArray.vals()) {
                
                let memo = switch (direction) {
                    case (#ToParticipant) "Launchpad refund - " # key;
                    case (#ToLaunchpad) "Launchpad collection - " # key;
                };

                let result = await transferFromSubaccount(
                    participant,
                    direction,
                    executionId,
                    memo
                );

                // Process result
                switch (result.status) {
                    case (#Success) {
                        successCount += 1;
                        totalAmount += result.amount;

                        // Record financial transaction
                        let txType: FinancialTxType = switch (direction) {
                            case (#ToParticipant) #Refund;
                            case (#ToLaunchpad) #TokenTransfer;
                        };

                        transactions.add({
                            txType = txType;
                            from = launchpadPrincipal;
                            to = result.participant;
                            amount = result.amount;
                            blockIndex = result.blockIndex;
                            timestamp = Time.now();
                            status = #Confirmed;
                            executionId = executionId;
                        });
                    };
                    case (#Failed) {
                        failedCount += 1;
                        failedTransfers.add((
                            result.participant,
                            Option.get(result.error, "Unknown error")
                        ));
                    };
                    case (#AlreadyProcessed or #ZeroBalance or #InsufficientForFee or #Skipped) {
                        skippedCount += 1;
                    };
                };
            };

            Debug.print("✅ Batch " # directionStr # " completed");
            Debug.print("   Total amount: " # Nat.toText(totalAmount));
            Debug.print("   Success: " # Nat.toText(successCount));
            Debug.print("   Failed: " # Nat.toText(failedCount));
            Debug.print("   Skipped: " # Nat.toText(skippedCount));

            {
                totalAmount = totalAmount;
                successCount = successCount;
                failedCount = failedCount;
                skippedCount = skippedCount;
                transactions = Buffer.toArray(transactions);
                failedTransfers = Buffer.toArray(failedTransfers);
            }
        };

        /// Verify total balance across all participant subaccounts
        /// Used for auditing and validation
        public func verifyTotalBalances(
            participants: Trie.Trie<Text, LaunchpadTypes.Participant>
        ) : async Result.Result<{ total: Nat; breakdown: [(Principal, Nat)] }, Text> {
            
            Debug.print("🔍 Verifying total balances...");

            let breakdown = Buffer.Buffer<(Principal, Nat)>(0);
            var total: Nat = 0;

            let participantArray = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(
                participants,
                func(k, v) { (k, v) }
            );

            for ((_, participant) in participantArray.vals()) {
                let balanceResult = await checkBalance(participant.principal);
                
                switch (balanceResult) {
                    case (#ok(balance)) {
                        breakdown.add((participant.principal, balance));
                        total += balance;
                    };
                    case (#err(msg)) {
                        return #err("Failed to verify balance for " # Principal.toText(participant.principal) # ": " # msg);
                    };
                };
            };

            Debug.print("✅ Verification complete");
            Debug.print("   Total balance: " # Nat.toText(total));

            #ok({
                total = total;
                breakdown = Buffer.toArray(breakdown);
            })
        };

        /// Get deposit account info for participant (for frontend display)
        public func getDepositAccountInfo(participant: Principal) : {
            owner: Principal;
            subaccount: [Nat8];
            subaccountHex: Text;
        } {
            let subAccount = principalToSubAccount(participant);
            
            {
                owner = launchpadPrincipal;
                subaccount = subAccount;
                subaccountHex = toHex(subAccount);
            }
        };

        /// Process a single transfer from the launchpad main account
        public func processTransfer(request: TransferRequest) : async Result.Result<Nat, Text> {
            try {
                let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(purchaseTokenCanisterId));
                
                let transferArgs: ICRCTypes.TransferArgs = {
                    from_subaccount = null; // Main account
                    to = { owner = request.to; subaccount = null };
                    amount = request.amount;
                    fee = ?purchaseTokenFee;
                    memo = ?Text.encodeUtf8("Ref: " # request.referenceId);
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };

                let result = await ledger.icrc1_transfer(transferArgs);

                switch (result) {
                    case (#Ok(blockIndex)) #ok(blockIndex);
                    case (#Err(e)) #err(debug_show(e));
                }
            } catch (e) {
                #err(Error.message(e))
            }
        };
    };
}


