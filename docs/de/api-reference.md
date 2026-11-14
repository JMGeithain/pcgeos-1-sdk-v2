# API-Nachweise und Referenzumfang

[Handbuch](README.md) · [English](../en/api-reference.md)

Diese Seite ist eine Anleitung zur Erweiterung des nachgewiesenen 1.x-Umfangs. Sie ist kein erfundener vollständiger Ersatz für die ursprünglichen GEOS-Header. Nicht belegte Aufrufe bleiben nicht freigegeben.

## Was eine API-Beschreibung enthalten muss

| Feld | Inhalt |
|---|---|
| Dienst | Präzise Funktion und ihr Zweck |
| Bibliothek | Exakte Modulidentität und erforderliches Protokoll |
| Aufrufart | Öffentlicher Import, Objektmethode, Ressourcenroutine oder interner Einstieg |
| Ziel | Untersuchte Ausgabe und Hashes der Referenzdateien |
| Parameter | Register, Stapel, Speicherbereiche und zulässige Werte |
| Rückgabe | Ergebnisse, Flags, Fehlerstatus und volatile Zustände |
| Eigentum | Wer Speicher besitzt, sperrt, kopiert und freigibt |
| Wiedereintritt | Zulässige Threads, Sperren und mögliche Rückrufe |
| Nebeneffekte | Objektänderungen, Grafikzustand, Nachrichten oder Dateiänderungen |
| Nachweis | Quellenstelle, native Analyse und ausgeführte Tests |

Eine Importposition gehört immer zu ihrer Bibliothek. Gleiche Nummern in zwei Importbibliotheken sind nicht austauschbar. Ebenso ist eine Ressourcen-Segmentrelokation etwas anderes als ein Import einer Kernelroutine.

## Verfügbare Dienste inventarisieren

Für ein neues Projekt können folgende Kategorien als Arbeitsliste dienen:

- Geode-Lebenszyklus, Imports, Exporte und Ressourcen.
- Speicherblöcke, lokale Speicherbereiche und Objektreferenzen.
- Nachrichten, Ereignisse, Timer und gegebenenfalls Threads.
- Fenster, Grafikzustand, Zeichenprimitive, Bitmaps und Text.
- Generische UI-Klassen und deren 1.x-Methoden.
- Dateien, Verzeichnisse, VM und eigene Dokumentformate.
- Lokalisierung, Zwischenablage und weitere tatsächlich benötigte Dienste.

Die Liste benennt Themen, nicht automatisch verfügbare Symbole. Streichen Sie unnötige Abhängigkeiten und prüfen Sie den verbleibenden Umfang einzeln. Importfreie Rechenbibliotheken können einen sinnvollen nativen Einstieg bieten, ohne diese Betriebssystemdienste vorauszusetzen.

## Einen neuen Adapter aufnehmen

1. Die gewünschte fachliche Funktion in einer kleinen eigenen Schnittstelle ausdrücken.
2. Einen passenden Dienst im konkreten Ziel nachweisen.
3. Header- und Strukturannahmen gegen die Zielversion prüfen.
4. Den Aufrufvertrag vollständig dokumentieren.
5. Einen kleinen Adapter implementieren.
6. Seine echten erzeugten Bytes und Relokationen prüfen.
7. Normale, Fehler- und Grenzfälle im Ziel ausführen.
8. Den freigegebenen Nachweis mit Quellstand und Hash verbinden.

Wenn die einzige Grundlage eine spätere Dokumentation ist, markieren Sie den Eintrag als konzeptionelle Referenz. Ein plausibel aussehender Header darf nicht als geprüftes 1.x-Binding in den Standard-Include-Pfad gelangen.

## Binäranalyse richtig begrenzen

Eine vorhandene Originaldatei kann zeigen, welches native Dateiformat, welche Importzuordnung oder welche Anweisungsfolge tatsächlich verwendet wird. Sie erklärt jedoch nicht automatisch alle zulässigen Parameter oder alle Eigentumsregeln.

Leiten Sie keine allgemeine API aus einer einzigen Aufrufstelle ab, wenn deren Eingabewerte nur einen Sonderfall abdecken. Suchen Sie nach weiteren Aufrufpfaden und prüfen Sie insbesondere Fehlerbehandlung, Segmentregister, Stapelbereinigung und mögliche Zustandsänderungen.

Ein geparster Binärkopf ist keine Symboltabelle. Ein exportierter Offset ist kein frei erfundener Funktionsname. Prüfsummen stellen Dateigleichheit her; sie ersetzen keine Bedeutungserklärung.

## Was in ein Referenzarchiv gehört

Speichern Sie eigene Notizen, Quellverweise, Hashes, die genaue Herkunft und die zulässigen Testdaten. Verteilen Sie eine ursprüngliche Runtime oder ein historisches SDK nur, wenn die Rechte dafür tatsächlich bestehen. Ein lokaler Nachweis kann mit einer nicht verteilten Referenzdatei arbeiten und deren erwartete Identität dokumentieren.

Siehe [Kompatibilität](compatibility.md), [gemischte Aufrufe](c-and-assembly.md) und [Fehlersuche](debugging-and-testing.md).


## Vorhandene Inspektionsbefehle

Die CLI leitet die folgenden Befehle an die Format- und Profilwerkzeuge weiter:

```sh
perl sdk.pl inspect build/mycalc/mycalc.geo --summary
perl sdk.pl extract build/mycalc/mycalc.geo --resource 0 --output build/inspection/resource0.bin
perl sdk.pl profile /pfad/zu/UI.GEO /pfad/zu/IM.GEO --output build/inspection/runtime-profile.json
perl sdk.pl check-imports /pfad/zum/program.geo --profile build/inspection/runtime-profile.json
```

Die Pfade sind bewusst Beispiele: Verwenden Sie eine eigene Ausgabedatei und die Bibliotheken Ihrer tatsächlichen Zielinstallation. Ressource 0 ist nicht automatisch ausführbarer Anwendungscode; wählen Sie die Ressource anhand des Inspektionsberichts. Auch ein ausgelesener Export liefert ohne weitere Angaben keinen C-Prototyp.

`profile` untersucht native `.GEO`-Bibliotheken. Übergeben Sie **nicht `KERNEL.EXE`**: Diese MZ-Datei hat einen anderen Aufbau und wird durch diesen Parser nicht zu einem allgemeinen Kernel-API-Katalog. Die Profilprüfung vergleicht Modulidentitäten und Protokollangaben; sie beweist keine Ordinalzuordnung, Register-ABI, Strukturgröße oder Verfügbarkeit eines bestimmten Nachrichtenpfads.

Ein importfreies Beispiel hat in dieser Prüfung keine Betriebssystemimports zu erfüllen. Das ist sein begrenzter Aufbau, kein umfassender Nachweis für eine spätere grafische Anwendung.

## Der bereits enthaltene begrenzte Ensemble-1.2-Ausschnitt

Die Datei [ensemble12-abi.json](../../targetprofiles/ensemble12-abi.json) erfasst beobachtete Kernelordinale, Registerverträge, UI-Klassen und Nachrichten für das festgelegte Ziel. Die daraus eigenständig geschriebenen Dateien [abi.inc](../../include/ensemble12/abi.inc), [abi.def](../../include/ensemble12/abi.def) und [abi.h](../../include/ensemble12/abi.h) verwenden NASM-, Esp-/MASM- beziehungsweise C-Syntax.

| Datei | Verwendungszweck | Grenze |
|---|---|---|
| `abi.inc` | Numerische Werte im NASM-Anwendungsweg | Kein vollständiger UI- oder Klassenübersetzer |
| `abi.def` | Numerische Werte für Esp-/MASM-Quelltext | Keine Übernahme späterer Systemdeklarationen |
| `abi.h` | C-Konstanten und vier Byte großer `E12Optr` | Keine aufrufbaren allgemeinen Betriebssystemprototypen |

Klassenordinale gehören zur UI-Importbibliothek; ein gleich nummerierter Kernelaufruf bezeichnet etwas anderes. Die als nur vermutet überlieferte Nachricht `MSG_META_DRAG_SELECT` wird ausdrücklich nicht freigegeben. Auch die enthaltenen Registerverträge verifizieren nicht pauschal jedes erhaltene Register sämtlicher Aufrufe.

```sh
perl sdk.pl verify-target /pfad/zum/eigenen/GWSVGA
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
```

Der erste Befehl prüft die vorgegebenen Runtime-Identitäten. Der zweite baut eine neue Anwendung für genau diesen Zielvertrag. Beides ist von einer nativen Testausführung zu trennen. Für die praktische Nutzung siehe [Native Anwendung bauen](native-applications.md).
