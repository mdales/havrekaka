[bits 32]

%macro inb 1
    mov dx, %1
    in al, dx
%endmacro

%macro inw 1
    mov dx, %1
    in ax, dx
%endmacro

%macro ind 1
    mov dx, %1
    in eax, dx
%endmacro

%macro outb 1
    mov dx, %1
    out dx, al
%endmacro

%macro outd 1
    mov dx, %1
    out dx, eax
%endmacro

; Inputs:
;     eax - pointer to first string
;     ebx - pointer to second string
; Returns:
;     eax - 0 if same, non-zero if not
; Clobbers:
;     none
compare_string:
    push ebx
    push ecx
    push edx

    mov ecx, [eax]
    mov edx, [ebx]
    cmp ecx, edx
    jne .done_fail

.next:
    add eax, 4
    add ebx, 4

    ; ecx happens to be the right value nows
.loop:
    mov dl, [eax]
    inc eax
    mov dh, [ebx]
    inc ebx
    cmp dl, dh
    jne .done_fail
    loop .loop

    mov eax, 0
    jmp .done

.done_fail:
    mov eax, 1
.done:
    pop edx
    pop ecx
    pop ebx
    ret
