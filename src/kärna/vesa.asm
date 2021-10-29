; VESA is a funny old thing. We want to use BIOS to query/set modes and
; thus be in real mode or virtual 8086 mode, but to use the linear frame buffer
; rather than bank switching we need to be able to address "high" memory, which
; requires us to be in protected mode. Thus, all the setup code should be run
; before we switch to protected mode

[bits 16]

struc vesa_info_t
    .signature:                 resb 4  ; 'VESA'
    .version:                   resw 1
    .oem_string_ptr_offset:     resw 1
    .oem_string_ptr_segment:    resw 1
    .capabilities:              resb 4
    .video_mode_ptr_offset:     resw 1
    .video_mode_ptr_segment:    resw 1
    .total_memory:              resw 1
endstruc

struc vesa_mode_t
    .attributes         resw 1  ; && 0x0080 to test for linear frame buffer
    .win_a_attributes   resb 1
    .win_b_attributes   resb 1
    .win_granularity    resw 1
    .win_size           resw 1
    .win_a_segment      resw 1
    .win_b_segment      resw 2
    .win_func_ptr       resd 1
    .bytes_per_scanline resw 1

    .x_resolution           resw 1
    .y_resolution           resw 1
    .x_char_size            resb 1
    .y_char_size            resb 1
    .number_of_planes       resb 1
    .bits_per_pixel         resb 1
    .number_of_banks        resb 1
    .memory_model           resb 1
    .bank_size              resb 1
    .number_of_image_pages  resb 1
    .reserved_0             resb 1

    .red_mask                   resb 1
    .red_offset                 resb 1
    .green_mask                 resb 1
    .green_offset               resb 1
    .blue_mask                  resb 1
    .blue_offset                resb 1
    .reserved_mask              resb 1
    .reserved_offset            resb 1
    .direct_color_attributes    resb 1

    .framebuffer_ptr            resd 1
    .off_screen_memory_offset   resd 1
    .off_screen_memory_length   resw 1

    .reserved_1 resb 206
endstruc

; Inputs:
;     es:di should be memory to use for info
; Returns:
;     ax - VESA version number if found, or 0 if not
; Clobbers:
;     none
vesa_load_info:
    mov ax, 0x4F00
    int 0x10

    cmp ax, 0x004F
    je .find_version
    mov ax, 0x0
    jmp .done

.find_version:
    mov ax, [di + vesa_info_t.version]

.done:
    ret

; Inputs:
;     ds:bx - location of VESA info
;     es:di - location of space to store mode info
; Returns:
;     ax - Mode number of "best" mode - probably the one with the most pixels and bit per pixel
;          returns 0 if we fail to do that
; Clobbers:
;     none
vesa_find_best_mode:

    ; first check that vesa_info looks valid, otherwise fail early
    ; should really load all of VESA into eax and compare that
    mov al, [bx + vesa_info_t.signature]
    cmp al, 'V'
    je .find_mode
    mov ax, 0x0 ; didn't find what we expected
    jmp .done_from_pre

.find_mode:
    push dx
    push bx
    push cx
    push es

    mov word cx, [bx + vesa_info_t.video_mode_ptr_segment]
    mov word dx, [bx + vesa_info_t.video_mode_ptr_offset]
    mov es, cx
    mov bx, dx

    mov ax, 0x0
.find_mode_loop:
    mov word dx, [es:bx]
    add bx, 0x2
    cmp dx, 0xFFFF
    je .done

    ; TODO, calc the "best" mode here. for testing just get
    ; last mode in list :)
    mov ax, dx

    jmp .find_mode_loop

.done:
    pop es
    pop cx
    pop bx
    pop dx
.done_from_pre:
    ret

; Inputs:
;     ax - vesa mode to set
;     es:di - mode info
; Returns:
;     ax - 0x0 on success
; Clobbers:
;     none
vesa_set_mode:
    push cx

    ; first load the mode info
    mov cx, ax
    mov ax, 0x4F01
    int 0x10
    cmp ax, 0x004F
    jne .done

.check_mode:
    ; we only want to set a mode with the LFB for now
    mov al, [di + vesa_mode_t.attributes]
    and al, 0x80
    jnz .set_mode
    mov ax, 0x1
    jmp .done

    push bx

.set_mode:
    or cx, 0x4000
    mov bx, cx
    mov ax, 0x4F02
    int 10h
    cmp ax, 0x004F
    je .store_mode_info
    mov ax, 0x2
    jmp .done_post_set

.store_mode_info:
    mov bx, video_mode_info
    mov al, 0x1
    mov [bx + video_mode_info_t.type], al
    mov ax, [di + vesa_mode_t.x_resolution]
    mov [bx + video_mode_info_t.width], ax
    mov ax, [di + vesa_mode_t.y_resolution]
    mov [bx + video_mode_info_t.height], ax
    ; TODO - better
    mov ax, [di + vesa_mode_t.framebuffer_ptr]
    mov [bx + video_mode_info_t.framebuffer_ptr], ax
    mov ax, [di + vesa_mode_t.framebuffer_ptr + 2]
    mov [bx + video_mode_info_t.framebuffer_ptr + 2], ax

.done_post_set:
    pop bx
.done:
    pop cx
    ret
