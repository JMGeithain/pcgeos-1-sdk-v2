# Primary references and reading map

[Handbook](README.md) · [Deutsch](../de/references.md)

Checked for this handbook on 14 November 2026. The links below lead to the maintainers' documentation or source. They are reading references, not a claim that a current API is present in PC/GEOS 1.x. Tool revisions actually used by a release are recorded by its lock files and build reports.

## GEOS architecture and development

The [official FreeGEOS documentation index](https://bluewaysw.github.io/pcgeos/) identifies its content as based on the GEOS SDK 2.0 library. The [official source repository](https://github.com/bluewaysw/pcgeos) describes its source base as Breadbox Ensemble 4.13. Preserve those version boundaries whenever using their examples or definitions.

| Topic | Official reference | How to use it here |
|---|---|---|
| System model | [System Architecture](https://bluewaysw.github.io/pcgeos/Concepts/carch.html) | Understand layers, objects and generic UI; verify target interfaces separately. |
| Programming | [GEOS Programming](https://bluewaysw.github.io/pcgeos/Concepts/ccoding.html) | Understand message/lifecycle patterns and identify contracts to establish. |
| Geodes | [Applications and Geodes](https://bluewaysw.github.io/pcgeos/Concepts/cappl.html) | Learn module/resource concepts without assuming identical native headers. |
| Handles | [Handles](https://bluewaysw.github.io/pcgeos/Concepts/chandle.html) | Distinguish identities from addresses. |
| Global memory | [Memory Management](https://bluewaysw.github.io/pcgeos/Concepts/cmemory.html) | Review memory mechanisms and ownership questions. |
| Local memory | [Local Memory](https://bluewaysw.github.io/pcgeos/Concepts/clmem.html) | Understand chunks and movement hazards. |
| UI | [The GEOS User Interface](https://bluewaysw.github.io/pcgeos/Concepts/cuiover.html) | Understand generic versus visible objects; check available classes. |
| Geometry | [Managing UI Geometry](https://bluewaysw.github.io/pcgeos/Concepts/cgeom.html) | Understand layout responsibilities. |
| Graphics state | [Graphics Environment](https://bluewaysw.github.io/pcgeos/Concepts/cgraph.html) | Identify state and clipping contracts. |
| Drawing | [Drawing Graphics](https://bluewaysw.github.io/pcgeos/Concepts/cshapes.html) | Locate graphics concepts and verify concrete target routines. |
| Files | [File System](https://bluewaysw.github.io/pcgeos/Concepts/cfile.html) | Review file identity and I/O concepts. |
| Persistence | [Virtual Memory](https://bluewaysw.github.io/pcgeos/Concepts/cvm.html) | Understand VM-managed storage and its separate handle domain. |
| Concurrency | [Threads and Semaphores](https://bluewaysw.github.io/pcgeos/Concepts/cmultit.html) | Review synchronization and reentrancy questions. |
| Libraries | [Libraries](https://bluewaysw.github.io/pcgeos/Concepts/clibr.html) | Understand dynamic linking and library responsibilities. |
| Localization | [Localization](https://bluewaysw.github.io/pcgeos/Concepts/clocal.html) | Review resource-oriented translation. |
| Build tools | [Using Tools](https://bluewaysw.github.io/pcgeos/Tools/ttools.html) | Understand Esp/Glue/Goc/tool roles; use this release's pinned profiles. |
| Assembly language | [Esp basics](https://bluewaysw.github.io/pcgeos/Esp/ebasics.html) and [routine writing](https://bluewaysw.github.io/pcgeos/Esp/erout.html) | Read the language model, then use the selected target include set. |
| UI compiler | [The UI Compiler](https://bluewaysw.github.io/pcgeos/Esp/euic.html) | Understand its role; do not infer 1.x object-resource compatibility. |
| Debugger | [Swat introduction](https://bluewaysw.github.io/pcgeos/Tools/tswatcm.html) | Establish matching stub/kernel/symbol compatibility before using the commands. |
| Language bridge | [Mixing C and Assembly](https://bluewaysw.github.io/pcgeos/Esp/emixing.html) | Identify compiler/assembly boundary issues; do not infer a 1.x C API. |

The source tree and its license are upstream material with their own provenance. This handbook is original guidance; it does not reproduce the upstream multi-volume manual or claim ownership of it.

## Compilers and assemblers

- [Open Watcom project](https://open-watcom.github.io/) and [source repository](https://github.com/open-watcom/open-watcom-v2).
- [Open Watcom C/C++ User's Guide](https://open-watcom.github.io/open-watcom-v2-wikidocs/cguide.html): compiler options, CPU targets and memory models.
- [Open Watcom C Language Reference](https://open-watcom.github.io/open-watcom-v2-wikidocs/clr.html): supported language and near/far declarations.
- [GCC x86 options](https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html): explains why GCC's `-m16` is not this 8086 C toolchain.
- [NASM directives](https://www.nasm.us/doc/nasm08.html): relevant when deliberately using NASM for separate machine-code work; not a replacement for ESP's object language.

Read the license supplied with each actual component. Do not assume that every compiler executable is redistributable because another part of the SDK is open source.

## Host and editor setup

- [Perl downloads](https://www.perl.org/get.html): obtain a Perl version meeting this project's minimum.
- [Git downloads](https://git-scm.com/downloads/): obtain Git for the development host.
- [Microsoft WSL installation](https://learn.microsoft.com/en-us/windows/wsl/install) and [WSL basic commands](https://learn.microsoft.com/en-us/windows/wsl/basic-commands).
- [VS Code with WSL](https://code.visualstudio.com/docs/remote/wsl): run the editor's tools in the intended Linux context.
- [Apple Xcode resources](https://developer.apple.com/xcode/resources/): host development tools for macOS, not a GEOS target compiler.
- [UTM documentation](https://docs.getutm.app/) and [QEMU system settings](https://docs.getutm.app/settings-qemu/system/): distinguish guest emulation from same-architecture virtualization.
- [Supplied editor support](../../editor/vscode/README.md): local syntax highlighting, snippets and task templates, with its own scope and tests.

## Evidence precedence

For a specific 1.x ABI decision, prefer a matching original definition and a documented native test. Use exact binary identities for reverse-engineering evidence. Use a later source only as a naming or architectural clue until the older layout/call is established. A search result or an old download mirror is not sufficient provenance for a compiler or a runtime.

When a link changes, update the reading map independently of the release's tool lock. Updating a URL does not justify silently replacing the compiler or build inputs used by a reproducible release.
