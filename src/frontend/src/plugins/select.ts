import type { App } from 'vue'
import Select from '@/components/common/Select.vue'

// Plugin for global register
export const SelectPlugin = {
    install(app: App) {
        app.component('Select', Select)
    }
}

// Export plugin as default
export default SelectPlugin
