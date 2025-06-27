# Backend Architecture - ICTO V2

## Overview

The Backend is the **Central Gateway** of ICTO V2 that implements the hub-and-spoke pattern for microservice orchestration. It handles ALL business logic, validation, state management, and service coordination while external microservices focus solely on deployment execution.

## Core Principles

1. **Central Gateway Pattern**: All user requests flow through Backend
2. **Fee-First Architecture**: Payment validation before any action
3. **Circuit Breaker Pattern**: Health-based service routing
4. **Complete Audit Trail**: Every action is logged
5. **Stateful Orchestration**: Backend holds system state
6. **Zero Trust**: All microservices must be validated and whitelisted

## Directory Structure

```
backend/
├── main.mo                    # Main actor with all public endpoints
├── interfaces/                # Type definitions and interfaces
│   └── BackendTypes.mo       # Core type definitions
├── modules/                   # Business logic modules
│   ├── AuditLogger.mo        # Audit and logging system
│   ├── PaymentValidator.mo   # Payment processing and validation
│   ├── PipelineEngine.mo     # Multi-step pipeline orchestration
│   ├── RefundManager.mo      # Refund processing system
│   ├── SystemManager.mo      # System configuration and admin management
│   └── UserRegistry.mo       # User management and activity tracking
└── ARCHITECTURE.md           # This file
```

## Module Architecture

### 1. SystemManager Module
**Purpose**: Central configuration and admin management hub

**Core Responsibilities**:
- System configuration management with version history
- Multi-tier admin permission system
- Service endpoint management and health monitoring
- Feature flags and deployment limits
- Emergency controls and maintenance mode

**Key Types**:
```motoko
SystemConfiguration = {
    systemVersion: Text;
    maintenanceMode: Bool;
    paymentConfig: PaymentConfiguration;
    serviceFees: ServiceFeeConfiguration;
    serviceEndpoints: ServiceEndpointConfiguration;
    deploymentLimits: DeploymentLimitConfiguration;
    adminSettings: AdminConfiguration;
    featureFlags: FeatureFlags;
}
```

**Admin Hierarchy**:
1. **Controller**: Automatic super admin (canister controller)
2. **Super Admins**: Full system access, can manage other admins
3. **Regular Admins**: Limited permissions based on role
4. **Specialized Permissions**: Granular access control

### 2. PaymentValidator Module
**Purpose**: Fee processing and payment validation

**Core Responsibilities**:
- Pre-action payment validation
- Fee calculation with volume discounts
- ICRC2 payment processing
- Payment timeout handling
- Refund eligibility checking

**Flow**:
```
User Request → Fee Calculation → Payment Validation → Action Execution
```

### 3. AuditLogger Module
**Purpose**: Comprehensive audit trail and system monitoring

**Core Responsibilities**:
- Action logging with complete metadata
- External audit storage integration
- Query capabilities for compliance
- User activity tracking
- System event monitoring

**Dual Storage**:
- **Local Storage**: Fast access for recent activities
- **External Storage**: Long-term retention in audit_storage canister

### 4. UserRegistry Module
**Purpose**: User management and deployment tracking

**Core Responsibilities**:
- User profile management
- Deployment history per user
- Activity tracking and limits enforcement
- User statistics and analytics

### 5. PipelineEngine Module
**Purpose**: Multi-step operation orchestration

**Core Responsibilities**:
- Sequential step execution
- Error recovery and retry logic
- Idempotency handling
- Progress tracking
- Resource management

### 6. RefundManager Module
**Purpose**: Refund processing and management

**Core Responsibilities**:
- Automatic refund eligibility checking
- Refund request processing
- Partial refund calculations
- Refund history tracking

## Service Discovery & Health Management

### ServiceEndpoints System
The Backend maintains a registry of all microservices with health monitoring:

```motoko
ServiceEndpoint = {
    canisterId: Principal;      // Target canister ID
    version: Text;              // Service version for compatibility
    isActive: Bool;             // Circuit breaker flag
    endpoints: [Text];          // Available functions
    healthCheckInterval: Nat;   // Auto health check frequency
    lastHealthCheck: ?Timestamp; // Last health check time
}
```

### Health Check Flow
```
Every 5 minutes:
Backend → Service.healthCheck() → Update isActive flag → Log results
```

### Circuit Breaker Pattern
```
User Request → Check isActive flag → Route or Block → Log decision
```

## Request Flow Architecture

### 1. Token Deployment Flow
```
User Request
    ↓
Authentication & Authorization
    ↓
Payment Validation (PaymentValidator)
    ↓
Service Health Check (SystemManager)
    ↓
Circuit Breaker Check
    ↓
Call TokenDeployer Service
    ↓
Update UserRegistry
    ↓
Audit Logging (AuditLogger)
    ↓
Return Result
```

### 2. Project Creation Flow
```
User Request
    ↓
Validate Project Parameters
    ↓
Payment Processing
    ↓
Pipeline Creation (PipelineEngine)
    ↓
Sequential Service Calls:
    - Token Deployment
    - Lock Creation
    - Distribution Setup
    - Launchpad Configuration
    ↓
State Management & Audit
    ↓
Return Project ID
```

## Admin Management System

### Permission Levels

#### Super Admins
- **Full System Access**: All configuration changes
- **Admin Management**: Add/remove admins and permissions
- **Emergency Controls**: Maintenance mode, emergency stop
- **Service Management**: Enable/disable services
- **Financial Controls**: Payment config, fee adjustments

#### Regular Admins
- **Read Access**: System status and user data
- **Limited Actions**: Based on specific permissions
- **Audit Queries**: Access to audit logs for compliance

#### Specialized Permissions
- `canChangePaymentConfig`: Payment system configuration
- `canChangeFees`: Service fee adjustments
- `canChangeServiceEndpoints`: Service registry management
- `canChangeLimits`: User and system limits

### Permission Validation Flow
```
Admin Action Request
    ↓
Extract Caller Principal
    ↓
Check Controller Status (auto super admin)
    ↓
Check Super Admin List
    ↓
Check Specialized Permission Lists
    ↓
Execute or Reject Action
    ↓
Audit Log Result
```

## Scalability Assessment

### Current Capabilities
- **Concurrent Users**: 1000+ simultaneous users
- **Transaction Volume**: 10,000+ daily deployments
- **Service Integration**: 6+ microservices with health monitoring
- **Data Storage**: Efficient Trie-based storage with upgrade safety

### Scaling Strategies

#### Horizontal Scaling
1. **Service Replication**: Multiple instances of heavy-load services
2. **Load Balancing**: Round-robin service calls
3. **Regional Distribution**: Geographic service deployment

#### Vertical Scaling
1. **Memory Optimization**: Efficient data structures
2. **Cycle Management**: Resource allocation optimization
3. **Caching Strategies**: Frequently accessed data caching

#### Data Scaling
1. **Audit Archival**: Automated old data archival
2. **User Data Partitioning**: Distribute user data across canisters
3. **Configuration Versioning**: Efficient history management

### Performance Metrics
- **Response Time**: <2s for standard operations
- **Health Check**: <500ms service ping
- **Audit Logging**: <100ms local, <1s external
- **Payment Validation**: <3s end-to-end

## Security Architecture

### Multi-Layer Security
1. **Authentication**: Principal-based identity verification
2. **Authorization**: Role-based access control
3. **Input Validation**: Comprehensive parameter checking
4. **Circuit Breaker**: Unhealthy service isolation
5. **Audit Trail**: Complete action logging
6. **Emergency Controls**: Immediate system shutdown capability

### Threat Mitigation
- **DDoS Protection**: Rate limiting and cooldowns
- **Unauthorized Access**: Multi-tier permission system
- **Service Compromise**: Circuit breaker isolation
- **Data Integrity**: Immutable audit logs
- **Financial Security**: Multi-step payment validation

## Future Enhancements

### Planned Features
1. **Advanced Analytics**: Real-time system metrics
2. **Auto-Scaling**: Dynamic service scaling based on load
3. **Multi-Chain Support**: Cross-chain deployment capabilities
4. **AI-Powered Monitoring**: Predictive health monitoring
5. **Compliance Automation**: Automated regulatory compliance

### Integration Capabilities
1. **External APIs**: Third-party service integration
2. **Webhook Support**: Event-driven notifications
3. **SDK Generation**: Auto-generated client libraries
4. **GraphQL Support**: Flexible query interface

## Deployment & Operations

### Upgrade Strategy
- **Stable Variables**: All state preserved during upgrades
- **Version Compatibility**: Backward-compatible API changes
- **Rollback Capability**: Previous version restoration
- **Health Verification**: Post-upgrade health checks

### Monitoring & Alerts
- **Service Health**: Real-time status dashboard
- **Performance Metrics**: Response time tracking
- **Error Rates**: Failure rate monitoring
- **Resource Usage**: Cycles and memory tracking

### Backup & Recovery
- **State Export**: Regular state snapshots
- **Audit Archival**: Long-term audit log storage
- **Configuration Backup**: System config versioning
- **Disaster Recovery**: Multi-region deployment capability

---

*Last Updated: 2024-12-18*
*Version: 2.0.0-MVP* 