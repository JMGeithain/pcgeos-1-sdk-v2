# Dateien, Dokumente und dauerhafte Daten

[Handbuch](README.md) · [English](../en/files-and-persistence.md)

Ein dauerhaftes Dateiformat soll nicht von zufälligen Zeigerwerten, Compilerpackung oder der aktuellen Position eines beweglichen Blocks abhängen. Planen Sie das Format getrennt vom internen Speichermodell.

Als konzeptionelle Ergänzung dienen die öffentlichen Kapitel zum [Dateisystem](https://bluewaysw.github.io/pcgeos/Concepts/cfile.html) und zu [Virtual Memory](https://bluewaysw.github.io/pcgeos/Concepts/cvm.html). Die auf Ihrem 1.x-Ziel verfügbaren Funktionen und Flags müssen im Zielprofil belegt sein.

## Dateiformat festlegen

Ein eigenes Format sollte mindestens eine erkennbare Kennung, eine Formatversion und explizite Längen enthalten. Definieren Sie für jedes mehrbyteige Feld die Bytefolge und den zulässigen Wertebereich. Legen Sie auch fest, wie unbekannte optionale Abschnitte übersprungen werden.

Speichern Sie keine folgenden Werte als dauerhafte Identität:

- Segment-/Offset-Adressen aus dem laufenden Programm.
- Temporäre Speicherhandles des aktuellen Prozesses.
- Funktionszeiger oder Rücksprungadressen.
- Ungeprüfte rohe C-Strukturen mit compilerabhängiger Packung.

Ein Container kann stattdessen eigene IDs und relative Positionen verwenden. Wenn Sie ein vom System verwaltetes VM-Format nutzen, übernehmen Sie nur dessen dokumentierte Lebensdauer- und Referenzregeln; erfinden Sie keine Gleichsetzung mit gewöhnlichen Speicherhandles.

## Jede Eingabe als unvollständig behandelbar entwerfen

Eine Datei kann abgeschnitten, beschädigt oder mit einer neueren Programmversion erzeugt worden sein. Prüfen Sie Längen vor Zuweisungen und vor Addition beziehungsweise Multiplikation. Der Ausdruck „Anzahl × Elementgröße“ kann auf dem 16-Bit-Ziel früher überlaufen als auf Ihrem Host.

Ein sinnvoller Parser arbeitet schrittweise:

1. Header mit einer festen Mindestgröße lesen.
2. Kennung und unterstützte Version prüfen.
3. Größen, Grenzen und gegenseitige Überlappungen validieren.
4. Benötigten Speicher begrenzt anfordern.
5. Abschnitte einzeln übernehmen und Fehler sauber zurückgeben.
6. Erst danach das bisherige Dokument ersetzen.

Beim Fehlschlag soll ein bereits geöffnetes, ungespeichertes Dokument nicht verloren gehen.

## Speichern gegen Datenverlust absichern

Schreiben Sie nach Möglichkeit zunächst in eine neue temporäre Datei. Prüfen Sie die tatsächlichen Schreib- und Abschlussfehler. Ersetzen Sie die bisherige Fassung erst nach erfolgreichem Abschluss mit einer auf dem Ziel unterstützten und geprüften Vorgehensweise.

Verwechseln Sie diesen Entwurf nicht mit einer universellen atomaren Transaktion. Die Garantien eines Umbenennens, Flushens oder Austauschs hängen vom Dateisystem und von den verfügbaren Funktionen ab. Dokumentieren Sie die tatsächlichen Zusicherungen Ihres 1.x-Pfads.

Prüfen Sie volle Datenträger, schreibgeschützte Ziele, abgebrochene Dateiauswahl und einen Schreibfehler nach teilweise erfolgreicher Ausgabe. Ein erfolgreicher kleiner Test auf einem großzügigen Emulatorlaufwerk deckt diese Fälle nicht ab.

## Dokumentzustand und UI

Führen Sie einen eindeutigen Änderungszustand. Eine fehlgeschlagene Speicherung darf ihn nicht löschen. Wird das Schließen abgebrochen, bleiben Dokument, Auswahl und Ansichten erhalten.

Wenn eine eigene Titelschaltfläche oder Menüfunktion das Fenster schließen soll, verwenden Sie den dafür nachgewiesenen nativen Nachrichtenpfad. Ein unmittelbares Beenden des Prozesses kann vorhandene Rückfragen und Dokumentmechanismen umgehen.

## Speicherbedarf bei großen Dokumenten

Nicht jedes Dokument muss vollständig und dauerhaft im RAM liegen. Zerlegen Sie große Datenbestände in überschaubare Einheiten und begrenzen Sie gleichzeitig gesperrte Blöcke. Ein Cache benötigt eine Größenobergrenze und eine klare Verwerfungsregel.

VM- oder Datenbankdienste können geeignet sein, wenn sie auf dem Ziel verfügbar sind und ihr Transaktions-/Fehlerverhalten zum Projekt passt. Verwenden Sie solche Dienste nicht allein deshalb, weil ein späteres SDK eine bequeme Klasse dafür anbietet.

## Mindesttests

| Test | Erwartung |
|---|---|
| Speichern und erneut öffnen | Fachlicher Inhalt bleibt gleich |
| Unbekannte Version | Verständliche Ablehnung oder definierter Migrationspfad |
| Abgeschnittener Abschnitt | Keine Grenzverletzung und kein Ersatz des offenen Dokuments |
| Größenüberlauf | Frühe, kontrollierte Ablehnung |
| Fehler beim Schreiben | Änderungszustand bleibt erhalten |
| Schließen und Abbrechen | Fenster und Inhalt bleiben bestehen |
| Mehrere Dokumente | Keine Vermischung von Dateihandles oder Objektzuständen |

Halten Sie Beispieldateien klein, reproduzierbar und lizenzrechtlich eindeutig. Testdateien mit absichtlich ungültigen Längen gehören in Tests; kennzeichnen Sie sie entsprechend.

