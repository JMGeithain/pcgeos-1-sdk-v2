# Data-only TextMate bundle

Import `PCGEOS.tmbundle` through IntelliJ IDEA's **Settings → Editor → TextMate
Bundles**, or through another editor that accepts standard TextMate XML plist
grammars. This is a syntax-coloring bundle. LSP setup for completion, references
and source diagnostics is documented in the [English guide](../../docs/en/ide-integration.md)
and [German guide](../../docs/de/ide-integration.md).

`perl editor/build_textmate.pl` regenerates the bundle deterministically from
the original VS Code grammars. No third-party grammar or extension executable
is included. `fileTypes` prefers `.asm` for ESP and `.nasm` for NASM; when a
project uses `.asm` for NASM, select its language/dialect explicitly.

Deutsch: `PCGEOS.tmbundle` ist ein reines TextMate-Datenpaket für Syntaxfarben.
Es lässt sich in IntelliJ unter **Einstellungen → Editor → TextMate Bundles**
importieren. Vervollständigung und Diagnosen liefert der separat konfigurierte
LSP-Server. Bei mehrdeutigen `.asm`-Dateien den passenden Dialekt wählen.
