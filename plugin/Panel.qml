import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Das Klick-Panel: Zustand, Kennzahlen und die Unterbrüche seit Rechnerstart.
// Die Daten schreibt der Sammler (bin/starlink-collector, Benutzerdienst)
// nach ~/.local/state/starlink/status.json; das Panel liest nur.
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
  property var data: null            // Inhalt von status.json
  property string lastError: ""
  property double nowMs: Date.now()

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/starlink/status.json"
  readonly property int staleAfterS: 30

  readonly property bool haveFile: data !== null
  readonly property bool stale: haveFile && (nowMs / 1000 - Number(data.ts || 0)) > staleAfterS
  readonly property bool reachable: haveFile && !stale && data.ok === true
  readonly property string state: reachable ? String(data.state || "") : ""
  readonly property bool connected: reachable && state === "CONNECTED"
  readonly property bool down: reachable && !connected
  readonly property real latencyMs: reachable && data.latency_ms !== null && data.latency_ms !== undefined ? Number(data.latency_ms) : -1
  readonly property real dropPct: reachable && data.drop !== null && data.drop !== undefined ? Number(data.drop) * 100 : -1
  readonly property var outages: haveFile && data.outages ? data.outages : []
  readonly property var currentOutage: haveFile && data.current_outage ? data.current_outage : null
  readonly property var recentOutages: {
    var list = outages.slice()
    list.reverse()
    return list.slice(0, 8)
  }

  // Symbol in der Bar (Nerd Font, Satellitenschüssel U+EF60, fa-satellite_dish, von David gewählt);
  // der Tooltip trägt die Zahlen.
  readonly property string glyph: "\uEF60"
  readonly property string tooltip: {
    if (!haveFile || stale) return "Starlink: Sammler meldet sich nicht"
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

  function fmtDuration(s) {
    var v = Math.round(Number(s))
    if (!isFinite(v) || v < 0) return "–"
    if (v < 60) return v + " s"
    if (v < 3600) return Math.floor(v / 60) + " min " + (v % 60) + " s"
    return Math.floor(v / 3600) + " h " + Math.floor((v % 3600) / 60) + " min"
  }

  // Uhrzeit; liegt der Zeitpunkt nicht am heutigen Tag, mit Wochentag davor.
  function fmtClock(ts) {
    var d = new Date(Number(ts) * 1000)
    var now = new Date(root.nowMs)
    var sameDay = d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth() && d.getDate() === now.getDate()
    return sameDay ? Qt.formatTime(d, "HH:mm") : Qt.formatDateTime(d, "ddd HH:mm")
  }

  function parse(text) {
    var line = String(text || "").trim()
    if (line === "") return
    try {
      root.data = JSON.parse(line)
      root.lastError = root.data.ok ? "" : String(root.data.error || "Schüssel nicht erreichbar")
    } catch (e) {
      // halb geschriebene Datei: alten Stand behalten
    }
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

  function refresh() { stateFile.reload() }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parse(text())
    onLoadFailed: { root.data = null; root.lastError = "Sammler läuft nicht" }
  }

  // Der Sammler ersetzt die Datei atomar; der Dateiwächter verliert dabei
  // manchmal den Faden. Darum zusätzlich alle 2 s lesen (die Datei ist klein).
  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: { root.nowMs = Date.now(); stateFile.reload() }
  }

  // ---- Das Panel selbst
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
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
            text: {
              if (!root.haveFile || root.stale) return "Sammler meldet sich nicht"
              if (!root.reachable) return "Schüssel nicht erreichbar"
              return root.reason(root.state)
            }
            color: column.fg
            font.family: column.family
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }
        }

        // Laufender Unterbruch
        Text {
          visible: root.reachable && root.currentOutage !== null
          leftPadding: Style.space(18)
          text: root.currentOutage ? "seit " + root.fmtClock(root.currentOutage.start) + ", " + root.fmtDuration(root.nowMs / 1000 - Number(root.currentOutage.start)) : ""
          color: column.urgent
          font.family: column.family
          font.pixelSize: Style.font.body
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

        // Unterbrüche seit Rechnerstart
        PanelSectionHeader {
          text: "UNTERBRÜCHE SEIT START"
          foreground: column.fg
          fontFamily: column.family
        }

        Text {
          visible: root.recentOutages.length === 0
          text: root.haveFile ? "keine seit " + root.fmtClock(root.data.boot) : "–"
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.body
        }

        Column {
          width: parent.width
          spacing: 0
          Repeater {
            model: root.recentOutages
            delegate: Item {
              required property var modelData
              width: column.width
              height: rowText.implicitHeight + Style.space(10)
              Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: column.dim; opacity: 0.25 }
              Text {
                id: rowText
                anchors.verticalCenter: parent.verticalCenter
                text: root.fmtClock(modelData.start)
                color: column.dim
                font.family: column.family
                font.pixelSize: Style.font.body
              }
              Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: rowText.right
                anchors.leftMargin: Style.space(12)
                anchors.right: durText.left
                anchors.rightMargin: Style.space(8)
                elide: Text.ElideRight
                text: root.reason(modelData.cause)
                color: column.fg
                font.family: column.family
                font.pixelSize: Style.font.body
              }
              Text {
                id: durText
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                text: root.fmtDuration(modelData.duration_s)
                color: column.dim
                font.family: column.family
                font.pixelSize: Style.font.body
              }
            }
          }
        }

        Text {
          visible: root.outages.length > root.recentOutages.length
          text: "und " + (root.outages.length - root.recentOutages.length) + " weitere"
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.bodySmall
        }

        // Fehler
        Text {
          visible: root.lastError !== "" && !root.reachable
          width: parent.width
          wrapMode: Text.WordWrap
          text: root.lastError
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.bodySmall
        }

        // Fusszeile
        Text {
          text: root.haveFile ? "Stand " + Qt.formatTime(new Date(Number(root.data.ts) * 1000), "HH:mm:ss") + " · Sammler fragt alle " + (root.data.interval_s || 2) + " s" : "warte auf den Sammler"
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
