import type { Principal } from "@dfinity/principal";
export default function delay (ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms))
}

export const shortAccount = (accountId: string) => {
    if (!accountId) return accountId;
    return `${accountId.slice(0, 8)}...${accountId.slice(-8)}`;
}
export const shortPrincipal = (principal: string | Principal) => {
    if (!principal) return principal;
    const parts = (
        typeof principal === "string" ? principal : principal.toText()
    ).split("-");
    return `${parts[0]}-${parts[1]}...-${parts.slice(-1)[0]}`;
};

export const copyToClipboard = async (text: string, target: string = "") => {
	try {
		await navigator.clipboard.writeText(text)
	} catch (err) {
		console.log('Failed to copy', err)
	}
}
  // to byte array
export const hex2Bytes = (hex: string): number[] => {
    const bytes = [];
    for (let i = 0; i < hex.length; i += 2) {
        bytes.push(parseInt(hex.substring(i, i + 2), 16));
    }
    return bytes;
}
export const getVariantKey = (obj: Record<string, any>): string | undefined => {
    try {
        const keys = Object.keys(obj);
        return keys.length > 0 ? keys[0] : undefined;
    } catch (error) {
        console.error('Error getting variant key:', error);
        return undefined;
    }
}
export const getFirstLetter = (principal: string | Principal) => {
    return (
        typeof principal === "string" ? principal : principal.toText()
    ).slice(0, 2).toUpperCase();
}

//Extract the key from an object, e.g. { Open: null } -> 'Open'
export const keyToText = (obj: Record<string, any>): string => {
    let keys = Object.keys(obj);
    if (keys.length === 1) {
        return keys[0];
    }
    return '---';
}

//Convert Cycles to T
export const cyclesToT = (cycles: number | bigint) => {
    return (Number(cycles) / 1_000_000_000_000).toFixed(2) + ' T';
}