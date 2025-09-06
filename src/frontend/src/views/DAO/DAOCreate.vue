<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center space-x-3 mb-4">
        <button @click="$router.go(-1)" class="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors">
          <ArrowLeftIcon class="h-5 w-5 text-gray-500" />
        </button>
        <div class="p-2 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg">
          <Building2Icon class="h-6 w-6 text-white" />
        </div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-900 via-amber-700 to-yellow-600 dark:from-white dark:via-yellow-400 dark:to-amber-300 bg-clip-text text-transparent">
          Create New miniDAO
        </h1>
      </div>
      <p class="text-gray-600 dark:text-gray-400 max-w-2xl">
        Build a decentralized autonomous organization with advanced governance features, token management, and community engagement tools.
      </p>
    </div>

    <!-- Progress Steps -->
    <div class="mb-8">
      <div class="flex items-center justify-between mb-4">
        <div 
          v-for="(step, index) in steps" 
          :key="step.id"
          class="flex items-center"
          :class="{ 'flex-1': index < steps.length - 1 }"
        >
          <!-- Step Circle -->
          <div class="flex items-center space-x-3">
            <div 
              :class="[
                'w-10 h-10 rounded-full flex items-center justify-center border-2 transition-all duration-300',
                currentStep >= index 
                  ? 'bg-gradient-to-r from-yellow-500 to-amber-500 border-yellow-500 text-white shadow-lg' 
                  : 'border-gray-300 dark:border-gray-600 text-gray-500 dark:text-gray-400'
              ]"
            >
              <CheckIcon v-if="currentStep > index" class="h-5 w-5" />
              <span v-else class="font-semibold">{{ index + 1 }}</span>
            </div>
            <div :class="currentStep >= index ? 'text-yellow-700 dark:text-yellow-300' : 'text-gray-500 dark:text-gray-400'">
              <div class="font-medium">{{ step.title }}</div>
              <div class="text-sm">{{ step.description }}</div>
            </div>
          </div>
          
          <!-- Progress Line -->
          <div 
            v-if="index < steps.length - 1"
            :class="[
              'flex-1 h-1 mx-6 rounded-full transition-all duration-300',
              currentStep > index 
                ? 'bg-gradient-to-r from-yellow-500 to-amber-500' 
                : 'bg-gray-200 dark:bg-gray-700'
            ]"
          ></div>
        </div>
      </div>
    </div>

    <!-- Form Card -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
      <!-- Step 1: Basic Information -->
      <div v-if="currentStep === 0" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Basic Information</h2>
        
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">DAO Name*</label>
            <input
              v-model="formData.name"
              type="text"
              placeholder="Enter your DAO name"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Description* <small>Markdown is supported</small></label>
            <textarea
              v-model="formData.description"
              rows="3"
              placeholder="Describe your DAO's purpose and goals"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            ></textarea>
          </div>

          <div class="md:col-span-2">
            <TokenSelector
              v-model="formData.tokenCanisterId"
              label="Token Canister ID*"
              placeholder="rdmx6-jaaaa-aaaaa-aaadq-cai"
              help-text="The ICRC token you want to use for this DAO"
              required
              @token-fetched="handleTokenFetched"
              @error="handleTokenError"
            />
          </div>


          <!-- NEW: Governance Level Selector -->
          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Governance Level*</label>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div 
                v-for="option in getGovernanceLevelOptions()" 
                :key="option.value"
                @click="formData.governanceLevel = option.value"
                :class="[
                  'cursor-pointer border-2 rounded-lg p-4 transition-all duration-200',
                  formData.governanceLevel === option.value
                    ? 'border-yellow-500 bg-yellow-50 dark:bg-yellow-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:border-yellow-300'
                ]"
              >
                <div class="flex items-center mb-2">
                  <input 
                    type="radio" 
                    :value="option.value"
                    v-model="formData.governanceLevel"
                    :id="option.value"
                    class="w-4 h-4 text-yellow-600 focus:ring-yellow-500"
                  />
                  <label :for="option.value" class="ml-2 font-medium text-gray-900 dark:text-white cursor-pointer">
                    {{ option.label }}
                  </label>
                </div>
                <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">{{ option.subtitle }}</p>
                <p class="text-xs text-gray-500 dark:text-gray-500">{{ option.description }}</p>
                
                <!-- Capability indicators -->
                <div class="mt-3 flex flex-wrap gap-1">
                  <span 
                    v-for="pro in option.pros" 
                    :key="pro"
                    class="inline-flex items-center px-2 py-1 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                  >
                    {{ pro }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Governance Level Info -->
            <div class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
              <div class="flex items-center mb-2">
                <InfoIcon class="h-5 w-5 text-blue-500 mr-2" />
                <h4 class="font-medium text-blue-800 dark:text-blue-200">{{ currentGovernanceCapabilities.description }}</h4>
              </div>
              <p class="text-sm text-blue-600 dark:text-blue-300 mb-2">
                <strong>Token Ownership:</strong> {{ currentGovernanceCapabilities.tokenOwnership }}
              </p>
              <p class="text-sm text-blue-600 dark:text-blue-300">
                <strong>Available Proposal Types:</strong> {{ currentGovernanceCapabilities.allowedProposalTypes.join(', ') }}
              </p>
              
              <!-- Warning for fully-managed -->
              <div v-if="requiresTokenOwnership" class="mt-3 p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
                <div class="flex items-center">
                  <AlertCircleIcon class="h-5 w-5 text-yellow-500 mr-2" />
                  <p class="text-sm text-yellow-700 dark:text-yellow-300">
                    <strong>Important:</strong> This option requires transferring token ownership to the DAO. This cannot be undone.
                  </p>
                </div>
              </div>
            </div>
          </div>

          <div class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Tags</label>
            <input
              v-model="tagsInput"
              type="text"
              placeholder="defi, governance, community (separate with commas)"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
            <div v-if="formData.tags.length > 0" class="flex flex-wrap gap-2 mt-2">
              <span 
                v-for="tag in formData.tags" 
                :key="tag"
                class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
              >
                {{ tag }}
                <button @click="removeTag(tag)" class="ml-1 text-yellow-600 hover:text-yellow-800">
                  <XIcon class="h-3 w-3" />
                </button>
              </span>
            </div>
          </div>

          <!-- Validation Errors Display -->
          <div v-if="!validationErrors.valid && validationErrors.errors.length > 0" class="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <div class="flex items-start">
              <AlertCircleIcon class="h-5 w-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" />
              <div>
                <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please follow the instructions:</h4>
                <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                  <li v-for="error in validationErrors.errors" :key="error" class="flex items-center">
                    <span class="w-2 h-2 bg-red-400 rounded-full mr-2"></span>
                    {{ error }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
          
        </div>
      </div>

      <!-- Step 2: Governance Settings -->
      <div v-else-if="currentStep === 1" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Governance Settings</h2>
      
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Minimum Stake (tokens)*</label>
            <input
              v-model="formData.minimumStake"
              type="number"
              placeholder="100"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Minimum tokens required to participate</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Proposal Threshold (voting power)*</label>
            <input
              v-model="formData.proposalThreshold"
              type="number"
              placeholder="1000"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Minimum voting power required to create proposals (no tokens consumed)</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Proposal Submission Deposit (tokens)*</label>
            <input
              v-model="formData.proposalSubmissionDeposit"
              type="number"
              placeholder="10"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Tokens locked when creating proposal (returned if proposal passes or meets threshold)</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Quorum Percentage (%)*</label>
            <input
              v-model="formData.quorumPercentage"
              type="number"
              min="1"
              max="100"
              placeholder="20"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Minimum participation required</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Approval Threshold (%)*</label>
            <input
              v-model="formData.approvalThreshold"
              type="number"
              min="1"
              max="100"
              placeholder="50"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Percentage needed for approval</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Voting Period (days)*</label>
            <input
              v-model="votingPeriodDays"
              type="number"
              placeholder="7"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">How long voting remains open</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Timelock Duration (days)*</label>
            <input
              v-model="timelockDays"
              type="number"
              placeholder="2"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Delay before proposal execution</p>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Voting Power Model*</label>
            <Select
              v-model="formData.votingPowerModel"
              :options="[{label: 'Equal (1 person = 1 vote)', value: 'equal'}, {label: 'Proportional (tokens = voting power)', value: 'proportional'}, {label: 'Quadratic (sqrt of tokens)', value: 'quadratic'}]"
              placeholder="Choose an option"
              size="lg"
            />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Transfer Fee (tokens)*</label>
            <input
              v-model="formData.transferFee"
              type="number"
              placeholder="0.0001"
              step="0.0001"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Fee for internal token transfers</p>
          </div>

          <div class="md:col-span-2">
            <div class="flex items-center space-x-3">
              <input
                v-model="formData.enableDelegation"
                type="checkbox"
                class="w-4 h-4 text-yellow-600 bg-white border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300">Enable Vote Delegation</label>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Allow members to delegate their voting power to others</p>
          </div>
        </div>

        <!-- Validation Errors Display -->
        <div v-if="!validationErrors.valid && validationErrors.errors.length > 0" class="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start">
            <AlertCircleIcon class="h-5 w-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" />
            <div>
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please follow the instructions:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="error in validationErrors.errors" :key="error" class="flex items-center">
                  <span class="w-2 h-2 bg-red-400 rounded-full mr-2"></span>
                  {{ error }}
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 3: Staking & Security -->
      <div v-else-if="currentStep === 2" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Staking & Security</h2>
      
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Voting Power Model -->
          <div class="md:col-span-2 mb-6">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Voting Power Model*</label>
            <Select
              v-model="formData.votingPowerModel"
              :options="[{label: 'Equal (1 person = 1 vote)', value: 'equal'}, {label: 'Proportional (tokens = voting power)', value: 'proportional'}, {label: 'Quadratic (sqrt of tokens)', value: 'quadratic'}]"
              placeholder="Choose voting power calculation"
            />
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">How voting power is calculated from token holdings</p>
          </div>

          <!-- Custom Tier Manager Integration -->
          <div class="md:col-span-2">
            <CustomTierManager 
              v-model="customTiers"
              @tier-config-changed="onTierConfigChanged"
              @validation-changed="onTierValidationChanged"
            />
          </div>

          <!-- Distribution Contract Manager Integration -->
          <div class="md:col-span-2 mt-8 border-t border-gray-200 dark:border-gray-700 pt-6">
            <DistributionContractManager 
              v-model="formData.distributionContracts"
              @validation-changed="onDistributionValidationChanged"
            />
          </div>

          <div class="md:col-span-2">
            <div class="flex items-center space-x-3 mb-4">
              <input
                id="emergencyPauseEnabled"
                v-model="formData.emergencyPauseEnabled"
                type="checkbox"
                class="w-4 h-4 text-yellow-600 bg-white border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
              <label class="text-sm font-medium text-gray-700 dark:text-gray-300" for="emergencyPauseEnabled" >Enable Emergency Pause</label>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400">Allow designated contacts to pause DAO operations in emergencies</p>
          </div>

          <div v-if="formData.emergencyPauseEnabled" class="md:col-span-2">
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Emergency Contacts</label>
            <div class="space-y-2">
              <div v-for="(contact, index) in formData.emergencyContacts" :key="index" class="flex items-center justify-between">
                <input
                v-model="formData.emergencyContacts[index]"
                type="text"
                placeholder="Principal ID"
                class="w-full text-sm px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <button
                @click="formData.emergencyContacts.splice(index, 1)"
                type="button"
                class="p-2 ml-2 text-red-600 px-3 py-3 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                title="Remove contact"
              >
                <XIcon class="h-4 w-4" />
              </button>
              </div>
              
              <button 
                @click="addEmergencyContact"
                class="text-sm text-yellow-600 hover:text-yellow-700 dark:text-yellow-400 dark:hover:text-yellow-300"
              >
                + Add Contact
              </button>
            </div>
          </div>

          <!-- DAO Token Management - Now derived from Governance Level -->
          <!-- <div class="md:col-span-2">
            <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
              <div class="flex items-center justify-between mb-2">
                <h4 class="text-sm font-medium text-gray-900 dark:text-white">Token Management Rights</h4>
                <span class="text-xs px-2 py-1 rounded-full" 
                      :class="formData.managedByDAO ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' : 'bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200'">
                  {{ formData.managedByDAO ? 'Enabled' : 'Disabled' }}
                </span>
              </div>
              <p class="text-xs text-gray-600 dark:text-gray-400">
                <strong>{{ currentGovernanceCapabilities.tokenOwnership }}</strong>
              </p>
              <p class="text-xs text-gray-500 dark:text-gray-500 mt-1">
                Based on your Governance Level selection. Can be upgraded later through proposals.
              </p>
              
              <div class="mt-3 pt-3 border-t border-gray-200 dark:border-gray-600">
                <p class="text-xs text-blue-600 dark:text-blue-400">
                  <strong>Future SNS Integration:</strong> When ICTO joins SNS, the hierarchy will be: 
                  <span class="font-mono">SNS DAO → ICTO Foundation → Factory → miniDAOs</span>
                </p>
              </div>
            </div>
          </div> -->

          <!-- Custom Security Settings -->
          <div class="md:col-span-2 mt-8 border-t border-gray-200 dark:border-gray-700 pt-6">
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium text-gray-900 dark:text-white">Advanced Security Settings</h3>
              <button
                @click="showAdvancedSecurity = !showAdvancedSecurity"
                class="text-sm text-yellow-600 hover:text-yellow-700 dark:text-yellow-400 dark:hover:text-yellow-300"
              >
                {{ showAdvancedSecurity ? 'Hide' : 'Show' }} Advanced Options
              </button>
            </div>
            
            <div v-if="showAdvancedSecurity" class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Min Stake Amount (optional)</label>
                <input
                  v-model="customSecurity.minStakeAmount"
                  type="number"
                  placeholder="1000"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Minimum tokens required to stake (overrides default)</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Max Stake Amount (optional)</label>
                <input
                  v-model="customSecurity.maxStakeAmount"
                  type="number"
                  placeholder="1000000"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Maximum tokens allowed to stake per user</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Min Proposal Deposit (optional)</label>
                <input
                  v-model="customSecurity.minProposalDeposit"
                  type="number"
                  placeholder="10"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Minimum deposit required for proposals</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Max Proposal Deposit (optional)</label>
                <input
                  v-model="customSecurity.maxProposalDeposit"
                  type="number"
                  placeholder="100000"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Maximum deposit allowed for proposals</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Max Proposals/Hour (optional)</label>
                <input
                  v-model="customSecurity.maxProposalsPerHour"
                  type="number"
                  min="1"
                  max="100"
                  placeholder="3"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Rate limit for proposal creation per hour</p>
              </div>

              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Max Proposals/Day (optional)</label>
                <input
                  v-model="customSecurity.maxProposalsPerDay"
                  type="number"
                  min="1"
                  max="1000"
                  placeholder="1000"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">Daily rate limit for proposal creation</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Validation Errors Display -->
        <div v-if="!validationErrors.valid && validationErrors.errors.length > 0" class="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start">
            <AlertCircleIcon class="h-5 w-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" />
            <div>
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please follow the instructions:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="error in validationErrors.errors" :key="error" class="flex items-center">
                  <span class="w-2 h-2 bg-red-400 rounded-full mr-2"></span>
                  {{ error }}
                </li>
              </ul>
            </div>
          </div>
        </div>

      </div>

      <!-- Step 4: Review & Deploy -->
      <div v-else-if="currentStep === 3" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Review & Deploy</h2>
        
        
        <div class="space-y-6">
          <!-- Summary Cards -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
              <h3 class="font-medium text-gray-900 dark:text-white mb-2">Basic Info</h3>
              <div class="text-sm space-y-1">
                <p><span class="text-gray-500">Name:</span> {{ formData.name }}</p>
                <p><span class="text-gray-500">Voting Model:</span> {{ formData.votingPowerModel }}</p>
                <p><span class="text-gray-500 mr-2">Governance Level:</span> 
                  <span class="inline-flex items-center px-2 py-1 rounded text-xs font-medium"
                        :class="formData.governanceLevel === 'motion-only' ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' :
                               formData.governanceLevel === 'semi-managed' ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200' :
                               'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'">
                    {{ getGovernanceLevelOptions().find(o => o.value === formData.governanceLevel)?.label }}
                  </span>
                </p>
                <p><span class="text-gray-500 mr-2">Public:</span>{{ formData.isPublic ? 'Yes' : 'No' }}</p>
                <p><span class="text-gray-500 mr-2">Staking System:</span> 
                  <span class="text-green-600  mr-2">Custom Multiplier Tiers</span>
                  <span class="text-xs text-gray-400  mr-2">({{ customTiers.length }} tiers configured)</span>
                </p>
                <p><span class="text-gray-500  mr-2">Security Level:</span> 
                  <span :class="{
                    'text-green-600': tierSecurityScore >= 80,
                    'text-yellow-600': tierSecurityScore >= 60,
                    'text-red-600': tierSecurityScore < 60
                  }">
                    {{ tierSecurityScore }}/100 - {{ getSecurityLevel(tierSecurityScore) }}
                  </span>
                </p>
                <p><span class="text-gray-500  mr-2">Distribution Contracts:</span> 
                  <span class="text-blue-600  mr-2">{{ formData.distributionContracts?.length || 0 }} configured</span>
                  <span v-if="formData.distributionContracts && formData.distributionContracts.length > 0" class="text-xs text-gray-400 ml-2">
                    (provides additional voting power)
                  </span>
                </p>
              </div>
            </div>

            <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
              <h3 class="font-medium text-gray-900 dark:text-white mb-2">Governance</h3>
              <div class="text-sm space-y-1">
                <p><span class="text-gray-500">Quorum:</span> {{ formData.quorumPercentage }}%</p>
                <p><span class="text-gray-500">Approval:</span> {{ formData.approvalThreshold }}%</p>
                <p><span class="text-gray-500">Voting Period:</span> {{ votingPeriodDays }} days</p>
                <p><span class="text-gray-500">Timelock:</span> {{ timelockDays }} days</p>
              </div>
            </div>
          </div>

          <!-- Custom Security Summary (if configured) -->
          <div v-if="hasCustomSecuritySettings" class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
            <h3 class="font-medium text-blue-800 dark:text-blue-200 mb-2">Custom Security Settings</h3>
            <div class="text-sm space-y-1">
              <p v-if="customSecurity.minStakeAmount"><span class="text-blue-600 dark:text-blue-300">Min Stake:</span> {{ customSecurity.minStakeAmount }} tokens</p>
              <p v-if="customSecurity.maxStakeAmount"><span class="text-blue-600 dark:text-blue-300">Max Stake:</span> {{ customSecurity.maxStakeAmount }} tokens</p>
              <p v-if="customSecurity.minProposalDeposit"><span class="text-blue-600 dark:text-blue-300">Min Proposal Deposit:</span> {{ customSecurity.minProposalDeposit }} tokens</p>
              <p v-if="customSecurity.maxProposalDeposit"><span class="text-blue-600 dark:text-blue-300">Max Proposal Deposit:</span> {{ customSecurity.maxProposalDeposit }} tokens</p>
              <p v-if="customSecurity.maxProposalsPerHour"><span class="text-blue-600 dark:text-blue-300">Rate Limit:</span> {{ customSecurity.maxProposalsPerHour }}/hour</p>
              <p v-if="customSecurity.maxProposalsPerDay"><span class="text-blue-600 dark:text-blue-300">Daily Limit:</span> {{ customSecurity.maxProposalsPerDay }}/day</p>
            </div>
          </div>

          <!-- Validation Summary -->
          <div v-if="totalValidationErrors.hasErrors" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <div class="flex items-start">
              <AlertCircleIcon class="h-5 w-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" />
              <div class="flex-1">
                <h3 class="font-medium text-red-800 dark:text-red-200 mb-2">Validation Issues Found</h3>
                <p class="text-sm text-red-600 dark:text-red-300 mb-3">
                  Please fix the following {{ totalValidationErrors.count }} validation error{{ totalValidationErrors.count > 1 ? 's' : '' }} before deploying:
                </p>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div v-if="validateBasicInfo().errors.length > 0">
                    <h4 class="text-sm font-medium text-red-700 dark:text-red-300 mb-2">Basic Information ({{ validateBasicInfo().errors.length }})</h4>
                    <ul class="text-xs text-red-600 dark:text-red-400 space-y-1">
                      <li v-for="error in validateBasicInfo().errors" :key="error" class="flex items-center">
                        <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2"></span>
                        {{ error }}
                      </li>
                    </ul>
                  </div>
                  <div v-if="validateGovernanceSettings().errors.length > 0">
                    <h4 class="text-sm font-medium text-red-700 dark:text-red-300 mb-2">Governance Settings ({{ validateGovernanceSettings().errors.length }})</h4>
                    <ul class="text-xs text-red-600 dark:text-red-400 space-y-1">
                      <li v-for="error in validateGovernanceSettings().errors" :key="error" class="flex items-center">
                        <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2"></span>
                        {{ error }}
                      </li>
                    </ul>
                  </div>
                  <div v-if="validateSecuritySettings().errors.length > 0">
                    <h4 class="text-sm font-medium text-red-700 dark:text-red-300 mb-2">Security Settings ({{ validateSecuritySettings().errors.length }})</h4>
                    <ul class="text-xs text-red-600 dark:text-red-400 space-y-1">
                      <li v-for="error in validateSecuritySettings().errors" :key="error" class="flex items-center">
                        <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2"></span>
                        {{ error }}
                      </li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Deployment Cost -->
          <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="font-medium text-yellow-800 dark:text-yellow-200">Deployment Cost</h3>
                <p class="text-sm text-yellow-600 dark:text-yellow-300">Required to create and deploy your DAO</p>
              </div>
              <div class="text-right">
                <p class="text-2xl font-bold text-yellow-800 dark:text-yellow-200">{{ creationCost }} ICP</p>
                <p class="text-sm text-yellow-600 dark:text-yellow-300">≈ ${{ (Number(creationCost) * 8).toFixed(2) }}</p>
              </div>
            </div>
          </div>

          <!-- Error Display -->
          <div v-if="error" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <div class="flex items-center">
              <AlertCircleIcon class="h-5 w-5 text-red-500 mr-2" />
              <p class="text-sm text-red-600 dark:text-red-400">{{ error }}</p>
            </div>
          </div>

          <!-- Success Display -->
          <div v-if="deploymentResult" class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center">
                <CheckCircleIcon class="h-5 w-5 text-green-500 mr-2" />
                <div>
                  <p class="font-medium text-green-800 dark:text-green-200">DAO Created Successfully!</p>
                  <p class="text-sm text-green-600 dark:text-green-400">Canister ID: {{ deploymentResult.daoCanisterId }}</p>
                </div>
              </div>
              <button 
                @click="goToDAO"
                class="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
              >
                View DAO
              </button>
            </div>
          </div>
        </div>

        <!-- Validation Errors Display -->
        <div v-if="!validationErrors.valid && validationErrors.errors.length > 0" class="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start">
            <AlertCircleIcon class="h-5 w-5 text-red-500 mr-2 mt-0.5 flex-shrink-0" />
            <div>
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please follow the instructions:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="error in validationErrors.errors" :key="error" class="flex items-center">
                  <span class="w-2 h-2 bg-red-400 rounded-full mr-2"></span>
                  {{ error }}
                </li>
              </ul>
            </div>
          </div>
        </div>
        
      </div>

      <!-- Navigation -->
      <div class="px-6 py-4 border-t border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <button
            v-if="currentStep > 0"
            @click="previousStep"
            :disabled="isPaying"
            class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500  disabled:opacity-50"
          >
            <ArrowLeftIcon class="h-4 w-4 mr-2" />
            Previous
          </button>
          <div v-else></div>

          <div class="flex items-center space-x-3">
            <button
              v-if="currentStep < steps.length - 1"
              @click="nextStep"
              :disabled="!canProceed || isPaying"
              class="inline-flex items-center px-6 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600 hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50 disabled:cursor-not-allowed "
            >
              Next Step
              <ArrowRightIcon class="h-4 w-4 ml-2" />
            </button>
            
            <button
              v-else
              @click="deployDAO"
              :disabled="!canProceed || isPaying || !!deploymentResult"
              class="inline-flex items-center px-6 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <div v-if="isPaying" class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
              <RocketIcon v-else class="h-4 w-4 mr-2" />
              {{ isPaying ? 'Deploying...' : `Deploy DAO${totalValidationErrors.hasErrors ? ` (${totalValidationErrors.count} errors)` : ''}` }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { DAOService } from '@/api/services/dao'
import { useProgressDialog } from '@/composables/useProgressDialog'
import { IcrcService } from '@/api/services/icrc'
import { backendService } from '@/api/services/backend'
import { toast } from 'vue-sonner'
import { Principal } from '@dfinity/principal'
import { hanldeApproveResult } from '@/utils/icrc'

import {
  ArrowLeftIcon,
  ArrowRightIcon,
  Building2Icon,
  CheckIcon,
  XIcon,
  AlertCircleIcon,
  CheckCircleIcon,
  RocketIcon,
  InfoIcon
} from 'lucide-vue-next'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import TokenSelector from '@/components/common/TokenSelector.vue'
import Select from '@/components/common/Select.vue'
import type { DAOConfig, CreateDAOResponse, CustomSecurityParams, GovernanceLevel } from '@/types/dao'
import { getGovernanceLevelOptions, getGovernanceLevelCapabilities, isTokenOwnershipRequired } from '@/types/dao'
// Note: Using local daysToSeconds and secondsToDays functions instead of staking imports
import { useSwal } from '@/composables/useSwal2'
import CustomTierManager from '@/components/dao/CustomTierManager.vue'
import DistributionContractManager from '@/components/dao/DistributionContractManager.vue'
const router = useRouter()
const authStore = useAuthStore()
const daoService = DAOService.getInstance()
const progress = useProgressDialog()

// Form data
const formData = ref<DAOConfig>({
  name: '',
  description: '',
  tokenCanisterId: '',
  governanceType: 'liquid',
  governanceLevel: 'motion-only', // Default to safest option
  stakingEnabled: false,
  minimumStake: '100',
  proposalThreshold: '1000',
  proposalSubmissionDeposit: '10',
  quorumPercentage: 20,
  approvalThreshold: 50,
  timelockDuration: 172800, // 2 days in seconds
  maxVotingPeriod: 604800, // 7 days in seconds
  minVotingPeriod: 86400, // 1 day in seconds
  stakeLockPeriods: [604800, 2592000, 7776000, 15552000, 31536000], // Legacy - 7, 30, 90, 180, 365 days
  customMultiplierTiers: undefined, // Will be set by CustomTierManager
  distributionContracts: [], // Distribution contracts for voting power
  emergencyContacts: [''],
  emergencyPauseEnabled: false,
  managedByDAO: false, // This will be computed based on governanceLevel
  transferFee: '0.0001',
  initialSupply: undefined, // For new tokens (if creating new token with DAO)
  enableDelegation: true,
  votingPowerModel: 'proportional',
  tags: [],
  isPublic: true
})


// Custom security settings (separate reactive object)
const customSecurity = ref<CustomSecurityParams>({
  minStakeAmount: '',
  maxStakeAmount: '',
  minProposalDeposit: '',
  maxProposalDeposit: '',
  maxProposalsPerHour: undefined,
  maxProposalsPerDay: undefined
})

// UI state
const showAdvancedSecurity = ref(false)
const currentStep = ref(0)
const error = ref<string | null>(null)
const deploymentResult = ref<CreateDAOResponse | null>(null)

// Payment state
const isPaying = ref(false)
const deployResult = ref<{ daoCanisterId?: string; success: boolean; error?: string } | null>(null)

// Deployment cost
const creationCostBigInt = ref<bigint>(BigInt(0))
const creationCost = computed(() => {
  if (creationCostBigInt.value === BigInt(0)) return '1.5' // fallback
  return (Number(creationCostBigInt.value) / 100000000).toFixed(2) // Convert from e8s to ICP
})

// Token info state
const tokenInfo = ref(null)
const tokenError = ref<string | null>(null)

// Helper refs
const tagsInput = ref('')
const votingPeriodDays = ref(7)
const timelockDays = ref(2)
// Custom Tier System Configuration
const customTiers = ref<any[]>([])
const tierSecurityScore = ref(85)
const tierValidationStatus = ref<{ valid: boolean; errors: string[]; score?: number }>({ valid: true, errors: [] })

// Distribution Contract System Configuration
const distributionValidationStatus = ref<{ valid: boolean; errors: string[] }>({ valid: true, errors: [] })

// Security is now handled through formData.emergencyPauseEnabled and emergencyContacts

const steps = [
  { id: 'basic', title: 'Basic Info', description: 'Name, description, token' },
  { id: 'governance', title: 'Governance', description: 'Voting rules and parameters' },
  { id: 'security', title: 'Staking & Security', description: 'Staking options and safety' },
  { id: 'deploy', title: 'Review & Deploy', description: 'Final review and deployment' }
]

// Validation functions based on backend DAOFactoryService.mo
const validateBasicInfo = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = []
  
  // Validate basic information
  if (!formData.value.name.trim()) {
    errors.push('DAO name cannot be empty')
  }
  
  if (!formData.value.description.trim()) {
    errors.push('DAO description cannot be empty')
  }
  
  // Validate token canister ID
  if (!formData.value.tokenCanisterId || !tokenInfo.value || tokenError.value) {
    errors.push('Valid token canister ID is required')
  }
  
  return { valid: errors.length === 0, errors }
}

const validateGovernanceSettings = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = []
  
  // Validate governance parameters
  if (!formData.value.minimumStake || Number(formData.value.minimumStake) <= 0) {
    errors.push('Minimum stake must be greater than 0')
  }
  
  if (!formData.value.proposalThreshold || Number(formData.value.proposalThreshold) <= 0) {
    errors.push('Proposal threshold must be greater than 0')
  }
  
  // Validate percentages (basis points - backend uses 10000 = 100%)
  if (formData.value.quorumPercentage <= 0 || formData.value.quorumPercentage > 100) {
    errors.push('Quorum percentage must be between 1 and 100%')
  }
  
  if (formData.value.approvalThreshold <= 0 || formData.value.approvalThreshold > 100) {
    errors.push('Approval threshold must be between 1 and 100%')
  }
  
  // Validate time parameters
  if (formData.value.timelockDuration < 3600) { // Minimum 1 hour
    errors.push('Timelock duration must be at least 1 hour (3600 seconds)')
  }
  
  if (formData.value.maxVotingPeriod < formData.value.minVotingPeriod) {
    errors.push('Maximum voting period must be greater than minimum voting period')
  }
  
  if (formData.value.minVotingPeriod < 3600) { // Minimum 1 hour
    errors.push('Minimum voting period must be at least 1 hour (3600 seconds)')
  }
  
  return { valid: errors.length === 0, errors }
}

const validateSecuritySettings = (): { valid: boolean; errors: string[] } => {
  const errors: string[] = []
  
  // Validate custom tier staking configuration
  if (formData.value.stakingEnabled) {
    if (customTiers.value.length === 0) {
      errors.push('At least one custom staking tier must be configured')
    }
    
    if (!tierValidationStatus.value.valid) {
      errors.push(...tierValidationStatus.value.errors)
    }
    
    // Validate minimum stake from tiers
    if (customTiers.value.length > 0) {
      const minStakeFromTiers = Math.min(...customTiers.value.map((t: any) => t.minStake))
      if (minStakeFromTiers <= 0) {
        errors.push('Minimum stake amount must be greater than 0')
      }
    }
  }
  
  // Validate distribution contracts
  if (!distributionValidationStatus.value.valid) {
    errors.push(...distributionValidationStatus.value.errors)
  }
  
  // Validate emergency contacts
  if (formData.value.emergencyPauseEnabled && 
      (!formData.value.emergencyContacts || 
       formData.value.emergencyContacts.length === 0 || 
       !formData.value.emergencyContacts.some(contact => contact.trim()))) {
    errors.push('Emergency contacts required when emergency pause is enabled')
  }
  
  // Validate transfer fee
  if (!formData.value.transferFee || Number(formData.value.transferFee) < 0) {
    errors.push('Transfer fee must be non-negative')
  }
  
  // Validate governance type
  const validGovernanceTypes = ['liquid', 'locked', 'hybrid']
  if (!validGovernanceTypes.includes(formData.value.governanceType)) {
    errors.push('Invalid governance type. Must be "liquid", "locked", or "hybrid"')
  }
  
  // Validate voting power model
  const validVotingModels = ['equal', 'proportional', 'quadratic']
  if (!validVotingModels.includes(formData.value.votingPowerModel)) {
    errors.push('Invalid voting power model. Must be "equal", "proportional", or "quadratic"')
  }
  
  return { valid: errors.length === 0, errors }
}

// Computed validation state
const validationErrors = computed(() => {
  switch (currentStep.value) {
    case 0:
      return validateBasicInfo()
    case 1:
      return validateGovernanceSettings()
    case 2:
      return validateSecuritySettings()
    case 3:
      return { valid: true, errors: [] }
    default:
      return { valid: false, errors: ['Invalid step'] }
  }
})

// Computed
const canProceed = computed(() => {
  // Check if current step validation passes
  if (!validationErrors.value.valid) {
    return false
  }
  
  // Additional step-specific checks
  switch (currentStep.value) {
    case 0:
      const basicValid = formData.value.name.trim() && 
                         formData.value.description.trim() && 
                         formData.value.tokenCanisterId && 
                         tokenInfo.value && 
                         !tokenError.value
      console.log('🔍 canProceed step 0:', {
        name: !!formData.value.name,
        description: !!formData.value.description,
        tokenCanisterId: !!formData.value.tokenCanisterId,
        tokenInfo: !!tokenInfo.value,
        noTokenError: !tokenError.value,
        tokenError: tokenError.value,
        result: basicValid
      })
      return basicValid
    case 1:
      return formData.value.minimumStake && formData.value.proposalThreshold && 
             formData.value.proposalSubmissionDeposit &&
             formData.value.quorumPercentage > 0 && formData.value.approvalThreshold > 0
    case 2:
      // Custom tier staking validation: must have valid tiers configured
      const stakingValid = !formData.value.stakingEnabled || (customTiers.value.length > 0 && tierValidationStatus.value.valid)
      const emergencyValid = !formData.value.emergencyPauseEnabled || 
                            formData.value.emergencyContacts.some(contact => contact.trim())
      const securityValid = tierSecurityScore.value >= 60 // Minimum security score
      const distributionValid = distributionValidationStatus.value.valid // Distribution contracts must be valid
      return formData.value.transferFee && stakingValid && emergencyValid && securityValid && distributionValid
    case 3:
      return true
    default:
      return false
  }
})

const hasCustomSecuritySettings = computed(() => {
  return Object.values(customSecurity.value).some(val => 
    val !== '' && val !== undefined && val !== null
  )
})

// Computed for total validation errors across all steps
const totalValidationErrors = computed(() => {
  const allErrors: string[] = []
  
  // Collect errors from all steps
  const basicErrors = validateBasicInfo()
  const governanceErrors = validateGovernanceSettings()
  const securityErrors = validateSecuritySettings()
  
  allErrors.push(...basicErrors.errors)
  allErrors.push(...governanceErrors.errors)
  allErrors.push(...securityErrors.errors)
  
  return {
    count: allErrors.length,
    errors: allErrors,
    hasErrors: allErrors.length > 0
  }
})

// Governance level capabilities
const currentGovernanceCapabilities = computed(() => {
  return getGovernanceLevelCapabilities(formData.value.governanceLevel)
})

const requiresTokenOwnership = computed(() => {
  return isTokenOwnershipRequired(formData.value.governanceLevel)
})

// Watchers
watch(tagsInput, (newValue) => {
  if (newValue.includes(',')) {
    const tags = newValue.split(',').map(tag => tag.trim()).filter(tag => tag)
    formData.value.tags = [...new Set([...formData.value.tags, ...tags])]
    tagsInput.value = ''
  }
})

// Auto-update managedByDAO based on governance level
watch(() => formData.value.governanceLevel, (newLevel) => {
  const capabilities = getGovernanceLevelCapabilities(newLevel)
  formData.value.managedByDAO = capabilities.canManageToken
})



watch(votingPeriodDays, (days) => {
  formData.value.maxVotingPeriod = days * 24 * 60 * 60
})

watch(timelockDays, (days) => {
  formData.value.timelockDuration = days * 24 * 60 * 60
})

// Watch staking configuration to update stake lock periods
watch(() => formData.value.stakingEnabled, (enabled) => {
  if (enabled && customTiers.value.length > 0) {
    // Custom tier system: use configured tiers' lock periods
    const lockPeriods = customTiers.value.map((tier: any) => tier.lockDays * 86400) // Convert days to seconds
    formData.value.stakeLockPeriods = [...new Set(lockPeriods)].sort((a, b) => a - b)
  } else {
    // No staking: empty lock periods
    formData.value.stakeLockPeriods = []
  }
}, { immediate: true })

// Computed
const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: 'Create DAO' }
])

// Methods
const nextStep = () => {
  if (currentStep.value < steps.length - 1) {
    currentStep.value++
  }
}

// Custom Tier Management Functions
const onTierConfigChanged = (tiers: any[]) => {
  customTiers.value = tiers
  
  // Set custom multiplier tiers in formData for backend
  formData.value.customMultiplierTiers = tiers.map(tier => ({
    id: tier.id,
    name: tier.name,
    minStake: tier.minStake * 100000000, // Convert to e8s
    maxStakePerEntry: tier.maxStakePerEntry > 0 ? tier.maxStakePerEntry * 100000000 : null,
    lockPeriod: tier.lockDays * 86400, // Convert days to seconds
    multiplier: tier.multiplier,
    maxVpPercentage: tier.maxVpPercent,
    emergencyUnlockEnabled: false,
    flashLoanProtection: tier.lockDays >= 7,
    governanceCapProtection: tier.maxVpPercent <= 40
  }))
  
  // Update legacy stakeLockPeriods for backward compatibility
  const lockPeriods = tiers.map(tier => tier.lockDays * 86400) // Convert days to seconds
  formData.value.stakeLockPeriods = [...new Set(lockPeriods)].sort((a, b) => a - b)
  
  // Update minimum stake based on lowest tier
  if (tiers.length > 0) {
    const minStakeFromTiers = Math.min(...tiers.map(t => t.minStake))
    formData.value.minimumStake = minStakeFromTiers.toString()
  }
  
  console.log('🔧 Custom tiers updated:', {
    tiersCount: tiers.length,
    customMultiplierTiers: formData.value.customMultiplierTiers,
    lockPeriods: formData.value.stakeLockPeriods
  })
}

const onTierValidationChanged = (validation: { valid: boolean; score: number; errors: string[] }) => {
  tierValidationStatus.value = validation
  tierSecurityScore.value = validation.score
}

const onDistributionValidationChanged = (validation: { valid: boolean; errors: string[] }) => {
  distributionValidationStatus.value = validation
}

const getSecurityLevel = (score: number): string => {
  if (score >= 90) return 'Excellent'
  if (score >= 80) return 'Good' 
  if (score >= 60) return 'Fair'
  return 'Needs Improvement'
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

const removeTag = (tag: string) => {
  formData.value.tags = formData.value.tags.filter(t => t !== tag)
}

const addEmergencyContact = () => {
  formData.value.emergencyContacts.push('')
}

// Lock period validation helper
const validateLockPeriod = (days: number): { valid: boolean; error?: string } => {
  if (days < 1) return { valid: false, error: 'Lock period must be at least 1 day' }
  if (days > 365) return { valid: false, error: 'Lock period cannot exceed 365 days' }
  return { valid: true }
}

const daysToSeconds = (days: number) => days * 24 * 60 * 60
const secondsToDays = (seconds: number) => Math.round(seconds / (24 * 60 * 60))

// Lock period selection helpers
const addLockPeriod = (days: number) => {
  const validation = validateLockPeriod(days)
  if (!validation.valid) {
    toast.error(validation.error || 'Invalid lock period')
    return
  }
  
  const seconds = daysToSeconds(days)
  if (!formData.value.stakeLockPeriods.includes(seconds)) {
    formData.value.stakeLockPeriods.push(seconds)
    formData.value.stakeLockPeriods.sort((a, b) => a - b)
    toast.success(`Added ${days}-day lock period`)
  }
}

const removeLockPeriod = (seconds: number) => {
  const index = formData.value.stakeLockPeriods.indexOf(seconds)
  if (index > -1) {
    formData.value.stakeLockPeriods.splice(index, 1)
    const days = secondsToDays(seconds)
    toast.success(`Removed ${days}-day lock period`)
  }
}

// Token handlers
const handleTokenFetched = (info: any) => {
  console.log('🔍 handleTokenFetched called with:', info)
  tokenInfo.value = info
  tokenError.value = null
}

const handleTokenError = (err: string | null) => {
  // TODO: handle token error, if null -> no error, string -> error
  if(err === null) {
    return
  } else {
    tokenError.value = err
    tokenInfo.value = null
  }
}

const deployDAO = async () => {
  if (!canProceed.value) return
  
  // Final validation check before deployment
  if (totalValidationErrors.value.hasErrors) {
    await useSwal.fire({
      title: 'Validation Errors Found',
      html: `
        <div class="text-left">
          <p class="mb-3">Please fix the following validation errors before deploying:</p>
          <ul class="text-left space-y-1">
            ${totalValidationErrors.value.errors.map((error: string) => `<li>• ${error}</li>`).join('')}
          </ul>
        </div>
      `,
      icon: 'error',
      confirmButtonText: 'Fix Errors',
      showCancelButton: false
    })
    return
  }

  const isConfirmed = await useSwal.fire({
    title: 'Are you sure?',
    text: 'You are about to deploy a DAO. This action is irreversible.',
    icon: 'warning',
    showCancelButton: true,
    confirmButtonText: 'Yes, deploy it!'
  })
  if (!isConfirmed.isConfirmed) return
  
  isPaying.value = true
  deployResult.value = null

  // Progress steps
  const steps = [
    'Getting deployment price...',
    'Approving payment amount...',
    'Verifying approval...',
    'Deploying DAO to canister...',
    'Initializing contract...',
    'Finalizing deployment...'
  ]

  // Track current step for retry
  let currentStepIndex = 0
  let deployPrice = BigInt(0)
  let icpToken: any | null = null
  let backendCanisterId = ''
  let approveAmount = BigInt(0)

  // Retry logic for a specific step
  const retryStep = async (stepIdx: number) => {
    progress.setError('')
    progress.setLoading(true)
    progress.setStep(stepIdx)
    try {
      await runSteps(stepIdx)
    } catch (error: unknown) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      progress.setError(errorMessage)
      deployResult.value = {
        success: false,
        error: errorMessage
      }
      toast.error('Deployment failed: ' + errorMessage)
    } finally {
      isPaying.value = false
      progress.setLoading(false)
    }
  }

  // Main step runner
  const runSteps = async (startIdx = 0) => {
    for (let i = startIdx; i < steps.length; i++) {
      currentStepIndex = i
      progress.setStep(i)

      try {
        switch (i) {
          case 0: // Get deployment price
            deployPrice = await backendService.getDeploymentFee('dao_factory')
            backendCanisterId = await backendService.getBackendCanisterId()

            // Get ICP token info for approval
            icpToken = {
              canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // ICP Ledger
              name: 'Internet Computer',
              symbol: 'ICP',
              decimals: 8,
              fee: 10000,
              standards: ['ICRC-1', 'ICRC-2'],
              metrics: {
                price: 0,
                volume: 0,
                marketCap: 0,
                totalSupply: 0
              }
            }

            // Calculate approve amount: deployPrice + (2 * transaction fee)
            const transactionFee = BigInt(icpToken.fee)
            approveAmount = deployPrice + (transactionFee * BigInt(2))
            break

          case 1: // ICRC2 Approve
            if (!icpToken || !authStore.principal) {
              throw new Error('Missing required data for approval')
            }

            const now = BigInt(Date.now()) * 1_000_000n; // nanoseconds
            const oneHour = 60n * 60n * 1_000_000_000n;  // 1 hour in nanoseconds

            const approveResult = await IcrcService.icrc2Approve(
              icpToken,
              Principal.fromText(backendCanisterId),
              approveAmount,
              {
                memo: undefined,
                createdAtTime: now,
                expiresAt: now + oneHour,
                expectedAllowance: undefined
              }
            )

            const approveResultData = hanldeApproveResult(approveResult)
            if (approveResultData.error) {
              throw new Error(approveResultData.error.message)
            }
            break

          case 2: // Verify approval
            if (!icpToken || !authStore.principal) {
              throw new Error('Missing required data for verification')
            }

            const allowance = await IcrcService.getIcrc2Allowance(
              icpToken,
              Principal.fromText(authStore.principal),
              Principal.fromText(backendCanisterId)
            )

            if (allowance < deployPrice) {
              throw new Error(`Insufficient allowance: ${allowance.toString()} < ${deployPrice.toString()}`)
            }
            break

          case 3: // Deploy DAO
            // Merge custom security settings if any are provided
            const hasCustomSecurity = Object.values(customSecurity.value).some(val => 
              val !== '' && val !== undefined && val !== null
            )
            
            const daoConfigWithSecurity = {
              ...formData.value,
              customSecurity: hasCustomSecurity ? {
                minStakeAmount: customSecurity.value.minStakeAmount || undefined,
                maxStakeAmount: customSecurity.value.maxStakeAmount || undefined,
                minProposalDeposit: customSecurity.value.minProposalDeposit || undefined,
                maxProposalDeposit: customSecurity.value.maxProposalDeposit || undefined,
                maxProposalsPerHour: customSecurity.value.maxProposalsPerHour || undefined,
                maxProposalsPerDay: customSecurity.value.maxProposalsPerHour || undefined
              } : undefined
            }
            
            const result = await daoService.createDAO(daoConfigWithSecurity)
            
            if (!result.success) {
              throw new Error(`DAO deployment failed: ${result.error}`)
            }

            deployResult.value = {
              daoCanisterId: result.daoCanisterId,
              success: true
            }
            break

          case 4: // Initialize contract
            if (deployResult.value?.daoCanisterId) {
              try {
                // TODO: Add DAO contract initialization if needed
                console.log('DAO contract deployed successfully')
              } catch (error) {
                console.error('Error during auto-initialization:', error)
                toast.warning('DAO deployed but auto-initialization failed. You may need to initialize manually.')
              }
            }
            break

          case 5: // Finalize
            progress.setLoading(false)
            progress.close()

            toast.success(`🎉 DAO deployed successfully! Canister ID: ${deployResult.value?.daoCanisterId}`)

            // Update the deployment result for the UI
            deploymentResult.value = {
              success: true,
              daoCanisterId: deployResult.value?.daoCanisterId || ''
            }
            return
        }

        // Add delay between steps for UX
        if (i < steps.length - 1) {
          await new Promise(resolve => setTimeout(resolve, 1000))
        }

      } catch (error) {
        console.error(`Error at step ${i}:`, error)
        throw error
      }
    }
  }

  // Start the deployment process
  progress.open({
    steps,
    title: 'Deploying DAO',
    subtitle: 'Please wait while we process your deployment',
    onRetryStep: retryStep
  })
  progress.setLoading(true)
  progress.setStep(0)

  try {
    await runSteps(0)
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
    progress.setError(errorMessage)
    deployResult.value = {
      success: false,
      error: errorMessage
    }
    toast.error('DAO deployment failed: ' + errorMessage)
  } finally {
    isPaying.value = false
    progress.setLoading(false)
  }
}

const goToDAO = () => {
  if (deploymentResult.value?.daoCanisterId) {
    router.push(`/dao/${deploymentResult.value.daoCanisterId}`)
  }
}

// Load deployment cost
const loadDeploymentCost = async () => {
  try {
    creationCostBigInt.value = await backendService.getDeploymentFee('dao_factory')
  } catch (error) {
    console.error('Error loading deployment cost:', error)
    creationCostBigInt.value = BigInt(150000000) // 1.5 ICP fallback
  }
}

// Initialize component
loadDeploymentCost()
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>