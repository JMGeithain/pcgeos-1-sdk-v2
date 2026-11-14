# Lokalisierung, GitHub und Veröffentlichungen

[Handbuch](README.md) · [English](../en/localization-and-release.md)

Lokalisierung betrifft Texte, Schriftmetriken, Zeichenkodierung und Bedienung. Für eine verlässliche deutsche Ausgabe genügt es nicht, englische Wörter durch längere deutsche Wörter zu ersetzen.

Das öffentliche [Lokalisierungskapitel](https://bluewaysw.github.io/pcgeos/Concepts/clocal.html) bietet konzeptionelle Hintergründe. Werkzeuge und Ressourcenformate müssen zu Ihrem tatsächlichen 1.x-Buildpfad passen.

## Texte und Logik trennen

Halten Sie sichtbare Texte in den dafür vorgesehenen Ressourcen oder in einer klar getrennten, vom Projekt verarbeiteten Datenquelle. Speichern Sie keine sprachabhängigen Vergleiche wie `if text == "Save"` als Funktionslogik.

Benennen Sie UI-Aktionen nach ihrer Bedeutung. So kann dieselbe Aktion beispielsweise „Speichern“ oder „Save“ heißen, ohne dass ihre Verarbeitung davon abhängt. Gemeinsame Rechen- und Dateiformatlogik sollte zwischen Sprachvarianten identisch bleiben.

## Kodierung bewusst konvertieren

Das Repository kann UTF-8 als Quelltextkodierung verwenden. Die native GEOS-Ressource benötigt jedoch die Kodierung, die der konkrete Übersetzungs- und Zielpfad erwartet. DOS-Codepage, Windows-Codepage, GEOS-Zeichensatz und Unicode sind nicht automatisch identisch.

Prüfen Sie insbesondere `ä`, `ö`, `ü`, `Ä`, `Ö`, `Ü`, `ß`, typografische Anführungszeichen und gegebenenfalls Währungssymbole. Verwenden Sie für nicht darstellbare Zeichen eine bewusste, dokumentierte Ersatzregel. Ein falsch dargestelltes Byte darf nicht dadurch „korrigiert“ werden, dass auf einem einzigen Host ein zufälliger anderer Editorzeichensatz gewählt wird.

## Die deutsche Oberfläche prüfen

| Bereich | Prüfung |
|---|---|
| Beschriftungen | Vollständige Anzeige und passende Mindestbreite |
| Dialoge | Umbruch, Standardaktion, Abbrechen und Fokusreihenfolge |
| Menüs | Eindeutige, verfügbare Tastaturkennungen |
| Schrift | Vorhandene Zeichen und tatsächliche gemessene Breite |
| Zahlen | Angezeigtes Dezimaltrennzeichen vom gespeicherten Format trennen |
| Fehlermeldungen | Verständliche Aktion nennen und ursprünglichen Fehlerzustand erhalten |
| Dateien | Englische und deutsche Fassungen lesen dasselbe sprachunabhängige Dokumentformat |

Passen Sie Größen mit den dafür vorgesehenen Layoutmechanismen an. Eine feste Pixelbreite, die für „Go“ reicht, kann „Ausführen“ abschneiden. Prüfen Sie beide Sprachfassungen im echten Zielsystem.

## GitHub-Repository vorbereiten

Ein öffentliches Repository sollte auf den ersten Blick beantworten:

1. Welche Funktionen und Zielprofile tatsächlich bereitstehen.
2. Wie ein neuer Entwickler die Hostprüfungen startet.
3. Welche Fremdwerkzeuge oder Originaldateien selbst zu beschaffen sind.
4. Welche Ausgaben neu gebaut werden können und welche Prüfungen ausgeführt wurden.
5. Welche Lizenz für eigenen Code, Dokumentation, Beispiele und Fremdbestandteile gilt.
6. Wie Fehler gemeldet und Änderungen beigetragen werden können.

Veröffentlichen Sie keine privaten Runtime-Verzeichnisse, Swapdateien, lokalen Toolpfade oder unklar lizenzierten Installationsarchive. Eine `.gitignore` hilft, ersetzt aber nicht die Kontrolle der tatsächlich erfassten Dateien.

## Lizenzen und Herkunft

Eigene neue Dateien können unter der für dieses Repository gewählten Lizenz stehen. Diese Lizenz dehnt sich nicht rückwirkend auf eine fremde Originalbibliothek, ein historisches SDK oder einen mitgebrachten Compiler aus.

Führen Sie für jeden Fremdbestandteil Herkunft, Version oder Commit, Prüfsumme, Lizenztext und Änderungen auf. Wenn ein Werkzeug nur heruntergeladen beziehungsweise lokal installiert werden darf, dokumentieren Sie diesen Schritt, statt die Datei ungeprüft in ein Release aufzunehmen. Entfernen Sie keine erhaltenen Urheber- oder Lizenzhinweise.

## Einen Release erzeugen

Ein Release sollte aus einem sauberen, eindeutig bezeichneten Quellstand gebaut werden. Führen Sie die freigegebenen Tests aus und erzeugen Sie Prüfsummen für die auszuliefernden Dateien. Kontrollieren Sie das fertige Archiv durch Entpacken und einen erneuten Build, wenn Reproduzierbarkeit behauptet wird.

Ein knapper, brauchbarer Releasehinweis nennt das konkrete Ergebnis, die Zielgrenzen, die getesteten Konfigurationen und verbleibende Einschränkungen. Aussagen wie „vollständiges 1.x-SDK“, „8086-getestet“ oder „macOS unterstützt“ benötigen die dafür entsprechenden Nachweise. Ein ausschließlich unter Linux getesteter Werkzeugabruf wird deshalb als solcher gekennzeichnet.

Für Beiträge empfiehlt sich eine kleine Änderung mit verständlicher Begründung und passenden Tests. Bei ABI-Erweiterungen gehört der native Nachweis zur Änderung; bei Dokumentationsübersetzungen sollten Links und die tatsächlichen Befehle beider Sprachfassungen konsistent bleiben.


## Lokalisierungsgrenze des kleinen Hello-Adapters

Das Handbuch liegt vollständig auf Deutsch vor; daraus folgt keine vollständige deutsche Oberfläche des GUI-Starters. Der aktuelle neue Objektgenerator nimmt für Moniker und Kennungen ASCII entgegen. Eine UTF-8-Zeichenfolge mit Umlauten im `long_name`-Feld ist deshalb keine native GEOS-Zeichensatzkonvertierung und wird nicht als solche unterstützt.

Auch die eigenen Pixelzeichen des Hello-Beispiels decken nur den tatsächlich benötigten kleinen Zeichenvorrat ab. Für deutsche Anwendungstexte benötigen Sie einen überprüften nativen Text-/Schriftpfad oder einen bewusst erweiterten eigenen Zeichensatz samt Encoding und Messung. Erweitern Sie dabei Quellkodierung, Ressourcenbytes, Schriftmetriken und Tests gemeinsam. Verwenden Sie eine dokumentierte ASCII-Umschrift nur als ausdrücklich gewählte Zwischenlösung.

## Praktischer erster GitHub-Upload

Erstellen Sie auf GitHub ein eigenes leeres Repository. Ersetzen Sie `OWNER` und `REPOSITORY` in der folgenden Adresse durch die tatsächlichen Namen. Prüfen Sie vor dem ersten Commit sorgfältig die erfassten Dateien; ein lokales SDK-/Runtime-Verzeichnis gehört nicht in diese Liste.

```sh
git init
git add .
git status --short
git diff --cached --stat
git diff --cached
```

Wenn die vorbereiteten Dateien dem gewünschten öffentlichen Quellstand entsprechen:

```sh
git commit -m "Initial PC/GEOS 1.x SDK source"
git branch -M main
git remote add origin https://github.com/OWNER/REPOSITORY.git
git push -u origin main
```

Bei einem bereits vorhandenen Git-Repository beginnen Sie mit `git status` und prüfen zuerst bestehende Branches und Remotes. Führen Sie dann nicht nochmals blind `git remote add origin` aus. Die GitHub-Anmeldung erfolgt über Ihre eigene reguläre Git-Konfiguration. Veröffentlichen Sie keine Zugangsdaten im Quelltext oder in Konfigurationsdateien.

Das mitgelieferte Paketwerkzeug erzeugt ein Quellarchiv aus den vorgesehenen öffentlichen Bestandteilen:

```sh
perl tools/package_source.pl ../PCGEOS1-SDK-source.zip
```

Kontrollieren Sie auch das fertige Archiv. Ein erfolgreicher Paketlauf allein belegt weder einen nativen Funktionstest noch korrekte Rechte an zusätzlich von Ihnen aufgenommenen Dateien.
