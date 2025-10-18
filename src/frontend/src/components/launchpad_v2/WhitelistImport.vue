<template>
  <div class="space-y-4">
    <!-- Whitelist Import Section -->
    <div v-if="showWhitelistImport" class="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-4">
      <div class="flex items-center justify-between mb-4">
        <div>
          <h5 class="text-sm font-semibold text-gray-900 dark:text-white">
            📋 Whitelist Management
          </h5>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            Import whitelisted addresses via CSV or manual entry
          </p>
        </div>
        <button
          @click="toggleImportSection"
          class="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
        >
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Import Tabs -->
      <div class="flex space-x-1 mb-4">
        <button
          @click="activeTab = 'csv'"
          :class="[
            'px-3 py-2 text-xs font-medium rounded-t-lg transition-colors',
            activeTab === 'csv'
              ? 'bg-blue-500 text-white'
              : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
          ]"
        >
          📁 CSV Import
        </button>
        <button
          @click="activeTab = 'manual'"
          :class="[
            'px-3 py-2 text-xs font-medium rounded-t-lg transition-colors',
            activeTab === 'manual'
              ? 'bg-blue-500 text-white'
              : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
          ]"
        >
          ✏️ Manual Entry
        </button>
        <button
          @click="activeTab = 'manage'"
          :class="[
            'px-3 py-2 text-xs font-medium rounded-t-lg transition-colors',
            activeTab === 'manage'
              ? 'bg-blue-500 text-white'
              : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
          ]"
        >
          👥 Manage ({{ whitelistCount }})
        </button>
      </div>

      <!-- CSV Import Tab -->
      <div v-if="activeTab === 'csv'" class="space-y-4">
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 border border-blue-200 dark:border-blue-800">
          <h6 class="text-sm font-medium text-blue-900 dark:text-blue-100 mb-2">CSV Format Instructions</h6>
          <p class="text-xs text-blue-700 dark:text-blue-300 mb-3">
            Upload a CSV file with the following columns:
          </p>
          <div class="bg-white dark:bg-gray-800 rounded p-2 text-xs font-mono">
            principal,allocation,tier<br>
            <span class="text-gray-500">
              aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa,1000,1<br>
              bbbbb-bbbbb-bbbbb-bbbbb-bbbbb-bbbbb-bbbbb,500,2
            </span>
          </div>
          <p class="text-xs text-blue-600 dark:text-blue-400 mt-2">
            • <strong>principal:</strong> Wallet address (required)<br>
            • <strong>allocation:</strong> Maximum tokens they can buy (optional)<br>
            • <strong>tier:</strong> Priority tier 1-10 (optional, defaults to 1)
          </p>
        </div>

        <div class="space-y-3">
          <div>
            <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              Upload CSV File
            </label>
            <div class="relative">
              <input
                ref="csvFileInput"
                type="file"
                accept=".csv"
                @change="handleFileUpload"
                class="hidden"
              />
              <button
                @click="$refs.csvFileInput.click()"
                :disabled="isProcessing"
                class="w-full px-4 py-2 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg hover:border-blue-500 dark:hover:border-blue-400 transition-colors disabled:opacity-50"
              >
                <svg v-if="!isProcessing" class="w-5 h-5 mx-auto text-gray-400 mb-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                </svg>
                <span v-if="!isProcessing" class="text-sm text-gray-600 dark:text-gray-400">
                  Click to upload CSV file
                </span>
                <span v-else class="text-sm text-blue-600 dark:text-blue-400">
                  Processing...
                </span>
              </button>
            </div>
          </div>

          <!-- CSV Preview -->
          <div v-if="csvPreview.length > 0" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
            <h6 class="text-sm font-medium text-gray-900 dark:text-white mb-2">
              Preview ({{ csvPreview.length }} entries)
            </h6>
            <div class="overflow-x-auto">
              <table class="w-full text-xs">
                <thead>
                  <tr class="border-b dark:border-gray-700">
                    <th class="text-left py-2 px-2">Principal</th>
                    <th class="text-left py-2 px-2">Allocation</th>
                    <th class="text-left py-2 px-2">Tier</th>
                    <th class="text-left py-2 px-2">Status</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="(entry, index) in csvPreview.slice(0, 5)" :key="index" class="border-b dark:border-gray-700">
                    <td class="py-2 px-2 font-mono text-xs truncate">{{ entry.principal }}</td>
                    <td class="py-2 px-2">{{ entry.allocation || '-' }}</td>
                    <td class="py-2 px-2">{{ entry.tier || 1 }}</td>
                    <td class="py-2 px-2">
                      <span v-if="entry.isValid" class="text-green-600">✓ Valid</span>
                      <span v-else class="text-red-600">✗ {{ entry.error }}</span>
                    </td>
                  </tr>
                </tbody>
              </table>
              <p v-if="csvPreview.length > 5" class="text-xs text-gray-500 mt-2">
                ... and {{ csvPreview.length - 5 }} more entries
              </p>
            </div>
            <button
              @click="importFromCSV"
              :disabled="!hasValidEntries || isProcessing"
              class="mt-3 w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {{ isProcessing ? 'Importing...' : `Import ${validEntriesCount} Valid Entries` }}
            </button>
          </div>
        </div>
      </div>

      <!-- Manual Entry Tab -->
      <div v-if="activeTab === 'manual'" class="space-y-4">
        <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-3 border border-purple-200 dark:border-purple-800">
          <h6 class="text-sm font-medium text-purple-900 dark:text-purple-100 mb-2">Manual Entry</h6>
          <p class="text-xs text-purple-700 dark:text-purple-300">
            Add individual addresses manually. Enter one address per line with optional allocation and tier.
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Whitelist Entries (one per line)
          </label>
          <textarea
            v-model="manualEntryText"
            @input="validateManualEntry"
            placeholder="Enter addresses, one per line:
aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa,1000,1
bbbbb-bbbbb-bbbbb-bbbbb-bbbbb-bbbbb-bbbbb,500"
            class="w-full h-32 px-3 py-2 text-sm border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
          <p class="text-xs text-gray-500 mt-1">
            Format: principal,allocation,tier (allocation and tier are optional)
          </p>
        </div>

        <!-- Manual Entry Preview -->
        <div v-if="manualEntries.length > 0" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
          <h6 class="text-sm font-medium text-gray-900 dark:text-white mb-2">
            Preview ({{ manualEntries.length }} entries)
          </h6>
          <div class="space-y-2">
            <div v-for="(entry, index) in manualEntries.slice(0, 3)" :key="index" class="flex items-center justify-between text-xs p-2 bg-white dark:bg-gray-700 rounded">
              <div class="flex-1">
                <span class="font-mono">{{ entry.principal }}</span>
                <span v-if="entry.allocation" class="ml-2 text-blue-600">({{ entry.allocation }} tokens)</span>
                <span v-if="entry.tier && entry.tier > 1" class="ml-1 px-1 py-0.5 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded text-xs">T{{ entry.tier }}</span>
              </div>
              <span v-if="entry.isValid" class="text-green-600">✓</span>
              <span v-else class="text-red-600">✗ {{ entry.error }}</span>
            </div>
            <p v-if="manualEntries.length > 3" class="text-xs text-gray-500">
              ... and {{ manualEntries.length - 3 }} more entries
            </p>
          </div>
          <button
            @click="importFromManual"
            :disabled="!hasValidManualEntries || isProcessing"
            class="mt-3 w-full px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ isProcessing ? 'Importing...' : `Import ${validManualEntriesCount} Valid Entries` }}
          </button>
        </div>
      </div>

      <!-- Manage Tab -->
      <div v-if="activeTab === 'manage'" class="space-y-4">
        <div class="flex items-center justify-between mb-3">
          <h6 class="text-sm font-medium text-gray-900 dark:text-white">
            Current Whitelist ({{ whitelistCount }} entries)
          </h6>
          <div class="flex space-x-2">
            <button
              @click="exportWhitelist"
              :disabled="whitelistCount === 0"
              class="text-xs px-3 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded hover:bg-gray-200 dark:hover:bg-gray-600 disabled:opacity-50"
            >
              📤 Export
            </button>
            <button
              @click="clearAllWhitelist"
              :disabled="whitelistCount === 0"
              class="text-xs px-3 py-1 bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 rounded hover:bg-red-200 dark:hover:bg-red-900/50 disabled:opacity-50"
            >
              🗑️ Clear All
            </button>
          </div>
        </div>

        <div v-if="whitelistCount === 0" class="text-center py-8 text-gray-500 dark:text-gray-400">
          <svg class="w-12 h-12 mx-auto mb-2 text-gray-300 dark:text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <p class="text-sm">No whitelisted addresses yet</p>
          <p class="text-xs mt-1">Import via CSV or add manually</p>
        </div>

        <div v-else class="space-y-2 max-h-60 overflow-y-auto">
          <div v-for="(entry, index) in whitelistEntries" :key="index" class="flex items-center justify-between p-3 bg-white dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600">
            <div class="flex-1 min-w-0">
              <div class="font-mono text-xs truncate">{{ entry.principal }}</div>
              <div class="flex items-center space-x-2 mt-1">
                <span v-if="entry.allocation" class="text-xs text-blue-600 dark:text-blue-400">{{ entry.allocation }} tokens</span>
                <span v-if="entry.tier && entry.tier > 1" class="text-xs px-1.5 py-0.5 bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 rounded">T{{ entry.tier }}</span>
                <span v-if="entry.registeredAt" class="text-xs text-gray-500">{{ formatDate(entry.registeredAt) }}</span>
              </div>
            </div>
            <button
              @click="removeWhitelistEntry(index)"
              class="text-red-500 hover:text-red-700 dark:hover:text-red-400"
            >
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Statistics -->
        <div v-if="whitelistCount > 0" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3 grid grid-cols-2 gap-4 text-xs">
          <div>
            <span class="text-gray-500 dark:text-gray-400">Total Allocation:</span>
            <span class="ml-2 font-medium">{{ totalAllocation }}</span>
          </div>
          <div>
            <span class="text-gray-500 dark:text-gray-400">Tier Distribution:</span>
            <span class="ml-2 font-medium">{{ tierDistribution }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Add Whitelist Button (when section is closed) -->
    <div v-else-if="requiresWhitelist" class="text-center">
      <button
        @click="toggleImportSection"
        class="inline-flex items-center px-4 py-2 bg-blue-500 text-white text-sm rounded-lg hover:bg-blue-600 transition-colors"
      >
        <svg class="w-4 h-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Manage Whitelist ({{ whitelistCount }})
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'
import { isValidPrincipal } from '@/utils/common'

interface WhitelistEntry {
  principal: string
  allocation?: string
  tier?: number
  isValid: boolean
  error?: string
}

const { formData } = useLaunchpadForm()

// State
const showImportSection = ref(false)
const activeTab = ref('manual') // Default to manual entry
const csvFileInput = ref<HTMLInputElement>()
const isProcessing = ref(false)
const manualEntryText = ref('')

// CSV Import State
const csvPreview = ref<WhitelistEntry[]>([])

// Manual Entry State
const manualEntries = ref<WhitelistEntry[]>([])

// Computed
const requiresWhitelist = computed(() => formData.value.saleParams.requiresWhitelist)
const whitelistEntries = computed(() => formData.value.whitelistEntries || [])
const whitelistCount = computed(() => whitelistEntries.value.length)

const showWhitelistImport = computed(() => requiresWhitelist.value && showImportSection.value)

const hasValidEntries = computed(() => csvPreview.value.some(entry => entry.isValid))
const validEntriesCount = computed(() => csvPreview.value.filter(entry => entry.isValid).length)

const hasValidManualEntries = computed(() => manualEntries.value.some(entry => entry.isValid))
const validManualEntriesCount = computed(() => manualEntries.value.filter(entry => entry.isValid).length)

const totalAllocation = computed(() => {
  const entries = whitelistEntries.value || []
  const total = entries.reduce((sum, entry) => {
    return sum + (entry.allocation ? Number(entry.allocation) : 0)
  }, 0)
  return total.toLocaleString()
})

const tierDistribution = computed(() => {
  const entries = whitelistEntries.value || []
  const tiers = entries.reduce((acc, entry) => {
    const tier = entry.tier || 1
    acc[tier] = (acc[tier] || 0) + 1
    return acc
  }, {} as Record<number, number>)

  return Object.entries(tiers)
    .sort(([a], [b]) => Number(a) - Number(b))
    .map(([tier, count]) => `T${tier}: ${count}`)
    .join(', ')
})

// Methods
const toggleImportSection = () => {
  showImportSection.value = !showImportSection.value
  if (showImportSection.value) {
    activeTab.value = whitelistEntries.value.length > 0 ? 'manage' : 'csv'
  }
}

// Using common validation function from utils/common.ts
// const validatePrincipal = (principal: string): boolean => {
//   Basic ICP principal validation
//   const principalRegex = /^[a-z0-9-]{5,63}$/
//   return principalRegex.test(principal) && principal.includes('-')
// }

const parseCSVLine = (line: string): WhitelistEntry => {
  const parts = line.split(',').map(part => part.trim())
  const principal = parts[0]

  if (!principal) {
    return { principal: '', isValid: false, error: 'Principal required' }
  }

  if (!isValidPrincipal(principal)) {
    return { principal, isValid: false, error: 'Invalid principal format' }
  }

  const allocation = parts[1] || undefined
  const tier = parts[2] ? parseInt(parts[2]) : 1

  if (tier < 1 || tier > 10) {
    return { principal, allocation, tier, isValid: false, error: 'Tier must be 1-10' }
  }

  return {
    principal,
    allocation,
    tier,
    isValid: true
  }
}

const handleFileUpload = (event: Event) => {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return

  if (!file.name.endsWith('.csv')) {
    alert('Please upload a CSV file')
    return
  }

  isProcessing.value = true

  const reader = new FileReader()
  reader.onload = (e) => {
    const content = e.target?.result as string
    const lines = content.split('\n').filter(line => line.trim())

    // Skip header if present
    const startIndex = lines[0]?.toLowerCase().includes('principal') ? 1 : 0

    csvPreview.value = lines
      .slice(startIndex)
      .map(line => parseCSVLine(line))
      .filter(entry => entry.principal)

    isProcessing.value = false
  }

  reader.onerror = () => {
    alert('Error reading file')
    isProcessing.value = false
  }

  reader.readAsText(file)
}

const importFromCSV = async () => {
  const validEntries = csvPreview.value.filter(entry => entry.isValid)

  // Safe initialization
  if (!formData.value.whitelistEntries) {
    formData.value.whitelistEntries = []
  }

  // Process each entry with duplicate detection
  validEntries.forEach(entry => {
    const existingIndex = formData.value.whitelistEntries.findIndex(
      existing => existing.principal === entry.principal
    )

    if (existingIndex >= 0) {
      // Update existing entry
      formData.value.whitelistEntries[existingIndex] = {
        ...formData.value.whitelistEntries[existingIndex],
        allocation: entry.allocation,
        tier: entry.tier,
        registeredAt: formData.value.whitelistEntries[existingIndex].registeredAt || new Date().toISOString()
      }
    } else {
      // Add new entry
      formData.value.whitelistEntries.push({
        principal: entry.principal,
        allocation: entry.allocation,
        tier: entry.tier,
        registeredAt: new Date().toISOString()
      })
    }
  })

  // Clear preview
  csvPreview.value = []

  // Reset file input
  if (csvFileInput.value) {
    csvFileInput.value.value = ''
  }

  // Switch to manage tab
  activeTab.value = 'manage'
}

const validateManualEntry = () => {
  const lines = manualEntryText.value.split('\n').filter(line => line.trim())

  manualEntries.value = lines.map(line => parseCSVLine(line)).filter(entry => entry.principal)
}

const importFromManual = async () => {
  const validEntries = manualEntries.value.filter(entry => entry.isValid)

  // Safe initialization
  if (!formData.value.whitelistEntries) {
    formData.value.whitelistEntries = []
  }

  // Process each entry with duplicate detection
  validEntries.forEach(entry => {
    const existingIndex = formData.value.whitelistEntries.findIndex(
      existing => existing.principal === entry.principal
    )

    if (existingIndex >= 0) {
      // Update existing entry
      formData.value.whitelistEntries[existingIndex] = {
        ...formData.value.whitelistEntries[existingIndex],
        allocation: entry.allocation,
        tier: entry.tier,
        registeredAt: formData.value.whitelistEntries[existingIndex].registeredAt || new Date().toISOString()
      }
    } else {
      // Add new entry
      formData.value.whitelistEntries.push({
        principal: entry.principal,
        allocation: entry.allocation,
        tier: entry.tier,
        registeredAt: new Date().toISOString()
      })
    }
  })

  // Clear form
  manualEntryText.value = ''
  manualEntries.value = []

  // Switch to manage tab
  activeTab.value = 'manage'
}

const removeWhitelistEntry = (index: number) => {
  // Safe initialization
  if (!formData.value.whitelistEntries) {
    formData.value.whitelistEntries = []
  }
  formData.value.whitelistEntries.splice(index, 1)
}

const clearAllWhitelist = () => {
  if (confirm('Are you sure you want to remove all whitelisted addresses?')) {
    formData.value.whitelistEntries = []
  }
}

const exportWhitelist = () => {
  // Safe check
  const entries = whitelistEntries.value || []
  const headers = ['principal', 'allocation', 'tier', 'registeredAt']
  const csvContent = [
    headers.join(','),
    ...entries.map(entry =>
      [entry.principal, entry.allocation || '', entry.tier || 1, entry.registeredAt || ''].join(',')
    )
  ].join('\n')

  const blob = new Blob([csvContent], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `whitelist_${new Date().toISOString().split('T')[0]}.csv`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString()
}

// Auto-open import section when whitelist is enabled
watch(requiresWhitelist, (newValue) => {
  if (newValue && whitelistEntries.value.length === 0) {
    showImportSection.value = true
    activeTab.value = 'manual' // Default to manual entry
  }
})
</script>