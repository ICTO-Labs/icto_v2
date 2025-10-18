/**
 * Payment System Types
 * Types for launchpad payment flow and cost calculation
 */

import type { LaunchpadFormData } from './launchpad'

/**
 * Payment configuration for deployment
 */
export interface PaymentConfig {
  formData: LaunchpadFormData
  onProgress?: (currentStep: number, totalSteps: number) => void
  onSuccess?: (canisterId: string) => void
  onError?: (error: Error) => void
}

/**
 * Payment state machine status
 */
export type PaymentStatus =
  | 'idle'
  | 'calculating'
  | 'confirming'
  | 'approving'
  | 'verifying'
  | 'deploying'
  | 'completed'
  | 'failed'
  | 'cancelled'

/**
 * Payment state tracking
 */
export interface PaymentState {
  status: PaymentStatus
  currentStep: number
  totalSteps: number
  error: string | null
  canisterId: string | null
}

/**
 * Launchpad deployment cost breakdown
 */
export interface LaunchpadDeploymentCost {
  serviceFee: bigint // Launchpad factory service fee
  tokenDeploymentFee?: bigint // Optional token deployment fee
  daoDeploymentFee?: bigint // Optional DAO integration fee
  platformFeeRate: number // Platform fee percentage (e.g., 2 for 2%)
  platformFeeAmount: bigint // Calculated platform fee
  icpTransferFee: bigint // ICP transfer fee (0.0001 ICP)
  approvalMargin: bigint // Safety margin for approval (2x transfer fee)
  subtotal: bigint // Sum of all service fees
  total: bigint // Total amount to approve
}

/**
 * Payment history record
 */
export interface PaymentHistory {
  id: string
  timestamp: number
  canisterId?: string
  status: 'success' | 'failed' | 'cancelled'
  cost: bigint
  error?: string
}

/**
 * Formatted cost display (for UI)
 */
export interface FormattedCosts {
  serviceFee: string
  tokenFee: string | null
  daoFee: string | null
  platformFee: string
  total: string
}
