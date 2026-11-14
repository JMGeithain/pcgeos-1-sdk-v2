# Gemeinsamer Sprachserver für Editoren

[English](README.md)

Perl ab Version 5.26 genügt; zusätzliche CPAN-Pakete sind nicht erforderlich.
Ein LSP-Client der IDE startet diesen Prozess mit stdin/stdout-Kommunikation:

```sh
perl /absoluter/pfad/pcgeos1-sdk/tools/lsp/server.pl --sdk-root /absoluter/pfad/pcgeos1-sdk
```

Die absoluten Pfade funktionieren unabhängig vom Arbeitsverzeichnis der IDE.
Im SDK-Hauptverzeichnis ist `perl tools/lsp/server.pl` gleichwertig. stdout enthält
ausschließlich JSON-RPC-Nachrichten mit `Content-Length`; Betriebsfehler erscheinen
auf stderr. Der Server führt weder Bauwerkzeuge noch Anwendungen oder Quelltexte aus.

Die [Anleitung für mehrere IDEs](../../docs/de/ide-integration.md) beschreibt die
Einrichtung. VS Code und andere Clients verwenden denselben Server. Ob eine
Funktion im Editor sichtbar ist, hängt auch vom jeweiligen LSP-Client ab.
Syntaxhervorhebung übernimmt weiterhin die Sprachgrammatik des Editors.

## Funktionen

| Funktion | Umfang |
| --- | --- |
| Vervollständigung | 8086-Mnemonik und Register, dialektspezifische Direktiven, Symbole im aktuellen Dokument, belegte numerische Ensemble-1.2-Konstanten |
| Hover | Beobachteter Zielwert, Registervertrag, Beleggrenzen und lokaler Link zur API-Referenz |
| Definition | Passende Symbole in geöffneten Dokumenten oder Konstantendefinition in `.h`, `.inc`, `.def` |
| Dokumentsymbole | Einfache Assemblerlabels, Prozeduren, Ressourcen, C-Funktionsdefinitionen und UI/GP-Deklarationen |
| Signaturhilfe | `KCALL E12_K_name` mit nativem Registervertrag; keine erfundenen C-Prototypen |
| Diagnosen | Begrenzte lexikalische CPU-Prüfungen und unbekannte `E12_K_`-Konstantennamen |

Sprachkennungen: `geos-esp`, `geos-nasm`, `geos-ui`, `geos-gp`, `geos-goc`, `c`,
`cpp`. Aliasse `esp`, `nasm`, `asm`, `ui`, `uic`, `gp`, `goc` werden akzeptiert.
Bei allgemeinen Kennungen dienen Dateiendung und Inhalt zur Erkennung.
ESPIRE/UIC verwendet einfache Schlüsselwörter wie `start`, `object`, `visMoniker`
und Semikolons als Anweisungsende. Der getrennte GOC-Dialekt nutzt `@`-Direktiven.
Kommentare und Zeichenketten werden vor lexikalischen Prüfungen ausgeblendet,
einschließlich Esp-`COMMENT`-Blöcken und NASM-Zeichenketten mit Backticks.

Die API-Daten stammen aus `targetprofiles/ensemble12-abi.json`; Referenzen liegen
unter `include/ensemble12/`. Sie beschreiben das bereitgestellte Ensemble 1.2 mit
Kernel 622.3/UI 693.0 und nicht sämtliche GEOS-1.x-Versionen. Bei einem bloßen
nativen API-Namen fügt die Vervollständigung die wirkliche Konstante mit
`E12_K_`, `E12_UI_` oder `E12_MSG_` ein. Dies sind Zahlenwerte, keine aufrufbaren
C-Hüllen. C-Anwendungen benötigen eine geprüfte Assemblerbrücke und die richtige
Aufrufkonvention des Zielsystems.

## Stapelprüfung für externe Werkzeuge

Dieselbe Prüfung lässt sich ohne LSP-Client aufrufen:

```sh
perl tools/lsp/server.pl --check examples/hello-asm/hello.nasm
perl tools/lsp/server.pl --check examples/math-c/checksum.c --format json
perl tools/lsp/server.pl --check source.inc --language geos-nasm
```

Textformat: `Pfad:Zeile:Spalte: Schweregrad: Meldung [Code]`; Zeilen und
UTF-16-Spalten beginnen bei eins. JSON verwendet LSP-Bereiche ab null. Rückgabecode
0 bedeutet keine Fehler, wobei Warnungen möglich sind. Code 1 steht für
lexikalische Fehler, Code 2 für Einrichtungs- oder Lesefehler. Nach `--check`
dürfen mehrere Dateipfade folgen.

Assemblerprüfungen melden spätere CPU-/Modusdirektiven und Register, eine
begrenzte Auswahl späterer Befehle wie `PUSHA`, numerisches unmittelbares `PUSH`
sowie konstante Schiebe-/Rotationszahlen größer eins. Makroexpansionen,
symbolische Ausdrücke, Operandentypen und sämtliche Befehlsformen werden nicht
analysiert. Unbekannte `E12_K_`-Namen führen zu einer Warnung über die begrenzte
Referenz; ihr Fehlen beweist nicht, dass die API nicht existiert. Private bloße
Aliasse werden nicht zurückgewiesen. C-Bezeichner gelten nicht als Assemblerbefehle.

Der Server ist kein Compiler, vollständiger Syntax-/Typprüfer, UIC-Ersatz,
allgemeiner Projektindex, Linker, CPU-Emulator oder API-Kompatibilitätsprüfer.
Zusätzlich sind echter Build, Objekt-/Geode-Prüfung und Tests auf dem Zielsystem
nötig. Keine Diagnose bedeutet nicht, dass der Quelltext baubar oder 8086-tauglich ist.

## Protokoll und Prüfung

Unterstützt werden initialize/serverInfo, shutdown/exit, Öffnen/Ändern/Schließen
von Dokumenten, Vervollständigung, Hover, Definition, documentSymbol,
signatureHelp und publishDiagnostics. Volltext-Synchronisation wird angekündigt;
korrekte inkrementelle Änderungen werden ebenfalls verarbeitet. Positionen und
Bereiche zählen UTF-16-Codeeinheiten, auch für Zeichen außerhalb der BMP.
Beim Schließen werden Diagnosen gelöscht.

```sh
prove -v tests/lsp/test_lsp.t
```

Die Tests steuern einen echten Subprozess über gerahmte Nachrichten für C,
NASM und Esp. Hinzu kommen Stapelprüfung, UTF-16-Änderungen, Kommentar-/Zeichenketten-
Behandlung und die Trennung von UI und GOC. Einrichtungsbeispiele bedeuten nicht,
dass jede genannte IDE in dieser Umgebung installiert und getestet wurde.
