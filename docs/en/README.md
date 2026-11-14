# PC/GEOS 1.x developer handbook

[Deutsch](../de/README.md) · [Repository home](../../README.md) · [Quickstart](quickstart.md)

This handbook is for developers writing applications and libraries for the original 16-bit PC/GEOS 1.x family, including Ensemble 1.x. It covers C, assembly and mixed-language design, host setup, the resource-based execution model, debugging and release work.

The buildable projects include assembly, C and mixed calculation libraries, plus original native GUI examples for one explicitly observed Ensemble 1.2 profile. Their process and UI resources are generated from new declarations; no stock application is a binary template. This release supplies a bounded interface subset, not a complete historical 1.x application/GOC/API declaration set or a redistributable target runtime. Read the current validation record for actual execution results.

**Start with the release's compatibility status.** A successful host build, a file ending in `.GEO`, and a program loading on a later FreeGEOS release are three different results. None alone establishes PC/GEOS 1.x compatibility. The public FreeGEOS documentation is an excellent architectural reference, but identifies itself as SDK 2.0 documentation; the current source tree is based on Ensemble 4.13. This project does not silently treat those interfaces as a 1.x SDK.

## Read in this order

| Stage | Page | What you will learn |
|---|---|---|
| First run | [Quickstart](quickstart.md) | Run the repository checks and understand which build paths are available. |
| Know the target | [Compatibility and evidence](compatibility.md) | Separate verified tooling from unverified APIs and choose a target profile. |
| Prepare the host | [Windows, macOS and Linux](host-setup.md) | Keep host tools, the 16-bit target and the test runtime separate. |
| Configure the editor | [IDE integration](ide-integration.md) | Use syntax support, snippets, tasks and the optional language server with explicit analysis limits. |
| Understand the build | [Toolchain](toolchain.md) | Know what the compiler, UI compiler, assembler, linker and import data do. |
| Write code | [C and assembly](c-and-assembly.md) | Define a deliberate interface between C logic, assembly adapters and GEOS methods. |
| Understand the OS | [Architecture](architecture.md) | Work with resources, objects, messages, threads and native module boundaries. |
| Fit the machine | [Memory and 8086](memory-and-8086.md) | Avoid stale pointers, budget conventional memory and audit the instruction set. |
| Build the UI | [UI and graphics](ui-and-graphics.md) | Use generic UI, redraw correctly and keep interaction responsive. |
| Build a native program | [Native application tutorial](native-applications.md) | Build and launch the original GUI, customize it and call C/mixed libraries through documented boundaries. |
| Save data | [Files and persistence](files-and-persistence.md) | Choose a file representation and handle failure without losing documents. |
| Extend and port | [Libraries and backporting](libraries-and-backporting.md) | Design exports and replace later APIs without copying later layouts. |
| Validate | [Debugging and testing](debugging-and-testing.md) | Test ABI contracts, low-memory behavior, multiple applications and real runtime integration. |
| Publish | [Localization and release](localization-and-release.md) | Produce English/German resources and a reproducible, redistributable GitHub release. |
| Look up a feature | [API reference map](api-reference.md) | Find the right category and record the exact 1.x declaration and evidence. |
| Learn from recovered ports | [Recovered reference applications](recovered-references.md) | Follow the original GUI build and distinguish technical facts from licensed code and templates. |
| Check a source | [Primary references](references.md) | Find official documentation, source and host-tool manuals with their version boundaries. |

## Three rules that prevent expensive mistakes

1. Treat handles, object pointers and CPU pointers as different types of value. Reacquire pointers after operations that can move storage.
2. Treat every system call and message as an ABI contract. Registers, flags, stack cleanup, owning library and structure version all matter.
3. Treat validation as part of the SDK. Record the exact compiler, build inputs, target runtime, driver and CPU configuration used to establish a claim.

## Scope of this handbook

The explanations are original developer guidance. Where a code fragment is labelled pseudocode or a portable C example, it is not a claim that the fragment can be linked into a native 1.x application unchanged. Commands must be used with the build paths actually enabled in this release. Unavailable prerequisites are reported as unavailable rather than replaced by guessed headers or imports.

For exact supported commands, start with `perl sdk.pl --help` at the repository root. Read the root release notes and [compatibility page](compatibility.md) before publishing a program with a “PC/GEOS 1.x” or “8088” label.
