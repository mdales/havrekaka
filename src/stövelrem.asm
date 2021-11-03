[org 0x7c00]
[bits 16]

; at some point we'll be more clever in our build, but for now hard coded
CATALOGUE_SECTOR_OFFSET equ 2
CATALOGUE_SECTOR_COUNT equ 1

; The first stage bootloader doesn't really need to understand most of the catalogue. The first
; file entry will be the second stage bootloader, so we can just treat the catalogue header and the
; metadata of the first catalogue entry as the stuff we want. This also means we don't need to worry
; about loading the entire catalogue, as the info we need will be guaranteed to fit within the first
; sector.
struc catalogue_header_t
    ; Catalogue header
    .version                     resd 1
	.catalogue_length_in_sectors resd 1
	.catalogue_entry_count       resd 1

    ; First entry meta data
	.entry_size resw 1
	.dlags      resw 1
	.offset     resq 1
	.length     resq 1
endstruc

start:
    ; at start of day dl should contain the drive number from the BIOS
    ; mov [DRIVE_NUMBER], dl

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
    call load_catalogue
    jc .load_fail_cat

    ; Hopefully the offset/size will fit within 16 bits each
    ; some trickery to get number of sectors - note we skip
    ; loading the first byte to get an implicit divide by 256
    mov ax, [AFTER_MBR + catalogue_header_t.offset + 1]
    shr ax, 1
    call logical_to_chs

    mov ax, [AFTER_MBR + catalogue_header_t.length + 1]
    shr ax, 1
    add ax, 1  ; round up... - may mean we load an unnecessary sector if the second stage
               ; loader is exactly a multiple of the sectore size

    call load_sectors
    jc .load_fail_kern

    jmp AFTER_MBR

.load_fail_cat:
    mov bx, LOAD_CAT_ERROR_MSG
    call print_msg
    mov al, [DRIVE_NUMBER]
    call print_hex_byte_16
    jmp $

.load_fail_kern:
    mov bx, LOAD_KERNEL_ERROR_MSG
    call print_msg
    mov al, [DRIVE_NUMBER]
    call print_hex_byte_16
    jmp $


; Inputs:
;     es:bx - place to load catalogue
; Returns:
;     ax - 0x0 on success
; Clobbers:
;     none
load_catalogue:
    ; The catalogue written by bakaFS is in sector 2,
    push cx
    push dx

    ; set up Cylincer/sector/head
    mov cl, CATALOGUE_SECTOR_OFFSET
	mov ch, 0
	mov dh, 0
	mov dl, [DRIVE_NUMBER]
    mov al, CATALOGUE_SECTOR_COUNT

    call load_sectors

    pop dx
    pop cx
    ret


; Inputs:
;     ax - A sector offset starting at 0
; Returns:
;     cx    - CHS address
;     dx    - CHS address
; Clobbers:
;     ax
logical_to_chs:

    push bx
    mov bx, ax

    mov dx, 0
    div word [SECTORS_PER_TRACK]
    mov cl, dl
    add cl, 1

    mov dx, 0
    div word [NUMBER_OF_HEADS]
    mov dh, dl
    mov ch, al

    mov dl, [DRIVE_NUMBER]

    pop bx
    ret


; Inputs:
;     es:bx - place to load data to
;     cx    - CHS address
;     dx    - CHS address
;     al    - count
; Returns:
;     ax - 0x0 on success
; Clobbers:
;     none
load_sectors:
    ; We assumed cx has the count of sectors we want
    ; we assume es:bx is set up to correct target

    ; don't save ax, as we then return
    ; the result of int 13h
    push bx
    push cx
    push dx

    mov ah, 0x02
    stc
    int 0x13

    pop dx
    pop cx
    pop bx
    ret



print_hex_byte_16:
    push ax
    push bx

    mov bx, ax

    shr al, 4
    add al, '0'
    cmp al, '9'
    jle .byte1
    add al, 0x7
.byte1:
    mov ah, 0x0e
    int 0x10
    mov al, bl
    and al, 0x0F
    add al, '0'
    cmp al, '9',
    jle .byte2
    add al, 0x7
.byte2:
    mov ah, 0x0e
    int 0x10

    pop bx
    pop ax
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

LOAD_CAT_ERROR_MSG:
    db "Failed to load catalogue from ", 0

LOAD_KERNEL_ERROR_MSG:
    db "Failed to load kärna.bin from ", 0

SECTORS_PER_TRACK:
    dw 18

NUMBER_OF_HEADS:
    dw 2

DRIVE_NUMBER:
    db 0x80

times 510-($-$$) db 0
dw 0xaa55

AFTER_MBR: