# Contributing / Beiträge

Use the same topic filenames in `docs/en/` and `docs/de/`. Keep commands consistent with `perl sdk.pl --help`. Provide a short English and German description for user-visible changes.

Before submitting:

```sh
perl sdk.pl check
perl sdk.pl test
perl editor/vscode/pack_vsix.pl
```

For a toolchain/example change, also rebuild the affected libraries with the pinned tools and record output hashes, exact commands, compiler flags, unresolved symbols and validation scope. An instruction test, structural file test and native loader/application test are separate results.

An API declaration needs evidence for the actual 1.x ABI: module identity/protocol, ordinal, register or stack contract, object layout where relevant, and the exact original source or binary audit. A similar 2.x symbol name is insufficient. Do not add a native-runtime pass flag without a recorded target and observed actions.

Do not commit `.sdk-local/`, licensed runtime/SDK files, downloaded installers, credentials or personal test documents. Small original fixtures are acceptable when their provenance and purpose are explicit. Keep original target files unchanged and test only copies.

Deutsch: API-Ergänzungen benötigen Belege für die tatsächliche 1.x-Schnittstelle. Gleichnamige 2.x-Funktionen, erzeugte Dateien oder Host-Tests ersetzen keine Prüfung im ursprünglichen Laufzeitsystem. Private SDK-/Laufzeitdateien und fremde Installer dürfen nicht eingecheckt werden. Für Änderungen sind Dokumentation und Prüfstatus in beiden Sprachen anzupassen.
