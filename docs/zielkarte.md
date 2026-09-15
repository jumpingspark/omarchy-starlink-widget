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

- GitHub: ja, öffentlich, github.com/jumpingspark/omarchy-starlink-widget (David, 15.9.). Push ist Teil des
  Installations- und Update-Wegs und damit für dieses Vorhaben gedeckt.
- Rundengrösse: 15 Minuten bis zum ersten Sichtbaren. Takt der Standmeldungen: alle 15 Minuten.
- Vereinbarte Grenzen: keine besonderen.

## Tragende Annahmen

| Annahme | Beleg oder Experiment | Ergebnis |
|---|---|---|
| Das Plugin kann den Sammler selbst starten und seine Python-Abhängigkeiten beim ersten Start selbst besorgen, ohne das Arbeitsrepo starlink-grpc-tools | 15.9.: Symlink und Dienst entfernt, Plugin per Omarchy-Befehl aus GitHub installiert, Sammler hat sich seine Umgebung selbst angelegt (Paket starlink-grpc-core) und fragt die Schüssel ab | belegt |
| Ein Widget, das sich ausblendet, lässt in der Bar keine Lücke | Gestellter Ausfall der Schüssel am 15.9., Screenshot der Bar: Nachbarn rücken zusammen | belegt |
| «Nicht über Starlink online» lässt sich daran erkennen, dass die Schüssel nicht antwortet | Im Starlink-Netz antwortet sie, in jedem anderen WLAN nicht; Beleg: Sammler-Fehler beim nächsten echten Netzwechsel | offen, plausibel |

## Scheiben

| Nr | Scheibe | Stand | Nachweis |
|---|---|---|---|
| 1 | Widget nur da, wenn Starlink. Acceptance Criteria: Antwortet die Schüssel eine Weile nicht, verschwindet das Symbol aus der Bar ohne Lücke; antwortet sie wieder, ist es wieder da. Ein Unterbruch mit erreichbarer Schüssel bleibt ein Unterbruch, kein Verschwinden. | steht | https://claude.ai/artifact/MZrotZeJNHVUQpMdosotXm |
| 2 | Installierbar und aktualisierbar mit einem Befehl. Acceptance Criteria: `omarchy plugin add` aus dem GitHub-Repo bringt Widget und Sammler auf diesem Rechner zum Laufen, ohne Symlink, ohne Arbeitsrepo starlink-grpc-tools, ohne Handarbeit am Benutzerdienst; `omarchy plugin update` holt eine neue Fassung. | steht | https://claude.ai/artifact/QptB5kfHH2VWbHE3rWwWwi |
| 3 | Panel im Stil der Omarchy-Panels. Acceptance Criteria: Kopf mit Symbol, Titel, Untertitel in Grossbuchstaben und grosser Kennzahl rechts; Kennzahlen zweispaltig, Beschriftung links, Wert rechts; Abschnittstitel in Grossbuchstaben; Trennlinien wie bei Batterie und Netzwerk. David bestätigt am Screenshot. | steht, Bestätigung offen | https://claude.ai/artifact/YWpgUy3PQcM9K8Yxy4mw39 |

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
- 2026-09-15 (David): GitHub öffentlich. Repo heisst omarchy-starlink-widget, nach der Sitte anderer
  Omarchy-Plugins.
- 2026-09-15: Das Widget startet den Sammler selbst, kein Benutzerdienst mehr. So reicht der eine
  Omarchy-Befehl, und der Sammler lebt genau so lange wie die Shell. Die Python-Bibliothek kommt als
  Paket in eine eigene Umgebung, nicht mehr aus dem Arbeitsrepo starlink-grpc-tools.
- 2026-09-15: Der Sammler erkennt das Ende der Shell am Elternprozess, nicht an seiner Eingabe;
  abgelöst wurde der erste Versuch über die Eingabe, weil Quickshell sie sofort schliesst.
- 2026-09-15 (David): Panel so nahe wie möglich an den Omarchy-Panels, alles Englisch, weniger
  Beschriftung. Umgesetzt mit denselben Bausteinen wie Batterie und Netzwerk: Statuszeile in
  Grossbuchstaben, grosse Verzögerung rechts, Raster aus Beschriftung und Wert, Trennlinie,
  Abschnittstitel. Verlauf ohne Achsen, Fusszeile weg, «läuft seit» ist die Zelle Uptime.

## Halde des Vorhabens

Ideen und Wünsche, die auf den Zielsatz einzahlen, aber nicht jetzt. Ein Satz je Eintrag.

- 2026-09-15 (David): Der Sammler soll nicht dauernd laufen, wenn Starlink lange nicht gebraucht wird.
  Heute fragt er alle 2 Sekunden, ohne Schüssel alle rund 20 Sekunden vergeblich. Idee: erst beim
  Netzwechsel wecken oder die Pausen bei Misserfolg wachsen lassen. Passt zu Scheibe 2, wenn das
  Plugin den Sammler selbst startet.

## Letzter Stand

15. September 2026, 13:05: Alle drei Scheiben stehen, der Zielsatz ist wahr. Das Plugin kommt mit
einem Befehl aus GitHub, zeigt sich nur im Starlink-Netz und sieht aus wie Batterie und Netzwerk.
David muss das Panel am Screenshot bestätigen und den Abschluss entscheiden: fertig, weiter oder
parken.

## Abschluss

Erst ausfüllen, wenn der Zielsatz wahr ist.

- War der Zielsatz nach der ersten Scheibe in ein bis zwei Tagen wahr? …
- Sind die Runden länger geworden? …
- Musste David nach dem Stand fragen? …
- Wurde ein Entscheid gekippt, weil eine Annahme nicht stimmte? …
- Davids Entscheid: fertig / weiter mit Scheibe … / parken, weil …
