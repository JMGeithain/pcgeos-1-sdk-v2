# Kompatibilität und Nachweisgrenzen

[Handbuch](README.md) · [English](../en/compatibility.md)

„PC/GEOS 1.x“ bezeichnet eine Zielgeneration, keinen universellen ABI-Vertrag für alle späteren GEOS-Dateien. Edition, Sprache, Bibliotheksprotokoll und Treiber können für einen konkreten Test relevant sein. Ein sauberer Kompatibilitätsnachweis nennt die tatsächlichen Eingaben.

## Umfang dieses Release

Die CLI baut drei importfreie Bibliotheken in Esp, C und gemischter Form sowie eigene GUI-Anwendungen über den begrenzten `ensemble12`-Adapter. Dieser Anwendungsweg gilt für die festgelegten Referenzdateien mit Kernel-Anforderung 622.3 und UI 693.0. `--target-root` vergleicht die eigenen Runtime-Dateien mit dem ausgelieferten [Profil](../../targetprofiles/supplied-ensemble12.json). Er kopiert keine proprietäre Runtime in die Ausgabe und prüft keine beliebige andere 1.x-Ausgabe frei.

Die [Include-Dateien](../../include/ensemble12/README.md) enthalten einen eigenen begrenzten Satz numerischer ABI-Werte. `abi.h` liefert keine allgemeine aufrufbare GEOS-C-Systembibliothek. Eine vollständige ursprüngliche 1.x-GOC-/UI-/C-Entwicklungsumgebung und ein allgemeiner Serializer für sämtliche Klassen sind nicht enthalten. Die Herkunft späterer FreeGEOS-Deklarationen bleibt gesondert zu bewerten.

Der Buildstatus und ein Hashvergleich sind von nativer Ausführung zu trennen. Für ausgeführte Runtime-, CPU- und Speichertests gilt der [Prüfbericht](../../VALIDATION.md). Die Bibliotheksausführungstests in `validation/math-*-execution.json` sind gezielte Prüfungen der tatsächlichen Codebytes mit einem begrenzten 8086-Ausführungsmodell; sie sind kein vollständiger PC/GEOS-Loader. Native Prüfungen werden separat protokolliert.

Der Unterbefehl `profile` ist ein Katalogwerkzeug für explizit angegebene `.GEO`-Bibliotheken. Er aktiviert keinen Anwendungscompiler. Die Vergleichsprüfung umfasst beobachtbare Modulnamen und Protokolle, nicht die vollständige Aufruf-ABI. Der im Repository ausgelieferte Release-/Validierungsbericht nennt den tatsächlichen Stand der durchgeführten Tests.

## Nachweise getrennt führen

| Stufe | Erforderlicher Nachweis | Beweist noch nicht |
|---|---|---|
| Quellprüfung | Syntax, Projektstruktur, ausgewählte statische Regeln | Übersetzbarkeit für das Ziel |
| Hosttest | Test läuft mit dokumentiertem Hostwerkzeug | 16-Bit-Verhalten, GEOS-Integration |
| Zielübersetzung | Reproduzierbarer Lauf der passenden Werkzeugkette | Korrekte Imports oder erfolgreiches Laden |
| Format-/ABI-Prüfung | Ressourcen, Protokolle, Relokationen und Aufrufverträge passen zum Zielprofil | Korrektes Zeichnen oder Bedienverhalten |
| Nativer Lauf | Konkrete Binärdatei wurde im dokumentierten 1.x-System ausgeführt | Alle Hardwarevarianten und alle Speicherzustände |
| Hardwaretest | Programm läuft auf der angegebenen physischen Maschine | Andere Treiber oder eine andere Prozessorgeneration |

Testergebnisse dürfen diese Stufen nicht zusammenziehen. Besonders wichtig: Ein 8086-Assemblerprüflauf ist keine Garantie, dass eine verlinkte C-Laufzeit oder ein fremder Grafiktreiber ebenfalls nur 8086-Befehle verwendet.

## Moderne Quellen richtig verwenden

Die aktuelle [FreeGEOS-Quellbasis](https://github.com/bluewaysw/pcgeos) benennt Breadbox Ensemble 4.13 als Ausgangspunkt. Die [öffentliche technische Dokumentation](https://bluewaysw.github.io/pcgeos/) beschreibt ihre Grundlage als SDK 2.0. Deshalb gelten folgende Regeln:

- Architekturtexte können ein Konzept erklären, ohne dessen konkrete 1.x-Strukturgröße zu belegen.
- Ein späterer Header darf nicht allein wegen eines vertrauten Symbolnamens in den 1.x-Include-Pfad übernommen werden.
- Eine spätere Exportposition, Nachrichtenkennung oder Strukturkonstante benötigt einen eigenen Zielnachweis.
- Ein moderner Compiler kann 16-Bit-Code erzeugen und dennoch eine andere Aufrufkonvention oder Laufzeit erwarten.
- Die Fähigkeit eines Linkers, eine Datei zu schreiben, muss vom unterstützten Dateiformat und von den verwendeten Importdaten getrennt geprüft werden.

## Zielprofile statt stiller Annahmen

Ein Zielprofil sollte mindestens enthalten:

1. Name und Ausgabe des Zielsystems sowie Hashes der verwendeten Referenzdateien.
2. Werkzeuge mit Version, Herkunft und Lizenz.
3. Prozessorziel und wirksame Compiler-/Assembleroptionen.
4. Bibliotheken, erforderliche Protokolle und nachgewiesene Exporte.
5. Datenmodelle: Zeigergrößen, Strukturpackung, Aufrufkonvention und Namensdekoration.
6. Unterstützte Buildarten und bekannte Einschränkungen.
7. Tatsächlich ausgeführte Tests und nicht geprüfte Bereiche.

Eine solche Datei ist ein überprüfbarer Vertrag. Sie darf nicht dadurch „repariert“ werden, dass ein fehlendes Ergebnis auf `passed` gesetzt wird.

## Binärdatei, SDK und Runtime sind verschiedene Dinge

Ein Geode kann als Referenz wertvoll sein, ohne einen allgemeinen Entwicklungsumfang bereitzustellen. Aus einer vorhandenen Bibliothek lassen sich beispielsweise einige Import- und Exportdaten untersuchen. Daraus entsteht noch keine vollständige C-Schnittstelle mit Typen, Eigentumsregeln, Fehlercodes und Dokumentation.

Umgekehrt kann ein vollständiges späteres SDK viele Dienste beschreiben, die auf dem älteren Ziel fehlen. Eine Rückportierung beginnt deshalb mit einer Liste tatsächlich benötigter Fähigkeiten. Reduzieren Sie die Oberfläche dieser Liste, statt pauschal den gesamten späteren Headerbestand freizugeben.

## Einen Fehler korrekt melden

Ein guter Bericht enthält den Commit des Projekts, den Buildbericht, den Hash des Geodes, den Emulator beziehungsweise Rechner, die konkrete GEOS-Ausgabe und einen kurzen reproduzierbaren Ablauf. Ein Foto eines Kernelabbruchs allein benennt die Ursache nicht. Geben Sie zusätzlich an, ob weitere Anwendungen geladen waren, ob Swap aktiv war und welche letzte Aktion den Fehler auslöste.

Siehe [API-Nachweise](api-reference.md) und [Teststrategie](debugging-and-testing.md).

