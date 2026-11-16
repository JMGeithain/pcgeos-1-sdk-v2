# Entwicklerhandbuch für PC/GEOS 1.x

[English](../en/README.md) · [Schnellstart](quickstart.md) · [Kompatibilitätsstatus](compatibility.md)

Dieses Handbuch richtet sich an Entwickler, die Anwendungen und Bibliotheken für PC/GEOS 1.x schreiben oder neuere GEOS-Programme zurückportieren möchten. Es behandelt C, Esp-Assembler und gemischte Projekte. Der Schwerpunkt liegt auf nachvollziehbaren Werkzeugketten, kleinen Ressourcen und überprüfbaren Schnittstellen.

**Der Name einer Datei, ein erfolgreicher Compilerlauf und eine moderne GEOS-Dokumentation beweisen noch keine Kompatibilität mit 1.x.** Lesen Sie vor dem ersten nativen Build den [Kompatibilitätsstatus](compatibility.md). Dort wird zwischen ausführbaren Hostwerkzeugen, verifizierter Ziel-ABI, einem erzeugten Geode und tatsächlich beobachtetem Verhalten im Zielsystem unterschieden.

## Praktisch verfügbarer Einstieg

Die drei Projekte `examples/math-asm`, `examples/math-c` und `examples/math-mixed` bauen native Rechenbibliotheken in Esp, C und gemischter Form. Der zusätzliche Adapter `ensemble12` erzeugt eigene NASM-GUI-Anwendungen für die ausdrücklich beobachtete Ensemble-1.2-Ausgabe. `examples/hello-asm` zeigt ein Fenster mit einer eigenen Zeichnung; `examples/hello-libraries` ruft die drei Bibliotheken über ihre eigenen ABIs auf. Beginnen Sie mit dem [nativen Anwendungsleitfaden](native-applications.md), wenn Sie zuerst ein sichtbares Ergebnis möchten.

Die Prozess- und UI-Ressourcen werden neu erzeugt; kein kommerzielles Programm dient als Binärvorlage. Die nachgewiesenen Konstanten und Registerverträge bilden einen begrenzten Schnittstellenausschnitt, keine vollständige allgemeine 1.x-/GOC-/C-System-API. Das ursprüngliche Hello-Beispiel wurde unter GEOS mit einem emulierten 8086 ausgeführt. Der Werkzeugabruf und Buildpfad verwendet Linux/x86-64; Editor und Perl-Prüfungen sind davon getrennt. Welche nativen Tests tatsächlich ausgeführt wurden, steht im [Prüfbericht](../../VALIDATION.md).

## Empfohlener Lernweg

1. [Schnellstart](quickstart.md): Repository prüfen und den ersten reproduzierbaren Arbeitsablauf ausführen.
2. [Windows, macOS und Linux einrichten](host-setup.md): Editor, Perl, Quellverwaltung und isoliertes Zielsystem vorbereiten.
3. [IDE-Integration](ide-integration.md): VS Code, IntelliJ IDEA, Eclipse, NetBeans sowie Kate/KDevelop mit demselben lokalen Sprachserver verbinden.
4. [Werkzeugkette und Compiler](toolchain.md): verstehen, welcher Schritt welches Dateiformat erzeugt.
5. [Architektur](architecture.md): Geodes, Ressourcen, Handles, Objekte und Nachrichten einordnen.
6. [C und Assembler kombinieren](c-and-assembly.md): eine eindeutige ABI zwischen Rechenkern, Adapter und Betriebssystem festlegen.
7. [Speicher und 8086/8088](memory-and-8086.md): bewegliche Blöcke, Segmentgrenzen, Stapel und geringe Speicherausstattung berücksichtigen.
8. [Native Anwendung bauen](native-applications.md): eigenen NASM-Code, Objektressourcen und Bibliotheksimports verbinden.
9. [Benutzeroberfläche und Grafik](ui-and-graphics.md): ereignisgesteuert zeichnen und native Fenstersemantik erhalten.
10. [Dateien und Persistenz](files-and-persistence.md): Dokumentformate, Fehlerbehandlung und VM-Dateien entwerfen.
11. [Bibliotheken und Rückportierung](libraries-and-backporting.md): Exporte, Protokolle und ersetzbare Funktionen verwalten.
12. [Fehlersuche und Tests](debugging-and-testing.md): Binärprüfung und echte Zielsystemtests miteinander verbinden.
13. [Lokalisierung und Veröffentlichung](localization-and-release.md): deutsche Texte, Ressourcen, Lizenzen und Releases vorbereiten.

[Wiederhergestellte Referenzanwendungen](recovered-references.md) ergänzen die allgemeinen Kapitel um versionsgebundene praktische Erkenntnisse und Lizenzgrenzen.

[API-Nachweise](api-reference.md) erklären, wie ein 1.x-Aufruf in dieses Projekt aufgenommen werden darf. Die [Quellenliste](references.md) trennt aktuelle Primärquellen von historischen beziehungsweise nur konzeptionell verwendbaren Unterlagen.

## Drei getrennte Arbeitsbereiche

| Bereich | Inhalt | In ein öffentliches Repository? |
|---|---|---|
| Projekt | Eigener Quellcode, Tests, Dokumentation, freigegebene Konfigurationen | Ja, mit passender Lizenz |
| Werkzeuginstallation | Compiler, Assembler, Linker und gegebenenfalls ein vorhandenes Original-SDK | Nur bei geklärten Weitergaberechten |
| Testinstallation | DOS und die konkrete PC/GEOS-1.x-Ausgabe mit ihren Treibern | Nicht automatisch; getrennt halten |

Die letzte Spalte ist keine Aussage darüber, welche Lizenz ein bestimmtes Fremdprodukt hat. Prüfen Sie die Rechte für jede tatsächlich verwendete Datei. Ein Verweis auf ein öffentliches Downloadangebot ersetzt diese Prüfung nicht.

## Was dieses Handbuch nicht behauptet

Die öffentlich gepflegte FreeGEOS-Quellbasis beruht auf einer späteren Produktgeneration. Ihre umfangreiche Dokumentation basiert auf dem SDK 2.0. Sie ist eine wertvolle Architektur- und Sprachreferenz, aber kein unveränderter Satz von 1.x-Headern. Ebenso sind Esp, GOC, Glue, ein C-Compiler und die zugehörigen Importbeschreibungen unterschiedliche Bestandteile. Ein einzelnes installiertes Programm macht daraus noch kein vollständiges 1.x-SDK.

Die in diesem Repository dokumentierten Nachweise und Testberichte haben Vorrang vor allgemeinen Formulierungen wie „GEOS-kompatibel“. Nicht ausgeführte Windows-, macOS- oder Hardwaretests sind nicht durch einen erfolgreichen Linux-Test abgedeckt.



## GEOTEST-Fallstudie

Die [GEOTEST-Fallstudie](geotest-case-study.md) sammelt Ergebnisse zu Kernel-Dateideskriptoren, Dispatcheraufrufen, dem GTDF-v1-Testformat, Icons und dem noch offenen Menü-/Dateidialogpfad. Sie trennt statische Befunde, beobachtete Laufzeit und offene Hypothesen.
