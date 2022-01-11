[org 0x7e00]
[bits 16]

start:
	; Set up real-mode memory map again. In theory stövelrem will have set that up
    ; for us, but who knows what it's doing really, so just set up a few things
    ; briefly, as soon we'll be flipping to protected mode, at which point
    ; we'll be using a totally different map
    mov ax, 0x0
    mov ds, ax
    mov ss, ax
    mov es, ax

    mov bp, 0x7c00
    mov sp, bp

    ; let the world know we made it across
    mov bx, KERNEL_START_MSG
    call print_msg_16

    ; disable the text mode cursor before we jump to protected mode
    ; as we'll be proding VGA directly after that
    mov ah, 0x1
    mov ch, 0x3F
    int 0x10

    ; we need to know how much memory we have, which means we need to find out
    ; where the extended bios information is, as that defines the upper bound of the first
    ; 1 MB usable memory space. As a simple starting point let's just put 64KB in there.
    mov ax, 0x40
    mov es, ax
    mov di, 0x000E
    mov ax, [es:di]

    ; ax is now the offset of the EBDA, but shifted 4 bits.
    sub ax, 0x1000 ; start of 64KB segment before the EBDA

    ; update the GDT entry for kernel data segment with the LFB address.
    mov bx, ax
    shr ax, 4
    shl bx, 12
    mov di, gdt.sd_kheap
    mov word [di + gdt_entry_t.base_0_15], ax
    mov byte [di + gdt_entry_t.base_16_23], bl
    mov ah, 0x0
    mov byte [di + gdt_entry_t.base_24_31], ah
    mov al, 0b01000001
    mov byte [di + gdt_entry_t.limit_and_flags], al
    mov ax, 0x00
    mov word [di + gdt_entry_t.limit_0_15], ax

    mov ax, 0x0
    mov es, ax

    ; We need to set up VESA now, so we can use int 0x10, but we'll only be
    ; able to draw to it once we've set up the GDT as we're using the LFB from
    ; VESA 2.0 for now
    mov di, 0x0500 ; store vesa info at start of free mem for now
    call vesa_load_info
    cmp ax, 0x0
    jne .vesa_setup
    mov bx, VESA_LOAD_FAIL_MSG
    call print_msg_16
    jmp $

.vesa_setup:
    mov bx, 0x500
    mov di, 0x500 + vesa_info_t_size
    call vesa_find_best_mode
    cmp ax, 0x0
    jne .load_vesa_mode
    mov bx, VESA_MODE_FIND_FAIL_MSG
    call print_msg_16
    jmp $

.load_vesa_mode:
    call vesa_set_mode
    cmp ax, 0x0
    je .load_vesa_palette
    mov bx, VESA_MODE_SET_FAIL_MSG
    call print_msg_16
    jmp $

.load_vesa_palette:
    mov bx, ds
    mov es, bx
    mov di, island_joy_16
    call vesa_set_palette

.post_vesa_setup:
    ; update the GDT entry for VESA with the LFB address
    mov bx, video_mode_info
    mov di, gdt.sd_vesa
    mov ax, [bx + video_mode_info_t.framebuffer_ptr]
    mov [di + gdt_entry_t.base_0_15], ax
    mov ax, [bx + video_mode_info_t.framebuffer_ptr + 2]
    mov [di + gdt_entry_t.base_16_23], al
    mov [di + gdt_entry_t.base_24_31], ah


    ; disable interrupts until we've in protected mode and have set up the
    ; Interrupt Descriptor Table (IDT).
    cli

    ; disable the pic
    ; call disable_pic
    call remap_pic

    ; load the global segment descriptor table
    lgdt [GDT_DESCRIPTOR]

    ; Set the protected mode bit in CR0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    ; Jump into protected mode!
    jmp CODE_SEG:protected_start

print_msg_16:
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


[bits 32]
protected_start:
    ; Set up the protected mode memory model for the kernel
    mov ax, DATA_SEG
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x7C00
    mov esp, ebp

    ; let the world know we made it this far again
    ; mov ebx, PROTECTED_START_MSG
    ; call clear_vga_screen
    ; call print_vga_string
    call clear_video_screen

    ; ; Set up the kernel heap
    mov eax, KERNEL_HEAP_SEG
    call kheap_zone_init


    ; to make VESA mode actually useful we need to load up
    ; a font
    call load_video_font
    cmp eax, 0x0
    jne .font_fail

    mov eax, PROTECTED_START_MSG
    call print_video_string

    ; set up interrupt table and enable interrupts again
    mov eax, 0x4000 ; move the IDT to start of free memory
    call build_idt
    sti

    mov al, 0
    mov ah, 1
    call set_video_cursor_position
    mov eax, TEST_1
    call print_video_string
    mov al, 0
    mov ah, 2
    call set_video_cursor_position
    mov eax, TEST_2
    call print_video_string
    mov al, 0
    mov ah, 3
    call set_video_cursor_position
    mov eax, TEST_3
    call print_video_string

    mov edx, 6
.outerlll:
    mov al, 40
    mov ah, 12
    sub ah, dl
    call set_video_cursor_position


    mov ebx, gdt
    mov eax, edx
    sub eax, 1
    shl eax, 3
    add ebx, eax
    mov ecx, gdt_entry_t_size
.lll:

    mov al, [ebx]
    inc ebx
    call print_video_hex_byte


    ; mov al, 48
    ; sub al, cl
    ; mov ah, 12
    ; sub ah, dl
    ; call set_video_cursor_position

    loop .lll

    dec dx
    cmp dx, 0
    jne .outerlll


    call paint_trim
    call scan_pci
    jmp .main

.font_fail:
    call print_vga_hex_byte
    mov ebx, FAILED_TO_FIND_FONT_MSG
    call print_vga_string

.main:
    hlt
    jmp .main


KERNEL_START_MSG:
    db "V", 0x84, "lkommen! ", 0

VESA_LOAD_FAIL_MSG:
    db "Vi hittar VESA inte", 0
VESA_MODE_FIND_FAIL_MSG:
    db "Vi hittar VESA mode inte", 0
VESA_MODE_SET_FAIL_MSG:
    db "Vi g", 0xF6, "r VESA mode inte", 0

%include "src/kärna/idt.asm"
%include "src/kärna/gdt.asm"
%include "src/kärna/kmem.asm"
%include "src/kärna/lib.asm"
%include "src/kärna/vga_text.asm"
%include "src/kärna/vga_video.asm"
%include "src/kärna/vesa.asm"
%include "src/kärna/pic.asm"
%include "src/kärna/ata.asm"
%include "src/kärna/fs.asm"
%include "src/kärna/pci.asm"
%include "src/kärna/typsnitt.asm"
%include "bin/strings.asm"
%include "bin/färger.asm"
