<template>
  <AdminLayout>
    <!-- Breadcrumb -->
    <Breadcrumb :items="breadcrumbItems" />
    
  <div v-if="dao" class="space-y-6">
    <!-- Header -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm p-6">
      <div class="flex items-start justify-between mb-4">
        <div class="flex items-center space-x-4">
          <div class="p-3 bg-gradient-to-r from-yellow-400 to-amber-500 rounded-lg shadow-sm">
            <Building2Icon class="h-8 w-8 text-white" />
          </div>
          <div>
            <div class="flex items-center space-x-3 mb-2">
              <h1 class="text-2xl font-bold text-gray-900 dark:text-white">{{ dao.name }}</h1>
              <GovernanceTypeBadge :type="dao.governanceType" />
              <span v-if="dao.isPublic" class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200">
                <GlobeIcon class="h-3 w-3 mr-1" />
                Public
              </span>
            </div>
            <p class="text-gray-600 dark:text-gray-400">{{ dao.description }}</p>
            <div class="flex items-center space-x-4 mt-2">
              <div class="text-sm text-gray-500 dark:text-gray-400 flex items-center space-x-2">
                <div>Token: {{ dao.tokenConfig.symbol }} ({{ dao.tokenConfig.name }}) </div>
                <!-- <div class="flex items-center space-x-2">
                  <span class="text-xs font-mono bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded">
                    {{ (dao.tokenConfig.canisterId) }}
                  </span>
                  <CopyIcon :data="dao.tokenConfig.canisterId" msg="canister ID" :size="14" />
                </div> -->
              </div>
              <span class="text-sm text-gray-500 dark:text-gray-400">
                Created: {{ formatDate(Number(dao.createdAt)) }}
              </span>
              
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex items-center space-x-3">
          <button 
            v-if="dao.stakingEnabled"
            @click="showStakeModal = true"
            v-auth-required="{ message: 'Please connect your wallet to continue' }"
            class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg hover:from-purple-700 hover:to-purple-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 transition-all duration-200"
          >
            <CoinsIcon class="h-4 w-4 mr-2" />
            Stake {{ dao?.tokenConfig.symbol }}
          </button>
          
          <button 
            @click="$router.push(`/dao/${dao.id}/proposals`)"
            class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-yellow-600 to-amber-600 text-white rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
          >
            <VoteIcon class="h-4 w-4 mr-2" />
            View Proposals
          </button>
          
          <button 
            @click="showCreateProposalModal = true"
            v-auth-required="{ message: 'Please connect your wallet to continue' }"
            class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-green-600 to-emerald-600 text-white rounded-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 transition-all duration-200"
          >
            <PlusIcon class="h-4 w-4 mr-2" />
            Create Proposal
          </button>
        </div>
      </div>

      <!-- Emergency State Warning -->
      <div v-if="dao.emergencyState.paused" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 mb-4">
        <div class="flex items-center">
          <AlertTriangleIcon class="h-5 w-5 text-red-500 mr-2" />
          <div>
            <p class="font-medium text-red-800 dark:text-red-200">DAO Operations Paused</p>
            <p class="text-sm text-red-600 dark:text-red-400">
              {{ dao.emergencyState.reason || 'Emergency pause is active' }}
            </p>
          </div>
        </div>
      </div>

      <!-- Tags -->
      <div v-if="dao.tags.length > 0" class="flex flex-wrap gap-2">
        <span 
          v-for="tag in dao.tags" 
          :key="tag"
          class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200"
        >
          {{ tag }}
        </span>
      </div>
    </div>

    <!-- Statistics Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <StatCard 
        title="Total Members"
        :value="dao.stats.totalMembers"
        :icon="UsersIcon"
        color="blue"
      />
      <StatCard 
        title="Total Staked"
        :value="formatTokenAmountLabel(parseTokenAmount(Number(dao.stats.totalStaked), dao.tokenConfig.decimals).toNumber(), dao.tokenConfig.symbol)"
        :icon="CoinsIcon"
        color="purple"
      />
      <StatCard 
        title="Active Proposals"
        :value="dao.stats.activeProposals"
        :icon="VoteIcon"
        color="green"
      />
      <StatCard 
        title="Total Proposals"
        :value="dao.stats.totalProposals"
        :icon="FileTextIcon"
        color="orange"
      />
    </div>

    <!-- Main Content Tabs -->
    <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-sm">
      <!-- Tab Navigation -->
      <div class="border-b border-gray-200 dark:border-gray-700">
        <nav class="flex space-x-8 px-6" aria-label="Tabs">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm transition-colors',
              activeTab === tab.id
                ? 'border-yellow-500 text-yellow-600 dark:text-yellow-400'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
            ]"
          >
            <component :is="tab.icon" class="h-4 w-4 inline mr-2" />
            {{ tab.name }}
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="p-6">
        <!-- Overview Tab -->
        <div v-if="activeTab === 'overview'" class="space-y-6">
          <!-- Main Information Grid - 3 Columns -->
          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Governance Configuration -->
            <div class="bg-gradient-to-br from-purple-50 to-blue-50 dark:from-purple-900/20 dark:to-blue-900/20 rounded-lg p-5 border border-purple-200 dark:border-purple-800">
              <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <SettingsIcon class="h-5 w-5 mr-2 text-purple-500" />
                Governance Config
              </h3>
              <div class="space-y-3">
                <!-- Governance Level -->
                <div class="flex justify-between items-center">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Governance Level</span>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200">
                    {{ formatGovernanceLevel(dao.governanceLevel) }}
                  </span>
                </div>
                <!-- Governance Type -->
                <div class="flex justify-between items-center">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Governance Type</span>
                  <span class="text-sm font-medium">{{ dao.governanceType || 'Liquid' }}</span>
                </div>
                <!-- Staking Status -->
                <div class="flex justify-between items-center">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Staking Enabled</span>
                  <span :class="[
                    'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                    dao.stakingEnabled 
                      ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' 
                      : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200'
                  ]">
                    {{ dao.stakingEnabled ? 'Yes' : 'No' }}
                  </span>
                </div>
                <!-- Total Members -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Total Members</span>
                  <span class="text-sm font-medium">{{ dao.stats?.totalMembers || 0 }}</span>
                </div>
                <!-- Total Staked -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Total Staked</span>
                  <span class="text-sm font-medium text-purple-600 dark:text-purple-400">
                    {{ formatTokenAmountLabel(parseTokenAmount(Number(dao.stats?.totalStaked || 0), dao.tokenConfig.decimals).toNumber(), dao.tokenConfig.symbol) }}
                  </span>
                </div>
                <!-- Total Voting Power -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Total Voting Power</span>
                  <span class="text-sm font-medium text-blue-600 dark:text-blue-400">
                    {{ formatTokenAmountLabel(parseTokenAmount(Number(dao.stats?.totalVotingPower || 0), dao.tokenConfig.decimals).toNumber(), 'VP') }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Voting Parameters -->
            <div class="bg-gradient-to-br from-yellow-50 to-orange-50 dark:from-yellow-900/20 dark:to-orange-900/20 rounded-lg p-5 border border-yellow-200 dark:border-yellow-800">
              <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <VoteIcon class="h-5 w-5 mr-2 text-yellow-500" />
                Voting Parameters
              </h3>
              <div class="space-y-3">
                <!-- Quorum Required -->
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Quorum Required</span>
                    <div class="ml-1 group relative">
                      <InfoIcon class="h-3 w-3 text-gray-400 cursor-help" />
                      <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        Minimum participation needed
                      </div>
                    </div>
                  </div>
                  <span class="text-sm font-medium text-yellow-600 dark:text-yellow-400">
                    {{ formatBasisPoints(dao.systemParams.quorum_percentage) }}%
                  </span>
                </div>
                <!-- Approval Threshold -->
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Approval Threshold</span>
                    <div class="ml-1 group relative">
                      <InfoIcon class="h-3 w-3 text-gray-400 cursor-help" />
                      <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        Minimum approval to pass
                      </div>
                    </div>
                  </div>
                  <span class="text-sm font-medium text-orange-600 dark:text-orange-400">
                    {{ formatBasisPoints(dao.systemParams.approval_threshold) }}%
                  </span>
                </div>
                <!-- Voting Period -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Voting Period</span>
                  <span class="text-sm font-medium">{{ formatDuration(Number(dao.systemParams.max_voting_period)) }}</span>
                </div>
                <!-- Min Voting Period -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Min Voting Period</span>
                  <span class="text-sm font-medium">{{ formatDuration(Number(dao.systemParams.min_voting_period)) }}</span>
                </div>
                <!-- Timelock Duration -->
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Timelock Duration</span>
                    <div class="ml-1 group relative">
                      <InfoIcon class="h-3 w-3 text-gray-400 cursor-help" />
                      <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        Delay before execution
                      </div>
                    </div>
                  </div>
                  <span class="text-sm font-medium">{{ formatDuration(Number(dao.systemParams.timelock_duration)) }}</span>
                </div>
                <!-- Proposal Threshold -->
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Proposal Threshold</span>
                    <div class="ml-1 group relative">
                      <InfoIcon class="h-3 w-3 text-gray-400 cursor-help" />
                      <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        Voting power needed to create proposal
                      </div>
                    </div>
                  </div>
                  <span class="text-sm font-medium">{{ formatTokenAmountLabel(Number(dao.systemParams.proposal_vote_threshold), 'VP') }}</span>
                </div>
                <!-- Proposal Deposit -->
                <div class="flex justify-between items-center">
                  <div class="flex items-center">
                    <span class="text-sm text-gray-600 dark:text-gray-400">Proposal Deposit</span>
                    <div class="ml-1 group relative">
                      <InfoIcon class="h-3 w-3 text-gray-400 cursor-help" />
                      <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                        Deposit required when creating proposal
                      </div>
                    </div>
                  </div>
                  <span class="text-sm font-medium text-yellow-600 dark:text-yellow-400">
                    {{ formatTokenAmountLabel(Number(dao.systemParams.proposal_submission_deposit), dao.tokenConfig.symbol) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- DAO Statistics -->
            <div class="bg-gradient-to-br from-indigo-50 to-purple-50 dark:from-indigo-900/20 dark:to-purple-900/20 rounded-lg p-5 border border-indigo-200 dark:border-indigo-800">
              <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
                <BarChartIcon class="h-5 w-5 mr-2 text-indigo-500" />
                DAO Statistics
              </h3>
              <div class="space-y-3">
                <!-- Creation Date -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Created</span>
                  <span class="text-sm font-medium">{{ formatDate(dao.createdAt) }}</span>
                </div>
                <!-- Total Proposals -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Total Proposals</span>
                  <span class="text-sm font-medium text-indigo-600 dark:text-indigo-400">{{ dao.stats?.totalProposals || 0 }}</span>
                </div>
                <!-- Active Proposals -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Active Proposals</span>
                  <span class="text-sm font-medium text-orange-600 dark:text-orange-400">{{ dao.stats?.activeProposals || 0 }}</span>
                </div>
                <!-- Executed Proposals -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Executed Proposals</span>
                  <span class="text-sm font-medium text-green-600 dark:text-green-400">{{ dao.stats?.executedProposals || 0 }}</span>
                </div>
                <!-- Treasury Balance -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Treasury Balance</span>
                  <span class="text-sm font-medium text-purple-600 dark:text-purple-400">
                    {{ formatTokenAmountLabel(Number(dao.stats?.treasuryBalance || 0), dao.tokenConfig.symbol) }}
                  </span>
                </div>
                <!-- Transfer Fee -->
                <div class="flex justify-between">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Transfer Fee</span>
                  <span class="text-sm font-medium text-green-600 dark:text-green-400">
                    {{ parseTokenAmount(dao.systemParams.transfer_fee, dao.tokenConfig.decimals) }} {{ dao.tokenConfig.symbol }}
                  </span>
                </div>
                <!-- Emergency Status -->
                <div class="flex justify-between items-center">
                  <span class="text-sm text-gray-600 dark:text-gray-400">Emergency Mode</span>
                  <span :class="[
                    'inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium',
                    dao.emergencyState 
                      ? 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200' 
                      : 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'
                  ]">
                    {{ dao.emergencyState ? 'Active' : 'Normal' }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Recent Activity -->
          <!-- <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-4">
            <h3 class="font-semibold text-gray-900 dark:text-white mb-4 flex items-center">
              <ActivityIcon class="h-5 w-5 mr-2 text-gray-500" />
              Recent Activity
            </h3>
            <div class="space-y-3">
              <div v-if="recentProposals.length === 0" class="text-center py-8">
                <p class="text-gray-500 dark:text-gray-400">No recent activity</p>
              </div>
              <div v-else>
                <div 
                  v-for="proposal in recentProposals.slice(0, 5)" 
                  :key="proposal.id"
                  class="flex items-center justify-between py-2 border-b border-gray-200 dark:border-gray-600 last:border-b-0"
                >
                  <div class="flex items-center space-x-3">
                    <div class="p-2 bg-white dark:bg-gray-600 rounded-lg">
                      <VoteIcon class="h-4 w-4 text-gray-500" />
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900 dark:text-white">
                        {{ proposal.payload.title }}
                      </p>
                      <p class="text-xs text-gray-500 dark:text-gray-400">
                        {{ formatDate(proposal.timestamp) }}
                      </p>
                    </div>
                  </div>
                  <ProposalStatusBadge :status="proposal.state" />
                </div>
              </div>
            </div>
          </div> -->

          <!-- Proposals Section -->
          <div class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6 mt-6">
            <div class="flex items-center justify-between mb-6">
              <h3 class="text-xl font-semibold text-gray-900 dark:text-white flex items-center">
                <VoteIcon class="h-6 w-6 mr-2 text-yellow-500" />
                Recent Proposals
              </h3>
              <div class="flex items-center space-x-3">
                <button
                  @click="showCreateProposalModal = true"
                  v-auth-required="{ message: 'Please connect your wallet to continue' }"
                  class="inline-flex items-center px-3 py-2 bg-gradient-to-r from-yellow-500 to-amber-600 text-white rounded-lg hover:from-yellow-600 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 text-sm"
                >
                  <PlusIcon class="h-4 w-4 mr-1" />
                  New Proposal
                </button>
                <button
                  @click="$router.push(`/dao/${dao.id}/proposals`)"
                  class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 text-sm"
                >
                  View All
                  <ChevronRightIcon class="h-4 w-4 ml-1" />
                </button>
              </div>
            </div>
            
            <div v-if="isLoadingProposals" class="flex justify-center py-8">
              <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-yellow-500"></div>
            </div>
            
            <div v-else-if="recentProposals.length === 0" class="text-center py-12">
              <VoteIcon class="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h4 class="text-lg font-medium text-gray-900 dark:text-white mb-2">No Proposals Yet</h4>
              <p class="text-gray-500 dark:text-gray-400 mb-6">
                Be the first to create a proposal and start the governance process.
              </p>
              <button
                @click="showCreateProposalModal = true"
                class="inline-flex items-center px-4 py-2 bg-gradient-to-r from-yellow-500 to-amber-600 text-white rounded-lg hover:from-yellow-600 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
              >
                <PlusIcon class="h-5 w-5 mr-2" />
                Create First Proposal
              </button>
            </div>
            
            <div v-else class="space-y-4">
              <ProposalCard
                v-for="proposal in recentProposals.slice(0, 6)"
                :key="proposal.id"
                :proposal="proposal"
                :dao="dao"
                @click="$router.push(`/dao/${dao.id}/proposal/${proposal.id}`)"
                class="hover:shadow-md transition-shadow cursor-pointer"
              />
              
              <div v-if="recentProposals.length > 6" class="text-center pt-4 border-t border-gray-200 dark:border-gray-700">
                <button
                  @click="$router.push(`/dao/${dao.id}/proposals`)"
                  class="inline-flex items-center px-4 py-2 text-yellow-600 dark:text-yellow-400 hover:text-yellow-700 dark:hover:text-yellow-300 transition-colors"
                >
                  View {{ recentProposals.length - 6 }} more proposals
                  <ChevronRightIcon class="h-4 w-4 ml-1" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Enhanced Staking Tab -->
        <div v-else-if="activeTab === 'member'" class="mt-6 space-y-6">
          <!-- Use the improved StakingDashboard component -->
          <StakingDashboard
            v-if="dao"
            :dao-id="dao.id"
            :token-symbol="dao.tokenConfig.symbol"
            :user-balance="memberInfo?.stakedAmount || BigInt(0)"
            @stake-success="handleStakeSuccess"
            @unstake-success="handleUnstakeSuccess"
          />


          <!-- User Activity Timeline Integration -->
          <UserActivityTimeline 
            v-if="dao"
            :dao="dao"
          />

          <!-- Not a Member State -->
          <div v-if="!memberInfo || Number(memberInfo.stakedAmount) === 0" class="text-center py-8">
            <UsersIcon class="h-16 w-16 mx-auto text-gray-400 mb-4" />
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-2">Not a Member</h3>
            <p class="text-gray-500 dark:text-gray-400 mb-6">
              You need to stake tokens to become a member and participate in governance.
            </p>
            <button 
              v-if="dao.stakingEnabled"
              @click="showStakeModal = true"
              v-auth-required="{ message: 'Please connect your wallet to continue' }"
              class="inline-flex items-center px-6 py-3 bg-gradient-to-r from-yellow-600 to-amber-600 text-white rounded-lg hover:from-yellow-700 hover:to-amber-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500 transition-all duration-200"
            >
              <CoinsIcon class="h-5 w-5 mr-2" />
              Stake {{ dao?.tokenConfig.symbol }}
            </button>
          </div>
        </div>
      </div>
    </div>
    </div>

  <!-- Loading State -->
  <div v-else-if="isLoading" class="text-center py-12">
    <div class="inline-flex items-center px-6 py-3 border border-transparent rounded-full shadow-sm text-sm font-medium text-white bg-gradient-to-r from-yellow-600 to-amber-600">
      <div class="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-white mr-3"></div>
      Loading DAO...
    </div>
  </div>

  <!-- Error State -->
  <div v-else class="text-center py-12">
    <div class="text-red-500 mb-4">
      <AlertCircleIcon class="h-12 w-12 mx-auto" />
    </div>
    <p class="text-red-600 dark:text-red-400 text-lg font-medium mb-4">{{ error }}</p>
    <button 
      @click="fetchData"
      class="inline-flex items-center px-4 py-2 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
    >
      <RefreshCcwIcon class="h-4 w-4 mr-2" />
      Try Again
    </button>
  </div>
    <!-- Modals -->
    <StakeModal 
      v-if="showStakeModal"
      :dao="dao"
      @close="showStakeModal = false"
      @success="handleStakeSuccess"
    />

    <UnstakeModal
      v-if="showUnstakeModal"
      :dao="dao"
      :member-info="memberInfo"
      @close="showUnstakeModal = false"
      @success="handleUnstakeSuccess"
    />

    <DelegationModal
      v-if="showDelegationModal"
      :dao="dao"
      :member-info="memberInfo"
      @close="showDelegationModal = false"
      @success="handleDelegationSuccess"
    />

    <CreateProposalModal
      v-if="showCreateProposalModal"
      :dao="dao"
      @close="showCreateProposalModal = false"
      @success="handleProposalSuccess"
    />

    <!-- Enhanced Staking Modals -->
    <StakeModal
      v-if="showStakeModal && dao"
      :dao="dao"
      @close="showStakeModal = false"
      @success="handleStakeSuccess"
      @confirm="handleStakeConfirm"
      :token-symbol="dao?.tokenConfig.symbol"
      :user-balance="memberInfo?.stakedAmount"
      :loading="false"
    />
  

  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { DAOService } from '@/api/services/dao'
import {
  Building2Icon,
  UsersIcon,
  CoinsIcon,
  VoteIcon,
  FileTextIcon,
  PlusIcon,
  SettingsIcon,
  ActivityIcon,
  GlobeIcon,
  ChevronRightIcon,
  AlertTriangleIcon,
  AlertCircleIcon,
  RefreshCcwIcon,
  InfoIcon,
  BarChartIcon
} from 'lucide-vue-next'
import GovernanceTypeBadge from '@/components/dao/GovernanceTypeBadge.vue'
import StatCard from '@/components/dao/StatCard.vue'
import ProposalCard from '@/components/dao/ProposalCard.vue'
import StakeModal from '@/components/dao/StakeModal.vue'
import UnstakeModal from '@/components/dao/UnstakeModal.vue'
import DelegationModal from '@/components/dao/DelegationModal.vue'
import CreateProposalModal from '@/components/dao/CreateProposalModal.vue'
import StakingDashboard from '@/components/dao/StakingDashboard.vue'
import UserActivityTimeline from '@/components/dao/UserActivityTimeline.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { formatTokenAmountLabel, parseTokenAmount } from '@/utils/token'
const route = useRoute()
const daoService = DAOService.getInstance()

// State
const dao = ref<any>(null)
const memberInfo = ref<any | null>(null)
const recentProposals = ref<any[]>([])
const isLoading = ref(true)
const isLoadingProposals = ref(false)
const error = ref<string | null>(null)
const activeTab = ref('overview')
const showStakeModal = ref(false)
const showUnstakeModal = ref(false)
const showDelegationModal = ref(false)
const showCreateProposalModal = ref(false)

// Enhanced Staking State - add missing variables
const stakingSummary = ref(null)
const stakeEntries = ref([])
const isLoadingStaking = ref(false)
const entriesFilter = ref('all')

// Activity tracking
const userActivities = ref([])
const isLoadingActivity = ref(false)
const hasMoreActivities = ref(false)
const currentActivityOffset = ref(0)
const selectedActivityFilter = ref('all')

// Tabs configuration
const tabs = [
  { id: 'overview', name: 'Overview', icon: FileTextIcon },
  { id: 'member', name: 'My Membership', icon: UsersIcon }
]

// Computed
const breadcrumbItems = computed(() => [
  { label: 'DAOs', to: '/dao' },
  { label: dao.value?.name || 'Loading...' }
])

// Methods
const fetchData = async () => {
  isLoading.value = true
  error.value = null

  try {
    const daoId = route.params.id as string
    
    // Fetch DAO details
    const daoData = await daoService.getDAO(daoId)
    console.log('daoData', daoData)
    if (!daoData) {
      error.value = 'DAO not found'
      return
    }
    dao.value = daoData

    // Fetch member info (if user is connected)
    try {
      const memberData = await daoService.getMyMemberInfo(daoId)
      memberInfo.value = memberData
    } catch (err) {
      // User might not be a member, that's okay
      memberInfo.value = null
    }

    // Fetch recent proposals
    try {
      const proposals = await daoService.getProposals(daoId)
      recentProposals.value = proposals.slice(0, 10)
    } catch (err) {
      console.error('Error fetching proposals:', err)
      recentProposals.value = []
    }

  } catch (err) {
    console.error('Error fetching DAO:', err)
    error.value = 'Failed to load DAO details'
  } finally {
    isLoading.value = false
  }
}

const formatDate = (timestamp: number | string): string => {
  const date = new Date(Number(timestamp)/1000000)
  return date.toLocaleDateString('en-US', { 
    year: 'numeric',
    month: 'short', 
    day: 'numeric'
  })
}

const formatDuration = (seconds: number): string => {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`
  } else {
    return `${Math.floor(seconds / 60)} minute${Math.floor(seconds / 60) > 1 ? 's' : ''}`
  }
}

// Convert basis points to percentage (e.g., 2000 -> 20)
const formatBasisPoints = (basisPoints: number): string => {
  return (Number(basisPoints) / 100).toFixed(1)
}

// Format governance level for display
const formatGovernanceLevel = (level: string): string => {
  const levelMap = {
    'motion-only': 'Motion Only',
    'semi-managed': 'Semi-Managed', 
    'fully-managed': 'Fully Managed'
  }
  return levelMap[level as keyof typeof levelMap] || level
}

// Format principal for display
const formatPrincipal = (principal: string): string => {
  if (principal.length <= 20) return principal
  return shortPrincipal(principal)
}



const handleStakeSuccess = () => {
  showStakeModal.value = false
  // Refresh member info
  fetchData()
}

const handleUnstakeSuccess = () => {
  showUnstakeModal.value = false
  // Refresh member info
  fetchData()
}

const handleDelegationSuccess = () => {
  showDelegationModal.value = false
  // Refresh member info
  fetchData()
}

const handleProposalSuccess = () => {
  showCreateProposalModal.value = false
  // Refresh proposals
  fetchData()
}

// Enhanced Staking Methods
const refreshStakingData = async () => {
  if (!dao.value) return
  
  isLoadingStaking.value = true
  try {
    // Mock data for now - replace with actual API calls
    const mockSummary = {
      totalStaked: BigInt(1000 * 100_000_000),
      totalVotingPower: BigInt(2000 * 100_000_000),
      activeEntries: 2,
      tierBreakdown: [
        ['Medium Term', BigInt(1000 * 100_000_000), BigInt(2000 * 100_000_000)],
        ['Liquid Staking', BigInt(500 * 100_000_000), BigInt(500 * 100_000_000)]
      ],
      nextUnlock: {
        time: BigInt(Date.now() + 86400000 * 30) * BigInt(1_000_000),
        amount: BigInt(1000 * 100_000_000),
        entryId: 1
      },
      availableToUnstake: BigInt(500 * 100_000_000),
      legacyStakeExists: false
    }
    
    const mockEntries = [
      {
        id: 1,
        staker: 'user-principal',
        amount: BigInt(1000 * 100_000_000),
        stakedAt: BigInt(Date.now() - 86400000) * BigInt(1_000_000),
        lockPeriod: 90 * 86400,
        unlockTime: BigInt(Date.now() + 86400000 * 89) * BigInt(1_000_000),
        multiplier: 2.0,
        votingPower: BigInt(2000 * 100_000_000),
        tier: {
          id: 2,
          name: 'Medium Term',
          minStake: BigInt(5000 * 100_000_000),
          lockPeriod: 90 * 86400,
          multiplier: 2.0,
          maxCapPerEntry: null,
          globalCap: null,
          description: '90-day lock, 2x multiplier'
        },
        isActive: true,
        blockIndex: 12345
      },
      {
        id: 2,
        staker: 'user-principal',
        amount: BigInt(500 * 100_000_000),
        stakedAt: BigInt(Date.now() - 86400000 * 7) * BigInt(1_000_000),
        lockPeriod: 0,
        unlockTime: BigInt(Date.now() - 86400000 * 7) * BigInt(1_000_000),
        multiplier: 1.0,
        votingPower: BigInt(500 * 100_000_000),
        tier: {
          id: 0,
          name: 'Liquid Staking',
          minStake: BigInt(100 * 100_000_000),
          lockPeriod: 0,
          multiplier: 1.0,
          maxCapPerEntry: null,
          globalCap: null,
          description: 'Instant liquidity, base voting power'
        },
        isActive: true,
        blockIndex: 12340
      }
    ]
    
    stakingSummary.value = mockSummary
    stakeEntries.value = mockEntries
  } catch (err) {
    console.error('Error fetching staking data:', err)
  } finally {
    isLoadingStaking.value = false
  }
}

// Computed properties for enhanced staking
const tierBreakdown = computed(() => {
  if (!stakingSummary.value?.tierBreakdown) return []
  
  return stakingSummary.value.tierBreakdown.map(([name, stakedAmount, votingPower]: [string, bigint, bigint]) => {
    const percentage = stakingSummary.value.totalStaked > 0 
      ? (Number(stakedAmount) / Number(stakingSummary.value.totalStaked)) * 100 
      : 0
    
    return {
      name,
      stakedAmount,
      votingPower,
      percentage
    }
  }).sort((a: any, b: any) => b.percentage - a.percentage)
})

const upcomingUnlocks = computed(() => {
  if (!stakingSummary.value?.nextUnlock) return []
  return stakingSummary.value.nextUnlock ? [stakingSummary.value.nextUnlock] : []
})

const filteredStakeEntries = computed(() => {
  switch (entriesFilter.value) {
    case 'active':
      return stakeEntries.value.filter(entry => entry.isActive)
    case 'unlocked':
      const now = BigInt(Date.now() * 1_000_000)
      return stakeEntries.value.filter(entry => 
        entry.isActive && entry.unlockTime <= now
      )
    default:
      return stakeEntries.value
  }
})

// Utility functions for enhanced staking
const getTierColor = (tierName: string): string => {
  const colors: Record<string, string> = {
    'Liquid Staking': 'bg-gray-500',
    'Short Term': 'bg-blue-500',
    'Medium Term': 'bg-green-500',
    'Long Term': 'bg-orange-500',
    'Diamond Hands': 'bg-purple-500'
  }
  return colors[tierName] || 'bg-gray-400'
}

const formatLockPeriod = (seconds: number): string => {
  if (seconds === 0) return 'Instant (No lock)'
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  
  if (days > 0) {
    return `${days} day${days > 1 ? 's' : ''}`
  } else if (hours > 0) {
    return `${hours} hour${hours > 1 ? 's' : ''}`
  } else {
    return `${Math.floor(seconds / 60)} minute${Math.floor(seconds / 60) > 1 ? 's' : ''}`
  }
}

const getUnlockProgress = (entry: any): number => {
  if (entry.lockPeriod === 0) return 100
  
  const now = BigInt(Date.now() * 1_000_000)
  const stakedAt = entry.stakedAt
  const unlockTime = entry.unlockTime
  
  const totalDuration = unlockTime - stakedAt
  const elapsed = now - stakedAt
  
  if (elapsed >= totalDuration) return 100
  if (elapsed <= 0) return 0
  
  return Math.min(100, Math.floor(Number(elapsed) / Number(totalDuration) * 100))
}

const canUnstakeEntry = (entry: any): boolean => {
  if (!entry.isActive) return false
  if (entry.lockPeriod === 0) return true // Liquid staking
  
  const now = BigInt(Date.now() * 1_000_000)
  return entry.unlockTime <= now
}

const handleUnstakeEntry = (entry: any) => {
  // TODO: Implement unstaking logic
  console.log('Unstaking entry:', entry)
}

const viewEntryDetails = (entry: any) => {
  // TODO: Implement entry details view
  console.log('Viewing entry details:', entry)
}

const migrateLegacyStakes = () => {
  // TODO: Implement legacy stake migration
  console.log('Migrating legacy stakes')
}

const handleStakeConfirm = (stakeData: any) => {
  // TODO: Implement staking logic
  console.log('Staking confirmed:', stakeData)
  showStakeModal.value = false
  refreshStakingData()
}

const formatTimeRemaining = (unlockTime: bigint): string => {
  const now = BigInt(Date.now() * 1_000_000)
  const remaining = Number(unlockTime - now) / 1_000_000_000
  
  if (remaining <= 0) return 'Available now'
  
  const days = Math.floor(remaining / 86400)
  const hours = Math.floor((remaining % 86400) / 3600)
  const minutes = Math.floor((remaining % 3600) / 60)
  
  if (days > 0) {
    return `${days}d ${hours}h`
  } else if (hours > 0) {
    return `${hours}h ${minutes}m`
  } else if (minutes > 0) {
    return `${minutes}m`
  } else {
    return 'Less than 1m'
  }
}

// User Activity Timeline Methods
const fetchUserActivity = async () => {
  if (!dao.value) return
  
  isLoadingActivity.value = true
  currentActivityOffset.value = 0
  
  try {
    // Mock data for now - replace with actual API calls
    const mockActivities = [
      {
        id: '1',
        type: 'stake',
        amount: BigInt(1000 * 100_000_000),
        timestamp: BigInt(Date.now() - 86400000) * BigInt(1_000_000),
        blockIndex: 12345,
        description: 'Staked tokens with 90-day lock period',
        metadata: {
          lockDuration: 90 * 24 * 60 * 60
        }
      },
      {
        id: '2',
        type: 'vote',
        timestamp: BigInt(Date.now() - 172800000) * BigInt(1_000_000),
        blockIndex: 12340,
        description: 'Voted on community proposal',
        metadata: {
          proposalId: 5,
          voteChoice: 'yes'
        }
      },
      {
        id: '3',
        type: 'proposal_created',
        timestamp: BigInt(Date.now() - 259200000) * BigInt(1_000_000),
        blockIndex: 12335,
        description: 'Created motion proposal for treasury allocation',
        metadata: {
          proposalId: 5
        }
      },
      {
        id: '4',
        type: 'delegation',
        timestamp: BigInt(Date.now() - 345600000) * BigInt(1_000_000),
        blockIndex: 12330,
        description: 'Delegated voting power to trusted member',
        metadata: {
          delegateTo: 'rdmx6-jaaaa-aaaah-qcaiq-cai'
        }
      },
      {
        id: '5',
        type: 'unstake',
        amount: BigInt(500 * 100_000_000),
        timestamp: BigInt(Date.now() - 432000000) * BigInt(1_000_000),
        blockIndex: 12325,
        description: 'Unstaked tokens after lock period expired'
      }
    ]
    
    userActivities.value = mockActivities
    hasMoreActivities.value = false
  } catch (error) {
    console.error('Error fetching user activity:', error)
  } finally {
    isLoadingActivity.value = false
  }
}

const loadMoreActivities = async () => {
  // Implementation for loading more activities
  hasMoreActivities.value = false
}

const filteredUserActivities = computed(() => {
  if (selectedActivityFilter.value === 'all') {
    return userActivities.value
  }
  return userActivities.value.filter(activity => activity.type === selectedActivityFilter.value)
})

const getActivityIcon = (type: string) => {
  switch (type) {
    case 'stake': return CoinsIcon
    case 'unstake': return ArrowRightLeftIcon
    case 'vote': return VoteIcon
    case 'proposal_created': return PlusIcon
    case 'delegation': return UsersIcon
    default: return ActivityIcon
  }
}

const getActivityColor = (type: string) => {
  switch (type) {
    case 'stake': return 'bg-green-500 text-white'
    case 'unstake': return 'bg-red-500 text-white'
    case 'vote': return 'bg-blue-500 text-white'
    case 'proposal_created': return 'bg-purple-500 text-white'
    case 'delegation': return 'bg-orange-500 text-white'
    default: return 'bg-gray-500 text-white'
  }
}

const getActivityTitle = (activity: any): string => {
  switch (activity.type) {
    case 'stake': return 'Staked Tokens'
    case 'unstake': return 'Unstaked Tokens'
    case 'vote': return 'Cast Vote'
    case 'proposal_created': return 'Created Proposal'
    case 'delegation': return 'Delegated Voting Power'
    default: return 'Activity'
  }
}

const hasActivityDetails = (activity: any): boolean => {
  return !!(
    activity.amount || 
    activity.metadata?.lockDuration || 
    activity.metadata?.voteChoice || 
    activity.metadata?.proposalId ||
    activity.metadata?.delegateTo
  )
}

const getExplorerUrl = (blockIndex: number): string => {
  // Return IC block explorer URL
  return `https://dashboard.internetcomputer.org/bitcoin/transaction/${blockIndex}`
}

const findTierById = (tierId: number) => {
  // Mock implementation - replace with actual tier lookup
  const tiers = [
    { id: 0, name: 'Liquid Staking' },
    { id: 1, name: 'Short Term' },
    { id: 2, name: 'Medium Term' },
    { id: 3, name: 'Long Term' },
    { id: 4, name: 'Diamond Hands' }
  ]
  return tiers.find(tier => tier.id === tierId)
}

onMounted(() => {
  fetchData()
  refreshStakingData()
  fetchUserActivity()
})
</script>