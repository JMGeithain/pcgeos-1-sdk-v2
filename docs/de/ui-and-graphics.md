# Benutzeroberfläche und Grafik

[Handbuch](README.md) · [English](../en/ui-and-graphics.md)

Die Oberfläche sollte aus dem Dokument- beziehungsweise Anwendungszustand wiederherstellbar sein. Ein Fensterinhalt, der nur einmal direkt auf den Bildschirm gezeichnet wurde, ist nach Überdeckung, Größenänderung oder Wiederherstellung nicht zuverlässig vorhanden.

Die öffentliche Dokumentation zu [generischer UI](https://bluewaysw.github.io/pcgeos/Concepts/cuiover.html) und [Grafikumgebung](https://bluewaysw.github.io/pcgeos/Concepts/cgraph.html) erklärt die Konzepte. Prüfen Sie konkrete Klassen, Nachrichten und Grafikaufrufe für Ihr 1.x-Profil gesondert.

## Generische und eigene Darstellung aufteilen

Nutzen Sie generische Objekte für Standardfunktionen, wenn deren 1.x-Verfügbarkeit belegt ist. Eigene Darstellungen sind für Brettansichten, technische Zeichnungen oder andere spezielle Inhalte sinnvoll. Zeichnen Sie Standardschaltflächen nicht nur deshalb selbst, weil ein späterer Screenshot ein anderes Aussehen zeigt.

Eine generische Beschreibung lässt der spezifischen UI die Entscheidung über das Aussehen. Eine Rückportierung darf daher nicht voraussetzen, dass eine Klasse in 1.x dieselbe Mindestgröße oder dieselben Hints wie in einem späteren System hat.

## Zustandsänderung und Neuzeichnen trennen

Ein verlässlicher Ereignisablauf besteht aus drei Schritten:

1. Eingabe validieren und den Modellzustand ändern.
2. Den betroffenen sichtbaren Bereich ungültig machen.
3. Im vorgesehenen Zeichenpfad aus dem aktuellen Zustand zeichnen.

Vermeiden Sie im Zeichenpfad Dateioperationen, lange Berechnungen, Netzwerkzugriffe und fremde Objektsperren. Ein Repaint kann häufiger und in anderen Zuständen auftreten als die ursprüngliche Benutzereingabe.

Für ein kleines bewegtes Objekt genügt häufig die vereinigte Fläche aus alter und neuer Position. Ein unnötiges vollständiges Löschen des Fensters kann dagegen Flackern und zusätzliche Arbeit verursachen. Umgekehrt darf eine zu kleine Invalidierung keine alten Pixel stehen lassen.

## Eltern- und Kindbereiche respektieren

Ein Elternobjekt darf sichtbare Kindobjekte nicht unkontrolliert übermalen. Ein Hintergrund kann beim ersten vollständigen Aufbau korrekt aussehen, aber bei einer späteren Fokusänderung die Schaltflächen auslöschen, wenn nur der Elternbereich neu gezeichnet wird.

Mögliche sichere Entwürfe sind:

- Nur den eigenen, nicht von Kindern belegten Bereich zeichnen.
- Einen dokumentierten Neuzeichenablauf verwenden, der die Kinder tatsächlich einschließt.
- Zustände lokal zwischenspeichern, statt für kosmetische Informationen während des Paint-Aufrufs fremde Objekte zu sperren.

Prüfen Sie ausdrücklich den Wechsel zwischen aktiven und inaktiven Fenstern sowie das Öffnen eines modalen Dialogs. Ein schöner Startbildschirm reicht nicht aus.

## Geometrie und Trefferbereiche zusammen ändern

Wenn ein Steuerelement größer gezeichnet wird, muss sein tatsächlicher Eingabebereich dazu passen. Mindestfenstergröße, Beschriftungsbreite, Clientursprung und benachbarte Elemente müssen dieselben Maße verwenden.

| Änderung | Zugehörige Prüfung |
|---|---|
| Größere Titelschaltflächen | Reihenfolge, Treffergrenzen, Mindestbreite und Titelbeschneidung |
| Andere Schrift | Gemessene Höhe/Breite, Umbruch und abgeschnittene Texte |
| Dünnerer Rahmen | Clientabstände und noch benutzbarer Größenänderungsbereich |
| Andere Fensterform | Zeichenclip, Überdeckung, Mauszugriff und maximierter Zustand |
| Skalierbare Zeichenfläche | Koordinatentransformation, Seitenverhältnis und Scrollbereich |

Leiten Sie die Bedeutung von rechten und unteren Rechteckgrenzen nicht ungeprüft aus späteren Headern ab. Auch ein Unterschied von einem Pixel kann bei dünnen Rahmen, benachbarten Treffflächen oder Bildpuffern relevant sein.

## Grafikzustand vollständig beachten

Eine native Zeichenroutine kann neben allgemeinen Registern auch den aktuellen Zeichenstift, Farben, Masken, Mischmodus, Clipzustand oder Transformationen verändern. Dokumentieren Sie diese Effekte am Adapter.

Ein brauchbarer Test verändert einen solchen Zustand absichtlich in einem Grafikstub und prüft danach, ob die aufrufende Routine den erforderlichen Zustand wiederherstellt. Anschließend ist ein nativer Repainttest nötig: ein Stub zeigt weder echte Treiberkonvertierung noch sichtbare Überdeckung.

## Farbe und Darstellungsgrenzen

Ein hochauflösender Modus ist nicht automatisch ein TrueColor-Aufrufpfad. Betrachten Sie getrennt, welche Farbangabe die API annimmt, wie der Kernel sie interpretiert und welche Farben der verwendete Treiber tatsächlich ausgibt.

Messen Sie bei Bedarf einen Pixel aus einem unveränderten Framebufferbild. Dokumentieren Sie, ob dieser Wert ein gewünschter RGB-Wert, ein Palettenindex oder das Ergebnis einer Umrechnung ist. Für eine 16-Farben-Ausgabe darf eine angenäherte Darstellung nicht als exakte RGB-Wiedergabe bezeichnet werden.

## Grafiktestliste

Prüfen Sie Start, Überdeckung, Wiederfreigabe, Verschieben, Größenänderung, Minimieren/Wiederherstellen und Maximieren/Wiederherstellen. Bei interaktiven Elementen gehören Drücken, Gedrückthalten, Herausziehen, Loslassen außerhalb und erneutes Hineinziehen dazu.

Lassen Sie die Anwendung nach einer Größenänderung vollständig neu zeichnen, bevor Sie ein Bild bewerten. Halten Sie außerdem fest, ob die beobachtete Verzögerung von einem Emulator, dem Zieltreiber, Swap oder einer eigenen zusätzlichen Zeichenoperation stammen kann. Ohne Messung ist daraus keine Bildraten- oder Hardwaregeschwindigkeitsangabe abzuleiten.


## Konkreter Einstieg mit dem mitgelieferten GUI-Adapter

[hello-asm](../../examples/hello-asm/README.de.md) verwendet einen neu erzeugten `GenApplication`-/`GenPrimary`-/`GenView`-Baum für das beobachtete Ensemble-1.2-Ziel. Es zeichnet Rechtecke und eigene kleine Pixelzeichen im nativen Exposed-Pfad. Der zugehörige [Anwendungsleitfaden](native-applications.md) erklärt Methodenregistrierung, Kernelaufrufe, Relokationen und den Update-Lebenszyklus.

Das Beispiel ist absichtlich eine nicht dokumentorientierte Zeichenanwendung. Es besitzt keine allgemeine Textkomponente, keinen Farbdialog und keinen automatisch skalierenden Inhalt. Ein größerer View zeigt dieselben festen Zeichenkoordinaten. Nutzen Sie das Beispiel für einen ersten sicheren Grafikpfad; ergänzen Sie weitere UI-Fähigkeiten erst mit deren konkreten nativen Klassen- und Nachrichtenverträgen.
