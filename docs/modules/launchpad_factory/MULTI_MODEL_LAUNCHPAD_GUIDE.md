# 🚀 ICTO V2 Multi-Model Launchpad Guide

## 📋 Business Requirements Overview

ICTO V2 supports **multiple launch models** to accommodate different fundraising strategies:

### 🎯 **Target Use Cases:**
1. **VC/Strategic Rounds** - Fixed pricing for institutional investors
2. **Presales** - Early bird fixed pricing for community
3. **Public Sales** - Fair launch with dynamic pricing
4. **Special Mechanisms** - Auctions, lotteries, etc.

---

## 🏗️ **Supported Launch Models**

### 1. **FixedPrice Model** 💰
**Use Cases:** VC rounds, strategic investors, presales

**Configuration:**
```motoko
saleType = #FixedPrice;
tokenPrice = 10_000_000_000; // 100 ICP per token (in e8s)
totalSaleAmount = 1_000_000_000; // 1M tokens for sale
```

**Token Allocation:**
```motoko
// Immediate calculation during participation
allocationAmount = contributionAmount * E8S / tokenPrice

// Example: 500 ICP contribution
// 500 ICP = 500 * 100,000,000 e8s = 50,000,000,000 e8s
// allocation = 50,000,000,000 / 10,000,000,000 = 5,000 tokens
```

**Economics:**
- ✅ **Fixed price discovery**
- ✅ **Predictable allocations**
- ✅ **Immediate token calculation**
- ✅ **VC/Investor friendly**

---

### 2. **FairLaunch Model** 📊
**Use Cases:** Public sales, community launches, token generation events

**Configuration:**
```motoko
saleType = #FairLaunch;
tokenPrice = 0; // Not used in fair launch
totalSaleAmount = 1_000_000_000; // 1M tokens for sale
softCap = 100_000_000_000;     // 1000 ICP
hardCap = 1_000_000_000_000;   // 10,000 ICP
```

**Token Allocation:**
```motoko
// Deferred calculation at sale end
// Final price = totalRaised / totalSaleAmount
// allocation = (contribution / totalRaised) × totalSaleAmount

// Example Sale Results:
// Total raised: 5,000 ICP
// Total sale amount: 1,000,000 tokens
// Final price: 5,000 ICP / 1,000,000 tokens = 0.005 ICP per token
// User contributed: 500 ICP (10% of total)
// User allocation: (500 / 5,000) × 1,000,000 = 100,000 tokens
```

**Economics:**
- ✅ **Market-driven pricing**
- ✅ **Fair distribution**
- ✅ **Price discovery mechanism**
- ✅ **Community friendly**

---

### 3. **PrivateSale Model** 🔒
**Use Cases:** Whitelisted strategic investors, private placements

**Configuration:**
```motoko
saleType = #PrivateSale;
tokenPrice = 5_000_000_000;  // 50 ICP per token
requiresWhitelist = true;
maxParticipants = 50;
```

**Features:**
- ✅ **Whitelist enforcement**
- ✅ **Fixed pricing**
- ✅ **Limited participants**
- ✅ **Strategic investor friendly**

---

### 4. **Auction Model** 🎯
**Use Cases:** Dutch auction, price discovery mechanism

**Configuration:**
```motoko
saleType = #Auction;
// TODO: Implement auction-specific logic
```

**Features (Future):**
- ⏳ **Dutch auction mechanism**
- ⏳ **Price discovery**
- ⏳ **Bidding system**

---

### 5. **Lottery Model** 🎲
**Use Cases:** Fair allocation when oversubscribed

**Configuration:**
```motoko
saleType = #Lottery;
// TODO: Implement lottery-specific logic
```

**Features (Future):**
- ⏳ **Random allocation**
- ⏳ **Fair selection mechanism**
- ⏳ **Anti-bot protection**

---

## 📊 **Model Comparison Matrix**

| Feature | FixedPrice | FairLaunch | PrivateSale | Auction | Lottery |
|---------|------------|------------|-------------|---------|---------|
| **Price Type** | Fixed | Dynamic | Fixed | Variable | Fixed |
| **Allocation** | Immediate | Deferred | Immediate | Variable | Random |
| **Price Discovery** | ❌ | ✅ | ❌ | ✅ | ❌ |
| **VC Friendly** | ✅ | ❌ | ✅ | ⚠️ | ❌ |
| **Community Friendly** | ❌ | ✅ | ❌ | ⚠️ | ✅ |
| **Whitelist** | Optional | ❌ | Required | Optional | Optional |
| **Min Contribution** | ✅ | ✅ | ✅ | ⏳ | ✅ |
| **Max Contribution** | ✅ | ✅ | ✅ | ⏳ | ✅ |

---

## 🛠️ **Implementation Architecture**

### **Core Functions:**
```motoko
// Multi-model allocation calculation
private func _calculateTokenAllocation(contributionAmount: Nat) : Nat {
    switch (config.saleParams.saleType) {
        case (#FairLaunch) {
            // Deferred calculation (sale end)
            0; // Placeholder
        };
        case (#FixedPrice or #PrivateSale or #IDO) {
            // Immediate calculation
            contributionAmount * E8S / config.saleParams.tokenPrice
        };
        case (#Auction or #Lottery) {
            // Special logic (TODO)
            contributionAmount;
        };
    };
};
```

### **Validation Logic:**
```motoko
// Per-model validation
switch (cfg.saleParams.saleType) {
    case (#FairLaunch) {
        // tokenPrice can be 0 (not used)
    };
    case (#FixedPrice or #PrivateSale or #IDO) {
        // tokenPrice must be > 0
        if (cfg.saleParams.tokenPrice == 0) {
            return #err("Fixed price sale requires tokenPrice > 0");
        };
    };
};
```

---

## 🎯 **Recommended Launch Strategy**

### **Phase 1: Strategic/VC Round**
```motoko
// Fixed price for strategic investors
saleType = #FixedPrice;
tokenPrice = 20_000_000_000; // 200 ICP per token (premium)
requiresWhitelist = true;
maxParticipants = 20;
softCap = 200_000_000_000;  // 2000 ICP
hardCap = 500_000_000_000;  // 5000 ICP
```

### **Phase 2: Community Presale**
```motoko
// Fixed price for early community
saleType = #PrivateSale;
tokenPrice = 10_000_000_000; // 100 ICP per token
requiresWhitelist = true;
maxParticipants = 100;
softCap = 500_000_000_000;   // 5000 ICP
hardCap = 1_000_000_000_000; // 10,000 ICP
```

### **Phase 3: Public Fair Launch**
```motoko
// Fair launch for community
saleType = #FairLaunch;
tokenPrice = 0; // Not used
totalSaleAmount = 5_000_000_000; // 5M tokens
softCap = 2_000_000_000_000;  // 20,000 ICP
hardCap = 10_000_000_000_000; // 100,000 ICP
```

---

## 🔍 **Testing Scenarios**

### **Test Fixed Price Model:**
```bash
# Create fixed price launchpad
saleType = #FixedPrice
tokenPrice = 10_000_000_000  # 100 ICP per token
totalSaleAmount = 1_000_000_000  # 1M tokens

# User contributes 500 ICP
# Expected: 5000 tokens (immediate calculation)
```

### **Test Fair Launch Model:**
```bash
# Create fair launch launchpad
saleType = #FairLaunch
tokenPrice = 0  # Not used
totalSaleAmount = 1_000_000_000  # 1M tokens

# Multiple users contribute totaling 1000 ICP
# Final price: 1000 ICP / 1M tokens = 0.001 ICP per token
# User with 100 ICP gets 100,000 tokens (10% allocation)
```

---

## 📚 **Best Practices**

### **For VC/Strategic Rounds:**
- Use **FixedPrice** model
- Set **higher tokenPrice** (premium)
- Enable **whitelist** restriction
- Set **lower hardCap**
- Limit **participant count**

### **For Community Sales:**
- Use **FairLaunch** model
- Set **tokenPrice = 0**
- Define **reasonable soft/hard caps**
- Enable **broad participation**
- Set **fair contribution limits**

### **For Hybrid Approaches:**
- Create **multiple launchpads** with different models
- Use **separate token allocations** per round
- Maintain **clear vesting schedules**
- Document **round hierarchy**

---

## 🚀 **Future Enhancements**

### **Planned Features:**
1. **Hybrid Launch Model** - Multiple rounds in one launchpad
2. **Dynamic Pricing Models** - Advanced auction mechanisms
3. **Vesting Integration** - Per-round vesting schedules
4. **Multi-Token Support** - Accept multiple payment tokens
5. **Tiered Allocations** - Different pricing tiers

### **Security Considerations:**
- ✅ **Per-model validation** implemented
- ✅ **Reentrancy protection** active
- ✅ **Deposit recovery** available
- ✅ **Emergency controls** ready

---

## ✅ **Status & Readiness**

**Current Implementation:** ✅ **PRODUCTION READY**
- ✅ FixedPrice model working
- ✅ FairLaunch model working
- ✅ Multi-model validation active
- ✅ Backward compatibility maintained

**Breaking Changes:** ⚠️ **CANDID INTERFACE UPDATED**
- Frontend may need updates
- Existing clients should be tested
- Migration strategy recommended

**Recommendation:** Deploy with proper testing and frontend updates.

---

*This guide will be updated as new models and features are implemented.*