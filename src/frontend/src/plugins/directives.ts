import type { App } from 'vue'
import { vAuthRequired } from '@/directives/authRequired'

export function setupDirectives(app: App) {
  app.directive('auth-required', vAuthRequired)
}

export default setupDirectives 