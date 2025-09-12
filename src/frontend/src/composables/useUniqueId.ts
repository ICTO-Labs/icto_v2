import { ref } from 'vue'

let idCounter = 0

/**
 * Composable to generate unique IDs for form elements
 * Prevents ID conflicts when multiple components use the same element types
 */
export function useUniqueId(prefix: string = 'element'): string {
  const id = ref(`${prefix}-${++idCounter}-${Date.now()}`)
  return id.value
}

/**
 * Generate multiple unique IDs with different prefixes
 */
export function useUniqueIds(prefixes: string[]): Record<string, string> {
  const ids: Record<string, string> = {}
  prefixes.forEach(prefix => {
    ids[prefix] = useUniqueId(prefix)
  })
  return ids
}

/**
 * Generate a unique ID for a specific component instance
 * Useful when the same component is used multiple times
 */
export function useComponentId(componentName: string, instanceId?: string | number): string {
  const baseId = instanceId ? `${componentName}-${instanceId}` : componentName
  return useUniqueId(baseId)
}
