print:
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

println:
    mov bx, 0007h
    mov ax, 0E0Dh
    int 10h
    mov ax, 0E0Ah
    int 10h

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x0F
    mov ch, 24d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h

    jmp print

newln:
    mov bx, 0007h
    mov ax, 0E0Dh
    int 10h
    mov ax, 0E0Ah
    int 10h

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x0F
    mov ch, 24d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h

    ret

cls:


    ; clear the screen
    mov ax, 02
    int 0x10

    ; For changing colors
    mov ah, 0x06
    mov bh, 0x0F
    mov ch, 00d     ; start row
    mov cl, 00d	    ; start col
    mov dh, 24d	    ; end of row
    mov dl, 79d	    ; end of col
    int 10h

    ; then we move the cursor
    mov ah, 0x02	; move cursor Instruction
    mov bh, 0x00	; page
    mov dh, 0x00	; row
    mov dl, 0x00	; column
    int 10h

    ret

; Function to convert a buffer to lowercase
; Input:
;   SI: Pointer to the buffer
;   CX: Length of the buffer
to_lowercase:
    push ax
    push si
    push cx

.loop:
    lodsb               ; Load byte from SI into AL and increment SI
    cmp al, 'A'
    jb .skip            ; If AL < 'A', skip
    cmp al, 'Z'
    ja .skip            ; If AL > 'Z', skip
    add al, 32          ; Convert to lowercase by adding 32
    mov [si-1], al      ; Store the lowercase character back

.skip:
    loop .loop          ; Decrement CX and continue if not zero

    pop cx
    pop si
    pop ax
    ret

; Function to convert a buffer to uppercase
; Input:
;   SI: Pointer to the buffer
;   CX: Length of the buffer
to_uppercase:
    push ax
    push si
    push cx

.loop:
    lodsb               ; Load byte from SI into AL and increment SI
    cmp al, 'a'
    jb .skip            ; If AL < 'a', skip
    cmp al, 'z'
    ja .skip            ; If AL > 'z', skip
    sub al, 32          ; Convert to uppercase by subtracting 32
    mov [si-1], al      ; Store the uppercase character back

.skip:
    loop .loop          ; Decrement CX and continue if not zero

    pop cx
    pop si
    pop ax
    ret

convt_filename:
    mov di, temp_buffer
    mov cx, 8
    xor bx, bx
.pad_name:
    lodsb
    cmp al, '.'
    je .prepare_extension
    cmp al, 0
    je .pad_all
    stosb
    inc bx
    loop .pad_name
    jmp .find_extension
.pad_all:
    mov cx, 11
    sub cx, bx
    mov al, ' '
    rep stosb
    jmp .done
.prepare_extension:
    mov cx, 8
    sub cx, bx
    mov al, ' '
    rep stosb
.find_extension:
    mov cx, 3
.pad_extension:
    lodsb
    cmp al, 0
    je .pad_extension_spaces
    cmp al, '.'
    je .pad_extension
    stosb
    loop .pad_extension
.pad_extension_spaces:
    mov al, ' '
    rep stosb
.done:
    ret
