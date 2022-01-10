[bits 32]

struc kalloc_unit_t
    .offset  resw, 0
    .length  resw, 0
    .flags   resb, 0
endstruc



; Inputs:
;     ax   - zone segment number
; Returns:
;     none
; Clobbers:
;     none
kheap_zone_init:
    ret

; Inputs:
;     ax    - zone segment number
;     bx    - length of allocation
; Returns:
;     ax    - Segment offset of allocation handle
; Clobbers:
;     none
kheap_zone_alloc:
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