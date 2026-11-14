# Libraries and backporting

[Handbook](README.md) · [Deutsch](../de/libraries-and-backporting.md)

The supplied small libraries are a starting point for understanding module linkage. A reusable library needs a stable interface, documented state ownership and a tested caller. Backporting adds another requirement: every dependency must exist in the older target.

## Create your own import-free assembly library

Start by copying the known small example, rather than constructing a guessed UI application:

```sh
cp -R examples/math-asm examples/mycalc
```

In PowerShell the equivalent directory copy is:

```powershell
Copy-Item -Recurse examples/math-asm examples/mycalc
```

Edit `examples/mycalc/project.json` to use a distinct project name. Its basic shape is:

```json
{
  "schema": 1,
  "name": "mycalc",
  "kind": "library",
  "import_free": true,
  "cpu": "8086",
  "gp": "math.gp",
  "sources": [{"language": "esp", "path": "math.asm"}],
  "expected_export_count": 1
}
```

Use a lowercase DOS-safe project name of at most eight characters. Source and GP paths are relative to the project and must remain inside it. In `math.gp`, change the permanent module name from the original example to `mycalc.lib`, choose your own long name and a distinct local test token. Do not publish several different libraries with the same permanent identity. The example's manufacturer/token values are local test identifiers, not a production registration.

Keep the entry routine and resource structure initially unchanged. Change the calculation and its documentation together. If you rename an exported routine, update both the assembly declaration and the GP export. Keep `expected_export_count` consistent with the intentional export table.

```sh
perl sdk.pl check --project examples/mycalc
perl sdk.pl build --project examples/mycalc
perl sdk.pl inspect build/mycalc/mycalc.geo --summary
```

The result is a library, not a window-opening program. A properly matched caller is still needed for native loader/call validation. The generic library route rejects arbitrary OS imports. Applications use the separately profiled `ensemble12` backend; see the [original native GUI](../../examples/hello-asm/README.md) and [library integration probe](../../examples/hello-libraries/README.md).

## Design a small export surface

Export capabilities rather than internal structures. Document input ranges, return values, error signaling, memory ownership and reentrancy. Prefer a simple calculation or bounded transformation for a first library. The library should not unexpectedly change the caller's UI, current directory, graphics state or global configuration.

For each exported routine, publish the exact ABI from [C and assembly](c-and-assembly.md). An undecorated-looking name does not prove that two compilers use the same calling convention.

Keep existing export identities stable. Reordering a table can change ordinal-based linkage even if every source function remains present. Add compatible behavior without changing the meaning of old entries; use the target's protocol/version mechanism when an incompatible change is required. A source control tag and a loader protocol serve different purposes.

The later [library manual](https://bluewaysw.github.io/pcgeos/Concepts/clibr.html) describes the dynamic-library model. Use matching 1.x declarations for entry points, notifications and export metadata.

## Data segment and client ownership

A caller's DS is not automatically the library's data segment. A far C entry point may require a verified adapter to establish its own data assumptions. Pure import-free calculations are simpler because they can avoid mutable global state.

A library shared by multiple clients must distinguish shared read-only data, shared mutable state and per-client state. A single global scratch buffer is not safe merely because the function is short. Define synchronization, lifetime and failure behavior.

Keep initialization and cleanup appropriate to the documented entry context. Do not allocate large buffers, open UI or call into arbitrary client code from an attach/detach callback unless that contract permits it. Teardown must tolerate partial initialization and outstanding references.

## A backport inventory

Before editing code, enumerate dependencies:

| Item | What to record |
|---|---|
| Imported module | Permanent identity, required protocol and target availability. |
| Imported routine/class | Owning library and exact linkage, not just a familiar name. |
| Message | Defining class/version, argument contract and supported behavior. |
| Structure/instance field | Exact layout, alignment, field width and version evidence. |
| UI feature | Whether an equivalent generic object exists and how it behaves. |
| Compiler/runtime helper | Object format, CPU requirement, ABI and implementation. |
| Driver/device feature | Supported target and CPU/memory needs. |
| File format | Whether old and new applications can read the same logical data. |

Classify each dependency as unchanged, replaceable, optional or unavailable. Keep that inventory under version control. A hidden fallback to a current header defeats the exercise.

## Port in layers

1. Isolate portable algorithms and run their tests on the host.
2. Establish a minimal native build with no unnecessary imports.
3. Add one verified older-target dependency at a time.
4. Replace later convenience APIs with a small adapter using available primitives.
5. Adapt the UI to supported generic objects and native lifecycle behavior.
6. Recheck files, localization, concurrency, failure handling and resource flags.
7. Audit the emitted CPU instructions and every newly linked helper.
8. Test the exact output in the older runtime under realistic memory pressure.

Replacing an API can change semantics. Test the observable behavior, not only a return value for the easy case. If an older target cannot provide a feature faithfully, make the limitation explicit rather than silently changing document meaning or data quality.

## Owning module is part of the call

The same ordinal can mean unrelated things in two different libraries. Store and test the pair: dependency identity plus ordinal/linkage. A test that resolves every far call to one generic stub can accidentally accept a call into the wrong module.

Use distinct selectors or other identities in an emulation harness so an incorrect import cannot pass merely because its numeric offset looks familiar. Check the actual relocation records in the final binary, not just the assembly text.

## Structure layouts and arithmetic semantics

Do not copy a later instance offset into a 1.x private object. Public source can help name a concept, but native evidence or a matching definition must establish the actual layout. Even familiar rectangle conventions can differ: verify whether a size is computed as a difference or an inclusive difference plus one.

Preserve arithmetic results and documented ranges when optimizing. Replacing a larger engine with a smaller approximation is a product decision, not a behavior-preserving backport. Compare outputs and corner cases before claiming equivalence.

## When binary transformation is unavoidable

A checked transformation of an existing module can be useful research or maintenance, but is not the same as rebuilding a new application from complete source. Identify the exact input hash and require before-byte checks. Preserve unrelated resources, dependency protocols, exports, allocation flags and opaque data.

A loader fixup modifies an operand span, not only its starting address. Check the whole span against replacement code; a relocation starting just before a new block can still overwrite that block when the loader runs.

Publish the transformation source and provenance, and include the original compiled template only if redistribution is permitted. Do not describe an opaque template-derived patch kit as a complete source SDK.

## Acceptance for a library release

Build a caller that uses every export and its error paths. Test repeated load/use/unload, multiple clients where supported, different caller data segments, task switching and cancellation. Verify that cleanup does not invalidate another client's data. Record both the library and caller hashes and the exact target installation.
