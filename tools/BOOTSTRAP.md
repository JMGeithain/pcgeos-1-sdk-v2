# Building the host tools

[Deutsch](#deutsch)

The tested environment is Linux x86-64. The editor can run on Windows or
macOS while compilation happens in WSL2 or an x86-64 Linux VM. Host tools and
the DOS/GEOS target are separate environments.

## Linux and Windows with WSL2

On Windows, install Ubuntu through Microsoft's
[WSL instructions](https://learn.microsoft.com/en-us/windows/wsl/install), then
run the following commands **inside the Linux terminal**. A Linux checkout in
your home directory avoids mixed Windows/Linux paths.

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
perl sdk.pl doctor --require-toolchain
```

On a system with native Linux IA32 execution, the Esp/Glue wrapper can execute
its static ELF32 binary directly. The explicit QEMU runner is a portable
alternative within the tested Linux x86-64 profile. The installer does not
install QEMU or change kernel configuration.

## macOS

Use an **x86-64 Linux guest**, including on Apple Silicon. An ARM64 Linux guest
alone does not run the pinned Linux x86-64 compiler. A Linux VM with a shared
project directory is the easiest path to keep host and target paths clear.

A Docker Desktop Linux container is another environment option:

```sh
docker run --platform linux/amd64 --rm -it \
  -v "$PWD":/sdk -w /sdk ubuntu:24.04 bash
```

Install Perl 5.26+ in that guest/container, then use the Linux commands above.
Ubuntu 24.04's Perl is suitable. Docker/VM setup on macOS and cross-architecture
emulation are documented paths, **not tested host combinations in this release**.
The pinned compiler/host tools were actually tested on Linux x86-64. Do not
attempt to execute their Linux ELF files directly in macOS Terminal.

## Exact offline archives

Download the assets identified in `toolchains/*.lock.json` on a connected
machine, transfer them, and supply all three paths:

```sh
perl sdk.pl toolchain install \
  --watcom-archive /downloads/open-watcom-2_0-c-linux-x64.sfx \
  --freegeos-archive /downloads/pcgeos-260b33dcfcac15b7ecfdf04242cb0abf029ec269.tar.gz \
  --nasm-archive /downloads/nasm-3.02.tar.xz \
  --i386-runner /usr/bin/qemu-i386
```

The installer rejects different sizes/digests. Names alone are not identities.
The pinned Watcom asset was published under upstream's rotating `Current-build`
release. Its recorded asset ID and digest identify the tested bytes, but do not
guarantee that upstream keeps the old download forever. Retain the exact archive
for offline reproduction. A replacement snapshot needs an explicit lock update
and repeated compiler/emitted-code checks.
The Open Watcom Linux self-extracting archive is opened as ZIP data; its
installer is never executed. Esp/Glue and NASM are built from source. NASM's
source build needs the C compiler, make and Perl packages above even when the
downloads are supplied offline.

To install individual components without registering a root SDK configuration:

```sh
perl tools/bootstrap_watcom.pl --prefix .sdk-local/toolchains/watcom \
  --archive /downloads/open-watcom-2_0-c-linux-x64.sfx
perl tools/bootstrap_freegeos.pl --prefix .sdk-local/toolchains/freegeos \
  --watcom-root .sdk-local/toolchains/watcom \
  --source-archive /downloads/pcgeos-260b33dcfcac15b7ecfdf04242cb0abf029ec269.tar.gz \
  --i386-runner /usr/bin/qemu-i386
perl tools/bootstrap_nasm.pl --prefix .sdk-local/toolchains/nasm \
  --source-archive /downloads/nasm-3.02.tar.xz
```

The Perl bootstraps use core modules for ZIP/gzip-tar handling, `curl` for HTTPS downloads and `xz` for the NASM source archive. Exact offline archives avoid downloads; NASM still needs `xz` and its C/make/shell build prerequisites.

Each script writes machine-readable JSON to standard output and progress to
standard error. It retains source/build logs and license notices in its
private prefix. `installation.json` records source, patch and executable
identities. The Open Watcom extraction uses `sdk-installation.json`.

See the [reviewed FreeGEOS changes](patches/README.md),
[third-party notices](../THIRD-PARTY.md) and [toolchain handbook](../docs/en/toolchain.md).
No tool installation itself supplies a commercial 1.x SDK or certifies a
program's loader/API compatibility.

## Deutsch

Getestet wurde Linux x86-64. Der Editor darf unter Windows oder macOS laufen;
gebaut wird mit diesem Profil in WSL2 oder einer x86-64-Linux-VM. Die moderne
Entwicklungsumgebung und das DOS/GEOS-Zielsystem bleiben getrennt.

Unter Windows zunächst Ubuntu gemäß der
[WSL-Anleitung von Microsoft](https://learn.microsoft.com/de-de/windows/wsl/install)
einrichten. In der Linux-Shell, im SDK-Verzeichnis:

```sh
sudo apt update
sudo apt install git build-essential perl qemu-user curl xz-utils ca-certificates
perl sdk.pl toolchain install --i386-runner /usr/bin/qemu-i386
perl sdk.pl doctor --require-toolchain
```

Perl 5.26 oder neuer ist erforderlich. Unter macOS eine **x86-64-Linux-VM**
verwenden, auch auf Apple Silicon. Ein ARM64-Gastsystem allein führt den
festgelegten x86-64-Compiler nicht aus. Alternativ lässt sich ein Docker-Desktop-
Container mit `--platform linux/amd64` verwenden; der Befehl steht oben.
Diese macOS-/VM-/Container-Einrichtung ist dokumentiert, wurde jedoch in
dieser Veröffentlichung nicht als Host-Kombination getestet. Linux-ELF-Dateien
lassen sich nicht unmittelbar in macOS ausführen.

Für eine Offline-Installation dieselben drei Archive aus den Lock-Dateien
bereitstellen. Der oben gezeigte Befehl mit `--watcom-archive`,
`--freegeos-archive` und `--nasm-archive` funktioniert ohne erneuten Download.
Geprüft werden Größe und SHA-256, nicht bloß der Dateiname. NASM benötigt auch
offline einen C-Compiler, GNU make und Perl. Der Watcom-Installer wird nur als
ZIP-Datenquelle gelesen, nicht ausgeführt; Esp/Glue und NASM werden aus ihren
Quellen gebaut.

Das festgelegte Watcom-Archiv stammt aus der wechselnden Upstream-Veröffentlichung
`Current-build`. Asset-ID und Prüfsumme bezeichnen die getesteten Bytes, sichern
aber deren dauerhafte Verfügbarkeit nicht. Das genaue Archiv für Offline-Bauten
aufbewahren. Ein anderer Snapshot benötigt eine ausdrückliche Lock-Änderung und
erneute Compiler- und Maschinencode-Prüfungen.

Die Einzelbefehle oben installieren die Werkzeuge ohne Registrierung in der
SDK-Konfiguration. JSON-Ergebnisse erscheinen auf der Standardausgabe,
Fortschrittsmeldungen auf der Fehlerausgabe. ZIP- und gzip-Tar-Archive werden mit Perl-Kernmodulen verarbeitet; für HTTPS wird `curl`, für das NASM-Quellarchiv `xz` verwendet. Die privaten Installationsordner
enthalten Quellen, Protokolle, Prüfsummen und Lizenzhinweise. Ein Compiler-
Werkzeugsatz ersetzt weder ein kommerzielles 1.x-SDK noch den Laufzeittest des
erstellten Programms.
