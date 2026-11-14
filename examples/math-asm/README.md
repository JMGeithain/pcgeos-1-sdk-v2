# Import-free assembly library / Importfreie Assemblerbibliothek

## English

`math.asm` uses **Esp syntax**, not NASM syntax. `.8086` restricts the assembled
instruction set. The official linker's 1.x output mode must be selected explicitly;
its default is a later GEOS format. Build this project through the SDK's documented
build command, rather than using a system DOS linker.

`AddWords` is ordinal 0 because it is the first `export` in `math.gp`. Its own
register ABI is:

| Value | Contract |
|---|---|
| Input | `AX = a`, `BX = b`, unsigned 16-bit values |
| Result | `AX = (a + b) mod 65536` |
| Preserved | `BX`, `CX`, `DX`, `SI`, `DI`, `BP`, `DS`, `ES`, caller stack |
| Flags | Unspecified |
| Calling style | Far call to the loaded export; far return |

This is an explicitly defined **application/library ABI**, not a claim that a
modern C compiler can call arbitrary native GEOS functions. The example imports
no OS functions, needs no C runtime, and contains no GUI application object. It
will not launch a window when double-clicked in GeoManager. Load/use it from a
properly matched native client during target validation.

The token is a local example identifier. Choose a unique token and the appropriate
manufacturer ID for a distributed product. Host assembly, linking and structural
checks do not establish native loader compatibility: see the validation report.

## Deutsch

`math.asm` verwendet **Esp-Syntax**, keine NASM-Syntax. `.8086` begrenzt den
Befehlssatz. Beim offiziellen Linker muss das Ausgabeformat für GEOS 1.x ausdrücklich
gewählt werden; die Voreinstellung erzeugt ein späteres GEOS-Format. Verwenden Sie
den dokumentierten SDK-Buildbefehl und keinen gewöhnlichen DOS-Linker.

`AddWords` hat die Ordinalnummer 0, da es der erste `export` in `math.gp` ist.
Die eigene Register-ABI ist:

| Wert | Vereinbarung |
|---|---|
| Eingabe | `AX = a`, `BX = b`, vorzeichenlose 16-Bit-Werte |
| Ergebnis | `AX = (a + b) mod 65536` |
| Erhalten | `BX`, `CX`, `DX`, `SI`, `DI`, `BP`, `DS`, `ES`, Aufrufer-Stack |
| Flags | Nicht festgelegt |
| Aufruf | Far-Aufruf des geladenen Exports; Far-Rückkehr |

Dies ist eine ausdrücklich festgelegte **Anwendungs-/Bibliotheks-ABI**. Sie
bedeutet nicht, dass ein moderner C-Compiler beliebige native GEOS-Funktionen
direkt aufrufen kann. Das Beispiel importiert keine Betriebssystemfunktionen,
benötigt keine C-Laufzeitbibliothek und enthält kein GUI-Anwendungsobjekt. Ein
Doppelklick im GeoManager öffnet daher kein Fenster. Laden und verwenden Sie die
Bibliothek bei der Zielsystemprüfung aus einem passend erstellten nativen Client.

Der Token dient nur als lokale Beispielkennung. Wählen Sie für veröffentlichte
Produkte einen eindeutigen Token und eine passende Hersteller-ID. Assemblierung,
Linken und Strukturprüfung auf dem Entwicklungssystem beweisen keine native
Ladekompatibilität; beachten Sie den Prüfbericht.
