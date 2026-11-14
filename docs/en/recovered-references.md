# Recovered applications: practical lessons and provenance

[Handbook](README.md) · [Deutsch](../de/recovered-references.md)

The supplied GeoSheet, GNU Chess and 3D Bounce development packages add
specific Ensemble 1.2 evidence to the public, later GEOS sources. They are
research inputs, not a redistributable copy of the commercial runtime. This
page explains what can be learned from them and how the new original GUI
example is constructed without copying an older application's resources.

Earlier successful application reports apply to their recorded binaries and
configurations. The SDK's current validation report identifies the actual new
outputs, hashes, tests and remaining gaps.

## Reference inventory

These paths identify files **inside the supplied reference archives**. The
archives are not silently included in the public SDK. A historical script name in this inventory records provenance; it is not a host dependency of the Perl SDK.

| Reference | Exact source location | What it helps establish |
|---|---|---|
| GeoSheet | `GeoSheet-PCGEOS1-v02/source/spreadsheet/native/objects/NATIVE-ABI-NOTES.md` | Native objects, document controllers, input and file-I/O lessons. |
| GeoSheet | `GeoSheet-PCGEOS1-v02/source/spreadsheet/toolchain/TOOLCHAIN.md` | 16-bit C, resource boundaries, relocations and callback lifetime. |
| GeoSheet | `GeoSheet-PCGEOS1-v02/source/spreadsheet/native/objects/build_object_scaffold.py` | Observed LMem packing and object links, with template ownership limits. |
| GeoSheet | `GeoSheet-PCGEOS1-v02/LICENSE.txt` | MIT scope for newly written code and explicit exclusions. |
| GNU Chess | `GNUChess-Ensemble1-MoveEntry/DEVELOPMENT/PORTING.txt` | Native one-line input, focus, form state and recorded test scope. |
| GNU Chess | `GNUChess-Ensemble1-MoveEntry/SOURCE/port1/api/ensemble12-api.json` | Observed interface facts, register contracts and source evidence. |
| GNU Chess | `GNUChess-Ensemble1-MoveEntry/COPYING.txt` | GPL 3 text; source-level notices remain relevant. |
| 3D Bounce | `3D-Bounce-PC-GEOS-8086/Source/Measurement/TIMER-ABI.md` | Tick-counter and timer-queue behavior. |
| 3D Bounce | `3D-Bounce-PC-GEOS-8086/README.md` and `TEST-REPORT.md` | File/scratch sizes, emulator profiles and measurement limits. |

Public source definitions are pinned separately. The original native file
writer follows `Tools/include/geode.h`, `Tools/include/os90File.h` and
`Tools/glue/geo.c` at revision
`260b33dcfcac15b7ecfdf04242cb0abf029ec269`. The class record is cross-checked
against the legacy `Class_rel1` representation in `Tools/esp/object.c`.
See [primary references](references.md) for the official source links.

## A concrete target, rather than a universal 1.x ABI

The observed installation requires kernel 622.3 and UI 693.0; its Motif library
has protocol 693.1. The target profile records exact identities for
`KERNEL.EXE`, `SYSTEM/UI.GEO` and `SYSTEM/MOTIF.GEO`.

```sh
perl tools/geos1/cli.pl verify-target /path/to/owned/GWSVGA
```

This checks the files against
[`supplied-ensemble12.json`](../../targetprofiles/supplied-ensemble12.json).
It is not an installation download or a certification that every interface in
those modules has been examined. A different localized release, patched UI or
specific UI can have different hashes. Establish a new audited profile for that
target; do not weaken the existing identity check until unrelated files pass.

The curated interface inventory is
[`ensemble12-abi.json`](../../targetprofiles/ensemble12-abi.json). The original
[include files](../../include/ensemble12/README.md) provide NASM/Esp constants
and C constants/types for that subset. `abi.h` does **not** supply callable C
system wrappers. Including it does not transform C calling conventions into
the native register ABI.

## How the fresh GUI example is built

The new [hello application](../../examples/hello-asm/README.md) uses its own
NASM source and field-by-field object declarations. It never loads BOUNCE or
NOTEPAD as a serialization template. Its pixel glyphs, rectangles and strings
are original; no stock icon or font bitmap is copied.

```sh
perl sdk.pl toolchain install
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
```

The build has three distinct responsibilities:

1. NASM assembles bounded `BITS 16`/`CPU 8086`/`ORG 0` code. Explicit macros record
   method addresses and the operands of actual imported calls.
2. The object generator writes new LMem chunks for the generic application,
   primary window and view, plus original monikers and window-list data.
3. The fresh container writer writes a native 1.x header, imports, resources and
   relocations. The independent strict parser then checks that output.

| Resource | New contents | Main constraint |
|---|---|---|
| 0 | Empty on-disk core placeholder | The loader creates the live module context. |
| 1 | TPD, process class and method tables |64-byte TPD; class starts at 40h. |
| 2 | Original assembly and glyph data | Native calls have explicit relocation records. |
| 3 | Primary window, text moniker and view | New1.2 object-block encoding. |
| 4 | Application object, moniker and primary-window list | Explicit cross-resource optrs. |

The view sends exposure events to the process. The starter does not create a
custom content class. For an exposed window, the handler creates a GState,
begins the native update, draws through GEOS clipping, ends the update and
destroys the GState. This avoids retaining a live window or graphics handle
across events. The current illustration has fixed logical dimensions; it does
not promise responsive scaling.

The initialized DGROUP is 256 bytes; its TPD stack-boundary word is initialized
explicitly. The process has 2048 bytes of additional uninitialized stack. These
are allocation declarations, **not a measured total resident-memory figure**.
The loader, shared UI, specific UI, fonts, graphics state, kernel and runtime
configuration contribute other costs. See [memory budgeting](memory-and-8086.md).

`G1_METHOD` records message/handler pairs, `KCALL` records kernel calls, `LC`
records library calls and `G1_FINISH` emits removable build metadata. Metadata
uses labels at actual operands. Searching the entire code resource for byte 9Ah
would confuse instruction data or graphics with real far-call operands.

The starter's native library-call relocation is source 1/type 4 (14h). Kernel
far pointers use source 0/type 0 (00h). The distinction is supported both by the
legacy linker source and by the supplied native modules. A fixed library code
resource does not make the imported-call record interchangeable with a kernel
call record. Class references use the separate offset/segment record types.

For code and exact limitations, read the
[backend contract](../../tools/ensemble12/README.md). This is a bounded
application construction path, not a general UI compiler or a replacement for
all historical SDK headers.

## Important object-block differences

| Observed 1.2 representation | Consequence for a new writer |
|---|---|
| Chunk allocations align to four bytes | A two-byte-only allocator is insufficient. |
| Chunk length includes the preceding two-byte length word | Keep stored and payload lengths distinct. |
| FFFFh means allocated-empty;0000h means unused | Preserve the difference in a handle table. |
| Class identity is a native marker and imported UI ordinal | It is not an ordinary C function pointer. |
| Same-block, cross-resource and process references have different encodings | Retarget optrs with format knowledge. |
| A terminal sibling contains a marked parent reference | Validate how the child chain ends as well as how it begins. |

The examined encoding uses class marker3000h, same-block marker4000h and
resource-relative markers based on1000h. The original generator writes these
fields deliberately; it does not overlay a later C structure onto the heap.
The class records, message values and field offsets remain tied to the target
profile. Some observed initialization words lack a completely reconstructed
public semantic name; do not infer arbitrary new behavior by toggling them.

For a larger UI, add a single native object class at a time. Validate chunk
flags, class ownership, reachable objects, parent/sibling termination, moniker
references and runtime geometry. A parser roundtrip checks bytes; a screenshot
and interaction test check a different part of the contract.

## Calling C and mixed libraries from a native GUI

The [library probe](../../examples/hello-libraries/README.md) extends the same
new GUI with imports of the assembly, C and mixed examples. Its checks exercise
the assembly register ABI, the C export's explicit far-cdecl stack cleanup,
and the mixed resource boundary. The program paints PASS or FAIL.

This separates C **algorithm** support from C **system-API** support. A small
freestanding C routine can be reached through a reviewed assembly call without
inventing C wrappers for every kernel/UI routine. For richer C functions, audit
global-data assumptions, compiler helpers, pointer models and the complete
resource/relocation path before expanding the example.

## Lessons from text input and document controllers

The native Chess input work records a significant text boundary: the
“get whole text” path returns a length without automatically appending NUL.
A parser must validate that length, reserve a terminator byte and couple its
buffer to the verified native entry limit. Focus loss, Enter and an explicit
Go action are different events; a change notification should not unexpectedly
launch an expensive operation. Busy state belongs both in handler logic and
in what controls remain usable.

GeoSheet's document notes distinguish the FileBox, model controller and
process callbacks. A message number sent to the wrong recipient can invoke a
different transition. Establish the active document only through its verified
lifecycle; do not treat every callback register as a new owned handle. Cancel
must undo temporary import/export modes. Controller-owned file handles require
controller-appropriate ownership rules. A successful truncate-and-write path
is not atomic replacement and does not guarantee recovery from a full disk.

The references also record an abandoned direct access into private dialog
implementation data. That history explains a bug; it is not a supported public
API to reproduce in new code.

## Callback lifetime and timer measurements

A stored physical segment:offset callback remains valid only while its code
resource has the required lifetime and location. GeoSheet used fixed callback
code and a negative relocation test for such a boundary. A method invocation
that resolves a movable target at call time is a different contract. Do not
replace either mechanism without checking the stored representation.

The Bounce analysis establishes a 32-bit tick result with BX as the high word
and AX as the low word for its exact kernel reference. DX is not its high
word. It also examines coalescing/replacement of matching pending continuous
timer events. Bounded queue growth does not imply unchanged animation speed
under overload. Distinguish timer events, simulation steps, completed frames
and actual presentations when measuring.

Do not transfer an older FPS number into the SDK's performance claims. New
tests require the exact output hash, CPU/emulator model, memory settings,
drivers, swapping and measurement interval. An emulator cycle budget is not
a physical 8088 benchmark.

## Ownership and publication

GeoSheet's MIT license covers its newly written source and documentation. It
expressly excludes the supplied GeoWorks runtime, extracted object templates,
upstream code and third-party tools; GeoCalc-derived exceptions retain their
Apache 2.0 notices. GNU Chess components need their own GPL/source review.

The public SDK therefore contains original resource descriptions and code,
documented numerical facts, pinned public tool sources and their required
notices. An MIT notice beside a commercial template does not relicense the
template. When actually reusing permitted source, preserve its required
copyright/license notice. The reference archives provide evidence and lessons,
not permission to republish their entire contents under a new product name.
