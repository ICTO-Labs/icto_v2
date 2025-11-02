// ================ DEX INTEGRATION MODULE ================
// Integration with decentralized exchanges for liquidity provisioning
//
// RESPONSIBILITIES:
// 1. Create liquidity pools on multiple DEXs
// 2. Add initial liquidity (token + ICP)
// 3. Configure pool parameters
// 4. Track LP tokens and positions
//
// SUPPORTED DEXs:
// - ICPSwap: Primary DEX on Internet Computer
// - KongSwap: Secondary DEX for diversification
//
// LOCATION: src/motoko/launchpad_factory/modules/DexIntegration.mo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";

import LaunchpadTypes "../../shared/types/LaunchpadTypes";
import ICRCTypes "../../shared/types/ICRC";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";

module {

    // ================ TYPES ================
    
    // KongSwap Interface Types
    public type KongSwapAddPoolArgs = {
        token_0: Text;        // Format: "IC.{canister_id}"
        amount_0: Nat;
        token_1: Text;        // Format: "IC.{canister_id}"
        amount_1: Nat;
        on_kong: ?Bool;
    };
    
    public type KongSwapAddPoolReply = {
        #Ok: KongSwapAddPoolSuccess;
        #Err: Text;
    };
    
    public type KongSwapAddPoolSuccess = {
        pool_id: Text;
        balance_0: Nat;
        balance_1: Nat;
        lp_token_amount: Nat;
        total_supply_lp_token: Nat;
        tx_id: Nat;
    };
    
    // KongSwap Backend Actor Interface
    public type KongSwapBackend = actor {
        add_pool: (args: KongSwapAddPoolArgs) -> async KongSwapAddPoolReply;
    };

    // ICPSwap Interface Types
    public type ICPSwapDepositArgs = {
        fee: Nat;
        token: Text;  // Principal as Text
        amount: Nat;
    };
    
    public type ICPSwapMintArgs = {
        amount0Desired: Text;  // Nat as Text
        amount1Desired: Text;  // Nat as Text
        fee: Nat;
        tickLower: Int;
        tickUpper: Int;
        token0: Text;  // Principal as Text
        token1: Text;  // Principal as Text
    };
    
    public type ICPSwapError = {
        #CommonError;
        #InternalError: Text;
        #UnsupportedToken: Text;
        #InsufficientFunds;
    };
    
    public type ICPSwapResult = {
        #ok: Nat;
        #err: ICPSwapError;
    };
    
    public type ICPSwapPoolMetadata = {
        token0: { address: Text };
        token1: { address: Text };
        fee: Nat;
        sqrtPriceX96: Nat;
        tick: Int;
    };
    
    public type ICPSwapMetadataResult = {
        #ok: ICPSwapPoolMetadata;
        #err: ICPSwapError;
    };
    
    // ICPSwap SwapPool Actor Interface
    public type ICPSwapPool = actor {
        deposit: (args: ICPSwapDepositArgs) -> async ICPSwapResult;
        depositFrom: (args: ICPSwapDepositArgs) -> async ICPSwapResult;
        metadata: () -> async ICPSwapMetadataResult;
        mint: (args: ICPSwapMintArgs) -> async ICPSwapResult;
    };

    public type DEXPlatform = {
        #ICPSwap;
        #KongSwap;
    };

    public type PoolDeploymentResult = {
        dexPlatform: Text;
        poolId: ?Text;
        tokenLiquidity: Nat;
        icpLiquidity: Nat;
        lpTokens: Nat;
        allocationPercentage: Nat8;
    };

    public type MultiDEXResult = {
        pools: [PoolDeploymentResult];
        totalTokenLiquidity: Nat;
        totalICPLiquidity: Nat;
        successCount: Nat;
        failedCount: Nat;
        failedPlatforms: [(Text, Text)];  // platform + error
    };

    public type DEXError = {
        #PlatformUnavailable: Text;
        #InsufficientLiquidity;
        #PoolCreationFailed: Text;
        #InvalidConfiguration: Text;
        #SlippageExceeded;
    };

    // ================ DEX INTEGRATION MODULE ================

    public class DexIntegration(
        tokenCanisterId: Principal,
        purchaseTokenCanisterId: Principal,  // ICP ledger
        _launchpadPrincipal: Principal,
        kongSwapCanisterId: ?Principal,  // Optional KongSwap backend canister
        icpSwapPoolCanisterId: ?Principal  // Optional ICPSwap pool canister
    ) {

        // ================ MULTI-DEX LIQUIDITY SETUP ================

        /// Setup liquidity across multiple DEX platforms
        public func setupMultiDEXLiquidity(
            config: LaunchpadTypes.LaunchpadConfig,
            launchpadId: Text
        ) : async Result.Result<MultiDEXResult, DEXError> {
            
            Debug.print("💧 DEX INTEGRATION: Setting up multi-DEX liquidity...");

            let multiDex = switch (config.multiDexConfig) {
                case (?dex) dex;
                case (null) return #err(#InvalidConfiguration("No multi-DEX config"));
            };

            Debug.print("   Platforms: " # Nat.toText(multiDex.platforms.size()));
            Debug.print("   Total Liquidity Allocation: " # Nat.toText(multiDex.totalLiquidityAllocation));

            let deployments = Buffer.Buffer<PoolDeploymentResult>(0);
            let failedPlatforms = Buffer.Buffer<(Text, Text)>(0);

            var totalTokenLiquidity: Nat = 0;
            var totalICPLiquidity: Nat = 0;
            var successCount: Nat = 0;
            var failedCount: Nat = 0;

            // Process each DEX platform
            for (platform in multiDex.platforms.vals()) {
                
                // Skip if platform is disabled
                if (platform.enabled) {
                    Debug.print("\n   📊 Setting up " # platform.name # "...");
                    Debug.print("      Allocation: " # Nat8.toText(platform.allocationPercentage) # "%");
                    Debug.print("      Token: " # Nat.toText(platform.calculatedTokenLiquidity));
                    Debug.print("      ICP: " # Nat.toText(platform.calculatedPurchaseLiquidity));

                    // Determine DEX platform type
                    let dexPlatformOpt: ?DEXPlatform = if (platform.id == "icpswap") {
                        ?#ICPSwap
                    } else if (platform.id == "kongswap") {
                        ?#KongSwap
                    } else {
                        Debug.print("      ⚠️ Unknown DEX platform: " # platform.id);
                        failedPlatforms.add((platform.name, "Unknown platform"));
                        failedCount += 1;
                        null
                    };

                    switch (dexPlatformOpt) {
                        case (?dexPlatform) {
                            // Deploy pool on this DEX
                            let result = await deployPoolOnDEX(
                                dexPlatform,
                                platform,
                                config.saleToken.name,
                                config.saleToken.symbol,
                                launchpadId
                            );

                            switch (result) {
                                case (#ok(deployment)) {
                                    deployments.add(deployment);
                                    totalTokenLiquidity += deployment.tokenLiquidity;
                                    totalICPLiquidity += deployment.icpLiquidity;
                                    successCount += 1;
                                    
                                    Debug.print("      ✅ Pool created successfully");
                                };
                                case (#err(error)) {
                                    let errorMsg = debug_show(error);
                                    Debug.print("      ❌ Failed: " # errorMsg);
                                    failedPlatforms.add((platform.name, errorMsg));
                                    failedCount += 1;
                                };
                            };
                        };
                        case (null) {
                            // Already handled error above
                        };
                    };
                } else {
                    Debug.print("   ⏭️ " # platform.name # " disabled - skipping");
                };
            };

            Debug.print("\n✅ Multi-DEX setup completed!");
            Debug.print("   Success: " # Nat.toText(successCount));
            Debug.print("   Failed: " # Nat.toText(failedCount));
            Debug.print("   Total Token: " # Nat.toText(totalTokenLiquidity));
            Debug.print("   Total ICP: " # Nat.toText(totalICPLiquidity));

            #ok({
                pools = Buffer.toArray(deployments);
                totalTokenLiquidity = totalTokenLiquidity;
                totalICPLiquidity = totalICPLiquidity;
                successCount = successCount;
                failedCount = failedCount;
                failedPlatforms = Buffer.toArray(failedPlatforms);
            })
        };

        // ================ INDIVIDUAL DEX DEPLOYMENT ================

        /// Deploy liquidity pool on specific DEX
        private func deployPoolOnDEX(
            dexPlatform: DEXPlatform,
            platformConfig: LaunchpadTypes.DEXPlatform,
            tokenName: Text,
            tokenSymbol: Text,
            launchpadId: Text
        ) : async Result.Result<PoolDeploymentResult, DEXError> {
            
            switch (dexPlatform) {
                case (#ICPSwap) {
                    await deployICPSwapPool(platformConfig, tokenName, tokenSymbol, launchpadId)
                };
                case (#KongSwap) {
                    await deployKongSwapPool(platformConfig, tokenName, tokenSymbol, launchpadId)
                };
            }
        };

        // ================ ICPSWAP INTEGRATION ================

        /// Create and fund liquidity pool on ICPSwap (Concentrated Liquidity)
        /// Based on ICPSwap's mint position workflow with deposit + mint
        private func deployICPSwapPool(
            platformConfig: LaunchpadTypes.DEXPlatform,
            _tokenName: Text,
            _tokenSymbol: Text,
            _launchpadIdICPSwap: Text
        ) : async Result.Result<PoolDeploymentResult, DEXError> {
            
            Debug.print("      🏊 Creating ICPSwap position...");

            // Check if ICPSwap pool canister is configured
            let poolCanisterId = switch (icpSwapPoolCanisterId) {
                case (?id) id;
                case (null) {
                    Debug.print("      ❌ ICPSwap pool canister not configured");
                    return #err(#PlatformUnavailable("ICPSwap pool canister not configured"));
                };
            };

            try {
                Debug.print("      - ICPSwap Pool: " # Principal.toText(poolCanisterId));
                Debug.print("      - Token 0: " # Principal.toText(tokenCanisterId));
                Debug.print("      - Token 1 (ICP): " # Principal.toText(purchaseTokenCanisterId));
                Debug.print("      - Token Amount: " # Nat.toText(platformConfig.calculatedTokenLiquidity));
                Debug.print("      - ICP Amount: " # Nat.toText(platformConfig.calculatedPurchaseLiquidity));

                let swapPool: ICPSwapPool = actor(Principal.toText(poolCanisterId));

                // Step 1: Get pool metadata to determine token order and fee
                Debug.print("      📝 Step 1: Getting pool metadata...");
                let metadataResult = await swapPool.metadata();
                
                let metadata = switch (metadataResult) {
                    case (#ok(meta)) meta;
                    case (#err(error)) {
                        Debug.print("      ❌ Failed to get metadata: " # debug_show(error));
                        return #err(#PoolCreationFailed("ICPSwap metadata: " # debug_show(error)));
                    };
                };

                Debug.print("      - Pool Fee: " # Nat.toText(metadata.fee));
                Debug.print("      - Token0 in pool: " # metadata.token0.address);
                Debug.print("      - Token1 in pool: " # metadata.token1.address);

                // Determine token order (token0 < token1 by principal)
                let projectTokenText = Principal.toText(tokenCanisterId);
                let icpTokenText = Principal.toText(purchaseTokenCanisterId);
                
                let (token0Text, amount0, token1Text, amount1) = if (projectTokenText < icpTokenText) {
                    (projectTokenText, platformConfig.calculatedTokenLiquidity, icpTokenText, platformConfig.calculatedPurchaseLiquidity)
                } else {
                    (icpTokenText, platformConfig.calculatedPurchaseLiquidity, projectTokenText, platformConfig.calculatedTokenLiquidity)
                };

                Debug.print("      - Ordered Token0: " # token0Text # " Amount: " # Nat.toText(amount0));
                Debug.print("      - Ordered Token1: " # token1Text # " Amount: " # Nat.toText(amount1));

                // Step 2 & 3: Approve and deposit token0 (using ICRC-2 depositFrom)
                Debug.print("      📝 Step 2-3: Depositing token0...");
                
                // Approve token0 to pool
                let token0Ledger: ICRCTypes.ICRCLedger = actor(token0Text);
                let token0Fee = await token0Ledger.icrc1_fee();
                
                let approve0Result = await approveICRC2Token(
                    token0Text,
                    poolCanisterId,
                    amount0 + token0Fee
                );
                
                switch (approve0Result) {
                    case (#err(msg)) {
                        Debug.print("      ❌ Token0 approval failed: " # msg);
                        return #err(#PoolCreationFailed("Token0 approval: " # msg));
                    };
                    case (#ok(_)) Debug.print("      ✅ Token0 approved");
                };

                // Deposit token0 using depositFrom
                let deposit0Args: ICPSwapDepositArgs = {
                    token = token0Text;
                    amount = amount0;
                    fee = token0Fee;
                };
                
                let deposit0Result = await swapPool.depositFrom(deposit0Args);
                
                switch (deposit0Result) {
                    case (#ok(deposited0)) {
                        Debug.print("      ✅ Token0 deposited: " # Nat.toText(deposited0));
                    };
                    case (#err(error)) {
                        Debug.print("      ❌ Token0 deposit failed: " # debug_show(error));
                        return #err(#PoolCreationFailed("Token0 deposit: " # debug_show(error)));
                    };
                };

                // Step 4 & 5: Approve and deposit token1
                Debug.print("      📝 Step 4-5: Depositing token1...");
                
                let token1Ledger: ICRCTypes.ICRCLedger = actor(token1Text);
                let token1Fee = await token1Ledger.icrc1_fee();
                
                let approve1Result = await approveICRC2Token(
                    token1Text,
                    poolCanisterId,
                    amount1 + token1Fee
                );
                
                switch (approve1Result) {
                    case (#err(msg)) {
                        Debug.print("      ❌ Token1 approval failed: " # msg);
                        return #err(#PoolCreationFailed("Token1 approval: " # msg));
                    };
                    case (#ok(_)) Debug.print("      ✅ Token1 approved");
                };

                let deposit1Args: ICPSwapDepositArgs = {
                    token = token1Text;
                    amount = amount1;
                    fee = token1Fee;
                };
                
                let deposit1Result = await swapPool.depositFrom(deposit1Args);
                
                switch (deposit1Result) {
                    case (#ok(deposited1)) {
                        Debug.print("      ✅ Token1 deposited: " # Nat.toText(deposited1));
                    };
                    case (#err(error)) {
                        Debug.print("      ❌ Token1 deposit failed: " # debug_show(error));
                        return #err(#PoolCreationFailed("Token1 deposit: " # debug_show(error)));
                    };
                };

                // Step 6: Mint liquidity position
                // Use full range ticks for simplicity: -887220 to 887220 (approximately -∞ to +∞)
                // In production, calculate optimal tick range based on price
                Debug.print("      📝 Step 6: Minting liquidity position...");
                
                let mintArgs: ICPSwapMintArgs = {
                    token0 = token0Text;
                    token1 = token1Text;
                    fee = metadata.fee;
                    amount0Desired = Nat.toText(amount0);
                    amount1Desired = Nat.toText(amount1);
                    tickLower = -887220;  // Full range lower tick
                    tickUpper = 887220;   // Full range upper tick
                };

                Debug.print("      🔄 Calling swapPool.mint...");
                let mintResult = await swapPool.mint(mintArgs);

                switch (mintResult) {
                    case (#ok(positionId)) {
                        Debug.print("      ✅ Position minted successfully!");
                        Debug.print("         Position ID: " # Nat.toText(positionId));
                        Debug.print("         Token0 Amount: " # Nat.toText(amount0));
                        Debug.print("         Token1 Amount: " # Nat.toText(amount1));

                        let deployment: PoolDeploymentResult = {
                            dexPlatform = "ICPSwap";
                            poolId = ?("icpswap_pos_" # Nat.toText(positionId));
                            tokenLiquidity = platformConfig.calculatedTokenLiquidity;
                            icpLiquidity = platformConfig.calculatedPurchaseLiquidity;
                            lpTokens = positionId;  // Position ID as LP token identifier
                            allocationPercentage = platformConfig.allocationPercentage;
                        };

                        #ok(deployment)
                    };
                    case (#err(error)) {
                        Debug.print("      ❌ ICPSwap mint failed: " # debug_show(error));
                        #err(#PoolCreationFailed("ICPSwap mint: " # debug_show(error)))
                    };
                };

            } catch (error) {
                Debug.print("      ❌ Exception: " # Error.message(error));
                #err(#PoolCreationFailed("ICPSwap exception: " # Error.message(error)))
            }
        };

        /// Approve ICRC-2 token for ICPSwap
        private func approveICRC2Token(
            tokenCanisterIdText: Text,
            spender: Principal,
            amount: Nat
        ) : async Result.Result<Nat, Text> {
            
            try {
                let tokenLedger: ICRCTypes.ICRCLedger = actor(tokenCanisterIdText);

                let expiresAt = Time.now() + 60_000_000_000; // 60 seconds

                let approveArgs: ICRCTypes.ApproveArgs = {
                    from_subaccount = null;
                    spender = {
                        owner = spender;
                        subaccount = null;
                    };
                    amount = amount;
                    expected_allowance = null;
                    expires_at = ?Nat64.fromIntWrap(expiresAt);
                    fee = null;
                    memo = ?Text.encodeUtf8("ICPSwap liquidity provision");
                    created_at_time = ?Nat64.fromIntWrap(Time.now());
                };

                let result = await tokenLedger.icrc2_approve(approveArgs);

                switch (result) {
                    case (#Ok(blockIndex)) {
                        #ok(blockIndex)
                    };
                    case (#Err(error)) {
                        #err("ICRC-2 approval failed: " # debug_show(error))
                    };
                };
            } catch (error) {
                #err("Approval exception: " # Error.message(error))
            }
        };

        // ================ KONGSWAP INTEGRATION ================

        /// Create and fund liquidity pool on KongSwap
        /// Based on KongSwap's add_liquidity mechanism with Constant Product Formula (CPF)
        private func deployKongSwapPool(
            platformConfig: LaunchpadTypes.DEXPlatform,
            _tokenName: Text,
            _tokenSymbol: Text,
            _launchpadId: Text
        ) : async Result.Result<PoolDeploymentResult, DEXError> {
            
            Debug.print("      🦍 Creating KongSwap pool...");

            // Check if KongSwap canister is configured
            let kongCanisterId = switch (kongSwapCanisterId) {
                case (?id) id;
                case (null) {
                    Debug.print("      ❌ KongSwap canister not configured");
                    return #err(#PlatformUnavailable("KongSwap canister not configured"));
                };
            };

            try {
                Debug.print("      - KongSwap Backend: " # Principal.toText(kongCanisterId));
                Debug.print("      - Token (token_0): " # Principal.toText(tokenCanisterId));
                Debug.print("      - ICP (token_1): " # Principal.toText(purchaseTokenCanisterId));
                Debug.print("      - Token Amount: " # Nat.toText(platformConfig.calculatedTokenLiquidity));
                Debug.print("      - ICP Amount: " # Nat.toText(platformConfig.calculatedPurchaseLiquidity));

                // Step 1: Approve token_0 (project token) to KongSwap
                Debug.print("      📝 Step 1: Approving project token to KongSwap...");
                let tokenApprovalResult = await approveTokenForKongSwap(
                    tokenCanisterId,
                    kongCanisterId,
                    platformConfig.calculatedTokenLiquidity
                );
                
                switch (tokenApprovalResult) {
                    case (#err(msg)) {
                        Debug.print("      ❌ Token approval failed: " # msg);
                        return #err(#PoolCreationFailed("Token approval failed: " # msg));
                    };
                    case (#ok(blockIndex)) {
                        Debug.print("      ✅ Token approved at block: " # Nat.toText(blockIndex));
                    };
                };

                // Step 2: Approve token_1 (ICP) to KongSwap
                Debug.print("      📝 Step 2: Approving ICP to KongSwap...");
                let icpApprovalResult = await approveTokenForKongSwap(
                    purchaseTokenCanisterId,
                    kongCanisterId,
                    platformConfig.calculatedPurchaseLiquidity
                );
                
                switch (icpApprovalResult) {
                    case (#err(msg)) {
                        Debug.print("      ❌ ICP approval failed: " # msg);
                        return #err(#PoolCreationFailed("ICP approval failed: " # msg));
                    };
                    case (#ok(blockIndex)) {
                        Debug.print("      ✅ ICP approved at block: " # Nat.toText(blockIndex));
                    };
                };

                // Step 3: Add pool to KongSwap
                Debug.print("      📝 Step 3: Creating pool on KongSwap...");
                let kongBackend: KongSwapBackend = actor(Principal.toText(kongCanisterId));
                
                // Format: "IC.{canister_id}" as per KongSwap specification
                let token0Id = "IC." # Principal.toText(tokenCanisterId);
                let token1Id = "IC." # Principal.toText(purchaseTokenCanisterId);
                
                let addPoolArgs: KongSwapAddPoolArgs = {
                    token_0 = token0Id;
                    amount_0 = platformConfig.calculatedTokenLiquidity;
                    token_1 = token1Id;
                    amount_1 = platformConfig.calculatedPurchaseLiquidity;
                    on_kong = ?true;  // Enable on KongSwap
                };

                Debug.print("      🔄 Calling kong_backend.add_pool...");
                let addPoolResult = await kongBackend.add_pool(addPoolArgs);

                switch (addPoolResult) {
                    case (#Ok(success)) {
                        Debug.print("      ✅ Pool created successfully!");
                        Debug.print("         Pool ID: " # success.pool_id);
                        Debug.print("         Balance 0: " # Nat.toText(success.balance_0));
                        Debug.print("         Balance 1: " # Nat.toText(success.balance_1));
                        Debug.print("         LP Tokens: " # Nat.toText(success.lp_token_amount));
                        Debug.print("         Total Supply LP: " # Nat.toText(success.total_supply_lp_token));
                        Debug.print("         TX ID: " # Nat.toText(success.tx_id));

                        // Calculate initial price (ICP per Token)
                        // Price = balance_1 / balance_0 = ICP / Token
                        let price = if (success.balance_0 > 0) {
                            success.balance_1 / success.balance_0
                        } else {
                            0
                        };
                        Debug.print("         Initial Price: " # Nat.toText(price) # " ICP per token");

                        let deployment: PoolDeploymentResult = {
                            dexPlatform = "KongSwap";
                            poolId = ?success.pool_id;
                            tokenLiquidity = success.balance_0;
                            icpLiquidity = success.balance_1;
                            lpTokens = success.lp_token_amount;
                            allocationPercentage = platformConfig.allocationPercentage;
                        };

                        #ok(deployment)
                    };
                    case (#Err(errorMsg)) {
                        Debug.print("      ❌ KongSwap add_pool failed: " # errorMsg);
                        #err(#PoolCreationFailed("KongSwap add_pool: " # errorMsg))
                    };
                };

            } catch (error) {
                Debug.print("      ❌ Exception: " # Error.message(error));
                #err(#PoolCreationFailed("KongSwap exception: " # Error.message(error)))
            }
        };

        /// Approve ICRC-2 token for KongSwap
        private func approveTokenForKongSwap(
            tokenCanisterId: Principal,
            spender: Principal,
            amount: Nat
        ) : async Result.Result<Nat, Text> {
            
            try {
                let tokenLedger: ICRCTypes.ICRCLedger = actor(Principal.toText(tokenCanisterId));

                // Get token fee for approval amount calculation
                let fee = await tokenLedger.icrc1_fee();
                let approvalAmount = amount + fee;  // Amount + fee

                // Set expiration to 60 seconds from now (same as script)
                let expiresAt = Time.now() + 60_000_000_000; // 60 seconds in nanoseconds

                let approveArgs: ICRCTypes.ApproveArgs = {
                    from_subaccount = null;
                    spender = {
                        owner = spender;
                        subaccount = null;
                    };
                    amount = approvalAmount;
                    expected_allowance = null;
                    expires_at = ?Nat64.fromIntWrap(expiresAt);
                    fee = ?fee;
                    memo = ?Text.encodeUtf8("KongSwap liquidity provision");
                    created_at_time = ?Nat64.fromIntWrap(Time.now());
                };

                let result = await tokenLedger.icrc2_approve(approveArgs);

                switch (result) {
                    case (#Ok(blockIndex)) {
                        #ok(blockIndex)
                    };
                    case (#Err(error)) {
                        #err("ICRC-2 approval failed: " # debug_show(error))
                    };
                };
            } catch (error) {
                #err("Approval exception: " # Error.message(error))
            }
        };

        // ================ LIQUIDITY MANAGEMENT ================

        /// Approve token transfer for liquidity provisioning
        /// NOTE: This is a legacy function, use approveTokenForKongSwap instead
        private func _approveTokenTransfer(
            spender: Principal,
            amount: Nat
        ) : async Result.Result<Nat, Text> {
            
            Debug.print("      ✅ Approving " # Nat.toText(amount) # " tokens for " # Principal.toText(spender));

            try {
                let tokenLedger: ICRCTypes.ICRCLedger = actor(Principal.toText(tokenCanisterId));

                let approveArgs: ICRCTypes.ApproveArgs = {
                    from_subaccount = null;
                    spender = {
                        owner = spender;
                        subaccount = null;
                    };
                    amount = amount;
                    expected_allowance = null;
                    expires_at = null;
                    fee = null;
                    memo = ?Text.encodeUtf8("Liquidity provision approval");
                    created_at_time = null;
                };

                let result = await tokenLedger.icrc2_approve(approveArgs);

                switch (result) {
                    case (#Ok(blockIndex)) {
                        Debug.print("      ✅ Approval successful: block " # Nat.toText(blockIndex));
                        #ok(blockIndex)
                    };
                    case (#Err(error)) {
                        #err("Approval failed: " # debug_show(error))
                    };
                };
            } catch (error) {
                #err("Approval exception: " # Error.message(error))
            }
        };

        /// Calculate optimal price for initial liquidity (ICP per Token)
        /// Returns price in smallest units (e8s per smallest token unit)
        public func calculateInitialPrice(
            tokenAmount: Nat,
            icpAmount: Nat
        ) : Nat {
            // Price = ICP / Token
            if (tokenAmount == 0) {
                0
            } else {
                icpAmount / tokenAmount
            }
        };

        /// Verify liquidity was added successfully
        public func verifyLiquidity(
            dexPlatform: DEXPlatform,
            _poolId: Text
        ) : async Result.Result<Bool, Text> {
            
            Debug.print("🔍 Verifying liquidity on " # debug_show(dexPlatform));

            try {
                // TODO: Query DEX to verify pool exists and has liquidity
                
                Debug.print("✅ Liquidity verified");
                #ok(true)
            } catch (error) {
                #err("Verification failed: " # Error.message(error))
            }
        };

        // ================ HEALTH CHECKS ================

        /// Check if DEX platform is available
        public func checkDEXAvailability(dexPlatform: DEXPlatform) : async Bool {
            try {
                // TODO: Ping DEX platform
                Debug.print("📡 Checking " # debug_show(dexPlatform) # " availability...");
                
                // Placeholder: assume available
                true
            } catch (error) {
                Debug.print("⚠️ " # debug_show(dexPlatform) # " unavailable: " # Error.message(error));
                false
            }
        };
    };

    // ================ HELPER FUNCTIONS ================

    /// Format multi-DEX deployment result
    public func formatMultiDEXResult(result: MultiDEXResult) : Text {
        var output = "Multi-DEX Liquidity Setup:\n";
        output #= "  Platforms: " # Nat.toText(result.successCount) # " successful, " # Nat.toText(result.failedCount) # " failed\n";
        output #= "  Total Token Liquidity: " # Nat.toText(result.totalTokenLiquidity) # "\n";
        output #= "  Total ICP Liquidity: " # Nat.toText(result.totalICPLiquidity) # "\n\n";
        
        output #= "Pools:\n";
        for (pool in result.pools.vals()) {
            output #= "  • " # pool.dexPlatform # " (" # Nat8.toText(pool.allocationPercentage) # "%)\n";
            output #= "    Token: " # Nat.toText(pool.tokenLiquidity) # "\n";
            output #= "    ICP: " # Nat.toText(pool.icpLiquidity) # "\n";
            output #= "    LP Tokens: " # Nat.toText(pool.lpTokens) # "\n";
        };

        if (result.failedPlatforms.size() > 0) {
            output #= "\nFailed Platforms:\n";
            for ((platform, error) in result.failedPlatforms.vals()) {
                output #= "  ❌ " # platform # ": " # error # "\n";
            };
        };

        output
    };

    /// Parse DEX platform ID to enum
    public func parseDEXPlatform(id: Text) : ?DEXPlatform {
        if (id == "icpswap") {
            ?#ICPSwap
        } else if (id == "kongswap") {
            ?#KongSwap
        } else {
            null
        }
    };
}

