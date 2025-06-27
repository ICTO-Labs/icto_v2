// ⬇️ Shared Validator functions across all ICTO V2 services

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import ErrorTypes "../types/ErrorTypes";

module {
    public type ValidationResult = Result.Result<(), Text>;
    
    // ================ PRINCIPAL VALIDATORS ================

    public func validatePrincipal(principal: Principal) : ValidationResult {
        if (Principal.isAnonymous(principal)) {
            #err("Anonymous principal is not allowed.")
        } else {
            #ok()
        }
    };

    // ================ TEXT VALIDATORS ================

    public func validateText(text: Text, minLength: Nat, maxLength: Nat) : ValidationResult {
        let len = Text.size(text);
        if (len < minLength) {
            #err("Text is too short. Minimum length is " # Nat.toText(minLength) # ".")
        } else if (len > maxLength) {
            #err("Text is too long. Maximum length is " # Nat.toText(maxLength) # ".")
        } else {
            #ok()
        }
    };

    // ================ ERROR VALIDATORS ================

    public func isSystemError(error: ErrorTypes.SystemError) : Bool {
        switch(error) {
            case (#InternalError(_)) true;
            case (#ServiceUnavailable(_)) true;
            case (_) false;
        }
    };
} 