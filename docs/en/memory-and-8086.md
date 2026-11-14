# Memory, pointer lifetimes and the 8086/8088

[Handbook](README.md) · [Deutsch](../de/memory-and-8086.md)

A 640 KB installation is a system-wide budget. DOS, the kernel, UI, drivers, fonts, shared libraries, other applications and temporary allocations all compete for space. A small `.GEO` file is useful, but is not a measurement of resident or peak RAM.

## Four identities to keep separate

| Value | Meaning | Common error |
|---|---|---|
| Resource/global handle | Identity managed by the OS | Treating its numeric value as a memory address. |
| Local-memory chunk handle | Identity within a local-memory block | Assuming it is permanently the data's byte offset. |
| Object pointer | Identity of an object in a block/chunk scheme | Casting it to a normal C pointer. |
| CPU pointer | A currently usable near/far address | Keeping it after the storage can move or disappear. |

Use the target headers' types. Host pointer sizes and C integer promotions can hide errors that become visible on the 16-bit target.

## Locking does not remove every movement hazard

A global block lock and local-memory allocation solve different problems. Even when a block remains at the same segment, a local-memory operation can move chunks inside it. Re-dereference the chunk after operations that can compact or resize that block.

Keep a pointer's valid scope short. Read or modify the required data, then release the lock according to the exact API. Store an identity for later work, not a pointer that happened to be valid now. Do not keep instance pointers across message dispatch, allocation, object duplication or other calls unless the native contract explicitly permits it.

The later [handle](https://bluewaysw.github.io/pcgeos/Concepts/chandle.html), [memory](https://bluewaysw.github.io/pcgeos/Concepts/cmemory.html) and [local-memory](https://bluewaysw.github.io/pcgeos/Concepts/clmem.html) chapters explain the architectural distinctions. Their data layouts are not a substitute for matching 1.x definitions.

## Avoid lock chains in paint and callbacks

A paint routine should draw from local, stable state. Looking up a foreign object and acquiring its block lock during a redraw can create a cross-thread lock dependency. A stubbed unit test that pretends every lock succeeds will not reveal such a deadlock.

Cache only information you can keep valid through a documented ownership mechanism. When an interaction changes it, update the cache through messages and request an appropriate repaint. Prefer conservative drawing over an unverified foreign-memory read.

For routines that must acquire multiple locks, document an order and release them on every exit. Include failure and reentrancy cases in testing. Never turn an allocation failure into a dereference of an absent or stale pointer.

## Budget the whole operation

| Quantity | Useful measurement |
|---|---|
| Native file size | Exact output bytes and hash. |
| Fixed/global data | Declared and loaded size, initialization and sharing. |
| Code/resources | Loaded resources at a representative workload, not only totals on disk. |
| Stack | Worst nested call path, callbacks, local arrays and interrupt/system overhead. |
| Heap/handles | Live allocation count, peak bytes, fragmentation and temporary blocks. |
| Graphics | Regions, graphics states, caches, font data and image buffers. |
| Documents | Loaded model, undo history, VM cache and unsaved changes. |
| Shared system cost | Dependencies already loaded versus introduced by this application. |

Measure idle, normal use, a large document, task switching, a costly operation and recovery from failure. Report the conventional-memory configuration and disk swapping separately. If peak RAM is not instrumented, say so; do not derive it from file growth.

## Techniques that preserve behavior

Use bounded buffers, release temporary storage promptly, avoid duplicate tables, separate optional resources and cap work queues. Compute expensive data once when it changes, rather than on every paint. Prefer integer or fixed-point arithmetic when its range and precision meet the application's actual requirements.

An optimization is not acceptable if it silently reduces the problem range, loses document data, changes arithmetic results, removes undo guarantees or blocks other applications. Write equivalence tests before replacing a correct C routine with assembly.

Disk swapping can make a low-conventional-memory configuration usable, but it does not eliminate handles, locked-block limits, stack pressure or I/O delays. Test both the operation and cancellation/close while the system is under pressure.

## Instruction-set target

8086 and 8088 share the relevant base instruction set, while their timing and memory-bus behavior differ. Build the new assembly with the selected assembler's 8086 restriction. Configure the C compiler for 8086 output, then inspect the final executable ranges and any compiler helpers.

Examples of instructions that must not slip into an 8086-only path include `PUSHA`/`POPA`, `ENTER`/`LEAVE`, immediate pushes and later multi-operand forms. Operand/address-size prefixes and 32-bit register use require a later processor. A modern compiler's “16-bit mode” flag is not enough.

Audit reachable code, not arbitrary data bytes. Embedded graphics, tables and relocation operands can contain bytes that resemble opcodes. Conversely, auditing only your handwritten assembly misses instructions in C output, runtime helpers, imported libraries and drivers.

A supplied video driver can require an 80186 or later CPU independently of your application. Test an 8086-capable configuration with an appropriate original driver, and a separate higher-color configuration when necessary. Do not infer that a TrueColor driver is 8086-safe from the application build settings.

## What to publish

Publish the exact build flags, emitted-code audit scope, emulator CPU and memory configuration, tested driver identities and workload. State whether the result was also run on physical hardware. Keep “file size,” “primary data payload,” “allocated heap” and “peak system memory” as separate measurements.
