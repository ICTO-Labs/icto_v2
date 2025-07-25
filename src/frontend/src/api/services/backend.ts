import { DEFAULT_TOKENS } from "@/config/constants";
import { useAuthStore, backendActor } from "@/stores/auth";
import type { Token, TokensByCanisterRequest } from "@/types/token";
import { BackendUtils } from "@/utils/backend";
import type {
    DeploymentRequest,
    DeployTokenResponse,
    UserDeployment,
    ProcessedDeployment,
    DeploymentRecord
} from "@/types/backend";

export class backendService {
    private static tokenFetchCache = new Map<string, { promise: Promise<Token[]>, timestamp: number }>();
    private static priceCache = new Map<string, { price: bigint, timestamp: number }>();
    private static userDeploymentsCache: { deployments: ProcessedDeployment[], timestamp: number } | null = null;
    private static CACHE_TTL = 30000; // 30 seconds cache
    private static PRICE_CACHE_TTL = 60000; // 1 minute cache for prices
    private static USER_DEPLOYMENTS_CACHE_TTL = 60000; // 1 minute cache for user deployments

    public static async getDefaultTokens(canisterIds: string[]) {
        // Validate input
        const validCanisterIds = canisterIds.filter(id => typeof id === 'string' && id.trim().length > 0);

        if (validCanisterIds.length === 0) {
            return [];
        }

        // Create a cache key from sorted canister IDs
        const cacheKey = validCanisterIds.slice().sort().join(',');
        const now = Date.now();

        // Check cache
        const cached = this.tokenFetchCache.get(cacheKey);
        if (cached && (now - cached.timestamp) < this.CACHE_TTL) {
            return cached.promise;
        }
        const allTokens = await backendActor({ anon: true }).getDefaultTokens();
        const serializedTokens = allTokens.map(token => BackendUtils.serializeTokenMetadata(token));

        // Filter out any null/undefined tokens from serialization before further processing
        const validSerializedTokens = serializedTokens.filter((token): token is Token => !!token);

        // Filter the results to only include the requested canister IDs
        const filteredTokens = validSerializedTokens.filter(token =>
            validCanisterIds.includes(token.canisterId.toString())
        );

        return filteredTokens;
    }

    public static async getTokenDeployPrice(serviceName: string = 'token_deployer'): Promise<bigint> {
        const cacheKey = serviceName ?? 'token_deployer';
        const now = Date.now();

        // Check cache first
        const cached = this.priceCache.get(cacheKey);
        if (cached && (now - cached.timestamp) < this.PRICE_CACHE_TTL) {
            return cached.price;
        }

        try {
            const actor = backendActor({ anon: true });
            const result = await actor.getServiceFee(serviceName);
            if (result) {
                const price = result[0] as bigint;
                console.log('price', price);
                // Cache the result
                this.priceCache.set(cacheKey, { price, timestamp: now });
                return price;
            } else {
                console.error('Error getting deploy price:', result);
                // Return default price if error (0.3 ICP in e8s)
                const defaultPrice = BigInt(30000000); // 0.3 ICP
                return defaultPrice;
            }
        } catch (error) {
            console.error('Error calling getServiceFee:', error);
            // Return default price if error
            const defaultPrice = BigInt(30000000); // 0.3 ICP
            return defaultPrice;
        }
    }

    public static async getBackendCanisterId(): Promise<string> {
        // This should return the backend canister principal
        // Get from environment variable or default
        const canisterId = import.meta.env.VITE_BACKEND_CANISTER_ID ||
            import.meta.env.VITE_CANISTER_ID_BACKEND ||
            'rdmx6-jaaaa-aaaah-qcaiq-cai'; // fallback canister ID

        return canisterId;
    }

    public static async deployToken(request: DeploymentRequest): Promise<DeployTokenResponse> {
        const actor = backendActor({ requiresSigning: true });
        console.log('Deploying token with request:', request);
        try {
            const result = await actor.deployToken(request);
            console.log('Deploy token result:', result);
            if ('err' in result) {
                throw new Error(result.err)
            }

            // Clear the deployments cache to ensure fresh data after a new deployment
            this.userDeploymentsCache = null;

            return {
                canisterId: result.ok.canisterId.toString(),
                success: true
            };
        } catch (error) {
            console.error('Error deploying token:', error);
            return {
                canisterId: '',
                success: false,
                error: error as string
            };
        }
    }

    public static async getUserDeployments(forceRefresh = false): Promise<ProcessedDeployment[]> {
        const now = Date.now();
        const authStore = useAuthStore();

        // Return empty array if user is not logged in
        if (!authStore.isConnected) {
            return [];
        }

        // Check cache first unless force refresh is requested
        if (!forceRefresh &&
            this.userDeploymentsCache &&
            (now - this.userDeploymentsCache.timestamp) < this.USER_DEPLOYMENTS_CACHE_TTL) {
            return this.userDeploymentsCache.deployments;
        }

        try {
            const actor = backendActor({ requiresSigning: true });
            const deployments: DeploymentRecord[] = await actor.getCurrentUserDeployments();

            // Process the deployments to make them more frontend-friendly
            const processedDeployments: ProcessedDeployment[] = deployments.map(deployment => {
                // Extract token info from deploymentType if it's a Token deployment
                let tokenInfo = null;
                if ('deploymentType' in deployment && typeof deployment.deploymentType === 'object') {
                    const deployType = deployment.deploymentType;
                    if ('Token' in deployType) {
                        const tokenData = deployType.Token;
                        console.log('tokenData', tokenData)
                        tokenInfo = {
                            name: tokenData.tokenName,
                            symbol: tokenData.tokenSymbol,
                            standard: tokenData.standard,
                            decimals: tokenData.decimals,
                            totalSupply: tokenData.totalSupply.toString(),
                            features: tokenData.features.map(feature => {
                                if (typeof feature === 'object') {
                                    return Object.keys(feature)[0];
                                }
                                return String(feature);
                            })
                        };
                    }
                }

                return {
                    id: deployment.id,
                    canisterId: deployment.canisterId.toString(),
                    name: deployment.metadata?.name || 'Unnamed Deployment',
                    description: deployment.metadata?.description?.[0] || '',
                    deploymentType: this.getDeploymentTypeLabel(deployment.deploymentType),
                    deploymentDetails: deployment.costs,
                    deployedAt: new Date(Number(deployment.deployedAt) / 1000000).toLocaleString(),
                    tokenInfo: tokenInfo
                };
            });

            // Update cache
            this.userDeploymentsCache = {
                deployments: processedDeployments,
                timestamp: now
            };

            return processedDeployments;
        } catch (error) {
            console.error('Error fetching user deployments:', error);
            return [];
        }
    }

    private static getDeploymentTypeLabel(deploymentType: any): string {
        if (typeof deploymentType === 'object') {
            // Check for ServiceType
            if ('TokenDeployer' in deploymentType) return 'Token';
            if ('TemplateDeployer' in deploymentType) return 'Template';
            if ('LaunchpadDeployer' in deploymentType) return 'Launchpad';
            if ('LockDeployer' in deploymentType) return 'Lock';
            if ('DistributionDeployer' in deploymentType) return 'Distribution';

            // Check for DeploymentType
            if ('Token' in deploymentType) return 'Token';
            if ('Lock' in deploymentType) return 'Lock';
            if ('Launchpad' in deploymentType) return 'Launchpad';
            if ('Distribution' in deploymentType) return 'Distribution';
            if ('DAO' in deploymentType) return 'DAO';
        }
        return 'Unknown';
    }
}
