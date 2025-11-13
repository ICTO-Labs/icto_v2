<template>
  <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden mb-6 border border-gray-200 dark:border-gray-700">
    <!-- Header with gradient/cover -->
    <div class="relative bg-gradient-to-r from-[#d8a735] via-[#eacf6f] to-[#e1b74c] p-6">
      <div class="absolute inset-0 bg-black/10"></div>
      <div class="relative flex items-start justify-between">
        <div class="flex items-center space-x-4">
          <TokenLogo
            :canister-id="details.tokenInfo.canisterId.toString()"
            :symbol="details.tokenInfo.symbol"
            :size="64"
          />
          <div>
            <h1 class="text-2xl font-bold text-white mb-1">
              {{ details.title }}
            </h1>
            <div class="flex items-center space-x-3">
              <span class="text-lg font-semibold text-white/90">{{ details.tokenInfo.symbol }}</span>

              <!-- Unified Status Badge -->
              <DistributionStatusBadge
                :distribution="details"
                :show-sub-status="true"
              />

              <!-- Eligibility Type Label -->
              <Label variant="blue" size="xs" class="inline-flex items-center gap-1">
                <ZapIcon class="w-3 h-3" />
                {{ getVariantKey(details.eligibilityType) }}
              </Label>

              <!-- Campaign Type Label -->
              <div
                :class="[
                  'inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border',
                  getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').bgClass
                ]"
              >
                <div
                  class="w-2 h-2 rounded-full mr-2"
                  :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').className.replace('text-', 'bg-')"
                ></div>
                <span :class="getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').className">
                  {{ getCampaignTypeLabel(getVariantKey(details.campaignType) || 'Airdrop').label }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Progress Bar (ALL 3 types - shows claimed %) -->
    <div class="px-6 py-4 bg-gray-50 dark:bg-gray-900">
      <div class="flex items-center justify-between mb-2">
        <div class="text-xs font-semibold text-[#d8a735]">
          <span class="text-xs">Claims:</span> {{ claimedCount }} / {{ totalParticipants }}
        </div>
        <span class="text-xs font-semibold text-[#d8a735]">{{ claimedPercentage.toFixed(2) }}%</span>
      </div>
      <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 overflow-hidden relative">
        <!-- Progress Fill -->
        <div
          :style="{ width: claimedPercentage + '%' }"
          class="bg-gradient-to-r from-[#b27c10] via-[#d8a735] to-[#e1b74c] h-2 rounded-full transition-all duration-1000 ease-out relative overflow-hidden"
        >
          <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer"></div>
        </div>
      </div>
      <div class="flex items-center justify-between mt-2 text-xs text-gray-600 dark:text-gray-400">
        <div>
          <span class="font-medium">Total Distributed:</span>
          <span class="font-semibold ml-1">
            {{ formatTokenAmount(totalClaimed, details.tokenInfo.decimals) }} {{ details.tokenInfo.symbol }}
          </span>
        </div>
        <div>
          <span class="font-medium">Total Allocated:</span>
          <span class="font-semibold ml-1">
            {{ formatTokenAmount(details.totalAmount, details.tokenInfo.decimals) }} {{ details.tokenInfo.symbol }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import TokenLogo from '@/components/token/TokenLogo.vue'
import Label from '@/components/common/Label.vue'
import DistributionStatusBadge from './DistributionStatusBadge.vue'
import { getCampaignTypeLabel } from '@/utils/lockConfig'
import { getVariantKey } from '@/utils/common'
import { ZapIcon } from 'lucide-vue-next'
import { parseTokenAmount } from '@/utils/token'

interface Props {
  details: any
  stats?: any
}

const props = defineProps<Props>()

// Calculate claimed percentage
const claimedCount = computed(() => {
  if (!props.stats) return 0
  return Number(props.stats.totalClaimants || 0)
})

const totalParticipants = computed(() => {
  if (!props.details?.participants) return 0
  return props.details.participants.length
})

const totalClaimed = computed(() => {
  if (!props.stats) return BigInt(0)
  return props.stats.totalClaimed || BigInt(0)
})

const claimedPercentage = computed(() => {
  const total = Number(props.details?.totalAmount || 0)
  const claimed = Number(totalClaimed.value || 0)

  if (total === 0) return 0
  return (claimed / total) * 100
})

// Format token amount
const formatTokenAmount = (amount: bigint | number, decimals: number): string => {
  const parsedAmount = parseTokenAmount(amount, decimals)
  return new Intl.NumberFormat().format(parsedAmount.toNumber())
}
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
