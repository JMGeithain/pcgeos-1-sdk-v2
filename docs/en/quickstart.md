# Quickstart

[Handbook](README.md) · [Deutsch](../de/quickstart.md)

The first goal is a trustworthy development environment. The second is a small program built through an enabled native target profile. A host-side test is useful, but it is not a GEOS application.

## 1. Open the repository

Extract the release archive, or clone your own GitHub repository. Open a terminal in the directory containing `sdk.pl` and the top-level `README.md`.

Use Perl 5.26 or newer. The examples use the executable name `perl`; substitute its absolute path if it is not on your `PATH`. Builds with the pinned native tools run in Linux x86-64, including WSL2 or the documented Linux VM.

```sh
perl -v
perl sdk.pl --help
perl sdk.pl doctor
```

`doctor` describes the tools and target assets it can actually find. A missing legacy compiler, a missing native SDK profile or a missing runtime is a prerequisite failure, not a reason to substitute a similarly named modern header.

## 2. Run the supplied checks

```sh
perl sdk.pl check
perl sdk.pl test
```

Read the command's output and the release's validation record. These checks cover the files and behaviors implemented by this repository. They do not assert that an arbitrary external SDK, compiler or target installation is compatible.

Expected distinctions:

| Result | Meaning |
|---|---|
| Repository validation passes | The checked files, configuration and local tooling are internally consistent. |
| Portable logic test passes | The tested algorithm works on the host for the tested cases. |
| 16-bit object produced | The compiler or assembler produced a target object; the ABI and final geode still need checking. |
| Native build blocked | A required compiler/profile/runtime input is absent or deliberately unverified. |
| Native runtime check passes | The exact binary was exercised on the recorded target configuration. |

Do not rename a host executable to `.GEO`, disable the compatibility gate or change a target profile to claim a missing validation result.

## 3. Build the small library examples

The three calculation examples are **import-free libraries**: assembly-only, C-only, and mixed C/assembly. They are deliberately small enough to inspect and explain the selected 16-bit toolchain and native library format. The next step introduces the separately profiled GUI route.

On the host supported by the toolchain installer:

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

The installer and build commands print their resolved tools, prerequisites and output paths. Use those paths; do not infer that a host executable or intermediate object is a native library. See [Toolchain](toolchain.md) for dependencies, compiler settings and the difference between format checks and native runtime tests.

The default examples deliberately have an **unbound kernel protocol (0.0)**. They are build/inspection artifacts until a matching target requirement has been established. For these import-free libraries only, you can explicitly read that requirement from a genuine user-owned native 1.x GEO from the intended installation:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /path/to/owned/UI.GEO
```

Use an authentic native GEO, not the DOS `KERNEL.EXE` container. This changes only the eligible library's declared kernel requirement and records the reference hash. It does not supply OS API declarations, authenticate the reference, prove loader acceptance or validate additional APIs. See [API verification](api-reference.md).

A library `.GEO` cannot be launched by double-clicking it as though it were an application. A matching 1.x program or test harness must import and call its exports through the correct ABI. If the release has no native runtime evidence for that step, its status remains target-built/format-tested rather than runtime-tested.

## 4. Build the original native GUI

For an owned installation matching the supplied Ensemble 1.2 profile:

```sh
perl tools/geos1/cli.pl verify-target /path/to/owned/GWSVGA
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
perl sdk.pl inspect build/g1hello/g1hello.geo --summary
```

The application is `build/g1hello/g1hello.geo`, displayed as **GEOS 1 SDK Hello**. Exit GEOS cleanly, copy it into `WORLD` in a disposable test installation, restart and launch it with GeoManager. Expect a blue HELLO GEOS header and an original stack-of-resources illustration. This is an application; the three earlier math modules are libraries.

The backend checks kernel/UI/Motif identities and constructs fresh process/application/primary/view resources. It does not copy a stock program or add a complete C/GOC system API. Other 1.x installations need their own audited target profile. A matching hash and valid structure remain separate from runtime behavior; read the root validation record for the tests actually completed.

For the C/mixed native integration probe, follow [hello-libraries](../../examples/hello-libraries/README.md): bind the three libraries against the matching native UI reference, install them in the test runtime's `SYSTEM`, put the probe in `WORLD`, and check its PASS/FAIL display. See [the recovered-reference walkthrough](recovered-references.md) for the build architecture and supported limits.

## 5. Separate the host from the target

The host runs Perl, the editor and build tools. A PC/GEOS runtime runs under DOS in an emulator or on a separate machine. Use a disposable copy of a legitimately obtained target installation. Keep the original installation and original binaries unchanged.

Before copying a new `.GEO`:

1. Exit the target cleanly to DOS.
2. Back up any file you intend to replace.
3. Copy the program to the location required by its project and module type.
4. Start GEOS, launch the program and test its normal close route.
5. If the application owns a document, modify it, invoke Close, cancel the save prompt and verify that the document remains intact.

A library and an application do not necessarily belong in the same directory. Do not put every module in `SYSTEM` simply because some libraries live there.

## 6. Record your first result

Keep a short validation note beside the build output:

```text
Program and revision:
Output SHA-256:
Compiler/assembler/linker versions:
Target release and language:
Kernel/UI/driver identities:
CPU model:
Conventional memory and XMS/EMS/UMB settings:
Disk swapping:
Actions tested:
Failures and untested features:
```

A clear note is more useful than an unsupported “works on everything” label. Continue with [Host setup](host-setup.md), [C and assembly](c-and-assembly.md) and [Debugging and testing](debugging-and-testing.md).
