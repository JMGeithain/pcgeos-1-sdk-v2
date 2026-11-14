# Eine eigene native Ensemble-1.2-Anwendung bauen

[Handbuch](README.md) · [Schnellstart](quickstart.md) · [English](../en/native-applications.md)

Der Buildadapter `ensemble12` verbindet eigenen 8086-NASM-Code mit neu erzeugten nativen Ressourcen. Das Beispiel öffnet ein GEOS-Fenster und zeichnet durch den Kernel. Es verwendet weder einen DOS-Grafikmodus noch einen Bildschirmtreiber direkt. Die ursprünglichen kommerziellen Programme dienen nicht als Binärvorlage.

Dieser Adapter unterstützt einen kleinen, ausdrücklich nachgewiesenen Ausschnitt der bereitgestellten Ensemble-1.2-Ausgabe: Kernel-Anforderung 622.3 und UI 693.0. Die Dateiidentität wird anhand des [Zielprofils](../../targetprofiles/supplied-ensemble12.json) geprüft. Eine andere 1.x-Ausgabe benötigt einen eigenen überprüften Profil- und ABI-Nachweis. Allgemeine GOC-Übersetzung und vollständige C-Systemwrapper gehören nicht zu diesem Adapter.

## 1. Hello bauen

Installieren Sie zuerst die [Hostwerkzeuge](host-setup.md). Im SDK-Hauptverzeichnis:

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor
perl sdk.pl verify-target /pfad/zum/eigenen/GWSVGA
perl sdk.pl check --project examples/hello-asm
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
perl sdk.pl inspect build/g1hello/g1hello.geo --summary
```

`--target-root` bezeichnet den Stammordner einer eigenen passenden Runtime mit `KERNEL.EXE` und `SYSTEM/UI.GEO`. Auch die für das Profil festgelegte `SYSTEM/MOTIF.GEO` muss passen. Der Prüflauf vergleicht deren Hashes; er kopiert keine Runtime-Dateien in die Ausgabe. Ein nicht passendes Profil soll den Build stoppen. Entfernen Sie diese Kontrolle nicht, um eine abweichende Installation scheinbar zu unterstützen.

Die Anwendung entsteht als `build/g1hello/g1hello.geo`. Der dauerhafte Modulname lautet `g1hello.app`, der sichtbare Titel `GEOS 1 SDK Hello`. Daneben stehen Buildbericht, Ressourceninspektion, NASM-Listing und Buildlog. Die ergänzende flache `.resource.bin` enthält Zwischenmetadaten und wird nicht als Anwendung installiert.

## 2. In einer Testinstallation starten

Beenden Sie GEOS sauber, bevor Sie Dateien seiner Installation verändern. Kopieren Sie `g1hello.geo` nach `WORLD` einer Arbeitskopie des passenden Zielsystems, starten Sie GEOS neu und öffnen Sie `GEOS 1 SDK Hello` mit GeoManager. Bewahren Sie die Referenzinstallation unverändert auf.

Die erwartete Zeichnung zeigt `HELLO GEOS`, farbige Rechtecke und die kleinen Zeichenfolgen `SDK1` und `8086`. Die Zeichen entstehen aus einer eigenen begrenzten Pixelzeichentabelle. Es handelt sich weder um eine vollständige Schrift noch um ein Beispiel für native Textbearbeitung. Die Darstellung hat feste Koordinaten; eine Fenstervergrößerung skaliert sie nicht automatisch.

Prüfen Sie anschließend Überdecken/Freilegen, Verschieben, Minimieren/Wiederherstellen, Größenänderung, Programmwechsel, Schließen und erneutes Starten. Für tatsächlich ausgeführte Prüfungen ist der aktuelle [Validierungsbericht](../../VALIDATION.md) maßgeblich. Ein Buildbericht hält zunächst Buildfakten fest; eine passende Dateiidentität ist noch kein Ausführungstest.

## 3. Projektbeschreibung verstehen

Das unveränderte Beispiel verwendet:

```json
{
  "schema": 1,
  "name": "g1hello",
  "kind": "application",
  "backend": "ensemble12",
  "cpu": "8086",
  "long_name": "GEOS 1 SDK Hello",
  "token": "G1HL",
  "sources": [{"language": "nasm", "path": "hello.nasm"}],
  "view": {"width": 320, "height": 180},
  "native_runtime_tested": false
}
```

| Feld | Bedeutung |
|---|---|
| `name` | Kleiner permanenter Basisname, ein bis acht zulässige ASCII-Zeichen |
| `kind` / `backend` | Anwendungsweg mit dem ausdrücklich gewählten `ensemble12`-Adapter |
| `cpu` | Hier fest `8086`; die Quelldirektive begrenzt den eigenen Maschinencode |
| `long_name` | Sichtbarer Name; der aktuelle einfache Objektgenerator akzeptiert ASCII |
| `token` | Vier ASCII-Zeichen; für eigene veröffentlichte Projekte eine geeignete eigene Kennung wählen |
| `sources` | Genau ein NASM-Haupteinstieg; lokale Include-Dateien sind möglich |
| `view` | Ausgangsmaße; noch keine dynamische Layout- oder Skalierungsfunktion |

Das Feld `native_runtime_tested` ist kein Schalter, mit dem sich eine Freigabe erzeugen lässt. Ein tatsächlicher Test benötigt seinen eigenen Bericht mit Binärhash und Zielkonfiguration. Die Quellmanifest-Angabe allein darf kein ungetestetes Ergebnis umbenennen.

Ein eigenes Projekt lässt sich direkt mit dem SDK-Starter erzeugen. Im SDK-Hauptverzeichnis:

```sh
perl sdk.pl new --name myapp --language gui --directory ../myapp
perl sdk.pl check --project ../myapp
perl sdk.pl build --project ../myapp --target-root /pfad/zum/eigenen/GWSVGA
```

Der Befehl kopiert die eigenen funktionierenden Starterquellen, passt den Modulnamen sowie beim GUI den Titel/Token an und legt Manifest und MIT-Lizenz bei. Ein vorhandener Zielordner wird abgelehnt. `--language asm`, `c` und `mixed` wählen die entsprechenden Bibliotheksstarter; diese benötigen zum Übersetzen keine GUI-Runtime. Prüfen Sie für eigene Veröffentlichungen Kennung, Titel, Protokoll und Exportvertrag ausdrücklich.

Alternativ können Sie `examples/hello-asm` selbst kopieren und die Manifestfelder bearbeiten. Bleiben Sie zunächst bei derselben Quellstruktur und verändern Sie eine Farbe oder ein Rechteck. Fügen Sie erst danach neue Nachrichten oder Importe hinzu. Die erzeugte Projektbeschreibung ersetzt keinen nativen Test der eigenen Änderungen.

## 4. NASM, Esp und C auseinanderhalten

`hello.nasm` ist NASM-Quelltext für diesen flachen Ressourcenpfad. Die Bibliothek `examples/math-asm/math.asm` verwendet dagegen Esp. Beide erzeugen 8086-Maschinenbefehle, verwenden aber unterschiedliche Direktiven, Makros und Zwischenausgaben. Die Dateiendung und der `language`-Eintrag sollen diese Unterscheidung sichtbar halten.

Die mitgelieferte Datei [ensemble12.inc](../../tools/ensemble12/ensemble12.inc) setzt `BITS 16`, `CPU 8086` und Ursprung null. Die normalen Labels sind Offsets innerhalb der eigenen Code-Ressource. Native Adressen anderer Ressourcen dürfen nicht als während eines früheren Laufs beobachtete Segmentwerte im Code stehen.

| Makro | Aufgabe |
|---|---|
| `KCALL ordinal` | Native Kernel-Fernaufrufstelle und ihre Kernelrelokation registrieren |
| `LC import_index, ordinal` | Fernaufruf einer ausdrücklich importierten Bibliothek registrieren |
| `G1_METHOD message, label` | Nachricht und FAR-Handler in die Prozessmethodentabelle aufnehmen |
| `G1_FINISH` | Metadaten abschließen; muss die letzte Quelldirektive sein |

Die Makros führen beim Assemblieren Metadaten über die tatsächlichen Aufrufoperanden. Der Builder entfernt diese Tabellen aus der Code-Ressource und erzeugt daraus native Relokationen. Er sucht nicht wahllos nach Bytes mit dem Wert `9A`, der auch in Daten oder anderen Operanden vorkommen könnte.

`KCALL` oder `LC` erledigen keine Registeranpassung. Die aufrufende Routine muss den zugehörigen Vertrag erfüllen. Ein bekannter Ordinalwert ist keine C-Funktionsdeklaration. [abi.h](../../include/ensemble12/abi.h) enthält Konstanten und einen Optr-Typ; es liefert keine automatisch aufrufbare allgemeine System-C-Bibliothek.

## 5. Erzeugte Ressourcen

Der aktuelle kleine Adapter erzeugt fünf Ressourcen:

| Nummer | Inhalt | Verantwortlichkeit |
|---|---|---|
| 0 | Native Verwaltungsressource | Containerstruktur des Geodes |
| 1 | Initialisiertes DGROUP und Prozessklasse | TPD, Methodentabelle und Klassenbezug |
| 2 | Eigener Code | NASM-Handler und ausdrücklich markierte Aufrufe |
| 3 | Neue Interface-Objekte | `GenPrimary` und `GenView` |
| 4 | Neues Application-Objekt | `GenApplication` und Verknüpfungen |

Die initialisierte DGROUP-Größe beträgt im Starter 256 Byte, der angeforderte nicht initialisierte Prozessstack 2048 Byte. Dies sind **keine Gesamt-RAM-Werte** der Anwendung. GEOS benötigt zusätzlich unter anderem Ressourcenhandles, Laufzeitobjekte, UI-/SPEC-Zustand, Stackverwaltung und Grafikzustände. Eine kleine Dateigröße darf daher nicht als gemessener Speicherbedarf ausgegeben werden.

Der Prozessklasseneintrag liegt beim aktuellen Generator bei Offset `40h`; seine Methoden werden aus den Makrometadaten aufgebaut. `GenApplication`, `GenPrimary` und `GenView` werden eigenständig serialisiert. Die Feldwerte und Verbindungen gelten für das festgelegte Ziel. Sie sind kein allgemeiner Serializer für jede bekannte UI-Klasse und kein UIC-Ersatz für beliebige `.ui`-Dateien.

## 6. Zeichnen im Lebenszyklus

Das Hello-Beispiel behandelt unter anderem Öffnen, Schließen, Anheften und Freilegen des View-Fensters. Initiale Lebenszyklusnachrichten werden im vorgesehenen Pfad an die beobachtete Prozess-Superklasse weitergegeben. Der Zeichenpfad erhält den aktuellen Fensterhandle und erzeugt dafür einen GState.

Die Reihenfolge lautet: GState anlegen, native Updatebehandlung beginnen, innerhalb des Clips zeichnen, Update beenden und GState zerstören. Es wird kein dauerhafter Segmentzeiger auf eine bewegliche Ressource und kein Fensterhandle über dessen Lebensdauer hinweg aufbewahrt. Der Bildschirm muss aus dem eigenen Anwendungszustand wiederherstellbar sein.

Die kleine Startanwendung besitzt kein Dokumentmodell, keine Speichern/Abbrechen-Verarbeitung, keine allgemeine Menüerzeugung und keine Texteditor-Komponente. Für solche Erweiterungen sind zusätzlich passende Klassen, Nachrichten, Eigentumsregeln und native Fehlerpfade nachzuweisen. Die [Referenzanwendungen](recovered-references.md) erklären mehrere dabei relevante Fallstricke.

## 7. C- und Assembler-Bibliotheken aus einer Anwendung aufrufen

Das zweite Beispiel [hello-libraries](../../examples/hello-libraries/README.de.md) importiert alle drei selbst gebauten Rechenbibliotheken. Es zeigt `PASS` erst, wenn die fünf eingebauten Ergebnisvergleiche stimmen; andernfalls erscheint `FAIL`.

Bauen Sie zunächst die Bibliotheken mit einer Kernelanforderung aus der passenden eigenen UI-Datei:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-c --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-mixed --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/hello-libraries --target-root /pfad/GWSVGA
```

Kopieren Sie bei beendetem GEOS `g1math.geo`, `g1mathc.geo` und `g1mixed.geo` aus ihren jeweiligen Buildordnern nach `SYSTEM`, die Anwendung `build/g1probe/g1probe.geo` nach `WORLD`. Starten Sie GEOS und öffnen Sie `GEOS 1 Library Probe`.

UI belegt im Anwendungsheader automatisch Importindex 0, die drei zusätzlichen Bibliotheken die Indizes 1 bis 3. Ihre permanenten Namen und Protokolle 1.0 stehen im `imports`-Feld des Projektmanifests. Die tatsächlichen Verträge unterscheiden sich: Die Assemblerexporte verwenden eigene Registerkonventionen, `_ChecksumStepC` verwendet eine eigene FAR-`__cdecl`-Konvention. Das Mischbeispiel hat einen Registeradapter vor einer FAR-C-Hilfsfunktion in einer anderen festen Ressource. Lesen Sie [C und Assembler](c-and-assembly.md), bevor Sie diese Aufrufe ändern.

Eine erfolgreiche native Probe übt Loader-Imports und diese konkreten Aufrufgrenzen aus. Sie bestätigt keine beliebige C-Funktion, keine vollständige Fehlerbehandlung und keine allgemeine GEOS-System-C-ABI. Geringer Speicher und Multitasking benötigen zusätzliche, ausdrücklich dokumentierte Prüfungen.

## 8. Den Adapter erweitern

Bevor Sie einen neuen Aufruf oder ein neues generisches Objekt übernehmen, dokumentieren Sie Herkunft, Zielidentität, Registervertrag, Strukturfelder und Relokationen. Ergänzen Sie eine kleine isolierte Prüfung. Prüfen Sie dann den nativen Aufbau und schließlich das Verhalten im konkreten Zielsystem.

Eine Erweiterung sollte beispielsweise zunächst nur einen nachgewiesenen Trigger mit einer einfachen Zustandsänderung hinzufügen. Erst nach einem vollständigen Öffnen/Eingabe/Repaint/Schließen-Test folgt ein Eingabefeld, ein Dokumentcontroller oder ein Timer. So lässt sich ein Fehler einer konkreten ABI-Grenze zuordnen.

Weiterführend: [Backend-Vertrag](../../tools/ensemble12/README.md), [ABI-Deklarationen](../../include/ensemble12/README.md), [Speicher und 8086](memory-and-8086.md), [API-Nachweise](api-reference.md).
