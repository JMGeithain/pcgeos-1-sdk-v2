# Kate and KDevelop assets

[English IDE guide](../../docs/en/ide-integration.md) ·
[Deutsche IDE-Anleitung](../../docs/de/ide-integration.md)

The five original MIT-licensed XML files use KDE's KSyntaxHighlighting format.
They supply ESP, NASM, GP, UIC and GOC colors, not a compiler or parser for the
complete GEOS language. The XML was checked against KDE's current schema;
actual IDE rendering is not part of that check.

Copy `pcgeos-*.xml` to your user syntax directory, usually
`~/.local/share/org.kde.syntax-highlighting/syntax/`, then restart the editor.
Select the required `PC/GEOS ...` mode. NASM and ESP share `.asm`; choose the
dialect explicitly for such files. Flatpak, Snap, Windows and macOS use other
data directories listed in the official [KDE instructions](https://docs.kde.org/stable_kf6/en/kate/katepart/highlight.html).

`lsp-servers.json` is the current nested-server configuration;
`lsp-servers-legacy.json` is for older Kate LSP plugins with direct `command`
entries. Replace `/absolute/perl` and `/absolute/sdk` with local absolute
paths before pasting the appropriate JSON into LSP Client's User Server
Settings. Match the format shown by the installed plugin's defaults. Do not
merge both variants. Recent KDevelop can reuse Kate's LSP plugin when installed.

Deutsch: Die XML-Dateien liefern Syntaxfarben. Sie wurden gegen das aktuelle
KDE-Schema geprüft; ein tatsächlicher IDE-Test ist davon getrennt. Dateien in
den persönlichen Syntaxordner kopieren und den Editor neu starten. Bei `.asm`
den Dialekt ausdrücklich wählen. Für den Sprachserver alle absoluten
Platzhalter ersetzen und genau die zum installierten LSP-Plugin passende
JSON-Variante verwenden. Die vollständige Anleitung ist oben verlinkt.
