/**
 * Common Input Mask utilities for ICTO system
 * Provides safe and consistent number formatting throughout the application
 */

export interface MaskOptions {
  decimals?: number
  thousands?: string
  decimal?: string
  prefix?: string
  suffix?: string
  allowNegative?: boolean
  min?: number
  max?: number
}

export class InputMask {
  /**
   * Format number with thousands separators and decimal places
   */
  static formatNumber(value: number | string, options: MaskOptions = {}): string {
    const {
      decimals = 0,
      thousands = ',',
      decimal = '.',
      prefix = '',
      suffix = ''
    } = options

    if (value === null || value === undefined || value === '') return ''
    
    const num = typeof value === 'string' ? parseFloat(value.replace(/[^\d.-]/g, '')) : value
    if (isNaN(num)) return ''

    const formatted = num.toLocaleString('en-US', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals
    }).replace(/,/g, thousands)

    return prefix + formatted + suffix
  }

  /**
   * Parse formatted string back to number
   */
  static parseNumber(value: string, options: MaskOptions = {}): number {
    if (!value) return 0
    const cleanValue = value.replace(/[^\d.-]/g, '')
    const num = parseFloat(cleanValue)
    return isNaN(num) ? 0 : num
  }

  /**
   * Token amount formatter (handles large numbers with proper decimals)
   */
  static formatTokenAmount(value: number | string, decimals: number = 8): string {
    return InputMask.formatNumber(value, {
      decimals: decimals,
      thousands: ',',
      decimal: '.'
    })
  }

  /**
   * Currency formatter (for ICP, USDT, etc.)
   */
  static formatCurrency(value: number | string, symbol: string = '', decimals: number = 8): string {
    return InputMask.formatNumber(value, {
      decimals: decimals,
      thousands: ',',
      decimal: '.',
      suffix: symbol ? ` ${symbol}` : ''
    })
  }

  /**
   * Percentage formatter
   */
  static formatPercentage(value: number | string, decimals: number = 2): string {
    return InputMask.formatNumber(value, {
      decimals: decimals,
      thousands: ',',
      decimal: '.',
      suffix: '%'
    })
  }

  /**
   * Input event handler for real-time formatting
   */
  static handleInput(event: Event, options: MaskOptions = {}): string {
    const input = event.target as HTMLInputElement
    const { min, max, allowNegative = false } = options
    
    let value = input.value.replace(/[^\d.-]/g, '')
    
    // Handle negative values
    if (!allowNegative && value.startsWith('-')) {
      value = value.substring(1)
    }
    
    // Parse and validate bounds
    const numValue = parseFloat(value)
    if (!isNaN(numValue)) {
      if (min !== undefined && numValue < min) {
        value = min.toString()
      }
      if (max !== undefined && numValue > max) {
        value = max.toString()
      }
    }
    
    // Format and update input
    const formatted = InputMask.formatNumber(value, options)
    input.value = formatted
    
    return value
  }

  /**
   * Create v-model directive for Vue components
   */
  static createDirective(options: MaskOptions = {}) {
    return {
      mounted(el: HTMLInputElement) {
        el.addEventListener('input', (event) => {
          InputMask.handleInput(event, options)
        })
      },
      beforeUnmount(el: HTMLInputElement) {
        el.removeEventListener('input', InputMask.handleInput)
      }
    }
  }

  /**
   * Safe number validation
   */
  static isValidNumber(value: string | number): boolean {
    if (value === null || value === undefined || value === '') return false
    const num = typeof value === 'string' ? parseFloat(value.replace(/[^\d.-]/g, '')) : value
    return !isNaN(num) && isFinite(num)
  }

  /**
   * Smart number parsing with fallback
   */
  static safeParseNumber(value: string | number, fallback: number = 0): number {
    if (!InputMask.isValidNumber(value)) return fallback
    const num = typeof value === 'string' ? parseFloat(value.replace(/[^\d.-]/g, '')) : value
    return isNaN(num) ? fallback : num
  }

  /**
   * Format large numbers with units (K, M, B, T)
   */
  static formatCompactNumber(value: number | string, decimals: number = 1): string {
    const num = InputMask.safeParseNumber(value)
    const units = ['', 'K', 'M', 'B', 'T']
    let unitIndex = 0
    let scaledNum = Math.abs(num)

    while (scaledNum >= 1000 && unitIndex < units.length - 1) {
      scaledNum /= 1000
      unitIndex++
    }

    const formatted = scaledNum.toFixed(decimals).replace(/\.0+$/, '')
    return (num < 0 ? '-' : '') + formatted + units[unitIndex]
  }

  /**
   * Format duration in seconds to human readable
   */
  static formatDuration(seconds: number): string {
    if (seconds < 60) return `${seconds}s`
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ${Math.floor((seconds % 3600) / 60)}m`
    return `${Math.floor(seconds / 86400)}d ${Math.floor((seconds % 86400) / 3600)}h`
  }
}

// Vue composable for reactive number formatting
export function useInputMask(options: MaskOptions = {}) {
  const formatValue = (value: number | string) => InputMask.formatNumber(value, options)
  const parseValue = (value: string) => InputMask.parseNumber(value, options)
  const isValid = (value: string | number) => InputMask.isValidNumber(value)
  
  return {
    formatValue,
    parseValue,
    isValid,
    handleInput: (event: Event) => InputMask.handleInput(event, options)
  }
}

// Common presets for ICTO system
export const ICTOMasks = {
  tokenAmount: (decimals: number = 8) => ({
    decimals,
    thousands: ',',
    decimal: '.',
    min: 0
  }),
  
  currency: (symbol: string = 'ICP', decimals: number = 8) => ({
    decimals,
    thousands: ',',
    decimal: '.',
    suffix: ` ${symbol}`,
    min: 0
  }),
  
  percentage: (decimals: number = 2) => ({
    decimals,
    thousands: ',',
    decimal: '.',
    suffix: '%',
    min: 0,
    max: 100
  }),
  
  integer: () => ({
    decimals: 0,
    thousands: ',',
    min: 0
  }),
  
  price: (decimals: number = 8) => ({
    decimals,
    thousands: ',',
    decimal: '.',
    min: 0.00000001
  })
}