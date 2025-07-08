import './assets/main.css'
// Import Swiper styles
import 'swiper/css'
import 'swiper/css/navigation'
import 'swiper/css/pagination'
import 'jsvectormap/dist/jsvectormap.css'
import 'flatpickr/dist/flatpickr.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import VueApexCharts from 'vue3-apexcharts'
import VueSweetalert2 from 'vue-sweetalert2'
import 'sweetalert2/dist/sweetalert2.min.css'
import './assets/custom-swal2.css'
import { setupDirectives } from './plugins/directives'
import TooltipPlugin from '@/plugins/tooltip'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(VueApexCharts as any)
app.use(VueSweetalert2)
app.use(TooltipPlugin)
setupDirectives(app)

app.mount('#app')
