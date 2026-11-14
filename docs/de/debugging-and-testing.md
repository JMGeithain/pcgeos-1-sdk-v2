# Fehlersuche und Teststrategie

[Handbuch](README.md) · [English](../en/debugging-and-testing.md)

Eine funktionierende Entwicklungsumgebung braucht mehr als einen Compiler. Gute Tests verbinden fachliche Ergebnisse, echte Maschinenbefehle, Dateiformatprüfungen und beobachtetes Zielverhalten. Jede Ebene kann Fehler übersehen, die eine andere Ebene sichtbar macht.

## Einen reproduzierbaren Befund sichern

Bevor Sie einen Fehler beheben, erfassen Sie:

1. Projekt-Commit, Werkzeugversionen und vollständigen Buildbericht.
2. Hash der tatsächlich in die Runtime kopierten Binärdatei.
3. GEOS-Ausgabe und die verwendeten Referenzbibliotheken.
4. Emulator und CPU-Modell beziehungsweise physische Hardware.
5. Treiber, Speicherarten, Swap und gleichzeitig geöffnete Anwendungen.
6. Eine kurze Folge aus Aktionen, die den Fehler erneut auslöst.

Ein Fehler beim Laden kann andere Ursachen haben als ein Absturz beim Schließen eines modalen Dialogs. Bewahren Sie die kleinste bekannte reproduzierbare Variante auf.

## Auf dem Host beginnen

Führen Sie zuerst die Repositoryprüfungen aus:

```sh
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

`doctor` beschreibt die Umgebung. Statische Prüfungen können fehlende Dateien, ungültige Metadaten oder einen nicht freigegebenen Buildpfad erkennen. Fachliche Hosttests prüfen Algorithmen. Keine dieser Ausgaben darf als bestandener nativer GEOS-Lauf umbenannt werden.

Für Parser und Berechnungen lohnen sich feste Grenzfälle: leer, minimal, maximal, abgeschnitten, zu groß und bewusst ungültig. Reproduzierbare Zufallstests müssen ihren Seed und die fehlgeschlagene Eingabe speichern.

## Vor dem Laden das Artefakt prüfen

Kontrollieren Sie Ressourcenanzahl und -grenzen, Imports, Exporte, Relokationen, erforderliche Protokolle und den erklärten Prozessortyp. Die Formatwerkzeuge im Repository beschreiben ihren tatsächlichen Prüfumfang; ein synthetischer Testdatensatz ist dabei kein Original-Geode.

Bei Codeänderungen müssen komplette Relokationsoperanden betrachtet werden. Wenn ein ursprünglicher Fixup über einen neuen Codebereich reicht, kann der Loader den scheinbar richtigen Patch beim Laden wieder überschreiben. Ein Test nur der unbearbeiteten Dateibytes erkennt diesen Fehler nicht zuverlässig.

## Maschinenbefehle und native Verträge testen

Ein Ausführungstest für einen kleinen Assembleradapter sollte echte erzeugte Bytes verwenden. Prüfen Sie, dass diese Bytes dem freigegebenen Quelltext entsprechen, bevor der Test irgendwelche Stub-Adressen einsetzt.

Geeignete Prüfungen umfassen:

- Eindeutige Bibliotheksselektoren für gleich nummerierte Imports.
- Stapelstand und Rückkehrart.
- Dokumentierte Registerausgaben statt pauschaler Erhaltung aller Register.
- Erlaubte Schreibbereiche und Grenzverletzungen.
- Wiederholte oder anders angeordnete Eingabenachrichten.
- Ausbalancierte Sperren und Freigaben.
- Fehlerpfade und abgebrochene Vorgänge.

Ein Grafikstub kann Parameter und Zustandseffekte beobachten. Er zeigt jedoch keine wirklichen Pixel, Treibereigenheiten, Invalidierungsreihenfolgen oder Deadlocks zwischen echten Objektthreads. Diese Grenzen gehören in den Testbericht.

## Native Integration testen

Eine sinnvolle Reihenfolge für eine Anwendung ist:

1. Sauberer Start und normale Hauptfunktion.
2. Mehrere Aktionen hintereinander und erneutes Öffnen.
3. Verschieben, Überdecken, Freilegen und Größenänderung.
4. Minimieren/Wiederherstellen und Maximieren/Wiederherstellen.
5. Fokuswechsel und modale sowie nicht modale Dialoge.
6. Schließen eines geänderten Dokuments mit Speichern, Verwerfen und Abbrechen.
7. Gleichzeitiges Laden anderer Anwendungen.
8. Knappere Speicher- und Fehlerkonfigurationen.

Vergleichen Sie die getestete Datei erneut mit dem Buildhash. Eine alte Datei im Zielordner kann sonst einen scheinbaren Erfolg erzeugen.

## Swat und historische Debugger

Die öffentliche [Swat-Einführung](https://bluewaysw.github.io/pcgeos/Tools/tswatcm.html) beschreibt den historischen Debugger und seine Arbeitsweise. Verwenden Sie für 1.x nur die dazu passende Kombination aus Debugger, Stub, Symbolformat und Zielsystem. Ein späterer Debugger oder ein nachgebauter Kommunikationsweg ist nicht allein durch den Namen „Swat“ kompatibel.

Wenn diese Kombination nicht vorliegt, behaupten Sie keine funktionierende Source-Level-Debugsitzung. Nutzen Sie zunächst kontrollierte Fehlerszenarien, Formatberichte, disassemblierte Zielbytes und kleine native Testprogramme. Kennzeichnen Sie direkte Binäranalyse und quelltextgestütztes Debugging als unterschiedliche Verfahren.

## Leistungs- und Speichermessung

Messen Sie feste Aufgaben unter identischen Bedingungen. Notieren Sie Warm-/Kaltstart, Swap, CPU-Einstellung, Auflösung und Datenmenge. Emulatorzyklen sind keine universelle MHz-Angabe. Eine Bildfolge ohne Zeitmessung beweist keine Bildrate auf echter Hardware.

Trennen Sie Dateigröße, statische Ressourcen, globale Daten, pro Objekt entstehenden Zustand, temporäre Spitzen und vom Kernel erzeugte Hilfsstrukturen. Falls nur einige dieser Größen bekannt sind, veröffentlichen Sie genau diese Werte. Ein fehlender Gesamt-RAM-Messwert sollte nicht durch eine Schätzung als „gemessen“ ersetzt werden.

## Fehlerkorrektur abschließen

Erstellen Sie einen Test, der den konkreten Fehler erfasst, ohne lediglich den geänderten Code nachzuzeichnen. Ein Beispiel ist ein negativer Kontrollfall, der einen falschen Bibliotheksimport oder einen beschädigten Fixup sicher ablehnt. Wiederholen Sie danach die betroffenen nativen Abläufe und binden Sie den Bericht an den neuen Hash.

