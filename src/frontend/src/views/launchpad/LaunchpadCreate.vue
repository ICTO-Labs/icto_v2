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
                  :options="PROJECT_CATEGORIES"
                  required
                  size="lg"
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
              <!-- ICTO Passport Verification -->
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  ICTO Passport Required <HelpTooltip>Minimum ICTO Passport level required for participants. Higher levels indicate more verified users with established identity and reputation. If you don't want to use ICTO Passport, leave it as 0.</HelpTooltip>
                </label>
                <input
                  v-model="formData.projectInfo.minICTOPassportScore"
                  type="number"
                  min="0"
                  placeholder="e.g.0, 1, 2, 3, 4, 5"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <p class="text-xs text-gray-500 mt-1">Higher ICTO Passport levels reduce bot participation and increase user quality</p>
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
        
        <!-- Step 1 Validation Errors -->
        <div v-if="step1ValidationErrors.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start space-x-2">
            <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
            <div class="flex-1">
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please complete these required fields:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="error in step1ValidationErrors" :key="error" class="flex items-start">
                  <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
                  <span>{{ error }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 2: Token & Sale Configuration -->
      <div v-if="currentStep === 2" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Token & Sale Configuration</h2>
        
        <!-- Token Configuration Section -->
        <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 mb-6">
          <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-4">Token Configuration</h3>
          <p class="text-sm text-green-700 dark:text-green-300 mb-6">Configure your token details for deployment on Internet Computer</p>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <!-- Token Name -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Token Name* <HelpTooltip>The full name of your token (e.g., "Awesome Project Token"). This will be visible to all users and cannot be changed after deployment.</HelpTooltip></label>
              <input
                v-model="formData.saleToken.name"
                type="text"
                placeholder="My Awesome Token"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
            </div>

            <!-- Token Symbol -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Token Symbol* <HelpTooltip>Short ticker symbol for your token (e.g., "APT"). Usually 3-5 characters, uppercase. This will be used in trading pairs.</HelpTooltip></label>
              <input
                v-model="formData.saleToken.symbol"
                type="text"
                placeholder="TOKEN"
                maxlength="10"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700 uppercase"
                required
              />
            </div>

            <!-- Token Decimals -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Token Decimals* <HelpTooltip>Number of decimal places for your token (typically 8 for IC ecosystem). Higher decimals allow for more granular amounts.</HelpTooltip></label>
              <Select
                v-model="formData.saleToken.decimals"
                :options="TOKEN_DECIMAL_OPTIONS"
                placeholder="Select decimals"
                required
                size="lg"
              />
            </div>

            <!-- Total Supply -->
            <!-- <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Total Supply* <HelpTooltip>Maximum number of tokens that will ever exist. Consider your tokenomics carefully - this cannot be changed after deployment.</HelpTooltip></label>
              <input
                v-model="formData.saleToken.totalSupply"
                type="number"
                step="1"
                min="1"
                placeholder="1000000000"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700"
                required
              />
            </div> -->

            <!-- Transfer Fee -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Transfer Fee <HelpTooltip>Fee charged for each token transfer (in smallest token unit). Set to 0 for no fees. Higher fees discourage spam but affect usability.</HelpTooltip></label>
              <div class="relative">
                <input
                  v-model="formData.saleToken.fee"
                  type="number"
                  step="1"
                  min="0"
                  placeholder="10000"
                  class="w-full px-3 py-2 pr-20 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700"
                />
                <span class="absolute right-3 top-3 text-xs text-gray-500">e{{ formData.saleToken.decimals || 8 }}</span>
              </div>
            </div>

            <!-- Token Logo -->
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Token Logo <HelpTooltip>Upload a logo for your token. Recommended size: 200x200px, PNG or JPG format. This will represent your token across the ecosystem.</HelpTooltip></label>
              <div class="flex items-center space-x-4">
                <input
                  ref="tokenLogoInput"
                  type="file"
                  accept="image/*"
                  @change="handleTokenLogoUpload"
                  class="hidden"
                />
                <button
                  @click="triggerTokenLogoInput"
                  type="button"
                  class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                >
                  <UploadIcon class="h-4 w-4 mr-2" />
                  {{ tokenLogoPreview ? 'Change Logo' : 'Upload Logo' }}
                </button>
                
                <!-- Logo Preview -->
                <div v-if="tokenLogoPreview" class="flex items-center space-x-3">
                  <div class="relative">
                    <img :src="tokenLogoPreview" alt="Token Logo" class="h-12 w-12 rounded-full object-cover border-2 border-green-300" />
                    <button
                      @click="removeTokenLogo"
                      type="button"
                      class="absolute -top-1 -right-1 h-5 w-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600 transition-colors"
                    >
                      ×
                    </button>
                  </div>
                  <div class="text-xs text-green-600 dark:text-green-400">
                    <div class="font-medium">✓ Loaded</div>
                    <div class="text-gray-500">{{ formData.saleToken.name || 'Token' }} logo ready</div>
                  </div>
                </div>
                
                <!-- Error Message -->
                <div v-if="tokenLogoError" class="text-xs text-red-500 bg-red-50 dark:bg-red-900/20 px-2 py-1 rounded">
                  {{ tokenLogoError }}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Sale Configuration Section -->
        <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 mb-6">
          <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">Sale Configuration</h3>
          <p class="text-sm text-blue-700 dark:text-blue-300 mb-6">Configure how your token sale will operate</p>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <!-- Purchase Token -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Purchase Token* <HelpTooltip>The token that participants will use to buy your sale token. ICP is the default and most liquid option. ckUSDT/ckUSDC provide stable pricing.</HelpTooltip></label>
            <Select
              v-model="formData.purchaseToken.canisterId"
              placeholder="Select Purchase Token"
              :options="PURCHASE_TOKEN_OPTIONS.map(token => ({
                value: token.value,
                label: `${token.symbol} - ${token.label}`,
                data: token
              }))"
              @change="handlePurchaseTokenChange"
              required
            />
            <p class="text-xs text-gray-500 mt-1">Token used by participants to purchase your tokens</p>
          </div>
          <div></div>
          
          <!-- Sale Type -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Sale Type* <HelpTooltip>Choose the type of token sale. IDO offers immediate liquidity, Private Sale is for pre-launch investors, Fair Launch ensures equal opportunity, Auction allows price discovery, and Lottery adds randomization.</HelpTooltip></label>
            <Select
              v-model="formData.saleParams.saleType"
              placeholder="Select Sale Type"
              :options="SALE_TYPE_OPTIONS"
              required
            />
          </div>

          <!-- Allocation Method -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Allocation Method* <HelpTooltip>First Come First Serve allocates tokens in order of contribution. Pro Rata distributes proportionally. Weighted considers user history/tier. Lottery adds randomness for fairness.</HelpTooltip></label>
            <Select
              v-model="formData.saleParams.allocationMethod"
              placeholder="Select Method"
              :options="ALLOCATION_METHOD_OPTIONS"
              required
            />
          </div>

          <!-- Total Sale Amount -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Total Sale Amount* <HelpTooltip>Total number of tokens available for sale to participants. This should be a portion of your total token supply allocated specifically for public/private sale.</HelpTooltip></label>
            <div class="relative">
              <money3
                v-bind="money3Options"
                v-model="formData.saleParams.totalSaleAmount"
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
            <money3
              v-bind="money3Options"
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
              <money3
                v-bind="money3Options"
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
              <money3
                v-bind="money3Options"
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

          <!-- Token Price Range (Dynamic) -->
          <div class="md:col-span-2 bg-gradient-to-r from-green-50 to-red-50 dark:from-green-900/20 dark:to-red-900/20 rounded-lg p-4 border border-gray-200 dark:border-gray-600">
            <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">🎯 Token Price Range (Dynamic)</h4>
            <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">Based on campaign participation levels and your allocation settings</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div class="relative">
                <div class="w-full px-3 py-2 pr-16 border border-green-300 dark:border-green-600 rounded-lg bg-green-50 dark:bg-green-900/20 text-green-900 dark:text-green-100 font-medium">
                  {{ tokenPriceAtSoftCap || '0' }}
                </div>
                <span class="absolute right-3 top-2.5 text-sm text-green-600">{{ purchaseTokenSymbol }}</span>
                <p class="text-xs text-green-600 mt-1">Min Price (at Soft Cap)</p>
              </div>
              <div class="relative">
                <div class="w-full px-3 py-2 pr-16 border border-red-300 dark:border-red-600 rounded-lg bg-red-50 dark:bg-red-900/20 text-red-900 dark:text-red-100 font-medium">
                  {{ tokenPriceAtHardCap || '0' }}
                </div>
                <span class="absolute right-3 top-2.5 text-sm text-red-600">{{ purchaseTokenSymbol }}</span>
                <p class="text-xs text-red-600 mt-1">Max Price (at Hard Cap)</p>
              </div>
            </div>
            <div class="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-lg">
              <p class="text-xs text-blue-700 dark:text-blue-300">
                <strong>Dynamic Pricing:</strong> Final token price = Total Committed Amount ÷ {{ formatNumber(formData.saleParams.totalSaleAmount || 0) }} {{ saleTokenSymbol }}
              </p>
              <p class="text-xs text-blue-600 dark:text-blue-400 mt-1">
                If campaign doesn't reach soft cap ({{ formatNumber(formData.saleParams.softCap || 0) }} {{ purchaseTokenSymbol }}), all funds will be refunded.
              </p>
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

           <!-- Whitelist Management (shown when whitelist is required) -->
           <div v-if="formData.saleParams.requiresWhitelist" class="md:col-span-2 mt-4 p-4 bg-blue-50 dark:bg-blue-500/20 border border-blue-200 dark:border-blue-800 rounded-lg">
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

        </div>
        
        <!-- Step 2 Validation Errors -->
        <div v-if="step2ValidationErrors.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start space-x-2">
            <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
            <div class="flex-1">
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please complete these required fields:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="error in step2ValidationErrors" :key="error" class="flex items-start">
                  <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
                  <span>{{ error }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        
      </div>
      <!-- Sale Timeline Configuration -->
      <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">📅 Sale Timeline</h3>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">Configure the timing for your token sale phases.</p>
          
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
      </div>


      <!-- Step 3: Token & Raised Funds Allocation -->
      <div v-if="currentStep === 3" class="p-6">
        <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Token & Raised Funds Allocation</h2>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
          Configure token distribution and raised funds allocation. Multi-DEX configuration included.
        </p>
        
        <!-- Token Allocation -->
        <div class="mb-8">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Token Distribution</h3>
          <TokenAllocation
            v-model="formData.distribution"
            :sale-token-symbol="saleTokenSymbol"
            :total-sale-amount="Number(formData.saleParams.totalSaleAmount) || 0"
            :total-liquidity-token="Number(formData.dexConfig.totalLiquidityToken) || 0"
            :total-supply="Number(formData.saleToken.totalSupply) || 100000000"
          />
        </div>

        <!-- DEX Configuration is now part of RaisedFundsAllocation component above -->


        <!-- Raised Funds Allocation -->
        <div class="mb-8">
          <RaisedFundsAllocation
            v-model="formData.raisedFundsAllocation"
            :soft-cap="formData.saleParams.softCap"
            :hard-cap="formData.saleParams.hardCap"
            :platform-fee-rate="platformFeePercentage"
          />
        </div>
        

        <!-- Step 3 Validation Errors -->
        <div v-if="step3ValidationErrors.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start space-x-2">
            <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
            <div class="flex-1">
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please complete these required fields:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="error in step3ValidationErrors" :key="error" class="flex items-start">
                  <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
                  <span>{{ error }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Liquidity Validation Issues -->
        <div v-if="liquidityValidation.issues.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
          <div class="flex items-start space-x-2">
            <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
            <div class="flex-1">
              <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">🚨 Critical Liquidity Issues:</h4>
              <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
                <li v-for="issue in liquidityValidation.issues" :key="issue" class="flex items-start">
                  <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
                  <span>{{ issue }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Liquidity Warnings (Non-blocking) -->
        <div v-if="liquidityValidation.warnings.length > 0" class="mt-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg">
          <div class="flex items-start space-x-2">
            <AlertTriangleIcon class="h-5 w-5 text-yellow-600 dark:text-yellow-400 mt-0.5 flex-shrink-0" />
            <div class="flex-1">
              <h4 class="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-2">⚠️ Liquidity Warnings:</h4>
              <ul class="text-sm text-yellow-700 dark:text-yellow-300 space-y-1">
                <li v-for="warning in liquidityValidation.warnings" :key="warning" class="flex items-start">
                  <span class="w-1.5 h-1.5 bg-yellow-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
                  <span>{{ warning }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 4: Post-Launch Options -->
      <div v-if="currentStep === 4" class="p-6">
        <PostLaunchOptions
          :allocation="{
            team_percentage: formData.distribution.team.percentage || 0,
            marketing_percentage: getMarketingPercentage(),
            dex_liquidity_percentage: 10, // Default DEX liquidity
            unallocated_percentage: getUnallocatedPercentage()
          }"
          :governance-model="governanceModel"
          :dao-config="daoConfig"
          :multisig-config="multisigConfig"
          @update:governance-model="governanceModel = $event"
          @update:dao-config="daoConfig = $event"
          @update:multisig-config="multisigConfig = $event"
        />
      </div>

      <!-- Step 5: Launch Overview & Terms -->
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
                      <div class="font-bold text-gray-900 dark:text-white">{{ formatNumber(Number(allocation.totalAmount)) }}</div>
                      <div class="text-xs text-gray-500 dark:text-gray-400">{{ saleTokenSymbol }}</div>
                    </div>
                  </div>
                  
                  <!-- DEX Liquidity (if enabled) -->
                  <div v-if="formData.dexConfig.autoList && Number(formData.dexConfig.totalLiquidityToken) > 0" class="flex items-center justify-between p-3 bg-orange-50 dark:bg-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800">
                    <div class="flex items-center space-x-3">
                      <div class="w-4 h-4 rounded-full bg-orange-500"></div>
                      <div>
                        <div class="font-medium text-orange-900 dark:text-orange-100">DEX Liquidity</div>
                        <div class="text-xs text-orange-600 dark:text-orange-400">{{ ((Number(formData.dexConfig.totalLiquidityToken) / Number(formData.saleToken.totalSupply)) * 100).toFixed(1) }}% for trading</div>
                      </div>
                    </div>
                    <div class="text-right">
                      <div class="font-bold text-orange-900 dark:text-orange-100">{{ formatNumber(Number(formData.dexConfig.totalLiquidityToken)) }}</div>
                      <div class="text-xs text-orange-600 dark:text-orange-400">{{ saleTokenSymbol }}</div>
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
                      <div class="font-bold text-blue-900 dark:text-blue-100">{{ formatNumber(Number(remainingAllocation)) }}</div>
                      <div class="text-xs text-blue-600 dark:text-blue-400">{{ saleTokenSymbol }}</div>
                    </div>
                  </div>
                </div>
                
                <div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-600">
                  <div class="flex justify-between text-sm mb-2">
                    <span class="text-gray-600 dark:text-gray-400">Total Allocated:</span>
                    <span class="font-medium">{{ formatNumber(Number(totalAllocationAmount)) }} {{ saleTokenSymbol }}</span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-600 dark:text-gray-400">Total Supply:</span>
                    <span class="font-medium">{{ formatNumber(Number(formData.saleToken.totalSupply) || 0) }} {{ saleTokenSymbol }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Complete Raised Funds Usage Overview with Simulation -->
          <div class="bg-gradient-to-br from-yellow-50 to-amber-50 dark:from-yellow-900/20 dark:to-amber-900/20 rounded-lg border border-yellow-200 dark:border-yellow-700 p-6 mb-6">
            <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">💰 Complete Raised Funds Usage Overview</h4>
            <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
              Simulate different funding scenarios to understand how raised funds will be allocated across platform fees, DEX liquidity, and team allocations.
            </p>
            
            <!-- Funding Simulation Slider -->
            <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 mb-6">
              <div class="flex justify-between items-center mb-4">
                <h5 class="font-medium text-gray-900 dark:text-white">📊 Funding Simulation</h5>
                <div class="text-sm font-bold text-blue-600">{{ formatNumber(simulatedAmount) }} {{ purchaseTokenSymbol }}</div>
              </div>
              
              <input
                v-model.number="simulatedAmount"
                type="range"
                :min="softCapAmount"
                :max="hardCapAmount"
                :step="stepSize"
                class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
              />
              <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
                <span>Soft Cap: {{ formatNumber(softCapAmount) }} {{ purchaseTokenSymbol }}</span>
                <span>Hard Cap: {{ formatNumber(hardCapAmount) }} {{ purchaseTokenSymbol }}</span>
              </div>
            </div>

            <!-- Fund Allocation Overview -->
            <FundAllocationOverview
              :allocation="formData.raisedFundsAllocation"
              :simulated-amount="simulatedAmount"
              :platform-fee-rate="platformFeePercentage"
              :dex-config="formData.raisedFundsAllocation?.dexConfig || formData.dexConfig"
            />
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

         
        </div>
        
        
        <div class="bg-gray-50 dark:bg-gray-700 rounded-lg p-6 mt-8">
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

      <!-- Form Actions - Moved outside step conditions -->
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

/* Simulation Slider Styling */
.slider::-webkit-slider-thumb {
  appearance: none;
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3B82F6, #1D4ED8);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(59, 130, 246, 0.4);
  border: 2px solid white;
  transition: all 0.2s ease;
}

.slider::-webkit-slider-thumb:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.6);
}

.slider::-moz-range-thumb {
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: linear-gradient(135deg, #3B82F6, #1D4ED8);
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(59, 130, 246, 0.4);
  border: 2px solid white;
  transition: all 0.2s ease;
}

.slider::-webkit-slider-track {
  height: 6px;
  border-radius: 3px;
  background: linear-gradient(to right, #FEF3C7 0%, #F59E0B 100%);
}

.slider::-moz-range-track {
  height: 6px;
  border-radius: 3px;
  background: linear-gradient(to right, #FEF3C7 0%, #F59E0B 100%);
}

.slider:focus {
  outline: none;
}

.dark .slider::-webkit-slider-track {
  background: linear-gradient(to right, #451A03 0%, #F59E0B 100%);
}

.dark .slider::-moz-range-track {
  background: linear-gradient(to right, #451A03 0%, #F59E0B 100%);
}
</style>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { toast } from 'vue-sonner'
import Swal from 'sweetalert2'
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
import PostLaunchOptions from '@/components/launchpad/PostLaunchOptions.vue'
import PieChart from '@/components/common/PieChart.vue'
import FundAllocationOverview from '@/components/launchpad/FundAllocationOverview.vue'
import { InputMask, ICTOMasks } from '@/utils/inputMask'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import { useLaunchpadService } from '@/composables/useLaunchpadService'
import { useUniqueId } from '@/composables/useUniqueId'
import { useAuthStore } from '@/stores/auth'
import { backendService } from '@/api/services/backend'
import { IcrcService } from '@/api/services/icrc'
import { useProgressDialog } from '@/composables/useProgressDialog'
import type { LaunchpadTemplate } from '@/data/launchpadTemplates'

// ===== CONSTANTS =====
const PLATFORM_FEE_PERCENTAGE = 2.0
const DEFAULT_LIQUIDITY_LOCK_DAYS = 180
const MAX_LOGO_SIZE = 30 * 1024 // 30KB
const MAX_TOKEN_LOGO_SIZE = 200 * 1024 // 200KB
const VALID_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']

const money3Options = {
  masked: false,
  prefix: '',
  suffix: '',
  thousands: ',',
  decimal: '.',
  precision: 0,
  disableNegative: false,
  disabled: false,
  min: null,
  max: null,
  allowBlank: false,
  minimumNumberOfCharacters: 0,
  shouldRound: true,
  focusOnRight: false,
}

const PROJECT_CATEGORIES = [
  { value: 'DeFi', label: 'Decentralized Finance (DeFi)' },
  { value: 'NFT', label: 'Non-Fungible Tokens (NFT)' },
  { value: 'Gaming', label: 'Gaming & Metaverse' },
  { value: 'Infrastructure', label: 'Infrastructure & Tools' },
  { value: 'Social', label: 'Social & Community' },
  { value: 'DAO', label: 'Decentralized Autonomous Organization' },
  { value: 'Other', label: 'Other' }
]

const TOKEN_DECIMAL_OPTIONS = [
  { value: 6, label: '6 decimals' },
  { value: 8, label: '8 decimals (recommended)' },
  { value: 12, label: '12 decimals' },
  { value: 18, label: '18 decimals' }
]

const SALE_TYPE_OPTIONS = [
  { value: 'IDO', label: 'IDO (Initial DEX Offering)' },
  { value: 'PrivateSale', label: 'Private Sale' },
  { value: 'FairLaunch', label: 'Fair Launch' },
  { value: 'Auction', label: 'Auction' },
  { value: 'Lottery', label: 'Lottery' }
]

const ALLOCATION_METHOD_OPTIONS = [
  { value: 'FirstComeFirstServe', label: 'First Come First Serve' },
  { value: 'ProRata', label: 'Pro Rata' },
  { value: 'Weighted', label: 'Weighted' },
  { value: 'Lottery', label: 'Lottery' }
]

const CHART_COLORS = [
  '#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
  '#06B6D4', '#84CC16', '#F97316', '#EC4899', '#6366F1'
]

const DEX_LIQUIDITY_COLORS = ['#6366F1', '#8B5CF6', '#EC4899', '#F59E0B', '#10B981']
const RAISED_FUNDS_COLORS = ['#3B82F6', '#10B981', '#F59E0B', '#6B7280']

const PURCHASE_TOKEN_OPTIONS = [
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

const router = useRouter()
const { createLaunchpad: createLaunchpadService, isCreating } = useLaunchpadService()
const authStore = useAuthStore()
const progress = useProgressDialog()

// Payment flow variables
const isPaying = ref(false)
const deployResult = ref<any>(null)
const creationCostBigInt = ref<bigint>(BigInt(0))
const showSuccessModal = ref(false)

// Breadcrumb configuration
const breadcrumbItems = [
  { label: 'Launchpad', to: '/launchpad' },
  { label: 'Create New Launch', to: '/launchpad/create' }
]

// Steps configuration - FINAL RESTRUCTURE
const steps = [
  { id: 'template', title: 'Template', description: 'Choose launchpad template' },
  { id: 'project', title: 'Project Info', description: 'Basic project details' },
  { id: 'token', title: 'Token & Sale Setup', description: 'Token config, sale parameters & timeline' },
  { id: 'allocation', title: 'Token & Raised Funds', description: 'Token distribution & raised funds allocation with Multi-DEX' },
  { id: 'governance', title: 'Post-Launch Options', description: 'Governance model & asset management' },
  { id: 'overview', title: 'Launch Overview', description: 'Review & launch' }
]

// State
const currentStep = ref(0)
const acceptTerms = ref(false)
const tagsInput = ref('')
const purchaseTokenInfo = ref<any>(null)
const selectedPurchaseToken = ref('ryjl3-tyaaa-aaaaa-aaaba-cai')
const tokenLogoInput = ref<HTMLInputElement | null>(null)
const tokenLogoPreview = ref('')
const tokenLogoError = ref('')
const csvFileName = ref('')
const csvFileInput = ref<HTMLInputElement | null>(null)
const previewRaisedAmount = ref(0)

// Governance model state
const governanceModel = ref<'dao_treasury' | 'multisig_wallet' | 'no_governance'>('no_governance')
const daoConfig = ref({
  proposal_threshold: 51,
  quorum: 30,
  voting_period: 7 * 24 * 60 * 60 // 7 days
})
const multisigConfig = ref({
  signers: [] as Array<{ principal: string; percentage: number; name?: string }>,
  threshold: 2,
  propose_duration: 24 * 60 * 60 // 24 hours
})

// Generate unique IDs for form elements
const uniqueIds = {
  isKYCed: useUniqueId('is-kyced'),
  isAudited: useUniqueId('is-audited'),
  requiresWhitelist: useUniqueId('requires-whitelist'),
  requiresKYC: useUniqueId('requires-kyc'),
  autoList: useUniqueId('auto-list'),
  acceptTerms: useUniqueId('accept-terms')
}

// Form data
const formData = ref({
  distribution: {
    // Sale allocation - no recipients needed (investors assigned after launch)
    sale: {
      name: 'Sale',
      percentage: 60, // Default 60%
      totalAmount: '',
      description: 'Public/Private sale allocation for investors'
    },

    // Team allocation - fixed category with recipients
    team: {
      name: 'Team',
      percentage: 15, // Default 15%
      totalAmount: '',
      vestingSchedule: {
        cliffDays: 365, // Default 1 year cliff
        durationDays: 1460, // Default 4 year vesting
        releaseFrequency: 'monthly' as 'daily' | 'weekly' | 'monthly' | 'quarterly',
        immediateRelease: 0 // Default 0% immediate release
      },
      recipients: [] as {
        principal: string
        percentage: number
        name?: string
        description?: string
        vestingEnabled: boolean
        vestingSchedule?: {
          cliffDays: number
          durationDays: number
          releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
          immediateRelease: number
        }
      }[],
      description: 'Team and founder allocation'
    },

    // LP allocation - auto-calculated from DEX config
    liquidityPool: {
      name: 'Liquidity Pool',
      percentage: 0, // Auto-calculated from dexConfig
      totalAmount: '',
      autoCalculated: true,
      description: 'DEX liquidity provision'
    },

    // Others - dynamic allocations (marketing, advisors, etc.)
    others: [] as {
      id: string
      name: string
      percentage: number
      totalAmount: string
      vestingEnabled: boolean
      vestingSchedule?: {
        cliffDays: number
        durationDays: number
        releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
        immediateRelease: number
      }
      recipients: {
        principal: string
        percentage: number
        name?: string
        description?: string
        vestingEnabled: boolean
        vestingSchedule?: {
          cliffDays: number
          durationDays: number
          releaseFrequency: 'daily' | 'weekly' | 'monthly' | 'quarterly'
          immediateRelease: number
        }
      }[]
      description?: string
    }[]
  },
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
    metadata: [],
    minICTOPassportScore: 0
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
    canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // Default to ICP
    name: 'Internet Computer',
    symbol: 'ICP',
    decimals: 8,
    totalSupply: '0',
    transferFee: '10000',
    standard: 'ICRC1',
    logo: 'https://cryptologos.cc/logos/internet-computer-icp-logo.png',
    description: 'Internet Computer Protocol',
    website: 'https://internetcomputer.org'
  } as any,
  saleParams: {
    saleType: 'FairLaunch' as string, // Default to FairLaunch
    allocationMethod: 'FirstComeFirstServe' as string,
    totalSaleAmount: '',
    price: '', // Token price
    tokenPrice: '',
    softCap: '',
    hardCap: '',
    minContribution: '',
    maxContribution: '',
    maxParticipants: '',
    requiresWhitelist: false,
    requiresKYC: false,
    minICTOPassportScore: BigInt(0),
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
    totalLiquidityToken: '', // Auto-calculated in RaisedFundsAllocation
    liquidityLockDays: DEFAULT_LIQUIDITY_LOCK_DAYS,
    autoList: false,
    lpTokenRecipient: ''
  },
  raisedFundsAllocation: {
    // Dynamic allocation system - starts with Team Allocation as default
    allocations: [
      {
        id: 'team',
        name: 'Team Allocation',
        amount: '',
        percentage: 0,
        recipients: [] as {
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
        }[]
      }
    ] as {
      id: string
      name: string
      amount: string
      percentage: number
      recipients: {
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
      }[]
    }[]
  },
  governanceConfig: {
    enabled: false,
    daoCanisterId: '',
    votingToken: '',
    proposalThreshold: '',
    quorumPercentage: 50,
    votingPeriod: '7',
    timelockDuration: '2',
    emergencyContacts: [],
    initialGovernors: [],
    autoActivateDAO: false
  }
})

// Multi-DEX Configuration
interface DEXPlatform {
  id: string
  name: string
  description: string
  logo: string
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
    logo: 'https://app.icpswap.com/static/media/logo-dark.7b8c12091e650c40c5e9f561c57473ba.svg',
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
    logo: '🦍',
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
    logo: '⚡',
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
    logo: '📊',
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


// Dynamic token price range calculations
const tokenPriceAtSoftCap = computed(() => {
  const softCap = Number(formData.value.saleParams.softCap) || 0
  const saleAllocation = Number(formData.value.saleParams.totalSaleAmount) || 0
  
  if (softCap > 0 && saleAllocation > 0) {
    const price = softCap / saleAllocation
    return price.toFixed(8).replace(/\.?0+$/, '') // Remove trailing zeros
  }
  return '0'
})

const tokenPriceAtHardCap = computed(() => {
  const hardCap = Number(formData.value.saleParams.hardCap) || 0
  const saleAllocation = Number(formData.value.saleParams.totalSaleAmount) || 0
  
  if (hardCap > 0 && saleAllocation > 0) {
    const price = hardCap / saleAllocation
    return price.toFixed(8).replace(/\.?0+$/, '') // Remove trailing zeros
  }
  return '0'
})

// Average price for compatibility with existing systems
const calculatedTokenPrice = computed(() => {
  const minPrice = Number(tokenPriceAtSoftCap.value) || 0
  const maxPrice = Number(tokenPriceAtHardCap.value) || 0

  if (minPrice > 0 && maxPrice > 0) {
    const avgPrice = (minPrice + maxPrice) / 2
    return avgPrice.toFixed(8).replace(/\.?0+$/, '')
  }
  return '0'
})

// Deployment cost computed property
const creationCost = computed(() => {
  const cost = Number(creationCostBigInt.value) / 100_000_000 // Convert e8s to ICP
  return cost.toFixed(3)
})

// Step validation computed properties
const step1ValidationErrors = computed(() => {
  const errors: string[] = []
  
  if (!formData.value.projectInfo.name?.trim()) {
    errors.push('Project name is required')
  }
  if (!formData.value.projectInfo.description?.trim()) {
    errors.push('Project description is required')
  }
  if (!formData.value.projectInfo.category?.trim()) {
    errors.push('Project category is required')
  }
  
  return errors
})

const step2ValidationErrors = computed(() => {
  const errors: string[] = []
  
  // Token validation
  if (!formData.value.saleToken.name?.trim()) {
    errors.push('Token name is required')
  }
  if (!formData.value.saleToken.symbol?.trim()) {
    errors.push('Token symbol is required')
  }
  if (!formData.value.saleToken.decimals || formData.value.saleToken.decimals < 1 || formData.value.saleToken.decimals > 18) {
    errors.push('Token decimals must be between 1 and 18')
  }
  if (!formData.value.saleToken.totalSupply || Number(formData.value.saleToken.totalSupply) <= 0) {
    errors.push('Token total supply must be greater than 0')
  }
  
  // Sale configuration validation
  if (!formData.value.saleParams.softCap || Number(formData.value.saleParams.softCap) <= 0) {
    errors.push('Soft cap is required and must be greater than 0')
  }
  if (!formData.value.saleParams.hardCap || Number(formData.value.saleParams.hardCap) <= 0) {
    errors.push('Hard cap is required and must be greater than 0')
  }
  if (Number(formData.value.saleParams.softCap) >= Number(formData.value.saleParams.hardCap)) {
    errors.push('Hard cap must be greater than soft cap')
  }
  if (!tokenPriceAtSoftCap.value || !tokenPriceAtHardCap.value || Number(tokenPriceAtSoftCap.value) <= 0) {
    errors.push('Token price range cannot be calculated - check Soft Cap, Hard Cap and Total Sale Amount values')
  }
  if (!formData.value.saleParams.totalSaleAmount || Number(formData.value.saleParams.totalSaleAmount) <= 0) {
    errors.push('Total sale amount is required and must be greater than 0')
  }
  
  // Timeline validation
  if (!formData.value.timeline.saleStart) {
    errors.push('Sale start time is required')
  }
  if (!formData.value.timeline.saleEnd) {
    errors.push('Sale end time is required')
  }
  if (!formData.value.timeline.claimStart) {
    errors.push('Claim start time is required')
  }
  
  return errors
})


const step3ValidationErrors = computed(() => {
  const errors: string[] = []
  
  if (!formData.value.distribution || formData.value.distribution.length === 0) {
    errors.push('At least one token distribution category is required')
  }
  
  // Check for DEX configuration if enabled
  const enabledDEXs = availableDEXs.value.filter(dex => dex.enabled)
  if (enabledDEXs.length > 0) {
    enabledDEXs.forEach(dex => {
      if (dex.allocationPercentage <= 0) {
        errors.push(`${dex.name} allocation percentage must be greater than 0%`)
      }
    })
  }
  
  // Check token allocation feasibility vs funding targets
  const totalSaleAmount = Number(formData.value.saleParams.totalSaleAmount) || 0
  const softCap = Number(formData.value.saleParams.softCap) || 0
  const hardCap = Number(formData.value.saleParams.hardCap) || 0
  
  if (totalSaleAmount > 0 && softCap > 0 && hardCap > 0) {
    // Calculate token prices at soft and hard cap
    const minPrice = softCap / totalSaleAmount  // Price when reaching soft cap
    const maxPrice = hardCap / totalSaleAmount  // Price when reaching hard cap
    
    // Check if allocation is feasible
    if (minPrice <= 0) {
      errors.push('Sale token allocation is too high - soft cap cannot provide meaningful token price')
    }
    
    if (maxPrice > minPrice * 100) {  // More than 100x price difference is unreasonable
      errors.push('Price range too wide - consider adjusting soft cap, hard cap, or sale token allocation')
    }
    
    // Check if sale allocation makes sense relative to total supply
    const totalSupply = Number(formData.value.saleToken.totalSupply) || 0
    if (totalSupply > 0 && totalSaleAmount > 0) {
      const salePercentage = (totalSaleAmount / totalSupply) * 100

      // Warning for very high allocation (>80%)
      if (salePercentage > 80) {
        errors.push(`Sale allocation (${totalSaleAmount.toLocaleString()} tokens) is ${salePercentage.toFixed(1)}% of total supply (${totalSupply.toLocaleString()} tokens). Consider reserving more tokens for team, development, and liquidity to ensure sustainable tokenomics.`)
      }
      // Advisory warning for high allocation (>60%)
      else if (salePercentage > 60) {
        // This is just a warning, not an error
        console.warn(`Sale allocation is ${salePercentage.toFixed(1)}% of total supply. Consider if this allocation supports your tokenomics goals.`)
      }
    }
  }

  // Check raised funds allocation from RaisedFundsAllocation component
  if (formData.value.raisedFundsAllocation) {
    const allocation = formData.value.raisedFundsAllocation

    // Check team allocation validation
    if (allocation.teamAllocationPercentage > 0) {
      if (!allocation.teamRecipients || allocation.teamRecipients.length === 0) {
        errors.push('Team allocation requires at least one recipient')
      } else {
        // Check if team recipients have valid principal IDs
        allocation.teamRecipients.forEach((recipient: any, index: number) => {
          if (!recipient.principal || !recipient.principal.trim()) {
            errors.push(`Team recipient #${index + 1} is missing Principal ID`)
          }
        })

        // Check if team recipient percentages sum to 100%
        const totalTeamPercentage = allocation.teamRecipients.reduce((sum: any, r: any) => sum + (Number(r.percentage) || 0), 0)
        if (totalTeamPercentage !== 100) {
          errors.push(`Team recipient percentages must total 100% (currently ${totalTeamPercentage}%)`)
        }
      }
    }

    // Check custom allocations validation
    if (allocation.customAllocations && Array.isArray(allocation.customAllocations)) {
      allocation.customAllocations.forEach((customAllocation: any, index: number) => {
        // Skip if allocation is null/undefined or has no percentage
        if (!customAllocation || !customAllocation.percentage || customAllocation.percentage <= 0) return

        // Skip Treasury allocation as it doesn't need recipients
        if (customAllocation.name?.toLowerCase().includes('treasury')) {
          return
        }

        if (!customAllocation.recipients || customAllocation.recipients.length === 0) {
          errors.push(`${customAllocation.name || `Custom allocation ${index + 1}`} requires at least one recipient`)
        } else {
          // Check if custom allocation recipients have valid principal IDs
          customAllocation.recipients.forEach((recipient: any, recipientIndex: number) => {
            if (!recipient.principal || !recipient.principal.trim()) {
              errors.push(`${customAllocation.name || `Custom allocation ${index + 1}`} recipient #${recipientIndex + 1} is missing Principal ID`)
            }
          })

          // Check if custom allocation recipient percentages sum to 100%
          const totalCustomPercentage = customAllocation.recipients.reduce((sum: any, r: any) => sum + (Number(r.percentage) || 0), 0)
          if (totalCustomPercentage !== 100) {
            errors.push(`${customAllocation.name || `Custom allocation ${index + 1}`} recipient percentages must total 100% (currently ${totalCustomPercentage}%)`)
          }
        }
      })
    }
  }
  
  return errors
})

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
  
  const colors = CHART_COLORS
  
  // Collect all allocations into arrays for chart
  const allAllocations = [
    formData.value.distribution.sale,
    formData.value.distribution.team,
    formData.value.distribution.liquidityPool,
    ...formData.value.distribution.others
  ]

  const labels = allAllocations.map(a => a.name || 'Unnamed')
  const data = allAllocations.map(a => Number(a.percentage || 0))
  const values = allAllocations.map(a => Number(a.totalAmount || 0))
  
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
  
  const labels: string[] = []
  const data: number[] = []
  const values: number[] = []
  const colors = CHART_COLORS
  
  // Process dynamic allocations
  formData.value.raisedFundsAllocation?.allocations?.forEach((allocation, index) => {
    const amount = Number(allocation.amount) || 0
    if (amount > 0) {
      const percentage = availableForAllocation > 0 ? (amount / availableForAllocation) * 100 : 0
      labels.push(allocation.name)
      data.push(percentage)
      values.push(amount)
    }
  })
  
  // Add DAO Treasury (remaining)
  const totalAllocated = totalRaisedAllocated.value
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

const totalPurchaseLiquidityRequired = computed(() => {
  // DEX liquidity calculation is now handled in RaisedFundsAllocation component
  // This returns 0 to avoid conflicts with the new DEX configuration system
  return 0
})

const estimatedTotalTVL = computed(() => {
  // Since we no longer have a fixed listing price, we can't calculate exact TVL
  // This would need to be calculated after the sale when we know the final token price
  return totalPurchaseLiquidityRequired.value * 2 // Rough estimate: liquidity * 2 for total pool value
})

// Raised Funds Calculations
const softCapAmount = computed(() => Number(formData.value.saleParams.softCap) || 0)
const hardCapAmount = computed(() => Number(formData.value.saleParams.hardCap) || 0)

const platformFeePercentage = computed(() => PLATFORM_FEE_PERCENTAGE)
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

// Enhanced Chart Data for Complete Overview
const enhancedRaisedFundsChartData = computed(() => {
  const labels: string[] = []
  const data: number[] = []
  const values: number[] = []
  const colors = RAISED_FUNDS_COLORS
  
  // Add allocations that have amounts
  formData.value.raisedFundsAllocation?.allocations?.forEach((allocation, index) => {
    const amount = Number(allocation.amount || 0)
    if (amount > 0) {
      labels.push(allocation.name)
      data.push(allocation.percentage || 0)
      values.push(amount)
    }
  })
  
  // Add remaining to treasury if any
  const totalAllocated = formData.value.raisedFundsAllocation?.allocations?.reduce((sum, allocation) => sum + Number(allocation.amount || 0), 0) || 0
  const remaining = raisedFundsAfterFees.value.availableForLiquidity - totalAllocated
  
  if (remaining > 0) {
    const remainingPercentage = (remaining / raisedFundsAfterFees.value.availableForLiquidity) * 100
    labels.push('DAO Treasury')
    data.push(remainingPercentage)
    values.push(remaining)
  }
  
  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages: data
  }
})

const dexLiquidityChartData = computed(() => {
  const labels: string[] = []
  const data: number[] = []
  const values: number[] = []
  const colors = DEX_LIQUIDITY_COLORS
  
  availableDEXs.value.forEach((dex, index) => {
    if (dex.enabled) {
      labels.push(dex.name)
      data.push(dex.allocationPercentage)
      values.push(dex.calculatedPurchaseLiquidity)
    }
  })
  
  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages: data
  }
})

// Simulation Variables and Computeds
const simulatedAmount = ref(1000)
const stepSize = computed(() => {
  const diff = hardCapAmount.value - softCapAmount.value
  return diff > 0 ? Math.max(1, Math.floor(diff / 100)) : 1000
})

// Initialize simulation amount
watch([softCapAmount, hardCapAmount], ([softCap, hardCap]) => {
  if (simulatedAmount.value === 0 || simulatedAmount.value < softCap || simulatedAmount.value > hardCap) {
    simulatedAmount.value = hardCap
  }
}, { immediate: true })

// Simulation calculations
const simulatedPlatformFee = computed(() => {
  return simulatedAmount.value * (platformFeePercentage.value / 100)
})

const simulatedAvailableForTeam = computed(() => {
  return Math.max(0, simulatedAmount.value - simulatedPlatformFee.value - totalPurchaseLiquidityRequired.value)
})

const simulatedAllocationAmount = (allocation: any) => {
  const percentage = allocation.percentage || 0
  return (simulatedAvailableForTeam.value * percentage) / 100
}

const simulatedRemainingToTreasury = computed(() => {
  const totalTeamAllocated = formData.value.raisedFundsAllocation?.allocations?.reduce((sum, allocation) => sum + simulatedAllocationAmount(allocation), 0) || 0
  return Math.max(0, simulatedAvailableForTeam.value - totalTeamAllocated)
})

// Comprehensive chart data for simulation
const comprehensiveFundsChartData = computed(() => {
  const labels: string[] = []
  const data: number[] = []
  const values: number[] = []
  const colors = CHART_COLORS
  
  // Platform Fee
  const platformFee = simulatedPlatformFee.value
  if (platformFee > 0) {
    labels.push('Platform Fee')
    data.push((platformFee / simulatedAmount.value) * 100)
    values.push(platformFee)
  }
  
  // Individual DEX Platforms from RaisedFundsAllocation component
  const allocation = formData.value.raisedFundsAllocation
  if (allocation && allocation.dexConfig && allocation.dexConfig.autoList && allocation.availableDexs) {
    const enabledDexs = allocation.availableDexs.filter(dex => dex.enabled)
    enabledDexs.forEach((dex) => {
      const dexAmount = Number(dex.calculatedPurchaseLiquidity) || 0
      if (dexAmount > 0) {
        // Calculate dynamic percentage based on current simulation amount
        const dexPercentage = ((dexAmount / simulatedAmount.value) * 100).toFixed(1)
        labels.push(`${dex.name} (${dexPercentage}%)`)
        data.push((dexAmount / simulatedAmount.value) * 100)
        values.push(dexAmount)
      }
    })
  }

  // Team Allocation from RaisedFundsAllocation component
  let colorIndex = 2 // Start after platform fee and DEX liquidity colors
  if (allocation && allocation.teamAllocationPercentage > 0) {
    const teamAmount = Number(allocation.teamAllocation) || 0
    if (teamAmount > 0) {
      // Calculate dynamic percentage based on current simulation amount
      const teamPercentage = ((teamAmount / simulatedAmount.value) * 100).toFixed(1)
      labels.push(`Team Allocation (${teamPercentage}%)`)
      data.push((teamAmount / simulatedAmount.value) * 100)
      values.push(teamAmount)
      colorIndex++
    }
  }

  // Custom Allocations from RaisedFundsAllocation component
  if (allocation && allocation.customAllocations && Array.isArray(allocation.customAllocations)) {
    allocation.customAllocations.forEach((customAllocation) => {
      if (customAllocation && customAllocation.percentage > 0) {
        const customAmount = Number(customAllocation.amount) || 0
        if (customAmount > 0) {
          // Calculate dynamic percentage based on current simulation amount
          const customPercentage = ((customAmount / simulatedAmount.value) * 100).toFixed(1)
          labels.push(`${customAllocation.name} (${customPercentage}%)`)
          data.push((customAmount / simulatedAmount.value) * 100)
          values.push(customAmount)
          colorIndex++
        }
      }
    })
  }
  
  // DAO Treasury
  const treasury = simulatedRemainingToTreasury.value
  if (treasury > 0) {
    labels.push('DAO Treasury')
    data.push((treasury / simulatedAmount.value) * 100)
    values.push(treasury)
  }
  
  return {
    labels,
    data,
    values,
    colors: colors.slice(0, labels.length),
    percentages: data.map(d => Number(d.toFixed(1)))
  }
})

const liquidityValidation = computed(() => {
  const issues: string[] = []
  const warnings: string[] = []

  // CRITICAL: Platform fees + DEX fees must not exceed soft cap (applies always)
  const platformFeeAtSoftCap = softCapAmount.value * (platformFeePercentage.value / 100)
  const totalFeesAtSoftCap = platformFeeAtSoftCap + dexFeesTotal.value

  if (softCapAmount.value > 0 && totalFeesAtSoftCap > softCapAmount.value) {
    issues.push(`🚨 CRITICAL: Total fees (${formatNumber(totalFeesAtSoftCap)} ${purchaseTokenSymbol.value}) exceed soft cap (${formatNumber(softCapAmount.value)} ${purchaseTokenSymbol.value}). Project is not viable even at minimum funding level!`)
  }

  // Check if any funds remain after fees at soft cap level
  const remainingAfterFeesAtSoftCap = softCapAmount.value - totalFeesAtSoftCap
  if (softCapAmount.value > 0 && remainingAfterFeesAtSoftCap < 0) {
    issues.push(`No funds available for project operations after paying fees. Reduce DEX allocation or increase soft cap.`)
  } else if (softCapAmount.value > 0 && remainingAfterFeesAtSoftCap < softCapAmount.value * 0.1) {
    warnings.push(`⚠️ Only ${formatNumber(remainingAfterFeesAtSoftCap)} ${purchaseTokenSymbol.value} (${(remainingAfterFeesAtSoftCap/softCapAmount.value*100).toFixed(1)}%) remains for project operations after fees. Consider adjusting DEX allocation.`)
  }

  // Skip DEX-specific validation if auto listing is disabled
  if (!formData.value.dexConfig.autoList) {
    return { issues, warnings }
  }

  // Critical validation: DEX liquidity must be feasible even at softCap (worst case scenario)
  const softCapAfterFees = softCapAmount.value * (1 - platformFeePercentage.value / 100)
  const softCapAvailableForLiquidity = Math.max(0, softCapAfterFees - totalPurchaseLiquidityRequired.value)

  if (totalPurchaseLiquidityRequired.value > softCapAfterFees) {
    issues.push(`DEX liquidity requirement (${formatNumber(totalPurchaseLiquidityRequired.value)} ${purchaseTokenSymbol.value}) exceeds soft cap after platform fees (${formatNumber(softCapAfterFees)} ${purchaseTokenSymbol.value}). Project cannot provide promised liquidity at minimum funding level.`)
  }

  // Warning: High liquidity ratio (>20% of softCap)
  const liquidityRatio = softCapAmount.value > 0 ? (totalPurchaseLiquidityRequired.value / softCapAmount.value * 100) : 0
  if (liquidityRatio > 20) {
    warnings.push(`DEX liquidity requirement is ${liquidityRatio.toFixed(1)}% of soft cap. Consider reducing liquidity allocation or increasing soft cap.`)
  }

  if (raisedFundsAfterFees.value.availableForLiquidity < 0) {
    issues.push(`Insufficient raised funds after fees and DEX liquidity allocation`)
  }

  return { issues, warnings }
})

// Separate warnings that don't block progress
const liquidityWarnings = computed(() => {
  const warnings: string[] = []
  
  // Skip warnings if auto listing is disabled
  if (!formData.value.dexConfig.autoList) {
    return warnings
  }
  
  if (totalPurchaseLiquidityRequired.value > softCapAmount.value) {
    warnings.push(`DEX liquidity requirement exceeds soft cap - project may not reach minimum funding`)
  }
  
  const liquidityToRaisedRatio = hardCapAmount.value > 0 ? totalPurchaseLiquidityRequired.value / hardCapAmount.value * 100 : 0
  if (liquidityToRaisedRatio > 80) {
    warnings.push(`Very high liquidity allocation (${liquidityToRaisedRatio.toFixed(1)}% of raised funds) - consider reducing`)
  }
  
  return warnings
})

// Recipient Validation - DYNAMIC VERSION
const recipientValidation = computed(() => {
  const issues: string[] = []
  
  // Check each dynamic allocation
  formData.value.raisedFundsAllocation.allocations?.forEach((allocation, allocIndex) => {
    // Skip Treasury allocation as it doesn't need recipients
    if (allocation.name?.toLowerCase().includes('treasury')) {
      return
    }

    if (Number(allocation.amount) > 0 &&
        (!allocation.recipients || allocation.recipients.length === 0)) {
      issues.push(`${allocation.name} requires at least one recipient with vesting details`)
    }
    
    // Validate recipient details for this allocation
    if (allocation.recipients && Array.isArray(allocation.recipients)) {
      allocation.recipients.forEach((recipient, recipientIndex) => {
        if (!recipient.principal || !recipient.principal.trim()) {
          issues.push(`${allocation.name} recipient ${recipientIndex + 1} requires a valid Principal ID`)
        }
        if (recipient.percentage <= 0 || recipient.percentage > 100) {
          issues.push(`${allocation.name} recipient ${recipientIndex + 1} percentage must be between 1-100%`)
        }
      })
    }
    
    // Validate that recipients percentages sum to 100%
    const totalPercentage = (allocation.recipients && Array.isArray(allocation.recipients)) 
      ? allocation.recipients.reduce((sum, recipient) => sum + recipient.percentage, 0) 
      : 0
    if (allocation.recipients && Array.isArray(allocation.recipients) && allocation.recipients.length > 0 && Math.abs(totalPercentage - 100) > 0.1) {
      issues.push(`${allocation.name} recipients percentages must sum to 100% (currently ${totalPercentage.toFixed(1)}%)`)
    }
  })
  
  return issues
})

// Raised Funds Allocation Computed Properties - DYNAMIC VERSION
const totalRaisedAllocated = computed(() => {
  return formData.value.raisedFundsAllocation.allocations?.reduce(
    (sum, allocation) => sum + (Number(allocation.amount) || 0), 0
  ) || 0
})

const remainingRaisedFunds = computed(() => {
  // Use a more conservative calculation based on realistic scenarios
  // If softCap is reached, what's the actual available amount after all deductions?
  const softCapAfterFees = softCapAmount.value * (1 - platformFeePercentage.value / 100)
  const softCapAfterLiquidity = Math.max(0, softCapAfterFees - totalPurchaseLiquidityRequired.value)
  
  // For allocation planning, use the more conservative softCap scenario
  const availableForAllocation = Math.min(
    raisedFundsAfterFees.value.availableForLiquidity, // Hard cap scenario
    softCapAfterLiquidity // Soft cap scenario (more conservative)
  )
  
  return Math.max(0, availableForAllocation - totalRaisedAllocated.value)
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

  // Collect all allocations for chart
  const allAllocations = [
    formData.value.distribution.sale,
    formData.value.distribution.team,
    formData.value.distribution.liquidityPool,
    ...formData.value.distribution.others
  ]

  return allAllocations.map((allocation: any) => Number(allocation.totalAmount) || 0)
})

const allocationChartOptions = computed(() => ({
  chart: {
    type: 'pie',
    fontFamily: 'Outfit, sans-serif',
  },
  labels: (() => {
    if (!formData.value.distribution) return []
    const allAllocations = [
      formData.value.distribution.sale,
      formData.value.distribution.team,
      formData.value.distribution.liquidityPool,
      ...formData.value.distribution.others
    ]
    return allAllocations.map((allocation: any) => allocation.name) || []
  })(),
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
    dynamicAllocations: formData.value.raisedFundsAllocation.allocations.map(allocation => ({
      name: allocation.name,
      amount: Number(allocation.amount) || 0,
      percentage: allocation.percentage
    }))
  }
})

// Smart Allocation Suggestions - SIMPLIFIED FOR DYNAMIC ALLOCATIONS
const smartAllocationSuggestions = computed(() => {
  const suggestions: any[] = []
  const totalAllocated = totalRaisedAllocated.value
  const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
  const allocationPercentage = availableAmount > 0 ? (totalAllocated / availableAmount) * 100 : 0
  
  // High allocation warning
  if (allocationPercentage > 70) {
    suggestions.push({
      title: 'High Team Allocation',
      description: `${allocationPercentage.toFixed(1)}% of raised funds allocated. Consider reducing to increase DAO treasury for sustainability.`,
      action: `Reduce to ~50% (${formatNumber(availableAmount * 0.5)} ${purchaseTokenSymbol.value})`,
      priority: 'high',
      autoFix: false // Disabled for now - will implement with dynamic allocation support
    })
  }
  
  // Missing recipients warning for allocations with no recipients
  formData.value.raisedFundsAllocation?.allocations?.forEach((allocation, index) => {
    if (Number(allocation.amount) > 0 && allocation.recipients.length === 0) {
      suggestions.push({
        title: `Missing ${allocation.name} Recipients`,
        description: `${allocation.name} allocation specified but no recipients configured.`,
        action: 'Add recipient wallet addresses',
        priority: 'high',
        autoFix: false
      })
    }
  })
  
  return suggestions
})

// Initialize preview amount to hard cap
watch(hardCapAmount, (newVal) => {
  if (newVal && previewRaisedAmount.value === 0) {
    previewRaisedAmount.value = newVal
  }
}, { immediate: true })

// Track if we're currently updating allocations to prevent recursion
let updatingAllocations = false

// Watch for changes from RaisedFundsAllocation component and sync to dynamic allocation structure
watch(() => formData.value.raisedFundsAllocation, (newAllocation) => {
  if (updatingAllocations || !newAllocation || (newAllocation as any).teamAllocation === undefined) {
    return
  }
  
  // Handle new dynamic allocation system from RaisedFundsAllocation component
  const oldData = newAllocation as any
  
  // Skip if this looks like our own allocation structure
  if (oldData.allocations && Array.isArray(oldData.allocations)) {
    return
  }
  
  updatingAllocations = true
  
  try {
    // Initialize or clear existing allocations
    if (!formData.value.raisedFundsAllocation?.allocations) {
      formData.value.raisedFundsAllocation = { ...formData.value.raisedFundsAllocation, allocations: [] }
    }
    const allocations = formData.value.raisedFundsAllocation.allocations
    allocations.length = 0
    
    // Add Team allocation
    if (oldData.teamAllocationPercentage > 0) {
      allocations.push({
        id: 'team',
        name: 'Team',
        percentage: oldData.teamAllocationPercentage || 0,
        amount: oldData.teamAllocation || '0',
        recipients: (oldData.teamRecipients || []).map((recipient: any) => ({
          principal: recipient.principal,
          percentage: recipient.percentage || 0,
          name: recipient.name || '',
          vestingEnabled: !!recipient.vestingSchedule,
          vestingSchedule: recipient.vestingSchedule
        }))
      })
    }
    
    // Add custom allocations
    if (oldData.customAllocations && Array.isArray(oldData.customAllocations)) {
      oldData.customAllocations.forEach((customAllocation: any) => {
        if (customAllocation.percentage > 0) {
          allocations.push({
            id: customAllocation.id || `custom_${Date.now()}`,
            name: customAllocation.name || 'Custom',
            percentage: customAllocation.percentage,
            amount: customAllocation.amount || '0',
            recipients: (customAllocation.recipients || []).map((recipient: any) => ({
              principal: recipient.principal,
              percentage: recipient.percentage || 0,
              name: recipient.name || '',
              vestingEnabled: !!recipient.vestingSchedule,
              vestingSchedule: recipient.vestingSchedule
            }))
          })
        }
      })
    }
    
    // Add Treasury allocation if there's remaining percentage
    if (oldData.remainingPercentage > 0) {
      allocations.push({
        id: 'treasury',
        name: 'Treasury', 
        percentage: oldData.remainingPercentage,
        amount: oldData.remainingAmount || '0',
        recipients: []
      })
    }
  } finally {
    updatingAllocations = false
  }
}, { deep: true, immediate: true })

// Fixed Allocation Watchers - Auto-sync with sale allocation and DEX liquidity

// Computed for total allocation percentages
const totalAllocationPercentage = computed(() => {
  const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
  return formData.value.raisedFundsAllocation.allocations?.reduce((sum, allocation) => {
    const percentage = availableAmount > 0 ? (Number(allocation.amount) / availableAmount * 100) : 0
    return sum + percentage
  }, 0) || 0
})

const remainingAllocationPercentage = computed(() => {
  return Math.max(0, 100 - totalAllocationPercentage.value)
})

const canProceed = computed(() => {
  switch (currentStep.value) {
    case 0: // Template Selection
      return true // Always allow proceeding from template selection
    case 1: // Project Info
      return step1ValidationErrors.value.length === 0
    case 2: // Token & Sale Configuration (includes timeline)
      return step2ValidationErrors.value.length === 0 && timelineValidation.value.length === 0
    case 3: // Token & Raised Funds Allocation (includes Multi-DEX)
      return step3ValidationErrors.value.length === 0 && liquidityValidation.value.issues.length === 0
    case 4: // Post-Launch Options (Governance Model)
      return governanceValidation.value.valid
    case 5: // Launch Overview & Timeline - Final step
      return acceptTerms.value
    default:
      return true
  }
})

// Governance model validation
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

const canLaunch = computed(() => {
  return canProceed.value && acceptTerms.value
})

// Helper functions for PostLaunchOptions
const getMarketingPercentage = () => {
  const marketingAllocation = formData.value.distribution.others.find(alloc =>
    alloc.name.toLowerCase().includes('marketing')
  )
  return marketingAllocation?.percentage || 0
}

const getUnallocatedPercentage = () => {
  const teamPercentage = formData.value.distribution.team.percentage || 0
  const marketingPercentage = getMarketingPercentage()
  const dexLiquidityPercentage = 10 // Default DEX liquidity
  const totalAllocated = teamPercentage + marketingPercentage + dexLiquidityPercentage
  return Math.max(0, 100 - totalAllocated)
}

// Helper function to get all allocations as array for compatibility
const getAllAllocationsAsArray = () => {
  if (!formData.value.distribution) return []
  return [
    formData.value.distribution.sale,
    formData.value.distribution.team,
    formData.value.distribution.liquidityPool,
    ...formData.value.distribution.others
  ]
}

// Fixed Allocation System - Auto-manage Sale and DEX Liquidity allocations
const ensureSaleAllocation = (saleAmount: number) => {
  if (saleAmount <= 0) return

  const totalSupply = Number(formData.value.saleToken.totalSupply) || 0
  const percentage = totalSupply > 0 ? (saleAmount / totalSupply) * 100 : 0

  // Update sale allocation in fixed structure
  formData.value.distribution.sale.totalAmount = saleAmount.toString()
  formData.value.distribution.sale.percentage = percentage
}

const ensureDEXLiquidityAllocation = (liquidityAmount: number) => {
  if (liquidityAmount <= 0) return

  const totalSupply = Number(formData.value.saleToken.totalSupply) || 0
  const percentage = totalSupply > 0 ? (liquidityAmount / totalSupply) * 100 : 0

  // Update liquidity pool allocation in fixed structure
  formData.value.distribution.liquidityPool.totalAmount = liquidityAmount.toString()
  formData.value.distribution.liquidityPool.percentage = percentage
}

const recalculatePercentages = () => {
  const totalSupply = Number(formData.value.saleToken.totalSupply) || 0
  if (totalSupply > 0) {
    // Sale allocation
    formData.value.distribution.sale.percentage = (Number(formData.value.distribution.sale.totalAmount) / totalSupply) * 100

    // Team allocation
    formData.value.distribution.team.percentage = (Number(formData.value.distribution.team.totalAmount) / totalSupply) * 100

    // LP allocation
    formData.value.distribution.liquidityPool.percentage = (Number(formData.value.distribution.liquidityPool.totalAmount) / totalSupply) * 100

    // Others allocations
    formData.value.distribution.others.forEach(allocation => {
      allocation.percentage = (Number(allocation.totalAmount) / totalSupply) * 100
    })
  }
}

// Prevent circular updates
let isUpdatingLiquidity = false

// Fixed Allocation Watchers - Auto-sync with sale allocation and DEX liquidity
watch(() => formData.value.saleParams.totalSaleAmount, (newAmount) => {
  if (newAmount && Number(newAmount) > 0) {
    ensureSaleAllocation(Number(newAmount))
  }
}, { immediate: true })

watch(() => formData.value.dexConfig.totalLiquidityToken, (newAmount) => {
  if (isUpdatingLiquidity || !newAmount || Number(newAmount) <= 0) return

  isUpdatingLiquidity = true
  ensureDEXLiquidityAllocation(Number(newAmount))
  nextTick(() => {
    isUpdatingLiquidity = false
  })
}, { immediate: true })

// Bi-directional sync: When DEX Liquidity allocation changes, update dexConfig.totalLiquidityToken
watch(() => formData.value.distribution?.liquidityPool?.totalAmount, (newAmount) => {
  if (isUpdatingLiquidity || !newAmount) return

  const amount = Number(newAmount) || 0
  // Only update if different to avoid infinite loop
  if (amount !== Number(formData.value.dexConfig.totalLiquidityToken)) {
    isUpdatingLiquidity = true
    formData.value.dexConfig.totalLiquidityToken = amount.toString()
    nextTick(() => {
      isUpdatingLiquidity = false
    })
  }
}, { deep: true })

// Recalculate percentages when total supply changes
watch(() => formData.value.saleToken.totalSupply, () => {
  recalculatePercentages()
}, { immediate: true })

// Auto-sync calculated price to formData for other components
watch(calculatedTokenPrice, (newPrice) => {
  formData.value.saleParams.price = newPrice
}, { immediate: true })

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
    // Scroll to top of the page when navigating to next step
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
    // Scroll to top of the page when navigating to previous step
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }
}

// Template loading function
const loadTemplate = (template: LaunchpadTemplate | null) => {
  console.log('🚀 loadTemplate called with:', template?.name || 'blank template')
  console.log('Current step before:', currentStep.value)
  console.log('Steps length:', steps.length)
  console.log('Can proceed before:', canProceed.value)
  
  try {
    // Handle "Start from Scratch" option (template is null)
    if (template === null) {
      toast.success('Starting with blank configuration!')
      return // Don't load any template data, just show success message
    }
    
    // Map flat template data to nested form structure
    const templateData = template.data
    
    // Project Information mapping
    if (templateData.projectInfo?.name || templateData.projectInfo?.description || templateData.projectInfo?.website) {
      Object.assign(formData.value.projectInfo, {
        name: templateData.projectInfo?.name || formData.value.projectInfo.name,
        description: templateData.projectInfo?.description || formData.value.projectInfo.description,
        website: templateData.projectInfo?.website || formData.value.projectInfo.website,
        twitter: templateData.projectInfo?.twitter || formData.value.projectInfo.twitter,
        telegram: templateData.projectInfo?.telegram || formData.value.projectInfo.telegram,
        discord: templateData.projectInfo?.discord || formData.value.projectInfo.discord,
        whitepaper: templateData.projectInfo?.whitepaper || formData.value.projectInfo.whitepaper
      })
    }
    
    // Sale Token mapping
    if (templateData.saleToken?.name || templateData.saleToken?.symbol) {
      Object.assign(formData.value.saleToken, {
        name: templateData.saleToken?.name || formData.value.saleToken.name,
        symbol: templateData.saleToken?.symbol || formData.value.saleToken.symbol,
        decimals: templateData.saleToken?.decimals ?? formData.value.saleToken.decimals,
        totalSupply: templateData.saleToken?.totalSupply || formData.value.saleToken.totalSupply,
        transferFee: templateData.saleToken?.transferFee || formData.value.saleToken.transferFee,
        description: templateData.saleToken?.description || formData.value.saleToken.description
      })
    }
    
    // Sale Parameters mapping
    if (templateData.saleParams?.saleType || templateData.saleParams?.tokenPrice) {
      Object.assign(formData.value.saleParams, {
        saleType: templateData.saleParams?.saleType || formData.value.saleParams.saleType,
        allocationMethod: templateData.saleParams?.allocationMethod || formData.value.saleParams.allocationMethod,
        tokenPrice: templateData.saleParams?.tokenPrice || formData.value.saleParams.tokenPrice,
        softCap: templateData.saleParams?.softCap || formData.value.saleParams.softCap,
        hardCap: templateData.saleParams?.hardCap || formData.value.saleParams.hardCap,
        minContribution: templateData.saleParams?.minContribution || formData.value.saleParams.minContribution,
        maxContribution: templateData.saleParams?.maxContribution || formData.value.saleParams.maxContribution,
        totalSaleAmount: templateData.saleParams?.totalSaleAmount || formData.value.saleParams.totalSaleAmount,
        requiresWhitelist: templateData.saleParams?.requiresWhitelist ?? formData.value.saleParams.requiresWhitelist,
        requiresKYC: templateData.saleParams?.requiresKYC ?? formData.value.saleParams.requiresKYC
      })
    }
    
    // Timeline mapping
    if (templateData.timeline?.saleStart || templateData.timeline?.saleEnd) {
      Object.assign(formData.value.timeline, {
        saleStart: templateData.timeline?.saleStart || formData.value.timeline.saleStart,
        saleEnd: templateData.timeline?.saleEnd || formData.value.timeline.saleEnd,
        claimStart: templateData.timeline?.claimStart || formData.value.timeline.claimStart
      })
    }
    
    // Note: Vesting properties are handled in the vesting configuration step
    // Template vesting configuration will be stored for later use
    
    // DEX Configuration mapping
    if (templateData.dexConfig) {
      Object.assign(formData.value.dexConfig, {
        platform: templateData.dexConfig.platform || formData.value.dexConfig.platform,
        totalLiquidityToken: templateData.dexConfig.totalLiquidityToken || formData.value.dexConfig.totalLiquidityToken,
        liquidityLockDays: templateData.dexConfig.liquidityLockDays || formData.value.dexConfig.liquidityLockDays,
        autoList: templateData.dexConfig.autoList ?? formData.value.dexConfig.autoList,
        lpTokenRecipient: templateData.dexConfig.lpTokenRecipient || formData.value.dexConfig.lpTokenRecipient
      })
    }

    // Distribution mapping - convert template fixed allocation structure
    if (templateData.distribution) {
      // Template now uses fixed allocation structure
      if (templateData.distribution.sale) {
        Object.assign(formData.value.distribution.sale, templateData.distribution.sale)
      }
      if (templateData.distribution.team) {
        Object.assign(formData.value.distribution.team, templateData.distribution.team)
      }
      if (templateData.distribution.liquidityPool) {
        Object.assign(formData.value.distribution.liquidityPool, templateData.distribution.liquidityPool)
      }
      if (templateData.distribution.others && Array.isArray(templateData.distribution.others)) {
        formData.value.distribution.others = [...templateData.distribution.others]
      }
    }
    
    // Force recalculation of allocations after template load
    // This ensures percentages are correct for the loaded template
    nextTick(() => {
      // Small delay to ensure all watchers have processed the template data
      setTimeout(() => {
        // Trigger percentage recalculation by briefly updating totalSupply
        const currentSupply = formData.value.saleToken.totalSupply
        if (currentSupply && Number(currentSupply) > 0) {
          formData.value.saleToken.totalSupply = (Number(currentSupply) + 1).toString()
          nextTick(() => {
            formData.value.saleToken.totalSupply = currentSupply
          })
        }
      }, 100)
    })
    
    // Show success message
    toast.success(`Template "${template.name}" loaded successfully!`)
    console.log('✅ Template loaded successfully!')
    console.log('Current step after:', currentStep.value)
    console.log('Can proceed after:', canProceed.value)
    console.log('Button should show:', currentStep.value < steps.length - 1)
    
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
  const selectedToken = PURCHASE_TOKEN_OPTIONS.find(token => token.value === canisterId)
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


// Token Logo handling functions
const triggerTokenLogoInput = () => {
  tokenLogoInput.value?.click()
}

const handleTokenLogoUpload = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.files && input.files[0]) {
    const file = input.files[0]
    tokenLogoError.value = ''

    // Validate file type
    if (!VALID_IMAGE_TYPES.includes(file.type)) {
      tokenLogoError.value = 'Please upload a valid image file (JPEG, PNG, GIF, or WebP)'
      return
    }

    // Validate file size (200KB max for token logo)
    if (file.size > MAX_TOKEN_LOGO_SIZE) {
      tokenLogoError.value = 'Logo size is too large, max size is 200KB'
      return
    }

    // Create preview and convert to base64
    const reader = new FileReader()
    reader.onload = (e) => {
      const result = e.target?.result as string
      tokenLogoPreview.value = result
      // Store the base64 data for the backend
      formData.value.saleToken.logo = result
    }
    reader.readAsDataURL(file)
  }
}

const removeTokenLogo = () => {
  tokenLogoPreview.value = ''
  tokenLogoError.value = ''
  formData.value.saleToken.logo = ''
  if (tokenLogoInput.value) {
    tokenLogoInput.value.value = ''
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
  const totalPurchaseLiquidity = totalPurchaseLiquidityRequired.value

  availableDEXs.value.forEach(dex => {
    if (dex.enabled && allocationPercentageTotal.value > 0) {
      // Calculate token liquidity for this DEX based on percentage
      dex.calculatedTokenLiquidity = (totalLiquidity * dex.allocationPercentage) / 100

      // Calculate purchase token liquidity based on percentage of total required
      dex.calculatedPurchaseLiquidity = (totalPurchaseLiquidity * dex.allocationPercentage) / 100
    } else {
      dex.calculatedTokenLiquidity = 0
      dex.calculatedPurchaseLiquidity = 0
    }
  })
}

const updateLiquidityCalculations = () => {
  redistributeLiquidity()

  // The liquidity calculations are now based on percentage of raised funds
  // No need for fixed price calculations since pricing is dynamic
}

// Dynamic Raised Funds Methods
const calculatePercentage = (amount: string | number): string => {
  const numAmount = Number(amount) || 0
  const available = Math.max(0, raisedFundsAfterFees.value.availableForLiquidity)
  if (available === 0) return '0.0'
  return ((numAmount / available) * 100).toFixed(1)
}

const addDynamicAllocation = () => {
  const allocationTypes = [
    'Development Fund',
    'Marketing Fund', 
    'Liquidity Fund',
    'Reserve Fund',
    'Advisor Fund',
    'Partnership Fund',
    'Legal & Compliance',
    'Audit & Security'
  ]
  
  const existingNames = formData.value.raisedFundsAllocation.allocations.map(a => a.name)
  const availableTypes = allocationTypes.filter(type => !existingNames.includes(type))
  
  const newName = availableTypes.length > 0 
    ? availableTypes[0] 
    : `Custom Allocation ${formData.value.raisedFundsAllocation.allocations.length + 1}`
  
  formData.value.raisedFundsAllocation.allocations.push({
    id: `allocation-${Date.now()}`,
    name: newName,
    amount: '',
    percentage: 0,
    recipients: []
  })
}

const removeDynamicAllocation = (index: number) => {
  // Can't remove Team Allocation (first item)
  if (index > 0) {
    formData.value.raisedFundsAllocation.allocations.splice(index, 1)
  }
}

const updateAllocationPercentage = (index: number) => {
  const allocation = formData.value.raisedFundsAllocation.allocations[index]
  const availableAmount = raisedFundsAfterFees.value.availableForLiquidity
  
  if (availableAmount > 0) {
    allocation.percentage = (Number(allocation.amount) / availableAmount) * 100
  }
}

// Dynamic Allocation Recipients Management
const addRecipientToAllocation = (allocationId: string) => {
  const allocation = formData.value.raisedFundsAllocation.allocations.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.push({
      principal: '',
      percentage: 100,
      name: '',
      vestingEnabled: false,
      vestingSchedule: {
        cliffDays: 0,
        durationDays: allocationId === 'team' ? 365 : allocationId === 'development' ? 730 : 180,
        releaseFrequency: 'monthly',
        immediateRelease: 0
      }
    })
  }
}

const removeRecipientFromAllocation = (allocationId: string, recipientIndex: number) => {
  const allocation = formData.value.raisedFundsAllocation.allocations.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.splice(recipientIndex, 1)
  }
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

// Sync simulation amount with soft cap changes
watch(
  () => softCapAmount.value,
  (newSoftCap) => {
    // Only update if simulation amount is still at or below the old soft cap
    // This preserves user's manual adjustments while ensuring it starts from soft cap
    if (simulatedAmount.value <= (softCapAmount.value || 1000) || simulatedAmount.value === 0) {
      simulatedAmount.value = Math.max(newSoftCap || 1000, 1000)
    }
  },
  { immediate: true }
)

// Initialize default purchase token
const initializeDefaults = () => {
  // Set default purchase token to ICP
  handlePurchaseTokenChange('ryjl3-tyaaa-aaaaa-aaaba-cai')
}

// Initialize defaults on component mount
initializeDefaults()

// Load deployment cost
const loadDeploymentCost = async () => {
  try {
    creationCostBigInt.value = await backendService.getDeploymentFee('launchpad_factory')
  } catch (error) {
    console.error('Error loading deployment cost:', error)
    creationCostBigInt.value = BigInt(50_000_000) // 0.5 ICP fallback
  }
}

// Helper function to handle approve result
const hanldeApproveResult = (result: any): { error?: { message: string } } => {
  if ('Err' in result) {
    return { error: { message: result.Err } }
  }
  return {}
}

// Payment approval flow
const handlePayment = async () => {
  if (!canLaunch.value) return

  const isConfirmed = await Swal.fire({
    title: 'Are you sure?',
    text: 'You are about to deploy a launchpad. This action is irreversible.',
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
    'Deploying launchpad to canister...',
    'Initializing contract...',
    'Finalizing deployment...'
  ]

  let deployPrice = BigInt(0)
  let icpToken: any | null = null
  let backendCanisterId = ''
  let approveAmount = BigInt(0)

  // Main step runner
  const runSteps = async () => {
    for (let i = 0; i < steps.length; i++) {
      progress.setStep(i)

      try {
        switch (i) {
          case 0: // Get deployment price
            deployPrice = await backendService.getDeploymentFee('launchpad_factory')
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

            const now = BigInt(Date.now()) * 1_000_000n // nanoseconds
            const oneHour = 60n * 60n * 1_000_000_000n  // 1 hour in nanoseconds

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

          case 3: // Deploy launchpad
            const result = await createLaunchpadService(formData.value as any)

            if (!result) {
              throw new Error('Launchpad deployment failed')
            }

            deployResult.value = {
              launchpadId: result.launchpadId,
              canisterId: result.canisterId,
              success: true
            }
            break

          case 4: // Initialize contract (handled in service)
            // Contract initialization is handled in the service layer
            break

          case 5: // Finalize deployment
            showSuccessModal.value = true
            isPaying.value = false
            progress.setLoading(false)
            progress.close()

            // Navigate to launchpad detail after short delay
            setTimeout(() => {
              if (deployResult.value?.launchpadId) {
                router.push(`/launchpad/${deployResult.value.launchpadId}`)
              }
            }, 2000)
            return
        }

        await new Promise(resolve => setTimeout(resolve, 500))
      } catch (error: unknown) {
        throw error
      }
    }
  }

  // Start the deployment process
  progress.open({
    steps,
    title: 'Deploying Launchpad',
    subtitle: 'Please wait while we process your deployment'
  })

  try {
    progress.setLoading(true)
    progress.setStep(0)
    await runSteps()
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

// Legacy function for backward compatibility
const createLaunchpad = async () => {
  await handlePayment()
}

// Load deployment cost on mount
loadDeploymentCost()

// These functions are now handled by TypeConverter in the service layer
</script>