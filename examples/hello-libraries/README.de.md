# Native Prüfung der Bibliotheksintegration

Dieses GUI erweitert das [Hello-Beispiel](../hello-asm/README.de.md) und
importiert die Assembler-, C- und gemischte Bibliothek über deren eigene
ABIs.`PASS` erscheint nur, wenn alle fünf Vergleiche in `library_probe.inc`
stimmen; sonst erscheint `FAIL`. Damit werden echte Loader-Imports, Far-Aufrufe,
C-Argumentbereinigung und die gemischte Ressourcengrenze ausgeübt.

Im SDK-Hauptverzeichnis die Kernelanforderung an eine passende eigene native
Referenz binden und die Anwendung gegen das genaue Zielprofil bauen:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-c --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-mixed --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/hello-libraries --target-root /pfad/GWSVGA
```

GEOS sauber beenden. In einer Testkopie der Installation die Bibliotheken
`build/g1math/g1math.geo`,`build/g1mathc/g1mathc.geo` und
`build/g1mixed/g1mixed.geo` nach `SYSTEM` kopieren; die Anwendung
`build/g1probe/g1probe.geo` gehört nach `WORLD`. GEOS neu starten und
`GEOS 1 Library Probe` öffnen. Bibliotheken sind Abhängigkeiten und werden
nicht durch Doppelklick gestartet. Der dauerhafte Anwendungsname lautet
`g1probe.app`.

Kernel ist implizit, UI hat Importindex 0, die drei Beispielbibliotheken haben
Indizes1 bis3. Native Bibliotheksaufrufe verwenden Relokation14h. Alle drei
Bibliotheksprotokolle sind1.0. Die jeweiligen READMEs beschreiben Register-,
Segment- und Stackverträge. Weder der C-Export noch diese Prüfung bietet eine
allgemeine C-System-API.

Der aktuelle Prüfbericht nennt tatsächlich ausgeführte native Tests. Ein
erfolgreicher Build oder eine korrekte Dateistruktur belegen allein keinen
ausgeführten und bestandenen Integrationstest.
