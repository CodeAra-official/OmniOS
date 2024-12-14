; OmniOS Bootloader v1.0 (fat12 impl)
[BITS 16]
[ORG 0x7C00]

jmp short start
nop

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

DriveNumber		    db 0		        ; The drive number.
                    db 0
Signature	        db 41		        ; Signature 41 is for floppy disks.
VolumeID		    db 12h,34h,56h,78h  ; A random ID.
VolumeLabel		    db "OmniOS      "    ; The volume label.
FileSystem		    db "FAT12   "	    ; The file system that is being used (FAT12)


start:
    ; Set up segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; clear the screen
    mov ax, 02
    int 0x10

     mov ah, 0x06    ; وظيفة التمرير (Scrolling function)
     mov bh, 0x07    ; النص أبيض (0x7) والخلفية سوداء (0x0)
     mov ch, 00d     ; الصف الأول (البداية)
     mov cl, 00d     ; العمود الأول (البداية)
     mov dh, 24d     ; الصف الأخير (النهاية)
     mov dl, 79d     ; العمود الأخير (النهاية)
     int 10h         ; استدعاء مقاطعة الفيديو


    ; then we move the cursor
    mov ah, 0x02	; move cursor Instruction
    mov bh, 0x00	; page
    mov dh, 0x00	; row
    mov dl, 0x00	; column
    int 10h
    
    mov si, boot_msg
    call print_string

    mov [bootdevice], dl    ; Save boot device number

    jmp load_RootDirectory


load_RootDirectory:
    mov ax, [SectorsPerFAT]
    mov bl, [NumberOfFATs]
    xor bh, bh
    mul bx                      ; Gives the 18 Sectors
    add ax, [ReservedSectors]   ; LBA of the root directory
    push ax

    mov ax, [RootDirEntries]
    shl ax, 5 ;ax *= 32
    xor dx, dx
    div word [BytesPerSector]   ; (32*num of entries)/bytes per sector

    test dx, dx
    jz after_load
    inc ax

after_load:
    mov cl, al
    pop ax
    mov dl, [DriveNumber]
    mov bx, buffer
    call disk_read

    xor bx, bx
    mov di, buffer

; ------------------------------------------------------------------
; Here, we search for the kernel

kernel_search:
    mov si, filename
    mov cx, 11
    push di
    repe cmpsb
    pop di
    je kernel_found

    add di, 32
    inc bx
    cmp bx, [RootDirEntries]
    jl kernel_search

    jmp kernel_notfound

kernel_notfound:
    mov si, not_found
    call print_string

    hlt
    jmp $

kernel_found:
    mov ax, [di+26] ; di is address of kernel, 26 offset to first cluster field
    mov [cluster], ax

    mov ax, [ReservedSectors]
    mov bx, buffer
    mov cl, [SectorsPerFAT]
    mov dl, [DriveNumber]

    call disk_read

    mov bx, kernel_load_segment
    mov es, bx
    mov bx, kernel_load_offset

    mov si, loading_msg
    call print_string

kernel_load:
    mov ax, [cluster]
    add ax, 31  ; For floppy disk
    mov cl, 1
    mov dl, [DriveNumber]

    call disk_read

    add bx, [BytesPerSector]

    mov ax, [cluster] ;(Kernel Cluster * 3)/2
    mov cx, 3
    mul cx
    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz even ; Even, otherwise odd

odd:
    shr ax, 4
    jmp next_ClusterAfter

even:
    and ax, 0x0FFF
    
next_ClusterAfter:
    cmp ax, 0x0FF8
    jae read_finish

    mov [cluster], ax
    jmp kernel_load

read_finish:
    mov dl, [DriveNumber]
    mov ax, kernel_load_segment
    mov ds, ax
    mov es, ax
    
    jmp kernel_load_segment:kernel_load_offset

    hlt

; ------------------------------------------------------------------
; basic functions
print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print_string
.done:
    ret
; ------------------------------------------------------------------
; data section

    boot_msg db ' OmniOS 1.0', 13, 10, 0
    loading_msg db ' Starting..', 13, 10, 0

    %INCLUDE "src/Boot/Disk.asm"

    filename    db "KERNEL  BIN"

    not_found   db " Erorr(455): KERNEL file was not found!" , 0

    bootdevice  db 0
    cluster		dw 0

    kernel_load_segment equ 0x2000
    kernel_load_offset equ 0

; ------------------------------------------------------------------
; end of boot sector

	times 510-($-$$) db 0
	dw 0AA55h

buffer: