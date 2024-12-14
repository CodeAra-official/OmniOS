;[BITS 16]
;[ORG 0x1000]

; TUI mode
tui_init:
    call loadwelcome
    call t_newln
    call loadtext
    call t_newln
    jmp inputreciever

    ; call cls
    
    ret

loadwelcome:
    ; clear the screen
    mov ax, 02
    int 0x10

    ; For changing colors
    mov ah, 0x06
    ; Changes to white text on black background

    mov bh, 0x1F
    mov ch, 00d     ; start row
    mov cl, 00d     ; start col
    mov dh, 02d     ; end of row
    mov dl, 79d     ; end of col
    int 10h

    mov bh, 0x7F
    mov ch, 03d     ; start row
    mov cl, 00d     ; start col
    mov dh, 22d     ; end of row
    mov dl, 79d     ; end of col
    int 10h

    mov bh, 0x1F
    mov ch, 23d     ; start row
    mov cl, 00d     ; start col
    mov dh, 24d     ; end of row
    mov dl, 79d     ; end of col
    int 10h
    ; Buttons
    mov bh, 0x1B        ; Display attribute
    mov ch, 14          ; Row for buttons

    ; First Button
    mov cl, 26          ; Start column for first button (centered)
    mov dh, 15          ; End of row for first button
    mov dl, 36          ; End of column for first button
    int 10h             ; Display the first button
    mov bh, 0x8F        ; Display attribute
    mov ch, 14          ; Row for buttons
    ; Second Button
    mov cl, 41          ; Start column for second button (adjust as needed)
    mov dh, 15          ; End of row for second button
    mov dl, 51          ; End of column for second button (adjust as needed)
    int 10h             ; Display the second button


    ; Hide Cursor
    mov ah, 0x01    ; Set cursor size function
    mov cx, 0x2000  ; Make cursor invisible, CX = 0x2000
    int 0x10
    ret

loadtext:

    
    mov si, menubar_1
    call t_print

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 26          ; Column number
    int 10h             ; Call BIOS video interrupt

    mov si, left
    call t_print

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 41          ; Column number
    int 10h             ; Call BIOS video interrupt

    mov si, right
    call t_print
    ret
    

inputreciever:
.readkeys:
    mov ah, 0x00  ; Service 0h: Read key press
    int 16h       ; Put the pressed key into AL

    cmp al, 13    ; Check if Enter key is pressed
    je .handler   ; If Enter is pressed, go to command handler

    ;cmp al, 8     ; Check if Backspace key is pressed
    ;je .handle_backspace ; If Backspace is pressed, handle it separately

    ;cmp al, 0     ; Check for extended key codes
    ;jne .process_key

    ;mov ah, 0x00  ; Read the extended key code
    ;int 16h       ; Put the extended key code into AL

    ;mov ah, 0x0e
    ;int 10h

    ; Assume al contains the scan code of the pressed key
    cmp ah, 0x4B  ; Compare with left arrow scan code
    je .left_pressed  ; Jump if equal to left arrow scan code
    cmp ah, 0x4D  ; Compare with right arrow scan code
    je .right_pressed  ; Jump if equal to right arrow scan code

    ;cmp al, 27
    ;ret

    jmp .readkeys

.left_pressed:
    ; Buttons
    mov ah, 0x06
    mov bh, 0x1B        ; Display attribute
    mov ch, 14          ; Row for buttons

    ; First Button
    mov cl, 26          ; Start column for first button (centered)
    mov dh, 15          ; End of row for first button
    mov dl, 36          ; End of column for first button
    int 10h             ; Display the first button
    mov bh, 0x8F        ; Display attribute
    mov ch, 14          ; Row for buttons
    ; Second Button
    mov cl, 41          ; Start column for second button (adjust as needed)
    mov dh, 15          ; End of row for second button
    mov dl, 51          ; End of column for second button (adjust as needed)
    int 10h             ; Display the second button

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 26          ; Column number
    int 10h             ; Call BIOS video interrupt

    mov si, left
    call t_print

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 41          ; Column number
    int 10h             ; Call BIOS video interrupt

    mov si, right
    call t_print

    mov byte [highlighted_button], 0
    jmp .readkeys
.right_pressed:
    ; Buttons
    mov ah, 0x06
    mov bh, 0x8F        ; Display attribute
    mov ch, 14          ; Row for buttons

    ; First Button
    mov cl, 26          ; Start column for first button (centered)
    mov dh, 15          ; End of row for first button
    mov dl, 36          ; End of column for first button
    int 10h             ; Display the first button
    mov bh, 0x1B        ; Display attribute
    mov ch, 14          ; Row for buttons
    ; Second Button
    mov cl, 41          ; Start column for second button (adjust as needed)
    mov dh, 15          ; End of row for second button
    mov dl, 51          ; End of column for second button (adjust as needed)
    int 10h             ; Display the second button

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 26          ; Column number
    int 10h             ; Call BIOS video interrupt

    mov si, left
    call t_print

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 41          ; Column number
    int 10h             ; Call BIOS video interrupt

    mov si, right
    call t_print

    mov byte [highlighted_button], 1
    jmp .readkeys

.handler:
    mov al, [highlighted_button]
    cmp al, 0           ; Check if left button is highlighted
    je .hl     ; If left button is highlighted, perform left action
    cmp al, 1           ; Check if right button is highlighted
    je .hr    ; If right button is highlighted, perform right action

.hl:
    ; Buttons
    mov ah, 0x06
    mov bh, 0x0F        ; Display attribute
    mov ch, 14          ; Row for buttons

    ; First Button
    mov cl, 26          ; Start column for first button (centered)
    mov dh, 15          ; End of row for first button
    mov dl, 36          ; End of column for first button
    int 10h             ; Display the first button

    mov bh, 0x0F        ; Display attribute
    mov ch, 14          ; Row for buttons

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 26          ; Column number
    int 10h             ; Call BIOS video interrupt
    
    mov si, left
    call t_print
    
        ; Some sort of delay
    mov cx, 1      ; HIGH WORD (set to 0)
    mov dx, 5000h ; LOW WORD (for example)
    mov ah, 86h   ; WAIT
    int 15h       ; Invoke interrupt

    ; Buttons
    mov ah, 0x06
    mov bh, 0x1B        ; Display attribute
    mov ch, 14          ; Row for buttons

    ; First Button
    mov cl, 26          ; Start column for first button (centered)
    mov dh, 15          ; End of row for first button
    mov dl, 36          ; End of column for first button
    int 10h             ; Display the first button
    mov bh, 0x0F        ; Display attribute
    mov ch, 14          ; Row for buttons

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 26          ; Column number
    int 10h             ; Call BIOS video interrupt
    
    mov si, left
    call t_print

    jmp .readkeys
.hr:
    ; Buttons
    mov ah, 0x06
    mov bh, 0x0F        ; Display attribute
    mov ch, 14          ; Row for buttons

    ; First Button
    mov cl, 41          ; Start column for first button (centered)
    mov dh, 15          ; End of row for first button
    mov dl, 51          ; End of column for first button
    int 10h             ; Display the first button
    
    mov bh, 0x0F        ; Display attribute
    mov ch, 14          ; Row for buttons

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 41          ; Column number
    int 10h             ; Call BIOS video interrupt
    
    mov si, right
    call t_print
    
        ; Some sort of delay
    mov cx, 1      ; HIGH WORD (set to 0)
    mov dx, 5000h ; LOW WORD (for example)
    mov ah, 86h   ; WAIT
    int 15h       ; Invoke interrupt

    ; Buttons
    mov ah, 0x06
    mov bh, 0x1B        ; Display attribute
    mov ch, 14          ; Row for buttons
    ; Second Button
    mov cl, 41          ; Start column for second button (adjust as needed)
    mov dh, 15          ; End of row for second button
    mov dl, 51          ; End of column for second button (adjust as needed)
    int 10h             ; Display the second button

    mov ah, 02h         ; Function 02h - Set Cursor Position
    mov bh, 0           ; Page number (usually 0)
    mov dh, 15          ; Row number
    mov dl, 41          ; Column number
    int 10h             ; Call BIOS video interrupt
    
    mov si, right
    call t_print

    mov byte [highlighted_button], 0
    ret

t_print:
    mov ah, 0Eh

.repeat:
    mov ah, 0Eh
    ; lodsb loads the next character from si
    lodsb
    ; acts as "if else" in a way
    cmp al, 0
    je .done
    int 10h
    ; loops
    jmp .repeat

.done:
    ret ; return to start

t_println:
    mov bx, 0007h
    mov ax, 0E0Dh
    int 10h
    mov ax, 0E0Ah
    int 10h

    jmp print

t_newln:
    mov bx, 0007h
    mov ax, 0E0Dh
    int 10h
    mov ax, 0E0Ah
    int 10h

    ret

; Strings
menubar_1 db '  OmniOS System', 0

left db 'Do Nothing', 0
right db 'Exit', 0
highlighted_button db 0