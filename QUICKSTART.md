# Quickstart

[Deutsch](QUICKSTART.de.md) · [Detailed guide](docs/en/quickstart.md)

1. Extract the repository. Use Perl 5.26+ on Linux x86-64, WSL2 on Windows, or an x86-64 Linux VM on macOS. See [host setup](docs/en/host-setup.md).
2. On Ubuntu 24.04, install prerequisites:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
```

3. In the folder containing `sdk.pl`, install the pinned tools and build your first GUI:

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor --require-toolchain
perl sdk.pl check
perl sdk.pl test
perl sdk.pl build --project examples/hello-asm
```

The output is `build/g1hello/g1hello.geo`. This backend targets the documented **Ensemble 1.2 kernel 622.3 / UI 693.0** profile. Verify your own runtime:

```sh
perl sdk.pl verify-target /path/to/owned/GWSVGA
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
```

Exit GEOS cleanly. Copy the output to `WORLD` in a disposable matching installation, restart GEOS and launch **GEOS 1 SDK Hello**. The [walkthrough](docs/en/native-applications.md) explains the source and library integration probe.

Create an editable starter of your own:

```sh
perl sdk.pl new --name myapp --language gui --directory ../myapp
perl sdk.pl build --project ../myapp
```

The other starter languages are `asm`, `c` and `mixed` for libraries. Choose a new destination directory; the command refuses to overwrite one.

For C and mixed examples:

```sh
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

These are libraries with their own documented interfaces. Read the [probe instructions](examples/hello-libraries/README.md) before native loading; do not launch them as applications.

For VS Code:

```sh
perl editor/vscode/pack_vsix.pl
code --install-extension editor/dist/pcgeos1-language-support-0.2.0.vsix
```

Open the SDK as a trusted workspace and select a Perl 5.26+ executable in `pcgeos1.perlExecutable`. For a separate project, set `pcgeos1.sdkRoot` to the SDK's absolute path. Use completion, API hovers and the Problems panel. See [other IDEs](docs/en/ide-integration.md).

No GEOS runtime is included. The API subset and tested combinations are explicit in [compatibility](docs/en/compatibility.md) and [validation](VALIDATION.md). Windows/macOS environment instructions are documented routes; the recorded native toolchain tests were on Linux x86-64.
