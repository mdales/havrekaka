; VESA is a funny old thing. We want to use BIOS to query/set modes and
; thus be in real mode or virtual 8086 mode, but to use the linear frame buffer
; rather than bank switching we need to be able to address "high" memory, which
; requires us to be in protected mode. Thus, all the setup code should be run
; before we switch to protected mode

[bits 16]

struc vesa_info_t
    .signature:         resb 4
    .version:           resw 1
    .oem_string_ptr:    resw 2
    .capabilities:      resd 1
    .video_mode_ptr:    resw 2
    .total_memory:      resw 1
endstruc

vesa_info:
    istruc vesa_info_t
        ; don't care
    iend

; Inputs:
;     none
; Returns:
;     ax - VESA version number if found, or 0 if not
; Clobbers:
;     none
check_vesa_version:
    push es
    push di

    mov ax, ds
    mov es, ax
    mov di, vesa_info

    mov ax, 0x4F00
    int 10

    cmp ax, 0x004F
    je .find_version
    mov ax, 0x0
    jmp .done

.find_version:
    mov ax, [di + vesa_info_t.version]

.done:
    pop di
    pop es
    ret
