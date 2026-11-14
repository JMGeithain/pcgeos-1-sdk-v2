# Schnellstart

[Handbuch](README.md) · [English](../en/quickstart.md)

Dieser Ablauf baut drei eigene Rechenbibliotheken und ein natives Grafikfenster für das ausdrücklich beobachtete Ensemble-1.2-Ziel. Anschließend kann eine zweite Anwendung alle drei Bibliotheken aufrufen. Sie benötigen eine eigene passende DOS-/GEOS-Installation für die nativen Schritte; die Runtime wird nicht mitgeliefert.

## 1. Host vorbereiten

Erforderlich sind Perl ab Version 5.26 und Git oder ein entpacktes Release-Archiv. Der getestete Werkzeugabruf verwendet Linux/x86-64. Unter Windows nutzen Sie WSL2 mit x86-64-Linux, unter macOS den beschriebenen x86-64-Linux-Gast. Ein macOS-/Windows-Editor kann dabei mit der Buildumgebung verbunden sein. Die ausführlichen Schritte stehen unter [Windows, macOS und Linux](host-setup.md).

Unter Debian/Ubuntu im Linux-Buildsystem:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
perl -v
uname -m
```

Prüfen Sie Perl 5.26 oder höher und `x86_64`. Installieren Sie gegebenenfalls einen zusätzlichen geeigneten Interpreter. Eine alte Distributionsversion wird nicht durch dieselben Befehlsnamen neuer. Verwenden Sie einen einfachen Projektpfad, beispielsweise `~/geosdev/pcgeos1-sdk`.

Die folgenden Befehle werden im SDK-Hauptverzeichnis ausgeführt. `perl` bezeichnet den installierten Perl-Interpreter; falls er nicht im `PATH` steht, verwenden Sie seinen absoluten Pfad. Die nativen Linux-Werkzeuge laufen im Linux-Kontext.

## 2. Projekt prüfen und Werkzeuge installieren

```sh
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
perl sdk.pl doctor --require-toolchain
```

`toolchain install` lädt festgelegte offizielle Archive, prüft ihre Hashes und baut die vorgesehenen Hostwerkzeuge. Dazu gehören Open Watcom, die wiederhergestellten Esp-/Glue-Werkzeuge und NASM. Der `qemu-i386`-Runner führt bei Bedarf die statischen 32-Bit-Linux-Hostwerkzeuge aus. Er startet weder DOS noch GEOS und ist kein 8086-Zieltest. Prüfen Sie den Runnerpfad, falls Ihre Distribution anders paketiert.

Ein fehlendes Werkzeug soll als solches gemeldet werden. Lesen Sie übersprungene Tests und Grenzen in der Ausgabe; ein ausgelassener nativer Schritt ist kein erfolgreicher Laufzeittest. Details und Offlinearchive: [Werkzeugkette](toolchain.md).

## 3. Die drei Bibliotheken bauen

```sh
perl sdk.pl check --project examples/math-asm
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

| Projekt | Ausgabe | Lernziel |
|---|---|---|
| `examples/math-asm` | `build/g1math/g1math.geo` | Esp, Ressourcen und eigene Register-ABI |
| `examples/math-c` | `build/g1mathc/g1mathc.geo` | Freestanding 16-Bit-C mit eigener FAR-`__cdecl`-ABI |
| `examples/math-mixed` | `build/g1mixed/g1mixed.geo` | FAR-C-Hilfsfunktion mit einem Assembleradapter |

Diese Dateien sind Bibliotheken und haben kein eigenes startbares Fenster. Sie enthalten weder eine gewöhnliche DOS-C-Laufzeit noch automatisch GEOS-System-C-Wrapper. Ein zunächst ungebundenes Kernelprotokoll 0.0 wird im Bericht kenntlich gemacht; es ist von ihrem eigenen Modulprotokoll 1.0 zu unterscheiden.

Für die spätere native Bibliotheksprobe binden Sie die Kernelanforderung ausdrücklich an eine passende eigene `.GEO`-Referenz:

```sh
perl sdk.pl build --project examples/math-asm --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-c --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
perl sdk.pl build --project examples/math-mixed --kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO
```

Der Build erhält eine ungebundene Kopie und protokolliert Referenzhash und beobachtete Anforderung. Dies ersetzt weder API- noch Ausführungstests. Übergeben Sie hier nicht `KERNEL.EXE`; diese MZ-Datei ist keine gewöhnliche native `.GEO`-Bibliothek.

## 4. Das erste native Fenster bauen

Der GUI-Adapter `ensemble12` erzeugt neue Prozess- und Objektressourcen. Er verwendet keine kommerzielle Anwendung als Binärvorlage. Voraussetzung ist die genaue Runtime-Identität des ausgelieferten Zielprofils mit Kernel-Anforderung 622.3 und UI 693.0.

```sh
perl sdk.pl verify-target /pfad/zum/eigenen/GWSVGA
perl sdk.pl check --project examples/hello-asm
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
perl sdk.pl inspect build/g1hello/g1hello.geo --summary
```

Das Profil prüft `KERNEL.EXE`, `SYSTEM/UI.GEO` und `SYSTEM/MOTIF.GEO` anhand ihrer Hashes. Der Build liest die Identität, kopiert aber keine Runtime in das Ergebnis. Ein abweichendes Ziel benötigt einen eigenen geprüften Adapter-/Profilnachweis. Eine erfolgreiche Dateiprüfung ist noch keine native Ausführung.

Beenden Sie GEOS sauber. Kopieren Sie `build/g1hello/g1hello.geo` nach `WORLD` einer Testkopie der passenden Installation. Starten Sie GEOS neu und öffnen Sie `GEOS 1 SDK Hello`. Erwartet werden ein blauer Kopf mit `HELLO GEOS`, eigene farbige Rechtecke sowie `SDK1` und `8086`. Die Zeichnung bleibt bei einer Fenstervergrößerung in festen Koordinaten.

Prüfen Sie Freilegen, Verschieben, Größenänderung, Minimieren/Wiederherstellen, Programmwechsel, Schließen und erneutes Starten. Für tatsächlich ausgeführte native Prüfungen gilt der [Prüfbericht](../../VALIDATION.md). NASM `CPU 8086` begrenzt eigenen Code; es bestätigt nicht die Prozessoranforderungen sämtlicher System- und Treiberroutinen.

## 5. C und Assembler gemeinsam nativ aufrufen

Nach den gebundenen Bibliotheksbuilds aus Schritt 3:

```sh
perl sdk.pl build --project examples/hello-libraries --target-root /pfad/zum/eigenen/GWSVGA
```

Beenden Sie GEOS sauber. Kopieren Sie die drei Bibliotheken nach `SYSTEM` der Testinstallation und `build/g1probe/g1probe.geo` nach `WORLD`. Starten Sie GEOS und öffnen Sie `GEOS 1 Library Probe`. `PASS` erscheint, wenn die fünf eingebauten Vergleiche stimmen; andernfalls erscheint `FAIL`.

Damit lassen sich tatsächliche Loader-Imports, Registerübergaben, FAR-C-Aufruf und Stackbereinigung der eigenen Beispiele gemeinsam ausüben. Eine erfolgreiche Probe beweist keine vollständige allgemeine C-System-ABI. Lesen Sie die [Bibliotheksverträge](c-and-assembly.md), bevor Sie Parameter oder Register ändern.

## 6. Eigene Anwendung beginnen

Legen Sie mit dem Starter einen neuen Ordner an:

```sh
perl sdk.pl new --name myapp --language gui --directory ../myapp
perl sdk.pl check --project ../myapp
perl sdk.pl build --project ../myapp --target-root /pfad/zum/eigenen/GWSVGA
```

`new` übernimmt eigene Beispielquellen, Manifest und MIT-Lizenz. Es verweigert einen vorhandenen Zielordner. `--language asm`, `c` oder `mixed` erzeugt stattdessen den jeweiligen Bibliotheksstarter. Der Projektname muss klein geschrieben, DOS-tauglich und höchstens acht Zeichen lang sein.

Ändern Sie bewusst Titel, Kennung und anschließend zunächst eine Farbe oder eine einfache Zeichenoperation. Der aktuelle Monikergenerator verwendet ASCII und die Pixelzeichentabelle nur einen begrenzten Zeichenvorrat.

Die vollständige Erklärung zu `project.json`, NASM-Makros, fünf Ressourcen, Update-Lebenszyklus und zusätzlichen Imports steht unter [Native Anwendung bauen](native-applications.md). Für einen eigenen Rechenkern beginnt der nächste Abschnitt mit einer kopierten Esp-Bibliothek. Ändern Sie nicht gleichzeitig Compiler, Aufrufkonvention, Speicherverwaltung und UI-Struktur.

## 7. Die erste eigene Bibliothek

Kopieren Sie das Assemblerbeispiel in einen neuen Projektordner. Unter Linux, WSL oder im Linux-Gast:

```sh
cp -R examples/math-asm examples/mycalc
```

Unter Windows können Sie denselben Ordner im Explorer kopieren. Ändern Sie anschließend bewusst:

1. In `examples/mycalc/project.json` den Projektnamen in `mycalc`. Der CLI-Name ist klein geschrieben und DOS-tauglich, höchstens acht Zeichen.
2. In der zugehörigen `.gp`-Datei den permanenten Namen auf `mycalc.lib`.
3. Den langen Anzeigenamen sowie die Beispiel-Tokenkennung. Für eine Veröffentlichung benötigen Sie eine eigene geeignete Kennung und Hersteller-ID.
4. Den eigenen Code, zunächst ohne den dokumentierten Registervertrag von `AddWords` zu ändern.

Für die unveränderten Dateinamen des Assemblerbeispiels sieht die Projektbeschreibung so aus:

```json
{
  "schema": 1,
  "name": "mycalc",
  "kind": "library",
  "import_free": true,
  "cpu": "8086",
  "gp": "math.gp",
  "sources": [
    {"language": "esp", "path": "math.asm"}
  ],
  "expected_export_count": 1
}
```

Die kopierten Quelldateinamen dürfen vorerst unverändert bleiben, solange `project.json` auf die richtigen Dateien zeigt. Bauen und prüfen Sie das neue Projekt:

```sh
perl sdk.pl check --project examples/mycalc
perl sdk.pl build --project examples/mycalc
perl sdk.pl inspect build/mycalc/mycalc.geo --summary
```

Im Verzeichnis `build/mycalc/` entstehen das Geode und die Berichte `build-report.json`, `geode-inspection.json` und `build.log`. Sie zeigen die tatsächliche Ausgabe, Werkzeugaufrufe und Prüfergebnisse. Ändern Sie nicht gleichzeitig permanenten Bibliotheksnamen, Exportreihenfolge, Aufrufkonvention und Berechnung.

Dieses Beispiel bleibt eine Bibliothek. Um es aus einer GUI aufzurufen, ergänzen Sie bewusst einen Import und einen Adapter mit genau diesem Exportvertrag. [hello-libraries](../../examples/hello-libraries/README.de.md) zeigt den entsprechenden Weg für die drei gelieferten Bibliotheken. Das bloße Ändern des `kind`-Felds wandelt keine Bibliothek in eine Anwendung um.
