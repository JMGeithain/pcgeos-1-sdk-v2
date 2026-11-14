# Reviewed FreeGEOS host patches

[Deutsch](#deutsch)

`freegeos-ilp32-g1.patch` is the human-readable review. The JSON companion is
the same change in a small, standard-library-only application format. The
bootstrap checks the bundle digest in `toolchains/freegeos.lock.json`, then
checks complete before/after SHA-256 digests for each file after normalizing
CRLF line endings to LF. It never applies a fuzzy patch.

These changes target the pinned FreeGEOS **host tools**, not a GEOS runtime:

| File | Change and reason |
|---|---|
| `Tools/glue/library.c` | For explicit `-G 1`, restore the existing `IS_KERNEL` classification for a legacy kernel import definition. The remaining linker already has the 1.x kernel relocation path. Later-format links reject that input. Actual 1.x import definitions remain separately required. |
| `Tools/glue/main.c` | Replace the unavailable Watcom Linux monotonic-clock call with a time-based serial; `SOURCE_DATE_EPOCH` explicitly selects a deterministic serial. |
| `Tools/utils/printf.c` | Use `fputc` instead of depending on another C library's internal `FILE` layout. Keep the GEOS-specific formatter. |
| `Tools/include/compat/string.h`, `Tools/include/config.h` | Make BSD `bzero`/`bcopy`/`bcmp` calls use declared ISO C functions throughout the old utility code. Otherwise an implicit call can mismatch Watcom's register calling convention. |
| `Tools/glue/msobj.c` | Consume exactly two-byte no-debug OMF comment markers `80 A1` and `80 E9` from the tested Watcom compiler. They contain no CodeView/Borland debug payload; selecting those debug parsers caused a crash or lost public symbols. Full debug records keep their original paths. |
| `Tools/glue/parse.y`, generated `parse.c` | Clear the complete fixed long-name buffer before setting an explicit title. The old action cleared 33 of 36 bytes, leaving three bytes of the default output path in padding and making output hashes depend on that path. |

The build uses Open Watcom's Linux headers in `lh/`, its Linux target libraries
and an ILP32 Linux executable format. Packing and enum options are recorded in
the lock file. Compiling these sources unmodified with a 64-bit `long` does not
establish correct on-disk structures.

The bootstrap assembles and links an import-free probe with actual Esp/Glue.
This proves the host pipeline can emit a 1.x-format library. It does not prove
that a particular 1.x loader accepts it, or supply GUI class definitions, API
ordinals, C veneers, GOC/UIC compatibility, or a runtime.

Upstream source retains its original license and individual notices. No
upstream executable or QEMU executable is included in this repository.

The source context in these patches is from the pinned FreeGEOS repository;
its [Apache-2.0 license](UPSTREAM-LICENSE.txt) accompanies the patches. Relevant
source notices identify Berkeley Softworks (1989), GeoWorks (1991), Geoworks
(1996), and, in `printf.c`, the following retained notice:

> Copyright 1988 Regents of the University of California
>
> Permission to use, copy, modify, and distribute this software and its
> documentation for any purpose and without fee is hereby granted, provided
> that the above copyright notice appear in all copies. The University of
> California makes no representations about the suitability of this software
> for any purpose. It is provided "as is" without express or implied warranty.

## Deutsch

`freegeos-ilp32-g1.patch` enthält die lesbare Fassung. Die JSON-Datei enthält
dieselben Änderungen für die Anwendung ohne externes Patch-Programm. Das
Bootstrap prüft zuerst die Prüfsumme des Pakets und danach die vollständigen
SHA-256-Prüfsummen jeder Quelldatei vor und nach der Änderung. Zeilenenden
werden auf LF vereinheitlicht; eine unscharfe Patch-Anwendung findet nicht
statt.

Die Änderungen betreffen die **Host-Werkzeuge**, nicht das GEOS-Laufzeitsystem:

- Die vorhandene `IS_KERNEL`-Behandlung wird ausschließlich mit `-G 1` wieder
  aktiviert. Passende echte 1.x-Importdefinitionen bleiben erforderlich.
- Der Linker kann mit `SOURCE_DATE_EPOCH` eine feste Seriennummer erzeugen.
- Die Ausgabe verwendet `fputc`, statt den internen Aufbau von `FILE` aus einer
  fremden C-Bibliothek vorauszusetzen.
- Alte BSD-Speicherfunktionen werden über deklarierte ISO-C-Funktionen
  aufgerufen, damit Watcoms Register-Aufrufkonvention korrekt bleibt.
- Die exakt zwei Byte langen OMF-Kommentare `80 A1` und `80 E9` des getesteten
  Watcom-Compilers werden als Marker ohne Debug-Daten behandelt. Vollständige
  Debug-Datensätze behalten ihren bisherigen Verarbeitungspfad.
- Der vollständige Namenspuffer wird vor dem Setzen eines expliziten Titels
  gelöscht. Drei Füllbytes enthielten zuvor Reste des Standard-Ausgabepfads.

Gebaut wird mit Watcoms Linux-Headern aus `lh/`, Linux-Bibliotheken und einem
ILP32-Ausgabeformat. Die Optionen stehen in der Lock-Datei. Ein erfolgreicher
64-Bit-Build allein beweist keine korrekten Dateistrukturen.

Ein echtes Esp/Glue-Probeprojekt prüft den Host-Baupfad. Dieser Test ersetzt
weder die Ausführung auf einem konkreten 1.x-System noch dessen API- und
GUI-Definitionen. Upstream-Lizenzhinweise bleiben erhalten; das Repository
enthält keine Upstream- oder QEMU-Programmdateien.
