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
| Ein Netzwechsel löst ein Routen-Ereignis aus, auf das der Wächter ohne Polling warten kann | 15.9.: `ip monitor route` läuft ohne Rechte; ob ein WLAN-Wechsel ein Ereignis liefert, ist beim nächsten echten Wechsel zu belegen | offen, plausibel |

## Scheiben

| Nr | Scheibe | Stand | Nachweis |
|---|---|---|---|
| 1 | Widget nur da, wenn Starlink. Acceptance Criteria: Antwortet die Schüssel eine Weile nicht, verschwindet das Symbol aus der Bar ohne Lücke; antwortet sie wieder, ist es wieder da. Ein Unterbruch mit erreichbarer Schüssel bleibt ein Unterbruch, kein Verschwinden. | steht | https://claude.ai/artifact/MZrotZeJNHVUQpMdosotXm |
| 2 | Installierbar und aktualisierbar mit einem Befehl. Acceptance Criteria: `omarchy plugin add` aus dem GitHub-Repo bringt Widget und Sammler auf diesem Rechner zum Laufen, ohne Symlink, ohne Arbeitsrepo starlink-grpc-tools, ohne Handarbeit am Benutzerdienst; `omarchy plugin update` holt eine neue Fassung. | steht | https://claude.ai/artifact/QptB5kfHH2VWbHE3rWwWwi |
| 3 | Panel im Stil der Omarchy-Panels. Acceptance Criteria: Kopf mit Symbol, Titel, Untertitel in Grossbuchstaben und grosser Kennzahl rechts; Kennzahlen zweispaltig, Beschriftung links, Wert rechts; Abschnittstitel in Grossbuchstaben; Trennlinien wie bei Batterie und Netzwerk. David bestätigt am Screenshot. | steht, bestätigt | https://claude.ai/artifact/YWpgUy3PQcM9K8Yxy4mw39 |
| 4 | Sammler nur im Starlink-Netz. Acceptance Criteria: Ausserhalb des Starlink-Netzes läuft kein Sammler und keine Python-Umgebung, nur ein wartender Wächter; das Symbol ist nicht in der Bar, und das Widget liest höchstens jede Minute. Kommt Starlink zurück, startet der Sammler von selbst innert einer halben Minute. | steht | https://claude.ai/artifact/TSndL6WAZVuikrgPWxG2CN |

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
- 2026-09-15 (David): Panel bestätigt. Weiter mit Scheibe 4: Der Sammler läuft nur im Starlink-Netz,
  weil David Starlink nur in den Ferien nutzt und das Widget sonst fast nichts brauchen soll.
- 2026-09-15: Erkennung über Routen-Ereignisse des Systems plus Prüfung der Schüssel-API, nicht
  über den WLAN-Namen: Der Name des Starlink-WLANs ist frei wählbar, die Adresse der Schüssel nicht.
  Ohne Ereignis wird nur alle zehn Minuten geprüft.
- 2026-09-15: Der Wächter vererbt seine Sperre nicht an Lauscher und Sammler, und der Lauscher wacht
  selbst über den Wächter und endet spätestens 15 s nach ihm; abgelöst wurden zwei Fassungen: eine,
  bei der ein verwaister Lauscher die Sperre hielt, und eine, die beim Aufräumen darauf baute, dass
  die Shell den Wächter sanft beendet. Sie tut es hart.
- 2026-09-15 (David): Panel so nahe wie möglich an den Omarchy-Panels, alles Englisch, weniger
  Beschriftung. Umgesetzt mit denselben Bausteinen wie Batterie und Netzwerk: Statuszeile in
  Grossbuchstaben, grosse Verzögerung rechts, Raster aus Beschriftung und Wert, Trennlinie,
  Abschnittstitel. Verlauf ohne Achsen, Fusszeile weg, «läuft seit» ist die Zelle Uptime.

## Halde des Vorhabens

Ideen und Wünsche, die auf den Zielsatz einzahlen, aber nicht jetzt. Ein Satz je Eintrag.

- (leer; die Idee «Sammler nicht dauernd laufen lassen» wurde Scheibe 4)

## Letzter Stand

15. September 2026, 13:35: Vier Scheiben stehen. Ohne Starlink läuft nur ein wartender Wächter,
das Symbol ist weg, geprüft gestellt; der echte WLAN-Wechsel ist die letzte offene Annahme. David
entscheidet den Abschluss: fertig, weiter oder parken.

## Abschluss

Erst ausfüllen, wenn der Zielsatz wahr ist.

- War der Zielsatz nach der ersten Scheibe in ein bis zwei Tagen wahr? …
- Sind die Runden länger geworden? …
- Musste David nach dem Stand fragen? …
- Wurde ein Entscheid gekippt, weil eine Annahme nicht stimmte? …
- Davids Entscheid: fertig / weiter mit Scheibe … / parken, weil …
