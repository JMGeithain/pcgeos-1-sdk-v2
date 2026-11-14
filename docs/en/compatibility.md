# Compatibility and evidence

[Handbook](README.md) · [Deutsch](../de/compatibility.md)

PC/GEOS 1.x is a versioned binary target, not a synonym for any 16-bit GEOS program. “Ensemble” has named several releases. Record the exact release, kernel, UI library, specific UI and drivers used by your program.

## This release

Two native routes are enabled: import-free libraries built from assembly, freestanding C or both, and a bounded original GUI backend for the supplied Ensemble 1.2 profile (kernel 622.3/UI 693.0). The GUI route generates new resources and validates exact target identities; it does not expose every 1.x API or a general GOC application environment. Default calculation-library outputs retain an unbound kernel requirement until an explicit matching native reference is supplied. Header binding copies an observed requirement only. The supplied runtime is a private test input and is not redistributed. Check the root validation report for the exact binaries and actual host, format, emitted-code and native-runtime results.

## What a compatibility claim must cover

| Layer | Questions to answer |
|---|---|
| File format | Does the loader recognize this native header, table layout and relocation representation? |
| Imports | Does each dependency exist, with the required protocol and the exact imported routine or class? |
| Call ABI | Are parameters, results, stack cleanup, flags and segment-register rules correct? |
| Objects | Are class layouts, message numbers, resource objects and instance offsets correct for this target? |
| CPU | Does every reachable instruction, including compiler support code and driver calls, meet the stated processor requirement? |
| Memory | Does the complete installation run within the stated configuration, including shared libraries and system allocations? |
| Behavior | Do close, save, input, redraw, task switching and failure paths work under the target OS? |

Passing one row does not establish the others. A structural inspector can reject malformed data; it cannot prove that a register-based call has the correct meaning.

## Evidence levels

Use explicit labels in issue reports and release notes:

- **Host-tested:** a tool or portable function ran on the recorded development host.
- **Format-tested:** a parser or writer passed the recorded structural checks for a documented format profile.
- **Target-built:** the selected target toolchain produced the program from the recorded source inputs.
- **ABI-checked:** the relevant binary interfaces were established from a matching definition, native code or an execution test.
- **Runtime-tested:** the exact output binary passed the listed actions on the recorded GEOS installation.
- **Hardware-tested:** those actions were performed on the specified physical hardware.
- **Unverified/reference-only:** useful research or source material that has not met the relevant target checks.

“Emulated 8086” and “physical 8088” are different claims. A newer video driver can raise the installation's CPU requirement even if your own code contains only 8086 instructions.

## Why SDK 2.x headers cannot simply be renamed

The [official documentation site](https://bluewaysw.github.io/pcgeos/) says it is based on SDK 2.0. The [current official source repository](https://github.com/bluewaysw/pcgeos) describes its base as Breadbox Ensemble 4.13. Those sources are valuable for understanding architecture and locating related routines. They do not prove the layout or availability of an interface in a 1.x binary.

The dangerous differences are often small: an instance field at a different offset, a structure with extra fields, a changed flag encoding, a message added after the older release, or an ordinal that belongs to a different imported library. A successful compile does not expose these errors.

Keep a separate target API inventory. For every imported feature, record its declaration source, target version, owning module, protocol, ordinal or linkage name, and validation evidence. Unknown entries must remain unknown; do not fill them with values copied from a later release.

## Required original assets

Native application development can require a matching 1.x development kit or independently established replacement declarations, import metadata, compiler adapters and a legally obtained runtime. The repository must state which of these it supplies and which the developer must supply separately.

The earlier porting project's native artifacts are not assumed to be present in a fresh checkout. Past test results apply to their recorded binaries and configurations. They are not blanket certification of a newly reconstructed SDK.

Do not commit a commercial GEOS installation, proprietary compiler, font or SDK archive merely because it is old. Availability on a download site does not establish redistribution permission. See [Localization and release](localization-and-release.md).

## Release acceptance

A project is ready for a 1.x compatibility label only when its selected build path is enabled, its exact output is identified, and its intended native behavior has been tested. State the lower bound precisely, for example an exact installation and driver configuration. If only a subset of APIs is supported, publish that subset and its limits rather than calling it the entire historical SDK.

A missing prerequisite should stop the native build with an actionable message. It should never silently select current FreeGEOS headers or link libraries from another installation.
