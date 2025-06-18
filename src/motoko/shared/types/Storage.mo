// ⬇️ Storage Types for User Registry and Deployment Tracking
// Comprehensive user activity and canister deployment tracking

import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Common "Common";
import Audit "Audit";

module {
    // ===== USER REGISTRY TYPES =====
    
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
    
    // ===== DEPLOYMENT REGISTRY =====
    
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
    
    // ===== SPECIFIC DEPLOYMENT INFO =====
    
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
        distributionType: Text;
        totalAmount: Nat;
        recipientCount: Nat;
        startTime: ?Common.Timestamp;
        endTime: ?Common.Timestamp;
        cliffPeriod: ?Nat;
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
    
    // ===== USER ACTIVITY SUMMARY =====
    
    public type UserActivitySummary = {
        userId: Common.UserId;
        timeRange: Audit.TimeRange;
        
        // Deployment statistics
        totalDeployments: Nat;
        activeDeployments: Nat;
        failedDeployments: Nat;
        deploymentsByType: [(Audit.ServiceType, Nat)];
        
        // Financial statistics
        totalFeesPaid: Nat;
        averageDeploymentCost: Nat;
        paymentTokensUsed: [Common.CanisterId];
        
        // Activity statistics
        totalActions: Nat;
        successfulActions: Nat;
        failedActions: Nat;
        lastActiveDate: Common.Timestamp;
        
        // Project statistics
        projectsCreated: Nat;
        activeProjects: Nat;
        completedProjects: Nat;
    };
    
    // ===== SEARCH AND QUERY TYPES =====
    
    public type UserQuery = {
        status: ?UserStatus;
        registeredAfter: ?Common.Timestamp;
        registeredBefore: ?Common.Timestamp;
        minDeployments: ?Nat;
        maxDeployments: ?Nat;
        minFeesPaid: ?Nat;
        country: ?Text;
        limit: ?Nat;
        offset: ?Nat;
    };
    
    public type DeploymentQuery = {
        userId: ?Common.UserId;
        projectId: ?Common.ProjectId;
        serviceType: ?Audit.ServiceType;
        deploymentType: ?Text;
        status: ?DeploymentStatus;
        deployedAfter: ?Common.Timestamp;
        deployedBefore: ?Common.Timestamp;
        tags: ?[Text];
        isPublic: ?Bool;
        limit: ?Nat;
        offset: ?Nat;
    };
    
    // ===== STORAGE OPTIMIZATION =====
    
    public type UserIndex = {
        byStatus: [(UserStatus, [Common.UserId])];
        byCountry: [(Text, [Common.UserId])];
        byRegistrationDate: [(Common.Timestamp, [Common.UserId])];
        byDeploymentCount: [(Nat, [Common.UserId])];
    };
    
    public type DeploymentIndex = {
        byUser: [(Common.UserId, [Text])]; // userId -> deploymentIds
        byProject: [(Common.ProjectId, [Text])]; // projectId -> deploymentIds
        byType: [(Audit.ServiceType, [Text])]; // serviceType -> deploymentIds
        byStatus: [(DeploymentStatus, [Text])]; // status -> deploymentIds
        byDate: [(Common.Timestamp, [Text])]; // date -> deploymentIds
    };
    
    // ===== PAGINATION RESULTS =====
    
    public type UserPage = {
        users: [UserProfile];
        totalCount: Nat;
        page: Nat;
        pageSize: Nat;
        hasNext: Bool;
    };
    
    public type DeploymentPage = {
        deployments: [DeploymentRecord];
        totalCount: Nat;
        page: Nat;
        pageSize: Nat;
        hasNext: Bool;
        summary: ?DeploymentSummary;
    };
    
    public type DeploymentSummary = {
        totalDeployments: Nat;
        activeDeployments: Nat;
        totalCosts: Nat;
        deploymentsByType: [(Audit.ServiceType, Nat)];
        timeRange: Audit.TimeRange;
    };
    
    // ===== HELPER FUNCTIONS =====
    
    public func generateDeploymentId(
        userId: Common.UserId, 
        serviceType: Audit.ServiceType, 
        timestamp: Common.Timestamp
    ) : Text {
        let serviceTypeText = switch (serviceType) {
            case (#TokenDeployer) "token";
            case (#LockDeployer) "lock";
            case (#DistributionDeployer) "dist";
            case (#LaunchpadDeployer) "launch";
            case (#InvoiceService) "invoice";
            case (#Backend) "backend";
        };
        Principal.toText(userId) # "_" # serviceTypeText # "_" # Int.toText(timestamp)
    };
    
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
                    pushNotifications = true;
                    marketingEmails = false;
                    theme = #Auto;
                    language = "en";
                    defaultGasLimit = null;
                };
            };
        }
    };
    
    public func serviceTypeToText(serviceType: Audit.ServiceType) : Text {
        switch (serviceType) {
            case (#TokenDeployer) "Token Deployer";
            case (#LockDeployer) "Lock Deployer";
            case (#DistributionDeployer) "Distribution Deployer";
            case (#LaunchpadDeployer) "Launchpad Deployer";
            case (#InvoiceService) "Invoice Service";
            case (#Backend) "Backend";
        }
    };
} 