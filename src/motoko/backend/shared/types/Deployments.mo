import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

import TokenFactoryTypes "../../modules/token_factory/TokenFactoryTypes";
import TemplateDeployerTypes "../../modules/template_deployer/TemplateDeployerTypes";

module Deployments {
    
    // A variant that represents any possible deployment action in the system.
    // This is the core payload for the unified deployment flow.
    public type DeploymentPayload = {
        #Token: TokenFactoryTypes.DeploymentRequest;
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