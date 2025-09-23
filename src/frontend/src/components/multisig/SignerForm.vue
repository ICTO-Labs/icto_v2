<template>
  <div class="signer-form space-y-6">
    <!-- Principal ID Input -->
    <div>
      <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
        Principal ID *
      </label>
      <input
        v-model="formData.principal"
        type="text"
        placeholder="Enter signer's principal ID"
        maxlength="100"
        class="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
        :class="{
          'border-red-300 focus:border-red-300 focus:ring-red-500/10': formData.principal && !isValidPrincipalValue,
          'border-green-300 focus:border-green-300 focus:ring-green-500/10': formData.principal && isValidPrincipalValue
        }"
      />
      <div class="mt-1 text-xs text-gray-500">
        The Internet Computer principal ID of the signer
      </div>
    </div>

    <!-- Display Name Input -->
    <div>
      <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
        Display Name
      </label>
      <input
        v-model="formData.name"
        type="text"
        placeholder="Optional display name"
        maxlength="50"
        class="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
      />
      <div class="mt-1 text-xs text-gray-500">
        Friendly name to identify this signer
      </div>
    </div>

    <!-- Role Select -->
    <div>
      <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
        Role *
      </label>
      <div class="relative z-20 bg-transparent">
        <select
          v-model="formData.role"
          class="h-11 w-full appearance-none rounded-lg border border-gray-300 bg-transparent bg-none px-4 py-2.5 pr-11 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
          :class="{ 'text-gray-800 dark:text-white/90': formData.role }"
        >
          <option value="" disabled>Select role</option>
          <option
            v-for="role in roleOptions"
            :key="role.value"
            :value="role.value"
            class="text-gray-700 dark:bg-gray-900 dark:text-gray-400"
          >
            {{ role.label }} - {{ role.description }}
          </option>
        </select>
        <span class="absolute z-30 text-gray-500 -translate-y-1/2 pointer-events-none right-4 top-1/2 dark:text-gray-400">
          <svg
            class="stroke-current"
            width="20"
            height="20"
            viewBox="0 0 20 20"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M4.79175 7.396L10.0001 12.6043L15.2084 7.396"
              stroke=""
              stroke-width="1.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </span>
      </div>
      <div class="mt-1 text-xs text-gray-500">
        Determines the signer's permissions in the wallet
      </div>
    </div>

    <!-- Principal Validation Info -->
    <div v-if="formData.principal && !isValidPrincipalValue" class="flex items-center gap-2 rounded-lg bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/20 dark:text-red-400">
      <AlertTriangle :size="16" />
      <span>Invalid principal format</span>
    </div>

    <div v-else-if="formData.principal && isValidPrincipalValue" class="flex items-center gap-2 rounded-lg bg-green-50 p-3 text-sm text-green-700 dark:bg-green-900/20 dark:text-green-400">
      <CheckCircle :size="16" />
      <span>Valid principal</span>
    </div>

    <!-- Principal Preview -->
    <div v-if="isValidPrincipalValue" class="rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800/50">
      <div class="mb-3">
        <h4 class="text-sm font-semibold text-gray-700 dark:text-gray-300">Principal Preview</h4>
      </div>
      <div class="flex items-center gap-3">
        <div class="flex h-10 w-10 items-center justify-center rounded-full bg-brand-100 text-brand-700 dark:bg-brand-900/20 dark:text-brand-400">
          {{ formData.name ? formData.name[0].toUpperCase() : 'S' }}
        </div>
        <div class="flex-1">
          <div class="font-medium text-gray-900 dark:text-white">
            {{ formData.name || 'Unnamed Signer' }}
          </div>
          <div class="text-xs font-mono text-gray-500 dark:text-gray-400">
            {{ formatPrincipal(formData.principal) }}
          </div>
          <div class="mt-1">
            <span
              class="inline-flex items-center rounded-full px-2 py-1 text-xs font-medium"
              :class="getRoleTagClasses(formData.role)"
            >
              {{ formData.role }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex justify-end gap-3 border-t border-gray-200 pt-4 dark:border-gray-700">
      <Button variant="outline" @click="$emit('cancel')">
        Cancel
      </Button>
      <Button
        variant="primary"
        :disabled="!canSubmit"
        @click="handleSubmit"
      >
        Add Signer
      </Button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue';
import {
  AlertTriangle,
  CheckCircle
} from 'lucide-vue-next';
import { isValidPrincipal, formatPrincipal } from '@/utils/multisig';
import type { SignerRole } from '@/types/multisig';
import Button from '@/components/ui/Button.vue';

// Emits
const emit = defineEmits<{
  confirm: [data: { principal: string; name?: string; role: SignerRole }];
  cancel: [];
}>();

// Form data
const formData = reactive({
  principal: '',
  name: '',
  role: 'Signer' as SignerRole
});

// Role options
const roleOptions = [
  {
    value: 'Owner',
    label: 'Owner',
    description: 'Full administrative rights'
  },
  {
    value: 'Signer',
    label: 'Signer',
    description: 'Can create and sign proposals'
  },
  {
    value: 'Observer',
    label: 'Observer',
    description: 'Read-only access'
  },
  {
    value: 'Guardian',
    label: 'Guardian',
    description: 'Emergency operations only'
  },
  {
    value: 'Delegate',
    label: 'Delegate',
    description: 'Temporary signing rights'
  }
];

// Computed
const isValidPrincipalValue = computed(() => {
  return formData.principal ? isValidPrincipal(formData.principal) : false;
});

const canSubmit = computed(() => {
  return formData.principal.trim() &&
         formData.role &&
         isValidPrincipalValue.value;
});

// Methods
const getRoleTagClasses = (role: SignerRole): string => {
  switch (role) {
    case 'Owner':
      return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400';
    case 'Signer':
      return 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400';
    case 'Observer':
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
    case 'Guardian':
      return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400';
    case 'Delegate':
      return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400';
    default:
      return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
  }
};

const handleSubmit = async () => {
  if (!canSubmit.value) return;

  emit('confirm', {
    principal: formData.principal.trim(),
    name: formData.name.trim() || undefined,
    role: formData.role
  });

  // Reset form
  formData.principal = '';
  formData.name = '';
  formData.role = 'Signer';
};
</script>