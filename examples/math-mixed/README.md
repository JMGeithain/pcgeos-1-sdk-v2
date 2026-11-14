# Mixed C and assembler library

[Deutsch](README.de.md)

This example combines the same original scalar C algorithm as `math-c` with an
Esp assembler register interface. It also exports an assembler saturating-add
function. Each language has its own fixed code resource: `ALGORITHM` contains
far C function `_ChecksumFar`; `BridgeCode` contains the exported veneers.
Glue emits the real internal segment relocation for the far call between them.

From the SDK root:

```sh
perl sdk.pl build --project examples/math-mixed
perl sdk.pl inspect build/g1mixed/g1mixed.geo
perl tools/omf_audit.pl build/g1mixed/00-checksum.obj
```

The native file is `build/g1mixed/g1mixed.geo`: 436 bytes with the pinned tools,
including 27 C code bytes and 35 assembler code bytes. This is not a loaded-memory
measurement. Both resources are fixed to make the direct far-call contract
explicit. A larger application should use the target kernel's verified resource
and call conventions before making either resource movable.

| Export ordinal | Name | Inputs | Result | Preserved |
| --- | --- | --- | --- | --- |
| 0 | `ChecksumStep` | AX: state; DX: value | AX: rotate-left-5(state) XOR low-byte(value) | BX, CX, DX, SI, DI, BP, DS, ES |
| 1 | `SaturatingAdd` | AX: a; DX: b | AX: min(a+b, 65535) | BX, CX, DX, SI, DI, BP, DS, ES |

Both exports use far calls and `RETF`; flags are unspecified. These register
contracts belong to this example, not to any GEOS system API. The assembler
veneer saves registers, pushes the C arguments right to left, far-calls the C
function, removes four argument bytes and restores registers. The C function's
own contract is `__far __cdecl`, with arguments at BP+6 and BP+8 after its
prologue. It may change AX, BX, CX, DX, ES and flags; the veneer preserves all
listed registers at its exported boundary.

Keeping C and Esp in separate resources also avoids assuming that their object
formats agree on a near procedure's symbol type. This build uses the actual
Watcom OMF object directly; it does not convert code bytes into source or silently
discard external references. `omf_audit.pl` verifies the intentionally restricted
C component has no external references, fixups, nonempty data or runtime helpers.

The library has no imports or initializer. Its unbound kernel protocol is 0.0.
It does not set the later `c-api` attribute or import SDK-2.x C wrappers. Native
loading and any required initializer/protocol must be validated on the intended
GEOS 1.x runtime; the build and CPU test do not establish this.

## Reproduce the emitted-code test

```sh
perl tests/algorithms/verify_c_geodes.pl --kind mixed \
  --geode build/g1mixed/g1mixed.geo \
  --report validation/math-mixed-execution.json
```

The test reads both actual linked resources, checks exact audited 8086 instruction
bytes and exports, and applies only the expected fixed-resource segment relocation
to its test load address. A bounded pure-Perl 8086 interpreter executes only the audited sample instructions. It executes 67,096 checksum cases and 4,160 saturating-add
cases, checks preservation and bounded stack writes, and runs with SS different
from DS. It does not implement the GEOS loader or resource manager, boot the OS,
or measure physical 8086/8088 timing.
