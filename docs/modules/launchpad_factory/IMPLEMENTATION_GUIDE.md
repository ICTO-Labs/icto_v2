# Launchpad Factory - Implementation Guide

**Status:** 🚧 In Progress
**Version:** 1.0.0
**Last Updated:** 2025-01-11

---

## 📋 Quick Links

- [Backend Implementation](#backend-implementation) - Motoko code examples
- [Frontend Implementation](#frontend-implementation) - Vue component patterns
- [API Integration](#api-integration) - Service layer patterns
- [Common Tasks](#common-tasks) - Step-by-step guides

---

## Backend Implementation

### 1. Adding Governance Model Types

```motoko
// Types.mo
module Types {

  /// Governance model for post-launch asset management
  public type GovernanceModel = {
    #dao_treasury : {
      dao_canister_id : ?Principal;
      proposal_threshold : Nat;  // Minimum votes for proposal
      voting_period : Nat;       // Voting duration in seconds
      quorum : Nat;              // Minimum participation percentage
    };
    #multisig_wallet : {
      signers : [Principal];
      threshold : Nat;           // Required signatures
      propose_duration : Nat;    // Time window for proposals
    };
    #no_governance;
  };

  /// Launchpad configuration with governance model
  public type LaunchpadConfig = {
    token_name : Text;
    token_symbol : Text;
    token_decimals : Nat8;
    total_supply : Nat;
    soft_cap : Nat;
    hard_cap : Nat;
    token_price_icp : Nat;  // Price per token in e8s
    allocation : Allocation;
    governance_model : GovernanceModel;
    vesting_config : ?VestingConfig;
    dex_config : DexConfig;
  };

  /// Asset distribution configuration
  public type AssetDistribution = {
    team_percentage : Nat;
    marketing_percentage : Nat;
    dex_liquidity_percentage : Nat;
    unallocated_percentage : Nat;
  };
}
```

### 2. Factory Implementation

```motoko
// main.mo
module LaunchpadFactory {

  // Deploy launchpad with governance model
  public shared({caller}) func createLaunchpad(
    config : Types.LaunchpadConfig
  ) : async Result.Result<Principal, Text> {
    // Validate configuration
    switch (validateLaunchpadConfig(config)) {
      case (#ok(validated)) {
        // Deploy governance structure first
        let governance_canister = switch (config.governance_model) {
          case (#dao_treasury dao_config) {
            await deployDaoTreasury(dao_config);
          };
          case (#multisig_wallet multisig_config) {
            await deployMultisigWallet(multisig_config);
          };
          case (#no_governance) null;
        };

        // Deploy launchpad contract
        let launchpad_canister = await deployLaunchpadContract(
          validated,
          governance_canister
        );

        // Update indexes
        launchpadIndex.put(caller, launchpad_canister);

        #ok(launchpad_canister);
      };
      case (#err(error)) {
        #err("Invalid configuration: " # error);
      };
    };
  };

  /// Deploy DAO Treasury contract
  private func deployDaoTreasury(
    config : Types.DaoConfig
  ) : async Principal {
    // Implementation for DAO deployment
    let dao_canister = await DAOFactory.createDAO({
      name = config.name;
      description = config.description;
      token = deployed_token_canister;
      governance_config = {
        proposal_threshold = config.proposal_threshold;
        voting_period = config.voting_period;
        quorum = config.quorum;
      };
    });

    dao_canister
  };

  /// Deploy Multisig Wallet contract
  private func deployMultisigWallet(
    config : Types.MultisigConfig
  ) : async Principal {
    // Implementation for multisig deployment
    let multisig_canister = await MultisigFactory.createMultisig({
      signers = config.signers;
      threshold = config.threshold;
      propose_duration = config.propose_duration;
    });

    multisig_canister
  };
}
```

### 3. Launchpad Contract with Governance Integration

```motoko
// LaunchpadContract.mo
module LaunchpadContract {

  /// Finalize launchpad and distribute assets
  public shared({caller}) func finalizeLaunchpad() : async Result.Result<(), Text> {
    if (is_finalized) {
      return #err("Already finalized");
    };

    if (not reached_soft_cap) {
      return #err("Soft cap not reached");
    };

    // Transfer to governance structure
    switch (governance_model) {
      case (#dao_treasury dao_id) {
        // Transfer tokens to DAO treasury
        let dao_transfer = await TokenContract.transfer({
          to = dao_id;
          amount = governance_tokens;
          from = Principal.fromText(this.canister_id());
        });

        // Transfer ICP to DAO treasury
        let icp_transfer = await ICP Ledger.transfer({
          to = dao_id;
          amount = raised_icp;
          from = Principal.fromText(this.canister_id());
        });
      };
      case (#multisig_wallet multisig_id) {
        // Transfer to multisig wallet
        let token_transfer = await TokenContract.transfer({
          to = multisig_id;
          amount = governance_tokens;
          from = Principal.fromText(this.canister_id());
        });
      };
      case (#no_governance) {
        // Direct distribution to recipients
        await distributeDirectly();
      };
    };

    is_finalized := true;
    #ok(());
  };

  /// Direct distribution without governance
  private func distributeDirectly() : async () {
    // Distribute team tokens
    for (recipient in team_recipients.vals()) {
      await TokenContract.transfer({
        to = recipient.principal;
        amount = recipient.amount;
        from = Principal.fromText(this.canister_id());
      });
    };

    // Distribute marketing tokens
    for (recipient in marketing_recipients.vals()) {
      await TokenContract.transfer({
        to = recipient.principal;
        amount = recipient.amount;
        from = Principal.fromText(this.canister_id());
      });
    };
  };
}
```

---

## Frontend Implementation

### 1. PostLaunchOptions Component

```vue
<template>
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
        Post-Launch Asset Management
      </h3>
      <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
        Configure how remaining assets will be managed after the token sale
      </p>
    </div>

    <!-- Governance Model Selection -->
    <div class="space-y-4">
      <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">
        Governance Model
      </label>

      <!-- DAO Treasury Option -->
      <div
        class="relative rounded-lg border p-4 cursor-pointer transition-colors"
        :class="{
          'border-blue-500 bg-blue-50 dark:bg-blue-900/20': governanceModel === 'dao_treasury',
          'border-gray-200 dark:border-gray-600': governanceModel !== 'dao_treasury'
        }"
        @click="selectGovernanceModel('dao_treasury')"
      >
        <div class="flex items-start">
          <input
            type="radio"
            :checked="governanceModel === 'dao_treasury'"
            class="mt-1 h-4 w-4 text-blue-600 border-gray-300"
            @change="selectGovernanceModel('dao_treasury')"
          />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <Building2 class="h-5 w-5 text-blue-600 mr-2" />
              <h4 class="font-medium text-gray-900 dark:text-white">
                DAO Treasury
              </h4>
            </div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Community-governed treasury with proposal-based voting system
            </p>

            <!-- DAO Configuration -->
            <div v-if="governanceModel === 'dao_treasury'" class="mt-4 space-y-3">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Proposal Threshold (%)
                  </label>
                  <input
                    v-model.number="daoConfig.proposal_threshold"
                    type="number"
                    min="1"
                    max="100"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Quorum (%)
                  </label>
                  <input
                    v-model.number="daoConfig.quorum"
                    type="number"
                    min="1"
                    max="100"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Multisig Wallet Option -->
      <div
        class="relative rounded-lg border p-4 cursor-pointer transition-colors"
        :class="{
          'border-purple-500 bg-purple-50 dark:bg-purple-900/20': governanceModel === 'multisig_wallet',
          'border-gray-200 dark:border-gray-600': governanceModel !== 'multisig_wallet'
        }"
        @click="selectGovernanceModel('multisig_wallet')"
      >
        <div class="flex items-start">
          <input
            type="radio"
            :checked="governanceModel === 'multisig_wallet'"
            class="mt-1 h-4 w-4 text-purple-600 border-gray-300"
            @change="selectGovernanceModel('multisig_wallet')"
          />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <Users class="h-5 w-5 text-purple-600 mr-2" />
              <h4 class="font-medium text-gray-900 dark:text-white">
                Multisig Wallet
              </h4>
            </div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Multi-signature wallet controlled by core team members
            </p>

            <!-- Multisig Configuration -->
            <div v-if="governanceModel === 'multisig_wallet'" class="mt-4 space-y-3">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Threshold (Signatures Required)
                  </label>
                  <input
                    v-model.number="multisigConfig.threshold"
                    type="number"
                    min="2"
                    :max="multisigConfig.signers.length"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                    Proposal Duration (hours)
                  </label>
                  <input
                    v-model.number="multisigConfig.propose_duration"
                    type="number"
                    min="1"
                    max="168"
                    class="w-full px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded"
                  />
                </div>
              </div>

              <!-- Signers Management -->
              <div>
                <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">
                  Signers ({{ multisigConfig.signers.length }}/{{ multisigConfig.threshold }} required)
                </label>
                <RecipientManagement
                  :recipients="multisigSigners"
                  title="Multisig Signers"
                  help-text="Add team members who can authorize transactions"
                  empty-message="At least 2 signers are required"
                  @add-recipient="addSigner"
                  @remove-signer="removeSigner"
                  @update:recipients="updateSigners"
                />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- No Governance Option -->
      <div
        class="relative rounded-lg border p-4 cursor-pointer transition-colors"
        :class="{
          'border-gray-500 bg-gray-50 dark:bg-gray-900/20': governanceModel === 'no_governance',
          'border-gray-200 dark:border-gray-600': governanceModel !== 'no_governance'
        }"
        @click="selectGovernanceModel('no_governance')"
      >
        <div class="flex items-start">
          <input
            type="radio"
            :checked="governanceModel === 'no_governance'"
            class="mt-1 h-4 w-4 text-gray-600 border-gray-300"
            @change="selectGovernanceModel('no_governance')"
          />
          <div class="ml-3 flex-1">
            <div class="flex items-center">
              <Zap class="h-5 w-5 text-gray-600 mr-2" />
              <h4 class="font-medium text-gray-900 dark:text-white">
                No Governance
              </h4>
            </div>
            <p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
              Direct distribution to recipients without additional governance structure
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Asset Distribution Preview -->
    <div v-if="governanceModel !== 'no_governance'" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4">
      <h4 class="font-medium text-gray-900 dark:text-white mb-3">Asset Distribution Preview</h4>
      <div class="space-y-2 text-sm">
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">Team Allocation:</span>
          <span class="font-medium">{{ allocation.team_percentage }}%</span>
        </div>
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">Marketing Allocation:</span>
          <span class="font-medium">{{ allocation.marketing_percentage }}%</span>
        </div>
        <div class="flex justify-between">
          <span class="text-gray-600 dark:text-gray-400">DEX Liquidity:</span>
          <span class="font-medium">{{ allocation.dex_liquidity_percentage }}%</span>
        </div>
        <div class="flex justify-between font-medium pt-2 border-t border-gray-200 dark:border-gray-600">
          <span>{{ governanceModel === 'dao_treasury' ? 'DAO Treasury' : 'Multisig Wallet' }}:</span>
          <span>{{ allocation.unallocated_percentage }}%</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { Building2, Users, Zap } from 'lucide-vue-next'
import RecipientManagement from './RecipientManagement.vue'

interface Props {
  allocation: {
    team_percentage: number
    marketing_percentage: number
    dex_liquidity_percentage: number
    unallocated_percentage: number
  }
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:governance-model': [model: GovernanceModel]
  'update:dao-config': [config: DaoConfig]
  'update:multisig-config': [config: MultisigConfig]
}>()

type GovernanceModel = 'dao_treasury' | 'multisig_wallet' | 'no_governance'

interface DaoConfig {
  proposal_threshold: number
  quorum: number
  voting_period: number
}

interface MultisigConfig {
  signers: Array<{ principal: string; percentage: number; name?: string }>
  threshold: number
  propose_duration: number
}

// State
const governanceModel = ref<GovernanceModel>('no_governance')
const daoConfig = ref<DaoConfig>({
  proposal_threshold: 51,
  quorum: 30,
  voting_period: 7 * 24 * 60 * 60 // 7 days
})

const multisigConfig = ref<MultisigConfig>({
  signers: [],
  threshold: 2,
  propose_duration: 24 * 60 * 60 // 24 hours
})

const multisigSigners = computed({
  get: () => multisigConfig.value.signers.map(signer => ({
    principal: signer.principal,
    percentage: signer.percentage,
    name: signer.name || ''
  })),
  set: (value) => {
    multisigConfig.value.signers = value.map(signer => ({
      principal: signer.principal,
      percentage: signer.percentage,
      name: signer.name
    }))
  }
})

// Methods
const selectGovernanceModel = (model: GovernanceModel) => {
  governanceModel.value = model
  emit('update:governance-model', model)
}

const addSigner = () => {
  multisigSigners.value.push({
    principal: '',
    percentage: 0,
    name: ''
  })
}

const removeSigner = (index: number) => {
  multisigSigners.value.splice(index, 1)
}

const updateSigners = (signers: any[]) => {
  multisigSigners.value = signers
}

// Watch for changes and emit
watch(daoConfig, (newConfig) => {
  emit('update:dao-config', newConfig)
}, { deep: true })

watch(multisigConfig, (newConfig) => {
  emit('update:multisig-config', newConfig)
}, { deep: true })

watch(governanceModel, (newModel) => {
  emit('update:governance-model', newModel)
})
</script>
```

### 2. Integration with LaunchpadCreate.vue

```vue
<!-- LaunchpadCreate.vue - Add Step 4 -->
<script setup lang="ts">
// Add governance model state
const governanceModel = ref<GovernanceModel>('no_governance')
const daoConfig = ref<DaoConfig>({
  proposal_threshold: 51,
  quorum: 30,
  voting_period: 7 * 24 * 60 * 60
})

const multisigConfig = ref<MultisigConfig>({
  signers: [],
  threshold: 2,
  propose_duration: 24 * 60 * 60
})

// Update steps array
const steps = [
  { id: 1, title: 'Token Configuration', icon: Coins },
  { id: 2, title: 'Raised Funds Allocation', icon: PieChart },
  { id: 3, title: 'Vesting Schedule', icon: Clock },
  { id: 4, title: 'DEX Configuration', icon: ArrowUpDown },
  { id: 5, title: 'Post-Launch Options', icon: Settings }, // New step
  { id: 6, title: 'Review & Deploy', icon: Rocket }
]

// Add validation for governance model
const governanceValidation = computed(() => {
  if (governanceModel.value === 'dao_treasury') {
    const issues = []
    if (daoConfig.value.proposal_threshold < 1 || daoConfig.value.proposal_threshold > 100) {
      issues.push('Proposal threshold must be between 1% and 100%')
    }
    if (daoConfig.value.quorum < 1 || daoConfig.value.quorum > 100) {
      issues.push('Quorum must be between 1% and 100%')
    }
    return { valid: issues.length === 0, issues }
  }

  if (governanceModel.value === 'multisig_wallet') {
    const issues = []
    if (multisigConfig.value.signers.length < 2) {
      issues.push('At least 2 signers are required')
    }
    if (multisigConfig.value.threshold < 2 || multisigConfig.value.threshold > multisigConfig.value.signers.length) {
      issues.push('Threshold must be between 2 and total signers')
    }
    return { valid: issues.length === 0, issues }
  }

  return { valid: true, issues: [] }
})

// Update canProceed for Step 5
const canProceed = computed(() => {
  switch (currentStep.value) {
    case 1:
      return tokenValidation.value.valid
    case 2:
      return allocationValidation.value.valid && teamRecipients.value.length > 0
    case 3:
      return !enableVesting.value || vestingValidation.value.valid
    case 4:
      return selectedDexPlatforms.value.length > 0 && dexValidation.value.valid
    case 5: // New governance step
      return governanceValidation.value.valid
    case 6:
      return allValidations.value.valid
    default:
      return true
  }
})
</script>

<template>
  <!-- Add Step 5 in template -->
  <div v-if="currentStep === 5" class="space-y-6">
    <PostLaunchOptions
      :allocation="allocationSummary"
      :governance-model="governanceModel"
      :dao-config="daoConfig"
      :multisig-config="multisigConfig"
      @update:governance-model="governanceModel = $event"
      @update:dao-config="daoConfig = $event"
      @update:multisig-config="multisigConfig = $event"
    />
  </div>
</template>
```

---

## API Integration

### 1. Launchpad Factory Service

```typescript
// services/launchpadFactory.ts
import { Actor, HttpAgent } from '@dfinity/agent'
import { idlFactory } from '@/declarations/launchpad_factory'

export interface LaunchpadConfig {
  token_name: string
  token_symbol: string
  token_decimals: number
  total_supply: bigint
  soft_cap: bigint
  hard_cap: bigint
  token_price_icp: bigint
  allocation: Allocation
  governance_model: GovernanceModel
  vesting_config?: VestingConfig
  dex_config: DexConfig
}

export interface GovernanceModel {
  dao_treasury?: {
    proposal_threshold: number
    voting_period: number
    quorum: number
  }
  multisig_wallet?: {
    signers: string[]
    threshold: number
    propose_duration: number
  }
  no_governance?: null
}

class LaunchpadFactoryService {
  private actor: any

  async initialize() {
    const agent = new HttpAgent({ host: process.env.VUE_APP_IC_HOST })
    this.actor = Actor.createActor(idlFactory, {
      agent,
      canisterId: process.env.VUE_APP_LAUNCHPAD_FACTORY_CANISTER_ID
    })
  }

  async createLaunchpad(config: LaunchpadConfig): Promise<string> {
    const result = await this.actor.createLaunchpad(config)

    if ('err' in result) {
      throw new Error(result.err)
    }

    return result.ok.toText()
  }

  async getLaunchpadList(user: string, limit = 10, offset = 0) {
    const result = await this.actor.getLaunchpadList(user, limit, offset)

    if ('err' in result) {
      throw new Error(result.err)
    }

    return {
      items: result.ok.items.map((launchpad: any) => ({
        ...launchpad,
        created_at: Number(launchpad.created_at),
        total_supply: Number(launchpad.total_supply),
        soft_cap: Number(launchpad.soft_cap),
        hard_cap: Number(launchpad.hard_cap)
      })),
      total: Number(result.ok.total)
    }
  }

  async getLaunchpadDetails(canisterId: string) {
    const result = await this.actor.getLaunchpadDetails(Principal.fromText(canisterId))

    if ('err' in result) {
      throw new Error(result.err)
    }

    return {
      ...result.ok,
      created_at: Number(result.ok.created_at),
      total_supply: Number(result.ok.total_supply),
      soft_cap: Number(result.ok.soft_cap),
      hard_cap: Number(result.ok.hard_cap)
    }
  }
}

export const launchpadFactoryService = new LaunchpadFactoryService()
```

### 2. DAO Factory Service

```typescript
// services/daoFactory.ts
import { Actor, HttpAgent } from '@dfinity/agent'
import { idlFactory } from '@/declarations/dao_factory'

export interface DAOConfig {
  name: string
  description: string
  token: string
  governance_config: {
    proposal_threshold: number
    voting_period: number
    quorum: number
  }
}

class DAOFactoryService {
  private actor: any

  async initialize() {
    const agent = new HttpAgent({ host: process.env.VUE_APP_IC_HOST })
    this.actor = Actor.createActor(idlFactory, {
      agent,
      canisterId: process.env.VUE_APP_DAO_FACTORY_CANISTER_ID
    })
  }

  async createDAO(config: DAOConfig): Promise<string> {
    const result = await this.actor.createDAO(config)

    if ('err' in result) {
      throw new Error(result.err)
    }

    return result.ok.toText()
  }

  async getDAOList(user: string, limit = 10, offset = 0) {
    const result = await this.actor.getDAOList(user, limit, offset)

    if ('err' in result) {
      throw new Error(result.err)
    }

    return {
      items: result.ok.items,
      total: Number(result.ok.total)
    }
  }
}

export const daoFactoryService = new DAOFactoryService()
```

---

## Common Tasks

### Task: Add New Governance Model

**Steps:**

1. **Update Backend Types** (`Types.mo`):
   ```motoko
   public type GovernanceModel = {
     // ... existing models
     #new_model : {
       // configuration parameters
     };
   };
   ```

2. **Update Factory Logic** (`main.mo`):
   ```motoko
   let governance_canister = switch (config.governance_model) {
     // ... existing cases
     case (#new_model new_config) {
       await deployNewModel(new_config);
     };
   };
   ```

3. **Update Frontend Component** (`PostLaunchOptions.vue`):
   ```vue
   <!-- Add new option card -->
   <div @click="selectGovernanceModel('new_model')">
     <!-- New model UI -->
   </div>
   ```

4. **Update API Services** (`launchpadFactory.ts`):
   ```typescript
   export interface GovernanceModel {
     // ... existing models
     new_model?: {
       // configuration parameters
     }
   }
   ```

### Task: Add Validation for Governance Configuration

**Steps:**

1. **Add Backend Validation**:
   ```motoko
   private func validateGovernanceModel(model : Types.GovernanceModel) : Result.Result<Types.GovernanceModel, Text> {
     switch (model) {
       case (#dao_treasury dao_config) {
         if (dao_config.proposal_threshold < 1 or dao_config.proposal_threshold > 100) {
           return #err("Invalid proposal threshold");
         };
         // ... other validations
       };
       case (#multisig_wallet multisig_config) {
         if (multisig_config.signers.size() < 2) {
           return #err("At least 2 signers required");
         };
         // ... other validations
       };
     };
     #ok(model);
   };
   ```

2. **Add Frontend Validation**:
   ```typescript
   const governanceValidation = computed(() => {
     const issues = []

     if (governanceModel.value === 'dao_treasury') {
       if (daoConfig.value.proposal_threshold < 1 || daoConfig.value.proposal_threshold > 100) {
         issues.push('Proposal threshold must be between 1% and 100%')
       }
     }

     return {
       valid: issues.length === 0,
       issues
     }
   })
   ```

### Task: Add Asset Transfer Functionality

**Steps:**

1. **Backend Transfer Logic**:
   ```motoko
   public shared({caller}) func transferToGovernance(
     amount : Nat,
     to_governance : Principal
   ) : async Result.Result<(), Text> {
     if (not is_finalized) {
       return #err("Launchpad not finalized");
     };

     let transfer_result = await TokenContract.transfer({
       to = to_governance;
       amount = amount;
       from = Principal.fromText(this.canister_id());
     });

     switch (transfer_result) {
       case (#ok(_)) #ok(());
       case (#err(error)) #err("Transfer failed: " # error);
     };
   };
   ```

2. **Frontend Transfer UI**:
   ```vue
   <template>
     <div class="bg-white dark:bg-gray-800 rounded-lg p-6">
       <h3 class="text-lg font-semibold mb-4">Transfer to Governance</h3>
       <div class="space-y-4">
         <div>
           <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
             Amount (tokens)
           </label>
           <input
             v-model.number="transferAmount"
             type="number"
             class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded"
           />
         </div>
         <button
           @click="handleTransfer"
           class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
         >
           Transfer
         </button>
       </div>
     </div>
   </template>
   ```

### Task: Add Governance Proposal System

**Steps:**

1. **Create Proposal Types**:
   ```motoko
   public type Proposal = {
     id : Nat;
     proposer : Principal;
     title : Text;
     description : Text;
     type : ProposalType;
     votes_for : Nat;
     votes_against : Nat;
     end_time : Time.Time;
     executed : Bool;
   };

   public type ProposalType = {
     #transfer_tokens : { to : Principal; amount : Nat };
     #update_config : { field : Text; value : Text };
     #upgrade_contract : { new_wasm : [Nat8] };
   };
   ```

2. **Implement Proposal Functions**:
   ```motoko
   public shared({caller}) func createProposal(
     title : Text,
     description : Text,
     proposal_type : ProposalType
   ) : async Result.Result<Nat, Text> {
     // Implementation
   };

   public shared({caller}) func vote(
     proposal_id : Nat,
     vote_for : Bool
   ) : async Result.Result<(), Text> {
     // Implementation
   };
   ```

3. **Frontend Proposal Interface**:
   ```vue
   <template>
     <div class="space-y-6">
       <div class="bg-white dark:bg-gray-800 rounded-lg p-6">
         <h3 class="text-lg font-semibold mb-4">Create Proposal</h3>
         <form @submit.prevent="createProposal" class="space-y-4">
           <div>
             <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
               Title
             </label>
             <input
               v-model="proposal.title"
               type="text"
               class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded"
               required
             />
           </div>
           <div>
             <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
               Description
             </label>
             <textarea
               v-model="proposal.description"
               rows="3"
               class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded"
               required
             />
           </div>
           <button
             type="submit"
             class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
           >
             Create Proposal
           </button>
         </form>
       </div>
     </div>
   </template>
   ```

---

## Testing

### Backend Tests

```motoko
// test/launchpad_factory.test.mo
import Test "mo:base/Testing";
import LaunchpadFactory "../src/motoko/launchpad_factory/main";

let factory = LaunchpadFactory.LaunchpadFactory();

test("create launchpad with DAO governance") {
  let config = {
    token_name = "Test Token";
    token_symbol = "TEST";
    token_decimals = 8;
    total_supply = 1_000_000_000;
    soft_cap = 100_000_000;
    hard_cap = 500_000_000;
    token_price_icp = 1_000;
    allocation = {
      team_percentage = 70;
      marketing_percentage = 20;
      dex_liquidity_percentage = 10;
      unallocated_percentage = 0;
    };
    governance_model = #dao_treasury {
      proposal_threshold = 51;
      voting_period = 7 * 24 * 60 * 60;
      quorum = 30;
    };
    vesting_config = null;
    dex_config = {
      platforms = [#icpswap];
      allocation_method = #percentage_based;
    };
  };

  let result = await factory.createLaunchpad(config);
  assert (Result.isOk(result));
};
```

### Frontend Tests

```typescript
// __tests__/PostLaunchOptions.spec.ts
import { mount } from '@vue/test-utils'
import { describe, it, expect } from 'vitest'
import PostLaunchOptions from '@/components/launchpad/PostLaunchOptions.vue'

describe('PostLaunchOptions', () => {
  it('renders governance model options', () => {
    const wrapper = mount(PostLaunchOptions, {
      props: {
        allocation: {
          team_percentage: 70,
          marketing_percentage: 20,
          dex_liquidity_percentage: 10,
          unallocated_percentage: 0
        }
      }
    })

    expect(wrapper.text()).toContain('Post-Launch Asset Management')
    expect(wrapper.text()).toContain('DAO Treasury')
    expect(wrapper.text()).toContain('Multisig Wallet')
    expect(wrapper.text()).toContain('No Governance')
  })

  it('emits governance model selection', async () => {
    const wrapper = mount(PostLaunchOptions, {
      props: {
        allocation: {
          team_percentage: 70,
          marketing_percentage: 20,
          dex_liquidity_percentage: 10,
          unallocated_percentage: 0
        }
      }
    })

    await wrapper.find('[data-testid="dao-treasury-option"]').trigger('click')

    expect(wrapper.emitted('update:governance-model')).toBeTruthy()
    expect(wrapper.emitted('update:governance-model')[0]).toEqual(['dao_treasury'])
  })
})
```

---

## Security Considerations

### 1. Access Control

```motoko
// Ensure only authorized users can create launchpads
if (not isAuthorizedCreator(caller)) {
  return #err("Unauthorized");
};

// Validate governance configuration
private func validateGovernanceConfig(config : Types.GovernanceModel) : Result.Result<(), Text> {
  switch (config) {
    case (#multisig_wallet multisig) {
      if (multisig.threshold < 2) {
        return #err("Threshold too low");
      };
      if (multisig.threshold > multisig.signers.size()) {
        return #err("Threshold exceeds signers");
      };
    };
    case (#dao_treasury dao) {
      if (dao.proposal_threshold > 100) {
        return #err("Invalid threshold");
      };
    };
  };
  #ok(())
};
```

### 2. Asset Security

```motoko
// Secure asset transfers
public shared({caller}) func finalizeLaunchpad() : async Result.Result<(), Text> {
  // Ensure only creator can finalize
  if (caller != creator) {
    return #err("Unauthorized");
  };

  // Ensure soft cap is reached
  if (not reached_soft_cap) {
    return #err("Soft cap not reached");
  };

  // Secure transfer to governance structure
  let transfer_result = await secureTransferToGovernance();

  switch (transfer_result) {
    case (#ok(_)) {
      is_finalized := true;
      #ok(());
    };
    case (#err(error)) {
      #err("Transfer failed: " # error);
    };
  };
};
```

---

## Performance Optimization

### 1. Batch Operations

```motoko
// Batch multiple transfers for efficiency
public shared({caller}) func batchTransfer(
  transfers : [(Principal, Nat)]
) : async Result.Result<(), Text> {
  let batch_size = 10;
  let batches = Array.chunks(transfers, batch_size);

  for (batch in batches.vals()) {
    let results = await* Array.map(batch, func((to, amount)) {
      TokenContract.transfer({ to; amount; from = Principal.fromText(this.canister_id()) })
    });

    // Check if any transfer failed
    for (result in results.vals()) {
      switch (result) {
        case (#err(_)) return #err("Batch transfer failed");
        case (#ok(_)) {};
      };
    };
  };

  #ok(());
};
```

### 2. Caching Strategy

```typescript
// Cache governance configurations
const governanceConfigCache = new Map<string, GovernanceConfig>()

export async function getGovernanceConfig(canisterId: string): Promise<GovernanceConfig> {
  const cached = governanceConfigCache.get(canisterId)
  if (cached && Date.now() - cached.timestamp < 5 * 60 * 1000) { // 5 minutes
    return cached.config
  }

  const config = await governanceService.getConfig(canisterId)
  governanceConfigCache.set(canisterId, {
    config,
    timestamp: Date.now()
  })

  return config
}
```

---

## Migration Guide

### From No Governance to DAO Treasury

1. **Prepare Migration Proposal**:
   ```motoko
   public shared({caller}) func proposeDAOMigration(
     dao_config : Types.DaoConfig
   ) : async Result.Result<Nat, Text> {
     // Create proposal to migrate to DAO
   };
   ```

2. **Execute Migration**:
   ```motoko
   public shared({caller}) func executeDAOMigration(
     proposal_id : Nat
   ) : async Result.Result<(), Text> {
     // Check if proposal passed
     if (not proposalPassed(proposal_id)) {
       return #err("Proposal not passed");
     };

     // Deploy DAO contract
     let dao_canister = await deployDaoTreasury(dao_config);

     // Transfer assets to DAO
     await transferAssetsToDAO(dao_canister);

     // Update governance model
     governance_model := #dao_treasury dao_config;

     #ok(());
   };
   ```

3. **Frontend Migration Interface**:
   ```vue
   <template>
     <div class="bg-white dark:bg-gray-800 rounded-lg p-6">
       <h3 class="text-lg font-semibold mb-4">Migrate to DAO Treasury</h3>
       <div class="space-y-4">
         <p class="text-sm text-gray-600 dark:text-gray-400">
           This will create a DAO treasury and transfer all assets to it.
         </p>
         <button
           @click="handleMigration"
           class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
         >
           Start Migration
         </button>
       </div>
     </div>
   </template>
   ```

---

This implementation guide provides comprehensive patterns for implementing governance model selection in the Launchpad Factory. It includes both backend Motoko code and frontend Vue components, following the established patterns from the codebase.