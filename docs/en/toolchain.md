# The build toolchain

[Handbook](README.md) · [Deutsch](../de/toolchain.md)

A C compiler alone is not a GEOS SDK. The compiler produces machine code and object records; a GEOS-aware toolchain must also describe resources, objects, imports, exports, relocations and module identity.

## Tools and their responsibilities

| Component | Responsibility | Important boundary |
|---|---|---|
| Host Perl tools | Configuration, checks, orchestration and reports | They run on the development host. |
| 16-bit C compiler | Compile ordinary C into the selected 16-bit object format | It must meet the target instruction set and selected C ABI. |
| GOC translator, where supported | Translate GEOS object-language additions into C | A translator and generated wrappers from another SDK version are not a verified 1.x API. |
| ESP assembler | GEOS object assembly and resource-related source | It is more than a generic x86 assembler; the include set matters. |
| UI compiler, where supported | Translate matching declarative UI descriptions | The UI/object format and class declarations must match the target. |
| GEOS linker | Combine objects, resources and import/export metadata into a geode | Native 1.x output requires the correct format/profile, not just a `.GEO` suffix. |
| Import definitions | Identify dependencies, protocols and exported interfaces | Names, ordinals and owning libraries must be correct. |
| Inspector/tests | Check structure, contracts and emitted code | Structural success is not runtime certification. |
| DOS/GEOS runtime | Load and execute the result | Supplied separately unless its redistribution is explicitly authorized. |

The [official tool documentation](https://bluewaysw.github.io/pcgeos/Tools/ttools.html) explains the historical roles of Esp, Glue, Goc, UI tools and pmake. It is a later SDK reference. Use the actual versions and settings recorded by this repository's selected profile.

## Initial build route

The small `math-asm`, `math-c` and `math-mixed` projects are import-free native library examples. Their build path uses the release's pinned host tools, reviewed legacy-format linker support and explicit 16-bit compiler settings. The root release notes and generated build records are authoritative for the exact versions and patch identities.

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

Do not add unrecorded tools from another SDK to `PATH` until a build happens to succeed. Inspect resolved executable paths in the build log. A copied tool with the same filename can have different defaults, object support or output formats.

## Pinned host-tool build

The supplied bootstrap uses the reviewed source revision `260b33dcfcac15b7ecfdf04242cb0abf029ec269` from the official FreeGEOS repository. It builds Esp and Glue from source with the pinned Open Watcom host toolchain. The historical C code needs its recorded host packing/enum/character assumptions; the bootstrap selects the Linux `lh/` headers and its reviewed flags rather than treating the tool sources as an arbitrary modern C project.

The resulting Esp/Glue programs are **static Linux ELF32 host executables**. They are not GEOS programs and are not the 16-bit library outputs. The compiler tools that build them can themselves be 64-bit Linux programs. Native Linux IA32 execution or an explicit `qemu-i386` user-mode runner is required to execute these generated host tools.

The bootstrap never downloads QEMU. On a Debian/Ubuntu-style host where a runner is needed:

```sh
sudo apt install qemu-user
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
```

`GEOS1_I386_RUNNER` can explicitly select the runner used by the generated host wrappers. This runner executes the Linux host tools; it does not run DOS or load `.GEO` modules. A native GEOS runtime test still needs the separate target environment.

The reviewed patch restores the legacy 1.x Glue path and handles the bare Open Watcom object metadata needed by the selected compiler route. The actual build invokes Esp's `-R 1` mode and Glue's `-G 1` legacy output mode, with explicit file type, module protocol and release metadata. Use the SDK build command so those choices remain tied together. The current recipe includes `-T 2`, `-P 1.0` and `-R 0.1.0.0`; the library's own protocol is separate from its kernel requirement.

The bootstrap supports an exact pinned offline source archive through `tools/bootstrap_freegeos.pl --source-archive`. See that command's `--help` for the required Watcom/prefix paths. A different archive with a similar filename is not an interchangeable input. Keep the patch, lock files and installation/build logs together when upgrading or reproducing the host tools.

## NASM for the profiled resource writer

The Ensemble 1.2 resource-writer route assembles bounded flat code with NASM;
Esp remains the assembler for GEOS object source in the library examples.
The installer also builds **NASM 3.02** from its official 1.5 MB source archive,
verified against `toolchains/nasm.lock.json`. It requires a host C compiler,
GNU make and Perl. On Debian/Ubuntu, including the WSL/Linux VM route:

```sh
sudo apt install build-essential perl qemu-user curl xz-utils ca-certificates
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
```

The NASM bootstrap tests `BITS 16`, `CPU 8086`, `ORG 0` and `-f bin`, checks
the exact bytes for `mov ax,0x1234; retf`, and verifies that `PUSHA` is rejected.
This checks instruction selection, not the correctness of an application's
native object resources or OS calls. A flat binary becomes a geode only through
the selected writer's resource/header/relocation work.

All three downloads can be supplied offline without changing their identities:

```sh
perl sdk.pl toolchain install \
  --watcom-archive /downloads/open-watcom-2_0-c-linux-x64.sfx \
  --freegeos-archive /downloads/pcgeos-260b33dcfcac15b7ecfdf04242cb0abf029ec269.tar.gz \
  --nasm-archive /downloads/nasm-3.02.tar.xz \
  --i386-runner /usr/bin/qemu-i386
```

The archive names are descriptive; their contents must match the lock files.
Each component's direct bootstrap also supports its corresponding archive
argument. See [bootstrap commands and host notes](../../tools/BOOTSTRAP.md).

## C compiler settings

The freestanding C route is intentionally narrow. The selected Open Watcom profile uses the 16-bit compiler, with the following options subject to the release's recorded validation:

| Option | Purpose |
|---|---|
| `-0` | Select 8086/8088 instruction generation. |
| `-ms` | Select the small memory model; individual boundary functions may still require explicit far linkage. |
| `-zu` | Avoid assuming that the stack segment is the default data segment. |
| `-s` | Disable the compiler's automatic stack-overflow checking sequence. |
| `-zl` | Suppress implicit default-library selection records. |
| `-zld` | Suppress compiler file-dependency metadata not needed by this small link route. |
| `-ecc` | Select the C calling convention used by the example C boundary. |
| `-nt=ALGORITHM`, `-nc=CODE` | Give generated code the segment/class identities expected by the selected link recipe. |

See the [Open Watcom C/C++ User's Guide](https://open-watcom.github.io/open-watcom-v2-wikidocs/cguide.html). Options are not interchangeable with GCC, Borland or Microsoft compiler options. The project recipe, not this table, selects the flags used for a real build.

Disabling implicit support is not proof that no support calls remain. Integer division, long arithmetic, floating point, structure copying and other operations can introduce compiler helper calls. Inspect the object and final symbol map. An import-free library must resolve all its code internally and must not acquire an unsupported DOS C runtime by accident.

A routine compiled in small model does not automatically become a GEOS-callable export. Its entry point, segment assumptions, return instruction and argument convention must agree with the assembly adapter or caller.

## Why common shortcuts fail

- **GCC `-m16`:** GCC documents it as the 32-bit model with a `.code16gcc` directive. It is not an 8086 GEOS C ABI or a replacement for this 16-bit compiler profile.
- **A DOS `.EXE`:** it has DOS startup and linking assumptions. Renaming it does not turn it into a geode.
- **A flat NASM binary:** it can be useful for tightly controlled leaf code, but does not by itself provide GEOS classes, object resources, import tables or loader relocations.
- **Current FreeGEOS libraries:** matching symbol names do not establish 1.x protocol/layout compatibility.
- **An arbitrary OMF object:** object-file support alone does not guarantee compatible symbol decoration, segment grouping, calling convention or linker records.

[GCC's own x86 options](https://gcc.gnu.org/onlinedocs/gcc/x86-Options.html) explain the `-m16` distinction.

## The bounded GUI build and general application inputs

The `ensemble12` route supplies a deliberately small, independently authored process/application/primary/view construction path for the exact supplied 1.2 target. NASM code, explicit call/method metadata, new LMem objects and the fresh native container writer form the application. Use `perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA`. The [backend contract](../../tools/ensemble12/README.md) and [reference walkthrough](recovered-references.md) explain its boundaries.

A general application path still needs all additional class/API declarations, UI construction, save/cancel behavior, imports and C-to-GEOS adapters it uses. Those require matching definitions or separately established replacements. The small libraries and bounded GUI do not prove that later GOC application samples run on 1.x.

If you supply a historical SDK, keep it outside the public repository unless redistribution is permitted. Record its source/version and hashes. Add an isolated configuration pointing to it; run an unmodified sample first. Never merge its headers into a later include tree and lose their provenance.

## Reproducibility and upgrades

Keep the source revision, tool source revisions, patches, executable hashes, flags, object maps and output hash together. Tool updates are compatibility changes: rebuild the examples, inspect symbols and instructions, and repeat relevant native tests before adopting a new version.

If a build depends on a local configuration file, publish an example without private absolute paths and document each field. Do not commit credentials, personal runtime files or the developer's entire home directory.

## Explicit local configuration

The installer writes local paths to `.sdk-local.json`, which is excluded from Git. To use an already installed toolchain, configure actual executable paths:

```sh
perl sdk.pl configure --esp /absolute/path/to/esp --glue /absolute/path/to/glue --wcc /absolute/path/to/wcc --watcom-root /absolute/path/to/watcom --nasm /absolute/path/to/nasm
perl sdk.pl doctor --require-toolchain
```

This is a path-registration step, not a compatibility certificate. The selected Esp/Glue version and legacy-format patch still matter. Environment overrides are `GEOS1_ESP`, `GEOS1_GLUE`, `GEOS1_WCC` and `GEOS1_WDIS`; a local `watcom_root` or `WATCOM` identifies the compiler installation. Avoid unintentional global overrides in a reproducible build.

The installer also accepts an explicitly supplied Open Watcom archive and an i386 runner when required:

```sh
perl sdk.pl toolchain install --help
```

Use the documented pinned archive, not an arbitrary installer with the same name. The presence of `qemu-i386` does not itself make a host/tool combination validated. After a successful build, inspect `build/<name>/build.log`, `build-report.json` and `geode-inspection.json`. The output geode is `build/<name>/<name>.geo`.
