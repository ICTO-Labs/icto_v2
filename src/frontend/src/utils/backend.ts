import type { Token, TokenMetrics } from "@/types/token";

export class BackendUtils {
    private static formatOdinToken(value: string): string {
        // Check if this is an ODIN token with bullet separators
        if (value.includes('•') && value.includes('ODIN')) {
            // Split by bullet and keep only the first part and ODIN
            const parts = value.split('•');
            if (parts.length > 2) {
            // Return first part + ODIN (e.g., "GHOSTNODE•ODIN")
            return `${parts[0]}`;
            }
        }
        return value;
        }
    public static formatOdinSymbol(value: string): string {
        // Check if this is an ODIN token with bullet separators
        if (value.includes('•') && value.includes('ODIN')) {
            // Split by bullet and keep only the first part and ODIN
            const parts = value.split('•');
            if (parts.length > 2) {
                // Return first part + ODIN (e.g., "GHOSTNODE•ODIN")
                return `${parts[0]}`;
            }
        }
        return value;
    }
    public static serializeTokenMetadata(response: unknown): Token | null {
        try {
            if (!response || typeof response !== 'object') {
                throw new Error('Invalid token metadata format');
            }

            const data = response as Record<string, unknown>;

            // Determine standards based on boolean flags
            const standards: string[] = [];
            if (this.toBoolean(data.icrc1)) standards.push('ICRC-1');
            if (this.toBoolean(data.icrc2)) standards.push('ICRC-2');
            if (this.toBoolean(data.icrc3)) standards.push('ICRC-3');
            // Add other potential standards if needed

            return {
                name: this.formatOdinToken(this.toString(data.name)),
                symbol: this.formatOdinSymbol(this.toString(data.symbol)),
                fee: this.toNumber(data.fee),
                decimals: this.toNumber(data.decimals),
                standards: standards,
                logoUrl: this.toString(data.logoUrl),
                metrics: this.serializeTokenMetrics(data.metrics) || {
                    price: 0,
                    volume: 0,
                    marketCap: 0,
                    totalSupply: 0,
                },
                canisterId: this.toString(data.canisterId),
            };
        } catch (error) {
            console.error('Error serializing token metadata:', error);
            return null;
        }
    }

    public static toBoolean(value: unknown): boolean {
        if (value === null || value === undefined) return false;
        return Boolean(value);
    }

    public static toString(value: unknown): string {
        if (value === null || value === undefined) return '';
        return String(value);
    }
    public static formatTokenAmount(amount: unknown, decimals: number): string {
        if (amount === null || amount === undefined) return '0';

        try {
            const cleanAmount = this.toString(amount).replace(/_/g, '');
            if (!cleanAmount) return '0';

            return (Number(cleanAmount) / Math.pow(10, decimals)).toString();
        } catch (error) {
            console.error('Error formatting token amount:', error);
            return '0';
        }
    }

    public static toNumber(value: unknown): number {
        if (value === null || value === undefined) return 0;
        return Number(value);
    }

    public static serializeTokenMetrics(metrics: unknown): TokenMetrics | null {
        if (!metrics || typeof metrics !== 'object') {
            return null;
        }

        const data = metrics as Record<string, unknown>;

        return {
            price: this.toNumber(data.price),
            volume: this.toNumber(data.volume),
            marketCap: this.toNumber(data.marketCap),
            totalSupply: this.toNumber(data.totalSupply),
        };
    }
    public static debounce<T extends (...args: any[]) => any>(
        func: T,
        wait: number
    ): (...args: Parameters<T>) => void {
        let timeout: ReturnType<typeof setTimeout>;
    
        return function executedFunction(...args: Parameters<T>) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
    
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
        };
    } 
}