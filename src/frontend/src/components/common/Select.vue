<!-- Select.vue -->
<template>
    <Listbox :model-value="modelValue" @update:model-value="$emit('update:modelValue', $event)" :disabled="disabled"
        :multiple="multiple">
        <div class="relative">
            <!-- Select Button -->
            <ListboxButton :class="[
                'relative cursor-default rounded-md bg-white pl-3 pr-10 text-left border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 sm:text-sm',
                disabled ? 'opacity-50 cursor-not-allowed bg-gray-50' : 'hover:border-gray-400 transition-colors duration-200',
                error ? 'border-red-300 focus:border-red-500 focus:ring-red-500' : '',
                width === 'auto' ? 'w-auto min-w-fit' : width === 'full' ? 'w-full' : `w-${width}`,
                !noShadow && 'shadow-sm',
                customButtonClass,
                size === 'sm' ? 'py-1.5' : size === 'lg' ? 'py-2.5' : size === 'xs' ? 'py-1' : 'py-2'
            ]" :style="customWidth ? { width: customWidth } : {}">
                <span class="block" :class="!selectedLabel && 'text-gray-400'">
                    {{ selectedLabel || placeholder }}
                </span>
                <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
                    <ChevronsUpDownIcon class="h-5 w-5 text-gray-400" aria-hidden="true" />
                </span>
            </ListboxButton>

            <!-- Error message -->
            <p v-if="error" class="mt-1 text-sm text-red-600">{{ error }}</p>

            <!-- Dropdown -->
            <transition leave-active-class="transition duration-100 ease-in" leave-from-class="opacity-100"
                leave-to-class="opacity-0" enter-active-class="transition duration-100 ease-out"
                enter-from-class="opacity-0" enter-to-class="opacity-100">
                <ListboxOptions :class="[
                    'absolute z-10 mt-1 max-h-60 overflow-auto rounded-md bg-white py-1 text-base border border-gray-200 focus:outline-none sm:text-sm',
                    width === 'auto' || customWidth ? 'w-auto min-w-full' : 'w-full',
                    !noShadow && 'shadow-lg',
                    dropdownClass
                ]">
                    <template v-if="$slots.default">
                        <slot />
                    </template>
                    <template v-else-if="normalizedOptions.length > 0">
                        <ListboxOption v-for="option in normalizedOptions" v-slot="{ active, selected }"
                            :key="getOptionKey(option)" :value="getOptionValue(option)" :disabled="option.disabled"
                            as="template">
                            <li :class="[
                                active ? 'bg-gray-100 text-gray-900' : 'text-gray-900',
                                option.disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-default',
                                'relative select-none py-2 pl-3 pr-4',
                            ]">
                                <div class="flex items-center">
                                    <span :class="[
                                        selected ? 'font-medium' : 'font-normal',
                                        'block truncate',
                                    ]">
                                        {{ getOptionLabel(option) }}
                                    </span>
                                    <span v-if="selected" class="ml-3 flex-shrink-0 text-blue-600">
                                        <CheckIcon class="h-5 w-5" aria-hidden="true" />
                                    </span>
                                </div>
                            </li>
                        </ListboxOption>
                    </template>
                    <template v-else>
                        <li class="relative cursor-default select-none py-2 pl-3 pr-4 text-gray-700">
                            No options available
                        </li>
                    </template>
                </ListboxOptions>
            </transition>
        </div>
    </Listbox>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
    Listbox,
    ListboxButton,
    ListboxOptions,
    ListboxOption,
} from '@headlessui/vue'
import { CheckIcon, ChevronsUpDownIcon } from 'lucide-vue-next'

// Types
interface Option {
    label: string
    value: any
    disabled?: boolean
}

type OptionValue = string | number | boolean | object
type ModelValue = OptionValue | OptionValue[]

// Props
interface Props {
    modelValue?: ModelValue
    options?: Option[] | string[] | number[]
    placeholder?: string
    disabled?: boolean
    multiple?: boolean
    error?: string
    customButtonClass?: string
    dropdownClass?: string
    size?: 'sm' | 'md' | 'lg' | 'xs'
    // Width control
    width?: 'auto' | 'full' | string
    customWidth?: string
    // Style control
    noShadow?: boolean
    // Props support object options
    labelKey?: string
    valueKey?: string
}

const props = withDefaults(defineProps<Props>(), {
    placeholder: 'Select an option',
    disabled: false,
    multiple: false,
    width: 'full',
    noShadow: false,
    labelKey: 'label',
    valueKey: 'value',
    size: 'md' as const
})

// Emits
interface Emits {
    'update:modelValue': [value: ModelValue]
}

defineEmits<Emits>()

// Computed
const normalizedOptions = computed(() => {
    if (!props.options) return []

    return props.options.map(option => {
        if (typeof option === 'string' || typeof option === 'number') {
            return { label: String(option), value: option }
        }
        if (typeof option === 'object' && option !== null) {
            return {
                label: (option as any)[props.labelKey] || String(option),
                value: (option as any)[props.valueKey] !== undefined
                    ? (option as any)[props.valueKey]
                    : option,
                disabled: (option as any).disabled
            }
        }
        return { label: String(option), value: option }
    })
})

const selectedLabel = computed(() => {
    if (!props.modelValue) return ''

    if (props.multiple && Array.isArray(props.modelValue)) {
        if (props.modelValue.length === 0) return ''
        if (props.modelValue.length === 1) {
            const option = normalizedOptions.value.find(opt =>
                opt.value === (props.modelValue as any[])[0]
            )
            return option?.label || ''
        }
        return `${(props.modelValue as any[]).length} selected`
    }

    const option = normalizedOptions.value.find(opt =>
        opt.value === props.modelValue
    )
    return option?.label || ''
})

// Helper functions
const getOptionKey = (option: Option) => {
    return String(option.value)
}

const getOptionValue = (option: Option) => {
    return option.value
}

const getOptionLabel = (option: Option) => {
    return option.label
}
</script>

<!-- Option.vue (Component riêng để sử dụng trong slot) -->
<!--
  <template>
    <ListboxOption
      v-slot="{ active, selected }"
      :value="value"
      :disabled="disabled"
      as="template"
    >
      <li
        :class="[
          active ? 'bg-indigo-100 text-indigo-900' : 'text-gray-900',
          disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-default',
          'relative select-none py-2 pl-10 pr-4',
        ]"
      >
        <span
          :class="[
            selected ? 'font-medium' : 'font-normal',
            'block truncate',
          ]"
        >
          <slot>{{ label || value }}</slot>
        </span>
        <span
          v-if="selected"
          class="absolute inset-y-0 left-0 flex items-center pl-3 text-indigo-600"
        >
          <CheckIcon class="h-5 w-5" aria-hidden="true" />
        </span>
      </li>
    </ListboxOption>
  </template>
  
  <script setup lang="ts">
  import { ListboxOption } from '@headlessui/vue'
  import { CheckIcon } from '@heroicons/vue/20/solid'
  
  interface Props {
    value: any
    label?: string
    disabled?: boolean
  }
  
  defineProps<Props>()
  </script>
  -->