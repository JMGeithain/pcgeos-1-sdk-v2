# Eigenes natives GUI-Beispiel

Die Anwendung öffnet ein natives Ensemble-1.2-Fenster und zeichnet eigene
Rechtecke und kleine Pixelzeichen. Prozessklasse sowie Application-, Primary-
und View-Objekte werden neu erzeugt. Serialisierte Oberflächen, Icons oder
Befehlsfolgen eines kommerziellen Programms sind keine Build-Eingaben.

Im SDK-Hauptverzeichnis:

```sh
perl sdk.pl toolchain install
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
```

Das Zielverzeichnis muss dem dokumentierten Profil entsprechen. Es wird
geprüft, aber nicht in die Ausgabe kopiert. Die Datei lautet
`build/g1hello/g1hello.geo`, der dauerhafte Name `g1hello.app`, der Anzeigename
`GEOS 1 SDK Hello`. GEOS sauber beenden, die Datei in `WORLD` einer Testkopie
ablegen, neu starten und mit GeoManager öffnen.

Erwartet werden ein blauer Kopf mit `HELLO GEOS`, ein türkis/grüner
Rechteckstapel sowie `SDK1` und `8086`. Prüfen Sie Freilegen, Minimieren und
Wiederherstellen, Größenänderung, Programmwechsel und normales Schließen.
Die Zeichnung hat eine feste Größe und wird bei größerem Fenster nicht
automatisch skaliert. Der aktuelle Prüfbericht nennt tatsächlich getestete
Ziele und CPU-Einstellungen. NASM `CPU 8086` belegt allein nicht die
Prozessoranforderungen sämtlicher System- und Treiberroutinen.

`hello.nasm` kennzeichnet die NASM-Syntax gegenüber ESP-Quelltext. Lesen Sie
den [Backend-Vertrag](../../tools/ensemble12/README.md), bevor Sie native
Aufrufe ergänzen. Allgemeine GOC-/C-Systemwrapper und beliebige1.x-Ausgaben
gehören nicht zum belegten Umfang dieses Beispiels.
