# Native Ensemble-1.2-API-Referenz

Diese Auswahl umfasst die 32 Kernel-Aufrufe der bereitgestellten nativen
ABI-Untersuchungen. Sie gilt für das festgelegte Ziel mit Kernel-Anforderung
**622.3** und UI **693.0**. Siehe [ABI-Dateien und Konventionen](README.md) und
[maschinenlesbare Belege](../../targetprofiles/ensemble12-abi.json). Sie ist keine
vollständige Betriebssystemanbindung und bestätigt keine anderen 1.x-Versionen.

Alle nachfolgenden Ordinale gehören zum impliziten **Kernel**-Ordinalraum.
Verwenden Sie `E12_K_`-Konstanten mit den nativen NASM-/Esp-Aufrufmetadaten oder
einer ausdrücklichen Assembler-Brücke. Es handelt sich um Registerverträge, nicht
um C-Funktionssignaturen. Die vollständige Registererhaltung wurde nicht für jeden
Aufruf festgestellt. Ein Ordinalwert darf nicht wie ein C-Funktionszeiger aufgerufen
werden.

Kurze Dateiübertragungen setzen Carry und liefern in CX die tatsächliche Bytezahl.
Auch ein DOS-/Treiberfehler setzt Carry; auf diesem Pfad muss CX keine brauchbare
Bytezahl enthalten. Lebensdauer von Rückrufen und Segmentzuordnungen müssen
ausdrücklich geregelt sein. Nach dem Entsperren einer Ressource dürfen Zeiger
auf deren Daten nicht weiterverwendet werden.

## MemAlloc

`E12_K_MemAlloc` = **0** (`0000h`).

AX=Bytezahl; CL=Heap-Flags; CH=Allokationsflags. BX erhält den Speicherhandle; bei gesperrter Allokation erhält AX das Segment. CF zeigt einen Fehler an.

Beleg: SPINTEXT code2:0x38, matching retained Bounce source.

## MemFree

`E12_K_MemFree` = **2** (`0002h`).

BX=Speicherhandle.

Beleg: SPINTEXT code2:0xaf.

## MemLock

`E12_K_MemLock` = **5** (`0005h`).

BX=Speicherhandle; AX erhält das gesperrte Segment.

Beleg: SPINTEXT code2:0x9.

## MemUnlock

`E12_K_MemUnlock` = **6** (`0006h`).

BX=Speicherhandle.

Beleg: SPINTEXT code2:0x1a.

## GeodeGetProcessHandle

`E12_K_GeodeGetProcessHandle` = **149** (`0095h`).

BX erhält den Handle des aktuellen Prozesses.

Beleg: SPINTEXT code2:0xd6, retained Bounce source.

## GeodeGetResourceHandle

`E12_K_GeodeGetResourceHandle` = **150** (`0096h`).

BX=Ressourcennummer; BX erhält den Handle der geladenen Ressource.

Beleg: SPINTEXT code2:0x64, retained Bounce source.

## ObjMessage

`E12_K_ObjMessage` = **169** (`00A9h`).

AX=Nachricht; BX:SI=Zielhandle:Chunk; CX, DX, BP=Nachrichtenparameter; DI=Nachrichtenflags.

Beleg: SPINTEXT code2 repeated native sends.

## TimerSleep

`E12_K_TimerSleep` = **184** (`00B8h`).

AX=Anzahl der abzugebenden Zeittakte.

Beleg: runtime_audit agent Bounce matching retained source.

## GrCreateState

`E12_K_GrCreateState` = **211** (`00D3h`).

DI=Fensterhandle; DI erhält einen Grafikzustandshandle.

Beleg: SPINTEXT code2:0x141.

## GrDestroyState

`E12_K_GrDestroyState` = **212** (`00D4h`).

DI=Grafikzustandshandle.

Beleg: SPINTEXT code2:0x153.

## GrDrawRect

`E12_K_GrDrawRect` = **316** (`013Ch`).

DI=Grafikzustand; AX, BX=links, oben; CX, DX=rechts, unten.

Beleg: TETRIS code2:0x4bd FillRect immediately followed call0x13c; KLIB code35:0x3d repeated box edges.

## GrDrawEllipse

`E12_K_GrDrawEllipse` = **324** (`0144h`).

DI=Grafikzustand; AX, BX=links, oben; CX, DX=rechts, unten.

Beleg: KLIB code35:0x37e on new window, rectangle=-100,-100,0,0.

## GrDrawBitmap

`E12_K_GrDrawBitmap` = **326** (`0146h`).

DI=Grafikzustand; AX, BX=Position; DS:SI=Bitmap; DX:CX=Rückruffunktion, bei DX=0 ohne Rückruf.

Beleg: MOTIF code12:0x46e; DS=CS SI=0x478 bitmap 12x8, compact0,type0.

## GrDrawText

`E12_K_GrDrawText` = **330** (`014Ah`).

DI=Grafikzustand; AX, BX=Position; DS:SI=Zeichen; CX=Länge oder 0 für NUL-Abschluss.

Beleg: SPINTEXT code2:0x1db.

## GrFillRect

`E12_K_GrFillRect` = **336** (`0150h`).

DI=Grafikzustand; AX, BX=links, oben; CX, DX=rechts, unten.

Beleg: SPINTEXT code2:0x1f5.

## GrSetLineColor

`E12_K_GrSetLineColor` = **346** (`015Ah`).

DI=Grafikzustand; AH=0 für Palettenindex-Modus; AL=Palettenindex.

Beleg: KLIB code35:0x362; MOTIF code12:0x48c.

## GrSetAreaColor

`E12_K_GrSetAreaColor` = **355** (`0163h`).

DI=Grafikzustand; AH=0 für Palettenindex-Modus; AL=Palettenindex.

Beleg: SPINTEXT code2:0x1e4.

## GrSetAreaMask

`E12_K_GrSetAreaMask` = **356** (`0164h`).

DI=Grafikzustand; AL=Index einer Systemmaske.

Beleg: TETRIS code3:0x3de and0x411.

## GrSetTextColor

`E12_K_GrSetTextColor` = **359** (`0167h`).

DI=Grafikzustand; AH=0 für Palettenindex-Modus; AL=Palettenindex.

Beleg: SPINTEXT code2:0x19f.

## GrSetTextStyle

`E12_K_GrSetTextStyle` = **362** (`016Ah`).

DI=Grafikzustand; AL=zu setzende Stilbits; AH=zu löschende Stilbits.

Beleg: SPINTEXT code2:0x16c, AL0x10 AH0xff.

## GrSetFont

`E12_K_GrSetFont` = **366** (`016Eh`).

DI=Grafikzustand; CX=Schriftkennung; DX=ganzzahliger Teil der Punktgröße; AH=Bruchteil der Punktgröße.

Beleg: SPINTEXT code2:0x179; TETRIS code2:0x41c uses Berkeley0x0202 at12pt.

## GrGetWinBounds

`E12_K_GrGetWinBounds` = **440** (`01B8h`).

DI=Grafikzustand; AX, BX, CX, DX erhalten die Fenstergrenzen.

Beleg: runtime_audit Bounce/source match.

## GrBeginUpdate

`E12_K_GrBeginUpdate` = **446** (`01BEh`).

DI=Grafikzustand. Beginnt die Bearbeitung des neu zu zeichnenden Fensterbereichs.

Beleg: SPINTEXT code2:0x146.

## GrEndUpdate

`E12_K_GrEndUpdate` = **447** (`01BFh`).

DI=Grafikzustand. Beendet die Bearbeitung des neu zu zeichnenden Bereichs.

Beleg: SPINTEXT code2:0x14e.

## ObjCallSuperNoLock

`E12_K_ObjCallSuperNoLock` = **489** (`01E9h`).

AX=Nachricht; DS:DI=Klassendatensatz der Unterklasse; weitere Register folgen dem Nachrichtenvertrag.

Beleg: SPINTEXT code2:0x27; retained Bounce source.

## FileSetCurrentPath

`E12_K_FileSetCurrentPath` = **51** (`0033h`).

BX=Datenträgerhandle; DS:DX=NUL-abgeschlossener Pfad; CF zeigt einen Fehler an.

Beleg: NINFNT code5:0xa7 and VIEWER code5:0x72a.

## FileOpen

`E12_K_FileOpen` = **52** (`0034h`).

AL=Zugriffsflags; DS:DX=NUL-abgeschlossener Pfad; AX=Dateihandle bei Erfolg, Fehlercode bei gesetztem CF.

Beleg: VIEWER code5:0x73d AL0xc0; WRITE code2:0x818 AL0xa0.

## FileCreate

`E12_K_FileCreate` = **53** (`0035h`).

AH=Erstellungsflags; AL=Zugriffsflags; CX=DOS-Attribute; DS:DX=Pfad; AX=Dateihandle oder Fehlercode bei gesetztem CF.

Beleg: DUMP code4:0x5fc AX0x00c1 CX0; WRITE code2:0x722 AH2 AL0x92.

## FileClose

`E12_K_FileClose` = **54** (`0036h`).

BX=Dateihandle; AL=Fehlerbehandlung, 0 behandelbar oder 80h zwingend; CF zeigt einen Fehler an.

Beleg: VIEWER code5:0x785; DUMP code4:0x83e AL0.

## FileRead

`E12_K_FileRead` = **58** (`003Ah`).

BX=Dateihandle; CX=gewünschte Bytezahl; DS:DX=Puffer; AL=0 für behandelbare Fehler. CF zeigt unvollständige Übertragung oder Fehler an; bei kurzer Übertragung enthält CX die tatsächliche Bytezahl.

Beleg: NOTEPAD code2:0x29f; VIEWER code5:0x13c8.

## FileWrite

`E12_K_FileWrite` = **59** (`003Bh`).

BX=Dateihandle; CX=gewünschte Bytezahl; DS:DX=Puffer; AL=0 für behandelbare Fehler. CF zeigt unvollständige Übertragung oder Fehler an; bei kurzer Übertragung enthält CX die tatsächliche Bytezahl.

Beleg: DUMP code4:0x442/0x460; NOTEPAD code2:0x4ba.

## FilePos

`E12_K_FilePos` = **60** (`003Ch`).

BX=Dateihandle; CX:DX=vorzeichenbehafteter Offset; AL=Bezug 0=Anfang, 1=aktuelle Position, 2=Ende. DX:AX enthält die resultierende Position.

Beleg: NOTEPAD code2:0x23b endseek then0x248 startseek.

## UI-Klassen

| Klasse | Ordinal | Konstante |
|---|---:|---|
| `GenProcessClass` | 0 | `E12_UI_GenProcessClass` |
| `GenTriggerClass` | 68 | `E12_UI_GenTriggerClass` |
| `GenApplicationClass` | 71 | `E12_UI_GenApplicationClass` |
| `GenViewClass` | 75 | `E12_UI_GenViewClass` |
| `GenTextClass` | 86 | `E12_UI_GenTextClass` |
| `GenPrimaryClass` | 88 | `E12_UI_GenPrimaryClass` |

Die Ordinale dieser Tabelle gehören zum importierten Modul `ui`.

## Nachrichten

| Nachricht | Wert |
|---|---:|
| `E12_MSG_META_EXPOSED` | `0049h` |
| `E12_MSG_META_CONTENT_VIEW_WIN_OPENED` | `0056h` |
| `E12_MSG_META_CONTENT_VIEW_WIN_CLOSED` | `0057h` |
| `E12_MSG_META_KBD_CHAR` | `007Bh` |
| `E12_MSG_META_START_SELECT` | `00C3h` |
| `E12_MSG_META_END_SELECT` | `00C4h` |
| `E12_MSG_GEN_PROCESS_OPEN_APPLICATION` | `0A01h` |
| `E12_MSG_GEN_PROCESS_CLOSE_APPLICATION` | `0A03h` |

`MSG_META_DRAG_SELECT` fehlt: Der bereitgestellte Beleg kennzeichnet den Wert als vermutet.
