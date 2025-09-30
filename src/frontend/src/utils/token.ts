import BigNumber from "bignumber.js";

//Convert token amount with decimals to actual amount (e.g. 100000000 -> 1)
export const parseTokenAmount = (amount: number | bigint, decimals = 8) => {
    if (amount !== 0 && !amount) return new BigNumber(0);
    if (typeof amount === "bigint") amount = Number(amount);
    if (typeof decimals === "bigint") decimals = Number(decimals);
    if (Number.isNaN(Number(amount))) return new BigNumber(String(amount));
    return new BigNumber(String(amount)).dividedBy(10 ** Number(decimals));

}
//Convert actual amount to token amount with decimals (e.g. 1 -> 100000000)
export function formatTokenAmount(amount: number | bigint, decimals = 8) {
    let _amount = amount;
    let _decimals = decimals;

    if (_amount !== 0 && !_amount) return new BigNumber(0);
    if (typeof _amount === "bigint") _amount = Number(_amount);
    if (typeof decimals === "bigint") _decimals = Number(_decimals);
    if (Number.isNaN(Number(amount))) return new BigNumber(_amount);
    return new BigNumber(_amount).multipliedBy(10 ** Number(_decimals));
}

//Format token amount with label (e.g. 100000000 -> 1B)
export const formatTokenAmountLabel = (amount: string | number, symbol: string): string => {
    const num = typeof amount === 'string' ? parseFloat(amount) : Number(amount)
    if (isNaN(num)) return '0 ' + symbol
    
    if (num >= 1000000000) {
        return (num / 1000000000).toFixed(1) + 'B ' + symbol
    } else if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M ' + symbol
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K ' + symbol
    }
    return Math.floor(num).toString() + ' ' + symbol
}

export const formatAmount = (amount: number): string => {
    return new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(amount)
}

/**
 * Format token amount with symbol for display (e.g. 119877000000 e8s -> "119,877 TOKEN")
 * @param rawAmount - Raw amount in smallest unit (e.g. e8s for ICP)
 * @param decimals - Number of decimals (default 8)
 * @param symbol - Token symbol (default 'Token')
 * @returns Formatted string with comma separators and symbol
 */
export const formatTokenDisplay = (rawAmount: number | bigint, decimals: number = 8, symbol: string = 'Token'): string => {
    // Convert raw amount to actual amount using decimals
    const parsedAmount = parseTokenAmount(rawAmount, decimals)
    const numValue = parsedAmount.toNumber()

    // Format number with commas and appropriate decimals
    let formattedNumber: string
    if (numValue === 0) {
        formattedNumber = '0'
    } else if (numValue < 0.00001 && numValue > 0) {
        // Very small amounts - show more decimals without commas
        formattedNumber = parsedAmount.toFixed(8).replace(/\.?0+$/, '')
    } else if (numValue < 1) {
        // Small amounts - show up to 6 decimals without commas
        formattedNumber = parsedAmount.toFixed(6).replace(/\.?0+$/, '')
    } else {
        // Normal amounts - show up to 3 decimals with comma separators
        formattedNumber = numValue.toLocaleString('en-US', {
            minimumFractionDigits: 0,
            maximumFractionDigits: 3
        })
    }

    return `${formattedNumber} ${symbol}`
}