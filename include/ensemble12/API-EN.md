# Ensemble 1.2 native API reference

This curated reference covers the 32 kernel calls recorded in the supplied native
ABI research. It targets the pinned runtime with kernel requirement **622.3** and
UI **693.0**. See [ABI files and conventions](README.md) and the
[machine-readable evidence](../../targetprofiles/ensemble12-abi.json). It is an
observed subset, not a complete OS binding or a promise about other 1.x versions.

All ordinals below belong to the implicit **kernel** ordinal space. Use the
`E12_K_` constant in NASM/Esp native call metadata or an explicit assembly bridge.
These are register contracts, not C function signatures. Preserved registers are
not exhaustively established. C code must not call an ordinal as a C pointer.

File read/write short transfers set carry and return an actual byte count in CX.
A DOS/driver error also sets carry, but CX is not guaranteed to hold a useful
actual count on that path. Keep callback lifetimes and caller-owned segments
explicit; do not retain pointers into a resource after releasing its lock.

## MemAlloc

`E12_K_MemAlloc` = **0** (`0000h`).

AX=bytes; CL=heap flags; CH=allocation flags. BX=allocated handle; locked allocation returns AX=segment. CF indicates failure.

Evidence: SPINTEXT code2:0x38, matching retained Bounce source.

## MemFree

`E12_K_MemFree` = **2** (`0002h`).

BX=memory handle.

Evidence: SPINTEXT code2:0xaf.

## MemLock

`E12_K_MemLock` = **5** (`0005h`).

BX=memory handle; AX=locked segment.

Evidence: SPINTEXT code2:0x9.

## MemUnlock

`E12_K_MemUnlock` = **6** (`0006h`).

BX=memory handle.

Evidence: SPINTEXT code2:0x1a.

## GeodeGetProcessHandle

`E12_K_GeodeGetProcessHandle` = **149** (`0095h`).

BX receives the current process handle.

Evidence: SPINTEXT code2:0xd6, retained Bounce source.

## GeodeGetResourceHandle

`E12_K_GeodeGetResourceHandle` = **150** (`0096h`).

BX=resource number; BX receives the loaded resource handle.

Evidence: SPINTEXT code2:0x64, retained Bounce source.

## ObjMessage

`E12_K_ObjMessage` = **169** (`00A9h`).

AX=message; BX:SI=destination handle:chunk; CX,DX,BP=message data; DI=message flags.

Evidence: SPINTEXT code2 repeated native sends.

## TimerSleep

`E12_K_TimerSleep` = **184** (`00B8h`).

AX=number of ticks to yield.

Evidence: runtime_audit agent Bounce matching retained source.

## GrCreateState

`E12_K_GrCreateState` = **211** (`00D3h`).

DI=window handle; DI receives a graphics-state handle.

Evidence: SPINTEXT code2:0x141.

## GrDestroyState

`E12_K_GrDestroyState` = **212** (`00D4h`).

DI=graphics-state handle.

Evidence: SPINTEXT code2:0x153.

## GrDrawRect

`E12_K_GrDrawRect` = **316** (`013Ch`).

DI=graphics state; AX,BX=left,top; CX,DX=right,bottom.

Evidence: TETRIS code2:0x4bd FillRect immediately followed call0x13c; KLIB code35:0x3d repeated box edges.

## GrDrawEllipse

`E12_K_GrDrawEllipse` = **324** (`0144h`).

DI=graphics state; AX,BX=left,top; CX,DX=right,bottom.

Evidence: KLIB code35:0x37e on new window, rectangle=-100,-100,0,0.

## GrDrawBitmap

`E12_K_GrDrawBitmap` = **326** (`0146h`).

DI=graphics state; AX,BX=position; DS:SI=bitmap; DX:CX=callback, with DX=0 for none.

Evidence: MOTIF code12:0x46e; DS=CS SI=0x478 bitmap 12x8, compact0,type0.

## GrDrawText

`E12_K_GrDrawText` = **330** (`014Ah`).

DI=graphics state; AX,BX=position; DS:SI=characters; CX=length, or 0 for NUL termination.

Evidence: SPINTEXT code2:0x1db.

## GrFillRect

`E12_K_GrFillRect` = **336** (`0150h`).

DI=graphics state; AX,BX=left,top; CX,DX=right,bottom.

Evidence: SPINTEXT code2:0x1f5.

## GrSetLineColor

`E12_K_GrSetLineColor` = **346** (`015Ah`).

DI=graphics state; AH=0 for palette-index mode; AL=palette index.

Evidence: KLIB code35:0x362; MOTIF code12:0x48c.

## GrSetAreaColor

`E12_K_GrSetAreaColor` = **355** (`0163h`).

DI=graphics state; AH=0 for palette-index mode; AL=palette index.

Evidence: SPINTEXT code2:0x1e4.

## GrSetAreaMask

`E12_K_GrSetAreaMask` = **356** (`0164h`).

DI=graphics state; AL=system mask index.

Evidence: TETRIS code3:0x3de and0x411.

## GrSetTextColor

`E12_K_GrSetTextColor` = **359** (`0167h`).

DI=graphics state; AH=0 for palette-index mode; AL=palette index.

Evidence: SPINTEXT code2:0x19f.

## GrSetTextStyle

`E12_K_GrSetTextStyle` = **362** (`016Ah`).

DI=graphics state; AL=style bits to set; AH=style bits to clear.

Evidence: SPINTEXT code2:0x16c, AL0x10 AH0xff.

## GrSetFont

`E12_K_GrSetFont` = **366** (`016Eh`).

DI=graphics state; CX=font identifier; DX=whole point size; AH=fractional point size.

Evidence: SPINTEXT code2:0x179; TETRIS code2:0x41c uses Berkeley0x0202 at12pt.

## GrGetWinBounds

`E12_K_GrGetWinBounds` = **440** (`01B8h`).

DI=graphics state; AX,BX,CX,DX receive window bounds.

Evidence: runtime_audit Bounce/source match.

## GrBeginUpdate

`E12_K_GrBeginUpdate` = **446** (`01BEh`).

DI=graphics state. Begin handling an exposed window region.

Evidence: SPINTEXT code2:0x146.

## GrEndUpdate

`E12_K_GrEndUpdate` = **447** (`01BFh`).

DI=graphics state. End handling the exposed region.

Evidence: SPINTEXT code2:0x14e.

## ObjCallSuperNoLock

`E12_K_ObjCallSuperNoLock` = **489** (`01E9h`).

AX=message; DS:DI=subclass record; other registers follow the message contract.

Evidence: SPINTEXT code2:0x27; retained Bounce source.

## FileSetCurrentPath

`E12_K_FileSetCurrentPath` = **51** (`0033h`).

BX=disk handle; DS:DX=NUL-terminated path; CF indicates failure.

Evidence: NINFNT code5:0xa7 and VIEWER code5:0x72a.

## FileOpen

`E12_K_FileOpen` = **52** (`0034h`).

AL=access flags; DS:DX=NUL-terminated path; AX=file handle on success, error on CF.

Evidence: VIEWER code5:0x73d AL0xc0; WRITE code2:0x818 AL0xa0.

## FileCreate

`E12_K_FileCreate` = **53** (`0035h`).

AH=create flags; AL=access flags; CX=DOS attributes; DS:DX=path; AX=handle or CF/error.

Evidence: DUMP code4:0x5fc AX0x00c1 CX0; WRITE code2:0x722 AH2 AL0x92.

## FileClose

`E12_K_FileClose` = **54** (`0036h`).

BX=file handle; AL=error policy, 0 recoverable or 80h mandatory; CF indicates failure.

Evidence: VIEWER code5:0x785; DUMP code4:0x83e AL0.

## FileRead

`E12_K_FileRead` = **58** (`003Ah`).

BX=file handle; CX=requested bytes; DS:DX=buffer; AL=0 recoverable policy; CF indicates incomplete/error; CX=actual bytes for a short transfer.

Evidence: NOTEPAD code2:0x29f; VIEWER code5:0x13c8.

## FileWrite

`E12_K_FileWrite` = **59** (`003Bh`).

BX=file handle; CX=requested bytes; DS:DX=buffer; AL=0 recoverable policy; CF indicates incomplete/error; CX=actual bytes for a short transfer.

Evidence: DUMP code4:0x442/0x460; NOTEPAD code2:0x4ba.

## FilePos

`E12_K_FilePos` = **60** (`003Ch`).

BX=file handle; CX:DX=signed offset; AL=origin 0=start,1=current, 2=end; DX:AX=resulting position.

Evidence: NOTEPAD code2:0x23b endseek then0x248 startseek.

## UI classes

| Class | Ordinal | Constant |
|---|---:|---|
| `GenProcessClass` | 0 | `E12_UI_GenProcessClass` |
| `GenTriggerClass` | 68 | `E12_UI_GenTriggerClass` |
| `GenApplicationClass` | 71 | `E12_UI_GenApplicationClass` |
| `GenViewClass` | 75 | `E12_UI_GenViewClass` |
| `GenTextClass` | 86 | `E12_UI_GenTextClass` |
| `GenPrimaryClass` | 88 | `E12_UI_GenPrimaryClass` |

These class ordinals belong to the imported `ui` module.

## Messages

| Message | Value |
|---|---:|
| `E12_MSG_META_EXPOSED` | `0049h` |
| `E12_MSG_META_CONTENT_VIEW_WIN_OPENED` | `0056h` |
| `E12_MSG_META_CONTENT_VIEW_WIN_CLOSED` | `0057h` |
| `E12_MSG_META_KBD_CHAR` | `007Bh` |
| `E12_MSG_META_START_SELECT` | `00C3h` |
| `E12_MSG_META_END_SELECT` | `00C4h` |
| `E12_MSG_GEN_PROCESS_OPEN_APPLICATION` | `0A01h` |
| `E12_MSG_GEN_PROCESS_CLOSE_APPLICATION` | `0A03h` |

`MSG_META_DRAG_SELECT` is omitted because the supplied reference labels its value inferred.
