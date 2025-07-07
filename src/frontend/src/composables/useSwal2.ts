// composables/useSwal2.ts
import Swal from 'sweetalert2';

export const useSwal = Swal.mixin({
    customClass: {
        popup: 'custom-font-swal',
        title: 'custom-title-swal',
        confirmButton: 'custom-confirm-btn',
        cancelButton: 'custom-cancel-btn'
    }
});