# Native 1.x file inspection / Native 1.x-Dateiprüfung

## English

The inspection commands are original, read-only Perl code. The separate
`tools/lib/PCGEOS/Geos1/Writer.pm` module creates fresh 1.x containers from explicitly authored
resources for the bounded Ensemble 1.2 application backend. These tools do not
replace an assembler, import-library generator or native runtime tests.

From the repository root:

```sh
perl tools/geos1/cli.pl inspect build/math-asm/g1math.geo
perl tools/geos1/cli.pl inspect build/math-asm/g1math.geo --summary --output build/math.json
perl tools/geos1/cli.pl extract build/math-asm/g1math.geo --resource 2 --output build/code.bin
perl tools/geos1/cli.pl profile path/to/UI.GEO path/to/IM.GEO --output build/runtime-profile.json
perl tools/geos1/cli.pl check-imports path/to/PROGRAM.GEO --profile build/runtime-profile.json
perl tools/geos1/cli.pl bind-kernel build/math-asm/g1math.geo --reference path/to/original/UI.GEO --output build/bound/g1math.geo
perl tools/geos1/cli.pl verify-target path/to/GWSVGA
prove -Itools/lib -r tests/native_format
```

Use real paths from your own runtime. The positional `profile` arguments are
explicit GEO file paths, not a request to search other directories. Do not pass
`KERNEL.EXE`: that DOS executable has a different layout. Names and long names
are shown as a lossless byte display; the code does not claim a complete GEOS
character-encoding conversion. Profiles currently require ASCII module names.

Exit status is 0 for the requested structural operation, 1 for a failed observed
import check or an explicitly requested partial profile, and 2 for invalid input
or an I/O error. `--keep-going` writes a partial profile and retains rejected-file
reasons; a partial profile still exits 1. Outputs cannot overwrite input files,
including symlink/hardlink aliases.

### What the inspector proves

| Disk property | 1.x interpretation |
|---|---|
| Signature | `C7 45 CF 53` (high-bit `GEOS`) |
| Standard executable type | Word at `0004h` is 0, not the 2.x value 1 |
| Fixed geode header | `0120h` bytes |
| Resource count | Word at `0118h`, duplicated at `00D0h` |
| Import count | Word at `0114h`, duplicated at `00D2h` |
| Export count | Word at `0112h`, duplicated at `00D4h` |
| Import table | At `0120h`; 14 bytes per library |
| Export table | After imports; 4 bytes per entry: offset, resource ID |
| Resource descriptor table | After exports; four arrays totaling 10 bytes per resource |
| Resource positions | Absolute file positions; do not subtract a 2.x 256-byte file header |
| Relocation position | Resource file position plus resource size rounded up to 16 bytes |
| Core resource 0 | May have zero payload and share its disk anchor with DGROUP |
| DGROUP resource 1 | Normally paragraph-aligned by Glue |

The descriptor arrays are word sizes, dword positions, word relocation byte
counts and word allocation flags. They are **four arrays**, not interleaved
10-byte C structures. Each relocation is `(info byte, extra byte, offset word)`.
The high info nibble identifies kernel/library/resource; the low nibble describes
the fixup. The library index is distinct from its exported ordinal. A movable
resource-call operand stores the resource ID first and target offset second;
it is not an ordinary pre-relocated x86 far address.

The code rejects the distinct `C7 45 C1 53` 2.x+ signature, inconsistent duplicate
fields, truncated/overlapping resources, invalid table extents and malformed
relocations. A raw resource extraction excludes padding and relocation records.
It never executes the extracted bytes.

### What it does not prove

A protocol/catalog match does not establish API signatures, register preservation,
C name decoration, C calling conventions, object-instance layouts, instruction
compatibility, native loading or application behavior. The JSON retains
`runtime_tested: false` and `abi_certified: false` where applicable. Export names
and signatures remain null: the tool does not invent them from ordinal numbers.

The unit-test constructor is deliberately synthetic. Passing those tests proves
parser behavior and malformed-file guards, not that a synthetic file is a useful
program. Library examples use the selected Esp/Glue build flow. The dedicated
application backend assembles original 8086 code and creates fresh native object
and class records for the exact supplied Ensemble 1.2 target.

### Fresh container API

`PCGEOS::Geos1::Writer::build_geode` accepts resource hash references with explicit
relocation records, import hash references, exports and header fields. It
creates a zero-origin header from the source-backed layout, duplicates the
required fields and writes the four resource-table arrays. It never opens an
existing application as a template. The independent inspector reparses the
result before it is returned. Process classes, TPD, object chunks and code must
already be valid for the intended runtime; container consistency cannot prove
those semantics. Pointer pairs in this API are `(resource, offset)`; the
application object's offset is its chunk handle.

`PCGEOS::Geos1::Target::verify_target` additionally checks the exact pinned user-owned
kernel/UI/Motif files against `targetprofiles/supplied-ensemble12.json`. The DOS
kernel is hashed, not decoded as a GEO. The return field `files_match` identifies
the observed target; it does not certify an application.

### Explicit kernel protocol binding

An import-free library built without a `geos.ldf` can have a zero kernel protocol
even when Glue writes the native 1.x container. `bind-kernel` can create a separate
copy using the **observed required kernel protocol** of an original 1.x GEO that
you supply. It changes only the word pair at `00CCh`; it does not change the
library's own protocol at `0010h`/`00EEh`, resource data or relocation records.

Binding is restricted to library-only files with no imported libraries and no
recorded kernel/library relocations. An existing different nonzero requirement
is rejected; an identical one permits an idempotent copy. Both inputs, including
hardlink/symlink aliases, are protected. Output is written through a temporary
file and atomic rename. The JSON records both input hashes, output hash, exact
byte changes and `runtime_tested: false`.

This is not authentication of the reference, generation of API definitions or
proof of native loadability. A reference only establishes a requirement observed
in that file. Manually embedded addresses or unsupported instructions are outside
the check. Do not use this operation to make a 2.x program appear compatible, to
rewrite an application's ABI, or to replace real target-system testing.

### Primary format evidence

Pinned upstream commit: `260b33dcfcac15b7ecfdf04242cb0abf029ec269`.

- [File headers](https://github.com/bluewaysw/pcgeos/blob/260b33dcfcac15b7ecfdf04242cb0abf029ec269/Tools/include/os90File.h)
- [Geode, import and relocation structures](https://github.com/bluewaysw/pcgeos/blob/260b33dcfcac15b7ecfdf04242cb0abf029ec269/Tools/include/geode.h)
- [Glue's separate 1.x/2.x writer](https://github.com/bluewaysw/pcgeos/blob/260b33dcfcac15b7ecfdf04242cb0abf029ec269/Tools/glue/geo.c)

## Deutsch

Die Prüfkommandos lesen und prüfen Dateien. Das getrennte Modul `tools/lib/PCGEOS/Geos1/Writer.pm`
erzeugt neue 1.x-Dateicontainer aus ausdrücklich erstellten Ressourcen für das
begrenzte Ensemble-1.2-Anwendungsbackend. Die Werkzeuge ersetzen weder Assembler
noch Importbibliotheken oder Tests auf einem laufenden GEOS-System.

Die obigen Befehle werden im Repository-Hauptverzeichnis ausgeführt. Verwenden Sie
die tatsächlichen Pfade zu Ihren eigenen Laufzeitdateien. `profile` erhält eine
ausdrückliche Liste von GEO-Dateien und durchsucht keine anderen Verzeichnisse.
`KERNEL.EXE` ist eine DOS-Datei mit anderem Aufbau und wird nicht so ausgewertet.
Modulnamen und lange Namen erscheinen als verlustfreie Byte-Darstellung; dies ist
keine vollständige Umsetzung des GEOS-Zeichensatzes. Profile verlangen derzeit
ASCII-Modulnamen.

Der Rückgabecode 0 bestätigt die angeforderte Strukturprüfung. Code 1 kennzeichnet
einen fehlgeschlagenen Vergleich beobachteter Importanforderungen oder ein
ausdrücklich angefordertes Teilprofil. Code 2 bedeutet ungültige Eingaben oder
einen Ein-/Ausgabefehler. `--keep-going` schreibt ein Teilprofil mit Fehlergründen
und liefert dennoch Code 1. Eingabedateien dürfen auch über symbolische Links
oder Hardlinks nicht überschrieben werden.

### Dateiaufbau

Die native 1.x-Signatur lautet `C7 45 CF 53`, nicht die 2.x-Signatur
`C7 45 C1 53`. Der feste Geode-Header ist `0120h` Bytes lang. Die Anzahl der
Ressourcen steht bei `0118h`, die Importanzahl bei `0114h` und die Exportanzahl
bei `0112h`; redundante Headerfelder werden abgeglichen.

Auf den Header folgen Importeinträge mit jeweils 14 Bytes, Exporte mit jeweils
4 Bytes und die Ressourcentabelle. Diese besteht aus vier getrennten Arrays:
Word-Größen, Dword-Dateipositionen, Word-Längen der Relokationstabellen und
Word-Speicherattribute. Sie ist kein Array aus 10-Byte-C-Strukturen.

1.x-Ressourcenpositionen sind **absolute Dateipositionen**. Ein 256-Byte-Header
eines späteren Formats darf nicht abgezogen werden. Relokationen stehen nach der
auf 16 Bytes aufgerundeten Ressourcengröße, nicht unmittelbar nach jedem logisch
letzten Datenbyte. Die Kernressource 0 kann leer sein; DGROUP ist Ressource 1.

Ein Relokationseintrag enthält Info-Byte, Zusatz-Byte und Offset-Word. Die
Bibliotheksnummer ist von der Exportordinalnummer zu unterscheiden. Bei einem
Aufruf einer beweglichen Ressource steht zuerst die Ressourcen-ID und danach
der Zieloffset; dies ist noch keine normale geladene x86-Far-Adresse.

### Aussagekraft

Das Werkzeug erkennt widersprüchliche Headerfelder, abgeschnittene oder
überlappende Ressourcen und fehlerhafte Relokationen. Eine Ressourcenextraktion
enthält nur die logischen Nutzdaten, weder Auffüllbytes noch Relokationen, und
führt diese Bytes nicht aus.

Ein passender Modul-/Protokollvergleich beweist weder API-Signaturen noch
Registererhaltung, C-Aufrufkonventionen, Objektlayouts, Befehlssatzkompatibilität
oder native Ladbarkeit. Entsprechende JSON-Felder bleiben ausdrücklich
`runtime_tested: false` und `abi_certified: false`. Symbolnamen und Signaturen
werden nicht aus Ordinalnummern erfunden.

Die Testdateien werden synthetisch erzeugt. Die Tests prüfen den Parser und seine
Fehlerbehandlung, nicht die Ausführbarkeit eines solchen Testbildes. Tatsächliche
Beispielbibliotheken müssen durch den gewählten Esp-/Glue-Build entstehen.
Die oben verlinkten Primärquellen belegen die Strukturfelder; die Commit-ID
fixiert die dabei verwendete Quellversion.

### Neue Dateicontainer

`build_geode` in `PCGEOS::Geos1::Writer` erzeugt Header und Ressourcentabellen
eigenständig aus Ressourcen- und Import-Hashreferenzen. Es liest keine bestehende
Anwendung als Vorlage. Das Ergebnis wird erneut durch den unabhängigen Parser
geprüft. Code, Prozessklasse, TPD und Objektblöcke müssen zur Ziellaufzeit passen;
eine gültige Dateistruktur beweist diese Semantik nicht. Zeigerpaare der API
lauten `(Ressource, Offset)`, beim Anwendungsobjekt `(Ressource, Chunk-Handle)`.

`verify_target` aus `PCGEOS::Geos1::Target` prüft die Dateiidentität des eigenen
Kernel-/UI-/Motif-Satzes anhand des festgelegten Zielprofils. `files_match`
bestätigt die untersuchten Dateien, nicht die Ausführbarkeit jeder Anwendung.

### Kernel-Protokoll ausdrücklich übernehmen

Eine importfreie Bibliothek ohne `geos.ldf` kann trotz nativem 1.x-Dateiformat ein
Kernel-Protokoll von 0.0 enthalten. `bind-kernel` erzeugt auf Wunsch eine getrennte
Kopie mit der **beobachteten Kernel-Anforderung** einer von Ihnen bereitgestellten
originalen 1.x-GEO-Datei. Ausschließlich das Word-Paar bei `00CCh` wird geändert.
Das eigene Bibliotheksprotokoll bei `0010h`/`00EEh`, Ressourcen und Relokationen
bleiben unverändert.

Zulässig sind nur reine Bibliotheken ohne Bibliotheksimporte und ohne erfasste
Kernel-/Bibliotheksrelokationen. Eine andere vorhandene Nichtnull-Anforderung
wird nicht ersetzt. Eine identische Anforderung erlaubt eine bytegleiche Kopie.
Beide Eingaben sind auch über Link-Aliase geschützt; die Ausgabe entsteht durch
eine temporäre Datei und atomare Umbenennung. Das JSON dokumentiert Hashes und
geänderte Bytes; `runtime_tested` bleibt ausdrücklich `false`.

Die Referenz wird dadurch nicht authentifiziert. Es entstehen keine API-Header
oder Signaturen, und eine native Ladbarkeit ist nicht bewiesen. Manuell eingebaute
Adressen oder ungeeignete CPU-Befehle bleiben außerhalb dieser Prüfung. Diese
Funktion darf keine 2.x-Anwendung als kompatibel ausgeben und ersetzt weder eine
korrekte ABI noch die Prüfung auf dem Zielsystem.
