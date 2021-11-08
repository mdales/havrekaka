[bits 32]

STATUS_BUSY equ 0x80
STATUS_DATA_REQEST equ 0x04

%macro inb 1
    mov dx, %1
    in al, dx
%endmacro

%macro inw 1
    mov dx, %1
    in ax, dx
%endmacro

%macro outb 1
    mov dx, %1
    out dx, al
%endmacro

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
;     eax   = LDA of sector to read
;     bl    - number of sectors to read
;     es:di - location to write data
; Returns:
;     none
; Clobbers:
;     none
ata_read_sectors:

    push edx
    push ebx
    push eax

    call ata_await_busy

    ; port_byte_out(0x1F6,0xE0 | ((LBA >>24) & 0xF));
    mov edx, eax
    shr eax, 24
    and eax, 0xF
    or  eax, 0xE0
    outb 0x1F6

	; port_byte_out(0x1F2,sector_count);
    mov al, bl
	outb 0x1F2

    ; port_byte_out(0x1F3, (uint8_t) LBA);
    mov eax, edx
    outb 0x1F3

	; port_byte_out(0x1F4, (uint8_t)(LBA >> 8));
    shr eax, 8
    outb 0x1F4

	; port_byte_out(0x1F5, (uint8_t)(LBA >> 16));
    shr eax, 8
    outb 0x1F5

	; port_byte_out(0x1F7,0x20); //Send the read command
    mov al, 0x20
    outb 0x1F7

.sector_loop:
    call ata_await_busy
    call ata_await_data

    mov edx, 256
.word_loop:
    inw 0x1F0
    mov [es:di], ax
    add di, 2

    sub edx, 1
    jnz .word_loop

    sub bl, 1
    jnz .sector_loop

    pop eax
    pop ebx
    pop edx
    ret

	; uint16_t *target = (uint16_t*) target_address;

	; for (int j =0;j<sector_count;j++)
	; {
	; 	ATA_wait_BSY();
	; 	ATA_wait_DRQ();
	; 	for(int i=0;i<256;i++)
	; 		target[i] = port_word_in(0x1F0);
	; 	target+=256;
	; }