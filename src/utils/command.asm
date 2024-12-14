%INCLUDE "src/tui/welcome.asm"
command:
    
.readkeys:
    mov ah, 0x00  ; Service 0h: Read key press
    int 16h       ; Put the pressed key into AL

    cmp al, 13    ; Check if Enter key is pressed
    je .handler   ; If Enter is pressed, go to command handler

    cmp al, 8     ; Check if Backspace key is pressed
    je .handle_backspace ; If Backspace is pressed, handle it separately

    cmp al, 0     ; Check for extended key codes
    jne .process_key

    mov ah, 0x00  ; Read the extended key code
    int 16h       ; Put the extended key code into AL

    jmp .readkeys

.process_key:
    mov bx, [buffer_len]       ; Move buffer length to BX
    mov [buffer + bx], byte al ; Store character in buffer at current buffer length
    inc byte [buffer_len]      ; Increment buffer length

    mov ah, 0x0e
    int 10h

    jmp .readkeys


.handle_backspace:
    mov bx, [buffer_len]       ; Move buffer length to BX
    cmp bx, 0                  ; Check if buffer is empty
    je .readkeys               ; If buffer is empty, just read keys again

    dec byte [buffer_len]      ; Decrement buffer length to remove last character
    mov ah, 0x0e
    mov al, 0x08               ; Move back
    int 10h
    mov al, ''                 ; Erase character
    int 10h
    mov al, 0x08               ; Move back again
    int 10h
    jmp .readkeys


.handler:
    mov si, buffer
    mov di, orig_case
    mov cx, [buffer_len]
    rep movsb

    mov si, buffer
    mov cx, [buffer_len]
    call to_lowercase

    mov si, buffer
    mov di, cmd_help
    mov cx, 4
    repe cmpsb
    je .cmdhelp

    mov si, buffer
    mov di, cmd_echo
    mov cx, 5
    repe cmpsb
    je .cmdecho

    mov si, buffer
    mov di, cmd_cls
    mov cx, 3
    repe cmpsb
    je .cmdcls

    mov si, buffer
    mov di, cmd_shutdown
    mov cx, 8
    repe cmpsb
    je .cmdshutdown

    mov si, buffer
    mov di, cmd_ver
    mov cx, 3
    repe cmpsb
    je .cmdver

    mov si, buffer
    mov di, cmd_tui
    mov cx, 3
    repe cmpsb
    je .cmdtui

    mov si, buffer
    mov di, cmd_ls
    mov cx, 2
    repe cmpsb
    je .cmdls

    mov si, buffer
    mov di, cmd_type
    mov cx, 5
    repe cmpsb
    je .cmdtype

    mov si, failure_cmd
    jmp .fail
.cmdls:
    call print_root
    jmp .end2
.cmdtype:
    mov si, buffer
    add si, 5
    mov cx, 11
    call to_uppercase

    call convt_filename
    
    ;call find_file
    jc .file_not_found

    ;call print_file_contents
    jmp .end

.file_not_found:
    mov si, file_not_found_msg
    call println
    jmp .end2
    
.cmdver:
    mov si, cmdout_ver_1
    call println
    mov si, cmdout_ver_2
    call println
	mov si, sys_ver
    call print
    mov si, cmdout_ver_3
    call println
	mov si, cmdout_ver_4
    call println
    jmp .end

.cmdreboot:
    db 0x0ea
    dw 0x0000
    dw 0xffff

.cmdcls:
    call cls
    jmp .end2

.cmdtui:
    call tui_init
    call cls
    jmp .end2

.cmdhelp:
    mov si, cmdout_help_1
    call println
    mov si, cmdout_help_2
    call println
    mov si, cmdout_help_3
    call println
    mov si, cmdout_help_5
    call println
    mov si, cmdout_help_6
    call println
    mov si, cmdout_help_7
	call println
	mov si, cmdout_help_8
    call println
    jmp .end

.cmdecho:
    mov si, orig_case
    add si, 5
    call println
    jmp .end

.cmdhalt:
    ret

.cmdshutdown:
    ; Check if the command has a '-r'
    mov si, buffer      ; Load the buffer into SI
    add si, 9           ; Add 9 to SI (Moves the buffer forward by 9 characters)
    mov di, cmd_extr    ; Load cmd_extr into DI
    mov cx, 2           ; Set CX to len of cmd_extr
    repe cmpsb          ; Compare
    je .cmdreboot       ; If true, run .cmdreboot
    ; Otherwise, let's make sure the command is just 'shutdown'
    mov bl, byte [buffer_len]
    mov bh, 8
    cmp bl, bh
    jne .fail
    ; Code to shutdown the system
    mov ax, 5307h
    mov cx, 3
    mov bx, 1
    int 15h

; If the command fails
.fail:
    mov si, failure_cmd
    call println
    jmp .end
    
.end:
    ; Reset buffer
    mov di, buffer
    mov cx, 255
    mov al, 0              ; Fill buffer with zeros
    rep stosb              ; Store AL in buffer

    ; Reset buffer length
    mov byte [buffer_len], 0  ; Reset buffer length to 0

    call newln

    mov si, uname
    call println
    mov si, prompt_symb
    call print
    
    jmp command

; A temporary fix for commands like 'cls', will be replaced later
.end2:
    ; Reset buffer
    mov di, buffer
    mov cx, 255
    mov al, 0              ; Fill buffer with zeros
    rep stosb              ; Store AL in buffer

    ; Reset buffer length
    mov byte [buffer_len], 0  ; Reset buffer length to 0

    mov si, uname
    call println
    mov si, prompt_symb
    call print
    
    jmp command

comparecmd:


; Command inputs
cmd_help db 'menu', 0
cmd_echo db 'echo ', 0
cmd_cls db 'cla', 0
cmd_shutdown db 'shutdown', 0
cmd_ver db 'ver', 0
cmd_tui db 'ui', 0

cmd_extr db '-r', 0

cmd_ls db 'ls', 0

cmd_type db 'type ', 0


; Command outputs
cmdout_help_1 db '--------        (=) MENU              --------', 0
cmdout_help_2 db ' (=) menu     : Displays the available commands.', 0
cmdout_help_3 db ' (a) echo     : Repeats the entered text.', 0
cmdout_help_5 db ' (x) cla      : Clears the screen.', 0
cmdout_help_6 db ' (|) shutdown : Turns off your PC. Run -r to reboot.', 0
cmdout_help_7 db ' (i) ver      : Displays the system version.', 0
cmdout_help_8 db '----------------------------------------------', 0

cmdout_ver_1 db '--------        (i) About             --------', 0
cmdout_ver_2 db ' System version: ', 0
cmdout_ver_3 db ' OmniOS System (C) 2024.', 0
cmdout_ver_4 db '----------------------------------------------', 0

; --- fail ---
cmd_none db '', 0
failure_cmd db " (?) Hmm, I didn't understand what you meant.", 0
