<template>
  <div class="space-y-6">
    <div>
      <label class="block text-sm font-medium text-gray-900 dark:text-white mb-3">
        Sale Visibility & Access Control
      </label>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Choose who can discover and participate in your launchpad sale
      </p>

      <!-- Visibility Options -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <!-- Public Sale -->
        <button
          @click="selectVisibility('Public')"
          :class="[
            'relative p-6 rounded-xl border-2 transition-all',
            visibility === 'Public'
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
          ]"
          class="text-left group"
        >
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-lg bg-blue-100 dark:bg-blue-900/30 flex items-center justify-center">
                <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <h3 class="text-base font-semibold text-gray-900 dark:text-white">
                Public Sale
              </h3>
            </div>
            <div v-if="visibility === 'Public'" class="w-6 h-6 rounded-full bg-blue-500 flex items-center justify-center">
              <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Open to everyone. Discoverable on public listings.
          </p>

          <div class="space-y-2">
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Public discovery
            </div>
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Anyone can participate
            </div>
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Optional whitelist
            </div>
          </div>
        </button>

        <!-- Whitelist Only -->
        <button
          @click="selectVisibility('WhitelistOnly')"
          :class="[
            'relative p-6 rounded-xl border-2 transition-all',
            visibility === 'WhitelistOnly'
              ? 'border-purple-500 bg-purple-50 dark:bg-purple-900/20'
              : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
          ]"
          class="text-left group"
        >
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-lg bg-purple-100 dark:bg-purple-900/30 flex items-center justify-center">
                <svg class="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 class="text-base font-semibold text-gray-900 dark:text-white">
                Whitelist Only
              </h3>
            </div>
            <div v-if="visibility === 'WhitelistOnly'" class="w-6 h-6 rounded-full bg-purple-500 flex items-center justify-center">
              <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Public discovery but whitelist required to participate.
          </p>

          <div class="space-y-2">
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Public discovery
            </div>
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-orange-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
              </svg>
              Whitelist required
            </div>
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
              Registration allowed
            </div>
          </div>
        </button>

        <!-- Private Sale -->
        <button
          @click="selectVisibility('Private')"
          :class="[
            'relative p-6 rounded-xl border-2 transition-all',
            visibility === 'Private'
              ? 'border-red-500 bg-red-50 dark:bg-red-900/20'
              : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
          ]"
          class="text-left group"
        >
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-3">
              <div class="w-12 h-12 rounded-lg bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
                <svg class="w-6 h-6 text-red-600 dark:text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
              </div>
              <h3 class="text-base font-semibold text-gray-900 dark:text-white">
                Private Sale
              </h3>
            </div>
            <div v-if="visibility === 'Private'" class="w-6 h-6 rounded-full bg-red-500 flex items-center justify-center">
              <svg class="w-4 h-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7" />
              </svg>
            </div>
          </div>
          <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
            Invite-only. Not discoverable. Admin approval required.
          </p>

          <div class="space-y-2">
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M13.477 14.89A6 6 0 015.11 6.524l8.367 8.368zm1.414-1.414L6.524 5.11a6 6 0 018.367 8.367zM18 10a8 8 0 11-16 0 8 8 0 0116 0z" clip-rule="evenodd" />
              </svg>
              No public discovery
            </div>
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-orange-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clip-rule="evenodd" />
              </svg>
              Invite-only whitelist
            </div>
            <div class="flex items-center text-xs text-gray-600 dark:text-gray-400">
              <svg class="w-4 h-4 mr-2 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 8a6 6 0 01-7.743 5.743L10 14l-1 1-1 1H6v2H2v-4l4.257-4.257A6 6 0 1118 8zm-6-4a1 1 0 100 2 2 2 0 012 2 1 1 0 102 0 4 4 0 00-4-4z" clip-rule="evenodd" />
              </svg>
              Admin approval only
            </div>
          </div>
        </button>
      </div>
    </div>

    <!-- Configuration Based on Selection -->
    <div v-if="visibility" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-6 border border-gray-200 dark:border-gray-700">
      <h4 class="text-sm font-semibold text-gray-900 dark:text-white mb-4">
        Configuration for {{ visibility }} Sale
      </h4>

  
      <!-- Public Sale Config -->
      <div v-if="visibility === 'Public'" class="space-y-4">
        <div class="flex items-center justify-between">
          <div>
            <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
              Enable Optional Whitelist
            </label>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              Allow whitelisted users early access before public sale
            </p>
          </div>
          <Switch
            v-model="formData.saleParams.requiresWhitelist"
            :class="formData.saleParams.requiresWhitelist ? 'bg-blue-600' : 'bg-gray-200 dark:bg-gray-700'"
            class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
          >
            <span
              :class="formData.saleParams.requiresWhitelist ? 'translate-x-6' : 'translate-x-1'"
              class="inline-block h-4 w-4 transform rounded-full bg-white transition"
            />
          </Switch>
        </div>
      </div>

      <!-- Whitelist Only Config -->
      <div v-else-if="visibility === 'WhitelistOnly'" class="space-y-4">
        <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4 border border-purple-200 dark:border-purple-800">
          <div class="flex items-start">
            <svg class="w-5 h-5 text-purple-500 mt-0.5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
            </svg>
            <div class="flex-1">
              <p class="text-sm font-medium text-purple-900 dark:text-purple-100">Whitelist Required</p>
              <p class="text-sm text-purple-700 dark:text-purple-300 mt-1">
                Only whitelisted addresses can participate. Sale is discoverable publicly.
              </p>
            </div>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Whitelist Registration Mode
          </label>
          <Select
            v-model="formData.saleParams.whitelistMode"
            :options="[
              { value: 'OpenRegistration', label: 'Open Registration (Users can self-register with auto-approval)' },
              { value: 'Closed', label: 'Closed (Admin approval required)' }
            ]"
          />
        </div>

        <!-- Open Registration Details -->
        <div v-if="formData.saleParams.whitelistMode === 'OpenRegistration'" class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 border border-blue-200 dark:border-blue-800">
          <h6 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-3">📋 Open Registration Flow</h6>

          <div class="space-y-3">
            <div class="flex items-start">
              <div class="w-2 h-2 rounded-full bg-blue-500 mt-1 mr-3"></div>
              <div>
                <p class="text-sm font-medium text-blue-800 dark:text-blue-200">User Self-Registration</p>
                <p class="text-xs text-blue-600 dark:text-blue-400">
                  Users can register themselves and get auto-approved based on criteria
                </p>
              </div>
            </div>

            <div class="flex items-start">
              <div class="w-2 h-2 rounded-full bg-green-500 mt-1 mr-3"></div>
              <div>
                <p class="text-sm font-medium text-green-800 dark:text-green-200">Admin Pre-Defined Whitelist</p>
                <p class="text-xs text-green-600 dark:text-green-400">
                  Admin can pre-add trusted addresses that auto-qualify
                </p>
              </div>
            </div>

            <div class="flex items-start">
              <div class="w-2 h-2 rounded-full bg-yellow-500 mt-1 mr-3"></div>
              <div>
                <p class="text-sm font-medium text-yellow-800 dark:text-yellow-200">Auto-Approval Criteria</p>
                <p class="text-xs text-yellow-600 dark:text-yellow-400">
                  Based on ICTO Passport score, registration order, or other rules
                </p>
              </div>
            </div>
          </div>

          <!-- Detailed Flow Implementation -->
          <div class="mt-4 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 dark:from-blue-900/20 dark:to-indigo-900/20 rounded-lg border border-blue-200 dark:border-blue-700">
            <p class="text-sm font-semibold text-blue-900 dark:text-blue-100 mb-3 flex items-center">
              <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9 2a1 1 0 000 2h2a1 1 0 100-2H9z" />
                <path fill-rule="evenodd" d="M4 5a2 2 0 012-2 1 1 0 000 2H6a2 2 0 00-2 2v6a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-1a1 1 0 100-2h1a4 4 0 014 4v6a4 4 0 01-4 4H6a4 4 0 01-4-4V7a4 4 0 014-4z" clip-rule="evenodd" />
              </svg>
              Open Registration Flow Details
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- User Registration Process -->
              <div class="bg-white dark:bg-gray-800 rounded-lg p-3 border border-blue-100 dark:border-blue-800">
                <p class="text-xs font-semibold text-blue-700 dark:text-blue-300 mb-2">👤 User Self-Registration</p>
                <ul class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                  <li>• Users connect wallet and register during whitelist period</li>
                  <li>• Automatic ICTO Passport verification (if required)</li>
                  <li>• Real-time approval status updates</li>
                  <li>• Email/notification on approval</li>
                </ul>
              </div>

              <!-- Admin Pre-Defined Whitelist -->
              <div class="bg-white dark:bg-gray-800 rounded-lg p-3 border border-green-100 dark:border-green-800">
                <p class="text-xs font-semibold text-green-700 dark:text-green-300 mb-2">⭐ Admin Pre-Defined Whitelist</p>
                <ul class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                  <li>• Pre-add trusted investors/partners</li>
                  <li>• Immediate whitelist approval</li>
                  <li>• Priority access during sale</li>
                  <li>• Bypass automatic criteria</li>
                </ul>
              </div>

              <!-- Auto-Approval Rules -->
              <div class="bg-white dark:bg-gray-800 rounded-lg p-3 border border-yellow-100 dark:border-yellow-800">
                <p class="text-xs font-semibold text-yellow-700 dark:text-yellow-300 mb-2">⚡ Auto-Approval Criteria</p>
                <ul class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                  <li>• ICTO Passport Score ≥ 80 (configurable)</li>
                  <li>• First-come-first-served up to limit</li>
                  <li>• Anti-sybil attack detection</li>
                  <li>• Geographic compliance check</li>
                </ul>
              </div>

              <!-- Manual Override -->
              <div class="bg-white dark:bg-gray-800 rounded-lg p-3 border border-purple-100 dark:border-purple-800">
                <p class="text-xs font-semibold text-purple-700 dark:text-purple-300 mb-2">🔧 Admin Manual Override</p>
                <ul class="text-xs text-gray-600 dark:text-gray-400 space-y-1">
                  <li>• Approve/reject pending applications</li>
                  <li>• Handle exceptional cases</li>
                  <li>• Set custom allocation limits</li>
                  <li>• Batch operations support</li>
                </ul>
              </div>
            </div>

            <!-- Flow Timeline -->
            <div class="mt-4 p-3 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-600">
              <p class="text-xs font-semibold text-gray-700 dark:text-gray-300 mb-2">📅 Registration Timeline</p>
              <div class="space-y-2 text-xs text-gray-600 dark:text-gray-400">
                <div class="flex items-start">
                  <span class="font-medium text-blue-600 dark:text-blue-400 mr-2">T₀:</span>
                  <span>Whitelist period starts → Registration opens</span>
                </div>
                <div class="flex items-start">
                  <span class="font-medium text-green-600 dark:text-green-400 mr-2">T₀+:</span>
                  <span>Admin pre-defined addresses immediately approved</span>
                </div>
                <div class="flex items-start">
                  <span class="font-medium text-yellow-600 dark:text-yellow-400 mr-2">T₀→T₁:</span>
                  <span>User registrations + Auto-approvals based on criteria</span>
                </div>
                <div class="flex items-start">
                  <span class="font-medium text-purple-600 dark:text-purple-400 mr-2">T₁:</span>
                  <span>Whitelist period ends → Final review period</span>
                </div>
                <div class="flex items-start">
                  <span class="font-medium text-gray-600 dark:text-gray-400 mr-2">T₂:</span>
                  <span>Sale starts for approved participants</span>
                </div>
              </div>
            </div>

            <!-- Configuration Notes -->
            <div class="mt-3 p-2 bg-blue-100 dark:bg-blue-900/30 rounded border border-blue-200 dark:border-blue-700">
              <p class="text-xs text-blue-800 dark:text-blue-200">
                <strong>💡 Admin Tip:</strong> You can pre-define up to 100 addresses that bypass auto-approval criteria. Set your ICTO Passport score requirements and registration limits in the Trust & Verification section above.
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Private Sale Config -->
      <div v-else-if="visibility === 'Private'" class="space-y-4">
        <div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-4 border border-red-200 dark:border-red-800">
          <div class="flex items-start">
            <svg class="w-5 h-5 text-red-500 mt-0.5 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <div class="flex-1">
              <p class="text-sm font-medium text-red-900 dark:text-red-100">Private Sale Requirements</p>
              <p class="text-sm text-red-700 dark:text-red-300 mt-1">
                <strong>Forced configurations:</strong> Whitelist required, Closed mode, Not publicly listed. Ideal for strategic investors and VCs.
              </p>
            </div>
          </div>
        </div>

        <div class="space-y-3">
          <div class="flex items-center justify-between p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Whitelist Required</span>
            <span class="px-2 py-1 text-xs font-semibold text-gray-800 dark:text-gray-200 bg-gray-200 dark:bg-gray-600 rounded">
              ✅ Forced ON
            </span>
          </div>

          <div class="flex items-center justify-between p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Whitelist Mode</span>
            <span class="px-2 py-1 text-xs font-semibold text-gray-800 dark:text-gray-200 bg-gray-200 dark:bg-gray-600 rounded">
              🔒 Closed (Admin Approval)
            </span>
          </div>

          <div class="flex items-center justify-between p-3 bg-gray-100 dark:bg-gray-700 rounded-lg">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">Public Discovery</span>
            <span class="px-2 py-1 text-xs font-semibold text-gray-800 dark:text-gray-200 bg-gray-200 dark:bg-gray-600 rounded">
              ❌ Disabled
            </span>
          </div>

          <div class="flex items-center justify-between p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
            <div class="flex items-center">
              <svg class="w-5 h-5 text-yellow-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
              </svg>
              <span class="text-sm font-medium text-yellow-800 dark:text-yellow-200">KYC Recommended</span>
            </div>
            <Switch
              v-model="formData.saleParams.requiresKYC"
              :class="formData.saleParams.requiresKYC ? 'bg-yellow-600' : 'bg-gray-200 dark:bg-gray-700'"
              class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-yellow-500 focus:ring-offset-2"
            >
              <span
                :class="formData.saleParams.requiresKYC ? 'translate-x-6' : 'translate-x-1'"
                class="inline-block h-4 w-4 transform rounded-full bg-white transition"
              />
            </Switch>
          </div>
        </div>
      </div>

      <!-- Whitelist Import Section -->
      <WhitelistImport />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { Switch } from '@headlessui/vue'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'
import WhitelistImport from './WhitelistImport.vue'

const { formData } = useLaunchpadForm()

const visibility = computed({
  get: () => formData.value.saleParams.visibility,
  set: (value: 'Public' | 'WhitelistOnly' | 'Private') => {
    formData.value.saleParams.visibility = value
  }
})

const selectVisibility = (value: 'Public' | 'WhitelistOnly' | 'Private') => {
  visibility.value = value

  // Map frontend visibility → backend saleType + whitelist config
  if (value === 'Public') {
    // Public: Use FairLaunch sale type, optional whitelist, open registration
    formData.value.saleParams.saleType = 'FairLaunch'
    formData.value.saleParams.requiresWhitelist = false
    formData.value.saleParams.whitelistMode = 'OpenRegistration'
  } else if (value === 'WhitelistOnly') {
    // Whitelist Only: Use IDO sale type, required whitelist, can choose mode
    formData.value.saleParams.saleType = 'IDO'
    formData.value.saleParams.requiresWhitelist = true
  } else if (value === 'Private') {
    // Private: Use PrivateSale sale type, forced whitelist, closed mode
    formData.value.saleParams.saleType = 'PrivateSale'
    formData.value.saleParams.requiresWhitelist = true
    formData.value.saleParams.whitelistMode = 'Closed'
  }
}
</script>
