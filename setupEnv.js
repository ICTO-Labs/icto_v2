// setupEnv.js
import fs from "fs";
import path from "path";

function initCanisterEnv() {
    let localCanisters, prodCanisters;
    const localPath = path.resolve(".dfx", "local", "canister_ids.json");
    const prodPath = path.resolve("canister_ids.json");

    // Try to read local canisters
    try {
        if (fs.existsSync(localPath)) {
            localCanisters = JSON.parse(fs.readFileSync(localPath, 'utf8'));
            console.log("✅ Local canister_ids.json loaded successfully");
        } else {
            console.log("⚠️ Local canister_ids.json not found at:", localPath);
        }
    } catch (error) {
        console.error("❌ Error reading local canister_ids.json:", error.message);
    }

    // Try to read production canisters
    try {
        if (fs.existsSync(prodPath)) {
            prodCanisters = JSON.parse(fs.readFileSync(prodPath, 'utf8'));
            console.log("✅ Production canister_ids.json loaded successfully");
        } else {
            console.log("⚠️ Production canister_ids.json not found at:", prodPath);
        }
    } catch (error) {
        console.error("❌ Error reading production canister_ids.json:", error.message);
    }

    const network =
        process.env.DFX_NETWORK ||
        (process.env.NODE_ENV === "production" ? "ic" : "local");

    console.log("🌍 Current network:", network);

    const canisterConfig = network === "local" ? localCanisters : prodCanisters;
    
    if (!canisterConfig) {
        console.error(`❌ No canister configuration found for network: ${network}`);
        return [null, null];
    }

    const localMap = localCanisters
        ? Object.entries(localCanisters).reduce((prev, current) => {
            const [canisterName, canisterDetails] = current;
            if (canisterDetails[network]) {
                prev["VITE_"+canisterName.toUpperCase()+"_CANISTER_ID"] = canisterDetails[network];
            } else {
                console.warn(`⚠️ No ${network} configuration found for canister: ${canisterName}`);
            }
            return prev;
        }, {})
        : undefined;

    const prodMap = prodCanisters
        ? Object.entries(prodCanisters).reduce((prev, current) => {
            const [canisterName, canisterDetails] = current;
            if (canisterDetails[network]) {
                prev["VITE_"+canisterName.toUpperCase()+"_CANISTER_ID"] = canisterDetails[network];
            } else {
                console.warn(`⚠️ No ${network} configuration found for canister: ${canisterName}`);
            }
            return prev;
        }, {})
        : undefined;

    return [localMap, prodMap];
}

const [localCanisters, prodCanisters] = initCanisterEnv();

// Write local environment variables
if (localCanisters && Object.keys(localCanisters).length > 0) {
    const localTemplate = Object.entries(localCanisters).reduce((start, next) => {
        const [key, val] = next;
        if (!start) return `${key}=${val}`;
        return `${start}\n${key}=${val}`;
    }, '');
    
    try {
        fs.writeFileSync("./src/frontend/.env.development", localTemplate);
        console.log("✅ Successfully wrote .env.development");
    } catch (error) {
        console.error("❌ Error writing .env.development:", error.message);
    }
} else {
    console.warn("⚠️ No local canisters found to write to .env.development");
}

// Write production environment variables
if (prodCanisters && Object.keys(prodCanisters).length > 0) {
    const prodTemplate = Object.entries(prodCanisters).reduce((start, next) => {
        const [key, val] = next;
        if (!start) return `${key}=${val}`;
        return `${start}\n${key}=${val}`;
    }, '');
    
    try {
        fs.writeFileSync("./src/frontend/.env", prodTemplate);
        console.log("✅ Successfully wrote .env");
    } catch (error) {
        console.error("❌ Error writing .env:", error.message);
    }
} else {
    console.warn("⚠️ No production canisters found to write to .env");
}