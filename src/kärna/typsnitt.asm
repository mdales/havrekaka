[bits 32]

FONT_MEMORY_SEGMENT  dw DATA_SEG
FONT_MEMORY_LOCATION dd 0x500

; The typsnitt file format is just a slightly pre-processed PC Screen Font file to save
; writing more asm for now. The layout is:
;
;  * typsnitt_header_t
;  * Glyph map: (uint32, uint32) * header.LookUpTableSize
;  * Glyphs: header.NumberOfGlyphs * header.BytesPerGlyph

struc typsnitt_header_t
	.Magic           resd 1
	.Version         resd 1
	.HeaderSize      resd 1
	.Flags           resd 1
	.NumberOfGlyphs  resd 1
	.BytesPerGlyph   resd 1
	.Height          resd 1
	.Width           resd 1
	.LookUpTableSize resd 1
endstruc

; Inputs:
;     none
; Returns:
;     eax - 0 on success, other one fail
; Clobbers:
;     none
load_video_font:
    push ebx
    push ecx
    push edx

    mov eax, FONT_FILE_NAME
    call locate_file
    cmp eax, 0x0
    jne .allocate_memory
    mov eax, ebx ; ebx has the error code for locate file
    jmp .done

.allocate_memory:
    mov edx, ebx
    mov ecx, eax
    mov ax, KERNEL_HEAP_SEG
    call kheap_zone_permanent_alloc
    cmp eax, 0x0
    je .restore
    mov [FONT_MEMORY_LOCATION], eax
    mov word [FONT_MEMORY_SEGMENT], KERNEL_HEAP_SEG

.restore:
    mov eax, ecx
    mov ebx, edx

.load_file:
    push es
    push edi

    mov dx, [FONT_MEMORY_SEGMENT]
    mov es, dx
    mov edi, [FONT_MEMORY_LOCATION]

    call load_file

    ; check for the magic number to verify we loaded stuff
    mov eax, [es:edi]
    cmp eax, 0x864AB572
    je .success
    mov eax, 0x42
    jmp .tidy

.success:
    mov eax, 0x0
    jmp .tidy

.tidy:
    pop edi
    pop es

.done:
    pop edx
    pop ecx
    pop ebx
    ret


; Inputs:
;     eax: unicode character
; Returns:
;     eax: location of bits for font (or substitute)
;      bx: segment for bits for font
; Clobbers:
;     none
bits_for_character:
    push ecx
    push edx
    push fs

    mov bx, [FONT_MEMORY_SEGMENT]
    mov fs, bx
    mov ebx, [FONT_MEMORY_LOCATION]

    ; glyph map is an ordered list of (unicode glyph, index) pairs, both 32 bits long in size
    ; in an ideal world we'd do a better search alg, but just to get something working, let's brute force it
    mov ecx, [fs:ebx + typsnitt_header_t.LookUpTableSize]
    add ebx, typsnitt_header_t_size
.loop:
    mov edx, [fs:ebx]
    cmp eax, edx
    je .found
    add ebx, 8
    loop .loop

    ; didn't find anything, so pick a substitute
    sub ebx, 8 ; last glyph in map

.found:
    ; get index in glyphs
    add ebx, 4

    mov eax, [fs:ebx]

    mov ebx, [FONT_MEMORY_LOCATION]

    mov edx, [fs:ebx + typsnitt_header_t.BytesPerGlyph]
    mul edx  ; eax = index of glyth, edx = size of glyph - so now eax = byte offset into glyphs

    mov ecx, [fs:ebx + typsnitt_header_t.LookUpTableSize]
    shl ecx, 3 ; ecx * sizeof(uint32) * 2

    add ebx, typsnitt_header_t_size
    add ebx, ecx

    add eax, ebx
    mov bx, fs

    pop fs
    pop edx
    pop ecx
    ret
