# omarchy-starlink-widget

Starlink in der Omarchy-Bar: ein Symbol, das nur da ist, wenn der Rechner über Starlink online ist,
und ein Klick-Panel mit Zustand, Verzögerung, Kurve der letzten 15 Minuten, Grund eines Unterbruchs
und der Liste der Unterbrüche seit Rechnerstart.

## Installieren

```
omarchy plugin add https://github.com/jumpingspark/omarchy-starlink-widget.git --enable
```

Beim ersten Start richtet sich der Sammler seine Python-Umgebung selbst ein
(`~/.local/share/starlink-widget/venv`, Paket `starlink-grpc-core`); das dauert etwa eine Minute,
das Panel sagt es. Braucht `python3` mit `venv` und `flock` (auf Omarchy vorhanden).

Aktualisieren: `omarchy plugin update dd.starlink`. Entfernen: `omarchy plugin remove dd.starlink`.

## Teile

- `BarWidget.qml`, `Panel.qml`, `manifest.json`: das Bar-Widget (Quickshell). Das Widget startet
  den Sammler und hält ihn am Leben; endet das Widget, endet der Sammler.
- `bin/starlink-collector`: der Sammler. Er fragt die Schüssel alle 2 Sekunden, erkennt Unterbrüche
  (Zustand ungleich `CONNECTED`, mit dem Grund, den die Schüssel nennt) und schreibt
  `~/.local/state/starlink/status.json` (Stand, Verlauf der letzten 15 Minuten, Unterbrüche seit
  Rechnerstart) sowie `outages.jsonl` (alle Unterbrüche, fortlaufend). Antwortet die Schüssel
  30 Sekunden nicht (fremdes WLAN, Kabel), verschwindet das Symbol aus der Bar.
- `docs/zielkarte.md`: Ziel, Stand und Entscheide des Vorhabens.

## Entwickeln

Installiert liegt das Plugin als Git-Checkout unter `~/.config/omarchy/plugins/dd.starlink`;
Änderungen dort lädt die Shell von selbst. Fürs Repo: hier ändern, pushen, `omarchy plugin update
dd.starlink`. Panel per Kommando öffnen: `omarchy-shell shell toggle dd.starlink`.
Log der Shell: `qs log -p /usr/share/omarchy/shell`. Sammler: `~/.local/state/starlink/setup.log`
für die Einrichtung, `status.json` für den Stand.
