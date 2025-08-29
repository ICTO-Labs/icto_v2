import Principal "mo:base/Principal";
import Nat "mo:base/Nat";

import TokenFactoryTypes "../../modules/token_factory/TokenFactoryTypes";
import TemplateFactoryTypes "../../modules/template_factory/TemplateFactoryTypes";
import DistributionFactoryTypes "../../modules/distribution_factory/DistributionFactoryTypes";
import DAOFactoryTypes "../../modules/dao_factory/DAOFactoryTypes";

module Deployments {
    
    // A variant that represents any possible deployment action in the system.
    // This is the core payload for the unified deployment flow.
    public type DeploymentPayload = {
        #Token: TokenFactoryTypes.DeploymentRequest;
        #Template: TemplateFactoryTypes.RemoteDeployRequest;
        #Distribution: DistributionFactoryTypes.DistributionConfig;
        #DAO: DAOFactoryTypes.DAOConfig;
    };

    // A standardized result returned by the unified deployment flow.
    // This provides a consistent success object for the backend.
    public type StandardDeploymentResult = {
        canisterId: Principal;
        transactionId: ?Text;
        paidAmount: Nat;
    };
}