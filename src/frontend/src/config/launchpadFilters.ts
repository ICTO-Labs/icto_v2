import type { ProjectStatus } from '@/composables/launchpad/useProjectStatus'

/**
 * Filter Option Configuration
 */
export interface FilterOption {
  value: ProjectStatus | 'all'
  label: string
  description: string
  icon: string
  color: string
  bgClass: string
  textClass: string
  borderClass: string
}

/**
 * Launchpad Filter Options for Homepage
 * Simplified to 7 user-friendly statuses
 */
export const LAUNCHPAD_FILTER_OPTIONS: FilterOption[] = [
  {
    value: 'all',
    label: 'All',
    description: 'Show all launchpads',
    icon: '📋',
    color: 'gray',
    bgClass: 'bg-gray-100 dark:bg-gray-700',
    textClass: 'text-gray-700 dark:text-gray-300',
    borderClass: 'border-gray-300 dark:border-gray-600'
  },
  {
    value: 'Live',
    label: 'Live',
    description: 'Active sales',
    icon: '🚀',
    color: 'blue',
    bgClass: 'bg-blue-100 dark:bg-blue-900',
    textClass: 'text-blue-700 dark:text-blue-300',
    borderClass: 'border-blue-300 dark:border-blue-600'
  },
  {
    value: 'Upcoming',
    label: 'Upcoming',
    description: 'Coming soon',
    icon: '⏰',
    color: 'gray',
    bgClass: 'bg-gray-100 dark:bg-gray-700',
    textClass: 'text-gray-700 dark:text-gray-300',
    borderClass: 'border-gray-300 dark:border-gray-600'
  },
  {
    value: 'Successful',
    label: 'Successful',
    description: 'Soft cap reached',
    icon: '✅',
    color: 'green',
    bgClass: 'bg-green-100 dark:bg-green-900',
    textClass: 'text-green-700 dark:text-green-300',
    borderClass: 'border-green-300 dark:border-green-600'
  },
  {
    value: 'Failed',
    label: 'Failed',
    description: 'Soft cap not reached',
    icon: '❌',
    color: 'red',
    bgClass: 'bg-red-100 dark:bg-red-900',
    textClass: 'text-red-700 dark:text-red-300',
    borderClass: 'border-red-300 dark:border-red-600'
  },
  {
    value: 'Whitelist',
    label: 'Whitelist',
    description: 'Registration open',
    icon: '👥',
    color: 'purple',
    bgClass: 'bg-purple-100 dark:bg-purple-900',
    textClass: 'text-purple-700 dark:text-purple-300',
    borderClass: 'border-purple-300 dark:border-purple-600'
  },
  {
    value: 'Cancelled',
    label: 'Cancelled',
    description: 'Cancelled',
    icon: '🚫',
    color: 'yellow',
    bgClass: 'bg-yellow-100 dark:bg-yellow-900',
    textClass: 'text-yellow-700 dark:text-yellow-300',
    borderClass: 'border-yellow-300 dark:border-yellow-600'
  }
]

/**
 * Get filter option by value
 */
export function getFilterOption(value: ProjectStatus | 'all'): FilterOption {
  return LAUNCHPAD_FILTER_OPTIONS.find(opt => opt.value === value) || LAUNCHPAD_FILTER_OPTIONS[0]
}

/**
 * Filter launchpads by project status
 */
export function filterLaunchpadsByStatus(
  launchpads: any[],
  filterValue: ProjectStatus | 'all'
): any[] {
  if (filterValue === 'all') {
    return launchpads
  }
  
  // This will be used with useProjectStatus composable
  return launchpads.filter(launchpad => {
    // Import and use useProjectStatus to get project status
    // const { projectStatus } = useProjectStatus(computed(() => launchpad))
    // return projectStatus.value === filterValue
    
    // For now, return all (will be implemented in component)
    return true
  })
}

