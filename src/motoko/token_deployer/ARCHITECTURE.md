# Token Deployer Architecture - ICTO V2

## Overview

The Token Deployer is a specialized microservice responsible for deploying ICRC-1/2 tokens using actor class instantiation. It operates under the Central Gateway Pattern, receiving validated deployment requests from the Backend and executing token creation with minimal business logic.

## Core Principles

1. **Single Responsibility**: Focus solely on token deployment execution
2. **Zero Business Logic**: All validation handled by Backend
3. **Actor Class Pattern**: Dynamic canister creation for tokens
4. **Standardized Health Interface**: Uniform health monitoring
5. **Cycle Management**: Efficient resource utilization
6. **Audit Integration**: Complete deployment tracking

## Directory Structure

```
token_deployer/
├── main.mo                    # Main deployment service actor
├── templates/                 # Token deployment templates
│   └── TokenTemplate.mo     # ICRC token template (placeholder)
└── ARCHITECTURE.md           # This file
```

## Service Architecture

### Core Functions

#### 1. Token Deployment Engine
**Purpose**: Execute token canister creation using actor classes

```motoko
public shared func deployToken(request: DeployTokenRequest) : 
    async Result<DeployTokenResponse, Text>
```

**Flow**:
```
Receive Request from Backend
    ↓
Security Validation (whitelist check)
    ↓
Request Parameter Validation
    ↓
Cycles Balance Check
    ↓
Actor Class Instantiation
    ↓
Token Canister Creation
    ↓
Deployment Record Storage
    ↓
Return Canister ID & Metadata
```

#### 2. Health Monitoring System
**Standardized Interface**:
```motoko
public func healthCheck() : async Bool
public query func getHealthInfo() : async HealthInfo
public query func getServiceInfo() : async ServiceInfo
```

**Health Criteria**:
- Sufficient cycles for deployment (>2T cycles)
- Service responsiveness
- Memory availability
- Template accessibility

#### 3. Security & Access Control
**Whitelist-Based Security**:
- Only Backend and authorized canisters can deploy
- Admin-managed whitelist system
- Controller override capability

### Data Types

#### DeployTokenRequest
```motoko
{
    projectId: ?Text;           // Optional project association
    tokenInfo: TokenInfo;       // Token metadata and configuration
    initialSupply: Nat;         // Token initial supply
    premintTo: ?Principal;      // Pre-mint recipient (defaults to caller)
    metadata: ?[(Text, Text)];  // Additional token metadata
}
```

#### DeployTokenResponse
```motoko
{
    canisterId: Text;           // Deployed token canister ID
    projectId: ?Text;           // Associated project ID
    tokenInfo: TokenInfo;       // Confirmed token configuration
    deployedAt: Time.Time;      // Deployment timestamp
    deployedBy: Principal;      // Deployer principal
    cyclesUsed: Nat;           // Cycles consumed in deployment
}
```

#### TokenInfo
```motoko
{
    name: Text;                 // Token name
    symbol: Text;               // Token symbol (max 10 chars)
    decimals: Nat;              // Decimal places
    transferFee: Nat;           // Transfer fee amount
    totalSupply: Nat;           // Maximum token supply
    metadata: ?[(Text, Text)];  // Token metadata
    logo: Text;                 // Token logo (base64 encoded)
    canisterId: ?Text;          // Target canister ID (optional)
}
```

## Actor Class Deployment Pattern

### Traditional vs Actor Class Approach

#### Traditional Deployment
```
1. Pre-deployed token canisters
2. Configuration via init arguments
3. Limited customization
4. Resource pre-allocation
```

#### Actor Class Deployment (ICTO V2)
```
1. Dynamic canister creation at runtime
2. Full customization per deployment
3. Resource efficiency
4. Scalable architecture
```

### Implementation Flow

```motoko
// 1. Prepare deployment parameters
let tokenInitArgs = {
    name = request.tokenInfo.name;
    symbol = request.tokenInfo.symbol;
    decimals = request.tokenInfo.decimals;
    initialSupply = request.initialSupply;
    premintTo = Option.get(request.premintTo, caller);
    fee = request.tokenInfo.transferFee;
    minter = Option.get(request.premintTo, caller);
    metadata = Option.get(request.metadata, []);
};

// 2. Add cycles for new canister
Cycles.add(CYCLES_FOR_TOKEN_CREATION);

// 3. Instantiate actor class (TODO: Implementation)
let tokenCanister = await TokenTemplate.create(tokenInitArgs);

// 4. Return deployment details
```

## Resource Management

### Cycle Economics
- **Deployment Cost**: 2T cycles per token
- **Minimum Reserve**: 2T cycles for service operation
- **Total Required**: 4T cycles minimum
- **Optimization**: Dynamic allocation based on token complexity

### Memory Management
- **Deployment Records**: Efficient Trie storage
- **Upgrade Safety**: Stable variable preservation
- **Garbage Collection**: Automatic old record cleanup

### Performance Metrics
- **Deployment Time**: <10s per token
- **Cycle Efficiency**: >95% utilization
- **Success Rate**: >99% for valid requests
- **Concurrent Deployments**: 10+ simultaneous

## Security Architecture

### Access Control Layers

#### 1. Whitelist Security
```motoko
private func _isWhitelisted(caller: Principal) : Bool
```
- Backend canister automatically whitelisted
- Admin-controlled whitelist management
- Regular whitelist auditing

#### 2. Request Validation
```motoko
private func _validateRequest(request: DeployTokenRequest) : Result<(), Text>
```
- Token symbol length limits (≤10 chars)
- Token name length limits (≤50 chars)
- Supply validation (>0)
- Metadata format checking

#### 3. Resource Protection
- Cycle balance verification before deployment
- Memory usage monitoring
- Rate limiting via Backend

### Threat Mitigation
- **Unauthorized Deployment**: Whitelist-only access
- **Resource Exhaustion**: Cycle balance checks
- **Malformed Requests**: Comprehensive validation
- **Service Abuse**: Backend-controlled rate limiting

## Monitoring & Observability

### Health Monitoring
**Real-time Metrics**:
```motoko
{
    isHealthy: Bool;            // Overall service health
    version: Text;              // Service version
    uptime: Nat;               // Service uptime in seconds
    resourceUsage: {
        cycles: Nat;            // Current cycle balance
        memory: Nat;            // Memory usage
        totalDeployments: Nat;  // Total deployments processed
    };
    capabilities: [Text];       // Available service functions
    status: Text;              // Health status description
}
```

### Deployment Tracking
**Per-Deployment Records**:
```motoko
{
    canisterId: Principal;      // Deployed token canister
    deployedBy: Principal;      // Deployer principal
    projectId: ?Text;          // Associated project
    tokenInfo: TokenInfo;      // Token configuration
    deployedAt: Time.Time;     // Deployment timestamp
    cyclesUsed: Nat;          // Resources consumed
    deploymentType: DeploymentType; // Fresh or upgrade
}
```

### Query Capabilities
- **getUserDeployments**: Deployments by specific user
- **getDeploymentRecord**: Specific deployment details
- **getAllDeployments**: Complete deployment history
- **getServiceHealth**: Current service status

## Integration Points

### Backend Integration
**Request Flow**:
```
Backend.deployToken() 
    ↓
ServiceEndpoints health check
    ↓
TokenDeployer.deployToken()
    ↓
Response with canister ID
    ↓
Backend updates UserRegistry & Audit
```

### Audit Storage Integration
**Deployment Logging**:
- Deployment attempts (success/failure)
- Resource utilization tracking
- Error condition logging
- Performance metrics

## Future Enhancements

### Planned Features

#### 1. Advanced Token Types
- **Multi-Standard Support**: ICRC-3, ICRC-7 NFTs
- **Custom Extensions**: Project-specific token features
- **Cross-Chain Tokens**: Multi-chain deployment capability

#### 2. Template Management
- **Dynamic Templates**: Runtime template selection
- **Template Versioning**: Multiple template versions
- **Custom Templates**: Project-specific templates

#### 3. Enhanced Security
- **Hardware Security**: HSM integration for sensitive operations
- **Multi-Signature**: Multi-admin deployment approval
- **Audit Integration**: Real-time security monitoring

#### 4. Performance Optimization
- **Batch Deployment**: Multiple tokens in single call
- **Parallel Processing**: Concurrent deployment handling
- **Resource Pooling**: Shared resource optimization

### Scalability Roadmap

#### Phase 1: Current (MVP)
- Single token deployment
- Basic health monitoring
- Whitelist security

#### Phase 2: Enhanced (Q1 2025)
- Batch deployment capability
- Advanced template system
- Performance optimization

#### Phase 3: Enterprise (Q2 2025)
- Multi-chain support
- Custom template creation
- Advanced analytics

## Deployment & Operations

### Upgrade Process
1. **State Preservation**: All deployment records maintained
2. **Service Compatibility**: Backward-compatible API
3. **Health Verification**: Post-upgrade health checks
4. **Rollback Capability**: Previous version restoration

### Monitoring Setup
- **Health Checks**: 5-minute intervals via Backend
- **Resource Alerts**: Low cycle balance warnings
- **Performance Tracking**: Deployment time monitoring
- **Error Alerting**: Failed deployment notifications

### Maintenance Procedures
- **Cycle Top-up**: Regular cycle balance maintenance
- **Whitelist Updates**: Admin-controlled access management
- **Template Updates**: New token template deployments
- **Performance Tuning**: Resource optimization adjustments

---

*Last Updated: 2024-12-18*
*Version: 1.0.0* 