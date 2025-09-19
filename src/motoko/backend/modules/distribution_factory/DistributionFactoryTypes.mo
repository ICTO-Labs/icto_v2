// Import shared distribution types to avoid duplication
import DistributionTypes "../../../shared/types/DistributionTypes";

module DistributionFactoryTypes {

    // ==================================================================================================
    // ⬇️ Types for the Distribution Factory Service client module - V2 Implementation
    // ==================================================================================================

    // Re-export all types from the shared module for backward compatibility
    public type DistributionConfig = DistributionTypes.DistributionConfig;
    public type Recipient = DistributionTypes.Recipient;
    public type CampaignType = DistributionTypes.CampaignType;
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

    // Launchpad batch types
    public type DistributionCategory = DistributionTypes.DistributionCategory;
    public type ProjectMetadata = DistributionTypes.ProjectMetadata;
    public type BatchDistributionRequest = DistributionTypes.BatchDistributionRequest;

    // Helper functions
    public func getCommonCategories() : [DistributionCategory] = DistributionTypes.getCommonCategories();
    public func getPresetVestingSchedule(categoryId: Text) : VestingSchedule = DistributionTypes.getPresetVestingSchedule(categoryId);
    public func createDistributionConfigForCategory(
        baseConfig: DistributionConfig,
        category: DistributionCategory,
        vestingOverride: ?VestingSchedule
    ) : DistributionConfig = DistributionTypes.createDistributionConfigForCategory(baseConfig, category, vestingOverride);

    // Legacy compatibility for backend service state management
    public type StableState = DistributionTypes.StableState;
    public func emptyState() : StableState = DistributionTypes.emptyState();
};

