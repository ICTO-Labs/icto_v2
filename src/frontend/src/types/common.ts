export interface DialogType {
    isConfirm: boolean
    title: string
    closeDelay: number
    text: string
    resolve: () => void
}