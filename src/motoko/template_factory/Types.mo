import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";

module TemplateFactoryTypes {

    // These are dummy/placeholder types for now.
    // In a real implementation, they would be imported from the actual module types
    // for lock, dao, etc. that will be stored in the /templates folder.
    public type LockConfig = { name: Text; unlockTime: Nat };
    public type DAOConfig = { name: Text; quorum: Nat };
    public type DistributionConfig = { name: Text; totalTokens: Nat };
    public type LaunchpadConfig = { name: Text; goal: Nat };

    // This enum defines all the types of templates this deployer can handle.
    // To add a new deployable template, you first add it here.
    public type DeployerType = {
        #Lock;
        #Distribution;
        #Launchpad;
        #DAO;
    };

    // A generic config variant that can hold the configuration for any template-based deployment.
    public type DeployConfig = {
        #LockConfig: LockConfig;
        #DAOConfig: DAOConfig;
        #DistributionConfig: DistributionConfig;
        #LaunchpadConfig: LaunchpadConfig;
    };

    // The standardized request object sent from the backend orchestrator.
    public type RemoteDeployRequest = {
        deployerType: DeployerType;
        config: DeployConfig;
        owner: Principal; // The principal who will own the new canister
    };

    // --- PENDING & RECORD-KEEPING TYPES ---

    public type PendingId = Text;

    // The status of a deployment lifecycle.
    public type DeploymentStatus = {
        #Pending;      // The deployment has been requested and is in the queue.
        #Processing;   // The async deployment call is in-flight.
        #Completed;    // The canister was created successfully.
        #Failed;       // The deployment failed and can be retried.
    };

    // The standardized result object.
    public type RemoteDeployResult = {
        canisterId: Principal;
    };

    // This is the source-of-truth record for every deployment attempt.
    // It is stored in a stable Trie for persistence.
    public type DeploymentRecord = {
        id: PendingId;
        status: DeploymentStatus;
        request: RemoteDeployRequest; // Store the full payload for tracing and retries
        result: ?RemoteDeployResult;
        error: ?Text;                 // Store detailed error messages
        createdAt: Time.Time;
        updatedAt: Time.Time;
    };
    
    // A structured error type returned to the backend.
    // This allows the backend to safely parse the PendingId.
    public type DeploymentError = {
        #Unauthorized;
        #InvalidPayload: Text;
        #TemporarilyUnavailable: Text;
        #Pending: PendingId; // Indicates success, but processing is async
    };
}
