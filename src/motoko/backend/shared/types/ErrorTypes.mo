// ⬇️ Shared Error types across all ICTO V2 services

import Result "mo:base/Result";

module {
    // Standard error types
    public type SystemError = {
        #InsufficientFunds;
        #Unauthorized;
        #NotFound;
        #InvalidInput : Text;
        #ServiceUnavailable : Text;
        #InternalError : Text;
    };

    // System-wide result type
    public type SystemResult<T> = Result.Result<T, SystemError>;
} 