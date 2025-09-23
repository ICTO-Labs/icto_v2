<template>
  <div class="space-y-6">
    <!-- Allocation Progress Summary -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Raised Funds Allocation Progress</h3>
      
      <div class="space-y-2">
        <!-- DEX Liquidity (if enabled) -->
        <div v-if="dexConfig.autoList" class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">DEX Liquidity ({{ dexLiquidityPercentage.toFixed(1) }}%):</span>
          <span class="font-medium text-blue-600">{{ formatAmount(calculatedDexLiquidity) }} ICP</span>
        </div>

        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Team ({{ teamPercentage.toFixed(1) }}%):</span>
          <span class="font-medium">{{ formatAmount(teamAmount) }} ICP</span>
        </div>
        <div v-for="allocation in validCustomAllocations" :key="allocation.id" class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">{{ allocation.name }} ({{ allocation.percentage.toFixed(1) }}%):</span>
          <span class="font-medium">{{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP</span>
        </div>
        <div class="border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
          <div class="flex justify-between text-sm font-semibold">
            <span>Total Allocated ({{ totalAllocationPercentageWithDex.toFixed(1) }}%):</span>
            <span>{{ formatAmount(totalAllocationAmountWithDex) }} ICP</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">Remaining to Treasury ({{ remainingPercentageWithDex.toFixed(1) }}%):</span>
            <span class="font-medium text-green-600">{{ formatAmount(remainingAmountWithDex) }} ICP</span>
          </div>
        </div>
      </div>

      <!-- Progress Bar -->
      <div class="mt-4">
        <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
          <span>Allocation Progress</span>
          <span>{{ totalAllocationPercentageWithDex.toFixed(1) }}% of raised funds</span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div 
            class="bg-blue-600 h-2 rounded-full transition-all duration-300"
            :style="{ width: `${Math.min(totalAllocationPercentageWithDex, 100)}%` }"
          ></div>
        </div>
      </div>
    </div>

    <!-- Raised Funds Slider -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Raised Funds Simulation</h3>
      
      <div class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Simulate Raised Amount: {{ formatAmount(currentRaisedAmount) }} ICP <HelpTooltip>Adjust this slider to see how different funding levels affect your allocation percentages and amounts. Plan for various scenarios.</HelpTooltip>
          </label>
          <input
            v-model.number="currentRaisedAmount"
            type="range"
            :min="softCapNumber"
            :max="hardCapNumber"
            :step="stepSize"
            class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
          />
          <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-1">
            <span>Soft Cap: {{ formatAmount(softCapNumber) }} ICP</span>
            <span>Hard Cap: {{ formatAmount(hardCapNumber) }} ICP</span>
          </div>
        </div>
        
        <!-- Platform Fee Display -->
        <div class="bg-gray-50 dark:bg-gray-900 rounded-lg p-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">Raised Amount:</span>
            <span class="font-medium">{{ formatAmount(currentRaisedAmount) }} ICP</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">Platform Fee ({{ platformFeeRate }}%):</span>
            <span class="font-medium text-red-600">-{{ formatAmount(platformFee) }} ICP</span>
          </div>
          <div v-if="dexLiquidityFee > 0" class="flex justify-between text-sm">
            <span class="text-gray-600 dark:text-gray-400">DEX Liquidity Required:</span>
            <span class="font-medium text-orange-600">-{{ formatAmount(dexLiquidityFee) }} ICP</span>
          </div>
          <div class="flex justify-between text-sm font-semibold border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
            <span>Available for Allocation:</span>
            <span class="text-green-600">{{ formatAmount(availableForAllocation) }} ICP</span>
          </div>
        </div>
      </div>
    </div>

    <!-- DEX Configuration -->
    <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden transition-all duration-300">
      <!-- Enable Auto Listing Toggle Header -->
      <div
        class="p-4 cursor-pointer transition-all duration-300"
        :class="[
          dexConfig.autoList
            ? 'bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 border-b border-blue-200 dark:border-blue-800'
            : 'bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700'
        ]"
        @click="toggleAutoListing"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <!-- Toggle Switch -->
            <div class="relative">
              <input
                type="checkbox"
                :checked="dexConfig.autoList"
                :id="autoListMainId"
                class="sr-only"
                @click.stop
                @change="handleAutoListToggle"
              />
              <div
                class="w-12 h-6 rounded-full transition-all duration-300 ease-in-out"
                :class="[
                  dexConfig.autoList
                    ? 'bg-gradient-to-r from-blue-500 to-indigo-600 shadow-lg'
                    : 'bg-gray-300 dark:bg-gray-600'
                ]"
              >
                <div
                  class="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow-md transition-transform duration-300 ease-in-out"
                  :class="{ 'transform translate-x-6': dexConfig.autoList }"
                ></div>
              </div>
            </div>

            <!-- Title and Description -->
            <div>
              <div class="flex items-center space-x-2">
                <h3
                  class="text-lg font-semibold transition-colors duration-300"
                  :class="[
                    dexConfig.autoList
                      ? 'text-blue-900 dark:text-blue-100'
                      : 'text-gray-700 dark:text-gray-300'
                  ]"
                >
                  🚀 Enable Auto DEX Listing
                </h3>
                <span
                  v-if="dexConfig.autoList"
                  class="px-2 py-1 text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300 rounded-full animate-pulse"
                >
                  ACTIVE
                </span>
              </div>
              <p
                class="text-sm mt-1 transition-colors duration-300"
                :class="[
                  dexConfig.autoList
                    ? 'text-blue-700 dark:text-blue-300'
                    : 'text-gray-500 dark:text-gray-400'
                ]"
              >
                {{ dexConfig.autoList
                  ? 'Multi-DEX configuration is enabled. Your token will be automatically listed on selected platforms.'
                  : 'Click to enable automatic listing on multiple DEX platforms with smart liquidity allocation'
                }}
              </p>
            </div>
          </div>

          <!-- Expand/Collapse Icon -->
          <div class="flex items-center space-x-3">
            <div
              v-if="dexConfig.autoList && enabledDEXCount > 0"
              class="text-right"
            >
              <div class="text-sm font-medium text-blue-600 dark:text-blue-400">
                {{ enabledDEXCount }} DEX{{ enabledDEXCount > 1 ? 's' : '' }} Selected
              </div>
              <div class="text-xs text-blue-500 dark:text-blue-400">
                ${{ formatNumber(estimatedTotalTVL) }} Est. TVL
              </div>
            </div>

            <div
              class="p-2 rounded-full transition-all duration-300"
              :class="[
                dexConfig.autoList
                  ? 'bg-blue-100 dark:bg-blue-900/50'
                  : 'bg-gray-100 dark:bg-gray-700'
              ]"
            >
              <svg
                class="w-5 h-5 transition-transform duration-300"
                :class="[
                  dexConfig.autoList ? 'rotate-180 text-blue-600' : 'text-gray-500',
                ]"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
              </svg>
            </div>
          </div>
        </div>
      </div>

      <!-- Expandable Multi-DEX Configuration -->
      <div
        class="transition-all duration-500 ease-in-out"
        :class="{
          'max-h-0 opacity-0 overflow-hidden': !dexConfig.autoList,
          'max-h-screen opacity-100 overflow-visible': dexConfig.autoList
        }"
      >
        <div v-if="dexConfig.autoList" class="p-6 bg-gradient-to-br from-blue-50/50 to-indigo-50/50 dark:from-blue-900/10 dark:to-indigo-900/10">

      <!-- Global Settings -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        <!-- Liquidity Allocation Percentage -->
        <!-- LP Allocation Method Selection -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
            Liquidity Pool Allocation Method* (Current: {{ lpAllocationMethod }})
            <HelpTooltip>Choose how to calculate liquidity pool token allocation: based on token supply percentage or raised funds percentage.</HelpTooltip>
          </label>
          
          <div class="space-y-3 mb-4">
            <label class="flex items-center space-x-3 cursor-pointer p-3 border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
              <input
                type="radio"
                v-model="lpAllocationMethod"
                value="token-supply"
                class="w-4 h-4 text-orange-600 border-gray-300 focus:ring-orange-500"
              />
              <div>
                <div class="text-sm font-medium text-gray-900 dark:text-white">Based on Token Supply (%)</div>
                <div class="text-xs text-gray-500 dark:text-gray-400">Define percentage of total token supply → Calculate ICP amount needed for liquidity</div>
              </div>
            </label>
            
            <label class="flex items-center space-x-3 cursor-pointer p-3 border border-gray-200 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
              <input
                type="radio"
                v-model="lpAllocationMethod"
                value="raised-funds"
                class="w-4 h-4 text-orange-600 border-gray-300 focus:ring-orange-500"
              />
              <div>
                <div class="text-sm font-medium text-gray-900 dark:text-white">Based on Raised Funds (%)</div>
                <div class="text-xs text-gray-500 dark:text-gray-400">Define percentage of raised funds → Calculate token amount for liquidity</div>
              </div>
            </label>
          </div>

          <!-- Method-specific Configuration -->
          <div v-if="lpAllocationMethod === 'token-supply'" class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Token Supply Percentage*</label>
              <div class="relative">
                <input
                  type="number"
                  v-model.number="lpTokenPercentage"
                  @input="updateLpTokenPercentage"
                  placeholder="30"
                  step="0.1"
                  min="1"
                  max="50"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-orange-500 focus:border-transparent pr-16"
                />
                <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">%</span>
              </div>
              <p class="text-xs text-gray-500 mt-1">{{ formatTokenAmount(calculatedTokenAmount) }} tokens</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Estimated ICP Needed</label>
              <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
                {{ formatAmount(estimatedIcpNeeded) }} ICP
              </div>
              <p class="text-xs text-gray-500 mt-1">Based on current simulation</p>
            </div>
          </div>

          <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Raised Funds Percentage*</label>
              <div class="relative">
                <input
                  type="number"
                  v-model.number="lpRaisedPercentage"
                  @input="updateLpRaisedPercentage"
                  placeholder="60"
                  step="0.1"
                  min="5"
                  max="80"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-orange-500 focus:border-transparent pr-16"
                />
                <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">%</span>
              </div>
              <p class="text-xs text-gray-500 mt-1">{{ formatAmount(calculatedIcpAmount) }} ICP (simulated)</p>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Calculated Token Amount</label>
              <div class="px-3 py-2 bg-gray-100 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
                {{ formatTokenAmount(calculatedTokenFromRaised) }} tokens
              </div>
              <p class="text-xs text-gray-500 mt-1">Based on token price from sale</p>
            </div>
          </div>

          <!-- Status Summary -->
          <div class="p-3 bg-orange-100 dark:bg-orange-900/30 border border-orange-200 dark:border-orange-700 rounded">
            <div class="text-xs text-orange-700 dark:text-orange-300">
              <div v-if="lpAllocationMethod === 'token-supply'">
                🔗 <strong>Token Supply Method:</strong> {{ formatTokenAmount(calculatedTokenAmount) }} tokens ({{ lpTokenPercentage }}%) → Need {{ formatAmount(estimatedIcpNeeded) }} ICP for liquidity
              </div>
              <div v-else>
                💰 <strong>Raised Funds Method:</strong> {{ lpRaisedPercentage }}% of raised funds ({{ formatAmount(calculatedIcpAmount) }} ICP) → Get {{ formatTokenAmount(calculatedTokenFromRaised) }} tokens
              </div>
              <!-- Debug info -->
              <div class="mt-2 pt-2 border-t border-orange-300 text-xs">
                <strong>Debug:</strong> Method={{ lpAllocationMethod }}, TokenPct={{ lpTokenPercentage }}, RaisedPct={{ lpRaisedPercentage }}
              </div>
            </div>
          </div>
        </div>

        <!-- Dynamic Price Info -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Final Token Price
            <HelpTooltip>Token price will be determined dynamically based on actual participation: Total Raised Amount ÷ Sale Token Allocation. This ensures fair price discovery through market participation.</HelpTooltip>
          </label>
          <div class="relative">
            <div class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-blue-50 dark:bg-blue-900 text-blue-800 dark:text-blue-200 font-medium">
              {{ formatNumber(dynamicListingPrice) }} {{ purchaseTokenSymbol }}/{{ saleTokenSymbol }}
            </div>
            <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
          </div>
          <p class="text-xs text-blue-600 dark:text-blue-400 mt-1">Live estimate based on simulation: {{ formatAmount(currentRaisedAmount) }} ÷ {{ formatNumber(saleTokenAllocationNumber) }} tokens</p>
        </div>

        <!-- LP Lock -->
        <div>
          <div class="flex items-center space-x-3 mb-2">
            <input
              :checked="lpLockEnabled"
              type="checkbox"
              :id="lpLockId"
              class="w-4 h-4 text-yellow-600 bg-gray-100 border-gray-300 rounded focus:ring-yellow-500 dark:focus:ring-yellow-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
              @change="lpLockEnabled = $event.target.checked"
            />
            <label :for="lpLockId" class="text-sm font-medium text-gray-700 dark:text-gray-300">
              Enable LP Lock
              <HelpTooltip>Lock LP tokens to prevent immediate withdrawal, increasing investor confidence and price stability.</HelpTooltip>
            </label>
          </div>

          <div v-if="lpLockEnabled" class="pl-7 space-y-4 border-l-2 border-yellow-300">
            <!-- Lock Period -->
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Lock Period</label>
              <div class="relative">
                <input
                  type="number"
                  :value="dexConfig.liquidityLockDays"
                  placeholder="180"
                  step="1"
                  min="0"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
                  @input="updateDexConfig('liquidityLockDays', $event.target.value)"
                />
                <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">days</span>
              </div>
              <p class="text-xs text-gray-500 mt-1">Lock duration, you will receive LP tokens after this period</p>
            </div>
          </div>
        </div>

        <!-- Auto-list on DEX -->
        <div v-if="lpLockEnabled">
          <div class="mt-7">
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Principal ID</label>
              <div class="relative">
                <input
                  type="text"
                  :value="dexConfig.lpTokenRecipient"
                  placeholder="aaaaa-aaa"
                  class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
                  @input="updateDexConfig('lpTokenRecipient', $event.target.value)"
                />
                <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-blue-500 cursor-pointer" @click="copylpTokenRecipient">Me</span>
              </div>
              <p class="text-xs text-gray-500 mt-1">Principal ID to receive LP tokens when unlocked</p>
            </div>
        </div>
      </div>

      <!-- DEX Platform Selection -->
      <div class="space-y-4">
        <div class="flex justify-between items-center mb-3 relative">
          <h4 class="text-md font-semibold text-gray-900 dark:text-white">DEX Platform Selection</h4>
          <div class="relative z-50">
            <Select
              :options="availableDexOptions?.map(dex => ({ label: `${dex.name}`, value: dex.id })) || []"
              placeholder="+ Add DEX Platform"
              v-model="selectedDexToAdd"
              @update:modelValue="addDexPlatform"
              :dropdown-class="'z-[9999] !important'"
              size="sm"
            />
          </div>
        </div>

        <!-- Selected DEX Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div
            v-for="dex in enabledDexs"
            :key="dex.id"
            class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-blue-100 dark:bg-blue-900/10 border-blue-300 dark:border-blue-700"
          >
            <div class="flex items-start justify-between">
              <!-- DEX Info with Logo -->
              <div class="flex items-center space-x-3">
                <div class="w-12 h-12 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-600 flex items-center justify-center p-2">
                  <img :src="dex.logo" class="w-full h-full object-contain" />
                </div>
                <div>
                  <h5 class="text-sm font-medium text-gray-900 dark:text-white">{{ dex.name }}</h5>
                  <p class="text-xs text-gray-500">{{ dex.description }}</p>
                </div>
              </div>

              <!-- Remove Button -->
              <button
                @click="removeDexPlatform(dex.id)"
                type="button"
                class="px-2 py-1 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors"
              >
                Remove
              </button>
            </div>

            <!-- Allocation Percentage -->
            <div class="mt-3 flex items-center space-x-2">
              <label class="text-xs text-gray-500">Liquidity Share:</label>
              <div class="flex items-center space-x-1">
                <input
                  type="number"
                  :value="dex.allocationPercentage"
                  placeholder="50"
                  min="0"
                  max="100"
                  step="0.1"
                  class="w-16 px-2 py-1 text-sm border border-gray-300 dark:border-gray-600 rounded bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  @input="updateDexAllocation(dex.id, parseFloat($event.target.value) || 0)"
                />
                <span class="text-xs text-gray-500">%</span>
              </div>
            </div>

            <!-- DEX-specific Configuration -->
            <div class="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4 pl-4 border-l-2 border-blue-300">
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
                  ${{ formatNumber((dex.calculatedTokenLiquidity * dynamicListingPrice * 2)) }}
                </div>
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
          <div v-for="issue in liquidityValidation.issues" :key="issue" class="p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded text-sm">
            <div class="flex items-center space-x-2">
              <AlertTriangleIcon class="h-4 w-4 text-red-600" />
              <span class="text-red-800 dark:text-red-200">{{ issue }}</span>
            </div>
          </div>

          <!-- Warnings -->
          <div v-for="warning in liquidityValidation.warnings" :key="warning" class="p-2 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm">
            <div class="flex items-center space-x-2">
              <AlertTriangleIcon class="h-4 w-4 text-yellow-600" />
              <span class="text-yellow-800 dark:text-yellow-200">{{ warning }}</span>
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
    </div>

    <!-- Team Allocation - Accordion Style -->
    <div class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
      <button
        @click="toggleRaisedFundsAccordion('team')"
        class="w-full px-4 py-3 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/30 dark:to-emerald-900/30 hover:from-green-100 hover:to-emerald-100 dark:hover:from-green-900/50 dark:hover:to-emerald-900/50 transition-colors text-left"
        type="button"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <span class="font-medium text-green-900 dark:text-green-100">Team</span>
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-600 text-white">
              {{ teamPercentage.toFixed(1) }}% ({{ formatAmount(teamAmount) }} ICP)
            </span>
          </div>
          <ChevronDown
            class="h-4 w-4 text-green-600 dark:text-green-400 transition-transform duration-200"
            :class="{ 'rotate-180': openRaisedFundsAccordions.team }"
          />
        </div>
      </button>
      <div
        v-show="openRaisedFundsAccordions.team"
        class="px-4 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700"
      >
        <!-- Team Percentage Input -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Team Allocation Percentage <HelpTooltip size="sm">Percentage of raised funds allocated to the team for compensation and operations. Consider vesting schedules for team allocations to build trust.</HelpTooltip>
            </label>
            <NumberInput
              v-model="teamPercentage"
              placeholder="0"
              suffix="%"
              :min="0"
              :max="maxTeamPercentage"
              class="w-full"
            />
            <p v-if="maxTeamPercentage < 100" class="text-xs text-amber-600 dark:text-amber-400 mt-1">
              Max available: {{ maxTeamPercentage.toFixed(1) }}% ({{ dexLiquidityPercentage.toFixed(1) }}% for DEX + {{ totalCustomPercentage.toFixed(1) }}% for custom allocations)
            </p>
          </div>
          
          <!-- Team Amount Display (Readonly) -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Team Amount (Calculated)
            </label>
            <div class="px-3 py-2 bg-gray-100 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
              {{ formatAmount(teamAmount) }} ICP
            </div>
          </div>
        </div>

          <!-- Team Vesting Configuration -->
          <div v-if="teamPercentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
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
              v-model="teamVestingSchedule"
              allocation-name="Team Allocation"
            />
          </div>

        <!-- Team Recipients Configuration -->
        <div v-if="teamPercentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <div class="flex justify-between items-center mb-3">
            <div class="flex items-center space-x-2">
              <h4 class="font-medium text-gray-900 dark:text-white required">Team Recipients</h4>
              <span class="text-sm text-gray-500 dark:text-gray-400">({{ teamRecipients.length }} participants)</span>
              <HelpTooltip>Configure principals who will receive team allocation. Each recipient will have the same vesting schedule configured above.</HelpTooltip>
            </div>
            <button 
              @click="addTeamRecipient"
              type="button"
              class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
            >
              Add Recipient
            </button>
          </div>
          
          <div v-if="teamRecipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
            ⚠️ At least one recipient is required for non-zero team allocation
          </div>
          
          <!-- Team Recipients Table -->
          <div v-else class="overflow-x-auto">
            <table class="w-full border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
              <thead class="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Calculated Amount
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Share %
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
                <tr v-for="(recipient, index) in teamRecipients" :key="index" class="hover:bg-gray-50 dark:hover:bg-gray-800">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                      {{ formatAmount(getRecipientAmount(recipient.percentage, teamAmount)) }} ICP
                    </div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <NumberInput
                      v-model="recipient.percentage"
                      placeholder="0"
                      suffix="%"
                      :min="0"
                      :max="100"
                      class="w-20"
                      :class="{ 'border-red-500': teamRecipientsTotalPercentage > 100 }"
                    />
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
                      @click="removeTeamRecipient(index)"
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

          <!-- Team Recipients Validation -->
          <div v-if="teamRecipientsTotalPercentage > 100" class="mt-3 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded text-sm text-red-800 dark:text-red-200">
            ⚠️ Team recipients total exceeds 100% (currently {{ teamRecipientsTotalPercentage.toFixed(1) }}%)
          </div>
          <div v-else-if="teamRecipientsTotalPercentage < 100 && teamRecipients.length > 0" class="mt-3 p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded text-sm text-amber-800 dark:text-amber-200">
            💡 Team recipients total is {{ teamRecipientsTotalPercentage.toFixed(1) }}% ({{ (100 - teamRecipientsTotalPercentage).toFixed(1) }}% unallocated)
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Allocations - Accordion Style -->
    <div 
      v-for="(allocation, index) in customAllocations" 
      :key="allocation.id"
      class="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden"
    >
      <button
        @click="toggleRaisedFundsAccordion(allocation.id)"
        class="w-full px-4 py-3 bg-gradient-to-r from-purple-50 to-indigo-50 dark:from-purple-900/30 dark:to-indigo-900/30 hover:from-purple-100 hover:to-indigo-100 dark:hover:from-purple-900/50 dark:hover:to-indigo-900/50 transition-colors text-left"
        type="button"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-3">
            <input
              v-model="allocation.name"
              type="text"
              placeholder="Allocation name (e.g., Development Fund)"
              class="font-medium bg-transparent border-none outline-none text-purple-900 dark:text-purple-100 placeholder-purple-600 dark:placeholder-purple-400"
              @click.stop
            />
            <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-600 text-white">
              {{ allocation.percentage.toFixed(1) }}% ({{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP)
            </span>
          </div>
          <div class="flex items-center space-x-2">
            <button 
              @click.stop="removeCustomAllocation(index)"
              type="button"
              class="px-2 py-1 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors"
            >
              Remove
            </button>
            <ChevronDown
              class="h-4 w-4 text-purple-600 dark:text-purple-400 transition-transform duration-200"
              :class="{ 'rotate-180': openRaisedFundsAccordions[allocation.id] }"
            />
          </div>
        </div>
      </button>
      <div
        v-show="openRaisedFundsAccordions[allocation.id]"
        class="px-4 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <!-- Allocation Percentage Input -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              {{ allocation.name || 'Custom' }} Allocation Percentage <HelpTooltip>Percentage of raised funds allocated to this category.</HelpTooltip>
            </label>
            <NumberInput
              v-model="allocation.percentage"
              placeholder="0"
              suffix="%"
              :min="0"
              :max="getMaxCustomAllocationPercentage(allocation.id)"
              class="w-full"
            />
            <p v-if="getMaxCustomAllocationPercentage(allocation.id) < 100" class="text-xs text-amber-600 dark:text-amber-400 mt-1">
              Max available: {{ getMaxCustomAllocationPercentage(allocation.id).toFixed(1) }}%
            </p>
          </div>
          
          <!-- Allocation Amount Display (Readonly) -->
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              {{ allocation.name || 'Custom' }} Amount (Calculated)
            </label>
            <div class="px-3 py-2 bg-gray-100 dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
              {{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP
            </div>
          </div>
        </div>

        <!-- Custom Allocation Vesting Configuration -->
        <div v-if="allocation.percentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <div class="flex items-center mb-3">
            <label class="relative inline-flex items-center cursor-pointer mr-3">
              <input 
                v-model="allocation.vestingEnabled" 
                type="checkbox" 
                class="sr-only peer"
              >
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-purple-300 dark:peer-focus:ring-purple-800 rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all dark:border-gray-600 peer-checked:bg-purple-600"></div>
            </label>
            <label 
              @click="allocation.vestingEnabled = !allocation.vestingEnabled"
              class="text-sm font-medium text-gray-700 dark:text-gray-300 cursor-pointer select-none"
            >
              Enable Vesting Schedule
            </label>
          </div>
          <VestingScheduleConfig
            v-if="allocation.vestingEnabled"
            v-model="allocation.vestingSchedule"
            :allocation-name="allocation.name || 'Custom Allocation'"
          />
        </div>

        <!-- Custom Allocation Recipients Configuration -->
        <div v-if="allocation.percentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
          <div class="flex justify-between items-center mb-3">
            <div class="flex items-center space-x-2">
              <h4 class="font-medium text-gray-900 dark:text-white">{{ allocation.name || 'Custom' }} Recipients</h4>
              <span class="text-sm text-gray-500 dark:text-gray-400">({{ allocation.recipients.length }} participants)</span>
              <HelpTooltip>Configure principals who will receive this allocation. Each recipient will have the same vesting schedule configured above.</HelpTooltip>
            </div>
            <button 
              @click="addCustomAllocationRecipient(allocation.id)"
              type="button"
              class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
            >
              Add Recipient
            </button>
          </div>
          
          <div v-if="allocation.recipients.length === 0" class="p-3 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded text-sm text-yellow-800 dark:text-yellow-200">
            ⚠️ At least one recipient is required for non-zero {{ allocation.name || 'custom' }} allocation
          </div>
          
          <!-- Custom Allocation Recipients Table -->
          <div v-else class="overflow-x-auto">
            <table class="w-full border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
              <thead class="bg-gray-50 dark:bg-gray-800">
                <tr>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Calculated Amount
                  </th>
                  <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                    Share %
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
                <tr v-for="(recipient, recipientIndex) in allocation.recipients" :key="recipientIndex" class="hover:bg-gray-50 dark:hover:bg-gray-800">
                  <td class="px-4 py-3 whitespace-nowrap">
                    <div class="text-sm font-medium text-gray-900 dark:text-gray-100">
                      {{ formatAmount(getRecipientAmount(recipient.percentage, calculateAllocationAmount(allocation.percentage))) }} ICP
                    </div>
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap">
                    <NumberInput
                      v-model="recipient.percentage"
                      placeholder="0"
                      suffix="%"
                      :min="0"
                      :max="100"
                      class="w-20"
                      :class="{ 'border-red-500': getCustomAllocationRecipientsTotalPercentage(allocation.id) > 100 }"
                    />
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
                      @click="removeCustomAllocationRecipient(allocation.id, recipientIndex)"
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

          <!-- Custom Allocation Recipients Validation -->
          <div v-if="getCustomAllocationRecipientsTotalPercentage(allocation.id) > 100" class="mt-3 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded text-sm text-red-800 dark:text-red-200">
            ⚠️ {{ allocation.name || 'Custom' }} recipients total exceeds 100% (currently {{ getCustomAllocationRecipientsTotalPercentage(allocation.id).toFixed(1) }}%)
          </div>
          <div v-else-if="getCustomAllocationRecipientsTotalPercentage(allocation.id) < 100 && allocation.recipients.length > 0" class="mt-3 p-3 bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded text-sm text-amber-800 dark:text-amber-200">
            💡 {{ allocation.name || 'Custom' }} recipients total is {{ getCustomAllocationRecipientsTotalPercentage(allocation.id).toFixed(1) }}% ({{ (100 - getCustomAllocationRecipientsTotalPercentage(allocation.id)).toFixed(1) }}% unallocated)
          </div>
        </div>
      </div>
    </div>


    <!-- Add Custom Allocation -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4 mb-6">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Additional Allocations <HelpTooltip>Add custom allocation categories beyond team allocation as needed for your project.</HelpTooltip></h3>
        <div class="flex space-x-2">
          <button 
            @click="addQuickAllocation('Development Fund', 15)"
            type="button"
            class="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white text-sm rounded-md transition-colors"
          >
            + Development Fund
          </button>
          <button 
            @click="addQuickAllocation('Marketing Fund', 10)"
            type="button"
            class="px-3 py-1 bg-green-600 hover:bg-green-700 text-white text-sm rounded-md transition-colors"
          >
            + Marketing Fund
          </button>
          <button 
            @click="addCustomAllocation()"
            type="button"
            class="px-3 py-1 bg-purple-600 hover:bg-purple-700 text-white text-sm rounded-md transition-colors"
          >
            + Custom Allocation
          </button>
        </div>
      </div>
      
      <div v-if="customAllocations.length === 0" class="p-3 bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded text-sm text-gray-600 dark:text-gray-400">
        💡 Click the buttons above to add custom allocations as needed for your project
      </div>
    </div>


  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { AlertTriangleIcon, ChevronDown } from 'lucide-vue-next'
import NumberInput from '@/components/common/NumberInput.vue'
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import VestingScheduleConfig from './VestingScheduleConfig.vue'
import Select from '@/components/common/Select.vue'
import { InputMask } from '@/utils/inputMask'
import { useUniqueId } from '@/composables/useUniqueId'
import { useAuthStore } from '@/stores/auth'

const props = defineProps({
  softCap: {
    type: String,
    required: true
  },
  hardCap: {
    type: String,
    required: true
  },
  platformFeeRate: {
    type: Number,
    default: 2.5
  },
  dexLiquidityRequired: {
    type: Number,
    default: 0
  },
  saleTokenAllocation: {
    type: [String, Number],
    default: 0
  },
  tokenSymbol: {
    type: String,
    default: 'TOK'
  },
  purchaseSymbol: {
    type: String,
    default: 'ICP'
  },
  modelValue: {
    type: Object,
    required: true
  },
  totalSupply: {
    type: String,
    required: true
  },
  totalSaleAmount: {
    type: String,
    required: true
  },
  simulatedRaisedAmount: {
    type: String,
    default: '0'
  }
})

const emit = defineEmits(['update:modelValue', 'update:dexConfig'])

// Auth store for principal access
const authStore = useAuthStore()

// Unique ID for form elements
const autoListMainId = useUniqueId('auto-list-main')
const lpLockId = useUniqueId('lp-lock')

// LP Lock state
const lpLockEnabled = ref(true)

// DEX selection state
const selectedDexToAdd = ref('')

// Accordion state for raised funds allocation sections
const openRaisedFundsAccordions = ref({
  team: true  // Team section open by default
})

// All available DEX platforms (including disabled ones)
const allDexPlatforms = [
  { id: 'icpswap', name: 'ICPSwap', description: 'Leading DEX on Internet Computer', logo: 'https://app.icpswap.com/static/media/logo-dark.7b8c12091e650c40c5e9f561c57473ba.svg' },
  { id: 'sonic', name: 'Sonic DEX', description: 'High-speed AMM on Internet Computer', logo: 'SonicLogo' },
  { id: 'kongswap', name: 'Kong Swap', description: 'Community-driven DEX', logo: '🦍' },
  { id: 'icdex', name: 'ICDex', description: 'Order book DEX', logo: '📊' }
]

// Available DEXs array (originally from props in MultiDEXConfiguration)
const availableDexs = ref([])


// LP Allocation Method State
const lpAllocationMethod = ref('token-supply')
const lpTokenPercentage = ref(30)
const lpRaisedPercentage = ref(60)

// Token symbols from props
const saleTokenSymbol = computed(() => props.tokenSymbol)
const purchaseTokenSymbol = computed(() => props.purchaseSymbol)

// Sale token allocation as number
const saleTokenAllocationNumber = computed(() => {
  const value = parseFloat(props.saleTokenAllocation)
  return isNaN(value) || value <= 0 ? 1000000 : value
})

// Dynamic listing price calculation: Raised Amount ÷ Sale Token Allocation
const dynamicListingPrice = computed(() => {
  if (saleTokenAllocationNumber.value <= 0) return 0
  return currentRaisedAmount.value / saleTokenAllocationNumber.value
})


// Convert caps to numbers for calculations
const softCapNumber = computed(() => {
  const value = parseFloat(props.softCap)
  return isNaN(value) || value <= 0 ? 1000 : value
})

const hardCapNumber = computed(() => {
  const value = parseFloat(props.hardCap)
  return isNaN(value) || value <= 0 ? 100000 : value
})

const stepSize = computed(() => {
  const diff = hardCapNumber.value - softCapNumber.value
  return diff > 0 ? diff / 100 : 1000
})

// Raised funds simulation - initialize with a default value first
const currentRaisedAmount = ref(1000)

// LP Allocation Calculated Values
const calculatedTokenAmount = computed(() => {
  const totalSupplyValue = parseFloat(props.totalSupply) || 0
  const result = (totalSupplyValue * lpTokenPercentage.value) / 100
  console.log('calculatedTokenAmount:', {
    totalSupply: props.totalSupply,
    totalSupplyValue,
    lpTokenPercentage: lpTokenPercentage.value,
    result
  })
  return result
})

const calculatedIcpAmount = computed(() => {
  const simulatedValue = parseFloat(props.simulatedRaisedAmount) || 0
  const result = (simulatedValue * lpRaisedPercentage.value) / 100
  console.log('calculatedIcpAmount:', {
    simulatedRaisedAmount: props.simulatedRaisedAmount,
    simulatedValue,
    lpRaisedPercentage: lpRaisedPercentage.value,
    result
  })
  return result
})

const calculatedTokenFromRaised = computed(() => {
  const icpAmount = calculatedIcpAmount.value
  const tokenPrice = dynamicListingPrice.value
  return tokenPrice > 0 ? icpAmount / tokenPrice : 0
})

const estimatedIcpNeeded = computed(() => {
  const tokenAmount = calculatedTokenAmount.value
  const tokenPrice = dynamicListingPrice.value
  return tokenAmount * tokenPrice
})

// Percentage inputs
const teamPercentage = ref(30)

// Recipients arrays
const teamRecipients = ref([])

// Team vesting schedule (category level)
const teamVestingSchedule = ref(null)
const teamVestingEnabled = ref(true) // Team should have vesting by default

// Custom allocations system
const customAllocations = ref([])
let allocationIdCounter = 0

// Flag to prevent recursive updates
let isUpdatingFromProps = false
let updateTimeout = null

// DEX Configuration
const dexConfig = ref({
  autoList: false,
  platform: '',
  liquidityPercentage: 20,
  liquidityLockDays: 180,
  lpTokenRecipient: ''
})

// Helper to generate unique allocation IDs
const generateAllocationId = () => {
  return `allocation_${++allocationIdCounter}_${Date.now()}`
}

// Calculations
const platformFee = computed(() => currentRaisedAmount.value * (props.platformFeeRate / 100))

// DEX Liquidity calculation based on percentage and auto listing setting
const calculatedDexLiquidity = computed(() => {
  if (!dexConfig.value.autoList) return 0
  const percentage = Number(dexConfig.value.liquidityPercentage) || 0
  return currentRaisedAmount.value * (percentage / 100)
})

const dexLiquidityFee = computed(() => calculatedDexLiquidity.value)
const availableForAllocation = computed(() => currentRaisedAmount.value - platformFee.value)

const teamAmount = computed(() => currentRaisedAmount.value * (teamPercentage.value / 100))

// Calculate allocation amount for any percentage
const calculateAllocationAmount = (percentage) => {
  return currentRaisedAmount.value * (percentage / 100)
}

// Valid custom allocations (filter out null/undefined and zero percentages)
const validCustomAllocations = computed(() => {
  return customAllocations.value.filter(allocation =>
    allocation &&
    allocation.id &&
    allocation.percentage > 0
  )
})

// Total custom allocations
const totalCustomPercentage = computed(() => {
  return customAllocations.value.reduce((sum, allocation) => sum + (allocation?.percentage || 0), 0)
})

const totalCustomAmount = computed(() => {
  return customAllocations.value.reduce((sum, allocation) => sum + calculateAllocationAmount(allocation?.percentage || 0), 0)
})

// DEX liquidity percentage calculation
const dexLiquidityPercentage = computed(() => {
  if (!dexConfig.value.autoList) return 0
  return Number(dexConfig.value.liquidityPercentage) || 0
})

// Calculate maximum available percentage for DEX liquidity allocation
const maxDexLiquidityPercentage = computed(() => {
  const usedByTeam = teamPercentage.value
  const usedByCustom = totalCustomPercentage.value
  const platformFeePercentage = props.platformFeeRate || 0
  return Math.max(0, 100 - platformFeePercentage - usedByTeam - usedByCustom)
})

// Calculate maximum available percentage for team allocation
const maxTeamPercentage = computed(() => {
  const usedByDex = dexLiquidityPercentage.value
  const usedByCustom = totalCustomPercentage.value
  const platformFeePercentage = props.platformFeeRate || 0
  return Math.max(0, 100 - platformFeePercentage - usedByDex - usedByCustom)
})


// Calculate max percentage for individual custom allocation
const getMaxCustomAllocationPercentage = (currentAllocationId) => {
  const usedByDex = dexLiquidityPercentage.value
  const usedByTeam = teamPercentage.value
  const platformFeePercentage = props.platformFeeRate || 0
  // Exclude current allocation from total to allow editing
  const usedByOtherCustom = customAllocations.value
    .filter(a => a.id !== currentAllocationId)
    .reduce((sum, a) => sum + (a.percentage || 0), 0)
  return Math.max(0, 100 - platformFeePercentage - usedByDex - usedByTeam - usedByOtherCustom)
}

// Overall totals (excluding DEX for internal allocation calculations)
const totalAllocationPercentage = computed(() => teamPercentage.value + totalCustomPercentage.value)
const totalAllocationAmount = computed(() => teamAmount.value + totalCustomAmount.value)
const remainingPercentage = computed(() => {
  const platformFeePercentage = props.platformFeeRate || 0
  const usedByDex = dexLiquidityPercentage.value
  return Math.max(0, 100 - platformFeePercentage - usedByDex - totalAllocationPercentage.value)
})
const remainingAmount = computed(() => availableForAllocation.value - calculatedDexLiquidity.value - totalAllocationAmount.value)

// Overall totals INCLUDING DEX for display purposes
const totalAllocationPercentageWithDex = computed(() => {
  return dexLiquidityPercentage.value + totalAllocationPercentage.value
})
const totalAllocationAmountWithDex = computed(() => {
  return calculatedDexLiquidity.value + totalAllocationAmount.value
})
const remainingPercentageWithDex = computed(() => {
  const platformFeePercentage = props.platformFeeRate || 0
  return Math.max(0, 100 - platformFeePercentage - totalAllocationPercentageWithDex.value)
})
const remainingAmountWithDex = computed(() => {
  return (currentRaisedAmount.value - platformFee.value) - totalAllocationAmountWithDex.value
})

// Format amount for display
const formatAmount = (amount) => {
  const numAmount = Number(amount)
  if (isNaN(numAmount)) return '0.00'
  return numAmount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  })
}

// Format token amount for display
const formatTokenAmount = (amount) => {
  const numAmount = Number(amount)
  if (isNaN(numAmount)) return '0'
  if (numAmount >= 1000000) {
    return (numAmount / 1000000).toFixed(2) + 'M'
  } else if (numAmount >= 1000) {
    return (numAmount / 1000).toFixed(2) + 'K'
  }
  return numAmount.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0
  })
}

// DEX Configuration Functions

const updateLpTokenPercentage = () => {
  console.log('Token percentage updated to:', lpTokenPercentage.value)
  nextTick(() => {
    emitDexConfig()
  })
}

const updateLpRaisedPercentage = () => {
  console.log('Raised percentage updated to:', lpRaisedPercentage.value)
  nextTick(() => {
    emitDexConfig()
  })
}

const emitDexConfig = () => {
  // Skip if we're updating from props to prevent recursive loop
  if (isUpdatingFromProps) return
  
  console.log('Emitting DEX config:', {
    lpAllocationMethod: lpAllocationMethod.value,
    lpTokenPercentage: lpTokenPercentage.value,
    lpRaisedPercentage: lpRaisedPercentage.value
  })
  
  emit('update:dexConfig', {
    lpAllocationMethod: lpAllocationMethod.value,
    lpTokenPercentage: lpTokenPercentage.value,
    lpRaisedPercentage: lpRaisedPercentage.value
  })
}

// Recipient management functions
const createDefaultRecipient = () => ({
  principal: '',
  percentage: 0,
  name: ''
})

// Custom allocation management  
const createCustomAllocation = (name = '', percentage = 0) => ({
  id: generateAllocationId(),
  name,
  percentage,
  recipients: [],
  vestingSchedule: null, // Category-level vesting
  vestingEnabled: false // Default to disabled
})

const addTeamRecipient = () => {
  teamRecipients.value.push(createDefaultRecipient())
}

const removeTeamRecipient = (index) => {
  teamRecipients.value.splice(index, 1)
}

// Custom allocation management
const addCustomAllocation = () => {
  const newAllocation = createCustomAllocation()
  customAllocations.value.push(newAllocation)
  // Auto-expand new allocation accordion
  openRaisedFundsAccordions.value[newAllocation.id] = true
}

const addQuickAllocation = (name, percentage) => {
  const newAllocation = createCustomAllocation(name, percentage)
  customAllocations.value.push(newAllocation)
  // Auto-expand new allocation accordion
  openRaisedFundsAccordions.value[newAllocation.id] = true
}

const removeCustomAllocation = (index) => {
  customAllocations.value.splice(index, 1)
}

const addCustomAllocationRecipient = (allocationId) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.push(createDefaultRecipient())
  }
}

const removeCustomAllocationRecipient = (allocationId, recipientIndex) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (allocation) {
    allocation.recipients.splice(recipientIndex, 1)
  }
}



// Pie Chart Data

// Watch for DEX liquidity changes to recalculate individual DEX allocations
watch([calculatedDexLiquidity, () => dexConfig.value.liquidityPercentage], () => {
  if (dexConfig.value.autoList && enabledDexs.value.length > 0) {
    recalculateDexLiquidity()
  }
}, { immediate: false })

// Enforce max limits for DEX liquidity percentage
watch(() => dexConfig.value.liquidityPercentage, (newValue) => {
  if (!dexConfig.value.autoList) return
  const max = maxDexLiquidityPercentage.value
  const numValue = Number(newValue) || 0
  if (numValue > max) {
    updateDexConfig('liquidityPercentage', max.toString())
  }
})

// Enforce max limits for team percentage
watch(teamPercentage, (newValue) => {
  const max = maxTeamPercentage.value
  if (newValue > max) {
    teamPercentage.value = max
  }
}, { immediate: false })

// Enforce max limits for custom allocations
watch(customAllocations, (newAllocations) => {
  newAllocations.forEach(allocation => {
    // Skip if allocation is null/undefined
    if (!allocation || !allocation.id) return

    const max = getMaxCustomAllocationPercentage(allocation.id)
    if (allocation.percentage > max) {
      allocation.percentage = max
    }
  })
}, { deep: true, immediate: false })

// Watch for changes and emit to parent (with debouncing)
watch([teamPercentage, currentRaisedAmount, teamRecipients, teamVestingSchedule, customAllocations, dexConfig, availableDexs], () => {
  // Skip if we're updating from props to prevent recursive loop
  if (isUpdatingFromProps) return
  
  // Clear previous timeout
  if (updateTimeout) {
    clearTimeout(updateTimeout)
  }
  
  // Debounce updates to prevent excessive emissions
  updateTimeout = setTimeout(() => {
    const allocationData = {
      teamAllocation: teamAmount.value.toString(),
      teamAllocationPercentage: teamPercentage.value,
      simulatedRaisedAmount: currentRaisedAmount.value,
      teamRecipients: teamRecipients.value,
      teamVestingSchedule: teamVestingSchedule.value,
      customAllocations: customAllocations.value.map(allocation => ({
        id: allocation.id,
        name: allocation.name,
        percentage: allocation.percentage,
        amount: calculateAllocationAmount(allocation.percentage).toString(),
        recipients: allocation.recipients,
        vestingSchedule: allocation.vestingSchedule
      })),
      totalAllocationPercentage: totalAllocationPercentage.value,
      totalAllocationAmount: totalAllocationAmount.value.toString(),
      remainingPercentage: remainingPercentage.value,
      remainingAmount: remainingAmount.value.toString(),
      // DEX Configuration
      dexConfig: {
        autoList: dexConfig.value.autoList,
        platform: dexConfig.value.platform,
        liquidityPercentage: dexConfig.value.liquidityPercentage,
        liquidityLockDays: dexConfig.value.liquidityLockDays,
        lpTokenRecipient: dexConfig.value.lpTokenRecipient,
        totalLiquidityToken: '', // Will be calculated in parent
        calculatedLiquidityAmount: calculatedDexLiquidity.value.toString()
      },
      // Available DEX platforms with calculations
      availableDexs: availableDexs.value
    }

    emit('update:modelValue', allocationData)
  }, 100) // 100ms debounce
}, { deep: true })

// Watch modelValue to restore state when component remounts
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue && typeof newValue === 'object') {
      // Set flag to prevent recursive updates
      isUpdatingFromProps = true
      
      // Restore DEX config
      if (newValue.dexConfig) {
        dexConfig.value = {
          autoList: newValue.dexConfig.autoList || false,
          platform: newValue.dexConfig.platform || '',
          liquidityPercentage: newValue.dexConfig.liquidityPercentage || 20,
          liquidityLockDays: newValue.dexConfig.liquidityLockDays || 180,
          lpTokenRecipient: newValue.dexConfig.lpTokenRecipient || ''
        }
      }

      // Restore team allocation
      if (newValue.teamAllocationPercentage !== undefined) {
        teamPercentage.value = newValue.teamAllocationPercentage
      }

      // Restore team recipients
      if (newValue.teamRecipients && Array.isArray(newValue.teamRecipients)) {
        teamRecipients.value = [...newValue.teamRecipients]
      }

      // Restore team vesting schedule
      if (newValue.teamVestingSchedule !== undefined) {
        teamVestingSchedule.value = newValue.teamVestingSchedule
      }

      // Restore custom allocations
      if (newValue.customAllocations && Array.isArray(newValue.customAllocations)) {
        customAllocations.value = newValue.customAllocations.map(alloc => ({
          id: alloc.id,
          name: alloc.name,
          percentage: alloc.percentage,
          recipients: [...(alloc.recipients || [])],
          vestingSchedule: alloc.vestingSchedule || null
        }))
      }

      // Restore available DEXs
      if (newValue.availableDexs && Array.isArray(newValue.availableDexs)) {
        availableDexs.value = [...newValue.availableDexs]
      }

      // Restore raised amount simulation
      if (newValue.simulatedRaisedAmount) {
        currentRaisedAmount.value = newValue.simulatedRaisedAmount
      }
      
      // Reset flag after all updates complete
      nextTick(() => {
        isUpdatingFromProps = false
      })
    }
  },
  { immediate: true, deep: true }
)

// Initialize currentRaisedAmount when softCap changes
watch([softCapNumber, hardCapNumber], ([newSoftCap, newHardCap]) => {
  console.log('Caps changed:', { newSoftCap, newHardCap, current: currentRaisedAmount.value })
  // Ensure currentRaisedAmount is within valid range
  if (currentRaisedAmount.value < newSoftCap || currentRaisedAmount.value > newHardCap) {
    currentRaisedAmount.value = newSoftCap
    console.log('Updated currentRaisedAmount to:', newSoftCap)
  }
}, { immediate: true })

// Debug prop values
watch(() => [props.softCap, props.hardCap], ([softCap, hardCap]) => {
  console.log('Props changed:', { softCap, hardCap, softCapNumber: softCapNumber.value, hardCapNumber: hardCapNumber.value })
}, { immediate: true })

// DEX Configuration Watchers
watch(lpAllocationMethod, (newMethod) => {
  console.log('LP Allocation Method changed to:', newMethod)
  nextTick(() => {
    emitDexConfig()
  })
})

watch([lpTokenPercentage, lpRaisedPercentage], ([newTokenPercentage, newRaisedPercentage]) => {
  console.log('LP percentages changed:', { token: newTokenPercentage, raised: newRaisedPercentage })
  nextTick(() => {
    emitDexConfig()
  })
})

// Debug watcher để kiểm tra calculated values
watch([lpAllocationMethod, lpTokenPercentage, lpRaisedPercentage, calculatedTokenAmount, calculatedIcpAmount, calculatedTokenFromRaised, estimatedIcpNeeded], 
  ([method, tokenPct, raisedPct, tokenAmt, icpAmt, tokenFromRaised, icpNeeded]) => {
  console.log('LP calculations updated:', {
    method,
    tokenPct,
    raisedPct,
    tokenAmt,
    icpAmt,
    tokenFromRaised,
    icpNeeded
  })
}, { immediate: true })

// ===== DEX CONFIGURATION FUNCTIONS FROM MULTIDEXCONFIGURATION =====

// Update dex config
const updateDexConfig = (key, value) => {
  dexConfig.value[key] = value
}

// Update DEX allocation percentage
const updateDexAllocation = (dexId, percentage) => {
  const updatedDexs = availableDexs.value.map(dex =>
    dex.id === dexId ? { ...dex, allocationPercentage: percentage } : dex
  )
  availableDexs.value = updatedDexs
  // Recalculate liquidity for all DEXs
  recalculateDexLiquidity()
}

// Recalculate DEX liquidity based on current raised amount and allocation percentages
const recalculateDexLiquidity = () => {
  const totalDexLiquidity = calculatedDexLiquidity.value

  availableDexs.value = availableDexs.value.map(dex => {
    if (!dex.enabled) return dex

    // Calculate this DEX's share of total liquidity based on its allocation percentage
    const dexLiquidityShare = totalDexLiquidity * (dex.allocationPercentage / 100)

    // Calculate token liquidity using dynamic listing price
    const tokenLiquidity = dynamicListingPrice.value > 0 ? dexLiquidityShare / dynamicListingPrice.value : 0

    return {
      ...dex,
      calculatedPurchaseLiquidity: dexLiquidityShare,
      calculatedTokenLiquidity: tokenLiquidity
    }
  })
}

// Computed properties for new card-based system
const enabledDexs = computed(() =>
  availableDexs.value.filter(dex => dex.enabled)
)

const availableDexOptions = computed(() => {
  const enabledIds = enabledDexs.value.map(dex => dex.id)
  return allDexPlatforms.filter(platform => !enabledIds.includes(platform.id))
})

const enabledDEXCount = computed(() => enabledDexs.value.length)

const totalPurchaseLiquidityRequired = computed(() => {
  return availableDexs.value
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + dex.calculatedPurchaseLiquidity, 0)
})

const estimatedTotalTVL = computed(() => {
  if (dynamicListingPrice.value <= 0) return 0
  return availableDexs.value
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + (dex.calculatedTokenLiquidity * dynamicListingPrice.value * 2), 0)
})

const allocationPercentageTotal = computed(() => {
  return availableDexs.value
    .filter(dex => dex.enabled)
    .reduce((sum, dex) => sum + dex.allocationPercentage, 0)
})

const dexFeesTotal = computed(() => {
  return availableDexs.value
    .filter(dex => dex.enabled && dex.fees)
    .reduce((sum, dex) => sum + (dex.calculatedPurchaseLiquidity * (dex.fees?.listing || 0) / 100), 0)
})

const totalFeesEstimate = computed(() => {
  return (hardCapNumber.value * (props.platformFeeRate / 100)) + dexFeesTotal.value
})

// Validation objects
const liquidityValidation = computed(() => {
  const issues = []
  const warnings = []

  // LP Receiver Principal ID validation when LP Lock is enabled
  if (lpLockEnabled.value && !dexConfig.value.lpTokenRecipient?.trim()) {
    warnings.push('LP Receiver Principal ID required when LP Lock is enabled. If not provided, LP tokens will be sent to DAO.')
  }

  return { issues, warnings }
})

const liquidityWarnings = computed(() => {
  const warnings = []

  // LP Receiver Principal ID format validation
  if (lpLockEnabled.value && dexConfig.value.lpTokenRecipient?.trim()) {
    const principalId = dexConfig.value.lpTokenRecipient.trim()
    // Basic Principal ID format check (should contain dashes and be reasonable length)
    if (principalId.length < 10 || !principalId.includes('-')) {
      warnings.push('LP Receiver Principal ID format appears invalid. Please verify the format.')
    }
  }

  return warnings
})

const raisedFundsAfterFees = computed(() => ({
  availableForLiquidity: currentRaisedAmount.value - platformFee.value - calculatedDexLiquidity.value
}))

// DEX management functions
const addDexPlatform = (value) => {
  if (!value) return

  const platformInfo = allDexPlatforms.find(p => p.id === value)
  if (!platformInfo) return

  const newDex = {
    id: platformInfo.id,
    logo: platformInfo.logo,
    name: platformInfo.name,
    description: platformInfo.description,
    enabled: true,
    allocationPercentage: enabledDexs.value.length === 0 ? 100 : 50, // Default allocation
    calculatedTokenLiquidity: 0,
    calculatedPurchaseLiquidity: 0,
    fees: {
      listing: 0.5,
      transaction: 0.3
    }
  }

  availableDexs.value.push(newDex)

  // Auto-redistribute allocations equally among enabled DEXs
  redistributeDexAllocations()

  // Reset selection
  selectedDexToAdd.value = ''
}

// Redistribute DEX allocations equally
const redistributeDexAllocations = () => {
  const enabledDexCount = enabledDexs.value.length
  if (enabledDexCount === 0) return

  const equalAllocation = 100 / enabledDexCount

  availableDexs.value = availableDexs.value.map(dex => {
    if (dex.enabled) {
      return { ...dex, allocationPercentage: equalAllocation }
    }
    return dex
  })

  // Recalculate liquidity after redistribution
  recalculateDexLiquidity()
}

const removeDexPlatform = (dexId) => {
  availableDexs.value = availableDexs.value.filter(dex => dex.id !== dexId)
  // Redistribute allocations after removal
  redistributeDexAllocations()
}

// Auto Listing Toggle Methods
const toggleAutoListing = () => {
  const newValue = !dexConfig.value.autoList
  updateDexConfig('autoList', newValue)

  if (newValue) {
    // If enabling, auto-select ICPSwap
    addDexPlatform('icpswap')
  } else {
    // If disabling, clear any selected DEXs to reset state
    const clearedDexs = availableDexs.value.map(dex => ({
      ...dex,
      enabled: false,
      allocationPercentage: 0
    }))
    availableDexs.value = clearedDexs
  }
}

const handleAutoListToggle = (event) => {
  const target = event.target
  updateDexConfig('autoList', target.checked)

  // If disabling, clear DEX selections
  if (!target.checked) {
    const clearedDexs = availableDexs.value.map(dex => ({
      ...dex,
      enabled: false,
      allocationPercentage: 0
    }))
    availableDexs.value = clearedDexs
  }
}

// Principal ID helper
const copylpTokenRecipient = () => {
  if (authStore.principal) {
    updateDexConfig('lpTokenRecipient', authStore.principal)
  }
}

// Format number helper
const formatNumber = (value) => {
  return InputMask.formatTokenAmount(value, 2)
}

// Accordion toggle function for raised funds sections
const toggleRaisedFundsAccordion = (section) => {
  openRaisedFundsAccordions.value[section] = !openRaisedFundsAccordions.value[section]
}

// Validation functions
const isValidPrincipal = (principal) => {
  if (!principal || typeof principal !== 'string') return false
  // Basic principal validation: should have dashes and reasonable length
  return principal.length >= 10 && principal.includes('-') && /^[a-z0-9-]+$/.test(principal)
}

// Calculate team recipients total percentage
const teamRecipientsTotalPercentage = computed(() => {
  return teamRecipients.value.reduce((sum, recipient) => sum + (recipient.percentage || 0), 0)
})

// Calculate custom allocation recipients total percentage
const getCustomAllocationRecipientsTotalPercentage = (allocationId) => {
  const allocation = customAllocations.value.find(a => a.id === allocationId)
  if (!allocation) return 0
  return allocation.recipients.reduce((sum, recipient) => sum + (recipient.percentage || 0), 0)
}

// Calculate recipient amount based on percentage of category total
const getRecipientAmount = (percentage, categoryTotal) => {
  return (categoryTotal * (percentage || 0)) / 100
}
</script>

<style scoped>
.slider::-webkit-slider-thumb {
  appearance: none;
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: #3b82f6;
  cursor: pointer;
}

.slider::-moz-range-thumb {
  height: 20px;
  width: 20px;
  border-radius: 50%;
  background: #3b82f6;
  cursor: pointer;
  border: none;
}
</style>