[bits 32]

clear_vga_screen:
    push es
    push edx
    push ecx
    push ebx

    mov bx, VGA_TEXT_SEG
    mov es, bx
    mov edx, 0x0
    mov ebx, 0x1E002F00
.loop:
    mov [es:edx], ebx
    add edx, 4
    cmp edx, 80 * 25 * 2
    jne .loop

    ; set the cursor back to zero
    mov word [cursor], 0x0

    pop ebx
    pop ecx
    pop edx
    pop es
    ret

print_vga_string:
    push es
    push eax
    push ebx
    push edx

    mov edx, VGA_TEXT_SEG
    mov es, edx

    mov dx, [cursor]

.loop:
    mov al, [ebx]
    cmp al, 0
    je .done
    mov byte [es:edx], al
    add edx, 2
    inc ebx
    jmp .loop
.done:
    mov [cursor], dx

    pop edx
    pop ebx
    pop eax
    pop es
    ret


cursor: dw 0x0