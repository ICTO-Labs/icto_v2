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