<template>
  <div class="space-y-6">
    <h2 class="text-xl font-semibold text-gray-900 dark:text-white mb-6">Token & Sale Configuration</h2>
    <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
      Configure your token details and sale parameters.
    </p>

    <!-- Token Configuration Section -->
    <div class="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-green-900 dark:text-green-100 mb-4">Token Configuration</h3>
      <p class="text-sm text-green-700 dark:text-green-300 mb-6">Configure your token details for deployment on Internet Computer</p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Token Name -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Token Name* <HelpTooltip>The full name of your token (e.g., "Awesome Project Token")</HelpTooltip>
          </label>
          <input
            v-model="localFormData.saleToken.name"
            type="text"
            placeholder="My Awesome Token"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          />
        </div>

        <!-- Token Symbol -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Token Symbol* <HelpTooltip>Short ticker symbol for your token (e.g., "APT")</HelpTooltip>
          </label>
          <input
            v-model="localFormData.saleToken.symbol"
            type="text"
            placeholder="TOKEN"
            maxlength="10"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700 uppercase"
            required
          />
        </div>

        <!-- Token Decimals -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Token Decimals* <HelpTooltip>Number of decimal places for your token (typically 8 for IC ecosystem)</HelpTooltip>
          </label>
          <Select
            v-model="localFormData.saleToken.decimals"
            :options="TOKEN_DECIMAL_OPTIONS"
            placeholder="Select decimals"
            required
            size="lg"
          />
        </div>

        <!-- Total Supply -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Total Supply* <HelpTooltip>Maximum number of tokens that will ever exist</HelpTooltip>
          </label>
          <money3
            v-bind="money3Options"
            v-model="localFormData.saleToken.totalSupply"
            step="1"
            min="1"
            placeholder="100000000"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          />
        </div>

        <!-- Transfer Fee -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Transfer Fee <HelpTooltip>Fee charged for each token transfer (in smallest token unit)</HelpTooltip>
          </label>
          <div class="relative">
            <money3
              v-bind="money3Options"
              v-model="localFormData.saleToken.transferFee"
              step="1"
              min="0"
              placeholder="10000"
              class="w-full px-3 py-2 pr-20 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
            <span class="absolute right-3 top-2.5 text-xs text-gray-500">e{{ localFormData.saleToken.decimals || 8 }}</span>
          </div>
        </div>

        <!-- Token Logo -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Token Logo <HelpTooltip>Upload a logo for your token. Recommended size: 200x200px</HelpTooltip>
          </label>
          <div class="flex items-center space-x-4">
            <input
              ref="tokenLogoInput"
              type="file"
              accept="image/*"
              @change="handleTokenLogoUpload"
              class="hidden"
            />
            <button
              @click="triggerTokenLogoInput"
              type="button"
              class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
            >
              <UploadIcon class="h-4 w-4 mr-2" />
              {{ tokenLogoPreview ? 'Change Logo' : 'Upload Logo' }}
            </button>

            <!-- Logo Preview -->
            <div v-if="tokenLogoPreview" class="flex items-center space-x-3">
              <div class="relative">
                <img :src="tokenLogoPreview" alt="Token Logo" class="h-12 w-12 rounded-full object-cover border-2 border-green-300" />
                <button
                  @click="removeTokenLogo"
                  type="button"
                  class="absolute -top-1 -right-1 h-5 w-5 bg-red-500 text-white rounded-full flex items-center justify-center text-xs hover:bg-red-600 transition-colors"
                >
                  ×
                </button>
              </div>
              <div class="text-xs text-green-600 dark:text-green-400">
                <div class="font-medium">✓ Loaded</div>
                <div class="text-gray-500">{{ localFormData.saleToken.name || 'Token' }} logo ready</div>
              </div>
            </div>

            <!-- Error Message -->
            <div v-if="tokenLogoError" class="text-xs text-red-500 bg-red-50 dark:bg-red-900/20 px-2 py-1 rounded">
              {{ tokenLogoError }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Sale Configuration Section -->
    <div class="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-blue-900 dark:text-blue-100 mb-4">Sale Configuration</h3>
      <p class="text-sm text-blue-700 dark:text-blue-300 mb-6">Configure how your token sale will operate</p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Purchase Token -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Purchase Token* <HelpTooltip>The token that participants will use to buy your sale token</HelpTooltip>
          </label>
          <Select
            v-model="localFormData.purchaseToken.canisterId"
            placeholder="Select Purchase Token"
            :options="PURCHASE_TOKEN_OPTIONS.map(token => ({
              value: token.value,
              label: `${token.symbol} - ${token.label}`,
              data: token
            }))"
            @change="handlePurchaseTokenChange"
            required
          />
          <p class="text-xs text-gray-500 mt-1">Token used by participants to purchase your tokens</p>
        </div>

        <!-- Sale Type -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Sale Type* <HelpTooltip>Choose the type of token sale</HelpTooltip>
          </label>
          <Select
            v-model="localFormData.saleParams.saleType"
            placeholder="Select Sale Type"
            :options="SALE_TYPE_OPTIONS"
            required
          />
        </div>

        <!-- Allocation Method -->
        <!-- <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Allocation Method* <HelpTooltip>How tokens will be allocated to participants</HelpTooltip>
          </label>
          <Select
            v-model="localFormData.saleParams.allocationMethod"
            placeholder="Select Method"
            :options="ALLOCATION_METHOD_OPTIONS"
            required
          />
        </div> -->

        <!-- Total Sale Amount -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Total Sale Amount* <HelpTooltip>Total number of tokens available for sale</HelpTooltip>
          </label>
          <div class="relative">
            <money3
              v-bind="money3Options"
              v-model="localFormData.saleParams.totalSaleAmount"
              step="1"
              min="1"
              placeholder="1000000"
              class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ saleTokenSymbol }}</span>
          </div>
        </div>

        <!-- Max Participants -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Max Participants <HelpTooltip>Maximum number of unique wallets that can participate</HelpTooltip>
          </label>
          <money3
            v-bind="money3Options"
            v-model="localFormData.saleParams.maxParticipants"
            type="number"
            min="1"
            placeholder="1000"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          />
        </div>

        <!-- Soft Cap -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Soft Cap* <HelpTooltip>Minimum amount of funds that must be raised</HelpTooltip>
          </label>
          <div class="relative">
            <money3
              v-bind="money3Options"
              v-model="localFormData.saleParams.softCap"
              type="number"
              step="0.01"
              min="0"
              placeholder="10000"
              class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
          </div>
        </div>

        <!-- Hard Cap -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Hard Cap* <HelpTooltip>Maximum amount of funds that can be raised</HelpTooltip>
          </label>
          <div class="relative">
            <money3
              v-bind="money3Options"
              v-model="localFormData.saleParams.hardCap"
              type="number"
              step="0.01"
              min="0"
              placeholder="50000"
              class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
          </div>
        </div>

        <!-- Token Price Range (Dynamic) -->
        <div class="md:col-span-2 bg-gradient-to-r from-green-50 to-red-50 dark:from-green-900/20 dark:to-red-900/20 rounded-lg p-4 border border-gray-200 dark:border-gray-600">
          <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-3">🎯 Token Price Range (Dynamic)</h4>
          <p class="text-xs text-gray-600 dark:text-gray-400 mb-4">Based on campaign participation levels and your allocation settings</p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div class="relative">
              <div class="w-full px-3 py-2 pr-16 border rounded-lg bg-green-50 text-green-900 dark:text-green-100 font-medium">
                {{ tokenPriceAtSoftCap || '0' }}
              </div>
              <span class="absolute right-3 top-2.5 text-sm text-green-600">{{ purchaseTokenSymbol }}</span>
              <p class="text-xs mt-1">Min Price (at Soft Cap)</p>
            </div>
            <div class="relative">
              <div class="w-full px-3 py-2 pr-16 border rounded-lg dark:bg-red-900/20 text-red-900 dark:text-red-100 font-medium">
                {{ tokenPriceAtHardCap || '0' }}
              </div>
              <span class="absolute right-3 top-2.5 text-sm text-red-600">{{ purchaseTokenSymbol }}</span>
              <p class="text-xs mt-1">Max Price (at Hard Cap)</p>
            </div>
          </div>
          <div class="mt-3 p-3 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-lg">
            <p class="text-xs text-blue-700 dark:text-blue-300">
              <strong>Dynamic Pricing:</strong> Final token price = Total Committed Amount ÷ {{ formatNumber(localFormData.saleParams.totalSaleAmount || 0) }} {{ saleTokenSymbol }}
            </p>
            <p class="text-xs text-blue-600 dark:text-blue-400 mt-1">
              If campaign doesn't reach soft cap ({{ formatNumber(localFormData.saleParams.softCap || 0) }} {{ purchaseTokenSymbol }}), all funds will be refunded.
            </p>
          </div>
        </div>

        <!-- Min Contribution -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Min Contribution* <HelpTooltip>Minimum amount each participant must invest</HelpTooltip>
          </label>
          <div class="relative">
            <input
              v-model="localFormData.saleParams.minContribution"
              type="number"
              step="0.01"
              min="0"
              placeholder="10"
              class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
              required
            />
            <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
          </div>
        </div>

        <!-- Max Contribution -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Max Contribution <HelpTooltip>Maximum amount each participant can invest</HelpTooltip>
          </label>
          <div class="relative">
            <input
              v-model="localFormData.saleParams.maxContribution"
              type="number"
              step="0.01"
              min="0"
              placeholder="1000"
              class="w-full px-3 py-2 pr-16 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            />
            <span class="absolute right-3 top-2.5 text-sm text-gray-500">{{ purchaseTokenSymbol }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Sale Visibility & Verification -->
    <div class="bg-gradient-to-br from-amber-50 to-orange-50 dark:from-amber-900/20 dark:to-orange-900/20 rounded-xl p-6 shadow-sm border border-amber-200 dark:border-amber-800">
      <SaleVisibilityConfig v-model="localFormData" />
      <ICTOPassportScoreConfig v-model="localFormData" />
    </div>

    <!-- Timeline Configuration -->
    <div class="bg-purple-50 dark:bg-purple-900/20 border border-purple-200 dark:border-purple-800 rounded-lg p-6 mb-6">
      <h3 class="text-lg font-semibold text-purple-900 dark:text-purple-100 mb-4">📅 Sale Timeline</h3>
      <p class="text-sm text-purple-600 dark:text-purple-400 mb-6">Configure the timing for your token sale phases.</p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Sale Start -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Sale Start* <HelpTooltip>When the token sale officially begins</HelpTooltip>
          </label>
          <input
            v-model="localFormData.timeline.saleStart"
            type="datetime-local"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          />
        </div>

        <!-- Sale End -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Sale End* <HelpTooltip>When the token sale officially ends</HelpTooltip>
          </label>
          <input
            v-model="localFormData.timeline.saleEnd"
            type="datetime-local"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          />
        </div>

        <!-- Claim Start -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Claim Start* <HelpTooltip>When participants can start claiming their purchased tokens</HelpTooltip>
          </label>
          <input
            v-model="localFormData.timeline.claimStart"
            type="datetime-local"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
            required
          />
        </div>

        <!-- Listing Time -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Listing Time <HelpTooltip>When the token will be listed on DEX platforms</HelpTooltip>
          </label>
          <input
            v-model="localFormData.timeline.listingTime"
            type="datetime-local"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-transparent bg-white dark:bg-gray-700"
          />
        </div>
      </div>
    </div>

    <!-- Validation Errors -->
    <div v-if="validationErrors.length > 0 || timelineValidation.length > 0" class="mt-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
      <div class="flex items-start space-x-2">
        <AlertTriangleIcon class="h-5 w-5 text-red-600 dark:text-red-400 mt-0.5 flex-shrink-0" />
        <div class="flex-1">
          <h4 class="text-sm font-medium text-red-800 dark:text-red-200 mb-2">Please complete these required fields:</h4>
          <ul class="text-sm text-red-700 dark:text-red-300 space-y-1">
            <li v-for="error in [...validationErrors, ...timelineValidation]" :key="error" class="flex items-start">
              <span class="w-1.5 h-1.5 bg-red-400 rounded-full mr-2 mt-2 flex-shrink-0"></span>
              <span>{{ error }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { AlertTriangleIcon, UploadIcon } from 'lucide-vue-next'

// Component imports
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import SaleVisibilityConfig from './SaleVisibilityConfig.vue'
import ICTOPassportScoreConfig from './ICTOPassportScoreConfig.vue'

// Composables
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Use composable for centralized state - no more props/emit!
const { formData: localFormData, step1ValidationErrors: validationErrors, timelineValidation } = useLaunchpadForm()

// Local state
const tokenLogoInput = ref<HTMLInputElement | null>(null)
const tokenLogoPreview = ref('')
const tokenLogoError = ref('')

// Constants
const money3Options = {
  masked: false,
  prefix: '',
  suffix: '',
  thousands: ',',
  decimal: '.',
  precision: 0,
  disableNegative: false,
  disabled: false,
  min: null,
  max: null,
  allowBlank: false,
  minimumNumberOfCharacters: 0,
  shouldRound: true,
  focusOnRight: false,
}

const TOKEN_DECIMAL_OPTIONS = [
  { value: 6, label: '6 decimals' },
  { value: 8, label: '8 decimals (recommended)' },
  { value: 12, label: '12 decimals' },
  { value: 18, label: '18 decimals' }
]

const SALE_TYPE_OPTIONS = [
  { value: 'IDO', label: 'IDO (Initial DEX Offering)' },
  { value: 'PrivateSale', label: 'Private Sale' },
  { value: 'FairLaunch', label: 'Fair Launch' },
  { value: 'Auction', label: 'Auction' },
  { value: 'Lottery', label: 'Lottery' }
]

// ALLOCATION_METHOD_OPTIONS - Commented out as unused
// const ALLOCATION_METHOD_OPTIONS = [
//   { value: 'FirstComeFirstServe', label: 'First Come First Serve' },
//   { value: 'ProRata', label: 'Pro Rata' },
//   { value: 'Weighted', label: 'Weighted' },
//   { value: 'Lottery', label: 'Lottery' }
// ]

const PURCHASE_TOKEN_OPTIONS = [
  {
    value: 'ryjl3-tyaaa-aaaaa-aaaba-cai',
    label: 'ICP (Internet Computer)',
    symbol: 'ICP',
    decimals: 8,
    fee: 10000,
    logo: 'https://cryptologos.cc/logos/internet-computer-icp-logo.png'
  },
  {
    value: 'xevnm-gaaaa-aaaar-qafnq-cai',
    label: 'ckUSDT (Chain Key USDT)',
    symbol: 'ckUSDT',
    decimals: 6,
    fee: 2000000,
    logo: 'https://cryptologos.cc/logos/tether-usdt-logo.png'
  },
  {
    value: 'mxzaz-hqaaa-aaaar-qaada-cai',
    label: 'ckBTC (Chain Key Bitcoin)',
    symbol: 'ckBTC',
    decimals: 8,
    fee: 10,
    logo: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png'
  },
  {
    value: 'ss2fx-dyaaa-aaaar-qacoq-cai',
    label: 'ckETH (Chain Key Ethereum)',
    symbol: 'ckETH',
    decimals: 18,
    fee: 2000000000000000,
    logo: 'https://cryptologos.cc/logos/ethereum-eth-logo.png'
  }
]

// Computed properties
const saleTokenSymbol = computed(() => localFormData.value.saleToken.symbol || 'TOKEN')
const purchaseTokenSymbol = computed(() => {
  const selectedToken = PURCHASE_TOKEN_OPTIONS.find(token => token.value === localFormData.value.purchaseToken.canisterId)
  return selectedToken?.symbol || 'ICP'
})

// Dynamic token price range calculations
const tokenPriceAtSoftCap = computed(() => {
  const softCap = Number(localFormData.value.saleParams.softCap) || 0
  const saleAllocation = Number(localFormData.value.saleParams.totalSaleAmount) || 0

  if (softCap > 0 && saleAllocation > 0) {
    const price = softCap / saleAllocation
    return price.toFixed(8).replace(/\.?0+$/, '')
  }
  return '0'
})

const tokenPriceAtHardCap = computed(() => {
  const hardCap = Number(localFormData.value.saleParams.hardCap) || 0
  const saleAllocation = Number(localFormData.value.saleParams.totalSaleAmount) || 0

  if (hardCap > 0 && saleAllocation > 0) {
    const price = hardCap / saleAllocation
    return price.toFixed(8).replace(/\.?0+$/, '')
  }
  return '0'
})

// Methods
const triggerTokenLogoInput = () => {
  tokenLogoInput.value?.click()
}

const handleTokenLogoUpload = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]

  if (!file) return

  // Validate file size (200KB max)
  if (file.size > 200 * 1024) {
    tokenLogoError.value = 'File size must be less than 200KB'
    return
  }

  // Validate file type
  if (!file.type.startsWith('image/')) {
    tokenLogoError.value = 'File must be an image'
    return
  }

  // Create preview
  const reader = new FileReader()
  reader.onload = (e) => {
    tokenLogoPreview.value = e.target?.result as string
    tokenLogoError.value = ''
    localFormData.value.saleToken.logo = tokenLogoPreview.value
  }
  reader.readAsDataURL(file)
}

const removeTokenLogo = () => {
  tokenLogoPreview.value = ''
  tokenLogoError.value = ''
  localFormData.value.saleToken.logo = ''
  if (tokenLogoInput.value) {
    tokenLogoInput.value.value = ''
  }
}

const handlePurchaseTokenChange = () => {
  const selectedToken = PURCHASE_TOKEN_OPTIONS.find(token => token.value === localFormData.value.purchaseToken.canisterId)
  if (selectedToken) {
    localFormData.value.purchaseToken = {
      ...localFormData.value.purchaseToken,
      name: selectedToken.label,
      symbol: selectedToken.symbol,
      decimals: selectedToken.decimals,
      logo: selectedToken.logo
    }
  }
}

const formatNumber = (num: number | string) => {
  return Number(num).toLocaleString()
}
</script>