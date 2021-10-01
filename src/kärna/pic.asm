
PIC1            equ 0x20
PIC2            equ 0xA0
PIC1_COMMAND    equ PIC1
PIC1_DATA       equ PIC1 + 1
PIC2_COMMAND    equ PIC2
PIC2_DATA       equ PIC2 + 1
PIC_EOI         equ 0x20

ICW1_ICW4       equ	0x1
ICW1_SINGLE	    equ 0x02
ICW1_INTERVAL4	equ 0x04
ICW1_LEVEL	    equ 0x08
ICW1_INIT	    equ 0x10

ICW4_8086	    equ 0x01
ICW4_AUTO	    equ 0x02
ICW4_BUF_SLAVE	equ 0x08
ICW4_BUF_MASTER	equ 0x0C
ICW4_SFNM	    equ 0x10

%macro out_al 2
    mov al, %2
    out %1, al
%endmacro

; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
disable_pic:
    push eax

    mov al, 0xff
    out PIC2_DATA, al
    out PIC1_DATA, al

    pop eax
    ret


; Inputs:
;     bl: irq that fired
; Returns:
;     none
; Clobbers:
;     none
clear_pic:
    push eax

    cmp bl, 8
    jl .clear_master
    out_al PIC2, PIC_EOI
.clear_master:
    out_al PIC1, PIC_EOI

    pop eax
    ret


; Inputs:
;     none
; Returns:
;     none
; Clobbers:
;     none
remap_pic:
    push eax
    push ebx

    ; backup state of PIC
    ; in al, PIC1_DATA
    ; mov bh, al
    ; in al, PIC2_DATA
    ; mov bl, al

    out_al PIC1_COMMAND, ICW1_INIT | ICW1_ICW4
    out_al PIC2_COMMAND, ICW1_INIT | ICW1_ICW4
    out_al PIC1_DATA, 0x20 ; remap to interrupt 32->39
    out_al PIC2_DATA, 0x28 ; remap to interrupt 40->47
    out_al PIC1_DATA, 4
    out_al PIC2_DATA, 2
    out_al PIC1_DATA, ICW4_8086
    out_al PIC2_DATA, ICW4_8086

    ; restore state of PIC
    ; mov al, bh
    ; out_al PIC1_DATA, al
    ; mov al, bl
    ; out_al PIC2_DATA, al
    out_al PIC1_DATA, 0x0
    out_al PIC2_DATA, 0x0


    pop ebx
    pop eax
    ret
