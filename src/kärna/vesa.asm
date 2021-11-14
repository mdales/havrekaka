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
    .win_b_segment      resw 1
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
    ; Because we need es:di for a place to store mode info
    ; and we need it for reading the mode numbers, rather than juggling them
    ; in a loop I split this work into two phases - we first move all the mode numbers
    ; onto the stack, and then process them off that.
    push bx
    push cx
    push dx

    mov ax, es ; back up the target data segment

    mov word cx, [bx + vesa_info_t.video_mode_ptr_segment]
    mov word dx, [bx + vesa_info_t.video_mode_ptr_offset]
    mov es, cx
    mov bx, dx

    mov dx, 0x0         ; normally I'd use cx for the counter, but VESA needs me to pass the mode in
                        ; via cx, so dx it is <face palm emoji/>
.load_mode_numbers:
    mov cx, [es:bx]
    add bx, 2
    cmp cx, 0xFFFF
    je .process_mode_numbers
    push cx
    inc dx  ; This could overflow, but we'll blow the stack before we hit that point
    jmp .load_mode_numbers

.process_mode_numbers:
    mov es, ax  ; es:di is once again where we can store stuff
    mov bx, 0x0 ; bx is our best mode - we return in ax, but again VESA call wants ax, so for now...

.find_mode_loop:
    pop cx
    dec dx
    mov ax, 0x4F01
    int 0x10
    cmp ax, 0x004F
    jne .drain_modes_from_stack

    ; First, ask if this is 8bpp - a simple mode for now
    mov al, [es:di + vesa_mode_t.bits_per_pixel]
    cmp al, 0x8 ; we want an 8bpp mode
    jne .find_mode_loop

    ; any 8bpp mode is better than none, so count the first one we find as success
    ; we pick the first one as, at least for hyper-v, the end of the most list has higher resolution
    ; and we're processing the list backwards because we put it on the stack
    cmp bx, 0x0
    jne .more_tests
    mov bx, cx

.more_tests:
    ; next lets target 1024x768 if we can
    mov ax, [es:di + vesa_mode_t.x_resolution]
    cmp ax, 1024
    jne .find_mode_loop

    mov ax, [es:di + vesa_mode_t.y_resolution]
    cmp ax, 768
    jne .find_mode_loop

    mov bx, cx ; we have a winner!

.drain_modes_from_stack:
    shl dx, 1
    add sp, dx

    mov ax, bx

.done:
    pop dx
    pop cx
    pop bx
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

.set_mode:
    push bx

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
    mov ax, [di + vesa_mode_t.bytes_per_scanline]
    mov [bx + video_mode_info_t.bytes_per_scanline], ax
    mov al, [di + vesa_mode_t.bits_per_pixel]
    mov [bx + video_mode_info_t.bits_per_pixel], al
    ; TODO - better
    mov ax, [di + vesa_mode_t.framebuffer_ptr]
    mov [bx + video_mode_info_t.framebuffer_ptr], ax
    mov ax, [di + vesa_mode_t.framebuffer_ptr + 2]
    mov [bx + video_mode_info_t.framebuffer_ptr + 2], ax

    mov ax, 0x0

.done_post_set:
    pop bx
.done:
    pop cx
    ret

; Inputs:
;     es:di - palette info
; Returns:
;     ax - 0x0 on success
; Clobbers:
;     none
vesa_set_palette:
    push bx
    push cx
    push dx
    push di

    mov ax, 0x4F09
    mov cx, [es:di]
    add di, 2
    mov bl, 0x0
    mov dx, 0x0
    int 10h
    cmp ax, 0x004F
    jne .fail
    mov ax, 0x0
    jmp .done
.fail:
    mov ax, 0x1

.done:
    pop di
    pop dx
    pop cx
    pop bx
    ret
