[bits 32]

scan_pci:
    push eax
    push ebx
    push ecx
    push edx

    mov al, 60
    mov ah, 0
    push eax

    mov ebx, 256
.bus_loop:
    dec ebx

    mov ecx, 32
.device_loop:
    dec ecx

    ; build address
    mov eax, ebx
    shl eax, 5
    or eax, ecx
    shl eax, 11
    or eax, 0x80000000

    ; try to get the vendor ID
    outd 0x0CF8
    ind 0x0CFC
    and eax, 0xFFFF
    cmp eax, 0xFFFF
    je .next

    mov edx, eax

    pop eax
    call set_video_cursor_position
    inc ah
    push eax

    mov al, bl
    call print_video_hex_byte
    mov eax, ':'
    call print_video_character
    mov al, cl
    call print_video_hex_byte
    mov eax, ' '
    call print_video_character
    mov eax, edx
    call print_video_hex_byte
    shr eax, 8
    call print_video_hex_byte
    mov eax, ':'
    call print_video_character

    mov eax, ebx
    shl eax, 5
    or eax, ecx
    shl eax, 11
    or eax, 0x80000002
    outd 0x0CF8
    ind 0x0CFC
    shr eax, 16
    call print_video_hex_byte
    shr eax, 8
    call print_video_hex_byte

    mov eax, ' '
    call print_video_character

    mov eax, ebx
    shl eax, 5
    or eax, ecx
    shl eax, 11
    or eax, 0x80000008
    outd 0x0CF8
    ind 0x0CFC
    call print_video_hex_byte
    shr eax, 8
    call print_video_hex_byte
    shr eax, 8
    call print_video_hex_byte
    shr eax, 8
    call print_video_hex_byte


.next:
    cmp ecx, 0x0
    jne .device_loop

    cmp ebx, 0x0
    jnz .bus_loop

.done:
    pop eax ; clear cursor
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret