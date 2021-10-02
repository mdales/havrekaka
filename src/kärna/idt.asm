
ISR_COUNT equ 256
ISR_ENTRY_SIZE equ 8

%macro ISR_GATE_INSTALL 1
    ; assume ebx is set to correct address before we start
    mov eax, isr_%1
    mov word [ebx], ax
    shr eax, 16
    mov word [ebx + 6], ax
    mov word [ebx + 2], CODE_SEG
    mov byte [ebx + 4], 0x0
    mov byte [ebx + 5], 0x8E
    add ebx, 8
%endmacro

; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
build_idt:
    push eax
    push ebx
    push ecx

    ; the table will be put in memory at buffer
    mov ebx, IDT_SPACE
    ; CPU interrupts
    ISR_GATE_INSTALL 0
    ISR_GATE_INSTALL 1
    ISR_GATE_INSTALL 2
    ISR_GATE_INSTALL 3
    ISR_GATE_INSTALL 4
    ISR_GATE_INSTALL 5
    ISR_GATE_INSTALL 6
    ISR_GATE_INSTALL 7
    ISR_GATE_INSTALL 8
    ISR_GATE_INSTALL 9
    ISR_GATE_INSTALL 10
    ISR_GATE_INSTALL 11
    ISR_GATE_INSTALL 12
    ISR_GATE_INSTALL 13
    ISR_GATE_INSTALL 14
    ISR_GATE_INSTALL 15
    ISR_GATE_INSTALL 16
    ISR_GATE_INSTALL 17
    ISR_GATE_INSTALL 18
    ISR_GATE_INSTALL 19
    ISR_GATE_INSTALL 20
    ISR_GATE_INSTALL 21
    ISR_GATE_INSTALL 22
    ISR_GATE_INSTALL 23
    ISR_GATE_INSTALL 24
    ISR_GATE_INSTALL 25
    ISR_GATE_INSTALL 26
    ISR_GATE_INSTALL 27
    ISR_GATE_INSTALL 28
    ISR_GATE_INSTALL 29
    ISR_GATE_INSTALL 30
    ISR_GATE_INSTALL 31
    ; IRQs post remap
    ISR_GATE_INSTALL 32
    ISR_GATE_INSTALL 33
    ISR_GATE_INSTALL 34
    ISR_GATE_INSTALL 35
    ISR_GATE_INSTALL 36
    ISR_GATE_INSTALL 37
    ISR_GATE_INSTALL 38
    ISR_GATE_INSTALL 39
    ISR_GATE_INSTALL 40
    ISR_GATE_INSTALL 41
    ISR_GATE_INSTALL 42
    ISR_GATE_INSTALL 43
    ISR_GATE_INSTALL 44
    ISR_GATE_INSTALL 45
    ISR_GATE_INSTALL 46
    ISR_GATE_INSTALL 47

    ; for the other entries just map them to the generic handler
    mov ecx, ISR_COUNT - (32 + 16)
.loop:
    mov eax, generic_isr
    mov word [ebx], ax
    shr eax, 16
    mov word [ebx + 6], ax
    mov word [ebx + 2], CODE_SEG
    mov byte [ebx + 4], 0x0
    mov byte [ebx + 5], 0x8E
    add ebx, 8
    loop .loop

    lidt [IDT_DESCRIPTOR]

    pop ecx
    pop ebx
    pop eax
    ret


 %macro ISR_NOERRCODE 1
    isr_%1:
        cli
        push byte 0x0
        push byte %1
        jmp non_generic_isr
%endmacro

%macro ISR_ERRCODE 1
    isr_%1:
        cli
        push byte %1
        jmp non_generic_isr
%endmacro

%macro IRQ_HANDLER 2
    isr_%1:
        cli
        push byte 0x0
        push byte %2
        jmp irq_routine
%endmacro

; Generate the first 32 handlers for the CPU
ISR_NOERRCODE 0
ISR_NOERRCODE 1
ISR_NOERRCODE 2
ISR_NOERRCODE 3
ISR_NOERRCODE 4
ISR_NOERRCODE 5
ISR_NOERRCODE 6
ISR_NOERRCODE 7
ISR_ERRCODE 8
ISR_NOERRCODE 9
ISR_ERRCODE 10
ISR_ERRCODE 11
ISR_ERRCODE 12
ISR_ERRCODE 13
ISR_ERRCODE 14
ISR_NOERRCODE 15
ISR_NOERRCODE 16
ISR_NOERRCODE 17
ISR_NOERRCODE 18
ISR_NOERRCODE 19
ISR_NOERRCODE 20
ISR_NOERRCODE 21
ISR_NOERRCODE 22
ISR_NOERRCODE 23
ISR_NOERRCODE 24
ISR_NOERRCODE 25
ISR_NOERRCODE 26
ISR_NOERRCODE 27
ISR_NOERRCODE 28
ISR_NOERRCODE 29
ISR_NOERRCODE 30
ISR_NOERRCODE 31
; Generate the 16 IRQ handlers
IRQ_HANDLER 32, 0
IRQ_HANDLER 33, 1
IRQ_HANDLER 34, 2
IRQ_HANDLER 35, 3
IRQ_HANDLER 36, 4
IRQ_HANDLER 37, 5
IRQ_HANDLER 38, 6
IRQ_HANDLER 39, 7
IRQ_HANDLER 40, 8
IRQ_HANDLER 41, 9
IRQ_HANDLER 42, 10
IRQ_HANDLER 43, 11
IRQ_HANDLER 44, 12
IRQ_HANDLER 45, 13
IRQ_HANDLER 46, 14
IRQ_HANDLER 47, 15

non_generic_isr:
    push ebx

    mov bl, 0
    mov bh, 10
    call set_vga_cursor_position

    mov ebx, INTERRUPT_MSG
    call print_vga_string

    mov byte bl, [esp + 4]
    call print_vga_hex_byte
    mov byte bl, [esp + 5]
    call print_vga_hex_byte
    mov byte bl, [esp + 6]
    call print_vga_hex_byte
    mov byte bl, [esp + 7]
    call print_vga_hex_byte

    mov bx, [cursor]
    add bx, 2
    mov word [cursor], bx

    mov byte bl, [esp + 8]
    call print_vga_hex_byte
    mov byte bl, [esp + 9]
    call print_vga_hex_byte
    mov byte bl, [esp + 10]
    call print_vga_hex_byte
    mov byte bl, [esp + 11]
    call print_vga_hex_byte

    pop ebx
    add esp, 8
    sti
    iret

irq_routine:
    push eax
    push ebx
    push edx

    mov dx, [cursor]
    mov bl, 0
    mov bh, 11
    call set_vga_cursor_position

    ; if it's not the timer interrupt, print it out.
    mov byte al, [esp + 12]
    cmp al, 0
    je .skip

    mov ebx, IRQ_MSG
    call print_vga_string

    mov bl, al
    call print_vga_hex_byte

    cmp al, 1
    jne .skip
    ;  this is the keyboard interrupt, so read the keycode
    in al, 0x60

    mov word bx, [cursor]
    add bx, 2
    mov word [cursor], bx

    mov bl, al
    call print_vga_hex_byte
    

.skip:
    ; clear IRQ!
    call clear_pic

    mov word [cursor], dx

    pop edx
    pop ebx
    pop eax
    add esp, 8
    sti
    iret


generic_isr:
    cli
    push ebx
    mov ebx, INTERRUPT_MSG
    call print_vga_string
    pop ebx
    jmp $
    sti
    iret


INTERRUPT_MSG:
    db " Interrupt called ", 0
IRQ_MSG:
    db " IRQ called ", 0

IDT_DESCRIPTOR: ; to be loaded by instruction lidt
    ; we'll just start with the minimal length
    dw (ISR_COUNT * ISR_ENTRY_SIZE) - 1
    ; we build the table at the end of the file
    dd IDT_SPACE

IDT_SPACE: