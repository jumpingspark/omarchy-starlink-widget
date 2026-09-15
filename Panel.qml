import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Das Klick-Panel, gebaut wie die Batterie- und Netzwerk-Panels von Omarchy:
// Kopf mit Symbol, Titel, Statuszeile und grosser Kennzahl, Verlauf als Linie,
// Kennzahlen im Raster, Unterbrüche als Liste.
// Die Daten schreibt der Sammler (bin/starlink-collector, vom Bar-Widget
// gestartet) nach ~/.local/state/starlink/status.json; das Panel liest nur.
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
  readonly property int staleAfterS: 45

  readonly property bool haveFile: data !== null
  readonly property bool stale: haveFile && (nowMs / 1000 - Number(data.ts || 0)) > staleAfterS
  readonly property bool reachable: haveFile && !stale && data.ok === true
  // Weg: die Schüssel antwortet seit einer Weile nicht, also sind wir nicht über
  // Starlink online (fremdes WLAN, Kabel). Dann verschwindet das Widget aus der Bar.
  // Ein Sammler, der sich nicht meldet, ist dagegen ein Fehler und bleibt sichtbar.
  readonly property int goneAfterS: 30
  readonly property bool setup: haveFile && data.setup === true
  readonly property bool gone: haveFile && !stale && !setup && data.ok !== true
    && (data.last_ok === null || data.last_ok === undefined || (Number(data.ts) - Number(data.last_ok)) > goneAfterS)
  onGoneChanged: if (gone && opened) close()
  readonly property string state: reachable ? String(data.state || "") : ""
  readonly property bool connected: reachable && state === "CONNECTED"
  readonly property bool down: reachable && !connected
  readonly property real latencyMs: reachable && data.latency_ms !== null && data.latency_ms !== undefined ? Number(data.latency_ms) : -1
  readonly property real dropPct: reachable && data.drop !== null && data.drop !== undefined ? Number(data.drop) * 100 : -1
  readonly property var outages: haveFile && data.outages ? data.outages : []
  readonly property var currentOutage: haveFile && data.current_outage ? data.current_outage : null
  readonly property int maxRows: 6
  readonly property var recentOutages: {
    var list = outages.slice()
    list.reverse()
    return list.slice(0, maxRows)
  }

  // Schwach: über die letzte Minute im Mittel mehr als 5 % Paketverlust oder
  // eine mittlere Verzögerung über 150 ms. Ein einzelner Ausreisser zählt nicht.
  readonly property int weakWindowS: 60
  readonly property real weakDrop: 0.05
  readonly property real weakLatencyMs: 150
  readonly property var weakness: {
    if (!reachable || !data.history) return { weak: false, why: "" }
    var t0 = nowMs / 1000 - weakWindowS
    var drops = [], lats = []
    for (var i = 0; i < data.history.length; i++) {
      var h = data.history[i]
      if (h[0] < t0) continue
      if (h[2] !== null && h[2] !== undefined) drops.push(Number(h[2]))
      if (h[1] !== null && h[1] !== undefined) lats.push(Number(h[1]))
    }
    if (drops.length < 10) return { weak: false, why: "" }
    var sum = 0
    for (var d = 0; d < drops.length; d++) sum += drops[d]
    if (sum / drops.length > weakDrop) return { weak: true, why: "loss", value: sum / drops.length * 100 }
    if (lats.length >= 10) {
      lats.sort(function(a, b) { return a - b })
      var med = lats[Math.floor(lats.length / 2)]
      if (med > weakLatencyMs) return { weak: true, why: "latency", value: med }
    }
    return { weak: false, why: "" }
  }
  readonly property bool weak: connected && weakness.weak

  // Statuszeile im Kopf, wie beim Akku-Panel: kurze Sprüche aus dem Weltall,
  // alle 2.8 s der nächste, solange das Panel offen ist.
  readonly property var phrasesGood: ["Orbiting smoothly", "Riding the beam", "Surfing low orbit", "Beaming down bits", "Talking to the stars", "Catching satellites", "Pinging the sky", "Locked on orbit", "Cruising at 550 km"]
  readonly property var phrasesLoss: ["Dropping packets", "Leaking bits", "Losing the beam", "Static in orbit", "Shedding packets"]
  readonly property var phrasesLatency: ["Taking the scenic orbit", "Long way round", "Lagging behind", "Slow beam tonight", "Signal detour"]

  readonly property var activePhrases: {
    if (!connected) return []
    if (weak) return weakness.why === "loss" ? phrasesLoss : phrasesLatency
    return phrasesGood
  }
  readonly property bool rotatingPhrases: activePhrases.length > 0
  property int phraseIndex: 0

  // Die eine Zeile unter dem Titel: Spruch, oder der Grund, warum keiner passt.
  readonly property string heroMeta: {
    if (!haveFile || stale) return "Collector silent"
    if (setup) return String(data.error || "Setting up")
    if (!reachable) return "Dish unreachable"
    if (down) return reason(state)
    return activePhrases[phraseIndex % activePhrases.length]
  }

  // Symbol in der Bar (Nerd Font, Satellitenschüssel U+EF60, fa-satellite_dish, von David gewählt);
  // der Tooltip trägt die Zahl.
  readonly property string glyph: ""
  readonly property string tooltip: latencyMs >= 0 ? "Starlink " + Math.round(latencyMs) + " ms · " + heroMeta : "Starlink · " + heroMeta

  // Die Schüssel nennt den Grund als Code. Hier die Übersetzung in Worte.
  function reason(code) {
    switch (String(code)) {
      case "CONNECTED": return "Connected"
      case "NO_SCHEDULE": return "No schedule"
      case "NO_SATS": return "No satellites"
      case "OBSTRUCTED": return "Obstructed"
      case "NO_DOWNLINK": return "No downlink"
      case "NO_PINGS": return "No pings"
      case "BOOTING": return "Booting"
      case "SEARCHING": return "Searching"
      case "STOWED": return "Stowed"
      case "THERMAL_SHUTDOWN": return "Thermal shutdown"
      case "SLEEPING": return "Sleeping"
      case "MOVING_WHILE_NOT_ALLOWED": return "Moving"
      case "UNKNOWN": return "Unknown"
      default: return String(code)
    }
  }

  // Durchsatz wie im Netzwerk-Panel: KB/s oder MB/s, aus Bit pro Sekunde.
  function fmtRate(bps) {
    var v = Number(bps) / 8
    if (!isFinite(v) || v < 0) return "--"
    if (v >= 1e6) return (v / 1e6).toFixed(1) + " MB/s"
    return (v / 1e3).toFixed(1) + " KB/s"
  }

  function fmtPct(p) {
    var v = Number(p)
    if (!isFinite(v) || v < 0) return "--"
    return (v >= 10 ? Math.round(v) : v.toFixed(1)) + "%"
  }

  function fmtUptime(s) {
    var v = Number(s)
    if (!isFinite(v) || v < 0) return "--"
    var h = Math.floor(v / 3600), m = Math.floor((v % 3600) / 60)
    if (h >= 48) return Math.floor(h / 24) + "d " + (h % 24) + "h"
    return h + "h " + m + "m"
  }

  function fmtDuration(s) {
    var v = Math.round(Number(s))
    if (!isFinite(v) || v < 0) return "--"
    if (v < 60) return v + "s"
    if (v < 3600) return Math.floor(v / 60) + "m " + (v % 60) + "s"
    return Math.floor(v / 3600) + "h " + Math.floor((v % 3600) / 60) + "m"
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
      root.lastError = root.data.ok ? "" : String(root.data.error || "")
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
    onLoadFailed: { root.data = null; root.lastError = "Collector not running" }
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

  // Spruchwechsel mit Ausblenden, wie beim Akku-Panel.
  Timer {
    interval: 2800
    running: root.opened && root.rotatingPhrases
    repeat: true
    onTriggered: phraseSwap.restart()
  }

  SequentialAnimation {
    id: phraseSwap
    PropertyAnimation { target: heroStatus; property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.OutQuad }
    ScriptAction {
      script: {
        var n = root.activePhrases.length
        if (n > 0) root.phraseIndex = (root.phraseIndex + 1) % n
      }
    }
    PropertyAnimation { target: heroStatus; property: "opacity"; to: 1.0; duration: 260; easing.type: Easing.InQuad }
  }

  Connections {
    target: root
    function onRotatingPhrasesChanged() {
      if (!root.rotatingPhrases) { phraseSwap.stop(); heroStatus.opacity = 1.0 }
    }
  }

  // ---- Das Panel selbst
  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onReturnRequested: root.refresh()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
        readonly property color dim: Qt.darker(fg, 1.4)
        readonly property color urgent: root.bar ? root.bar.urgent : Color.urgent
        readonly property string family: root.bar ? root.bar.fontFamily : Style.font.family

        // ---------- Kopf: Symbol · Titel/Status · Verzögerung ----------
        Item {
          width: parent.width
          implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroValue.implicitHeight)

          Text {
            id: heroIcon
            textFormat: Text.PlainText
            text: root.glyph
            color: column.fg
            font.family: column.family
            font.pixelSize: Style.font.display
            opacity: root.reachable ? 1.0 : 0.5
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            id: heroLabels
            anchors.left: heroIcon.right
            anchors.leftMargin: Style.space(14)
            anchors.right: heroValue.left
            anchors.rightMargin: Style.space(10)
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(2)

            Text {
              textFormat: Text.PlainText
              text: "Starlink"
              color: column.fg
              font.family: column.family
              font.pixelSize: Style.font.title
              font.bold: true
              elide: Text.ElideRight
              width: parent.width
            }

            Text {
              id: heroStatus
              textFormat: Text.PlainText
              text: root.heroMeta.toUpperCase()
              color: root.down ? column.urgent : column.dim
              font.family: column.family
              font.pixelSize: Style.font.caption
              font.bold: true
              font.letterSpacing: 1.2
              elide: Text.ElideRight
              width: parent.width
            }
          }

          Text {
            id: heroValue
            textFormat: Text.PlainText
            text: root.latencyMs >= 0 ? Math.round(root.latencyMs) + " ms" : "—"
            color: root.down || root.weak ? column.urgent : column.fg
            font.family: column.family
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
          }
        }

        // ---------- Verlauf der Verzögerung, 15 Minuten, ohne Beschriftung ----------
        Canvas {
          id: chart
          width: parent.width
          height: Style.space(40)
          visible: root.haveFile

          readonly property int spanS: 15 * 60
          readonly property var history: root.haveFile && root.data.history ? root.data.history : []

          onHistoryChanged: requestPaint()
          onWidthChanged: requestPaint()
          Connections {
            target: root
            function onNowMsChanged() { chart.requestPaint() }
          }

          onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var w = width, h = height
            var now = root.nowMs / 1000
            var t0 = now - spanS
            var pts = history

            // Skala: mindestens 100 ms, sonst die nächste runde Stufe über dem Maximum
            var maxV = 0
            for (var i = 0; i < pts.length; i++) {
              var v = pts[i][1]
              if (v !== null && v !== undefined && isFinite(v) && v > maxV) maxV = v
            }
            var steps = [100, 150, 200, 300, 500, 1000, 2000]
            var yMax = steps[steps.length - 1]
            for (var k = 0; k < steps.length; k++) { if (maxV <= steps[k]) { yMax = steps[k]; break } }

            function x(t) { return (t - t0) / spanS * w }
            function y(v) { return h - 1 - Math.min(v, yMax) / yMax * (h - 2) }

            var fg = column.fg
            // Grundlinie, so leise wie eine Trennlinie
            ctx.fillStyle = Qt.rgba(fg.r, fg.g, fg.b, 0.12)
            ctx.fillRect(0, h - 1, w, 1)

            // Unterbrüche als Band: Messpunkte ohne Verzögerung oder mit vollem Verlust
            var urgent = column.urgent
            ctx.fillStyle = Qt.rgba(urgent.r, urgent.g, urgent.b, 0.35)
            var gapStart = -1
            for (var g = 0; g <= pts.length; g++) {
              var isGap = g < pts.length && (pts[g][1] === null || pts[g][1] === undefined || Number(pts[g][2]) >= 1)
              if (isGap && gapStart < 0) gapStart = pts[g][0]
              if (!isGap && gapStart >= 0) {
                var gEnd = g < pts.length ? pts[g][0] : now
                var gx = Math.max(0, x(gapStart))
                ctx.fillRect(gx, 0, Math.max(2, x(gEnd) - gx), h)
                gapStart = -1
              }
            }

            // Die Kurve; Lücken bleiben Lücken
            ctx.strokeStyle = String(fg)
            ctx.lineWidth = 1.5
            ctx.lineJoin = "round"
            var drawing = false
            ctx.beginPath()
            for (var j = 0; j < pts.length; j++) {
              var t = pts[j][0], val = pts[j][1]
              if (t < t0) continue
              var ok = val !== null && val !== undefined && isFinite(val) && Number(pts[j][2]) < 1
              if (!ok) { drawing = false; continue }
              if (!drawing) { ctx.moveTo(x(t), y(val)); drawing = true }
              else ctx.lineTo(x(t), y(val))
            }
            ctx.stroke()
          }
        }

        // ---------- Kennzahlen, vierspaltig wie im Netzwerk-Panel ----------
        GridLayout {
          visible: root.reachable
          width: parent.width
          columns: 4
          columnSpacing: Style.space(20)
          rowSpacing: Style.spacing.labelGap

          InfoLabel { text: "Ping" }
          DetailValue { text: root.latencyMs >= 0 ? Math.round(root.latencyMs) + " ms" : "--" }
          InfoLabel { text: "Packet Loss" }
          DetailValue {
            text: root.fmtPct(root.dropPct)
            color: root.dropPct > 0 ? column.urgent : column.fg
          }

          InfoLabel { text: "Receiving" }
          DetailValue { text: root.reachable ? root.fmtRate(root.data.down_bps) : "--" }
          InfoLabel { text: "Sending" }
          DetailValue { text: root.reachable ? root.fmtRate(root.data.up_bps) : "--" }

          InfoLabel { text: "Uptime" }
          DetailValue { text: root.reachable ? root.fmtUptime(root.data.uptime_s) : "--" }
          InfoLabel { text: "Obstructed" }
          DetailValue {
            text: root.reachable ? root.fmtPct(Number(root.data.fraction_obstructed) * 100) : "--"
            color: root.reachable && root.data.obstructed ? column.urgent : column.fg
          }
        }

        // Hinweise der Schüssel (Alerts), nur wenn welche anliegen
        Text {
          visible: root.reachable && root.data.alerts && root.data.alerts.length > 0
          width: parent.width
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
          text: root.reachable && root.data.alerts ? root.data.alerts.join(", ") : ""
          color: column.urgent
          font.family: column.family
          font.pixelSize: Style.font.bodySmall
        }

        // Fehler des Sammlers, nur wenn die Schüssel nicht antwortet
        Text {
          visible: root.lastError !== "" && !root.reachable && !root.setup
          width: parent.width
          wrapMode: Text.WordWrap
          textFormat: Text.PlainText
          text: root.lastError
          color: column.dim
          font.family: column.family
          font.pixelSize: Style.font.bodySmall
        }

        // ---------- Unterbrüche seit Rechnerstart ----------
        PanelSeparator { foreground: column.fg }

        Column {
          width: parent.width
          spacing: Style.space(6)

          PanelSectionHeader {
            text: "OUTAGES"
            foreground: column.fg
            fontFamily: column.family
          }

          InfoLabel {
            visible: root.currentOutage === null && root.recentOutages.length === 0
            text: root.haveFile && root.data.boot ? "None since " + root.fmtClock(root.data.boot) : "--"
          }

          OutageRow {
            visible: root.currentOutage !== null
            start: root.currentOutage ? Number(root.currentOutage.start) : 0
            cause: root.currentOutage ? String(root.currentOutage.cause) : ""
            duration: root.currentOutage ? root.nowMs / 1000 - Number(root.currentOutage.start) : 0
            running: true
          }

          Repeater {
            model: root.recentOutages
            OutageRow {
              required property var modelData
              start: Number(modelData.start)
              cause: String(modelData.cause)
              duration: Number(modelData.duration_s)
            }
          }

          InfoLabel {
            visible: root.outages.length > root.recentOutages.length
            text: "+" + (root.outages.length - root.recentOutages.length) + " more"
          }
        }
      }
    }
  }

  component InfoLabel: Text {
    textFormat: Text.PlainText
    color: column.fg
    opacity: 0.6
    font.family: column.family
    font.pixelSize: Style.font.bodySmall
  }

  component InfoValue: Text {
    textFormat: Text.PlainText
    color: column.fg
    font.family: column.family
    font.pixelSize: Style.font.bodySmall
  }

  // Wert im Raster, rechtsbündig in seiner Spalte wie im Netzwerk-Panel.
  component DetailValue: InfoValue {
    Layout.fillWidth: true
    horizontalAlignment: Text.AlignRight
  }

  // Eine Zeile der Unterbruchsliste: Uhrzeit, Grund, Dauer; laufend in Alarmfarbe.
  component OutageRow: Item {
    property real start: 0
    property string cause: ""
    property real duration: 0
    property bool running: false

    width: parent ? parent.width : implicitWidth
    implicitHeight: rowTime.implicitHeight + Style.spacing.labelGap

    InfoLabel {
      id: rowTime
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: root.fmtClock(start)
    }
    InfoValue {
      anchors.left: rowTime.right
      anchors.leftMargin: Style.space(12)
      anchors.right: rowDuration.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
      text: root.reason(cause)
      color: running ? column.urgent : column.fg
    }
    InfoValue {
      id: rowDuration
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: root.fmtDuration(duration)
      color: running ? column.urgent : column.fg
      opacity: running ? 1 : 0.6
    }
  }
}
