import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";

module DistributionTypes {



    // Distribution Configuration
    public type DistributionConfig = {
        // Basic Information
        title: Text;
        description: Text;
        isPublic: Bool;
        
        // Token Configuration
        tokenInfo: TokenInfo;
        totalAmount: Nat;
        
        // Eligibility & Recipients
        eligibilityType: EligibilityType;
        eligibilityLogic: ?EligibilityLogic;
        recipientMode: RecipientMode;
        maxRecipients: ?Nat;
        
        // Vesting Configuration
        vestingSchedule: VestingSchedule;
        initialUnlockPercentage: Nat;
        
        // Timing
        registrationPeriod: ?RegistrationPeriod;
        distributionStart: Time.Time;
        distributionEnd: ?Time.Time;
        
        // Fees & Permissions
        feeStructure: FeeStructure;
        allowCancel: Bool;
        allowModification: Bool;
        
        // Owner & Governance
        owner: Principal;
        governance: ?Principal;
        
        // External Integrations
        externalCheckers: ?[(Text, Principal)];
    };

    public type TokenInfo = {
        canisterId: Principal;
        symbol: Text;
        name: Text;
        decimals: Nat8;
    };

    public type EligibilityType = {
        #Open;
        #Whitelist: [Principal];
        #TokenHolder: TokenHolderConfig;
        #NFTHolder: NFTHolderConfig;
        #BlockIDScore: Nat;
        #Hybrid: {
            conditions: [EligibilityType];
            logic: EligibilityLogic;
        };
    };

    public type TokenHolderConfig = {
        canisterId: Principal;
        minAmount: Nat;
        snapshotTime: ?Time.Time;
    };

    public type NFTHolderConfig = {
        canisterId: Principal;
        minCount: Nat;
        collections: ?[Text];
    };

    public type EligibilityLogic = {
        #AND;
        #OR;
    };

    public type RecipientMode = {
        #Fixed;
        #Dynamic;
        #SelfService;
    };

    public type RegistrationPeriod = {
        startTime: Time.Time;
        endTime: Time.Time;
        maxParticipants: ?Nat;
    };

    public type VestingSchedule = {
        #Instant;
        #Linear: LinearVesting;
        #Cliff: CliffVesting;
        #SteppedCliff: [CliffStep];
        #Custom: [UnlockEvent];
    };

    public type LinearVesting = {
        duration: Nat;
        frequency: UnlockFrequency;
    };

    public type CliffVesting = {
        cliffDuration: Nat;
        cliffPercentage: Nat;
        vestingDuration: Nat;
        frequency: UnlockFrequency;
    };

    public type CliffStep = {
        timeOffset: Nat;
        percentage: Nat;
    };

    public type UnlockEvent = {
        timestamp: Time.Time;
        amount: Nat;
    };

    public type UnlockFrequency = {
        #Continuous;
        #Daily;
        #Weekly;
        #Monthly;
        #Quarterly;
        #Yearly;
        #Custom: Nat;
    };

    public type FeeStructure = {
        #Free;
        #Fixed: Nat;
        #Percentage: Nat;
        #Progressive: [FeeTier];
        #RecipientPays;
        #CreatorPays;
    };

    public type FeeTier = {
        threshold: Nat;
        feeRate: Nat;
    };

    // External Deployer Args
    public type ExternalDeployerArgs = {
        config: DistributionConfig;
        owner: Principal;
    };

    // Distribution Contract Record (stored in factory)
    public type DistributionContract = {
        id: Text;
        creator: Principal;
        config: DistributionConfig;
        deployedCanister: ?Principal;
        createdAt: Time.Time;
        status: DistributionStatus;
    };

    public type DistributionStatus = {
        #Created;
        #Deployed;
        #Active;
        #Paused;
        #Completed;
        #Cancelled;
    };

    // Deployment Result
    public type DeploymentResult = {
        distributionCanisterId: Principal;
    };

    // For backend service compatibility
    public type StableState = {
        var distributionFactoryCanisterId: ?Principal;
        var distributionContracts: [(Text, DistributionContract)];
    };

    public func emptyState() : StableState {
        {
            var distributionFactoryCanisterId = null;
            var distributionContracts = [];
        }
    };


}