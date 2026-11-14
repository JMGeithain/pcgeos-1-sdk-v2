# Debugging and testing

[Handbook](README.md) · [Deutsch](../de/debugging-and-testing.md)

Use several layers of evidence. Host tests are fast, native instruction tests expose ABI mistakes, and the actual OS exposes scheduling, ownership and repaint behavior that stubs cannot reproduce.

## The development loop

```sh
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
perl sdk.pl build --project examples/math-mixed
```

Use the actual project you are changing. Save the full build log and output hash. If the selected native profile is blocked, resolve the prerequisite instead of disabling its checks.

## What each layer can prove

| Layer | Good at finding | Does not prove by itself |
|---|---|---|
| Source/configuration checks | Invalid configuration, missing paths and inconsistent metadata. | Native API behavior. |
| Portable unit tests | Algorithm boundaries and deterministic serialization. | 16-bit ABI or GEOS loading. |
| Format tests | Table extents, resource bounds, relocation encoding and file identity. | Correct routine meaning or private class layout. |
| Emitted-code execution | Register/stack contracts, branches, arithmetic and selected memory writes. | Real scheduling, allocation, graphics or lock ownership when those are stubbed. |
| Native emulator tests | Loader integration, UI behavior, actual OS calls and driver interaction. | Physical-hardware timing or every installation. |
| Hardware tests | Actual device/CPU behavior for the recorded machine. | Every other hardware configuration. |

A generated fixture is valuable for testing a parser's bounds checks. Label it synthetic; it is not a historical runtime sample.

## Debugger setup

Use a debugger and symbols compatible with the selected target. The later [Swat introduction](https://bluewaysw.github.io/pcgeos/Tools/tswatcm.html) and [tool manual](https://bluewaysw.github.io/pcgeos/Tools/ttools.html) explain the development model, but a modern Swat build, current kernel stub and later symbol set are not automatically compatible with a 1.x runtime.

First prove the debugger connection with the unmodified target. Record the stub, kernel and symbols used. Without that match, prefer a bounded external instruction harness and native logs/screenshots to pretending that an unusable debugger is configured.

## ABI test design

Execute the actual final code bytes where practical. Verify that the tested payload, hooks and relocation records match the built file before patching private test selectors or replacing system calls with stubs.

Seed registers and caller/callee segments with different values. Check argument order, return address, final stack pointer, ownership transfer and the documented output registers and flags. Do not require every register to remain unchanged if the native contract deliberately returns a changed value.

Use a separate identity for each imported library. Assert writes stay within intended data and stack ranges. Add negative controls: corrupt an operand, change a relocation's owning library or alter a hook and ensure the test rejects it.

If the code uses an existing native helper, execute that helper too when possible. A high-level stub of its presumed behavior can accidentally encode the same mistaken assumption as the implementation.

## Native integration matrix

| Area | Minimum useful actions |
|---|---|
| Startup/shutdown | Launch, normal close, repeat launch, partial initialization failure. |
| Input | Mouse press/release/cancel, keyboard focus, default action and native menu behavior. |
| Drawing | Cover/uncover, move, resize, minimum size, maximize/restore and minimize/restore. |
| Documents | Modify, save, close with each choice, cancel and verify exact retained content. |
| Dialogs | Modal focus changes, property-window close, owner destruction and reopening. |
| Memory | Large operation, allocation pressure, multiple applications, swap and recovery. |
| Threads | Completion, cancellation, close during work and late-result handling. |
| Libraries | Every export, repeated calls, multiple clients and load/unload behavior. |
| Devices | Original low-color driver, optional higher-depth driver and supported fonts. |
| Localization | English/German strings, character encoding, long labels and paths. |

Wait for a stable observable result. Native repaint and application work may be queued. A screenshot captured too soon after resize can show an incomplete frame. Conversely, a UI that never finishes must not be excused as “just asynchronous.” Record the observation and a reasonable completion deadline for the test.

## 8086 and low-memory configuration

For the 8086/8088 target, use an emulator mode that rejects later instructions and an appropriate driver. A 386 emulator configured with little RAM does not perform that CPU test.

For a stated 640 KB conventional-memory test, record available DOS conventional memory and disable XMS/EMS/UMB when that is the promised configuration. Record whether disk swapping is enabled. Run another application and exercise the expensive or dialog paths; an idle first window is not a low-memory stress test.

Measure peak memory only with a defined measurement method. Report file size or a known payload increase as those quantities, not as total RAM. Keep timing comparisons on the same emulator/core/cycle/driver configuration and use repeated measurements rather than one stopwatch impression.

## Investigating a failure

Reduce the change while preserving the failing sequence. Compare with a known-good unmodified baseline on the same runtime. A failure present in both is useful context, but does not automatically make a new result acceptable.

Typical clues:

- An immediate loader rejection suggests format, dependency or protocol problems.
- Correct first paint followed by missing controls suggests repaint ownership or invalidation.
- Wrong data after a call suggests segment, stack, register-output or pointer-lifetime assumptions.
- A UI freeze during paint suggests blocking, a foreign lock or reentrant work in the redraw path.
- An illegal instruction suggests the emitted code or a dependency exceeded the CPU target.
- A low-memory crash suggests unchecked failure, too many locked blocks, recursion or a transient allocation peak.

Do not patch a kernel assertion out to make the test continue. Establish the caller and contract that caused the failure.

## Evidence to keep

Publish source revision, tool identities, build flags, binary hashes, target identities, CPU/memory/driver settings, actions and results. Distinguish automated checks from observed UI tests. Preserve representative native screenshots and exact pixel samples when making color/geometry claims. Exclude personal documents and unrelated runtime data from public artifacts.
