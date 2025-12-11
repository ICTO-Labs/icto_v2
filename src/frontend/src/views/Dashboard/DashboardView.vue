<template>
  <AdminLayout>
    <PageBreadcrumb pageTitle="Dashboard" />

    <div class="container mx-auto px-4 py-6 space-y-8">
      <!-- Hero Section - Compact with Gradient -->
      <div class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#b27c10] via-[#d8a735] to-[#e1b74c] p-6 lg:p-8 text-white">
        <div class="absolute top-0 right-0 w-48 h-48 lg:w-64 lg:h-64 opacity-15">
          <RocketIcon class="w-full h-full" />
        </div>
        <div class="relative z-10">
          <h1 class="text-3xl lg:text-4xl font-bold mb-2">Welcome to ICTO V2</h1>
          <p class="text-sm lg:text-base text-white/90 mb-5">
            Internet Computer Token Operations Platform - Your Web3 Ecosystem Hub
          </p>
          <div class="flex flex-wrap gap-3">
            <button
              @click="navigateToTokenFactory"
              class="px-5 lg:px-6 py-2 lg:py-3 bg-white text-[#b27c10] font-semibold rounded-lg hover:bg-white/90 transition-all duration-200 hover:shadow-lg cursor-pointer"
            >
              <PlusIcon class="w-4 lg:w-5 h-4 lg:h-5 inline-block mr-2" />
              Deploy Token
            </button>
            <button
              @click="navigateToMultisigFactory"
              class="px-5 lg:px-6 py-2 lg:py-3 bg-white/10 backdrop-blur-sm border-2 border-white/30 text-white font-semibold rounded-lg hover:bg-white/20 transition-all duration-200 cursor-pointer"
            >
              <WalletIcon class="w-4 lg:w-5 h-4 lg:h-5 inline-block mr-2" />
              Create Multisig
            </button>
          </div>
        </div>
      </div>

      <!-- Key Metrics - Enhanced -->
      <div>
        <div class="flex items-center justify-between mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <TrendingUpIcon class="w-6 h-6 text-[#b27c10]" />
            Ecosystem Overview
          </h2>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 lg:gap-6">
          <StatsCard
            title="Total Contracts"
            :value="dashboardStats.totalContracts"
            :icon="LayoutGridIcon"
            iconBg="bg-gradient-to-br from-[#b27c10]/15 to-[#d8a735]/15 dark:from-[#b27c10]/10 dark:to-[#d8a735]/10"
            iconColor="text-[#b27c10]"
            :change="12.5"
            changeLabel="this month"
            :loading="loading"
          />
          <StatsCard
            title="Active Users"
            :value="dashboardStats.activeUsers"
            :icon="UsersIcon"
            iconBg="bg-gradient-to-br from-blue-100/60 to-blue-200/60 dark:from-blue-900/20 dark:to-blue-800/20"
            iconColor="text-blue-600"
            :change="8.3"
            changeLabel="vs last month"
            :loading="loading"
          />
          <StatsCard
            title="Total Value Locked"
            :value="dashboardStats.tvl"
            :icon="DollarSignIcon"
            iconBg="bg-gradient-to-br from-green-100/60 to-green-200/60 dark:from-green-900/20 dark:to-green-800/20"
            iconColor="text-green-600"
            :change="15.7"
            changeLabel="growth"
            :loading="loading"
            suffix=" ICP"
          />
          <StatsCard
            title="24h Transactions"
            :value="dashboardStats.transactions24h"
            :icon="ActivityIcon"
            iconBg="bg-gradient-to-br from-purple-100/60 to-purple-200/60 dark:from-purple-900/20 dark:to-purple-800/20"
            iconColor="text-purple-600"
            :change="5.4"
            changeLabel="vs yesterday"
            :loading="loading"
          />
        </div>
      </div>

      <!-- Charts Section - First -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Ecosystem Distribution -->
        <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700 hover:shadow-lg transition-shadow">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <PieChartIcon class="w-5 h-5 text-[#b27c10]" />
              Ecosystem Distribution
            </h3>
            <button class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer">
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
        <div class="bg-white dark:bg-gray-800 rounded-xl p-6 border dark:border-gray-700 hover:shadow-lg transition-shadow">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <BarChart3Icon class="w-5 h-5 text-[#b27c10]" />
              Platform Activity (7 Days)
            </h3>
            <div class="flex items-center space-x-2">
              <button
                v-for="period in ['7D', '30D', '90D']"
                :key="period"
                :class="[
                  'px-3 py-1 text-xs rounded-lg transition-colors font-medium cursor-pointer',
                  selectedPeriod === period
                    ? 'bg-[#b27c10] text-white'
                    : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700'
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

      <!-- Factory Services - Featured -->
      <div>
        <div class="mb-6">
          <h2 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2 mb-2">
            <FactoryIcon class="w-6 h-6 text-[#b27c10]" />
            Factory Services
          </h2>
          <p class="text-gray-600 dark:text-gray-400 text-sm">
            Deploy and manage blockchain services on the Internet Computer
          </p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <!-- Token Factory -->
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

          <!-- Multisig Factory -->
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

          <!-- Distribution Factory -->
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

          <!-- DAO Factory -->
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

          <!-- Launchpad Factory -->
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

          <!-- Coming Soon Placeholder -->
          <div class="bg-gradient-to-br from-gray-100 to-gray-200 dark:from-gray-800 dark:to-gray-700 rounded-xl border-2 border-dashed border-gray-300 dark:border-gray-600 p-8 flex flex-col items-center justify-center text-center">
            <SparklesIcon class="w-12 h-12 text-gray-400 dark:text-gray-500 mb-4" />
            <h3 class="text-lg font-semibold text-gray-600 dark:text-gray-400 mb-2">More Coming Soon</h3>
            <p class="text-sm text-gray-500 dark:text-gray-500">
              New factory services are in development
            </p>
          </div>
        </div>
      </div>


      <!-- Recent Activity & Quick Actions -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:gap-8">
        <!-- Recent Activities -->
        <div class="lg:col-span-2 bg-white dark:bg-gray-800/80 rounded-xl p-6 lg:p-8 border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg lg:text-xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
              <ClockIcon class="w-5 h-5 text-[#b27c10]" />
              Recent Platform Activity
            </h3>
            <button class="text-xs lg:text-sm text-[#b27c10] hover:text-[#d8a735] font-semibold uppercase tracking-wide transition-colors cursor-pointer">
              View All →
            </button>
          </div>
          <ActivityTimeline :activities="recentActivities" />
        </div>

        <!-- Quick Actions & Resources -->
        <div class="space-y-6">
          <!-- Quick Actions -->
          <div class="bg-white dark:bg-gray-800/80 rounded-xl p-6 border border-gray-200 dark:border-gray-700 hover:shadow-lg transition-shadow">
            <h3 class="text-base lg:text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <ZapIcon class="w-5 h-5 text-[#b27c10]" />
              Quick Actions
            </h3>
            <div class="space-y-2">
              <button
                @click="navigateToTokenFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors group"
              >
                <div class="w-10 h-10 bg-blue-100 dark:bg-blue-900/20 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <CoinsIcon class="w-5 h-5 text-blue-600" />
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">Deploy Token</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Create ICRC-1/2 token</p>
                </div>
              </button>

              <button
                @click="navigateToMultisigFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors group"
              >
                <div class="w-10 h-10 bg-purple-100 dark:bg-purple-900/20 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <LockKeyholeIcon class="w-5 h-5 text-purple-600" />
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">Create Multisig</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Multi-signature wallet</p>
                </div>
              </button>

              <button
                @click="navigateToDistributionFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors group"
              >
                <div class="w-10 h-10 bg-green-100 dark:bg-green-900/20 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <SendIcon class="w-5 h-5 text-green-600" />
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">Distribute Tokens</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Airdrops & vesting</p>
                </div>
              </button>

              <button
                @click="navigateToLaunchpadFactory"
                class="w-full flex items-center gap-3 p-3 text-left rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors group"
              >
                <div class="w-10 h-10 bg-pink-100 dark:bg-pink-900/20 rounded-lg flex items-center justify-center group-hover:scale-110 transition-transform">
                  <RocketIcon class="w-5 h-5 text-pink-600" />
                </div>
                <div>
                  <p class="text-sm font-medium text-gray-900 dark:text-white">Launch Token Sale</p>
                  <p class="text-xs text-gray-500 dark:text-gray-400">Presale & fundraising</p>
                </div>
              </button>
            </div>
          </div>

          <!-- Resources -->
          <div class="bg-gradient-to-br from-[#b27c10]/12 to-[#d8a735]/12 dark:from-[#b27c10]/8 dark:to-[#d8a735]/8 rounded-xl p-6 border border-[#b27c10]/20 dark:border-[#b27c10]/15 hover:shadow-lg transition-shadow">
            <h3 class="text-base lg:text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center gap-2">
              <BookOpenIcon class="w-5 h-5 text-[#b27c10]" />
              Resources
            </h3>
            <div class="space-y-3">
              <a
                href="/docs/architecture"
                class="flex items-center justify-between p-3 bg-white/60 dark:bg-gray-800/60 rounded-lg hover:bg-white dark:hover:bg-gray-800 transition-colors cursor-pointer"
              >
                <span class="text-sm font-medium text-gray-900 dark:text-white">Architecture Guide</span>
                <ArrowRightIcon class="w-4 h-4 text-gray-400 group-hover:text-[#b27c10]" />
              </a>
              <a
                href="/docs/workflow"
                class="flex items-center justify-between p-3 bg-white/60 dark:bg-gray-800/60 rounded-lg hover:bg-white dark:hover:bg-gray-800 transition-colors cursor-pointer"
              >
                <span class="text-sm font-medium text-gray-900 dark:text-white">Workflow Guide</span>
                <ArrowRightIcon class="w-4 h-4 text-gray-400 group-hover:text-[#b27c10]" />
              </a>
              <a
                href="https://github.com/ICTO-Labs/icto_v2"
                target="_blank"
                class="flex items-center justify-between p-3 bg-white/60 dark:bg-gray-800/60 rounded-lg hover:bg-white dark:hover:bg-gray-800 transition-colors cursor-pointer"
              >
                <span class="text-sm font-medium text-gray-900 dark:text-white">GitHub Repository</span>
                <ExternalLinkIcon class="w-4 h-4 text-gray-400 group-hover:text-[#b27c10]" />
              </a>
            </div>
          </div>
        </div>
      </div>


      <!-- Footer -->
      <div class="bg-gradient-to-br from-gray-50 to-gray-100 dark:from-white/[0.02] dark:to-white/[0.05] rounded-2xl p-8 lg:p-12 border border-gray-200 dark:border-gray-800">
        <!-- Top Section -->
        <div class="text-center mb-8 lg:mb-10">
          <div class="inline-block mb-4 lg:mb-6">
            <div class="flex items-center justify-center gap-2 lg:gap-3 bg-white dark:bg-gray-800/80 rounded-full px-5 lg:px-6 py-2 lg:py-3 border border-gray-200 dark:border-gray-700">
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
              <span class="text-xs lg:text-sm font-medium text-gray-700 dark:text-gray-300">Decentralized</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-700 dark:text-gray-300">Trustless</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-700 dark:text-gray-300">Transparent</span>
            </div>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-xs lg:text-sm font-medium text-gray-700 dark:text-gray-300">Immutable</span>
            </div>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-gray-200 dark:border-gray-700 mb-8"></div>

        <!-- Bottom Section - Links & Socials -->
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6 lg:gap-8 text-left">
          <!-- About -->
          <div>
            <h4 class="text-sm font-bold uppercase tracking-wide mb-4 text-gray-900 dark:text-white">About ICTO</h4>
            <ul class="space-y-2">
              <li>
                <a href="/about" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  About Us
                </a>
              </li>
              <li>
                <a href="/docs" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Documentation
                </a>
              </li>
              <li>
                <a href="/roadmap" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Roadmap
                </a>
              </li>
              <li>
                <a href="/blog" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
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
                <a href="/docs/architecture" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Architecture
                </a>
              </li>
              <li>
                <a href="/docs/api" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  API Reference
                </a>
              </li>
              <li>
                <a href="/docs/guides" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
                  Guides & Tutorials
                </a>
              </li>
              <li>
                <a href="/faq" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors">
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
                <a href="https://github.com/ICTO-Labs/icto_v2" target="_blank" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <GithubIcon class="w-4 h-4" />
                  GitHub
                </a>
              </li>
              <li>
                <a href="https://x.com/icto_app" target="_blank" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <XIcon class="w-4 h-4" />
                  X
                </a>
              </li>
              <li>
                <a href="https://discord.gg/icto" target="_blank" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <MessageCircleIcon class="w-4 h-4" />
                  Discord
                </a>
              </li>
              <li>
                <a href="https://t.me/icto_app" target="_blank" class="text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors flex items-center gap-2">
                  <SendIcon class="w-4 h-4" />
                  Telegram
                </a>
              </li>
            </ul>
            <div class="flex gap-3">
              <a
                href="https://github.com/ICTO-Labs/icto_v2"
                target="_blank"
                class="w-10 h-10 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg flex items-center justify-center text-gray-700 dark:text-gray-300 hover:bg-[#b27c10] hover:border-[#b27c10] hover:text-white transition-all"
              >
                <GithubIcon class="w-5 h-5" />
              </a>
              <a
                href="https://x.com/icto_app"
                target="_blank"
                class="w-10 h-10 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg flex items-center justify-center text-gray-700 dark:text-gray-300 hover:bg-[#b27c10] hover:border-[#b27c10] hover:text-white transition-all"
              >
                <XIcon class="w-5 h-5" />
              </a>
              <a
                href="#"
                target="_blank"
                class="w-10 h-10 bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded-lg flex items-center justify-center text-gray-700 dark:text-gray-300 hover:bg-[#b27c10] hover:border-[#b27c10] hover:text-white transition-all"
              >
                <MessageCircleIcon class="w-5 h-5" />
              </a>
            </div>
          </div>
        </div>

        <!-- Bottom Bar -->
        <div class="border-t border-gray-200 dark:border-gray-700 mt-8 pt-6 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p class="text-xs lg:text-sm text-gray-600 dark:text-gray-400">
            © 2024 ICTO Labs. Built on Internet Computer Protocol.
          </p>
          <div class="flex items-center gap-4 lg:gap-6">
            <a href="/privacy" class="text-xs lg:text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors cursor-pointer">
              Privacy Policy
            </a>
            <a href="/terms" class="text-xs lg:text-sm text-gray-600 dark:text-gray-400 hover:text-[#b27c10] transition-colors cursor-pointer">
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
