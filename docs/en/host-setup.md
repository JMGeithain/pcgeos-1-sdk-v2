# Development hosts: Windows, macOS and Linux

[Handbook](README.md) · [Deutsch](../de/host-setup.md)

There are two machines in the development model, even when they share one physical computer: the **host** runs the editor and tools; the **target** runs DOS and PC/GEOS. Perl running on a modern host is not the application's C runtime.

Use **Perl 5.26 or newer** for the SDK commands. Check `perl -v` after installation. The SDK uses core modules such as `JSON::PP`, `Digest::SHA`, `Test::More` and `IO::Compress::Zip`; no CPAN installation is required. On macOS, use the supplied system Perl if it meets the minimum, or install a separate Perl through your usual package manager.

## Common layout

Use a short path without spaces or non-ASCII characters for legacy tools, for example `C:\geosdev` or `~/geosdev`. Keep these areas separate:

```text
geosdev/
  pcgeos1-sdk/       repository and original source
  toolchains/       separately installed tools
  target-original/  preserved original runtime
  target-test/      disposable runtime copy
  results/          build logs, identities and native test notes
```

This directory sketch describes roles; it is not a mandatory SDK configuration file. Use the actual configuration names shipped by this release. Keep proprietary inputs and target state outside the repository or in explicitly ignored local directories.

Choose one host path convention per build. A DOS path such as `C:\SDK\INCLUDE`, a Windows path and a Linux path are not interchangeable. Test case sensitivity, line endings and filename length before blaming the compiler.

## Windows: WSL 2 workflow

On a supported Windows installation, open an administrator PowerShell and follow Microsoft's [WSL installation instructions](https://learn.microsoft.com/en-us/windows/wsl/install):

```powershell
wsl --install -d Ubuntu
```

Restart if requested, open Ubuntu and create the Linux user account. Inside Ubuntu, install the ordinary host prerequisites for this repository:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
```

These packages provide Perl/Git, the native compiler/make/Perl needed to build NASM, and the optional i386 host-tool runner. They do not install a commercial GEOS runtime. The SDK's pinned installer downloads/builds the selected compiler and GEOS host tools; see [Toolchain](toolchain.md) for source identities and offline archives.

Place an active Linux checkout under the Linux home directory when using Linux build tools. From its root:

```sh
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

Install VS Code on Windows and its official WSL support, open the checkout in a WSL window, then install the repository's editor extension in the context used to edit the source. A syntax extension installed only in the wrong extension host may not be active in a remote window. See [VS Code's WSL guide](https://code.visualstudio.com/docs/remote/wsl) and the supplied [editor package](../../editor/vscode/README.md).

On Windows ARM64, an ARM64 WSL distribution does not automatically execute x86 Linux legacy SDK binaries. Use a documented cross-architecture route or an x86 environment. Do not mark that host/tool combination as tested merely because Perl runs.

### Native Windows option

For native editor services and host checks, install a compatible Windows Perl, for example [Strawberry Perl](https://strawberryperl.com/), and reopen your terminal so its executable is on `PATH`:

```powershell
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

Native Perl support does not imply that every external compiler or assembler has a Windows build. DOS tools require an appropriate DOS execution environment; Win32 tools require their own compatible host. Avoid mixing a Linux profile with native Windows executable paths. Use the profile's documented host rather than inventing a `PATH` that appears to work.

## Linux

For a Debian/Ubuntu-style host:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
```

Other distributions provide equivalent packages. Use the release's stated Perl minimum. `build-essential` provides the host compiler/make for NASM; Perl supports its source build. `qemu-user` supplies `qemu-i386` if native IA32 execution is unavailable. Then run `perl sdk.pl toolchain install`, followed by the same `doctor`, `check` and `test` commands from the repository root. This package list targets Debian/Ubuntu and is not a claim that an arbitrary distribution has passed the complete toolchain validation.

Prefer a normal user account for builds. A root-owned toolchain or checkout can produce confusing permission failures and generated files that other tools cannot update. Do not install target `.GEO` files into host system directories.

If a selected host tool is distributed only for x86-64, an ARM Linux host needs a documented x86 execution route or a source build that supports ARM. A CPU architecture label on the host binary is independent of the 8086 target setting used by the compiler.

## macOS

Use `perl -v` to check the macOS system Perl. If it is missing or older than 5.26, install a separate Perl with your usual package manager, for example `brew install perl` with Homebrew. Install Git through its official distribution or your package manager. Apple's command-line developer tools can provide Git and native build tools:

```sh
xcode-select --install
```

That command does not supply a 16-bit GEOS compiler. Verify the versions and run:

```sh
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

For external tools requiring Linux, use a Linux VM or an explicitly supported container route. On an Intel Mac, an x86-64 Linux guest is the simplest architectural match for x86-64 Linux tools. On Apple Silicon, an ARM64 Linux VM and an x86-64 Linux VM are different environments. Use x86-64 emulation when the selected tools need it; merely enabling virtualization of an ARM guest does not make those tools native ARM programs.

[UTM](https://docs.getutm.app/) documents both emulation and virtualization. Its [system settings](https://docs.getutm.app/settings-qemu/system/) identify `x86_64` and `aarch64` as different guest architectures. Record the chosen guest and tool versions in your validation log. This handbook does not claim that an untested Apple Silicon configuration has passed native SDK validation.

### Step-by-step x86 Linux VM route on a Mac

1. Install UTM from its official distribution and obtain an **amd64/x86-64** Linux installation ISO. Choose a distribution that provides Perl 5.26 or newer; an ARM64 ISO is not the same guest.
2. Create a VM. On an Intel Mac, a supported x86-64 Linux guest can use virtualization. On Apple Silicon, choose the QEMU **emulation** route for an x86-64 guest, rather than an ordinary ARM64 virtualized Linux machine.
3. Confirm the VM architecture is `x86_64`. An example host VM can have 4 GB RAM and a 20 GB virtual disk; these are development-host resources, not the GEOS target's 640 KB configuration.
4. Attach the ISO, install Linux, remove the installer media and boot the installed guest. Keep the SDK checkout inside the guest's home directory to start with; add shared folders only after ordinary file access works.
5. Inside the guest, follow the Linux Perl/Git setup in this chapter and run `perl -v`, `uname -m` and `perl sdk.pl doctor`. The compiler host should be reported as Linux/x86-64, even though the physical computer is a Mac.
6. Run the toolchain installation and example builds in that guest. If the selected bootstrap reports a missing native compiler/build tool or i386 runner, install the documented prerequisite and repeat the check; do not select an unrelated binary just to silence it.
7. Use an editor inside the guest, or VS Code on macOS with its [Remote SSH workflow](https://code.visualstudio.com/docs/remote/ssh). Open the Linux checkout through that connection so terminal tasks run in the same environment as the selected tools.
8. Keep a later DOS/GEOS test runtime separate from the host VM's SDK checkout. A successful Linux toolchain build is still not a GEOS runtime test.

This route is a documented setup strategy, not a claim that this release was tested on every Mac/UTM version. In particular, Rosetta support for some Linux x86-64 applications is not proof that an arbitrary 32-bit host executable will run.

A container also does not eliminate architecture differences. Use a supplied, pinned container profile if the release has one. A generic `linux/amd64` image running through emulation is not evidence that every legacy binary inside it works.

## VS Code workflow

1. Open the SDK repository folder, so the integrated terminal and tasks can find `sdk.pl`.
2. Install the supplied `.vsix` from `editor/dist` using **Extensions: Install from VSIX**. Its exact artifact name and packaging command are documented in [the editor README](../../editor/vscode/README.md).
3. In WSL or Remote SSH, install/enable the language extension in the extension context that edits the remote files. Run build tasks in that same environment.
4. Use the supplied settings and task templates as project configuration. Review and merge them with an existing `.vscode` directory; do not overwrite unrelated settings blindly.
5. Select the language mode appropriate to ESP, NASM, UI, GP or GOC source. Ordinary `.c` files can use a C editor extension, but its host-oriented analysis does not establish the 16-bit compiler's types or ABI.
6. Run the SDK checks/build commands through the integrated terminal or supplied tasks. Editor services do not replace the actual compiler or establish ABI compatibility. The separate [IDE integration guide](ide-integration.md) describes highlighting, snippets, tasks and the optional language server, including its deliberately bounded analysis.

The TextMate grammar files are available for reuse by editors with compatible grammar support, subject to the editor's own integration format. Such reuse is not a claim that every editor has been tested.

A native `.GEO` is not a host ELF/PE executable. Do not configure a generic host GDB launch task and expect it to run the program. Native debugging requires the matching GEOS runtime/debugger route described in [Debugging and testing](debugging-and-testing.md).

## Running the target

Use a separately obtained DOS/GEOS runtime in the emulator supported by your target profile. Copy it to a test directory before experimenting. Keep the target's language, kernel, UI and video driver versions together; replacing only one library can create an incompatible installation.

For an 8086/8088 claim, configure an actual 8086-capable emulator mode and a compatible driver. Disable XMS, EMS and UMB when testing the stated 640 KB conventional-memory configuration, and record disk swapping. A generic DOS virtual machine configured as a 386 is useful for many tasks, but it does not establish 8086 instruction compatibility.

Do not let a build script overwrite the original runtime or start GEOS on the host's unrelated DOS installation. Make target copying an explicit project operation and preserve a known-good recovery configuration.

## Troubleshooting the environment

| Symptom | First checks |
|---|---|
| Command not found | Correct terminal/VM, executable architecture, executable bit, and the profile's tool paths. |
| Tool starts but cannot find headers | Correct SDK root, path separators, case, and target-specific include ordering. |
| Build accidentally uses another SDK | Print resolved tool and include paths; remove global fallback paths from the project. |
| Emulator starts but GEOS does not | Test the unmodified runtime first; inspect DOS configuration, driver and INI line endings. |
| Works on x86 Linux, fails on ARM Mac | Check the host binary architecture and actual emulation route before changing target code. |
| Editor colors code but build fails | Syntax highlighting is lexical support, not an assembler or API validator. |
