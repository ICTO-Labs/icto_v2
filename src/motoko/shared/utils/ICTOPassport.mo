import Principal "mo:base/Principal";
module {
    public type WalletScore = {
        linkedWallet : ?(Principal, Nat);
        linkedScore : Nat;
        primaryScore : Nat;
        totalScore : Nat;
        percentileAbove : Float;
    };
    public type Self = actor {
        getWalletScore : shared query (Principal, Text) -> async WalletScore;
    };
}