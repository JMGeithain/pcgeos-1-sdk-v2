# Third-party components and provenance

The MIT license covers original files in this repository, not the operating system, compiler or emulator downloads.

| Component | Source and license | How it is used |
|---|---|---|
| FreeGEOS Esp/Glue sources | [Official repository](https://github.com/bluewaysw/pcgeos), Apache-2.0 umbrella license and retained per-file notices | The bootstrap fetches a pinned revision and applies the included reviewed host/legacy-output patches. Modern headers are not shipped as verified 1.x headers. |
| Open Watcom v2 | [Official repository](https://github.com/open-watcom/open-watcom-v2), Sybase Open Watcom Public License | Pinned external compiler archive, hash checked before selected extraction; installer code is not executed. The extracted license is retained. |
| NASM 3.02 | [Official release](https://www.nasm.us/pub/nasm/releasebuilds/3.02/), BSD-2-Clause | The bootstrap downloads hash-pinned source and builds native Linux host tools. Its exact license is retained beside the installation. No NASM binary is bundled in this repository. |
| QEMU user-mode runner | [QEMU project](https://www.qemu.org/), GPL and component-specific notices | Optional host prerequisite for 32-bit build tools. No QEMU binary is included. |
| DOSBox-X | [Official project](https://dosbox-x.com/), GPL-2.0 | Optional native-target emulator described in the handbook; not bundled and not used to claim an unavailable runtime test. |
| Visual Studio Code | [Official documentation](https://code.visualstudio.com/docs) | Optional editor. This repository supplies original grammars, snippets and a local language-server client, not VS Code binaries. |

Exact compiler/source identities are in `toolchains/*.lock.json`. Read those files rather than relying on a moving `latest` tag. Each bootstrap rejects a changed archive. Downloaded notices remain beside the private installation. Redistribution of a modified upstream tool must retain its applicable source/notices and satisfy its license.

The native format inspector cites the pinned upstream structure definitions and linker implementation in its output. Its synthetic fixtures are original tests and are not native-runtime evidence. Original commercial 1.x SDK headers/import definitions, a GEOS runtime and user application binaries are intentionally absent.

The included FreeGEOS patches retain upstream context under its applicable terms;
see [the upstream license copy](tools/patches/UPSTREAM-LICENSE.txt) and
[patch attribution and explanation](tools/patches/README.md). Downloaded complete
source files keep their own copyright and license notices. The patch does not
grant rights to redistribute unrelated commercial runtime files.
