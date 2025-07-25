import Text "mo:base/Text";
import Result "mo:base/Result";

module {
    // Common validation error type that can be used across modules
    public type ValidationError = {
        #InvalidSymbol : Text;
        #InvalidName : Text;
        #InvalidLogo : Text;
        #Other : Text;
    };

    // Validate token symbol
    public func validateSymbol(symbol: Text) : Result.Result<(), ValidationError> {
        let length = Text.size(symbol);
        if (length < 2 or length > 8) {
            return #err(#InvalidSymbol("Token symbol must be 2-8 characters"));
        };
        #ok(())
    };

    // Validate token name
    public func validateName(name: Text) : Result.Result<(), ValidationError> {
        let length = Text.size(name);
        if (length < 3 or length > 32) {
            return #err(#InvalidName("Token name must be 3-32 characters"));
        };
        #ok(())
    };

    // Validate token logo if provided
    public func validateLogo(logo: ?Text) : Result.Result<(), ValidationError> {
        switch (logo) {
            case (null) { #ok(()) };
            case (?logoText) {
                let size = Text.size(logoText);
                if (size > 30_000) {
                    return #err(#InvalidLogo("Logo too large (max 30KB)"));
                };
                #ok(())
            };
        }
    };

    // Comprehensive token config validation
    public func validateTokenConfig<T>(
        symbol: Text,
        name: Text,
        logo: ?Text
    ) : Result.Result<(), ValidationError> {
        // Validate symbol
        switch (validateSymbol(symbol)) {
            case (#err(e)) { return #err(e) };
            case (#ok(_)) {};
        };

        // Validate name
        switch (validateName(name)) {
            case (#err(e)) { return #err(e) };
            case (#ok(_)) {};
        };

        // Validate logo if provided
        switch (validateLogo(logo)) {
            case (#err(e)) { return #err(e) };
            case (#ok(_)) {};
        };

        #ok(())
    };
}