# Bibliotheken und Rückportierung

[Handbuch](README.md) · [English](../en/libraries-and-backporting.md)

Eine Bibliothek ist ein guter Einstieg für eine begrenzte, überprüfbare GEOS-Schnittstelle. Die importfreien Mathematikbeispiele dieses Repositorys sollen den Übersetzungs- und Exportpfad zeigen. Sie sind keine durch Doppelklick startbaren GUI-Anwendungen und ersetzen kein vollständiges UI-SDK.

Die öffentliche Dokumentation zu [Bibliotheken](https://bluewaysw.github.io/pcgeos/Concepts/clibr.html) erläutert die Architektur einer späteren SDK-Generation. Die tatsächlich benötigten 1.x-Header und Protokolle müssen gesondert vorliegen.

## Eine öffentliche Bibliotheksschnittstelle entwerfen

Halten Sie öffentliche Ein- und Ausgaben klein. Dokumentieren Sie für jeden Export Symbol, Version, Aufrufart, Datentypen, Fehlerfälle und Eigentum an Puffern. Ein Aufrufer soll nicht auf private globale Variablen oder Instanzlayouts zugreifen müssen.

Bei einer etablierten Schnittstelle müssen exportierte Positionen und ihre Bedeutung stabil bleiben. Entfernen oder verschieben Sie keinen alten Export stillschweigend. Ob und wie ein Protokoll erhöht werden muss, hängt vom tatsächlichen GEOS-Vertrag ab; die bloße Änderung einer Versionszahl repariert keinen ABI-Bruch.

Geben Sie außerdem an, ob eine Routine wiederholt beziehungsweise gleichzeitig aufrufbar ist. Ein versteckter globaler Arbeitspuffer kann für ein Einzelbeispiel ausreichen und bei zwei Anwendungen zu gegenseitiger Beschädigung führen.

## Zuerst Abhängigkeiten inventarisieren

Eine Rückportierung sollte mit einer Tabelle beginnen:

| Benötigte Fähigkeit | Bisherige Umsetzung | 1.x-Nachweis | Entscheidung |
|---|---|---|---|
| Berechnung | Eigener C-Kern | Keine OS-Abhängigkeit, aber Zieltypen prüfen | Unverändert übernehmen und testen |
| Fenster-/Dokumentmodell | Neuere generische Klassen | Noch offen | Original-1.x-Unterlagen oder Ersatzentwurf erforderlich |
| Dateioperation | Bibliotheksroutine | Zielprotokoll und Vertrag prüfen | Adapter kapseln |
| Sondergrafik | Späterer Treiberpfad | Noch offen | Native Primitive oder klar begrenzte Alternative |
| Hilfsfunktion | C-Laufzeit | Compiler-/Laufzeitnachweis erforderlich | Freestanding-Variante oder nachgewiesener Helfer |

Diese Tabelle ist absichtlich kein fertiger API-Katalog. Sie zwingt dazu, fehlende Nachweise sichtbar zu lassen. „Ähnlicher Name vorhanden“ ist keine abgeschlossene Zeile.

## In kleinen Schichten zurückportieren

1. Trennen Sie fachliche Logik und GEOS-Anbindung.
2. Erstellen Sie Referenztests für Ergebnisse und Dateiformate.
3. Prüfen Sie jede Betriebssystemabhängigkeit gegen das Zielprofil.
4. Bauen Sie einen kleinen Adapter für die nachgewiesene ältere Funktion.
5. Ersetzen Sie fehlende Oberflächenfunktionen ausdrücklich statt implizit.
6. Prüfen Sie zuerst einen minimalen, dann den vollständigen nativen Pfad.

Übernehmen Sie nicht den gesamten modernen Include-Baum, um ein einzelnes Symbol zu erhalten. Damit könnten unbemerkt Strukturdefinitionen, Farbcodierungen, Aufrufmakros und Bibliotheksannahmen aus einer späteren Generation in den Build gelangen.

## Fachliches Verhalten erhalten

Nicht jede Speicheroptimierung ist verhaltensneutral. Geänderte Tabellen, verkleinerte Suchräume, weniger genaue Zahlen oder eine andere Cachepolitik können Ergebnisse beeinflussen. Legen Sie deshalb vor der Optimierung fest, was unverändert bleiben muss.

Beispiele sind reproduzierbare Berechnungsergebnisse, vollständige Spielregeln, Dokumentinhalt und Fehlerbehandlung. UI-Vereinfachungen können zulässig sein, sollten aber als sichtbare Änderungen dokumentiert werden. Eine entfernte Rückfrage zum Speichern ist kein rein kosmetischer Umbau.

## Typische ABI-Fallen

- Gleiche Exportnummer in zwei Bibliotheken bedeutet nicht dieselbe Routine.
- Ein alter Dateikopf und ein neuer Ressourcenblock ergeben zusammen nicht automatisch ein gültiges 1.x-Geode.
- Ein Klassenlayout kann sich ändern, obwohl die sichtbare Funktion gleich heißt.
- Eine feste Bildschirmgröße darf nicht ungeprüft in ein veränderbares Fenster übertragen werden.
- Ein gepufferter Zeiger darf nicht über einen möglichen Verschiebe- oder Entladepunkt hinweg benutzt werden.
- Ein unter einem späteren Treiber erfolgreicher RGB-Test beweist keinen entsprechenden Pfad im ursprünglichen 16-Farben-System.

## Eine Bibliothek freigeben

Liefern Sie den öffentlichen Schnittstellenvertrag, Versions-/Protokollregeln, ein kleines Aufruferbeispiel, die getesteten Werkzeugversionen und die Hashes der geprüften Ausgaben mit. Geben Sie an, ob ein nativer Loaderlauf stattgefunden hat oder ob nur Code-, Objekt- und Formatprüfungen vorliegen.

Ein Import-freier Demonstrationsbuild kann wertvoll sein, auch wenn die GUI-Bindung noch fehlt. Kennzeichnen Sie ihn entsprechend und verwenden Sie ihn nicht als Beleg für sämtliche GEOS-Systemdienste.

