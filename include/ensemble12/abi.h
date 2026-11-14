/* SPDX-License-Identifier: MIT
 * Original factual constants for the supplied Ensemble1.2 target only.
 * Native register calls are not C functions: no callable prototypes supplied.
 * Evidence and contracts: targetprofiles/ensemble12-abi.json.
 */
#ifndef PCGEOS1_ENSEMBLE12_ABI_H
#define PCGEOS1_ENSEMBLE12_ABI_H

#define E12_KERNEL_PROTOCOL_MAJOR 622u
#define E12_KERNEL_PROTOCOL_MINOR 3u
#define E12_UI_PROTOCOL_MAJOR 693u
#define E12_UI_PROTOCOL_MINOR 0u
#define E12_K_MemAlloc 0u
#define E12_K_MemFree 2u
#define E12_K_MemLock 5u
#define E12_K_MemUnlock 6u
#define E12_K_GeodeGetProcessHandle 149u
#define E12_K_GeodeGetResourceHandle 150u
#define E12_K_ObjMessage 169u
#define E12_K_TimerSleep 184u
#define E12_K_GrCreateState 211u
#define E12_K_GrDestroyState 212u
#define E12_K_GrDrawRect 316u
#define E12_K_GrDrawEllipse 324u
#define E12_K_GrDrawBitmap 326u
#define E12_K_GrDrawText 330u
#define E12_K_GrFillRect 336u
#define E12_K_GrSetLineColor 346u
#define E12_K_GrSetAreaColor 355u
#define E12_K_GrSetAreaMask 356u
#define E12_K_GrSetTextColor 359u
#define E12_K_GrSetTextStyle 362u
#define E12_K_GrSetFont 366u
#define E12_K_GrGetWinBounds 440u
#define E12_K_GrBeginUpdate 446u
#define E12_K_GrEndUpdate 447u
#define E12_K_ObjCallSuperNoLock 489u
#define E12_K_FileSetCurrentPath 51u
#define E12_K_FileOpen 52u
#define E12_K_FileCreate 53u
#define E12_K_FileClose 54u
#define E12_K_FileRead 58u
#define E12_K_FileWrite 59u
#define E12_K_FilePos 60u
#define E12_UI_GenProcessClass 0u
#define E12_UI_GenTriggerClass 68u
#define E12_UI_GenApplicationClass 71u
#define E12_UI_GenViewClass 75u
#define E12_UI_GenTextClass 86u
#define E12_UI_GenPrimaryClass 88u
#define E12_MSG_META_EXPOSED 73u
#define E12_MSG_META_CONTENT_VIEW_WIN_OPENED 86u
#define E12_MSG_META_CONTENT_VIEW_WIN_CLOSED 87u
#define E12_MSG_META_KBD_CHAR 123u
#define E12_MSG_META_START_SELECT 195u
#define E12_MSG_META_END_SELECT 196u
#define E12_MSG_GEN_PROCESS_OPEN_APPLICATION 2561u
#define E12_MSG_GEN_PROCESS_CLOSE_APPLICATION 2563u

typedef unsigned char E12Byte;
typedef unsigned short E12Word;
typedef struct E12Optr { E12Word chunk; E12Word handle; } E12Optr;
typedef char E12WordMustBe16Bits[(sizeof(E12Word)==2)?1:-1];
typedef char E12OptrMustBe4Bytes[(sizeof(E12Optr)==4)?1:-1];

/* Bitmap headers are encoded as six bytes, not sizeof a host structure. */
#define E12_BITMAP_HEADER_BYTES 6u
#define E12_BITMAP_MONO 0u
#define E12_BITMAP_4BIT 1u
#define E12_BITMAP_MASK 16u

#endif
