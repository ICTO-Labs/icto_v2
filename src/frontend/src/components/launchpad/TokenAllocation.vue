<template>
  <div class="space-y-4">
    <!-- Header -->
    <!-- <div class="flex items-center justify-between mb-4">
      <div>
        <h4 class="text-sm font-medium text-gray-900 dark:text-white mb-1">Token Distribution Allocation</h4>
        <p class="text-xs text-gray-500 dark:text-gray-400">Configure how tokens will be distributed across 4 fixed categories</p>
      </div>
    </div> -->

    <!-- Allocation Progress - Moved to top -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-4">
      <div class="flex items-center justify-between mb-3">
        <h5 class="font-medium text-blue-900 dark:text-blue-100">Total Token Supply</h5>
        <span class="text-lg font-bold text-blue-600 dark:text-blue-400">{{ formatTokenAmount(totalSupply) }}</span>
      </div>
      <div class="space-y-2">
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Total Allocated:</span>
          <span class="font-medium text-blue-800 dark:text-blue-200">{{ formatTokenAmount(totalAllocated) }} ({{ allocationPercentage.toFixed(2) }}%)</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-blue-700 dark:text-blue-300">Remaining:</span>
          <span class="font-medium" :class="remainingTokens < 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400'">
            {{ formatTokenAmount(Math.abs(remainingTokens)) }}
          </span>
        </div>
        <!-- Progress Bar -->
        <div class="w-full bg-blue-100 dark:bg-blue-800 rounded-full h-2 overflow-hidden">
          <div 
            :style="{ width: Math.min(allocationPercentage, 100) + '%' }" 
            class="h-2 rounded-full transition-all duration-500"
            :class="allocationPercentage > 100 ? 'bg-red-500' : 'bg-blue-500'"
          ></div>
        </div>
      </div>
    </div>

    <!-- Liquidity Pool Info - Configured in Step 3 -->
    <!-- <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-4">
      <div class="flex items-start space-x-3">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
        </div>
        <div class="flex-1">
          <h5 class="font-medium text-blue-900 dark:text-blue-100 mb-1">DEX Liquidity Pool Allocation</h5>
          <p class="text-sm text-blue-700 dark:text-blue-300">
            DEX liquidity is automatically calculated from <strong>Raised Funds Allocation</strong> in Step 3 (Allocation Configuration).
            The token amount will be determined based on the percentage you allocate to DEX liquidity from your raised funds.
          </p>
          <p class="text-xs text-blue-600 dark:text-blue-400 mt-2">
            ➜ Configure DEX liquidity percentage and multi-DEX distribution in <strong>Step 3</strong>
          </p>
        </div>
      </div>
    </div> -->

    <!-- Fixed Categories Accordion -->
    <div class="space-y-2">
      <!-- Sale Category -->
      <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
        <button
          @click="toggleAccordion('sale')"
          class="w-full px-4 py-3 bg-gradient-to-r from-blue-50 to-blue-100 dark:from-blue-900/30 dark:to-blue-800/30 hover:from-blue-100 hover:to-blue-150 dark:hover:from-blue-900/50 dark:hover:to-blue-800/50 transition-colors text-left"
          type="button"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <span class="font-medium text-blue-900 dark:text-blue-100">Fairlaunch</span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-600 text-white">
                {{ formatTokenAmount(parseFloat(distributionData.sale.totalAmount)) }}
              </span>
            </div>
            <ChevronDown 
              class="h-4 w-4 text-blue-600 dark:text-blue-400 transition-transform duration-200"
              :class="{ 'rotate-180': openAccordions.sale }"
            />
          </div>
        </button>
        
        <div 
          v-show="openAccordions.sale"
          class="px-4 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700"
        >
          <div class="space-y-4">
            <!-- Total Amount and Description in Grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Total amount:</label>
                <money3
                  v-bind="MONEY3_OPTIONS"
                  v-model="distributionData.sale.totalAmount"
                  @input="updateSaleFromAmount"
                  placeholder="0"
                  class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description:</label>
                <input
                  v-model="distributionData.sale.description"
                  type="text"
                  placeholder="Tokens available for public sale"
                  class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                />
              </div>
            </div>

            <!-- Vesting Section -->
            <div>
              <div class="flex items-center mb-3">
                <label class="relative inline-flex items-center cursor-pointer mr-3">
                  <input 
                    v-model="saleVestingEnabled" 
                    type="checkbox" 
                    class="sr-only peer"
                  >
                  <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-blue-300 dark:peer-focus:ring-blue-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-blue-600"></div>
                </label>
                <label 
                  @click="saleVestingEnabled = !saleVestingEnabled"
                  class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
                >
                  Enable Vesting Schedule
                </label>
              </div>
              <VestingScheduleConfig 
                v-if="saleVestingEnabled"
                v-model="distributionData.sale.vestingSchedule"
                allocation-name="Sale"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Liquidity Category - Hidden (configured in MultiDexConfig) -->
      <div v-if="false" class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
        <button
          @click="toggleAccordion('liquidityPool')"
          class="w-full px-4 py-3 bg-gradient-to-r from-orange-50 to-orange-100 dark:from-orange-900/30 dark:to-orange-800/30 hover:from-orange-100 hover:to-orange-150 dark:hover:from-orange-900/50 dark:hover:to-orange-800/50 transition-colors text-left"
          type="button"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <span class="font-medium text-orange-900 dark:text-orange-100">Liquidity</span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-orange-600 text-white">
                {{ formatTokenAmount(parseFloat(distributionData.liquidityPool.totalAmount)) }}
              </span>
            </div>
            <ChevronDown 
              class="h-4 w-4 text-orange-600 dark:text-orange-400 transition-transform duration-200"
              :class="{ 'rotate-180': openAccordions.liquidityPool }"
            />
          </div>
        </button>
        
        <div 
          v-show="openAccordions.liquidityPool"
          class="px-4 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700"
        >
          <div class="space-y-4">
            <!-- LP Allocation Method Selection -->
            <div class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-white dark:bg-gray-800">
              <h6 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">LP Allocation Method</h6>
              <div class="space-y-3">
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    v-model="lpAllocationMethod"
                    value="token-supply"
                    type="radio"
                    class="w-4 h-4 text-orange-600 border-gray-300 focus:ring-orange-500"
                  />
                  <div>
                    <div class="text-sm font-medium text-gray-900 dark:text-white">Based on Token Supply (%)</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">Define percentage of total supply → Calculate ICP amount needed</div>
                  </div>
                </label>
                <label class="flex items-center space-x-3 cursor-pointer">
                  <input
                    v-model="lpAllocationMethod"
                    value="raised-funds"
                    type="radio"
                    class="w-4 h-4 text-orange-600 border-gray-300 focus:ring-orange-500"
                  />
                  <div>
                    <div class="text-sm font-medium text-gray-900 dark:text-white">Based on Raised Funds (%)</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">Define percentage of raised funds → Calculate token amount</div>
                  </div>
                </label>
              </div>
            </div>

            <!-- Configuration based on selected method -->
            <div v-if="lpAllocationMethod === 'token-supply'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Token Supply Percentage:</label>
                <div class="flex items-center space-x-2">
                  <input
                    v-model.number="lpTokenPercentage"
                    @input="updateLiquidityAllocation"
                    type="number"
                    min="0"
                    max="100"
                    step="0.1"
                    class="flex-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                  />
                  <span class="text-sm text-gray-500">%</span>
                </div>
                <p class="text-xs text-orange-600 dark:text-orange-400 mt-1">
                  {{ formatTokenAmount(lpTokenSupplyAmount) }} tokens
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Estimated ICP Needed:</label>
                <input
                  :value="formatAmount(estimatedIcpForTokenSupply)"
                  readonly
                  class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-gray-100 dark:bg-gray-600 cursor-not-allowed"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  Range: {{ formatAmount(estimatedIcpMinMax.min) }} - {{ formatAmount(estimatedIcpMinMax.max) }} ICP
                </p>
              </div>
            </div>

            <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Raised Funds Percentage:</label>
                <div class="flex items-center space-x-2">
                  <input
                    v-model.number="lpRaisedPercentage"
                    @input="updateLiquidityAllocation"
                    type="number"
                    min="0"
                    max="100"
                    step="0.1"
                    class="flex-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                  />
                  <span class="text-sm text-gray-500">%</span>
                </div>
                <p class="text-xs text-orange-600 dark:text-orange-400 mt-1">
                  {{ formatAmount(lpRaisedFundsAmount) }} ICP (simulated)
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Calculated Token Amount:</label>
                <input
                  :value="formatTokenAmount(lpRaisedTokenAmount)"
                  readonly
                  class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-gray-100 dark:bg-gray-600 cursor-not-allowed"
                />
                <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  Wait for sale ends or estimate via simulator
                </p>
              </div>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description:</label>
              <input
                v-model="distributionData.liquidityPool.description"
                @input="emitUpdate"
                type="text"
                placeholder="Auto-calculated liquidity pool allocation"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
              />
            </div>

            <!-- DEX Configuration Section -->
            <div class="border border-orange-200 dark:border-orange-700 rounded-lg p-4 bg-orange-50 dark:bg-orange-900/20">
              <h6 class="text-sm font-medium text-orange-800 dark:text-orange-200 mb-3">DEX Configuration</h6>
              
              <div class="space-y-4">
                <!-- DEX Enable Toggle -->
                <div class="flex items-center justify-between">
                  <div>
                    <div class="text-sm font-medium text-gray-900 dark:text-white">Enable DEX Listing</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">Automatically list token on DEX with liquidity pool</div>
                  </div>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input 
                      v-model="dexEnabled" 
                      type="checkbox" 
                      class="sr-only peer"
                    >
                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-orange-300 dark:peer-focus:ring-orange-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-orange-600"></div>
                  </label>
                </div>

                <!-- DEX Configuration when enabled -->
                <div v-if="dexEnabled" class="grid grid-cols-1 md:grid-cols-2 gap-4 pt-4 border-t border-orange-300 dark:border-orange-600">
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Target Token Price:</label>
                    <div class="flex items-center space-x-2">
                      <input
                        v-model.number="dexTokenPrice"
                        type="number"
                        step="0.001"
                        min="0"
                        class="flex-1 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                      />
                      <span class="text-sm text-gray-500">ICP per token</span>
                    </div>
                  </div>
                  
                  <div>
                    <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">LP Lock Duration:</label>
                    <select
                      v-model="dexLockDuration"
                      class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                    >
                      <option value="0">No Lock</option>
                      <option value="30">30 Days</option>
                      <option value="90">90 Days</option>
                      <option value="180">180 Days</option>
                      <option value="365">1 Year</option>
                    </select>
                  </div>
                </div>

                <!-- Status and Info -->
                <div class="text-xs text-orange-600 dark:text-orange-400 pt-2 border-t border-orange-200 dark:border-orange-700">
                  <div v-if="dexEnabled && lpAllocationMethod === 'token-supply'">
                    🔗 <strong>Token Supply Method:</strong> LP amount {{ formatTokenAmount(lpTokenSupplyAmount) }} tokens → Need {{ formatAmount(estimatedIcpForTokenSupply) }} ICP for liquidity
                  </div>
                  <div v-else-if="dexEnabled && lpAllocationMethod === 'raised-funds'">
                    💰 <strong>Raised Funds Method:</strong> Using {{ lpRaisedPercentage }}% of raised funds ({{ formatAmount(lpRaisedFundsAmount) }} ICP) → Get {{ formatTokenAmount(lpRaisedTokenAmount) }} tokens
                  </div>
                  <div v-else>
                    ⚠️ <strong>DEX Disabled:</strong> No automatic DEX listing. Tokens need to be available immediately for manual liquidity provision.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Team Category -->
      <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
        <button
          @click="toggleAccordion('team')"
          class="w-full px-4 py-3 bg-gradient-to-r from-green-50 to-green-100 dark:from-green-900/30 dark:to-green-800/30 hover:from-green-100 hover:to-green-150 dark:hover:from-green-900/50 dark:hover:to-green-800/50 transition-colors text-left"
          type="button"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <span class="font-medium text-green-900 dark:text-green-100">Team</span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-600 text-white">
                {{ formatTokenAmount(parseFloat(distributionData.team.totalAmount)) }}
              </span>
              <ChevronUp 
                v-if="openAccordions.team"
                class="h-4 w-4 text-green-600"
              />
            </div>
            <ChevronDown 
              class="h-4 w-4 text-green-600 dark:text-green-400 transition-transform duration-200"
              :class="{ 'rotate-180': openAccordions.team }"
            />
          </div>
        </button>
        
        <div 
          v-show="openAccordions.team"
          class="px-4 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700"
        >
          <div class="space-y-4">
            <!-- Total Amount and Description -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Total amount (calculated from recipients):</label>
                <input
                  :value="teamTotalAmount"
                  readonly
                  class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-gray-100 dark:bg-gray-600 cursor-not-allowed"
                />
                <p class="text-xs text-blue-600 dark:text-blue-400 mt-1">
                  Auto-calculated from team recipients below
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description:</label>
                <input
                  v-model="distributionData.team.description"
                  @input="emitUpdate"
                  type="text"
                  placeholder="Team allocation"
                  class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                />
              </div>
            </div>

            <!-- Vesting Section -->
            <div>
              <div class="flex items-center mb-3">
                <label class="relative inline-flex items-center cursor-pointer mr-3">
                  <input 
                    v-model="teamVestingEnabled" 
                    type="checkbox" 
                    class="sr-only peer"
                  >
                  <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-green-300 dark:peer-focus:ring-green-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-green-600"></div>
                </label>
                <label 
                  @click="teamVestingEnabled = !teamVestingEnabled"
                  class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
                >
                  Enable Vesting Schedule
                </label>
              </div>
              <VestingScheduleConfig 
                v-if="teamVestingEnabled"
                v-model="distributionData.team.vestingSchedule"
                allocation-name="Team"
              />
            </div>

            <!-- Recipients Section -->
            <div>
              <RecipientManagementV2
                v-model="distributionData.team.recipients"
                title="Team Recipients"
                help-text="Configure principals who will receive team token allocation."
                empty-message="⚠️ At least one team recipient is required for non-zero team allocation"
                allocation-type="tokens"
                value-type="amount"
                :token-symbol="saleToken?.symbol || 'Token'"
                @add-recipient="addTeamMember"
                @remove-recipient="removeTeamMember"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Others Category -->
      <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
        <button
          @click="toggleAccordion('others')"
          class="w-full px-4 py-3 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-left"
          type="button"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center space-x-3">
              <span class="font-medium text-gray-900 dark:text-white">Others</span>
              <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200">
                {{ distributionData.others.length }}
              </span>
            </div>
            <ChevronDown 
              class="h-4 w-4 text-gray-500 transition-transform duration-200"
              :class="{ 'rotate-180': openAccordions.others }"
            />
          </div>
        </button>
        
        <div 
          v-show="openAccordions.others"
          class="px-4 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700"
        >
          <!-- Add Category Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <button 
              @click="addQuickAllocation('Marketing', 5)"
              type="button"
              class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-xs rounded-md transition-colors"
            >
              + Marketing
            </button>
            <button 
              @click="addQuickAllocation('Advisors', 3)"
              type="button"
              class="px-3 py-1 bg-green-600 hover:bg-green-700 text-white text-xs rounded-md transition-colors"
            >
              + Advisors
            </button>
            <button 
              @click="addQuickAllocation('Development', 10)"
              type="button"
              class="px-3 py-1 bg-indigo-600 hover:bg-indigo-700 text-white text-xs rounded-md transition-colors"
            >
              + Development
            </button>
            <button
              @click="addOtherCategory"
              type="button"
              class="px-3 py-1 bg-purple-600 hover:bg-purple-700 text-white text-xs rounded-md transition-colors"
            >
              + Custom
            </button>
          </div>

          <!-- Other Categories List -->
          <div v-if="distributionData.others.length === 0" class="p-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded text-sm text-gray-600 dark:text-gray-400 text-center">
            💡 Click the buttons above to add custom allocations
          </div>

          <div v-else class="space-y-4">
            <div
              v-for="(category, index) in distributionData.others"
              :key="`other-${index}`"
              class="p-4 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg"
            >
              <!-- Category Header -->
              <div class="flex items-center justify-between mb-3">
                <input
                  v-model="category.name"
                  placeholder="Category name (e.g., Marketing)"
                  class="text-lg font-medium bg-transparent border-none outline-none text-gray-900 dark:text-white placeholder-gray-400 flex-1"
                />
                <button
                  @click="removeOtherCategory(index)"
                  type="button"
                  class="p-1 text-red-600 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900/20 rounded transition-colors"
                >
                  <X class="h-4 w-4" />
                </button>
              </div>

              <!-- Amount and Description -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Total amount (calculated from recipients):</label>
                  <input
                    :value="getOtherCategoryTotalAmount(index)"
                    readonly
                    class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-gray-100 dark:bg-gray-600 cursor-not-allowed"
                  />
                  <p class="text-xs text-purple-600 dark:text-purple-400 mt-1">
                    Auto-calculated from recipients below
                  </p>
                </div>
                <div>
                  <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Description:</label>
                  <input
                    v-model="category.description"
                    @input="emitUpdate"
                    type="text"
                    placeholder="Describe this allocation"
                    class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800"
                  />
                </div>
              </div>

              <!-- Vesting for Category -->
              <div class="mb-3">
                <div class="flex items-center mb-3">
                  <label class="relative inline-flex items-center cursor-pointer mr-3">
                    <input 
                      v-model="category.vestingEnabled" 
                      type="checkbox" 
                      class="sr-only peer"
                    >
                    <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-purple-300 dark:peer-focus:ring-purple-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-purple-600"></div>
                  </label>
                  <label 
                    @click="category.vestingEnabled = !category.vestingEnabled"
                    class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
                  >
                    Enable Vesting Schedule
                  </label>
                </div>
                <VestingScheduleConfig 
                  v-if="category.vestingEnabled"
                  v-model="category.vestingSchedule"
                  :allocation-name="category.name || 'Custom'"
                />
              </div>

              <!-- Recipients -->
              <div>
                <div class="flex items-center justify-between mb-3">
                  <div class="flex items-center space-x-2">
                    <h6 class="text-sm font-medium text-gray-700 dark:text-gray-300">{{ category.name || 'Custom' }} Recipients</h6>
                    <span class="text-sm text-gray-500 dark:text-gray-400">({{ category.recipients.length }} participants)</span>
                  </div>
                  <button
                    @click="addCategoryRecipient(index)"
                    type="button"
                    class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
                  >
                    Add Recipient
                  </button>
                </div>

                <div v-if="category.recipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-dashed border-yellow-300 dark:border-yellow-700 rounded-lg text-sm text-yellow-800 dark:text-yellow-200">
                  ⚠️ At least one recipient is required for non-zero {{ category.name || 'custom' }} allocation
                </div>

                <!-- Recipients Table -->
                <div v-else class="overflow-x-auto">
                  <table class="w-full border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
                    <thead class="bg-gray-50 dark:bg-gray-800">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          Token Amount *
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          Principal *
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          Name/Notes
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                          Action
                        </th>
                      </tr>
                    </thead>
                    <tbody class="bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700">
                      <tr v-for="(recipient, recipientIndex) in category.recipients" :key="`other-${index}-recipient-${recipientIndex}`" class="hover:bg-gray-50 dark:hover:bg-gray-800">
                        <td class="px-4 py-3">
                          <input
                            v-model="recipient.amount"
                            type="text"
                            placeholder="5,000"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800"
                            :class="{ 'border-red-500': !isValidTokenAmount(recipient.amount || '') && recipient.amount }"
                          />
                          <p v-if="!isValidTokenAmount(recipient.amount || '') && recipient.amount" class="text-xs text-red-600 mt-1">
                            Invalid token amount
                          </p>
                        </td>
                        <td class="px-4 py-3">
                          <input
                            v-model="recipient.principal"
                            type="text"
                            placeholder="Principal ID"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800"
                            :class="{ 'border-red-500': !isValidPrincipal(recipient.principal) && recipient.principal }"
                          />
                          <p v-if="!isValidPrincipal(recipient.principal) && recipient.principal" class="text-xs text-red-600 mt-1">
                            Invalid principal format
                          </p>
                        </td>
                        <td class="px-4 py-3">
                          <input
                            v-model="recipient.name"
                            type="text"
                            placeholder="Optional name"
                            class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800"
                          />
                        </td>
                        <td class="px-4 py-3 whitespace-nowrap">
                          <button
                            @click="removeCategoryRecipient(index, recipientIndex)"
                            type="button"
                            class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300"
                          >
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                            </svg>
                          </button>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Total Supply and Chart Section -->
    <!-- <div class="mt-6 text-center">
      <div class="text-lg font-medium text-gray-900 dark:text-white mb-2">
        Total Supply: <span class="text-blue-600 dark:text-blue-400">{{ formatTokenAmount(totalSupply) }}</span>
      </div>
      
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-4">
        <div 
          class="bg-blue-600 h-2 rounded-full transition-all duration-300"
          :style="{ width: `${Math.min(allocationPercentage, 100)}%` }"
        ></div>
      </div>
      
      <div class="text-sm text-gray-600 dark:text-gray-400">
        Allocated: {{ allocationPercentage.toFixed(1) }}% 
        ({{ formatTokenAmount(totalAllocated) }} / {{ formatTokenAmount(totalSupply) }})
      </div>
    </div> -->

    <!-- Validation Messages -->
    <div v-if="validationErrors.length > 0" class="bg-red-50 dark:bg-red-900/20 border-2 border-dashed border-red-300 dark:border-red-700 rounded-lg p-4">
      <h6 class="text-sm font-medium text-red-900 dark:text-red-100 mb-2">⚠️ Validation Errors</h6>
      <ul class="list-disc list-inside text-sm text-red-700 dark:text-red-300 space-y-1">
        <li v-for="error in validationErrors" :key="error">{{ error }}</li>
      </ul>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, nextTick } from 'vue'
import { Plus, X, ChevronDown, ChevronUp } from 'lucide-vue-next'
import VestingScheduleConfig from './VestingScheduleConfig.vue'
import RecipientManagementV2 from '@/components/launchpad_v2/RecipientManagementV2.vue'
import type { VestingSchedule } from '@/types/launchpad'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'
import { MONEY3_OPTIONS } from '@/config/constants'
interface TeamRecipient {
  principal: string
  percentage: number
  amount?: string
  name?: string
  description?: string
  vestingOverride?: VestingSchedule
}

interface OtherRecipient {
  principal: string
  percentage: number
  amount?: string
  name?: string
  description?: string
  vestingOverride?: VestingSchedule
}

interface OtherCategory {
  id: string
  name: string
  percentage: number
  totalAmount: string
  description?: string
  recipients: OtherRecipient[]
  vestingSchedule?: VestingSchedule
  vestingEnabled?: boolean
}

interface DistributionData {
  sale: {
    name: 'Sale'
    percentage: number
    totalAmount: string
    vestingSchedule?: VestingSchedule
    description?: string
  }
  team: {
    name: 'Team'
    percentage: number
    totalAmount: string
    vestingSchedule?: VestingSchedule
    recipients: TeamRecipient[]
    description?: string
  }
  liquidityPool: {
    name: 'Liquidity Pool'
    percentage: number
    totalAmount: string
    autoCalculated: boolean
    description?: string
  }
  others: OtherCategory[]
}

interface Props {
  saleTokenSymbol?: string // Only keep display props, not data
  // LP Allocation props (controlled from MultiDexConfig) - these are calculated externally
  lpAllocationMethodProp?: 'token-supply' | 'raised-funds'
  lpTokenPercentageProp?: number
  lpRaisedPercentageProp?: number
}

const props = withDefaults(defineProps<Props>(), {
  saleTokenSymbol: 'TOKEN'
})

// Use composable for data - single source of truth
const launchpadForm = useLaunchpadForm()
const { formData, simulatedAmount, estimatedTokenPrice } = launchpadForm

// Direct reference to distribution data from composable (no local copy!)
const distributionData = computed(() => formData.value.distribution)

// Accordion state - Sale expanded by default, others collapsed
const openAccordions = ref({
  sale: true,
  team: false,
  liquidityPool: false,
  others: false
})

// Vesting toggle states - initialized from composable data
const saleVestingEnabled = computed({
  get: () => {
    const schedule = distributionData.value?.sale?.vestingSchedule
    return !!(schedule && Object.keys(schedule).length > 0)
  },
  set: (value) => {
    if (!value) {
      // Remove vesting when disabled
      if (distributionData.value?.sale) {
        delete distributionData.value.sale.vestingSchedule
      }
    } else {
      // Initialize default vesting when enabled
      if (distributionData.value?.sale) {
        distributionData.value.sale.vestingSchedule = {
          cliffDays: 0,
          durationDays: 0,
          releaseFrequency: 'monthly',
          immediatePercentage: 100
        }
      }
    }
  }
})

const teamVestingEnabled = computed({
  get: () => {
    const schedule = distributionData.value?.team?.vestingSchedule
    return !!(schedule && Object.keys(schedule).length > 0)
  },
  set: (value) => {
    if (!value) {
      // Remove vesting when disabled
      if (distributionData.value?.team) {
        delete distributionData.value.team.vestingSchedule
      }
    } else {
      // Initialize default vesting when enabled
      if (distributionData.value?.team) {
        distributionData.value.team.vestingSchedule = {
          cliffDays: 365,
          durationDays: 1460,
          releaseFrequency: 'monthly',
          immediatePercentage: 0
        }
      }
    }
  }
})

// Liquidity Pool allocation method (synced with MultiDexConfig)
const lpAllocationMethod = ref<'token-supply' | 'raised-funds'>(props.lpAllocationMethodProp || 'token-supply')
const lpTokenPercentage = ref(props.lpTokenPercentageProp || 30) // Default 30% of token supply
const lpRaisedPercentage = ref(props.lpRaisedPercentageProp || 60) // Default 60% of raised funds

// DEX configuration
const dexEnabled = ref(false)
const dexTokenPrice = ref(0.001) // Default token price in ICP
const dexLockDuration = ref(90) // Default 90 days LP lock

// Computed total amounts from recipients
const teamTotalAmount = computed(() => {
  return distributionData.value.team.recipients.reduce((sum, recipient) => {
    return sum + (parseFloat(recipient.amount || '0') || 0)
  }, 0).toString()
})

const getOtherCategoryTotalAmount = (categoryIndex: number) => {
  const category = distributionData.value.others[categoryIndex]
  if (!category) return '0'
  return category.recipients.reduce((sum, recipient) => {
    return sum + (parseFloat(recipient.amount || '0') || 0)
  }, 0).toString()
}

// Get data from composable
const tokenSymbol = computed(() => formData.value?.saleToken?.symbol || 'Token')
const totalSupply = computed(() => Number(formData.value?.saleToken?.totalSupply) || 100000000)
const totalSaleAmount = computed(() => Number(formData.value?.saleParams?.totalSaleAmount) || 0)
const softCap = computed(() => Number(formData.value?.saleParams?.softCap) || 0)
const hardCap = computed(() => Number(formData.value?.saleParams?.hardCap) || 0)

// LP Allocation calculations
const lpTokenSupplyAmount = computed(() => {
  return (totalSupply.value * lpTokenPercentage.value) / 100
})

const lpRaisedFundsAmount = computed(() => {
  return ((simulatedAmount.value || 0) * lpRaisedPercentage.value) / 100
})

const lpRaisedTokenAmount = computed(() => {
  // This would be calculated based on the token price or ratio
  // For now, we'll use a simple calculation - in real scenario, this would come from
  // the sale price calculation
  const tokenPrice = (simulatedAmount.value || 0) / (totalSaleAmount.value || 1)
  return lpRaisedFundsAmount.value / tokenPrice
})

const estimatedIcpForTokenSupply = computed(() => {
  // Estimate ICP needed based on simulated raised amount and sale allocation
  const currentSimulated = simulatedAmount.value || 0
  if (currentSimulated === 0) return 0

  const tokenPrice = currentSimulated / (totalSaleAmount.value || 1)
  return lpTokenSupplyAmount.value * tokenPrice
})

const estimatedIcpMinMax = computed(() => {
  const softCapTokenPrice = (softCap.value || 0) / (totalSaleAmount.value || 1)
  const hardCapTokenPrice = (hardCap.value || 0) / (totalSaleAmount.value || 1)

  return {
    min: lpTokenSupplyAmount.value * softCapTokenPrice,
    max: lpTokenSupplyAmount.value * hardCapTokenPrice
  }
})

// Format helpers
const formatAmount = (amount: number): string => {
  return new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(amount)
}

// Sync LP allocation props from MultiDexConfig (only for display, not data)
watch(() => props.lpAllocationMethodProp, (newMethod) => {
  if (newMethod) {
    lpAllocationMethod.value = newMethod
  }
})

watch(() => props.lpTokenPercentageProp, (newPercentage) => {
  if (newPercentage !== undefined) {
    lpTokenPercentage.value = newPercentage
  }
})

watch(() => props.lpRaisedPercentageProp, (newPercentage) => {
  if (newPercentage !== undefined) {
    lpRaisedPercentage.value = newPercentage
  }
})

// Computed properties
const totalAllocated = computed(() => {
  const saleAmount = parseFloat(distributionData.value.sale.totalAmount) || 0
  const teamAmount = parseFloat(distributionData.value.team.totalAmount) || 0
  // Use computed LP amount from allocation method
  const lpAmount = lpAllocationMethod.value === 'token-supply'
    ? lpTokenSupplyAmount.value
    : lpRaisedTokenAmount.value
  const othersAmount = distributionData.value.others.reduce((sum, category) =>
    sum + (parseFloat(category.totalAmount) || 0), 0
  )
  return saleAmount + teamAmount + lpAmount + othersAmount
})

const allocationPercentage = computed(() => {
  return totalSupply.value > 0 ? (totalAllocated.value / totalSupply.value) * 100 : 0
})

const remainingTokens = computed(() => {
  return totalSupply.value - totalAllocated.value
})

const validationErrors = computed(() => {
  const errors: string[] = []
  
  if (allocationPercentage.value > 100) {
    errors.push('Total allocation exceeds 100% of token supply')
  }
  
  return errors
})

// Methods
const formatTokenAmount = (amount: number): string => {
  return new Intl.NumberFormat('en-US').format(amount)
}

const toggleAccordion = (section: keyof typeof openAccordions.value) => {
  openAccordions.value[section] = !openAccordions.value[section]
}

const updateSaleFromAmount = () => {
  const amount = parseFloat(distributionData.value.sale.totalAmount) || 0
  distributionData.value.sale.percentage = totalSupply.value > 0 ? (amount / totalSupply.value) * 100 : 0
  // No need to emit - composable is reactive
}

const updateTeamFromAmount = () => {
  const amount = parseFloat(distributionData.value.team.totalAmount) || 0
  distributionData.value.team.percentage = totalSupply.value > 0 ? (amount / totalSupply.value) * 100 : 0
  // No need to emit - composable is reactive
}

const updateOtherFromAmount = (index: number) => {
  const category = distributionData.value.others[index]
  const amount = parseFloat(category.totalAmount) || 0
  category.percentage = totalSupply.value > 0 ? (amount / totalSupply.value) * 100 : 0
  // No need to emit - composable is reactive
}

const updateLiquidityAllocation = () => {
  let amount = 0

  if (lpAllocationMethod.value === 'token-supply') {
    // Based on token supply percentage
    amount = lpTokenSupplyAmount.value
    distributionData.value.liquidityPool.totalAmount = amount.toString()
    distributionData.value.liquidityPool.percentage = lpTokenPercentage.value
  } else {
    // Based on raised funds percentage
    amount = lpRaisedTokenAmount.value
    distributionData.value.liquidityPool.totalAmount = amount.toString()
    distributionData.value.liquidityPool.percentage = totalSupply.value > 0 ? (amount / totalSupply.value) * 100 : 0
  }

  distributionData.value.liquidityPool.autoCalculated = true
  // No need to emit - composable is reactive
}

const updateLiquidityFromAmount = () => {
  const amount = parseFloat(distributionData.value.liquidityPool.totalAmount) || 0
  distributionData.value.liquidityPool.percentage = totalSupply.value > 0 ? (amount / totalSupply.value) * 100 : 0
  // No need to emit - composable is reactive
}

const addTeamMember = () => {
  distributionData.value.team.recipients.push({
    principal: '',
    percentage: 0,
    amount: '',
    name: ''
  })
  // No need to emit - composable is reactive
}

const removeTeamMember = (index: number) => {
  distributionData.value.team.recipients.splice(index, 1)
  // No need to emit - composable is reactive
}

const addQuickAllocation = (name: string, percentage: number) => {
  const id = `other-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  // Fix BigInt serialization: Always parse to Number first
  const totalSupplyNum = Number(totalSupply.value) || 0
  const amount = ((totalSupplyNum * percentage) / 100).toString()
  distributionData.value.others.push({
    id,
    name,
    percentage,
    totalAmount: amount,
    description: `${name} allocation`,
    recipients: [],
    vestingEnabled: false
  })
  // No need to emit - composable is reactive
}

const addOtherCategory = () => {
  const id = `other-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
  distributionData.value.others.push({
    id,
    name: '',
    percentage: 0,
    totalAmount: '0',
    description: '',
    recipients: [],
    vestingEnabled: false
  })
  // No need to emit - composable is reactive
}

const removeOtherCategory = (index: number) => {
  distributionData.value.others.splice(index, 1)
  // No need to emit - composable is reactive
}

const addCategoryRecipient = (categoryIndex: number) => {
  distributionData.value.others[categoryIndex].recipients.push({
    principal: '',
    percentage: 0,
    amount: '',
    name: ''
  })
  // No need to emit - composable is reactive
}

const removeCategoryRecipient = (categoryIndex: number, recipientIndex: number) => {
  distributionData.value.others[categoryIndex].recipients.splice(recipientIndex, 1)
  // No need to emit - composable is reactive
}

// Validation functions
const isValidPrincipal = (principal: string): boolean => {
  if (!principal || typeof principal !== 'string') return false
  // Basic principal validation: should have dashes and reasonable length
  return principal.length >= 10 && principal.includes('-') && /^[a-z0-9-]+$/.test(principal)
}

const isValidTokenAmount = (amount: string): boolean => {
  if (!amount || typeof amount !== 'string') return false
  // Remove commas and check if it's a valid number
  const cleanAmount = amount.replace(/,/g, '')
  const numAmount = parseFloat(cleanAmount)
  return !isNaN(numAmount) && numAmount > 0
}

// Watch for changes in recipients to update total amounts
watch(teamTotalAmount, (newAmount) => {
  distributionData.value.team.totalAmount = newAmount
  updateTeamFromAmount()
})

watch(() => distributionData.value.others, () => {
  // Update total amounts for all other categories when recipients change
  distributionData.value.others.forEach((category, index) => {
    category.totalAmount = getOtherCategoryTotalAmount(index)
    updateOtherFromAmount(index)
  })
}, { deep: true })

// Watch for LP allocation method changes
watch(lpAllocationMethod, () => {
  updateLiquidityAllocation()
})

watch([lpTokenPercentage, lpRaisedPercentage], () => {
  updateLiquidityAllocation()
})

// Watch for changes in totalSaleAmount from composable to update sale allocation
watch(totalSaleAmount, (newAmount) => {
  if (newAmount && newAmount !== parseFloat(distributionData.value.sale.totalAmount)) {
    distributionData.value.sale.totalAmount = newAmount.toString()
    updateSaleFromAmount()
  }
}, { immediate: true })

// Initialize
updateLiquidityAllocation()
</script>