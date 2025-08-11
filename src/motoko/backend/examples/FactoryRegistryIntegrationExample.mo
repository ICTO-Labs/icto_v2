// Factory Registry Integration Example
// Ví dụ tích hợp Factory Registry với existing deployment flows

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import FactoryRegistryTypes "../modules/systems/factory_registry/FactoryRegistryTypes";

module IntegrationExample {

    // ==================================================================================================
    // EXAMPLE: Tích hợp với Distribution Factory
    // ==================================================================================================

    // Đây là ví dụ về cách tích hợp factory registry vào flow deployment hiện tại:

    /*
    // Trong distribution deployment function (ví dụ trong main.mo):
    
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
    // Frontend có thể call các functions sau để lấy data cho /distribution page:

    1. Lấy tất cả distribution contracts mà user có liên quan:
    
    let distributionCanisters = await backend.getRelatedCanistersByType(#DistributionFactory, null);
    // Returns: Result<[Principal], Error>
    
    2. Lấy tất cả related canisters (all types):
    
    let allRelated = await backend.getRelatedCanisters(null);
    // Returns: Result<UserDeploymentMap, Error>
    
    3. Lấy deployment details cho specific canisters:
    
    let myDeployments = await backend.getMyDeployments(?#DistributionFactory, ?50, ?0);
    // Returns: Result<[DeploymentInfo], Error>
    
    4. Lấy thông tin chi tiết của một deployment:
    
    let deploymentInfo = await backend.getDeploymentInfo(deploymentId);
    // Returns: Result<DeploymentInfo, Error>
    */

    // ==================================================================================================
    // FACTORY SETUP EXAMPLE
    // ==================================================================================================

    /*
    // Admin setup các factories (một lần duy nhất):
    
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
    Tóm tắt pattern tích hợp:

    1. User tạo deployment request (ví dụ: createDistribution)
    2. Backend validate + process payment
    3. Backend deploy contract via factory
    4. **Backend auto-register deployment** bằng _registerSuccessfulDeployment()
    5. Frontend query related canisters bằng getRelatedCanistersByType()
    
    Pattern này đảm bảo:
    - Automatic tracking không cần manual intervention
    - User chỉ cần query, không cần manage registry
    - Consistent data across all deployment types
    - Easy frontend integration với clear APIs
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