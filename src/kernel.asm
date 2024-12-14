[BITS 16]
[ORG 0x0000]

section .bss
    buffer resb 100
    buffer_len resb 1
    file_size resb 1
    temp_buffer resb 100
    orig_case resb 100
    ext_buffer resb 100
    uname resb 20         ; تخصيص 20 بايت لاسم المستخدم
    uname_len resb 1      ; تخصيص 1 بايت لطول اسم المستخدم

section .text

jmp Main

; Include external code
%INCLUDE "src/utils/print.asm"
%INCLUDE "src/utils/command.asm"
%INCLUDE "src/utils/setup.asm"
%INCLUDE "src/fs/disk.asm"

Main:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    call newln
    mov si, welcome_sys
    call print
    mov si, sys_ver
    call print
    mov al, '!'
    int 10h

    mov si, info1
    call println
    call newln

    mov di, buffer
    mov cx, 255
    mov al, 0
    rep stosb
    mov byte [buffer_len], 0

    mov si, prompt_symb
    call println

    call command

    mov si, haltedmsg
    call println

    jmp hang

error:
    mov si, error_x
    call println
    jmp hang
hang:
    cli
    hlt
    
    jmp $

; ------------------------------------------------------------------
; data section
    welcome_sys db ' Welcome to OmniOS ', 0
    sys_ver db "1.0.0", 0

    error_x db " (!) Something went wrong..", 0

    usera db ' (-)Enter your username: ', 0

    info1 db " (i) Type MENU to start.", 0

    prompt_symb db " OmniOS:", 0
    haltedmsg db ' (!) OmniOS System crash!', 0

    filename db "TEST    TXT"
; ------------------------------------------------------------------
