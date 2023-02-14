
; See https://wiki.osdev.org/Global_Descriptor_Table
;     and
;     https://www.intel.com/content/www/us/en/architecture-and-technology/64-ia-32-architectures-software-developer-vol-3a-part-1-manual.html
; a simple flat Global Descriptor Table (GDT)

struc gdt_entry_t
    .limit_0_15      resw 1
    .base_0_15       resw 1
    .base_16_23      resb 1
    .access          resb 1
    .limit_and_flags resb 1
    .base_24_31      resb 1
endstruc

; Access bits
    ;   P    = 1    -> segemnt present (1 for present in memory; 0 for not)
    ;   DPL  = 00   -> privilege level 00 for highest  (11 for lowest)
    ;   S    = 1    -> 0 for system; 1 for code or data
    ;   Type = 1010 -> segment type 4 bits as follows
    ;                  code:
    ;                       1 for code (0 for data)
    ;                  conforming:
    ;                       If 1 code in this segment can be executed from
    ;                           an equal or lower privilege level.
    ;                           For example, code in ring 3 can far-jump to
    ;                           conforming code in a ring 2 segment.  The
    ;                           privl-bits represent the highest privilege
    ;                           level that is allowed to execute the segment.
    ;                           For example, code in ring 0 cannot far-jump
    ;                           to a conforming code segment with privl==0x2,
    ;                           while code in ring 2 and 3 can. Note that the
    ;                           privilege level remains the same, ie. a
    ;                           far-jump form ring 3 to a privl==2-segment
    ;                           remains in ring 3 after the jump.
    ;                       If 0 code in this segment can only be executed
    ;                           from the ring set in privl.
    ;                  readable: 1 for readable, 0 for execute-only
    ;                  accessed: 0 initially, if accessed, CPU sets it to 1

gdt:
    .sd_null:
        db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

    .sd_code:
        istruc gdt_entry_t
            at gdt_entry_t.limit_0_15,       dw 0xFFFF
            at gdt_entry_t.base_0_15,        dw 0x0000
            at gdt_entry_t.base_16_23,       db 0x00
            ;   P    = 1    -> segemnt present (1 for present in memory; 0 for not)
            ;   DPL  = 00   -> privilege level 00 for highest  (11 for lowest)
            ;   S    = 1    -> 0 for system; 1 for code or data
            ;   Type = 1010 -> segment type 4 bits as follows
            at gdt_entry_t.access,           db 0b10011010
            ; Bits
            ;   G    = 1 -> offset is in unit 4K (2^12 bytes)
            ;   D/B  = 1 -> 1 for 32-bit segment; 0 for 16-bit
            ;   L    = 0 -> 64-bit code segment? 0 for not, ununsed on 32-bit processor
            ;   AVL  = 0 -> Not available to system programmers
            ;   Segment Limit (bits 19:16) = 1111
            at gdt_entry_t.limit_and_flags,  db 0b11001111
            at gdt_entry_t.base_24_31,       db 0x00
        iend

    .sd_data:
        istruc gdt_entry_t
            at gdt_entry_t.limit_0_15,       dw 0xFFFF
            at gdt_entry_t.base_0_15,        dw 0x0000
            at gdt_entry_t.base_16_23,       db 0x00
            ; Bits
            ;   P    = 1    -> segemnt present (1 for present in memory; 0 for not)
            ;   DPL  = 00   -> privilege level 00 for highest  (11 for lowest)
            ;   S    = 1    -> 0 for system; 1 for code or data
            ;   Type = 0010 -> segment type 4 bits as follows
            at gdt_entry_t.access,           db 0b10010010
            ; Bits
            ;   G    = 1 -> offset is in unit 4K (2^12 bytes)
            ;   D/B  = 1 -> 1 for 32-bit segment; 0 for 16-bit
            ;   L    = 0 -> 64-bit code segment? 0 for not, ununsed on 32-bit processor
            ;   AVL  = 0 -> Not available to system programmers
            ;   Segment Limit (bits 19:16) = 1111
            at gdt_entry_t.limit_and_flags,  db 0b11001111
            at gdt_entry_t.base_24_31,       db 0x00
        iend

    .sd_vga:
        istruc gdt_entry_t
            at gdt_entry_t.limit_0_15,       dw 0xFFFF
            at gdt_entry_t.base_0_15,        dw 0x8000
            at gdt_entry_t.base_16_23,       db 0x0B
            at gdt_entry_t.access,           db 0b10010010
            at gdt_entry_t.limit_and_flags,  db 0b11000000
            at gdt_entry_t.base_24_31,       db 0x00
        iend

    .sd_vesa:
        istruc gdt_entry_t
            at gdt_entry_t.limit_0_15,       dw 0xFFFF
            at gdt_entry_t.base_0_15,        dw 0x0000
            at gdt_entry_t.base_16_23,       db 0x00
            at gdt_entry_t.access,           db 0b10010010
            at gdt_entry_t.limit_and_flags,  db 0b11000000
            at gdt_entry_t.base_24_31,       db 0x00
        iend

    .sd_kheap:
        istruc gdt_entry_t
            at gdt_entry_t.limit_0_15,       dw 0x0000
            at gdt_entry_t.base_0_15,        dw 0x0000
            at gdt_entry_t.base_16_23,       db 0x00
            at gdt_entry_t.access,           db 0b10010010
            at gdt_entry_t.limit_and_flags,  db 0b01000000
            at gdt_entry_t.base_24_31,       db 0x00
        iend

    .sd_bootloader_tss:
        istruc gdt_entry_t
            at gdt_entry_t.limit_0_15,       dw 0x0000
            at gdt_entry_t.base_0_15,        dw 0x0000
            at gdt_entry_t.base_16_23,       db 0x00
            at gdt_entry_t.access,           db 0b10001001
            at gdt_entry_t.limit_and_flags,  db 0b01000000
            at gdt_entry_t.base_24_31,       db 0x00
        iend

.gdt_end:


GDT_DESCRIPTOR: ; to be loaded by instruction lgdt
    ; The size is the size of the table subtracted by 1. This is because the
    ; maximum value of size is 65535, while the GDT can be up to 65536 bytes (a
    ; maximum of 8192 entries). Further no GDT can have a size of 0.
    dw gdt.gdt_end - gdt - 1
    ; The offset is the linear address of the table itself
    dd gdt


CODE_SEG equ gdt.sd_code - gdt
DATA_SEG equ gdt.sd_data - gdt
VGA_TEXT_SEG equ gdt.sd_vga - gdt
VESA_SEG equ gdt.sd_vesa - gdt
BOOTLOADER_TSS_SEG equ gdt.sd_bootloader_tss - gdt
KERNEL_HEAP_SEG equ gdt.sd_kheap - gdt
