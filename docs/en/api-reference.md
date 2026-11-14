# API reference map and verification records

[Handbook](README.md) · [Deutsch](../de/api-reference.md)

This is a map for building a trustworthy 1.x API inventory. It is not a fabricated list of complete historical declarations. The root release notes state which concrete interfaces this release actually supplies and validates.

## Supplied observed subset

The [curated Ensemble 1.2 inventory](../../targetprofiles/ensemble12-abi.json) records numerical facts, native register contracts, evidence and limits for kernel 622.3/UI 693.0. [Original include files](../../include/ensemble12/README.md) provide NASM/Esp constants and C constants/types. They are a bounded subset; the C header does not supply callable system wrappers. Verify your exact target with `perl tools/geos1/cli.pl verify-target /path/to/owned/GWSVGA` before the profiled GUI build. See [the recovered-reference walkthrough](recovered-references.md) for newly generated object resources and the native-call relocation distinction.

## What an API record needs

| Field | Purpose |
|---|---|
| Target/profile | Exact release family and evidence scope. |
| Owning module | Kernel, UI or another dependency; part of the identity. |
| Linkage | Verified export name/ordinal/class/message relationship. |
| Dependency protocol | Loader compatibility requirement. |
| Language declaration | C/assembly declaration tied to a specific compiler/profile. |
| Parameters/results | Widths, registers/stack, flags, error signaling and pointer representation. |
| Preserved/changed state | Including segment registers and relevant graphics/object state. |
| Ownership/lifetime | Allocation, locks, object/thread affinity and destruction. |
| Structure evidence | Exact field layout/alignment/version when structures are exposed. |
| Evidence | Definition source, native binary identity, tests and known limitations. |
| Status | Reference-only, format-tested, ABI-checked, runtime-tested or unavailable. |

An unknown ordinal or field offset stays unknown. Values copied from another release must not acquire a “verified” label merely because the source looks authoritative.

## Categories every application author should examine

| Area | Typical concerns | Entry point in this handbook |
|---|---|---|
| Application lifecycle | Process/application identity, startup, events and close. | [Architecture](architecture.md) |
| Objects/messages | Object identity, method ABI, queued data lifetime and ownership. | [Architecture](architecture.md) |
| Memory/resources | Loading, locking, movement, sharing, allocation failure and local memory. | [Memory](memory-and-8086.md) |
| UI/geometry | Available generic objects, hints, minimum sizes, focus and dialogs. | [UI and graphics](ui-and-graphics.md) |
| Graphics/text | Graphics state, colors, masks, transforms, clipping, fonts and repaint. | [UI and graphics](ui-and-graphics.md) |
| Files/VM | File identity, paths, document formats, persistent blocks and save recovery. | [Persistence](files-and-persistence.md) |
| Libraries | Entry context, export stability, protocols, data segments and multiple clients. | [Libraries](libraries-and-backporting.md) |
| Threads/timers | Ownership, scheduling, cancellation, reentrancy and teardown. | [Architecture](architecture.md) and [Testing](debugging-and-testing.md) |
| Input | Pointer sequence, keyboard focus, accelerators and cancellation. | [UI and graphics](ui-and-graphics.md) |
| Clipboard/import/export | Data formats, ownership and libraries actually present on the target. | Target inventory and [Backporting](libraries-and-backporting.md) |
| Printing/drivers | Device support, imaging, job lifecycle and driver CPU requirements. | Target inventory and [Testing](debugging-and-testing.md) |
| Localization | Resource encoding, strings, mnemonics and shared document formats. | [Release](localization-and-release.md) |

Some of these features may require libraries absent from a minimal 1.x installation. Do not add imports merely because the later documentation describes the feature.

## How to establish a declaration

1. Identify a matching original SDK definition or a target binary with trustworthy provenance.
2. Establish the owning module and protocol before interpreting the symbol/ordinal.
3. Compare the entry behavior, argument widths, output registers/flags and stack effect.
4. For a structure, verify the full layout used by the routine, not only one convenient field.
5. Create a small caller and a bounded ABI test.
6. Check the final emitted relocation and execute the call on the target when possible.
7. Record what was checked and what remains inferred.

A disassembly can show which fields a routine accesses, but often cannot establish their complete semantic meaning. A later source file can suggest a name, but the target's actual layout still needs evidence. Use both sources carefully and label inferences.

## Application-profile completion checklist

An application-capable profile needs more than the import-free math examples:

- matching fundamental types and object/class definitions;
- verified application/process and generic UI declarations;
- import/linkage data for the required kernel/UI/dependencies;
- C adapters or assembly call macros with correct 1.x contracts;
- object/UI resource construction that the 1.x loader accepts;
- startup, close, save/cancel and error behavior;
- a tested compiler/UI compiler/assembler/linker combination;
- a native runtime test matrix and reproducible sample outputs.

Until those inputs have been supplied or independently reconstructed and validated, the application route must remain explicitly incomplete. This protects developers from a seemingly complete header tree that produces subtly invalid programs.

## Use of later reference material

The [official FreeGEOS documentation index](https://bluewaysw.github.io/pcgeos/) links C, assembly, object and driver manuals. Its 2.0 basis is useful context. Search it to locate a concept; do not treat all its classes, routines or flags as present in 1.x. The [primary references](references.md) page records this distinction.

## Inspect native files without inventing API declarations

The SDK inspector accepts its documented native GEO format. It is not a general DOS EXE parser or a decompiler. After the custom-library walkthrough in [Libraries and backporting](libraries-and-backporting.md), for example:

```sh
perl sdk.pl inspect build/mycalc/mycalc.geo --summary
perl sdk.pl inspect /path/to/owned/UI.GEO --output .sdk-local/ui-inspection.json
perl sdk.pl extract /path/to/owned/UI.GEO --resource 2 --output .sdk-local/ui-resource2.bin
```

Use the output path printed by your project build if its name differs. Resource numbers and export entries are observations of that exact file; they do not establish the meaning of an arbitrary function. Extraction writes logical resource bytes without its relocation table. Inspect the relocation metadata separately when studying executable code.

Catalog explicit user-owned native modules and compare observable imports:

```sh
perl sdk.pl profile /path/to/owned/UI.GEO /path/to/owned/IM.GEO --output .sdk-local/runtime-profile.json
perl sdk.pl check-imports /path/to/program.GEO --profile .sdk-local/runtime-profile.json
```

Supply the actual modules needed by the program; the two filenames are illustrative. `check-imports` compares module identities and protocols only. It does not validate individual routine ordinals, class layouts, parameter contracts, instruction reachability or native behavior. An import-free example can pass a module comparison trivially because it has no such dependencies.

A DOS `KERNEL.EXE` can be an MZ executable rather than a native GEO file. Do not feed it to this inspector and reinterpret a rejection as evidence that the runtime is invalid. A separate, explicitly validated executable-format tool is needed for that container.

## Explicit kernel-requirement binding

For an eligible import-free library, the build command can copy the observed kernel protocol from a user-supplied native 1.x GEO:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /path/to/owned/UI.GEO
```

The build retains the unbound linker output separately and emits a binding record identifying the input, reference and output hashes. The binder refuses imported-library/API-relocation cases and other module roles, refuses an already different kernel requirement, preserves the library's own protocol and does not overwrite either input. It does not authenticate the supplied reference: choose a genuine module from the intended original installation, not a synthetic fixture or later file renamed to `.GEO`.

This operation supplies a declared loader requirement. It does not establish the native API, object layouts, calling convention, CPU compatibility or actual loader behavior. In particular, changing a header is not a general 2.x-to-1.x conversion technique.
