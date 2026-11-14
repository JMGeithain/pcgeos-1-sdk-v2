# Entwicklungsumgebung unter Windows, macOS und Linux

[Handbuch](README.md) · [English](../en/host-setup.md)

Trennen Sie den modernen Entwicklungsrechner vom alten Zielsystem. Editor, Git, Perl und Quellprüfungen laufen auf dem Host. Das erzeugte Programm läuft in einer gesonderten DOS-/GEOS-Installation. Ein DOS-Emulator stellt weder automatisch ein lizenziertes DOS noch PC/GEOS bereit.

## Perl-Mindestversion prüfen

Dieses Repository benötigt Perl ab Version 5.26. Prüfen Sie die tatsächlich gestartete Version mit `perl -v`. Verwendet werden Kernmodule wie `JSON::PP`, `Digest::SHA`, `Test::More` und `IO::Compress::Zip`; eine zusätzliche CPAN-Installation ist nicht erforderlich. Unter macOS genügt das System-Perl, wenn es die Mindestversion erfüllt. Andernfalls installieren Sie ein separates Perl mit Ihrem Paketmanager.

## Gemeinsame Verzeichnisstruktur

Eine praktikable Aufteilung ist:

```text
geosdev/
  pcgeos1-sdk/       öffentliches Projekt und eigener Quellcode
  toolchains/       lokale Compiler- und SDK-Installationen
  runtimes/         getrennte GEOS-Testkopien
  artifacts/        Buildausgaben und Testberichte
```

Behandeln Sie diese Namen als Vorschlag. Maßgeblich sind die Pfade in der ausgelieferten Projektkonfiguration. Prüfen Sie vor einem Git-Commit, dass keine Runtime, kein Swapfile, kein privates SDK und kein fremder Compiler versehentlich erfasst wird.

## Windows: Hostwerkzeuge

1. Installieren Sie Git aus der [offiziellen Distribution](https://git-scm.com/downloads).
2. Installieren Sie für native Editordienste und Hostprüfungen beispielsweise [Strawberry Perl](https://strawberryperl.com/) ab Version 5.26. Öffnen Sie danach ein neues Terminal, damit der Perl-Pfad übernommen wird.
3. Öffnen Sie PowerShell im Projektordner und prüfen Sie:

```powershell
git --version
perl -v
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

4. Installieren Sie [Visual Studio Code](https://code.visualstudio.com/). Öffnen Sie den Projektordner, nicht nur eine einzelne Quelldatei.
5. Installieren Sie die mitgelieferte GEOS-Sprachunterstützung gemäß [Editoranleitung](../../editor/vscode/README-DE.md).

Ein alter 16-Bit-DOS-Compiler läuft nicht automatisch in einer aktuellen 64-Bit-Windows-Konsole. Dafür ist ein geeigneter DOS-Gast nötig. Ein Linux-Buildwerkzeug wiederum benötigt eine Linux-Umgebung; eine Dateiendung oder eine Umbenennung macht daraus keine Windows-Anwendung.

## Windows: Linux-Werkzeuge mit WSL

Wenn das ausgewählte Profil Linux-Werkzeuge verwendet, ist WSL eine sinnvolle Hostumgebung. Die [Microsoft-Anleitung](https://learn.microsoft.com/en-us/windows/wsl/install) beschreibt Voraussetzungen und unterstützte Windows-Versionen.

Bei einer neuen WSL-Installation lautet der zentrale Schritt in einer PowerShell mit den dafür erforderlichen Administratorrechten:

```powershell
wsl --install
```

Führen Sie den angeforderten Neustart durch und richten Sie den Benutzer der Linux-Distribution ein. Innerhalb einer Debian-/Ubuntu-Umgebung können Sie die Basiswerkzeuge installieren:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
```

Legen Sie das Repository vorzugsweise im Linux-Dateisystem, beispielsweise unter `~/geosdev`, ab. Öffnen Sie es mit VS Code über die [WSL-Erweiterung](https://code.visualstudio.com/docs/remote/wsl). Achten Sie darauf, dass Terminal, Perl und konfigurierte Compiler tatsächlich im selben WSL-Kontext laufen. Ein Windows-Pfad wie `C:\...` und ein Linux-Pfad wie `/home/...` sind nicht austauschbar.

Der aktuelle Werkzeugabruf richtet sich an Linux/x86-64. Prüfen Sie innerhalb WSL mit `uname -m`, ob tatsächlich `x86_64` gemeldet wird. WSL auf einem ARM64-Windows-System wird dadurch nicht automatisch zu einer x86-64-Umgebung.

Die wiederhergestellten Esp-/Glue-Hostwerkzeuge können statische 32-Bit-Linux-ELF-Dateien sein. Ein 64-Bit-Linux-Kernel unterstützt sie nicht in jeder Konfiguration unmittelbar. Das Paket `qemu-user` liefert unter Debian/Ubuntu normalerweise `/usr/bin/qemu-i386`; dieser Benutzerprogrammemulator kann die 32-Bit-Hostwerkzeuge ausführen. Er ist nicht mit einem DOS-/GEOS-Zielsystem gleichzusetzen.

Nach der Paketinstallation können Sie den Runner ausdrücklich für den Abruf und die Konfiguration wählen:

```sh
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
perl sdk.pl doctor --require-toolchain
```

Prüfen Sie den tatsächlich installierten Pfad, wenn Ihre Distribution anders paketiert. Ein vorhandener `qemu-system-x86_64`-Befehl ist kein Ersatz für den erwarteten `qemu-i386`-Runner. Auf einem ARM-Host allein reicht dieses Setup nicht als Zusicherung für den gesamten festgelegten x86-64-Werkzeugsatz.

Die Paketinstallation liefert die Hostvoraussetzungen, einschließlich C-Compiler, Make und Perl für den NASM-Quellbuild. Der SDK-Installer bezieht die festgelegten Werkzeuge gesondert. Die eigenständig erstellten begrenzten Ensemble-1.2-Deklarationen liegen im Repository; sie ersetzen keine vollständigen historischen Systemheader. Siehe [Werkzeugprofil](toolchain.md).

## Linux

Installieren Sie Git, Perl und bei Bedarf einen Host-C-Compiler mit dem Paketmanager Ihrer Distribution. Für Debian/Ubuntu ist die obige Paketliste ein Ausgangspunkt. Andere Distributionen verwenden andere Paketnamen.

```sh
git --version
perl -v
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

Wenn ein Profil einen bestimmten historischen oder modern gepflegten GEOS-Buildwerkzeugsatz benötigt, installieren Sie diesen gesondert und protokollieren dessen Version. Verlassen Sie sich nicht darauf, dass irgendein Programm namens `glue`, `esp` oder `goc` im `PATH` zur ausgewählten Quelle passt. Nutzen Sie explizite Werkzeugpfade beziehungsweise die vom Profil vorgesehene Erkennung.

Verwenden Sie für Routinebuilds keine Administratorrechte. Ein Projekt sollte seine Ausgaben in einem lokalen Buildverzeichnis erzeugen, nicht in Systemverzeichnissen oder in einer unveränderten Referenz-Runtime.

## macOS auf Intel und Apple Silicon

Perl, Git und VS Code können auf macOS als Hostwerkzeuge eingesetzt werden. Prüfen Sie zunächst das System-Perl mit `perl -v`. Falls es fehlt oder älter als 5.26 ist, installieren Sie ein separates Perl mit Ihrem Paketmanager, beispielsweise `brew install perl` bei Homebrew. Die Command Line Tools von Apple sind bei Bedarf ein Weg zu einem lokalen Host-C-Compiler; dieser erzeugt noch keine GEOS-Anwendung.

```sh
git --version
perl -v
perl sdk.pl doctor
perl sdk.pl check
perl sdk.pl test
```

Beachten Sie drei voneinander unabhängige Architekturen:

| Ebene | Beispiel | Konsequenz |
|---|---|---|
| Host | macOS auf ARM64 | Native Hostwerkzeuge müssen für macOS/ARM64 vorliegen |
| Buildumgebung | Linux x86-64 | Eine Linux-Binärdatei läuft nicht unmittelbar als macOS-Programm |
| Ziel | DOS/GEOS mit 8086-Code | Dafür wird ein geeigneter x86-Zielrechner oder Emulator benötigt |

Für Linux-exklusive Werkzeuge ist eine geeignete Linux-VM oder ein passend konfigurierter Container möglich. Auf Apple Silicon darf nicht stillschweigend ein ARM64-Container verwendet werden, wenn nur x86-64-Werkzeuge bereitstehen. Ebenso macht Rosetta allein aus einer Linux-Binärdatei keine native macOS-Anwendung. Die tatsächlich verwendete Kombination muss im Testbericht stehen.

[Docker Desktop](https://docs.docker.com/desktop/setup/install/mac-install/) bietet getrennte Installationswege für Intel und Apple Silicon. Falls Sie Container verwenden, pinnen Sie Image und Architektur. Ein Container mit gemeinsam eingebundenem Arbeitsverzeichnis kann eine Host-Buildumgebung liefern; er bestätigt weder einen nativen macOS-Build noch das Verhalten des 16-Bit-Zielprogramms.

## Konkreter Mac-Weg: x86-64-Linux-Gast

Dieser Ablauf ist eine Einrichtungsanleitung, kein behaupteter macOS-Hardwaretest des SDK:

1. Installieren Sie einen geeigneten VM-/Emulationshost, beispielsweise [UTM](https://docs.getutm.app/), und beschaffen Sie ein offizielles Linux-Installationsabbild für **amd64/x86-64**.
2. Wählen Sie auf einem Intel-Mac eine geeignete x86-64-Virtualisierung. Auf Apple Silicon wählen Sie für diesen Weg vollständige **x86-64-Emulation**, nicht nur einen ARM64-Linux-Gast.
3. Legen Sie eine eigene virtuelle Festplatte und eine für ein gewöhnliches Linux-Entwicklungssystem ausreichende Host-Speicherausstattung an. Diese VM-Speichergröße ist nicht die spätere 640-KB-Konfiguration des DOS-Ziels.
4. Installieren Sie Linux nach dessen offizieller Anleitung. Öffnen Sie ein Terminal im Gast und prüfen Sie `uname -m`; für den festgelegten Werkzeugpfad muss die Umgebung zu x86-64 passen.
5. Installieren Sie dort Git, Perl ab 5.26 und die Basis-Buildwerkzeuge. Verwenden Sie bei Debian/Ubuntu die oben beschriebenen Paketbefehle.
6. Klonen oder entpacken Sie das SDK **im Gast**. Damit vermeiden Sie zunächst zusätzliche Probleme durch Dateifreigaben, Rechte und Pfadübersetzung.
7. Führen Sie im Gast `perl sdk.pl doctor`, `perl sdk.pl toolchain install` und die Buildschritte des [Schnellstarts](quickstart.md) aus.
8. Bearbeiten Sie entweder im Gast oder mit einer passenden Remote-Editorverbindung. Das Terminal muss weiterhin dieselbe Gastinstallation und dieselben Werkzeugpfade verwenden.

Die UTM-Dokumentation unterscheidet [Systemarchitektur](https://docs.getutm.app/settings-qemu/system/) und [Rosetta für Linux](https://docs.getutm.app/advanced/rosetta/). Rosetta für einige Intel-Linux-Programme ist kein allgemeiner Nachweis, dass eine beliebige Mischung aus 32- und 64-Bit-Hostwerkzeugen unterstützt wird. Die vollständige x86-Gastumgebung hält diese Frage getrennt von einem nativen ARM64-Mac-Build. Alternativ beschreibt [QEMU](https://www.qemu.org/download/) seine Installations- und Emulationsmöglichkeiten.

## Zielsystem einrichten

1. Legen Sie eine unveränderte Referenzkopie Ihrer rechtmäßig vorhandenen DOS-/GEOS-Installation an.
2. Erstellen Sie daraus eine Arbeitskopie für Tests.
3. Halten Sie die Zielkonfiguration mit CPU-Modell, konventionellem Speicher, XMS/EMS/UMB, Treibern und Swap fest.
4. Prüfen Sie zunächst, ob die unveränderte Runtime zuverlässig startet.
5. Übertragen Sie danach genau eine Projektversion in diese Arbeitskopie.
6. Bewahren Sie bei einem Fehler die Buildberichte und die Konfigurationsdatei auf.

Für den Nachweis „8086/8088“ reicht ein schneller 386-Emulatorkern nicht. Auch ein Grafiktreiber kann eine höhere Mindest-CPU benötigen als Ihr eigener Code. Nutzen Sie einen zum Ziel passenden Treiber und dokumentieren Sie diese Einschränkung.

## Häufige Einrichtungsfehler

| Symptom | Zuerst prüfen |
|---|---|
| Perl wird nicht gefunden | Tatsächlicher Interpreter und Startkommando des Hosts |
| Werkzeug startet, findet aber Includes nicht | Profilpfade, Arbeitsverzeichnis und Groß-/Kleinschreibung |
| Linux-Werkzeug startet auf dem Mac nicht | Betriebssystemformat und CPU-Architektur der Binärdatei |
| Aufgabe läuft in VS Code anders als im Terminal | Remote-Kontext, ausgewählter Interpreter und Aufgabenparameter |
| DOS-Compiler akzeptiert den Projektpfad nicht | Kurzer Pfad, Laufwerkszuordnung und DOS-Dateinamen |
| Emulator startet, GEOS fehlt | Runtime ist ein gesonderter Bestandteil und wird nicht vom Emulator erzeugt |

