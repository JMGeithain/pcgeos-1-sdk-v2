# Originale vorgebaute Beispiele

[English](README.md) · [Prüfbericht](../../../VALIDATION.de.md)

Diese fünf Dateien wurden aus den Originalquellen des SDK gebaut und in den dokumentierten Tests unter Ensemble 1.2 mit emuliertem 8086 und 640 KB konventionellem Speicher ausgeführt. Sie enthalten keine historischen Anwendungsvorlagen oder Laufzeitressourcen. `samples.json` nennt Größen und Prüfsummen.

Das separat beschaffte Zielsystem mit `perl sdk.pl verify-target /Pfad/zu/GWSVGA` prüfen. GEOS ordnungsgemäß beenden und eine entbehrliche Testinstallation sichern. Den Inhalt von `WORLD` in deren `WORLD` und die drei Bibliotheken aus `SYSTEM` in deren `SYSTEM` kopieren. Keine fremden vorhandenen Dateien ersetzen. GEOS starten und **GEOS 1 SDK Hello** oder **GEOS 1 Library Probe** aufrufen. Die Bibliotheken sind Abhängigkeiten und werden nicht selbst gestartet.

Die Bibliotheksprüfung soll **PASS** anzeigen. Vor Änderungen die Quellen und die [Anleitung](../../../docs/de/native-applications.md) lesen. Die Beispiele gelten für das dokumentierte Zielprofil; andere Ensemble-Versionen, übersetzte Systembibliotheken oder Treiber sind damit nicht zertifiziert.

Der Originalcode unterliegt der MIT-Lizenz des Repositories. GEOS-Laufzeitsystem, Compiler und Emulator sind hier nicht enthalten.
