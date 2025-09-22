import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Int "mo:base/Int";

import Common "../../../shared/types/Common";
import Audit "../audit/AuditTypes";


module UserTypes {

    // ==================================================================================================
    // ⬇️ Ported from V1: icto_app/shared/types/Storage.mo and /backend/modules/UserRegistry.mo
    // Refactored for modular pipeline compatibility (V2)
    // ==================================================================================================
    
    // --- STATE ---
    
    public type State = {
        var userProfiles: Trie.Trie<Text, UserProfile>; // userId (as Text) -> profile
        var deploymentRecords: Trie.Trie<Text, DeploymentRecord>; // deploymentId -> record
        var userDeployments: Trie.Trie<Text, [Text]>; // userId (as Text) -> deploymentIds
        var projectDeployments: Trie.Trie<Common.ProjectId, [Text]>; // projectId -> deploymentIds
        var canisterOwnership: Trie.Trie<Text, Common.UserId>; // canisterId (as Text) -> userId
    };

    public type StableState = {
        userProfiles: [(Text, UserProfile)];
        deploymentRecords: [(Text, DeploymentRecord)];
        userDeployments: [(Text, [Text])];
        projectDeployments: [(Common.ProjectId, [Text])];
        canisterOwnership: [(Text, Common.UserId)];
    };
    
    public func emptyState() : State {
      {
        var userProfiles = Trie.empty();
        var deploymentRecords = Trie.empty();
        var userDeployments = Trie.empty();
        var projectDeployments = Trie.empty();
        var canisterOwnership = Trie.empty();
      }
    };
    
    // --- USER PROFILE ---
    
    public type UserProfile = {
        userId: Common.UserId;
        registeredAt: Common.Timestamp;
        lastActiveAt: Common.Timestamp;
        totalFeesPaid: Nat;
        deploymentCount: Nat;
        preferredPaymentToken: ?Common.CanisterId;
        status: UserStatus;
        metadata: UserMetadata;
    };
    
    public type UserStatus = {
        #Active;
        #Suspended : Text; // reason
        #Banned : Text; // reason
        #PendingVerification;
    };
    
    public type UserMetadata = {
        email: ?Text;
        telegramHandle: ?Text;
        discordHandle: ?Text;
        twitterHandle: ?Text;
        companyName: ?Text;
        websiteUrl: ?Text;
        country: ?Text;
        timezone: ?Text;
        preferences: UserPreferences;
    };
    
    public type UserPreferences = {
        emailNotifications: Bool;
        pushNotifications: Bool;
        marketingEmails: Bool;
        theme: Theme;
        language: Text;
        defaultGasLimit: ?Nat;
    };
    
    public type Theme = {
        #Light;
        #Dark;
        #Auto;
    };

    // --- DEPLOYMENT ---
    
    public type DeploymentRecord = {
        id: Text; // deploymentId
        userId: Common.UserId;
        projectId: ?Common.ProjectId;
        deploymentType: DeploymentType;
        canisterId: Common.CanisterId;
        serviceType: Audit.ServiceType;
        deployedAt: Common.Timestamp;
        status: DeploymentStatus;
        configuration: DeploymentConfig;
        costs: DeploymentCosts;
        metadata: DeploymentMetadata;
    };
    
    public type DeploymentType = {
        #Token : TokenDeploymentInfo;
        #Lock : LockDeploymentInfo;
        #Distribution : DistributionDeploymentInfo;
        #Launchpad : LaunchpadDeploymentInfo;
        #DAO : DAODeploymentInfo;
        #Multisig : MultisigDeploymentInfo;
    };
    
    public type DeploymentStatus = {
        #Deploying;
        #Active;
        #Paused;
        #Stopped;
        #Failed : Text;
        #Deprecated;
    };
    
    public type DeploymentConfig = {
        rawConfig: Text; // JSON configuration used for deployment
        templateVersion: Text;
        features: [Text];
        upgradePolicy: Text;
    };
    
    public type DeploymentCosts = {
        deploymentFee: Nat;
        cyclesCost: Nat;
        totalCost: Nat;
        paymentToken: Common.CanisterId;
        transactionId: ?Audit.TransactionId;
    };
    
    public type DeploymentMetadata = {
        name: Text;
        description: ?Text;
        tags: [Text];
        isPublic: Bool;
        parentProject: ?Common.ProjectId;
        dependsOn: [Common.CanisterId]; // other canisters this depends on
        version: Text;
    };
    
    // --- DEPLOYMENT - SPECIFIC INFO ---
    
    public type TokenDeploymentInfo = {
        tokenName: Text;
        tokenSymbol: Text;
        decimals: Nat8;
        totalSupply: Nat;
        standard: Text; // ICRC-1, ICRC-2, etc
        features: [TokenFeature];
    };
    
    public type TokenFeature = {
        #Mintable;
        #Burnable;
        #Pausable;
        #Fee;
        #Blacklist;
        #Whitelist;
    };
    
    public type LockDeploymentInfo = {
        lockType: Text;
        duration: Nat; // seconds
        totalAmount: Nat;
        recipientCount: Nat;
        releaseSchedule: Text;
        canCancel: Bool;
    };
    
    public type DistributionDeploymentInfo = {
        title: Text;
        tokenSymbol: Text;
        totalAmount: Nat;
        vestingSchedule: Text;
        distributionType: Text;
        description: ?Text;
        tokenCanisterId: ?Text;
        eligibilityType: ?Text;
        recipientMode: ?Text;
        recipientCount: ?Nat;
        startTime: ?Common.Timestamp;
        endTime: ?Common.Timestamp;
        initialUnlockPercentage: ?Nat;
        allowCancel: ?Bool;
        allowModification: ?Bool;
        feeStructure: ?Text;
    };
    
    public type LaunchpadDeploymentInfo = {
        launchpadName: Text;
        tokenId: ?Common.CanisterId;
        fundingGoal: ?Nat;
        hardCap: ?Nat;
        daoEnabled: Bool;
        votingEnabled: Bool;
    };
    
    public type DAODeploymentInfo = {
        daoName: Text;
        governanceToken: Common.CanisterId;
        votingThreshold: Nat;
        proposalDuration: Nat;
        executionDelay: Nat;
        memberCount: Nat;
    };

    public type MultisigDeploymentInfo = {
        walletName: Text;
        signersCount: Nat;
        threshold: Nat;
        requiresTimelock: Bool;
        dailyLimit: ?Nat;
        allowRecovery: Bool;
        maxProposalLifetime: Int;
    };

    // --- UTILS ---

    // Function to create a default user profile
    public func createDefaultUserProfile(userId: Common.UserId) : UserProfile {
        {
            userId = userId;
            registeredAt = Time.now();
            lastActiveAt = Time.now();
            totalFeesPaid = 0;
            deploymentCount = 0;
            preferredPaymentToken = null;
            status = #Active;
            metadata = {
                email = null;
                telegramHandle = null;
                discordHandle = null;
                twitterHandle = null;
                companyName = null;
                websiteUrl = null;
                country = null;
                timezone = null;
                preferences = {
                    emailNotifications = true;
                    pushNotifications = false;
                    marketingEmails = false;
                    theme = #Auto;
                    language = "en";
                    defaultGasLimit = null;
                };
            };
        }
    };

    // Function to generate a unique deployment ID
    public func generateDeploymentId(
        userId: Common.UserId,
        serviceType: Audit.ServiceType,
        timestamp: Common.Timestamp
    ) : Text {
        let serviceText = Audit.serviceTypeToText(serviceType);
        let userText = Principal.toText(userId);
        let timeText = Int.toText(timestamp / 1_000_000); // Convert ns to ms
        serviceText # ":" # userText # ":" # timeText
    };
};
