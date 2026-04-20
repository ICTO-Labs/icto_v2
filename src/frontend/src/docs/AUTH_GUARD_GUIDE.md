# Auth Guard System - ICTO V2 Frontend

A flexible authentication guard system that protects actions requiring wallet connection without hardcoding logic everywhere.

## 📋 Overview

We provide 2 main approaches:

1. **`useAuthGuard` Composable** - Flexible and powerful
2. **`v-auth-required` Directive** - Simple and quick

## 🚀 Method 1: useAuthGuard Composable

### Import and Setup
```typescript
import { useAuthGuard } from '@/composables/useAuthGuard'

const { withAuth, createProtectedAction, requireAuth } = useAuthGuard()
```

### 1.1 Using `withAuth()`
```typescript
// Basic usage
const handleTransfer = () => {
    withAuth(async () => {
        // Token transfer logic here
        console.log('Transferring tokens...')
        await transferTokens()
    })
}

// With custom options
const handleStake = () => {
    withAuth(async () => {
        await stakeTokens()
    }, {
        message: 'Please connect your wallet to stake tokens!',
        beforeConnect: () => {
            console.log('Preparing to connect wallet...')
        },
        afterConnect: () => {
            toast.success('Wallet connected! Starting stake...')
        }
    })
}
```

### 1.2 Using `createProtectedAction()`
```typescript
// Create protected version of a function
const protectedSendToken = createProtectedAction(async (amount: number, to: string) => {
    await sendToken(amount, to)
}, {
    message: 'Connect wallet to send tokens!'
})

// Use like a normal function
const handleSend = () => {
    protectedSendToken(100, 'recipient-principal')
}
```

### 1.3 Using `requireAuth()`
```typescript
const handleAction = () => {
    // Simple check
    if (!requireAuth()) {
        return // User not connected
    }
    
    // Perform action
    performAction()
}
```

## 🎯 Method 2: v-auth-required Directive

### Basic usage
```vue
<template>
    <!-- Use with default settings -->
    <button v-auth-required @click="deployToken">
        Deploy Token
    </button>
    
    <!-- Custom message -->
    <button 
        v-auth-required="{ message: 'Please connect your wallet to mint tokens!' }"
        @click="mintTokens"
    >
        Mint Tokens
    </button>
    
    <!-- Disable toast notification -->
    <button 
        v-auth-required="{ showToast: false }"
        @click="burnTokens"
    >
        Burn Tokens
    </button>
    
    <!-- Don't auto-open modal -->
    <button 
        v-auth-required="{ autoOpenModal: false }"
        @click="pauseToken"
    >
        Pause Token
    </button>
</template>
```

## ⚙️ Configuration Options

### AuthGuardOptions Interface
```typescript
interface AuthGuardOptions {
  // Message to show when wallet is not connected
  message?: string                              // Default: 'Please connect your wallet to continue'
  
  // Whether to show toast warning
  showToast?: boolean                           // Default: true
  
  // Custom callback before opening connect modal  
  beforeConnect?: () => void | Promise<void>    // Default: undefined
  
  // Custom callback after successful connection
  afterConnect?: () => void | Promise<void>     // Default: undefined
  
  // Whether to automatically open connect modal
  autoOpenModal?: boolean                       // Default: true
}
```

## 📝 Real-world Examples

### Complete component
```vue
<template>
    <div class="token-actions">
        <!-- Method 1: Composable -->
        <button @click="protectedTransfer" class="btn-primary">
            Transfer (Composable)
        </button>
        
        <!-- Method 2: Directive -->
        <button 
            v-auth-required="{ message: 'Connect wallet to transfer!' }"
            @click="transfer"
            class="btn-secondary"
        >
            Transfer (Directive)
        </button>
        
        <!-- Advanced composable usage -->
        <button @click="advancedStake" class="btn-accent">
            Stake with Analytics
        </button>
    </div>
</template>

<script setup lang="ts">
import { useAuthGuard } from '@/composables/useAuthGuard'
import { analytics } from '@/utils/analytics'

const { withAuth, createProtectedAction } = useAuthGuard()

// Simple transfer function
const transfer = async () => {
    console.log('Transferring tokens...')
    // Transfer logic here
}

// Protected version with composable
const protectedTransfer = () => {
    withAuth(transfer, {
        message: 'Please connect wallet to transfer tokens!',
        afterConnect: () => {
            analytics.track('wallet_connected_for_transfer')
        }
    })
}

// Advanced usage with multiple callbacks
const advancedStake = () => {
    withAuth(async () => {
        await stakeTokens()
        analytics.track('stake_completed')
    }, {
        message: 'Staking requires wallet connection!',
        beforeConnect: () => {
            analytics.track('stake_auth_required')
        },
        afterConnect: () => {
            analytics.track('wallet_connected_for_stake')
            toast.success('Wallet connected! Starting stake...')
        }
    })
}

// Create reusable protected actions
const protectedMint = createProtectedAction(async (amount: number) => {
    await mintTokens(amount)
    analytics.track('tokens_minted', { amount })
})
</script>
```

## 🎨 Styling & UX

### Visual feedback when not connected
```vue
<template>
    <button 
        :class="[
            'btn',
            authStore.isConnected 
                ? 'btn-primary' 
                : 'btn-disabled'
        ]"
        v-auth-required
        @click="performAction"
    >
        <WalletIcon v-if="!authStore.isConnected" class="mr-2" />
        {{ authStore.isConnected ? 'Perform Action' : 'Connect Wallet First' }}
    </button>
</template>
```

## 🔄 Integration with existing codebase

### Migrate from hardcoded logic
```typescript
// ❌ Before (hardcoded)
const handleDeploy = () => {
    if (!authStore.isConnected) {
        toast.warning('Please connect wallet')
        modalStore.open('wallet')
        return
    }
    deployToken()
}

// ✅ After (using auth guard)
const handleDeploy = () => {
    withAuth(deployToken)
}
```

## 🛠️ Best Practices

### 1. Choose the right method
- **Composable**: When you need custom logic, callbacks, or conditional flow
- **Directive**: When you only need simple protection for buttons

### 2. Consistent messaging
```typescript
// Create constants for messages
const AUTH_MESSAGES = {
    DEPLOY: 'Connect wallet to deploy new token!',
    TRANSFER: 'Connect wallet to transfer tokens!', 
    STAKE: 'Connect wallet to stake tokens!',
    MINT: 'Connect wallet to mint tokens!'
}

// Usage
withAuth(deployToken, { message: AUTH_MESSAGES.DEPLOY })
```

### 3. Analytics integration
```typescript
const trackingOptions = {
    beforeConnect: () => analytics.track('auth_required', { action: 'deploy' }),
    afterConnect: () => analytics.track('wallet_connected', { action: 'deploy' })
}

withAuth(deployToken, trackingOptions)
```

### 4. Error handling
```typescript
const safeProtectedAction = () => {
    withAuth(async () => {
        try {
            await riskyOperation()
        } catch (error) {
            toast.error('Operation failed: ' + error.message)
        }
    })
}
```

## 🧪 Testing

### Unit test for protected actions
```typescript
import { vi } from 'vitest'
import { useAuthGuard } from '@/composables/useAuthGuard'

describe('useAuthGuard', () => {
    it('should execute callback when authenticated', async () => {
        const mockCallback = vi.fn()
        const { withAuth } = useAuthGuard()
        
        // Mock authenticated state
        vi.mocked(authStore.isConnected).mockReturnValue(true)
        
        await withAuth(mockCallback)
        
        expect(mockCallback).toHaveBeenCalled()
    })
})
```

---

## 🎯 Summary

Auth Guard System provides 2 flexible ways to protect actions requiring wallet connection:

1. **`useAuthGuard` Composable** - Powerful, flexible, with callbacks
2. **`v-auth-required` Directive** - Simple and quick

Both integrate seamlessly with the existing modal and auth store systems, ensuring consistent UX across the entire application. 