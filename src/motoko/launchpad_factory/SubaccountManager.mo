// ================ SUBACCOUNT MANAGER MODULE ================
// Unified subaccount management for deposits, refunds, and fund collection
// SECURITY LEVEL: CRITICAL (handles user funds)
//
// RESPONSIBILITIES:
// 1. Generate deterministic subaccounts (IC standard format)
// 2. Check balances in subaccounts
// 3. Transfer funds FROM subaccounts (refund OR collect)
// 4. Batch processing for multiple participants
// 5. Complete audit trail

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

import LaunchpadTypes "../shared/types/LaunchpadTypes";
import ICRCTypes "../shared/types/ICRC";
import PipelineManager "./PipelineManager";

module {

    // ================ TYPES ================

    /// Transfer direction
    public type TransferDirection = {
        #ToParticipant;    // Refund: subaccount → participant
        #ToLaunchpad;      // Collection: subaccount → launchpad main
    };

    /// Batch transfer result
    public type BatchTransferResult = {
        totalAmount: Nat;
        successCount: Nat;
        failedCount: Nat;
        skippedCount: Nat;
        transactions: [PipelineManager.FinancialRecord];
        failedTransfers: [(Principal, Text)];  // Principal + error reason
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

    // ================ SUBACCOUNT MANAGER CLASS ================

    public class SubaccountManager(
        purchaseTokenCanisterId: Principal,
        purchaseTokenFee: Nat,
        launchpadPrincipal: Principal
    ) {

        // ================ SUBACCOUNT UTILITIES ================

        /// Convert Principal to subaccount (32 bytes) - IC STANDARD FORMAT
        /// Format: [size_byte, ...principal_bytes..., ...padding_zeros...]
        /// This MATCHES LaunchpadContract.mo implementation
        private func principalToSubAccount(userId: Principal) : [Nat8] {
            let p = Blob.toArray(Principal.toBlob(userId));
            Array.tabulate(32, func(i : Nat) : Nat8 {
                if (i >= p.size() + 1) 0
                else if (i == 0) (Nat8.fromNat(p.size()))
                else (p[i - 1])
            })
        };

        /// Get deposit account for participant
        private func getDepositAccount(participant: Principal) : ICRCTypes.Account {
            let subAccount = principalToSubAccount(participant);
            let subAccountBlob = Blob.fromArray(subAccount);
            
            {
                owner = launchpadPrincipal;
                subaccount = ?subAccountBlob;
            }
        };

        /// Convert subaccount bytes to hex string (for display/debugging)
        private func toHex(arr: [Nat8]): Text {
            let hexChars = ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
            Text.join("", Iter.map<Nat8, Text>(Iter.fromArray(arr), func (x: Nat8) : Text {
                let a = Nat8.toNat(x / 16);
                let b = Nat8.toNat(x % 16);
                hexChars[a] # hexChars[b]
            }))
        };

        // ================ BALANCE CHECKING ================

        /// Check balance in participant's deposit account
        public func checkBalance(participant: Principal) : async Result.Result<Nat, Text> {
            try {
                let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(purchaseTokenCanisterId));
                let depositAccount = getDepositAccount(participant);
                
                let balance = await ledger.icrc1_balance_of(depositAccount);
                
                #ok(balance)
            } catch (error) {
                #err("Failed to check balance: " # Error.message(error))
            }
        };

        // ================ SINGLE TRANSFER ================

        /// Transfer funds from participant's subaccount
        /// Direction determines recipient (participant for refund, launchpad for collection)
        public func transferFromSubaccount(
            participant: LaunchpadTypes.Participant,
            direction: TransferDirection,
            executionId: PipelineManager.ExecutionId,
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
                            error = ?("Already refunded " # Nat.toText(participant.refundedAmount));
                        };
                    };
                };
                case (#ToLaunchpad) {
                    // No duplicate check needed for collection
                };
            };

            // VALIDATION #2: Check if has contribution
            if (participant.totalContribution == 0) {
                Debug.print("⚠️ Zero contribution: " # Principal.toText(participantPrincipal));
                return {
                    participant = participantPrincipal;
                    amount = 0;
                    blockIndex = null;
                    status = #ZeroBalance;
                    error = ?"No contribution";
                };
            };

            try {
                let directionLabel = switch (direction) {
                    case (#ToParticipant) "REFUND";
                    case (#ToLaunchpad) "COLLECTION";
                };
                
                Debug.print("💸 " # directionLabel # " for: " # Principal.toText(participantPrincipal));
                Debug.print("   Expected: " # Nat.toText(participant.totalContribution));

                let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(purchaseTokenCanisterId));
                
                // Get deposit account
                let depositAccount = getDepositAccount(participantPrincipal);
                
                // SECURITY: Check actual balance in subaccount
                let actualBalance = await ledger.icrc1_balance_of(depositAccount);
                
                Debug.print("   Actual balance: " # Nat.toText(actualBalance));

                // VALIDATION #3: Check balance exists
                if (actualBalance == 0) {
                    Debug.print("⚠️ Zero balance in subaccount");
                    return {
                        participant = participantPrincipal;
                        amount = 0;
                        blockIndex = null;
                        status = #ZeroBalance;
                        error = ?"No funds in deposit account";
                    };
                };

                // VALIDATION #4: Check balance covers fee
                if (actualBalance < purchaseTokenFee) {
                    Debug.print("⚠️ Balance too low to cover fee");
                    return {
                        participant = participantPrincipal;
                        amount = actualBalance;
                        blockIndex = null;
                        status = #InsufficientForFee;
                        error = ?"Balance less than transfer fee";
                    };
                };

                // Calculate transfer amount (balance minus fee)
                let transferAmount = actualBalance - purchaseTokenFee;

                // VALIDATION #5: Sanity check (for refunds)
                switch (direction) {
                    case (#ToParticipant) {
                        if (transferAmount > participant.totalContribution) {
                            Debug.print("⚠️ WARNING: Transfer exceeds contribution!");
                            Debug.print("   Transfer: " # Nat.toText(transferAmount));
                            Debug.print("   Contribution: " # Nat.toText(participant.totalContribution));
                        };
                    };
                    case (#ToLaunchpad) {
                        // No sanity check needed for collection
                    };
                };

                // Determine recipient
                let recipient: ICRCTypes.Account = switch (direction) {
                    case (#ToParticipant) {
                        {
                            owner = participantPrincipal;
                            subaccount = null;  // Participant's main account
                        }
                    };
                    case (#ToLaunchpad) {
                        {
                            owner = launchpadPrincipal;
                            subaccount = null;  // Launchpad main account
                        }
                    };
                };

                // Execute ICRC transfer FROM subaccount
                let subaccountBlob = Blob.fromArray(principalToSubAccount(participantPrincipal));
                let transferArgs: ICRCTypes.TransferArgs = {
                    from_subaccount = ?subaccountBlob;
                    to = recipient;
                    amount = transferAmount;
                    fee = ?purchaseTokenFee;
                    memo = ?Text.encodeUtf8(memo);
                    created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
                };

                Debug.print("   Initiating ICRC transfer...");
                let transferResult = await ledger.icrc1_transfer(transferArgs);

                switch (transferResult) {
                    case (#Ok(blockIndex)) {
                        Debug.print("✅ " # directionLabel # " successful!");
                        Debug.print("   Block: " # Nat.toText(blockIndex));
                        Debug.print("   Amount: " # Nat.toText(transferAmount));

                        {
                            participant = participantPrincipal;
                            amount = transferAmount;
                            blockIndex = ?blockIndex;
                            status = #Success;
                            error = null;
                        }
                    };
                    case (#Err(error)) {
                        let errorMsg = "ICRC transfer failed: " # debug_show(error);
                        Debug.print("❌ " # errorMsg);

                        {
                            participant = participantPrincipal;
                            amount = transferAmount;
                            blockIndex = null;
                            status = #Failed;
                            error = ?errorMsg;
                        }
                    };
                };

            } catch (error) {
                let errorMsg = "Transfer exception: " # Error.message(error);
                Debug.print("❌ " # errorMsg);

                {
                    participant = participantPrincipal;
                    amount = 0;
                    blockIndex = null;
                    status = #Failed;
                    error = ?errorMsg;
                }
            }
        };

        // ================ BATCH TRANSFERS ================

        /// Process batch transfers (refund OR collection)
        public func processBatchTransfers(
            participants: Trie.Trie<Text, LaunchpadTypes.Participant>,
            direction: TransferDirection,
            executionId: PipelineManager.ExecutionId,
            batchSize: Nat
        ) : async BatchTransferResult {
            
            let operationType = switch (direction) {
                case (#ToParticipant) "REFUND";
                case (#ToLaunchpad) "FUND COLLECTION";
            };
            
            Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Debug.print("💸 STARTING " # operationType # " PROCESS");
            Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

            // Convert Trie to Array
            let participantArray = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(
                participants,
                func(k, v) { (k, v) }
            );

            Debug.print("📊 Total participants: " # Nat.toText(participantArray.size()));
            Debug.print("📦 Batch size: " # Nat.toText(batchSize));

            var totalAmount: Nat = 0;
            var successCount = 0;
            var failedCount = 0;
            var skippedCount = 0;

            let financialRecords = Buffer.Buffer<PipelineManager.FinancialRecord>(0);
            let failedTransfers = Buffer.Buffer<(Principal, Text)>(0);

            // Memo for ICRC transfer
            let memo = switch (direction) {
                case (#ToParticipant) "Launchpad refund - sale failed";
                case (#ToLaunchpad) "Collect participant funds";
            };

            // SECURITY: Process in batches to avoid cycle exhaustion
            var batchStart = 0;
            var batchNumber = 1;

            label transferLoop while (batchStart < participantArray.size()) {
                let batchEnd = Nat.min(batchStart + batchSize, participantArray.size());
                
                Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
                Debug.print("📦 Batch #" # Nat.toText(batchNumber));
                Debug.print("   Range: " # Nat.toText(batchStart) # " to " # Nat.toText(batchEnd - 1));
                Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

                for (i in Iter.range(batchStart, batchEnd - 1)) {
                    let (_key, participant) = participantArray[i];
                    
                    Debug.print("👤 [" # Nat.toText(i + 1) # "/" # Nat.toText(participantArray.size()) # "] " # Principal.toText(participant.principal));

                    // Process individual transfer
                    let transferResult = await transferFromSubaccount(
                        participant,
                        direction,
                        executionId,
                        memo
                    );

                    // Handle result
                    switch (transferResult.status) {
                        case (#Success) {
                            successCount += 1;
                            totalAmount += transferResult.amount;

                            // Determine transaction type
                            let txType = switch (direction) {
                                case (#ToParticipant) #Refund;
                                case (#ToLaunchpad) #TokenTransfer;
                            };

                            // Determine from/to based on direction
                            let (txFrom, txTo) = switch (direction) {
                                case (#ToParticipant) {
                                    (launchpadPrincipal, transferResult.participant)
                                };
                                case (#ToLaunchpad) {
                                    (transferResult.participant, launchpadPrincipal)
                                };
                            };

                            // Record financial transaction
                            let record: PipelineManager.FinancialRecord = {
                                txType = txType;
                                amount = transferResult.amount;
                                from = txFrom;
                                to = txTo;
                                blockIndex = transferResult.blockIndex;
                                timestamp = Time.now();
                                status = #Confirmed;
                                executionId = executionId;
                            };
                            financialRecords.add(record);
                        };
                        case (#Failed) {
                            failedCount += 1;
                            let errorMsg = switch (transferResult.error) {
                                case (?msg) msg;
                                case null "Unknown error";
                            };
                            failedTransfers.add((transferResult.participant, errorMsg));
                        };
                        case (#AlreadyProcessed or #ZeroBalance or #InsufficientForFee or #Skipped) {
                            skippedCount += 1;
                        };
                    };
                };

                batchStart := batchEnd;
                batchNumber += 1;

                // Log batch summary
                Debug.print("✅ Batch #" # Nat.toText(batchNumber - 1) # " completed");
                Debug.print("   Success so far: " # Nat.toText(successCount));
                Debug.print("   Failed so far: " # Nat.toText(failedCount));
                Debug.print("   Skipped so far: " # Nat.toText(skippedCount));
            };

            // Final summary
            Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Debug.print("📊 " # operationType # " COMPLETED");
            Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
            Debug.print("✅ Successful: " # Nat.toText(successCount));
            Debug.print("❌ Failed: " # Nat.toText(failedCount));
            Debug.print("⏭️ Skipped: " # Nat.toText(skippedCount));
            Debug.print("💰 Total amount: " # Nat.toText(totalAmount));
            Debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

            // Log failed transfers for manual review
            if (failedCount > 0) {
                Debug.print("⚠️ FAILED TRANSFERS (require manual intervention):");
                for ((principal, error) in Buffer.toArray(failedTransfers).vals()) {
                    Debug.print("   • " # Principal.toText(principal) # ": " # error);
                };
            };

            {
                totalAmount = totalAmount;
                successCount = successCount;
                failedCount = failedCount;
                skippedCount = skippedCount;
                transactions = Buffer.toArray(financialRecords);
                failedTransfers = Buffer.toArray(failedTransfers);
            }
        };

        // ================ AUDIT & VERIFICATION ================

        /// Verify total balances across all subaccounts
        public func verifyTotalBalances(
            participants: Trie.Trie<Text, LaunchpadTypes.Participant>
        ) : async {
            totalExpected: Nat;
            totalActual: Nat;
            discrepancies: [(Principal, Nat, Nat)];  // Principal, expected, actual
        } {
            Debug.print("🔍 Verifying total balances...");

            let participantArray = Trie.toArray<Text, LaunchpadTypes.Participant, (Text, LaunchpadTypes.Participant)>(
                participants,
                func(k, v) { (k, v) }
            );

            var totalExpected: Nat = 0;
            var totalActual: Nat = 0;
            let discrepancies = Buffer.Buffer<(Principal, Nat, Nat)>(0);

            let ledger: ICRCTypes.ICRCLedger = actor(Principal.toText(purchaseTokenCanisterId));

            for ((_key, participant) in participantArray.vals()) {
                totalExpected += participant.totalContribution;

                let depositAccount = getDepositAccount(participant.principal);
                let balance = await ledger.icrc1_balance_of(depositAccount);
                totalActual += balance;

                // Check for discrepancies
                if (balance != participant.totalContribution) {
                    discrepancies.add((participant.principal, participant.totalContribution, balance));
                    Debug.print("⚠️ Discrepancy for " # Principal.toText(participant.principal));
                    Debug.print("   Expected: " # Nat.toText(participant.totalContribution));
                    Debug.print("   Actual: " # Nat.toText(balance));
                };
            };

            Debug.print("📊 Verification complete:");
            Debug.print("   Total expected: " # Nat.toText(totalExpected));
            Debug.print("   Total actual: " # Nat.toText(totalActual));
            Debug.print("   Discrepancies: " # Nat.toText(discrepancies.size()));

            {
                totalExpected = totalExpected;
                totalActual = totalActual;
                discrepancies = Buffer.toArray(discrepancies);
            }
        };

        // ================ QUERY FUNCTIONS ================

        /// Get deposit account info for a participant (for display)
        public func getDepositAccountInfo(participant: Principal) : {
            subaccount: [Nat8];
            subaccountHex: Text;
            owner: Principal;
        } {
            let subaccount = principalToSubAccount(participant);
            {
                subaccount = subaccount;
                subaccountHex = toHex(subaccount);
                owner = launchpadPrincipal;
            }
        };
    };
}


