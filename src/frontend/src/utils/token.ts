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