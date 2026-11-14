# Portable checksum core

This supporting C source is used by the host semantic tests. It is not a native
GEOS application or a standalone project. The `__near __cdecl` declaration
describes a potential same-segment helper; the shipped mixed native example
instead uses an explicit far C call between separate resources.

Use [math-c](../math-c/README.md) or [math-mixed](../math-mixed/README.md) to build
the actual native-format libraries. Both document their own calling convention
and the limits of their runtime validation.

## Deutsch

Dieser ergänzende C-Quelltext dient den Semantiktests auf dem Entwicklungsrechner.
Er ist weder eine native GEOS-Anwendung noch ein eigenständig baubares Projekt.
Die Deklaration `__near __cdecl` beschreibt eine mögliche Hilfsfunktion im selben
Segment. Das mitgelieferte gemischte native Beispiel verwendet dagegen einen
ausdrücklichen fernen C-Aufruf zwischen getrennten Ressourcen.

Zum Erzeugen nativer Bibliotheksdateien dienen
[math-c](../math-c/README.de.md) und [math-mixed](../math-mixed/README.de.md).
Beide erläutern ihre eigene Aufrufkonvention und die Grenzen der Laufzeitprüfung.
