<template>
  <div class="multisig-create-form max-w-4xl mx-auto bg-white dark:bg-gray-900 rounded-xl shadow-lg overflow-hidden">
    <!-- Header -->
    <div class="bg-gradient-to-r from-brand-500 to-brand-600 px-8 py-6 text-white">
      <h2 class="text-2xl font-bold mb-2">Create Multisig Wallet</h2>
      <p class="text-brand-100 mb-6">Secure shared wallet with multi-signature approval</p>

      <!-- Progress Steps -->
      <div class="flex space-x-6">
        <div
          v-for="step in totalSteps"
          :key="step"
          class="flex items-center space-x-3 px-4 py-2 rounded-full"
          :class="{
            'bg-white/20': currentStep === step,
            'bg-white/10': currentStep > step,
            'bg-white/5': currentStep < step
          }"
        >
          <div
            class="flex items-center justify-center w-6 h-6 rounded-full text-xs font-semibold"
            :class="{
              'bg-white text-brand-600': currentStep >= step,
              'bg-white/20 text-white': currentStep < step
            }"
          >
            {{ step }}
          </div>
          <span class="text-sm font-medium">{{ getStepLabel(step) }}</span>
        </div>
      </div>
    </div>

    <div class="p-8">
      <!-- Step 1: Basic Information -->
      <div v-if="currentStep === 1" class="space-y-6">
        <div class="mb-6">
          <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Basic Information</h3>
          <p class="text-gray-600 dark:text-gray-400">Set up your wallet's basic details</p>
        </div>

        <div>
          <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
            Wallet Name *
          </label>
          <input
            v-model="formData.name"
            type="text"
            placeholder="e.g., Treasury Wallet, Team Fund"
            maxlength="50"
            class="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
          />
        </div>

        <div>
          <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
            Description
          </label>
          <textarea
            v-model="formData.description"
            rows="3"
            placeholder="Optional description of the wallet's purpose"
            maxlength="200"
            class="w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
          ></textarea>
        </div>
      </div>

      <!-- Step 2: Signers Configuration -->
      <div v-if="currentStep === 2" class="space-y-6">
        <div class="mb-6">
          <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Signers Configuration</h3>
          <p class="text-gray-600 dark:text-gray-400">Add signers and set approval threshold</p>
        </div>

        <!-- Threshold Setting -->
        <div class="rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800/50">
          <label class="mb-3 block text-sm font-medium text-gray-700 dark:text-gray-400">
            Approval Threshold
          </label>
          <div class="flex items-center space-x-3">
            <input
              v-model.number="formData.threshold"
              type="number"
              :min="1"
              :max="formData.signers.length || 1"
              class="h-12 w-24 rounded-lg border border-gray-300 bg-white px-3 text-center text-lg font-semibold text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
            />
            <span class="text-gray-600 dark:text-gray-400">
              of {{ formData.signers.length || 1 }} signature(s) required
            </span>
          </div>
          <p class="mt-2 text-xs text-gray-500">
            Number of signatures required to approve transactions
          </p>
        </div>

        <!-- Signers List -->
        <div>
          <div class="flex items-center justify-between mb-4">
            <h4 class="text-lg font-semibold text-gray-900 dark:text-white">
              Signers ({{ formData.signers.length }})
            </h4>
            <Button
              variant="primary"
              startIcon="Plus"
              @click="showAddSignerDialog = true"
            >
              Add Signer
            </Button>
          </div>

          <div v-if="formData.signers.length === 0" class="text-center py-12 text-gray-500">
            <UserCircle :size="48" class="mx-auto mb-4 text-gray-300" />
            <p class="text-lg font-medium mb-1">No signers added yet</p>
            <p class="text-sm">Add at least one signer to continue</p>
          </div>

          <div v-else class="space-y-3">
            <div
              v-for="(signer, index) in formData.signers"
              :key="signer.principal"
              class="flex items-center space-x-4 rounded-lg border border-gray-200 bg-gray-50 p-4 dark:border-gray-700 dark:bg-gray-800/50"
            >
              <div class="flex h-10 w-10 items-center justify-center rounded-full bg-brand-100 text-brand-700 dark:bg-brand-900/20 dark:text-brand-400">
                {{ signer.name ? signer.name[0].toUpperCase() : 'S' }}
              </div>

              <div class="flex-1">
                <div class="font-medium text-gray-900 dark:text-white">
                  {{ signer.name || 'Unnamed Signer' }}
                </div>
                <div class="text-xs font-mono text-gray-500 dark:text-gray-400">
                  {{ formatPrincipal(signer.principal) }}
                </div>
                <div class="mt-1">
                  <span
                    class="inline-flex items-center rounded-full px-2 py-1 text-xs font-medium"
                    :class="getRoleTagClasses(signer.role)"
                  >
                    {{ signer.role }}
                  </span>
                </div>
              </div>

              <Button
                variant="outline"
                size="sm"
                startIcon="Trash2"
                @click="removeSigner(signer.principal)"
                class="text-red-600 hover:text-red-700 hover:bg-red-50"
              >
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Step 3: Security Settings -->
      <div v-if="currentStep === 3" class="space-y-6">
        <div class="mb-6">
          <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Security Settings</h3>
          <p class="text-gray-600 dark:text-gray-400">Configure security features for your wallet</p>
        </div>

        <div class="space-y-6">
          <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <BaseSwitch
              v-model="formData.requiresTimelock"
              label="Time Lock"
              description="Add delay between approval and execution"
              labelPosition="right"
            />

            <div v-if="formData.requiresTimelock" class="mt-4 pl-12">
              <div class="flex items-center space-x-3">
                <input
                  v-model.number="formData.timelockDuration"
                  type="number"
                  :min="1"
                  :max="168"
                  placeholder="Hours"
                  class="h-9 w-24 rounded-lg border border-gray-300 bg-transparent px-3 text-sm text-gray-800 focus:border-brand-300 focus:outline-hidden focus:ring-2 focus:ring-brand-500/10 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                />
                <span class="text-sm text-gray-500">hours</span>
              </div>
            </div>
          </div>

          <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <BaseSwitch
              v-model="formData.allowRecovery"
              label="Recovery Mode"
              description="Allow wallet recovery in emergencies"
              labelPosition="right"
            />

            <div v-if="formData.allowRecovery" class="mt-4 pl-12">
              <label class="mb-2 block text-sm text-gray-700 dark:text-gray-400">Recovery Threshold</label>
              <div class="flex items-center space-x-3">
                <input
                  v-model.number="formData.recoveryThreshold"
                  type="number"
                  :min="1"
                  :max="formData.signers.length"
                  class="h-9 w-24 rounded-lg border border-gray-300 bg-transparent px-3 text-sm text-gray-800 focus:border-brand-300 focus:outline-hidden focus:ring-2 focus:ring-brand-500/10 dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                />
                <span class="text-sm text-gray-500">signers for recovery</span>
              </div>
            </div>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              Daily Spending Limit (ICP)
            </label>
            <input
              v-model.number="formData.dailyLimit"
              type="number"
              :min="0"
              step="0.01"
              placeholder="Optional daily limit"
              class="h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
            />
            <p class="mt-1 text-xs text-gray-500">
              Leave empty for no daily limit
            </p>
          </div>
        </div>
      </div>

      <!-- Step 4: Advanced Settings -->
      <div v-if="currentStep === 4" class="space-y-6">
        <div class="mb-6">
          <h3 class="text-xl font-semibold text-gray-900 dark:text-white mb-2">Advanced Settings</h3>
          <p class="text-gray-600 dark:text-gray-400">Fine-tune wallet behavior and governance</p>
        </div>

        <div class="space-y-6">
          <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <BaseSwitch
              v-model="formData.allowObservers"
              label="Allow Observers"
              description="Read-only access for non-signing members"
              labelPosition="right"
            />
          </div>

          <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <BaseSwitch
              v-model="formData.requiresConsensusForChanges"
              label="Consensus for Changes"
              description="Require all signers for structural changes"
              labelPosition="right"
            />
          </div>

          <div class="rounded-lg border border-gray-200 p-4 dark:border-gray-700">
            <BaseSwitch
              v-model="formData.isPublic"
              label="Public Wallet"
              description="Anyone can view this wallet (private: only signers and observers can view)"
              labelPosition="right"
            />
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              Maximum Proposal Lifetime
            </label>
            <div class="flex items-center space-x-3">
              <input
                v-model.number="formData.maxProposalLifetime"
                type="number"
                :min="1"
                :max="720"
                class="h-11 w-32 rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
              />
              <span class="text-sm text-gray-500">hours</span>
            </div>
            <p class="mt-1 text-xs text-gray-500">
              Proposals expire after this duration
            </p>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400">
              Emergency Contact Delay
            </label>
            <div class="flex items-center space-x-3">
              <input
                v-model.number="formData.emergencyContactDelay"
                type="number"
                :min="0"
                :max="168"
                class="h-11 w-32 rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:focus:border-brand-800"
              />
              <span class="text-sm text-gray-500">hours</span>
            </div>
            <p class="mt-1 text-xs text-gray-500">
              Delay before emergency contacts can act
            </p>
          </div>
        </div>
      </div>

      <!-- Validation Errors -->
      <div v-if="validationErrors.length > 0" class="mt-6 space-y-2">
        <div
          v-for="error in validationErrors"
          :key="error"
          class="flex items-center gap-2 rounded-lg bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/20 dark:text-red-400"
        >
          <AlertTriangle :size="16" />
          <span>{{ error }}</span>
        </div>
      </div>
    </div>

    <!-- Form Actions -->
    <div class="flex items-center justify-between border-t border-gray-200 bg-gray-50 px-8 py-4 dark:border-gray-700 dark:bg-gray-800">
      <div>
        <Button
          v-if="currentStep > 1"
          variant="outline"
          startIcon="ArrowLeft"
          @click="prevStep()"
        >
          Previous
        </Button>
      </div>

      <div class="flex space-x-3">
        <Button variant="outline" @click="$emit('cancel')">
          Cancel
        </Button>

        <Button
          v-if="currentStep < totalSteps"
          variant="primary"
          :disabled="!canProceed"
          endIcon="ArrowRight"
          @click="nextStep()"
        >
          Next
        </Button>

        <Button
          v-else
          variant="primary"
          :disabled="!isValid || loading"
          startIcon="Check"
          @click="handleSubmit"
        >
          {{ loading ? 'Creating...' : 'Create Wallet' }}
        </Button>
      </div>
    </div>

    <!-- Add Signer Dialog -->
    <Modal :fullScreenBackdrop="true" v-if="showAddSignerDialog" @close="showAddSignerDialog = false">
      <template #body>
        <div class="max-w-lg rounded-xl bg-white p-6 shadow-xl dark:bg-gray-900">
          <div class="mb-4">
            <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Add Signer</h3>
          </div>
          <SignerForm
            @confirm="handleAddSigner"
            @cancel="showAddSignerDialog = false"
          />
        </div>
      </template>
    </Modal>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { toast } from 'vue-sonner';
import {
  Plus,
  UserCircle,
  Trash2,
  ArrowLeft,
  ArrowRight,
  Check,
  AlertTriangle
} from 'lucide-vue-next';
import { useWalletForm } from '@/composables/useMultisig';
import { formatPrincipal } from '@/utils/multisig';
import SignerForm from './SignerForm.vue';
import Button from '@/components/ui/Button.vue';
import Modal from '@/components/ui/Modal.vue';
import BaseSwitch from '@/components/common/BaseSwitch.vue';
import type { SignerRole } from '@/types/multisig';

// Emits
const emit = defineEmits<{
  cancel: [];
  success: [walletId: string];
}>();

// Composables
const {
  formData,
  validationErrors,
  currentStep,
  totalSteps,
  isValid,
  canProceed,
  addSigner,
  removeSigner,
  nextStep,
  prevStep,
  resetForm
} = useWalletForm();

// Local state
const loading = ref(false);
const showAddSignerDialog = ref(false);

// Computed
const getStepLabel = (step: number): string => {
  switch (step) {
    case 1: return 'Basic Info';
    case 2: return 'Signers';
    case 3: return 'Security';
    case 4: return 'Advanced';
    default: return '';
  }
};

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

const handleAddSigner = (signerData: { principal: string; name?: string; role: SignerRole }) => {
  try {
    addSigner(signerData.principal, signerData.name, signerData.role);
    showAddSignerDialog.value = false;
    toast.success('Signer added successfully');
  } catch (error) {
    toast.error(error instanceof Error ? error.message : 'Failed to add signer');
  }
};

const handleSubmit = async () => {
  if (!isValid.value) {
    toast.error('Please fix validation errors before submitting');
    return;
  }

  loading.value = true;

  try {
    const { createWallet } = useMultisig();
    const success = await createWallet(formData.value);

    if (success) {
      toast.success('Multisig wallet created successfully!');
      emit('success', 'wallet-id'); // TODO: Get actual wallet ID
      resetForm();
    }
  } catch (error) {
    toast.error(error instanceof Error ? error.message : 'Failed to create wallet');
  } finally {
    loading.value = false;
  }
};
</script>