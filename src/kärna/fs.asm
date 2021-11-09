[bits 32]

; Our naive disk format is currently:
; sector    -   thing
;    0      -   bootloader
;    1..n   -   catalog
;    n+1..x -   kernel
;    ...    -   other files

CATALOGUE_SECTOR_LBA equ 0x0000001

struc catalogue_header_t
    .Version                  resd 1
	.CatalogueLengthInSectors resd 1
	.CatalogueEntryCount      resd 1
endstruc

CATALOGUE_VERSION equ 1

struc catalogue_entry_t
    .EntrySize  resw 1
	.Flags      resw 1
	.Offset     resq 1
	.Length     resq 1
    .NameLength resd 1
endstruc

; Inputs:
;     eax   - pointer to file name
; Returns:
;     eax    - On success, LBA of file, or 0
;     ebx    - On success, Sector count, or reason code
; Clobbers:
;     none
locate_file:
    push edx
    push edi

    ; load the first sector of the FS catalog onto the stack
    sub esp, 512

    mov edi, esp

    ; backup file name pointer
    mov edx, eax

    ; read the start of the catalog
    mov bl, 1
    mov eax, CATALOGUE_SECTOR_LBA
    call ata_read_sectors

    mov eax, [di + catalogue_header_t.Version]
    cmp eax, CATALOGUE_VERSION
    je .test_sectors
    mov eax, 0
    mov ebx, 4
    jmp .done

.test_sectors:
    ; lazy - for now assume one sector long header
    mov eax, [di + catalogue_header_t.CatalogueLengthInSectors]
    cmp eax, 1
    je .read_entries
    mov eax, 0
    mov ebx, 1
    jmp .done

.read_entries:
    mov ecx, [edi + catalogue_header_t.CatalogueEntryCount]
    add edi, catalogue_header_t_size

.read_loop:
    mov eax, edx
    mov ebx, edi
    add ebx, catalogue_entry_t.NameLength
    call compare_string
    cmp eax, 0
    je .found_entry

    mov ebx, [edi + catalogue_entry_t.EntrySize]
    add edi, ebx
    loop .read_loop

    mov eax, 0
    mov ebx, 2
    jmp .done

.found_entry:
    ; di points to the record
    mov eax, [edi + catalogue_entry_t.Offset]
    mov ebx, [edi + catalogue_entry_t.Length]

.done:
    add esp, 512
    pop edi

    pop edx

    ret
