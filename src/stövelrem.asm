[org 0x7c00]
[bits 16]

; at some point we'll be more clever in our build, but for now hard coded
KERNEL_SECTOR_OFFSET equ 3
KERNEL_SECTOR_COUNT equ 7

start:
	; Set up real-mode memory map
    mov ax, 0x0
    mov ds, ax
    mov ss, ax

    mov bp, 0x7c00
    mov sp, bp

    ; Show some sign of life
    mov bx, START_MSG
    call print_msg

    ; now we want to load the real kernel. althought we could do a lot of it
    ; here, setting up the IDT withing 512 bytes is tedious, and I want to keep all the
    ; protected mode setup code together. So we just load the sectors that follow from
    ; the MBR into memory after this and let that start.
    mov bx, cs
	mov es, bx
    mov bx, AFTER_MBR
    call load_sectors

    jc .load_fail

    jmp AFTER_MBR

.load_fail:
    mov bx, LOAD_ERROR_MSG
    call print_msg
    jmp $

load_sectors:
    ; We assumed cx has the count of sectors we want
    ; we assume es:bx is set up to correct target

    ; don't save ax, as we then return
    ; the result of int 13h
    push bx
    push cx
    push dx

    ; set up Cylincer/sector/head
    mov cl, KERNEL_SECTOR_OFFSET
	mov ch, 0
	mov dh, 0
	mov dl, 0

    mov ah, 0x02
    mov al, KERNEL_SECTOR_COUNT
    stc
    int 0x13

    pop dx
    pop cx
    pop bx
    ret

print_msg:
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

START_MSG:
    db "B", 0x94, "rjar... ", 0

LOAD_ERROR_MSG:
    db "Failed to load kärna.bin", 0

times 510-($-$$) db 0
dw 0xaa55

AFTER_MBR: