# Scalar C library

[Deutsch](README.de.md)

This example compiles original freestanding C into a native PC/GEOS 1.x-format
library with Open Watcom and Glue. It needs no system headers, runtime startup,
heap, imported library or modern GEOS C wrapper. The exported function rotates
a 16-bit checksum left by five and XORs the low byte of its second argument.
For example, `ChecksumStepC(0x1234, 0x56)` returns `0x46d4`.

From the SDK root, after installing the toolchain:

```sh
perl sdk.pl build --project examples/math-c
perl sdk.pl inspect build/g1mathc/g1mathc.geo
perl tools/omf_audit.pl build/g1mathc/00-checksum.obj
```

The native output is `build/g1mathc/g1mathc.geo`. The pinned compiler emits 27
bytes of executable code; the example file is 370 bytes. These are file and
code sizes, not measurements of the loaded kernel/handle/resource overhead.
The build report explicitly records whether the native runtime was tested.

## Export contract

Export ordinal 0 is `_ChecksumStepC`, at offset zero in resource `ALGORITHM`.
This is a calling convention owned by this example. It does not establish a
C API for GEOS system routines or justify using SDK 2.x headers with GEOS 1.x.

| Property | Contract |
| --- | --- |
| Source declaration | `unsigned short __far __cdecl ChecksumStepC(unsigned short state, unsigned short byte_value)` |
| Arguments | Push `byte_value`, then `state`; issue a far call |
| Frame | Return IP at BP+2; return CS at BP+4; state at BP+6; byte_value at BP+8 |
| Result | AX, with a 16-bit result |
| Stack cleanup | Caller removes the four argument bytes after `RETF` |
| Volatile | AX, BX, CX, DX, ES and arithmetic flags |
| Preserved | SI, DI, BP, DS; SS and stack balance |

The project uses `-0 -ms -s -zu -zl -zld -ecc -nt=ALGORITHM -nc=CODE`.
`-0` selects 8086 instructions; `-zu` permits SS to differ from DS. Suppressing
the stack checker and default libraries does not make arbitrary C runtime
calls safe: this deliberately small source has no external symbols or fixups.
The object audit refuses such dependencies rather than supplying a DOS CRT.

The GP file uses `type library, single`, with fixed shared read-only code. It
does not set the later `c-api` attribute. It omits an initializer because the
example has no initialization; the native loader contract must still be checked
against the intended runtime. The unbound build records kernel protocol 0.0.
Structural inspection and the tests below do not certify native loading.

## Reproduce the emitted-code test

```sh
perl tests/algorithms/verify_c_geodes.pl --kind c \
  --geode build/g1mathc/g1mathc.geo \
  --report validation/math-c-execution.json
```

This executes the actual linked export for 67,096 cases, including every 16-bit
state, upper argument bits, SS differing from DS, register preservation, far
return and bounded stack writes. The 8086 opcode fixture covers these 27 bytes.
A bounded pure-Perl 8086 interpreter executes only the audited sample instructions outside GEOS. It does not test the native loader, emulate a complete CPU or measure physical CPU timing.

See [the mixed example](../math-mixed/README.md) for a register interface with an
assembler veneer and a real internal resource relocation.
