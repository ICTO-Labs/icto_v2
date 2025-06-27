// ErrorHandler.mo - Centralized Error Handling
import Result "mo:base/Result";
import Text "mo:base/Text";

module ErrorHandler {
    
    public type ErrorType = {
        #ValidationError;
        #PaymentError;
        #ServiceError;
        #AuthorizationError;
        #SystemError;
    };
    
    public func formatError(errorType: ErrorType, message: Text) : Text {
        let prefix = switch (errorType) {
            case (#ValidationError) "VALIDATION";
            case (#PaymentError) "PAYMENT";
            case (#ServiceError) "SERVICE";
            case (#AuthorizationError) "AUTH";
            case (#SystemError) "SYSTEM";
        };
        prefix # "_ERROR: " # message
    };
} 