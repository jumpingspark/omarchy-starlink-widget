# starlink-widget

Starlink-Widget für die Omarchy-Bar: ein Symbol in der Bar, Klick-Panel mit Zustand, Kennzahlen,
Grund eines Unterbruchs und der Liste der Unterbrüche seit Rechnerstart.

## Teile

- `plugin/` ist das Bar-Widget (Quickshell). Es wird per Symlink nach
  `~/.config/omarchy/plugins/dd.starlink` eingebunden und in `~/.config/omarchy/shell.json` mit
  `{"id": "dd.starlink"}` in die Bar gesetzt.
- `bin/starlink-collector` ist der Sammler. Er fragt die Schüssel alle 2 Sekunden, erkennt
  Unterbrüche (Zustand ungleich `CONNECTED`, mit dem Grund, den die Schüssel nennt) und schreibt
  `~/.local/state/starlink/status.json` (Stand, Verlauf der letzten 15 Minuten, Unterbrüche seit
  Rechnerstart) sowie `outages.jsonl` (alle Unterbrüche, fortlaufend).
- `systemd/starlink-collector.service` startet den Sammler als Benutzerdienst. Einbinden:
  `ln -sf $PWD/systemd/starlink-collector.service ~/.config/systemd/user/ && systemctl --user enable --now starlink-collector`.
- `bin/starlink-status` fragt die Schüssel einmal ab (Diagnose, nicht mehr vom Widget benutzt).

Beide Skripte nutzen die Python-Umgebung von `~/Work/starlink-grpc-tools` (`.venv`), Pfad über
`STARLINK_TOOLS` änderbar.

## Entwickeln

Änderungen am Plugin übernimmt die Bar über den Symlink nicht zuverlässig: `omarchy restart shell`.
Panel per Kommando öffnen: `omarchy-shell shell toggle dd.starlink`. Log: `qs log -p /usr/share/omarchy/shell`.
Sammler: `systemctl --user status starlink-collector`, `journalctl --user -u starlink-collector`.
