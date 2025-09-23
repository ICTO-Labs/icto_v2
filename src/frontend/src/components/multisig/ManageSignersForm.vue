<template>
  <div class="manage-signers-form">
    <!-- Current Signers -->
    <div class="current-signers-section">
      <div class="section-header">
        <h3>Current Signers</h3>
        <div class="threshold-info">
          <span>Threshold: {{ wallet.config.threshold }} of {{ wallet.signers.length }}</span>
        </div>
      </div>

      <div class="signers-list">
        <div
          v-for="(signer, index) in wallet.signers"
          :key="signer.principal.toString()"
          class="signer-item"
        >
          <div class="signer-info">
            <el-avatar :size="40">
              {{ getSignerInitials(signer) }}
            </el-avatar>
            <div class="signer-details">
              <div class="signer-name">{{ signer.name || 'Unnamed Signer' }}</div>
              <div class="signer-principal">{{ formatPrincipal(signer.principal) }}</div>
            </div>
          </div>

          <div class="signer-meta">
            <el-tag :type="getRoleTagType(signer.role)" size="small">
              {{ signer.role }}
            </el-tag>
            <div class="signer-actions">
              <el-button
                v-if="canModifyRole(signer)"
                size="small"
                type="text"
                @click="openEditSigner(signer, index)"
              >
                <Edit :size="16" />
                Edit
              </el-button>
              <el-button
                v-if="canRemoveSigner(signer)"
                size="small"
                type="text"
                class="danger"
                @click="confirmRemoveSigner(signer, index)"
              >
                <Trash2 :size="16" />
                Remove
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Add New Signer -->
    <div class="add-signer-section">
      <div class="section-header">
        <h3>Add New Signer</h3>
        <el-button type="primary" @click="showAddForm = !showAddForm">
          <Plus :size="16" />
          Add Signer
        </el-button>
      </div>

      <div v-if="showAddForm" class="add-signer-form">
        <SignerForm
          @confirm="handleAddSigner"
          @cancel="showAddForm = false"
        />
      </div>
    </div>

    <!-- Threshold Configuration -->
    <div class="threshold-section">
      <div class="section-header">
        <h3>Signature Threshold</h3>
      </div>

      <div class="threshold-config">
        <div class="threshold-info-text">
          <p>The number of signatures required to execute proposals.</p>
          <p class="warning-text">
            <AlertTriangle :size="16" />
            Changing the threshold requires a proposal and majority approval.
          </p>
        </div>

        <div class="threshold-controls">
          <el-form-item label="New Threshold">
            <el-input-number
              v-model="newThreshold"
              :min="1"
              :max="wallet.signers.length"
              :disabled="!canModifyThreshold"
            />
          </el-form-item>

          <el-button
            type="warning"
            :disabled="!canModifyThreshold || newThreshold === wallet.config.threshold"
            @click="proposeThresholdChange"
          >
            Propose Threshold Change
          </el-button>
        </div>

        <div class="threshold-visualization">
          <div class="current-threshold">
            <span class="label">Current:</span>
            <div class="threshold-bar">
              <div
                class="threshold-fill current"
                :style="{ width: `${(wallet.config.threshold / wallet.signers.length) * 100}%` }"
              ></div>
            </div>
            <span class="value">{{ wallet.config.threshold }}/{{ wallet.signers.length }}</span>
          </div>

          <div v-if="newThreshold !== wallet.config.threshold" class="new-threshold">
            <span class="label">Proposed:</span>
            <div class="threshold-bar">
              <div
                class="threshold-fill proposed"
                :style="{ width: `${(newThreshold / wallet.signers.length) * 100}%` }"
              ></div>
            </div>
            <span class="value">{{ newThreshold }}/{{ wallet.signers.length }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Advanced Settings -->
    <div class="advanced-settings-section">
      <div class="section-header">
        <h3>Advanced Settings</h3>
      </div>

      <div class="settings-grid">
        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-name">Recovery Mode</div>
            <div class="setting-description">
              Allow wallet recovery with special procedures
            </div>
          </div>
          <el-switch
            v-model="advancedSettings.allowRecovery"
            :disabled="!canModifySettings"
          />
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-name">Observer Access</div>
            <div class="setting-description">
              Allow read-only observer accounts
            </div>
          </div>
          <el-switch
            v-model="advancedSettings.allowObservers"
            :disabled="!canModifySettings"
          />
        </div>

        <div class="setting-item">
          <div class="setting-info">
            <div class="setting-name">Consensus Required</div>
            <div class="setting-description">
              Require consensus for configuration changes
            </div>
          </div>
          <el-switch
            v-model="advancedSettings.requiresConsensus"
            :disabled="!canModifySettings"
          />
        </div>
      </div>

      <div v-if="hasSettingsChanges" class="settings-actions">
        <el-button @click="resetSettings">Reset</el-button>
        <el-button type="warning" @click="proposeSettingsChange">
          Propose Settings Change
        </el-button>
      </div>
    </div>

    <!-- Edit Signer Dialog -->
    <el-dialog
      v-model="editSignerVisible"
      title="Edit Signer"
      width="500px"
    >
      <div v-if="editingSigner" class="edit-signer-content">
        <el-form :model="editSignerForm" label-position="top">
          <el-form-item label="Display Name">
            <el-input
              v-model="editSignerForm.name"
              placeholder="Optional display name"
              maxlength="50"
            />
          </el-form-item>

          <el-form-item label="Role">
            <el-select v-model="editSignerForm.role">
              <el-option
                v-for="role in availableRoles"
                :key="role.value"
                :label="role.label"
                :value="role.value"
                :disabled="!canAssignRole(role.value)"
              >
                <div class="role-option">
                  <div class="role-info">
                    <div class="role-name">{{ role.label }}</div>
                    <div class="role-description">{{ role.description }}</div>
                  </div>
                </div>
              </el-option>
            </el-select>
          </el-form-item>
        </el-form>
      </div>

      <template #footer>
        <el-button @click="editSignerVisible = false">Cancel</el-button>
        <el-button type="primary" @click="confirmEditSigner">
          Save Changes
        </el-button>
      </template>
    </el-dialog>

    <!-- Confirmation Dialogs -->
    <el-dialog
      v-model="confirmDialogVisible"
      :title="confirmDialog.title"
      width="400px"
    >
      <p>{{ confirmDialog.message }}</p>
      <template #footer>
        <el-button @click="confirmDialogVisible = false">Cancel</el-button>
        <el-button type="danger" @click="confirmDialog.action">
          Confirm
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive, watch } from 'vue';
import {
  Edit,
  Trash2,
  Plus,
  AlertTriangle
} from 'lucide-vue-next';
import type { MultisigWallet, SignerRole } from '@/types/multisig';
import { useAuthStore } from '@/stores/auth';
import SignerForm from './SignerForm.vue';
import {
  formatPrincipal,
  canSignerManage,
  canSignerSign
} from '@/utils/multisig';

interface Props {
  wallet: MultisigWallet;
}

const props = defineProps<Props>();

const emit = defineEmits<{
  updated: [];
  cancel: [];
}>();

const authStore = useAuthStore();

// Reactive state
const showAddForm = ref(false);
const newThreshold = ref(props.wallet.config.threshold);
const editSignerVisible = ref(false);
const confirmDialogVisible = ref(false);

const editingSigner = ref<any>(null);
const editingIndex = ref(-1);

const editSignerForm = reactive({
  name: '',
  role: 'Signer' as SignerRole
});

const advancedSettings = reactive({
  allowRecovery: props.wallet.config.allowRecovery || false,
  allowObservers: props.wallet.config.allowObservers || false,
  requiresConsensus: props.wallet.config.requiresConsensusForChanges || false
});

const confirmDialog = reactive({
  title: '',
  message: '',
  action: () => {}
});

// Available roles for assignment
const availableRoles = [
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

// Computed properties
const currentUserSigner = computed(() => {
  if (!authStore.principal) return null;
  return props.wallet.signers.find(
    signer => signer.principal.toString() === authStore.principal?.toString()
  );
});

const canModifyThreshold = computed(() => {
  return currentUserSigner.value ? canSignerManage(currentUserSigner.value.role) : false;
});

const canModifySettings = computed(() => {
  return currentUserSigner.value ? canSignerManage(currentUserSigner.value.role) : false;
});

const hasSettingsChanges = computed(() => {
  return advancedSettings.allowRecovery !== (props.wallet.config.allowRecovery || false) ||
         advancedSettings.allowObservers !== (props.wallet.config.allowObservers || false) ||
         advancedSettings.requiresConsensus !== (props.wallet.config.requiresConsensusForChanges || false);
});

// Methods
const getSignerInitials = (signer: any): string => {
  if (signer?.name && typeof signer.name === 'string') {
    return signer.name.split(' ').map((n: string) => n[0]).join('').toUpperCase().slice(0, 2);
  }
  return signer?.principal?.toString().slice(0, 2).toUpperCase() || '??';
};

const getRoleTagType = (role: SignerRole): string => {
  switch (role) {
    case 'Owner': return 'warning';
    case 'Signer': return 'primary';
    case 'Observer': return 'info';
    case 'Guardian': return 'danger';
    case 'Delegate': return 'success';
    default: return 'info';
  }
};

const canModifyRole = (signer: any): boolean => {
  if (!currentUserSigner.value) return false;

  // Owners can modify any role except other owners
  if (currentUserSigner.value.role === 'Owner' && signer.role !== 'Owner') {
    return true;
  }

  // Users can only modify their own profile (name)
  return signer.principal.toString() === authStore.principal?.toString();
};

const canRemoveSigner = (signer: any): boolean => {
  if (!currentUserSigner.value) return false;

  // Can't remove if it would break minimum threshold
  if (props.wallet.signers.length <= props.wallet.config.threshold) {
    return false;
  }

  // Owners can remove non-owners
  if (currentUserSigner.value.role === 'Owner' && signer.role !== 'Owner') {
    return true;
  }

  // Users can remove themselves (leave wallet)
  return signer.principal.toString() === authStore.principal?.toString();
};

const canAssignRole = (role: SignerRole): boolean => {
  if (!currentUserSigner.value) return false;

  // Only owners can assign Owner role
  if (role === 'Owner') {
    return currentUserSigner.value.role === 'Owner';
  }

  // Owners can assign any role
  return currentUserSigner.value.role === 'Owner';
};

const openEditSigner = (signer: any, index: number) => {
  editingSigner.value = signer;
  editingIndex.value = index;
  editSignerForm.name = signer.name || '';
  editSignerForm.role = signer.role;
  editSignerVisible.value = true;
};

const confirmEditSigner = () => {
  // This would create a proposal to modify the signer
  console.log('Edit signer:', {
    index: editingIndex.value,
    updates: editSignerForm
  });

  editSignerVisible.value = false;
  emit('updated');
};

const confirmRemoveSigner = (signer: any, index: number) => {
  confirmDialog.title = 'Remove Signer';
  confirmDialog.message = `Are you sure you want to remove ${signer.name || formatPrincipal(signer.principal)} from this wallet?`;
  confirmDialog.action = () => {
    handleRemoveSigner(signer, index);
    confirmDialogVisible.value = false;
  };
  confirmDialogVisible.value = true;
};

const handleRemoveSigner = (signer: any, index: number) => {
  // This would create a proposal to remove the signer
  console.log('Remove signer:', { signer, index });
  emit('updated');
};

const handleAddSigner = (signerData: any) => {
  // This would create a proposal to add the signer
  console.log('Add signer:', signerData);
  showAddForm.value = false;
  emit('updated');
};

const proposeThresholdChange = () => {
  // This would create a proposal to change the threshold
  console.log('Propose threshold change:', {
    current: props.wallet.config.threshold,
    new: newThreshold.value
  });
  emit('updated');
};

const proposeSettingsChange = () => {
  // This would create a proposal to change the settings
  console.log('Propose settings change:', advancedSettings);
  emit('updated');
};

const resetSettings = () => {
  advancedSettings.allowRecovery = props.wallet.config.allowRecovery || false;
  advancedSettings.allowObservers = props.wallet.config.allowObservers || false;
  advancedSettings.requiresConsensus = props.wallet.config.requiresConsensusForChanges || false;
};

// Watch for wallet changes
watch(() => props.wallet, () => {
  newThreshold.value = props.wallet.config.threshold;
  resetSettings();
}, { deep: true });
</script>

<style scoped lang="scss">
.manage-signers-form {
  .section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
    padding-bottom: 8px;
    border-bottom: 1px solid #ebeef5;

    h3 {
      margin: 0;
      color: #303133;
      font-size: 16px;
    }

    .threshold-info {
      font-size: 14px;
      color: #606266;
      font-weight: 600;
    }
  }

  .current-signers-section {
    margin-bottom: 32px;

    .signers-list {
      display: flex;
      flex-direction: column;
      gap: 12px;

      .signer-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px;
        background: #fafafa;
        border-radius: 8px;
        transition: all 0.3s ease;

        &:hover {
          background: #f0f0f0;
        }

        .signer-info {
          display: flex;
          align-items: center;
          gap: 12px;

          .signer-details {
            .signer-name {
              font-weight: 600;
              color: #303133;
              margin-bottom: 4px;
            }

            .signer-principal {
              font-size: 12px;
              color: #909399;
              font-family: monospace;
            }
          }
        }

        .signer-meta {
          display: flex;
          align-items: center;
          gap: 12px;

          .signer-actions {
            display: flex;
            gap: 8px;

            .danger {
              color: #f56c6c;

              &:hover {
                color: #f78989;
              }
            }
          }
        }
      }
    }
  }

  .add-signer-section {
    margin-bottom: 32px;

    .add-signer-form {
      margin-top: 16px;
      padding: 16px;
      background: #f8fafc;
      border-radius: 8px;
      border: 1px solid #e5e7eb;
    }
  }

  .threshold-section {
    margin-bottom: 32px;

    .threshold-config {
      .threshold-info-text {
        margin-bottom: 16px;

        p {
          margin: 0 0 8px 0;
          color: #606266;
        }

        .warning-text {
          display: flex;
          align-items: center;
          gap: 8px;
          color: #e6a23c;
          font-size: 14px;
        }
      }

      .threshold-controls {
        display: flex;
        gap: 16px;
        align-items: flex-end;
        margin-bottom: 24px;

        .el-form-item {
          margin-bottom: 0;
        }
      }

      .threshold-visualization {
        display: flex;
        flex-direction: column;
        gap: 12px;

        .current-threshold,
        .new-threshold {
          display: flex;
          align-items: center;
          gap: 12px;

          .label {
            width: 80px;
            font-size: 14px;
            color: #606266;
          }

          .threshold-bar {
            flex: 1;
            height: 8px;
            background: #f5f7fa;
            border-radius: 4px;
            overflow: hidden;

            .threshold-fill {
              height: 100%;
              transition: width 0.3s ease;

              &.current {
                background: #409eff;
              }

              &.proposed {
                background: #e6a23c;
              }
            }
          }

          .value {
            width: 60px;
            text-align: right;
            font-weight: 600;
            color: #303133;
          }
        }
      }
    }
  }

  .advanced-settings-section {
    .settings-grid {
      display: flex;
      flex-direction: column;
      gap: 16px;
      margin-bottom: 16px;

      .setting-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 16px;
        background: #fafafa;
        border-radius: 8px;

        .setting-info {
          .setting-name {
            font-weight: 600;
            color: #303133;
            margin-bottom: 4px;
          }

          .setting-description {
            font-size: 14px;
            color: #606266;
          }
        }
      }
    }

    .settings-actions {
      display: flex;
      justify-content: flex-end;
      gap: 12px;
      padding-top: 16px;
      border-top: 1px solid #ebeef5;
    }
  }

  .edit-signer-content {
    .role-option {
      .role-info {
        .role-name {
          font-weight: 600;
          color: #303133;
        }

        .role-description {
          font-size: 12px;
          color: #909399;
          margin-top: 2px;
        }
      }
    }
  }
}
</style>