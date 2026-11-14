# Your first native application and C-backed GUI

[Handbook](README.md) · [Deutsch](../de/native-applications.md)

This tutorial builds an original window-opening program for the exact
Ensemble 1.2 installation described by the supplied target profile. It then
connects the native GUI to the three assembly/C/mixed library examples. The
bounded application backend generates new resources; it does not require a
stock application's serialized object blocks as templates.

The current root validation record identifies the exact new programs tested
and their emulator/CPU/memory settings. A build report deliberately records
construction separately from that runtime evidence. No physical 8088 result is
implied by an emulated 8086 test.

## Prerequisites and target identity

Follow [host setup](host-setup.md), install Perl 5.26 or newer and prepare the
pinned toolchain:

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

The native GUI code uses NASM 3.02. The C/ESP library examples additionally use
Open Watcom and the restored Esp/Glue legacy output path. These host tools run
in the documented Linux environment; Windows uses WSL and Mac uses the
documented Linux VM route. A DOS/GEOS installation is a separate target.

Keep a legally obtained original runtime intact and use a disposable test
copy. The public repository supplies a file-identity profile, not a commercial
runtime download. Check that copy:

```sh
perl tools/geos1/cli.pl verify-target /path/to/owned/GWSVGA
```

The profile checks `KERNEL.EXE`, `SYSTEM/UI.GEO` and `SYSTEM/MOTIF.GEO`. Its
target is kernel 622.3/UI 693.0, with the documented Motif identity. Hashes avoid
accidentally treating another release as the measured target. They do not
validate all APIs or certify a patched installation. For a different target,
establish and document the interfaces you actually need before defining a new
profile.

## Build and launch Hello

From the repository root:

```sh
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
perl sdk.pl inspect build/g1hello/g1hello.geo --summary
```

The build creates the native application, a NASM listing, build log, structural
inspection and build report. The permanent module name is `g1hello.app`; the
file is `build/g1hello/g1hello.geo`; the desktop name is **GEOS 1 SDK Hello**.

Exit GEOS cleanly to DOS before copying files into the test installation. Copy
the application into its `WORLD` directory, restart GEOS and launch it through
GeoManager. The expected drawing has a blue HELLO GEOS banner, cyan/green
rectangles, and SDK1/8086 captions. Open/uncover and minimize/restore it, resize
the window, switch to another application and close normally. The illustration
uses fixed logical coordinates; resizing the window does not scale its art.

The example neither creates nor edits a document. There is no save prompt,
document controller, undo history, clipboard implementation or printing path.
Add those as explicit features with their own target contracts and tests.

## Read the project declaration

The actual [project manifest](../../examples/hello-asm/project.json) selects:

```json
{
  "schema": 1,
  "name": "g1hello",
  "kind": "application",
  "backend": "ensemble12",
  "cpu": "8086",
  "long_name": "GEOS 1 SDK Hello",
  "token": "G1HL",
  "sources": [{"language": "nasm", "path": "hello.nasm"}],
  "view": {"width": 320, "height": 180}
}
```

`name` is a lowercase DOS-safe permanent identity of at most eight characters.
The human-readable title and the four-byte token are separate fields. Choose
distinct local test identities for different programs. The examples' token and
manufacturer values are not production registrations.

The backend accepts one NASM source with local includes. It builds a process,
one generic application, one primary and one view. It is deliberately not a
complete generic UI language or arbitrary GOC project recipe. Copying a 2.x
application's manifest into this shape does not adapt its object ABI.

## Follow the method and repaint lifecycle

Open [hello.nasm](../../examples/hello-asm/hello.nasm). Its first include sets
`BITS 16`, `CPU 8086`, `ORG 0` and the explicit metadata macros. `G1_METHOD`
connects observed native message values to the new handlers.

The open/attach handlers forward through the target's process superclass. The
close handler supplies no additional saved state. The exposed handler receives
the window handle and owns a short-lived GState:

1. Create graphics state for the exposed window.
2. Begin the native update so clipping corresponds to the damaged region.
3. Draw background, rectangles and original glyphs through kernel graphics.
4. End the update and destroy that graphics state.

No graphics handle or resource pointer is retained after the event. The pixel
glyph routine uses ordinary original glyph data, small stack saves and native
rectangles. Its code does not access video memory directly. A richer program
can use the observed text/graphics APIs after checking their font, string,
segment and state contracts; it need not imitate this deliberately small font.

The generated process class is in DGROUP, with method IDs and far handler
pointers. Native class references, object optrs and relocations are different
representations. Do not replace one with a physical address observed during
an earlier run. The [build walkthrough](recovered-references.md) describes the
fresh resource layout and the distinction between kernel and library calls.

## Make your own application

Create a starter in a new directory. The SDK command refuses an existing destination:

```sh
perl sdk.pl new --name myhello --language gui --directory examples/myhello
```

Edit `examples/myhello/project.json`: set `name` to `myhello`, give it a distinct
`long_name` and four-character local token. Keep the selected backend, CPU and
source unchanged for the first build.

```sh
perl sdk.pl check --project examples/myhello
perl sdk.pl build --project examples/myhello --target-root /path/to/owned/GWSVGA
perl sdk.pl inspect build/myhello/myhello.geo --summary
```

First change only the original drawing and its documented expected result.
Then add one user operation or one new class at a time. A custom content class,
menu, input entry or controller needs its own verified native declaration and
lifecycle. The [curated ABI inventory](../../targetprofiles/ensemble12-abi.json)
states the subset already established; later manual chapters are architectural
references rather than an automatic supply of older interfaces.

## Connect the GUI to C and mixed libraries

The native GUI can call a freestanding C algorithm through its explicit far
boundary without requiring a general C system-API binding. The supplied
[integration probe](../../examples/hello-libraries/README.md) imports all three
small libraries and checks known results.

Build the libraries with requirements read from the matching native UI file:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /path/to/owned/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-c --kernel-reference /path/to/owned/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-mixed --kernel-reference /path/to/owned/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/hello-libraries --target-root /path/to/owned/GWSVGA
```

Exit GEOS. Put the three generated library files in the test installation's
`SYSTEM` directory and `build/g1probe/g1probe.geo` in `WORLD`. Restart and open
**GEOS 1 Library Probe**. The handler checks assembly addition, C checksum,
mixed checksum and the two saturating-add cases; it displays PASS only when
all comparisons succeed.

The probe's manifest declares additional imports after UI index 0. They are
identified by permanent library name and own protocol 1.0; entry ordinals and
calling conventions remain separately documented. The assembly library takes
register arguments. The C export takes far-cdecl stack arguments and needs
caller cleanup. The mixed export takes register arguments and crosses to its
separate fixed C resource internally. See [C and assembly](c-and-assembly.md)
for complete preserved-register and stack contracts.

Do not infer from this example that arbitrary C functions can directly call
GEOS. Global data, movable memory, callbacks, compiler helpers, pointer widths,
stack segment and native error flags require deliberate adapters. The C header
in `include/ensemble12` contains constants/types, not automatic callable
wrappers.

## Extend evidence with the program

Keep the output hash with the exact test actions, target file identities,
driver, CPU and memory configuration. A source comment saying8086 is weaker
evidence than assembled instruction constraints, and those constraints are
still distinct from OS/driver compatibility. A working idle window is not
low-memory or multitasking validation.

For each feature, add the smallest meaningful native exercise: redraw after
uncovering; a rejected malformed entry; close with pending work; allocation
failure; save cancellation; task switching during calculation. Retain host-side
tests for portable logic, but reserve runtime labels for code actually executed
on the target. Follow [debugging and testing](debugging-and-testing.md) and the
release's current validation record.
