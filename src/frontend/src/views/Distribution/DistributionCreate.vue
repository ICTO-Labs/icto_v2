<template>
	<AdminLayout>
	<div class="max-w-8xl mx-auto">
		<!-- Header -->
		<div class="mb-8">
			<div class="flex items-center justify-between">
				<div>
					<h1 class="text-2xl font-bold text-gray-900 dark:text-white">Create Distribution Campaign</h1>
					<p class="mt-1 text-sm text-gray-600 dark:text-gray-400">
						Set up a new token distribution with advanced vesting and eligibility features
					</p>
				</div>
				<button @click="$router.back()" class="btn-secondary flex items-center">
					<ArrowLeftIcon class="h-4 w-4 mr-2" />
					Back
				</button>
			</div>
		</div>

		<!-- Progress Steps -->
		<div class="mb-8">
			<nav aria-label="Progress">
                <ol class="flex items-center justify-between w-full">
                    <li v-for="(step, index) in steps" :key="step.id"
                        class="step-item relative flex-1 flex flex-col items-center"
                        :class="{ 'completed': index < currentStep }">
                        <div class="relative flex flex-col items-center">
                            <template v-if="index < currentStep">
                                <div class="relative flex h-8 w-8 items-center justify-center rounded-full bg-blue-600 z-10">
                                    <svg class="h-5 w-5 text-white" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                                    </svg>
                                </div>
                            </template>
                            <template v-else-if="index === currentStep">
                                <div class="relative flex h-8 w-8 items-center justify-center rounded-full border-2 border-blue-600 bg-white z-10">
                                    <span class="text-blue-600 font-medium text-sm">{{ index + 1 }}</span>
                                </div>
                            </template>
                            <template v-else>
                                <div class="relative flex h-8 w-8 items-center justify-center rounded-full border-2 border-gray-300 bg-white z-10">
                                    <span class="text-gray-500 font-medium text-sm">{{ index + 1 }}</span>
                                </div>
                            </template>
                            
                            <span class="mt-2 text-sm font-medium text-center whitespace-nowrap"
                                :class="index <= currentStep ? 'text-blue-600' : 'text-gray-500'">
                                {{ step.name }}
                            </span>
                        </div>
                    </li>
                </ol>
            </nav>
		</div>

		<!-- Form Content -->
		<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700">
			<form @submit.prevent="handleSubmit" class="p-6">
				<!-- Step 1: Basic Information -->
				<div v-if="currentStep === 0" class="space-y-8">
					<div>
						<h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Basic Information</h3>
						<div class="flex flex-col gap-6">
							<!-- Campaign Type -->
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-4">
									Campaign Type *
								</label>
								<div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
									<label v-for="type in campaignTypes" :key="type.value"
										class="flex items-center gap-4 p-4 rounded-lg border transition cursor-pointer shadow-sm"
										:class="formData.campaignType === type.value
											? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
											: 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400'">
										<input v-model="formData.campaignType" :value="type.value" type="radio"
											class="sr-only" />
										<div class="flex items-center justify-center h-10 w-10 rounded-full" :class="formData.campaignType === type.value
											? 'bg-blue-600'
											: 'bg-blue-50 dark:bg-blue-900/20'">
											<component :is="type.icon" class="h-6 w-6" :class="formData.campaignType === type.value
												? 'text-white'
												: 'text-blue-600'" />
										</div>
										<div class="flex-1 min-w-0">
											<div class="text-base font-medium text-gray-900 dark:text-blue-500">{{
												type.label }}
											</div>
											<div class="text-sm text-gray-500">{{ type.description }}</div>
										</div>
										<div v-if="formData.campaignType === type.value" class="ml-2">
											<CheckIcon class="h-5 w-5 text-blue-600" />
										</div>
									</label>
								</div>
							</div>

							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
									Campaign Title *
								</label>
								<input v-model="formData.title" type="text" required
									placeholder="e.g., Community Airdrop Q4 2024"
									class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
								<p class="mt-2 text-xs text-gray-500">A descriptive name for your distribution campaign
								</p>
							</div>
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
									Description *
								</label>
								<textarea v-model="formData.description" rows="4" required
									placeholder="Describe the purpose and details of this distribution..."
									class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"></textarea>
								<p class="mt-2 text-xs text-gray-500">Explain the purpose and benefits of this
									distribution</p>
							</div>

							<!-- Token & Amount Configuration -->
							<div class="bg-gradient-to-r from-blue-50/30 to-indigo-50/30 dark:from-blue-900/10 dark:to-indigo-900/10 rounded-xl p-5 border border-blue-200/50 dark:border-blue-700/50">
								<h4 class="text-lg font-semibold text-gray-900 dark:text-white mb-5 flex items-center gap-2">
									<CoinsIcon class="w-5 h-5 text-blue-600 dark:text-blue-400" />
									Token Selection
								</h4>
								
								<!-- Compact Token Selection -->
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
									<!-- Token Selection Method -->
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Selection Method
										</label>
										<div class="flex gap-2">
											<label class="flex items-center gap-2 cursor-pointer px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 flex-1 text-center">
												<input v-model="tokenSelectionMethod" value="assets" type="radio"
													class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" />
												<span class="text-sm text-gray-700 dark:text-gray-300">From Assets</span>
											</label>
											<label class="flex items-center gap-2 cursor-pointer px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400 flex-1 text-center">
												<input v-model="tokenSelectionMethod" value="custom" type="radio"
													class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" />
												<span class="text-sm text-gray-700 dark:text-gray-300">Custom ID</span>
											</label>
										</div>
									</div>

									<!-- Token Input -->
									<div>
										<!-- Assets Selection -->
										<div v-if="tokenSelectionMethod === 'assets'">
											<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Select Token *
											</label>
											<select v-model="selectedAssetId" required
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
												@change="onAssetSelected">
												<option value="">Choose token</option>
												<option v-for="asset in availableAssets" :key="asset.canisterId"
													:value="asset.canisterId">
													{{ asset.symbol }} - {{ asset.name }}
												</option>
											</select>
										</div>

										<!-- Custom Canister ID -->
										<div v-if="tokenSelectionMethod === 'custom'">
											<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Canister ID *
											</label>
											<input v-model="formData.tokenInfo.canisterId" type="text" required
												placeholder="rdmx6-jaaaa-aaaah-qcaiq-cai"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
												@blur="fetchTokenInfo" />
										</div>
									</div>
								</div>

								<!-- Token Info Display - Compact Version -->
								<div v-if="formData.tokenInfo.canisterId"
									class="bg-gradient-to-r from-amber-50/30 to-orange-50/30 dark:from-amber-900/10 dark:to-orange-900/10 rounded-lg p-4 border border-amber-200/50 dark:border-amber-700/50">
									<div class="flex items-center justify-between">
										<!-- Left: Token Info -->
										<div class="flex items-center gap-3 flex-1">
											<TokenLogo 
												:canister-id="formData.tokenInfo.canisterId" 
												:symbol="formData.tokenInfo.symbol || 'T'"
												:size="40"
												class="flex-shrink-0"
											/>
											<div class="flex-1 min-w-0">
												<h6 class="text-base font-semibold text-gray-900 dark:text-white truncate">
													{{ formData.tokenInfo.name || 'Loading...' }}
												</h6>
												<div class="flex items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
													<span>{{ formData.tokenInfo.symbol || 'Loading...' }}</span>
													<span>•</span>
													<span>{{ formData.tokenInfo.decimals || 8 }} decimals</span>
												</div>
											</div>
										</div>
										
										<!-- Right: Balance -->
										<div class="text-right ml-4">
											<div class="text-xs text-amber-700 dark:text-amber-300 font-medium">
												Your Balance
											</div>
											<div v-if="authStore.isConnected" class="flex items-center gap-2">
												<div class="text-lg font-bold text-gray-900 dark:text-white">
													{{ userTokenBalance !== null ? formatTokenBalance(userTokenBalance) : 'Loading...' }}
												</div>
												<button 
													@click="refreshUserBalance"
													:disabled="isLoadingBalance"
													class="p-1 text-amber-600 dark:text-amber-400 hover:text-amber-700 dark:hover:text-amber-300 transition-colors duration-200 disabled:opacity-50"
													title="Refresh Balance"
												>
													<RefreshCwIcon 
														class="w-4 h-4" 
														:class="{ 'animate-spin': isLoadingBalance }"
													/>
												</button>
											</div>
											<div v-else class="text-sm text-gray-500 dark:text-gray-400">
												Connect wallet
											</div>
										</div>
									</div>
								</div>

							</div>
							
							<!-- BlockID Optional Configuration -->
							<div>
								<label class="flex items-center gap-3 cursor-pointer">
									<input v-model="formData.useBlockId" type="checkbox"
										class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" />
									<span class="text-sm font-medium text-gray-700 dark:text-gray-300">
										Enable Block ID Score Requirements
									</span>
								</label>
								<p class="mt-1 text-xs text-gray-500">Add Block ID score verification to eligibility criteria</p>
								
								<!-- Block ID Score Input (conditional) -->
								<div v-if="formData.useBlockId" class="mt-4">
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Minimum Block ID Score *
									</label>
									<input v-model.number="formData.blockIdScore" type="number" required min="0"
										placeholder="50"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									<p class="mt-2 text-xs text-gray-500">Minimum Block ID score required for
										eligibility</p>
								</div>
							</div>

							<!-- Public Distribution Toggle -->
							<div>
								<label class="flex items-center gap-3">
									<input
										v-model="formData.isPublic"
										type="checkbox"
										class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
									/>
									<div>
										<span class="text-sm font-medium text-gray-700 dark:text-gray-300">
											Public Distribution
										</span>
										<p class="text-xs text-gray-500">
											Make this distribution visible in the public ICTO marketplace
										</p>
									</div>
								</label>
								<div class="mt-2 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
									<p class="text-sm text-blue-700 dark:text-blue-300">
										{{ formData.isPublic 
											? '📢 This distribution will be discoverable by all users and appear in public listings.' 
											: '🔒 This distribution will be private and only accessible via direct link or by eligible participants.' 
										}}
									</p>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Step 2: Eligibility -->
				<div v-if="currentStep === 1" class="space-y-8">
					<div>
						<h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Eligibility Configuration</h3>
						<div class="flex flex-col gap-6">
							<!-- Eligibility Type -->
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-4">
									Eligibility Type *
								</label>
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
									<label v-for="type in eligibilityTypes" :key="keyToText(type.value)"
										class="flex items-center gap-4 p-4 rounded-lg border transition cursor-pointer shadow-sm"
										:class="keyToText(formData.eligibilityType) == keyToText(type.value)
											? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
											: 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400'">
										<input v-model="formData.eligibilityType" :value="type.value" type="radio" class="sr-only" />
										<div class="flex items-center justify-center h-10 w-10 rounded-full" :class="keyToText(formData.eligibilityType) == keyToText(type.value)
											? 'bg-blue-600'
											: 'bg-blue-50 dark:bg-blue-900/20'">
											<component :is="type.icon" class="h-6 w-6" :class="keyToText(formData.eligibilityType) == keyToText(type.value)
												? 'text-white'
												: 'text-blue-600'" />
										</div>
										<div class="flex-1 min-w-0">
											<div class="text-base font-medium text-gray-900 dark:text-blue-500">{{
												type.label }}
											</div>
											<div class="text-sm text-gray-500">{{ type.description }}</div>
										</div>
										<div v-if="formData.eligibilityType && keyToText(formData.eligibilityType) == keyToText(type.value)" class="ml-2">
											<CheckIcon class="h-5 w-5 text-blue-600" />
										</div>
									</label>
								</div>
							</div>

							<!-- Whitelist Configuration -->
							<div v-if="formData.eligibilityType && keyToText(formData.eligibilityType) === 'Whitelist'" class="space-y-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-3">
										Whitelist Amount Type
									</label>
									<div class="flex gap-4">
										<label class="flex items-center gap-3">
											<input v-model="whitelistAmountType" value="same" type="radio"
												class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" />
											<span class="text-sm text-gray-700 dark:text-gray-300">Same amount for
												all</span>
										</label>
										<label class="flex items-center gap-3">
											<input v-model="whitelistAmountType" value="custom" type="radio"
												class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" />
											<span class="text-sm text-gray-700 dark:text-gray-300">Custom amounts</span>
										</label>
									</div>
								</div>

								<div v-if="whitelistAmountType === 'same'">
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Amount per Recipient
									</label>
									<input v-model.number="whitelistSameAmount" type="number" min="1" placeholder="1000"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									<p class="mt-2 text-xs text-gray-500">Amount each whitelisted recipient will receive
									</p>
								</div>

								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Whitelist Addresses
									</label>
									<textarea v-model="whitelistText" rows="6"
										:placeholder="whitelistAmountType === 'same'
											? 'Enter principal addresses, one per line\ne.g.:\nbe2us-64aaa-aaaah-qaabq-cai\nrdmx6-jaaaa-aaaah-qcaiq-cai'
											: 'Enter principal addresses with amounts, one per line\nFormat: Principal,Amount,Note (optional)\ne.g.:\nbe2us-64aaa-aaaah-qaabq-cai,1000,Early supporter\nrdmx6-jaaaa-aaaah-qcaiq-cai,2000,Community member'"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"></textarea>
									<p class="mt-2 text-xs text-gray-500">
										{{ whitelistAmountType === 'same'
											? 'Enter principal addresses, one per line'
											: 'Format: Principal,Amount,Note (one per line). Note is optional.' }}
									</p>
									
									<!-- Total Distribution Amount Display -->
									<div v-if="whitelistTotalAmount > 0" class="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
										<div class="flex items-center justify-between">
											<span class="text-sm font-medium text-blue-900 dark:text-blue-100">
												Total Distribution Amount:
											</span>
											<span class="text-lg font-bold text-blue-900 dark:text-blue-100">
												{{ whitelistTotalAmount.toLocaleString() }} tokens
											</span>
										</div>
										<p class="text-xs text-blue-700 dark:text-blue-300 mt-1">
											This will be shown on the next step and used for token amount verification
										</p>
									</div>
								</div>
							</div>

							<!-- Token Holder Configuration -->
							<div v-if="formData.eligibilityType && keyToText(formData.eligibilityType) === 'TokenHolder'" class="space-y-4">
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Token Canister ID *
										</label>
										<input v-model="formData.tokenHolderConfig.canisterId" type="text" required
											placeholder="rdmx6-jaaaa-aaaah-qcaiq-cai"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
										<p class="mt-2 text-xs text-gray-500">Canister ID of the required token</p>
									</div>
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Minimum Token Amount *
										</label>
										<input v-model.number="formData.tokenHolderConfig.minAmount" type="number"
											required min="1" placeholder="100000000"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
										<p class="mt-2 text-xs text-gray-500">Minimum token balance required (in
											smallest unit)
										</p>
									</div>
								</div>
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Snapshot Time (Optional)
									</label>
									<input v-model="tokenHolderSnapshotDate" type="datetime-local"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									<p class="mt-2 text-xs text-gray-500">Specific time to check token balances (leave
										empty for
										current balance)</p>
								</div>
							</div>

							<!-- NFT Holder Configuration -->
							<div v-if="formData.eligibilityType && keyToText(formData.eligibilityType) === 'NFTHolder'" class="space-y-4">
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											NFT Canister ID *
										</label>
										<input v-model="formData.nftHolderConfig.canisterId" type="text" required
											placeholder="abc123-jaaaa-aaaah-qcaiq-cai"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
										<p class="mt-2 text-xs text-gray-500">Canister ID of the required NFT collection
										</p>
									</div>
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Minimum NFT Count *
										</label>
										<input v-model.number="formData.nftHolderConfig.minCount" type="number" required
											min="1" placeholder="1"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
										<p class="mt-2 text-xs text-gray-500">Minimum number of NFTs required</p>
									</div>
								</div>
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Specific Collections (Optional)
									</label>
									<textarea v-model="nftCollectionsText" rows="3"
										placeholder="Enter collection names, one per line (leave empty for any collection)"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm"></textarea>
									<p class="mt-2 text-xs text-gray-500">Specific NFT collections to require (optional)
									</p>
								</div>
							</div>

							</div>


							</div>


							<!-- Open Distribution Configuration OR Max Recipients -->
							<div v-if="formData.eligibilityType && keyToText(formData.eligibilityType) !== 'Whitelist'">
								<!-- Open Distribution Configuration (for Open to all, Token holders, NFT holders) -->
								<div class="bg-gradient-to-r from-amber-50/30 to-orange-50/30 dark:from-amber-900/10 dark:to-orange-900/10 rounded-xl p-6 border border-amber-200/50 dark:border-amber-700/50">
									<!-- Header with Self-Service Toggle -->
									<div class="flex items-center justify-between mb-6">
										<div class="flex items-center gap-2">
											<SlidersIcon class="w-5 h-5 text-amber-600 dark:text-amber-400" />
											<h4 class="text-lg font-semibold text-gray-900 dark:text-white">
												Distribution Configuration
											</h4>
										</div>
										<!-- Self-Service Mode Toggle -->
										<div class="flex items-center gap-3">
											<label class="text-sm font-medium text-gray-700 dark:text-gray-300">Mode:</label>
											<div class="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
												<input 
													v-model="formData.recipientMode" 
													:value="{ SelfService: null }" 
													type="radio"
													class="h-4 w-4 text-blue-600 border-gray-300 focus:ring-blue-500" 
												/>
												<span class="text-sm font-medium text-gray-900 dark:text-white">Self-Service</span>
												<span class="text-xs text-gray-500">Users register themselves</span>
											</div>
										</div>
									</div>
									
									<!-- Security Warning -->
									<div v-if="keyToText(formData.eligibilityType) === 'Open'" class="bg-amber-50/60 dark:bg-amber-900/15 border border-amber-200/60 dark:border-amber-700/60 rounded-lg p-4 mb-6">
										<div class="flex items-start gap-3">
											<AlertTriangleIcon class="w-5 h-5 text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
											<div>
												<h6 class="text-sm font-medium text-amber-800 dark:text-amber-200 mb-1">
													Security Recommendation
												</h6>
												<p class="text-sm text-amber-700 dark:text-amber-300">
													We recommend enabling BlockID and set a minimum score to prevent malicious users/bots from claiming tokens at settings section.
												</p>
											</div>
										</div>
									</div>

									<!-- Compact Configuration Fields - All in One Line -->
									<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
										<!-- Total Distribution Amount -->
										<div>
											<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Total Amount *
											</label>
											<div v-if="whitelistTotalAmount > 0" class="mb-2">
												<span class="text-xs text-blue-600 dark:text-blue-400">
													From whitelist: {{ whitelistTotalAmount.toLocaleString() }}
												</span>
											</div>
											<input v-model.number="formData.totalAmount" type="number" required min="1" 
												placeholder="1000000"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm" 
												:disabled="whitelistTotalAmount > 0" />
											<p class="mt-1 text-xs text-gray-500">Total tokens to distribute</p>
										</div>

										<!-- Total Recipients -->
										<div>
											<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Recipients *
											</label>
											<input v-model.number="openDistributionConfig.totalRecipients" type="number" required min="1" 
												placeholder="1000"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
												@input="calculateOpenDistribution" />
											<p class="mt-1 text-xs text-gray-500">Max number of participants</p>
										</div>

										<!-- Tokens per Recipient -->
										<div>
											<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Per Recipient
											</label>
											<div class="block w-full rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 px-3 py-2 text-gray-900 dark:text-white text-sm font-medium">
												{{ formattedTokensPerRecipient }} {{ formData.tokenInfo.symbol || 'TOKEN' }}
											</div>
											<p class="mt-1 text-xs text-gray-500">Auto-calculated (supports decimals)</p>
										</div>
									</div>
								</div>
							</div>
					
				</div>

				<!-- Step 2: Vesting Schedule -->
				<div v-if="currentStep === 2" class="space-y-8">
					<div>
						<h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Vesting Schedule</h3>
						<div class="flex flex-col gap-8">
							<!-- Vesting Type -->
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-4">
									Vesting Type *
								</label>
								<div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
									<label v-for="type in vestingTypes" :key="type.value"
										class="flex items-center gap-4 p-4 rounded-lg border transition cursor-pointer shadow-sm"
										:class="formData.vestingType === type.value
											? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
											: 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400'">
										<input v-model="formData.vestingType" :value="type.value" type="radio"
											class="sr-only" />
										<div class="flex items-center justify-center h-10 w-10 rounded-full" :class="formData.vestingType === type.value
											? 'bg-blue-600'
											: 'bg-blue-50 dark:bg-blue-900/20'">
											<component :is="type.icon" class="h-6 w-6" :class="formData.vestingType === type.value
												? 'text-white'
												: 'text-blue-600'" />
										</div>
										<div class="flex-1 min-w-0">
											<div class="text-base font-medium text-gray-900 dark:text-blue-500">{{ type.label }}
											</div>
											<div class="text-sm text-gray-500">{{ type.description }}</div>
										</div>
										<div v-if="formData.vestingType === type.value" class="ml-2">
											<CheckIcon class="h-5 w-5 text-blue-600" />
										</div>
									</label>
								</div>
							</div>
							
							<!-- Universal Cliff Duration (Optional for all vesting types) -->
							<div class="space-y-4" v-if="formData.vestingType !== 'Instant'">
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Cliff Duration (days) - Optional
										</label>
										<input v-model.number="cliffDurationDays" type="number" min="0"
											placeholder="90"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
										<p class="mt-2 text-xs text-gray-500">Optional lock period before vesting begins (leave empty for no cliff)</p>
									</div>
									<!-- Initial Unlock Percentage -->
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Initial Unlock Percentage
										</label>
										<input v-model.number="formData.initialUnlockPercentage" type="number" min="0" max="100"
											placeholder="25"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
										<p class="mt-2 text-xs text-gray-500">Percentage of tokens unlocked immediately (0-100%)
										</p>
									</div>
								</div>
							</div>

							

							<!-- Linear Vesting Configuration -->
							<div v-if="formData.vestingType === 'Linear'" class="space-y-4">
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Vesting Duration (days) *
										</label>
										<input v-model.number="linearDurationDays" type="number" required min="1"
											placeholder="365"
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									</div>
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Unlock Frequency *
										</label>
										<select v-model="formData.linearConfig.frequency" required
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm">
											<option value="">Select frequency</option>
											<option value="Daily">Daily</option>
											<option value="Weekly">Weekly</option>
											<option value="Monthly">Monthly</option>
											<option value="Quarterly">Quarterly</option>
										</select>
									</div>
								</div>
							</div>

							<!-- Custom Vesting Configuration -->
							<div v-if="formData.vestingType === 'Custom'" class="space-y-4">
								<div class="flex items-center justify-between">
									<h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Custom Unlock
										Events</h4>
									<button type="button" @click="addCustomEvent"
										class="px-3 py-1 text-xs bg-blue-600 text-white rounded-lg hover:bg-blue-700">
										Add Event
									</button>
								</div>

								<div v-if="formData.customConfig.length === 0"
									class="text-center py-6 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg">
									<p class="text-sm text-gray-500">No unlock events defined. Click "Add Event" to
										create your
										first unlock milestone.</p>
								</div>

								<div v-for="(event, index) in formData.customConfig" :key="index"
									class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
									<div class="flex items-center justify-between mb-3">
										<h5 class="text-sm font-medium text-gray-700 dark:text-gray-300">Event {{ index
											+ 1 }}
										</h5>
										<button type="button" @click="removeCustomEvent(index)"
											class="text-red-600 hover:text-red-700 text-xs">
											Remove
										</button>
									</div>
									<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
										<div>
											<label
												class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Unlock Date & Time *
											</label>
											<input v-model="event.timestampLocal" type="datetime-local" required
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm" />
										</div>
										<div>
											<label
												class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Amount to Unlock *
											</label>
											<input v-model.number="event.amount" type="number" required min="1"
												placeholder="1000000"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm" />
										</div>
									</div>
								</div>

								<div v-if="formData.customConfig.length > 0"
									class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
									<p class="text-sm text-blue-700 dark:text-blue-300">
										Total amount scheduled: {{ totalCustomAmount.toLocaleString() }} tokens
									</p>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Step 3: Timing -->
				<div v-if="currentStep === 3" class="space-y-8">
					<div>
						<h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Distribution Timing</h3>
						<div class="flex flex-col gap-8">
							<!-- Registration Period -->
							<div>
								<div class="flex items-center gap-3 mb-4">
									<input v-model="formData.hasRegistrationPeriod" type="checkbox" id="hasRegistrationPeriod"
										class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" />
									<label class="text-sm font-medium text-gray-700 dark:text-gray-300" for="hasRegistrationPeriod">
										Enable registration period
									</label>
								</div>
								<div v-if="formData.hasRegistrationPeriod"
									class="grid grid-cols-1 md:grid-cols-2 gap-4">
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Registration Start *
										</label>
										<input v-model="registrationStartDate" type="datetime-local" required
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									</div>
									<div>
										<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
											Registration End *
										</label>
										<input v-model="registrationEndDate" type="datetime-local" required
											class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									</div>
								</div>
							</div>

							<!-- Distribution Timing -->
							<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Distribution Start *
									</label>
									<input v-model="distributionStartDate" type="datetime-local" required
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									<p class="mt-2 text-xs text-gray-500">When the distribution becomes active</p>
								</div>
								<div>
									<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
										Distribution End (Optional)
									</label>
									<input v-model="distributionEndDate" type="datetime-local"
										class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
									<p class="mt-2 text-xs text-gray-500">Leave empty for no end date</p>
								</div>
							</div>
						</div>
					</div>
				</div>

				<!-- Step 4: Settings -->
				<div v-if="currentStep === 4" class="space-y-8">
					<div>
						<h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Additional Settings</h3>
						<div class="flex flex-col gap-8">
							<!-- Fee Structure -->
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-4">
									Fee Structure *
								</label>
								<div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
									<label v-for="fee in feeStructures" :key="keyToText(fee.value)"
										class="flex items-center gap-4 p-4 rounded-lg border transition cursor-pointer shadow-sm"
										:class="keyToText(formData.feeStructure) == keyToText(fee.value)
											? 'border-blue-600 bg-blue-50 dark:bg-blue-900/20'
											: 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-blue-400'">
										<input v-model="formData.feeStructure" :value="fee.value" type="radio"
											class="sr-only" />
										<div class="flex items-center justify-center h-10 w-10 rounded-full" :class="keyToText(formData.feeStructure) == keyToText(fee.value)
											? 'bg-blue-600'
											: 'bg-blue-50 dark:bg-blue-900/20'">
											<component :is="fee.icon || 'SettingsIcon'" class="h-6 w-6" :class="keyToText(formData.feeStructure) == keyToText(fee.value)
												? 'text-white'
												: 'text-blue-600'" />
										</div>
										<div class="flex-1 min-w-0">
											<div class="text-base font-medium text-gray-900 dark:text-blue-500">{{
												fee.label }}
											</div>
											<div class="text-sm text-gray-500">{{ fee.description }}</div>
										</div>
										<div v-if="keyToText(formData.feeStructure) == keyToText(fee.value)" class="ml-2">
											<CheckIcon class="h-5 w-5 text-blue-600" />
										</div>
									</label>
								</div>
							</div>

							<!-- Fee Configuration -->
							<div v-if="keyToText(formData.feeStructure) == 'Fixed'">
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
									Fixed Fee Amount
								</label>
								<input v-model.number="formData.fixedFeeAmount" type="number" min="0" placeholder="1000"
									class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
							</div>

							<div v-if="keyToText(formData.feeStructure) == 'Percentage'">
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
									Percentage Fee Rate (%)
								</label>
								<input v-model.number="formData.percentageFeeRate" type="number" min="0" max="100"
									step="0.1" placeholder="2.5"
									class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
							</div>

							<!-- Progressive Fee Configuration -->
							<div v-if="keyToText(formData.feeStructure) == 'Progressive'" class="space-y-4">
								<div class="flex items-center justify-between">
									<h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Fee Tiers</h4>
									<button type="button" @click="addFeeTier"
										class="px-3 py-1 text-xs bg-blue-600 text-white rounded-lg hover:bg-blue-700">
										Add Tier
									</button>
								</div>

								<div v-if="formData.progressiveTiers.length === 0"
									class="text-center py-6 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg">
									<p class="text-sm text-gray-500">No fee tiers defined. Click "Add Tier" to create
										your first
										tier.</p>
								</div>

								<div v-for="(tier, index) in formData.progressiveTiers" :key="index"
									class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700">
									<div class="flex items-center justify-between mb-3">
										<h5 class="text-sm font-medium text-gray-700 dark:text-gray-300">Tier {{ index +
											1 }}
										</h5>
										<button type="button" @click="removeFeeTier(index)"
											class="text-red-600 hover:text-red-700 text-xs">
											Remove
										</button>
									</div>
									<div class="grid grid-cols-1 md:grid-cols-2 gap-4">
										<div>
											<label
												class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Amount Threshold *
											</label>
											<input v-model.number="tier.threshold" type="number" required min="0"
												placeholder="1000000"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm" />
											<p class="mt-1 text-xs text-gray-500">Amount above which this tier applies
											</p>
										</div>
										<div>
											<label
												class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
												Fee Rate (%) *
											</label>
											<input v-model.number="tier.feeRate" type="number" required min="0"
												max="100" step="0.1" placeholder="1.5"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm" />
											<p class="mt-1 text-xs text-gray-500">Fee percentage for this tier</p>
										</div>
									</div>
								</div>

								<div v-if="formData.progressiveTiers && formData.progressiveTiers.length > 0"
									class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
									<p class="text-sm text-blue-700 dark:text-blue-300">
										{{ formData.progressiveTiers.length }} fee tier(s) configured. Higher tiers apply to larger amounts.
									</p>
								</div>
							</div>

							<!-- Permissions -->
							<div class="space-y-4">
								<h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Permissions</h4>
								<div class="flex flex-col gap-3">
									<div class="flex items-center gap-3">
										<input v-model="formData.allowCancel" type="checkbox" id="allowCancel"
											class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" />
										<label class="text-sm text-gray-700 dark:text-gray-300" for="allowCancel">
											Allow campaign cancellation
										</label>
									</div>
									<div class="flex items-center gap-3">
										<input v-model="formData.allowModification" type="checkbox" id="allowModification"
											class="h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" />
										<label class="text-sm text-gray-700 dark:text-gray-300" for="allowModification">
											Allow campaign modification
										</label>
									</div>
								</div>
							</div>

							<!-- Governance -->
							<div>
								<label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
									Governance Principal (Optional)
								</label>
								<input v-model="formData.governance" type="text"
									placeholder="be2us-64aaa-aaaah-qaabq-cai"
									class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-4 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
								<p class="mt-2 text-xs text-gray-500">Principal that can manage this distribution (MiniDAO, SNS, etc.)</p>
							</div>
							<!-- Summary -->
							<div
								class="bg-gray-50 dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
								<h4 class="text-sm font-medium text-gray-700 dark:text-gray-300 mb-4">Distribution
									Summary</h4>
								<div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
									<div>
										<span class="text-gray-500">Campaign:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ formData.title || 'Not set' }}</span>
									</div>
									<div>
										<span class="text-gray-500">Type:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ formData.campaignType || 'Not set' }}</span>
									</div>
									<div>
										<span class="text-gray-500">Token:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ formData.tokenInfo.symbol || 'Not set' }}</span>
									</div>
									<div>
										<span class="text-gray-500">Total Amount:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ formData.totalAmount || 0 }}</span>
									</div>
									<div>
										<span class="text-gray-500">Eligibility:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ keyToText(formData.eligibilityType) || 'Not set' }}</span>
									</div>
									<div>
										<span class="text-gray-500">Vesting:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ formData.vestingType || 'Not set' }}</span>
									</div>
									<div>
										<span class="text-gray-500">Fee Type:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ keyToText(formData.feeStructure) || 'Not set' }}</span>
									</div>
									<div v-if="keyToText(formData.eligibilityType) == 'Whitelist' && whitelistTotalRecipients > 0">
										<span class="text-gray-500">Recipients:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ whitelistTotalRecipients }} addresses</span>
									</div>
								</div>
							</div>
							<!-- Payment Section -->
							<div
								class="bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-200 dark:border-yellow-800 rounded-lg p-4">
								<div class="flex items-start">
									<div class="flex-shrink-0">
										<svg class="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
											<path fill-rule="evenodd"
												d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
												clip-rule="evenodd" />
										</svg>
									</div>
									<div class="ml-3">
										<h3 class="text-sm font-medium text-yellow-800 dark:text-yellow-200">
											Important Notice
										</h3>
										<div class="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
											<p>
												Once smart contract is successfully deployed, creation fees are
												<strong>non-refundable</strong>.
												Please review your distribution details carefully before proceeding.
											</p>
										</div>
									</div>
								</div>
							</div>

							<!-- Payment Card -->
							<div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
								<div class="flex items-center justify-between">
									<div>
										<h4 class="font-medium text-blue-900 dark:text-blue-100">
											Creation Cost
										</h4>
										<p class="text-sm text-blue-700 dark:text-blue-300">
											One-time creation fee
										</p>
									</div>
									<div class="text-right">
										<div class="text-2xl font-bold text-blue-900 dark:text-blue-100">
											{{ creationCost }} ICP
										</div>
										<button @click="handlePayment" :disabled="!canProceed || isPaying"
											class="mt-2 w-full md:w-auto px-4 py-2 bg-blue-600 text-white text-sm rounded-lg hover:bg-blue-700 disabled:opacity-50 font-medium">
											{{ isPaying ? (paymentStep || 'Processing...') : 'Pay & Deploy' }}
										</button>
									</div>
								</div>
							</div>

							<!-- Deployment Result -->
							<div v-if="deployResult" class="rounded-lg p-4" :class="[
								deployResult.success
									? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800'
									: 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'
							]">
								<div class="flex items-start">
									<div class="flex-shrink-0">
										<svg v-if="deployResult.success" class="w-5 h-5 text-green-400"
											fill="currentColor" viewBox="0 0 20 20">
											<path fill-rule="evenodd"
												d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
												clip-rule="evenodd" />
										</svg>
										<svg v-else class="w-5 h-5 text-red-400" fill="currentColor"
											viewBox="0 0 20 20">
											<path fill-rule="evenodd"
												d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
												clip-rule="evenodd" />
										</svg>
									</div>
									<div class="ml-3">
										<h3 class="text-sm font-medium" :class="[
											deployResult.success
												? 'text-green-800 dark:text-green-200'
												: 'text-red-800 dark:text-red-200'
										]">
											{{ deployResult.success ? 'Deployment Successful!' : 'Deployment Failed' }}
										</h3>
										<div class="mt-1 text-sm" :class="[
											deployResult.success
												? 'text-green-700 dark:text-green-300'
												: 'text-red-700 dark:text-red-300'
										]">
											<div v-if="deployResult.success && deployResult.distributionCanisterId">
												<p class="font-medium">Your distribution is now live on the Internet
													Computer!
												</p>
												<p class="mt-2">
													<span class="font-medium">Distribution Canister ID:</span>
													<code
														class="ml-2 px-2 py-1 bg-white dark:bg-gray-800 rounded text-xs font-mono">
												{{ deployResult.distributionCanisterId }}
											</code>
													<button
														@click="copyToClipboard(deployResult.distributionCanisterId)"
														class="ml-2 px-2 py-1 bg-gray-200 dark:bg-gray-800 rounded text-xs font-mono">
														Copy
													</button>
												</p>
												<p class="mt-2 text-xs">
													You can now use this canister ID to manage your distribution
													campaign.
												</p>
											</div>
											<div v-else-if="!deployResult.success">
												<p>{{ deployResult.error || 'An unknown error occurred during deployment.' }}
												</p>
												<p class="mt-2 text-xs">Please try again or contact support if the issue
													persists.</p>
											</div>
										</div>
									</div>
								</div>
							</div>

							
						</div>
					</div>
				</div>

				<!-- Navigation Buttons -->
				<div class="flex justify-between pt-6 mt-6 border-t border-gray-200 dark:border-gray-700">
					<button type="button" v-if="currentStep > 0" @click="previousStep" class="flex items-center btn-secondary text-blue-700 text-decoration-underline">
						<ArrowLeftIcon class="h-4 w-4 mr-2" />
						Previous
					</button>
					<div v-else></div>

					<div class="flex space-x-3">
						<button v-if="currentStep < steps.length - 1" type="button" @click="nextStep"
							:class="`btn-primary hover:text-decoration flex items-center ${!canProceed ? 'opacity-30' : 'text-blue-700'}`" :disabled="!canProceed">
							Next
							<ArrowRightIcon class="h-4 w-4 ml-2" />
						</button>
						<button v-else type="button" @click="handlePayment" :disabled="isPaying || !canProceed"
							class="btn-primary">
							<div v-if="isPaying" class="flex items-center">
								<div class="animate-spin rounded-full h-4 w-4 border-t-2 border-b-2 border-white mr-2">
								</div>
								{{ paymentStep || 'Processing...' }}
							</div>
							<div v-else class="flex items-center">
								<!-- <RocketIcon class="h-4 w-4 mr-2" />
								Pay & Deploy Distribution -->
							</div>
						</button>
					</div>
				</div>
			</form>
		</div>

		<!-- Success Modal -->
		<div v-if="showSuccessModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
			<div class="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md w-full mx-4">
				<div class="text-center">
					<CheckCircleIcon class="h-12 w-12 text-green-600 mx-auto mb-4" />
					<h3 class="text-lg font-medium text-gray-900 dark:text-white mb-2">
						Distribution Created Successfully!
					</h3>
					<p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
						Your distribution campaign has been deployed to canister: {{
							deploymentResult?.distributionCanisterId }}
					</p>
					<div class="flex space-x-3">
						<button @click="closeSuccessModal" class="flex-1 btn-secondary">
							Create Another
						</button>
						<button @click="viewDistribution" class="flex-1 btn-primary">
							View Distribution
						</button>
					</div>
				</div>
			</div>
		</div>
	</div>
</AdminLayout>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useDistributionStore } from '@/stores/distribution'
import { useUserTokensStore } from '@/stores/userTokens'
import { useProgressDialog } from '@/composables/useProgressDialog'
import { IcrcService } from '@/api/services/icrc'
import { DistributionService } from '@/api/services/distribution'
import { parseTokenAmount } from '@/utils/token'
import { backendService } from '@/api/services/backend'
import { DistributionUtils } from '@/utils/distribution'
import { keyToText } from '@/utils/common'
import { toast } from 'vue-sonner'
import { Principal } from '@dfinity/principal'
import { handleTransferResult, hanldeApproveResult } from '@/utils/icrc'
import {
	ArrowLeftIcon,
	ArrowRightIcon,
	CheckIcon,
	CheckCircleIcon,
	RocketIcon,
	GlobeIcon,
	ShieldCheckIcon,
	CoinsIcon,
	StarIcon,
	ZapIcon,
	TrendingUpIcon,
	ClockIcon,
	LayersIcon,
	SettingsIcon,
	GiftIcon,
	LockIcon,
	RefreshCwIcon,
	CalendarIcon,
	AlertTriangleIcon,
	UsersIcon,
	SlidersIcon
} from 'lucide-vue-next'
import type {
	DistributionFormData,
	EligibilityType,
	RecipientMode,
	VestingType,
	FeeStructure,
	CampaignType
} from '@/types/distribution'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import TokenLogo from '@/components/token/TokenLogo.vue'

const router = useRouter()
const authStore = useAuthStore()
const distributionStore = useDistributionStore()
const userTokensStore = useUserTokensStore()
const progress = useProgressDialog()

// Form state
const currentStep = ref(0)
const isSubmitting = ref(false)
const showSuccessModal = ref(false)
const deploymentResult = ref<{ distributionCanisterId?: string } | null>(null)

// Payment state
const isPaying = ref(false)
const paymentStep = ref('')
const deployResult = ref<{ distributionCanisterId?: string; success: boolean; error?: string } | null>(null)

// Deployment cost
const creationCostBigInt = ref<bigint>(BigInt(0))
const creationCost = computed(() => {
	if (creationCostBigInt.value === BigInt(0)) return '0.3' // fallback
	return (Number(creationCostBigInt.value) / 100000000).toFixed(2) // Convert from e8s to ICP
})

// Check if current configuration is Open + Self-Service
const isOpenSelfService = computed(() => {
	const isOpen = formData.eligibilityType && keyToText(formData.eligibilityType) === 'Open'
	const isSelfService = formData.recipientMode && keyToText(formData.recipientMode) === 'SelfService'
	return isOpen && isSelfService
})

// Calculate tokens per recipient for Open Distribution Configuration
const tokensPerRecipient = computed(() => {
	if (openDistributionConfig.totalRecipients === 0 || formData.totalAmount === 0) {
		return 0
	}
	return formatAmountPerRecipient(formData.totalAmount, openDistributionConfig.totalRecipients)
})

// Format tokens per recipient for display with proper decimals
const formattedTokensPerRecipient = computed(() => {
	if (!formData.tokenInfo.decimals) return '0'
	const perRecipient = tokensPerRecipient.value
	if (perRecipient === 0) return '0'
	// Convert from smallest unit to token unit for display
	return perRecipient
})

// Method to calculate Open Distribution
const calculateOpenDistribution = () => {
	// Set maxRecipients if configured
	if (openDistributionConfig.totalRecipients > 0) {
		formData.maxRecipients = openDistributionConfig.totalRecipients
		hasMaxRecipients.value = true
	} else {
		formData.maxRecipients = undefined
		hasMaxRecipients.value = false
	}
}

const formatAmountPerRecipient = (total: number, recipients: number): string => {
	if (recipients <= 0) return "0";

	const amount = total / recipients;

	if (amount >= 1) {
		return amount.toFixed(2);
	} else {
		return parseFloat(amount.toFixed(6)).toString();
	}
}


// Additional form state
const hasMaxRecipients = ref(false)
const whitelistText = ref('')
const whitelistAmountType = ref('same') // 'same' or 'custom'
const whitelistSameAmount = ref(1000) // Default for 'same'
const linearDurationDays = ref(365)
const cliffDurationDays = ref(90)
const vestingDurationDays = ref(275)
const registrationStartDate = ref('')
const registrationEndDate = ref('')
const distributionStartDate = ref('')
const distributionEndDate = ref('')

// Token selection state
const tokenSelectionMethod = ref('assets') // 'assets' or 'custom'
const selectedAssetId = ref('')
const availableAssets = ref<{ canisterId: string; symbol: string; name: string }[]>([])

// Additional eligibility configuration state
const tokenHolderSnapshotDate = ref('')
const nftCollectionsText = ref('')

// User balance state
const userTokenBalance = ref<bigint | null>(null)
const isLoadingBalance = ref(false)

// Format token balance helper function using existing utility
const formatTokenBalance = (balance: bigint) => {
	if (!formData.tokenInfo.decimals) return '0'
	return parseTokenAmount(balance, formData.tokenInfo.decimals).toFormat()
}

// Refresh user balance function using existing service
const refreshUserBalance = async () => {
	if (!authStore.isConnected || !formData.tokenInfo.canisterId) return
	
	try {
		isLoadingBalance.value = true
		const token = {
			canisterId: formData.tokenInfo.canisterId,
			symbol: formData.tokenInfo.symbol || '',
			name: formData.tokenInfo.name || '',
			decimals: formData.tokenInfo.decimals || 8,
			fee: 0,
			standards: ['ICRC-1'],
			metrics: {
				price: 0,
				volume: 0,
				marketCap: 0,
				totalSupply: 0
			}
		}
		const balance = await IcrcService.getIcrc1Balance(token, Principal.fromText(authStore.principal as string))
		// Handle both bigint and complex return types
		if (typeof balance === 'bigint') {
			userTokenBalance.value = balance
		} else if (balance && typeof balance === 'object' && 'default' in balance) {
			userTokenBalance.value = balance.default
		} else {
			userTokenBalance.value = BigInt(0)
		}
	} catch (error) {
		console.error('Error fetching user balance:', error)
		userTokenBalance.value = BigInt(0)
	} finally {
		isLoadingBalance.value = false
	}
}

// Form data
const formData = reactive<DistributionFormData>({
	// Step 1: Basic Info
	title: '',
	description: '',
	isPublic: true,
	campaignType: 'Airdrop', // New field for campaign type
	useBlockId: false,

	// Step 2: Token Selection
	tokenInfo: {
		canisterId: '',
		symbol: '',
		name: '',
		decimals: 8
	},
	totalAmount: 0,

	// Step 3: Eligibility
	eligibilityType: { Open: null },
	whitelistAddresses: [],
	tokenHolderConfig: {
		canisterId: '',
		minAmount: 0
	},
	nftHolderConfig: {
		canisterId: '',
		minCount: 1
	},
	blockIdScore: 0,
	recipientMode: { SelfService: null },
	maxRecipients: undefined,

	// Step 4: Vesting
	vestingType: 'Instant',
	linearConfig: {
		duration: 0,
		frequency: { Monthly: null }
	},
	cliffConfig: {
		cliffDuration: 0,
		cliffPercentage: 25,
		vestingDuration: 0,
		frequency: { Monthly: null }
	},
	steppedCliffConfig: [],
	customConfig: [],
	initialUnlockPercentage: 0,

	// Step 5: Timing
	hasRegistrationPeriod: false,
	registrationPeriod: undefined,
	distributionStart: new Date(),
	distributionEnd: undefined,

	// Step 6: Settings
	feeStructure: { Free: null },
	fixedFeeAmount: 0,
	percentageFeeRate: 0,
	progressiveTiers: [],
	allowCancel: true,
	allowModification: false,
	governance: '',
	externalCheckers: []
})

// Open Distribution Configuration for Open + Self-Service
const openDistributionConfig = reactive({
	totalRecipients: 0,
	totalTokens: 0
})

// Steps configuration
const steps = [
	{ id: 'basic', name: 'Basic Info' },
	{ id: 'eligibility', name: 'Eligibility' },
	{ id: 'vesting', name: 'Vesting' },
	{ id: 'timing', name: 'Timing' },
	{ id: 'settings', name: 'Settings' }
]

// Configuration options
const campaignTypes = [
	{ value: 'Airdrop', label: 'Airdrop', description: 'Free token distribution to community', icon: GiftIcon },
	{ value: 'Vesting', label: 'Vesting', description: 'Gradual token unlock over time', icon: CalendarIcon },
	{ value: 'Lock', label: 'Token Lock', description: 'Lock tokens for a specific period', icon: LockIcon }
]

const eligibilityTypes = [
	{ value: { Open: null }, label: 'Open to All', description: 'Anyone can participate', icon: GlobeIcon },
	{ value: { Whitelist: null }, label: 'Whitelist Only', description: 'Pre-approved addresses only', icon: ShieldCheckIcon },
	{ value: { TokenHolder: null }, label: 'Token Holders', description: 'Must hold specific tokens', icon: CoinsIcon },
	{ value: { NFTHolder: null }, label: 'NFT Holders', description: 'Must hold specific NFTs', icon: CoinsIcon },


]

const recipientModes = [
	// { value: 'Fixed', label: 'Fixed Recipients', description: 'Pre-defined list of recipients' },
	// { value: { Dynamic: null }, label: 'Dynamic Recipients', description: 'Recipients can be added/modified' }, // Removed per user request
	{ value: { SelfService: null }, label: 'Self-Service', description: 'Users register themselves' }
]

const vestingTypes = [
	{ value: 'Instant', label: 'Instant', description: 'Immediate distribution', icon: ZapIcon },
	{ value: 'Linear', label: 'Linear Vesting', description: 'Gradual unlock over time', icon: TrendingUpIcon },

	// { value: 'SteppedCliff', label: 'Stepped Cliff', description: 'Multiple unlock milestones', icon: LayersIcon },
	{ value: 'Custom', label: 'Custom Schedule', description: 'Define your own schedule', icon: SettingsIcon }
]

const feeStructures = [
	{ value: { Free: null }, label: 'Free', description: 'No fees charged', icon: SettingsIcon },
	{ value: { Fixed: null }, label: 'Fixed Fee', description: 'Fixed amount per distribution', icon: CoinsIcon },
	{ value: { Percentage: null }, label: 'Percentage Fee', description: 'Percentage of distributed amount', icon: TrendingUpIcon },
	{ value: { Progressive: null }, label: 'Progressive Tiers', description: 'Different fees for different tiers', icon: LayersIcon },
	{ value: { RecipientPays: null }, label: 'Recipient Pays', description: 'Recipients pay the fees', icon: ShieldCheckIcon },
	{ value: { CreatorPays: null }, label: 'Creator Pays', description: 'Campaign creator pays fees', icon: ShieldCheckIcon }
]

// Available recipient modes based on eligibility type
const availableRecipientModes = computed(() => {
	// Token and NFT holders should only use Fixed mode
	// if (keyToText(formData.eligibilityType) === 'TokenHolder' || keyToText(formData.eligibilityType) === 'NFTHolder') {
	// 	return recipientModes.filter(mode => keyToText(mode.value) === 'Dynamic')
	// }
	return recipientModes
})

// Calculate total whitelist recipients
const whitelistTotalRecipients = computed(() => {
	if (keyToText(formData.eligibilityType) !== 'Whitelist') return 0
	
	const recipients = whitelistText.value.split('\n').filter(line => line.trim().length > 0)
	return recipients.length
})

// Calculate total whitelist distribution amount
const whitelistTotalAmount = computed(() => {
	if (keyToText(formData.eligibilityType) !== 'Whitelist') return 0
	
	const recipients = whitelistText.value.split('\n').filter(line => line.trim().length > 0)
	if (recipients.length === 0) return 0
	
	if (whitelistAmountType.value === 'same') {
		return recipients.length * whitelistSameAmount.value
	} else {
		return recipients.reduce((total, line) => {
			const [, amount] = line.trim().split(',')
			const numAmount = parseInt(amount, 10)
			return total + (isNaN(numAmount) ? 0 : numAmount)
		}, 0)
	}
})

// Validation
const canProceed = computed(() => {
	switch (currentStep.value) {
		case 0: // Basic Info + Token Selection (no amount validation here anymore)
			const basicValid = formData.title.trim() && formData.description.trim() && formData.campaignType
			const tokenValid = tokenSelectionMethod.value === 'assets' ? 
				selectedAssetId.value :
				formData.tokenInfo.canisterId?.trim()
			
			let allValid = basicValid && tokenValid
			
			if (formData.useBlockId) {
				allValid = allValid && formData?.blockIdScore && formData?.blockIdScore > 0
			}
			
			return allValid
		case 1: // Eligibility
			if (formData?.eligibilityType && keyToText(formData.eligibilityType) === 'Whitelist') {
				if (whitelistAmountType.value === 'same') {
					const validLines = whitelistText.value.split('\n').filter(line => line.trim().length > 0);
					return whitelistSameAmount.value > 0 && validLines.length > 0 && validLines.every(line => {
						const principal = line.trim();
						return principal.length > 0;
					});
				} else {
					const validLines = whitelistText.value.split('\n').filter(line => line.trim().length > 0);
					return validLines.length > 0 && validLines.every(line => {
						const [principal, amount] = line.trim().split(',');
						return principal && principal.length > 0 && amount && !isNaN(parseInt(amount, 10)) && parseInt(amount, 10) > 0;
					});
				}
			}
			if (keyToText(formData.eligibilityType) === 'TokenHolder') {
				return formData.tokenHolderConfig?.canisterId && formData.tokenHolderConfig?.minAmount && formData.tokenHolderConfig?.minAmount > 0;
			}
			if (keyToText(formData.eligibilityType) === 'NFTHolder') {
				return formData.nftHolderConfig?.canisterId && formData.nftHolderConfig?.minCount && formData.nftHolderConfig?.minCount > 0;
			}

			let eligibilityValid = formData.eligibilityType && (keyToText(formData.eligibilityType) === 'Open' || formData.recipientMode)
			
			// Always require totalAmount in this step (moved from Step 1)
			const amountValid = formData.totalAmount > 0
			
			// For Open Distribution Configuration, also validate recipients
			const openConfigValid = keyToText(formData.eligibilityType) !== 'Whitelist' ? 
				openDistributionConfig.totalRecipients > 0 : true
			
			return eligibilityValid && amountValid && openConfigValid
		case 2: // Vesting
			return formData.vestingType &&
				(formData.vestingType === 'Instant' || validateVestingConfig())
		case 3: // Timing
			return distributionStartDate.value && validateTimeLogic.value.valid
		case 4: // Settings
			const feeValid = formData.feeStructure && (
				keyToText(formData.feeStructure) === 'Free' ||
				(keyToText(formData.feeStructure) === 'Fixed' && (formData.fixedFeeAmount || 0) > 0) ||
				(keyToText(formData.feeStructure) === 'Percentage' && (formData.percentageFeeRate || 0) > 0) ||
				(keyToText(formData.feeStructure) === 'Progressive' && formData.progressiveTiers && formData.progressiveTiers.length > 0 &&
					formData.progressiveTiers.every(tier => tier.threshold >= 0 && tier.feeRate > 0)) ||
				['RecipientPays', 'CreatorPays'].includes(keyToText(formData.feeStructure))
			)
			const progressiveValid = validateProgressiveFees.value.valid
			return feeValid && progressiveValid
		default:
			return false
	}
})

const validateVestingConfig = () => {
	if (formData.vestingType === 'Linear') {
		return formData.linearConfig?.frequency && linearDurationDays.value > 0
	}
	if (formData.vestingType === 'Cliff') {
		return formData.cliffConfig?.frequency &&
			cliffDurationDays.value > 0 &&
			vestingDurationDays.value > 0 &&
			formData.cliffConfig?.cliffPercentage &&
			formData.cliffConfig?.cliffPercentage >= 0 &&
			formData.cliffConfig?.cliffPercentage <= 100
	}
	if (formData.vestingType === 'SteppedCliff') {
		return formData.steppedCliffConfig &&
			formData.steppedCliffConfig.length > 0 &&
			formData.steppedCliffConfig.every(step => step.timeOffset > 0 && step.percentage > 0) &&
			totalSteppedCliffPercentage.value <= 100
	}
	if (formData.vestingType === 'Custom') {
		return formData.customConfig &&
			formData.customConfig.length > 0 &&
			formData.customConfig.every(event => event.timestamp && event.amount > 0) &&
			totalCustomAmount.value <= formData.totalAmount
	}
	return true
}

// Navigation
const nextStep = () => {
	if (canProceed.value && currentStep.value < steps.length - 1) {
		processCurrentStep()
		currentStep.value++
	}
}

const previousStep = () => {
	if (currentStep.value > 0) {
		currentStep.value--
	}
}

// Process all steps to ensure data integrity before deployment
const processAllSteps = () => {
	console.log('Processing all steps before deployment')
	// Process step 1 (Eligibility)
	if (formData.eligibilityType && keyToText(formData.eligibilityType) === 'Whitelist') {
		console.log('Processing whitelist data:', whitelistText.value)
		console.log('Whitelist amount type:', whitelistAmountType.value)
		if (whitelistAmountType.value === 'same') {
			formData.whitelistAddresses = whitelistText.value
				.split('\n')
				.map(line => line.trim())
				.filter(line => line.length > 0)
		} else {
			formData.whitelistAddresses = whitelistText.value
				.split('\n')
				.filter(line => line.trim().length > 0)
				.map(line => {
					const [principal, amount, note] = line.trim().split(',');
					return { principal: principal?.trim() || '', amount: parseInt(amount, 10), note: note?.trim() || '' };
				})
				.filter(item => item.principal.length > 0 && !isNaN(item.amount))
		}
		console.log('Processed whitelist addresses:', formData.whitelistAddresses)
	}
	
	// Process step 3 (Vesting) - Convert days to nanoseconds
	if (formData.vestingType === 'Linear') {
		formData.linearConfig!.duration = linearDurationDays.value * 24 * 60 * 60 * 1_000_000_000
	}
	if (formData.vestingType === 'Cliff') {
		formData.cliffConfig!.cliffDuration = cliffDurationDays.value * 24 * 60 * 60 * 1_000_000_000
		formData.cliffConfig!.vestingDuration = vestingDurationDays.value * 24 * 60 * 60 * 1_000_000_000
	}
	
	// Process step 4 (Timing)
	formData.distributionStart = new Date(distributionStartDate.value)
	if (distributionEndDate.value) {
		formData.distributionEnd = new Date(distributionEndDate.value)
	}
	if (formData.hasRegistrationPeriod && registrationStartDate.value && registrationEndDate.value) {
		formData.registrationPeriod = {
			startTime: new Date(registrationStartDate.value),
			endTime: new Date(registrationEndDate.value),
			maxParticipants: undefined
		}
	} else {
		formData.registrationPeriod = undefined
	}
	
	if (!hasMaxRecipients.value) {
		formData.maxRecipients = undefined
	}
}

// Process current step data
const processCurrentStep = () => {
	console.log('Processing step:', currentStep.value)
	switch (currentStep.value) {
		case 1: // Eligibility
			if (keyToText(formData.eligibilityType) === 'Whitelist') {
				console.log('Processing whitelist data:', whitelistText.value)
				console.log('Whitelist amount type:', whitelistAmountType.value)
				if (whitelistAmountType.value === 'same') {
					formData.whitelistAddresses = whitelistText.value
						.split('\n')
						.map(line => line.trim())
						.filter(line => line.length > 0)
				} else {
					formData.whitelistAddresses = whitelistText.value
						.split('\n')
						.filter(line => line.trim().length > 0)
						.map(line => {
							const [principal, amount, note] = line.trim().split(',');
							return { principal: principal?.trim() || '', amount: parseInt(amount, 10), note: note?.trim() || '' };
						})
						.filter(item => item.principal.length > 0 && !isNaN(item.amount))
				}
				console.log('Processed whitelist addresses:', formData.whitelistAddresses)
			}
			// For non-Whitelist distributions, check if we should preserve maxRecipients from Open Distribution Config
			if (keyToText(formData.eligibilityType) === 'Whitelist') {
				// For Whitelist, hasMaxRecipients controls the optional max recipients limit
				if (!hasMaxRecipients.value) {
					formData.maxRecipients = undefined
				}
			} else {
				// For non-Whitelist distributions, maxRecipients should come from Open Distribution Config
				// Don't reset it here as it's controlled by calculateOpenDistribution
			}
			break
		case 2: // Vesting
			// Convert days to nanoseconds (1 day = 24 * 60 * 60 * 1_000_000_000 nanoseconds)
			if (formData.vestingType === 'Linear') {
				formData.linearConfig!.duration = linearDurationDays.value * 24 * 60 * 60 * 1_000_000_000
			}
			if (formData.vestingType === 'Cliff') {
				formData.cliffConfig!.cliffDuration = cliffDurationDays.value * 24 * 60 * 60 * 1_000_000_000
				formData.cliffConfig!.vestingDuration = vestingDurationDays.value * 24 * 60 * 60 * 1_000_000_000
			}
			break
		case 3: // Timing
			formData.distributionStart = new Date(distributionStartDate.value)
			if (distributionEndDate.value) {
				formData.distributionEnd = new Date(distributionEndDate.value)
			}
			if (formData.hasRegistrationPeriod && registrationStartDate.value && registrationEndDate.value) {
				formData.registrationPeriod = {
					startTime: new Date(registrationStartDate.value),
					endTime: new Date(registrationEndDate.value),
					maxParticipants: undefined
				}
			} else {
				formData.registrationPeriod = undefined
			}
			break
	}
}

// Form submission (now handled through payment flow)
const handleSubmit = async () => {
	// This function is now handled through the payment flow in handlePayment()
	// Keep for form compatibility but redirect to payment flow
	if (currentStep.value === steps.length - 1) {
		await handlePayment()
	}
}

const buildDistributionConfig = () => {
	// Convert form data to backend format
	const config = {
		title: formData.title,
		description: formData.description,
		isPublic: formData.isPublic,
		campaignType: formData.campaignType || 'Airdrop', // Default to Airdrop if not set
		tokenInfo: {
			canisterId: formData.tokenInfo.canisterId!,
			symbol: formData.tokenInfo.symbol!,
			name: formData.tokenInfo.name!,
			decimals: formData.tokenInfo.decimals!
		},
		totalAmount: formData.totalAmount,
		eligibilityType: formData.eligibilityType,
		// Include whitelist data when eligibility type is Whitelist
		whitelistAddresses: formData.whitelistAddresses || [],
		whitelistAmountType: whitelistAmountType.value,
		whitelistSameAmount: whitelistSameAmount.value,
		// Include token/NFT holder configurations
		tokenHolderConfig: formData.tokenHolderConfig,
		nftHolderConfig: formData.nftHolderConfig,
		blockIdScore: formData.blockIdScore,
		recipientMode: formData.recipientMode,
		maxRecipients: formData.maxRecipients,
		vestingSchedule: buildVestingSchedule(),
		initialUnlockPercentage: formData.initialUnlockPercentage,
		registrationPeriod: formData.registrationPeriod,
		distributionStart: formData.distributionStart,
		distributionEnd: formData.distributionEnd,
		feeStructure: buildFeeStructure(),
		allowCancel: formData.allowCancel,
		allowModification: formData.allowModification,
		owner: authStore?.principal || '',
		governance: formData.governance || null,
		externalCheckers: formData.externalCheckers?.length ? formData.externalCheckers : null
	}

	console.log('Distribution config being sent:', config)
	return config
}

const buildVestingSchedule = () => {
	// Add universal cliff duration to all vesting types
	const baseConfig = {
		cliffDuration: cliffDurationDays.value > 0 ? cliffDurationDays.value : undefined
	}
	
	switch (formData.vestingType) {
		case 'Instant':
			return { 
				type: 'Instant',
				...baseConfig
			}
		case 'Linear':
			return {
				type: 'Linear',
				config: {
					duration: formData.linearConfig?.duration || 0,
					frequency: formData.linearConfig?.frequency || 'Monthly'
				},
				...baseConfig
			}
		case 'SteppedCliff':
			return {
				type: 'SteppedCliff',
				config: formData.steppedCliffConfig || [],
				...baseConfig
			}
		case 'Custom':
			return {
				type: 'Custom',
				config: formData.customConfig || [],
				...baseConfig
			}
		default:
			return { 
				type: 'Instant',
				...baseConfig
			}
	}
}

const buildFeeStructure = () => {
	switch (keyToText(formData.feeStructure)) {
		case 'Free':
			return { type: 'Free' }
		case 'Fixed':
			return { type: 'Fixed', amount: formData.fixedFeeAmount || 0 }
		case 'Percentage':
			return { type: 'Percentage', rate: formData.percentageFeeRate || 0 }
		case 'Progressive':
			return { type: 'Progressive', tiers: formData.progressiveTiers || [] }
		case 'RecipientPays':
			return { type: 'RecipientPays' }
		case 'CreatorPays':
			return { type: 'CreatorPays' }
		default:
			return { type: 'Free' }
	}
}

// Distribution creation is now handled through the payment flow

// Modal actions
const closeSuccessModal = () => {
	showSuccessModal.value = false
	deploymentResult.value = null
	// Reset form
	Object.assign(formData, {
		title: '',
		description: '',
		isPublic: true,
		campaignType: 'Airdrop',
		tokenInfo: { canisterId: '', symbol: '', name: '', decimals: 8 },
		totalAmount: 0,
		eligibilityType: { Open: null },
		recipientMode: { SelfService: null },
		vestingType: 'Instant',
		initialUnlockPercentage: 0,
		hasRegistrationPeriod: false,
		distributionStart: new Date(),
		feeStructure: { Free: null },
		allowCancel: true,
		allowModification: false,
		whitelistAddresses: [],
		blockIdScore: 0
	})
	currentStep.value = 0
}

const viewDistribution = () => {
	showSuccessModal.value = false
	router.push(`/distribution/${deploymentResult.value?.distributionCanisterId}`)
}

// Initialize dates
const initializeDates = () => {
	const tomorrow = new Date()
	tomorrow.setDate(tomorrow.getDate() + 1)
	tomorrow.setHours(12, 0, 0, 0)

	const nextWeek = new Date(tomorrow)
	nextWeek.setDate(nextWeek.getDate() + 7)

	distributionStartDate.value = tomorrow.toISOString().slice(0, 16)
	registrationStartDate.value = new Date().toISOString().slice(0, 16)
	registrationEndDate.value = tomorrow.toISOString().slice(0, 16)
}

// Watch for changes
watch(() => hasMaxRecipients.value, (newVal) => {
	// Only apply to Whitelist distributions, others use Open Distribution Config
	if (!newVal && keyToText(formData.eligibilityType) === 'Whitelist') {
		formData.maxRecipients = undefined
	}
})

// Watch for Open Distribution Configuration changes
watch(() => [openDistributionConfig.totalRecipients, formData.eligibilityType], () => {
	if (keyToText(formData.eligibilityType) !== 'Whitelist') {
		calculateOpenDistribution()
	}
}, { deep: true })

// Auto-set recipient mode to Fixed for Token/NFT holders
watch(() => formData.eligibilityType, (newType) => {
	if (keyToText(newType) === 'TokenHolder' || keyToText(newType) === 'NFTHolder') {
		formData.recipientMode = { SelfService: null }
	}
})

// Auto-refresh user balance when token info changes
watch(() => formData.tokenInfo.canisterId, (newCanisterId) => {
	if (newCanisterId && authStore.isConnected) {
		// Small delay to ensure token info is fully loaded
		setTimeout(() => {
			refreshUserBalance()
		}, 500)
	} else {
		userTokenBalance.value = null
	}
})

// Fetch available assets
const fetchAvailableAssets = async () => {
	try {
		const assets = await userTokensStore.enabledTokensList
		availableAssets.value = assets
		
		// Auto-select ICP as default if available
		const icpAsset = assets.find(asset => asset.symbol === 'ICP')
		if (icpAsset && !selectedAssetId.value) {
			selectedAssetId.value = icpAsset.canisterId
			onAssetSelected()
		}
	} catch (error) {
		console.error('Failed to fetch available assets:', error)
		alert('Failed to fetch available assets. Please try again.')
	}
}

// Fetch token info when custom canister ID is entered
const fetchTokenInfo = async () => {
	if (!formData.tokenInfo.canisterId) {
		formData.tokenInfo = { canisterId: '', symbol: '', name: '', decimals: 8 }
		return
	}

	try {
		const token = await userTokensStore.getTokenDetails(formData.tokenInfo.canisterId)
		if (token) {
			formData.tokenInfo = {
				canisterId: token.canisterId,
				symbol: token.symbol,
				name: token.name,
				decimals: token.decimals
			}
		} else {
			alert('Token not found. Please ensure the canister ID is correct.')
			formData.tokenInfo = { canisterId: '', symbol: '', name: '', decimals: 8 }
		}
	} catch (error) {
		console.error('Failed to fetch token info:', error)
		alert('Failed to fetch token info. Please try again.')
		formData.tokenInfo = { canisterId: '', symbol: '', name: '', decimals: 8 }
	}
}

// onAssetSelected function
const onAssetSelected = () => {
	if (selectedAssetId.value) {
		const asset = availableAssets.value.find(a => a.canisterId === selectedAssetId.value)
		if (asset) {
			formData.tokenInfo = {
				canisterId: asset.canisterId,
				symbol: asset.symbol,
				name: asset.name,
				decimals: 8 // Default to 8 for assets
			}
		}
	}
}


// Load deployment cost
const loadDeploymentCost = async () => {
	try {
		creationCostBigInt.value = await backendService.getDeploymentFee('distribution_factory')
	} catch (error) {
		console.error('Error loading deployment cost:', error)
		creationCostBigInt.value = BigInt(30000000) // 0.3 ICP fallback
	}
}

// Payment approval flow
const handlePayment = async () => {
	if (!canProceed.value) return

	isPaying.value = true
	deployResult.value = null

	// Progress steps
	const steps = [
		'Getting deployment price...',
		'Approving payment amount...',
		'Verifying approval...',
		'Deploying distribution to canister...',
		'Initializing contract...',
		'Finalizing deployment...'
	]

	// Track current step for retry
	let currentStepIndex = 0
	let deployPrice = BigInt(0)
	let icpToken: any | null = null
	let backendCanisterId = ''
	let approveAmount = BigInt(0)

	// Retry logic for a specific step
	const retryStep = async (stepIdx: number) => {
		progress.setError('')
		progress.setLoading(true)
		progress.setStep(stepIdx)
		try {
			await runSteps(stepIdx)
		} catch (error: unknown) {
			const errorMessage = error instanceof Error ? error.message : 'Unknown error'
			progress.setError(errorMessage)
			deployResult.value = {
				success: false,
				error: errorMessage
			}
			toast.error('Deployment failed: ' + errorMessage)
		} finally {
			isPaying.value = false
			progress.setLoading(false)
		}
	}

	// Main step runner
	const runSteps = async (startIdx = 0) => {
		for (let i = startIdx; i < steps.length; i++) {
			currentStepIndex = i
			progress.setStep(i)

			try {
				switch (i) {
					case 0: // Get deployment price
						deployPrice = await DistributionUtils.getDistributionDeployPrice()
						backendCanisterId = await backendService.getBackendCanisterId()

						// Get ICP token info for approval
						icpToken = {
							canisterId: 'ryjl3-tyaaa-aaaaa-aaaba-cai', // ICP Ledger
							name: 'Internet Computer',
							symbol: 'ICP',
							decimals: 8,
							fee: 10000,
							standards: ['ICRC-1', 'ICRC-2'],
							metrics: {
								price: 0,
								volume: 0,
								marketCap: 0,
								totalSupply: 0
							}
						}

						// Calculate approve amount: deployPrice + (2 * transaction fee)
						const transactionFee = BigInt(icpToken.fee)
						approveAmount = deployPrice + (transactionFee * BigInt(2))
						break

					case 1: // ICRC2 Approve
						if (!icpToken || !authStore.principal) {
							throw new Error('Missing required data for approval')
						}

						const now = BigInt(Date.now()) * 1_000_000n; // nanoseconds
						const oneHour = 60n * 60n * 1_000_000_000n;  // 1 hour in nanoseconds

						const approveResult = await IcrcService.icrc2Approve(
							icpToken,
							Principal.fromText(backendCanisterId),
							approveAmount,
							{
								memo: undefined,
								createdAtTime: now,
								expiresAt: now + oneHour,
								expectedAllowance: undefined
							}
						)

						const approveResultData = hanldeApproveResult(approveResult)
						if (approveResultData.error) {
							throw new Error(approveResultData.error.message)
						}
						break

					case 2: // Verify approval
						if (!icpToken || !authStore.principal) {
							throw new Error('Missing required data for verification')
						}

						const allowance = await IcrcService.getIcrc2Allowance(
							icpToken,
							Principal.fromText(authStore.principal),
							Principal.fromText(backendCanisterId)
						)

						if (allowance < deployPrice) {
							throw new Error(`Insufficient allowance: ${allowance.toString()} < ${deployPrice.toString()}`)
						}
						break

					case 3: // Deploy distribution
						// Process all steps to ensure data is properly set
						processAllSteps()
						const config = buildDistributionConfig()
						const backendRequest = DistributionUtils.convertToBackendRequest(config as any)
						const deployDistributionResult = await backendService.deployDistribution(backendRequest)

						if (!deployDistributionResult.success) {
							throw new Error(`Distribution deployment failed: ${deployDistributionResult.error}`)
						}

						deployResult.value = {
							distributionCanisterId: deployDistributionResult.distributionCanisterId,
							success: true
						}
						break

					case 4: // Initialize contract
					if (deployResult.value?.distributionCanisterId) {
						try {
							const initResult = await DistributionService.initializeContract(deployResult.value.distributionCanisterId)
							if ('ok' in initResult) {
								console.log('Contract initialized successfully')
							} else {
								console.warn('Contract initialization failed:', initResult.err)
								toast.warning('Contract deployed but initialization failed. You may need to initialize manually.')
							}
						} catch (error) {
							console.error('Error during auto-initialization:', error)
							toast.warning('Contract deployed but auto-initialization failed. You may need to initialize manually.')
						}
					}
					break
				case 5: // Finalize
						progress.setLoading(false)
						progress.close()

						toast.success(`🎉 Distribution deployed successfully! Canister ID: ${deployResult.value?.distributionCanisterId}`)

						// Update the deployment result for the UI
						deploymentResult.value = {
							distributionCanisterId: deployResult.value?.distributionCanisterId || ''
						}
						showSuccessModal.value = true
						return
				}

				// Add delay between steps for UX
				if (i < steps.length - 1) {
					await new Promise(resolve => setTimeout(resolve, 1000))
				}

			} catch (error) {
				console.error(`Error at step ${i}:`, error)
				throw error
			}
		}
	}

	// Start the deployment process
	progress.open({
		steps,
		title: 'Deploying Distribution',
		subtitle: 'Please wait while we process your deployment',
		onRetryStep: retryStep
	})
	progress.setLoading(true)
	progress.setStep(0)

	try {
		await runSteps(0)
	} catch (error: unknown) {
		const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
		progress.setError(errorMessage)
		deployResult.value = {
			success: false,
			error: errorMessage
		}
		toast.error('Distribution deployment failed: ' + errorMessage)
	} finally {
		isPaying.value = false
		progress.setLoading(false)
	}
}

// Stepped Cliff Management
const addCliffStep = () => {
	if (!formData.steppedCliffConfig) {
		formData.steppedCliffConfig = []
	}
	formData.steppedCliffConfig.push({
		timeOffset: 0,
		percentage: 0
	})
}

const removeCliffStep = (index: number) => {
	if (formData.steppedCliffConfig && index >= 0 && index < formData.steppedCliffConfig.length) {
		formData.steppedCliffConfig.splice(index, 1)
	}
}

// Custom Events Management
const addCustomEvent = () => {
	if (!formData.customConfig) {
		formData.customConfig = []
	}
	formData.customConfig.push({
		timestamp: new Date(),
		amount: 0
	})
}

const removeCustomEvent = (index: number) => {
	if (formData.customConfig && index >= 0 && index < formData.customConfig.length) {
		formData.customConfig.splice(index, 1)
	}
}

// Progressive Fee Tiers Management
const addFeeTier = () => {
	if (!formData.progressiveTiers) {
		formData.progressiveTiers = []
	}
	formData.progressiveTiers.push({
		threshold: 0,
		feeRate: 0
	})
}

const removeFeeTier = (index: number) => {
	if (formData.progressiveTiers && index >= 0 && index < formData.progressiveTiers.length) {
		formData.progressiveTiers.splice(index, 1)
	}
}

// Computed Properties for Validation
const totalSteppedCliffPercentage = computed(() => {
	if (!formData.steppedCliffConfig || formData.steppedCliffConfig.length === 0) {
		return 0
	}
	return formData.steppedCliffConfig.reduce((total, step) => total + (step.percentage || 0), 0)
})

const totalCustomAmount = computed(() => {
	if (!formData.customConfig || formData.customConfig.length === 0) {
		return 0
	}
	return formData.customConfig.reduce((total, event) => total + (event.amount || 0), 0)
})

// Utility function to copy text to clipboard
const copyToClipboard = async (text: string) => {
	try {
		await navigator.clipboard.writeText(text)
		toast.success('Copied to clipboard!')
	} catch (error) {
		console.error('Failed to copy to clipboard:', error)
		toast.error('Failed to copy to clipboard')
	}
}

// Enhanced validation functions
const validateAmountVsRecipients = computed(() => {
	if (!formData.totalAmount || formData.totalAmount <= 0) return { valid: false, message: 'Total amount is required' }
	
	// For whitelist, check if amount covers all recipients
	if (formData.eligibilityType && keyToText(formData.eligibilityType) === 'Whitelist') {
		const recipients = whitelistText.value.split('\n').filter(line => line.trim().length > 0)
		if (recipients.length === 0) return { valid: false, message: 'No recipients specified' }
		
		if (whitelistAmountType.value === 'same') {
			const totalNeeded = recipients.length * whitelistSameAmount.value
			if (totalNeeded > formData.totalAmount) {
				return { 
					valid: false, 
					message: `Total amount (${formData.totalAmount}) insufficient for ${recipients.length} recipients × ${whitelistSameAmount.value} = ${totalNeeded}` 
				}
			}
		} else {
			let totalCustomAmounts = 0
			for (const line of recipients) {
				const [, amount] = line.trim().split(',')
				if (amount && !isNaN(parseInt(amount, 10))) {
					totalCustomAmounts += parseInt(amount, 10)
				}
			}
			if (totalCustomAmounts > formData.totalAmount) {
				return { 
					valid: false, 
					message: `Total amount (${formData.totalAmount}) insufficient for custom amounts totaling ${totalCustomAmounts}` 
				}  
			}
		}
	}
	
	// Check max recipients limit
	if (formData.maxRecipients && formData.maxRecipients > 0) {
		const estimatedAmount = formData.totalAmount / formData.maxRecipients
		if (estimatedAmount < 1) {
			return { 
				valid: false, 
				message: `Amount per recipient would be less than 1 token (${estimatedAmount.toFixed(6)})` 
			}
		}
	}
	
	return { valid: true, message: '' }
})

const validateTimeLogic = computed(() => {
	const now = new Date()
	
	// Distribution start should be in the future (with some tolerance)
	const distributionStart = new Date(distributionStartDate.value)
	if (distributionStart < now) {
		const timeDiff = now.getTime() - distributionStart.getTime()
		if (timeDiff > 5 * 60 * 1000) { // Allow 5 minutes tolerance
			return { valid: false, message: 'Distribution start time should be in the future' }
		}
	}
	
	// Registration period validation
	if (formData.hasRegistrationPeriod && registrationStartDate.value && registrationEndDate.value) {
		const regStart = new Date(registrationStartDate.value)
		const regEnd = new Date(registrationEndDate.value)
		
		if (regStart >= regEnd) {
			return { valid: false, message: 'Registration end must be after registration start' }
		}
		
		if (regEnd >= distributionStart) {
			return { valid: false, message: 'Registration must end before distribution starts' }
		}
		
		if (regStart < now) {
			return { valid: false, message: 'Registration start should be in the future' }
		}
	}
	
	// Distribution end validation
	if (distributionEndDate.value) {
		const distributionEnd = new Date(distributionEndDate.value)
		if (distributionEnd <= distributionStart) {
			return { valid: false, message: 'Distribution end must be after distribution start' }
		}
	}
	
	return { valid: true, message: '' }
})

const validateProgressiveFees = computed(() => {
	if (formData.feeStructure && keyToText(formData.feeStructure) !== 'Progressive' || !formData.progressiveTiers || formData.progressiveTiers.length === 0) {
		return { valid: true, message: '' }
	}
	
	// Check if tiers are sorted by threshold
	for (let i = 1; i < formData.progressiveTiers.length; i++) {
		if (formData.progressiveTiers[i].threshold <= formData.progressiveTiers[i - 1].threshold) {
			return { valid: false, message: 'Progressive fee tiers must be sorted by threshold (ascending)' }
		}
	}
	
	// Check for reasonable fee rates
	for (const tier of formData.progressiveTiers) {
		if (tier.feeRate > 50) {
			return { valid: false, message: 'Fee rate should not exceed 50%' }
		}
	}
	
	return { valid: true, message: '' }
})

// Initialize component
initializeDates()
fetchAvailableAssets()
loadDeploymentCost()
</script>

<style scoped>
	/* Custom CSS for connector lines */
	.step-item:not(:last-child)::after {
		content: '';
		position: absolute;
		top: 1rem;
		left: calc(50% + 1.25rem); /* Distance from current step */
		width: calc(100% - 2.5rem); /* Length of line */
		height: 2px;
		background-color: #e5e7eb;
		z-index: 0;
	}

	.step-item.completed:not(:last-child)::after {
		background-color: #b27c10;
	}
	
	/* Alternative approach with better positioning */
	.connector-line {
		position: absolute;
		top: 1rem;
		left: calc(50% + 1rem);
		right: calc(-50% + 1rem);
		height: 2px;
		z-index: 0;
	}
</style>