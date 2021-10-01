

ISR_COUNT equ 256
ISR_ENTRY_SIZE equ 8

build_idt:
    pusha

    ; the table will be put in memory at buffer
    mov cx, ISR_COUNT
    mov ebx, IDT_SPACE
.next_idt:
    mov eax, generic_isr
    mov word [bx], ax
    shr eax, 16
    mov word [bx + 6], ax
    mov word [bx + 2], 0x0008
    mov byte [bx + 4], 0x0
    mov byte [bx + 5], 0x8E

    add bx, 8
    loop .next_idt

    lidt [IDT_DESCRIPTOR]

    popa
    ret

generic_isr:
    cli
    pusha

    mov ebx, INTERRUPT_MSG
    call print_vga_string

    popa
    sti
    iret


INTERRUPT_MSG:
    db "Interrpt called ", 0

IDT_DESCRIPTOR: ; to be loaded by instruction lidt
    ; we'll just start with the minimal length
    dw (ISR_COUNT * ISR_ENTRY_SIZE) - 1
    ; we build the table at the end of the file
    dd IDT_SPACE

IDT_SPACE: