<template>
  <AdminLayout>
    <PageBreadcrumb pageTitle="Dashboard" />

    <div class="container mx-auto px-4 py-6 space-y-8">
      <!-- Hero Section - Web3 Style -->
      <div class="relative overflow-hidden rounded-3xl bg-white dark:bg-gray-900/40 backdrop-blur-xl border border-gray-200 dark:border-white/5 p-8 lg:p-10 shadow-sm dark:shadow-none">
        <!-- Background Glow Effects -->
        <div class="absolute top-0 right-0 w-[500px] h-[500px] bg-[#b27c10]/20 rounded-full blur-[120px] -translate-y-1/2 translate-x-1/3 pointer-events-none"></div>
        <div class="absolute bottom-0 left-0 w-[300px] h-[300px] bg-blue-600/10 rounded-full blur-[100px] translate-y-1/3 -translate-x-1/3 pointer-events-none"></div>

        <div class="relative z-10 flex flex-col lg:flex-row items-center justify-between gap-8">
          <div class="max-w-2xl">
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#b27c10]/10 border border-[#b27c10]/20 text-[#b27c10] text-xs font-bold uppercase tracking-wider mb-4">
              <span class="w-2 h-2 rounded-full bg-[#b27c10] animate-pulse"></span>
              ICTO Protocol V2
            </div>
            <h1 class="text-4xl lg:text-5xl font-bold text-gray-900 dark:text-white mb-4 tracking-tight">
              Manage Your <span class="text-transparent bg-clip-text bg-gradient-to-r from-[#b27c10] to-[#e1b74c]">Web3 Assets</span>
            </h1>
            <p class="text-gray-600 dark:text-gray-400 text-lg mb-8 leading-relaxed max-w-xl">
              The all-in-one platform for deploying tokens, managing multisigs, and launching DAOs on the Internet Computer.
            </p>
            
            <div class="flex flex-wrap gap-4">
              <button
                @click="navigateToTokenFactory"
                class="group relative px-6 py-3 bg-[#b27c10] text-white font-bold rounded-xl overflow-hidden transition-all hover:shadow-[0_0_20px_rgba(178,124,16,0.4)] hover:scale-105 active:scale-95"
              >
                <div class="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300"></div>
                <span class="relative flex items-center gap-2">
                  <PlusIcon class="w-5 h-5" />
                  Deploy Token
                </span>
              </button>
              <button
                @click="navigateToMultisigFactory"
                class="group px-6 py-3 bg-gray-100 dark:bg-white/5 border border-gray-200 dark:border-white/10 text-gray-900 dark:text-white font-bold rounded-xl hover:bg-gray-200 dark:hover:bg-white/10 hover:border-gray-300 dark:hover:border-white/20 transition-all hover:scale-105 active:scale-95 backdrop-blur-sm"
              >
                <span class="flex items-center gap-2">
                  <WalletIcon class="w-5 h-5" />
                  Create Multisig
                </span>
              </button>
            </div>
          </div>

          <!-- Hero Visual -->
          <div class="relative w-full max-w-md lg:max-w-lg">
            <div class="absolute inset-0 bg-gradient-to-tr from-[#b27c10]/20 to-transparent rounded-full blur-3xl"></div>
            <div class="relative grid grid-cols-2 gap-4">
              <div class="space-y-4 translate-y-8">
                <div class="bg-white/80 dark:bg-gray-800/60 backdrop-blur-md p-4 rounded-2xl border border-gray-200 dark:border-white/5 transform hover:-translate-y-1 transition-transform duration-300 shadow-sm dark:shadow-none">
                  <CoinsIcon class="w-8 h-8 text-[#b27c10] mb-2" />
                  <div class="h-2 w-20 bg-gray-200 dark:bg-white/10 rounded mb-2"></div>
                  <div class="h-2 w-12 bg-gray-200 dark:bg-white/10 rounded"></div>
                </div>
                <div class="bg-white/80 dark:bg-gray-800/60 backdrop-blur-md p-4 rounded-2xl border border-gray-200 dark:border-white/5 transform hover:-translate-y-1 transition-transform duration-300 shadow-sm dark:shadow-none">
                  <LockKeyholeIcon class="w-8 h-8 text-purple-500 mb-2" />
                  <div class="h-2 w-16 bg-gray-200 dark:bg-white/10 rounded mb-2"></div>
                  <div class="h-2 w-10 bg-gray-200 dark:bg-white/10 rounded"></div>
                </div>
              </div>
              <div class="space-y-4">
                <div class="bg-white/80 dark:bg-gray-800/60 backdrop-blur-md p-4 rounded-2xl border border-gray-200 dark:border-white/5 transform hover:-translate-y-1 transition-transform duration-300 shadow-sm dark:shadow-none">
                  <RocketIcon class="w-8 h-8 text-pink-500 mb-2" />
                  <div class="h-2 w-24 bg-gray-200 dark:bg-white/10 rounded mb-2"></div>
                  <div class="h-2 w-16 bg-gray-200 dark:bg-white/10 rounded"></div>
                </div>
                <div class="bg-white/80 dark:bg-gray-800/60 backdrop-blur-md p-4 rounded-2xl border border-gray-200 dark:border-white/5 transform hover:-translate-y-1 transition-transform duration-300 shadow-sm dark:shadow-none">
                  <BuildingIcon class="w-8 h-8 text-blue-500 mb-2" />
                  <div class="h-2 w-20 bg-gray-200 dark:bg-white/10 rounded mb-2"></div>
                  <div class="h-2 w-14 bg-gray-200 dark:bg-white/10 rounded"></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Key Metrics -->
      <div>
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <ActivityIcon class="w-6 h-6 text-[#b27c10]" />
            Network Status
          </h2>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <StatsCard
            title="Total Contracts"
            :value="dashboardStats.totalContracts"
            :icon="LayoutGridIcon"
            iconBg="bg-[#b27c10]/10"
            iconColor="text-[#b27c10]"
            :change="12.5"
            changeLabel="this month"
            :loading="loading"
          />
          <StatsCard
            title="Active Users"
            :value="dashboardStats.activeUsers"
            :icon="UsersIcon"
            iconBg="bg-blue-500/10"
            iconColor="text-blue-500"
            :change="8.3"
            changeLabel="vs last month"
            :loading="loading"
          />
          <StatsCard
            title="Total Value Locked"
            :value="dashboardStats.tvl"
            :icon="DollarSignIcon"
            iconBg="bg-green-500/10"
            iconColor="text-green-500"
            :change="15.7"
            changeLabel="growth"
            :loading="loading"
            suffix=" ICP"
          />
          <StatsCard
            title="24h Transactions"
            :value="dashboardStats.transactions24h"
            :icon="ActivityIcon"
            iconBg="bg-purple-500/10"
            iconColor="text-purple-500"
            :change="5.4"
            changeLabel="vs yesterday"
            :loading="loading"
          />
        </div>
      </div>

      <!-- Charts Section -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Ecosystem Distribution -->
        <div class="bg-white dark:bg-gray-900/40 backdrop-blur-xl rounded-2xl p-6 border border-gray-200 dark:border-white/5 shadow-sm dark:shadow-none">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <PieChartIcon class="w-5 h-5 text-[#b27c10]" />
              Distribution
            </h3>
            <button class="p-2 text-gray-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors cursor-pointer">
              <RefreshCwIcon class="w-4 h-4" />
            </button>
          </div>
          <EcosystemChart
            :data="{
              tokens: Number(factoryStats.tokens),
              multisigs: Number(factoryStats.multisigs),
              distributions: Number(factoryStats.distributions),
              daos: Number(factoryStats.daos),
              launchpads: Number(factoryStats.launchpads)
            }"
          />
        </div>

        <!-- Activity Over Time -->
        <div class="bg-white dark:bg-gray-900/40 backdrop-blur-xl rounded-2xl p-6 border border-gray-200 dark:border-white/5 shadow-sm dark:shadow-none">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <BarChart3Icon class="w-5 h-5 text-[#b27c10]" />
              Activity
            </h3>
            <div class="flex items-center gap-1 bg-black/20 p-1 rounded-lg">
              <button
                v-for="period in ['7D', '30D', '90D']"
                :key="period"
                :class="[
                  'px-3 py-1 text-xs rounded-md transition-all font-medium cursor-pointer',
                  selectedPeriod === period
                    ? 'bg-[#b27c10] text-white shadow-lg'
                    : 'text-gray-400 hover:text-white hover:bg-white/5'
                ]"
                @click="selectedPeriod = period"
              >
                {{ period }}
              </button>
            </div>
          </div>
          <ActivityChart :data="activityData" />
        </div>
      </div>

      <!-- Factory Services -->
      <div>
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2 mb-2">
            <FactoryIcon class="w-6 h-6 text-[#b27c10]" />
            Services
          </h2>
          <p class="text-gray-600 dark:text-gray-400 text-sm">
            Deploy and manage your on-chain infrastructure
          </p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <FactoryCard
            title="Token Factory"
            description="Deploy ICRC-1/2 compliant tokens with blessed SNS-W WASM"
            :icon="CoinsIcon"
            :status="getFactoryStatus('token_factory')"
            :totalCreated="factoryStats.tokens"
            :fee="getFactoryFeeInfo('token_factory')"
            :features="getFactoryFeatures('token_factory')"
            :gradientClass="getFactoryGradient('token_factory').card"
            :buttonGradient="getFactoryGradient('token_factory').button"
            :loading="loading"
            @create="navigateToTokenFactory"
            @view="navigateToTokenList"
          />

          <FactoryCard
            title="Multisig Factory"
            description="Create multi-signature wallets with customizable policies"
            :icon="LockKeyholeIcon"
            :status="getFactoryStatus('multisig_factory')"
            :totalCreated="factoryStats.multisigs"
            :fee="getFactoryFeeInfo('multisig_factory')"
            :features="getFactoryFeatures('multisig_factory')"
            :gradientClass="getFactoryGradient('multisig_factory').card"
            :buttonGradient="getFactoryGradient('multisig_factory').button"
            :loading="loading"
            @create="navigateToMultisigFactory"
            @view="navigateToMultisigList"
          />

          <FactoryCard
            title="Distribution Factory"
            description="Token distribution with vesting, airdrops, and locks"
            :icon="SendIcon"
            :status="getFactoryStatus('distribution_factory')"
            :totalCreated="factoryStats.distributions"
            :fee="getFactoryFeeInfo('distribution_factory')"
            :features="getFactoryFeatures('distribution_factory')"
            :gradientClass="getFactoryGradient('distribution_factory').card"
            :buttonGradient="getFactoryGradient('distribution_factory').button"
            :loading="loading"
            @create="navigateToDistributionFactory"
            @view="navigateToDistributionList"
          />

          <FactoryCard
            title="DAO Factory"
            description="Deploy decentralized governance structures"
            :icon="BuildingIcon"
            :status="getFactoryStatus('dao_factory')"
            :totalCreated="factoryStats.daos"
            :fee="getFactoryFeeInfo('dao_factory')"
            :features="getFactoryFeatures('dao_factory')"
            :gradientClass="getFactoryGradient('dao_factory').card"
            :buttonGradient="getFactoryGradient('dao_factory').button"
            :loading="loading"
            @create="navigateToDAOFactory"
            @view="navigateToDAOList"
          />

          <FactoryCard
            title="Launchpad Factory"
            description="Token presale and launch platform"
            :icon="RocketIcon"
            :status="getFactoryStatus('launchpad_factory')"
            :totalCreated="factoryStats.launchpads"
            :fee="getFactoryFeeInfo('launchpad_factory')"
            :features="getFactoryFeatures('launchpad_factory')"
            :gradientClass="getFactoryGradient('launchpad_factory').card"
            :buttonGradient="getFactoryGradient('launchpad_factory').button"
            :loading="loading"
            @create="navigateToLaunchpadFactory"
            @view="navigateToLaunchpadList"
          />

          <!-- Coming Soon -->
          <div class="group relative overflow-hidden rounded-2xl bg-white dark:bg-gray-900/40 backdrop-blur-xl border border-gray-200 dark:border-white/5 p-8 flex flex-col items-center justify-center text-center hover:border-[#b27c10]/30 transition-colors shadow-sm dark:shadow-none">
            <div class="absolute inset-0 bg-[url('/grid.svg')] opacity-10"></div>
            <SparklesIcon class="w-12 h-12 text-gray-400 dark:text-gray-600 mb-4 group-hover:text-[#b27c10] group-hover:scale-110 transition-all duration-300" />
            <h3 class="text-lg font-bold text-gray-500 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-white mb-2 transition-colors">More Coming Soon</h3>
            <p class="text-sm text-gray-500">
              New factory services are in development
            </p>
          </div>
        </div>
      </div>

      <!-- Recent Activity & Quick Actions -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8">
        <!-- Recent Activities -->
        <div class="lg:col-span-2 bg-white dark:bg-gray-900/40 backdrop-blur-xl rounded-2xl p-6 lg:p-8 border border-gray-200 dark:border-white/5 shadow-sm dark:shadow-none">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg lg:text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <ClockIcon class="w-5 h-5 text-[#b27c10]" />
              Recent Activity
            </h3>
            <button class="text-xs lg:text-sm text-[#b27c10] hover:text-[#d8a735] font-bold uppercase tracking-wide transition-colors cursor-pointer">
              View All →
            </button>
          </div>
          <ActivityTimeline :activities="recentActivities" />
        </div>

        <!-- Quick Actions & Resources -->
        <div class="space-y-6">
          <!-- Quick Actions -->
          <div class="bg-white dark:bg-gray-900/40 backdrop-blur-xl rounded-2xl p-6 border border-gray-200 dark:border-white/5 shadow-sm dark:shadow-none">
            <h3 class="text-base lg:text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <ZapIcon class="w-5 h-5 text-[#b27c10]" />
              Quick Actions
            </h3>
            <div class="space-y-2">
              <button
                @click="navigateToTokenFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-xl hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group border border-transparent hover:border-gray-200 dark:hover:border-white/5"
              >
                <div class="w-10 h-10 bg-blue-500/10 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <CoinsIcon class="w-5 h-5 text-blue-500" />
                </div>
                <div>
                  <p class="text-sm font-bold text-gray-900 dark:text-white">Deploy Token</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Create ICRC-1/2 token</p>
                </div>
              </button>

              <button
                @click="navigateToMultisigFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-xl hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group border border-transparent hover:border-gray-200 dark:hover:border-white/5"
              >
                <div class="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <LockKeyholeIcon class="w-5 h-5 text-purple-500" />
                </div>
                <div>
                  <p class="text-sm font-bold text-gray-900 dark:text-white">Create Multisig</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Multi-signature wallet</p>
                </div>
              </button>

              <button
                @click="navigateToDistributionFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-xl hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group border border-transparent hover:border-gray-200 dark:hover:border-white/5"
              >
                <div class="w-10 h-10 bg-green-500/10 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <SendIcon class="w-5 h-5 text-green-500" />
                </div>
                <div>
                  <p class="text-sm font-bold text-gray-900 dark:text-white">Distribute Tokens</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Airdrops & vesting</p>
                </div>
              </button>

              <button
                @click="navigateToLaunchpadFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-xl hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group border border-transparent hover:border-gray-200 dark:hover:border-white/5"
              >
                <div class="w-10 h-10 bg-pink-500/10 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <RocketIcon class="w-5 h-5 text-pink-500" />
                </div>
                <div>
                  <p class="text-sm font-bold text-gray-900 dark:text-white">Launch Token Sale</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Presale & fundraising</p>
                </div>
              </button>
            </div>
          </div>

          <!-- Resources -->
          <div class="bg-gradient-to-br from-[#b27c10]/10 to-[#d8a735]/5 rounded-2xl p-6 border border-[#b27c10]/20">
            <h3 class="text-base lg:text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <BookOpenIcon class="w-5 h-5 text-[#b27c10]" />
              Resources
            </h3>
            <div class="space-y-3">
              <a
                href="/docs/architecture"
                class="flex items-center justify-between p-3 bg-white/60 dark:bg-black/20 rounded-xl hover:bg-white dark:hover:bg-black/40 transition-colors cursor-pointer border border-transparent hover:border-[#b27c10]/30 shadow-sm dark:shadow-none"
              >
                <span class="text-sm font-medium text-gray-900 dark:text-white">Architecture Guide</span>
                <ArrowRightIcon class="w-4 h-4 text-gray-400 group-hover:text-[#b27c10]" />
              </a>
              <a
                href="/docs/workflow"
                class="flex items-center justify-between p-3 bg-white/60 dark:bg-black/20 rounded-xl hover:bg-white dark:hover:bg-black/40 transition-colors cursor-pointer border border-transparent hover:border-[#b27c10]/30 shadow-sm dark:shadow-none"
              >
                <span class="text-sm font-medium text-gray-900 dark:text-white">Workflow Guide</span>
                <ArrowRightIcon class="w-4 h-4 text-gray-400 group-hover:text-[#b27c10]" />
              </a>
              <a
                href="https://github.com/ICTO-Labs/icto_v2"
                target="_blank"
                class="flex items-center justify-between p-3 bg-white/60 dark:bg-black/20 rounded-xl hover:bg-white dark:hover:bg-black/40 transition-colors cursor-pointer border border-transparent hover:border-[#b27c10]/30 shadow-sm dark:shadow-none"
              >
                <span class="text-sm font-medium text-gray-900 dark:text-white">GitHub Repository</span>
                <ExternalLinkIcon class="w-4 h-4 text-gray-400 group-hover:text-[#b27c10]" />
              </a>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="bg-white dark:bg-gray-900/40 backdrop-blur-xl rounded-3xl p-8 lg:p-12 border border-gray-200 dark:border-white/5 shadow-sm dark:shadow-none">
        <!-- Top Section -->
        <div class="text-center mb-8 lg:mb-10">
          <div class="inline-block mb-4 lg:mb-6">
            <div class="flex items-center justify-center gap-2 lg:gap-3 bg-gray-100 dark:bg-white/5 rounded-full px-5 lg:px-6 py-2 lg:py-3 border border-gray-200 dark:border-white/10">
              <ShieldCheckIcon class="w-5 lg:w-6 h-5 lg:h-6 text-[#b27c10]" />
              <span class="text-base lg:text-lg font-bold text-gray-900 dark:text-white">100% On-Chain</span>
            </div>
          </div>
          <h3 class="text-2xl lg:text-3xl xl:text-4xl font-bold mb-3 text-gray-900 dark:text-white">Entirely on Internet Computer</h3>
          <p class="text-sm lg:text-base text-gray-600 dark:text-gray-400 max-w-3xl mx-auto mb-6 lg:mb-8">
            Every transaction, every smart contract, every piece of data is stored and executed on the Internet Computer blockchain. No centralized servers, no third-party dependencies.
          </p>
          <div class="flex items-center justify-center gap-4 lg:gap-8 flex-wrap mb-8">
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-300">Decentralized</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-300">Trustless</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-300">Transparent</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-600 dark:text-gray-300">Immutable</span>
            </div>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-gray-200 dark:border-white/5 mb-8"></div>

        <!-- Bottom Section - Links & Socials -->
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6 lg:gap-8 text-left">
          <!-- About -->
          <div>
            <h4 class="text-sm font-bold uppercase tracking-wide mb-4 text-gray-900 dark:text-white">About ICTO</h4>
            <ul class="space-y-2">
              <li>
                <a href="/about" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  About Us
                </a>
              </li>
              <li>
                <a href="/docs" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Documentation
                </a>
              </li>
              <li>
                <a href="/roadmap" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Roadmap
                </a>
              </li>
              <li>
                <a href="/blog" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Blog
                </a>
              </li>
            </ul>
          </div>

          <!-- Resources -->
          <div>
            <h4 class="text-sm font-bold uppercase tracking-wide mb-4 text-gray-900 dark:text-white">Resources</h4>
            <ul class="space-y-2">
              <li>
                <a href="/docs/architecture" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Architecture
                </a>
              </li>
              <li>
                <a href="/docs/api" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  API Reference
                </a>
              </li>
              <li>
                <a href="/docs/guides" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Guides & Tutorials
                </a>
              </li>
              <li>
                <a href="/faq" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  FAQ
                </a>
              </li>
            </ul>
          </div>

          <!-- Community -->
          <div>
            <h4 class="text-sm font-bold uppercase tracking-wide mb-4 text-gray-900 dark:text-white">Community</h4>
            <ul class="space-y-2 mb-4">
              <li>
                <a href="https://github.com/ICTO-Labs/icto_v2" target="_blank" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <GithubIcon class="w-4 h-4" />
                  GitHub
                </a>
              </li>
              <li>
                <a href="https://x.com/icto_app" target="_blank" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <XIcon class="w-4 h-4" />
                  X
                </a>
              </li>
              <li>
                <a href="https://discord.gg/icto" target="_blank" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <MessageCircleIcon class="w-4 h-4" />
                  Discord
                </a>
              </li>
              <li>
                <a href="https://t.me/icto_app" target="_blank" class="text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <SendIcon class="w-4 h-4" />
                  Telegram
                </a>
              </li>
            </ul>
            <div class="flex gap-3">
              <a
                href="https://github.com/ICTO-Labs/icto_v2"
                target="_blank"
                class="w-10 h-10 bg-white/5 border border-white/10 rounded-lg flex items-center justify-center text-gray-300 hover:bg-[#b27c10] hover:border-[#b27c10] hover:text-white transition-all"
              >
                <GithubIcon class="w-5 h-5" />
              </a>
              <a
                href="https://x.com/icto_app"
                target="_blank"
                class="w-10 h-10 bg-white/5 border border-white/10 rounded-lg flex items-center justify-center text-gray-300 hover:bg-[#b27c10] hover:border-[#b27c10] hover:text-white transition-all"
              >
                <XIcon class="w-5 h-5" />
              </a>
              <a
                href="#"
                target="_blank"
                class="w-10 h-10 bg-white/5 border border-white/10 rounded-lg flex items-center justify-center text-gray-300 hover:bg-[#b27c10] hover:border-[#b27c10] hover:text-white transition-all"
              >
                <MessageCircleIcon class="w-5 h-5" />
              </a>
            </div>
          </div>
        </div>

        <!-- Bottom Bar -->
        <div class="border-t border-gray-200 dark:border-white/5 mt-8 pt-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p class="text-xs lg:text-sm text-gray-500 dark:text-gray-400">
            © 2024 ICTO Labs. Built on Internet Computer Protocol.
          </p>
          <div class="flex items-center gap-4 lg:gap-6">
            <a href="/privacy" class="text-xs lg:text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors cursor-pointer">
              Privacy Policy
            </a>
            <a href="/terms" class="text-xs lg:text-sm text-gray-500 dark:text-gray-400 hover:text-[#b27c10] transition-colors cursor-pointer">
              Terms of Service
            </a>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { Principal } from '@dfinity/principal'
import {
  RocketIcon,
  PlusIcon,
  WalletIcon,
  TrendingUpIcon,
  LayoutGridIcon,
  UsersIcon,
  DollarSignIcon,
  ActivityIcon,
  FactoryIcon,
  CoinsIcon,
  LockKeyholeIcon,
  SendIcon,
  BuildingIcon,
  SparklesIcon,
  PieChartIcon,
  RefreshCwIcon,
  BarChart3Icon,
  ClockIcon,
  ZapIcon,
  BookOpenIcon,
  ArrowRightIcon,
  ExternalLinkIcon,
  ShieldCheckIcon,
  GithubIcon,
  XIcon,
  MessageCircleIcon
} from 'lucide-vue-next'

import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import StatsCard from '@/components/dashboard/StatsCard.vue'
import FactoryCard from '@/components/dashboard/FactoryCard.vue'
import EcosystemChart from '@/components/dashboard/EcosystemChart.vue'
import ActivityChart from '@/components/dashboard/ActivityChart.vue'
import ActivityTimeline from '@/components/dashboard/ActivityTimeline.vue'

import { tokenFactoryService } from '@/api/services/tokenFactory'
import { multisigFactoryService } from '@/api/services/multisigFactory'
import { distributionFactoryService } from '@/api/services/distributionFactory'
import { daoFactoryService } from '@/api/services/daoFactory'
import { launchpadFactoryService } from '@/api/services/launchpadFactory'

import {
  getFactoryStatus,
  getFactoryFeeInfo,
  getFactoryFeatures,
  getFactoryGradient,
  generateMockTimeSeries
} from '@/utils/dashboard'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(true)
const selectedPeriod = ref('7D')

// Dashboard statistics
const dashboardStats = ref({
  totalContracts: 0,
  activeUsers: 247,
  tvl: '12.5K',
  transactions24h: 156
})

// Factory statistics
const factoryStats = ref({
  tokens: 0,
  multisigs: 0,
  distributions: 0,
  daos: 0,
  launchpads: 0
})

// Activity data for charts
const activityData = computed(() => {
  const deployments = generateMockTimeSeries(20, 0.3)
  const transactions = generateMockTimeSeries(50, 0.4)

  return {
    deployments: deployments.data,
    transactions: transactions.data,
    labels: deployments.labels
  }
})

// Recent activities
const recentActivities = ref([
  {
    id: '1',
    title: 'New Token Deployed',
    description: 'ICTO Token (ICTO) deployed successfully with 1M supply',
    time: '2 minutes ago',
    status: 'completed' as const,
    icon: CoinsIcon,
    iconBg: 'bg-blue-100 dark:bg-blue-900/20',
    iconColor: 'text-blue-600'
  },
  {
    id: '2',
    title: 'Multisig Wallet Created',
    description: 'Treasury wallet with 3/5 threshold created',
    time: '15 minutes ago',
    status: 'completed' as const,
    icon: LockKeyholeIcon,
    iconBg: 'bg-purple-100 dark:bg-purple-900/20',
    iconColor: 'text-purple-600'
  },
  {
    id: '3',
    title: 'Distribution Started',
    description: 'Airdrop of 50K tokens to 100 recipients initiated',
    time: '1 hour ago',
    status: 'active' as const,
    icon: SendIcon,
    iconBg: 'bg-green-100 dark:bg-green-900/20',
    iconColor: 'text-green-600'
  },
  {
    id: '4',
    title: 'DAO Proposal Submitted',
    description: 'Proposal to update treasury parameters',
    time: '3 hours ago',
    status: 'pending' as const,
    icon: BuildingIcon,
    iconBg: 'bg-orange-100 dark:bg-orange-900/20',
    iconColor: 'text-orange-600'
  },
  {
    id: '5',
    title: 'Launchpad Sale Live',
    description: 'Public sale for TOKEN-X now active - 45% funded',
    time: '5 hours ago',
    status: 'active' as const,
    icon: RocketIcon,
    iconBg: 'bg-pink-100 dark:bg-pink-900/20',
    iconColor: 'text-pink-600'
  }
])

// Navigation methods
const navigateToTokenFactory = () => router.push('/token/create')
const navigateToTokenList = () => router.push('/tokens')
const navigateToMultisigFactory = () => router.push('/multisig/create')
const navigateToMultisigList = () => router.push('/multisig')
const navigateToDistributionFactory = () => router.push('/distribution/create')
const navigateToDistributionList = () => router.push('/distribution')
const navigateToDAOFactory = () => router.push('/dao/create')
const navigateToDAOList = () => router.push('/dao')
const navigateToLaunchpadFactory = () => router.push('/launchpad/create')
const navigateToLaunchpadList = () => router.push('/launchpad')

// Fetch data from all factories
const fetchDashboardData = async () => {
  loading.value = true

  try {
    // Fetch data from all factories concurrently using service methods
    const [tokensTotal, multisigsStats, distributionsTotal, daosTotal, launchpadsTotal] = await Promise.allSettled([
      tokenFactoryService.getTotalTokens(),
      multisigFactoryService.getFactoryStats(),
      // Use getPublic methods which internally handle actor calls
      distributionFactoryService.getPublicDistributions(1, 0).then(res => res.total),
      daoFactoryService.getPublicDAOs(1, 0).then(res => res.total),
      launchpadFactoryService.getPublicSales(1, 0).then(res => res.total)
    ])

    // Update factory stats
    if (tokensTotal.status === 'fulfilled') {
      factoryStats.value.tokens = tokensTotal.value
    }

    if (multisigsStats.status === 'fulfilled') {
      factoryStats.value.multisigs = Number(multisigsStats.value.totalWallets)
    }

    if (distributionsTotal.status === 'fulfilled') {
      factoryStats.value.distributions = Number(distributionsTotal.value)
    }

    if (daosTotal.status === 'fulfilled') {
      factoryStats.value.daos = Number(daosTotal.value)
    }

    if (launchpadsTotal.status === 'fulfilled') {
      factoryStats.value.launchpads = Number(launchpadsTotal.value)
    }

    // Calculate total contracts
    dashboardStats.value.totalContracts =
      Number(factoryStats.value.tokens) +
      Number(factoryStats.value.multisigs) +
      Number(factoryStats.value.distributions) +
      Number(factoryStats.value.daos) +
      Number(factoryStats.value.launchpads)

  } catch (error) {
    console.error('Error fetching dashboard data:', error)
  } finally {
    loading.value = false
  }
}

// Lifecycle
onMounted(() => {
  fetchDashboardData()
})

// Export utils for template
defineExpose({
  getFactoryStatus,
  getFactoryFeeInfo,
  getFactoryFeatures,
  getFactoryGradient
})
</script>

<style scoped>
/* Smooth animations */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* Custom scrollbar */
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(178, 124, 16, 0.3);
  border-radius: 3px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: rgba(178, 124, 16, 0.5);
}
</style>
