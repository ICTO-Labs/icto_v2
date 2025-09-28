<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200">
    <!-- Header -->
    <div class="px-6 py-4 border-b border-gray-200">
      <div class="flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-900">Security Audit Dashboard</h3>
          <p class="text-sm text-gray-600">Monitor wallet activities and security events</p>
        </div>
        <div class="flex gap-2">
          <button
            @click="refreshAll"
            :disabled="loading"
            class="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
          >
            <RefreshCw :class="{ 'animate-spin': loading }" class="w-4 h-4 mr-2" />
            Refresh
          </button>
          <button
            @click="downloadReport"
            class="px-3 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700"
          >
            <Download class="w-4 h-4 mr-2" />
            Export
          </button>
        </div>
      </div>
    </div>

    <!-- Security Status Overview -->
    <div class="p-6 border-b border-gray-200">
      <h4 class="text-md font-medium text-gray-900 mb-4">Security Status</h4>

      <div v-if="securityStatus" class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <!-- Risk Level -->
        <div class="bg-white border rounded-lg p-4">
          <div class="flex items-center">
            <div :class="getRiskLevelColor(securityStatus.riskLevel)" class="w-3 h-3 rounded-full mr-2"></div>
            <span class="text-sm font-medium text-gray-600">Risk Level</span>
          </div>
          <p :class="getRiskLevelTextColor(securityStatus.riskLevel)" class="text-lg font-bold mt-1">
            {{ securityStatus.riskLevel }}
          </p>
        </div>

        <!-- Active Threats -->
        <div class="bg-white border rounded-lg p-4">
          <div class="flex items-center">
            <AlertTriangle class="w-4 h-4 text-orange-500 mr-2" />
            <span class="text-sm font-medium text-gray-600">Active Threats</span>
          </div>
          <p class="text-lg font-bold text-gray-900 mt-1">{{ securityStatus.activeThreats }}</p>
        </div>

        <!-- Emergency Status -->
        <div class="bg-white border rounded-lg p-4">
          <div class="flex items-center">
            <Shield class="w-4 h-4 text-blue-500 mr-2" />
            <span class="text-sm font-medium text-gray-600">Emergency Status</span>
          </div>
          <p :class="securityStatus.isPaused ? 'text-red-600' : 'text-green-600'" class="text-lg font-bold mt-1">
            {{ securityStatus.isPaused ? 'PAUSED' : 'ACTIVE' }}
          </p>
        </div>

        <!-- Execution Status -->
        <div class="bg-white border rounded-lg p-4">
          <div class="flex items-center">
            <Activity class="w-4 h-4 text-green-500 mr-2" />
            <span class="text-sm font-medium text-gray-600">Execution</span>
          </div>
          <p :class="securityStatus.isExecuting ? 'text-orange-600' : 'text-green-600'" class="text-lg font-bold mt-1">
            {{ securityStatus.isExecuting ? 'EXECUTING' : 'IDLE' }}
          </p>
        </div>
      </div>

      <!-- Security Recommendations -->
      <div v-if="securityStatus?.recommendations?.length" class="mt-4">
        <h5 class="text-sm font-medium text-gray-900 mb-2">Security Recommendations</h5>
        <div class="space-y-2">
          <div
            v-for="(recommendation, index) in securityStatus.recommendations"
            :key="index"
            class="flex items-start gap-2 p-3 bg-yellow-50 border border-yellow-200 rounded-md"
          >
            <AlertCircle class="w-4 h-4 text-yellow-600 mt-0.5 flex-shrink-0" />
            <p class="text-sm text-yellow-800">{{ recommendation }}</p>
          </div>
        </div>
      </div>

      <!-- Emergency Controls -->
      <div v-if="visibility?.isOwner" class="mt-4 flex gap-2">
        <button
          v-if="!securityStatus?.isPaused"
          @click="handleEmergencyPause"
          :disabled="loading"
          class="px-4 py-2 text-sm font-medium text-white bg-red-600 border border-transparent rounded-md hover:bg-red-700 disabled:opacity-50"
        >
          <Pause class="w-4 h-4 mr-2" />
          Emergency Pause
        </button>
        <button
          v-else
          @click="handleEmergencyUnpause"
          :disabled="loading"
          class="px-4 py-2 text-sm font-medium text-white bg-green-600 border border-transparent rounded-md hover:bg-green-700 disabled:opacity-50"
        >
          <Play class="w-4 h-4 mr-2" />
          Emergency Unpause
        </button>
      </div>
    </div>

    <!-- Activity Summary -->
    <div class="p-6 border-b border-gray-200">
      <div class="flex items-center justify-between mb-4">
        <h4 class="text-md font-medium text-gray-900">Activity Summary</h4>
        <div class="flex gap-2">
          <Select
            v-model="selectedTimeRange"
            :options="timeRangeOptions"
            placeholder="Select time range"
            @update:modelValue="handleTimeRangeChange"
          />
        </div>
      </div>

      <div v-if="activityReport" class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <!-- Proposal Activity -->
        <div class="bg-gradient-to-r from-blue-50 to-blue-100 border border-blue-200 rounded-lg p-4">
          <h5 class="text-sm font-medium text-blue-900 mb-3">Proposal Activity</h5>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-blue-700">Created:</span>
              <span class="font-medium text-blue-900">{{ activityReport.proposalActivity.created }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-blue-700">Executed:</span>
              <span class="font-medium text-blue-900">{{ activityReport.proposalActivity.executed }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-blue-700">Failed:</span>
              <span class="font-medium text-blue-900">{{ activityReport.proposalActivity.failed }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-blue-700">Pending:</span>
              <span class="font-medium text-blue-900">{{ activityReport.proposalActivity.pending }}</span>
            </div>
          </div>
        </div>

        <!-- Transfer Activity -->
        <div class="bg-gradient-to-r from-green-50 to-green-100 border border-green-200 rounded-lg p-4">
          <h5 class="text-sm font-medium text-green-900 mb-3">Transfer Activity</h5>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-green-700">ICP Transfers:</span>
              <span class="font-medium text-green-900">{{ activityReport.transferActivity.icpTransfers }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-green-700">Token Transfers:</span>
              <span class="font-medium text-green-900">{{ activityReport.transferActivity.tokenTransfers }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-green-700">Total Value:</span>
              <span class="font-medium text-green-900">{{ formatTokenAmount(activityReport.transferActivity.totalValue, 8) }} ICP</span>
            </div>
          </div>
        </div>

        <!-- Security Activity -->
        <div class="bg-gradient-to-r from-orange-50 to-orange-100 border border-orange-200 rounded-lg p-4">
          <h5 class="text-sm font-medium text-orange-900 mb-3">Security Activity</h5>
          <div class="space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-orange-700">Emergency Actions:</span>
              <span class="font-medium text-orange-900">{{ activityReport.securityActivity.emergencyActions }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-orange-700">Signer Changes:</span>
              <span class="font-medium text-orange-900">{{ activityReport.securityActivity.signerChanges }}</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-orange-700">Config Changes:</span>
              <span class="font-medium text-orange-900">{{ activityReport.securityActivity.configChanges }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Recent Security Events -->
    <div class="p-6">
      <div class="flex items-center justify-between mb-4">
        <h4 class="text-md font-medium text-gray-900">Recent Security Events</h4>
        <button
          @click="viewFullAuditLog"
          class="text-sm text-blue-600 hover:text-blue-700"
        >
          View Full Audit Log →
        </button>
      </div>

      <div v-if="auditData?.securityAlerts?.length" class="space-y-3">
        <div
          v-for="(alert, index) in auditData.securityAlerts.slice(0, 5)"
          :key="index"
          class="flex items-start gap-3 p-3 border rounded-lg"
          :class="getAlertColor(alert.severity)"
        >
          <div :class="getAlertIconColor(alert.severity)" class="flex-shrink-0 mt-0.5">
            <AlertTriangle v-if="alert.severity === 'HIGH' || alert.severity === 'CRITICAL'" class="w-4 h-4" />
            <AlertCircle v-else-if="alert.severity === 'MEDIUM'" class="w-4 h-4" />
            <Info v-else class="w-4 h-4" />
          </div>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2">
              <span :class="getAlertTextColor(alert.severity)" class="text-xs font-medium uppercase tracking-wide">
                {{ alert.severity }}
              </span>
              <span class="text-xs text-gray-500">{{ formatTimestamp(alert.timestamp) }}</span>
            </div>
            <p class="text-sm text-gray-900 mt-1">{{ alert.message }}</p>
            <p class="text-xs text-gray-600 mt-1">Principal: {{ alert.principal.toString().slice(0, 20) }}...</p>
          </div>
        </div>
      </div>

      <div v-else class="text-center py-8">
        <Shield class="w-12 h-12 text-gray-400 mx-auto mb-3" />
        <p class="text-gray-500">No recent security events</p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import {
  RefreshCw, Download, AlertTriangle, Shield, Activity,
  AlertCircle, Pause, Play, Info
} from 'lucide-vue-next';
import { useMultisig } from '@/composables/useMultisig';
import { formatTokenAmount, formatTimestamp } from '@/utils/multisig';
import { toast } from 'vue-sonner';

const props = defineProps<{
  canisterId: string;
  visibility?: {
    isOwner: boolean;
    isSigner: boolean;
    isObserver: boolean;
    isAuthorized: boolean;
  };
}>();

const emit = defineEmits<{
  viewFullAuditLog: [];
}>();

const {
  loading,
  error,
  auditData,
  securityStatus,
  activityReport,
  fetchAuditLog,
  fetchSecurityStatus,
  fetchActivityReport,
  emergencyPause,
  emergencyUnpause
} = useMultisig();

const selectedTimeRange = ref('24h');
const timeRangeOptions = [
  { value: '1h', label: 'Last Hour' },
  { value: '24h', label: 'Last 24 Hours' },
  { value: '7d', label: 'Last 7 Days' },
  { value: '30d', label: 'Last 30 Days' }
];

const getTimeRangeMs = (range: string) => {
  const now = Date.now() * 1000000; // Convert to nanoseconds
  switch (range) {
    case '1h': return now - (60 * 60 * 1000000000);
    case '24h': return now - (24 * 60 * 60 * 1000000000);
    case '7d': return now - (7 * 24 * 60 * 60 * 1000000000);
    case '30d': return now - (30 * 24 * 60 * 60 * 1000000000);
    default: return now - (24 * 60 * 60 * 1000000000);
  }
};

const refreshAll = async () => {
  const startTime = getTimeRangeMs(selectedTimeRange.value);
  const endTime = Date.now() * 1000000;

  await Promise.all([
    fetchSecurityStatus(props.canisterId),
    fetchAuditLog(props.canisterId, startTime, endTime, undefined, 50),
    fetchActivityReport(props.canisterId, startTime, endTime)
  ]);
};

const handleTimeRangeChange = () => {
  refreshAll();
};

const handleEmergencyPause = async () => {
  try {
    const success = await emergencyPause(props.canisterId);
    if (success) {
      toast.success('Emergency pause activated successfully');
    }
  } catch (err) {
    console.error('Failed to activate emergency pause:', err);
  }
};

const handleEmergencyUnpause = async () => {
  try {
    const success = await emergencyUnpause(props.canisterId);
    if (success) {
      toast.success('Emergency pause deactivated successfully');
    }
  } catch (err) {
    console.error('Failed to deactivate emergency pause:', err);
  }
};

const downloadReport = () => {
  if (!auditData.value || !activityReport.value || !securityStatus.value) {
    toast.error('No data available to export');
    return;
  }

  const report = {
    timestamp: new Date().toISOString(),
    walletId: props.canisterId,
    securityStatus: securityStatus.value,
    activityReport: activityReport.value,
    auditData: auditData.value
  };

  const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `multisig-audit-report-${props.canisterId}-${new Date().toISOString().split('T')[0]}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);

  toast.success('Audit report exported successfully');
};

const viewFullAuditLog = () => {
  emit('viewFullAuditLog');
};

const getRiskLevelColor = (level: string) => {
  switch (level) {
    case 'HIGH': return 'bg-red-500';
    case 'MEDIUM': return 'bg-yellow-500';
    case 'LOW': return 'bg-green-500';
    default: return 'bg-gray-500';
  }
};

const getRiskLevelTextColor = (level: string) => {
  switch (level) {
    case 'HIGH': return 'text-red-600';
    case 'MEDIUM': return 'text-yellow-600';
    case 'LOW': return 'text-green-600';
    default: return 'text-gray-600';
  }
};

const getAlertColor = (severity: string) => {
  switch (severity) {
    case 'CRITICAL': return 'border-red-300 bg-red-50';
    case 'HIGH': return 'border-orange-300 bg-orange-50';
    case 'MEDIUM': return 'border-yellow-300 bg-yellow-50';
    default: return 'border-blue-300 bg-blue-50';
  }
};

const getAlertIconColor = (severity: string) => {
  switch (severity) {
    case 'CRITICAL': return 'text-red-600';
    case 'HIGH': return 'text-orange-600';
    case 'MEDIUM': return 'text-yellow-600';
    default: return 'text-blue-600';
  }
};

const getAlertTextColor = (severity: string) => {
  switch (severity) {
    case 'CRITICAL': return 'text-red-800';
    case 'HIGH': return 'text-orange-800';
    case 'MEDIUM': return 'text-yellow-800';
    default: return 'text-blue-800';
  }
};

onMounted(() => {
  if (props.visibility?.isAuthorized) {
    refreshAll();
  }
});

watch(() => props.canisterId, () => {
  if (props.visibility?.isAuthorized) {
    refreshAll();
  }
});
</script>