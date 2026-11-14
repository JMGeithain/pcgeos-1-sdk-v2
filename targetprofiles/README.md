# Supplied Ensemble 1.2 target / Bereitgestelltes Ensemble-1.2-Ziel

`supplied-ensemble12.json` pins the supplied kernel, UI and Motif by SHA-256 and
records the native export tables for selected libraries. The module table uses
the same schema as `perl sdk.pl profile`; the additional identity fields are used
by `perl sdk.pl verify-target` and the dedicated application backend.

`supplied-ensemble12-audit.json` records hashes and structural facts for the
uploaded native files. The strict parser accepted 140 geodes, all requiring kernel
protocol 622.3. It rejected `WORLD/PCAO.GEO` because its duplicated release or
protocol fields disagree. Duplicate permanent names are retained in this audit:
for example, different video-driver files can share a permanent name.

The kernel is a DOS executable and is identified by hash; the native-GEO parser
does not decode it. Kernel 622.3 is the requirement observed in the supplied
geodes, corroborated by the supplied ABI research. UI's own protocol is 693.0;
Motif's is 693.1. Do not replace these values with a version inferred from a
product's marketing name.

`ensemble12-abi.json` contains 32 curated kernel ordinal/register contracts,
six UI class ordinals and eight observed message values. Evidence descriptions
identify the supplied native-code research. The contracts are an observed subset,
not an exhaustive header tree or certification of other 1.x versions. No binaries,
serialized object templates, icons, fonts or other proprietary assets are stored
in these catalogs.

## Deutsch

`supplied-ensemble12.json` legt die bereitgestellten Kernel-, UI- und Motif-Dateien
über SHA-256 fest und enthält native Exporttabellen ausgewählter Bibliotheken.
`supplied-ensemble12-audit.json` dokumentiert die untersuchten Dateien: 140 Geodes
bestanden die Strukturprüfung und verlangen Kernel-Protokoll 622.3. Bei
`WORLD/PCAO.GEO` widersprechen sich doppelt gespeicherte Release- oder
Protokollangaben; die Datei wurde abgelehnt. Gleichnamige permanente Module,
beispielsweise alternative Grafiktreiber, bleiben im Prüfbericht sichtbar.

Der DOS-Kernel wird über seinen Hash identifiziert, nicht vom GEO-Parser gelesen.
Die Anforderung 622.3 stammt aus den Geode-Headern und den bereitgestellten
ABI-Untersuchungen. UI besitzt Protokoll 693.0, Motif 693.1. Produktnamen reichen
nicht aus, um solche Werte abzuleiten.

`ensemble12-abi.json` enthält eine begrenzte Auswahl beobachteter Schnittstellen:
32 Kernel-Aufrufe, sechs UI-Klassen und acht Nachrichtenwerte mit Belegen.
Die Angaben gelten für das festgelegte Ziel; andere Versionen und nicht geprüfte
Schnittstellen werden damit nicht bestätigt. Die Kataloge enthalten keine
proprietären Programmdateien oder serialisierten Objektvorlagen.
