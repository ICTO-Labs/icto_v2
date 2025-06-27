// TokenController.mo - Token Management Business Logic
// Extracted from main.mo to improve code organization

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Trie "mo:base/Trie";

// Import shared types
import AuditLogger "../modules/AuditLogger";
import UserRegistry "../modules/UserRegistry";
import ControllerTypes "../types/ControllerTypes";
import PaymentValidator "../modules/PaymentValidator";
import SystemManager "../modules/SystemManager";
import TokenService "../services/TokenService";


import TokenDeployerTypes "../../shared/types/TokenDeployer";

module TokenController {
    
    // Use centralized types
    public type TokenInfo = TokenDeployerTypes.TokenInfo;
    public type TokenRecord = TokenDeployerTypes.TokenRecord;
    public type TokenDeploymentRequest = TokenDeployerTypes.TokenDeploymentRequest;
    public type TokenDeploymentResult = TokenDeployerTypes.TokenDeploymentResult;
    
    // Enhanced TokenControllerState to include all required storages
    public type TokenControllerState = {
        userRegistryStorage: UserRegistry.UserRegistryStorage;
        auditStorage: AuditLogger.AuditStorage;
        tokenRecords: [(Text, TokenRecord)];
        systemStorage: ?SystemManager.ConfigStorage;
        paymentValidatorStorage: ?PaymentValidator.PaymentValidatorStorage;
    };
    
    // Initialize controller with required state
    public func init(
        userRegistryStorage: UserRegistry.UserRegistryStorage,
        auditStorage: AuditLogger.AuditStorage,
        tokenRecords: [(Text, TokenRecord)]
    ) : TokenControllerState {
        {
            userRegistryStorage = userRegistryStorage;
            auditStorage = auditStorage;
            tokenRecords = tokenRecords;
            systemStorage = null;
            paymentValidatorStorage = null;
        }
    };
    
    // Update context with additional required storages
    public func updateContext(
        state: TokenControllerState,
        auditStorage: AuditLogger.AuditStorage,
        userRegistryStorage: UserRegistry.UserRegistryStorage,
        systemStorage: SystemManager.ConfigStorage,
        paymentValidatorStorage: PaymentValidator.PaymentValidatorStorage
    ) : TokenControllerState {
        {
            userRegistryStorage = userRegistryStorage;
            auditStorage = auditStorage;
            tokenRecords = state.tokenRecords;
            systemStorage = ?systemStorage;
            paymentValidatorStorage = ?paymentValidatorStorage;
        }
    };
    
    // ================ TOKEN INFORMATION RETRIEVAL ================
    
    public func getTokenRecord(
        state: TokenControllerState,
        tokenId: Text
    ) : ?TokenRecord {
        Array.find<(Text, TokenRecord)>(state.tokenRecords, func((id, _)) { id == tokenId }) |> 
        Option.map<(Text, TokenRecord), TokenRecord>(_, func((_, record)) { record })
    };
    
    public func getTokensByOwner(
        state: TokenControllerState,
        owner: Principal
    ) : [TokenRecord] {
        Array.mapFilter<(Text, TokenRecord), TokenRecord>(
            state.tokenRecords, 
            func((_, record)) { 
                if (record.owner == owner) ?record else null 
            }
        )
    };
    
    public func getTokensByProject(
        state: TokenControllerState,
        projectId: Text
    ) : [TokenRecord] {
        Array.mapFilter<(Text, TokenRecord), TokenRecord>(
            state.tokenRecords, 
            func((_, record)) { 
                if (record.projectId == projectId) ?record else null 
            }
        )
    };
    
    public func getAllTokens(
        state: TokenControllerState
    ) : [(Text, TokenRecord)] {
        state.tokenRecords
    };
    
    // ================ TOKEN ANALYTICS ================
    
    public func getTokenStatistics(
        state: TokenControllerState,
        tokenSymbol: Text
    ) : ?{
        symbol: Text;
        deployer: Principal;
        deployedAt: ?Int;
        canisterId: ?Text;
        projectId: ?Text;
    } {
        // TODO: Implement token statistics lookup
        // For now, return null - this needs to be implemented with proper token registry
        null
    };
    
    // TODO: Implement comprehensive token analytics
    /*
    public func getTokenAnalytics(
        state: TokenControllerState,
        tokenId: Text
    ) : ?TokenAnalytics {
        // Implementation needed
        null
    };
    */
    
} 