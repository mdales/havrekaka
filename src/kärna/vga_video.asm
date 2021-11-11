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


; Inputs:
;     eax: unicode character
; Returns:
;     none
; Clobbers:
;     none
print_video_character:
    push es
    push edx
    push edi
    push ebx
    push eax

    ; convert unicode character to a memory address of the glyph
    call bits_for_character
    mov ebx, eax

    mov edx, VESA_SEG
    mov es, edx
    mov edi, 0x0; [cursor]

    ; first pass, hardwire some vals here
    mov cl, 20
.yloop:
    mov ax, [ebx]
    add ebx, 2

    mov ch, 10
.xloop:
    mov dx, ax
    and dx, 0b1000000000
    cmp dx, 0b1000000000
    jne .nothing

    mov word [es:edi], 0x0
.nothing:
    add edi, 2
    shl ax, 1
    sub ch, 1
    jnz .xloop

    add edi, (1590 * 2) ; cough
    sub cl, 1
    jnz .yloop

    mov [cursor], edi

    pop eax
    pop ebx
    pop edi
    pop edx
    pop es
    ret
