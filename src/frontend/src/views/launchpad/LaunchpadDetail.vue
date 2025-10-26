<template>
	<AdminLayout>
		<div class="min-h-screen dark:from-gray-900 dark:to-gray-800">
			<!-- Loading State -->
			<div v-if="loading" class="flex items-center justify-center min-h-screen">
				<div class="text-center">
					<div class="inline-block animate-spin rounded-full h-16 w-16 border-b-2 border-[#d8a735]"></div>
					<p class="mt-4 text-gray-600 dark:text-gray-400">Loading launchpad details...</p>
				</div>
			</div>

			<!-- Error State -->
			<div v-else-if="error" class="flex items-center justify-center min-h-screen">
				<div class="text-center max-w-md">
					<div class="text-red-500 text-6xl mb-4">⚠️</div>
					<h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">Failed to Load Launchpad</h2>
					<p class="text-gray-600 dark:text-gray-400 mb-6">{{ error }}</p>
					<button @click="fetchData"
						class="px-6 py-3 bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white rounded-xl font-semibold hover:shadow-lg transform hover:-translate-y-0.5 transition-all">
						Try Again
					</button>
				</div>
			</div>

			<!-- Main Content -->
			<div v-else-if="launchpad" class="mx-auto">
				<!-- Breadcrumb Navigation -->
				<Breadcrumb :items="breadcrumbItems" />

				<!-- Hero Section -->
				<div
					class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden mb-6 border border-gray-200 dark:border-gray-700">
					<!-- Header with gradient/cover -->
					<div class="relative bg-gradient-to-r from-[#d8a735] via-[#eacf6f] to-[#e1b74c] p-6"
						:style="projectCover ? `background-image: url('${projectCover}'); background-size: cover; background-position: center;` : ''">
						<div class="absolute inset-0" :class="projectCover ? 'bg-black/50' : 'bg-black/10'"></div>
						<div class="relative flex items-start justify-between">
							<div class="flex items-center space-x-4">
								<div
									class="w-16 h-16 bg-white rounded-xl shadow-sm flex items-center justify-center overflow-hidden border-2 border-white/30">
									<img v-if="projectLogo" :src="projectLogo" :alt="projectName"
										class="w-full h-full object-cover"
										@error="(e) => { (e.target as HTMLImageElement).style.display = 'none' }">
									<div v-else class="text-2xl font-bold text-[#b27c10]">
										{{ projectName.charAt(0) }}
									</div>
								</div>
								<div>
									<h1 class="text-2xl font-bold text-white mb-1">{{ projectName }}</h1>
									<div class="flex items-center space-x-3">
										<span class="text-lg font-semibold text-white/90">{{ saleTokenSymbol }}</span>
										<StatusBadge v-if="launchpad" :status="launchpad.status" />
										<span v-if="categoryDisplay"
											class="px-2 py-0.5 bg-white/20 text-white rounded-full text-xs font-medium">
											{{ categoryDisplay }}
										</span>
									</div>
								</div>
							</div>

							<!-- Quick Stats with Refresh -->
							<div class="text-right flex items-center gap-2">
								<div class="text-white">
									<p class="text-xs opacity-90 mb-1">Total Raised</p>
									<p class="text-2xl font-bold">{{ formatAmount(totalRaised, purchaseTokenDecimals) }}
										{{
											purchaseTokenSymbol }}</p>
									<p class="text-xs opacity-80">of {{ formatAmount(hardCap, purchaseTokenDecimals) }}
										{{
											purchaseTokenSymbol }}</p>
								</div>
								<button @click="refreshStats" :disabled="refreshingStats"
									class="text-white/80 hover:text-white transition-all disabled:opacity-50 disabled:cursor-not-allowed"
									title="Refresh stats">
									<svg :class="['w-5 h-5', refreshingStats ? 'animate-spin' : '']" fill="none"
										stroke="currentColor" viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
											d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
									</svg>
								</button>
							</div>
						</div>
					</div>

					<!-- Progress Bar -->
					<div class="px-6 py-4 bg-gray-50 dark:bg-gray-900">
						<div class="flex items-center justify-between mb-2">
							<span class="text-xs font-semibold text-gray-700 dark:text-gray-300">Sale Progress</span>
							<span class="text-xs font-semibold text-[#d8a735]">{{ progressPercentage.toFixed(2)
								}}%</span>
						</div>
						<div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 overflow-hidden relative">
							<!-- Progress Fill -->
							<div :style="{ width: progressPercentage + '%' }"
								class="bg-gradient-to-r from-[#b27c10] via-[#d8a735] to-[#e1b74c] h-2 rounded-full transition-all duration-1000 ease-out relative overflow-hidden">
								<div
									class="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer">
								</div>
							</div>

							<!-- Softcap Marker -->
							<div :style="{ left: `calc(${(Number(softCap) / Number(hardCap)) * 100}% - 4px)` }"
								class="absolute top-1/2 -translate-y-1/2 w-2 h-2 bg-blue-500 dark:bg-blue-400 rounded-full border-2 border-white dark:border-gray-900 shadow-lg transition-all duration-300"
								:class="{ 'ring-2 ring-blue-400 dark:ring-blue-300 ring-offset-1': softCapProgress >= 100 }"
								:title="`Soft Cap: ${formatAmount(softCap, purchaseTokenDecimals)} ${purchaseTokenSymbol}`">
							</div>
						</div>
						<div class="flex items-center justify-between mt-2 text-xs text-gray-600 dark:text-gray-400">
							<div>
								<span class="font-medium">Soft Cap:</span> {{ formatAmount(softCap,
								purchaseTokenDecimals) }} {{
									purchaseTokenSymbol }}
								<span v-if="softCapProgress >= 100"
									class="ml-2 text-green-600 dark:text-green-400">✓</span>
							</div>
							<div>
								<span class="font-medium">Participants:</span> {{ participantCount }}
							</div>
						</div>
					</div>
				</div>

				<!-- Main Content Area (Hero + Grid) -->
				<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
					<!-- Tab Content Area (2/3 width) -->
					<div class="lg:col-span-2">
						<!-- Tab Navigation -->
						<div
							class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
							<div class="border-b border-gray-200 dark:border-gray-700">
								<nav class="flex space-x-6 px-4" aria-label="Tabs">
									<button v-for="tab in tabs" :key="tab.id" @click="activeTab = tab.id" :class="[
										activeTab === tab.id
											? 'border-[#d8a735] text-[#d8a735]'
											: 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300',
										'whitespace-nowrap py-3 px-1 border-b-2 font-medium text-sm transition-colors'
									]">
										{{ tab.label }}
									</button>
								</nav>
							</div>

							<!-- Tab Content -->
							<div class="p-4">
								<!-- Overview Tab -->
								<div v-show="activeTab === 'overview'" class="space-y-4">
									<!-- Project Info -->
									<div>
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
											</svg>
											About the Project
										</h3>
										<p
											class="text-sm text-gray-700 dark:text-gray-300 leading-relaxed whitespace-pre-wrap">
											{{
												projectDescription }}</p>

										<!-- Project Links -->
										<div v-if="hasProjectLinks"
											class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
											<h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">
												Official Links</h4>
											<div class="flex flex-wrap gap-2">
												<a v-if="projectWebsite" :href="projectWebsite" target="_blank"
													class="inline-flex items-center px-3 py-1.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-[#eacf6f] hover:text-[#b27c10] dark:hover:bg-[#d8a735] dark:hover:text-white transition-all text-sm">
													<svg class="w-3.5 h-3.5 mr-1.5" fill="none" stroke="currentColor"
														viewBox="0 0 24 24">
														<path stroke-linecap="round" stroke-linejoin="round"
															stroke-width="2"
															d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9" />
													</svg>
													Website
												</a>
												<a v-if="projectTwitter" :href="projectTwitter" target="_blank"
													class="inline-flex items-center px-3 py-1.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-[#eacf6f] hover:text-[#b27c10] dark:hover:bg-[#d8a735] dark:hover:text-white transition-all text-sm">
													<svg class="w-3.5 h-3.5 mr-1.5" fill="currentColor"
														viewBox="0 0 24 24">
														<path
															d="M23 3a10.9 10.9 0 01-3.14 1.53 4.48 4.48 0 00-7.86 3v1A10.66 10.66 0 013 4s-4 9 5 13a11.64 11.64 0 01-7 2c9 5 20 0 20-11.5a4.5 4.5 0 00-.08-.83A7.72 7.72 0 0023 3z" />
													</svg>
													Twitter
												</a>
												<a v-if="projectTelegram" :href="projectTelegram" target="_blank"
													class="inline-flex items-center px-3 py-1.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-[#eacf6f] hover:text-[#b27c10] dark:hover:bg-[#d8a735] dark:hover:text-white transition-all text-sm">
													<svg class="w-3.5 h-3.5 mr-1.5" fill="currentColor"
														viewBox="0 0 24 24">
														<path
															d="M12 0C5.373 0 0 5.373 0 12s5.373 12 12 12 12-5.373 12-12S18.627 0 12 0zm5.894 8.221l-1.97 9.28c-.145.658-.537.818-1.084.508l-3-2.21-1.446 1.394c-.14.18-.357.295-.6.295-.002 0-.003 0-.005 0l.213-3.054 5.56-5.022c.24-.213-.054-.334-.373-.121l-6.869 4.326-2.96-.924c-.64-.203-.658-.64.135-.954l11.566-4.458c.538-.196 1.006.128.832.941z" />
													</svg>
													Telegram
												</a>
												<a v-if="projectGithub" :href="projectGithub" target="_blank"
													class="inline-flex items-center px-3 py-1.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-[#eacf6f] hover:text-[#b27c10] dark:hover:bg-[#d8a735] dark:hover:text-white transition-all text-sm">
													<svg class="w-3.5 h-3.5 mr-1.5" fill="currentColor"
														viewBox="0 0 24 24">
														<path
															d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
													</svg>
													GitHub
												</a>
												<a v-if="projectDiscord" :href="projectDiscord" target="_blank"
													class="inline-flex items-center px-3 py-1.5 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-[#eacf6f] hover:text-[#b27c10] dark:hover:bg-[#d8a735] dark:hover:text-white transition-all text-sm">
													<svg class="w-3.5 h-3.5 mr-1.5" fill="currentColor"
														viewBox="0 0 24 24">
														<path
															d="M20.317 4.37a19.791 19.791 0 00-4.885-1.515.074.074 0 00-.079.037c-.211.375-.445.865-.608 1.25a18.27 18.27 0 00-5.487 0 12.64 12.64 0 00-.617-1.25.077.077 0 00-.079-.037A19.736 19.736 0 003.677 4.37a.07.07 0 00-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 00.031.057 19.9 19.9 0 005.993 3.03.078.078 0 00.084-.028c.462-.63.874-1.295 1.226-1.994.021-.041.001-.09-.041-.106a13.107 13.107 0 01-1.872-.892.077.077 0 01-.008-.128 10.2 10.2 0 00.372-.292.074.074 0 01.077-.01c3.928 1.793 8.18 1.793 12.062 0 a.074.074 0 01.078.01c.12.098.246.198.373.292a.077.077 0 01-.006.127 12.299 12.299 0 01-1.873.892.077.077 0 00-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 00.084.028 19.839 19.839 0 006.002-3.03.077.077 0 00.032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 00-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
													</svg>
													Discord
												</a>
											</div>
										</div>

										<!-- Trust Indicators -->
										<div v-if="isAudited || isKYCed"
											class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
											<div class="flex flex-wrap gap-2">
												<div v-if="isAudited"
													class="flex items-center px-3 py-1.5 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-lg text-sm">
													<svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor"
														viewBox="0 0 24 24">
														<path stroke-linecap="round" stroke-linejoin="round"
															stroke-width="2"
															d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
													</svg>
													<span class="font-semibold">Audited</span>
												</div>
												<div v-if="isKYCed"
													class="flex items-center px-3 py-1.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400 rounded-lg text-sm">
													<svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor"
														viewBox="0 0 24 24">
														<path stroke-linecap="round" stroke-linejoin="round"
															stroke-width="2"
															d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
													</svg>
													<span class="font-semibold">KYC Verified</span>
													<span v-if="kycProvider" class="ml-1.5 text-xs">by {{ kycProvider
														}}</span>
												</div>
											</div>
										</div>
									</div>

									<!-- Sale Parameters -->
									<div>
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
											</svg>
											Sale Parameters
										</h3>
										<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
											<InfoCard label="Sale Type" :value="saleTypeDisplay" />
											<InfoCard label="Allocation Method" :value="allocationMethodDisplay" />
											<InfoCard label="Token Price"
												:value="`1 ${saleTokenSymbol} = ${tokenPrice} ${purchaseTokenSymbol}`" />
											<InfoCard label="Min Contribution"
												:value="`${formatAmount(minContribution, purchaseTokenDecimals)} ${purchaseTokenSymbol}`" />
											<InfoCard label="Max Contribution"
												:value="maxContribution ? `${formatAmount(maxContribution, purchaseTokenDecimals)} ${purchaseTokenSymbol}` : 'No limit'" />
											<InfoCard label="Max Participants"
												:value="maxParticipants ? maxParticipants.toString() : 'Unlimited'" />
											<InfoCard label="Total Sale Amount"
												:value="formatTokenAmount(totalSaleAmount)" />
											<InfoCard label="Soft Cap"
												:value="`${formatAmount(softCap, purchaseTokenDecimals)} ${purchaseTokenSymbol}`" />
											<InfoCard label="Hard Cap"
												:value="`${formatAmount(hardCap, purchaseTokenDecimals)} ${purchaseTokenSymbol}`" />
										</div>
									</div>

									<!-- Multi-DEX Liquidity Allocation -->
									<div v-if="dexPlatforms.length > 0 && isSaleStarted">
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
											</svg>
											DEX Liquidity Allocation
										</h3>

										<!-- Total Raised for DEX -->
										<div
											class="bg-gradient-to-r from-[#eacf6f]/10 to-[#f5e590]/10 rounded-lg p-4 mb-3 border border-[#d8a735]/20">
											<div class="flex items-center justify-between">
												<div>
													<p class="text-xs text-gray-600 dark:text-gray-400">Total for LP</p>
													<p class="text-xl font-bold text-gray-900 dark:text-white">
														{{ formatAmount(actualLPAmount, purchaseTokenDecimals) }} {{
														purchaseTokenSymbol }}
													</p>
													<p class="text-xs text-[#b27c10] mt-1">
														{{ totalDexAllocationPercent }}% of {{ formatAmount(totalRaised,
														purchaseTokenDecimals) }}
														{{ purchaseTokenSymbol }} raised
													</p>
												</div>
												<div class="text-right">
													<p class="text-xs text-gray-600 dark:text-gray-400">Est. Listing</p>
													<p class="text-sm font-semibold text-gray-900 dark:text-white">{{
														estimatedListingTime }}</p>
												</div>
											</div>
										</div>

										<!-- DEX Platforms -->
										<div class="space-y-2">
											<div v-for="(platform, index) in dexPlatforms" :key="index"
												class="bg-white dark:bg-gray-800 rounded-lg p-3 border border-gray-200 dark:border-gray-700">
												<div class="flex items-center justify-between">
													<div class="flex items-center space-x-2">
														<div
															class="w-8 h-8 bg-gradient-to-r from-[#b27c10] to-[#e1b74c] rounded-lg flex items-center justify-center">
															<span class="text-white text-sm font-bold">{{
																platform.name.charAt(0) }}</span>
														</div>
														<div>
															<p class="text-sm font-bold text-gray-900 dark:text-white">
																{{ platform.name }}</p>
															<p class="text-xs text-[#d8a735]">{{
																platform.allocationPercentage }}% Allocation</p>
														</div>
													</div>
													<div class="text-right">
														<div class="flex items-baseline gap-1 justify-end">
															<p
																class="text-sm font-semibold text-gray-900 dark:text-white">
																{{
																	formatAmount(BigInt(platform.calculatedPurchaseLiquidity),
																purchaseTokenDecimals) }}
																{{ purchaseTokenSymbol }}
															</p>
															<span class="text-xs text-gray-500 dark:text-gray-400">
																({{
																	calculateDexPercentage(platform.calculatedPurchaseLiquidity)
																}}%)
															</span>
														</div>
														<p class="text-xs text-gray-600 dark:text-gray-400">LP Value</p>
													</div>
												</div>
											</div>
										</div>
									</div>

									<!-- Waiting for Sale Start (DEX) -->
									<div v-else-if="dexPlatforms.length > 0 && !isSaleStarted">
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-3 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
											</svg>
											DEX Liquidity Allocation
										</h3>
										<div
											class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-200 dark:border-gray-700 text-center">
											<svg class="w-12 h-12 mx-auto text-gray-400 dark:text-gray-600 mb-2"
												fill="none" stroke="currentColor" viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
											</svg>
											<p class="text-sm font-medium text-gray-900 dark:text-white mb-1">Waiting
												for Sale Start</p>
											<p class="text-xs text-gray-600 dark:text-gray-400">
												Liquidity allocation will be calculated after the sale begins
											</p>
										</div>
									</div>

									<!-- Pipeline Timeline -->
									<div>
										<h3
											class="text-base font-bold text-gray-900 dark:text-white mb-3 flex items-center">
											<svg class="w-4 h-4 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
											</svg>
											Deployment Pipeline
										</h3>
										<PipelineTimeline :sale-started="isSaleActiveOrBeyond"
											:sale-ended="isSaleEndedOrBeyond" :softcap-reached="softCapProgress >= 100"
											:token-deployed="!!deployedContracts.tokenCanister && deployedContracts.tokenCanister.length > 0"
											:distribution-deployed="deployedContracts.vestingContracts.length > 0"
											:dex-listed="!!deployedContracts.liquidityPool && deployedContracts.liquidityPool.length > 0"
											:token-symbol="saleTokenSymbol" />
									</div>
								</div>
								<!-- Tokenomics Tab Content -->
								<div v-show="activeTab === 'tokenomics'" class="space-y-4">
									<div>
										<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-3">Token
											Distribution</h3>
										<DistributionChart v-if="tokenDistributionItems.length > 0"
											:items="tokenDistributionItems" total-label="Total Supply"
											:value-formatter="(val) => formatTokenAmount(val)" />
									</div>

									<!-- Vesting Schedules -->
									<div>
										<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-3">Vesting
											Schedules</h3>
										<div class="grid grid-cols-1 md:grid-cols-2 gap-3">
											<VestingCard v-for="(vesting, index) in vestingSchedules" :key="index"
												:title="vesting.name" :immediate-release="vesting.immediateRelease"
												:cliff-days="vesting.cliffDays" :duration-days="vesting.durationDays"
												:release-frequency="vesting.releaseFrequency"
												:description="vesting.description" :badge="vesting.badge" />
										</div>
									</div>
								</div>

								<!-- Raised Funds Tab Content -->
								<div v-show="activeTab === 'raised-funds'" class="space-y-4">
									<div>
										<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-3">Raised Funds
											Allocation</h3>
										<DistributionChart v-if="raisedFundsItems.length > 0" :items="raisedFundsItems"
											total-label="Total Raised Funds"
											:value-formatter="(val) => formatAmount(BigInt(Math.floor(val)), purchaseTokenDecimals) + ' ' + purchaseTokenSymbol" />
									</div>

									<!-- Recipients Details -->
									<div v-if="raisedFundsRecipients.length > 0">
										<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-3">Recipients &
											Vesting</h3>
										<div class="space-y-3">
											<div v-for="(recipient, index) in raisedFundsRecipients" :key="index"
												class="bg-gray-50 dark:bg-gray-900 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
												<div class="flex items-start justify-between mb-3">
													<div>
														<h4
															class="text-base font-semibold text-gray-900 dark:text-white">
															{{ recipient.category }}</h4>
														<p v-if="recipient.name"
															class="text-xs text-gray-600 dark:text-gray-400 mt-1">{{
															recipient.name }}</p>
													</div>
													<div class="text-right">
														<p class="text-xs text-gray-600 dark:text-gray-400">Allocation
														</p>
														<p class="text-base font-bold text-[#d8a735]">{{
															recipient.percentage }}%</p>
													</div>
												</div>

												<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
													<div>
														<p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Details
														</p>
														<p class="text-gray-700 dark:text-gray-300">{{ recipient.details
															}}</p>
													</div>
													<div class="text-right">
														<p class="text-xs text-gray-500 dark:text-gray-400 mb-1">Vesting
														</p>
														<p class="text-gray-700 dark:text-gray-300">{{ recipient.vesting
															}}</p>
													</div>
												</div>
											</div>
										</div>
									</div>
								</div>

								<!-- Manager Tab (Owner Only) -->
								<div v-show="activeTab === 'manager'" class="space-y-6">
									<!-- Version Management Section -->
									<VersionManagement ref="versionManagementRef" factory-type="launchpad"
										:canister-id="canisterId" :is-owner="isOwner"
										@upgraded="handleVersionUpgraded" />

									<!-- Quick Actions -->
									<div
										class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M13 10V3L4 14h7v7l9-11h-7z" />
											</svg>
											Quick Actions
										</h3>

										<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
											<!-- Pause/Resume Sale -->
											<button @click="handlePauseResume" :disabled="!canPauseResume"
												class="flex items-center justify-center p-4 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg hover:bg-yellow-100 dark:hover:bg-yellow-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
												<svg class="w-5 h-5 mr-2 text-yellow-600 dark:text-yellow-400"
													fill="none" stroke="currentColor" viewBox="0 0 24 24">
													<path stroke-linecap="round" stroke-linejoin="round"
														stroke-width="2"
														d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z" />
												</svg>
												<span
													class="text-sm font-semibold text-yellow-700 dark:text-yellow-300">{{
														isSalePaused ? 'Resume Sale' : 'Pause Sale' }}</span>
											</button>

											<!-- Emergency Stop -->
											<button @click="handleEmergencyStop" :disabled="!canEmergencyStop"
												class="flex items-center justify-center p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg hover:bg-red-100 dark:hover:bg-red-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
												<svg class="w-5 h-5 mr-2 text-red-600 dark:text-red-400" fill="none"
													stroke="currentColor" viewBox="0 0 24 24">
													<path stroke-linecap="round" stroke-linejoin="round"
														stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
													<path stroke-linecap="round" stroke-linejoin="round"
														stroke-width="2" d="M9 10h6v4H9z" />
												</svg>
												<span
													class="text-sm font-semibold text-red-700 dark:text-red-300">Emergency
													Stop</span>
											</button>

											<!-- Update Settings -->
											<button @click="handleUpdateSettings" :disabled="!canUpdateSettings"
												class="flex items-center justify-center p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
												<svg class="w-5 h-5 mr-2 text-blue-600 dark:text-blue-400" fill="none"
													stroke="currentColor" viewBox="0 0 24 24">
													<path stroke-linecap="round" stroke-linejoin="round"
														stroke-width="2"
														d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
												</svg>
												<span
													class="text-sm font-semibold text-blue-700 dark:text-blue-300">Update
													Settings</span>
											</button>

											<!-- Deploy Token -->
											<button @click="handleDeployToken" :disabled="!canDeployToken"
												class="flex items-center justify-center p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg hover:bg-green-100 dark:hover:bg-green-900/30 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
												<svg class="w-5 h-5 mr-2 text-green-600 dark:text-green-400" fill="none"
													stroke="currentColor" viewBox="0 0 24 24">
													<path stroke-linecap="round" stroke-linejoin="round"
														stroke-width="2"
														d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
												</svg>
												<span
													class="text-sm font-semibold text-green-700 dark:text-green-300">Deploy
													Token</span>
											</button>
										</div>
									</div>

									<!-- Edit Basic Information -->
									<div
										class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
											</svg>
											Edit Project Information
										</h3>

										<div class="space-y-4">
											<!-- Description -->
											<div>
												<label
													class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
													Description
												</label>
												<textarea v-model="editForm.description" rows="6"
													class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
													placeholder="Project description..."></textarea>
											</div>

											<!-- Website & Social Links -->
											<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Website</label>
													<input v-model="editForm.website" type="url"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="https://myproject.com" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Twitter</label>
													<input v-model="editForm.twitter" type="text"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="@myproject" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Telegram</label>
													<input v-model="editForm.telegram" type="text"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="myproject" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Discord</label>
													<input v-model="editForm.discord" type="url"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="https://discord.gg/myproject" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">GitHub</label>
													<input v-model="editForm.github" type="url"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="https://github.com/myproject" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Medium</label>
													<input v-model="editForm.medium" type="url"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="https://medium.com/@myproject" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Reddit</label>
													<input v-model="editForm.reddit" type="url"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="https://reddit.com/r/myproject" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">YouTube</label>
													<input v-model="editForm.youtube" type="url"
														class="w-full px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-[#d8a735] focus:border-[#d8a735] dark:bg-gray-700 dark:text-white"
														placeholder="https://youtube.com/@myproject" />
												</div>
											</div>

											<div
												class="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
												<button @click="resetEditForm"
													class="px-4 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
													Reset
												</button>
												<button @click="saveProjectInfo" :disabled="isSaving"
													class="px-6 py-2 bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white rounded-lg hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all">
													{{ isSaving ? 'Saving...' : 'Save Changes' }}
												</button>
											</div>
										</div>
									</div>

									<!-- Edit Images -->
									<div
										class="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700">
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
											</svg>
											Edit Project Images
										</h3>

										<div class="space-y-4">
											<div class="grid grid-cols-1 md:grid-cols-2 gap-6">
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Project
														Logo URL</label>
													<URLImageInput v-model="editForm.logo"
														placeholder="https://example.com/logo.png"
														preview-class="h-32 w-32"
														help-text="Square format (512x512px)" />
												</div>
												<div>
													<label
														class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Cover
														Image URL</label>
													<URLImageInput v-model="editForm.cover"
														placeholder="https://example.com/cover.png"
														preview-class="max-h-32 max-w-full"
														help-text="Wide format (1920x600px)" />
												</div>
											</div>

											<div
												class="flex justify-end space-x-3 pt-4 border-t border-gray-200 dark:border-gray-700">
												<button @click="saveProjectImages" :disabled="isSavingImages"
													class="px-6 py-2 bg-gradient-to-r from-[#d8a735] to-[#b27c10] text-white rounded-lg hover:shadow-lg disabled:opacity-50 disabled:cursor-not-allowed transition-all">
													{{ isSavingImages ? 'Saving...' : 'Update Images' }}
												</button>
											</div>
										</div>
									</div>

									<!-- Contract Information -->
									<div
										class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 border border-gray-200 dark:border-gray-700">
										<h3
											class="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
											<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
												viewBox="0 0 24 24">
												<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
													d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
											</svg>
											Contract Information (Pipeline deployment)
										</h3>

										<div class="space-y-4">
											<!-- Contract Addresses -->
											<div>
												<h4 class="text-base font-semibold text-gray-900 dark:text-white mb-3">
													Deployed Contracts</h4>
												<div class="space-y-2">
													<div v-if="deployedContracts.tokenCanister && deployedContracts.tokenCanister.length > 0"
														class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<div>
															<p class="text-sm font-semibold text-gray-900 dark:text-white">
																Token Canister</p>
															<p class="text-xs text-gray-500 dark:text-gray-400">{{
																deployedContracts.tokenCanister && deployedContracts.tokenCanister.length > 0 ? deployedContracts.tokenCanister : 'Not Deployed' }}</p>
														</div>
														<CopyIcon :data="deployedContracts.tokenCanister" v-if="deployedContracts.tokenCanister.length > 0"
															class="w-4 h-4 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer"
															msg="Token Canister ID" />
													</div>
													<div v-if="deployedContracts.vestingContracts.length > 0 && deployedContracts.vestingContracts.length > 0"
														class="p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<p class="text-sm font-semibold text-gray-900 dark:text-white mb-2">
															Vesting Contracts</p>
														<div v-for="(vesting, index) in deployedContracts.vestingContracts"
															:key="index"
															class="flex items-center justify-between mb-2 last:mb-0">
															<p class="text-xs text-gray-500 dark:text-gray-400">{{
																vesting && vesting.length > 0 ? vesting : 'Not Deployed' }}</p>
															<CopyIcon :data="vesting" v-if="vesting.length > 0"
																class="w-3 h-3 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer"
																msg="Vesting Contract ID" />
														</div>
													</div>
													<div v-if="deployedContracts.liquidityPool && deployedContracts.liquidityPool.length > 0"
														class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<div>
															<p
																class="text-sm font-semibold text-gray-900 dark:text-white">
																Liquidity Pool</p>
															<p class="text-xs text-gray-500 dark:text-gray-400">{{
																deployedContracts.liquidityPool && deployedContracts.liquidityPool.length > 0 ? deployedContracts.liquidityPool : 'Not Deployed' }}</p>
														</div>
														<CopyIcon :data="deployedContracts.liquidityPool" v-if="deployedContracts.liquidityPool.length > 0"
															class="w-4 h-4 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer"
															msg="Liquidity Pool ID" />
													</div>
												</div>
											</div>

											<!-- Contract Status -->
											<div>
												<h4 class="text-base font-semibold text-gray-900 dark:text-white mb-3">
													Contract Status</h4>
												<div class="grid grid-cols-1 md:grid-cols-2 gap-3">
													<div
														class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<span class="text-sm text-gray-600 dark:text-gray-400">Sale
															Contract</span>
														<span
															class="text-sm font-semibold text-green-600 dark:text-green-400">Active</span>
													</div>
													<div
														class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<span class="text-sm text-gray-600 dark:text-gray-400">Token
															Contract</span>
														<span
															:class="deployedContracts.tokenCanister && deployedContracts.tokenCanister.length > 0 ? 'text-sm font-semibold text-green-600 dark:text-green-400' : 'text-sm font-semibold text-orange-600 dark:text-orange-400'">
															{{ deployedContracts.tokenCanister && deployedContracts.tokenCanister.length > 0 ? 'Deployed' : 'Not Deployed' }}
														</span>
													</div>
													<div
														class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<span class="text-sm text-gray-600 dark:text-gray-400">Vesting
															Contracts</span>
														<span
															:class="deployedContracts.vestingContracts.length > 0 && deployedContracts.vestingContracts.length > 0 ? 'text-sm font-semibold text-green-600 dark:text-green-400' : 'text-sm font-semibold text-orange-600 dark:text-orange-400'">
															{{ deployedContracts.vestingContracts.length > 0 && deployedContracts.vestingContracts.length > 0 ?
																`${deployedContracts.vestingContracts.length} Deployed` : deployedContracts.vestingContracts.length > 0 ? 'Deployed' : 'Not Deployed' }}
														</span>
													</div>
													<div
														class="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-900 rounded-lg">
														<span class="text-sm text-gray-600 dark:text-gray-400">Liquidity
															Pool</span>
														<span
															:class="deployedContracts.liquidityPool && deployedContracts.liquidityPool.length > 0 ? 'text-sm font-semibold text-green-600 dark:text-green-400' : 'text-sm font-semibold text-orange-600 dark:text-orange-400'">
															{{ deployedContracts.liquidityPool && deployedContracts.liquidityPool.length > 0 ? 'Created' : 'Not Created' }}
														</span>
													</div>
												</div>
											</div>
										</div>
									</div>
								</div>
							</div>
						</div>


					</div>
					<div class="lg:col">
						<!-- Sidebar (1/3 width) -->
						<div class="space-y-4">
							<!-- Timeline Card -->
							<div
								class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 border border-gray-200 dark:border-gray-700">
								<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4 flex items-center">
									<svg class="w-5 h-5 mr-2 text-[#d8a735]" fill="none" stroke="currentColor"
										viewBox="0 0 24 24">
										<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
											d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
									</svg>
									Timeline
								</h3>
								<div class="space-y-3">
									<TimelineItem label="Sale Start" :date="formatTimestamp(saleStart)"
										:status="saleStartStatus" :active="isSaleActive" />
									<TimelineItem label="Sale End" :date="formatTimestamp(saleEnd)"
										:status="saleEndStatus" :active="false" />
									<TimelineItem v-if="claimStart" label="Claim Start"
										:date="formatTimestamp(claimStart)" :status="claimStartStatus"
										:active="false" />
									<TimelineItem v-if="listingTime" label="Listing Time"
										:date="formatTimestamp(listingTime)" :status="listingTimeStatus"
										:active="listingTimeActive" />
								</div>
							</div>

							<!-- Action Card -->
							<div
								class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 border border-gray-200 dark:border-gray-700 sticky top-8">
								<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">Participate</h3>

								<!-- ICTO Passport Score Requirement (if required) -->
								<div v-if="minPassportScore > 0"
									class="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
									<div class="flex items-center justify-between mb-2">
										<span class="text-xs font-semibold text-blue-700 dark:text-blue-400">ICTO
											Passport Required</span>
										<span class="text-xs font-bold text-blue-900 dark:text-blue-300">{{
											minPassportScore }}+
											Score</span>
									</div>
									<div class="flex items-center justify-between">
										<span class="text-xs text-gray-600 dark:text-gray-400">Your Score:</span>
										<span :class="[
											'text-xs font-semibold',
											userPassportScore >= minPassportScore
												? 'text-green-600 dark:text-green-400'
												: 'text-red-600 dark:text-red-400'
										]">
											{{ userPassportScore }} {{ userPassportScore >= minPassportScore ? '✓' : '✗'
											}}
										</span>
									</div>
									<p v-if="userPassportScore < minPassportScore"
										class="mt-2 text-xs text-red-600 dark:text-red-400">
										Your score is below the minimum requirement.
									</p>
								</div>

								<!-- Deposit Action -->
								<button @click="handleDeposit"
									:disabled="!canParticipate || (minPassportScore > 0 && userPassportScore < minPassportScore)"
									class="w-full px-4 py-3 bg-gradient-to-r from-[#b27c10] via-[#d8a735] to-[#e1b74c] text-white font-bold rounded-lg shadow-md hover:shadow-lg transform hover:-translate-y-0.5 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0 relative overflow-hidden group text-sm">
									<span class="relative z-10">
										{{ participateButtonText }}
									</span>
									<div
										class="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent translate-x-[-100%] group-hover:translate-x-[100%] transition-transform duration-1000">
									</div>
								</button>

								<!-- Quick Stats -->
								<div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700 space-y-3">
									<!-- Your Deposited (Recorded Contribution) -->
									<div v-if="authStore.isConnected" class="flex items-center justify-between">
										<span class="text-sm text-gray-600 dark:text-gray-400">Your Deposited</span>
										<span class="text-sm font-semibold text-green-600 dark:text-green-400">
											{{ formatAmount(userDeposited, purchaseTokenDecimals) }} {{
											purchaseTokenSymbol }}
										</span>
									</div>

									<div class="flex items-center justify-between">
										<span class="text-sm text-gray-600 dark:text-gray-400">Your Allocation</span>
										<span class="text-sm font-semibold text-gray-900 dark:text-white">TBA</span>
									</div>
									<div class="flex items-center justify-between">
										<span class="text-sm text-gray-600 dark:text-gray-400">Claimable</span>
										<span class="text-sm font-semibold text-gray-900 dark:text-white">0 {{
											saleTokenSymbol }}</span>
									</div>
								</div>

								<!-- Contract Info -->
								<div class="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
									<h4 class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">Contract
										<span class="text-xs text-gray-700 dark:text-gray-300 ">V{{ contractVersion
											}}</span>
									</h4>
									<div class="space-y-2">
										<!-- Canister ID -->
										<div
											class="flex items-center space-x-2 bg-gray-50 dark:bg-gray-900 rounded-lg p-2">
											<span v-if="canisterId"
												class="text-xs text-gray-600 dark:text-gray-400 flex-1">{{ canisterId
												}}</span>
											<CopyIcon :data="canisterId"
												class="w-4 h-4 text-[#d8a735] hover:text-[#b27c10] transition-colors cursor-pointer"
												msg="Canister ID" />
										</div>
									</div>
								</div>
							</div>

							<!-- Token Info -->
							<div
								class="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-4 border border-gray-200 dark:border-gray-700">
								<h3 class="text-lg font-bold text-gray-900 dark:text-white mb-4">Token Details</h3>
								<div class="space-y-3">
									<div>
										<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Token Name</p>
										<p class="text-base font-semibold text-gray-900 dark:text-white">{{
											saleTokenName }}</p>
									</div>
									<div>
										<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Symbol</p>
										<p class="text-base font-semibold text-gray-900 dark:text-white">{{
											saleTokenSymbol }}</p>
									</div>
									<div>
										<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Total Supply</p>
										<p class="text-base font-semibold text-gray-900 dark:text-white">{{
											formatTokenAmount(Number(totalSupply)) }}</p>
									</div>
									<div>
										<p class="text-sm text-gray-600 dark:text-gray-400 mb-1">Standard</p>
										<p class="text-base font-semibold text-gray-900 dark:text-white">{{
											saleTokenStandard }}</p>
									</div>
								</div>
							</div>
						</div>
					</div>
				</div>
			</div>


		</div>

		<!-- Participants Section (Full Width Below Main Content) -->
		<div class="w-full mt-6">
			<div class="mx-auto">
				<Participants :canister-id="canisterId" :purchase-token-symbol="purchaseTokenSymbol"
					:purchase-token-decimals="purchaseTokenDecimals" :sale-token-symbol="saleTokenSymbol" />
			</div>
		</div>

		<!-- Affiliate Stats Section (Full Width Below Main Content) -->
		<div class="w-full mt-6">
			<div class="mx-auto">
				<AffiliateStats :canister-id="canisterId" :purchase-token-symbol="purchaseTokenSymbol"
					:purchase-token-decimals="purchaseTokenDecimals"
					:commission-rate="launchpad?.config.affiliateConfig?.commissionRate || 5" />
			</div>
		</div>
	</AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { LaunchpadService } from '@/api/services/launchpad'
import type { LaunchpadDetail } from '@/types/launchpad'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import StatusBadge from '@/components/launchpad/StatusBadge.vue'
import InfoCard from '@/components/launchpad/InfoCard.vue'
import TimelineItem from '@/components/launchpad/TimelineItem.vue'
import PipelineTimeline from '@/components/launchpad/PipelineTimeline.vue'
import DistributionChart from '@/components/launchpad/DistributionChart.vue'
import VestingCard from '@/components/launchpad/VestingCard.vue'
import URLImageInput from '@/components/common/URLImageInput.vue'
import Breadcrumb from '@/components/common/Breadcrumb.vue'
import VersionManagement from '@/components/common/VersionManagement.vue'
import Participants from '@/components/launchpad/Participants.vue'
import AffiliateStats from '@/components/launchpad/AffiliateStats.vue'
import RaisedFundsAllocation from '@/components/launchpad/RaisedFundsAllocation.vue'
import FundAllocationOverview from '@/components/launchpad/FundAllocationOverview.vue'
import { toast } from 'vue-sonner'
import { useModalStore } from '@/stores/modal'
import { launchpadContractActor, useAuthStore } from '@/stores/auth'
import { useSwal } from '@/composables/useSwal2'
import CopyIcon from '@/icons/CopyIcon.vue'
// State
const route = useRoute()
const launchpadService = LaunchpadService.getInstance()
const modalStore = useModalStore()
const authStore = useAuthStore()

const loading = ref(true)
const error = ref<string | null>(null)
const launchpad = ref<LaunchpadDetail | null>(null)
const activeTab = ref('overview')
const projectImages = ref<{ logo?: string; cover?: string }>({})  // Fetch separately to avoid large payload

const isSaving = ref(false)
const isSavingImages = ref(false)

// Version Management Ref
const versionManagementRef = ref<InstanceType<any> | null>(null)

const editForm = ref({
	description: '',
	website: '',
	twitter: '',
	telegram: '',
	discord: '',
	github: '',
	medium: '',
	reddit: '',
	youtube: '',
	logo: '',
	cover: ''
})

// Check if current user is the owner
const isOwner = computed(() => {
	if (!launchpad.value) {
		console.log('[LaunchpadDetail] isOwner: No launchpad data')
		return false
	}

	try {
		// Get user principal from multiple sources
		let userPrincipal: string | null = null

		// Try authStore.principal first
		if (authStore.principal) {
			userPrincipal = authStore.principal
		}
		// Fallback to pnp.owner
		else if ((authStore.pnp as any)?.owner) {
			userPrincipal = (authStore.pnp as any).owner.toString()
		}

		console.log('[LaunchpadDetail] Principal check:', {
			fromAuthStore: authStore.principal,
			fromPNP: (authStore.pnp as any)?.owner?.toString(),
			finalPrincipal: userPrincipal,
			isConnected: authStore.isConnected
		})

		if (!userPrincipal) {
			console.log('[LaunchpadDetail] ❌ No user principal found - wallet not connected?')
			return false
		}

		// Handle both string and Principal object types for creator
		const creatorPrincipal = typeof launchpad.value.creator === 'string'
			? launchpad.value.creator
			: launchpad.value.creator.toText()

		const isMatch = userPrincipal === creatorPrincipal

		console.log('[LaunchpadDetail] isOwner result:', {
			userPrincipal,
			creatorPrincipal,
			isMatch: isMatch ? '✅ YES - USER IS OWNER!' : '❌ NO - Different principal'
		})

		return isMatch
	} catch (err) {
		console.error('[LaunchpadDetail] Error checking owner:', err)
		return false
	}
})

const tabs = computed(() => {
	const baseTabs = [
		{ id: 'overview', label: 'Overview' },
		{ id: 'tokenomics', label: 'Tokenomics' },
		{ id: 'raised-funds', label: 'Raised Funds' }
	]

	// Add Manager tab only if user is owner
	if (isOwner.value) {
		baseTabs.push({ id: 'manager', label: '⚙️ Manager' })
		console.log('[LaunchpadDetail] ✅ Manager tab added to tabs')
	} else {
		console.log('[LaunchpadDetail] ❌ Manager tab NOT added')
		console.log('[LaunchpadDetail] Wallet connected?', authStore.isConnected)
		console.log('[LaunchpadDetail] If you ARE the owner but tab is not showing:')
		console.log('[LaunchpadDetail]   1. Make sure wallet is connected')
		console.log('[LaunchpadDetail]   2. Try disconnecting and reconnecting wallet')
		console.log('[LaunchpadDetail]   3. Refresh the page after connecting')
	}

	console.log('[LaunchpadDetail] Final tabs:', baseTabs.map(t => t.label).join(', '))
	return baseTabs
})

// Computed Properties
const canisterId = computed(() => route.params.id as string)
const canisterIdShort = computed(() => {
	const id = canisterId.value
	return id ? `${id.slice(0, 5)}...${id.slice(-5)}` : ''
})

// Project Info
const projectName = computed(() => launchpad.value?.config.projectInfo.name || 'Unknown Project')
const projectDescription = computed(() => launchpad.value?.config.projectInfo.description || 'No description available')
const projectLogo = computed(() => projectImages.value.logo || '')  // Use fetched image
const projectCover = computed(() => projectImages.value.cover || '')  // Use fetched image

// Breadcrumb
const breadcrumbItems = computed(() => [
	{ label: 'Launchpads', to: '/launchpad' },
	{ label: `${projectName.value}` }
])
const projectWebsite = computed(() => launchpad.value?.config.projectInfo.website?.[0] || '')
const projectTwitter = computed(() => launchpad.value?.config.projectInfo.twitter?.[0] || '')
const projectTelegram = computed(() => launchpad.value?.config.projectInfo.telegram?.[0] || '')
const projectGithub = computed(() => launchpad.value?.config.projectInfo.github?.[0] || '')
const projectDiscord = computed(() => launchpad.value?.config.projectInfo.discord?.[0] || '')
const isAudited = computed(() => launchpad.value?.config.projectInfo.isAudited || false)
const isKYCed = computed(() => launchpad.value?.config.projectInfo.isKYCed || false)
const kycProvider = computed(() => launchpad.value?.config.projectInfo.kycProvider?.[0] || '')

const hasProjectLinks = computed(() => {
	return projectWebsite.value || projectTwitter.value || projectTelegram.value || projectGithub.value || projectDiscord.value
})

// Category
const categoryDisplay = computed(() => {
	if (!launchpad.value) return ''
	const category = launchpad.value.config.projectInfo.category
	if ('DeFi' in category) return 'DeFi'
	if ('Gaming' in category) return 'Gaming'
	if ('NFT' in category) return 'NFT'
	if ('AI' in category) return 'AI'
	if ('Infrastructure' in category) return 'Infrastructure'
	if ('DAO' in category) return 'DAO'
	if ('SocialFi' in category) return 'SocialFi'
	if ('Metaverse' in category) return 'Metaverse'
	return 'Other'
})

// Sale Token
const saleTokenSymbol = computed(() => launchpad.value?.config.saleToken.symbol || 'TOKEN')
const saleTokenName = computed(() => launchpad.value?.config.saleToken.name || 'Unknown Token')
const saleTokenDecimals = computed(() => Number(launchpad.value?.config.saleToken.decimals || 8))
const totalSupply = computed(() => BigInt(launchpad.value?.config.saleToken.totalSupply || '0'))
const saleTokenStandard = computed(() => launchpad.value?.config.saleToken.standard || 'ICRC1')

// Purchase Token
const purchaseTokenSymbol = computed(() => launchpad.value?.config.purchaseToken.symbol || 'ICP')
const purchaseTokenDecimals = computed(() => Number(launchpad.value?.config.purchaseToken.decimals || 8))

// Sale Params
// Note: Backend returns values WITHOUT e8s format (raw values)
// We need to convert to e8s format (multiply by 10^decimals)
const softCap = computed(() => {
	const raw = BigInt(launchpad.value?.config.saleParams.softCap || '0')
	const decimals = BigInt(purchaseTokenDecimals.value)
	return raw * (BigInt(10) ** decimals)
})

const hardCap = computed(() => {
	const raw = BigInt(launchpad.value?.config.saleParams.hardCap || '0')
	const decimals = BigInt(purchaseTokenDecimals.value)
	return raw * (BigInt(10) ** decimals)
})

const minContribution = computed(() => {
	const raw = BigInt(launchpad.value?.config.saleParams.minContribution || '0')
	const decimals = BigInt(purchaseTokenDecimals.value)
	return raw * (BigInt(10) ** decimals)
})

const maxContribution = computed(() => {
	const val = launchpad.value?.config.saleParams.maxContribution?.[0]
	if (!val) return null
	const raw = BigInt(val)
	const decimals = BigInt(purchaseTokenDecimals.value)
	return raw * (BigInt(10) ** decimals)
})
const maxParticipants = computed(() => {
	const val = launchpad.value?.config.saleParams.maxParticipants?.[0]
	return val ? Number(val) : null
})
const totalSaleAmount = computed(() => Number(launchpad.value?.config.saleParams.totalSaleAmount || 0))

const tokenPrice = computed(() => {
	if (!launchpad.value) return '0'
	const price = Number(launchpad.value.config.saleParams.tokenPrice)
	const decimals = purchaseTokenDecimals.value
	return (price / Math.pow(10, decimals)).toFixed(decimals)
})

const saleTypeDisplay = computed(() => {
	if (!launchpad.value) return 'Unknown'
	const saleType = launchpad.value.config.saleParams.saleType
	if ('IDO' in saleType) return 'IDO'
	if ('PrivateSale' in saleType) return 'Private Sale'
	if ('FairLaunch' in saleType) return 'Fair Launch'
	if ('Auction' in saleType) return 'Auction'
	if ('Lottery' in saleType) return 'Lottery'
	return 'Unknown'
})

const allocationMethodDisplay = computed(() => {
	if (!launchpad.value) return 'Unknown'
	const method = launchpad.value.config.saleParams.allocationMethod
	if ('FirstComeFirstServe' in method) return 'First Come First Serve'
	if ('ProRata' in method) return 'Pro-Rata'
	if ('Lottery' in method) return 'Lottery'
	if ('Weighted' in method) return 'Weighted'
	return 'Unknown'
})

// Stats
const totalRaised = computed(() => BigInt(launchpad.value?.stats.totalRaised || '0'))
const participantCount = computed(() => Number(launchpad.value?.stats.participantCount || 0))
const softCapProgress = computed(() => Number(launchpad.value?.stats.softCapProgress || 0))
const progressPercentage = computed(() => {
	const raised = Number(totalRaised.value)
	const target = Number(hardCap.value)
	return target > 0 ? Math.min((raised / target) * 100, 100) : 0
})

// Status
const isSaleStarted = computed(() => {
	if (!launchpad.value) return false
	const now = Date.now()
	const start = Number(saleStart.value) / 1_000_000 // Convert nanoseconds to milliseconds
	const started = now >= start

	// Debug logging
	console.log('🔍 Sale Start Debug:', {
		now: new Date(now).toLocaleString(),
		saleStart: new Date(start).toLocaleString(),
		saleStartValue: saleStart.value.toString(),
		started,
		status: launchpad.value.status,
		deployedContracts: {
			hasToken: !!deployedContracts.value.tokenCanister,
			hasVesting: deployedContracts.value.vestingContracts.length > 0,
			hasLP: !!deployedContracts.value.liquidityPool
		}
	})

	return started
})

const isSaleActive = computed(() => {
	if (!launchpad.value) return false
	const status = launchpad.value.status
	return 'SaleActive' in status
})

// Check if sale has started based on STATUS (not time)
const isSaleActiveOrBeyond = computed(() => {
	if (!launchpad.value) return false
	const status = launchpad.value.status
	// Sale is considered "started" if status is SaleActive, SaleEnded, Claiming, or Completed
	return 'SaleActive' in status ||
		'SaleEnded' in status ||
		'Claiming' in status ||
		'Completed' in status
})

// Check if sale has ended (for deployment pipeline waiting state)
const isSaleEndedOrBeyond = computed(() => {
	if (!launchpad.value) return false
	const status = launchpad.value.status
	// Sale is considered "ended" if status is SaleEnded, Claiming, or Completed
	return 'SaleEnded' in status ||
		'Claiming' in status ||
		'Completed' in status
})

const saleStartStatus = computed(() => {
	const now = Date.now()
	const start = Number(saleStart.value) / 1_000_000 // Convert nanoseconds to milliseconds

	if (now < start) {
		const diff = start - now
		const days = Math.floor(diff / (1000 * 60 * 60 * 24))
		const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
		const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
		return `Waiting (${days}d ${hours}h ${minutes}m)`
	} else if (isSaleActive.value) {
		return 'In Progress'
	} else {
		return 'Started'
	}
})

const saleEndStatus = computed(() => {
	const now = Date.now()
	const end = Number(saleEnd.value) / 1_000_000 // Convert nanoseconds to milliseconds

	if (now < end && isSaleActive.value) {
		const diff = end - now
		const days = Math.floor(diff / (1000 * 60 * 60 * 24))
		const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
		const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
		return `Waiting (${days}d ${hours}h ${minutes}m)`
	} else if (now >= end) {
		// Check launchpad status to determine if sale was successful or failed
		if (!launchpad.value) return 'Completed'
		const status = launchpad.value.status

		// Sale was successful (softcap reached)
		if ('Successful' in status || 'Claiming' in status || 'Completed' in status) {
			return 'Successful'
		}
		// Sale failed (softcap not reached)
		if ('Refunding' in status || 'Failed' in status) {
			return 'Failed'
		}
		// Default fallback
		return 'Completed'
	} else {
		return 'Waiting'
	}
})

const claimStartStatus = computed(() => {
	if (!claimStart.value) return 'N/A'

	const now = Date.now()
	const claim = Number(claimStart.value) / 1_000_000 // Convert nanoseconds to milliseconds

	if (!launchpad.value) return 'Waiting'
	const status = launchpad.value.status

	// Check if sale failed - no claiming will happen
	if ('Refunding' in status || 'Failed' in status) {
		return 'Cancelled'
	}

	if (now < claim) {
		const diff = claim - now
		const days = Math.floor(diff / (1000 * 60 * 60 * 24))
		const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
		const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))
		return `Waiting (${days}d ${hours}h ${minutes}m)`
	} else if ('Claiming' in status) {
		return 'Active'
	} else if ('Completed' in status) {
		return 'Completed'
	} else {
		return 'Waiting'
	}
})

const listingTimeStatus = computed(() => {
	if (!listingTime.value) return 'N/A'

	if (!launchpad.value) return 'Waiting'
	const status = launchpad.value.status

	// Case 1: Sale Failed - Processing refunds
	if ('Refunding' in status) {
		return 'Refunding'
	}

	// Case 2: Sale Failed - Refunds completed
	if ('Failed' in status) {
		return 'Refunded'
	}

	// Case 3: Sale Successful - Running pipeline (deploy token, vesting, liquidity, etc.)
	if ('Successful' in status) {
		return 'Finalizing Launchpad'
	}

	// Case 4: Pipeline completed - Tokens listed
	if ('Claiming' in status || 'Completed' in status) {
		return 'Completed'
	}

	// Default: Before sale end or during sale
	return 'Waiting'
})

const listingTimeActive = computed(() => {
	if (!launchpad.value) return false
	const status = launchpad.value.status

	// Active when processing refunds or finalizing launchpad
	return 'Refunding' in status || 'Successful' in status
})

const canParticipate = computed(() => isSaleActive.value)

const participateButtonText = computed(() => {
	if (!launchpad.value) return 'Loading...'
	const status = launchpad.value.status
	if ('Upcoming' in status) return 'Coming Soon'
	if ('SaleActive' in status) return 'Deposit & Participate'
	if ('SaleEnded' in status) return 'Sale Ended'
	if ('Claiming' in status) return 'Claim Tokens'
	if ('Completed' in status) return 'Completed'
	return 'View Details'
})

// Timeline
const saleStart = computed(() => BigInt(launchpad.value?.config.timeline.saleStart || '0'))
const saleEnd = computed(() => BigInt(launchpad.value?.config.timeline.saleEnd || '0'))
const claimStart = computed(() => {
	const val = launchpad.value?.config.timeline.claimStart?.[0]
	return val ? BigInt(val) : null
})
const listingTime = computed(() => {
	const val = launchpad.value?.config.timeline.listingTime?.[0]
	return val ? BigInt(val) : null
})

// Deployed Contracts
const deployedContracts = computed(() => {
	const contracts = launchpad.value?.deployedContracts || {
		tokenCanister: null,
		vestingContracts: [],
		liquidityPool: null,
		stakingContract: null,
		daoCanister: null
	}

	return contracts
})

// Token Distribution for Chart
const tokenDistributionItems = computed(() => {
	if (!launchpad.value?.config.distribution) return []

	const colors = ['#b27c10', '#d8a735', '#e1b74c', '#eacf6f', '#f5e590']
	const distribution = launchpad.value.config.distribution || []

	return distribution
		.filter(item => Number(item.totalAmount) > 0) // Filter out zero amounts
		.map((item, index) => ({
			name: item.name,
			value: Number(item.totalAmount),
			percentage: Number(item.percentage),
			color: colors[index % colors.length]
		}))
})

// Raised Funds for Chart
const raisedFundsItems = computed(() => {
	if (!launchpad.value?.config.raisedFundsAllocation) return []

	const colors = ['#b27c10', '#d8a735', '#e1b74c']
	const allocations = launchpad.value.config.raisedFundsAllocation.allocations || []

	return allocations
		.filter(alloc => Number(alloc.percentage) > 0) // Filter out zero percentage
		.map((alloc, index) => {
			// Calculate actual amount based on current raised funds
			const actualAmount = (totalRaised.value * BigInt(Math.floor(Number(alloc.percentage) * 100))) / BigInt(10000)

			return {
				name: alloc.name,
				value: Number(actualAmount), // Use actual raised amount instead of planned
				percentage: Number(alloc.percentage),
				color: colors[index % colors.length]
			}
		})
})

// Raised Funds Recipients
const raisedFundsRecipients = computed(() => {
	if (!launchpad.value?.config.raisedFundsAllocation) return []

	const recipients: any[] = []
	const allocations = launchpad.value.config.raisedFundsAllocation.allocations || []

	allocations
		.filter(alloc => Number(alloc.amount) > 0) // Only process allocations with amount > 0
		.forEach(alloc => {
			alloc.recipients.forEach(recipient => {
				recipients.push({
					category: alloc.name,
					name: recipient.name?.[0] || '',
					percentage: Number(recipient.percentage),
					vestingSchedule: recipient.vestingSchedule?.[0] ? {
						immediateRelease: Number(recipient.vestingSchedule[0].immediateRelease),
						cliffDays: Number(recipient.vestingSchedule[0].cliffDays),
						durationDays: Number(recipient.vestingSchedule[0].durationDays),
						releaseFrequency: getReleaseFrequency(recipient.vestingSchedule[0].releaseFrequency)
					} : null
				})
			})
		})

	return recipients
})

// Vesting Schedules
const vestingSchedules = computed(() => {
	if (!launchpad.value?.config.tokenDistribution) return []

	const schedules: any[] = []
	const dist = launchpad.value.config.tokenDistribution[0]

	if (dist) {
		if (dist.sale?.vestingSchedule?.[0]) {
			const schedule = dist.sale.vestingSchedule[0]
			schedules.push({
				name: dist.sale.name,
				description: dist.sale.description?.[0] || '',
				immediateRelease: Number(schedule.immediateRelease),
				cliffDays: Number(schedule.cliffDays),
				durationDays: Number(schedule.durationDays),
				releaseFrequency: getReleaseFrequency(schedule.releaseFrequency),
				badge: 'Sale'
			})
		}

		if (dist.team?.vestingSchedule?.[0]) {
			const schedule = dist.team.vestingSchedule[0]
			schedules.push({
				name: dist.team.name,
				description: dist.team.description?.[0] || '',
				immediateRelease: Number(schedule.immediateRelease),
				cliffDays: Number(schedule.cliffDays),
				durationDays: Number(schedule.durationDays),
				releaseFrequency: getReleaseFrequency(schedule.releaseFrequency),
				badge: 'Team'
			})
		}
	}

	return schedules
})

// Multi-DEX Platforms
const dexPlatforms = computed(() => {
	if (!launchpad.value?.config.multiDexConfig?.[0]) return []

	return launchpad.value.config.multiDexConfig[0].platforms.map(platform => {
		// Calculate actual LP for this platform based on current raised funds
		const actualPlatformLP = (actualLPAmount.value * BigInt(Math.floor(platform.allocationPercentage * 100))) / BigInt(10000)

		return {
			id: platform.id,
			name: platform.name,
			description: platform.description?.[0] || '',
			enabled: platform.enabled,
			allocationPercentage: platform.allocationPercentage,
			calculatedTokenLiquidity: platform.calculatedTokenLiquidity,
			calculatedPurchaseLiquidity: actualPlatformLP.toString() // Use actual LP instead of planned
		}
	})
})

const icpswapAllocation = computed(() => {
	const platform = dexPlatforms.value.find(p => p.id === 'icpswap')
	return platform?.allocationPercentage || 0
})

const kongswapAllocation = computed(() => {
	const platform = dexPlatforms.value.find(p => p.id === 'kongswap')
	return platform?.allocationPercentage || 0
})

const distributionStrategy = computed(() => {
	if (!launchpad.value?.config.multiDexConfig?.[0]) return 'Not configured'

	const strategy = launchpad.value.config.multiDexConfig[0].distributionStrategy
	if ('Weighted' in strategy) return 'Weighted distribution based on allocation percentages'
	if ('Equal' in strategy) return 'Equal distribution across all platforms'
	return 'Custom distribution strategy'
})

// Calculate DEX allocation percentage from config
const totalDexAllocationPercent = computed(() => {
	if (!launchpad.value?.config.raisedFundsAllocation) return 0

	const allocations = launchpad.value.config.raisedFundsAllocation.allocations || []
	const dexAllocation = allocations.find(alloc =>
		alloc.name.toLowerCase().includes('liquidity') ||
		alloc.name.toLowerCase().includes('dex')
	)

	return dexAllocation ? Number(dexAllocation.percentage) : 0
})

// Calculate actual LP amount from current raised funds
const actualLPAmount = computed(() => {
	if (!totalRaised.value || totalDexAllocationPercent.value === 0) return BigInt(0)

	// Calculate actual LP amount: totalRaised * (dexAllocationPercent / 100)
	const raised = totalRaised.value
	const percent = BigInt(Math.floor(totalDexAllocationPercent.value * 100)) // Multiply by 100 to avoid decimals

	return (raised * percent) / BigInt(10000) // Divide by 10000 to get the correct percentage
})

const estimatedListingTime = computed(() => {
	if (!listingTime.value) return 'TBA'

	const listing = Number(listingTime.value) / 1_000_000 // Convert to milliseconds
	const now = Date.now()

	if (now >= listing) {
		return 'Listed'
	}

	const diff = listing - now
	const days = Math.floor(diff / (1000 * 60 * 60 * 24))
	const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))

	if (days > 0) {
		return `~${days}d ${hours}h`
	} else if (hours > 0) {
		return `~${hours}h`
	} else {
		return 'Soon'
	}
})


// Manager tab computed properties
const isSalePaused = computed(() => {
	// Check if launchpad has a paused status
	return launchpad.value?.status && 'Paused' in launchpad.value.status
})

const canPauseResume = computed(() => {
	return isOwner.value && isSaleActive.value
})

const canEmergencyStop = computed(() => {
	return isOwner.value && (isSaleActive.value || isSalePaused.value)
})

const canUpdateSettings = computed(() => {
	return isOwner.value && !isSaleActive.value
})

const canDeployToken = computed(() => {
	return isOwner.value && isSaleEndedOrBeyond.value && !deployedContracts.value.tokenCanister
})


// Manager tab methods
const handlePauseResume = async () => {
	if (!canPauseResume.value) return

	try {
		loading.value = true
		if (isSalePaused.value) {
			// Resume sale logic
			toast.success('Sale resumed successfully')
		} else {
			// Pause sale logic
			toast.success('Sale paused successfully')
		}
		await fetchData() // Refresh data
	} catch (error) {
		console.error('Error toggling sale pause:', error)
		toast.error('Failed to toggle sale pause')
	} finally {
		loading.value = false
	}
}

const handleEmergencyStop = async () => {
	if (!canEmergencyStop.value) return

	try {
		const result = await useSwal.fire({
			title: 'Emergency Stop',
			text: 'Are you sure you want to emergency stop the sale? This action cannot be undone.',
			icon: 'warning',
			showCancelButton: true,
			confirmButtonColor: '#d33',
			confirmButtonText: 'Emergency Stop',
			cancelButtonText: 'Cancel'
		})

		if (result.isConfirmed) {
			loading.value = true
			// Emergency stop logic
			toast.success('Sale emergency stopped')
			await fetchData() // Refresh data
		}
	} catch (error) {
		console.error('Error emergency stopping sale:', error)
		toast.error('Failed to emergency stop sale')
	} finally {
		loading.value = false
	}
}

const handleUpdateSettings = async () => {
	if (!canUpdateSettings.value) return

	try {
		loading.value = true
		// Update settings logic
		toast.success('Settings updated successfully')
		await fetchData() // Refresh data
	} catch (error) {
		console.error('Error updating settings:', error)
		toast.error('Failed to update settings')
	} finally {
		loading.value = false
	}
}

const handleDeployToken = async () => {
	if (!canDeployToken.value) return

	try {
		loading.value = true
		// Deploy token logic
		toast.success('Token deployed successfully')
		await fetchData() // Refresh data
	} catch (error) {
		console.error('Error deploying token:', error)
		toast.error('Failed to deploy token')
	} finally {
		loading.value = false
	}
}


// Version Management Methods
const handleVersionUpgraded = async () => {
	// Reload launchpad data after successful upgrade
	toast.success('Contract upgraded successfully!')
	await fetchData()
}


const resetEditForm = () => {
	if (!launchpad.value) return

	editForm.value = {
		description: launchpad.value.config.projectInfo.description || '',
		website: launchpad.value.config.projectInfo.website?.[0] || '',
		twitter: launchpad.value.config.projectInfo.twitter?.[0] || '',
		telegram: launchpad.value.config.projectInfo.telegram?.[0] || '',
		discord: launchpad.value.config.projectInfo.discord?.[0] || '',
		github: launchpad.value.config.projectInfo.github?.[0] || '',
		medium: launchpad.value.config.projectInfo.medium?.[0] || '',
		reddit: launchpad.value.config.projectInfo.reddit?.[0] || '',
		youtube: launchpad.value.config.projectInfo.youtube?.[0] || '',
		logo: projectImages.value.logo || '',
		cover: projectImages.value.cover || ''
	}
}

const saveProjectInfo = async () => {
	try {
		isSaving.value = true
		// TODO: Implement save project info via backend
		toast.info('Save project info feature coming soon!')

		await new Promise(resolve => setTimeout(resolve, 1000))
		toast.success('Project information updated successfully!')
	} catch (error) {
		console.error('Error saving project info:', error)
		toast.error('Failed to save project information')
	} finally {
		isSaving.value = false
	}
}

const saveProjectImages = async () => {
	try {
		isSavingImages.value = true
		// TODO: Implement save project images via backend
		toast.info('Save project images feature coming soon!')

		await new Promise(resolve => setTimeout(resolve, 1000))
		toast.success('Project images updated successfully!')
	} catch (error) {
		console.error('Error saving project images:', error)
		toast.error('Failed to save project images')
	} finally {
		isSavingImages.value = false
	}
}

// Calculate percentage of raised funds for each DEX
const calculateDexPercentage = (lpValue: any): string => {
	if (!actualLPAmount.value || actualLPAmount.value === BigInt(0)) return '0.0'

	const lpBigInt = BigInt(lpValue)
	const total = actualLPAmount.value

	// Calculate percentage: (lpValue / total) * 100
	const percentage = (Number(lpBigInt) / Number(total)) * 100

	return percentage.toFixed(1)
}





// Methods
const fetchData = async () => {
	loading.value = true
	error.value = null

	try {
		const data = await launchpadService.getLaunchpad(canisterId.value)

		if (!data) {
			error.value = 'Launchpad not found'
			return
		}

		launchpad.value = data

		// Initialize edit form with current data
		editForm.value = {
			description: data.config.projectInfo.description || '',
			website: data.config.projectInfo.website?.[0] || '',
			twitter: data.config.projectInfo.twitter?.[0] || '',
			telegram: data.config.projectInfo.telegram?.[0] || '',
			discord: data.config.projectInfo.discord?.[0] || '',
			github: data.config.projectInfo.github?.[0] || '',
			medium: data.config.projectInfo.medium?.[0] || '',
			reddit: data.config.projectInfo.reddit?.[0] || '',
			youtube: data.config.projectInfo.youtube?.[0] || '',
			logo: projectImages.value.logo || '',
			cover: projectImages.value.cover || ''
		}

		// Fetch contract version and project images
		try {
			const launchpadActor = launchpadContractActor({
				canisterId: canisterId.value,
				requiresSigning: false,
				anon: false
			})

			// Fetch version
			const version = await launchpadActor.getVersion()
			// Convert version object to string format
			if (typeof version === 'string') {
				contractVersion.value = version
			} else if (version && typeof version === 'object') {
				// Handle version object like { major: 1, minor: 0, patch: 0 }
				contractVersion.value = `${(version as any).major || 0}.${(version as any).minor || 0}.${(version as any).patch || 0}`
			}
			console.log('📦 Contract version:', contractVersion.value)

			// Fetch project images (logo and cover)
			const images = await launchpadActor.getProjectImages()
			projectImages.value = {
				logo: images.logo?.[0] || '',
				cover: images.cover?.[0] || ''
			}
			console.log('🖼️ Project images:', projectImages.value)
		} catch (versionError) {
			console.warn('⚠️ Could not fetch contract version or images:', versionError)
		}

		// After conversion to e8s format
		setTimeout(() => {
			console.log('💰 Converted Values (with e8s):', {
				softCap: softCap.value.toString(),
				hardCap: hardCap.value.toString(),
				minContribution: minContribution.value.toString(),
				maxContribution: maxContribution.value?.toString() || 'null'
			})
		}, 100)

		// Initialize edit form with current values
		if (isOwner.value) {
			resetEditForm()
		}
	} catch (err) {
		console.error('Error fetching launchpad:', err)
		error.value = err instanceof Error ? err.message : 'Failed to load launchpad'
	} finally {
		loading.value = false
	}
}

const formatAmount = (amount: bigint, decimals: number): string => {
	try {
		// Handle BigInt safely without losing precision
		const divisor = BigInt(10) ** BigInt(decimals)
		const integerPart = amount / divisor
		const remainder = amount % divisor

		// Convert remainder to decimal string
		const remainderStr = remainder.toString().padStart(decimals, '0')

		// Get full decimal representation
		const fullDecimal = `${integerPart.toString()}.${remainderStr}`
		const value = parseFloat(fullDecimal)

		return value.toLocaleString('en-US', {
			minimumFractionDigits: 2,
			maximumFractionDigits: 2
		})
	} catch (error) {
		console.error('Error formatting amount:', error, amount, decimals)
		return '0.00'
	}
}

const formatTokenAmount = (amount: number): string => {
	return amount.toLocaleString('en-US', {
		minimumFractionDigits: 0,
		maximumFractionDigits: 0
	})
}

const formatTimestamp = (timestamp: bigint | null): string => {
	if (!timestamp) return 'TBA'
	return launchpadService.formatDateTime(timestamp)
}

const getReleaseFrequency = (frequency: any): string => {
	if ('Linear' in frequency) return 'Linear'
	if ('Monthly' in frequency) return 'Monthly'
	if ('Quarterly' in frequency) return 'Quarterly'
	if ('Yearly' in frequency) return 'Yearly'
	return 'Custom'
}


// ICTO Passport Score
const minPassportScore = computed(() => {
	return Number(launchpad.value?.config.saleParams.minICTOPassportScore || 0)
})

// Placeholder for user's passport score - will be fetched from backend
const userPassportScore = ref(0)
// Contract version
const contractVersion = ref('')
// User participation data
const userDeposited = ref(BigInt(0)) // Recorded contribution from contract
const refreshingStats = ref(false)

const handleDeposit = () => {
	if (!canParticipate.value) return

	// Check passport score requirement
	if (minPassportScore.value > 0 && userPassportScore.value < minPassportScore.value) {
		toast.error('ICTO Passport Score requirement not met', {
			description: `You need a score of at least ${minPassportScore.value} to participate`
		})
		return
	}

	modalStore.open('launchpadDeposit', {
		launchpad: launchpad.value,
		canisterId: canisterId.value,
		purchaseToken: launchpad.value?.config.purchaseToken,
		minContribution: minContribution.value,
		maxContribution: maxContribution.value
	})
}

// Fetch user's passport score
const fetchUserPassportScore = async () => {
	try {
		const score = await launchpadService.getUserPassportScore()
		userPassportScore.value = score
	} catch (error) {
		console.error('Error fetching passport score:', error)
		// Keep default value of 0
	}
}

// Fetch user's participation data
const fetchUserParticipation = async () => {
	if (!authStore.principal || !canisterId.value) {
		userDeposited.value = BigInt(0)
		return
	}

	try {
		const { Principal } = await import('@dfinity/principal')

		const launchpadActor = launchpadContractActor({
			canisterId: canisterId.value,
			requiresSigning: false,
			anon: false
		})

		// Get participant info from contract
		const participant = await launchpadActor.getParticipant(Principal.fromText(authStore.principal))

		if (participant && participant[0]) {
			const participantData = participant[0]
			// Parse totalContribution to BigInt
			userDeposited.value = BigInt(Number(participantData.totalContribution || 0))
			console.log('✅ User deposited:', userDeposited.value.toString())
		} else {
			userDeposited.value = BigInt(0)
		}
	} catch (error) {
		console.error('Error fetching user participation:', error)
		userDeposited.value = BigInt(0)
	}
}

// Refresh all stats and user data
const refreshStats = async () => {
	refreshingStats.value = true
	try {
		// Reload main data
		await fetchData()
		// Reload user-specific data
		if (authStore.isConnected) {
			await Promise.all([
				fetchUserPassportScore(),
				fetchUserParticipation()
			])
		}
		toast.success('Stats refreshed successfully!')
	} catch (error) {
		console.error('Error refreshing stats:', error)
		toast.error('Failed to refresh stats')
	} finally {
		refreshingStats.value = false
	}
}

// Watch for tab changes to auto-load version info
watch(activeTab, async (newTab) => {
	if (newTab === 'manager' && isOwner.value && canisterId.value && versionManagementRef.value) {
		// Auto-load version info when switching to Manager tab
		await versionManagementRef.value.loadVersionInfo()
	}
})

// Lifecycle
onMounted(() => {
	fetchData()
	if (authStore.isConnected) {
		fetchUserPassportScore()
		fetchUserParticipation()
	}
})
</script>

<style scoped>
@keyframes shimmer {
	0% {
		transform: translateX(-100%);
	}

	100% {
		transform: translateX(100%);
	}
}

.animate-shimmer {
	animation: shimmer 2s infinite;
}
</style>
