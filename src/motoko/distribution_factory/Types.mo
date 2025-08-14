// Import shared distribution types to avoid duplication
import DistributionTypes "../shared/types/DistributionTypes";

module Types {
    // Re-export all types from the shared module for backward compatibility
    public type DistributionConfig = DistributionTypes.DistributionConfig;
    public type TokenInfo = DistributionTypes.TokenInfo;
    public type EligibilityType = DistributionTypes.EligibilityType;
    public type TokenHolderConfig = DistributionTypes.TokenHolderConfig;
    public type NFTHolderConfig = DistributionTypes.NFTHolderConfig;
    public type EligibilityLogic = DistributionTypes.EligibilityLogic;
    public type RecipientMode = DistributionTypes.RecipientMode;
    public type RegistrationPeriod = DistributionTypes.RegistrationPeriod;
    public type VestingSchedule = DistributionTypes.VestingSchedule;
    public type LinearVesting = DistributionTypes.LinearVesting;
    public type CliffVesting = DistributionTypes.CliffVesting;
    public type CliffStep = DistributionTypes.CliffStep;
    public type UnlockEvent = DistributionTypes.UnlockEvent;
    public type UnlockFrequency = DistributionTypes.UnlockFrequency;
    public type FeeStructure = DistributionTypes.FeeStructure;
    public type FeeTier = DistributionTypes.FeeTier;
    public type ExternalDeployerArgs = DistributionTypes.ExternalDeployerArgs;
    public type DistributionContract = DistributionTypes.DistributionContract;
    public type DistributionStatus = DistributionTypes.DistributionStatus;
    public type DeploymentResult = DistributionTypes.DeploymentResult;
}