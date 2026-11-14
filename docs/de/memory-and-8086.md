# Speicher, Segmentierung und 8086/8088

[Handbuch](README.md) · [English](../en/memory-and-8086.md)

Der 8086/8088 zwingt zu klaren Größen- und Lebensdauerentscheidungen. GEOS kann Ressourcen bewegen oder auslagern; dadurch wird Speicherverwaltung leistungsfähiger, aber ein unbedacht gespeicherter Segmentzeiger gefährlicher.

Als konzeptionelle Ergänzung dienen die öffentlichen Kapitel über [Handles](https://bluewaysw.github.io/pcgeos/Concepts/chandle.html), [Speicherverwaltung](https://bluewaysw.github.io/pcgeos/Concepts/cmemory.html) und [lokalen Speicher](https://bluewaysw.github.io/pcgeos/Concepts/clmem.html). Verwenden Sie für konkrete 1.x-Flags und Strukturgrößen nur das ausgewählte Zielprofil.

## Größen immer auf das Ziel beziehen

Ein einzelner 16-Bit-Offset beschreibt keinen beliebig großen linearen Puffer. Große Datenmengen müssen in geeignete Blöcke aufgeteilt werden. Verlassen Sie sich nicht auf die Zeigerarithmetik eines gewöhnlichen 64-Bit-Hostprogramms.

| Größe | Prüfen |
|---|---|
| Code-/Datenressource | Formatgrenzen, Segmentgrenze und Linkerbeschränkungen |
| Stapel | Tiefe Aufrufketten, lokale Felder, Rekursion und Callbackpfade |
| Globale Daten | Dauerhaft residenter Zustand pro Anwendung oder Bibliothek |
| Pro-Fenster-Zustand | Wachstum mit der Zahl geöffneter Fenster |
| Temporärer Puffer | Spitzenbedarf und Verhalten bei Fehlschlag |
| Datei-/VM-Daten | Pufferung und gleichzeitige gesperrte Blöcke |

Ein kleineres `.geo` beweist keinen kleineren Spitzenbedarf im RAM. Ressourcen können geteilt, geladen, verworfen oder gleichzeitig resident sein. Zusätzlich entstehen Kernel- und Treiberdaten.

## Bewegliche Blöcke sicher verwenden

Arbeiten Sie mit begrenzten Sperrbereichen. Nach einer Entsperrung ist ein zuvor ermittelter Rohzeiger nicht mehr als dauerhaft gültig zu behandeln. Ebenso kann eine Operation auf lokalem Speicher dessen Inhalte umorganisieren.

Ein robustes Muster ist:

1. Die passende Block- oder Objektreferenz besitzen.
2. Den dokumentierten Zugriff herstellen.
3. Benötigte Daten lokal prüfen oder kopieren.
4. Keine unnötigen fremden Aufrufe innerhalb des kritischen Bereichs durchführen.
5. Den Zugriff symmetrisch beenden.
6. Später bei Bedarf erneut über die Referenz auflösen.

Eine Sperre ist keine kostenlose Bequemlichkeit. Dauerhaft gesperrte Blöcke können Verschiebung und Auslagerung behindern. Sperren fremder Objektblöcke während eines Zeichen- oder Nachrichtenpfads können außerdem die Sperrreihenfolge zwischen Threads verändern.

## Lokaler Speicher und Chunks

Ein Chunk ist nicht mit einer festen Adresse innerhalb des Blocks gleichzusetzen. Wenn eine lokale Speicheroperation die Tabelle oder Daten verschiebt, muss die aktuelle Adresse erneut aufgelöst werden. Geben Sie weder einen Chunk-Handle noch einen Block-Handle an eine Routine weiter, die einen linearen Zeiger erwartet.

Dokumentieren Sie bei eigenen Datenstrukturen, welche Felder Identifikatoren und welche temporäre Adressen enthalten. Eine kleine Typabstraktion oder ein Namensschema wie `...Handle`, `...Chunk` und `...Ptr` kann bereits viele Fehlübergaben verhindern.

## 8086-Instruktionsgrenze durchgängig einhalten

Stellen Sie das Prozessorziel im Assembler und im C-Compiler ein. Prüfen Sie anschließend nicht nur Ihren handgeschriebenen Code, sondern auch Startup, Hilfsfunktionen und tatsächlich erreichbare Fremdmodule. Beispielsweise gehört `PUSHA` nicht zum 8086/8088-Befehlssatz.

Eine Disassemblierung muss ausführbaren Code von Tabellen, Bitmaps und Zeichenketten unterscheiden. Zufällige Datenbytes lassen sich oft als ungültige oder neuere Befehle interpretieren; eine ungeführte Suche über die gesamte Datei erzeugt daher irreführende Befunde. Umgekehrt darf Code nicht durch eine großzügige Datendeklaration aus der Prüfung verschwinden.

Ein 8086-Zielbuild ist ohne 8086-Zieltest nur ein Teilnachweis. Verwenden Sie im Emulator wirklich das entsprechende CPU-Modell und einen dafür geeigneten Treiber. Der Emulatorname allein beschreibt den ausgeführten Befehlssatz nicht.

## Mit 640 KB testen

Beschreiben Sie die gesamte Konfiguration: konventioneller Speicher, XMS, EMS, UMB, Disk-Swap, Zahl gleichzeitig geöffneter Programme und verwendete Treiber. „640 KB“ ohne diese Angaben ist unvollständig.

Prüfen Sie besonders:

- Start bei bereits geladenen Anwendungen.
- Wiederholtes Öffnen und Schließen von Fenstern und Dokumenten.
- Große Eingaben und eine abgelehnte oder fehlgeschlagene Zuweisung.
- Unterbrechen und erneutes Aufnehmen langer Arbeiten.
- Beibehalten eines ungespeicherten Dokuments nach einem abgebrochenen Schließen.
- Gleichbleibende Funktion nach vielen Iterationen, nicht nur nach dem ersten Start.

Messen Sie Datei-, Ressourcen-, globale und pro Instanz entstehende Größen getrennt. Wenn der gesamte Spitzenbedarf nicht instrumentiert wurde, schreiben Sie genau das in den Bericht.

## Optimieren ohne Funktionsverlust

Beginnen Sie bei Lebensdauer und Datenrepräsentation, nicht bei einer vollständigen Assemblerumschreibung. Teilen Sie seltenen Code ab, reduzieren Sie doppelte Tabellen und geben Sie temporäre Daten früh frei. Ein kompakter Datenzustand kann mehr sparen als ein paar kürzere Befehle.

Bewahren Sie Referenztests für die fachlichen Ergebnisse auf. Eine kleinere Suchstruktur, ein reduzierter Cache oder eine andere Zahlendarstellung kann das Verhalten verändern. Ein behaupteter „reiner Speicherumbau“ benötigt deshalb weiterhin Tests für Grenzfälle und Ergebnisse.

