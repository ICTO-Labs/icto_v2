import { storeToRefs } from 'pinia'
import { useProgressDialogStore } from '@/stores/progressDialog'

export function useProgressDialog() {
  const store = useProgressDialogStore()
  const state = storeToRefs(store)

  function open(opts: { steps: string[], title?: string, subtitle?: string, onRetryStep?: (stepIdx: number) => void }) {
    store.open(opts)
  }

  function close() {
    store.close()
  }

  function nextStep() {
    if (state.currentStep.value < state.steps.value.length - 1) {
      store.setStep(state.currentStep.value + 1)
    }
  }

  function prevStep() {
    if (state.currentStep.value > 0) {
      store.setStep(state.currentStep.value - 1)
    }
  }

  function setStep(idx: number) {
    store.setStep(idx)
  }

  function setError(msg: string) {
    store.setError(msg)
  }

  function setLoading(val: boolean) {
    store.setLoading(val)
  }

  function setSteps(steps: string[]) {
    store.setSteps(steps)
  }

  function setTitle(val: string) {
    store.setTitle(val)
  }

  function setSubtitle(val: string) {
    store.setSubtitle(val)
  }

  return {
    ...state,
    open,
    close,
    nextStep,
    prevStep,
    setStep,
    setError,
    setLoading,
    setSteps,
    setTitle,
    setSubtitle,
    onRetryStep: state.onRetryStep
  }
} 