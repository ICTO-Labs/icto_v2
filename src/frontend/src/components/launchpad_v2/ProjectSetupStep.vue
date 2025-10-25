<template>
  <div class="space-y-6">
    <div class="text-center mb-8">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-2">
        Project Setup
      </h2>
      <p class="text-sm text-gray-600 dark:text-gray-400">
        Configure your project information to get started with your launchpad.
      </p>
    </div>

    <!-- Basic Project Information -->
    <div class="dark:bg-gray-800 rounded-lg border p-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        📝 Basic Information
      </h3>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Project Name -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Project Name* <HelpTooltip>The official name of your project that will be displayed to investors</HelpTooltip>
          </label>
          <input
            v-model="localFormData.projectInfo.name"
            type="text"
            class="w-full px-3 py-2 border"
            :class="[
              hasFieldError('projectName').value
                ? 'border-red-300 dark:border-red-600 focus:ring-2 focus:ring-red-500 focus:border-red-500'
                : 'border-gray-300 dark:border-gray-600 focus:ring-2 focus:ring-blue-500 focus:border-blue-500',
              'rounded-lg dark:bg-gray-700 dark:text-white'
            ]"
            placeholder="My Awesome Project"
            :id="uniqueIds.projectName"
          />
          <FieldError :field="'projectName'" :all-errors="allErrors" />
        </div>

        <!-- Project Category -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Project Category* <HelpTooltip>Select the category that best describes your project</HelpTooltip>
          </label>
          <Select
            v-model="localFormData.projectInfo.category"
            :options="PROJECT_CATEGORIES"
            placeholder="Choose a category"
            :id="uniqueIds.projectCategory"
            size="lg"
            :class="hasFieldError('projectCategory').value ? 'border-red-300 dark:border-red-600' : ''"
          />
          <FieldError :field="'projectCategory'" :all-errors="allErrors" />
        </div>

        <!-- Project Description -->
        <div class="md:col-span-2">
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Project Description* <HelpTooltip>Detailed description of your project, its purpose, and key features</HelpTooltip>
          </label>
          <textarea
            v-model="localFormData.projectInfo.description"
            rows="4"
            class="w-full px-3 py-2 border"
            :class="[
              hasFieldError('projectDescription').value
                ? 'border-red-300 dark:border-red-600 focus:ring-2 focus:ring-red-500 focus:border-red-500'
                : 'border-gray-300 dark:border-gray-600 focus:ring-2 focus:ring-blue-500 focus:border-blue-500',
              'rounded-lg dark:bg-gray-700 dark:text-white'
            ]"
            placeholder="Describe your project in detail..."
          ></textarea>
          <FieldError :field="'projectDescription'" :all-errors="allErrors" />
        </div>

        <!-- Project Logo -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Project Logo URL <HelpTooltip>URL to your project logo. Used as logo and avatar. (Recommended: 512x512px, square format)</HelpTooltip>
          </label>
          <URLImageInput
            v-model="localFormData.projectInfo.logo"
            placeholder="https://example.com/logo.png"
            :input-class="hasFieldError('projectLogo').value
                ? 'border-red-300 dark:border-red-600'
                : 'border-gray-300 dark:border-gray-600'"
            preview-class="h-32 w-32"
            help-text="Square format recommended (e.g., 512x512px)"
          />
          <FieldError :field="'projectLogo'" :all-errors="allErrors" />
        </div>

        <!-- Project Cover -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Project Cover URL <HelpTooltip>Cover/banner image for detail page. (Recommended: 1920x600px, wide format)</HelpTooltip>
          </label>
          <URLImageInput
            v-model="localFormData.projectInfo.cover"
            placeholder="https://example.com/cover.png"
            preview-class="max-h-32 max-w-full"
            help-text="Wide format recommended (e.g., 1920x600px)"
          />
        </div>
      </div>
    </div>

    <!-- Project Links -->
    <div class="dark:bg-gray-800 rounded-lg border p-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        🔗 Project Links
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Provide links to your project's online presence. These help build trust with investors.
      </p>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Website -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Website
          </label>
          <input
            v-model="localFormData.projectInfo.website"
            type="url"
            class="w-full px-3 py-2 border"
            :class="[
              hasFieldError('projectWebsite').value
                ? 'border-red-300 dark:border-red-600 focus:ring-2 focus:ring-red-500 focus:border-red-500'
                : 'border-gray-300 dark:border-gray-600 focus:ring-2 focus:ring-blue-500 focus:border-blue-500',
              'rounded-lg dark:bg-gray-700 dark:text-white'
            ]"
            placeholder="https://myproject.com"
          />
          <FieldError :field="'projectWebsite'" :all-errors="allErrors" />
        </div>

        <!-- Twitter -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Twitter
          </label>
          <input
            v-model="localFormData.projectInfo.twitter"
            type="text"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="@myproject"
          />
        </div>

        <!-- Telegram -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Telegram
          </label>
          <input
            v-model="localFormData.projectInfo.telegram"
            type="text"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="myproject"
          />
        </div>

        <!-- Discord -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Discord
          </label>
          <input
            v-model="localFormData.projectInfo.discord"
            type="url"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="https://discord.gg/myproject"
          />
        </div>

        <!-- GitHub -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            GitHub Repository
          </label>
          <input
            v-model="localFormData.projectInfo.github"
            type="url"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="https://github.com/myproject"
          />
        </div>

        <!-- Medium -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Medium Blog
          </label>
          <input
            v-model="localFormData.projectInfo.medium"
            type="url"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="https://medium.com/@myproject"
          />
        </div>

        <!-- Reddit -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            Reddit Community
          </label>
          <input
            v-model="localFormData.projectInfo.reddit"
            type="url"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="https://reddit.com/r/myproject"
          />
        </div>

        <!-- YouTube -->
        <div>
          <label class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            YouTube Channel
          </label>
          <input
            v-model="localFormData.projectInfo.youtube"
            type="url"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-green-500 dark:bg-gray-700 dark:text-white"
            placeholder="https://youtube.com/@myproject"
          />
        </div>
      </div>
    </div>

    <!-- Trust & Verification -->
    <div class="bg-gray-50 dark:bg-gray-800 rounded-lg border p-6">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        🔒 Trust & Verification
      </h3>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-4">
        Verification information helps build investor confidence in your project.
      </p>

      <div class="space-y-4">
        <!-- KYC Verification -->
        <div class="flex items-center justify-between">
          <div>
            <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
              KYC Verified
            </label>
            <p class="text-xs text-gray-500 dark:text-gray-400">Project has completed KYC verification</p>
          </div>
          <BaseSwitch
            v-model="localFormData.projectInfo.isKYCed"
            size="md"
          />
        </div>
        <div v-if="localFormData.projectInfo.isKYCed" class="ml-0 mt-3">
          <input
            v-model="localFormData.projectInfo.kycProvider"
            type="text"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
            placeholder="KYC provider name (e.g., CertiK, Chainalysis)"
          />
        </div>

        <!-- Audit Information -->
        <div class="flex items-center justify-between">
          <div>
            <label class="text-sm font-medium text-gray-700 dark:text-gray-300">
              Smart Contracts Audited
            </label>
            <p class="text-xs text-gray-500 dark:text-gray-400">Smart contracts have been security audited</p>
          </div>
          <BaseSwitch
            v-model="localFormData.projectInfo.isAudited"
            size="md"
          />
        </div>
        <div v-if="localFormData.projectInfo.isAudited" class="ml-0 mt-3">
          <input
            v-model="localFormData.projectInfo.auditReport"
            type="url"
            class="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
            placeholder="Link to audit report (optional)"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { watch } from 'vue'

// Component imports
import HelpTooltip from '@/components/common/HelpTooltip.vue'
import BaseSwitch from '@/components/common/BaseSwitch.vue'
import Select from '@/components/common/Select.vue'
import FieldError from '@/components/common/FieldError.vue'
import URLImageInput from '@/components/common/URLImageInput.vue'

// Composables
import { useUniqueId } from '@/composables/useUniqueId'
import { useFieldErrors } from '@/composables/useFieldErrors'
import { useLaunchpadForm } from '@/composables/useLaunchpadForm'

// Use composable for centralized state - no more props/emit!
const { formData: localFormData, step0ValidationErrors } = useLaunchpadForm()

// DEBUG: Log formData initialization
console.log('[ProjectSetupStep] 🔍 Component mounted, localFormData:', localFormData.value)
console.log('[ProjectSetupStep] 📝 Project Name:', localFormData.value?.projectInfo?.name)

// Local state
const uniqueIds = {
  projectName: useUniqueId('project-name'),
  projectCategory: useUniqueId('project-category'),
  isKYCed: useUniqueId('is-kyced'),
  isAudited: useUniqueId('is-audited')
}

// Field errors management
const {
  hasFieldError,
  setErrorsFromValidation,
  allErrors,
  clearAllErrors
} = useFieldErrors()

// Set up field mappings for error matching
const fieldMappings = {
  projectName: 'project name|name is required|project name is required',
  projectCategory: 'category|project category|category is required',
  projectDescription: 'description|project description|description is required',
  projectWebsite: 'website|project website|invalid website',
  projectLogo: 'logo|project logo|invalid logo',
  projectCover: 'cover|project cover|invalid cover',
  twitter: 'twitter|twitter handle',
  telegram: 'telegram|telegram group',
  discord: 'discord|discord server',
  github: 'github|github repository',
  medium: 'medium|medium blog',
  reddit: 'reddit|reddit community',
  youtube: 'youtube|youtube channel'
}

// Watch validation errors and map them to fields
watch(() => step0ValidationErrors.value, (errors) => {
  if (errors && errors.length > 0) {
    setErrorsFromValidation(errors)
  } else {
    clearAllErrors()
  }
}, { immediate: true })

// Constants
const PROJECT_CATEGORIES = [
  { value: 'DeFi', label: 'Decentralized Finance (DeFi)' },
  { value: 'NFT', label: 'Non-Fungible Tokens (NFT)' },
  { value: 'Gaming', label: 'Gaming & Metaverse' },
  { value: 'Infrastructure', label: 'Infrastructure & Tools' },
  { value: 'Social', label: 'Social & Community' },
  { value: 'DAO', label: 'Decentralized Autonomous Organization' },
  { value: 'Other', label: 'Other' }
]
</script>