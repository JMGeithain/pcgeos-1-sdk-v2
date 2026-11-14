# Observed Ensemble 1.2 ABI / Beobachtete Ensemble-1.2-ABI

These original include files describe a small, explicit subset of the supplied
runtime: kernel requirement 622.3, UI 693.0. They contain numeric interface facts
and data types, not extracted code, application resources or a later SDK's headers.
The full register contracts and evidence are recorded in
[`ensemble12-abi.json`](../../targetprofiles/ensemble12-abi.json).
The readable references are [English](API-EN.md) and [Deutsch](API-DE.md).

| File | Use |
|---|---|
| `abi.h` | C constants and a four-byte `E12Optr`; no callable OS prototypes |
| `abi.inc` | NASM constants for original native assembly |
| `abi.def` | Esp/MASM-style numeric constants |

The C compiler's calling convention does not become the GEOS register convention
by including a header. Call native interfaces through a reviewed assembly bridge
that handles the relevant registers, segment ownership, stack and result flags.
These constants do not establish every preserved register for every kernel call.

Class ordinals refer to the imported `ui` library, not to the kernel. Kernel far
calls use source 0/type 0 relocation; imported library calls use source 1/type 4.
An imported class pointer uses separate offset and segment relocations, source 1,
types 1 and 2. Never use a live segment address from a previous run.

`MSG_META_DRAG_SELECT` is intentionally absent: the supplied reference labels its
value as inferred. Current PC/GEOS 2.x or newer API numbering is not substituted.
Verify your own runtime directory before building target-specific applications:

```sh
perl sdk.pl verify-target /path/to/GWSVGA
```

See the target profile for exact required file hashes. Matching identities and
valid geode structures are evidence about files; native execution remains a
separate check. No supplied proprietary runtime files are redistributed here.

## Deutsch

Diese eigenständig erstellten Include-Dateien beschreiben einen kleinen,
ausdrücklichen Teil der bereitgestellten Laufzeit: Kernel-Anforderung 622.3,
UI 693.0. Sie enthalten numerische Schnittstellenwerte und Datentypen, keinen
extrahierten Programmcode und keine Anwendungsressourcen. Registerverträge und
Belege stehen in `targetprofiles/ensemble12-abi.json`.

`abi.h` liefert C-Konstanten und den vier Byte großen Typ `E12Optr`, aber keine
aufrufbaren Betriebssystem-Prototypen. `abi.inc` verwendet NASM-Syntax;
`abi.def` enthält Konstanten in Esp/MASM-Syntax. Eine geprüfte Assembler-Brücke
muss die native Registerkonvention, Segmentzuordnung, den Stack und Ergebnisflags
beachten. Die Include-Datei ändert die C-Aufrufkonvention nicht.

Klassenordinale gehören zur importierten Bibliothek `ui`. Kernel-Fernaufrufe
verwenden Relokationsquelle 0, Typ 0; Bibliotheksaufrufe Quelle 1, Typ 4.
Klassenzeiger benötigen getrennte Offset- und Segmentrelokationen der Typen 1
und 2. Die nur vermutete Konstante `MSG_META_DRAG_SELECT` wird nicht angeboten.
Prüfen Sie das eigene Laufzeitverzeichnis mit dem oben gezeigten Befehl.
Passende Hashwerte bestätigen die Dateiidentität, nicht das Verhalten jeder
Anwendung. Proprietäre Laufzeitdateien werden nicht mitgeliefert.
