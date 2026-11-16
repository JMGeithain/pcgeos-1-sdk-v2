# GEOTEST: Verified Findings and Development Status

As of 2026-11-16. This case study records findings from the GEOTEST work. It is **not a general PC/GEOS API specification**. Claims apply only to the named file, probe, or observed GeoWorks 1.x installation.

## Goal and platform boundary

GEOTEST is a native PC/GEOS 1.x application with its own document type. The project targets 8086 code and GeoWorks 1.x. A structurally built geode, static analysis, emulator run, and user-provided observation in the target system are distinct evidence types and must remain separate. No proprietary kernel, UI, icon, or runtime files are committed to this SDK repository.

## Kernel file: file descriptor and dispatcher

The only kernel source examined was the German original `GEOWORKS/KERNEL.OLD` from `GEOWORKS.zip`, 72,688 bytes, SHA-256 `BD4D680B15F8DD66B2B09B506DE96672972F716A11E0A38220477BF07B6C1E9B`. It was not modified. Method: 16-bit disassembly plus targeted hex, control-flow, and stack analysis.

- The far pointer `ES:[0x05B8]` is loaded dynamically at raw file offsets `0x111A3–0x111B8` from an offset/segment pair. `KERNEL.OLD` contains the call site, not the implementation of the target loaded at runtime.
- In the open/create path (`0x18F6` and `0x1983`, common path from `0x18FC`), `DI=4` is called through that pointer. Assigning a DOS-handle meaning to individual register values remains a hypothesis without the actual dispatcher target code.
- `0x17CB` writes separate inputs into the FD object. After the stack-trace correction in 2532, the normal path is: `FD+0` receives the low byte of input `BX`; `FD+2` the low byte of `AX` saved before `DI=4`; `FD+3` the low byte of `AX` remaining after `DI=4`; `FD+6` the result of `0x0D2B`.
- `0x0D2B` validates through `0x12C5` and maps the value through `0x14BB` into an internal table. `0x14BB` uses a 22-byte stride and base `0x021C`. `0x0D95/0x0DA8` resolve `FD+6` again as this internal key/table reference.
- No examined kernel site passes `FD+6` itself as a raw DOS file handle to a DOS function call. `DI=0x16` is called, among other paths, with `AH=0x40` (write); addendum 2531 also found the same service with `AH=0x42`, `0x46`, and `0x3E`. The driver might perform an internal translation, but that code was not examined here.

**Correction history:** Early reports 2513 and 2530 misassigned some bytes. The stack trace in 2532 is authoritative. Therefore neither `FD+0` nor `FD+3` should be called a universal DOS handle. What is established is the field source above and the internal processing of `FD+6`; the external dispatcher's semantics and any handle translation remain open.

## Custom document format GTDF v1

GTDF is a flat, application-specific ASCII test format inside an observed GEOS file wrapper. It is not a GeoWrite, VM, or universal PC/GEOS document format.

| Offset | Contents |
|---|---|
| `0x00–0x03` | GEOS signature `C7 45 CF 53` |
| `0x04–0x13` | 16-byte prefix copied from an empty GeoWrite reference; field meanings unknown, preserved unchanged |
| `0x14` | Type token `GTD1`, manufacturer ID 0 |
| `0x1A` | Creator token `GTAP`, manufacturer ID 0 |
| `0x20–0x3F` | NUL-terminated title and padding through offset `0x40` |
| `0x40` | `GTDF`, version `u16=1`, header size `u16=12`, payload length `u16`, reserved `u16=0` |
| `0x4C` | printable ASCII payload, currently at most 40 bytes |
| after payload | trailer `GTE!`, followed by exact EOF |

All multibyte fields are little-endian. Total size is `80 + N` bytes. The parser checks signature, tokens, magic, version, header size, length bound, printable bytes, trailer, and EOF. The 16-byte prefix is a limited compatibility carry-over; its meaning has not been determined.

## Application/document tokens and icons

- Application: token `GTAP`, manufacturer 0; application moniker is the monitor.
- Document type: token `GTD1`, manufacturer 0; its own icon is the test pattern.
- A four-plane EGA PCX must be 48x30 pixels, 1 bit per plane and four planes. A supplied 8-bit/one-plane PCX was not accepted by `ICONMAKE 1.0` as an EGA icon. A lossless conversion of its 16 color-index planes into four planes was checked by decoding it back.
- The icon workflow used `ICONMAKE m0 GTS1,0 GTS1_EGA.PCX`; `ICONMAKE` created token dummy `GTS10000.000`. User screenshots confirm the GTS1 moniker and the application icon in GeoManager. A separate dummy `GTD10000.000` is intended for the document token; token creation and visible document association must be checked separately.
- Test-system DOS filenames must follow 8.3; PCX example name: `GTS1_EGA.PCX`.

## Observed implementation steps

- Earlier probe: the user saw `WRITTEN` after create/write/close and then `EXISTS` on a subsequent open; the existing file was not overwritten. This establishes the observed I/O path on that installation, not a general error-code or kernel API guarantee.
- GTDF samples were opened under GeoWorks 1.x and displayed `EXACT` plus the read content. User screenshots confirmed, among others, the wrapping `GEOTEST DOCUMENT` / `PAYLOAD V1` (2540) and `GEOTEST DOKUMENT` / `2026` (2541). The user confirmed a GeoManager double-click opening GEOTEST 2537 for the test document.
- The GTDF v1 sample `GTST2537.000` is 107 bytes, payload `GEOTEST document payload v1`, SHA-256 `15223E9079AC05FADB94620DCAC17A4FA2D53EC278D9FBDF7D53B8954DD64494`.
- Source revision 2543 added a create-if-missing probe with read, validation, close, and read-back. Its recorded build report says `runtime_tested=false`; later user screenshots from other version states do not prove execution of this exact artifact. Therefore no runtime pass for 2543 itself should be claimed from the build report alone.

## Menu/dialog work: current open status

Requested UI: a `Datei` menu with `Neu` and `Öffnen`, documents under `GEOWORKS\DOCUMENT`, monitor icon for the application, test-pattern icon for documents, plus `Info` and `Hilfe`.

A generator-only probe using local original templates (`SPINTEXT.GEO`, `NOTEPAD.GEO`, `VIEWER.GEO`, `TERM.GEO`) produced a native UI resource with 53 objects and 23 triggers. The templates differ in hash and size from an earlier SDK reference. This proves only that the generator can create an object structure from those bytes.

**Not implemented or proven yet:** a new GEOTEST version with the requested menus, working `Neu`/`Öffnen` actions, a native file selector correctly starting at `GEOWORKS\DOCUMENT`, Info/Help dialogs, and a runtime check of those functions. The existing native UI example contains 386 code and must not be copied into the 8086 target. Its object layouts are a research reference, not a finished GEOTEST implementation.

## Next steps

1. Identify the `DI=4`/`DI=0x16` dispatcher target in the actually loaded original installation and compare its register contract with observed callers.
2. Implement the 8086 menu/dialog path for `New`, `Open`, `Info`, and `Help` without reusing the 386 adapter.
3. Set the native FileSelector to `GEOWORKS\DOCUMENT` and test paths using disposable copies.
4. Structurally inspect a fresh build, then observe each action in the specific GeoWorks 1.x system. Keep build status separate from runtime evidence.
5. Claim system-wide document association only after GeoManager icon and double-click behavior are confirmed for the isolated document type.

## Evidence boundary and provenance

Findings come from the German GEOWORKS archive, GEOTEST source/build reports, and user-provided screenshots from the installed GeoWorks 1.x system. The kernel binary and proprietary runtime templates are not copied into this repository. Screenshots prove only visible states and identifiable versions; they are not universal file-format or API guarantees.

