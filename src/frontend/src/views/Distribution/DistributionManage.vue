<template>
  <AdminLayout>
    <div class="distribution-manage min-h-screen">
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
          <div class="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl" v-for="i in 6" :key="i"></div>
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

      <!-- Main Content -->
      <div v-else-if="details && stats">
        <!-- Header Section -->
        <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-8 mb-8">
          <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between">
            <div class="flex items-start space-x-4">
              <div class="w-16 h-16 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center flex-shrink-0">
                <SettingsIcon class="w-8 h-8 text-white" />
              </div>
              <div class="flex-1 min-w-0">
                <h1 class="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                  {{ details.title }}
                </h1>
                <p class="text-gray-600 dark:text-gray-300 mb-4">
                  {{ details.description }}
                </p>
                <div class="flex flex-wrap items-center gap-3">
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium"
                    :class="statusColor">
                    <div class="w-2 h-2 rounded-full mr-2" :class="statusDotColor"></div>
                    {{ statusText }}
                  </span>
                  <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200">
                    <CalendarIcon class="w-4 h-4 mr-1" />
                    {{ formatDate(details.distributionStart) }}
                  </span>
                </div>
              </div>
            </div>
            
            <!-- Admin Action Toolbar -->
            <div class="flex flex-wrap gap-3 mt-6 lg:mt-0">
              <button v-if="canInitialize" @click="initializeDistribution" :disabled="initializing"
                class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                <PlayIcon class="w-4 h-4 mr-2" />
                {{ initializing ? 'Initializing...' : 'Initialize' }}
              </button>
              <button v-if="canActivate" @click="activateDistribution" :disabled="activating"
                class="inline-flex text-sm items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                <PlayIcon class="w-4 h-4 mr-2" />
                {{ activating ? 'Activating...' : 'Activate' }}
              </button>
              
              <button v-if="canPause" @click="pauseDistribution" :disabled="pausing"
                class="inline-flex text-sm items-center px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                <PauseIcon class="w-4 h-4 mr-2" />
                {{ pausing ? 'Pausing...' : 'Pause' }}
              </button>
              
              <button v-if="canResume" @click="resumeDistribution" :disabled="resuming"
                class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                <PlayIcon class="w-4 h-4 mr-2" />
                {{ resuming ? 'Resuming...' : 'Resume' }}
              </button>
              
              <button v-if="canCancel" @click="confirmCancelDistribution"
                class="inline-flex text-sm items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors duration-200">
                <XCircleIcon class="w-4 h-4 mr-2" />
                Cancel
              </button>
              
              <button @click="refreshData" :disabled="refreshing"
                class="inline-flex text-sm items-center px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': refreshing }" />
                Refresh
              </button>
            </div>
          </div>
        </div>

        <!-- Insufficient Balance Alert -->
        <div v-if="hasInsufficientBalance" class="bg-red-50 border border-red-200 rounded-xl p-6 mb-8 dark:bg-red-900/20 dark:border-red-800">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <AlertCircleIcon class="w-6 h-6 text-red-600 dark:text-red-400" />
            </div>
            <div class="ml-3 flex-1">
              <h3 class="text-lg font-semibold text-red-800 dark:text-red-200 mb-2">
                Insufficient  {{ details.tokenInfo.symbol }} balance in the contract
              </h3>
              <p class="text-red-700 text-sm dark:text-red-300 mb-4">
                Campaign cannot be started due to insufficient ICP balance. The contract needs <span class="font-bold">{{ formatNumber(missingAmount) }} more {{ details.tokenInfo.symbol }}</span> to fulfill all distributions. Please transfer additional {{ details.tokenInfo.symbol }} to the contract.
              </p>
              <div class="bg-red-100 dark:bg-red-900/40 rounded-lg p-4 mb-4">
                <div class="flex flex-col lg:flex-row gap-4">
                  <!-- Canister ID -->
                  <div class="flex-1 text-center lg:text-left">
                    <div class="text-xs text-red-600 dark:text-red-400 font-medium mb-1">Contract Address</div>
                    <div class="flex items-center justify-center lg:justify-start space-x-2">
                      <code class="text-xs font-mono text-gray-900 dark:text-white bg-white dark:bg-gray-700 px-2 py-1 rounded border truncate">
                        {{ distributionId }}
                      </code>
                      <CopyIcon :data="distributionId" class="w-4 h-4 text-gray-500 dark:text-gray-400 flex-shrink-0" />
                    </div>
                  </div>
                  <!-- Required Amount -->
                  <div class="flex-1 text-center lg:text-left">
                    <div class="text-xs text-red-600 dark:text-red-400 font-medium mb-1">Required Amount</div>
                    <div class="text-lg font-bold text-red-800 dark:text-red-200">
                      {{ formatNumber(parseTokenAmount(details.totalAmount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                    </div>
                  </div>
                  
                  <!-- Current Balance -->
                  <div class="flex-1 text-center lg:text-left">
                    <div class="text-xs text-red-600 dark:text-red-400 font-medium mb-1">Current Balance</div>
                    <div class="text-lg font-bold text-red-800 dark:text-red-200">
                      {{ formatNumber(parseTokenAmount(contractBalance, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                    </div>
                  </div>
                  
                  
                </div>
              </div>
              
              <div class="flex items-center space-x-3">
                <button @click="checkBalance" :disabled="checkingBalance"
                  class="inline-flex text-sm items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors duration-200">
                  <RefreshCwIcon class="w-4 h-4 mr-2" :class="{ 'animate-spin': checkingBalance }" />
                  {{ checkingBalance ? 'Checking...' : 'Check Balance' }}
                </button>
                <div class="text-sm text-red-600 dark:text-red-400">
                  Transfer {{ formatNumber(missingAmount) }} {{ details.tokenInfo.symbol }} to the canister ID above
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Analytics Dashboard -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <!-- Total Participants -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900/30 rounded-lg flex items-center justify-center">
                <UsersIcon class="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ stats.totalParticipants }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Participants</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-green-600 dark:text-green-400">
                <TrendingUpIcon class="w-4 h-4 mr-1" />
                <span>{{ participantGrowthRate }}%</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">vs last period</span>
            </div>
          </div>

          <!-- Total Distributed -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-purple-100 dark:bg-purple-900/30 rounded-lg flex items-center justify-center">
                <CoinsIcon class="w-6 h-6 text-purple-600 dark:text-purple-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ formatNumber(parseTokenAmount(stats.totalDistributed, details.tokenInfo.decimals).toNumber()) }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">{{ details.tokenInfo.symbol }}</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-blue-600 dark:text-blue-400">
                <PercentIcon class="w-4 h-4 mr-1" />
                <span>{{ distributionProgress.toFixed(1) }}%</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">distributed</span>
            </div>
          </div>

          <!-- Claims Made -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-green-100 dark:bg-green-900/30 rounded-lg flex items-center justify-center">
                <CheckCircleIcon class="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ totalClaims }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">Claims</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center text-green-600 dark:text-green-400">
                <ActivityIcon class="w-4 h-4 mr-1" />
                <span>{{ claimRate.toFixed(1) }}%</span>
              </div>
              <span class="text-gray-500 dark:text-gray-400 ml-2">claim rate</span>
            </div>
          </div>

          <!-- Contract Balance -->
          <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-4">
              <div class="w-12 h-12 bg-orange-100 dark:bg-orange-900/30 rounded-lg flex items-center justify-center">
                <WalletIcon class="w-6 h-6 text-orange-600 dark:text-orange-400" />
              </div>
              <div class="text-right">
                <div class="text-2xl font-bold text-gray-900 dark:text-white">
                  {{ formatNumber(parseTokenAmount(contractBalance, details.tokenInfo.decimals).toNumber()) }}
                </div>
                <div class="text-sm text-gray-500 dark:text-gray-400">{{ details.tokenInfo.symbol }}</div>
              </div>
            </div>
            <div class="flex items-center text-sm">
              <div class="flex items-center" :class="balanceHealthColor">
                <DollarSignIcon class="w-4 h-4 mr-1" />
                <span>{{ balanceHealthText }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Charts Section -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <!-- Vesting Chart -->
          <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Token Unlock Schedule</h3>
              <div class="flex items-center space-x-2">
                <button @click="chartType = 'apex'" :class="chartType === 'apex' ? 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400' : 'text-gray-500 dark:text-gray-400'"
                  class="px-3 py-1 rounded-lg text-sm font-medium transition-colors">
                  Visualize Schedule
                </button>
              </div>
            </div>
            <div class="h-80">
              <VestingChart v-if="chartType === 'apex'"
                :vestingData="vestingScheduleData"
                :hasCliffPeriod="hasCliffPeriod"
                :hasInstantUnlock="hasInstantUnlock"
                :currentTimePosition="currentTimePosition"
                :cliffEndPosition="cliffEndPosition" />
              <!-- SVG Chart would go here -->
            </div>
          </div>

          <!-- Claims Timeline -->
          <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Claims Timeline</h3>
            <div class="h-80">
              <VueApexCharts v-if="claimTimelineData.length > 0"
                type="area"
                height="320"
                :options="claimTimelineOptions"
                :series="claimTimelineData" />
              <div v-else class="flex items-center justify-center h-full text-gray-500 dark:text-gray-400">
                No claims data available
              </div>
            </div>
          </div>
        </div>

        <!-- Management Sections -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <!-- Participants Management -->
          <div class="lg:col-span-2 bg-white dark:bg-gray-800 rounded-2xl shadow-lg border border-gray-200 dark:border-gray-700">
            <div class="p-6 border-b border-gray-200 dark:border-gray-700">
              <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Participants Management</h3>
                <div class="flex items-center space-x-3">
                  <div class="relative">
                    <input v-model="participantSearch" type="text" placeholder="Search participants..."
                      class="pl-10 pr-4 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
                    <SearchIcon class="w-5 h-5 text-gray-400 absolute left-3 top-2.5" />
                  </div>
                  <button v-if="canAddParticipants" @click="showAddParticipantModal = true"
                    class="inline-flex text-sm items-center px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200">
                    <PlusIcon class="w-4 h-4 mr-2" />
                    Add Participant
                  </button>
                </div>
              </div>
              
              <!-- Participants Filters -->
              <div class="flex flex-wrap gap-2">
                <button v-for="filter in participantFilters" :key="filter.key" @click="activeParticipantFilter = filter.key"
                  :class="activeParticipantFilter === filter.key ? 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400' : 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-300'"
                  class="px-3 py-1 rounded-lg text-sm font-medium transition-colors">
                  {{ filter.label }} ({{ filter.count }})
                </button>
              </div>
            </div>
            
            <div class="overflow-x-auto">
              <table class="w-full">
                <thead class="bg-gray-50 dark:bg-gray-900/50">
                  <tr>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Participant
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Eligible Amount
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Claimed
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Status
                    </th>
                    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Last Claim
                    </th>
                    <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                  <tr v-for="participant in filteredParticipants" :key="participant.principal">
                    <td class="px-6 py-4 whitespace-nowrap">
                      <div class="flex items-center">
                        <div class="w-8 h-8 bg-gray-200 dark:bg-gray-600 rounded-full flex items-center justify-center mr-3">
                          <UserIcon class="w-4 h-4 text-gray-600 dark:text-gray-300" />
                        </div>
                        <div>
                          <div class="text-sm font-medium text-gray-900 dark:text-white">
                            {{ shortPrincipal(participant.principal) }}
                          </div>
                          <div v-if="participant.note" class="text-sm text-gray-500 dark:text-gray-400">
                            {{ participant.note.length > 0 ? participant.note : '' }}
                          </div>
                        </div>
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      {{ formatNumber(parseTokenAmount(participant.eligibleAmount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                      {{ formatNumber(parseTokenAmount(participant.claimedAmount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}
                      <div class="text-xs text-gray-500 dark:text-gray-400">
                        {{ ((Number(participant.claimedAmount) / Number(participant.eligibleAmount)) * 100).toFixed(1) }}%
                      </div>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap">
                      <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
                        :class="getParticipantStatusColor(participant.status)">
                        {{ keyToText(participant.status) }}
                      </span>
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                      {{ participant.lastClaimTime ? (Number(participant.lastClaimTime) * 1000) : 'Never' }}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div class="flex items-center justify-end space-x-2">
                        <button @click="viewParticipantDetails(participant)"
                          class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300">
                          <EyeIcon class="w-4 h-4" />
                        </button>
                        <button v-if="canManageParticipants" @click="editParticipant(participant)"
                          class="text-gray-600 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300">
                          <EditIcon class="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            
            <!-- Pagination -->
            <div v-if="totalParticipantPages > 1" class="px-6 py-4 border-t border-gray-200 dark:border-gray-700">
              <div class="flex items-center justify-between">
                <div class="text-sm text-gray-500 dark:text-gray-400">
                  Showing {{ ((currentParticipantPage - 1) * participantsPerPage) + 1 }} to {{ Math.min(currentParticipantPage * participantsPerPage, filteredParticipants.length) }} of {{ filteredParticipants.length }} participants
                </div>
                <div class="flex items-center space-x-2">
                  <button @click="currentParticipantPage--" :disabled="currentParticipantPage === 1"
                    class="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600">
                    Previous
                  </button>
                  <button @click="currentParticipantPage++" :disabled="currentParticipantPage >= totalParticipantPages"
                    class="px-3 py-1 rounded-lg bg-gray-100 text-gray-600 hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed dark:bg-gray-700 dark:text-gray-300 dark:hover:bg-gray-600">
                    Next
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- System Information -->
          <div class="space-y-6">
            <!-- Contract Status -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Contract Status</h3>
              <div class="space-y-4">
                <div class="flex items-center justify-between">
                  <span class="text-sm text-gray-500 dark:text-gray-400">Contract Address</span>
                  <button @click="copyToClipboard(route.params.id as string)"
                    class="text-sm text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 font-mono">
                    {{ shortPrincipal(route.params.id as string) }}
                  </button>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-sm text-gray-500 dark:text-gray-400">Created</span>
                  <span class="text-sm text-gray-900 dark:text-white">{{ formatDate(details.distributionStart) }}</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-sm text-gray-500 dark:text-gray-400">Total Amount</span>
                  <span class="text-sm text-gray-900 dark:text-white">{{ formatNumber(parseTokenAmount(details.totalAmount, details.tokenInfo.decimals).toNumber()) }} {{ details.tokenInfo.symbol }}</span>
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-sm text-gray-500 dark:text-gray-400">Cycles Balance</span>
                  <span class="text-sm text-gray-900 dark:text-white">{{ cyclesToT(cyclesBalance) }}</span>
                </div>
              </div>
            </div>

            <!-- Recent Activity -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Recent Activity</h3>
              <div class="space-y-3">
                <div v-for="activity in recentActivity" :key="activity.id" class="flex items-start space-x-3">
                  <div class="w-2 h-2 rounded-full mt-2 flex-shrink-0" :class="activity.color"></div>
                  <div class="flex-1 min-w-0">
                    <p class="text-sm text-gray-900 dark:text-white">{{ activity.description }}</p>
                    <p class="text-xs text-gray-500 dark:text-gray-400">{{ formatRelativeTime(activity.timestamp) }}</p>
                  </div>
                </div>
                <div v-if="recentActivity.length === 0" class="text-sm text-gray-500 dark:text-gray-400 text-center py-4">
                  No recent activity
                </div>
              </div>
            </div>

            <!-- Timer Status -->
            <div class="bg-white dark:bg-gray-800 rounded-xl shadow-lg border border-gray-200 dark:border-gray-700 p-6">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">Timer Status</h3>
              <div class="space-y-4">
                <div class="flex items-center justify-between">
                  <span class="text-sm text-gray-500 dark:text-gray-400">Auto-start Timer</span>
                  <div class="flex items-center space-x-2">
                    <div class="w-2 h-2 rounded-full" :class="timerRunning ? 'bg-green-400' : 'bg-gray-400'"></div>
                    <span class="text-sm text-gray-900 dark:text-white">{{ timerRunning ? 'Running' : 'Stopped' }}</span>
                  </div>
                </div>
                <div class="flex items-center space-x-2">
                  <button @click="startTimer" :disabled="startingTimer || timerRunning"
                    class="flex-1 px-3 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm">
                    {{ startingTimer ? 'Starting...' : 'Start Timer' }}
                  </button>
                  <button @click="stopTimer" :disabled="stoppingTimer || !timerRunning"
                    class="flex-1 px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm">
                    {{ stoppingTimer ? 'Stopping...' : 'Stop Timer' }}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modals -->
    <!-- Cancel Confirmation Modal -->
    <div v-if="showCancelModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl p-6 max-w-md w-full mx-4">
        <div class="flex items-center mb-4">
          <div class="w-12 h-12 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center mr-4">
            <XCircleIcon class="w-6 h-6 text-red-600 dark:text-red-400" />
          </div>
          <div>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Cancel Distribution</h3>
            <p class="text-sm text-gray-500 dark:text-gray-400">This action cannot be undone</p>
          </div>
        </div>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-6">
          Are you sure you want to cancel this distribution? All remaining tokens will be returned to the owner.
        </p>
        <div class="flex justify-end space-x-3">
          <button @click="showCancelModal = false"
            class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
            Keep Active
          </button>
          <button @click="cancelDistribution" :disabled="cancelling"
            class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm">
            {{ cancelling ? 'Cancelling...' : 'Yes, Cancel' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Add Participant Modal -->
    <div v-if="showAddParticipantModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl p-6 max-w-md w-full mx-4">
        <div class="flex items-center justify-between mb-6">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Add Participant</h3>
          <button @click="showAddParticipantModal = false">
            <XIcon class="w-5 h-5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300" />
          </button>
        </div>
        <form @submit.prevent="addParticipant">
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Principal ID
              </label>
              <input v-model="newParticipant.principal" type="text" required
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Enter participant's principal ID">
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Amount ({{ details.tokenInfo.symbol }})
              </label>
              <input v-model="newParticipant.amount" type="number" required min="0" step="0.00000001"
                class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                placeholder="Enter allocation amount">
            </div>
          </div>
          <div class="flex justify-end space-x-3 mt-6">
            <button type="button" @click="showAddParticipantModal = false"
              class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white">
              Cancel
            </button>
            <button type="submit" :disabled="addingParticipant"
              class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-sm">
              {{ addingParticipant ? 'Adding...' : 'Add Participant' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { DistributionService } from '@/api/services/distribution'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import VestingChart from '@/components/distribution/VestingChart.vue'
import VueApexCharts from 'vue3-apexcharts'
import { 
  ArrowLeftIcon, AlertCircleIcon, RefreshCwIcon, SettingsIcon, CalendarIcon,
  PlayIcon, PauseIcon, XCircleIcon, UsersIcon, CoinsIcon, CheckCircleIcon,
  WalletIcon, TrendingUpIcon, PercentIcon, ActivityIcon, DollarSignIcon,
  SearchIcon, PlusIcon, UserIcon, EyeIcon, EditIcon, XIcon
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'
import { parseTokenAmount, formatTokenAmount } from '@/utils/token'
import { cyclesToT, shortPrincipal, keyToText } from '@/utils/common'
import { 
  getDistributionStatusColor,
  getDistributionStatusDotColor,
  getDistributionStatusText,
  canActivateDistribution,
  canPauseDistribution,
  canResumeDistribution,
  canCancelDistribution,
  canInitializeDistribution,
  shouldShowInsufficientBalanceAlert
} from '@/utils/distribution'
import { CopyIcon } from '@/icons'
import type { Token } from '@/types/token'
// Types
interface Participant {
  principal: string
  registeredAt: bigint
  eligibleAmount: number
  claimedAmount: number
  lastClaimTime: bigint | null
  status: string
  vestingStart: bigint | null
  note: string | null
}

interface ClaimRecord {
  participant: string
  amount: number
  timestamp: bigint
  blockHeight: number | null
  transactionId: string | null
}

// Router and auth
const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

// Reactive data
const loading = ref(true)
const error = ref<string | null>(null)
const details = ref<any>(null)
const stats = ref<any>(null)
const participants = ref<Participant[]>([])
const claimHistory = ref<ClaimRecord[]>([])
const contractBalance = ref(0)
const cyclesBalance = ref(0)
const distributionStatus = ref<string>('')

// Action states
const activating = ref(false)
const pausing = ref(false)
const resuming = ref(false)
const cancelling = ref(false)
const refreshing = ref(false)
const startingTimer = ref(false)
const stoppingTimer = ref(false)
const addingParticipant = ref(false)
const checkingBalance = ref(false)
const initializing = ref(false)
// UI states
const chartType = ref<'svg' | 'apex'>('apex')
const showCancelModal = ref(false)
const showAddParticipantModal = ref(false)
const participantSearch = ref('')
const activeParticipantFilter = ref('all')
const currentParticipantPage = ref(1)
const participantsPerPage = ref(10)
const timerRunning = ref(false)

// New participant form
const newParticipant = ref({
  principal: '',
  amount: 0
})

// Computed properties
const distributionId = computed(() => route.params.id as string)

const statusColor = computed(() => {
  return getDistributionStatusColor(distributionStatus.value)
})

const statusDotColor = computed(() => {
  return getDistributionStatusDotColor(distributionStatus.value)
})

const statusText = computed(() => {
  return getDistributionStatusText(distributionStatus.value)
})

const canActivate = computed(() => {
  return details.value && canActivateDistribution(distributionStatus.value, hasEnoughBalance.value)
})

const hasEnoughBalance = computed(() => {
  if (!details.value || Number(contractBalance.value) === 0) return false
  return Number(contractBalance.value) >= parseTokenAmount(details.value.totalAmount, details.value.tokenInfo.decimals).toNumber()
})

const hasInsufficientBalance = computed(() => {
  if (!details.value) return false
  const insufficient = Number(contractBalance.value) < details.value.totalAmount
  console.log('insufficient', insufficient)
  return shouldShowInsufficientBalanceAlert(distributionStatus.value, insufficient)
})

const missingAmount = computed(() => {
  if (!details.value) return 0
  console.log('totalAmount', details.value.totalAmount)
  console.log('contractBalance', contractBalance.value, Number(details.value.totalAmount) - Number(contractBalance.value))
  return parseTokenAmount(Number(details.value.totalAmount) - Number(contractBalance.value), details.value.tokenInfo.decimals).toNumber()
})

const canPause = computed(() => {
  return details.value && canPauseDistribution(distributionStatus.value)
})

const canResume = computed(() => {
  return details.value && canResumeDistribution(distributionStatus.value)
})

const canInitialize = computed(() => {
  return details.value && canInitializeDistribution(distributionStatus.value)
})

const canCancel = computed(() => {
  return details.value && canCancelDistribution(distributionStatus.value, details.value?.allowCancel)
})

const canAddParticipants = computed(() => {
  return details.value?.recipientMode && !('SelfService' in details.value.recipientMode)
})

const canManageParticipants = computed(() => {
  return canAddParticipants.value
})

const participantGrowthRate = computed(() => {
  // Mock calculation - in real app, compare with previous period
  return Math.floor(Math.random() * 50)
})

const distributionProgress = computed(() => {
  if (!details.value || !stats.value) return 0
  return (Number(stats.value.totalDistributed) / Number(details.value.totalAmount)) * 100
})

const totalClaims = computed(() => {
  return claimHistory.value.length
})

const claimRate = computed(() => {
  if (!participants.value.length) return 0
  const participantsWithClaims = participants.value.filter(p => p.claimedAmount > 0).length
  return (participantsWithClaims / participants.value.length) * 100
})

const balanceHealthColor = computed(() => {
  if (!details.value || Number(contractBalance.value) === 0) return 'text-gray-500 dark:text-gray-400'
  
  const ratio = Number(contractBalance.value) / parseTokenAmount(details.value.totalAmount, details.value.tokenInfo.decimals).toNumber()
  if (ratio >= 0.8) return 'text-green-600 dark:text-green-400'
  if (ratio >= 0.5) return 'text-yellow-600 dark:text-yellow-400'
  return 'text-red-600 dark:text-red-400'
})

const balanceHealthText = computed(() => {
  if (!details.value || Number(contractBalance.value) === 0) return 'No balance'
  
  const ratio = Number(contractBalance.value) / parseTokenAmount(details.value.totalAmount, details.value.tokenInfo.decimals).toNumber()
  if (ratio >= 0.8) return 'Healthy'
  if (ratio >= 0.5) return 'Moderate'
  return 'Low balance'
})

const participantFilters = computed(() => {
  if (!participants.value.length) return []
  
  const all = participants.value.length
  const eligible = participants.value.filter(p => p.status === 'Eligible').length
  const registered = participants.value.filter(p => p.status === 'Registered').length
  const claimed = participants.value.filter(p => p.status === 'Claimed').length
  const partialClaim = participants.value.filter(p => p.status === 'PartialClaim').length
  
  return [
    { key: 'all', label: 'All', count: all },
    { key: 'eligible', label: 'Eligible', count: eligible },
    { key: 'registered', label: 'Registered', count: registered },
    { key: 'partialClaim', label: 'Partial Claims', count: partialClaim },
    { key: 'claimed', label: 'Fully Claimed', count: claimed }
  ]
})

const filteredParticipants = computed(() => {
  let filtered = participants.value
  
  // Apply search filter
  if (participantSearch.value) {
    const search = participantSearch.value.toLowerCase()
    filtered = filtered.filter(p => 
      p.principal.toLowerCase().includes(search) ||
      (p.note && p.note.toLowerCase().includes(search))
    )
  }
  
  // Apply status filter
  if (activeParticipantFilter.value !== 'all') {
    filtered = filtered.filter(p => p.status === activeParticipantFilter.value)
  }
  
  return filtered
})

const totalParticipantPages = computed(() => {
  return Math.ceil(filteredParticipants.value.length / participantsPerPage.value)
})

const paginatedParticipants = computed(() => {
  const start = (currentParticipantPage.value - 1) * participantsPerPage.value
  const end = start + participantsPerPage.value
  return filteredParticipants.value.slice(start, end)
})

const recentActivity = computed(() => {
  // Mock activity data - in real app, this would come from actual events
  return [
    {
      id: 1,
      description: 'Distribution activated',
      timestamp: Date.now() - 3600000,
      color: 'bg-green-400'
    },
    {
      id: 2,
      description: 'New participant registered',
      timestamp: Date.now() - 7200000,
      color: 'bg-blue-400'
    },
    {
      id: 3,
      description: 'Tokens claimed by user',
      timestamp: Date.now() - 10800000,
      color: 'bg-purple-400'
    }
  ]
})

// Vesting chart data (reusing from DistributionDetail)
const vestingScheduleData = computed(() => {
  if (!details.value) return []
  
  const data = []
  const startTime = Number(details.value.distributionStart) / 1_000_000
  const endTime = details.value.distributionEnd ? Number(details.value.distributionEnd) / 1_000_000 : startTime + (365 * 24 * 60 * 60 * 1000)
  
  // Add buffer points (2 days before start and after end)
  const bufferBefore = startTime - (2 * 24 * 60 * 60 * 1000)
  const bufferAfter = endTime + (2 * 24 * 60 * 60 * 1000)
  
  data.push({
    date: new Date(bufferBefore),
    amount: 0,
    cumulative: 0,
    percentage: 0,
    type: 'buffer' as const
  })
  
  // Initial unlock
  if (details.value.initialUnlockPercentage > 0) {
    data.push({
      date: new Date(startTime),
      amount: (Number(details.value.totalAmount) * Number(details.value.initialUnlockPercentage)) / 100,
      cumulative: (Number(details.value.totalAmount) * Number(details.value.initialUnlockPercentage)) / 100,
      percentage: details.value.initialUnlockPercentage,
      type: details.value.initialUnlockPercentage === 100 ? 'instant' as const : 'initial' as const
    })
  }
  
  // Vesting schedule points
  if (details.value.initialUnlockPercentage < 100) {
    switch (details.value.vestingSchedule?.constructor?.name) {
      case 'Linear':
        // Add linear vesting points
        const duration = Number(details.value.vestingSchedule.Linear?.duration || 0)
        const intervals = 10 // Show 10 points
        for (let i = 1; i <= intervals; i++) {
          const time = startTime + (duration / intervals * i) / 1_000_000
          const percentage = details.value.initialUnlockPercentage + ((100 - details.value.initialUnlockPercentage) * i / intervals)
          data.push({
            date: new Date(time),
            amount: (Number(details.value.totalAmount) * percentage) / 100,
            cumulative: (Number(details.value.totalAmount) * percentage) / 100,
            percentage,
            type: 'vesting' as const
          })
        }
        break
        
      case 'Cliff':
        // Add cliff points
        const cliffDuration = Number(details.value.vestingSchedule.Cliff?.cliffDuration || 0)
        const cliffPercentage = Number(details.value.vestingSchedule.Cliff?.cliffPercentage || 0)
        const vestingDuration = Number(details.value.vestingSchedule.Cliff?.vestingDuration || 0)
        
        // Cliff unlock
        const cliffTime = startTime + cliffDuration / 1_000_000
        data.push({
          date: new Date(cliffTime),
          amount: (Number(details.value.totalAmount) * cliffPercentage) / 100,
          cumulative: data[data.length - 1].cumulative + (Number(details.value.totalAmount) * cliffPercentage) / 100,
          percentage: details.value.initialUnlockPercentage + cliffPercentage,
          type: 'cliff' as const
        })
        
        // Linear vesting after cliff
        const remainingPercentage = 100 - details.value.initialUnlockPercentage - cliffPercentage
        const vestingIntervals = 8
        for (let i = 1; i <= vestingIntervals; i++) {
          const time = cliffTime + (Number(vestingDuration) / Number(vestingIntervals) * i) / 1_000_000
          const percentage = details.value.initialUnlockPercentage + cliffPercentage + (Number(remainingPercentage) * i / Number(vestingIntervals))
          data.push({
            date: new Date(time),
            amount: (Number(details.value.totalAmount) * percentage) / 100,
            cumulative: (Number(details.value.totalAmount) * percentage) / 100,
            percentage,
            type: 'vesting' as const
          })
        }
        break
    }
  }
  
  data.push({
    date: new Date(bufferAfter),
    amount: details.value.totalAmount,
    cumulative: details.value.totalAmount,
    percentage: 100,
    type: 'buffer' as const
  })
  
  return data
})

const hasCliffPeriod = computed(() => {
  return details.value?.vestingSchedule?.Cliff !== undefined
})

const hasInstantUnlock = computed(() => {
  return details.value?.initialUnlockPercentage === 100
})

const currentTimePosition = computed(() => {
  if (!details.value || vestingScheduleData.value.length === 0) return null
  
  const now = Date.now()
  const startTime = vestingScheduleData.value[0].date.getTime()
  const endTime = vestingScheduleData.value[vestingScheduleData.value.length - 1].date.getTime()
  
  if (now < startTime || now > endTime) return null
  
  return ((now - Number(startTime)) / (Number(endTime) - Number(startTime))) * 100
})

const cliffEndPosition = computed(() => {
  if (!hasCliffPeriod.value || !details.value || vestingScheduleData.value.length === 0) return null
  
  const cliffDuration = Number(details.value.vestingSchedule.Cliff?.cliffDuration || 0)
  const startTime = Number(details.value.distributionStart) / 1_000_000
  const cliffEndTime = startTime + Number(cliffDuration) / 1_000_000
  
  const chartStartTime = vestingScheduleData.value[0].date.getTime()
  const chartEndTime = vestingScheduleData.value[vestingScheduleData.value.length - 1].date.getTime()
  
  return ((Number(cliffEndTime) - Number(chartStartTime)) / (Number(chartEndTime) - Number(chartStartTime))) * 100
})

// Claims timeline chart
const claimTimelineData = computed(() => {
  if (!claimHistory.value.length) return []
  
  // Group claims by day
  const claimsByDay = new Map()
  claimHistory.value.forEach(claim => {
    const day = new Date(Number(claim.timestamp) / 1_000_000).toDateString()
    if (!claimsByDay.has(day)) {
      claimsByDay.set(day, { total: 0, count: 0 })
    }
    claimsByDay.get(day).total += parseTokenAmount(claim.amount, details.value?.tokenInfo.decimals).toNumber()
    claimsByDay.get(day).count += 1
  })
  
  const data = Array.from(claimsByDay.entries())
    .sort((a, b) => new Date(a[0]).getTime() - new Date(b[0]).getTime())
    .map(([day, stats]) => ({
      x: new Date(day).getTime(),
      y: stats.total
    }))
  
  return [{
    name: 'Daily Claims',
    data
  }]
})

const claimTimelineOptions = computed(() => ({
  chart: {
    type: 'area',
    height: 320,
    background: 'transparent',
    toolbar: { show: false },
    zoom: { enabled: false }
  },
  stroke: {
    curve: 'smooth',
    width: 3,
    colors: ['#3B82F6']
  },
  fill: {
    type: 'gradient',
    gradient: {
      shade: 'light',
      type: 'vertical',
      shadeIntensity: 0.4,
      gradientToColors: ['#93C5FD'],
      inverseColors: false,
      opacityFrom: 0.6,
      opacityTo: 0.1
    }
  },
  dataLabels: { enabled: false },
  xaxis: {
    type: 'datetime',
    labels: {
      style: {
        colors: '#6B7280',
        fontSize: '12px'
      }
    }
  },
  yaxis: {
    labels: {
      formatter: (value: number) => `${formatNumber(value)} ${details.value?.tokenInfo.symbol}`,
      style: {
        colors: '#6B7280',
        fontSize: '12px'
      }
    }
  },
  grid: {
    show: true,
    borderColor: '#F3F4F6',
    strokeDashArray: 0
  },
  tooltip: {
    theme: 'light',
    x: { format: 'dd MMM yyyy' },
    y: {
      formatter: (value: number) => `${formatNumber(value)} ${details.value?.tokenInfo.symbol}`
    }
  }
}))

// Methods
const fetchDetails = async () => {
  try {
    loading.value = true
    error.value = null
    
    const [distributionData, statsData, participantsData, claimsData] = await Promise.all([
      DistributionService.getDistributionDetails(distributionId.value),
      DistributionService.getDistributionStats(distributionId.value),
      DistributionService.getAllParticipants(distributionId.value),
      DistributionService.getClaimHistory(distributionId.value)
    ])
    
    details.value = distributionData
    stats.value = statsData
    participants.value = participantsData
    claimHistory.value = claimsData
    
    // Fetch additional admin data
    await Promise.all([
      fetchContractBalance(),
      fetchTimerStatus(),
      fetchDistributionStatus()
    ])
    
  } catch (err) {
    console.error('Error fetching distribution details:', err)
    error.value = err instanceof Error ? err.message : 'Failed to load distribution details'
  } finally {
    loading.value = false
  }
}

const fetchContractBalance = async () => {
  console.log('details.value', details.value)
  try {
    const token: Token = {
      canisterId: details.value.tokenInfo.canisterId.toString(),
      symbol: details.value.tokenInfo.symbol,
      name: details.value.tokenInfo.name,
      decimals: details.value.tokenInfo.decimals || 8,
      fee: 0,
      standards: [],
      metrics: {
        price: 0,
        volume: 0,
        marketCap: 0,
        totalSupply: 0
      }
    }
    const [balance, canisterInfo] = await Promise.all([
      DistributionService.getContractBalance(token, distributionId.value),
      DistributionService.getCanisterInfo(distributionId.value)
    ])
    contractBalance.value = Number(balance)
    cyclesBalance.value = Number(canisterInfo.cyclesBalance)
  } catch (err) {
    console.error('Error fetching contract balance:', err)
  }
}

const checkBalance = async () => {
  try {
    checkingBalance.value = true
    await fetchContractBalance()
    toast.success('Balance updated successfully')
  } catch (err) {
    toast.error('Error checking balance: ' + err)
    console.error('Error checking balance:', err)
  } finally {
    checkingBalance.value = false
  }
}

const fetchTimerStatus = async () => {
  try {
    const status = await DistributionService.getTimerStatus(distributionId.value)
    timerRunning.value = status.isRunning
  } catch (err) {
    console.error('Error fetching timer status:', err)
  }
}

const fetchDistributionStatus = async () => {
  try {
    const status = await DistributionService.getDistributionStatus(distributionId.value)
    distributionStatus.value = status
  } catch (err) {
    console.error('Error fetching distribution status:', err)
  }
}

const refreshData = async () => {
  refreshing.value = true
  await fetchDetails()
  refreshing.value = false
}

// Admin actions
const activateDistribution = async () => {
  try {
    activating.value = true
    const result = await DistributionService.activateDistribution(distributionId.value)
    if ('err' in result) {
      throw new Error(result.err)
    }else{
      toast.success('Distribution activated')
    }
    await Promise.all([refreshData(), fetchDistributionStatus()])
  } catch (err) {
    toast.error('' + err)
    console.error('Error activating distribution:', err)
  } finally {
    activating.value = false
  }
}

//Initialize distribution
const initializeDistribution = async () => {
  try {
    initializing.value = true
    const result = await DistributionService.initializeContract(distributionId.value)
    if ('err' in result) {
      throw new Error(result.err)
    }else{
      toast.success('Distribution initialized')
    }
    await refreshData()
  } catch (err) {
    toast.error('' + err)
    console.error('Error initializing distribution:', err)
  } finally {
    initializing.value = false
  }
}

const pauseDistribution = async () => {
  try {
    pausing.value = true
    const result = await DistributionService.pauseDistribution(distributionId.value)
    if ('err' in result) {
      throw new Error(result.err)
    }
    await refreshData()
  } catch (err) {
    console.error('Error pausing distribution:', err)
  } finally {
    pausing.value = false
  }
}

const resumeDistribution = async () => {
  try {
    resuming.value = true
    const result = await DistributionService.resumeDistribution(distributionId.value)
    if ('err' in result) {
      throw new Error(result.err)
    }else{
      toast.success('Distribution resumed')
    }
    await Promise.all([refreshData(), fetchDistributionStatus()])
  } catch (err) {
    toast.error(''+err)
    console.error('Error resuming distribution:', err)
  } finally {
    resuming.value = false
  }
}

const confirmCancelDistribution = () => {
  showCancelModal.value = true
}

const cancelDistribution = async () => {
  try {
    cancelling.value = true
    const result = await DistributionService.cancelDistribution(distributionId.value)
    if ('err' in result) {
      throw new Error(result.err)
    }else{
      toast.success('Distribution cancelled')
    }
    showCancelModal.value = false
    await Promise.all([refreshData(), fetchDistributionStatus()])
  } catch (err) {
    toast.error('' + err)
    console.error('Error cancelling distribution:', err)
  } finally {
    cancelling.value = false
  }
}

const startTimer = async () => {
  try {
    startingTimer.value = true
    await DistributionService.startTimer(distributionId.value)
    toast.success('Timer started')
    await fetchTimerStatus()
  } catch (err) {
    toast.error('Error starting timer: ' + err)
    console.error('Error starting timer:', err)
  } finally {
    startingTimer.value = false
  }
}

const stopTimer = async () => {
  try {
    stoppingTimer.value = true
    await DistributionService.cancelTimer(distributionId.value)
    toast.success('Timer stopped')
    await fetchTimerStatus()
  } catch (err) {
    toast.error('Error stopping timer: ' + err)
    console.error('Error stopping timer:', err)
  } finally {
    stoppingTimer.value = false
  }
}

const addParticipant = async () => {
  try {
    addingParticipant.value = true
    
    // Convert amount to proper format (multiply by decimals if needed)
    const amount = BigInt(Math.floor(newParticipant.value.amount * 100_000_000)) // Assuming 8 decimals
    const participants = [[newParticipant.value.principal, amount]] as [string, bigint][]
    
    const result = await DistributionService.addParticipants(distributionId.value, participants)
    if ('err' in result) {
      throw new Error(result.err)
    }else{
      toast.success('Participant added')
    }
    showAddParticipantModal.value = false
    newParticipant.value = { principal: '', amount: 0 }
    await refreshData()
  } catch (err) {
    toast.error('Error adding participant: ' + err)
    console.error('Error adding participant:', err)
  } finally {
    addingParticipant.value = false
  }
}

// Utility methods
const formatDate = (timestamp: bigint | number) => {
  const date = new Date(typeof timestamp === 'bigint' ? Number(timestamp) / 1_000_000 : Number(timestamp))
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

const formatNumber = (value: number | bigint) => {
  return new Intl.NumberFormat().format(Math.floor(Number(value)))
}

const formatRelativeTime = (timestamp: number) => {
  const now = Date.now()
  const diff = now - timestamp
  
  if (diff < 60000) return 'Just now'
  if (diff < 3600000) return `${Math.floor(Number(diff) / 60000)}m ago`
  if (diff < 86400000) return `${Math.floor(Number(diff) / 3600000)}h ago`
  return `${Math.floor(Number(diff) / 86400000)}d ago`
}

const truncateAddress = (address: string) => {
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

const copyToClipboard = async (text: string) => {
  try {
    await navigator.clipboard.writeText(text)
  } catch (err) {
    console.error('Failed to copy to clipboard:', err)
  }
}

const getParticipantStatusColor = (status: string) => {
  switch (status) {
    case 'Eligible':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400'
    case 'Registered':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
    case 'PartialClaim':
      return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-400'
    case 'Claimed':
      return 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
  }
}

const getParticipantStatusText = (status: string) => {
  switch (status) {
    case 'Eligible': return 'Eligible'
    case 'Registered': return 'Registered'
    case 'PartialClaim': return 'Partial'
    case 'Claimed': return 'Claimed'
    default: return status
  }
}

const viewParticipantDetails = (participant: Participant) => {
  // Navigate to participant detail view or open modal
  console.log('View participant:', participant)
}

const editParticipant = (participant: Participant) => {
  // Open edit modal
  console.log('Edit participant:', participant)
}

// Lifecycle
onMounted(() => {
  fetchDetails()
})
</script>

<style scoped>
/* Custom animations and transitions */
.animate-pulse {
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: .5;
  }
}

.animate-spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

/* Smooth transitions */
.transition-colors {
  transition-property: color, background-color, border-color, text-decoration-color, fill, stroke;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 150ms;
}

/* Custom scrollbar */
.overflow-x-auto::-webkit-scrollbar {
  height: 4px;
}

.overflow-x-auto::-webkit-scrollbar-track {
  background: #f1f5f9;
}

.overflow-x-auto::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 2px;
}

.dark .overflow-x-auto::-webkit-scrollbar-track {
  background: #1e293b;
}

.dark .overflow-x-auto::-webkit-scrollbar-thumb {
  background: #475569;
}
</style>