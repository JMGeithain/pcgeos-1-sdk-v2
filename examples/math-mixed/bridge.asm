; SPDX-License-Identifier: MIT
; Esp veneer for the example's own register ABI, not a GEOS system ABI.
        .8086

        global _ChecksumFar:far

BridgeCode segment resource

        public ChecksumStep
ChecksumStep proc far
        ; AX=state, DX=byte value. Return AX=result; preserve other registers.
        push bp
        push bx
        push cx
        push dx
        push si
        push di
        push ds
        push es
        ; __cdecl: rightmost argument first; far C has a 4-byte return CS:IP.
        push dx
        push ax
        call _ChecksumFar
        add sp,4
        pop es
        pop ds
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop bp
        ret
ChecksumStep endp

        public SaturatingAdd
SaturatingAdd proc far
        ; AX=a, DX=b. Return min(a+b,65535) in AX; preserve DX and others.
        add ax,dx
        jnc no_overflow
        mov ax,0ffffh
no_overflow:
        ret
SaturatingAdd endp

BridgeCode ends
        end
