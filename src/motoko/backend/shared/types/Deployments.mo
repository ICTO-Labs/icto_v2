import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

import TokenDeployerTypes "../../modules/token_deployer/TokenDeployerTypes";
import TemplateDeployerTypes "../../modules/template_deployer/TemplateDeployerTypes";

module Deployments {
    
    // A variant that represents any possible deployment action in the system.
    // This is the core payload for the unified deployment flow.
    public type DeploymentPayload = {
        #Token: TokenDeployerTypes.DeploymentRequest;
        #Template: TemplateDeployerTypes.RemoteDeployRequest;
    };

    // A standardized result returned by the unified deployment flow.
    // This provides a consistent success object for the backend.
    public type StandardDeploymentResult = {
        canisterId: Principal;
        transactionId: ?Text;
        paidAmount: Nat;
    };
} 