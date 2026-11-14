; SPDX-License-Identifier: MIT
; An import-free library, written in Esp object assembly syntax.
; This file deliberately does not include any 2.x SDK API definitions.

        .8086

idata   segment
idata   ends

udata   segment
udata   ends

dgroup  group   idata, udata

MathCode segment resource

        public  LibraryEntry
LibraryEntry proc far
        ; Native library initialization notification: no work, success.
        ; No C runtime, floating point, heap, thread or graphics dependency.
        clc
        ret
LibraryEntry endp

        public  AddWords
AddWords proc far
        ; Library's own register ABI (not a claimed kernel C ABI):
        ; input AX=a, BX=b; output AX=(a+b) modulo 65536.
        ; BX/CX/DX/SI/DI/BP/DS/ES and the caller's stack are preserved.
        ; Arithmetic flags are unspecified.
        add     ax, bx
        ret
AddWords endp

MathCode ends
        end
