import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Das Klick-Panel: Zustand, Verzögerung, Verlust, Durchsatz und der Grund,
// falls die Verbindung gerade unterbrochen ist. Daten kommen vom Skript
// bin/starlink-status (eine JSON-Zeile je Abfrage).
Panel {
  id: root
  moduleName: "dd.starlink"
  ipcTarget: "dd.starlink"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property bool openedFromHotkey: false

  // ---- Daten
  property var data: null            // letzte JSON-Antwort
  property string lastError: ""
  property double lastUpdateMs: 0

  readonly property string scriptPath: Quickshell.env("HOME") + "/Work/starlink-widget/bin/starlink-status"
  readonly property int refreshSec: Math.max(2, parseInt(setting("refreshIntervalSec", 5), 10) || 5)

  readonly property bool reachable: data !== null && data.ok === true
  readonly property string state: reachable ? String(data.state || "") : ""
  readonly property bool connected: reachable && state === "CONNECTED"
  readonly property bool down: reachable && !connected
  readonly property real latencyMs: reachable && data.latency_ms !== null && data.latency_ms !== undefined ? Number(data.latency_ms) : -1
  readonly property real dropPct: reachable && data.drop !== null && data.drop !== undefined ? Number(data.drop) * 100 : -1

  // Symbol in der Bar (Nerd Font, nf-md, Satellitenschüssel U+EF60 (fa-satellite_dish), im Test); der Tooltip trägt die Zahlen.
  readonly property string glyph: "\uEF60"
  readonly property string tooltip: {
    if (!reachable) return "Starlink: Schüssel nicht erreichbar"
    if (down) return "Starlink: " + reason(state)
    if (latencyMs >= 0) return "Starlink " + Math.round(latencyMs) + " ms"
    return "Starlink verbunden"
  }

  // Die Schüssel nennt den Grund als Code. Hier die Übersetzung in Worte.
  function reason(code) {
    switch (String(code)) {
      case "CONNECTED": return "Verbunden"
      case "NO_SCHEDULE": return "Kein Satellit erreichbar"
      case "NO_SATS": return "Kein Satellit in Sicht"
      case "OBSTRUCTED": return "Hindernis im Blickfeld"
      case "NO_DOWNLINK": return "Kein Empfang vom Satelliten"
      case "NO_PINGS": return "Keine Antwort vom Netz"
      case "BOOTING": return "Schüssel startet"
      case "SEARCHING": return "Schüssel sucht Satelliten"
      case "STOWED": return "Schüssel eingeklappt"
      case "THERMAL_SHUTDOWN": return "Überhitzt, abgeschaltet"
      case "SLEEPING": return "Schüssel schläft"
      case "MOVING_WHILE_NOT_ALLOWED": return "In Bewegung, nicht erlaubt"
      case "UNKNOWN": return "Unbekannter Grund"
      default: return String(code)
    }
  }

  function shortReason(code) {
    switch (String(code)) {
      case "NO_SCHEDULE":
      case "NO_SATS": return "kein Satellit"
      case "OBSTRUCTED": return "Hindernis"
      case "NO_DOWNLINK": return "kein Empfang"
      case "NO_PINGS": return "kein Netz"
      case "BOOTING":
      case "SEARCHING": return "sucht"
      case "THERMAL_SHUTDOWN": return "überhitzt"
      default: return "Unterbruch"
    }
  }

  function fmtMbit(bps) {
    var v = Number(bps)
    if (!isFinite(v) || v < 0) return "–"
    return (v / 1e6).toFixed(v >= 10e6 ? 0 : (v >= 1e6 ? 1 : 2))
  }

  function fmtUptime(s) {
    var v = Number(s)
    if (!isFinite(v) || v < 0) return "–"
    var h = Math.floor(v / 3600), m = Math.floor((v % 3600) / 60)
    if (h >= 48) return Math.floor(h / 24) + " d " + (h % 24) + " h"
    return h + " h " + m + " min"
  }

  // ---- Öffnen und Schliessen, wie bei den eingebauten Panels
  function open() {
    openedFromHotkey = false
    root.controller.show()
    root.refresh()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    root.controller.show()
    root.refresh()
  }

  function close() { root.controller.hide() }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  Process {
    id: statusProc
    command: ["bash", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var line = String(text || "").trim()
        if (line === "") return
        try {
          root.data = JSON.parse(line)
          root.lastError = root.data.ok ? "" : String(root.data.error || "Schüssel nicht erreichbar")
          root.lastUpdateMs = Date.now()
        } catch (e) {
          root.lastError = "Antwort nicht lesbar"
        }
      }
    }
  }

  Timer {
    interval: root.refreshSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // ---- Das Panel selbst
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onReturnRequested: root.refresh()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
        readonly property color dim: Qt.darker(fg, 1.5)
        readonly property color accent: Color.accent
        readonly property color urgent: root.bar ? root.bar.urgent : Color.urgent
        readonly property string family: root.bar ? root.bar.fontFamily : Style.font.family

        // Kopfzeile
        Item {
          width: parent.width
          height: title.implicitHeight
          Text {
            id: title
            text: "Starlink"
            color: column.fg
            font.family: column.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            anchors.right: parent.right
            anchors.baseline: title.baseline
            text: root.reachable ? "läuft seit " + root.fmtUptime(root.data.uptime_s) : ""
            color: column.dim
            font.family: column.family
            font.pixelSize: Style.font.bodySmall
          }
        }

        // Zustand
        Row {
          spacing: Style.space(8)
          Rectangle {
            width: Style.space(10); height: width; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: !root.reachable ? column.dim : (root.connected ? column.accent : column.urgent)
          }
          Text {
            text: !root.reachable ? "Schüssel nicht erreichbar" : root.reason(root.state)
            color: column.fg
            font.family: column.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
        }

        // Kennzahlen; Flow bricht um, wenn die Zeile zu lang wird
        Flow {
          visible: root.reachable
          width: parent.width
          spacing: Style.space(18)
          leftPadding: Style.space(18)
          Text {
            text: root.latencyMs >= 0 ? Math.round(root.latencyMs) + " ms" : "– ms"
            color: column.fg; font.family: column.family; font.pixelSize: Style.font.body
          }
          Text {
            text: root.dropPct >= 0 ? root.dropPct.toFixed(1) + " % Verlust" : "– % Verlust"
            color: column.fg; font.family: column.family; font.pixelSize: Style.font.body
          }
          Text {
            text: root.reachable ? root.fmtMbit(root.data.down_bps) + " / " + root.fmtMbit(root.data.up_bps) + " Mbit/s" : ""
            color: column.fg; font.family: column.family; font.pixelSize: Style.font.body
          }
        }

        // Hinweise der Schüssel (Alerts), falls welche anliegen
        Text {
          visible: root.reachable && root.data.alerts && root.data.alerts.length > 0
          width: parent.width
          wrapMode: Text.WordWrap
          text: root.reachable && root.data.alerts ? "Hinweis: " + root.data.alerts.join(", ") : ""
          color: column.urgent
          font.family: column.family
          font.pixelSize: Style.font.bodySmall
        }

        // Fehler
        Text {
          visible: root.lastError !== ""
          width: parent.width
          wrapMode: Text.WordWrap
          text: root.lastError
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.bodySmall
        }

        // Fusszeile
        Text {
          text: root.lastUpdateMs > 0 ? "zuletzt " + Qt.formatTime(new Date(root.lastUpdateMs), "HH:mm:ss") + " · alle " + root.refreshSec + " s" : "warte auf erste Antwort"
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
