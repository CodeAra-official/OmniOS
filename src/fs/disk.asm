[BITS 16]

; BIOS Parameter Block
OEMLabel:           db  "MSDOS5.0"
BytesPerSector:     dw  512
SectorsPerCluster:  db  1
ReservedSectors:    dw  1               ; Reserved for the boot sector
NumberOfFATs:       db  2
RootDirEntries:     dw  224
TotalSectors:       dw  2880            ; Number of logical sectors
MediaDescriptor:    db  0F0h
SectorsPerFAT:      dw  9
SectorsPerTrack:    dw  18
HeadsPerCylinder:   dw  2
HiddenSectors:      dd  0
LargeSectors:       dd  0

; Extended Boot Record
DriveNumber		    db 0		        ; The drive number.
                    db 0
Signature	        db 41		        ; Signature 41 is for floppy disks.
VolumeID		    db 12h,34h,56h,78h  ; A random ID.
VolumeLabel		    db "OmniOS      "    ; The volume label.
FileSystem		    db "FAT12   "	    ; The file system that is being used (FAT12)

print_root:
    call loadrootdirectory
    ret

;************************************************;
; convert lba to chs
; ax: lba address to convert
;************************************************;
lba2chs:
    xor dx, dx
    div word [SectorsPerTrack]
    inc dl
    mov byte [sector], dl
    xor dx, dx
    div word [HeadsPerCylinder]
    mov byte [head], dl
    mov byte [track], al
    ret

;************************************************;
; converts a fat cluster to lba.
; lba = (fat cluster - 2) * sectors per cluster
;************************************************;
fatcluster2lba:
    sub ax, 0x0002
    xor cx, cx
    mov cl, byte [SectorsPerCluster]
    mul cx
    add ax, word [dataSectorBeginning]
    ret

;======================================================
; loads data from the disk
; dh: number of sectors to read
; cl: starting sector to read from
;======================================================
loadsectors:
    push dx
    mov ah, 0x02
    mov al, dh
    mov ch, byte [track]
    mov cl, byte [sector]
    mov dh, byte [head]
    mov dl, 0
    int 0x13
    jc  diskerror
    pop dx
    cmp dh, al
    jne diskerror
    ret

diskerror:
    mov si, read_failure
    call println
    jmp $

failure:
    mov si, file_not_found_msg
    call println
    jmp $

;=========================================================
; loads the fat12 root directory and a given file into memory
;=========================================================
loadrootdirectory:
    xor     cx, cx
    xor     dx, dx
    mov     ax, 0x0020
    mul     word [RootDirEntries]
    div     word [BytesPerSector]
    xchg    ax, cx
    mov     al, byte [NumberOfFATs]
    mul     word [SectorsPerFAT]
    add     ax, word [ReservedSectors]
    mov     word [dataSectorBeginning], ax
    add     word [dataSectorBeginning], cx
    call    lba2chs
    mov     bx, rootdirectory_and_fat_offset
    mov     dh, cl
    call    loadsectors
    mov     cx, [RootDirEntries]
    mov     di, rootdirectory_and_fat_offset
.loop:
    push    cx
    mov     cx, 11
    mov     si, filename
    push    di
    rep cmpsb
    pop     di
    je      loadfat
    pop     cx
    add     di, 32
    loop    .loop
    jmp     failure

loadfat:
    mov     dx, word [di + 0x001a]
    mov     word [cluster], dx
    xor     ax, ax
    mov     byte [track], al
    mov     byte [head], al
    mov     al, 1
    mul     word [SectorsPerFAT]
    mov     dh, al
    mov     bx, rootdirectory_and_fat_offset
    mov     cx, word [ReservedSectors]
    add     cx, 1
    mov     byte [sector], cl
    call    loadsectors
    mov     bx, image_offset
    push    bx

loadimage:
    mov     ax, word [cluster]
    call    fatcluster2lba
    call    lba2chs
    xor     dx, dx
    mov     dh, byte [SectorsPerCluster]
    pop     bx
    call    loadsectors
    add     bx, 0x200
    push    bx
    mov     ax, word [cluster]
    mov     cx, ax
    mov     dx, ax
    shr     dx, 0x0001
    add     cx, dx
    mov     bx, rootdirectory_and_fat_offset
    add     bx, cx
    mov     dx, word [bx]
    test    ax, 0x0001
    jnz     loadrootdirectory_oddcluster

loadrootdirectory_evencluster:
    and     dx, 0000111111111111b
    jmp     loadrootdirectory_done

loadrootdirectory_oddcluster:
    shr     dx, 0x0004

loadrootdirectory_done:
    mov     word [cluster], dx
    cmp     dx, 0x0ff0
    jb      loadimage

loadrootdirectory_end:
    pop     bx
    pop     bx
    ret

print_char:
    mov ah, 0x0E
    int 0x10
    ret
; ------------------------------------------------------------------
; data section
    current_directory_start     dw 0
    data_start                  dw 0

    sector db 0x00
    head db 0x00
    track db 0x00
    cluster dw 0x0000

    rootdirectory_and_fat_offset    equ 0x500
    image_offset                    equ 0x1200

    dataSectorBeginning         dw 0x0000

    dir_content_msg             db 'Directory content:', 13, 10, 0
    dir_indicator               db ' <DIR>', 0
    dir_not_found_msg           db 'Directory not found.', 13, 10, 0
    root_dir_msg                db 'Content:', 13, 10, 0
    read_failure                db 'Failed to read disk.', 13, 10, 0
    file_contents_msg           db 'File contents:', 13, 10, 0
    file_not_found_msg          db 'File not found.', 13, 10, 0
; ------------------------------------------------------------------