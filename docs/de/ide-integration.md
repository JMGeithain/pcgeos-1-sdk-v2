# IDE-Integration, Vervollständigung und API-Hilfe

[Handbuch](README.md) · [English](../en/ide-integration.md)

Das SDK liefert wiederverwendbare Syntaxgrammatiken und einen kleinen gemeinsamen Perl-Sprachserver. Editoren können damit Quelltext einfärben, Namen vorschlagen, die beobachteten Ensemble-1.2-Registerverträge anzeigen und ausgewählte Quellprobleme markieren. Der Server verwendet die Perl-Kernmodule. Er startet weder Compiler noch Emulator oder Anwendung.

## Umfang der einzelnen Integrationen

| IDE | Syntaxdateien | Vervollständigung, Hover und laufende Prüfung | Einrichtungsweg |
|---|---|---|---|
| Visual Studio Code | Installierbare VSIX, TextMate-Grammatiken und Snippets | Eigener Client startet den SDK-Server im vertrauenswürdigen Arbeitsbereich | VSIX installieren; SDK- und Perl-Pfade einstellen |
| IntelliJ IDEA und passende JetBrains-IDEs | TextMate-Bundle ohne ausführbaren Code | Benutzerdefinierter Server mit Red Hats LSP4IJ | Bundle importieren; Dateinamen zuordnen |
| Eclipse | Vorhandene JSON-Grammatiken über TM4E | LSP4E mit stdio-Startkonfiguration | Grammatik und Server demselben Textinhaltstyp zuordnen |
| Apache NetBeans | JSON-Grammatik über die Einstellungen für eigene Sprachen | Generischer LSP-Client | Pro Grammatik beziehungsweise Dialekt eine Sprache registrieren |
| Kate | Fünf KSyntaxHighlighting-XML-Dateien | Kate-LSP-Client | XML-Dateien installieren und JSON-Vorlage anpassen |
| KDevelop mit Kate-LSP-Unterstützung | Dieselben KDE-XML-Dateien | Kate-LSP-Integration, soweit mitgeliefert | Kate-Plugin installieren/aktivieren; dieselbe JSON-Konfiguration verwenden |
| Älteres KDevelop oder IDE ohne generischen LSP-Client | Passende Grammatik, soweit unterstützt | Wortvervollständigung und externe Stapelprüfungen | Die unten gezeigten Prüf-/Buildbefehle einrichten |

Protokoll, Referenzkatalog und Editorressourcen besitzen automatisierte Prüfungen. Die Anleitungen für weitere IDEs beruhen auf deren offizieller Dokumentation. Daraus folgt kein behaupteter interaktiver Installationstest jeder grafischen IDE und jeder Version. Ein von einem LSP-Client angebotenes Merkmal funktioniert nur, wenn es der SDK-Server tatsächlich implementiert.

## Sprachen und Dateizuordnung

| Dialekt | LSP-Sprachkennung | Übliche Dateien | JSON-Grammatik unter `editor/vscode/syntaxes/` |
|---|---|---|---|
| Esp-Objektassembler | `geos-esp` | `.esp`, `.gasm`, `.def`, `.asm` | `esp.tmLanguage.json` |
| NASM für flache Ressourcen | `geos-nasm` | `.nasm`; manche Projekte verwenden `.asm` | `nasm.tmLanguage.json` |
| Glue-Parameter | `geos-gp` | `.gp` | `gp.tmLanguage.json` |
| ESPIRE-/UIC-Deklarationen | `geos-ui` | `.ui`, `.uih` | `uic.tmLanguage.json` |
| GOC-Deklarationen | `geos-goc` | `.goc`, `.goh` | `goc.tmLanguage.json` |
| Freestanding C | `c` | `.c`, `.h` | Normale C-Hervorhebung des Editors verwenden |

`.asm` legt den Dialekt nicht fest. Ordnen Sie Esp-Bibliotheksquellen Esp und die flachen GUI-Ressourcen NASM zu. Wenn die IDE nur Dateiendungen zuordnen kann, wählen Sie einen Standard und verwenden Sie für den anderen Dialekt `.nasm`, soweit die Projektbeschreibung dies zulässt. Registrieren Sie nicht zwei konkurrierende automatische Zuordnungen für `.asm`.

Die Hervorhebung von GOC und UIC installiert keine historischen Übersetzer und macht spätere Deklarationen nicht unter 1.x verfügbar. Die Erkennung von C++-Dateien ist eine Editorhilfe; die ausgelieferten Zielbeispiele verwenden C, Assembler und deren überprüfte Kombination.

Behalten Sie für C die normale Syntaxhervorhebung der IDE bei. Falls der Client es unterstützt, können Sie zusätzlich eine Zuordnung der Sprachkennung `c` zum gemeinsamen SDK-Server einrichten. Die mitgelieferte KDE-JSON-Konfiguration deckt die fünf eigenen Dialekte ab und ersetzt keinen vorhandenen C-Sprachserver. KDevelops eigene C-Unterstützung kann beispielsweise die Konstanten in [abi.h](../../include/ensemble12/abi.h) erschließen; die Markdown-Referenz beschreibt die Registerverträge. Ein moderner C-Parser bestätigt keine korrekte 16-Bit-ABI.

## Gemeinsamer Sprachserver

Alle Clients starten denselben Prozess mit lokalen absoluten Pfaden:

```sh
/absolut/perl /absolut/sdk/tools/lsp/server.pl --sdk-root /absolut/sdk
```

Die Kommunikation läuft über Standardein- und -ausgabe. Wenn der Befehl in einem Terminal scheinbar wartet, ist dies normal: Der Client muss gerahmte LSP-Nachrichten schicken. Fügen Sie auf der Standardausgabe weder `echo`-Text noch eine Shell-Begrüßung ein.

Portable Startskripte stehen als [pcgeos-lsp.sh](../../editor/launchers/pcgeos-lsp.sh) und [pcgeos-lsp.cmd](../../editor/launchers/pcgeos-lsp.cmd) bereit. Die optionale Umgebungsvariable `PCGEOS_PERL` wählt genau einen Interpreter ohne zusätzliche Argumente. Verwenden Sie Perl ab Version 5.26. Falls ein Archiv beim Entpacken das Ausführungsrecht entfernt hat, führen Sie auf POSIX-Systemen `chmod +x editor/launchers/pcgeos-lsp.sh` aus.

IDE und Server müssen dieselben Dateipfade sehen. Eine Windows-IDE kann den Server mit nativem Windows-Perl ausführen, während ein getrenntes WSL-Terminal die Builds erledigt. VS Code Remote WSL kann stattdessen sowohl Editordienste als auch Perl in WSL starten. Eine beliebige Verbindung über diese Grenze übersetzt Windows-Dokument-URIs nicht automatisch in Linux-Pfade.

### Gelieferte Referenzen und Prüfungen

Der Katalog liegt unter [targetprofiles/ensemble12-abi.json](../../targetprofiles/ensemble12-abi.json). Er beschreibt den begrenzten beobachteten Zielumfang mit Kernel 622.3 und UI 693.0. Lesbare Referenzen stehen auf [Englisch](../../include/ensemble12/API-EN.md) und [Deutsch](../../include/ensemble12/API-DE.md) bereit. Sie enthalten konkrete numerische Werte und Registerverträge, keine vollständige aufrufbare C-System-API.

Die Vervollständigung umfasst kuratierte Kernelkonstanten `E12_K_...`, UI-Klassen und Nachrichten, 8086-Mnemonik/Register, Dialektdirektiven und einfache lokale Symbole. Hover-Hinweise verweisen auf die lokale Referenz. Definitionen und Dokumentgliederung sind bewusst klein und dokumentbezogen. Parameterhilfe beschreibt die erfassten Registerverträge; sie leitet weder sämtliche erhaltenen Register her noch wandelt sie einen C-Aufruf in die native GEOS-Aufrufkonvention um.

Die laufende Prüfung markiert ausgewählte Konstrukte späterer CPUs, offensichtliche nicht unterstützte Operandenformen und Verweise außerhalb des kuratierten Konstantensatzes. Ein unbekanntes `E12_K_...`-Symbol bedeutet, dass der Katalog den Eintrag nicht enthält. Es bedeutet nicht, dass der echte Kernel keine entsprechende Funktion besitzt. Diese lexikalische Hilfe ist kein vollständiger Assembler, Makroexpander, C-Typprüfer oder Nachweis für 8086-/Runtime-Korrektheit. Bauen und testen Sie mit den tatsächlichen Zielwerkzeugen.

## Visual Studio Code

Installieren Sie die VSIX aus [editor/dist](../../editor/dist/) über **Extensions → Install from VSIX** oder mit `code --install-extension <pfad-zur-vsix>`. Öffnen Sie SDK oder Projekt, geben Sie den Arbeitsbereich bei entsprechender Vertrauenswürdigkeit frei und wählen Sie den passenden Sprachmodus. Die Einstellungen lauten:

```json
{
  "pcgeos1.sdkRoot": "/absolut/sdk",
  "pcgeos1.perlExecutable": "/absolut/perl",
  "pcgeos1.enableLanguageServer": true
}
```

Ein leerer `sdkRoot` sucht in geöffneten Arbeitsbereichsordnern nach `tools/lsp/server.pl`. Der Perl-Wert ist ein ausführbarer Programmpfad, kein Befehl mit Argumenten. Nutzen Sie nach einer Änderung **PC/GEOS: Restart Language Server** und zum Öffnen der Referenz den Befehl **PC/GEOS: Open Ensemble 1.2 API Reference**. Der Client startet nur in einem vertrauenswürdigen Arbeitsbereich. Eine Installation von npm-Abhängigkeiten ist nicht erforderlich. Weitere Aufgaben und Details stehen in der [Erweiterungsanleitung](../../editor/vscode/README-DE.md).

## IntelliJ IDEA und passende JetBrains-IDEs

Aktivieren Sie **TextMate Bundles** und importieren Sie [editor/textmate/PCGEOS.tmbundle](../../editor/textmate/README.md) unter **Settings → Editor → TextMate Bundles**. Die Syntaxfarben funktionieren unabhängig von LSP. JetBrains akzeptiert auch passende VS-Code-Grammatikverzeichnisse.

Installieren Sie Red Hats Plugin **LSP4IJ**. Legen Sie in dessen Sprachservereinstellungen einen benutzerdefinierten Server namens `PC/GEOS` an. Verwenden Sie den gemeinsamen Perl-Befehl von oben und stdio als Transport. Ergänzen Sie unter **Mappings** Dateinamenmuster und die Sprachkennungen aus der Tabelle. Dateinamenzuordnungen sind hier zweckmäßiger als eigene Dateitypen, die TextMate die Syntaxhervorhebung entziehen könnten. Ordnen Sie `.asm` dem Dialekt des jeweiligen Projekts zu. Installations-, Debug- und Socketfelder bleiben unbenutzt: Der Server ist bereits im SDK vorhanden und dient der Quelltextunterstützung.

Primärquellen: [JetBrains-TextMate-Einrichtung](https://www.jetbrains.com/help/idea/textmate.html), [benutzerdefinierte LSP4IJ-Server](https://github.com/redhat-developer/lsp4ij/blob/main/docs/UserDefinedLanguageServer.md).

## Eclipse

Installieren Sie **TM4E** und **LSP4E**, falls die Eclipse-Ausgabe diese Komponenten nicht enthält. Importieren Sie unter **Preferences → TextMate → Grammar** die passende JSON-Grammatik und verknüpfen Sie sie mit einem Textinhaltstyp samt gewünschten Dateinamen. Derselbe Inhaltstyp muss auch für LSP verwendet werden.

Erstellen Sie eine Startkonfiguration für ein externes Programm. Als ausführbares Programm wählen Sie Perl, als Argumente `/absolut/sdk/tools/lsp/server.pl --sdk-root /absolut/sdk`. Ordnen Sie diese Konfiguration unter **Preferences → Language Servers** dem Inhaltstyp zu. Öffnen Sie die Datei mit **Open With → Generic Editor**. Wiederholen Sie dies für weitere Dialekte. In TM4Es Bereich **Language Configuration** können die passenden Bearbeitungsregeln aus `language-configuration-*.json` importiert werden.

Dies ist LSP4Es dokumentierter Konfigurationsweg, kein bereits installiertes eigenes Eclipse-Produktplugin. Siehe [LSP4E-Konfiguration](https://github.com/eclipse-lsp4e/lsp4e/blob/main/documentation/using-language-server-via-configuration-no-code.md) und [TM4E-Handbuch](https://github.com/eclipse-tm4e/tm4e/blob/main/docs/user-guide.md).

## Apache NetBeans

Verwenden Sie **Tools → Options → Editor → Language Servers → Add** in einer Ausgabe mit dem generischen LSP-Client. Der Dialog für eigene Sprachen ist bereits im NetBeans-25-Quelltext vorhanden; neuere Versionen können zusätzliche Felder anbieten.

Tragen Sie einen Namen, durch Leerzeichen getrennte Dateiendungen **ohne führenden Punkt**, den JSON-Grammatikpfad und den gemeinsamen Serverbefehl ein. Falls der Dialog **Language Identifier** anbietet, verwenden Sie die Kennung aus der Tabelle. Andernfalls kann der Server den Dialekt anhand von Dateiname/Inhalt erkennen. Für NASM ist beispielsweise `nasm` die Endung und `nasm.tmLanguage.json` die Grammatik. Wiederholen Sie den Vorgang für die anderen Dialekte.

Der untersuchte Client speichert den Befehl durch Aufteilung an Leerzeichen. Bei Pfaden mit Leerzeichen setzen Sie das Feld **Language Server** deshalb auf einen einzigen Startskriptpfad ohne Leerzeichen. Dieses Skript kann seinerseits die Perl-/SDK-Pfade korrekt quotieren. Lassen Sie **Enable Breakpoints** deaktiviert: Dieser Sprachserver debuggt keine GEOS-Programme.

Primärquellen: [Quelltext des Sprachen-Dialogs](https://github.com/apache/netbeans/blob/25/ide/lsp.client/src/org/netbeans/modules/lsp/client/options/LanguageDescriptionPanel.java), [aktuelle Speicherung und Befehlsverarbeitung](https://github.com/apache/netbeans/blob/master/ide/lsp.client/src/org/netbeans/modules/lsp/client/options/LanguageStorage.java), [Apache-LSP-Übersicht](https://cwiki.apache.org/confluence/spaces/NETBEANS/pages/263425900/Using+Language+Server+Protocol+LSP).

## Kate und KDevelop

Installieren Sie die fünf XML-Dateien aus [editor/kate](../../editor/kate/README.md), starten Sie den Editor neu und wählen Sie `PC/GEOS ESP`, `PC/GEOS NASM`, `PC/GEOS GP`, `PC/GEOS UI` oder `PC/GEOS GOC`. Der übliche Linux-Benutzerpfad lautet `~/.local/share/org.kde.syntax-highlighting/syntax/`. Abgeschottete Pakete und andere Betriebssysteme verwenden die in der offiziellen KDE-Dokumentation genannten Pfade.

Aktivieren Sie **LSP Client**. Ersetzen Sie alle Platzhalter `/absolute/perl` und `/absolute/sdk` in `lsp-servers.json` und übernehmen Sie die Konfiguration in **User Server Settings**. Neuere Plugins verwenden für jede Sprache ein verschachteltes `servers`-Objekt; ältere Versionen verwenden die direkten `command`-Einträge aus `lsp-servers-legacy.json`. Vergleichen Sie das Format mit der Standardkonfiguration des installierten Plugins und verwenden Sie genau eine Variante.

KDevelop erhielt die Kate-LSP-Integration mit KDE Gear 25.04; zunächst musste Kate dafür zusätzlich installiert sein. Die Verfügbarkeit hängt von der Plugin-Paketierung der Distribution ab. Fehlen die LSP-Einstellungen, verwenden Sie Syntaxdateien und externe Prüfungen oder Kate neben KDevelop. Die vorhandene Clang-C/C++-Unterstützung prüft keine Watcom-/GEOS-ABI.

Primärquellen: [KDE-Syntaxpfade](https://docs.kde.org/stable_kf6/en/kate/katepart/highlight.html), [Kate-LSP-Konfiguration](https://docs.kde.org/stable_kf6/en/kate/kate/kate-application-plugin-lspclient.html), [Ankündigung der KDevelop-Integration](https://blogs.kde.org/2025/03/09/this-week-in-kde-apps/), [externe KDevelop-Skripte](https://dot.kde.org/2010/10/26/kdevelop-41-brings-git-integration/).

## Stapelprüfungen und Buildaufgaben in jeder IDE

Dieselben Quellmeldungen können als externes Werkzeug ausgegeben werden:

```sh
perl tools/lsp/server.pl --sdk-root . --check pfad/zur/quelle.nasm --format text
perl tools/lsp/server.pl --sdk-root . --check pfad/zur/quelle.asm --language geos-nasm --format json
perl sdk.pl check
perl sdk.pl build --project examples/math-asm
```

Die Textausgabe verwendet `Datei:Zeile:Spalte: Schweregrad: Meldung` mit bei eins beginnenden Anzeigepositionen. JSON behält die LSP-Bereiche bei. Fehlerdiagnosen liefern Exitstatus 1, ausschließlich Warnungen Status 0; ein Eingabe-/Einrichtungsfehler liefert Status 2. Speichern Sie Quelldateien vor Stapelprüfung und Build. Hinterlegen Sie diese Befehle unter **External Tools**, **External Scripts** oder einem Projekt-Buildziel mit dem SDK-Stamm als Arbeitsverzeichnis. Der laufende Server prüft auch ungespeicherte Editorpuffer; der Build liest die Dateien auf der Festplatte.

Prüfen Sie die Verbindung durch Vervollständigung von `E12_K_Mem`, einen Hover über `E12_K_MemAlloc` und ein eingefügtes `pusha` in einer temporären Assemblerdatei. Die Meldung zu einer späteren CPU sollte erscheinen. Entfernen Sie danach die Testanweisung. Falls nichts geschieht, prüfen Sie zuerst Sprachmodus, Perl-Pfad, API-Katalog und Serverlog des Clients.
