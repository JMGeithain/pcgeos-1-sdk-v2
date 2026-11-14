# Werkzeugkette, Compiler und Dateiformate

[Handbuch](README.md) · [English](../en/toolchain.md)

Eine GEOS-Werkzeugkette besteht aus mehreren Übersetzungsschritten. Für einen funktionierenden 1.x-Build müssen Werkzeuge, Includes, Importdaten, Ziel-ABI und Ressourcenformat zusammenpassen. „16-Bit“ allein ist dafür keine ausreichende Spezifikation.

## Aufgaben der Werkzeuge

| Bestandteil | Aufgabe | Häufiges Missverständnis |
|---|---|---|
| C-Compiler | C in Zielcode beziehungsweise ein unterstütztes Objektformat übersetzen | Ein Host-GCC erzeugt mit gewöhnlichen Optionen kein GEOS-Geode |
| GOC | GEOS-spezifische C-/Objektbeschreibung für eine unterstützte C-Werkzeugkette aufbereiten | GOC ersetzt nicht den eigentlichen C-Compiler |
| NASM | Flachen 8086-Code und explizite Metadaten für den `ensemble12`-Adapter erzeugen | NASM ersetzt weder Esp-Objekte noch eine allgemeine UI-Übersetzung |
| Esp | GEOS-Assembler mit eigenen Objekt-, Ressourcen- und Methodenkonstrukten | Esp-Quellcode ist kein unverändertes NASM-Programm |
| UI-Übersetzung | Deklarative UI-Beschreibungen in die vom Buildsystem erwarteten Daten umsetzen | Eine UI-Datei ist keine ausführbare Anwendung |
| Linker/Geode-Erzeugung | Code, Daten, Ressourcen, Exporte und Relokationen verbinden | Eine neuere Geode-Ausgabe ist nicht automatisch vom alten Loader lesbar |
| Buildsteuerung | Reihenfolge, Optionen und Abhängigkeiten festlegen | `pmake` oder ein Perl-Skript ist selbst kein C-Compiler |
| Debugger und Zieltransport | Native Ausführung untersuchen beziehungsweise Dateien übertragen | Eine erfolgreiche Dateiübertragung ist noch kein Laufzeittest |

Die öffentliche [Werkzeugdokumentation](https://bluewaysw.github.io/pcgeos/tools.html) beschreibt die Rollen der GEOS-Werkzeuge. Ihre Optionen müssen für die tatsächlich verwendete Version geprüft werden.

## Der begrenzte Bibliotheks-Buildpfad dieses Repositorys

Die drei Mathematikbeispiele verwenden importfreie 16-Bit-Bibliotheken. Der festgelegte Hostpfad kombiniert den Esp-Release-1-Pfad mit einem überprüften Glue-Release-1-Pfad und dessen im Repository dokumentierter Korrektur. Der C-Anteil wird mit dem 16-Bit-Compiler `wcc` von Open Watcom übersetzt. `wcc386` ist ein anderes Werkzeug und darf nicht als Ersatz für den Ziel-C-Compiler gewählt werden.

Das [Open-Watcom-Lockfile](../../toolchains/open-watcom.lock.json) erfasst Herkunft, Linux/x86-64-Host, Version und Hash des konkreten Pakets. `perl sdk.pl toolchain install` führt den vom Repository vorgesehenen Abruf aus. Es enthält keine allgemeine Zusage für den unveränderten Watcom-DOS-CRT, moderne GEOS-C-Wrapper oder sämtliche Systemaufrufe unter 1.x.

Für den kleinen freestanding C-Pfad gehören folgende Optionen zum zu prüfenden Vertrag; maßgeblich bleibt die tatsächlich protokollierte Befehlszeile:

| Option | Bedeutung im Beispielpfad |
|---|---|
| `-0` | Codeerzeugung für 8086/8088 |
| `-ms` | Kleines Speichermodell; die öffentliche Funktion wird ausdrücklich als `far` deklariert |
| `-zu` | Nicht voraussetzen, dass `SS` auf das eigene `DGROUP` zeigt |
| `-s` | Compiler-Stapelprüfaufrufe weglassen; eigenen Stapelbedarf prüfen |
| `-zl` | Keine gewöhnlichen Standardbibliotheksnamen in die Objektdatei einfügen |
| `-zld` | Compiler-Dateiabhängigkeitsmetadaten für diesen Linkpfad unterdrücken |

Die Optionen sind keine universelle Vorlage für jede C-Anwendung. Insbesondere können weitergehende Sprachkonstrukte trotzdem Hilfsroutinen benötigen. Der [Watcom-C-Leitfaden](https://open-watcom.github.io/open-watcom-v2-wikidocs/cguide.html) beschreibt diese Schalter; das GEOS-Zielprofil bestimmt ihre Verwendung.

## C-Compiler bewusst auswählen

Die moderne FreeGEOS-Quelle verwendet eine Watcom-Werkzeugkette für C-Anteile. Das belegt die aktuelle Quelle, aber keine unveränderte 1.x-C-Unterstützung. Ein vorhandener historischer Compiler kann ebenfalls geeignet sein, wenn das konkrete Profil dessen Datenmodell, Objektformat und Laufzeit nachweist.

Ein C-Profil muss folgende Fragen beantworten:

- Werden 16-Bit-x86-Objekte im erwarteten Format erzeugt?
- Sind `near`- und `far`-Zeiger sowie Funktionen mit den erforderlichen Aufrufkonventionen darstellbar?
- Wie werden externe Symbole dekoriert?
- Wie werden Argumente und Rückgabewerte übergeben, und wer bereinigt den Stapel?
- Welche Hilfsroutinen erzeugt der Compiler für Division, lange Ganzzahlen, Strukturkopien oder Gleitkomma?
- Werden diese Routinen mitgeliefert und sind sie für den Zielprozessor sowie für bewegliche GEOS-Ressourcen geeignet?
- Welche Startdateien und Initialisierungsregeln sind tatsächlich erforderlich?

Ohne diese Antworten ist ein `hello.c` möglicherweise ein gültiges DOS- oder Hostprogramm, jedoch keine native GEOS-Anwendung. Verlinken Sie insbesondere nicht versehentlich eine gewöhnliche DOS-C-Laufzeit mit Annahmen über einen eigenen Prozessstart, `malloc`, Dateideskriptoren oder Terminalausgabe.

## Esp und gewöhnliche Assembler unterscheiden

Esp unterstützt GEOS-spezifische Konstrukte, die neben Maschinenbefehlen auch Metadaten ausdrücken. Ein herkömmlicher Assembler kann für einen eng definierten Codeblock sinnvoll sein. Er ersetzt damit nicht automatisch Esp, den UI-Übersetzer, Klassenbeschreibungen oder den Geode-Linker.

Wählen Sie nur eine der tatsächlich unterstützten Routen des Profils:

1. Originale beziehungsweise nachgewiesen kompatible GEOS-Werkzeugkette mit den passenden Includes.
2. Ein ausdrücklich dokumentierter alternativer Übersetzungsweg mit eigenem Format- und ABI-Nachweis.
3. Reine Hosttests für einen betriebssystemunabhängigen Rechenkern.

Mischen Sie nicht unbemerkt Objektdateien verschiedener Formate. Eine Datei mit `.obj` oder `.o` benennt das Format nicht eindeutig. Auch eine flache Binärdatei besitzt noch keine Informationen über bewegliche Ressourcen oder dynamische Bibliotheksaufrufe.

## Reproduzierbarer Build

Für jede freizugebende Ausgabe sollten Sie speichern:

| Angabe | Zweck |
|---|---|
| Projekt-Commit und unveränderte Eingabedateien | Quellstand eindeutig zuordnen |
| Werkzeugversionen und Hashes | Unbeabsichtigten Werkzeugwechsel erkennen |
| Vollständige Optionen und Zielprofil | CPU, ABI und Includeauswahl nachvollziehen |
| Erzeugte Imports/Exporte und Ressourcenübersicht | Native Struktur vor dem Start prüfen |
| Hash der Zielbinärdatei | Test und ausgelieferten Build verbinden |
| Build- und Testergebnisse | Erfolgreiche und übersprungene Schritte auseinanderhalten |

Ein sinnvoller Build scheitert deutlich, wenn eine notwendige Abhängigkeit fehlt. Er sollte nicht stillschweigend einen modernen Headerordner auswählen, eine Protokollprüfung entfernen oder eine native Prüfung als Hosttest ausgeben.

## Werkzeuginstallation sauber halten

Installieren Sie Fremdwerkzeuge in einen eigenen Ordner. Nehmen Sie keine nicht dokumentierten globalen Änderungen an `PATH`, System-Includes oder Compiler-Startdateien vor. Bevorzugen Sie projektbezogene Konfigurationen und explizite Versionen.

Bewahren Sie originale Lizenz- und Herkunftshinweise auf. Manche Werkzeuge dürfen als Quellcode weitergegeben werden, während andere Installationsdateien oder historische SDK-Inhalte gesonderten Bedingungen unterliegen. Ein GitHub-Repository sollte für nicht mitgelieferte Bestandteile Beschaffungs- und Prüfhinweise bereitstellen, statt sie ungeprüft einzupacken.


## Eigene Werkzeugpfade konfigurieren

Wenn Sie die passenden Programme bereits installiert haben, kann die lokale Konfiguration statt eines erneuten Abrufs verwendet werden. Ersetzen Sie die Beispielpfade durch tatsächlich vorhandene Dateien:

```sh
perl sdk.pl configure --esp /pfad/zu/esp --glue /pfad/zu/glue
perl sdk.pl configure --nasm /pfad/zu/nasm
perl sdk.pl configure --wcc /pfad/zu/wcc --wdis /pfad/zu/wdis --watcom-root /pfad/zu/watcom
perl sdk.pl doctor
```

Die Einstellungen landen in `.sdk-local.json`, die nicht in Git gehört. Ein erfolgreicher Pfadtest bedeutet nur, dass eine Datei gefunden wurde. Erst ein erfolgreicher Werkzeuglauf zeigt, ob ihr Betriebssystem- und CPU-Format zum Host passt.

Für einen gegebenenfalls nötigen Linux-i386-Ausführungspfad existiert `configure --i386-runner /pfad/zu/qemu-i386`. Der Wert ist ein Programmpfad, keine frei zusammengesetzte Shell-Befehlszeile. Nutzen Sie ihn nur für den dokumentierten Hostpfad. Er ist kein DOS-Emulator und kein 8086-Zieltest.

Der tatsächliche C-Beispielaufruf setzt außerdem `-ecc` für die C-Aufrufkonvention sowie die Segment-/Klassennamen `-nt=ALGORITHM` und `-nc=CODE`. Diese Anordnung gehört zu den gelieferten skalaren, importfreien Beispielen. Übernehmen Sie sie nicht als Versprechen, dass globale Daten, Standard-C-Laufzeit oder beliebige System-C-Aufrufe damit funktionieren.

Die Umgebungsvariablen `GEOS1_ESP`, `GEOS1_GLUE`, `GEOS1_WCC` und `GEOS1_WDIS` können Werkzeugpfade überschreiben. `WATCOM` bezeichnet bei diesem Pfad die Watcom-Installation. Dokumentieren Sie solche Überschreibungen im Buildbericht und prüfen Sie die Ausgabe von `doctor`, damit nicht unbeabsichtigt ein anderes Programm aus dem allgemeinen `PATH` verwendet wird.

## Festgelegter Host-Build der GEOS-Werkzeuge

Der geprüfte Quellstand der wiederhergestellten Werkzeuge ist `260b33dcfcac15b7ecfdf04242cb0abf029ec269`. Der Bootstrap baut 98 ausgewählte C-Dateien der Dienstbibliotheken, des Assemblers und des Linkers. Er verwendet dafür die Linux-Hostwerkzeuge von Watcom, Linux-Header und die im Patch dokumentierten historischen Annahmen, unter anderem `-zp=1`, `-ei` und `-j`. Das Ergebnis sind statische 32-Bit-Linux-ELF-**Hostprogramme**. Sie sind keine 16-Bit-Zielprogramme und laufen nicht als native macOS-Anwendungen.

Der Zielpfad ruft Esp mit `-R 1` auf. Glue erhält für die Bibliotheksbeispiele ausdrücklich `-G 1`, die Parameterdatei über `-Og`, den Bibliothekstyp mit `-T 2`, das eigene Modulprotokoll `-P 1.0` und die Freigabeangabe `-R 0.1.0.0`. Die eigene Modulversion ist von einer erforderlichen Kernelversion zu unterscheiden.

Der nachvollziehbare Patch stellt den alten Kernel-Bibliotheksstatus für das 1.x-Ausgabeformat wieder her und berücksichtigt eng begrenzte OMF-Kommentarfälle aus dem C-Pfad. Übernehmen Sie diese Änderungen nicht ungesehen in einen anderen Quellstand. Der Bootstrap speichert beziehungsweise prüft die dazugehörigen Eingaben; die erzeugten Objekt- und Geode-Dateien werden anschließend gesondert untersucht.

Für einen Offlineabruf können bereits vorhandene, exakt zu den Lockfiles passende Archive verwendet werden:

```sh
perl sdk.pl toolchain install --watcom-archive /pfad/zum/watcom-archiv --freegeos-archive /pfad/zum/freegeos-quellarchiv
```

Ein nicht passender Hash ist ein Abbruchgrund. `--freegeos-archive` bezeichnet das Quellarchiv, keinen ausgepackten Include-Ordner. Die Runner-Installation erfolgt gesondert über die Hostumgebung; der Bootstrap lädt nicht stillschweigend einen QEMU-Runner herunter.

## Optionale beobachtete Kernelbindung der Bibliotheksbeispiele

Ein importfreier Linkerbuild kann zunächst Kernelprotokoll 0.0 enthalten. Das eigene Bibliotheksprotokoll ist davon unabhängig. Für einen bewusst beobachteten Anforderungswert können Sie eine eigene echte 1.x-Geode als Referenz angeben:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /pfad/zu/UI.GEO
```

Der Build behält die ungebundene Fassung und protokolliert Referenz und Hash. Er übernimmt einen beobachteten Anforderungswert, keine komplette API und keine Loaderfreigabe. Verwenden Sie nicht `KERNEL.EXE` als `.GEO`-Referenz. Diese MZ-Datei benötigt einen anderen Analysepfad. Ein öffentliches Projekt darf seine eigene Runtime nicht als dadurch neu lizenzierten SDK-Bestandteil betrachten.

## Zusätzlicher nativer Anwendungsweg mit NASM

`perl sdk.pl toolchain install` baut zusätzlich den im [NASM-Lockfile](../../toolchains/nasm.lock.json) festgelegten Assembler aus dem offiziellen Quellarchiv. Der Host benötigt C-Compiler, Make, Perl und eine POSIX-Shell. `--nasm-archive /pfad/zum/archiv` erlaubt ein bereits vorhandenes Archiv mit exakt passendem Hash. Die getestete Bootstrapumgebung ist Linux/x86-64.

Der `ensemble12`-Adapter ruft NASM mit `-f bin` und projektspezifischen Include-Verzeichnissen auf. `CPU 8086` begrenzt die eigenen Anweisungen. Ein eigener Perl-Writer erzeugt anschließend den nativen Container, Prozessklasse, zwei neue Objektressourcen und die ausdrücklich markierten Relokationen. Dieser Weg benötigt für seine begrenzte eigene UI-Beschreibung weder kopierte kommerzielle Ressourcen noch einen vollständigen historischen UI-Compiler.

```sh
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
perl sdk.pl build --project examples/hello-libraries --target-root /pfad/zum/eigenen/GWSVGA
```

`--target-root` gehört zum Anwendungsweg, `--kernel-reference` zum Bibliotheksweg. Sie sind keine austauschbaren Optionen. Das Zielprofil der Anwendung legt Kernel 622.3 und UI 693.0 fest und vergleicht die Referenzhashes. Die Bibliotheksprobe benötigt zusätzlich die korrekt gebauten und in `SYSTEM` installierten eigenen Bibliotheken. Die vollständigen Schritte stehen im [Anwendungsleitfaden](native-applications.md).

Es gibt damit zwei unterschiedliche Assemblerpfade: Esp/Glue für die Rechenbibliotheken und NASM/eigener Writer für die kleine GUI. Verwenden Sie die zugehörigen Quelldialekte und Manifeste; eine Umbenennung von `.asm` in `.nasm` übersetzt keine Esp-Direktiven.
