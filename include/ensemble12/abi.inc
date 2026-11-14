; SPDX-License-Identifier: MIT
; Native register ABI for the exact supplied Ensemble1.2 target.
; Constants only. Kernel calls need source0/type0 relocation on a FAR operand.
; Imported UI calls need source1/type4, class references pairedtype1/type2.
; See targetprofiles/ensemble12-abi.json for contracts and evidence.
%ifndef PCGEOS1_ENSEMBLE12_ABI_INC
%define PCGEOS1_ENSEMBLE12_ABI_INC 1
%define E12_KERNEL_PROTOCOL_MAJOR 622
%define E12_KERNEL_PROTOCOL_MINOR 3
%define E12_UI_PROTOCOL_MAJOR 693
%define E12_UI_PROTOCOL_MINOR 0
%define E12_K_MemAlloc 0
%define E12_K_MemFree 2
%define E12_K_MemLock 5
%define E12_K_MemUnlock 6
%define E12_K_GeodeGetProcessHandle 149
%define E12_K_GeodeGetResourceHandle 150
%define E12_K_ObjMessage 169
%define E12_K_TimerSleep 184
%define E12_K_GrCreateState 211
%define E12_K_GrDestroyState 212
%define E12_K_GrDrawRect 316
%define E12_K_GrDrawEllipse 324
%define E12_K_GrDrawBitmap 326
%define E12_K_GrDrawText 330
%define E12_K_GrFillRect 336
%define E12_K_GrSetLineColor 346
%define E12_K_GrSetAreaColor 355
%define E12_K_GrSetAreaMask 356
%define E12_K_GrSetTextColor 359
%define E12_K_GrSetTextStyle 362
%define E12_K_GrSetFont 366
%define E12_K_GrGetWinBounds 440
%define E12_K_GrBeginUpdate 446
%define E12_K_GrEndUpdate 447
%define E12_K_ObjCallSuperNoLock 489
%define E12_K_FileSetCurrentPath 51
%define E12_K_FileOpen 52
%define E12_K_FileCreate 53
%define E12_K_FileClose 54
%define E12_K_FileRead 58
%define E12_K_FileWrite 59
%define E12_K_FilePos 60
%define E12_UI_GenProcessClass 0
%define E12_UI_GenTriggerClass 68
%define E12_UI_GenApplicationClass 71
%define E12_UI_GenViewClass 75
%define E12_UI_GenTextClass 86
%define E12_UI_GenPrimaryClass 88
%define E12_MSG_META_EXPOSED 73
%define E12_MSG_META_CONTENT_VIEW_WIN_OPENED 86
%define E12_MSG_META_CONTENT_VIEW_WIN_CLOSED 87
%define E12_MSG_META_KBD_CHAR 123
%define E12_MSG_META_START_SELECT 195
%define E12_MSG_META_END_SELECT 196
%define E12_MSG_GEN_PROCESS_OPEN_APPLICATION 2561
%define E12_MSG_GEN_PROCESS_CLOSE_APPLICATION 2563
%define E12_BITMAP_HEADER_BYTES 6
%define E12_BITMAP_MONO 0
%define E12_BITMAP_4BIT 1
%define E12_BITMAP_MASK 16
%endif
