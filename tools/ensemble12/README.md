# Observed Ensemble 1.2 application backend

This original backend emits a new native application from NASM code, fresh
LMem object declarations and a zero-origin container header. It reads no stock
application as a template and includes no proprietary icon or object payload.
It targets the exact supplied Ensemble 1.2 profile (kernel 622.3, UI 693.0), not
every 1.x release. A matching target identity is distinct from an execution test.

From the repository root after toolchain installation:

```sh
perl sdk.pl build --project examples/hello-asm --target-root /path/to/owned/GWSVGA
```

The normal CLI resolves NASM and writes `build/g1hello/`. The backend can also
be invoked directly for diagnosis:

```sh
perl tools/ensemble12/build.pl --project examples/hello-asm \
  --output-dir build/g1hello --nasm /absolute/path/to/nasm \
  --target-root /path/to/owned/GWSVGA
```

`--target-root` checks the exact kernel/UI/Motif hashes in
`targetprofiles/supplied-ensemble12.json`; no runtime file is incorporated into
the output. Direct construction without that argument is format-only research.
The public CLI may require it for an application. Read the current root
validation record for actual runtime results.

## Source contract

The project has `kind: application`, `backend: ensemble12`, `cpu: 8086` and
one `sources` entry with `language: nasm`. `long_name`, `token`, `view.width`,
`view.height` and `imports` are explicit declarations. An additional import
has a permanent `name`, its own `protocol: [major,minor]`, and optional
`attributes` (library default 16384). UI automatically occupies index 0;
additional imports start at 1. A protocol does not declare a calling convention.

Include `ensemble12.inc`, declare methods using `G1_METHOD message, label`,
and finish with `G1_FINISH`. Each `KCALL ordinal` records a real kernel-call
operand with native relocation 00h. `LC import_index, ordinal` records a native
library-call operand with relocation 14h. A macro-generated label identifies the
operand; the builder does not search arbitrary code for byte 9Ah. It removes the
method/relocation footer from the emitted code resource.

The initialized DGROUP is 256 bytes, beginning with the native 64-byte TPD and a
process class at 40h. The process has 2048 bytes of uninitialized stack. The class
derives from the observed UI export0 and records method IDs and far handlers.
The two UI resources contain one `GenApplication`, `GenPrimary` and `GenView`.
The view sends exposed events to the process. There is no separate custom
content object, general UI language, menu/document generator or GOC runtime.

These defaults deliberately keep the starter small. Extending them requires
checking native field/ABI evidence and adding tests; changing a later SDK's
class definition is not sufficient.

## Drawing lifecycle

The example receives a window handle with the exposed event, creates a GState,
begins the native update, paints within clipping, ends the update and destroys
the GState. It retains neither a window handle nor a movable resource pointer.
Its small glyphs and rectangles are original graphics drawn through GEOS;
there is no framebuffer assumption or borrowed font bitmap.

Open/attach forward to the observed process superclass. Close returns no extra
saved state. This is a non-document demonstration. A document application needs
its own verified model/controller, save/cancel and lifecycle behavior.

See [the English handbook](../../docs/en/recovered-references.md) and
[German handbook](../../docs/de/recovered-references.md) for provenance,
compatibility limits and the distinction between later public sources and the
observed1.2 ABI.
