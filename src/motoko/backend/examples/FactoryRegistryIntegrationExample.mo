// Factory Registry Integration Example
// Example of integrating Factory Registry with existing deployment flows

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import FactoryRegistryTypes "../modules/systems/factory_registry/FactoryRegistryTypes";

module IntegrationExample {

    // ==================================================================================================
    // EXAMPLE: Integrate with Distribution Factory
    // ==================================================================================================

    // This is an example of how to integrate factory registry into the current deployment flow:

    /*
    // In distribution deployment function (e.g. in main.mo):
    
    public shared ({ caller }) func createDistribution(args: DistributionArgs) : async Result.Result<Principal, Text> {
        // 1. Existing validation and payment logic
        switch (validateArgs(args)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };
        
        // 2. Process payment
        switch (await processPayment(caller, args.paymentInfo)) {
            case (#err(msg)) { return #err(msg) };
            case (#ok()) {};
        };
        
        // 3. Deploy distribution contract
        let deployResult = await deployDistributionContract(args);
        let canisterId = switch (deployResult) {
            case (#err(msg)) { return #err(msg) };
            case (#ok(id)) { id };
        };
        
        // 4. **NEW: Register deployment in factory registry**
        await _registerSuccessfulDeployment(
            caller,                              // creator
            #DistributionFactory,                // deployment type
            canisterId,                          // deployed canister ID
            args.title,                          // name
            args.description,                    // description
            ?args.recipients                     // recipients list
        );
        
        // 5. Return success
        #ok(canisterId)
    };
    */

    // ==================================================================================================
    // USER QUERIES - Frontend Integration Examples
    // ==================================================================================================

    /*
    // Frontend can call the following functions to get data for /distribution page:

    1. Get all distribution contracts user is related to:
    
    let distributionCanisters = await backend.getRelatedCanistersByType(#DistributionFactory, null);
    // Returns: Result<[Principal], Error>
    
    2. Get all related canisters (all types):
    
    let allRelated = await backend.getRelatedCanisters(null);
    // Returns: Result<UserDeploymentMap, Error>
    
    3. Get deployment details for specific canisters:
    
    let myDeployments = await backend.getMyDeployments(?#DistributionFactory, ?50, ?0);
    // Returns: Result<[DeploymentInfo], Error>
    
    4. Get detailed information about a deployment:
    
    let deploymentInfo = await backend.getDeploymentInfo(deploymentId);
    // Returns: Result<DeploymentInfo, Error>
    */

    // ==================================================================================================
    // FACTORY SETUP EXAMPLE
    // ==================================================================================================

    /*
    // Admin setup factories (once):
    
    // 1. Register distribution factory
    await backend.adminRegisterFactory(
        #DistributionFactory, 
        Principal.fromText("rdmx6-jaaaa-aaaah-qca2q-cai") // distribution factory canister ID
    );
    
    // 2. Register token factory
    await backend.adminRegisterFactory(
        #TokenFactory,
        Principal.fromText("rrkah-fqaaa-aaaah-qcl4q-cai") // token factory canister ID
    );
    
    // 3. Register launchpad factory
    await backend.adminRegisterFactory(
        #LaunchpadFactory,
        Principal.fromText("ryjl3-tyaaa-aaaah-qcd6a-cai") // launchpad factory canister ID
    );
    */

    // ==================================================================================================
    // DEPLOYMENT FLOW PATTERN
    // ==================================================================================================

    /*
    Summary of integration pattern:

    1. User create deployment request (e.g. createDistribution)
    2. Backend validate + process payment
    3. Backend deploy contract via factory
    4. **Backend auto-register deployment** by _registerSuccessfulDeployment()
    5. Frontend query related canisters by getRelatedCanistersByType()
    
    This pattern ensures:
    - Automatic tracking without manual intervention
    - User only needs to query, no need to manage registry
    - Consistent data across all deployment types
    - Easy frontend integration with clear APIs
    */

    // ==================================================================================================
    // TYPE DEFINITIONS FOR REFERENCE
    // ==================================================================================================

    /*
    type UserDeploymentMap = {
        distributions: [Principal]; // Distribution contracts user is recipient of
        tokens: [Principal];        // Tokens user deployed
        templates: [Principal];     // Templates user created
        launchpads: [Principal];    // Launchpads user created/participated in
        nfts: [Principal];          // Future
        staking: [Principal];       // Future
        daos: [Principal];          // Future
    };

    type DeploymentInfo = {
        id: Text;                           // Unique deployment ID
        deploymentType: DeploymentType;     // Type of deployment
        factoryPrincipal: Principal;        // Factory that created this
        canisterId: Principal;              // Deployed canister ID
        creator: Principal;                 // User who created it
        recipients: ?[Principal];           // For distributions, launchpads etc
        createdAt: Int;                     // Timestamp
        metadata: DeploymentMetadata;       // Name, description, status etc
    };
    */
}