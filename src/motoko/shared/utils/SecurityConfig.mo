// ICTO V2 - Dynamic Security Configuration
// Replaces SecurityConstants with configurable values from ConfigService
import ConfigService "../../backend/modules/systems/config/ConfigService";
import ConfigTypes "../../backend/modules/systems/config/ConfigTypes";
import Result "mo:base/Result";
import Time "mo:base/Time";

module SecurityConfig {
    public type SecurityConfig = ConfigTypes.SecurityConfig;
    
    /// Get security configuration from config state
    /// This replaces all the static constants with dynamic config values
    public func getConfig(configState: ConfigTypes.State) : SecurityConfig {
        ConfigService.getSecurityConfig(configState)
    };
    
    /// Validation functions that use dynamic config values
    
    /// Check if a timestamp is within a reasonable range
    public func isValidTimestamp(timestamp: Int) : Bool {
        ConfigService.isValidTimestamp(timestamp)
    };
    
    /// Check if voting period is within acceptable bounds
    public func isValidVotingPeriod(period: Int, config: SecurityConfig) : Bool {
        ConfigService.isValidVotingPeriod(period, config.minVotingPeriod, config.maxVotingPeriod)
    };
    
    /// Check if timelock duration is within acceptable bounds  
    public func isValidTimelockDuration(duration: Int, config: SecurityConfig) : Bool {
        ConfigService.isValidTimelockDuration(duration, config.minTimelockDuration, config.maxTimelockDuration)
    };
    
    /// Check if percentage is valid (in basis points)
    public func isValidBasisPoints(basisPoints: Nat) : Bool {
        ConfigService.isValidBasisPoints(basisPoints)
    };
    
    /// Check if quorum percentage is within acceptable bounds
    public func isValidQuorumPercentage(percentage: Nat, config: SecurityConfig) : Bool {
        ConfigService.isValidQuorumPercentage(percentage, config.minQuorumPercentage, config.maxQuorumPercentage)
    };
    
    /// Check if approval threshold is within acceptable bounds
    public func isValidApprovalThreshold(threshold: Nat, config: SecurityConfig) : Bool {
        ConfigService.isValidApprovalThreshold(threshold, config.minApprovalThreshold, config.maxApprovalThreshold)
    };
    
    /// Validate amount within configured bounds
    public func validateAmount(amount: Nat, minAmount: Nat, maxAmount: Nat) : Result.Result<(), Text> {
        if (amount < minAmount) {
            return #err("Amount below minimum: " # Nat.toText(minAmount));
        };
        
        if (amount > maxAmount) {
            return #err("Amount exceeds maximum: " # Nat.toText(maxAmount));
        };
        
        #ok()
    };
}