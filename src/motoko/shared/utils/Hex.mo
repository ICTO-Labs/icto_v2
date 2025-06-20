// Hex encoding/decoding utilities

import Array "mo:base/Array";
import Char "mo:base/Char";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Text "mo:base/Text";

module {
    private let symbols = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
    private let base : Nat8 = 0x10;

    public func encode(array : [Nat8]) : Text {
        Array.foldLeft<Nat8, Text>(array, "", func (accum, w8) {
            accum # nat8ToText(w8);
        });
    };

    public func decode(t : Text) : Result.Result<[Nat8], Text> {
        let s = t.size();
        if (s % 2 != 0) {
            return #err "hex string size should be even";
        };
        let cs = t.chars();
        let half = s / 2;
        let bs : [var Nat8] = Array.init<Nat8>(half, 0);
        var i = 0;
        while (i < half) {
            switch (cs.next(), cs.next()) {
                case (?c1, ?c2) {
                    switch (charToNat8(c1), charToNat8(c2)) {
                        case (?n1, ?n2) {
                            bs[i] := n1 * base + n2;
                            i += 1;
                        };
                        case _ {
                            return #err("unexpected char: " # Char.toText(c1) # Char.toText(c2));
                        };
                    }
                };
                case _ {
                    return #err "not reachable";
                };
            }
        };
        #ok(Array.freeze<Nat8>(bs));
    };

    private func charToNat8(c : Char) : ?Nat8 {
        let n32 = Char.toNat32(c);
        if (n32 >= 48 and n32 <= 57) {
            ?(Nat8.fromNat(Nat32.toNat(n32 - 48)))
        } else if (n32 >= 97 and n32 <= 102) {
            ?(Nat8.fromNat(Nat32.toNat(n32 - 97) + 10))
        } else if (n32 >= 65 and n32 <= 70) {
            ?(Nat8.fromNat(Nat32.toNat(n32 - 65) + 10))
        } else {
            null
        }
    };

    private func nat8ToText(w8 : Nat8) : Text {
        let n = Nat8.toNat(w8);
        let n1 = n / 16;
        let n2 = n % 16;
        Char.toText(symbols[n1]) # Char.toText(symbols[n2]);
    };
} 