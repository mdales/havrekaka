[bits 32]

struc kalloc_meta_t
    .offset resd 1
    .length resd 1
endstruc


; This is currently just a naive memory allocator. We'll make it more complex as and when we need to!

; Inputs:
;     ax   - zone segment number
; Returns:
;     none
; Clobbers:
;     none
kheap_zone_init:
    push eax
    push ebx
    push ecx
    push fs
    push edi

    ; we want to make a note of how long the segment is, as that's how much memory we have to allocate
    mov ebx, 0x0
    mov bx, ax ; segment "numbers" are just offsets into the GDT rather than indexes
    add ebx, gdt

    mov ecx, 0x0
    mov cl, [ebx + gdt_entry_t.limit_and_flags]

    ; check the size of the
    mov dl, cl
    and dl, 0x80 ; flag for whether segement limit is in 4K pages or not

    and cl, 0x0F
    shl ecx, 16
    mov cx, [ebx + gdt_entry_t.limit_0_15]

    cmp dl, 0x0
    je .size_calc_done

    shl ecx, 12 ; if segment size is in pages rather than bytes

.size_calc_done:
    sub ecx, kalloc_meta_t_size

    mov fs, ax
    mov edi, 0x0
    mov dword [fs:edi + kalloc_meta_t.offset], 0x0
    mov [fs:edi + kalloc_meta_t.length], ecx

    pop edi
    pop fs
    pop ecx
    pop ebx
    pop eax
    ret

; Notes:
;     This allocates memory and never ever releases it, which for the OS boot strap is useful for
;     certain memory structures. For permanent allocations we just place them at the end of the zone if there's
;     free space.
; Inputs:
;     ax    - zone segment number
;     ebx    - length of allocation
; Returns:
;     eax    - Segment offset of allocation handle
; Clobbers:
;     none
kheap_zone_permanent_alloc:
    push fs
    push edi
    push ecx

    mov fs, ax
    mov edi, 0x0
    mov ecx, [fs:edi + kalloc_meta_t.length]

    cmp ebx, ecx
    jlt .alloc

.fail:
    mov eax, 0x0
    jmp .done

.alloc:
    sub ecx, ebx
    mov eax, ecx
    mov [fs:edi + kalloc_meta_t.length], ecx

.done:
    pop ecx
    pop edi
    pop fs
    ret

; Inputs:
;     ax    - zone segment number
;     bx    - length of allocation
; Returns:
;     ax    - Segment offset of allocation handle
; Clobbers:
;     none
kheap_zone_dyanamic_alloc:
    ret

; Inputs:
;     ax    - zone segment number
;     bx    - pointer of allocated block
; Returns:
;     none
; Clobbers:
;     none
kheap_zone_free:
    ret