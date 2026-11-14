# Wiederhergestellte Referenzanwendungen: Erkenntnisse und Herkunft

[Handbuch](README.md) · [English](../en/recovered-references.md)

Die nachgereichten Quell- und Prüfpakete zu GeoSheet, GNU Chess und der 3D-Bounce-Demo ergänzen die öffentlichen späteren GEOS-Quellen um konkrete Erfahrungen mit der bereitgestellten Ensemble-1.2-Installation. Diese Seite hält daraus abgeleitete technische Erkenntnisse fest. Sie verteilt weder die Original-Runtime noch extrahierte native Objektvorlagen.

Ein erfolgreicher älterer Anwendungsbericht ist kein neuer Test dieses SDK. Maßgeblich für die jetzt ausgelieferten Werkzeuge und Beispiele ist der aktuelle Prüfbericht mit dem jeweiligen Binärhash.

## Welche Quellen untersucht wurden

Die folgenden Pfade bezeichnen Dateien **innerhalb der beigebrachten Referenzarchive**. Diese Archive sind keine Voraussetzung dafür, dieses Handbuch zu lesen, und werden nicht allein durch diese Nennung öffentlich mitgeliefert.

| Referenz | Genaue Quellstelle | Zweck |
|---|---|---|
| GeoSheet | `GeoSheet-PCGEOS1-v02/source/spreadsheet/native/objects/NATIVE-ABI-NOTES.md` | Native Objektblöcke, Dokumentcontroller, Eingabe und Datei-I/O |
| GeoSheet | `GeoSheet-PCGEOS1-v02/source/spreadsheet/toolchain/TOOLCHAIN.md` | 16-Bit-C, gemischte Ressourcen, Relokationen und Callback-Lebensdauer |
| GeoSheet | `GeoSheet-PCGEOS1-v02/LICENSE.txt` | Lizenzumfang des neu geschriebenen Codes und ausdrückliche Ausnahmen |
| GNU Chess | `GNUChess-Ensemble1-MoveEntry/DEVELOPMENT/PORTING.txt` | Native einzeilige Eingabe, Tastaturfokus, Formularzustand und Prüfumfang |
| GNU Chess | `GNUChess-Ensemble1-MoveEntry/COPYING.txt` | Enthaltener GPL-3.0-Lizenztext; tatsächliche Quellhinweise bleiben maßgeblich |
| 3D Bounce | `3D-Bounce-PC-GEOS-8086/Source/Measurement/TIMER-ABI.md` | Tick-Zähler, Timerereignisse und Warteschlangenverhalten |
| 3D Bounce | `3D-Bounce-PC-GEOS-8086/README.md` und `TEST-REPORT.md` | Getrennte Angaben zu Dateigröße, Scratchbedarf, Emulatorprofil und Messgrenzen |

## Der konkrete Versionsbezug

Die GeoSheet-Notizen nennen die untersuchte Runtime mit Kernelprotokoll 622.3, UI-Protokoll 693.0 und Motif-Protokoll 693.1. Die Timeranalyse nennt für ihr ursprüngliches `KERNEL.EXE` den SHA-256:

```text
c2cc8952cdb01d0f459bf281ee3b78f8ce9464aba0b58c3758f8c73e24fb6eb5
```

Diese Werte bezeichnen konkrete Referenzen. Sie sind keine allgemeine Konstantentabelle für jede GEOS-1.x-Ausgabe. Prüfen Sie die tatsächlich vorliegenden Dateien und den vom SDK unterstützten Profilumfang. Eine spätere Quelle kann einen symbolischen Namen erklären; der alte Binärpfad muss dessen Verwendung auf dem Ziel belegen.

## Native Objektblöcke nicht mit 2.x-Vorlagen verwechseln

Einige für die untersuchten 1.2-Objektblöcke dokumentierte Unterschiede sind klein, aber entscheidend:

| Beobachtung | Bedeutung für eigene Werkzeuge |
|---|---|
| Chunk-Anordnung mit Vierbyte-Ausrichtung | Nicht lediglich an Zweibytegrenzen weiterpacken |
| Chunk-Länge einschließlich des vorangestellten Zweibyte-Längenworts | Nutzdatenlänge und gespeicherte Länge getrennt behandeln |
| `FFFFh` als leerer, bereits zugeteilter Handle; `0000h` als unbenutzter Eintrag | Nicht beide Werte als dieselbe leere Position zusammenfassen |
| Klassenbezug als native Kennung plus UI-Exportposition | Eine Klassenreferenz ist kein gewöhnlicher C-Funktionszeiger |
| Unterschiedliche Kennungen für denselben Objektblock, andere Ressourcen und den Prozess | Optr-Retargeting braucht Formatwissen, keine pauschale Zahlenersetzung |
| Letztes Geschwister verweist mit einem markierten Elternbezug zurück | Objektketten einschließlich ihres Abschlusses validieren |

Die Referenznotizen dokumentieren unter anderem die native Klassenkennung `3000h`, den gleichen Block mit `4000h` sowie ressourcenbezogene Kennungen auf Basis `1000h`. Diese Angaben erklären den untersuchten Objektkodierungspfad; sie begründen keine beliebige C-Instanzstruktur. Für ein neues Originalbeispiel sollen Ressourcen aus eigenen Deklarationen erzeugt werden, statt BOUNCE- oder NOTEPAD-Objektpayloads in ein neues Repository zu kopieren.

Die ursprünglichen Untersuchungen bestätigten ein unverändertes Pack-/Entpack-Roundtrip für die verwendeten Referenzblöcke. Ein solcher Test ist auch für einen neuen Builder wertvoll. Zusätzlich braucht es eine Prüfung erreichbarer Objekte, gültiger Klassen- und Chunkbezüge, korrekter Eltern-/Geschwisterketten und tatsächlicher Darstellung im Ziel.

## Eigene Menüs, Eingaben und Nachrichten

Die Referenzanwendungen zeigen, dass ein sichtbares Ergebnis nicht allein aus einem vermeintlichen Popup-Flag folgt. Native Hinweise, Objektketten und Kontext müssen gemeinsam stimmen. Bei kopierten oder neu angelegten Objekten können sich Chunknummern ändern; verwenden Sie die vom Builder erzeugten Metadaten statt fest angenommener Adressen.

Die GNU-Chess-Eingabe verwendet den alten nativen Textpfad. Die Notizen halten besonders fest, dass ein „gesamten Text lesen“-Aufruf eine Länge zurückgibt, ohne automatisch ein abschließendes NUL-Byte zu schreiben. Ein eigener Parser muss deshalb die Rückgabelänge prüfen, am richtigen Ort terminieren und seine Puffergröße an die native Eingabegrenze koppeln.

Auch das Verhalten ist Teil des Vertrags: Eingabe bei Fokusverlust, Eingabe bei Enter und eine ausdrückliche Bestätigungsaktion sind verschiedene Ereignisse. Ein Rechen- oder Suchvorgang darf nicht unbemerkt durch eine bloße Änderungsbenachrichtigung ausgelöst werden. Zustände wie „beschäftigt“ müssen sowohl im Handler als auch in den tatsächlich bedienbaren Steuerelementen berücksichtigt werden.

## Dokumentcontroller: Empfänger und Lebensdauer zählen

Die GeoSheet-Dokumentnotizen unterscheiden FileBox, Modellcontroller und Prozess-Callbacks. Dass zwei Objekte dieselbe Methodenzahl behandeln, macht sie nicht austauschbar. Eine an den falschen Empfänger gesendete „Save As“-Zahl kann einen anderen Übergang auslösen.

Praktische Regeln daraus:

- Den aktiven Dokumentbezug nur in dem dafür belegten Lebenszyklus etablieren und nicht aus jedem Callbackargument neu ableiten.
- Bereits geöffnete Dateihandles nicht als neu von der Anwendung zu schließende Handles behandeln, wenn der Controller sie besitzt.
- Fehler nach dem tatsächlich verwendeten Statusvertrag weitergeben; ein beliebiger Registerwert ist nicht automatisch ein Handle oder eine Fehlernummer.
- Abbrechen eines Dialogs darf keinen dauerhaft hängen gebliebenen Exportmodus zurücklassen.
- Ein erfolgreicher „truncate and write“-Pfad ist keine atomare Speicherung und bietet ohne weitere Maßnahmen keinen Rollback bei vollem Datenträger.

Die Referenz kennzeichnet einen direkten Zugriff auf interne Dialog-Implementierungsdaten nach einem nativen Fehler ausdrücklich als entfernt. Solche Notizen sind keine Erlaubnis, den verworfenen Zugriff als neue öffentliche API zu übernehmen.

## C-Ressourcen und Callback-Zeiger

Die ältere GeoSheet-Werkzeugkette übersetzt einen freestanding 16-Bit-C-Kern und ordnet Code-/Datenframes danach nativen Ressourcen zu. Ihre genauen Optionen, Helfer und Rückgabeverträge sind ein eigener Buildpfad; sie dürfen nicht mit dem kleinen skalaren Watcom-Pfad der SDK-Bibliotheksbeispiele gleichgesetzt werden.

Ein besonders wichtiger Befund betrifft gespeicherte physische Callback-Zeiger. Wenn C-Daten eine Segment-/Offset-Adresse auf Assemblercode behalten, darf deren Lebensdauer nicht kürzer sein als die gespeicherte Referenz. Das Referenzprojekt nutzte dafür feste Callback-eigene Coderessourcen und einen negativen Test mit erzwungener Verschiebung. Ein abstrakter Methodenaufruf, dessen Ziel bei jedem Aufruf neu aufgelöst wird, ist ein anderer Vertrag.

Auch Relokationen müssen aus eindeutigen Quellen stammen. Die GeoSheet-Notizen beschreiben, wie ein Bytefolgen-Sucher zufällige Befehlsdaten für einen Import hielt. Gelabelte echte Operanden beziehungsweise die tatsächlichen Linkermetadaten sind verlässlicher als die Suche nach einem einzelnen Opcodebyte im gesamten Ressourceninhalt.

## Timer und Messungen

Die Bounce-Notizen belegen für ihre konkrete Kernelreferenz einen 32-Bit-Tick-Zähler mit hohem Wort in `BX` und niedrigem Wort in `AX`. `DX` ist dort nicht das hohe Wort. Sie untersuchen außerdem, dass gleichartige anstehende kontinuierliche Timerereignisse im beobachteten Pfad zusammengefasst beziehungsweise ersetzt werden können.

Das sind zwei unterschiedliche Entwurfsfragen: Eine Warteschlange kann begrenzt bleiben, während eine Animation bei Überlast trotzdem langsamer läuft. FPS, abgeschlossene Präsentationen, Timerereignisse und physikalische Simulationsschritte dürfen nicht als dieselbe Größe gezählt werden.

Übernehmen Sie keine ältere Bildrate als SDK-Leistungswert. Ein aktueller Test muss dieselbe Binärdatei, einen dokumentierten Emulator beziehungsweise Rechner, vollständige Speicher-/Treiberangaben und einen definierten Messablauf verwenden. Die alten Berichte unterscheiden bereits zwischen physischer Hardware, Emulator-Arbeitsbudget, konventionellem Speicher und zusätzlichem Swap.

## Lizenz- und Veröffentlichungsgrenzen

Die GeoSheet-MIT-Lizenz erfasst den dort neu verfassten Quellcode und die Dokumentation. Ihr Geltungsbereich nimmt unter anderem die beigebrachte GeoWorks-Runtime, extrahierte native Vorlagen, upstream-PC/GEOS-Quellen und Watcom-Helfer ausdrücklich aus. GeoCalc-abgeleitete Bestandteile behalten zudem ihre Apache-2.0-Hinweise.

Daraus folgt für dieses SDK:

1. Technische Fakten und neu geschriebene Erklärungen können mit Herkunft dokumentiert werden.
2. Bei einer tatsächlichen Übernahme von MIT-Quellcode sind dessen Lizenz- und Urheberhinweise zu erhalten.
3. Ursprüngliche native Ressourcen oder Befehlssequenzen werden nicht durch einen benachbarten MIT-Text neu lizenziert.
4. GNU-Chess-Komponenten sind gesondert anhand ihrer GPL- und Quellhinweise zu behandeln.
5. Compiler, Bibliothekshelfer, öffentliche GEOS-Quelle und Runtime behalten jeweils ihre eigenen Bedingungen.

Die neuen SDK-Beispiele müssen daher ihren eigenen Ressourcenquelltext, ihre tatsächlich verwendeten Imports, ihren Buildpfad und ihre aktuellen Tests offenlegen. Die Referenzarchive liefern Erfahrungen und Nachweise für die Untersuchung; sie sind kein Freibrief, fremde Programme unter einem neuen Namen zu verteilen.

