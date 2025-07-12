import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useProgressDialogStore = defineStore('progressDialog', () => {
    const visible = ref(false)
    const steps = ref<string[]>([])
    const currentStep = ref(0)
    const loading = ref(false)
    const error = ref<string | null>(null)
    const title = ref<string>('')
    const subtitle = ref<string>('')
    const onRetryStep = ref<((stepIdx: number) => void) | undefined>(undefined)

    function open(opts: {
        steps: string[],
        title?: string,
        subtitle?: string,
        onRetryStep?: (stepIdx: number) => void
    }) {
        steps.value = opts.steps
        currentStep.value = 0
        loading.value = true
        error.value = null
        title.value = opts.title || ''
        subtitle.value = opts.subtitle || ''
        visible.value = true
        onRetryStep.value = opts.onRetryStep
    }

    function close() {
        visible.value = false
        loading.value = false
        error.value = null
        steps.value = []
        currentStep.value = 0
        title.value = ''
        subtitle.value = ''
        onRetryStep.value = undefined
    }

    function setStep(idx: number) {
        currentStep.value = idx
    }

    function setError(msg: string) {
        error.value = msg
        loading.value = false
    }

    function setLoading(val: boolean) {
        loading.value = val
    }

    function setSteps(newSteps: string[]) {
        steps.value = newSteps
    }

    function setTitle(val: string) {
        title.value = val
    }

    function setSubtitle(val: string) {
        subtitle.value = val
    }

    return {
        visible,
        steps,
        currentStep,
        loading,
        error,
        title,
        subtitle,
        onRetryStep,
        open,
        close,
        setStep,
        setError,
        setLoading,
        setSteps,
        setTitle,
        setSubtitle
    }
}) 