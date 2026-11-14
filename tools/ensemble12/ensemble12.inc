; SPDX-License-Identifier: MIT
; NASM flat-binary resource metadata. These macros do not call a modern C API.
%ifndef GEOS1_ENSEMBLE12_INC
%define GEOS1_ENSEMBLE12_INC
BITS 16
CPU 8086
ORG 0
section .text start=0 vstart=0 align=1
__g1_code_start:
section .g1methods follows=.text align=1
__g1_methods_start:
section .g1relocs follows=.g1methods align=1
__g1_relocs_start:
section .text

; Kernel's ordinal space is implicit in the 1.x loader.
%macro KCALL 1
 %%call:
 call 0:%1
 section .g1relocs follows=.g1methods align=1
 db 0,0
 dw %%call+1
 section .text
%endmacro

; A library import uses its zero-based header index (UI is index zero).
%macro LC 2
 %%call:
 call 0:%2
 section .g1relocs follows=.g1methods align=1
 db 0x14,%1
 dw %%call+1
 section .text
%endmacro

%macro G1_METHOD 2
 section .g1methods follows=.text align=1
 dw %1,%2
 section .text
%endmacro

; Must be the final source directive. The builder removes metadata from code.
%macro G1_FINISH 0
 __g1_code_end:
 section .g1methods follows=.text align=1
 __g1_methods_end:
 section .g1relocs follows=.g1methods align=1
 __g1_relocs_end:
 section .g1footer follows=.g1relocs align=1
 db 'G1META01'
 dw __g1_code_end-__g1_code_start
 dw __g1_methods_end-__g1_methods_start
 dw __g1_relocs_end-__g1_relocs_start
 dw 1
%endmacro
%endif
