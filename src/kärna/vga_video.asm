[bits 32]


; This info will either be a standard VGA mode or a VESA mode. It's assumed that we're
struc video_mode_info_t
    .type               resb 1      ; 0 == text, 1 == graphics
    .width              resw 1
    .height             resw 1
    .bits_per_pixel     resb 1
    .bytes_per_scanline resw 1
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
    push eax

    mov ebx, video_mode_info
    mov eax, 0
    mov ax, [ebx + video_mode_info_t.width]
    mov edx, 0
    mov dx, [ebx + video_mode_info_t.height]
    mul edx
    mov edx, 0
    mov dl, [ebx + video_mode_info_t.bits_per_pixel]
    shr edx, 3
    mul edx

    mov bx, VESA_SEG
    mov es, bx
    mov edx, 0x0
    mov ebx, 0x1E1E1E1E
.loop:
    mov [es:edx], ebx
    add edx, 4
    cmp edx, eax
    jl .loop

    ; set the cursor back to zero
    mov dword [cursor], 0x0

    pop eax
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
    push ecx
    push ebx
    push eax

    ; convert unicode character to a memory address of the glyph
    call bits_for_character
    mov ebx, eax

    mov edx, VESA_SEG
    mov es, edx
    mov edi, [cursor]

    ; first pass, hardwire some vals here
    mov cl, 20
.yloop:
    mov ah, [ebx]
    inc ebx
    mov al, [ebx]
    inc ebx

    mov ch, 10
.xloop:
    mov dx, ax
    and dx, 0x8000
    jz .nothing

    mov byte [es:edi], 0x0
    jmp .post_pixel
.nothing:
    mov byte [es:edi], 0x1E
.post_pixel:
    add edi, 1
    shl ax, 1
    sub ch, 1
    jnz .xloop

    mov eax, video_mode_info
    mov edx, 0
    mov dx, [eax + video_mode_info_t.bytes_per_scanline]
    add edi, edx
    sub edi, 10 ; cough - should be glyth width * bpp
    sub cl, 1
    jnz .yloop

    ; tidy up cursor value. note edx should contain scan line width at this point
    mov eax, edx
    mov edx, 20 ; cough - glyph height
    mul edx
    sub edi, eax
    add edi, 10 ; cough - should be glyph width * bpp
    mov [cursor], edi

    pop eax
    pop ebx
    pop ecx
    pop edi
    pop edx
    pop es
    ret

; Inputs:
;     eax: string to print
; Returns:
;     none
; Clobbers:
;     none
print_video_string:
    push edx
    push ecx
    push ebx
    push eax

    mov ebx, eax

    mov ecx, [ebx]
    add ebx, 4
    mov eax, 0x0
.loop:
    mov edx, 0x0
    mov dl, [ebx]
    inc ebx

    mov dh, dl
    and dh, 0b11000000   ; this needs to be updated to cope with for than 16 bit chars!
    cmp dh, 0b11000000
    jne .print

.unicode:
    mov dh, 0x0
    and dl, 0b00111111
    or eax, edx
    shl eax, 6
    sub ecx, 1
    jnz .loop
    ; unknown, and out of data, so just print a holder
    mov eax, '?'
    call print_vga_character
    jmp .done

.print:
    mov dh, 0x0
    and dl, 0b01111111
    or eax, edx
    call print_video_character
    mov eax, 0x0
    sub ecx, 1
    jnz .loop

.done:
    pop eax
    pop ebx
    pop ecx
    pop edx
    ret

; Inputs:
;     al: cursor x position
;     ah: cursor y position
; Returns:
;     none
; Clobbers:
;     none
set_video_cursor_position:

    push eax
    push ebx
    push ecx
    push edx

    mov ecx, eax ; back up args

    mov ebx, video_mode_info
    mov eax, 0x0
    mov ax, [ebx + video_mode_info_t.bytes_per_scanline]
    mov ebx, 20 ; cough - glyph height
    mul ebx
    mov ebx, 0x0
    mov bl, ch
    mul ebx

    mov ebx, eax
    mov eax, 0x0
    mov al, cl
    mov edx, (1 * 10)
    mul edx
    add eax, ebx

    mov [cursor], eax

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; Inputs:
;     al: byte to print
; Returns:
;     none
; Clobbers:
;     none
print_video_hex_byte:
    push es
    push edx
    push eax

    ; ensure upper bits are clear
    mov dl, al
    mov eax, 0x0
    mov al, dl

    shr al, 4
    add al, '0'
    cmp al, '9'
    jle .byte1
    add al, 0x7
.byte1:
    call print_video_character

    mov al, dl
    and al, 0x0F
    add al, '0'
    cmp al, '9',
    jle .byte2
    add al, 0x7
.byte2:
    call print_video_character

    pop eax
    pop edx
    pop es
    ret

TRIM_SIZE equ 0x20

; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
paint_trim:
    push eax
    push ebx
    push ecx
    push edx
    push es
    push edi

    mov ecx, VESA_SEG
    mov es, ecx

    mov ebx, video_mode_info
    mov eax, 0x0
    mov ax, [ebx + video_mode_info_t.height]
    mov ecx, 0x0
    mov cx, [ebx + video_mode_info_t.bytes_per_scanline]
    mov edx, ecx
    mul edx
    mov edx, ecx

    mov edi, eax
    mov ecx, TRIM_SIZE
.outer_loop:

    sub edi, ecx

    mov eax, 0x0
.inner_loop:

    mov [es:edi], al
    inc edi

    inc eax
    cmp eax, ecx
    jne .inner_loop

    sub edi, edx
    loop .outer_loop

    pop edi
    pop es
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
