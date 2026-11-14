; SPDX-License-Identifier: MIT
; An original 8086 GUI application for the observed Ensemble 1.2 ABI.
; No stock program's code, object chunks, icon or artwork is included.
%include "ensemble12.inc"
%define PROCESS_CLASS 0x40

G1_METHOD 0x0a01, app_open
G1_METHOD 0x0a03, app_close
G1_METHOD 0x0004, meta_attach
G1_METHOD 0x0057, view_closed
G1_METHOD 0x0049, view_exposed

app_open:
 push es
 pop ds
 mov di,PROCESS_CLASS
 KCALL 489                       ; ObjCallSuperNoLock, native register ABI.
 retf
app_close:
 xor cx,cx                        ; No application-owned state block to save.
 retf
meta_attach:
 mov di,PROCESS_CLASS
 KCALL 489
 retf
view_closed:
 mov di,PROCESS_CLASS
 KCALL 489
 retf

view_exposed:
 push cx
 call TestExampleLibraries
 mov [0xe0],ax
 pop cx
 mov di,cx                        ; CX is the exposed window handle.
 KCALL 211                        ; GrCreateState -> DI graphics state.
 KCALL 446                        ; GrBeginUpdate preserves native clipping.
 mov ax,15                        ; Indexed white, not direct framebuffer IO.
 KCALL 355                        ; GrSetAreaColor.
 xor ax,ax
 xor bx,bx
 mov cx,320
 mov dx,180
 KCALL 336                        ; GrFillRect, AX/BX left/top CX/DX right/bottom.
 mov ax,1                         ; Blue header and original simple illustration.
 KCALL 355
 mov ax,12
 mov bx,12
 mov cx,308
 mov dx,54
 KCALL 336
 mov ax,15
 KCALL 355
 push ds
 push cs
 pop ds
 mov si,welcome
 mov bp,24
 mov bx,24
 call pixel_string
 mov ax,2                         ; Green stack of resource-like rectangles.
 KCALL 355
 mov ax,24
 mov bx,82
 mov cx,85
 mov dx,139
 KCALL 336
 mov ax,3
 KCALL 355
 mov ax,31
 mov bx,75
 mov cx,92
 mov dx,132
 KCALL 336
 mov ax,11
 KCALL 355
 mov ax,38
 mov bx,68
 mov cx,99
 mov dx,125
 KCALL 336
 xor ax,ax
 KCALL 355
 mov si,caption
 mov bp,120
 mov bx,78
 call pixel_string
 mov si,pass_text
 pop ds
 cmp word [0xe0],0
 push ds
 push cs
 pop ds
 je .test_result
 mov si,fail_text
.test_result:
 mov bp,120
 mov bx,102
 call pixel_string
 pop ds
 KCALL 447                        ; GrEndUpdate.
 KCALL 212                        ; GrDestroyState: no retained GState/window.
 retf

; Text made from original 5x7 glyphs: no font number/API assumption, no bitmap
; borrowed from the supplied applications. Geometry uses 2x2 logical pixels.
; DS:SI strings index glyphs. BP left, BX top; DI native GState unchanged.
pixel_string:
 lodsb
 cmp al,0xff
 je .done
 push si
 xor ah,ah
 mov si,ax
 mov cl,3
 shl si,cl
 add si,glyphs
 mov dh,7
.row:
 lodsb
 mov dl,5
 push bp
.column:
 test al,0x10
 jz .skip
 push ax
 push bx
 push dx
 push si
 push bp
 mov ax,bp
 mov cx,bp
 add cx,1
 mov dx,bx
 inc dx
 KCALL 336
 pop bp
 pop si
 pop dx
 pop bx
 pop ax
.skip:
 shl al,1
 add bp,2
 dec dl
 jnz .column
 pop bp
 add bx,2
 dec dh
 jnz .row
 sub bx,14
 add bp,12
 pop si
 jmp pixel_string
.done:
 ret

%include "library_probe.inc"

; Glyph order: H E L O G S 1 D K 8 0 6 space A F I P.
glyphs:
 db 17,17,17,31,17,17,17,0
 db 31,16,16,30,16,16,31,0
 db 16,16,16,16,16,16,31,0
 db 14,17,17,17,17,17,14,0
 db 14,17,16,23,17,17,15,0
 db 15,16,16,14,1,1,30,0
 db 4,12,4,4,4,4,14,0
 db 30,17,17,17,17,17,30,0
 db 17,18,20,24,20,18,17,0
 db 14,17,17,14,17,17,14,0
 db 14,17,19,21,25,17,14,0
 db 6,8,16,30,17,17,14,0
 db 0,0,0,0,0,0,0,0
 db 14,17,17,31,17,17,17,0
 db 31,16,16,30,16,16,16,0
 db 14,4,4,4,4,4,14,0
 db 30,17,17,30,16,16,16,0
pass_text: db 16,13,5,5,0xff
fail_text: db 14,13,15,2,0xff
welcome: db 0,1,2,2,3,12,4,1,3,5,0xff
caption: db 5,7,8,12,6,0xff
caption2: db 9,10,9,11,0xff
G1_FINISH
