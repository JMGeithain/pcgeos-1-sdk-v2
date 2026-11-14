# PC/GEOS 1.x Community SDK

[Deutsch](README.de.md) · [Quickstart](QUICKSTART.md) · [Developer handbook](docs/en/README.md) · [Validation](VALIDATION.md)

Build original **8086 applications and libraries** using assembly, freestanding C, or C with assembly adapters. This GitHub-ready kit includes reproducible tool installers, a native application builder, examples, English/German documentation, API references and editor support.

**Experimental release, targeting the supplied Ensemble 1.2 profile.** The original GUI example has run under GEOS on an emulated 8086. The curated API covers 32 kernel calls and a small UI subset; this is not the complete historical SDK. General GOC/UIC application compilation, complete C system wrappers and other 1.x releases remain outside the verified scope. See [compatibility](docs/en/compatibility.md) and [validation](VALIDATION.md).

## Start here

Perl 5.26+ is required. The pinned native tool profile runs on Linux x86-64: directly, through WSL2 on Windows, or in an x86-64 Linux VM on macOS. Follow the [host setup](docs/en/host-setup.md) and [toolchain instructions](tools/BOOTSTRAP.md).

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor --require-toolchain
perl sdk.pl check
perl sdk.pl test
perl sdk.pl build --project examples/hello-asm
```

The application is `build/g1hello/g1hello.geo`. Before running it, verify your separately obtained target and follow the [native application walkthrough](docs/en/native-applications.md):

```sh
perl sdk.pl verify-target /path/to/owned/GWSVGA
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
```

Exit GEOS cleanly, copy the application to `WORLD` in a disposable matching installation, then restart and launch it. A target identity match is a prerequisite check, not a runtime test of your own changes.

Create your own starter with `perl sdk.pl new --name myapp --language gui --directory ../myapp`, then build that directory. Use `asm`, `c` or `mixed` for a library starter. Existing directories are never overwritten.

## C, assembly and mixed modules

```sh
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

These three outputs are **libraries** with explicit interfaces, not desktop applications. The C path uses Open Watcom C/16 with 8086 instructions, separate stack/data segments and no DOS C runtime. The mixed example supplies a small assembly adapter around a far C function.

The [library integration probe](examples/hello-libraries/README.md) imports all three libraries from a native GUI. Its instructions show how to bind the libraries' initially unset kernel requirements to an observed matching 1.x module. Binding preserves the code and records input/output hashes; it does not establish API compatibility by itself.

## Included components

| Location | Purpose |
|---|---|
| `sdk.pl` | Configure, check, build, test and inspect |
| `tools/`, `toolchains/` | Hash-pinned Open Watcom, Esp/Glue and NASM installers; reviewed source patches |
| `tools/ensemble12/` | Fresh application resources, class records and UI object generation |
| `tools/geos1/` | Strict native-file inspection, profiles, import checks and safe header binding |
| `include/ensemble12/`, `targetprofiles/` | Observed ABI constants, bilingual API references and target identities |
| `examples/` | Native GUI, library probe, assembly, C and mixed examples |
| `docs/en/`, `docs/de/` | Developer handbooks and quickstarts |
| `tools/lsp/` | Shared local language server for completion, API hovers and bounded checks |
| `editor/` | VS Code VSIX/client, TextMate grammars, KDE highlighting and IDE setup assets |
| `tests/`, `validation/` | Reproducible tooling tests and recorded evidence |
| `.github/` | CI and contribution templates |

## IDE support

```sh
perl editor/vscode/pack_vsix.pl
code --install-extension editor/dist/pcgeos1-language-support-0.2.0.vsix
```

The VS Code extension distinguishes **Esp, NASM, UI, GP and GOC**. Its optional local Perl server provides API completion, hover references, definitions, symbols and bounded source checks in a trusted workspace. Native compilation remains a separate check.

The same server supports other LSP clients. The [multi-IDE guide](docs/en/ide-integration.md) covers IntelliJ IDEA, Eclipse, NetBeans and KDevelop/Kate, with the required plugins/version limits and clear validation status. No claim is made that every IDE has been exercised in its GUI.

## GitHub and licensing

Original code and documentation are MIT-licensed. External compiler/tool sources retain their licenses; see [THIRD-PARTY.md](THIRD-PARTY.md). No original GEOS runtime, commercial SDK, historical object template, font or compiler archive is included. The supplied applications and runtime informed the recorded ABI facts and private tests.

Upload this source tree to your repository. Keep local tool downloads, runtime copies and machine-specific configuration outside Git. Rebuild the source ZIP with:

```sh
perl tools/package_source.pl ../PCGEOS1-SDK-source.zip
```

Start with [CONTRIBUTING.md](CONTRIBUTING.md) before adding declarations or widening compatibility claims. The handbook covers C/assembly ABI, resource architecture, UI, graphics, memory, files, persistence, libraries, backporting, testing and localization.
