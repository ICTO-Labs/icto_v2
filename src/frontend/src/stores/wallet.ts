import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import { Principal } from '@dfinity/principal';
import { getPnpInstance } from '@/config/auth';

const pnp = getPnpInstance();

interface WalletInfo {
  id: string;
  walletName: string;
  logo: string;
  website: string;
  recommended: boolean;
}

export const useWalletStore = defineStore('wallet', () => {
  const principal = ref<Principal | null>(null);
  const isConnecting = ref(false);
  const error = ref<string | null>(null);
  const connectingWalletId = ref<string | null>(null);
  const clickedWalletInfo = ref<WalletInfo | null>(null);
  const searchQuery = ref('');
  const allWallets = ref<WalletInfo[]>([]);

  const isConnected = computed(() => principal.value !== null);

  function loadWallets() {
    const adapters = pnp.getEnabledWallets() || {};
    console.log(adapters)
    allWallets.value = Object.values(adapters)
      .filter((adapter: any) => adapter.enabled !== false)
      .map((adapter: any) => ({ id: adapter.id, walletName: adapter.walletName, logo: adapter.logo || '', website: adapter.website || '', recommended: adapter.id === 'oisy' || false }));
  }

  async function connect(walletId: string) {
    isConnecting.value = true;
    error.value = null;
    connectingWalletId.value = walletId;
    try {
      console.log(`Connecting with ${walletId}...`);
      // Simulate a successful connection
      await new Promise(resolve => setTimeout(resolve, 1000));
      principal.value = Principal.fromText("aaaaa-aa"); // Placeholder principal
      console.log('Wallet connected, principal:', principal.value.toText());
    } catch (e: any) {
      error.value = e.message;
      console.error('Failed to connect wallet:', e);
    } finally {
      isConnecting.value = false;
      connectingWalletId.value = null;
    }
  }

  function disconnect() {
    principal.value = null;
    console.log('Wallet disconnected.');
  }

  function setSearchQuery(query: string) {
    searchQuery.value = query;
  }

  return {
    principal,
    isConnecting,
    error,
    isConnected,
    connectingWalletId,
    clickedWalletInfo,
    searchQuery,
    allWallets,
    connect,
    disconnect,
    loadWallets,
    setSearchQuery
  };
}); 