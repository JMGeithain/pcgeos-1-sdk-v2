# Writing C, assembly and mixed modules

[Handbook](README.md) · [Deutsch](../de/c-and-assembly.md)

A useful division is to keep algorithms in ordinary C and keep OS-specific entry points and ABI translation small and explicit. Assembly-only projects are equally valid. Choose the language for clarity and measured cost, then validate the complete result.

## Start from the supplied examples

Build the selected project from the repository root:

```sh
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

Read each project's source and export contract before writing a caller. These examples are libraries, not applications. Their lack of OS imports is intentional: they can demonstrate the compiler/assembler/linker boundary without depending on unverified 1.x UI declarations.

For a working native window around these algorithms, continue with the [GUI tutorial](native-applications.md) and [library probe](../../examples/hello-libraries/README.md). Its assembly UI imports the C/mixed libraries through their explicit interfaces. This is a practical C-backed application route without claiming a complete C system API.

Changing the pure calculation is a good first exercise. Adding a call into the OS is a different exercise that requires the target API inventory and import/profile checks described in [Compatibility](compatibility.md).

## Ordinary C is not GOC

Ordinary C defines functions and data according to the selected compiler. GOC adds a GEOS-oriented object-language layer that a translator expands into C. A `.goc` file is not accepted by an ordinary C compiler merely because much of it looks like C.

For freestanding C logic:

- prefer simple, bounded operations and explicit input/output ranges;
- check the target widths of `char`, `short`, `int`, `long` and pointers;
- avoid assuming that host `int` and target `int` have the same width;
- do not use a host pointer value as a resource handle or object pointer;
- inspect operations that may introduce compiler support routines;
- choose the available C language level deliberately; later C syntax may not work with a historical compiler.

A portable arithmetic example can check its assumptions without any GEOS call:

```c
/* Ordinary C example, not an OS entry point. */
#include <limits.h>
#if USHRT_MAX != 65535U
#error This example requires a 16-bit unsigned short.
#endif

unsigned short add_saturating_u16(unsigned short a, unsigned short b)
{
    if (b > 65535U - a) {
        return 65535U;
    }
    return (unsigned short)(a + b);
}
```

Host tests can establish the arithmetic behavior for boundary inputs. They do not establish the compiler's far-call convention, native export layout or loader behavior.

## The C example's own scalar ABI

`examples/math-c/checksum.c` declares its exported calculation as `__far __cdecl` for the selected Watcom compiler. The actual object symbol is `_ChecksumStepC`; use the example's GP/export metadata rather than assuming how another compiler decorates the same source name.

| Item | C-only example contract |
|---|---|
| Parameters | Two 16-bit word scalars: checksum state, then byte value. |
| Entry | Far C call to the loaded library export. |
| Argument order | Caller pushes rightmost argument first. |
| Stack after saving BP | State at BP+6; byte value at BP+8, after the far return address and saved BP. |
| Result | AX contains the 16-bit result. |
| Cleanup | Caller removes the four argument bytes. |
| Caller-saved | Treat AX, BX, CX, DX and ES as volatile. |
| Callee-preserved | SI, DI, BP and DS. |
| Flags | Not a public result; do not depend on arithmetic flags. |

This is an explicitly selected **library ABI owned by this project**, not a declaration that GEOS 1.x kernel/UI calls use the C convention. The compiler profile uses `-zu` so code does not assume SS equals DGROUP. It suppresses automatic stack-check/default-library machinery, so the application must still budget stack use and inspect unresolved helpers.

At the instruction level, a suitable assembly caller places both words on the stack, calls the verified loaded far export and adjusts SP by four afterward. Obtaining and keeping that loaded entry point is a separate native loader/lifetime operation. It needs the matching application profile; do not fill that gap with an unverified system ordinal or a raw pointer copied from an inspection file.

The supplied probe demonstrates this with a declared native library import and the `LC` macro's source1/type4 call relocation. UI is import index0; the three example libraries occupy indices1 through3. The loader resolves the declared export; the source does not hardcode a previous run's loaded segment.

The current generated routine is a small scalar calculation. Its exact byte count is a build result, not a permanent ABI promise. Future changes may use additional caller-saved registers even if today's disassembly happens not to.

## Define every boundary

Before connecting two modules, write a contract with these fields:

| Field | Examples of what must be specified |
|---|---|
| Entry type | Near routine, far routine, GEOS method, exported library routine or callback. |
| Parameters | Registers, stack layout, parameter order, widths, pointer representation and ownership. |
| Results | Registers, memory outputs, flags and failure encoding. |
| Stack | Who removes arguments; exact bytes consumed; alignment assumptions. |
| Segments | Incoming and outgoing DS/ES/SS expectations; default data group requirements. |
| Preserved state | Register and flag preservation, direction flag, graphics state if relevant. |
| Lifetime | Whether a pointer is valid only during a lock or callback. |
| Reentrancy | Thread ownership, possible callbacks, blocking and shared-state rules. |
| Linkage | Owning module, symbol spelling/decoration, protocol and import/export identity. |

Do not copy a C calling convention into a GEOS method handler. A method can receive arguments and return values in an OS-defined register contract. Likewise, a native helper may deliberately change a segment register or a result register. “Preserve every register” can be just as incorrect as preserving too few.

## Near and far are separate decisions

An 8086 near call changes the instruction offset within the current code segment. A far call also changes the code segment. These calls require compatible returns and stack layouts. A far data pointer is not an object pointer, and a far pointer does not solve the lifetime problem of movable storage.

Use the selected compiler's declarations and assembly syntax. A keyword accepted by Watcom may be spelled differently by another compiler. Inspect the generated object or listing rather than assuming that a declaration produced the intended call.

## A mixed-language adapter

A small assembly adapter can:

1. receive the verified native call or method parameters;
2. preserve only the state required by that native contract;
3. establish the C function's data/stack assumptions;
4. translate arguments into the selected compiler's convention;
5. call the C function through the correct near/far linkage;
6. translate results and errors back into the native contract;
7. release any owned temporary resource and return with the correct stack effect.

Keep this adapter short. Test it with distinctive register values and different caller/callee data segments so an accidental dependency does not pass unnoticed. Test zero, maximum values, carry/overflow cases and repeated calls. If it uses a callback, test the callback independently rather than treating a function pointer as an ordinary address.

For a pure function, an assembly implementation can serve as an independent oracle for the C implementation. Compare results across an exhaustive small domain or a meaningful boundary set. Do not make both versions share the same incorrect assumption and call that independent verification.

## The mixed example's two resources

The verified mixed link route keeps the C function and assembly bridge in separate fixed code resources: the C `ChecksumFar` function uses the `ALGORITHM` resource, and the ESP exports use `BridgeCode`. The bridge makes a **far** call into the C resource. It is not a near call merely because both resources belong to one library.

| Export | Inputs | Result | Preserved |
|---|---|---|---|
| `ChecksumStep` | AX = checksum state; DX = byte value | AX = updated 16-bit checksum | BX, CX, DX, SI, DI, BP, DS, ES and caller stack |
| `SaturatingAdd` | AX and DX = unsigned 16-bit values | AX = the sum, capped at 65535 | BX, CX, DX, SI, DI, BP, DS, ES and caller stack |

Flags are unspecified. These are this example's **register interfaces**, distinct from both the raw C-only export and any GEOS system API. The assembly saves the promised caller state, supplies the C scalar stack arguments, calls the private far C function, removes its arguments and returns the result through the register contract.

The actual linked output includes the native resource-segment relocation for that far C call. Testing should verify the owning resource and relocation field as well as the calculation result. Treat an unrelocated file offset or current resource segment as a temporary implementation detail, not an export address that another program can hardcode.

Read the bilingual example README and build report for the exact current symbols and export order. A successful mixed link establishes the toolchain boundary exercised here; native loader/runtime validation remains a separate step.

## ESP and generic assemblers

ESP understands GEOS-oriented declarations and integrates with the matching SDK include/resource conventions. NASM or another x86 assembler can assemble machine instructions, but cannot automatically replace the ESP object model, UI compiler and native linker support.

Keep source dialects distinct. Semicolon comments and `proc`/`method` directives in an ESP file are not interchangeable with every MASM/NASM construct. The editor's syntax support helps reading; the actual assembler and target profile determine valid source.

## Assembly review

Inspect the final executable ranges, not only handwritten source. Check stack balance, far-call relocation identities, segment handling and instructions introduced by the compiler or libraries. Separate code from embedded data before disassembling. A byte with the value of an unsupported opcode inside a bitmap is not an executed instruction.

The later [Mixing C and Assembly manual](https://bluewaysw.github.io/pcgeos/Esp/emixing.html) is a useful guide to the problems a bridge must solve. It does not establish a historical 1.x C wrapper ABI by itself.
