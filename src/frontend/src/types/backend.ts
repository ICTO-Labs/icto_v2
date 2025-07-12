import type { DeploymentRequest } from '../../../declarations/backend/backend.did'

export type { DeploymentRequest };

export interface DeployTokenResponse {
    canisterId: string
    success: boolean
    error?: string
}
