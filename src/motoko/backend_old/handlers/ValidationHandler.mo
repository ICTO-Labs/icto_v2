// ValidationHandler.mo - Request Validation Handler
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

module ValidationHandler {
    
    public type ValidationResult = Result.Result<(), Text>;
    
    public func validatePrincipal(principal: Principal) : ValidationResult {
        if (Principal.isAnonymous(principal)) {
            #err("Anonymous principal not allowed")
        } else {
            #ok()
        }
    };
    
    public func validateText(text: Text, minLength: Nat, maxLength: Nat) : ValidationResult {
        if (Text.size(text) < minLength) {
            #err("Text too short")
        } else if (Text.size(text) > maxLength) {
            #err("Text too long")
        } else {
            #ok()
        }
    };
    
    public func validateProjectId(projectId: Text) : ValidationResult {
        validateText(projectId, 3, 50)
    };
    
    public func validateTokenSymbol(symbol: Text) : ValidationResult {
        validateText(symbol, 3, 6)
    };
} 