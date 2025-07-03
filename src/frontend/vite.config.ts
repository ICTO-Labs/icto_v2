import { fileURLToPath, URL } from 'node:url'
import environment from 'vite-plugin-environment';

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueJsx(),
    vueDevTools(),
    environment('all', { prefix: 'VITE_' }),
    environment('all', { prefix: 'DFX_' })
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
  define: {
    'process.env': process.env,
    'process.env.DFX_NETWORK': JSON.stringify(process.env.DFX_NETWORK),
    'process.env.CANISTER_ID_BACKEND': JSON.stringify(process.env.CANISTER_ID_BACKEND),
  },
})
