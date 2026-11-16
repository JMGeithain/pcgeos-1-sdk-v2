# GEOTEST: gesicherte Erkenntnisse und Entwicklungsstand

Stand: 16.11.2026. Dieses Fallbeispiel hält Ergebnisse aus der GEOTEST-Arbeit fest. Es ist **keine allgemeine PC/GEOS-API-Spezifikation**. Aussagen gelten nur für die jeweils benannte Datei, Probe oder beobachtete GeoWorks-1.x-Installation.

## Ziel und Plattformgrenze

GEOTEST ist eine eigene PC/GEOS-1.x-Anwendung mit einem eigenen Dokumenttyp. Das Projekt hält 8086-Code und GeoWorks 1.x als Ziel ein. Ein formal gebauter Geode, eine statische Analyse, ein Emulatorlauf und ein vom Nutzer gezeigter Lauf im Zielsystem sind verschiedene Evidenzarten und werden getrennt dokumentiert. Keine proprietären Kernel-, UI-, Icon- oder Runtime-Dateien werden in diesem SDK-Repository abgelegt.

## Kerneldatei: Dateideskriptor und Dispatcher

Untersuchte Quelle war ausschließlich `GEOWORKS/KERNEL.OLD` aus dem deutschen `GEOWORKS.zip`, 72.688 Byte, SHA-256 `BD4D680B15F8DD66B2B09B506DE96672972F716A11E0A38220477BF07B6C1E9B`. Die Rohdatei blieb unverändert. Methode: 16-Bit-Disassemblierung und gezielte Hex-/Kontrollfluss-/Stackanalyse.

- Der Fernzeiger `ES:[0x05B8]` wird bei Rohdateioffset `0x111A3–0x111B8` dynamisch aus einem Offset/Segment-Paar geladen. `KERNEL.OLD` enthält den Aufruf, aber nicht die Implementierung des zur Laufzeit geladenen Ziels.
- Im Open-/Create-Pfad (`0x18F6` bzw. `0x1983`, gemeinsamer Pfad ab `0x18FC`) wird `DI=4` über diesen Fernzeiger aufgerufen. Die Zuordnung einzelner Registerwerte zu einem DOS-Handle bleibt ohne den konkreten Dispatcherzielcode eine Hypothese.
- `0x17CB` schreibt getrennte Eingaben in das FD-Objekt. Nach Stackkorrektur 2532 gilt auf dem normalen Pfad: `FD+0` erhält das Low-Byte des Eingangs-`BX`; `FD+2` das Low-Byte des vor `DI=4` gesicherten `AX`; `FD+3` das Low-Byte des nach `DI=4` verbliebenen `AX`; `FD+6` das Ergebnis von `0x0D2B`.
- `0x0D2B` validiert den Wert über `0x12C5` und bildet ihn über `0x14BB` in eine interne Tabelle ab. `0x14BB` verwendet eine Schrittweite von 22 Byte und die Basis `0x021C`. `0x0D95/0x0DA8` lösen `FD+6` als diesen internen Schlüssel/Tabellenverweis wieder auf.
- Im Kernel wurde keine untersuchte Stelle gefunden, die `FD+6` selbst als rohen DOS-Dateihandle an einen DOS-Funktionsaufruf übergibt. `DI=0x16` wird unter anderem im Pfad mit `AH=0x40` (Schreiben) aufgerufen; Nachtrag 2531 fand denselben Dienst außerdem bei `AH=0x42`, `0x46` und `0x3E`. Der Treiber kann intern noch übersetzen, ist hier aber nicht untersucht.

**Korrekturhistorie:** Die ersten Fassungen 2513 und 2530 ordneten einzelne Bytes falsch zu. Maßgeblich ist die Stackverfolgung aus 2532. Daher weder `FD+0` noch `FD+3` als universellen DOS-Handle bezeichnen. Gesichert ist nur die oben angegebene Feldquelle und die interne Weiterverarbeitung von `FD+6`; die Semantik des externen Dispatchers und eine mögliche Handle-Übersetzung bleiben offen.

## Eigenes Dokumentformat GTDF v1

GTDF ist ein flaches, anwendungseigenes ASCII-Testformat mit einer beobachteten GEOS-Dateihülle. Es ist kein GeoWrite-, VM- oder universelles PC/GEOS-Dokumentformat.

| Offset | Inhalt |
|---|---|
| `0x00–0x03` | GEOS-Signatur `C7 45 CF 53` |
| `0x04–0x13` | 16-Byte-Präfix aus einer leeren GeoWrite-Referenz; Feldbedeutung unbekannt, unverändert übernommen |
| `0x14` | Typ-Token `GTD1`, Manufacturer-ID 0 |
| `0x1A` | Creator-Token `GTAP`, Manufacturer-ID 0 |
| `0x20–0x3F` | Nullterminierter Titel und Auffüllung bis Offset `0x40` |
| `0x40` | `GTDF`, Version `u16=1`, Kopfgröße `u16=12`, Nutzdatenlänge `u16`, reserviert `u16=0` |
| `0x4C` | druckbarer ASCII-Nutztext, derzeit höchstens 40 Byte |
| nach Nutztext | Abschluss `GTE!`, danach exaktes Dateiende |

Alle Mehrbytewerte sind little-endian. Die Gesamtgröße ist `80 + N` Byte. Der Parser prüft Signatur, Tokens, Magic, Version, Kopfgröße, Längenlimit, druckbare Zeichen, Abschluss und EOF. Der 16-Byte-Präfix ist lediglich eine begrenzte Kompatibilitätsübernahme; seine Bedeutung ist nicht erschlossen.

## Programm-/Dokument-Token und Icons

- Programm: Token `GTAP`, Hersteller 0; Programm-Moniker ist der Monitor.
- Dokumenttyp: Token `GTD1`, Hersteller 0; eigenes Icon aus dem Testbild.
- Die 4-plane-EGA-PCX muss 48×30 Pixel, 1 Bit je Plane und vier Planes haben. Eine bereitgestellte 8-Bit-/1-Plane-PCX wurde von `ICONMAKE 1.0` nicht als EGA-Icon akzeptiert; die verlustfreie Umwandlung der 16 Farbindex-Ebenen in vier Planes wurde zurückdekodiert geprüft.
- Der Icon-Workflow verwendete `ICONMAKE m0 GTS1,0 GTS1_EGA.PCX`; `ICONMAKE` erzeugte den Token-Dummy `GTS10000.000`. Nutzerbilder bestätigen die Anzeige des GTS1-Monikers und die Anwendungssymbolanzeige im GeoManager. Für den Dokumenttoken ist der separate Dummy `GTD10000.000` vorgesehen; Token-Erzeugung und sichtbare Dokumentzuordnung sind getrennt zu prüfen.
- DOS-Dateinamen im Testsystem müssen 8.3-konform sein; PCX-Beispielname `GTS1_EGA.PCX`.

## Beobachtete Implementierungsschritte

- Frühere Probe: der Nutzer sah `WRITTEN` nach Anlegen/Schreiben/Schließen und danach `EXISTS` bei erneutem Öffnen; die existierende Datei wurde nicht überschrieben. Dies belegt den beobachteten I/O-Pfad dieser Installation, nicht eine allgemeine Fehlercode- oder Kernel-API-Garantie.
- GTDF-Proben wurden in GeoWorks 1.x geöffnet und zeigten `EXACT` plus den gelesenen Inhalt. Nutzerbilder bestätigten unter anderem den Wortumbruch `GEOTEST DOCUMENT` / `PAYLOAD V1` (2540) sowie `GEOTEST DOKUMENT` / `2026` (2541). Ein vom Nutzer bestätigter GeoManager-Doppelklick öffnete GEOTEST 2537 für das Testdokument.
- Das GTDF-v1-Beispiel `GTST2537.000` ist 107 Byte groß, Nutztext `GEOTEST document payload v1`, SHA-256 `15223E9079AC05FADB94620DCAC17A4FA2D53EC278D9FBDF7D53B8954DD64494`.
- 2543-Quellstand fügte eine Create-if-missing-Probe mit Lesen, Validierung, Schließen und Rücklesen hinzu. Sein gespeicherter Buildbericht sagt `runtime_tested=false`; spätere Nutzerbilder anderer Versionsstände belegen keine Ausführung genau dieses Artefakts. Für 2543 selbst ist daher anhand des Buildberichts keine Laufzeitfreigabe zu behaupten.

## Menü-/Dialogarbeit: aktueller offener Stand

Zielanforderung: Menü `Datei` mit `Neu` und `Öffnen`, Dokumente unter `GEOWORKS\DOCUMENT`, Programm-Icon Monitor, Dokument-Icon Testbild sowie `Info` und `Hilfe`.

Eine reine Objektgenerator-Probe mit lokalen Originalvorlagen (`SPINTEXT.GEO`, `NOTEPAD.GEO`, `VIEWER.GEO`, `TERM.GEO`) erzeugte eine native UI-Ressource mit 53 Objekten und 23 Auslösern. Die Vorlagen unterscheiden sich in Hash und Größe von einer früheren SDK-Referenz. Das belegt nur, dass der Generator mit diesen Bytes eine Objektstruktur erstellen kann.

**Noch nicht implementiert oder belegt:** eine neue GEOTEST-Version mit den gewünschten Menüs, lauffähige `Neu`-/`Öffnen`-Aktionen, ein korrekt auf `GEOWORKS\DOCUMENT` gesetzter nativer Dateiauswahldialog, Info-/Hilfedialoge und eine Laufzeitprüfung dieser Funktionen. Das vorhandene native UI-Beispiel enthält 386-Code und darf nicht in das 8086-Ziel übernommen werden. Seine Vorlagenlayouts können als Forschungsreferenz dienen, nicht als fertige GEOTEST-Implementierung.

## Nächste Schritte

1. Den `DI=4`-/`DI=0x16`-Dispatcherzielcode in der tatsächlich geladenen Originalinstallation identifizieren; Registervertrag gegen beobachtete Aufrufer abgleichen.
2. Den 8086-Menü-/Dialogpfad für `Neu`, `Öffnen`, `Info` und `Hilfe` implementieren, ohne den 386-Adapter zu übernehmen.
3. Den nativen FileSelector gezielt auf `GEOWORKS\DOCUMENT` setzen und die Dateipfade mit Testkopien prüfen.
4. Frischen Build strukturell prüfen; dann im konkreten GeoWorks-1.x-System jede Aktion einzeln beobachten. Buildstatus und Laufzeitnachweis getrennt halten.
5. Ein Dokument darf erst systemweit als dem Programm zugeordnet gelten, wenn GeoManager-Icon und Doppelklick-Verhalten für den isolierten Dokumenttyp bestätigt wurden.

## Nachweisgrenze und Provenienz

Die Ergebnisse stammen aus dem deutschen GEOWORKS-Archiv, eigenen GEOTEST-Quellständen/-Buildberichten und vom Nutzer bereitgestellten Screenshots des installierten GeoWorks-1.x-Systems. Die Kerneldatei und die proprietären Laufzeitvorlagen selbst werden nicht in dieses Repository kopiert. Screenshots belegen nur die sichtbaren Zustände und jeweils erkennbaren Versionen; sie ersetzen keine beliebige Dateiformat- oder API-Garantie.

