# Bibliothek aus C und Assembler

[English](README.md)

Dieses Beispiel verbindet denselben eigenen skalaren C-Algorithmus wie `math-c`
mit einer Registerschnittstelle in Esp-Assembler. Zusätzlich exportiert es eine
sättigende Additionsfunktion in Assembler. Jede Sprache besitzt eine eigene
feste Coderessource: `ALGORITHM` enthält die ferne C-Funktion `_ChecksumFar`,
`BridgeCode` die exportierten Assemblerfunktionen. Glue erzeugt die tatsächliche
interne Segmentrelokation für den fernen Aufruf zwischen beiden Ressourcen.

Im SDK-Hauptverzeichnis ausführen:

```sh
perl sdk.pl build --project examples/math-mixed
perl sdk.pl inspect build/g1mixed/g1mixed.geo
perl tools/omf_audit.pl build/g1mixed/00-checksum.obj
```

Die native Datei `build/g1mixed/g1mixed.geo` umfasst mit den festgelegten
Werkzeugen 436 Byte, darunter 27 Byte C-Code und 35 Byte Assemblercode. Das ist
keine Messung des geladenen Speicherbedarfs. Beide Ressourcen sind fest, damit
der Vertrag des direkten fernen Aufrufs eindeutig bleibt. Größere Anwendungen
müssen vor der Umstellung auf verschiebbare Ressourcen die Ressourcen- und
Aufrufkonventionen des Zielkernels prüfen.

| Exportordinal | Name | Eingaben | Ergebnis | Erhalten |
| --- | --- | --- | --- | --- |
| 0 | `ChecksumStep` | AX: Zustand; DX: Wert | AX: Zustand um 5 Bit nach links rotieren, XOR mit niederwertigem Byte des Werts | BX, CX, DX, SI, DI, BP, DS, ES |
| 1 | `SaturatingAdd` | AX: a; DX: b | AX: min(a+b, 65535) | BX, CX, DX, SI, DI, BP, DS, ES |

Beide Exporte verwenden ferne Aufrufe und `RETF`; Flags sind nicht festgelegt.
Diese Registerverträge gehören dem Beispiel und keiner GEOS-System-API. Die
Assembler-Hülle sichert Register, legt die C-Argumente von rechts nach links auf
den Stack, ruft die C-Funktion fern auf, entfernt vier Argumentbytes und stellt
die Register wieder her. Die C-Funktion verwendet `__far __cdecl`; nach ihrem
Prolog liegen die Argumente bei BP+6 und BP+8. Sie darf AX, BX, CX, DX, ES und
Flags ändern; die Hülle erhält an der Exportgrenze alle aufgeführten Register.

Getrennte C- und Esp-Ressourcen vermeiden außerdem die Annahme, beide
Objektformate würden den Symboltyp einer nahen Prozedur gleich behandeln. Der
Build verarbeitet das wirkliche Watcom-OMF-Objekt unmittelbar. Er wandelt keine
Codebytes in Quelltext um und entfernt keine externen Verweise stillschweigend.
`omf_audit.pl` prüft, dass die bewusst eingeschränkte C-Komponente keine externen
Verweise, Fixups, nichtleeren Daten oder Laufzeit-Hilfsfunktionen benötigt.

Die Bibliothek hat keine Importe und keinen Initialisierer. Ihr ungebundenes
Kernelprotokoll ist 0.0. Sie setzt das spätere Attribut `c-api` nicht und bindet
keine SDK-2.x-C-Hüllen ein. Native Ladefähigkeit sowie ein gegebenenfalls nötiger
Initialisierer und das Protokoll müssen auf der vorgesehenen GEOS-1.x-Laufzeit
geprüft werden; Build und CPU-Test belegen dies nicht.

## Test des erzeugten Codes wiederholen

```sh
perl tests/algorithms/verify_c_geodes.pl --kind mixed \
  --geode build/g1mixed/g1mixed.geo \
  --report validation/math-mixed-execution.json
```

Der Test liest die beiden tatsächlich gelinkten Ressourcen, prüft die exakten
begutachteten 8086-Codebytes und Exporte und ersetzt ausschließlich die erwartete
Segmentrelokation der festen Ressource durch seine Testladeadresse. Ein begrenzter reiner Perl-Interpreter führt nur die geprüften Beispielanweisungen aus. Er prüft
67.096 Prüfsummenfälle und 4.160 Fälle der sättigenden Addition aus. Registererhalt
und begrenzte Stack-Schreibzugriffe werden bei unterschiedlichem SS und DS
geprüft. Der Test implementiert weder GEOS-Loader noch Ressourcenverwaltung,
startet das Betriebssystem nicht und misst keine echten 8086/8088-Laufzeiten.
