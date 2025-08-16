<template>
  <AdminLayout>
    <div class="distribution-detail min-h-screen">
      <!-- Back Button -->
      <div class="mb-6">
        <button @click="router.back()"
          class="flex items-center text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300 transition-colors duration-200">
          <ArrowLeftIcon class="w-5 h-5 mr-2" />
          <span class="font-medium">Back to Distributions</span>
        </button>
      </div>

      <!-- Loading State -->
      <div v-if="loading" class="animate-pulse space-y-8">
        <div class="flex items-center space-x-4">
          <div class="w-16 h-16 bg-gray-200 dark:bg-gray-700 rounded-full"></div>
          <div class="space-y-2">
            <div class="h-8 bg-gray-200 dark:bg-gray-700 rounded w-64"></div>
            <div class="h-4 bg-gray-200 dark:bg-gray-700 rounded w-96"></div>
          </div>
        </div>
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-6">
          <div class="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl" v-for="i in 4" :key="i"></div>
        </div>
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 space-y-6">
            <div class="h-96 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
            <div class="h-64 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
          </div>
          <div class="space-y-6">
            <div class="h-48 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
            <div class="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl"></div>
          </div>
        </div>
      </div>

      <!-- Error State -->
      <div v-else-if="error" class="text-center py-16">
        <div class="max-w-md mx-auto">
          <div class="w-16 h-16 mx-auto mb-4 text-red-500">
            <AlertCircleIcon class="w-full h-full" />
          </div>
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Something went wrong
          </h3>
          <p class="text-gray-500 dark:text-gray-400 mb-6">{{ error }}</p>
          <button @click="fetchDetails"
            class="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
            <RefreshCwIcon class="w-4 h-4 mr-2" />
            Try Again
          </button>
        </div>
      </div>

      <!-- Content -->
      <div v-else-if="details" class="space-y-6">
        <!-- Campaign Header -->
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <TokenLogo :canister-id="details.tokenInfo.canisterId.toString()" :symbol="details.tokenInfo.symbol" :size="64" />
            <div>
              <h4 class="text-xl font-bold text-gray-900 dark:text-white">
                {{ details.title }}
              </h4>
              <div class="flex items-center space-x-4">
                <p class="flex items-center gap-1 text-sm text-gray-500 dark:text-gray-400">{{ canisterId }} <CopyIcon class="w-3.5 h-3.5" :data="canisterId" /></p>
                <Label variant="gray" size="xs" >{{ cyclesToT(canisterCycles) }}</Label>
                  <div :class="statusColor" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium">
                    <div class="w-2 h-2 rounded-full mr-2" :class="statusDotColor"></div>
                    {{ statusText }}
                  </div>
                  <Label variant="blue" class="inline-flex items-center gap-1">
                  <ZapIcon class="w-3 h-3 mr-1" />
                  {{ getVariantKey(details.eligibilityType) }}
                </Label>              
              </div>
            </div>
          </div>

          <!-- Action Toolbar -->
          <div class="flex items-center space-x-3">
            <!-- Admin Management Link - Only show if user is owner -->
            <router-link v-if="isOwner" :to="`/distribution/${distributionId}/manage`"
              class="inline-flex text-sm items-center px-3 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors duration-200">
              <SettingsIcon class="w-4 h-4 mr-2" />
              Manage
            </router-link>
            
            <!-- Check Eligibility Button - Only show if user is not registered and not eligible yet -->
            <button v-if="!isRegistered && !isEligible && !eligibilityStatus" @click="checkEligibility" :disabled="eligibilityLoading"
              class="inline-flex text-sm items-center px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200 disabled:opacity-50">
              <SearchIcon class="w-4 h-4 mr-2" />
              {{ eligibilityLoading ? 'Checking...' : 'Check Eligibility' }}
            </button>

            <!-- Register Button - Only show if user can register (not registered and eligible or open campaign) -->
            <button v-if="!isRegistered && canRegisterFromContext" @click="registerForCampaign" :disabled="registering"
              class="inline-flex text-sm items-center px-3 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors duration-200 disabled:opacity-50">
              <UserPlusIcon class="w-4 h-4 mr-2" />
              {{ registering ? 'Registering...' : 'Register' }}
            </button>

            <!-- Claim Button - Only show if user can claim tokens -->
            <button v-if="canClaimFromContext && availableToClaim > 0" @click="claimTokens" :disabled="claiming"
              class="inline-flex text-sm items-center px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors duration-200 disabled:opacity-50">
              <GiftIcon class="w-4 h-4 mr-2" />
              {{ claiming ? 'Claiming...' : 'Claim Tokens' }}
            </button>

            <!-- Refresh Button - Always visible -->
            <button @click="refreshData" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 transition-colors duration-200 disabled:opacity-50">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              {{ refreshing ? 'Refreshing...' : 'Refresh' }}
            </button>
          </div>
        </div>

        <!-- Description -->
        <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">About This Campaign</h3>
          <p class="text-gray-600 dark:text-gray-300 leading-relaxed">{{ details.description }}</p>
        </div>

        <!-- Contract Balance Status (only show for owners) -->
        <ContractBalanceStatus 
          v-if="details && isOwner"
          :contract-id="canisterId"
          :current-balance="contractBalance"
          :required-amount="details.totalAmount"
          :token-symbol="details.tokenInfo.symbol"
          :token-decimals="details.tokenInfo.decimals"
          :contract-status="distributionStatus"
          :refreshing="checkingBalance"
          @refresh="checkBalance"
          @initial-check="checkBalance"
        />

        <!-- Main Content Grid -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Left Column - Charts & Analytics -->
          <div class="lg:col-span-2 space-y-8">
            <!-- Key Statistics -->
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <MetricCard 
                title="Start Date" 
                :value="startDate"
                icon="CalendarIcon"
                size="sm"
              />
              <MetricCard 
                title="End Date" 
                :value="endDate"
                icon="ClockIcon"
                size="sm"
              />
              <MetricCard 
                title="Max Recipients" 
                :value="maxRecipients"
                icon="UserPlusIcon"
                size="sm"
              />
              <MetricCard 
                v-if="registrationPeriod"
                title="Registration" 
                :value="registrationPeriod.isActive ? 'Open' : 'Closed'"
                icon="ShieldCheckIcon"
                size="sm"
              />
              <MetricCard 
                v-else
                title="Campaign Type" 
                :value="getVariantKey(details.campaignType)"
                icon="ZapIcon"
                size="sm"
              />
            </div>

            <!-- ApexCharts Vesting Schedule (for comparison) -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
              <div class="flex items-center justify-between mb-8">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                    Token Unlock Schedule
                    <Label size="sm" variant="gray">
                      {{ vestingFrequency }}
                    </Label>
                  </h2>
                  <p class="text-gray-600 dark:text-gray-400">Token unlock timeline and distribution pattern
                  </p>
                </div>
                
              </div>

              <VestingChart
                :vesting-data="vestingScheduleData"
                :has-cliff-period="hasCliffPeriod"
                :has-instant-unlock="hasInstantUnlock"
                :current-time-position="currentTimePosition"
                :cliff-end-position="cliffEndPosition"
              />

              <div class="flex items-center space-x-2 text-xs mt-4" v-if="vestingScheduleData.length > 0">
                  <div class="flex items-center space-x-1">
                    <div class="w-2 h-2 bg-green-500 rounded-full"></div>
                    <span>Initial Unlock</span>
                  </div>
                  <div v-if="hasInstantUnlock" class="flex items-center space-x-1">
                    <div class="w-2 h-2 bg-purple-500 rounded-full"></div>
                    <span>Instant Unlock (100%)</span>
                  </div>
                  <div v-if="hasCliffPeriod" class="flex items-center space-x-1">
                    <div class="w-2 h-2 bg-amber-500 rounded-full"></div>
                    <span>Cliff Unlock</span>
                  </div>
                  <div class="flex items-center space-x-1">
                    <div class="w-2 h-2 bg-yellow-500 rounded-full"></div>
                    <span>Linear Vesting</span>
                  </div>
                  <div class="flex items-center space-x-2">
                    <div class="w-3 h-0.5 bg-blue-500"></div>
                    <span class="">Current Time</span>
                  </div>
                </div>
            </div>

            <!-- Recipients & Transactions -->
            <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
              <!-- Tab Headers -->
              <div class="flex items-center justify-between mb-6">
                <div class="flex space-x-1 bg-gray-100 dark:bg-gray-700 p-1 rounded-lg">
                  <button
                    @click="activeTab = 'recipients'"
                    :class="[
                      'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200',
                      activeTab === 'recipients'
                        ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-sm'
                        : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                    ]"
                  >
                    <UsersIcon class="w-4 h-4 mr-2 inline" />
                    Recipients
                  </button>
                  <button
                    @click="activeTab = 'transactions'"
                    :class="[
                      'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200',
                      activeTab === 'transactions'
                        ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-sm'
                        : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                    ]"
                  >
                    <HistoryIcon class="w-4 h-4 mr-2 inline" />
                    Transactions
                  </button>
                </div>
                <div class="flex items-center space-x-2">
                  <button
                    class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200">
                    <FilterIcon class="w-5 h-5" />
                  </button>
                  <button
                    class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors duration-200">
                    <DownloadIcon class="w-5 h-5" />
                  </button>
                </div>
              </div>

              <!-- Recipients Tab -->
              <div v-if="activeTab === 'recipients'">
                <div v-if="participants && participants.length > 0" class="overflow-x-auto">
                  <table class="w-full">
                    <thead>
                      <tr class="border-b border-gray-200 dark:border-gray-600">
                        <th class="text-left py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Address</th>
                        <th class="text-right py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Amount</th>
                        <th class="text-right py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Claimed</th>
                        <th class="text-left py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Note</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr 
                        v-for="recipient in participants" 
                        :key="recipient.address"
                        class="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200"
                      >
                        <td class="py-4 px-4">
                          <div class="flex items-center space-x-3">
                            <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                              <span class="text-white text-xs font-medium">
                                {{ getFirstLetter(recipient.principal) }}
                              </span>
                            </div>
                            <div>
                              <p class="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-1" :title="recipient.principal">
                                {{ shortPrincipal(recipient.principal) }}
                                <CopyIcon :data="recipient.principal" class="w-4 h-4 cursor-pointer" />
                              </p>
                            </div>
                          </div>
                        </td>
                        <td class="py-4 px-4 text-right">
                          <span class="font-semibold text-gray-900 dark:text-white">
                            {{ formatNumber(parseTokenAmount(recipient.eligibleAmount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                          </span>
                        </td>
                        <td class="py-4 px-4 text-right">
                          <span class="text-gray-500 dark:text-gray-400">
                            {{ formatNumber(parseTokenAmount(recipient.claimedAmount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                          </span>
                        </td>
                        <td class="py-4 px-4">
                          <span v-if="recipient.note && recipient.note.length > 0" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                            {{ recipient.note[0] }}
                          </span>
                          <span v-else class="text-gray-400 text-xs">—</span>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
                <div v-else class="text-center py-12">
                  <UsersIcon class="w-12 h-12 text-gray-300 dark:text-gray-600 mx-auto mb-3" />
                  <p class="text-gray-500 dark:text-gray-400">No recipients yet</p>
                  <p class="text-sm text-gray-400 dark:text-gray-500 mt-1">Recipients will appear here once added</p>
                </div>
              </div>

              <!-- Transactions Tab -->
              <div v-if="activeTab === 'transactions'">

                <table class="w-full">
                    <thead>
                      <tr class="border-b border-gray-200 dark:border-gray-600">
                        <th class="text-left py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Address</th>
                        <th class="text-right py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Amount</th>
                        <th class="text-right py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Claimed</th>
                        <th class="text-left py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">TxId</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr 
                        v-for="claim in claimHistory" 
                        :key="claim.id"
                        class="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200"
                      >
                        <td class="py-4 px-4">
                          <div class="flex items-center space-x-3">
                            <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                              <span class="text-white text-xs font-medium">
                                {{ getFirstLetter(claim.participant) }}
                              </span>
                            </div>
                            <div>
                              <p class="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-1" :title="claim.participant">
                                {{ shortPrincipal(claim.participant) }}
                                <CopyIcon :data="claim.participant" class="w-4 h-4 cursor-pointer" />
                              </p>
                            </div>
                          </div>
                        </td>
                        <td class="py-4 px-4 text-right">
                          <span class="font-semibold text-gray-900 dark:text-white">
                            {{ formatNumber(parseTokenAmount(claim.amount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                          </span>
                        </td>
                        <td class="py-4 px-4 text-right">
                          <span class="text-gray-500 dark:text-gray-400">
                            {{ formatNumber(parseTokenAmount(claim.amount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                          </span>
                        </td>
                        <td class="py-2 px-2">
                          <span v-if="claim.transactionId" class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                            #{{ claim.transactionId.length > 0 ? claim.transactionId[0] : 'N/A' }}
                          </span>
                          <span v-else class="text-gray-400 text-xs">—</span>
                        </td>
                      </tr>
                    </tbody>
                  </table>
              </div>
            </div>
          </div>

          <!-- Right Column - Actions & Info -->
          <div class="space-y-6">
            <!-- Eligibility Status -->
            <div v-if="userContext"
              class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-100 dark:border-gray-700">
              <div class="flex items-center space-x-3 mb-4">
                <div class="p-2" :class="isEligible ? 'bg-green-100 dark:bg-green-900' : 'bg-gray-100 dark:bg-gray-700'">
                  <ShieldCheckIcon class="w-5 h-5" :class="isEligible ? 'text-green-600 dark:text-green-400' : 'text-gray-500 dark:text-gray-400'" />
                </div>
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Your Status</h3>
              </div>

              <div class="space-y-4">
                <!-- Status Display -->
                <div class="p-4 rounded-lg border" 
                  :class="isRegistered ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800' : 
                          isEligible ? 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800' :
                          'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600'">
                  <div class="flex items-center space-x-3">
                    <CheckCircleIcon v-if="isRegistered" class="w-6 h-6 text-blue-500" />
                    <CheckCircleIcon v-else-if="isEligible" class="w-6 h-6 text-green-500" />
                    <XCircleIcon v-else class="w-6 h-6 text-gray-500" />
                    <div>
                      <p class="font-semibold" 
                        :class="isRegistered ? 'text-blue-800 dark:text-blue-200' : 
                                isEligible ? 'text-green-800 dark:text-green-200' :
                                'text-gray-800 dark:text-gray-200'">
                        {{ isRegistered ? 'Registered' : isEligible ? 'Eligible' : 'Not Eligible' }}
                      </p>
                      <p class="text-sm" 
                        :class="isRegistered ? 'text-blue-600 dark:text-blue-300' : 
                                isEligible ? 'text-green-600 dark:text-green-300' :
                                'text-gray-600 dark:text-gray-300'">
                        {{ isRegistered ? 'You are registered and can claim tokens when available' : 
                            isEligible ? 'You are eligible to participate in this distribution' :
                            'You are not eligible for this distribution' }}
                      </p>
                    </div>
                  </div>
                </div>

                <!-- Registration Error Display -->
                <!-- <div v-if="userContext?.registrationError" 
                  class="p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
                  <div class="flex items-center space-x-3">
                    <AlertCircleIcon class="w-5 h-5 text-red-500" />
                    <div>
                      <p class="font-semibold text-red-800 dark:text-red-200">Registration Issue</p>
                      <p class="text-sm text-red-600 dark:text-red-300">{{ userContext.registrationError }}</p>
                    </div>
                  </div>
                </div> -->

                <!-- Token Information - Only show if user is registered or has allocation -->
                <div v-if="isRegistered || userAllocation > 0" class="space-y-3">
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-500 dark:text-gray-400">Your Allocation</span>
                    <span class="font-semibold text-gray-900 dark:text-white">
                      {{ userAllocation > 0 ? BackendUtils.formatTokenAmount(userAllocation, details.tokenInfo.decimals) : '0' }} {{ details.tokenInfo.symbol }}
                    </span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-500 dark:text-gray-400">Available to Claim</span>
                    <span class="font-semibold text-green-600 dark:text-green-400">
                      {{ availableToClaim > 0 ? BackendUtils.formatTokenAmount(availableToClaim, details.tokenInfo.decimals) : '0' }} {{ details.tokenInfo.symbol }}
                    </span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-500 dark:text-gray-400">Already Claimed</span>
                    <span class="font-semibold text-gray-900 dark:text-white">
                      {{ alreadyClaimed > 0 ? BackendUtils.formatTokenAmount(alreadyClaimed, details.tokenInfo.decimals) : '0' }} {{ details.tokenInfo.symbol }}
                    </span>
                  </div>
                  
                  <!-- Progress bar for user's claim progress -->
                  <div v-if="userAllocation > 0" class="mt-4">
                    <ProgressBar
                      :percentage="Math.min((Number(alreadyClaimed) / Number(userAllocation)) * 100, 100)"
                      label="Claim Progress"
                      variant="brand"
                      size="sm"
                      :animated="true"
                      :glow-effect="true"
                    />
                  </div>
                </div>

                <!-- Not Eligible Message -->
                <div v-if="!isEligible && !isRegistered" class="text-center py-4">
                  <p class="text-gray-500 dark:text-gray-400 text-sm">
                    You are not eligible for this distribution. Check the eligibility requirements or contact the distribution owner.
                  </p>
                </div>
              </div>
            </div>
            <!-- Campaign Details -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-100 dark:border-gray-700 h-fit">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Campaign Details</h3>

              <!-- Circle Chart -->
              <div v-if="circleChartData" class="mb-6">
                <div class="relative w-48 h-48 mx-auto">
                  <svg class="w-full h-full -rotate-90" viewBox="0 0 100 100">
                    <!-- Background circle -->
                    <circle cx="50" cy="50" r="40" fill="none" stroke="#e5e7eb" stroke-width="8" class="dark:stroke-gray-600"/>
                    
                    <!-- Distributed arc -->
                    <circle 
                      cx="50" 
                      cy="50" 
                      r="40" 
                      fill="none" 
                      stroke="#10b981" 
                      stroke-width="8"
                      stroke-linecap="round"
                      :stroke-dasharray="`${circleChartData.distributedPercentage * 2.51} 251.2`"
                      class="transition-all duration-1000"
                    />
                    
                    <!-- Remaining arc -->
                    <circle 
                      cx="50" 
                      cy="50" 
                      r="40" 
                      fill="none" 
                      stroke="#3b82f6" 
                      stroke-width="8"
                      stroke-linecap="round"
                      :stroke-dasharray="`${circleChartData.remainingPercentage * 2.51} 251.2`"
                      :stroke-dashoffset="`-${circleChartData.distributedPercentage * 2.51}`"
                      class="transition-all duration-1000"
                    />
                  </svg>
                  
                  <!-- Center text -->
                  <div class="absolute inset-0 flex flex-col items-center justify-center">
                    <div class="text-2xl font-bold text-gray-900 dark:text-white">
                      {{ formatNumber(parseTokenAmount(circleChartData.total, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                    </div>
                    <div class="text-sm text-gray-500 dark:text-gray-400">
                      {{ details?.tokenInfo?.symbol }}
                    </div>
                  </div>
                </div>
                
                <!-- Legend -->
                <div class="flex justify-center space-x-6 mt-4">
                  <div class="flex items-center space-x-2">
                    <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                    <span class="text-sm text-gray-600 dark:text-gray-300">
                      Distributed ({{ circleChartData.distributedPercentage.toFixed(1) }}%)
                    </span>
                  </div>
                  <div class="flex items-center space-x-2">
                    <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                    <span class="text-sm text-gray-600 dark:text-gray-300">
                      Remaining ({{ circleChartData.remainingPercentage.toFixed(1) }}%)
                    </span>
                  </div>
                </div>
              </div>

              <!-- Campaign Info -->
              <div class="space-y-4 mb-6">
                <div class="flex items-center space-x-3">
                  <ZapIcon class="w-5 h-5 text-gray-400" />
                  <div>
                    <p class="text-sm text-gray-500 dark:text-gray-400">Vesting Type</p>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {{ vestingFrequency }} {{ hasCliffPeriod ? 'with Cliff' : 'Linear' }}
                    </p>
                  </div>
                </div>

                <div class="flex items-center space-x-3">
                  <LockIcon class="w-5 h-5 text-gray-400" />
                  <div>
                    <p class="text-sm text-gray-500 dark:text-gray-400">Initial Unlock</p>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {{ initialUnlockPercentage }}% at start
                    </p>
                  </div>
                </div>

                <div v-if="details?.allowModification !== undefined" class="flex items-center space-x-3">
                  <ShieldCheckIcon class="w-5 h-5 text-gray-400" />
                  <div>
                    <p class="text-sm text-gray-500 dark:text-gray-400">Modifications</p>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {{ details.allowModification ? 'Allowed' : 'Locked' }}
                    </p>
                  </div>
                </div>

                <div v-if="details?.allowCancel !== undefined" class="flex items-center space-x-3">
                  <AlertCircleIcon class="w-5 h-5 text-gray-400" />
                  <div>
                    <p class="text-sm text-gray-500 dark:text-gray-400">Cancellation</p>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {{ details.allowCancel ? 'Allowed' : 'Not Allowed' }}
                    </p>
                  </div>
                </div>
              </div>

              <!-- Upcoming Milestones -->
              <div class="mb-6">
                <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Upcoming Milestones</h4>
                <div class="space-y-3">
                  <div class="flex items-center justify-between p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Initial Unlock</p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                          {{ distributionStartDate ? formatDate(distributionStartDate) : 'Not available' }}
                        </p>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-blue-600 dark:text-blue-400">{{ initialUnlockPercentage }}%</span>
                  </div>
                  <div class="flex items-center justify-between p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Linear Vesting Complete</p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                          {{ vestingEndDate ? formatDate(vestingEndDate) : 'Not available' }}
                        </p>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-green-600 dark:text-green-400">{{ vestingFrequency }}</span>
                  </div>
                </div>
              </div>

              <!-- Distribution Progress -->
              <div>
                <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Distribution Progress</h4>
                <div class="space-y-3">
                  <ProgressBar
                    :percentage="100 - (100 - initialUnlockPercentage - (stats?.completionPercentage ?? 0))"
                    :label="`Current Period - ${(100 - (100 - initialUnlockPercentage - (stats?.completionPercentage ?? 0))).toFixed(1)}% unlocked`"
                    variant="brand"
                    size="lg"
                    :animated="true"
                    :glow-effect="true"
                    :sub-labels="{
                      left: 'Start',
                      right: 'Complete'
                    }"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { DistributionService } from '@/api/services/distribution'
import {
  ArrowLeftIcon,
  AlertCircleIcon,
  RefreshCwIcon,
  CoinsIcon,
  TrendingUpIcon,
  CheckCircleIcon,
  XCircleIcon,
  UsersIcon,
  UserPlusIcon,
  LockIcon,
  ClockIcon,
  BarChart3Icon,
  FilterIcon,
  DownloadIcon,
  CheckIcon,
  HistoryIcon,
  ShieldCheckIcon,
  SearchIcon,
  GiftIcon,
  CalendarIcon,
  LinkIcon,
  ZapIcon,
  SettingsIcon
} from 'lucide-vue-next'
import { CopyIcon } from '@/icons'
import Label from '@/components/common/Label.vue'
import TokenLogo from '@/components/token/TokenLogo.vue'
import MetricCard from '@/components/token/MetricCard.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import VestingChart from '@/components/distribution/VestingChart.vue'
import ContractBalanceStatus from '@/components/distribution/ContractBalanceStatus.vue'
import ProgressBar from '@/components/common/ProgressBar.vue'
import type { DistributionDetails, DistributionStats } from '@/types/distribution'
import { BackendUtils } from '@/utils/backend'
import { getVariantKey, shortPrincipal, getFirstLetter } from '@/utils/common'
import { 
  getDistributionStatusColor,
  getDistributionStatusDotColor,
  getDistributionStatusText
} from '@/utils/distribution'
import { cyclesToT } from '@/utils/common'
import { parseTokenAmount } from '@/utils/token'
import { toast } from 'vue-sonner'
const route = useRoute()
const router = useRouter()
const loading = ref(true)
const error = ref<string | null>(null)
const details = ref<DistributionDetails | null>(null)
const stats = ref<DistributionStats | null>(null)
const claiming = ref(false)
const refreshing = ref(false)
const eligibilityLoading = ref(false)
const eligibilityStatus = ref(false)
const registering = ref(false)
const distributionStatus = ref<string>('')
const chartPeriod = ref('Monthly')
const activeTab = ref('recipients')
const participants = ref<any[]>([])

// User context data
const userContext = ref<{
  principal: string;
  isOwner: boolean;
  isRegistered: boolean;
  isEligible: boolean;
  participant: any;
  claimableAmount: bigint;
  distributionStatus: string;
  canRegister: boolean;
  canClaim: boolean;
  registrationError?: string;
} | null>(null)

// User participant data
const participantData = ref<any>(null)

// User data  
const userAllocation = ref<bigint>(BigInt(0))
const availableToClaim = ref<bigint>(BigInt(0))
const alreadyClaimed = ref<bigint>(BigInt(0))

const canisterCycles = ref(0)
const contractBalance = ref(BigInt(0))
const checkingBalance = ref(false)

// Mock claim history data
const claimHistory = ref<any[]>([])

const canisterId = computed(() => route.params.id as string)

// Distribution status computed properties using utility functions
const statusColor = computed(() => {
  return getDistributionStatusColor(distributionStatus.value)
})

const statusDotColor = computed(() => {
  return getDistributionStatusDotColor(distributionStatus.value)
})

const statusText = computed(() => {
  return getDistributionStatusText(distributionStatus.value)
})

const canClaim = computed(() => {
  return canClaimFromContext.value && availableToClaim.value > 0
})

// Computed properties for milestone dates
const distributionStartDate = computed(() => {
  if (!details.value?.distributionStart) return null
  // Convert nanoseconds to milliseconds
  const timestamp = Number(details.value.distributionStart) / 1_000_000
  return new Date(timestamp)
})

const vestingEndDate = computed(() => {
  if (!details.value?.distributionStart || !details.value?.vestingSchedule) return null
  
  const startTimestamp = Number(details.value.distributionStart) / 1_000_000
  
  if ('Linear' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Linear.duration)
    const durationMs = durationNanos / 1_000_000
    return new Date(startTimestamp + durationMs)
  }
  
  return null
})

const initialUnlockPercentage = computed(() => {
  return details.value?.initialUnlockPercentage ? Number(details.value.initialUnlockPercentage) : 0
})

const vestingFrequency = computed(() => {
  if (!details.value?.vestingSchedule) return 'Unknown'
  
  if ('Linear' in details.value.vestingSchedule) {
    const frequency = details.value.vestingSchedule.Linear.frequency
    if ('Monthly' in frequency) return 'Monthly'
    if ('Weekly' in frequency) return 'Weekly'
    if ('Daily' in frequency) return 'Daily'
  }
  
  return 'Unknown'
})

const vestingScheduleData = computed(() => {
  if (!details.value?.distributionStart || !details.value?.vestingSchedule || !details.value?.totalAmount) {
    return []
  }

  const startTimestamp = Number(details.value.distributionStart) / 1_000_000
  const totalAmount = Number(details.value.totalAmount)
  const initialUnlock = Number(details.value.initialUnlockPercentage || 0)
  
  // Add 2-day buffer (in milliseconds)
  const bufferMs = 2 * 24 * 60 * 60 * 1000 // 2 days
  
  if ('Linear' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Linear.duration)
    const durationMs = durationNanos / 1_000_000
    const frequency = details.value.vestingSchedule.Linear.frequency
    
    let intervalMs = 0
    let periods = 0
    
    if ('Monthly' in frequency) {
      intervalMs = 30 * 24 * 60 * 60 * 1000 // ~30 days
      periods = Math.ceil(durationMs / intervalMs)
    } else if ('Weekly' in frequency) {
      intervalMs = 7 * 24 * 60 * 60 * 1000
      periods = Math.ceil(durationMs / intervalMs)
    } else if ('Daily' in frequency) {
      intervalMs = 24 * 60 * 60 * 1000
      periods = Math.ceil(durationMs / intervalMs)
    }
    
    if (periods === 0) return []
    
    const initialAmount = (totalAmount * initialUnlock) / 100
    const remainingAmount = totalAmount - initialAmount
    const amountPerPeriod = remainingAmount / periods
    
    const schedule = []
    let cumulativeAmount = 0
    
    // Start buffer point (2 days before start)
    schedule.push({
      date: new Date(startTimestamp - bufferMs),
      amount: 0,
      cumulative: 0,
      percentage: 0,
      type: 'buffer'
    })
    
    // Initial unlock - Handle Instant case
    if (initialUnlock > 0) {
      cumulativeAmount = initialAmount
      schedule.push({
        date: new Date(startTimestamp),
        amount: initialAmount,
        cumulative: cumulativeAmount,
        percentage: initialUnlock,
        type: initialUnlock === 100 ? 'instant' : 'initial'
      })
    }
    
    // Linear vesting periods
    for (let i = 1; i <= periods; i++) {
      const periodDate = new Date(startTimestamp + (intervalMs * i))
      cumulativeAmount += amountPerPeriod
      
      schedule.push({
        date: periodDate,
        amount: amountPerPeriod,
        cumulative: Math.min(cumulativeAmount, totalAmount),
        percentage: Math.min((cumulativeAmount / totalAmount) * 100, 100),
        type: 'vesting'
      })
    }
    
    // End buffer point (2 days after end)
    const endTimestamp = startTimestamp + durationMs
    schedule.push({
      date: new Date(endTimestamp + bufferMs),
      amount: 0,
      cumulative: Math.min(cumulativeAmount, totalAmount),
      percentage: Math.min((cumulativeAmount / totalAmount) * 100, 100),
      type: 'buffer'
    })
    
    return schedule
  }
  
  if ('Cliff' in details.value.vestingSchedule) {
    const cliffConfig = details.value.vestingSchedule.Cliff
    const cliffDurationNanos = Number(cliffConfig.cliffPeriod)
    const cliffDurationMs = cliffDurationNanos / 1_000_000
    const vestingDurationNanos = Number(cliffConfig.vestingPeriod)
    const vestingDurationMs = vestingDurationNanos / 1_000_000
    const frequency = cliffConfig.frequency
    
    let intervalMs = 0
    let periods = 0
    
    if ('Monthly' in frequency) {
      intervalMs = 30 * 24 * 60 * 60 * 1000
      periods = Math.ceil(vestingDurationMs / intervalMs)
    } else if ('Weekly' in frequency) {
      intervalMs = 7 * 24 * 60 * 60 * 1000
      periods = Math.ceil(vestingDurationMs / intervalMs)
    } else if ('Daily' in frequency) {
      intervalMs = 24 * 60 * 60 * 1000
      periods = Math.ceil(vestingDurationMs / intervalMs)
    }
    
    const cliffEndTimestamp = startTimestamp + cliffDurationMs
    const initialAmount = (totalAmount * initialUnlock) / 100
    const cliffAmount = (totalAmount * Number(cliffConfig.cliffPercentage || 0)) / 100
    const remainingAmount = totalAmount - initialAmount - cliffAmount
    const amountPerPeriod = periods > 0 ? remainingAmount / periods : 0
    
    const schedule = []
    let cumulativeAmount = 0
    
    // Start buffer point (2 days before start)
    schedule.push({
      date: new Date(startTimestamp - bufferMs),
      amount: 0,
      cumulative: 0,
      percentage: 0,
      type: 'buffer'
    })
    
    // Initial unlock - Handle Instant case  
    if (initialAmount > 0) {
      cumulativeAmount = initialAmount
      schedule.push({
        date: new Date(startTimestamp),
        amount: initialAmount,
        cumulative: cumulativeAmount,
        percentage: initialUnlock,
        type: initialUnlock === 100 ? 'instant' : 'initial'
      })
    }
    
    // Cliff period (flat line)
    schedule.push({
      date: new Date(cliffEndTimestamp),
      amount: cliffAmount,
      cumulative: cumulativeAmount + cliffAmount,
      percentage: ((cumulativeAmount + cliffAmount) / totalAmount) * 100,
      type: 'cliff'
    })
    
    cumulativeAmount += cliffAmount
    
    // Linear vesting after cliff
    for (let i = 1; i <= periods; i++) {
      const periodDate = new Date(cliffEndTimestamp + (intervalMs * i))
      cumulativeAmount += amountPerPeriod
      
      schedule.push({
        date: periodDate,
        amount: amountPerPeriod,
        cumulative: Math.min(cumulativeAmount, totalAmount),
        percentage: Math.min((cumulativeAmount / totalAmount) * 100, 100),
        type: 'vesting'
      })
    }
    
    // End buffer point (2 days after end)
    const endTimestamp = cliffEndTimestamp + vestingDurationMs
    schedule.push({
      date: new Date(endTimestamp + bufferMs),
      amount: 0,
      cumulative: Math.min(cumulativeAmount, totalAmount),
      percentage: Math.min((cumulativeAmount / totalAmount) * 100, 100),
      type: 'buffer'
    })
    
    return schedule
  }
  
  return []
})

// Utility functions
const formatNumber = (value: number) => {
  return new Intl.NumberFormat().format(value)
}

const formatDate = (date: Date) => {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  }).format(date)
}


const fetchDetails = async () => {
  try {
    loading.value = true
    error.value = null
    details.value = await DistributionService.getDistributionDetails(canisterId.value)

  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to fetch distribution details'
    console.error('Error fetching distribution details:', err)
  } finally {
    loading.value = false
  }
}

const fetchStats = async () => {
  try {
    stats.value = await DistributionService.getDistributionStats(canisterId.value)
  } catch (err) {
    console.error('Error fetching distribution stats:', err)
  }
}

const fetchDistributionStatus = async () => {
  try {
    const status = await DistributionService.getDistributionStatus(canisterId.value)
    distributionStatus.value = status
  } catch (err) {
    console.error('Error fetching distribution status:', err)
  }
}

const fetchCanisterInfo = async () => {
  try {
    const info = await DistributionService.getCanisterInfo(canisterId.value)
    canisterCycles.value = info.cyclesBalance
  } catch (err) {
    console.error('Error fetching canister info:', err)
  }
}

const checkEligibility = async () => {
  try {
    eligibilityLoading.value = true
    // Simulate eligibility check
    await new Promise(resolve => setTimeout(resolve, 2000))
    eligibilityStatus.value = true
  } catch (err) {
    console.error('Error checking eligibility:', err)
  } finally {
    eligibilityLoading.value = false
  }
}

const claimTokens = async () => {
  try {
    claiming.value = true
    const result = await DistributionService.claimTokens(canisterId.value)
    if ('ok' in result) {
      toast.success('Successfully claimed tokens')
    } else {
      toast.error('Error: ' + result.err)
    }

    // Update available and claimed amounts
    alreadyClaimed.value += availableToClaim.value
    availableToClaim.value = BigInt(0)

    // Add to claim history
    claimHistory.value.unshift({
      id: Date.now().toString(),
      amount: availableToClaim.value,
      date: formatDate(new Date()),
      txHash: Math.random().toString(36).substring(2, 18)
    })

    await refreshData()
  } catch (err) {
    console.error('Error claiming tokens:', err)
  } finally {
    claiming.value = false
  }
}

const checkBalance = async () => {
  if (!details.value) return
  try {
    checkingBalance.value = true
    // Create a proper Token object with required properties
    const token = {
      canisterId: details.value.tokenInfo.canisterId.toString(),
      name: details.value.tokenInfo.name,
      symbol: details.value.tokenInfo.symbol,
      decimals: details.value.tokenInfo.decimals,
      fee: 10000, // Default fee
      standards: ['ICRC-1'], // Default standards
      metrics: { totalSupply: 0, holders: 0, marketCap: 0, price: 0, volume: 0 } // Default metrics
    }
    const balance = await DistributionService.getContractBalance(token, canisterId.value)
    contractBalance.value = balance
  } catch (err) {
    console.error('Error fetching contract balance:', err)
  } finally {
    checkingBalance.value = false
  }
}

const refreshData = async () => {
  refreshing.value = true
  await fetchDetails()
  await fetchStats()
  await fetchDistributionStatus()
  await fetchAllParticipants()
  await fetchClaimHistory()
  await fetchUserContext()
  await checkBalance()
  refreshing.value = false
}

const fetchClaimHistory = async () => {
  try {
    claimHistory.value = await DistributionService.getClaimHistory(canisterId.value)
  } catch (err) {
    console.error('Error fetching claim history:', err)
  }
}
const fetchAllParticipants = async () => {
  try {
    participants.value = await DistributionService.getAllParticipants(canisterId.value)
  } catch (err) {
    console.error('Error fetching all participants:', err)
  }
}

const registerForCampaign = async () => {
  try {
    registering.value = true
    const result = await DistributionService.register(canisterId.value)
    if ('ok' in result) {
      toast.success('Successfully registered for campaign')
    } else {
      toast.error('Error: ' + result.err)
    }
    
    // Refresh data after successful registration
    await refreshData()
  } catch (err) {
    toast.error('Error: ' + err)
    // Handle error - could show toast notification
  } finally {
    registering.value = false
  }
}


// Current time and cliff indicators
const currentTimePosition = computed(() => {
  if (vestingScheduleData.value.length === 0) return null
  
  const now = new Date()
  const startTime = vestingScheduleData.value[0].date.getTime()
  const endTime = vestingScheduleData.value[vestingScheduleData.value.length - 1].date.getTime()
  
  if (now.getTime() < startTime || now.getTime() > endTime) return null
  
  const progress = (now.getTime() - startTime) / (endTime - startTime)
  return progress * 100
})

const cliffEndPosition = computed(() => {
  const cliffPoint = vestingScheduleData.value.find(point => point.type === 'cliff')
  if (!cliffPoint) return null
  
  const startTime = vestingScheduleData.value[0].date.getTime()
  const endTime = vestingScheduleData.value[vestingScheduleData.value.length - 1].date.getTime()
  
  const progress = (cliffPoint.date.getTime() - startTime) / (endTime - startTime)
  return progress * 100
})

const hasCliffPeriod = computed(() => {
  return vestingScheduleData.value.some(point => point.type === 'cliff')
})

const hasInstantUnlock = computed(() => {
  return vestingScheduleData.value.some(point => point.type === 'instant')
})


// Circle chart data for Campaign Details
const circleChartData = computed(() => {
  if (!details.value?.totalAmount || !stats.value) return null
  
  const total = Number(details.value.totalAmount)
  const distributed = Number(stats.value.totalClaimed || 0)
  const remaining = total - distributed
  
  return {
    total,
    distributed,
    remaining,
    distributedPercentage: total > 0 ? (distributed / total) * 100 : 0,
    remainingPercentage: total > 0 ? (remaining / total) * 100 : 100
  }
})

// Additional metrics for cards
const startDate = computed(() => {
  if (!details.value?.distributionStart) return 'Not set'
  return formatDate(new Date(Number(details.value.distributionStart) / 1_000_000))
})

const endDate = computed(() => {
  if (!details.value?.distributionEnd || details.value.distributionEnd.length === 0) {
    return vestingEndDate.value ? formatDate(vestingEndDate.value) : 'Not set'
  }
  return formatDate(new Date(Number(details.value.distributionEnd) / 1_000_000))
})

const maxRecipients = computed(() => {
  if (!details.value?.maxRecipients || details.value.maxRecipients.length === 0) return 'Unlimited'
  return formatNumber(Number(details.value.maxRecipients[0]))
})

const registrationPeriod = computed(() => {
  if (!details.value?.registrationPeriod || details.value.registrationPeriod.length === 0) return null
  
  const start = new Date(Number(details.value.registrationPeriod[0]) / 1_000_000)
  const end = new Date(Number(details.value.registrationPeriod[1]) / 1_000_000)
  
  return {
    start: formatDate(start),
    end: formatDate(end),
    isActive: Date.now() >= start.getTime() && Date.now() <= end.getTime()
  }
})

const daysUntilStart = computed(() => {
  if (!distributionStartDate.value) return null
  
  const now = new Date()
  const diff = distributionStartDate.value.getTime() - now.getTime()
  const days = Math.ceil(diff / (1000 * 60 * 60 * 24))
  
  if (days <= 0) return null
  return days
})

const daysUntilEnd = computed(() => {
  if (!vestingEndDate.value) return null
  
  const now = new Date()
  const diff = vestingEndDate.value.getTime() - now.getTime()
  const days = Math.ceil(diff / (1000 * 60 * 60 * 24))
  
  if (days <= 0) return null
  return days
})

// Check if user can register for this campaign (legacy - prefer canRegisterFromContext)
const canRegister = computed(() => {
  // Use context-based registration check if available, otherwise fall back to old logic
  if (userContext.value) {
    return canRegisterFromContext.value
  }
  
  // Fallback logic for when context is not available
  if (!details.value || !stats.value) return false
  
  // Check recipient mode is SelfService
  const isSelfService = details.value.recipientMode && 'SelfService' in details.value.recipientMode
  
  // Check eligibility type is Open  
  const isOpen = details.value.eligibilityType && 'Open' in details.value.eligibilityType
  
  // Check campaign is active
  const isActive = stats.value.isActive
  
  // Check if registration period is active (if exists)
  let isRegistrationOpen = true
  if (registrationPeriod.value) {
    isRegistrationOpen = registrationPeriod.value.isActive
  }
  
  return isSelfService && isOpen && isActive && isRegistrationOpen
})

// Get user context function
const fetchUserContext = async () => {
  try {
    const context = await DistributionService.getUserContext(canisterId.value)
    userContext.value = context
    
    // Update local user data from context
    if (context.participant) {
      userAllocation.value = context.participant.eligibleAmount || BigInt(0)
      alreadyClaimed.value = context.participant.claimedAmount || BigInt(0)
    }
    availableToClaim.value = context.claimableAmount
    
    // If user is registered, fetch detailed participant data
    if (context.isRegistered && context.principal) {
      await fetchParticipantData(context.principal)
    }
  } catch (err) {
    console.error('Error fetching user context:', err)
    // Set default values on error
    userContext.value = null
  }
}

// Fetch detailed participant data
const fetchParticipantData = async (principalId?: string) => {
  try {
    // Use the principal from context or auth store
    const principal = principalId || userContext.value?.principal
    if (!principal) return
    
    const participant = await DistributionService.getParticipant(canisterId.value, principal)
    participantData.value = participant
    
    // Update user data with participant info if available
    if (participant && participant.length > 0) {
      const participantInfo = participant[0] // getParticipant returns an optional array
      userAllocation.value = participantInfo.eligibleAmount || BigInt(0)
      alreadyClaimed.value = participantInfo.claimedAmount || BigInt(0)
      
      // Calculate available to claim from claimable amount in context
      availableToClaim.value = userContext.value?.claimableAmount || BigInt(0)
    }
  } catch (err) {
    console.error('Error fetching participant data:', err)
    participantData.value = null
  }
}

// Check if current user is the owner of this distribution
const isOwner = computed(() => {
  return userContext.value?.isOwner ?? false
})

// Check if user is registered
const isRegistered = computed(() => {
  return userContext.value?.isRegistered ?? false
})

// Check if user is eligible
const isEligible = computed(() => {
  return userContext.value?.isEligible ?? false
})

// Check if user can register (from context)
const canRegisterFromContext = computed(() => {
  return userContext.value?.canRegister ?? false
})

// Check if user can claim (from context)
const canClaimFromContext = computed(() => {
  return userContext.value?.canClaim ?? false
})

const distributionId = computed(() => route.params.id as string)

const parallelFetch = async () => {
  await Promise.all([
    fetchDetails(),
    fetchCanisterInfo(),
    fetchStats(),
    fetchDistributionStatus(),
    fetchAllParticipants(),
    fetchClaimHistory(),
    fetchUserContext()
  ])
}

onMounted(() => {
  parallelFetch()
})
</script>

<style scoped>
.distribution-detail {
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  min-height: 100vh;
}

.dark .distribution-detail {
  background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
}

.stat-card {
  @apply bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-6 border border-gray-100 dark:border-gray-700;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}



.dark .stat-card {
  background: rgba(31, 41, 55, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(75, 85, 99, 0.3);
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
}

.dark .stat-card:hover {
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.3), 0 10px 10px -5px rgba(0, 0, 0, 0.2);
}

.stat-title {
  @apply text-sm font-medium text-gray-500 dark:text-gray-400;
  letter-spacing: 0.025em;
}

.stat-value {
  @apply mt-2 font-bold text-gray-900 dark:text-white;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-size: 200% 200%;
  animation: gradient-shift 3s ease infinite;
}

@keyframes gradient-shift {
  0% {
    background-position: 0% 50%;
  }

  50% {
    background-position: 100% 50%;
  }

  100% {
    background-position: 0% 50%;
  }
}

.dark .stat-value {
  background: linear-gradient(135deg, #60a5fa 0%, #a78bfa 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

/* Enhanced button styles */
.btn-gradient {
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  background-size: 200% 200%;
  animation: gradient-shift 3s ease infinite;
  position: relative;
  overflow: hidden;
}

.btn-gradient::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
  transition: left 0.5s;
}

.btn-gradient:hover::before {
  left: 100%;
}

/* Card animations */
@keyframes card-entrance {
  0% {
    opacity: 0;
    transform: translateY(20px);
  }

  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

.stat-card {
  animation: card-entrance 0.6s ease-out forwards;
}

.stat-card:nth-child(1) {
  animation-delay: 0.1s;
}

.stat-card:nth-child(2) {
  animation-delay: 0.2s;
}

.stat-card:nth-child(3) {
  animation-delay: 0.3s;
}

.stat-card:nth-child(4) {
  animation-delay: 0.4s;
}

/* Glassmorphism effects */
.glass-card {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
}

.dark .glass-card {
  background: rgba(31, 41, 55, 0.1);
  border: 1px solid rgba(75, 85, 99, 0.2);
  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
}

/* Progress bars with glow */
.progress-bar {
  position: relative;
  overflow: hidden;
}

.progress-bar::after {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(90deg, transparent 0%, rgba(255, 255, 255, 0.3) 50%, transparent 100%);
  animation: shimmer 2s infinite;
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }

  100% {
    transform: translateX(100%);
  }
}

/* Responsive improvements */
@media (max-width: 768px) {
  .stat-card {
    padding: 1rem;
  }

  .stat-value {
    font-size: 1.5rem;
  }

  .distribution-detail {
    padding: 1rem;
  }
}

@media (max-width: 640px) {
  .grid.grid-cols-2.lg\:grid-cols-4 {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .grid.grid-cols-1.lg\:grid-cols-3 {
    grid-template-columns: 1fr;
  }

  .stat-value {
    font-size: 1.25rem;
  }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f5f9;
}

.dark ::-webkit-scrollbar-track {
  background: #1e293b;
}

::-webkit-scrollbar-thumb {
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: linear-gradient(135deg, #2563eb, #7c3aed);
}

/* Loading animation improvements */
@keyframes pulse-glow {

  0%,
  100% {
    opacity: 1;
    box-shadow: 0 0 20px rgba(59, 130, 246, 0.3);
  }

  50% {
    opacity: 0.8;
    box-shadow: 0 0 40px rgba(59, 130, 246, 0.5);
  }
}

.animate-pulse-glow {
  animation: pulse-glow 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

/* Web3 aesthetic enhancements */
.neon-border {
  border: 2px solid transparent;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6) border-box;
  border-radius: 12px;
  position: relative;
}

.neon-border::before {
  content: '';
  position: absolute;
  inset: 0;
  padding: 2px;
  background: linear-gradient(135deg, #3b82f6, #8b5cf6);
  border-radius: inherit;
  mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  mask-composite: xor;
  -webkit-mask-composite: xor;
}

/* Hover effects for interactive elements */
.interactive-hover {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.interactive-hover:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
}

.dark .interactive-hover:hover {
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.3);
}

/* Status indicator glow */
.status-indicator {
  position: relative;
}

.status-indicator::before {
  content: '';
  position: absolute;
  inset: -2px;
  border-radius: inherit;
  padding: 2px;
  background: linear-gradient(45deg, currentColor, transparent, currentColor);
  mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  mask-composite: xor;
  -webkit-mask-composite: xor;
  opacity: 0.5;
  animation: rotate 3s linear infinite;
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}

/* Typography enhancements */
.heading-gradient {
  background: linear-gradient(135deg, #1f2937 0%, #3b82f6 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}

.dark .heading-gradient {
  background: linear-gradient(135deg, #f8fafc 0%, #60a5fa 100%);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
</style>