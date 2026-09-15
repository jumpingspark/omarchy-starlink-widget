# Zielkarte: Starlink-Widget als Plugin

Angelegt 15. September 2026. Diese Datei ist die Wahrheit über das Vorhaben. Claude liest sie beim
Start jeder Session und schreibt sie am Ende jeder Runde fort. Kein Code, keine Technik, keine
Historie: nur Ziel, Stand, Entscheide, Halde. Vorgänger ohne Zielkarte: Slice 1 vom 14. September
2026 (Symbol in der Bar, Panel mit Zustand, Kurve über 15 Minuten, Unterbrüche seit Rechnerstart),
steht und läuft.

## Zielsatz

Wenn es fertig ist, kann ich das Starlink-Widget auf jedem Omarchy-Rechner mit einem Befehl
installieren und aktualisieren, es zeigt sich nur, wenn ich über Starlink online bin, und es sieht
aus, als gehörte es zur Bar.

Nutzbar heisst: Auf diesem Rechner ist der Symlink ins Arbeitsrepo weg, das Plugin läuft aus der
Plugin-Installation von Omarchy, ein Update kommt über den Omarchy-Befehl an; in einem fremden WLAN
ist das Widget nicht in der Bar; das Panel folgt dem Aufbau der Batterie- und Netzwerk-Panels.

## Rahmen

- GitHub: offen (David entscheidet öffentlich oder privat vor Scheibe 2). Push nur auf Davids Wort.
- Rundengrösse: 15 Minuten bis zum ersten Sichtbaren. Takt der Standmeldungen: alle 15 Minuten.
- Vereinbarte Grenzen: keine besonderen.

## Tragende Annahmen

| Annahme | Beleg oder Experiment | Ergebnis |
|---|---|---|
| Das Plugin kann den Sammler selbst starten und seine Python-Abhängigkeiten beim ersten Start selbst besorgen, ohne das Arbeitsrepo starlink-grpc-tools | In Scheibe 2: frisches Verzeichnis, Plugin per Omarchy-Befehl installiert, Sammler läuft | offen |
| Ein Widget, das sich ausblendet, lässt in der Bar keine Lücke | Gestellter Ausfall der Schüssel am 15.9., Screenshot der Bar: Nachbarn rücken zusammen | belegt |
| «Nicht über Starlink online» lässt sich daran erkennen, dass die Schüssel nicht antwortet | Im Starlink-Netz antwortet sie, in jedem anderen WLAN nicht; Beleg: Sammler-Fehler beim nächsten echten Netzwechsel | offen, plausibel |

## Scheiben

| Nr | Scheibe | Stand | Nachweis |
|---|---|---|---|
| 1 | Widget nur da, wenn Starlink. Acceptance Criteria: Antwortet die Schüssel eine Weile nicht, verschwindet das Symbol aus der Bar ohne Lücke; antwortet sie wieder, ist es wieder da. Ein Unterbruch mit erreichbarer Schüssel bleibt ein Unterbruch, kein Verschwinden. | steht | https://claude.ai/artifact/MZrotZeJNHVUQpMdosotXm |
| 2 | Installierbar und aktualisierbar mit einem Befehl. Acceptance Criteria: `omarchy plugin add` aus dem GitHub-Repo bringt Widget und Sammler auf diesem Rechner zum Laufen, ohne Symlink, ohne Arbeitsrepo starlink-grpc-tools, ohne Handarbeit am Benutzerdienst; `omarchy plugin update` holt eine neue Fassung. | offen | |
| 3 | Panel im Stil der Omarchy-Panels. Acceptance Criteria: Kopf mit Symbol, Titel, Untertitel in Grossbuchstaben und grosser Kennzahl rechts; Kennzahlen zweispaltig, Beschriftung links, Wert rechts; Abschnittstitel in Grossbuchstaben; Trennlinien wie bei Batterie und Netzwerk. David bestätigt am Screenshot. | offen | |

## Entscheide

Datum, Entscheid, Grund. Nichts löschen; ein gekippter Entscheid bekommt «abgelöst durch».

- 2026-09-15 (David): Die alten Slice-2-Wünsche (Klick öffnet Dashboard, Empfang über den ganzen
  Tag, Hinderniskarte) sind weg, nicht Halde. Das Vorhaben ist jetzt: Plugin, Ein/Aus, Design.
- 2026-09-15: Reihenfolge Ein/Aus, Installation, Design. Ein/Aus ist am kleinsten, die Installation
  trägt die grösste Annahme, das Design landet auf dem Stand, der bleibt.
- 2026-09-15 (David): Design orientiert sich an den Omarchy-Panels für Batterie und Netzwerk, keine
  eigene Galerie nötig.
- 2026-09-15: Das Symbol verschwindet erst nach 30 Sekunden ohne Antwort der Schüssel, damit ein
  kurzer Aussetzer die Bar nicht flackern lässt. Ein Sammler, der sich nicht meldet, bleibt sichtbar
  und gedämpft: das ist ein Fehler, den man sehen soll, kein Netzwechsel.

## Halde des Vorhabens

Ideen und Wünsche, die auf den Zielsatz einzahlen, aber nicht jetzt. Ein Satz je Eintrag.

- (leer)

## Letzter Stand

15. September 2026, 12:30: Scheibe 1 steht, das Symbol verschwindet ohne Lücke, wenn die Schüssel
nicht antwortet, gestellt geprüft. Als Nächstes Scheibe 2, installierbar mit einem Befehl. David
muss dafür entscheiden, ob GitHub öffentlich oder privat.

## Abschluss

Erst ausfüllen, wenn der Zielsatz wahr ist.

- War der Zielsatz nach der ersten Scheibe in ein bis zwei Tagen wahr? …
- Sind die Runden länger geworden? …
- Musste David nach dem Stand fragen? …
- Wurde ein Entscheid gekippt, weil eine Annahme nicht stimmte? …
- Davids Entscheid: fertig / weiter mit Scheibe … / parken, weil …
