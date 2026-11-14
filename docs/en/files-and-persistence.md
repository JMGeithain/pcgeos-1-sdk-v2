# Files, documents and persistence

[Handbook](README.md) · [Deutsch](../de/files-and-persistence.md)

Design persistent data independently of live pointers, compiler padding and the current arrangement of resource blocks. An application that draws correctly but loses a document on a failed save is not ready for release.

## Choose the representation deliberately

| Representation | Suitable use | Questions to resolve |
|---|---|---|
| A plain structured file | Small documents, interchange, simple sequential data | Exact bytes, byte order, versioning and validation. |
| A supported GEOS VM file | Data naturally divided into managed blocks | VM API availability, dirty/update rules and block ownership. |
| A target-provided document framework | Integration with native open/save/close behavior | Exact 1.x classes/messages and lifecycle responsibilities. |
| A database service | Collections needing the target's supported database facilities | Available library/protocol, item lifetime and recovery rules. |

Do not assume a class or convenience routine exists in 1.x because it appears in the later [file-system](https://bluewaysw.github.io/pcgeos/Concepts/cfile.html) or [VM](https://bluewaysw.github.io/pcgeos/Concepts/cvm.html) reference. Use those references to understand the concepts, then resolve each concrete API through the target inventory.

## Define an on-disk format

For an application-owned format, write down the magic/version, lengths, integer widths, byte order, permitted ranges and optional sections. Validate sizes before multiplication or allocation. A count supplied by a file must not overflow a 16-bit byte-size calculation.

Avoid writing a C structure directly with its host `sizeof`. Its padding, integer widths and pointer fields can differ across compilers or models. Serialize fields explicitly. Never store a segment value, CPU pointer, live global handle or current local-memory address as though it will still be meaningful next time the file is opened.

Choose whether text is stored in a defined native character set or a documented interchange encoding. The English and German application should share the same document representation; translating menu labels must not change the file's meaning.

Handle a newer document version deliberately: reject it with a useful message, or read a documented compatible subset without destroying the unknown data. Do not silently save an incompletely understood document as an older version.

## File identity and metadata

A GEOS document can have native type/creator metadata in addition to DOS directory information. Use the supported target APIs and conventions to create that identity. Merely giving a file a familiar extension does not establish its native type.

Test short DOS names, paths with spaces, case differences, target character-set names, full disks, read-only media and unavailable directories. A host shared folder's behavior can differ from a real DOS filesystem. Keep host paths out of portable document records.

Close every successfully opened handle on all error paths. Do not reuse a handle after closing it, or treat a handle of one kind as a handle of another kind.

## VM blocks are another handle domain

A VM block belongs to its VM file. Its handle is not automatically a global-memory handle or a directly usable address. Lock, access, mark modified and unlock in the order required by the exact target API. Keep the file and block ownership valid throughout the operation.

As with local memory, avoid keeping pointers across calls that can move or replace storage. A lookup table containing handles can be more robust than one containing transient pointers, provided its handle lifetime is defined.

Separate persistent document state from runtime-only data such as open windows, graphics states, queues and caches. Reconstruct runtime state after loading the document rather than serializing raw process memory.

## A save operation is a transaction design

A robust save has several phases: validate the model, produce the new bytes, detect write/flush/close errors, and publish the new version according to the filesystem's actual guarantees. A temporary file plus rename can be a useful strategy, but do not call it atomic unless the target filesystem and APIs provide that guarantee.

Define recovery behavior for partial writes or interrupted replacement. Preserve the last known good copy until the replacement has succeeded according to that strategy. Report errors to the user and retain the application's unsaved state when saving fails.

If saving is cancellable, define the last point where cancellation is safe. Do not abandon a file halfway through a replacement and then clear the modified flag. If saving runs in a worker thread, snapshot or synchronize the model so the saved data has a coherent revision.

## Close and cancellation

A document's modified state belongs to its lifecycle. Verify these separate routes:

1. Close an unchanged document.
2. Modify, close and save successfully.
3. Modify, close and decline saving through the supported route.
4. Modify, close and cancel; preserve both the open document and its data.
5. Modify, attempt a save that fails, then cancel closing.
6. Exit the application with multiple documents or outstanding work.

Do not replace the native document-close path with an unconditional application exit. A property dialog's Close is a different action from closing the document that owns it.

## Test data and recovery

Keep a small known-good file, a boundary-size file, truncated files, invalid lengths, unknown versions and representative German text. Test each reader without allowing it to overwrite the original fixture. Where possible, use a host-side parser or serializer test for application-owned formats and a separate native test for the actual file/VM API.

An exact byte comparison is appropriate for deterministic application data. For a native VM container whose block organization may vary, compare the documented logical data and structural invariants rather than assuming every allocation decision must be byte-identical.
