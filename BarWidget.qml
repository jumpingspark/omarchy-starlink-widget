import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Das Widget in der Bar: zeigt die Verzögerung, Klick öffnet das Panel.
// Aufbau nach dem Muster von omarchy.weather (BarWidget + Panel.qml).
BarWidget {
  id: root
  moduleName: "dd.starlink"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  // Nicht über Starlink online: kein Symbol, keine Breite, keine Lücke in der Bar.
  readonly property bool gone: panelLoader.item ? panelLoader.item.gone === true : false
  visible: !gone
  implicitWidth: gone ? 0 : button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  // Der Wächter läuft, solange das Widget lebt: Quickshell beendet ihn mit dem
  // Widget, und stirbt die Shell, merkt er es am Elternprozess. Er startet den
  // Sammler nur im Starlink-Netz. Stirbt er selbst, kommt er nach 15 s wieder.
  readonly property string watchPath: String(Qt.resolvedUrl("bin/starlink-watch")).replace(/^file:\/\//, "")

  Process {
    id: watcher
    command: [root.watchPath]
    running: true
    onExited: restartWatcher.start()
  }

  Timer {
    id: restartWatcher
    interval: 15000
    onTriggered: watcher.running = true
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: panelLoader.item ? panelLoader.item.glyph : "\uEF60"
    active: panelLoader.item ? panelLoader.item.down : false
    // schwach: Symbol halb gedämpft, damit es auffällt, ohne Alarm zu schreien
    opacity: panelLoader.item && panelLoader.item.weak ? 0.5 : 1
    tooltipText: panelLoader.item ? panelLoader.item.tooltip : "Starlink"

    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.refresh()
      else root.togglePanel()
    }
  }
}
