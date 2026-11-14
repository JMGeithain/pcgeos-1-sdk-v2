# PC/GEOS 1.x Community-SDK

[English](README.md) · [Schnellstart](QUICKSTART.de.md) · [Entwicklerhandbuch](docs/de/README.md) · [Prüfbericht](VALIDATION.de.md)

Ein für GitHub vorbereitetes Entwicklungspaket für **16-Bit-C, Assembler und gemischte Module für den 8086**, mit reproduzierbaren Hostwerkzeugen, eigenen nativen Beispielen, Format-/ABI-Prüfungen und Editorunterstützung. Ein begrenzter eigener GUI-Adapter erzeugt neue Anwendungen für die ausdrücklich beobachtete Ensemble-1.2-Ausgabe mit Kernel-Anforderung 622.3 und UI 693.0.

**Experimenteller Stand, beschränkt auf das festgelegte Zielprofil.** Das ursprüngliche GUI-Beispiel wurde bereits unter GEOS auf einem emulierten 8086 ausgeführt. Die kuratierte Referenz enthält 32 Kernelaufrufe und einen kleinen UI-Ausschnitt. Die Prozess- und UI-Ressourcen der Beispiele werden neu erzeugt. Kommerzielle Anwendungen dienen nicht als Binärvorlage. Das Paket enthält einen begrenzten Satz eigenständig erstellter ABI-Deklarationen; es ist kein vollständiger Ersatz für sämtliche historischen 1.x-APIs, GOC-/UI-Werkzeuge und System-C-Wrapper. Ein originales Laufzeitsystem wird nicht mitgeliefert. Für tatsächlich ausgeführte native Prüfungen und deren Grenzen gilt [VALIDATION.de.md](VALIDATION.de.md).

## Einstieg

Erforderlich ist Perl ab Version 5.26. Der getestete Compiler-/Bootstrapweg verwendet Linux x86-64; Windows nutzt WSL2, macOS einen geeigneten Linux-x86-64-Gast. Die Perl- und Editorwerkzeuge sind davon getrennt. Lesen Sie zuerst die [Hosteinrichtung](docs/de/host-setup.md).

```sh
perl sdk.pl toolchain install
perl sdk.pl doctor --require-toolchain
perl sdk.pl check
perl sdk.pl test
perl sdk.pl build --project examples/hello-asm
```

Unter Debian/Ubuntu benötigt der Bootstrap unter anderem `build-essential`, `perl` und bei Bedarf `qemu-user`. Mit `toolchain install --i386-runner /usr/bin/qemu-i386` lässt sich der Runner für die 32-Bit-Linux-Hostwerkzeuge ausdrücklich wählen. Er ist kein DOS-/GEOS-Emulator.

`hello-asm` erzeugt `build/g1hello/g1hello.geo`: ein natives Fenster mit eigenen Rechtecken und kleinen Pixelzeichen. Prüfen Sie vor der Ausführung die getrennt vorhandene eigene Runtime und bauen Sie ausdrücklich gegen deren Identität:

```sh
perl sdk.pl verify-target /pfad/zum/eigenen/GWSVGA
perl sdk.pl build --project examples/hello-asm --target-root /pfad/zum/eigenen/GWSVGA
```

GEOS sauber beenden, diese Datei nach `WORLD` einer passenden Testinstallation kopieren, GEOS neu starten und `GEOS 1 SDK Hello` öffnen. Details: [Native Anwendung bauen](docs/de/native-applications.md).

## C, Assembler und gemischte Module

```sh
perl sdk.pl build --project examples/math-asm
perl sdk.pl build --project examples/math-c
perl sdk.pl build --project examples/math-mixed
```

Die drei Mathematikprojekte sind Bibliotheken und werden nicht durch Doppelklick gestartet. Ihre eigenen Register- beziehungsweise FAR-C-Verträge stehen neben dem Quelltext. Das zusätzliche [Bibliotheks-GUI](examples/hello-libraries/README.de.md) importiert alle drei und zeigt nach fünf Ergebnisvergleichen `PASS` oder `FAIL`. Die Anleitung erklärt Kernelbindung, Build und Installation nach `SYSTEM`/`WORLD`.

## Inhalt

| Pfad | Aufgabe |
|---|---|
| `sdk.pl` | Diagnose, Projektprüfung, Build, Tests und Inspektion |
| `tools/ensemble12/` | Eigener begrenzter NASM-/GUI-Buildadapter |
| `tools/geos1/` | Nativer Writer, Ressourcenprüfung und Laufzeitkatalog |
| `tools/lsp/` | Gemeinsamer lokaler Perl-Sprachserver |
| `include/ensemble12/` | Beobachtete Konstanten in C-, NASM- und Esp-Syntax |
| `targetprofiles/` | Genaue Runtime-Identität und nachgewiesener ABI-Ausschnitt |
| `toolchains/` | Festgelegte Downloads, Hashes und Quellstände |
| `examples/math-asm/` | Esp-Bibliothek mit eigener Registerschnittstelle |
| `examples/math-c/` | Freestanding-C-Bibliothek mit eigener FAR-`__cdecl`-Schnittstelle |
| `examples/math-mixed/` | C-Algorithmus mit ausdrücklichem Assembleradapter |
| `examples/hello-asm/` | Neu erzeugte native GUI-Anwendung |
| `examples/hello-libraries/` | Nativer Aufrufer der drei Bibliotheken |
| `docs/en/`, `docs/de/` | Englische und deutsche Entwicklerhandbücher |
| `editor/vscode/`, `editor/dist/` | Editorquellen und installierbare VSIX |
| `tests/`, `validation/` | Hosttests und zugeordnete Ausführungsnachweise |
| `.github/` | CI und Beitragsvorlagen |

## Eigene Zieldateien untersuchen

```sh
perl sdk.pl inspect /pfad/GWSVGA/SYSTEM/UI.GEO --summary
perl sdk.pl profile /pfad/GWSVGA/SYSTEM/UI.GEO /pfad/GWSVGA/SYSTEM/IM.GEO --output .sdk-local/runtime-profile.json
perl sdk.pl check-imports build/g1hello/g1hello.geo --profile .sdk-local/runtime-profile.json
perl sdk.pl verify-target /pfad/GWSVGA
```

Der allgemeine Katalog erfasst beobachtete Namen, Protokolle, Hashes und Exportpositionen. Er erfindet keine Funktionsnamen oder C-Signaturen. `KERNEL.EXE` ist keine gewöhnliche native `.GEO`-Datei und wird nicht an diesen Parser übergeben. Die gesonderte Zielprüfung vergleicht ihren festgelegten Hash. Passende Protokolle und Dateihashes sind von korrektem nativen Verhalten zu unterscheiden.

Importfreie Bibliotheken können zunächst Kernelprotokoll 0.0 enthalten. Mit `--kernel-reference /pfad/GWSVGA/SYSTEM/UI.GEO` übernimmt der Bibliotheksbuild einen beobachteten Anforderungswert, behält die ungebundene Fassung und protokolliert die Herkunft. Anwendungsbuilds verwenden stattdessen ihr Zielprofil und `--target-root`.

## Editor und IDEs

```sh
perl editor/vscode/pack_vsix.pl
code --install-extension editor/dist/pcgeos1-language-support-0.2.0.vsix
```

Die VSIX bietet fünf Syntaxmodi für Esp, NASM, UIC/ESPIRE, GOC und GP. Ihr optionaler eigener Client verbindet sich in einem vertrauenswürdigen SDK-Arbeitsbereich mit dem lokalen Perl-Sprachserver. Dieser bietet kuratierte API-Vervollständigung, Hover-Hinweise, Definitionen, Symbole und begrenzte statische Meldungen. Er ist kein Compiler, vollständiger Typprüfer oder nativer GEOS-Debugger. Für die Installation werden keine gesonderte Node-/npm-Umgebung und kein Marketplace-Konto benötigt.

[VS-Code-Anleitung](editor/vscode/README-DE.md) · [Weitere IDEs und Sprachserver](docs/de/ide-integration.md)

## GitHub und Lizenzen

Veröffentlichen Sie den Quellbaum und die freigegebenen Artefakte. Lokale Laufzeitkopien, Compilerinstallationen und private Werkzeugpfade bleiben außerhalb von Git. Ursprüngliche kommerzielle Header, Binärdateien und Ressourcen werden durch ihre Verwendung als Referenz nicht neu lizenziert.

Eigener Code und Dokumentation stehen unter MIT-Lizenz. Externe FreeGEOS-, Open-Watcom-, NASM- und Emulatorbestandteile behalten ihre eigenen Lizenzen; siehe [THIRD-PARTY.md](THIRD-PARTY.md). Die [Referenzanwendungen](docs/de/recovered-references.md) erklären die Trennung zwischen numerischen Schnittstellenfakten, eigenen Implementierungen, fremdem Quellcode und extrahierten Vorlagen.

Das Quellarchiv lässt sich mit `perl tools/package_source.pl ../PCGEOS1-SDK-source.zip` neu erzeugen.

Das [Handbuch](docs/de/README.md) behandelt Architektur, C/Assembler, Speicher, 8086, Grafik, Dateien, Bibliotheken, Rückportierung, Fehlersuche und Veröffentlichung. Für Beiträge gilt [CONTRIBUTING.md](CONTRIBUTING.md).
