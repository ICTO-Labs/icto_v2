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
                  <div :class="currentPhaseConfig.color.bg + ' ' + currentPhaseConfig.color.text + ' ' + currentPhaseConfig.color.border" 
                       class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border">
                    <div class="w-2 h-2 rounded-full mr-2 animate-pulse" :class="currentPhaseConfig.color.dot"></div>
                    {{ currentPhaseConfig.label }}
                  </div>
                  <Label variant="blue" class="inline-flex items-center gap-1">
                  <ZapIcon class="w-3 h-3 mr-1" />
                  {{ getVariantKey(details.eligibilityType) }}
                </Label>
                <!-- Campaign Type Label -->
                <div :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').bgClass" class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border">
                  <div class="w-2 h-2 rounded-full mr-2" :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').className.replace('text-', 'bg-')"></div>
                  <span :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').className">
                    {{ getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').label }}
                  </span>
                </div>              
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
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">About This Campaign</h3>
            <!-- Countdown Component -->
            <DistributionCountdown 
              :start-time="details.distributionStart"
              :end-time="details.distributionEnd && details.distributionEnd.length > 0 ? details.distributionEnd[0] : null"
              :status="countdownStatus"
            />
          </div>
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
            <!-- Phase-based Metrics -->
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
              <!-- Current Phase with Countdown -->
              <div v-if="showPhaseCountdown" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                <div class="flex items-center space-x-2 mb-2">
                  <ClockIcon class="h-5 w-5 text-gray-400 dark:text-gray-500" />
                  <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Next Phase</h3>
                </div>
                <vue-countdown 
                  :time="phaseCountdownTime" 
                  v-slot="{ days, hours, minutes, seconds }"
                  class="text-brand-600 dark:text-brand-400 font-semibold"
                >
                  <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ phaseCountdownLabel }}</div>
                  <div class="text-sm font-bold">{{ days }}d {{ hours }}h {{ minutes }}m {{ seconds }}s</div>
                </vue-countdown>
              </div>
              
              <!-- Registration Period (only for Airdrop campaigns that enable registration) -->
              <MetricCard 
                v-if="campaignTimeline.hasRegistration && getVariantKey(details.campaignType) !== 'Lock'"
                title="Registration" 
                :value="phaseInfo.currentPhase === 'registration_open' ? 'Open Now' : 
                         phaseInfo.currentPhase === 'registration_closed' ? 'Closed' : 
                         'Not Started'"
                icon="ShieldCheckIcon"
                size="sm"
              />
              
              <MetricCard 
                title="Max Recipients" 
                :value="maxRecipients"
                icon="UserPlusIcon"
                size="sm"
              />
              
              <MetricCard 
                title="Campaign Type" 
                :value="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').label"
                icon="ZapIcon"
                size="sm"
              />
            </div>

            <!-- Lock Detail (for Lock campaigns) -->
            <div v-if="getVariantKey(details.campaignType) === 'Lock'" class="">
              <LockDetail :campaign="{ id: distributionId, creator: details?.owner?.toText() || '', config: details as any }" />
            </div>

            <!-- ApexCharts Vesting Schedule (for Airdrop/Vesting campaigns with vesting data) -->
            <div v-else-if="vestingScheduleData.length > 0" class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
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

            <!-- Claims Timeline (for Airdrop/Vesting campaigns only) -->
            <div v-if="getVariantKey(details.campaignType) !== 'Lock'" class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
              <div class="flex items-center justify-between mb-8">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                    Claims Timeline
                    <Label size="sm" variant="blue">
                      Daily Activity
                    </Label>
                  </h2>
                  <p class="text-gray-600 dark:text-gray-400">Real-time tracking of token claims over time</p>
                </div>
              </div>

              <div class="h-80">
                <VueApexCharts v-if="claimTimelineData.length > 0"
                  type="area"
                  height="320"
                  :options="claimTimelineOptions"
                  :series="claimTimelineData" />
                <div v-else class="flex flex-col items-center justify-center h-full">
                  <div class="w-16 h-16 text-gray-300 dark:text-gray-600 mb-4">
                    <BarChart3Icon class="w-full h-full" />
                  </div>
                  <p class="text-gray-500 dark:text-gray-400 font-medium">No claims data available</p>
                  <p class="text-sm text-gray-400 dark:text-gray-500 mt-1">Claims will appear here once users start claiming tokens</p>
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
            <!-- Contract Status -->
            <ContractStatus
              :details="details"
              :user-context="userContext"
              :campaign-timeline="campaignTimeline"
              @action="handleStatusAction"
            />
            
            <!-- Eligibility Status -->
            <div v-if="userContext"
              class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-100 dark:border-gray-700">
              <div class="flex items-center space-x-3 mb-4">
                <div class="p-2 rounded-full" :class="statusStyles.iconBg">
                  <component :is="statusIcon" class="w-5 h-5" :class="statusStyles.icon" />
                </div>
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Your Status</h3>
              </div>

              <div class="space-y-4">
                <!-- Enhanced Status Display -->
                <div class="p-4 rounded-lg border transition-all duration-200" :class="statusStyles.container">
                  <div class="flex items-start space-x-3">
                    <div class="flex-shrink-0 mt-0.5">
                      <component :is="statusIcon" class="w-6 h-6" :class="statusStyles.icon" />
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center justify-between">
                        <p class="text-lg font-semibold" :class="statusStyles.title">
                          {{ userStatus.label }}
                        </p>
                        <div v-if="userStatus.type === 'withdrawn'" 
                             class="px-2 py-1 rounded-full text-xs font-medium bg-amber-200 dark:bg-amber-800 text-amber-800 dark:text-amber-200">
                          100% Complete
                        </div>
                      </div>
                      <p class="text-sm mt-1" :class="statusStyles.description">
                        {{ userStatus.description }}
                      </p>
                      
                      <!-- Progress indicator for registered users -->
                      <div v-if="userStatus.type === 'registered' && Number(userAllocation) > 0" class="mt-3">
                        <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mb-1">
                          <span>Progress</span>
                          <span>{{ ((Number(alreadyClaimed) / Number(userAllocation)) * 100).toFixed(1) }}%</span>
                        </div>
                        <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                          <div 
                            class="bg-gradient-to-r from-green-400 to-green-600 h-1.5 rounded-full transition-all duration-300"
                            :style="{ width: Math.min((Number(alreadyClaimed) / Number(userAllocation)) * 100, 100) + '%' }"
                          ></div>
                        </div>
                      </div>
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
                    <span class="text-gray-500 dark:text-gray-400">
                      {{ getVariantKey(details.campaignType) === 'Lock' ? 'Available to Withdraw' : 'Available to Claim' }}
                    </span>
                    <span class="font-semibold text-green-600 dark:text-green-400">
                      {{ availableToClaim > 0 ? BackendUtils.formatTokenAmount(availableToClaim, details.tokenInfo.decimals) : '0' }} {{ details.tokenInfo.symbol }}
                    </span>
                  </div>
                  <div class="flex justify-between text-sm">
                    <span class="text-gray-500 dark:text-gray-400">
                      {{ getVariantKey(details.campaignType) === 'Lock' ? 'Already Withdrawn' : 'Already Claimed' }}
                    </span>
                    <span class="font-semibold text-gray-900 dark:text-white">
                      {{ alreadyClaimed > 0 ? BackendUtils.formatTokenAmount(alreadyClaimed, details.tokenInfo.decimals) : '0' }} {{ details.tokenInfo.symbol }}
                    </span>
                  </div>
                  
                  <!-- Progress bar for user's claim progress -->
                  <div v-if="userAllocation > 0" class="mt-4">
                    <ProgressBar
                      :percentage="Math.min((Number(alreadyClaimed) / Number(userAllocation)) * 100, 100)"
                      :label="getVariantKey(details.campaignType) === 'Lock' ? 'Withdrawal Progress' : 'Claim Progress'"
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
                      stroke="#f0c94d" 
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
                      stroke="#b27c10" 
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
                    <div class="w-3 h-3 bg-blue-300 rounded-full"></div>
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
                    <p class="text-sm text-gray-500 dark:text-gray-400">
                      {{ getVariantKey(details.campaignType) === 'Lock' ? 'Lock Type' : 'Vesting Type' }}
                    </p>
                    <p class="font-medium text-gray-900 dark:text-white">
                      {{ getVariantKey(details.campaignType) === 'Lock' ? vestingFrequency : (vestingFrequency + (hasCliffPeriod ? ' with Cliff' : ' Linear')) }}
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
                  <!-- For Lock campaigns, show Lock Start instead of Initial Unlock -->
                  <div v-if="getVariantKey(details.campaignType) === 'Lock'" class="flex items-center justify-between p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-3 h-3 bg-purple-500 rounded-full"></div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Lock Period</p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                          {{ distributionStartDate ? formatDate(distributionStartDate, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }) : 'Not available' }}
                        </p>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-purple-600 dark:text-purple-400">Locked</span>
                  </div>
                  
                  <!-- For other campaigns, show Initial Unlock -->
                  <div v-else class="flex items-center justify-between p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-3 h-3 bg-blue-500 rounded-full"></div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">Initial Unlock</p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                          {{ distributionStartDate ? formatDate(distributionStartDate, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }) : 'Not available' }}
                        </p>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-blue-600 dark:text-blue-400">{{ initialUnlockPercentage }}%</span>
                  </div>
                  
                  <!-- End milestone -->
                  <div class="flex items-center justify-between p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
                    <div class="flex items-center space-x-3">
                      <div class="w-3 h-3 bg-green-500 rounded-full"></div>
                      <div>
                        <p class="font-medium text-gray-900 dark:text-white">
                          {{ getVariantKey(details.campaignType) === 'Lock' ? 'Unlock' : 'Linear Vesting Complete' }}
                        </p>
                        <p class="text-sm text-gray-500 dark:text-gray-400">
                          {{ vestingEndDate ? formatDate(vestingEndDate, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }) : 'Not available' }}
                        </p>
                      </div>
                    </div>
                    <span class="text-sm font-semibold text-green-600 dark:text-green-400">
                      {{ getVariantKey(details.campaignType) === 'Lock' ? '100%' : vestingFrequency }}
                    </span>
                  </div>
                </div>
              </div>

              <!-- Distribution Progress -->
              <div>
                <h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                  {{ getVariantKey(details.campaignType) === 'Lock' ? 'Lock Progress' : 'Distribution Progress' }}
                </h4>
                <div class="space-y-3">
                  <ProgressBar
                    :percentage="100 - (100 - initialUnlockPercentage - (stats?.completionPercentage ?? 0))"
                    :label="`Current Period - ${(100 - (100 - initialUnlockPercentage - (stats?.completionPercentage ?? 0))).toFixed(1)}% ${getVariantKey(details.campaignType) === 'Lock' ? 'toward unlock' : 'unlocked'}`"
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
import LockDetail from '@/components/distribution/LockDetail.vue'
import { getCampaignTypeLabel } from '@/utils/lockConfig'
import TokenLogo from '@/components/token/TokenLogo.vue'
import MetricCard from '@/components/token/MetricCard.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import VestingChart from '@/components/distribution/VestingChart.vue'
import ContractBalanceStatus from '@/components/distribution/ContractBalanceStatus.vue'
import VueApexCharts from 'vue3-apexcharts'
import ProgressBar from '@/components/common/ProgressBar.vue'
import DistributionCountdown from '@/components/distribution/DistributionCountdown.vue'
import CampaignTimeline from '@/components/campaign/CampaignTimeline.vue'
import ContractStatus from '@/components/distribution/ContractStatus.vue'
import type { DistributionDetails, DistributionStats } from '@/types/distribution'
import type { CampaignTimeline as CampaignTimelineType } from '@/types/campaignPhase'
import { detectCampaignPhase, getPhaseConfig } from '@/utils/campaignPhase'
import { CampaignPhase } from '@/types/campaignPhase'
import { BackendUtils } from '@/utils/backend'
import { getVariantKey, shortPrincipal, getFirstLetter } from '@/utils/common'
import { 
  getDistributionStatusColor,
  getDistributionStatusDotColor,
  getDistributionStatusText
} from '@/utils/distribution'
import { cyclesToT } from '@/utils/common'
import { parseTokenAmount } from '@/utils/token'
import { formatDate } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'
import { useTheme } from '@/components/layout/ThemeProvider.vue'

const route = useRoute()
const router = useRouter()
const { isDarkMode } = useTheme() as { isDarkMode: any, toggleTheme: () => void }
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
  
  if ('Single' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Single.duration)
    const durationMs = durationNanos / 1_000_000
    
    // If duration is 0, it means permanently locked (no unlock date)
    if (durationMs === 0) return null
    
    return new Date(startTimestamp + durationMs)
  }
  
  if ('Linear' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Linear.duration)
    const durationMs = durationNanos / 1_000_000
    
    // If duration is 0, it means permanently locked (no unlock date)
    if (durationMs === 0) return null
    
    return new Date(startTimestamp + durationMs)
  }
  
  if ('Cliff' in details.value.vestingSchedule) {
    const cliffConfig = details.value.vestingSchedule.Cliff
    const cliffDurationNanos = Number(cliffConfig.cliffDuration)
    const cliffDurationMs = cliffDurationNanos / 1_000_000
    const vestingDurationNanos = Number(cliffConfig.vestingDuration)
    const vestingDurationMs = vestingDurationNanos / 1_000_000
    
    // Total duration is cliff period + vesting period
    const totalDurationMs = cliffDurationMs + vestingDurationMs
    
    // If total duration is 0, it means permanently locked (no unlock date)
    if (totalDurationMs === 0) return null
    
    return new Date(startTimestamp + totalDurationMs)
  }
  
  return null
})

const initialUnlockPercentage = computed(() => {
  return details.value?.initialUnlockPercentage ? Number(details.value.initialUnlockPercentage) : 0
})

const vestingFrequency = computed(() => {
  if (!details.value?.vestingSchedule) return 'Unknown'
  
  if ('Single' in details.value.vestingSchedule) {
    return 'Single Unlock'
  }
  
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
      type: 'buffer' as const
    })
    
    // Initial unlock - Handle Instant case
    if (initialUnlock > 0) {
      cumulativeAmount = initialAmount
      schedule.push({
        date: new Date(startTimestamp),
        amount: initialAmount,
        cumulative: cumulativeAmount,
        percentage: initialUnlock,
        type: initialUnlock === 100 ? ('instant' as const) : ('initial' as const)
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
      type: 'buffer' as const
    })
    
    return schedule
  }
  
  if ('Cliff' in details.value.vestingSchedule) {
    const cliffConfig = details.value.vestingSchedule.Cliff
    const cliffDurationNanos = Number(cliffConfig.cliffDuration)
    const cliffDurationMs = cliffDurationNanos / 1_000_000
    const vestingDurationNanos = Number(cliffConfig.vestingDuration)
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
      type: 'buffer' as const
    })
    
    // Initial unlock - Handle Instant case  
    if (initialAmount > 0) {
      cumulativeAmount = initialAmount
      schedule.push({
        date: new Date(startTimestamp),
        amount: initialAmount,
        cumulative: cumulativeAmount,
        percentage: initialUnlock,
        type: initialUnlock === 100 ? ('instant' as const) : ('initial' as const)
      })
    }
    
    // Cliff period (flat line)
    schedule.push({
      date: new Date(cliffEndTimestamp),
      amount: cliffAmount,
      cumulative: cumulativeAmount + cliffAmount,
      percentage: ((cumulativeAmount + cliffAmount) / totalAmount) * 100,
      type: 'cliff' as const
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
      type: 'buffer' as const
    })
    
    return schedule
  }
  
  return []
})

// Utility functions
const formatNumber = (value: number) => {
  return new Intl.NumberFormat().format(value)
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
      date: formatDate(new Date(), { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric' }),
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

// Handle actions from ContractStatus component
const handleStatusAction = async (actionKey: string) => {
  switch (actionKey) {
    case 'check-eligibility':
      await checkEligibility()
      break
    case 'register':
      await registerForCampaign()
      break
    case 'claim':
      await claimTokens()
      break
    default:
      console.warn('Unknown action:', actionKey)
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
  return formatDate(new Date(Number(details.value.distributionStart) / 1_000_000), { 
    year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric'
  })
})

const endDate = computed(() => {
  if (!details.value?.distributionEnd || details.value.distributionEnd.length === 0) {
    return vestingEndDate.value ? formatDate(vestingEndDate.value, { 
      year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric'
    }) : 'Not set'
  }
  return formatDate(new Date(Number(details.value.distributionEnd) / 1_000_000), { 
    year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric'
  })
})

const maxRecipients = computed(() => {
  // For Whitelist campaigns, show actual number of whitelisted addresses
  if (details.value?.eligibilityType && getVariantKey(details.value.eligibilityType) === 'Whitelist') {
    const recipientCount = participants.value?.length || 0
    if (recipientCount > 0) {
      return `${formatNumber(recipientCount)} Whitelisted`
    }
    return 'Whitelisted'
  }
  
  // For other campaigns, show maxRecipients limit
  if (!details.value?.maxRecipients || details.value.maxRecipients.length === 0) return 'Unlimited'
  return formatNumber(Number(details.value.maxRecipients[0]))
})

const registrationPeriod = computed(() => {
  if (!details.value?.registrationPeriod || details.value.registrationPeriod.length === 0) return null
  
  const regPeriod = details.value.registrationPeriod[0]
  const start = new Date(Number(regPeriod.startTime) / 1_000_000)
  const end = new Date(Number(regPeriod.endTime) / 1_000_000)
  
  return {
    start: formatDate(start, { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric' }),
    end: formatDate(end, { year: 'numeric', month: 'short', day: 'numeric', hour: 'numeric', minute: 'numeric' }),
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

// Campaign Timeline Logic
const campaignTimeline = computed((): CampaignTimelineType => {
  if (!details.value) {
    return {
      hasRegistration: false,
      distributionStart: undefined,
      distributionEnd: undefined
    }
  }

  // Check if registration is required: SelfService mode AND has registration period configured
  const isSelfService = details.value.recipientMode && 'SelfService' in details.value.recipientMode
  const hasRegistrationPeriod = details.value.registrationPeriod && details.value.registrationPeriod.length > 0
  const hasRegistration = isSelfService && hasRegistrationPeriod

  const regPeriod = details.value.registrationPeriod
  
  // Handle distributionEnd properly
  let distributionEnd: Date | undefined
  const campaignType = getVariantKey(details.value.campaignType)
  
  if (campaignType === 'Lock') {
    // For Lock campaigns, ALWAYS use vesting schedule duration (durationLock + cliff)
    distributionEnd = vestingEndDate.value || undefined
  } else {
    // For other campaigns, use explicit distributionEnd or fall back to vesting schedule
    if (details.value.distributionEnd && details.value.distributionEnd.length > 0) {
      // Explicit end time provided
      distributionEnd = new Date(Number(details.value.distributionEnd[0]) / 1_000_000)
    } else if (vestingEndDate.value) {
      // Calculate from vesting schedule if available
      distributionEnd = vestingEndDate.value
    }
    // If both are null/undefined, it's permanently active (distributionEnd = undefined)
  }
  
  return {
    hasRegistration,
    registrationStart: hasRegistration && regPeriod && regPeriod.length > 0 && regPeriod[0] ? 
      new Date(Number(regPeriod[0].startTime) / 1_000_000) : undefined,
    registrationEnd: hasRegistration && regPeriod && regPeriod.length > 0 && regPeriod[0] ? 
      new Date(Number(regPeriod[0].endTime) / 1_000_000) : undefined,
    distributionStart: distributionStartDate.value || undefined,
    distributionEnd
  }
})

const phaseInfo = computed(() => detectCampaignPhase(campaignTimeline.value))
const currentPhaseConfig = computed(() => getPhaseConfig(phaseInfo.value.currentPhase))

// Phase-based countdown logic
const showPhaseCountdown = computed(() => {
  return phaseInfo.value.timeToNextPhase > 0 && phaseInfo.value.nextPhase !== undefined
})

const phaseCountdownTime = computed(() => phaseInfo.value.timeToNextPhase)

const phaseCountdownLabel = computed(() => {
  const nextPhase = phaseInfo.value.nextPhase
  if (!nextPhase) return ''
  
  switch (nextPhase) {
    case CampaignPhase.REGISTRATION_OPEN:
      return 'Registration starts in:'
    case CampaignPhase.REGISTRATION_CLOSED:
      return 'Registration ends in:'
    case CampaignPhase.DISTRIBUTION_LIVE:
      return 'Distribution starts in:'
    case CampaignPhase.DISTRIBUTION_ENDED:
      return 'Distribution ends in:'
    default:
      return 'Next phase in:'
  }
})

// Convert phase info to status string for DistributionCountdown component
const countdownStatus = computed(() => {
  const currentPhase = phaseInfo.value.currentPhase
  const campaignType = details.value?.campaignType
  
  // Handle Lock campaign special status labels
  if (campaignType && getVariantKey(campaignType) === 'Lock') {
    switch (currentPhase) {
      case CampaignPhase.CREATED:
        return 'Created'
      case CampaignPhase.REGISTRATION_OPEN:
        return 'Registration Open'
      case CampaignPhase.REGISTRATION_CLOSED:
        return 'Registration Closed'
      case CampaignPhase.DISTRIBUTION_LIVE:
        return 'Locked'
      case CampaignPhase.DISTRIBUTION_ENDED:
        return 'Unlocked'
      default:
        return 'Unknown'
    }
  }
  
  // Handle regular campaign status labels
  switch (currentPhase) {
    case CampaignPhase.CREATED:
      return 'Created'
    case CampaignPhase.REGISTRATION_OPEN:
      return 'Active'
    case CampaignPhase.REGISTRATION_CLOSED:
      return 'Registration Closed'
    case CampaignPhase.DISTRIBUTION_LIVE:
      return 'Active'
    case CampaignPhase.DISTRIBUTION_ENDED:
      return 'Completed'
    default:
      return 'Unknown'
  }
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

// Enhanced status logic for three states: Eligible/Registered/Withdrawn
const userStatus = computed(() => {
  if (!userContext.value) return { type: 'unknown', label: 'Unknown', description: 'Status unavailable' }
  
  const isRegistered = userContext.value.isRegistered
  const isEligible = userContext.value.isEligible
  const allocation = Number(userAllocation.value)
  const claimed = Number(alreadyClaimed.value)
  const campaignType = details.value?.campaignType ? getVariantKey(details.value.campaignType) : null
  
  // Calculate withdrawal/claim completion percentage
  const completionPercentage = allocation > 0 ? (claimed / allocation) * 100 : 0
  
  // Check if fully withdrawn/claimed (>=95% to account for rounding)
  const isFullyWithdrawn = completionPercentage >= 95
  
  if (isFullyWithdrawn && (isRegistered || isEligible)) {
    return {
      type: 'withdrawn',
      label: campaignType === 'Lock' ? 'Withdrawn' : 'Completed',
      description: campaignType === 'Lock' 
        ? 'You have withdrawn all available tokens' 
        : 'You have claimed all available tokens'
    }
  }
  
  if (isRegistered) {
    return {
      type: 'registered',
      label: 'Registered',
      description: campaignType === 'Lock' 
        ? 'You are registered and can withdraw tokens when unlocked' 
        : 'You are registered and can claim tokens when available'
    }
  }
  
  if (isEligible) {
    return {
      type: 'eligible', 
      label: 'Eligible',
      description: 'You are eligible to participate in this distribution'
    }
  }
  
  return {
    type: 'ineligible',
    label: 'Not Eligible', 
    description: 'You are not eligible for this distribution'
  }
})

// Status styling configuration
const statusStyles = computed(() => {
  const status = userStatus.value.type
  
  switch (status) {
    case 'eligible':
      return {
        container: 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-700',
        icon: 'text-blue-600 dark:text-blue-400',
        title: 'text-blue-800 dark:text-blue-200',
        description: 'text-blue-600 dark:text-blue-300',
        iconBg: 'bg-blue-100 dark:bg-blue-900'
      }
    case 'registered':
      return {
        container: 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-700',
        icon: 'text-green-600 dark:text-green-400',
        title: 'text-green-800 dark:text-green-200', 
        description: 'text-green-600 dark:text-green-300',
        iconBg: 'bg-green-100 dark:bg-green-900'
      }
    case 'withdrawn':
      return {
        container: 'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-700',
        icon: 'text-amber-600 dark:text-amber-400',
        title: 'text-amber-800 dark:text-amber-200',
        description: 'text-amber-600 dark:text-amber-300',
        iconBg: 'bg-amber-100 dark:bg-amber-900'
      }
    default: // ineligible/unknown
      return {
        container: 'bg-gray-50 dark:bg-gray-700/50 border-gray-200 dark:border-gray-600',
        icon: 'text-gray-500 dark:text-gray-400',
        title: 'text-gray-800 dark:text-gray-200',
        description: 'text-gray-600 dark:text-gray-300',
        iconBg: 'bg-gray-100 dark:bg-gray-700'
      }
  }
})

// Status icon component
const statusIcon = computed(() => {
  const status = userStatus.value.type
  
  switch (status) {
    case 'eligible':
      return ShieldCheckIcon
    case 'registered': 
      return CheckCircleIcon
    case 'withdrawn':
      return CoinsIcon
    default:
      return XCircleIcon
  }
})

// Claims Timeline Data - Enhanced with vesting schedule integration
const claimTimelineData = computed(() => {
  const series = []
  
  // Actual Claims Series (if we have claim history)
  if (claimHistory.value.length > 0) {
    // Group claims by day
    const claimsByDay = new Map()
    claimHistory.value.forEach(claim => {
      const day = new Date(Number(claim.timestamp) / 1_000_000).toDateString()
      if (!claimsByDay.has(day)) {
        claimsByDay.set(day, { total: 0, count: 0 })
      }
      claimsByDay.get(day).total += parseTokenAmount(claim.amount, details.value?.tokenInfo.decimals || 8).toNumber()
      claimsByDay.get(day).count += 1
    })
    
    const actualClaimsData = Array.from(claimsByDay.entries())
      .sort((a, b) => new Date(a[0]).getTime() - new Date(b[0]).getTime())
      .map(([day, stats]) => ({
        x: new Date(day).getTime(),
        y: stats.total
      }))
    
    series.push({
      name: 'Actual Claims',
      type: 'column',
      data: actualClaimsData
    })
  }
  
  // Expected Claims Series (based on vesting schedule)
  if (vestingScheduleData.value.length > 0 && details.value) {
    const totalAmount = Number(details.value.totalAmount)
    const expectedClaimsData = vestingScheduleData.value
      .filter(point => point.type !== 'buffer')
      .map(point => ({
        x: point.date.getTime(),
        y: (point.amount / totalAmount) * totalAmount // Normalize to actual amounts
      }))
    
    series.push({
      name: 'Expected Unlocks',
      type: 'line',
      data: expectedClaimsData
    })
  }
  
  // If no data available, return empty array
  return series.length > 0 ? series : []
})

const claimTimelineOptions = computed(() => ({
  chart: {
    height: 350,
    type: 'line' as const,
    stacked: false,
    background: 'transparent',
    toolbar: {
      show: true,
      tools: {
        download: true,
        selection: false,
        zoom: true,
        zoomin: true,
        zoomout: true,
        pan: true,
        reset: true
      }
    },
    zoom: {
      enabled: true,
      type: 'x' as const,
      autoScaleYaxis: true
    },
    animations: {
      enabled: true,
      easing: 'easeinout',
      speed: 800
    }
  },
  stroke: {
    width: [0, 2], // Column width 0, line width 2
    curve: 'smooth' as const
  },
  colors: ['#3B82F6', '#10B981'], // Blue for actual claims, green for expected
  fill: {
    opacity: [0.85, 0.25],
    gradient: {
      shade: isDarkMode.value ? 'dark' : 'light',
      type: 'vertical',
      shadeIntensity: 0.4,
      gradientToColors: ['#93C5FD', '#6EE7B7'],
      inverseColors: false,
      opacityFrom: [0.85, 0.25],
      opacityTo: [0.6, 0.05]
    }
  },
  plotOptions: {
    bar: {
      columnWidth: '50%'
    }
  },
  xaxis: {
    type: 'datetime' as const,
    labels: {
      format: 'MMM dd',
      style: {
        colors: isDarkMode.value ? '#9CA3AF' : '#6B7280'
      }
    },
    axisBorder: {
      color: isDarkMode.value ? '#374151' : '#E5E7EB'
    },
    axisTicks: {
      color: isDarkMode.value ? '#374151' : '#E5E7EB'
    }
  },
  yaxis: {
    labels: {
      formatter: (value: number) => `${formatNumber(value)} ${details.value?.tokenInfo.symbol || 'TOKENS'}`,
      style: {
        colors: isDarkMode.value ? '#9CA3AF' : '#6B7280'
      }
    },
    axisBorder: {
      color: isDarkMode.value ? '#374151' : '#E5E7EB'
    }
  },
  grid: {
    borderColor: isDarkMode.value ? '#374151' : '#E5E7EB',
    strokeDashArray: 3
  },
  tooltip: {
    theme: isDarkMode.value ? 'dark' : 'light',
    shared: true,
    intersect: false,
    x: {
      format: 'MMM dd, yyyy'
    },
    y: {
      formatter: (value: number) => `${formatNumber(value)} ${details.value?.tokenInfo.symbol || 'TOKENS'}`
    }
  },
  legend: {
    show: true,
    position: 'top' as const,
    horizontalAlign: 'left' as const,
    labels: {
      colors: isDarkMode.value ? '#F3F4F6' : '#1F2937'
    }
  },
  dataLabels: {
    enabled: false
  }
}))

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