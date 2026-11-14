; SPDX-License-Identifier: MIT
; Included by the original NASM GUI shell, which supplies LC import,ordinal.
; Import0 is UI; imports1/2/3 are g1math/g1mathc/g1mixed, protocol1.0.
; Uses only 8086 instructions. No C runtime, global state or GEOS C API.

TestExampleLibraries:
        push bp
        push bx
        push cx
        push dx
        push si
        push di
        push ds
        push es

        ; Assembly library's own register ABI: AX+BX -> AX, modulo65536.
        mov ax,1234h
        mov bx,4321h
        LC 1,0
        cmp ax,5555h
        jne .assembly_failed

        ; C library's own far __cdecl ABI: push right argument first.
        ; Use MOV/PUSH registers: PUSH immediate would require80186.
        mov ax,0056h
        push ax
        mov ax,1234h
        push ax
        LC 2,0
        add sp,4
        cmp ax,46d4h
        jne .c_failed

        ; Mixed library's register veneer saves the C-volatile registers.
        mov ax,1234h
        mov dx,0056h
        LC 3,0
        cmp ax,46d4h
        jne .mixed_failed
        cmp dx,0056h
        jne .mixed_failed

        mov ax,0ffffh
        mov dx,1
        LC 3,1
        cmp ax,0ffffh
        jne .saturation_failed
        mov ax,1234h
        mov dx,4321h
        LC 3,1
        cmp ax,5555h
        jne .addition_failed
        xor ax,ax
        jmp .done

.assembly_failed:
        mov ax,1
        jmp .done
.c_failed:
        mov ax,2
        jmp .done
.mixed_failed:
        mov ax,3
        jmp .done
.saturation_failed:
        mov ax,4
        jmp .done
.addition_failed:
        mov ax,5
.done:
        pop es
        pop ds
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop bp
        ret
