# PC/GEOS-Sprachunterstützung für Visual Studio Code

[English](README.md)

Diese Erweiterung bietet TextMate-Syntaxhervorhebung, Kommentarbefehle,
Faltung, Klammerpaare und strukturelle Snippets. Ein optionaler eigener
JavaScript-Client startet zusätzlich den lokalen Perl-Sprachserver des SDK
für API-Vervollständigung, Hover-Hinweise und begrenzte Quellprüfungen. Der
Server startet nur in einem als vertrauenswürdig freigegebenen Arbeitsbereich.

| Sprachmodus | Dateien | Kommentare |
|---|---|---|
| PC/GEOS ESP | `.asm`, `.esp`, `.gasm`, `.def` | `;` und ESP-`COMMENT`-Blöcke |
| PC/GEOS NASM | `.nasm` | `;` |
| PC/GEOS ESPIRE/UIC | `.ui`, `.uih` | `/* ... */`, `//` |
| PC/GEOS Glue-Parameter | `.gp` | `#` |
| PC/GEOS GOC | `.goc`, `.goh` | C-Kommentare; C und eingebettetes Assembler |

Ein Semikolon **beendet in ESPIRE eine Anweisung**. Es leitet dort keinen
Kommentar ein. In ESP beginnt damit dagegen ein Kommentar.

Syntaxfarben sind **keine Prüfung der API oder Binärkompatibilität**. Auch
GOC-Schlüsselwörter und spätere x86-Register werden zum Lesen vorhandener Quellen
erkannt. Dadurch werden weder spätere APIs und Header noch GOC-Objektdefinitionen
oder neuere Prozessorbefehle unter PC/GEOS 1.x verfügbar. Maßgeblich sind das
gewählte Zielprofil und die Compilerprüfungen. Die Snippets sind unvollständige
Strukturvorlagen, keine geprüften Anwendungen. Die Erweiterung enthält keinen Compiler, nativen Debugger oder Emulator. Der
Sprachserver gehört zum SDK-Quellbaum; die VSIX enthält den kleinen Client und
die Editorressourcen. Sie übersetzt und startet keine GEOS-Anwendung.

## Installation

Im Stammverzeichnis des SDK-Repositories mit Perl ab Version 5.26 ausführen:

```sh
perl editor/vscode/pack_vsix.pl
```

Unter Windows ist auch `perl editor/vscode/pack_vsix.pl` möglich. Es entsteht
`editor/dist/pcgeos1-language-support-0.2.0.vsix`. In der Befehlspalette **Extensions: Install
from VSIX...** auswählen oder die VS-Code-Kommandozeile verwenden:

```sh
code --install-extension editor/dist/pcgeos1-language-support-0.2.0.vsix
```

VS Code bei Aufforderung neu laden. Für dieses lokale Paket werden weder eine gesonderte Node.js-Installation,
npm-Downloads noch ein Marketplace-Konto benötigt. Der Client verwendet die
Node-Laufzeit der VS-Code-Erweiterungshostumgebung. Der Paketbau ist reproduzierbar.
Die Tests prüfen ZIP-Metadaten und enthaltene Dateien; ein Installationstest in
einer echten VS-Code-Instanz ist eine separate Prüfung.

Zur Entwicklung `editor/vscode` öffnen und eine installierte Kopie nach Änderungen
über **Developer: Reload Window** neu laden. Alternativ im Repository-Stamm
`code --extensionDevelopmentPath=editor/vscode` starten. Das prüft die
Editorerweiterung, nicht die Ausführung eines GEOS-Programms.

## SDK-Arbeitsbereich einrichten

Den **SDK-Repository-Stamm** als Arbeitsbereich öffnen. Die JSON-Dateien aus
`editor/vscode/templates/` nach `.vscode/` übernehmen. Vorhandene Einstellungen
zusammenführen, nicht unbesehen überschreiben. `pcgeos1.perlExecutable` auf den
Perl-Interpreter ab Version 5.26 setzen:

| Betriebssystem | Typischer Wert |
|---|---|
| Linux | `perl` oder absoluter Interpreterpfad |
| macOS | `perl` oder absoluter Interpreterpfad |
| Windows | `perl` oder vollständiger Pfad zu `perl.exe` |

Hier nur einen Programmpfad ohne zusätzliche Argumente wie `-w` eintragen. Stattdessen `perl.exe` angeben oder Befehl und Argumentliste des
Tasks ausdrücklich anpassen. Pfade mit Leerzeichen werden als Prozessargumente
weitergegeben.

Für die Sprachserververbindung können Sie außerdem `pcgeos1.sdkRoot` auf den
**absoluten** SDK-Ordner setzen, der `tools/lsp/server.pl` enthält. Bleibt der
Wert leer, erkennt die Erweiterung einen passenden SDK-Arbeitsbereich selbst.
`pcgeos1.enableLanguageServer` ist standardmäßig `true`; `false` schaltet den
Server ab und lässt die Syntaxhervorhebung bestehen. Der Standardwert für
`pcgeos1.perlExecutable` lautet `perl`; wählen Sie gegebenenfalls den vollständigen Perl-5.26+-Pfad im verwendeten Remote-Kontext.

Die optionalen Tasks rufen im Repository-Stamm `sdk.pl doctor`, `sdk.pl check`, `sdk.pl test`
und `sdk.pl build --project <Projekt>` auf. `pcgeos1.project` auf ein vorhandenes
SDK-Projekt setzen und **Tasks: Run Task** verwenden. Die Vorlagen sind Beispiele;
bei geänderten Optionen gilt die aktuelle SDK-Kommandozeile. Kein Task wird
automatisch gestartet. Zum Ausführen ist ein geeigneter vertrauenswürdiger
Arbeitsbereich erforderlich.

Die Endungen `.asm`, `.def` und `.gp` werden auch von anderen Werkzeugen verwendet.
Bei Bedarf **Change Language Mode** wählen. Arbeitsbereichsspezifische
`files.associations` begrenzen die Zuordnung. `.c` und `.h` bleiben im normalen
C-Modus. Eine optionale C/C++-Erweiterung kann die Navigation verbessern; ihre
Host-Datentypgrößen belegen jedoch keine korrekte 16-Bit-GEOS-ABI.

## Vervollständigung, Hover und Meldungen

1. Öffnen Sie den SDK-Stamm oder konfigurieren Sie `pcgeos1.sdkRoot`.
2. Verwenden Sie den Interpreter der Buildumgebung. Bei WSL/Remote-Verbindung
   muss er dort vorhanden sein; ein lokaler Windows-Pfad funktioniert im
   Linux-Erweiterungshost nicht automatisch.
3. Öffnen Sie eine `.nasm`-, `.asm`-, `.gp`-, `.goc`- oder C-Datei. Geben Sie
   beispielsweise einen Teil eines bekannten `E12_`-Symbols ein und rufen Sie
   bei Bedarf **Trigger Suggest** auf.
4. Bewegen Sie den Zeiger über ein bekanntes ABI-Symbol. Der Hovertext nennt
   die gespeicherte Beschreibung beziehungsweise ihren Zielbezug.
5. Nutzen Sie bei Problemen **PC/GEOS: Restart Language Server**.
   **PC/GEOS: Open Ensemble 1.2 API Reference** öffnet die lokale Referenz.

Die Meldungen sind begrenzte statische Hilfen, keine vollständige Syntax- oder
Typprüfung für Esp, GOC oder NASM. Vervollständigung bietet nur den erfassten
Schnittstellenausschnitt. Sie beweist weder einen System-C-Wrapper noch korrekte
Registernutzung, Ressourcenlebensdauer, einen vollständigen 8086-Audit oder
native Laufzeitkompatibilität. Compiler, Formatprüfung und Zieltests bleiben
getrennte Schritte. C/C++-Navigation einer zusätzlichen Erweiterung muss
weiterhin ihre Host-Typannahmen von der 16-Bit-Ziel-ABI unterscheiden.

Im eingeschränkten, nicht vertrauenswürdigen Arbeitsbereich bleiben die
deklarativen Editorfunktionen verfügbar; der lokale Perl-Prozess wird dort
nicht gestartet. Weitere IDEs und das gemeinsame Serverprotokoll behandelt
[IDE-Integration](../../docs/de/ide-integration.md).

## Snippets und Kontrolle

Über **Insert Snippet** oder die Präfixe `geos-proc`, `geos-method`, `geos-class`,
`geos-ui-resource`, `geos-ui-object`, `geos-gp-name`, `geos-gp-resource`,
`geos-goc-method` und `geos-goc-resource` einfügen. Zielspezifische Definitionen
ergänzen und jeden Register-/Stack-Vertrag dokumentieren.

Mit **Developer: Inspect Editor Tokens and Scopes** die erkannten Bereiche prüfen.
Die Erweiterung verwendet übliche TextMate-Scopes. Die Farben bestimmt das
eingestellte Theme; die Erweiterung ändert es nicht.

## Veröffentlichung

`pcgeos1-community` ist eine lokale Paketkennung und keine Behauptung, ein
Marketplace-Konto zu besitzen. Für eine Marketplace-Veröffentlichung einen
eigenen Publisher wählen und die aktuellen Bedingungen des Dienstes beachten.
Die VSIX-Datei kann ohne Marketplace über GitHub Releases verteilt werden.
Eigene Grammatik, Snippets, Konfiguration, Paketwerkzeug und Dokumentation stehen
unter MIT-Lizenz. Microsoft-Schriften, proprietäre SDK-Binärdateien oder fremde
Erweiterungsgrammatiken sind nicht enthalten.

## Primärquellen

- [VS-Code-Erweiterungsmanifest](https://code.visualstudio.com/api/references/extension-manifest)
- [Syntaxhervorhebung](https://code.visualstudio.com/api/language-extensions/syntax-highlight-guide)
- [Contribution Points](https://code.visualstudio.com/api/references/contribution-points)
- [Snippets](https://code.visualstudio.com/api/language-extensions/snippet-guide)
- [Offizielles GEOS-Hello-UI-Beispiel](https://github.com/bluewaysw/pcgeos/blob/master/Appl/SDK_Asm/Hello/hello.ui): spätere Referenz für ESPIRE-Syntax, kein Nachweis einer 1.x-API
