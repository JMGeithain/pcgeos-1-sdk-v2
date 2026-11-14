# Skalare C-Bibliothek

[English](README.md)

Dieses Beispiel übersetzt eigenen freistehenden C-Code mit Open Watcom und
Glue in eine Bibliothek im nativen PC/GEOS-1.x-Dateiformat. Es benötigt keine
System-Header, Laufzeitinitialisierung, Heap, importierte Bibliothek oder moderne
GEOS-C-Hülle. Die exportierte Funktion rotiert eine 16-Bit-Prüfsumme um fünf
Bit nach links und verknüpft das niederwertige Byte des zweiten Arguments mit
XOR. `ChecksumStepC(0x1234, 0x56)` ergibt beispielsweise `0x46d4`.

Nach der Installation der Werkzeugkette im SDK-Hauptverzeichnis ausführen:

```sh
perl sdk.pl build --project examples/math-c
perl sdk.pl inspect build/g1mathc/g1mathc.geo
perl tools/omf_audit.pl build/g1mathc/00-checksum.obj
```

Die native Ausgabedatei heißt `build/g1mathc/g1mathc.geo`. Der festgelegte
Compiler erzeugt 27 Byte ausführbaren Code; die Beispieldatei umfasst 370 Byte.
Das sind Datei- und Codegrößen, keine Messwerte für den geladenen Kernel oder
den zusätzlichen Speicherbedarf für Handles und Ressourcen. Der Baubericht
gibt ausdrücklich an, ob die native Laufzeitumgebung getestet wurde.

## Exportvertrag

Exportordinal 0 ist `_ChecksumStepC` bei Offset null in Ressource `ALGORITHM`.
Diese Aufrufkonvention gehört diesem Beispiel. Sie definiert weder eine C-API
für GEOS-Systemroutinen noch die Eignung von SDK-2.x-Headern für GEOS 1.x.

| Eigenschaft | Vertrag |
| --- | --- |
| C-Deklaration | `unsigned short __far __cdecl ChecksumStepC(unsigned short state, unsigned short byte_value)` |
| Argumente | Erst `byte_value`, dann `state` auf den Stack legen; ferner Aufruf |
| Stackrahmen | Rücksprung-IP bei BP+2; Rücksprung-CS bei BP+4; state bei BP+6; byte_value bei BP+8 |
| Ergebnis | AX, 16 Bit |
| Stackbereinigung | Aufrufer entfernt nach `RETF` vier Argumentbytes |
| Veränderlich | AX, BX, CX, DX, ES und arithmetische Flags |
| Erhalten | SI, DI, BP, DS; SS und ausgeglichener Stack |

Das Projekt verwendet `-0 -ms -s -zu -zl -zld -ecc -nt=ALGORITHM -nc=CODE`.
`-0` wählt 8086-Befehle; `-zu` erlaubt unterschiedliche SS- und DS-Segmente.
Das Abschalten von Stackprüfung und Standardbibliotheken macht beliebige
C-Laufzeitaufrufe nicht zulässig: Dieser kleine Quelltext besitzt weder externe
Symbole noch Fixups. Die Objektprüfung weist solche Abhängigkeiten zurück,
anstatt eine DOS-C-Laufzeit einzubinden.

Die GP-Datei verwendet `type library, single` und festen, gemeinsam nutzbaren,
schreibgeschützten Code. Das spätere Attribut `c-api` wird nicht gesetzt. Da es
nichts zu initialisieren gibt, fehlt ein Initialisierer. Ob dies mit dem
vorgesehenen nativen Loader übereinstimmt, muss dort weiterhin geprüft werden.
Der ungebundene Build trägt Kernelprotokoll 0.0. Strukturprüfung und die folgenden
Tests bescheinigen keine native Ladefähigkeit.

## Test des erzeugten Codes wiederholen

```sh
perl tests/algorithms/verify_c_geodes.pl --kind c \
  --geode build/g1mathc/g1mathc.geo \
  --report validation/math-c-execution.json
```

Der Test führt den tatsächlich gelinkten Export für 67.096 Fälle aus. Er prüft
alle 16-Bit-Zustände, höhere Argumentbits, unterschiedliche SS/DS, Registererhalt,
fernen Rücksprung und begrenzte Stack-Schreibzugriffe. Die 8086-Befehlsprüfung
gilt für genau diese 27 Byte. Ein begrenzter reiner Perl-Interpreter führt nur die geprüften Beispielanweisungen außerhalb von GEOS aus. Er prüft weder den nativen Loader noch eine vollständige CPU oder physische Laufzeiten.

Das [gemischte Beispiel](../math-mixed/README.de.md) zeigt eine
Registerschnittstelle mit Assembler-Hülle und tatsächlicher Ressourcenrelokation.
