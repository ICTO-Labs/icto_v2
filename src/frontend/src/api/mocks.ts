// api/mocks.ts
import { Principal } from "@dfinity/principal";
import type { UserProfile, TransactionView, /* AuditLog */ } from "../../../declarations/backend/backend.did";

// Note: AuditLog type is complex and not fully defined in the provided DID snippet.
// We will omit it from mocks for now.

export const mockUserProfile: UserProfile = {
  userId: Principal.fromText('aaaaa-bbbbb-ccccc-ddddd-eeeeee'),
  status: { 'Active': null },
  totalFeesPaid: 2500000n,
  metadata: {
      preferences: {
          theme: { 'Dark': null },
          language: 'en',
          emailNotifications: true,
          marketingEmails: false,
          pushNotifications: false,
          defaultGasLimit: [],
      },
      country: [],
      discordHandle: [],
      email: [],
      companyName: [],
      telegramHandle: [],
      timezone: [],
      twitterHandle: [],
      websiteUrl: [],
  },
  lastActiveAt: BigInt(Date.now()),
  deploymentCount: 5n,
  registeredAt: BigInt(Date.now() - 1000 * 60 * 60 * 24 * 30), // 30 days ago
  preferredPaymentToken: [],
};

export const mockTransactions: TransactionView[] = [
  {
    id: 'tx1',
    transactionType: { 'Payment': null },
    amount: 1000000n,
    status: 'Completed',
    timestamp: BigInt(Date.now() - 1000 * 60 * 5), // 5 minutes ago
    details: 'Payment for Token Deployment',
    onChainTxId: ['0x123abc...'],
    relatedId: ['payment_record_1'],
  },
  {
    id: 'tx2',
    transactionType: { 'Refund': null },
    amount: 500000n,
    status: 'Completed',
    timestamp: BigInt(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
    details: 'Refund for failed deployment',
    onChainTxId: ['0x456def...'],
    relatedId: ['refund_record_1'],
  }
];

// Mock for AuditLog would go here once the type is clarified.
// export const mockAuditLogs: any[] = [ ... ];
