<template>
  <div class="relative" ref="dropdownRef">
    <button class="relative flex items-center justify-center text-gray-500 transition-colors bg-white border border-gray-200 rounded-full hover:text-dark-900 h-11 w-11 hover:bg-gray-100 hover:text-gray-700 dark:border-gray-800 dark:bg-gray-900 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-white" @click.prevent="toggleDropdown">
      <span
        :class="{ hidden: !authStore.isConnected, flex: authStore.isConnected }"
        class="absolute right-0 top-0.5 z-1 h-2 w-2 rounded-full bg-success-500"
      >
        <span
          class="absolute inline-flex w-full h-full bg-success-500 rounded-full opacity-75 -z-1 animate-ping"
        ></span>
      </span>
      <WalletIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />

      <!-- <span class="block mr-1 font-medium text-theme-sm">{{ authStore.selectedWalletId }}</span> -->

      <!-- <ChevronDownIcon :class="{ 'rotate-180': dropdownOpen }" /> -->
    </button>

    <!-- Dropdown Start -->
    <div v-if="dropdownOpen"
      class="absolute right-0 mt-[17px] flex w-[260px] flex-col rounded-2xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark">
      <div>
        <span class="block font-medium text-gray-700 text-theme-sm dark:text-gray-400">
          Connected
          <span class="text-xs ml-2 rounded-full px-2 py-0.5 text-theme-xs font-medium bg-success-50 text-success-600 dark:bg-success-500/15 dark:text-success-500" v-if="authStore.isConnected">
            {{ authStore.selectedWalletId }}</span>
        </span>
        <span class="mt-0.5 block text-theme-xs text-gray-500 dark:text-gray-400">
          Principal: {{ authStore.principal }}
          Address: {{ authStore.address }}
        </span>
      </div>

      <ul class="flex flex-col gap-1 pt-4 pb-3 border-b border-gray-200 dark:border-gray-800">
        <li v-for="item in menuItems" :key="item.href">
          <router-link :to="item.href"
            class="flex items-center gap-3 px-3 py-2 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300">
            <!-- SVG icon would go here -->
            <component :is="item.icon" class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
            {{ item.text }}
          </router-link>
        </li>
        <li>
          <button @click="openWalletModal" class="flex w-full items-center gap-3 px-3 py-2 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300">
            <WalletIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
            Connect Wallet
          </button>
        </li>
      </ul>
      <button @click="showDialog = true"
        class="flex items-center gap-3 px-3 py-2 mt-3 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300">
        <LogoutIcon class="text-gray-500 group-hover:text-gray-700 dark:group-hover:text-gray-300" />
        Disconnect
      </button>
    </div>
    <!-- Dropdown End -->
    <AlertDialog
      :is-open="showDialog"
      title="Disconnect Wallet"
      description="Are you sure you want to disconnect your wallet? This action cannot be undone."
      confirmText="Disconnect"
      cancelText="Cancel"
      @close="showDialog = false"
      @confirm="disconnectWallet"
    />

  </div>
</template>

<script setup>
import { UserCircleIcon, ChevronDownIcon, LogoutIcon, SettingsIcon, InfoCircleIcon } from '@/icons'
import { WalletIcon } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useModalStore } from '@/stores/modal'
import AlertDialog from '@/components/common/AlertDialog.vue'
const authStore = useAuthStore()
const modalStore = useModalStore()
const dropdownOpen = ref(false)
const dropdownRef = ref(null)
const showDialog = ref(false)
const menuItems = [
  { href: '/profile', icon: UserCircleIcon, text: 'Edit profile' },
  { href: '/account', icon: SettingsIcon, text: 'Account settings' },
  { href: '/profile', icon: InfoCircleIcon, text: 'Support' },
]

const toggleDropdown = () => {
  dropdownOpen.value = !dropdownOpen.value
}

const closeDropdown = () => {
  dropdownOpen.value = false
}

const disconnectWallet = () => {
  authStore.disconnectWallet()
  closeDropdown()
  modalStore.close('wallet')
}

const handleClickOutside = (event) => {
  if (dropdownRef.value && !dropdownRef.value.contains(event.target)) {
    closeDropdown()
  }
}
const openWalletModal = () => {
  modalStore.open('wallet')
}
onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
