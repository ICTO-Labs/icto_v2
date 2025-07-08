import HelpTooltip from '@/components/common/HelpTooltip.vue'
import type { App } from 'vue'

export default {
    install: (app: App) => {
        app.component('HelpTooltip', HelpTooltip)
    }
}