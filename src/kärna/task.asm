[bits 32]

struc task_state_segment_t
    .link           resw 1
    .reserved_0     resw 1
    .esp0           resd 1
    .ss0            resw 1
    .reserved_1     resw 1
    .esp1           resd 1
    .ss1            resw 1
    .reserved_2     resw 1
    .esp2           resd 1
    .ss2            resw 1
    .reserved_3     resw 1
    .cr3            resd 1
    .eip            resd 1
    .eflags         resd 1
    .eax            resd 1
    .ecx            resd 1
    .edx            resd 1
    .ebx            resd 1
    .esp            resd 1
    .ebp            resd 1
    .esi            resd 1
    .edi            resd 1
    .es             resw 1
    .reserved_4     resw 1
    .cs             resw 1
    .reserved_5     resw 1
    .ss             resw 1
    .reserved_6     resw 1
    .ds             resw 1
    .reserved_7     resw 1
    .fs             resw 1
    .reserved_8     resw 1
    .gs             resw 1
    .reserved_9     resw 1
    .ldtr           resw 1
    .reserved_10    resd 1
    .iobp_offset    resw 1
endstruc

bootloader_tss:
    times task_state_segment_t_size db 0

; Inputs:
;     eax - address of call to jump to
; Returns:
;     none
; Clobbers:
;     none
; Notes:
;     Currently it is assumed this is called after the leap to protected mode, so the GDT already has a pointer
;     to the bootloader's TSS ready for us to invoke it, but the values in the TSS are yet to be made right
fill_bootloader_tss:
    push eax
    push ebx

    mov ebx, eax

    mov eax, bootloader_tss

    ; first set the instruction pointer!
    mov [eax + task_state_segment_t.eip], ebx

    ; Set the segment registers as we find them now
    mov bx, cs
    mov [eax + task_state_segment_t.cs], bx
    mov bx, ss
    mov [eax + task_state_segment_t.ss], bx
    mov bx, ds
    mov [eax + task_state_segment_t.ds], bx
    mov [eax + task_state_segment_t.ss0], bx
    mov bx, fs
    mov [eax + task_state_segment_t.fs], bx
    mov bx, gs
    mov [eax + task_state_segment_t.gs], bx

    ; once we switch, history is bunk, so reset the stack pointer to what it is
    ; when we enter the bootloader
    mov ebx, 0x00007c00
    mov [eax + task_state_segment_t.ebp], ebx
    mov [eax + task_state_segment_t.esp], ebx

    mov bx, task_state_segment_t_size
    mov [eax + task_state_segment_t.iobp_offset], bx

    pop ebx
    pop eax
    ret
