import { ref, computed } from 'vue'

export interface FieldError {
  field: string
  message: string
}

export function useFieldErrors() {
  const fieldErrors = ref<Record<string, string[]>>({})

  const hasFieldError = (field: string) => {
    return computed(() => {
      const errors = fieldErrors.value[field]
      return errors && errors.length > 0
    })
  }

  const getFieldErrors = (field: string) => {
    return computed(() => {
      return fieldErrors.value[field] || []
    })
  }

  const setFieldError = (field: string, message: string) => {
    if (!fieldErrors.value[field]) {
      fieldErrors.value[field] = []
    }
    fieldErrors.value[field].push(message)
  }

  const setFieldErrors = (field: string, messages: string[]) => {
    fieldErrors.value[field] = [...messages]
  }

  const clearFieldError = (field: string) => {
    delete fieldErrors.value[field]
  }

  const clearAllErrors = () => {
    fieldErrors.value = {}
  }

  const setErrorsFromValidation = (errors: string[], fieldMappings?: Record<string, string>) => {
    clearAllErrors()

    errors.forEach(error => {
      // Try to match error to a specific field
      let matchedField = null

      if (fieldMappings) {
        // Check if any field mapping matches the error
        for (const [fieldName, keywords] of Object.entries(fieldMappings)) {
          if (keywords.some(keyword => error.toLowerCase().includes(keyword.toLowerCase()))) {
            matchedField = fieldName
            break
          }
        }
      }

      // Common field matching patterns
      if (!matchedField) {
        const lowerError = error.toLowerCase()

        if (lowerError.includes('name') && lowerError.includes('project')) {
          matchedField = 'projectName'
        } else if (lowerError.includes('description')) {
          matchedField = 'projectDescription'
        } else if (lowerError.includes('category')) {
          matchedField = 'projectCategory'
        } else if (lowerError.includes('website')) {
          matchedField = 'projectWebsite'
        } else if (lowerError.includes('symbol')) {
          matchedField = 'tokenSymbol'
        } else if (lowerError.includes('supply')) {
          matchedField = 'tokenSupply'
        } else if (lowerError.includes('soft cap')) {
          matchedField = 'softCap'
        } else if (lowerError.includes('hard cap')) {
          matchedField = 'hardCap'
        }
      }

      if (matchedField) {
        setFieldError(matchedField, error)
      } else {
        // If no specific field matched, add to general errors
        setFieldError('general', error)
      }
    })
  }

  const allErrors = computed(() => {
    return Object.entries(fieldErrors.value).reduce((acc, [field, errors]) => {
      if (errors.length > 0) {
        acc[field] = errors
      }
      return acc
    }, {} as Record<string, string[]>)
  })

  const totalErrorCount = computed(() => {
    return Object.values(fieldErrors.value).reduce((total, errors) => total + errors.length, 0)
  })

  return {
    fieldErrors,
    hasFieldError,
    getFieldErrors,
    setFieldError,
    setFieldErrors,
    clearFieldError,
    clearAllErrors,
    setErrorsFromValidation,
    allErrors,
    totalErrorCount
  }
}