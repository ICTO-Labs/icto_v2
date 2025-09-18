<template>
  <div class="space-y-6">
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
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Liquidity Allocation*
            <HelpTooltip>Percentage of raised funds (after platform fees) that will be used for DEX liquidity. This creates a transparent commitment to liquidity provision regardless of final raise amount.</HelpTooltip>
          </label>
          <div class="relative">
            <input
              type="number"
              :value="dexConfig.liquidityPercentage || 20"
              placeholder="20"
              step="1"
              min="5"
              :max="maxDexLiquidityPercentage"
              class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent pr-16"
              @input="updateDexConfig('liquidityPercentage', $event.target.value)"
            />
            <span class="absolute inset-y-0 right-0 flex items-center pr-3 text-sm text-gray-500">%</span>
          </div>
          <p class="text-xs text-gray-500 mt-1">Percentage of raised funds allocated for liquidity</p>
          <p v-if="maxDexLiquidityPercentage < 100" class="text-xs text-amber-600 dark:text-amber-400 mt-1">
            Max available: {{ maxDexLiquidityPercentage.toFixed(1) }}% ({{ props.platformFeeRate }}% platform fee + {{ teamPercentage }}% team + {{ totalCustomPercentage.toFixed(1) }}% custom allocations)
          </p>
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

    <!-- Team Allocation -->
    <div class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Team Allocation</h3>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
        <!-- Team Percentage Input -->
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
          <div class="px-3 py-2 bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
            {{ formatAmount(teamAmount) }} ICP
          </div>
        </div>
      </div>

      <!-- Team Recipients Configuration -->
      <div v-if="teamPercentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-3">
          <h4 class="font-medium text-gray-900 dark:text-white required">Team Recipients <HelpTooltip>Configure principals who will receive team allocation and their distribution terms.</HelpTooltip></h4>
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
        
        <div v-for="(recipient, index) in teamRecipients" :key="index" class="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Name (Optional)</label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="Team member name"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Principal * </label>
              <input
                v-model="recipient.principal"
                type="text"
                placeholder="Principal ID"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Percentage</label>
              <div class="flex items-center space-x-2">
                <div class="flex-1">
                  <NumberInput
                    v-model="recipient.percentage"
                    placeholder="0"
                    suffix="%"
                    :min="0"
                    :max="100"
                    class="w-full h-10"
                  />
                </div>
                <button 
                  @click="removeTeamRecipient(index)"
                  type="button"
                  class="px-3 py-2 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors h-10 flex-shrink-0"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
          
          <!-- Vesting Configuration -->
          <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
            <VestingScheduleConfig
              v-model="recipient.vestingSchedule"
              :allocation-name="`Team Member ${index + 1}`"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Allocations -->
    <div 
      v-for="(allocation, index) in customAllocations" 
      :key="allocation.id"
      class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4"
    >
      <div class="flex justify-between items-center mb-4">
        <div class="flex items-center space-x-2">
          <input
            v-model="allocation.name"
            type="text"
            placeholder="Allocation name (e.g., Development Fund)"
            class="text-lg font-semibold bg-transparent border-none outline-none text-gray-900 dark:text-white placeholder-gray-400"
          />
        </div>
        <button 
          @click="removeCustomAllocation(index)"
          type="button"
          class="px-2 py-1 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors"
        >
          Remove
        </button>
      </div>
      
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
          <div class="px-3 py-2 bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-600 rounded-md text-gray-900 dark:text-gray-100">
            {{ formatAmount(calculateAllocationAmount(allocation.percentage)) }} ICP
          </div>
        </div>
      </div>

      <!-- Custom Allocation Recipients Configuration -->
      <div v-if="allocation.percentage > 0" class="border-t border-gray-200 dark:border-gray-700 pt-4">
        <div class="flex justify-between items-center mb-3">
          <h4 class="font-medium text-gray-900 dark:text-white">{{ allocation.name || 'Custom' }} Recipients <HelpTooltip>Configure principals who will receive this allocation.</HelpTooltip></h4>
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
        
        <div v-for="(recipient, recipientIndex) in allocation.recipients" :key="recipientIndex" class="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-3">
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Name (Optional)</label>
              <input
                v-model="recipient.name"
                type="text"
                placeholder="Recipient name"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Principal ID</label>
              <input
                v-model="recipient.principal"
                type="text"
                placeholder="Principal ID"
                class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 h-10"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 dark:text-gray-400 mb-1">Percentage</label>
              <div class="flex items-center space-x-2">
                <div class="flex-1">
                  <NumberInput
                    v-model="recipient.percentage"
                    placeholder="0"
                    suffix="%"
                    :min="0"
                    :max="100"
                    class="w-full h-10"
                  />
                </div>
                <button 
                  @click="removeCustomAllocationRecipient(allocation.id, recipientIndex)"
                  type="button"
                  class="px-3 py-2 bg-red-600 hover:bg-red-700 text-white text-xs rounded transition-colors h-10 flex-shrink-0"
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
          
          <!-- Vesting Configuration -->
          <div class="border-t border-gray-200 dark:border-gray-700 pt-3">
            <VestingScheduleConfig
              v-model="recipient.vestingSchedule"
              :allocation-name="`${allocation.name || 'Custom'} Recipient ${recipientIndex + 1}`"
            />
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



    <!-- Summary -->
    <div class="bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-700 p-4">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Allocation Summary</h3>
      
      <div class="space-y-2">
        <!-- DEX Liquidity (if enabled) -->
        <div v-if="dexConfig.autoList" class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">DEX Liquidity ({{ dexLiquidityPercentage.toFixed(1) }}%):</span>
          <span class="font-medium text-blue-600">{{ formatAmount(calculatedDexLiquidity) }} ICP</span>
        </div>

        <div class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">Team ({{ teamPercentage }}%):</span>
          <span class="font-medium">{{ formatAmount(teamAmount) }} ICP</span>
        </div>
        <div v-for="allocation in validCustomAllocations" :key="allocation.id" class="flex justify-between text-sm">
          <span class="text-gray-600 dark:text-gray-400">{{ allocation.name }} ({{ allocation.percentage }}%):</span>
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
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { AlertTriangleIcon } from 'lucide-vue-next'
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
  }
})

const emit = defineEmits(['update:modelValue'])

// Auth store for principal access
const authStore = useAuthStore()

// Unique ID for form elements
const autoListMainId = useUniqueId('auto-list-main')
const lpLockId = useUniqueId('lp-lock')

// LP Lock state
const lpLockEnabled = ref(true)

// DEX selection state
const selectedDexToAdd = ref('')

// All available DEX platforms (including disabled ones)
const allDexPlatforms = [
  { id: 'icpswap', name: 'ICPSwap', description: 'Leading DEX on Internet Computer', logo: 'https://app.icpswap.com/static/media/logo-dark.7b8c12091e650c40c5e9f561c57473ba.svg' },
  { id: 'sonic', name: 'Sonic DEX', description: 'High-speed AMM on Internet Computer', logo: 'SonicLogo' },
  { id: 'kongswap', name: 'Kong Swap', description: 'Community-driven DEX', logo: '🦍' },
  { id: 'icdex', name: 'ICDex', description: 'Order book DEX', logo: '📊' }
]

// Available DEXs array (originally from props in MultiDEXConfiguration)
const availableDexs = ref([])

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

// Percentage inputs
const teamPercentage = ref(30)

// Recipients arrays
const teamRecipients = ref([])

// Custom allocations system
const customAllocations = ref([])
let allocationIdCounter = 0

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

// Recipient management functions
const createDefaultRecipient = () => ({
  principal: '',
  percentage: 0,
  name: '',
  vestingEnabled: false,
  vestingSchedule: null // VestingScheduleConfig expects null or VestingSchedule object
})

// Custom allocation management
const createCustomAllocation = (name = '', percentage = 0) => ({
  id: generateAllocationId(),
  name,
  percentage,
  recipients: []
})

const addTeamRecipient = () => {
  teamRecipients.value.push(createDefaultRecipient())
}

const removeTeamRecipient = (index) => {
  teamRecipients.value.splice(index, 1)
}

// Custom allocation management
const addCustomAllocation = () => {
  customAllocations.value.push(createCustomAllocation())
}

const addQuickAllocation = (name, percentage) => {
  customAllocations.value.push(createCustomAllocation(name, percentage))
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

// Watch for changes and emit to parent
watch([teamPercentage, currentRaisedAmount, teamRecipients, customAllocations, dexConfig, availableDexs], () => {
  const allocationData = {
    teamAllocation: teamAmount.value.toString(),
    teamAllocationPercentage: teamPercentage.value,
    simulatedRaisedAmount: currentRaisedAmount.value,
    teamRecipients: teamRecipients.value,
    customAllocations: customAllocations.value.map(allocation => ({
      id: allocation.id,
      name: allocation.name,
      percentage: allocation.percentage,
      amount: calculateAllocationAmount(allocation.percentage).toString(),
      recipients: allocation.recipients
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
}, { deep: true })

// Watch modelValue to restore state when component remounts
watch(
  () => props.modelValue,
  (newValue) => {
    if (newValue && typeof newValue === 'object') {
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

      // Restore custom allocations
      if (newValue.customAllocations && Array.isArray(newValue.customAllocations)) {
        customAllocations.value = newValue.customAllocations.map(alloc => ({
          id: alloc.id,
          name: alloc.name,
          percentage: alloc.percentage,
          recipients: [...(alloc.recipients || [])]
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