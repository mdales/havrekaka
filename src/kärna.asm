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

    mov bx, KERNEL_START_MSG
    call print_msg_16

    jmp $

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



KERNEL_START_MSG:
    db "V", 0x84, "lkommen!", 0