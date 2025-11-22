<template>
  <AdminLayout>
    <div class="distribution-detail min-h-screen">
      <!-- Breadcrumb Navigation -->
      <Breadcrumb :items="breadcrumbItems" />

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
        <!-- ============================================ -->
        <!-- CAMPAIGN HEADER (ORIGINAL HEADER BLOCK) -->
        <!-- ============================================ -->
        <div class="flex items-center justify-between">
          <div class="flex items-center space-x-4">
            <TokenLogo :canister-id="details?.tokenInfo?.canisterId?.toString() || ''"
              :symbol="details?.tokenInfo?.symbol || 'TOKEN'" :size="64" />
            <div>
              <h4 class="text-xl font-bold text-gray-900 dark:text-white">
                {{ details.title }}
              </h4>
              <div class="flex items-center space-x-4">
                <p class="flex items-center gap-1 text-sm text-gray-500 dark:text-gray-400">{{ canisterId }}
                  <CopyIcon class="w-3.5 h-3.5" :data="canisterId?.toString()" />
                </p>
                <Label variant="gray" size="xs">{{ cyclesToT(canisterCycles) }}</Label>
                <!-- NEW: Unified Status Badge with Balance Validation -->
                <DistributionStatusBadge :distribution="details" :contract-balance="contractBalance"
                  :show-sub-status="true" />
                <!-- Campaign Visibility Type (Public/Private) -->
                <Label variant="blue" class="inline-flex items-center gap-1">
                  <GlobeIcon v-if="getVariantKey(details.eligibilityType) === 'Public'" class="w-3.5 h-3.5 mr-1" />
                  <LockIcon v-else class="w-3.5 h-3.5 mr-1" />
                  {{ getVariantKey(details.eligibilityType) === 'Public' ? 'Open' : 'Private' }}
                </Label>
                <!-- Campaign Type Label (Airdrop/Vesting/Lock) -->
                <div :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').bgClass"
                  class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border">
                  <div class="w-2 h-2 rounded-full mr-2"
                    :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').className.replace('text-', 'bg-')">
                  </div>
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

            <!-- Refresh Button - Always visible -->
            <button @click="refreshData" :disabled="refreshing"
              class="inline-flex text-sm items-center px-4 py-2 border border-gray-300 rounded-lg shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 dark:bg-gray-800 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-700 transition-colors duration-200 disabled:opacity-50">
              <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
              {{ refreshing ? 'Refreshing...' : 'Refresh' }}
            </button>
          </div>
        </div>

        <!-- ============================================ -->
        <!-- LAUNCHPAD CONTEXT (IF FROM LAUNCHPAD) -->
        <!-- ============================================ -->
        <LaunchpadInfo v-if="details.launchpadContext && details.launchpadContext.length > 0"
          :launchpad-context="{
            launchpadId: details.launchpadContext[0].launchpadId,
            category: details.launchpadContext[0].category,
            projectMetadata: details.launchpadContext[0].projectMetadata,
            batchId: details.launchpadContext[0].batchId
          }"
          :token-info="details.tokenInfo"
          @view-launchpad="navigateToLaunchpad(details.launchpadContext[0].launchpadId)"
          @view-token="navigateToToken(details.tokenInfo.canisterId)"
          class="mb-6"
        />

        <!-- ============================================ -->
        <!-- DESCRIPTION SECTION (ORIGINAL WITH COUNTDOWN) -->
        <!-- ============================================ -->
        <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700" v-else>
          <div class="flex items-center justify-between mb-3">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">About This Campaign</h3>
            <!-- Countdown Component -->
            <DistributionCountdown :start-time="details.distributionStart"
              :end-time="details.distributionEnd && details.distributionEnd.length > 0 ? details.distributionEnd[0] : null"
              :status="countdownStatus" @countdown-end="handleCountdownEnd" />
          </div>
          <p class="text-gray-600 dark:text-gray-300 leading-relaxed">{{ details.description }}</p>
        </div>

        <!-- ============================================ -->
        <!-- CONTRACT BALANCE (OWNER ONLY - KEEP AS-IS but move up) -->
        <!-- ============================================ -->
        <ContractBalanceStatus v-if="details && isOwner" :contract-id="canisterId" :current-balance="contractBalance"
          :required-amount="details.totalAmount" :token-symbol="details?.tokenInfo?.symbol || 'TOKEN'"
          :token-decimals="details?.tokenInfo?.decimals || 8" :contract-status="composableStatus"
          :distribution-start="details.distributionStart" :refreshing="checkingBalance" :needs-funding="needsFunding"
          @refresh="checkBalance" @initial-check="checkBalance" @fund="showFundModal = true" />

        <!-- ============================================ -->
        <!-- MAIN GRID (2/3 + 1/3) -->
        <!-- ============================================ -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">

          <!-- ============================================ -->
          <!-- LEFT COLUMN (2/3) -->
          <!-- ============================================ -->
          <div class="lg:col-span-2 space-y-8">

            <!-- Categories Section (Tab Navigation) -->
            <div v-if="categoryData.length > 0" class="space-y-4">
              <!-- Tab Navigation -->
              <CategoryTabNavigation :categories="categoryData" v-model:active-tab="activeCategoryTab"
                :show-all-tab="true" />

              <!-- All Categories Overview -->
              <div v-if="activeCategoryTab === 'all'">
                <AllCategoriesOverview :categories="categoryData" :token-symbol="details?.tokenInfo?.symbol || 'TOKEN'"
                  :token-decimals="details?.tokenInfo?.decimals || 8"
                  @navigate-to-category="handleNavigateToCategory" />
              </div>

              <!-- Individual Category Detail -->
              <div v-else-if="selectedCategory">
                <CategoryDetailsCard :key="selectedCategory.categoryId?.toString() || selectedCategory.name"
                  :id="`category-${selectedCategory.categoryId?.toString()}`" :category="selectedCategory"
                  :participants="selectedCategory.participants" :token-symbol="details?.tokenInfo?.symbol || 'TOKEN'"
                  :token-decimals="details?.tokenInfo?.decimals || 8" :total-categories="categoryData.length"
                  :claim-history="claimHistory" :refreshing="refreshing"
                  :user-status="categoriesWithStatus[selectedCategoryIndex] ? {
                    status: categoriesWithStatus[selectedCategoryIndex].userStatus,
                    canRegister: categoriesWithStatus[selectedCategoryIndex].canRegister,
                    canClaim: categoriesWithStatus[selectedCategoryIndex].canClaim,
                    claimableAmount: categoriesWithStatus[selectedCategoryIndex].claimableAmount,
                    eligibleAmount: categoriesWithStatus[selectedCategoryIndex].eligibleAmount,
                    claimedAmount: categoriesWithStatus[selectedCategoryIndex].claimedAmount,
                    isRegistered: categoriesWithStatus[selectedCategoryIndex].isRegistered
                  } : undefined" 
                  :is-authenticated="authStore.isConnected"
                  :processing="registering || claiming" @refresh-participants="fetchAllParticipants"
                  @register="handleCategoryRegister" @claim="handleCategoryClaim" />
              </div>
            </div>

            <!-- Fallback: Global Recipients & Transactions (if no categories) -->
            <div v-else
              class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
              <!-- Tab Headers -->
              <div class="flex items-center justify-between mb-6">
                <div class="flex space-x-1 bg-gray-100 dark:bg-gray-700 p-1 rounded-lg">
                  <button @click="activeTab = 'recipients'" :class="[
                    'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200',
                    activeTab === 'recipients'
                      ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-sm'
                      : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                  ]">
                    <UsersIcon class="w-4 h-4 mr-2 inline" />
                    Recipients
                  </button>
                  <button @click="activeTab = 'transactions'" :class="[
                    'px-4 py-2 text-sm font-medium rounded-md transition-colors duration-200',
                    activeTab === 'transactions'
                      ? 'bg-white dark:bg-gray-800 text-gray-900 dark:text-white shadow-sm'
                      : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                  ]">
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
                        <th class="text-left py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Address
                        </th>
                        <th class="text-right py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Amount
                        </th>
                        <th class="text-right py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Claimed
                        </th>
                        <th class="text-left py-3 px-4 font-medium text-gray-500 dark:text-gray-400 text-sm">Note</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="recipient in participants" :key="recipient.address"
                        class="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200">
                        <td class="py-4 px-4">
                          <div class="flex items-center space-x-3">
                            <div
                              class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                              <span class="text-white text-xs font-medium">
                                {{ getFirstLetter(recipient.principal) }}
                              </span>
                            </div>
                            <div>
                              <p class="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-1"
                                :title="recipient.principal">
                                {{ shortPrincipal(recipient.principal) }}
                                <CopyIcon :data="recipient?.principal?.toString()" class="w-4 h-4 cursor-pointer" />
                              </p>
                            </div>
                          </div>
                        </td>
                        <td class="py-4 px-4 text-right">
                          <span class="font-semibold text-gray-900 dark:text-white">
                            {{ formatNumber(parseTokenAmount(recipient.eligibleAmount,
                              details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                          </span>
                        </td>
                        <td class="py-4 px-4 text-right">
                          <span class="text-gray-500 dark:text-gray-400">
                            {{ formatNumber(parseTokenAmount(recipient.claimedAmount,
                              details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                          </span>
                        </td>
                        <td class="py-4 px-4">
                          <span v-if="recipient.note && recipient.note.length > 0"
                            class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
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
                    <tr v-for="claim in claimHistory" :key="claim.id"
                      class="border-b border-gray-100 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors duration-200">
                      <td class="py-4 px-4">
                        <div class="flex items-center space-x-3">
                          <div
                            class="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                            <span class="text-white text-xs font-medium">
                              {{ getFirstLetter(claim.participant) }}
                            </span>
                          </div>
                          <div>
                            <p class="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-1"
                              :title="claim.participant">
                              {{ shortPrincipal(claim.participant) }}
                              <CopyIcon :data="claim.participant?.toString()" class="w-4 h-4 cursor-pointer" />
                            </p>
                          </div>
                        </div>
                      </td>
                      <td class="py-4 px-4 text-right">
                        <span class="font-semibold text-gray-900 dark:text-white">
                          {{ formatNumber(parseTokenAmount(claim.amount, details.tokenInfo.decimals).toNumber()) }} {{
                            details.tokenInfo.symbol }}
                        </span>
                      </td>
                      <td class="py-4 px-4 text-right">
                        <span class="text-gray-500 dark:text-gray-400">
                          {{ formatNumber(parseTokenAmount(claim.amount, details.tokenInfo.decimals).toNumber()) }} {{
                            details.tokenInfo.symbol }}
                        </span>
                      </td>
                      <td class="py-2 px-2">
                        <span v-if="claim.transactionId"
                          class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300">
                          #{{ claim.transactionId.length > 0 ? claim.transactionId[0] : 'N/A' }}
                        </span>
                        <span v-else class="text-gray-400 text-xs">—</span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

            </div>
            <!-- Lock Detail (for Lock campaigns) -->
            <div v-if="getVariantKey(details.campaignType) === 'Lock'" class="">
              <LockDetail
                :campaign="{ id: distributionId, creator: details?.owner?.toText() || '', config: details as any }" />
            </div>

            <!-- Vesting Schedule Chart -->
            <div v-else-if="vestingScheduleData.length > 0"
              class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
              <div class="flex items-center justify-between mb-8">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                    Token Unlock Schedule
                    <Label size="sm" variant="gray">
                      {{ vestingFrequency }}
                    </Label>
                  </h2>
                  <p class="text-gray-600 dark:text-gray-400">Token unlock timeline and distribution pattern</p>
                </div>
              </div>

              <VestingChart :vesting-data="vestingScheduleData" :has-cliff-period="hasCliffPeriod"
                :has-instant-unlock="hasInstantUnlock" :current-time-position="currentTimePosition"
                :cliff-end-position="cliffEndPosition" />

              <!-- Legend -->
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

            <!-- ============================================ -->
            <!-- CAMPAIGN ANALYTICS & DETAILS SECTION -->
            <!-- ============================================ -->
            <div class="space-y-8">
              <!-- Campaign Details Component -->
              <DistributionCampaignDetails :details="details" :stats="stats" :token-symbol="details.tokenInfo.symbol"
                :token-decimals="details.tokenInfo.decimals" />

              <!-- Campaign Stats Grid -->
              <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
                <!-- Show countdown in first card if needed -->
                <div v-if="showPhaseCountdown"
                  class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
                  <div class="flex items-center space-x-2 mb-2">
                    <ClockIcon class="h-5 w-5 text-gray-400 dark:text-gray-500" />
                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Next Phase</h3>
                  </div>
                  <vue-countdown :time="phaseCountdownTime" v-slot="{ days, hours, minutes, seconds }"
                    class="text-brand-600 dark:text-brand-400 font-semibold">
                    <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">{{ phaseCountdownLabel }}</div>
                    <div class="text-sm font-bold">{{ days }}d {{ hours }}h {{ minutes }}m {{ seconds }}s</div>
                  </vue-countdown>
                </div>

                <!-- Other metric cards -->
                <MetricCard v-if="campaignTimeline.hasRegistration && getVariantKey(details.campaignType) !== 'Lock'"
                  title="Registration" :value="phaseInfo.currentPhase === 'registration_open' ? 'Open Now' :
                    phaseInfo.currentPhase === 'registration_closed' ? 'Closed' :
                      'Not Started'" icon="ShieldCheckIcon" size="sm" />

                <MetricCard title="Max Recipients" :value="maxRecipients" icon="UserPlusIcon" size="sm" />

                <MetricCard title="Campaign Type"
                  :value="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').label" icon="ZapIcon"
                  size="sm" />
              </div>

              <!-- Claims Timeline -->
              <div v-if="getVariantKey(details.campaignType) !== 'Lock'"
                class="bg-white dark:bg-gray-800 rounded-2xl shadow-sm p-8 border border-gray-100 dark:border-gray-700">
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
                  <VueApexCharts v-if="claimTimelineData.length > 0" type="area" height="320"
                    :options="claimTimelineOptions" :series="claimTimelineData" />
                  <div v-else class="flex flex-col items-center justify-center h-full">
                    <div class="w-16 h-16 text-gray-300 dark:text-gray-600 mb-4">
                      <BarChart3Icon class="w-full h-full" />
                    </div>
                    <p class="text-gray-500 dark:text-gray-400 font-medium">No claims data available</p>
                    <p class="text-sm text-gray-400 dark:text-gray-500 mt-1">Claims will appear here once users start
                      claiming tokens</p>
                  </div>
                </div>
              </div>
            </div>


          </div>

          <!-- ============================================ -->
          <!-- RIGHT COLUMN (1/3) -->
          <!-- ============================================ -->
          <div class="space-y-6">

            <!-- ============================================ -->
            <!-- CATEGORY STATUS SIDEBAR (MULTI-CATEGORY ONLY) -->
            <!-- ============================================ -->
            <DistributionCategoryStatus v-if="categoryData.length > 0" :categories="categoryData"
              :user-context="userContext" :is-authenticated="authStore.isConnected" :processing="registering || claiming"
              :active-category="activeCategoryTab === 'all' ? undefined : activeCategoryTab"
              :distribution-start="details?.distributionStart"
              @register-all="handleBatchRegister" @claim-all="handleBatchClaim"
              @scroll-to-category="handleNavigateToCategory" />

            <!-- ============================================ -->
            <!-- USER ALLOCATION (LEGACY - For non-category or single category) -->
            <!-- ============================================ -->
            <DistributionUserAllocation v-else :user-context="userContext" :user-allocation="userAllocation"
              :available-to-claim="availableToClaim" :already-claimed="alreadyClaimed"
              :token-symbol="details.tokenInfo.symbol" :token-decimals="details.tokenInfo.decimals"
              :eligibility-loading="eligibilityLoading" :eligibility-status="eligibilityStatus"
              :registering="registering" :claiming="claiming"
              :campaign-type="getVariantKey(details.campaignType) || 'Airdrop'"
              :is-authenticated="authStore.isConnected" @check-eligibility="checkEligibility"
              @register="registerForCampaign" @claim="claimTokens" />

            <!-- ============================================ -->
            <!-- ACTION CARD (NEW COMPONENT) -->
            <!-- ============================================ -->
            <DistributionActionCard :details="details" :stats="stats" :is-owner="isOwner"
              :is-authenticated="authStore.isConnected" :canister-id="canisterId" :user-allocation="userAllocation"
              :refreshing="refreshing" :auto-refresh-enabled="autoRefreshEnabled" :contract-version="contractVersion"
              @refresh="refreshData" @toggle-auto-refresh="toggleAutoRefresh" />

            <!-- ============================================ -->
            <!-- TIMELINE (NEW COMPONENT) -->
            <!-- ============================================ -->
            <DistributionTimeline :distribution="details" @countdown-end="refreshData" />
          </div>
        </div>
      </div>
    </div>

    <!-- ============================================ -->
    <!-- CLAIM MODAL (KEEP AS-IS) -->
    <!-- ============================================ -->
    <ClaimModal v-if="showClaimModal && claimInfo" :distribution-id="canisterId" :claim-info="claimInfo"
      :token-symbol="details?.tokenInfo.symbol || 'TOKEN'" :token-decimals="details?.tokenInfo.decimals || 8"
      @close="showClaimModal = false" @claimed="handleClaim" @refresh="refreshClaimInfo" />

    <!-- ============================================ -->
    <!-- FUND CONTRACT MODAL (NEW) -->
    <!-- ============================================ -->
    <FundContractModal v-if="details" :is-open="showFundModal" :contract-id="canisterId"
      :required-amount="details.totalAmount" :token-symbol="details?.tokenInfo?.symbol || 'TOKEN'"
      :token-decimals="details?.tokenInfo?.decimals || 8"
      :token-canister-id="details?.tokenInfo?.canisterId?.toString() || ''" @close="showFundModal = false"
      @success="handleFundSuccess" />

    <!-- ============================================ -->
    <!-- BATCH RESULT MODAL (NEW) -->
    <!-- ============================================ -->
    <BatchResultModal v-if="batchResult" :is-open="showBatchResultModal" :result="batchResult"
      :operation-type="batchOperationType" :token-symbol="details?.tokenInfo.symbol || 'TOKEN'"
      :token-decimals="details?.tokenInfo.decimals || 8" @close="showBatchResultModal = false" />

    <!-- ============================================ -->
    <!-- BATCH CONFIRM MODAL (NEW) -->
    <!-- ============================================ -->
    <BatchConfirmModal v-if="details" :is-open="showBatchConfirmModal" :operation-type="batchConfirmType"
              :categories="batchConfirmType === 'register' ? eligibleCategories : claimableCategories"
              :token-symbol="details.tokenInfo.symbol" :token-decimals="details.tokenInfo.decimals"
              :can-claim="userContext?.canClaim" :distribution-start="details.distributionStart"
              :initial-selected-ids="singleClaimCategory ? [singleClaimCategory.categoryId || singleClaimCategory.category?.id] : []"
              :loading="claiming || registering"
              @close="showBatchConfirmModal = false" @confirm="confirmBatchOperation" />
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { DistributionService } from '@/api/services/distribution'

// ============================================
// NEW IMPORTS (Components) - NO HERO COMPONENT
// ============================================
import DistributionActionCard from '@/components/distribution/DistributionActionCard.vue'
import DistributionUserAllocation from '@/components/distribution/DistributionUserAllocation.vue'
import DistributionCampaignDetails from '@/components/distribution/DistributionCampaignDetails.vue'
import DistributionTimeline from '@/components/distribution/DistributionTimeline.vue'
import DistributionStatusBadge from '@/components/distribution/DistributionStatusBadge.vue'
import DistributionCategoryStatus from '@/components/distribution/DistributionCategoryStatus.vue'
import CategoryTabNavigation from '@/components/distribution/CategoryTabNavigation.vue'
import AllCategoriesOverview from '@/components/distribution/AllCategoriesOverview.vue'

// ============================================
// NEW IMPORTS (Composable)
// ============================================
import { useDistributionStatus } from '@/composables/distribution/useDistributionStatus'
import { useCategoryStatus } from '@/composables/distribution/useCategoryStatus'

// ============================================
// EXISTING IMPORTS (KEEP ALL)
// ============================================
import AdminLayout from '@/components/layout/AdminLayout.vue'
import TokenLogo from '@/components/token/TokenLogo.vue'
import Label from '@/components/common/Label.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import LockDetail from '@/components/distribution/LockDetail.vue'
import MetricCard from '@/components/token/MetricCard.vue'
import VestingChart from '@/components/distribution/VestingChart.vue'
import ContractBalanceStatus from '@/components/distribution/ContractBalanceStatus.vue'
import FundContractModal from '@/components/distribution/FundContractModal.vue'
import VueApexCharts from 'vue3-apexcharts'
import ClaimModal from '@/components/distribution/ClaimModal.vue'
import BatchResultModal from '@/components/distribution/BatchResultModal.vue'
import BatchConfirmModal from '@/components/distribution/BatchConfirmModal.vue'
import CategoryDetailsCard from '@/components/distribution/CategoryDetailsCard.vue'
import LaunchpadInfo from '@/components/distribution/LaunchpadInfo.vue'
import VueCountdown from '@chenfengyuan/vue-countdown'
import DistributionCountdown from '@/components/distribution/DistributionCountdown.vue'
import type { DistributionDetails, DistributionStats, ClaimInfo } from '@/types/distribution'
import type { CampaignTimeline as CampaignTimelineType } from '@/types/campaignPhase'
import { detectCampaignPhase, getPhaseConfig } from '@/utils/campaignPhase'
import { CampaignPhase } from '@/types/campaignPhase'
import { getVariantKey, shortPrincipal, getFirstLetter, cyclesToT } from '@/utils/common'
import { getCampaignTypeLabel } from '@/utils/lockConfig'
import { parseTokenAmount, formatTokenAmount } from '@/utils/token'
import { formatDate } from '@/utils/dateFormat'
import { toast } from 'vue-sonner'
import { useTheme } from '@/components/layout/ThemeProvider.vue'
import { useAuthStore } from '@/stores/auth'
import {
  AlertCircleIcon,
  RefreshCwIcon,
  SettingsIcon,
  UsersIcon,
  ClockIcon,
  BarChart3Icon,
  FilterIcon,
  DownloadIcon,
  HistoryIcon,
  GlobeIcon,
  LockIcon,
} from 'lucide-vue-next'
import { CopyIcon } from '@/icons'

// ============================================
// SETUP
// ============================================
const props = defineProps<{
  canisterId: string
}>()

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const { isDarkMode } = useTheme() as { isDarkMode: any, toggleTheme: () => void }

// ============================================
// EXISTING STATE (KEEP ALL)
// ============================================
const loading = ref(true)
const error = ref<string | null>(null)
const details = ref<DistributionDetails | null>(null)
const stats = ref<DistributionStats | null>(null)
const claiming = ref(false)
const showClaimModal = ref(false)
const showFundModal = ref(false)  // ✅ NEW: Fund contract modal

// ============================================
// NEW STATE: Batch & Single Claim Confirmation
// ============================================
const singleClaimCategory = ref<any>(null)
const confirmModalMode = ref<'batch' | 'single'>('batch')

const confirmModalCategories = computed(() => {
  if (confirmModalMode.value === 'single' && singleClaimCategory.value) {
    return [singleClaimCategory.value]
  }
  return batchConfirmType.value === 'register' ? eligibleCategories.value : claimableCategories.value
})

// ============================================
// NEW STATE: Tab Navigation
// ============================================
const activeCategoryTab = ref('all')

const handleCategoryTabChange = (tabId: string) => {
  activeCategoryTab.value = tabId
}

const handleNavigateToCategory = (categoryId: string) => {
  activeCategoryTab.value = categoryId
  // Scroll to top of content area
  const contentArea = document.querySelector('.distribution-detail')
  if (contentArea) {
    contentArea.scrollIntoView({ behavior: 'smooth' })
  }
}

const selectedCategory = computed(() => {
  if (activeCategoryTab.value === 'all') return null
  return categoryData.value.find(c => (c.categoryId?.toString() || '') === activeCategoryTab.value)
})

const selectedCategoryIndex = computed(() => {
  if (activeCategoryTab.value === 'all') return -1
  return categoryData.value.findIndex(c => (c.categoryId?.toString() || '') === activeCategoryTab.value)
})
const claimInfo = ref<ClaimInfo | null>(null)
// Batch result modal state
const showBatchResultModal = ref(false)
const batchResult = ref<any>(null)
const batchOperationType = ref<'register' | 'claim'>('register')
const refreshing = ref(false)
const eligibilityLoading = ref(false)
const eligibilityStatus = ref(false)
const registering = ref(false)
const distributionStatus = ref<string>('')
const activeTab = ref('recipients')
const participants = ref<any[]>([])
const claimHistory = ref<any[]>([])
const canisterCycles = ref(0)
const contractBalance = ref(BigInt(0))
const checkingBalance = ref(false)

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

// User category breakdown (vesting-aware claimable amounts)
const userCategoryBreakdown = ref<Map<string, any>>(new Map())

// User data
const userAllocation = ref<bigint>(BigInt(0))
const availableToClaim = ref<bigint>(BigInt(0))
const alreadyClaimed = ref<bigint>(BigInt(0))

// Auto-refresh
const autoRefreshEnabled = ref(true)
const contractVersion = '1.0.0'

// ============================================
// NEW: CATEGORY STATUS & OPERATIONS
// ============================================
const activeCategoryId = ref<string | undefined>(undefined)
const showBatchConfirmModal = ref(false)
const batchConfirmType = ref<'register' | 'claim'>('register')

// ============================================
// NEW COMPOSABLE USAGE WITH BALANCE VALIDATION
// ============================================
const distributionRef = computed(() => details.value)
const {
  distributionStatus: composableStatus,
  statusInfo,
  timeline: statusTimeline,
  canRegister: canRegisterFromComposable,
  canClaim: canClaimFromComposable,
  canManage,
  needsFunding,
  isLive,
  isCreated,
  isRegistration,
  isEnded
} = useDistributionStatus(distributionRef, contractBalance)

// ============================================
// EXISTING COMPUTED (KEEP ALL)
// ============================================
const canisterId = computed(() => route.params.id as string)
const distributionId = computed(() => route.params.id as string)
const isOwner = computed(() => userContext.value?.isOwner ?? false)
const isRegistered = computed(() => userContext.value?.isRegistered ?? false)
const isEligible = computed(() => userContext.value?.isEligible ?? false)
const canRegisterFromContext = computed(() => userContext.value?.canRegister ?? false)
const canClaimFromContext = computed(() => userContext.value?.canClaim ?? false)

const canClaim = computed(() => {
  return canClaimFromContext.value && availableToClaim.value > 0
})

// Breadcrumb navigation
const breadcrumbItems = computed(() => [
  { label: 'Distributions', to: '/distribution' },
  { label: details.value?.title || 'Distribution Detail' }
])

// Computed properties for milestone dates
const distributionStartDate = computed(() => {
  if (!details.value?.distributionStart) return null
  const timestamp = Number(details.value.distributionStart) / 1_000_000
  return new Date(timestamp)
})

const vestingEndDate = computed(() => {
  if (!details.value?.distributionStart || !details.value?.vestingSchedule) return null

  const startTimestamp = Number(details.value.distributionStart) / 1_000_000

  if ('Single' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Single.duration)
    const durationMs = durationNanos / 1_000_000
    if (durationMs === 0) return null
    return new Date(startTimestamp + durationMs)
  }

  if ('Linear' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Linear.duration)
    const durationMs = durationNanos / 1_000_000
    if (durationMs === 0) return null
    return new Date(startTimestamp + durationMs)
  }

  if ('Cliff' in details.value.vestingSchedule) {
    const cliffConfig = details.value.vestingSchedule.Cliff
    const cliffDurationNanos = Number(cliffConfig.cliffDuration)
    const cliffDurationMs = cliffDurationNanos / 1_000_000
    const vestingDurationNanos = Number(cliffConfig.vestingDuration)
    const vestingDurationMs = vestingDurationNanos / 1_000_000
    const totalDurationMs = cliffDurationMs + vestingDurationMs
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
  const bufferMs = 2 * 24 * 60 * 60 * 1000 // 2 days

  if ('Linear' in details.value.vestingSchedule) {
    const durationNanos = Number(details.value.vestingSchedule.Linear.duration)
    const durationMs = durationNanos / 1_000_000
    const frequency = details.value.vestingSchedule.Linear.frequency

    let intervalMs = 0
    let periods = 0

    if ('Monthly' in frequency) {
      intervalMs = 30 * 24 * 60 * 60 * 1000
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

    schedule.push({
      date: new Date(startTimestamp - bufferMs),
      amount: 0,
      cumulative: 0,
      percentage: 0,
      type: 'buffer' as const
    })

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

    schedule.push({
      date: new Date(startTimestamp - bufferMs),
      amount: 0,
      cumulative: 0,
      percentage: 0,
      type: 'buffer' as const
    })

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

    schedule.push({
      date: new Date(cliffEndTimestamp),
      amount: cliffAmount,
      cumulative: cumulativeAmount + cliffAmount,
      percentage: ((cumulativeAmount + cliffAmount) / totalAmount) * 100,
      type: 'cliff' as const
    })

    cumulativeAmount += cliffAmount

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

// Additional metrics for cards
const maxRecipients = computed(() => {
  if (details.value?.eligibilityType && getVariantKey(details.value.eligibilityType) === 'Whitelist') {
    const recipientCount = participants.value?.length || 0
    if (recipientCount > 0) {
      return `${formatNumber(recipientCount)} Whitelisted`
    }
    return 'Whitelisted'
  }

  if (!details.value?.maxRecipients || details.value.maxRecipients.length === 0) return 'Unlimited'
  return formatNumber(Number(details.value.maxRecipients[0]))
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

  const isSelfService = details.value.recipientMode && 'SelfService' in details.value.recipientMode
  const hasRegistrationPeriod = details.value.registrationPeriod && details.value.registrationPeriod.length > 0
  const hasRegistration = isSelfService && hasRegistrationPeriod

  const regPeriod = details.value.registrationPeriod

  let distributionEnd: Date | undefined
  const campaignType = getVariantKey(details.value.campaignType)

  if (campaignType === 'Lock') {
    distributionEnd = vestingEndDate.value || undefined
  } else {
    if (details.value.distributionEnd && details.value.distributionEnd.length > 0) {
      distributionEnd = new Date(Number(details.value.distributionEnd[0]) / 1_000_000)
    } else if (vestingEndDate.value) {
      distributionEnd = vestingEndDate.value
    }
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

const countdownStatus = computed(() => {
  if (phaseInfo.value.currentPhase === CampaignPhase.REGISTRATION_OPEN) {
    return 'registration'
  } else if (phaseInfo.value.currentPhase === CampaignPhase.DISTRIBUTION_LIVE) {
    return 'distribution'
  } else if (phaseInfo.value.currentPhase === CampaignPhase.DISTRIBUTION_ENDED) {
    return 'ended'
  }
  return 'upcoming'
})

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

// Claims Timeline Data
const claimTimelineData = computed(() => {
  const series = []

  if (claimHistory.value.length > 0) {
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

  if (vestingScheduleData.value.length > 0 && details.value) {
    const totalAmount = Number(details.value.totalAmount)
    const expectedClaimsData = vestingScheduleData.value
      .filter(point => point.type !== 'buffer')
      .map(point => ({
        x: point.date.getTime(),
        y: (point.amount / totalAmount) * totalAmount
      }))

    series.push({
      name: 'Expected Unlocks',
      type: 'line',
      data: expectedClaimsData
    })
  }

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
    width: [0, 2],
    curve: 'smooth' as const
  },
  colors: ['#3B82F6', '#10B981'],
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

// ============================================
// CATEGORIES & PARTICIPANTS
// ============================================
const categories = computed(() => {
  // @ts-ignore - categories may not be in type definition yet
  const cats = details.value?.categories
  // Check if categories is an array or nested array
  if (!cats) {
    return []
  }

  // If categories is nested array like [[category1, category2]]
  if (Array.isArray(cats) && cats.length > 0 && Array.isArray(cats[0])) {
    return cats[0]
  }

  // Otherwise use as is
  return cats
})

// Organize participants by category
const participantsByCategory = computed(() => {
  if (!participants.value || participants.value.length === 0 || !categories.value || categories.value.length === 0) {
    return new Map()
  }

  const categoryMap = new Map<string, any[]>()

  // Initialize map with all categories
  categories.value.forEach((category: any) => {
    const categoryId = category.id?.toString() || category.categoryId?.toString()
    if (categoryId) {
      categoryMap.set(categoryId, [])
    }
  })

  // Distribute participants to their categories
  participants.value.forEach((participant: any) => {
    console.log('🔍 DEBUG - Processing participant:', participant.principal?.toString())
    console.log('🔍 DEBUG - Participant categories:', participant.categories)

    // ✅ FIX: Backend returns "categories" not "categoryAllocations"
    if (participant.categories && Array.isArray(participant.categories)) {
      participant.categories.forEach((category: any) => {
        const catId = category.categoryId.toString()

        // Robustly get amount and claimed amount (handle variations)
        const amount = category.amount !== undefined
          ? category.amount
          : (category.allocatedAmount !== undefined ? category.allocatedAmount : BigInt(0))

        const claimed = category.claimedAmount !== undefined
          ? category.claimedAmount
          : (category.claimed !== undefined ? category.claimed : BigInt(0))

        console.log(`🔍 DEBUG - Category ${catId}:`, {
          amount: amount,
          claimedAmount: claimed,
          rawCategory: category
        })

        if (categoryMap.has(catId)) {
          categoryMap.get(catId)!.push({
            principal: participant.principal,
            allocation: amount,
            claimed: claimed,
            note: category.note
          })
          console.log(`🔍 DEBUG - Added participant to category ${catId} with allocation: ${amount}`)
        } else {
          console.log(`🔍 DEBUG - Category ${catId} not found in categoryMap`)
        }
      })
    } else {
      console.log('🔍 DEBUG - Participant has no categories array')
    }
  })
  return categoryMap
})

// Enhanced category data with participant info
const categoryData = computed(() => {
  if (!categories.value || categories.value.length === 0) {
    return []
  }

  return categories.value.map((category: any) => {
    const categoryId = (category.id || category.categoryId)?.toString()
    const categoryParticipants = participantsByCategory.value.get(categoryId) || []

    // Get total allocation for this category
    let totalAllocation: bigint

    // Check if this is an Open category with allocationPerUser and maxParticipants
    const isPredefined = category.mode && (('Predefined' in category.mode) ? true : false)
    const isOpen = category.mode && (('Open' in category.mode) ? true : false)

    if (isOpen && category.allocationPerUser && category.maxParticipants) {
      // Open category: calculate from maxParticipants * allocationPerUser
      const allocationPerUser = typeof category.allocationPerUser === 'bigint'
        ? category.allocationPerUser
        : BigInt(category.allocationPerUser || 0)
      const maxParticipants = BigInt(category.maxParticipants || 0)
      totalAllocation = allocationPerUser * maxParticipants
    }
    // For Predefined category or if calculation fails: calculate from participants
    else {
      totalAllocation = categoryParticipants.reduce((sum: bigint, p: any) => {
        const allocation = typeof p.allocation === 'bigint' ? p.allocation : BigInt(p.allocation || 0)
        return sum + allocation
      }, BigInt(0))
    }

    return {
      category,
      categoryId: category.id || category.categoryId,
      categoryParticipants,
      participantsCount: categoryParticipants.length,
      // Properties for CategoryDetailsCard
      name: category.name || `Category ${categoryId}`,
      description: category.description && category.description.length > 0 ? category.description[0] : '',
      mode: category.mode ? (('Predefined' in category.mode) ? 'Predefined' : 'Open') : 'Open',
      totalAllocation: totalAllocation,
      vestingSchedule: category.defaultVestingSchedule || details.value?.vestingSchedule,
      vestingStart: category.defaultVestingStart || details.value?.distributionStart,
      passportScore: category.defaultPassportScore || BigInt(0),
      passportProvider: category.defaultPassportProvider || 'ICTO',
      maxParticipants: category.maxParticipants && category.maxParticipants.length > 0 ? category.maxParticipants[0] : null,
      allocationPerUser: category.allocationPerUser && category.allocationPerUser.length > 0 ? category.allocationPerUser[0] : null,
      participants: categoryParticipants,
      // Inject user-specific status data from backend (vesting-aware)
      claimableAmount: userCategoryBreakdown.value.get(categoryId)?.claimableAmount,
      eligibleAmount: userCategoryBreakdown.value.get(categoryId)?.allocatedAmount,
      claimedAmount: userCategoryBreakdown.value.get(categoryId)?.claimedAmount
    }
  })
})

// ============================================
// UTILITY FUNCTIONS
// ============================================
const formatNumber = (value: number) => {
  return new Intl.NumberFormat().format(value)
}

// ============================================
// EXISTING METHODS (KEEP ALL)
// ============================================
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
    await refreshClaimInfo()
    showClaimModal.value = true
  } catch (err) {
    console.error('Error fetching claim info:', err)
    toast.error('Error: ' + (err instanceof Error ? err.message : 'Failed to fetch claim info'))
  }
}

const refreshClaimInfo = async () => {
  try {
    claimInfo.value = await DistributionService.getClaimInfo(canisterId.value)
  } catch (err) {
    console.error('Error refreshing claim info:', err)
    toast.error('Error: ' + (err instanceof Error ? err.message : 'Failed to refresh claim info'))
  }
}

const handleClaim = async (amount: number) => {
  try {
    claiming.value = true

    const rawAmount = formatTokenAmount(amount, details.value?.tokenInfo.decimals || 8)
    // Use batch claim (with no category ID = claim from all categories)
    const result = await DistributionService.batchClaim(canisterId.value, undefined, rawAmount.toFixed())

    if ('ok' in result) {
      const batchData = result.ok
      // Store result for modal display
      batchResult.value = batchData
      batchOperationType.value = 'claim'
      showBatchResultModal.value = true

      // Close the claim amount modal
      showClaimModal.value = false

      // Show success toast
      if (batchData.success) {
        toast.success(batchData.message || 'Successfully claimed tokens')
      } else {
        toast.warning(batchData.message || 'Claim completed with some issues')
      }

      // Refresh claim info and data
      await refreshClaimInfo()
      await refreshData()
    } else {
      toast.error('Claim failed: ' + result.err)
    }
  } catch (err) {
    console.error('Error claiming tokens:', err)
    toast.error('Error: ' + (err instanceof Error ? err.message : 'Failed to claim tokens'))
  } finally {
    claiming.value = false
  }
}

// ✅ NEW: Handle successful contract funding
const handleFundSuccess = async () => {
  showFundModal.value = false
  toast.success('Contract funded successfully! Refreshing balance...')

  // Wait a moment for blockchain to process
  await new Promise(resolve => setTimeout(resolve, 2000))

  // Refresh contract balance
  await checkBalance()

  // Refresh all data to update status
  await refreshData()
}

const checkBalance = async () => {
  if (!details.value) return
  try {
    checkingBalance.value = true
    const token = {
      canisterId: details.value.tokenInfo.canisterId.toString(),
      name: details.value.tokenInfo.name,
      symbol: details.value.tokenInfo.symbol,
      decimals: details.value.tokenInfo.decimals,
      fee: 10000,
      standards: ['ICRC-1'],
      metrics: { totalSupply: 0, holders: 0, marketCap: 0, price: 0, volume: 0 }
    }
    const balance = await DistributionService.getContractBalance(token, canisterId.value)
    contractBalance.value = balance
  } catch (err) {
    console.error('Error fetching contract balance:', err)
  } finally {
    checkingBalance.value = false
  }
}

// Watch for details to auto-select category if only one exists
watch(() => details.value, (newDetails) => {
  // Logic moved to categoryData watch to handle nested arrays correctly
}, { immediate: true })

// Watch for category data as well in case it loads separately
watch(() => categoryData.value, (newCategories) => {
  if (!newCategories || newCategories.length === 0) return

  if (newCategories.length === 1) {
    // Auto-select single category
    const categoryId = newCategories[0].categoryId || newCategories[0].category?.id
    if (categoryId && (activeCategoryTab.value === 'all' || !activeCategoryTab.value)) {
      activeCategoryTab.value = String(categoryId)
    }
  } else {
    // Default to 'all' if multiple categories and not set
    if (!activeCategoryTab.value) {
      activeCategoryTab.value = 'all'
    }
  }
}, { immediate: true })

onMounted(async () => {
  if (props.canisterId) {
    canisterId.value = props.canisterId
    await fetchDetails()
  }
})

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
    // Use batch register (with no category ID = register for all Open categories)
    const result = await DistributionService.batchRegister(canisterId.value)

    if ('ok' in result) {
      const batchData = result.ok
      // Store result for modal display
      batchResult.value = batchData
      batchOperationType.value = 'register'
      showBatchResultModal.value = true

      // Show success toast
      if (batchData.success) {
        toast.success(batchData.message || 'Successfully registered for distribution')
      } else {
        toast.warning(batchData.message || 'Registration completed with some issues')
      }

      // Refresh data
      await refreshData()
    } else {
      toast.error('Registration failed: ' + result.err)
    }
  } catch (err) {
    console.error('Error in batch registration:', err)
    toast.error('Error: ' + (err instanceof Error ? err.message : String(err)))
  } finally {
    registering.value = false
  }
}

const fetchUserContext = async () => {
  try {
    const context = await DistributionService.getUserContext(canisterId.value)
    userContext.value = context

    if (context.participant) {
      userAllocation.value = context.participant.eligibleAmount || BigInt(0)
      alreadyClaimed.value = context.participant.claimedAmount || BigInt(0)
    }
    availableToClaim.value = context.claimableAmount

    if (context.isRegistered && context.principal) {
      await fetchParticipantData(context.principal)
      // Fetch vesting-aware category breakdown
      await fetchCategoryBreakdown(context.principal)
    }
  } catch (err) {
    console.error('Error fetching user context:', err)
    userContext.value = null
  }
}

const fetchCategoryBreakdown = async (principalId: string) => {
  try {
    const breakdown = await DistributionService.getUserCategoryBreakdown(canisterId.value, principalId)

    // Convert array to Map for quick lookup by categoryId
    const breakdownMap = new Map()
    breakdown.forEach((cat: any) => {
      breakdownMap.set(cat.categoryId.toString(), cat)
    })
    userCategoryBreakdown.value = breakdownMap
  } catch (err) {
    console.error('Error fetching category breakdown:', err)
    userCategoryBreakdown.value = new Map()
  }
}

const fetchParticipantData = async (principalId?: string) => {
  try {
    const principal = principalId || userContext.value?.principal
    if (!principal) return

    const participant = await DistributionService.getParticipant(canisterId.value, principal)
    participantData.value = participant

    if (participant && participant.length > 0) {
      const participantInfo = participant[0]
      userAllocation.value = participantInfo.eligibleAmount || BigInt(0)
      alreadyClaimed.value = participantInfo.claimedAmount || BigInt(0)
      availableToClaim.value = userContext.value?.claimableAmount || BigInt(0)
    }
  } catch (err) {
    console.error('Error fetching participant data:', err)
    participantData.value = null
  }
}

const toggleAutoRefresh = () => {
  autoRefreshEnabled.value = !autoRefreshEnabled.value
}

// ============================================
// NEW: CATEGORY STATUS COMPOSABLE
// ============================================
const categoriesRef = computed(() => categoryData.value)
const userContextRef = computed(() => userContext.value)
const isAuthenticatedRef = computed(() => authStore.isConnected)
const categoryBreakdownRef = computed(() => userCategoryBreakdown.value)

const {
  categoriesWithStatus,
  eligibleCategories,
  claimableCategories,
  hasEligibleCategories,
  hasClaimableCategories,
  getCategoryUserStatus
} = useCategoryStatus(categoriesRef, userContextRef, isAuthenticatedRef, categoryBreakdownRef)

// ============================================
// NEW: CATEGORY OPERATIONS
// ============================================

/**
 * Handle batch register for all eligible categories
 */
const handleBatchRegister = async () => {
  // Show confirmation modal
  batchConfirmType.value = 'register'
  showBatchConfirmModal.value = true
}

/**
 * Confirm and execute batch operation (register or claim)
 */
const confirmBatchOperation = (selectedIds?: string[]) => {
  if (batchConfirmType.value === 'register') {
    confirmBatchRegister(selectedIds)
  } else {
    confirmBatchClaim(selectedIds)
  }
}

/**
 * Confirm and execute batch register
 */
const confirmBatchRegister = async (selectedIds?: string[]) => {
  try {
    registering.value = true
    showBatchConfirmModal.value = false

    // Check if this is a single category register
    if (selectedIds && selectedIds.length === 1) {
      // Single category register
      const categoryId = selectedIds[0]
      const result = await DistributionService.batchRegister(canisterId.value, [Number(categoryId)])

      if ('ok' in result) {
        const batchData = result.ok
        batchResult.value = {
          success: batchData.success ?? true,
          message: batchData.message || 'Successfully registered for category',
          categories: batchData.categories || []
        }
        batchOperationType.value = 'register'
        showBatchResultModal.value = true

        if (batchData.success) {
          toast.success(batchData.message || 'Successfully registered for category')
        } else {
          toast.warning(batchData.message || 'Registration completed with some issues')
        }

        await refreshData()
        
        // Reset single category state
        singleClaimCategory.value = null
        confirmModalMode.value = 'batch'
      } else {
        toast.error('Registration failed: ' + result.err)
      }
    } else {
      // Batch register for all or multiple categories
      await registerForCampaign()
    }
  } catch (err) {
    console.error('Error in batch registration:', err)
    toast.error('Error: ' + (err instanceof Error ? err.message : String(err)))
  } finally {
    registering.value = false
  }
}

/**
 * Handle batch claim for all claimable categories
 */
const handleBatchClaim = async () => {
  // Check if there are any claimable categories
  if (claimableCategories.value.length === 0) {
    toast.warning('No categories available to claim at this time')
    return
  }

  // Show confirmation modal
  batchConfirmType.value = 'claim'
  showBatchConfirmModal.value = true
}

/**
 * Confirm and execute batch claim
 */
/**
 * Confirm and execute batch claim
 */
/**
 * Confirm and execute batch claim
 */
/**
 * Confirm and execute batch claim
 */
const confirmBatchClaim = async (selectedIds?: string[]) => {
  try {
    claiming.value = true
    // Keep modal open but show loading state
    // showBatchConfirmModal.value = false // Don't close yet

    let result;
    let totalAmount = BigInt(0);
    const idsToClaim = selectedIds || claimableCategories.value.map((c: any) => c.categoryId)

    if (idsToClaim.length === 0) {
      toast.warning('No categories selected')
      claiming.value = false
      return
    }

    // Check if we can use batch claim for all (if all selected)
    const allClaimableIds = claimableCategories.value.map((c: any) => c.categoryId)
    const isAllSelected = idsToClaim.length === allClaimableIds.length && 
                          idsToClaim.every((id: string) => allClaimableIds.includes(id))

    if (isAllSelected) {
      // Batch claim all
      totalAmount = claimableCategories.value.reduce(
        (sum: bigint, cat: any) => sum + cat.claimableAmount,
        BigInt(0)
      )
      result = await DistributionService.batchClaim(canisterId.value)
    } else if (idsToClaim.length === 1) {
      // Single category claim
      const categoryId = idsToClaim[0]
      const category = claimableCategories.value.find((c: any) => c.categoryId === categoryId)
      const amount = category?.claimableAmount
      totalAmount = amount ? BigInt(amount) : BigInt(0)
      
      result = await DistributionService.batchClaim(
        canisterId.value,
        Number(categoryId),
        amount?.toString()
      )
    } else {
      // Subset claim - loop through selected IDs
      // Note: Ideally backend should support array of IDs for claim, but for now we loop
      // or we can use batchClaim with specific ID multiple times.
      // However, to show a unified result, we might need to aggregate.
      // For now, let's try to use the batchClaim with array if supported, or loop.
      // Looking at service, batchClaim takes optional categoryId.
      // If we want to claim multiple but not all, we have to loop.
      
      const results = []
      let successCount = 0
      let failCount = 0
      
      for (const id of idsToClaim) {
        const category = claimableCategories.value.find((c: any) => c.categoryId === id)
        if (category) {
          const res = await DistributionService.batchClaim(
            canisterId.value,
            Number(id),
            category.claimableAmount?.toString()
          )
          
          if ('ok' in res && res.ok.success) {
            successCount++
            totalAmount += BigInt(category.claimableAmount || 0)
            results.push({
              categoryId: id,
              success: true,
              message: res.ok.message
            })
          } else {
            failCount++
            results.push({
              categoryId: id,
              success: false,
              message: 'ok' in res ? res.ok.message : res.err
            })
          }
        }
      }
      
      // Construct a synthetic result
      result = {
        ok: {
          success: failCount === 0,
          message: failCount === 0 
            ? `Successfully claimed ${formatTokenAmount(totalAmount, details.value?.tokenInfo.decimals || 8)} ${details.value?.tokenInfo.symbol} from ${idsToClaim.length} ${idsToClaim.length === 1 ? 'category' : 'categories'}`
            : `Claimed ${successCount}/${idsToClaim.length} categories`,
          categories: results.map(r => ({
            categoryId: r.categoryId,
            categoryName: claimableCategories.value.find((c: any) => c.categoryId === r.categoryId)?.name || '',
            success: r.success,
            isValid: true,
            allocation: BigInt(0), // Not needed for claim result display usually
            claimedAmount: BigInt(0), // We could track this if needed
            isRegistered: true,
            errorMessage: r.success ? null : r.message
          }))
        }
      }
    }
    
    // Show result modal
    if (result && 'ok' in result) {
      const batchData = result.ok
      
      batchResult.value = {
        success: batchData.success ?? true,
        message: batchData.message || `Successfully claimed ${formatTokenAmount(totalAmount)} ${details.value?.tokenInfo.symbol}`,
        categories: batchData.categories || [],
        totalAmount: totalAmount
      }
    } else {
      batchResult.value = {
        success: false,
        message: result?.err || 'Claim failed',
        categories: [],
        totalAmount: BigInt(0)
      }
    }
    
    // Close confirm modal and show result modal
    showBatchConfirmModal.value = false
    batchOperationType.value = 'claim'
    showBatchResultModal.value = true
    
    // Refresh all data (user status, claimed amounts, etc.)
    await refreshData()
  } catch (err) {
    console.error('Error in batch claim:', err)
    toast.error('Error: ' + (err instanceof Error ? err.message : String(err)))
    showBatchConfirmModal.value = false // Close on error
  } finally {
    claiming.value = false
    // Reset mode after operation
    setTimeout(() => {
      confirmModalMode.value = 'batch'
      singleClaimCategory.value = null
    }, 500)
  }
}

/**
 * Handle individual category register
 */
const handleCategoryRegister = async (categoryId: number | bigint) => {
  // Find the category object
  const category = categoryData.value.find((c: any) => 
    (c.categoryId?.toString() === categoryId.toString()) || 
    (c.category?.id?.toString() === categoryId.toString())
  )
  
  if (!category) {
    toast.error('Category not found')
    return
  }

  // Set up single register confirmation
  singleClaimCategory.value = category
  confirmModalMode.value = 'single'
  batchConfirmType.value = 'register'
  showBatchConfirmModal.value = true
}

/**
 * Handle individual category claim
 */
const handleCategoryClaim = async (categoryId: number | bigint, amount: bigint) => {
  // Find the category object
  const category = categoryData.value.find((c: any) => 
    (c.categoryId?.toString() === categoryId.toString()) || 
    (c.category?.id?.toString() === categoryId.toString())
  )
  
  if (!category) {
    toast.error('Category not found')
    return
  }

  // Set up single claim confirmation
  singleClaimCategory.value = {
    ...category,
    claimableAmount: amount // Ensure claimable amount is set for the modal
  }
  confirmModalMode.value = 'single'
  batchConfirmType.value = 'claim'
  showBatchConfirmModal.value = true
}

/**
 * Navigate to category (from sidebar click)
 */
const scrollToCategory = (categoryId: string) => {
  // Update active category tab - this will trigger the breadcrumb navigation and show the category details
  activeCategoryTab.value = categoryId
  
  // Scroll to top of page to show the category content
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

/**
 * Navigate to Launchpad detail page
 */
const navigateToLaunchpad = (launchpadId: string) => {
  router.push(`/launchpad/${launchpadId}`)
}

/**
 * Navigate to Token detail page
 */
const navigateToToken = (tokenCanisterId: string) => {
  router.push(`/token/${tokenCanisterId}`)
}

/**
 * Handle countdown end - refresh data from server to get latest status
 * This is critical for status transitions (Created -> Live, Registration -> Live, etc.)
 */
const handleCountdownEnd = async () => {
  console.log('🔄 Countdown ended, refreshing data from server...')

  // Check balance first (important for Created -> Live transition)
  await checkBalance()

  // Then refresh all data
  await refreshData()

  toast.info('Distribution status updated', {
    description: 'Fetched latest status from server'
  })
}

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

/* Highlight pulse animation for scrolled category */
:global(.highlight-pulse) {
  animation: highlight-pulse 2s ease-out;
}

@keyframes highlight-pulse {

  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0);
    transform: scale(1);
  }

  50% {
    box-shadow: 0 0 0 10px rgba(59, 130, 246, 0.3);
    transform: scale(1.01);
  }
}
</style>
