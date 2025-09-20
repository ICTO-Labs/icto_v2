#!/bin/bash

# ==========================================
# ICTO V2 - Launchpad Sample Data Generator
# ==========================================
# Provides sample data configurations for launchpad testing

# Function to generate timestamps
generate_timestamps() {
    local now_ns=$(($(date +%s) * 1000000000))
    local sale_start_ns=$((now_ns + 86400000000000))    # +1 day
    local sale_end_ns=$((now_ns + 604800000000000))     # +7 days
    local claim_start_ns=$((now_ns + 691200000000000))  # +8 days
    local listing_time_ns=$((now_ns + 777600000000000)) # +9 days

    echo "$now_ns $sale_start_ns $sale_end_ns $claim_start_ns $listing_time_ns"
}

# Simple Launchpad Configuration (minimal viable)
get_simple_launchpad_config() {
    local user_principal="${1:-$(dfx identity get-principal)}"
    local icp_canister="${2:-ryjl3-tyaaa-aaaaa-aaaba-cai}"

    read now_ns sale_start_ns sale_end_ns claim_start_ns listing_time_ns <<< $(generate_timestamps)

    cat <<EOF
record {
    projectInfo = record {
        name = "Simple Test Token";
        description = "A simple test token for basic launchpad testing";
        logo = null;
        banner = null;
        website = null;
        whitepaper = null;
        documentation = null;
        telegram = null;
        twitter = null;
        discord = null;
        github = null;
        isAudited = false;
        auditReport = null;
        isKYCed = false;
        kycProvider = null;
        tags = vec { "Test" };
        category = variant { Other };
        metadata = vec {};
        blockIdRequired = 1000 : nat64;
    };
    saleToken = record {
        canisterId = null;
        symbol = "SIMPLE";
        name = "Simple Test Token";
        decimals = 8 : nat8;
        totalSupply = 100000000000000 : nat;
        transferFee = 10000 : nat;
        logo = null;
        description = null;
        website = null;
        standard = "ICRC-2";
    };
    purchaseToken = record {
        canisterId = opt principal "$icp_canister";
        symbol = "ICP";
        name = "Internet Computer";
        decimals = 8 : nat8;
        totalSupply = 0 : nat;
        transferFee = 10000 : nat;
        logo = null;
        description = null;
        website = null;
        standard = "ICRC-2";
    };
    saleParams = record {
        saleType = variant { IDO };
        allocationMethod = variant { FirstComeFirstServe };
        totalSaleAmount = 1000000000000 : nat;
        softCap = 100000000000 : nat;
        hardCap = 500000000000 : nat;
        tokenPrice = 10000000 : nat;
        minContribution = 100000000 : nat;
        maxContribution = null;
        maxParticipants = null;
        requiresWhitelist = false;
        requiresKYC = false;
        blockIdRequired = 1000 : nat64;
        restrictedRegions = vec {};
        whitelistMode = variant { OpenRegistration };
        whitelistEntries = vec {};
    };
    timeline = record {
        createdAt = $now_ns : int;
        whitelistStart = null;
        whitelistEnd = null;
        saleStart = $sale_start_ns : int;
        saleEnd = $sale_end_ns : int;
        claimStart = $claim_start_ns : int;
        vestingStart = null;
        listingTime = null;
        daoActivation = null;
    };
    distribution = vec {
        record {
            name = "Sale";
            percentage = 5000 : nat16;
            totalAmount = 50000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                SaleParticipants = record {
                    eligibilityType = variant { ParticipationBased };
                    minContribution = null;
                    distributionMethod = variant { Proportional };
                }
            };
            description = null;
        };
        record {
            name = "Team";
            percentage = 3000 : nat16;
            totalAmount = 30000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                FixedList = vec {
                    record {
                        address = principal "$user_principal";
                        amount = 30000000000000 : nat;
                        description = null;
                        vestingOverride = null;
                    }
                }
            };
            description = null;
        };
        record {
            name = "Reserve";
            percentage = 2000 : nat16;
            totalAmount = 20000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                TreasuryReserve = record {
                    controller = principal "$user_principal";
                    useGovernance = false;
                }
            };
            description = null;
        }
    };
    dexConfig = record {
        enabled = false;
        platform = "ICPSwap";
        listingPrice = 10000000 : nat;
        totalLiquidityToken = 0 : nat;
        initialLiquidityToken = 0 : nat;
        initialLiquidityPurchase = 0 : nat;
        liquidityLockDays = 0 : nat16;
        autoList = false;
        slippageTolerance = 500 : nat16;
        lpTokenRecipient = null;
        fees = record {
            listingFee = 0 : nat;
            transactionFee = 0 : nat16;
        };
    };
    multiDexConfig = null;
    raisedFundsAllocation = record {
        teamAllocation = 5000 : nat16;
        developmentFund = 3000 : nat16;
        marketingFund = 1000 : nat16;
        liquidityFund = 1000 : nat16;
        reserveFund = 0 : nat16;
        teamRecipients = vec {
            record {
                principal = principal "$user_principal";
                percentage = 10000 : nat16;
                vestingSchedule = null;
                description = null;
            }
        };
        developmentRecipients = vec {};
        marketingRecipients = vec {};
        customAllocations = vec {};
    };
    affiliateConfig = record {
        enabled = false;
        commissionRate = 0 : nat16;
        maxTiers = 0 : nat8;
        tierRates = vec {};
        minPurchaseForCommission = 0 : nat;
        paymentToken = "ICP";
        vestingSchedule = null;
    };
    governanceConfig = record {
        enabled = false;
        daoCanisterId = null;
        votingToken = "SIMPLE";
        proposalThreshold = 0 : nat;
        quorumPercentage = 0 : nat16;
        votingPeriod = 0 : int;
        timelockDuration = 0 : int;
        emergencyContacts = vec {};
        initialGovernors = vec {};
        autoActivateDAO = false;
    };
    whitelist = vec {};
    blacklist = vec {};
    adminList = vec { principal "$user_principal" };
    emergencyContacts = vec { principal "$user_principal" };
    pausable = true;
    cancellable = true;
    platformFeeRate = 250 : nat16;
    successFeeRate = 500 : nat16;
}
EOF
}

# Advanced Launchpad Configuration (full features)
get_advanced_launchpad_config() {
    local user_principal="${1:-$(dfx identity get-principal)}"
    local icp_canister="${2:-ryjl3-tyaaa-aaaaa-aaaba-cai}"

    read now_ns sale_start_ns sale_end_ns claim_start_ns listing_time_ns <<< $(generate_timestamps)

    cat <<EOF
record {
    projectInfo = record {
        name = "Advanced DeFi Token";
        description = "An advanced DeFi token with comprehensive launchpad features including vesting, governance, and multi-DEX liquidity";
        logo = opt "https://example.com/advanced-logo.png";
        banner = opt "https://example.com/advanced-banner.png";
        website = opt "https://advanceddefi.example.com";
        whitepaper = opt "https://advanceddefi.example.com/whitepaper.pdf";
        documentation = opt "https://docs.advanceddefi.example.com";
        telegram = opt "https://t.me/advanceddefi";
        twitter = opt "https://twitter.com/advanceddefi";
        discord = opt "https://discord.gg/advanceddefi";
        github = opt "https://github.com/advanceddefi";
        isAudited = true;
        auditReport = opt "https://advanceddefi.example.com/audit.pdf";
        isKYCed = true;
        kycProvider = opt "ExampleKYC";
        tags = vec { "DeFi"; "Governance"; "Yield"; "Advanced" };
        category = variant { DeFi };
        metadata = vec {
            ("website", "https://advanceddefi.example.com");
            ("audit_score", "95");
            ("security_rating", "A+");
        };
        blockIdRequired = 1000 : nat64;
    };
    saleToken = record {
        canisterId = null;
        symbol = "ADFI";
        name = "Advanced DeFi Token";
        decimals = 8 : nat8;
        totalSupply = 1000000000000000 : nat;
        transferFee = 10000 : nat;
        logo = opt "https://example.com/adfi-logo.png";
        description = opt "Governance and utility token for Advanced DeFi protocol";
        website = opt "https://advanceddefi.example.com";
        standard = "ICRC-2";
    };
    purchaseToken = record {
        canisterId = opt principal "$icp_canister";
        symbol = "ICP";
        name = "Internet Computer";
        decimals = 8 : nat8;
        totalSupply = 0 : nat;
        transferFee = 10000 : nat;
        logo = opt "https://cryptologos.cc/logos/internet-computer-icp-logo.png";
        description = opt "Internet Computer Protocol token";
        website = opt "https://internetcomputer.org";
        standard = "ICRC-2";
    };
    saleParams = record {
        saleType = variant { IDO };
        allocationMethod = variant { ProRata };
        totalSaleAmount = 20000000000000 : nat;
        softCap = 2000000000000 : nat;
        hardCap = 10000000000000 : nat;
        tokenPrice = 50000000 : nat;
        minContribution = 500000000 : nat;
        maxContribution = opt 2000000000000 : opt nat;
        maxParticipants = opt 500 : opt nat;
        requiresWhitelist = true;
        requiresKYC = true;
        blockIdRequired = 1000 : nat64;
        restrictedRegions = vec { "US"; "CN" };
        whitelistMode = variant { Closed };
        whitelistEntries = vec {
            record {
                principal = principal "$user_principal";
                allocation = opt 1000000000000 : opt nat;
                tier = opt 1 : opt nat8;
                registeredAt = opt $now_ns : opt int;
                approvedAt = opt $now_ns : opt int;
            }
        };
    };
    timeline = record {
        createdAt = $now_ns : int;
        whitelistStart = opt $((now_ns + 43200000000000)) : opt int;
        whitelistEnd = opt $((now_ns + 86400000000000)) : opt int;
        saleStart = $sale_start_ns : int;
        saleEnd = $sale_end_ns : int;
        claimStart = $claim_start_ns : int;
        vestingStart = opt $claim_start_ns : opt int;
        listingTime = opt $listing_time_ns : opt int;
        daoActivation = opt $((listing_time_ns + 86400000000000)) : opt int;
    };
    distribution = vec {
        record {
            name = "IDO Sale";
            percentage = 2000 : nat16;
            totalAmount = 200000000000000 : nat;
            vestingSchedule = opt record {
                duration = 15552000000000000 : int;
                initialUnlock = 2500 : nat16;
                cliff = 2592000000000000 : int;
                frequency = variant { Monthly };
            };
            recipients = variant {
                SaleParticipants = record {
                    eligibilityType = variant { WhitelistBased };
                    minContribution = opt 500000000 : opt nat;
                    distributionMethod = variant { ProRata };
                }
            };
            description = opt "Tokens sold in IDO with vesting";
        };
        record {
            name = "Team & Advisors";
            percentage = 1500 : nat16;
            totalAmount = 150000000000000 : nat;
            vestingSchedule = opt record {
                duration = 31536000000000000 : int;
                initialUnlock = 0 : nat16;
                cliff = 15552000000000000 : int;
                frequency = variant { Monthly };
            };
            recipients = variant {
                FixedList = vec {
                    record {
                        address = principal "$user_principal";
                        amount = 100000000000000 : nat;
                        description = opt "Team allocation";
                        vestingOverride = null;
                    };
                    record {
                        address = principal "$user_principal";
                        amount = 50000000000000 : nat;
                        description = opt "Advisors allocation";
                        vestingOverride = opt record {
                            duration = 15552000000000000 : int;
                            initialUnlock = 1000 : nat16;
                            cliff = 7776000000000000 : int;
                            frequency = variant { Monthly };
                        };
                    }
                }
            };
            description = opt "Team and advisor tokens with long vesting";
        };
        record {
            name = "Liquidity Mining";
            percentage = 2500 : nat16;
            totalAmount = 250000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                Staking = record {
                    stakingContract = null;
                    rewardDuration = 31536000000000000 : int;
                    autoStake = false;
                }
            };
            description = opt "Tokens for liquidity mining rewards";
        };
        record {
            name = "DEX Liquidity";
            percentage = 1500 : nat16;
            totalAmount = 150000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                LiquidityPool = record {
                    platform = "ICPSwap";
                    lockDuration = 31536000000000000 : int;
                    autoProvide = true;
                }
            };
            description = opt "Tokens for DEX liquidity provision";
        };
        record {
            name = "Treasury & Governance";
            percentage = 1500 : nat16;
            totalAmount = 150000000000000 : nat;
            vestingSchedule = null;
            recipients = variant {
                TreasuryReserve = record {
                    controller = principal "$user_principal";
                    useGovernance = true;
                }
            };
            description = opt "Treasury reserves controlled by DAO";
        };
        record {
            name = "Ecosystem Fund";
            percentage = 1000 : nat16;
            totalAmount = 100000000000000 : nat;
            vestingSchedule = opt record {
                duration = 63072000000000000 : int;
                initialUnlock = 500 : nat16;
                cliff = 7776000000000000 : int;
                frequency = variant { Quarterly };
            };
            recipients = variant {
                FixedList = vec {
                    record {
                        address = principal "$user_principal";
                        amount = 100000000000000 : nat;
                        description = opt "Ecosystem development fund";
                        vestingOverride = null;
                    }
                }
            };
            description = opt "Fund for ecosystem development and partnerships";
        }
    };
    dexConfig = record {
        enabled = true;
        platform = "ICPSwap";
        listingPrice = 60000000 : nat;
        totalLiquidityToken = 150000000000000 : nat;
        initialLiquidityToken = 150000000000000 : nat;
        initialLiquidityPurchase = 9000000000000 : nat;
        liquidityLockDays = 730 : nat16;
        autoList = true;
        slippageTolerance = 200 : nat16;
        lpTokenRecipient = opt principal "$user_principal";
        fees = record {
            listingFee = 500000000 : nat;
            transactionFee = 300 : nat16;
        };
    };
    multiDexConfig = opt record {
        platforms = vec {
            record {
                id = "icpswap";
                name = "ICPSwap";
                enabled = true;
                allocationPercentage = 6000 : nat16;
                calculatedTokenLiquidity = 90000000000000 : nat;
                calculatedPurchaseLiquidity = 5400000000000 : nat;
                fees = record {
                    listing = 300000000 : nat;
                    transaction = 300 : nat16;
                };
            };
            record {
                id = "sonic";
                name = "Sonic DEX";
                enabled = true;
                allocationPercentage = 4000 : nat16;
                calculatedTokenLiquidity = 60000000000000 : nat;
                calculatedPurchaseLiquidity = 3600000000000 : nat;
                fees = record {
                    listing = 200000000 : nat;
                    transaction = 250 : nat16;
                };
            }
        };
        totalLiquidityAllocation = 150000000000000 : nat;
        distributionStrategy = variant { Weighted };
    };
    raisedFundsAllocation = record {
        teamAllocation = 2000 : nat16;
        developmentFund = 4000 : nat16;
        marketingFund = 1500 : nat16;
        liquidityFund = 2000 : nat16;
        reserveFund = 500 : nat16;
        teamRecipients = vec {
            record {
                principal = principal "$user_principal";
                percentage = 7000 : nat16;
                vestingSchedule = opt record {
                    duration = 15552000000000000 : int;
                    initialUnlock = 1000 : nat16;
                    cliff = 2592000000000000 : int;
                    frequency = variant { Monthly };
                };
                description = opt "Core team fund allocation";
            };
            record {
                principal = principal "$user_principal";
                percentage = 3000 : nat16;
                vestingSchedule = null;
                description = opt "Operations fund allocation";
            }
        };
        developmentRecipients = vec {
            record {
                principal = principal "$user_principal";
                percentage = 10000 : nat16;
                vestingSchedule = null;
                description = opt "Development and R&D fund";
            }
        };
        marketingRecipients = vec {
            record {
                principal = principal "$user_principal";
                percentage = 10000 : nat16;
                vestingSchedule = null;
                description = opt "Marketing and community fund";
            }
        };
        customAllocations = vec {
            record {
                name = "Partnership Fund";
                percentage = 1000 : nat16;
                recipients = vec {
                    record {
                        principal = principal "$user_principal";
                        percentage = 10000 : nat16;
                        vestingSchedule = null;
                        description = opt "Strategic partnerships";
                    }
                };
                vestingSchedule = null;
                description = opt "Fund for strategic partnerships and integrations";
            }
        };
    };
    affiliateConfig = record {
        enabled = true;
        commissionRate = 500 : nat16;
        maxTiers = 3 : nat8;
        tierRates = vec { 500 : nat16; 300 : nat16; 200 : nat16 };
        minPurchaseForCommission = 1000000000 : nat;
        paymentToken = "ADFI";
        vestingSchedule = opt record {
            duration = 7776000000000000 : int;
            initialUnlock = 2500 : nat16;
            cliff = 2592000000000000 : int;
            frequency = variant { Monthly };
        };
    };
    governanceConfig = record {
        enabled = true;
        daoCanisterId = null;
        votingToken = "ADFI";
        proposalThreshold = 10000000000000 : nat;
        quorumPercentage = 4000 : nat16;
        votingPeriod = 604800000000000 : int;
        timelockDuration = 259200000000000 : int;
        emergencyContacts = vec {
            principal "$user_principal"
        };
        initialGovernors = vec {
            principal "$user_principal"
        };
        autoActivateDAO = true;
    };
    whitelist = vec { principal "$user_principal" };
    blacklist = vec {};
    adminList = vec { principal "$user_principal" };
    emergencyContacts = vec {
        principal "$user_principal"
    };
    pausable = true;
    cancellable = true;
    platformFeeRate = 250 : nat16;
    successFeeRate = 300 : nat16;
}
EOF
}

# Export functions for use in other scripts
export -f get_simple_launchpad_config
export -f get_advanced_launchpad_config
export -f generate_timestamps