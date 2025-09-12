// Bridge between shared LaunchpadTypes and factory-specific types
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";

import LaunchpadTypes "../shared/types/LaunchpadTypes";

module Types {
    // Re-export commonly used types for backward compatibility
    public type LaunchpadConfig = LaunchpadTypes.LaunchpadConfig;
    public type LaunchpadDetail = LaunchpadTypes.LaunchpadDetail;
    public type LaunchpadStatus = LaunchpadTypes.LaunchpadStatus;
    public type Participant = LaunchpadTypes.Participant;
    public type Transaction = LaunchpadTypes.Transaction;
    public type AffiliateStats = LaunchpadTypes.AffiliateStats;
    public type ProcessingState = LaunchpadTypes.ProcessingState;
    public type Account = LaunchpadTypes.Account;
    public type TokenInfo = LaunchpadTypes.TokenInfo;
    public type Timeline = LaunchpadTypes.Timeline;
    public type ProjectInfo = LaunchpadTypes.ProjectInfo;

    // Factory-specific types
    public type CreateLaunchpadArgs = {
        config: LaunchpadTypes.LaunchpadConfig;
        creator: Principal;
    };

    public type LaunchpadInitArgs = {
        id: Text;
        config: LaunchpadTypes.LaunchpadConfig;
        creator: Principal;
        createdAt: Time.Time;
    };
    public type CreateLaunchpadResult = {
        #Ok: {
            launchpadId: Text;
            canisterId: Principal;
        };
        #Err: Text;
    };

    public type FactoryStats = {
        totalLaunchpads: Nat;
        activeLaunchpads: Nat;
        completedLaunchpads: Nat;
        totalRaised: Nat;
        averageRaise: Nat;
        successRate: Nat8;
    };

    // Legacy V1 types for backward compatibility
    public type V1_Participant = {
        commit : Nat;
        totalAmount : Nat;
        lastDeposit: ?Time.Time;
    };

    public type V1_Transaction = {
        participant: Text;
        amount: Nat;
        time: Time.Time;
        method: Text;
        txId: ?Nat;
    };

    public type V1_LaunchParams = {
        sellAmount : Nat;
        softCap : Nat;
        hardCap : Nat;
        minimumAmount : Nat;
        maximumAmount : Nat;
    };

    public type V1_LaunchpadStatus = {
        totalAmountCommitted: Nat;
        totalParticipants: Nat;
        totalTransactions: Nat;
        whitelistEnabled: Bool;
        status: Text;
        affiliate: Nat;
        cycle: Nat;
        installed: Bool;
        totalAffiliateVolume: Nat;
        affiliateRewardPool: Nat;
        refererTransaction: Nat;
    };
}