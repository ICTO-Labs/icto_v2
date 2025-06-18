# 🏗️ ICTO V2 Architecture - MVP Structure

## 📁 Complete Directory Structure

```
src/motoko/
├── backend/                           # Central Orchestrator
│   ├── main.mo                       # Main backend actor (public APIs)
│   ├── Dispatcher.mo                 # Request routing & service coordination
│   ├── types/
│   │   ├── Core.mo                   # Core types (Project, Pipeline, etc.)
│   │   ├── Requests.mo               # API request/response types  
│   │   └── Services.mo               # Service interface types
│   ├── modules/
│   │   ├── PipelineEngine.mo         # Workflow execution engine
│   │   ├── FeeValidator.mo           # Fee validation & payment processing
│   │   ├── ProjectManager.mo         # Project lifecycle management
│   │   └── AuditLogger.mo            # Logging & monitoring
│   └── interfaces/
│       ├── ITokenDeployer.mo         # Token service interface
│       ├── ILockDeployer.mo          # Lock service interface
│       ├── IDistributor.mo           # Distribution service interface
│       └── ILaunchpad.mo             # Launchpad service interface
├── services/                          # Shared Services & Utils
│   ├── Invoice.mo                    # Fee payment processing
│   ├── Registry.mo                   # Service discovery & registration
│   ├── Cycles.mo                     # Cycles management utilities
│   └── Utils.mo                      # Common helper functions
├── shared/                           # Shared Types & Logic
│   ├── types/
│   │   ├── Common.mo                 # Common types across all services
│   │   ├── Token.mo                  # Token-related types (ICRC standards)
│   │   ├── Vesting.mo                # Vesting & lock types
│   │   └── Governance.mo             # DAO & governance types
│   ├── utils/
│   │   ├── IC.mo                     # IC management interface
│   │   ├── Time.mo                   # Time utilities
│   │   ├── Math.mo                   # Mathematical calculations
│   │   └── Validation.mo             # Input validation helpers
│   └── constants/
│       ├── Errors.mo                 # Error messages & codes
│       └── Config.mo                 # System configuration constants
├── token_deployer/                   # Token Creation Service
│   ├── main.mo                       # Token deployer actor
│   ├── TokenFactory.mo               # Token creation logic
│   ├── templates/
│   │   ├── ICRC1Token.mo            # ICRC-1 token template
│   │   ├── ICRC2Token.mo            # ICRC-2 token template
│   │   └── CustomToken.mo           # Custom token template
│   └── types/
│       └── TokenDeployer.mo         # Token deployer specific types
├── lock_deployer/                    # Vesting & Lock Service
│   ├── main.mo                       # Lock deployer actor
│   ├── LockFactory.mo                # Lock contract creation logic
│   ├── VestingEngine.mo              # Vesting calculation engine
│   ├── templates/
│   │   ├── TimeLock.mo              # Time-based lock template
│   │   ├── VestingLock.mo           # Vesting schedule template
│   │   └── TeamLock.mo              # Team token lock template
│   └── types/
│       └── LockDeployer.mo          # Lock deployer specific types
├── distributing_deployer/            # Distribution Service
│   ├── main.mo                       # Distribution deployer actor
│   ├── DistributionFactory.mo        # Distribution contract creation
│   ├── AirdropEngine.mo              # Airdrop logic
│   ├── templates/
│   │   ├── PublicDistribution.mo    # Public distribution template
│   │   ├── WhitelistDistribution.mo # Whitelist distribution template
│   │   └── AirdropDistribution.mo   # Airdrop distribution template
│   └── types/
│       └── DistributionDeployer.mo  # Distribution specific types
└── launchpad/                        # Launchpad & DAO Service
    ├── main.mo                       # Launchpad deployer actor
    ├── LaunchpadFactory.mo           # Launchpad creation logic
    ├── templates/
    │   ├── LaunchpadTemplate.mo      # Main launchpad template
    │   ├── DAOTemplate.mo            # DAO governance template
    │   ├── VotingTemplate.mo         # Voting mechanism template
    │   └── TreasuryTemplate.mo       # Treasury management template
    └── types/
        └── LaunchpadDeployer.mo      # Launchpad specific types
```

## 🔄 Service Interaction Flow

### 1. Independent Module Calls
```motoko
// Direct service calls from backend
let tokenDeployer = actor("token-deployer-id") : ITokenDeployer.Self;
let result = await tokenDeployer.createToken(tokenConfig);
```

### 2. Pipeline-Based Orchestration
```motoko
// Full project launch pipeline
let pipeline = PipelineEngine.createLaunchPipeline({
  steps = [
    #ValidateFee,
    #CreateToken,
    #SetupTeamLock,
    #CreateDistribution,
    #LaunchDAO,
    #TransferOwnership
  ];
  config = projectConfig;
});
await PipelineEngine.execute(pipeline);
```

## 🎯 MVP Service Capabilities

### Backend (Central Orchestrator)
- ✅ Request routing & validation
- ✅ Fee processing & validation
- ✅ Pipeline execution engine
- ✅ Project lifecycle management
- ✅ Audit logging & monitoring

### Token Deployer Service
- ✅ ICRC-1/2 token creation
- ✅ Custom token parameters
- ✅ Ownership transfer to user
- ✅ Integration with IC ledger standards

### Lock Deployer Service  
- ✅ Time-based token locks
- ✅ Vesting schedule creation
- ✅ Team token vesting
- ✅ Release schedule management

### Distribution Deployer Service
- ✅ Public token distribution
- ✅ Whitelist-based distribution
- ✅ Airdrop campaigns
- ✅ Multi-recipient batch processing

### Launchpad Service
- ✅ Project launchpad creation
- ✅ DAO governance setup
- ✅ Voting mechanism implementation
- ✅ Treasury management basics

## 🔧 Key Architecture Patterns

### 1. Actor-Based Services
Each service is an independent actor that can be called directly or through pipelines.

### 2. Template-Based Deployment
All deployed contracts use standardized templates with configurable parameters.

### 3. Interface-Driven Design
All services implement well-defined interfaces for consistent interaction.

### 4. Fee-First Validation
Every operation validates payment before execution through Invoice service.

### 5. Ownership Model
- Backend orchestrates but doesn't hold custody
- All deployed contracts owned by user principals
- Clear ownership transfer mechanisms

## 📊 Data Flow Examples

### Simple Token Creation
```
Frontend → Backend → Fee Validation → Token Deployer → User Owns Token
```

### Full Project Launch
```
Frontend → Backend → Pipeline Engine
                  ↓
        [Fee Validation] → [Token Creation] → [Team Lock] 
                  ↓              ↓              ↓
        [Distribution Setup] → [DAO Creation] → [Ownership Transfer]
                  ↓
        [Audit Logging] → [Project Complete]
```

## 🚀 MVP Deployment Strategy

### Phase 1: Core Backend + Token Service
- Backend with basic routing
- Token deployer with ICRC templates
- Fee validation system

### Phase 2: Distribution + Lock Services
- Lock deployer with vesting
- Distribution deployer with airdrop
- Pipeline engine basic implementation

### Phase 3: Launchpad + DAO
- Launchpad service
- DAO template system
- Full pipeline orchestration

### Phase 4: Polish + Optimization
- Advanced error handling
- Performance optimization
- Frontend integration testing 