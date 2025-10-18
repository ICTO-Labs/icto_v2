<template>
  <div class="space-y-6">
    <!-- Enable BlockID Toggle -->
    <div class="flex items-center justify-between p-4 bg-gradient-to-r from-indigo-50 to-purple-50 dark:from-indigo-900/20 dark:to-purple-900/20 rounded-lg border border-indigo-200 dark:border-indigo-800">
      <div class="flex items-start flex-1">
        <div class="w-12 h-12 bg-indigo-100 dark:bg-indigo-900/30 rounded-lg flex items-center justify-center mr-4 flex-shrink-0">
          <svg class="w-6 h-6 text-indigo-600 dark:text-indigo-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
          </svg>
        </div>
        <div class="flex-1">
          <h3 class="text-base font-semibold text-gray-900 dark:text-white mb-1">
            BlockID Verification
          </h3>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-2">
            Third-party identity verification service to prevent bot participation
          </p>
          <a
            href="https://blockid.cc"
            target="_blank"
            class="inline-flex items-center text-sm text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300"
          >
            Learn more about BlockID
            <svg class="w-4 h-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
            </svg>
          </a>
        </div>
      </div>
      <Switch
        v-model="blockIdConfig.enabled"
        :class="blockIdConfig.enabled ? 'bg-indigo-600' : 'bg-gray-200 dark:bg-gray-700'"
        class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 ml-4"
      >
        <span
          :class="blockIdConfig.enabled ? 'translate-x-6' : 'translate-x-1'"
          class="inline-block h-4 w-4 transform rounded-full bg-white transition"
        />
      </Switch>
    </div>

    <!-- BlockID Configuration (when enabled) -->
    <div v-if="blockIdConfig.enabled" class="space-y-6 animate-fadeIn">
      <!-- Minimum Score Requirement -->
      <div class="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
        <label class="block text-sm font-medium text-gray-900 dark:text-white mb-3">
          Minimum BlockID Score Required
        </label>
        <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
          Set the minimum verification score (0-100) that participants must have to join your sale
        </p>

        <!-- Score Slider -->
        <div class="relative pt-1">
          <div class="flex items-center justify-between mb-2">
            <div class="text-left">
              <span class="text-xs font-semibold inline-block text-gray-600 dark:text-gray-400">
                Minimum Score
              </span>
            </div>
            <div class="text-right">
              <span class="text-sm font-semibold inline-block px-3 py-1 rounded-full" :class="[
                blockIdConfig.minScore >= 81 ? 'text-green-800 dark:text-green-200 bg-green-100 dark:bg-green-900/30' :
                blockIdConfig.minScore >= 51 ? 'text-blue-800 dark:text-blue-200 bg-blue-100 dark:bg-blue-900/30' :
                blockIdConfig.minScore >= 21 ? 'text-yellow-800 dark:text-yellow-200 bg-yellow-100 dark:bg-yellow-900/30' :
                'text-red-800 dark:text-red-200 bg-red-100 dark:bg-red-900/30'
              ]">
                {{ blockIdConfig.minScore }}
              </span>
            </div>
          </div>

          <input
            v-model.number="blockIdConfig.minScore"
            type="range"
            min="0"
            max="100"
            step="5"
            class="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer dark:bg-gray-700 slider"
            :style="{
              background: `linear-gradient(to right,
                #ef4444 0%, #ef4444 20%,
                #eab308 20%, #eab308 50%,
                #3b82f6 50%, #3b82f6 80%,
                #22c55e 80%, #22c55e 100%)`
            }"
          >

          <!-- Score Range Labels -->
          <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400 mt-2">
            <span>0</span>
            <span>25</span>
            <span>50</span>
            <span>75</span>
            <span>100</span>
          </div>
        </div>

        <!-- Score Level Explanation -->
        <div class="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="p-4 rounded-lg border" :class="[
            blockIdConfig.minScore >= 81 ? 'border-green-300 bg-green-50 dark:bg-green-900/20 dark:border-green-800' : 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50'
          ]">
            <div class="flex items-center mb-2">
              <div class="w-3 h-3 rounded-full bg-green-500 mr-2"></div>
              <span class="text-sm font-semibold text-gray-900 dark:text-white">81-100: Highly Trusted</span>
            </div>
            <p class="text-xs text-gray-600 dark:text-gray-400">
              Multiple verifications, proven on-chain history, strong reputation
            </p>
          </div>

          <div class="p-4 rounded-lg border" :class="[
            blockIdConfig.minScore >= 51 && blockIdConfig.minScore < 81 ? 'border-blue-300 bg-blue-50 dark:bg-blue-900/20 dark:border-blue-800' : 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50'
          ]">
            <div class="flex items-center mb-2">
              <div class="w-3 h-3 rounded-full bg-blue-500 mr-2"></div>
              <span class="text-sm font-semibold text-gray-900 dark:text-white">51-80: Good Reputation</span>
            </div>
            <p class="text-xs text-gray-600 dark:text-gray-400">
              Some verifications, moderate activity, generally trustworthy
            </p>
          </div>

          <div class="p-4 rounded-lg border" :class="[
            blockIdConfig.minScore >= 21 && blockIdConfig.minScore < 51 ? 'border-yellow-300 bg-yellow-50 dark:bg-yellow-900/20 dark:border-yellow-800' : 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50'
          ]">
            <div class="flex items-center mb-2">
              <div class="w-3 h-3 rounded-full bg-yellow-500 mr-2"></div>
              <span class="text-sm font-semibold text-gray-900 dark:text-white">21-50: Basic Verification</span>
            </div>
            <p class="text-xs text-gray-600 dark:text-gray-400">
              Minimal verification, limited history, acceptable for public sales
            </p>
          </div>

          <div class="p-4 rounded-lg border" :class="[
            blockIdConfig.minScore < 21 ? 'border-red-300 bg-red-50 dark:bg-red-900/20 dark:border-red-800' : 'border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800/50'
          ]">
            <div class="flex items-center mb-2">
              <div class="w-3 h-3 rounded-full bg-red-500 mr-2"></div>
              <span class="text-sm font-semibold text-gray-900 dark:text-white">0-20: Unverified/New</span>
            </div>
            <p class="text-xs text-gray-600 dark:text-gray-400">
              No verification, likely bot or new account, high risk
            </p>
          </div>
        </div>

        <!-- Recommended Scores by Sale Type -->
        <div class="mt-6 bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
          <div class="flex items-start">
            <svg class="w-5 h-5 text-blue-500 mt-0.5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
            </svg>
            <div class="flex-1">
              <p class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">Recommended Scores:</p>
              <ul class="text-sm text-blue-700 dark:text-blue-300 space-y-1">
                <li>• <strong>Public Sales:</strong> 30-50 (basic bot protection)</li>
                <li>• <strong>Whitelist Sales:</strong> 50-70 (moderate verification)</li>
                <li>• <strong>Private Sales:</strong> 70-90 (high trust required)</li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Bypass for Whitelisted Users -->
      <div class="bg-white dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <label class="block text-sm font-medium text-gray-900 dark:text-white mb-1">
              Bypass BlockID for Whitelisted Users
            </label>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Allow manually whitelisted addresses to participate without BlockID verification
            </p>
          </div>
          <Switch
            v-model="blockIdConfig.bypassForWhitelisted"
            :class="blockIdConfig.bypassForWhitelisted ? 'bg-green-600' : 'bg-gray-200 dark:bg-gray-700'"
            class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2 ml-4"
          >
            <span
              :class="blockIdConfig.bypassForWhitelisted ? 'translate-x-6' : 'translate-x-1'"
              class="inline-block h-4 w-4 transform rounded-full bg-white transition"
            />
          </Switch>
        </div>

        <div v-if="blockIdConfig.bypassForWhitelisted" class="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
          <div class="flex items-start">
            <svg class="w-5 h-5 text-yellow-500 mt-0.5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <div class="flex-1">
              <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200 mb-1">Security Note</p>
              <p class="text-sm text-yellow-700 dark:text-yellow-300">
                Whitelisted users can skip BlockID verification. Ensure you trust manually added addresses.
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Verification Methods (Future Feature) -->
      <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700 opacity-60">
        <div class="flex items-start justify-between mb-4">
          <div>
            <label class="block text-sm font-medium text-gray-900 dark:text-white mb-1">
              Required Verification Methods
            </label>
            <p class="text-sm text-gray-600 dark:text-gray-400">
              Choose which verification methods are required (Coming Soon)
            </p>
          </div>
          <span class="px-2 py-1 text-xs font-semibold text-gray-600 dark:text-gray-400 bg-gray-200 dark:bg-gray-700 rounded">
            Coming Soon
          </span>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div class="flex items-center p-3 bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 cursor-not-allowed">
            <input type="checkbox" disabled class="mr-3 opacity-50">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-blue-500 mr-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M23.953 4.57a10 10 0 01-2.825.775 4.958 4.958 0 002.163-2.723c-.951.555-2.005.959-3.127 1.184a4.92 4.92 0 00-8.384 4.482C7.69 8.095 4.067 6.13 1.64 3.162a4.822 4.822 0 00-.666 2.475c0 1.71.87 3.213 2.188 4.096a4.904 4.904 0 01-2.228-.616v.06a4.923 4.923 0 003.946 4.827 4.996 4.996 0 01-2.212.085 4.936 4.936 0 004.604 3.417 9.867 9.867 0 01-6.102 2.105c-.39 0-.779-.023-1.17-.067a13.995 13.995 0 007.557 2.209c9.053 0 13.998-7.496 13.998-13.985 0-.21 0-.42-.015-.63A9.935 9.935 0 0024 4.59z"/>
              </svg>
              <span class="text-sm text-gray-700 dark:text-gray-300">Twitter</span>
            </div>
          </div>

          <div class="flex items-center p-3 bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 cursor-not-allowed">
            <input type="checkbox" disabled class="mr-3 opacity-50">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-indigo-500 mr-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M20.317 4.37a19.791 19.791 0 00-4.885-1.515.074.074 0 00-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 00-5.487 0 12.64 12.64 0 00-.617-1.25.077.077 0 00-.079-.037A19.736 19.736 0 003.677 4.37a.07.07 0 00-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 00.031.057 19.9 19.9 0 005.993 3.03.078.078 0 00.084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 00-.041-.106 13.107 13.107 0 01-1.872-.892.077.077 0 01-.008-.128 10.2 10.2 0 00.372-.292.074.074 0 01.077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 01.078.01c.12.098.246.198.373.292a.077.077 0 01-.006.127 12.299 12.299 0 01-1.873.892.077.077 0 00-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 00.084.028 19.839 19.839 0 006.002-3.03.077.077 0 00.032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 00-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
              </svg>
              <span class="text-sm text-gray-700 dark:text-gray-300">Discord</span>
            </div>
          </div>

          <div class="flex items-center p-3 bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 cursor-not-allowed">
            <input type="checkbox" disabled class="mr-3 opacity-50">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-gray-900 dark:text-gray-100 mr-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
              </svg>
              <span class="text-sm text-gray-700 dark:text-gray-300">GitHub</span>
            </div>
          </div>

          <div class="flex items-center p-3 bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 cursor-not-allowed">
            <input type="checkbox" disabled class="mr-3 opacity-50">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-blue-400 mr-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 0c-6.627 0-12 5.373-12 12s5.373 12 12 12 12-5.373 12-12-5.373-12-12-12zm0 22c-5.514 0-10-4.486-10-10s4.486-10 10-10 10 4.486 10 10-4.486 10-10 10zm-2-15v10l8-5-8-5z"/>
              </svg>
              <span class="text-sm text-gray-700 dark:text-gray-300">On-chain History</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Switch } from '@headlessui/vue'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

const { formData } = useLaunchpadForm()

const blockIdConfig = computed(() => formData.value.saleParams.blockIdConfig || {
  enabled: false,
  minScore: 50,
  providerCanisterId: undefined,
  verificationMethods: [],
  bypassForWhitelisted: true
})
</script>

<style scoped>
.animate-fadeIn {
  animation: fadeIn 0.3s ease-in;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.slider::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #4f46e5;
  cursor: pointer;
  border: 3px solid white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}

.slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: #4f46e5;
  cursor: pointer;
  border: 3px solid white;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
}
</style>
