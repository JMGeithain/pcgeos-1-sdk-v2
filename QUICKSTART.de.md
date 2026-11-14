# Schnellstart

[English](QUICKSTART.md) · [Ausführlicher Einstieg](docs/de/quickstart.md)

Perl ab Version 5.26 ist erforderlich. Verwenden Sie für den getesteten nativen Werkzeugpfad Linux/x86-64: Linux direkt, WSL2 unter Windows oder einen passenden Linux-Gast unter macOS. Die [Hostanleitung](docs/de/host-setup.md) beschreibt die Einrichtung einschließlich `qemu-i386` für die 32-Bit-Hostwerkzeuge.

Unter Debian/Ubuntu im Linux-Gast:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
```

Im SDK-Hauptverzeichnis, mit Ihrem geeigneten Perl-Interpreter:

```sh
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
perl sdk.pl doctor --require-toolchain
perl sdk.pl check
perl sdk.pl test
perl sdk.pl build --project examples/hello-asm
```

Die GUI entsteht als `build/g1hello/g1hello.geo`. Prüfen Sie die eigene Runtime und bauen Sie gegen die festgelegte Ensemble-1.2-Dateiidentität:

```sh
perl sdk.pl verify-target /pfad/zum/eigenen/GWSVGA
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
```

Die eigene Runtime wird geprüft und nicht in die Ausgabe kopiert.

GEOS sauber beenden, `g1hello.geo` nach `WORLD` einer passenden Testinstallation kopieren, GEOS neu starten und `GEOS 1 SDK Hello` öffnen. Erwartet werden ein blauer Kopf mit `HELLO GEOS`, eigene Rechtecke sowie kleine Zeichen `SDK1` und `8086`. Der [Anwendungsleitfaden](docs/de/native-applications.md) erklärt Aufbau und Repainttests.

Die C-, Assembler- und Mischbeispiele bauen Sie gesondert:

```sh
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

Diese Ausgaben sind Bibliotheken und liegen unter `build/g1math/`, `build/g1mathc/` und `build/g1mixed/`. Danach können Sie die [native Bibliotheksprobe](examples/hello-libraries/README.de.md) bauen. Sie benötigt die drei bewusst an eine passende Kernelanforderung gebundenen Bibliotheken nach `SYSTEM` und zeigt nach ihren Ergebnisvergleichen `PASS` oder `FAIL`. Bibliotheken werden nicht einzeln per Doppelklick gestartet.

Die [Validierung](VALIDATION.md) nennt ausgeführte Tests und Grenzen. Ein erfolgreicher Build oder Hashvergleich allein ist kein nativer Ausführungsnachweis. Der Adapter stellt einen begrenzten eigenen Ensemble-1.2-Ausschnitt bereit; vollständige allgemeine 1.x-/GOC-/System-C-Deklarationen sind nicht enthalten.

Ein eigenes Projekt erzeugen Sie im SDK-Stamm ohne vorhandene Dateien zu überschreiben:

```sh
perl sdk.pl new --name myapp --language gui --directory ../myapp
perl sdk.pl check --project ../myapp
perl sdk.pl build --project ../myapp --target-root /pfad/zum/eigenen/GWSVGA
```

`--language asm`, `c` oder `mixed` erzeugt stattdessen eine Rechenbibliothek. Der Starter übernimmt eigene Beispielquellen, Manifest und MIT-Lizenz. Der Name muss klein geschrieben, DOS-tauglich und höchstens acht Zeichen lang sein; ein vorhandener Zielordner wird abgelehnt. Prüfen Sie vor einer Veröffentlichung Anzeigename, Token und die dokumentierte ABI.

Optionale Editorunterstützung:

```sh
perl editor/vscode/pack_vsix.pl
code --install-extension editor/dist/pcgeos1-language-support-0.2.0.vsix
```

Öffnen Sie den SDK-Stamm und richten Sie gegebenenfalls `pcgeos1.perlExecutable` ein. In einem vertrauenswürdigen Arbeitsbereich bietet der optionale lokale Sprachserver API-Vervollständigung, Hover-Hinweise und begrenzte Quellmeldungen. Weiterführend: [IDE-Einrichtung](docs/de/ide-integration.md) und [deutsches Handbuch](docs/de/README.md).
