# C, Assembler und gemischte Projekte

[Handbuch](README.md) · [English](../en/c-and-assembly.md)

Ein gemischtes Projekt ist dann beherrschbar, wenn der Übergang zwischen C und Assembler klein und eindeutig beschrieben ist. Verwenden Sie C für gut testbare Datenverarbeitung und Assembler dort, wo der nachgewiesene native Aufrufvertrag oder eine gemessene Engstelle es verlangt.

Die öffentliche [Anleitung zum Mischen von C und Assembler](https://bluewaysw.github.io/pcgeos/Esp/emixing.html) erklärt die Rolle von Schnittstellen und Compilerkonventionen. Ihre Beispiele sind keine pauschale Zusicherung für die 1.x-ABI dieses Projekts.

## Empfohlene Aufteilung

| Schicht | Inhalt | Darf GEOS-Strukturoffsets kennen? |
|---|---|---|
| Portabler Kern | Berechnung, Parser, Formatprüfung, Zustandsübergänge | Nein |
| C/Assembler-Grenze | Kleine Datenpakete, eindeutig definierte Rückgaben | Nur eigene, festgelegte Strukturen |
| Zieladapter | Native Registeraufrufe, Speicher- und Nachrichtenoperationen | Ja, mit Zielnachweis |
| UI-Code | Ereignisse, Zustandsanzeige und Invalidierung | Nur über die ausgewählte native Schnittstelle |

Diese Aufteilung ist oft wertvoller als eine vollständige Neuimplementierung in Assembler. Ein schnellerer Einzelblock nützt wenig, wenn dadurch zusätzliche Kopien, dauerhaft gesperrte Ressourcen oder eine größere residente Datenmenge entstehen.

## Vor dem ersten gemischten Aufruf festlegen

Für jede exportierte Funktion benötigen Sie einen Vertrag mit folgenden Angaben:

1. Symbolname im Objektformat einschließlich Namensdekoration.
2. `near`- oder `far`-Aufruf und passende Rückkehrart.
3. Reihenfolge, Größe und Ort der Argumente.
4. Verantwortlichkeit für die Stapelbereinigung.
5. Register beziehungsweise Speicherort des Ergebnisses.
6. Zu erhaltende Register, Flags und Segmentregister.
7. Datenmodell, Strukturpackung und zulässige Zeiger.
8. Eigentum und Gültigkeitsdauer aller übergebenen Puffer.

Begriffe wie „cdecl“ oder „Pascal“ reichen ohne die verwendete Compilerimplementierung nicht aus. Auch `int`, ein Funktionszeiger oder ein gewöhnlicher Datenzeiger hat nicht auf jedem Host und in jedem 16-Bit-Speichermodell dieselbe Größe.

## Einen portablen Kern gestalten

Der Kern sollte keine DOS- oder GEOS-Initialisierung voraussetzen. Nutzen Sie kleine Ein-/Ausgaben, explizite Pufferlängen und nachvollziehbare Fehlerzustände. Vermeiden Sie einen stillen Rückgriff auf globale C-Laufzeitfunktionen, deren Zielimplementierung noch nicht feststeht.

Ein einfacher Prüffall kann auf dem Host beispielsweise feststellen, ob ein Parser eine zu lange Eingabe ablehnt oder ob eine Berechnung an einer Grenze überläuft. Dieser Test kann nützlich sein, obwohl die Hostgröße von `int` abweicht. Er muss diese Abweichung ausdrücklich behandeln; andernfalls testet er ein anderes Programmverhalten als das 16-Bit-Ziel.

Schreiben Sie Übergaben möglichst in eigene kleine Strukturen und prüfen Sie deren tatsächliche Größe im Zielbuild. Serialisieren Sie diese Strukturen nicht ungeprüft auf die Festplatte: internes Speicherlayout und dauerhaftes Dateiformat sind zwei unterschiedliche Verträge.

## Konkretes C-Beispiel: ein Prüfsummenschritt

[`examples/math-c/checksum.c`](../../examples/math-c/checksum.c) definiert einen 16-Bit-Typ und erzwingt dessen Größe beim Übersetzen. Die öffentliche Funktion `ChecksumStepC` verwendet für Watcom ausdrücklich `__far __cdecl`; der Hostpfad entfernt diese Zielspezifika für den fachlichen Test.

Die Berechnung rotiert einen 16-Bit-Zustand um fünf Bit und verknüpft ihn mit dem unteren Byte der Eingabe. Beispielsweise ergibt ein Zustand von 0 mit dem Bytewert `0x41` den Wert `0x0041`. Ein solcher Test ist klein genug, um Argumentübergabe und Rechenlogik getrennt zu untersuchen.

Der Erfolg dieses Beispiels erlaubt keine willkürlichen Zeigerübergaben: Die gezeigte Schnittstelle verwendet nur Wortskalare. Sobald Sie einen Puffer, globale Daten oder eine Struktur hinzufügen, müssen Sie Segmentbezug, Länge, Packung und Lebensdauer neu festlegen. Die Trennung zwischen internem C-Aufruf, `far`-Export und nativer GEOS-Objektmethode bleibt bestehen.

## Assembleradapter schreiben

Ein Adapter soll gerade so viel erledigen, wie der native Vertrag verlangt:

1. Eigene Argumente validieren beziehungsweise übernehmen.
2. Benötigte Register und Segmentbezüge herstellen.
3. Genau den nachgewiesenen Bibliotheksaufruf durchführen.
4. Ergebnis und Fehlerstatus in den eigenen Vertrag übersetzen.
5. Sperren und temporäre Zustände korrekt auflösen.
6. Mit der vereinbarten Stapel- und Registerlage zurückkehren.

„Alle Register erhalten“ ist kein universell richtiger Vertrag. Manche internen Routinen müssen bestimmte Register mit neuen Werten zurückgeben. Prüfen Sie deshalb die echte Aufrufstelle und die echte Rückkehrgrenze. Ein Test, der einen falschen Vertrag besonders streng durchsetzt, schützt nicht vor Integrationsfehlern.

## Objektmethoden sind nicht beliebige C-Funktionen

Ein Objektmethodenaufruf kann zusätzliche Zustände wie Nachrichtenkennung, Objektbezug oder Bibliothekskontext benötigen. Ein gewöhnlicher Compiler erzeugt diese Umgebung nicht allein durch einen passenden Funktionsnamen. Auch ein GOC-generierter Aufrufpfad braucht eine für das Ziel passende Laufzeit und Importbeschreibung.

Behandeln Sie daher drei Fälle getrennt:

- Interne C-Funktion des Rechenkerns.
- Öffentliche C-Funktion einer eigenen Bibliothek.
- Native GEOS-Objektmethode beziehungsweise Kernel-/UI-Routine.

Erst wenn jeder Übergang dokumentiert und geprüft ist, dürfen die Schichten verbunden werden.

## Gemischte Projekte testen

Beginnen Sie mit sehr kleinen Aufrufen und festen Testvektoren. Prüfen Sie Ergebnisse und außerdem Stapelstand, Segmentregister, vorgeschriebene Registerausgaben sowie Speichergrenzen. Führen Sie danach denselben Pfad im nativen Ziel aus.

Kontrollieren Sie auch compilererzeugte Hilfsroutinen. Eine scheinbar einfache C-Ausdrucksfolge kann einen externen Divisionshelfer, eine Strukturkopie oder eine Initialisierung benötigen. Ein erfolgreicher Hosttest belegt weder das Vorhandensein dieses Helfers im Ziel noch dessen 8086-Tauglichkeit.

Die Beispiele unter [examples](../../examples/) und die [Werkzeugprofile](toolchain.md) geben an, welcher dieser Schritte im jeweiligen Release tatsächlich ausgeführt wurde.


## Die geprüfte eigene C-Bibliotheks-ABI

Der C-only-Export des gelieferten Beispiels heißt im Objekt-/Exportpfad `_ChecksumStepC`. Er besitzt eine ausdrücklich eigene `far __cdecl`-Schnittstelle:

| Bestandteil | Vertrag dieses Beispiels |
|---|---|
| Argumente | Zwei 16-Bit-Wörter, rechtes Argument zuerst auf den Stapel |
| Rückkehr | Far-Rückkehr; der Aufrufer entfernt die vier Argumentbytes |
| Ergebnis | `AX` enthält den 16-Bit-Prüfsummenwert |
| Volatil | `AX`, `BX`, `CX`, `DX`, `ES` |
| Erhalten | `SI`, `DI`, `BP`, `DS` |
| Flags | Keine öffentliche Zusage |

Nach dem üblichen gesicherten `BP` liegen bei diesem generierten Pfad der Zustand unter `[BP+6]` und der Bytewert unter `[BP+8]`. Diese Offsets gehören zu diesem geprüften Far-C-Aufrufrahmen, nicht zu beliebigen GEOS-Methoden oder Compileroptionen. Ein Stub beziehungsweise Aufrufer muss `SS` und `DS` ausdrücklich als möglicherweise verschiedene Segmente behandeln.

## Der gemischte Build

Das aktuelle Mischbeispiel verwendet einen **Far-C-Helfer** in einer eigenen festen Ressource `ALGORITHM` und Esp-Code in einer getrennten festen Ressource `BridgeCode`. Der Assembleradapter übergibt die Wortargumente an C, bereinigt danach den Stapel und stellt seine öffentliche Registerschnittstelle wieder her.

| Export | Eingabe | Ergebnis | Weitere Register |
|---|---|---|---|
| `ChecksumStep` | `AX` Zustand, `DX` Bytewert | `AX` Prüfsumme | `BX/CX/DX/SI/DI/BP/DS/ES` erhalten |
| `SaturatingAdd` | `AX` und `DX`, vorzeichenlose Wörter | `AX=min(a+b,65535)` | `BX/CX/DX/SI/DI/BP/DS/ES` erhalten |

Die Flags sind bei diesen beiden Registerexporten nicht festgelegt. Diese Konvention wurde für die Bibliothek gewählt; sie ist keine behauptete native GEOS-C-System-ABI. Die feste interne Codeadresse wird mit der tatsächlich erzeugten Segmentrelokation geprüft.

Die gelieferten Ausführungsberichte unter `validation/` prüfen den tatsächlich verlinkten Zielcode mit kontrollierten Aufrufrahmen, getrenntem Stack-/Datensegment und erlaubten Schreibbereichen. Sie lassen native Loader- beziehungsweise GEOS-Runtime-Tests ausdrücklich getrennt. Verwenden Sie die aktuellen Berichte, statt ältere Fallzahlen als erneut ausgeführte Tests auszugeben.

## Die Bibliotheksgrenze aus einer nativen GUI ausüben

[hello-libraries](../../examples/hello-libraries/README.de.md) ist ein eigener nativer NASM-Prozess, der die drei Rechenbibliotheken über echte Import-Fernaufrufe anspricht. Er prüft deren Ergebnisse und zeigt `PASS` oder `FAIL`. Die vollständige Build-/Installationsfolge steht im [Anwendungsleitfaden](native-applications.md).

Der native Import löst den Zielcode; er wandelt die Aufrufkonvention nicht um. Der C-Aufruf benötigt weiterhin die richtigen Argumentwörter und Stapelbereinigung. Die Assemblerexporte erwarten ihre eigenen Registerwerte. Damit bleibt die kleine private C-ABI von der Register-ABI des Kernels getrennt. Eine erfolgreiche Probe ist ein konkreter Integrationsnachweis, kein allgemeines Versprechen für fremde C-Objekte oder Systemwrapper.
