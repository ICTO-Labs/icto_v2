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
          <RocketIcon class="h-6 w-6 text-white" />
        </div>
        <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-900 via-amber-700 to-yellow-600 dark:from-white dark:via-yellow-400 dark:to-amber-300 bg-clip-text text-transparent">
          Launch New Project
        </h1>
      </div>
      <p class="text-gray-600 dark:text-gray-400 max-w-2xl">
        Create a comprehensive token launch campaign with advanced tokenomics, distribution management, and fundraising capabilities.
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
      
      <!-- Step 0: Template Selection -->
      <div v-if="currentStep === 0" class="p-6">
        <LaunchpadTemplateSelector
          @select-template="loadTemplate"
        />
      </div>

      <!-- Step 1: Project Information -->
      <div v-if="currentStep === 1" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Project Information</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">Provide detailed information about your project that will be displayed to potential investors.</p>
        
        <div class="space-y-6">
          <!-- Basic Project Information -->
          <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">Basic Information</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Project Name -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Project Name* <HelpTooltip>The official name of your project that will be displayed to investors</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.name"
                  type="text"
                  placeholder="My Awesome Project"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                  required
                />
              </div>

              <!-- Category -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Category* <HelpTooltip>Select the category that best describes your project</HelpTooltip>
                </label>
                <Select
                  v-model="formData.projectInfo.category"
                  placeholder="Select Category"
                  :options="[
                    { value: 'DeFi', label: 'Decentralized Finance (DeFi)' },
                    { value: 'NFT', label: 'Non-Fungible Tokens (NFT)' },
                    { value: 'Gaming', label: 'Gaming & Metaverse' },
                    { value: 'Infrastructure', label: 'Infrastructure & Tools' },
                    { value: 'Social', label: 'Social & Community' },
                    { value: 'DAO', label: 'Decentralized Autonomous Organization' },
                    { value: 'Other', label: 'Other' }
                  ]"
                  required
                />
              </div>

              <!-- Project Description -->
              <div class="md:col-span-2">
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Description* <HelpTooltip>Detailed description of your project, its purpose, and value proposition. This will be prominently displayed to potential investors.</HelpTooltip>
                </label>
                <textarea
                  v-model="formData.projectInfo.description"
                  rows="4"
                  placeholder="Provide a comprehensive description of your project, including its goals, technology, and unique features..."
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                  required
                ></textarea>
              </div>
            </div>
          </div>

          <!-- Links & Social Media -->
          <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-4">Links & Social Media</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Website -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Website <HelpTooltip>Your project's official website URL</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.website"
                  type="url"
                  placeholder="https://yourproject.com"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
              </div>

              <!-- Twitter -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Twitter <HelpTooltip>Your project's official Twitter/X account URL</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.twitter"
                  type="url"
                  placeholder="https://twitter.com/yourproject"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
              </div>

              <!-- Telegram -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Telegram <HelpTooltip>Your project's official Telegram channel or group URL</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.telegram"
                  type="url"
                  placeholder="https://t.me/yourproject"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
              </div>

              <!-- Discord -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Discord <HelpTooltip>Your project's official Discord server invitation URL</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.discord"
                  type="url"
                  placeholder="https://discord.gg/yourproject"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
              </div>
            </div>
          </div>

          <!-- Verification & Compliance -->
          <div class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-6">
            <h3 class="text-lg font-semibold text-yellow-900 dark:text-yellow-100 mb-4">Verification & Compliance</h3>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- BlockID Verification -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  BlockID Required <HelpTooltip>Minimum BlockID level required for participants. Higher levels indicate more verified users with established identity and reputation.</HelpTooltip>
                </label>
                <Select
                  v-model="formData.saleParams.blockIdRequired"
                  placeholder="Select BlockID Requirement"
                  :options="[
                    { value: BigInt(0), label: 'No BlockID Required' },
                    { value: BigInt(1), label: 'BlockID Level 1 (Basic)' },
                    { value: BigInt(2), label: 'BlockID Level 2 (Verified)' },
                    { value: BigInt(3), label: 'BlockID Level 3 (Premium)' }
                  ]"
                />
                <p class="text-xs text-gray-500 mt-1">Higher BlockID levels reduce bot participation and increase user quality</p>
              </div>

              <!-- KYC Provider -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  KYC Provider <HelpTooltip>Optional: If your project has completed KYC verification, specify the provider</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.kycProvider"
                  type="text"
                  placeholder="e.g., CertiK, Assure DeFi"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
              </div>
            </div>

            <!-- Verification Checkboxes -->
            <div class="mt-4 space-y-3">
              <div class="flex items-center">
                <input
                  :id="uniqueIds.isKYCed"
                  v-model="formData.projectInfo.isKYCed"
                  type="checkbox"
                  class="h-4 w-4 text-yellow-600 focus:ring-yellow-500 border-gray-300 rounded"
                />
                <label :for="uniqueIds.isKYCed" class="ml-2 block text-sm text-gray-700 dark:text-gray-300">
                  Team has completed KYC verification
                </label>
              </div>

              <div class="flex items-center">
                <input
                  :id="uniqueIds.isAudited"
                  v-model="formData.projectInfo.isAudited"
                  type="checkbox"
                  class="h-4 w-4 text-yellow-600 focus:ring-yellow-500 border-gray-300 rounded"
                />
                <label :for="uniqueIds.isAudited" class="ml-2 block text-sm text-gray-700 dark:text-gray-300">
                  Smart contracts have been audited
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 3: Token Configuration -->
      <div v-if="currentStep === 2" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Token & Sale Configuration</h2>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Sale Type -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Sale Type* <HelpTooltip>Choose the type of token sale. IDO offers immediate liquidity, Private Sale is for pre-launch investors, Fair Launch ensures equal opportunity, Auction allows price discovery, and Lottery adds randomization.</HelpTooltip></label>
            <Select
              v-model="formData.saleParams.saleType"
              placeholder="Select Sale Type"
              :options="[
                { value: 'IDO', label: 'IDO (Initial DEX Offering)' },
                { value: 'PrivateSale', label: 'Private Sale' },
                { value: 'FairLaunch', label: 'Fair Launch' },
                { value: 'Auction', label: 'Auction' },
                { value: 'Lottery', label: 'Lottery' }
              ]"
              required
            />
          </div>

          <!-- Allocation Method -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Allocation Method* <HelpTooltip>First Come First Serve allocates tokens in order of contribution. Pro Rata distributes proportionally. Weighted considers user history/tier. Lottery adds randomness for fairness.</HelpTooltip></label>
            <Select
              v-model="formData.saleParams.allocationMethod"
              placeholder="Select Method"
              :options="[
                { value: 'FirstComeFirstServe', label: 'First Come First Serve' },
                { value: 'ProRata', label: 'Pro Rata' },
                { value: 'Weighted', label: 'Weighted' },
                { value: 'Lottery', label: 'Lottery' }
              ]"
              required
            />
          </div>

          <!-- Total Sale Amount -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Total Sale Amount* <HelpTooltip>Total number of tokens available for sale to participants. This should be a portion of your total token supply allocated specifically for public/private sale.</HelpTooltip></label>
            <div class="relative">
              <input
                v-model="formData.saleParams.totalSaleAmount"
                type="number"
                step="1"
                min="1"
                placeholder="1000000"
                class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ saleTokenSymbol }}</span>
            </div>
          </div>

          <!-- Max Participants -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Max Participants <HelpTooltip>Maximum number of unique wallets that can participate in the sale. Leave empty for unlimited. Setting a limit helps create exclusivity and prevents overwhelming participation.</HelpTooltip></label>
            <input
              v-model="formData.saleParams.maxParticipants"
              type="number"
              min="1"
              placeholder="1000"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
          </div>

          <!-- Soft Cap -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Soft Cap* <HelpTooltip>Minimum amount of funds that must be raised for the sale to be considered successful. If not reached, participants get refunded. Set realistically to ensure project viability.</HelpTooltip></label>
            <div class="relative">
              <input
                v-model="formData.saleParams.softCap"
                type="number"
                step="0.01"
                min="0"
                placeholder="10000"
                class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
            </div>
          </div>

          <!-- Hard Cap -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Hard Cap* <HelpTooltip>Maximum amount of funds that can be raised. Once reached, the sale closes automatically. Set this based on your project's funding needs and tokenomics.</HelpTooltip></label>
            <div class="relative">
              <input
                v-model="formData.saleParams.hardCap"
                type="number"
                step="0.01"
                min="0"
                placeholder="50000"
                class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
            </div>
          </div>

          <!-- Min Contribution -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Min Contribution* <HelpTooltip>Minimum amount each participant must invest. Helps prevent spam and ensures meaningful participation. Consider your target audience's capacity.</HelpTooltip></label>
            <div class="relative">
              <input
                v-model="formData.saleParams.minContribution"
                type="number"
                step="0.01"
                min="0"
                placeholder="10"
                class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
            </div>
          </div>

          <!-- Max Contribution -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Max Contribution <HelpTooltip>Maximum amount each participant can invest. Helps ensure fair distribution and prevents whales from dominating the sale. Leave empty for no limit.</HelpTooltip></label>
            <div class="relative">
              <input
                v-model="formData.saleParams.maxContribution"
                type="number"
                step="0.01"
                min="0"
                placeholder="1000"
                class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
              <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
            </div>
          </div>

          <!-- Requires Whitelist -->
          <div class="md:col-span-2">
            <div class="flex items-center space-x-3">
              <input
                v-model="formData.saleParams.requiresWhitelist"
                type="checkbox"
                :id="uniqueIds.requiresWhitelist"
                class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
              <label :for="uniqueIds.requiresWhitelist" class="text-sm font-medium text-gray-700 dark:text-gray-300">
                Requires Whitelist <HelpTooltip>Restrict sale participation to pre-approved addresses. Useful for private sales or compliance requirements. You'll need to provide the whitelist below.</HelpTooltip>
              </label>
            </div>
            <p class="text-xs text-gray-500 mt-1">Enable if you want to restrict participation to whitelisted addresses</p>
          </div>

          <!-- Requires KYC -->
          <div class="md:col-span-2">
            <div class="flex items-center space-x-3">
              <input
                v-model="formData.saleParams.requiresKYC"
                type="checkbox"
                :id="uniqueIds.requiresKYC"
                class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              />
              <label :for="uniqueIds.requiresKYC" class="text-sm font-medium text-gray-700 dark:text-gray-300">
                Requires KYC <HelpTooltip>Require participants to complete Know Your Customer verification. Increases compliance but may reduce participation. Consider your jurisdiction requirements.</HelpTooltip>
              </label>
            </div>
            <p class="text-xs text-gray-500 mt-1">Enable if you require participants to complete KYC verification</p>
          </div>

          <!-- Whitelist Management (shown when whitelist is required) -->
          <div v-if="formData.saleParams.requiresWhitelist" class="md:col-span-2 mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
            <h4 class="text-md font-semibold text-blue-900 dark:text-blue-100 mb-3">Whitelist Management</h4>
            
            <div class="space-y-4">
              <!-- Option 1: Upload CSV -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Upload Whitelist (CSV) <HelpTooltip>Upload a CSV file with whitelisted addresses. Format: address,allocation (allocation is optional). This is the fastest way to add multiple addresses.</HelpTooltip></label>
                <div class="flex items-center space-x-3">
                  <input
                    ref="csvFileInput"
                    type="file"
                    accept=".csv"
                    @change="handleCsvUpload"
                    class="hidden"
                  />
                  <button
                    @click="triggerCsvUpload"
                    type="button"
                    class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500"
                  >
                    <UploadIcon class="h-4 w-4 mr-2" />
                    Choose CSV File
                  </button>
                  <span v-if="csvFileName" class="text-sm text-gray-600 dark:text-gray-400">{{ csvFileName }}</span>
                </div>
                <p class="text-xs text-gray-500 mt-1">CSV format: address,allocation (optional)</p>
              </div>

              <!-- Option 2: Manual Entry -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300">Manual Entry <HelpTooltip>Add whitelist addresses individually. Include optional allocation limits per address. Useful for small lists or special allocations.</HelpTooltip></label>
                  <button
                    @click="addWhitelistAddress"
                    type="button"
                    class="text-xs px-2 py-1 text-yellow-600 hover:text-yellow-700 hover:bg-yellow-50 dark:hover:bg-yellow-900/20 rounded transition-colors"
                  >
                    <PlusIcon class="h-3 w-3 inline mr-1" />
                    Add Address
                  </button>
                </div>
                
                <div class="space-y-2 max-h-32 overflow-y-auto">
                  <div
                    v-for="(address, index) in formData.saleParams.whitelistAddresses"
                    :key="`whitelist-${index}`"
                    class="flex items-center space-x-2"
                  >
                    <input
                      v-model="address.principal"
                      type="text"
                      placeholder="Principal address (e.g., abc12-def34-...)"
                      class="flex-1 px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 bg-white dark:bg-gray-700"
                    />
                    <input
                      v-model="address.allocation"
                      type="number"
                      min="0"
                      placeholder="Max allocation (optional)"
                      class="w-32 px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded focus:ring-1 focus:ring-yellow-500 bg-white dark:bg-gray-700"
                    />
                    <button
                      @click="removeWhitelistAddress(index)"
                      type="button"
                      class="p-1 text-red-500 hover:text-red-700 rounded transition-colors"
                    >
                      <XIcon class="h-4 w-4" />
                    </button>
                  </div>
                </div>
                
                <div v-if="formData.saleParams.whitelistAddresses.length === 0" class="text-center py-4 text-sm text-gray-500">
                  No whitelist addresses added
                </div>
              </div>

              <!-- Whitelist Statistics -->
              <div v-if="formData.saleParams.whitelistAddresses.length > 0" class="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded p-3">
                <div class="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span class="text-gray-500">Total Addresses:</span>
                    <span class="ml-2 font-medium">{{ formData.saleParams.whitelistAddresses.length }}</span>
                  </div>
                  <div>
                    <span class="text-gray-500">With Allocation:</span>
                    <span class="ml-2 font-medium">{{ formData.saleParams.whitelistAddresses.filter(a => a.allocation).length }}</span>
                  </div>
                </div>
              </div>

              <!-- Registration Mode -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Registration Mode <HelpTooltip>Choose between a closed list (only pre-approved addresses) or open registration (users can register themselves for whitelist approval).</HelpTooltip></label>
                <div class="space-y-2">
                  <label class="flex items-center">
                    <input
                      v-model="formData.saleParams.whitelistMode"
                      value="closed"
                      type="radio"
                      class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                    />
                    <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">Closed List - Only addresses above can participate</span>
                  </label>
                  <label class="flex items-center">
                    <input
                      v-model="formData.saleParams.whitelistMode"
                      value="registration"
                      type="radio"
                      class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                    />
                    <span class="ml-2 text-sm text-gray-700 dark:text-gray-300">Open Registration - Allow users to register for whitelist</span>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 4: Token & Raised Funds Allocation -->
      <div v-if="currentStep === 3" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Token & Raised Funds Allocation</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Configure how tokens will be distributed and how raised funds will be allocated to team, development, and marketing.
        </p>
        
        <!-- Token Allocation -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Token Distribution</h3>
          <TokenAllocation
            v-model="formData.distribution"
            :sale-token-symbol="saleTokenSymbol"
            :total-sale-amount="Number(formData.saleParams.totalSaleAmount) || 0"
            :total-supply="Number(formData.saleToken.totalSupply) || 100000000"
          />
        </div>

        <!-- Raised Funds Allocation -->
        <div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Raised Funds Allocation</h3>
          <RaisedFundsAllocation
            v-model="formData.raisedFundsAllocation"
            :soft-cap="formData.saleParams.softCap"
            :hard-cap="formData.saleParams.hardCap"
            :platform-fee-rate="platformFeePercentage"
          />
        </div>
      </div>


      <!-- Step 5: Timeline & DEX Configuration -->
      <div v-if="currentStep === 4" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Timeline & DEX Configuration</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Configure your sale timeline and DEX listing settings.
        </p>

        <!-- Timeline Configuration -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Sale Timeline</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Whitelist Start -->
            <div v-if="formData.saleParams.requiresWhitelist">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Whitelist Start <HelpTooltip>When whitelist registration begins. Users can register for whitelist approval starting at this time. Should be before the actual sale starts.</HelpTooltip></label>
              <input
                v-model="formData.timeline.whitelistStart"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
            </div>

            <!-- Whitelist End -->
            <div v-if="formData.saleParams.requiresWhitelist">
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Whitelist End <HelpTooltip>When whitelist registration closes. No new registrations accepted after this time. Should be before sale starts to allow time for approval.</HelpTooltip></label>
              <input
                v-model="formData.timeline.whitelistEnd"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
            </div>

            <!-- Sale Start -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Sale Start* <HelpTooltip>When the token sale officially begins. Participants can start contributing funds at this time. Ensure adequate time after whitelist ends for processing approvals.</HelpTooltip></label>
              <input
                v-model="formData.timeline.saleStart"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
            </div>

            <!-- Sale End -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Sale End* <HelpTooltip>When the token sale officially ends. No more contributions accepted after this time. Allow sufficient time to reach your funding goals.</HelpTooltip></label>
              <input
                v-model="formData.timeline.saleEnd"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
            </div>

            <!-- Claim Start -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Claim Start* <HelpTooltip>When participants can start claiming their purchased tokens. Usually set after sale ends and successful completion is confirmed.</HelpTooltip></label>
              <input
                v-model="formData.timeline.claimStart"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
            </div>

            <!-- Listing Time -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Listing Time <HelpTooltip>When the token will be listed on DEX platforms for public trading. Typically set after successful sale completion and token distribution.</HelpTooltip></label>
              <input
                v-model="formData.timeline.listingTime"
                type="datetime-local"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              />
            </div>
          </div>

          <!-- Timeline Validation Messages -->
          <div v-if="timelineValidation.length > 0" class="mt-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
            <div class="flex items-start space-x-2">
              <AlertTriangleIcon class="h-5 w-5 text-yellow-600 dark:text-yellow-400 mt-0.5" />
              <div>
                <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-1">Timeline Validation Issues</p>
                <ul class="text-sm text-yellow-700 dark:text-yellow-300 space-y-1">
                  <li v-for="issue in timelineValidation" :key="issue" class="flex items-center">
                    <span class="w-1.5 h-1.5 bg-yellow-400 rounded-full mr-2"></span>
                    {{ issue }}
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <!-- DEX Listing Configuration -->
        <div class="mt-8 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
          <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">Multi-DEX Listing Configuration</h3>
          <p class="text-sm text-blue-700 dark:text-blue-300 mb-4">Configure automatic listing on multiple DEX platforms with smart liquidity allocation</p>
          
          <!-- Global Settings -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <!-- Listing Price -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Listing Price* <HelpTooltip>Initial price per token when listed on DEX platforms. This should be strategic - often set at or slightly above the sale price to prevent immediate dumps.</HelpTooltip></label>
              <div class="relative">
                <NumberInput
                  v-model="formData.dexConfig.listingPrice"
                  :options="ICTOMasks.price(8)"
                  placeholder="0.1"
                  :suffix="purchaseTokenSymbol"
                  @update:modelValue="updateLiquidityCalculations"
                />
              </div>
              <p class="text-xs text-gray-500 mt-1">Base price for listing across all DEX platforms</p>
            </div>

            <!-- Total Liquidity Amount -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Total Initial Liquidity* <HelpTooltip>Total amount of your tokens to provide as liquidity across all DEX platforms. Higher liquidity reduces price volatility and improves trading experience.</HelpTooltip></label>
              <div class="relative">
                <NumberInput
                  v-model="formData.dexConfig.totalLiquidityToken"
                  :options="ICTOMasks.tokenAmount(8)"
                  placeholder="10000"
                  :suffix="saleTokenSymbol"
                  @update:modelValue="redistributeLiquidity"
                />
              </div>
              <p class="text-xs text-gray-500 mt-1">Total {{ saleTokenSymbol }} to be allocated across selected DEXs</p>
            </div>

            <!-- Liquidity Lock Period -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Liquidity Lock Period <HelpTooltip>How long liquidity tokens will be locked to prevent immediate withdrawal. Longer lock periods increase investor confidence and price stability. Common range: 30-365 days.</HelpTooltip></label>
              <div class="relative">
                <NumberInput
                  v-model="formData.dexConfig.liquidityLockDays"
                  :options="ICTOMasks.integer()"
                  placeholder="180"
                  suffix="days"
                />
              </div>
            </div>

            <!-- Auto-list on DEX -->
            <div>
              <div class="flex items-center space-x-3 mb-2">
                <input
                  v-model="formData.dexConfig.autoList"
                  type="checkbox"
                  :id="uniqueIds.autoList"
                  class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                />
                <label :for="uniqueIds.autoList" class="text-sm font-medium text-gray-700 dark:text-gray-300">
                  Enable Multi-DEX Auto-listing <HelpTooltip>Automatically list your token on selected DEX platforms after sale completion. Saves time and ensures immediate trading availability for participants.</HelpTooltip>
                </label>
              </div>
              <p class="text-xs text-gray-500">Automatically list on selected DEX platforms after sale ends</p>
            </div>
          </div>

          <!-- DEX Platform Selection -->
          <div class="space-y-4">
            <h4 class="text-md font-semibold text-gray-900 dark:text-white mb-3">DEX Platform Selection</h4>
            
            <div 
              v-for="dex in availableDEXs" 
              :key="dex.id"
              class="border border-gray-200 dark:border-gray-700 rounded-lg p-4"
              :class="{ 'bg-blue-50 dark:bg-blue-900/10 border-blue-300 dark:border-blue-700': dex.enabled }"
            >
              <div class="flex items-start justify-between">
                <!-- DEX Info -->
                <div class="flex items-center space-x-3">
                  <input
                    v-model="dex.enabled"
                    type="checkbox"
                    :id="`dex-${dex.id}-${uniqueIds.autoList}`"
                    @change="handleDEXToggle(dex)"
                    class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                  />
                  <div>
                    <label :for="`dex-${dex.id}-${uniqueIds.autoList}`" class="text-sm font-medium text-gray-900 dark:text-white">
                      {{ dex.name }}
                    </label>
                    <p class="text-xs text-gray-500">{{ dex.description }}</p>
                  </div>
                </div>

                <!-- Allocation Percentage -->
                <div v-if="dex.enabled" class="flex items-center space-x-2">
                  <label class="text-xs text-gray-500">Share:</label>
                  <div class="relative">
                    <NumberInput
                      v-model="dex.allocationPercentage"
                      :options="{ decimals: 1, min: 0, max: 100 }"
                      placeholder="50"
                      suffix="%"
                      class="w-20"
                      @update:modelValue="redistributeLiquidity"
                    />
                  </div>
                </div>
              </div>

              <!-- DEX-specific Configuration -->
              <div v-if="dex.enabled" class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4 pl-7 border-l-2 border-blue-300">
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ saleTokenSymbol }} Liquidity</label>
                  <div class="text-sm font-medium text-gray-900 dark:text-white">
                    {{ formatNumber(dex.calculatedTokenLiquidity) }} {{ saleTokenSymbol }}
                  </div>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">{{ purchaseTokenSymbol }} Liquidity</label>
                  <div class="text-sm font-medium text-gray-900 dark:text-white">
                    {{ formatNumber(dex.calculatedPurchaseLiquidity) }} {{ purchaseTokenSymbol }}
                  </div>
                </div>
                <div v-if="dex.fees">
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Platform Fees</label>
                  <div class="text-xs text-gray-600 dark:text-gray-400">
                    {{ dex.fees.listing }}% listing + {{ dex.fees.transaction }}% transaction
                  </div>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-700 dark:text-gray-300 mb-1">Estimated TVL</label>
                  <div class="text-sm font-semibold text-green-600 dark:text-green-400">
                    ${{ formatNumber((dex.calculatedTokenLiquidity * (parseFloat(formData.dexConfig.listingPrice) || 0) * 2)) }}
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Summary -->
          <div v-if="enabledDEXCount > 0" class="mt-6 p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg">
            <h5 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">Liquidity Distribution Summary</h5>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <span class="text-gray-500">Total Platforms:</span>
                <span class="ml-2 font-medium">{{ enabledDEXCount }}</span>
              </div>
              <div>
                <span class="text-gray-500">Total {{ purchaseTokenSymbol }} Required:</span>
                <span class="ml-2 font-medium text-blue-600">{{ formatNumber(totalPurchaseLiquidityRequired) }} {{ purchaseTokenSymbol }}</span>
              </div>
              <div>
                <span class="text-gray-500">Est. Total TVL:</span>
                <span class="ml-2 font-medium text-green-600">${{ formatNumber(estimatedTotalTVL) }}</span>
              </div>
            </div>
            
            <!-- Warnings and Validations -->
            <div class="space-y-2 mt-3">
              <!-- Allocation Warning -->
              <div v-if="allocationPercentageTotal !== 100" class="p-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm">
                <div class="flex items-center space-x-2">
                  <AlertTriangleIcon class="h-4 w-4 text-yellow-600" />
                  <span class="text-yellow-800 dark:text-yellow-200">
                    Allocation percentages must total 100% (currently {{ allocationPercentageTotal.toFixed(1) }}%)
                  </span>
                </div>
              </div>

              <!-- Liquidity Critical Issues -->
              <div v-for="issue in liquidityValidation" :key="issue" class="p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded text-sm">
                <div class="flex items-center space-x-2">
                  <AlertTriangleIcon class="h-4 w-4 text-red-600" />
                  <span class="text-red-800 dark:text-red-200">{{ issue }}</span>
                </div>
              </div>

              <!-- Liquidity Warnings (non-blocking) -->
              <div v-for="warning in liquidityWarnings" :key="warning" class="p-2 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded text-sm">
                <div class="flex items-center space-x-2">
                  <AlertTriangleIcon class="h-4 w-4 text-amber-600" />
                  <span class="text-amber-800 dark:text-amber-200">{{ warning }}</span>
                </div>
              </div>

              <!-- Fees Breakdown -->
              <div v-if="enabledDEXCount > 0 && totalFeesEstimate > 0" class="p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded">
                <h6 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">Fees Breakdown</h6>
                <div class="grid grid-cols-2 gap-2 text-xs">
                  <div>
                    <span class="text-blue-700 dark:text-blue-300">Platform Fee ({{ platformFeePercentage }}%):</span>
                    <span class="ml-1 font-medium">{{ formatNumber(hardCapAmount * (platformFeePercentage / 100)) }} {{ purchaseTokenSymbol }}</span>
                  </div>
                  <div>
                    <span class="text-blue-700 dark:text-blue-300">DEX Fees:</span>
                    <span class="ml-1 font-medium">{{ formatNumber(dexFeesTotal) }} {{ purchaseTokenSymbol }}</span>
                  </div>
                  <div class="col-span-2 pt-1 border-t border-blue-200 dark:border-blue-700">
                    <span class="text-blue-700 dark:text-blue-300">Remaining after fees & liquidity:</span>
                    <span class="ml-1 font-medium" :class="raisedFundsAfterFees.availableForLiquidity >= 0 ? 'text-green-600' : 'text-red-600'">
                      {{ formatNumber(raisedFundsAfterFees.availableForLiquidity) }} {{ purchaseTokenSymbol }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>

      <!-- Step 5: Terms & Conditions -->
      <div v-if="currentStep === 5" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Launch Overview & Terms</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Review your launch configuration and accept the terms and conditions before launching your project.
        </p>

        <!-- Launch Overview -->
        <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-xl p-6 border border-blue-200 dark:border-blue-700 mb-8">
          <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">🚀 Launch Overview</h3>
          
          <!-- Project Summary -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div class="bg-white dark:bg-gray-800 rounded-lg p-4">
              <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Project Information</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Project Name:</span>
                  <span class="font-medium">{{ formData.projectInfo.name || 'Not specified' }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Category:</span>
                  <span class="font-medium">{{ formData.projectInfo.category || 'Not specified' }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Token Name:</span>
                  <span class="font-medium">{{ formData.saleToken.name || 'Not specified' }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Token Symbol:</span>
                  <span class="font-medium">{{ formData.saleToken.symbol || 'Not specified' }}</span>
                </div>
              </div>
            </div>
            
            <div class="bg-white dark:bg-gray-800 rounded-lg p-4">
              <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Sale Configuration</h4>
              <div class="space-y-2 text-sm">
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Sale Type:</span>
                  <span class="font-medium">{{ formData.saleParams.saleType }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Token Price:</span>
                  <span class="font-medium">{{ formData.saleParams.tokenPrice || '0' }} {{ purchaseTokenSymbol }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Soft Cap:</span>
                  <span class="font-medium">{{ formatNumber(formData.saleParams.softCap || 0) }} {{ purchaseTokenSymbol }}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-gray-600 dark:text-gray-400">Hard Cap:</span>
                  <span class="font-medium">{{ formatNumber(formData.saleParams.hardCap || 0) }} {{ purchaseTokenSymbol }}</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Token Allocation Overview -->
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-6">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Chart Section -->
              <div>
                <PieChart
                  title="Token Distribution"
                  :chart-data="overviewTokenChartData"
                  :show-values="true"
                  :value-unit="saleTokenSymbol"
                  center-label="Total Supply"
                  :total-value="Number(formData.saleToken.totalSupply) || 0"
                />
              </div>
              
              <!-- Summary Section -->
              <div class="space-y-4">
                <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Token Allocation Summary</h4>
                <div class="space-y-3">
                  <div v-for="(allocation, index) in formData.distribution" :key="index" class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full" :style="{ backgroundColor: getAllocationColor(index) }"></div>
                      <div>
                        <div class="font-medium text-gray-900 dark:text-white">{{ allocation.name }}</div>
                        <div class="text-xs text-gray-500 dark:text-gray-400">{{ allocation.percentage }}% of total supply</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-gray-900 dark:text-white">{{ formatNumber(allocation.totalAmount) }}</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">{{ saleTokenSymbol }}</div>
                    </div>
                  </div>
                  
                  <div v-if="remainingAllocation > 0" class="flex items-center justify-between p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full bg-gray-400"></div>
                      <div>
                        <div class="font-medium text-blue-900 dark:text-blue-100">Auto Treasury</div>
                        <div class="text-xs text-blue-600 dark:text-blue-400">{{ ((remainingAllocation / Number(formData.saleToken.totalSupply)) * 100).toFixed(1) }}% unallocated</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-blue-900 dark:text-blue-100">{{ formatNumber(remainingAllocation) }}</div>
                      <div class="text-xs text-blue-600 dark:text-blue-400">{{ saleTokenSymbol }}</div>
                    </div>
                  </div>
                </div>
                
                <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
                  <div class="flex justify-between text-sm mb-2">
                    <span class="text-gray-600 dark:text-gray-400">Total Allocated:</span>
                    <span class="font-medium">{{ formatNumber(totalAllocationAmount) }} {{ saleTokenSymbol }}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">Total Supply:</span>
                    <span class="font-medium">{{ formatNumber(formData.saleToken.totalSupply || 0) }} {{ saleTokenSymbol }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Raised Funds Allocation -->
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-6" v-if="hardCapAmount > 0">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Chart Section -->
              <div>
                <PieChart
                  title="Raised Funds Distribution"
                  :chart-data="overviewRaisedFundsChartData"
                  :show-values="true"
                  :value-unit="purchaseTokenSymbol"
                  center-label="Hard Cap"
                  :total-value="hardCapAmount"
                />
              </div>
              
              <!-- Summary Section -->
              <div class="space-y-4">
                <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Raised Funds Allocation</h4>
                <div class="space-y-3">
                  <div class="flex items-center justify-between p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full bg-blue-500"></div>
                      <div>
                        <div class="font-medium text-blue-900 dark:text-blue-100">Team</div>
                        <div class="text-xs text-blue-600 dark:text-blue-400">{{ teamAllocationPercentage }}% of raised funds</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-blue-900 dark:text-blue-100">{{ formatNumber(Number(formData.raisedFundsAllocation.teamAllocation) || 0) }}</div>
                      <div class="text-xs text-blue-600 dark:text-blue-400">{{ purchaseTokenSymbol }}</div>
                    </div>
                  </div>
                  
                  <div class="flex items-center justify-between p-3 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full bg-green-500"></div>
                      <div>
                        <div class="font-medium text-green-900 dark:text-green-100">Development</div>
                        <div class="text-xs text-green-600 dark:text-green-400">{{ developmentAllocationPercentage }}% of raised funds</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-green-900 dark:text-green-100">{{ formatNumber(Number(formData.raisedFundsAllocation.developmentFund) || 0) }}</div>
                      <div class="text-xs text-green-600 dark:text-green-400">{{ purchaseTokenSymbol }}</div>
                    </div>
                  </div>
                  
                  <div class="flex items-center justify-between p-3 bg-purple-50 dark:bg-purple-900/20 rounded-lg border border-purple-200 dark:border-purple-800">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full bg-purple-500"></div>
                      <div>
                        <div class="font-medium text-purple-900 dark:text-purple-100">Marketing</div>
                        <div class="text-xs text-purple-600 dark:text-purple-400">{{ marketingAllocationPercentage }}% of raised funds</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-purple-900 dark:text-purple-100">{{ formatNumber(Number(formData.raisedFundsAllocation.marketingFund) || 0) }}</div>
                      <div class="text-xs text-purple-600 dark:text-purple-400">{{ purchaseTokenSymbol }}</div>
                    </div>
                  </div>
                  
                  <div v-if="remainingRaisedFunds > 0" class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full bg-gray-400"></div>
                      <div>
                        <div class="font-medium text-gray-900 dark:text-gray-100">DAO Treasury (Auto)</div>
                        <div class="text-xs text-gray-600 dark:text-gray-400">{{ remainingAllocationPercentage.toFixed(1) }}% unallocated</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-gray-900 dark:text-gray-100">{{ formatNumber(remainingRaisedFunds) }}</div>
                      <div class="text-xs text-gray-600 dark:text-gray-400">{{ purchaseTokenSymbol }}</div>
                    </div>
                  </div>
                </div>
                
                <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600 space-y-2">
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">Platform Fee ({{ platformFeePercentage }}%):</span>
                    <span class="text-red-600">-{{ formatNumber(hardCapAmount * (platformFeePercentage / 100)) }} {{ purchaseTokenSymbol }}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">DEX Liquidity:</span>
                    <span class="text-orange-600">-{{ formatNumber(totalPurchaseLiquidityRequired) }} {{ purchaseTokenSymbol }}</span>
                  </div>
                  <div class="flex justify-between text-sm font-medium">
                    <span class="text-gray-600 dark:text-gray-400">Available for Allocation:</span>
                    <span>{{ formatNumber(raisedFundsAfterFees.availableForLiquidity) }} {{ purchaseTokenSymbol }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Timeline Summary -->
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4 mb-6">
            <h4 class="font-semibold text-gray-900 dark:text-white mb-3">Timeline</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <div class="text-gray-600 dark:text-gray-400">Sale Start</div>
                <div class="font-medium">{{ formData.timeline.saleStart ? new Date(formData.timeline.saleStart).toLocaleString() : 'Not set' }}</div>
              </div>
              <div>
                <div class="text-gray-600 dark:text-gray-400">Sale End</div>
                <div class="font-medium">{{ formData.timeline.saleEnd ? new Date(formData.timeline.saleEnd).toLocaleString() : 'Not set' }}</div>
              </div>
              <div>
                <div class="text-gray-600 dark:text-gray-400">Claim Start</div>
                <div class="font-medium">{{ formData.timeline.claimStart ? new Date(formData.timeline.claimStart).toLocaleString() : 'Not set' }}</div>
              </div>
            </div>
          </div>

          <!-- DEX Configuration -->
          <div class="bg-white dark:bg-gray-800 rounded-lg p-4">
            <h4 class="font-semibold text-gray-900 dark:text-white mb-3">DEX Configuration</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Primary Platform:</span>
                <span class="font-medium">{{ formData.dexConfig.platform || 'Not specified' }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Listing Price:</span>
                <span class="font-medium">{{ formData.dexConfig.listingPrice || '0' }} {{ purchaseTokenSymbol }}</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Liquidity Lock Days:</span>
                <span class="font-medium">{{ formData.dexConfig.liquidityLockDays || 0 }} days</span>
              </div>
              <div class="flex justify-between">
                <span class="text-gray-600 dark:text-gray-400">Auto List:</span>
                <span class="font-medium">{{ formData.dexConfig.autoList ? 'Yes' : 'No' }}</span>
              </div>
            </div>
          </div>
        </div>
        
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
          <div class="prose dark:prose-invert max-w-none">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Platform Terms & Conditions</h3>
            <div class="space-y-4 text-sm text-gray-700 dark:text-gray-300">
              <p>By proceeding with this token launch, you acknowledge and agree to the following:</p>
              <ul class="list-disc list-inside space-y-2 ml-4">
                <li>All information provided is accurate and truthful</li>
                <li>You have the necessary rights and permissions to conduct this token sale</li>
                <li>You comply with all applicable laws and regulations in your jurisdiction</li>
                <li>Platform fees (2%) will be deducted from raised funds</li>
                <li>DEX listing fees and liquidity requirements are your responsibility</li>
                <li>The platform is not responsible for the success or failure of your project</li>
                <li>You understand the risks associated with token launches and DeFi protocols</li>
              </ul>
            </div>
          </div>
          
          <div class="border-t border-gray-200 dark:border-gray-600 pt-6 mt-6">
            <div class="flex items-start space-x-3">
              <input
                v-model="acceptTerms"
                type="checkbox"
                :id="uniqueIds.acceptTerms"
                class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600 mt-0.5"
                required
              />
              <label :for="uniqueIds.acceptTerms" class="text-sm text-gray-700 dark:text-gray-300">
                I understand and accept the terms and conditions for launching a token sale on this platform. 
                I confirm that all information provided is accurate and that I have the necessary rights to conduct this token sale.
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- Form Actions -->
      <div class="border-t border-gray-200 dark:border-gray-700 px-6 py-4">
        <div class="flex items-center justify-between">
          <button
            v-if="currentStep > 0"
            @click="previousStep"
            type="button"
            class="inline-flex items-center px-4 py-2 border border-gray-300 dark:border-gray-600 text-sm font-medium rounded-lg text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-colors"
          >
            <ArrowLeftIcon class="h-4 w-4 mr-2" />
            Previous
          </button>
          <div v-else></div>
          
          <div class="flex items-center space-x-3">
            <button
              type="button"
              @click="$router.push('/launchpad')"
              class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
            >
              Cancel
            </button>
            
            <button
              v-if="currentStep < steps.length - 1"
              @click="nextStep"
              :disabled="!canProceed"
              type="button"
              class="inline-flex items-center px-6 py-2 bg-gradient-to-r from-yellow-600 to-amber-600 text-white font-medium rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              Next
              <ArrowRightIcon class="h-4 w-4 ml-2" />
            </button>
            
            <button
              v-else
              @click="createLaunchpad"
              :disabled="!canLaunch || isCreating"
              type="button"
              class="inline-flex items-center px-6 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white font-medium rounded-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg hover:shadow-xl transform hover:-translate-y-0.5"
            >
              <div v-if="isCreating" class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2"></div>
              <RocketIcon v-else class="h-4 w-4 mr-2" />
              {{ isCreating ? 'Launching...' : 'Launch Project' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<style scoped>
/* Custom slider styling */
.slider-thumb::-webkit-slider-thumb {
  appearance: none;
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #10B981, #059669);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(16, 185, 129, 0.4);
  border: 2px solid white;
}

.slider-thumb::-moz-range-thumb {
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #10B981, #059669);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(16, 185, 129, 0.4);
  border: 2px solid white;
}

.slider-thumb::-webkit-slider-track {
  height: 4px;
  border-radius: 2px;
  background: linear-gradient(to right, #D1FAE5 0%, #10B981 100%);
}

.slider-thumb::-moz-range-track {
  height: 4px;
  border-radius: 2px;
  background: linear-gradient(to right, #D1FAE5 0%, #10B981 100%);
}

.slider-thumb:focus {
  outline: none;
  box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.3);
}

.dark .slider-thumb::-webkit-slider-track {
  background: linear-gradient(to right, #065F46 0%, #10B981 100%);
}

.dark .slider-thumb::-moz-range-track {
  background: linear-gradient(to right, #065F46 0%, #10B981 100%);
}
</style>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import { 
  ArrowLeftIcon, 
  ArrowRightIcon, 
  CheckIcon, 
  RocketIcon, 
  XIcon,
  AlertTriangleIcon,
  ImageIcon,
  UploadIcon,
  PlusIcon
} from 'lucide-vue-next'
// Types are imported through other composables and services
import { Principal } from '@dfinity/principal'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import TokenAllocation from '@/components/launchpad/TokenAllocation.vue'
import RaisedFundsAllocation from '@/components/launchpad/RaisedFundsAllocation.vue'
import LaunchpadTemplateSelector from '@/components/launchpad/LaunchpadTemplateSelector.vue'
import PieChart from '@/components/common/PieChart.vue'
import VueApexCharts from 'vue3-apexcharts'
import { InputMask, ICTOMasks } from '@/utils/inputMask'
import NumberInput from '@/components/common/NumberInput.vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import { useLaunchpadService } from '@/composables/useLaunchpadService'
import { useUniqueId } from '@/composables/useUniqueId'
import type { LaunchpadTemplate } from '@/data/launchpadTemplates'

const router = useRouter()
const { createLaunchpad: createLaunchpadService, isCreating } = useLaunchpadService()

// Breadcrumb configuration
const breadcrumbItems = [
  { label: 'Launchpad', to: '/launchpad' },
  { label: 'Create New Launch', to: '/launchpad/create' }
]

// Steps configuration
const steps = [
  { id: 'template', title: 'Template', description: 'Choose launchpad template' },
  { id: 'project', title: 'Project Info', description: 'Basic project details' },
  { id: 'token', title: 'Token Config', description: 'Token configuration' },
  { id: 'allocation', title: 'Allocation', description: 'Token distribution' },
  { id: 'timeline', title: 'Timeline & Funds', description: 'Schedule, DEX & raised funds' },
  { id: 'terms', title: 'Terms', description: 'Accept terms and conditions' }
]

// State
const currentStep = ref(0)
const acceptTerms = ref(false)
const tagsInput = ref('')
const purchaseTokenInfo = ref<any>(null)
const selectedPurchaseToken = ref('ryjl3-tyaaa-aaaaa-aaaba-cai')
const logoPreview = ref('')
const logoError = ref('')
const fileInput = ref<HTMLInputElement | null>(null)
const csvFileName = ref('')
const csvFileInput = ref<HTMLInputElement | null>(null)
const showTeamDetails = ref(false)
const previewRaisedAmount = ref(0)

// Generate unique IDs for form elements
const uniqueIds = {
  isKYCed: useUniqueId('is-kyced'),
  isAudited: useUniqueId('is-audited'),
  requiresWhitelist: useUniqueId('requires-whitelist'),
  requiresKYC: useUniqueId('requires-kyc'),
  autoList: useUniqueId('auto-list'),
  acceptTerms: useUniqueId('accept-terms')
}

// Percentage-based allocation state
const teamAllocationPercentage = ref(30)
const developmentAllocationPercentage = ref(20)
const marketingAllocationPercentage = ref(10)

// Predefined purchase token options
const purchaseTokenOptions = [
  {
    value: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
    label: 'ICP (Internet Computer)',
    symbol: 'ICP',
    decimals: 8,
    fee: 10000,
    logo: 'https://cryptologos.cc/logos/internet-computer-icp-logo.png'
  },
  {
    value: 'xevnm-gaaaa-aaaar-qafnq-cai',
    label: 'ckUSDT (Chain Key USDT)',
    symbol: 'ckUSDT',
    decimals: 6,
    fee: 2000000,
    logo: 'https://cryptologos.cc/logos/tether-usdt-logo.png'
  },
  {
    value: 'mxzaz-hqaaa-aaaar-qaada-cai',
    label: 'ckBTC (Chain Key Bitcoin)', 
    symbol: 'ckBTC',
    decimals: 8,
    fee: 10,
    logo: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png'
  },
  {
    value: 'ss2fx-dyaaa-aaaar-qacoq-cai',
    label: 'ckETH (Chain Key Ethereum)',
    symbol: 'ckETH', 
    decimals: 18,
    fee: 2000000000000000,
    logo: 'https://cryptologos.cc/logos/ethereum-eth-logo.png'
  }
]

// Form data
const formData = ref({
  distribution: [] as any[],
  projectInfo: {
    name: '',
    description: '',
    logo: '',
    banner: '',
    website: '',
    twitter: '',
    telegram: '',
    discord: '',
    github: '',
    documentation: '',
    whitepaper: '',
    auditReport: '',
    category: '' as string,
    tags: [] as string[],
    kycProvider: '',
    isKYCed: false,
    isAudited: false,
    metadata: []
  } as any,
  saleToken: {
    name: '',
    symbol: '',
    decimals: 8,
    totalSupply: '100000000',
    transferFee: '10000',
    standard: 'ICRC1',
    logo: '',
    description: '',
    website: ''
  } as any,
  purchaseToken: {
    canisterId: '',
    name: '',
    symbol: '',
    decimals: 8,
    totalSupply: BigInt(0),
    transferFee: BigInt(0),
    standard: 'ICRC1',
    logo: '',
    description: '',
    website: ''
  } as any,
  saleParams: {
    saleType: 'FairLaunch' as string,
    allocationMethod: 'FirstComeFirstServe' as string,
    totalSaleAmount: '',
    tokenPrice: '',
    softCap: '',
    hardCap: '',
    minContribution: '',
    maxContribution: '',
    maxParticipants: '',
    requiresWhitelist: false,
    requiresKYC: false,
    blockIdRequired: BigInt(0),
    restrictedRegions: [],
    whitelistAddresses: [] as { principal: string; allocation?: string }[],
    whitelistMode: 'closed' as string
  },
  timeline: {
    saleStart: '',
    saleEnd: '',
    whitelistStart: '',
    whitelistEnd: '',
    claimStart: '',
    listingTime: '',
    vestingStart: '',
    daoActivation: '',
    createdAt: BigInt(0)
  },
  dexConfig: {
    platform: '',
    listingPrice: '',
    totalLiquidityToken: '',
    initialLiquidityToken: '',
    initialLiquidityPurchase: '',
    liquidityLockDays: 180,
    autoList: false
  },
  raisedFundsAllocation: {
    teamAllocation: '',
    developmentFund: '',
    marketingFund: '',
    teamRecipients: [] as {
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: {
        cliffDays: number
        durationDays: number
        releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
        immediateRelease: number
      }
    }[],
    developmentRecipients: [] as {
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: {
        cliffDays: number
        durationDays: number
        releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
        immediateRelease: number
      }
    }[],
    marketingRecipients: [] as {
      principal: string
      percentage: number
      name?: string
      vestingEnabled: boolean
      vestingSchedule?: {
        cliffDays: number
        durationDays: number
        releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
        immediateRelease: number
      }
    }[],
    customAllocations: [] as {
      name: string
      amount: string
      recipients: { principal: string; percentage: number }[]
      vestingSchedule: {
        type: string
        cliff: number
        duration: number
        releases: number
      } | null
    }[]
  }
})

// Multi-DEX Configuration
interface DEXPlatform {
  id: string
  name: string
  description: string
  enabled: boolean
  allocationPercentage: number
  calculatedTokenLiquidity: number
  calculatedPurchaseLiquidity: number
  fees?: {
    listing: number
    transaction: number
  }
}

const availableDEXs = ref<DEXPlatform[]>([
  {
    id: 'icpswap',
    name: 'ICPSwap',
    description: 'Leading DEX on Internet Computer with deep liquidity pools',
    enabled: true,
    allocationPercentage: 60,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.3,
      transaction: 0.3
    }
  },
  {
    id: 'kongswap',
    name: 'KongSwap',
    description: 'Fast and efficient DEX with competitive fees',
    enabled: true,
    allocationPercentage: 40,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.25,
      transaction: 0.25
    }
  },
  {
    id: 'sonic',
    name: 'Sonic DEX',
    description: 'Advanced AMM with innovative features',
    enabled: false,
    allocationPercentage: 0,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.3,
      transaction: 0.3
    }
  },
  {
    id: 'icdex',
    name: 'ICDex',
    description: 'Order-book based decentralized exchange',
    enabled: false,
    allocationPercentage: 0,
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.2,
      transaction: 0.2
    }
  }
])

// Computed properties
const saleTokenSymbol = computed(() => formData.value.saleToken.symbol || 'TOKEN')
const purchaseTokenSymbol = computed(() => purchaseTokenInfo.value?.symbol || 'ICP')

// Chart data for overview
const overviewTokenChartData = computed(() => {
  if (!formData.value.distribution || formData.value.distribution.length === 0) {
    return {
      labels: [],
      data: [],
      values: [],
      colors: [],
      percentages: []
    }
  }
  
  const colors = [
    '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
    '#06B6D4', '#84CC16', '#F97316', '#EC4899', '#6366F1'
  ]
  
  const labels = formData.value.distribution.map(a => a.name || 'Unnamed')
  const data = formData.value.distribution.map(a => Number(a.percentage || 0))
  const values = formData.value.distribution.map(a => Number(a.totalAmount || 0))
  
  // Add unallocated portion if exists
  const totalAllocated = data.reduce((sum, value) => sum + value, 0)
  const unallocatedPercentage = Math.max(0, 100 - totalAllocated)
  const totalSupply = Number(formData.value.saleToken.totalSupply) || 0
  
  if (unallocatedPercentage > 0) {
    labels.push('Auto Treasury')
    data.push(unallocatedPercentage)
    values.push(totalSupply * (unallocatedPercentage / 100))
  }
  
  // Calculate actual percentages
  const total = data.reduce((sum, value) => sum + value, 0)
  const percentages = data.map(value => total > 0 ? Number((value / total * 100).toFixed(1)) : 0)
  
  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages
  }
})

const overviewRaisedFundsChartData = computed(() => {
  const availableForAllocation = hardCapAmount.value - (hardCapAmount.value * (platformFeePercentage.value / 100)) - totalPurchaseLiquidityRequired.value
  
  if (availableForAllocation <= 0) {
    return {
      labels: [],
      data: [],
      values: [],
      colors: [],
      percentages: []
    }
  }
  
  const labels = []
  const data = []
  const values = []
  const colors = ['#3B82F6', '#10B981', '#F59E0B', '#6B7280']
  
  const teamAmount = Number(formData.value.raisedFundsAllocation.teamAllocation) || 0
  const devAmount = Number(formData.value.raisedFundsAllocation.developmentFund) || 0
  const marketingAmount = Number(formData.value.raisedFundsAllocation.marketingFund) || 0
  
  const teamPercentage = availableForAllocation > 0 ? (teamAmount / availableForAllocation) * 100 : 0
  const devPercentage = availableForAllocation > 0 ? (devAmount / availableForAllocation) * 100 : 0
  const marketingPercentage = availableForAllocation > 0 ? (marketingAmount / availableForAllocation) * 100 : 0
  
  if (teamAmount > 0) {
    labels.push('Team')
    data.push(teamPercentage)
    values.push(teamAmount)
  }
  
  if (devAmount > 0) {
    labels.push('Development')
    data.push(devPercentage)
    values.push(devAmount)
  }
  
  if (marketingAmount > 0) {
    labels.push('Marketing')
    data.push(marketingPercentage)
    values.push(marketingAmount)
  }
  
  const totalAllocated = teamAmount + devAmount + marketingAmount
  const remaining = availableForAllocation - totalAllocated
  
  if (remaining > 0) {
    const remainingPercentage = (remaining / availableForAllocation) * 100
    labels.push('DAO Treasury')
    data.push(remainingPercentage)
    values.push(remaining)
  }
  
  // Calculate actual percentages
  const total = data.reduce((sum, value) => sum + value, 0)
  const percentages = data.map(value => total > 0 ? Number((value / total * 100).toFixed(1)) : 0)
  
  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages
  }
})

// Multi-DEX computed properties
const enabledDEXCount = computed(() => 
  availableDEXs.value.filter(dex => dex.enabled).length
)

const allocationPercentageTotal = computed(() => 
  availableDEXs.value.reduce((sum, dex) => sum + (dex.enabled ? dex.allocationPercentage : 0), 0)
)

const totalPurchaseLiquidityRequired = computed(() => 
  availableDEXs.value.reduce((sum, dex) => sum + (dex.enabled ? dex.calculatedPurchaseLiquidity : 0), 0)
)

const estimatedTotalTVL = computed(() => {
  const listingPrice = Number(formData.value.dexConfig.listingPrice) || 0
  return availableDEXs.value.reduce((sum, dex) => {
    if (dex.enabled) {
      return sum + (dex.calculatedTokenLiquidity * listingPrice * 2)
    }
    return sum
  }, 0)
})

// Raised Funds Calculations
const softCapAmount = computed(() => Number(formData.value.saleParams.softCap) || 0)
const hardCapAmount = computed(() => Number(formData.value.saleParams.hardCap) || 0)

const platformFeePercentage = computed(() => 2.0) // 2% platform fee
const dexFeesTotal = computed(() => {
  return availableDEXs.value.reduce((sum, dex) => {
    if (dex.enabled && dex.fees) {
      return sum + (dex.calculatedPurchaseLiquidity * (dex.fees.listing / 100))
    }
    return sum
  }, 0)
})

const totalFeesEstimate = computed(() => {
  const platformFee = hardCapAmount.value * (platformFeePercentage.value / 100)
  return platformFee + dexFeesTotal.value
})

const raisedFundsAfterFees = computed(() => {
  return {
    softCap: Math.max(0, softCapAmount.value - totalFeesEstimate.value),
    hardCap: Math.max(0, hardCapAmount.value - totalFeesEstimate.value),
    availableForLiquidity: Math.max(0, hardCapAmount.value - totalFeesEstimate.value - totalPurchaseLiquidityRequired.value)
  }
})

const liquidityValidation = computed(() => {
  const issues: string[] = []
  
  // Only show critical errors that prevent proceeding
  if (totalPurchaseLiquidityRequired.value > hardCapAmount.value) {
    issues.push(`DEX liquidity requirement (${formatNumber(totalPurchaseLiquidityRequired.value)} ${purchaseTokenSymbol.value}) exceeds hard cap`)
  }
  
  if (raisedFundsAfterFees.value.availableForLiquidity < 0) {
    issues.push(`Insufficient raised funds after fees and DEX liquidity allocation`)
  }
  
  return issues
})

// Separate warnings that don't block progress
const liquidityWarnings = computed(() => {
  const warnings: string[] = []
  
  if (totalPurchaseLiquidityRequired.value > softCapAmount.value) {
    warnings.push(`DEX liquidity requirement exceeds soft cap - project may not reach minimum funding`)
  }
  
  const liquidityToRaisedRatio = hardCapAmount.value > 0 ? totalPurchaseLiquidityRequired.value / hardCapAmount.value * 100 : 0
  if (liquidityToRaisedRatio > 80) {
    warnings.push(`Very high liquidity allocation (${liquidityToRaisedRatio.toFixed(1)}% of raised funds) - consider reducing`)
  }
  
  return warnings
})

// Recipient Validation
const recipientValidation = computed(() => {
  const issues: string[] = []
  
  // Check Team Allocation
  if (Number(formData.value.raisedFundsAllocation.teamAllocation) > 0 && 
      (!formData.value.raisedFundsAllocation.teamRecipients || 
       formData.value.raisedFundsAllocation.teamRecipients.length === 0)) {
    issues.push('Team allocation requires at least one recipient with vesting details')
  }
  
  // Check Development Fund
  if (Number(formData.value.raisedFundsAllocation.developmentFund) > 0 && 
      (!formData.value.raisedFundsAllocation.developmentRecipients || 
       formData.value.raisedFundsAllocation.developmentRecipients.length === 0)) {
    issues.push('Development fund requires at least one recipient with vesting details')
  }
  
  // Check Marketing Fund
  if (Number(formData.value.raisedFundsAllocation.marketingFund) > 0 && 
      (!formData.value.raisedFundsAllocation.marketingRecipients || 
       formData.value.raisedFundsAllocation.marketingRecipients.length === 0)) {
    issues.push('Marketing fund requires at least one recipient with vesting details')
  }
  
  // Validate recipient details
  formData.value.raisedFundsAllocation.teamRecipients?.forEach((recipient, index) => {
    if (!recipient.principal || !recipient.principal.trim()) {
      issues.push(`Team recipient ${index + 1} requires a valid Principal ID`)
    }
    if (recipient.percentage <= 0 || recipient.percentage > 100) {
      issues.push(`Team recipient ${index + 1} percentage must be between 1-100%`)
    }
  })
  
  formData.value.raisedFundsAllocation.developmentRecipients?.forEach((recipient, index) => {
    if (!recipient.principal || !recipient.principal.trim()) {
      issues.push(`Development recipient ${index + 1} requires a valid Principal ID`)
    }
    if (recipient.percentage <= 0 || recipient.percentage > 100) {
      issues.push(`Development recipient ${index + 1} percentage must be between 1-100%`)
    }
  })
  
  formData.value.raisedFundsAllocation.marketingRecipients?.forEach((recipient, index) => {
    if (!recipient.principal || !recipient.principal.trim()) {
      issues.push(`Marketing recipient ${index + 1} requires a valid Principal ID`)
    }
    if (recipient.percentage <= 0 || recipient.percentage > 100) {
      issues.push(`Marketing recipient ${index + 1} percentage must be between 1-100%`)
    }
  })
  
  return issues
})

// Raised Funds Allocation Computed Properties
const totalRaisedAllocated = computed(() => {
  const team = Number(formData.value.raisedFundsAllocation.teamAllocation) || 0
  const dev = Number(formData.value.raisedFundsAllocation.developmentFund) || 0
  const marketing = Number(formData.value.raisedFundsAllocation.marketingFund) || 0
  const custom = formData.value.raisedFundsAllocation.customAllocations?.reduce(
    (sum, allocation) => sum + (Number(allocation.amount) || 0), 0
  ) || 0
  return team + dev + marketing + custom
})

const remainingRaisedFunds = computed(() => {
  return Math.max(0, raisedFundsAfterFees.value.availableForLiquidity) - totalRaisedAllocated.value
})

// Allocation chart data
const totalAllocationAmount = computed(() => {
  if (!formData.value.distribution) return 0
  return formData.value.distribution.reduce((sum: number, allocation: any) => {
    return sum + (Number(allocation.totalAmount) || 0)
  }, 0)
})

const remainingAllocation = computed(() => {
  return Number(formData.value.saleToken.totalSupply) - totalAllocationAmount.value
})

// Auto Treasury Calculation
const autoTreasuryAllocation = computed(() => {
  const remainingTokens = remainingAllocation.value
  
  if (remainingTokens > 0) {
    return {
      name: 'Treasury (Auto)',
      percentage: (remainingTokens / Number(formData.value.saleToken.totalSupply)) * 100,
      totalAmount: remainingTokens.toString(),
      recipients: { DAO: null }, // Auto-assigned to DAO
      vestingSchedule: null, // Immediate unlock to DAO
      isAuto: true
    }
  }
  return null
})

// Enhanced allocation with auto treasury
const enhancedAllocation = computed(() => {
  const allocations = [...(formData.value.distribution || [])]
  
  if (autoTreasuryAllocation.value) {
    allocations.push(autoTreasuryAllocation.value)
  }
  
  return allocations
})

// Auto Raised Funds Calculation  
const autoRaisedFundsTreasury = computed(() => {
  const totalAllocated = totalRaisedAllocated.value
  const remaining = remainingRaisedFunds.value
  
  if (remaining > 0) {
    return {
      name: 'Treasury (Auto)',
      amount: remaining.toString(),
      percentage: (remaining / raisedFundsAfterFees.value.hardCap) * 100,
      recipients: [{ principal: 'DAO', percentage: 100 }],
      vestingSchedule: null, // Immediate to DAO
      isAuto: true
    }
  }
  return null
})

const allocationChartSeries = computed(() => {
  if (!formData.value.distribution) return []
  return formData.value.distribution.map((allocation: any) => Number(allocation.totalAmount) || 0)
})

const allocationChartOptions = computed(() => ({
  chart: {
    type: 'pie',
    fontFamily: 'Outfit, sans-serif',
  },
  labels: formData.value.distribution?.map((allocation: any) => allocation.name) || [],
  colors: [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
    '#84CC16', // Lime
    '#F97316', // Orange
    '#EC4899', // Pink
    '#6366F1', // Indigo
  ],
  legend: {
    show: false // We'll show custom legend
  },
  tooltip: {
    y: {
      formatter: (value: number) => formatNumber(value) + ' ' + saleTokenSymbol.value
    }
  },
  plotOptions: {
    pie: {
      donut: {
        size: '40%'
      }
    }
  },
  responsive: [
    {
      breakpoint: 480,
      options: {
        chart: {
          width: 200
        }
      }
    }
  ]
}))

// Preview Allocations with Interactive Slider
const previewAllocations = computed(() => {
  const currentRaised = previewRaisedAmount.value || hardCapAmount.value
  const platformFee = currentRaised * (platformFeePercentage.value / 100)
  const dexLiquidity = (totalPurchaseLiquidityRequired.value / hardCapAmount.value) * currentRaised
  const availableForAllocation = Math.max(0, currentRaised - platformFee - dexLiquidity)
  
  return {
    totalRaised: currentRaised,
    platformFee,
    dexLiquidity,
    availableForAllocation,
    teamAllocations: {
      team: (Number(formData.value.raisedFundsAllocation.teamAllocation) / hardCapAmount.value) * availableForAllocation,
      development: (Number(formData.value.raisedFundsAllocation.developmentFund) / hardCapAmount.value) * availableForAllocation,
      marketing: (Number(formData.value.raisedFundsAllocation.marketingFund) / hardCapAmount.value) * availableForAllocation
    }
  }
})

// Smart Allocation Suggestions
const smartAllocationSuggestions = computed(() => {
  const suggestions: any[] = []
  const totalTeamAllocation = Number(formData.value.raisedFundsAllocation.teamAllocation) + 
                             Number(formData.value.raisedFundsAllocation.developmentFund) + 
                             Number(formData.value.raisedFundsAllocation.marketingFund)
  
  const availableAmount = previewAllocations.value.availableForAllocation
  const allocationPercentage = (totalTeamAllocation / availableAmount) * 100
  
  // High team allocation warning
  if (allocationPercentage > 70) {
    suggestions.push({
      title: 'High Team Allocation',
      description: `${allocationPercentage.toFixed(1)}% of raised funds allocated to team. Consider reducing to increase DAO treasury for sustainability.`,
      action: `Reduce to ~50% (${formatNumber(availableAmount * 0.5)} ${purchaseTokenSymbol.value})`,
      priority: 'high',
      autoFix: () => {
        const recommended = availableAmount * 0.5
        const currentTotal = totalTeamAllocation
        const ratio = recommended / currentTotal
        formData.value.raisedFundsAllocation.teamAllocation = String(Number(formData.value.raisedFundsAllocation.teamAllocation) * ratio)
        formData.value.raisedFundsAllocation.developmentFund = String(Number(formData.value.raisedFundsAllocation.developmentFund) * ratio)
        formData.value.raisedFundsAllocation.marketingFund = String(Number(formData.value.raisedFundsAllocation.marketingFund) * ratio)
      }
    })
  }
  
  // No team recipients warning
  if (Number(formData.value.raisedFundsAllocation.teamAllocation) > 0 && 
      (!formData.value.raisedFundsAllocation.teamRecipients || formData.value.raisedFundsAllocation.teamRecipients.length === 0)) {
    suggestions.push({
      title: 'Missing Team Recipients',
      description: 'Team allocation specified but no recipients configured. Add team members to receive funds.',
      action: 'Configure team member wallet addresses',
      priority: 'high',
      autoFix: false
    })
  }
  
  // Low treasury allocation suggestion
  if (remainingRaisedFunds.value / availableAmount < 0.2) {
    suggestions.push({
      title: 'Low DAO Treasury Allocation',
      description: 'Less than 20% will go to DAO treasury. Consider reducing team allocation to strengthen DAO governance.',
      action: `Increase treasury to ~30% (${formatNumber(availableAmount * 0.3)} ${purchaseTokenSymbol.value})`,
      priority: 'medium',
      autoFix: () => {
        const targetTreasury = availableAmount * 0.3
        const currentRemaining = remainingRaisedFunds.value
        const reduceBy = targetTreasury - currentRemaining
        
        // Proportionally reduce team allocations
        const reductionRatio = reduceBy / totalTeamAllocation
        formData.value.raisedFundsAllocation.teamAllocation = String(Number(formData.value.raisedFundsAllocation.teamAllocation) * (1 - reductionRatio))
        formData.value.raisedFundsAllocation.developmentFund = String(Number(formData.value.raisedFundsAllocation.developmentFund) * (1 - reductionRatio))
        formData.value.raisedFundsAllocation.marketingFund = String(Number(formData.value.raisedFundsAllocation.marketingFund) * (1 - reductionRatio))
      }
    })
  }
  
  // Balanced allocation suggestion
  if (allocationPercentage >= 40 && allocationPercentage <= 60 && remainingRaisedFunds.value > 0) {
    suggestions.push({
      title: 'Well-Balanced Allocation',
      description: 'Your allocation appears balanced between team and DAO treasury, promoting sustainable governance.',
      action: 'No changes needed',
      priority: 'low',
      autoFix: false
    })
  }
  
  return suggestions
})

// Initialize preview amount to hard cap
watch(hardCapAmount, (newVal) => {
  if (newVal && previewRaisedAmount.value === 0) {
    previewRaisedAmount.value = newVal
  }
}, { immediate: true })

// Sync percentage-based allocations with form data
watch(teamAllocationPercentage, (percentage) => {
  const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
  formData.value.raisedFundsAllocation.teamAllocation = String(availableAmount * percentage / 100)
})

watch(developmentAllocationPercentage, (percentage) => {
  const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
  formData.value.raisedFundsAllocation.developmentFund = String(availableAmount * percentage / 100)
})

watch(marketingAllocationPercentage, (percentage) => {
  const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
  formData.value.raisedFundsAllocation.marketingFund = String(availableAmount * percentage / 100)
})

// Computed for total allocation percentages
const totalAllocationPercentage = computed(() => {
  const customTotal = formData.value.raisedFundsAllocation.customAllocations?.reduce((sum, allocation) => {
    const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
    const percentage = availableAmount > 0 ? (Number(allocation.amount) / availableAmount * 100) : 0
    return sum + percentage
  }, 0) || 0
  
  return teamAllocationPercentage.value + 
         developmentAllocationPercentage.value + 
         marketingAllocationPercentage.value + 
         customTotal
})

const remainingAllocationPercentage = computed(() => {
  return Math.max(0, 100 - totalAllocationPercentage.value)
})

const canProceed = computed(() => {
  switch (currentStep.value) {
    case 0: // Template Selection
      return true // Always allow proceeding from template selection
    case 1: // Project Info
      return formData.value.projectInfo.name && 
             formData.value.projectInfo.description && 
             formData.value.projectInfo.category
    case 2: // Token & Sale Config
      return formData.value.saleParams.saleType && 
             formData.value.saleParams.allocationMethod &&
             formData.value.saleParams.totalSaleAmount &&
             formData.value.saleParams.softCap &&
             formData.value.saleParams.hardCap &&
             formData.value.saleParams.minContribution
    case 3: // Token & Raised Funds Allocation
      return formData.value.distribution && formData.value.distribution.length > 0 &&
             remainingRaisedFunds.value >= 0 && // No over-allocation
             recipientValidation.value.length === 0 // All allocations have recipients
    case 4: // Timeline & DEX Configuration
      return formData.value.timeline.saleStart && 
             formData.value.timeline.saleEnd && 
             formData.value.timeline.claimStart &&
             timelineValidation.value.length === 0 &&
             liquidityValidation.value.length === 0
    case 5: // Terms
      return acceptTerms.value
    default:
      return true
  }
})

const canLaunch = computed(() => {
  return canProceed.value && acceptTerms.value
})

const timelineValidation = computed(() => {
  const issues: string[] = []
  const now = new Date()
  
  if (formData.value.timeline.saleStart) {
    const saleStart = new Date(formData.value.timeline.saleStart)
    if (saleStart <= now) {
      issues.push('Sale start must be in the future')
    }
  }
  
  if (formData.value.timeline.saleStart && formData.value.timeline.saleEnd) {
    const saleStart = new Date(formData.value.timeline.saleStart)
    const saleEnd = new Date(formData.value.timeline.saleEnd)
    if (saleEnd <= saleStart) {
      issues.push('Sale end must be after sale start')
    }
  }
  
  if (formData.value.timeline.saleEnd && formData.value.timeline.claimStart) {
    const saleEnd = new Date(formData.value.timeline.saleEnd)
    const claimStart = new Date(formData.value.timeline.claimStart)
    if (claimStart <= saleEnd) {
      issues.push('Claim start should be after sale end')
    }
  }
  
  return issues
})

// Methods
const nextStep = () => {
  if (canProceed.value && currentStep.value < steps.length - 1) {
    currentStep.value++
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
  }
}

// Template loading function
const loadTemplate = (template: LaunchpadTemplate | null) => {
  try {
    // Handle "Start from Scratch" option (template is null)
    if (template === null) {
      toast.success('Starting with blank configuration!')
      return // Don't load any template data, just show success message
    }
    
    // Map flat template data to nested form structure
    const templateData = template.data
    
    // Project Information mapping
    if (templateData.projectName || templateData.description || templateData.website) {
      Object.assign(formData.value.projectInfo, {
        name: templateData.projectName || formData.value.projectInfo.name,
        description: templateData.description || formData.value.projectInfo.description,
        website: templateData.website || formData.value.projectInfo.website,
        twitter: templateData.twitter || formData.value.projectInfo.twitter,
        telegram: templateData.telegram || formData.value.projectInfo.telegram,
        discord: templateData.discord || formData.value.projectInfo.discord,
        whitepaper: templateData.whitepaper || formData.value.projectInfo.whitepaper
      })
    }
    
    // Sale Token mapping
    if (templateData.saleTokenName || templateData.saleTokenSymbol) {
      Object.assign(formData.value.saleToken, {
        name: templateData.saleTokenName || formData.value.saleToken.name,
        symbol: templateData.saleTokenSymbol || formData.value.saleToken.symbol,
        decimals: templateData.saleTokenDecimals ?? formData.value.saleToken.decimals,
        totalSupply: templateData.saleTokenTotalSupply || formData.value.saleToken.totalSupply,
        transferFee: templateData.saleTokenTransferFee || formData.value.saleToken.transferFee,
        description: templateData.saleTokenDescription || formData.value.saleToken.description
      })
    }
    
    // Sale Parameters mapping
    if (templateData.saleType || templateData.tokenPrice) {
      Object.assign(formData.value.saleParams, {
        saleType: templateData.saleType || formData.value.saleParams.saleType,
        allocationMethod: templateData.allocationMethod || formData.value.saleParams.allocationMethod,
        tokenPrice: templateData.tokenPrice || formData.value.saleParams.tokenPrice,
        softCap: templateData.softCap || formData.value.saleParams.softCap,
        hardCap: templateData.hardCap || formData.value.saleParams.hardCap,
        minContribution: templateData.minContribution || formData.value.saleParams.minContribution,
        maxContribution: templateData.maxContribution || formData.value.saleParams.maxContribution,
        totalSaleAmount: templateData.totalSaleAmount || formData.value.saleParams.totalSaleAmount,
        requiresWhitelist: templateData.requiresWhitelist ?? formData.value.saleParams.requiresWhitelist,
        requiresKYC: templateData.requiresKYC ?? formData.value.saleParams.requiresKYC
      })
    }
    
    // Timeline mapping
    if (templateData.saleStart || templateData.saleEnd) {
      Object.assign(formData.value.timeline, {
        saleStart: templateData.saleStart || formData.value.timeline.saleStart,
        saleEnd: templateData.saleEnd || formData.value.timeline.saleEnd,
        claimStart: templateData.claimStart || formData.value.timeline.claimStart
      })
    }
    
    // Note: Vesting properties are handled in the vesting configuration step
    // Template vesting configuration will be stored for later use
    
    // Distribution mapping - convert category to name
    if (templateData.distribution && Array.isArray(templateData.distribution)) {
      formData.value.distribution = templateData.distribution.map((item: any) => ({
        ...item,
        name: item.category || item.name, // Convert category to name for form compatibility
        category: item.category || item.name
      }))
    }
    
    // Show success message
    toast.success(`Template "${template.name}" loaded successfully!`)
  } catch (error) {
    console.error('Failed to load template:', error)
    toast.error('Failed to load template. Please try again.')
  }
}

const addTag = () => {
  const tag = tagsInput.value.trim()
  if (tag && !formData.value.projectInfo.tags.includes(tag)) {
    formData.value.projectInfo.tags.push(tag)
    tagsInput.value = ''
  }
}

const removeTag = (tag: string) => {
  const index = formData.value.projectInfo.tags.indexOf(tag)
  if (index > -1) {
    formData.value.projectInfo.tags.splice(index, 1)
  }
}

const handlePurchaseTokenChange = (canisterId: string) => {
  const selectedToken = purchaseTokenOptions.find(token => token.value === canisterId)
  if (selectedToken) {
    purchaseTokenInfo.value = selectedToken
    formData.value.purchaseToken = {
      canisterId: Principal.fromText(selectedToken.value),
      name: selectedToken.label,
      symbol: selectedToken.symbol,
      decimals: Number(selectedToken.decimals),
      totalSupply: BigInt(0),
      transferFee: BigInt(Number(selectedToken.fee)),
      standard: 'ICRC1',
      logo: selectedToken.logo ? [selectedToken.logo] : [],
      description: [],
      website: []
    }
    formData.value.purchaseToken.canisterId = selectedToken.value
  }
}

// Logo upload handlers
const triggerFileInput = () => {
  fileInput.value?.click()
}

const removeLogo = () => {
  logoPreview.value = ''
  logoError.value = ''
  formData.value.saleToken.logo = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const handleFileUpload = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    const file = input.files[0]
    logoError.value = ''

    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
    if (!validTypes.includes(file.type)) {
      logoError.value = 'Please upload a valid image file (JPEG, PNG, GIF, or WebP)'
      return
    }

    // Validate file size (30KB max)
    const maxSize = 30 * 1024 // 30KB
    if (file.size > maxSize) {
      logoError.value = 'Logo size is too large, max size is 30KB'
      return
    }

    // Create preview and convert to base64
    const reader = new FileReader()
    reader.onload = (e) => {
      const result = e.target?.result as string
      logoPreview.value = result
      // Store the base64 data for the backend
      formData.value.saleToken.logo = result
    }
    reader.readAsDataURL(file)
  }
}

// Multi-DEX Methods
const handleDEXToggle = (dex: DEXPlatform) => {
  if (!dex.enabled) {
    dex.allocationPercentage = 0
  } else {
    // Auto-assign percentage if none exists
    const enabledCount = availableDEXs.value.filter(d => d.enabled).length
    if (enabledCount === 1) {
      dex.allocationPercentage = 100
    } else {
      // Redistribute percentages evenly
      redistributePercentagesEvenly()
    }
  }
  redistributeLiquidity()
}

const redistributePercentagesEvenly = () => {
  const enabled = availableDEXs.value.filter(dex => dex.enabled)
  if (enabled.length === 0) return
  
  const evenPercentage = Math.floor(100 / enabled.length)
  const remainder = 100 - (evenPercentage * enabled.length)
  
  enabled.forEach((dex, index) => {
    dex.allocationPercentage = evenPercentage + (index === 0 ? remainder : 0)
  })
}

const redistributeLiquidity = () => {
  const totalLiquidity = Number(formData.value.dexConfig.totalLiquidityToken) || 0
  const listingPrice = Number(formData.value.dexConfig.listingPrice) || 0
  
  availableDEXs.value.forEach(dex => {
    if (dex.enabled && allocationPercentageTotal.value > 0) {
      // Calculate token liquidity for this DEX
      dex.calculatedTokenLiquidity = (totalLiquidity * dex.allocationPercentage) / 100
      
      // Calculate required purchase token liquidity based on listing price
      if (listingPrice > 0) {
        dex.calculatedPurchaseLiquidity = dex.calculatedTokenLiquidity * listingPrice
      } else {
        dex.calculatedPurchaseLiquidity = 0
      }
    } else {
      dex.calculatedTokenLiquidity = 0
      dex.calculatedPurchaseLiquidity = 0
    }
  })
}

const updateLiquidityCalculations = () => {
  redistributeLiquidity()
  
  // Also update the last task - automatic ICP liquidity calculation from listing price
  const listingPrice = Number(formData.value.dexConfig.listingPrice) || 0
  const totalTokenLiquidity = Number(formData.value.dexConfig.totalLiquidityToken) || 0
  
  if (listingPrice > 0 && totalTokenLiquidity > 0) {
    // Calculate total ICP needed based on listing price
    const totalICPRequired = totalTokenLiquidity * listingPrice
    
    // Update the old single DEX fields for backward compatibility
    formData.value.dexConfig.initialLiquidityToken = totalTokenLiquidity.toString()
    formData.value.dexConfig.initialLiquidityPurchase = totalICPRequired.toString()
  }
}

// Raised Funds Methods
const calculatePercentage = (amount: string | number): string => {
  const numAmount = Number(amount) || 0
  const available = Math.max(0, raisedFundsAfterFees.value.availableForLiquidity)
  if (available === 0) return '0.0'
  return ((numAmount / available) * 100).toFixed(1)
}

const addCustomAllocation = () => {
  formData.value.raisedFundsAllocation.customAllocations.push({
    name: `Custom Allocation ${formData.value.raisedFundsAllocation.customAllocations.length + 1}`,
    amount: '',
    recipients: [],
    vestingSchedule: null
  })
}

const removeCustomAllocation = (index: number) => {
  formData.value.raisedFundsAllocation.customAllocations.splice(index, 1)
}

// Team Recipients Management
const addTeamRecipient = () => {
  formData.value.raisedFundsAllocation.teamRecipients.push({
    principal: '',
    percentage: 100,
    name: '',
    vestingEnabled: false,
    vestingSchedule: {
      cliffDays: 0,
      durationDays: 365,
      releaseFrequency: 'monthly',
      immediateRelease: 0
    }
  })
}

const removeTeamRecipient = (index: number) => {
  formData.value.raisedFundsAllocation.teamRecipients.splice(index, 1)
}

// Development Recipients Management
const addDevelopmentRecipient = () => {
  formData.value.raisedFundsAllocation.developmentRecipients.push({
    principal: '',
    percentage: 100,
    name: '',
    vestingEnabled: false,
    vestingSchedule: {
      cliffDays: 0,
      durationDays: 730,
      releaseFrequency: 'monthly',
      immediateRelease: 0
    }
  })
}

const removeDevelopmentRecipient = (index: number) => {
  formData.value.raisedFundsAllocation.developmentRecipients.splice(index, 1)
}

// Marketing Recipients Management
const addMarketingRecipient = () => {
  formData.value.raisedFundsAllocation.marketingRecipients.push({
    principal: '',
    percentage: 100,
    name: '',
    vestingEnabled: false,
    vestingSchedule: {
      cliffDays: 0,
      durationDays: 180,
      releaseFrequency: 'monthly',
      immediateRelease: 0
    }
  })
}

const removeMarketingRecipient = (index: number) => {
  formData.value.raisedFundsAllocation.marketingRecipients.splice(index, 1)
}

// Apply smart allocation suggestion
const applySuggestion = (suggestion: any) => {
  if (suggestion.autoFix && typeof suggestion.autoFix === 'function') {
    suggestion.autoFix()
    toast.success(`Applied suggestion: ${suggestion.title}`)
  }
}

const formatNumber = (value: any): string => {
  return InputMask.formatTokenAmount(value, 2)
}

const formatDateTime = (dateStr: string): string => {
  if (!dateStr) return ''
  return new Date(dateStr).toLocaleString()
}

const getDexPlatformLabel = (platform: string): string => {
  switch (platform) {
    case 'icpswap': return 'ICPSwap'
    case 'sonic': return 'Sonic DEX'
    case 'icdex': return 'ICDex'
    case 'other': return 'Other'
    default: return platform
  }
}

// Whitelist management methods
const triggerCsvUpload = () => {
  csvFileInput.value?.click()
}

const handleCsvUpload = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    const file = input.files[0]
    csvFileName.value = file.name
    
    // Parse CSV file
    const reader = new FileReader()
    reader.onload = (e) => {
      const csv = e.target?.result as string
      if (csv) {
        parseCsvWhitelist(csv)
      }
    }
    reader.readAsText(file)
  }
}

const parseCsvWhitelist = (csv: string) => {
  const lines = csv.split('\n').filter(line => line.trim())
  const addresses: { principal: string; allocation?: string }[] = []
  
  lines.forEach((line, index) => {
    if (index === 0 && (line.toLowerCase().includes('address') || line.toLowerCase().includes('principal'))) {
      return // Skip header row
    }
    
    const [principal, allocation] = line.split(',').map(item => item.trim())
    if (principal) {
      addresses.push({
        principal,
        allocation: allocation || ''
      })
    }
  })
  
  formData.value.saleParams.whitelistAddresses = addresses
  toast.success(`Loaded ${addresses.length} addresses from CSV`)
}

const addWhitelistAddress = () => {
  formData.value.saleParams.whitelistAddresses.push({
    principal: '',
    allocation: ''
  })
}

const removeWhitelistAddress = (index: number) => {
  formData.value.saleParams.whitelistAddresses.splice(index, 1)
}

// Get allocation color for chart consistency
const getAllocationColor = (index: number): string => {
  const colors = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
    '#84CC16', // Lime
    '#F97316', // Orange
    '#EC4899', // Pink
    '#6366F1', // Indigo
  ]
  return colors[index % colors.length]
}

// Initialize default purchase token
const initializeDefaults = () => {
  // Set default purchase token to ICP
  handlePurchaseTokenChange('ryjl3-tyaaa-aaaaa-aaaba-cai')
}

// Initialize defaults on component mount
initializeDefaults()

const createLaunchpad = async () => {
  if (!canLaunch.value) return
  
  try {
    // Call the service layer through composable
    const result = await createLaunchpadService(formData.value as any)
    
    if (result) {
      // Navigate to the new launchpad detail page
      router.push(`/launchpad/${result.launchpadId}`)
    }
    
  } catch (error) {
    console.error('Error creating launchpad:', error)
    // Error handling is done in the composable
  }
}

// These functions are now handled by TypeConverter in the service layer
</script>