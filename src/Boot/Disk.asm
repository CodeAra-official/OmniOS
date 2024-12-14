; Input: LBA index in AX
; CX: Sector number (bits 0-5), Cylinder (bits 6-15)
; DH: Head number

; Calculate head, track, and sector settings for INT 13h
; IN: AX contains the logical block address (LBA)
; OUT: DX holds the correct registers for INT 13h

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [SectorsPerTrack]  ; (LBA % sectors per track) + 1 <- Sector
    inc dx                      ; Sector
    mov cx, dx

    xor dx, dx
    div word [HeadsPerCylinder]

    mov dh, dl                  ; Head
    mov ch, al
    shl ah, 6
    or cl, ah                   ; Cylinder

    ; Head: (LBA / sectors per track) % number of heads
    ; Cylinder: (LBA / sectors per track) / number of heads

    pop ax
    mov dl, al
    pop ax

    ret

disk_read:
    push ax
    push bx
    push cx
    push dx
    push di

    call lba_to_chs

    mov ah, 02h
    mov di, 3   ; Loop Counter

retry:
    stc
    int 13h
    jnc done_read

    call disk_reset

    dec di
    test di, di
    jnz retry

disk_readfailure:
    hlt

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc disk_readfailure
    popa
    ret

done_read:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret