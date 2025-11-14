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
				<!-- Step 0: Basic Information -->
				<div v-if="currentStep === 0" class="space-y-8">
					<div>
						<h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-6">Basic Information</h3>
						<div class="flex flex-col gap-6">

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
											<Select 
												v-model="selectedAssetId" 
												:options="availableAssets.map(asset => ({ label: `${asset.symbol} - ${asset.name}`, value: asset.canisterId }))"
												placeholder="Choose token"
											/>
											<!-- <select v-model="selectedAssetId" required
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white text-sm"
												@change="onAssetSelected">
												<option value="">Choose token</option>
												<option v-for="asset in availableAssets" :key="asset.canisterId"
													:value="asset.canisterId">
													{{ asset.symbol }} - {{ asset.name }}
												</option>
											</select> -->
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
						</div>
					</div>
				</div>
				<!-- Step 1: Categories & Distribution -->
				<div v-if="currentStep === 1" class="space-y-6">
					<CategoryManagement v-model="categories" />
				</div>
				<!-- Step 2: Settings & Payment -->
				<div v-if="currentStep === 2" class="space-y-8">
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


							<!-- Progressive Fee Configuration - COMMENTED FOR FUTURE USE -->
							<!-- 
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
							-->

							<!-- Fee Payment Token Configuration -->
							<div v-if="keyToText(formData.feeStructure) === 'Fixed'">
								<FeePaymentToken 
									v-model="feePaymentTokenConfig"
									:distribution-token="formData.tokenInfo"
									:available-assets="availableAssets.map(asset => ({ canisterId: asset.canisterId, symbol: asset.symbol, name: asset.name, decimals: (asset as any).decimals || 8 }))"
								/>
							</div>

							<!-- Permissions -->
							<div class="space-y-4">
								<h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Permissions</h4>
								<div class="flex flex-col gap-3">
									<BaseSwitch
										v-model="formData.allowCancel"
										label="Allow the owner to cancel the contract, remaining tokens will be transfered to the owner"
										label-position="right"
									/>
									<BaseSwitch
										v-model="formData.allowModification"
										label="Allow the owner to modify the contract information."
										label-position="right"
									/>
								</div>
							</div>

							<!-- Governance -->
							<div class="space-y-4">
								<h4 class="text-sm font-medium text-gray-700 dark:text-gray-300">Advanced Settings</h4>
									<div class="flex flex-col gap-3">
										<BaseSwitch
											v-model="formData.governanceEnabled"
											label="Governance control enabled, only the governance principal can manage the distribution"
											label-position="right"
										/>
										<!-- <div>
											<input v-model="formData.governance" type="text"
												placeholder="be2us-64aaa-aaaah-qaabq-cai"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-2 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm" />
											<p class="mt-2 text-xs text-gray-500">Principal that can manage this distribution (MiniDAO, SNS, etc.)</p>
										</div> -->
									
									<!-- ICTO Passport Optional Configuration -->
									
										<BaseSwitch
											v-model="formData.useBlockId"
											label="Require ICTO Passport score check for eligibility"
											label-position="right"
										/>
										
										<!-- Block ID Score Input (conditional) -->
										<div v-if="formData.useBlockId" class="mt-2">
											<input v-model.number="formData.ictoPassportScore" type="number" required min="0"
												placeholder="50"
												class="block w-full rounded-lg border border-gray-300 dark:border-gray-600 px-2 py-3 shadow-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-700 dark:text-white sm:text-sm text-sm" />
											<p class="mt-2 text-xs text-gray-500">Minimum Block ID score required for eligibility</p>
										</div>
								

									<!-- Public Distribution Toggle -->
									
										<BaseSwitch
											v-model="formData.isPublic"
											label="Public Distribution"
											label-position="right"
										/>
										<div v-if="formData.isPublic" class="mt-1 p-3 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800">
											<p class="text-sm text-green-700 dark:text-green-300 flex items-center gap-2">
												<GlobeIcon class="w-5 h-5 text-green-600 dark:text-green-400 mt-0.5 flex-shrink-0" /> This distribution will be discoverable by all users and appear in public listings.
											</p>
										</div>
										<div v-else class="mt-1 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
											<p class="text-sm text-blue-700 dark:text-blue-300 flex items-center gap-2">
												<LockIcon class="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" /> This distribution will be private and only accessible via direct link or by eligible participants.
											</p>
										</div>
									</div>
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
									<div v-if="categories.length > 0">
										<span class="text-gray-500">Categories:</span>
										<span class="ml-2 font-medium text-gray-900 dark:text-white">{{ categories.length }} categor{{ categories.length > 1 ? 'ies' : 'y' }}</span>
									</div>
								</div>
							</div>

							<!-- Payment Card -->
							<div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4">
								<div class="flex items-center justify-between">
									<div>
										<h4 class="font-medium text-blue-900 dark:text-blue-100">
											Creation Cost (One-time creation fee)
										</h4>
										<p class="text-sm text-blue-700 dark:text-blue-300">
											One-time creation fee
										</p>
										<div class="mt-1 text-sm text-yellow-700 dark:text-yellow-300">
											<p>
												Once smart contract is successfully deployed, creation fees are
												<strong>non-refundable</strong>.
												Please review your distribution details carefully before proceeding.
											</p>
										</div>
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
					<button type="button" v-if="currentStep > 0" @click="previousStep" :class="`bg-blue-500 hover:bg-blue-600 text-white font-normal py-2 px-4 rounded flex items-center justify-center text-sm`">
						<ArrowLeftIcon class="h-4 w-4 mr-2" />
						Previous
					</button>
					<div v-else></div>

					<div class="flex space-x-3">
						<button v-if="currentStep < steps.length - 1"
							@click="nextStep"
							:class="`bg-blue-500 hover:bg-blue-600 text-white font-normal py-2 px-4 rounded w-full flex items-center justify-center text-sm ${!canProceed ? 'opacity-30' : ''}`"  :disabled="!canProceed"
							>
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
	CampaignType
} from '@/types/distribution'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import TokenLogo from '@/components/token/TokenLogo.vue'
import FeePaymentToken from '@/components/distribution/FeePaymentToken.vue'
import LockConfiguration from '@/components/distribution/LockConfiguration.vue'
import PenaltyUnlockConfig from '@/components/distribution/PenaltyUnlockConfig.vue'
import TimingConfiguration from '@/components/distribution/TimingConfiguration.vue'
import CategoryManagement from '@/components/distribution/CategoryManagement.vue'
import type { CategoryData } from '@/components/distribution/CategoryCard.vue'
import type { FeePaymentTokenConfig } from '@/components/distribution/FeePaymentToken.vue'
import type { LockUIState } from '@/utils/lockConfig'
import type { PenaltyUnlock } from '@/types/distribution'
import { lockConfigToSingleVesting, cliffConfigToLockConfig } from '@/utils/lockConfig'
import { useSwal } from '@/composables/useSwal2'

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
	} else {
		formData.maxRecipients = undefined
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

// Calculate total amount from whitelist for Lock campaigns


// Additional form state (kept for other features if needed)
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

// Lock configuration state
// Lock config removed - each category manages its own vesting

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
	tokenHolderConfig: {
		canisterId: '',
		minAmount: 0
	},
	nftHolderConfig: {
		canisterId: '',
		minCount: 1
	},
	ictoPassportScore: 0,
	recipientMode: { SelfService: null },
	maxRecipients: undefined,

	// Step 4: Categories & Vesting (handled by categories state)
	// Legacy vesting fields - kept for compatibility but not used in UI
	vestingType: 'Instant',
	initialUnlockPercentage: 0,
	linearConfig: {},
	cliffConfig: {},
	singleConfig: {},
	steppedCliffConfig: [],
	customConfig: [],
	penaltyUnlock: {},

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
	externalCheckers: [],
})

// Fee Payment Token Configuration
const feePaymentTokenConfig = ref<FeePaymentTokenConfig>({
	fixedAmount: '',
	useDistributionToken: true,
	customToken: {
		method: 'assets'
	}
})

// Penalty unlock config removed - handled per category if needed

// Open Distribution Configuration for Open + Self-Service
const openDistributionConfig = reactive({
	totalRecipients: 0,
	totalTokens: 0
})

// Categories for multi-category distribution
const categories = ref<CategoryData[]>([
	{
		id: 1,
		name: 'Default Category',
		mode: 'predefined',
		recipientsText: '',
		passportScore: 0, // Default: disabled (no verification)
		passportProvider: 'ICTO', // Default provider
		vestingSchedule: null, // Default: No vesting (instant unlock)
		vestingStartDate: new Date(Date.now() + 5 * 60 * 1000).toISOString().slice(0, 16), // 5 minutes from now
		note: ''
	}
])

// Timing configuration states
const distributionTimingConfig = ref({
	mode: 'immediate' as 'immediate' | 'scheduled',
	startTime: '',
	endTime: ''
})

const registrationTimingConfig = ref({
	mode: 'immediate' as 'immediate' | 'scheduled', 
	startTime: '',
	endTime: '',
	maxParticipants: undefined as number | undefined
})


// Steps configuration (3 steps - streamlined)
const steps = [
	{ id: 'basic', name: 'Basic Info' },
	{ id: 'categories', name: 'Categories & Distribution' },
	{ id: 'settings', name: 'Settings & Payment' },
]

// Configuration options


// Filter vesting types based on campaign type
const availableVestingTypes = computed(() => {
	if (formData.campaignType === 'Lock') {
		// Lock campaigns only support Single Unlock
		return vestingTypes.filter(type => type.value === 'Single')
	}
	return vestingTypes
})

const recipientModes = [
	// { value: 'Fixed', label: 'Fixed Recipients', description: 'Pre-defined list of recipients' },
	// { value: { Dynamic: null }, label: 'Dynamic Recipients', description: 'Recipients can be added/modified' }, // Removed per user request
	{ value: { SelfService: null }, label: 'Self-Service', description: 'Users register themselves' }
]

const vestingTypes = [
	{ value: 'Instant', label: 'Instant', description: 'Immediate distribution', icon: ZapIcon },
	{ value: 'Linear', label: 'Linear Vesting', description: 'Gradual unlock over time', icon: TrendingUpIcon },
	{ value: 'Cliff', label: 'Cliff Vesting', description: 'Cliff period + gradual vesting', icon: ClockIcon },
	{ value: 'Single', label: 'Single Unlock', description: 'Locked until specific time, then 100% unlock', icon: LockIcon },
	// { value: 'SteppedCliff', label: 'Stepped Cliff', description: 'Multiple unlock milestones', icon: LayersIcon },
	{ value: 'Custom', label: 'Custom Schedule', description: 'Define your own schedule', icon: SettingsIcon }
]

const feeStructures = [
	{ value: { Free: null }, label: 'Free', description: 'No fees charged', icon: SettingsIcon },
	{ value: { Fixed: null }, label: 'Fixed Fee', description: 'Fixed amount per distribution', icon: CoinsIcon },
	// { value: { Percentage: null }, label: 'Percentage Fee', description: 'Percentage of distributed amount', icon: TrendingUpIcon },
	// { value: { Progressive: null }, label: 'Progressive Tiers', description: 'Different fees for different tiers', icon: LayersIcon }
]

// Available recipient modes based on eligibility type
const availableRecipientModes = computed(() => {
	// Token and NFT holders should only use Fixed mode
	// if (keyToText(formData.eligibilityType) === 'TokenHolder' || keyToText(formData.eligibilityType) === 'NFTHolder') {
	// 	return recipientModes.filter(mode => keyToText(mode.value) === 'Dynamic')
	// }
	return recipientModes
})

// Check if eligibility type is enabled based on campaign type

// Calculate total whitelist recipients

// Validation
const canProceed = computed(() => {
	switch (currentStep.value) {
		case 0: // Basic Info + Token Selection (removed campaign type requirement)
			const basicValid = formData.title.trim() && formData.description.trim()
			const tokenValid = tokenSelectionMethod.value === 'assets' ?
				selectedAssetId.value :
				formData.tokenInfo.canisterId?.trim()

			let allValid = basicValid && tokenValid

			if (formData.useBlockId) {
				allValid = allValid && formData?.ictoPassportScore && formData?.ictoPassportScore > 0
			}

			return allValid
		case 1: // Categories & Distribution
			// Validate that we have at least one category
			if (categories.value.length === 0) return false

			// Check each category has required data
			const categoriesValid = categories.value.every(category => {
				// Must have name
				if (!category.name.trim()) return false

				// Check based on distribution method
				if (category.mode === 'predefined') {
					// PREDEFINED MODE: Allow proceeding without recipients for now (user can add them in Settings step)
					// const recipients = parseCategoryRecipients(category.recipientsText)
					// if (recipients.length === 0) return false
				} else {
					// OPEN MODE: Must have complete config
					if (!category.maxRecipients || category.maxRecipients <= 0) return false
					if (!category.amountPerRecipient || category.amountPerRecipient <= 0) return false
				}

				// NOTE: Registration and ICTO Passport validation moved to global settings
				// Vesting schedule is optional (null = instant unlock)
				// No validation needed for vesting schedule

				// Must have vesting start date
				if (!category.vestingStartDate) return false

				return true
			})

			return categoriesValid
		case 2: // Settings & Payment
			const feeValid = formData.feeStructure && (
				keyToText(formData.feeStructure) === 'Free' ||
				(keyToText(formData.feeStructure) === 'Fixed' &&
					parseFloat(feePaymentTokenConfig.value.fixedAmount) > 0 &&
					(feePaymentTokenConfig.value.useDistributionToken ||
						feePaymentTokenConfig.value.customToken?.assetId ||
						feePaymentTokenConfig.value.customToken?.customId)
				)
			)
			// Final validation - check categories are properly configured
			const categoriesConfigured = categories.value.some(category => {
				if (category.mode === 'predefined') {
					// Predefined mode: allow proceeding without recipients for now
					return true // Temporarily allow
				} else {
					// Open mode: must have valid config
					return category.maxRecipients && category.maxRecipients > 0 &&
						   category.amountPerRecipient && category.amountPerRecipient > 0
				}
			})
			return feeValid && categoriesConfigured
		default:
			return false
	}
})


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
	// Legacy eligibility and vesting processing removed - now handled by multi-category system

	// Process step 3 (Vesting) - Legacy vesting type handling
	if (formData.vestingType === 'Linear') {
		// Legacy linear vesting - should not be used with multi-category
	}
	if (formData.vestingType === 'Cliff') {
		// Legacy cliff vesting - should not be used with multi-category
	}
	if (formData.vestingType === 'Single') {
		// For Lock campaigns, use lockConfig values; for regular campaigns, use singleDuration values
		let durationValue: number
		let durationUnit: string

		if (formData.campaignType === 'Lock') {
			// These values can be hardcoded or retrieved from form data if needed
			durationValue = 30 // Default 30 days
			durationUnit = 'days'
		} else {
			durationValue = 30 // Default 30 days
			durationUnit = 'days'
		}
		
		// Convert duration to nanoseconds based on unit
		let durationInNanoseconds = durationValue * 24 * 60 * 60 * 1_000_000_000 // default days
		if (durationUnit === 'months') {
			durationInNanoseconds = durationValue * 30 * 24 * 60 * 60 * 1_000_000_000 // approximate months
		} else if (durationUnit === 'years') {
			durationInNanoseconds = durationValue * 365 * 24 * 60 * 60 * 1_000_000_000 // approximate years
		}
		formData.singleConfig!.duration = durationInNanoseconds
	}
	
	// Process step 4 (Timing)
	// For Lock campaigns with immediate timing, set distributionStart to current time + buffer
	if (formData.campaignType === 'Lock' && true) { // Simplified condition
		const now = new Date()
		const immediateStart = new Date(now.getTime() + 5 * 60 * 1000) // Add 5 minutes buffer
		formData.distributionStart = immediateStart
	} else {
		// For scheduled campaigns, validate and adjust if needed
		const scheduledTime = new Date(distributionStartDate.value)
		const now = new Date()
		
		if (scheduledTime <= now) {
			// If scheduled time is in the past or too close, set to current time + buffer
			const immediateStart = new Date(now.getTime() + 5 * 60 * 1000) // Add 5 minutes buffer
			formData.distributionStart = immediateStart
		} else {
			formData.distributionStart = scheduledTime
		}
	}
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
}

// Process current step data
const processCurrentStep = () => {
	console.log('Processing step:', currentStep.value)
	switch (currentStep.value) {
		case 1: // Eligibility
			// Legacy whitelist processing removed - now handled by multi-category system
			break
		case 2: // Categories & Vesting
			// Legacy vesting processing removed - now handled by multi-category system
			break
		case 3: // Settings
			// Process timing configurations if needed
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

// Parse recipients text for a category
const parseCategoryRecipients = (text?: string) => {
	if (!text?.trim()) return []

	return text
		.split('\n')
		.filter(line => line.trim())
		.map(line => {
			const [principal, amountStr, note] = line.trim().split(',')
			const amount = parseInt(amountStr?.trim() || '0', 10)
			return {
				principal: principal?.trim() || '',
				amount: isNaN(amount) ? 0 : amount,
				note: note?.trim() || ''
			}
		})
		.filter(r => r.principal && r.amount > 0)
}

// Build vesting schedule from category data
const buildCategoryVestingSchedule = (category: CategoryData) => {
	const schedule = category.vestingSchedule
	if (!schedule) {
		return { Instant: null }
	}

	// Convert days to nanoseconds
	const durationNs = (schedule.durationDays || 0) * 24 * 60 * 60 * 1_000_000_000
	const cliffNs = (schedule.cliffDays || 0) * 24 * 60 * 60 * 1_000_000_000

	// Build frequency variant based on UI config
	const frequencyMap: Record<string, any> = {
		'Daily': { Daily: null },
		'Weekly': { Weekly: null },
		'Monthly': { Monthly: null },
		'Quarterly': { Quarterly: null },
		'Yearly': { Yearly: null },
		'Continuous': { Continuous: null }
	}
	const frequencyVariant = frequencyMap[schedule.releaseFrequency || 'Monthly'] || { Monthly: null }

	// Convert to backend variant format
	switch (schedule.type) {
		case 'Instant':
			return { Instant: null }

		case 'Linear':
			return {
				Linear: {
					duration: durationNs,
					frequency: frequencyVariant
				}
			}

		case 'Cliff':
			return {
				Cliff: {
					cliffDuration: cliffNs,
					cliffPercentage: 0, // Simplified - removed property that doesn't exist
					vestingDuration: durationNs,
					frequency: frequencyVariant
				}
			}

		default:
			// Fallback to linear vesting
			return {
				Linear: {
					duration: durationNs,
					frequency: frequencyVariant
				}
			}
	}
}

// Build multi-category recipients
const buildMultiCategoryRecipients = () => {
	const recipientMap = new Map<string, any>() // principal -> recipient data

	for (const category of categories.value) {
		// Only process predefined mode categories
		// Registration mode categories don't have recipients yet (they register later)
		if (category.mode !== 'predefined') {
			continue
		}

		const categoryRecipients = parseCategoryRecipients(category.recipientsText)

		for (const recipient of categoryRecipients) {
			const principal = recipient.principal

			// Get or create recipient entry
			if (!recipientMap.has(principal)) {
				recipientMap.set(principal, {
					address: principal,
					categories: [],
					note: ''
				})
			}

			// Convert vesting start date to nanoseconds
			const vestingStartMs = new Date(category.vestingStartDate).getTime()
			const vestingStartNs = vestingStartMs * 1_000_000 // Convert ms to ns

			// Add this category allocation
			recipientMap.get(principal).categories.push({
				categoryId: category.id,
				categoryName: category.name,
				amount: recipient.amount,
				claimedAmount: 0,
				vestingSchedule: buildCategoryVestingSchedule(category),
				vestingStart: vestingStartNs,
				note: recipient.note || category.note || ''
			})
		}
	}

	return Array.from(recipientMap.values())
}

// Convert eligibility type from Motoko to Backend format
const convertEligibilityType = (eligibilityType: any): any => {
	if ('Whitelist' in eligibilityType) {
		return {
			Whitelist: eligibilityType.Whitelist.map((principal: any) => principal.toText())
		}
	}
	return eligibilityType
}

// Convert recipient mode from Motoko to Backend format
const convertRecipientMode = (recipientMode: any): 'SelfService' | 'Dynamic' | 'Fixed' => {
	if ('Fixed' in recipientMode) {
		return 'Fixed'
	}
	return 'SelfService' // Default fallback
}

// Convert external checkers from Motoko to Backend format
const convertExternalCheckers = (externalCheckers?: [string, Principal][]): [string, string][] | undefined => {
	if (!externalCheckers) return undefined
	return externalCheckers.map(([name, principal]) => [name, principal.toText()])
}

const buildDistributionConfig = () => {
	// Build multi-category recipients
	const multiCategoryRecipients = buildMultiCategoryRecipients()

	// Calculate total amount from all categories
	const totalAmount = categories.value.reduce((sum, category) => {
		if (category.mode === 'predefined') {
			// For predefined mode: sum from recipients text
			const recipients = parseCategoryRecipients(category.recipientsText)
			return sum + recipients.reduce((catSum, r) => catSum + r.amount, 0)
		} else {
			// For open mode: max recipients * amount per recipient
			if (category.maxRecipients && category.amountPerRecipient) {
				return sum + (category.maxRecipients * category.amountPerRecipient)
			}
			return sum
		}
	}, 0)

	// Convert form data to backend format
	const config = {
		title: formData.title,
		description: formData.description,
		isPublic: formData.isPublic,
		campaignType: formData.campaignType || 'Airdrop',
		tokenInfo: {
			canisterId: formData.tokenInfo.canisterId!,
			symbol: formData.tokenInfo.symbol!,
			name: formData.tokenInfo.name!,
			decimals: formData.tokenInfo.decimals!
		},
		totalAmount: totalAmount,
		eligibilityType: formData.eligibilityType,
		// Multi-category recipients
		multiCategoryRecipients: multiCategoryRecipients,
		recipients: [], // Empty for multi-category mode
		vestingSchedule: { Instant: null }, // Ignored in multi-category mode
		// Include token/NFT holder configurations
		tokenHolderConfig: formData.tokenHolderConfig,
		nftHolderConfig: formData.nftHolderConfig,
		ictoPassportScore: formData.ictoPassportScore,
		recipientMode: formData.recipientMode,
		maxRecipients: formData.maxRecipients,
		registrationPeriod: formData.registrationPeriod,
		distributionStart: formData.distributionStart,
		distributionEnd: formData.distributionEnd,
		feeStructure: buildFeeStructure(),
		allowCancel: formData.allowCancel,
		allowModification: formData.allowModification,
		owner: authStore?.principal || '',
		governance: formData.governance || null,
		externalCheckers: formData.externalCheckers?.length ? formData.externalCheckers : null,
	}

	console.log('Multi-category distribution config being sent:', config)
	return config
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
		ictoPassportScore: 0
	})
	currentStep.value = 0
}

const viewDistribution = () => {
	showSuccessModal.value = false
	router.push(`/distribution/${deploymentResult.value?.distributionCanisterId}`)
}

// Initialize dates
const initializeDates = () => {
	const now = new Date()
	
	// Add 5 minutes buffer for immediate distributions
	const immediateStart = new Date(now.getTime() + 5 * 60 * 1000)
	
	const tomorrow = new Date()
	tomorrow.setDate(tomorrow.getDate() + 1)
	tomorrow.setHours(12, 0, 0, 0)

	const nextWeek = new Date(tomorrow)
	nextWeek.setDate(nextWeek.getDate() + 7)

	// For scheduled distributions, use tomorrow by default
	distributionStartDate.value = tomorrow.toISOString().slice(0, 16)
	registrationStartDate.value = now.toISOString().slice(0, 16)
	registrationEndDate.value = tomorrow.toISOString().slice(0, 16)
	
	// Set immediate start time for immediate distributions
	formData.distributionStart = immediateStart
}

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

	const isConfirmed = await useSwal.fire({
		title: 'Are you sure?',
		text: 'You are about to deploy a distribution. This action is irreversible.',
		icon: 'warning',
		showCancelButton: true,
		confirmButtonText: 'Yes, deploy it!'
	})
	if (!isConfirmed.isConfirmed) return
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
						console.log('Backend request:', backendRequest);
						// return;
						// Convert eligibility type from Motoko to Backend format
						const convertedRequest = {
							...backendRequest,
							eligibilityType: convertEligibilityType(backendRequest.eligibilityType),
							recipientMode: convertRecipientMode(backendRequest.recipientMode),
							externalCheckers: convertExternalCheckers(backendRequest.externalCheckers)
						}
						const deployDistributionResult = await backendService.deployDistribution(convertedRequest)

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

// Auto-set eligibility to Whitelist for Lock campaigns
watch(() => formData.campaignType, (newType) => {
	if (newType === 'Lock') {
		// Auto-set to Whitelist for Lock campaigns
		formData.eligibilityType = { Whitelist: null }
	}
})


// Watch for distribution timing config changes and sync with form data
watch(distributionTimingConfig, (newConfig) => {
	if (newConfig.mode === 'immediate') {
		// Start immediately with 5 minutes buffer
		const now = new Date()
		const immediateStart = new Date(now.getTime() + 5 * 60 * 1000) // 5 minutes buffer
		formData.distributionStart = immediateStart
		formData.distributionEnd = newConfig.endTime ? new Date(newConfig.endTime) : undefined
	} else if (newConfig.mode === 'scheduled' && newConfig.startTime) {
		// Scheduled start
		formData.distributionStart = new Date(newConfig.startTime)
		formData.distributionEnd = newConfig.endTime ? new Date(newConfig.endTime) : undefined
	}
}, { deep: true })

// Watch for registration timing config changes and sync with form data
watch(registrationTimingConfig, (newConfig) => {
	if (formData.hasRegistrationPeriod) {
		if (newConfig.startTime && newConfig.endTime) {
			formData.registrationPeriod = {
				startTime: new Date(newConfig.startTime),
				endTime: new Date(newConfig.endTime),
				maxParticipants: newConfig.maxParticipants || undefined
			}
		}
	}
}, { deep: true })


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