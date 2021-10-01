[org 0x7e00]
[bits 16]

start:
	; Set up real-mode memory map again. In theory stövelrem will have set that up
    ; for us, but who knows what it's doing really, so just set up a few things
    ; briefly, as soon we'll be flipping to protected mode, at which point
    ; we'll be using a totally different map
    mov ax, 0x0
    mov ds, ax

    mov bp, 0x9000
    mov sp, bp

    ; let the world know we made it across
    mov bx, KERNEL_START_MSG
    call print_msg_16

    ; disable the text mode cursor before we jump to protected mode
    ; as we'll be proding VGA directly after that
    mov ah, 0x1
    mov ch, 0x3F
    int 0x10

    ; disable interrupts until we've in protected mode and have set up the
    ; Interrupt Descriptor Table (IDT).
    cli

    ; disable the pic
    ; call disable_pic
    call remap_pic

    ; load the global segment descriptor table
    lgdt [GDT_DESCRIPTOR]

    ; Set the protected mode bit in CR0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Jump into protected mode!
    jmp CODE_SEG:protected_start

print_msg_16:
    push ax
    push bx
    mov ah, 0x0e
.loop:
    mov al, [ds:bx]
    cmp al, 0
    je .done
    int 0x10
    inc bx
    jmp .loop
.done:
    pop bx
    pop ax
    ret

[bits 32]
protected_start:
    ; Set up the protected mode memory model for the kernel
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000
    mov esp, ebp

    ; let the world know we made it this far again
    mov ebx, PROTECTED_START_MSG
    call clear_vga_screen
    call print_vga_string

    ; set up interrupt table and enable interrupts again
    call build_idt
    sti

    mov ebx, PROTECTED_START_MSG
    call print_vga_string

.main:
    hlt
    jmp .main


KERNEL_START_MSG:
    db "V", 0x84, "lkommen!", 0

PROTECTED_START_MSG:
    db "Hej! ", 0

%include "src/kärna/gdt.asm"
%include "src/kärna/vga_text.asm"
%include "src/kärna/pic.asm"
%include "src/kärna/idt.asm" ; <--- currently must be last as we use mem at end of area
