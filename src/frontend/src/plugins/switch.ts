import type { App } from 'vue'
import BaseSwitch from '@/components/common/BaseSwitch.vue'

export const SwitchPlugin = {
    install(app: App) {
        app.component('BaseSwitch', BaseSwitch)
    },
}
