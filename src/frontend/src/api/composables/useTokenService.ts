import { ref } from 'vue'
import { backend as backendActor } from '../../../../declarations/backend'
import type { 
    TokenConfig,
    DeploymentRequest,
    Result as DeploymentResult 
} from '../../../../declarations/backend/backend.did'
import { Principal } from '@dfinity/principal'

export function useTokenService() {
  const isDeploying = ref(false)
  const error = ref<string | null>(null)

  async function deployToken(config: TokenConfig): Promise<DeploymentResult> {
    isDeploying.value = true
    error.value = null
    
    try {
      // NOTE: This is a simplified request. The real implementation will need a more
      // complete DeploymentConfig and a real Principal.
      const request: DeploymentRequest = {
        tokenConfig: config,
        projectId: [],
        deploymentConfig: {
          tokenOwner: Principal.fromText("aaaaa-aa"), // Placeholder
          enableCycleOps: [],
          minCyclesInDeployer: [],
          cyclesForInstall: [],
          cyclesForArchive: [],
          archiveOptions: [],
        }
      }
      
      const result = await backendActor.deployToken(request)
      if ('err' in result) {
        throw new Error(result.err)
      }
      return result
    } catch (e: any) {
      error.value = e.message
      throw e
    } finally {
      isDeploying.value = false
    }
  }

  return {
    deployToken,
    isDeploying,
    error
  }
} 