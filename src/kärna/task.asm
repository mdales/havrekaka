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

