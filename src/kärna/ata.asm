[bits 32]

STATUS_BUSY equ 0x80
STATUS_DATA_REQEST equ 0x04

; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
ata_await_busy:
    push eax
.loop:
    inb 0x1F7
    and al, STATUS_BUSY
    jnz .loop

    pop eax
    ret

; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
ata_await_data:
    push eax
.loop:
    inb 0x1F7
    and al, STATUS_DATA_REQEST
    jnz .loop

    pop eax
    ret

; Inputs:
;     eax   = LBA of sector to read
;     bl    - number of sectors to read
;     es:edi - location to write data
; Returns:
;     none
; Clobbers:
;     none
ata_read_sectors:

    cmp bl, 0
    je .early

    push edx
    push ecx
    push ebx
    push eax
    push edi

    call ata_await_busy

    mov ecx, eax
    shr eax, 24
    and eax, 0xF
    or  eax, 0xE0
    outb 0x1F6

    mov al, bl
    outb 0x1F2
    mov eax, ecx
    outb 0x1F3
    shr eax, 8
    outb 0x1F4
    shr eax, 8
    outb 0x1F5
    mov al, 0x20
    outb 0x1F7

.sector_loop:
    call ata_await_busy
    call ata_await_data

    mov ecx, 256
.word_loop:
    inw 0x1F0
    mov [es:edi], ax
    add edi, 2

    sub ecx, 1
    jnz .word_loop

    sub bl, 1
    jnz .sector_loop

    pop edi
    pop eax
    pop ebx
    pop ecx
    pop edx
.early:
    ret
