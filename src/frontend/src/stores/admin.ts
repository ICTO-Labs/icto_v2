import { defineStore } from 'pinia';
import { ref } from 'vue';
import { backend as backendActor } from '@declarations/backend';
// TODO: FIX THIS TYPE IMPORT ISSUE. Using 'any' as a temporary workaround.
// import type { AuditLog, RefundRequest } from '../../../../declarations/backend/backend.did';

export const useAdminStore = defineStore('admin', () => {
  const auditLogs = ref<any[]>([]); // Should be AuditLog[]
  const refundRequests = ref<any[]>([]); // Should be RefundRequest[]
  const isLoading = ref(false);

  // TODO: Define proper type for filters
  async function fetchAuditLogs(filters: any) {
    isLoading.value = true;
    try {
      // TODO: Backend does not have adminGetAuditLogs. This is a placeholder.
      console.log('Fetching audit logs with filters:', filters);
      // auditLogs.value = await backendActor.adminGetAuditLogs(filters);
      await new Promise(resolve => setTimeout(resolve, 500));
      auditLogs.value = []; // Placeholder
    } catch(e) {
      console.error('Failed to fetch audit logs:', e);
    }
    finally {
      isLoading.value = false;
    }
  }

  async function fetchRefundRequests() {
    isLoading.value = true;
    try {
      refundRequests.value = await backendActor.adminGetRefundRequests([]);
    } catch(e) {
      console.error('Failed to fetch refund requests:', e);
    }
    finally {
      isLoading.value = false;
    }
  }

  async function approveRefund(refundId: string) {
    try {
        const result = await backendActor.adminApproveRefund(refundId, []);
        if ('ok' in result) {
            await fetchRefundRequests(); // Refresh the list
        } else {
            throw new Error(result.err);
        }
    } catch (e) {
        console.error('Failed to approve refund:', e);
    }
  }

  return {
    auditLogs,
    refundRequests,
    isLoading,
    fetchAuditLogs,
    fetchRefundRequests,
    approveRefund,
  };
}); 