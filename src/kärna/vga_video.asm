[bits 32]

; This info will either be a standard VGA mode or a VESA mode. It's assumed that we're
struc video_mode_info_t
    .type               resb 1      ; 0 == text, 1 == graphics
    .width              resw 1
    .height             resw 1
    .framebuffer_ptr    resq 1      ; we'll look silly when 128 bit CPUs are the norm
endstruc

video_mode_info:
    istruc video_mode_info_t
        at video_mode_info_t.type,            db 0
        at video_mode_info_t.width,           dw 80
        at video_mode_info_t.height,          dw 25
        at video_mode_info_t.framebuffer_ptr, dq 0x00000000b8000000
    iend


; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
clear_video_screen:
    push es
    push edx
    push ecx
    push ebx

    mov bx, VESA_SEG
    mov es, bx
    mov edx, 0x0
    mov ebx, 0xFFFFFFFF
.loop:
    mov [es:edx], ebx
    add edx, 4
    cmp edx, 1600 * 1200 * 2
    jne .loop

    ; set the cursor back to zero
    mov word [cursor], 0x0

    pop ebx
    pop ecx
    pop edx
    pop es
    ret
