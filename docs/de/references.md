# Quellen und weiterführende Unterlagen

[Handbuch](README.md) · [English](../en/references.md)

Die folgenden Primärquellen dienen der Herkunftsprüfung und der Vertiefung. Die aktuelle FreeGEOS-Quelle und ihre SDK-2.0-basierte Dokumentation sind keine unverändert einsetzbaren 1.x-Header. Prüfen Sie die Version jeder verwendeten Definition.

## GEOS-Quellen und Architektur

| Quelle | Wofür sie nützlich ist | Grenze |
|---|---|---|
| [Offizielle FreeGEOS-Quellbasis](https://github.com/bluewaysw/pcgeos) | Werkzeuge, spätere Systemquellen, Lizenz und Buildhinweise | Ausgangsbasis Breadbox Ensemble 4.13 |
| [Technische Dokumentation](https://bluewaysw.github.io/pcgeos/) | Einstieg und Inhaltsverzeichnis | Grundlage SDK 2.0 |
| [Systemarchitektur](https://bluewaysw.github.io/pcgeos/Concepts/carch.html) | Schichten, Ressourcen und Objektmodell | Konkrete 1.x-Verträge separat prüfen |
| [Handles](https://bluewaysw.github.io/pcgeos/Concepts/chandle.html) | Verwaltete Referenzen verstehen | Kein Ersatz für die Ziel-Includes |
| [Speicherverwaltung](https://bluewaysw.github.io/pcgeos/Concepts/cmemory.html) | Lebensdauer und beweglicher Speicher | Flags und Layouts zielabhängig |
| [Lokaler Speicher](https://bluewaysw.github.io/pcgeos/Concepts/clmem.html) | Chunks und blocklokale Verwaltung | Native Details für 1.x belegen |
| [Benutzeroberfläche](https://bluewaysw.github.io/pcgeos/Concepts/cuiover.html) | Generische und spezifische UI | Nicht jede spätere Klasse existiert im Ziel |
| [Grafikumgebung](https://bluewaysw.github.io/pcgeos/Concepts/cgraph.html) | Grafikzustand und Zeichnen | Treiber- und ABI-Grenzen beachten |
| [Dateisystem](https://bluewaysw.github.io/pcgeos/Concepts/cfile.html) | Dateioperationen konzipieren | Konkrete Funktionen prüfen |
| [Virtual Memory](https://bluewaysw.github.io/pcgeos/Concepts/cvm.html) | Persistente blockorientierte Daten | Kein gewöhnlicher Speicherhandle |
| [Bibliotheken](https://bluewaysw.github.io/pcgeos/Concepts/clibr.html) | Exporte und Schnittstellen | Protokolle für das Ziel nachweisen |
| [Lokalisierung](https://bluewaysw.github.io/pcgeos/Concepts/clocal.html) | Sprache und Ressourcen | Kodierung und Werkzeuge zielabhängig |

## Sprache und Werkzeuge

- [Werkzeugübersicht](https://bluewaysw.github.io/pcgeos/tools.html): Rollen der GEOS-Werkzeuge und historische Arbeitsabläufe.
- [Esp-Dokumentation](https://bluewaysw.github.io/pcgeos/esp.html): Spracheinstieg und Assemblerkonzepte; konkrete Werkzeuggeneration beachten.
- [C und Assembler kombinieren](https://bluewaysw.github.io/pcgeos/Esp/emixing.html): Schnittstellen zwischen den Sprachen, mit der oben genannten Versionsgrenze.
- [Swat-Einführung](https://bluewaysw.github.io/pcgeos/Tools/tswatcm.html): Debuggerkonzepte; ein passendes 1.x-Zielprofil ist gesondert erforderlich.
- [Open Watcom v2](https://github.com/open-watcom/open-watcom-v2): Compilerquellen, Dokumentation und Bedingungen. Ein C-Compiler allein ist kein GEOS-SDK.

Für heruntergeladene Werkzeuge sind die im Repository aufgezeichneten Versionen und Prüfsummen maßgeblich. Links auf bewegliche Hauptzweige dienen zum Auffinden; ein reproduzierbarer Build benötigt einen festgelegten Stand.

## Moderne Hostumgebung

- [Perl](https://www.perl.org/get.html): offizielle Installation und unterstützte Versionen.
- [Git](https://git-scm.com/downloads): Quellverwaltung auf den drei Hostplattformen.
- [Visual Studio Code](https://code.visualstudio.com/): Editorinstallation.
- [Microsoft: WSL installieren](https://learn.microsoft.com/en-us/windows/wsl/install): Linux-Umgebung unter unterstützten Windows-Ausgaben.
- [VS Code mit WSL](https://code.visualstudio.com/docs/remote/wsl): Editor und Werkzeuge im selben Remote-Kontext verwenden.
- [Docker Desktop für macOS](https://docs.docker.com/desktop/setup/install/mac-install/): Hostarchitekturen und Installationsvoraussetzungen beachten.

Diese Verweise sind keine Aussage, dass jede genannte Kombination im Rahmen dieses Release ausgeführt wurde. Der tatsächliche Testumfang steht im Repository-Testbericht.

## Quellen in eigenen Beiträgen angeben

Ein nachvollziehbarer Beitrag nennt die genaue Datei und Version einer Definition, die untersuchte Zielausgabe und den daraus abgeleiteten Vertrag. Bei einer Änderung an einem vorhandenen Werkzeug gehören auch der Patch und die ausgeführten Regressionstests dazu.

Vermeiden Sie große Kopien aus Handbüchern, wenn ein Link und eine eigene präzise Erklärung ausreichen. Erhalten Sie bei weitergegebenem Quellcode die dazugehörigen Lizenz- und Urheberhinweise.


## Beigebrachte Anwendungsreferenzen

Die genauen Archivpfade und der Lizenzumfang der nachgereichten GeoSheet-, GNU-Chess- und Bounce-Unterlagen stehen in [Wiederhergestellte Referenzanwendungen](recovered-references.md). Sie enthalten konkrete Beobachtungen der bereitgestellten Ensemble-1.2-Umgebung. Frühere Messungen und Tests werden nicht als erneute SDK-Tests ausgegeben, und ursprüngliche Runtime-/Objektvorlagen werden dadurch nicht Bestandteil der öffentlichen SDK-Lizenz.
